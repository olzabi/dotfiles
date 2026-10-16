# Folder Structure

This is one feature-oriented convention, not a required Angular layout. Use the host application's established structure when it is already clear.

```text
src/
├── app/
│   ├── app.config.ts         # Application providers
│   ├── app.routes.ts         # Root routes
│   ├── app.ts                # Root component
│   ├── core/                 # Optional grouping for app-wide providers
│   ├── shared/               # Optional grouping for reusable UI/utilities
│   └── features/             # Feature-oriented grouping
│       ├── dashboard/
│       │   ├── dashboard.ts
│       │   ├── dashboard.routes.ts
│       │   └── dashboard.html
│       └── profile/
└── assets/
```
