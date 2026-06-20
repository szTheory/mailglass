defmodule Mailglass.Compliance do
  @moduledoc """
  Injects RFC-required and mailglass-specific headers into outbound messages.

   ships functional stubs for the v0.1 RFC floor:

    * `Date` — RFC 2822 format; injected if absent.
    * `Message-ID` — RFC 5322 unique identifier; injected if absent.
    * `MIME-Version` — always `"1.0"`; injected if absent.
    * `Mailglass-Mailable` — `"Module.function/arity"`; injected if absent.

  Full RFC 8058 `List-Unsubscribe` + `List-Unsubscribe-Post` lands in v0.5
  `Feedback-ID` gets its full shape once tenant-scoped streams land
  in .

  ## Invariant

  `add_rfc_required_headers/1` NEVER overwrites a header that already exists.
  Adopters who set their own `Date` or `Message-ID` keep their values intact.
  """

  @doc """
  Injects RFC-required headers (`Date`, `Message-ID`, `MIME-Version`) and the
  `Mailglass-Mailable` header if absent.

  Does NOT overwrite existing header values.

  ## Examples

      iex> email = %Swoosh.Email{}
      iex> updated = Mailglass.Compliance.add_rfc_required_headers(email)
      iex> Map.has_key?(updated.headers, "Date")
      true
      iex> updated.headers["MIME-Version"]
      "1.0"
  """
  @doc since: "0.1.0"
  @spec add_rfc_required_headers(Swoosh.Email.t()) :: Swoosh.Email.t()
  def add_rfc_required_headers(%Swoosh.Email{} = email) do
    email
    |> maybe_add_date()
    |> maybe_add_message_id()
    |> maybe_add_mime_version()
    |> maybe_add_default_mailable_header()
  end

  @doc """
  Adds the `Mailglass-Mailable` header identifying the source mailable.

  Format: `"ModuleName.function/arity"` — e.g., `"MyApp.UserMailer.welcome/1"`.

  Does NOT overwrite an existing `Mailglass-Mailable` header.

  ## Examples

      iex> email = %Swoosh.Email{}
      iex> result = Mailglass.Compliance.add_mailable_header(email, MyApp.UserMailer, :welcome, 1)
      iex> result.headers["Mailglass-Mailable"]
      "MyApp.UserMailer.welcome/1"
  """
  @doc since: "0.1.0"
  @spec add_mailable_header(Swoosh.Email.t(), module(), atom(), non_neg_integer()) ::
          Swoosh.Email.t()
  def add_mailable_header(%Swoosh.Email{} = email, module, function, arity)
      when is_atom(module) and is_atom(function) and is_integer(arity) and arity >= 0 do
    header_value = format_mailable_header(module, function, arity)
    put_header_if_absent(email, "Mailglass-Mailable", header_value)
  end

  alias Mailglass.Compliance.Unsubscribe

  @unsubscribe_post_value "List-Unsubscribe=One-Click"

  @doc """
  Applies message-aware outbound compliance headers after render while stream
  context is still available.

  Generic RFC headers stay on the `%Swoosh.Email{}` primitive. Stream-aware
  headers such as `Feedback-ID` and RFC 8058 unsubscribe headers flow through
  this wrapper.
  """
  @doc since: "0.2.0"
  @spec apply_outbound_headers(Mailglass.Message.t()) :: Mailglass.Message.t()
  def apply_outbound_headers(%Mailglass.Message{} = message) do
    message
    |> maybe_add_feedback_id()
    |> maybe_add_unsubscribe_headers()
  end

  @doc """
  Injects the `Feedback-ID` header into the inner `%Swoosh.Email{}` if configured and absent.

  Requires a `%Mailglass.Message{}` because it interpolates the stream, tenant, and mailable.
  """
  @doc since: "0.2.0"
  @spec maybe_add_feedback_id(Mailglass.Message.t()) :: Mailglass.Message.t()
  def maybe_add_feedback_id(%Mailglass.Message{} = message) do
    if feedback_id = Application.get_env(:mailglass, :feedback_id) do
      tenant_id = message.tenant_id || "default"
      mailable_str = extract_mailable_name(message.mailable)
      stream = message.stream
      header_value = "#{feedback_id}:#{mailable_str}:#{tenant_id}:#{stream}"

      updated_email = put_header_if_absent(message.swoosh_email, "Feedback-ID", header_value)
      %{message | swoosh_email: updated_email}
    else
      message
    end
  end

  @doc """
  Writes the RFC 8058 unsubscribe header pair atomically on the inner
  `%Swoosh.Email{}`.

  This is the only allowed mutation path for `List-Unsubscribe` and
  `List-Unsubscribe-Post`.
  """
  @doc since: "0.2.0"
  @spec inject_unsubscribe_headers(Mailglass.Message.t(), String.t()) :: Mailglass.Message.t()
  def inject_unsubscribe_headers(%Mailglass.Message{} = message, url) when is_binary(url) do
    email =
      case unsubscribe_header_state(message.swoosh_email) do
        :absent ->
          message.swoosh_email
          |> put_header_if_absent("List-Unsubscribe", "<#{url}>")
          |> put_header_if_absent("List-Unsubscribe-Post", @unsubscribe_post_value)

        :complete ->
          message.swoosh_email

        :partial ->
          message.swoosh_email
      end

    %{message | swoosh_email: email}
  end

  @doc false
  @spec configured_lifecycle() :: module()
  def configured_lifecycle, do: Mailglass.Config.compliance_lifecycle()

  defp extract_mailable_name(nil), do: "unknown"

  defp extract_mailable_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
  end

  # --- Private helpers ---

  defp maybe_add_date(%Swoosh.Email{} = email) do
    if has_header?(email, "Date") do
      email
    else
      put_header(email, "Date", format_rfc2822_date(Mailglass.Clock.utc_now()))
    end
  end

  defp maybe_add_message_id(%Swoosh.Email{} = email) do
    if has_header?(email, "Message-ID") do
      email
    else
      put_header(email, "Message-ID", generate_message_id())
    end
  end

  defp maybe_add_mime_version(%Swoosh.Email{} = email) do
    if has_header?(email, "MIME-Version") do
      email
    else
      put_header(email, "MIME-Version", "1.0")
    end
  end

  # Adds a placeholder Mailglass-Mailable header when no mailable is known.
  # Adopters who know the mailable should call add_mailable_header/4 explicitly
  # (typically threaded through the Outbound pipeline in ).
  defp maybe_add_default_mailable_header(%Swoosh.Email{} = email) do
    put_header_if_absent(email, "Mailglass-Mailable", "unknown")
  end

  defp format_mailable_header(module, function, arity) do
    module_string =
      module
      |> Atom.to_string()
      |> String.replace_prefix("Elixir.", "")

    "#{module_string}.#{function}/#{arity}"
  end

  # RFC 5322 Message-ID: "<unique-id@domain>"
  defp generate_message_id do
    random = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    "<#{random}@mailglass>"
  end

  # RFC 2822 date format: "Mon, 22 Apr 2026 12:00:00 +0000"
  defp format_rfc2822_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%a, %d %b %Y %H:%M:%S +0000")
  end

  defp maybe_add_unsubscribe_headers(%Mailglass.Message{} = message) do
    if should_inject_unsubscribe_headers?(message) do
      url =
        Unsubscribe.unsubscribe_url(unsubscribe_delivery_id(message), unsubscribe_context(message))

      inject_unsubscribe_headers(message, url)
    else
      message
    end
  end

  defp should_inject_unsubscribe_headers?(%Mailglass.Message{stream: :bulk}), do: true

  defp should_inject_unsubscribe_headers?(%Mailglass.Message{
         stream: :operational,
         mailable: mailable
       })
       when is_atom(mailable) do
    if function_exported?(mailable, :__mailglass_unsubscribe__, 0) do
      mailable.__mailglass_unsubscribe__()
      |> Keyword.get(:enabled, false)
      |> Kernel.==(true)
    else
      false
    end
  end

  defp should_inject_unsubscribe_headers?(%Mailglass.Message{stream: :operational}), do: false
  defp should_inject_unsubscribe_headers?(%Mailglass.Message{}), do: false

  defp unsubscribe_delivery_id(%Mailglass.Message{} = message) do
    message.metadata[:delivery_id] || Ecto.UUID.generate()
  end

  defp unsubscribe_context(%Mailglass.Message{} = message) do
    %{tenant_id: message.tenant_id}
  end

  defp unsubscribe_header_state(%Swoosh.Email{} = email) do
    list_unsubscribe? = has_header?(email, "List-Unsubscribe")
    one_click? = has_header?(email, "List-Unsubscribe-Post")

    cond do
      list_unsubscribe? and one_click? -> :complete
      list_unsubscribe? or one_click? -> :partial
      true -> :absent
    end
  end

  defp has_header?(%Swoosh.Email{headers: headers}, key) when is_map(headers) do
    Map.has_key?(headers, key)
  end

  defp has_header?(%Swoosh.Email{headers: headers}, key) when is_list(headers) do
    Enum.any?(headers, fn
      {k, _v} -> k == key
      _ -> false
    end)
  end

  defp put_header(%Swoosh.Email{headers: headers} = email, key, value) when is_map(headers) do
    %{email | headers: Map.put(headers, key, value)}
  end

  defp put_header(%Swoosh.Email{headers: headers} = email, key, value) when is_list(headers) do
    %{email | headers: [{key, value} | headers]}
  end

  defp put_header_if_absent(%Swoosh.Email{} = email, key, value) do
    if has_header?(email, key), do: email, else: put_header(email, key, value)
  end
end
