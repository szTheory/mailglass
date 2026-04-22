---
phase: 02-persistence-tenancy
reviewed: 2026-04-22T00:00:00Z
depth: standard
files_reviewed: 42
files_reviewed_list:
  - config/test.exs
  - docs/api_stability.md
  - lib/mailglass/error.ex
  - lib/mailglass/errors/event_ledger_immutable_error.ex
  - lib/mailglass/errors/suppressed_error.ex
  - lib/mailglass/errors/tenancy_error.ex
  - lib/mailglass/events.ex
  - lib/mailglass/events/event.ex
  - lib/mailglass/events/reconciler.ex
  - lib/mailglass/migration.ex
  - lib/mailglass/migrations/postgres.ex
  - lib/mailglass/migrations/postgres/v01.ex
  - lib/mailglass/optional_deps/oban.ex
  - lib/mailglass/outbound/delivery.ex
  - lib/mailglass/outbound/projector.ex
  - lib/mailglass/repo.ex
  - lib/mailglass/schema.ex
  - lib/mailglass/suppression/entry.ex
  - lib/mailglass/suppression_store.ex
  - lib/mailglass/suppression_store/ecto.ex
  - lib/mailglass/telemetry.ex
  - lib/mailglass/tenancy.ex
  - lib/mailglass/tenancy/single_tenant.ex
  - mix.exs
  - priv/repo/migrations/00000000000001_mailglass_init.exs
  - test/mailglass/error_test.exs
  - test/mailglass/events/event_test.exs
  - test/mailglass/events/reconciler_test.exs
  - test/mailglass/events_immutability_test.exs
  - test/mailglass/events_test.exs
  - test/mailglass/migration_test.exs
  - test/mailglass/oban/tenancy_middleware_test.exs
  - test/mailglass/outbound/delivery_test.exs
  - test/mailglass/outbound/projector_test.exs
  - test/mailglass/persistence_integration_test.exs
  - test/mailglass/properties/idempotency_convergence_test.exs
  - test/mailglass/suppression/entry_test.exs
  - test/mailglass/suppression_store/ecto_test.exs
  - test/mailglass/tenancy_test.exs
  - test/support/data_case.ex
  - test/support/generators.ex
  - test/support/test_repo.ex
  - test/test_helper.exs
findings:
  critical: 0
  warning: 4
  info: 8
  total: 12
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-04-22
**Depth:** standard
**Files Reviewed:** 42
**Status:** issues_found

## Summary

Phase 2 (Persistence + Tenancy) is in strong shape. The append-only event ledger, SQLSTATE 45A01 translation, tenancy behaviour, scope/stream coupling, and projection state machine are all implemented per the plan, with thorough test coverage for monotonic projections, idempotency replay, multi-tenant isolation, and immutability trigger enforcement. Error contracts match `docs/api_stability.md`, telemetry metadata is PII-free on every emitter in scope, no module outside `Mailglass.Config` touches `Application.compile_env*`, and the optional-Oban gateway is properly conditionally compiled.

The findings below fall into two categories:

1. **Four warnings** — mostly correctness/robustness issues that are unlikely to bite today but will become liabilities as Phase 3/4 land. The most important is a latent SQL-injection exposure in `Mailglass.Migrations.Postgres.migrated_version/1` when adopters set a custom `:prefix`, and a projection-ordering bug where `maybe_set_later_event_type/2` overwrites `last_event_type` for strictly-earlier out-of-order events (the test at `projector_test.exs:124` currently **asserts** this unexpected behaviour — see WR-02).

2. **Eight info-level items** — dead arguments, redundant guards, minor doc drift, a property-test determinism concern, and a few brand-voice/doc nits. All low-stakes.

No critical issues found. No PII leaks in telemetry. No `mailglass_events` UPDATE/DELETE paths. No `name: __MODULE__` singletons in library code. Error contracts are struct-matched, not message-matched. Optional-dep gateway correctly uses `@compile {:no_warn_undefined, ...}` + `available?/0` + `Code.ensure_loaded?/1` guards.

## Warnings

### WR-01: SQL injection via `:prefix` option in `migrated_version/1`

**File:** `lib/mailglass/migrations/postgres.ex:52-58`
**Issue:** The `migrated_version/1` query is built by string interpolation of `escaped_prefix` directly into SQL:

