defmodule Mailglass.Webhook.Providers.MailgunTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Webhook.Providers.{Mailgun, MailgunReplayCache}

  @signing_key "mailgun-signing-key"
  @config %{
    signing_key: @signing_key,
    timestamp_tolerance_seconds: 300,
    future_skew_seconds: 60,
    replay_cache_ttl_seconds: 900
  }

  setup do
    MailgunReplayCache.reset()
    :ok
  end

  describe "verify!/3 Mailgun verification" do
    test "returns :ok for a valid signed payload" do
      body = signed_fixture("delivered")

      assert :ok = Mailgun.verify!(body, [], @config)
    end

    test "reuses a caller-supplied decoded payload for verification and normalization" do
      body = signed_fixture("delivered", token: "decoded-mailgun-token")
      decoded = Jason.decode(body)

      assert :ok = Mailgun.verify_decoded!(decoded, [], @config)
      [event] = Mailgun.normalize_decoded(decoded, [])
      assert event.metadata["provider_event_id"] == "decoded-mailgun-token"
    end

    test "raises :malformed_header when the signature object is missing" do
      body = load_mailgun_fixture("delivered")

      err = catch_raised(fn -> Mailgun.verify!(body, [], @config) end)
      assert %SignatureError{type: :malformed_header, provider: :mailgun} = err
    end

    test "raises ConfigError when signing_key is missing" do
      body = signed_fixture("delivered")

      err = catch_raised(fn -> Mailgun.verify!(body, [], %{}) end)
      assert %ConfigError{type: :webhook_verification_key_missing} = err
    end

    test "raises :bad_signature when the signature is tampered" do
      body = signed_fixture("delivered")
      tampered = String.replace(body, "\"signature\":\"", "\"signature\":\"0", global: false)
      refute tampered == body

      err = catch_raised(fn -> Mailgun.verify!(tampered, [], @config) end)
      assert %SignatureError{type: :bad_signature, provider: :mailgun} = err
    end

    test "raises :timestamp_skew for a stale timestamp" do
      frozen_at = Mailglass.WebhookCase.freeze_timestamp(~U[2026-04-28 16:00:00Z])
      timestamp = frozen_at |> DateTime.add(-601, :second) |> DateTime.to_unix()
      body = signed_fixture("delivered", timestamp: timestamp)

      err = catch_raised(fn -> Mailgun.verify!(body, [], @config) end)
      assert %SignatureError{type: :timestamp_skew, provider: :mailgun} = err
    end

    test "raises :timestamp_skew with future-skew detail" do
      frozen_at = Mailglass.WebhookCase.freeze_timestamp(~U[2026-04-28 16:00:00Z])
      timestamp = frozen_at |> DateTime.add(120, :second) |> DateTime.to_unix()
      body = signed_fixture("delivered", timestamp: timestamp)

      err = catch_raised(fn -> Mailgun.verify!(body, [], @config) end)
      assert %SignatureError{type: :timestamp_skew, provider: :mailgun} = err
      assert err.context[:detail] =~ "future"
    end
  end

  describe "verify!/3 Mailgun replay handling" do
    test "returns {:ok, :replay} when the token has already been accepted" do
      body = signed_fixture("accepted", token: "mailgun-replay-token")

      assert :ok = Mailgun.verify!(body, [], @config)
      assert {:ok, :replay} = Mailgun.verify!(body, [], @config)
    end

    test "only one concurrent verification can claim a fresh token" do
      body = signed_fixture("accepted", token: "mailgun-race-token")

      results =
        1..2
        |> Task.async_stream(fn _ -> Mailgun.verify!(body, [], @config) end,
          ordered: false,
          max_concurrency: 2
        )
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.sort(results) == [:ok, {:ok, :replay}]
    end

    test "reclaims expired tokens but refuses a new token when live capacity is full" do
      now = Mailglass.Clock.utc_now()
      Application.put_env(:mailglass, :mailgun_replay_cache, max_entries: 1)

      on_exit(fn -> Application.delete_env(:mailglass, :mailgun_replay_cache) end)

      assert :ok = MailgunReplayCache.check_and_put("expired", DateTime.add(now, -1, :second))
      assert :ok = MailgunReplayCache.check_and_put("fresh", DateTime.add(now, 60, :second))

      assert {:error, :replay} =
               MailgunReplayCache.check_and_put("overflow", DateTime.add(now, 60, :second))

      assert :ets.info(MailgunReplayCache.table(), :size) == 1
    end
  end

  describe "normalize/2 Mailgun event mapping" do
    test "accepted -> :queued" do
      [event] = Mailgun.normalize(signed_fixture("accepted", token: "token-accepted"), [])

      assert event.type == :queued
      assert event.reject_reason == nil
      assert event.metadata["provider"] == "mailgun"
      assert event.metadata["provider_event_id"] == "token-accepted"
    end

    test "delivered -> :delivered" do
      [event] = Mailgun.normalize(signed_fixture("delivered"), [])

      assert event.type == :delivered
      assert event.reject_reason == nil
    end

    test "failed temporary -> :deferred" do
      [event] = Mailgun.normalize(signed_fixture("failed_temporary"), [])

      assert event.type == :deferred
      assert event.reject_reason == nil
      assert event.metadata["severity"] == "temporary"
      assert event.metadata["reason"] == "generic"
      assert is_map(event.metadata["delivery-status"])
      assert is_binary(event.metadata["timestamp"])
    end

    test "failed permanent bounce -> :bounced with preserved raw details" do
      [event] = Mailgun.normalize(signed_fixture("failed_permanent_bounce"), [])

      assert event.type == :bounced
      assert event.reject_reason == :bounced
      assert event.metadata["severity"] == "permanent"
      assert event.metadata["reason"] == "bounce"
      assert event.metadata["delivery-status"]["code"] == 550
    end

    test "failed permanent rejected -> :rejected with preserved raw details" do
      [event] = Mailgun.normalize(signed_fixture("failed_permanent_rejected"), [])

      assert event.type == :rejected
      assert event.reject_reason in [:blocked, :other]
      assert event.metadata["severity"] == "permanent"
      assert event.metadata["reason"] == "suppress-bounce"
      assert event.metadata["delivery-status"]["message"] =~ "suppressed"
    end

    test "opened -> :opened" do
      [event] = Mailgun.normalize(signed_fixture("opened"), [])
      assert event.type == :opened
    end

    test "clicked -> :clicked" do
      [event] = Mailgun.normalize(signed_fixture("clicked"), [])
      assert event.type == :clicked
    end

    test "complained -> :complained" do
      [event] = Mailgun.normalize(signed_fixture("complained"), [])
      assert event.type == :complained
    end

    test "unsubscribed -> :unsubscribed" do
      [event] = Mailgun.normalize(signed_fixture("unsubscribed"), [])
      assert event.type == :unsubscribed
    end

    test "malformed JSON returns [] and logs" do
      {events, log} = with_log(fn -> Mailgun.normalize("not json", []) end)
      assert events == []
      assert log =~ "Mailgun normalize: malformed JSON body"
    end
  end

  defp signed_fixture(name, opts \\ []) do
    name
    |> load_mailgun_fixture()
    |> sign_mailgun_payload(@signing_key, opts)
  end

  defp catch_raised(fun) do
    try do
      fun.()
      flunk("expected exception to be raised, but function returned normally")
    rescue
      error -> error
    end
  end
end
