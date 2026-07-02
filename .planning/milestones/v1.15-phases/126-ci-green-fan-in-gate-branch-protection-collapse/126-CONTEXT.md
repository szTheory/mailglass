# Phase 126: CI Green fan-in gate + branch-protection collapse - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning
**Source:** Synthesized from research-complete decisions of record (`.planning/research/milestone-cicd/SYNTHESIS.md`, LD-6). Milestone v1.15 is research-complete — discuss-phase and RESEARCH.md are intentionally skipped; SYNTHESIS.md is the canonical decision record. This CONTEXT also carries orchestrator file-reconnaissance (exact job names, line numbers, and the workflow-level `paths-ignore` finding) done during planning setup.

<domain>
## Phase Boundary

Collapse the five required leaf branch-protection contexts into a single `CI Green` aggregate job
(plus `Guard Release Trigger`), with **release-SHA-safe `skipped` handling** and a **set-equality**
coverage meta-test so no required lane can silently drop out of `needs`. Also fix the stale
`gate-self-test.yml` default and verify `guard-release-trigger` always reports.

**In scope:**
- A new `CI Green` aggregate job in `.github/workflows/ci.yml` (`if: always()`, explicit `needs`).
- Collapsing `scripts/setup_branch_protection.sh` `REQUIRED_CHECKS` to `{CI Green, Guard Release Trigger}`.
- Ensuring `CI Green` **always reports a status** on every PR to main (the workflow-level `paths-ignore`
  trap — see Specific Ideas).
- Hardening the publish/release path so a `skipped` required lane does NOT count as green
  (`publish-hex.yml` `gate-ci-green`, GATE-02).
- The coverage meta-test (extend `test/scripts/required_checks_test.exs`): set-equality between
  `REQUIRED_CHECKS`, `ci-green.needs`, and the real job set; no required lane permanently `if:`-disabled.
- `gate-self-test.yml` `check_name` default fix + `guard-release-trigger` always-reports verification.

**Out of scope:** Any product/provider/transport/route/schema change (D-23 convergence). The `mix ci`
parity work and the `ci_lanes` manifest's *full* population (that is Phase 128 — this phase MAY seed the
shared source but only needs the required-lane set). Inbound determinism / `--seed 0` deletion (Phase
127). Dialyzer promotion to required (Phase 129, gated on the PLT fix — LD-7; do NOT add `dialyzer` to
`ci-green.needs`). Actual branch-protection API mutation is owned by `branch-protection-drift.yml`
(the daily `Branch Protection Apply` workflow) + a maintainer with the PAT — this phase changes the
*desired* ruleset in the script and lets that workflow re-assert it; do not call the GitHub API from here.

**Depends on:** Phase 125 (the pin change is green on main; keystone lands before pipeline gates are
re-shaped). Phase 125 is complete + verified.
</domain>

<decisions>
## Implementation Decisions

### GATE-01 — `CI Green` aggregate job + branch-protection collapse (LD-6, locked)

- **Add a `ci_green` job** to `.github/workflows/ci.yml` (currently 1068 lines; last job is
  `branch_protection_advisory` at :1020). Job display `name: CI Green`, `if: always()`, `runs-on:
  ubuntu-latest`, with an **explicit `needs:`** list of the five required leaf jobs:
  - `support_contract_core` (name "Support Contract Core (Elixir 1.18 / OTP 27)", :143)
  - `support_contract_admin` (name "Support Contract Admin (Elixir 1.18 / OTP 27)", :584)
  - `compile_no_optional_deps` (name "Compile No Optional Deps (Elixir 1.18 / OTP 27)", :85)
  - `trust_lane_repo_head` (name "Trust Lane Repo Head (Elixir 1.18 / OTP 27)", :874)
  - `installer_host_smoke` (name "Installer Host Smoke", :111)
- **Aggregate verdict (PR path):** fail `CI Green` if any needed job's `result` is `failure` or
  `cancelled`; treat `skipped` as OK (so a docs-only / path-filtered PR still passes — the release-SHA
  strictness is enforced separately by GATE-02, not by `CI Green`). Use the standard
  `needs.<job>.result`/`toJSON(needs)` fan-in pattern; do NOT hardcode a re-list of job names inside the
  step body in a way that can drift from `needs:` (derive from `needs` context where practical, or the
  GATE-03 meta-test must cover the body list too).
