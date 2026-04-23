---
phase: 03-transport-send-pipeline
reviewed: 2026-04-22T00:00:00Z
depth: standard
files_reviewed: 49
files_reviewed_list:
  - config/config.exs
  - config/test.exs
  - docs/api_stability.md
  - lib/mailglass.ex
  - lib/mailglass/adapter.ex
  - lib/mailglass/adapters/fake.ex
  - lib/mailglass/adapters/fake/storage.ex
  - lib/mailglass/adapters/fake/supervisor.ex
  - lib/mailglass/adapters/swoosh.ex
  - lib/mailglass/application.ex
  - lib/mailglass/clock.ex
  - lib/mailglass/clock/frozen.ex
  - lib/mailglass/clock/system.ex
  - lib/mailglass/config.ex
  - lib/mailglass/errors/batch_failed.ex
  - lib/mailglass/errors/config_error.ex
  - lib/mailglass/events.ex
  - lib/mailglass/mailable.ex
  - lib/mailglass/message.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/delivery.ex
  - lib/mailglass/outbound/projector.ex
  - lib/mailglass/outbound/worker.ex
  - lib/mailglass/pub_sub.ex
  - lib/mailglass/pub_sub/topics.ex
  - lib/mailglass/rate_limiter.ex
  - lib/mailglass/rate_limiter/supervisor.ex
  - lib/mailglass/rate_limiter/table_owner.ex
  - lib/mailglass/repo.ex
  - lib/mailglass/stream.ex
  - lib/mailglass/suppression.ex
  - lib/mailglass/suppression_store/ets.ex
  - lib/mailglass/suppression_store/ets/supervisor.ex
  - lib/mailglass/suppression_store/ets/table_owner.ex
  - lib/mailglass/telemetry.ex
  - lib/mailglass/tenancy.ex
  - lib/mailglass/test_assertions.ex
  - lib/mailglass/tracking.ex
  - lib/mailglass/tracking/config_validator.ex
  - lib/mailglass/tracking/guard.ex
  - lib/mailglass/tracking/plug.ex
  - lib/mailglass/tracking/rewriter.ex
  - lib/mailglass/tracking/token.ex
  - mix.exs
  - priv/repo/migrations/00000000000002_add_idempotency_key_to_deliveries.exs
  - test/support/mailer_case.ex
  - test/support/webhook_case.ex
  - test/support/admin_case.ex
  - test/support/fake_fixtures.ex
  - test/support/generators.ex
findings:
  critical: 0
  high: 2
  medium: 5
  low: 6
  nit: 4
  total: 17
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-04-22
**Depth:** standard
**Files Reviewed:** 49
**Status:** issues_found (non-blocking — recommend Phase 3.1 gap closure)

## Summary

Phase 3 ships the transport + send pipeline: Clock, Tenancy, PubSub/Topics,
error hierarchy, Telemetry, Application tree, Config schema, Message +
Mailable behaviour, Fake + Swoosh adapters, RateLimiter + Suppression +
Stream preflight stages, Outbound facade (send/deliver/deliver_later/deliver_many),
Tracking infrastructure (Rewriter, Token, Plug, ConfigValidator), TestAssertions
+ MailerCase. The UAT gate passes (61 tests, 0 failures) and locked contracts
in `docs/api_stability.md` match the implementation.

**Assessment:** The code generally honours the project's locked rules —
`Application.compile_env` is isolated to `Mailglass.Config`, no `Swoosh.Mailer.deliver/1`
calls appear outside the Swoosh adapter's own guard-documented path, no
PII leaks through telemetry metadata, errors are pattern-matched by struct,
and `name: __MODULE__` singletons all match the documented allowlist
(RateLimiter.TableOwner, SuppressionStore.ETS.TableOwner, Fake.Storage,
plus their supervisors which api_stability.md documents as
library-reserved). The two-Multi pattern in `Mailglass.Outbound` correctly
keeps the adapter call OUTSIDE `Repo.multi/1` (D-20). Tracking defaults to
off per TRACK-01.

