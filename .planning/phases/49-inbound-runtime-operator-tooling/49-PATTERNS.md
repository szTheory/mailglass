# Phase 49: Inbound Runtime Operator Tooling - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 25 (10 new, 15 modified)
**Analogs found:** 25 / 25 (every new file has a verified outbound clone source; every modified file has the live target read in-session)

> This is a deliberately clone-heavy phase. Five of six deliverables are near-direct clones of a shipped outbound/core module, adapted for inbound. The CONTEXT/RESEARCH pre-named nearly every analog; this map **verifies each analog path against the live tree (2026-05-25)** and extracts the concrete excerpt + the precise delta to apply. All new-file paths were confirmed **absent** today; all analog + modified-target paths were confirmed **present** with the line counts in the Metadata section.

---

## File Classification

### New files

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mailglass_inbound/lib/mailglass_inbound/config.ex` | config | request-response (boot read) | `lib/mailglass/config.ex` | role-match (style-mirror; different app env) |
| `mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex` | utility | transform | `lib/mailglass/deliverability/formatter.ex` | exact |
| `mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex` | service | request-response (gate) | `lib/mailglass/rate_limiter.ex` | exact (clone, drop deltas) |
| `mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex` | provider (ETS owner) | event-driven (init-and-idle) | `lib/mailglass/rate_limiter/table_owner.ex` | exact (verbatim, rename table) |
| `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` | service | batch (reflection checks) | `lib/mailglass/deliverability.ex` (runner) + `Router.Matcher` (reuse) | role-match (DNS-free; novel checks) |
| `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex` | service | batch (DB delete) | `lib/mailglass/webhook/pruner.ex` (`prune/0` core) | role-match (mirror structure, upgrade to batched) |
| `mailglass_inbound/lib/mailglass_inbound/prune/worker.ex` | service (Oban worker) | event-driven (cron) | `lib/mailglass/webhook/pruner.ex` (Oban-guard wrapper) | exact (guard shape) |
| `mailglass_inbound/lib/mailglass_inbound/inbound_message/signals.ex` (or inline in `inbound_message.ex`) | model (typed nested struct) | transform (projection target) | `Ecto.Schema.Metadata` archetype (external); `lib/mailglass/message.ex` (anti-analog for `:metadata`) | role-match (novel public contract) |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` | route (CLI shell) | request-response | `lib/mix/tasks/mail.doctor.ex` | exact (clone; three-state exit delta) |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` | route (CLI shell) | batch (selector → iterate) | `lib/mix/tasks/mail.doctor.ex` (shell) + `lib/mix/tasks/mailglass.webhooks.prune.ex` (confirm tier) | role-match |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex` | route (CLI shell) | request-response | `lib/mix/tasks/mailglass.webhooks.prune.ex` | exact (clone; run-without-Oban delta) |
| `mailglass_inbound/priv/repo/migrations/*_add_suppression_flagged.exs` | migration | DDL | inbound `..._create_mailglass_inbound_storage_foundation.exs` (style) | role-match |

### Modified files (extend, do not rewrite)

| Modified File | Role | Data Flow | Insertion Point (verified line) |
|---------------|------|-----------|----------------|
| `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` | controller | request-response | top of `persist_and_respond/5`, after `tenant_id = resolve_tenant!(...)` (line 180) |
| `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | service | CRUD | `insert_record/4` attrs map (lines 219-238) |
| `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex` | model | CRUD | add field after line 57; add to `@cast` line 66-68 (NOT `@required` line 65) |
| `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` | model | transform | add `:signals` to `@type` (line 40-58) + `defstruct` (line 60-78); add `suppression_flagged?/1` |
| `mailglass_inbound/lib/mailglass_inbound/execution.ex` | service | transform | `message_from_record/1` struct literal (lines 99-119) |
| `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` | service | CRUD (read) | `select/2` map (lines 56-68) |
| `mailglass_inbound/lib/mailglass_inbound/router/route.ex` | model | n/a | `@type` (line 7-12) + `defstruct` (line 14) |
| `mailglass_inbound/lib/mailglass_inbound/router.ex` | utility (macro) | n/a | `route/2` macro body (lines 48-62) |
| `mailglass_inbound/lib/mailglass_inbound/telemetry.ex` | utility | event-driven | whitelist docstring (lines 37-44) + new span helpers (after line 123) |
| `mailglass_inbound/lib/mailglass_inbound/application.ex` | config (supervisor) | n/a | `children` list (lines 13-15) |

---

## Pattern Assignments

### `mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex` (utility, transform)

**Analog:** `lib/mailglass/deliverability/formatter.ex` — EXACT structural clone.

**Public surface to mirror** (`formatter.ex:8-22`):
```elixir
@spec render_human(Result.t(), keyword()) :: String.t()
def render_human(result, opts \\ []) when is_map(result) and is_list(opts) do
  verbose? = Keyword.get(opts, :verbose?, false)
  # summary line + per-section finding render, joined with "\n\n"
end

@spec render_json(Mailglass.Deliverability.Result.t()) :: String.t()
def render_json(result) when is_map(result) do
  Jason.encode!(result)
end
```

**Per-finding human render to copy** (`formatter.ex:46-61`) — note the `[status] title / Why it matters / Observed / Remediation` shape and the `verbose? and Map.has_key?(finding, :evidence)` evidence gate:
```elixir
defp render_finding(finding, verbose?) do
  base_lines = [
    "[#{finding.status}] #{finding.title}",
    "Why it matters: #{finding.why_it_matters}",
    "Observed: #{finding.observed}",
    "Remediation: #{finding.remediation}"
  ]
  case verbose? and Map.has_key?(finding, :evidence) do
    true -> base_lines ++ ["Evidence: " <> inspect(finding.evidence, pretty: true, limit: :infinity)]
    false -> base_lines
  end
