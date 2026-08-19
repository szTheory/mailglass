defmodule MailglassInbound.Ingress.Providers.Mailgun do
  @moduledoc false

  @behaviour MailglassInbound.Ingress.Provider

  alias Mailglass.{Clock, ConfigError}
  alias Mailglass.Webhook.Providers.MailgunReplayCache
  alias MailglassInbound.{InboundMessage, MIME, MIMEError, SignatureError}
  alias MailglassInbound.Ingress.Request

  @default_tolerance_seconds 300
  @default_future_skew_seconds 60
  @default_replay_cache_ttl_seconds 28_800

  # ---------------------------------------------------------------------------
  # verify! — flat-field HMAC over `timestamp <> token` (the design contract).
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
      # Replay is a 200 no-op handled by the plug (the design contract) — NEVER raise/401.
      {:error, :replay} -> {:replay}
    end
  end

  # ---------------------------------------------------------------------------
  # normalize/1 — two modes (the design contract).
  #
  # Branch on presence of `params["body-mime"]` (RESEARCH Open Question 3 rec —
  # branch on the payload field, more robust than parsing the URL suffix):
  #
  #   * RAW-MIME mode (`body-mime` present): route through
  #     `MailglassInbound.MIME.parse/1` (never raises). On a MIME error, record a
  #     parse warning and fall back to whatever flat fields exist.
  #   * PARSED mode (default): normalize from `body-plain`/`body-html`/
  #     `stripped-*` + `message-headers` + Mailgun address fields.
  #
  # Provider-specific data goes in the evidence map; the public
  # `%InboundMessage{}` struct is NOT widened for Mailgun quirks.
  #
  # normalize/2 is the legacy compatibility shim required by the
  # `MailglassInbound.Ingress.Provider` behaviour (mirrors `sendgrid.ex:64-67`);
  # the plug dispatches Mailgun through the struct-arity normalize/1.
  # ---------------------------------------------------------------------------
  @impl false
  def normalize(%Request{} = request) do
    params = request.params || %{}

    case params["body-mime"] do
      raw when is_binary(raw) and raw != "" -> normalize_raw_mime(request, params, raw)
      _ -> normalize_parsed(request, params)
    end
  end

  @impl MailglassInbound.Ingress.Provider
  def normalize(raw_body, headers) when is_binary(raw_body) and is_list(headers) do
    normalize(%Request{
      provider: :mailgun,
      raw_mime: raw_body,
      headers: headers,
      params: %{"body-mime" => raw_body}
    })
  end

  # PARSED mode: build the canonical message from Mailgun's flat parsed fields.
  defp normalize_parsed(request, params) do
    normalized_headers = headers_from_message_headers(params["message-headers"])
    provider_message_id = extract_message_id(params)
    {attachments, attachment_blobs} = extract_attachments(params)

    message = %InboundMessage{
      provider: :mailgun,
      provider_message_id: provider_message_id,
      message_id: provider_message_id || first_header(normalized_headers, "message-id"),
      envelope_recipient: envelope_recipient(params),
      from: normalize_address_header(params["from"] || first_header(normalized_headers, "from")),
      to: normalize_address_header(params["to"] || first_header(normalized_headers, "to")),
      cc: normalize_address_header(params["cc"] || first_header(normalized_headers, "cc")),
      bcc: normalize_address_header(params["bcc"] || first_header(normalized_headers, "bcc")),
      reply_to:
        normalize_address_header(params["reply-to"] || first_header(normalized_headers, "reply-to")),
      subject: params["subject"] || first_header(normalized_headers, "subject"),
      headers: normalized_headers,
      sent_at: parse_datetime(first_header(normalized_headers, "date")),
      received_at: DateTime.utc_now(),
      text_body: params["body-plain"] || params["stripped-text"],
      html_body: params["body-html"] || params["stripped-html"],
      attachments: attachments
    }

    %{
      message: message,
      evidence: %{
        raw_payload: params,
        raw_headers: select_safe_headers(request.headers),
        raw_mime: nil,
        verification_facts: %{},
        parse_warnings: parse_warnings(message, %{}),
        attachment_blobs: attachment_blobs
      }
    }
  end

  # RAW-MIME mode: route body-mime through the never-raising Phase-45 MIME parser.
  defp normalize_raw_mime(request, params, raw) do
    {normalized_headers, text_body, html_body, attachments, attachment_blobs, mime_warning} =
      case MIME.parse(raw) do
        {:ok, repr} ->
          headers = normalize_headers(proplist_to_pairs(repr.headers))
          {text, html} = extract_bodies(repr)
          {attach, blobs} = extract_mime_attachments(repr)
          {headers, text, html, attach, blobs, %{}}

        {:error, %MIMEError{} = error} ->
          # Never raise — fall back to flat fields, record the parse warning.
          {%{}, params["body-plain"] || params["stripped-text"],
           params["body-html"] || params["stripped-html"], [], %{},
           %{mime_parse_failed: Atom.to_string(error.type)}}
      end

    provider_message_id =
      first_header(normalized_headers, "message-id") || extract_message_id(params)

    message = %InboundMessage{
      provider: :mailgun,
      provider_message_id: provider_message_id,
      message_id: provider_message_id,
      envelope_recipient: envelope_recipient(params),
      from: normalize_address_header(first_header(normalized_headers, "from")),
      to: normalize_address_header(first_header(normalized_headers, "to")),
      cc: normalize_address_header(first_header(normalized_headers, "cc")),
      bcc: normalize_address_header(first_header(normalized_headers, "bcc")),
      reply_to: normalize_address_header(first_header(normalized_headers, "reply-to")),
      subject: first_header(normalized_headers, "subject"),
      headers: normalized_headers,
      sent_at: parse_datetime(first_header(normalized_headers, "date")),
      received_at: DateTime.utc_now(),
      text_body: text_body,
      html_body: html_body,
      attachments: attachments
    }

    %{
      message: message,
      evidence: %{
        raw_payload: Map.delete(params, "body-mime"),
        raw_headers: select_safe_headers(request.headers),
        raw_mime: raw,
        verification_facts: %{},
        parse_warnings: parse_warnings(message, mime_warning),
        attachment_blobs: attachment_blobs
      }
    }
  end

  # gen_smtp returns the MIME repr's :body as decoded bytes already; for the
  # text/html bodies we take the first matching leaf part.
  defp extract_bodies(repr) do
    text =
      Enum.find_value(repr.parts, fn part ->
        if part.type == "text" and part.subtype == "plain", do: to_string(part.body)
      end)

    html =
      Enum.find_value(repr.parts, fn part ->
        if part.type == "text" and part.subtype == "html", do: to_string(part.body)
      end)

    {text, html}
  end

  defp extract_mime_attachments(repr) do
    repr.attachments
    |> Enum.with_index(1)
    |> Enum.reduce({[], %{}}, fn {part, index}, {attachments, blobs} ->
      filename = Map.get(part, :filename)

      attachment =
        %{
          filename: filename,
          content_type: "#{part.type}/#{part.subtype}",
          disposition: :attachment
        }
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()

      blob_key = "#{index}:#{filename || "attachment"}"
      {attachments ++ [attachment], Map.put(blobs, blob_key, to_string(part.body))}
    end)
  end

  # Mailgun parsed-mode attachments arrive as flat `attachment-N` form fields
  # alongside `attachment-count` and per-attachment `-filename`/`-content-type`.
  defp extract_attachments(params) do
    count =
      case Integer.parse(to_string(params["attachment-count"] || "0")) do
        {n, _} -> n
        :error -> 0
      end

    1..count//1
    |> Enum.reduce({[], %{}}, fn index, {attachments, blobs} ->
      case params["attachment-#{index}"] do
        bytes when is_binary(bytes) ->
          filename = params["attachment-#{index}-filename"]
          content_type = params["attachment-#{index}-content-type"]

          attachment =
            %{filename: filename, content_type: content_type}
            |> Enum.reject(fn {_k, v} -> is_nil(v) end)
            |> Map.new()

          blob_key = "#{index}:#{filename || "attachment"}"
          {attachments ++ [attachment], Map.put(blobs, blob_key, bytes)}

        _ ->
          {attachments, blobs}
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Message-Id extraction (the design contract).
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

  # ---------------------------------------------------------------------------
  # Header + RFC-5322 helpers.
  #
  # The address/datetime/header helpers below are RFC-5322-shaped and mirror the
  # SendGrid provider's private helpers (`sendgrid.ex:157,164,307,316,333`).
  # They are pure and copy cleanly per the phase pattern map; duplicating them
  # here keeps the provider self-contained without widening a shared module.
  # ---------------------------------------------------------------------------

  # Mailgun `message-headers` is a JSON-encoded ordered `[name, value]` pairs
  # list. Decode it into the normalized header map shape used everywhere else.
  defp headers_from_message_headers(raw) when is_binary(raw) do
    case Jason.decode(raw) do
      {:ok, pairs} when is_list(pairs) ->
        pairs
        |> Enum.flat_map(fn
          [name, value] when is_binary(name) -> [{String.downcase(name), to_string(value)}]
          _ -> []
        end)
        |> normalize_headers()

      _ ->
        %{}
    end
  end

  defp headers_from_message_headers(_other), do: %{}

  defp proplist_to_pairs(headers) when is_list(headers) do
    Enum.flat_map(headers, fn
      {name, value} when is_binary(name) -> [{String.downcase(name), to_string(value)}]
      _ -> []
    end)
  end

  defp proplist_to_pairs(_other), do: []

  defp normalize_headers(headers) do
    headers
    |> Enum.reduce(%{}, fn {name, value}, acc ->
      Map.update(acc, name, [value], &[value | &1])
    end)
    |> Map.new(fn {name, values} -> {name, Enum.reverse(values)} end)
  end

  defp first_header(headers, name) do
    headers
    |> Map.get(name, [])
    |> List.first()
  end

  defp envelope_recipient(params) do
    case params["recipient"] do
      recipient when is_binary(recipient) and recipient != "" -> recipient
      _ -> nil
    end
  end

  defp normalize_address_header(nil), do: []

  defp normalize_address_header(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&parse_address/1)
    |> Enum.reject(&(Map.get(&1, :address) in [nil, ""]))
  end

  defp parse_address(value) do
    trimmed = String.trim(value)

    case Regex.run(~r/^(.*)<([^>]+)>$/, trimmed) do
      [_, name, address] ->
        %{
          address: String.trim(address),
          name: name |> String.trim() |> String.trim("\"")
        }
        |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
        |> Map.new()

      _ ->
        %{address: trimmed}
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) do
    with [_, day, month, year, hour, minute, second, offset] <-
           Regex.run(
             ~r/^(?:[A-Za-z]{3},\s+)?(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s+([+-]\d{4})$/,
             value
           ),
         {month_int, true} <- {month_number(month), true},
         {day_int, ""} <- Integer.parse(day),
         {year_int, ""} <- Integer.parse(year),
         {hour_int, ""} <- Integer.parse(hour),
         {minute_int, ""} <- Integer.parse(minute),
         {second_int, ""} <- Integer.parse(second),
         {:ok, naive} <-
           NaiveDateTime.new(year_int, month_int, day_int, hour_int, minute_int, second_int) do
      offset_seconds = utc_offset_seconds(offset)
      naive |> NaiveDateTime.add(-offset_seconds, :second) |> DateTime.from_naive!("Etc/UTC")
    else
      _ -> nil
    end
  end

  defp month_number("Jan"), do: 1
  defp month_number("Feb"), do: 2
  defp month_number("Mar"), do: 3
  defp month_number("Apr"), do: 4
  defp month_number("May"), do: 5
  defp month_number("Jun"), do: 6
  defp month_number("Jul"), do: 7
  defp month_number("Aug"), do: 8
  defp month_number("Sep"), do: 9
  defp month_number("Oct"), do: 10
  defp month_number("Nov"), do: 11
  defp month_number("Dec"), do: 12
  defp month_number(_), do: nil

  defp utc_offset_seconds(<<sign::binary-size(1), hours::binary-size(2), minutes::binary-size(2)>>) do
    {hour_int, ""} = Integer.parse(hours)
    {minute_int, ""} = Integer.parse(minutes)
    seconds = hour_int * 3600 + minute_int * 60
    if sign == "-", do: -seconds, else: seconds
  end

  defp parse_warnings(message, base) do
    base
    |> maybe_put_warning(:missing_envelope_recipient, is_nil(message.envelope_recipient))
    |> maybe_put_warning(:missing_message_id_header, is_nil(message.message_id))
  end

  defp maybe_put_warning(warnings, _key, false), do: warnings
  defp maybe_put_warning(warnings, key, true), do: Map.put(warnings, key, true)

  defp select_safe_headers(headers) when is_list(headers) do
    headers
    |> Enum.reject(fn {name, _value} -> String.downcase(name) == "authorization" end)
    |> Enum.reduce(%{}, fn {name, value}, acc ->
      Map.update(acc, String.downcase(name), [value], &[value | &1])
    end)
    |> Map.new(fn {name, values} -> {name, Enum.reverse(values)} end)
  end

  defp select_safe_headers(_other), do: %{}
end
