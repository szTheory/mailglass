# Phase 39: Inbound Package Foundation - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_inbound/mix.exs` | config | transform | `mailglass_admin/mix.exs` | role-match |
| `mailglass_inbound/lib/mailglass_inbound.ex` | utility | transform | `mailglass_admin/lib/mailglass_admin.ex` | role-match |
| `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` | public contract | transform | `lib/mailglass/message.ex` | strong |
| `mailglass_inbound/lib/mailglass_inbound/router.ex` | public contract | transform | `lib/mailglass/router.ex` | strong |
| `mailglass_inbound/lib/mailglass_inbound/mailbox.ex` | public contract | request-response | `lib/mailglass/webhook/provider.ex` | role-match |
| `mailglass_inbound/lib/mailglass_inbound/schema.ex` | utility | transform | `lib/mailglass/schema.ex` | exact-shape |
| `mailglass_inbound/lib/mailglass_inbound/repo.ex` | utility | request-response | `lib/mailglass/repo.ex` | exact-shape |
| `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` | utility | transform | `lib/mailglass/optional_deps.ex` | exact-shape |
| `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex` | persistence | transform | existing schema modules using `Mailglass.Schema` | role-match |
| `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex` | persistence | transform | webhook/event persistence patterns in core repo | partial |
| `mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex` | persistence | transform | append-only truth posture from event-ledger patterns | partial |
| `mailglass_inbound/priv/repo/migrations/*_create_mailglass_inbound_*.exs` | persistence | batch | existing core Ecto migration style | role-match |
| `mailglass_inbound/test/mailglass_inbound/*_test.exs` | test | transform | `test/mailglass/message_test.exs`, router tests, webhook provider tests | strong |
| `mailglass_inbound/README.md` | docs | transform | `README.md`, `mailglass_admin/README.md` | role-match |

The exact `mailglass_inbound/` package root is inferred from roadmap/project language about a sibling Hex package. Final filenames remain planner discretion, but the public modules above should stay narrow and obvious. [INFERRED from `.planning/ROADMAP.md` + `.planning/PROJECT.md`]

## Pattern Assignments

### `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex`

**Analog:** `lib/mailglass/message.ex`

**Pattern to copy:**

- rich moduledoc that explains domain language, boundary, and stable fields
- explicit `@type t :: %__MODULE__{...}` inventory
- plain `defstruct` with sensible defaults
- helper constructors/updaters only when they clarify the contract

**Why it fits:**

`Mailglass.Message` is the house precedent for a stable adopter-facing value object that wraps domain semantics without exposing persistence details. Phase 39's context explicitly asks for the inbound analog of that pattern. [VERIFIED: `lib/mailglass/message.ex`, `39-CONTEXT.md`]

**Key notes for planner:**

- keep inbound field inventory explicit in docs/types
- do not make this module an Ecto schema
- keep raw/provider/debug/replay fields out of the struct

### `mailglass_inbound/lib/mailglass_inbound/router.ex`

**Analog:** `lib/mailglass/router.ex`

**Pattern to copy:**

- narrow macro entrypoint
- `NimbleOptions` schema for public DSL options
- compile-time validation with specific `ArgumentError` messages
- helper functions that normalize author input before emitting quoted code

**Why it fits:**

The Phase 39 router should feel declarative for adopters while compiling into pure route data. `Mailglass.Router` already shows the preferred "thin macro, explicit validation" posture. [VERIFIED: `lib/mailglass/router.ex`]

**Key notes for planner:**

- macro layer should author routes; runtime matcher should stay in plain internal modules
- first-match-wins ordering needs tests and probably a compiled route list structure
- do not let the macro expand into provider/runtime-specific code

### `mailglass_inbound/lib/mailglass_inbound/mailbox.ex`

**Analog:** `lib/mailglass/webhook/provider.ex`

**Pattern to copy:**

- one narrow behaviour module
- small callback count
- strong moduledoc documenting exact callback semantics and what is intentionally excluded
- clear separation between explicit result values and operational failures

**Why it fits:**

`Mailglass.Webhook.Provider` is the cleanest existing example of a narrow contract that keeps operational churn behind internal implementations. Phase 39's mailbox behaviour has the same need. [VERIFIED: `lib/mailglass/webhook/provider.ex`]

**Key notes for planner:**

- `process/1` should be the only stable callback
- document exact outcome classes
- execution/retry/Oban semantics belong in internal runner modules, not the behaviour

### `mailglass_inbound/lib/mailglass_inbound/schema.ex`

**Analog:** `lib/mailglass/schema.ex`

**Pattern to copy:**

- minimal `__using__/1` macro that only stamps schema conventions
- no behaviour injection
- shared primary-key / foreign-key / timestamp defaults

**Why it fits:**

If `mailglass_inbound` is a true sibling package, it should carry the same schema conventions locally rather than reaching across package boundaries in surprising ways. [INFERRED from sibling-package posture + `lib/mailglass/schema.ex`]

### `mailglass_inbound/lib/mailglass_inbound/repo.ex`

**Analog:** `lib/mailglass/repo.ex`

**Pattern to copy:**

