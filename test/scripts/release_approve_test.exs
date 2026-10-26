defmodule Mailglass.Scripts.ReleaseApproveTest do
  # scripts/release_approve.sh approves the single `hex-publish` gate of one
  # publish-hex.yml run. It must POST only after every check passes, resolve the
  # environment by name, and never approve for a non-reviewer or without consent.
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/release_approve.sh")
  @run_id "40379381910"
  @env_id 14_597_720_602

  @fake_gh ~S"""
  #!/usr/bin/env bash
  set -euo pipefail
  printf '%s\n' "$*" >> "$FAKE_GH_LOG"
  case "$*" in
    "api repos/szTheory/mailglass/actions/runs/${FAKE_RUN_ID}")
      printf '%s' "$FAKE_RUN_JSON" ;;
    "api repos/szTheory/mailglass/environments/hex-publish --jq .id")
      printf '%s\n' "$FAKE_ENV_ID" ;;
    "api repos/szTheory/mailglass/actions/runs/${FAKE_RUN_ID}/pending_deployments")
      printf '%s' "$FAKE_PENDING_JSON" ;;
    "api -X POST repos/szTheory/mailglass/actions/runs/${FAKE_RUN_ID}/pending_deployments --input -")
      cat > "$FAKE_POST_BODY"
      printf '[]' ;;
    *)
      echo "unexpected gh call: $*" >&2
      exit 1 ;;
  esac
  """

  setup do
    root = Path.join(System.tmp_dir!(), "release-approve-#{System.unique_integer([:positive])}")
    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)
    on_exit(fn -> File.rm_rf!(root) end)

    gh = Path.join(bin, "gh")
    File.write!(gh, @fake_gh)
    File.chmod!(gh, 0o755)
    %{root: root, bin: bin}
  end

  test "approves exactly the hex-publish environment resolved by name", ctx do
    {out, status} = run(ctx, [@run_id, "--yes"])

    assert status == 0, out
    assert out =~ "Approved hex-publish for run #{@run_id}"

    body = ctx |> post_body_path() |> File.read!() |> Jason.decode!()
    assert body["environment_ids"] == [@env_id]
    assert body["state"] == "approved"
    assert body["comment"] =~ "scripts/release_approve.sh"
  end

  test "never approves when a precondition fails", ctx do
    hostile = [
      {[@run_id, "--yes"], %{"FAKE_PENDING_JSON" => pending(false)}, "not an allowed reviewer"},
      {[@run_id, "--yes"], %{"FAKE_PENDING_JSON" => "[]"}, "no single pending hex-publish"},
      {[@run_id, "--yes"], %{"FAKE_PENDING_JSON" => pending(true, 1, "hex-publish")},
       "no single pending hex-publish"},
      {[@run_id, "--yes"], %{"FAKE_PENDING_JSON" => pending(true, @env_id, "other")},
       "no single pending hex-publish"},
      {[@run_id, "--yes"], %{"FAKE_RUN_JSON" => run_json(".github/workflows/ci.yml", "waiting")},
       "not a .github/workflows/publish-hex.yml run"},
      {[@run_id, "--yes"],
       %{"FAKE_RUN_JSON" => run_json(".github/workflows/publish-hex.yml", "completed")},
       "not waiting for an approval"},
      {[@run_id, "--yes"], %{"FAKE_ENV_ID" => "null"}, "environment id is malformed"},
      {["12; rm -rf /", "--yes"], %{}, "run id must be a positive integer"},
      # No --yes and no terminal: consent cannot be given, so nothing is approved.
      {[@run_id], %{}, "no terminal to confirm on"},
      {[], %{}, "usage:"}
    ]

    for {args, overrides, message} <- hostile do
      File.rm(post_body_path(ctx))
      {out, status} = run(ctx, args, overrides)

      assert status != 0, "unexpectedly approved #{inspect({args, overrides})}"
      assert out =~ message, out
      refute File.exists?(post_body_path(ctx)), "POSTed an approval for #{inspect(args)}"
    end
  end

  test "no workflow or script invokes the approval on its own" do
    callers =
      ["git", "-C", @repo_root, "grep", "-l", "release_approve.sh", "--", ".github", "scripts"]
      |> then(fn [cmd | args] -> System.cmd(cmd, args) end)
      |> elem(0)
      |> String.split("\n", trim: true)

    # Apart from the script itself, the only mention is the approve-release job's
    # comment that points the human at it.
    assert Enum.reject(callers, &(&1 == "scripts/release_approve.sh")) ==
             [".github/workflows/publish-hex.yml"]

    refute File.read!(Path.join(@repo_root, ".github/workflows/publish-hex.yml")) =~
             ~r/run:.*release_approve\.sh/
  end

  defp run(ctx, args, overrides \\ %{}) do
    env =
      %{
        "PATH" => ctx.bin <> ":" <> System.get_env("PATH", ""),
        "FAKE_GH_LOG" => Path.join(ctx.root, "gh.log"),
        "FAKE_POST_BODY" => post_body_path(ctx),
        "FAKE_RUN_ID" => @run_id,
        "FAKE_ENV_ID" => Integer.to_string(@env_id),
        "FAKE_RUN_JSON" => run_json(".github/workflows/publish-hex.yml", "waiting"),
        "FAKE_PENDING_JSON" => pending(true)
      }
      |> Map.merge(overrides)

    System.cmd("bash", [@script | args],
      cd: @repo_root,
      env: Map.to_list(env),
      stderr_to_stdout: true,
      into: ""
    )
  end

  defp post_body_path(ctx), do: Path.join(ctx.root, "post.json")

  defp run_json(path, status) do
    Jason.encode!(%{
      "id" => String.to_integer(@run_id),
      "path" => path,
      "status" => status,
      "head_sha" => String.duplicate("a", 40),
      "html_url" => "https://github.com/szTheory/mailglass/actions/runs/#{@run_id}"
    })
  end

  defp pending(can_approve, env_id \\ @env_id, name \\ "hex-publish") do
    Jason.encode!([
      %{
        "environment" => %{"id" => env_id, "name" => name},
        "current_user_can_approve" => can_approve,
        "wait_timer_started_at" => "2026-10-26T19:10:00Z"
      }
    ])
  end
end