- **`scripts/setup_branch_protection.sh`:** replace the 5-entry `REQUIRED_CHECKS` array (:17–23) with
  exactly two contexts — `"CI Green"` and `"Guard Release Trigger"` — and update the
  `print_expected_text` heredoc bullets (:28–32) to match char-for-char. `Guard Release Trigger` is the
  job name from `guard-release-trigger.yml:14`. NOTE: guard-release-trigger is NOT currently in
  `REQUIRED_CHECKS`; this phase *adds* it as the 2nd required context while collapsing the 5 leaves.
- The `strict: true` and the non-context fields in `expected_json` (:52–68) stay unchanged.

### GATE-02 — `skipped ≠ success` on the release/publish path (LD-6, locked)

- The `CI Green` PR-path rule tolerates `skipped`. That is a **genuine hole on the release SHA**:
  release commits touch many paths, `docs(state):` skips CI entirely, and a required lane that
  path-skips would be blessed green. So the publish path must re-assert that each required lane actually
  **executed with `success`**.
- **File:** `.github/workflows/publish-hex.yml`, `gate-ci-green` job, step "Verify CI is green on tagged
  SHA" (:190–259). **Current bug:** `blockingFailures` (:242–244) filters
  `j.conclusion !== 'success' && j.conclusion !== 'skipped'` — so a **skipped required lane passes**.
- **Fix:** introduce an explicit `REQUIRED_LANES` set (the 5 leaf job display names above) inside that
  script. A required lane must be present in the run's jobs AND have `conclusion === 'success'`; any
  required lane that is missing, `skipped`, `failure`, `cancelled`, etc. → `core.setFailed(...)` with a
  brand-voice "Delivery blocked: …" message naming the offending lane(s). Advisory lanes keep their
  existing skip-tolerance (the `ADVISORY_LANES` + `/ Advisory \(/` logic at :205–208, :238–240 stays).
  Keep the `latest.conclusion === 'success'` fast-path (:227) only if it still guarantees every required
  lane ran — safer to always evaluate the required-lane presence/success check.

### GATE-03 — coverage meta-test: set-equality, not superset (LD-6, locked)

- **Extend** `test/scripts/required_checks_test.exs` (existing REQUIRED_CHECKS drift test). It must now
  assert **set-equality** between three sources — failing if any diverges:
  1. `REQUIRED_CHECKS` in `setup_branch_protection.sh` → now `{"CI Green", "Guard Release Trigger"}`.
  2. The `ci-green` job's `needs:` list in `ci.yml` (the 5 required leaf jobs).
  3. The **actual job set** in `ci.yml` — every entry in `ci-green.needs` must be a real, defined job
     (NOT a superset that names a nonexistent job; NOT missing a lane the required set intends).
- Assert **no required lane is permanently `if:`-disabled** — a job whose `if:` is a literal `false`
  (or an always-false constant) "passes" vacuously and must fail the meta-test. (Path-conditional /
  event-conditional `if:` are fine; only a permanently-off constant is the anti-pattern.)
- **Keep an anti-vacuity guard** (mirror the existing `MapSet.size(...) > 0` assertions at :20–24): if
  any parser returns an empty set, fail loudly — a format change must never make the test pass by
  parsing nothing.
