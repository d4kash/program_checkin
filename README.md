# Program Check-in Mini App

A production-style Flutter mini app for the **Program Check-in Mini App** technical assignment. The code is shaped around the PDF requirements: dashboard, weekly check-in, history, English/German locale switching, fake session storage, reliability failures, local observability, redaction, and tests.

## Included

- Flutter/Dart app with Material 3 UI.
- Three named routes: `dashboard`, `check-in`, and `history`.
- Cubit state management for dashboard, check-in, history, session, and locale.
- Local JSON fixture under `assets/fixtures/program_fixture.json`.
- Fake injectable API client for success, timeout, offline, malformed JSON, 401, 429, and unexpected exceptions.
- SecureStore and PlainPreferences abstractions with fakeable in-memory implementations.
- Local-only observability with structured logs, spans, metrics, breadcrumbs, sanitized errors, and crash boundary.
- Allowlist redaction path for all telemetry attributes.
- Unit, Cubit/state, widget, semantics, locale, observability, and privacy tests.

## Setup

```bash
flutter pub get
```

## Run

```bash
flutter run
```

## Verify

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
rg "print\\(|debugPrint\\(|log\\(" lib test
rg -i "secret|token|password|email|phone|authorization" lib test
or
Get-ChildItem -Path lib,test -Recurse -Include *.dart |Select-String -Pattern 'print\(|debugPrint\(|log\('
Get-ChildItem -Path lib,test -Recurse -Include *.dart |Select-String -Pattern 'secret|token|password|email|phone|authorization' -CaseSensitive:$false

```

The `rg` commands are review aids. Matches for token/email/phone can appear intentionally in the fixture, secure storage code, storage policy, privacy tests, and README. No raw user data, tokens, request bodies, response bodies, notes, or progress values are written to telemetry or plain preferences.

## Architecture

```txt
lib/
  app/
    app.dart
    router.dart
    theme.dart
    localization/
  core/
    clock/
    formatting/
    network/
    observability/
    result/
    storage/
  features/
    checkin/
    history/
    program/
    session/
    settings/
test/
```

## State management

- `DashboardCubit`: loading, loaded, empty, error, retryable failure. Failed refresh keeps the last usable view.
- `CheckInCubit`: editing, validating, support-needed, submitting, submitted, retryable failure, error, unauthorized.
- `HistoryCubit`: loading, loaded, empty, error.
- `SessionCubit`: fake local session restore, refresh, clear.
- `LocaleCubit`: English/German preference stored in plain preferences.

## Routing

The app uses `go_router`.

- `/dashboard`
- `/check-in`
- `/history`

Route query data is safely decoded. Invalid route data shows a recoverable error screen.

## Privacy and security model

| Value | Storage |
|---|---|
| Access token | SecureStore only |
| Refresh token | SecureStore only |
| Token expiry | SecureStore with session |
| Locale | PlainPreferences |
| Theme | PlainPreferences |
| Check-in draft | Memory only |
| Optional note | Memory/repository mock only |
| User ID/name/email/phone | Fixture/repository only |
| Raw progress value | Domain/repository only |

Tokens, notes, names, emails, phone numbers, user identifiers, authorization headers, raw request bodies, raw response bodies, raw progress values, file paths, and URL query values are not allowed in telemetry or plain preferences.

A 401-style fake response clears secure session state and moves the app to a safe unauthenticated state.

## Observability

Local-only `InMemoryObservability` models:

### Events

- `dashboard_loaded`
- `checkin_validated`
- `checkin_submit_attempted`
- `checkin_submitted`
- `checkin_failed`
- `session_refresh_failed`

### Spans

- `dashboard.load`
- `checkin.flow`
- `checkin.submit`
- `repository.submit_checkin`
- `history.refresh`

### Metrics

- `checkin.submit_attempts`
- `checkin.submit_failures`
- `checkin.validation_failures`
- `checkin.submit_duration_ms`

Every submit attempt receives a correlation ID that links breadcrumb, UI span, repository span, metric, log, and sanitized error record.

## Reliability choices

- Expected failures use `AppResult<T>` and `AppFailure`, not thrown exceptions.
- Double submit is guarded with `_submitInFlight`.
- Repository saves check-ins by idempotency key.
- Retryable submit failure preserves the draft.
- Dashboard stale delayed loads cannot overwrite newer successful state.
- Connectivity is not treated as proof that the backend is reachable.

## Assumptions

- The program is generic and does not provide domain-specific advice.
- Fake tokens are modeled but not displayed raw in the UI.
- The note is accepted locally but never logged.
- The assignment values correctness, reliability, privacy, and explanation over pixel perfection.

## Trade-offs

- Localization is a small local abstraction instead of ARB/gen_l10n to keep the assignment compact and testable.
- Fake in-memory stores replace platform plugins so tests stay deterministic.
- A debug observability viewer is not included to keep scope controlled.

## Time spent

Designed for the requested 4-hour build plus 30-minute README timebox.

## With another day

- Add golden tests.
- Add a debug-only observability viewer.
- Add more route recovery tests.
- Add full ARB/gen_l10n if this grows into a larger app.
- Add CI workflow for format/analyze/test.
