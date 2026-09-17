---
created: 2026-09-17T16:50:00.000Z
title: Release close-out advances the ledger but not the rest of the published baseline of record
area: release-engineering
files:
  - scripts/release_policy_close_out.sh
  - test/scripts/reconcile_release_versions_test.exs:619 (baseline_versions/0)
  - test/scripts/reconcile_release_versions_test.exs:660 (evidence_identifiers/0)
  - .planning/publish/mailglass-publish-summary.json
  - .planning/publish/mailglass_admin-publish-summary.json
  - .github/workflows/publish-hex.yml (publish fan-out)
priority: next-release
---

## Problem

`scripts/release_policy_close_out.sh --write` advances
`.planning/release-target.json` and stops. But the repo records the
published baseline in **four** places, and the other three are left
behind:

1. `baseline_versions/0` in `reconcile_release_versions_test.exs` —
   hardcoded literals.
2. `evidence_identifiers/0` in the same file — endpoints, Hex
   checksums, historical tag + SHA.
3. `.planning/publish/mailglass-publish-summary.json` and
   `mailglass_admin-publish-summary.json`.

This is not cosmetic. `ReconcileReleaseVersionsTest` has two modes:
while the ledger is `captured`/`authorized` it takes a
release-candidate branch and only asserts versions *advanced*; the
moment close-out returns the ledger to `inactive` it switches to the
published-baseline branch and compares the tree against those literals
exactly. So **the close-out commit is itself guaranteed to turn Core
Full Suite red on both schemas** until the literals are advanced by
hand. That is what happened on 2.6.0 (commit `29464056`).

The publish summaries have their own defect underneath: the publish
fan-out advances only `mailglass_inbound`'s summary. Core and admin sat
a full release behind after 2.5.0, and again after 2.6.0. The test's own
comment at the time wrote 2.5.0 off as a one-off; two occurrences make
it the shape of the pipeline.

## Fix

Two independent pieces, either one worth doing alone:

- **Close-out completeness.** Have the close-out path advance all four
  records in one commit, or fail loudly listing what still disagrees.
  The checksums must keep coming from the Hex release API — the
  close-out script already reads them, so it already holds everything
  the test literals need.
- **Fan-out symmetry.** Fix `publish-hex.yml` so the fan-out regenerates
  all three publish summaries, not just inbound's. These files are
  publication evidence: they are produced by
  `mix mailglass.publish.check` and never hand-written, so the fix
  belongs in the workflow, not in a commit that edits the JSON.

## Why it matters

A release ceremony that reliably ends with a red required check trains
the maintainer to expect red at close-out, which is exactly the
condition under which a real regression gets waved through. It also
lengthens the ceremony at its most fragile moment — after publish, when
the ledger is still open.

## Evidence

- 2.6.0 close-out: run 35244826764, both Core Full Suite schemas red on
  `assert repository_versions == baseline_versions()`.
- The lagging summaries: `mailglass`/`mailglass_admin` summaries read
  2.5.0 on a tree that had published 2.6.0.

## Partial resolution (2026-09-17)

**Close-out completeness — done, as fail-loudly rather than auto-advance.**
`scripts/check_published_baseline_of_record.sh` verifies all four records
against the release evidence, and `release_policy_close_out.sh --write`
refuses while any disagree, naming each one and printing the released
set, tag, tag SHA and the Hex checksums to copy.

Chosen over having close-out *write* the other three records: two of them
are Elixir source, and generating a control's literals from a script is
the kind of thing that fails quietly and corrupts the baseline of record.
Fail-loudly gets the same result — a close-out commit that is green by
construction — at a fraction of the blast radius.

Bound to `--write` only. `release-please.yml` runs this script without
`--write` as an in-memory self-heal for a stranded ledger, and
`release_policy_contract_test.exs` pins that it never passes `--write`
there; gating that path would fail the release control closed on every
run. Both behaviours are now pinned by tests, and the refusal test was
verified to fail with the gate removed.

**Still open: fan-out symmetry.** `publish-hex.yml` still regenerates
only `mailglass_inbound`'s publish summary. The check above now catches
the lag at close-out instead of letting it reach main, but the operator
still has to run `mix mailglass.publish.check` for core and admin by
hand. The workflow fix is unstarted.

**Worth considering separately:** collapsing the four records to one —
a close-out-written JSON artifact that the test reads instead of holding
literals. It would delete this whole class of drift, and it is grounded
in the Hex API rather than in the tree, so it is not self-certifying.
But it changes the shape of a control and deserves its own decision.

