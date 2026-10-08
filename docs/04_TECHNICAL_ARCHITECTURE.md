# Technical Architecture — iOS Expense Tracker

**Status:** proposed architecture for an offline-first native MVP. Revisit after the minimum iOS target and Xcode version are confirmed.

## 1. Platform and stack

- **UI:** SwiftUI.
- **Minimum OS:** proposed iOS 17+ if using SwiftData; confirm before creating the production Xcode project. If lower OS support is required, choose Core Data or another supported persistence path.
- **Local persistence:** SwiftData for a simple local MVP, behind repository protocols; Core Data remains the alternative if deployment/migration needs warrant it.
- **Concurrency:** Swift Concurrency (`async`/`await`, `Task`, actors where appropriate); UI state owned by `@MainActor` observable view models.
- **Voice:** Apple Speech/AVFoundation APIs behind a service interface. Check on-device recognition/language support at runtime; do not promise offline support for every locale/device. Manual entry remains available.
- **Security:** Keychain only for secrets/keys; LocalAuthentication for optional app lock; iOS file-protection/data-protection settings reviewed for persistent and exported files.
- **Notifications:** UserNotifications for explicit local reminders in a later milestone. Request authorization only after the user opts into a reminder.
- **Native extensions:** WidgetKit and App Intents after core app stability.
- Use native frameworks first. Add external packages only with a clear capability gap and product-owner approval.

## 2. Architecture principles

- Feature-oriented modules with a small domain layer; avoid over-engineering a single-user local MVP.
- SwiftUI views render immutable/readable state and forward user intent; calculations and parsing live outside views.
- Repositories abstract local persistence so tests and future sync do not leak SwiftData APIs through the entire UI.
- No network or account dependency for core operations.
- Derived totals are computed deterministically from transactions and budgets; do not persist duplicate aggregate values unless measured performance justifies it.
- Money, date boundaries, refunds, transfers and deletion semantics are domain rules and must be unit-tested.

## 3. Logical structure

```text
ExpenseTrackerApp/
├── App/                       # App entry, navigation, dependency composition
├── Core/
│   ├── DesignSystem/          # Tokens and reusable accessible components
│   ├── Domain/                # Entities, value types, money/date rules
│   ├── Persistence/           # SwiftData/Core Data models, migrations, DAOs
│   ├── Security/              # Face ID gate, protected file/export helpers
│   └── Utilities/             # Formatters, validation, clock/calendar
├── Features/
│   ├── Onboarding/
│   ├── Dashboard/
│   ├── Transactions/
│   ├── Budgets/
│   ├── VoiceCapture/
│   └── Settings/
├── Integrations/              # Speech, notifications, exports, later widgets
└── Tests/
    ├── DomainTests/
    ├── PersistenceTests/
    └── UI/                    # Critical user flows
```

Keep these logical boundaries even if the first Xcode project uses one app target. Do not create many Swift packages/framework targets before a real need emerges.

## 4. Data flow

```text
SwiftUI screen → ViewModel → Use case/domain service → Repository protocol
                                                   ↓
                                  Local SwiftData/Core Data implementation
```

- Add: validate draft → create stable ID → save locally in a transaction → return success/failure → emit refreshed query state.
- Dashboard: query period transactions + budget → compute summary in domain → format for UI.
- Voice: microphone user action → OS speech-to-text capability → deterministic parser → validate → editable draft → user confirmation → repository save.
- Export: query filtered records → generate CSV in temporary/protected location → present system share sheet after explicit action → clean temporary data when safe.

## 5. State and error handling

Represent view state explicitly (loading, content, empty, recoverable error). Persistence or parse errors must be visible and actionable. Do not show “saved” before successful local commit. Avoid retaining mutable reference state across unrelated screens. Prevent duplicate submission while save is in flight.

## 6. Local-first and future service boundary

**MVP:** local-only repositories; no authentication, server, sync queue or cloud SDK required.  
**Future:** a remote repository adapter may be introduced behind interfaces. Every future sync record needs a stable UUID, creation/update timestamps, deletion tombstone and revision/conflict policy. Do not silently implement last-write-wins without a documented rule. Cloud backup/sync must be opt-in and have export, restore and delete behavior specified.

The linked MCP server is a separate Python service intended for AI clients. It is not a Swift package or iOS backend requirement. If an MCP/API bridge is approved later, place it outside the local app boundary, authenticate/authorize every user, scope tools, and require in-app confirmation for writes/exports.

## 7. Voice pipeline

```text
Tap mic → explain/request permission → speech service → transcript
       → deterministic extraction → validation/confidence → editable review
       → user confirms → local transaction
```

- Ask permission only on explicit mic action; support denial and manual fallback.
- Check `supportsOnDeviceRecognition` / language support where the chosen API exposes it; if processing requires a network, disclose this before use and obtain consent.
- Do not save audio; do not persist raw transcript by default. A user may edit the parsed note independently.
- Parser must not invent missing amount/date/category. Ambiguous “kal” should resolve to an explicit date in review.
- Currency and locale formatting is distinct from parsing; store normalized minor units and currency code.

## 8. Testing and quality

- Unit-test pure domain calculations, date windows, currency conversion/formatting boundaries (no FX in MVP), validation and voice parser.
- Use in-memory persistence or isolated test stores for CRUD/migration tests.
- UI-test onboarding, add/edit/delete, budget refresh, voice review and permission denial.
- Test offline use, relaunch durability, duplicate submit, month boundary, timezone/locale changes, leap year, category archive and large font.
- Use Xcode build/test on macOS; do not claim success from static inspection alone.

## 9. Performance and observability

Keep database/CSV work off the main actor when appropriate. Query only needed periods, paginate long histories and avoid repeated full-list recomputation. Telemetry, if ever added, must be opt-in/approved and exclude financial content. Crash logs must not include serialized transaction models.

## 10. Definition of done

A feature is done only when behavior meets its acceptance criteria, empty/loading/error states exist, accessibility semantics are present, business rules have tests, persistence/migration implications are reviewed, privacy is checked, build/tests run on the supported environment, and changed docs/backlog items are updated.
