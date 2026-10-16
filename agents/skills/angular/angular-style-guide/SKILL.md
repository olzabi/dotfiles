---
name: angular-style-guide
description: Naming conventions, file structure, and coding standards for Angular projects. Use for Angular-specific naming and organization; defer language-only TypeScript naming questions.
metadata:
  triggers:
    keywords:
    - angular style
    - naming convention
    - file structure
    - angular-style-guide
---
# Angular Style Guide

## **Priority: P0 (CRITICAL)**

## Principles

- **Single responsibility**: Keep each file focused. Split code when its responsibilities make it hard to understand, test, or change; line counts are a prompt to review, not a rule.
- **Naming**: Use clear, consistent names that match the feature or exported symbol. Angular's current style guide uses hyphenated feature names such as `user-profile.ts`; type suffixes such as `.component.ts` are optional, not required.
- **Barrels**: Use `index.ts` for intentional public APIs. Prefer direct imports when they make dependencies clearer; do not assume barrels inherently break tree-shaking.
- **LIFT**: Use Locate, Identify, Flat structure, Try DRY as a discoverability heuristic rather than a fixed folder-depth limit.

## Naming Standards

- **Files**: Prefer hyphenated names based on the feature or primary exported symbol, such as `user-profile.ts`, `user-profile.html`, and `user-profile.spec.ts`. Keep templates, styles, and tests easy to associate with their component.
- **Classes**: Use PascalCase and clear domain names. A type suffix such as `Component`, `Service`, or `Pipe` is optional when it improves clarity or matches the project convention.
- **Directives**: Use a descriptive selector with the application's prefix where appropriate (for example, `appHighlight`).
- **Pipes**: Use a concise, descriptive pipe name (for example, `truncate`).
- **Interfaces**: Prefer domain nouns such as `User` or `Hero`; avoid an `I` prefix unless the surrounding codebase has an established convention.

## Folder Structure

- Organize by feature when it improves discoverability. `core/`, `shared/`, and `features/` are optional conventions, not Angular requirements.
- Keep nesting as shallow as is practical, without enforcing a fixed maximum depth.

## Anti-Patterns

- **Unclear ownership**: Avoid scattering one feature across unrelated folders when grouping it would make changes easier to locate.
- **Rigid size or suffix rules**: Do not split files or add type suffixes solely to meet arbitrary line counts or naming rules.
- **Template work**: Keep template expressions simple and side-effect-free; move expensive derived work into appropriate component logic or a pure pipe.

## References

- [Naming Conventions](references/naming-convention.md)

