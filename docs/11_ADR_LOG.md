# Architecture Decision Record Log

This is a **proposed** decision log. “Proposed” means suitable as a working default but still subject to product-owner approval where marked.

## ADR-001 — Native iOS application

- **Status:** Proposed.
- **Decision:** Build a native iOS app using SwiftUI and Apple APIs.
- **Reason:** The requested platform is iOS; native accessibility, permissions, widgets and Shortcuts are part of the product opportunity.
- **Consequence:** The Android Kotlin/Compose architecture in the source pack is not reused. Minimum OS must be confirmed before final persistence selection.

## ADR-002 — Local-first MVP, no backend

- **Status:** Proposed.
- **Decision:** Core MVP data stays on device; no required account, cloud API or MCP server.
- **Reason:** Privacy and offline use are foundational; syncing adds auth, conflict and deletion requirements.
- **Consequence:** Multi-device backup/sync is later. Provide CSV export and clear deletion behavior in MVP.

## ADR-003 — Money/date representation

- **Status:** Proposed.
- **Decision:** Store positive integer minor units plus a transaction type and ISO currency; persist transaction calendar day separately from UTC creation/update timestamps.
- **Reason:** Avoid floating-point money errors and timezone-driven period shifts.
- **Consequence:** Domain math and month boundaries require unit tests; currency exponent/formatting must use locale-aware APIs.

## ADR-004 — Honest “money left” semantics

- **Status:** Proposed.
- **Decision:** MVP headline is “Budget remaining” for a calendar-month budget, not bank balance. Keep actual transaction totals separate; defer “safe to spend until payday” forecast until its inputs/rules are explicit.
- **Reason:** The app does not know cash on hand, unrecorded transactions or linked accounts.
- **Consequence:** Marketing and UI copy must not imply a verified account balance.

## ADR-005 — Voice review before save

- **Status:** Proposed.
- **Decision:** Show a user-editable parsed transaction and require confirmation before saving in MVP.
- **Reason:** A wrong amount/date is a financial-data integrity issue; English/Hinglish and relative dates can be ambiguous.
- **Consequence:** Keep a manual fallback and no audio/transcript retention by default.

## ADR-006 — MCP / AI is a later integration

- **Status:** Proposed.
- **Decision:** Do not embed the Python MCP server or call cloud LLMs in MVP. Consider a scoped, opt-in assistant only after local domain rules and user consent are established.
- **Reason:** The linked repository is a separate MCP server designed to expose tools to AI clients, not a native iOS client. Financial data requires strict authorization and write confirmation.

## ADR-007 — No bank or message scraping

- **Status:** Proposed.
- **Decision:** Do not read bank SMS, notifications or other payment apps. Do not promise automatic transaction import in MVP.
- **Reason:** Privacy, reliability, OS limitations and product scope.
- **Consequence:** Manual/voice capture and later user-initiated statement import are alternatives.

## ADR-008 — SwiftData vs Core Data

- **Status:** Open.
- **Working proposal:** SwiftData if minimum supported OS is iOS 17+ and migration/test requirements remain modest; otherwise evaluate Core Data.
- **Decision owner:** Product owner + iOS engineering.
- **Gate:** Resolve before creating long-lived production schema.

## ADR-009 — Calendar month vs custom pay period

- **Status:** Accepted (V1 Delivered).
- **Decision:** Calendar month for MVP; custom pay cycle and safe-to-spend estimate in V1 only after formulas and copy are approved.
- **Implemented:** Pure deterministic PayCycle calculation engine (supporting calendar month or custom salary start day e.g. 25th), SafeToSpendCalculation deducting posted spend (expenses minus refunds; transfers excluded) and upcoming active recurring commitments before cycle end, daily budget pace indicator, and prominent non-account-balance assumptions modal.
- **Reason:** Keeps MVP simple while delivering high-value V1 retention capability with complete transparency and zero bank aggregation.

## ADR-010 — WidgetKit and App Shortcuts / App Intents Architecture

- **Status:** Accepted (V1 Delivered).
- **Decision:** Provide Home Screen and Lock Screen widgets (Small, Medium, Circular, Rectangular) and Siri/Shortcuts App Intents (`LogExpenseIntent`, `ViewSafeToSpendIntent`, `OpenAddExpenseIntent`, `OpenVoiceCaptureIntent`) without compromising financial privacy or local-first invariants.
- **Implemented:**
  - `WidgetSnapshot` and pure `WidgetSnapshotGenerator` producing deterministic, isolated metric snapshots without background query overhead.
  - `WidgetDataStore` with graceful App Group fallback to local documents if provisioning profiles are unconfigured, ensuring zero crashes.
  - Deep links (`expensetracker://add-expense`, `expensetracker://voice-capture`) allowing instant sheet presentation from widget action buttons.
  - Safe decimal conversion in `LogExpenseIntentHandler` enforcing integer minor units (`Int64`) with zero floating-point storage or math.
  - Full privacy redaction (`isPrivacyRedacted`) for Lock Screen and obscured displays.
  - Explicit labels: all widget views clearly label "Safe-to-Spend (Estimate)" or "Configured Budget Limit • Not a bank balance".
- **Reason:** Maximizes iOS platform native capture convenience and habit retention while strictly adhering to ADR-004 and offline privacy.

## Decision change protocol

When a decision changes, add date, decision owner, context, alternatives and consequences to this file; update affected PRD/UX/architecture/data docs; then ask the agent to implement only the approved change.

