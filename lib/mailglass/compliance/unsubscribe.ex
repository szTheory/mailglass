defmodule Mailglass.Compliance.Unsubscribe do
  @moduledoc """
  Core unsubscribe token and URL service for RFC 8058 flows.

  Tokens carry only the `delivery_id`. Verification tries the current
  compliance endpoint/secret first, then each configured previous raw secret
  to survive `secret_key_base` rotation without breaking in-flight links.
  """

  alias Mailglass.Config
  alias Mailglass.ConfigError
  alias Mailglass.Tenancy

  @salt "mailglass_unsubscribe_v1"
  @max_url_bytes 900
  @sign_opts [key_iterations: 1000, key_length: 32, key_digest: :sha256]

  @type verify_result :: {:ok, %{delivery_id: String.t()}} | {:error, :expired | :invalid}

  @doc """
  Signs a delivery-only unsubscribe token with the current endpoint/secret.
  """
  @doc since: "0.2.0"
  @spec sign_token(String.t()) :: binary()
  def sign_token(delivery_id) when is_binary(delivery_id) do
    Phoenix.Token.sign(Config.compliance_endpoint(), @salt, delivery_id, @sign_opts)
  end

  @doc """
  Verifies an unsubscribe token against the current endpoint first and then any
  configured previous raw secrets.
  """
  @doc since: "0.2.0"
  @spec verify_token(binary()) :: verify_result
  def verify_token(token) when is_binary(token) do
    contexts = [Config.compliance_endpoint() | Config.compliance_previous_secrets()]

    iterate_contexts(contexts, fn context ->
      case Phoenix.Token.verify(context, @salt, token, verify_opts()) do
        {:ok, delivery_id} when is_binary(delivery_id) ->
          {:halt, {:ok, %{delivery_id: delivery_id}}}

        {:error, :expired} ->
          {:halt, {:error, :expired}}

        {:error, :invalid} ->
          :cont

        {:error, :missing} ->
          :cont
      end
    end)
  end

  @doc """
  Builds the canonical unsubscribe URL for a delivery.

  Raises `%Mailglass.ConfigError{}` before returning if the generated URL
  exceeds #{@max_url_bytes} bytes.
  """
  @doc since: "0.2.0"
  @spec unsubscribe_url(String.t(), map()) :: String.t()
  def unsubscribe_url(delivery_id, context \\ %{})

  def unsubscribe_url(delivery_id, context) when is_binary(delivery_id) and is_map(context) do
    token = sign_token(delivery_id)
    scheme = Config.compliance_scheme()
    host = resolve_host!(context)
    mount_path = normalize_mount_path(Config.compliance_mount_path())
    url = "#{scheme}://#{host}#{mount_path}/#{token}"

    if byte_size(url) > @max_url_bytes do
      raise ConfigError.new(:invalid,
              context: %{
                key: :compliance_mount_path,
                reason: :unsubscribe_url_too_long,
                max_bytes: @max_url_bytes
              }
            )
    end

    url
  end

  defp resolve_host!(context) do
    case Tenancy.compliance_host(context) do
      {:ok, host} when is_binary(host) and host != "" ->
        validate_host!(host)

      :default ->
        Config.compliance_host()
        |> case do
          nil ->
            raise ConfigError.new(:missing,
                    context: %{
                      key: :compliance_host
                    }
                  )

          host ->
            validate_host!(host)
        end
    end
  end

  defp normalize_mount_path(path) when is_binary(path) do
    normalized =
      path
      |> String.trim()
      |> String.trim_trailing("/")
      |> String.trim_leading("/")

    "/" <> normalized
  end

  defp verify_opts do
    Keyword.put(@sign_opts, :max_age, Config.compliance_max_age())
  end

  defp validate_host!(host) when is_binary(host) do
    trimmed = String.trim(host)

    uri = URI.parse("https://#{trimmed}")

    cond do
      trimmed == "" ->
        raise_invalid_host!()

      trimmed != host ->
        raise_invalid_host!()

      String.match?(trimmed, ~r/\s/u) ->
        raise_invalid_host!()

      String.contains?(trimmed, ["/", "?", "#", "@"]) ->
        raise_invalid_host!()

      String.contains?(trimmed, ["://", "\\"]) ->
        raise_invalid_host!()

      is_nil(uri.host) or uri.host != trimmed or uri.path not in [nil, ""] ->
        raise_invalid_host!()

      local_or_private_host?(trimmed) ->
        raise_invalid_host!()

      true ->
        trimmed
    end
  end

  @spec raise_invalid_host!() :: no_return()
  defp raise_invalid_host! do
    raise ConfigError.new(:invalid,
            context: %{
              key: :compliance_host
            }
          )
  end

  defp local_or_private_host?(host) do
    downcased = String.downcase(host)

    downcased == "localhost" or
      private_ipv4?(downcased) or
      private_ipv6?(downcased)
  end

  defp private_ipv4?(host) do
    case :inet.parse_ipv4strict_address(String.to_charlist(host)) do
      {:ok, {a, b, c, d}} ->
        _ = c
        _ = d

        a == 10 or
          a == 127 or
          (a == 169 and b == 254) or
          (a == 172 and b in 16..31) or
          (a == 192 and b == 168)

      {:error, _reason} ->
        false
    end
  end

  defp private_ipv6?(host) do
    normalized =
      host
      |> String.trim_leading("[")
      |> String.trim_trailing("]")

    case :inet.parse_ipv6strict_address(String.to_charlist(normalized)) do
      {:ok, tuple} ->
        tuple == {0, 0, 0, 0, 0, 0, 0, 1} or
          tuple == {0, 0, 0, 0, 0, 0, 0, 0} or
          match?({0xFE80, _, _, _, _, _, _, _}, tuple) or
          match?({0xFC00, _, _, _, _, _, _, _}, tuple) or
          match?({0xFD00, _, _, _, _, _, _, _}, tuple)

      {:error, _reason} ->
        false
    end
  end

  defp iterate_contexts([], _fun), do: {:error, :invalid}

  defp iterate_contexts([context | rest], fun) do
    case fun.(context) do
      {:halt, result} -> result
      :cont -> iterate_contexts(rest, fun)
    end
  end
end
