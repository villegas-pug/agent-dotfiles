import { type Plugin, tool } from "@opencode-ai/plugin"

// Formato validado por la skill session-rename: feature-action o feature-context-action.
const TITLE_PATTERN = /^[a-z]+(-[a-z]+){1,2}$/

// Solo renombra la sesión actual (context.sessionID). No acepta IDs por argumento.
export const SessionRenamePlugin: Plugin = async ({ client }) => {
  return {
    tool: {
      session_rename: tool({
        description: "Aplica el título de la sesión actual. Formato feature-action en minúsculas, separado por guiones.",
        args: {
          title: tool.schema.string().regex(TITLE_PATTERN).max(40),
        },
        async execute(args, context) {
          const { error } = await client.session.update({
            path: { id: context.sessionID },
            body: { title: args.title },
          })
          if (error) throw new Error(`No se pudo renombrar la sesión: ${JSON.stringify(error)}`)
          return `Título aplicado: ${args.title}`
        },
      }),
    },
  }
}
