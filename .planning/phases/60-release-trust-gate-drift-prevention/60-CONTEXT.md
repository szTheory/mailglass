# Phase 60: release-trust-gate-drift-prevention - Context

**Gathered:** 2026-05-29 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Gate release trust claims on **published-version** trust evidence and close the active
smoke-risk reliability gap. Requirements in scope: **EVID-03, OPS-01, OPS-02** (plus the
folded **EVID-02** clean-baseline lane todo — now unblocked by the 1.3.0 publish).

This phase is CI/release/ops plumbing + docs, not product source. The "code" is GitHub
Actions workflows, shell scripts, the reference host app's dep declaration, the
`MAINTAINING.md` release runbook, and one regression-guard test.

**Out of scope (do not creep):** provider-matrix broadening, `gen_smtp` expansion,
`SEED-003` promotion, new reference-app product features, and the Phase 61 docs-contract
boundary work (DOCB-01..03). Changing the locked hands-free publish posture (the
`hex-publish` environment has no required reviewers) is also out of scope.
</domain>

<decisions>
## Implementation Decisions

### Area 1 — Published-version + clean-baseline trust journey (EVID-03, EVID-02)

- **D-01:** The trust runner (`mix mailglass.trust.run`, exposed via the root `verify.reference_host.journey` alias) is **NOT shipped to Hex** — it lives in the root repo `dev/` tree (`dev/mix/tasks/mailglass.trust.run.ex` + `dev/mailglass/reference_host/*`), compiled only in `:dev`/`:test`. Both trust lanes therefore run the **repo-root runner as orchestrator** with `--host-root reference/host_app`. Do NOT attempt to call a shipped Mix task from inside `reference/host_app` (aliases/tasks are not inherited from deps — this was the Phase 59 deferral cause).
- **D-02:** The "published-version / clean-baseline" property comes entirely from `reference/host_app` resolving its three siblings (`mailglass`, `mailglass_admin`, `mailglass_inbound`) from **Hex** (`~> 1.3` / `~> 1.3` / `~> 0.3`) instead of path deps. Enabling edit: bump `reference/host_app/mix.exs` (currently `~> 1.2`) and refresh `reference/host_app/mix.lock`. Verify Hex-source with the already-shipped `scripts/check_clean_baseline_hex_only.sh`.
- **D-03 (EVID-02, folded todo):** Add a `trust_lane_clean_baseline` job to `.github/workflows/ci.yml` (PR trigger). Shape: run from repo root → `cd reference/host_app && mix deps.get && mix compile` (Hex-sourced dev build) → `bash scripts/check_clean_baseline_hex_only.sh` (from `reference/host_app/`) → `mix verify.reference_host.journey --host-root reference/host_app` **from repo root** → validate `tmp/mailglass_trust_runner/checkpoint.json` via `scripts/check_trust_runner_checkpoint.sh` → upload as `trust-runner-clean-baseline-${{ github.run_id }}` (retention-days 90, if-no-files-found error, exact path). The 59-02-PLAN.md Task 1 Edit B body is **superseded** — its `working-directory: reference/host_app` + bare task call is the impossible path.
- **D-04 (clean-baseline gate posture — USER-CONFIRMED):** The `trust_lane_clean_baseline` lane stays **publish-gate-only (the Phase 59 "A1 lock" reading)** — it gates publish via `gate-ci-green` but is **NOT** added to `REQUIRED_CHECKS`/branch protection. A path-dep leak / Hex-resolution break on the reference host blocks releases, not every PR merge. Reversible later (one-line `REQUIRED_CHECKS` add) if drift pressure warrants. **Do not silently flip this to a required check.**
- **D-05 (EVID-03):** The published-version trust journey is the **same mechanism** as D-03, attached to `.github/workflows/post-publish-smoke.yml` (which already resolves the published version, waits for Hex index + HexDocs, and generates a consumer host). It runs **POST-publish** as a sentinel/evidence gate (publish is hands-free with no pre-publish human gate), and its green status drives milestone-trust-claim acceptance (see D-08). EVID-02 and EVID-03 are one trust-journey mechanism in two trigger contexts (PR `ci.yml` vs `release`/`schedule` smoke). Recommended attachment: **extend `post-publish-smoke.yml`** (it already owns the post-publish, version-aware, issue-tracker lifecycle) rather than a new workflow.

### Area 2 — OPS-01: hackney regression protection + issue #32

