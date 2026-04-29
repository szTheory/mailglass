defmodule Mailglass.Webhook.Providers.Mailgun do
  @moduledoc """
  Mailgun webhook verifier + normalizer.
  """

  @behaviour Mailglass.Webhook.Provider

  require Logger

  alias Mailglass.{Clock, ConfigError, SignatureError}
  alias Mailglass.Events.Event
  alias Mailglass.Webhook.Providers.MailgunReplayCache

  @default_tolerance_seconds 300
  @default_future_skew_seconds 60
  @default_replay_cache_ttl_seconds 28_800

  @impl Mailglass.Webhook.Provider
  @spec verify!(binary(), [{String.t(), String.t()}], map()) :: :ok | {:ok, :replay}
  def verify!(raw_body, _headers, %{} = config) when is_binary(raw_body) do
    signing_key = fetch_signing_key!(config)
    tolerance = Map.get(config, :timestamp_tolerance_seconds, @default_tolerance_seconds)
    future_skew = Map.get(config, :future_skew_seconds, @default_future_skew_seconds)
    replay_ttl = Map.get(config, :replay_cache_ttl_seconds, @default_replay_cache_ttl_seconds)

    payload = decode_payload!(raw_body)
    {timestamp, token, signature} = fetch_signature_fields!(payload)

    expected_signature =
      :crypto.mac(:hmac, :sha256, signing_key, timestamp <> token)
      |> Base.encode16(case: :lower)

    unless signatures_match?(expected_signature, signature) do
      raise SignatureError.new(:bad_signature, provider: :mailgun)
    end

    verify_timestamp!(timestamp, tolerance, future_skew)

    expires_at = DateTime.add(Clock.utc_now(), replay_ttl, :second)

    case MailgunReplayCache.check_and_put(token, expires_at) do
      :ok -> :ok
      {:error, :replay} -> {:ok, :replay}
    end
  end

  @impl Mailglass.Webhook.Provider
  @spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
  def normalize(raw_body, _headers) when is_binary(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, %{} = payload} ->
        [build_event(payload)]

      {:ok, _other} ->
        Logger.warning("[mailglass] Mailgun normalize: expected JSON object payload")
        []

      {:error, _reason} ->
        Logger.warning("[mailglass] Mailgun normalize: malformed JSON body")
        []
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
                    "configure {:mailgun, signing_key: \"<mailgun-webhook-signing-key>\"} in your :mailglass config"
                }
              )

      _other ->
        raise ConfigError.new(:invalid, context: %{key: :signing_key, provider: :mailgun})
    end
  end

  defp decode_payload!(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, %{} = payload} ->
        payload

      _ ->
        raise SignatureError.new(:malformed_header,
                provider: :mailgun,
                context: %{detail: "signature payload is not valid Mailgun webhook JSON"}
              )
    end
  end

  defp fetch_signature_fields!(%{"signature" => %{} = signature}) do
    with {:ok, timestamp} <- fetch_binary_field(signature, "timestamp"),
         {:ok, token} <- fetch_binary_field(signature, "token"),
         {:ok, provided_signature} <- fetch_binary_field(signature, "signature") do
      {timestamp, token, String.downcase(provided_signature)}
    else
      {:error, detail} ->
        raise SignatureError.new(:malformed_header, provider: :mailgun, context: %{detail: detail})
    end
  end

  defp fetch_signature_fields!(_payload) do
    raise SignatureError.new(:malformed_header,
            provider: :mailgun,
            context: %{detail: "signature object is missing or malformed"}
          )
  end

  defp fetch_binary_field(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        {:error, "signature.#{key} is missing or malformed"}
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
                context: %{detail: "signature.timestamp is not a Unix integer"}
              )
    end
  end

  defp build_event(payload) do
    event_data = Map.get(payload, "event-data", %{})
    {type, reject_reason} = map_event(event_data)
    token = get_in(payload, ["signature", "token"])

    %Event{
      type: type,
      reject_reason: reject_reason,
      metadata: %{
        "provider" => "mailgun",
        "provider_event_id" => token,
        "record_type" => to_string_or_nil(event_data["event"]),
        "message_id" => get_in(event_data, ["message", "headers", "message-id"]),
        "mailgun_event_id" => to_string_or_nil(event_data["id"]),
        "timestamp" => stringify_timestamp(event_data["timestamp"]),
        "severity" => to_string_or_nil(event_data["severity"]),
        "reason" => to_string_or_nil(event_data["reason"]),
        "delivery-status" => stringify_map(event_data["delivery-status"])
      }
    }
  end

  defp map_event(%{"event" => "accepted"}), do: {:queued, nil}
  defp map_event(%{"event" => "delivered"}), do: {:delivered, nil}
  defp map_event(%{"event" => "opened"}), do: {:opened, nil}
  defp map_event(%{"event" => "clicked"}), do: {:clicked, nil}
  defp map_event(%{"event" => "complained"}), do: {:complained, nil}
  defp map_event(%{"event" => "unsubscribed"}), do: {:unsubscribed, nil}

  defp map_event(%{"event" => "failed", "severity" => "temporary"}), do: {:deferred, nil}

  defp map_event(%{"event" => "failed", "severity" => "permanent", "reason" => "bounce"}),
    do: {:bounced, :bounced}

  defp map_event(%{"event" => "failed", "severity" => "permanent"} = event_data) do
    reason = event_data["reason"] |> map_reject_reason()
    {:rejected, reason}
  end

  defp map_event(%{"event" => "failed"}), do: {:failed, nil}

  defp map_event(%{"event" => other}) do
    Logger.warning("[mailglass] Unmapped Mailgun event: #{inspect(other)}")
    {:unknown, nil}
  end

  defp map_event(_other), do: {:unknown, nil}

  defp map_reject_reason(reason) when reason in ["generic", "bounce"], do: :bounced

  defp map_reject_reason(reason) when reason in ["suppress-bounce", "suppress-complaint"],
    do: :blocked

  defp map_reject_reason(reason) when reason in ["spam", "spamtrap"], do: :spam

  defp map_reject_reason(reason) when reason in ["unsubscribe", "suppress-unsubscribe"],
    do: :unsubscribed

  defp map_reject_reason(_reason), do: :other

  defp stringify_timestamp(value) when is_integer(value), do: Integer.to_string(value)

  defp stringify_timestamp(value) when is_float(value),
    do: :erlang.float_to_binary(value, [:compact])

  defp stringify_timestamp(value) when is_binary(value), do: value
  defp stringify_timestamp(_value), do: nil

  defp stringify_map(%{} = value), do: value
  defp stringify_map(_value), do: nil

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(value), do: to_string(value)
end