end
```

**Deltas to apply:**
- D-49-05 finding shape is `%{check, status, title, observed, remediation, evidence}` (no `:why_it_matters`, no `:area`). Adjust `render_finding/2` field names accordingly; keep the `[status] title` first-line convention and the verbose evidence gate verbatim.
- `render_json/1` emits the locked one-object shape `%{summary: %{pass, warn, fail}, findings: [...]}` (D-49-05) — `Jason.encode!/1` on that map; do NOT encode a bare list.
- `summary_line/1` (`formatter.ex:24-28`) — adapt to `"N pass, N warn, N fail"` (drop `cannot_verify`; doctor models cannot-diagnose as exit code 2, not a finding tally column — see doctor task).
- Section grouping (`@section_order` at `formatter.ex:6`) — the doctor's findings group by `:check` not by DNS area; either drop sectioning (flat list) or group by a `:group` key. Planner discretion (D-49 §Discretion: exact formatter signatures).

---

### `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` (route/CLI, request-response)

**Analog:** `lib/mix/tasks/mail.doctor.ex` — clone the shell; **the exit model is the critical delta**.

**Shell to copy** (`mail.doctor.ex:23-35`):
```elixir
def run(argv) do
  {opts, rest, invalid} =
    OptionParser.parse(argv, strict: [domain: :string, dkim_selector: :keep, verbose: :boolean, format: :string])
  validate_cli!(opts, rest, invalid)
  Mix.Task.run("app.start")
  # delegate → format → emit
end
```

**`validate_cli!/3` to copy** (`mail.doctor.ex:54-81`) — rejects positional args, unknown options, and validates the `--format` allowlist with `Mix.raise`:
```elixir
defp validate_cli!(opts, rest, invalid) do
  if rest != [], do: Mix.raise("... unexpected positional arguments #{Enum.join(rest, " ")}")
  if invalid != [] do
    invalid_flags = invalid |> Enum.map(fn {k, _} -> "--#{k}" end) |> Enum.join(", ")
    Mix.raise("... unknown option(s) #{invalid_flags}")
  end
  format = Keyword.get(opts, :format, "human")
  unless format in ["human", "json"], do: Mix.raise("... invalid format #{inspect(format)}")
  :ok
end
```

**Format dispatch to copy** (`mail.doctor.ex:90-95`):
```elixir
defp render_output(result, opts) do
  case Keyword.get(opts, :format, "human") do
    "json" -> Formatter.render_json(result)
    "human" -> Formatter.render_human(result, verbose?: opts[:verbose] == true)
  end
end
```

**CRITICAL DELTA — three-state exit (D-49-05, RESEARCH Pitfall 6):** `mail.doctor.ex` uses `Mix.raise` for *both* CLI misuse AND check failures (`:43-51`), collapsing everything to exit 1. The inbound doctor MUST:
- Keep `Mix.raise` (via `validate_cli!/3`) for **CLI misuse only** (bad flags / positional / `--format`).
- For **findings**, inspect the summary tally and call `exit({:shutdown, N})` with `N ∈ {0,1,2}`:
  - `0` = all pass (or pass+warn without `--strict`)
  - `1` = ≥1 `fail` (or any `warn` under `--strict`) — the CI-gate signal
  - `2` = cannot-diagnose (no router configured / app failed to boot)
- `strict:` keyword for `OptionParser.parse/2` becomes `[format: :string, strict: :boolean, verbose: :boolean]`.
- Brand-voice prefix: "Inbound doctor blocked: ..." for misuse (mirror `mail.doctor`'s "Deliverability doctor blocked:").

**`exit({:shutdown, N})` precedent** (`mailglass.webhooks.prune.ex:54`) — this is the in-repo idiom for a non-zero CLI exit without a stacktrace.

---

### `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` (service, batch)

**Analog (structure):** a check-runner returning the locked finding list + summary (no shipped 1:1 clone — `Mailglass.Deliverability.run/1` is the conceptual sibling). **Analog (route-conflict semantics): REUSE, do not re-implement.**

**Route-conflict detection MUST reuse `MailglassInbound.Router.Matcher.matches_route?/2`** (`router/matcher.ex:30-35`) — the single source of truth:
```elixir
@spec matches_route?(Route.t(), InboundMessage.t()) :: boolean()
def matches_route?(%Route{} = route, %InboundMessage{} = message) do
  matches_matcher?(route.recipient, message.envelope_recipient) and
    matches_matcher?(route.subject, message.subject) and
    matches_headers?(route.headers, message.headers)