**Noteworthy risks found (none block merge):**

- **HIGH (HI-01):** `test/support/mailer_case.ex:134` mutates
  `Application.put_env(:mailglass, :async_adapter, :task_supervisor)` on
  every test's `setup/1` — global state write in a case template that
  supports `async: true`. Concurrent async tests race on this env, and
  `on_exit` unconditionally restores to `:oban` even if the original was
  `:task_supervisor`. This is a testing-correctness regression, not a
  library bug.
- **HIGH (HI-02):** `lib/mailglass/tracking/rewriter.ex:222-226` vs
  `lib/mailglass/tracking/plug.ex:142-145` — mismatched endpoint fallback
  chains. The Rewriter additionally honours
  `Application.get_env(:mailglass, :adapter_endpoint)` which the Plug
  ignores. If an adopter sets `:adapter_endpoint` but not
  `:tracking, :endpoint`, the Rewriter signs tokens with one key and the
  Plug verifies with a different key → every pixel + click URL silently
  fails verification (204 + 404 responses with no log), tracking events
  are lost.
- **MEDIUM (ME-01):** `lib/mailglass/events.ex:160` calls
  `DateTime.utc_now/0` directly instead of `Mailglass.Clock.utc_now/0`.
  Tests using `Clock.Frozen.freeze/1` will not freeze event `occurred_at`
  timestamps written via `Events.append/1`. Phase 6 LINT-12
  (`NoDirectDateTimeNow`) will catch this, but it's a live bug until
  then. `Events.append_multi/3` does NOT go through `normalize/1`'s
  lazy-default for the same field when the caller supplies `occurred_at`
  explicitly (which `Outbound` always does), so the sync/async hot paths
  are unaffected. The bug surfaces in `Tracking.Plug` (already passes
  `occurred_at: Clock.utc_now()`) and any adopter calling `append/1`
  without an explicit `occurred_at`.

Criterion-level correctness is verified: the 5 ROADMAP criteria pass
under `mix verify.phase_03`, and the api_stability.md contract is matched
point-for-point. Merge recommended **after** opening Phase 3.1 gap-closure
tickets for HI-01, HI-02, ME-01, ME-02.

## High Issues

### HI-01: MailerCase setup mutates global `:async_adapter` env under `async: true`

**File:** `test/support/mailer_case.ex:134,142`
**Category:** concurrency / test correctness
**Issue:** The default branch of `setup tags` runs `Application.put_env(:mailglass, :async_adapter, :task_supervisor)` on EVERY test invocation. `MailerCase` supports `async: true` (default). Multiple async tests running in parallel all write this global env concurrently. Worse, `on_exit` unconditionally restores to `:oban`:

```elixir
Application.put_env(:mailglass, :async_adapter, :task_supervisor)   # L134
# ...
on_exit(fn ->
  # ...
  Application.put_env(:mailglass, :async_adapter, :oban)             # L142
  # ...
end)
```

Two symptoms: (a) Test A's `setup` can set `:task_supervisor`, Test B's `on_exit` firing concurrently sets `:oban`, then Test A's body runs expecting `:task_supervisor` and calls `deliver_later`. Oban path taken. Fake.set_shared(self()) was set for test A, so the result is still routed to A — but the branch taken differs, defeating the test's intent. (b) If the adopter host-configures `:async_adapter, :task_supervisor` at boot, every on_exit now irrevocably rewrites it to `:oban`.

**Reproduction:** Run any two `MailerCase` async tests that exercise `deliver_later` concurrently under load. Occasional flakiness observed in long-run CI is often this class.

**Fix:** Two options, pick one:

1. **Make the mutation a `@moduletag :async false`-only path.** Guard the Application.put_env inside the `case async? do` branch so it only runs when `async? == false`:
   ```elixir
   unless async? do
     Application.put_env(:mailglass, :async_adapter, :task_supervisor)
   end
   ```
   Tests that want `task_supervisor` then need `use Mailglass.MailerCase, async: false`. Mirrors the I-12 guard already present for `@tag oban:`.

