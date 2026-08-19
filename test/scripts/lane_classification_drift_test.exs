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
  # (`core_full_suite`) and the 1.19/OTP 28 job
  # (`core_full_suite_next_toolchain_advisory`).
  @suite_floor_env_occurrences 2

  # Every RUNTIME lane name advisory-matrix.yml produces: 2 Core Full Suite legs +
  # 2 next-toolchain legs + 1 Provider Compatibility leg + 2 Inbound Full Suite legs.
  # Deliberately NOT derived from the parser under test — a count computed from the
  # thing it is counting cannot fail.
  @advisory_matrix_runtime_lane_count 7

  # The MAINTAINING.md top-level heading bounding the advisory-matrix table. Its own
  # heading, never rows inside "Required Checks": that section's parser is bounded by
  # the same "\n## " split and its row count is asserted at exactly 24, so a row filed
  # under the wrong heading shows up as a 31-row failure rather than as new coverage.
  @advisory_matrix_heading "Advisory Matrix Lanes"

  # Bucket sizes for the third (advisory-matrix) classification axis. Hardcoded for
  # the same reason every other count in this file is: a size derived from the list
  # it describes cannot fail.
  @advisory_matrix_gating_count 2
  @advisory_matrix_advisory_count 5

  @required_lanes MapSet.new(Mailglass.CILanes.release_required_lanes())
  @merge_required_lanes MapSet.new(Mailglass.CILanes.required_lanes())
  @advisory_classified_lanes MapSet.new(Mailglass.CILanes.advisory_classified_lanes())
  @publish_gating_lanes MapSet.new(Mailglass.CILanes.publish_gating_lanes())
  @structural_lanes MapSet.new(Mailglass.CILanes.structural_lanes())

  @advisory_matrix_gating_lanes MapSet.new(Mailglass.CILanes.advisory_matrix_gating_lanes())
  @advisory_matrix_advisory_lanes MapSet.new(Mailglass.CILanes.advisory_matrix_advisory_lanes())
  @advisory_matrix_all_lanes MapSet.union(
                               @advisory_matrix_gating_lanes,
                               @advisory_matrix_advisory_lanes
                             )

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "REQUIRED_LANES (publish-hex.yml) set-equals the release-required registry" do
    js_source = File.read!(@publish_hex_path)
    required_from_js = parse_js_array(js_source, "REQUIRED_LANES")

    {only_in_js, only_in_registry} = drift(required_from_js, @required_lanes)

    assert MapSet.size(only_in_js) == 0 and MapSet.size(only_in_registry) == 0,
           "publish-hex.yml's REQUIRED_LANES and Mailglass.CILanes.release_required_lanes/0 " <>
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

    assert MapSet.size(publish_gating_from_js) == 11,
           "expected exactly 11 entries parsed from publish-hex.yml's " <>
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

    assert MapSet.size(required_from_js) == 8,
           "expected exactly 8 entries parsed from publish-hex.yml's REQUIRED_LANES " <>
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

  test "ci.yml parses to exactly 26 jobs and all_classified_lanes/0 returns exactly 26 distinct names" do
    ci_source = File.read!(@ci_yml_path)
    job_names = Mailglass.CIYaml.job_names(ci_source)
    classified = Mailglass.CILanes.all_classified_lanes()

    assert map_size(job_names) == 26,
           "expected exactly 26 ci.yml jobs after deterministic-core and inbound-Dialyzer promotion " <>
             "in Phase 159 — got #{map_size(job_names)}. A future legitimate " <>
             "job addition must update this count deliberately, not delete the guard."

    assert length(classified) == 26,
           "expected Mailglass.CILanes.all_classified_lanes/0 to return exactly 26 entries " <>
             "after deduplicating the merge and release axes — got " <>
             "#{length(classified)}"

    assert MapSet.size(MapSet.new(classified)) == 26,
           "all_classified_lanes/0 returned 26 entries but fewer than 26 distinct strings — " <>
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
               "(core_full_suite's and core_full_suite_next_toolchain_advisory's) — got " <>
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
  # D-24 / D-25: the third classification axis — advisory-matrix.yml's seven
  # runtime lanes, bound three ways (workflow ↔ registry ↔ MAINTAINING.md), the
  # same three-way agreement Phase 141 built for ci.yml.
  # ---------------------------------------------------------------------------

  describe "advisory-matrix.yml lane classification (third axis, D-24/D-25)" do
    test "the two buckets hold #{@advisory_matrix_gating_count} and " <>
           "#{@advisory_matrix_advisory_count} lanes and are disjoint" do
      assert MapSet.size(@advisory_matrix_gating_lanes) == @advisory_matrix_gating_count,
             "expected exactly #{@advisory_matrix_gating_count} entries in " <>
               "Mailglass.CILanes.advisory_matrix_gating_lanes/0 — the Elixir 1.18 / OTP 27 " <>
               "floor pair, one per schema axis — got " <>
               "#{MapSet.size(@advisory_matrix_gating_lanes)}. Widening the gated set is a " <>
               "deliberate act (D-19 confines gating to the declared `~> 1.18` floor); " <>
               "update this count on purpose, do not delete the guard."

      assert MapSet.size(@advisory_matrix_advisory_lanes) == @advisory_matrix_advisory_count,
             "expected exactly #{@advisory_matrix_advisory_count} entries in " <>
               "Mailglass.CILanes.advisory_matrix_advisory_lanes/0 — got " <>
               "#{MapSet.size(@advisory_matrix_advisory_lanes)}"
    end

    # Its own test, not a third assertion in the one above: ExUnit stops at the first
    # failing assert, so a count change would mask the disjointness check and the
    # disjointness check could never be shown to fire on its own.
    test "the two buckets are disjoint" do
      overlap =
        MapSet.intersection(@advisory_matrix_gating_lanes, @advisory_matrix_advisory_lanes)

      assert MapSet.size(overlap) == 0,
             "these lanes are in BOTH advisory-matrix buckets: " <>
               "#{inspect(MapSet.to_list(overlap))}. A lane cannot both gate a publish and " <>
               "be classified as blocking nothing — the two buckets are disjoint by " <>
               "construction and every consumer relies on it."
    end

    test "expanded_matrix_job_names/1 over advisory-matrix.yml set-equals the union of the " <>
           "two buckets" do
      runtime = Mailglass.CIYaml.expanded_matrix_job_names(File.read!(@advisory_matrix_path))

      assert MapSet.size(runtime) > 0,
             "Mailglass.CIYaml.expanded_matrix_job_names/1 parsed no runtime job names — " <>
               "the comparison below would be an empty-set-versus-empty-set vacuous pass"

      {only_in_yaml, only_in_registry} = drift(runtime, @advisory_matrix_all_lanes)

      assert MapSet.size(only_in_yaml) == 0 and MapSet.size(only_in_registry) == 0,
             "advisory-matrix.yml and Mailglass.CILanes's advisory-matrix buckets have " <>
               "drifted — an unclassified advisory-matrix lane is exactly the hidden tier " <>
               "this milestone eliminates:\n" <>
               "  In advisory-matrix.yml but not classified (add to " <>
               "advisory_matrix_gating_lanes/0 or advisory_matrix_advisory_lanes/0 AND to " <>
               "MAINTAINING.md § \"#{@advisory_matrix_heading}\"): " <>
               "#{inspect(MapSet.to_list(only_in_yaml))}\n" <>
               "  Classified but not present in advisory-matrix.yml (stale entry): " <>
               "#{inspect(MapSet.to_list(only_in_registry))}"
    end

    test "negative control: removing one lane from the parsed runtime set makes the " <>
           "registry comparison report it, and only it" do
      runtime = Mailglass.CIYaml.expanded_matrix_job_names(File.read!(@advisory_matrix_path))

      assert drift(runtime, @advisory_matrix_all_lanes) == {MapSet.new(), MapSet.new()},
             "sanity check failed: advisory-matrix.yml's runtime names and the registry's " <>
               "two advisory-matrix buckets should agree before the injected-removal " <>
               "assertion runs"

      # A gating leg deliberately: it is the entry whose silent loss would matter
      # most, since it is the half of the axis that is meant to block a publish.
      removed_entry = "Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)"
      assert removed_entry in MapSet.to_list(runtime)

      {only_in_broken_yaml, only_in_registry} =
        drift(MapSet.delete(runtime, removed_entry), @advisory_matrix_all_lanes)

      assert only_in_registry == MapSet.new([removed_entry]),
             "removing '#{removed_entry}' from the parsed runtime set must make drift/2 " <>
               "report it, and only it, in the 'classified but missing from the workflow' " <>
               "direction — got #{inspect(MapSet.to_list(only_in_registry))}"

      assert MapSet.size(only_in_broken_yaml) == 0,
             "unexpected reverse-direction drift after removing only '#{removed_entry}': " <>
               "#{inspect(MapSet.to_list(only_in_broken_yaml))}"
    end

    test "neither advisory-matrix bucket leaks into all_classified_lanes/0" do
      classified = MapSet.new(Mailglass.CILanes.all_classified_lanes())

      leaked = MapSet.intersection(classified, @advisory_matrix_all_lanes)

      assert MapSet.size(leaked) == 0,
             "these advisory-matrix lanes have been folded into " <>
               "Mailglass.CILanes.all_classified_lanes/0: #{inspect(MapSet.to_list(leaked))}. " <>
               "That accessor is bound by set equality to ci.yml's 24 jobs — folding breaks " <>
               "the three 24-count assertions in this file, both publish-hex.yml " <>
               "set-equality tests, and the MAINTAINING.md disposition-table comparison, all " <>
               "at once. The advisory-matrix axis is additive and must stay separate."
    end

    test "the two gating lane names are not prefixes of one another, in either direction" do
      [first, second] = Enum.sort(Mailglass.CILanes.advisory_matrix_gating_lanes())

      refute String.starts_with?(first, second),
             "prefix collision between the two gating lanes: '#{first}' starts with " <>
               "'#{second}'. gate-ci-green classifies by ordered prefix match for every " <>
               "non-required bucket, so one gating leg's runtime name matching the other's " <>
               "prefix would let a single green leg satisfy both and let a red one hide."

      refute String.starts_with?(second, first),
             "prefix collision between the two gating lanes: '#{second}' starts with " <>
               "'#{first}' — same misclassification hazard, other direction."
    end

    test "no advisory-matrix lane name is a prefix of another, and none carries a " <>
           "table-breaking or uninterpolated character" do
      names = MapSet.to_list(@advisory_matrix_all_lanes)

      for a <- names, b <- names, a != b do
        refute String.starts_with?(b, a),
               "prefix collision: '#{b}' starts with '#{a}' — the gating half of this axis " <>
                 "is matched by exact equality, but the advisory half is prefix-matched, so " <>
                 "a prefix relation across the two would misclassify a lane"
      end

      for name <- names do
        refute String.contains?(name, "|"),
               "'#{name}' contains a pipe character, which would break MAINTAINING.md's " <>
                 "§ \"#{@advisory_matrix_heading}\" table parser"

        refute String.contains?(name, "${{"),
               "'#{name}' is a declared `name:` TEMPLATE, not a runtime name — the registry " <>
                 "must hold the strings GitHub reports live, or every comparison against a " <>
                 "real run reports the lane missing"
      end
    end

    test "MAINTAINING.md's \"#{@advisory_matrix_heading}\" table parses to exactly " <>
           "#{@advisory_matrix_gating_count + @advisory_matrix_advisory_count} rows " <>
           "(anti-vacuity)" do
      md = File.read!(@maintaining_path)

      assert find_section(md, @advisory_matrix_heading) != nil,
             "could not find MAINTAINING.md's '## #{@advisory_matrix_heading}' section — the " <>
               "heading was renamed or removed, which unbinds the table parser below and " <>
               "would otherwise leave it comparing an empty row list against the registry"

      rows = parse_advisory_matrix_table(md)

      expected = @advisory_matrix_gating_count + @advisory_matrix_advisory_count

      assert length(rows) == expected,
             "expected exactly #{expected} rows in MAINTAINING.md's " <>
               "'#{@advisory_matrix_heading}' table — got #{length(rows)}. A '|' inside a " <>
               "free-text reason cell silently drops that row under the cell-count reject, " <>
               "which is the vacuity risk this exact count guards against."

      assert length(rows) == length(Enum.uniq(rows)),
             "duplicate rows in MAINTAINING.md's '#{@advisory_matrix_heading}' table"
    end

    test "MAINTAINING.md's advisory-matrix table display names set-equal the union of the " <>
           "two buckets" do
      table_names =
        @maintaining_path
        |> File.read!()
        |> parse_advisory_matrix_table()
        |> Enum.map(fn {_id, name, _cls, _disp, _reason} -> name end)
        |> MapSet.new()

      assert MapSet.size(table_names) > 0,
             "parsed zero display names from MAINTAINING.md's " <>
               "'#{@advisory_matrix_heading}' table — the comparison below would be vacuous"

      {only_in_md, only_in_registry} = drift(table_names, @advisory_matrix_all_lanes)

      assert MapSet.size(only_in_md) == 0 and MapSet.size(only_in_registry) == 0,
             "MAINTAINING.md's '#{@advisory_matrix_heading}' table and Mailglass.CILanes's " <>
               "advisory-matrix buckets have drifted:\n" <>
               "  In MAINTAINING.md but missing from CILanes: " <>
               "#{inspect(MapSet.to_list(only_in_md))}\n" <>
               "  In CILanes but missing from MAINTAINING.md: " <>
               "#{inspect(MapSet.to_list(only_in_registry))}"
    end

    test "negative control: dropping one row from the parsed advisory-matrix table makes " <>
           "the comparison report only that lane" do
      table_names =
        @maintaining_path
        |> File.read!()
        |> parse_advisory_matrix_table()
        |> Enum.map(fn {_id, name, _cls, _disp, _reason} -> name end)
        |> MapSet.new()

      assert drift(table_names, @advisory_matrix_all_lanes) == {MapSet.new(), MapSet.new()},
             "sanity check failed: MAINTAINING.md's '#{@advisory_matrix_heading}' table and " <>
               "the registry's advisory-matrix buckets should agree before the " <>
               "injected-removal assertion runs"

      # The advisory half this time — the gating half is covered by the workflow-side
      # negative control above, and an advisory row is the one a maintainer is most
      # likely to forget when adding a lane.
      removed_entry = "Inbound Full Suite Advisory (schema public)"
      assert removed_entry in MapSet.to_list(table_names)

      {only_in_broken_md, only_in_registry} =
        drift(MapSet.delete(table_names, removed_entry), @advisory_matrix_all_lanes)

      assert only_in_registry == MapSet.new([removed_entry]),
             "dropping '#{removed_entry}' from the parsed table must make drift/2 report " <>
               "it, and only it, in the 'missing from MAINTAINING.md' direction — got " <>
               "#{inspect(MapSet.to_list(only_in_registry))}"

      assert MapSet.size(only_in_broken_md) == 0,
             "unexpected reverse-direction drift after dropping only '#{removed_entry}': " <>
               "#{inspect(MapSet.to_list(only_in_broken_md))}"
    end

    test "every advisory-matrix row's classification and disposition are drawn from the " <>
           "closed vocabularies, and classification tracks the bucket" do
      rows = parse_advisory_matrix_table(File.read!(@maintaining_path))

      assert rows != [], "parsed zero advisory-matrix rows — see the row-count test above"

      for {id, name, cls, disp, _reason} <- rows do
        assert cls in ~w(required advisory publish-gating structural),
               "MAINTAINING.md advisory-matrix row '#{id}' / '#{name}' has classification " <>
                 "'#{cls}', which is not a member of the closed vocabulary"

        assert disp in ~w(promote keep-with-reason retire),
               "MAINTAINING.md advisory-matrix row '#{id}' / '#{name}' has disposition " <>
                 "'#{disp}', which is not a member of the closed vocabulary"

        # Plan 143-13 wired gate-ci-green to advisory-matrix.yml, so the gating pair
        # is no longer a recommendation. Its rows moved from `advisory` / `promote` to
        # `publish-gating` / `keep-with-reason` in that same commit, exactly as this
        # assertion's previous message and MAINTAINING.md's own prose said they would.
        # Classification is now the load-bearing half: it is what actually differs
        # between the two buckets, so a gating leg silently downgraded to `advisory`
        # in the docs fails here.
        {expected_classification, expected_bucket} =
          if MapSet.member?(@advisory_matrix_gating_lanes, name),
            do: {"publish-gating", "advisory_matrix_gating_lanes/0"},
            else: {"advisory", "advisory_matrix_advisory_lanes/0"}

        assert cls == expected_classification,
               "'#{name}' sits in #{expected_bucket} but MAINTAINING.md records " <>
                 "classification '#{cls}' rather than '#{expected_classification}'. " <>
                 "gate-ci-green reads advisory-matrix.yml as of plan 143-13: the two " <>
                 "Core Full Suite floor legs block a Hex publish, and the other five " <>
                 "block nothing. A doc that says otherwise is the signal-honesty defect " <>
                 "this milestone exists to fix."

        assert disp == "keep-with-reason",
               "MAINTAINING.md advisory-matrix row '#{name}' records disposition " <>
                 "'#{disp}'. Every row on this axis is now `keep-with-reason`: the " <>
                 "gating pair was `promote` only while its promotion was still a " <>
                 "recommendation, and plan 143-13 executed it."
      end
    end
  end

  # ---------------------------------------------------------------------------
  # HARNESS-04 / D-19, D-22, D-23: gate-ci-green's advisory-matrix arrays, and the
  # dispatch-only override that makes gating affordable.
  #
  # These bind the THIRD axis to `publish-hex.yml` the same way the four ci.yml
  # arrays above are bound. Without them the workflow could gate on a lane name
  # the registry no longer holds — which reports `(missing)` and blocks every
  # publish — or silently stop gating on one it does.
  # ---------------------------------------------------------------------------

  describe "publish-hex.yml's advisory-matrix arrays and override (HARNESS-04)" do
    test "ADVISORY_MATRIX_GATING_LANES (publish-hex.yml) set-equals " <>
           "Mailglass.CILanes.advisory_matrix_gating_lanes/0" do
      gating_from_js = parse_js_array(File.read!(@publish_hex_path), "ADVISORY_MATRIX_GATING_LANES")

      assert MapSet.size(gating_from_js) == @advisory_matrix_gating_count,
             "expected exactly #{@advisory_matrix_gating_count} entries parsed from " <>
               "publish-hex.yml's ADVISORY_MATRIX_GATING_LANES array — got " <>
               "#{MapSet.size(gating_from_js)}. A zero here would make the set-equality " <>
               "below compare an empty set and pass vacuously while the gate matched " <>
               "nothing; the parser, the array name, or the file format changed."

      {only_in_js, only_in_registry} = drift(gating_from_js, @advisory_matrix_gating_lanes)

      assert MapSet.size(only_in_js) == 0 and MapSet.size(only_in_registry) == 0,
             "publish-hex.yml's ADVISORY_MATRIX_GATING_LANES and " <>
               "Mailglass.CILanes.advisory_matrix_gating_lanes/0 have drifted. The gate " <>
               "matches these by EXACT equality, so a name in the workflow that the " <>
               "registry no longer holds reports '(missing)' and blocks every publish:\n" <>
               "  In the JS array but missing from CILanes: " <>
               "#{inspect(MapSet.to_list(only_in_js))}\n" <>
               "  In CILanes but missing from the JS array: " <>
               "#{inspect(MapSet.to_list(only_in_registry))}"
    end

    test "ADVISORY_MATRIX_ADVISORY_LANES (publish-hex.yml) set-equals " <>
           "Mailglass.CILanes.advisory_matrix_advisory_lanes/0" do
      advisory_from_js =
        parse_js_array(File.read!(@publish_hex_path), "ADVISORY_MATRIX_ADVISORY_LANES")

      assert MapSet.size(advisory_from_js) == @advisory_matrix_advisory_count,
             "expected exactly #{@advisory_matrix_advisory_count} entries parsed from " <>
               "publish-hex.yml's ADVISORY_MATRIX_ADVISORY_LANES array — got " <>
               "#{MapSet.size(advisory_from_js)}. Same vacuity risk as the gating array: " <>
               "an empty parse would make the comparison below prove nothing."

      {only_in_js, only_in_registry} = drift(advisory_from_js, @advisory_matrix_advisory_lanes)

      assert MapSet.size(only_in_js) == 0 and MapSet.size(only_in_registry) == 0,
             "publish-hex.yml's ADVISORY_MATRIX_ADVISORY_LANES and " <>
               "Mailglass.CILanes.advisory_matrix_advisory_lanes/0 have drifted — an " <>
               "advisory-matrix lane the workflow cannot classify blocks the publish when " <>
               "it is red:\n" <>
               "  In the JS array but missing from CILanes: " <>
               "#{inspect(MapSet.to_list(only_in_js))}\n" <>
               "  In CILanes but missing from the JS array: " <>
               "#{inspect(MapSet.to_list(only_in_registry))}"
    end

    test "the two parsed advisory-matrix arrays are disjoint" do
      source = File.read!(@publish_hex_path)
      gating_from_js = parse_js_array(source, "ADVISORY_MATRIX_GATING_LANES")
      advisory_from_js = parse_js_array(source, "ADVISORY_MATRIX_ADVISORY_LANES")

      assert MapSet.size(gating_from_js) > 0 and MapSet.size(advisory_from_js) > 0,
             "one of publish-hex.yml's two advisory-matrix arrays parsed empty — an " <>
               "intersection with an empty set is empty, so this test would pass while " <>
               "proving nothing"

      overlap = MapSet.intersection(gating_from_js, advisory_from_js)

      assert MapSet.size(overlap) == 0,
             "these lanes appear in BOTH of publish-hex.yml's advisory-matrix arrays: " <>
               "#{inspect(MapSet.to_list(overlap))}. classifyAdvisoryMatrix/1 returns the " <>
               "FIRST matching bucket, so a duplicated lane would be silently treated as " <>
               "gating and never warned on as advisory — or the reverse after a reorder."
    end

    test "negative control: removing one entry from the parsed ADVISORY_MATRIX_GATING_LANES " <>
           "set makes the drift comparison report it, and only it" do
      gating_from_js = parse_js_array(File.read!(@publish_hex_path), "ADVISORY_MATRIX_GATING_LANES")

      assert drift(gating_from_js, @advisory_matrix_gating_lanes) == {MapSet.new(), MapSet.new()},
             "sanity check failed: ADVISORY_MATRIX_GATING_LANES and " <>
               "Mailglass.CILanes.advisory_matrix_gating_lanes/0 should agree before the " <>
               "injected-breakage assertion runs"

      # The mailglass-schema leg: the axis a reader skims past, and the one whose
      # silent loss would leave the gate half-blind while still looking wired up.
      removed_entry = "Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)"
      assert removed_entry in MapSet.to_list(gating_from_js)

      {only_in_broken_js, only_in_registry} =
        drift(MapSet.delete(gating_from_js, removed_entry), @advisory_matrix_gating_lanes)

      assert only_in_registry == MapSet.new([removed_entry]),
             "removing '#{removed_entry}' from the parsed set must make drift/2 — the same " <>
               "helper the real assertion uses — report it, and only it, in the 'missing " <>
               "from the JS array' direction; got " <>
               "#{inspect(MapSet.to_list(only_in_registry))}"

      assert MapSet.size(only_in_broken_js) == 0,
             "unexpected reverse-direction drift after removing only '#{removed_entry}': " <>
               "#{inspect(MapSet.to_list(only_in_broken_js))}"
    end

    test "negative control: removing one entry from the parsed " <>
           "ADVISORY_MATRIX_ADVISORY_LANES set makes the drift comparison report it, and " <>
           "only it" do
      advisory_from_js =
        parse_js_array(File.read!(@publish_hex_path), "ADVISORY_MATRIX_ADVISORY_LANES")

      assert drift(advisory_from_js, @advisory_matrix_advisory_lanes) ==
               {MapSet.new(), MapSet.new()},
             "sanity check failed: ADVISORY_MATRIX_ADVISORY_LANES and " <>
               "Mailglass.CILanes.advisory_matrix_advisory_lanes/0 should agree before the " <>
               "injected-breakage assertion runs"

      # A next-toolchain leg: the one whose absence on a pull_request run is a
      # designed outcome, so it is the entry most likely to be "cleaned up" by
      # someone who reads its absence as staleness.
      removed_entry =
        "Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema public)"

      assert removed_entry in MapSet.to_list(advisory_from_js)

      {only_in_broken_js, only_in_registry} =
        drift(MapSet.delete(advisory_from_js, removed_entry), @advisory_matrix_advisory_lanes)

      assert only_in_registry == MapSet.new([removed_entry]),
             "removing '#{removed_entry}' from the parsed set must make drift/2 report it, " <>
               "and only it, in the 'missing from the JS array' direction; got " <>
               "#{inspect(MapSet.to_list(only_in_registry))}"

      assert MapSet.size(only_in_broken_js) == 0,
             "unexpected reverse-direction drift after removing only '#{removed_entry}': " <>
               "#{inspect(MapSet.to_list(only_in_broken_js))}"
    end

    test "the Core Full Suite gate blocks by its own named message, and its verdict is " <>
           "reached by a presence loop rather than a filter (posture guard)" do
      source = File.read!(@publish_hex_path)

      assert String.contains?(
               source,
               "Delivery blocked: Core Full Suite gating lane(s) did not pass on SHA"
             ),
             "publish-hex.yml no longer contains the Core Full Suite gating failure " <>
               "message. HARNESS-04's whole content is that these two legs can veto a " <>
               "publish; if this message is gone, either the gate was removed or its " <>
               "verdict now shares the ci.yml message and cannot be told apart in a log."

      assert String.contains?(source, "for (const lane of ADVISORY_MATRIX_GATING_LANES)"),
             "publish-hex.yml no longer iterates ADVISORY_MATRIX_GATING_LANES as a " <>
               "presence loop. A filter over the jobs the API returned cannot observe a " <>
               "lane that is ABSENT — and a gating leg that is absent is not green. This " <>
               "is the same guarantee the required-lane presence loop provides, and it " <>
               "must not be refactored into a filter."
    end

    test "both override inputs are declared, the reason is required, and the override is " <>
           "inert on the release event" do
      source = File.read!(@publish_hex_path)

      skip_block = workflow_dispatch_input_block(source, "skip_core_full_suite_gate")
      reason_block = workflow_dispatch_input_block(source, "core_full_suite_gate_skip_reason")

      assert skip_block != nil,
             "publish-hex.yml declares no `skip_core_full_suite_gate` workflow_dispatch " <>
               "input — the documented override the gating trade depends on is gone, which " <>
               "makes a blocked release unaffordable (its gated steps include a " <>
               "network-dependent inbound deps.get)"

      assert reason_block != nil,
             "publish-hex.yml declares no `core_full_suite_gate_skip_reason` " <>
               "workflow_dispatch input — the override would become reason-free"

      assert String.contains?(reason_block, "required: true"),
             "publish-hex.yml's `core_full_suite_gate_skip_reason` input is not marked " <>
               "`required: true`. An override with an optional reason is an override with " <>
               "no reason, and D-30 records exactly that decay as the risk this input " <>
               "exists to hold off. Parsed block was:\n#{reason_block}"

      assert String.contains?(
               source,
               "process.env.SKIP_CORE_FULL_SUITE_GATE === 'true' && context.eventName !== 'release'"
             ),
             "publish-hex.yml no longer guards the override on the triggering event. " <>
               "Without `context.eventName !== 'release'` the hands-free release path " <>
               "could self-skip its own publish gate (T-143-46), which is the one thing " <>
               "the override must never be able to do."
    end

    test "negative control: stripping `required: true` from the parsed reason-input block " <>
           "makes the required-marker assertion report it" do
      source = File.read!(@publish_hex_path)

      assert source
             |> workflow_dispatch_input_block("core_full_suite_gate_skip_reason")
             |> String.contains?("required: true"),
             "sanity check failed: the unmodified workflow should already mark the reason " <>
               "input required before the injected-breakage assertion runs"

      # Strips the marker from THIS input only. Anchored on the input key rather
      # than replaced globally: the pre-existing `tag:` input carries a
      # byte-identical `required: true` / `type: string` pair, so a global replace
      # would mutate that one as well and the control would stop being about the
      # override's reason. Exercises the SAME extractor the real assertion uses, so
      # a future edit loosening that extractor into a whole-file search breaks this
      # control too — a whole-file search would keep passing on `tag:`'s marker.
      key = "\n      core_full_suite_gate_skip_reason:\n"
      [before_key, after_key] = String.split(source, key, parts: 2)

      broken =
        before_key <>
          key <> String.replace(after_key, "        required: true\n", "", global: false)

      refute broken
             |> workflow_dispatch_input_block("core_full_suite_gate_skip_reason")
             |> String.contains?("required: true"),
             "removing `required: true` from the reason input must be observable by the " <>
               "same extractor the assertion above uses — otherwise that assertion could " <>
               "pass on a workflow whose override reason had become optional"
    end
  end

  test "Phase 159 policy keeps target required IDs disjoint from advisory-only IDs" do
    policy = Mailglass.CIPolicy.load!()
    target_ids = policy.target_required |> Enum.map(& &1.id) |> MapSet.new()
    advisory_ids = MapSet.new(policy.advisory)

    assert MapSet.disjoint?(target_ids, advisory_ids)

    promoted =
      update_in(
        policy.target_required,
        &(&1 ++
            [
              %{
                id: "demo_browser_evidence",
                name: "Demo Browser Evidence (Docker Compose / Chromium)",
                behavior: :docs,
                ci_only_reason: "advisory"
              }
            ])
      )

    assert_raise ArgumentError, ~r/target required and advisory lane IDs overlap/, fn ->
      Mailglass.CIPolicy.validate!(promoted)
    end
  end

  # ---------------------------------------------------------------------------
  # Parsers
  # ---------------------------------------------------------------------------

  # Extracts one `workflow_dispatch` input's own indented block from a workflow
  # source, bounded by the next line at or above the input-key indent. Bounding is
  # the whole point: a whole-file `String.contains?(source, "required: true")` would
  # pass on the pre-existing `tag:` input's marker and prove nothing about this one.
  # Returns nil (not a crash) when the input is absent, so the caller's assertion
  # names the cause.
  defp workflow_dispatch_input_block(source, input_name) do
    case String.split(source, "\n      #{input_name}:\n", parts: 2) do
      [_before, rest] ->
        rest
        |> String.split("\n")
        |> Enum.take_while(fn line ->
          String.trim(line) == "" or String.starts_with?(line, "        ")
        end)
        |> Enum.join("\n")

      _ ->
        nil
    end
  end

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
    |> maybe_add(:required, name in @merge_required_lanes)
    |> maybe_add(:advisory, prefix_match?(name, @advisory_classified_lanes))
    |> maybe_add(
      :publish_gating,
      not prefix_match?(name, @merge_required_lanes) and
        prefix_match?(name, @publish_gating_lanes)
    )
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
  defp find_required_checks_section(md), do: find_section(md, "Required Checks")

  # Generalised from find_required_checks_section/1 (plan 143-11) so the
  # advisory-matrix table can be bounded by its OWN top-level heading. The bound is
  # what keeps the two tables' row counts independent: rows filed under the wrong
  # heading are counted against the wrong assertion and fail loudly.
  defp find_section(md, heading) do
    md
    |> String.split("\n## ")
    |> Enum.find(&String.starts_with?(&1, heading))
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
    |> parse_pipe_table()
  end

  # The advisory-matrix table (plan 143-11 / D-25) uses the identical 5-column shape
  # and is parsed by the identical rules, bounded by its own top-level heading. Note
  # its `job id` cells REPEAT across rows — one job expands to one runtime lane per
  # matrix row — so the "distinct job ids" assertion that applies to the required-checks
  # table deliberately does not apply here.
  defp parse_advisory_matrix_table(md) do
    md
    |> find_section(@advisory_matrix_heading)
    |> parse_pipe_table()
  end

  defp parse_pipe_table(section) do
    section
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
    required = Enum.map(Mailglass.CILanes.release_required_lanes(), &{&1, "required"})
    advisory = Enum.map(Mailglass.CILanes.advisory_classified_lanes(), &{&1, "advisory"})
    publish_gating = Enum.map(Mailglass.CILanes.publish_gating_lanes(), &{&1, "publish-gating"})
    structural = Enum.map(Mailglass.CILanes.structural_lanes(), &{&1, "structural"})

    MapSet.new(required ++ advisory ++ publish_gating ++ structural)
  end
end
