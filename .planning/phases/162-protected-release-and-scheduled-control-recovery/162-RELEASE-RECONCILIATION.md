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

## Capture 2026-08-22T18:45:01Z — Expanded scope

**Captured UTC:** `2026-08-22T18:45:01Z`  
**Canonical HEAD:** `fec73dda` (the immutable first capture is retained byte-present above)  
**Method:** fixed-argument, read-only GitHub API/CLI, Git, `jq`, `shasum`, and Hex HTTPS GET
commands. `cannot-check` means acquisition failed or returned unavailable; it is never an empty
category, freshness proof, scheduled proof, publication proof, merge authority, or retirement
authority.

### Expanded source ledger

| Captured UTC | Canonical source | Source command or URL | Coverage and observation | Recovery command |
| --- | --- | --- | --- | --- |
| 2026-08-22T18:45:01Z | GitHub PR API | `gh pr view 222 --json number,state,headRefName,headRefOid,baseRefName,baseRefOid,mergeStateStatus,autoMergeRequest,url` | PR #222 remains open/CLEAN, auto-merge null, head `7253bc278fd25066d8e0ffcd82f08944a2f2329b`, base `6c4b2846d4d3af062ae27579394ccfe7e9c27f20` | rerun the same `gh pr view` command |
| 2026-08-22T18:45:01Z | GitHub Checks API | `gh pr checks 222 --json name,state,link,bucket` | non-advisory observed checks pass; one advisory check is skipped | rerun the same `gh pr checks` command |
| 2026-08-22T18:45:01Z | Git refs | `git show-ref --heads --tags` and `gh api repos/szTheory/mailglass/branches/{name}` | local/preserved release and recovery refs captured; two remote branch lookups returned 404 and are `cannot-check` | rerun the same `git show-ref` and `gh api` reads |
| 2026-08-22T18:45:01Z | Git tags/releases | `git rev-parse <tag>^{}` and `gh release view mailglass-v2.5.0 --json tagName,targetCommitish,url,isDraft,isPrerelease,publishedAt` | each v2.5 tag resolves to `0f0b06861b1cbb2e89f44ea4f40db754effc4017`; core release published 2026-08-20 | rerun exact tag/release reads |
| 2026-08-22T18:45:01Z | Hex package API | `https://hex.pm/api/packages/{package}/releases/{version}` | exact 2.5.0/2.5.0/2.2.0 release checksums captured | repeat the exact HTTPS GET URLs |
| 2026-08-22T18:45:01Z | release-target.json | `jq '{status,package_set,baselines,candidate_versions,proposal_identity,publishable_content,final_identity,states}' .planning/release-target.json` | authorized ledger candidate `d0369ba76c1f5d033d4d10b804050fa76c784756`; publication not_started | rerun the same `jq` query |
| 2026-08-22T18:45:01Z | canonical publish summaries | `jq -c . .planning/publish/*-publish-summary.json` | canonical summaries retain prior 2.4.1/2.4.1/2.1.2 facts and inbound candidate 2.2.0 facts | rerun exact `jq` reads |
| 2026-08-22T18:45:01Z | WT-03 retained diff | `git -C /private/tmp/mailglass-release-candidate.3B6UyC diff -- .planning/publish/* | shasum -a 256` | detached candidate `d0369ba76c1f5d033d4d10b804050fa76c784756`; three path hashes captured without modifying it | rerun exact diff/hash reads |
| 2026-08-22T18:45:01Z | Phase 161 recovery refs | `161-WORKSPACE-INVENTORY.md` plus `161-PRESERVATION-RECONCILIATION.tsv` | preserve refs and their OIDs remain evidence inputs, not cleanup targets | rerun the recorded read-only enumerators |

### Expanded evidence matrix