```elixir
query = """
SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
FROM pg_class
LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE pg_class.relname = 'mailglass_events'
AND pg_namespace.nspname = '#{escaped_prefix}'
"""
```

The `with_defaults/2` helper computes `escaped_prefix` as `String.replace(prefix, "'", "\\'")` which only escapes single-quotes. This is inadequate for general SQL escaping and diverges from the Oban/Ecto convention of passing schema names as parameters or using `Postgrex`'s identifier quoting. Today all call sites pass `"public"` (the default) or a caller-controlled atom, so there is no current exploit — but as soon as `Mailglass.Migration.migrated_version(prefix: user_supplied)` is surfaced to an adopter (e.g. a multi-schema deployment) this becomes injectable via e.g. `prefix: "public'; DROP TABLE x; --"`.

Also: the DDL at `postgres.ex:86` — `execute("COMMENT ON TABLE #{inspect(prefix)}.mailglass_events IS '#{version}'")` — has the same shape. `version` is an integer from `@current_version`/`Enum.max(range)` so not attacker-controlled today, and `inspect(prefix)` double-quotes the prefix (making it a valid identifier), but the pattern is fragile and should be audited now before any adopter-facing path reaches it.

**Fix:** Use parameter binding for the schema comparison, and validate the prefix against an identifier regex before interpolating it anywhere. E.g.:

```elixir
defp migrated_version(opts) do
  opts = with_defaults(opts, @initial_version)
  repo = Map.get_lazy(opts, :repo, fn -> repo() end)
  prefix = Map.fetch!(opts, :prefix)

  unless valid_identifier?(prefix) do
    raise Mailglass.ConfigError.new(:invalid,
      context: %{key: :prefix, reason: "must match ~r/\\A[a-z_][a-z0-9_]*\\z/i"})
  end

  query = """
  SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
  FROM pg_class
  LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
  WHERE pg_class.relname = 'mailglass_events'
  AND pg_namespace.nspname = $1
  """

  case repo.query(query, [prefix], log: false) do
    {:ok, %{rows: [[version]]}} when is_binary(version) -> String.to_integer(version)
    _ -> 0
  end
end

defp valid_identifier?(s) when is_binary(s),
  do: Regex.match?(~r/\A[a-z_][a-z0-9_]*\z/i, s)
```

Apply the same identifier-validation guard at `postgres.ex:86` before the `COMMENT ON TABLE` execute, so the whole migration surface becomes injection-safe.

### WR-02: `last_event_type` overwrites on strictly-earlier out-of-order events (contradicts D-15 "monotonic max" intent)

**File:** `lib/mailglass/outbound/projector.ex:69-72`
**Issue:** The helper `maybe_set_later_event_type/2` unconditionally writes the incoming event's type to `last_event_type` whenever `type` is non-nil:

```elixir
defp maybe_set_later_event_type(changeset, %Event{type: type}) when not is_nil(type),
  do: Ecto.Changeset.put_change(changeset, :last_event_type, type)
```

The sibling helper `maybe_set_later_at/2` on the very next line **does** compare timestamps and only advances `last_event_at` when strictly greater. The result is that a late-arriving, earlier-timestamped event will move `last_event_type` without moving `last_event_at`, producing the impossible state "the last event was of type `:clicked` at time T, but `:clicked` actually happened *before* the event that's currently set as last".

The test at `projector_test.exs:124-143` ("earlier occurred_at does NOT move last_event_at backwards") explicitly asserts this behaviour:

```elixir
assert after_earlier.last_event_at == now          # monotonic max preserved
assert after_earlier.last_event_type == :clicked   # ← but type IS overwritten to an older event's type
```

This means `last_event_type` and `last_event_at` can disagree about which event is "latest" when webhook batches reorder — exactly the case D-15 says providers hit in practice. The docstring at `projector.ex:68` ("it's a 'latest event' pointer, not a monotonic lifecycle fact") acknowledges this but the "latest" pointer should point at the same event `last_event_at` points at, which isn't what the code does.

Downstream consequence: admin LiveView queries of the form `SELECT last_event_type FROM mailglass_deliveries WHERE ...` will report types that contradict the event-ledger truth. `terminal` + the lifecycle timestamps are correct because they're set-once, but the denormalized "latest event" summary diverges from the ledger.

