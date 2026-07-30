defmodule Mailglass.Scripts.LaneClassificationDriftTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Lane-contract truth seam (TRUTH-07/TRUTH-09). Wired into a real CI job via the
  `verify.ci_lane_contract` alias (`mix_task_tests`, `.github/workflows/ci.yml`) —
  per RESEARCH.md **F2**, a drift meta-test that runs nowhere in `ci.yml` enforces
  nothing, no matter how correct its assertions are.

  Asserts, by identity — not a whole-file substring match — that all four of
  `publish-hex.yml`'s classification arrays (`REQUIRED_LANES`, `ADVISORY_LANES`,
  `PUBLISH_GATING_LANES`, `STRUCTURAL_LANES`) each set-equal their counterpart
  accessor on `Mailglass.CILanes` (`required_lanes/0`, `advisory_classified_lanes/0`,
  `publish_gating_lanes/0`, `structural_lanes/0`). The four lane lists are read
  from `Mailglass.CILanes` — they are NOT duplicated as literals in this file.

  As of Phase 141 plan 06, this file proves **three-way agreement** (D-05/D-06):
  `Mailglass.CILanes`, `publish-hex.yml`'s four classification arrays, and
  `MAINTAINING.md` § "Required Checks"'s 24-row disposition table all set-equal
  each other on `(display name, classification)`, plus completeness against
  `ci.yml`'s live job set — so none of the three can silently drift from the
  others without failing CI.

  Anti-vacuity guards (the `required_checks_test.exs:30-34` idiom): every parser
  used here fails loud with a named message rather than silently returning nothing
  and letting a difference-of-empty-sets pass vacuously.

  ## The two name spaces (RESEARCH F1)

  `REQUIRED_LANES` is matched with exact `===` equality by `gate-ci-green`, and
  GitHub appends matrix values to a matrix job's declared `name:` at runtime — so a
  matrix lane placed in `REQUIRED_LANES` would report `(missing)` at every publish
  attempt (the declared name never matches the suffixed runtime name). The other
  three arrays are matched by prefix instead, precisely because they may contain a
  matrix lane (`Dialyzer`, `Operator Browser Gate`, `Preview Capture Advisory`). The
  matrix exact-match safety test below makes the `REQUIRED_LANES` half of this a
  machine-enforced invariant instead of a comment someone can delete.
  """

  @repo_root Path.expand("../..", __DIR__)
  @publish_hex_path Path.join(@repo_root, ".github/workflows/publish-hex.yml")
  @ci_yml_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @advisory_matrix_path Path.join(@repo_root, ".github/workflows/advisory-matrix.yml")
  @maintaining_path Path.join(@repo_root, "MAINTAINING.md")

  # The literal env entry `Mailglass.TestSupport.SuiteFloor` enforcement hangs
  # off (HARNESS-03). Written out here rather than assembled from parts so this
  # file fails on a value change (`"0"`, `"true"`) and not merely on the key
  # disappearing — the module compares against the string `"1"` exactly.
  @suite_floor_env_entry ~s(MAILGLASS_SUITE_FLOOR: "1")

  # One per `advisory-matrix.yml` full-suite step: the 1.18/OTP 27 job
  # (`core_full_suite_advisory`) and the 1.19/OTP 28 job
  # (`core_latest_elixir_advisory`).
  @suite_floor_env_occurrences 2

  # Every RUNTIME lane name advisory-matrix.yml produces: 2 Core Full Suite legs +
  # 2 next-toolchain legs + 1 Provider Compatibility leg + 2 Inbound Full Suite legs.
  # Deliberately NOT derived from the parser under test — a count computed from the
  # thing it is counting cannot fail.
  @advisory_matrix_runtime_lane_count 7

  @required_lanes MapSet.new(Mailglass.CILanes.required_lanes())
  @advisory_classified_lanes MapSet.new(Mailglass.CILanes.advisory_classified_lanes())
  @publish_gating_lanes MapSet.new(Mailglass.CILanes.publish_gating_lanes())
  @structural_lanes MapSet.new(Mailglass.CILanes.structural_lanes())

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

  test "ADVISORY_LANES (publish-hex.yml) set-equals Mailglass.CILanes.advisory_classified_lanes/0" do
    js_source = File.read!(@publish_hex_path)
    advisory_from_js = parse_js_array(js_source, "ADVISORY_LANES")

    assert MapSet.size(advisory_from_js) == 3,
           "expected exactly 3 entries parsed from publish-hex.yml's ADVISORY_LANES " <>
             "array — parser or file format changed"

    {only_in_js, only_in_registry} = drift(advisory_from_js, @advisory_classified_lanes)

    assert MapSet.size(only_in_js) == 0 and MapSet.size(only_in_registry) == 0,
           "publish-hex.yml's ADVISORY_LANES and " <>
             "Mailglass.CILanes.advisory_classified_lanes/0 have drifted:\n" <>
             "  In the JS array but missing from CILanes: #{inspect(MapSet.to_list(only_in_js))}\n" <>
             "  In CILanes but missing from the JS array: #{inspect(MapSet.to_list(only_in_registry))}"
  end

  test "PUBLISH_GATING_LANES (publish-hex.yml) set-equals Mailglass.CILanes.publish_gating_lanes/0" do
    js_source = File.read!(@publish_hex_path)
    publish_gating_from_js = parse_js_array(js_source, "PUBLISH_GATING_LANES")

    assert MapSet.size(publish_gating_from_js) == 12,
           "expected exactly 12 entries parsed from publish-hex.yml's " <>
             "PUBLISH_GATING_LANES array — parser or file format changed"

    {only_in_js, only_in_registry} = drift(publish_gating_from_js, @publish_gating_lanes)

    assert MapSet.size(only_in_js) == 0 and MapSet.size(only_in_registry) == 0,
           "publish-hex.yml's PUBLISH_GATING_LANES and " <>
             "Mailglass.CILanes.publish_gating_lanes/0 have drifted:\n" <>
             "  In the JS array but missing from CILanes: #{inspect(MapSet.to_list(only_in_js))}\n" <>
             "  In CILanes but missing from the JS array: #{inspect(MapSet.to_list(only_in_registry))}"
  end

  test "STRUCTURAL_LANES (publish-hex.yml) set-equals Mailglass.CILanes.structural_lanes/0" do
    js_source = File.read!(@publish_hex_path)
    structural_from_js = parse_js_array(js_source, "STRUCTURAL_LANES")

    assert MapSet.size(structural_from_js) == 2,
           "expected exactly 2 entries parsed from publish-hex.yml's STRUCTURAL_LANES " <>
             "array — parser or file format changed"

    {only_in_js, only_in_registry} = drift(structural_from_js, @structural_lanes)

    assert MapSet.size(only_in_js) == 0 and MapSet.size(only_in_registry) == 0,
           "publish-hex.yml's STRUCTURAL_LANES and Mailglass.CILanes.structural_lanes/0 " <>
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

    assert MapSet.size(required_from_js) == 7,
           "expected exactly 7 entries parsed from publish-hex.yml's REQUIRED_LANES " <>
             "array — parser or file format changed"

    assert map_size(job_names) > 0,
           "Mailglass.CIYaml.job_names/1 parsed no ci.yml jobs — parser or file format changed"

    assert MapSet.size(matrix_names) > 0,
           "Mailglass.CIYaml.matrix_job_names/1 parsed no matrix jobs — parser or file " <>
             "format changed (ci.yml has at least one strategy: job today)"
  end

  # A vacuously-passing drift meta-test is this milestone's originating failure
  # mode (CLAUDE.md: branch-protection-drift.yml reported SUCCESS while its own
  # comparison was skipped for 24 days). This test mechanically proves the
  # fail-loud property instead of trusting it by inspection — it exercises the
  # SAME drift/2 helper the real assertion above uses, not a re-implementation, so
  # a future edit that weakens drift/2 breaks this negative control too.
  test "negative control: removing one entry from the parsed REQUIRED_LANES set " <>
         "makes the drift comparison report it (fail-loud property is tested)" do
    js_source = File.read!(@publish_hex_path)
    required_from_js = parse_js_array(js_source, "REQUIRED_LANES")

    # Sanity: today the two sides agree — drift/2 reports two empty sets.
    assert drift(required_from_js, @required_lanes) == {MapSet.new(), MapSet.new()},
           "sanity check failed: REQUIRED_LANES and Mailglass.CILanes.required_lanes/0 " <>
             "should agree before the injected-breakage assertion runs"

    # "Installer Host Smoke" is the one required lane with no "(Elixir ... )"
    # suffix, so removing it is unambiguous (no other entry could be mistaken for
    # it in the reported diff).
    removed_entry = "Installer Host Smoke"
    assert removed_entry in MapSet.to_list(required_from_js)

    broken_js_set = MapSet.delete(required_from_js, removed_entry)

    # drift(a, b) returns {a \ b, b \ a}: the first element is what's only in the
    # broken JS set (empty — we only removed, never added), the second is what's
    # only in the registry — i.e. what the JS array is now missing.
    {only_in_broken_js_not_registry, only_in_registry_not_broken_js} =
      drift(broken_js_set, @required_lanes)

    assert only_in_registry_not_broken_js == MapSet.new([removed_entry]),
           "a vacuous pass is exactly the failure mode this test excludes: removing " <>
             "'#{removed_entry}' from the parsed set must make drift/2 report it, and " <>
             "only it, in the 'missing from the JS array' direction — got " <>
             "#{inspect(MapSet.to_list(only_in_registry_not_broken_js))}"

    assert MapSet.size(only_in_broken_js_not_registry) == 0,
           "unexpected reverse-direction drift after removing only '#{removed_entry}': " <>
             "#{inspect(MapSet.to_list(only_in_broken_js_not_registry))}"

    # Extended negative control: PUBLISH_GATING_LANES, using the lane this phase
    # adds ("Design System Conformance (shell gates)") as the removed entry — the
    # one most likely to be forgotten in a future edit, so it is the one whose
    # fail-loud property matters most.
    publish_gating_from_js = parse_js_array(js_source, "PUBLISH_GATING_LANES")

    assert drift(publish_gating_from_js, @publish_gating_lanes) == {MapSet.new(), MapSet.new()},
           "sanity check failed: PUBLISH_GATING_LANES and " <>
             "Mailglass.CILanes.publish_gating_lanes/0 should agree before the " <>
             "injected-breakage assertion runs"

    pg_removed_entry = "Design System Conformance (shell gates)"
    assert pg_removed_entry in MapSet.to_list(publish_gating_from_js)

    broken_publish_gating_set = MapSet.delete(publish_gating_from_js, pg_removed_entry)

    {pg_only_in_broken_js, pg_only_in_registry} =
      drift(broken_publish_gating_set, @publish_gating_lanes)

    assert pg_only_in_registry == MapSet.new([pg_removed_entry]),
           "removing '#{pg_removed_entry}' from the parsed PUBLISH_GATING_LANES set " <>
             "must make drift/2 report it, and only it, in the 'missing from the JS " <>
             "array' direction — got #{inspect(MapSet.to_list(pg_only_in_registry))}"

    assert MapSet.size(pg_only_in_broken_js) == 0,
           "unexpected reverse-direction drift after removing only " <>
             "'#{pg_removed_entry}': #{inspect(MapSet.to_list(pg_only_in_broken_js))}"
  end

  # ---------------------------------------------------------------------------
  # Task 1 (141-05): every ci.yml job is classified — TRUTH-09 / ROADMAP
  # criterion 2 becomes a build failure, not a policy.
  # ---------------------------------------------------------------------------

  test "every ci.yml job display name is classified in Mailglass.CILanes.all_classified_lanes/0 (TRUTH-09)" do
    ci_source = File.read!(@ci_yml_path)
    job_display_names = MapSet.new(Map.values(Mailglass.CIYaml.job_names(ci_source)))
    classified = MapSet.new(Mailglass.CILanes.all_classified_lanes())

    {only_in_ci_yml, only_in_registry} = drift(job_display_names, classified)

    assert MapSet.size(only_in_ci_yml) == 0 and MapSet.size(only_in_registry) == 0,
           "ci.yml and Mailglass.CILanes.all_classified_lanes/0 have drifted — an " <>
             "unclassified job can be merged, which recreates the hidden third gating " <>
             "tier this phase eliminates:\n" <>
             "  In ci.yml but not classified in CILanes (add to Mailglass.CILanes AND to " <>
             "publish-hex.yml's classification arrays): " <>
             "#{inspect(MapSet.to_list(only_in_ci_yml))}\n" <>
             "  Classified in CILanes but not present in ci.yml (stale entry — remove from " <>
             "Mailglass.CILanes and publish-hex.yml): #{inspect(MapSet.to_list(only_in_registry))}"
  end

  test "ci.yml parses to exactly 24 jobs and all_classified_lanes/0 returns exactly 24 distinct names" do
    ci_source = File.read!(@ci_yml_path)
    job_names = Mailglass.CIYaml.job_names(ci_source)
    classified = Mailglass.CILanes.all_classified_lanes()

    assert map_size(job_names) == 24,
           "expected exactly 24 ci.yml jobs (23 pre-existing + the conformance_gates job " <>
             "added in Phase 141 plan 03) — got #{map_size(job_names)}. A future legitimate " <>
             "job addition must update this count deliberately, not delete the guard."

    assert length(classified) == 24,
           "expected Mailglass.CILanes.all_classified_lanes/0 to return exactly 24 entries " <>
             "(7 required + 3 advisory + 12 publish-gating + 2 structural) — got " <>
             "#{length(classified)}"

    assert MapSet.size(MapSet.new(classified)) == 24,
           "all_classified_lanes/0 returned 24 entries but fewer than 24 distinct strings — " <>
             "a lane sits in two buckets, which classify/1 must never allow"
  end

  test "publish-hex.yml still contains the required-lane presence loop (posture guard)" do
    js_source = File.read!(@publish_hex_path)

    assert String.contains?(js_source, "(missing)"),
           "publish-hex.yml no longer contains the '(missing)' marker — the required-lane " <>
             "presence loop may have been refactored away or folded into classify/1, which " <>
             "would make a zero-job API response fall through to success instead of blocking"

    assert String.contains?(
             js_source,
             "Delivery blocked: required CI lane(s) did not pass on SHA"
           ),
           "publish-hex.yml no longer contains the required-lane failure message — a run " <>
             "reporting zero jobs must still block publish rather than pass silently"
  end

  test "negative control: removing 'Detect Non-Doc Changes' from the parsed ci.yml job map " <>
         "makes the drift comparison report it (structural jobs are not vacuously exempt)" do
    ci_source = File.read!(@ci_yml_path)
    job_display_names = MapSet.new(Map.values(Mailglass.CIYaml.job_names(ci_source)))
    classified = MapSet.new(Mailglass.CILanes.all_classified_lanes())

    assert drift(job_display_names, classified) == {MapSet.new(), MapSet.new()},
           "sanity check failed: ci.yml job names and all_classified_lanes/0 should agree " <>
             "before the injected-removal assertion runs"

    removed_entry = "Detect Non-Doc Changes"
    assert removed_entry in MapSet.to_list(job_display_names)

    broken_job_names = MapSet.delete(job_display_names, removed_entry)

    {only_in_broken_ci_yml, only_in_registry} = drift(broken_job_names, classified)

    assert only_in_registry == MapSet.new([removed_entry]),
           "removing '#{removed_entry}' — a structural job that is easy to overlook because " <>
             "it is a path filter, not a check lane — from the parsed ci.yml job map must " <>
             "make drift/2 report it, and only it, in the 'classified but not present in " <>
             "ci.yml' direction; got #{inspect(MapSet.to_list(only_in_registry))}"

    assert MapSet.size(only_in_broken_ci_yml) == 0,
           "unexpected reverse-direction drift after removing only '#{removed_entry}': " <>
             "#{inspect(MapSet.to_list(only_in_broken_ci_yml))}"
  end

  # ---------------------------------------------------------------------------
  # Task 2 (141-05): the matrix name-space seam, prefix safety, and
  # byte-exact-comparability hazards a comment cannot hold.
  # ---------------------------------------------------------------------------

  test "no classified display name is a prefix of another (adjacency safety, RESEARCH F1)" do
    names = Mailglass.CILanes.all_classified_lanes()

    for a <- names, b <- names, a != b do
      refute String.starts_with?(b, a),
             "prefix collision: '#{b}' starts with '#{a}' — gate-ci-green's ordered " <>
               "prefix checks could assign a runtime job name carrying this prefix to the " <>
               "wrong bucket"
    end
  end

  test "each classified name — bare and with a synthetic matrix suffix — matches exactly one bucket" do
    names = Mailglass.CILanes.all_classified_lanes()

    for name <- names do
      buckets = classify_lane_buckets(name)

      assert length(buckets) == 1,
             "'#{name}' matched #{length(buckets)} classification buckets " <>
               "(#{inspect(buckets)}) — classify/1's ordered exact/prefix rule must assign " <>
               "exactly one bucket to every classified name"
    end

    # The synthetic-suffix probe is scoped to the 19 non-required (prefix-matched)
    # names deliberately: required_lanes/0 is matched by EXACT equality (RESEARCH
    # F1), and the separate matrix-exact-match-safety test below guards the
    # invariant that no required lane ever declares a `strategy:` block — so a
    # required lane can never legitimately carry a runtime matrix suffix. Probing
    # a required name with a synthetic suffix would assert a property that must
    # be FALSE (zero buckets, not one) and would contradict that guarantee rather
    # than model a genuine F1 hazard for those 5 lanes.
    non_required_names = names -- Mailglass.CILanes.required_lanes()

    suffixed =
      for name <- non_required_names, suffix <- [" (1.18, 27)", " (22)"], do: name <> suffix

    for name <- suffixed do
      buckets = classify_lane_buckets(name)

      assert length(buckets) == 1,
             "'#{name}' (synthetic matrix-suffixed form) matched #{length(buckets)} " <>
               "classification buckets (#{inspect(buckets)}) — this is exactly the " <>
               "F1-class misclassification hazard: a matrix lane's runtime name must " <>
               "still resolve to exactly one bucket"
    end
  end

  test "matrix_job_names/1 lanes are absent from required_lanes/0 and land in exactly one prefix bucket" do
    ci_source = File.read!(@ci_yml_path)
    matrix_names = Mailglass.CIYaml.matrix_job_names(ci_source)

    assert MapSet.size(matrix_names) >= 3,
           "expected at least 3 matrix-strategy ci.yml jobs (dialyzer, operator_browser_gate, " <>
             "preview_capture_advisory) — matrix_job_names/1 parsed fewer than 3"

    required_set = @required_lanes

    for name <- MapSet.to_list(matrix_names) do
      refute MapSet.member?(required_set, name),
             "matrix-strategy job '#{name}' must never appear in required_lanes/0 — GitHub " <>
               "appends matrix values to its runtime name, so exact-equality matching would " <>
               "report it '(missing)' and block every publish (RESEARCH F1 consequence 4)"

      buckets = classify_lane_buckets(name)

      assert length(buckets) == 1,
             "matrix job '#{name}' must be matched by exactly one of the three " <>
               "prefix-matched buckets (advisory/publish_gating/structural); got " <>
               "#{inspect(buckets)}"
    end
  end

  test "every classified display name is printable ASCII with no ' or | characters (byte-exact comparability)" do
    names = Mailglass.CILanes.all_classified_lanes()

    for name <- names do
      assert Regex.match?(~r/\A[ -~]+\z/, name),
             "'#{name}' contains a non-printable-ASCII character — comparison across " <>
               "ci.yml, ci_lanes.ex, publish-hex.yml, and MAINTAINING.md is byte-exact and " <>
               "would break"

      refute String.contains?(name, "'"),
             "'#{name}' contains a single quote, which would break publish-hex.yml's " <>
               "single-quoted JS array parser"

      refute String.contains?(name, "|"),
             "'#{name}' contains a pipe character, which would break MAINTAINING.md's " <>
               "markdown disposition-table parser (plan 141-06)"
    end
  end

  test "drift/2 is order-independent — reversing a registry list yields an identical verdict" do
    names = Mailglass.CILanes.all_classified_lanes()
    forward = MapSet.new(names)
    reversed = MapSet.new(Enum.reverse(names))

    assert drift(forward, reversed) == {MapSet.new(), MapSet.new()},
           "drift/2 must be order-independent: reversing the registry list before " <>
             "building a MapSet must not change the verdict. A future refactor from " <>
             "MapSet.difference/2 to list equality would fail this and turn a harmless " <>
             "reordering into a false failure."
  end

  # ---------------------------------------------------------------------------
  # Plan 141-06: bind MAINTAINING.md's disposition table to the same registry,
  # closing the third leg of the three-way agreement (D-05/D-06/TRUTH-05).
  # ---------------------------------------------------------------------------

  test "MAINTAINING.md's disposition table (display name, classification) pairs " <>
         "set-equal Mailglass.CILanes's four classification buckets" do
    md = File.read!(@maintaining_path)

    section = find_required_checks_section(md)

    assert section != nil,
           "could not find MAINTAINING.md's '## Required Checks' section — the heading " <>
             "was renamed or removed, which moves the disposition-table parser's bound"

    rows = parse_disposition_table(md)
    table_pairs = disposition_table_pairs(rows)
    registry_pairs = cilanes_classification_pairs()

    {only_in_table, only_in_registry} = drift(table_pairs, registry_pairs)

    assert MapSet.size(only_in_table) == 0 and MapSet.size(only_in_registry) == 0,
           "MAINTAINING.md's disposition table and Mailglass.CILanes have drifted:\n" <>
             "  In MAINTAINING.md but missing from CILanes: " <>
             "#{inspect(MapSet.to_list(only_in_table))}\n" <>
             "  In CILanes but missing from MAINTAINING.md: " <>
             "#{inspect(MapSet.to_list(only_in_registry))}"
  end

  test "MAINTAINING.md's disposition table parses to exactly 24 non-empty rows (anti-vacuity)" do
    rows = parse_disposition_table(File.read!(@maintaining_path))

    assert rows != [],
           "parsed zero rows from MAINTAINING.md's disposition table — the table's " <>
             "format changed or the '## Required Checks' section was not found"

    assert length(rows) == 24,
           "expected exactly 24 rows in MAINTAINING.md's disposition table — got " <>
             "#{length(rows)}. A '|' inside a free-text reason cell silently drops that " <>
             "row under the cell-count reject, which is the vacuity risk this exact " <>
             "count guards against — the document that exists to prevent a vacuous " <>
             "pass must not itself pass vacuously."
  end

  test "MAINTAINING.md's 24 job id cells are distinct and its 24 display name cells are distinct" do
    rows = parse_disposition_table(File.read!(@maintaining_path))

    ids = Enum.map(rows, fn {id, _name, _cls, _disp, _reason} -> id end)
    names = Enum.map(rows, fn {_id, name, _cls, _disp, _reason} -> name end)

    assert length(ids) == length(Enum.uniq(ids)),
           "MAINTAINING.md's disposition table has duplicate job id cells " <>
             "(two rows merged): #{inspect(ids -- Enum.uniq(ids))}"

    assert length(names) == length(Enum.uniq(names)),
           "MAINTAINING.md's disposition table has duplicate display name cells " <>
             "(two rows merged): #{inspect(names -- Enum.uniq(names))}"
  end

  test "every row's disposition in MAINTAINING.md's table is a member of the closed vocabulary" do
    rows = parse_disposition_table(File.read!(@maintaining_path))

    for {id, _name, _cls, disp, _reason} <- rows do
      assert disp in ~w(promote keep-with-reason retire),
             "MAINTAINING.md row '#{id}' has disposition '#{disp}', which is not a " <>
               "member of the closed vocabulary ~w(promote keep-with-reason retire) — " <>
               "an empty or misspelled cell must fail here, naming the row"
    end
  end

  test "no display name or job id cell in MAINTAINING.md's disposition table contains a '|' character" do
    rows = parse_disposition_table(File.read!(@maintaining_path))

    for {id, name, _cls, _disp, _reason} <- rows do
      refute String.contains?(id, "|"),
             "MAINTAINING.md job id cell '#{id}' contains a pipe character, which would " <>
               "break the row-cell-count parser"

      refute String.contains?(name, "|"),
             "MAINTAINING.md display name cell '#{name}' contains a pipe character, " <>
               "which would break the row-cell-count parser"
    end
  end

  test "reversing MAINTAINING.md's parsed row list before set construction yields an identical verdict" do
    rows = parse_disposition_table(File.read!(@maintaining_path))

    forward = disposition_table_pairs(rows)
    reversed = disposition_table_pairs(Enum.reverse(rows))

    assert drift(forward, reversed) == {MapSet.new(), MapSet.new()},
           "row order in MAINTAINING.md's disposition table must not be load-bearing: " <>
             "reversing the parsed row list before building a MapSet changed the verdict"
  end

  test "negative control: dropping one row from MAINTAINING.md's parsed disposition " <>
         "table makes the comparison report only that lane, in the 'in CILanes but " <>
         "missing from MAINTAINING.md' direction" do
    rows = parse_disposition_table(File.read!(@maintaining_path))
    table_pairs = disposition_table_pairs(rows)
    registry_pairs = cilanes_classification_pairs()

    assert drift(table_pairs, registry_pairs) == {MapSet.new(), MapSet.new()},
           "sanity check failed: MAINTAINING.md's disposition table and " <>
             "Mailglass.CILanes should agree before the injected-removal assertion runs"

    # "Installer Host Smoke" — same stable choice as the REQUIRED_LANES negative
    # control above: the one required lane with no "(Elixir ... )" suffix, so
    # removing it is unambiguous in the reported diff.
    removed_pair = {"Installer Host Smoke", "required"}
    assert removed_pair in MapSet.to_list(table_pairs)

    broken_table_pairs = MapSet.delete(table_pairs, removed_pair)

    {only_in_broken_table, only_in_registry} = drift(broken_table_pairs, registry_pairs)

    assert only_in_registry == MapSet.new([removed_pair]),
           "dropping '#{inspect(removed_pair)}' from the parsed disposition table must " <>
             "make drift/2 report it, and only it, in the 'missing from MAINTAINING.md' " <>
             "direction — got #{inspect(MapSet.to_list(only_in_registry))}"

    assert MapSet.size(only_in_broken_table) == 0,
           "unexpected reverse-direction drift after dropping only " <>
             "'#{inspect(removed_pair)}': #{inspect(MapSet.to_list(only_in_broken_table))}"
  end

  # ---------------------------------------------------------------------------
  # HARNESS-03: the suite-floor opt-in on advisory-matrix.yml's full-suite steps
  #
  # Enforcement lives at the intersection of two things: the pinned constants in
  # `Mailglass.TestSupport.SuiteFloor` and this env entry on the lane step.
  # Either one disappearing silently disables the guard, and only one of the two
  # is visible in an Elixir test — so the workflow half is asserted here.
  # ---------------------------------------------------------------------------

  describe "advisory-matrix.yml's suite-floor opt-in (HARNESS-03)" do
    test "the full-suite steps carry the suite-floor env entry exactly twice, with the " <>
           "literal value SuiteFloor compares against" do
      occurrences = count_suite_floor_env_entries()

      assert occurrences == @suite_floor_env_occurrences,
             "expected exactly #{@suite_floor_env_occurrences} `#{@suite_floor_env_entry}` " <>
               "entries in advisory-matrix.yml — one on each full-suite step " <>
               "(core_full_suite_advisory's and core_latest_elixir_advisory's) — got " <>
               "#{occurrences}.\n\n" <>
               "Removing one silently disables, on that leg, the per-schema executed-count " <>
               "floor, the skipped ceiling, and the `:already_shared == 0` sandbox-ownership " <>
               "signature assertion: SuiteFloor keeps PRINTING its counts, so the log still " <>
               "looks instrumented while nothing can fail. A future legitimate change (a " <>
               "third full-suite step, or a job removed) must update this count " <>
               "deliberately, not delete the guard."
    end

    test "anti-vacuity: the parser finds the workflow and the env entry it counts" do
      source = File.read!(@advisory_matrix_path)

      assert byte_size(source) > 0,
             "advisory-matrix.yml parsed to an empty string — the count assertion above " <>
               "would then compare 0 against 0 for a moved or deleted file rather than " <>
               "failing on it"

      assert String.contains?(source, @suite_floor_env_entry),
             "advisory-matrix.yml contains no `#{@suite_floor_env_entry}` at all. If the " <>
               "variable was renamed, this file's @suite_floor_env_entry and " <>
               "Mailglass.TestSupport.SuiteFloor's `System.get_env/1` read must move " <>
               "together — a rename in one place alone turns the gate off silently."
    end

    test "negative control: deleting one occurrence from the parsed source makes the count " <>
           "assertion report it" do
      source = File.read!(@advisory_matrix_path)

      assert count_suite_floor_env_entries(source) == @suite_floor_env_occurrences,
             "sanity check failed: the unmodified workflow should already carry both entries"

      broken =
        String.replace(source, @suite_floor_env_entry, "", global: false)

      assert count_suite_floor_env_entries(broken) == @suite_floor_env_occurrences - 1,
             "removing one occurrence must be observable by the same counting function the " <>
               "assertion above uses — otherwise that assertion could pass on a workflow " <>
               "with the opt-in stripped out"
    end
  end

  # ---------------------------------------------------------------------------
  # D-24: the RUNTIME name space for advisory-matrix.yml.
  #
  # `job_names/1` returns DECLARED names and collapses advisory-matrix.yml's two
  # byte-identical Core Full Suite `name:` templates into one entry — so a
  # registry-versus-YAML set-equality test built on it would claim four-leg
  # coverage while proving two. `expanded_matrix_job_names/1` expands
  # `strategy.matrix.include:` rows into the template and returns what GitHub
  # actually reports. These assertions pin that distinction so a future refactor
  # cannot quietly collapse the two spaces back together.
  # ---------------------------------------------------------------------------

  describe "expanded_matrix_job_names/1 (advisory-matrix.yml runtime names, D-24)" do
    test "anti-vacuity: the parser returns a non-empty set" do
      names = Mailglass.CIYaml.expanded_matrix_job_names(File.read!(@advisory_matrix_path))

      assert MapSet.size(names) > 0,
             "Mailglass.CIYaml.expanded_matrix_job_names/1 parsed no runtime job names from " <>
               "advisory-matrix.yml — parser or file format changed (advisory-matrix.yml has " <>
               "at least one strategy.matrix.include: job today). Without this guard the " <>
               "set-equality assertions below would compare an empty set against an empty " <>
               "registry and pass while proving nothing."
    end

    test "the parser returns exactly #{@advisory_matrix_runtime_lane_count} runtime lane names" do
      names = Mailglass.CIYaml.expanded_matrix_job_names(File.read!(@advisory_matrix_path))

      assert MapSet.size(names) == @advisory_matrix_runtime_lane_count,
             "expected exactly #{@advisory_matrix_runtime_lane_count} runtime lane names from " <>
               "advisory-matrix.yml (2 Core Full Suite legs + 2 next-toolchain legs + 1 " <>
               "Provider Compatibility leg + 2 Inbound Full Suite legs) — got " <>
               "#{MapSet.size(names)}: #{inspect(Enum.sort(names))}. A future legitimate " <>
               "matrix row or job addition must update this count deliberately, not delete " <>
               "the guard."
    end

    test "every returned name is fully substituted — no `${{` survives expansion" do
      names = Mailglass.CIYaml.expanded_matrix_job_names(File.read!(@advisory_matrix_path))

      for name <- names do
        refute String.contains?(name, "${{"),
               "runtime name '#{name}' still carries an uninterpolated matrix expression — " <>
                 "the parser emitted a template rather than expanding it, which is the " <>
                 "silent-vacuity shape this function exists to eliminate (a registry built " <>
                 "from templates would never match a live job name)"
      end
    end

    test "runtime names strictly outnumber declared names — the two spaces do not collapse" do
      source = File.read!(@advisory_matrix_path)

      runtime = Mailglass.CIYaml.expanded_matrix_job_names(source)
      declared = MapSet.new(Map.values(Mailglass.CIYaml.job_names(source)))

      assert MapSet.size(declared) > 0,
             "Mailglass.CIYaml.job_names/1 parsed no advisory-matrix.yml jobs — the " <>
               "comparison below would be vacuous"

      assert MapSet.size(runtime) > MapSet.size(declared),
             "expected advisory-matrix.yml to yield strictly more RUNTIME names " <>
               "(#{MapSet.size(runtime)}) than DECLARED ones (#{MapSet.size(declared)}). " <>
               "Declared names collapse every matrix leg of a job into one template — and, " <>
               "before the D-21 rename, collapsed the two Core Full Suite jobs into each " <>
               "other as well. A registry bound to declared names would claim per-leg " <>
               "coverage it does not have; that is the exact vacuity this assertion pins."
    end

    test "negative control: removing one known runtime name makes the drift comparison " <>
           "report it, and only it, in the correct direction" do
      names = Mailglass.CIYaml.expanded_matrix_job_names(File.read!(@advisory_matrix_path))

      # Chosen because it is stable across the D-21 Core Full Suite rename and is
      # unambiguous in a reported diff (no other lane could be mistaken for it).
      removed_entry = "Inbound Full Suite Advisory (schema mailglass)"

      assert removed_entry in MapSet.to_list(names),
             "sanity check failed: '#{removed_entry}' should already be one of the parsed " <>
               "runtime names before the injected-removal assertion runs — got " <>
               "#{inspect(Enum.sort(names))}"

      broken = MapSet.delete(names, removed_entry)

      # drift(a, b) returns {a \ b, b \ a}: nothing was added, so the first set must
      # be empty and the second must name exactly the removed lane.
      {only_in_broken, only_in_full} = drift(broken, names)

      assert only_in_full == MapSet.new([removed_entry]),
             "a vacuous pass is exactly the failure mode this test excludes: removing " <>
               "'#{removed_entry}' from the parsed runtime set must make drift/2 — the same " <>
               "helper the real set-equality assertions use — report it, and only it, in " <>
               "the 'missing from the parsed set' direction; got " <>
               "#{inspect(MapSet.to_list(only_in_full))}"

      assert MapSet.size(only_in_broken) == 0,
             "unexpected reverse-direction drift after removing only '#{removed_entry}': " <>
               "#{inspect(MapSet.to_list(only_in_broken))}"
    end
  end

  # ---------------------------------------------------------------------------
  # Parsers
  # ---------------------------------------------------------------------------

  defp count_suite_floor_env_entries(source \\ nil) do
    (source || File.read!(@advisory_matrix_path))
    |> String.split(@suite_floor_env_entry)
    |> length()
    |> Kernel.-(1)
  end

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

  # Mirrors `gate-ci-green`'s `classify/1` (publish-hex.yml) so the "exactly one
  # bucket" and matrix-safety assertions above test the SAME rule the JavaScript
  # runs, not a re-implementation with different semantics: exact equality for
  # required, `String.starts_with?` prefix matching for the other three. This
  # deliberately mirrors JavaScript that cannot be executed from ExUnit — changing
  # one without the other is the drift this file exists to catch. Returns every
  # bucket that matches (not first-match-wins), so callers can assert the count is
  # exactly one.
  defp classify_lane_buckets(name) do
    []
    |> maybe_add(:required, name in @required_lanes)
    |> maybe_add(:advisory, prefix_match?(name, @advisory_classified_lanes))
    |> maybe_add(:publish_gating, prefix_match?(name, @publish_gating_lanes))
    |> maybe_add(:structural, prefix_match?(name, @structural_lanes))
  end

  defp maybe_add(acc, _bucket, false), do: acc
  defp maybe_add(acc, bucket, true), do: [bucket | acc]

  defp prefix_match?(name, lanes), do: Enum.any?(lanes, &String.starts_with?(name, &1))

  # Bounds MAINTAINING.md's "## Required Checks" section by splitting on the
  # unique "\n## " heading token, same technique as the JS-array splitter
  # above. Returns nil (not a crash) on a renamed/removed heading, so callers
  # can assert non-nil with a message naming the cause instead of getting an
  # opaque FunctionClauseError.
  defp find_required_checks_section(md) do
    md
    |> String.split("\n## ")
    |> Enum.find(&String.starts_with?(&1, "Required Checks"))
  end

  # Parses MAINTAINING.md's "| job id | display name | classification |
  # disposition | reason |" table into {id, name, classification, disposition,
  # reason} tuples. Rejects the separator row, the header row, and any row
  # whose cell count isn't 7 (leading "" + 5 data cells + trailing "") — a `|`
  # inside a free-text reason cell would otherwise drop that row SILENTLY,
  # which is exactly the vacuity risk the caller's `length(rows) == 24`
  # assertion exists to catch loudly instead.
  defp parse_disposition_table(md) do
    md
    |> find_required_checks_section()
    |> Kernel.||("")
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(String.trim(&1), "|"))
    |> Enum.reject(&String.contains?(&1, "---"))
    |> Enum.map(&String.split(&1, "|"))
    |> Enum.reject(&(length(&1) != 7))
    |> Enum.map(fn [_, id, name, cls, disp, reason, _] ->
      {trim_bt(id), trim_bt(name), trim_bt(cls), trim_bt(disp), String.trim(reason)}
    end)
    |> Enum.reject(fn {id, _name, _cls, _disp, _reason} -> id == "job id" end)
  end

  defp trim_bt(s), do: s |> String.trim() |> String.trim("`")

  # {display name, classification} pairs from MAINTAINING.md's parsed rows —
  # shared by every table-vs-registry comparison so a future edit to the pair
  # shape only needs to change one place.
  defp disposition_table_pairs(rows) do
    rows
    |> Enum.map(fn {_id, name, cls, _disp, _reason} -> {name, cls} end)
    |> MapSet.new()
  end

  # {display name, classification} pairs derived from Mailglass.CILanes's four
  # classification accessors — read the lane names from CILanes, never
  # duplicate them as literals in this file.
  defp cilanes_classification_pairs do
    required = Enum.map(Mailglass.CILanes.required_lanes(), &{&1, "required"})
    advisory = Enum.map(Mailglass.CILanes.advisory_classified_lanes(), &{&1, "advisory"})
    publish_gating = Enum.map(Mailglass.CILanes.publish_gating_lanes(), &{&1, "publish-gating"})
    structural = Enum.map(Mailglass.CILanes.structural_lanes(), &{&1, "structural"})

    MapSet.new(required ++ advisory ++ publish_gating ++ structural)
  end
end
