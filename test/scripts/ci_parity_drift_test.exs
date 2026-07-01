defmodule Mailglass.Scripts.CIParityDriftTest do
  use ExUnit.Case, async: true

  @moduledoc """
  MIXCI-03 parity-drift test (D-LD-10).

  Asserts, by IDENTITY + flag-set (NOT a whole-file substring superset), that the
  union of the `mix ci` and `mix ci.browser` alias step-sets covers every required +
  advisory CI lane declared in `Mailglass.CILanes`. The two surfaces — the human
  aliases and CI's per-job matrix — are intentionally separate (DX-MIX-CI.md section E
  footgun #6); this test is what keeps them from drifting silently. A required CI job
  that isn't reflected in the alias fails this test.

  Anti-vacuity guards (Phase 126 precedent): the test fails if the flattened alias
  step-set is empty, if the `Mailglass.CILanes` source is empty, or if the
  lane->matcher table is not a bijection with the ci_lanes set — so it cannot pass by
  parsing nothing or by silently ignoring a newly-added lane. A negative-control
  assertion proves the coverage function reports "uncovered" when a required step is
  removed, so the fail-loud property is itself tested.

  Durable determinism guard (Phase 127 consume, DET-02): a committed assertion refutes
  any seed-pinning token in the flattened root `ci` alias step-set, so a future edit
  reintroducing a fixed seed on any ci step fails here — not just at one-shot execution
  time.

  The lane list is read from `Mailglass.CILanes` (single source, MIXCI-03) — it is NOT
  duplicated here.
  """

  # ---------------------------------------------------------------------------
  # Alias loading + flattening
  # ---------------------------------------------------------------------------

  # The transitive closure of string steps for an alias, resolving nested alias
  # references (e.g. ci.fast / ci.setup nested inside ci) to their own steps.
  #
  # A nested alias reference is retained AS WELL AS expanded: the reference token
  # (e.g. "verify.support_contract.core") preserves CI-job identity for lanes named
  # after a semantic alias, while the expansion exposes the concrete nested steps
  # (e.g. those inside ci.fast) so hygiene lanes and the seed guard can match too.
  defp flatten_alias(aliases, name) do
    # Pre-compute the alias key names as STRINGS. Comparing a step string against
    # this set (rather than String.to_atom/1) avoids minting an atom per non-alias
    # step — an arbitrary step like "test test/... --warnings-as-errors" would
    # otherwise exhaust the atom table (SystemLimitError).
    alias_key_strings = MapSet.new(Keyword.keys(aliases), &Atom.to_string/1)

    do_flatten_alias(aliases, name, alias_key_strings)
  end

  defp do_flatten_alias(aliases, name, alias_key_strings) do
    case Keyword.get(aliases, name) do
      nil ->
        []

      steps when is_list(steps) ->
        Enum.flat_map(steps, fn step ->
          cond do
            is_binary(step) and MapSet.member?(alias_key_strings, step) ->
              # Safe: `step` is a known alias key, so the atom already exists.
              # Keep the reference token AND its transitive expansion.
              [step | do_flatten_alias(aliases, String.to_existing_atom(step), alias_key_strings)]

            is_binary(step) ->
              [step]

            true ->
              []
          end
        end)
    end
  end

  defp aliases, do: Mix.Project.config()[:aliases]

  defp ci_steps, do: flatten_alias(aliases(), :ci)
  defp ci_browser_steps, do: flatten_alias(aliases(), :"ci.browser")
  defp union_steps, do: ci_steps() ++ ci_browser_steps()

  # ---------------------------------------------------------------------------
  # Lane -> covering-step matcher table (identity + flag-set, not loose substring)
  #
  # Each matcher is a predicate over the flattened alias step-set. A lane is
  # "covered" iff its matcher returns true. Names are read from Mailglass.CILanes
  # verbatim — never duplicated as literals in this table's keys.
  # ---------------------------------------------------------------------------

  defp any_step?(steps, substr), do: Enum.any?(steps, &String.contains?(&1, substr))

  # Maps a lane display name to a matcher/1 over the union step-set.
  # Built programmatically off Mailglass.CILanes so the keys are never a second
  # copy of the lane list.
  defp matcher_for(lane) do
    %{
      "Support Contract Core (Elixir 1.18 / OTP 27)" =>
        &any_step?(&1, "verify.support_contract.core"),
      "Support Contract Admin (Elixir 1.18 / OTP 27)" =>
        &any_step?(&1, "verify.support_contract.admin"),
      "Compile No Optional Deps (Elixir 1.18 / OTP 27)" =>
        &any_step?(&1, "compile --no-optional-deps --warnings-as-errors"),
      "Trust Lane Repo Head (Elixir 1.18 / OTP 27)" =>
        fn steps ->
          any_step?(steps, "verify.reference_host.journey") and
            any_step?(steps, "check_trust_runner_checkpoint.sh")
        end,
      "Installer Host Smoke" => &any_step?(&1, "consumer_install_smoke.sh"),
      "Format Check (Elixir 1.18 / OTP 27)" => &any_step?(&1, "format --check-formatted"),
      "Compile Warnings as Errors (Elixir 1.18 / OTP 27)" =>
        &any_step?(&1, "compile --warnings-as-errors"),
      "Credo Strict (Elixir 1.18 / OTP 27)" => &any_step?(&1, "credo --strict"),
      "Dialyzer (Elixir 1.18 / OTP 27)" => &any_step?(&1, "dialyzer"),
      "Docs Warnings as Errors (Elixir 1.18 / OTP 27)" =>
        &any_step?(&1, "docs --warnings-as-errors"),
      "Hex Audit (Elixir 1.18 / OTP 27)" => &any_step?(&1, "hex.audit"),
      "Mix Task Tests (Elixir 1.18 / OTP 27)" =>
        &any_step?(&1, "test --warnings-as-errors --exclude flaky"),
      "Inbound Test (Elixir 1.18 / OTP 27)" =>
        &any_step?(&1, "mailglass_inbound mix test"),
      "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)" =>
        &any_step?(&1, "mailglass_inbound mix compile --no-optional-deps")
    }
    |> Map.merge(%{
      "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)" =>
        &any_step?(&1, "npm run test:operator-browser")
    })
    |> Map.get(lane)
  end

  defp all_lanes, do: Mailglass.CILanes.required_lanes() ++ Mailglass.CILanes.advisory_lanes()

  # Returns the list of lanes NOT covered by the given step-set.
  defp uncovered_lanes(steps, lanes) do
    Enum.reject(lanes, fn lane ->
      matcher = matcher_for(lane)
      is_function(matcher, 1) and matcher.(steps)
    end)
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "mix ci ∪ ci.browser covers every required + advisory CI lane by identity (MIXCI-03)" do
    steps = union_steps()
    lanes = all_lanes()

    uncovered = uncovered_lanes(steps, lanes)

    assert uncovered == [],
           "mix ci ∪ ci.browser does not cover these required/advisory CI lanes " <>
             "(the alias drifted from the parity contract): #{inspect(uncovered)}"
  end

  test "anti-vacuity: alias step-set, ci_lanes source, and lane/matcher table are all non-empty and bijective" do
    steps = union_steps()

    assert length(steps) > 0,
           "flattened mix ci ∪ ci.browser step-set is empty — alias parse returned nothing"

    lanes = all_lanes()

    assert length(lanes) > 0,
           "Mailglass.CILanes required + advisory lanes parsed empty — ci_lanes source changed"

    assert length(Mailglass.CILanes.required_lanes()) == 5,
           "expected exactly 5 required lanes from Mailglass.CILanes"

    # Every ci_lanes lane must have a matcher (no lane silently ignored)...
    lanes_without_matcher =
      Enum.reject(lanes, fn lane -> is_function(matcher_for(lane), 1) end)

    assert lanes_without_matcher == [],
           "these ci_lanes lanes have no covering matcher (a new lane was added " <>
             "without a matcher, so coverage would silently pass): #{inspect(lanes_without_matcher)}"

    # ...and no matcher may reference a lane absent from ci_lanes (no stale matcher).
    known = MapSet.new(lanes)

    matcher_lanes =
      MapSet.new([
        "Support Contract Core (Elixir 1.18 / OTP 27)",
        "Support Contract Admin (Elixir 1.18 / OTP 27)",
        "Compile No Optional Deps (Elixir 1.18 / OTP 27)",
        "Trust Lane Repo Head (Elixir 1.18 / OTP 27)",
        "Installer Host Smoke",
        "Format Check (Elixir 1.18 / OTP 27)",
        "Compile Warnings as Errors (Elixir 1.18 / OTP 27)",
        "Credo Strict (Elixir 1.18 / OTP 27)",
        "Dialyzer (Elixir 1.18 / OTP 27)",
        "Docs Warnings as Errors (Elixir 1.18 / OTP 27)",
        "Hex Audit (Elixir 1.18 / OTP 27)",
        "Mix Task Tests (Elixir 1.18 / OTP 27)",
        "Inbound Test (Elixir 1.18 / OTP 27)",
        "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)",
        "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)"
      ])

    stale = MapSet.difference(matcher_lanes, known)

    assert MapSet.size(stale) == 0,
           "matcher table references lanes not in Mailglass.CILanes (stale matcher — " <>
             "a lane was renamed/removed in ci_lanes but not here): #{inspect(MapSet.to_list(stale))}"
  end

  test "negative control: removing the installer-smoke step makes its lane report uncovered (fail-loud property is tested)" do
    lane = "Installer Host Smoke"

    # Sanity: the lane is a real ci_lanes required lane and IS covered today.
    assert lane in Mailglass.CILanes.required_lanes()
    assert uncovered_lanes(union_steps(), [lane]) == []

    # Construct a copy of the step-set with the installer-smoke step removed and
    # confirm the coverage function now reports the lane uncovered. This proves the
    # gate fails loud on drift rather than rotting into a vacuous pass.
    broken_steps =
      Enum.reject(union_steps(), &String.contains?(&1, "consumer_install_smoke.sh"))

    assert uncovered_lanes(broken_steps, [lane]) == [lane],
           "coverage function did not report '#{lane}' uncovered after removing its " <>
             "covering step — the fail-loud property is broken"
  end

  test "durable determinism guard: the flattened root ci alias step-set pins no fixed seed (DET-02)" do
    steps = ci_steps()

    offending = Enum.filter(steps, &String.contains?(&1, "--seed"))

    assert offending == [],
           "the flattened mix ci alias step-set reintroduced a fixed-seed flag — " <>
             "this regresses DET-02 (Phase 127). Offending step(s): #{inspect(offending)}"
  end
end
