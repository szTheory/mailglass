---
created: 2026-09-16T17:55:00.000Z
title: Close out the stale 2.5.0 release-target ledger
area: release-engineering
severity: critical
files:
  - .planning/release-target.json
  - .github/workflows/release-please.yml:556-580
  - scripts/release_policy.exs
---

## Problem

`.planning/release-target.json` is frozen mid-ceremony from the 2.5.0 release on
2026-08-20. **Every `release-please` workflow run since then has failed** — 0
successes in the last 100 runs (which reach back only to 2026-09-13; the failure
streak is older). The failing step is:

```
RESULT_STATUS: blocked
RESULT_REASON: proposal_identity_mismatch
```

The ledger currently reads:

```json
"status": "authorized",
"candidate_versions": { "mailglass": "2.5.0", "mailglass_admin": "2.5.0", "mailglass_inbound": "2.2.0" },
"proposal_identity": { "head_sha": "d0369ba76c1f5d033d4d10b804050fa76c784756", ... },
"final_identity": { "tag_sha": null },
"states": { "capture": "captured", "authorization": "authorized", "publication": "not_started" }
```

It claims a release is authorized and **awaiting publication**. In reality
2.5.0 / 2.5.0 / 2.2.0 went live on Hex at 2026-08-20T21:12Z — roughly four weeks
ago. `d0369ba7` is `"Merge branch 'main' into release-please--branches--main"`,
the head of the release PR that produced 2.5.0 and was merged the same day.

`release-please.yml:563-580` takes the `captured|authorized` branch and asserts
the currently-open proposal is byte-for-byte the one it authorized. No present
or future proposal can ever satisfy that, so the control fails closed on every
push to `main` — correctly, by design. The ceremony simply never advanced
`states.publication` past `not_started` or reset `status` to `inactive`.

**This is the real scheduled-control blocker.** It was previously attributed to
open proposal PR #222; closing #222 (2026-09-16) did not clear it, which is what
exposed the actual cause.

## Impact

- A red X on `release-please` for every push to `main`, masking any genuine
  failure in that workflow.
- No new release can be captured or authorized. The next Hex release is blocked
  until this is closed out.
- Not user-facing: publishing is a separate fan-out, and nothing incorrect has
  shipped.

## Solution

Advance the ledger to reflect what actually happened, transitioning it back to
`inactive` so the control takes the `capture-candidate` branch on the next run.
Roughly:

- `status`: `authorized` → `inactive`
- `baselines`: `2.4.1/2.4.1/2.1.2` → `2.5.0/2.5.0/2.2.0`
- `candidate_versions` → `null`
- `proposal_identity` → cleared
- `required_evidence_identifiers`: Hex release endpoints + checksums advanced to
  the 2.5.0/2.5.0/2.2.0 releases; `historical_tag` → `mailglass-v2.5.0`,
  `historical_tag_sha` → `0f0b06861b1cbb2e89f44ea4f40db754effc4017`
- `final_identity.tag_sha` → the 2.5.0 tag SHA
- `states` → reset for a fresh cycle

Precedent for the shape: `git show 61e8c8e8:.planning/release-target.json` is the
same file in its `inactive` state.

## Constraints — why this is not a casual edit

This file is the **release authorization ledger**. It is what tells the pipeline
a publish is sanctioned, and the surrounding controls are deliberately
fail-closed (phases 162–164). Hand-editing it is exactly the operation those
phases were built to make impossible to do carelessly.

- There is **no CLI verb for this transition**. `scripts/release_policy.exs`
  exposes `capture-candidate`, `validate-*`, `verify-published` and
  `verify-complete`, but no reset/close-out. Past transitions were hand-authored
  commits (`375589e2`, `77774f10`, `256af3e1`).
- `verify-published` / `verify-complete` should be run first — they may confirm
  the 2.5.0 publication and be the intended route to advancing
  `states.publication`.
- The Hex checksums in `required_evidence_identifiers` must be read from the Hex
  API, never invented.
- Do this as its own reviewed PR. Do not fold it into an unrelated change.

## Open question

Whether the missing close-out was a one-off (the 2.5.0 ceremony was interrupted —
`77774f10` "retire invalidated exact candidate" suggests it was already messy) or
whether the ledger has no automated close-out path at all, in which case every
future release will strand it the same way and the fix belongs in the workflow,
not just in the data.
