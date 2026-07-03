---
phase: 136-upgrade-codemod-docs-api-stability
verified: 2026-07-03T10:35:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification
---

# Phase 136: Upgrade codemod + docs + api_stability Verification Report

**Phase Goal:** Ship `mix mailglass.upgrade.v2_schema` (Route B `ALTER TABLE … SET SCHEMA` move migration with `lock_timeout` + trigger recreation + working `down/0`), author `guides/upgrading-to-v2_0.md`, and update `api_stability.md` (core + inbound) with the `:schema` config contract — proven end-to-end against the frozen reference host.
**Verified:** 2026-07-03T10:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix mailglass.upgrade.v2_schema` generates a Route B move migration: `CREATE SCHEMA`, four `ALTER TABLE … SET SCHEMA` under `SET LOCAL lock_timeout`, byte-parity trigger+function recreation, working `down/0` | ✓ VERIFIED | `lib/mix/tasks/mailglass.upgrade.v2_schema.ex` `migration_body/2` emits all four moves (L113-116), `SET LOCAL lock_timeout` (L109), `CREATE SCHEMA IF NOT EXISTS` (L110), recreated function/trigger byte-parity with `v01.ex:136-159`, and a full `down/0` (L145-182) that moves tables back to public + drops the schema. Generation test 14/14 pass. |
| 2 | Applied over a 1.x `public` seed, the move relocates all four tables to `mailglass.*`, 45A01 fires under the moved schema with NO path pin, version comment + citext survive, `down` reverses (tables back in public, schema gone) | ✓ VERIFIED (behavioral) | `test/mailglass/upgrade_v2_schema_migration_test.exs` runs the EMITTED body through `Ecto.Migrator.up/down` and asserts: four tables under `mailglass.*`, 0 mailglass tables in `public`, UPDATE+DELETE raise `45A01` (L147-170), `obj_description` == dynamic `current_version()` (L174-183), mixed-case citext resolves (L186-206), down leaves schema gone (L209-227). 6/6 migration tests pass — real DDL, not presence. |
| 3 | `guides/upgrading-to-v2_0.md` documents Route A (`config :mailglass, :schema, "public"` opt-out), Route B move, `create_schema: false` grants, `public.mailglass_*` grep checklist, `lock_timeout` + `55P03` retry posture | ✓ VERIFIED | Guide (181 lines) contains Route A (L27), Route B (L50), `config :mailglass, :schema, "public"` (L32), `mix mailglass.upgrade.v2_schema` (L57), `create_schema: false` (L129/145), `GRANT USAGE ON SCHEMA` + `ALTER DEFAULT PRIVILEGES` (L137-138), `public.mailglass_` grep string (L93/97/103), `lock_timeout`/`55P03` (L64/115-121). No banned `D-NN`/`LINT-NN` tokens. Docs test 9/9 pass. |
| 4 | `docs/api_stability.md` (core) + `mailglass_inbound/docs/api_stability.md` document `:schema` as a stable 2.0 surface (`Since: 2.0.0`) with tenancy-vs-schema orthogonality | ✓ VERIFIED | Core `## §Schema config (2.0)` (L515), `config :mailglass, :schema` (L517), `Since: 2.0.0` (L544), `orthogonal to tenant_id` + "not a per-tenant prefix" (L536-540). Inbound `### Schema config (2.0)` (L364), `config :mailglass_inbound, :schema` (L366), `Since: 2.0.0` (L389), mirror orthogonality (L382-386). `mix mailglass.docs.check` OK — no tier-1 token disturbed. |

