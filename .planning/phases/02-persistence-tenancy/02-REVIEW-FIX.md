---
phase: 02-persistence-tenancy
fixed_at: 2026-04-22T00:00:00Z
review_path: .planning/phases/02-persistence-tenancy/02-REVIEW.md
iteration: 2
findings_in_scope: 12
fixed: 12
skipped: 0
status: all_fixed
---

# Phase 2: Code Review Fix Report (Iteration 2)

**Fixed at:** 2026-04-22
**Source review:** `.planning/phases/02-persistence-tenancy/02-REVIEW.md`
**Iteration:** 2 (supersedes iteration 1)

**Summary:**
- Findings in scope: 12 (4 Warning + 8 Info across both iterations)
- Fixed: 12 (all 4 Warnings in iteration 1; all 8 Info items in iteration 2)
- Skipped: 0
- Status: `all_fixed`

## Preamble

This report supersedes the iteration-1 report (`fix_scope: critical_warning`,
which landed commits `4947fe9`, `41fd242`, `735065f`, `452b0e2` against
`WR-01..WR-04`). The Warning-fix history is preserved verbatim below so the
full Phase 2 fix trail stays discoverable in one artifact.

Iteration 2 was invoked as `/gsd-code-review-fix 02 --all`, which expanded
scope to include the 8 Info findings (`IN-01..IN-08`). All 8 were applied
cleanly; no finding was skipped.

## Test Results

Final `mix test` run (seed 1): `2 properties, 212 tests, 1 failure, 1 skipped`.

