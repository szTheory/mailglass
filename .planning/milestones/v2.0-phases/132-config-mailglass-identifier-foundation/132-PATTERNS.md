# Phase 132: Config + `Mailglass.Identifier` foundation - Pattern Map

**Mapped:** 2026-07-02
**Files analyzed:** 5 (1 created, 4 modified)
**Analogs found:** 5 / 5 (all in-repo, exact or near-exact)

All analogs live in the same codebase and same layer as the target files. This is a
pure-additive config/validation phase, so every new file has a strong local template.
Line numbers below were re-verified against the live files (CONTEXT.md's refs held; only
minor ±1 drift noted inline).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/identifier.ex` | utility (validator) | transform (validate-or-raise) | `lib/mailglass/migrations/postgres.ex` `validate_identifier!/2` (l.123-140) | exact — being promoted verbatim |
| `lib/mailglass/config.ex` | config | request-response (accessor) + boot-warm | `Mailglass.Config` `:theme` cache (l.544) + `get_theme/0` (l.630-633) | exact — sibling accessor, same module |
| `lib/mailglass/migrations/postgres.ex` | migration | transform | its own `validate_identifier!/2` → one-line delegate | self (refactor) |
| `mailglass_inbound/lib/mailglass_inbound/config.ex` | config | request-response (accessor) + boot-warm | core `Mailglass.Config` `:schema` (this phase) + own `validated/0` (l.165) | role-match — cross-package mirror |
| `mailglass_inbound/lib/mailglass_inbound/application.ex` | application (boot) | event-driven (start/2) | `Mailglass.Application.start/2` (l.7-11) | role-match — mirror boot-warm wiring |

## Pattern Assignments

### `lib/mailglass/identifier.ex` (NEW — utility/validator, transform)

**Analog:** `lib/mailglass/migrations/postgres.ex` lines 115-140 (the private
`validate_identifier!/2` + `@identifier_regex` being **promoted** into this module).

**Regex + doc comment to lift verbatim** (`postgres.ex:115-121`):
```elixir
# Postgres unquoted-identifier grammar: letter or underscore, then any
# combination of letters, digits, and underscores. Rejects anything that
# could be an injection vector (quotes, semicolons, whitespace, etc.).
# Callers with a legitimate need for a quoted identifier (mixed case,
# dashes) should pre-quote and adjust the regex — but at v0.1 we do not
# surface such options.
@identifier_regex ~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/
```
Keep `\A...\z` (NOT `^...$`) per D-06.

**Binary clause to promote** (`postgres.ex:123-134`) — BUT change the `:ok` return to the
validated string (D-07), and ADD the 63-byte NAMEDATALEN guard (D-10). The two error
clauses (regex-fail + non-binary) keep raising `ConfigError.new(:invalid, ...)` unchanged
(D-08). Existing regex-fail raise to preserve byte-identically:
```elixir
raise Mailglass.ConfigError.new(:invalid,
        context: %{
          key: key,
          reason: "must match #{inspect(@identifier_regex)}"
        }
      )
```

**Non-binary clause to promote** (`postgres.ex:136-140`) verbatim:
```elixir
defp validate_identifier!(value, key) do
  raise Mailglass.ConfigError.new(:invalid,
          context: %{key: key, reason: "must be a binary, got: #{inspect(value)}"}
        )
end
```

**New over-63-byte guard to ADD** (D-10) — model the raise on the two existing clauses,
reusing `ConfigError.new(:invalid, context: %{key:, reason:})`. Place it as a guarded
`is_binary(value) and byte_size(value) > 63` clause (or a `byte_size` check inside the
binary clause, before the regex match). Reason string names the 63-byte NAMEDATALEN limit.

**Public contract shape** (D-07/D-09): single bang function, returns the string.
```elixir
@doc since: "2.0.0"
@spec validate!(String.t(), atom()) :: String.t()
def validate!(value, key) when is_binary(value) do
  # 63-byte guard, then regex match, then: value
