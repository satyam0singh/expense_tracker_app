# Implementation Plan — iOS Expense Tracker

**Delivery approach:** small vertical slices; local-first; each phase ends with a build/test and owner review.  
**MVP:** Phases 0–6.  
**V1:** Phase 7.  
**Later:** Phase 8.

## Phase 0 — Confirm product and environment

**Work:** review Product Brain and open questions; confirm product name placeholder, minimum iOS deployment target, currency/locale and voice/privacy assumptions; inspect existing repository; set up Git and Xcode/macOS validation environment.

**Deliverable:** approved decisions/ADRs, repo inventory, initial app target plan, no unapproved code changes.

**Gate:** user approves the initial scope and platform/deployment target. If target is below SwiftData support, choose Core Data or alternative before schema work.

## Phase 1 — iOS foundation and domain core

**Work:** create/confirm SwiftUI app and test target; establish feature folder structure, navigation skeleton, theme/accessibility baseline, domain entities/value types, money/date formatters, validation and repository protocols. Add local persistence selection after ADR-008 is resolved.

**Tests:** currency minor-unit formatting, amount validation, period/date boundaries, transaction-type semantics, budget formulas.

**Deliverable:** app launches; unit tests pass; no financial feature UI required yet.

## Phase 2 — Local persistence and onboarding

**Work:** profile and category seed data; local schema and migration baseline; onboarding with skip path; local repository implementations; clean install and relaunch state.

**Tests:** local CRUD, migration from empty/current schema, onboarding resume/completion, category archive/history rules.

**Deliverable:** user reaches a configured/usable Home without network or sign-in.

## Phase 3 — Transaction capture and activity

**Work:** amount-first add expense/income; manual date/category/merchant/note/payment method; edit/delete/undo; Activity list and basic search/filter; duplicate-submit guard; successful local commit before confirmation.

**Tests:** create/update/delete/undo, invalid amounts, sorting/grouping, activity filters, app relaunch persistence and error recovery.

**Deliverable:** reliable manual local expense tracker.

## Phase 4 — Dashboard and budgets

**Work:** calendar month selector; actual income and expenses; total monthly budget; optional category limits if scope/effort permits; progress/warnings; empty and over-budget states; summaries derived from source transactions.

**Tests:** month boundaries, leap year, refunds, excluded transfers, zero/no budget, exceeded budget, category totals reconcile to eligible totals.

**Deliverable:** user can understand recorded activity and budget remaining without misleading “bank balance” language.

## Phase 5 — Voice capture

**Work:** contextual microphone permission; capability/language check; speech-to-text adapter; deterministic parser for approved language patterns; validation/confidence rules; editable review screen; cancellation and manual fallback; prevent duplicate saves.

**Tests:** examples and malformed/ambiguous phrases in `docs/09_TEST_PLAN.md`; permission denied; no speech; unsupported language; offline/network limitation disclosure.

**Deliverable:** user can speak a common transaction, correct extracted fields and explicitly save.

## Phase 6 — MVP hardening and release candidate

**Work:** CSV export, delete-all flow, optional Face ID if approved, local data protection review, production logging scrub, accessibility passes, critical UI tests, performance profiling and App Store metadata/privacy preparation.

**Tests:** end-to-end critical flows, VoiceOver/Dynamic Type, dark mode, export encoding/range, deletion, upgrade/migration, crash/error recovery.

**Deliverable:** MVP release candidate that passes `docs/14_RELEASE_CHECKLIST.md` and owner/privacy review.

## Phase 7 — V1: habit, recurring items and iOS integrations

**Completed slices:**
1. Recurring commitment schedules and reminders (US-070, FR-13). Pure cadence calculation, non-negotiable schedule-vs-actual distinction (no silent auto-post), due-now action banners, manual posting flow with schedule advancement, and full repository lifecycle.
2. Factual weekly & month-over-month category trends and shifts (US-077). Net expense/refund calculations, transfer exclusions, weekly spending rhythm, and factual calculation basis disclosures.
3. Custom pay cycles and safe-to-spend model (US-071, ADR-009). Configurable salary payday (e.g. 25th), days remaining, commitment deduplication, daily pace target, and non-bank-balance modal.
4. WidgetKit and App Shortcuts / App Intents (US-072, ADR-010). Small, Medium, and Lock Screen widgets, WidgetSnapshotGenerator, WidgetDataStore with App Group fallback, deep link action buttons (`expensetracker://add-expense`, `expensetracker://voice-capture`), Siri/Shortcuts `LogExpenseIntent` with integer minor units, and privacy redaction.

**Phase 7 (V1 Scope):** Fully Complete.

**Gate:** All MVP and V1 user stories (US-010 through US-072 and US-077) are implemented and unit-tested.

## Phase 8 — Later ecosystem capabilities

Potentially explore manual credit-card statement/due tracking, receipt OCR, split expenses, optional iCloud/private sync, server API and consented MCP/AI query integration. These require a separate ADR, threat model, auth/ownership model, data deletion/restore design, and user testing before implementation.

## Milestone definitions

### MVP complete

- Offline install → onboarding skip/complete → add/edit/delete expense/income → see correct monthly figures → voice parse/review/save → export/delete data.
- Critical calculations and parser tests pass.
- No critical data-loss, permission, privacy, accessibility or security issues remain.
- Real Xcode build and simulator/device verification executed on a supported macOS environment.

### V1 complete

- Approved retention feature(s) shipped, including tests, accessibility, migration and updated privacy/permission disclosures.

### Later release ready

- Each capability has product validation, security/privacy review, architecture decision, support/restore behavior and operational owner.

## Change control

If an agent suggests expanding scope, ask it to identify the affected requirements, tests, migration, privacy implications and schedule. Update PRD, backlog and ADR only after product-owner approval. Keep MVP and later milestones distinct.
