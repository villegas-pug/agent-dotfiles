# Global Agent Rules

## Idioma
- Responde, documenta, planifica y razona SIEMPRE en español
- Excepción: nombres de variables, funciones, clases, archivos, rutas, comandos de terminal y código fuente se mantienen en inglés técnico
- Comentarios en código: español
- Mensajes de commit: español
- Aplica a: respuestas, análisis, specs, skills, definiciones de agentes y subagentes, documentación generada

## No compilar ni ejecutar builds
- Al terminar de escribir o modificar código, NO ejecutes comandos de compilación, empaquetado ni pruebas automáticas
- Prohibido sin instrucción explícita del usuario:
  - `npm run build` / `npm run dev` / `npm test` / `npx` con scripts de build
  - `yarn build` / `pnpm build`
  - `mvn package` / `mvn install` / `gradle build`
  - `java -jar` / `javac`
  - `go build` / `cargo build` / `dotnet build`
  - `pytest` / `jest` / `mocha` / cualquier test runner
  - `docker build` / `docker compose up`
- Sí permitido: linters (`eslint`, `ruff`, `golangci-lint`), formatters (`prettier`, `gofmt`), verificación de tipos (`tsc --noEmit`)
- Si el usuario pide verificar que algo funciona, pregunta antes de compilar o ejecutar

## Generación de documentos (SPECS, SKILLS, AGENTS, SUBAGENTS, COMMANDS)
- Todo el contenido descriptivo, funcional y de criterios de aceptación: en español
- Nombres de archivo, headings técnicos estándar (`## Overview`, `## Usage`) y frontmatter keys: pueden quedar en inglés
- Las descripciones en frontmatter (`description:`) se escriben en español

## rovidev Vault
- Al inicio, usa el contexto de solo lectura inyectado por el plugin global `rovidev-vault.ts`.
- Si el repositorio no está registrado, no descubras ni registres proyectos automáticamente; informa que requiere `vault-project register`.
- El repositorio es autoridad para código, especificaciones, pruebas y configuración. El Vault conserva continuidad y decisiones aprobadas.
- Antes de cerrar trabajo material, usa `vault-session` para mostrar una propuesta. Escribe en el Vault solo con aprobación explícita del usuario en el turno actual.