**Fix:** Tie `last_event_type` updates to the same monotonic comparison `last_event_at` uses. Easiest approach: fuse the two helpers:

```elixir
# Advance last_event_at + last_event_type together, only when the incoming
# event's occurred_at is strictly greater than the current stamp. Keeps the
# summary columns internally consistent.
defp maybe_advance_last_event(changeset, %Event{type: type, occurred_at: occurred_at})
     when not is_nil(type) and not is_nil(occurred_at) do
  current_at = Ecto.Changeset.get_field(changeset, :last_event_at)

  if is_nil(current_at) or DateTime.compare(occurred_at, current_at) == :gt do
    changeset
    |> Ecto.Changeset.put_change(:last_event_at, occurred_at)
    |> Ecto.Changeset.put_change(:last_event_type, type)
  else
    changeset
  end
end

defp maybe_advance_last_event(changeset, _), do: changeset
```

Update the test `projector_test.exs:124` to assert the corrected invariant:

```elixir
# last_event_type should NOT move back either — both advance together or neither does.
assert after_earlier.last_event_type == :opened
```

If the current behaviour is genuinely intended (sometimes a product wants "most recently observed" instead of "latest observed"), please add a docstring paragraph explaining the divergence from `last_event_at` and why; today the divergence looks accidental given how closely `maybe_set_later_at/2` sits next to it.

### WR-03: `Mailglass.SuppressionStore.Ecto.check/2` raises `FunctionClauseError` on malformed input instead of returning `{:error, term()}`

**File:** `lib/mailglass/suppression_store/ecto.ex:32-35`
**Issue:** The behaviour callback `Mailglass.SuppressionStore.check/2` is specified as returning `{:suppressed, Entry.t()} | :not_suppressed | {:error, term()}`. The Ecto implementation has only the happy-path clause gated on `is_binary(tenant_id) and is_binary(address)`:

```elixir
def check(%{tenant_id: tenant_id, address: address} = key, _opts)
    when is_binary(tenant_id) and is_binary(address) do
```

With no fallback clause, any call like `check(%{tenant_id: nil, ...})` or `check(%{address: nil})` raises `FunctionClauseError` instead of returning `{:error, :invalid_key}`. Phase 3's `Outbound.preflight` will call this on every send — a malformed key (e.g. from a mis-wired adopter test helper) will surface as a scary stacktrace instead of a structured error that can be logged/handled.

**Fix:** Add a fallback clause that returns `{:error, :invalid_key}` (or raise a `Mailglass.ConfigError` — consistent with the rest of the error surface):

```elixir
@impl Mailglass.SuppressionStore
def check(key, opts \\ [])

def check(%{tenant_id: tenant_id, address: address} = key, _opts)
    when is_binary(tenant_id) and is_binary(address) do
  # ... existing body
end

def check(_key, _opts), do: {:error, :invalid_key}
```

Same treatment for `record/2` — today malformed attrs go through the changeset and return `{:error, %Ecto.Changeset{}}`, which is fine, but a non-map input raises `FunctionClauseError`. Consider whether the guard belongs on the public surface.

### WR-04: `Events.append/1` on a `Repo.transact/1` configured with a non-Postgres adapter is a runtime crash, not a typed error

**File:** `lib/mailglass/events.ex:98` (via `lib/mailglass/repo.ex:51-55`)
**Issue:** `Mailglass.Repo.transact/1` only rescues `Postgrex.Error`. If an adopter configures a non-Postgres Repo (e.g. `Ecto.Adapters.MyXQL`), every append-path will raise a non-mailglass error at the first `Postgrex`-specific call. `Mailglass.Migration.migrator/0` at `lib/mailglass/migration.ex:56-63` correctly guards the migration path with a `Mailglass.ConfigError.new(:invalid, ...)`, but the runtime path (`Events.append/1`, `Projector.update_projections/2`, `SuppressionStore.Ecto.*`) does not. An adopter who wires `config :mailglass, repo: MyApp.SqliteRepo` will get confusing errors from Ecto/Postgrex layers instead of a single clean `ConfigError`.

