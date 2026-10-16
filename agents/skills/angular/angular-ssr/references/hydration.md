# Hydration

## Enable Hydration

In `app.config.ts`:

```typescript
export const appConfig: ApplicationConfig = {
  providers: [provideClientHydration()],
};
```

## Browser-Only Code

Use `afterNextRender()` for one-time DOM setup; it runs in the browser and not during server rendering. For recurring logic that needs to branch by platform, `isPlatformBrowser()` with `PLATFORM_ID` remains appropriate.

```typescript
@Component({...})
export class ChartComponent {
  constructor() {
    afterNextRender(() => {
      // Safe to access browser APIs in this callback
      new Chart(document.getElementById('chart'));
    });
  }
}
```

## Event Replay and Incremental Hydration

`withEventReplay()` enables event replay when it is needed without incremental hydration. Incremental hydration enables event replay automatically:

```typescript
provideClientHydration(withIncrementalHydration());
```

## Full App Config with Hydration and Transfer Cache

```typescript
// app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideClientHydration(withEventReplay()),
    provideHttpClient(withHttpTransferCacheOptions({ includePostRequests: false }))
  ]
};
```
