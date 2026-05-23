defmodule MailglassInbound.Ingress.Providers.Mailgun do
  @moduledoc false

  @behaviour MailglassInbound.Ingress.Provider

  alias Mailglass.{Clock, ConfigError}
  alias Mailglass.Webhook.Providers.MailgunReplayCache
  alias MailglassInbound.SignatureError
  alias MailglassInbound.Ingress.Request

  @default_tolerance_seconds 300
  @default_future_skew_seconds 60
  @default_replay_cache_ttl_seconds 28_800

  # ---------------------------------------------------------------------------
  # verify! — flat-field HMAC over `timestamp <> token` (D-46-08).
  #
  # Mailgun INBOUND routes deliver the signature triple as TOP-LEVEL form
  # fields (`params["timestamp"]`/`["token"]`/`["signature"]`), NOT the nested
  # JSON `%{"signature" => %{...}}` object outbound webhooks send. We therefore
  # REIMPLEMENT the ~15-line HMAC math here over flat fields rather than calling
  # core `Mailglass.Webhook.Providers.Mailgun.verify!/3`, which `Jason.decode`s
  # the body first and would raise on every authentic inbound request
  # (RESEARCH Pitfall 1). Only the shape-agnostic crypto is shared.
  # ---------------------------------------------------------------------------
  @impl MailglassInbound.Ingress.Provider
  def verify!(%Request{params: params}, %{} = config) when is_map(params) do
    signing_key = fetch_signing_key!(config)
    tolerance = Map.get(config, :timestamp_tolerance_seconds, @default_tolerance_seconds)
    future_skew = Map.get(config, :future_skew_seconds, @default_future_skew_seconds)
    replay_ttl = Map.get(config, :replay_cache_ttl_seconds, @default_replay_cache_ttl_seconds)

    {timestamp, token, signature} = fetch_signature_fields!(params)

    expected_signature =
      :crypto.mac(:hmac, :sha256, signing_key, timestamp <> token)
      |> Base.encode16(case: :lower)

    unless signatures_match?(expected_signature, String.downcase(signature)) do
      raise SignatureError.new(:bad_signature, provider: :mailgun)
    end

    verify_timestamp!(timestamp, tolerance, future_skew)

    expires_at = DateTime.add(Clock.utc_now(), replay_ttl, :second)

    case MailgunReplayCache.check_and_put(token, expires_at) do
      :ok -> {:ok, %{auth: :hmac}}
      # Replay is a 200 no-op handled by the plug (D-46-06) — NEVER raise/401.
      {:error, :replay} -> {:replay}
    end
  end

  # normalize/1 is the real Mailgun normalizer (two modes, built in Plan 02
  # Task 2). normalize/2 is the legacy compatibility shim required by the
  # `MailglassInbound.Ingress.Provider` behaviour (mirrors `sendgrid.ex:64-67`);
  # the plug dispatches Mailgun through the struct-arity normalize/1.
  @impl false
  def normalize(%Request{} = request) do
    raw_mime_normalize(request)
  end

  @impl MailglassInbound.Ingress.Provider
  def normalize(raw_body, headers) when is_binary(raw_body) and is_list(headers) do
    normalize(%Request{provider: :mailgun, raw_mime: raw_body, headers: headers})
  end

  # Placeholder normalize body — replaced with the parsed/raw-MIME two-mode
  # implementation in Plan 02 Task 2.
  defp raw_mime_normalize(%Request{}) do
    raise "MailglassInbound.Ingress.Providers.Mailgun.normalize/1 not yet implemented"
  end

  # ---------------------------------------------------------------------------
  # Message-Id extraction (D-46-10).
  #
  # Mailgun inbound has no flat `Message-Id` form field; the RFC Message-Id
  # lives inside the `message-headers` field — a JSON-encoded ordered list of
  # `[name, value]` pairs. Match the header name case-insensitively. The
  # `token` is the replay nonce and is NEVER used for dedupe.
  # ---------------------------------------------------------------------------
  @doc false
  @spec extract_message_id(map()) :: String.t() | nil
  def extract_message_id(params) when is_map(params) do
    with raw when is_binary(raw) <- params["message-headers"],
         {:ok, pairs} when is_list(pairs) <- Jason.decode(raw) do
      Enum.find_value(pairs, fn
        [name, value] when is_binary(name) ->
          if String.downcase(name) == "message-id", do: value

        _ ->
          nil
      end)
    else
      _ -> nil
    end
  end

  defp fetch_signing_key!(config) do
    case Map.get(config, :signing_key) do
      key when is_binary(key) and byte_size(key) > 0 ->
        key

      nil ->
        raise ConfigError.new(:webhook_verification_key_missing,
                context: %{
                  provider: :mailgun,
                  hint:
                    "configure {:mailgun, signing_key: \"<mailgun-webhook-signing-key>\"} in your :mailglass_inbound config"
                }
              )

      _other ->
        raise ConfigError.new(:invalid, context: %{key: :signing_key, provider: :mailgun})
    end
  end

  defp fetch_signature_fields!(params) do
    with {:ok, timestamp} <- fetch_binary_field(params, "timestamp"),
         {:ok, token} <- fetch_binary_field(params, "token"),
         {:ok, signature} <- fetch_binary_field(params, "signature") do
      {timestamp, token, signature}
    else
      {:error, detail} ->
        raise SignatureError.new(:missing_header, provider: :mailgun, context: %{detail: detail})
    end
  end

  defp fetch_binary_field(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        {:error, "#{key} form field is missing or malformed"}
    end
  end

  defp signatures_match?(expected_signature, provided_signature)
       when byte_size(expected_signature) == byte_size(provided_signature) do
    Plug.Crypto.secure_compare(expected_signature, provided_signature)
  end

  defp signatures_match?(_expected_signature, _provided_signature), do: false

  defp verify_timestamp!(timestamp, tolerance, future_skew) do
    with {timestamp_int, ""} <- Integer.parse(timestamp),
         {:ok, signed_at} <- DateTime.from_unix(timestamp_int, :second) do
      now = Clock.utc_now()
      diff = DateTime.diff(now, signed_at, :second)

      cond do
        diff > tolerance ->
          raise SignatureError.new(:timestamp_skew, provider: :mailgun)

        diff < -future_skew ->
          raise SignatureError.new(:timestamp_skew,
                  provider: :mailgun,
                  context: %{detail: "timestamp is #{abs(diff)}s in the future"}
                )

        true ->
          :ok
      end
    else
      _ ->
        raise SignatureError.new(:malformed_header,
                provider: :mailgun,
                context: %{detail: "timestamp form field is not a Unix integer"}
              )
    end
  end
end
