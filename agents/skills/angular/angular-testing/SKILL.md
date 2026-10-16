---
name: angular-testing
description: Write Angular component tests using TestBed, ComponentHarness, and HttpTestingController with proper signal input handling. Use when writing component tests, mocking HTTP calls, or testing signal inputs.
metadata:
  triggers:
    files:
    - '**/*.spec.ts'
    keywords:
    - TestBed
    - ComponentFixture
    - TestHarness
    - provideHttpClientTesting
---
# Testing

## **Priority: P1 (HIGH)**

## 1. Choose Stable DOM Queries

- Use `ComponentHarness` (for example, `MatButtonHarness`) when the component provides one or when a reusable test API is valuable.
- For simple component-local tests, semantic queries such as roles, labels, or stable attributes are appropriate. Avoid depending on styling classes or incidental DOM structure.
- `loader.getHarness(MatButtonHarness)` + `await button.click()` is a stable interaction pattern.

See [harness pattern](references/harness-pattern.md) for ComponentHarness examples.

## 2. Mock HTTP with HttpTestingController

- Prefer `HttpTestingController` over hand-written `HttpClient` mocks when testing the HTTP integration.
- Provide `provideHttpClient()` before `provideHttpClientTesting()` in the test providers.
- Call `expectOne`, `.flush(mockData)`, and `verify()` in `afterEach`.

See [harness pattern](references/harness-pattern.md) for HttpTestingController examples.

## 3. Test Signal Inputs and Scheduled Updates

- Use `fixture.componentRef.setInput('name', value)` rather than assigning an input property directly.
- In zoneless tests, prefer waiting for scheduled work (for example, `await fixture.whenStable()`) when verifying normal Angular update behavior. Call `fixture.detectChanges()` when the test explicitly needs a synchronous change-detection pass, not as an automatic step after every input update.
- Signals update synchronously, but rendering and asynchronous work may still require awaiting stability; use `fakeAsync` only when it fits the code under test.

## 4. Choose Your Test Runner

- New projects created with the current Angular CLI use **Vitest** through `@angular/build:unit-test`. Existing workspaces may use another configured runner; check the builder in `angular.json` before assuming the test setup.
- Jasmine/Karma remain supported for existing projects.
- Standalone: import directly in `TestBed.configureTestingModule({ imports: [StandaloneComponent] })`.

## Anti-Patterns

- **Brittle DOM queries**: Avoid styling classes and incidental structure when accessible roles, labels, stable attributes, or a harness are available.
- **Unnecessary HTTP mocks**: Use `HttpTestingController` when the HTTP request behavior is part of the test; use simpler fakes when testing an unrelated consumer boundary.
- **Direct input mutation**: Use `fixture.componentRef.setInput()` to exercise Angular input semantics.

## References

- [Harness Pattern](references/harness-pattern.md)

## Canonical response anchors

When this skill applies, preserve the following domain terminology or equivalent concrete examples in the answer when relevant:
- Prefer semantic roles, labels, stable attributes, or a component harness over brittle styling-class queries.
- native ESM

- Additional task-grounded exact anchors: ComponentHarness
