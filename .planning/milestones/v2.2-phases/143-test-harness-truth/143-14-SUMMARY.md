---
phase: 143-test-harness-truth
plan: 14
implementation-commit: d01c6c38
subsystem: infra
tags: [github-actions, release-pipeline, publish-gate, hex, negative-control]

requires:
  - phase: 143-test-harness-truth (plans 01-13)
    provides: green Core Full Suite floor legs, anti-vacuity floors, and the publish gate on main
provides:
  - "Live negative proof that red Core Full Suite floor legs block the real Hex workflow before publish-core starts"
  - "Evidence-backed final gating decision with rationale, accepted gaps, and override discipline"
  - "A required-lane docs contract binding all seven decision sections and both live publish-path outcomes"
  - "HARNESS-04 completion evidence"
affects: [release-pipeline, publish-hex, phase-143-verification]

tech-stack:
  added: []
  patterns:
    - "Exercise irreversible delivery paths with already-published versions plus dry_run, then prove the dependency boundary from API job state"
    - "A check that cannot observe its subject fails visibly; raw ExUnit output is authoritative when an observer is known blind"

key-files:
  created:
    - .planning/phases/143-test-harness-truth/143-14-SUMMARY.md
  modified:
    - .planning/phases/143-test-harness-truth/143-GATING-DECISION.md
    - .planning/phases/143-test-harness-truth/143-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - test/scripts/mechanism_account_contract_test.exs

key-decisions:
  - "The real 2.3.0 release is stronger positive evidence than a throwaway dry-run: both gate jobs passed after the anti-recursion self-heal dispatched the missing workflows"
  - "The negative rehearsal used package=mailglass to minimize live surface while still exercising publish-core's dependency on gate-ci-green"
  - "CI and Advisory Matrix were dispatched before the negative tag so the gate read completed, causally isolated evidence rather than self-healing during the publish run"
  - "Formatter-ledger green is not cited as suite truth because SuiteTruthFormatter's module-boundary probes are known not to execute"

requirements-completed: [HARNESS-04]

coverage:
  - id: D1
    description: "A red floor leg blocks a Hex publish before the publish job executes"
    requirement: HARNESS-04
    verification:
      - kind: other
        ref: "publish-hex run 30654293410: gate-ci-green failure; publish-core completed/skipped with zero steps"
        status: pass
      - kind: other
        ref: "advisory-matrix run 30653683660: both floor jobs failed on the injected assertion"
        status: pass
    human_judgment: false
  - id: D2
    description: "A green floor pair permits the live publish path"
    requirement: HARNESS-04
    verification:
      - kind: other
        ref: "real 2.3.0 publish runs 30645265238 and 30645266725: gate-ci-green success; self-healed advisory run 30645896855"
        status: pass
    human_judgment: false
  - id: D3
    description: "The gating decision remains structurally complete and evidence-backed"
    requirement: HARNESS-04
    verification:
      - kind: unit
        ref: "mix test test/scripts/mechanism_account_contract_test.exs --warnings-as-errors — 13 tests, 0 failures"
        status: pass
      - kind: unit
        ref: "mix test test/scripts/ --warnings-as-errors — 114 tests, 0 failures"
        status: pass
    human_judgment: false

status: complete
---

# Phase 143 Plan 14: Publish-Path Rehearsal and Gating Decision — Summary

A durable closure record and contract landed in commit `d01c6c38`. The primary artifacts are
`.planning/phases/143-test-harness-truth/143-GATING-DECISION.md` and
`test/scripts/mechanism_account_contract_test.exs`.

A deliberately red Core Full Suite was observed blocking the real `publish-hex.yml` dependency chain:
`gate-ci-green` failed with both exact floor-lane names, while `publish-core` did not start.

## What happened

### Safety checkpoint

The maintainer authorised `run-rehearsal-pair`. Before any live dispatch:

- `mailglass 2.3.0`, `mailglass_admin 2.3.0`, and `mailglass_inbound 2.1.1` were confirmed live on Hex.
- No Release Please PR or active release train existed.
- Gate commit `34008138` was confirmed on `main` at `2ac5b278`.
- Every publish dispatch used `dry_run=true`; no version file changed.

### Positive path

