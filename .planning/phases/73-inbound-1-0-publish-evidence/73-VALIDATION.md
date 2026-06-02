---
phase: 73
slug: inbound-1-0-publish-evidence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 73 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> All validation is deterministic and repo-native — explicitly NOT through live
> Hex/HexDocs assertions (prepare-and-stage posture, CONTEXT D-01/D-08).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18 / OTP 27) |
| **Config file** | sibling configs; root `mix.exs` aliases drive lanes |
| **Quick run command** | `cd mailglass_inbound && mix verify.docs.contract.inbound` |
| **Full suite command** | `mix verify.stability_contract` (root) |
| **Estimated runtime** | ~30–60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_inbound && mix verify.docs.contract.inbound` (fast docs guard)
- **After every plan wave:** Run `mix verify.stability_contract` (root) + `mix mailglass.publish.check --package mailglass_inbound`
- **Before `/gsd:verify-work`:** Full `mix verify.stability_contract` green + dry-run rehearsal evidence recorded (run URL or staged command) + record field-presence test green (if D-08 extension added)
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 73-xx | record | — | REL-03 | — | Pending fields read as `pending`/`not run` (no fabricated evidence) | field-presence | new/extended test: record `=~` each REL-03 header + `pending` markers | ❌ W0 (if D-08 chosen) | ⬜ pending |
| 73-xx | record | — | REL-03 | — | Inbound publish preflight summary internally consistent | unit | `mix test test/mailglass/stability_contract_test.exs` | ✅ | ⬜ pending |
| 73-xx | record | — | REL-03 | — | Pre-publish tarball/metadata proof | task exit status | `mix mailglass.publish.check --package mailglass_inbound` (exit 0) | ✅ | ⬜ pending |
| 73-xx | rehearse | — | REL-02 | — | Inbound-only dispatch tag-pinned, no forced core/admin | structural + manual dry-run | `mix test test/mailglass/stability_contract_test.exs` + `gh workflow run ... dry_run=true` exit status | ✅ | ⬜ pending |
| 73-xx | runbook | — | REL-02 | — | Runbook documents inbound-only publish/fallback path | docs-contract | `cd mailglass_inbound && mix verify.docs.contract.inbound` | ✅ | ⬜ pending |
| 73-xx | runbook | — | REL-02 | — | Stale Phase 38 path fixed (D-10) | manual verify + optional assertion | `grep -n "phases/38" MAINTAINING.md` returns nothing | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] *(If D-08 extension chosen)* Add a field-presence test for the inbound RELEASE-RECORD to `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` OR `test/mailglass/stability_contract_test.exs` — string-presence of REL-03 headers + `pending`/`not run` markers, **NO live HTTP**. Lightest honest option per D-08.
- [ ] *(If D-10 hardening desired)* Add an assertion that `MAINTAINING.md` does NOT contain `.planning/phases/38-` (catches regression of the stale path). Optional.

*Existing infrastructure (`stability_contract_test`, `docs_contract_test`, `publish.check`, `verify.stability_contract`) already covers REL-02 wiring and REL-03 source-truth consistency. The only new test is the optional record field-presence guard.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inbound-only `dry_run=true` workflow_dispatch rehearsal | REL-02 | Requires GitHub Actions runner; cannot run in local ExUnit. Honest under D-05 to either fire in-phase against the reviewed ref or stage as a documented `gh workflow run` command with run URL marked `pending`. | `gh workflow run publish-hex.yml -f package=mailglass_inbound -f dry_run=true [-f tag=<reviewed-ref>]`; capture run URL; rehearsal proves wiring/gating/fan-out, NOT dependency resolution (dry-run skips `mix hex.publish --dry-run` + `MIX_PUBLISH=true mix deps.get`). |
| Live Hex index URL / HexDocs URL / install+smoke / 60-minute revert-retire decision | REL-03 | Post-publish-only; `1.0.0` is not on Hex under prepare posture. **Must read as explicit `pending`/`not run`** — never fabricated (Honest Surface Area, D-05). | Recorded as pending markers in the RELEASE-RECORD; captured only by the deferred maintainer publish trigger. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies (record field-presence + publish.check + stability_contract + docs.contract.inbound)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (optional D-08 record test)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] No validation asserts live external Hex/HexDocs state (prepare posture)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
