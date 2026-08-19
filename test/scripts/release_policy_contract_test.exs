defmodule Mailglass.Scripts.ReleasePolicyContractTest do
  # Wrapper tests invoke Mix in subprocesses, which contend for the shared build
  # directory when this module runs concurrently with the rest of the suite.
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @expected_tags Path.join(@repo_root, "scripts/release_policy_expected_tags.sh")
  @validate_target Path.join(@repo_root, "scripts/release_policy_validate_target.sh")
  @release_please Path.join(@repo_root, ".github/workflows/release-please.yml")
  @publish Path.join(@repo_root, ".github/workflows/publish-hex.yml")

  test "captured target deterministically selects the exact three-package candidate tags" do
    in_tmp(fn dir ->
      manifest = write_json(dir, "manifest.json", %{"." => "9.9.9", "mailglass_inbound" => "8.8.8"})

      target =
        write_json(dir, "target.json", %{
          "schema_version" => 1,
          "status" => "captured",
          "package_set" => ["mailglass", "mailglass_admin", "mailglass_inbound"],
          "baselines" => %{
            "mailglass" => "2.4.0",
            "mailglass_admin" => "2.4.0",
            "mailglass_inbound" => "2.1.1"
          },
          "candidate_versions" => %{
            "mailglass" => "2.5.0",
            "mailglass_admin" => "2.5.0",
            "mailglass_inbound" => "2.2.0"
          },
          "required_evidence_identifiers" => evidence("2.4.0", "2.4.0", "2.1.1"),
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
        })

      assert {"mailglass-v2.5.0\nmailglass_admin-v2.5.0\nmailglass_inbound-v2.2.0\n", 0} =
               run(@expected_tags, [manifest, target])
    end)
  end

  test "manifest fallback is deterministic and invalid release inputs fail closed" do
    in_tmp(fn dir ->
      manifest =
        write_json(dir, "manifest.json", %{
          "." => "1.2.3",
          "mailglass_admin" => "1.2.3",
          "mailglass_inbound" => "4.5.6"
        })

      assert {"mailglass-v1.2.3\nmailglass_admin-v1.2.3\nmailglass_inbound-v4.5.6\n", 0} =
               run(@expected_tags, [manifest])

      for target <- [
            %{
              "schema_version" => 1,
              "status" => "captured",
              "package_set" => [],
              "baselines" => %{}
            },
            %{
              "schema_version" => 1,
              "status" => "captured",
              "package_set" => ["unknown"],
              "baselines" => %{}
            }
          ] do
        path = write_json(dir, "bad-target.json", target)
        assert {_output, status} = run(@expected_tags, [manifest, path])
        assert status != 0
      end

      empty = write_json(dir, "empty.json", %{})
      assert {_output, status} = run(@expected_tags, [empty])
      assert status != 0
    end)
  end

  test "manifest rejects divergent linked core and admin versions" do
    in_tmp(fn dir ->
      manifest =
        write_json(dir, "manifest.json", %{
          "." => "1.2.3",
          "mailglass_admin" => "1.2.4",
          "mailglass_inbound" => "4.5.6"
        })

      assert {_output, status} = run(@expected_tags, [manifest])
      assert status != 0
    end)
  end

  test "target validation accepts only source-matching exact candidate tags" do
    in_tmp(fn dir ->
      File.mkdir_p!(Path.join(dir, "mailglass_admin"))
      File.mkdir_p!(Path.join(dir, "mailglass_inbound"))
      File.write!(Path.join(dir, "mix.exs"), "  @version \"2.4.0\"\n")
      File.write!(Path.join(dir, "mailglass_admin/mix.exs"), "  @version \"2.4.0\"\n")
      File.write!(Path.join(dir, "mailglass_inbound/mix.exs"), "  @version \"2.1.1\"\n")

      target =
        write_json(dir, "target.json", %{
          "schema_version" => 1,
          "status" => "captured",
          "package_set" => ["mailglass", "mailglass_admin", "mailglass_inbound"],
          "baselines" => %{
            "mailglass" => "2.4.0",
            "mailglass_admin" => "2.4.0",
            "mailglass_inbound" => "2.1.1"
          },
          "candidate_versions" => %{
            "mailglass" => "2.5.0",
            "mailglass_admin" => "2.5.0",
            "mailglass_inbound" => "2.2.0"
          },
          "required_evidence_identifiers" => evidence("2.4.0", "2.4.0", "2.1.1"),
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
        })

      File.write!(Path.join(dir, "mix.exs"), "  @version \"2.5.0\"\n")
      File.write!(Path.join(dir, "mailglass_admin/mix.exs"), "  @version \"2.5.0\"\n")
      File.write!(Path.join(dir, "mailglass_inbound/mix.exs"), "  @version \"2.2.0\"\n")

      for tag <- ["mailglass-v2.5.0", "mailglass_admin-v2.5.0", "mailglass_inbound-v2.2.0"] do
        assert {output, 0} = run(@validate_target, [target, tag, dir])
        assert output =~ "active=true\ncore=2.5.0\nadmin=2.5.0\ninbound=2.2.0\n"
      end

      assert {output, status} = run(@validate_target, [target, "mailglass_inbound-v2.2.1", dir])
      assert status != 0
      refute output =~ "active=true"
      refute output =~ "core=2.5.0"

      File.write!(Path.join(dir, "mailglass_inbound/mix.exs"), "  @version \"2.1.0\"\n")
      assert {output, status} = run(@validate_target, [target, "mailglass-v2.5.0", dir])
      assert status != 0
      refute output =~ "active=true"
      refute output =~ "core=2.5.0"
    end)
  end

  test "legacy recovery tag without the versioned validator uses the fail-closed inline contract" do
    step = extract_step_script!(File.read!(@publish), "Validate automated release target")

    in_tmp(fn dir ->
      File.mkdir_p!(Path.join(dir, ".planning"))
      File.mkdir_p!(Path.join(dir, "mailglass_admin"))
      File.mkdir_p!(Path.join(dir, "mailglass_inbound"))
      File.write!(Path.join(dir, "mix.exs"), "  @version \"2.4.0\"\n")
      File.write!(Path.join(dir, "mailglass_admin/mix.exs"), "  @version \"2.4.0\"\n")
      File.write!(Path.join(dir, "mailglass_inbound/mix.exs"), "  @version \"2.1.1\"\n")

      write_json(dir, ".planning/release-target.json", %{
        "status" => "active",
        "packages" => %{
          "mailglass" => "2.4.0",
          "mailglass_admin" => "2.4.0",
          "mailglass_inbound" => "2.1.1"
        }
      })

      refute File.exists?(Path.join(dir, "scripts/release_policy_validate_target.sh"))
      output = Path.join(dir, "github-output")

      assert {message, 0} =
               System.cmd("bash", ["-c", step],
                 cd: dir,
                 env: [{"RELEASE_REF", "mailglass-v2.4.0"}, {"GITHUB_OUTPUT", output}],
                 stderr_to_stdout: true
               )

      assert message == ""
      assert File.read!(output) =~ "authorized=false"

      assert {message, 0} =
               System.cmd("bash", ["-c", step],
                 cd: dir,
                 env: [
                   {"RELEASE_REF", "mailglass_inbound-v2.1.1"},
                   {"GITHUB_OUTPUT", Path.join(dir, "rejected-output")}
                 ],
                 stderr_to_stdout: true
               )

      assert message == ""
    end)
  end

  test "workflows delegate only pure decisions and preserve release effects inline" do
    release = File.read!(@release_please)
    publish = File.read!(@publish)

    assert release =~ "scripts/release_policy_expected_tags.sh"
    assert publish =~ "scripts/release_policy_validate_target.sh"
    refute release =~ "to_entries[]"

    assert publish =~ "release:\n    types: [published]"
    assert publish =~ "environment: hex-publish"
    assert publish =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert publish =~ "mix hex.publish"
    assert release =~ "googleapis/release-please-action@"
    assert release =~ "RELEASE_PLEASE_PAT"

    for script <- [@expected_tags, @validate_target] do
      source = File.read!(script)
      refute source =~ ~r/\bgh\s/
      refute source =~ "secrets."
      refute source =~ "mix hex.publish"
      assert source =~ "Mailglass.ReleasePolicy.cli"
    end

    broken =
      String.replace(release, "scripts/release_policy_expected_tags.sh", "true", global: true)

    refute broken =~ "scripts/release_policy_expected_tags.sh"
  end

  test "release preparation is proposal-only and disarms ordinary auto-merge" do
    release = File.read!(@release_please)

    assert release =~ "skip-github-release: ${{ github.event.inputs.candidate_digest == '' }}"
    assert release =~ "steps.release.outputs.prs"
    assert release =~ "proposal/source identity"
    assert release =~ "publishable-content digest"
    assert release =~ "Disarmed ordinary auto-merge"
    refute release =~ "gh pr merge \"$number\" --auto --squash"

    assert step_precedes?(
             release,
             "Set up OTP + Elixir for policy",
             "Detect already-tagged release PR"
           )

    assert step_precedes?(release, "Install deps for policy", "Detect already-tagged release PR")
  end

  test "proposal mode bypasses historical tag recovery while protected dispatch requires exact authorization" do
    release = File.read!(@release_please)

    assert release =~ "candidate_digest:"
    assert release =~ "Proposal mode bypasses historical baseline tag recovery"
    assert release =~ "Validate protected exact candidate dispatch"
    assert release =~ "validate-protected-dispatch"
    assert release =~ "candidate_digest=$(awk -F= '$1 == \"candidate_digest\" {print $2}' \"$policy\")"
    assert release =~ "content_digest=$(awk -F= '$1 == \"content_digest\" {print $2}' \"$policy\")"
    assert release =~ "[ \"$candidate_digest\" = \"$CANDIDATE_DIGEST\" ]"
    assert release =~ "git checkout --detach \"$proposal_head\""
    assert release =~ "[ \"$actual_digest\" = \"$content_digest\" ]"
    assert release =~ "[ \"$(jq -er 'length' <<<\"$prs\")\" -eq 1 ]"
    assert release =~ "[ \"$merged_digest\" = \"$CONTENT_DIGEST\" ]"
    assert release =~ "echo \"merge_tree_verified=true\" >> \"$GITHUB_OUTPUT\""
    assert release =~ "--match-head-commit \"$PROPOSAL_HEAD\""
    assert release =~ "validate-protected-dispatch .planning/release-target.json \"$CANDIDATE_DIGEST\" >/dev/null"
    assert release =~ "Compile policy runtime"
    refute release =~ "cat \"$policy\" >> \"$GITHUB_OUTPUT\""
    assert release =~ "Protected exact candidate dispatch may merge only the validated release PR"
    assert release =~ "steps.protected-dispatch.outputs.authorized == 'true'"
    assert release =~ "steps.protected-merge.outcome == 'success'"
    assert release =~ "steps.protected-merge.outputs.merge_tree_verified == 'true'"
    refute release =~ "gh pr merge \"$number\" --auto --squash"
    refute release =~ "gh pr merge \"$NUMBER\" --auto"
  end

  test "proposal capture runs after synchronization and is the sole release-target policy path" do
    release = File.read!(@release_please)

    assert step_precedes?(
             release,
             "Sync sibling package -> mailglass dep pin on release-please branch",
             "Capture Release Please proposal identity without activation"
           )

    assert release =~ "gh pr list --head release-please--branches--main"
    assert release =~ "proposal-candidate.json"
    refute release =~ "release_packages=$(jq"
    refute release =~ "Phase 148 must publish exactly"
  end

  test "publish workflow requires a protected exact-digest dispatch and keeps live jobs inert" do
    publish = File.read!(@publish)

    assert publish =~ "candidate_digest:"
    assert publish =~ "Protected candidate digest"
    assert publish =~ "needs.prepublish-summary.outputs.authorized == 'true'"
    assert publish =~ "github.event.inputs.candidate_digest"
    refute publish =~ "false &&"
    assert publish =~ "mailglass_inbound"
  end

  test "dry-run remains credential-free and outside every protected publish environment" do
    publish = File.read!(@publish)

    for job <- ["publish-core", "publish-admin", "publish-inbound"] do
      block = extract_job!(publish, job)
      assert block =~ "github.event.inputs.dry_run != 'true'"
      assert block =~ "environment: hex-publish"
      assert block =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    end

    prepublish = extract_job!(publish, "prepublish-summary")
    refute prepublish =~ "environment: hex-publish"
    refute prepublish =~ "HEX_API_KEY"
    assert prepublish =~ "Compile policy runtime"
    assert prepublish =~ "Pre-publish check for mailglass"
    assert prepublish =~ "Pre-publish check for mailglass_admin"
    assert prepublish =~ "Pre-publish check for mailglass_inbound"
    assert prepublish =~ "validate-captured-dispatch"
    assert prepublish =~ "pretag=true"
    assert prepublish =~ "[ \"$(git rev-parse HEAD)\" = \"$proposal_head\" ]"
    assert prepublish =~ "[ \"$actual_digest\" = \"$content_digest\" ]"
  end

  defp run(script, args), do: System.cmd("bash", [script | args], stderr_to_stdout: true)

  defp extract_step_script!(source, name) do
    marker = "      - name: #{name}\n"
    [_before, rest] = String.split(source, marker, parts: 2)
    [block | _] = String.split(rest, ~r/\n      - name:/, parts: 2)
    [_before_run, script] = String.split(block, "        run: |\n", parts: 2)

    script
    |> String.split("\n")
    |> Enum.map_join("\n", &String.replace_prefix(&1, "          ", ""))
  end

  defp write_json(dir, name, value) do
    path = Path.join(dir, name)
    File.write!(path, Jason.encode!(value))
    path
  end

  defp evidence(core, admin, inbound) do
    packages = %{"mailglass" => core, "mailglass_admin" => admin, "mailglass_inbound" => inbound}

    %{
      "hex_package_endpoints" =>
        Map.new(packages, fn {package, _} -> {package, "https://hex.pm/api/packages/#{package}"} end),
      "hex_release_endpoints" =>
        Map.new(packages, fn {package, version} ->
          {package, "https://hex.pm/api/packages/#{package}/releases/#{version}"}
        end),
      "hex_release_checksums" =>
        Map.new(packages, fn {package, _} -> {package, String.duplicate("d", 64)} end),
      "historical_tag" => "mailglass-v#{core}",
      "historical_tag_sha" => String.duplicate("e", 40)
    }
  end

  defp in_tmp(fun) do
    dir = Path.join(System.tmp_dir!(), "release-policy-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    try do
      fun.(dir)
    after
      File.rm_rf!(dir)
    end
  end

  defp step_precedes?(source, first, second) do
    {first_index, _} = :binary.match(source, "- name: #{first}")
    {second_index, _} = :binary.match(source, "- name: #{second}")
    first_index < second_index
  end

  defp extract_job!(source, job_name) do
    marker = "  #{job_name}:\n"
    [_before, rest] = String.split(source, marker, parts: 2)
    [block | _] = String.split(rest, ~r/^  [a-z][a-z0-9-]*:$/m, parts: 2)
    block
  end
end