**Fix:** Either (a) enforce adapter at boot in `Mailglass.Config.validate_at_boot!/0` (Phase 3 already owns this hook — add a check that `repo().__adapter__() == Ecto.Adapters.Postgres`), or (b) add an adapter guard at `Mailglass.Repo.repo/0` symmetric to the migrator's check. Option (a) is cheaper and fails at boot instead of first write.

## Info

### IN-01: `Reconciler.attempt_link/2` declares an unused `opts` parameter and never emits telemetry

**File:** `lib/mailglass/events/reconciler.ex:98`
**Issue:** The signature is `attempt_link(%Event{} = event, _opts \\ [])` — the `opts` keyword is accepted but unused, and the function body never emits the `[:mailglass, :persist, :reconcile, :link, :*]` span that `lib/mailglass/telemetry.ex:69` lists in `@logged_events`. The attached logger handler is thus registered for an event name that never fires in Phase 2 (fires in Phase 4 per the plan). This is not a bug (the Phase 4 worker will wrap these calls in the span), but it creates a silent discrepancy between what the default logger advertises and what the current code emits.

**Fix:** Either (a) wrap `attempt_link/2` in `Mailglass.Telemetry.persist_span([:reconcile, :link], %{tenant_id: event.tenant_id}, fn -> ... end)` now — low-cost, and gives Phase 4's worker a ready-made observability surface — or (b) drop `[:mailglass, :persist, :reconcile, :link, :*]` from `@logged_events` until Phase 4 actually emits it. Prefer (a).

If you also drop the unused `_opts \\ []` parameter, the public API surface shrinks by one no-op keyword.

### IN-02: Property test may produce flaky failures when `idempotency_key` generator collides across different event types

**File:** `test/mailglass/properties/idempotency_convergence_test.exs:63-100`
**Issue:** The generator produces `idempotency_key <- string(:alphanumeric, min_length: 8, max_length: 32)` — collision-unlikely (62^8 ≈ 2.18e14 at minimum length) but not zero. If a single generated `events` list happens to contain two events with the same `idempotency_key` and different `type`s, Pass 1 ("apply each once, in original order") will keep the first event's type; Pass 2 ("shuffle N duplicates") will keep whichever type lands first in the shuffle — which can differ.

The `snapshot()` comparison compares `%{idempotency_key => type}` maps, so a divergent winner shows up as a `fresh_snapshot != replayed_snapshot` failure — a false positive that blames the convergence code when the real cause is the generator shape.

**Fix:** Either (a) make keys disambiguate `type` (e.g. `idempotency_key <- map({type, key}, fn {t, k} -> "#{t}-#{k}" end)` passed through or generated post-hoc), or (b) in Pass 1 dedupe by `idempotency_key` *keeping the first occurrence* and compare against Pass 2's expected-first-wins behaviour. Option (a) is simpler:

```elixir
gen all(
      type <- member_of(@event_types),
      key_raw <- string(:alphanumeric, min_length: 8, max_length: 32),
      occurred_offset_sec <- integer(-60..60)
    ) do
  %{
    type: type,
    tenant_id: "prop-test-tenant",
    # Disambiguate by type so same raw key across different types produces
    # distinct idempotency keys — prevents spurious "replay-of-different-type"
    # coincidence collisions from failing the convergence assertion.
    idempotency_key: "#{type}-#{key_raw}",
    occurred_at: DateTime.add(DateTime.utc_now(), occurred_offset_sec, :second),
    raw_payload: %{},
    normalized_payload: %{},
    metadata: %{}
  }
end
```

Low priority — the collision probability at current cardinality is ~1e-11 per pair, so a real failure here is overwhelmingly more likely to indicate a real convergence bug. Still worth eliminating the known flaky mode.

### IN-03: `Mailglass.Repo.infer_immutability_type/1` always returns `:update_attempt` even for DELETE triggers

**File:** `lib/mailglass/repo.ex:139-140`
**Issue:** The comment at `repo.ex:132-138` is explicit that the distinction is deliberately dropped because the Postgrex error message text isn't a stable API. Fair. But the ledger immutability error's `__types__` atom set (`[:update_attempt, :delete_attempt]`) is now asymmetric — `:delete_attempt` is a value the type system accepts but nothing in the codebase can produce. Either (a) document the asymmetry in `docs/api_stability.md` ("`:delete_attempt` is reserved for future use — the Phase 2 translator always emits `:update_attempt`"), or (b) actually distinguish by checking the Postgrex error's `:constraint` field or by naming two trigger functions (one per action) in the migration and pattern-matching the raised MESSAGE.

