---
name: angular-http-client
description: Integrate HttpClient, Interceptors, and API interactions in Angular. Use when integrating HttpClient, writing interceptors, or handling API calls in Angular.
metadata:
  triggers:
    files:
    - '**/*.service.ts'
    - '**/*.interceptor.ts'
    keywords:
    - HttpClient
    - HttpInterceptorFn
    - withInterceptors
    - httpResource
    - resource
---
# HTTP Client

## **Priority: P1 (HIGH)**

## Principles

- **Functional interceptors**: Prefer `HttpInterceptorFn` registered with `withInterceptors([...])`; Angular recommends this style for predictable ordering. DI-based class interceptors remain supported and may be retained in existing applications.
- **Typed responses**: Use `HttpClient` generics when the response contract is known. Generics are compile-time types, not runtime validation; treat untrusted payloads as `unknown` and validate them at the boundary when needed.
- **HTTP setup**: Configure `provideHttpClient()` in application providers. Add `withFetch()` when its Fetch backend fits the app (including SSR use cases); account for its lack of upload-progress events.
- **Service boundaries**: Put shared API access, transformations, and error policy in services. A component-local `httpResource` can be appropriate for data used only by that component; avoid forcing every request through a service.

## Signal-Based HTTP (Angular 19+)

Use `httpResource<T>()` when a read request should react to signal inputs and expose resource state. It re-fetches when its request expression changes:

```typescript
// Reactive: refetches automatically when userId() changes
userResource = httpResource<User>(() => `/api/users/${this.userId()}`);
// States: .isLoading() | .hasValue() | .error() | .value() | .reload()
```

Use `resource<T, P>({ request: () => params(), loader: ... })` for non-HTTP async work when its reactive request and loading state are useful. Use `HttpClient` directly for mutations or imperative requests where that is clearer.

## Guidelines

- **Caching**: Cache only requests whose semantics and invalidation are understood; interceptors and `shareReplay` are options, not automatic defaults.
- **Error handling**: Keep transport-level policy in services or interceptors, and handle user-specific presentation where the UI has the relevant context.
- **Context**: Use `HttpContext` to pass request metadata to interceptors, such as opting out of shared error handling or caching.

## Anti-Patterns

- **Blindly trusting response generics**: `http.get<User>()` does not validate a server response at runtime.
- **Unmanaged subscriptions**: Prefer `httpResource`, `toSignal`, or `AsyncPipe` for signal/template-bound reads. Imperative subscriptions are valid when their completion and cleanup are handled.
- **Over-centralizing requests**: Use a service when it provides a useful boundary; do not prohibit component-local resource usage categorically.

## References

- [Interceptors](references/interceptors.md)

## Canonical response anchors

When this skill applies, preserve the following domain terminology or equivalent concrete examples in the answer when relevant:
- Use services for shared HTTP policy; component-local resources can be appropriate.
- auto-refetches
- http.post<T>
- skip error handling

- Additional task-grounded exact anchors: notification service
