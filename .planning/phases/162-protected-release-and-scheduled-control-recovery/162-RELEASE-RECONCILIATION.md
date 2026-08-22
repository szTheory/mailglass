# Release-State Capture

## Capture 2026-08-22T18:43:11Z

**Captured UTC:** `2026-08-22T18:43:11Z`  
**Canonical HEAD:** `12ddacfc0481304c972e8db516134830e2202418`  
**Method:** fixed-argument, read-only `gh`, `git`, `jq`, and HTTPS GET commands.
No merge, close, auto-merge enablement, ref mutation, tag, publish, push, or retained-evidence
rewrite was performed. Later observations append a new capture; they do not edit this one.

`authorized` plus `publication: not_started` is **blocked reconciliation evidence**, not
merge, tag, or publication authorization. A `protected-merge` outcome is available only
through the existing exact candidate-digest protected dispatch; this capture does not cross
that boundary.

### Source ledger

| Captured UTC | Source command or URL | Immutable identity | Observation | Recovery command |
| --- | --- | --- | --- | --- |
| 2026-08-22T18:43:11Z | `gh pr view 222 --json number,state,headRefName,headRefOid,baseRefName,baseRefOid,mergeStateStatus,autoMergeRequest,url` | PR #222; head SHA `7253bc278fd25066d8e0ffcd82f08944a2f2329b`; base SHA `6c4b2846d4d3af062ae27579394ccfe7e9c27f20` | open; CLEAN; auto-merge: null | `gh pr view 222 --json number,state,headRefName,headRefOid,baseRefName,baseRefOid,mergeStateStatus,autoMergeRequest,url` |
| 2026-08-22T18:43:11Z | `gh pr checks 222 --json name,state,link,bucket` | PR #222 check set at head SHA `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | required observed checks passed; one advisory check skipped | `gh pr checks 222 --json name,state,link,bucket` |
| 2026-08-22T18:43:11Z | `.planning/release-target.json` via `jq` | ledger proposal head SHA `d0369ba76c1f5d033d4d10b804050fa76c784756`; source SHA `77774f1085e6f07ecaa9e595116cd33827b750a2`; candidate digest `1f2202e829cbb26b876fee41c6730f9c5dab7a5dcb04a9aeb9cb5368088e6831` | `status: authorized`; `publication: not_started`; distinct from PR #222 | `jq '{status,proposal_identity,publishable_content,states}' .planning/release-target.json` |

### Evidence matrix

| Category | Immutable identity | Source | Observation | Disposition |
| --- | --- | --- | --- | --- |
| PR | PR #222; head SHA `7253bc278fd25066d8e0ffcd82f08944a2f2329b`; base SHA `6c4b2846d4d3af062ae27579394ccfe7e9c27f20` | GitHub PR API | open/CLEAN, checks observed, auto-merge: null | retain — recovery condition below |
| candidate ledger | proposal head SHA `d0369ba76c1f5d033d4d10b804050fa76c784756`; candidate digest `1f2202e829cbb26b876fee41c6730f9c5dab7a5dcb04a9aeb9cb5368088e6831` | tracked release target | authorized; publication: not_started | retain — no release authority |
| unavailable acquisition sentinel | GitHub PR source unavailable | source ledger command | cannot-check; never absence or authorization | retain — rerun the named source command |

### Disposition matrix

| Scoped identity | Exactly one outcome | Evidence or named recovery condition |
| --- | --- | --- |
| PR #222 | retain | The fresh PR head SHA differs from the ledger proposal head SHA. Retain only for the existing exact candidate-digest protected dispatch after fresh head/base/content-digest/required-check equality is established; do not protected-merge from this capture. |

An unavailable GitHub query is represented as `cannot-check`, not absence, retirement authority,
or protected-merge eligibility. **Recovery command:** rerun the exact read-only `gh` command in
the source ledger and append its result as a later capture.
