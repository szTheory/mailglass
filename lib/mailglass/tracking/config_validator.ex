defmodule Mailglass.Tracking.ConfigValidator do
  @moduledoc """
  Boot-time validator for TRACK-03 configuration (D-32).

  When ANY loaded mailable module has `tracking: [opens: true]` or
  `tracking: [clicks: true]` in its `@mailglass_opts`, the
  `config :mailglass, :tracking, host:` key is REQUIRED. Boot fails
  with `%Mailglass.ConfigError{type: :tracking_host_missing}` on
  omission.

  ## Adopter usage (v0.1)

  Call from your `Application.start/2` callback after
  `Mailglass.Config.validate_at_boot!/0`:

      def start(_type, _args) do
        Mailglass.Config.validate_at_boot!()
        Mailglass.Tracking.ConfigValidator.validate_at_boot!()
        # ...
      end

  v0.5 will auto-wire this into `Mailglass.Config.validate_at_boot!/0`.

  ## Detection algorithm

  Walks `:code.all_loaded/0` checking for modules that export both
  `__mailglass_mailable__/0` (discovery marker) and `__mailglass_opts__/0`
  (compile-time opts reflection). Any module with `opens: true` or
  `clicks: true` in its `:tracking` opts triggers the host check.
  """

  @doc """
  Raises `%Mailglass.ConfigError{type: :tracking_host_missing}` if any
  loaded `Mailglass.Mailable` module has tracking enabled AND
  `:tracking, :host` is unset or empty.

  Returns `:ok` otherwise.
  """
  @doc since: "0.1.0"
  @spec validate_at_boot!() :: :ok
  def validate_at_boot! do
    if any_mailable_has_tracking?() and tracking_host_missing?() do
      raise Mailglass.ConfigError.new(:tracking_host_missing, context: %{})
    end

    :ok
  end

  # --- Private helpers ---

  defp any_mailable_has_tracking? do
    :code.all_loaded()
    |> Enum.any?(fn {mod, _} ->
      function_exported?(mod, :__mailglass_mailable__, 0) and
        function_exported?(mod, :__mailglass_opts__, 0) and
        tracking_enabled?(mod.__mailglass_opts__())
    end)
  end

  defp tracking_enabled?(opts) do
    t = Keyword.get(opts, :tracking, [])
    Keyword.get(t, :opens, false) or Keyword.get(t, :clicks, false)
  end

  defp tracking_host_missing? do
    case Application.get_env(:mailglass, :tracking, [])[:host] do
      nil -> true
      "" -> true
      _ -> false
    end
  end
end
