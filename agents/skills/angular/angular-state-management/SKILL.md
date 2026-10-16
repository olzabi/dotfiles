---
name: angular-state-management
description: Implement application state with Angular Signals, computed derivations, and NgRx Signal Store. Use when implementing reactive state with signal(), computed(), effect(), or @ngrx/signals in Angular.
metadata:
  triggers:
    files:
    - '**/*.store.ts'
    - '**/state/**'
    keywords:
    - angular signals
    - signal store
    - computed
    - effect
    - linkedSignal
---
# State Management

## **Priority: P1 (HIGH)**

## 1. Choose State Tools by Data Flow

- Signals work well for local UI state and synchronous derived values. Keep service-owned signals private and expose readonly views when consumers should not mutate them.
- Keep RxJS for asynchronous streams and operator-heavy composition where its stream model is useful; Signals and RxJS can interoperate.

See [signal store pattern](references/signal-store.md) for signal-based service and store examples.

## 2. Derive State with computed()

- Use `computed()` for totals, filtered lists, derived values — pure and cached.
- Use `linkedSignal(() => source())` for dependent writable state that resets when source changes.
- Use `untracked()` only when a read should intentionally not become a reactive dependency; do not use it to hide dependencies that should trigger recomputation.

## 3. Scale with Signal Store

- For complex features, use `@ngrx/signals` (`signalStore`) with `withState`, `withComputed`, `withMethods`, and `withEntities()`.

## 4. Handle Side Effects

- Use `effect()` to synchronize with external systems (logging, browser storage, or imperative APIs), not as the default mechanism for deriving application state.
- Avoid signal-to-signal state propagation in effects; use `computed()` or `linkedSignal()` for derivation. If an effect intentionally writes state in response to an external side effect, make the dependency explicit and prevent feedback loops.
- Treat object and array signal values immutably when updating with `.set()` or `.update()` so change tracking stays predictable.

## Anti-Patterns

- **Over-centralized state**: Keep simple component-local UI state local; move state to a service or Signal Store when it is shared or has meaningful domain behavior.
- **Forcing one reactive primitive**: `BehaviorSubject` remains valid when its stream semantics are useful. Prefer a Signal for straightforward synchronous state in signal-oriented code, not as a blanket replacement.

## References

- [Signal Store Pattern](references/signal-store.md)

