---
name: angular-routing
description: Configure Angular Router with deliberate route loading, functional guards, component input binding, and resolvers. Use when defining routes, navigation, or route-level data and access behavior.
metadata:
  triggers:
    files:
    - '**/*.routes.ts'
    - '**/routes.ts'
    keywords:
    - angular router
    - provideRouter
    - RouterLink
    - RouterOutlet
    - withComponentInputBinding
    - loadComponent
    - loadChildren
    - CanActivateFn
    - CanDeactivateFn
    - ResolveFn
    - canActivate
    - resolver
---
# Routing

## **Priority: P0 (CRITICAL)**

## 1. Choose Route Loading Deliberately

- Use `loadComponent` or `loadChildren` when a route boundary should split substantial or infrequently used features from the initial bundle. Eager routes are reasonable for small features needed immediately; base the choice on bundle size and navigation behavior.

See [routing patterns](references/routing-patterns.md) for lazy loading and guard examples.

## 2. Use Functional Guards

- Prefer function-based guards (`CanActivateFn`, `CanMatchFn`, and related functional APIs) for new code. Class-based guard interfaces are deprecated; existing implementations can be migrated when appropriate.
- Guards control client-side navigation and user experience only. Enforce authorization on the server for protected data and operations.

See [routing patterns](references/routing-patterns.md) for functional guard implementation.

## 3. Enable Component Input Binding

- Configure `withComponentInputBinding()` in `provideRouter(routes, withComponentInputBinding())`.
- Define `input.required<string>()` in components — Angular auto-maps route params, query params, and resolve data.

## 4. Configure Resolvers and Titles

- Create `ResolveFn<T>` to pre-fetch critical data before navigation.
- Provide custom `TitleStrategy` or use `title: 'Dashboard'` in route data.

## Anti-Patterns

- **Overloaded route configuration**: Keep route declarations readable; move reusable authorization checks and navigation-critical data resolution into guards or resolvers when that improves separation.
- **Unnecessary eager loading**: Avoid putting large, rarely used features in the initial bundle without a reason, but do not lazy-load every route mechanically.

## References

- [Routing Patterns](references/routing-patterns.md)

