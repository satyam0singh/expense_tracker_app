# Security and Privacy Requirements — iOS Expense Tracker

**Security posture:** sensitive personal finance data. This document is a product/engineering baseline, not legal advice or a completed threat assessment.

## 1. Data classification

Treat transactions, amounts, merchant names, notes, budgets, income, receipts, transcripts and inferred categories as sensitive financial/personal data. User preferences and app diagnostics may also be identifying. Do not collect more than the product needs.

## 2. MVP privacy commitments

- Core tracking is local-first and works without account creation or internet.
- No bank aggregation, SMS/notification scraping, payment-app scraping or background financial data access.
- No transaction contents in logs, analytics, crash reports or support screenshots by default.
- Microphone access only after the user taps the voice action and sees contextual explanation.
- Do not retain raw audio/transcript by default. Speech provider/device behavior must be explained when network processing is involved; obtain consent before sending.
- Notifications are opt-in; never reveal merchant/amount on the lock screen unless the user explicitly chooses detailed previews.
- CSV/PDF files may contain sensitive data; preview scope, present the native share sheet only on user action, use a protected temporary location and clean up temporary files when safe.
- Clear, accessible path to export and delete local data.

## 3. Local storage and app lock

- Use platform data protection for files/database where supported; verify the actual persistence framework’s behavior rather than claiming encryption that has not been implemented.
- Store credentials/cryptographic keys in Keychain, not source code, UserDefaults or exported config.
- If app lock is provided, use LocalAuthentication and respect device authentication policy; never access or store biometric templates.
- Obscure sensitive app-switcher snapshots when practical, without creating confusing UX.
- Face ID is an app access gate, not a substitute for secure database design.

## 4. Future networking/sync boundary

No backend is in MVP. Before any sync/API/AI work, require:

1. Threat model and data-flow diagram.
2. User identity, authentication, authorization and tenant-isolation design.
3. HTTPS, secure token storage/refresh, deletion and export behavior.
4. Encryption at rest/in transit and backup/restore policy.
5. Conflict handling, tombstones, device unlinking and account deletion.
6. Consent wording, retention, subprocessors and incident response ownership.
7. Strictly scoped AI/MCP tools; read-only by default; in-app confirmation for writes, deletion, sharing or exports.

Never embed a server/API secret in the app binary. Never trust client-supplied user IDs for server authorization. Do not send full transaction history to an LLM when a narrow local calculation answers the question.

## 5. Voice and AI threat boundaries

- Treat speech recognition and generated output as untrusted input.
- Validate amount, date, direction, currency and category before display/save.
- Ambiguous parsing produces a draft requiring confirmation; missing values remain missing.
- Voice permission is scoped to the feature; no always-on listening.
- A future assistant cannot silently edit/delete transactions or infer financial advice.
- If an MCP integration is considered, use least-privilege tools, explicit user identity, authorization checks, auditability and confirmation. The linked Python MCP project is not a substitute for an iOS-specific auth/privacy design.

## 6. Logging and diagnostics

Allowed diagnostics should be minimized (app version, OS version, coarse performance/crash identifiers) and privacy-reviewed. Redact transaction payloads at source; do not rely on dashboard filtering after upload. Ensure error messages never echo transcripts, free-form notes or export contents. No real personal finance data in fixtures/screenshots.

## 7. Data lifecycle

- Define delete vs undo separately. Undo is a short-lived local recovery affordance; delete-all must actually remove app-managed records/preferences and later cloud data if sync is introduced.
- Specify retention for temporary export files and voice buffers.
- Do not keep backups or hidden copies that contradict user deletion expectations.
- Schema migrations must preserve data and be tested. Migration failures should offer safe recovery, not wipe the database.

## 8. Privacy review checklist

Before each release, enumerate collected data, permissions, local files, network calls, third-party SDKs, notifications, exported fields and retention. Compare against App Store privacy disclosures and applicable laws for intended distribution regions. Obtain qualified legal/privacy review where needed.
