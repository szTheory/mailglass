defmodule Mailglass.Compliance do
  @moduledoc """
  Injects RFC-required and mailglass-specific headers into outbound messages.

  Phase 1 ships functional stubs for the v0.1 RFC floor:

    * `Date` — RFC 2822 format; injected if absent.
    * `Message-ID` — RFC 5322 unique identifier; injected if absent.
    * `MIME-Version` — always `"1.0"`; injected if absent.
    * `Mailglass-Mailable` — `"Module.function/arity"`; injected if absent.

  Full RFC 8058 `List-Unsubscribe` + `List-Unsubscribe-Post` lands in v0.5
  (DELIV-01). `Feedback-ID` gets its full shape once tenant-scoped streams land
  in Phase 2.

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

  # --- Private helpers ---

  defp maybe_add_date(%Swoosh.Email{} = email) do
    if has_header?(email, "Date") do
      email
    else
      put_header(email, "Date", format_rfc2822_date(DateTime.utc_now()))
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
  # (typically threaded through the Outbound pipeline in Phase 3).
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