end
```
`Matcher.explain/2` (`router/matcher.ex:57-76`) is also available for per-clause verdicts if useful in finding evidence.

**Route reflection source:** read routes via `router.__mailglass_inbound_routes__/0` (`router.ex:64-72`) — pass the router module via an opt so the doctor reflects a fixture router in tests (RESEARCH §Per-deliverable validation 1).

**Match-primitive semantics to respect** (`router/matcher.ex:86-89`) — these define what "broad" means for subsumption:
```elixir
defp matches_matcher?(nil, _value), do: true            # nil matcher = wildcard/catch-all
defp matches_matcher?(_matcher, nil), do: false
defp matches_matcher?(%Regex{} = m, v) when is_binary(v), do: Regex.match?(m, v)
defp matches_matcher?(m, v) when is_binary(m) and is_binary(v), do: m == v
```

**Checks (all DNS-free, D-49-06):** router configured + compiles (→ exit 2 if absent); ≥1 route; per route `Code.ensure_compiled!/1` + `function_exported?(mod, :process, 1)`; signing keys present (read the same `:mailglass_inbound` config the plug reads — NEVER verify a signature); MIME backend via the gen_smtp pattern below.

**Conflict strategy (D-49-07):** (a) structural subsumption — earlier `nil`/broader matcher preceding a narrower one → `fail`; (b) witness-probe — synthesize an `%InboundMessage{}` from a later route's exact-string matchers, run the earlier route's `matches_route?/2`; if it matches, the later route is shadowed → `fail`; (c) regex-vs-regex overlap is undecidable → `warn`. Conflict findings name `router.ex:12` using the new `Route.:source` field (D-49-08).

**Building witness messages:** `%InboundMessage{}` defaults make this safe (`inbound_message.ex:60-78`): `from/to/cc/bcc/reply_to: []`, `headers: %{}`, `attachments: []`; set `envelope_recipient`/`subject`/`headers` from the later route's matchers.

---

### `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex` (service, batch)

**Analog:** `lib/mailglass/webhook/pruner.ex` — mirror the **structure** (`:infinity` disable, telemetry shape, public `prune/0`), **upgrade** the unbounded delete to batched.

**`:infinity`-disables-a-window pattern to copy** (`pruner.ex:91`):
```elixir
defp prune_status(_status, :infinity), do: {:ok, 0}   # returns 0 WITHOUT issuing the DELETE
```

**The unbounded delete to UPGRADE (anti-pattern for inbound)** (`pruner.ex:93-105`) — copy the cutoff-math shape, replace the `Repo.delete_all` body with the batched idiom:
```elixir
defp prune_status(status, days) when is_atom(status) and is_integer(days) and days > 0 do
  cutoff = DateTime.add(Clock.utc_now(), -days * 86_400, :second)
  {count, _} = Repo.delete_all(from(w in WebhookEvent, where: w.status == ^status and w.inserted_at < ^cutoff))
  {:ok, count}
end
```

**Batched idiom to introduce (NEW in repo, D-49-27)** — `LIMIT 1000` + `FOR UPDATE SKIP LOCKED`, looped until affected `< 1000`, the whole sweep wrapped in a session `pg_try_advisory_lock` (bail `{:ok, :locked_out}` if not acquired). See RESEARCH §Pattern 6 (lines 413-466) for the concrete `Stream.repeatedly` + `Enum.reduce_while` loop and the advisory-lock wrapper. `[VERIFIED: grep]` no `FOR UPDATE SKIP LOCKED` or advisory-lock usage exists in the tree today.

**Window split (D-49-25) — three physical tables, child-first delete order (D-49-26):**
1. `mailglass_inbound_replay_runs` WHERE `source = :replay` AND age > replay_runs_days (30d)
2. `mailglass_inbound_replay_runs` WHERE `source = :fresh` AND age > execution_runs_days (90d)
3. `mailglass_inbound_evidence` WHERE age > evidence_days (30d)
4. `mailglass_inbound_records` WHERE age > records_days (90d)

**CRITICAL — filter `source` via `ExecutionRun`, NEVER `ReplayRun` (D-49-25, Pitfall 4):** both schemas map `mailglass_inbound_replay_runs`, but only `ExecutionRun` declares the `source` column.
- `ExecutionRun` HAS `field :source, Ecto.Enum, values: [:fresh, :replay]` (`execution_run.ex:40`).
- `ReplayRun` has NO `:source` field (`replay_run.ex:37-51`) — `from(r in ReplayRun, where: r.source == :replay)` is a compile-time field error.

**Telemetry (D-49-29):** `[:mailglass_inbound, :prune, :stop]` with `%{records_deleted, evidence_deleted, fresh_runs_deleted, replay_runs_deleted, status}` (counts only). Mirror the webhook emit shape (`pruner.ex:107-115`).

**FKs are `on_delete: :nothing`** (storage_foundation migration) — a mis-ordered delete fails loudly on the FK; that is the designed safety net (D-49-26). Do NOT switch to CASCADE.

---

### `mailglass_inbound/lib/mailglass_inbound/prune/worker.ex` (Oban worker)

**Analog:** `lib/mailglass/webhook/pruner.ex` top-of-file conditional-compile guard.

**Guard shape to copy** (`pruner.ex:1` + `:117-130`):
```elixir
if Code.ensure_loaded?(Oban.Worker) do
  defmodule MailglassInbound.Prune.Worker do
    use Oban.Worker, queue: :mailglass_inbound_maintenance
    @spec available?() :: true
    def available?, do: true
    @impl Oban.Worker
    def perform(_job), do: ... MailglassInbound.Internal.Prune.prune() ...
  end
else
  defmodule MailglassInbound.Prune.Worker do
    @spec available?() :: false
    def available?, do: false
  end
end
```

**Deltas:**
- `perform/1` just calls `Internal.Prune.prune/0` (the workhorse lives in `Internal.Prune`, not the worker — D-49-28).
- Gate the worker through `MailglassInbound.OptionalDeps.Oban` (`optional_deps.ex:12-71`) rather than a bare `Oban` reference where possible; the file-top `if Code.ensure_loaded?(Oban.Worker)` is the established exception.
- **Never auto-register the cron** (D-49-28); document `0 3 * * *` in Phase 50. Mirror the boot-warning, not auto-registration — see Shared Patterns § Oban-absent boot warning.

---

### `mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex` (route/CLI)

**Analog:** `lib/mix/tasks/mailglass.webhooks.prune.ex` — clone, **upgrade the Oban gate**.

**The exits-1-when-Oban-absent anti-pattern to UPGRADE** (`mailglass.webhooks.prune.ex:44-55`):
```elixir
if Mailglass.Webhook.Pruner.available?() do
  {:ok, %{succeeded: s, dead: d}} = Mailglass.Webhook.Pruner.prune()
  Mix.shell().info("...")
