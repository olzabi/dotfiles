# Angular security

Angular interpolation renders values as text. Angular sanitizes untrusted values in supported binding contexts, including HTML and URLs; resource URLs cannot be safely sanitized in general. Prefer text interpolation when HTML is not required, and review any use of `DomSanitizer.bypassSecurityTrust...` as a security boundary: only trust content whose provenance and safety have been verified. Avoid direct DOM APIs that bypass Angular's protections.

Route guards control navigation, not authorization. Enforce access on the server for every protected resource. Never put secrets in the client bundle.

Configure CSP and Trusted Types according to the application's deployment and Angular version. When using nonce-based CSP, generate a fresh nonce per response and supply it to Angular as documented. Choose authentication storage and CSRF defenses for the application's threat model; `HttpOnly` cookies are not readable by JavaScript but do not by themselves prevent CSRF.

Consult the current Angular security guidance for the exact APIs and CSP configuration: https://angular.dev/best-practices/security.
