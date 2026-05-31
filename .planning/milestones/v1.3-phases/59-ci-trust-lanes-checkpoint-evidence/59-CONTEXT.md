# Phase 59: ci-trust-lanes-checkpoint-evidence - Context

**Gathered:** 2026-05-27 (assumptions mode, in-thread)
**Status:** Ready for planning

<domain>
## Phase Boundary

Enforce trust proof in required CI lanes and publish machine-readable checkpoint evidence artifacts.

This phase satisfies `EVID-01`, `EVID-02`, and `EVID-04`: a repo-head trust lane is required in CI and fails on missing checkpoints; a clean-baseline trust lane enforces Hex-first dependency resolution and blocks path-dependency leakage; both lanes emit machine-readable `trust_runner.v1` checkpoint artifacts that Phase 60's release gate will ingest as evidence.

This phase is purely a CI surface and artifact-emission phase on top of the runner contract already locked by Phases 52, 57, and 58. It does not change the trust runner, the checkpoint schema, the reference host wiring, the public seam boundary, or any product code. It does not gate published-version trust journeys, post-publish smoke reliability, or release-checklist semantics — those are Phase 60. It does not change docs contract boundary language — that is Phase 61.

</domain>

<decisions>
## Implementation Decisions

### Lane Placement and "Required" Semantics
- **D-01:** Add the two new trust lanes as new jobs inside `.github/workflows/ci.yml`, not as a separate workflow file. Every existing required lane in this repo lives in `ci.yml`, and `publish-hex.yml`'s `gate-ci-green` job only inspects runs of `workflow_id: 'ci.yml'`. A separate file would silently bypass the publish gate.
- **D-02:** Make the repo-head trust lane "required" by adding its exact job name to `REQUIRED_CHECKS` in `scripts/setup_branch_protection.sh` (the single source of truth that `.github/workflows/branch-protection-drift.yml` guards). Adding it to `REQUIRED_CHECKS` is the definition of required — adding it to `ci.yml` alone does not satisfy EVID-01.
- **D-03:** Pin the OTP/Elixir matrix to `1.18 / 27`, matching the existing required-lane convention in `ci.yml`. Do not add a second matrix entry for Phase 59 — `mix verify.reference_host.journey` is already evidenced as deterministic on this version pair by phases 57 and 58, and broadening the matrix here is provider-breadth scope creep.

### Repo-Head Trust Lane (EVID-01)
- **D-04:** The repo-head lane runs `mix verify.reference_host.journey` from the repo root, then runs `bash scripts/check_trust_runner_checkpoint.sh` against the runner's default checkpoint path. The validator already exits non-zero on missing/malformed checkpoints — Phase 59 does not invent a new failure surface, it wires the existing one into CI.
- **D-05:** "Fails on missing trust checkpoints" is satisfied by `scripts/check_trust_runner_checkpoint.sh` (existing behavior: `missing checkpoint at '$CHECKPOINT_PATH'` → exit 1). No new validator logic is in scope.
- **D-06:** Use the runner's default `tmp/mailglass_trust_runner/checkpoint.json` path. Do not relocate, do not pass `--checkpoint-out`. The validator's default and the runner's default agree; preserving the default keeps local-dev parity with CI.

### Clean-Baseline Hex-First Lane (EVID-02)
- **D-07:** Run the clean-baseline lane from the `reference/host_app` working directory. Its `mix.exs` already declares `{:mailglass, "~> 1.2"}`, `{:mailglass_admin, "~> 1.2"}`, `{:mailglass_inbound, "~> 0.2"}` with no `path:` keys — published Hex packages at 1.2.0 / 1.2.0 / 0.2.0 are already live, so this lane proves the journey works against the line an adopter actually consumes today. No chicken-and-egg with the in-flight v1.3 milestone.
- **D-08:** Enforce Hex-first by inspecting `mix.lock` *after* `mix deps.get`, not by grepping `mix.exs`. The lane fails if any resolved entry for `mailglass`, `mailglass_admin`, or `mailglass_inbound` in `mix.lock` is not a `:hex` source. This catches both a future contributor adding a `path:` override and any transitive resolution that resolves a sibling via path.
- **D-09:** Do not pollute the clean-baseline lane with the root project's dev path overrides. The lane operates from `reference/host_app` exclusively — it does not run `mix deps.get` from the repo root or from `mailglass_admin/`/`mailglass_inbound/` (whose `mix.exs` use a `MIX_PUBLISH`-gated path/version branch for local dev).
- **D-10:** The clean-baseline lane runs the same trust journey command as the repo-head lane (`mix verify.reference_host.journey` from within `reference/host_app/`) and applies the same `scripts/check_trust_runner_checkpoint.sh` validator against its checkpoint.

