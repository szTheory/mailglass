---
phase: 44
slug: async-adoption-closeout-reconciliation
researched: 2026-05-06
status: complete
confidence: high
posture: closeout-proof + bookkeeping reconciliation (mirror of Phase 43 for Phase 42)
---

# Phase 44 Research: Async Adoption Closeout Reconciliation

**Researched:** 2026-05-06
**Domain:** milestone closeout / verification-evidence recovery / requirement reconciliation
**Confidence:** HIGH (existing test surface already proves the behavior; the work is artifact generation and bookkeeping, mirroring the just-completed Phase 43 pattern almost exactly)

## Summary

Phase 42 shipped real product behavior — durable Oban-backed inbound execution, bounded `Task.Supervisor` fallback, one canonical adoption lane in the README, and root-level release/publish proof for `mailglass_inbound`. The `v1.1` milestone audit (`v1.1-MILESTONE-AUDIT.md`) confirms the implementation is present and the proof lanes pass; what is missing is a phase-level execution `42-VERIFICATION.md` and matching central bookkeeping in `REQUIREMENTS.md`. As a result, `EXEC-01`, `EXEC-02`, and `ADOPT-01` are still marked Pending against Phase 44 even though the tests already named in `42-VALIDATION.md` cover them.

Phase 43 just resolved the same pattern for Phases 39–41 (seven requirements, three recovered verification artifacts, one bookkeeping reconciliation). Phase 44 must close the equivalent loop for Phase 42 (three requirements, one recovered verification artifact, one bookkeeping reconciliation) and then re-run the milestone audit so v1.1 can be archived without contradictory source-of-truth documents.

