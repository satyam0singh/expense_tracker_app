---
trigger: always_on
description: Swift and SwiftUI implementation constraints for the iOS expense tracker.
---

# Swift Quality Rules

- Inspect the current Xcode/workspace structure before changing it; preserve working code.
- Keep SwiftUI views focused on rendering and user intent; put calculations, validation, parsing and persistence in testable types.
- Keep persistence behind repository boundaries; do not leak SwiftData/Core Data models through every feature.
- Use explicit loading/content/empty/error states, accessible labels and Dynamic Type support.
- Do not add packages, network services, permissions or background work without a documented requirement and approval.
- Add tests for business logic and critical paths; run Xcode build/tests when available and report exact commands/results.
- Do not claim simulator/device validation unless actually performed.
