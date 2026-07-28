# Phase 132: Config + `Mailglass.Identifier` foundation - Context

**Gathered:** 2026-07-02 (assumptions mode + per-area research)
**Status:** Ready for planning

<domain>
## Phase Boundary

**Design Phase A of v2.0 (Postgres Schema Isolation).** Establish the *additive*
configuration + validation foundation that everything downstream reads:

- the `:schema` config key on core (`config :mailglass, :schema`, default `"mailglass"`,
  `"public"` = explicit pre-2.0 opt-out),
- a boot-validated, `:persistent_term`-cached `Mailglass.Config.schema/0` accessor,
- a shared `Mailglass.Identifier` validator (promoted from the private
  `Migrations.Postgres.validate_identifier!/2`), and
- the identical contract mirrored on `config :mailglass_inbound, :schema`.

**Pure additive — ZERO runtime behavior change.** The `Mailglass.Repo` facade is NOT
wired in this phase (that is Phase 133); no `prefix:` is injected into any read/write/DDL
yet. Downstream (133+) reads `Config.schema/0` and validates through `Mailglass.Identifier`.

**Scope is fixed by ROADMAP §Phase 132 + the LOCKED dossier §5 Phase A.** Discussion
here clarifies HOW to build the four requirements, never WHETHER to add new capability.

**Requirements:** SCHEMA-01, SCHEMA-02, SCHEMA-03, SCHEMA-04.
</domain>

<decisions>
## Implementation Decisions

### Area 1 — Config key + hot-path accessor caching (SCHEMA-01, SCHEMA-02)

- **D-01:** Add `:schema` to the `Mailglass.Config` NimbleOptions `@schema`:
  `type: :string`, `default: "mailglass"`, `doc:` explaining it names the Postgres
  SCHEMA holding all mailglass domain tables and that `"public"` is the explicit
  pre-2.0 opt-out (verbatim shape from dossier §3.1). Must be a valid unquoted
  Postgres identifier.

- **D-02:** `Mailglass.Config.schema/0` reads from `:persistent_term` key
  `{Mailglass.Config, :schema}` — a bare, zero-copy pointer read on the hot path
  (the facade calls it on every delegated DB op in Phase 133+). Mirrors the existing
  `:theme` cache (`config.ex:544` / `get_theme/0:630`).

- **D-03:** **Boot-warm PLUS self-healing lazy backfill.** `validate_at_boot!/0`
  validates the schema once and `:persistent_term.put`s the *validated* string
  (alongside the existing `:theme` put). On a **cold miss** (unit tests / `iex`
  without full app boot), the accessor uses a **sentinel** (e.g. `:__miss__`) — NOT
  a silent default — and self-heals: read `Application.get_env(:mailglass, :schema,
  "mailglass")` → `Identifier.validate!` → `:persistent_term.put` → return.
  - **Why sentinel, not `get/2` default:** a silent `"mailglass"` default would mask
    an adopter's `config :mailglass, :schema, "public"` opt-out in a boot-skipped
    context and split reads/writes across two schemas (silent cross-schema
    corruption). The `get_theme/0` empty-default idiom is UNSAFE to copy here.

- **D-04:** **Validate ONCE, at the cache-write boundary — never per read.** This
  **supersedes the dossier §3.1 sketch**, which calls `Identifier.validate!` inside
  `schema/0` on every invocation (a regex match on the library's hottest path). Both
  the boot-warm path and the lazy-backfill path validate before caching; hot reads
  are a pure `:persistent_term.get`.

- **D-05:** **No cache invalidation / no `config_change/3` handler.** `:schema` is a
  boot-time constant for the node's life (changing it mid-run would strand tables in
  the old schema). A stale-forever cache is the *correct* behavior. Do NOT lazy-`put`
  on every miss or per op — `:persistent_term.put/2` triggers a global GC scan;
  writes must be boot-once + at-most-once-per-boot-skipped-context.

### Area 2 — `Mailglass.Identifier` module shape + single-source refactor (SCHEMA-03)

- **D-06:** NEW `lib/mailglass/identifier.ex` is the single source of truth for
  Postgres unquoted-identifier validation, holding the regex
  `~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/` (keep `\A...\z`, not `^...$`).

- **D-07:** `validate!(value, key)` **returns the validated string** (not `:ok`, not
  `{:ok, _}`) so call-sites pipe: `Application.get_env(...) |> Identifier.validate!(:schema)`.
  This supersedes the two-statement `validate!(s, :schema); s` sketch in §3.1 — update
  that call-site to pipe. (The old private return was `:ok` but unobserved, so no break.)
  `@spec validate!(String.t(), atom()) :: String.t()`, `@doc since: "2.0.0"`.

