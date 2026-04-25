# Security Policy

## Supported Versions

We provide security updates for the latest minor version of each major release.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

Do not open a public GitHub issue for security reports. Use GitHub's
Private Vulnerability Reporting on this repository:
https://github.com/szTheory/mailglass/security/advisories/new — this routes
the report directly to the maintainer without exposing it.

Single-maintainer SLA, written to be kept:

- Acknowledgement of report: within 72 hours.
- Mitigation or workaround for critical issues: within 14 days.
- Public security advisory: published alongside the fix.

## Critical Classes

We treat the following as high-priority security issues:

1. **Webhook Signature Bypass:** Any flaw that allows an attacker to inject events into the ledger without a valid provider signature.
2. **Tenant Isolation Leaks:** Any flaw that allows one tenant to access or modify another tenant's deliveries, events, or suppressions.

## Disclosure Process

1. Report the issue privately.
2. We acknowledge the report and work on a fix.
3. A security advisory is published once the fix is released.
