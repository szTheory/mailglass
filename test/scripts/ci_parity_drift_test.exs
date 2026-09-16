defmodule Mailglass.Scripts.CIParityDriftTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @required_contract_step "test test/scripts/ --exclude phase_164_proposal_boundary --exclude phase_164_installed_production_boundary --exclude phase_165_installed_production_boundary --exclude phase_165_controlled_host --warnings-as-errors"
  @installed_boundary_step "test test/scripts/phase_164_closeout_test.exs --only phase_164_installed_production_boundary --warnings-as-errors"

  @moduledoc """
  MIXCI-03 parity-drift test (D-LD-10).

  Asserts, by IDENTITY + flag-set (NOT a whole-file substring superset), that the
  union of the `mix ci` and `mix ci.browser` alias step-sets covers every required +
  advisory CI lane declared in `Mailglass.CILanes`. The two surfaces — the human
  aliases and CI's per-job matrix — are intentionally separate (DX-MIX-CI.md section E
  footgun #6); this test is what keeps them from drifting silently. A required CI job
  that isn't reflected in the alias fails this test.

  Anti-vacuity guards (Phase 126 precedent): the test fails if the flattened alias
  step-set is empty, if `Mailglass.CILanes.required_lanes/0` does not have exactly 7
  entries, or if the lane->matcher table is not a bijection with the ci_lanes set — so
  it cannot pass by parsing nothing or by silently ignoring a newly-added lane. A
  negative-control assertion proves the coverage function reports "uncovered" when a
  required step is removed, so the fail-loud property is itself tested.

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
          external_alias = external_mix_alias(step, alias_key_strings)

          cond do
            is_binary(step) and MapSet.member?(alias_key_strings, step) ->
              # Safe: `step` is a known alias key, so the atom already exists.
              # Keep the reference token AND its transitive expansion.
              [step | do_flatten_alias(aliases, String.to_existing_atom(step), alias_key_strings)]

            external_alias != nil ->
              # `mix ci` intentionally crosses a fresh-VM boundary between its
              # fast and full tiers. Preserve the command for exact matching and
              # expand its known root alias so parity checks cannot become blind
              # to the lanes behind that process boundary.
              [
                step
                | do_flatten_alias(
                    aliases,
                    String.to_existing_atom(external_alias),
                    alias_key_strings
                  )
              ]

            is_binary(step) ->
              [step]

            true ->
              []
          end
        end)
    end
  end

  defp external_mix_alias(step, alias_key_strings) when is_binary(step) do
    case Regex.run(~r/(?:^|\s)mix\s+([a-z0-9_.]+)(?:\s|$)/, step) do
      [_, name] -> if MapSet.member?(alias_key_strings, name), do: name
      _ -> nil
    end
  end

  defp external_mix_alias(_step, _alias_key_strings), do: nil

  defp aliases, do: Mix.Project.config()[:aliases]

  defp full_suite_alias_commands(aliases) do
    aliases
    |> Keyword.keys()
    |> Enum.flat_map(&flatten_alias(aliases, &1))
    |> Enum.uniq()
    |> Enum.filter(&full_root_mix_test?/1)
  end

  defp workflow_full_suite_commands(workflow) do
    workflow
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&full_root_mix_test?/1)
  end

  defp full_root_mix_test?(command) do
    core_root? = not String.contains?(command, "--cd ")
    mix_test? = Regex.match?(~r/(?:^|\s)(?:mix\s+)?test(?:\s|$)/, command)
    file_scoped? = Regex.match?(~r/(?:^|\s)[^\s-][^\s]*[\/.][^\s]*/, command)
    core_root? and mix_test? and not file_scoped?
  end

  defp host_only_collection_impossible?(commands, default_excluded?) do
    default_excluded? and
      Enum.all?(commands, fn command ->
        not String.contains?(command, "--only phase_164_installed_production_boundary") and
          not String.contains?(command, "--only phase_165_installed_production_boundary")
      end)
  end

  defp default_host_exclusion?(source) do
    source =~ ":phase_164_installed_production_boundary" and
      source =~ ":phase_165_installed_production_boundary" and
      source =~ "ExUnit.configure(exclude: exclusions)"
  end

  defp ci_steps, do: flatten_alias(aliases(), :ci)
  defp ci_browser_steps, do: flatten_alias(aliases(), :"ci.browser")
  defp union_steps, do: ci_steps() ++ ci_browser_steps()

  defp exact_phase_164_scope?(required, installed) do
    required == [@required_contract_step] and installed == [@installed_boundary_step]
  end

  defp describe_test_count(source, name) do
    escaped = Regex.escape(name)

    case Regex.run(~r/^  describe "#{escaped}" do\n(?<body>.*?)(?=^  (?:describe|test) )/ms, source,
           capture: :all_names
         ) do
      [body] -> length(Regex.scan(~r/^    test "/m, body))
      nil -> 0
    end
  end

  # ---------------------------------------------------------------------------
  # Lane -> covering-step matcher table (identity + flag-set, not loose substring)
  #
  # Each matcher is a predicate over the flattened alias step-set. A lane is
  # "covered" iff its matcher returns true. The policy registry and matcher-key
  # registry are deliberately separate so set-equality can detect drift both ways.
  # ---------------------------------------------------------------------------

  defp any_step?(steps, substr), do: Enum.any?(steps, &String.contains?(&1, substr))

  # This table is intentionally independent from Mailglass.CILanes. The duplicated
  # keys are the assertion boundary: deleting or renaming a policy lane without
  # updating its local matcher (or leaving a retired matcher behind) must fail the
  # set-equality check below instead of disappearing from both sides at once.
  @matcher_specs %{
    "Format Check (Elixir 1.18 / OTP 27)" => ["format --check-formatted"],
    "Compile Warnings as Errors (Elixir 1.18 / OTP 27)" => ["compile --warnings-as-errors"],
    "Compile No Optional Deps (Elixir 1.18 / OTP 27)" => [
      "compile --no-optional-deps --warnings-as-errors"
    ],
    "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)" => [
      "mailglass_inbound mix compile --no-optional-deps --warnings-as-errors"
    ],
    "Support Contract Core (Elixir 1.18 / OTP 27)" => ["verify.support_contract.core"],
    "Support Contract Admin (Elixir 1.18 / OTP 27)" => ["verify.support_contract.admin"],
    "Inbound Test (Elixir 1.18 / OTP 27)" => [
      "mailglass_inbound mix test --exclude property",
      "mailglass_inbound mix test --only property"
    ],
    "Core Deterministic Suite (Elixir 1.18 / OTP 27)" => ["mix test --warnings-as-errors"],
    "Mix Task Tests (Elixir 1.18 / OTP 27)" => ["mix test --warnings-as-errors"],
    "Credo Strict (Elixir 1.18 / OTP 27)" => ["credo --strict"],
    "Docs Warnings as Errors (Elixir 1.18 / OTP 27)" => ["docs --warnings-as-errors"],
    "Dialyzer (Elixir 1.18 / OTP 27)" => ["mix dialyzer"],
    "Inbound Dialyzer (Elixir 1.18 / OTP 27)" => ["mailglass_inbound mix dialyzer"],
    "Hex Audit (Elixir 1.18 / OTP 27)" => ["mailglass.audit --kind hex"],
    "Deps Audit (Elixir 1.18 / OTP 27)" => ["mailglass.audit --kind deps"],
    "Trust Lane Repo Head (Elixir 1.18 / OTP 27)" => ["verify.reference_host.journey"],
    "Installer Host Smoke" => ["consumer_install_smoke.sh", "generated_ecto_host_proof.sh"],
    "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)" => [
      "npm run test:operator-browser"
    ]
  }

  # Maps a lane display name to a matcher/1 over the union step-set.
  defp matcher_for(lane) do
    case Map.fetch(@matcher_specs, lane) do
      {:ok, required_fragments} ->
        fn steps -> Enum.all?(required_fragments, &any_step?(steps, &1)) end

      :error ->
        nil
    end
  end

  defp matcher_lanes, do: Map.keys(@matcher_specs)

  defp matcher_drift(policy_lanes, matcher_lane_names) do
    policy = MapSet.new(policy_lanes)
    matchers = MapSet.new(matcher_lane_names)

    %{
      missing: MapSet.difference(policy, matchers),
      stale: MapSet.difference(matchers, policy)
    }
  end

  defp local_required_lanes do
    Mailglass.CIPolicy.load!()
    |> Mailglass.CIPolicy.active_required_lanes()
    |> Enum.filter(&Map.has_key?(&1, :local_alias))
  end

  defp all_lanes,
    do: Enum.map(local_required_lanes(), & &1.name) ++ Mailglass.CILanes.advisory_lanes()

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

    assert steps != [],
           "flattened mix ci ∪ ci.browser step-set is empty — alias parse returned nothing"

    lanes = all_lanes()

    assert length(Mailglass.CILanes.required_lanes()) == 19,
           "expected exactly 19 required lanes from the promoted CI policy"

    drift = matcher_drift(lanes, matcher_lanes())

    assert MapSet.size(drift.missing) == 0,
           "these ci_lanes lanes have no covering matcher (a new lane was added " <>
             "without a matcher, so coverage would silently pass): #{inspect(MapSet.to_list(drift.missing))}"

    # ...and no matcher may reference a lane absent from ci_lanes (no stale matcher).
    assert MapSet.size(drift.stale) == 0,
           "matcher table references lanes not in Mailglass.CILanes (stale matcher — " <>
             "a lane was renamed/removed in ci_lanes but not here): #{inspect(MapSet.to_list(drift.stale))}"

    hostile = matcher_drift(lanes, ["Retired Stale Lane" | matcher_lanes()])

    assert hostile.stale == MapSet.new(["Retired Stale Lane"]),
           "the stale-matcher negative control did not report the injected retired key"
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

    without_generated_proof =
      Enum.reject(union_steps(), &String.contains?(&1, "generated_ecto_host_proof.sh"))

    assert uncovered_lanes(without_generated_proof, [lane]) == [lane]
  end

  test "negative controls: either missing inbound test cohort reports parity drift" do
    lane = "Inbound Test (Elixir 1.18 / OTP 27)"
    assert uncovered_lanes(union_steps(), [lane]) == []

    for marker <- [
          "mailglass_inbound mix test --exclude property",
          "mailglass_inbound mix test --only property"
        ] do
      broken_steps = Enum.reject(union_steps(), &String.contains?(&1, marker))
      assert uncovered_lanes(broken_steps, [lane]) == [lane]
    end
  end

  test "negative control: changing the inbound Dialyzer alias command reports parity drift" do
    lane = "Inbound Dialyzer (Elixir 1.18 / OTP 27)"
    assert uncovered_lanes(union_steps(), [lane]) == []

    broken_steps =
      Enum.map(
        union_steps(),
        &String.replace(&1, "mailglass_inbound mix dialyzer", "mailglass_inbound mix test")
      )

    assert uncovered_lanes(broken_steps, [lane]) == [lane]
  end

  test "durable determinism guard: the flattened root ci alias step-set pins no fixed seed (DET-02)" do
    steps = ci_steps()

    offending = Enum.filter(steps, &String.contains?(&1, "--seed"))

    assert offending == [],
           "the flattened mix ci alias step-set reintroduced a fixed-seed flag — " <>
             "this regresses DET-02 (Phase 127). Offending step(s): #{inspect(offending)}"
  end

  test "required CI excludes proposal and controlled-host proof while repository fixtures stay non-vacuous" do
    aliases = aliases()
    required = Keyword.fetch!(aliases, :"verify.ci_lane_contract")
    installed = Keyword.fetch!(aliases, :"verify.phase_164.installed_boundary")

    assert exact_phase_164_scope?(required, installed)

    ci = File.read!(Path.join(@repo_root, ".github/workflows/ci.yml"))
    assert length(Regex.scan(~r/\bmix verify\.ci_lane_contract\b/, ci)) == 1
    refute ci =~ "mix verify.phase_164.installed_boundary"

    closeout = File.read!(Path.join(@repo_root, "test/scripts/phase_164_closeout_test.exs"))
    assert describe_test_count(closeout, "phase 164 immutable loader") > 0

    immutable_body =
      Regex.run(
        ~r/^  describe "phase 164 immutable loader" do\n(?<body>.*?)(?=^  describe )/ms,
        closeout,
        capture: :all_names
      )

    assert [body] = immutable_body
    refute body =~ "@describetag :phase_164_installed_production_boundary"

    for {broken_required, broken_installed} <- [
          {[], installed},
          {required, []},
          {["test test/scripts/ --exclude phase_164 --warnings-as-errors"], installed},
          {required,
           [
             "test test/scripts/ --only phase_164_installed_production_boundary --warnings-as-errors"
           ]}
        ] do
      refute exact_phase_164_scope?(broken_required, broken_installed)
    end
  end

  test "every root alias and workflow suite inherits the controlled-host exclusion" do
    helper = File.read!(Path.join(@repo_root, "test/test_helper.exs"))
    workflow = File.read!(Path.join(@repo_root, ".github/workflows/ci.yml"))
    alias_commands = full_suite_alias_commands(aliases())
    workflow_commands = workflow_full_suite_commands(workflow)

    assert alias_commands != []
    assert workflow_commands != []
    assert default_host_exclusion?(helper)
    assert host_only_collection_impossible?(alias_commands ++ workflow_commands, true)

    refute host_only_collection_impossible?(alias_commands ++ workflow_commands, false)

    refute host_only_collection_impossible?(
             alias_commands ++ ["mix test --only phase_164_installed_production_boundary"],
             true
           )
  end

  test "repository-only loader attacks remain active and portable" do
    source = File.read!(Path.join(@repo_root, "test/scripts/phase_164_closeout_test.exs"))

    [body] =
      Regex.run(
        ~r/^  describe "phase 164 repository-only installed-loader attacks" do\n(?<body>.*?)(?=^  describe )/ms,
        source,
        capture: :all_names
      )

    assert length(Regex.scan(~r/^    test "/m, body)) == 5
    refute body =~ "@describetag :phase_164_installed_production_boundary"

    refute Regex.match?(
             ~r/defp invoke_(?:production|immutable)_loader.*?System\.cmd\("\/Users\/jon\/\.asdf\/installs\/nodejs\/24\.19\.0\/bin\/node"/ms,
             source
           )

    assert source =~ "System.find_executable(\"node\")"
  end
end
