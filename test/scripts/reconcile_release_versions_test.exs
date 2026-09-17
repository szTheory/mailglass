defmodule Mailglass.Scripts.ReconcileReleaseVersionsTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/reconcile_release_versions.exs")
  @release_policy_script Path.join(@repo_root, "scripts/release_policy.exs")
  @packages ~w(mailglass mailglass_admin mailglass_inbound)

  setup_all do
    Code.require_file(@script)
    Code.require_file(@release_policy_script)
    :ok
  end

  test "classifies known repository/live patch drift without inventing a candidate" do
    assert {:drift, report} =
             reconcile(
               repository_records("2.4.0", "2.4.0", "2.1.1"),
               hex_records("2.4.1", "2.4.1", "2.1.2")
             )

    assert report.status == "drift"
    assert report.package_set == @packages

    assert report.drift == %{
             "mailglass" => %{repository: "2.4.0", live: "2.4.1"},
             "mailglass_admin" => %{repository: "2.4.0", live: "2.4.1"},
             "mailglass_inbound" => %{repository: "2.1.1", live: "2.1.2"}
           }

    refute Map.has_key?(report, :candidate_versions)
    refute inspect(report) =~ "2.6.0"
    refute inspect(report) =~ "2.3.0"
  end

  test "accepts exact equality while preserving linked core/admin and independent inbound" do
    assert {:ok, report} =
             reconcile(
               repository_records("2.4.1", "2.4.1", "2.1.2"),
               hex_records("2.4.1", "2.4.1", "2.1.2")
             )

    assert report.status == "reconciled"
    assert report.package_set == @packages

    # Mirrors this test's own synthetic records, not the published baselines —
    # the two were equal until 2.5.0 shipped, which is why they are now separate.
    assert report.baselines == %{
             "mailglass" => "2.4.1",
             "mailglass_admin" => "2.4.1",
             "mailglass_inbound" => "2.1.2"
           }

    assert report.constraints == %{
             "mailglass_admin->mailglass" => "~> 2.0",
             "mailglass_admin->mailglass_inbound" => "~> 2.0",
             "mailglass_inbound->mailglass" => "~> 2.0"
           }
  end

  test "dependency constraints are checked against live versions, not only stale source" do
    repository = repository_records("2.4.0", "2.4.0", "2.1.1")

    repository =
      replace_record(
        repository,
        "mailglass_admin",
        "dependencies",
        %{"mailglass" => "== 2.4.0", "mailglass_inbound" => "~> 2.0"}
      )

    assert {:error, %{reason: :constraint_mismatch}} =
             reconcile(repository, hex_records("2.4.1", "2.4.1", "2.1.2"))
  end

  test "fails closed on missing, duplicate, unknown, malformed, retired, and conflicting evidence" do
    repository = repository_records("2.4.1", "2.4.1", "2.1.2")
    hex = hex_records("2.4.1", "2.4.1", "2.1.2")

    cases = [
      {:missing_repository, []},
      {:missing_repository, tl(repository)},
      {:duplicate_repository, repository ++ [hd(repository)]},
      {:unknown_repository, repository ++ [%{"name" => "mailglass_extra", "version" => "1.0.0"}]},
      {:malformed_repository, replace_record(repository, "mailglass", "version", "latest")}
    ]

    for {expected, changed} <- cases do
      assert {:error, %{reason: ^expected}} = reconcile(changed, hex)
    end

    hex_cases = [
      {:missing_hex, []},
      {:missing_hex, tl(hex)},
      {:duplicate_hex, hex ++ [hd(hex)]},
      {:unknown_hex, hex ++ [hex_record("mailglass_extra", "1.0.0")]},
      {:malformed_hex, replace_record(hex, "mailglass", "latest_stable_version", "latest")},
      {:retired_hex, replace_record(hex, "mailglass", "retirement", %{"reason" => "deprecated"})},
      {:conflicting_hex, replace_record(hex, "mailglass", "release_version", "2.4.0")},
      {:conflicting_hex, replace_record(hex, "mailglass", "package_name", "mailglass_admin")}
    ]

    for {expected, changed} <- hex_cases do
      assert {:error, %{reason: ^expected}} = reconcile(repository, changed)
    end
  end

  test "fixture CLI reports drift with a nonzero status and equality with zero" do
    in_tmp(fn root ->
      fixture_path = Path.join(root, "fixture.json")

      drift_fixture = %{
        "repository" => repository_records("2.4.0", "2.4.0", "2.1.1"),
        "hex" => hex_records("2.4.1", "2.4.1", "2.1.2")
      }

      File.write!(fixture_path, Jason.encode!(drift_fixture))
      assert {2, output} = apply(reconciler(), :cli, [["--fixture", fixture_path], root])
      assert %{"result" => "drift", "report" => report} = Jason.decode!(output)
      refute Map.has_key?(report, "candidate_versions")

      equal_fixture = %{
        "repository" => repository_records("2.4.1", "2.4.1", "2.1.2"),
        "hex" => hex_records("2.4.1", "2.4.1", "2.1.2")
      }

      File.write!(fixture_path, Jason.encode!(equal_fixture))
      assert {0, output} = apply(reconciler(), :cli, [["--fixture", fixture_path], root])
      assert %{"result" => "ok"} = Jason.decode!(output)
    end)
  end

  test "parses narrow source contracts without evaluating mix files" do
    in_tmp(fn root ->
      write!(root, "mix.exs", """
      raise "must not execute"
      defmodule Fixture.Core do
        @version "2.4.1"
      end
      """)

      write!(root, "mailglass_admin/mix.exs", """
      raise "must not execute"
      defmodule Fixture.Admin do
        @version "2.4.1"
        defp mailglass_dep, do: {:mailglass, "~> 2.0"}
        defp mailglass_inbound_dep, do: {:mailglass_inbound, "~> 2.0", optional: true}
      end
      """)

      write!(root, "mailglass_inbound/mix.exs", """
      raise "must not execute"
      defmodule Fixture.Inbound do
        @version "2.1.2"
        defp mailglass_dep, do: {:mailglass, "~> 2.0"}
      end
      """)

      write!(root, ".release-please-manifest.json", Jason.encode!(manifest_versions()))

      assert {:ok, records} = apply(reconciler(), :parse_repository, [root])

      assert Enum.map(records, &{&1["name"], &1["version"]}) ==
               Enum.map(repository_records("2.4.1", "2.4.1", "2.1.2"), &{&1["name"], &1["version"]})

      refute_received {:fixture_executed, _}
    end)
  end

  test "source parser rejects missing and duplicate version declarations" do
    for source <- [
          "defmodule Fixture.Core do\nend\n",
          "defmodule Fixture.Core do\n  @version \"2.4.1\"\n  @version \"2.4.1\"\nend\n"
        ] do
      in_tmp(fn root ->
        write_repository_sources!(root, source)

        assert {:error, %{reason: :malformed_repository}} =
                 apply(reconciler(), :parse_repository, [root])
      end)
    end
  end

  test "live parser rejects prerelease, malformed, duplicate, retired, and conflicting payload shapes" do
    valid_package = %{
      "name" => "mailglass",
      "latest_stable_version" => "2.4.1",
      "releases" => [%{"version" => "2.4.1"}]
    }

    valid_release = %{
      "version" => "2.4.1",
      "retirement" => nil,
      "checksum" => String.duplicate("a", 64),
      "has_docs" => true
    }

    package_mutations = [
      {:malformed_hex, Map.put(valid_package, "latest_stable_version", "2.4.1-rc.1")},
      {:malformed_hex, Map.put(valid_package, "releases", %{})},
      {:duplicate_hex,
       Map.put(valid_package, "releases", [
         %{"version" => "2.4.1", "retirement" => nil},
         %{"version" => "2.4.1", "retirement" => nil}
       ])},
      {:retired_hex,
       Map.put(valid_package, "releases", [
         %{"version" => "2.4.1", "retirement" => %{"reason" => "deprecated"}}
       ])},
      {:conflicting_hex, Map.put(valid_package, "name", "mailglass_admin")}
    ]

    for {expected, package_payload} <- package_mutations do
      getter = fixture_getter(package_payload, valid_release)
      assert {:error, %{reason: ^expected}} = apply(reconciler(), :fetch_live, [getter])
    end

    release_mutations = [
      {:malformed_hex, []},
      {:malformed_hex, Map.put(valid_release, "version", "2.4.1-rc.1")},
      {:retired_hex, Map.put(valid_release, "retirement", %{"reason" => "deprecated"})},
      {:conflicting_hex, Map.put(valid_release, "version", "2.4.0")}
    ]

    for {expected, release_payload} <- release_mutations do
      getter = fixture_getter(valid_package, release_payload)
      assert {:error, %{reason: ^expected}} = apply(reconciler(), :fetch_live, [getter])
    end
  end

  test "live parser accepts active package summaries whose retirement is authoritative only on the exact release" do
    getter = fn url ->
      versions = baseline_versions()

      case Enum.find(@packages, &String.ends_with?(url, "/#{&1}")) do
        nil ->
          name = Enum.find(@packages, &String.contains?(url, "/#{&1}/releases/"))
          version = versions[name]

          {:ok,
           Jason.encode!(%{
             "version" => version,
             "retirement" => nil,
             "checksum" => String.duplicate("a", 64),
             "has_docs" => true
           })}

        name ->
          version = versions[name]

          {:ok,
           Jason.encode!(%{
             "name" => name,
             "latest_stable_version" => version,
             "releases" => [%{"version" => version, "has_docs" => true}]
           })}
      end
    end

    assert {:ok, records} = apply(reconciler(), :fetch_live, [getter])

    assert Enum.map(records, &{&1["name"], &1["release_version"]}) ==
             Enum.map(@packages, &{&1, baseline_versions()[&1]})
  end

  test "builds only the inactive version-neutral three-package target" do
    evidence = evidence_identifiers()
    target = apply(reconciler(), :inactive_target, [baseline_versions(), evidence])

    assert target["schema_version"] == 1
    assert target["status"] == "inactive"
    assert target["package_set"] == @packages
    assert target["baselines"] == baseline_versions()
    assert target["candidate_versions"] == nil
    assert target["proposal_identity"] == %{"head_sha" => nil, "source_sha" => nil}

    assert target["publishable_content"] == %{
             "algorithm" => "sha256",
             "digest" => nil,
             "excludes" => [".planning/release-target.json"]
           }

    assert target["final_identity"] == %{"tag_sha" => nil}

    assert target["states"] == %{
             "capture" => "inactive",
             "authorization" => "unauthorized",
             "publication" => "not_started"
           }

    assert {:ok, _} = apply(reconciler(), :validate_inactive_target, [target])
  end

  test "repository metadata preserves published baselines or an exact generated proposal" do
    assert {:ok, records} = apply(reconciler(), :parse_repository, [@repo_root])

    repository_versions = Map.new(records, &{&1["name"], &1["version"]})

    if release_candidate_tree?(repository_versions) do
      for name <- @packages do
        assert Version.compare(repository_versions[name], baseline_versions()[name]) == :gt,
               "canonical release proposal must advance #{name} beyond its published baseline"
      end
    else
      assert repository_versions == baseline_versions()
    end

    assert File.read!(Path.join(@repo_root, "CHANGELOG.md")) =~
             "## [2.4.1](https://github.com/szTheory/mailglass/compare/mailglass-v2.4.0...mailglass-v2.4.1) (2026-08-03)"

    assert File.read!(Path.join(@repo_root, "mailglass_admin/CHANGELOG.md")) =~
             "## [2.4.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.4.0...mailglass_admin-v2.4.1) (2026-08-03)"

    assert File.read!(Path.join(@repo_root, "mailglass_inbound/CHANGELOG.md")) =~
             "## [2.1.2](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v2.1.1...mailglass_inbound-v2.1.2) (2026-08-03)"

    # The published baselines this test now asserts against.
    assert File.read!(Path.join(@repo_root, "CHANGELOG.md")) =~
             "## [2.6.0](https://github.com/szTheory/mailglass/compare/mailglass-v2.5.0...mailglass-v2.6.0) (2026-09-17)"

    assert File.read!(Path.join(@repo_root, "mailglass_admin/CHANGELOG.md")) =~
             "## [2.6.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.5.0...mailglass_admin-v2.6.0) (2026-09-17)"

    assert File.read!(Path.join(@repo_root, "mailglass_inbound/CHANGELOG.md")) =~
             "## [2.3.0](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v2.2.0...mailglass_inbound-v2.3.0) (2026-09-17)"

    # The publish fan-out advances only mailglass_inbound's summary; core and
    # admin lag a release behind until someone regenerates them. That happened
    # at 2.5.0 and again at 2.6.0, so it is the shape of the pipeline, not a
    # one-off. Both were regenerated with `mix mailglass.publish.check` under
    # the Publish Summary Snapshot Protocol (MAINTAINING.md) as part of this
    # close-out, so all three agree with the published baseline again.
    #
    # The summary files remain publication evidence — they are regenerated by
    # that task, never hand-written — but "not hand-written" is not the same as
    # "never changes", and an earlier note here conflated the two.
    published_linked_versions = baseline_versions()
    core_version = published_linked_versions["mailglass"]
    admin_version = published_linked_versions["mailglass_admin"]

    expected_summaries = %{
      "mailglass" => %{
        "version" => core_version,
        "manifest_version" => core_version,
        "source_ref" => "v" <> core_version,
        "linked_versions" => published_linked_versions
      },
      "mailglass_admin" => %{
        "version" => admin_version,
        "manifest_version" => admin_version,
        "source_ref" => "v" <> admin_version,
        "linked_versions" => published_linked_versions
      },
      "mailglass_inbound" => inbound_summary_expectation(repository_versions)
    }

    for {name, expected} <- expected_summaries do
      summary = read_json!(Path.join(@repo_root, ".planning/publish/#{name}-publish-summary.json"))
      assert Map.take(summary, Map.keys(expected)) == expected
    end

    target = read_json!(Path.join(@repo_root, ".planning/release-target.json"))

    assert target["baselines"] == baseline_versions()
    assert {:ok, ^target} = apply(release_policy(), :validate_target, [target])

    case target["status"] do
      "inactive" ->
        assert target ==
                 apply(reconciler(), :inactive_target, [baseline_versions(), evidence_identifiers()])

        assert {:ok, ^target} = apply(reconciler(), :validate_inactive_target, [target])

      status when status in ["captured", "authorized"] ->
        reviewed = %{
          "candidate_versions" => target["candidate_versions"],
          "proposal_identity" => target["proposal_identity"],
          "publishable_content" => %{"digest" => target["publishable_content"]["digest"]}
        }

        assert {:ok, ^target} = apply(reconciler(), :validate_activation, [target, reviewed])

      status when status in ["published", "completed"] ->
        assert target["states"]["publication"] == "published"
    end
  end

  defp release_policy, do: Module.concat([Mailglass, ReleasePolicy])

  test "inactive target validation rejects unexpected top-level or evidence fields" do
    target = apply(reconciler(), :inactive_target, [baseline_versions(), evidence_identifiers()])

    mutations = [
      Map.put(target, "release_packages", ["mailglass"]),
      put_in(target, ["required_evidence_identifiers", "candidate_version"], "99.98.97")
    ]

    for mutated <- mutations do
      assert {:error, %{reason: :invalid_package_set}} =
               apply(reconciler(), :validate_inactive_target, [mutated])
    end
  end

  test "activation rejects every absent or automation-mismatched candidate identity" do
    reviewed = reviewed_candidate()
    complete = complete_candidate_target(reviewed)

    assert {:ok, _} = apply(reconciler(), :validate_activation, [complete, reviewed])

    mutations = [
      put_in(complete, ["candidate_versions"], nil),
      put_in(complete, ["candidate_versions", "mailglass_inbound"], nil),
      put_in(complete, ["proposal_identity", "head_sha"], nil),
      put_in(complete, ["proposal_identity", "source_sha"], nil),
      put_in(complete, ["publishable_content", "digest"], nil),
      put_in(complete, ["candidate_versions", "mailglass"], "9.9.9"),
      put_in(complete, ["proposal_identity", "head_sha"], String.duplicate("f", 40)),
      put_in(complete, ["publishable_content", "digest"], String.duplicate("f", 64))
    ]

    for mutated <- mutations do
      assert {:error, _} = apply(reconciler(), :validate_activation, [mutated, reviewed])
    end
  end

  test "activation enforces the exact target and evidence schema at every layer" do
    reviewed = reviewed_candidate()
    complete = complete_candidate_target(reviewed)

    target_mutations = [
      Map.delete(complete, "status"),
      Map.delete(complete, "required_evidence_identifiers"),
      Map.put(complete, "unknown", true),
      Map.delete(complete, "baselines"),
      drop_in(complete, ["baselines", "mailglass_inbound"]),
      put_in(complete, ["baselines", "unknown"], "1.0.0"),
      Map.delete(complete, "candidate_versions"),
      drop_in(complete, ["candidate_versions", "mailglass_inbound"]),
      put_in(complete, ["candidate_versions", "unknown"], "1.0.0"),
      put_in(complete, ["required_evidence_identifiers", "unknown"], true),
      drop_in(complete, ["required_evidence_identifiers", "hex_package_endpoints"]),
      drop_in(complete, ["required_evidence_identifiers", "hex_package_endpoints", "mailglass"]),
      put_in(
        complete,
        ["required_evidence_identifiers", "hex_package_endpoints", "unknown"],
        "https://hex.pm/api/packages/unknown"
      ),
      drop_in(complete, ["required_evidence_identifiers", "hex_release_endpoints"]),
      drop_in(complete, ["required_evidence_identifiers", "hex_release_endpoints", "mailglass"]),
      put_in(
        complete,
        ["required_evidence_identifiers", "hex_release_endpoints", "unknown"],
        "https://hex.pm/api/packages/unknown/releases/1.0.0"
      ),
      drop_in(complete, ["required_evidence_identifiers", "hex_release_checksums"]),
      drop_in(complete, ["required_evidence_identifiers", "hex_release_checksums", "mailglass"]),
      put_in(
        complete,
        ["required_evidence_identifiers", "hex_release_checksums", "unknown"],
        String.duplicate("a", 64)
      ),
      put_in(
        complete,
        ["required_evidence_identifiers", "hex_release_checksums", "mailglass"],
        "bad"
      ),
      drop_in(complete, ["required_evidence_identifiers", "historical_tag"]),
      put_in(complete, ["required_evidence_identifiers", "historical_tag"], ""),
      drop_in(complete, ["required_evidence_identifiers", "historical_tag_sha"]),
      put_in(complete, ["required_evidence_identifiers", "historical_tag_sha"], "bad"),
      Map.delete(complete, "proposal_identity"),
      drop_in(complete, ["proposal_identity", "source_sha"]),
      Map.delete(complete, "publishable_content"),
      put_in(complete, ["publishable_content", "unknown"], true),
      drop_in(complete, ["publishable_content", "algorithm"]),
      drop_in(complete, ["publishable_content", "digest"]),
      drop_in(complete, ["publishable_content", "excludes"]),
      Map.delete(complete, "final_identity"),
      drop_in(complete, ["final_identity", "tag_sha"]),
      put_in(complete, ["final_identity", "unknown"], true),
      Map.delete(complete, "states"),
      drop_in(complete, ["states", "publication"]),
      put_in(complete, ["states", "unknown"], true),
      put_in(complete, ["states", "publication"], "publishing"),
      Map.put(complete, "status", "publishing")
    ]

    for mutated <- target_mutations do
      assert {:error, _} = apply(reconciler(), :validate_activation, [mutated, reviewed])
    end

    paired_mutations = [
      {
        put_in(complete, ["proposal_identity", "unknown"], true),
        put_in(reviewed, ["proposal_identity", "unknown"], true)
      },
      {complete, Map.put(reviewed, "unknown", true)},
      {complete, put_in(reviewed, ["publishable_content", "unknown"], true)}
    ]

    for {mutated_target, mutated_review} <- paired_mutations do
      assert {:error, _} =
               apply(reconciler(), :validate_activation, [mutated_target, mutated_review])
    end
  end

  test "activation accepts only captured or authorized prepublication lifecycle states" do
    reviewed = reviewed_candidate()
    captured = complete_candidate_target(reviewed)

    authorized =
      captured
      |> Map.put("status", "authorized")
      |> put_in(["states", "authorization"], "authorized")

    assert {:ok, ^captured} = apply(reconciler(), :validate_activation, [captured, reviewed])
    assert {:ok, ^authorized} = apply(reconciler(), :validate_activation, [authorized, reviewed])

    invalid = [
      put_in(captured, ["states", "authorization"], "authorized"),
      authorized |> Map.put("status", "captured"),
      put_in(authorized, ["states", "publication"], "published")
    ]

    for mutated <- invalid do
      assert {:error, _} = apply(reconciler(), :validate_activation, [mutated, reviewed])
    end
  end

  test "activation requires every automation-proposed package to advance its baseline" do
    reviewed = reviewed_candidate()
    complete = complete_candidate_target(reviewed)

    non_advancing_candidates = [
      reviewed["candidate_versions"]
      |> Map.put("mailglass", baseline_versions()["mailglass"])
      |> Map.put("mailglass_admin", baseline_versions()["mailglass_admin"]),
      Map.put(
        reviewed["candidate_versions"],
        "mailglass_inbound",
        baseline_versions()["mailglass_inbound"]
      )
    ]

    for candidate_versions <- non_advancing_candidates do
      changed_review = Map.put(reviewed, "candidate_versions", candidate_versions)
      changed_target = Map.put(complete, "candidate_versions", candidate_versions)

      assert {:error, %{reason: :candidate_not_new}} =
               apply(reconciler(), :validate_activation, [changed_target, changed_review])
    end
  end

  defp reconcile(repository, hex) do
    apply(reconciler(), :reconcile, [%{"repository" => repository, "hex" => hex}])
  end

  defp reconciler, do: Mailglass.ReleaseVersionReconciler

  defp repository_records(core, admin, inbound) do
    [
      %{
        "name" => "mailglass",
        "version" => core,
        "manifest_version" => core,
        "dependencies" => %{}
      },
      %{
        "name" => "mailglass_admin",
        "version" => admin,
        "manifest_version" => admin,
        "dependencies" => %{
          "mailglass" => "~> 2.0",
          "mailglass_inbound" => "~> 2.0"
        }
      },
      %{
        "name" => "mailglass_inbound",
        "version" => inbound,
        "manifest_version" => inbound,
        "dependencies" => %{"mailglass" => "~> 2.0"}
      }
    ]
  end

  defp hex_records(core, admin, inbound) do
    [
      hex_record("mailglass", core),
      hex_record("mailglass_admin", admin),
      hex_record("mailglass_inbound", inbound)
    ]
  end

  defp hex_record(name, version) do
    %{
      "name" => name,
      "package_name" => name,
      "latest_stable_version" => version,
      "release_version" => version,
      "retirement" => nil,
      "checksum" => String.duplicate("a", 64),
      "has_docs" => true,
      "package_endpoint" => "https://hex.pm/api/packages/#{name}",
      "release_endpoint" => "https://hex.pm/api/packages/#{name}/releases/#{version}"
    }
  end

  defp replace_record(records, name, key, value) do
    Enum.map(records, fn record ->
      if record["name"] == name, do: Map.put(record, key, value), else: record
    end)
  end

  # The published baselines, read from Hex: 2.6.0/2.6.0/2.3.0 went live
  # 2026-09-17, superseding 2.5.0/2.5.0/2.2.0 (2026-08-20). Advancing these
  # literals is part of the release close-out, not an afterthought: once the
  # ledger returns to `inactive` this test stops taking its release-candidate
  # branch and compares the tree against these values exactly.
  defp baseline_versions do
    %{"mailglass" => "2.6.0", "mailglass_admin" => "2.6.0", "mailglass_inbound" => "2.3.0"}
  end

  defp release_candidate_tree?(repository_versions) do
    target = read_json!(Path.join(@repo_root, ".planning/release-target.json"))

    System.get_env("GITHUB_HEAD_REF") == "release-please--branches--main" or
      (target["status"] in ["captured", "authorized", "published", "completed"] and
         target["candidate_versions"] == repository_versions)
  end

  defp inbound_summary_expectation(repository_versions) do
    if release_candidate_tree?(repository_versions) do
      core_version = repository_versions["mailglass"]
      inbound_version = repository_versions["mailglass_inbound"]
      {:ok, parsed_core} = Version.parse(core_version)

      %{
        "version" => inbound_version,
        "manifest_version" => inbound_version,
        "source_ref" => "v#{inbound_version}",
        "linked_versions" => repository_versions,
        "mailglass_inbound_publish_pin" =>
          "~> #{parsed_core.major}.#{parsed_core.minor} and >= #{core_version}"
      }
    else
      %{
        "version" => "2.3.0",
        "manifest_version" => "2.3.0",
        "source_ref" => "v2.3.0",
        "linked_versions" => baseline_versions(),
        "mailglass_inbound_publish_pin" => "~> 2.6 and >= 2.6.0"
      }
    end
  end

  defp manifest_versions do
    %{"." => "2.4.1", "mailglass_admin" => "2.4.1", "mailglass_inbound" => "2.1.2"}
  end

  defp evidence_identifiers do
    %{
      "hex_package_endpoints" => Map.new(@packages, &{&1, "https://hex.pm/api/packages/#{&1}"}),
      "hex_release_endpoints" => %{
        "mailglass" => "https://hex.pm/api/packages/mailglass/releases/2.6.0",
        "mailglass_admin" => "https://hex.pm/api/packages/mailglass_admin/releases/2.6.0",
        "mailglass_inbound" => "https://hex.pm/api/packages/mailglass_inbound/releases/2.3.0"
      },
      # Read from the Hex release API, never computed locally.
      "hex_release_checksums" => %{
        "mailglass" => "bf6b7b782c36bfd95fae148ab9413e10312987081839e8135b2ca82066c555c6",
        "mailglass_admin" => "e0f34013e56cf2d8ca41322d59cf9595e58bb65446bb071f75cf393bccb67db5",
        "mailglass_inbound" => "f83a7aede26dc68fd72298aa95bef55fb53ada5ac5f272ede34743f141ad1b4d"
      },
      "historical_tag" => "mailglass-v2.6.0",
      "historical_tag_sha" => "6a0447a900e26b2b07332ac50682767801ddcda7"
    }
  end

  defp reviewed_candidate do
    # These deliberately artificial values exist only to exercise identity
    # matching. They are not release recommendations or inferred versions.
    %{
      "candidate_versions" => %{
        "mailglass" => "99.98.97",
        "mailglass_admin" => "99.98.97",
        "mailglass_inbound" => "88.87.86"
      },
      "proposal_identity" => %{
        "head_sha" => String.duplicate("a", 40),
        "source_sha" => String.duplicate("b", 40)
      },
      "publishable_content" => %{"digest" => String.duplicate("c", 64)}
    }
  end

  defp complete_candidate_target(reviewed) do
    inactive = apply(reconciler(), :inactive_target, [baseline_versions(), evidence_identifiers()])

    inactive
    |> Map.put("status", "captured")
    |> Map.put("candidate_versions", reviewed["candidate_versions"])
    |> Map.put("proposal_identity", reviewed["proposal_identity"])
    |> put_in(["publishable_content", "digest"], reviewed["publishable_content"]["digest"])
    |> put_in(["states", "capture"], "captured")
  end

  defp in_tmp(fun) do
    root = Path.join(System.tmp_dir!(), "mailglass-reconcile-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    try do
      fun.(root)
    after
      File.rm_rf!(root)
    end
  end

  defp write!(root, relative, contents) do
    path = Path.join(root, relative)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end

  defp read_json!(path), do: path |> File.read!() |> Jason.decode!()

  defp drop_in(map, path), do: map |> pop_in(path) |> elem(1)

  defp write_repository_sources!(root, core_source) do
    write!(root, "mix.exs", core_source)

    write!(root, "mailglass_admin/mix.exs", """
    defmodule Fixture.Admin do
      @version "2.4.1"
      defp mailglass_dep, do: {:mailglass, "~> 2.0"}
      defp mailglass_inbound_dep, do: {:mailglass_inbound, "~> 2.0", optional: true}
    end
    """)

    write!(root, "mailglass_inbound/mix.exs", """
    defmodule Fixture.Inbound do
      @version "2.1.2"
      defp mailglass_dep, do: {:mailglass, "~> 2.0"}
    end
    """)

    write!(root, ".release-please-manifest.json", Jason.encode!(manifest_versions()))
  end

  defp fixture_getter(package_payload, release_payload) do
    fn url ->
      cond do
        url == "https://hex.pm/api/packages/mailglass" ->
          {:ok, Jason.encode!(package_payload)}

        url == "https://hex.pm/api/packages/mailglass/releases/2.4.1" ->
          {:ok, Jason.encode!(release_payload)}

        true ->
          {:error, :unexpected_request}
      end
    end
  end
end
