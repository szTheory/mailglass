defmodule Mailglass.TestSupport.DeliverabilityResolverStub do
  @moduledoc """
  Deterministic DNS resolver stub for deliverability tests.

  Fixtures are process-local so concurrent tests can configure TXT, MX, and
  CNAME answers without leaking state across runs.
  """

  @fixture_key {__MODULE__, :fixtures}
  @error_reasons [:timeout, :nxdomain, :servfail, :malformed_answer]

  @type txt_response :: {:ok, [binary()]} | {:error, atom()}
  @type mx_response :: {:ok, [%{exchange: binary(), preference: integer()}]} | {:error, atom()}
  @type cname_response :: {:ok, binary()} | {:error, atom()}

  @spec put_fixtures(keyword() | map()) :: :ok
  def put_fixtures(fixtures) when is_list(fixtures) do
    fixtures
    |> Enum.into(%{})
    |> put_fixtures()
  end

  def put_fixtures(fixtures) when is_map(fixtures) do
    fixtures
    |> normalize_fixture_map()
    |> then(&Process.put(@fixture_key, &1))

    :ok
  end

  @spec reset() :: :ok
  def reset do
    Process.delete(@fixture_key)
    :ok
  end

  @spec lookup_txt(String.t()) :: txt_response()
  def lookup_txt(domain) when is_binary(domain) do
    lookup(:txt, domain, {:error, :nxdomain})
  end

  @spec lookup_mx(String.t()) :: mx_response()
  def lookup_mx(domain) when is_binary(domain) do
    lookup(:mx, domain, {:error, :nxdomain})
  end

  @spec lookup_cname(String.t()) :: cname_response()
  def lookup_cname(domain) when is_binary(domain) do
    lookup(:cname, domain, {:error, :nxdomain})
  end

  defp lookup(kind, domain, default) do
    fixtures()
    |> Map.get(kind, %{})
    |> Map.get(domain, default)
    |> normalize_response(kind)
  end

  defp fixtures do
    Process.get(@fixture_key, %{txt: %{}, mx: %{}, cname: %{}})
  end

  defp normalize_fixture_map(fixtures) do
    %{txt: %{}, mx: %{}, cname: %{}}
    |> Map.merge(Map.take(fixtures, [:txt, :mx, :cname]))
  end

  defp normalize_response({:ok, values}, :txt) when is_list(values) do
    if Enum.all?(values, &is_binary/1), do: {:ok, values}, else: {:error, :malformed_answer}
  end

  defp normalize_response({:ok, values}, :mx) when is_list(values) do
    if Enum.all?(values, &valid_mx?/1), do: {:ok, values}, else: {:error, :malformed_answer}
  end

  defp normalize_response({:ok, value}, :cname) when is_binary(value), do: {:ok, value}

  defp normalize_response({:error, reason}, _kind) when reason in @error_reasons, do: {:error, reason}
  defp normalize_response(_response, _kind), do: {:error, :malformed_answer}

  defp valid_mx?(%{exchange: exchange, preference: preference})
       when is_binary(exchange) and is_integer(preference) do
    true
  end

  defp valid_mx?(_), do: false
end
