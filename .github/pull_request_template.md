## What and why

<!-- What this changes, and why. Link the issue. -->

## Checks

- [ ] `swift format lint --strict --recursive Sources Tests examples Package.swift`
- [ ] `scripts/check-unsafe-swift`
- [ ] `swift build -Xswiftc -warnings-as-errors` and `swift test` (all 43 vectors pass)
- [ ] `scripts/run-examples` and `scripts/build-docs`
- [ ] A test that fails without this change (for a fix)
- [ ] `CHANGELOG.md` updated under "Unreleased" (for anything users notice)
- [ ] No new runtime dependency (or one justified in CONTRIBUTING.md)
