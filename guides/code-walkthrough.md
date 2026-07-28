# Mailglass Code Walkthrough

**This guide starts where [How Mailglass Works](architecture.md) stops.** The
architecture guide gives you the system; this one puts real functions behind
that picture.

By the end, you should be able to open a Mailglass bug or feature, place it in
the send or webhook path, and know the next two or three modules to read. You
do not need to memorize the code. The goal is to make the repository feel
familiar before you enter it.

The excerpts below are the current implementation with comments and secondary
branches removed. A `# ...` marks a deliberate cut, never invented behavior.
Documented module and function names link into HexDocs; from a module page,
**View Source** opens the code for that exact release.

> #### Reading is not an API promise {: .warning}
>
> This tour includes private functions and internal modules because they carry
> the architecture. Reachability is not stability. Check the
> [API stability inventory](../docs/api_stability.md) before building adopter
> code on anything shown here.

## Keep one route in your head

The core package is easier to learn as a value moving through boundaries than
as a list of modules.

| Question | Follow this code |
|---|---|
| What is being sent? | `Mailglass.Mailable` manufactures a `Mailglass.Message`. |
| What turns it into email-client output? | `Mailglass.Renderer` compiles the bodies. |
| What decides whether and how it leaves? | `Mailglass.Outbound` applies policy and records intent. |
| What crosses the network? | `Mailglass.Adapter` hands the inner email to Swoosh. |
| What remembers the result? | `Mailglass.Events` records facts; `Mailglass.Outbound.Projector` updates the snapshot. |
| What changes the next send? | Verified webhook evidence can become suppression policy. |

We will follow that route once. Small side trips explain tenancy, schema
isolation, and the tests that reveal the intended design.

## A mailable manufactures the value

`use Mailglass.Mailable` writes a small builder API into an adopter module. The
important part of the macro is not metaprogramming cleverness. It makes all
mailables begin with the same Message constructor and end at the same outbound
boundary.

```elixir
defmacro __using__(opts) do
  quote bind_quoted: [opts: opts] do
    @behaviour Mailglass.Mailable
    @mailglass_opts opts

    import Mailglass.Message,
      only: [
        to: 2,
        from: 2,
        subject: 2,
        html_body: 2,
        text_body: 2,
        header: 3,
        attach: 2,
        put_tag: 2
      ]

    def new(assigns \\ []) do
      Mailglass.Message.new_from_use(__MODULE__, @mailglass_opts)
      |> Mailglass.Message.assign(assigns)
    end

    def render(msg, _template, _assigns), do: Mailglass.Renderer.render(msg)
    def deliver(msg, opts \\ []), do: Mailglass.Outbound.deliver(msg, opts)
    def deliver_later(msg, opts \\ []), do: Mailglass.Outbound.deliver_later(msg, opts)
  end
end
```

Read this as: **a mailable is a factory with policy defaults**. `new/1` stamps
the module, stream, current tenant, and assigns. The injected delegates prevent
each adopter module from growing its own delivery path.

The value produced by that factory is deliberately split. Swoosh owns familiar
email fields; Mailglass keeps the lifecycle context alongside them.

```elixir
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

def update_swoosh(%__MODULE__{swoosh_email: email} = msg, fun) do
  %{msg | swoosh_email: fun.(email)}
end

def to(%__MODULE__{} = msg, recipient) do
  update_swoosh(msg, &Swoosh.Email.to(&1, recipient))
end
```

That setter is the recurring pattern. Native Mailglass setters transform the
inner `%Swoosh.Email{}` without dropping tenant, stream, tags, metadata, or the
mailable identity. `update_swoosh/2` is the escape hatch for a Swoosh operation
that has no native setter.

At this point nothing has been rendered, persisted, queued, or sent. We have
only a rich in-memory description of intent.

## Rendering collapses intent into bytes

`Mailglass.Renderer.render/2` is short enough to hold in your head. Its ordering
is most of the design.

```elixir
def render(%Message{} = message, opts \\ []) do
  metadata = %{
    tenant_id: message.tenant_id || "single_tenant",
    mailable: message.mailable
  }

  Telemetry.render_span(metadata, fn ->
    with {:ok, html_iodata} <- render_html(message, opts),
         html_binary = IO.iodata_to_binary(html_iodata),
         plaintext = to_plaintext(html_binary),
         {:ok, inlined_html} <- inline_css(html_binary) do
      final_html = strip_mg_attributes(inlined_html)

      updated_email = %{
        message.swoosh_email
        | html_body: final_html,
          text_body: plaintext
      }

      {:ok, %{message | swoosh_email: updated_email}}
    end
  end)
end
```

