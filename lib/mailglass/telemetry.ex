defmodule Mailglass.Telemetry do
  @moduledoc """
  Telemetry integration for mailglass.

  ## Event Naming Convention

  All mailglass events follow the 4-level path plus a phase suffix:

      [:mailglass, :domain, :resource, :action, :start | :stop | :exception]

  Named span helpers wrap `:telemetry.span/3` for each domain. Domain helpers
  land in their owning phase (render in , send/batch in ,
  persist/events in , webhook_verify/webhook_ingest in ,
  preview_render in ).

  ##  Events

  ### Render pipeline

    * `[:mailglass, :render, :message, :start | :stop | :exception]`
      — Measurements on `:start`: `%{system_time: integer}`
      — Measurements on `:stop`: `%{duration: native_time}`
      — Metadata: `%{tenant_id: string, mailable: atom}`

  ## Metadata Policy ()

  **Whitelisted keys:** `:tenant_id, :mailable, :provider, :status,
  :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count,
  :bytes, :retry_count`.

  **Forbidden (PII):** `:to, :from, :body, :html_body, :subject, :headers,
  :recipient, :email`.
  Telemetry metadata must never include recipient or message-content PII.

  Enforcement is lint-time ( custom Credo check `NoPiiInTelemetryMeta`)
  plus a runtime StreamData property test that asserts every emitted stop
  event's metadata keys are a subset of the whitelist across 1000 varied
  inputs.

  ## Handler Isolation

  `:telemetry.span/3` wraps each attached handler in a try/catch. A handler
  that raises is detached automatically and `[:telemetry, :handler, :failure]`
  is emitted — the caller's pipeline is unaffected. Mailglass does **not**
  add a parallel try/rescue wrapper (would duplicate or — worse — swallow
  the meta-event operators rely on).

  ## Default Logger

  Call `attach_default_logger/1` at boot (or configure
  `[telemetry: [default_logger: true]]` in the Application env) to log every
  Mailglass event:

      Mailglass.Telemetry.attach_default_logger()
      Mailglass.Telemetry.attach_default_logger(level: :warning)
  """

  require Logger

  @handler_name "mailglass-default-logger"

  @logged_events [
    [:mailglass, :render, :message, :stop],
    [:mailglass, :render, :message, :exception],
    # : events-append + persist spans.
    [:mailglass, :events, :append, :stop],
    [:mailglass, :events, :append, :exception],
    [:mailglass, :persist, :delivery, :update_projections, :stop],
    [:mailglass, :persist, :delivery, :update_projections, :exception],
    [:mailglass, :persist, :reconcile, :link, :stop],
    [:mailglass, :persist, :reconcile, :link, :exception],
    # : outbound hot path.
    [:mailglass, :outbound, :send, :stop],
    [:mailglass, :outbound, :send, :exception],
    [:mailglass, :outbound, :dispatch, :stop],
    [:mailglass, :outbound, :dispatch, :exception],
    [:mailglass, :outbound, :suppression, :stop],
    [:mailglass, :outbound, :rate_limit, :stop],
    [:mailglass, :outbound, :stream_policy, :stop],
    [:mailglass, :persist, :outbound, :multi, :stop],
    [:mailglass, :persist, :outbound, :multi, :exception]
  ]

  @doc """
  Wraps a zero-arity function in `:telemetry.span/3`, emitting `:start`,
  `:stop`, and (on exception) `:exception` events under `event_prefix`.

  The same metadata map is emitted on every phase. The function's return
  value is returned unchanged.

  ## Examples

      Mailglass.Telemetry.span([:mailglass, :render, :message],
        %{tenant_id: "acme", mailable: MyMailer},
        fn -> render(message) end)
  """
  @doc since: "0.1.0"
  @spec span([atom()], map(), (-> result)) :: result when result: term()
  def span(event_prefix, metadata, fun)
      when is_list(event_prefix) and is_map(metadata) and is_function(fun, 0) do
    :telemetry.span(event_prefix, metadata, fn ->
      result = fun.()
      {result, metadata}
    end)
  end

  @doc """
  Named span helper for the render pipeline.  surface.

  Equivalent to `span([:mailglass, :render, :message], metadata, fun)`.
  """
  @doc since: "0.1.0"
  @spec render_span(map(), (-> result)) :: result when result: term()
  def render_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :render, :message], metadata, fun)
  end

  @doc """
  Named span helper for the events-append write path.  surface.

  Equivalent to `span([:mailglass, :events, :append], metadata, fun)`.
  `:stop` metadata SHOULD include `inserted?: boolean` and
  `idempotency_key_present?: boolean` per .
  """
  @doc since: "0.1.0"
  @spec events_append_span(map(), (-> result)) :: result when result: term()
  def events_append_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :events, :append], metadata, fun)
  end

  @doc """
  Named span helper for persist-layer write paths (projector, reconciler).
   surface.

  Event path: `[:mailglass, :persist | suffix]`. Examples:

      Mailglass.Telemetry.persist_span([:delivery, :update_projections], meta, fn -> ... end)
      Mailglass.Telemetry.persist_span([:reconcile, :link], meta, fn -> ... end)
  """
  @doc since: "0.1.0"
  @spec persist_span([atom()], map(), (-> result)) :: result when result: term()
  def persist_span(suffix, metadata, fun)
      when is_list(suffix) and is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :persist] ++ suffix, metadata, fun)
  end

  @doc """
  Named span helper for the Outbound hot path (, ).

  Emits `[:mailglass, :outbound, :send, :start | :stop | :exception]`.
  Metadata whitelist per : `:tenant_id, :mailable, :stream, :delivery_id, :status, :latency_ms`.
  """
  @doc since: "0.1.0"
  @spec send_span(map(), (-> any())) :: any()
  def send_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :outbound, :send], metadata, fun)
  end

  @doc """
  Named span helper wrapping the adapter.deliver/2 call (, ).

  Emits `[:mailglass, :outbound, :dispatch, :start | :stop | :exception]`.
  Provider latency is the fat tail — this span captures it.
  """
  @doc since: "0.1.0"
  @spec dispatch_span(map(), (-> any())) :: any()
  def dispatch_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :outbound, :dispatch], metadata, fun)
  end

  @doc """
  Named span helper wrapping each Multi commit in the send pipeline (, ).

  Emits `[:mailglass, :persist, :outbound, :multi, :start | :stop | :exception]`.
  Metadata carries `:step_name` (`:persist_queued | :persist_dispatched | :persist_failed`).
  """
  @doc since: "0.1.0"
  @spec persist_outbound_multi_span(map(), (-> any())) :: any()
  def persist_outbound_multi_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :persist, :outbound, :multi], metadata, fun)
  end

  @doc """
  One-shot wrapper around `:telemetry.execute/3` for non-span counter events.

  Callers are expected to prepend `:mailglass` to the event path.
  """
  @doc since: "0.1.0"
  @spec execute([atom(), ...], map(), map()) :: :ok
  def execute(event_name, measurements \\ %{}, metadata \\ %{})
      when is_list(event_name) and is_map(measurements) and is_map(metadata) do
    :telemetry.execute(event_name, measurements, metadata)
  end

  @doc """
  Attaches the default logger handler for the  event set.

  Returns `:ok` on first attach and `{:error, :already_exists}` if a handler
  with the same ID is already attached (useful for idempotent boot paths).

  ## Options

    * `:level` — log level passed to `Logger.log/2`. Default: `:info`.
  """
  @doc since: "0.1.0"
  @spec attach_default_logger(keyword()) :: :ok | {:error, :already_exists}
  def attach_default_logger(opts \\ []) do
    :telemetry.attach_many(
      @handler_name,
      @logged_events,
      &__MODULE__.handle_event/4,
      opts
    )
  end

  @doc false
  def handle_event(event, measurements, metadata, opts) do
    level = Keyword.get(opts, :level, :info)
    Logger.log(level, fn -> format_event(event, measurements, metadata) end)
  end

  defp format_event(event, measurements, metadata) do
    [_mailglass | rest] = event
    label = rest |> Enum.map_join(".", &Atom.to_string/1)
    "[Mailglass] #{label} #{inspect(measurements)} #{inspect(metadata)}"
  end
end
