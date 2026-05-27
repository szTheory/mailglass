defmodule Mailglass.Webhook.Providers.SES.CertCache do
  @moduledoc """
  ETS-backed SNS X.509 certificate cache for SES webhook signature verification.

  Caches RSA public key terms extracted from AWS SNS signing certificates,
  keyed by `SigningCertURL`. Prevents repeated `:httpc` network calls for the
  same certificate (, ).

  Cache entries expire after a configurable TTL (default 24 hours). Expiry is
  checked lazily during `fetch_public_key/1` — no background timer or sweep.

  ## Usage

      # On cache miss in SES provider:
      case CertCache.fetch_public_key(cert_url) do
        {:ok, public_key} -> public_key
        :miss ->
          public_key = fetch_and_extract_public_key!(cert_url)
          expires_at = DateTime.add(Mailglass.Clock.utc_now(), ttl_seconds, :second)
          CertCache.put(cert_url, public_key, expires_at)
          public_key
      end
  """

  @table :mailglass_webhook_ses_cert_cache

  @doc """
  Fetches the cached RSA public key term for `url`.

  Returns `{:ok, public_key}` on cache hit within TTL, `:miss` on cache miss
  or if the cached entry has expired. Expired entries are evicted from ETS
  before returning `:miss`.
  """
  @spec fetch_public_key(binary()) :: {:ok, term()} | :miss
  def fetch_public_key(url) when is_binary(url) do
    now = Mailglass.Clock.utc_now()

    case :ets.lookup(@table, url) do
      [{^url, public_key, %DateTime{} = expires_at}] ->
        if DateTime.compare(expires_at, now) == :gt do
          {:ok, public_key}
        else
          :ets.delete(@table, url)
          :miss
        end

      _ ->
        :miss
    end
  end

  @doc """
  Inserts `public_key` into the cache keyed by `url` with expiry `expires_at`.

  Overwrites any existing entry for the same URL. The `public_key` term is
  whatever `:public_key.verify/4` accepts as its fourth argument — typically
  an `{:RSAPublicKey, n, e}` record extracted from an X.509 certificate.
  """
  @spec put(binary(), term(), DateTime.t()) :: :ok
  def put(url, public_key, %DateTime{} = expires_at) when is_binary(url) do
    :ets.insert(@table, {url, public_key, expires_at})
    :ok
  end

  @doc since: "0.3.0"
  @spec reset() :: :ok
  def reset do
    :ets.delete_all_objects(@table)
    :ok
  end

  @doc since: "0.3.0"
  @spec table() :: :mailglass_webhook_ses_cert_cache
  def table, do: @table
end