else
  Mix.shell().error("... Oban not available ...")
  exit({:shutdown, 1})
end
```

**Delta (D-49-28):** the inbound prune task runs `Internal.Prune.prune/0` **synchronously whether or not Oban is present** — only *scheduling* needs Oban; the batched sweep is the workhorse. So there is NO `available?()` gate around the call; drop the `else exit({:shutdown, 1})` branch entirely.

**Destructive-confirmation tier (D-49-10, stronger than replay):** `--dry-run` (report scope + count, no delete) + a typed confirmation above a row-count threshold + `--yes`/`-y` for cron/CI. Use `Mix.shell().yes?/1` for the simple prompt and `Mix.shell().prompt/1` for the typed confirmation. The `@prune_lock_key` constant + the typed-confirmation threshold are planner discretion (D-49 §Discretion).

---

### `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` (route/CLI, batch)

**Analog (shell):** `lib/mix/tasks/mail.doctor.ex` (OptionParser strict + validate_cli! + `Mix.Task.run("app.start")`). **Analog (confirm tier):** `Mix.shell().yes?/1`.

**Reuses the shipped single-record service unchanged** (`internal/replay.ex:13-28`):
```elixir
@spec replay(Ecto.UUID.t(), keyword()) :: {:ok, map()} | {:error, term()}
def replay(inbound_record_id, opts \\ []) when is_binary(inbound_record_id) and is_list(opts) do
  # loads record + evidence + resolves mailbox, then execution.execute(payload, source: :replay)
end
```

**Deltas (D-49-09):** `Internal.Replay.replay/2` STAYS single-record (do not widen). The task resolves `--record-id` / `--since <iso8601>` / `--tenant <id>` (AND-combinable) into an id list via a small selection query (`from(r in InboundRecord, where: ...)`, parameterized — never interpolate selectors), then iterates `replay/2` per id. `[y/N]` defaulting **No** via `Mix.shell().yes?/1`; `--yes`/`-y` skips the prompt (never removes it). Zero matches → exit `0` with "nothing to replay." `--dry-run` reports count + scope with no change. Replay is non-destructive (appends `ExecutionRun` with `source: :replay`) → `[y/N]` tier suffices (lighter than prune).

---

### `mailglass_inbound/lib/mailglass_inbound/config.ex` (config)

**Analog:** `lib/mailglass/config.ex` — mirror the **style** (NimbleOptions `@schema` declared before `@moduledoc`, `validate_at_boot!/0`), NOT the content. Reads the **`:mailglass_inbound`** app env (D-49-02).

**`validate_at_boot!/0` style to mirror** (`config.ex:524-552`):
```elixir
@spec validate_at_boot!() :: :ok
def validate_at_boot! do
  known_keys = Keyword.keys(@schema)
  opts =
    :mailglass                                  # ← inbound clone uses :mailglass_inbound
    |> Application.get_all_env()
    |> Keyword.take(known_keys)
    |> normalize_optional_keyword_subtrees()
  validated = opts |> NimbleOptions.validate!(@schema) |> ...
  :ok
end
```

**Schema-before-moduledoc convention** (`config.ex:1-4`):
```elixir
defmodule Mailglass.Config do
  # Schema is declared BEFORE @moduledoc so NimbleOptions.docs(@schema) can
  # interpolate into the module documentation.
  @schema [ ... ]
```

**Deltas (D-49-02/03):**
- Reads `Application.get_all_env(:mailglass_inbound)` (NOT `:mailglass`). Do NOT add inbound keys to core `Mailglass.Config` — that inverts the package dependency (boundary law).
- Locked config key shape: `retention: [records_days: 90, evidence_days: 30, execution_runs_days: 90, replay_runs_days: 30]` + `rate_limit: [tenant: [...], sender_domain: [...], recipient: [...]]`. `:infinity` valid on any retention class.
- NimbleOptions type for retention classes: `{:or, [:non_neg_integer, {:in, [:infinity]}]}` (planner discretion on exact schema field names — D-49 §Discretion).
- Honest-surface: ship ONLY the knobs the runtime reads (no speculative per-tenant override maps; core's `:overrides` keyword tree at `config.ex` is NOT carried over).

---

### `mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex` + `rate_limiter/table_owner.ex` (service + ETS owner)

**Analog:** `lib/mailglass/rate_limiter.ex` + `lib/mailglass/rate_limiter/table_owner.ex` — clone the leaky-bucket math VERBATIM; drop the `%Message{}`/`:transactional` coupling.

**The load-bearing ETS update to copy verbatim** (`rate_limiter.ex:109-141`):
```elixir
defp check_bucket(type, sub_key) do
  {capacity, refill_per_ms} = limits_for(type, sub_key)
  key = {type, sub_key}
  now_ms = System.monotonic_time(:millisecond)
  :ets.insert_new(@table, {key, capacity, now_ms})            # first-hit seed
  [{^key, tokens, last}] = :ets.lookup(@table, key)
  restore = if tokens < 0, do: abs(tokens), else: 0
  elapsed_ms = max(0, now_ms - last)
  refilled = round(elapsed_ms * refill_per_ms)
  total_add = min(restore + refilled, capacity - tokens)
  result =
    :ets.update_counter(@table, key,
      [{2, total_add, capacity, capacity}, {3, 0, 0, now_ms}, {2, -1}],
      {key, capacity, now_ms})
  case result do
    [_refilled, _ts, new_tokens] when new_tokens >= 0 -> :ok
    _ -> {:error, refill_per_ms}
  end