**Score:** 4/4 truths verified (0 present, behavior-unverified). Truth #2 is behavior-dependent (cancellation/immutability + state-move invariants); it is VERIFIED because the migration test executes the emitted DDL and exercises 45A01, comment survival, citext, and down-reverse directly.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/mailglass.upgrade.v2_schema.ex` | Route B emitter, plain `use Mix.Task`, no Igniter/compile guard | ✓ VERIFIED | 195 lines, substantive; `run/1` + testable `migration_body/2`; idempotency wildcard; `--schema` validated via `Mailglass.Identifier.validate!/2`. Credo clean. |
| `test/mailglass/upgrade_v2_schema_generation_test.exs` | UPG-01 emitter + UPG-04 host_app module | ✓ VERIFIED | 14 tests pass, incl. host_app-module discovery (`MailglassReferenceHost`) + compile proof. |
| `test/mailglass/upgrade_v2_schema_migration_test.exs` | UPG-01/04 DDL execution | ✓ VERIFIED | 6 tests pass; runs emitted bytes through `Ecto.Migrator`. |
| `guides/upgrading-to-v2_0.md` | Adopter guide (routes/grants/grep/lock) | ✓ VERIFIED | 181 lines; all required sections present; wired into HexDocs. |
| `docs/api_stability.md` §Schema config (2.0) | `:schema` stable 2.0 surface | ✓ VERIFIED | Section at L515-544. |
| `mailglass_inbound/docs/api_stability.md` :schema | mirror subsection | ✓ VERIFIED | Section at L364-389; docs.check confirms ADD-only. |
| `test/mailglass/upgrade_v2_docs_test.exs` | doc-token + allowlist test | ✓ VERIFIED | 9 tests pass. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| Generated trigger/function DDL | `v01.ex:136-159` | byte-parity → moved DB == fresh install | ✓ WIRED | Same `SET search_path = ''`, same `RAISE SQLSTATE '45A01'` message, same `BEFORE UPDATE OR DELETE`, same `FOR EACH ROW EXECUTE FUNCTION`. Confirmed by side-by-side read + 45A01-under-moved-schema test. |
| `migration_body/2` version comment | `Mailglass.Migrations.Postgres.current_version/0` | dynamic read, not hard-coded '5' | ✓ WIRED | L100 reads at generation time; test asserts against dynamic `current_version()` (L174). |
| App-module discovery regex | `reference/host_app/mix.exs` (`:mailglass_reference_host`) | emitter → valid host_app migration | ✓ WIRED | Test reads real host_app mix.exs, yields `MailglassReferenceHost`, emitted body compiles. host_app tree clean (no pin bump). |
| `guides/upgrading-to-v2_0.md` | `.planning/publish/mailglass-files.expected` | sorted allowlist → unblocks Phase 137 release | ✓ WIRED | Line 28, `sort -c` passes. Prevents 1.10.2 tag-move dance. |
| guide | `mix.exs` extras + groups_for_extras | HexDocs Guides rendering | ✓ WIRED | Lines 440 + 471. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Docs-token + allowlist test | `mix test test/mailglass/upgrade_v2_docs_test.exs --seed 0` | 9 tests, 0 failures | ✓ PASS |
| Emitter + host_app module (UPG-01/04) | `mix test .../upgrade_v2_schema_generation_test.exs --seed 0` | 14 tests, 0 failures | ✓ PASS |
| Move migration DDL execution (45A01/comment/citext/down) | `mix test .../upgrade_v2_schema_migration_test.exs --seed 0` | 6 tests, 0 failures (combined run: 20 tests) | ✓ PASS |
| No-optional-deps warnings-as-errors | `mix compile --no-optional-deps --warnings-as-errors` | exit 0, clean | ✓ PASS |
| Format | `mix format --check-formatted <5 files>` | exit 0 | ✓ PASS |
| Credo (task file) | `mix credo --strict lib/mix/tasks/mailglass.upgrade.v2_schema.ex` | no issues | ✓ PASS |
| Inbound tier-1 tokens intact | `mix mailglass.docs.check` | OK — Tier 1 docs match | ✓ PASS |
| host_app baseline untouched | `git status --short reference/host_app/` | clean | ✓ PASS |
| Allowlist sorted | `LC_ALL=C sort -c .planning/publish/mailglass-files.expected` | passes | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| UPG-01 | 136-01 | Route B move migration (CREATE SCHEMA, 4× ALTER SET SCHEMA under lock_timeout, trigger+function, down/0) | ✓ SATISFIED | Task module + generation test (14 pass) |
| UPG-02 | 136-02 | `guides/upgrading-to-v2_0.md` (both routes, grants, grep checklist, lock posture) + allowlist/HexDocs wiring | ✓ SATISFIED | Guide + docs test (9 pass) + allowlist L28 + mix.exs L440/471 |
| UPG-03 | 136-02 | `:schema` stable 2.0 contract in core + inbound api_stability with orthogonality | ✓ SATISFIED | Both docs edited; docs.check OK |
| UPG-04 | 136-01 | Codemod run end-to-end against `reference/host_app`, asserted green | ✓ SATISFIED | Migration integration test (6 pass) + host_app-module discovery/compile test; host_app pins untouched |

All 4 requirement IDs from PLAN frontmatter (UPG-01..04) are present in `.planning/REQUIREMENTS.md` (L93-106) and mapped to this phase (L166-169). No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `docs/api_stability.md` | 1392 | "not yet implemented" (List-Unsubscribe) | ℹ️ Info | Pre-existing (commit a5e016ec, 2026-04-23); not in phase-added `:schema` section (L515-544). Not a phase gap. |
| `mailglass_inbound/docs/api_stability.md` | 142 | "TODO" in prose | ℹ️ Info | Pre-existing (commit a451a88c, 2026-05-31); describes token-inventory rule, not in phase-added `:schema` section (L364-389). Not a phase gap. |

No blocker anti-patterns introduced by this phase. The two matches predate Phase 136 (confirmed via `git log -L`) and are outside the phase's added content.

### Human Verification Required

None. Every truth is verified by targeted automated tests exercising real behavior (DDL execution, 45A01 invariant, comment/citext survival, down-reverse), plus deterministic file/wiring checks.

### Gaps Summary

None. All four success criteria are behaviorally verified against the codebase:

1. The emitter produces a correct, compilable, idempotent Route B move migration with byte-parity immutability DDL and a working `down/0`.
2. The emitted migration, executed over a 1.x `public` seed, relocates all four tables to `mailglass.*`, preserves the append-only 45A01 invariant with no `search_path` pin, keeps the version comment + citext resolvable, and reverses cleanly (schema gone).
3. The v2.0 guide documents both routes, grants, the `public.mailglass_*` grep checklist, and the lock/retry posture — and is wired into HexDocs + the publish allowlist (load-bearing for Phase 137).
4. `:schema` is documented as a stable 2.0 surface in both api_stability docs with the tenancy-vs-schema orthogonality statement, with docs.check confirming no existing inbound tier-1 token was disturbed.
5. UPG-04's "against reference/host_app" clause is satisfied via the real host_app app-module discovery + compile proof, with the frozen baseline's pins/locks untouched.

The SUMMARY-documented deviations (unrolled ALTER loop, `~s|...|` delimiter fix, down/0 schema drop, teardown-poisoning fix) were independently confirmed correct in the source and are exercised by the passing tests.

---

_Verified: 2026-07-03T10:35:00Z_
_Verifier: Claude (gsd-verifier)_
