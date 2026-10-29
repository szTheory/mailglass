---
phase: 178-preview-authoring-and-milestone-review
plan: "03"
subsystem: testing
tags: [bash, docker-compose, git-worktree, github-actions, cost-budget, node-test]

requires:
  - phase: 174-faithful-storybook-and-quiet-quick-views
    provides: "retained hosted receipts (ci-job.json, cost.json, raw run/jobs JSON) the derivation is proven against"
  - phase: 173-consistency-and-delivery-evidence
    provides: "check_phase173_candidate.sh mechanics (detached worktree, port refusal, CSS triple, exact-SHA CI lookup) reused by the launcher"
provides:
  - "scripts/check_phase178_candidate.sh: exact-SHA isolated demo launcher, route probes, CSS identity triple, read-only CI check, explicit teardown"
  - "scripts/test_check_phase178_candidate.sh: offline self-test (11 ok) with docker/gh stubs"
  - "scripts/phase178_cost_disposition.cjs: ci-job / enrich-cost / counts / disposition derivation from raw GitHub JSON"
  - "scripts/phase178_cost_disposition.test.cjs: 11 node:test cases including the Phase 174 reproduction"
affects: [178-05, 178-07, 178-08, 178-09, 178-10]

phase_base_sha: 61e90275
plan_head_before: cc495e0c738db387567991dda38f4056782e8d07
plan_head_after: 7ceddf4f179ae16ec7ded01a401b02026174989a

actuals:
  tokens: 19400
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Library-mode shell (PHASE178_CANDIDATE_LIB_ONLY=1) so pure helpers are unit-tested without side effects"
    - "Allow-list teardown: only mailglass-phase178-review-* projects and /tmp/mailglass-phase178.* parents are ever acted on"
    - "Provenance-tagged derivation: every derived platform field says whether it came from a label table or a saved log"

key-files:
  created:
    - scripts/check_phase178_candidate.sh
    - scripts/test_check_phase178_candidate.sh
    - scripts/phase178_cost_disposition.cjs
    - scripts/phase178_cost_disposition.test.cjs
    - .planning/phases/178-preview-authoring-and-milestone-review/deferred-items.md
  modified: []

key-decisions:
  - "D-14 amendment (2026-10-29, plan-phase), repeated here: D-14 is honored by a slim sibling, scripts/check_phase178_candidate.sh, reusing the mechanics and 173-DELIVERY format of check_phase173_candidate.sh, because that script hard-requires Phase 168-172 summaries, 173 baseline PNGs and an always-unverified owner status. The 173 script is not modified."
  - "A saved job log names the runner OS but not the CPU architecture; the log path takes OS from the log and architecture from the label table only when the label's OS agrees, and says so in provenance"
  - "disposition refuses a run whose head_sha is not the candidate SHA (identity-bound), and a requested job that is missing is an error, never a zero"
  - "enrich-cost's added_cost.reason states only what the tool derives (matching job name and labels); the retained 174 prose also asserted identical lock pins, which raw run JSON cannot show"

requirements-completed: ["UIQ-07", "UIQ-08"]

