# Contributing to ensemble-weather-swift

Thanks for helping. This SDK follows the shared
[SDK standard](spec/SDK-STANDARD.md) and [behaviour spec](spec/BEHAVIOR.md);
read them before changing behaviour. Where they and the code disagree, the
shared vectors in `spec/vectors/` win.

## Setup

You need Swift 6.1 or later (Xcode 26 on macOS, or a swift.org toolchain on
Linux) and Python 3 for the local mock API. Then:

```sh
swift build
swift test
```

Nothing calls the real API: tests and examples use a mock transport or the
local mock server.

## Checks

CI runs exactly these; run them before you push.

| Check | Command |
|---|---|
| Format | `swift format lint --strict --recursive Sources Tests examples Package.swift` (fix with `swift format format --in-place --recursive Sources Tests examples Package.swift`) |
| Security gate | `scripts/check-unsafe-swift` (no force unwraps, `as!` or `try!` outside tests) |
| Build, Swift 6 strict concurrency | `swift build -Xswiftc -warnings-as-errors` |
| Unit tests, vectors, spec drift | `swift test` |
| Examples | `scripts/run-examples` |
| Docs | `scripts/build-docs` |
| README quickstart | `scripts/check-readme` |
| Dependencies | `scripts/check-dependencies` |
| Spec pin | `scripts/sync-spec --check` |

`swift test` runs all 43 shared vectors (`Tests/EnsembleWeatherTests/VectorTests.swift`);
the only Swift-specific code there is the mapping from vector operations to
SDK calls. A vector the runner cannot run fails; never skip one.

## Updating the spec

`spec/` is a copy of
[ensemble-weather-spec](https://github.com/Ourea-Technologies/ensemble-weather-spec)
at the commit in `spec/VERSION`. To move it, write the new ref to
`spec/VERSION` and run `scripts/sync-spec` (set `OUREA_SPEC_SOURCE` to a local
clone to work offline). Never edit `spec/` by hand.

## Dependencies

The library target depends on nothing but Foundation (and
FoundationNetworking on Linux). `scripts/check-dependencies` fails CI if the
library gains a dependency, or if `Package.swift` declares a package missing
from this list. Each entry is the package's identity and why it is here.

- `swift-docc-plugin`: development only, for `swift package generate-documentation`; no target depends on it.

Adding a runtime dependency needs a written justification here and
Harrison's approval.

## Style

- Swift API Design Guidelines; `swift format` with the repository's `.swift-format`.
- Every public declaration is documented (DocC).
- Models are hand-written `Sendable`, `Codable`, `Hashable` value types;
  unknown enum values decode to `.unknown(raw)`.
- The SDK never computes statistics: a helper that seems to need client-side
  math is a request for a new server query.
- Every bug fix ships with a test that fails without it.

## Commits and pull requests

- One logical change per commit; an imperative summary line, then a short
  body saying what and why.
- History on `main` stays linear: rebase, don't merge.
- Add a line to `CHANGELOG.md` under "Unreleased" for anything users notice.
- Releases: a `vX.Y.Z` tag on `main` is the release (`release.yml`).
