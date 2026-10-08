# iOS Expense Tracker — V1 Release Handoff & Verification Guide

This document is the authoritative engineering handoff for the **V1 Release Candidate** of the native iOS Expense Tracker. It provides the exact commands, architectural invariants, test coverage summary, and instructions for verifying and building the app on macOS with Xcode 15+.

---

## 1. Executive Summary & Delivered Scope

All user stories and milestones across **Phase 0 through Phase 7** are complete:

| Phase | Milestone | Scope / Deliverables | Status |
|---|---|---|---|
| **Phase 0** | Alignment & Decisions | PRD, BRD, Technical Architecture, ADR Baseline (ADR-001 to ADR-007). | **Complete** |
| **Phase 1** | Foundation & Domain Core | Integer minor units `Money` (`Int64`), `CurrencyCode`, `CalendarMonth`, repository protocols, pure domain validation, `Package.swift`, and Xcode project. | **Complete** |
| **Phase 2** | Persistence & Onboarding | Actor-isolated thread-safe `LocalFileStore`, concrete local repositories, starter category seeding, and first-launch `OnboardingView`. | **Complete** |
| **Phase 3** | Transaction Capture & Activity | Amount-first `AddEditTransactionView`, `TransactionRowView`, search, filter chips (Income/Expense/Refund/Transfer), swipe-to-delete with 5-second undo banner in `ActivityView`. | **Complete** |
| **Phase 4** | Dashboard & Budgets | `BudgetSummary`, `CategorySpendSummary`, accessible `BudgetProgressBar`, monthly budget configuration, and category breakdowns in `BudgetsView` & `HomeView`. | **Complete** |
| **Phase 5** | Voice Capture & Review | Deterministic English/Hinglish speech parser (`VoiceTransactionParser`), on-device `SpeechRecognitionServiceProtocol`, `VoiceCaptureSheet`, and mandatory confirmation screen (`VoiceReviewView`). | **Complete** |
| **Phase 6** | Settings, Hardening & Data Control | RFC 4180 `CSVExporter` with iOS Share Sheet, irreversible local data purge with double confirmation, privacy status disclosures, and app reset. | **Complete** |
| **Phase 7** | V1 Habits, Trends & Integrations | **US-070:** Recurring rules with due alerts (no silent auto-post).<br>**US-077:** Factual category shifts and 7-day weekly spending rhythms.<br>**US-071 / ADR-009:** Custom salary pay cycles & Safe-to-Spend calculation with non-bank-balance modal.<br>**US-072 / ADR-010:** WidgetKit widgets (Small, Medium, Circular, Rectangular), App Groups, and Siri/Shortcuts App Intents (`LogExpenseIntent`, `ViewSafeToSpendIntent`). | **Complete** |

---

## 2. Non-Negotiable Invariants Checklist

The codebase strictly adheres to all invariants defined in `docs/00_PRODUCT_BRAIN.md` and `.agents/rules/`:

- [x] **Zero Floating-Point Money Storage:** All amounts, budgets, and safe-to-spend totals are stored and manipulated as integer minor units (`Int64`).
- [x] **Honest Financial Semantics (ADR-004 / ADR-009 / ADR-010):** Headlines and widgets are explicitly labeled as *"Budget remaining"* or *"Safe-to-Spend (Estimate)"*. The app never claims to know a bank balance or account balance.
- [x] **Zero Silent Commits (ADR-005 / US-070):** Voice transcriptions and recurring schedules are never committed without explicit user review.
- [x] **Zero Remote Dependencies or Telemetry:** 100% offline and local-first. No backend servers, external analytics SDKs, or cloud AI endpoints.
- [x] **Strict Privacy & Zero Logging:** Transaction notes, amounts, merchants, transcripts, and category details are never output to system console logs (`os_log` or `print`).
- [x] **Safe Transfer Semantics:** Transfers (`TransactionType.transfer`) are strictly excluded from spending metrics across Home, Budgets, Trends, Widgets, and CSV Export.

---

## 3. Test Suite Inventory (14 Suites)

All business rules, date roll-overs, decimal conversions, and error states are covered across **14 unit test suites** in `Tests/ExpenseTrackerTests/`:

