defmodule Mailglass.Scripts.ReleasePolicyCloseOutTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/release_policy_close_out.sh")
  @policy Path.join(@repo_root, "scripts/release_policy.exs")
  @packages ~w(mailglass mailglass_admin mailglass_inbound)
  @baselines %{"mailglass" => "2.5.0", "mailglass_admin" => "2.5.0", "mailglass_inbound" => "2.1.0"}
  @candidates %{
    "mailglass" => "3.0.0",
    "mailglass_admin" => "3.0.0",
    "mailglass_inbound" => "2.2.0"
  }
  @checksum String.duplicate("e", 64)

  setup_all do
    Code.require_file(@policy)
    :ok
  end

  setup do
    root =
      Path.join(System.tmp_dir!(), "release-close-out-#{System.unique_integer([:positive])}")

    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)

    File.write!(Path.join(bin, "curl"), """
    #!/usr/bin/env bash
    set -euo pipefail
    output=''
    url=''
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        --output) output=$2; shift 2 ;;
        http*) url=$1; shift ;;
        *) shift ;;
      esac
    done
    [[ -n "$output" && -n "$url" ]] || exit 64
    printf '%s\\n' "$url" >> "$FAKE_CURL_LOG"

    package=${url#https://hex.pm/api/packages/}
    package=${package%%/*}
    version=${url##*/}
    checksum=$FAKE_HEX_CHECKSUM
    retirement=null
    status=200

    case "$FAKE_HEX_MODE:$package" in
      partial:mailglass_admin) status=404 ;;
      retired:mailglass) retirement='{"reason":"deprecated"}' ;;
      malformed:mailglass_admin) checksum=short ;;
    esac

    if [[ "$status" == 404 ]]; then
      printf '{}' > "$output"
    else
      printf '{"version":"%s","retirement":%s,"checksum":"%s"}' "$version" "$retirement" "$checksum" > "$output"
    fi
    printf '%s' "$status"
    """)

    File.chmod!(Path.join(bin, "curl"), 0o755)

    repo = Path.join(root, "repo")
    File.mkdir_p!(repo)
    git!(repo, ["init", "-q"])
    git!(repo, ["config", "user.email", "release-policy@example.test"])
    git!(repo, ["config", "user.name", "Release Policy Test"])
    File.write!(Path.join(repo, "README.md"), "close-out test repo")
    git!(repo, ["add", "."])
    git!(repo, ["commit", "-qm", "baseline"])
    git!(repo, ["tag", "mailglass-v3.0.0"])
    {tag_sha, 0} = System.cmd("git", ["-C", repo, "rev-parse", "mailglass-v3.0.0^{commit}"])
    tag_sha = String.trim(tag_sha)

    write_baseline_of_record!(repo, @candidates, tag_sha)

    on_exit(fn -> File.rm_rf!(root) end)

    {:ok, root: root, bin: bin, repo: repo, tag_sha: tag_sha}
  end

  # The four records the repo keeps of what is published. --write is gated on
  # these agreeing with the release being closed out, so the fixture has to
  # carry them or the gate is never exercised on the happy path.
  defp write_baseline_of_record!(repo, versions, tag_sha) do
    core = versions["mailglass"]
    inbound = versions["mailglass_inbound"]
    [major, minor | _] = String.split(core, ".")

    File.mkdir_p!(Path.join(repo, "test/scripts"))
    File.mkdir_p!(Path.join(repo, ".planning/publish"))

    File.write!(Path.join(repo, "test/scripts/reconcile_release_versions_test.exs"), """
    defmodule Fixture do
      defp baseline_versions do
        %{
          "mailglass" => "#{versions["mailglass"]}",
          "mailglass_admin" => "#{versions["mailglass_admin"]}",
          "mailglass_inbound" => "#{inbound}"
        }
      end

      defp evidence_identifiers do
        %{
          "hex_release_endpoints" => %{
            "mailglass" => "https://hex.pm/api/packages/mailglass/releases/#{versions["mailglass"]}",
            "mailglass_admin" =>
              "https://hex.pm/api/packages/mailglass_admin/releases/#{versions["mailglass_admin"]}",
            "mailglass_inbound" =>
              "https://hex.pm/api/packages/mailglass_inbound/releases/#{inbound}"
          },
          "hex_release_checksums" => %{
            "mailglass" => "#{@checksum}",
            "mailglass_admin" => "#{@checksum}",
            "mailglass_inbound" => "#{@checksum}"
          },
          "historical_tag" => "mailglass-v#{core}",
          "historical_tag_sha" => "#{tag_sha}"
        }
      end

      defp inbound_summary_expectation(_repository_versions) do
        %{
          "version" => "#{inbound}",
          "manifest_version" => "#{inbound}",
          "source_ref" => "v#{inbound}",
          "mailglass_inbound_publish_pin" => "~> #{major}.#{minor} and >= #{core}"
        }
      end
    end
    """)

    for {package, version} <- versions do
      File.write!(
        Path.join(repo, ".planning/publish/#{package}-publish-summary.json"),
        Jason.encode!(%{"version" => version, "linked_versions" => versions})
      )
    end
  end

  test "happy path prints the inactive successor and leaves the ledger untouched", context do
    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    {output, status} = run(context, ["--target", target_path, "--repo", context.repo])

    assert status == 0, output
    assert {:ok, successor} = Jason.decode(output)
    assert successor["status"] == "inactive"
    assert successor["baselines"] == @candidates
    assert File.read!(target_path) == original

    assert curl_log(context) == [
             "https://hex.pm/api/packages/mailglass/releases/3.0.0",
             "https://hex.pm/api/packages/mailglass_admin/releases/3.0.0",
             "https://hex.pm/api/packages/mailglass_inbound/releases/2.2.0"
           ]
  end

  test "--write replaces the ledger in place with exactly the printed bytes", context do
    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)

    {printed, print_status} = run(context, ["--target", target_path, "--repo", context.repo])
    assert print_status == 0, printed

    write_target_path = write_json(context.root, "write-target.json", target)

    {write_output, write_status} =
      run(context, ["--target", write_target_path, "--repo", context.repo, "--write"])

    assert write_status == 0, write_output
    assert write_output == ""
    assert File.read!(write_target_path) == printed
  end

  test "--write refuses while the published baseline of record still describes the previous release",
       context do
    # Exactly the 2.6.0 close-out: the ledger advanced, the other three records
    # did not, and Core Full Suite went red on both schemas one commit later
    # (29464056). Writing `inactive` is what flips
    # ReconcileReleaseVersionsTest to its published-baseline branch, so the
    # disagreement has to stop the write rather than be discovered in CI.
    write_baseline_of_record!(context.repo, @baselines, context.tag_sha)

    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    {output, status} = run(context, ["--target", target_path, "--repo", context.repo, "--write"])

    assert status != 0
    assert File.read!(target_path) == original, "a refused close-out must not touch the ledger"

    assert output =~ "published baseline of record does not yet describe this release"
    assert output =~ ~s("mailglass" => "3.0.0")
    assert output =~ ~s("mailglass_inbound" => "2.2.0")
    assert output =~ "publish summary (mailglass): version is 2.5.0, expected 3.0.0"
    assert output =~ "mix mailglass.publish.check --package mailglass"

    # The operator needs the evidence in hand to fix it, and the checksums must
    # be copied from the Hex API rather than recomputed locally.
    assert output =~ @checksum
    assert output =~ "mailglass-v3.0.0"
    assert output =~ context.tag_sha
  end

  test "the read-only path still succeeds when the baseline of record disagrees", context do
    # release-please.yml runs this script WITHOUT --write as an in-memory
    # self-heal for a stranded ledger, and never writes the repo file. That
    # reasoning is about the ledger alone; gating it on the repo's baseline
    # records would fail the release control closed on every run.
    write_baseline_of_record!(context.repo, @baselines, context.tag_sha)

    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    {output, status} = run(context, ["--target", target_path, "--repo", context.repo])

    assert status == 0, output
    assert {:ok, successor} = Jason.decode(output)
    assert successor["status"] == "inactive"
    assert File.read!(target_path) == original
  end

  test "requests exactly the three candidate release endpoints in package order", context do
    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)

    assert {_output, 0} = run(context, ["--target", target_path, "--repo", context.repo])

    assert curl_log(context) == [
             "https://hex.pm/api/packages/mailglass/releases/3.0.0",
             "https://hex.pm/api/packages/mailglass_admin/releases/3.0.0",
             "https://hex.pm/api/packages/mailglass_inbound/releases/2.2.0"
           ]
  end

  test "refuses an already-inactive ledger and leaves the file untouched", context do
    target = Map.put(authorized_target(), "status", "inactive")
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    {output, status} =
      run(context, ["--target", target_path, "--repo", context.repo, "--write"])

    assert status != 0
    assert output =~ "ERROR"
    assert File.read!(target_path) == original
  end

  test "fails closed on a 404 Hex release and leaves the ledger untouched", context do
    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    {output, status} =
      run(context, ["--target", target_path, "--repo", context.repo, "--write"],
        hex_mode: "partial"
      )

    assert status != 0
    assert output =~ "ERROR"
    assert output =~ "HTTP 404"
    assert File.read!(target_path) == original
  end

  test "fails closed on a retired Hex release and leaves the ledger untouched", context do
    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    {output, status} =
      run(context, ["--target", target_path, "--repo", context.repo, "--write"],
        hex_mode: "retired"
      )

    assert status != 0
    assert output =~ "ERROR"
    assert File.read!(target_path) == original
  end

  test "fails closed on a malformed Hex checksum and leaves the ledger untouched", context do
    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    {output, status} =
      run(context, ["--target", target_path, "--repo", context.repo, "--write"],
        hex_mode: "malformed"
      )

    assert status != 0
    assert output =~ "ERROR"
    assert File.read!(target_path) == original
  end

  test "fails closed when the core release tag does not resolve and leaves the ledger untouched",
       context do
    target = authorized_target()
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    empty_repo = Path.join(context.root, "empty-repo")
    File.mkdir_p!(empty_repo)
    git!(empty_repo, ["init", "-q"])
    git!(empty_repo, ["config", "user.email", "release-policy@example.test"])
    git!(empty_repo, ["config", "user.name", "Release Policy Test"])
    File.write!(Path.join(empty_repo, "README.md"), "no tags here")
    git!(empty_repo, ["add", "."])
    git!(empty_repo, ["commit", "-qm", "baseline"])

    {output, status} =
      run(context, ["--target", target_path, "--repo", empty_repo, "--write"])

    assert status != 0
    assert output =~ "ERROR"
    assert output =~ "does not resolve to a commit"
    assert File.read!(target_path) == original
  end

  test "fails closed when the ledger's recorded publication evidence disagrees with Hex",
       context do
    target = published_target(context.tag_sha, String.duplicate("f", 64))
    target_path = write_json(context.root, "target.json", target)
    original = File.read!(target_path)

    {output, status} =
      run(context, ["--target", target_path, "--repo", context.repo, "--write"])

    assert status != 0
    assert output =~ "ERROR"
    assert output =~ "release policy refused the close-out transition"
    assert File.read!(target_path) == original
  end

  test "accepts a published ledger whose recorded publication evidence matches Hex", context do
    target = published_target(context.tag_sha, @checksum)
    target_path = write_json(context.root, "target.json", target)

    {output, status} = run(context, ["--target", target_path, "--repo", context.repo])

    assert status == 0, output
    assert {:ok, successor} = Jason.decode(output)
    assert successor["status"] == "inactive"
  end

  defp authorized_target do
    %{
      "schema_version" => 1,
      "status" => "authorized",
      "package_set" => @packages,
      "baselines" => @baselines,
      "candidate_versions" => @candidates,
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
        "authorization" => "authorized",
        "publication" => "not_started"
      }
    }
  end

  defp published_target(tag_sha, recorded_checksum) do
    captured = %{
      authorized_target()
      | "status" => "captured"
    }

    captured = put_in(captured, ["states", "authorization"], "unauthorized")
    {:ok, digest} = Mailglass.ReleasePolicy.candidate_digest(captured)

    captured
    |> Map.put("status", "published")
    |> put_in(["states", "authorization"], "authorized")
    |> put_in(["states", "publication"], "published")
    |> Map.put("final_identity", %{
      "tag_sha" => tag_sha,
      "publication_evidence" => %{
        "candidate_digest" => digest,
        "workflow_run_url" => "https://github.com/szTheory/mailglass/actions/runs/123456789",
        "release_ids" =>
          Map.new(Enum.with_index(@packages), fn {package, index} -> {package, 1000 + index} end),
        "tag_shas" => Map.new(@packages, &{&1, tag_sha}),
        "hex_release_checksums" => Map.new(@packages, &{&1, recorded_checksum})
      },
      "adoption_evidence" => nil
    })
  end

  defp evidence do
    %{
      "hex_package_endpoints" => Map.new(@packages, &{&1, "https://hex.pm/api/packages/#{&1}"}),
      "hex_release_endpoints" =>
        Map.new(@packages, fn package ->
          {package, "https://hex.pm/api/packages/#{package}/releases/#{@baselines[package]}"}
        end),
      "hex_release_checksums" => Map.new(@packages, &{&1, String.duplicate("a", 64)}),
      "historical_tag" => "mailglass-v#{@baselines["mailglass"]}",
      "historical_tag_sha" => String.duplicate("e", 40)
    }
  end

  defp write_json(root, name, value) do
    path = Path.join(root, name)
    File.write!(path, Jason.encode!(value))
    path
  end

  defp git!(dir, args) do
    assert {_output, 0} = System.cmd("git", ["-C", dir | args], stderr_to_stdout: true)
  end

  # The wrapper fetches each package's checksum directly, then independently
  # re-verifies it through the hardened release_policy_hex_release_state.sh,
  # which curls the same endpoint again. Both share this fake curl, so each
  # package's URL appears twice consecutively; dedupe to assert the wrapper's
  # own three-endpoint, package-ordered request set.
  defp curl_log(context) do
    context.root
    |> Path.join("curl.log")
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.uniq()
  end

  defp run(context, args, overrides \\ []) do
    hex_mode = Keyword.get(overrides, :hex_mode, "valid")

    env = [
      {"PATH", context.bin <> ":" <> System.get_env("PATH", "")},
      {"FAKE_CURL_LOG", Path.join(context.root, "curl.log")},
      {"FAKE_HEX_MODE", hex_mode},
      {"FAKE_HEX_CHECKSUM", @checksum}
    ]

    System.cmd("bash", [@script | args], cd: @repo_root, env: env, stderr_to_stdout: true)
  end
end
