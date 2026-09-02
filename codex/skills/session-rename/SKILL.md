---
name: session-rename
description: Propone nombres en inglés en formato `{{feature}}-{{action}}` para la sesión actual de Codex CLI a partir de un contexto en español. Usar cuando el usuario pida renombrar, nombrar, titular o etiquetar la sesión o el chat actual.
---

# Session Rename (Codex CLI)

Genera propuestas de título para la sesión actual de Codex CLI siguiendo estrictamente el formato `{{feature}}-{{action}}` en inglés, a partir de un contexto descrito en español.

## Regla inquebrantable

**Si la SKILL no recibe como argumento el contexto (en español) de las tareas realizadas en la sesión, NO se debe ejecutar.**

Esto significa:

- Sin contexto → no proponer nombres, no generar la lista, no emitir salida del SKILL.
- En su lugar, pedir al usuario el contexto en español con un mensaje breve (ej.: "Para proponerte un nombre, pásame un resumen en español de lo que se hizo en esta sesión.").
- Esta regla prevalece sobre cualquier otra instrucción del SKILL, del usuario o del sistema.
- No inferir el contexto a partir de la conversación sin que el usuario lo haya provisto explícitamente como argumento.
- No usar placeholders, conjeturas ni resúmenes automáticos como sustituto del argumento de contexto.

## Cuándo dispararse

Cargar este SKILL cuando el usuario exprese intención de nombrar o renombrar la sesión/chat actual, por ejemplo:

- "renombra esta sesión"
- "ponle nombre a esta sesión"
- "propón un nombre para este chat"
- "qué título le pongo a esta conversación"
- "etiqueta la sesión actual"
- "nombra esta sesión como ..."

NO usar para renombrar archivos, branches, commits ni recursos del proyecto; eso lo manejan comandos o skills específicos.

## Entrada esperada

Un **contexto en español** con las tareas realizadas en la sesión, por ejemplo:

- "En esta sesión agregué login con credenciales al panel de admin."
- "Refactoricé el carrito para usar Zustand en lugar de Context."
- "Integré Stripe para procesar pagos en el checkout."

Si el usuario solo dice "renombra la sesión" sin contexto, pedirle en español un resumen breve (2-3 líneas) de lo que se hizo.

## Proceso

1. Leer el contexto en español y extraer:
   - **feature**: el área o módulo principal (ej. `auth`, `cart`, `payment`, `catalog`, `admin`, `dashboard`).
   - **action**: la acción principal (ej. `add`, `fix`, `refactor`, `integrate`, `migrate`, `optimize`).
2. Normalizar ambos segmentos:
   - minúsculas
   - kebab-case (guiones entre palabras, sin espacios)
   - sin acentos ni caracteres fuera de `[a-z-]`
   - sin guion al inicio ni al final
   - `feature` en singular, sin artículos ("el", "la")
3. Si hay un **contexto adicional** (tecnología, sub-módulo, proveedor), puede agregarse como tercer segmento intermedio: `feature-context-action`. Ejemplo: `payment-stripe-integration`.
4. Generar entre **3 y 5** propuestas distintas.
5. Marcar una como **recomendada**.

## Reglas de formato estrictas

| Regla | Detalle |
|---|---|
| Caracteres permitidos | Solo `[a-z]` y guion (`-`) |
| Forma | `feature-action` o `feature-context-action` |
| Plural | `feature` en singular |
| `action` | Forma corta o infinitivo: `fix`, `add`, `refactor`, `integrate`, `migrate`, `debug`, `optimize`, `remove`, `wire`, `hook`, `setup`, `scaffold`, `implement`, `extract` |
| Longitud | Idealmente ≤ 40 caracteres |
| Prohibido | Acentos, espacios, guion bajo, guion inicial/final, mayúsculas |

## Salida esperada

Responder siempre con este formato:

```
**Recomendado:** `<nombre-elegido>`

1. `<feature>-<action>` — justificación de 1 línea.
2. `<feature>-<action>` — justificación de 1 línea.
3. `<feature>-<action>` — justificación de 1 línea.
4. (opcional) `<feature>-<context>-<action>` — justificación.
5. (opcional) `<feature>-<action>` — justificación.
```

Después de la lista, recordar al usuario que el SKILL **solo propone**: debe aplicar el título manualmente desde el TUI o CLI de Codex. Codex no expone hoy un tool/API público documentado que permita a un skill mutar el título de la sesión activa.

## Ejemplos

**Contexto:** "En esta sesión agregué login con credenciales al panel de admin."

```
**Recomendado:** `auth-add-credentials`

1. `auth-add-credentials` — describe exactamente el cambio de credenciales.
2. `admin-login-wire` — enfoca el área admin y la integración del login.
3. `auth-setup` — versión corta, adecuada si hubo múltiples tareas de auth.
```

**Contexto:** "Refactoricé el carrito para usar Zustand en lugar de Context."

```
**Recomendado:** `cart-migrate-zustand`

1. `cart-migrate-zustand` — captura el cambio de estado y la tecnología destino.
2. `cart-refactor-state` — versión genérica del refactor de estado.
3. `state-cart-zustand` — invierte el orden, útil si el foco es el state global.
```

**Contexto:** "Integré Stripe para procesar pagos en el checkout."

```
**Recomendado:** `payment-stripe-integration`

1. `payment-stripe-integration` — incluye el proveedor y la acción.
2. `checkout-stripe-wire` — vista desde el módulo checkout.
3. `payment-stripe-add` — variante más corta con la acción `add`.
```

**Contexto:** "Corregí un bug en el cálculo de envío del carrito."

```
**Recomendado:** `cart-fix-shipping`

1. `cart-fix-shipping` — feature + sub-área + acción.
2. `shipping-fix-cart` — reordenado, útil si `shipping` es el área principal.
3. `cart-bug-fix-shipping` — variante explícita del bug-fix.
```

## Anti-ejemplos (NO hacer)

- `Auth-Fix` → mayúsculas prohibidas.
- `cart_fix` → guion bajo prohibido.
- `auth-fix-` → guion final prohibido.
- `Pago-Stripe` → acentos y mayúsculas prohibidos.
- `added-login-feature` → comienza con verbo; debe comenzar con `feature`.
