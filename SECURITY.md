# Security Policy

## Supported Versions

We provide security updates for the latest minor version of each major release.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please do not open a public issue. Instead, report it to `security@example.com` (placeholder).

We aim to respond to all reports within 24 hours and provide a fix or mitigation strategy within 7 days.

## Critical Classes

We treat the following as high-priority security issues:

1. **Webhook Signature Bypass:** Any flaw that allows an attacker to inject events into the ledger without a valid provider signature.
2. **Tenant Isolation Leaks:** Any flaw that allows one tenant to access or modify another tenant's deliveries, events, or suppressions.

## Disclosure Process

1. Report the issue privately.
2. We acknowledge the report and work on a fix.
3. A security advisory is published once the fix is released.
