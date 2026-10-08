# Requirements Traceability Matrix

Use this matrix to keep product requirements, user stories and verification connected. Update it when scope changes. Story IDs live in `docs/08_EPICS_AND_USER_STORIES.md`; test coverage is defined in `docs/09_TEST_PLAN.md`.

| PRD requirement | Story / epic | Main verification |
|---|---|---|
| FR-01 Onboarding | US-010, US-011 | Clean install, skip/setup, relaunch persistence; expected income remains planning-only. |
| FR-02 Home/dashboard | US-040, US-041 | Calculation unit cases; Home UI states; no bank-balance claim. |
| FR-03 Add/edit/delete transaction | US-020, US-021, US-022 | CRUD, validation, duplicate-submit, persistence and undo tests. |
| FR-04 Voice entry | US-050, US-051, US-052 | Parser fixtures, permission denial, review-before-save, no speech retention. |
| FR-05 Categories | US-030, US-031 | Seed idempotency, custom category validation, archive/history test. |
| FR-06 Budgets | US-011, US-040, US-042 | Month boundary, refund, zero/over-budget and percentage tests. |
| FR-07 Search/filter | US-032 | Filter/search tests, empty/no-result UI states. |
| FR-08 Offline/local persistence | US-001, US-020, US-022 | Airplane/offline flow; app relaunch; repository persistence tests. |
| FR-09 Export and deletion | US-060, US-061 | CSV encoding/range/field tests; delete-all confirmation and clean state. |
| FR-10 Accessible errors/states | All UI stories | VoiceOver, Dynamic Type, contrast and manual accessibility review. |
| FR-12 Notifications / Reminders | US-070 | RecurringRulesTests; opt-in permission timing, schedule/update/cancel behavior. |
| FR-13 Recurring items | US-070 | RecurringRulesTests; schedule ≠ posted transaction; manual confirmation without silent auto-post. |
| FR-14 Analytics / Trends | US-077, US-071 | TrendsCalculationTests, PayCycleAndSafeToSpendTests; factual weekly/monthly comparisons and safe-to-spend pace. |
| FR-15 iOS integrations | US-072 | WidgetSnapshotTests, LogExpenseIntentTests; WidgetKit timeline, lock screen accessories, and App Intents. |
| FR-16 Post-V1 Capabilities (later) | US-073–US-076 | Phase 8 candidates: Credit card statement lifecycle, receipt OCR, encrypted sync, consented MCP. |

## Release trace

Before MVP release, every **M** requirement in `docs/01_PRD.md` must map to a passing test or documented manual check. A requirement can only be deferred by a product-owner-approved ADR that updates the PRD, backlog, implementation plan and this matrix.
