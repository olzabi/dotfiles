---
name: angular-components
description: Build Angular components with standalone APIs, signal inputs and outputs, built-in control flow, and appropriate change detection. Use when creating components, templates, or component state.
metadata:
  triggers:
    files:
    - '**/*.component.ts'
    - '**/*.component.html'
    keywords:
    - angular component
    - standalone
    - input signal
    - output
    - "@if"
    - "@for"
    - ChangeDetectionStrategy
    - OnPush
    - Input
    - Output
---
# Angular Components

## **Priority: P0 (CRITICAL)**

## Standalone & Structure

- **Standalone**: Standalone is the default for components, directives, and pipes in Angular 19+. Import dependencies in the component's `imports` when needed. Prefer standalone for new code; existing NgModule-based code remains supported and can interoperate.
- **Component boundaries**: A container/presentational split can help when it clarifies data flow, but it is not required for every feature. Keep dependencies and state at the narrowest useful scope.
- **Host bindings**: Prefer the `host` metadata property for new host bindings. Existing `@HostBinding` and `@HostListener` code remains supported.
- **View Encapsulation**: Default `Emulated`. Use `None` carefully.

## Signals & Change Detection

- **OnPush**: OnPush is the default change-detection strategy in Angular 21+. An explicit `changeDetection` setting is optional unless supporting an older version or documenting intent.
- **Signal Inputs**: Prefer `input.required<T>()` or `input<T>()` for signal-oriented new code. Decorator-based `@Input()` remains supported. Access signal inputs as functions, such as `userId()`; use `booleanAttribute` or `numberAttribute` transforms when appropriate.
- **Signal Outputs**: Prefer `output<T>()` for new code; `@Output() EventEmitter` remains supported. Use `model()` when a two-way bindable input/output pair is appropriate.
- **State**: Use `signal()` for local writable state and `computed()` for derived state. Reserve `effect()` primarily for synchronizing with external side effects rather than propagating derived state.
- **Cleanup**: For template-bound streams, prefer `AsyncPipe` or `toSignal()`. For imperative subscriptions, use a finite stream or clean up with `takeUntilDestroyed()` or `DestroyRef`.

## Control Flow

- Use `@if (condition)`, `@for (item of items; track item.id)`, `@switch`, `@empty { }` instead of `*ngIf`/`*ngFor` (new control flow syntax, Angular 17+).

## Anti-Patterns

- **Expensive or impure template expressions**: Keep template work cheap and side-effect-free; use `computed()` for signal-derived values when appropriate.
- **Unmanaged long-lived subscriptions**: Prefer `AsyncPipe` or `toSignal()` for rendered streams, and clean up imperative subscriptions.
- **Unnecessary direct DOM access**: Prefer template bindings and directives; use browser APIs only when the use case requires them and account for SSR.
- **Unnecessary inheritance**: Prefer composition when it keeps component behavior easier to understand and test.

## References

- [Standalone Pattern](references/standalone-pattern.md)
- [Control Flow](references/control-flow.md)

## Canonical response anchors

When this skill applies, preserve the following domain terminology or equivalent concrete examples in the answer when relevant:
- @empty { }
- Prefer `host` metadata for new host bindings; legacy decorators remain supported.
- Signal inputs
- inputs and emit events via outputs

- Additional task-grounded exact anchors: @if (condition); @for (item of items; track item.id); booleanAttribute; model(); Smart (Container); toSignal()