### Machine-Readable Checkpoint Artifacts (EVID-04)
- **D-11:** Both lanes upload their `trust_runner.v1` checkpoint JSON via `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02` (v4) — the exact SHA already pinned in `ci.yml` for `preview_capture_advisory`. Reusing the pinned SHA avoids expanding the pinned-Actions surface area and keeps Dependabot noise bounded.
- **D-12:** Use `if-no-files-found: error` on both uploads. This is the second enforcement layer for EVID-01: if the lane somehow reached the upload step without a checkpoint, the upload fails.
- **D-13:** Artifact names are stable and disambiguated by run ID: `trust-runner-repo-head-${{ github.run_id }}` and `trust-runner-clean-baseline-${{ github.run_id }}`. The `run_id` suffix matches the `preview_capture_advisory` precedent and avoids GitHub's duplicate-artifact-name rejection on workflow re-runs.
- **D-14:** Retention is `retention-days: 90` (longer than the 14d preview-capture default). Phase 60's release ceremony may run on a quarterly cadence and must be able to ingest evidence without re-running CI. The artifact is a tiny JSON (~2 KB).
- **D-15:** Do not change the runner-emitted checkpoint shape, schema version, stage ordering, hash semantics, bounded claim text, or fixture IDs. The schema is `trust_runner.v1` and is the binding contract for Phase 60 release-gate consumption. Phase 59 ships the *transport* (CI lane + artifact upload), not the schema.

### Claude's Discretion
- Exact job names in `ci.yml` (must be human-readable, follow the `Title Case (Elixir 1.18 / OTP 27)` convention, and the repo-head name must match the string added to `REQUIRED_CHECKS`).
- Whether to emit a small step that prints the checkpoint hash to the GitHub Actions log for human-glance evidence in addition to artifact upload (recommended but not required).
- Whether the `mix.lock` Hex-source guard is a short inline shell snippet or a dedicated `scripts/check_clean_baseline_hex_only.sh`. If reusable beyond Phase 59, prefer the script form; if one-off, prefer inline.
- Where in `ci.yml`'s job graph the new lanes sit (early, parallel with existing required lanes, before `gate-ci-green`); choose to maximize parallelism without re-doing dep cache work the existing lanes already pay for.

### Folded Todos
None. No backlog items roll into this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase intent and locked requirements
- `.planning/ROADMAP.md` — Phase 59 goal, requirement mapping (`EVID-01`, `EVID-02`, `EVID-04`), and success criteria.
- `.planning/REQUIREMENTS.md` — v1.3 CI and Release Trust Evidence requirements, traceability mapping.
- `.planning/PROJECT.md` — v1.3 preflight locks, public-seam posture, trust-evidence posture, pinned-Actions rule.
- `.planning/STATE.md` — current milestone state and active risk context.

### Prior locked context
- `.planning/phases/52-trust-scope-lock-reference-host-baseline/52-CONTEXT.md` — reference-host public-seam boundary and scope lock.
- `.planning/phases/57-deterministic-trust-runner-fixtures/57-CONTEXT.md` — canonical runner entrypoint, deterministic fixtures, and checkpoint schema contract.
- `.planning/phases/58-verify-first-webhook-operator-path/58-CONTEXT.md` — verify-first webhook path and operator diagnosis evidence locked into existing stages.

### CI surface and required-checks contract
- `.github/workflows/ci.yml` — main CI: format check, Credo, dialyzer, tests, no-optional-deps build, `preview_capture_advisory` (canonical "runner → validator → upload-artifact" precedent).
- `.github/workflows/branch-protection-drift.yml` — guards `REQUIRED_CHECKS` against drift; any new required lane changes this file's expected text indirectly via the script below.
- `scripts/setup_branch_protection.sh` — `REQUIRED_CHECKS` array + `print_expected_text` block; the single source of truth for which CI jobs are required.
- `.github/workflows/publish-hex.yml` — `gate-ci-green` job; only inspects `workflow_id: 'ci.yml'` runs (so trust lanes must live in `ci.yml`).
- `.github/workflows/gate-self-test.yml` — gate consistency self-test reference.

### Trust runner and validator surfaces (do not modify in this phase)
- `mix.exs` — `verify.reference_host.journey` alias and preferred test environment.
- `lib/mix/tasks/mailglass.trust.run.ex` — canonical trust-runner task; default checkpoint path is `tmp/mailglass_trust_runner/checkpoint.json`.
- `lib/mailglass/reference_host/trust_checkpoint.ex` — `trust_runner.v1` checkpoint encoder, bounded claim text, deterministic hash.
- `scripts/check_trust_runner_checkpoint.sh` — executable checkpoint schema/order/hash validator; exits non-zero on missing/malformed checkpoint.
- `test/reference_host/trust_runner_command_contract_test.exs` — pinned runner command contract.
- `test/reference_host/trust_runner_checkpoint_contract_test.exs` — repeatable checkpoint/hash contract.

