defmodule Mailglass.WebhookCase do
  @moduledoc """
  Test case template for webhook ingest tests (TEST-02, TEST-03).

  Extends `Mailglass.MailerCase` with the webhook-specific helpers listed
  in `04-CONTEXT.md` D-26:

    * `Plug.Test` + `Plug.Conn` imports for request construction
    * `Mailglass.WebhookFixtures` — ECDSA P-256 keypair mint + SendGrid
      signing + Postmark Basic Auth header builder + fixture loader
    * `mailglass_webhook_conn/3` — builds a `%Plug.Conn{}` with the right
      signature header attached (Basic Auth for Postmark, ECDSA for
      SendGrid) and `conn.private[:raw_body]` populated to mirror what
      `Mailglass.Webhook.CachingBodyReader` (Plan 02) writes in production
    * `assert_webhook_ingested/1,2` — wait on the Projector post-commit
      PubSub broadcast (matches the Phase 3 `{:delivery_updated, id, type,
      meta}` tuple shape; Plan 06 extends `meta` with provider/event_count)
    * `stub_postmark_fixture/1` + `stub_sendgrid_fixture/1` — load a
      fixture JSON from disk as raw bytes (pass-through to
      `Mailglass.WebhookFixtures.load_*_fixture/1`)
    * `freeze_timestamp/1` — re-export of `Mailglass.Clock.Frozen.freeze/1`
      for SendGrid timestamp-skew tests (TEST-03 property gen)

  ## Async safety

  This case SHOULD be used with `async: false` by default. The `setup`
  block installs per-test SendGrid + Postmark config via
  `Application.put_env/3` — concurrent async tests with different keypairs
  would clobber each other's `:mailglass, :sendgrid, public_key:` entry.

  Tests that do not mutate the global provider config (e.g. those that
  only exercise `Mailglass.Webhook.CachingBodyReader`) can opt into
  `async: true` and skip the env snapshot — set `@tag webhook_config: false`.

  ## Usage (Phase 4+)

      defmodule MyApp.PostmarkWebhookTest do
        use Mailglass.WebhookCase, async: false

        test "delivered event updates delivery status", %{sendgrid_keypair: _} do
          raw = stub_postmark_fixture("delivered")
          conn = mailglass_webhook_conn(:postmark, raw)
          # Plan 02+ dispatches conn through Mailglass.Webhook.Plug here
          # assert_webhook_ingested(%{type: :delivered})
        end
      end
  """
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Mailglass.MailerCase, unquote(opts)

      import Plug.Test
      import Plug.Conn
      import Mailglass.WebhookFixtures

      import Mailglass.WebhookCase,
        only: [
          mailglass_webhook_conn: 2,
          mailglass_webhook_conn: 3,
          stub_postmark_fixture: 1,
          stub_sendgrid_fixture: 1,
          freeze_timestamp: 1
        ]

      # `assert_webhook_ingested/1,2` is a macro (must be imported separately).
      import Mailglass.WebhookCase, only: [assert_webhook_ingested: 1, assert_webhook_ingested: 2]
    end
  end

  setup tags do
    # Mint a fresh P-256 keypair per test. Tests pass the private half to
    # `mailglass_webhook_conn(:sendgrid, body, keypair: keypair)` so the
    # signature header matches whatever SendGrid config is installed.
    {pub_b64, priv_key} = Mailglass.WebhookFixtures.generate_sendgrid_keypair()

    # Install global provider config unless the test opts out. Most Phase 4
    # tests DO want this — the plug reads `Application.get_env/2` to resolve
    # the public key. Tests that exercise pure CachingBodyReader or header
    # parsing can set `@tag webhook_config: false` to skip the mutation.
    install_config? = Map.get(tags, :webhook_config, true)

    prior_sendgrid = Application.get_env(:mailglass, :sendgrid)
    prior_postmark = Application.get_env(:mailglass, :postmark)

    if install_config? do
      Application.put_env(:mailglass, :sendgrid,
        enabled: true,
        public_key: pub_b64,
        timestamp_tolerance_seconds: 300
      )

      Application.put_env(:mailglass, :postmark,
        enabled: true,
        basic_auth: {"test_user", "test_pass"},
        ip_allowlist: []
      )
    end

    on_exit(fn ->
      restore_env(:sendgrid, prior_sendgrid)
      restore_env(:postmark, prior_postmark)
    end)

    {:ok, sendgrid_keypair: {pub_b64, priv_key}}
  end

  defp restore_env(key, nil), do: Application.delete_env(:mailglass, key)
  defp restore_env(key, prior), do: Application.put_env(:mailglass, key, prior)

  @doc """
  Builds a `%Plug.Conn{}` targeting `/webhooks/\#{provider}` with `raw_body`
  as the request body and the appropriate signature header attached.

  The conn mirrors what a production request looks like AFTER
  `Mailglass.Webhook.CachingBodyReader` has run: `conn.private[:raw_body]`
  is set to the exact bytes used for signature verification, and the
  `content-type` is `application/json`.

  ## Provider options

    * `:postmark` — attaches a Basic Auth header derived from the
      `:postmark` `basic_auth` Application env tuple (installed by the
      `setup` block unless `@tag webhook_config: false`).
    * `:sendgrid` — signs `timestamp <> raw_body` with the private key
      passed via `opts[:keypair]` (defaults to the `sendgrid_keypair`
      stashed in the test context). Attaches
      `x-twilio-email-event-webhook-signature` and
      `x-twilio-email-event-webhook-timestamp` headers. Timestamp is
      `opts[:timestamp]` (string) or `System.system_time(:second)` as a
      string.
  """
  @spec mailglass_webhook_conn(:postmark | :sendgrid, binary(), keyword()) :: Plug.Conn.t()
  def mailglass_webhook_conn(provider, raw_body, opts \\ [])

  def mailglass_webhook_conn(:postmark, raw_body, _opts) when is_binary(raw_body) do
    {user, pass} =
      case Application.fetch_env(:mailglass, :postmark) do
        {:ok, cfg} -> Keyword.fetch!(cfg, :basic_auth)
        :error -> {"test_user", "test_pass"}
      end

    {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(user, pass)

    base_conn(:postmark, raw_body)
    |> Plug.Conn.put_req_header(h, v)
  end

  def mailglass_webhook_conn(:sendgrid, raw_body, opts) when is_binary(raw_body) do
    {_pub_b64, priv_key} =
      Keyword.get_lazy(opts, :keypair, fn ->
        # Best-effort fallback — callers should pass :keypair from context,
        # but if omitted we regenerate one. Signature won't match the
        # installed config in that case; the plug will reject with
        # SignatureError — that's the correct failure for careless tests.
        Mailglass.WebhookFixtures.generate_sendgrid_keypair()
      end)

    timestamp =
      case Keyword.get(opts, :timestamp) do
        nil -> Integer.to_string(System.system_time(:second))
        ts when is_integer(ts) -> Integer.to_string(ts)
        ts when is_binary(ts) -> ts
      end

    sig_b64 = Mailglass.WebhookFixtures.sign_sendgrid_payload(timestamp, raw_body, priv_key)

    base_conn(:sendgrid, raw_body)
    |> Plug.Conn.put_req_header("x-twilio-email-event-webhook-signature", sig_b64)
    |> Plug.Conn.put_req_header("x-twilio-email-event-webhook-timestamp", timestamp)
  end

  # Builds the shared `%Plug.Conn{}` skeleton: POST to /webhooks/<provider>
  # with `content-type: application/json`, raw body populated, and
  # `conn.private[:raw_body]` mirrored (Plan 02 `CachingBodyReader.read_body/2`
  # stores raw bytes there).
  defp base_conn(provider, raw_body) do
    :post
    |> Plug.Test.conn("/webhooks/#{provider}", raw_body)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_private(:raw_body, raw_body)
  end

  @doc """
  Asserts that a webhook ingest broadcast arrived on the PubSub topic the
  test process is subscribed to (MailerCase setup subscribes to the
  tenant-wide events topic).

  Matches the Phase 3 Projector broadcast shape:
  `{:delivery_updated, delivery_id, event_type, meta}`. Plan 06 extends
  `meta` with `provider` + `event_count`; existing pattern matches keep
  working (maps accept extra keys).

  ## Forms

      # Presence — any delivery_updated broadcast within 100 ms:
      assert_webhook_ingested()

      # Match by event_type atom:
      assert_webhook_ingested(:delivered)

      # Match by meta map pattern (plan 06+ populates :provider in meta):
      assert_webhook_ingested(%{provider: :sendgrid})

      # Custom timeout:
      assert_webhook_ingested(:bounced, 250)
  """
  defmacro assert_webhook_ingested(pattern_or_type \\ nil, timeout \\ 100) do
    quote do
      pattern = unquote(pattern_or_type)
      timeout = unquote(timeout)

      case pattern do
        nil ->
          # Presence check — any broadcast within timeout.
          ExUnit.Assertions.assert_receive(
            {:delivery_updated, _delivery_id, _event_type, _meta},
            timeout,
            "assert_webhook_ingested: no broadcast within #{timeout}ms"
          )

        event_type when is_atom(event_type) ->
          ExUnit.Assertions.assert_receive(
            {:delivery_updated, _delivery_id, ^event_type, _meta},
            timeout,
            "assert_webhook_ingested: no broadcast with event_type=#{inspect(event_type)} within #{timeout}ms"
          )

        meta_pattern when is_map(meta_pattern) ->
          ExUnit.Assertions.assert_receive(
            {:delivery_updated, _delivery_id, _event_type, meta},
            timeout,
            "assert_webhook_ingested: no broadcast within #{timeout}ms"
          )

          assert meta_pattern
                 |> Map.keys()
                 |> Enum.all?(fn k -> Map.get(meta, k) == Map.fetch!(meta_pattern, k) end),
                 "assert_webhook_ingested: received broadcast but meta #{inspect(meta)} does not match #{inspect(meta_pattern)}"
      end
    end
  end

  @doc "Loads a Postmark fixture and returns raw bytes ready for `mailglass_webhook_conn/2`."
  @spec stub_postmark_fixture(String.t()) :: binary()
  def stub_postmark_fixture(name), do: Mailglass.WebhookFixtures.load_postmark_fixture(name)

  @doc "Loads a SendGrid fixture and returns raw bytes ready for `mailglass_webhook_conn/2`."
  @spec stub_sendgrid_fixture(String.t()) :: binary()
  def stub_sendgrid_fixture(name), do: Mailglass.WebhookFixtures.load_sendgrid_fixture(name)

  @doc """
  Re-export of `Mailglass.Clock.Frozen.freeze/1`.

  SendGrid timestamp-skew tests need to freeze wall clock time before
  signing so the generated timestamp lands inside (or outside) the
  300-second verification tolerance window deterministically.
  """
  @spec freeze_timestamp(DateTime.t()) :: DateTime.t()
  def freeze_timestamp(%DateTime{} = dt), do: Mailglass.Clock.Frozen.freeze(dt)
end