coverage:
  - id: D1
    description: "Launcher starts an isolated demo from a detached worktree at an exact SHA under a unique Compose project on fresh non-reserved ports, probes routes, proves built==served CSS, and tears down only its own project"
    requirement: "UIQ-08"
    verification:
      - kind: command
        ref: "G178-03-DEMO on dangling proof commit 2431e7b0 (main + two-line demo lock refresh): final_status pass, 3/3 routes 200, built==served CSS, owner demo count 2->2, 0 phase178 containers/worktrees left, wall_s=70"
        status: pass
      - kind: command
        ref: "G178-03-DEMO on committed HEAD 77c0a5ba and 7ceddf4f: fails in 11-13 s on pre-existing demo mix.lock drift (deferred-items.md D-178-03-A); teardown clean, owner demo untouched"
        status: fail
    human_judgment: false
  - id: D2
    description: "Launcher refusals and pure helpers (css href, CSS triple, project-name allow-list, port refusal, CI contexts, SHA refusal before docker, teardown refusals, no GitHub writes, project-scoped compose) are proven offline"
    requirement: "UIQ-08"
    verification:
      - kind: command
        ref: "bash scripts/test_check_phase178_candidate.sh (PASS 11)"
        status: pass
    human_judgment: false
  - id: D3
    description: "ci-job, enrich-cost and disposition reproduce the retained Phase 174 hosted outputs from raw inputs; Demo delta 314000 ms, 5.2333 runner-minutes, 14000 ms over the 5-minute budget"
    requirement: "UIQ-07"
    verification:
      - kind: unit
        ref: "scripts/phase178_cost_disposition.test.cjs#reproduces the retained Phase 174 ci-job, cost enrichment and disposition from raw inputs"
        status: pass
      - kind: command
        ref: "check_phase174_evidence.cjs --pilot --require-ci from a worktree at 18c6cf32 against the regenerated scratch directory: valid:true"
        status: pass
    human_judgment: false
  - id: D4
    description: "counts derives executed counts only from saved files; disposition records SHA-256 for every input and is byte-reproducible; mismatches are reported, never coerced"
    requirement: "UIQ-07"
    verification:
      - kind: unit
        ref: "scripts/phase178_cost_disposition.test.cjs#deriveCounts parses Playwright summary lines behind GitHub timestamps and flags mismatches"
        status: pass
      - kind: unit
        ref: "scripts/phase178_cost_disposition.test.cjs#disposition CLI records a SHA-256 for every input file and is byte-reproducible"
        status: pass
    human_judgment: false

duration: 9 min
completed: 2026-10-29
status: complete
---

# Phase 178 Plan 03: Candidate launcher and hosted cost derivation Summary

**An exact-SHA isolated-demo launcher and a deterministic GitHub-JSON cost derivation exist, are tested offline, and are proven end to end; the launcher cannot start a demo from current `main` until the demo `mix.lock` is refreshed (blocker below).**

## Accomplishments

- `scripts/check_phase178_candidate.sh` creates a detached worktree at exactly `--sha`, allocates two ports (never 4015/5415), starts `docker compose -p mailglass-phase178-review-<sha8>-<utc>-<pid>` with `--build --detach --wait --wait-timeout 600`, restores the worktree demo `mix.lock`, probes routes (HTTP status after redirects, up to 3 tries), fetches `/dev/mail`, extracts the versioned `css-<32 hex>` href and records the source/built/served SHA-256 triple. `--require-ci` reads check runs read-only (`gh api ... --paginate`) and passes only when `CI Green` and `Guard Release Trigger` both concluded success. `--teardown <record>` acts only on a `mailglass-phase178-review-*` project and a `/tmp/mailglass-phase178.*` parent, and writes per-step dispositions back into the record. A provisional record is written before compose starts so teardown works even if the launch dies; on a failed launch the demo container log is saved beside the record.
- `scripts/phase178_cost_disposition.cjs` (Node built-ins only, no `child_process`) implements `ci-job`, `enrich-cost`, `counts`, `disposition` plus the exported pure functions. It reproduces the Phase 174 hosted record from raw inputs.
- Self-test (11 `ok`) and `node --test` file (11 tests) cover the helpers, refusals and the 174 reproduction.

## Task Commits

| Task | Commit | What |
| --- | --- | --- |
| 178-03-01 (tracer) | `77c0a5ba` | Launcher (mode 100755) |
| 178-03-01 (fix found by the gate) | `54f0a9d7` | Save the demo container log when the isolated launch fails |
| 178-03-02 | `4fbfe081` | Offline self-test |
| 178-03-03 | `7ceddf4f` | Cost derivation tool and tests |

## Gate G178-03-DEMO (wall times)

| Run | Candidate | Result | wall_s |
| --- | --- | --- | --- |
| 1 | committed `77c0a5ba` | fail: demo container exit 1 (`mix.lock is out of date`) | 13 |
| 2 | committed `7ceddf4f` (final HEAD) | fail: same cause | 11 |
| 3 | dangling commit `2431e7b0` = `54f0a9d7` + two-line demo lock refresh (never on a branch) | **pass** | **70** |

Run 3 record excerpt (teardown block abbreviated):

