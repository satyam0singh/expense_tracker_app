# Product Brain — iOS Expense Tracker

**Status:** approved direction with explicitly marked proposals; product name and several release choices remain open.  
**Audience:** product owner, designer, developer, QA and coding agents such as Antigravity.

## One-sentence product

A calm, privacy-first personal expense tracker that makes recording money activity quick and helps a person understand what remains in their chosen budget period—without pretending to be a bank ledger.

## Why this product exists

People abandon expense tools when adding an ordinary purchase takes too long, the dashboard looks like accounting software, or charts do not suggest what to do next. This product should make capture easier than postponing it and make the financial picture understandable at a glance.

## Target users

**Primary:** students, first-job professionals and freelancers who want lightweight personal budgeting, often track cash/UPI/card spending manually, and prefer an app that does not require linking a bank account.  
**Secondary:** people moving from spreadsheets, users who want to track recurring bills or understand spending patterns without a complex accounting product.

## North-star experience

1. A user can record a typical expense in under 15 seconds manually.
2. After optional voice setup, a common spoken expense can be reviewed and recorded in under 10 seconds.
3. On opening Home, the user can tell which period is shown, how much has been spent, and how much of the configured budget remains.
4. The app works offline and explains what its numbers mean.

## Product principles

1. **Fast over comprehensive.** Keep the common expense path short; put advanced fields behind optional controls.
2. **Honest financial language.** A budget estimate is not an account balance. Label actual, budget-based and projected values separately.
3. **Local-first by default.** A new user can track expenses with no sign-in and no internet connection.
4. **Review before commitment.** Voice, OCR and any future AI can suggest a transaction; the user owns the final save.
5. **Explain, don’t overwhelm.** Prefer a small, factual insight with its reason over a dashboard full of charts.
6. **Respectful, non-judgmental tone.** No shame, fear-based alerts, or unqualified financial advice.
7. **Accessible and native.** Support VoiceOver, Dynamic Type, sufficient contrast, large touch targets, dark mode and familiar iOS behavior.

## What “money left” means

This phrase can mean different things; keep three concepts separate:

- **Actual transaction net for a period:** posted income plus refunds minus posted expenses. It is not a bank balance; cash on hand, unrecorded purchases and external accounts are unknown.
- **Budget remaining:** configured period/category limit minus eligible spending (net of assigned refunds).
- **Safe-to-spend estimate:** a future estimate that can only be shown when the user has supplied enough information (for example, pay cycle, expected income and upcoming commitments). Clearly mark assumptions and forecast status.

**MVP default:** calendar-month budget remaining is the Home headline. Show actual recorded income/expenses as supporting data. Do not call the headline “account balance.” A custom pay-cycle/safe-to-spend view is a later feature after its calculation rules are specified and tested.

## MVP boundaries

**In:** optional profile/currency and expected-income setup, categories, expense and income entries, fast manual capture, voice-to-review capture, activity history, edit/delete/undo, calendar-month budget, basic monthly summary, offline local data, privacy controls and simple CSV export. Expected income is a planning preference, never posted/actual income.

**Out:** bank account aggregation, SMS/notification scraping, money movement, investment/tax/accounting features, mandatory account creation, cloud sync, cloud AI, AI-generated advice, full subscription intelligence, shared household ledger and automatic financial imports.

## India-friendly defaults

- INR/₹ as the suggested initial currency; money values are stored in paise for INR.
- Starter categories include Food & Drink, Groceries, Transport, Shopping, Bills, Health, Education, Travel, Personal and Other.
- Payment method choices may include Cash, UPI, Debit Card, Credit Card, Bank Transfer and Wallet. These are labels, not linked accounts.
- Voice examples can include English and Hinglish. Relative dates such as “kal” can be ambiguous and must be confirmed as an explicit date.
- Do not infer purchases by reading messages or other payment apps.

## Key domain invariants

- Money is represented as signed/typed transaction direction plus a positive `Int64` amount in minor currency units; no `Double` for money.
- A category is optional only when a user explicitly chooses “Uncategorized”; archived categories do not erase historical meaning.
- Expense, income, refund and transfer/payment are distinct concepts. Transfers and credit-card repayments must not inflate expense totals.
- Recurring schedules (later phase) are not the same as actual transactions. Never create a posted expense without a visible rule/consent.
- Voice parsing must validate amount, currency, transaction direction and date; low-confidence or missing information requires correction, not an invented value.
- Transaction contents and voice/receipt content are excluded from production telemetry and logs.

## Business and monetization stance

First validate regular use and trust. No pricing, subscriptions or paywall should be invented by the coding agent. If a freemium model is tested later, keep core manual tracking, local data access and export from being silently locked away; obtain product-owner approval for any limit.

## How to resolve uncertainty

1. Check approved decisions in `docs/11_ADR_LOG.md`.
2. Check product boundaries here and in `docs/01_PRD.md`.
3. Check screen behavior in `docs/03_UX_UI_SPEC.md` and platform/data detail in `docs/04_TECHNICAL_ARCHITECTURE.md` and `docs/05_DATABASE_API_SPEC.md`.
4. Check `docs/12_OPEN_QUESTIONS.md` for unresolved items.
5. If the choice changes data semantics, privacy, user-visible financial meaning, backend scope, or release target, stop and ask the product owner. Record the decision before coding.

## Source notes

The attached pack was Android-focused; this spec translates the product intent, not the Android stack. The linked [Expense_Tracker_MCP repository](https://github.com/satyam0singh/Expense_Tracker_MCP) is a Python MCP server, not an iOS client. Its README describes expense/budget/search/analytics/card/export/audit capabilities; subscription automation is presented as roadmap work. Treat those as references to validate, not as a production dependency or proof of iOS requirements.