### Clean-baseline lane host surface
- `reference/host_app/mix.exs` — adopter-facing Hex constraints; the working directory for the clean-baseline lane.
- `mailglass_admin/mix.exs` — sibling package with `MIX_PUBLISH`-gated path/version branch (must NOT be the lane's working dir).
- `mailglass_inbound/mix.exs` — sibling package with `MIX_PUBLISH`-gated path/version branch (must NOT be the lane's working dir).

### Project policy
- `CLAUDE.md` — "All third-party GitHub Actions pinned to commit SHA"; "Conventional Commits enforced"; `docs(state):` skipped by path filter (relevant for any commit that touches `.planning/STATE.md`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `preview_capture_advisory` in `ci.yml` is a 1:1 template for "runner → validator → upload-artifact." Its `upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02` (v4) SHA pin, `if-no-files-found: error`, and `${{ github.run_id }}`-suffixed name are the precedent Phase 59 reuses verbatim.
- `scripts/check_trust_runner_checkpoint.sh` already exits non-zero on missing/malformed checkpoints — Phase 59 wires it, does not rewrite it.
- `mix verify.reference_host.journey` already writes its checkpoint to `tmp/mailglass_trust_runner/checkpoint.json` by default; CI inherits the same path.
- `reference/host_app/mix.exs` already declares Hex-only constraints — the clean-baseline lane gets correct-by-default declarations without touching the host's mix.exs.
- `gate-ci-green` in `publish-hex.yml` already auto-includes any `ci.yml` job in publish gating, with an explicit `ADVISORY_LANES` allowlist for opt-out (so adding a new required lane is one job + one entry in `REQUIRED_CHECKS`, no `publish-hex.yml` change required).

### Established Patterns
- Required lanes live in `ci.yml` and are mirrored in `scripts/setup_branch_protection.sh::REQUIRED_CHECKS`. Drift is guarded by `branch-protection-drift.yml`.
- Third-party Actions are pinned to commit SHA, with a single canonical SHA per Action across the repo (Dependabot bumps one place).
- "Failure semantics" for evidence checks are defined by the validator script, not by ad-hoc bash in the workflow.
- Artifact retention follows the consumer's cadence (preview uses 14d for PR-review windows; release-evidence should be longer).

### Integration Points
- Adding a job to `ci.yml` automatically lights it up for `gate-ci-green` (no separate registration). Only the `REQUIRED_CHECKS` mirror and the `branch-protection-drift.yml` expected text need to be updated to make it required.
- The clean-baseline lane must operate inside `reference/host_app` exclusively — running `deps.get` from the repo root would pollute the resolution with the root project's dev dependency graph.
- Phase 60 will consume the uploaded artifacts via GitHub's artifact API keyed by the stable artifact-name prefix; renaming the artifacts later would break that contract.

</code_context>

<specifics>
## Specific Ideas

- Reuse the `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02` SHA pin already present elsewhere in `ci.yml`. Do not introduce a different v4 SHA.
- The clean-baseline Hex-source guard is most naturally an inline `mix run -e` or `elixir -e` snippet that loads `mix.lock` (which is an Elixir term) and asserts each of the three package entries has `:hex` as the source. Pure-bash grep is brittle against `mix.lock` format changes.
- Print the checkpoint hash to the GitHub Actions log (e.g., `jq -r '.hash // .checkpoint_hash'`) as a human-glance evidence step — small ergonomic win.
- Adding to `REQUIRED_CHECKS` requires committing the change first so the new lane is in `ci.yml` AND in the required list at the same point in history; otherwise `branch-protection-drift.yml` will flag drift transiently. Plan the commit ordering accordingly.

</specifics>

<deferred>
## Deferred Ideas

- Published-version trust journey (running the journey against a freshly-published v1.3 in the post-publish workflow) is Phase 60 (`EVID-03`) scope.
- Post-publish smoke hackney failure resolution is Phase 60 (`OPS-01`) scope.
- Release checklist gating on green trust evidence is Phase 60 (`OPS-02`) scope.
- Docs contract boundary language tightening (DOCB-01..03) is Phase 61 scope.
- Provider-matrix CI broadening, `gen_smtp` lanes, and ecosystem-integration lanes remain out of scope for v1.3.
- Broadening the OTP/Elixir matrix on the trust lanes is deferred — v1.3 trust proof is one representative journey, not a compatibility matrix.

</deferred>

---

*Phase: 59-ci-trust-lanes-checkpoint-evidence*
*Context gathered: 2026-05-27*
