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

  ## What this module does NOT ship at v0.1

  - Pixel injection + link rewriting — Plan 06 (`Mailglass.Tracking.Rewriter`)
  - Phoenix.Token sign/verify — Plan 06 (`Mailglass.Tracking.Token`)
  - Plug endpoint for GIF + click redirect — Plan 06 (`Mailglass.Tracking.Plug`)

  ## `enabled?/1` helper

  Returns a `%{opens: boolean, clicks: boolean}` map for a given mailable
  module. Used by Plan 06's Rewriter to decide whether to inject pixel / rewrite
  links, and by the Guard to decide whether the auth-stream heuristic applies.
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
