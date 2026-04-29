defmodule Mailglass.Webhook.Providers.SES.CertCacheTest do
  use ExUnit.Case, async: false

  alias Mailglass.Webhook.Providers.SES.CertCache

  @url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem"

  setup do
    start_supervised!(CertCache.Supervisor)
    CertCache.reset()
    :ok
  end

  defp future_dt(seconds \\ 86_400),
    do: DateTime.add(DateTime.utc_now(), seconds, :second)

  defp past_dt(seconds \\ 1),
    do: DateTime.add(DateTime.utc_now(), -seconds, :second)

  describe "fetch_public_key/1" do
    test "returns :miss on empty cache" do
      assert :miss = CertCache.fetch_public_key(@url)
    end

    test "returns {:ok, public_key} on cache hit within TTL" do
      fake_key = {:RSAPublicKey, 12345, 65537}
      CertCache.put(@url, fake_key, future_dt())

      assert {:ok, ^fake_key} = CertCache.fetch_public_key(@url)
    end

    test "returns :miss for expired entry" do
      fake_key = {:RSAPublicKey, 12345, 65537}
      CertCache.put(@url, fake_key, past_dt())

      assert :miss = CertCache.fetch_public_key(@url)
    end

    test "evicts expired entry from ETS on miss path" do
      fake_key = {:RSAPublicKey, 12345, 65537}
      CertCache.put(@url, fake_key, past_dt())

      # Confirm it was stored
      assert :ets.lookup(CertCache.table(), @url) != []

      # Trigger expiry eviction via fetch
      assert :miss = CertCache.fetch_public_key(@url)

      # Confirm it was evicted
      assert :ets.lookup(CertCache.table(), @url) == []
    end

    test "different URLs are cached independently" do
      url_a = "https://sns.us-east-1.amazonaws.com/cert-a.pem"
      url_b = "https://sns.us-east-1.amazonaws.com/cert-b.pem"
      key_a = {:RSAPublicKey, 11111, 65537}
      key_b = {:RSAPublicKey, 22222, 65537}

      CertCache.put(url_a, key_a, future_dt())
      CertCache.put(url_b, key_b, future_dt())

      assert {:ok, ^key_a} = CertCache.fetch_public_key(url_a)
      assert {:ok, ^key_b} = CertCache.fetch_public_key(url_b)
    end
  end

  describe "reset/0" do
    test "clears all entries from the cache" do
      CertCache.put(@url, {:RSAPublicKey, 99, 3}, future_dt())
      assert {:ok, _} = CertCache.fetch_public_key(@url)

      CertCache.reset()

      assert :miss = CertCache.fetch_public_key(@url)
    end
  end

  describe "table/0" do
    test "returns the ETS table atom" do
      assert CertCache.table() == :mailglass_webhook_ses_cert_cache
    end
  end
end
