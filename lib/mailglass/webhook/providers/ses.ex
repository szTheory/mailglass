defmodule Mailglass.Webhook.Providers.SES do
  @moduledoc """
  AWS SES webhook verifier via Amazon SNS.

  Implements `Mailglass.Webhook.Provider` for SES events delivered through
  SNS HTTP subscriptions. Handles all three SNS message types on the same
  endpoint:

    * `Notification` — SES event payload; returns `:ok` for the ingest pipeline
    * `SubscriptionConfirmation` — auto-confirms after verification; returns
      `{:ok, :control_plane, :subscription_confirmed}`
    * `UnsubscribeConfirmation` — verifies and no-ops; returns
      `{:ok, :control_plane, :unsubscribe_confirmed}`

  ## Verification algorithm

  1. Parse raw body as JSON (SNS delivers `text/plain` but body is valid JSON)
  2. Validate `SigningCertURL` with `TrustPolicy.valid_cert_url?/1` before network I/O
  3. Fetch X.509 public key from `CertCache` (ETS hit) or `:httpc` (cache miss)
  4. Build canonical string from message fields (byte-sorted per AWS spec)
  5. Verify RSA-SHA1 (SignatureVersion 1) or RSA-SHA256 (SignatureVersion 2) signature
  6. Dispatch on `MessageType`:
     - `Notification` → return `:ok`
     - `SubscriptionConfirmation` → validate SubscribeURL, construct ConfirmSubscription
      URL from TopicArn + Token, :httpc GET with redirects disabled
     - `UnsubscribeConfirmation` → log telemetry, return control-plane no-op

  ## Inbound-reuse seam

  `verify_envelope!/2` exposes steps 1-5 (the SNS X.509 verification) as a public
  seam so `mailglass_inbound`'s SES ingress can reuse the byte-identical SNS
  envelope verification without reinventing cryptography (-01). `verify!/3`
  calls it, then dispatches on `MessageType`; its public return and behavior are
  unchanged.

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
    # Step 1: verify the SNS envelope (shared crypto seam, reused by inbound).
    {:ok, payload} = verify_envelope!(raw_body, config)
    msg_type = fetch_required_field!(payload, "Type")

    # Step 2: dispatch on MessageType (all types verified above).
    dispatch_message_type(msg_type, payload, config)
  end

  @doc """
  Verify the SNS envelope's X.509 signature and trust policy, returning the
  decoded SNS payload.

  This is the **inbound-reuse seam** (-01): the SNS JSON envelope is
  byte-identical for outbound webhooks and `mailglass_inbound` SES ingress, so
  the crypto primitive (decode → `TrustPolicy.valid_cert_url?` → `CertCache`
  public-key fetch → canonical-string build → `:public_key.verify`) is factored
  out for `mailglass_inbound.Ingress.Providers.SES` to call directly, then drive
  its own MessageType dispatch (S3 fetch / inline content / control-plane).

  Raises `Mailglass.SignatureError` on any verification failure — identical
  behavior to the steps previously inlined in `verify!/3`. The outbound
  `verify!/3` return and behavior are unchanged.
  """
  @doc since: "1.2.0"
  @spec verify_envelope!(binary(), map()) :: {:ok, map()}
  def verify_envelope!(raw_body, %{} = config) when is_binary(raw_body) do
    payload = decode_payload!(raw_body)
    cert_url = fetch_required_field!(payload, "SigningCertURL")
    sig_version = Map.get(payload, "SignatureVersion", "1")
    signature_b64 = fetch_required_field!(payload, "Signature")
    msg_type = fetch_required_field!(payload, "Type")

    # Validate cert URL before any network I/O.
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
    digest =
      case sig_version do
        "1" ->
          :sha

        "2" ->
          :sha256

        other ->
          raise SignatureError.new(:malformed_header,
                  provider: :ses,
                  context: %{detail: "Unknown SignatureVersion: #{inspect(other)}"}
                )
      end

    decoded_sig =
      case Base.decode64(signature_b64) do
        {:ok, bytes} ->
          bytes

        :error ->
          raise SignatureError.new(:malformed_header,
                  provider: :ses,
                  context: %{detail: "Signature field is not valid base64"}
                )
      end

    unless :public_key.verify(canonical, digest, decoded_sig, public_key) do
      raise SignatureError.new(:bad_signature, provider: :ses)
    end

    {:ok, payload}
  end

  @impl Mailglass.Webhook.Provider
  @spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
  def normalize(raw_body, _headers) when is_binary(raw_body) do
    with {:ok, sns_payload} <- Jason.decode(raw_body),
         "Notification" <- Map.get(sns_payload, "Type"),
         message_str when is_binary(message_str) <- Map.get(sns_payload, "Message"),
         {:ok, ses_payload} <- Jason.decode(message_str) do
      sns_message_id = Map.get(sns_payload, "MessageId", "unknown")
      normalize_ses(ses_payload, sns_message_id)
    else
      {:error, _} ->
        Logger.warning("[mailglass] SES normalize: malformed SNS envelope JSON")
        []

      _other ->
        Logger.warning(
          "[mailglass] SES normalize: unexpected SNS payload shape or non-Notification type"
        )

        []
    end
  end

  # ---- Private: message type dispatch ----

  defp dispatch_message_type("Notification", _payload, _config), do: :ok

  defp dispatch_message_type("SubscriptionConfirmation", payload, config) do
    subscribe_url = fetch_required_field!(payload, "SubscribeURL")
    topic_arn = fetch_required_field!(payload, "TopicArn")
    token = fetch_required_field!(payload, "Token")

    # Validate SubscribeURL for consistency only; do not follow it.
    unless TrustPolicy.valid_subscribe_url?(subscribe_url) do
      raise SignatureError.new(:bad_signature,
              provider: :ses,
              context: %{detail: "SubscribeURL failed trust-policy validation"}
            )
    end

    # Construct ConfirmSubscription URL from signed TopicArn + Token.
    confirm_url = build_confirm_url(topic_arn, token)

    case confirm_subscription(confirm_url, config) do
      :ok ->
        Logger.info("[mailglass] SES SNS SubscriptionConfirmation confirmed topic=#{topic_arn}")
        {:ok, :control_plane, :subscription_confirmed}

      {:error, reason} ->
        Logger.warning(
          "[mailglass] SES SNS SubscriptionConfirmation failed topic=#{topic_arn} reason=#{inspect(reason)}"
        )

        # Treat signature verification failures as non-recoverable input trust failures.
        # Verification succeeded but confirmation failed, so this path still fails closed.
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
    # No-op; do not silently re-confirm.
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

  # NOTE — cache-miss stampede: this is a check-then-act pattern. If N webhook
  # requests arrive concurrently before the cert for a given URL is cached (cold
  # start or after a TTL expiry), each caller independently sees :miss, issues its
  # own :httpc request, and writes the result. ETS :insert is atomic so all writers
  # converge on the same key; correctness is not affected. The impact is N
  # simultaneous HTTP GETs to the SNS cert endpoint per cold burst — acceptable for
  # the expected traffic pattern (one unique cert URL per SNS topic, rarely changes).
  # If serialization is required in future, route the cache-miss path through a
  # TableOwner GenServer call to serialize writers under the same cert URL.
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

  # ---- Private: ConfirmSubscription URL construction () ----

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

  # ---- Private: SES normalization ----

  defp normalize_ses(%{"notificationType" => type} = payload, sns_message_id) do
    normalize_feedback(type, payload, sns_message_id)
  end

  defp normalize_ses(%{"eventType" => type} = payload, sns_message_id) do
    normalize_event_publishing(type, payload, sns_message_id)
  end

  defp normalize_ses(_payload, _sns_message_id) do
    Logger.warning("[mailglass] SES normalize: no notificationType or eventType found")
    []
  end

  # ---- Classic SES feedback notifications (notificationType) ----

  defp normalize_feedback("Bounce", payload, sns_message_id) do
    bounce = Map.get(payload, "bounce", %{})
    recipients = Map.get(bounce, "bouncedRecipients", [])
    {type, reject_reason} = map_bounce(bounce)

    recipients
    |> Enum.with_index()
    |> Enum.map(fn {recipient, idx} ->
      email = recipient["emailAddress"]
      provider_event_id = build_provider_event_id(sns_message_id, email, idx)

      build_event(
        payload,
        sns_message_id,
        type,
        reject_reason,
        provider_event_id,
        email,
        "Bounce",
        %{
          "bounce_type" => to_string_or_nil(get_in(payload, ["bounce", "bounceType"])),
          "bounce_subtype" => to_string_or_nil(get_in(payload, ["bounce", "bounceSubType"]))
        }
      )
    end)
  end

  defp normalize_feedback("Complaint", payload, sns_message_id) do
    complaint = Map.get(payload, "complaint", %{})
    recipients = Map.get(complaint, "complainedRecipients", [])

    recipients
    |> Enum.with_index()
    |> Enum.map(fn {recipient, idx} ->
      email = recipient["emailAddress"]
      provider_event_id = build_provider_event_id(sns_message_id, email, idx)

      build_event(
        payload,
        sns_message_id,
        :complained,
        nil,
        provider_event_id,
        email,
        "Complaint",
        %{"complaint_feedback_type" => to_string_or_nil(complaint["complaintFeedbackType"])}
      )
    end)
  end

  defp normalize_feedback("Delivery", payload, sns_message_id) do
    delivery = Map.get(payload, "delivery", %{})
    recipients = Map.get(delivery, "recipients", [])

    recipients
    |> Enum.with_index()
    |> Enum.map(fn {email, idx} ->
      provider_event_id = build_provider_event_id(sns_message_id, email, idx)

      build_event(
        payload,
        sns_message_id,
        :delivered,
        nil,
        provider_event_id,
        email,
        "Delivery",
        %{}
      )
    end)
  end

  defp normalize_feedback(other, _payload, _sns_message_id) do
    Logger.warning("[mailglass] Unmapped SES notificationType: #{inspect(other)}")
    []
  end

  # ---- SES event publishing (eventType) ----

  defp normalize_event_publishing("Bounce", payload, sns_message_id) do
    bounce = Map.get(payload, "bounce", %{})
    recipients = Map.get(bounce, "bouncedRecipients", [])
    {type, reject_reason} = map_bounce(bounce)
    mail = Map.get(payload, "mail", %{})

    recipients
    |> Enum.with_index()
    |> Enum.map(fn {recipient, idx} ->
      email = recipient["emailAddress"]
      provider_event_id = build_provider_event_id(sns_message_id, email, idx)

      build_event(
        payload,
        sns_message_id,
        type,
        reject_reason,
        provider_event_id,
        email,
        "Bounce",
        %{
          "bounce_type" => to_string_or_nil(bounce["bounceType"]),
          "bounce_subtype" => to_string_or_nil(bounce["bounceSubType"]),
          "ses_message_id" => to_string_or_nil(mail["messageId"])
        }
      )
    end)
  end

  defp normalize_event_publishing("Complaint", payload, sns_message_id) do
    complaint = Map.get(payload, "complaint", %{})
    recipients = Map.get(complaint, "complainedRecipients", [])
    mail = Map.get(payload, "mail", %{})

    recipients
    |> Enum.with_index()
    |> Enum.map(fn {recipient, idx} ->
      email = recipient["emailAddress"]
      provider_event_id = build_provider_event_id(sns_message_id, email, idx)

      build_event(
        payload,
        sns_message_id,
        :complained,
        nil,
        provider_event_id,
        email,
        "Complaint",
        %{
          "complaint_feedback_type" => to_string_or_nil(complaint["complaintFeedbackType"]),
          "ses_message_id" => to_string_or_nil(mail["messageId"])
        }
      )
    end)
  end

  defp normalize_event_publishing("Delivery", payload, sns_message_id) do
    delivery = Map.get(payload, "delivery", %{})
    recipients = Map.get(delivery, "recipients", [])
    mail = Map.get(payload, "mail", %{})

    recipients
    |> Enum.with_index()
    |> Enum.map(fn {email, idx} ->
      provider_event_id = build_provider_event_id(sns_message_id, email, idx)

      build_event(
        payload,
        sns_message_id,
        :delivered,
        nil,
        provider_event_id,
        email,
        "Delivery",
        %{"ses_message_id" => to_string_or_nil(mail["messageId"])}
      )
    end)
  end

  defp normalize_event_publishing(event_type, payload, sns_message_id) do
    mail = Map.get(payload, "mail", %{})
    destinations = Map.get(mail, "destination", [])

    {type, reject_reason} = map_event_type(event_type)

    if is_nil(type) do
      # map_event_type returned nil (e.g. Subscription) — drop silently
      []
    else
      destinations
      |> Enum.with_index()
      |> Enum.map(fn {email, idx} ->
        provider_event_id = build_provider_event_id(sns_message_id, email, idx)

        build_event(
          payload,
          sns_message_id,
          type,
          reject_reason,
          provider_event_id,
          email,
          event_type,
          %{"ses_message_id" => to_string_or_nil(mail["messageId"])}
        )
      end)
    end
  end

  # ---- Shared event builder ----

  # _email is intentionally discarded here. The recipient address is embedded in
  # provider_event_id ("#{sns_message_id}:#{email}") and is recoverable from that
  # field for deduplication and orphan reconciliation. Storing it in a separate
  # metadata key would duplicate PII inside the persisted Event record without
  # adding lookup value — telemetry emission never touches metadata, so the PII
  # policy does not apply to the DB path, but we keep the field absent to keep the
  # schema minimal and consistent across all normalizers.
  defp build_event(
         payload,
         sns_message_id,
         type,
         reject_reason,
         provider_event_id,
         _email,
         record_type,
         extra_metadata
       ) do
    mail = Map.get(payload, "mail", %{})
    ses_message_id = to_string_or_nil(mail["messageId"])

    %Event{
      type: type,
      reject_reason: reject_reason,
      metadata:
        %{
          "provider" => "ses",
          "provider_event_id" => provider_event_id,
          "record_type" => record_type,
          "message_id" => ses_message_id,
          "sns_message_id" => sns_message_id,
          "ses_message_id" => ses_message_id
        }
        |> Map.merge(extra_metadata)
    }
  end

  # ---- SES bounce mapping () ----

  defp map_bounce(%{"bounceType" => "Permanent", "bounceSubType" => sub_type}) do
    case sub_type do
      sub when sub in ["Suppressed", "OnAccountSuppressionList", "UnsubscribedRecipient"] ->
        {:rejected, :blocked}

      _ ->
        {:bounced, :bounced}
    end
  end

  defp map_bounce(%{"bounceType" => "Transient"}), do: {:deferred, nil}
  defp map_bounce(%{"bounceType" => "Undetermined"}), do: {:deferred, nil}
  defp map_bounce(_), do: {:bounced, :bounced}

  # ---- SES event publishing type mapping () ----

  defp map_event_type("Send"), do: {:sent, nil}
  defp map_event_type("Delivery"), do: {:delivered, nil}
  defp map_event_type("Reject"), do: {:rejected, :other}
  defp map_event_type("Complaint"), do: {:complained, nil}
  defp map_event_type("Open"), do: {:opened, nil}
  defp map_event_type("Click"), do: {:clicked, nil}
  defp map_event_type("Rendering Failure"), do: {:failed, nil}
  defp map_event_type("DeliveryDelay"), do: {:deferred, nil}
  defp map_event_type("Subscription"), do: {nil, nil}

  defp map_event_type(other) do
    Logger.warning("[mailglass] Unmapped SES eventType: #{inspect(other)}")
    {:unknown, nil}
  end

  # ---- Stable provider_event_id () ----

  defp build_provider_event_id(sns_message_id, email, _idx) when is_binary(email) do
    "#{sns_message_id}:#{email}"
  end

  defp build_provider_event_id(sns_message_id, _email, idx) do
    "#{sns_message_id}:#{idx}"
  end

  # ---- Utility helpers ----

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(value), do: to_string(value)
end