- **D-08:** **Keep raising `Mailglass.ConfigError.new(:invalid, context: %{key:, reason:})`**
  — do NOT introduce an `IdentifierError`. The `:invalid` atom on `ConfigError` is the
  documented, closed contract for "config value present but bad" (`docs/api_stability.md`;
  `lib/mailglass/errors/config_error.ex`). A bad schema name IS that case; a new struct
  would expand the closed `Mailglass.Error` union for zero adopter benefit and break the
  migration's byte-identical behavior. Semantic clarity comes via `context.key` /
  `context.reason`, never the message string.

- **D-09:** **Single bang function only** — do NOT add `valid?/1` or a non-bang
  `validate/2`. Both call-sites (config-boot + migration) want fail-fast raising.
  YAGNI on a closed public API surface; add a predicate later as a non-breaking minor
  IF a UI/test caller ever materializes.

- **D-10:** **ADD a 63-byte NAMEDATALEN length guard.** Postgres silently truncates
  identifiers over 63 bytes (an aliasing/correctness hazard, not just cosmetic). Reject
  `byte_size(value) > 63` with the same `ConfigError.new(:invalid, ...)`. This is
  strictly *stricter* — it can only reject inputs the old regex accepted; no legitimate
  schema name approaches 63 bytes. Keep the non-binary clause raising `ConfigError` too.

- **D-11:** Refactor `Migrations.Postgres.validate_identifier!/2`
  (`lib/mailglass/migrations/postgres.ex:121-140`) to a **one-line delegate**:
  `defp validate_identifier!(value, key), do: Mailglass.Identifier.validate!(value, key)`,
  and drop the module-local `@identifier_regex`. The migration call-site
  (`postgres.ex:106`) discards the return inside a `then/2` returning `o`, so the
  `:ok`→string change is invisible; the raised error stays byte-identical. Only
  behavioral delta anywhere: the new over-63-byte rejection, inherited for free.

### Area 3 — Inbound mirror on its own line (SCHEMA-04)

- **D-12:** Add `:schema` to `MailglassInbound.Config` NimbleOptions `@schema`
  (`type: :string`, default `"mailglass"`, same `doc` intent), read from
  `:mailglass_inbound` app env only (boundary law — never `:mailglass`).

- **D-13:** **REUSE `Mailglass.Identifier.validate!/2` from core** — do NOT duplicate
  the regex or introduce an inbound-local error. Inbound already raises
  `Mailglass.ConfigError` pervasively (ingress plug + all four provider verifiers) and
  already hard-depends on core at runtime, so this adds no new coupling axis. Gives one
  regex + one error type (`%Mailglass.ConfigError{type: :invalid}`) across the family
  (Oban Web/Pro reuse Oban core validators the same way).

- **D-14:** `MailglassInbound.Config.schema/0` uses the SAME persistent_term +
  self-healing lazy-backfill pattern (key `{MailglassInbound.Config, :schema}`, sentinel
  on miss, validate-once-then-cache). **Only `:schema` is cached** — `retention/0` and
  `rate_limit/0` stay on their existing uncached `validated/0` path (cold-path; not hot).
  This intentional divergence from a "cache everything" mirror is correct.

- **D-15:** **Wire `MailglassInbound.Config.validate_at_boot!()` into inbound's
  `application.ex` `start/2`** (as the first statement, before children). This fixes the
  pre-existing gap: inbound's `validate_at_boot!/0` is defined (`config.ex:104`) but
  currently NEVER called. It now also validates + warms the `:schema` persistent_term
  (mirroring core warming `:theme`). Gives fail-fast on a bad identifier + a warm cache.
  `:schema` is inbound's OWN app env, so inbound's `start/2` is the correct owner (the
  old "not called automatically" moduledoc note was about `retention`/`rate_limit`, which
  the host reads on demand — leave those callable-on-demand).

### Family coherence — MUST stay identical across core + inbound
Accessor name `schema/0`; default `"mailglass"`; validation via shared
`Mailglass.Identifier.validate!/2` (same regex + 63-byte guard); error type
`%Mailglass.ConfigError{type: :invalid}`; cache mechanism + key shape
`:persistent_term` keyed `{Module, :schema}` with sentinel-miss self-heal; validate
once at cache boundary.

### Claude's Discretion
- Exact sentinel atom name (`:__miss__` / `:__unset__`) and private helper naming
  (`warm_schema/0`) — planner's choice, keep consistent across both packages.
