---
name: ios-expense-development
description: Implements one approved iOS Expense Tracker feature as a small tested SwiftUI/domain/persistence slice. Use when coding, fixing, or reviewing a feature in this workspace.
---

# iOS Expense Development Skill

## Before coding

1. Read `AGENTS.md`, `docs/00_PRODUCT_BRAIN.md`, the relevant PRD/UX/architecture/database requirements, story acceptance criteria and applicable ADRs.
2. Inspect existing project files and tests; do not assume the project is empty or rewrite a working architecture.
3. Restate the user-visible behavior, acceptance criteria, out-of-scope items and unresolved assumptions.
4. Create a small file-level plan. If scope crosses privacy, data semantics, schema, deployment target, backend or App Store behavior, stop and ask for approval.

## Implementation

1. Implement the smallest vertical slice that satisfies the approved story.
2. Keep business rules outside SwiftUI views. Use repository boundaries and existing conventions.
3. Validate amounts and dates before persistence; use integer minor currency units.
4. Preserve offline behavior. Do not introduce network, telemetry, AI, third-party dependencies or new permissions unless explicitly approved.
5. Handle loading, content, empty and recoverable error states. Provide VoiceOver semantics and Dynamic Type support.
6. For speech/receipt/AI-derived data, keep a user-editable draft and explicit save step; never retain raw content by default.
7. Avoid destructive migrations or data loss. Add a migration and regression test whenever schema changes.

## Verification

1. Add/update unit tests for domain calculations, validation, parser behavior and date boundaries.
2. Add persistence or UI tests for the critical user path where feasible.
3. Run available formatter/linter/build/test commands; prefer the project’s existing scripts.
4. If Xcode/macOS is unavailable, state that build/simulator/device verification remains outstanding; do not claim success.
5. Inspect diff for accidental transaction logging, secrets, unnecessary package changes, broken accessibility or out-of-scope features.

## Completion report

Return: requirements met; files changed; tests added; exact commands and results; known limitations; spec/ADR updates; and the next smallest task. Never mark an acceptance criterion done based solely on generated code inspection.