1. `MoneyTests.swift`: Addition, subtraction, minor unit formatting, currency validation, integer overflow bounds.
2. `CalendarMonthTests.swift`: Month navigation, start/end dates, leap year handling, and string conversion.
3. `TransactionValidationTests.swift`: Draft validation, positive amount requirement, currency checks, source tagging.
4. `BudgetCalculationTests.swift`: Monthly spend totals, refund subtraction, transfer exclusions, over-budget percentage clamps.
5. `PersistenceAndOnboardingTests.swift`: File-system serialization, thread safety, onboarding profile defaults, starter categories.
6. `ActivityAndTransactionTests.swift`: Soft deletion, 5-second undo restoration, category/type search filters.
7. `BudgetFeatureTests.swift`: Category budget allocation, month-over-month rollovers, progress calculation.
8. `VoiceParserTests.swift`: English and Hinglish phrases, relative date offsets (*"yesterday"*, *"day before yesterday"*), amount extraction, ambiguous fallback drafts.
9. `DataExportAndDeleteTests.swift`: RFC 4180 CSV escaping (commas, quotes, newlines), complete local file deletion, clean state re-initialization.
10. `RecurringRulesTests.swift`: Cadence calculation (weekly, biweekly, monthly, annual), due-date triggers, advance next-due without auto-posting.
11. `TrendsCalculationTests.swift`: Month-over-month category deltas, percentage calculations, 7-day spending distribution.
12. `PayCycleAndSafeToSpendTests.swift`: Payday-of-month cycles (e.g. 25th), leap year clamping, daily pace calculation, commitment deduplication, zero-deficit clamping.
13. `WidgetSnapshotTests.swift`: Snapshot metrics generation, over-budget states, privacy redaction masking (`••••`), and `WidgetDataStore` save/load/clear lifecycles.
14. `LogExpenseIntentTests.swift`: App Intents decimal amount parsing into integer minor units, category case-insensitivity, negative amount validation, and widget refresh trigger.

---

## 4. macOS Verification & Build Commands

When opening this project on a macOS system equipped with Xcode 15+ and Swift 5.9+:

### Step 1: Run the Swift Package Unit Tests (Command Line)
```bash
cd /path/to/ios_expense_tracker
swift test
```
*Expected result:* All 14 test suites pass with 0 failures.

### Step 2: Run Tests via Xcode CLI on iOS Simulator
```bash
xcodebuild test \
  -project ExpenseTracker.xcodeproj \
  -scheme ExpenseTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### Step 3: Build Archive for TestFlight / App Store Distribution
```bash
xcodebuild clean archive \
  -project ExpenseTracker.xcodeproj \
  -scheme ExpenseTracker \
  -configuration Release \
  -archivePath ./build/ExpenseTracker.xcarchive \
  -destination 'generic/platform=iOS'
```

---

## 5. Apple Developer Configuration (Widgets & Provisioning)

To deploy the widgets to a physical device or submit to App Store:

1. **App Group Entitlement (Optional but Recommended):**
   - In Xcode under **Signing & Capabilities**, add **App Groups**.
   - Enable group: `group.com.expensetracker.shared`.
   - *Note:* If App Groups are not provisioned, `WidgetDataStore` automatically falls back to local container storage without crashing.
2. **Siri & App Intents:**
   - App Intents are automatically discovered by iOS 16/17+ via the `AppShortcutsProvider` in `ExpenseAppIntents.swift`.
3. **Microphone & Speech Permissions:**
   - `Info.plist` includes `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription`.
   - Permissions are only requested contextually when the user explicitly taps the microphone icon.

---

## 6. Post-V1 Roadmap (Phase 8 Candidates)

The following capabilities are reserved for Phase 8 and require explicit ADR approval and privacy reviews before commencement:
- **US-073:** Manual credit-card statement tracking and cycle repayments without double-counting spend.
- **US-074:** On-device receipt OCR draft scanner with duplicate detection.
- **US-075:** Optional private end-to-end encrypted iCloud sync.
- **US-076:** Consented read-only natural-language / MCP query assistant.