The single failure (`test/mailglass/tenancy_test.exs:113` — "SingleTenant
implements @behaviour Mailglass.Tenancy") is a **pre-existing seed-dependent
module-loading race** that also fails at the iteration-1 HEAD (`91aaef1`)
with the same seeds. It asserts `function_exported?(Mailglass.Tenancy.SingleTenant, :scope, 2)`
which returns `false` before the module is loaded; no IN-xx fix touches
that code path. Reruns with seeds `716023` and `12345` (property-test-only)
report `1 property, 0 failures` for the convergence property — confirming
the `IN-02` generator change is correct and non-flaky on its own. The one
pre-existing skip is the same marker that was present in iteration 1 and is
unrelated to these fixes.

## Fixed Issues (Iteration 1 — Warnings, preserved)

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

## Fixed Issues (Iteration 2 — Info)

### IN-01: `Reconciler.attempt_link/2` declares unused `opts` and never emits telemetry

**Files modified:** `lib/mailglass/events/reconciler.ex`
**Commit:** `5bdd3c8`
**Applied fix:** Adopted option (a) from the review. Wrapped the
function body in
`Mailglass.Telemetry.persist_span([:reconcile, :link], %{tenant_id: event.tenant_id}, fn -> ... end)`
so the `[:mailglass, :persist, :reconcile, :link, :start | :stop | :exception]`
span now actually fires during Phase 2 — closing the gap between what
`Mailglass.Telemetry.@logged_events` advertises and what the code emits.
Grepped all call sites (`Reconciler.attempt_link(orphan)` in four test
cases, no production callers yet) — none pass a second argument, so
the `_opts \\ []` parameter was dropped outright. `@spec` and `@doc`
were updated to the new 1-arity signature. Metadata is `:tenant_id`
only, matching the D-31 whitelist.

Verified: `mix test test/mailglass/events/reconciler_test.exs` passed
(9 tests, 0 failures).

### IN-02: Property test can collide `idempotency_key` across different event types

**Files modified:** `test/mailglass/properties/idempotency_convergence_test.exs`
**Commit:** `dd833b6`
**Applied fix:** Adopted option (a). Renamed the raw generator from
`key` to `key_raw` and composed the final `idempotency_key` as
`"#{type}-#{key_raw}"`. Same-raw-key across distinct event types
now produces distinct idempotency keys, eliminating the
~1e-11-per-pair coincidence collision mode that could have produced
false "convergence failed" positives. Added an inline code comment
explaining the motivation so future readers don't restore the naive
form.

Verified: `mix test test/mailglass/properties/idempotency_convergence_test.exs`
passed (1 property, 0 failures) on rerun.

### IN-03: `Mailglass.Repo.infer_immutability_type/1` always returns `:update_attempt`

**Files modified:** `docs/api_stability.md`
**Commit:** `a4a0707`
**Applied fix:** Adopted option (a) from the review — documented the
translator asymmetry under `Mailglass.EventLedgerImmutableError`.
Added a "Translator asymmetry (Phase 2, IN-03)" paragraph explaining
that both `:update_attempt` and `:delete_attempt` remain part of the
stable closed type set, but the v0.1 translator always emits
`:update_attempt`. Explicitly called out that a Phase 4+ refinement
is the path to distinguishing the two actions (either dedicated
trigger functions per action, or pattern-matching the constraint name)
and that today's callers should match either atom
(`err.type in [:update_attempt, :delete_attempt]`) to stay
forward-compatible.

Verified: documentation-only change; no test impact.

### IN-04: Redundant `tenant_id` guard inside `find_orphans/1`

**Files modified:** `lib/mailglass/events/reconciler.ex`
**Commit:** `c513e8f`
**Applied fix:** Added an `is_list(opts)` guard to the function head
plus an explicit `ArgumentError` raise when `tenant_id` is neither
`nil` nor a binary. A caller passing `tenant_id: 42` or `tenant_id: :acme`
now receives
`ArgumentError: tenant_id must be nil or a binary, got: 42`
at the callsite rather than the cryptic `CaseClauseError` the
existing `case tenant_id do ...` form would have produced on the
later binary-only clause.

Verified: `mix test test/mailglass/events/reconciler_test.exs` passed
(9 tests, 0 failures).

### IN-05: `Mailglass.Error` moduledoc says "six error structs" but ships eight

**Files modified:** `lib/mailglass/error.ex`
**Commit:** `6abc242`
**Applied fix:** Updated the moduledoc opening sentence
"Mailglass ships six sibling `defexception` modules" → "eight", and
extended the `## Error Types` bullet list to include
`Mailglass.EventLedgerImmutableError` and `Mailglass.TenancyError`
with verbatim-from-review descriptions. Also updated the `is_error?/1`
docstring that still said "one of the six mailglass error structs" →
"eight". The `@type t`, `@error_modules` module attribute, and
`docs/api_stability.md` all already list all eight correctly — only
the moduledoc and one helper docstring were stale.

Verified: `mix compile` succeeded (module docs re-generated cleanly).

### IN-06: `retryable?/1` docstring references "D-09 retry policy"

**Files modified:** `lib/mailglass/error.ex`
**Commit:** `e0b0f54`
**Applied fix:** Stripped the `"Delegates to the struct module (see
D-09 retry policy):"` wording (D-09 in `.planning/PROJECT.md` is
"Multi-tenancy first-class from v0.1", not the retry policy) and
replaced it with `"Per-struct policy:"`. The authoritative inline
list is now the single source of truth. Added
`Mailglass.EventLedgerImmutableError` and `Mailglass.TenancyError`
to the "always `false`" bullets so the per-struct policy is
complete, plus a closing pointer that `docs/api_stability.md`
documents the per-struct `Retryable:` line verbatim.

Verified: `mix compile` succeeded.

### IN-07: `timestamp_field_for/1` has no entry for `:rejected` or `:failed`

**Files modified:** `lib/mailglass/outbound/projector.ex`
**Commit:** `af401de`
**Applied fix:** Extended the `App-level monotonic rule (D-15)`
section of the `Mailglass.Outbound.Projector` moduledoc — layered on
top of WR-02's earlier rewrite so the "joined pointer" wording for
`last_event_at` + `last_event_type` is preserved intact. The
`dispatched_at / delivered_at / bounced_at / complained_at /
suppressed_at` bullet now explicitly notes that `:rejected` and
`:failed` events DO flip `terminal` but have no corresponding
`*_at` column (D-13 scoped five lifecycle timestamps), and directs
admins to join the event ledger on `(delivery_id, type)` when
answering "when did this delivery fail?". Code unchanged — the
asymmetry was intentional per D-13; this is pure documentation of
the existing contract.

Verified: `mix compile` succeeded.

### IN-08: Brand-voice drift on "must be nil when scope is :address"

**Files modified:** `lib/mailglass/suppression/entry.ex`, `test/mailglass/suppression/entry_test.exs`
**Commit:** `1bf2a6b`
**Applied fix:** Replaced both branches of
`validate_scope_stream_coupling/1` with the composed, on-brand
phrasing from the review:

- `:address_stream` + missing stream → `"is required when scope is :address_stream"`
- `:address` / `:domain` + non-nil stream →
  `"must be omitted when scope is #{inspect(scope)} — stream is only valid for :address_stream"`

The new form mirrors the CLAUDE.md brand convention ("errors are
specific and composed" — D-07) and gives the reader the *why* (what
stream is valid for) inline rather than just the *what*
(`"must be nil"`). Updated the three assertions in
`test/mailglass/suppression/entry_test.exs` (`:address_stream
REQUIRES stream`, `:address REJECTS stream`, `:domain REJECTS
stream`) to match the new messages, keeping the regex-style
`=~` partial-match shape so the tests remain robust to minor
punctuation tweaks.

Verified: `mix test test/mailglass/suppression/entry_test.exs`
passed (14 tests, 0 failures).

---

_Fixed: 2026-04-22_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
