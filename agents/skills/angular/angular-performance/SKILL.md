---
name: angular-performance
description: Optimization techniques including OnPush, @defer, and Image Optimization. Use when optimizing Angular rendering, deferring blocks, or improving Core Web Vitals.
metadata:
  triggers:
    keywords:
    - "@defer"
    - NgOptimizedImage
    - runOutsideAngular
    - OnPush
---
# Performance

## **Priority: P1 (HIGH)**

## Principles

- **Change detection**: OnPush is the default strategy in Angular 21+. Set it explicitly only when supporting older Angular versions or when the declaration makes project intent clearer. Keep template work cheap; use signals, `AsyncPipe`, and immutable data where they fit the data flow.
- **Deferrable Views**: Use `@defer` for substantial content that does not need to load immediately, such as below-the-fold widgets. Choose a trigger (`on viewport`, `on interaction`, `on idle`, or `when`) based on the user experience. Deferred dependencies must meet Angular's deferrable-view requirements. Use `@placeholder` for meaningful loading states.
- **Images**: Prefer `NgOptimizedImage` for application images where its sizing and loading behavior help. Provide dimensions, and mark only the actual LCP image as `priority`.

## Guidelines

- **Zoneless**: Zoneless change detection is the default in Angular 21+. Do not add `provideExperimentalZonelessChangeDetection()`; it is obsolete. For Angular 20 opt-in projects, use the API documented for that version. Use `runOutsideAngular` only when a measured high-frequency callback benefits from it, not as a default optimization.
- **Lists**: Give `@for` a stable, unique `track` expression when the data has a stable identity. Use `$index` only for static or append-only lists where index tracking is appropriate.
- **Derived work**: Use `computed()` for signal-derived values and pure pipes for reusable pure transformations. Template methods are evaluated during change detection, so avoid expensive or side-effecting calls; small, pure helpers can be appropriate.

## Anti-Patterns

- **Expensive template work**: Move expensive derived calculations into `computed()` or a pure pipe so the work is cached or reused appropriately.
- **Constructor side effects**: Keep constructors focused on dependency injection and simple field initialization. Put lifecycle-dependent work in the appropriate lifecycle/render hook.

## References

- [Defer Usage](references/defer-usage.md)

## Canonical response anchors

When this skill applies, preserve the following domain terminology or equivalent concrete examples in the answer when relevant:
- caches until dependencies change
- computed() signal
- priority attribute
- re-evaluates on every change detection
- replaces trackBy
- srcset

- Additional task-grounded exact anchors: Signals when they fit the state model; @for (item of items; track item.id); stable unique identifier
