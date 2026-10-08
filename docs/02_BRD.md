# Business Requirements Document — iOS Expense Tracker

**Status:** v0.1; commercial assumptions require validation  
**Product name:** TBD  
**Business model:** not decided; validate retention and willingness to pay before pricing

## 1. Executive summary

The product is a lightweight, privacy-respecting personal finance app for users who want to record expenses quickly and understand spending without adopting accounting software or linking a bank. Its differentiating promise is **fast capture + an understandable money-left view + user control over financial data**.

## 2. Business problem and opportunity

Many expense apps ask for too much setup, put charts ahead of practical meaning, or rely on account connections that some users do not want. Spreadsheets are flexible but inconvenient on a phone. An offline-capable, manual-first app can serve users who prefer control, especially students, first-job professionals and freelancers.

## 3. Value proposition and positioning

**Positioning:** “A simple, private way to know where your money is going and how much of your budget remains.”

Compete on ease, clarity, trust and native iOS quick access—not on bank automation, investment tools or enterprise accounting. Voice capture is a differentiator only if it is accurate, reviewable and privacy-transparent.

## 4. Business objectives

| Objective | Outcome | Example measure |
|---|---|---|
| Acquisition | Make value understandable in the first session. | First-session completion; store-page conversion (later). |
| Activation | Get a new user to configure a useful budget and save the first transaction. | First transaction rate/time; optional setup completion. |
| Retention | Make the app worth reopening through a reliable remaining-budget view. | Weekly logging; D7/D30 retention. |
| Trust | Let users track locally, export and delete their records. | Export success; privacy-related support issues; deletion success. |
| Monetization | Test an optional sustainable model only after product value is demonstrated. | Paid conversion and renewal, only after validation. |

## 5. Business requirements

| ID | Requirement | Priority |
|---|---|---|
| BR-01 | Fast and reliable manual expense capture. | Must |
| BR-02 | Clear, non-misleading monthly budget/expense dashboard. | Must |
| BR-03 | Offline-first local expense and income tracking. | Must |
| BR-04 | Reviewable voice capture with explicit privacy behavior. | Must |
| BR-05 | Simple categories, budgets and understandable monthly summaries. | Must |
| BR-06 | Data export and permanent deletion. | Must |
| BR-07 | Optional reminders and recurrence. | Should |
| BR-08 | iOS Home/Lock Screen widgets, Shortcuts and accessibility. | Should |
| BR-09 | Credit-card statement/due tracking and receipt scanning. | Later |
| BR-10 | Optional multi-device sync. | Later |
| BR-11 | Natural-language/MCP finance assistant. | Later, opt-in |
| BR-12 | Paid tier/pricing. | Validate after PMF evidence |

## 6. Proposed business model

Do not implement a paywall in the MVP. After evidence of recurring use, test a free core tracker and a paid tier for convenience/depth (for example, cross-device backup, advanced trends, higher-volume receipt parsing or custom reports). Do not decide exact limits/prices by analogy to another app. Preserve transparency, data export and user deletion regardless of tier; pricing and consumer-protection review are product-owner responsibilities.

## 7. Stakeholders

- Product owner / business sponsor
- iOS engineer or coding agent supervised by an engineer
- UX/UI designer
- QA tester
- Privacy/security reviewer
- App Store / release owner
- Future backend engineer only if sync/AI is approved

## 8. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Users forget cash expenses. | Incomplete data and declining retention. | Quick add, recent/favorite categories, widgets/Shortcuts later; avoid excessive reminders. |
| Voice misreads numbers, dates or Hinglish. | Incorrect financial records. | Editable review, parser tests, explicit dates, confidence states, manual fallback. |
| “Money left” is mistaken for actual bank balance. | Loss of trust and potential harm. | Label metrics, explain data sources, never claim account balance. |
| Financial data exposure. | Severe trust/privacy impact. | Local-first default, minimum permissions, no transaction telemetry, opt-in cloud only. |
| Scope expands into AI, banking and subscriptions. | Delayed release and more failure modes. | Milestone gates, explicit non-goals, approval for new dependencies and services. |
| Platform differences reduce agent ability to validate. | False confidence in build quality. | Xcode/macOS build and simulator/device gates; agent reports exactly what ran. |
| Recurring bills are mistaken for actual transactions. | Incorrect totals. | Keep schedules and posted transactions separate; no silent auto-post in initial release. |

## 9. Commercial acceptance

The app is commercially testable when a new user can install, skip optional setup, add an expense, understand the current month’s budget status, close/reopen the app and trust that the record remains; core tracking does not require an account or connection. Monetization and distribution decisions remain open until discovery/retention evidence exists.
