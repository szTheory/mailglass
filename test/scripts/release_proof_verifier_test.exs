defmodule Mailglass.Scripts.ReleaseProofVerifierTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../scripts/verify_release_proof.exs", __DIR__)
  @candidate String.duplicate("a", 40)
  @checksum String.duplicate("b", 64)
  @packages ["mailglass", "mailglass_admin", "mailglass_inbound"]
  @versions %{
    "mailglass" => "2.4.1",
    "mailglass_admin" => "2.4.1",
    "mailglass_inbound" => "2.1.2"
  }

  test "prepublication accepts exact candidate proof without a publish run or approval event" do
    with_fixture("prepublication", ledger("prepublication"), prepublication_evidence(), fn output,
                                                                                           status ->
      assert status == 0, output
      assert output =~ "release proof verified"
    end)
  end

  test "prepublication fails closed on occupied versions, archive drift, environment drift, and CI drift" do
    mutations = [
      fn evidence -> put_in(evidence, ["hex_releases", "mailglass"], %{"version" => "2.4.1"}) end,
      fn evidence ->
        put_in(evidence, ["archive_checksums", "mailglass"], String.duplicate("c", 64))
      end,
      fn evidence -> put_in(evidence, ["environment_protection", "can_admins_bypass"], true) end,
      fn evidence -> put_in(evidence, ["ci_runs", "ci", "conclusion"], "failure") end,
      fn evidence ->
        put_in(evidence, ["required_checks", Access.at(0), "conclusion"], "failure")
      end
    ]

    Enum.each(mutations, fn mutate ->
      with_fixture(
        "prepublication",
        ledger("prepublication"),
        mutate.(prepublication_evidence()),
        fn output, status ->
          assert status != 0
          assert output =~ "release proof verification failed"
        end
      )
    end)
  end

  test "complete accepts only ledger-bound protected publication and exact Hex artifacts" do
    with_fixture("complete", ledger("complete"), complete_evidence(), fn output, status ->
      assert status == 0, output
      assert output =~ "release proof verified"
    end)
  end

  test "complete fails closed on run, approval, publish step, deployment, artifact, or Hex drift" do
    mutations = [
      fn evidence -> put_in(evidence, ["publish_run", "head_sha"], String.duplicate("d", 40)) end,
      fn evidence -> Map.put(evidence, "approvals", []) end,
      fn evidence ->
        update_in(
          evidence,
          ["publish_jobs", Access.at(0), "steps", Access.at(0)],
          &Map.put(&1, "conclusion", "skipped")
        )
      end,
      fn evidence -> put_in(evidence, ["deployments", Access.at(0), "states"], ["failure"]) end,
      fn evidence ->
        put_in(evidence, ["release_artifact", "candidate_sha"], String.duplicate("e", 40))
      end,
      fn evidence ->
        put_in(evidence, ["hex_releases", "mailglass", "checksum"], String.duplicate("f", 64))
      end
    ]

    Enum.each(mutations, fn mutate ->
      with_fixture("complete", ledger("complete"), mutate.(complete_evidence()), fn output,
                                                                                    status ->
        assert status != 0
        assert output =~ "release proof verification failed"
      end)
    end)
  end

  test "the two stages cannot consume each other's evidence" do
    with_fixture("prepublication", ledger("prepublication"), complete_evidence(), fn _output,
                                                                                     status ->
      assert status != 0
    end)

    with_fixture("complete", ledger("complete"), prepublication_evidence(), fn _output, status ->
      assert status != 0
    end)
  end

  defp with_fixture(stage, ledger, evidence, fun) do
    root =
      Path.join(System.tmp_dir!(), "mailglass-release-proof-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    ledger_path = Path.join(root, "ledger.json")
    fixture_path = Path.join(root, "fixture.json")
    File.write!(ledger_path, Jason.encode!(ledger))
    File.write!(fixture_path, Jason.encode!(evidence))

    try do
      {output, status} =
        System.cmd(
          "mix",
          [
            "run",
            @script,
            "--",
            "--ledger",
            ledger_path,
            "--fixture",
            fixture_path,
            "--stage",
            stage
          ],
          stderr_to_stdout: true
        )

      fun.(output, status)
    after
      File.rm_rf(root)
    end
  end

  defp ledger(stage) do
    publication = %{
      "workflow_path" => ".github/workflows/publish-hex.yml",
      "workflow_name" => "publish-hex",
      "environment" => "hex-publish",
      "environment_protection" => %{
        "required_reviewer" => "szTheory",
        "prevent_self_review" => false,
        "can_admins_bypass" => false
      },
      "run_id" => if(stage == "complete", do: 123, else: nil),
      "run_url" => if(stage == "complete", do: "https://github.example/actions/runs/123", else: nil)
    }

    %{
      "candidate" => %{"sha" => @candidate, "tag" => "mailglass-v2.4.1"},
      "publication" => publication,
      "prepublication" => %{
        "ci" => %{"run_id" => 201, "run_url" => "https://github.example/actions/runs/201"},
        "advisory" => %{"run_id" => 202, "run_url" => "https://github.example/actions/runs/202"}
      },
      "release_packages" => @packages,
      "target_versions" => @versions,
      "archive_checksums" => Map.new(@packages, &{&1, @checksum})
    }
  end

  defp common_evidence do
    %{
      "candidate_head" => @candidate,
      "tag_sha" => @candidate,
      "resolver_packages" => @packages,
      "resolver_bases" => %{
        "mailglass" => "mailglass-v2.4.0",
        "mailglass_admin" => "mailglass_admin-v2.4.0",
        "mailglass_inbound" => "mailglass_inbound-v2.1.1"
      },
      "source_versions" => @versions,
      "archive_checksums" => Map.new(@packages, &{&1, @checksum}),
      "environment_protection" => %{
        "name" => "hex-publish",
        "id" => 42,
        "can_admins_bypass" => false,
        "prevent_self_review" => false,
        "required_reviewers" => ["szTheory"]
      }
    }
  end

  defp prepublication_evidence do
    common_evidence()
    |> Map.merge(%{
      "hex_releases" => Map.new(@packages, &{&1, nil}),
      "branch_protection_contexts" => ["CI Green", "Guard Release Trigger"],
      "required_checks" => [
        %{"name" => "CI Green", "status" => "completed", "conclusion" => "success"},
        %{"name" => "Guard Release Trigger", "status" => "completed", "conclusion" => "success"}
      ],
      "ci_runs" => %{
        "ci" => %{
          "id" => 201,
          "html_url" => "https://github.example/actions/runs/201",
          "path" => ".github/workflows/ci.yml@refs/heads/release",
          "head_sha" => @candidate,
          "status" => "completed",
          "conclusion" => "success",
          "jobs" => [%{"name" => "CI Green", "status" => "completed", "conclusion" => "success"}]
        },
        "advisory" => %{
          "id" => 202,
          "html_url" => "https://github.example/actions/runs/202",
          "path" => ".github/workflows/advisory-matrix.yml@refs/heads/release",
          "head_sha" => @candidate,
          "status" => "completed",
          "conclusion" => "success",
          "jobs" =>
            Enum.map(
              [
                "Core Full Suite (Elixir 1.18 / OTP 27 / schema public)",
                "Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)"
              ],
              &%{"name" => &1, "status" => "completed", "conclusion" => "success"}
            )
        }
      }
    })
  end

  defp complete_evidence do
    jobs =
      Enum.with_index(@packages, 11)
      |> Enum.map(fn {package, id} ->
        %{
          "id" => id,
          "name" => publish_job(package),
          "status" => "completed",
          "conclusion" => "success",
          "steps" => [%{"name" => publish_step(package), "conclusion" => "success"}]
        }
      end)

    common_evidence()
    |> Map.merge(%{
      "publish_run" => %{
        "id" => 123,
        "html_url" => "https://github.example/actions/runs/123",
        "path" => ".github/workflows/publish-hex.yml@refs/tags/mailglass-v2.4.1",
        "name" => "publish-hex",
        "event" => "workflow_dispatch",
        "head_sha" => @candidate,
        "status" => "completed",
        "conclusion" => "success"
      },
      "publish_jobs" => jobs,
      "approvals" => [
        %{
          "state" => "approved",
          "user" => %{"login" => "szTheory"},
          "environments" => [%{"name" => "hex-publish"}]
        }
      ],
      "deployments" =>
        Enum.map(jobs, fn job ->
          %{
            "job_id" => job["id"],
            "sha" => @candidate,
            "ref" => "mailglass-v2.4.1",
            "environment" => "hex-publish",
            "states" => ["in_progress", "success"]
          }
        end),
      "release_artifact" => %{
        "ref" => "mailglass-v2.4.1",
        "candidate_sha" => @candidate,
        "release_packages" => @packages,
        "packages" => @versions,
        "artifact_digest" => "sha256:#{@checksum}"
      },
      "hex_releases" =>
        Map.new(@packages, fn package ->
          {package,
           %{
             "version" => @versions[package],
             "checksum" => @checksum,
             "tarball_checksum" => @checksum,
             "has_docs" => true,
             "retirement" => nil
           }}
        end)
    })
  end

  defp publish_job("mailglass"), do: "publish-core"
  defp publish_job(package), do: "publish-#{String.replace_prefix(package, "mailglass_", "")}"
  defp publish_step("mailglass"), do: "Publish mailglass to Hex.pm"
  defp publish_step("mailglass_admin"), do: "Publish mailglass_admin to Hex.pm"
  defp publish_step("mailglass_inbound"), do: "Publish mailglass_inbound to Hex.pm"
end
