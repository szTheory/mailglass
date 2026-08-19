defmodule Mailglass.Scripts.ReconcileReleaseVersionsTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/reconcile_release_versions.exs")
  @packages ~w(mailglass mailglass_admin mailglass_inbound)

  setup_all do
    Code.require_file(@script)
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
    refute inspect(report) =~ "2.5.0"
    refute inspect(report) =~ "2.2.0"
  end

  test "accepts exact equality while preserving linked core/admin and independent inbound" do
    assert {:ok, report} =
             reconcile(
               repository_records("2.4.1", "2.4.1", "2.1.2"),
               hex_records("2.4.1", "2.4.1", "2.1.2")
             )

    assert report.status == "reconciled"
    assert report.package_set == @packages
    assert report.baselines == baseline_versions()

    assert report.constraints == %{
             "mailglass_admin->mailglass" => "~> 2.0",
             "mailglass_inbound->mailglass" => "~> 2.0"
           }
  end

  test "fails closed on missing, duplicate, unknown, malformed, retired, and conflicting evidence" do
    repository = repository_records("2.4.1", "2.4.1", "2.1.2")
    hex = hex_records("2.4.1", "2.4.1", "2.1.2")

    cases = [
      {:missing_repository, tl(repository)},
      {:duplicate_repository, repository ++ [hd(repository)]},
      {:unknown_repository, repository ++ [%{"name" => "mailglass_extra", "version" => "1.0.0"}]},
      {:malformed_repository, replace_record(repository, "mailglass", "version", "latest")}
    ]

    for {expected, changed} <- cases do
      assert {:error, %{reason: ^expected}} = reconcile(changed, hex)
    end

    hex_cases = [
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
        "dependencies" => %{"mailglass" => "~> 2.0"}
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

  defp baseline_versions do
    %{"mailglass" => "2.4.1", "mailglass_admin" => "2.4.1", "mailglass_inbound" => "2.1.2"}
  end

  defp manifest_versions do
    %{"." => "2.4.1", "mailglass_admin" => "2.4.1", "mailglass_inbound" => "2.1.2"}
  end

  defp evidence_identifiers do
    %{
      "hex_package_endpoints" => Map.new(@packages, &{&1, "https://hex.pm/api/packages/#{&1}"}),
      "hex_release_endpoints" => %{
        "mailglass" => "https://hex.pm/api/packages/mailglass/releases/2.4.1",
        "mailglass_admin" => "https://hex.pm/api/packages/mailglass_admin/releases/2.4.1",
        "mailglass_inbound" => "https://hex.pm/api/packages/mailglass_inbound/releases/2.1.2"
      },
      "historical_tag" => "mailglass-v2.4.1",
      "historical_tag_sha" => "587c9d1a09944de02220b3fa121ce937677a8c3a"
    }
  end

  defp reviewed_candidate do
    %{
      "candidate_versions" => %{
        "mailglass" => "3.0.0",
        "mailglass_admin" => "3.0.0",
        "mailglass_inbound" => "2.2.0"
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
end