- **Reconcile the existing sub-tests:** the `@v1_0_lock_entries` test (:35–43) currently asserts the 3
  Phase-27 stability-lock lanes are in `REQUIRED_CHECKS`. They have **moved behind `CI Green`** — rewrite
  that assertion to require them in `ci-green.needs` instead. The D-04 sub-test (:45–50, "clean-baseline
  lane is NOT required") must still hold — assert the clean-baseline lane is in neither `REQUIRED_CHECKS`
  nor `ci-green.needs`.
- The meta-test parses YAML/text from the workflow file(s) and the script; a small `.github/`-reading
  helper is fine. Prefer a real YAML parse of `ci.yml` over brittle regex where feasible.

### GATE-04 — `gate-self-test` default fix + `guard-release-trigger` always-reports (LD-6, locked)

- **`gate-self-test.yml`:** the `check_name` input default (:23) is the stale `"Tests ("` — a lane that
  no longer exists as the gate. Change the default to `"CI Green"` so the self-test polls the real
  required aggregate. Also update the human-facing copy that says "Tests gate" (the workflow header
  comment :3–11, the job name :32 "Verify Tests gate blocks failing PRs", the summary text :165–175) to
  be gate-agnostic / name the `CI Green` gate — brand voice, no "Oops". The poll uses
  `startswith(env.CHECK_NAME)` with `--required` (:123–125), so `"CI Green"` will match the required
  context.
- **`guard-release-trigger` always reports:** because it becomes a required branch-protection context,
  it must post a status on **every** PR to main or it re-introduces green-but-BLOCKED (a required check
  that never reports leaves the PR stuck "Expected"). Verify + lock the invariant:
  `guard-release-trigger.yml` triggers on `pull_request: types: [opened, edited, synchronize, reopened]`
  with **no `paths:`/`paths-ignore:` filter** (:3–6) → it always runs and always `exit 0`/`exit 1`s
  (never no-ops without a status). Add a lightweight assertion (in the GATE-03 meta-test or a sibling
  test) that `guard-release-trigger.yml` has no path filter and includes the trigger types that
  guarantee a report. Do NOT add a `paths-ignore` to it.

### Claude's Discretion
- The exact fan-in expression for `CI Green`'s verdict (a `if: always()` job with a shell/`toJSON(needs)`
  step, vs. per-`needs` `result` checks) — provided a `failure`/`cancelled` in any required leaf reds it
  and `skipped` is tolerated on the PR path.
- Whether to introduce the shared `ci_lanes` source of truth (LD-10, shared with Phase 128 MIXCI-03)
  **now** as a single manifest (data file or module the meta-test + publish gate both read) or defer full
  population to Phase 128. Recommended: seed a minimal shared required-lane list here so GATE-03 and the
  Phase-128 parity-drift test can both consume it — but the atomic requirement for 126 is only the
  required-lane set.
- How to make `CI Green` **always report** given the workflow-level `paths-ignore` (see Specific Ideas):
  the recommended idiomatic fix is a `changes`/paths-detection gate job + per-leaf `if:` so the workflow
  always runs and leaves skip individually (letting `CI Green` post `success` with skipped leaves), vs. a
  companion always-on reporter. Pick the least-surprising, most-idiomatic GitHub-Actions pattern; this is
  the crux of GATE-01. A strong idiomatic precedent settles it — do not leave docs-only PRs stuck-pending.
- Plan decomposition: GATE-01 + GATE-03 are tightly coupled (the meta-test must match the collapsed
  script + the new `ci-green.needs`) and should land together; GATE-02 (publish gate) and GATE-04
  (gate-self-test / guard-release-trigger) touch disjoint files and may be a separate plan/wave. 1–2
  plans is the expected shape.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Decisions of record (authoritative — this file wins over raw dossiers)
- `.planning/research/milestone-cicd/SYNTHESIS.md` — LD-6 is Phase 126's binding decision; §0 ground-truth
  corrections; §7 "PR required" promotion caveat (do NOT silently promote advisory lanes — LD-7 defers
  Dialyzer). LD-10 defines the shared `ci_lanes` manifest that GATE-03 and Phase-128 MIXCI-03 share.
- `.planning/research/milestone-cicd/CICD-RELEASE-HARDENING.md` — raw release-eng dossier (version/line
  stale; SYNTHESIS overrides on conflict).

### Files this phase changes
- `.github/workflows/ci.yml` — add the `CI Green` aggregate job; resolve the workflow-level
  `paths-ignore` (:5–13) so `CI Green` always reports.
- `scripts/setup_branch_protection.sh` — `REQUIRED_CHECKS` (:17–23) → `{CI Green, Guard Release Trigger}`
  + matching `print_expected_text` heredoc (:28–32).
- `.github/workflows/publish-hex.yml` — `gate-ci-green` "Verify CI is green on tagged SHA" step
  (:190–259): required lanes must be `success` (skipped required lane blocks).
- `test/scripts/required_checks_test.exs` — extend to the set-equality coverage meta-test (GATE-03).
- `.github/workflows/gate-self-test.yml` — `check_name` default (:23) `"Tests ("` → `"CI Green"` + copy.
- `.github/workflows/guard-release-trigger.yml` — read-only verify no path filter (:3–6); do not weaken.