```json
{
  "schema_version": "phase178-candidate.v1",
  "source_sha": "2431e7b009d91a705df206d85bcc39d8e62996d6",
  "compose_project": "mailglass-phase178-review-2431e7b0-20261029125723-90070",
  "base_url": "http://127.0.0.1:58086",
  "ports": { "http": 58086, "database": 58087 },
  "routes": [
    { "route": "/dev/mail", "status": 200 },
    { "route": "/dev/storybook/preview_chrome", "status": 200 },
    { "route": "/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin", "status": 200 }
  ],
  "served_css_path": "/dev/mail/css-bb2156de84d3550bfa21a10048441e91",
  "source_css_sha256": "634fc2d5bf32fb30f6063087eb68b5809bbc0ad1002d49bb32477d9dd962e777",
  "built_css_sha256": "173fdd6fe2d7d06c322321796a6aba9a3e6508be4270fdc632dd7d4d364ff6b2",
  "served_css_sha256": "173fdd6fe2d7d06c322321796a6aba9a3e6508be4270fdc632dd7d4d364ff6b2",
  "ci_status": "not_checked",
  "final_status": "pass",
  "teardown": { "dispositions": ["demo_mix_lock restored", "compose_down stopped", "worktree removed", "run_parent removed"] }
}
```

In every run the owner's `mailglass-storybook-review-demo` container count was 2 before and after, no `mailglass-phase178-review-` container or `mailglass-phase178` worktree remained. The `--require-ci` parser was exercised read-only against the real, paginated (919 KB) check-runs for `8328093e`: `{"status":"pass","contexts":{"CI Green":"success","Guard Release Trigger":"success"}}`.

## Self-test output

`bash scripts/test_check_phase178_candidate.sh`: `ok` x11 (extract_css_href, css_triple, assert_safe_project, allocate_ports, ci_contexts_status, invalid-sha-refused-before-docker, teardown-refuses-foreign-projects-and-paths, no-github-write-commands x2, every-docker-compose-call-is-project-scoped, default-routes-and-mode) then `PASS 11`. The stubbed docker/gh log stays empty for the invalid-SHA and unsafe-teardown cases. Re-run after task 3, the GitHub-write grep covers the real cjs file.

## Phase 174 reproduction and the runner_os / runner_arch derivation

- Regenerating `ci-job.json` from only `github-run.raw.json` + `github-jobs.raw.json` equals the retained file after JSON normalization (sorted keys, `provenance` excluded), including `runner_os: Linux` and `runner_arch: X64`.
- **Derivation:** the platform is not in the raw jobs API. The tool maps the job's `labels` (`ubuntu-latest`) through a fixed published-mapping table (`Linux`/`X64`); an unmapped label with no log is an error. With `--log`, the OS comes from the log's `Operating System` header and the architecture from the label table only when its OS agrees (a real runner log has no CPU-architecture line; only Docker `amd64` package lines appear, which describe the container).
- **Log path proven on the real log:** `gh api --allow-escape-sequences repos/szTheory/mailglass/actions/jobs/122170444350/logs` (read-only) downloaded, its header says `Ubuntu 24.04.5 LTS`, `Image: ubuntu-24.04`; the log-derived `ci-job.json` equals both the label-derived one and the retained one outside provenance. Provenance names which source was used.
- `enrich-cost` regenerates `phase174/cost.json` equal to the retained file except `added_cost.reason` prose (see key-decisions). Disposition on the 174 run: Demo job 221 s baseline, 535 s candidate, delta 314 s, 5.2333 runner-minutes, 14000 ms over the 5-minute budget (not within), runner-minutes within 10.
- Full checker proof: `check_phase174_evidence.cjs --pilot --require-ci` returns `valid:true` for the regenerated scratch directory when run from a worktree at the Phase 174 candidate `18c6cf32` (see deviation 2 for why not from `main`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking, found by the gate] Launcher could not show why a launch failed**
- **Found during:** Task 1, gate run 1.
- **Issue:** the compose container exited 1 and teardown then deleted the evidence of why.
- **Fix:** on a failed `compose up` the launcher saves `docker compose logs --tail 120 demo` next to the record, adds the path to `failures`, and tails it to stderr.
- **Files modified:** `scripts/check_phase178_candidate.sh`. **Commit:** `54f0a9d7`.

### Plan-vs-reality deviations

