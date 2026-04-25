defmodule Mailglass.Tracking do
  @moduledoc """
  Tracking public facade. Off by default per TRACK-01 / D-08.

  Adopters opt in per-mailable at compile time:

      use Mailglass.Mailable, tracking: [opens: true, clicks: true]

  `opens` and `clicks` are independent booleans (D-31). Apple Mail Privacy
  Protection neuters opens but not clicks — `opens: false, clicks: true` is
  a real configuration adopters will want once they understand the ecosystem.

  ## Enforcement layers (D-30 + D-38)

  1. NimbleOptions default `false` in `use` opts.
  2. Phase 6 `TRACK-02 NoTrackingOnAuthStream` Credo check at compile time.
  3. Phase 3 `Mailglass.Tracking.Guard.assert_safe!/1` at runtime (D-38).

  Adopters CAN disable tracking at runtime per-call via `tracking: false` opt
  on `deliver/2` — but they CANNOT enable it at runtime. This keeps compile-time
  AST inspection load-bearing.

  ## `enabled?/1` helper

  Returns a `%{opens: boolean, clicks: boolean}` map for a given mailable
  module. Used by `Mailglass.Tracking.Rewriter` to decide whether to inject
  pixel / rewrite links, and by the Guard to decide whether the auth-stream
  heuristic applies.

  ## `rewrite_if_enabled/1` post-render hook

  Reads tracking flags for the message's mailable and calls
  `Mailglass.Tracking.Rewriter.rewrite/2` when any flag is true. Returns
  the message unchanged when tracking is disabled (D-10). Never touches
  `text_body` (D-36).
  """

  @type tracking_flags :: %{opens: boolean(), clicks: boolean()}

  @doc """
  Returns the tracking flags for a given mailable module.

  Reads `module.__mailglass_opts__()` to inspect the compile-time `tracking:`
  opts. Returns `%{opens: false, clicks: false}` for modules that do not use
  `Mailglass.Mailable` (off-by-default semantics, TRACK-01).

  ## Examples

      iex> Mailglass.Tracking.enabled?(mailable: MyApp.UserMailer)
      %{opens: false, clicks: false}

      iex> Mailglass.Tracking.enabled?(mailable: MyApp.CampaignMailer)
      %{opens: true, clicks: true}

  """
  @doc since: "0.1.0"
  @spec enabled?(mailable: module()) :: tracking_flags()
  def enabled?(opts) when is_list(opts) do
    mailable = Keyword.fetch!(opts, :mailable)
    fetch_from_mailable(mailable)
  end

  @doc """
  Post-render hook: calls `Mailglass.Tracking.Rewriter.rewrite/2` when the
  mailable has any tracking flag enabled. Called by the Outbound pipeline
  (or adopters invoking manually) after `Mailglass.Renderer.render/1`.

  When no flags are set, returns the message unchanged. Never touches
  `text_body` (D-36).

  `delivery_id` is read from `message.metadata[:delivery_id]`; falls back
  to `"pre-delivery"` when not yet stamped (render-preview mode).
  """
  @doc since: "0.1.0"
  @spec rewrite_if_enabled(Mailglass.Message.t()) :: Mailglass.Message.t()
  def rewrite_if_enabled(%Mailglass.Message{mailable: nil} = msg), do: msg

  def rewrite_if_enabled(%Mailglass.Message{mailable: mod} = msg) when is_atom(mod) do
    flags = enabled?(mailable: mod)

    if flags.opens or flags.clicks do
      delivery_id = Map.get(msg.metadata || %{}, :delivery_id, "pre-delivery")
      tenant_id = msg.tenant_id || "default"

      new_html =
        Mailglass.Tracking.Rewriter.rewrite(
          msg.swoosh_email.html_body || "",
          flags: flags,
          delivery_id: delivery_id,
          tenant_id: tenant_id
        )

      Mailglass.Message.update_swoosh(msg, &Swoosh.Email.html_body(&1, new_html))
    else
      msg
    end
  end

  @doc """
  Resolves the Phoenix.Token endpoint used to sign and verify tracking tokens.

  Resolution order (HI-02 fix — identical chain in Rewriter and Plug):
  1. `config :mailglass, :tracking, endpoint: MyApp.Endpoint`
  2. `config :mailglass, :adapter_endpoint, MyApp.Endpoint`
  3. Raises `%Mailglass.ConfigError{type: :tracking_endpoint_missing}` if neither is set

  Both `Mailglass.Tracking.Rewriter` and `Mailglass.Tracking.Plug` call this function
  so that sign and verify always use the same key material.
  """
  @doc since: "0.1.0"
  @spec endpoint() :: module() | binary()
  def endpoint do
    Application.get_env(:mailglass, :tracking, [])[:endpoint] ||
      Application.get_env(:mailglass, :adapter_endpoint) ||
      raise Mailglass.ConfigError.new(:tracking_endpoint_missing,
              context: %{
                hint: "config :mailglass, :tracking, endpoint: MyApp.Endpoint"
              }
            )
  end

  defp fetch_from_mailable(mailable) when is_atom(mailable) do
    # Ensure the module is loaded before probing — compiled .beam files are
    # loaded lazily by the BEAM. This matters in async test contexts where a
    # module may be compiled but not yet loaded in the calling process.
    Code.ensure_loaded(mailable)

    if function_exported?(mailable, :__mailglass_opts__, 0) do
      use_opts = mailable.__mailglass_opts__()
      tracking = Keyword.get(use_opts, :tracking, [])

      %{
        opens: Keyword.get(tracking, :opens, false),
        clicks: Keyword.get(tracking, :clicks, false)
      }
    else
      %{opens: false, clicks: false}
    end
  end
end
