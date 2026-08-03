defmodule Mailglass.Outbound.Envelope do
  @moduledoc false

  alias Mailglass.Message

  @version 1
  @max_json_depth 16
  @max_json_items 10_000
  @max_json_bytes 1_048_576
  @max_envelope_bytes 10_485_760
  @json_float_prefix "~mailglass:json-v1:float:"
  @json_string_prefix "~mailglass:json-v1:string:"
  @allowed_streams %{
    "transactional" => :transactional,
    "operational" => :operational,
    "bulk" => :bulk
  }

  defmodule Decoded do
    @moduledoc false
    @enforce_keys [:message, :adapter_ref]
    defstruct [:message, :adapter_ref]
  end

  def version, do: @version

  def dump(%Message{swoosh_email: email} = message, opts) when is_list(opts) do
    with {:ok, tenant_id} <- string(message.tenant_id),
         {:ok, stream} <- stream(message.stream),
         {:ok, adapter_ref} <- string(opts[:adapter_ref]),
         {:ok, from} <- mailbox(email.from),
         {:ok, recipient} <- sole_recipient(email),
         {:ok, reply_to} <- mailboxes(email.reply_to),
         {:ok, subject} <- nullable_string(email.subject),
         {:ok, html_body} <- nullable_string(email.html_body),
         {:ok, text_body} <- nullable_string(email.text_body),
         {:ok, headers} <- headers(email.headers),
         {:ok, attachments} <- attachments(email.attachments),
         {:ok, provider_options} <- json(email.provider_options),
         {:ok, metadata} <- json(message.metadata),
         {:ok, tags} <- strings(message.tags),
         {:ok, envelope} <-
           canonical_envelope(%{
             "version" => @version,
             "tenant_id" => tenant_id,
             "stream" => stream,
             "adapter_ref" => adapter_ref,
             "from" => from,
             "recipient" => recipient,
             "reply_to" => reply_to,
             "subject" => subject,
             "headers" => headers,
             "html_body" => html_body,
             "text_body" => text_body,
             "tags" => tags,
             "metadata" => metadata,
             "provider_options" => provider_options,
             "attachments" => attachments
           }) do
      {:ok, envelope}
    else
      _ -> serialization_error(:invalid_envelope)
    end
  end

  def dump(_, _), do: serialization_error(:invalid_envelope)

  def load(%{"version" => @version} = envelope) do
    with {:ok, _canonical} <- canonical_envelope(envelope),
         {:ok, tenant_id} <- required_string(envelope, "tenant_id"),
         {:ok, stream} <- required_stream(envelope),
         {:ok, adapter_ref} <- required_string(envelope, "adapter_ref"),
         {:ok, from} <- required_mailbox(envelope, "from"),
         {:ok, {field, recipient}} <- required_recipient(envelope),
         {:ok, reply_to} <- required_mailboxes(envelope, "reply_to"),
         {:ok, subject} <- required_nullable_string(envelope, "subject"),
         {:ok, headers} <- required_headers(envelope),
         {:ok, html_body} <- required_nullable_string(envelope, "html_body"),
         {:ok, text_body} <- required_nullable_string(envelope, "text_body"),
         {:ok, tags} <- required_strings(envelope, "tags"),
         {:ok, metadata} <- required_json(envelope, "metadata"),
         {:ok, provider_options} <- required_json(envelope, "provider_options"),
         {:ok, attachments} <- required_attachments(envelope) do
      email = Swoosh.Email.new(from: from, subject: subject || "")
      email = apply(Swoosh.Email, field, [email, recipient])

      email = %{
        email
        | reply_to: reply_to,
          headers: headers,
          html_body: html_body,
          text_body: text_body,
          attachments: attachments,
          provider_options: provider_options
      }

      {:ok,
       %Decoded{
         message: %Message{
           swoosh_email: email,
           tenant_id: tenant_id,
           stream: stream,
           tags: tags,
           metadata: metadata
         },
         adapter_ref: adapter_ref
       }}
    else
      _ -> serialization_error(:invalid_persisted_envelope)
    end
  end

  def load(_), do: serialization_error(:unsupported_version)

  def digest(envelope) do
    case Jason.encode(envelope) do
      {:ok, encoded} -> encoded |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
      _ -> nil
    end
  end

  defp canonical_envelope(envelope) when is_map(envelope) do
    with {:ok, encoded} <- Jason.encode(envelope),
         true <- byte_size(encoded) <= @max_envelope_bytes do
      {:ok, envelope}
    else
      _ -> :error
    end
  end

  defp canonical_envelope(_), do: :error

  defp serialization_error(reason),
    do: {:error, Mailglass.SendError.new(:serialization_failed, context: %{reason_class: reason})}

  defp required_string(map, key), do: with({:ok, value} <- Map.fetch(map, key), do: string(value))

  defp required_nullable_string(map, key),
    do: with({:ok, value} <- Map.fetch(map, key), do: nullable_string(value))

  defp required_json(map, key),
    do: with({:ok, value} <- Map.fetch(map, key), do: load_json(value))

  defp required_strings(map, key), do: with({:ok, value} <- Map.fetch(map, key), do: strings(value))

  defp required_stream(map),
    do: with({:ok, value} <- Map.fetch(map, "stream"), do: Map.fetch(@allowed_streams, value))

  defp required_mailbox(map, key),
    do: with({:ok, value} <- Map.fetch(map, key), do: load_mailbox(value))

  defp required_mailboxes(map, key),
    do: with({:ok, value} <- Map.fetch(map, key), do: load_mailboxes(value))

  defp required_headers(map),
    do: with({:ok, value} <- Map.fetch(map, "headers"), do: load_headers(value))

  defp required_attachments(map),
    do: with({:ok, value} <- Map.fetch(map, "attachments"), do: load_attachments(value))

  defp required_recipient(map),
    do: with({:ok, value} <- Map.fetch(map, "recipient"), do: load_recipient(value))

  defp stream(value) when is_atom(value) do
    case Map.fetch(@allowed_streams, Atom.to_string(value)) do
      {:ok, _} -> {:ok, Atom.to_string(value)}
      _ -> :error
    end
  end

  defp stream(_), do: :error

  defp string(value) when is_binary(value) and byte_size(value) > 0 do
    if String.valid?(value), do: {:ok, value}, else: :error
  end

  defp string(_), do: :error
  defp nullable_string(nil), do: {:ok, nil}

  defp nullable_string(value) when is_binary(value),
    do: if(String.valid?(value), do: {:ok, value}, else: :error)

  defp nullable_string(_), do: :error

  defp strings(values) when is_list(values),
    do:
      if(Enum.all?(values, &(is_binary(&1) and String.valid?(&1))), do: {:ok, values}, else: :error)

  defp strings(_), do: :error

  defp mailbox({name, address}) when is_binary(name),
    do: with({:ok, address} <- string(address), do: {:ok, [name, address]})

  defp mailbox(address) when is_binary(address),
    do: with({:ok, address} <- string(address), do: {:ok, ["", address]})

  defp mailbox(_), do: :error
  defp mailboxes(nil), do: {:ok, []}
  defp mailboxes(values) when is_list(values), do: values |> Enum.map(&mailbox/1) |> collect()
  defp mailboxes(value), do: with({:ok, mailbox} <- mailbox(value), do: {:ok, [mailbox]})

  defp sole_recipient(email) do
    with {:ok, %{field: field}} <- Message.sole_recipient(%Message{swoosh_email: email}),
         [mailbox] <- Map.get(email, field),
         {:ok, value} <- mailbox(mailbox),
         do: {:ok, [Atom.to_string(field), value]},
         else: (_ -> :error)
  end

  defp headers(values) when is_map(values) do
    values |> Enum.sort_by(fn {key, value} -> {key, value} end) |> headers()
  end

  defp headers(values) when is_list(values), do: values |> Enum.map(&header/1) |> collect()
  defp headers(_), do: :error
  defp header({key, value}), do: header([key, value])

  defp header([key, value]) when is_binary(key) and is_binary(value),
    do: if(String.valid?(key) and String.valid?(value), do: {:ok, [key, value]}, else: :error)

  defp header(_), do: :error

  defp attachments(values) when is_list(values), do: values |> Enum.map(&attachment/1) |> collect()
  defp attachments(_), do: :error

  defp attachment(%Swoosh.Attachment{} = attachment) do
    try do
      with bytes when is_binary(bytes) <- Swoosh.Attachment.get_content(attachment),
           {:ok, filename} <- string(attachment.filename),
           {:ok, content_type} <- string(attachment.content_type),
           {:ok, cid} <- nullable_string(attachment.cid),
           {:ok, headers} <- headers(attachment.headers),
           true <- attachment.type in [:attachment, :inline] do
        {:ok,
         %{
           "encoding" => "base64",
           "data" => Base.encode64(bytes),
           "filename" => filename,
           "content_type" => content_type,
           "type" => Atom.to_string(attachment.type),
           "cid" => cid,
           "headers" => headers
         }}
      else
        _ -> :error
      end
    rescue
      _ -> :error
    end
  end

  defp attachment(_), do: :error

  defp json(value) do
    with {:ok, normalized, _items} <- normalize_json(value, 0, 0),
         {:ok, encoded} <- Jason.encode(normalized),
         true <- byte_size(encoded) <= @max_json_bytes,
         do: {:ok, normalized},
         else: (_ -> :error)
  end

  defp normalize_json(_value, _depth, items) when items >= @max_json_items, do: :error
  defp normalize_json(nil, _depth, items), do: {:ok, nil, items + 1}

  defp normalize_json(value, _depth, items) when is_boolean(value) or is_integer(value),
    do: {:ok, value, items + 1}

  defp normalize_json(value, _depth, items) when is_binary(value),
    do: if(String.valid?(value), do: {:ok, encode_json_string(value), items + 1}, else: :error)

  defp normalize_json(value, _depth, items) when is_float(value),
    do: if(finite_float?(value), do: {:ok, encode_json_float(value), items + 1}, else: :error)

  defp normalize_json(_value, depth, _items) when depth >= @max_json_depth, do: :error

  defp normalize_json(values, depth, items) when is_list(values),
    do: normalize_list(values, depth + 1, items + 1, [])

  defp normalize_json(values, depth, items) when is_map(values) and not is_struct(values),
    do: normalize_map(values, depth + 1, items + 1, %{})

  defp normalize_json(_, _, _), do: :error
  defp normalize_list([], _, items, acc), do: {:ok, Enum.reverse(acc), items}

  defp normalize_list([value | rest], depth, items, acc),
    do:
      with(
        {:ok, value, items} <- normalize_json(value, depth, items),
        do: normalize_list(rest, depth, items, [value | acc])
      )

  defp normalize_map(values, depth, items, acc) do
    Enum.reduce_while(values, {:ok, acc, items}, fn {key, value}, {:ok, acc, items} ->
      key = if is_atom(key), do: Atom.to_string(key), else: key

      with true <- is_binary(key) and String.valid?(key),
           false <- Map.has_key?(acc, key),
           {:ok, value, items} <- normalize_json(value, depth, items) do
        {:cont, {:ok, Map.put(acc, key, value), items}}
      else
        _ -> {:halt, :error}
      end
    end)
  end

  defp finite_float?(value) do
    case <<value::float-64>> do
      <<_sign::1, 0x7FF::11, _::52>> -> false
      _ -> true
    end
  end

  # PostgreSQL jsonb canonicalizes numeric spellings. Store finite floats as
  # tagged IEEE-754 bytes so the payload digest covers a value that survives a
  # jsonb round trip exactly. User strings sharing either reserved prefix are
  # escaped, so the on-disk representation has no marker collisions.
  defp encode_json_float(value),
    do: @json_float_prefix <> Base.encode16(<<value::float-64>>, case: :lower)

  defp encode_json_string(value) do
    if String.starts_with?(value, [@json_float_prefix, @json_string_prefix]) do
      @json_string_prefix <> value
    else
      value
    end
  end

  defp load_json(value) do
    with {:ok, value, _items} <- decode_json(value, 0, 0),
         {:ok, encoded} <- Jason.encode(value),
         true <- byte_size(encoded) <= @max_json_bytes do
      {:ok, value}
    else
      _ -> :error
    end
  end

  defp decode_json(_value, _depth, items) when items >= @max_json_items, do: :error
  defp decode_json(nil, _depth, items), do: {:ok, nil, items + 1}

  defp decode_json(value, _depth, items) when is_boolean(value) or is_integer(value),
    do: {:ok, value, items + 1}

  defp decode_json(value, _depth, items) when is_float(value),
    do: if(finite_float?(value), do: {:ok, value, items + 1}, else: :error)

  defp decode_json(value, _depth, items) when is_binary(value) do
    with true <- String.valid?(value),
         {:ok, decoded} <- decode_json_string(value) do
      {:ok, decoded, items + 1}
    else
      _ -> :error
    end
  end

  defp decode_json(_value, depth, _items) when depth >= @max_json_depth, do: :error

  defp decode_json(values, depth, items) when is_list(values),
    do: decode_json_list(values, depth + 1, items + 1, [])

  defp decode_json(values, depth, items) when is_map(values) and not is_struct(values),
    do: decode_json_map(values, depth + 1, items + 1, %{})

  defp decode_json(_, _, _), do: :error

  defp decode_json_string(value) do
    cond do
      String.starts_with?(value, @json_string_prefix) ->
        {:ok, String.replace_prefix(value, @json_string_prefix, "")}

      String.starts_with?(value, @json_float_prefix) ->
        value
        |> String.replace_prefix(@json_float_prefix, "")
        |> Base.decode16(case: :mixed)
        |> decode_json_float()

      true ->
        {:ok, value}
    end
  end

  defp decode_json_float({:ok, <<value::float-64>>}) do
    if finite_float?(value), do: {:ok, value}, else: :error
  end

  defp decode_json_float(_), do: :error

  defp decode_json_list([], _, items, acc), do: {:ok, Enum.reverse(acc), items}

  defp decode_json_list([value | rest], depth, items, acc),
    do:
      with(
        {:ok, value, items} <- decode_json(value, depth, items),
        do: decode_json_list(rest, depth, items, [value | acc])
      )

  defp decode_json_map(values, depth, items, acc) do
    Enum.reduce_while(values, {:ok, acc, items}, fn {key, value}, {:ok, acc, items} ->
      with true <- is_binary(key) and String.valid?(key),
           false <- Map.has_key?(acc, key),
           {:ok, value, items} <- decode_json(value, depth, items) do
        {:cont, {:ok, Map.put(acc, key, value), items}}
      else
        _ -> {:halt, :error}
      end
    end)
  end

  defp collect(items) do
    case Enum.reduce_while(items, {:ok, []}, fn item, {:ok, acc} ->
           case item do
             {:ok, value} -> {:cont, {:ok, [value | acc]}}
             _ -> {:halt, :error}
           end
         end) do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      x -> x
    end
  end

  defp load_mailbox([name, address]) when is_binary(name) and is_binary(address) do
    with true <- String.valid?(name), {:ok, address} <- string(address), do: {:ok, {name, address}}
  end

  defp load_mailbox(_), do: :error

  defp load_mailboxes(values) when is_list(values),
    do: values |> Enum.map(&load_mailbox/1) |> collect()

  defp load_mailboxes(_), do: :error

  defp load_recipient([field, mailbox]) when field in ["to", "cc", "bcc"],
    do:
      with(
        {:ok, mailbox} <- load_mailbox(mailbox),
        do: {:ok, {String.to_existing_atom(field), mailbox}}
      )

  defp load_recipient(_), do: :error

  defp load_headers(values) when is_list(values) do
    case values |> Enum.map(&header/1) |> collect() do
      {:ok, pairs} -> {:ok, Enum.map(pairs, fn [k, v] -> {k, v} end)}
      x -> x
    end
  end

  defp load_headers(_), do: :error

  defp load_attachments(values) when is_list(values),
    do: values |> Enum.map(&load_attachment/1) |> collect()

  defp load_attachments(_), do: :error

  defp load_attachment(%{} = attachment) do
    with "base64" <- attachment["encoding"],
         {:ok, bytes} <- Base.decode64(attachment["data"] || ""),
         {:ok, filename} <- string(attachment["filename"]),
         {:ok, content_type} <- string(attachment["content_type"]),
         {:ok, cid} <- nullable_string(attachment["cid"]),
         {:ok, headers} <- load_headers(attachment["headers"]),
         type when type in ["attachment", "inline"] <- attachment["type"] do
      {:ok,
       %Swoosh.Attachment{
         filename: filename,
         content_type: content_type,
         data: bytes,
         type: String.to_existing_atom(type),
         cid: cid,
         headers: headers
       }}
    else
      _ -> :error
    end
  end

  defp load_attachment(_), do: :error
end