**2. [Rule 3 - pre-existing drift] The plan's `check_phase174_evidence.cjs --pilot --require-ci` verify cannot pass on `main`**
- The checker reads the current scenario manifest, which Phases 175-177 extended; it rejects even the untouched retained directory (8 missing delivery-investigation Axe cases). Not caused by this plan.
- **Substitute proof (stronger on the contract the plan names):** (a) full checker from a detached worktree at `18c6cf32` against the regenerated scratch directory returns `valid:true`; (b) the node test calls the exported `validateCiJob` and `validateHostedCost` on current `main` with the regenerated files. Also, the plan's pipeline `... | head -c` masks the checker exit code; I read the checker's `valid:true` payload instead. The scratch directory is under the session scratchpad and is not removed (a harness safety check blocks `bash -c` scripts that call `rm -rf`).
- Logged as D-178-03-B in `deferred-items.md`.

**3. [Blocker, NOT auto-fixed] G178-03-DEMO cannot pass on committed `main`**
- `reference/demo_app/mix.lock` is behind upstream (`bandit 1.14.0 => 1.14.1`, `swoosh 1.29.0 => 1.29.3`), so the container's `mix deps.get --check-locked` exits 1 before the server starts. This is the known "reference baselines drift on upstream releases" class. The established remedy is a separate `chore(deps):` lock refresh, which is outside this plan's `files_modified` and which the dispatch explicitly forbade committing, so it was not applied.
- **Proof the tooling is correct anyway:** gate run 3 on a throwaway unreferenced commit (`main` + exactly that two-line refresh, created with `git commit-tree`, no branch or ref) passes everything. The dangling object is unreferenced and will be garbage-collected.
- **Consequence for the phase:** plans 178-05 and 178-07 (isolated-demo gates at committed HEAD) and 178-09/10 fail until the demo lock is refreshed. Recorded as D-178-03-A and as a STATE blocker. The acceptance criterion "Gate G178-03-DEMO passes on committed HEAD" is therefore **not met**; the plan is closed on the launcher being proven on the refreshed candidate.

**4. [Process] Commit trailer.** The plan text names `Co-Authored-By: Claude Opus 5.5`; commits carry `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`, the model that authored them (same as 178-01/178-02). `gsd-sdk query commit` was not used; all staging was by explicit path.

**5. [Process] TDD ordering.** The shell helpers were written into the launcher in task 1 (the file is one unit), so the task 2 self-test could not go red by absence; it went green on first run and is anchored by the teardown/refusal checks. The cjs test file was written before the implementation, but I did not capture a separate red run before writing the implementation.

**Total deviations:** 1 auto-fixed (Rule 3), 1 pre-existing-drift workaround (Rule 3), 1 unresolved blocker raised, 2 process notes. **Impact:** tooling complete and proven; the demo lock refresh is required before the launcher-using plans.

## Issues Encountered

- Local `mix deps.get` in a throwaway worktree (used only to build the proof commit) was run with the pinned `ASDF_*` versions; the worktree and `deps` were removed and `reference/demo_app/mix.lock` in the main tree was never touched (`git status` shows only the pre-existing owner edits).
- `gh api` refuses terminal escape sequences in job logs unless `--allow-escape-sequences` is passed.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. T-178-06 (owner demo teardown) is mitigated and tested: unique prefix allow-list, port refusal, container-count invariant held across all three gate runs. T-178-07 (GitHub write) is mitigated: both tools grep-clean for push/PR/dispatch/rerun/merge. T-178-08: built==served enforced for `final_status: pass`. T-178-09: the record is built only from whitelisted `PHASE178_REC_*` variables, no environment dump.

## Self-Check: PASSED

- FOUND: scripts/check_phase178_candidate.sh (mode 100755), scripts/test_check_phase178_candidate.sh, scripts/phase178_cost_disposition.cjs, scripts/phase178_cost_disposition.test.cjs
- FOUND: commits 77c0a5ba, 54f0a9d7, 4fbfe081, 7ceddf4f are ancestors of HEAD
- `node --test scripts/phase178_cost_disposition.test.cjs`: 11 pass, 0 fail, 0 skipped (retained-174 case ran)
- `bash scripts/test_check_phase178_candidate.sh`: PASS 11
- `grep -cE 'execSync|spawnSync|child_process' scripts/phase178_cost_disposition.cjs`: 0
- Acceptance gap (stated above): G178-03-DEMO on committed HEAD fails on pre-existing demo lock drift
