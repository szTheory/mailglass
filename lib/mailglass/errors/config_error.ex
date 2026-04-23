defmodule Mailglass.ConfigError do
  @moduledoc """
  Raised when mailglass is misconfigured.

  Configuration errors are never retryable — the host application must
  fix the configuration and restart. `Mailglass.Config.validate_at_boot!/0`
  (lands in Plan 03) raises this at application startup.

  ## Types

  - `:missing` — a required configuration key is not set
  - `:invalid` — a key is present but the value is invalid
  - `:conflicting` — two or more keys contradict each other
  - `:optional_dep_missing` — an optional dependency is required for the
    selected configuration but is not loaded
  - `:tracking_on_auth_stream` — open/click tracking is enabled on a mailable
    whose function name matches an auth-stream heuristic (D-38). Forbidden.
  - `:tracking_host_missing` — a mailable enables opens or clicks but no
    tracking host is configured (D-32). Required for link rewriting.
  - `:tracking_endpoint_missing` — tracking is enabled but no Phoenix.Token
    endpoint is configured. Set `config :mailglass, :tracking, endpoint:` or
    `config :mailglass, :adapter_endpoint` to enable open/click tracking.
  - `:webhook_verification_key_missing` — a webhook provider is configured
    but its verification credentials are not set (Postmark `basic_auth`,
    SendGrid `public_key`). Phase 4 D-21.
  - `:webhook_caching_body_reader_missing` — the webhook plug received a
    request with `conn.private[:raw_body]` unset, meaning the adopter has
    not wired `Mailglass.Webhook.CachingBodyReader` into their
    `Plug.Parsers` `:body_reader`. Phase 4 D-21 / revision B4.

  See `Mailglass.Error` for the shared contract and `docs/api_stability.md`
  for the locked `:type` atom set.
  """

  @behaviour Mailglass.Error

  @types [
    :missing,
    :invalid,
    :conflicting,
    :optional_dep_missing,
    :tracking_on_auth_stream,
    :tracking_host_missing,
    :tracking_endpoint_missing,
    # Phase 4 D-21: webhook config surface.
    :webhook_verification_key_missing,
    :webhook_caching_body_reader_missing
  ]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type:
            :missing
            | :invalid
            | :conflicting
            | :optional_dep_missing
            | :tracking_on_auth_stream
            | :tracking_host_missing
            | :tracking_endpoint_missing
            | :webhook_verification_key_missing
            | :webhook_caching_body_reader_missing,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()}
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.1.0"
  @spec __types__() :: [atom()]
  def __types__, do: @types

  @impl Mailglass.Error
  def type(%__MODULE__{type: t}), do: t

  @impl Mailglass.Error
  def retryable?(%__MODULE__{}), do: false

  @impl true
  def message(%__MODULE__{type: type, context: ctx}) do
    format_message(type, ctx || %{})
  end

  @doc """
  Build a `Mailglass.ConfigError` struct.

  ## Options

  - `:cause` — an underlying exception to wrap (kept out of JSON output).
  - `:context` — a map of non-PII metadata; `:key` is used for `:missing` /
    `:invalid` messages, `:dep` for `:optional_dep_missing`.
  """
  @doc since: "0.1.0"
  @spec new(atom(), keyword()) :: t()
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx
    }
  end

  defp format_message(:missing, ctx) do
    key = ctx[:key] || "unknown"
    "Configuration error: required key :#{key} is not set"
  end

  defp format_message(:invalid, ctx) do
    key = ctx[:key] || "unknown"
    "Configuration error: invalid value for :#{key}"
  end

  defp format_message(:conflicting, _ctx), do: "Configuration error: conflicting options"

  defp format_message(:optional_dep_missing, ctx) do
    dep = ctx[:dep] || "unknown"
    "Configuration error: optional dependency #{dep} is not loaded"
  end

  defp format_message(:tracking_on_auth_stream, ctx) do
    mod = ctx[:mailable] || "(unknown mailable)"
    fun = ctx[:function] || "(unknown function)"

    "Tracking misconfigured: tracking enabled on auth-stream mailable " <>
      "#{inspect(mod)}.#{fun} — forbidden. Remove `tracking:` opts from " <>
      "mailables whose function name matches magic_link/password_reset/verify_email/confirm_account."
  end

  defp format_message(:tracking_host_missing, _ctx) do
    "Tracking misconfigured: tracking host is required when any mailable " <>
      "enables opens or clicks. Set `config :mailglass, :tracking, host: \"track.example.com\"`."
  end

  defp format_message(:tracking_endpoint_missing, _ctx) do
    "Tracking endpoint not configured. " <>
      "Set `config :mailglass, :tracking, endpoint: MyApp.Endpoint` or " <>
      "`config :mailglass, :adapter_endpoint, MyApp.Endpoint` to enable open/click tracking."
  end

  defp format_message(:webhook_verification_key_missing, ctx) do
    hint = ctx[:hint] || "configure the per-tenant webhook verification key"
    "Mailglass webhook verification key missing: #{hint}"
  end

  defp format_message(:webhook_caching_body_reader_missing, ctx) do
    hint =
      ctx[:hint] ||
        "ensure Plug.Parsers is configured with body_reader: " <>
          "{Mailglass.Webhook.CachingBodyReader, :read_body, []} in your endpoint.ex"

    "Webhook ingest blocked: raw_body is missing from conn.private — #{hint}"
  end
end
