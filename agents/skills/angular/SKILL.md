---
name: angular
description: Entry point for Angular implementation, debugging, review, architecture, and framework questions. Route each task to the relevant nested Angular skill before acting.
---

# Angular Skill Router

Use this skill as the entry point, then load only the focused skill or skills needed for the task.

1. Read [`INDEX.md`](INDEX.md) and select the relevant skill(s) before acting.
2. For a request to create a new Angular application, load `angular-new-app/SKILL.md` first. Add `angular-tooling/SKILL.md` only for separate CLI, workspace, or build-configuration work.
3. For work in an existing Angular application, prefer the focused domain skill(s) mapped in the index. Usually one is enough; add another only for a real cross-cutting concern.
4. Use `angular-developer/SKILL.md` as the broad fallback for Angular questions that span several domains or do not fit a focused skill. Do not load it alongside a focused skill for the same topic; where guidance overlaps, the focused skill and the target project's conventions take precedence.
5. Follow the target project's Angular version and existing conventions when guidance is version-specific or the project differs from an example.

Treat Angular application TypeScript as Angular/bundler-managed code. Load the general Node skill only for a concrete Node.js runtime concern, such as a standalone Node script or custom Node server code; Angular CLI use or SSR alone is not a reason to apply Node type-stripping guidance.

If the task is Angular-related but no skill clearly matches, use `angular-developer` as the fallback and inspect the relevant references it links to.