**Primary recommendation:** Two-plan phase. Plan 44-01 creates `.planning/phases/42-async-execution-and-adopter-proof/42-VERIFICATION.md` from re-run proof lanes named in `42-VALIDATION.md` and ties each lane to `EXEC-01`, `EXEC-02`, or `ADOPT-01`. Plan 44-02 reconciles `REQUIREMENTS.md` and `STATE.md`, then re-runs the milestone audit and produces `v1.1-MILESTONE-AUDIT-CLOSEOUT.md` proving the gaps closed. `ROADMAP.md` only changes if it would otherwise stay misleading after the recovery (it currently won't — see Bookkeeping Reconciliation below). No product code changes. No widening of the `mailglass_inbound` public surface.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-44-01:** Phase 44 is a closeout-proof and bookkeeping-reconciliation phase, not a runtime feature phase.
- **D-44-02:** Closeout target is narrow and concrete: create execution-level `42-VERIFICATION.md`, reconcile `EXEC-01`/`EXEC-02`/`ADOPT-01` in `REQUIREMENTS.md`, align state/roadmap only where they would otherwise preserve contradiction, rerun milestone audit/closeout proof.
- **D-44-03:** No "bookkeeping only" repair that skips behavioral proof. The phase must tie shipped behavior back to requirements.
- **D-44-04:** Strict on shipped package behavior and published contract; not strict on full host-app matrix simulation.
- **D-44-05:** Canonical proof surface is the existing package-boundary evidence set:
  - `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs`
  - `mailglass_inbound/test/mailglass_inbound/worker_test.exs`
  - `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
  - `test/mailglass/stability_contract_test.exs`
  - release/publish proof already wired at the repo root.
- **D-44-06:** The new execution verification artifact must map those lanes directly to `EXEC-01`, `EXEC-02`, and `ADOPT-01`.
- **D-44-07:** Do NOT raise the closeout bar to "prove every adopter wiring permutation in a real host app." That widens public support surface — different phase.
- **D-44-08:** Internal worker, queue, retry, and replay machinery stays internal — verification confirms behavior without widening the stable surface.
- **D-44-09:** Bookkeeping repair stays as narrow as possible while removing contradictions.
- **D-44-10:** Minimum bookkeeping set:
  - `.planning/REQUIREMENTS.md`
  - `.planning/STATE.md` if it claims completion while requirements stay pending or verification missing
  - `.planning/ROADMAP.md` only if Phase 44 or milestone status would remain misleading
  - new Phase 44 planning artifacts needed for audit re-run
- **D-44-11:** Explicitly out of scope: revisiting Phase 39–41 beyond Phase 43's work, live `v1.0` publish closeout, Phase 35 Nyquist residue, non-blocking boundary-warning debt, release-process redesign, new product/docs surface unrelated to the async/adoption closeout chain.
- **D-44-12..15:** Recommendation-first posture. Synthesize one coherent recommendation per gray area; alternatives only as overrides. Escalate ONLY when the choice would materially change: stable public API/router DSL/config schema/install contract/docs-promised behavior; tenant boundary/security/retention/replay/audit truth semantics; permanent maintainer burden through new dep/subsystem/lane; user-visible default workflow the project owner is especially likely to care about. Otherwise decide and proceed.

### Claude's Discretion

- Exact wording and section layout for `42-VERIFICATION.md`, as long as it is execution-level rather than plan-level.
- Exact command grouping for the Phase 42 proof lanes, as long as the artifact ties concrete commands back to the three requirements honestly.
- Exact bookkeeping note wording in roadmap/state/requirements reconciliation, as long as the repaired source-of-truth chain is explicit and non-marketing.
- Whether the workflow-posture preference is reinforced only in this phase context or also in project-level methodology artifacts.

### Deferred Ideas (OUT OF SCOPE)

- Canonical host-app fixture or matrix proof for inbound setup permutations.
- Public replay API or operator surface for inbound recovery.
- Broader project-wide GSD workflow changes outside local planning artifacts.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `EXEC-01` | Adopter can execute inbound routing asynchronously through Oban when Oban is installed and configured. | Already proven by `async_execution_test.exs` (oban dispatch path) + `worker_test.exs` (worker job-arg load + outcome mapping) + `MailglassInbound.OptionalDeps.Oban` runtime gateway + `MailglassInbound.Execution.Worker` (compiled when Oban present, queue `:mailglass_inbound`, max_attempts 20, unique[period: 3600]). The recovery report must spot-check those lanes and tie them to `EXEC-01`. |
| `EXEC-02` | Adopter can execute the same logical mailbox contract through a supported bounded fallback when Oban is absent. | Already proven by `async_execution_test.exs` (Task.Supervisor fallback path returns `mode: :task_supervisor, durability: :best_effort`) + once-per-node fallback warning test (`maybe_warn_fallback_mode/1`) + `MailglassInbound.Application` supervising `MailglassInbound.TaskSupervisor`. The recovery report must spot-check those lanes and tie them to `EXEC-02`. |
| `ADOPT-01` | Adopter can install, configure, test, and support the core inbound slice through honest first-party docs and verification lanes. | Already proven by `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (11 assertions covering README install lane, api_stability inventory, postmark/sendgrid guides, operator-trust doc, root-verification wiring) + `test/mailglass/stability_contract_test.exs` (root proof asserting `mailglass_inbound` participates in `verify.stability_contract`, `mailglass.docs.check`, `mailglass.publish.check`, release-please linked-version manifest, committed publish allowlist). The recovery report must spot-check both lanes and tie them to `ADOPT-01`. |

## Project Constraints (from CLAUDE.md)

These directives apply to this phase even though it is bookkeeping/verification work:

- Use `Mailglass.Config` for any config reads (N/A — no code changes expected).
- Never UPDATE/DELETE `mailglass_events` rows (N/A — no DB writes).
- Never put PII in telemetry metadata (N/A — no telemetry handlers added).
- Never call `Swoosh.Mailer.deliver/1` directly inside library code (N/A — no library code).
- Conventional Commits enforced. Use `docs(state):` prefix for `.planning/STATE.md` updates so CI path filters skip them.
- All commits will be docs/planning-artifact only — confirm `commit_docs` flag in `.planning/config.json` before committing if the planner uses it.
- `MIT` license is locked across all sibling packages.
- Bleeding-edge floor (Elixir 1.18+ / OTP 27+ / Phoenix 1.8+) — irrelevant for this phase but note that `mix test --warnings-as-errors` is the canonical proof posture and must stay green.

## Architectural Responsibility Map

This is not a feature phase, so the "tier" axis is "artifact tier" rather than "runtime tier":

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Execution-level proof for `EXEC-01`/`EXEC-02` | Phase planning artifacts (`42-VERIFICATION.md`) | Package test suite (`mailglass_inbound/test/`) | Tests already prove the behavior; the missing artifact is the verification *report* that maps tests → requirements. |
| Adopter-docs proof for `ADOPT-01` | Phase planning artifacts (`42-VERIFICATION.md`) | Package docs-contract test + root release/publish proof | Same shape: behavior is proven; the missing artifact is the report. |
| Requirement traceability | Central bookkeeping (`.planning/REQUIREMENTS.md`) | — | Status flips happen only after evidence exists, mirroring Phase 43's discipline. |
| Milestone closeout truth | Central bookkeeping (`.planning/STATE.md`) + new `.planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md` | `.planning/ROADMAP.md` (only if it would otherwise stay misleading) | The audit ran as `gaps_found`; closeout truth needs a re-run with `passed` status to retire the audit artifact's blocker call. |

## Standard Stack

No new stack. The phase reuses what is already wired:

| Component | Role | Status |
|-----------|------|--------|
| ExUnit + `--warnings-as-errors` | Re-run proof lanes for spot-checks | Green per Phase 42 summaries; expected to stay green |
| Phase 43 verification-report shape | Document template | Proven shape from `39-VERIFICATION.md` and `41-VERIFICATION.md` (recovered) |
| `mix verify.stability_contract` | Repo-root semantic verification including `mailglass_inbound` docs lane | Green (per `42-03-SUMMARY.md` and audit's "Root semantic verification did pass" note) |
| `mix verify.docs.contract.inbound` | Targeted docs-contract lane for inbound | Green (alias defined in root `mix.exs:262-264`) |
| `actionlint .github/workflows/release-please.yml` | Release automation lint | Green per `42-03-SUMMARY.md` |
| `mix mailglass.publish.check --package mailglass_inbound --keep` | Sibling package publish-truth check | Green per `42-03-SUMMARY.md` |

## Phase 42 Shipped Proof Surface — Mapped to Requirements

This is the load-bearing section of this research. The recommended `42-VERIFICATION.md` shape comes directly from this map.

### EXEC-01: Durable Oban-backed async dispatch

| Proof Lane | Re-run Command | What It Proves | Source |
|------------|----------------|----------------|--------|
| Async dispatch through internal Oban worker without leaking `%Oban.Job{}` publicly | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs --warnings-as-errors` | `Execution.dispatch/2` returns `{:ok, %{status: :queued, mode: :oban}}` when the gateway runner is `:oban`; only stable internal worker name + tenant-keyed job args travel through the seam | `42-01-SUMMARY.md` |
| Worker arg load + result mapping (no public job-shape leakage) | `cd mailglass_inbound && mix test test/mailglass_inbound/worker_test.exs --warnings-as-errors` | `MailglassInbound.Execution.Worker.perform/2` restores tenancy-safe args, returns `:ok` on success and `{:error, failure}` on mailbox failure for retryable Oban behavior | `42-01-SUMMARY.md` |
| Combined dispatch + worker proof | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs --warnings-as-errors` | Both surfaces remain green together; named in `42-VALIDATION.md` as the canonical EXEC-01 lane | `42-VALIDATION.md` task `42-01-01` |

### EXEC-02: Bounded `Task.Supervisor` fallback

| Proof Lane | Re-run Command | What It Proves | Source |
|------------|----------------|----------------|--------|
| Fallback dispatch returns explicit `:best_effort` durability | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs --warnings-as-errors` (same lane, distinct test) | `Execution.dispatch/2` with `:task_supervisor` runner returns `{:ok, %{status: :queued, mode: :task_supervisor, durability: :best_effort}}` and runs only after persistence | `42-01-SUMMARY.md` |
| Once-per-node fallback warning is honest | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs --warnings-as-errors` (same lane, "fallback mode emits an honest warning once per node") | `MailglassInbound.Application.maybe_warn_fallback_mode/1` logs "best-effort", "Task.Supervisor", and "mailglass_inbound" exactly once via `:persistent_term` guard | `42-01-SUMMARY.md` |
| Post-persist (not inline) fallback dispatch from ingress | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | Fresh ingress dispatches asynchronously after persistence commits; never inline on the request path | `42-VALIDATION.md` task `42-01-02` |

### ADOPT-01: Honest first-party docs + verification lanes

| Proof Lane | Re-run Command | What It Proves | Source |
|------------|----------------|----------------|--------|
| Canonical adoption runbook + provider/stability/operator-trust drift guard | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | README ships one manual setup lane (deps, migrations, body-reader, router, provider mounts, async mode); api_stability.md inventories stable/internal/deferred surfaces; postmark/sendgrid guides describe verification + duplicate semantics; operator-trust doc keeps replay distinct from fresh receive; root verification wiring is asserted from the package side | `42-02-SUMMARY.md` |
| Replay docs do not pretend to be a fresh receive or public API | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors` | Same docs-contract lane combined with replay behavior to prove docs match runtime | `42-VALIDATION.md` task `42-02-02` |
| Root semantic verification includes `mailglass_inbound` | `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` | `mix.exs` `verify.stability_contract` alias runs inbound docs-contract test; `mailglass.docs.check` scans inbound README + api_stability + sendgrid_ingress; release-please manifest includes `mailglass_inbound`; `mailglass.publish.check` accepts `mailglass_inbound`; committed publish allowlist + summary exist | `42-03-SUMMARY.md` |
| Release automation lint | `actionlint .github/workflows/release-please.yml` | Sibling-package linked-version dep-pin sync step parses cleanly | `42-03-SUMMARY.md` |
| Inbound publish allowlist truth | `mix mailglass.publish.check --package mailglass_inbound --keep` | Real `MIX_PUBLISH=true mix hex.build --unpack` produces a tarball matching `.planning/publish/mailglass_inbound-files.expected` | `42-03-SUMMARY.md` |

**Single canonical full-bundle command** (recommended for the verification report's "Full proof bundle" spot-check):

```bash
cd mailglass_inbound && mix test \
  test/mailglass_inbound/async_execution_test.exs \
  test/mailglass_inbound/worker_test.exs \
  test/mailglass_inbound/docs_contract_test.exs \
  --warnings-as-errors \
&& cd .. && mix test test/mailglass/stability_contract_test.exs --warnings-as-errors \
&& actionlint .github/workflows/release-please.yml
```

This is the single command the report should run last and record the result of, mirroring what Phase 43's recovered reports did with their multi-lane bundles.

## Recommended `42-VERIFICATION.md` Structure

The recommended shape mirrors `39-VERIFICATION.md` and `41-VERIFICATION.md` (both recovered under Phase 43, both pass the audit's "execution evidence not plan-check" test, both passed `gsd-verify-work` patterns in this repo).

### Frontmatter

```yaml
---
phase: 42-async-execution-and-adopter-proof
verified: <UTC timestamp at execution time>
status: passed
score: 5/5 must-haves verified  # adjust to actual count of Observable Truths
overrides_applied: 0
human_verification: []
---
```

### Body sections (in order)

1. **Title + intro** — `# Phase 42: Async Execution And Adopter Proof Verification Report` + the phase goal restated + `Re-verification: Yes - recovered execution verification after milestone audit gap`.

2. **`## Goal Achievement`**.

3. **`### Observable Truths`** — Markdown table with five rows (recommended). The exact five truths the verifier should claim:
   1. Fresh persisted inbound work dispatches asynchronously through one shared `Execution.dispatch/2` seam, with `:oban` mode preferred when the gateway reports it.
   2. The fallback mode is `Task.Supervisor` only, returns `durability: :best_effort` explicitly, runs only after persistence, and emits an honest once-per-node warning.
   3. The internal Oban worker (`MailglassInbound.Execution.Worker`) loads tenancy-safe args, reuses `Execution.execute/2`, and maps mailbox failures into retryable Oban errors — without exposing `%Oban.Job{}` or queue names through the public contract.
   4. The shipped adoption docs ship one canonical manual setup lane and reject installer framing, replay-as-fresh-receive claims, public-replay-API claims, and any widening of the stable inbound surface.
   5. Repo-root semantic verification, release-please linked versions, and the committed sibling-package publish allowlist all explicitly include `mailglass_inbound`, so root proof fails closed if `mailglass_inbound` falls out of release truth.

4. **`### Required Artifacts`** — Table with rows for: `42-VALIDATION.md`, `42-01-SUMMARY.md`, `42-02-SUMMARY.md`, `42-03-SUMMARY.md`, `mailglass_inbound/lib/mailglass_inbound/execution.ex`, `.../execution/worker.ex`, `.../application.ex`, `.../optional_deps.ex`, `mailglass_inbound/README.md`, `mailglass_inbound/docs/api_stability.md`, `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs`, `.../worker_test.exs`, `.../docs_contract_test.exs`, `test/mailglass/stability_contract_test.exs`, `.planning/publish/mailglass_inbound-files.expected`, `.planning/publish/mailglass_inbound-publish-summary.json`. Each marked `✓ VERIFIED`.

5. **`### Key Link Verification`** — Four rows (one per Phase 42 summary plus the validation map):
   - `42-01-SUMMARY.md` → `42-VERIFICATION.md` via execution truth for `EXEC-01` and `EXEC-02`.
   - `42-02-SUMMARY.md` → `42-VERIFICATION.md` via canonical adoption + operator-trust truth for `ADOPT-01`.
   - `42-03-SUMMARY.md` → `42-VERIFICATION.md` via root release-proof + publish-allowlist truth for `ADOPT-01`.
   - `42-VALIDATION.md` → `42-VERIFICATION.md` via Nyquist proof lanes becoming behavioral spot-checks.

6. **`### Behavioral Spot-Checks`** — Markdown table with one row per re-run command from the proof-surface map above, with concrete `N tests, 0 failures` results recorded inline. Use the exact six commands listed in the proof-surface tables (three for EXEC-01/02 lanes, three for ADOPT-01 lanes including root + actionlint + publish.check).

7. **`### Requirements Coverage`** — Three-row table:
   - `EXEC-01` | `42-01` | `Adopter can execute inbound routing asynchronously through Oban when Oban is installed and configured.` | `✓ SATISFIED` | evidence pointing to async_execution_test + worker_test re-run results.
   - `EXEC-02` | `42-01` | `Adopter can execute the same logical mailbox contract through a supported bounded fallback when Oban is absent.` | `✓ SATISFIED` | evidence pointing to async_execution_test fallback + warning lanes + ingress combined lane.
   - `ADOPT-01` | `42-02`, `42-03` | `Adopter can install, configure, test, and support the core inbound slice through honest first-party docs and verification lanes.` | `✓ SATISFIED` | evidence pointing to docs_contract_test + stability_contract_test + actionlint + publish.check.

8. **`### Anti-Patterns Found`** — One row mirroring the Phase 43 reports: the `v1.1-MILESTONE-AUDIT.md` entry for Phase 42 was missing-execution-verification-not-missing-behavior; severity Warning; impact "central bookkeeping closed by Plan 44-02".

9. **`### Gaps Summary`** — Short prose: "No Phase 42 behavior gap remains. The prior audit blocker was missing execution verification rather than missing product behavior. This recovered report closes the Phase 42 proof chain locally; central requirement bookkeeping is reconciled by Plan 44-02."

This shape is mechanical to verify — every section header has a counterpart in `39-VERIFICATION.md` and `41-VERIFICATION.md` and `35-VERIFICATION.md`/`37-VERIFICATION.md` (the original Phase 43 references).

## Bookkeeping Reconciliation Sequence

The minimum-set per D-44-09..11. Each item below is the answer to "Would this file remain misleading after Phase 44 if we did not touch it?"

### `.planning/REQUIREMENTS.md` — REQUIRED

Current state (from the current file):

```
| EXEC-01 | Phase 44 | Pending |
| EXEC-02 | Phase 44 | Pending |
| ADOPT-01 | Phase 44 | Pending |
```

Also: lines 26–28 still show `[ ] EXEC-01`, `[ ] EXEC-02`, `[ ] ADOPT-01` checkboxes in the requirements list itself.

Recommended changes (after `42-VERIFICATION.md` exists):

1. Flip the three traceability rows from `Pending` to `Satisfied` (matching the verb form Phase 43 used for its seven recovered rows).
2. Flip the `[ ]` to `[x]` in the requirements list at lines 26–28.
3. Replace the existing trailing note ("Phase 43 reconciles bookkeeping only: these seven requirements were implemented in Phases 39 to 41 and recovered under Phase 43 by restoring execution verification artifacts.") with a *combined* note covering both Phase 43 and Phase 44 recovery, e.g.:

   > Phase 43 reconciles bookkeeping for the seven requirements implemented in Phases 39 to 41 by restoring execution verification artifacts. Phase 44 reconciles bookkeeping for `EXEC-01`, `EXEC-02`, and `ADOPT-01`, which were implemented in Phase 42 and recovered under Phase 44 by creating an execution-level `42-VERIFICATION.md`.

This is the only file in the bookkeeping set that *must* change.

### `.planning/STATE.md` — REQUIRED (light touch)

Current state contradicts the audit:

- frontmatter says `status: phase 42 complete; v1.1 ready for milestone closeout`
- `progress.percent: 100`
- "Current Position" says "v1.1 is ready for milestone closeout"

But the audit says `gaps_found` and `REQUIREMENTS.md` still has three `Pending` rows. After Plan 44-02, the audit will say `passed`.

Recommended changes after audit re-runs green:

1. Bump `last_updated` and `last_activity` to the Phase 44 closeout timestamp.
2. Add one bullet under "Session Continuity" stating "Phase 44 closed the v1.1 audit gap by adding `42-VERIFICATION.md` and reconciling `EXEC-01`/`EXEC-02`/`ADOPT-01` traceability; v1.1 milestone audit re-ran with `status: passed`."
3. Update progress to reflect 6 phases (39–44) rather than the current 4-phase count, and 14 plans (12 product + 2 closeout, assuming the recommended 2-plan split for Phase 44; adjust to 15 if the planner adds a third plan for audit re-run).
4. Update "Current Position" header from "Phase 42 complete" to "Phase 44 complete" and "Status" line accordingly.

Use the `docs(state):` commit prefix per CLAUDE.md so CI path filters skip.

### `.planning/ROADMAP.md` — CONDITIONAL (likely yes, narrowly)

Current state:

- Line 15 says "🚧 v1.1 ... (active; audit gap closure phases added 2026-05-06)"
- Line 19 says "Status: Active. Product implementation phases 39-42 are complete; audit gap closure phases 43-44 are next."
- Phase 43 entry shows `Status: Pending` and `0 plans` despite Phase 43 actually being complete (per `43-*-SUMMARY.md` files).
- Phase 44 entry shows `Status: Pending` and `0 plans`.

The Phase 43 status drift is technically out of Phase 44 scope per D-44-11 ("revisiting Phase 39-41 recovery beyond Phase 43's completed work"). But Phase 43's own status is its own line — *not* a Phase 39–41 revisit — and leaving it `Pending` would visibly contradict the v1.1 closeout claim. Recommendation: update Phase 43's roadmap row only (status → Complete, plan count → 3) as a *consequence* of the Phase 43 work that just shipped, plus update Phase 44's row when Phase 44 itself closes.

Recommended changes at end of Plan 44-02:

1. Phase 43 row: status `Pending` → `Complete (2026-05-06)`; plans `0` → `3` with the three plan titles inline (mirror the Phase 39–42 entry shape).
2. Phase 44 row: status `Pending` → `Complete (<date>)`; plans `0` → actual plan count with titles.
3. Line 15 milestone status from "🚧 ... (active; audit gap closure phases added 2026-05-06)" → "✅ v1.1 Inbound Core Slice — Phases 39–44 (shipped <date>)" — *only after* the milestone audit re-runs `passed`. If the planner wants to be ultra-conservative, leave milestone-level marking to a separate `/gsd-complete-milestone v1.1` invocation post-Phase-44; doing so is honest, since "milestone shipped" is a separate concept from "Phase 44 closeout-proof done."

If the planner prefers, the milestone-level "shipped" marking can stay deferred to `gsd-complete-milestone`; the Phase 43/44 row updates are still required to avoid contradiction.

### New artifact: `.planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md` — REQUIRED

The current `v1.1-MILESTONE-AUDIT.md` records `status: gaps_found` and lists 10 partial requirements. Re-running `$gsd-audit-milestone v1.1` after Phase 44 should produce a fresh artifact that records `status: passed`. Two options:

- **Option A (recommended):** Write a new `v1.1-MILESTONE-AUDIT-CLOSEOUT.md` that records the re-run and links back to the original `v1.1-MILESTONE-AUDIT.md` for historical context. This preserves the original audit as historical truth (mirrors how Phase 43 left the original audit untouched).
- **Option B:** Overwrite `v1.1-MILESTONE-AUDIT.md` with the passing run.

A is preferred because the audit artifact is forensic evidence of what gap was found and what closed it. Overwriting would erase the contradictions that motivated the gap-closure phases.

Either way, the closeout artifact must:

1. Record the `$gsd-audit-milestone v1.1` re-run result.
2. Cite the recovered `42-VERIFICATION.md` and the reconciled `REQUIREMENTS.md` rows as the gap-closure evidence.
3. Note that Phase 43 closed the seven Phase 39–41 requirements and Phase 44 closed the three Phase 42 requirements.
4. Confirm that root verification (`mix test test/mailglass/stability_contract_test.exs --warnings-as-errors`) still passes.
5. List any *accepted* residual debt for v1.1 (matching the v1.0 closeout pattern). Likely accepted residue: none material (per audit's `tech_debt: Environment` note about workspace dep-fetch — the recovery itself fixes that with `mix deps.get`, so it should not survive into closeout).

## Recommended Plan Split

**Two plans. Wave-sequenced (44-02 depends on 44-01) per Phase 43 precedent.**

### Plan 44-01: Recover Phase 42 execution verification

- **Wave:** 1
- **Depends on:** none
- **Files modified:** `.planning/phases/42-async-execution-and-adopter-proof/42-VERIFICATION.md` (created)
- **Requirements addressed:** `EXEC-01`, `EXEC-02`, `ADOPT-01`
- **Tasks:**
  1. Re-run the six proof-surface commands listed in the EXEC-01/EXEC-02/ADOPT-01 tables above. Record exact pass results inline.
  2. Write `42-VERIFICATION.md` using the recommended structure (frontmatter, Goal Achievement, Observable Truths × 5, Required Artifacts, Key Link Verification, Behavioral Spot-Checks, Requirements Coverage marking all three `✓ SATISFIED`, Anti-Patterns Found × 1, Gaps Summary).
  3. Acceptance: `rg -n "EXEC-01|EXEC-02|ADOPT-01|✓ SATISFIED" .planning/phases/42-async-execution-and-adopter-proof/42-VERIFICATION.md` returns rows for all three requirements; `rg -n "Behavioral Spot-Checks" .planning/phases/42-async-execution-and-adopter-proof/42-VERIFICATION.md` finds the section.

### Plan 44-02: Reconcile bookkeeping and re-run milestone audit

- **Wave:** 2
- **Depends on:** `44-01`
- **Files modified:** `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` (Phase 43 + 44 row status only), `.planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md` (created)
- **Requirements addressed:** `EXEC-01`, `EXEC-02`, `ADOPT-01` (central bookkeeping flip)
- **Tasks:**
  1. Flip `EXEC-01`/`EXEC-02`/`ADOPT-01` rows in `REQUIREMENTS.md` from `Pending` → `Satisfied` and the `[ ]` → `[x]` in the requirement list. Update the trailing note to cover both Phase 43 and Phase 44 recovery.
  2. Update `STATE.md` per the Light Touch list above. Use `docs(state):` commit prefix.
  3. Update `ROADMAP.md` Phase 43 row (status `Pending` → `Complete`, plan count `0` → `3`) and Phase 44 row.
  4. Run `$gsd-audit-milestone v1.1` (or equivalent — the orchestrator should know which slash command produces the audit). Capture output as `.planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md`. Verify `status: passed`.
  5. Re-run the canonical full-bundle command from this research doc as a final sanity check and record the result in the closeout artifact.
  6. Acceptance: `! rg -n "\\| (EXEC-01|EXEC-02|ADOPT-01) \\| Phase 44 \\| Pending \\|" .planning/REQUIREMENTS.md` (none remain); `rg -n "status: passed" .planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md` (passes); `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` (passes).

**Why two plans, not three?** Phase 43 split into three plans because each of the seven recovered requirements lived in a distinct already-shipped phase (39, 40, 41) and the Phase 41 recovery additionally needed a new `41-VALIDATION.md`. Phase 44's three requirements all live in one already-shipped phase (Phase 42) which already has `42-VALIDATION.md`. Splitting Plan 44-01 into "recover EXEC" and "recover ADOPT" sub-plans would add planning overhead with no isolation benefit — the same proof commands and the same single recovered file are touched either way. Two plans is the honest minimum.

**Why not one plan?** The discipline of "central bookkeeping flips only after the recovered verification artifact exists" — proven valuable in Phase 43 — needs to survive a worker restart or partial-execution failure. Splitting at the verification-artifact / bookkeeping boundary preserves that invariant cheaply.

## Audit Re-run + Closeout Proof Step

After Plan 44-02:

1. Run `$gsd-audit-milestone v1.1` (orchestrator decides exact slash-command). The expected `gaps` array is empty and `status: passed`.
2. Capture as `.planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md` per "New artifact" guidance above. Do NOT overwrite the original `v1.1-MILESTONE-AUDIT.md`.
3. Run the canonical full-bundle command one more time and paste exact `N tests, 0 failures` results into the closeout artifact's "Behavioral re-confirmation" section.
4. The milestone is then ready for `$gsd-complete-milestone v1.1` whenever the project owner wants to archive it. That call is *not* in Phase 44 scope per D-44-11 (live `v1.0` publish closeout was deferred; v1.1 archival is a separate operation that may itself want to be a separate explicit user action).

## Validation Architecture

Per Nyquist conventions (`workflow.nyquist_validation` is enabled in this project — Phase 42's own VALIDATION.md exists and uses this format).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Mix tasks + grep/file verification + actionlint |
| Config file | `mailglass_inbound/mix.exs`, `mix.exs`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` |
| Quick run command | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| Full suite command | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors && cd .. && mix test test/mailglass/stability_contract_test.exs --warnings-as-errors && actionlint .github/workflows/release-please.yml` |
| Estimated runtime | ~20–40s task-local / ~120–180s full phase scope |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXEC-01 | Durable Oban-backed dispatch via internal worker | unit + integration | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/worker_test.exs --warnings-as-errors` | ✅ |
| EXEC-02 | Bounded `Task.Supervisor` fallback with explicit best-effort warning | unit + plug integration | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ✅ |
| ADOPT-01 | Honest adoption docs + drift guard + root release proof | docs contract + root contract + workflow lint | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors && cd .. && mix test test/mailglass/stability_contract_test.exs --warnings-as-errors && actionlint .github/workflows/release-please.yml` | ✅ |
| (closeout) | Recovered verification + bookkeeping reconciliation re-passes the milestone audit | grep / artifact check + audit re-run | `! rg -n "\\| (EXEC-01\|EXEC-02\|ADOPT-01) \\| Phase 44 \\| Pending \\|" .planning/REQUIREMENTS.md && rg -n "status: passed" .planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md` | ⬜ task creates |

### Sampling Rate

- **Per task commit:** quick run command above (~20–40s).
- **Per wave merge:** full suite command above (~120–180s).
- **Phase gate:** Full suite green + the closeout grep/artifact check + audit re-run before `/gsd-verify-work`.

### Wave 0 Gaps

None — all required test infrastructure exists. The Phase 42 work already created `async_execution_test.exs`, `worker_test.exs`, the extended `docs_contract_test.exs`, the root `stability_contract_test.exs` assertions, and the publish allowlist. Phase 44 needs zero new test files. The "files this phase creates" are planning artifacts only: `42-VERIFICATION.md`, `v1.1-MILESTONE-AUDIT-CLOSEOUT.md`, and Phase 44's own SUMMARY files.

### Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Recovered verification report uses execution-evidence language, not plan-check language | all | This is partly a document-truth judgment, mirroring Phase 43's manual-only sign-off | Compare `42-VERIFICATION.md` against `39-VERIFICATION.md` and `41-VERIFICATION.md`; reject wording such as `planned`, `will`, `Plan-Check Findings`, or `passes plan checker`. |
| Closeout artifact records the actual audit re-run result, not a paraphrase | (closeout) | Audit truth is forensic | Confirm the re-run command was executed and the output (or a faithful summary) is captured in `v1.1-MILESTONE-AUDIT-CLOSEOUT.md`. |

## Closeout-Phase Risks and Mitigations

These are the landmines specific to bookkeeping-recovery phases. Each comes with the recommended mitigation, all of which are verifiable mechanically.

### Risk 1: Accidentally widening the public surface in `42-VERIFICATION.md`

**What goes wrong:** The verification report is tempted to enumerate `MailglassInbound.Execution.Worker.perform/1` arguments, queue names, retry tuning, or `%Oban.Job{}` shape as "stable" because the tests reference them. This contradicts D-44-08 and `api_stability.md` which explicitly mark workers, queue names, retry tuning, and worker args as `internal`.

**Mitigation:** Use exactly the language already in `api_stability.md` — `internal` surfaces stay internal; the verification report only confirms behavioral truth, not surface promises. The Observable Truth wording recommended above ("without exposing `%Oban.Job{}` or queue names through the public contract") is the load-bearing phrase. Add a docs-contract assertion-style negative check in the verification report itself (e.g., "no `%Oban.Job{}` shape promise was added to the docs by this report").

**Mechanical guard:** Re-run `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` after writing `42-VERIFICATION.md` — the existing test asserts `refute readme =~ "%Oban.Job{}"` and `refute stability =~ "stable public replay API"`. If those still pass, the verification report did not accidentally pollute the docs.

### Risk 2: Claiming proof the test suite does not actually demonstrate

**What goes wrong:** Writing "EXEC-01 is satisfied because Oban executes durably across node restarts" without a test that proves crash-recovery semantics. The shipped tests prove dispatch + worker arg loading + outcome mapping; they do NOT prove durable enqueue actually survives node loss (that's a real Oban property and a host-app concern).

**Mitigation:** Phrase Observable Truths in the report exactly as the tests prove them — "fresh persisted inbound work dispatches asynchronously through one shared seam, with `:oban` mode preferred when the gateway reports it" is honest. "Durably survives node loss" would be a claim that depends on Oban's own guarantees, not on `mailglass_inbound` test surface, and per D-44-04 / D-44-07 we are not running host-app matrix simulation.

**Mechanical guard:** Each Observable Truth row in the report must cite a specific test file. The recovered Phase 39/40/41 reports follow this pattern; the verifier should not write a row that cannot point to a re-run command in Behavioral Spot-Checks.

### Risk 3: Leaving STATE.md / ROADMAP.md / REQUIREMENTS.md drift

**What goes wrong:** The verification artifact is created but the central bookkeeping update gets dropped (e.g., the executor restarts mid-Plan 44-02 and only does the `REQUIREMENTS.md` flip, not the `STATE.md` `last_activity` update, not the `ROADMAP.md` Phase 43/44 row update). The audit re-runs `passed` but `STATE.md` still says "Phase 42 complete".

**Mitigation:** Plan 44-02 acceptance criteria must include grep checks against all three files. Specifically:
- `! rg -n "\\| (EXEC-01\|EXEC-02\|ADOPT-01) \\| Phase 44 \\| Pending \\|" .planning/REQUIREMENTS.md`
- `rg -n "Phase 44" .planning/STATE.md` returns updated content
- `rg -n "Phase 43:.*Complete" .planning/ROADMAP.md` (or equivalent) confirms Phase 43 row update

The Phase 43 plan (43-03) used this exact pattern successfully — see its `<verify>` block for the model.

### Risk 4: Re-introducing the original Phase 41 mistake (writing a plan-check report instead of an execution-evidence report)

**What goes wrong:** The verifier writes "All tasks for plan 42-01 passed plan checker" or "Phase 42 was correctly planned" instead of "running `cd mailglass_inbound && mix test ...` produced `N tests, 0 failures`." The audit will reject this exactly the way it rejected the original `41-VERIFICATION.md`.

**Mitigation:** Borrow the Phase 43 manual-only check verbatim — "Compare the recovered reports against `35-VERIFICATION.md` and `37-VERIFICATION.md`; reject wording such as `planned`, `will`, or `passes checker` when describing executed Phase 42 behavior." Encode this as a grep-style negative check in Plan 44-01's acceptance criteria: `! rg -n "passes plan checker|✓ PLANNED|Plan-Check Findings|will execute" .planning/phases/42-async-execution-and-adopter-proof/42-VERIFICATION.md`.

### Risk 5: Pulling Phase 39–41 scope back into Phase 44

**What goes wrong:** While reviewing `REQUIREMENTS.md` the verifier notices a small inconsistency in one of the Phase 43 recovered files and "fixes it," dragging Phase 43-completed work into Phase 44 commits. This violates D-44-11 ("revisiting Phase 39-41 recovery beyond Phase 43's completed work").

**Mitigation:** Plan 44-02 task acceptance criteria must explicitly enumerate which files are touched (`REQUIREMENTS.md`, `STATE.md`, `ROADMAP.md` Phase 43+44 rows only, new closeout artifact). Any other file modified during Plan 44-02 is a deviation that requires a planner re-spawn or an explicit deviation note. The Phase 43 plan-03 pattern named the seven specific requirement IDs in scope — Phase 44's plan-02 should name the three specific requirement IDs (`EXEC-01`/`EXEC-02`/`ADOPT-01`) and explicitly say "Do not touch the seven Phase 43 requirement rows."

### Risk 6: Audit re-run produces fresh `gaps_found` for an unrelated v1.1 issue we did not anticipate

**What goes wrong:** The original audit had a `tech_debt.Environment` note ("mailglass_inbound test suite could not be re-run in this workspace because package dependencies were not fetched locally"). Phase 43's `mix deps.get` resolved that. But the re-run might surface fresh issues — e.g., `41-VALIDATION.md` was created during Phase 43 but with a backdated `created: 2026-05-06` date that an audit-tool freshness check might flag.

**Mitigation:** Plan 44-02 should treat the audit re-run as a *verification step*, not a guaranteed pass. If the re-run surfaces a new gap that is genuinely Phase 44 in scope (i.e., it relates to `EXEC-01`/`EXEC-02`/`ADOPT-01`), close it. If it surfaces a genuinely unrelated issue, document it in the closeout artifact's "Accepted residue / surfaced issues" section and either close it inline (if trivial — e.g., timestamp normalization) or escalate to the user (if it would materially change milestone scope per D-44-14). The latter is the rare case where escalation is warranted.

## State of the Art

Not relevant for this phase. No new framework, library, or pattern is being introduced. The state of the art is "what Phase 43 just did."

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact `$gsd-audit-milestone v1.1` slash-command syntax is what the orchestrator expects to invoke. | Audit Re-run + Closeout Proof Step | Low — the orchestrator can substitute the actual command. The substantive work (running the audit and capturing the result) is invariant. |
| A2 | The two-plan split (verification + bookkeeping/audit) is preferable to a one-plan or three-plan split. | Recommended Plan Split | Low — the planner can override based on its own constraints. Phase 43 used three plans for seven requirements across three phases; two plans for three requirements in one phase is the proportional minimum. |
| A3 | `.planning/v1.1-MILESTONE-AUDIT-CLOSEOUT.md` is the right name/location for the closeout artifact. | Bookkeeping Reconciliation Sequence + Audit Re-run | Low — the planner can rename. The substance (do not overwrite the original audit; record the re-run elsewhere) is what matters. |
| A4 | Updating Phase 43's roadmap row to `Complete` is in scope for Phase 44 (treating it as a Phase-43-status fact, not a Phase-39-41 revisit). | Bookkeeping Reconciliation Sequence — ROADMAP.md | Low — if the planner judges this out of scope, the alternative is to leave Phase 43's row as-is and accept a small visible contradiction (Phase 43 is `Pending` in roadmap but its summaries exist). The contradiction is easily noticed, so updating is the cleaner choice. |

**Note:** None of these assumptions trigger D-44-14 escalation criteria. They are routine planning details. Per D-44-15, the agent should decide and proceed.

## Open Questions

None material to planning. The phase is highly constrained by:
- The Phase 43 precedent (mechanical pattern to mirror)
- The existing test suite (proof commands already named in `42-VALIDATION.md`)
- The CONTEXT.md decisions (closeout-proof, narrow bookkeeping, no surface widening)

If the orchestrator wants to be paranoid, the only meaningful pre-execution check is: re-read `42-VALIDATION.md` to confirm its `Per-Task Verification Map` still names the same six commands listed in the proof-surface tables above. The validation map was created during Phase 42 itself, so it is the source of truth that the verification report should mirror.

## Sources

### Primary (HIGH confidence)
- `.planning/phases/42-async-execution-and-adopter-proof/42-VALIDATION.md` — canonical proof-lane map for Phase 42, named the six commands the recovery report must spot-check.
- `.planning/phases/42-async-execution-and-adopter-proof/42-01-SUMMARY.md` / `42-02-SUMMARY.md` / `42-03-SUMMARY.md` — shipped summaries describing exactly what behavior was implemented for `EXEC-01`/`EXEC-02`/`ADOPT-01`.
- `.planning/v1.1-MILESTONE-AUDIT.md` — the audit failure that defines Phase 44's scope; its `requirements`/`integration`/`flows`/`tech_debt` arrays are the explicit gap list.
- `.planning/phases/43-execution-verification-recovery/43-RESEARCH.md` / `43-01-PLAN.md` / `43-02-PLAN.md` / `43-03-PLAN.md` / `43-VALIDATION.md` / `43-PATTERNS.md` / `43-01-SUMMARY.md` / `43-02-SUMMARY.md` / `43-03-SUMMARY.md` — the precedent. The Phase 44 plans should mirror this set's shape almost exactly, scaled to one phase (42) and three requirements.
- `.planning/phases/39-inbound-package-foundation/39-VERIFICATION.md` and `.planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md` — recovered verification reports from Phase 43 that pass the audit gate. Use these as the literal template for `42-VERIFICATION.md`.
- `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs` / `worker_test.exs` / `docs_contract_test.exs` — read in full; the proof lanes named in `42-VALIDATION.md` correspond to these files exactly.
- `test/mailglass/stability_contract_test.exs` — read in full; provides the root proof for ADOPT-01.
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` / `execution/worker.ex` / `application.ex` / `optional_deps.ex` — read in full; confirm the runtime behavior the verification report describes.
- `mailglass_inbound/README.md` and `mailglass_inbound/docs/api_stability.md` — read in full; confirm the "honest manual setup lane" and "stable/internal/deferred" claims the verification report cites.

### Secondary (MEDIUM confidence)
- `.planning/CLAUDE.md` and `.planning/PROJECT.md` — confirm engineering DNA constraints (D-07 Oban-optional, D-08 tracking off by default, D-22 narrow inbound milestone) which this phase honors by not widening surface.
- `.planning/METHODOLOGY.md` — recommendation-first / narrow-escalation posture which this research applies throughout.
- `mix.exs` lines 252–268 — confirm `verify.stability_contract` and `verify.docs.contract.inbound` aliases exist and include `mailglass_inbound`. This is the source of truth for the root proof commands.

### Tertiary (LOW confidence)
- None. Every claim in this research is sourced from a file in the repo or a test that has been re-run during Phase 43 (or earlier in Phase 42 itself).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new stack; reusing what already shipped.
- Architecture: HIGH — `42-VERIFICATION.md` shape is mechanically derivable from `39-VERIFICATION.md` and `41-VERIFICATION.md`.
- Pitfalls: HIGH — the same five risks burned Phase 43 and are well-documented; mitigations are mechanical grep checks.

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 (30 days; the only thing that would invalidate this research is a major change to `mailglass_inbound`'s test surface or `42-VALIDATION.md`'s named lanes — neither is expected during a closeout phase)

## RESEARCH COMPLETE
