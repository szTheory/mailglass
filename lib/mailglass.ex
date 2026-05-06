defmodule Mailglass do
  @compile {:no_warn_undefined, [Mailglass.Oban.TenancyMiddleware, Mailglass.Outbound.Worker]}

  @moduledoc since: "0.1.0"
  @moduledoc """
  Transactional email framework for Phoenix.

  Composes on top of Swoosh, shipping the framework layer Swoosh omits:
  HEEx-native components, LiveView preview dashboard, normalized webhook events,
  suppression lists, RFC 8058 List-Unsubscribe, multi-tenant routing, and an
  append-only event ledger.

  ## Getting Started

      config :mailglass,
        repo: MyApp.Repo,
        adapter:
          {Mailglass.Adapters.Swoosh,
           swoosh_adapter:
             {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_API_KEY")}}

  ## Stability Contract

  The canonical `v1.x` contract inventory for the core package lives in
  `docs/api_stability.md`.

  Treat this module as a narrow root entrypoint:

  - `Mailglass.deliver/2`, `deliver!/2`, `deliver_later/2`,
    `deliver_many/2`, and `deliver_many!/2` are stable adopter-facing
    delegates.
  - Root reachability or `Boundary` exports do not mean every exported
    `Mailglass.*` module is promised public API.
  - Exported helpers used for framework wiring, internal implementation, or
    sibling-package integration remain classified in the stability inventory as
    `stable`, `internal`, or `sibling-package-only`.

  ## Architecture

  See `Mailglass.Config`, `Mailglass.Renderer`, `Mailglass.Components`, and
  `docs/api_stability.md`.
  """

  # Root boundary. Phase 1 keeps the graph flat: a single root that contains
  # most modules under `Mailglass.*`. Internal boundaries land as their owning
  # plans introduce them. Plan 01-06 introduces the first sub-boundary
  # (`Mailglass.Renderer`) to enforce the CORE-07 renderer-purity rule, so the
  # root now exports the modules Renderer may legitimately call into. Future
  # sub-boundaries (Outbound, Events, Webhook, Admin) will follow the same
  # pattern: declare the sub-boundary with an explicit `deps:` list and
  # export the surface it consumes from here.
  # Oban-dependent modules are conditionally compiled — only include them
  # in Boundary exports when Oban is loaded. Keeps `mix compile
  # --no-optional-deps --warnings-as-errors` clean.
  @oban_exports if Code.ensure_loaded?(Oban.Worker),
                  do: [Oban.TenancyMiddleware, Outbound.Worker],
                  else: []

  use Boundary,
    deps: [],
    exports:
      [
        Message,
        Telemetry,
        Config,
        Clock,
        Repo,
        Tenancy,
        TenancyError,
        Stream,
        RateLimiter,
        Suppression,
        Tracking,
        Tracking.Guard,
        IdempotencyKey,
        Schema,
        TemplateEngine,
        TemplateEngine.HEEx,
        TemplateError,
        SendError,
        SignatureError,
        ConfigError,
        Error.BatchFailed,
        OptionalDeps.Oban,
        Events,
        Events.Event,
        Events.Reconciler,
        Webhook,
        Webhook.CachingBodyReader,
        Webhook.Plug,
        Webhook.Router,
        Webhook.Replay,
        Outbound,
        Outbound.Delivery,
        Outbound.Projector,
        Operator.Deliveries,
        Operator.ReplayHistory,
        Operator.ReplayTargets,
        Operator.Timeline,
        Operator.Suppressions,
        Adapter,
        Adapters.Fake,
        Adapters.Swoosh,
        PubSub,
        PubSub.Topics,
        Mailable,
        Compliance,
        Compliance.Unsubscribe,
        Tracking,
        Clock,
        # Renderer exposed so MailglassAdmin.PreviewLive can call the
        # production render pipeline directly (PREV-03 "no placeholder
        # shape divergence"). The sub-boundary still blocks the reverse
        # direction — Renderer cannot depend on admin code.
        Renderer
      ] ++ @oban_exports

  @doc "Synchronous delivery. See `Mailglass.Outbound.deliver/2`."
  @doc since: "0.1.0"
  defdelegate deliver(msg, opts \\ []), to: Mailglass.Outbound

  @doc "Asynchronous delivery. See `Mailglass.Outbound.deliver_later/2`."
  @doc since: "0.1.0"
  defdelegate deliver_later(msg, opts \\ []), to: Mailglass.Outbound

  @doc "Batch async delivery. See `Mailglass.Outbound.deliver_many/2`."
  @doc since: "0.1.0"
  defdelegate deliver_many(msgs, opts \\ []), to: Mailglass.Outbound

  @doc "Bang variant. See `Mailglass.Outbound.deliver!/2`."
  @doc since: "0.1.0"
  defdelegate deliver!(msg, opts \\ []), to: Mailglass.Outbound

  @doc "Bang batch variant. See `Mailglass.Outbound.deliver_many!/2`."
  @doc since: "0.1.0"
  defdelegate deliver_many!(msgs, opts \\ []), to: Mailglass.Outbound
end
