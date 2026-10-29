# Phase 177 deferred items

## From plan 177-04 (out of scope, pre-existing)

- `mailglass_admin/e2e/axe-baseline.spec.js` "axe WCAG 2.2 AA baseline producer (RATCHET-03) > scan deliveries / light|dark|system" times out at `page.getByTestId("operator-replay-open").click()` (Full detail overlay, line 120 via `openOverlay`).
  Reproduced on the pre-plan tree (commit 5e1d605d, with the Health files checked out at that SHA), so it is not caused by the Health recomposition. The Health scans in the same spec pass. Whole operator browser run with plan 177-04 applied: 279 passed, 1 skipped, these 3 failed.

## From plan 177-11 (phase gate; out of scope, pre-existing)

- Core suite (`mix test --seed 0` at the repository root): 3 failures, none in a file this phase changed. `state_md_contract_test.exs:38` and `:52` need `gh issue list` and `f733fc22` in `.planning/STATE.md`; STATE.md at the pre-phase commit `03e2cc35` already lacks both (the GSD v2.10 state format). `phase_164_repository_truth_test.exs:261` fails because an untracked local `.gsd/.gitignore` containing `*` makes git ignore `.gsd/extensions/finalize-phase/index.ts`. Needs a decision on the STATE.md contract versus the GSD state format, and removal of the local `.gsd/.gitignore` or a test that ignores it.
- `mix format --check-formatted` in `mailglass_admin` lists ten files with drift that is identical at `03e2cc35` (`auth.ex`, `operator/replay_modal.ex`, `operator/timeline.ex`, and seven test files). `mix credo --strict` reports 1 warning, 3 refactoring opportunities and 2 readability issues in `token_parity_test.exs`, `operator_live.ex` `assign_delivery_state/*`, `endpoint_case.ex` `reset/2` (complexity was already over the limit before the one Phase 177 clause), `operator_live_test.exs:1945`, `fixtures/mailables.ex:84` and `admin_bootstrap.ex:31`.
- The three `axe-baseline.spec.js` "scan deliveries / light|dark|system" timeouts at `operator-replay-open` (see the 177-04 entry above) still reproduce.
