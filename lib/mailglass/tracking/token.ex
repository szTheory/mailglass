defmodule Mailglass.Tracking.Token do
  @moduledoc """
  Phoenix.Token-signed tokens for open pixel + click redirect URLs (TRACK-03, D-33..D-35).

  ## Token shape (D-34 + D-35)

  Open pixel payload: `{:open, delivery_id, tenant_id}`
  Click redirect payload: `{:click, delivery_id, tenant_id, target_url}`

  ## Open-redirect prevention (D-35 pattern a)

  Target URL lives INSIDE the signed token, NEVER as a query parameter.
  The class of CVE that Mailchimp shipped in 2019 + 2022
  (open-redirect via weak parameter validation) is structurally
  unreachable — there is no parameter to tamper with. A tampered
  token fails Phoenix.Token's HMAC check → `:error`.

  Target URL scheme is validated at SIGN time (not just verify time) —
  `http` or `https` only. Attempting to sign a `javascript:` or `ftp:`
  URL raises `%Mailglass.ConfigError{type: :invalid}`.

  ## Salts rotation (D-33)

  `config :mailglass, :tracking, salts: ["q2-2026", "q1-2026"]`. The
  HEAD of the list signs; ALL salts in the list verify (iterate with
  early return). Rotating = prepending a new salt; old salts verify
  until removed from the list. Token max_age default: 2 years
  (archived-email pixel loads still work).

  ## `tenant_id` in payload, not URL (D-39)

  Decoded `tenant_id` comes from the SIGNED PAYLOAD, not from URL
  path/query. Phase 3 Plug uses it to call `Tenancy.put_current/1`.
  URL path + query leak to referrer headers, shared-link screenshots,
  corporate proxy logs; the signed payload is the only privacy-preserving
  option.
  """

  alias Mailglass.ConfigError

  @sign_opts [key_iterations: 1000, key_length: 32, digest: :sha256]

  @doc """
  Signs an open-pixel token. Payload: `{:open, delivery_id, tenant_id}`.

  Uses the HEAD of `config :mailglass, :tracking, salts:` to sign.
  Raises `%Mailglass.ConfigError{type: :missing}` if no salts are configured.
  """
  @doc since: "0.1.0"
  @spec sign_open(endpoint :: atom() | binary(), delivery_id :: String.t(), tenant_id :: String.t()) ::
          binary()
  def sign_open(endpoint, delivery_id, tenant_id)
      when is_binary(delivery_id) and is_binary(tenant_id) do
    Phoenix.Token.sign(endpoint, head_salt!(), {:open, delivery_id, tenant_id}, @sign_opts)
  end

  @doc """
  Verifies an open-pixel token. Returns `{:ok, %{delivery_id, tenant_id}}`
  on success or `:error` on any failure (expired, tampered, unknown salt).

  Iterates over ALL configured salts to support rotation windows.
  """
  @doc since: "0.1.0"
  @spec verify_open(endpoint :: atom() | binary(), binary()) ::
          {:ok, %{delivery_id: String.t(), tenant_id: String.t()}} | :error
  def verify_open(endpoint, token) when is_binary(token) do
    iterate_salts(salts(), fn salt ->
      case Phoenix.Token.verify(endpoint, salt, token, verify_opts()) do
        {:ok, {:open, d, t}} when is_binary(d) and is_binary(t) ->
          {:halt, {:ok, %{delivery_id: d, tenant_id: t}}}

        _ ->
          :cont
      end
    end)
  end

  @doc """
  Signs a click-redirect token. Payload:
  `{:click, delivery_id, tenant_id, target_url}`.

  Raises `%Mailglass.ConfigError{type: :invalid}` if `target_url`
  scheme is not `http` or `https`.
  """
  @doc since: "0.1.0"
  @spec sign_click(endpoint :: atom() | binary(), String.t(), String.t(), String.t()) :: binary()
  def sign_click(endpoint, delivery_id, tenant_id, target_url)
      when is_binary(delivery_id) and is_binary(tenant_id) and is_binary(target_url) do
    validate_target!(target_url)

    Phoenix.Token.sign(
      endpoint,
      head_salt!(),
      {:click, delivery_id, tenant_id, target_url},
      @sign_opts
    )
  end

  @doc """
  Verifies a click-redirect token. Returns
  `{:ok, %{delivery_id, tenant_id, target_url}}` or `:error`.

  Verified target_url is ALWAYS scheme ∈ ["http", "https"] (scheme was
  validated at sign time; tampered tokens fail HMAC first; defense-in-depth
  re-check at verify time per T-3-07-10).
  """
  @doc since: "0.1.0"
  @spec verify_click(endpoint :: atom() | binary(), binary()) ::
          {:ok, %{delivery_id: String.t(), tenant_id: String.t(), target_url: String.t()}}
          | :error
  def verify_click(endpoint, token) when is_binary(token) do
    iterate_salts(salts(), fn salt ->
      case Phoenix.Token.verify(endpoint, salt, token, verify_opts()) do
        {:ok, {:click, d, t, url}} when is_binary(d) and is_binary(t) and is_binary(url) ->
          # Defense-in-depth: re-validate scheme at verify time (T-3-07-10).
          case URI.parse(url).scheme do
            s when s in ["http", "https"] ->
              {:halt, {:ok, %{delivery_id: d, tenant_id: t, target_url: url}}}

            _ ->
              :cont
          end

        _ ->
          :cont
      end
    end)
  end

  # --- Private helpers ---

  defp validate_target!(target_url) do
    case URI.parse(target_url).scheme do
      s when s in ["http", "https"] ->
        :ok

      _ ->
        raise ConfigError.new(:invalid,
                context: %{rejected_url: target_url, reason: :scheme}
              )
    end
  end

  defp salts do
    case Application.get_env(:mailglass, :tracking, [])[:salts] do
      [_ | _] = s ->
        s

      _ ->
        raise ConfigError.new(:missing,
                context: %{
                  key: :tracking_salts,
                  hint: "config :mailglass, :tracking, salts: [\"salt-1\", ...]"
                }
              )
    end
  end

  defp head_salt! do
    [head | _] = salts()
    head
  end

  defp verify_opts do
    max_age = Application.get_env(:mailglass, :tracking, [])[:max_age] || 2 * 365 * 86_400
    Keyword.put(@sign_opts, :max_age, max_age)
  end

  defp iterate_salts([], _fun), do: :error

  defp iterate_salts([salt | rest], fun) do
    case fun.(salt) do
      {:halt, result} -> result
      :cont -> iterate_salts(rest, fun)
    end
  end
end
