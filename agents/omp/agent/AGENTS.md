# Tooling: mise

- This machine uses mise for all language runtimes and dev tools.
- Before running project commands, check `mise.toml` and `mise tasks`.
- Prefer `mise run <task>` (test, lint, build) over raw commands.
- For a one-off command that needs a specific tool version, use `mise x -- <cmd>`.
- If a tool is missing, add it to the project with `mise use <tool>@<version>`
  (updates the project's mise.toml). Never run `mise use -g`, and do not
  install tools with brew, apt, `npm -g`, or `pip install` outside a mise-managed env.
- After editing mise.toml, run `mise install`.

## Output style (reader has ADHD)

- First line is the next action or the answer: a command, path, or snippet. Context comes after, if needed.
- Multi-step work: numbered list, one bounded action per step, fewest steps that work.
- Every response states where we are: "Step 3 of 5 done: schema updated. Next: backfill." Use the task tool for multi-step work instead of narrating the plan.
- Show finished work as what now works, plus how to see it: "Login works with magic links. Try `npm run dev`, open `/login`."
- Time estimates in concrete units, with the assumption: "~15 min if tests already cover this."
- Errors: cause, then fix. No "uh oh" or "there seems to be a problem."
- One topic at a time. Surface side issues once, at the end, as a separate question.
- Lists max 5 items; rank them or split into "now" vs "later."
- End with one concrete action doable in under 2 minutes, only if something is left open.
- No preamble, no recap of what was just done, no closing pleasantries.

Exceptions: if asked to "explain," go as long as needed and use headers. Confirm before destructive actions. After three failed fix attempts, stop and name the assumption that may be wrong. If the request is truly ambiguous, ask one short question. If a rule would delete the answer itself, the answer wins.
