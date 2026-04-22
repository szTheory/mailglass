# Phase 2: Persistence + Tenancy — Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 28 new + 5 patches = 33 files
**Analogs found:** 33 / 33 (all files have concrete analogs, in-repo or external)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` (patch: `:uuidv7` dep) | config | build-time | existing `mix.exs` (pattern: add entry to `deps/0`) | exact |
| `lib/mailglass/schema.ex` | utility (DRY macro) | compile-time | `Mailglass.OptionalDeps.Sigra` (tiny module) + Ecto.Schema convention | role-match |
| `lib/mailglass/errors/event_ledger_immutable_error.ex` | error struct | N/A (struct only) | `lib/mailglass/errors/config_error.ex` (in-repo, 6-of-6 error struct pattern) | exact |
| `lib/mailglass/errors/tenancy_error.ex` | error struct | N/A | `lib/mailglass/errors/config_error.ex` | exact |
| `lib/mailglass/errors/suppressed_error.ex` (patch: `@types`) | error struct | N/A | self, existing | patch |
| `lib/mailglass/repo.ex` (patch: activate 45A01 stub) | facade | request-response | self (lines 62-77) + `~/projects/accrue/accrue/lib/accrue/events.ex:208-225` | exact (both sources) |
| `lib/mailglass/config.ex` (patch: `:tenancy`, `:suppression_store`) | config | request-response | self (lines 73-85 already present) — just needs `default:` change | patch |
| `lib/mailglass/telemetry.ex` (patch: `persist_span/3`, `events_append_span/3`) | utility | event emission | `Mailglass.Telemetry.render_span/2` (lines 95-99) | exact |
| `lib/mailglass/tenancy.ex` | behaviour + module | process-dict read/write | `~/projects/accrue/accrue/lib/accrue/actor.ex` (4-of-4 DNA precedent) | exact |
| `lib/mailglass/tenancy/single_tenant.ex` | behaviour impl | no-op | `Mailglass.Adapters.Fake` (tiny default impl pattern, Phase 3) — or just inline | role-match |
| `lib/mailglass/outbound/delivery.ex` | schema | CRUD | `~/projects/accrue/accrue/lib/accrue/events/event.ex` | role-match (Delivery is mutable, Event is append-only) |
| `lib/mailglass/events/event.ex` | schema (immutable) | append-only | `~/projects/accrue/accrue/lib/accrue/events/event.ex` | exact |
| `lib/mailglass/suppression/entry.ex` | schema | CRUD | `~/projects/accrue/accrue/lib/accrue/events/event.ex` (changeset discipline) | role-match |
| `lib/mailglass/events.ex` | context/writer | append-only (dual: inline + Multi) | `~/projects/accrue/accrue/lib/accrue/events.ex` | exact |
| `lib/mailglass/events/reconciler.ex` | context (pure queries) | read-only lookup | `~/projects/accrue/accrue/lib/accrue/events.ex:237-338` (timeline_for, bucket_by) | role-match |
| `lib/mailglass/outbound/projector.ex` | context (pure changeset) | transform | No in-repo analog; RESEARCH §Pattern 4 is canonical | no analog (see §No Analog Found) |
| `lib/mailglass/suppression_store.ex` | behaviour | request-response | `Mailglass.TemplateEngine` (behaviour + default impl, Phase 1) | role-match |
| `lib/mailglass/suppression_store/ecto.ex` | behaviour impl | CRUD | `Mailglass.TemplateEngine.HEEx` (default impl for Phase 1 behaviour) | role-match |
| `lib/mailglass/migration.ex` | public API facade | DDL | `deps/oban/lib/oban/migration.ex` | exact |
| `lib/mailglass/migrations/postgres.ex` | version dispatcher | DDL | `deps/oban/lib/oban/migrations/postgres.ex` | exact |
| `lib/mailglass/migrations/postgres/v01.ex` | migration (per-version DDL) | DDL | `deps/oban/lib/oban/migrations/postgres/v01.ex` + `~/projects/accrue/accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs` | exact (composition) |
| `lib/mailglass/optional_deps/oban.ex` (extend: `TenancyMiddleware`) | optional-dep gateway | request-response | self + `Mailglass.OptionalDeps.Sigra` (conditional-compile idiom) | patch |
| `priv/repo/migrations/00000000000001_mailglass_init.exs` | synthetic test migration | DDL | `deps/oban/lib/oban/migration.ex` (docs example lines 24-32) | exact |
| `config/test.exs` (patch: repo, tenancy) | config | boot-time | existing `config/test.exs` | patch |
| `test/test_helper.exs` (patch: sandbox mode, run migration) | test harness | boot-time | `~/projects/accrue/accrue/test/test_helper.exs` | exact |
| `test/support/test_repo.ex` | test harness | CRUD | `~/projects/accrue/accrue/test/support/test_repo.ex` (if exists) or standard Ecto test-repo pattern | role-match |
| `test/support/data_case.ex` | test case template | test infra | standard Phoenix-generated `DataCase` pattern (Ecto sandbox) | role-match |
| `test/support/generators.ex` | test support | data gen | `test/mailglass/components/vml_preservation_test.exs` (StreamData usage in repo — if present) or `stream_data` idiom | role-match |
| `test/mailglass/events_test.exs` | test | append + idempotency | `test/mailglass/idempotency_key_test.exs` (test shape, describe blocks) | role-match |
| `test/mailglass/events/event_test.exs` | test | changeset validation | `test/mailglass/error_test.exs` | role-match |
| `test/mailglass/events/reconciler_test.exs` | test | query | — | role-match (pure Ecto query tests) |
| `test/mailglass/outbound/delivery_test.exs` | test | changeset + optimistic_lock | `test/mailglass/error_test.exs` | role-match |
| `test/mailglass/outbound/projector_test.exs` | test | pure transform | `test/mailglass/renderer_test.exs` (pure function test) | role-match |
| `test/mailglass/suppression/entry_test.exs` | test | changeset + enum | `test/mailglass/error_test.exs` | role-match |
| `test/mailglass/suppression_store/ecto_test.exs` | test | CRUD | — | role-match |
| `test/mailglass/tenancy_test.exs` | test | process-dict | `test/mailglass/idempotency_key_test.exs` (pure-module test shape) | role-match |
| `test/mailglass/migration_test.exs` | test | DDL | `test/mailglass/repo_test.exs` (Repo facade test shape) | role-match |
| `test/mailglass/properties/idempotency_convergence_test.exs` | property test | StreamData | RESEARCH §1660-1697 + existing `stream_data` dep | no in-repo analog |
| `test/mailglass/properties/tenant_isolation_test.exs` | property test | StreamData | same | no in-repo analog |

---

## Pattern Assignments

### `lib/mailglass/schema.ex` (utility, compile-time DRY macro) — D-28

**Analog:** RESEARCH.md §3.4 (only analog needed; tiny file)

**Complete module** (~12 lines):
```elixir
defmodule Mailglass.Schema do
  @moduledoc """
  Stamps mailglass-wide schema conventions. Three module attributes, no
  behaviour injection, no magic.
  """
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @primary_key {:id, UUIDv7, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
```

---

### `lib/mailglass/errors/event_ledger_immutable_error.ex` (error struct) — D-06

**Analog:** `lib/mailglass/errors/config_error.ex` (in-repo, verbatim Phase 1 pattern)

**Imports + behaviour pattern** (`config_error.ex:19-33`):
```elixir
@behaviour Mailglass.Error

@types [:missing, :invalid, :conflicting, :optional_dep_missing]

@derive {Jason.Encoder, only: [:type, :message, :context]}
defexception [:type, :message, :cause, :context]

@type t :: %__MODULE__{
        type: :missing | :invalid | :conflicting | :optional_dep_missing,
        message: String.t(),
        cause: Exception.t() | nil,
        context: %{atom() => term()}
      }

@doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
@doc since: "0.1.0"
@spec __types__() :: [atom()]
def __types__, do: @types
```

**`@behaviour` callbacks** (`config_error.ex:40-48`):
```elixir
@impl Mailglass.Error
def type(%__MODULE__{type: t}), do: t

@impl Mailglass.Error
def retryable?(%__MODULE__{}), do: false

@impl true
def message(%__MODULE__{type: type, context: ctx}) do
  format_message(type, ctx || %{})
end
```

**For `EventLedgerImmutableError` specifically** — `@types [:update_attempt, :delete_attempt]` per CONTEXT.md §specifics + RESEARCH §5.1. Retryable? = `false`. Also add the `:pg_code` field to `defexception` (defaults to `"45A01"`) so re-raise sites can propagate the SQL state machine-readably.

**Also update** `lib/mailglass/error.ex:46-51, 59-66` `@type t ::` union and `@error_modules` list to include the new struct.

---

### `lib/mailglass/errors/tenancy_error.ex` (error struct) — D-30

**Analog:** `lib/mailglass/errors/config_error.ex` (same pattern as above)

**Difference:** `@types [:unstamped]` (one type — raised by `tenant_id!/0` when no stamp present). Retryable? = `false`.

---

### `lib/mailglass/errors/suppressed_error.ex` (PATCH) — D-09

**Analog:** self (patch in place)

**Current state** (`suppressed_error.ex:21-31`, `76-77`):
```elixir
@types [:address, :domain, :tenant_address]

@type t :: %__MODULE__{
        type: :address | :domain | :tenant_address,
        ...
      }
...
defp format_message(:tenant_address, _ctx),
  do: "Delivery blocked: recipient is suppressed for this tenant"
```

**Patch (D-09):**
- `@types [:address, :domain, :address_stream]`
- `@type t :: %__MODULE__{type: :address | :domain | :address_stream, ...}`
- Replace `:tenant_address` format_message clause with `:address_stream`: `"Delivery blocked: recipient is suppressed for the :bulk stream"` (or a context-aware variant reading `ctx[:stream]`).
- Update moduledoc bullets (lines 13) from `:tenant_address` → `:address_stream`.
- Update `test/mailglass/error_test.exs:68` assertion: `[:address, :domain, :address_stream]`.
- Update `docs/api_stability.md` §Errors per D-09.

---

### `lib/mailglass/repo.ex` (PATCH: activate SQLSTATE 45A01 translation) — D-06

**Analog:** self (lines 62-77 already have the commented stub) + `~/projects/accrue/accrue/lib/accrue/events.ex:208-225`

**Current stub in-repo** (`repo.ex:62-77`):
```elixir
# defp translate_immutability_error(err) do
#   case err do
#     %Postgrex.Error{postgres: %{pg_code: "45A01"}} ->
#       reraise Mailglass.EventLedgerImmutableError,
#               [pg_code: "45A01"],
#               __STACKTRACE__
#     _ ->
#       reraise err, __STACKTRACE__
#   end
# end
```

**Accrue reference for activation shape** (`~/projects/accrue/accrue/lib/accrue/events.ex:208-225`):
```elixir
defp reraise_if_immutable(%Postgrex.Error{postgres: %{pg_code: "45A01"} = pg}, stacktrace) do
  reraise Accrue.EventLedgerImmutableError,
          [message: pg[:message], pg_code: "45A01"],
          stacktrace
end

defp reraise_if_immutable(
       %Postgrex.Error{postgres: %{code: :accrue_event_immutable} = pg},
       stacktrace
     ) do
  reraise Accrue.EventLedgerImmutableError,
          [message: pg[:message], pg_code: "45A01"],
          stacktrace
end

defp reraise_if_immutable(%Postgrex.Error{} = err, stacktrace) do
  reraise err, stacktrace
end
```

**Target shape for `Mailglass.Repo.transact/1`** — wrap the inner `repo().transact(fun, opts)` call in a `try do ... rescue err in Postgrex.Error -> translate_immutability_error(err, __STACKTRACE__) end`. Plus surface the translation on `Mailglass.Repo.insert/2`, `.update/2`, `.delete/2` if those are added (they are — per §1 research Integration Points: Phase 2 extends the Repo facade).

**Also add thin passthroughs on `Mailglass.Repo`** — `insert/2`, `update/2`, `delete/2`, `one/1`, `all/1`, `get/2` — each wrapping the same translation (or routed through transact). Cleanest: single `translate_immutability_error/2` defp; every public function rescues Postgrex.Error and pipes through it.

---

### `lib/mailglass/telemetry.ex` (PATCH: add `persist_span/3` + `events_append_span/3`) — D-04, D-14

**Analog:** self (`telemetry.ex:96-99`)

**Existing pattern — `render_span/2`** (`telemetry.ex:96-99`):
```elixir
@spec render_span(map(), (-> result)) :: result when result: term()
def render_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
  span([:mailglass, :render, :message], metadata, fun)
end
```

**Target — add these two functions following the same shape**:
```elixir
@spec events_append_span(map(), (-> result)) :: result when result: term()
def events_append_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
  span([:mailglass, :events, :append], metadata, fun)
end

@spec persist_span([atom()], map(), (-> result)) :: result when result: term()
def persist_span(suffix, metadata, fun) when is_list(suffix) and is_map(metadata) and is_function(fun, 0) do
  span([:mailglass, :persist] ++ suffix, metadata, fun)
end
```

Per CONTEXT.md "Claude's Discretion" — events append = `[:mailglass, :events, :append, :*]`; projector = `[:mailglass, :persist, :delivery, :update_projections, :*]`; reconciler = `[:mailglass, :persist, :reconcile, :link, :*]`.

**Also extend** `@logged_events` (line 62) with the new stop/exception events so `attach_default_logger/1` picks them up.

---

### `lib/mailglass/tenancy.ex` (behaviour + process-dict helpers) — D-29, D-30, D-31

**Analog:** `~/projects/accrue/accrue/lib/accrue/actor.ex` (verbatim pattern, 4-of-4 DNA)

**Core process-dict helpers** (`~/projects/accrue/accrue/lib/accrue/actor.ex:26-68`):
```elixir
@doc "Stores an actor in the process dictionary."
@spec put_current(t() | nil) :: :ok
def put_current(nil) do
  Process.delete(__MODULE__)
  :ok
end

def put_current(%{type: type} = actor) when type in @actor_types do
  Process.put(__MODULE__, actor)
  :ok
end

@spec current() :: t() | nil
def current, do: Process.get(__MODULE__)

@spec with_actor(t(), (-> any())) :: any()
def with_actor(actor, fun) when is_function(fun, 0) do
  prior = current()
  put_current(actor)

  try do
    fun.()
  after
    put_current(prior)
  end
end
```

**Mailglass divergence** — tenant is a `String.t()` (not a map with `:type`). Single callback `scope/2`. RESEARCH §4.1 gives the final shape. Key points:
- Process-dict key: `:mailglass_tenant_id` (namespaced)
- `current/0` returns `Process.get(@key) || default_tenant()`; `default_tenant()` reads `Mailglass.Config` to detect `SingleTenant` and returns `"default"` when so configured
- `put_current/1` accepts `String.t()` only (raise `ArgumentError` on non-binary)
- `with_tenant/2` wraps + restores prior value (exact accrue `with_actor/2` idiom)
- `tenant_id!/0` raises `Mailglass.TenancyError.new(:unstamped)` when `Process.get(@key)` is nil — fail-loud variant. **Do not** read default from Config here (the `!` suffix means "I hold context, error if absent").
- `scope/2` is the behaviour callback — delegates to `Mailglass.Config.tenancy().scope(query, context)`

**Behaviour declaration** (from RESEARCH §4.1 / D-29):
```elixir
@callback scope(queryable :: Ecto.Queryable.t(), context :: term()) :: Ecto.Queryable.t()
```

---

### `lib/mailglass/tenancy/single_tenant.ex` (no-op default resolver) — D-31

**Analog:** N/A (too tiny; RESEARCH §4.1 gives full code)

**Complete module**:
```elixir
defmodule Mailglass.Tenancy.SingleTenant do
  @moduledoc "Default Tenancy resolver: no-op scope, `\"default\"` tenant_id."
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query
end
```

---

### `lib/mailglass/events/event.ex` (Ecto schema, immutable) — PERSIST-02, D-22

**Analog:** `~/projects/accrue/accrue/lib/accrue/events/event.ex` (4-of-4 DNA precedent)

**Imports + module attrs** (`~/projects/accrue/accrue/lib/accrue/events/event.ex:13-33`):
```elixir
use Ecto.Schema

import Ecto.Changeset

@actor_types ~w[user system webhook oban admin]

@type t :: %__MODULE__{
        id: integer() | nil,
        type: String.t() | nil,
        ...
      }
```

**Schema block + changeset pattern** (`~/projects/accrue/accrue/lib/accrue/events/event.ex:35-72`):
```elixir
@primary_key {:id, :id, autogenerate: true}
schema "accrue_events" do
  field(:type, :string)
  field(:schema_version, :integer, default: 1)
  field(:actor_type, :string)
  # ...
  field(:inserted_at, :utc_datetime_usec, read_after_writes: true)
end

@cast_fields ~w[type schema_version ...]a
@required_fields ~w[type actor_type subject_type subject_id]a

@spec changeset(map()) :: Ecto.Changeset.t()
def changeset(attrs) when is_map(attrs) do
  %__MODULE__{}
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> validate_inclusion(:actor_type, @actor_types)
end
```

**Mailglass divergences (D-10, D-22, D-25, D-26):**
- Replace `use Ecto.Schema` with `use Mailglass.Schema` (D-28 — stamps UUIDv7 + `:binary_id` FK + usec timestamps).
- `@primary_key {:id, UUIDv7, autogenerate: true}` (D-26 — NOT bigserial; explicit override since `Mailglass.Schema` already sets this but reads clearer at the schema site).
- `field :type, Ecto.Enum, values: @event_types` (D-10 — replaces `validate_inclusion`).
- `field :delivery_id, :binary_id` — logical ref, no `references()` (Pitfall 4 in RESEARCH §Common Pitfalls).
- No `updated_at` timestamp — append-only.
- Expose `__types__/0` + `__reject_reasons__/0` per Phase 1 closed-atom-set pattern (Phase 1 D-07).

**Complete target** — RESEARCH §3.2 (lines 1083-1152) gives the full verbatim schema shape.

---

### `lib/mailglass/outbound/delivery.ex` (Ecto schema) — PERSIST-01, D-13, D-18

**Analog:** `~/projects/accrue/accrue/lib/accrue/events/event.ex` (changeset discipline — but Delivery is mutable, unlike Event)

**Adopt the same shape** as Event but with these differences:
- `timestamps(type: :utc_datetime_usec)` at bottom (D-41 — includes `updated_at`; Delivery is mutable).
- `field :lock_version, :integer, default: 1` (D-18).
- `field :last_event_type, Ecto.Enum, values: [all Anymail + internal atoms]` (RESEARCH §3.1, lines 1039-1044).
- `field :stream, Ecto.Enum, values: [:transactional, :operational, :bulk]` (D-10, matches `Mailglass.Message.stream/0` from Phase 1).
- **Field order per CONTEXT.md "Claude's Discretion":** id → tenant_id → foreign keys → state → metadata/flags → timestamps.
- `put_recipient_domain/1` change step (RESEARCH §3.1 lines 1069-1076) — denormalize domain for rate-limit + analytics.

**Complete target** — RESEARCH §3.1 (lines 999-1077).

**Changeset validation order** (per CONTEXT.md "Claude's Discretion"): `cast → validate_required → put_recipient_domain` (mirrors accrue's cast → validate_required → validate_inclusion pattern).

---

### `lib/mailglass/suppression/entry.ex` (Ecto schema) — PERSIST-04, D-07, D-10, D-11

**Analog:** `~/projects/accrue/accrue/lib/accrue/events/event.ex` (changeset shape)

**Key divergences (D-07, D-10, D-11):**
- Three `Ecto.Enum` fields: `:scope`, `:stream` (nullable), `:reason` (D-10).
- `:scope` has NO `default:` (D-11 — MAIL-07 invariant). Changeset requires `:scope` in `validate_required`.
- `field :address, :string` — DB column is `citext` but Ecto sees `:string`.
- Extra changeset step `validate_scope_stream_coupling/1` (RESEARCH §3.3 lines 1207-1220) — belt-and-suspenders with DB CHECK constraint.
- Extra changeset step `downcase_address/1` (RESEARCH §3.3 lines 1222-1227) — defense-in-depth with citext.
- Expose `__scopes__/0`, `__streams__/0`, `__reasons__/0` per closed-atom-set pattern.

**Complete target** — RESEARCH §3.3 (lines 1158-1232).

---

### `lib/mailglass/events.ex` (context/writer) — PERSIST-05, D-01..D-06

**Analog:** `~/projects/accrue/accrue/lib/accrue/events.ex` (verbatim architectural template)

**Dual-API shape** (`~/projects/accrue/accrue/lib/accrue/events.ex:83-116`):
```elixir
@spec record(attrs()) :: {:ok, Event.t()} | {:error, term()}
def record(attrs) when is_map(attrs) do
  normalized = normalize(attrs)
  changeset = Event.changeset(normalized)

  do_insert(changeset, normalized)
rescue
  err in Postgrex.Error ->
    reraise_if_immutable(err, __STACKTRACE__)
end

@spec record_multi(Ecto.Multi.t(), atom(), attrs()) :: Ecto.Multi.t()
def record_multi(multi, name, attrs) when is_atom(name) and is_map(attrs) do
  normalized = normalize(attrs)
  changeset = Event.changeset(normalized)

  Ecto.Multi.insert(multi, name, changeset, insert_opts(normalized))
end
```

**Idempotency insert_opts** (`~/projects/accrue/accrue/lib/accrue/events.ex:122-130`) — use verbatim:
```elixir
defp insert_opts(%{idempotency_key: key}) when is_binary(key) do
  [
    on_conflict: :nothing,
    conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
    returning: true
  ]
end

defp insert_opts(_), do: [returning: true]
```

**`id: nil` replay fetch** (`~/projects/accrue/accrue/lib/accrue/events.ex:177-202`):
```elixir
defp do_insert(changeset, %{idempotency_key: key} = attrs) when is_binary(key) do
  case Accrue.Repo.insert(changeset, insert_opts(attrs)) do
    {:ok, %Event{id: nil}} ->
      fetch_by_idempotency_key(key)

    {:ok, %Event{} = event} ->
      {:ok, event}

    {:error, _} = err ->
      err
  end
end

defp do_insert(changeset, attrs) do
  Accrue.Repo.insert(changeset, insert_opts(attrs))
end

defp fetch_by_idempotency_key(key) do
  query = from(e in Event, where: e.idempotency_key == ^key, limit: 1)

  case Accrue.Repo.one(query) do
    nil -> {:error, :idempotency_lookup_failed}
    event -> {:ok, event}
  end
end
```

**Mailglass divergences from accrue:**
- Rename `record` → `append`, `record_multi` → `append_multi` (PERSIST-05 verb).
- Replace `put_actor/1` with `put_tenant_id/1` — reads `Mailglass.Tenancy.current/0` (D-05).
- Keep `put_trace_id/1` — but read from `:otel_propagator_text_map.current/0` (D-05) not accrue's `Accrue.Telemetry.current_trace_id/0`.
- Wrap the whole `append/1` body in `Mailglass.Telemetry.events_append_span/2` (D-04) — emit `inserted?: boolean` + `idempotency_key_present?: boolean` via the span-return-tuple pattern.
- No upcaster chain (accrue lines 237-370) — mailglass doesn't ship event upcasting in v0.1 (deferred to v0.5+ per RESEARCH §6.1).
- Remove query functions (accrue lines 237-338) — `Mailglass.Events.Reconciler` owns the only Phase 2 query surface; general timeline/bucket queries land in Phase 5's admin LiveView via ARCHITECTURE §4.3 index shapes.
- The SQLSTATE 45A01 rescue happens inside `Mailglass.Repo.transact/1` per D-06 — so `append/1` wraps `do_insert` in `Mailglass.Repo.transact(fn -> ... end)` rather than directly rescuing `Postgrex.Error` (the facade does it).

**Complete target** — RESEARCH §Pattern 1 (lines 336-423) + §5.1.

---

### `lib/mailglass/events/reconciler.ex` (pure queries) — D-19

**Analog:** `~/projects/accrue/accrue/lib/accrue/events.ex:237-338` (pure-query pattern)

**Query pattern** (accrue `timeline_for/3` lines 238-250):
```elixir
@spec timeline_for(String.t(), String.t(), keyword()) :: [Event.t()]
def timeline_for(subject_type, subject_id, opts \\ [])
    when is_binary(subject_type) and is_binary(subject_id) and is_list(opts) do
  limit = Keyword.get(opts, :limit, 1_000)

  from(e in Event,
    where: e.subject_type == ^subject_type and e.subject_id == ^subject_id,
    order_by: [asc: e.inserted_at, asc: e.id],
    limit: ^limit
  )
  |> Accrue.Repo.all()
end
```

**Mailglass target** — RESEARCH §6.1 (lines 1403-1449). Two functions: `find_orphans/1` + `attempt_link/2`. Both pure-Ecto — no Oban dep.

**Critical:** `find_orphans/1` MUST include a `where: e.inserted_at >= ^cutoff` clause — retention-window semantics (default 7 days per RESEARCH §6.1). And MUST use the partial index `mailglass_events_needs_reconcile_idx` via `where: e.needs_reconciliation == true and is_nil(e.delivery_id)`.

---

### `lib/mailglass/outbound/projector.ex` (pure changeset transform) — D-14, D-15, D-18

**Analog:** No in-repo analog (novel module). RESEARCH §Pattern 4 (lines 583-633) is the canonical template.

**Complete target:**
```elixir
defmodule Mailglass.Outbound.Projector do
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Events.Event

  @terminal_event_types ~w[delivered bounced complained rejected failed suppressed]a

  @spec update_projections(Delivery.t(), Event.t()) :: Ecto.Changeset.t()
  def update_projections(%Delivery{} = delivery, %Event{} = event) do
    delivery
    |> Ecto.Changeset.change()
    |> maybe_set_later(:last_event_type, to_string(event.type), delivery.last_event_type)
    |> maybe_set_later_datetime(:last_event_at, event.occurred_at, delivery.last_event_at)
    |> maybe_set_once(timestamp_field_for(event.type), event.occurred_at)
    |> maybe_flip_terminal(event.type)
    |> Ecto.Changeset.optimistic_lock(:lock_version)  # D-18
  end

  # ... timestamp_field_for, maybe_set_later, maybe_set_once, maybe_flip_terminal helpers
  # ... see RESEARCH §Pattern 4 lines 601-632 for exact bodies
end
```

Wrap the public function in `Mailglass.Telemetry.persist_span([:delivery, :update_projections], %{tenant_id: delivery.tenant_id, delivery_id: delivery.id}, fn -> ... end)` per CONTEXT.md "Claude's Discretion" — telemetry granularity.

---

### `lib/mailglass/suppression_store.ex` (behaviour) — PERSIST-04 prep

**Analog:** `Mailglass.TemplateEngine` (Phase 1 behaviour + default impl pattern)

**Behaviour shape** (callbacks per CONTEXT.md "Claude's Discretion" — at minimum `check/2` + `record/1`):
```elixir
defmodule Mailglass.SuppressionStore do
  @moduledoc "Behaviour for suppression-list storage backends."

  alias Mailglass.Suppression.Entry

  @type lookup_key :: %{
          tenant_id: String.t(),
          address: String.t(),
          stream: atom() | nil
        }

  @callback check(lookup_key(), keyword()) ::
              {:suppressed, Entry.t()} | :not_suppressed | {:error, term()}

  @callback record(Entry.changeset_attrs(), keyword()) ::
              {:ok, Entry.t()} | {:error, Ecto.Changeset.t()}
end
```

---

### `lib/mailglass/suppression_store/ecto.ex` (default Ecto impl)

**Analog:** Standard Ecto context pattern; accrue's `Accrue.Events.record/1` insert + `Accrue.Repo.one/1` query for `check/2`.

**Key details:**
- `@behaviour Mailglass.SuppressionStore`
- `check/2` issues the Phase 3 preflight OR-union query from CONTEXT.md §specifics lines 231-240.
- `record/1` wraps `Entry.changeset/1` + `Mailglass.Repo.insert/2` with `on_conflict: {:replace, [:reason, :source, :expires_at, :metadata]}, conflict_target: {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"}` to make admin-re-adds idempotent.

---

### `lib/mailglass/migration.ex` (public API facade) — D-35

**Analog:** `deps/oban/lib/oban/migration.ex` (verbatim pattern)

**Public API shape** (`deps/oban/lib/oban/migration.ex:161-195`):
```elixir
def up(opts \\ []) when is_list(opts) do
  migrator().up(opts)
end

def down(opts \\ []) when is_list(opts) do
  migrator().down(opts)
end

def migrated_version(opts \\ []) when is_list(opts) do
  migrator().migrated_version(opts)
end

defp migrator do
  case repo().__adapter__() do
    Ecto.Adapters.Postgres -> Oban.Migrations.Postgres
    # ...
  end
end
```

**Mailglass divergences:**
- Postgres-only in v0.1 — `migrator/0` unconditionally returns `Mailglass.Migrations.Postgres`; MySQL/SQLite explicitly unsupported (RESEARCH §Migration Strategy Postgres-only note).
- `repo/0` — uses `Mailglass.Repo.repo/0` (extend the existing `defp repo/0` in `lib/mailglass/repo.ex:54-60` to a `def repo/0` — already looks up via `Application.get_env(:mailglass, :repo)`).
- Keep `up/1`, `down/1`, `migrated_version/1` surface identical to Oban's — the adopter migration is the 8-line wrapper per D-36.

**Complete target** — RESEARCH lines 498-501 + Oban pattern.

---

### `lib/mailglass/migrations/postgres.ex` (version dispatcher) — D-35

**Analog:** `deps/oban/lib/oban/migrations/postgres.ex` (verbatim pattern)

**Complete dispatcher logic** (`deps/oban/lib/oban/migrations/postgres.ex:1-96`):
```elixir
defmodule Oban.Migrations.Postgres do
  @moduledoc false

  @behaviour Oban.Migration

  use Ecto.Migration

  @initial_version 1
  @current_version 14  # mailglass starts at 1

  @impl Oban.Migration
  def up(opts) do
    opts = with_defaults(opts, @current_version)
    initial = migrated_version(opts)

    cond do
      initial == 0 ->
        change(@initial_version..opts.version, :up, opts)

      initial < opts.version ->
        change((initial + 1)..opts.version, :up, opts)

      true ->
        :ok
    end
  end

  @impl Oban.Migration
  def migrated_version(opts) do
    opts = with_defaults(opts, @initial_version)
    repo = Map.get_lazy(opts, :repo, fn -> repo() end)
    escaped_prefix = Map.fetch!(opts, :escaped_prefix)

    query = """
    SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
    FROM pg_class
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_class.relname = 'oban_jobs'
    AND pg_namespace.nspname = '#{escaped_prefix}'
    """

    case repo.query(query, [], log: false) do
      {:ok, %{rows: [[version]]}} when is_binary(version) -> String.to_integer(version)
      _ -> 0
    end
  end

  defp change(range, direction, opts) do
    for index <- range do
      pad_idx = String.pad_leading(to_string(index), 2, "0")

      [__MODULE__, "V#{pad_idx}"]
      |> Module.concat()
      |> apply(direction, [opts])
    end

    case direction do
      :up -> record_version(opts, Enum.max(range))
      :down -> record_version(opts, Enum.min(range) - 1)
    end
  end

  defp record_version(_opts, 0), do: :ok

  defp record_version(%{prefix: prefix}, version) do
    execute "COMMENT ON TABLE #{inspect(prefix)}.oban_jobs IS '#{version}'"
  end

  defp with_defaults(opts, version) do
    opts = Enum.into(opts, %{prefix: @default_prefix, version: version})
    opts
    |> Map.put(:quoted_prefix, inspect(opts.prefix))
    |> Map.put(:escaped_prefix, String.replace(opts.prefix, "'", "\\'"))
    |> Map.put_new(:unlogged, true)
    |> Map.put_new(:create_schema, opts.prefix != @default_prefix)
  end
end
```

**Mailglass divergences:**
- Replace `oban_jobs` → `mailglass_events` in the `relname` query (the version marker lives on the events table, not deliveries).
- `@current_version 1` (V01 only ships in Phase 2).
- Drop `unlogged` option (Oban-specific; doesn't apply to mailglass).
- Keep `@default_prefix "public"` and the prefix plumbing — tenant-per-prefix is a v0.5+ deployment option worth preserving in the signature.

---

### `lib/mailglass/migrations/postgres/v01.ex` (per-version DDL) — PERSIST-01..06

**Analog (composition of two):**
1. `deps/oban/lib/oban/migrations/postgres/v01.ex` (Ecto.Migration structure + `create table(:..., primary_key: false, prefix: prefix)` idiom)
2. `~/projects/accrue/accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs` (the trigger function + trigger DDL, verbatim)

**Table creation shape from Oban V01** (lines 1-50):
```elixir
defmodule Oban.Migrations.Postgres.V01 do
  @moduledoc false
  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    # ...
    create_if_not_exists table(:oban_jobs, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true
      add :state, :"#{quoted}.oban_job_state", null: false, default: "available"
      # ...
      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("timezone('UTC', now())")
    end
    # ...
  end
end
```

**Trigger DDL from accrue** (`~/projects/accrue/accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs:44-62`):
```elixir
execute """
        CREATE OR REPLACE FUNCTION accrue_events_immutable()
        RETURNS trigger
        LANGUAGE plpgsql AS $$
        BEGIN
          RAISE SQLSTATE '45A01'
            USING MESSAGE = 'accrue_events is append-only; UPDATE and DELETE are forbidden';
        END;
        $$;
        """,
        "DROP FUNCTION IF EXISTS accrue_events_immutable()"

execute """
        CREATE TRIGGER accrue_events_immutable_trigger
          BEFORE UPDATE OR DELETE ON accrue_events
          FOR EACH ROW EXECUTE FUNCTION accrue_events_immutable();
        """,
        "DROP TRIGGER IF EXISTS accrue_events_immutable_trigger ON accrue_events"
```

**Mailglass V01 composition** — RESEARCH §Migration Strategy §2 (lines 857-988) gives the complete translation. Key changes from the two analogs:
- Rename to `mailglass_raise_immutability` function + `mailglass_events_immutable_trigger` trigger.
- Three tables (not one): `mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`.
- UUIDv7 PKs via `add :id, :uuid, primary_key: true` (D-25 — no `:bigserial`).
- Partial UNIQUE indexes: `create unique_index(..., where: "idempotency_key IS NOT NULL")` and `(provider, provider_message_id) WHERE provider_message_id IS NOT NULL`.
- `citext` extension creation BEFORE `mailglass_suppressions` (Pitfall 8).
- Structural CHECK constraint on `scope`/`stream` coupling (RESEARCH §3 lines 807-814).
- Initial `COMMENT ON TABLE mailglass_events IS '1'` to seed the version marker.

**Partial-index `where:` clauses must match the Ecto `conflict_target` fragments character-for-character** (Pitfall 1 in RESEARCH §Common Pitfalls).

---

### `lib/mailglass/optional_deps/oban.ex` (PATCH: add `TenancyMiddleware`) — D-33

**Analog:** self + `lib/mailglass/optional_deps/sigra.ex` (conditional-compile idiom for behaviour implementers)

**Existing gateway** (`lib/mailglass/optional_deps/oban.ex:1-31`):
```elixir
defmodule Mailglass.OptionalDeps.Oban do
  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)
end
```

**Conditional-compile pattern for the middleware** (`lib/mailglass/optional_deps/sigra.ex:1-33`):
```elixir
if Code.ensure_loaded?(Sigra) do
  defmodule Mailglass.OptionalDeps.Sigra do
    @compile {:no_warn_undefined, [Sigra]}
    @spec available?() :: boolean()
    def available?, do: true
  end
end
```

**Target — extend `lib/mailglass/optional_deps/oban.ex`**:
- Add `@compile {:no_warn_undefined, [Oban.Middleware]}` to the existing compile directive.
- Wrap a new `Mailglass.Oban.TenancyMiddleware` module in `if Code.ensure_loaded?(Oban) and Code.ensure_loaded?(Oban.Middleware) do ... end` — either inside the existing module or as a sibling module in the same file (decide per module-naming convention; RESEARCH §4.2 lines 1275-1300 shows it as a nested `defmodule` inside the gateway file, which matches the sigra pattern).
- Middleware implementation per RESEARCH §4.2 (lines 1286-1297):

```elixir
@behaviour Oban.Middleware

@impl Oban.Middleware
def call(job, next) do
  case job.args do
    %{"mailglass_tenant_id" => tenant_id} when is_binary(tenant_id) ->
      Mailglass.Tenancy.with_tenant(tenant_id, fn -> next.(job) end)
    _ ->
      next.(job)
  end
end
```

**Critical:** The module must NOT break `mix compile --no-optional-deps --warnings-as-errors`. The `if Code.ensure_loaded?(Oban.Middleware)` guard elides the entire `defmodule` when Oban is absent.

---

### `priv/repo/migrations/00000000000001_mailglass_init.exs` (synthetic test migration) — D-37

**Analog:** `deps/oban/lib/oban/migration.ex:24-32` (docstring example) — the 8-line adopter wrapper shape

**Reference pattern** (`deps/oban/lib/oban/migration.ex:24-32`):
```elixir
defmodule MyApp.Repo.Migrations.AddOban do
  use Ecto.Migration

  def up, do: Oban.Migrations.up()

  def down, do: Oban.Migrations.down()
end
```

**Mailglass synthetic test migration** — RESEARCH §Migration Strategy §1 lines 836-842:
```elixir
defmodule Mailglass.TestRepo.Migrations.MailglassInit do
  use Ecto.Migration

  def up, do: Mailglass.Migration.up()

  def down, do: Mailglass.Migration.down()
end
```

Same 8-line shape the `mix mailglass.gen.migration` task will emit for adopters per D-36 (Phase 7 installer composes on top — D-38).

---

### `test/support/test_repo.ex` (test Repo) — D-37

**Analog:** Standard Ecto test-repo pattern (if `~/projects/accrue/accrue/test/support/test_repo.ex` exists, use verbatim; otherwise standard shape)

**Standard shape:**
```elixir
defmodule Mailglass.TestRepo do
  use Ecto.Repo,
    otp_app: :mailglass,
    adapter: Ecto.Adapters.Postgres
end
```

Configured in `config/test.exs` with DB credentials + `config :mailglass, repo: Mailglass.TestRepo`.

---

### `test/support/data_case.ex` (ExUnit case template)

**Analog:** Standard Phoenix-generated `DataCase` (Ecto sandbox pattern)

**Standard shape:**
```elixir
defmodule Mailglass.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Mailglass.TestRepo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Mailglass.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
```

**Mailglass-specific additions:**
- A helper `with_tenant/2` that wraps `Mailglass.Tenancy.with_tenant/2` for test blocks.
- A helper to insert a canned Delivery for tests that need an event-with-delivery.

---

### `test/test_helper.exs` (PATCH: sandbox + migration)

**Analog:** `~/projects/accrue/accrue/test/test_helper.exs` (if it includes sandbox bootstrap); otherwise Ecto standard.

**Current state** (`test/test_helper.exs:1-7`):
```elixir
ExUnit.start()

if Code.ensure_loaded?(Mailglass.TemplateEngine) do
  Mox.defmock(Mailglass.MockTemplateEngine, for: Mailglass.TemplateEngine)
end
```

**Target additions:**
```elixir
# Start the test repo
Mailglass.TestRepo.start_link()

# Run Mailglass.Migration.up/0 via Ecto.Migrator (idempotent — Postgres.migrated_version
# checks the pg_class comment and skips if already at current version)
Ecto.Migrator.run(Mailglass.TestRepo, Path.join(:code.priv_dir(:mailglass), "repo/migrations"), :up, all: true)

# Sandbox mode
Ecto.Adapters.SQL.Sandbox.mode(Mailglass.TestRepo, :manual)
```

---

### `mix.exs` (PATCH: add `:uuidv7` dep) — D-25

**Analog:** existing `mix.exs` `deps/0` function

**Pattern:** Add `{:uuidv7, "~> 1.0"}` to the existing `deps/0` list under the "Core (required)" block — alongside `{:ecto, "~> 3.13"}` and `{:postgrex, "~> 0.22"}`. Required dep, not optional (D-25 — `Mailglass.Schema` macro depends on the `UUIDv7` module at compile time).

---

### `config/test.exs` (PATCH)

**Pattern:** Add three lines:
```elixir
config :mailglass, repo: Mailglass.TestRepo
config :mailglass, tenancy: Mailglass.Tenancy.SingleTenant
config :mailglass, Mailglass.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mailglass_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
```

(DB creds follow Phoenix test-config conventions; pool size per `async: true` test count.)

---

## Shared Patterns

### Error struct (6-of-6 Phase 1 convergent)

**Source:** `lib/mailglass/errors/config_error.ex` (in-repo) + `lib/mailglass/error.ex` behaviour

**Apply to:** `event_ledger_immutable_error.ex`, `tenancy_error.ex`

**Every new error struct:**
1. `@behaviour Mailglass.Error`
2. `@types [...]` — closed atom set, single line, cross-checked in `docs/api_stability.md`.
3. `@derive {Jason.Encoder, only: [:type, :message, :context]}` — `:cause` excluded (PII risk from wrapped adapter/Postgrex structs).
4. `defexception [:type, :message, :cause, :context]`
5. `@type t :: %__MODULE__{type: <union>, message: String.t(), cause: Exception.t() | nil, context: %{atom() => term()}}`
6. `def __types__, do: @types` with `@doc since: "0.1.0"` + `@spec`.
7. `def type/1`, `def retryable?/1`, `def message/1` (behaviour callbacks).
8. `def new(type, opts \\ []) when type in @types do ... end`
9. Register in `lib/mailglass/error.ex` `@type t ::` union (line 46) + `@error_modules` list (line 59).
10. Add corresponding tests to `test/mailglass/error_test.exs` mirroring existing blocks (lines 7-79).

---

### Telemetry span emission

**Source:** `lib/mailglass/telemetry.ex:96-99` (`render_span/2`)

**Apply to:** Every write path — `Events.append/1`, `Events.append_multi/3` (the `_multi` path wraps the COMMIT not the insert), `Projector.update_projections/2`, `Reconciler.attempt_link/2`.

**Contract:**
- Event prefix: 4 atoms `[:mailglass, :domain, :resource, :action]`. Phase-suffix `:start | :stop | :exception` added by `:telemetry.span/3`.
- Metadata: only whitelisted keys per Phase 1 D-31 (`:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`).
- **PII forbidden:** `:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`. Phase 6 `NoPiiInTelemetryMeta` check enforces at lint time.

---

### Closed atom set with `__types__/0` reflection

**Source:** All six Phase 1 error structs + `docs/api_stability.md` cross-check test

**Apply to:**
- `Mailglass.Events.Event.__types__/0` + `__reject_reasons__/0` (Anymail taxonomy, D-14)
- `Mailglass.Suppression.Entry.__scopes__/0` + `__streams__/0` + `__reasons__/0` (D-07, D-10)
- `Mailglass.EventLedgerImmutableError.__types__/0`
- `Mailglass.TenancyError.__types__/0`

**Contract:** Every closed-atom-set `@type` in mailglass code has a `__x__/0` public reflector; every such set is asserted verbatim in a corresponding test against `docs/api_stability.md`.

---

### Schema convention (D-22, D-28, D-41)

**Source:** `lib/mailglass/schema.ex` (new Phase 2 macro) + `~/projects/accrue/accrue/lib/accrue/events/event.ex` (changeset discipline)

**Apply to:** `Delivery`, `Event`, `Suppression.Entry`

**Contract:**
- `use Mailglass.Schema` at top (D-28 — stamps UUIDv7 PK, `:binary_id` FK, usec timestamps).
- Hand-written `@type t :: %__MODULE__{...}` (D-22, D-23 — no `typed_ecto_schema`).
- `schema "mailglass_<plural>" do ... end` with explicit field order: id → tenant_id → foreign keys → state → metadata/flags → timestamps (CONTEXT.md "Claude's Discretion").
- `Ecto.Enum` for all closed atom columns (D-10) — replaces `validate_inclusion/3`.
- Changeset order: `cast → validate_required → domain-specific step(s) → normalize step(s)`.
- Public `__types__/0` / `__<enum>s__/0` reflectors for all `Ecto.Enum` values.
- `timestamps(type: :utc_datetime_usec)` — explicit (not default) for clarity, even though `Mailglass.Schema` sets `@timestamps_opts` (D-41).

---

### Optional-dep gateway for Oban middleware (D-33)

**Source:** `lib/mailglass/optional_deps/oban.ex` (Phase 1) + `lib/mailglass/optional_deps/sigra.ex` (conditional-compile)

**Apply to:** `Mailglass.Oban.TenancyMiddleware`

**Contract:**
- Always-compile gateway: `Mailglass.OptionalDeps.Oban` with `@compile {:no_warn_undefined, [Oban, ...]}` + `available?/0`.
- Conditional-compile behaviour implementer: wrap the `defmodule Mailglass.Oban.TenancyMiddleware` in `if Code.ensure_loaded?(Oban.Middleware) do ... end` so `mix compile --no-optional-deps --warnings-as-errors` passes.
- Callers (Phase 3 enqueue site) check `Mailglass.OptionalDeps.Oban.available?()` before referencing the middleware module.

---

### Tenant context stamping (D-05, D-30, D-33)

**Source:** `~/projects/accrue/accrue/lib/accrue/actor.ex` (4-of-4 DNA precedent)

**Apply to:** `Mailglass.Events.append/1` (reads `Tenancy.current/0`); Phase 3 Outbound enqueue code (writes into Oban job args); Phase 5 admin LiveView mount (via documented two-liner).

**Contract:**
- `Mailglass.Tenancy.put_current/1` stamps process dict on `on_mount/4` (adopter-owned) + `Plug.init/1` (adopter-owned) + test setup blocks.
- Core reads `Mailglass.Tenancy.current/0` — never reads process dict directly (keeps the key name encapsulated).
- Oban jobs carry `"mailglass_tenant_id" => tenant_id` in args; `TenancyMiddleware` restores on `perform/1`.

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns as primary source):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/mailglass/outbound/projector.ex` | context (pure changeset transform) | transform | Novel mailglass-specific module. No precedent in accrue (accrue has no projection-maintenance concept — events ARE the state there). RESEARCH §Pattern 4 (lines 583-633) is the canonical template. |
| `test/mailglass/properties/idempotency_convergence_test.exs` | property test | StreamData | No existing `use ExUnitProperties` tests in-repo yet. RESEARCH §Code Examples (lines 1666-1696) is the canonical shape. |
| `test/mailglass/properties/tenant_isolation_test.exs` | property test | StreamData | Same as above — first property test in repo. Use idempotency_convergence_test as sibling pattern once it lands (Plan N first). |
| `test/mailglass/events/reconciler_test.exs` | test | pure Ecto query | No existing pure-query tests (Phase 1 is DB-free). Standard Ecto query test shape applies: seed rows with `Repo.insert/1`, call `Reconciler.find_orphans/1`, assert shape. |
| `test/mailglass/suppression_store/ecto_test.exs` | test | CRUD | Same — first DB-backed CRUD test in repo. Standard `Mailglass.DataCase`-using test. |

**Planner guidance for "no analog" files:** lean on the RESEARCH.md code blocks directly — they are intentionally written as near-paste-ready Elixir, not sketches. The `Projector` in particular is ~50 lines total; RESEARCH §Pattern 4 is effectively the final implementation.

---

## Metadata

**Analog search scope:**
- `/Users/jon/projects/mailglass/lib/**` (in-repo Phase 1 code — primary source for error structs, behaviours, OptionalDeps, Telemetry, Config, Repo facade)
- `/Users/jon/projects/mailglass/test/**` (test shape precedents)
- `/Users/jon/projects/accrue/accrue/lib/**` (ancestral library — Events writer, Actor, Event schema)
- `/Users/jon/projects/accrue/accrue/priv/repo/migrations/**` (SQLSTATE 45A01 trigger DDL, verbatim)
- `/Users/jon/projects/mailglass/deps/oban/lib/oban/migration.ex` + `/migrations/postgres.ex` + `/migrations/postgres/v01.ex` (migration-delivery pattern, verbatim)

**Files scanned:** ~18 (full reads) + ~10 (targeted reads via Bash `ls`/`head`).

**Pattern extraction date:** 2026-04-22

**Analog ranking summary:**
- Exact match (10): error structs (2), Repo patch (1), Telemetry patch (1), Config patch (1), mix.exs patch (1), test_helper patch (1), synthetic migration (1), Events writer (1), immutability trigger DDL (1).
- Role-match, same data flow (~15): schemas, tenancy (accrue → actor), migration dispatcher (Oban → mailglass), test shapes.
- Role-match, different precise semantics (~5): Delivery schema (mutable vs accrue's Event immutable), SuppressionStore behaviour (TemplateEngine precedent).
- No analog (3): Projector (novel), property tests (first in repo), DB-backed CRUD tests (first in repo).

**Cross-cutting pattern count:** 6 shared patterns applied across multiple files (error struct, telemetry span, closed atom set, schema convention, optional-dep gateway, tenant context stamping).
