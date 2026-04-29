defmodule Mailglass.Webhook.Providers.Resend do
  @moduledoc """
  Resend webhook verifier + normalizer.

  Verifier: Svix-style HMAC-SHA256 over `svix-id.svix-timestamp.raw_body`.
  Resend signs one or more `v1,<base64>` values in the `svix-signature`
  header, allowing zero-downtime secret rotation. This verifier decodes
  the configured `whsec_...` secret, enforces a replay window, and
  compares signatures with `Plug.Crypto.secure_compare/2`.

  Normalizer: decodes the JSON object body and maps Resend's `type`
  strings into the Anymail taxonomy verbatim where possible. Unmapped
  event types fall through to `:unknown` with `Logger.warning`.
  """

  @behaviour Mailglass.Webhook.Provider

  require Logger

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Events.Event

  @id_header "svix-id"
  @timestamp_header "svix-timestamp"
  @signature_header "svix-signature"
  @default_tolerance_seconds 300

  @impl Mailglass.Webhook.Provider
  @spec verify!(binary(), [{String.t(), String.t()}], map()) :: :ok
  def verify!(raw_body, headers, %{} = config)
      when is_binary(raw_body) and is_list(headers) do
    tolerance = Map.get(config, :timestamp_tolerance_seconds, @default_tolerance_seconds)
    secret = fetch_secret!(config)

    with {:ok, svix_id} <- fetch_header(headers, @id_header),
         {:ok, svix_timestamp} <- fetch_header(headers, @timestamp_header),
         {:ok, svix_signature} <- fetch_header(headers, @signature_header),
         :ok <- verify_timestamp(svix_timestamp, tolerance) do
      signed_content = "#{svix_id}.#{svix_timestamp}.#{raw_body}"

      expected_sig =
        :crypto.mac(:hmac, :sha256, secret, signed_content)
        |> Base.encode64()

      if valid_signature?(svix_signature, expected_sig) do
        :ok
      else
        raise SignatureError.new(:bad_signature, provider: :resend)
      end
    else
      {:error, :missing_header} ->
        raise SignatureError.new(:missing_header, provider: :resend)

      {:error, :timestamp_skew} ->
        raise SignatureError.new(:timestamp_skew, provider: :resend)

      {:error, :malformed_timestamp} ->
        raise SignatureError.new(:malformed_header,
                provider: :resend,
                context: %{detail: "svix-timestamp header is not a Unix integer"}
              )
    end
  end

  defp fetch_header(headers, name) do
    case List.keyfind(headers, name, 0) do
      {^name, value} when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :missing_header}
    end
  end

  defp verify_timestamp(timestamp, tolerance) do
    case Integer.parse(timestamp) do
      {timestamp_int, ""} ->
        diff = abs(System.system_time(:second) - timestamp_int)
        if diff <= tolerance, do: :ok, else: {:error, :timestamp_skew}

      _ ->
        {:error, :malformed_timestamp}
    end
  end

  defp fetch_secret!(config) do
    case Map.get(config, :secret) do
      "whsec_" <> encoded_secret ->
        case Base.decode64(encoded_secret) do
          {:ok, secret} ->
            secret

          :error ->
            raise ConfigError.new(:invalid,
                    context: %{key: :secret, provider: :resend}
                  )
        end

      nil ->
        raise ConfigError.new(:webhook_verification_key_missing,
                context: %{
                  provider: :resend,
                  hint:
                    "configure {:resend, secret: \"whsec_<base64-secret>\"} in your :mailglass config"
                }
              )

      _other ->
        raise ConfigError.new(:invalid, context: %{key: :secret, provider: :resend})
    end
  end

  defp valid_signature?(header_value, expected_sig) do
    header_value
    |> String.split(" ", trim: true)
    |> Enum.any?(fn
      "v1," <> sig when byte_size(sig) == byte_size(expected_sig) ->
        Plug.Crypto.secure_compare(sig, expected_sig)

      _ ->
        false
    end)
  end

  @impl Mailglass.Webhook.Provider
  @spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
  def normalize(raw_body, _headers) when is_binary(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, payload} when is_map(payload) ->
        [build_event(payload)]

      _ ->
        Logger.warning("[mailglass] Resend normalize: malformed JSON body")
        []
    end
  end

  defp build_event(payload) do
    {type, reject_reason} = map_event_type(payload["type"])

    %Event{
      type: type,
      reject_reason: reject_reason,
      metadata: %{
        "provider" => "resend",
        "provider_event_id" => to_string_or_nil(payload["id"]),
        "record_type" => payload["type"],
        "message_id" => extract_message_id(payload)
      }
    }
  end

  defp map_event_type("email.sent"), do: {:sent, nil}
  defp map_event_type("email.delivered"), do: {:delivered, nil}
  defp map_event_type("email.delivery_delayed"), do: {:deferred, nil}
  defp map_event_type("email.bounced"), do: {:bounced, :bounced}
  defp map_event_type("email.complained"), do: {:complained, nil}

  defp map_event_type(other) do
    Logger.warning("[mailglass] Unmapped Resend event type: #{inspect(other)}")
    {:unknown, nil}
  end

  defp extract_message_id(payload) do
    payload
    |> Map.get("data", %{})
    |> case do
      %{} = data -> data["email_id"] || to_string_or_nil(payload["id"])
      _ -> to_string_or_nil(payload["id"])
    end
  end

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(value), do: to_string(value)
end
