# Test Plan — iOS Expense Tracker

## 1. Objectives

Prove that financial calculations are deterministic, records persist locally, the voice flow cannot commit an unreviewed ambiguous parse, and privacy/accessibility behavior matches product requirements. Tests must not use production financial data.

## 2. Test layers

### Unit tests — required

- Amount parsing/validation, integer minor units, currency formatting boundaries.
- Actual income/expense/refund/transfer totals and budget remaining.
- Month start/end, leap years, locale/timezone changes and selected-period navigation.
- Category totals reconcile to eligible total; archived category snapshot remains visible.
- Voice parser extraction, confidence/unknown fields and category mapping.
- Search normalization, filtering and CSV escaping.

### Persistence/integration tests — required

- Transaction/category/budget create-read-update-delete and undo behavior.
- Persistence after app process termination/relaunch (where UI test infrastructure permits).
- Schema migration from each supported released schema; migration must not drop user records.
- Repository error behavior; no false “saved” result on failed commit.
- Duplicate submit/idempotency protection in UI/service.

### UI tests — critical flows

1. Clean install → skip optional onboarding → Home.
2. Configure budget → add expense → Home updates.
3. Add income → income and net summary update; expense budget does not increase incorrectly.
4. Edit/delete/undo → Activity and summary refresh.
5. Voice: grant permission → parse → edit field → confirm once.
6. Voice permission denied/no speech/unsupported language → manual fallback.
7. Empty activity, no budget, over-budget and no-search-results states.
8. Export selected date range → preview → system share sheet path (test export file separately if share sheet automation is limited).
9. Delete all data → confirmation → clean first-run state.

## 3. Calculation test cases

- No transactions, no budget; no divide-by-zero or fake zero-state claim.
- Budget 10,000; eligible expenses 6,450 → 3,550 remaining and 64.5% used.
- Expenses exceed limit → negative remaining preserved and over-budget state announced.
- Income does not reduce expense budget consumption.
- Transfer/card repayment excluded from spending and income.
- Refund treatment follows approved category/period rule; test both same-category and unassigned case.
- Amount one minor unit; large `Int64` boundary; invalid overflow rejected.
- A transaction at local month boundary belongs to its stored local date even after timezone change.
- Leap day, December/January change and custom period (when implemented).

## 4. Voice parser fixtures

Use synthetic text/audio and do not put real user financial data into test logs. Include:

- “Spent 350 rupees on lunch.”
- “Paid 800 for electricity.”
- “Got 5000 from freelance work.”
- “₹250 chai, UPI.”
- “Auto 120 yesterday.”
- “Kal metro 40.” (must require explicit-date review if ambiguous)
- Missing amount, two amounts, negative/zero amount, unspecified currency, noisy transcript, unsupported spoken locale and cancellation.

Assert extraction output independently from UI; assert that ambiguous/missing/low-confidence drafts cannot reach repository save without user correction/confirmation.

## 5. Accessibility and usability checks

- VoiceOver reads amount, type, category, date, budget progress and error state meaningfully.
- Dynamic Type at largest supported sizes; no truncated currency or unreachable controls.
- Contrast in light/dark mode; red/green not sole status cue.
- Reduce Motion; keyboard dismissal and form focus; minimum touch target review.
- Usability timing: typical manual expense under 15 seconds; voice review under 10 seconds after setup for common phrase.

## 6. Privacy/security tests

- Permission is not requested before an explicit voice/notification action.
- Denied permissions do not block manual tracking.
- Search/debug/crash logs contain no amount, merchant, note, transcript, receipt, or full transaction object.
- Export only includes selected range/fields; no silent network transfer.
- Delete-all removes local records and the app returns to documented clean state.
- Biometric cancellation/failure (if enabled) does not erase records or bypass security unexpectedly.

## 7. Device/environment coverage

- Test on supported iOS simulator versions and at least one physical device before release.
- Test light/dark modes, Dynamic Type sizes, English UI and each committed parser language.
- Record Xcode version, device/simulator, OS, test command and results.
- When Xcode/macOS is unavailable to the agent, mark native build/UI verification as outstanding; static inspection is not a substitute.

## 8. Release gate

No P0 defect in money calculations, transaction durability, duplicate saves, deletion, voice confirmation, privacy permission flow or accessibility. All required automated tests pass; manual test evidence and known limitations are recorded in `docs/14_RELEASE_CHECKLIST.md`.
