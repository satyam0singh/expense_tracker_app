# Workspace Instructions

This repository is the **native iOS Expense Tracker** project. Before making changes, read `docs/00_PRODUCT_BRAIN.md` and the task-relevant spec. The detailed product and engineering source of truth is in `docs/`.

## Non-negotiable invariants

- Build an original iOS product; do not copy another app’s branding, visual assets, or proprietary implementation.
- Prefer SwiftUI and native Apple APIs. Keep money logic outside views and isolate persistence behind repository interfaces.
- Store money as integer minor units. Never use floating-point arithmetic for amounts or budget totals.
- Core tracking must work offline. Do not add a backend, AI provider, analytics SDK, bank/SMS scraping, or third-party dependency without explicit approval.
- Do not claim to know a bank balance. Distinguish actual transactions, configured budget, and any forecast in the UI and calculations.
- Do not silently save an ambiguous voice parse. Show extracted fields for review; retain no raw audio/transcript by default.
- Never log transaction contents, amounts, merchant names, notes, speech transcripts, or receipt contents.

## Agent working protocol

1. Inspect the existing workspace and report what is already present; never assume it is an empty app.
2. State the relevant requirements/acceptance criteria and any assumptions before implementation.
3. Make a small plan and implement one vertical slice at a time. Avoid speculative abstractions and broad rewrites.
4. Add or update tests for business logic and critical flows. Run the strongest available build/test checks; report commands and results honestly.
5. Update the applicable spec, ADR or backlog when a decision changes. Do not resolve high-impact ambiguity silently.
6. Do not claim simulator, device, Xcode, or App Store validation unless it actually ran successfully.

See `.agents/rules/` for persistent product and Swift-specific constraints; use the workspace skills for kickoff and feature delivery.
