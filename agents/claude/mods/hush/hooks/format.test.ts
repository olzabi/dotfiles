import { expect, test } from 'claude-code/testing'

import { compactDiff, groupMatches, jsonToToon, mcpPreview, mentions, outline, toToon, touched } from './format'

test('grep -rn lines group under one filename header per file', () => {
  const out = ['src/a.ts:3:const x = 1', 'src/a.ts:9:x += 1', 'src/b.ts:12:use(x): ok'].join('\n')

  expect(groupMatches(out)).toEqual(['src/a.ts', '  3: const x = 1', '  9: x += 1', 'src/b.ts', '  12: use(x): ok'])
})

test('ordinary output is not grep output', () => {
  expect(groupMatches('total 4\ndrwxr-xr-x 2 me me 4096 Oct 31 18:00 .')).toBeNull()
  expect(groupMatches('only one: 1: line')).toBeNull()
})

test('an MCP result of JSON text is pretty-printed and capped with a [...] marker', () => {
  const output = [{ type: 'text', text: '{"a":1,"b":{"c":[1,2]}}' }]

  expect(mcpPreview(output, 3)).toEqual(['{', '  "a": 1,', '  "b": { [...]'])
})

test('an MCP result of plain text keeps its lines; an unknown shape is left to the engine', () => {
  expect(mcpPreview('hello\nworld', 5)).toEqual(['hello', 'world'])
  expect(mcpPreview([{ type: 'image', data: 'xx' }], 5)).toBeNull()
  expect(mcpPreview({ weird: true }, 5)).toBeNull()
})

test('TOON: objects, primitive lists, tables of flat records and mixed lists', () => {
  const v = {
    id: 7, name: 'Ada', tags: ['x', 'y z'], empty: {},
    rows: [{ a: 1, b: 'p, q' }, { a: 2, b: null }],
    mixed: [1, { k: true }],
    nested: { deep: { s: '42' } },
  }
  expect(toToon(v)).toBe([
    'id: 7', 'name: Ada', 'tags[2]: x,y z', 'empty: {}',
    'rows[2]{a,b}:', '  1,"p, q"', '  2,null',
    'mixed[2]:', '  - 1', '  - k: true',
    'nested:', '  deep:', '    s: "42"',
  ].join('\n'))
  expect(toToon([{ a: 1 }, { a: 2 }])).toBe('[2]{a}:\n  1\n  2')
})

test('jsonToToon leaves non-JSON and short JSON alone', () => {
  expect(jsonToToon('plain text')).toBeNull()
  expect(jsonToToon('[]')).toBeNull()
  expect(jsonToToon(JSON.stringify({ items: [{ id: 1, name: 'one' }, { id: 2, name: 'two' }] }, null, 2)))
    .toBe('items[2]{id,name}:\n  1,one\n  2,two')
})

test('outline lists declarations with line numbers, nested by indent, no control flow', () => {
  const src = [
    'import x from "y"',
    'export class Shop extends Base {',
    '  total(items: Item[]): number {',
    '    if (items) {',
    '    }',
    '  }',
    '}',
    'const add = (a, b) => a + b',
    'def helper(x):',
  ].join('\n')
  expect(outline(src, 'a.ts', 10)).toEqual([
    '  11 export class Shop extends Base',
    '  12   total(items: Item[]): number',
    '  17 const add = (a, b) =>',
    '  18 def helper(x)',
  ])
  expect(outline('# Title\ntext\n## Part', 'README.md')).toEqual(['   1 # Title', '   3   ## Part'])
})

test('touched names the enclosing declaration of each hunk and any it adds', () => {
  const original = ['class A {', '  run() {', '    go()', '  }', '}'].join('\n')
  const hunks = [{ oldStart: 2, newStart: 2, lines: [' ' + '  run() {', '-    go()', '+    go(1)', '+  stop() {'] }]
  expect(touched(original, hunks, 'a.ts')).toEqual(['run()', 'stop()'])
})

test('mentions finds @@names outside code, once each', () => {
  expect(mentions('ask @@Explore and @@plugin-dev:agent-creator, not `@@Plan`, again @@Explore')).toEqual([
    'Explore', 'plugin-dev:agent-creator',
  ])
  expect(mentions('mail a@@b')).toEqual([])
})

test('a compact diff keeps changed lines alone, numbered, dedented, one gap between hunks', () => {
  const hunks = [
    { oldStart: 2, newStart: 2, lines: ['   run() {', '-    go()', '+    go(1)', '   }'] },
    { oldStart: 120, newStart: 120, lines: ['   a', '-  b', '   c'] },
  ]

  expect(compactDiff('a.ts', hunks)).toEqual([
    { text: 'a.ts +1 -2', kind: 'head' },
    { text: '  3 -   go()', kind: 'del' },
    { text: '  3 +   go(1)', kind: 'add' },
    { text: '···', kind: 'gap' },
    { text: '121 - b', kind: 'del' },
  ])
})