The real 2.3.0 release supplied stronger evidence than the planned throwaway positive tag. Release runs
[`30645265238`](https://github.com/szTheory/mailglass/actions/runs/30645265238) and
[`30645266725`](https://github.com/szTheory/mailglass/actions/runs/30645266725) both passed
`gate-ci-green`. Because GitHub does not trigger workflows for the bot-raised release commit, the second
gate self-healed by dispatching both missing workflows on the release tag; the sibling gate reused them.
Advisory Matrix run [`30645896855`](https://github.com/szTheory/mailglass/actions/runs/30645896855)
passed both floor legs. The core run's later duplicate-publish race does not change the gate result;
2.3.0 is present in the Hex registry.

### Negative path

The rehearsal branch carried exactly one added file,
`test/gate_self_test/intentional_failure_test.exs`, at synthetic commit
`97e02b95739f5aef3f62284806ce037fa9b16cb7`. Its sole test assertion was:

```elixir
assert false, "intentional failure for gate-self-test"
```

User-token dispatches first established causal isolation:

- CI run [`30653681147`](https://github.com/szTheory/mailglass/actions/runs/30653681147) passed all seven
  required lanes. Only the pre-existing advisory Demo Browser Evidence job failed.
- Advisory Matrix run [`30653683660`](https://github.com/szTheory/mailglass/actions/runs/30653683660)
  failed both floor legs. Raw output in each schema reported `1629 tests, 1 failure`; the intentional
  assertion is present in both logs.

Only then was an annotated tag cut on the synthetic commit and the real publish workflow dispatched with
`package=mailglass`, `dry_run=true`, and the gate override disabled. In run
[`30654293410`](https://github.com/szTheory/mailglass/actions/runs/30654293410):

| Job | Result | Meaning |
|---|---|---|
| `prepublish-summary` | success | The selected package and already-published version were valid. |
| `gate-ci-green` | failure | The blocking message named both failed floor legs and Advisory Matrix run `30653683660`. |
| `publish-core` | completed / skipped, zero steps | The job did not start because its gate dependency failed. |
| `publish-admin`, `publish-inbound` | completed / skipped, zero steps | No sibling publish path started. |

The temporary local and remote tag and branch were deleted. Remote/local ref scans are empty, and the
synthetic test is reachable from no remaining ref. Hex still reports the same three versions.

## Decision record and contract

`143-GATING-DECISION.md` now has the final seven-section record: verdict, two-sided rationale, floor-only
scope, inbound exclusion, run evidence, accepted gaps, and override discipline. It corrects the stale
paired-release premise: inbound uses `{:mailglass, "~> 2.0"}`, not an exact core pin. It also records the
known SuiteTruthFormatter blind spot and relies on raw `mix test` output for this rehearsal.

The required `mix_task_tests` lane now binds the record's existence, all seven headings, explicit verdict,
positive and negative run URLs, and the `publish-core` did-not-start conclusion with a non-vacuous heading
parser. HARNESS-04 is complete in `REQUIREMENTS.md`.

## Deviations from plan

1. **Planned positive dry-run replaced by real-release evidence.** The 2.3.0 release occurred after the
   gate landed and exercised the exact irreversible path, including its anti-recursion self-heal. Repeating
   it with a throwaway positive tag would add risk without adding a stronger observable.
2. **Negative dispatch selected only `mailglass`.** The goal is to prove `publish-core` depends on the gate;
   selecting all packages would widen the live surface without improving that proof.
3. **CI and Advisory Matrix ran before the tag.** The gate therefore read completed evidence whose only
   required failure was the injected test, making the causal claim sharper and the publish dispatch shorter.
4. **A sixth accepted gap was promoted into the record.** The formatter's module-boundary observer is known
   blind, so a green ledger is explicitly not used as rehearsal evidence.

## Validation evidence

| Check | Result |
|---|---|
| Negative Advisory Matrix | both floor legs failed on the intentional assertion; raw `1629 tests, 1 failure` per schema |
| Negative publish workflow | gate failure; `publish-core` skipped with zero steps |
| `mix test test/scripts/mechanism_account_contract_test.exs --warnings-as-errors` | 13 tests, 0 failures |
| `mix test test/scripts/ --warnings-as-errors` | 114 tests, 0 failures |
| `mix credo --strict` | 3936 mods/funs, no issues |
| `mix format --check-formatted` | clean |
| `git diff --check` | clean |
| Rehearsal refs | absent locally and remotely |
| Package version diffs | none |

## Self-check: PASSED

- Commit `d01c6c38` exists and contains the decision record, requirement closure, validation evidence, and
  non-vacuous docs contract.
- The rehearsal run URLs and exact job states remain available in GitHub Actions.
- No temporary synthetic-test file or rehearsal ref remains in the repository.