Read the `with` from top to bottom as a compiler pipeline. Plaintext is derived
from logical HTML before CSS inlining can introduce email-client artifacts.
Temporary `data-mg-*` authoring hints are useful to the plaintext walker, then
removed from the wire HTML.

The function returns another Message, but its body has crossed a real boundary:
it now contains transportable binary HTML and text. The Renderer has no Repo,
process, or network dependency, which is why preview can call the same code
without accidentally sending anything.

## Outbound is the decision center

The root `Mailglass.deliver_later/2` function is intentionally boring: it
delegates to `Mailglass.Outbound`. The private pipeline inside that module is
where the decisions collect.

```elixir
defp do_deliver_later(%Message{} = msg, opts) do
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
end
```

The shape matters: policy is a fail-fast prefix, rendering happens only after
the message is allowed, and persistence happens only after rendering succeeds.
`prepare_outbound_message/1` then assigns the delivery ID and applies outbound
compliance and tracking changes.

With Oban, the first durable boundary is one `Ecto.Multi`.

```elixir
defp enqueue_oban(%Message{} = rendered, adapter_ref, _opts) do
  ik = compute_idempotency_key(rendered)
  tenant_id = rendered.tenant_id
  delivery_id = delivery_id!(rendered)
  attrs = base_delivery_attrs(rendered, ik, adapter_ref)

  result =
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :delivery,
      Delivery.changeset(%Delivery{id: delivery_id}, attrs),
      Repo.multi_opts()
    )
    |> Events.append_multi(:event_queued, fn %{delivery: d} ->
      %{
        tenant_id: tenant_id,
        delivery_id: d.id,
        type: :queued,
        occurred_at: Clock.utc_now(),
        idempotency_key: ik,
        normalized_payload: %{}
      }
    end)
    |> Mailglass.OptionalDeps.Oban.insert(:job, fn %{delivery: d} ->
      Mailglass.Outbound.Worker.new(%{
        "delivery_id" => d.id,
        "mailglass_tenant_id" => tenant_id
      })
    end)
    |> Repo.multi()

  case result do
    {:ok, %{delivery: d}} ->
      {:ok, %{d | status: :queued, last_event_type: :queued}}

    {:error, _step, err, _} ->
      {:error, to_error(err)}
  end
end
```

One commit creates three mutually supporting facts: the mutable Delivery
snapshot, the immutable queued Event, and the executable job. If that commit
fails, there is no background promise for the caller to believe. If it
succeeds, `deliver_later/2` returns the queued Delivery without waiting for the
email service.

Notice what is absent: the adapter call. Network transport does not occur while
the transaction owns a database connection.

## The worker receives identity, not behavior

A `%Mailglass.Message{}` can contain functions and arbitrary assigns, so it is
the wrong durable job payload. Before enqueue, Mailglass stores the rendered
artifact on the Delivery. Later it reconstructs only what transport needs.

```elixir
defp base_delivery_attrs(rendered, ik, adapter_ref) do
  %{
    tenant_id: rendered.tenant_id,
    mailable: inspect(rendered.mailable),
    stream: rendered.stream,
    recipient: primary_recipient(rendered),
    adapter_ref: adapter_ref,
    status: :queued,
    metadata:
      Map.merge(rendered.metadata || %{}, %{
        rendered_html: rendered.swoosh_email.html_body,
        rendered_text: rendered.swoosh_email.text_body,
        subject: rendered.swoosh_email.subject,
        headers: rendered.swoosh_email.headers || %{}
      }),
    idempotency_key: ik
  }
end

# ... later, on the worker side ...

defp build_rehydrated_message(delivery, mod_atom) do
  email =
    Swoosh.Email.new()
    |> Swoosh.Email.to(delivery.recipient)
    |> Swoosh.Email.subject(get_in(delivery.metadata, ["subject"]) || "")
    |> Swoosh.Email.html_body(get_in(delivery.metadata, ["rendered_html"]))
    |> Swoosh.Email.text_body(get_in(delivery.metadata, ["rendered_text"]))
    |> put_rehydrated_headers(Map.get(delivery.metadata || %{}, "headers", %{}))

  %Message{
    swoosh_email: email,
    mailable: mod_atom,
    tenant_id: delivery.tenant_id,
    stream: delivery.stream,
    metadata: rehydrated_metadata(delivery.metadata || %{})
  }
end
```

