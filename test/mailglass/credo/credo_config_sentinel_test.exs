defmodule Mailglass.Credo.CredoConfigSentinelTest do
  use ExUnit.Case, async: true

  # Config sentinel: pins the load-bearing .credo.exs keys that make the CR-01
  # and WR-02 guards actually fire against real config. Behavior tests pass
  # against hand-passed params; this test proves the SHIPPED config carries the
  # same params, so the two cannot drift apart silently.
  #
  # CR-01: gen_smtp is an Erlang lib with no `GenSmtp` Elixir module — its surface
  #        is reached via bare atoms, so NoBareOptionalDepReference's gated_modules
  #        MUST be keyed on :mimemail and :gen_smtp_client.
  # WR-02: TelemetryEventConvention's required_root must include :mailglass_inbound
  #        so the convention check covers the inbound sibling package's events.

  setup_all do
    {config, _binding} = Code.eval_file(".credo.exs")
    {:ok, checks: load_checks(config)}
  end

  test "NoBareOptionalDepReference gates :mimemail and :gen_smtp_client (CR-01)", %{checks: checks} do
    params = find_check(checks, Mailglass.Credo.NoBareOptionalDepReference)

    assert is_list(params),
           "NoBareOptionalDepReference is not configured in .credo.exs"

    gated = Keyword.get(params, :gated_modules) || %{}

    assert Map.has_key?(gated, :mimemail),
           "CR-01 regression: .credo.exs NoBareOptionalDepReference gated_modules is missing the :mimemail atom key"

    assert Map.has_key?(gated, :gen_smtp_client),
           "CR-01 regression: .credo.exs NoBareOptionalDepReference gated_modules is missing the :gen_smtp_client atom key"
  end

  test "TelemetryEventConvention required_root includes :mailglass_inbound (WR-02)", %{checks: checks} do
    params = find_check(checks, Mailglass.Credo.TelemetryEventConvention)

    assert is_list(params),
           "TelemetryEventConvention is not configured in .credo.exs"

    roots = params |> Keyword.get(:required_root) |> List.wrap()

    assert :mailglass_inbound in roots,
           "WR-02 regression: .credo.exs TelemetryEventConvention required_root is missing :mailglass_inbound"
  end

  # Normalize the first config's :checks into a flat list of {module, params} tuples.
  # The value may be a flat keyword-style list or grouped under
  # :enabled / :extra / :disabled keys — handle both.
  defp load_checks(config) do
    config
    |> Map.fetch!(:configs)
    |> hd()
    |> Map.fetch!(:checks)
    |> flatten_checks()
  end

  defp flatten_checks(checks) when is_list(checks) do
    if Keyword.keyword?(checks) and
         Enum.all?(Keyword.keys(checks), &(&1 in [:enabled, :extra, :disabled])) and
         checks != [] do
      checks
      |> Keyword.values()
      |> List.flatten()
    else
      checks
    end
  end

  defp find_check(checks, module) do
    Enum.find_value(checks, fn
      {^module, params} -> params
      _ -> nil
    end)
  end
end