end
```

**The multi-bucket `with` chain to adapt** (`rate_limiter.ex:69-92`) — copy the fail-fast `with` + error-build shape, change the bucket set and order:
```elixir
with :ok <- check_bucket(:tenant_recipient, {msg.tenant_id, recipient_domain}),
     :ok <- check_bucket(:global_recipient, recipient_domain),
     :ok <- check_bucket(:sender_domain, sender_domain) do
  ...; :ok
else
  {:error, refill_per_ms} ->
    ms = retry_after_ms(refill_per_ms)
    {:error, RateLimitError.new(:per_domain, retry_after_ms: ms, context: %{...})}
end
```

**ETS opts to copy verbatim** (`table_owner.ex:46-54`) — rename ONLY the table:
```elixir
:ets.new(@table, [           # @table = :mailglass_inbound_rate_limit (was :mailglass_rate_limit)
  :set, :public, :named_table,
  read_concurrency: true, write_concurrency: :auto, decentralized_counters: true
])
```

**`start_link/init` + LINT-07 allowlist note to copy** (`table_owner.ex:34-62`) — the `name: __MODULE__` singleton is the documented LIB-05 exception; the inbound TableOwner needs the same `api_stability.md` note + `NoDefaultModuleNameSingleton` allowlist entry.

**Deltas (D-49-11/12/13):**
- **DROP the `:transactional` bypass clause** (`rate_limiter.ex:57-60`) entirely — inbound has no stream semantics.
- **DROP `%Mailglass.Message{}` coupling** — no `check(%Message{})` head, no `extract_recipient_domain/extract_sender_domain` from swoosh (`rate_limiter.ex:191-217`). The inbound limiter takes plain args (e.g. `check(tenant_id, recipient_addr, sender_domain)` — exact signature is discretion, D-49 §Discretion).
- **Bucket set + order:** tenant (1000/min) → recipient (500/min) → sender_domain (200/min), fail-fast. The tripped bucket returns ITS OWN `refill_per_ms` → `Retry-After`; do NOT compute a cross-bucket max (D-49-13).
- **Reuse only the `Mailglass.RateLimitError` struct** (`errors/rate_limit_error.ex`) — build it internally; `:per_tenant` / `:per_domain` cover the buckets (`rate_limit_error.ex:26`: `@types [:per_domain, :per_tenant, :per_stream]`).
- **PII (D-49-16):** sender bucket keyed on domain only; recipient bucket may key on full address (node-local ETS, never logged) — add the code comment citing D-49-16 so a lint pass doesn't false-positive (mirror `rate_limiter.ex:43` PII comment).
- **Reads `:mailglass_inbound` config** (via `MailglassInbound.Config`), NOT `:mailglass` (`rate_limiter.ex:163` reads `:mailglass`).
- **Config-getter (`limits_for/2`, `get_config/0`) — simplify:** drop the backward-compat `:default`/`:overrides` wrapping (`rate_limiter.ex:162-174`); inbound's locked config shape has no overrides.

---

### `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` + `inbound_message/signals.ex` (model)

**Analog (archetype):** `Ecto.Schema.Metadata` / `__meta__` (framework writes, adopter reads, dialyzer-checkable). **Anti-analog:** `lib/mailglass/message.ex` `:metadata` (adopter-owned — do NOT reuse the name).

**The struct to extend** (`inbound_message.ex:40-78`) — add `:signals` to BOTH `@type t` and `defstruct`, defaulting to `%Signals{}`:
```elixir
# @type addition: signals: MailglassInbound.InboundMessage.Signals.t()
# defstruct addition: signals: %MailglassInbound.InboundMessage.Signals{}
```

**The new nested struct (D-49-21)** — every field enumerated, defaulted, non-nil:
```elixir
defmodule MailglassInbound.InboundMessage.Signals do
  @moduledoc "Framework-derived, read-only inbound signals. Framework writes; adopter reads."
  @type t :: %__MODULE__{suppression_flagged: boolean()}
  defstruct suppression_flagged: false
end
```

**One convenience predicate (D-49-22)** — `MailglassInbound.InboundMessage.suppression_flagged?/1`; do NOT mint a predicate per future signal.

**Why NOT `:metadata`:** `Mailglass.Message` reserves `:metadata` + `put_metadata/3` for adopter-owned data (`lib/mailglass/message.ex`); the domain-language doc defines Metadata = application-defined. Reusing the name for framework facts inverts its meaning framework-wide.

**Backward-compat (D-49-22, Pitfall 7):** every `Signals` field defaulted → safe dot-access (`msg.signals.suppression_flagged`) never `KeyError`, even for pre-migration records (the DB column is `NOT NULL DEFAULT false`) and hand-built test structs. `@since "1.2.0"` + CHANGELOG "Added" under `mailglass_inbound`.

---

### `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex` (model) — MODIFY

**Add the column field** after `attachments` (`inbound_record.ex:57`):
```elixir
field :suppression_flagged, :boolean, default: false
```
Add `:suppression_flagged` to the `@type t` map (line 17-38) and to `@cast` (line 66-68) — **NOT** `@required` (line 65); it is settable-at-insert with a default (D-49-20).

**Migration:** new generated migration `add :suppression_flagged, :boolean, null: false, default: false` on `mailglass_inbound_records` — `NOT NULL DEFAULT false` backfills existing rows (D-49-20). Inbound tables carry no UPDATE/DELETE trigger; the flag is set once at INSERT.

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` (service, CRUD) — MODIFY

