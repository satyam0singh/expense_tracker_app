# Plan of Action — Starting in Antigravity

This is the practical “what to do next” sequence for the product owner and the Antigravity agent.

## A. Before opening Antigravity

1. Download/unzip this starter pack into a dedicated project folder.
2. Decide whether the workspace already contains an Xcode project. If it does, place the docs into that repository without replacing its existing files.
3. Confirm access to macOS/Xcode for native builds. Antigravity can generate and edit files, but successful iOS simulator/device validation requires the appropriate Apple toolchain.
4. Review `docs/12_OPEN_QUESTIONS.md`. At minimum, confirm the deployment target and the MVP meaning of the Home headline. Use the proposal in `docs/11_ADR_LOG.md` if you agree.
5. Initialize Git and make a baseline commit before code-generation changes.

## B. First Antigravity session — read-only review

Open the project root as the Antigravity workspace. Workspace instructions live in `AGENTS.md`; the project rules and skills are under `.agents/`. Ask the agent to perform the read-only review using the prompt in `docs/13_ANTIGRAVITY_MASTER_PROMPT.md` or invoke the `project-kickoff` skill.

Expected output: workspace inventory, product summary, blockers, a proposed first milestone and explicit statement that no code changed. Correct any misunderstanding before implementation.

## C. Approve the first vertical slice

Recommended first coding milestone:

1. Confirm target iOS/deployment version and persistence decision.
2. Create/verify Xcode project and unit-test target.
3. Add app launch shell, navigation placeholder, domain money/date types and deterministic calculation tests.
4. Build/run on a simulator. Do not implement voice, sync or AI during this milestone.

Approve this milestone explicitly. Require the agent to list exact files and acceptance criteria before it edits.

## D. Build in phase order

Follow `docs/06_IMPLEMENTATION_PLAN.md` and the backlog in `docs/08_EPICS_AND_USER_STORIES.md`:

1. Domain + local persistence.
2. Onboarding.
3. Manual transactions and Activity.
4. Dashboard and budgets.
5. Voice capture with user review.
6. Privacy, CSV export, accessibility and QA.
7. Only then decide which V1 features justify implementation.

One agent task should usually fit one story or a small related pair. Do not ask the agent to “build the entire app” in a single prompt.

## E. Per-feature working loop

1. Read relevant specs and current code.
2. Restate story ID and acceptance criteria.
3. Report assumptions and plan.
4. Implement the minimum slice.
5. Add/update tests and run them.
6. Inspect the diff for privacy, data and accessibility regressions.
7. Update docs/ADR/backlog if behavior or decisions changed.
8. Report files, exact commands/results, limitations and next task.

## F. Review checkpoints

- **After Phase 1:** approve architecture and money/date tests before saving real user data.
- **After Phase 3:** test normal manual capture before adding voice.
- **After Phase 4:** verify every dashboard value with hand-calculated cases; review copy for “bank balance” ambiguity.
- **After Phase 5:** test spoken amounts/dates, denied permissions and offline behavior with actual supported devices/languages.
- **Before TestFlight/App Store:** complete security/privacy, accessibility, export/delete, support and release checklists; inspect all permissions and store disclosures.

## Copy-ready first prompt

```text
Read AGENTS.md, docs/00_PRODUCT_BRAIN.md, docs/01_PRD.md, docs/04_TECHNICAL_ARCHITECTURE.md, docs/05_DATABASE_API_SPEC.md, docs/06_IMPLEMENTATION_PLAN.md, docs/11_ADR_LOG.md and docs/12_OPEN_QUESTIONS.md. Inspect the current workspace and do not edit files or create code yet. Summarize what exists, the product, MVP boundaries, proposed technical choices, blocking decisions, any contradictions in the specs, and the smallest safe first milestone with acceptance criteria and tests. Clearly mark proposals versus approved decisions. End by confirming that you made no changes.
```

## Copy-ready implementation prompt

```text
Implement only story [ID] from docs/08_EPICS_AND_USER_STORIES.md. First inspect the workspace and read the relevant PRD, UX, architecture, database, privacy and ADR requirements. Before editing, restate acceptance criteria, out-of-scope items, assumptions and a small file-level plan. If a high-impact decision is missing, stop and ask. Implement the smallest vertical slice, add/update tests, run the available Xcode build/tests, inspect the diff for privacy/accessibility/data regressions, update affected docs, and report exact files and command results. Do not add unrelated features, dependencies, networking, analytics or permissions.
```

## Copy-ready review prompt

```text
Review the current diff against the story acceptance criteria and docs/00_PRODUCT_BRAIN.md. Do not edit code yet. Look specifically for money/date calculation defects, transaction duplication, budget-vs-balance mislabeling, persistence/migration risk, data exposure in logs, permission timing, voice low-confidence saves, accessibility, error/empty states, and missing tests. List blockers separately from suggestions and cite file/line locations. Do not claim tests passed unless you ran them.
```

## Antigravity note

Use the workspace `AGENTS.md` and `.agents/rules/*.md` for persistent instructions and `.agents/skills/*/SKILL.md` for task procedures. This starter pack intentionally uses Skills rather than legacy workflows; verify the current [Antigravity Rules](https://antigravity.google/docs/rules/) and [Agent Skills](https://antigravity.google/docs/skills/) documentation if configuration changes.
