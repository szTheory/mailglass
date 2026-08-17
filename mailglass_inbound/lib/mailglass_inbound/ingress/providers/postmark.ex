defmodule MailglassInbound.Ingress.Providers.Postmark do
  @moduledoc false

  @behaviour MailglassInbound.Ingress.Provider

  import Bitwise

  alias Mailglass.{ConfigError, SignatureError}
  alias MailglassInbound.InboundMessage

  @impl MailglassInbound.Ingress.Provider
  def verify!(_raw_body, headers, %{} = config) when is_list(headers) do
    {user, pass} = fetch_basic_auth!(config)
    verify_basic_auth!(headers, user, pass)
    ip_status = verify_ip_allowlist!(config)

    %{
      auth: :basic_auth,
      ip_allowlist: ip_status
    }
  end

  @impl MailglassInbound.Ingress.Provider
  def normalize(raw_body, headers) when is_binary(raw_body) and is_list(headers) do
    payload = Jason.decode!(raw_body)
    normalized_headers = normalize_headers(payload["Headers"] || [])

    message = %InboundMessage{
      provider: :postmark,
      provider_message_id: string_or_nil(payload["MessageID"]),
      message_id: first_header(normalized_headers, "message-id"),
      envelope_recipient: string_or_nil(payload["OriginalRecipient"]),
      from: normalize_addresses(payload["FromFull"]),
      to: normalize_addresses(payload["ToFull"]),
      cc: normalize_addresses(payload["CcFull"]),
      bcc: normalize_addresses(payload["BccFull"]),
      reply_to: normalize_addresses(payload["ReplyToFull"]),
      subject: string_or_nil(payload["Subject"]),
      headers: normalized_headers,
      sent_at: parse_datetime(first_header(normalized_headers, "date")),
      received_at: DateTime.utc_now(),
      text_body: string_or_nil(payload["TextBody"]),
      html_body: string_or_nil(payload["HtmlBody"]),
      attachments: normalize_attachment_metadata(payload["Attachments"] || [])
    }

    %{
      message: message,
      evidence: %{
        raw_payload: payload,
        raw_headers: select_safe_headers(headers),
        raw_mime: raw_mime(payload),
        verification_facts: %{},
        parse_warnings: parse_warnings(payload, message),
        attachment_blobs: attachment_blobs(payload["Attachments"] || [])
      }
    }
  end

  defp fetch_basic_auth!(config) do
    case Map.get(config, :basic_auth) do
      {u, p} when is_binary(u) and is_binary(p) ->
        {u, p}

      _ ->
        raise ConfigError.new(:webhook_verification_key_missing,
                context: %{
                  provider: :postmark,
                  hint:
                    "configure :mailglass_inbound, :postmark basic_auth: {user, pass} for inbound verification"
                }
              )
    end
  end

  defp verify_basic_auth!(headers, user, pass) do
    case List.keyfind(headers, "authorization", 0) do
      nil ->
        raise SignatureError.new(:missing_header, provider: :postmark)

      {"authorization", "Basic " <> b64} ->
        with {:ok, decoded} <- Base.decode64(b64),
             [decoded_user, decoded_pass] <- String.split(decoded, ":", parts: 2),
             true <- Plug.Crypto.secure_compare(decoded_user, user),
             true <- Plug.Crypto.secure_compare(decoded_pass, pass) do
          :ok
        else
          :error ->
            raise SignatureError.new(:malformed_header, provider: :postmark)

          [_only] ->
            raise SignatureError.new(:malformed_header, provider: :postmark)

          false ->
            raise SignatureError.new(:bad_credentials, provider: :postmark)
        end

      {"authorization", _other} ->
        raise SignatureError.new(:malformed_header, provider: :postmark)
    end
  end

  defp verify_ip_allowlist!(config) do
    case Map.get(config, :ip_allowlist, []) do
      [] ->
        :not_configured

      cidrs when is_list(cidrs) ->
        case Map.get(config, :remote_ip) do
          nil ->
            raise SignatureError.new(:malformed_header,
                    provider: :postmark,
                    context: %{detail: "ip_allowlist configured but remote_ip missing"}
                  )

          remote_ip when is_tuple(remote_ip) ->
            if Enum.any?(cidrs, &cidr_match?(remote_ip, &1)) do
              :matched
            else
              raise SignatureError.new(:ip_disallowed, provider: :postmark)
            end
        end
    end
  end

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

  defp normalize_headers(headers) do
    Enum.reduce(headers, %{}, fn header, acc ->
      case {header["Name"], header["Value"]} do
        {name, value} when is_binary(name) and is_binary(value) ->
          Map.update(acc, String.downcase(name), [value], &[value | &1])

        _ ->
          acc
      end
    end)
    |> Map.new(fn {name, values} -> {name, Enum.reverse(values)} end)
  end

  defp first_header(headers, name) do
    headers
    |> Map.get(name, [])
    |> List.first()
  end

  defp normalize_addresses(list) when is_list(list) do
    Enum.map(list, fn item ->
      %{
        address: item["Email"],
        name: item["Name"]
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end)
    |> Enum.reject(&(Map.get(&1, :address) in [nil, ""]))
  end

  defp normalize_addresses(_), do: []

  defp normalize_attachment_metadata(list) when is_list(list) do
    Enum.map(list, fn attachment ->
      %{
        filename: string_or_nil(attachment["Name"]),
        content_type: string_or_nil(attachment["ContentType"]),
        disposition: normalize_disposition(attachment["ContentDisposition"]),
        content_id: string_or_nil(attachment["ContentID"])
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end)
  end

  defp normalize_attachment_metadata(_), do: []

  defp normalize_disposition("inline"), do: :inline
  defp normalize_disposition("attachment"), do: :attachment
  defp normalize_disposition(value) when is_binary(value), do: value
  defp normalize_disposition(_), do: nil

  defp attachment_blobs(list) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {attachment, idx}, acc ->
      with name when is_binary(name) <- attachment["Name"],
           content when is_binary(content) <- attachment["Content"],
           {:ok, decoded} <- Base.decode64(content) do
        Map.put(acc, "#{idx}:#{name}", decoded)
      else
        _ -> acc
      end
    end)
  end

  defp attachment_blobs(_), do: %{}

  defp select_safe_headers(headers) do
    headers
    |> Enum.reject(fn {name, _value} -> String.downcase(name) == "authorization" end)
    |> Enum.reduce(%{}, fn {name, value}, acc ->
      Map.update(acc, String.downcase(name), [value], &[value | &1])
    end)
    |> Map.new(fn {name, values} -> {name, Enum.reverse(values)} end)
  end

  defp raw_mime(payload) do
    case payload["RawEmail"] do
      raw when is_binary(raw) and raw != "" -> raw
      _ -> nil
    end
  end

  defp parse_warnings(payload, message) do
    warnings = %{}

    warnings =
      maybe_put_warning(warnings, :missing_original_recipient, is_nil(message.envelope_recipient))

    warnings = maybe_put_warning(warnings, :missing_message_id_header, is_nil(message.message_id))
    maybe_put_warning(warnings, :bcc_partial_or_missing, (payload["BccFull"] || []) == [])
  end

  defp maybe_put_warning(warnings, _key, false), do: warnings
  defp maybe_put_warning(warnings, key, true), do: Map.put(warnings, key, true)

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} ->
        dt

      _ ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
          _ -> nil
        end
    end
  end

  defp string_or_nil(value) when is_binary(value) and value != "", do: value
  defp string_or_nil(_), do: nil
end
