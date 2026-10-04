#!/usr/bin/env node
// Status line de dos líneas:
//   1) usuario ➜ proyecto, rama git y estado de sesión
//   2) modelo · esfuerzo | contexto | costo | cache | límites 5h/7d
const os = require('os');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const ESC = '\x1b';
const RESET = `${ESC}[0m`;
const paint = (code, text) => `${ESC}[${code}m${text}${RESET}`;
const DAYS = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
const RESET_ICON = '↻';
const SEP = paint('90', ' | ');

const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const str = (v) => (typeof v === 'string' && v.trim() ? v : null);
const pad = (n) => String(n).padStart(2, '0');
const hhmm = (d) => `${pad(d.getHours())}:${pad(d.getMinutes())}`;
const visibleLength = (s) => s.replace(/\x1b\[[0-9;]*m/g, '').length;

// Nivel de esfuerzo: más intenso cuanto mayor es el razonamiento.
const EFFORT_COLORS = { low: '90', medium: '36', high: '33', xhigh: '38;5;208', max: '31' };

// Verde sano, amarillo medio, rojo bajo (sobre porcentaje restante).
const pctColor = (p) => (p >= 40 ? '32' : p >= 15 ? '33' : '31');

// Barra de contexto con semáforo según uso: [fg del %, bg celda llena, bg celda libre].
const BAR_CELLS = 10;
const barTheme = (usedPct) => (usedPct < 50 ? ['32', 41, 22] : usedPct < 80 ? ['33', 178, 58] : ['31', 160, 52]);
const bar = (usedPct, fillBg, emptyBg) => {
  const filled = Math.round((usedPct / 100) * BAR_CELLS);
  const cell = (bg, n) => (n > 0 ? `${ESC}[48;5;${bg}m${' '.repeat(n)}${RESET}` : '');
  return cell(fillBg, filled) + cell(emptyBg, BAR_CELLS - filled);
};

// 1000000 -> "1M", 200000 -> "200k".
const formatSize = (n) => {
  if (n === null || n <= 0) return null;
  if (n >= 1e6) return `${Number((n / 1e6).toFixed(1))}M`;
  return `${Math.round(n / 1e3)}k`;
};

// 4320000 -> "1h12m", 95000 -> "1m", 12000 -> "12s".
const formatDuration = (ms) => {
  const totalMin = Math.floor(ms / 60000);
  if (totalMin >= 60) return `${Math.floor(totalMin / 60)}h${pad(totalMin % 60)}m`;
  if (totalMin >= 1) return `${totalMin}m`;
  return `${Math.max(0, Math.floor(ms / 1000))}s`;
};

// Tiempo restante hasta una fecha futura; null si ya pasó.
const formatCountdown = (date) => {
  const ms = date.getTime() - Date.now();
  if (ms <= 0) return null;
  const totalMin = Math.ceil(ms / 60000);
  if (totalMin >= 60) return `${Math.floor(totalMin / 60)}h${pad(totalMin % 60)}m`;
  return `${totalMin}m`;
};

const toDate = (epoch) => {
  const n = num(epoch);
  if (n === null) return null;
  // Segundos Unix; tolera milisegundos.
  const d = new Date(n < 1e12 ? n * 1000 : n);
  return Number.isNaN(d.getTime()) ? null : d;
};

const normalizePath = (s) => s.replace(/\\/g, '/').replace(/\/+$/, '');

// "~" en lugar del home; separadores normalizados a "/".
const shortenHome = (p) => {
  const target = normalizePath(p);
  const homes = [process.env.USERPROFILE, process.env.HOME, os.homedir()].filter(Boolean).map(normalizePath);
  for (const home of homes) {
    if (target.toLowerCase() === home.toLowerCase()) return '~';
    if (target.toLowerCase().startsWith(`${home.toLowerCase()}/`)) return `~${target.slice(home.length)}`;
  }
  return target;
};

// Subdirectorio de `cwd` respecto al proyecto; null si es el mismo o queda fuera.
const relativeSubdir = (cwd, proj) => {
  const c = normalizePath(cwd);
  const p = normalizePath(proj);
  if (c.toLowerCase() === p.toLowerCase()) return null;
  return c.toLowerCase().startsWith(`${p.toLowerCase()}/`) ? c.slice(p.length + 1) : null;
};

// Rama git y archivos sucios, cacheado unos segundos para no lanzar git en cada refresco.
const GIT_CACHE_TTL_MS = 5000;
const gitInfo = (cwd) => {
  if (!cwd) return null;
  const cacheFile = path.join(os.tmpdir(), `claude-statusline-git-${crypto.createHash('md5').update(cwd).digest('hex')}.json`);
  try {
    const cached = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
    if (Date.now() - cached.at < GIT_CACHE_TTL_MS) return cached.info;
  } catch {
    // Sin caché válida: se consulta git.
  }
  let info = null;
  try {
    const out = execFileSync('git', ['-C', cwd, '--no-optional-locks', 'status', '--porcelain=v1', '-b'], {
      encoding: 'utf8',
      timeout: 500,
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    const [header, ...files] = out.split('\n').filter(Boolean);
    const branch = header.replace(/^## /, '').replace(/^No commits yet on /, '').split(/\.\.\.|\s/)[0];
    info = { branch: branch === 'HEAD' ? 'detached' : branch, dirty: files.length };
  } catch {
    // No es repositorio, git ausente o timeout: se omite el segmento.
  }
  try {
    fs.writeFileSync(cacheFile, JSON.stringify({ at: Date.now(), info }));
  } catch {
    // Caché opcional.
  }
  return info;
};

const buildLine1 = (data) => {
  const user = (os.userInfo().username || process.env.USERNAME || '').split('\\').pop();
  const cwd = str(data?.workspace?.current_dir) || str(data?.cwd);
  const proj = str(data?.workspace?.project_dir) || cwd || '';
  let line = `${paint('38;5;209', `@${user}`)} ${paint('32', '➜')} ${paint('36', shortenHome(proj))}`;

  const sub = cwd && proj ? relativeSubdir(cwd, proj) : null;
  if (sub) line += ` ${paint('90', '↳')} ${paint('36', sub)}`;

  const git = gitInfo(cwd);
  if (git) {
    line += ` ${paint('35', `⎇ ${git.branch}`)}`;
    if (git.dirty > 0) line += ` ${paint('33', `±${git.dirty}`)}`;
  }

  const worktree = str(data?.workspace?.git_worktree);
  if (worktree) line += ` ${paint('90', `wt:${worktree}`)}`;
  const agent = str(data?.agent?.name);
  if (agent) line += ` ${paint('90', `agent:${agent}`)}`;
  const vim = str(data?.vim?.mode);
  if (vim) line += ` ${paint('90', vim.toLowerCase())}`;
  return line;
};

// Segmentos de la línea 2 con prioridad (menor = se conserva primero).
const buildSegments = (data) => {
  const segments = [];
  const add = (priority, text) => text && segments.push({ priority, text });

  const model = str(data?.model?.display_name);
  const effort = str(data?.effort?.level);
  const fast = data?.fast_mode === true ? ` ${paint('33', '⚡')}` : '';
  if (model) {
    const effortText = effort ? ` ${paint('90', '·')} ${paint(EFFORT_COLORS[effort] || '37', effort)}` : '';
    add(1, `${model}${effortText}${fast}`);
  }

  const ctxUsedRaw = num(data?.context_window?.used_percentage);
  const ctxRemaining = num(data?.context_window?.remaining_percentage);
  const ctxUsed = ctxUsedRaw !== null ? ctxUsedRaw : ctxRemaining !== null ? 100 - ctxRemaining : null;
  if (ctxUsed !== null) {
    const used = Math.min(100, Math.max(0, Math.round(ctxUsed)));
    const [fg, fillBg, emptyBg] = barTheme(used);
    const size = formatSize(num(data?.context_window?.context_window_size));
    add(1, `ctx ${bar(used, fillBg, emptyBg)} ${paint(fg, `${used}%`)}${size ? paint('90', `/${size}`) : ''}`);
  } else {
    add(1, 'ctx -');
  }

  const five = num(data?.rate_limits?.five_hour?.used_percentage);
  if (five !== null) {
    const left = Math.round(100 - five);
    const reset = toDate(data.rate_limits.five_hour.resets_at);
    const when = reset ? formatCountdown(reset) || hhmm(reset) : null;
    add(2, `left 5h:${paint(pctColor(left), `${left}%`)}${when ? ` ${paint('90', `${RESET_ICON}${when}`)}` : ''}`);
  }

  const seven = num(data?.rate_limits?.seven_day?.used_percentage);
  if (seven !== null) {
    const left = Math.round(100 - seven);
    const reset = toDate(data.rate_limits.seven_day.resets_at);
    const when = reset ? `${DAYS[reset.getDay()]} ${hhmm(reset)}` : null;
    add(3, `7d:${paint(pctColor(left), `${left}%`)}${when ? ` ${paint('90', `${RESET_ICON}${when}`)}` : ''}`);
  }

  // Sesión: costo, líneas cambiadas y duración.
  const session = [];
  const cost = num(data?.cost?.total_cost_usd);
  if (cost !== null) session.push(`$${cost.toFixed(2)}`);
  const added = num(data?.cost?.total_lines_added) || 0;
  const removed = num(data?.cost?.total_lines_removed) || 0;
  if (added || removed) session.push(`${paint('32', `+${added}`)} ${paint('31', `−${removed}`)}`);
  const duration = num(data?.cost?.total_duration_ms);
  if (duration !== null) session.push(paint('90', formatDuration(duration)));
  if (session.length) add(4, session.join(' '));

  // Prompt cache: verde si está caliente, amarillo si expiró.
  const ratio = num(data?.prompt_cache?.hit_ratio);
  if (ratio !== null) {
    add(5, `cache ${paint(data.prompt_cache.warm === false ? '33' : '32', `${Math.round(ratio * 100)}%`)}`);
  }

  return segments;
};

// Une segmentos descartando los de menor prioridad hasta caber en el ancho disponible.
const fitLine2 = (segments) => {
  const columns = Number.parseInt(process.env.COLUMNS, 10);
  const join = (list) => list.map((s) => s.text).join(SEP);
  let kept = segments.slice();
  while (columns > 0 && kept.length > 1 && visibleLength(join(kept)) > columns) {
    const worst = Math.max(...kept.map((s) => s.priority));
    if (worst <= 1) break;
    const idx = kept.map((s) => s.priority).lastIndexOf(worst);
    kept.splice(idx, 1);
  }
  return join(kept);
};

const render = (data) => `${buildLine1(data)}\n${fitLine2(buildSegments(data))}`;

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => (raw += chunk));
process.stdin.on('end', () => {
  let data = {};
  try {
    data = JSON.parse(raw);
  } catch {
    // JSON ausente o inválido: se renderiza con valores por defecto.
  }
  process.stdout.write(render(data));
});