**Insertion point: `insert_record/4` attrs map** (`persist.ex:219-238`) — thread `suppression_flagged:` into the existing attrs:
```elixir
defp insert_record(repo, tenant_id, provider, message) do
  attrs = %{
    tenant_id: tenant_id,
    provider: to_string(provider),
    # ... existing fields ...
    attachments: message.attachments
    # ADD: suppression_flagged: compute_suppression_flag(tenant_id, message)
  }
  ...
end
```

**Compute the flag (D-49-19, degrade-OPEN, RESEARCH lines 640-655):**
```elixir
defp compute_suppression_flag(tenant_id, %InboundMessage{from: from}) do
  store = Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)
  case first_from_address(from) do
    nil -> false                                   # empty/missing from → degrade OPEN
    address ->
      case store.check(%{tenant_id: tenant_id, address: String.downcase(address)}) do
        {:suppressed, _entry} -> true
        :not_suppressed -> false
        {:error, _} -> false                       # store hiccup → degrade OPEN
      end
  end
end
```

**Use the configured store `check/2` (D-49-19) — NOT the outbound facade.** The seam contract (`suppression_store.ex:44-45`):
```elixir
@callback check(lookup_key(), keyword()) ::
            {:suppressed, Entry.t()} | :not_suppressed | {:error, term()}
```
The Ecto impl downcases + tenant-scopes internally (`suppression_store/ecto.ex:49-89` via `Tenancy.scope`); the malformed-key fallback returns `{:error, :invalid_key}` (`ecto.ex:96`) → degrade OPEN. **Do NOT call `Mailglass.Suppression.check_before_send/1`** (`lib/mailglass/suppression.ex:41`) — it reads swoosh `:to` and emits *outbound* telemetry (`suppression.ex:120` `[:mailglass, :outbound, :suppression, :stop]`), wrong direction. Key = `%{tenant_id, address}` with NO `:stream` (outbound concept).

**`from` shape** (`inbound_message.ex:28-31`): list of `%{address: String.t(), name: String.t() | nil}` maps. `first_from_address/1` pulls `.address` of `List.first(from)`.

**Telemetry (D-49-23):** emit `[:mailglass_inbound, :ingress, :suppression_flag, :stop]` with `%{flagged, tenant_id, provider}` only — never the address. **No auto-bounce, no auto-suppression.**

---

### `mailglass_inbound/lib/mailglass_inbound/execution.ex` (service, transform) — MODIFY

**Insertion point: `message_from_record/1` struct literal** (`execution.ex:99-119`) — add `signals:` projection from the column:
```elixir
def message_from_record(record) do
  %InboundMessage{
    tenant_id: record.tenant_id,
    # ... existing fields ...
    attachments: record.attachments,
    # ADD:
    signals: %MailglassInbound.InboundMessage.Signals{
      suppression_flagged: record.suppression_flagged
    }
  }
end
```
This is the SINGLE projection point where the persisted column becomes the typed struct (D-49-21). For pre-migration rows the column is the DB default `false`.

---

### `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` (service, read) — MODIFY

**Insertion point: `list_records/2` select map** (`records.ex:56-68`) — add the column directly:
```elixir
|> select([rec: record], %{
  id: record.id,
  # ... existing fields ...
  outcome: subquery(latest_fresh_run_field(tenant_id, :outcome)),
  mailbox: subquery(latest_fresh_run_field(tenant_id, :mailbox))
  # ADD: suppression_flagged: record.suppression_flagged
})
```
The column is the source of truth (D-49-20); select it directly from `:rec` (no subquery needed). This is the IADM-02 read-model (D-49-20).

---

### `mailglass_inbound/lib/mailglass_inbound/router/route.ex` + `router.ex` (model + macro) — MODIFY

**`Route` struct to extend** (`route.ex:7-14`) — add `:source` `{file, line}`:
```elixir
@type t :: %__MODULE__{
        mailbox: module(),
        recipient: matcher() | nil,
        subject: matcher() | nil,
        headers: [header_match()],
        source: {String.t(), pos_integer()} | nil    # ADD
      }
defstruct [:mailbox, :recipient, :subject, :source, headers: []]   # ADD :source
```

**`route/2` macro to extend** (`router.ex:48-62`) — capture `__CALLER__.file`/`.line`:
```elixir
defmacro route(mailbox, opts) do
  expanded_mailbox = Macro.expand(mailbox, __CALLER__)
  {evaluated_opts, _binding} = Code.eval_quoted(opts, [], __CALLER__)
  validated = validate_route_opts!(expanded_mailbox, evaluated_opts)
  route = %Route{
    mailbox: expanded_mailbox,
    recipient: validated[:recipient],
    subject: validated[:subject],
    headers: validated[:headers],
    source: {__CALLER__.file, __CALLER__.line}      # ADD (D-49-08)
  }
  quote bind_quoted: [route: Macro.escape(route)] do
    @mailglass_inbound_routes route
  end
end
```
Additive, internal reflection metadata; surfaces "router.ex:12" in conflict findings (D-49-08).

---

### `mailglass_inbound/lib/mailglass_inbound/telemetry.ex` (utility, event-driven) — MODIFY

