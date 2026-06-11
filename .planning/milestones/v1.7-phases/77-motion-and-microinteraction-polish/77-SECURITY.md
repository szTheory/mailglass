---
phase: 77
slug: motion-and-microinteraction-polish
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-04
---

# Phase 77 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> **Mode:** VERIFY MITIGATIONS (register authored at plan time — all four plans carried parseable `<threat_model>` blocks). **block_on:** high.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| HEEx template render | Record-keyed `id` attributes interpolated from `@selected_delivery.id` / `@detail.record.id` | Internal record UUIDs (already in URL params + DOM); no PII |
| CI shell script execution | `check_motion_conformance.sh` runs as a CI grep gate | Repo-internal files only (`lib/`, `app.css`); no secrets, no network |
| Playwright → OperatorBrowserServer | E2e tests connect to a local seeded test server | Synthetic seed data only; no production/real-user data |
| Asset build pipeline | Vendored `tailwind-macos-arm64` reads `app.css`, writes `priv/static/` | Static CSS bundle; binary vendored + pinned since Phase 76 |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-77-01-01 | Information Disclosure | `id={"delivery-detail-#{@selected_delivery.id}"}` | accept | UUID already in `?delivery_id=` URL param + DOM; no new info, no PII (`operator_live.ex:442`) | closed |
| T-77-01-02 | Information Disclosure | `id={"inbound-detail-#{@detail.record.id}"}` | accept | UUID already in `?inbound_id=` URL param + DOM; no PII (`inbound_live.ex:341`) | closed |
| T-77-01-SC | Tampering (deps) | No package installs | accept | Zero mix.exs/mix.lock/package.json deltas in `08dbd2f1~1..HEAD` | closed |
| T-77-02-01 | Tampering | `check_motion_conformance.sh` CI gate | accept | Reads only repo-internal `lib/` + `app.css`; no network, secrets, or external I/O | closed |
| T-77-02-02 | Denial of Service | grep regex in conformance script | accept | Literal alternations + bounded char-classes; no nested quantifiers / catastrophic backtracking | closed |
| T-77-02-SC | Tampering (deps) | No package installs | accept | No dep manifest changes in phase range | closed |
| T-77-03-01 | Information Disclosure | `deliveryId` read from URL in e2e test | accept | UUID already in URL; test-only against local synthetic seed server (`operator.spec.js:203,217`) | closed |
| T-77-03-02 | Spoofing | `test.skip` on inbound test masking regression | accept | Skip explicit + documented (Phase 78 enablement); HEEx fix ships regardless (`operator.spec.js:242-254`) | closed |
| T-77-03-SC | Tampering (deps) | No package installs | accept | No new npm/mix deps; Playwright pre-installed | closed |
| T-77-04-01 | Tampering | Vendored tailwind binary writes `priv/static/` | accept | Same binary committed Phase 76; no new binary in phase diff; `git diff` gate catches output | closed |
| T-77-04-02 | Spoofing | Stale `priv/static/` in Hex tarball | **mitigate** | `cmd git diff --exit-code priv/static/` in `verify.preview` (`mix.exs:187`); gate load-bearing because `priv/static` is in package `files:` allowlist (`mix.exs:209`) | closed |
| T-77-04-SC | Tampering (deps) | No package installs | accept | No dep manifest changes in phase range | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Mitigate-disposition detail (the only non-accept threat)

T-77-04-02 is the single `mitigate` threat. Its declared mitigation — the `git diff --exit-code priv/static/` gate — is present at `mailglass_admin/mix.exs:187` inside the `verify.preview` alias, and the gate is meaningful because `priv/static` is included in the package `files:` allowlist (`mix.exs:209`). A stale bundle would otherwise ship in the Hex tarball, so the gate genuinely blocks release. Verified present in the correct location, not merely intended.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-77-01 | T-77-01-01 / T-77-01-02 | Record UUIDs added to HTML `id` attributes are already present in URL params and rendered in the DOM; no new information exposed, no PII. | gsd-security-auditor | 2026-06-04 |
| AR-77-02 | T-77-02-01 / T-77-02-02 | Read-only CI grep gate over repo-internal paths; bounded regexes with no backtracking risk; no secrets/network. | gsd-security-auditor | 2026-06-04 |
| AR-77-03 | T-77-03-01 / T-77-03-02 | Test-only Playwright code against a local synthetic seed server; UUID-from-URL is non-sensitive; the inbound `test.skip` is explicit, documented, and re-enabled in Phase 78. | gsd-security-auditor | 2026-06-04 |
| AR-77-04 | T-77-04-01 | Vendored tailwind binary unchanged since Phase 76; `git diff` gate guards any unexpected `priv/static/` output. | gsd-security-auditor | 2026-06-04 |
| AR-77-SC | T-77-01-SC / T-77-02-SC / T-77-03-SC / T-77-04-SC | No npm/mix dependencies added in this phase — verified against the actual `08dbd2f1~1..HEAD` git diff (no manifest deltas). | gsd-security-auditor | 2026-06-04 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-04 | 12 | 12 | 0 | gsd-security-auditor (verify-mitigations mode) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-04
