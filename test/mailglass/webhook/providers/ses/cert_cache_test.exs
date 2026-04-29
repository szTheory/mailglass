defmodule Mailglass.Webhook.Providers.SES.CertCacheTest do
  use ExUnit.Case, async: false

  alias Mailglass.Webhook.Providers.SES.CertCache

  setup do
    start_supervised!(Mailglass.Webhook.Providers.SES.CertCache.Supervisor)
    CertCache.reset()
    :ok
  end

  @url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-abc123.pem"
  @fake_public_key {:RSAPublicKey, 1234567, 65537}

  describe "fetch_public_key/1" do
    test "returns :miss when nothing is cached" do
      assert :miss = CertCache.fetch_public_key(@url)
    end

    test "returns {:ok, key} when cached and not expired" do
      expires_at = DateTime.add(Mailglass.Clock.utc_now(), 3600, :second)
      :ok = CertCache.put(@url, @fake_public_key, expires_at)

      assert {:ok, @fake_public_key} = CertCache.fetch_public_key(@url)
    end

    test "returns :miss when TTL is expired" do
      expires_at = DateTime.add(Mailglass.Clock.utc_now(), -1, :second)
      :ok = CertCache.put(@url, @fake_public_key, expires_at)

      assert :miss = CertCache.fetch_public_key(@url)
    end

    test "evicts expired entry from ETS on miss" do
      expires_at = DateTime.add(Mailglass.Clock.utc_now(), -1, :second)
      :ok = CertCache.put(@url, @fake_public_key, expires_at)

      # Fetch causes eviction
      assert :miss = CertCache.fetch_public_key(@url)

      # Entry should be gone from ETS
      assert [] = :ets.lookup(CertCache.table(), @url)
    end
  end

  describe "reset/0" do
    test "deletes all objects from ETS table" do
      expires_at = DateTime.add(Mailglass.Clock.utc_now(), 3600, :second)
      :ok = CertCache.put(@url, @fake_public_key, expires_at)
      assert {:ok, _} = CertCache.fetch_public_key(@url)

      :ok = CertCache.reset()

      assert :miss = CertCache.fetch_public_key(@url)
    end
  end

  describe "table/0" do
    test "returns :mailglass_webhook_ses_cert_cache" do
      assert :mailglass_webhook_ses_cert_cache = CertCache.table()
    end
  end
end
