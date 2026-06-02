# Phase 73 — Inbound Release Record

Release type: PUBLISHED (canonical release: published path) — 2026-06-02
Tag: mailglass_inbound-v1.0.0 (CUT @ 50bc4b825cc2a2c75ba152b6d1b5cf1a50db0d37)
Release-vs-dispatch path: canonical release: published — GitHub release fired publish-hex.yml; publish-core/publish-admin idempotency-skipped (mailglass/mailglass_admin stayed 1.3.0), publish-inbound published 1.0.0. No core/admin release forced.
Publish workflow run URL: https://github.com/szTheory/mailglass/actions/runs/26836825278 (all jobs success: prepublish-summary, gate-ci-green, publish-core[skip], publish-inbound[PUBLISH], publish-admin[skip])
Post-publish smoke run URL: https://github.com/szTheory/mailglass/actions/runs/26836825313 (release-triggered, success)
Proof bundle path: .planning/publish/mailglass_inbound-publish-summary.json (mix mailglass.publish.check --package mailglass_inbound, exit 0, conflict=0)
Install/upgrade rehearsal path: covered by post-publish-smoke (release-triggered, success)
Hex index confirmation: mailglass_inbound 1.0.0 LIVE — inserted 2026-06-02T17:42:31.640432Z, has_docs=true (https://hex.pm/packages/mailglass_inbound/1.0.0)
HexDocs URLs: https://hexdocs.pm/mailglass_inbound/1.0.0/ (live)
Fallback path used: not needed (canonical release path succeeded first attempt)
60-minute outcome: publish window opened 2026-06-02T17:42:31Z; release-triggered smoke green; no revert needed.

> NOTE: cut at main HEAD 50bc4b82 (not the original staged ref 88155d3e). HEAD advanced
> with Phase-73 code-review fixes plus two release-readiness fixes made at publish time:
> (1) chore(release-engineering) 5a28545c — dropped 7 untracked draft files from the inbound
> publish allowlist so the package builds reproducibly from clean source (removed a duplicate
> suppression_flagged migration that would have broken adopters' mix ecto.migrate);
> (2) ci 50bc4b82 — mix format + fixed a stale compatibility-contract test (main had been
> silently red since 2026-05-29 because phases 66–73 landed via paths-ignored commits that
> never ran ci.yml). gate-ci-green required a green ci.yml run on the tagged SHA.

--- Original prepare-and-stage record (pre-publish, retained for history) ---
Release type: prepare-and-stage
Tag: mailglass_inbound-v1.0.0 (staged, not cut)

## Dry-run rehearsal

Rehearsal posture: staged-as-command (prepare-and-stage, D-05/D-07). The exact dispatch command
is recorded below; the run URL is marked `pending` until the maintainer cuts the
`mailglass_inbound-v1.0.0` tag and fires the rehearsal against the live tag.

Reviewed ref under prepare posture: `main @ 88155d3e`
(the SHA the maintainer will tag as `mailglass_inbound-v1.0.0`; no tag cut yet under D-01/D-02)

Exact dispatch command (fire against the reviewed tag, not `main`):

```
gh workflow run publish-hex.yml \
  -f package=mailglass_inbound \
  -f dry_run=true \
  -f tag=mailglass_inbound-v1.0.0
```

After dispatch, capture the run:

```
gh run list --workflow=publish-hex.yml --limit 1
gh run view <run-id> --json url,conclusion
```

Publish workflow run URL: pending

What this dry-run proves (when executed):
- `package=mailglass_inbound` routing is correct — the workflow receives the right package input
- Checkout pins to the reviewed tag (`mailglass_inbound-v1.0.0`), not `main`
- `prepublish-summary` job runs the inbound publish check and emits the summary
- `gate-ci-green` resolves against the tag's SHA (requires a prior green `ci.yml` run)
- `publish-core` job is skipped (inbound-only routing — no `mailglass` release forced)
- `publish-inbound` job is gated-in and would proceed to the publish step
- `publish-admin` job is NOT triggered (no `mailglass_admin` release forced)

What this dry-run does NOT prove (IMPORTANT — do not over-claim):
- `== 1.3.0` core-pin dependency resolution: `dry_run=true` mode SKIPS the
  `MIX_PUBLISH=true mix deps.get` step and the per-sibling `mix hex.publish --dry-run`
  commands (workflow lines 313/338/395/420). Dependency resolution proof is owned by
  `mix mailglass.publish.check --package mailglass_inbound` (isolated-tarball compile),
  not by this rehearsal. The dry-run did NOT validate `== 1.3.0` resolution.

## Proof links

- Inbound release checklist: `73-01-RELEASE-CHECKLIST.md`
- Committed inbound publish summary: `.planning/publish/mailglass_inbound-publish-summary.json`
- Maintainer runbook (inbound-only publish/fallback path): `MAINTAINING.md`

## Notes

This record captures repo-local staging only. The `mix mailglass.publish.check --package mailglass_inbound` preflight lane exited 0 and the root inbound-preflight-consistency test (`mix test test/mailglass/stability_contract_test.exs`) passed — these are the deterministic captured fields. Live publish, Hex index, HexDocs verification, install/smoke proof, and the 60-minute revert window remain explicit `pending` / `not run` until the maintainer's deferred `mailglass_inbound 1.0.0` publish trigger runs (D-01). Branch-protection verification does not apply to this inbound-only slice; the `hex-publish` GitHub Environment has no required reviewers (publish is hands-free, per D-04 and CLAUDE.md "Commit & Branch Conventions").
