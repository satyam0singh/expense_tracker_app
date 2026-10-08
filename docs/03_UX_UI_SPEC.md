# UX/UI Specification — iOS Expense Tracker

**Design intent:** minimal, calm, native, readable and fast. Use original branding and visual design; this document is interaction guidance, not a pixel-perfect reference.

## 1. UX principles

- Show the most useful financial answer first, but label it precisely.
- Make amount entry the easiest part of the add flow; reveal optional fields progressively.
- Do not use color alone to communicate over-budget, success or error.
- Prefer plain-language explanation to unexplained finance terms.
- Preserve familiar iOS behavior: navigation bars, safe areas, sheets where appropriate, system share sheet and permission prompts only in context.
- No guilt-driven wording, flashing urgency or cluttered charts.

## 2. Information architecture

Primary tabs:

1. **Home** — current period, budget status, summary and quick add.
2. **Activity** — dated transaction list, search and filters.
3. **Budgets** — overall/category limits and progress.
4. **Settings** — profile, currency, categories, privacy, export and about.

Use a highly visible **Add** action from Home and Activity, plus App Intent/Shortcut in a later release. Do not make transaction entry depend on deep navigation.

## 3. Screen inventory and requirements

### S01 Launch / routing
- Load local profile and repository state without network calls.
- Route to onboarding only when required first-run preferences are absent; otherwise Home.
- Present recoverable errors; do not clear data or show false empty state on database failure.

### S02 Welcome and onboarding
- Explain value in one sentence and show a sample, clearly labeled budget view.
- Ask locale/currency and optional monthly income/budget; allow Skip and configure later.
- Include a brief privacy explanation before any microphone permission is requested; do not request it during onboarding.
- Provide progress and back navigation. Completion should work with only required preferences.

### S03 Home
Visual hierarchy:
1. Period selector and month/year label.
2. Primary **Budget remaining** (or “No budget set” guidance); never “bank balance.”
3. Spent vs budget progress with text and numeric values.
4. Recorded income and expenses; if expected monthly income is configured, show it separately and label it “Expected,” never merge it into actual income.
5. Recent transactions, empty state and Add action.
6. At most one or two factual insights after data exists.

States: first-use empty, no budget, zero income, budget exceeded, month with no transactions, calculation/loading issue, offline (tracking still works). Month navigation must not silently change user’s budget.

### S04 Add / edit transaction
- Amount entry first; custom numeric input must support decimal input appropriate to currency.
- Segmented type choice: Expense / Income; refund/transfer not part of MVP UI unless implemented under a documented story.
- Category selection with recent/favorites and searchable list.
- Optional merchant/title, note, payment method and date.
- Show currency clearly and validate amount > 0 before Save.
- Save only after persistence succeeds. Provide a brief success/undo affordance; on failure say whether data was saved (normally no) and how to retry.
- Editing should preserve existing values and support cancellation without accidental save.

### S05 Voice capture and review
States: idle → permission explanation → listening → transcribing/parsing → review → saved; plus cancel, permission denied, no speech, unsupported language, offline limitation and parsing error.

Review card fields: type, amount/currency, category, merchant/note, explicit date and payment method if extracted. Each field is editable. Unknown values stay unknown; do not fabricate a category/date. The initial MVP always shows the review before save. “Add” commits once; disable duplicate taps while saving. Cancel discards the draft.

### S06 Activity and transaction detail
- Group rows by local transaction date; row shows category, merchant/note, amount and income/expense signifier.
- Search merchant/note; filter by period, category and type. Display no-result state and clear filters action.
- Detail offers edit, delete with undo/confirmation, and source indicator (manual/voice) only when useful.
- Archived categories retain historical display name/icon snapshot.

### S07 Budgets
- Display period total and optional category limits with amount spent, remaining and percentage.
- Warnings at user-configurable thresholds; use text/icon plus color.
- Explain calculation basis and refunds. If no budget exists, offer setup, not a fake zero.

### S08 Settings / data controls
- Currency/locale; custom categories; default period; optional app lock; notification preferences; CSV export; delete all local data; privacy/about.
- Export preview: date range, fields, row count and destination share sheet. Never share without user action.
- Delete flow explains irreversibility, requires explicit confirmation, then returns to a clean first-run state.

## 4. Core flows

### First run → first transaction
Welcome → choose currency (default suggested, editable) → optional budget/profile → Home → Add → amount/type/category/date → Save → updated Home.

### Quick manual expense
Home/Activity → Add → amount → recent category → optional payment method/note → Save. Minimize required fields; no forced account linking.

### Voice transaction
User taps mic → sees why speech permission is requested → speaks → editable parse appears with date made explicit → user corrects if needed → Add → success. On denial, provide manual entry path without pressure.

### Edit/delete
Open transaction → Edit → Save; or Delete → confirm/undo according to implementation. Recompute any summaries from source transactions; never rely on stale totals.

## 5. Visual and content direction

- Create independent color, icon and typography tokens after design review. Avoid copying the referenced “Left” app or MCP README art.
- Use system type scales and SF Symbols where suitable; decorative gradients are optional and should not reduce contrast.
- Prefer sentence case and short labels: “Budget left,” “Spent this month,” “Add expense.”
- Explain “Recorded” or “Estimate” near non-obvious totals.
- Use date examples that show full dates when voice parsing involved.

## 6. Accessibility and localization

- VoiceOver names/value/hints for buttons, money amounts, progress and charts.
- Dynamic Type through largest supported accessibility sizes; no clipped totals.
- Touch targets meet Apple accessibility guidance; keyboard/switch-control navigation where applicable.
- Contrast is tested in light/dark modes; no status represented by red/green alone.
- Respect Reduce Motion and system settings.
- Format INR and dates with locale-aware system formatters. Do not assume language from currency. Test English and Hindi/Hinglish text expansion; keep parser language support distinct from UI localization.

## 7. UX acceptance checks

- New user can reach a saved manual expense without a tutorial.
- Voice permission appears only after mic tap; denial leaves manual flow usable.
- Voice result is reviewed and every extracted field is editable.
- Home distinguishes spending from budget and does not imply bank knowledge.
- Empty/error states provide the next action and never display unexplained blank screens.