This pair is a change detector. If transport begins to depend on another email
field, both snapshot creation and rehydration must change together. Background
workers never rerun adopter template functions; they resume from compiled
bytes.

The Oban worker itself stays thin.

```elixir
def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) when is_binary(id) do
  Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
    case Mailglass.Outbound.dispatch_by_id(id) do
      {:ok, %Mailglass.Outbound.Delivery{status: :sent}} ->
        :ok

      {:ok, %Mailglass.Outbound.Delivery{status: :failed, last_error: err}} ->
        {:error, err}

      {:error, %{__exception__: true} = err} ->
        {:error, err}

      {:error, other} ->
        {:error, inspect(other)}
    end
  end)
end
```

The middleware restores tenant process context from the two boring job
arguments. Oban owns retries; the worker converts Mailglass outcomes into the
success or error shape Oban understands.

The actual continuation lives back in Outbound:

```elixir
def dispatch_by_id(delivery_id) when is_binary(delivery_id) do
  with {:ok, delivery} <- load_delivery(delivery_id),
       {:ok, rendered} <- rehydrate_message(delivery),
       prepared = Mailglass.Message.put_metadata(rendered, :delivery_id, delivery.id),
       {:ok, adapter} <- resolve_persisted_adapter(delivery.adapter_ref),
       {:ok, dispatch_result} <- call_adapter(prepared, adapter) do
    case persist_dispatched_multi(delivery, dispatch_result, rendered) do
      {:ok, %{delivery: updated}} ->
        Projector.broadcast_delivery_updated(updated, :dispatched, %{
          tenant_id: updated.tenant_id,
          delivery_id: updated.id
        })

        {:ok, updated}

      {:error, _step, err, _changes} ->
        {:error, to_error(err)}
    end
  else
    {:error, %{__exception__: true} = err} ->
      persist_failed_by_id(delivery_id, err)
      {:error, err}

    other ->
      other
  end
end
```

Read the `with` as the second half of async delivery: load identity, rebuild the
artifact, resolve the persisted route, cross the network boundary, then record
the result. The adapter call sits visibly between the enqueue transaction and
the result transaction.

## Swoosh owns the final transport hop

Every Mailglass adapter collapses transport into one result shape. The shipped
Swoosh bridge implements that contract by calling the configured Swoosh adapter
directly.

```elixir
@callback deliver(Mailglass.Message.t(), keyword()) ::
            {:ok, %{message_id: String.t(), provider_response: term()}}
            | {:error, Mailglass.Error.t()}

# Mailglass.Adapters.Swoosh
defp raw_deliver(swoosh_adapter, email) do
  {mod, config} = normalize_swoosh_adapter(swoosh_adapter)

  case mod.deliver(email, config) do
    {:ok, %{id: message_id} = response} when is_binary(message_id) ->
      {:ok, %{message_id: message_id, provider_response: response}}

    {:ok, response} when is_map(response) ->
      {:ok, %{message_id: synthetic_id(), provider_response: response}}

    {:error, {:api_error, status, body}} ->
      {:error,
       Mailglass.SendError.new(:adapter_failure,
         context: %{
           provider_status: status,
           provider_module: mod,
           body_preview: body_preview(body),
           reason_class: classify_status(status)
         }
       )}

    {:error, reason} ->
      {:error,
       Mailglass.SendError.new(:adapter_failure,
         context: %{provider_module: mod, reason_class: classify_reason(reason)}
       )}
  end
end
```

`mod.deliver/2` is the `Swoosh.Adapter` callback. Postmark, SES, SMTP, or
another Swoosh integration owns the service-specific request. The bridge does
not render or persist; it only unwraps the email and normalizes provider-facing
success and failure.

The returned message ID is the join point for future webhooks. That is the one
piece of transport output the lifecycle needs to understand.

## Events are history; Delivery is the view

Outbound dispatch and webhook ingest both append Events and feed those Events
through one Projector. Its public function reads like a list of projection
invariants.

