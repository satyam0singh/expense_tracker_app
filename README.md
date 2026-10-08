# iOS Expense Tracker — Antigravity Starter Pack

**Status:** product, design and engineering specifications. This is not yet an Xcode project or a running app.

This pack turns the attached Android-oriented documents, the feature ideation, and the linked Expense Tracker MCP repository into a native-iOS-ready specification. The product name is intentionally **TBD**; do not ship the old working name or copy another app’s branding/UI.

## Start here

1. Open this folder as the workspace in Google Antigravity.
2. Read `AGENTS.md` and `docs/00_PRODUCT_BRAIN.md`.
3. Start with the **read-only review prompt** in `docs/13_ANTIGRAVITY_MASTER_PROMPT.md`. Ask the agent to identify assumptions and blockers; do not let it create app code yet.
4. Resolve the small set of blocking decisions in `docs/12_OPEN_QUESTIONS.md` (especially minimum iOS version and “money left” semantics).
5. Use the **project kickoff** skill, then build one milestone at a time with the **iOS expense development** skill.
6. Before each milestone, review the implementation plan and relevant acceptance criteria; after each, run tests and update the docs.

## Pack contents

| File | Purpose |
|---|---|
| `AGENTS.md` | Always-relevant workspace instructions for Antigravity. |
| `docs/00_PRODUCT_BRAIN.md` | Product context, principles, non-goals and rules for resolving ambiguity. |
| `docs/00_FEATURE_IDEATION.md` | The original feature ideation and priority tiers. |
| `docs/01_PRD.md` | Product requirements and MVP boundary. |
| `docs/02_BRD.md` | Business goals, positioning, stakeholders, risks and measures. |
| `docs/03_UX_UI_SPEC.md` | Navigation, screen behavior, flows, states and accessibility. |
| `docs/04_TECHNICAL_ARCHITECTURE.md` | Native iOS stack, layers, offline-first approach and integrations. |
| `docs/05_DATABASE_API_SPEC.md` | Local data model, calculation rules and a future API contract. |
| `docs/06_IMPLEMENTATION_PLAN.md` | Phase gates from foundation through later capabilities. |
| `docs/07_PLAN_OF_ACTION.md` | Practical first steps and reusable Antigravity prompts. |
| `docs/08_EPICS_AND_USER_STORIES.md` | Backlog starter with story IDs and acceptance criteria. |
| `docs/09_TEST_PLAN.md` | Unit, persistence, parser, UI, privacy and release testing. |
| `docs/10_SECURITY_PRIVACY.md` | Data handling, voice, permissions, threat boundaries and privacy requirements. |
| `docs/11_ADR_LOG.md` | Proposed architecture/product decisions and their status. |
| `docs/12_OPEN_QUESTIONS.md` | Blocking decisions vs questions that can wait. |
| `docs/13_ANTIGRAVITY_MASTER_PROMPT.md` | Copy-ready prompts for kickoff, implementation and review. |
| `docs/14_RELEASE_CHECKLIST.md` | TestFlight/App Store readiness checklist. |
| `docs/15_REQUIREMENTS_TRACEABILITY.md` | PRD-to-story-to-test coverage map. |
| `.gitignore` | Starter ignore rules for Xcode/macOS/Swift Package Manager artifacts and local secrets. |
| `.agents/rules/` | Short, persistent product and Swift implementation invariants. |
| `.agents/skills/` | Antigravity skills for project kickoff and small, verified feature delivery. |

## Source-of-truth order

1. Explicit, approved decisions in `docs/11_ADR_LOG.md`.
2. Product boundaries in `docs/00_PRODUCT_BRAIN.md` and `docs/01_PRD.md`.
3. UX and engineering details in their corresponding specifications.
4. Implementation plan and backlog for sequencing.

If a high-impact detail is missing or contradictory, Antigravity must surface it instead of inventing a product decision. Update the relevant spec and ADR before implementation.

## Product defaults in this pack

- Native iOS; SwiftUI UI; proposed iOS 17+ floor pending confirmation.
- Local-first, offline-capable, INR-first. No bank aggregation or network dependency for core tracking.
- Calendar-month budgets in the initial MVP. “Safe to spend until payday” is an estimate for a later phase, not a bank balance.
- Voice entry is a differentiator, but parsed details are reviewed before saving; no audio/transcript retention by default.
- No cloud sync, LLM, MCP server, subscription monetization or automatic bank/SMS scraping in the MVP.
- Treat any future MCP/AI connection as opt-in and confirm all financial writes and exports in the app.

## Antigravity configuration

This pack uses workspace `AGENTS.md`, `.agents/rules/*.md`, and `.agents/skills/*/SKILL.md`; skills are preferred over legacy workflows. Google’s current documentation describes these locations and formats: [Rules](https://antigravity.google/docs/rules/) and [Agent Skills](https://antigravity.google/docs/skills/). Check Antigravity’s current UI/docs if the product changes its conventions.

## Practical prerequisites

Building/signing a native iOS app requires macOS with a compatible Xcode installation and an Apple developer account for device/TestFlight/App Store distribution. The Antigravity agent can prepare project files, but a real Xcode build and simulator/device validation remain release gates.