### Files this phase reads (do not change unless a decision above requires it)
- `.github/workflows/branch-protection-drift.yml` — the `Branch Protection Apply` workflow that re-asserts
  the ruleset from the script (why we edit the script, not the live API).
- `scripts/verify-branch-protection.sh` — read-only verifier that diffs live protection vs the script's
  `--print-expected-json`; it inherits the new 2-context set automatically.
- `.github/workflows/ci.yml` job inventory (names above) — the required-leaf display names.

### Project conventions
- `./CLAUDE.md` — release mechanics; "Hex publish only from a protected ref"; hands-free auto-merge;
  "All third-party GitHub Actions pinned to commit SHA" (any new `uses:` must be SHA-pinned); brand voice
  for CI failure messages ("Delivery blocked: …", never "Oops"); "Things Not To Do".
- `.planning/REQUIREMENTS.md` — GATE-01..04 acceptance wording.
</canonical_refs>

<specifics>
## Specific Ideas

- **The workflow-level `paths-ignore` trap (central GATE-01 design point).** `ci.yml` (:5–13) has
  `paths-ignore: [.planning/**, prompts/**]` at the WORKFLOW level on both `push` and `pull_request`. A
  PR that touches only those paths runs **no jobs at all**, so a required `CI Green` context would never
  post → the PR is stuck "Expected — waiting for status" (green-but-BLOCKED), the exact regression GATE-04
  guards against. LD-6's "'skipped is OK' rule (so docs-only path-filtered PRs don't false-fail)" assumes
  `CI Green` *runs* and sees *skipped leaves* — which requires the workflow to always trigger, with the
  leaves gated individually. The recommended fix: drop the workflow-level `paths-ignore`, add a
  changes-detection gate job (e.g. a first job that computes whether non-doc paths changed), and gate each
  leaf's `if:` on it; `CI Green` (`if: always()`) then always runs and posts `success` when leaves are
  skipped. Preserve the intent that docs/planning-only PRs don't burn the full matrix.
- **Anti-recursion note stays true.** The `workflow_dispatch` trigger + comment (:14–20) exists so
  `publish-hex.yml`'s `gate-ci-green` can dispatch `ci.yml` on the release PR head SHA (GITHUB_TOKEN
  pushes don't fire `push`/`pull_request`). Any restructure must keep `workflow_dispatch` working and keep
  `CI Green` runnable on a dispatched run so the publish gate can find it.
- **New `uses:` must be SHA-pinned.** If the changes-detection approach adds an action (e.g. a
  paths-filter action), pin it to a commit SHA per CLAUDE.md; a hand-rolled `git diff` gate job avoids a
  new dependency entirely and is preferred.
- **Relevant memory:** `project_milestone_1_2_designed.md` (this milestone's design + the keystone
  ordering), `project_1_10_2_patch_release.md` (release-recovery gotchas — the allowlist-not-in-PR-CI and
  gate-ci-green behavior), `project_ci_advisory_and_dep_pr_facts.md` (advisory-lane facts:
  Core Full Suite Advisory is the only full-core-mix-test lane; advisory naming convention).
- **Verify by running, not grep.** For the meta-test, run `mix test test/scripts/required_checks_test.exs`
  and `actionlint .github/workflows/ci.yml` (actionlint.yml exists) rather than eyeballing YAML.
</specifics>

<deferred>
## Deferred Ideas
- Full `ci_lanes` manifest population + `mix ci` parity-drift test — Phase 128 (MIXCI-03 shares the source
  seeded here).
- Inbound determinism / `--seed 0` deletion — Phase 127.
- Dialyzer / format / credo / compile-warnings promotion to required — Phase 129+ (LD-7: only after PLT
  self-healing lands; do NOT add them to `ci-green.needs` in this phase).
- Cache-key single-source + PLT self-healing — Phase 129.
- Supply-chain / actionlint-on-PR / dependabot sibling coverage — Phase 130.
- The real linked Hex release — Phase 131.
</deferred>

---

*Phase: 126-ci-green-fan-in-gate-branch-protection-collapse*
*Context synthesized 2026-07-01 from SYNTHESIS.md LD-6 (research-complete milestone) + orchestrator file reconnaissance*
