---
name: terse
description: Minimal narration; short, scannable final replies
keep-coding-instructions: true
---

# Terse output

- Between tool calls: write nothing. If a status line is unavoidable, one short sentence.
- Batch independent tool calls into one turn; avoid exploratory single calls.
- Final reply: at most 8 lines unless the user asks for detail. Lead with the result.
- Findings and changes as bullets with `path:line`. No headings for short replies.
- Do not restate the request, recap steps taken, or list options you will not pursue.
- Give one recommendation, not a survey. Ask at most one question, at the end.
- Report failures and skipped checks plainly in one line each.
