---
created: 2026-10-26
source: 2.7.0/2.7.0/2.4.0 release ceremony (owner request: "streamline this mailglass")
status: open
---

# Streamline the release pipeline

The 2.7.0/2.7.0/2.4.0 release took six PRs, six manual dispatches, a force-moved tag set,
and three per-package approvals. Compare `~/projects/lattice_stripe`: merging its release
PR publishes to Hex with `HEX_API_KEY` and no environment gate. Every item below is a
friction point observed in this release, with evidence.

## What broke or needed a human, in order

| # | Friction | Evidence | Recommended fix | Keeps the safety property? |
|---|---|---|---|---|
| 1 | No release PR could open after any close-out | Preflight skipped release-please whenever all manifest tags existed | **Done**: #309 (47db380c) | yes |
| 2 | Captured proposal head was stale six seconds later | Push run 40362661068 captured 748910fe; the pin-sync step then pushed 27cdfa10; recapture dispatch 40365897654 needed | Capture after the sync step's push, reading the PR's final `headRefOid` (or re-read it and fail if it moved) | yes |
| 3 | Ledger authorization is a hand-built PR | #311 copied six values from an artifact by hand | `scripts/release_authorize.sh <run-id>`: download `proposal-candidate.json`, write the ledger, run validate-target / validate-candidate / validate-authorization, open the PR, print the candidate digest | yes; still a reviewed PR |
| 4 | Stale package allowlists found only at publish | Publish run 40372273962: core and admin `*-files.expected` missed v2.9 adds/removes | Run the allowlist diff of `mix mailglass.publish.check` in PR CI for every package (known gotcha, recurred from v2.0 / 1.10.2) | yes, catches it earlier |
| 5 | Recovery forced a tag move | Tags were cut on a commit with the stale allowlist; allowlists are read from the tag tree | Fixed by #4: allowlists can no longer be stale at tag time | n/a |
| 6 | A tag on a `.planning`-only commit has no green required lanes | Publish run 40379381910: `gate-ci-green` blocked, every required lane `skipped` by path filters on f2c91e40; manual `ci.yml` + `advisory-matrix.yml` dispatch on the tag | `ensure-live-ci-runs` treats "required lanes skipped" like "no run" and dispatches the full matrix on the tag (it already self-heals missing runs) | yes |
| 7 | Three approvals for one linked release | `hex-publish` gate pauses `publish-core`, `publish-admin`, `publish-inbound` separately | **Single approval**: one `approve-release` job on `hex-publish` before the fan-out; the three publish jobs drop the environment and `needs:` it | yes, one human gate per release |
| 8 | Approvals required the web UI | Owner asked for programmatic approval | `scripts/release_approve.sh <run-id>`: `POST /actions/runs/{id}/pending_deployments` for `hex-publish`, with `current_user_can_approve` checked first | yes; the approver is still the owner |
| 9 | Close-out is another manual PR | Runbook § Release Close-Out | Fold into one `scripts/release.sh` driver (below) | yes |

## One driver instead of a runbook

`scripts/release.sh` (or `make release`). It stops at each human decision and does the rest:

1. Find the open `chore: release main` PR and wait for its capture to be current (#2).
2. Open the ledger authorization PR (#3); wait for the owner's merge.
3. Run the protected `release-please.yml` dispatch with the candidate digest; verify the
   three tags and GitHub releases point at one SHA.
4. Run `publish-hex.yml`; make sure CI exists on the tag (#6); approve with one command (#7, #8).
5. Verify the Hex API versions and checksums, then open the close-out PR.

## The bigger option: drop the gate

lattice_stripe has no environment gate. Dropping `hex-publish`'s `required_reviewers` would
make the publish hands-free after the release PR merges. CLAUDE.md records that gate as
deliberate policy ("Removing that gate is a deliberate policy change; do not remove it to
make a doc or a script true"). That call is the owner's alone. Recommendation: keep one human
gate (#7 + #8). It costs one command per release, and Hex cannot unpublish after 60 minutes.

## Suggested order

#4 and #6 first: they remove the two failures that forced recovery. Then #7 + #8, then #2,
#3 and the driver.
