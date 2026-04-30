defmodule Mailglass.Webhook.PlugSESTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.TestRepo
  alias Mailglass.Webhook.Plug, as: WebhookPlug
  alias Mailglass.Webhook.Providers.SES.CertCache
  alias Mailglass.Webhook.WebhookEvent

  @cert_url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem"

  setup do
    CertCache.reset()
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

    {public_key, private_key} = generate_sns_keypair()
    future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
    CertCache.put(@cert_url, public_key, future)

    {:ok, private_key: private_key}
  end

  # ---- helpers (mirror test/mailglass/webhook/providers/ses_test.exs:42-65) ----

  defp build_canonical_string(payload, "Notification") do
    ~w(Message MessageId Subject Timestamp TopicArn Type)
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  defp sign_ses_fixture(name, private_key) do
    raw = Mailglass.WebhookCase.stub_ses_fixture(name)
    payload = Jason.decode!(raw)
    canonical = build_canonical_string(payload, payload["Type"])
    sig = sign_sns_canonical_string(canonical, private_key)
    payload |> Map.put("Signature", sig) |> Jason.encode!()
  end

  # ---- success path (closes BLOCKER → covers SES-01, SES-03, SES-04, SES-05) ----

  describe "call/2 SES Notification end-to-end" do
    test "returns 200 and persists WebhookEvent on a valid signed Notification",
         %{private_key: private_key} do
      raw = sign_ses_fixture("notification_delivery", private_key)
      conn = Mailglass.WebhookCase.mailglass_webhook_conn(:ses, raw)

      result = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))

      assert result.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end

    test "returns 200 and persists once on a replayed Notification",
         %{private_key: private_key} do
      raw = sign_ses_fixture("notification_delivery", private_key)
      conn = Mailglass.WebhookCase.mailglass_webhook_conn(:ses, raw)

      first = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))
      second = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))

      assert first.status == 200
      assert second.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end

  # ---- bad signature path (defense-in-depth + PII guard) ----

  describe "call/2 SES bad signature response" do
    test "returns 401 when the Message field is tampered",
         %{private_key: private_key} do
      raw = sign_ses_fixture("notification_delivery", private_key)

      tampered =
        String.replace(raw, "\"Message\":", "\"Message\":\"TAMPERED\", \"X\":", global: false)

      conn = Mailglass.WebhookCase.mailglass_webhook_conn(:ses, tampered)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))
        end)

      assert result.status == 401
      assert log =~ "provider=ses"
      refute log =~ raw
    end
  end

  # ---- explicit init/1 sanity (mirrors plug_mailgun_test.exs:129-133) ----

  describe "call/2 SES explicit route execution" do
    test "init/1 accepts :ses as an explicit provider" do
      assert Keyword.get(WebhookPlug.init(provider: :ses), :provider) == :ses
    end
  end
end
