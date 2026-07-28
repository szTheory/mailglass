---
phase: 132-config-mailglass-identifier-foundation
verified: 2026-07-02T22:05:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 132: Config + `Mailglass.Identifier` Foundation Verification Report

**Phase Goal:** Establish the additive configuration + validation foundation — the `:schema` config key (default `"mailglass"`), a boot-validated `:persistent_term`-cached accessor, and a shared `Mailglass.Identifier` validator — mirrored on the inbound line, with zero runtime behavior change yet (Design Phase A of v2.0).
**Verified:** 2026-07-02T22:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Adopter can set `config :mailglass, :schema, "<name>"`; unset defaults to `"mailglass"`; `"public"` documented as pre-2.0 opt-out via config key `:doc` | ✓ VERIFIED | `lib/mailglass/config.ex:17-24` — NimbleOptions `:schema` key `type: :string`, `default: "mailglass"`, doc names `"public"` opt-out + "valid unquoted Postgres identifier". Tests `config_schema_test.exs:30,37,44` assert default `"mailglass"`, override `"analytics"`, and `"public"` accepted. |
| 2 | `Config.schema/0` returns validated name; `validate_at_boot!/0` fails fast on malformed; served from `:persistent_term` (no per-op `Application.get_env`) | ✓ VERIFIED | `config.ex:667-672` reads `:persistent_term.get(@schema_key, :__miss__)`, self-heals via `warm_schema/0`. `config.ex:561-562` boot-warm runs `Identifier.validate!` and caches. Tests assert `persistent_term` holds validated string after read (`:52,62`) and boot raises `%ConfigError{type: :invalid}` on `"has-dash"` (`:66-74`). |
| 3 | Shared `Mailglass.Identifier.validate!/2` rejects non-`[a-zA-Z_][a-zA-Z0-9_]*`; both config-boot AND migration validation call it | ✓ VERIFIED | `lib/mailglass/identifier.ex:29` regex `\A[a-zA-Z_][a-zA-Z0-9_]*\z` (correct `\A...\z` anchors), `:33/:48` 63-byte NAMEDATALEN guard, returns `value` on success, raises `ConfigError.new(:invalid, ...)`. `migrations/postgres.ex:115` `validate_identifier!/2` is a one-line delegate; `@identifier_regex` count = 0. `config.ex:562` + `:676` both call it. |
| 4 | `mailglass_inbound` mirrors the same contract on its own line — `:schema` key, validated accessor, boot validation, `:persistent_term` cache, reusing `Mailglass.Identifier` | ✓ VERIFIED | `mailglass_inbound/.../config.ex:14-23` mirrored `:schema` key; `:148-159` `schema/0` + `warm_schema/0` reuse core `Mailglass.Identifier.validate!/2`, read `:mailglass_inbound` env ONLY (`:156`), same `:__miss__` sentinel + `{MailglassInbound.Config, :schema}` key. `application.ex:14` `validate_at_boot!/0` is the FIRST statement of `start/2` (pre-existing never-called gap closed). |
| 5 | Config tests + `mix credo` green; ZERO runtime behavior change (facade not yet wired) | ✓ VERIFIED | Core 23 tests / 0 failures; inbound 9 tests / 0 failures (both run by verifier, `--seed 0`). Phase diff (`c67bc0db^..90647119`) grep for `prefix:`/`put_prefix`/`Mailglass.Repo`/`@schema_prefix`/`facade` on added lines = NONE. No new error type (only closed `ConfigError :invalid`). |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mailglass/identifier.ex` | Shared validator, `validate!/2` returns string, regex + 63-byte guard, `%ConfigError{type: :invalid}` | ✓ VERIFIED | 77 lines; correct anchors, cond-ordered 63-byte-then-regex, non-binary clause, `@doc since: "2.0.0"`, `@spec`. No `IdentifierError`, no new `:type`. |
| `lib/mailglass/config.ex` | `:schema` key, `schema/0`, `warm_schema/0`, boot-warm, `:__miss__` sentinel | ✓ VERIFIED | `@schema_key {__MODULE__, :schema}` (`:471`); key `:17-24`; boot-warm `:561-562`; accessor `:667-679`. |
| `lib/mailglass/migrations/postgres.ex` | `validate_identifier!/2` one-line delegate; `@identifier_regex` gone | ✓ VERIFIED | `:115` delegate; `@identifier_regex` count 0; 3 call-sites unchanged (`:52,:98,:106`). |
| `test/mailglass/identifier_test.exs` | 8 tests, struct-match only | ✓ VERIFIED | Covers valid/`public`/leading-underscore, 63/64-byte boundary, `has-dash`, `1leading_digit`, non-binary; all `%ConfigError{type: :invalid}` struct-match, never message text. |
| `test/mailglass/config_schema_test.exs` | 6 tests, env+persistent_term restore | ✓ VERIFIED | default/override/`public`, persistent_term caching, boot-warm-on-valid, malformed-boot-raises; `async: false` + `on_exit` restore. |
| `mailglass_inbound/lib/mailglass_inbound/config.ex` | Mirrored `:schema` key + `schema/0`, `:mailglass_inbound` env only, only `:schema` cached | ✓ VERIFIED | Key `:14-23`; `schema/0`/`warm_schema/0` `:148-159`; `validate_at_boot!/0` `:120-130` keeps `validated()` for retention/rate_limit, caches only `:schema`. |
| `mailglass_inbound/lib/mailglass_inbound/application.ex` | `start/2` calls `validate_at_boot!/0` first | ✓ VERIFIED | `:14` `:ok = MailglassInbound.Config.validate_at_boot!()` before `maybe_warn_fallback_mode/0` and children. |
| `mailglass_inbound/test/mailglass_inbound/config_schema_test.exs` | 9 tests incl. boundary-law + uncached guards | ✓ VERIFIED | Adds `:mailglass_inbound`-env-only boundary test (`:40`, ignores core `:mailglass`) and retention/rate_limit uncached guards (`:95-107`). |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| `Config.validate_at_boot!/0` + `warm_schema/0` | `Mailglass.Identifier.validate!/2` | cache-write boundary | ✓ WIRED (`config.ex:562`, `:676`) |
| `Migrations.Postgres.validate_identifier!/2` | `Mailglass.Identifier.validate!/2` | one-line delegate | ✓ WIRED (`postgres.ex:115`) |
| `persistent_term {Mailglass.Config, :schema}` | `schema/0` | boot-warm + sentinel self-heal write, read by accessor | ✓ WIRED |
| `MailglassInbound.Config.schema/0` / `warm_schema/0` | core `Mailglass.Identifier.validate!/2` | cache-write boundary | ✓ WIRED (`inbound config.ex:157`, `:127`) |
| `MailglassInbound.Application.start/2` | `validate_at_boot!/0` | first statement | ✓ WIRED (`application.ex:14`) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Core validator + config + migration suites | `mix test identifier_test config_schema_test migration_test --seed 0` | 23 tests, 0 failures | ✓ PASS |
| Inbound config schema suite | `cd mailglass_inbound && mix test config_schema_test.exs --seed 0` | 9 tests, 0 failures | ✓ PASS |
| Zero-behavior-change constraint | `git diff <phase-range> -- lib/` grep prefix:/Repo/facade on +lines | NONE | ✓ PASS |
| No new error type | grep `IdentifierError`/`defexception` in identifier.ex | only `ConfigError.new(:invalid)` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| SCHEMA-01 | 132-01 | ✓ SATISFIED | `:schema` key, default `"mailglass"`, `"public"` opt-out doc (Truth 1) |
| SCHEMA-02 | 132-01 | ✓ SATISFIED | boot-validated `:persistent_term`-cached `schema/0` (Truth 2) |
| SCHEMA-03 | 132-01 | ✓ SATISFIED | shared `Identifier.validate!/2`, migration delegate (Truth 3) |
| SCHEMA-04 | 132-02 | ✓ SATISFIED | inbound mirror reusing core validator + boot wiring (Truth 4) |

### Anti-Patterns Found

None. No debt markers (`TBD`/`FIXME`/`XXX`) in modified files. No stubs — all functions wired to real config/env sources. Compile warnings observed during test run (`redefining module Mailglass.TestRepo.Migrations.*`) are pre-existing test-fixture noise unrelated to this phase's diff.

### Gaps Summary

None. All 5 ROADMAP success criteria are observably true in the codebase. The load-bearing critical constraint — ZERO runtime behavior change (no `prefix:` injection, no `Mailglass.Repo` facade wiring) — is confirmed by direct inspection of the phase commit range: no such lines were added. The `Mailglass.Repo` facade remains intentionally unwired, deferred to Phase 133 as designed. Both packages ship the identical, family-coherent schema-config contract on their respective version lines.

---

_Verified: 2026-07-02T22:05:00Z_
_Verifier: Claude (gsd-verifier)_