```elixir
@terminal_event_types ~w[delivered bounced complained rejected failed suppressed]a

def update_projections(%Delivery{} = delivery, %Event{} = event) do
  Mailglass.Telemetry.persist_span(
    [:delivery, :update_projections],
    %{tenant_id: delivery.tenant_id, delivery_id: delivery.id},
    fn ->
      delivery
      |> Ecto.Changeset.change()
      |> maybe_advance_last_event(event)
      |> maybe_set_once_timestamp(event)
      |> maybe_flip_terminal(event)
      |> Ecto.Changeset.optimistic_lock(:lock_version)
    end
  )
end

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
```

The ledger does not need events to arrive in a fictional lifecycle order.
`last_event_at` advances only forward, lifecycle timestamps are set once, and
`terminal` is a one-way latch. Optimistic locking makes concurrent projection
writers lose visibly instead of overwriting a newer view.

Callers put the projection update and matching Event append in the same Multi.
After commit, they may broadcast the updated Delivery. PostgreSQL remains the
truth if PubSub is missed.

## Webhooks bring provider facts home

The webhook half begins at an adversarial boundary. In
`Mailglass.Webhook.Plug`, ordering is security policy:

```elixir
defp do_call(conn, provider, _opts) do
  {raw_body, headers} = extract_headers_and_raw_body!(conn)
  config = resolve_config!(provider, conn)

  case verify_with_telemetry!(provider, raw_body, headers, config) do
    # ... verified replay and control-plane requests return 200 without ingest ...

    :ok ->
      tenant_id = resolve_tenant!(provider, conn, raw_body, headers)

      Tenancy.with_tenant(tenant_id, fn ->
        events =
          provider
          |> provider_module()
          |> apply(:normalize, [raw_body, headers])

        ingest_and_respond(conn, provider, raw_body, events, tenant_id)
      end)
  end
end
```

Raw bytes come first because some signatures cover their exact representation.
Authenticity is established before Mailglass asks tenant code to work or writes
anything. Only verified input reaches the pure provider normalizer.

A normalizer turns a service dialect into the common Event vocabulary. A few
Postmark clauses show the character of that code:

```elixir
defp map_record_type(%{"RecordType" => "Delivery"}),
  do: {:delivered, nil}

defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 1}),
  do: {:bounced, :bounced}

defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 2}),
  do: {:deferred, nil}

defp map_record_type(%{"RecordType" => "SpamComplaint"}),
  do: {:complained, nil}

defp map_record_type(%{"RecordType" => "SubscriptionChange", "SuppressSending" => true}),
  do: {:unsubscribed, nil}

defp map_record_type(%{"RecordType" => other}) do
  Logger.warning("[mailglass] Unmapped Postmark RecordType: #{inspect(other)}")
  {:unknown, nil}
end
```

There is no provider-specific Delivery logic below this point. Unrecognized
input becomes explicit `:unknown` evidence rather than being guessed into a
more serious state.

The ingest code then composes the temporary provider receipt, normalized
history, current projection, and future-send policy into one flat transaction.

```elixir
defp build_multi(provider, raw_body, events, tenant_id) do
  provider_str = Atom.to_string(provider)
  # ... derive provider identity and build the WebhookEvent changeset ...

  duplicate_check_step
  |> Multi.insert(
    :webhook_event,
    WebhookEvent.changeset(webhook_event_attrs),
    Repo.multi_opts(
      on_conflict: :nothing,
      conflict_target: [:provider, :provider_event_id],
      returning: true
    )
  )
  |> append_events_for_each(events, provider, tenant_id)
  |> update_projections_for_each(events)
  |> Multi.update_all(
    :flip_status,
    &flip_status_query(&1, provider_str),
    [set: [status: :succeeded, processed_at: Clock.utc_now()]],
    Repo.multi_opts()
  )
end

# ... inside update_projections_for_each/2, after matching an Event ...

acc =
  Multi.run(acc, {:projector_apply, idx}, fn repo, changes ->
    case Map.get(changes, {:projector_categorize, idx}) do
      {:matched, delivery, inserted_event} ->
        case repo.update(
               Projector.update_projections(delivery, inserted_event),
               Repo.multi_opts()
             ) do
          {:ok, _projected} -> {:ok, {:matched, delivery, inserted_event}}
          {:error, reason} -> {:error, reason}
        end

      other ->
        {:ok, other}
    end
  end)

Multi.run(acc, {:auto_suppress, idx}, fn repo, changes ->
  apply(@auto_suppress_module, :apply, [repo, Map.get(changes, {:projector_apply, idx})])
end)
```

