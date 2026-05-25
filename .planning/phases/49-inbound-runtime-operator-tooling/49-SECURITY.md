---
phase: 49
slug: inbound-runtime-operator-tooling
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-25
---

# Phase 49 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Phase 49 ships inbound runtime operator tooling across three plans: (01) post-verify
> ingress rate limiter + runtime config + telemetry, (02) suppression flag-only contract,
> (03) operator mix tasks (`doctor` / `replay` / `prune`).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| provider webhook poster → `Ingress.Plug` | Untrusted HTTP POST; signature verify is the wall, rate limiter sits behind it | Raw provider payload (untrusted) |
| operator app env → `MailglassInbound.Config` | Config validated at boot via NimbleOptions | Retention + rate-limit knobs |
| inbound persist → core `SuppressionStore` | Tenant-scoped lookup; result is diagnostic signal, must never block legitimate mail | Sender address (read), boolean flag (write) |
| persisted column → adopter mailbox via `%InboundMessage{}` | Framework writes `:signals`; adopter reads (read-only contract) | `suppression_flagged` boolean |
| operator CLI args → mix tasks | `--tenant` / `--record-id` / `--since` are untrusted input; parameterized + tenant-scoped | Selectors (untrusted) |
| concurrent prune runs (cron + manual) → DB | Advisory lock serializes; double-delete prevented | Bulk DELETE windows |
| doctor finding text → operator decision | Must be honest about what it does/doesn't verify | Diagnostic findings |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-49-01 | Denial of Service | Ingress rate limiter placement | mitigate | Limiter in `persist_and_respond/5` AFTER verify + `resolve_tenant!`; forged sig → 401 before any budget read (`ingress/plug.ex:179-198`, `130-132`). Test: forged request burns no budget. | closed |
| T-49-02 | Information Disclosure | rate_limit telemetry + 429 body | mitigate | Body + telemetry carry bucket TYPE only; sender keyed on DOMAIN (`plug.ex:217-269`). PII-absence test + `NoPiiInTelemetryMeta` (credo green). | closed |
| T-49-03 | Denial of Service | limiter raising → 500 retry-storm | mitigate | Limiter branch returns `{:rate_limited, resp, meta}`, never raises (`plug.ex:203-241`). | closed |
| T-49-04 | Tampering | per-node ETS rate state | **accept** | Node-local `:ets`; N-node cluster enforces N× limit. Single-node-default posture; cluster-global out of scope (D-49-18). Documented `rate_limiter.ex:35-39`. See Accepted Risks. | closed |
| T-49-05 | Spoofing / Input Validation | `:mailglass_inbound` app env config | mitigate | `Config.validate_at_boot!/0` → `NimbleOptions.validate!` raises on bad shapes (`config.ex:104-107, 165-172`). | closed |
| T-49-06 | Denial of Service | suppression check blocking inbound (degrade-CLOSED) | mitigate | Degrade-OPEN: `{:error,_}` / rescue / catch / empty-from → false AND persist still commits (`persist.ex:341-368`). Flag is diagnostic, never a gate (D-49-19). | closed |
| T-49-07 | Abuse / Reputation | auto-bounce of webhook-accepted mail (backscatter) | mitigate | No auto-bounce / auto-suppression on a true flag; routing unconditional (`persist.ex:330-339, 402-419`). Adopter decides (D-49-23). | closed |
| T-49-08 | Information Disclosure | suppression_flag telemetry leaking sender address | mitigate | Span meta `%{flagged, tenant_id, provider}` only (`persist.ex:331-337`); credo green. | closed |
| T-49-09 | Info Disclosure / Elevation | cross-tenant suppression lookup or admin select | mitigate | `SuppressionStore.check/2` scopes internally via `Mailglass.Tenancy`; IADM-02 select tenant-scoped (`records.ex:45,72`). | closed |
| T-49-10 | Tampering | mislabeling framework facts as adopter `:metadata` | mitigate | Field is `:signals` (framework-owned typed struct), not `:metadata`; `grep -c metadata signals.ex` == 0 (`inbound_message.ex:86,107`). | closed |
| T-49-11 | Tampering (SQLi) | SQL injection via CLI selectors | mitigate | All selectors pinned `^` vars (`replay.ex:125-131`, `prune.ex:167,178,192`); `--since` via `DateTime.from_iso8601`. | closed |
| T-49-12 | Tampering / DoS | concurrent prune double-delete or lock contention | mitigate | `pg_try_advisory_lock` single-run guard; second sweep → `{:ok, :locked_out}`, deletes nothing (`prune.ex:140-154`). | closed |
| T-49-13 | Spoofing | doctor "passed" misleads operator on signature validity | mitigate | Doctor checks key PRESENCE only, never verifies a signature; finding text explicit (`doctor.ex:381-405`). | closed |
| T-49-14 | Denial of Service | unbounded retention delete → replication-lag / long locks | mitigate | Batched `LIMIT 1000` + `FOR UPDATE SKIP LOCKED`, looped per-batch commit (`prune.ex:185-203`). | closed |
| T-49-15 | Information Disclosure | prune telemetry leaking PII | mitigate | `[:mailglass_inbound, :prune, :sweep, :stop]` carries per-table counts + status only (`prune.ex:209-220`); credo green. | closed |
| T-49-16 | Data loss | accidental over-broad prune from config typo | mitigate | NimbleOptions config validation + retention clamp; typed-`yes` + `--dry-run` (`prune.ex:60-98`, `config.ex:130-146`). | closed |
| T-49-17 | Info Disclosure / Elevation | cross-tenant replay/prune | mitigate | **Remediated 2026-05-25.** `Internal.Replay.replay/2` now requires `:tenant_id` and scopes every load (record / evidence / runs) by explicit `tenant_id` where-clause + `Mailglass.Tenancy.scope/2` — foreign-tenant id → `{:error, :not_found}` (`internal/replay.ex:14-150`). The `mix mailglass.inbound.replay` task makes `--tenant` **required** (`mailglass.inbound.replay.ex`); the admin replay gateway threads `record.tenant_id` (`inbound_live.ex:398-409`). Prune windows are global retention by design (not tenant-targeted). Tests: cross-tenant `--record-id` → nothing replayed; `replay/2` raises without `:tenant_id`. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-49-01 | T-49-04 | Per-node ETS rate-limit state (`rate_limiter.ex:44, 82-114`; `table_owner.ex:46-53`). An N-node cluster enforces N× the configured limit because buckets are node-local. Acceptable for the single-node-default library posture; cluster-global enforcement (shared backend) is explicitly out of scope (D-49-18) and documented in the `RateLimiter` moduledoc. | szTheory | 2026-05-25 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-25 | 17 | 16 | 1 | gsd-security-auditor (T-49-17 found OPEN: replay/2 not tenant-scoped) |
| 2026-05-25 | 17 | 17 | 0 | /gsd-secure-phase remediation (T-49-17 fixed + re-verified; tests + credo green) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-25
