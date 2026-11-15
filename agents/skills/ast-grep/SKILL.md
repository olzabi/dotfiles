---
name: ast-grep
description: Structural search, codemods and lint rules with ast-grep (`ast-grep`/`sg`). Use when a change must be applied to many call sites or code shapes at once, when text search is noisy because the match depends on syntax (arguments, nesting, missing try/catch, a call inside a class), or when writing a project lint rule. Not for who-calls-what, call chains, impact or dead code: that is the codebase-memory graph.
---

# ast-grep

ast-grep matches code by its syntax tree (tree-sitter). A pattern matches regardless of whitespace and line breaks, never matches inside strings or comments, and can rewrite what it matches with captured pieces.

## Pick the tool

| Question | Tool |
| --- | --- |
| Who calls X, what X calls, impact of a diff, dead code, architecture | codebase-memory graph (`trace_path`, `search_graph`, `detect_changes`) |
| Where does this text, name, string or config key appear | `rg` (Grep) |
| Find code of a given **shape**: `foo($A, $B)` with two args, `await` outside `try`, `console.log` inside a method | `ast-grep run -p` / `scan --inline-rules` |
| Change many call sites or shapes the same way | `ast-grep run -p … -r … -U` |
| One or two edits | the normal edit tool |
| A rule the project should keep enforcing | rule file + `ast-grep scan`, or an oxlint rule if the project lints with oxlint |

Use the graph to find *which* symbols are affected, then ast-grep to rewrite their call sites. Do not use ast-grep to answer relationship questions: it sees one file's syntax and resolves no imports, types or re-exports.

## Search

```bash
ast-grep run -p 'foo($A, $B)' -l ts src/          # $A: one node
ast-grep run -p 'foo($$$ARGS)' -l ts src/          # $$$: zero or more nodes
ast-grep run -p 'foo($A)' -l ts --json=compact .   # machine-readable; [] means no match
```

- Always pass `-l <lang>` (ts, tsx, js, py, go, rust, sh, …); `.tsx` needs `tsx`, not `ts`.
- A pattern must be a complete node. `env::var($E)` does not match `std::env::var("X")`; try both forms or absorb the prefix with `$$$`.
- Zero matches: run the pattern on a snippet that contains the code, and inspect how it parses with `--debug-query=pattern` (or `=ast` on the target code) to find the right shape or `kind`.

## Rewrite (the main reason to use it)

```bash
ast-grep run -p 'foo($A, $B)' -r 'bar($B, $A)' -l ts src/     # dry run: prints a diff
ast-grep run -p 'foo($A, $B)' -r 'bar($B, $A)' -l ts -U src/  # apply all
```

1. Dry run first and read the diff; count the matches against what you expected.
2. Apply with `-U`, then run the project's formatter, typecheck and tests. ast-grep keeps captured text verbatim but does not reformat the rest.
3. Never use `-i` (interactive): it needs a TTY.

## Relational and negative queries

Use an inline rule when a pattern alone cannot express the shape:

```bash
ast-grep scan --inline-rules 'id: await-without-try
language: ts
rule:
  pattern: await $E
  not:
    inside:
      kind: try_statement
      stopBy: end' src/
```

- Put `stopBy: end` on every `inside` / `has`; without it the search stops at the nearest parent and misses most matches.
- Combine with `all`, `any`, `not`. Add `fix:` to a rule to rewrite with it (`scan --inline-rules … -U`).
- Single-quote the rule so the shell keeps `$E`; inside double quotes write `\$E`.

## Gotchas

- Rewriting changes code text, not meaning: renamed exports, overloads and dynamic access (`obj[name]()`) are invisible to it. Cross-check the symbol list with the graph or the compiler.
- Generated files and `node_modules` are skipped only through `.gitignore`; pass explicit paths when in doubt.
- Full rule reference: `https://ast-grep.github.io/llms.txt` (fetch the one page you need).
