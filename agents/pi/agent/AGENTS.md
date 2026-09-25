# Shared agent defaults

These defaults apply across repositories and clients. Use the current client's equivalent
when a named tool is unavailable. A repository's own `AGENTS.md` adds project-specific
commands and constraints.

## General

- Be concise and explicit.
- Read relevant files before editing.
- Prefer small, reviewable changes.
- State assumptions when uncertain.
- Treat public API or visibility widening as a design change; avoid it unless required and call it out explicitly.
- Comment non-obvious intent, constraints, and trade-offs, not mechanics already clear from the code.
- Prefer explicit tools and visible context over invisible automation.
- Search for equivalent behavior before adding a helper, component, migration, or abstraction.
- Reuse or improve the canonical implementation instead of introducing a near-duplicate.
- Remove incidental dead code or duplication only when clearly in scope.
- Do not self-defer requested work into an invented phase or version.
- Prefer the minimum implementation that solves the request; avoid speculative abstractions and unrelated cleanup.
- Use rg over grep.

## Discovery and code intelligence

Use the tool that matches the question:

- Prefer the current client's registered path and text-search tools (`fffind` and `ffgrep` in Pi).
- For Pi project orientation, use `project_report`, then `symbol_search` → `module_report` → `read_symbol` or `read_enclosing`.
- For semantic definitions, references, or implementations, use the current client's navigation capability (`lsp_navigation` in Pi) when available.
- Use `codebase-memory_*` tools for architecture, call relationships, data flow, impact analysis, and graph queries when the current client exposes them. Check index coverage before making exhaustive or negative claims; grep files marked partial or skipped.
- Use AST-grep tools for structural searches or replacements when available; otherwise use the current client's language-aware structural search.
- Do not assume that tools named `subagent_list`, `implement`, `chain`, `sem_diff`, or generic `lsp_*` aliases are available. Use the registered tools for the current client.

## Editing and validation

- Read the target file or relevant symbol before editing it.
- Use the current client's focused edit and write tools; in Pi, prefer `edit` for focused textual changes and `write` for intentional whole-file replacement. Use AST-grep replacement for structural changes when available.
- Resolve blocking diagnostics from the current client before completion. Treat advisories separately from blockers, but do not ignore security or secret findings.
- Run focused tests first, then the relevant project checks. Report failures and pre-existing failures separately.

## Pi runtime behavior

These rules apply when working in the Pi environment configured by this directory. Extension versions belong in
`npm/package.json`; do not duplicate them here.

- `@aliou/pi-guardrails` may block secret-file access, outside-workspace access, or dangerous shell commands. Do not route around a guardrail; inspect the reason and ask for explicit approval when a legitimate exception is needed.
- `pi-rtk-optimizer` rewrites and compacts model-visible Bash output, including test, build, Git, lint, and search output. `pi-tool-display` separately summarizes or collapses tool output for the interface. A compacted or summarized result is not evidence that all output was inspected; use targeted commands or inspect files directly when exact output matters.
- `pi-lens` can inject diagnostics and test findings at turn end. Treat injected findings as machine-generated work feedback, resolve blockers, and use `lens_diagnostics` as the authoritative diagnostic source.
- Pi Lens may format or autofix files after a write or edit. Treat the post-fix content as authoritative; after an `edit`, re-read the file before editing again.
- In Pi, after changing source, run `lens_diagnostics` with an LSP probe on the changed paths before declaring the work complete. Use a full scan when the result is `partial`, `stale`, `cold`, `unconfirmed`, or `truncated`; an empty cached result is not proof of a clean file.
- `@ff-labs/pi-fff` provides the preferred `fffind` and `ffgrep` search tools.
- `pi-mcp-adapter` exposes MCP tools.
- `pi-headroom` may start a local proxy service. Do not interpret proxy startup, provider limits, or cache behavior as application failures without checking the actual command result.
- Several context layers may be active at once: native Pi compaction, `pi-observational-memory`, `pi-context-prune`, `pi-context`, and `context-mode`. Use `context_checkpoint`, `context_timeline`, and `context_compact` to manage conversation state; these do not roll back files or external side effects.
- Use `ctx_execute` or `ctx_execute_file` for large command output, logs, test output, and data processing so raw output does not consume the conversation context.
- Use the persistent `todo` tool for work with three or more steps. Keep exactly one task in progress, mark it complete immediately when verified, and do not mark failing or partial work complete.
- Use `pi-memory` only for durable decisions, preferences, lessons, or user-requested memories; do not store transient debugging output.

## Delegation

- Delegate non-trivial exploration, implementation, or review when it reduces context or provides a useful specialist perspective. Do not delegate trivial reads, exact searches, or one-file edits.
- Use the current client's registered delegation mechanism. In Pi, the available agent types include `Explore`, `Plan`, and `general-purpose`.
- In Pi, use `Agent` for a small number of delegated tasks. Use `SubagentWorkflow` only when the user explicitly requests workflow orchestration and the work genuinely needs staged execution.
- Give each delegated task an explicit scope, expected output, and side-effect boundary. Use worktree isolation for independent parallel edits; otherwise keep shared-file integration serial.
- Independently verify delegated work by inspecting the resulting diff and running the relevant checks. Do not report an agent's intended changes as completed changes.

## Design and implementation

- When a request allows materially different implementations, briefly identify the options and trade-offs before making a non-trivial change.
- Prefer pure functions and explicit inputs and outputs when they make behavior easier to test and change.
- Model multi-step or event-driven logic as an explicit state machine when the transitions matter.
- Use TDD for non-trivial, testable behavior; pin the contract with a failing test before implementation when practical.
- Leave touched code easier to understand without turning focused work into a speculative refactor.
