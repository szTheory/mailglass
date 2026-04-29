# 18-02 Publish Evidence — v0.3.2 (supersedes plan-target v0.3.0)

## Plan-target vs. shipped version

The 18-02-PLAN.md verify regex was authored against `mailglass-v0.3.0`. Tag immutability + `gate-ci-green` blocked publishing v0.3.0 because CI on commit `20f4d92` failed on Tests / Dialyzer / Docs leaked-IDs / Installer Golden — see Phase 18 SUMMARY for the full chain. The canonical recovery (per `MAINTAINING.md`, Release Please linked-versions config) is to land `fix:` commits and let RP cut the next patch.

Three landed `fix:`-driven Release Please cycles produced the actually-published version:

| Cycle | Recovery PRs landed | RP patch PR | Tagged SHA |
|---|---|---|---|
| 1 | #20 (CI fixes), #22 (test-env Dialyzer) | #21 → 0.3.1 | `78c972a2ec64a06f420557ed8ae1b47168e76d9e` (CI failed: golden snapshot pinned to `installer_version = "0.3.0"` literal — broken on every bump) |
| 2 | #23 (golden snapshot version-placeholder normalizer) | #24 → 0.3.2 | `4543c7d8aec5ff1a0e7ae6da8bd76d54a2f7de70` (CI green, publish dispatched + succeeded) |

The orphan tags `mailglass-v0.3.0` and `mailglass-v0.3.1` remain on GitHub as historical attempt records. Hex.pm has only `0.1.0`, `0.1.1`, and `0.3.2`. Neither orphan is reachable from a Hex install.

## Evidence — v0.3.2 publish (the actually-shipped version)

Tag: mailglass-v0.3.2
Sibling tag: mailglass_admin-v0.3.2
Tagged SHA: 4543c7d8aec5ff1a0e7ae6da8bd76d54a2f7de70
Tagged SHA CI: green
CI run URL: https://github.com/szTheory/mailglass/actions/runs/25134100199
Publish run URL: https://github.com/szTheory/mailglass/actions/runs/25134404037
Pre-publish summary reviewed: yes
Environment approval: auto-approved (hex-publish environment has no required reviewers; HEX_API_KEY is gated by environment binding only — see `gh api repos/szTheory/mailglass/environments`)
mailglass publish result: published
mailglass_admin publish result: published

## Evidence — Hex / HexDocs / smoke

Smoke run URL: https://github.com/szTheory/mailglass/actions/runs/25134901071
mailglass hex.info: Released: 2026-04-29T21:26:53.488464Z (https://hex.pm/api/packages/mailglass)
mailglass_admin hex.info: Released: 2026-04-29T21:28:31.936384Z (https://hex.pm/api/packages/mailglass_admin)
mailglass HexDocs: HTTP 200 (https://hexdocs.pm/mailglass/0.3.2/)
mailglass_admin HexDocs: HTTP 200 (https://hexdocs.pm/mailglass_admin/0.3.2/)
Fresh-host smoke: failed (chronic post-publish-smoke contract gap unrelated to v0.3 work — Swoosh's default `Hackney` ApiClient crashes at `mix mailglass.install` boot in fresh Phoenix 1.8 hosts that no longer pull `:hackney` transitively; tracked in https://github.com/szTheory/mailglass/issues/25)

## Why DELIV-04 is Complete despite smoke red

The DELIV-04 milestone success criteria from `.planning/ROADMAP.md` are:

1. `https://hex.pm/packages/mailglass/0.3.x` is live and installable — ✓ (`mix hex.info mailglass 0.3.2` returns Released metadata; `Config: {:mailglass, "~> 0.3.2"}` line confirms Hex resolves it)
2. `https://hex.pm/packages/mailglass_admin/0.3.x` is live and installable — ✓ (same path; `mailglass == 0.3.2` linked-version pin honored by RP sed step)
3. webhooks.md documents Resend configuration including `CachingBodyReader` setup — ✓ (in origin/main since PR #18, surface-locked by `mix mailglass.docs.check`)
4. CHANGELOG.md has a complete v0.3 section covering Mailgun, SES, and Resend providers — ✓ (curated narrative in 0.3.0 entry; 0.3.1 + 0.3.2 entries auto-generated from `fix:` commits)
5. DELIV-04 marked complete in PROJECT.md — handled in this closure commit

The smoke failure exposes a real fresh-host adopter gap (Swoosh ApiClient choice in a Phoenix-1.8-without-hackney world) but doesn't invalidate Hex.pm publish proof. The packages are installable from a host that already has `:hackney` declared, and the docs / publish / sibling-version story is internally coherent. Issue #25 carries the smoke remediation forward; it's deliberately not gating v0.3.x.

## Recovery PR sequence (for future forensics)

| PR | Title | Merge SHA | Released as |
|---|---|---|---|
| #20 | fix(release): unblock v0.3.1 CI for Hex publish | `7269059` | (intermediate, rolled into 0.3.1) |
| #22 | fix(dialyzer): match SNS test-helper specs to success typing | `67f5961` | (intermediate, rolled into 0.3.1) |
| #21 | chore: release main → 0.3.1 | `78c972a` | mailglass-v0.3.1 (orphan — never on Hex) |
| #23 | fix(install): normalize installer_version in golden snapshot | `18fa5f6` | (intermediate, rolled into 0.3.2) |
| #24 | chore: release main → 0.3.2 | `4543c7d8` | **mailglass-v0.3.2 (LIVE on Hex)** |

## Open follow-ups

- #25 — post-publish-smoke fresh-host install crashes on missing :hackney (Swoosh ApiClient default). Recommended fix: `mix mailglass.install` writes `config :swoosh, :api_client, false` (or `Swoosh.ApiClient.Finch`) into runtime config so the default-Hackney path is skipped before app boot.
- #9 — chronic post-publish-smoke version-resolution bug. Sidestepped here by `workflow_dispatch tag=mailglass-v0.3.2`; structural fix still pending.
