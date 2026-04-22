defmodule Mailglass.Telemetry do
  @moduledoc """
  Telemetry integration for mailglass.

  ## Event Naming Convention

  All mailglass events follow the 4-level path plus a phase suffix:

      [:mailglass, :domain, :resource, :action, :start | :stop | :exception]

  Named span helpers wrap `:telemetry.span/3` for each domain. Domain helpers
  land in their owning phase (render in Phase 1, send/batch in Phase 3,
  persist/events in Phase 2, webhook_verify/webhook_ingest in Phase 4,
  preview_render in Phase 5).

  ## Phase 1 Events

  ### Render pipeline

    * `[:mailglass, :render, :message, :start | :stop | :exception]`
      — Measurements on `:start`: `%{system_time: integer}`
      — Measurements on `:stop`: `%{duration: native_time}`
      — Metadata: `%{tenant_id: string, mailable: atom}`

  ## Metadata Policy (D-31)

  **Whitelisted keys:** `:tenant_id, :mailable, :provider, :status,
  :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count,
  :bytes, :retry_count`.

  **Forbidden (PII):** `:to, :from, :body, :html_body, :subject, :headers,
  :recipient, :email`.

  Enforcement is lint-time (Phase 6 custom Credo check `NoPiiInTelemetryMeta`)
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
    # Phase 2: events-append + persist spans.
    [:mailglass, :events, :append, :stop],
    [:mailglass, :events, :append, :exception],
    [:mailglass, :persist, :delivery, :update_projections, :stop],
    [:mailglass, :persist, :delivery, :update_projections, :exception],
    [:mailglass, :persist, :reconcile, :link, :stop],
    [:mailglass, :persist, :reconcile, :link, :exception]
    # Expanded per phase as new spans land (send, webhook_ingest, ...).
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
  Named span helper for the render pipeline. Phase 1 surface.

  Equivalent to `span([:mailglass, :render, :message], metadata, fun)`.
  """
  @doc since: "0.1.0"
  @spec render_span(map(), (-> result)) :: result when result: term()
  def render_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :render, :message], metadata, fun)
  end

  @doc """
  Named span helper for the events-append write path. Phase 2 surface.

  Equivalent to `span([:mailglass, :events, :append], metadata, fun)`.
  `:stop` metadata SHOULD include `inserted?: boolean` and
  `idempotency_key_present?: boolean` per D-04.
  """
  @doc since: "0.1.0"
  @spec events_append_span(map(), (-> result)) :: result when result: term()
  def events_append_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass, :events, :append], metadata, fun)
  end

  @doc """
  Named span helper for persist-layer write paths (projector, reconciler).
  Phase 2 surface.

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
  One-shot wrapper around `:telemetry.execute/3` for non-span counter events.

  Callers are expected to prepend `:mailglass` to the event path.
  """
  @doc since: "0.1.0"
  @spec execute([atom()], map(), map()) :: :ok
  def execute(event_name, measurements \\ %{}, metadata \\ %{})
      when is_list(event_name) and is_map(measurements) and is_map(metadata) do
    :telemetry.execute(event_name, measurements, metadata)
  end

  @doc """
  Attaches the default logger handler for the Phase 1 event set.

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
