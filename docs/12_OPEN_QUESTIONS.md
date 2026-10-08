# Open Questions and Assumptions

Resolve the **blocking** items before production architecture and App Store setup. The coding agent must not silently choose them. Non-blocking items can remain deferred.

## Blocking before Xcode project / first persistent schema

| ID | Question | Working default | Why it matters |
|---|---|---|---|
| OQ-01 | What is the final product name, bundle ID and brand? | Name TBD; use a non-shipping development bundle ID. | Branding, App Store identity and bundle IDs are difficult to change later. |
| OQ-02 | What is the minimum supported iOS version? | Propose iOS 17+ for SwiftData feasibility; confirm device reach before coding. | Determines SwiftData/Core Data and API availability. |
| OQ-03 | Is India/INR the first market, and are Hindi/Hinglish voice phrases required for first release? | INR-first and Hinglish-aware parsing; UI English initially unless localization is separately approved. | Affects currency defaults, parser, formatting and testing. |
| OQ-04 | What should Home call its main number? | “Budget remaining” for MVP; never bank balance. | Financial meaning must be agreed before copy/calculations. |
| OQ-05 | Should explicit refunds and transfers be supported in MVP UI? | Model types safely; defer UI if scope requires. | Affects totals and double counting. |
| OQ-06 | Must voice work fully offline? | Use on-device recognition when supported; if a network is required, disclose and ask consent; always retain manual entry. | Speech availability differs by device/language and permission. |
| OQ-07 | Who will build and sign the app, and is a Mac/Xcode environment available? | Assume native build/test is performed on macOS by owner/engineer. | Required for real simulator/device build and distribution. |

## Can be decided after MVP baseline

| ID | Question | Working default |
|---|---|---|
| OQ-08 | Which pay-cycle model and forecast calculation should V1 support? | Defer; calendar month first. |
| OQ-09 | Should recurring commitments create draft transactions automatically? | No auto-post by default; reminder/confirm first. |
| OQ-10 | Is optional iCloud sync desired, or local-only long term? | Local-only until validated. |
| OQ-11 | Should Face ID app lock be on by default or opt-in? | Opt-in, with OS device authentication fallback as designed. |
| OQ-12 | Should CSV export include notes/merchant by default? | Show fields/range preview; user chooses. |
| OQ-13 | Which exact App Store regions, languages and accessibility targets are required? | India-focused initial research; confirm before release. |
| OQ-14 | What is the monetization model and premium boundary? | No paywall in MVP; validate later. |
| OQ-15 | Is credit-card tracking a must-have? | Later; not in MVP. |
| OQ-16 | Is “Ask my spending”/MCP integration a product goal? | Not MVP; any future access is opt-in, scoped and confirm-before-write. |

## Assumptions currently used in the specs

1. The initial user enters transactions manually or by reviewable voice; no institution integration.
2. The MVP is single-device/local-first with no account required.
3. Calendar-month budget is the first release calculation window.
4. Income configuration is not treated as actual income until logged as a transaction.
5. The transaction date is a local calendar day; creation/update timestamps are UTC.
6. Recurring bills, cards, receipts, sync and AI/MCP are future-phase capabilities.
7. Release will be tested with Xcode on macOS; agent reports may not substitute for this gate.
