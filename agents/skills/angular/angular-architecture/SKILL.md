---
name: angular-architecture
description: Standards for Angular project structure, feature modules, and lazy loading. Use when structuring Angular apps, defining feature modules, or configuring lazy loading.
metadata:
  triggers:
    files:
      - "angular.json"
      - "**/app.config.ts"
      - "**/*.routes.ts"
    keywords:
      - angular components
      - standalone
      - feature module
      - lazy loading
      - loadComponent
      - loadChildren
---

# Angular Architecture

## **Priority: P0 (CRITICAL)**

## Principles

- **Feature-based organization**: Group code by the business capability it supports. A feature folder can contain its routes, components, services, and models; use LIFT (Locate, Identify, Flat structure, Try DRY) as a guide, not a rigid folder specification.
- **Standalone first**: Standalone is the default for components, pipes, and directives in Angular 19+. Prefer standalone APIs for new code. NgModules remain supported for existing applications and library interop; do not migrate solely to remove every NgModule.
- **Shared boundaries**: `core/`, `shared/`, and `features/` are useful conventions, not required Angular folders. Keep app-wide providers separate from genuinely reusable UI, and avoid turning `shared/` into a catch-all.
- **Component boundaries**: A Smart (Container)/Dumb (Presentational) split can improve testability and clarify ownership, but use it only when it reduces coupling or complexity.

## Guidelines

- **Route loading**: Use `loadComponent` or `loadChildren` for substantial features that should not increase the initial bundle. Eager loading can be appropriate for the small critical path or features needed immediately; choose based on startup cost and navigation behavior.
- **Flat structure**: Avoid unnecessary directory depth; organize around feature ownership rather than mandatory top-level `components/` and `services/` folders.
- **Barrel files**: Use barrels for intentional public APIs. Prefer direct imports when they make dependencies clearer; modern bundlers generally handle barrels, so do not promise tree-shaking gains without evidence.

## Verification Checklist

- [ ] Are feature boundaries clear and easy to navigate?
- [ ] Are standalone APIs used for new code where appropriate?
- [ ] Are large or infrequently used features loaded lazily where that benefits the initial bundle?
- [ ] Are shared providers and reusable UI placed according to the application's conventions?

## Anti-Patterns

- **Unnecessary NgModule use in new code**: Prefer standalone APIs for new components and features, while retaining modules where existing architecture or interop requires them.
- **Unnecessary eager imports**: Avoid pulling substantial, rarely used features into the initial bundle without a reason.
- **Type-based top-level folders by default**: Prefer feature ownership when it improves discoverability; follow the host application's established structure when it is clearer.

## References

- [Folder Structure](references/folder-structure.md)
