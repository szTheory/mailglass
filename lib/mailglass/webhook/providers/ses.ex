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

  alias Mailglass.SignatureError
  alias Mailglass.Events.Event
  alias Mailglass.Webhook.Providers.SES.{CertCache, TrustPolicy}

  @default_cert_cache_ttl_seconds 86_400
  @default_cert_cache_negative_ttl_seconds 60
  @default_cert_cache_max_entries 1_024
  @default_cert_response_bytes 65_536
  @maximum_cert_response_bytes 1_048_576

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
    verify_decoded!(Jason.decode(raw_body), [], config)
  end

  @doc false
  @spec verify_decoded!({:ok, term()} | {:error, term()}, [{String.t(), String.t()}], map()) ::
          :ok | {:ok, :control_plane, :subscription_confirmed | :unsubscribe_confirmed}
  def verify_decoded!({:ok, %{} = payload}, _headers, %{} = config) do
    # Step 1: verify the SNS envelope (shared crypto seam, reused by inbound).
    :ok = verify_envelope_decoded!(payload, config)
    msg_type = fetch_required_field!(payload, "Type")

    # Step 2: dispatch on MessageType (all types verified above).
    dispatch_message_type(msg_type, payload, config)
  end

  def verify_decoded!(_decoded, _headers, %{} = _config) do
    raise SignatureError.new(:malformed_header,
            provider: :ses,
            context: %{detail: "SNS payload is not valid JSON"}
          )
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
    :ok = verify_envelope_decoded!(payload, config)
    {:ok, payload}
  end

  @doc false
  @spec verify_envelope_decoded!(map(), map()) :: :ok
  def verify_envelope_decoded!(%{} = payload, %{} = config) do
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

    :ok
  end

  @impl Mailglass.Webhook.Provider
  @spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
  def normalize(raw_body, headers) when is_binary(raw_body),
    do: normalize_decoded(Jason.decode(raw_body), headers)

  @doc false
  def normalize_decoded({:ok, %{} = sns_payload}, _headers) do
    with "Notification" <- Map.get(sns_payload, "Type"),
         message_str when is_binary(message_str) <- Map.get(sns_payload, "Message"),
         {:ok, ses_payload} <- Jason.decode(message_str) do
      sns_message_id = Map.get(sns_payload, "MessageId", "unknown")
      normalize_ses(ses_payload, sns_message_id)
    else
      {:error, _} ->
        Logger.warning("[mailglass] SES normalize: malformed nested SES Message JSON")
        []

      _other ->
        Logger.warning(
          "[mailglass] SES normalize: unexpected SNS payload shape or non-Notification type"
        )

        []
    end
  end

  def normalize_decoded(_decoded, _headers) do
    Logger.warning("[mailglass] SES normalize: malformed SNS envelope JSON")
    []
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

  defp fetch_public_key!(cert_url, config) do
    fetch = fn ->
      try do
        {:ok, cert_url |> fetch_cert_via_httpc!(config) |> extract_public_key_from_pem!()}
      rescue
        error in [SignatureError] -> {:error, error.type}
      end
    end

    case CertCache.fetch_or_store(cert_url, fetch,
           positive_ttl_seconds:
             Map.get(config, :cert_cache_ttl_seconds, @default_cert_cache_ttl_seconds),
           negative_ttl_seconds:
             Map.get(
               config,
               :cert_cache_negative_ttl_seconds,
               @default_cert_cache_negative_ttl_seconds
             ),
           max_entries: Map.get(config, :cert_cache_max_entries, @default_cert_cache_max_entries)
         ) do
      {:ok, public_key} ->
        public_key

      {:error, reason} ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "cert fetch failed", reason: inspect(reason)}
              )
    end
  end

  defp fetch_cert_via_httpc!(cert_url, config) do
    httpc_mod = httpc_client(config)
    ssl_opts = [verify: :verify_peer, cacerts: :public_key.cacerts_get()]
    timeout_ms = bounded_cert_timeout!(config)

    http_opts = [
      ssl: ssl_opts,
      autoredirect: false,
      timeout: timeout_ms,
      connect_timeout: timeout_ms
    ]

    url_charlist = String.to_charlist(cert_url)
    # `:httpc` expects the literal receiver selector `:self` here. Passing the
    # caller pid looks plausible but is rejected as an invalid stream option,
    # which silently falls back to buffering the entire response.
    request_opts = [sync: false, stream: {:self, :once}]

    case apply(httpc_mod, :request, [:get, {url_charlist, []}, http_opts, request_opts]) do
      {:ok, request_id} when is_reference(request_id) ->
        deadline_ms = System.monotonic_time(:millisecond) + timeout_ms
        receive_cert_stream!(httpc_mod, request_id, config, deadline_ms)

      # Retain compatibility with small injected clients that implement the
      # historical synchronous result shape. Production :httpc always takes
      # the streaming branch above.
      {:ok, {{_vsn, 200, _}, _headers, body}} when is_list(body) ->
        body |> IO.iodata_to_binary() |> limit_cert_body!(config)

      {:ok, {{_vsn, 200, _}, _headers, body}} when is_binary(body) ->
        limit_cert_body!(body, config)

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

  defp receive_cert_stream!(httpc_mod, request_id, config, deadline_ms) do
    receive do
      {:http, {^request_id, :stream_start, headers, handler_pid}} ->
        reject_oversized_content_length!(httpc_mod, request_id, headers, config)
        stream_next!(httpc_mod, handler_pid)
        collect_cert_stream!(httpc_mod, request_id, handler_pid, config, deadline_ms, [], 0)

      {:http, {^request_id, {{_vsn, status, _}, _headers, _body}}} ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "cert fetch returned HTTP #{status}"}
              )

      {:http, {^request_id, {:error, reason}}} ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "cert fetch failed", reason: inspect(reason)}
              )
    after
      remaining_timeout_ms(deadline_ms) ->
        cancel_request(httpc_mod, request_id)
        raise cert_timeout_error()
    end
  end

  defp collect_cert_stream!(
         httpc_mod,
         request_id,
         handler_pid,
         config,
         deadline_ms,
         chunks,
         bytes
       ) do
    receive do
      {:http, {^request_id, :stream, chunk}} when is_binary(chunk) ->
        next_bytes = bytes + byte_size(chunk)

        if next_bytes > cert_response_limit!(config) do
          cancel_request(httpc_mod, request_id)
          raise cert_oversized_error()
        end

        stream_next!(httpc_mod, handler_pid)

        collect_cert_stream!(
          httpc_mod,
          request_id,
          handler_pid,
          config,
          deadline_ms,
          [chunk | chunks],
          next_bytes
        )

      {:http, {^request_id, :stream_end, _headers}} ->
        chunks |> Enum.reverse() |> IO.iodata_to_binary()

      {:http, {^request_id, {:error, reason}}} ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "cert fetch failed", reason: inspect(reason)}
              )
    after
      remaining_timeout_ms(deadline_ms) ->
        cancel_request(httpc_mod, request_id)
        raise cert_timeout_error()
    end
  end

  defp reject_oversized_content_length!(httpc_mod, request_id, headers, config) do
    content_length =
      Enum.find_value(headers, fn
        {name, value} when is_list(name) and is_list(value) ->
          if String.downcase(List.to_string(name)) == "content-length" do
            case Integer.parse(List.to_string(value)) do
              {size, ""} -> size
              _ -> nil
            end
          end

        _ ->
          nil
      end)

    if is_integer(content_length) and content_length > cert_response_limit!(config) do
      cancel_request(httpc_mod, request_id)
      raise cert_oversized_error()
    end
  end

  defp stream_next!(httpc_mod, handler_pid), do: apply(httpc_mod, :stream_next, [handler_pid])

  defp cancel_request(httpc_mod, request_id) do
    if function_exported?(httpc_mod, :cancel_request, 1) do
      _ = apply(httpc_mod, :cancel_request, [request_id])
    end

    :ok
  end

  defp remaining_timeout_ms(deadline_ms) do
    max(deadline_ms - System.monotonic_time(:millisecond), 0)
  end

  defp limit_cert_body!(body, config) when is_binary(body) do
    max_bytes = cert_response_limit!(config)

    if byte_size(body) <= max_bytes do
      body
    else
      raise cert_oversized_error()
    end
  end

  defp cert_response_limit!(config) do
    case Map.get(config, :cert_max_response_bytes, @default_cert_response_bytes) do
      bytes when is_integer(bytes) and bytes > 0 and bytes <= @maximum_cert_response_bytes ->
        bytes

      _ ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "invalid cert response limit"}
              )
    end
  end

  defp bounded_cert_timeout!(config) do
    case Map.get(config, :cert_request_timeout_ms, @confirm_timeout_ms) do
      timeout when is_integer(timeout) and timeout > 0 and timeout <= 30_000 ->
        timeout

      _ ->
        raise SignatureError.new(:bad_signature,
                provider: :ses,
                context: %{detail: "invalid cert request timeout"}
              )
    end
  end

  defp cert_oversized_error,
    do:
      SignatureError.new(:bad_signature,
        provider: :ses,
        context: %{detail: "cert fetch response exceeded maximum bytes"}
      )

  defp cert_timeout_error,
    do:
      SignatureError.new(:bad_signature,
        provider: :ses,
        context: %{detail: "cert fetch timed out"}
      )

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

  # ---- Private: ConfirmSubscription URL construction ----

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
        Mailglass.Config.ses_http_client()
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

  # ---- SES bounce mapping ----

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

  # ---- SES event publishing type mapping ----

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

  # ---- Stable provider_event_id ----

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