end
```
NO `valid?/1`, NO non-bang `validate/2` (D-09). `@doc since: "2.0.0"` (net-new in core 2.0).

**Moduledoc/voice:** clear, exact, confident — name the Postgres unquoted-identifier
grammar and the 63-byte NAMEDATALEN reason. Errors composed, never "Oops!".

---

### `lib/mailglass/config.ex` (MODIFIED — config, accessor + boot-warm)

**Analog:** the `:theme` persistent_term cache in this same module — but with the D-03
caveat that its empty-default cold-miss idiom is **UNSAFE to copy** for `:schema`.

**1. NimbleOptions `@schema` key** — add BEFORE `@moduledoc` (the `@schema` list runs
`l.4-460`; `@moduledoc` starts `l.462`). Follow the exact per-key shape of neighbors like
`feedback_id` (l.5-10):
```elixir
schema: [
  type: :string,
  default: "mailglass",
  doc:
    "Names the Postgres SCHEMA holding all mailglass domain tables. " <>
      "`\"public\"` is the explicit pre-2.0 opt-out. Must be a valid " <>
      "unquoted Postgres identifier."
],
```
Placement anywhere in the `@schema` keyword list is fine; append near the DB-oriented
keys (`repo`, l.11-16). Verbatim doc intent from dossier §3.1 + D-01.

**2. Boot-warm** — extend `validate_at_boot!/0` (`l.526-553`). The `:theme` put is the
direct template (`l.543-544`):
```elixir
theme = Keyword.get(validated, :theme, [])
:persistent_term.put({__MODULE__, :theme}, theme)
```
Add ALONGSIDE it (D-03): read the already-NimbleOptions-validated `:schema` from
`validated`, run `Mailglass.Identifier.validate!/2`, then `:persistent_term.put`. Recommend
caching the validated value from the boot pipeline so boot + cache can never disagree
(Claude's Discretion note). Example landing at ~l.544 (right after the theme put):
```elixir
schema = Keyword.get(validated, :schema, "mailglass")
:persistent_term.put({__MODULE__, :schema}, Mailglass.Identifier.validate!(schema, :schema))
```
`validate_at_boot!/0` still returns `:ok` — no spec change (l.525).

**3. Hot-path accessor `schema/0`** — model on `get_theme/0` (`l.630-633`) for the
`@doc since` / `@spec` / `:persistent_term.get` shape:
```elixir
@doc since: "0.1.0"
@spec get_theme() :: keyword()
def get_theme do
  :persistent_term.get({__MODULE__, :theme}, [])
end
```
**DO NOT copy the empty-default idiom** (D-03). `schema/0` must use a **sentinel-miss
self-heal**, not a silent `"mailglass"` default (a silent default would mask an adopter's
`schema: "public"` opt-out in a boot-skipped context → silent cross-schema corruption).
Use the locked sketch from CONTEXT.md §Specific Ideas:
```elixir
@schema_key {__MODULE__, :schema}
def schema do
  case :persistent_term.get(@schema_key, :__miss__) do
    :__miss__ -> warm_schema()
    schema -> schema
  end
end
defp warm_schema do
  schema = Application.get_env(:mailglass, :schema, "mailglass")
  Mailglass.Identifier.validate!(schema, :schema)
  :persistent_term.put(@schema_key, schema)
  schema
