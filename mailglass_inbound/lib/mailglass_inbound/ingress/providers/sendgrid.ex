defmodule MailglassInbound.Ingress.Providers.Sendgrid do
  @moduledoc false

  @behaviour MailglassInbound.Ingress.Provider

  alias Mailglass.{ConfigError, SignatureError}
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Ingress.Request

  @impl false
  def verify!(%Request{headers: headers}, %{} = config) when is_list(headers) do
    {user, pass} = fetch_basic_auth!(config)
    verify_basic_auth!(headers, user, pass)

    %{auth: :basic_auth}
  end

  @impl MailglassInbound.Ingress.Provider
  def verify!(raw_body, headers, config) when is_binary(raw_body) and is_list(headers) and is_map(config) do
    verify!(%Request{provider: :sendgrid, raw_mime: raw_body, headers: headers}, config)
  end

  @impl false
  def normalize(%Request{} = request) do
    raw_mime = require_raw_mime!(request)
    payload = request.params || %{}
    {headers, body} = parse_message(raw_mime)
    normalized_headers = normalize_headers(headers)
    parts = parse_parts(headers, body)
    {text_body, html_body, attachments, attachment_blobs} = extract_parts(parts)

    message = %InboundMessage{
      provider: :sendgrid,
      provider_message_id: nil,
      message_id: first_header(normalized_headers, "message-id"),
      envelope_recipient: envelope_recipient(payload),
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
        raw_payload: payload,
        raw_headers: select_safe_headers(request.headers),
        raw_mime: raw_mime,
        verification_facts: %{},
        parse_warnings: parse_warnings(message),
        attachment_blobs: attachment_blobs
      }
    }
  end

  @impl MailglassInbound.Ingress.Provider
  def normalize(raw_body, headers) when is_binary(raw_body) and is_list(headers) do
    normalize(%Request{provider: :sendgrid, raw_mime: raw_body, headers: headers})
  end

  defp fetch_basic_auth!(config) do
    case Map.get(config, :basic_auth) do
      {user, pass} when is_binary(user) and is_binary(pass) ->
        {user, pass}

      _ ->
        raise ConfigError.new(:webhook_verification_key_missing,
                context: %{
                  provider: :sendgrid,
                  hint:
                    "configure :mailglass_inbound, :sendgrid basic_auth: {user, pass} for inbound verification"
                }
              )
    end
  end

  defp verify_basic_auth!(headers, user, pass) do
    case Enum.find(headers, fn {name, _value} -> String.downcase(name) == "authorization" end) do
      nil ->
        raise SignatureError.new(:missing_header, provider: :sendgrid)

      {_name, "Basic " <> encoded} ->
        with {:ok, decoded} <- Base.decode64(encoded),
             [decoded_user, decoded_pass] <- String.split(decoded, ":", parts: 2),
             true <- Plug.Crypto.secure_compare(decoded_user, user),
             true <- Plug.Crypto.secure_compare(decoded_pass, pass) do
          :ok
        else
          :error ->
            raise SignatureError.new(:malformed_header, provider: :sendgrid)

          [_only] ->
            raise SignatureError.new(:malformed_header, provider: :sendgrid)

          false ->
            raise SignatureError.new(:bad_credentials, provider: :sendgrid)
        end

      {_name, _other} ->
        raise SignatureError.new(:malformed_header, provider: :sendgrid)
    end
  end

  defp require_raw_mime!(%Request{raw_mime: raw_mime}) when is_binary(raw_mime) and raw_mime != "",
    do: raw_mime

  defp require_raw_mime!(_request) do
    raise ConfigError.new(:invalid,
            context: %{
              key: :"raw MIME email part",
              hint:
                "SendGrid inbound requires the raw MIME email part. Enable the `Send Raw` / `Post the raw, full MIME message` option so the multipart payload includes `email`."
            }
          )
  end

  defp parse_message(raw_mime) do
    [raw_headers, body] =
      case String.split(raw_mime, "\r\n\r\n", parts: 2) do
        [headers, rest] -> [headers, rest]
        [headers] -> [headers, ""]
      end

    {parse_headers(raw_headers), body}
  end

  defp parse_headers(raw_headers) do
    raw_headers
    |> String.split(~r/\r\n(?![ \t])/, trim: true)
    |> Enum.map(&unfold_header/1)
    |> Enum.reduce([], fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [name, value] ->
          [{String.downcase(String.trim(name)), String.trim_leading(value)} | acc]

        _ ->
          acc
      end
    end)
    |> Enum.reverse()
  end

  defp unfold_header(line) do
    line
    |> String.replace("\r\n\t", " ")
    |> String.replace("\r\n ", " ")
  end

  defp normalize_headers(headers) do
    Enum.reduce(headers, %{}, fn {name, value}, acc ->
      Map.update(acc, name, [value], &[value | &1])
    end)
    |> Map.new(fn {name, values} -> {name, Enum.reverse(values)} end)
  end

  defp first_header(headers, name) do
    headers
    |> Map.get(name, [])
    |> List.first()
  end

  defp parse_parts(headers, body) do
    content_type = first_header(normalize_headers(headers), "content-type") || ""

    case boundary_for(content_type) do
      nil ->
        [%{headers: headers, body: body}]

      boundary ->
        body
        |> split_multipart_body(boundary)
        |> Enum.flat_map(fn section ->
          {part_headers, part_body} = parse_message(section)
          parse_parts(part_headers, part_body)
        end)
    end
  end

  defp boundary_for(content_type) do
    case Regex.run(~r/boundary="?([^\";]+)"?/, content_type) do
      [_, boundary] -> boundary
      _ -> nil
    end
  end

  defp split_multipart_body(body, boundary) do
    delimiter = "--" <> boundary

    body
    |> String.split(delimiter)
    |> Enum.map(&String.trim_leading(&1, "\r\n"))
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn
      <<"--", _rest::binary>> -> nil
      section -> section
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp extract_parts(parts) do
    parts
    |> Enum.reduce({nil, nil, [], %{}, 0}, fn part,
                                              {text_body, html_body, attachments, blobs, attachment_index} ->
      content_type = content_type(part.headers)
      disposition = content_disposition(part.headers)
      filename = filename(disposition)

      cond do
        is_nil(filename) and content_type == "text/plain" and is_nil(text_body) ->
          {part.body, html_body, attachments, blobs, attachment_index}

        is_nil(filename) and content_type == "text/html" and is_nil(html_body) ->
          {text_body, part.body, attachments, blobs, attachment_index}

        filename ->
          attachment = %{
            filename: filename,
            content_type: content_type,
            disposition: disposition_type(disposition),
            content_id: content_id(part.headers)
          }

          attachment = Enum.reject(attachment, fn {_k, v} -> is_nil(v) end) |> Map.new()
          next_index = attachment_index + 1
          blob_key = "#{next_index}:#{filename}"

          {text_body, html_body, attachments ++ [attachment], Map.put(blobs, blob_key, part.body),
           next_index}

        true ->
          {text_body, html_body, attachments, blobs, attachment_index}
      end
    end)
    |> then(fn {text_body, html_body, attachments, blobs, _index} ->
      {text_body, html_body, attachments, blobs}
    end)
  end

  defp content_type(headers) do
    headers
    |> normalize_headers()
    |> first_header("content-type")
    |> case do
      nil -> "text/plain"
      value -> value |> String.split(";", parts: 2) |> hd() |> String.trim() |> String.downcase()
    end
  end

  defp content_disposition(headers) do
    headers
    |> normalize_headers()
    |> first_header("content-disposition")
  end

  defp filename(nil), do: nil

  defp filename(disposition) do
    case Regex.run(~r/filename="?([^\";]+)"?/, disposition) do
      [_, name] -> name
      _ -> nil
    end
  end

  defp disposition_type(nil), do: nil

  defp disposition_type(disposition) do
    disposition
    |> String.split(";", parts: 2)
    |> hd()
    |> String.trim()
    |> case do
      "inline" -> :inline
      "attachment" -> :attachment
      value -> value
    end
  end

  defp content_id(headers) do
    headers
    |> normalize_headers()
    |> first_header("content-id")
    |> case do
      nil -> nil
      value -> value |> String.trim() |> String.trim_leading("<") |> String.trim_trailing(">")
    end
  end

  defp envelope_recipient(payload) do
    with envelope when is_binary(envelope) <- payload["envelope"],
         {:ok, decoded} <- Jason.decode(envelope),
         [recipient | _] <- List.wrap(decoded["to"]),
         true <- is_binary(recipient) do
      recipient
    else
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
         {:ok, naive} <- NaiveDateTime.new(year_int, month_int, day_int, hour_int, minute_int, second_int) do
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
    |> maybe_put_warning(:missing_envelope_recipient, is_nil(message.envelope_recipient))
    |> maybe_put_warning(:missing_message_id_header, is_nil(message.message_id))
  end

  defp maybe_put_warning(warnings, _key, false), do: warnings
  defp maybe_put_warning(warnings, key, true), do: Map.put(warnings, key, true)

  defp select_safe_headers(headers) do
    headers
    |> Enum.reject(fn {name, _value} -> String.downcase(name) == "authorization" end)
    |> Enum.reduce(%{}, fn {name, value}, acc ->
      Map.update(acc, String.downcase(name), [value], &[value | &1])
    end)
    |> Map.new(fn {name, values} -> {name, Enum.reverse(values)} end)
  end
end
