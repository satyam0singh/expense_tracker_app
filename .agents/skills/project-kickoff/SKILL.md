---
name: project-kickoff
description: Reviews the iOS Expense Tracker specification pack, identifies blockers, and prepares a safe first milestone. Use when opening this project, starting a new milestone, or planning work before code changes.
---

# Project Kickoff Skill

## Goal
Orient the agent and product owner before code changes. Do not create or modify app code during the initial review unless the user explicitly asks to move from review into implementation.

## Procedure

1. Read `AGENTS.md`, `docs/00_PRODUCT_BRAIN.md`, `docs/12_OPEN_QUESTIONS.md`, the relevant product specs, and `docs/11_ADR_LOG.md`.
2. Inspect the actual workspace and identify whether an Xcode project, source, tests or assets already exist.
3. Summarize the product in a few sentences, the approved scope, the relevant acceptance criteria and the non-goals.
4. List unresolved questions; distinguish true blockers from choices that can wait. Do not invent high-impact decisions.
5. Propose one small milestone with: objective, in-scope/out-of-scope work, files likely to change, acceptance criteria, tests and risks.
6. Ask for approval before creating an Xcode project, adding packages, changing persistent schema, requesting external services or implementing a blocked decision.
7. After approval, implement only the approved milestone using `ios-expense-development` skill; update docs/ADR if an approved decision changes.

## Initial review output

- Workspace state (what exists, not what is assumed).
- One-paragraph product summary.
- Top blocking decisions with defaults shown as proposals.
- Recommended first vertical slice.
- Commands/build environment needed for validation.
- Confirmation that no code changes were made during read-only review.
