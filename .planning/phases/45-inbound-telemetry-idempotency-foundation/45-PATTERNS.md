# Phase 45: Inbound Telemetry + Idempotency Foundation - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 18 (8 new lib/test infra + 6 modified + 4 schemas/configs referenced)
**Analogs found:** 18 / 18 (every file has a verified in-repo analog — this phase is "mirror, do not invent")

> The dominant phase instruction is **mirror the outbound/core seam**. Every new file
> below has a concrete, verified analog already shipped in `lib/mailglass/`. The planner
> should copy patterns by file + line number, not re-derive them.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mailglass_inbound/lib/mailglass_inbound/telemetry.ex` (NEW) | utility (instrumentation) | event-driven | `lib/mailglass/webhook/telemetry.ex` | exact |
| `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` (MOD) | controller (Plug) | request-response | `lib/mailglass/webhook/telemetry.ex` call sites (`ingest_span/2`) | role-match |
| `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` (MOD) | service (matcher) | transform | `Mailglass.Webhook.Telemetry.span_with_enrichment/3` shape | partial (enrichment) |
| `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` (MOD) | service (persistence) | CRUD | `lib/mailglass/outbound/projector.ex` (span wrap + post-commit) | role-match |
| `mailglass_inbound/lib/mailglass_inbound/execution.ex` (MOD) | service (executor) | event-driven | `Mailglass.Telemetry` span pattern + `Execution.execute/2` itself | role-match |
| `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex` (NEW) | utility (topic builder) | pub-sub | `lib/mailglass/pub_sub/topics.ex` | exact |
| post-commit broadcast helper (in `ingress/plug.ex` or `persist.ex`) | service (broadcaster) | pub-sub | `Mailglass.Outbound.Projector.broadcast_delivery_updated/3` + `safe_broadcast/2` | exact |
| `mailglass_inbound/lib/mailglass_inbound/mime.ex` (NEW) | service (parser) | transform | (net-new repr) gated by `Mailglass.OptionalDeps.GenSmtp` | partial |
| `lib/mailglass/optional_deps/gen_smtp.ex` (MOD) | config (optional-dep gateway) | transform | itself (`available?/0`) + `lib/mailglass/optional_deps.ex` | exact |
| `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` (NEW) | model (error struct) | — | `lib/mailglass/errors/config_error.ex` | exact |
| `.credo.exs` (MOD) | config (lint) | — | itself (path-scope + check params) | exact |
| `credo_checks/no_pii_in_telemetry_meta.ex` (MOD) | utility (lint check) | transform | itself | exact |
| `credo_checks/telemetry_event_convention.ex` (MOD, defensive) | utility (lint check) | transform | itself (`required_root` param) | exact |
| `mailglass_inbound/test/support/test_repo.ex` (NEW) | test (repo) | CRUD | `test/support/test_repo.ex` | exact |
| `mailglass_inbound/config/test.exs` (NEW) | config (test) | — | `config/test.exs` | exact |
| `mailglass_inbound/test/test_helper.exs` (MOD) | test (bootstrap) | — | `test/test_helper.exs` | role-match |
| `mailglass_inbound/test/.../properties/inbound_idempotency_convergence_test.exs` (NEW) | test (property) | CRUD | `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | exact |
| `mailglass_inbound/mix.exs` (MOD) | config (deps) | — | core `mailglass/mix.exs` gen_smtp optional dep line | role-match |

---

## Pattern Assignments

### `mailglass_inbound/lib/mailglass_inbound/telemetry.ex` (utility, event-driven) — NEW

**Analog:** `lib/mailglass/webhook/telemetry.ex` (exact)

The new module is the single span surface for `mailglass_inbound` (D-45-01) — one
module for `NoPiiInTelemetryMeta` to audit. It needs the **enrichment** shape because
stop metadata (status/operation/outcome/source) is only known after the inner fn returns.

**Copy the `defp span_with_enrichment/3` body verbatim** (`lib/mailglass/webhook/telemetry.ex`
lines 179-189). It is `defp` in the analog, so it **cannot** be called cross-module — copy
the body into the new inbound module:

```elixir
# lib/mailglass/webhook/telemetry.ex:179-189 — COPY this body into MailglassInbound.Telemetry
defp span_with_enrichment(event_prefix, metadata, fun) do
  :telemetry.span(event_prefix, metadata, fn ->
    case fun.() do
      {result, %{} = stop_metadata} ->
        {result, stop_metadata}

      result ->
        {result, metadata}
    end
  end)
end
```

