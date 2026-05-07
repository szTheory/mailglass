---
phase: 38
slug: release-rehearsal-and-proof-artifacts
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 38 — Validation Strategy

> Per-phase validation contract for release-proof export, install/upgrade rehearsal evidence, and honest manual release-day closeout.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix tasks + GitHub Actions workflow validation + docs generation |
| **Config file** | `config/test.exs`, `mailglass_admin/config/test.exs`, `.github/workflows/*.yml`, `mix.exs`, `mailglass_admin/mix.exs` |
| **Quick run command** | Task-local: `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors`, `mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors`, or `actionlint <touched workflows>`; wave-level: `mix mailglass.publish.check --package mailglass`, `mix mailglass.publish.check --package mailglass_admin`, `mix mailglass.docs.check`, `mix verify.stability_contract`, `mix verify.docs.migration` |
| **Full suite command** | `mix test --warnings-as-errors && mix docs --warnings-as-errors && (cd mailglass_admin && mix test --warnings-as-errors && mix docs --warnings-as-errors)` |
| **Estimated runtime** | ~20-30s task-local / ~240s wave-level / ~420s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest changed-surface command plus `actionlint` for workflow edits; prefer the sub-30-second task-local lane whenever the touched files allow it
- **After every plan wave:** rerun the quick phase commands and the relevant smoke/doc tests for any touched install or upgrade artifacts
- **Before `$gsd-verify-work`:** full suite and docs generation must be green in both packages
- **Max feedback latency:** 30 seconds for task-local checks; 240 seconds for the wave-level bundle because publish-check and docs-proof commands are the narrowest safe slice for this phase

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 38-01-01 | 01 | 1 | RELS-03 | T-38-01 | prepublish proof export reflects package allowlists, metadata, dependency shapes, and linked-version truth without inventing a second checker | mix task / file assertion | `mix mailglass.publish.check --package mailglass && mix mailglass.publish.check --package mailglass_admin && rg -n "mailglass_admin|linked-version|CHANGELOG|hex.audit" .planning/phases/38-release-rehearsal-and-proof-artifacts/` | ✅ | ⬜ pending |
| 38-01-02 | 01 | 1 | RELS-03 | T-38-02 | docs-input proof captures the exact extras/grouping/source-ref inputs that define published docs | docs / grep | `mix mailglass.docs.check && mix docs --warnings-as-errors && (cd mailglass_admin && mix docs --warnings-as-errors) && rg -n "extras|groups_for_extras|source_ref|source_url" mix.exs mailglass_admin/mix.exs .planning/phases/38-release-rehearsal-and-proof-artifacts/` | ✅ | ⬜ pending |
| 38-02-01 | 02 | 2 | RELS-01 | T-38-03 | canonical install rehearsal stays aligned with the fresh Phoenix host smoke contract, preserves the Swoosh sentinel, and includes a secondary executable first-send rehearsal lane | targeted tests / workflow / grep | `actionlint .github/workflows/post-publish-smoke.yml && mix test test/mailglass/install/install_first_preview_smoke_test.exs test/mailglass/install/install_first_send_smoke_test.exs --warnings-as-errors && rg -n "config :swoosh, :api_client, false|GET /dev/mail/|Run mix mailglass.install|First-send workflow proof" test/mailglass/install/install_first_preview_smoke_test.exs test/mailglass/install/install_first_send_smoke_test.exs .github/workflows/post-publish-smoke.yml .planning/phases/38-release-rehearsal-and-proof-artifacts/` | ✅ / Task creates file | ⬜ pending |
| 38-02-02 | 02 | 2 | RELS-02 | T-38-04 | canonical `0.3.x -> 1.0` upgrade rehearsal remains centered on `guides/upgrading-to-v1_0.md` and strict docs/stability checks | targeted test / docs / alias | `mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors && mix verify.docs.migration && mix verify.stability_contract && rg -n "canonical latest-`0.x` to `1.0` upgrade guide|Mailglass.Outbound.send/2|support-until version|proof artifact" guides/upgrading-to-v1_0.md .planning/phases/38-release-rehearsal-and-proof-artifacts/` | ✅ | ⬜ pending |
| 38-03-01 | 03 | 3 | RELS-04 | T-38-05 | release checklist distinguishes repo-proved truth from external/manual proof and requires explicit run URLs, tag names, concrete CI buckets, and timing results | docs / workflow / grep | `actionlint .github/workflows/publish-hex.yml .github/workflows/post-publish-smoke.yml .github/workflows/release-please.yml && rg -n "actions/workflows/ci.yml|38-01-PREPUBLISH-PROOF.md|38-02-REHEARSAL-EVIDENCE.md|verify.stability_contract|verify.docs.migration|workflow_dispatch|release:|hex-publish|60-minute|HexDocs|run URL|fallback" MAINTAINING.md .github/workflows/publish-hex.yml .github/workflows/post-publish-smoke.yml .planning/phases/38-release-rehearsal-and-proof-artifacts/` | ✅ | ⬜ pending |
| 38-03-02 | 03 | 3 | RELS-04 | T-38-07 | release record ties proof bundle, rehearsal evidence, approvals, and live publish data into one auditable schema | docs / grep | `rg -n "Release type|Publish workflow run URL|Post-publish smoke run URL|Proof bundle path|Install/upgrade rehearsal path|Hex index confirmation|HexDocs URLs|Fallback path used|60-minute outcome|Manual approvals and external checks|Branch-protection verification result" .planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md` | ✅ / Task creates file | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Environment approval for `hex-publish` was granted intentionally and by the expected maintainer identity | RELS-04 | GitHub environment approval state and reviewer identity are external to the repo | During rehearsal or real cut, record the workflow run URL, approver identity, and approval timestamp in the committed release record. |
| Branch-protection required checks match the documented release-truth buckets | RELS-04 | Branch protection is configured in GitHub, not stored as authoritative state in the repo | Verify the required checks in GitHub match the maintainer docs; if helper assets remain stale, record this as manual external proof rather than automated truth. |
| Published package versions are visible on Hex.pm and the versioned docs URLs are live | RELS-04 | Live Hex/HexDocs state is temporal and external | Record the exact Hex package pages, version numbers, and HexDocs URLs after the publish/smoke runs complete. |
| 60-minute smoke and revert-window outcome is captured honestly | RELS-04 | The timer window and download count are live operational facts, not repo state | Start a timer at approval, run the smoke during the window, and record whether revert remained available, whether it was needed, and the final outcome. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual-only rationale
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 240s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
