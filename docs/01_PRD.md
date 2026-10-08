# Product Requirements Document — iOS Expense Tracker

**Status:** v0.1 starter specification  
**Platform:** iOS, native app  
**Product name:** TBD  
**Primary audience:** people who want simple, private personal expense tracking  
**Release target:** MVP first; no backend dependency

## 1. Product overview

Build a native personal expense tracker centered on fast transaction capture and a clear monthly view. The app should help users understand recorded income, recorded spending and remaining budget while being explicit that it does not know unrecorded cash or a bank balance.

## 2. Problem statement

Users often intend to track spending but stop because logging is repetitive, budget apps feel complicated, recurring commitments are easy to forget, or analytics do not lead to an understandable takeaway. A mobile-first, local-first product can reduce capture friction and make basic budgeting approachable.

## 3. Goals

### MVP goals

- Complete essential onboarding in under three minutes; allow skipping optional income/profile details.
- Record a typical manual expense in under 15 seconds.
- After permission and setup, review and save a common voice-captured transaction in under 10 seconds.
- Show period, recorded income, recorded spending and budget remaining without conflating their meaning.
- Support expense/income CRUD, categories, search, a calendar-month budget and basic summaries.
- Work offline for core tracking; persist data safely across app restarts.
- Require user confirmation for voice-parsed transactions in the initial release.
- Provide data export/deletion controls and accessible labels for interactive elements.

### Later goals

Custom pay cycles and safe-to-spend estimates, recurring commitments/subscription reminders, richer analytics, iOS widgets and Shortcuts, receipt capture, card lifecycle tracking, optional sync and consented natural-language/MCP access.

## 4. Non-goals

- Bank aggregation, open banking, SMS/notification scraping or automatic payment-app imports.
- Payments, transfers of real money, investment management, tax filing, credit underwriting or accounting software.
- Guaranteed prediction of future balances or financial advice.
- Cloud account requirement for the local MVP.
- Cloud LLM, generative advice or an MCP service in the MVP.
- Pixel-perfect copying of any referenced application’s identity or screens.

## 5. Personas and use cases

### P1: First-job professional
Wants a quick way to record daily UPI/card/cash expenses and see whether a monthly limit is close.

### P2: Student
Has irregular income, needs easy cash/food/transport tracking, and wants setup to be optional.

### P3: Freelancer
Wants income and expense records, clear date ranges and exportable data without linking a bank account.

## 6. MVP functional requirements

Priority key: **M** = required for MVP; **S** = should follow in V1; **L** = later.

| ID | Requirement | Priority |
|---|---|---|
| FR-01 | Onboarding asks for locale/currency and optional name, expected monthly income and budget; can be skipped or completed later. Expected income is labelled as a planning figure, not actual received income. | M |
| FR-02 | Home displays selected calendar month, recorded income, recorded expenses, budget limit/remaining and recent transactions. Labels distinguish actuals from limits/estimates. | M |
| FR-03 | Add expense or income with positive amount, currency, date and category; merchant/note/payment method are optional. | M |
| FR-04 | Edit, delete and undo a transaction; changes update Home and summaries immediately. | M |
| FR-05 | Provide seeded and custom categories; rename/archive without breaking history. | M |
| FR-06 | Set a calendar-month total budget; optionally set category limits and warning thresholds. | M (total); S (category limits) |
| FR-07 | Search/filter activity by date range, category, type, merchant/note and amount. | M (basic search/date/type/category); S (advanced filters) |
| FR-08 | Voice input converts speech to editable type, amount, currency, date, category, merchant/note and optional payment method. No ambiguous/low-confidence result can save without user correction/confirmation. | M |
| FR-09 | Core reads/writes/calculations work offline and survive process termination/relaunch. | M |
| FR-10 | Display useful empty/loading/error states and accessible control labels. | M |
| FR-11 | Export selected transactions as CSV and permanently erase local data after explicit confirmation. | M |
| FR-12 | Local notifications can be used for budget reminders only after user opt-in; no notification permission request at install. | S |
| FR-13 | Track recurring bills/income, due dates and subscription totals. | S (V1; not an MVP blocker) |
| FR-14 | Provide trend, category, month comparison and factual deterministic insights. | S |
| FR-15 | Widgets, App Intents/Shortcuts, receipt scan and card tracking. | L |
| FR-16 | Optional authenticated sync or consented AI/MCP assistant. | L |

## 7. Calculation and language requirements

- Money stored as integer minor units and formatted using currency/locale rules.
- **Actual net:** posted income + posted refunds − posted expenses; transfers excluded.
- **Budget remaining:** configured limit − eligible expense net of assigned refunds. Do not count income as additional budget unless the user explicitly chooses an income-based budget model in a later version.
- **Projection:** not part of the initial monthly headline; any future estimate must be labeled projected and show its assumptions.
- “Budget left” is not “bank balance.” UI and export must not imply linked-account knowledge.
- Relative dates, invalid amounts, missing currency, ambiguous speech and duplicate submissions are handled explicitly.

## 8. Non-functional requirements

- **Reliability:** no silent loss/duplication during transaction add/edit/delete; validate persistence before showing success.
- **Performance:** local Home/Activity should feel immediate for normal personal datasets; do not block the main thread on I/O or exports.
- **Privacy:** no transaction contents in logs/telemetry; microphone permission only on voice action; clear data deletion and export.
- **Security:** OS-protected local storage where available, optional Face ID app lock, safe handling of temporary exports, no embedded API secrets.
- **Accessibility:** VoiceOver labels, Dynamic Type, sufficient contrast, non-color status cues, reduce-motion respect and minimum touch targets.
- **Maintainability:** testable domain calculations, repository boundaries, documented schema migrations and no unnecessary third-party dependencies.

## 9. Success metrics

- Onboarding completion; time to first saved transaction.
- Median time to record common manual expense; voice flow completion and correction rate.
- Weekly active recorders, day-7/day-30 retention and transactions/user/week.
- Duplicate/save failure rate; transaction edit/delete recovery failure rate; crash-free sessions.
- Budget warning opt-out/dismissal rates to detect alert fatigue.
- Technical telemetry must exclude raw amounts, merchants, notes, categories linked to individuals, transcripts and receipts.

## 10. MVP acceptance criteria

MVP is testable when a clean install can reach Home without required sign-in; add/edit/delete expense and income offline; accurately calculate tested month/budget summaries; capture voice to review without silently committing; restore local records after relaunch; export CSV; erase data on request; and pass critical accessibility, privacy and regression checks. The minimum supported iOS version and final release branding must be decided before App Store submission.
