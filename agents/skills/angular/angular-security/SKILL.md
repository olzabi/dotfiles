---
name: angular-security
description: Harden Angular apps against XSS, CSP violations, and unauthorized access. Use when implementing XSS protection, Content Security Policy, or auth guards in Angular.
metadata:
  triggers:
    keywords:
    - DomSanitizer
    - innerHTML
    - sanitize(SecurityContext.HTML)
    - trusted HTML
    - CSP
    - angular security
    - route guard
---
# Security

## **Priority: P0 (CRITICAL)**

## Principles

- **XSS Prevention**: Angular sanitizes interpolated values by default — **{{ userInput }} safe**. NOT use `innerHTML` unless absolutely necessary (e.g., trusted static CMS content). For user-generated content, display as text with **{{ content }} — never as HTML**.
- **Trusted HTML APIs**: Mark HTML as trusted only for content you control (e.g., vetted CMS headers). Never mark user-provided data as trusted. Prefer **DomSanitizer.sanitize(SecurityContext.HTML, content)** and review every trust-marking call as a potential XSS vector.
- **Route Guards**: Use functional **CanActivateFn** guards (for example, return `inject(Router).createUrlTree(['/login'])`) to control client-side navigation and user experience. A guard is not an authorization boundary; enforce access on the server for every protected resource.

## Guidelines

- **CSP**: Configure **CSP headers on server** (not in Angular source). Use **nonce-based CSP** with **script-src 'nonce-{nonce}'** and avoid unsafe-inline/unsafe-eval.
- **HTTP**: Prefer appropriately secured, server-managed **HttpOnly cookies** over browser-readable token storage when the authentication design supports cookies. JavaScript cannot read an HttpOnly cookie; let the browser send it and enforce authorization on the server. Use interceptors for headers or request policy only when the credential is available to client code.
- **Secrets**: **Never store API keys** or secrets in Angular source code or bundle.

## Anti-Patterns

- **No trust-marking on user input**: Trust Angular's sanitization; reserve trusted HTML APIs for verified static content only.
- **No client-only authorization**: Route guards and hidden UI improve navigation but cannot protect server data or APIs. Validate authorization on the server.
- **No secrets in source**: Never embed API keys or secrets in Angular bundle code.

## References

- [Security Best Practices](references/security-best-practices.md)
- common/security-standards

## CSP and secret checklist

- Use a server-generated, per-response nonce in `script-src 'nonce-{nonce}'`; do not use a static nonce.
- Keep controlled provenance explicit: trust-mark only controlled and verified or vetted static CMS content.
- Do not put API keys or other secrets in the compiled bundle.


