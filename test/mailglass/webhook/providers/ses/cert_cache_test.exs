defmodule Mailglass.Webhook.Providers.SES.CertCacheTest do
  use ExUnit.Case, async: false

  alias Mailglass.Webhook.Providers.SES.CertCache

  @url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-abc123.pem"
  @fake_public_key {:RSAPublicKey, 1_234_567, 65537}

  setup do
    start_supervised!(CertCache.Supervisor)
    CertCache.reset()
    :ok
  end

  defp future_dt(seconds \\ 86_400),
    do: DateTime.add(Mailglass.Clock.utc_now(), seconds, :second)

  defp past_dt(seconds \\ 1),
    do: DateTime.add(Mailglass.Clock.utc_now(), -seconds, :second)

  describe "fetch_public_key/1" do
    test "returns :miss on empty cache" do
      assert :miss = CertCache.fetch_public_key(@url)
    end

    test "returns {:ok, key} when cached and not expired" do
      :ok = CertCache.put(@url, @fake_public_key, future_dt())
      assert {:ok, @fake_public_key} = CertCache.fetch_public_key(@url)
    end

    test "returns :miss when TTL is expired" do
      :ok = CertCache.put(@url, @fake_public_key, past_dt())
      assert :miss = CertCache.fetch_public_key(@url)
    end

    test "evicts expired entry from ETS on miss" do
      :ok = CertCache.put(@url, @fake_public_key, past_dt())
      assert :miss = CertCache.fetch_public_key(@url)
      assert [] = :ets.lookup(CertCache.table(), @url)
    end

    test "different URLs are cached independently" do
      url_a = "https://sns.us-east-1.amazonaws.com/cert-a.pem"
      url_b = "https://sns.us-east-1.amazonaws.com/cert-b.pem"
      key_a = {:RSAPublicKey, 11111, 65537}
      key_b = {:RSAPublicKey, 22222, 65537}

      :ok = CertCache.put(url_a, key_a, future_dt())
      :ok = CertCache.put(url_b, key_b, future_dt())

      assert {:ok, ^key_a} = CertCache.fetch_public_key(url_a)
      assert {:ok, ^key_b} = CertCache.fetch_public_key(url_b)
    end
  end

  describe "reset/0" do
    test "deletes all objects from ETS table" do
      :ok = CertCache.put(@url, @fake_public_key, future_dt())
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
