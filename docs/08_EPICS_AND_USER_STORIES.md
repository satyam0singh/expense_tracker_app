# Epics and User Stories — MVP Backlog Starter

Priorities: **P0** release blocker; **P1** MVP target; **P2** V1/later. Stories are intentionally small; split further when implementation or review is large. `AC` lists acceptance criteria.

## E00 — Foundation

### US-001 (P0): Launch a native iOS app
As a user, I want the app to launch reliably so I can start tracking.

**AC:** app target builds on approved deployment target; launch routes without network; test target runs; no placeholder secret or production bundle ID is used.

### US-002 (P0): Calculate money safely
As a user, I want amounts and budget totals to remain accurate.

**AC:** amount validation rejects zero/negative input; money uses integer minor units; date-range calculations use local calendar dates; unit tests cover rounding/formatting, month boundaries and transaction direction.

## E01 — Onboarding

### US-010 (P1): Choose currency and optional expected income
As a new user, I want to set currency/locale and optionally expected monthly income so the app has useful planning context.

**AC:** default suggestion is editable; user may skip optional details; expected income is clearly labeled as planned, never counted as actual received income; currency/date formatting uses locale-aware formatters; preferences survive relaunch.

### US-011 (P1): Set an optional budget
As a new user, I want to set a monthly limit so Home can show budget remaining.

**AC:** zero/no budget is represented explicitly; budget can be changed later; onboarding does not invent income or a bank balance.

## E02 — Manual transactions

### US-020 (P0): Add an expense
As a user, I want to record an expense quickly so I do not postpone it.

**AC:** amount and date validated; category selection available; optional merchant/note/payment method can be skipped; Save only reports success after local persistence succeeds; duplicate taps do not create duplicates.

### US-021 (P1): Add income
As a user, I want to record actual received income separately from expenses.

**AC:** type is visible; entry affects actual income and net summary, not expense budget spend; amount/date are validated.

### US-022 (P1): Edit or delete an entry
As a user, I want to correct a record or remove it if mistaken.

**AC:** edit preserves unmodified fields; delete supports documented undo/confirmation; summaries update immediately; deleted record does not leak into normal export/query.

### US-023 (P1): Choose a payment method
As a user, I want to label cash, UPI or card so I can filter later.

**AC:** payment method is optional; it is a label only and never implies a linked account; filter works when supported.

## E03 — Categories and activity

### US-030 (P1): Use starter categories
As a user, I want familiar categories so I can classify spending quickly.

**AC:** starter categories are seeded once; re-launch does not duplicate them; transaction history preserves archived/renamed category meaning.

### US-031 (P1): Manage custom categories
As a user, I want to create, rename, sort and archive categories.

**AC:** duplicate/empty names are validated; archived categories are excluded from new-entry suggestions but still display on history.

### US-032 (P1): Browse and find transactions
As a user, I want a dated activity list and basic search/filter.

**AC:** group by local date; filter by date/type/category; search merchant/note as approved; empty/no-results state offers a clear action; list updates after edits/deletes.

## E04 — Dashboard and budgets

### US-040 (P0): Understand monthly budget remaining
As a user, I want to see spent vs monthly budget so I know whether I am near my limit.

**AC:** selected month is visible; formula is deterministic; total budget, spent and remaining have labels; over-budget amount is not clamped; no account-balance claim.

### US-041 (P1): View recorded income and expenses
As a user, I want actual transaction totals separate from my budget.

**AC:** income, expenses and net are not conflated; transfers excluded; empty/zero cases are explained.

### US-042 (P2): Add category budgets and warnings
As a user, I want limits for selected categories and gentle alerts.

**AC:** only configured categories show limits; percentage/remaining values are correct; notification permission only requested after user opts in.

## E05 — Voice capture

### US-050 (P0): Start speech capture on request
As a user, I want to tap the microphone when I choose to speak an expense.

**AC:** explain purpose before permission; no microphone request at install/onboarding; denial preserves manual capture; listening/cancel/error states are clear.

### US-051 (P0): Review a parsed transaction
As a user, I want to correct voice extraction before it is saved.

**AC:** amount/type/date/category/merchant/note are editable; missing/ambiguous data is not fabricated; low confidence cannot silently save; explicit Add commits once.

### US-052 (P1): Understand privacy/offline limits
As a user, I want to know whether speech stays on device.

**AC:** implementation checks language/device capability; cloud/network processing is disclosed and requires consent; raw audio/transcript is not retained by default; manual/text fallback exists.

## E06 — Data control and privacy

### US-060 (P1): Export my records
As a user, I want to export selected transactions for my own use.

**AC:** preview date range/fields; CSV is valid UTF-8 and properly escaped; explicit Share action; temporary export lifecycle is handled; no auto-upload.

### US-061 (P1): Delete my local data
As a user, I want to erase my financial data.

**AC:** explain irreversibility; require explicit confirmation; remove records/preferences according to documented behavior; next launch is a clean setup; test deletion.

### US-062 (P2): Lock the app
As a user, I want optional biometric protection for private financial information.

**AC:** use LocalAuthentication; provide a clear fallback; do not store biometric data; failure/cancel handling does not lose records.

## E07 — V1 and later (not MVP commitments)

- **US-070:** create recurring schedule and reminder without silently posting an expense.
- **US-071:** set a pay cycle and view a clearly labeled safe-to-spend estimate with assumptions.
- **US-072:** add Home/Lock Screen widget and Shortcuts/App Intents.
- **US-073:** manually track card statement dates and repayments without double-counting.
- **US-074:** scan receipt into editable draft with duplicate warning.
- **US-075:** enable optional sync with restore/delete/conflict behavior documented.
- **US-076:** ask read-only natural-language questions; require confirmation for writes/exports.
- **US-077:** view factual weekly/monthly category trends and comparisons with an explanation of the compared periods and calculation basis.

## Definition of ready/done

**Ready:** clear outcome, scope, acceptance criteria, UI state, data impact and test plan.  
**Done:** acceptance passes, tests run, accessibility/privacy reviewed, migration handled, spec updated and exact validation results reported.
