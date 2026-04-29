defmodule Mailglass.Webhook.Providers.SES do
  @moduledoc """
  AWS SES webhook verifier via Amazon SNS.

  Implements `Mailglass.Webhook.Provider` for SES events delivered through
  SNS HTTP subscriptions. Handles all three SNS message types on the same
  endpoint per D-01:

    * `Notification` — SES event payload; returns `:ok` for the ingest pipeline
    * `SubscriptionConfirmation` — auto-confirms after verification; returns
      `{:ok, :control_plane, :subscription_confirmed}` (D-03)
    * `UnsubscribeConfirmation` — verifies and no-ops; returns
      `{:ok, :control_plane, :unsubscribe_confirmed}` (D-04)

  ## Verification algorithm

  1. Parse raw body as JSON (SNS delivers `text/plain` but body is valid JSON)
  2. Validate `SigningCertURL` with `TrustPolicy.valid_cert_url?/1` before network I/O (D-06)
  3. Fetch X.509 public key from `CertCache` (ETS hit) or `:httpc` (cache miss) (D-10)
  4. Build canonical string from message fields (byte-sorted per AWS spec)
  5. Verify RSA-SHA1 (SignatureVersion 1) or RSA-SHA256 (SignatureVersion 2) signature
  6. Dispatch on `MessageType`:
     - `Notification` → return `:ok`
     - `SubscriptionConfirmation` → validate SubscribeURL, construct ConfirmSubscription
       URL from TopicArn + Token, :httpc GET with redirects disabled (D-07)
     - `UnsubscribeConfirmation` → log telemetry, return control-plane no-op

  ## Configuration (Application env)

      config :mailglass, :ses,
        cert_cache_ttl_seconds: 86_400   # default 24 hours
  """

  @behaviour Mailglass.Webhook.Provider

  require Logger

  alias Mailglass.{Clock, SignatureError}
  alias Mailglass.Events.Event
  alias Mailglass.Webhook.Providers.SES.{CertCache, TrustPolicy}

  @default_cert_cache_ttl_seconds 86_400

  # Byte-sorted signable fields per AWS SNS signature spec.
  # Subject is optional in Notification — filtered by Map.has_key? at runtime.
  @signable_keys_notification ~w(Message MessageId Subject Timestamp TopicArn Type)
  @signable_keys_control ~w(Message MessageId SubscribeURL Timestamp Token TopicArn Type)

  # ConfirmSubscription :httpc timeout (milliseconds)
  @confirm_timeout_ms 10_000

  @impl Mailglass.Webhook.Provider
  @spec verify!(binary(), [{String.t(), String.t()}], map()) ::
          :ok | {:ok, :control_plane, :subscription_confirmed | :unsubscribe_confirmed}
  def verify!(raw_body, _headers, %{} = config) when is_binary(raw_body) do
    payload = decode_payload!(raw_body)
    cert_url = fetch_required_field!(payload, "SigningCertURL")
    sig_version = Map.get(payload, "SignatureVersion", "1")
    signature_b64 = fetch_required_field!(payload, "Signature")
    msg_type = fetch_required_field!(payload, "Type")

    # D-06, D-09: validate cert URL BEFORE any network I/O
    unless TrustPolicy.valid_cert_url?(cert_url) do
      raise SignatureError.new(:bad_signature,
              provider: :ses,
              context: %{detail: "SigningCertURL failed trust-policy validation"}
            )
    end

    # Fetch or load the public key from ETS cache / network
    public_key = fetch_public_key!(cert_url, config)

    # Build canonical string based on message type
    canonical = build_canonical_string(payload, msg_type)

    # Verify RSA signature
    digest = if sig_version == "2", do: :sha256, else: :sha
    decoded_sig = Base.decode64!(signature_b64)

    unless :public_key.verify(canonical, digest, decoded_sig, public_key) do
      raise SignatureError.new(:bad_signature, provider: :ses)
    end

    # Dispatch on MessageType (all types verified above — D-05)
    dispatch_message_type(msg_type, payload, config)
  end

  @impl Mailglass.Webhook.Provider
  @spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
  def normalize(_raw_body, _headers) do
    # Stub — implemented in Plan 04
    []
  end

  # ---- Private: message type dispatch ----

  defp dispatch_message_type("Notification", _payload, _config), do: :ok

  defp dispatch_message_type("SubscriptionConfirmation", payload, config) do
    subscribe_url = fetch_required_field!(payload, "SubscribeURL")
    topic_arn = fetch_required_field!(payload, "TopicArn")
    token = fetch_required_field!(payload, "Token")

    # D-07: validate SubscribeURL for consistency only — do not follow it
    unless TrustPolicy.valid_subscribe_url?(subscribe_url) do
      raise SignatureError.new(:bad_signature,
              provider: :ses,
              context: %{detail: "SubscribeURL failed trust-policy validation"}
            )
    end

    # D-07: construct ConfirmSubscription URL from signed TopicArn + Token
    confirm_url = build_confirm_url(topic_arn, token)

    case confirm_subscription(confirm_url, config) do
      :ok ->
        Logger.info("[mailglass] SES SNS SubscriptionConfirmation confirmed topic=#{topic_arn}")
        {:ok, :control_plane, :subscription_confirmed}

      {:error, reason} ->
        Logger.warning(
          "[mailglass] SES SNS SubscriptionConfirmation failed topic=#{topic_arn} reason=#{inspect(reason)}"
        )

        # Fail closed per D-09 — verification succeeded but confirmation failed
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{
                  detail: "SubscriptionConfirmation HTTP request failed",
                  reason: reason
                }
              )
    end
  end

  defp dispatch_message_type("UnsubscribeConfirmation", payload, _config) do
    topic_arn = Map.get(payload, "TopicArn", "unknown")
    Logger.info("[mailglass] SES SNS UnsubscribeConfirmation received topic=#{topic_arn}")
    # D-04: no-op — do not silently re-confirm
    {:ok, :control_plane, :unsubscribe_confirmed}
  end

  defp dispatch_message_type(other, _payload, _config) do
    raise SignatureError.new(:malformed_header,
            provider: :ses,
            context: %{detail: "unknown SNS MessageType: #{inspect(other)}"}
          )
  end

  # ---- Private: payload parsing ----

  defp decode_payload!(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, %{} = payload} ->
        payload

      _ ->
        raise SignatureError.new(:malformed_header,
                provider: :ses,
                context: %{detail: "SNS payload is not valid JSON"}
              )
    end
  end

  defp fetch_required_field!(payload, key) do
    case Map.get(payload, key) do
      value when is_binary(value) and value != "" ->
        value

      _ ->
        raise SignatureError.new(:malformed_header,
                provider: :ses,
                context: %{detail: "SNS payload missing required field: #{key}"}
              )
    end
  end

  # ---- Private: canonical string ----

  defp build_canonical_string(payload, "Notification") do
    @signable_keys_notification
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn key -> "#{key}\n#{payload[key]}\n" end)
  end

  defp build_canonical_string(payload, type)
       when type in ["SubscriptionConfirmation", "UnsubscribeConfirmation"] do
    @signable_keys_control
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn key -> "#{key}\n#{payload[key]}\n" end)
  end

  defp build_canonical_string(_payload, other) do
    raise SignatureError.new(:malformed_header,
            provider: :ses,
            context: %{detail: "cannot build canonical string for unknown type: #{inspect(other)}"}
          )
  end

  # ---- Private: certificate fetching ----

  defp fetch_public_key!(cert_url, config) do
    case CertCache.fetch_public_key(cert_url) do
      {:ok, public_key} ->
        public_key

      :miss ->
        pem_binary = fetch_cert_via_httpc!(cert_url, config)
        public_key = extract_public_key_from_pem!(pem_binary)
        ttl = Map.get(config, :cert_cache_ttl_seconds, @default_cert_cache_ttl_seconds)
        expires_at = DateTime.add(Clock.utc_now(), ttl, :second)
        CertCache.put(cert_url, public_key, expires_at)
        public_key
    end
  end

  defp fetch_cert_via_httpc!(cert_url, config) do
    httpc_mod = httpc_client(config)
    ssl_opts = [verify: :verify_peer, cacerts: :public_key.cacerts_get()]
    http_opts = [ssl: ssl_opts, autoredirect: false, timeout: @confirm_timeout_ms]
    url_charlist = String.to_charlist(cert_url)

    case apply(httpc_mod, :request, [:get, {url_charlist, []}, http_opts, []]) do
      {:ok, {{_vsn, 200, _}, _headers, body}} when is_list(body) ->
        IO.iodata_to_binary(body)

      {:ok, {{_vsn, 200, _}, _headers, body}} when is_binary(body) ->
        body

      {:ok, {{_vsn, status, _}, _, _}} ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "cert fetch returned HTTP #{status}"}
              )

      {:error, reason} ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "cert fetch failed", reason: inspect(reason)}
              )
    end
  end

  defp extract_public_key_from_pem!(pem_binary) when is_binary(pem_binary) do
    case :public_key.pem_decode(pem_binary) do
      [{:Certificate, der, :not_encrypted}] ->
        # Use pkix_decode_cert with :otp option to get native Erlang public key terms.
        # OTPCertificate record layout:
        #   elem(otp_cert, 1) = OTPTBSCertificate
        #   elem(tbs, 7)      = OTPSubjectPublicKeyInfo
        #   elem(spki, 2)     = subjectPublicKey ({:RSAPublicKey, n, e} for RSA certs)
        otp_cert = :public_key.pkix_decode_cert(der, :otp)
        tbs = elem(otp_cert, 1)
        spki = elem(tbs, 7)
        elem(spki, 2)

      _ ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "PEM decode failed: expected single Certificate entry"}
              )
    end
  end

  # ---- Private: ConfirmSubscription URL construction (D-07) ----

  defp build_confirm_url(topic_arn, token) do
    # TopicArn format: arn:{partition}:sns:{region}:{account}:{name}
    parts = String.split(topic_arn, ":")
    region = Enum.at(parts, 3, "us-east-1")
    partition = Enum.at(parts, 1, "aws")
    base_host = sns_host(partition, region)

    "https://#{base_host}/?Action=ConfirmSubscription" <>
      "&TopicArn=#{URI.encode_www_form(topic_arn)}" <>
      "&Token=#{URI.encode_www_form(token)}"
  end

  defp sns_host("aws-cn", region), do: "sns.#{region}.amazonaws.com.cn"
  defp sns_host(_partition, region), do: "sns.#{region}.amazonaws.com"

  defp confirm_subscription(url, config) do
    httpc_mod = httpc_client(config)
    ssl_opts = [verify: :verify_peer, cacerts: :public_key.cacerts_get()]
    http_opts = [ssl: ssl_opts, autoredirect: false, timeout: @confirm_timeout_ms]
    url_charlist = String.to_charlist(url)

    case apply(httpc_mod, :request, [:get, {url_charlist, []}, http_opts, []]) do
      {:ok, {{_vsn, status, _}, _headers, _body}} when status in 200..299 ->
        :ok

      {:ok, {{_vsn, status, _}, _, _}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end

  # ---- Private: httpc client resolution ----

  defp httpc_client(config) do
    # Check config map first, then Application env
    # Application.get_env (NOT compile_env) is allowed here per CLAUDE.md rule 1
    case Map.get(config, :httpc_client) do
      mod when is_atom(mod) and not is_nil(mod) ->
        mod

      _ ->
        ses_env = Application.get_env(:mailglass, :ses, [])
        Keyword.get(ses_env, :httpc_client, :httpc)
    end
  end
end
