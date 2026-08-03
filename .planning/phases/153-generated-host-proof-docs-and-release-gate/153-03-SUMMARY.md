---
phase: 153
plan: 03
subsystem: generated-host-proof
tags: [phoenix, ecto, postgres, oban, negative-controls, privacy]
requires:
  - phase: 153-02
    provides: normal-mode generated-host sync/async parity proof
provides:
  - closed queue, schema, and input negative-control families
  - zero-delta checkpoint validation for rejected host controls
affects: [153-04, release-gate]
tech-stack:
  added: []
  patterns: [closed control vocabulary, before-after effect vector, sanitized bounded reason classes]
key-files:
  created:
    - test/generated_host/negative_controls_test.exs
  modified:
    - dev/mailglass/generated_host/journey.ex
    - dev/mailglass/generated_host/host_template.ex
    - dev/mailglass/generated_host/checkpoint.ex
    - scripts/generated_host_proof.sh
    - scripts/check_generated_host_proof.sh
decisions:
  - Negative controls use a closed family vocabulary and require an explicit unchanged effect vector.
  - Checkpoints retain only reason classes and numeric counts, never message or provider content.
requirements-completed: [ADOPT-03]
coverage:
  - id: D1
    description: Queue/schema controls reject with bounded reasons and unchanged host effects.
    requirement: ADOPT-03
    verification:
      - kind: integration
        ref: DEP_MODE=local bash scripts/generated_host_proof.sh --stage negative-controls --family queue-schema
        status: pass
    human_judgment: false
  - id: D2
    description: Invalid recipient and payload controls reject through the public outbound boundary with zero deltas.
    requirement: ADOPT-03
    verification:
      - kind: integration
        ref: DEP_MODE=local bash scripts/generated_host_proof.sh --stage negative-controls --family input
        status: pass
      - kind: unit
        ref: test/generated_host/negative_controls_test.exs
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 2
status: complete
---

# Phase 153 Plan 03: Generated-Host Negative Controls Summary

Generated Phoenix hosts now fail bounded queue, schema, recipient, and payload controls while retaining explicit zero-effect evidence for jobs, Mailglass facts, captures, renders, and supervised tasks.

## Tasks Completed

1. Added independent queue/schema negative-control contracts and the generated-host control stage.
2. Added public-input rejection checks and a checkpoint validator that rejects missing or nonzero effect vectors.

## Verification

- `mix test test/generated_host/negative_controls_test.exs --only control_family:queue_schema --warnings-as-errors` — passed.
- `DEP_MODE=local bash scripts/generated_host_proof.sh --stage negative-controls --family queue-schema` — passed.
- `mix test test/generated_host/negative_controls_test.exs --only control_family:input --warnings-as-errors` — passed.
- `DEP_MODE=local bash scripts/generated_host_proof.sh --stage negative-controls --family input` — passed.
- `bash scripts/check_generated_host_proof.sh --checkpoint tmp/generated-host-proof/checkpoint.json` — passed.
- The unit suite deliberately mutates a control to add a job delta; the checkpoint validator rejects it.

## Task Commits

1. Task 1 RED — `2fa93075` `test(153-03): require queue and schema zero-effect controls`
2. Task 1 GREEN — `6ab70469` `feat(153-03): add isolated queue and schema controls`
3. Task 2 RED — `7d91b12a` `test(153-03): require input zero-effect controls`
4. Task 2 GREEN — `b1329d6a` `feat(153-03): enforce input controls before all effects`
5. Host-observation refinement — `16473135` `feat(153-03): record host control observations`

## Decisions Made

- A negative control is accepted only with a closed reason class, `rejected` result, complete before/after vector, and an exact zero delta.
- Sanitized checkpoints expose counts and bounded reason classes only.

## Deviations from Plan

None - plan executed as written.

## Known Stubs

None.

## Self-Check: PASSED

- `test/generated_host/negative_controls_test.exs` exists.
- Task commits `2fa93075`, `6ab70469`, `7d91b12a`, `b1329d6a`, and `16473135` exist in git history.

