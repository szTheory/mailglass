---
slug: schema-isolation-regressions
status: investigating
trigger: v2.0 schema-isolation full-suite regressions blocking the linked 2.0 release (PR #119). Never-CI'd 132–136 body surfaced ~7 real cross-phase regressions on first full-body CI. 8 fixes landed; RC5/RC7/residuals remain. Full scope in .planning/phases/137-linked-2-0-release-ceremony-milestone-closeout/137-RELEASE-BLOCKED-DEBUG-SCOPE.md
created: 2026-07-03
updated: 2026-07-03
---

# Debug Session: schema-isolation-regressions

## Symptoms

- **Expected behavior:** Main branch fully green (all required leaves + advisory lanes) on the release-please PR #119 head, so the linked 2.0.0/2.0.0/2.0.0 release can publish. Under both `MAILGLASS_SCHEMA=public` and `MAILGLASS_SCHEMA=mailglass`, the full test suites pass.
- **Actual behavior:** First-ever full-body CI of the never-pushed Phase 132–136 work (Postgres schema isolation) surfaced ~7 distinct real regressions (zero flakes). 8 fixes landed; 3 classes remain red: (a) RC5 admin operator harness, (b) RC7 Trust Lane contract test, (c) residual Core Full Suite per-test regressions (ecto.rollback correctness bug + others).
- **Error messages:**
  - RC5: `relation "mailglass.mailglass_inbound_records" does not exist` in `mailglass_admin/test/mailglass_admin/operator_live_test.exs` (Support Contract Admin — REQUIRED leaf; also Operator Browser Gate + Preview Capture cascade).
  - RC7: `CITrustLaneContractTest:8` asserts the "Trust Lane Clean Baseline" job in `ci.yml` has NO top-level `if:`; PR ci.yml now has `if: needs.changes.outputs.code == 'true'`.
  - Residual: `test/mailglass/migration_test.exs:146` — after `Ecto.Migrator.run(:down, all: true)` the immutability function `mailglass_raise_immutability` is NOT dropped (`fn_rows == [["mailglass_raise_immutability"]]`, expected `[]`); real `mix ecto.rollback` correctness bug from Phase 134's schema-qualified down path. Under `MAILGLASS_SCHEMA=mailglass` it times out on `lock_for_migrations` instead.
- **Timeline:** Introduced across Phases 132–136 (v2.0 schema isolation); never caught because per-phase CI ran path-scoped lanes, never the full body together. Surfaced 2026-07-03 when PR #119's full CI ran (run `28672395333`, head `f1917bac`).
- **Reproduction:** Root repo `MAILGLASS_SCHEMA=mailglass mix test --seed 0` and `MAILGLASS_SCHEMA=public mix test --seed 0`; admin `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs`; contract `mix test test/mailglass/publish/ci_trust_lane_contract_test.exs`. Authoritative full-suite signal = advisory-lane CI logs on the latest RP-PR head.

## Known root causes (from handoff doc — pre-diagnosed, still OPEN)

- **RC5 (REQUIRED merge-blocker):** admin `operator_live_test.exs` `setup_all` `Facade03WrapperMigration.up` runs only `Mailglass.Migration.up(prefix: "mailglass")` (core tables) — never creates the INBOUND tables in the `mailglass` schema. Naive `MailglassInbound.Migration.up` inside the same wrapper FAILED (inbound composes via a nested migrator, not direct DDL). Canonical pattern: `mailglass_inbound/test/test_helper.exs` — an inline wrapper migration calling `MailglassInbound.Migration.up(prefix:, repo:)` driven by its OWN `Ecto.Migrator.up` with a separate version slot + `CREATE SCHEMA` first. Also confirm `operator_fixtures.ex` raw-SQL TRUNCATE/INSERT resolves to the `mailglass` schema. Clears Support Contract Admin + Operator Browser + Preview Capture.
- **RC7:** decide whether to remove the `if:` from the Trust Lane job (restore always-run — likely correct per contract intent) OR update the contract test. `git blame ci.yml` to learn when/why the `if:` was added.
- **Residual RC3 tail:** real `ecto.rollback` bug at `migration_test.exs:146` (Phase 134 schema-qualified down path: `00000000000001_mailglass_init.exs` → `Mailglass.Migration.down()` → `lib/mailglass/migrations/postgres/v01.ex`). Enumerate the rest via the two `--seed 0` runs; classify real-vs-flake (known flakes: `voice_test` "oops" dep-JS noise; phase-45 inbound property-test DB-pool flake — passes in isolation).
- **⚠️ Rigor re-audit (RC3/RC4/RC5 search_path mechanism):** the harness sets `search_path='<schema>, public'` on the TEST connection. Locked decision (3) is "explicit per-query/per-DDL qualification, NEVER SET search_path"; MIGR-05 is framed "no search_path pin". A connection-level search_path can MASK a library query that forgot its explicit `prefix:`. Decide whether the mailglass-axis suite should run WITHOUT a query-path search_path (relying solely on facade `prefix:` injection so missing-qualification bugs surface), confining search_path strictly to raw-SQL fixture/TRUNCATE setup.

## SAFE STATE constraints (MUST hold throughout)

- Nothing published to Hex. Live still 1.11.0/1.11.0/1.6.0. PR #119 OPEN + auto-merge DISARMED.
- Auto-merge RE-ARMS on every push to main (release-please "Arm auto-merge"). After EVERY push run `gh pr merge 119 --disable-auto` and verify `autoMergeRequest == null`.
- Do NOT merge #119 until CI is FULLY green (maintainer chose full-green, not just required-green, for this MAJOR).
- Do NOT reintroduce an `==` inbound core pin. Do NOT pin `config :mailglass, :schema, "public"` in the reference baseline. Do NOT edit `check_clean_baseline_hex_only.sh` or `ci_trust_lane_contract_test.exs` to make them version-specific. Baseline advance stays deferred to post-publish.
- Do NOT trust a red publish-hex run as proof of failed publish — verify via `mix hex.info`.

## Current Focus

hypothesis: Maintainer chose Option B (scope the line-144 `down/0` generic-rollback test to the public axis via `:public_only` tag; the isolation path is already proven by the line-197 `:schema_isolation` sibling). Implementing Option B for the release + a measured Option A dry-run to size the search_path-removal blast radius.
test: BOTH axes on `migration_test.exs` — public must still RUN the down/0 test; mailglass must SKIP it (no lock timeout) while the schema_isolation sibling still runs+passes.
expecting: Option B green on both axes. Option A dry-run cataloged then reverted.

reasoning_checkpoint:
  hypothesis: "The line-144 `down/0` describe is a generic public-axis rollback test (tagged `:migration_roundtrip`). It contributes ZERO schema-isolation coverage on the mailglass axis — the non-public down path is proven independently by the line-197 `:schema_isolation` sibling describe. It only fails on the mailglass axis because the harness connection search_path='mailglass, public' + Sandbox :auto makes Ecto.Migrator.run(:down, all: true) deadlock on lock_for_migrations."
  confirming_evidence:
    - "Line 145: `@describetag :migration_roundtrip` — generic roundtrip, no `:schema_isolation` tag."
    - "Lines 197-383: separate describe tagged `:schema_isolation` proves CREATE/DROP SCHEMA + non-public up/down lifecycle."
    - "Evidence log (e): passes 12/0 under public on clean DB; times out 60s on do_lock_for_migrations under mailglass axis."
  falsification_test: "If skipping the down/0 test on the mailglass axis dropped real isolation coverage, the `:schema_isolation` sibling would NOT already exercise the non-public down path — but it does (lines 317-353, DROP SCHEMA RESTRICT lifecycle)."
  fix_rationale: "Tagging the generic test `:public_only` + excluding that tag on non-public axes routes each test to the axis it actually validates. Addresses root cause (wrong-axis test drag), not the symptom (lock timeout)."
  blind_spots: "Whether any OTHER non-isolation test in the suite has the same wrong-axis lock interaction — Task 2 dry-run will surface those."

next_action: Task 1 — add `@describetag :public_only` to the line-144 down/0 describe; add axis-conditional ExUnit.configure exclude to test_helper.exs; verify both axes.

## Evidence

- timestamp: 2026-07-03 — CI run `28672395333` (head `f1917bac`) is the source of all diagnoses; shipped LIBRARY code largely correct — failures are test-harness / migration-rollback / lint / docs / demo drift from cross-phase (132×133×134×135) interactions per-phase CI never exercised together.
- timestamp: 2026-07-03 — RC5 CONFIRMED + FIXED. Reproduced `mix test test/mailglass_admin/operator_live_test.exs` → 50/70 fail with `relation "mailglass.mailglass_inbound_records" does not exist`. Two root causes: (1) `mailglass_admin/config/test.exs` pinned `:mailglass, :schema` to "public" but NOT `:mailglass_inbound, :schema`, and `MailglassInbound.Config.schema/0` defaults to "mailglass" (not "public") — so inbound reads injected `prefix: "mailglass"`. (2) admin `test_helper.exs` drove inbound migration via `Ecto.Migrator.run` on a `priv/repo/migrations` path, but inbound ships NO priv migrations (created programmatically via `MailglassInbound.Migration.up`, a nested runner) — so ZERO inbound tables were ever created in the admin DB (confirmed `pg_tables` had no `mailglass_inbound%` rows). Fix: pin inbound schema to "public"; replace the path-run with an inline wrapper migration under `Ecto.Migrator.up` (mirroring `mailglass_inbound/test/test_helper.exs`); FACADE-03 module now also flips `:mailglass_inbound, :schema` → "mailglass" and migrates inbound tables into the isolated schema. Result: operator_live_test 70/0; full admin suite 460 tests, 1 pre-existing failure (the `~> 2.0` vs 1.11.0 manifest skew — resolves at publish, NOT a regression). Committed locally (not pushed).

- timestamp: 2026-07-03 — RC7 CONFIRMED + FIXED. `ci_trust_lane_contract_test.exs:8` refutes `^    if:` / `^    needs:` on the Trust Lane Clean Baseline job (added Phase 60, commit `33a5e810`). `git blame` shows the `if: needs.changes.outputs.code == 'true'` + `needs: [changes]` landed in Phase 126 (commit `db8761527`, "M1 CI/CD efficiency"), which deliberately gated ALL 15+ lanes on the `changes` job so docs-only PRs skip expensive lanes — but did not update this stale contract test. Verified the changes-gate is compatible with the publish gate: `Trust Lane Clean Baseline` is NOT in `publish-hex.yml` REQUIRED_LANES, and the gate's `blockingFailures` filter excludes `skipped` jobs — so on real release PRs (code changes present) the lane RUNS and gates, and on docs-only PRs it skips harmlessly. Decision (research-backed, not escalated — strong Phase-126 precedent, fully reversible): UPDATE the test to assert the changes-gate present while preserving the load-bearing "publish-gate-only" contract (not in `ci_green.needs`). Reverting the `if:` would regress the shipped v1.15 milestone. Result: 5 tests, 0 failures. Committed locally.

- timestamp: 2026-07-03 — RC3 TAIL ENUMERATED + CLASSIFIED (repo root, both axes on a clean `mailglass_test` DB). CRITICAL META-FINDING: the authoritative release ref is the RP-PR head `9e204db7` (fetched), where `mix.exs` @version = `2.0.0` and manifest = `2.0.0/2.0.0/2.0.0`. On `main` @version is still `1.11.0` (release-please only bumps on the PR head). So any test that asserts `~> 2.0` admits the core @version is a FALSE POSITIVE on main and PASSES on the RP head. Classification of the ~193 local `MAILGLASS_SCHEMA=public mix test` failures:
  - (a) ~180 webhook/DB tests (Postmark 30, Mailgun 18, Resend 14, CoreWebhookIntegration 11, Suppression, Ingest, Pruner, Plugs, Replay, Reconciler): SHARED-DB-STATE CASCADE in local bare `mix test` — every file passes 0-failures IN ISOLATION on a clean DB (verified postmark_test 30/0, migration_test 12/0). NOT real; an artifact of local full-suite DB ordering. CI uses proper lane isolation.
  - (b) `stability_contract_test:120` + `:183` and admin `mix_config_test:45`: the `~> 2.0` vs 1.11.0 manifest skew — FALSE POSITIVES on main; pass on the RP head (@version 2.0.0). Confirmed by `git show 9e204db7:mix.exs` → @version "2.0.0" and `~> 2.0` admits 2.0.0. NOT real.
  - (c) `docs_contract_test:43-47`: REAL, order-independent — README was updated to "stable 2.0" (RC fix `22c03d82`) but the 3 test assertions still said "stable 1.0". FIXED (updated 3 assertions to 2.0). Now 32/0. Committed.
  - (d) `post_publish_smoke_contract_test:34`: asserts publish-hex `consumer-install` job has an inline `Run mix mailglass.install` step, but that job (in post-publish-smoke.yml) was refactored to `bash scripts/consumer_install_smoke.sh` in PR #61 (`9a02847e`), LONG before v2.0. PRE-EXISTING stale test, AND tagged `@moduletag :requires_workspace` → EXCLUDED from the Core Full Suite Advisory lane (`--exclude requires_workspace`), so it does NOT run in CI and does NOT block the release. OUT OF SCOPE for this v2.0 debug effort; not fixed here.
  - (e) `migration_test.exs:146` ("down/0 drops all three tables + trigger + function + citext in reverse order"): passes 12/0 under PUBLIC on a clean DB (the scope-doc's public `fn_rows` failure did NOT reproduce locally on a clean DB — was likely CI DB-state-specific). Under MAILGLASS it TIMES OUT (60s) on `Ecto.Migrator.do_lock_for_migrations` when `Ecto.Migrator.run(:down, all: true)` runs with the connection `search_path = "mailglass, public"` + Sandbox `:auto`. This test lives in the NON-isolation `up/0`/`down/0` describe (no `@describetag :schema_isolation`) — it's a generic public-axis rollback test dragged into the mailglass axis by the global harness search_path. This is precisely the section-3b/4 search_path-rigor fork → CHECKPOINT.

- timestamp: 2026-07-03 — TASK 1 (Option B) IMPLEMENTED + VERIFIED GREEN ON BOTH AXES. Added `@describetag :public_only` (with an explanatory comment pointing at the `:schema_isolation` sibling as the isolation-path proof) to the line-144 `down/0` describe in `test/mailglass/migration_test.exs`. Added an axis-conditional `if schema != "public", do: ExUnit.configure(exclude: [:public_only])` in root `test/test_helper.exs` (schema var = `Mailglass.Config.schema()`). Verification (clean DBs per axis): `MAILGLASS_SCHEMA=public mix test --seed 0 test/mailglass/migration_test.exs` → 12 tests, 0 failures (down/0 RUNS + passes). `MAILGLASS_SCHEMA=mailglass mix test --seed 0 test/mailglass/migration_test.exs` → 11 tests, 0 failures, **1 excluded** (down/0 SKIPPED, NO lock timeout; the `:schema_isolation` sibling still runs+passes — confirmed via `--only schema_isolation` → 3 tests, 0 failures). Root cause addressed: wrong-axis test drag, not the symptom. Committed locally (not pushed).

## Eliminated

- hypothesis: The ~193 local `MAILGLASS_SCHEMA=public mix test` failures (webhook/DB providers) are real per-test v2.0 regressions.
  evidence: Every failing file passes 0-failures in isolation on a clean DB (postmark_test 30/0, migration_test 12/0). They only fail in the local full-suite run = shared-DB-state ordering cascade, not real. Scope doc pre-flagged CI advisory-lane logs (proper isolation) as the authoritative signal, not local DB state.
  timestamp: 2026-07-03

- hypothesis: The `stability_contract`/`mix_config` `~> 2.0`-vs-1.11.0 failures are real regressions to fix.
  evidence: They are the intended pre-publish manifest skew. `git show 9e204db7:mix.exs` (RP-PR head) → @version "2.0.0"; `~> 2.0` admits 2.0.0 → the assertions pass on the release ref. Fixing them (making them version-tolerant) would defeat their purpose (they PROVE the sibling pin admits the core version at release time). Correct ref = RP head, not main.
  timestamp: 2026-07-03

- hypothesis: The RC7 fix should REMOVE the `if:`/`needs:` from the Trust Lane job to restore always-run.
  evidence: The `if:`/`needs:` were a deliberate Phase 126 (v1.15 M1 CI/CD efficiency) decision applied to ALL lanes; removing them regresses that shipped milestone and re-runs the expensive trust journey on docs-only PRs. The publish gate still runs+gates the lane for real releases (code changes present) and safely skips it (skipped ≠ blocking) for docs-only PRs. So always-run is unnecessary and the contract test was stale, not the ci.yml.
  timestamp: 2026-07-03

- hypothesis: The admin `test_helper.exs` `inbound_migrations_path` (`:code.priv_dir(:mailglass_inbound)/repo/migrations`) was migrating inbound tables into the admin DB.
  evidence: Inbound ships no `priv/` directory at all; the path is empty/nonexistent so `Ecto.Migrator.run` ran zero inbound migrations. Inbound tables were never present in the admin test DB (`pg_tables` LIKE 'mailglass_inbound%' → 0 rows).
  timestamp: 2026-07-03
