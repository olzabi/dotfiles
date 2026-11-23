import type { EngineInterface, Register } from 'claude-code'

// Subagent type → model, from roles.json beside this mod (keys starting with `_` are notes).
async function rolesOf($: EngineInterface): Promise<Record<string, string>> {
  try {
    const t = await $.fs.read(`${$.plugin.root}/roles.json`)
    const all = JSON.parse(typeof t === 'string' ? t : '') as Record<string, unknown>
    return Object.fromEntries(Object.entries(all).filter((e): e is [string, string] => !e[0].startsWith('_') && typeof e[1] === 'string' && !!e[1].trim()))
  } catch {
    return {} // no file or bad JSON: every agent keeps the engine's choice
  }
}

// A model the caller named wins; forks inherit by rule; a resumed or workflow run and a teammate keep their own.
export const register: Register = on => {
  on('agent.spawn', async ($, e, next) => {
    if (e.model || e.fork || e.resume || e.workflow || e.isTeammate) return next(e)
    const roles = await rolesOf($)
    const model = roles[e.subagentType] ?? roles['*']
    return next(model ? { ...e, model } : e)
  }).catch(($, e, next) => next(e))
}
