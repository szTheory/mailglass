defmodule Mailglass.Webhook.Providers.SendGrid do
  @moduledoc """
  SendGrid Event Webhook verifier + normalizer.

  Verifier: ECDSA P-256 (prime256v1 / secp256r1) signature over
  `timestamp <> raw_body` per the SendGrid Event Webhook security
  docs. Public key is supplied as base64-encoded SubjectPublicKeyInfo
  DER (NOT PEM — Pitfall 1; the SendGrid dashboard ships DER without
  `-----BEGIN PUBLIC KEY-----` framing).

  The verifier pattern-matches strictly on `true` from
  `:public_key.verify/4`. `false`, `{:error, _}`, and DER-decode
  exceptions all collapse to `%SignatureError{type: :bad_signature}`
  per CONTEXT D-03 (closes the "wrong algo silently returns false"
  footgun).

  Replay protection: `300`-second timestamp tolerance window
  (Stripe / Svix / Standard Webhooks consensus; SendGrid does not
  document one). Configurable via
  `config :mailglass, :sendgrid, timestamp_tolerance_seconds: N`.

  ## Provider identity lives in `Event.metadata`

  The `%Mailglass.Events.Event{}` struct has no `:provider` column
  (per V02 schema — provider identity lives on `mailglass_webhook_events`).
  This module stashes `"event"` + `"sg_message_id"` in `Event.metadata`
  with STRING keys (revision W9; JSONB roundtrip safety). Plan 06's
  Ingest Multi reads these metadata keys to populate the
  `mailglass_webhook_events` row's UNIQUE columns.

  Normalizer: decodes the JSON array of events (1..128 per request);
  maps each event string to the Anymail taxonomy verbatim. Unmapped
  strings fall through to `:unknown` with `Logger.warning` per D-05.
  """

  @behaviour Mailglass.Webhook.Provider

  require Logger

  alias Mailglass.{Clock, ConfigError, SignatureError}
  alias Mailglass.Events.Event

  @sig_header "x-twilio-email-event-webhook-signature"
  @ts_header "x-twilio-email-event-webhook-timestamp"
  @default_tolerance_seconds 300

  # ---- verify!/3 -----------------------------------------------------

  @impl Mailglass.Webhook.Provider
  @spec verify!(binary(), [{String.t(), String.t()}], map()) :: :ok
  def verify!(raw_body, headers, %{} = config)
      when is_binary(raw_body) and is_list(headers) do
    public_key_b64 = fetch_public_key!(config)
    tolerance = Map.get(config, :timestamp_tolerance_seconds, @default_tolerance_seconds)

    with {:ok, sig_b64} <- fetch_header(headers, @sig_header),
         {:ok, ts_str} <- fetch_header(headers, @ts_header),
         :ok <- check_tolerance(ts_str, tolerance) do
      verify_ecdsa!(raw_body, sig_b64, ts_str, public_key_b64)
      :ok
    else
      {:error, :missing_header} ->
        raise SignatureError.new(:missing_header, provider: :sendgrid)

      {:error, :timestamp_skew} ->
        raise SignatureError.new(:timestamp_skew, provider: :sendgrid)

      {:error, :malformed_timestamp} ->
        raise SignatureError.new(:malformed_header,
                provider: :sendgrid,
                context: %{detail: "timestamp header is not a Unix integer"}
              )
    end
  end

  defp fetch_public_key!(config) do
    case Map.get(config, :public_key) do
      pk when is_binary(pk) and byte_size(pk) > 0 ->
        pk

      _ ->
        raise ConfigError.new(:webhook_verification_key_missing,
                context: %{
                  provider: :sendgrid,
                  hint:
                    "configure {:sendgrid, public_key: \"<base64-DER>\"} in your :mailglass config"
                }
              )
    end
  end

  defp fetch_header(headers, name) do
    case List.keyfind(headers, name, 0) do
      {^name, value} when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :missing_header}
    end
  end

  defp check_tolerance(ts_str, tolerance) do
    # Pitfall 9: SendGrid sends timestamp as a Unix-epoch string.
    # `DateTime.diff/2` needs `%DateTime{}` on both sides — parse the
    # string to integer, convert via `DateTime.from_unix!/1`, then
    # compare against `Mailglass.Clock.utc_now/0` (NOT `DateTime.utc_now/0`
    # per LINT-12 discipline and so test-time freezing works).
    with {ts_int, ""} <- Integer.parse(ts_str),
         {:ok, sent_at} <- DateTime.from_unix(ts_int, :second) do
      diff = abs(DateTime.diff(Clock.utc_now(), sent_at, :second))
      if diff <= tolerance, do: :ok, else: {:error, :timestamp_skew}
    else
      _ -> {:error, :malformed_timestamp}
    end
  end

  # ECDSA verify per RESEARCH §Pattern 2 + CONTEXT D-03.
  # Uses OTP 27 `:public_key.der_decode/2` (NOT `:pem_decode/1` — the
  # SendGrid dashboard ships raw DER without PEM framing; see Pitfall 1).
  defp verify_ecdsa!(raw_body, sig_b64, timestamp, public_key_b64) do
    try do
      decoded = Base.decode64!(public_key_b64)

      {:SubjectPublicKeyInfo, alg_id, pk_bits} =
        :public_key.der_decode(:SubjectPublicKeyInfo, decoded)

      {:AlgorithmIdentifier, _oid, ec_params_der} = alg_id
      ecc_params = :public_key.der_decode(:EcpkParameters, ec_params_der)
      pk = {{:ECPoint, pk_bits}, ecc_params}

      signed_payload = timestamp <> raw_body
      sig = Base.decode64!(sig_b64)

      case :public_key.verify(signed_payload, :sha256, sig, pk) do
        true ->
          :ok

        false ->
          raise SignatureError.new(:bad_signature, provider: :sendgrid)
      end
    rescue
      # Pattern-match-strictly discipline per CONTEXT D-03 — collapse
      # every DER/ASN.1/EC failure mode to either `:bad_signature`
      # (wrong-signature-for-right-shape key) or `:malformed_key` (the
      # supplied public_key blob is not a valid base64 SPKI DER).
      #
      # The SignatureError re-raise is caught here but re-raised below;
      # we must preserve its original atom (`:bad_signature` from the
      # `false` branch of the case above).
      e in [ArgumentError, MatchError, FunctionClauseError, ErlangError] ->
        type = classify_rescue(e)
        reraise SignatureError.new(type, provider: :sendgrid, cause: e), __STACKTRACE__
    end
  end

  # Heuristic: a `Base.decode64!/1` ArgumentError on the PUBLIC KEY blob
  # means the configured key itself is malformed — surface as `:malformed_key`
  # so adopters see the distinction between "bad key" and "bad signature".
  # Any other rescue (MatchError from DER-decode, FunctionClauseError from
  # EC math, bad-base64 on the signature itself) collapses to `:bad_signature`.
  defp classify_rescue(%ArgumentError{message: msg}) when is_binary(msg) do
    if msg =~ ~r/non-alphabet/i or msg =~ ~r/invalid base64/i or msg =~ ~r/base64/i do
      # This catches bad-base64 on either the public key or the signature;
      # we cannot tell them apart from the message alone. `:malformed_key`
      # is the safer disclosure (never leaks "your signature was wrong").
      :malformed_key
    else
      :bad_signature
    end
  end

  defp classify_rescue(_), do: :bad_signature

  # ---- normalize/2 ---------------------------------------------------

  @impl Mailglass.Webhook.Provider
  @spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
  def normalize(raw_body, _headers) when is_binary(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, events} when is_list(events) ->
        events
        |> Enum.with_index()
        |> Enum.map(fn {payload, idx} -> build_event(payload, idx) end)

      {:ok, _other} ->
        Logger.warning("[mailglass] SendGrid normalize: expected JSON array, got non-list")
        []

      {:error, _} ->
        Logger.warning("[mailglass] SendGrid normalize: malformed JSON body")
        []
    end
  end

  defp build_event(payload, idx) when is_map(payload) do
    {type, reject_reason} = map_event(payload)
    provider_event_id = extract_event_id(payload, idx)

    %Event{
      type: type,
      reject_reason: reject_reason,
      # STRING keys per revision W9 — Ecto stores metadata as JSONB;
      # JSONB returns string keys on read; normalizing on write prevents
      # atom-vs-string drift downstream. Plan 06's Ingest reads
      # `metadata["provider"]` + `metadata["provider_event_id"]` to
      # populate the `mailglass_webhook_events` row's UNIQUE columns.
      metadata: %{
        "provider" => "sendgrid",
        "provider_event_id" => provider_event_id,
        "event" => payload["event"],
        "sg_message_id" => payload["sg_message_id"]
      }
    }
  end

  defp build_event(_other, idx) do
    # Non-map element inside the events array — emit `:unknown` with a
    # synthetic id so downstream uniqueness still holds.
    Logger.warning("[mailglass] SendGrid normalize: non-map event at index #{idx}")

    %Event{
      type: :unknown,
      reject_reason: nil,
      metadata: %{
        "provider" => "sendgrid",
        "provider_event_id" => "sendgrid_invalid_element:#{idx}",
        "event" => nil,
        "sg_message_id" => nil
      }
    }
  end

  # Per SendGrid Event Webhook docs:
  #   https://www.twilio.com/docs/sendgrid/for-developers/tracking-events/event
  #
  # Anymail taxonomy verbatim per PROJECT D-14 / CONTEXT D-05. Unmapped
  # strings fall through to `:unknown` with `Logger.warning` — never
  # silent `_ -> :hard_bounce` catch-all.
  defp map_event(%{"event" => "processed"}), do: {:queued, nil}
  defp map_event(%{"event" => "deferred"}), do: {:deferred, nil}
  defp map_event(%{"event" => "delivered"}), do: {:delivered, nil}
  defp map_event(%{"event" => "open"}), do: {:opened, nil}
  defp map_event(%{"event" => "click"}), do: {:clicked, nil}

  # Bounce variants: Anymail `:bounced` with per-type reject_reason.
  defp map_event(%{"event" => "bounce", "type" => "bounce"}), do: {:bounced, :bounced}
  defp map_event(%{"event" => "bounce", "type" => "blocked"}), do: {:bounced, :blocked}
  defp map_event(%{"event" => "bounce", "type" => "expired"}), do: {:bounced, :timed_out}

  defp map_event(%{"event" => "bounce"} = p) do
    Logger.warning("[mailglass] Unmapped SendGrid bounce type: #{inspect(p["type"])}")
    {:bounced, :other}
  end

  # Dropped → Anymail `:rejected` with reject_reason derived from the
  # documented `reason` strings (SendGrid's closed-ish set; new strings
  # fall through to `:other`).
  defp map_event(%{"event" => "dropped"} = p) do
    reason =
      case p["reason"] do
        "Bounced Address" -> :bounced
        "Spam Reporting Address" -> :spam
        "Invalid SMTPAPI header" -> :invalid
        "Spam Content (if spam checker app enabled)" -> :spam
        "Unsubscribed Address" -> :unsubscribed
        nil -> :other
        _ -> :other
      end

    {:rejected, reason}
  end

  defp map_event(%{"event" => "spamreport"}), do: {:complained, nil}
  defp map_event(%{"event" => "unsubscribe"}), do: {:unsubscribed, nil}
  defp map_event(%{"event" => "group_unsubscribe"}), do: {:unsubscribed, nil}
  defp map_event(%{"event" => "group_resubscribe"}), do: {:subscribed, nil}

  defp map_event(%{"event" => other}) do
    Logger.warning("[mailglass] Unmapped SendGrid event: #{inspect(other)}")
    {:unknown, nil}
  end

  defp map_event(_), do: {:unknown, nil}

  # SendGrid provides `sg_event_id` (canonical). Fallback chain ensures
  # uniqueness within a single batch even if the provider omits it
  # (defensive — should not happen in practice, but V02's
  # UNIQUE(provider, provider_event_id) constraint must never silently
  # collide on bad provider data).
  defp extract_event_id(payload, idx) do
    cond do
      id = payload["sg_event_id"] -> id
      id = payload["smtp-id"] -> "#{id}:#{idx}"
      id = payload["sg_message_id"] -> "#{id}:#{idx}"
      true -> "sendgrid_unknown_id:#{idx}"
    end
  end
end
