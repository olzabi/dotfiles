# Angular Skills Index

## Nested Skill Map

The focused skills listed below are the router's normal destinations. `angular-new-app` is the entry for creating an application; `angular-developer` is the broad fallback for cross-domain or otherwise uncovered Angular questions. Prefer focused skills for a matching domain, and follow them over overlapping fallback guidance. Links below are relative to this index. A matched skill's `references/` links are relative to that leaf directory. Use file names as hints only—current Angular projects do not have to use type suffixes such as `.component.ts`.

| Skill ID | Source | Route here for |
| --- | --- | --- |
| `angular-architecture` | [SKILL.md](angular-architecture/SKILL.md) | Feature boundaries, standalone-first structure, NgModule interop, lazy-loading decisions, and project folders. |
| `angular-new-app` | [SKILL.md](angular-new-app/SKILL.md) | Creating a new Angular application. |
| `angular-developer` | [SKILL.md](angular-developer/SKILL.md) | Broad Angular guidance when a task spans domains or no focused skill applies. |
| `angular-components` | [SKILL.md](angular-components/SKILL.md) | Components, templates, signal inputs/outputs, change detection, and built-in control flow. |
| `angular-dependency-injection` | [SKILL.md](angular-dependency-injection/SKILL.md) | `inject()`, providers, injection tokens, and application initializers. |
| `angular-directives-pipes` | [SKILL.md](angular-directives-pipes/SKILL.md) | Attribute directives, host directives, and pure pipes. |
| `angular-forms` | [SKILL.md](angular-forms/SKILL.md) | Typed Reactive Forms, Signal Forms, form controls, and validation. |
| `angular-http-client` | [SKILL.md](angular-http-client/SKILL.md) | `HttpClient`, `httpResource`, interceptors, and HTTP testing or error policy. |
| `angular-performance` | [SKILL.md](angular-performance/SKILL.md) | Rendering costs, `@defer`, image optimization, and change-detection performance. |
| `angular-routing` | [SKILL.md](angular-routing/SKILL.md) | Route definitions, lazy loading, functional guards, resolvers, titles, and route-to-component binding. |
| `angular-rxjs-interop` | [SKILL.md](angular-rxjs-interop/SKILL.md) | `toSignal`, `toObservable`, `takeUntilDestroyed`, and choosing between streams and signals. |
| `angular-security` | [SKILL.md](angular-security/SKILL.md) | XSS, sanitization, CSP, credential handling, and client-side route protection. |
| `angular-ssr` | [SKILL.md](angular-ssr/SKILL.md) | SSR, render modes, hydration, transfer caching, and browser-only code. |
| `angular-state-management` | [SKILL.md](angular-state-management/SKILL.md) | Signals, derived state, effects, and NgRx Signal Store. |
| `angular-style-guide` | [SKILL.md](angular-style-guide/SKILL.md) | Angular naming, file organization, and project conventions. |
| `angular-testing` | [SKILL.md](angular-testing/SKILL.md) | TestBed, component harnesses, HTTP tests, and test-runner setup. |
| `angular-tooling` | [SKILL.md](angular-tooling/SKILL.md) | Angular CLI commands, workspace/build configuration, and bundle analysis. |

## File and Topic Routing Hints

| File or topic hint | Skill IDs |
| --- | --- |
| `angular.json`, `app.config.ts`, feature boundaries, standalone migration | `angular-architecture`, `angular-tooling` |
| `*.component.ts`, component templates, `@Component`, signal inputs/outputs, `@if`, `@for` | `angular-components`; add `angular-performance` for measured rendering concerns |
| `*.service.ts`, `inject()`, providers, injection tokens, `provideAppInitializer` | `angular-dependency-injection`; add `angular-http-client` when the service uses HTTP |
| `*.directive.ts`, `*.pipe.ts`, `hostDirectives`, `PipeTransform` | `angular-directives-pipes` |
| `FormGroup`, `FormControl`, validators, typed forms, Signal Forms | `angular-forms` |
| `HttpClient`, `httpResource`, `HttpInterceptorFn`, `withInterceptors` | `angular-http-client` |
| `@defer`, `NgOptimizedImage`, LCP, change-detection profiling | `angular-performance` |
| `**/*.routes.ts`, `**/routes.ts`, `provideRouter`, `RouterLink`, `RouterOutlet`, `CanActivateFn`, `ResolveFn` | `angular-routing`; add `angular-security` when discussing access control |
| `*.server.ts`, `RenderMode`, hydration, transfer cache, `afterNextRender` | `angular-ssr` |
| `*.store.ts`, `state/`, `signal()`, `computed()`, `effect()`, `linkedSignal` | `angular-state-management` |
| `toSignal`, `toObservable`, `takeUntilDestroyed`, RxJS stream composition | `angular-rxjs-interop` |
| `DomSanitizer`, `innerHTML`, trusted HTML, CSP, credentials | `angular-security` |
| `*.spec.ts`, `TestBed`, `ComponentFixture`, `ComponentHarness`, `HttpTestingController` | `angular-testing` |
| Angular naming, feature-folder layout, style conventions | `angular-style-guide` |

Load the leaf skills relevant to the task rather than every skill in the `angular/` group. File patterns are hints; when modern feature-based filenames do not reveal the artifact type, route by the code or task topic.
