# Phase 14: Resend Webhook Provider & Core Ingest - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 14-Resend Webhook Provider & Core Ingest
**Areas discussed:** Svix Signature Implementation, Timestamp Drift Tolerance, Unmapped Events Handling

---

## Svix Signature Implementation

| Option | Description | Selected |
|--------|-------------|----------|
| Native HMAC-SHA256 | Implement standard HMAC-SHA256 natively | ✓ |
| Third-party Dependency | Add the official `svix` Elixir library | |

**User's choice:** Native HMAC-SHA256
**Notes:** User requested deep research and asked for a cohesive, idiomatic recommendation. Recommended native implementation as `:crypto` is fast and standard, avoids dependency bloat, and solves the real issue of reading the raw body from `Plug.Conn`.

---

## Timestamp Drift Tolerance

| Option | Description | Selected |
|--------|-------------|----------|
| Configurable (300s default) | Make it configurable with secure 300s default | ✓ |
| Hardcode 300s | Strictly enforce 300s with no escape hatch | |

**User's choice:** Configurable (300s default)
**Notes:** Recommended to allow `tolerance` overrides for testing ergonomics without sacrificing security by default.

---

## Unmapped Events Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Faithfully Map | Map `email.sent` → `:sent`, `email.delivery_delayed` → `:deferred` | ✓ |
| Map to `:unknown` | Collapse intermediate states | |

**User's choice:** Faithfully Map
**Notes:** Recommended to preserve the high-fidelity audit trail of the append-only event ledger and align with Anymail's taxonomy.

---

## Claude's Discretion

- Configuration key names for tolerance.
- Internal test assertions setup for HMAC signatures (fixture generation).

## Deferred Ideas

None.