**Named helper pattern** (analog `lib/mailglass/webhook/telemetry.ex` lines 93-96):
```elixir
@doc since: "0.1.0"
@spec ingest_span(map(), (-> result | {result, map()})) :: result when result: term()
def ingest_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
  span_with_enrichment([:mailglass, :webhook, :ingest], metadata, fun)
end
```

Inbound version provides four named helpers with the four fixed event prefixes from D-45-02:
- `ingress_span/2` → `[:mailglass_inbound, :ingress, :request]`
- `route_span/2` → `[:mailglass_inbound, :route, :match]`
- `persist_span/2` → `[:mailglass_inbound, :persist, :record]`
- `execution_span/2` → `[:mailglass_inbound, :execution, :run]`

**Moduledoc requirements to mirror** (analog lines 1-78): document the event table, the
PII whitelist (D-45-03), the "callers MUST NOT reach for `:telemetry.span/3` directly"
rule, and that handler isolation (TELE-05) is free from `:telemetry.span/3` (analog lines
28-34 + `lib/mailglass/telemetry.ex` lines 40-46). The handler-isolation prose is locked:
> `:telemetry.span/3` wraps each attached handler in a try/catch. A handler that raises is
> detached automatically and `[:telemetry, :handler, :failure]` is emitted — the caller's
> pipeline is unaffected. Mailglass does **not** add a parallel try/rescue wrapper.

**Do NOT** add single-emit helpers — inbound emits via spans only (RESEARCH Pitfall 2 / A6;
keeps `TelemetryEventConvention`, which only inspects `:telemetry.execute`, from firing).

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` (controller, request-response) — MODIFY

**Analog:** `lib/mailglass/webhook/telemetry.ex` ingest call-site convention.

Two changes:
1. **TELE-01 ingress span** wraps the body of `call/2` (analog: the whole try/case body at
   `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` lines 33-69). Wrap via
   `MailglassInbound.Telemetry.ingress_span/2`. Stop metadata: `provider, tenant_id, status,
   byte_size, latency` (D-45-03 whitelist). Return `{result, stop_metadata}` from the fn so
   the classified outcome lands on `:stop`.
2. **TELE-07 post-commit broadcast** — the natural site is **after** `persistence.persist(...)`
   returns `{:ok, %{status: :inserted}}` (current line 44-52), which is already OUTSIDE the
   transact (the transact lives inside `Persist.persist/2`, line 26-47). This satisfies the
   D-45-06 "never broadcast inside the transaction" invariant. The existing `maybe_execute/2`
   guard at lines 203-208 already discriminates `:duplicate` (no-op) vs `:inserted` — broadcast
   on the same `:inserted` branch.

Current persist→execute dispatch (existing, line 203-208 — broadcast goes alongside):
```elixir
defp maybe_execute(_execution, %{status: :duplicate}), do: :ok

defp maybe_execute(execution, %{status: :inserted} = result) do
  _ = execution.dispatch(result)
  :ok
end
```

---

### `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` (service, transform) — MODIFY

**Analog:** `Mailglass.Webhook.Telemetry.span_with_enrichment/3` enrichment shape.

**TELE-02 route span** wraps `match/2` (current `mailglass_inbound/lib/.../router/matcher.ex`
lines 8-12). Outcome is `{:ok, Route.t()}` or `:no_match` — outcome-dependent, so use
`MailglassInbound.Telemetry.route_span/2` returning `{result, stop_metadata}`. Stop metadata:
matched-mailbox identity / `no_match` / candidate count (`length(routes)`) — all PII-free
(D-45-03). Note: route compatibility is *also* computed in `Persist.route_compatibility/2`
(persist.ex lines 163-175) which calls `Matcher.match/2`; the span belongs on `match/2` itself
so both call paths are covered.

```elixir
# Current matcher.ex:8-12 — wrap this body in route_span/2
def match(routes, %InboundMessage{} = message) when is_list(routes) do
  Enum.find_value(routes, :no_match, fn route ->
    if matches_route?(route, message), do: {:ok, route}, else: false
  end)
end
```

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` (service, CRUD) — MODIFY

**Analog:** `lib/mailglass/outbound/projector.ex` (span-wrapped persist) + the result-status
mapping idiom.

**TELE-04 persist span** wraps the `repo.transact` (current `persist.ex` lines 26-47) via
`MailglassInbound.Telemetry.persist_span/2`. Operation derives from result status (D-45-02):
`{:ok, %{status: :inserted}}` → `operation: :insert`; `{:ok, %{status: :duplicate}}` →
`operation: :dedup_skip`. The result status is already produced by the transact body at
persist.ex lines 28-46 (`:duplicate` at line 30, `:inserted` at line 41). Stop metadata:
`tenant_id, provider, operation, record_type` ("inbound_record"), PII-free.

