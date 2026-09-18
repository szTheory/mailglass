# Deferred Items — Phase 166

Out-of-scope discoveries logged per the executor's scope-boundary rule (do not fix, do not
re-run builds hoping they resolve themselves).

## 166-04

- **`test/scripts/phase_164_closeout_test.exs` is slow/flaky on this machine.** During Task 2's
  full `test/scripts/ test/mix/tasks/` verification run, the test
  `"phase 164 immutable loader loader and shell authenticate exact terminal pairs 01 through 44"`
  hit ExUnit's 60s per-test timeout (and did not complete even under a 200s isolated `timeout`
  wrapper). This file shells out via `System.cmd` across 44 terminal-pair sub-cases and is
  unrelated to `.github/workflows/release-please.yml` (its two `"release-please"` mentions are
  just control-ID strings passed to `scripts/closeout_repository_truth.sh`, not anything this
  plan's diff touches). Not fixed here — pre-existing, unrelated file, out of scope for CTRL-02/
  CTRL-03. Confirmed 166-04's full test suite is green when this one file is excluded (492 tests,
  0 failures, 20 excluded).

- **Task 3 (checkpoint:human-verify, `gate="blocking-human"`) -- post-merge evidence for
  CTRL-02/CTRL-03 acceptance criteria is explicitly PENDING, not observed.** Cannot be satisfied
  pre-merge and must never be manufactured by dispatch or re-run (plan prohibition, confirmed by
  maintainer). Checklist for whoever picks this up next (166-05/166-06 or Phase 167 merges are
  expected to supply the observations naturally per D-37):
  1. Open the `release-please` workflow runs for the three most recent merges to `main`; confirm
     each concluded `success`.
  2. For each of those SHAs, open both the `push` run and the `schedule` run and confirm they
     agree.
  3. When the next `chore: release main` PR merges, open its `release-please` push run and confirm
     the tagged-SHA skip fired (CTRL-02's own acceptance) rather than the action re-running.
  4. Confirm no run reported a `cannot-check` outcome as `pass`.

  Until all four are observed, `.planning/REQUIREMENTS.md`'s CTRL-02/CTRL-03 rows stay
  `Implemented, evidence pending` -- not `Complete`. See `166-04-SUMMARY.md` for full detail.

## 166-05

- **Task 1 (GREEN-04) deviated from the plan's literal isolation mechanism — documented, not a
  silent substitution.** The plan's acceptance text named a `MIX_DEPS_PATH`/`MIX_BUILD_PATH`
  environment-variable override as the isolation mechanism. That override was reproduced locally
  (5 runs, isolated variable, prior executor attempt) to break cowlib's `erlang.mk` build. Per
  orchestrator resolution, the isolated Hex build instead uses a scratch copy of
  `reference/demo_app` + `reference/persona_spec` (via `rsync`) built with default `deps`/`_build`
  paths inside `/tmp/mailglass_demo_hex_proof`. Verified locally: `HEX_BUILD_ISOLATED` (path-dep
  `deps/` directory listing byte-identical before/after), `--check-locked` succeeds, compile
  succeeds. A dedicated new CI job (the orchestrator's first-preference option) was rejected
  because any new `ci.yml` job — required or advisory — must be registered in
  `Mailglass.CILanes.all_classified_lanes/0` (enforced by a job-count-parity test in
  `lane_classification_drift_test.exs`), which is strictly more blast radius for the same signal
  than a step inside the existing required `support_contract_core` job.

- **`reference/demo_app/mix.lock`'s three mailglass sibling entries were refreshed to
  2.6.0/2.6.0/2.3.0** (the current published line) as a precondition for GREEN-04 — the frozen
  2.0.0 lock cannot satisfy `mailglass_admin`'s `:navigation` router dependency (introduced at
  2.1.0), so `MAILGLASS_DEMO_DEPS=hex mix compile` failed against the committed lock before this
  refresh. Verified: `git diff --stat` shows exactly 3 lines changed (one per sibling package);
  `mix.exs` and every other lock entry are untouched. This lifts the plan's "do not edit
  `reference/demo_app/mix.lock`" prohibition for this narrow refresh only, per orchestrator
  resolution (the prohibition and D-12 were both written on the now-disproven assumption that
  `mix compile` succeeds unmodified at 2.0.0).

- **Task 3 (checkpoint:human-verify, `gate="blocking-human"`) — post-merge/post-push evidence for
  GREEN-05's Part 2 (CI-observed cache-restore behavior) and GREEN-04's post-merge confirmation is
  explicitly PENDING, not observed.** `docs/ci-cache-isolation.md` Parts 1 and 3 are fully written
  and demonstrated locally; Part 2 has a placeholder describing what is expected (a first-run cache
  miss on both disambiguated trust-lane keys) but no real CI run has occurred yet from this
  sequential-executor context (no branch was pushed; this executor has no push/PR-creation
  mandate). Checklist for whoever picks this up next:
  1. Push this branch (or merge to `main`) so CI actually runs with the disambiguated
     `mix-trust-repo-head-…` / `mix-trust-clean-baseline-…` cache keys for the first time.
  2. From that run, open both `trust_lane_repo_head` and `trust_lane_clean_baseline`; copy each
     job's cache-restore log line (hit or miss, resolved key) and the new
     "List reference/host_app/deps before install" step's output.
  3. Paste both, plus the run URL, into `docs/ci-cache-isolation.md` Part 2, annotating the
     expected first-run cache miss as a cold start (D-16), not a regression.
  4. On the same or a subsequent `main` run, confirm the `support_contract_core` job's
     "Prove demo app Hex pins" step resolved all three sibling packages from Hex and compiled
     (GREEN-04's own post-merge confirmation row), and record that run URL too.
  5. Present the completed note to the maintainer for a yes/no per Task 3's resume-signal.

  Until this is observed, `.planning/REQUIREMENTS.md`'s GREEN-04/GREEN-05 rows stay
  `Implemented, evidence pending` — not `Complete`. See `166-05-SUMMARY.md` for full detail.

## 166-06

- **Task 3 (checkpoint:human-verify, `gate="blocking-human"`) — post-merge evidence for
  CTRL-01/CTRL-05 acceptance criteria is explicitly PENDING, not observed.** Nothing from this
  plan has merged to `main` yet, and CTRL-05's evidence needs two NATURALLY-TRIGGERED
  `repo-hygiene` cron firings — never a `workflow_dispatch` or re-run manufactured to produce
  them (the plan's own prohibition, confirmed by maintainer). Checklist for whoever picks this
  up next:

  **CTRL-01 (milestone exit criterion 3 — do not drop if the timebox tightens):**
  1. After this PR merges to `main`, dispatch `post-publish-smoke.yml` via
     `gh workflow run post-publish-smoke.yml --ref main -f mode=baseline -f core_version=<any
     non-empty value> -f admin_version=<any non-empty value> -f inbound_version=<any non-empty
     value> -f target_ref=<any 40-hex value, e.g. the ledger's
     required_evidence_identifiers.historical_tag_sha>`. The four non-mode inputs stay
     `required: true` per D-17 but are NOT consulted in baseline mode — any well-formed
     placeholder satisfies GitHub's non-empty requirement.
  2. Confirm the `resolve-completed-target` job's "Resolve protected target versions" step
     exits 0 and the "Upload post-publish resolution" step uploads
     `post-publish-resolution-<run_id>` containing `post-publish-resolution.json`.
  3. Download the artifact; confirm `status: "pass"`, `reason: "exact_target_verified"`, and
     that `core`/`admin`/`inbound`/`target_ref` match `.planning/release-target.json`'s
     `baselines` and `required_evidence_identifiers.historical_tag_sha` (currently
     2.6.0/2.6.0/2.3.0 and `6a0447a900e26b2b07332ac50682767801ddcda7`).
  4. Record the run URL and the artifact's resolved values.
  5. Confirm the live-dispatch path is unaffected: the guards this plan did not touch
     (40-hex ref regex, exact-SemVer assertions, all 4 pre-existing required inputs, the
     64-hex digest requirement) still apply unconditionally when `mode` is left empty.

  **CTRL-05:**
  1. Wait for two consecutive naturally-triggered scheduled `repo-hygiene` runs (daily cron
     `30 12 * * *`). Do not dispatch or re-run to manufacture these.
  2. Confirm both runs conclude `success` with an overall `status: pass` in the uploaded
     `repo-hygiene` artifact.
  3. Keep at least one healthy PR (age ≤14 days, no failing required check) open across both
     firings; record its number, so "a freshly opened healthy PR does not turn it red" is
     exercised rather than vacuously true on an empty PR list.
  4. Confirm no `repo-hygiene` run exited 0 on a non-pass verdict (the workflow's `pipefail`
     step should fail whenever `mix mailglass.repo.hygiene --check --format json` exits
     `{:shutdown, 1}` blocked or `{:shutdown, 2}` cannot-check).

  Until all of the above are observed, `.planning/REQUIREMENTS.md`'s CTRL-01/CTRL-05 rows stay
  `Implemented, evidence pending` — not `Complete`. See `166-06-SUMMARY.md` for full detail.

## Code review (166-REVIEW.md) — findings NOT fixed in this phase

WR-01 was fixed in-phase (`test/scripts/check_post_publish_target_test.exs`, commit `905cb3f9`):
the `--baseline-mode` digest bypass now has tests that execute the script rather than grep the
YAML that calls it, verified by mutation. The remaining findings are recorded here rather than
fixed, each with the reason.

- **WR-03 — `status/1` ranks `:cannot_check` above `:blocked` (NOT a defect to flip unilaterally).**
  In `dev/mix/tasks/mailglass.repo.hygiene.ex:482-488` the aggregate resolves to `:cannot_check`
  whenever any check is unobservable, even if another check is a confirmed `:blocked`. The review
  reads this as a confirmed alarm being masked. Investigated and deliberately left alone:
  1. It is pre-existing Phase 162 behavior, not introduced by 166-06.
  2. It is explicitly test-pinned — `test/mix/tasks/mailglass.repo.hygiene_test.exs:148`,
     `"cannot-check takes precedence over a confirmed policy block"` — and D-35 instructed 166-06's
     executor to pin current behavior, which it did.
  3. It is not lossy. The text renderer (`Enum.each(result.checks, ...)`, line 520) and the JSON
     encoder both emit every individual check, so the `:blocked` finding is still fully visible in
     the output; only the one-line `reason/1` headline and the aggregate exit code prefer
     cannot-check.
  4. The control does not fail open either way — `:cannot_check` exits 2 and `:blocked` exits 1,
     both non-zero, so the workflow step fails identically.

  The precedence is a defensible reading ("do not issue a verdict on a repository you could not
  fully observe"), and the opposite reading ("a confirmed alarm outranks an unknown") is also
  defensible. Flipping a fail-closed control's semantics on review-agent initiative, against a
  deliberate pin, is not a call to make at phase close. Carry to Phase 167 as an explicit design
  question for the maintainer.

- **WR-02 — `report_sha256` in the coverage baselines is decorative.** The field is recorded in
  `config/coverage_baselines/*.json` and cited as provenance in SUMMARY prose, but neither
  `scripts/check_coverage_floor.sh` nor any test reads or verifies it. This is genuinely on-theme
  for v2.8 (data presented as proof that proves nothing), but it touches the Phase 166-01 coverage
  baseline contract rather than any control this phase was chartered to fix. Phase 167 candidate:
  either verify the digest at floor-check time or stop citing it as evidence.

- **WR-04 — `support_contract_admin` runs the 510-test admin suite twice.** Once via
  `verify.support_contract.admin` and again under the coverage step. Wasteful and it doubles the
  flake surface of a required job, but not a correctness defect. Phase 167 candidate.

- **IN-01 — `scripts/release_policy.exs`'s bare-invocation guard only catches three known-stale
  flag spellings.** Other bare `elixir scripts/release_policy.exs <verb>` forms still exit 0
  without invoking `cli/1`. This is the same vacuity shape 166-06's executor hit in the plan's own
  verify command and worked around by using `mix run -e cli(System.argv())`. No shipped code path
  depends on the bare form, so it is latent rather than live. Phase 167 candidate: make the guard
  reject any invocation that does not reach `cli/1`, rather than enumerating stale spellings.
