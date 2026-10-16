# Naming Conventions

Angular file names should be clear, hyphenated, and associated with the feature or primary exported symbol. Type suffixes are optional; follow the project's established convention rather than requiring `.component`, `.service`, or similar suffixes.

| Construct | Example file names | Example symbol or selector |
| --- | --- | --- |
| Component | `hero-list.ts`, `hero-list.html`, `hero-list.spec.ts` | `HeroList`, `app-hero-list` |
| Service | `user-profile.ts` or `user-profile.service.ts` | `UserProfile` or `UserProfileService` |
| Directive | `validate.ts` or `validate.directive.ts` | `Validate`, `[appValidate]` |
| Pipe | `truncate.ts` or `truncate.pipe.ts` | `Truncate`, `truncate` |
| Guard | `auth.ts` or `auth.guard.ts` | `authGuard` |
| Interceptor | `auth.ts` or `auth.interceptor.ts` | `authInterceptor` |
| Model | `hero.ts` | `Hero` |

## Member Names

- **Signals**: Name signals after the value they represent. A `Sig` suffix is optional and usually unnecessary.
- **Observables**: A `$` suffix (for example, `heroes$`) is a common convention; follow the project style.
- **Outputs**: Use action-oriented names such as `delete` or `save`; event handlers can use `onDelete` or `onSave`.
