defmodule MailglassInbound.Ingress.Pipeline do
  @moduledoc false

  alias MailglassInbound.Ingress.VerifiedRequest

  @type outcome ::
          {:replay}
          | {:control_plane}
          | {:persist, term(), map()}
          | {:persist_verified, term(), term(), map()}

  @doc false
  @spec run(atom(), term(), map(), keyword(), map()) :: outcome()
  def run(provider, request, config, opts, deps)
      when is_atom(provider) and is_map(config) and is_list(opts) and is_map(deps) do
    # Verification is intentionally the first effect. The remaining stages are
    # injected so this package owns their order without depending on Plug.Conn.
    case deps.verify.(provider, request, config, opts) do
      {:replay} ->
        {:replay}

      {:control_plane, _http_status} ->
        {:control_plane}

      {:ok, %VerifiedRequest{} = verified} ->
        {:persist_verified, verified, config, opts}

      {:ok, facts} when is_map(facts) ->
        {:persist, request, facts}

      facts when is_map(facts) ->
        {:persist, request, facts}
    end
  end
end
