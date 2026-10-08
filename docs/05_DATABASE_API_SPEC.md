# Database and API Specification — iOS Expense Tracker

**Status:** proposed local schema for MVP; remote API is a future contract draft only.  
**Important:** this file describes domain behavior, not a decision to build a backend.

## 1. Persistence rules

- Generate stable UUIDs at creation; never identify records by list position.
- Persist monetary amounts as integer minor units (`Int64`) with a currency code. Never use `Float`/`Double` for monetary values.
- MVP currency defaults to INR; retain `currencyCode` for future compatibility. No FX conversion in MVP.
- Persist the transaction’s **local calendar date** as a date-only canonical value (e.g. `YYYY-MM-DD`) so timezone changes do not shift a purchase into another month. Record `createdAt`/`updatedAt` as UTC timestamps.
- Amount is positive; direction/type controls whether it is spending, income, refund or transfer.
- User deletion/undo semantics and SwiftData/Core Data migrations must be explicit.

## 2. Local entities

### UserProfile (local singleton)

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable local identity. |
| displayName | String? | Optional; not required to use app. |
| defaultCurrencyCode | String | MVP default INR. |
| localeIdentifier | String | Formatting preference/system locale. |
| expectedMonthlyIncomeMinor | Int64? | Optional planning figure in default currency; never included in actual income totals. |
| budgetPeriodMode | enum | MVP `CALENDAR_MONTH`; future `CUSTOM_PAY_CYCLE`. |
| onboardingCompletedAt | Date? | Completion state, not personal financial data. |
| createdAt / updatedAt | Date | UTC timestamps. |

### Category

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable identity. |
| name | String | Current display name. |
| categoryType | enum | Expense, income or both as supported. |
| iconKey | String | Semantic key, not a remotely loaded image. |
| sortOrder | Int | User-controlled ordering. |
| isDefault | Bool | Seeded vs user-created. |
| isArchived | Bool | Archive instead of hard-delete when referenced. |
| createdAt / updatedAt | Date | UTC timestamps. |

### Transaction

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable ID; unique. |
| type | enum | `EXPENSE`, `INCOME`, `REFUND`, `TRANSFER` (transfer support may be deferred in UI). |
| amountMinor | Int64 | Must be > 0. |
| currencyCode | String | ISO 4217 code; INR MVP. |
| categoryId | UUID? | Optional only for explicit uncategorized/transfer cases. |
| categoryNameSnapshot | String? | Preserves historic meaning if category renamed/archived. |
| merchant | String? | Optional; user-entered or voice-confirmed. |
| note | String? | Optional; never sent to telemetry. |
| transactionDay | String | Local date `YYYY-MM-DD`; stable calendar semantics. |
| paymentMethod | enum? | Cash, UPI, debit card, credit card, bank transfer, wallet, other. No linked account implied. |
| source | enum | Manual, voice, import, recurring (future). |
| recurringRuleId | UUID? | Future relation; nil for MVP. |
| createdAt / updatedAt | Date | UTC timestamps. |
| deletedAt | Date? | Soft-delete/undo/tombstone support. |

### Budget

| Field | Type | Notes |
|---|---|---|
| id | UUID | Stable identity. |
| periodStart / periodEnd | String | Inclusive local calendar dates. |
| scope | enum | `TOTAL` or `CATEGORY`. |
| categoryId | UUID? | Required for category scope; nil for total. |
| limitMinor | Int64 | Must be >= 0. |
| currencyCode | String | Must match the period’s supported currency. |
| warningThresholdPercent | Int? | Optional; valid 1–100. |
| createdAt / updatedAt | Date | UTC timestamps. |

### Future-only entities

- `RecurringRule`: title, type, amount, currency, cadence, next due date, category, reminder opt-in, active status. A rule is a planned commitment, not a posted transaction.
- `ReceiptAttachment`: protected local file reference and metadata; raw image is not analytics content.
- `CreditCard`: later phase only; limit, statement/due dates and payment records need separate liability semantics.
- `AuditEvent`: later if AI/sync requires provenance. MVP can use soft-delete/undo and update timestamps without a verbose permanent event log.

## 3. Relationships and deletion

