# Phase 164 Repository Truth Closeout

This is the durable usage contract for a volatile closeout report. It is not a
captured final-state snapshot: each report's timestamp, SHAs, run IDs, control
observations, and verdict are time-bound evidence and must remain untracked.

## Run after a protected merge

From the canonical checkout at `/Users/jon/projects/mailglass`, obtain the exact
normally triggered protected CI run ID for the current `main` SHA. Do not use a
manual dispatch, a different branch, or a merely latest run.

```bash
scripts/closeout_repository_truth.sh \
  --repo /Users/jon/projects/mailglass \
  --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv \
  --ci-run-id <exact-current-main-ci-run-id> \
  --output /Users/jon/projects/mailglass/tmp/phase-164-closeout/report.json
```

These are enforced identities, not examples: the command resolves `--repo` to
exactly `/Users/jon/projects/mailglass`, accepts only the Phase 164 ledger at
the path above, and accepts output only beneath that repository's `tmp/`
directory. Arbitrary checkouts, copied or equivalent ledgers, and destinations
not covered by the root `/tmp/` ignore rule are rejected before evidence
collection or output creation.

`tmp/phase-164-closeout/report.json` and its sibling `components/` source files
are volatile, untracked runtime evidence under that existing root `/tmp/` ignore
rule. Inspect or attach them to an appropriate later evidence capture; never
commit them as the repository's final state.

## Report contract

The JSON report contains `schema`, `captured_at`, `repo`, `branch`, `head_sha`,
`origin_main_sha`, `ci_run_id`, `components`, `status`, and `reason`. Component
source paths preserve the raw output used for each normalized verdict.

The command exits zero only for `status: "pass"`; it writes the report atomically
for every other verdict as well. Stable porcelain is sampled before collection
and again after every component and final-report write, so an observed
post-write dirty workspace prevents a pass. It is read-only apart from the
ignored volatile report: it does not dispatch, rerun, merge, publish, authorize,
or mutate Git/GitHub/Hex state.

## Quiet pass conditions

- **D-10:** the supplied repository is `/Users/jon/projects/mailglass` on `main`,
  its local `HEAD` equals `origin/main`, and stable porcelain has no tracked or
  untracked entries.
- **D-11:** the exact supplied CI run completed successfully for that same SHA;
  every scheduled/recovery control has current, complete, event/run/workflow/head
  identity and retained-artifact provenance. A policy-blocked control is eligible
  only when that complete evidence is valid.
- **D-12:** the authoritative durable ledger passes the shared full-ledger
  validator: every audited subject is complete, each currentness value is exactly
  `current`, `historical`, or `stale`, and a `stale` entry has an update, archive,
  or removal outcome rather than `retain` or `ignore`.

`pending`, `cannot-check`, stale, malformed, mismatched, missing, or unexplained
evidence is non-pass. `cannot-check` takes precedence over `pending`, which takes
precedence over `blocked`; none can be represented as quiet.

## Durable authorities

- The complete disposition ledger is
  [164-TRUTH-DISPOSITION.tsv](164-TRUTH-DISPOSITION.tsv).
- Phase 161's [workspace inventory](../161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md)
  and [preservation reconciliation](../161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv)
  remain the preservation proof.
- Phase 162's [release reconciliation](../162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md)
  and [scheduled-control UAT](../162-protected-release-and-scheduled-control-recovery/162-UAT.md)
  remain recovery provenance.
- [MAINTAINING.md](../../../MAINTAINING.md) is the current maintainer entry point
  for protected release and recovery authority.