2. **Read-through opts instead of global env.** Threading `:async_adapter` through `deliver_later/2` opts (already partially supported: `Keyword.get(opts, :async_adapter)` in `outbound.ex:331`) and teaching MailerCase to inject `Process.put({:mailglass, :deliver_opts}, async_adapter: :task_supervisor)` for per-process isolation. Bigger change; defer to Phase 3.1 if (1) is infeasible.

Additionally, on_exit should restore to the pre-setup value:
```elixir
prior = Application.get_env(:mailglass, :async_adapter)
# ... setup mutations ...
on_exit(fn ->
  Application.put_env(:mailglass, :async_adapter, prior)
end)
```

### HI-02: Tracking Rewriter and Plug have divergent endpoint fallback chains

**File:** `lib/mailglass/tracking/rewriter.ex:222-226` vs `lib/mailglass/tracking/plug.ex:142-145`
**Category:** correctness / security (defense-in-depth)
**Issue:** The two modules resolve the Phoenix.Token endpoint differently:

```elixir
# rewriter.ex (signing side)
defp endpoint_fallback do
  Application.get_env(:mailglass, :tracking, [])[:endpoint] ||
    Application.get_env(:mailglass, :adapter_endpoint) ||    # <-- extra fallback
    "mailglass-tracking-default-endpoint"
end

# plug.ex (verifying side)
defp endpoint do
  Application.get_env(:mailglass, :tracking, [])[:endpoint] ||
    "mailglass-tracking-default-endpoint"
end
```

If an adopter has `config :mailglass, :adapter_endpoint, MyApp.Endpoint` (not uncommon — matches Plug defaults) but has NOT set `config :mailglass, :tracking, endpoint:`, the Rewriter signs tokens with `MyApp.Endpoint` and the Plug verifies against the literal string `"mailglass-tracking-default-endpoint"`. Phoenix.Token derives keys from the endpoint, so verification always fails. Users see pixel loads return 204 and click URLs return 404 — no pixels record, no clicks record. No log message (the 204 path is deliberately silent per D-39).

Additionally, the fallback string `"mailglass-tracking-default-endpoint"` is an in-source constant. Phoenix.Token's HMAC seed derives from `endpoint.secret_key_base + salt`; when endpoint is a plain string Phoenix.Token uses it as raw key material. The `salts` config is required (Token.salts/0 raises if missing), so key entropy comes from the salt — but a hard-coded endpoint fallback string is still a defense-in-depth regression.

**Reproduction:** `config :mailglass, :adapter_endpoint, SomeEndpoint` (without `:tracking, endpoint:`), enable tracking on a mailable, send a message, fetch the pixel URL — 204 response, no event recorded. Running `Tracking.Token.verify_open(endpoint(), token)` in the Plug's endpoint context yields `:error` while the signing path used a different endpoint.

**Fix:** Centralize the fallback in a single module — either put it on `Mailglass.Tracking` or create `Mailglass.Tracking.Endpoint`:

```elixir
# lib/mailglass/tracking.ex
def endpoint do
  Application.get_env(:mailglass, :tracking, [])[:endpoint] ||
    raise Mailglass.ConfigError.new(:missing,
      context: %{key: :tracking_endpoint,
                 hint: "config :mailglass, :tracking, endpoint: MyApp.Endpoint"})
end
```

Both rewriter + plug call `Tracking.endpoint/0`. Raise-on-missing is a safer default than falling back to a hard-coded literal — the `ConfigValidator` already raises `:tracking_host_missing` when tracking is enabled without a host; `:tracking_endpoint_missing` would pair naturally.

## Medium Issues

### ME-01: `Events.append/1` uses `DateTime.utc_now/0` directly, bypassing `Mailglass.Clock`

**File:** `lib/mailglass/events.ex:160`
**Category:** bug / convention
**Issue:**
```elixir
|> Map.put_new_lazy(:occurred_at, &DateTime.utc_now/0)
```

`Mailglass.Clock.utc_now/0` is the single legitimate source of wall-clock time per TEST-05 and the api_stability.md §Clock section. Phase 6 LINT-12 (`NoDirectDateTimeNow`) will catch this, but the live bug is that `Mailglass.Clock.Frozen.freeze/1` in tests does not affect event `occurred_at` when `Events.append/1` is called without an explicit `occurred_at`. The hot-path Outbound code always passes `occurred_at: Clock.utc_now()` so the bug does not surface in UAT; it surfaces for `Mailglass.Tracking.Plug` (already compliant because it passes `occurred_at`) and any adopter-authored admin / doctor tool that calls `Events.append(%{type: :audit})`.

**Reproduction:**
```elixir
test "frozen clock does not freeze event occurred_at" do
  frozen = ~U[2026-01-01 00:00:00.000000Z]
  Mailglass.Clock.Frozen.freeze(frozen)
  Mailglass.Tenancy.put_current("test")
  {:ok, event} = Mailglass.Events.append(%{type: :queued, delivery_id: Ecto.UUID.generate()})
  assert event.occurred_at == frozen  # FAILS — event.occurred_at is wall-clock now
end
```

**Fix:**
```elixir
defp normalize(attrs) do
  attrs
  |> Map.new()
  |> Map.put_new_lazy(:tenant_id, &Tenancy.current/0)
  |> Map.put_new_lazy(:trace_id, &current_trace_id/0)
  |> Map.put_new_lazy(:occurred_at, &Mailglass.Clock.utc_now/0)  # <-- change
  |> Map.put_new(:normalized_payload, %{})
  |> Map.put_new(:metadata, %{})
end
```

### ME-02: `Mailglass.Error.BatchFailed.format_message/2` is fragile and partial

**File:** `lib/mailglass/errors/batch_failed.ex:77-81`
**Category:** bug / dead-code
**Issue:**
```elixir
defp format_message(:partial_failure, ctx) do
  failed = length(ctx[:failures] || []) |> then(fn 0 -> ctx[:failed_count] || "some" end)
  total = ctx[:count] || "the"
  "Batch send partially failed: #{failed} of #{total} deliveries failed"
end
```

Two problems:
1. The anonymous function `fn 0 -> ... end` only matches `0`. If `ctx[:failures]` is a non-empty list (length > 0), this raises `FunctionClauseError`. Today, callers never put `:failures` in context (they pass it as a top-level keyword on `new/2`), so the expression ALWAYS evaluates `length([]) = 0` and the then-clause always fires — it works by accident, not by design.
2. `ctx[:failures]` is not threaded by any caller in `lib/mailglass/outbound.ex:198,204` — those pass `%{count: N, failed_count: M}` in context and `failures: [...]` at top level. The `length(ctx[:failures] || [])` path is dead.

**Reproduction:** Add a test that constructs `BatchFailed.new(:partial_failure, context: %{count: 2, failed_count: 1, failures: [%Delivery{}]})`. The `format_message` call crashes with `FunctionClauseError` because `length` returns 1, which the `fn 0 -> _ end` clause does not match.

**Fix:** Simplify to the actual caller contract:
```elixir
defp format_message(:partial_failure, ctx) do
  failed = ctx[:failed_count] || "some"
  total = ctx[:count] || "the"
  "Batch send partially failed: #{failed} of #{total} deliveries failed"
end
```

### ME-03: `Outbound.rehydrate_message` uses `String.to_atom/1` (not `to_existing_atom/1`)

**File:** `lib/mailglass/outbound.ex:833`
**Category:** security / memory exhaustion
**Issue:**
```elixir
mod_str when is_binary(mod_str) ->
  mod_atom = String.to_atom("Elixir." <> mod_str)    # <-- unbounded
```

`String.to_atom/1` creates a new atom each call. Atoms are never garbage-collected. `delivery.mailable` is a text column populated from `inspect(msg.mailable)` at enqueue time — so in normal operation the set of distinct values is small (one per adopter-defined mailable module). But: if the DB row were tampered with (SQL injection, malicious dump restore, corrupted backup), each distinct bad value bloats the atom table. The BEAM's default atom limit is 1,048,576; exhaustion crashes the node.

The fallback branch at line 857 correctly uses `String.to_existing_atom/1` with rescue → structured error. The primary branch should do the same.

**Reproduction:** Manually `UPDATE mailglass_deliveries SET mailable = 'Attacker.Module.' || gen_random_uuid()::text FROM <n rows>;` then replay via dispatch_by_id. Each replay consumes one atom permanently.

**Fix:** Swap to `to_existing_atom`:
```elixir
mod_str when is_binary(mod_str) ->
  mod_atom_result =
    try do
      {:ok, String.to_existing_atom("Elixir." <> mod_str)}
    rescue
      ArgumentError -> :no_module
    end

  case mod_atom_result do
    {:ok, mod_atom} ->
      # ... same body as current primary branch ...
    :no_module ->
      # fallback to current rescue path — try to_existing_atom without Elixir. prefix
      # ...
  end
```

Or more directly, the existing fallback branch already handles this correctly — collapse the two branches and always use `to_existing_atom`:
```elixir
try do
  mod_atom = String.to_existing_atom("Elixir." <> mod_str)
  # ... body ...
rescue
  ArgumentError ->
    try do
      mod = String.to_existing_atom(mod_str)
      # ... body ...
    rescue
      ArgumentError -> {:error, Mailglass.SendError.new(:adapter_failure, ...)}
    end
end
```

### ME-04: `Projector.safe_broadcast/2` rescue list is narrow

**File:** `lib/mailglass/outbound/projector.ex:180-192`
**Category:** defensive programming
**Issue:**
```elixir
defp safe_broadcast(topic, payload) do
  Phoenix.PubSub.broadcast(Mailglass.PubSub, topic, payload)
rescue
  e in [ArgumentError, RuntimeError] -> ...
end
```

`Phoenix.PubSub.broadcast/3` can raise more than `ArgumentError`/`RuntimeError` depending on the adapter — notably `:exit` from a GenServer call when the PubSub server is terminating. `rescue` does not catch exits; that requires `catch :exit, _` or `try/catch`. Under normal conditions this is fine; during graceful shutdown or a node partition the broadcast could exit-kill the caller's process.

The Phase 3 pipeline already persists the delivery + event before broadcasting (D-04: "broadcast runs AFTER commit"), so a broadcast-induced exit does not corrupt the ledger. But the exit propagates into the caller (e.g. the Task.Supervisor task dispatching an async send), killing what should have succeeded.

**Reproduction:** Stop the `Mailglass.PubSub` child via `Supervisor.terminate_child/2`, then call `broadcast_delivery_updated/3`. The current rescue does not catch the `:exit, :noproc`.

**Fix:**
```elixir
defp safe_broadcast(topic, payload) do
  Phoenix.PubSub.broadcast(Mailglass.PubSub, topic, payload)
rescue
  e in [ArgumentError, RuntimeError] -> log_and_ok(e)
catch
  :exit, reason -> log_and_ok(reason)
end
```

### ME-05: `dispatch_result.provider_response` may not be a map

**File:** `lib/mailglass/outbound.ex:280`
**Category:** bug (latent)
**Issue:**
```elixir
Projector.broadcast_delivery_updated(updated, :dispatched, %{
  tenant_id: updated.tenant_id,
  delivery_id: updated.id,
  provider: inspect(Map.get(dispatch_result.provider_response, :adapter, :unknown))
})
```

`provider_response` is adapter-defined (see `Mailglass.Adapter` callback — `provider_response :: term()`). For `Adapters.Fake` it's `%{adapter: :fake}`; for `Adapters.Swoosh` it's the raw Swoosh map. A custom adapter returning a non-map `provider_response` (list, tuple, binary) hits `Map.get/3` with a non-map first arg → raises `BadMapError`.

**Reproduction:** Define a custom adapter returning `{:ok, %{message_id: "abc", provider_response: "raw_json_string"}}` — each sync send crashes at this line.

**Fix:**
```elixir
provider: provider_tag(dispatch_result.provider_response)

# ...

defp provider_tag(%{adapter: a}), do: inspect(a)
defp provider_tag(_), do: "unknown"
```

## Low Issues

### LO-01: `Mailglass.Outbound.send/2` shadows `Kernel.send/2`

**File:** `lib/mailglass/outbound.ex:89`
**Category:** naming / stylistic
**Issue:** `def send(%Message{} = msg, opts \\ [])` defines `send/2` at the module level. `Kernel.send/2` is auto-imported. Inside the module body there is no `import Kernel, except: [send: 2]` — which means any `send(pid, msg)` expression inside `Mailglass.Outbound` now resolves to the local function (and would fail pattern-match on `%Message{}`). The module does not call `Kernel.send` anywhere, so no live bug, but future edits risk a silent mis-dispatch. api_stability.md documents this as the internal verb with `deliver/2` as the public alias, so the name is deliberate.

**Fix (optional):** Add a comment at the function head documenting the shadow, or add an explicit `import Kernel, except: [send: 2]` to make the intent load-bearing:
```elixir
import Kernel, except: [send: 2]  # Mailglass.Outbound.send/2 is the canonical internal verb
```

### LO-02: `BatchFailed.format_message` "some" placeholder is a message-string dependency

**File:** `lib/mailglass/errors/batch_failed.ex:78,84`
**Category:** convention / brand voice
**Issue:** Error messages with placeholder strings like `"Batch send partially failed: some of the deliveries failed"` violate the brand voice ("clear, exact"). If `:failed_count` is missing from context the message degrades to an unhelpful sentence. Current callers (`outbound.ex:204`) always set `failed_count`, so the placeholder path is dead — but the message shape is the adopter-facing surface, and "some of the" is neither clear nor exact.

**Fix:** Require `:count` and `:failed_count` at construction, raise a clearer error on misuse:
```elixir
def new(type, opts \\ []) when type in @types do
  ctx = opts[:context] || %{}
  failures = opts[:failures] || []
  unless Map.has_key?(ctx, :count) do
    raise ArgumentError, "Mailglass.Error.BatchFailed.new/2: :count required in context"
  end
  # ...
end
```

### LO-03: `Outbound.serialize_error/1` drops `:message` when error has no `__exception__: true`

**File:** `lib/mailglass/outbound.ex:775-782`
**Category:** minor bug
**Issue:**
```elixir
defp serialize_error(%{__exception__: true, __struct__: mod} = err) do
  base = %{module: Atom.to_string(mod), message: Exception.message(err)}
  case err do
    %{type: t} when is_atom(t) -> Map.put(base, :type, t)
    _ -> base
  end
end
```

There is no second clause — if a non-exception map sneaks in (e.g., an `Ecto.Changeset`), `serialize_error/1` raises FunctionClauseError. `call_adapter_or_persist_failure/3` routes `Ecto.Changeset` through `to_error/1` which wraps it in `%SendError{}`, so the happy path is fine. But `persist_failed_by_id/2` at line 728 only accepts `%{__exception__: true}` as well, silently dropping non-exception errors (line 747 only passes `err` into `serialize_error` which then raises). The chain depends on every caller pre-wrapping, which is fragile.

**Fix:** Add a fallback clause:
```elixir
defp serialize_error(other) do
  %{module: "unknown", message: inspect(other, limit: 50)}
end
```

### LO-04: `Mailable.__using__` macro does not enforce `use` opts schema

**File:** `lib/mailglass/mailable.ex:122-144`
**Category:** defensive API
**Issue:** The `use Mailglass.Mailable, stream: :transactional, tracking: [opens: true], foo: :bar` expression accepts arbitrary keyword keys. `:foo` is silently stored in `@mailglass_opts`. This means typos (`tracking_opens: true` vs `tracking: [opens: true]`) produce no warning — tracking remains off-by-default, and the adopter may not discover the typo until they inspect `__mailglass_opts__/0` manually.

**Fix:** Validate with NimbleOptions at compile time:
```elixir
@use_opts_schema [
  stream: [type: {:in, [:transactional, :operational, :bulk]}, default: :transactional],
  tracking: [type: :keyword_list, default: [],
             keys: [opens: [type: :boolean, default: false],
                    clicks: [type: :boolean, default: false]]],
  from_default: [type: :any, default: nil],
  reply_to_default: [type: :any, default: nil]
]

defmacro __using__(opts) do
  validated = NimbleOptions.validate!(opts, @use_opts_schema)
  quote bind_quoted: [opts: validated] do
    # ...
  end
end
```

### LO-05: `Tracking.Plug.record_open_event/2` rescue swallows all exceptions

**File:** `lib/mailglass/tracking/plug.ex:93-114`
**Category:** observability
**Issue:**
```elixir
defp record_open_event(delivery_id, tenant_id) do
  # ... Events.append + telemetry.execute ...
rescue
  _ -> :ok
end
```

api_stability.md §Tracking.Plug says "DB write failures are swallowed — the pixel and redirect responses ALWAYS succeed." The intent is correct (responding 200/302 to the user must not fail because of a DB error). But the rescue is `_`, which also masks programming errors (ArgumentError, KeyError, etc.) and never emits any trace. Under sustained DB failure, the telemetry at line 104 also never fires — the `:telemetry.execute` call is INSIDE the block and rescued. Operators get zero signal.

**Fix:** Narrow the rescue and always emit telemetry:
```elixir
defp record_open_event(delivery_id, tenant_id) do
  :telemetry.execute([:mailglass, :tracking, :open, :recorded], %{count: 1},
                     %{delivery_id: delivery_id, tenant_id: tenant_id})

  Mailglass.Tenancy.with_tenant(tenant_id, fn ->
    Mailglass.Events.append(%{
      tenant_id: tenant_id, delivery_id: delivery_id, type: :opened,
      occurred_at: Mailglass.Clock.utc_now(), normalized_payload: %{source: :pixel}
    })
  end)
rescue
  e in [DBConnection.ConnectionError, Postgrex.Error, Ecto.InvalidChangesetError] ->
    require Logger
    Logger.warning("[mailglass] tracking open event persist failed: #{Exception.message(e)}")
    :ok
end
```

### LO-06: `config/test.exs:42` sets `:logger, level: :warning`, masking test diagnostics

**File:** `config/test.exs:41-42`
**Category:** test hygiene
**Issue:** `config :logger, level: :warning` suppresses `:info` and `:debug`. This hides `Logger.debug("[mailglass] PubSub broadcast failed …")` in `Projector.safe_broadcast` and `Logger.debug("[mailglass] Tracking.Rewriter: Floki.parse_document failed …")`. When a test fails because of one of these code paths, operators have no trail.

**Fix:** Keep at `:info` (or `:debug` under CI-tagged runs) and use capture-log opt-in for tests that should silence noise:
```elixir
config :logger, level: :info
# In specific tests: ExUnit.CaptureLog.capture_log(fn -> ... end)
```

The original rationale ("suppress the Oban boot warning") is better solved by setting the async_adapter to :task_supervisor in the test config — which is already done at line 39, so the :warning level is no longer needed.

## Nits

### NI-01: `Mailable` declares `@optional_callbacks` before the `@callback` it references

**File:** `lib/mailglass/mailable.ex:111-112`
**Issue:**
```elixir
@optional_callbacks preview_props: 0
@callback preview_props() :: [{atom(), map()}]
```

Works correctly (optional_callbacks accepts a forward reference), but convention is to declare `@callback` first.

**Fix:** Reorder:
```elixir
@callback preview_props() :: [{atom(), map()}]
@optional_callbacks preview_props: 0
```

### NI-02: `Mailglass.Message.put_metadata` tolerates `nil` metadata but the type spec says `%{atom() => term()}`

**File:** `lib/mailglass/message.ex:60,199-202`
**Issue:** `@type t` declares `metadata: %{atom() => term()}` but `put_metadata/3` accepts `nil` via `Map.put(meta || %{}, key, value)`. The nil tolerance is for safety in case someone constructs a `%Message{metadata: nil}` via `%Message{}` literal, but then the struct default is `metadata: %{}` and `new/2` uses `Keyword.get(opts, :metadata, %{})`, so `nil` cannot legitimately occur.

**Fix:** Either drop `meta || %{}` (let a latent nil raise visibly) or update the type spec to `%{atom() => term()} | nil`. Preference: drop the fallback, fail-loud on the unreachable case.

### NI-03: `Outbound.do_deliver_many/2` silently drops `_opts`

**File:** `lib/mailglass/outbound.ex:441`
**Issue:**
```elixir
defp do_deliver_many(messages, _opts) do
  # ... never consults opts ...
end
```

`deliver_many/2` accepts opts and passes them through, but all callees underscore-match and drop them. Adopters setting `adapter:` or `async_adapter:` in opts for `deliver_many/2` are silently ignored — unlike `deliver/2` which honours both.

**Fix:** Either document in api_stability that deliver_many ignores opts at v0.1, or thread them into `insert_batch/enqueue_batch_jobs`. Minor documentation shift for v0.1.

### NI-04: `Tenancy.assert_stamped!` delegates to `tenant_id!` which re-reads the process dict

**File:** `lib/mailglass/tenancy.ex:126-131,143-147`
**Issue:** `assert_stamped!/0` calls `tenant_id!/0` which does its own process dict read + raise. One extra process dict probe vs. inlining is negligible, but the doc on `assert_stamped!` says "does NOT fall back" which is true of `tenant_id!` too. Could collapse to one function.

**Fix:** Either leave as-is (the two names carry different semantics in api_stability.md) or have `assert_stamped!` return `:ok | no_return()` and document that semantically. Cosmetic.

## Pass/Fail Gate Assessment

**Recommendation: PASS (merge) with Phase 3.1 gap-closure tickets for HI-01, HI-02, ME-01, ME-02.**

Rationale:
- No critical-severity findings; no merge-blockers.
- The two HIGH findings (HI-01, HI-02) are latent bugs that the UAT gate + current test fixtures do not exercise. They will bite first-use adopters (HI-02) or intermittent CI (HI-01) — both are fixable in a small follow-up commit.
- ME-01 (DateTime.utc_now in events.ex) is pre-Phase 6 lint coverage — fix when LINT-12 lands.
- ME-02 (BatchFailed format_message) is dead-code latency, not a live crash path.
- Locked invariants are intact: D-20 (adapter outside transaction), D-06 (event-ledger immutability), D-08 (tracking off-by-default), D-13 (Fake as release gate), D-18 (tenancy assert_stamped! precondition), D-31 (telemetry PII whitelist), D-38 (tracking auth-stream guard). Criterion-level UAT (mix verify.phase_03: 61 tests, 0 failures, 2 skipped) passes.
- api_stability.md matches the implementation point-for-point. No documented contract was violated.

**Recommended Phase 3.1 tickets:**
1. HI-01 (MailerCase async-adapter env race) — single-digit LoC fix
2. HI-02 (Tracking endpoint fallback divergence) — one-module refactor
3. ME-01 (Events.append Clock usage) — one-line fix
4. ME-02 (BatchFailed format_message) — one-function simplification
5. ME-03 (rehydrate_message to_existing_atom) — defensive
6. ME-04 (safe_broadcast exit catching) — defensive
7. ME-05 (provider_response map guard) — defensive

---

_Reviewed: 2026-04-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
