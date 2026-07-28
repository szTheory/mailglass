defmodule Mailglass.Scripts.LaneClassificationDriftTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Lane-contract truth seam (TRUTH-07). Wired into a real CI job via the
  `verify.ci_lane_contract` alias (`mix_task_tests`, `.github/workflows/ci.yml`) —
  per RESEARCH.md **F2**, a drift meta-test that runs nowhere in `ci.yml` enforces
  nothing, no matter how correct its assertions are.

  Asserts, by identity — not a whole-file substring match — that
  `publish-hex.yml`'s `REQUIRED_LANES` JS array set-equals
  `Mailglass.CILanes.required_lanes/0`. This is the one registry pairing that
  already agrees today; later plans in this phase load the fuller
  publish-gating/advisory/structural classification into the same seam this test
  proves works.

  Anti-vacuity guards (the `required_checks_test.exs:30-34` idiom): every parser
  used here fails loud with a named message rather than silently returning nothing
  and letting a difference-of-empty-sets pass vacuously. The lane list is read from
  `Mailglass.CILanes` — it is NOT duplicated here.

  ## The two name spaces (RESEARCH F1)

  `REQUIRED_LANES` is matched with exact `===` equality by `gate-ci-green`, and
  GitHub appends matrix values to a matrix job's declared `name:` at runtime — so a
  matrix lane placed in `REQUIRED_LANES` would report `(missing)` at every publish
  attempt (the declared name never matches the suffixed runtime name). The matrix
  exact-match safety test below makes this a machine-enforced invariant instead of a
  comment someone can delete.
  """

  @repo_root Path.expand("../..", __DIR__)
  @publish_hex_path Path.join(@repo_root, ".github/workflows/publish-hex.yml")
  @ci_yml_path Path.join(@repo_root, ".github/workflows/ci.yml")

  @required_lanes MapSet.new(Mailglass.CILanes.required_lanes())

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "REQUIRED_LANES (publish-hex.yml) set-equals Mailglass.CILanes.required_lanes/0" do
    js_source = File.read!(@publish_hex_path)
    required_from_js = parse_js_array(js_source, "REQUIRED_LANES")

    {only_in_js, only_in_registry} = drift(required_from_js, @required_lanes)

    assert MapSet.size(only_in_js) == 0 and MapSet.size(only_in_registry) == 0,
           "publish-hex.yml's REQUIRED_LANES and Mailglass.CILanes.required_lanes/0 " <>
             "have drifted:\n" <>
             "  In the JS array but missing from CILanes: #{inspect(MapSet.to_list(only_in_js))}\n" <>
             "  In CILanes but missing from the JS array: #{inspect(MapSet.to_list(only_in_registry))}"
  end

  test "no matrix-strategy ci.yml job's display name appears in REQUIRED_LANES (F1 safety)" do
    ci_source = File.read!(@ci_yml_path)
    js_source = File.read!(@publish_hex_path)

    matrix_names = Mailglass.CIYaml.matrix_job_names(ci_source)
    required_from_js = parse_js_array(js_source, "REQUIRED_LANES")

    colliding = MapSet.intersection(matrix_names, required_from_js)

    assert MapSet.size(colliding) == 0,
           "these ci.yml jobs declare a strategy: (matrix) block AND appear in " <>
             "publish-hex.yml's exact-equality REQUIRED_LANES array — GitHub appends " <>
             "matrix values to a matrix job's runtime name, so REQUIRED_LANES's exact " <>
             "match would never see it and every publish would report it '(missing)': " <>
             "#{inspect(MapSet.to_list(colliding))}"
  end

  test "anti-vacuity: parsed REQUIRED_LANES, ci.yml job map, and matrix-job set are all non-empty" do
    js_source = File.read!(@publish_hex_path)
    ci_source = File.read!(@ci_yml_path)

    required_from_js = parse_js_array(js_source, "REQUIRED_LANES")
    job_names = Mailglass.CIYaml.job_names(ci_source)
    matrix_names = Mailglass.CIYaml.matrix_job_names(ci_source)

    assert MapSet.size(required_from_js) == 5,
           "expected exactly 5 entries parsed from publish-hex.yml's REQUIRED_LANES " <>
             "array — parser or file format changed"

    assert map_size(job_names) > 0,
           "Mailglass.CIYaml.job_names/1 parsed no ci.yml jobs — parser or file format changed"

    assert MapSet.size(matrix_names) > 0,
           "Mailglass.CIYaml.matrix_job_names/1 parsed no matrix jobs — parser or file " <>
             "format changed (ci.yml has at least one strategy: job today)"
  end

  # ---------------------------------------------------------------------------
  # Parsers
  # ---------------------------------------------------------------------------

  # Splits on the full unique token `const <name> = [` and scans single-quoted
  # entries up to the closing `];`. Unlike required_checks_test.exs:159-166 (which
  # crashes via `[_before, rest] = String.split(...)` on a non-match), a non-match
  # here returns an EMPTY SET via the `case` fallback — so the anti-vacuity assert,
  # not a MatchError, is what fires and names the cause.
  defp parse_js_array(source, name) do
    case String.split(source, "const #{name} = [", parts: 2) do
      [_before, rest] ->
        [chunk | _] = String.split(rest, "];", parts: 2)

        ~r/'([^']*)'/
        |> Regex.scan(chunk)
        |> Enum.map(fn [_full, entry] -> entry end)
        |> MapSet.new()

      _ ->
        MapSet.new()
    end
  end

  # Returns {only_in_a, only_in_b} — the two-direction set difference shared by the
  # real assertion above and the negative-control test (Task 2), so a future edit
  # that weakens this helper breaks the negative control too.
  defp drift(a, b), do: {MapSet.difference(a, b), MapSet.difference(b, a)}
end
