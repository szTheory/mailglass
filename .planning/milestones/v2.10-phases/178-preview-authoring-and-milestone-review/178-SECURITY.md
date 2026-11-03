---
phase: "178"
slug: "preview-authoring-and-milestone-review"
status: reviewed_with_nonblocking_open_items
threats_open: 0
open_nonblocking: 4
asvs_level: 1
created: "2026-11-02"
verified: "2026-11-02"
---

# Phase 178 — Security

> ASVS L1 review of the phase threat register and retained execution evidence. The blocking threshold is high. There are no open high or critical threats; four low/medium items remain unaccepted and visible below.

## Trust boundaries

| Boundary | Description | Data crossing |
|---|---|---|
| Preview UI and test browser | Preview authoring, scenario labels, and test-only browser support | Synthetic mailables, scenario names, assign values, browser events |
| Repository and hosted workflows | Same-repository pull request and hosted evidence workflows | Source, test artifacts, workflow environment and CI secrets |
| Candidate runner and local host | Exact-SHA candidate checks and bounded preview lifecycle | Candidate files, local ports, temporary cookie/session data, container resources |
| Operator and review records | Owner-authorized review of hosted and local candidate evidence | Run IDs, hashes, costs, route results, review decisions |

## Threat register

| Threat ID | Category | Component | Severity | Disposition | Planned mitigation | Status | Plan source |
|---|---|---|---|---|---|---|---|
| T-178-01 | Tampering | assigns_changed for read-only keys | medium | mitigate | parse_assigns/3 and parse_scalar/2 untouched (preview_live.ex unchanged, git diff gate); the forged-event test stays green. | closed — verified ASVS L1 | 178-01-PLAN.md:191 |
| T-178-02 | Spoofing | Dangling aria-describedby after removing help ids | low | mitigate | assert_ids_closed!/1 on every form state; rule P2 in plan 178-11 mutation-proves it. | closed — verified ASVS L1 | 178-01-PLAN.md:192 |
| T-178-03 | Information disclosure | Note or errors echoing assign values | low | accept | Errors are fixed strings from parse_error/1; values are already rendered in the inputs by design; no telemetry or logging added. | open — below high threshold (non-blocking) | 178-01-PLAN.md:193 |
| T-178-04 | Repudiation | Ledger rows claiming evidence that does not exist | medium | mitigate | resolve_pointer/2 fail-closed on missing files and headings; teeth tests; clean-state test on the real manifest in the merge-blocking admin lane. | closed — verified ASVS L1 | 178-02-PLAN.md:171 |
| T-178-05 | Tampering | Pointer path traversal reading outside the repository | low | mitigate | resolve_pointer/2 rejects absolute paths and any pointer whose expanded path is not under repo_root/0 (teeth test with "../../etc/hosts"). | closed — verified ASVS L1 | 178-02-PLAN.md:172 |
| T-178-06 | Denial of service | Teardown of the owner's review demo | high | mitigate | Unique project prefix; assert_safe_project refuses any other name; port refusal for 4015/5415; container-count invariant in the tracer verify; self-test cases. | closed — verified ASVS L1 | 178-03-PLAN.md:204 |
| T-178-07 | Elevation of privilege | Accidental GitHub write from a tool | high | mitigate | No push/PR/dispatch/rerun/merge commands in either tool (grep gate in the self-test); writes happen only in plan 178-09 after the owner checkpoint. | closed — verified ASVS L1 | 178-03-PLAN.md:205 |
| T-178-08 | Tampering | Served CSS differing from the committed bundle | medium | mitigate | Source/built/served sha256 triple; final_status pass requires built == served. | closed — verified ASVS L1 | 178-03-PLAN.md:206 |
| T-178-09 | Information disclosure | gh token or env leaked into records | low | mitigate | Records contain only SHAs, URLs, statuses and digests; no env dump; records are git-ignored under reference/demo_app/tmp/. | closed — verified ASVS L1 | 178-03-PLAN.md:207 |
| T-178-10 | Tampering | Markup-looking or RTL scenario/module names in labels | medium | mitigate | HEEx auto-escaping only (no raw/1); scenario_label_test includes an atom containing `<script>` and U+202E and asserts the rendered menu escapes it. | closed — verified ASVS L1 | 178-04-PLAN.md:206 |
| T-178-11 | Denial of service | Atom creation from labels | medium | mitigate | No String.to_atom (source-scan test); inputs are already-loaded atoms from Discovery. | closed — verified ASVS L1 | 178-04-PLAN.md:207 |
| T-178-12 | Spoofing | Look-alike duplicate labels hiding a different scenario | low | mitigate | NFC + downcase collision key; visible technical identity in trigger and options. | closed — verified ASVS L1 | 178-04-PLAN.md:208 |
| T-178-13 | Information disclosure | Story fixtures carrying real data | low | mitigate | Synthetic AtlasDesk/Northstar/Fjordline values only; HappyMailer defaults are test fixtures. | closed — verified ASVS L1 | 178-05-PLAN.md:208 |
| T-178-14 | Repudiation | Accounting table drifting from the manifest | medium | mitigate | Doc-truth test in the merge-blocking admin lane with a mutated-fixture fail-first case. | closed — verified ASVS L1 | 178-05-PLAN.md:209 |
| T-178-15 | Denial of service | Atom creation from JSON in the builder | low | mitigate | Closed compile-time module map and tag decoders; no runtime String.to_atom (grep baseline gate). | closed — verified ASVS L1 | 178-05-PLAN.md:210 |
| T-178-16 | Repudiation | Zoom evidence mislabelled (CSS zoom claimed as real) | medium | mitigate | Relabel here; P7 source-scan rule with mutation proof in plan 178-11; receipts record tabZoom and DPR ratio. | closed — verified ASVS L1 | 178-06-PLAN.md:162 |
| T-178-17 | Tampering | Browser extension loaded into tests | low | accept | The extension is the repository's own two-file test extension (manifest permission "tabs"), loaded only into headless test Chromium; no network or host access. | open — below high threshold (non-blocking) | 178-06-PLAN.md:163 |
| T-178-18 | Tampering | A receipt fixed by editing the shipped bundle | medium | mitigate | Fixes go in the story template or demo Storybook setup, never `priv/static/app.css`. Verification confirms `mailglass_admin/priv/static` is clean. | closed — verified ASVS L1 | 178-07-PLAN.md:195 |
| T-178-19 | Repudiation | A vacuous source scan passing on zero files | low | mitigate | P7's non-vacuity guard (more than 15 spec files), plus teeth fixtures per rule. | closed — verified ASVS L1 | 178-11-PLAN.md:179 |
| T-178-20 | Elevation of privilege | Premature remote write | high | mitigate | No write commands in this plan; remote branch SHA compared before and after; writes only after the plan 178-09 owner checkpoint. | closed — verified ASVS L1 | 178-08-PLAN.md:217 |
| T-178-21 | Tampering | Gate weakened to pass locally | high | mitigate | Gate-integrity diff over baselines, checker case sets, workflows, CI policy, toolchain and release ledger must be empty. | closed — verified ASVS L1 | 178-08-PLAN.md:218 |
| T-178-22 | Elevation of privilege | Remote write without consent | high | mitigate | checkpoint:decision gate="blocking-human" with a user-originated reply; a precondition on task 3 (the only task that runs remote writes); only the commands of the chosen option; no rerun command and no rerun checkpoint in the plan; attempt audit (each measured run's attempt is 1). | closed — verified ASVS L1 | 178-09-PLAN.md:311 |
| T-178-23 | Tampering | Accidental merge, main push or release trigger | high | mitigate | Draft PR with a non-bumping title; post-action audit (isDraft, main ls-remote equals the pre-approval value, release ledger unchanged); no merge command anywhere in the plan. | closed — verified ASVS L1 | 178-09-PLAN.md:312 |
| T-178-24 | Information disclosure | Secrets exposed to PR workflows | medium | accept | Same-repo branch. HEX_API_KEY is referenced only by publish steps, which do not run on pull_request or on this dispatch (CLAUDE.md, RESEARCH V10). | open — below high threshold (non-blocking) | 178-09-PLAN.md:313 |
| T-178-25 | Repudiation | Cost evidence not bound to the candidate, or counts from unsaved output | medium | mitigate | --require-ci on the dispatch artifact (or identity_bound false, stated, for PR-only). Counts are derived only from saved logs and receipts whose hashes are recorded. The disposition is reproduced byte for byte by cmp. | closed — verified ASVS L1 | 178-09-PLAN.md:314 |
| T-178-26 | Information disclosure | Preview reachable beyond the machine | low | mitigate | Compose ports bound to 127.0.0.1 (compose.demo.yml), synthetic data only. | closed — verified ASVS L1 | 178-10-PLAN.md:184 |
| T-178-27 | Repudiation | Runbook URLs that do not render | medium | mitigate | Every URL fetched (200 + page marker) or resolved via gh before the checkpoint. | closed — verified ASVS L1 | 178-10-PLAN.md:185 |
| T-178-28 | Denial of service | Owner's review demo stopped by cleanup | medium | mitigate | --teardown refuses non-candidate project names; container-count comparison; no make demo-down. | closed — verified ASVS L1 | 178-10-PLAN.md:186 |
| T-178-29 | Elevation of privilege | Ship read as merge/release authorization | high | mitigate | Checkpoint text and runbook state that ship authorizes no merge, release, publication or deployment; no such command in this plan. | closed — verified ASVS L1 | 178-10-PLAN.md:187 |
| T-178-30 | Tampering | A required-lane contract weakened to get green | high | mitigate | The prohibitions keep targeting STATE.md (grep gate on `14 open PR` and the refute count). The positive facts move rather than being deleted, with six teeth cases and one real-file mutation. | closed — verified ASVS L1 | 178-12-PLAN.md:162 |
| T-178-31 | Repudiation | A vacuous pass when the DOCS-01 entry moves or is renamed | medium | mitigate | `docs01_section/1` raises on a missing marker, and the missing-entry test proves it. | closed — verified ASVS L1 | 178-12-PLAN.md:163 |
| T-178-32 | Tampering | Hand edit of tool-written STATE.md | medium | mitigate | `git diff --quiet HEAD -- .planning/STATE.md` in the task verify, with an explicit-path commit. | closed — verified ASVS L1 | 178-12-PLAN.md:164 |
| T-178-33 | Denial of service | Gate run against the owner's review demo on :4015 | medium | mitigate | The gate uses only `scripts/check_phase178_candidate.sh` (unique project, refuses ports 4015/5415). The container-count check is in the gate. | closed — verified ASVS L1 | 178-07-PLAN.md:196 |
| T-178-34 | Tampering | A mutation left in committed source | medium | mitigate | Path-specific revert against HEAD after each mutation, and a `git diff --quiet HEAD` gate on lib, persona_spec and both e2e trees in the task verify. | closed — verified ASVS L1 | 178-11-PLAN.md:178 |
| T-178-35 | Repudiation | Owner approves without seeing the real scope | medium | mitigate | Scope is computed live at checkpoint time after a fresh fetch, and repeated in the PR body. | closed — verified ASVS L1 | 178-09-PLAN.md:315 |
| T-178-36 | Tampering | Guard that passes vacuously (parses nothing, or a no-match pattern skips loading) | high | mitigate | Anti-vacuity: at least 3 steps parsed and named steps asserted; a `loaded` record is required for every listed file; three hermetic cases prove fail, allow and lazy paths through the same helper. | closed — verified ASVS L1 | 178-13-PLAN.md:288 |
| T-178-37 | Tampering | Gate weakened to get green (test removed from ci.yml, install added, assertions edited) | high | mitigate | Prohibitions verified by diff: ci.yml and storybook-axe.test.cjs unchanged; supplement diff at most 4 added and 2 removed lines; ci.yml still lists the test. | closed — verified ASVS L1 | 178-13-PLAN.md:289 |
| T-178-38 | Repudiation | Fix claimed without evidence that the hosted defect was reproduced | medium | mitigate | RED log saved before the fix, with the package and file names; GREEN run recorded in the SUMMARY. | closed — verified ASVS L1 | 178-13-PLAN.md:290 |
| T-178-39 | Repudiation | A real regression hidden by a "flake" label | high | mitigate | Classification requires at least 50/50 local repeats, saved hashed traces, and an evidence-cited section. It writes one `recorded_advisory_title:` line that 178-17 matches only within that line. | closed — verified ASVS L1 | 178-14-PLAN.md:176 |
| T-178-40 | Tampering | Scroll-access assertion weakened to go green | high | mitigate | The verify pins the End predicate text and both key presses, compares skip and fixme counts with the base, keeps playwright.config.cjs unchanged, and adds preconditions rather than removing checks. | closed — verified ASVS L1 | 178-14-PLAN.md:177 |
| T-178-41 | Tampering | Committed admin CSS bundle rebuilt by browser runs | medium | mitigate | Every browser command restores app.css, and the verify asserts no app.css diff since the base. | closed — verified ASVS L1 | 178-14-PLAN.md:178 |
| T-178-42 | Elevation of privilege | Premature remote write | high | mitigate | No write commands in this plan. Task 3 asserts the branch SHA is unchanged and that no new run exists. | closed — verified ASVS L1 | 178-15-PLAN.md:233 |
| T-178-43 | Tampering | Transitive lock drift committed as a "refresh" | medium | mitigate | Task 1 verify maps every changed lock package to the `rerun_lock_refresh:` names and requires the chore(deps): type. | closed — verified ASVS L1 | 178-15-PLAN.md:234 |
| T-178-44 | Tampering | Gate weakened to freeze faster | high | mitigate | Failures are fixed in separate commits with re-runs; no baseline, checker case set, workflow or policy edit is allowed; the pilot revision is bound to the gate head. | closed — verified ASVS L1 | 178-15-PLAN.md:235 |
| T-178-45 | Elevation of privilege | Remote write without consent, or carried over from the stopped run's approval | high | mitigate | A new checkpoint:decision gate="blocking-human" for the new SHA; a precondition on task 3; only the chosen option's commands; no rerun or force push; branch re-verified before the push; attempt-1 audit. | closed — verified ASVS L1 | 178-16-PLAN.md:225 |
| T-178-46 | Tampering | Accidental merge, main push or release trigger | high | mitigate | Draft PR with a non-bumping title; verify asserts isDraft, main unchanged and release ledger unchanged; no merge command anywhere in the plan. | closed — verified ASVS L1 | 178-16-PLAN.md:226 |
| T-178-47 | Information disclosure | Secrets exposed to PR workflows | medium | accept | Same-repo branch. HEX_API_KEY is referenced only by publish steps, which do not run on pull_request or on this dispatch (CLAUDE.md, 178-RESEARCH V10). | open — below high threshold (non-blocking) | 178-16-PLAN.md:227 |
| T-178-48 | Repudiation | Owner approves stale scope or stale URLs | medium | mitigate | Scope recomputed live just before presenting; every runbook URL resolved through gh in task 1 and recorded. | closed — verified ASVS L1 | 178-16-PLAN.md:228 |
| T-178-49 | Repudiation | Cost or receipts not bound to the candidate, or counts from unsaved output | medium | mitigate | --require-ci and an execution.json source_revision check under approve-all (identity_bound false stated otherwise); counts only from saved, hashed logs; disposition reproduced by cmp. | closed — verified ASVS L1 | 178-17-PLAN.md:227 |
| T-178-50 | Tampering | A Demo or required-lane red classified as advisory to keep going | high | mitigate | The verify rejects advisory lines for any job other than Operator Browser Gate or Preview Capture Advisory; 178-AUTOMATION.md matches only inside recorded_advisory_title lines; every red job needs a line; attempt-1 audit. | closed — verified ASVS L1 | 178-17-PLAN.md:228 |
| T-178-51 | Repudiation | Hosted figures fabricated after a stop | high | mitigate | Under a stop or decline, the verify asserts the disposition file is absent and the not-measured statement is present. | closed — verified ASVS L1 | 178-17-PLAN.md:229 |
| T-178-52 | Information disclosure | Preview reachable beyond the machine | low | mitigate | Compose ports bound to 127.0.0.1 (compose.demo.yml), synthetic data only. | closed — verified ASVS L1 | 178-18-PLAN.md:163 |
| T-178-53 | Repudiation | Runbook URLs that do not render, or a stale candidate | medium | mitigate | Every URL fetched (200 plus page marker) or resolved through gh before hand-off; the launcher record binds source_sha to rerun_candidate_sha. | closed — verified ASVS L1 | 178-18-PLAN.md:164 |
| T-178-54 | Denial of service | Owner's review demo disturbed by the launch | medium | mitigate | Unique candidate project prefix; the launcher refuses the owner's project name; delivery_review_demo_count_before is recorded for 178-19's comparison. | closed — verified ASVS L1 | 178-18-PLAN.md:165 |
| T-178-55 | Denial of service | Owner's review demo stopped by cleanup | medium | mitigate | --teardown refuses non-candidate project names; container-count comparison with delivery_review_demo_count_before; the runbook names only the candidate's own teardown command. | closed — verified ASVS L1 | 178-19-PLAN.md:173 |
| T-178-56 | Elevation of privilege | Ship read as merge or release authorization | high | mitigate | The checkpoint and runbook state that ship authorizes no merge, release, publication or deployment; no such command exists in this plan; the verify asserts the PR is still an open draft. | closed — verified ASVS L1 | 178-19-PLAN.md:174 |
| T-178-57 | Tampering | Hosted operator counts inflated by annotation continuation lines, producing false count mismatches that hide or excuse real ones | medium | mitigate | Task 3 counts only timestamped summary lines in a timestamped log; the saved hosted log for run 40904235961 must parse to exactly 309/1/1/0. | closed — verified ASVS L1 | 178-13-PLAN.md:291 |
| T-178-58 | Tampering | Cost disposition relaxed to accept any red job so a broken candidate still gets a cost figure | high | mitigate | Task 4 accepts a non-success conclusion only for Operator Browser Gate, only `failure`, and only when a recorded `rerun_advisory_red:` line names that run and job; Demo, Support and CI Green still require success; mismatched or unmeasured lines are rejected; tests prove each refusal and the CLI exit 1; the test file may only gain lines. | closed — verified ASVS L1 | 178-13-PLAN.md:292 |
| T-178-59 | Elevation of privilege | Hosted write and preview authority | high | mitigate | Blocking user checkpoint binds SHA, three operations and conditional preview; no prior authority is reused. | closed — verified ASVS L1 | 178-21-PLAN.md:91 |
| T-178-60 | Tampering | Remote ref/body race | high | mitigate | Recheck refs, SHA and body hash immediately before writes; no force push or automatic retry on ambiguity. | closed — verified ASVS L1 | 178-21-PLAN.md:92 |
| T-178-61 | Denial of service | Hosted compute spend | medium | mitigate | One PR-triggered CI and one dispatch only, attempts fixed at 1, no rerun; capture consumed/unspent operations on stop. | closed — verified ASVS L1 | 178-21-PLAN.md:93 |
| T-178-62 | Repudiation | Hosted receipt provenance | high | mitigate | Raw run/jobs/log metadata, hashes, attempt 1, exact dispatch SHA and --require-ci before acceptance closure. | closed — verified ASVS L1 | 178-22-PLAN.md:90 |
| T-178-63 | Elevation of privilege | Red-run continuation | high | mitigate | Required/Demo or unknown failures stop without rerun/preview; only previously evidenced advisory titles may be classified under the existing protocol. | closed — verified ASVS L1 | 178-22-PLAN.md:91 |
| T-178-64 | Tampering | Counts and cost disposition | medium | mitigate | Immutable expected hash, named mismatches, baseline/current input hashes and byte-identical regeneration; no coverage/gate changes. | closed — verified ASVS L1 | 178-22-PLAN.md:92 |
| T-178-65 | Elevation of privilege | Preview launch | high | mitigate | Assert new SHA-bound conditional authorization and completed hosted/cost state; failed preconditions stop without launching. | closed — verified ASVS L1 | 178-23-PLAN.md:104 |
| T-178-66 | Tampering | Runbook source and asset identity | medium | mitigate | Existing exact-SHA launcher, required contexts, CSS triple, authenticated 200/marker checks for every URL before hand-off. | closed — verified ASVS L1 | 178-23-PLAN.md:105 |
| T-178-67 | Denial of service | Existing owner demo | medium | mitigate | Unique candidate project/ports and retained-demo count; never reuse or stop the owner project. | closed — verified ASVS L1 | 178-23-PLAN.md:106 |
| T-178-68 | Elevation of privilege | Ship decision | high | mitigate | Separate blocking owner checkpoint with verified full URLs; record user message and explicitly exclude merge/release/publication/deployment. | closed — verified ASVS L1 | 178-24-PLAN.md:150 |
| T-178-69 | Denial of service | Candidate teardown | medium | mitigate | Source/project/worktree identity check and candidate-scoped teardown only; retained owner demo count verified; keep-running skips removal. | closed — verified ASVS L1 | 178-24-PLAN.md:151 |
| T-178-70 | Tampering | Candidate source and local evidence | high | mitigate | File-byte hashes, reviewed Git blobs and saved gate provenance must agree before freeze; unresolved high findings block. | closed — verified ASVS L1 | 178-20-PLAN.md:104 |
| T-178-71 | Elevation of privilege | Historical hosted approval | high | mitigate | New authority fields begin null; old rerun_* stop remains unchanged; no remote write is in this plan. | closed — verified ASVS L1 | 178-20-PLAN.md:105 |
| T-178-72 | Tampering | CI job setup | medium | mitigate | Contract test asserts the install command stays inside the named advisory job and before server startup; actionlint checks workflow syntax. | closed — verified ASVS L1 | 178-25-PLAN.md:104 |
| T-178-73 | Elevation of privilege | Recovery authority | high | mitigate | Use a separate cycle record with null authority and re-hash the prior record; no remote command is included. | closed — verified ASVS L1 | 178-25-PLAN.md:105 |
| T-178-74 | Elevation of privilege | Candidate push and PR edit | high | mitigate | A direct user checkpoint binds the exact candidate, target ref, body hash and three one-time operations; prior authority is not reused. | closed — verified ASVS L1 | 178-26-PLAN.md:120 |
| T-178-75 | Tampering | Remote snapshot and PR body | high | mitigate | Compare source, both refs, PR state/body and ledger immediately before writes; drift stops the plan without force push. | closed — verified ASVS L1 | 178-26-PLAN.md:121 |
| T-178-76 | Denial of service | Hosted runner spend | medium | mitigate | Limit to one PR-triggered run and one explicit dispatch, attempt 1 only, no retry or rerun; stop before dispatch when the PR gate fails. | closed — verified ASVS L1 | 178-26-PLAN.md:122 |
| T-178-77 | Tampering | Hosted run identity and result | high | mitigate | Match new run events, candidate head SHA, attempt, required contexts and repaired advisory job; preserve receipts on any stop. | closed — verified ASVS L1 | 178-26-PLAN.md:123 |
| T-178-82 | Elevation of privilege | GitHub writes | high | mitigate | Exact-SHA and named-operation approval, one use each, with pre-write ref/body/ledger checks. | closed — verified ASVS L1 | 178-28-PLAN.md:109 |
| T-178-83 | Denial of service | Runner budget | medium | mitigate | At most eight attempt-1 runs; stop on first failure; no retry, rerun, or cancellation. | closed — verified ASVS L1 | 178-28-PLAN.md:110 |
| T-178-84 | Tampering | Hosted evidence and cost | high | mitigate | Hash raw inputs, bind identities, and require deterministic cost regeneration. | closed — verified ASVS L1 | 178-28-PLAN.md:111 |
| T-178-85 | Denial of service | Local demo resources | medium | mitigate | Existing candidate-specific loopback launcher, resource inventory, and scoped cleanup. | closed — verified ASVS L1 | 178-28-PLAN.md:112 |
| T-178-86 | Information disclosure | Temporary demo cookie | medium | mitigate | Use a mode-0600 jar inside the private mktemp probe directory; never log or persist it. | closed — verified ASVS L1 | 178-29-PLAN.md:91 |
| T-178-87 | Tampering | Redirect and route acceptance | medium | mitigate | Preserve redirect-following and exact final-200 checks; assert the return URL and jar use in an offline stub. | closed — verified ASVS L1 | 178-29-PLAN.md:92 |
| T-178-88 | Elevation of privilege | Repeat preview invocation | high | mitigate | Plan 29 performs no preview; a fresh Cycle 05 exact-SHA approval must precede any new launcher run. | closed — verified ASVS L1 | 178-29-PLAN.md:93 |
| T-178-89 | Denial of service | Preview harness | low | mitigate | Preserve Git failure diagnostics so infrastructure or permission stops can be distinguished without blind retries. | closed — verified ASVS L1 | 178-30-PLAN.md:81 |
| T-178-90 | Elevation of privilege | Preview retry authority | high | mitigate | Keep Cycle 05 stopped and require a new one-attempt approval before any future preview. | closed — verified ASVS L1 | 178-30-PLAN.md:82 |
| T-178-91 | Tampering | Demo dependency lock | medium | mitigate | Update only nimble_options, review full one-entry diff and normal Hex checksums, then require locked install and compilation. | closed — verified ASVS L1 | 178-31-PLAN.md:148 |
| T-178-92 | Repudiation | Candidate evidence | high | mitigate | Preserve old SHA receipts and explicitly require new identity/evidence for changed source; keep UIQ-08 open. | closed — verified ASVS L1 | 178-31-PLAN.md:149 |
| T-178-93 | Elevation of privilege | Consumed preview authority | high | mitigate | Record the single failed attempt and prohibit any launcher, Docker or hosted operation in this plan. | closed — verified ASVS L1 | 178-31-PLAN.md:150 |
| T-178-94 | Tampering | Shared worktree | medium | mitigate | Snapshot user work, keep state.json byte-identical, use supported state tooling and explicit staging paths. | closed — verified ASVS L1 | 178-31-PLAN.md:151 |
| T-178-95 | Elevation of privilege | Push, PR edit, workflow dispatch | high | mitigate | Blocking fresh-owner checkpoint binds each one-time action to the exact candidate SHA; any drift stops before writes. | closed — verified ASVS L1 | 178-32-PLAN.md:130 |
| T-178-96 | Tampering | Candidate and hosted receipts | high | mitigate | Recheck candidate, remote refs, event, attempt, head SHA, and artifact source revision; preserve raw input hashes and reproduce cost output byte-for-byte. | closed — verified ASVS L1 | 178-32-PLAN.md:131 |
| T-178-97 | Denial of service | Hosted workflow spend | medium | mitigate | Limit to one push, one body update, one dispatch and eight total attempt-1 workflow runs; stop on any failed gate, ambiguity, or unexpected trigger without retry. | closed — verified ASVS L1 | 178-32-PLAN.md:132 |
| T-178-98 | Elevation of privilege | Push, PR edit, workflow dispatch | high | mitigate | Require a fresh blocking checkpoint with separate hosted/preview decisions and recheck candidate, remote refs, PR and ledger before each write. | closed — verified ASVS L1 | 178-34-PLAN.md:138 |
| T-178-99 | Tampering | Candidate and hosted/cost receipts | high | mitigate | Require cycle 8, full-SHA equality across every attempt-1 run, dispatch artifact and cost source; preserve raw evidence and reproduce the cost artifact byte-for-byte. | closed — verified ASVS L1 | 178-34-PLAN.md:139 |
| T-178-100 | Denial of service | Hosted workflow spend | medium | mitigate | Cap at one fast-forward push, one body-only edit, one gated dispatch and eight attempt-1 runs; stop on required/Demo failure, drift, ambiguity or unclassified errors without retry. | closed — verified ASVS L1 | 178-34-PLAN.md:140 |
| T-178-101 | Elevation of privilege | Recovery preview approval | high | mitigate | Require a new blocking owner decision bound to the exact SHA and attempt 2; prior Plan 23 authority cannot authorize a second launch. | closed — verified ASVS L1 | 178-37-PLAN.md:216 |
| T-178-102 | Tampering | Candidate and hosted/cost evidence | medium | mitigate | Keep original receipts immutable, verify their hashes and SHA identities, and assert the temporary clone remains at the candidate with no source diff. | closed — verified ASVS L1 | 178-37-PLAN.md:217 |
| T-178-103 | Denial of service | Owner demo and unrelated Docker projects | medium | mitigate | Use the launcher's unique loopback project, compare owner-demo counts before/after, and allow teardown only through the exact attempt-2 record. | closed — verified ASVS L1 | 178-37-PLAN.md:218 |
| T-178-104 | Information disclosure | Copied logs and browser evidence | low | mitigate | Use synthetic demo data, retain ignored local evidence, and never copy credentials or tokens into the clone or evidence files. | closed — verified ASVS L1 | 178-37-PLAN.md:219 |
| T-178-105 | Elevation of privilege | Recovery preview approval | high | mitigate | Require new direct approval for attempt 3; do not reuse attempt-2 authorization. | closed — verified ASVS L1 | 178-38-PLAN.md:129 |
| T-178-106 | Tampering | Candidate and prior receipts | medium | mitigate | Pin the same candidate SHA, verify stored hashes, append attempt 3, and preserve attempts 1 and 2. | closed — verified ASVS L1 | 178-38-PLAN.md:130 |
| T-178-107 | Denial of service | Docker builder and retained preview services | medium | mitigate | Require the same selected running Docker driver builder, use only the unique config and candidate project, and compare owner-demo snapshots. | closed — verified ASVS L1 | 178-38-PLAN.md:131 |
| T-178-108 | Information disclosure | Temporary Git/Buildx state and logs | low | mitigate | Keep credentials out of clone/config/evidence; remove only the dedicated Buildx config and retain only non-secret preview evidence. | closed — verified ASVS L1 | 178-38-PLAN.md:132 |
| T-178-SC | Tampering | Existing locked container build | high | mitigate | Add or upgrade no packages; use candidate lockfiles only and stop if the build changes a candidate source/lock file. | closed — verified ASVS L1 | 178-38-PLAN.md:133 (+29 repeated) |

Status counts use the audit's deduplicated register: 105 unique threats, 101 closed, 4 open below the high threshold. Repeated declarations are consolidated by threat ID. The threats_open field counts only open threats at or above the configured high threshold.

## Open non-blocking risks

These retain their plan-declared accept disposition, but are not owner-accepted: the audit found no specific owner risk-acceptance record. The phase can pass the configured high-severity gate while these remain visible.

| Threat | Severity | Risk | Missing evidence |
|---|---|---|---|
| T-178-03 | low | Assign values or errors disclose values | Explicit owner risk acceptance or mitigation; see 178-01-PLAN.md:193 |
| T-178-17 | low | Test browser extension is loaded in headless Chromium | Explicit owner risk acceptance or mitigation; see 178-06-PLAN.md:163 |
| T-178-24 | medium | Secrets may be exposed to same-repository PR workflows | Explicit owner risk acceptance or mitigation; see 178-09-PLAN.md:313 |
| T-178-47 | medium | Secrets may be exposed to the successor hosted cycle | Explicit owner risk acceptance or mitigation; see 178-16-PLAN.md:227 |

## Audit trail

| Date | Total | Closed | Open | Run by |
|---|---:|---:|---:|---|
| 2026-11-02 | 105 | 101 | 4 (0 blocking) | GSD security auditor, ASVS L1 |

The audit checked the Phase 178 plans and summaries plus implementation, test, hosted receipt, cost, and cleanup evidence. It independently verified raw hosted run identities/log hashes, reproduced the retained cost outputs, and confirmed the attempt-3 pre-teardown digest from the embedded launch snapshot. The current recovery record adds authorized teardown data; this is not a candidate-integrity discrepancy. The plan-source locations above identify the threat declarations; implementation and test evidence was checked by the auditor for every closed item.

## Sign-off

- [x] Every threat has a disposition and audit status.
- [ ] No accepted risks remain — four declared accepts lack owner acceptance.
- [x] threats_open: 0 at the configured high threshold.
- [x] ASVS L1 verification completed on 2026-11-02.

**Approval:** phase gate passed with four visible, non-blocking open risks; no risk acceptance inferred.
