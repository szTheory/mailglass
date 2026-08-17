defmodule MailglassInbound.Ingress.Providers.SES do
  @moduledoc false

  # SES inbound provider. Reuses core's byte-identical SNS X.509 verification
  # seam, drives its own three-way MessageType dispatch, and extracts the raw
  # MIME body from the receipt-rule S3 action (primary) or the SNS-inline
  # `content` field (secondary). Mirrors the SendGrid provider's
  # verify!/normalize struct shape (the design contract).
  #
  # ## Verify / normalize handoff
  #
  # Authentication returns an explicit private value. Content retrieval and
  # normalization consume that same value; no request state is stored in the
  # process dictionary and no fallback can refetch untrusted material.
  #
  # ## Trust reuse (do NOT re-supervise — the design contract)
  #
  #   * `Mailglass.Webhook.Providers.SES.verify_envelope!/2` — the SNS X.509
  #     crypto seam (decode → TrustPolicy.valid_cert_url? → CertCache public-key
  #     fetch → canonical-string → :public_key.verify). Raises core
  #     `Mailglass.SignatureError` on forgery; we re-raise as the package-local
  #     `MailglassInbound.SignatureError` so the plug's dual rescue maps it to 401
  #     (the design contract, SESI-01).
  #   * `TrustPolicy.valid_subscribe_url?/1` — SSRF/hijack guard for the
  #     control-plane SubscribeURL (T-46-22).
  #
  # ## Out of scope (documented, the design contract)
  #
  # SES client-side KMS-encrypted objects are NOT decrypted: a `GetObject`
  # returns ciphertext that an Elixir gateway cannot transparently decrypt.
  # Adopters use bucket-level SSE instead (this milestone phase setup doc). Ciphertext simply
  # parses as a degraded record, never a crash (MIME.parse/1 never raises).

  @behaviour MailglassInbound.Ingress.Provider

  alias MailglassInbound.{InboundMessage, S3FetchError, S3Fetcher, SignatureError}
  alias MailglassInbound.Ingress.{Request, VerifiedRequest}
  alias Mailglass.Webhook.Providers.SES, as: CoreSES
  alias Mailglass.Webhook.Providers.SES.TrustPolicy

  @impl MailglassInbound.Ingress.Provider
  def verify!(%Request{raw_body: raw_body} = request, %{} = config) when is_binary(raw_body) do
    payload = verify_envelope!(raw_body, config)

    case Map.get(payload, "Type") do
      "Notification" ->
        {:ok,
         %VerifiedRequest{
           request: request,
           raw_body: raw_body,
           envelope: payload,
           verification_facts: %{auth: :sns_x509},
           warnings: %{}
         }}

      type when type in ["SubscriptionConfirmation", "UnsubscribeConfirmation"] ->
        confirm_control_plane!(payload)
        {:control_plane, 200}

      other ->
        raise SignatureError.new(:malformed_header,
                provider: :ses,
                context: %{detail: "unknown SNS MessageType: #{inspect(other)}"}
              )
    end
  end

  @impl MailglassInbound.Ingress.Provider
  def resolve_content!(%VerifiedRequest{raw_mime: raw_mime} = verified, _config)
      when is_binary(raw_mime),
      do: verified

  @impl MailglassInbound.Ingress.Provider
  def resolve_content!(%VerifiedRequest{} = verified, config) do
    {raw_mime, warnings} = extract_raw_mime!(verified.envelope, config)
    %{verified | raw_mime: raw_mime, warnings: Map.merge(verified.warnings, warnings)}
  end

  # The canonical normalization entry consumes a resolved verified value.
  @impl false
  def normalize(
        %VerifiedRequest{request: request, envelope: payload, raw_mime: raw_mime} = verified
      )
      when is_binary(raw_mime) do
    repr =
      case MailglassInbound.MIME.parse(raw_mime) do
        {:ok, repr} -> repr
        # MIME.parse/1 never raises; a degraded body yields a record with empty
        # normalized fields (the raw bytes still land in evidence).
        {:error, _mime_error} -> %{headers: [], parts: [], attachments: [], inline: []}
      end

    headers = normalize_headers(repr.headers)
    {text_body, html_body, attachments, attachment_blobs} = extract_parts(repr)

    message = %InboundMessage{
      provider: :ses,
      provider_message_id: ses_message_id(payload),
      message_id: first_header(headers, "message-id"),
      envelope_recipient: nil,
      from: normalize_address_header(first_header(headers, "from")),
      to: normalize_address_header(first_header(headers, "to")),
      cc: normalize_address_header(first_header(headers, "cc")),
      bcc: normalize_address_header(first_header(headers, "bcc")),
      reply_to: normalize_address_header(first_header(headers, "reply-to")),
      subject: first_header(headers, "subject"),
      headers: headers,
      sent_at: parse_datetime(first_header(headers, "date")),
      received_at: DateTime.utc_now(),
      text_body: text_body,
      html_body: html_body,
      attachments: attachments
    }

    %{
      message: message,
      evidence: %{
        raw_payload: payload,
        raw_headers: select_safe_headers(request.headers),
        raw_mime: raw_mime,
        verification_facts: %{},
        parse_warnings: Map.merge(parse_warnings(message), verified.warnings),
        attachment_blobs: attachment_blobs
      }
    }
  end

  # Legacy `normalize/2` arity required by the behaviour. SES never uses it in the
  # plug path (the plug calls the struct arity), but the behaviour declares it
  # required, so this compatibility shim wraps the raw body into a Request and
  # delegates — mirroring SendGrid's `normalize/2` shim.
  @impl MailglassInbound.Ingress.Provider
  def normalize(raw_body, headers) when is_binary(raw_body) and is_list(headers) do
    request = %Request{provider: :ses, raw_body: raw_body, headers: headers}

    normalize(%VerifiedRequest{
      request: request,
      raw_body: raw_body,
      envelope: %{},
      verification_facts: %{},
      warnings: %{},
      raw_mime: raw_body
    })
  end

  # ---- verify seam (re-raise as inbound SignatureError) ----------------

  defp verify_envelope!(raw_body, config) do
    case CoreSES.verify_envelope!(raw_body, config) do
      {:ok, payload} -> payload
    end
  rescue
    e in Mailglass.SignatureError ->
      # Re-raise core's forgery/SSRF rejection as the package-local error so the
      # inbound plug's dual rescue maps it to 401 (the design contract). `reraise` with a new
      # exception preserves the original stacktrace (mirrors core SendGrid's
      # rewrap). Map a known :type through; everything else collapses to
      # :bad_signature. The core cause rides on `:cause` (excluded from JSON).
      type =
        if e.type in MailglassInbound.SignatureError.__types__(), do: e.type, else: :bad_signature

      reraise SignatureError.new(type, provider: :ses, cause: e, context: e.context || %{}),
              __STACKTRACE__
  end

  # ---- control-plane (Subscription/Unsubscribe) ------------------------

  # The control plane is a 200 no-op with NO record (the design contract, T-46-23). We do NOT
  # follow SubscribeURL; we validate it against the TrustPolicy host allowlist as
  # an SSRF/hijack guard (T-46-22). A hijacked URL fails closed with
  # :subscribe_url_untrusted. Topic activation (the actual ConfirmSubscription
  # HTTP call) is core's outbound concern; for inbound the control-plane no-op is
  # the deliverable.
  defp confirm_control_plane!(payload) do
    case Map.get(payload, "SubscribeURL") do
      url when is_binary(url) ->
        unless TrustPolicy.valid_subscribe_url?(url) do
          raise SignatureError.new(:subscribe_url_untrusted, provider: :ses)
        end

        :ok

      _ ->
        # UnsubscribeConfirmation may omit SubscribeURL — still a 200 no-op.
        :ok
    end
  end

  # ---- MIME extraction (S3 primary, inline secondary) ------------------

  # Returns `{raw_mime, warnings}` where `warnings` is a map merged into the
  # record's parse_warnings by normalize/1. The S3 path adds no warnings; the
  # inline-content path flags when the ambiguous base64 heuristic was taken
  # (WR-05).
  defp extract_raw_mime!(payload, config) do
    inner = decode_inner_message(payload)
    action_type = get_in(inner, ["receipt", "action", "type"])

    cond do
      action_type == "S3" ->
        bucket = get_in(inner, ["receipt", "action", "bucketName"])

        key =
          get_in(inner, ["receipt", "action", "objectKey"]) || get_in(inner, ["mail", "messageId"])

        {fetch_s3_body!(bucket, key, config), %{}}

      is_binary(Map.get(inner, "content")) ->
        case decode_inline_content(Map.get(inner, "content")) do
          {raw_mime, true} -> {raw_mime, %{inline_content_base64_decoded: true}}
          {raw_mime, false} -> {raw_mime, %{}}
        end

      true ->
        raise %S3FetchError{
          type: :s3_fetch_failed,
          message: "Inbound SES message carries neither an S3 action nor inline content",
          context: %{}
        }
    end
  end

  defp fetch_s3_body!(bucket, key, config) when is_binary(bucket) and is_binary(key) do
    fetcher = s3_fetcher(config)
    retry_opts = Map.get(config, :s3_retry_opts, [])
    max_bytes = s3_max_bytes!(config)

    case S3Fetcher.Retry.head_with_retry(fetcher, bucket, key, retry_opts) do
      {:ok, %{content_length: bytes}}
      when is_integer(bytes) and bytes >= 0 and bytes <= max_bytes ->
        :ok

      {:ok, %{content_length: bytes}} when is_integer(bytes) and bytes > max_bytes ->
        raise_s3_size_error!(max_bytes)

      {:ok, _} ->
        raise_s3_metadata_error!()

      {:error, reason} ->
        raise_s3_fetch_error!(reason)
    end

    {:ok, body} = S3Fetcher.Retry.fetch_with_retry(fetcher, bucket, key, retry_opts)
    if byte_size(body) > max_bytes, do: raise_s3_size_error!(max_bytes)
    body
  end

  defp fetch_s3_body!(_bucket, _key, _config) do
    raise %S3FetchError{
      type: :s3_fetch_failed,
      message: "Inbound SES S3 action is missing bucketName/objectKey",
      context: %{}
    }
  end

  @default_s3_max_bytes 40 * 1024 * 1024

  defp s3_max_bytes!(config) do
    case Map.get(config, :s3_max_bytes, @default_s3_max_bytes) do
      bytes when is_integer(bytes) and bytes > 0 -> bytes
      _ -> raise_s3_metadata_error!()
    end
  end

  defp raise_s3_size_error!(max_bytes) do
    raise %S3FetchError{
      type: :s3_fetch_failed,
      message: "Inbound SES S3 object exceeds configured byte limit",
      context: %{max_bytes: max_bytes}
    }
  end

  defp raise_s3_metadata_error! do
    raise %S3FetchError{
      type: :s3_fetch_failed,
      message: "Inbound SES S3 object metadata is malformed",
      context: %{}
    }
  end

  defp raise_s3_fetch_error!(reason) do
    raise %S3FetchError{
      type: :s3_fetch_failed,
      message: "Inbound SES S3 metadata retrieval failed",
      cause: reason,
      context: %{}
    }
  end

  # SNS-inline content is UTF-8 or Base64 (≤150 KB). Try Base64 first only when
  # the content is not already valid printable MIME; fall back to raw bytes.
  # Returns `{raw_mime, base64_decoded?}` so normalize/1 can record a
  # parse_warning whenever the base64 branch is taken (WR-05) — the heuristic is
  # inherently ambiguous, so the decision is made auditable.
  defp decode_inline_content(content) do
    case Base.decode64(content) do
      {:ok, decoded} -> if looks_like_mime?(decoded), do: {decoded, true}, else: {content, false}
      :error -> {content, false}
    end
  end

  # WR-05: a `:`-anywhere check is too weak (any "Key: value"-ish text passes,
  # and terse single-line raw MIME that happens to be valid base64 could be
  # mis-decoded). Require a real RFC-5322 header line — `Field-Name:` followed by
  # SP/HTAB — at the very start of the decoded bytes (before the first blank
  # line). This is the deterministic signal a decoded MIME message begins with a
  # header block, not arbitrary text.
  @header_line_regex ~r/\A[A-Za-z][A-Za-z0-9-]*:[ \t]/

  defp looks_like_mime?(bytes) do
    prefix = binary_part(bytes, 0, min(byte_size(bytes), 998))
    String.printable?(prefix) and Regex.match?(@header_line_regex, prefix)
  end

  defp decode_inner_message(payload) do
    case Jason.decode(Map.get(payload, "Message", "")) do
      {:ok, %{} = inner} -> inner
      _ -> %{}
    end
  end

  defp ses_message_id(payload) do
    payload |> decode_inner_message() |> get_in(["mail", "messageId"])
  end

  # ---- config-resolution seam (mirror core ses.ex httpc_client/1) ------

  defp s3_fetcher(config) do
    case Map.get(config, :s3_fetcher) do
      mod when is_atom(mod) and not is_nil(mod) ->
        mod

      _ ->
        :mailglass_inbound
        |> Application.get_env(:ses, [])
        |> Keyword.get(:s3_fetcher, default_fetcher())
    end
  end

  defp default_fetcher do
    if function_exported?(Mix, :env, 0) and Mix.env() == :test do
      S3Fetcher.Fake
    else
      S3Fetcher.ExAwsS3
    end
  end

  # ---- MIME repr → normalized fields -----------------------------------

  defp normalize_headers(repr_headers) do
    Enum.reduce(repr_headers, %{}, fn {name, value}, acc ->
      key = String.downcase(name)
      Map.update(acc, key, [value], &(&1 ++ [value]))
    end)
  end

  defp first_header(headers, name), do: headers |> Map.get(name, []) |> List.first()

  defp extract_parts(repr) do
    leaves = Map.get(repr, :parts, [])

    {text, html} =
      Enum.reduce(leaves, {nil, nil}, fn part, {text, html} ->
        cond do
          part.type == "text" and part.subtype == "plain" and is_nil(text) ->
            {to_text(part.body), html}

          part.type == "text" and part.subtype == "html" and is_nil(html) ->
            {text, to_text(part.body)}

          true ->
            {text, html}
        end
      end)

    {attachments, blobs} = build_attachments(Map.get(repr, :attachments, []))
    {text, html, attachments, blobs}
  end

  defp build_attachments(parts) do
    parts
    |> Enum.with_index(1)
    |> Enum.reduce({[], %{}}, fn {part, idx}, {atts, blobs} ->
      filename = Map.get(part, :filename) || part_filename(part)

      attachment =
        %{
          filename: filename,
          content_type: "#{part.type}/#{part.subtype}",
          disposition: :attachment,
          content_id: nil
        }
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()

      blob_key = "#{idx}:#{filename || "attachment-#{idx}"}"
      {atts ++ [attachment], Map.put(blobs, blob_key, to_text(part.body))}
    end)
  end

  defp part_filename(part) do
    dp = get_in(part, [:params, :disposition_params]) || []
    cp = get_in(part, [:params, :content_type_params]) || []
    find_param(dp, "filename") || find_param(cp, "name")
  end

  defp find_param(list, key) when is_list(list) do
    Enum.find_value(list, fn
      {k, v} -> if String.downcase(to_string(k)) == key, do: v
      _ -> nil
    end)
  end

  defp find_param(_list, _key), do: nil

  defp to_text(body) when is_binary(body), do: body
  defp to_text(body) when is_list(body), do: IO.iodata_to_binary(body)
  defp to_text(_), do: nil

  # ---- address / datetime helpers (RFC-5322, SendGrid-shaped) ----------

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
        %{address: String.trim(address), name: name |> String.trim() |> String.trim("\"")}
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
         month_int when is_integer(month_int) <- month_number(month),
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

  defp parse_warnings(message) do
    %{}
    |> maybe_put_warning(:missing_message_id_header, is_nil(message.message_id))
    # WR-02: SES dedupes primarily on `mail.messageId` (provider_message_id).
    # When it is absent the dedupe falls back to the MD5(raw_mime) fingerprint;
    # flag the missing primary anchor so the weaker fallback path is auditable.
    |> maybe_put_warning(:missing_provider_message_id, is_nil(message.provider_message_id))
  end

  defp maybe_put_warning(warnings, _key, false), do: warnings
  defp maybe_put_warning(warnings, key, true), do: Map.put(warnings, key, true)

  defp select_safe_headers(headers) when is_list(headers) do
    headers
    |> Enum.reject(fn {name, _value} -> String.downcase(name) == "authorization" end)
    |> Enum.reduce(%{}, fn {name, value}, acc ->
      Map.update(acc, String.downcase(name), [value], &(&1 ++ [value]))
    end)
  end

  defp select_safe_headers(_), do: %{}
end