end
```
`@doc since: "2.0.0"`, `@spec schema() :: String.t()`. Validate ONCE at the cache-write
boundary (D-04), never per read. NO `config_change/3`, NO invalidation (D-05). Sentinel
atom name (`:__miss__` / `:__unset__`) and helper name (`warm_schema/0`) are Claude's
Discretion — keep identical across core + inbound.

**Moduledoc note:** the existing moduledoc (l.469-471) already documents the persistent_term
theme cache — extend that paragraph to mention `:schema` is cached the same way, warmed at
boot with a self-healing backfill for boot-skipped contexts.

---

### `lib/mailglass/migrations/postgres.ex` (MODIFIED — migration, delegate refactor)

**Analog:** self. Refactor its own private `validate_identifier!/2` (l.123-140) into a
one-line delegate and drop `@identifier_regex` (l.121) + the promotion doc comment
(l.115-121) — they now live in `Mailglass.Identifier` (D-11).

**Replace l.115-140** with:
```elixir
defp validate_identifier!(value, key), do: Mailglass.Identifier.validate!(value, key)
```

**Call-sites unchanged** — both discard the return:
- `l.98`: `validate_identifier!(prefix, :prefix)` (defensive re-check in `record_version/2`)
- `l.106`: `validate_identifier!(o.prefix, :prefix)` inside a `then/2` that returns `o`

The `:ok`→string return change is invisible at both call-sites (the value is discarded).
The raised `ConfigError` stays byte-identical. Only behavioral delta anywhere: the new
over-63-byte rejection, inherited for free (strictly stricter — D-10/D-11).

---

### `mailglass_inbound/lib/mailglass_inbound/config.ex` (MODIFIED — config, accessor + boot-warm)

**Analog:** core `Mailglass.Config` `:schema` (built this phase) — mirror it exactly. The
`@schema` block already declared BEFORE `@moduledoc` here (l.14-57 / moduledoc l.59), and
the existing `validate_at_boot!/0` (l.104-107) + private `validated/0` (l.165-172) are the
local scaffold to extend.

**1. NimbleOptions `:schema` key** — add to the `@schema` list (l.14-57), same shape as
core D-01, read from `:mailglass_inbound` app env ONLY (D-12, boundary law):
```elixir
schema: [
  type: :string,
  default: "mailglass",
  doc:
    "Names the Postgres SCHEMA holding inbound tables. `\"public\"` is the " <>
      "explicit pre-2.0 opt-out. Must be a valid unquoted Postgres identifier."
],
```

**2. `schema/0` accessor** — SAME persistent_term + sentinel-miss self-heal as core
(D-14), but keyed `{MailglassInbound.Config, :schema}`, and the lazy re-read pulls from
`:mailglass_inbound` env:
```elixir
@schema_key {__MODULE__, :schema}
def schema do
  case :persistent_term.get(@schema_key, :__miss__) do
    :__miss__ -> warm_schema()
    schema -> schema
  end
end
defp warm_schema do
  schema = Application.get_env(:mailglass_inbound, :schema, "mailglass")
  Mailglass.Identifier.validate!(schema, :schema)   # REUSE core validator (D-13)
  :persistent_term.put(@schema_key, schema)
  schema
end
```
**REUSE `Mailglass.Identifier.validate!/2`** (D-13) — inbound already hard-depends on core
and already raises `Mailglass.ConfigError` pervasively; no inbound-local regex/error.
`@doc since: "2.0.0"`. ONLY `:schema` is cached (D-14) — `retention/0` (l.130) and
`rate_limit/0` (l.163) stay on the existing uncached `validated/0` path (cold-path).

**3. Boot-warm** — extend `validate_at_boot!/0` (l.104-107). Currently:
```elixir
@doc since: "1.2.0"
@spec validate_at_boot!() :: :ok
def validate_at_boot! do
  _ = validated()
  :ok
end
```
Add a `:schema` validate + `:persistent_term.put` before returning `:ok` (mirroring core's
boot warm of `:theme`/`:schema`). Read the `:schema` from the `validated()` result (or
re-read env), `Identifier.validate!`, then put. Still returns `:ok` — no spec change.

**Moduledoc:** the existing note (l.99-101) says `validate_at_boot!/0` "is not called
automatically." That note was about `retention`/`rate_limit` (host reads on demand). After
D-15 wires boot-warm, update the moduledoc to state that inbound's own `application.ex` now
calls `validate_at_boot!/0` to warm `:schema` and fail fast on a bad identifier.

---

### `mailglass_inbound/lib/mailglass_inbound/application.ex` (MODIFIED — application boot)

**Analog:** `Mailglass.Application.start/2` (l.7-11):
```elixir
def start(_type, _args) do
  if Code.ensure_loaded?(Mailglass.Config) and
       function_exported?(Mailglass.Config, :validate_at_boot!, 0) do
    Mailglass.Config.validate_at_boot!()
  end
  # ...
```

**Wire the call as the FIRST statement of `start/2`** (D-15), before the existing
`maybe_warn_fallback_mode()` (l.11) and `children` list (l.13). Current inbound `start/2`:
```elixir
def start(_type, _args) do
  :ok = maybe_warn_fallback_mode()

  children = [ ... ]
  Supervisor.start_link(children, ...)
