# iOS Expense Tracker — Feature Ideation

## Product direction

**A calm, privacy-first money companion that makes it effortless to record spending and clearly answers: “What can I safely spend before my next payday?”**

The source documents call the working concept “Left” and prioritize fast capture, a money-left dashboard, voice entry, simple budgets, local-first storage and understandable insights. Treat “Left” as a working name only; create original branding, language and visual design for the iOS product.

## What I used from the source material

- The attached PRD/BRD/UX/architecture/database/implementation pack defines a minimalist tracker: quick manual and voice entry, income and expenses, budgets, categories, transaction history, monthly summaries, optional recurring commitments, notifications and future sync/AI.
- The linked [Expense_Tracker_MCP repository](https://github.com/satyam0singh/Expense_Tracker_MCP) is a **Python MCP server, not an iOS app**. Its README describes tools for expense CRUD/search, categories, budgets, trends, credit cards and CSV/Excel/PDF exports, plus validation and audit concepts. Its roadmap places recurring subscriptions/rules and broader integrations later, so treat those as ideas to validate—not as already-shipped app features.
- The source pack is Android-specific. For iOS, keep its product principles and translate the implementation to native Apple technologies rather than carrying over Android libraries or copying another product’s branding/UI.

## Recommended feature set

### P0 — A trustworthy, genuinely useful first release

1. **“Left” home screen, with honest numbers**
   - Show the selected pay/month period, income received, expenses, budget remaining and upcoming planned bills.
   - Make the primary figure configurable: “Budget left” for a monthly budget, or “Available until payday” when the user has set a pay cycle and recurring commitments.
   - Keep **actual balance**, **budget remaining** and **forecast** distinct and explicitly labelled. Don’t imply the app knows a user’s bank balance unless it is connected to an account.
   - Add a simple daily/weekly pace indicator and one contextual sentence, not a wall of charts.

2. **Fast transaction capture**
   - Amount-first entry with a large numeric keypad; expense/income toggle; recent and favorite categories; optional merchant/note; date; and payment method (cash, UPI, debit card, credit card, bank transfer, wallet).
   - Save a common expense in a few taps; offer quick-add presets such as “₹50 chai · Cash” without making users fill every field.
   - Make edit, delete and undo obvious. Search and filters can start simple: date, category, type, merchant and payment method.

3. **Voice logging as a first-class path**
   - Support natural phrases such as “₹250 lunch,” “paid 800 for electricity,” or “kal metro 40 UPI,” with English and Hindi-English (Hinglish) in mind.
   - Extract amount, expense/income, category, merchant/note, date and—when clearly spoken—payment method.
   - Show a compact editable review before saving in the initial release. Resolve ambiguous amounts/dates visibly; “kal,” for example, can mean yesterday or tomorrow depending on context.
   - Never silently save a low-confidence parse. Prefer on-device speech recognition where available; explain and ask before sending financial text to a cloud/AI service.

4. **Simple budgets and categories**
   - One monthly total budget plus optional category limits, progress and gentle warning thresholds.
   - Start with useful India-ready categories (Food & Drink, Groceries, Transport, Shopping, Bills, Health, Education, Travel, Personal, Other), then let users add, rename, archive and customize categories.
   - Support a user-defined pay cycle (for example, salary date to the day before next salary), but keep calendar-month view available.

5. **Offline-first data and privacy controls**
   - Core capture, history and calculations work without internet.
   - Offer Face ID app lock, a setting to hide sensitive notification text, clear data deletion and a basic CSV export early in the product’s life.
   - Don’t put transaction details in analytics/crash logs. Keep cloud sync and AI processing opt-in.

### P1 — Retention and useful depth

- **Recurring commitments:** rent, bills, subscriptions and recurring income, with next date, frequency, amount and local reminders. Show expected upcoming outflows separately from money already spent.
- **Practical insights:** month-over-month comparison, category/merchant breakdown, weekly trend and unusually high days. Explain the observation (“Dining is ₹1,200 above your four-week average”) and avoid judgment or unqualified financial advice.
- **Apple-native quick access:** Home/Lock Screen widgets for budget left and an Add action; Siri Shortcuts/App Intents for “log an expense”; notification actions for reminders. These are strong iOS differentiators for reducing missed entries.
- **Export and reports:** filtered CSV first, then a clean PDF month summary using the iOS share sheet. Let users choose the date range and fields before sharing.
- **On-device categorization rules:** let a user choose “Always categorize Metro as Transport.” Show a proposed rule and make it easy to undo.

### P2 — Differentiators to validate after the basics work

- **Manual credit-card tracker:** card nickname, statement/due dates, limit and payment reminders. Model card purchases and card repayments correctly so a repayment is not counted as a second expense.
- **Receipt capture:** scan totals/merchant/date with Apple Vision, then review before saving; detect likely duplicate entries.
- **Split transactions and shared expenses:** split one purchase across categories or record “paid by me / owed by friend” for trips or roommates. Keep repayments distinct from income.
- **“Ask my spending” assistant:** questions such as “How much did I spend on food last month?” Start with deterministic, read-only answers. If adding an MCP-compatible connection later, scope it narrowly, require consent, and confirm every write/export in the app. Don’t expose a local database directly to an untrusted model.
- **Optional backup/sync:** offer opt-in iCloud/private sync only after local data, restore and deletion behavior are well tested. Avoid making an account mandatory for the core app.

## Suggested screen flow

1. **Onboarding:** currency/locale (INR as an India-friendly default), optional income and budget, optional pay date, choose starter categories. Skip anything the user doesn’t know yet.
2. **Home:** a clear “left” amount, period label, spent vs budget, next known bill, recent transactions and a prominent Add button.
3. **Add:** amount keypad → type/category → optional merchant, payment method and note → save; microphone is available from the same entry point.
4. **Activity:** date-grouped transactions, search/filter, tap to edit, undo after deletion.
5. **Budgets / Insights:** simple progress and a small number of explanatory observations.
6. **Settings:** currency, pay cycle, categories, notifications, Face ID, export, backup and delete-data controls.

## Important product/data decisions

- Store money as integer minor units (paise for INR), never floating-point values.
- Keep a recurring *schedule* separate from the transactions it produces; don’t silently create duplicate expenses.
- Consider distinct transaction types for expense, income, refund and transfer/card repayment. This prevents transfers and credit-card payments from inflating spending totals.
- Preserve historical category labels when a category is renamed or archived. Keep a recoverable undo/audit trail for edits/deletes, especially if voice or AI actions are introduced.
- For India, support ₹/INR, cash/UPI/card payment methods, salary-date budgeting, and Hinglish voice phrases. Do not depend on scraping bank SMS or another payment app in the MVP.

## iOS implementation translation

Use **SwiftUI** for the native interface; **SwiftData or Core Data** for local persistence; Keychain for secrets; **LocalAuthentication** for Face ID; **WidgetKit and App Intents** for widgets/Shortcuts; Apple speech/vision frameworks for optional voice and receipt capture; and local notifications for reminders. Keep the data layer and money-calculation rules independent of the UI so they can be unit-tested. Use CloudKit only as an opt-in later phase. iOS background execution is constrained, so schedule local reminders rather than relying on frequent background jobs.

## Suggested release sequence

- **MVP:** onboarding, offline transaction CRUD, clear dashboard, basic budgets/categories, fast manual entry, voice capture with review, monthly summary, privacy controls and tests for money/month-boundary calculations.
- **V1:** pay-cycle budgeting, recurring bills/reminders, search/filter improvements, Apple widgets/Shortcuts, stronger trends, CSV/PDF export and categorization rules.
- **Later:** card-cycle tracking, receipt scanning, shared expenses, optional sync, and a consented natural-language/MCP assistant.

This sequencing reconciles a small mismatch in the source pack: voice is a core differentiator in the PRD/BRD, while subscriptions, richer analytics and notifications are marked “Should” or scheduled after the MVP in the implementation plan. Build reliable manual entry and calculations first, then add voice before the first public release; defer the full subscription/AI/sync scope.

## Success measures worth tracking

- Time to first transaction and time to record a typical expense (target: under 15 seconds manually; under 10 seconds by voice after setup).
- Onboarding completion, first-week return rate and percentage of active users who record expenses weekly.
- Voice correction rate, duplicate-entry rate and edit/delete recovery failures.
- Budget alert usefulness (dismissals/opt-outs as well as opens), not just notification volume.
- Track technical performance without collecting raw transaction content.

## Best next product decision

Before designing screens, agree on what **“money left”** means: budget remaining, net income minus expenses, or an estimated safe-to-spend amount until payday. My recommendation is to show all three concepts only when relevant, label each clearly, and make **“available until payday”** the headline only after the user provides a pay cycle and expected bills.