“Flat” is important here. Projection and suppression use the outer Multi's Repo
handle; they do not open nested transactions that could survive an outer
rollback. Complaints, unsubscribes, and hard bounces can therefore become
suppression policy in the same commit as the evidence that justified them.

After the transaction returns, the Plug emits telemetry and broadcasts matched
Delivery changes. Those observers never see work that can still roll back.

## Context rides every asynchronous and database boundary

Two tiny helpers explain a surprising amount of the codebase. They live in
different modules, but they solve the same problem: context that Elixir or Ecto
will not propagate for you.

```elixir
# Mailglass.Tenancy
def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do
  prior = Process.get(@process_dict_key)
  put_current(tenant_id)

  try do
    fun.()
  after
    if is_nil(prior), do: Process.delete(@process_dict_key), else: put_current(prior)
  end
end

# Mailglass.Repo
def multi_opts(opts \\ []) do
  Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
end
```

Tenant identity is process-local, so Tasks, Oban workers, and webhook handlers
must stamp it in the process that executes the query. Schema prefix is
statement-local inside `Ecto.Multi`, so each Mailglass table step carries
`multi_opts/1`; transaction executor options alone are not enough.

When a bug appears only in async work or only with the version-2 schema prefix,
look for one of these two missing handoffs first.

## Tests expose the intended design

Good tests are often a faster architecture reference than another private
helper. Two short examples reveal behavior that is easy to misread from the
happy path.

First, the returned Delivery is a snapshot, not a live handle. Even when Oban
runs the job inline before the call returns, the API still reports what the
enqueue boundary promised:

```elixir
@tag oban: :inline
test "oban :inline path — job runs synchronously, return shape is {:ok, %Delivery{status: :queued}}" do
  msg = "uat-c2-oban@example.com" |> TestMailer.welcome()
  assert {:ok, %Delivery{status: :queued}} = Outbound.deliver_later(msg)
  assert_mail_sent(to: "uat-c2-oban@example.com")
end
```

The email can already be in the Fake adapter while the returned struct still
says queued. A later query sees the projected state; an old Elixir value does
not mutate behind the caller's back.

Second, provider time is not request-arrival order. The Projector must accept
late evidence without undoing terminal state:

```elixir
test "terminal never flips back: :opened after :bounced leaves terminal=true" do
  {:ok, delivery} = insert_delivery()

  {:ok, bounced} =
    delivery |> Projector.update_projections(build_event(:bounced)) |> TestRepo.update()

  late_opened = build_event(:opened, DateTime.add(bounced.bounced_at, 30, :second))

  {:ok, after_opened} =
    bounced |> Projector.update_projections(late_opened) |> TestRepo.update()

  assert after_opened.terminal == true
  assert after_opened.bounced_at == bounced.bounced_at
  assert after_opened.last_event_type == :opened
end
```

The latest observed fact and the terminal outcome answer different questions.
That distinction is encoded in both the Projector pipeline and its tests.

## Your next source-reading session

You now have enough landmarks to follow changes by value and invariant:

| If you are changing… | Start here, then follow… |
|---|---|
| Rendering or plaintext | `Mailglass.Renderer` → `Mailglass.Components` → `Mailglass.RendererTest` |
| Async snapshot contents | `Mailglass.Outbound` snapshot creation → rehydration → `Mailglass.Outbound.WorkerTest` |
| A webhook event mapping | The provider normalizer → `Mailglass.Webhook.Ingest` → Projector → provider and ingest tests |
| Tenant or schema behavior | `Mailglass.Tenancy` → `Mailglass.Repo` → schema-prefix contract tests |

Search by module or function name rather than walking directories
alphabetically. At each boundary, ask four questions:

1. What value entered?
2. What durable fact was written?
3. What external work happened outside the transaction?
4. What context must be restored on the other side?

This tour deliberately skipped batch delivery, installer and migration
machinery, deliverability diagnostics, and most operational read models. Use
the [module atlas](architecture.md#module-atlas) to place those areas, then the
focused guide for the work itself. The admin and inbound packages have their
own lifecycles; the architecture guide's
[sibling-package map](architecture.md#how-the-sibling-packages-fit) marks the
handoffs without pretending they are part of this core trace.
