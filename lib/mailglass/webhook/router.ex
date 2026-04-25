defmodule Mailglass.Webhook.Router do
  @moduledoc """
  Router macro for mounting Mailglass webhook endpoints in an adopter
  Phoenix router.

  Mirrors the `Phoenix.LiveDashboard.Router` + `Oban.Web.Router` idiom:
  the macro is invoked inside an adopter-owned `scope` block with
  adopter-owned `pipe_through` (CONTEXT D-06). Mailglass does NOT
  provide its own router — adopters keep full control over the
  surrounding pipeline (CORS, IP allowlist, rate-limit, endpoint
  selection).

  ## Usage

      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import Mailglass.Webhook.Router

        pipeline :mailglass_webhooks do
          plug :accepts, ["json"]
          # NO :browser, :fetch_session, :protect_from_forgery — webhooks
          # do not carry a session or participate in CSRF.
        end

        scope "/", MyAppWeb do
          pipe_through :mailglass_webhooks
          mailglass_webhook_routes "/webhooks"
        end
      end

  Generates two `post` routes by default (CONTEXT D-07 — provider-per-path
  discipline):

    * `POST /webhooks/postmark` → `Mailglass.Webhook.Plug` with `[provider: :postmark]`
    * `POST /webhooks/sendgrid` → `Mailglass.Webhook.Plug` with `[provider: :sendgrid]`

  ## Options

    * `:providers` — list of provider atoms. v0.1 validated set:
      `[:postmark, :sendgrid]` (default both). Unknown providers raise
      `ArgumentError` at compile time — invalid config fails at
      router-mount, not at request time (D-07).
    * `:as` — route helper prefix. Default `:mailglass_webhook` per
      CONTEXT D-08 (shared vocabulary lock with the Phase 5 admin
      mount). Each generated route's helper is `:"\#{as}_\#{provider}"`.

  The provider list is locked at v0.1 per PROJECT D-10 — Mailgun/SES/Resend
  land at v0.5. Additions to `@valid_providers` are minor-version API
  extensions (additive); they do not break adopters already passing the
  default.

  ## Endpoint wiring (separate from this macro)

  The macro only generates routes. Adopters MUST also configure
  `Plug.Parsers` in their endpoint with Mailglass's
  `Mailglass.Webhook.CachingBodyReader`:

      plug Plug.Parsers,
        parsers: [:json],
        pass: ["*/*"],
        json_decoder: Jason,
        body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []},
        length: 10_000_000   # 10 MB cap; SendGrid batches up to 128 events
                             # fit comfortably under 8 MB with 2 MB headroom

  Without the `CachingBodyReader` wiring, `Mailglass.Webhook.Plug`
  raises `%Mailglass.ConfigError{type: :webhook_caching_body_reader_missing}`
  at request time — the 500 is the diagnostic.
  """

  @valid_providers [:postmark, :sendgrid]
  @default_providers @valid_providers
  @default_as :mailglass_webhook

  @doc """
  Generate provider-per-path POST routes for `Mailglass.Webhook.Plug`.

  Must be invoked inside a `Phoenix.Router` `scope` block. See the module
  doc for full usage and endpoint-wiring requirements.

  ## Options

    * `:providers` — defaults to `#{inspect(@default_providers)}`
    * `:as` — defaults to `#{inspect(@default_as)}`

  Raises `ArgumentError` at compile time if `:providers` contains an
  unknown provider atom — fails at router-mount time, not request time.
  """
  defmacro mailglass_webhook_routes(path, opts \\ []) do
    providers = Keyword.get(opts, :providers, @default_providers)
    as = Keyword.get(opts, :as, @default_as)

    # Validate at compile time — invalid providers should fail adopter
    # endpoint.ex boot, not produce request-time 500s on live traffic.
    Enum.each(providers, fn p ->
      unless p in @valid_providers do
        raise ArgumentError,
              "Mailglass.Webhook.Router: unknown provider #{inspect(p)} " <>
                "(valid at v0.1: #{inspect(@valid_providers)}; " <>
                "Mailgun/SES/Resend land in v0.5 per PROJECT D-10)"
      end
    end)

    quote bind_quoted: [path: path, providers: providers, as: as] do
      for provider <- providers do
        post(
          "#{path}/#{provider}",
          Mailglass.Webhook.Plug,
          [provider: provider],
          as: :"#{as}_#{provider}"
        )
      end
    end
  end
end
