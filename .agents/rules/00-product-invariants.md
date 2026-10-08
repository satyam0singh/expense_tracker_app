---
trigger: always_on
description: Product-wide invariants for the iOS expense tracker; use for all product, UX, data, and code changes.
---

# Product Invariants

- Native iOS, local-first MVP; no mandatory account, bank aggregation, message scraping, backend or cloud AI.
- A budget is not a bank balance. Label actual, budget and forecast separately; never imply account access.
- Store money as integer minor units plus currency; no floating-point money math.
- Expense, income, refund and transfer/payment have distinct semantics; transfers/card repayments must not inflate spending.
- Voice/OCR/AI outputs are drafts. Review before committing; never invent missing amounts/dates or save low-confidence data silently.
- Financial records, merchant/note text, amounts, transcripts and receipts must not enter logs or analytics.
- Follow approved ADRs and `docs/00_PRODUCT_BRAIN.md`; ask about high-impact conflicts instead of guessing.