The test at `events_immutability_test.exs:62-73` already asserts `err.type in [:update_attempt, :delete_attempt]` — so the public test contract tolerates either answer, but a caller trying to report "was this an UPDATE or a DELETE?" has no correct path today.

**Fix:** For Phase 2, option (a) — add a note to `docs/api_stability.md` under `Mailglass.EventLedgerImmutableError` explaining that both atoms are reserved but the v0.1 translator always emits `:update_attempt`. Option (b) is a Phase 4 follow-up candidate if webhook-path DELETE-attempt telemetry becomes valuable.

### IN-04: Redundant `tenant_id` guard inside `find_orphans/1`

**File:** `lib/mailglass/events/reconciler.ex:72-75`
**Issue:**

```elixir
query =
  case tenant_id do
    nil -> query
    tid when is_binary(tid) -> where(query, [e], e.tenant_id == ^tid)
  end
```

There's no explicit clause for non-binary, non-nil values — if a caller passes `tenant_id: 42` or `tenant_id: :acme`, this raises `CaseClauseError`. The `Keyword.get(opts, :tenant_id)` at the top returns whatever the caller supplied; the function signature (`find_orphans(keyword())`) doesn't constrain it further. A single `_other -> raise ArgumentError, "tenant_id must be nil or a binary"` clause or a guard on the function head would make the failure actionable.

**Fix:**

```elixir
def find_orphans(opts \\ []) when is_list(opts) do
  tenant_id = Keyword.get(opts, :tenant_id)

  unless is_nil(tenant_id) or is_binary(tenant_id) do
    raise ArgumentError,
          "tenant_id must be nil or a binary, got: #{inspect(tenant_id)}"
  end

  # ... rest unchanged
end
```

### IN-05: `Mailglass.Error` behaviour documentation still says "six error structs" but union has eight

**File:** `lib/mailglass/error.ex:5-18, 45-53`
**Issue:** The moduledoc says "Mailglass ships six sibling `defexception` modules" and lists six, but `@type t` correctly unions eight (`EventLedgerImmutableError`, `TenancyError` added in Phase 2). `@error_modules` at `:61-70` also correctly lists eight. The docstring at `:17-18` — "## Error Types / - `Mailglass.SendError` ... - `Mailglass.ConfigError`" — omits the two Phase 2 additions, so readers grepping the moduledoc will miss them.

`docs/api_stability.md` correctly documents all eight. Only the moduledoc is stale.

**Fix:** Extend the moduledoc list:

```elixir
## Error Types

- `Mailglass.SendError` — delivery failure (...)
- `Mailglass.TemplateError` — HEEx compile, missing assign, undefined helper, inliner
- `Mailglass.SignatureError` — webhook signature missing, malformed, mismatch, stale
- `Mailglass.SuppressedError` — delivery blocked by suppression list
- `Mailglass.RateLimitError` — rate limit exceeded (domain, tenant, stream)
- `Mailglass.ConfigError` — configuration missing, invalid, conflicting, optional-dep absent
- `Mailglass.EventLedgerImmutableError` — SQLSTATE 45A01 translation (D-06, Phase 2)
- `Mailglass.TenancyError` — tenant context not stamped on the current process (Phase 2)
```

Update "six" → "eight" in the opening sentence.

### IN-06: `retryable?/1` docstring references "D-09" (project decision) but the decision lives at Phase 1

**File:** `lib/mailglass/error.ex:94-99`
**Issue:** The docstring for `retryable?/1` says "Delegates to the struct module (see D-09 retry policy)". D-09 in `.planning/PROJECT.md` is "Multi-tenancy first-class from v0.1" — not the retry policy. The retry policy decision lives at Phase 1's D-09 internal ID (phase-scoped). This is a documentation cross-reference drift that'll confuse a reader consulting PROJECT.md's D-table.

**Fix:** Replace "D-09 retry policy" with a concrete inline summary or a pointer to Phase 1's error-contract section:

