defmodule Mailglass do
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

  ## Architecture

  See `Mailglass.Config`, `Mailglass.Renderer`, `Mailglass.Components`.
  """

  # Root boundary. Phase 1 keeps the graph flat: a single root that contains
  # most modules under `Mailglass.*`. Internal boundaries land as their owning
  # plans introduce them. Plan 01-06 introduces the first sub-boundary
  # (`Mailglass.Renderer`) to enforce the CORE-07 renderer-purity rule, so the
  # root now exports the modules Renderer may legitimately call into. Future
  # sub-boundaries (Outbound, Events, Webhook, Admin) will follow the same
  # pattern: declare the sub-boundary with an explicit `deps:` list and
  # export the surface it consumes from here.
  use Boundary,
    deps: [],
    exports: [
      Message,
      Telemetry,
      Config,
      TemplateEngine,
      TemplateEngine.HEEx,
      TemplateError,
      Outbound,
      Outbound.Delivery,
      Adapter,
      Adapters.Fake,
      Adapters.Swoosh,
      PubSub,
      PubSub.Topics,
      Mailable,
      Tracking,
      Clock
    ]

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
