# Security policy

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub's
[private vulnerability reporting](https://github.com/Ourea-Technologies/ensemble-weather-swift/security/advisories/new)
for this repository. Do not open a public issue, pull request or discussion
for a security problem.

Include what you found, how to reproduce it, and the versions affected. We
acknowledge reports within three working days and keep you informed until a
fix is released. We credit reporters who want to be credited.

## Supported versions

Security fixes go into the latest release. Before 1.0, only the newest 0.x
minor version is supported.

## What the SDK guarantees

These are tested in `Tests/EnsembleWeatherTests/SecurityTests.swift` and by
the shared vectors:

- the API key never appears in logs, errors, descriptions or dumps;
- the key is never sent to another host on a redirect (nor back after leaving);
- TLS certificate validation is the system's own, with no option to disable it;
- a response body over 64 MiB is an error, not unbounded memory;
- JSON is decoded only into the SDK's concrete model types.

CI runs osv-scanner on `Package.resolved`, a source gate against force
unwraps and `try!`, CodeQL (`security-extended`), zizmor on the workflows,
Dependency Review on pull requests, and OpenSSF Scorecard.

## Scope

This repository is the Swift SDK. For the Ourea API itself, report through
the same channel; we route it.