- thin facade over adopter-configured repo
- explicit write/read helpers only for what the package itself uses
- domain-specific error translation where needed

**Why it fits:**

Phase 39 needs tenant-safe persistence without cross-package coupling. A package-local repo facade mirrors current host-boundary discipline and keeps configuration/runtime semantics obvious for adopters. [VERIFIED: `lib/mailglass/repo.ex`, context D-39-23]

### `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex`

**Analog:** `lib/mailglass/optional_deps.ex`

**Pattern to copy:**

- namespace-only root module
- one gateway submodule per optional dependency
- `Code.ensure_loaded?/1` runtime checks
- compile-time warning suppression scoped to wrapped optional modules

**Why it fits:**

The milestone explicitly preserves optional Oban support instead of making inbound execution mandatory-Oban. This is exactly the existing optional-deps pattern. [VERIFIED: `lib/mailglass/optional_deps.ex`, roadmap]

### Canonical/evidence/history persistence modules

**Analogs:** repo schema conventions plus append-only operational truth posture in core persistence

**Pattern to copy:**

- use separate schemas for distinct truth domains
- make tenant scope explicit on every persisted row
- keep durable/auditable data append-oriented rather than overwriting history

**Why it fits:**

No exact inbound analog exists yet, but the repo's event-ledger and webhook persistence posture already favors explicit durable truth and clear boundary separation. Phase 39 should reuse that mindset without forcing the same exact table design. [VERIFIED: `lib/mailglass/repo.ex`, project constraints, context D-39-20..24]

**Key notes for planner:**

- package-local FK from evidence/history to canonical inbound record is acceptable
- cross-package FK into `mailglass` tables is not
- canonical row should look normalized and adopter-facing; evidence/history rows can stay operational

### Test modules

**Analogs:** `test/mailglass/message_test.exs`, router tests, webhook provider tests

**Pattern to copy:**

- contract tests that read like API guarantees, not internal implementation checks
- focused compile-time validation tests for DSL misuse
- explicit outcome-case coverage for behaviour returns and runtime failures

**Why it fits:**

Phase 39 is defining a stable public contract. The current repo already uses focused contract tests around public API surfaces and routing/provider semantics. [VERIFIED: codebase test layout]

## Concrete Source Patterns

### Stable value object documentation

From `lib/mailglass/message.ex`:

```elixir
@type t :: %__MODULE__{
        swoosh_email: Swoosh.Email.t(),
        mailable: module() | nil,
        mailable_function: atom() | nil,
        tenant_id: String.t() | nil,
        stream: stream(),
        tags: [String.t()],
        metadata: %{atom() => term()},
        assigns: %{atom() => term()}
      }

defstruct [
  :swoosh_email,
  :mailable,
  :mailable_function,
  :tenant_id,
  stream: :transactional,
  tags: [],
  metadata: %{},
  assigns: %{}
]
```

Use this exact level of explicitness for `%InboundMessage{}`.

### Thin macro + option validation

From `lib/mailglass/router.ex`:

```elixir
@opts_schema [
  as: [
    type: :atom,
    default: :mailglass_unsubscribe,
    doc: "Route helper prefix."
  ]
]
```

```elixir
defp validate_opts!(opts) do
  case NimbleOptions.validate(opts, @opts_schema) do
    {:ok, validated} -> validated
    {:error, %NimbleOptions.ValidationError{message: message}} ->
      raise ArgumentError, "invalid opts for mailglass_router_routes/2: " <> message
  end
end
```

Phase 39 should reuse this style for any public routing DSL options or matcher declarations.

### Narrow behaviour contract

From `lib/mailglass/webhook/provider.ex`:

```elixir
@callback verify!(
            raw_body :: binary(),
            headers :: [{String.t(), String.t()}],
            config :: map()
          ) :: :ok | {:ok, :replay}

@callback normalize(
            raw_body :: binary(),
            headers :: [{String.t(), String.t()}]
          ) :: [Mailglass.Events.Event.t()]
```

For `Mailbox`, keep the same discipline but with one callback only.

### Repo boundary discipline

From `lib/mailglass/repo.ex`:

```elixir
def transact(fun, opts \\ []) when is_function(fun, 0) and is_list(opts) do
  repo().transact(fun, opts)
end
```

```elixir
defp repo do
  case Application.get_env(:mailglass, :repo) do
    nil -> raise Mailglass.ConfigError.new(:missing, context: %{key: :repo})
    mod when is_atom(mod) -> mod
  end
end
```

`mailglass_inbound` should use the same explicit host-repo resolution pattern rather than hiding repo ownership.

## Planning Guidance From Patterns

- Keep `39-01` centered on public modules and matcher internals, with tests proving compile-time and runtime routing semantics.
- Keep `39-02` centered on package-local schemas/migrations/repo-facing persistence modules, not on provider plugs or execution workers.
- Keep `39-03` centered on sibling package wiring, optional dependency gateways, baseline docs, and contract tests that prove the public shape.

The main anti-pattern to avoid is mixing all three into one package bootstrap task. The repo's successful phases keep public contract work, persistence work, and docs/proof work distinct enough to verify independently.