```elixir
@doc """
Returns `true` when the error is retryable per its struct's `retryable?/1`
callback. Per-struct policy:

- `Mailglass.SignatureError`, `Mailglass.ConfigError` — always `false`
- `Mailglass.SuppressedError`, `Mailglass.TemplateError` — always `false`
- `Mailglass.RateLimitError` — always `true` (caller uses `retry_after_ms`)
- `Mailglass.SendError` — `true` only for `:adapter_failure`
"""
```

(Drop the "D-09" reference — the inline list is the authoritative contract.)

### IN-07: `timestamp_field_for/1` has no entry for `:rejected` or `:failed`, but they flip `terminal`

**File:** `lib/mailglass/outbound/projector.ex:109-114`
**Issue:** `@terminal_event_types` at `projector.ex:41` includes `:rejected` and `:failed`, and `maybe_flip_terminal/2` flips `terminal` to true for both. But `timestamp_field_for/1` maps only `:dispatched | :delivered | :bounced | :complained | :suppressed` to columns — `:rejected` and `:failed` have no corresponding `*_at` column in `mailglass_deliveries`. That's consistent with D-13 ("Full 8 projection columns... dispatched_at, delivered_at, bounced_at, complained_at, suppressed_at"), but it means a `:rejected` or `:failed` event will flip `terminal=true` without recording a lifecycle timestamp — admins querying "when did this delivery fail?" have to join the event ledger instead of reading a single column on `mailglass_deliveries`.

This isn't incorrect (the plan explicitly scoped to 5 timestamp columns), but the asymmetry between "terminal event types" (6 entries) and "timestamp-tracked event types" (5 entries) is worth a docstring note so the next reader doesn't assume it's a bug.

**Fix:** Extend the docstring at `projector.ex:11-18` to call out the asymmetry:

```elixir
## App-level monotonic rule (D-15)

- `last_event_type` — always updated to the latest event's type.
- `last_event_at` — `max(current, event.occurred_at)`; monotonic.
- `dispatched_at` / `delivered_at` / `bounced_at` / `complained_at` /
  `suppressed_at` — set ONCE when the matching event type arrives;
  never overwritten. Note that `:rejected` and `:failed` events DO
  flip `terminal` but have no corresponding `*_at` column — querying
  "when did this delivery fail?" joins the event ledger.
- `terminal` — flips `false → true` on any of
  `:delivered | :bounced | :complained | :rejected | :failed |
  :suppressed`. Never flips back.
```

Alternatively: add `failed_at` and `rejected_at` columns in V02 (v0.5). Defer to the planner.

### IN-08: Minor brand-voice drift in one error message ("must be nil when scope is :address")

**File:** `lib/mailglass/suppression/entry.ex:97-99`
**Issue:** The error added by `validate_scope_stream_coupling/1` for the mismatched-stream case is:

```elixir
add_error(changeset, :stream, "must be nil when scope is #{inspect(scope)}")
```

Compare the adjacent error at `:96`:

> `"required when scope is :address_stream"`

The "must be nil" phrasing is a little blunt for mailglass's brand voice ("clear, exact, confident... warm not cute"). The prior maintainer wrote D-07 as "scope in (:address, :domain) REJECTS stream" — a more composed message would mirror that:

```elixir
"must be omitted when scope is #{inspect(scope)} — stream is only valid for :address_stream"
```

Not a functional issue. Purely brand-voice polish. Mentioning because CLAUDE.md calls out "errors are specific and composed" as a locked convention.

**Fix:**

```elixir
defp validate_scope_stream_coupling(changeset) do
  scope = get_field(changeset, :scope)
  stream = get_field(changeset, :stream)

  case {scope, stream} do
    {:address_stream, nil} ->
      add_error(changeset, :stream, "is required when scope is :address_stream")

    {scope, stream} when scope in [:address, :domain] and not is_nil(stream) ->
      add_error(
        changeset,
        :stream,
        "must be omitted when scope is #{inspect(scope)} — stream is only valid for :address_stream"
      )

    _ ->
      changeset
  end
end
```

Update the matching test at `suppression/entry_test.exs:45-52` to assert the new messages.

---

_Reviewed: 2026-04-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
