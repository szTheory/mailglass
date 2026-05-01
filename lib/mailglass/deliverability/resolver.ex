defmodule Mailglass.Deliverability.Resolver do
  @moduledoc """
  Mailglass-owned DNS resolver seam for deliverability checks.

  The default implementation uses OTP `:inet_res` and normalizes DNS answers
  into binaries and maps only. Callers never receive raw charlists or
  `:dns_rec` tuples across the boundary.
  """

  @type reason :: :timeout | :nxdomain | :servfail | :malformed_answer | :not_found
  @type mx_record :: %{exchange: binary(), preference: integer()}

  @doc """
  Looks up TXT records for one domain.
  """
  @callback lookup_txt(String.t()) :: {:ok, [binary()]} | {:error, reason()}

  @doc """
  Looks up MX records for one domain.
  """
  @callback lookup_mx(String.t()) :: {:ok, [mx_record()]} | {:error, reason()}

  @doc """
  Looks up one CNAME target for one domain.
  """
  @callback lookup_cname(String.t()) :: {:ok, binary()} | {:error, reason()}

  @behaviour __MODULE__

  @impl true
  def lookup_txt(domain) when is_binary(domain) do
    with {:ok, answers} <- resolve_answers(domain, :txt) do
      normalize_txt_answers(answers)
    end
  end

  @impl true
  def lookup_mx(domain) when is_binary(domain) do
    with {:ok, answers} <- resolve_answers(domain, :mx) do
      normalize_mx_answers(answers)
    end
  end

  @impl true
  def lookup_cname(domain) when is_binary(domain) do
    with {:ok, answers} <- resolve_answers(domain, :cname) do
      normalize_cname_answers(answers)
    end
  end

  defp resolve_answers(domain, type) do
    host = String.to_charlist(domain)

    try do
      case :inet_res.resolve(host, :in, type) do
        {:ok, dns_rec} ->
          {:ok, answer_records(dns_rec, type)}

        {:error, reason} ->
          {:error, normalize_reason(reason)}
      end
    rescue
      ArgumentError ->
        {:error, :malformed_answer}
    catch
      :exit, {:timeout, _} -> {:error, :timeout}
      :exit, _ -> {:error, :servfail}
      :error, _ -> {:error, :malformed_answer}
    end
  end

  defp answer_records({:dns_rec, _header, _queries, answers, _authority, _additional}, type) do
    Enum.filter(answers, fn
      {:dns_rr, _domain, ^type, :in, _class, _ttl, _data, _bm, _func, _cnt} -> true
      _ -> false
    end)
  end

  defp normalize_txt_answers(answers) do
    answers
    |> Enum.reduce_while({:ok, []}, fn answer, {:ok, acc} ->
      case answer do
        {:dns_rr, _domain, :txt, :in, _class, _ttl, values, _bm, _func, _cnt}
        when is_list(values) ->
          normalized =
            values
            |> Enum.map(&charlist_to_binary/1)
            |> Enum.join("")

          {:cont, {:ok, acc ++ [normalized]}}

        _ ->
          {:halt, {:error, :malformed_answer}}
      end
    end)
  end

  defp normalize_mx_answers(answers) do
    answers
    |> Enum.reduce_while({:ok, []}, fn answer, {:ok, acc} ->
      case answer do
        {:dns_rr, _domain, :mx, :in, _class, _ttl, {preference, exchange}, _bm, _func, _cnt}
        when is_integer(preference) ->
          {:cont,
           {:ok,
            acc ++
              [
                %{
                  exchange: charlist_to_binary(exchange),
                  preference: preference
                }
              ]}}

        _ ->
          {:halt, {:error, :malformed_answer}}
      end
    end)
  end

  defp normalize_cname_answers([]), do: {:error, :not_found}

  defp normalize_cname_answers([answer]) do
    case answer do
      {:dns_rr, _domain, :cname, :in, _class, _ttl, target, _bm, _func, _cnt} ->
        {:ok, charlist_to_binary(target)}

      _ ->
        {:error, :malformed_answer}
    end
  end

  defp normalize_cname_answers(_answers), do: {:error, :malformed_answer}

  defp normalize_reason(:timeout), do: :timeout
  defp normalize_reason(:nxdomain), do: :nxdomain
  defp normalize_reason(:servfail), do: :servfail
  defp normalize_reason(:formerr), do: :malformed_answer
  defp normalize_reason(:timeout_error), do: :timeout
  defp normalize_reason(_reason), do: :servfail

  defp charlist_to_binary(value) when is_list(value), do: List.to_string(value)
  defp charlist_to_binary(value) when is_binary(value), do: value
  defp charlist_to_binary(_value), do: raise(ArgumentError)
end
