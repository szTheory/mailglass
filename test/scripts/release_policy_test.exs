defmodule Mailglass.Scripts.ReleasePolicyTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../scripts/release_policy.exs", __DIR__)
  @packages ~w(mailglass mailglass_admin mailglass_inbound)

  setup_all do
    Code.require_file(@script)
    :ok
  end

  test "accepts a complete captured three-package candidate while inbound remains independent" do
    target = captured_target()

    assert {:ok, ^target} = policy(:validate_target, [target])

    assert policy(:expected_tags, [target]) ==
             {:ok, ["mailglass-v3.0.0", "mailglass_admin-v3.0.0", "mailglass_inbound-v2.2.0"]}
  end

  test "rejects empty, missing, duplicate, unknown, conflicting, and untrusted candidate inputs" do
    target = captured_target()

    mutations = [
      Map.put(target, "package_set", []),
      Map.put(target, "package_set", ["mailglass", "mailglass", "mailglass_inbound"]),
      Map.put(target, "package_set", ["mailglass", "mailglass_admin", "unknown"]),
      Map.delete(target, "candidate_versions"),
      put_in(target, ["candidate_versions", "unknown"], "1.0.0"),
      put_in(target, ["candidate_versions", "mailglass_inbound"], "2.1.2"),
      put_in(target, ["proposal_identity", "head_sha"], "$(touch pwned)"),
      put_in(target, ["publishable_content", "digest"], "bad\nGITHUB_OUTPUT=owned"),
      put_in(target, ["proposal_identity", "unknown"], true),
      put_in(target, ["publishable_content", "unknown"], true),
      put_in(target, ["final_identity", "unknown"], true),
      put_in(target, ["states", "unknown"], true),
      Map.put(target, "unexpected", true)
    ]

    for mutation <- mutations do
      assert {:error, _} = policy(:validate_target, [mutation])
    end
  end

  test "binds the reviewed Release Please proposal and publishable digest while final tag SHA stays separate" do
    target = captured_target()
    review = review_from(target)

    assert {:ok, ^target} = policy(:validate_candidate, [target, review])

    assert {:error, _} =
             policy(:validate_candidate, [
               target,
               put_in(review, ["proposal_identity", "source_sha"], String.duplicate("f", 40))
             ])

    assert {:error, _} =
             policy(:validate_candidate, [
               put_in(target, ["final_identity", "tag_sha"], String.duplicate("d", 40)),
               review
             ])
  end

  test "derives one deterministic authorization digest from candidate, identity, content, and evidence" do
    target = captured_target()
    assert {:ok, digest} = policy(:candidate_digest, [target])
    assert byte_size(digest) == 64

    reordered_target =
      target
      |> Map.to_list()
      |> Enum.reverse()
      |> Map.new()
      |> update_in(["required_evidence_identifiers"], fn evidence ->
        evidence |> Map.to_list() |> Enum.reverse() |> Map.new()
      end)

    assert {:ok, ^digest} = policy(:candidate_digest, [reordered_target])

    authorized =
      target
      |> Map.put("status", "authorized")
      |> put_in(["states", "authorization"], "authorized")

    assert {:ok, ^authorized} = policy(:validate_authorization_digest, [authorized, digest])

    assert {:error, %{reason: :authorization_digest_mismatch}} =
             policy(:validate_authorization_digest, [authorized, String.duplicate("0", 64)])

    changed_evidence =
      put_in(
        authorized,
        ["required_evidence_identifiers", "historical_tag_sha"],
        String.duplicate("d", 40)
      )

    assert {:error, %{reason: :authorization_digest_mismatch}} =
             policy(:validate_authorization_digest, [changed_evidence, digest])
  end

  test "authorizes only exact candidate tag refs and source versions" do
    target = captured_target()
    versions = target["candidate_versions"]

    for ref <- ["mailglass-v3.0.0", "mailglass_admin-v3.0.0", "mailglass_inbound-v2.2.0"] do
      assert {:ok, ^versions} = policy(:validate_release_ref, [target, ref, versions])
    end

    for ref <- ["mailglass-v3.0.0;echo owned", "refs/tags/mailglass-v3.0.0", "mailglass-v3.0.1"] do
      assert {:error, _} = policy(:validate_release_ref, [target, ref, versions])
    end
  end

  test "manifest versions must exactly equal all three source package versions" do
    versions = captured_target()["candidate_versions"]

    manifest = %{
      "." => versions["mailglass"],
      "mailglass_admin" => versions["mailglass_admin"],
      "mailglass_inbound" => versions["mailglass_inbound"]
    }

    assert :ok = policy(:validate_manifest_source, [manifest, versions])

    for mutation <- [
          Map.put(manifest, ".", "99.0.0"),
          Map.put(manifest, "mailglass_admin", "99.0.0"),
          Map.put(manifest, "mailglass_inbound", "99.0.0"),
          Map.put(manifest, "unknown", "1.0.0"),
          Map.delete(manifest, "mailglass_inbound")
        ] do
      assert {:error, _} = policy(:validate_manifest_source, [mutation, versions])
    end
  end

  test "completed target carries a separately verified final tag SHA" do
    completed = completed_target()

    assert {:ok, ^completed} = policy(:validate_completed_target, [completed])

    assert {:error, _} =
             policy(:validate_completed_target, [
               put_in(completed, ["final_identity", "tag_sha"], nil)
             ])
  end

  test "published lifecycle requires exact immutable workflow release tag and Hex evidence" do
    published = published_target()

    assert {:ok, ^published} = policy(:validate_published_target, [published])
    assert {:error, _} = policy(:validate_completed_target, [published])

    publication_path = ["final_identity", "publication_evidence"]

    mutations = [
      Map.put(published, "status", "completed"),
      put_in(published, ["final_identity", "adoption_evidence"], %{}),
      update_in(published, publication_path, &Map.delete(&1, "workflow_run_url")),
      put_in(published, publication_path ++ ["workflow_run_url"], "https://example.com/run/1"),
      put_in(published, publication_path ++ ["candidate_digest"], String.duplicate("0", 64)),
      put_in(published, publication_path ++ ["release_ids", "mailglass"], 0),
      put_in(published, publication_path ++ ["release_ids", "mailglass_admin"], "123"),
      put_in(published, publication_path ++ ["release_ids", "mailglass_admin"], 1000),
      put_in(published, publication_path ++ ["tag_shas", "mailglass"], String.duplicate("e", 40)),
      put_in(published, publication_path ++ ["hex_release_checksums", "mailglass"], "short"),
      put_in(published, publication_path ++ ["unknown"], true)
    ]

    for mutation <- mutations do
      assert {:error, _} = policy(:validate_published_target, [mutation])
    end
  end

  test "completion additionally requires both immutable adoption checkpoint digests" do
    completed = completed_target()

    assert {:ok, ^completed} = policy(:validate_completed_target, [completed])

    adoption_path = ["final_identity", "adoption_evidence"]

    mutations = [
      put_in(completed, adoption_path, nil),
      update_in(completed, adoption_path, &Map.delete(&1, "workflow_run_url")),
      put_in(completed, adoption_path ++ ["workflow_run_url"], "http://github.com/run/123"),
      put_in(completed, adoption_path ++ ["target_ref"], String.duplicate("a", 40)),
      update_in(
        completed,
        adoption_path ++ ["checkpoint_digests"],
        &Map.delete(&1, "generated_host")
      ),
      put_in(completed, adoption_path ++ ["checkpoint_digests", "trust_runner"], "bad"),
      put_in(
        completed,
        adoption_path ++ ["checkpoint_digests", "unknown"],
        String.duplicate("f", 64)
      ),
      put_in(completed, adoption_path ++ ["unknown"], true),
      Map.put(completed, "final_identity", %{"tag_sha" => String.duplicate("d", 40)})
    ]

    for mutation <- mutations do
      assert {:error, _} = policy(:validate_completed_target, [mutation])
    end
  end

  test "real CLI validates reviewed candidate published and complete artifacts" do
    in_tmp(fn root ->
      candidate = captured_target()
      review = review_from(candidate)
      published = published_target()
      completed = completed_target()

      candidate_path = write_json(root, "candidate.json", candidate)
      review_path = write_json(root, "review.json", review)
      published_path = write_json(root, "published.json", published)
      completed_path = write_json(root, "completed.json", completed)

      assert_cli(["validate-candidate", candidate_path, review_path], "candidate_valid=true")
      assert_cli(["verify-published", published_path], "published=true")
      assert_cli(["verify-complete", completed_path], "completed=true")
      assert_cli(["authorized-versions", published_path], "authorized=true")

      forged_review_path =
        write_json(
          root,
          "forged-review.json",
          put_in(review, ["publishable_content", "digest"], String.duplicate("0", 64))
        )

      refute_cli(["validate-candidate", candidate_path, forged_review_path])
      refute_cli(["validate-candidate", completed_path, review_path])
      refute_cli(["verify-published", completed_path])
      refute_cli(["verify-complete", published_path])
      refute_cli(["authorized-versions", completed_path])
    end)
  end

  test "keeps core and admin linked across baselines, candidates, and every candidate lifecycle" do
    captured = captured_target()

    divergent_baseline = put_in(captured, ["baselines", "mailglass_admin"], "2.4.2")
    divergent_candidate = put_in(captured, ["candidate_versions", "mailglass_admin"], "3.0.1")

    for target <- [divergent_baseline, divergent_candidate] do
      assert {:error, _} = policy(:validate_target, [target])
    end

    authorized =
      divergent_candidate
      |> Map.put("status", "authorized")
      |> put_in(["states", "authorization"], "authorized")

    completed =
      completed_target()
      |> put_in(["candidate_versions", "mailglass_admin"], "3.0.1")

    assert {:error, _} = policy(:validate_target, [authorized])
    assert {:error, _} = policy(:validate_completed_target, [completed])
  end

  test "rejects prerelease, build, and Version-invalid release versions" do
    for version <- [
          "4.0.0-rc.1",
          "4.0.0-01",
          "4.0.0+build.1",
          "04.0.0",
          "4.0",
          "4.0.0 trailing"
        ] do
      assert {:error, _} =
               captured_target()
               |> put_in(["candidate_versions", "mailglass"], version)
               |> put_in(["candidate_versions", "mailglass_admin"], version)
               |> then(&policy(:validate_target, [&1]))
    end
  end

  test "reads exactly one full-line stable version declaration per package" do
    in_tmp(fn root ->
      write_versions(root, "2.5.0", "2.5.0", "2.2.0")
      assert {:ok, _} = policy(:source_versions, [root])

      File.write!(
        Path.join(root, "mailglass_admin/mix.exs"),
        "  @version \"2.5.0\"\n  @version \"2.5.1\"\n"
      )

      assert {:error, _} = policy(:source_versions, [root])

      File.write!(Path.join(root, "mailglass_admin/mix.exs"), "  @version \"2.5.0\" # comment\n")
      assert {:error, _} = policy(:source_versions, [root])

      write_versions(root, "2.5.0", "2.5.1", "2.2.0")
      assert {:error, _} = policy(:source_versions, [root])
    end)
  end

  test "legacy direct script-style verification flags fail closed" do
    for flag <- ["--validate-candidate", "--verify-published", "--verify-complete"] do
      {output, status} = System.cmd("elixir", [@script, flag], stderr_to_stdout: true)

      assert status == 64
      assert output =~ "unsupported direct release-policy invocation"
    end
  end

  defp captured_target do
    %{
      "schema_version" => 1,
      "status" => "captured",
      "package_set" => @packages,
      "baselines" => %{
        "mailglass" => "2.4.1",
        "mailglass_admin" => "2.4.1",
        "mailglass_inbound" => "2.1.2"
      },
      "candidate_versions" => %{
        "mailglass" => "3.0.0",
        "mailglass_admin" => "3.0.0",
        "mailglass_inbound" => "2.2.0"
      },
      "required_evidence_identifiers" => evidence(),
      "proposal_identity" => %{
        "head_sha" => String.duplicate("a", 40),
        "source_sha" => String.duplicate("b", 40)
      },
      "publishable_content" => %{
        "algorithm" => "sha256",
        "digest" => String.duplicate("c", 64),
        "excludes" => [".planning/release-target.json"]
      },
      "final_identity" => %{"tag_sha" => nil},
      "states" => %{
        "capture" => "captured",
        "authorization" => "unauthorized",
        "publication" => "not_started"
      }
    }
  end

  defp review_from(target) do
    Map.take(target, ["candidate_versions", "proposal_identity", "publishable_content"])
  end

  defp published_target do
    tag_sha = String.duplicate("d", 40)
    target = captured_target()
    {:ok, candidate_digest} = policy(:candidate_digest, [target])

    target
    |> Map.put("status", "published")
    |> put_in(["states", "authorization"], "authorized")
    |> put_in(["states", "publication"], "published")
    |> Map.put("final_identity", %{
      "tag_sha" => tag_sha,
      "publication_evidence" => %{
        "candidate_digest" => candidate_digest,
        "workflow_run_url" => "https://github.com/szTheory/mailglass/actions/runs/123456789",
        "release_ids" =>
          Map.new(@packages, &{&1, 1000 + Enum.find_index(@packages, fn p -> p == &1 end)}),
        "tag_shas" => Map.new(@packages, &{&1, tag_sha}),
        "hex_release_checksums" => Map.new(@packages, &{&1, String.duplicate("e", 64)})
      },
      "adoption_evidence" => nil
    })
  end

  defp completed_target do
    published_target()
    |> Map.put("status", "completed")
    |> put_in(["final_identity", "adoption_evidence"], %{
      "workflow_run_url" => "https://github.com/szTheory/mailglass/actions/runs/123456790",
      "target_ref" => String.duplicate("d", 40),
      "checkpoint_digests" => %{
        "generated_host" => String.duplicate("f", 64),
        "trust_runner" => String.duplicate("0", 64)
      }
    })
  end

  defp policy(function, args), do: apply(Mailglass.ReleasePolicy, function, args)

  defp evidence do
    baselines = %{
      "mailglass" => "2.4.1",
      "mailglass_admin" => "2.4.1",
      "mailglass_inbound" => "2.1.2"
    }

    %{
      "hex_package_endpoints" => Map.new(@packages, &{&1, "https://hex.pm/api/packages/#{&1}"}),
      "hex_release_endpoints" =>
        Map.new(@packages, fn package ->
          {package, "https://hex.pm/api/packages/#{package}/releases/#{baselines[package]}"}
        end),
      "hex_release_checksums" => Map.new(@packages, &{&1, String.duplicate("a", 64)}),
      "historical_tag" => "mailglass-v2.4.1",
      "historical_tag_sha" => String.duplicate("e", 40)
    }
  end

  defp write_versions(root, core, admin, inbound) do
    for {path, version} <- [
          {"mix.exs", core},
          {"mailglass_admin/mix.exs", admin},
          {"mailglass_inbound/mix.exs", inbound}
        ] do
      full_path = Path.join(root, path)
      File.mkdir_p!(Path.dirname(full_path))
      File.write!(full_path, "  @version \"#{version}\"\n")
    end
  end

  defp write_json(root, name, value) do
    path = Path.join(root, name)
    File.write!(path, Jason.encode!(value))
    path
  end

  defp assert_cli(arguments, expected_output) do
    {output, status} = run_cli(arguments)
    assert status == 0, output
    assert output =~ expected_output
  end

  defp refute_cli(arguments) do
    {_output, status} = run_cli(arguments)
    assert status != 0
  end

  defp run_cli(arguments) do
    System.cmd(
      "mix",
      [
        "run",
        "--no-start",
        "--no-compile",
        "--no-deps-check",
        "--require",
        @script,
        "-e",
        "Mailglass.ReleasePolicy.cli(System.argv())",
        "--"
        | arguments
      ],
      cd: Path.expand("../..", __DIR__),
      stderr_to_stdout: true
    )
  end

  defp in_tmp(fun) do
    root = Path.join(System.tmp_dir!(), "release-policy-unit-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    try do
      fun.(root)
    after
      File.rm_rf!(root)
    end
  end
end
