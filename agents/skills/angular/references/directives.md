# Directives

Use attribute directives for reusable behavior attached to an element. Prefer template and host bindings; use `ElementRef` or `Renderer2` only when the behavior requires DOM access, accounting for server rendering.

Compose standalone directives with `hostDirectives` on a component or directive. Expose a host directive's inputs or outputs explicitly with the `inputs` and `outputs` arrays when consumers need to bind them. Follow the application's Angular version and standalone or NgModule conventions.

For pipes, see [pipes.md](pipes.md); for host bindings, see [host-elements.md](host-elements.md).
