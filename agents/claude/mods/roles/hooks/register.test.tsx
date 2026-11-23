import { expect, test } from 'claude-code/testing'

const ROLES = JSON.stringify({ _: 'note', Explore: 'haiku', Plan: 'opus' })
const spawn = (o: { subagentType: string; model?: string; fork?: boolean }) =>
  ({ tool_use_id: 't', prompt: 'p', description: 'd', provider: { plugin: 'engine', tier: 'core' }, parentModel: 'claude-opus-5-5', background: false, fork: false, ...o }) as never

test('a subagent gets its role\'s model; a named model, a fork and an unlisted type are left alone', async ($, on) => {
  on('fs.read', ($, e) => ({ value: e.path.endsWith('/roles.json') ? ROLES : '' }) as never)
  const seen: (string | undefined)[] = []
  on('agent.spawn', ($, e) => (seen.push(e.model), { agentId: `a${seen.length}`, model: e.model ?? 'parent' }) as never)

  await $.agent.spawn(spawn({ subagentType: 'Explore' }))
  await $.agent.spawn(spawn({ subagentType: 'Explore', model: 'sonnet' }))
  await $.agent.spawn(spawn({ subagentType: 'Plan' }))
  await $.agent.spawn(spawn({ subagentType: 'Explore', fork: true }))
  await $.agent.spawn(spawn({ subagentType: 'no-such-role' }))

  expect(seen).toEqual(['haiku', 'sonnet', 'opus', undefined, undefined])
})