**Single-span-surface invariant** (`telemetry.ex:1-8`) — all `:telemetry.span/3`/`execute` calls live in this module; new spans go here, not at call sites. The shared `span/3` helper is at `telemetry.ex:135-145`.

**Whitelist to extend (D-49-17, Pitfall 8)** — the docstring whitelist (`telemetry.ex:37-44`) currently lists 11 keys: `provider, tenant_id, status, latency, byte_size, mailbox, candidate_count, outcome, source, operation, record_type`. Add the PII-free keys the new spans need: `bucket, limit, retry_after, flagged` + per-table prune counts (`records_deleted, evidence_deleted, fresh_runs_deleted, replay_runs_deleted`).

**New spans to add (after line 123):**
- `rate_limit_span` → `[:mailglass_inbound, :rate_limit, :stop]`, meta `%{provider, tenant_id, bucket, limit, retry_after}` (D-49-17).
- suppression-flag emit → `[:mailglass_inbound, :ingress, :suppression_flag, :stop]`, meta `%{flagged, tenant_id, provider}` (D-49-23).
- prune emit → `[:mailglass_inbound, :prune, :stop]`, per-table counts + `status` (D-49-29).

**CRITICAL (Pitfall 8):** also update the `NoPiiInTelemetry` allowlist (a Credo check spanning this module + every caller). **Validate by RUNNING credo** (`mix credo --strict` + the credo test dir), not by grep (MEMORY: validate-credo-by-running-it).

---

### `mailglass_inbound/lib/mailglass_inbound/application.ex` (supervisor) — MODIFY

**Insertion point: `children` list** (`application.ex:13-15`):
```elixir
children = [
  {Task.Supervisor, name: MailglassInbound.TaskSupervisor},
  MailglassInbound.RateLimiter.TableOwner          # ADD (D-49-11)
]
```
Add the `RateLimiter.TableOwner` child alongside `Task.Supervisor`. **Do NOT auto-register the prune Oban worker** (D-49-28). The existing `maybe_warn_fallback_mode/1` (`application.ex:20-42`) is the boot-warning pattern to mirror for the Oban-absent prune warning (see Shared Patterns).

---

## Shared Patterns

### MIME-backend report (no bare optional-dep reference) — MIME-03

**Source:** `lib/mailglass/optional_deps/gen_smtp.ex:57`
**Apply to:** `Internal.Doctor` MIME check
```elixir
backend_available? = Mailglass.OptionalDeps.GenSmtp.available?()   # Code.ensure_loaded?(:gen_smtp_client)
backend_name = "gen_smtp (:mimemail)"
backend_version =
  case Application.spec(:gen_smtp, :vsn) do
    vsn when is_list(vsn) -> List.to_string(vsn)   # ~c"1.3.0" → "1.3.0"
    _ -> nil
  end
# finding: status = if backend_available?, do: :pass, else: :warn
```
Neither `available?/0` nor `Application.spec/2` trips `NoBareOptionalDepReference` (D-49-06). Core's `Mailglass.OptionalDeps.GenSmtp` is callable from inbound (boundary law allows inbound → core).

### Oban-absent boot warning (`:persistent_term` once-per-node gate)

**Source:** `lib/mailglass/application.ex:88-111` (`maybe_warn_missing_oban_for_webhook_workers/0`) and inbound's own `application.ex:20-42` (`maybe_warn_fallback_mode/1`).
**Apply to:** the prune Oban worker (warn that scheduled pruning needs Oban; direct operators to `mix mailglass.inbound.prune`).
```elixir
already_warned? = :persistent_term.get(@warning_key, false)
cond do
  already_warned? -> :ok
  Code.ensure_loaded?(Oban.Worker) -> :ok
  true ->
    Logger.warning("[mailglass_inbound] Oban not loaded; run `mix mailglass.inbound.prune` from cron ...")
    :persistent_term.put(@warning_key, true)
    :ok
end
```

### Inbound optional-dep gateway (single file)

**Source:** `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` — `MailglassInbound.OptionalDeps.Oban` ALREADY EXISTS (`optional_deps.ex:12-71`) with `available?/0` (line 36) + `@compile {:no_warn_undefined, [Oban, Oban.Job, Oban.Worker]}` (line 30).
**Apply to:** the prune worker's Oban gating. The gateway already provides `available?/0` and `runner/0`; the worker reuses it rather than re-deriving the guard. The `ExAwsS3` sibling (`optional_deps.ex:73-168`) is the template for any new gateway if needed.

### Telemetry single-span surface + PII whitelist

**Source:** `mailglass_inbound/lib/mailglass_inbound/telemetry.ex`
**Apply to:** ALL new spans (rate_limit, suppression_flag, prune). Every span goes through this module's `span/3` helper; metadata restricted to the extended whitelist; `NoPiiInTelemetry` allowlist updated; validated by running credo.

### Non-raising `{resp, meta}` plug egress (429 branch)

**Source:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:159-161` (the `TenancyError` 422 sibling) and `:179-204` (`persist_and_respond/5`).
**Apply to:** the rate-limit 429 branch (D-49-14). Insert at the TOP of `persist_and_respond/5`, immediately after `tenant_id = resolve_tenant!(...)` (line 180) — this is post-verify (only reached on `{:ok, facts}`/bare-map after a successful verify, lines 116-122) and post-tenant. NEVER raise; return `{resp, meta}`:
```elixir
e in TenancyError ->   # ← the egress idiom to mirror
  resp = send_json(conn, 422, %{status: "tenant_unresolved", reason: Atom.to_string(e.type)})
  {resp, %{provider: provider, status: :tenant_unresolved}}
