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
        host

      :default ->
        Config.compliance_host() ||
          raise ConfigError.new(:missing,
                  context: %{
                    key: :compliance_host
                  }
                )
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

  defp iterate_contexts([], _fun), do: {:error, :invalid}

  defp iterate_contexts([context | rest], fun) do
    case fun.(context) do
      {:halt, result} -> result
      :cont -> iterate_contexts(rest, fun)
    end
  end
end
