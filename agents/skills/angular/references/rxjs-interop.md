# RxJS and signal interop

Choose signals for synchronous state and derived values; retain Observables for streams and operator-based asynchronous composition where useful.

- `toSignal(observable$)` subscribes immediately and normally cleans up with its injection context. Call it once and reuse the result. Supply `initialValue` when a meaningful initial value exists, or account for `undefined` until the first emission; use `requireSync` only when the source guarantees a synchronous emission. An Observable error is thrown when the signal is read, so model or handle errors explicitly.
- `toObservable(signal)` exposes signal changes to RxJS operators such as `debounceTime` and `switchMap`. Use an injection context or pass an injector as supported by the target version.
- For imperative subscriptions, use finite streams or `takeUntilDestroyed()` in an injection context. Outside one, pass a `DestroyRef` obtained in an injection context. For template-bound streams, `AsyncPipe` is also an option.
- Distinguish loading, empty, and error states when the UI needs them. Replace an HTTP error with an empty result only when that is the intended behavior.