- **D-06:** The hackney failure root cause is genuinely fixed (the installer template emits `config :swoosh, :api_client, false`, so a fresh `--no-mailer` host boots without hackney/finch). Keep `test/mailglass/install/install_first_preview_smoke_test.exs` as the **unit-level** contract guard.
- **D-07:** Add a **live regression guard** to `post-publish-smoke.yml`'s `consumer-install` job that fails if `mix mailglass.install` reintroduces a hackney/api_client dependency on a fresh **published** host (mirror the existing `UndefinedFunctionError` grep guard at `post-publish-smoke.yml:408-411`). Close issue **#32** ("publish-smoke failure tracker", still OPEN) **only after** the next post-publish-smoke run is green with this guard in place — do not close it on the strength of the one-time local test run that marked the todo "completed".

### Area 3 — OPS-02: release checklist + cadence require green trust evidence

- **D-08:** Satisfy OPS-02 by editing **`MAINTAINING.md`**: (a) list green trust evidence as an explicit release-gate item — the `Trust Lane Repo Head` required check + the new clean-baseline/published-version journey + the `trust-runner-*` checkpoint artifacts — under the "Verify CI green" runbook step and the "Required Checks" section; (b) add a maintenance-cadence note that the post-publish trust journey (the EVID-03 sentinel) must be green before milestone trust claims / v1.3 closeout.
- **D-09:** In the same pass, reconcile the `MAINTAINING.md` "Required Checks" list — it currently omits the Phase 59 `Trust Lane Repo Head (Elixir 1.18 / OTP 27)` context that was added to `scripts/setup_branch_protection.sh` REQUIRED_CHECKS.
- **D-10:** In the same pass, **fix two stale lines** in `MAINTAINING.md` (around line 24 and line 260) that describe a manual `hex-publish` GitHub-Environment approval gate. That gate does NOT exist (locked hands-free publish — no required reviewers); a release checklist that requires "green trust evidence" must not also instruct the maintainer to click an approval that isn't there.