| Category | Immutable identity | Source | Observation | Disposition |
| --- | --- | --- | --- | --- |
| NONE | NONE-unavailable-remote-response | GitHub branch API | zero successful remote response for two named stale branches; each is separately represented below as cannot-check | retain pending a fresh read |
| branch | `chore/authorize-release-91353` @ `256af3e1030c3cf0070207643809e36d715300eb` | GitHub branch API and Phase 161 REF-0007 | remote exists, unprotected | retain with explicit recovery condition |
| branch | `chore/retire-invalid-release-candidate` @ `40c5c888f29f987dc589e120bd131c67bbfb503c` | GitHub branch API and Phase 161 REF-0008 | remote returned 404: cannot-check, not absence | retain pending fresh authenticated API evidence |
| branch | `fix/protected-release-freshness` @ `63ed7997030012695c900b24f93075038e8d940d` | GitHub branch API and Phase 161 REF-0009 | remote returned 404: cannot-check, not absence | retain pending fresh authenticated API evidence |
| branch | `fix/release-ci-recovery` @ `271f4145bb4d06366023bf7fb6ae53b473691453` | GitHub branch API and Phase 161 REF-0010 | remote exists, unprotected | retain with explicit recovery condition |
| branch | `release-please--branches--main` @ `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | GitHub branch API | remote exists, unprotected; corresponds to PR #222 but remains a distinct identity | retain only for exact protected dispatch evaluation |
| check | `Branch Protection Advisory` at PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | GitHub Checks API | SUCCESS | retain as observed non-authorizing evidence |
| check | `CI Green` at PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | GitHub Checks API | SUCCESS | retain as observed non-authorizing evidence |
| check | `Conventional PR Title` at PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | GitHub Checks API | SUCCESS | retain as observed non-authorizing evidence |
| check | `Guard Release Trigger` at PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | GitHub Checks API | SUCCESS | retain as observed non-authorizing evidence |
| hex | `mailglass_admin` version `2.5.0` checksum `19a4400bb76631605424f6edba30905de50c1d31e8db6667ec31007222ba832c` | Hex package API | exact published package fact | retain publication evidence |
| hex | `mailglass_inbound` version `2.2.0` checksum `b3261d51b58fa8d69ffee7045507f9a0e2c57ea4b09be7f796378f267ad84cc2` | Hex package API | exact published package fact | retain publication evidence |
| hex | `mailglass` version `2.5.0` checksum `8ffab2c0708b5eb3b18693ec6df1b4ad105abc38d7041f1f7b7650cb046f05de` | Hex package API | exact published package fact | retain publication evidence |
| ledger | proposal `d0369ba76c1f5d033d4d10b804050fa76c784756`; source `77774f1085e6f07ecaa9e595116cd33827b750a2`; digest `1f2202e829cbb26b876fee41c6730f9c5dab7a5dcb04a9aeb9cb5368088e6831` | release-target.json | authorized and publication: not_started; distinct from PR and published tag SHA | retain blocked evidence, no authority |
| publish | `.planning/publish/mailglass-publish-summary.json` | canonical publish summaries | canonical `2.4.1`; WT-03 diff hash `2e7e9781508df6ba7a33e1683879112f326548044760563f03fef49858f6ce99` | retain immutable local evidence |
| publish | `.planning/publish/mailglass_admin-publish-summary.json` | canonical publish summaries | canonical `2.4.1`; WT-03 diff hash `82e891100470011d7f50337d401414cc01094008452134de42f19ff40cf79f12` | retain immutable local evidence |
| publish | `.planning/publish/mailglass_inbound-publish-summary.json` | canonical publish summaries | canonical `2.2.0`; WT-03 diff hash `26ce912f4168d5f8c4be1dd17c0d857a0aad74d4617fb4dd3636326bf86b067a` | retain immutable local evidence |
| ref | `preserve/phase-161-archive-range-pre-cleanup-main-20260822` @ `2f86fa2b7ac1d47fa70f458beecf83b61e217632` | Phase 161 recovery refs | same OID as archive ref, separate immutable identity | retain; no cleanup action |
| ref | `preserve/phase-161-archive-ref-pre-cleanup-main-20260822` @ `2f86fa2b7ac1d47fa70f458beecf83b61e217632` | Phase 161 recovery refs | preserved archive ref remains distinct evidence | retain; no cleanup action |
| tag | `mailglass-v2.5.0` @ `0f0b06861b1cbb2e89f44ea4f40db754effc4017` | Git tags/releases | published, exact tag SHA | retain immutable publication evidence |
| tag | `mailglass_admin-v2.5.0` @ `0f0b06861b1cbb2e89f44ea4f40db754effc4017` | Git tags/releases | exact tag SHA; same OID, distinct tag identity | retain immutable publication evidence |
| tag | `mailglass_inbound-v2.2.0` @ `0f0b06861b1cbb2e89f44ea4f40db754effc4017` | Git tags/releases | exact tag SHA; same OID, distinct tag identity | retain immutable publication evidence |
| wt | WT-03 detached SHA `d0369ba76c1f5d033d4d10b804050fa76c784756` | WT-03 retained diff | dirty detached evidence; no ref or file changed | retain immutable local evidence |

### Expanded disposition matrix

| Category | Immutable identity | Outcome | Evidence or named recovery condition |
| --- | --- | --- | --- |
| NONE | NONE-stale-release-branches | retain | zero-count sentinel: no additional scoped stale release branches beyond the named rows; omission is never emptiness |
| NONE | NONE-unavailable-remote-response | retain | zero-count sentinel for an empty successful response set; the two failed named lookups remain cannot-check rows, not empty |
| branch | `chore/authorize-release-91353` @ `256af3e1030c3cf0070207643809e36d715300eb` | retain | keep until a protected exact-candidate recovery condition identifies a safe owner; no branch action occurs here |
| branch | `chore/retire-invalid-release-candidate` @ `40c5c888f29f987dc589e120bd131c67bbfb503c` | retain | remote 404 is cannot-check; rerun authenticated GitHub branch lookup before any retirement decision |
| branch | `fix/protected-release-freshness` @ `63ed7997030012695c900b24f93075038e8d940d` | retain | remote 404 is cannot-check; rerun authenticated GitHub branch lookup before any retirement decision |
| branch | `fix/release-ci-recovery` @ `271f4145bb4d06366023bf7fb6ae53b473691453` | retain | preserve named recovery evidence until later control repair is independently verified |
| branch | `release-please--branches--main` @ `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | retain | only the protected exact candidate-digest dispatch may evaluate it; ordinary triggers gain no merge/tag/release authority |
| check | `Branch Protection Advisory` at PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | retain | successful observed check is evidence only; rerun with the exact PR head before protected dispatch |
| check | `CI Green` at PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | retain | successful observed check is evidence only; rerun with the exact PR head before protected dispatch |
| check | `Conventional PR Title` at PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | retain | successful observed check is evidence only; rerun with the exact PR head before protected dispatch |
| check | `Guard Release Trigger` at PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b` | retain | successful observed check is evidence only; rerun with the exact PR head before protected dispatch |
| pr | PR #222 head `7253bc278fd25066d8e0ffcd82f08944a2f2329b`; base `6c4b2846d4d3af062ae27579394ccfe7e9c27f20` | retain | it mismatches ledger proposal SHA `d0369ba76c1f5d033d4d10b804050fa76c784756`; retain only for a later fresh exact head/base/content digest/required-check comparison |
| ref | `preserve/phase-161-archive-ref-pre-cleanup-main-20260822` @ `2f86fa2b7ac1d47fa70f458beecf83b61e217632` | retain | Phase 161 preservation condition remains binding; do not rewrite or delete evidence |
| ref | `preserve/phase-161-archive-range-pre-cleanup-main-20260822` @ `2f86fa2b7ac1d47fa70f458beecf83b61e217632` | retain | equal OID does not combine this range identity with the archive-ref identity |
| tag | `mailglass-v2.5.0` @ `0f0b06861b1cbb2e89f44ea4f40db754effc4017` | retain | immutable published tag; never substitute it for the PR or ledger candidate |
| tag | `mailglass_admin-v2.5.0` @ `0f0b06861b1cbb2e89f44ea4f40db754effc4017` | retain | immutable published tag; equal SHA remains a separate identity |
| tag | `mailglass_inbound-v2.2.0` @ `0f0b06861b1cbb2e89f44ea4f40db754effc4017` | retain | immutable published tag; equal SHA remains a separate identity |
| wt | WT-03 detached SHA `d0369ba76c1f5d033d4d10b804050fa76c784756` | retain | preserve dirty three-file evidence and rerun exact diff hashes before any later interpretation |
