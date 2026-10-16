---
name: angular-forms
description: Build Angular forms with typed Reactive Forms or Signal Forms, custom validation, and appropriate control patterns. Use when implementing forms, validators, or form state.
metadata:
  triggers:
    keywords:
    - FormBuilder
    - FormGroup
    - FormControl
    - Validators
    - reactive forms
    - typed forms
    - Signal Forms
    - signal forms
---
# Forms

## **Priority: P2 (MEDIUM)**

## 1. Choose a Form Model

- Use typed Reactive Forms when you need their established control model, dynamic form composition, or compatibility with an existing application.
- Angular 21+ Signal Forms are an option for new signal-oriented applications. Check the current maturity and API status for the target Angular version before adopting them in production.
- Template-driven forms remain suitable for simple forms; choose based on complexity and team conventions.

See [typed forms](references/typed-forms.md) for typed `FormGroup` examples.

## 2. Type Controls and Validation

- Prefer typed controls and groups. Avoid `UntypedFormGroup` unless working with dynamic data whose shape is genuinely unknown.
- Keep validation close to the form by default. Extract reusable or complex validators into standalone functions or a shared module.
- Use `takeUntilDestroyed()` when imperatively subscribing to `valueChanges` for a longer-lived consumer.

## 3. Use NonNullable Controls Intentionally

- Use `fb.nonNullable.group(...)` or `nonNullable: true` when a control should not reset to `null`.
- Non-nullability preserves the control's non-null value type; it does not mean every form value is a string.

## Anti-Patterns

- **Wrong form model for the task**: Do not require Reactive Forms for every form or adopt Signal Forms without checking the target version's maturity.
- **Unnecessarily untyped controls**: Keep form types explicit where the shape is known.
- **Over-extracting validation**: Extract validators when reuse or complexity warrants it, not merely to keep every validator out of the component.

## References

- [Typed Forms](references/typed-forms.md)

