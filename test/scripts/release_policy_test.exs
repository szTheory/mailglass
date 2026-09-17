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

  test "close_out returns a hard-coded non-authorizing inactive successor for a published target" do
    target = published_target()
    tag_sha = target["final_identity"]["tag_sha"]
    checksums = target["final_identity"]["publication_evidence"]["hex_release_checksums"]

    assert {:ok, successor} = policy(:close_out, [target, tag_sha, checksums])

    assert successor["status"] == "inactive"

    assert successor["states"] == %{
             "capture" => "inactive",
             "authorization" => "unauthorized",
             "publication" => "not_started"
           }

    assert successor["candidate_versions"] == nil
    assert successor["proposal_identity"] == %{"head_sha" => nil, "source_sha" => nil}
    assert successor["publishable_content"]["digest"] == nil
    assert successor["final_identity"] == %{"tag_sha" => nil}

    assert successor["baselines"] == target["candidate_versions"]

    assert successor["required_evidence_identifiers"]["hex_release_endpoints"] ==
             Map.new(@packages, fn package ->
               {package,
                "https://hex.pm/api/packages/#{package}/releases/#{target["candidate_versions"][package]}"}
             end)

    assert successor["required_evidence_identifiers"]["hex_release_checksums"] == checksums

    assert successor["required_evidence_identifiers"]["historical_tag"] ==
             "mailglass-v#{target["candidate_versions"]["mailglass"]}"

    assert successor["required_evidence_identifiers"]["historical_tag_sha"] == tag_sha

    assert successor["required_evidence_identifiers"]["hex_package_endpoints"] ==
             target["required_evidence_identifiers"]["hex_package_endpoints"]

    assert successor["package_set"] == target["package_set"]
    assert successor["schema_version"] == target["schema_version"]

    assert {:ok, ^successor} = policy(:validate_target, [successor])
  end

  test "close-out successor is non-authorizing for every accepted input status" do
    for target <- [authorized_target(), published_target(), completed_target()] do
      tag_sha = close_out_tag_sha(target)
      checksums = close_out_checksums(target)

      assert {:ok, successor} = policy(:close_out, [target, tag_sha, checksums])
      assert successor["status"] == "inactive"

      assert policy(:candidate_digest, [successor]) ==
               {:error, %{reason: :inactive_candidate}}

      assert policy(:expected_tags, [successor]) ==
               {:error, %{reason: :inactive_candidate}}
    end
  end

  test "close-out refuses inactive input, malformed evidence, and evidence tampering" do
    published = published_target()
    tag_sha = published["final_identity"]["tag_sha"]
    checksums = published["final_identity"]["publication_evidence"]["hex_release_checksums"]

    {:ok, already_inactive} = policy(:close_out, [published, tag_sha, checksums])

    refutations = [
      {already_inactive, tag_sha, checksums},
      {published, "not-a-sha", checksums},
      {published, tag_sha, Map.delete(checksums, "mailglass")},
      {published, tag_sha, Map.put(checksums, "unknown", String.duplicate("a", 64))},
      {published, tag_sha, Map.put(checksums, "mailglass", "short")},
      {published, String.duplicate("9", 40), checksums},
      {published, tag_sha, Map.put(checksums, "mailglass", String.duplicate("9", 64))}
    ]

    for {target, tag, cksum} <- refutations do
      assert {:error, _} = policy(:close_out, [target, tag, cksum])
    end
  end

  test "close-out advances baselines so the just-released versions are no longer new candidates" do
    published = published_target()
    tag_sha = published["final_identity"]["tag_sha"]
    checksums = published["final_identity"]["publication_evidence"]["hex_release_checksums"]

    assert {:ok, successor} = policy(:close_out, [published, tag_sha, checksums])

    in_tmp(fn root ->
      successor_path = write_json(root, "successor.json", successor)
      released = successor["baselines"]

      write_versions(
        root,
        released["mailglass"],
        released["mailglass_admin"],
        released["mailglass_inbound"]
      )

      write_json(root, ".release-please-manifest.json", %{
        "." => released["mailglass"],
        "mailglass_admin" => released["mailglass_admin"],
        "mailglass_inbound" => released["mailglass_inbound"]
      })

      capture_args = [
        "capture-candidate",
        successor_path,
        root,
        String.duplicate("1", 40),
        String.duplicate("2", 40),
        String.duplicate("3", 64)
      ]

      refute_cli(capture_args)

      higher = bumped_patch_versions(released)

      write_versions(
        root,
        higher["mailglass"],
        higher["mailglass_admin"],
        higher["mailglass_inbound"]
      )

      write_json(root, ".release-please-manifest.json", %{
        "." => higher["mailglass"],
        "mailglass_admin" => higher["mailglass_admin"],
        "mailglass_inbound" => higher["mailglass_inbound"]
      })

      assert_cli(capture_args, "candidate_versions")
    end)
  end

  test "close-out CLI prints a deterministic pretty successor and fails closed on refusal" do
    in_tmp(fn root ->
      published = published_target()
      tag_sha = published["final_identity"]["tag_sha"]
      checksums = published["final_identity"]["publication_evidence"]["hex_release_checksums"]

      target_path = write_json(root, "published.json", published)
      checksums_path = write_json(root, "checksums.json", checksums)

      {output_1, status_1} = run_cli(["close-out", target_path, tag_sha, checksums_path])
      {output_2, status_2} = run_cli(["close-out", target_path, tag_sha, checksums_path])

      assert status_1 == 0
      assert status_2 == 0
      assert output_1 == output_2
      assert String.ends_with?(output_1, "\n")
      assert {:ok, decoded} = Jason.decode(output_1)
      assert decoded["status"] == "inactive"

      bad_checksums_path =
        write_json(root, "bad-checksums.json", Map.delete(checksums, "mailglass"))

      {bad_output, bad_status} =
        run_cli(["close-out", target_path, tag_sha, bad_checksums_path])

      assert bad_status != 0
      refute bad_output =~ "\"status\""
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

  defp authorized_target do
    captured_target()
    |> Map.put("status", "authorized")
    |> put_in(["states", "authorization"], "authorized")
  end

  defp close_out_tag_sha(%{"status" => "authorized"}), do: String.duplicate("9", 40)
  defp close_out_tag_sha(target), do: target["final_identity"]["tag_sha"]

  defp close_out_checksums(%{"status" => "authorized"}),
    do: Map.new(@packages, &{&1, String.duplicate("1", 64)})

  defp close_out_checksums(target),
    do: target["final_identity"]["publication_evidence"]["hex_release_checksums"]

  defp bumped_patch_versions(versions) do
    Map.new(versions, fn {package, version} ->
      {:ok, parsed} = Version.parse(version)
      {package, "#{parsed.major}.#{parsed.minor}.#{parsed.patch + 1}"}
    end)
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
      stderr_to_stdout: true,
      # `--no-compile --no-deps-check` makes this subprocess use whatever is
      # already built for the env it resolves to. Mix sets an alias's
      # preferred_env internally rather than exporting MIX_ENV, so without this
      # the child defaults to :dev and silently depends on _build/dev being
      # populated by some unrelated earlier command — a green-or-red coin flip.
      env: [{"MIX_ENV", to_string(Mix.env())}]
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