end
```
Insert `MailglassInbound.Config.validate_at_boot!()` as the new first statement. Inbound is
the correct owner because `:schema` is inbound's OWN app env (D-15). This fixes the
pre-existing gap where `validate_at_boot!/0` was defined but never called. A direct call is
fine (unlike core's defensive `Code.ensure_loaded?` guard, which exists because core's
`application.ex` may run before `Mailglass.Config` compiles in some load orders — inbound
has no such ordering concern, but matching the guarded form is acceptable if desired).

---

## Shared Patterns

### Error contract — `Mailglass.ConfigError.new(:invalid, context:)`
**Source:** `lib/mailglass/errors/config_error.ex` (constructor l.94-104; `:invalid` in the
closed `@types` set l.37-48; message formatter l.111-114).
**Apply to:** `Mailglass.Identifier` (all raise paths), and transitively every `schema/0`
warm path (core + inbound) via the validator.
```elixir
raise Mailglass.ConfigError.new(:invalid,
        context: %{key: key, reason: "..."})
```
Reuse `:invalid` unchanged (D-08) — do NOT add an `IdentifierError` or a new `:type` atom.
The closed set is contract-tested against `docs/api_stability.md`. Semantic clarity lives
in `context.key` / `context.reason`, NEVER the message string (engineering DNA:
"pattern-match by struct, never by message string").

### persistent_term cache + sentinel-miss self-heal
**Source (mechanism):** `Mailglass.Config` `:theme` (put l.544, get l.632).
**Source (sentinel-gate precedent):** `Mailglass.Application` uses
`:persistent_term.get({:mailglass, :oban_warning_emitted}, false)` as a boot-once gate
(l.55, l.74) — same "read with a default sentinel, act on miss, put-once" shape.
**Apply to:** `Config.schema/0` (core) and `MailglassInbound.Config.schema/0`.
Key shape `{Module, :schema}`; validate ONCE at the write boundary (D-04); NO invalidation
(D-05) — `:persistent_term.put/2` triggers a global GC scan, so writes are boot-once +
at-most-once-per-boot-skipped-context. The `:theme` empty-default idiom is UNSAFE to copy
(D-03) — schema needs the sentinel, not a silent default.

### Boot-warm wiring in `start/2`
**Source:** `Mailglass.Application.start/2` (l.7-11) calls `Mailglass.Config.validate_at_boot!()`
first thing.
**Apply to:** `MailglassInbound.Application.start/2` (D-15) — mirror the first-statement
boot-warm. Fail fast on a bad identifier + warm the `:schema` cache before children start.

### NimbleOptions `@schema` before `@moduledoc`
**Source:** both config modules already do this (`config.ex:2-4` comment + `@schema` l.4;
`mailglass_inbound/.../config.ex:2-3` comment + `@schema` l.14). `#{NimbleOptions.docs(@schema)}`
is interpolated into the moduledoc (core l.475, inbound l.89).
**Apply to:** add the `:schema` key inside the existing `@schema` lists so it renders in
generated docs. Do NOT move the `@schema` after `@moduledoc`.

## No Analog Found

None. Every target file has a strong in-repo template. `Mailglass.Identifier` is net-new as
a module, but its entire body is promoted verbatim from an existing private function.

## Metadata

**Analog search scope:** `lib/mailglass/` (config, migrations, errors, application),
`mailglass_inbound/lib/mailglass_inbound/` (config, application).
**Files scanned:** 6 (config.ex ×2, migrations/postgres.ex, errors/config_error.ex,
application.ex ×2).
**Line numbers:** verified against live files 2026-07-02. Notable: `validate_at_boot!/0`
core l.526 (CONTEXT said 525, ±1 drift); `:theme` put l.544 ✓; `get_theme/0` l.630-633 ✓;
`@identifier_regex` l.121 ✓; `validate_identifier!/2` l.123-140 (CONTEXT said 121-140);
call-sites l.98 + l.106 ✓; inbound `validate_at_boot!/0` l.104 ✓; inbound `validated/0`
l.165 ✓.
**Pattern extraction date:** 2026-07-02
