# Phase 178 Cycle 06 Summary

Cycle 06's one approved candidate preview attempt was consumed by a stale demo dependency lock; the isolated resources were removed and the owner demo was untouched.

## Preview result

- Candidate: `8e501960bc975ed44b632ba5c74522e0c5d66f8c`; the approval snapshot and one-attempt authority remain preserved in [178-RECOVERY-CYCLE-06.json](178-RECOVERY-CYCLE-06.json).
- Exact-SHA CI lookup: passed for `CI Green` and `Guard Release Trigger` before the local attempt. It applies to the recorded candidate SHA only.
- The isolated Compose project did not become healthy. Mix resolved `nimble_options` 1.2.0 while the candidate lock pinned 1.1.1; the launcher exited 1 before route, CSS, or page-marker checks.
- Routes: none checked. CSS identity: not checked. Page markers: not run. The generated `http://127.0.0.1:54666` address is historical, never served a verified preview, and is unavailable.
- The one attempt is consumed. No retry or relaunch occurred.

## Evidence and cleanup

- Candidate record: `reference/demo_app/tmp/phase178_candidate/recovery-cycle-06/candidate-8e501960.json`, SHA-256 `444e8c576ab43fb447fd11da77581d60012ad2249550382635c4fb0b079c9380`.
- Compose log: `reference/demo_app/tmp/phase178_candidate/recovery-cycle-06/candidate-8e501960.compose.log`, SHA-256 `b7ff3c2dc50db558e12c38ea7891a376dfba26677a556fa3557d6413657ec5c3`.
- Teardown completed at `2026-11-02T14:56:20.649Z`: candidate containers, network and volumes stopped; candidate worktree and run parent removed; demo lock restored to the candidate blob; owner demo not touched.

## Local lock repair

Plan 178-31 updated only the demo lock's `nimble_options` entry from 1.1.1 to 1.2.0, with the Hex-provided checksum. The release's authoritative Hex metadata lists `inserted_at` as `2026-11-02T08:37:25.588622Z` ([Hex release metadata](https://hex.pm/api/packages/nimble_options/releases/1.2.0)). The following local checks passed with the plan's asdf overrides and task-owned `HEX_HOME`:

- `asdf exec mix deps.update nimble_options` (exit 0); only the named lock entry changed.
- `asdf exec mix deps.get --check-locked` (exit 0).
- `asdf exec mix compile --warnings-as-errors` (exit 0).

The compiler run logged missing Storybook CSS/JS asset-path messages because those assets are produced by `mix assets.build`, which was not run. They were runtime logger warnings in the successful dev compile, not compiler warnings that failed the warnings-as-errors gate. Mix also reported the separate unchanged `cowlib` 2.21.0 advisory EEF-CVE-2026-43966 ([OSV advisory](https://osv.dev/vulnerability/EEF-CVE-2026-43966)); that advisory did not cause the nimble_options lock drift and remains visible.

## Remaining boundary

The local lock repair does not alter candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c`, make its hosted receipts current for changed source, or renew the consumed Cycle 06 approval. UIQ-08 remains open. The next owner/planner step is to freeze a new candidate containing the reviewed lock fix, verify current exact-source required CI, then request fresh bounded approval before any preview operation.
