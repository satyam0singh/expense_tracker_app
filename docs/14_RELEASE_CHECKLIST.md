# Release Checklist — iOS Expense Tracker

Use for internal/TestFlight and App Store readiness. A checked box requires evidence; do not mark complete based only on code generation.

## Product and scope

- [ ] Release scope matches approved PRD/ADR; no unapproved features or hidden network dependency.
- [ ] Final app name, icon, bundle ID, privacy copy and screenshots approved.
- [ ] MVP calculation labels distinguish actual, budget remaining and forecast.
- [ ] Known limitations and support contact are documented.

## Build and quality

- [ ] Xcode build succeeds on the agreed minimum/current supported iOS versions.
- [ ] Unit, persistence, UI and migration tests pass; test evidence records tool/device versions.
- [ ] Manual test flows in `docs/09_TEST_PLAN.md` completed.
- [ ] No critical crashes, data-loss defects, duplicate submissions or unresolved P0 accessibility issues.
- [ ] Performance tested with realistic personal-history volumes; long lists remain responsive.
- [ ] Dependency and privacy manifest review completed for any third-party SDKs.

## Privacy and security

- [ ] Permission prompts are contextual and minimal; voice/notifications are not requested at first launch without need.
- [ ] Speech/device/network behavior is disclosed accurately; audio/transcript retention matches policy.
- [ ] No financial content, secrets or personal files appear in logs/crash reports.
- [ ] Export and delete-all flows tested end to end.
- [ ] Local storage/file protection and app-lock behavior reviewed; no unsupported encryption claims.
- [ ] App Store privacy disclosures match code and all SDK/data practices.
- [ ] Privacy policy/legal review completed for distribution regions; this checklist is not legal advice.

## UX and accessibility

- [ ] VoiceOver, Dynamic Type, contrast, dark mode, Reduce Motion and minimum targets reviewed.
- [ ] Empty/loading/error states provide clear next actions.
- [ ] Currency/date formatting correct for supported locales; no clipped values.
- [ ] Permission-denied and offline states remain usable.

## Distribution

- [ ] Signing certificates/profiles and App Store Connect metadata configured securely.
- [ ] TestFlight test plan, known issues and rollback plan prepared.
- [ ] Store screenshots/video use synthetic data only.
- [ ] Version/build number and migration strategy confirmed.
- [ ] Post-release support/monitoring owner and incident contact identified.
- [ ] Final release review by product owner and iOS reviewer completed.
