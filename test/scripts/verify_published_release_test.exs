defmodule Mailglass.Scripts.VerifyPublishedReleaseTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/verify_published_release.sh")
  @policy Path.join(@repo_root, "scripts/release_policy.exs")
  @packages ~w(mailglass mailglass_admin mailglass_inbound)
  @tag_sha String.duplicate("d", 40)
  @workflow_head_sha String.duplicate("9", 40)
  @checksum String.duplicate("e", 64)
  @run_id 123_456_789
  @run_url "https://github.com/szTheory/mailglass/actions/runs/#{@run_id}"

  setup_all do
    Code.require_file(@policy)
    :ok
  end

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-published-release-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)

    File.write!(Path.join(bin, "gh"), """
    #!/usr/bin/env bash
    set -euo pipefail
    [[ "$1" == api && "$#" == 2 ]] || exit 64
    endpoint=$2
    printf '%s\n' "$endpoint" >> "$FAKE_GH_LOG"

    case "$FAKE_GH_MODE:$endpoint" in
      failure:*) exit 1 ;;
      partial:repos/szTheory/mailglass/releases/1002) exit 1 ;;
      *:repos/szTheory/mailglass/actions/runs/123456789) printf '%s' "$FAKE_RUN_JSON" ;;
      *:repos/szTheory/mailglass/actions/runs/123456789/jobs*) printf '%s' "$FAKE_JOBS_JSON" ;;
      *:repos/szTheory/mailglass/releases/1001) printf '%s' "$FAKE_CORE_RELEASE_JSON" ;;
      *:repos/szTheory/mailglass/releases/1002) printf '%s' "$FAKE_ADMIN_RELEASE_JSON" ;;
      *:repos/szTheory/mailglass/releases/1003) printf '%s' "$FAKE_INBOUND_RELEASE_JSON" ;;
      *:repos/szTheory/mailglass/git/ref/tags/mailglass-v3.0.0) printf '%s' "$FAKE_CORE_REF_JSON" ;;
      *:repos/szTheory/mailglass/git/ref/tags/mailglass_admin-v3.0.0) printf '%s' "$FAKE_ADMIN_REF_JSON" ;;
      *:repos/szTheory/mailglass/git/ref/tags/mailglass_inbound-v2.2.0) printf '%s' "$FAKE_INBOUND_REF_JSON" ;;
      *) exit 65 ;;
    esac
    """)

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
    printf '%s\n' "$url" >> "$FAKE_CURL_LOG"

    package=${url#https://hex.pm/api/packages/}
    package=${package%%/*}
    version=${url##*/}
    checksum=$FAKE_HEX_CHECKSUM
    retirement=null
    status=200
    body_type=object

    case "$FAKE_HEX_MODE:$package" in
      partial:mailglass_admin) status=404 ;;
      wrong:mailglass_inbound) checksum=$FAKE_WRONG_CHECKSUM ;;
      retired:mailglass) retirement='{"reason":"deprecated"}' ;;
      ambiguous:mailglass_admin) body_type=array ;;
      failure:mailglass_inbound) exit 7 ;;
    esac

    if [[ "$body_type" == array ]]; then
      printf '[{"version":"%s","retirement":null,"checksum":"%s"}]' \
        "$version" "$checksum" > "$output"
    else
      printf '{"version":"%s","retirement":%s,"checksum":"%s"}' \
        "$version" "$retirement" "$checksum" > "$output"
    fi
    printf '%s' "$status"
    """)

    File.chmod!(Path.join(bin, "gh"), 0o755)
    File.chmod!(Path.join(bin, "curl"), 0o755)
    on_exit(fn -> File.rm_rf!(root) end)

    target = published_target()
    target_path = Path.join(root, "published.json")
    File.write!(target_path, Jason.encode!(target))

    {:ok, root: root, bin: bin, target: target, target_path: target_path}
  end

  test "accepts only the exact successful protected run, releases, tags, and active Hex records",
       context do
    assert {output, 0} = run(context)
    assert output =~ "published_release_verified=true"
    assert output =~ "candidate_digest=#{candidate_digest(context.target)}"
    assert output =~ "workflow_head_sha=#{@workflow_head_sha}"

    assert context.root |> Path.join("gh.log") |> File.read!() |> String.split("\n", trim: true) ==
             [
               "repos/szTheory/mailglass/actions/runs/123456789",
               "repos/szTheory/mailglass/actions/runs/123456789/jobs?per_page=100&filter=latest",
               "repos/szTheory/mailglass/releases/1001",
               "repos/szTheory/mailglass/git/ref/tags/mailglass-v3.0.0",
               "repos/szTheory/mailglass/releases/1002",
               "repos/szTheory/mailglass/git/ref/tags/mailglass_admin-v3.0.0",
               "repos/szTheory/mailglass/releases/1003",
               "repos/szTheory/mailglass/git/ref/tags/mailglass_inbound-v2.2.0"
             ]

    assert context.root |> Path.join("curl.log") |> File.read!() |> String.split("\n", trim: true) ==
             [
               "https://hex.pm/api/packages/mailglass/releases/3.0.0",
               "https://hex.pm/api/packages/mailglass_admin/releases/3.0.0",
               "https://hex.pm/api/packages/mailglass_inbound/releases/2.2.0"
             ]
  end

  test "runs the real policy validator before making any external query", context do
    invalid_path = Path.join(context.root, "invalid.json")
    File.write!(invalid_path, Jason.encode!(put_in(context.target, ["status"], "completed")))

    assert {_output, status} = run(%{context | target_path: invalid_path})
    assert status != 0
    refute File.exists?(Path.join(context.root, "gh.log"))
    refute File.exists?(Path.join(context.root, "curl.log"))
  end

  test "fails closed on failed, malformed, partial, ambiguous, or wrong GitHub evidence", context do
    hostile = [
      %{gh_mode: "failure"},
      %{run_json: "not-json"},
      %{run_json: Jason.encode!([valid_run()])},
      %{run_json: Jason.encode!(%{valid_run() | "conclusion" => "failure"})},
      %{run_json: Jason.encode!(%{valid_run() | "event" => "push"})},
      %{run_json: Jason.encode!(%{valid_run() | "path" => ".github/workflows/ci.yml"})},
      %{run_json: Jason.encode!(%{valid_run() | "head_sha" => "not-a-sha"})},
      %{run_json: Jason.encode!(%{valid_run() | "head_branch" => "release-candidate"})},
      %{
        run_json:
          Jason.encode!(%{
            valid_run()
            | "head_repository" => %{"full_name" => "attacker/fork"}
          })
      },
      %{gh_mode: "partial"},
      %{admin_release_json: Jason.encode!([valid_release("mailglass_admin", 1002)])},
      %{
        inbound_release_json:
          Jason.encode!(%{valid_release("mailglass_inbound", 1003) | "tag_name" => "wrong"})
      },
      %{
        core_ref_json:
          Jason.encode!(%{
            valid_ref("mailglass", "3.0.0")
            | "object" => %{"type" => "tag", "sha" => @tag_sha}
          })
      },
      %{
        core_ref_json:
          Jason.encode!(%{
            valid_ref("mailglass", "3.0.0")
            | "object" => %{"type" => "commit", "sha" => String.duplicate("a", 40)}
          })
      }
    ]

    Enum.each(hostile, fn overrides ->
      assert {_output, status} = run(context, overrides)
      assert status != 0, "unexpectedly accepted #{inspect(overrides)}"
    end)
  end

  test "rejects successful inert, dry-run, partial, duplicate, or failed publish job evidence",
       context do
    valid_jobs = valid_jobs()

    hostile = [
      %{jobs_json: "not-json"},
      %{jobs_json: Jason.encode!(valid_jobs["jobs"])},
      %{jobs_json: Jason.encode!(%{"total_count" => 4, "jobs" => Enum.take(valid_jobs["jobs"], 4)})},
      %{
        jobs_json:
          Jason.encode!(%{
            "total_count" => 7,
            "jobs" =>
              Enum.map(valid_jobs["jobs"], fn
                %{"name" => "publish-admin"} = job -> %{job | "conclusion" => "skipped"}
                job -> job
              end)
          })
      },
      %{
        jobs_json:
          Jason.encode!(%{
            "total_count" => 8,
            "jobs" => [hd(valid_jobs["jobs"]) | valid_jobs["jobs"]]
          })
      }
    ]

    Enum.each(hostile, fn overrides ->
      assert {_output, status} = run(context, overrides)
      assert status != 0, "unexpectedly accepted publish jobs #{inspect(overrides)}"
    end)
  end

  test "fails closed on partial, ambiguous, retired, mismatched, or unavailable Hex evidence",
       context do
    for mode <- ~w(partial ambiguous retired wrong failure) do
      assert {_output, status} = run(context, %{hex_mode: mode})
      assert status != 0, "unexpectedly accepted Hex mode #{mode}"
    end
  end

  defp run(context, overrides \\ %{}) do
    env =
      context
      |> valid_env()
      |> Map.merge(Map.new(overrides, fn {key, value} -> {env_name(key), value} end))

    System.cmd("bash", [@script, context.target_path],
      cd: @repo_root,
      env: Map.to_list(env),
      stderr_to_stdout: true
    )
  end

  defp valid_env(context) do
    %{
      "PATH" => context.bin <> ":" <> System.get_env("PATH", ""),
      "FAKE_GH_LOG" => Path.join(context.root, "gh.log"),
      "FAKE_CURL_LOG" => Path.join(context.root, "curl.log"),
      "FAKE_GH_MODE" => "valid",
      "FAKE_HEX_MODE" => "valid",
      "FAKE_HEX_CHECKSUM" => @checksum,
      "FAKE_WRONG_CHECKSUM" => String.duplicate("f", 64),
      "FAKE_RUN_JSON" => Jason.encode!(valid_run()),
      "FAKE_JOBS_JSON" => Jason.encode!(valid_jobs()),
      "FAKE_CORE_RELEASE_JSON" => Jason.encode!(valid_release("mailglass", 1001)),
      "FAKE_ADMIN_RELEASE_JSON" => Jason.encode!(valid_release("mailglass_admin", 1002)),
      "FAKE_INBOUND_RELEASE_JSON" => Jason.encode!(valid_release("mailglass_inbound", 1003)),
      "FAKE_CORE_REF_JSON" => Jason.encode!(valid_ref("mailglass", "3.0.0")),
      "FAKE_ADMIN_REF_JSON" => Jason.encode!(valid_ref("mailglass_admin", "3.0.0")),
      "FAKE_INBOUND_REF_JSON" => Jason.encode!(valid_ref("mailglass_inbound", "2.2.0"))
    }
  end

  defp env_name(key), do: "FAKE_" <> (key |> Atom.to_string() |> String.upcase())

  defp valid_run do
    %{
      "id" => @run_id,
      "html_url" => @run_url,
      "repository" => %{"full_name" => "szTheory/mailglass"},
      "event" => "workflow_dispatch",
      "status" => "completed",
      "conclusion" => "success",
      "head_sha" => @workflow_head_sha,
      "head_branch" => "main",
      "head_repository" => %{"full_name" => "szTheory/mailglass"},
      "path" => ".github/workflows/publish-hex.yml"
    }
  end

  defp valid_jobs do
    names = [
      "prepublish-summary",
      "ensure-live-ci-runs",
      "gate-ci-green",
      "publish-core",
      "publish-admin",
      "publish-inbound",
      "dispatch-post-publish-smoke"
    ]

    %{
      "total_count" => length(names),
      "jobs" => Enum.map(names, &%{"name" => &1, "status" => "completed", "conclusion" => "success"})
    }
  end

  defp valid_release(package, id) do
    %{
      "id" => id,
      "tag_name" => expected_tag(package),
      "draft" => false,
      "prerelease" => false
    }
  end

  defp valid_ref(package, _version) do
    %{
      "ref" => "refs/tags/#{expected_tag(package)}",
      "object" => %{"type" => "commit", "sha" => @tag_sha}
    }
  end

  defp expected_tag("mailglass"), do: "mailglass-v3.0.0"
  defp expected_tag("mailglass_admin"), do: "mailglass_admin-v3.0.0"
  defp expected_tag("mailglass_inbound"), do: "mailglass_inbound-v2.2.0"

  defp published_target do
    target = %{
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

    digest = candidate_digest(target)

    target
    |> Map.put("status", "published")
    |> put_in(["states", "authorization"], "authorized")
    |> put_in(["states", "publication"], "published")
    |> Map.put("final_identity", %{
      "tag_sha" => @tag_sha,
      "publication_evidence" => %{
        "candidate_digest" => digest,
        "workflow_run_url" => @run_url,
        "release_ids" => %{
          "mailglass" => 1001,
          "mailglass_admin" => 1002,
          "mailglass_inbound" => 1003
        },
        "tag_shas" => Map.new(@packages, &{&1, @tag_sha}),
        "hex_release_checksums" => Map.new(@packages, &{&1, @checksum})
      },
      "adoption_evidence" => nil
    })
  end

  defp candidate_digest(target) do
    {:ok, digest} = apply(Mailglass.ReleasePolicy, :candidate_digest, [target])
    digest
  end

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
end
