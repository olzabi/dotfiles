---
name: angular-ssr
description: Implement Angular SSR with hydration, TransferState caching, and per-route render modes. Use when configuring Angular Universal SSR, client hydration, static prerendering, or preventing double-fetching.
metadata:
  triggers:
    files:
    - '**/*.server.ts'
    - 'server.ts'
    keywords:
    - hydration
    - transferState
    - afterNextRender
    - isPlatformServer
    - RenderMode
---
# SSR (Server-Side Rendering)

## **Priority: P2 (MEDIUM)**

## 1. Enable Hydration

- Use `ng add @angular/ssr` to set up SSR for a CLI application.
- Add `provideClientHydration()` to application providers. Add `withEventReplay()` when replaying pre-hydration events is needed independently; incremental hydration enables event replay automatically.

See [hydration examples](references/hydration.md) for app config and hydration setup.

## 2. Guard Browser-Only Code

- Use `afterNextRender(() => { /* window access */ })` for one-time browser-only code.
- For recurring checks, inject `PLATFORM_ID` and use `isPlatformBrowser(platformId)`.

## 3. Prevent Double-Fetching

- Use `withHttpTransferCacheOptions()` or manual `TransferState` to cache server responses for client replay.

## 4. Configure Render Modes (Angular 17+)

Export `ServerRoute[]` in `app.routes.server.ts` and choose a mode per route:

- **RenderMode.Prerender** — Static HTML at build time for content that is safe and useful to publish.
- **RenderMode.Server** — Dynamic HTML per request when server rendering benefits the route.
- **RenderMode.Client** — Client-rendered SPA when SSR is not useful or practical for the route.

Authenticated routes may use SSR when the server securely establishes identity and authorization. Do not publicly cache personalized HTML; client rendering is a product/performance choice, not an access-control measure.

## 5. Incremental Hydration (Angular 19+)

- Enable incremental hydration with `withIncrementalHydration()` in `provideClientHydration(...)` before using `@defer (hydrate on viewport)` and other hydration triggers.
- Triggers include `viewport`, `interaction`, `idle`, `timer(ms)`, `immediate`, and `never`.
- Incremental hydration enables event replay automatically. Use `withEventReplay()` when event replay is needed without incremental hydration.

## Anti-Patterns

- **Unsafe server-only assumptions**: Use `afterNextRender()` for one-time browser-only work. Use `PLATFORM_ID` checks when recurring code genuinely needs a platform branch.
- **Unnecessary double-fetching**: Use the HTTP transfer cache or `TransferState` when its cache semantics fit the request.
- **Treating client rendering as security**: Protect data and operations with server-side authentication and authorization regardless of render mode.

## References

- [Hydration](references/hydration.md)
