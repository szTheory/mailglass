defmodule Mailglass.Outbound.Envelope do
  @moduledoc false

  alias Mailglass.Message

  @version 1
  @allowed_streams %{
    "transactional" => :transactional,
    "operational" => :operational,
    "bulk" => :bulk
  }

  def version, do: @version

  def dump(%Message{swoosh_email: email} = message, opts) when is_list(opts) do
    with {:ok, adapter_ref} <- string(opts[:adapter_ref]),
         {:ok, from} <- mailbox(email.from),
         {:ok, recipient} <- sole_recipient(email),
         {:ok, reply_to} <- mailboxes(email.reply_to),
         {:ok, attachments} <- attachments(email.attachments),
         {:ok, provider_options} <- json(email.provider_options),
         {:ok, metadata} <- json(message.metadata),
         {:ok, headers} <- json(email.headers),
         {:ok, tags} <- strings(message.tags) do
      {:ok,
       %{
         "version" => @version,
         "tenant_id" => message.tenant_id,
         "stream" => Atom.to_string(message.stream),
         "adapter_ref" => adapter_ref,
         "from" => from,
         "recipient" => recipient,
         "reply_to" => reply_to,
         "subject" => email.subject,
         "headers" => headers,
         "html_body" => email.html_body,
         "text_body" => email.text_body,
         "tags" => tags,
         "metadata" => metadata,
         "provider_options" => provider_options,
         "attachments" => attachments
       }}
    else
      _ ->
        {:error,
         Mailglass.SendError.new(:serialization_failed, context: %{reason_class: :invalid_envelope})}
    end
  end

  def load(%{"version" => @version} = envelope) do
    with {:ok, from} <- load_mailbox(envelope["from"]),
         {:ok, {field, mailbox}} <- load_recipient(envelope["recipient"]),
         {:ok, reply_to} <- load_mailboxes(envelope["reply_to"]),
         {:ok, attachments} <- load_attachments(envelope["attachments"] || []),
         {:ok, stream} <- Map.fetch(@allowed_streams, envelope["stream"]) do
      email = Swoosh.Email.new(from: from, subject: envelope["subject"] || "")
      email = apply(Swoosh.Email, field, [email, mailbox])
      email = if reply_to == [], do: email, else: Swoosh.Email.reply_to(email, reply_to)

      {:ok,
       %Message{
         swoosh_email: %{
           email
           | headers: envelope["headers"] || %{},
             html_body: envelope["html_body"],
             text_body: envelope["text_body"],
             attachments: attachments,
             provider_options: envelope["provider_options"] || %{}
         },
         tenant_id: envelope["tenant_id"],
         stream: stream,
         tags: envelope["tags"] || [],
         metadata: envelope["metadata"] || %{}
       }}
    else
      _ ->
        {:error,
         Mailglass.SendError.new(:serialization_failed,
           context: %{reason_class: :invalid_persisted_envelope}
         )}
    end
  end

  def load(_),
    do:
      {:error,
       Mailglass.SendError.new(:serialization_failed,
         context: %{reason_class: :unsupported_version}
       )}

  def digest(envelope),
    do:
      envelope |> Jason.encode!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  defp string(value) when is_binary(value) and byte_size(value) > 0 do
    if String.valid?(value), do: {:ok, value}, else: :error
  end

  defp string(_), do: :error

  defp strings(values) when is_list(values),
    do:
      if(Enum.all?(values, &(is_binary(&1) and String.valid?(&1))), do: {:ok, values}, else: :error)

  defp strings(_), do: :error

  defp mailbox({name, address}) when is_binary(name),
    do:
      string(address)
      |> then(fn
        {:ok, address} -> {:ok, [name, address]}
        x -> x
      end)

  defp mailbox(address) when is_binary(address), do: {:ok, ["", address]}
  defp mailbox(_), do: :error
  defp mailboxes(nil), do: {:ok, []}
  defp mailboxes(value) when is_list(value), do: value |> Enum.map(&mailbox/1) |> collect()

  defp mailboxes(value),
    do:
      mailbox(value)
      |> then(fn
        {:ok, item} -> {:ok, [item]}
        x -> x
      end)

  defp sole_recipient(email) do
    case Message.sole_recipient(%Message{swoosh_email: email}) do
      {:ok, %{field: field}} ->
        {:ok, [Atom.to_string(field), hd(Map.get(email, field)) |> Tuple.to_list()]}

      _ ->
        :error
    end
  end

  defp attachments(values) when is_list(values), do: values |> Enum.map(&attachment/1) |> collect()
  defp attachments(_), do: :error

  defp attachment(%Swoosh.Attachment{} = a) do
    try do
      bytes = Swoosh.Attachment.get_content(a)

      if is_binary(bytes),
        do:
          {:ok,
           %{
             "encoding" => "base64",
             "data" => Base.encode64(bytes),
             "filename" => a.filename,
             "content_type" => a.content_type,
             "type" => Atom.to_string(a.type),
             "cid" => a.cid,
             "headers" => a.headers || []
           }},
        else: :error
    rescue
      _ -> :error
    end
  end

  defp attachment(_), do: :error

  defp json(value) when is_nil(value) or is_binary(value) or is_boolean(value) or is_integer(value),
    do: {:ok, value}

  defp json(value) when is_float(value) and value == value, do: {:ok, value}
  defp json(value) when is_list(value), do: value |> Enum.map(&json/1) |> collect()

  defp json(value) when is_map(value) and not is_struct(value) do
    Enum.reduce_while(value, {:ok, %{}}, fn {key, val}, {:ok, acc} ->
      key = if is_atom(key), do: Atom.to_string(key), else: key

      with true <- is_binary(key),
           false <- Map.has_key?(acc, key),
           {:ok, val} <- json(val),
           do: {:cont, {:ok, Map.put(acc, key, val)}},
           else: (_ -> {:halt, :error})
    end)
  end

  defp json(_), do: :error

  defp collect(items),
    do:
      Enum.reduce_while(items, {:ok, []}, fn item, {:ok, acc} ->
        case item do
          {:ok, value} -> {:cont, {:ok, acc ++ [value]}}
          _ -> {:halt, :error}
        end
      end)

  defp load_mailbox([name, address]) when is_binary(name) and is_binary(address),
    do: {:ok, {name, address}}

  defp load_mailbox(_), do: :error

  defp load_mailboxes(values) when is_list(values),
    do: values |> Enum.map(&load_mailbox/1) |> collect()

  defp load_mailboxes(_), do: :error

  defp load_recipient([field, mailbox]) when field in ["to", "cc", "bcc"],
    do:
      load_mailbox(mailbox)
      |> then(fn
        {:ok, x} -> {:ok, {String.to_existing_atom(field), x}}
        x -> x
      end)

  defp load_recipient(_), do: :error

  defp load_attachments(values),
    do:
      values
      |> Enum.map(fn a ->
        with "base64" <- a["encoding"], {:ok, bytes} <- Base.decode64(a["data"] || "") do
          {:ok,
           %Swoosh.Attachment{
             filename: a["filename"],
             content_type: a["content_type"],
             data: bytes,
             type: if(a["type"] == "inline", do: :inline, else: :attachment),
             cid: a["cid"],
             headers: a["headers"] || []
           }}
        else
          _ -> :error
        end
      end)
      |> collect()
end