Projector's span-wrapped write path is the structural template (analog lines 59-72):
```elixir
# lib/mailglass/outbound/projector.ex:59-72 — span wraps the write, returns the changeset
def update_projections(%Delivery{} = delivery, %Event{} = event) do
  Mailglass.Telemetry.persist_span(
    [:delivery, :update_projections],
    %{tenant_id: delivery.tenant_id, delivery_id: delivery.id},
    fn ->
      delivery |> Ecto.Changeset.change() |> ... |> Ecto.Changeset.optimistic_lock(:lock_version)
    end
  )
end
```

The dedupe anchor is unchanged (`InboundRecord.changeset/1` `unique_constraint`,
`inbound_record.ex` lines 75-77, index `mailglass_inbound_records_postmark_idempotency_idx`)
and the `duplicate_constraint?/1` guard (persist.ex lines 177-182). Do NOT alter dedupe logic.

---

### `mailglass_inbound/lib/mailglass_inbound/execution.ex` (service, event-driven) — MODIFY

**Analog:** `Mailglass.Telemetry.span/3` usage + the existing `execute/2`.

**TELE-03 execution span** wraps the body of `execute/2` (current `execution.ex` lines 40-49),
NOT `dispatch/2` (D-45-02, RESEARCH Pitfall 5). `execute/2` is the single sync point both async
paths funnel through: worker → `execute/2`, and `dispatch_task_supervisor` calls
`execution.execute(persisted, ...)` (execution.ex line 119). Wrap via
`MailglassInbound.Telemetry.execution_span/2`. Stop metadata: `mailbox` (module identity),
`outcome` (`:accept | :reject | :ignore | :bounce | :no_match | :failed`), `source`
(`:fresh | :replay`), all PII-free.

Outcome + source are computed in `execute/2` today (lines 40-49 + `execution_attrs/2` lines
158-190 + `classify_mailbox_result/3` lines 192-215). The `:duplicate` short-circuit at line
51 (`def execute(%{status: status}, ...) when status in [:duplicate], do: {:ok, %{status: :skipped}}`)
is the zero-extra-`ExecutionRun` invariant the convergence proof relies on (D-45-11).

```elixir
# Current execution.ex:40-49 — wrap this body in execution_span/2 (outcome/source enrichment)
def execute(%{status: :inserted} = persisted, opts) when is_list(opts) do
  records = Keyword.get(opts, :inbound_records, InboundRecords)
  source = Keyword.get(opts, :source, :fresh)
  attrs = execution_attrs(persisted, source)
  normalized_result = normalize_result(attrs)

  with {:ok, _run} <- records.insert_execution_run(attrs) do
    {:ok, normalized_result}
  end
end
```

---

### `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex` (utility, pub-sub) — NEW

**Analog:** `lib/mailglass/pub_sub/topics.ex` (exact). Also matches the admin consumer module
`mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex` (same prefix convention).

One function, per-tenant, `mailglass:`-prefixed (D-45-07/08, LINT-06). Builder routes around
the literal-string flag at the broadcast call site.

```elixir
# lib/mailglass/pub_sub/topics.ex:17-21 — exact shape to mirror
@doc "Returns the tenant-wide event stream topic."
@doc since: "0.1.0"
@spec events(String.t()) :: String.t()
def events(tenant_id) when is_binary(tenant_id),
  do: "mailglass:events:" <> tenant_id
```

Inbound version (default from D-45-07):
```elixir
@doc since: "0.2.0"   # inbound minor bump; public-contract addition
@spec inbound_record_inserted(String.t()) :: String.t()
def inbound_record_inserted(tenant_id) when is_binary(tenant_id),
  do: "mailglass:inbound:" <> tenant_id
```
Mirror the moduledoc that names every topic + the LINT-06 prefix note (analog lines 1-15).

---

### Post-commit broadcast helper (service, pub-sub) — NEW (co-located in plug.ex or persist.ex)

**Analog:** `lib/mailglass/outbound/projector.ex` `broadcast_delivery_updated/3` + `safe_broadcast/2`
(exact, TELE-07).

**Copy `safe_broadcast/2` verbatim** (analog lines 180-200) — only the log prefix changes
(`[mailglass]` → `[mailglass_inbound]`). The rescue list `[ArgumentError, RuntimeError]` and the
`catch :exit, reason` clause are both load-bearing (PubSub server may be down at shutdown):

