defmodule Mailglass.Webhook.Providers.Postmark do
  @moduledoc """
  Postmark webhook verifier + normalizer.

  Verifier: HTTP Basic Auth (Postmark has no HMAC) via
  `Plug.Crypto.secure_compare/2` for timing-attack-safe comparison
  (CONTEXT D-04). Optional IP allowlist (off by default — Postmark's
  own docs warn origin IPs change; opt-in avoids surprise-blocking).

  Normalizer: pattern-matches each documented `RecordType` to the
  Anymail event taxonomy verbatim (PROJECT D-14). Unmapped types
  fall through to `:unknown` with `Logger.warning` — never silent
  `_ -> :hard_bounce` (CONTEXT D-05).

  ## Provider identity lives in `Event.metadata`

  The `%Mailglass.Events.Event{}` struct has no `:provider` column
  (per V02 schema — provider identity lives on `mailglass_webhook_events`).
  This module stashes `"provider"` + `"provider_event_id"` in
  `Event.metadata` with STRING keys (revision W9; JSONB roundtrip safety).
  Plan 04's Ingest Multi reads these metadata keys to populate the
  `mailglass_webhook_events` row.
  """

  @behaviour Mailglass.Webhook.Provider

  import Bitwise

  require Logger

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Events.Event

  # ---- verify!/3 -----------------------------------------------------

  @impl Mailglass.Webhook.Provider
  @spec verify!(binary(), [{String.t(), String.t()}], map()) :: :ok
  def verify!(_raw_body, headers, %{} = config) when is_list(headers) do
    {user, pass} = fetch_basic_auth!(config)
    verify_basic_auth!(headers, user, pass)
    # IP allowlist is opt-in. When configured, the Plug must forward
    # `:remote_ip` via the config map (the Provider contract is Conn-free
    # per D-02, so the Plug extracts `conn.remote_ip` and threads it
    # through).
    verify_ip_allowlist!(config)
    :ok
  end

  defp fetch_basic_auth!(config) do
    case Map.get(config, :basic_auth) do
      {u, p} when is_binary(u) and is_binary(p) ->
        {u, p}

      _ ->
        raise ConfigError.new(:webhook_verification_key_missing,
                context: %{
                  provider: :postmark,
                  hint: "configure {:postmark, basic_auth: {user, pass}} in your :mailglass config"
                }
              )
    end
  end

  defp verify_basic_auth!(headers, user, pass) do
    case List.keyfind(headers, "authorization", 0) do
      nil ->
        raise SignatureError.new(:missing_header, provider: :postmark)

      {"authorization", "Basic " <> b64} ->
        case Base.decode64(b64) do
          {:ok, decoded} ->
            case String.split(decoded, ":", parts: 2) do
              [decoded_user, decoded_pass] ->
                if Plug.Crypto.secure_compare(decoded_user, user) and
                     Plug.Crypto.secure_compare(decoded_pass, pass) do
                  :ok
                else
                  raise SignatureError.new(:bad_credentials, provider: :postmark)
                end

              _ ->
                raise SignatureError.new(:malformed_header, provider: :postmark)
            end

          :error ->
            raise SignatureError.new(:malformed_header, provider: :postmark)
        end

      {"authorization", _other} ->
        raise SignatureError.new(:malformed_header, provider: :postmark)
    end
  end

  defp verify_ip_allowlist!(config) do
    case Map.get(config, :ip_allowlist, []) do
      [] ->
        :ok

      cidrs when is_list(cidrs) ->
        case Map.get(config, :remote_ip) do
          nil ->
            # Allowlist configured but Plug failed to forward remote_ip;
            # surface as :malformed_header so adopters notice the wiring
            # gap instead of silent pass-through.
            raise SignatureError.new(:malformed_header,
                    provider: :postmark,
                    context: %{
                      detail: "ip_allowlist configured but remote_ip not forwarded by plug"
                    }
                  )

          remote_ip when is_tuple(remote_ip) ->
            if Enum.any?(cidrs, &cidr_match?(remote_ip, &1)) do
              :ok
            else
              raise SignatureError.new(:ip_disallowed, provider: :postmark)
            end
        end
    end
  end

  # CIDR match using `:inet` helpers — no new dep. Format: "1.2.3.0/24"
  # or single-address "1.2.3.4". IPv4-only at v0.1; v0.5 may extend to
  # IPv6 (Claude's Discretion per plan's design space).
  defp cidr_match?(remote_ip, cidr) do
    case String.split(cidr, "/", parts: 2) do
      [single] ->
        case :inet.parse_address(String.to_charlist(single)) do
          {:ok, parsed} -> remote_ip == parsed
          _ -> false
        end

      [base, mask] ->
        with {:ok, base_ip} <- :inet.parse_address(String.to_charlist(base)),
             {mask_int, ""} <- Integer.parse(mask),
             true <- ip_in_cidr?(remote_ip, base_ip, mask_int) do
          true
        else
          _ -> false
        end
    end
  end

  defp ip_in_cidr?({a1, a2, a3, a4}, {b1, b2, b3, b4}, mask)
       when mask >= 0 and mask <= 32 do
    a = (a1 <<< 24) + (a2 <<< 16) + (a3 <<< 8) + a4
    b = (b1 <<< 24) + (b2 <<< 16) + (b3 <<< 8) + b4
    shift = 32 - mask
    bsr(a, shift) == bsr(b, shift)
  end

  defp ip_in_cidr?(_, _, _), do: false

  # ---- normalize/2 ---------------------------------------------------

  @impl Mailglass.Webhook.Provider
  @spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
  def normalize(raw_body, _headers) when is_binary(raw_body) do
    # Postmark sends ONE event per webhook (unlike SendGrid batches).
    # Raw is a JSON object; decode then map.
    case Jason.decode(raw_body) do
      {:ok, payload} when is_map(payload) ->
        [build_event(payload)]

      _ ->
        # Malformed JSON shouldn't reach `normalize/2` (Plug.Parsers
        # parses upstream), but if it does, emit nothing + audit trail.
        Logger.warning("[mailglass] Postmark normalize: malformed JSON body")
        []
    end
  end

  defp build_event(payload) do
    {type, reject_reason} = map_record_type(payload)
    provider_event_id = extract_event_id(payload)

    %Event{
      type: type,
      reject_reason: reject_reason,
      # STRING keys per revision W9 — Ecto stores metadata as JSONB;
      # JSONB returns string keys on read; normalizing on write prevents
      # atom-vs-string drift downstream. Plan 04's Ingest layer reads
      # `metadata["provider"]` + `metadata["provider_event_id"]` to
      # populate the `mailglass_webhook_events` row's UNIQUE columns.
      metadata: %{
        "provider" => "postmark",
        "provider_event_id" => provider_event_id,
        "record_type" => payload["RecordType"],
        "message_id" => payload["MessageID"] || to_string_or_nil(payload["ID"])
      }
    }
  end

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(v), do: to_string(v)

  # Per Postmark webhook docs:
  #   https://postmarkapp.com/developer/webhooks/bounce-webhook
  #   https://postmarkapp.com/developer/webhooks/delivery-webhook
  #   https://postmarkapp.com/developer/webhooks/spam-complaint-webhook
  #   https://postmarkapp.com/developer/webhooks/open-tracking-webhook
  #   https://postmarkapp.com/developer/webhooks/click-tracking-webhook
  #   https://postmarkapp.com/developer/webhooks/subscription-change-webhook
  defp map_record_type(%{"RecordType" => "Delivery"}), do: {:delivered, nil}

  defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 1}),
    do: {:bounced, :bounced}

  defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 2}),
    do: {:deferred, nil}

  defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 16}),
    do: {:bounced, :invalid}

  defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 24}),
    do: {:rejected, :spam}

  defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 32}),
    do: {:deferred, nil}

  defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 64}),
    do: {:rejected, :blocked}

  defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => other_code}) do
    Logger.warning("[mailglass] Unmapped Postmark Bounce TypeCode: #{inspect(other_code)}")
    {:bounced, :other}
  end

  defp map_record_type(%{"RecordType" => "SpamComplaint"}), do: {:complained, nil}
  defp map_record_type(%{"RecordType" => "Open"}), do: {:opened, nil}
  defp map_record_type(%{"RecordType" => "Click"}), do: {:clicked, nil}

  defp map_record_type(%{"RecordType" => "SubscriptionChange", "SuppressSending" => true}),
    do: {:unsubscribed, nil}

  defp map_record_type(%{"RecordType" => "SubscriptionChange", "SuppressSending" => false}),
    do: {:subscribed, nil}

  defp map_record_type(%{"RecordType" => other}) do
    Logger.warning("[mailglass] Unmapped Postmark RecordType: #{inspect(other)}")
    {:unknown, nil}
  end

  defp map_record_type(_), do: {:unknown, nil}

  # Postmark uses different ID fields per RecordType:
  #   - Bounce: "ID" (numeric)
  #   - SpamComplaint: "ID" (numeric) + "MessageID"
  #   - Delivery/Open/Click: "MessageID" + ServerID + ReceivedAt
  # We construct a synthetic per-event ID combining RecordType +
  # (ID or MessageID) + first-available timestamp so replays of the
  # same event at the same MessageID for the same RecordType collapse
  # to the UNIQUE `(provider, provider_event_id)` index in V02.
  defp extract_event_id(payload) do
    record_type = payload["RecordType"] || "Unknown"

    id_part =
      cond do
        id = payload["ID"] -> to_string(id)
        msg_id = payload["MessageID"] -> msg_id
        true -> ""
      end

    ts_part =
      payload["DeliveredAt"] || payload["BouncedAt"] || payload["ReceivedAt"] ||
        payload["ChangedAt"] || ""

    "#{record_type}:#{id_part}:#{ts_part}"
  end
end
