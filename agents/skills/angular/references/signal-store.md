# NgRx Signal Store

Use `@ngrx/signals` when the project already uses it or its composition and shared-state features justify the dependency. Simple local state can remain in a component or service; follow the project's established state model.

Compose a `signalStore` with `withState`, `withComputed`, and `withMethods` as needed; use `patchState` for updates and add entity features only when useful. Obtain injected dependencies in an injection context, such as the `withMethods` factory, rather than assuming a later method call has one. Use immutable object and array updates.

For Angular's built-in signal derivation and effects, see [signals-overview.md](signals-overview.md), [linked-signal.md](linked-signal.md), and [effects.md](effects.md).