```elixir
# lib/mailglass/outbound/projector.ex:180-200 — COPY (change log tag only)
defp safe_broadcast(topic, payload) do
  Phoenix.PubSub.broadcast(Mailglass.PubSub, topic, payload)
rescue
  e in [ArgumentError, RuntimeError] ->
    require Logger
    Logger.debug("[mailglass] PubSub broadcast failed (non-fatal): #{Exception.message(e)}")
    :ok
catch
  :exit, reason ->
    require Logger
    Logger.debug("[mailglass] PubSub broadcast exited (non-fatal): #{inspect(reason)}")
    :ok
end
```

Broadcast call shape (analog lines 166-178): broadcast on `Mailglass.PubSub` (the shared server),
to `MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id)`, payload PII-free
(`{:inbound_record_inserted, record_id, %{provider: ..., record_type: "inbound_record"}}`).
Mirror the analog moduledoc's "broadcast runs AFTER commit / never rolls back / event ledger is
the durable source of truth" prose (analog lines 136-163).

---

### `mailglass_inbound/lib/mailglass_inbound/mime.ex` (service, transform) — NEW

**Analog:** none for the internal representation (net-new, Claude's discretion per D-45-13/14);
the *gating* pattern mirrors any `Mailglass.OptionalDeps.*` consumer. The full skeleton is locked
in RESEARCH lines 632-653.

Contract: `parse/1` returns `{:ok, internal_repr}` or `{:error, %MailglassInbound.MIMEError{}}`,
**never raises** (MIME-04). Branch on `Mailglass.OptionalDeps.GenSmtp.available?/0`; on `false`
return `%MIMEError{type: :gen_smtp_unavailable}` (D-45-17). On parse failure from the gateway,
wrap as `%MIMEError{type: :inbound_mime_invalid, cause: cause, context: %{byte_size: ...}}`.
All `:mimemail` access goes through the gateway — never bare (`NoBareOptionalDepReference`).

Internal repr fields (D-45-14, discretion): `headers, parts, attachments, inline`. Decode shape
is the gen_smtp 5-tuple `{Type, SubType, Headers, Parameters, Body}` where `Parameters` is a MAP
(`content_type_params`, `disposition`, `disposition_params`; `transfer_encoding` may be ABSENT —
use `Map.get`, RESEARCH A1). Multipart `Body` is a list → recurse; `message/rfc822` is a single
tuple; leaf is a binary. Attachment = `params.disposition == <<"attachment">>`; filename =
`disposition_params["filename"] || content_type_params["name"]`. Consider a max-recursion-depth
guard (V5 input validation, boundary-bomb DoS — RESEARCH Security Domain).

---

### `lib/mailglass/optional_deps/gen_smtp.ex` (config, optional-dep gateway) — MODIFY

**Analog:** itself (the existing `available?/0`) + the gateway discipline in `lib/mailglass/optional_deps.ex`.

Add the **parse seam** here (D-45-13) — not scattered `Code.ensure_loaded?` calls. The locked
shape (RESEARCH lines 614-630):

1. Extend the no-warn list: `@compile {:no_warn_undefined, [:gen_smtp_client, :mimemail]}`
   (current line 14 has only `:gen_smtp_client`).
2. Add `decode/2` that wraps `:mimemail.decode/2` and **never raises** — `try/rescue` AND
   `catch :throw` AND `catch :exit` (D-45-15, RESEARCH Pitfall 6: `:mimemail` raises via
   `erlang:error` AND `throw`, plus `:exit`/`:undef` if iconv missing).
3. Pass explicit opts `[{:allow_missing_version, true}, {:encoding, :none}]` — `encoding: :none`
   is **mandatory** (skips iconv, which gen_smtp does not bundle — RESEARCH Pitfall 6 / A3).

```elixir
# RESEARCH 619-629 — locked decode seam shape
@doc since: "1.2.0"
@spec decode(binary(), keyword()) :: {:ok, tuple()} | {:error, term()}
def decode(raw, opts \\ []) when is_binary(raw) do
  erl_opts = [{:allow_missing_version, true}, {:encoding, :none}] ++ opts
  {:ok, :mimemail.decode(raw, erl_opts)}
rescue
  e -> {:error, {:error, e}}                  # erlang:error: no_boundary, missing_boundary, ...
catch
  :throw, reason -> {:error, {:throw, reason}} # bad_content_type, bad_disposition, badchar
  :exit, reason  -> {:error, {:exit, reason}}  # iconv / eiconv unavailable
end
```

Existing gateway shape to preserve (current `gen_smtp.ex` lines 14-21):
```elixir
@compile {:no_warn_undefined, [:gen_smtp_client]}
@doc since: "0.1.0"
@spec available?() :: boolean()
def available?, do: Code.ensure_loaded?(:gen_smtp_client)
```
Verify `mix compile --no-optional-deps --warnings-as-errors` stays green after adding `:mimemail`.

---

### `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` (model, error struct) — NEW

**Analog:** `lib/mailglass/errors/config_error.ex` (exact canonical error shape + closed-type discipline).

Mirror the `[:type, :message, :cause, :context]` `defexception`, the `@derive {Jason.Encoder,
only: [:type, :message, :context]}` (excludes `:cause` so payload fragments don't leak — analog
line 50), and the `__types__/0` discipline (analog lines 69-71). Closed type set (D-45-16):
`[:inbound_mime_invalid, :gen_smtp_unavailable]`.

Key difference from `ConfigError`: `MailglassInbound.MIMEError` is **package-local** — it does NOT
implement `@behaviour Mailglass.Error` (that behaviour and its `@type t` union live in core; the
inbound struct must not add itself to the core union — RESEARCH lines 674-676). It is a plain
`defexception` with `__types__/0` for the contract test.

```elixir
# Mirror lib/mailglass/errors/config_error.ex:37-71 — closed types + @derive + __types__/0
@types [:inbound_mime_invalid, :gen_smtp_unavailable]
@derive {Jason.Encoder, only: [:type, :message, :context]}
defexception [:type, :message, :cause, :context]

@type t :: %__MODULE__{
        type: :inbound_mime_invalid | :gen_smtp_unavailable,
        message: String.t(),
        cause: term() | nil,
        context: map()
      }

@doc "Returns the closed set of valid :type atoms. Tested against docs/api_stability.md."
@doc since: "0.2.0"
def __types__, do: @types

@impl true
def message(%__MODULE__{message: m}), do: m
```

Public-contract obligations (D-45-16): CHANGELOG entry + `@since "0.2.0"` + a `__types__/0`
assertion test mirroring core's `test/mailglass/error_test.exs` (the `__types__/0 returns the
closed atom set for ConfigError` test at line 94-99), and add the struct to
`mailglass_inbound/docs/api_stability.md` Stable Inventory.

---

### `.credo.exs` (config, lint) — MODIFY

**Analog:** itself (path scope + per-check param lists).

TELE-06's hardest sub-task (RESEARCH Pitfall 1). The root `included` is repo-root-relative and
does NOT see inbound today (current `.credo.exs` lines 67-72):
```elixir
files: %{
  # D-08-21: included stays ["lib/", "test/"]; do NOT add credo_checks/
  included: ["lib/", "test/"],
  excluded: []
},
```
Recommended fix (RESEARCH A4, option a): widen `included` to add `"mailglass_inbound/lib/"` +
`"mailglass_inbound/test/"`. Honor the existing D-08-21 note — do NOT add `credo_checks/`.

Two custom checks scope themselves to `included_path_prefixes: ["lib/mailglass/"]` and would
SKIP inbound silently (current lines 30 + 51-52): `NoBareOptionalDepReference` and
`NoDirectDateTimeNow`. Widen or document that they don't apply to inbound. `NoBareOptionalDepReference`
matters for MIME (it must catch any bare `:mimemail` outside the gateway).

`TelemetryEventConvention` is configured `[required_root: :mailglass, min_segments: 4]` (current
line 44) and will false-positive on `:mailglass_inbound` event roots once Credo lints inbound
(RESEARCH Pitfall 2 / A6). Defensive fix: widen the check to accept `:mailglass_inbound` too.

**Verification requirement (RESEARCH Pitfall 1, A4):** after widening, prove inbound is actually
linted — introduce a temporary blocked key (e.g. `%{to: "x"}`) in an inbound span call, confirm
`mix credo --strict` flags it, then revert. Silent non-coverage is the failure mode.

---

### `credo_checks/no_pii_in_telemetry_meta.ex` (utility, lint check) — MODIFY

**Analog:** itself. The check already inspects both `:telemetry.execute` (lines 52-56) and
`:telemetry.span` (lines 58-60) literal metadata maps against `blocked_keys` (lines 64-79).
It is package-agnostic AST analysis — the only change needed for TELE-06 is making Credo *run*
it against inbound files (handled in `.credo.exs` above). Verify the `blocked_keys` set in
`.credo.exs` lines 6-9 covers the inbound whitelist's forbidden keys (it does:
`to from cc bcc body html_body text_body subject headers recipient email`).

```elixir
# credo_checks/no_pii_in_telemetry_meta.ex:58-60 — already covers :telemetry.span (inbound's only emitter)
defp telemetry_metadata({{:., _, [:telemetry, :span]}, meta, [_event, metadata, _fun]}) do
  {:ok, metadata, meta[:line], meta[:column]}
end
```

---

### `credo_checks/telemetry_event_convention.ex` (utility, lint check) — MODIFY (defensive)

**Analog:** itself. Today it only inspects `:telemetry.execute` (lines 29-35) and requires
`root == required_root` (line 38). Inbound emits only via `:telemetry.span` (RESEARCH A6), so it
won't fire on inbound spans — but defensively widen `required_root` to accept `:mailglass` OR
`:mailglass_inbound` so a future inbound `:telemetry.execute` doesn't silently break (RESEARCH
Pitfall 2, Open Q3). The param is a single atom today (`.credo.exs` line 44); change to a list or
add a second scoped config entry.

```elixir
# credo_checks/telemetry_event_convention.ex:36-40 — the guard to widen
case literal_atom_list(event_ast) do
  {:ok, [root | _] = event}
  when root == required_root and length(event) >= min_segments ->
    {ast, ctx}
```

---

### `mailglass_inbound/test/support/test_repo.ex` (test, repo) — NEW (Wave 0)

**Analog:** `test/support/test_repo.ex` (exact). No inbound test DB exists today — all inbound
tests use in-memory `FakeRepo` stubs (RESEARCH Pitfall 3). The convergence proof needs a real
Postgres repo with the unique index (the dedupe anchor).

```elixir
# test/support/test_repo.ex:1-16 — exact shape (rename module + otp_app)
defmodule Mailglass.TestRepo do
  @moduledoc "..."
  use Ecto.Repo,
    otp_app: :mailglass,
    adapter: Ecto.Adapters.Postgres
end
```
Inbound version: `MailglassInbound.TestRepo`, `otp_app: :mailglass_inbound`,
`adapter: Ecto.Adapters.Postgres`. Wire it via `config :mailglass_inbound, :repo,
MailglassInbound.TestRepo` so the `MailglassInbound.Repo` facade (`repo.ex` lines 37-46)
resolves to it (the facade raises today when `:repo` is unset — repo.ex lines 39-41).

---

### `mailglass_inbound/config/test.exs` (config, test) — NEW (Wave 0)

**Analog:** `config/test.exs` (exact, the Postgres credentials + `MIX_TEST_PARTITION` block).

```elixir
# config/test.exs:17-22 — credential shape to mirror (rename app + repo + db)
config :mailglass, Mailglass.TestRepo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database: "mailglass_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
```
Inbound version: `config :mailglass_inbound, MailglassInbound.TestRepo, ...` with
`database: "mailglass_inbound_test#{...}"`, plus `config :mailglass_inbound, :repo,
MailglassInbound.TestRepo`. The citext-specific `prepare: :unnamed` / `disconnect_on_error_codes`
options (analog lines 23-39) are NOT needed — inbound has no citext columns. Inbound has no
`config/` dir today, so this is a new file; ensure `mix.exs` reads it (Mix loads `config/config.exs`
by convention — may need a `config/config.exs` that imports env config, mirror core's `config/`).

---

### `mailglass_inbound/test/test_helper.exs` (test, bootstrap) — MODIFY (Wave 0)

**Analog:** `test/test_helper.exs` (role-match — the migration-runner + sandbox-mode block).

Current inbound helper is minimal (`mailglass_inbound/test/test_helper.exs` lines 1-3: swoosh
api_client false + `ExUnit.start()`). Extend to: run all 4 inbound migrations against the test DB,
start the repo, set sandbox mode `:manual`. Mirror the core migration block (analog lines 29-77),
INCLUDING the **pool override** during migration (analog lines 33-46): the migrator's connection
checkout hangs if the pool is `Sandbox` before `mode/2` is set, so swap to
`DBConnection.ConnectionPool` for the migration step, then restore the Sandbox config.

```elixir
# test/test_helper.exs:41-48 — migration-then-start pattern to mirror
{:ok, _, _} =
  Ecto.Migrator.with_repo(Mailglass.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
  end)

Application.put_env(:mailglass, Mailglass.TestRepo, test_repo_config)
{:ok, _pid} = Mailglass.TestRepo.start_link()
```
Inbound migrations live at `mailglass_inbound/priv/repo/migrations/` (4 files, verified). Skip the
citext probe (analog lines 55-75) — inbound has no citext. End with
`Ecto.Adapters.SQL.Sandbox.mode(MailglassInbound.TestRepo, :manual)`.

---

### `mailglass_inbound/test/.../properties/inbound_idempotency_convergence_test.exs` (test, property) — NEW

**Analog:** `test/mailglass/properties/webhook_idempotency_convergence_test.exs` (exact, TELE-08).
The full skeleton is locked in RESEARCH lines 680-731.

Structural idioms to mirror exactly (D-45-09):
- `use ExUnit.Case, async: false` + `use ExUnitProperties` — **NOT** DataCase (analog lines 38-39;
  the per-test transaction deadlocks against inter-iteration TRUNCATE — analog moduledoc lines 27-36).
- `@moduletag :property` + `@moduletag timeout: :infinity` (analog lines 48-49).
- `Sandbox.start_owner!(TestRepo, shared: true, ownership_timeout: 10 * 60_000)` in setup;
  `Sandbox.stop_owner(owner)` on exit (analog lines 51-72).
- `TRUNCATE … CASCADE` between iterations (append-only trigger forbids UPDATE/DELETE — analog
  lines 61-66 + 111-112). For inbound, truncate `mailglass_inbound_records` and
  `mailglass_inbound_replay_runs` (the latter is the shared ExecutionRun/ReplayRun table).
- `max_runs: 1000` (analog line 107).

```elixir
# test/mailglass/properties/webhook_idempotency_convergence_test.exs:103-108 — check-all + max_runs shape
property "convergence: apply N times == apply once for any (event, replay_count) sequence" do
  check all(
          events <- list_of(event_gen(), min_length: 1, max_length: 10),
          replay_count <- integer(1..10),
          max_runs: 1000
        ) do
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
```

Generator (D-45-12): draw `provider_message_id` (`MessageID`) from a small `member_of` pool
(≤4 ids) over `list_of(payload, max_length: 10)` so collisions occur across list elements, plus
`integer(1..10)` replay multiplier. Postmark-style string-keyed JSON. The analog's `event_gen/0`
(analog lines 76-101) uses `member_of` for record types — same idiom.

**Drive the real write path** (D-45-10): synchronous `MailglassInbound.Ingress.Persist.persist/2`
then `MailglassInbound.Execution.execute(persisted, source: :fresh)` — NOT `dispatch/2` (Oban may
not be started; Task.Supervisor children run detached → non-deterministic counts, RESEARCH
Pitfall 5).

**Assertions** (D-45-11): exactly one `InboundRecord` per unique `(tenant_id, provider,
provider_message_id)`, AND exactly one **`:fresh`** `ExecutionRun` per inserted record.
**Critical (RESEARCH Pitfall 4):** `ExecutionRun` and `ReplayRun` share table
`mailglass_inbound_replay_runs` (`execution_run.ex` line 38; `replay_run.ex` same), so count only
`where: r.source == :fresh` — a naive `aggregate(ExecutionRun, :count)` also counts ReplayRun rows.
The `source` enum is `[:fresh, :replay]` (`execution_run.ex` line 16).

Alternate sandbox precedent (mode flip instead of owner): `test/mailglass/properties/idempotency_convergence_test.exs`
lines 42-57 (`Sandbox.mode(TestRepo, :auto)` in setup, restore `:manual` on exit) — D-45-09 picks
the `start_owner!` shared-owner form, so prefer the webhook analog over this one.

---

### `mailglass_inbound/mix.exs` (config, deps) — MODIFY (Wave 0)

**Analog:** core `mailglass/mix.exs` gen_smtp optional-dep declaration (`{:gen_smtp, "~> 1.3",
optional: true}`, RESEARCH line 201).

Add `{:gen_smtp, "~> 1.3", optional: true}` to `deps/0` (current `mailglass_inbound/mix.exs`
lines 48-57) so the inbound test/dev env can load `:mimemail` to exercise the real parser
(RESEARCH A7). Also extend `elixirc_options` no-warn list (current line 45 has
`[Oban, Oban.Job, Oban.Worker]`) if any inbound module references `:mimemail` directly — but it
should not (all access via the core gateway). Run `mix deps.get` in inbound after. Verify
`mix compile --no-optional-deps --warnings-as-errors` stays green.

---

## Shared Patterns

### Telemetry span (single-surface, enrichment)
**Source:** `lib/mailglass/webhook/telemetry.ex` lines 179-189 (`span_with_enrichment/3` body).
**Apply to:** `MailglassInbound.Telemetry` (copy body) + all four wrap sites (plug, matcher,
persist, execution) which call the named helpers, never `:telemetry.span/3` directly.
Handler isolation (TELE-05) is free — no custom rescue (`lib/mailglass/telemetry.ex` lines 40-46).

### Post-commit PubSub broadcast
**Source:** `lib/mailglass/outbound/projector.ex` lines 166-200 (`broadcast_delivery_updated/3` +
`safe_broadcast/2`).
**Apply to:** the TELE-07 broadcast (in plug.ex `:inserted` branch). Copy `safe_broadcast/2`
verbatim (rescue `[ArgumentError, RuntimeError]` + `catch :exit`); change log tag only. Broadcast
OUTSIDE the transact, on `Mailglass.PubSub`, via the typed topic builder.

### Typed topic builder (LINT-06)
**Source:** `lib/mailglass/pub_sub/topics.ex` lines 17-21 (plus admin consumer
`mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex`).
**Apply to:** `MailglassInbound.PubSub.Topics.inbound_record_inserted/1` → `"mailglass:inbound:" <>
tenant_id`. Always call the builder at broadcast sites — never a literal string.

### Optional-dep gateway (single module, never bare)
**Source:** `lib/mailglass/optional_deps/gen_smtp.ex` lines 14-21 + RESEARCH lines 614-630 (decode seam).
**Apply to:** the MIME parse seam — extend the gateway with `decode/2`, add `:mimemail` to the
`@compile {:no_warn_undefined, ...}` list, never reference `:mimemail` bare elsewhere
(`NoBareOptionalDepReference`). `mix compile --no-optional-deps --warnings-as-errors` must pass.

### Canonical error struct (closed type, PII-safe serialization)
**Source:** `lib/mailglass/errors/config_error.ex` lines 37-71 + behaviour `lib/mailglass/error.ex`
lines 33-44 + test `test/mailglass/error_test.exs` line 94 (`__types__/0` assertion).
**Apply to:** `MailglassInbound.MIMEError` — `[:type, :message, :cause, :context]` defexception,
`@derive {Jason.Encoder, only: [:type, :message, :context]}` (excludes `:cause`), `@types` +
`__types__/0`, closed set `[:inbound_mime_invalid, :gen_smtp_unavailable]`. Package-local — does
NOT join `Mailglass.Error`'s union. CHANGELOG + `@since` + `__types__/0` test + api_stability entry.

### Real-DB convergence harness (sandbox + TRUNCATE + max_runs:1000)
**Source:** `test/mailglass/properties/webhook_idempotency_convergence_test.exs` lines 38-179.
**Apply to:** the inbound convergence proof + Wave 0 infra (TestRepo, config/test.exs, test_helper
migration block). `use ExUnit.Case, async: false` (not DataCase), `start_owner!(shared: true,
ownership_timeout: 10*60_000)`, `TRUNCATE … CASCADE`, `max_runs: 1000`, `timeout: :infinity`.

---

## No Analog Found

| File | Role | Data Flow | Reason / Mitigation |
|------|------|-----------|---------------------|
| `mailglass_inbound/lib/mailglass_inbound/mime.ex` (internal repr struct) | service | transform | No existing internal MIME representation exists anywhere in the repo (D-45-13: net-new). The *gating* and *never-raise* patterns have analogs (gateway + projector `safe_broadcast` try/catch shape), but the `%{headers, parts, attachments, inline}` repr is Claude's discretion. Planner should use RESEARCH lines 594-653 (verified 5-tuple shape + parse skeleton), not a codebase analog. |

> Note: this is the only genuinely new build in the phase. Everything else mirrors an existing,
> verified outbound/core file.

## Metadata

**Analog search scope:** `lib/mailglass/` (telemetry, webhook/telemetry, outbound/projector,
pub_sub/topics, optional_deps/gen_smtp, error, errors/config_error), `credo_checks/`, `.credo.exs`,
`test/support/`, `config/test.exs`, `test/test_helper.exs`, `test/mailglass/properties/`,
`mailglass_inbound/lib/` (ingress/plug, ingress/persist, router/matcher, execution,
inbound_records/{execution_run,inbound_record}, repo, schema), `mailglass_inbound/{mix.exs,
test/test_helper.exs, docs/api_stability.md, priv/repo/migrations/}`, `mailglass_admin/lib/.../pub_sub/topics.ex`.
**Files scanned:** 25 read in full + targeted greps (CI workflow, error_test).
**Pattern extraction date:** 2026-05-22
**Skills loaded:** none (`.claude/skills/` and `.agents/skills/` absent).
