---
phase: 18-ship-v0-3-0
plan: "02"
subsystem: release
tags: [hex, release-please, conventional-commits, publish-hex, post-publish-smoke, dialyzer, install-golden]

requires:
  - phase: 17-unblock-verify-resend
    provides: shipped Resend webhook plug + verify path that v0.3 release narrative claims
provides:
  - mailglass 0.3.2 live on Hex.pm
  - mailglass_admin 0.3.2 live on Hex.pm (linked-versions paired with core)
  - HexDocs 0.3.2 builds for both packages
  - durable evidence file recording the publish chain (3 recovery PRs + 2 RP cycles)
  - canonical recovery pattern (Conventional Commits → Release Please patch) proven end to end
affects: [release-engineering, future v0.x patch ceremonies, smoke-contract remediation]

tech-stack:
  added: []
  patterns:
    - "Tag-immutable patch recovery: when a release tag's CI fails gate-ci-green, land fix: commits and let Release Please cut the next patch — never re-point the tag"
    - "Install golden snapshots normalize installer_version literal, so version bumps don't break the gate"

key-files:
  created:
    - .planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md
  modified:
    - lib/mailglass/webhook/ingest.ex (PR #20 — :resend in ingest_multi/3 guard + derive_webhook_provider_event_id/3)
    - lib/mailglass/webhook/providers/{mailgun_replay_cache,mailgun_replay_cache/table_owner,ses/cert_cache,ses/cert_cache/table_owner}.ex (PR #20 — concrete-singleton table specs)
    - lib/mailglass/config.ex (PR #20 — Config.new!/1 spec narrowed to keyword())
    - lib/mix/tasks/mailglass.docs.check.ex (PR #20 — Tier 1 surface tokens advanced to v0.3)
    - guides/webhooks.md, guides/migration-from-swoosh.md (PR #20 — D-18 leak removal + v0.3 surface)
    - test/mailglass/docs_contract_test.exs (PR #20 — v0.3 contract assertion)
    - test/mailglass/webhook/providers/resend_webhook_plug_test.exs + test/support/fixtures/webhooks/resend/delivered.json (PR #20 — Plug-level Resend integration coverage)
    - test/example/README.md (PR #20 then PR #23 — install golden snapshot)
    - test/support/installer_fixture_helpers.ex (PR #23 — installer_version placeholder normalizer)
    - test/support/webhook_fixtures.ex (PR #22 — SNS test-helper spec tightening)
    - .release-please-manifest.json, CHANGELOG.md, mailglass_admin/CHANGELOG.md, mix.exs, mailglass_admin/mix.exs (PR #21 + #24 — Release Please version bumps)

key-decisions:
  - "Cut v0.3.1 then v0.3.2 instead of moving the v0.3.0 tag — preserves tag immutability and gate-ci-green contract"
  - "Land each CI fix as its own atomic Conventional-Commits fix: commit so Release Please's changelog generator picks them up cleanly"
  - "Treat the post-publish-smoke fresh-host failure as ship-then-investigate (Issue #25) — Hex publish is irreversible and the chronic Swoosh/Hackney gap predates v0.3 work"

patterns-established:
  - "Pattern: When CI fails on a Release Please tagged commit, do not retag — push fix: commits and merge them; RP opens the next patch PR automatically"
  - "Pattern: Install golden snapshots use placeholder normalizers (`<INSTALLER_VERSION>`, `<MIGRATION_TS>`, `<LAST_RUN_AT>`, `<SECRET>`) so structural pinning survives version bumps"
  - "Pattern: Multi-pass dialyzer hygiene — local MIX_ENV=dev misses test/support; CI runs MIX_ENV=test; both must be green"

requirements-completed:
  - DELIV-04

duration: ~80min (5 fix commits + 3 RP cycles + publish + smoke + evidence)
completed: 2026-04-29
---

# Phase 18 Plan 02 Summary

**v0.3.2 published to Hex.pm via three Conventional-Commits Release Please cycles after the original v0.3.0 release commit's CI gate failed on four jobs.**

## Performance

- **Duration:** ~80 min (research + edits + 3 RP cycles + dispatch + smoke)
- **Started:** 2026-04-29 (continuation of earlier `/gsd-execute-phase 18` run)
- **Completed:** 2026-04-29T21:26:53Z (mailglass) / 2026-04-29T21:28:31Z (mailglass_admin)
- **PRs landed:** 5 (#20, #21, #22, #23, #24)
- **Workflow runs:** 4 CI runs on main (3 green, 1 red), 1 publish-hex (green), 1 post-publish-smoke (red — known chronic, see #25)

## Accomplishments

- `mix hex.info mailglass 0.3.2` and `mix hex.info mailglass_admin 0.3.2` both return live release metadata.
- HexDocs HTTP 200 for both packages at `0.3.2`.
- Surfaced two carryover Phase 14/17 gaps (`ingest_multi/3` guard + `derive_webhook_provider_event_id/3` clause) and added Plug-level integration coverage so they can't regress.
- Stabilized the install golden gate: future patch / minor / major version bumps no longer re-baseline the snapshot's content-addressed sha256s.
- Tightened 5 dialyzer specs from supertypes to concrete success typings (4 ETS singletons + `Config.new!/1` + 2 SNS test helpers).
- Removed a `(D-18)` planning-decision leak from `guides/webhooks.md` that the Tier 1 docs check had been red-flagging.
- Advanced the locked Tier 1 surface (`mix mailglass.docs.check` + `Mailglass.DocsContractTest`) from `~> 0.2` to `~> 0.3`.

## Why we shipped v0.3.2 instead of v0.3.0

`publish-hex.yml`'s `gate-ci-green` job blocks unless `ci.yml` succeeds on the *tagged SHA*. CI on the v0.3.0 release commit (`20f4d92`) failed on Tests, Dialyzer, Docs leaked-IDs, and Installer Golden. Repo policy (`MAINTAINING.md` lines 87–107 + `publish-hex.yml` lines 105–143) forbids re-pointing tags. The canonical recovery is to land `fix:` commits and let Release Please's linked-versions plugin cut the next patch.

The first recovery cycle (PRs #20, #22 → RP PR #21 → tag v0.3.1) was blocked by a *structural* problem: the install golden snapshot pinned the literal `installer_version = "0.3.0"` string, which the v0.3.0 → v0.3.1 bump invalidated. The second cycle (PR #23 → RP PR #24 → tag v0.3.2) added a placeholder normalizer so future bumps are stable, and v0.3.2 cleared the gate.

The orphan tags `mailglass-v0.3.0` and `mailglass-v0.3.1` remain on GitHub as historical artifacts of the recovery chain. Neither is on Hex.pm.

## Task Commits / PRs

1. **PR #20** — `fix(release): unblock v0.3.1 CI for Hex publish` (`7269059`)
   - 7 atomic fix:/test:/chore: commits covering ingest guard, dialyzer specs, docs leak, surface tokens, golden, Plug integration test
2. **PR #22** — `fix(dialyzer): match SNS test-helper specs to success typing (CI test-env)` (`67f5961`)
   - Surfaced because local `MIX_ENV=dev` doesn't compile `test/support`; CI's `MIX_ENV=test` does
3. **PR #21** — `chore: release main → 0.3.1` (`78c972a`) — RP linked-versions PR; orphaned by the next CI failure
4. **PR #23** — `fix(install): normalize installer_version in golden snapshot` (`18fa5f6`)
   - Structural fix: snapshot now pins `installer_version = "<INSTALLER_VERSION>"`
5. **PR #24** — `chore: release main → 0.3.2` (`4543c7d8`) — RP PR; merged, CI green, publish dispatched
6. **publish-hex.yml** workflow_dispatch on `mailglass-v0.3.2` — succeeded
7. **post-publish-smoke.yml** workflow_dispatch — failed on Consumer install (Swoosh/Hackney chronic gap, see #25)
8. **closure commit** — this SUMMARY + EVIDENCE + ROADMAP/PROJECT/REQUIREMENTS/STATE updates

## Open follow-ups

- **#25** — post-publish-smoke Swoosh/Hackney chronic gap. Recommended fix: `mix mailglass.install` writes `config :swoosh, :api_client, false` (or `Swoosh.ApiClient.Finch`) into runtime config. v0.4 candidate.
- **#9** — chronic post-publish-smoke version-resolution bug. Sidestepped here by passing `tag=mailglass-v0.3.2` explicitly to `workflow_dispatch`. Structural fix still open.
- **Plan-frozen verify regex** — 18-02-PLAN.md bakes in literal `mailglass-v0.3.0` matchers. Per the recovery plan, those gates were intentionally not edited; the EVIDENCE narrative carries the actual shipped tag forward.