- Category 1 → many Transactions; category archive does not delete transactions or snapshots.
- Budget may refer to a Category; deleting/archiving a category must not corrupt a saved budget/history.
- A future recurring transaction references a recurrence rule but is still a separately confirmed/postable transaction.
- A future transfer/card payment must not appear as expense/income in spending totals.
- Hard-delete versus tombstone for MVP must support “Delete all local data.” Individual deletion may use soft delete for undo; retention window must be short and documented.

## 4. Calculation contract

Let `period` be a selected local-date interval and only include non-deleted, confirmed records with matching currency.

```text
recordedIncome = sum(INCOME.amountMinor)
recordedExpenses = sum(EXPENSE.amountMinor)
recordedRefunds = sum(REFUND.amountMinor)  # assigned to the original/category when available
actualNet = recordedIncome + recordedRefunds - recordedExpenses
netBudgetSpend = max(0, recordedExpenses - refundsAssignedToBudget)
budgetRemaining = totalBudget.limitMinor - netBudgetSpend
budgetUsedPercent = netBudgetSpend / totalBudget.limitMinor * 100  # undefined when limit is zero
```

- Exclude `TRANSFER` from expenses and income.
- Define refund category/period treatment before shipping the refund UI; default MVP may defer explicit refund type and support refunds as negative expense only if domain invariants remain clear.
- Category totals must sum consistently to eligible net spend, with uncategorized shown separately.
- `budgetRemaining` may be negative (over budget); do not clamp the underlying calculation.
- No recurring income should be counted as actual until a corresponding income transaction exists.
- Safe-to-spend projections are later; formula and user assumptions must be approved before implementation.

## 5. Indexing and migrations

Add indexes/unique constraints only where demonstrated by queries: transaction date + deleted status, type, category ID and normalized searchable merchant. Ensure stable case/diacritic behavior is defined for search. Every schema change needs a migration and migration test from the last supported version. Do not destroy user data to simplify a migration.

## 6. Repository interfaces (MVP)

```text
TransactionRepository
  add(draft) -> Transaction
  update(id, changes) -> Transaction
  delete(id) -> UndoToken / status
  undoDelete(token) -> Transaction
  list(period, filters, page) -> [Transaction]
  observeSummary(period) -> Summary

CategoryRepository
  list(includeArchived) -> [Category]
  create/update/archive(category)

BudgetRepository
  get(period) -> Budget?
  save(budget)
```

Exact Swift signatures should match the existing codebase and selected persistence framework; keep UI independent from ORM model types.

## 7. Future REST API draft (not MVP scope)

If a server is approved, begin with authenticated, versioned JSON endpoints:

```text
GET    /v1/me
GET    /v1/transactions?from=YYYY-MM-DD&to=YYYY-MM-DD&type=&categoryId=&q=&cursor=
POST   /v1/transactions
GET    /v1/transactions/{id}
PATCH  /v1/transactions/{id}
DELETE /v1/transactions/{id}
GET    /v1/categories
POST   /v1/categories
PATCH  /v1/categories/{id}
GET    /v1/budgets?from=YYYY-MM-DD&to=YYYY-MM-DD
PUT    /v1/budgets/{id}
GET    /v1/analytics/summary?from=YYYY-MM-DD&to=YYYY-MM-DD
GET    /v1/analytics/categories?from=YYYY-MM-DD&to=YYYY-MM-DD
```

- Use authenticated ownership from server-side identity; never trust a client-provided user ID for authorization.
- Validate money, currency, dates, enum values and payload size on server.
- Writes should support an idempotency key to prevent duplicate submission after retry.
- Use stable IDs, `createdAt`, `updatedAt`, and `deletedAt` for future sync. Conflict behavior needs an ADR.
- Example error shape:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Amount must be greater than zero",
    "details": {"field": "amountMinor"}
  }
}
```

- HTTPS only; refreshable auth tokens in Keychain; rate-limit expensive/AI endpoints; do not expose stack traces.

## 8. Export format

CSV includes selected date, type, amount, currency, category, merchant/note and payment method. Escape commas, quotes and newlines correctly; use UTF-8 and a documented date/decimal format. Preview the requested range and fields before presenting the system share sheet. Do not export hidden/deleted records unless a recovery export is explicitly designed.
