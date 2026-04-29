---
phase: 18
slug: ship-v0-3-0
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for release-surface and publish-ceremony execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Mix tasks + GitHub Actions + Hex / HexDocs visibility checks |
| **Config file** | `.planning/config.json` |
| **Quick run command** | `mix mailglass.publish.check --package mailglass && mix mailglass.publish.check --package mailglass_admin` |
| **Full suite command** | `mix test && mix mailglass.publish.check` |
| **Estimated runtime** | ~2-10 minutes locally; publish/smoke waits longer after release |

---

## Sampling Rate

- **After every docs/release-surface task commit:** run the package-specific `mix mailglass.publish.check` command relevant to the edited surface, then run both before closing Plan `18-01`
- **After every plan wave:** verify release-facing docs and runbook wording still align with route/config reality
- **Before `/gsd-verify-work`:** both package prepublish checks must pass and the release evidence file must contain real publish/smoke proof
- **Max feedback latency:** under 10 minutes for prepublish checks; under the documented publish/smoke wait windows for live-release proof

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | DELIV-04 | T-18-01 | curated changelog matches shipped release story | static | `test "$(rg -c '^## \\[0\\.2\\.0\\]' CHANGELOG.md)" = "1" && test "$(rg -c '^## \\[0\\.2\\.0\\]' mailglass_admin/CHANGELOG.md)" = "1" && rg -n '^## \\[0\\.3\\.0\\]' CHANGELOG.md mailglass_admin/CHANGELOG.md` | ✅ exists | ⬜ pending |
| 18-01-02 | 01 | 1 | DELIV-04 | T-18-01 | Resend docs are explicit opt-in and raw-body safe | static | `rg -n '### Resend setup|providers: \\[:postmark, :sendgrid, :resend\\]|whsec_|svix-id|CachingBodyReader' guides/webhooks.md && ! rg -n 'SES and Resend land later' guides/webhooks.md` | ✅ exists | ⬜ pending |
| 18-01-03 | 01 | 1 | DELIV-04 | T-18-02 | README + runbook + workflow comments align with `0.3.0` contract | static | `! rg -n 'v0\\.5 .*Mailgun|v0\\.5 .*SES|v0\\.5 .*Resend' README.md && rg -n 'mailglass-v0\\.3\\.0|0\\.3\\.0' MAINTAINING.md .github/workflows/publish-hex.yml .github/workflows/post-publish-smoke.yml` | ✅ exists | ⬜ pending |
| 18-01-04 | 01 | 1 | DELIV-04 | T-18-01 | both packages pass prepublish gate against final release story | automated | `mix mailglass.publish.check --package mailglass && mix mailglass.publish.check --package mailglass_admin` | ✅ exists | ⬜ pending |
| 18-02-01 | 02 | 2 | DELIV-04 | T-18-03 | publish evidence records tag, tagged-SHA CI green, pre-publish summary review, approval, and both package outcomes | static | `test -f .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^Tag: mailglass-v0\\.3\\.0$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^Tagged SHA: [0-9a-f]{7,40}$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^Tagged SHA CI: green$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^CI run URL: https://github.com/.+/actions/runs/[0-9]+' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^Publish run URL: https://github.com/.+/actions/runs/[0-9]+' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^Pre-publish summary reviewed: yes$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^Environment approval: .+' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^mailglass publish result: (published|already-published)$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^mailglass_admin publish result: (published|already-published)$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md` | ❌ pending artifact | ⬜ pending |
| 18-02-02 | 02 | 2 | DELIV-04 | T-18-03 | smoke evidence records Hex visibility, HexDocs 200s, and fresh-host result | static | `rg -n '^Smoke run URL: https://github.com/.+/actions/runs/[0-9]+' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^mailglass hex.info: Released:' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^mailglass_admin hex.info: Released:' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^mailglass HexDocs: HTTP 200$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^mailglass_admin HexDocs: HTTP 200$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md && rg -n '^Fresh-host smoke: passed$' .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md` | ❌ pending artifact | ⬜ pending |
| 18-02-03 | 02 | 2 | DELIV-04 | T-18-04 | completion markers update only after evidence exists | static | `rg -n 'Phase 18: Ship v0.3.0.*completed|\\| 18\\. Ship v0\\.3\\.0 \\| 2/2 \\| Complete \\|' .planning/ROADMAP.md && rg -n '0\\.3\\.0 shipped|v0\\.3\\.0 shipped|DELIV-04 marked complete' .planning/PROJECT.md && rg -n '^\\| DELIV-04 \\| Phase 18 \\| Complete \\|$' .planning/REQUIREMENTS.md` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None. All required planning artifacts and proof-source files already exist before execution; the only pending artifact is the real publish-evidence file produced during Plan `18-02`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Environment approval UI step | DELIV-04 | Requires maintainer interaction in GitHub UI | Approve `hex-publish`, then record the approver and outcome in `18-02-PUBLISH-EVIDENCE.md` |
| Fresh-host Phoenix smoke during 60-minute window | DELIV-04 | Requires real release timing and a disposable host app | Follow `MAINTAINING.md`, then record `Fresh-host smoke: passed` or failure details in the evidence file |

---

## Threat Model

| ID | Threat | STRIDE | Mitigation | ASVS |
|----|--------|--------|------------|------|
| T-18-01 | Public docs overstate provider behavior or route defaults | Tampering | Tie docs to router/provider truth sources and prepublish checks | V1 |
| T-18-02 | Maintainer fallback path drifts from actual workflow contract | Repudiation | Keep runbook/workflow examples aligned to reviewed `0.3.0` tag dispatch | V1 |
| T-18-03 | Release appears green internally but is not yet public on Hex / HexDocs | Denial of Service | Require evidence-file checks for Hex visibility and docs HTTP 200s | V14 |
| T-18-04 | Phase completion claimed before DELIV-04 traceability updates | Repudiation | Gate `ROADMAP.md`, `PROJECT.md`, and `REQUIREMENTS.md` completion on public proof | V1 |

---

## Validation Sign-Off

- [x] All tasks have automated verification or an explicit artifact-backed manual step
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing-file dependencies
- [x] No watch-mode flags
- [x] Feedback latency is acceptable for release-proof work
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready
