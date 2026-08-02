# Phase 149: First-Send Contract Foundation - Pattern Map

**Mapped:** 2026-08-02  
**Files analyzed:** 16 likely created or modified files  
**Analogs found:** 15 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/outbound/preflight.ex` (new, if extracted) | service / utility | transform | private `preflight_single/1` in `lib/mailglass/outbound.ex` | partial-match |
| `lib/mailglass/outbound.ex` | service / orchestrator | request-response, CRUD | itself: `do_send/2`, `do_deliver_later/2`, `preflight_single/1` | exact |
| `lib/mailglass/renderer.ex` | service | transform | itself: `render/2` pipeline | exact |
| `lib/mailglass/tenancy.ex` | service / behaviour facade | request-response | itself: `current/0`, `tenant_id!/0`, resolver fallback | exact |
| `lib/mailglass/config.ex` | config | request-response | existing schema and validated-config pattern | role-match |
| `test/mailglass/outbound/preflight_test.exs` | test | request-response, CRUD | itself: staged short-circuit/no-row assertions | exact |
| `test/mailglass/outbound/deliver_later_test.exs` | test | request-response, CRUD | itself: async setup and no-delivery assertion | exact |
| `test/mailglass/outbound_test.exs` | test | request-response, CRUD | itself: sync Fake adapter and persisted-delivery assertions | exact |
| `test/mailglass/renderer_test.exs` | test | transform | itself: direct renderer input/output assertions | exact |
| `test/mailglass/tenancy_test.exs` | test | request-response | itself: process-dictionary and resolver-default tests | exact |
| `mailglass_admin/test/mailglass_admin/preview_live_test.exs` | test | request-response | itself: HTML/Text tab parity assertions | exact |
| `docs/api_stability.md` | documentation | transform | its typed-error, tenancy, and pipeline contract sections | exact |
| `guides/authoring-mailables.md` | documentation | request-response | its native setter + sync/async examples | exact |
| `guides/getting-started.md` | documentation | request-response | its first-message walkthrough | exact |
| `guides/jobs.md` | documentation | request-response | Jobs 2 and 4 renderer/async promises | exact |
| `guides/preview.md` and `guides/multi-tenancy.md` | documentation | request-response | their production-renderer and zero-config tenancy sections | exact |

`mailglass_admin/lib/mailglass_admin/preview_live.ex` is a read-only integration analog rather than a planned production edit: it already delegates to `Mailglass.Renderer.render/1`. Keep preview logic there unchanged; add parity coverage through its existing test seam.

## Pattern Assignments

### `lib/mailglass/outbound/preflight.ex` (new internal service, transform)

**Analog:** `lib/mailglass/outbound.ex` private `preflight_single/1` (lines 535-545), plus the existing `with` paths (lines 288-297 and 350-360).

**Boundary/import pattern:** If extraction is chosen, make it an internal `Mailglass.Outbound.*` sub-boundary and depend only on modules already legal to `Outbound`. Do not create a public authoring API or alter durable-envelope storage (Phase 150).

**Core short-circuit pattern** (lines 535-545):

```elixir
defp preflight_single(%Message{} = msg) do
  with :ok <- Tracking.Guard.assert_safe!(msg),
       :ok <- Suppression.check_before_send(msg),
       :ok <- RateLimiter.check(msg),
       :ok <- Stream.policy_check(msg),
       {:ok, rendered} <- Renderer.render(msg) do
    {:ok, prepare_outbound_message(rendered)}
  else
    {:error, err} -> {:error, err, msg}
    {:error, _step, err, _} -> {:error, to_error(err), msg}
  end
end
```

**Required Phase-149 adaptation:** put the new pure tenant normalization plus `to ++ cc ++ bcc` / supported-body validation *before* this existing effectful chain, return `{:ok, normalized_message}` or the established typed error, then pass the normalized message onward. The helper must neither insert deliveries/jobs nor invoke renderer, rate limiter, suppression, tracking, or an adapter on rejection. `preflight_single/1` is the closest behavior analog, but the new gate is intentionally earlier than its first line.

**Typed error pattern:** `lib/mailglass/errors/send_error.ex` lines 56-72 constructs only closed error types, and lines 82-85 provide the branded `:preflight_rejected` message. Reuse `Mailglass.SendError.new(:preflight_rejected, context: bounded_non_pii_map)`; do not add a type atom or include envelope/body values in context.

---

### `lib/mailglass/outbound.ex` (service/orchestrator, request-response and CRUD)

**Analog:** its three current convergence paths.

**Imports and Boundary pattern** (lines 57-84):

```elixir
use Boundary,
  deps: [Mailglass],
  exports: [Delivery, Projector] ++ @oban_exports

alias Mailglass.{
  Clock, Compliance, Config, Events, Message, Renderer, Repo, Suppression,
  RateLimiter, Stream, Tenancy, Telemetry
}
alias Mailglass.Outbound.{Delivery, Projector}
alias Mailglass.Tracking
```

**Sync ordering pattern** (lines 288-297):

```elixir
with :ok <- Tenancy.assert_stamped!(),
     :ok <- Tracking.Guard.assert_safe!(msg),
     :ok <- Suppression.check_before_send(msg),
     :ok <- RateLimiter.check(msg),
     :ok <- Stream.policy_check(msg),
     {:ok, rendered} <- Renderer.render(msg) do
  do_send_after_preflight(prepare_outbound_message(rendered), opts)
end
```

Replace the tenancy-first step with shared preflight and retain all later stage ordering. The first persistence remains in `do_send_after_preflight/2` (lines 300-325); leave the adapter outside the transaction per lines 328-343.

**Async ordering pattern** (lines 350-360):

```elixir
with :ok <- Tenancy.assert_stamped!(),
     :ok <- Tracking.Guard.assert_safe!(msg),
     :ok <- Suppression.check_before_send(msg),
     :ok <- RateLimiter.check(msg),
     :ok <- Stream.policy_check(msg),
     {:ok, rendered} <- Renderer.render(msg),
     prepared = prepare_outbound_message(rendered),
     {:ok, adapter_ref} <- resolve_async_adapter_ref(prepared, opts) do
  enqueue_via_async_adapter(prepared, adapter_ref, opts)
end
```

**Batch reuse pattern** (lines 500-545): preserve per-message `{:ok, msg}` / `{:error, err, msg}` partitioning and call the same shared preflight for every batch item. Do not redesign `insert_batch/1`, Oban arguments, private payloads, or atomic enqueue; those are explicitly Phase 150.

---

### `lib/mailglass/renderer.ex` (pure service, transform)

**Analog:** existing single render pipeline in the same module (lines 63-107 and 236-254).

**Imports / telemetry pattern** (lines 35-38 and 63-84):

```elixir
alias Mailglass.Message
alias Mailglass.Telemetry
alias Mailglass.TemplateEngine.HEEx
alias Mailglass.TemplateError

Telemetry.render_span(metadata, fn ->
  with {:ok, html_iodata} <- render_html(message, opts),
       html_binary = IO.iodata_to_binary(html_iodata),
       plaintext = to_plaintext(html_binary),
       {:ok, inlined_html} <- inline_css(html_binary) do
    final_html = strip_mg_attributes(inlined_html)
    {:ok, %{message | swoosh_email: updated_email}}
  end
end)
```

Keep this `Telemetry.render_span/2` envelope and this module as the one renderer consumed by direct render, outbound, and preview. Change only the body-shape branches: preserve a non-empty explicit `text_body`; allow text-only messages without calling `render_html/2`; derive plaintext only for an HTML-only message when the renderer setting enables it; and call `strip_mg_attributes/1` after either configured HTML branch.

**Supported HTML/error pattern** (lines 89-106):

```elixir
defp render_html(%Message{swoosh_email: %{html_body: fun}}, opts)
     when is_function(fun, 1), do: HEEx.render(fun, %{}, opts)

defp render_html(%Message{swoosh_email: %{html_body: html}}, _opts)
     when is_binary(html) or is_nil(html), do: {:ok, html || ""}

defp render_html(_message, _opts) do
  {:error, TemplateError.new(:heex_compile, context: %{reason: "..."})}
end
```

Preflight owns rejection of invalid or empty outbound body shapes; Renderer should retain its current `TemplateError` surface for direct-render invalid HTML. Do not introduce a preview-only transformation.

**CSS error pattern** (lines 238-247):

```elixir
defp inline_css(html) when is_binary(html) do
  inlined = Premailex.to_inline_css(html)
  {:ok, inlined}
rescue
  e ->
    {:error, TemplateError.new(:inliner_failed, cause: e,
      context: %{reason: Exception.message(e)})}
end
```

Branch this exact stage on the validated `renderer.css_inliner` setting: `:premailex` retains it, `:none` returns HTML unchanged. Do not duplicate the whole pipeline.

---

### `lib/mailglass/tenancy.ex` (behaviour facade, request-response)

**Analog:** resolver-aware `current/0` and strict stamped-only methods.

**Effective-default pattern** (lines 163-166 and 385-404):

```elixir
def current do
  Process.get(@process_dict_key) || default_tenant()
end

defp resolver do
  case Application.get_env(:mailglass, :tenancy) do
    nil -> Mailglass.Tenancy.SingleTenant
    mod when is_atom(mod) -> mod
  end
end

defp default_tenant do
  case resolver() do
    Mailglass.Tenancy.SingleTenant -> "default"
    _ -> nil
  end
end
```

**Fail-closed pattern** (lines 237-258):

```elixir
def tenant_id! do
  case Process.get(@process_dict_key) do
    nil -> raise Mailglass.TenancyError.new(:unstamped)
    tenant_id when is_binary(tenant_id) -> tenant_id
  end
end

def assert_stamped! do
  _ = tenant_id!()
  :ok
end
```

Phase 149 should use the existing resolver distinction to make outbound normalizing logic accept unstamped `SingleTenant` as `"default"`, while retaining strict failure for every custom resolver. Keep `assert_stamped!/0` semantics unchanged unless a narrow helper makes this distinction explicit; worker restoration must still be fail-closed.

---

### `lib/mailglass/config.ex` (config, request-response)

**Analog:** renderer schema at lines 77-92 and centralized validated access at lines 787-797.

```elixir
renderer: [
  type: :keyword_list,
  default: [],
  doc: "Renderer options.",
  keys: [
    css_inliner: [type: {:in, [:premailex, :none]}, default: :premailex],
    plaintext: [type: :boolean, default: true]
  ]
]

defp validated_config do
  :mailglass
  |> Application.get_all_env()
  |> Keyword.take(Keyword.keys(@schema))
  |> normalize_optional_keyword_subtrees()
  |> NimbleOptions.validate!(@schema)
  |> validate_adapter_config!()
  |> validate_mailgun_replay_window!()
end
```

The schema already defines the public switches. If Renderer needs an accessor, expose it through `Mailglass.Config` and validated configuration rather than reading application env in Renderer. Preserve `Config` as the only configuration gateway.

---

### Test files (test, exact focused analogs)

#### `test/mailglass/outbound/preflight_test.exs`

**Analog:** lines 44-79 and 137-180 show the project’s short-circuit pattern: invoke the public path, match the error struct/type, then assert no `Delivery` row. Lines 183-201 are the shared valid-message builder. Extend this file with recipient/body matrix cases, no-render/no-rate-limit/no-Fake assertions, and unstamped SingleTenant normalization; do not assert recipient/body contents in error context.

```elixir
assert {:error, %Mailglass.SuppressedError{context: context}} = Outbound.send(msg)

count =
  TestRepo.aggregate(from(d in Delivery, where: d.recipient == "blocked@example.com"), :count)

assert count == 0
```

#### `test/mailglass/outbound/deliver_later_test.exs`

**Analog:** lines 1-70 use `DataCase, async: false`, shared sandbox ownership, environment capture/restoration, and `:task_supervisor` fallback. Lines 176-196 provide the async preflight/no-delivery pattern.

```elixir
msg = build_message(addr)
assert {:error, %Mailglass.SuppressedError{}} = Outbound.deliver_later(msg)

count = TestRepo.aggregate(from(d in Delivery, where: d.recipient == ^addr), :count)
assert count == 0
```

Extend for default tenant persisted/enqueued as `"default"` and invalid envelope/body before jobs. Do not redesign the job payload or atomic transaction in this phase.

#### `test/mailglass/outbound_test.exs`

**Analog:** lines 63-105 provide the synchronous happy-path contract with Fake adapter and persisted Delivery/Event assertions.

```elixir
assert {:ok, %Delivery{status: :sent, tenant_id: "test-tenant"} = delivery} =
         Outbound.send(msg)

[record] = Fake.deliveries()
assert record.message.swoosh_email.to == [{"", "happy@example.com"}]
```

Use this file for direct sync contract proof after preflight, including renderer-switch behavior if the test needs actual dispatched output.

#### `test/mailglass/renderer_test.exs`

**Analog:** lines 15-50 directly build `Swoosh.Email`, wrap it with `Message.build/2`, call `Renderer.render/1`, then inspect `html_body` and `text_body`. Lines 145-152 match the existing direct-render `TemplateError` behavior.

```elixir
email = %Swoosh.Email{html_body: component}
message = Mailglass.Message.build(email, tenant_id: "t")

assert {:ok, rendered} = Mailglass.Renderer.render(message)
html = rendered.swoosh_email.html_body
```

Add explicit-text preservation, text-only, plaintext enabled/disabled HTML-only, and `:none` CSS behavior here. Retain direct-render error coverage separately from outbound `SendError` preflight coverage.

#### `test/mailglass/tenancy_test.exs`

**Analog:** lines 35-40 prove default resolution; lines 92-105 and 124-144 prove stamped-only strictness.

```elixir
Process.delete(:mailglass_tenant_id)
assert Tenancy.current() == "default"

err = assert_raise TenancyError, fn -> Tenancy.tenant_id!() end
assert err.type == :unstamped
```

Add only resolver-distinction coverage needed by outbound preflight. `current/0` remains default-capable; `tenant_id!/0` and custom resolver context remain strict.

#### `mailglass_admin/test/mailglass_admin/preview_live_test.exs`

**Analog:** the HTML/Text tab test at lines 369-376 renders the LiveView, switches the selected tab, and verifies text output. The production seam is `mailglass_admin/lib/mailglass_admin/preview_live.ex` lines 805-840:

```elixir
case build_and_render(mod, scenario, assigns_map) do
  {:ok, rendered} ->
    email = rendered.swoosh_email
    assign(socket, :html_body, email.html_body || "")
    |> assign(:text_body, email.text_body || "")
end

Mailglass.Renderer.render(msg)
```

Add configuration parity coverage through this UI test or a focused regression test; leave `PreviewLive` delegating to the core renderer.

---

### Documentation files (documentation, request-response)

**Analog:** maintain existing guide style: a short behavioral statement followed by native setter/config code. Do not document Phase-150 envelope storage or Phase-151 dispatch outcomes as shipped.

- `guides/authoring-mailables.md` lines 13-27 demonstrate native `new() |> to |> from |> subject |> html_body |> text_body`; lines 46-63 show sync/async consumption. Use this pattern to state exactly-one-recipient and valid body requirements, plus authored-text behavior.
- `guides/getting-started.md` lines 57-78 are the first-send walkthrough. Extend its supported first message with default single-tenant behavior and an optional renderer configuration example if necessary.
- `guides/jobs.md` lines 118-141 promise preview runs the same renderer; lines 187-206 promise durable-or-fallback async. Update these claims to match the shared renderer and preflight, without claiming cross-client parity or wire-equivalence.
- `guides/preview.md` lines 1-6 state preview uses production rendering. Retain that lead and document resulting HTML/text parity only; no preview rendering fork.
- `guides/multi-tenancy.md` lines 5-18 are the zero-config default contract and lines 47-82 describe custom tenancy fail-loud routing. Correct `:default` terminology to tenant `"default"` where relevant and state that custom tenancy does not receive an implicit fallback.
- `docs/api_stability.md` lines 225-240 define the closed `SendError` set, lines 392-410 define `TenancyError`, and lines 1290-1317 record the preflight/persistence invariants. Update these inventory sections in-place: invalid envelope/body use the already-public `:preflight_rejected`; context excludes PII; and the Phase-149 shared preflight precedes all side effects. Do not alter the closed error atom sets.

## Shared Patterns

### Typed errors and privacy

**Sources:** `lib/mailglass/errors/send_error.ex` lines 24-72; `docs/api_stability.md` lines 225-240 and 754-756.

```elixir
@types [:adapter_failure, :rendering_failed, :preflight_rejected, :serialization_failed]

def new(type, opts \\ []) when type in @types do
  ctx = opts[:context] || %{}
  %__MODULE__{type: type, message: format_message(type, ctx), context: ctx}
end
```

Apply to recipient/body preflight errors. Context must be bounded and omit `:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`; tests should pattern-match the struct/type and safe reason/count fields, never a message string.

### Pure-before-effects ordering

**Sources:** `lib/mailglass/outbound.ex` lines 288-297, 350-360, and 535-545.

Put shared preflight before tracking, suppression, rate limiting, stream policy, rendering, persistence, enqueue, and dispatch in sync, async, and batch paths. Maintain `with` short-circuit semantics and use the normalized message afterwards.

### Renderer convergence

**Sources:** `lib/mailglass/renderer.ex` lines 63-84; `mailglass_admin/lib/mailglass_admin/preview_live.ex` lines 833-840.

All render consumers call `Mailglass.Renderer.render/1`. Config is read through `Mailglass.Config`; renderer owns HTML rendering, optional plaintext derivation, optional CSS inlining, and `data-mg-*` stripping. Preview only displays the returned message.

### Tenant resolution and custom fail-closed behavior

**Sources:** `lib/mailglass/tenancy.ex` lines 163-166, 237-258, and 385-404; `lib/mailglass/tenancy/single_tenant.ex` lines 23-32.

Use `SingleTenant`’s established `"default"` resolver result only for that resolver. A custom resolver with no stamped/restorable context remains an actionable `%Mailglass.TenancyError{type: :unstamped}` failure; no default fallback is permitted.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/mailglass/outbound/preflight.ex` (if created) | internal service | transform | No extracted pure outbound preflight module exists. Copy `Outbound`’s private `with`/tuple pattern, keep it internal, and do not promote it to stable API. |

## Metadata

**Analog search scope:** `lib/mailglass`, `mailglass_admin/lib`, `test/mailglass`, `mailglass_admin/test`, `guides`, `docs`  
**Files scanned:** 20 focused source/test/documentation files  
**Pattern extraction date:** 2026-08-02  
**Phase boundary:** No private durable-envelope persistence or atomic enqueue changes (Phase 150); no sync/async wire equivalence, dispatch outcome, retry, or payload-lifecycle work (Phase 151).