### Claude's Discretion
- **Exact placement** of the OPS-01 live guard within `consumer-install` (a `--no-mailer` boot assertion vs a dedicated published-host install-assertion step) — planner's call; the idiomatic spot is alongside the existing compile-log grep.
- **Whether to add a machine-checkable doc-contract test** for the `MAINTAINING.md` green-trust-evidence requirement (repo precedent exists, e.g. `install_first_preview_smoke_test.exs:30-39` asserts workflow strings). Nice-to-have, not required by the OPS-02 success criterion — planner judgment.
- **Whether EVID-03 reuses the full 5-stage runner or a bounded subset** in the post-publish context — confirm what the published-version journey can actually exercise (the runner loads `MailglassReferenceHostWeb.Router` + sibling beams from the host's `_build/dev`; the same `cd reference/host_app && mix deps.get && mix compile` prep the repo-head lane uses at `ci.yml:853-862` applies).

### Folded Todos
- **EVID-02 / clean-baseline trust lane** — `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` is folded into this phase (D-03, D-04). Its "Ready-made building blocks" (the Hex-source guard script, `gate-self-test.yml check_name` input, `test/scripts/required_checks_test.exs` drift contract) still apply; its "What done looks like" step that calls the task from `reference/host_app` is **wrong** and superseded by D-01/D-03. Mark the todo resolved when D-03 lands.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — EVID-02, EVID-03, OPS-01, OPS-02 requirement text + traceability table
- `.planning/ROADMAP.md` — Phase 60 goal + success criteria (v1.3 section)
- `.github/workflows/ci.yml` — existing repo-head trust lane (~`ci.yml:853-862` builds the reference host); where `trust_lane_clean_baseline` goes
- `.github/workflows/publish-hex.yml` — `gate-ci-green` job (~line 115); confirms publish gate only inspects `ci.yml` checks
- `.github/workflows/post-publish-smoke.yml` — EVID-03 attachment point + OPS-01 live-guard location (`consumer-install` lines 367-438; `UndefinedFunctionError` grep at 408-411; `notify-on-failure` issue tracker at 495-571)
- `.github/workflows/release-please.yml` — hands-free release sequence (auto-merge armed ~lines 215-232)
- `dev/mix/tasks/mailglass.trust.run.ex` — the runner; `--host-root` flag (~lines 33,45-53,118-141); checkpoint default path
- `dev/mailglass/reference_host/{webhook_operator_proof,operator_diagnosis_proof,trust_checkpoint}.ex` — journey proof modules (dev-only, unshipped)
- `reference/host_app/mix.exs` (dep pins ~lines 32-34) + `reference/host_app/mix.lock` + `reference/host_app/SCOPE.md` — the host to bump to Hex `~> 1.3`
- `scripts/check_clean_baseline_hex_only.sh` — Hex-source guard (shipped Phase 59 P01)
- `scripts/check_trust_runner_checkpoint.sh` — checkpoint validator
- `scripts/setup_branch_protection.sh` — REQUIRED_CHECKS array (do NOT add the clean-baseline lane per D-04)
- `MAINTAINING.md` — OPS-02 surface; "Required Checks" (~144-147), "Release Runbook" (~241-260), stale approval-gate lines (~24, ~260)
- `test/mailglass/install/install_first_preview_smoke_test.exs` — OPS-01 unit contract guard (REL-17 assertion ~16-20; workflow-string asserts ~30-39)
- `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` — folded EVID-02 (its "call the task from reference/host_app" step is superseded)
- `.planning/todos/completed/2026-05-27-resolve-post-publish-smoke-hackney-dependency-failure.md` — OPS-01 history (resolved via one-time local run, no live guard)
- `.planning/phases/59-ci-trust-lanes-checkpoint-evidence/59-02-PLAN.md` (Task 1 Edit B — superseded shape) + `59-VERIFICATION.md` (gaps_found; required-check reconciliation context)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/check_clean_baseline_hex_only.sh` — inspects resolved `reference/host_app/mix.lock` for `:hex` source on all three siblings; ready to wire into the clean-baseline lane.
- `scripts/check_trust_runner_checkpoint.sh` — validates `tmp/mailglass_trust_runner/checkpoint.json`; reuse for both lanes.
- `gate-self-test.yml` `check_name` input — can self-test the new lane's enforcement.
- `test/scripts/required_checks_test.exs` — name-agnostic array/heredoc drift contract for REQUIRED_CHECKS.
- `post-publish-smoke.yml` already owns the post-publish lifecycle: version resolution (`cron-guard`), Hex-index + HexDocs waits, consumer Phoenix host generation, retracted-check, and the auto-opening `publish-smoke-failed` issue tracker — EVID-03 extends this rather than rebuilding it.
- The repo-head trust lane in `ci.yml` (~853-862) already does `cd reference/host_app && mix deps.get && mix compile` before running the runner — the clean-baseline lane needs the identical prep, only with Hex-sourced deps.

### Established Patterns
- Trust runner orchestrates from repo root via `--host-root`; checkpoint emitted to `tmp/mailglass_trust_runner/checkpoint.json`; artifacts uploaded with `retention-days: 90`, `if-no-files-found: error`, exact path (Pitfall 6).
- Internal dev/CI tooling lives in `dev/` (compiled `:dev`/`:test` only, excluded from Hex `:files`); `dev/` mirrors `lib/` depth for `__DIR__`-relative paths; `.dialyzer_ignore.exs` filters point at `dev/` paths.
- Publish is fully hands-free: `hex-publish` environment has no reviewers; release-please auto-merges on green; `gate-ci-green` is the publish gate and only inspects `ci.yml` checks (whitelists only "Operator Browser Gate").
- Regression guards in `consumer-install` are grep-on-compile-log style (e.g., `UndefinedFunctionError` at lines 408-411).

### Integration Points
- New `trust_lane_clean_baseline` job → `ci.yml` (gated via `gate-ci-green`, NOT in `REQUIRED_CHECKS`).
- Published-version trust journey → `post-publish-smoke.yml` (new job in the existing chain).
- OPS-01 live guard → `post-publish-smoke.yml` `consumer-install` job.
- OPS-02 doc gate → `MAINTAINING.md` (Required Checks + Release Runbook sections).
- `reference/host_app/mix.exs` + `mix.lock` dep bump → enables both Hex-baseline lanes.
</code_context>

<specifics>
## Specific Ideas

- User confirmed clean-baseline lane stays **publish-gate-only (A1 lock)**, not a required branch-protection check (D-04). Reason given implicitly by accepting the Phase 59 reading: keeps PR merges from depending on a Hex-baseline reference-host build; reversible later.
</specifics>

<deferred>
## Deferred Ideas

- **Adding `trust_lane_clean_baseline` to `REQUIRED_CHECKS`** — explicitly declined for now (D-04). Revisit only if path-dep / Hex-resolution drift starts slipping past the publish gate.
- **Phase 61 docs-contract boundary (DOCB-01..03)** — separate phase, not Phase 60.
- **Multi-provider trust matrix in reference host (FUTR-01)** and other FUTR-* breadth — post-milestone.

### Reviewed Todos (not folded)
- None beyond the single pending EVID-02 todo, which WAS folded (D-03/D-04). The completed hackney todo informs OPS-01 (D-06/D-07) as history, not as new scope.
</deferred>