```
On trip: `put_resp_header("retry-after", Integer.to_string(retry_after_s))` + `send_json(429, %{status: "rate_limited", bucket: Atom.to_string(bucket)})` + meta `%{provider, tenant_id, status: :rate_limited, bucket, limit, retry_after}`. `Retry-After` = `max(1, ceil(err.retry_after_ms / 1000))` (Open Question 2). See RESEARCH §Pattern 4 (lines 350-384).

### Suppression check seam (tenant-scoped, downcased)

**Source:** `lib/mailglass/suppression_store.ex` (behaviour) + `lib/mailglass/suppression_store/ecto.ex:46-96` (impl, `check/2` with internal `Tenancy.scope` + downcasing + `{:error, :invalid_key}` fallback).
**Apply to:** `Ingress.Persist` flag computation. Call the CONFIGURED store (`Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)`), not the outbound facade. Degrade OPEN on `{:error, _}` and empty/missing `from`.

### Errors-as-contract — reuse the RateLimitError struct

**Source:** `lib/mailglass/errors/rate_limit_error.ex` — `RateLimitError.new(type, opts)` (line 67), `@types [:per_domain, :per_tenant, :per_stream]` (line 26), `.type`/`.retry_after_ms`/`.context` fields.
**Apply to:** the inbound rate limiter — build the struct internally; pattern-match `%RateLimitError{type: ...}`, never the message string (Things-Not-To-Do #7). `:per_tenant`/`:per_domain` map the inbound buckets.

---

## No Analog Found

None. Every new file has a verified clone source or a clearly-named structural analog in the live tree. The two genuinely-novel design surfaces both follow an established archetype:

| New surface | Why "novel" | Archetype it follows |
|-------------|-------------|----------------------|
| `InboundMessage.Signals` typed nested struct | First framework-owned read-only typed struct on a public inbound contract | `Ecto.Schema.Metadata` / `__meta__` (framework writes, adopter reads, dialyzer-checkable) — D-49-21 |
| Batched advisory-locked retention delete (`Internal.Prune`) | `[VERIFIED: grep]` no `FOR UPDATE SKIP LOCKED` / advisory-lock usage exists in the tree today | Standard Postgres time-based retention idiom (RESEARCH §Pattern 6); mirrors `Webhook.Pruner` structure, upgrades the delete |

---

## Cross-cutting deviations the planner must carry (both documented, both have erratum precedent)

1. **IOPS-04 "via `Mailglass.Config`" → inbound-local `MailglassInbound.Config`** reading `:mailglass_inbound` (D-49-02, boundary law). Adding inbound keys to core `Mailglass.Config` (which reads `:mailglass` only, `config.ex:529`) would invert the package dependency.
2. **IOPS-05 `.metadata.suppression_flagged` → `.signals.suppression_flagged`** (D-49-21). Core reserves `:metadata` for adopter-owned data (`lib/mailglass/message.ex`); framework facts go on `:signals`. Same precedent as the Phase-46 SESI-04 erratum.

## Open item flagged in RESEARCH (planner should confirm)

- **`use Boundary` on inbound tasks (RESEARCH A1/Q1):** `[VERIFIED: grep]` the inbound package does NOT run the `:boundary` compiler (only core lists `compilers: [:boundary | Mix.compilers()]`). D-49-04 says each task should `use Boundary, classify_to:` the package — taken literally that requires also wiring the boundary compiler + root `use Boundary` into `mailglass_inbound` (larger scope). Safest default: do NOT introduce the boundary compiler this phase; omit `use Boundary` from the inbound tasks (it would not compile without the compiler). Confirm in plan-phase.

## Metadata

**Analog search scope:** `lib/` (core) + `mailglass_inbound/lib/` (inbound) + `mailglass_inbound/priv/repo/migrations/`.

**Files scanned (read in-session 2026-05-25):**
- Core analogs (verified present, lines): `lib/mix/tasks/mail.doctor.ex` (99), `lib/mailglass/deliverability/formatter.ex` (68), `lib/mailglass/webhook/pruner.ex` (130), `lib/mix/tasks/mailglass.webhooks.prune.ex` (57), `lib/mailglass/rate_limiter.ex` (218), `lib/mailglass/rate_limiter/table_owner.ex` (62), `lib/mailglass/errors/rate_limit_error.ex` (93), `lib/mailglass/suppression_store.ex` (49), `lib/mailglass/suppression_store/ecto.ex` (197), `lib/mailglass/suppression.ex` (170, anti-analog), `lib/mailglass/message.ex` (346, anti-analog), `lib/mailglass/config.ex` (824), `lib/mailglass/optional_deps/gen_smtp.ex` (90), `lib/mailglass/application.ex` (112).
- Inbound targets (verified present, lines): `ingress/plug.ex` (570), `ingress/persist.ex` (339), `inbound_message.ex` (79), `execution.ex` (264), `mailbox.ex` (32), `inbound_records/{inbound_record (79), execution_run (126), replay_run (100), inbound_evidence (74)}.ex`, `internal/replay.ex` (109), `internal/operator/records.ex` (223), `router.ex` (97), `router/matcher.ex` (90), `router/route.ex` (15), `telemetry.ex` (146), `application.ex` (43), `optional_deps.ex` (168).
- New-file paths confirmed ABSENT (10): config.ex, rate_limiter.ex, rate_limiter/table_owner.ex, operator/formatter.ex, internal/doctor.ex, internal/prune.ex, prune/worker.ex, inbound_message/signals.ex, and the three `mix/tasks/mailglass.inbound.{doctor,replay,prune}.ex`.

**Pattern extraction date:** 2026-05-25