- Whether the boot-warm reads the already-NimbleOptions-validated value vs re-reads env
  (recommend: cache the validated value from the boot pipeline so boot and cache can
  never disagree; lazy path re-reads env only because boot hasn't run there).

### Folded Todos
None.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/milestone-schema-isolation/SCHEMA-ISOLATION-DESIGN.md` — the
  LOCKED design dossier. For this phase: §0 (locked shape), §1 (Ecto/Postgres decision
  table — the `@schema_prefix` rejection + runtime-prefix rationale), §3.1 (Config API —
  NOTE D-04/D-07 supersede its per-read `validate!` sketch and two-statement call-site),
  §5 Phase A, §6 (footguns 5, 6, 13), §7 (diff surface).
- `.planning/REQUIREMENTS.md` — SCHEMA-01..04 acceptance criteria.
- `lib/mailglass/config.ex` — `@schema` (l.4+), `validate_at_boot!/0` (l.525), `:theme`
  persistent_term cache (l.544), `get_theme/0` (l.630) — the template to adapt (with the
  D-03 unsafe-empty-default caveat).
- `lib/mailglass/migrations/postgres.ex` l.118-141 — `@identifier_regex` + private
  `validate_identifier!/2` to promote/delegate (l.106 call-site).
- `lib/mailglass/errors/config_error.ex` + `docs/api_stability.md` — the closed
  `ConfigError` `:type` atom contract (`:invalid`) that D-08 preserves.
- `mailglass_inbound/lib/mailglass_inbound/config.ex` — `@schema`, `validate_at_boot!/0`
  (l.103, currently uncalled), private `validated/0` (l.165), NO persistent_term today.
- `mailglass_inbound/lib/mailglass_inbound/application.ex` — `start/2` to wire boot
  validation into (D-15).
- `mailglass_inbound/docs/api_stability.md` — inbound error/config contract to keep aligned.
- `prompts/` — engineering-DNA + "errors as a public API contract" + hot-path/boot-validation
  conventions inherited from the 4 prior shipped libs.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`:theme` persistent_term pattern** (`config.ex:544` + `get_theme/0:630`) — the
  direct template for the `:schema` cache, with the D-03 caveat that its empty-`[]`
  cold-miss default is UNSAFE to copy verbatim (schema needs sentinel-miss self-heal).
- **`Migrations.Postgres.validate_identifier!/2`** (`postgres.ex:121-140`) — the exact
  regex + `ConfigError` raise being promoted into `Mailglass.Identifier` (D-06/D-11).
- **`Mailglass.ConfigError.new(:invalid, context:)`** (`lib/mailglass/errors/config_error.ex`)
  — reused unchanged by the promoted validator AND by inbound (already used pervasively).
- **`Mailglass.Config.validate_at_boot!/0`** (`config.ex:525`) — extend to warm the
  `:schema` cache; already called from `Mailglass.Application.start/2` (`application.ex:9-10`).
- **`MailglassInbound.Config.validate_at_boot!/0`** (`config.ex:103`) — exists but is
  never invoked; D-15 wires it into inbound `application.ex`.

### Established Patterns
- NimbleOptions `@schema` declared BEFORE `@moduledoc` (both packages) — add `:schema`
  key there so `NimbleOptions.docs/1` renders it.
- Boot-time fail-fast validation with typed `ConfigError` (errors-as-contract DNA).
- "Don't use `Application.compile_env*` outside `Mailglass.Config`" — runtime read only.
- Sibling packages depend on core's error contract (inbound already imports it).

### Integration Points
- `Config.schema/0` is the value the Phase 133 `Mailglass.Repo.put_prefix/1`
  (`Keyword.put_new(opts, :prefix, Config.schema())`) will consume — this phase must
  make it correct + O(1) before the facade is wired.
- `Mailglass.Identifier` becomes the shared guard both config-boot (this phase) and the
  Phase 134 `CREATE SCHEMA`/migration path call.
- Inbound's core dep floor rises to `>= 2.0` because `Mailglass.Identifier` is net-new
  in core 2.0 — a Phase 137 release/pin concern, NOT a blocker for this design (dev build
  uses `path: ".."` override).
</code_context>

<specifics>
## Specific Ideas

- Accessor sketch (locked shape, both packages):
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
- `Mailglass.Identifier.validate!/2` returns the string, adds the 63-byte guard, keeps
  the non-binary + regex-fail `ConfigError` clauses (D-07/D-08/D-10).
- Verification for this phase = config unit tests (core + inbound) + `mix credo`, asserting
  ZERO runtime behavior change (facade unwired).
</specifics>

<deferred>
## Deferred Ideas

- Facade `put_prefix/1` + `multi_opts/1` threading → Phase 133 (FACADE-*).
- `CREATE SCHEMA`/migration entrypoint + raw-DDL trigger qualification → Phase 134 (MIGR-*).
- Inbound facade + migration-dispatcher conversion → Phase 135 (INB-*).
- Non-raising `Identifier.valid?/1` / `validate/2` — only if a real caller appears (D-09).

### Reviewed Todos (not folded)
- `2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes` (match score 0.6) —
  a release/tooling advisory concern, orthogonal to the config foundation. Belongs to a
  release/hygiene pass, not Phase 132.
</deferred>
