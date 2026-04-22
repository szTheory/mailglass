---
phase: 02-persistence-tenancy
fixed_at: 2026-04-22T00:00:00Z
review_path: .planning/phases/02-persistence-tenancy/02-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 2: Code Review Fix Report

**Fixed at:** 2026-04-22
**Source review:** `.planning/phases/02-persistence-tenancy/02-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (Critical + Warning; Info items out of scope)
- Fixed: 4
- Skipped: 0

All four Warning findings were fixed. Info items (IN-01..IN-08) were
out of scope for this pass (`fix_scope: critical_warning`) and remain
open for a future polish iteration.

The full test suite (`mix test`) was run after the WR-04 fix and
reported `2 properties, 212 tests, 0 failures, 1 skipped` — the
skipped test is pre-existing and unrelated to these fixes.

## Fixed Issues

### WR-01: SQL injection via `:prefix` option in `migrated_version/1`

**Files modified:** `lib/mailglass/migrations/postgres.ex`
**Commit:** `4947fe9`
**Applied fix:** Replaced single-quote escaping + string interpolation
in `Mailglass.Migrations.Postgres.migrated_version/1` with
parameter-bound queries (`$1`) and added a `validate_identifier!/2`
guard that rejects any `:prefix` not matching
`~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/`. The guard is also applied at
`with_defaults/2` and re-applied defensively inside `record_version/2`
before the `COMMENT ON TABLE` DDL. Raises `Mailglass.ConfigError` of
type `:invalid` with the `:key`/`:reason` context atoms on rejection,
matching the rest of the error surface.

### WR-02: `last_event_type` overwrites on strictly-earlier out-of-order events

**Files modified:** `lib/mailglass/outbound/projector.ex`, `test/mailglass/outbound/projector_test.exs`
**Commit:** `41fd242`
**Applied fix:** Fused `maybe_set_later_at/2` and
`maybe_set_later_event_type/2` into a single
`maybe_advance_last_event/2` helper that advances both
`last_event_at` and `last_event_type` together — only when the
incoming event's `occurred_at` is strictly greater than the current
stamp. Earlier out-of-order events move neither field, keeping the
denormalized summary internally consistent with the event-ledger
truth. The moduledoc `App-level monotonic rule (D-15)` section was
rewritten to describe the joined pointer, and the test at
`projector_test.exs:124` was updated to assert
`last_event_type == :opened` (unchanged) rather than `:clicked`
(stale-before-fix behaviour).

Verified: `mix test test/mailglass/outbound/projector_test.exs`
passed (11 tests, 0 failures).

### WR-03: `SuppressionStore.Ecto.check/2` raises `FunctionClauseError` on malformed input

**Files modified:** `lib/mailglass/suppression_store/ecto.ex`
**Commit:** `735065f`
**Applied fix:** Added fallback clauses to both `check/2` and
`record/2` that return `{:error, :invalid_key}` / `{:error, :invalid_attrs}`
respectively. This matches the behaviour's documented
`{:error, term()}` return shape and prevents Phase 3's
`Outbound.preflight` from crashing with a `FunctionClauseError`
stacktrace when an adopter helper passes a malformed key. Map inputs
with invalid field values still flow through `Entry.changeset/1` and
return `{:error, %Ecto.Changeset{}}` as before — only the "not-a-map"
and "missing-required-key" cases are re-routed.

Verified: `mix test test/mailglass/suppression_store/ecto_test.exs`
passed (14 tests, 0 failures).

### WR-04: `Events.append/1` on a non-Postgres adapter is a runtime crash

**Files modified:** `lib/mailglass/config.ex`
**Commit:** `452b0e2`
**Applied fix:** Adopted option (a) from the review — added a
`validate_repo_adapter!/1` helper invoked from
`Mailglass.Config.validate_at_boot!/0`. The helper calls
`repo.__adapter__()` and raises `Mailglass.ConfigError.new(:invalid,
context: %{key: :repo, adapter: other, reason: "Postgres only at v0.1"})`
when the adapter is not `Ecto.Adapters.Postgres`. Because `:repo` is
optional in the v0.1 schema (Phases 0/1 don't require it), the check
is a no-op on `nil` — the Repo facade still raises the `:missing`
error on first use if a Phase 2+ code path needs a repo that wasn't
configured. This mirrors the existing `Mailglass.Migration.migrator/0`
guard and means an adopter wiring
`config :mailglass, repo: MyApp.SqliteRepo` now fails fast at
application startup instead of limping through to the first runtime
write.

Verified: `mix test` (full suite) passed — 2 properties, 212 tests,
0 failures, 1 skipped (pre-existing skip unrelated).

---

_Fixed: 2026-04-22_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
