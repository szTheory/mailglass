defmodule Mailglass.Scripts.CheckStateMdPrRefsTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/check_state_md_pr_refs.sh")

  test "a prefix-colliding reference checks its own line rather than an earlier longer ID" do
    in_fixture(fn fixture ->
      File.write!(fixture.target, "PR #260 is closed.\nPR #26 is open.\n")

      {output, status} = run(fixture)
      result = Jason.decode!(output)

      assert status == 1,
             "#26 is closed on GitHub but described as open, so the audit must block:\n#{output}"

      assert result["status"] == "blocked"
      assert check_status(result, "#260") == "pass"
      assert check_status(result, "#26") == "blocked"
    end)
  end

  defp run(fixture) do
    System.cmd("bash", [@script, "--target", fixture.target, "--format", "json"],
      cd: @repo_root,
      env: [{"PATH", fixture.bin <> ":" <> System.get_env("PATH", "")}],
      stderr_to_stdout: true
    )
  end

  defp check_status(result, name) do
    result["checks"]
    |> Enum.find(&(&1["name"] == name))
    |> Map.fetch!("status")
  end

  defp in_fixture(fun) do
    root = Path.join(System.tmp_dir!(), "state-md-pr-refs-#{System.unique_integer([:positive])}")
    bin = Path.join(root, "bin")
    target = Path.join(root, "STATE.md")
    File.mkdir_p!(bin)

    File.write!(Path.join(bin, "gh"), """
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ "$1" == "auth" && "$2" == "status" ]]; then
      exit 0
    fi

    if [[ "$1" == "pr" && "$2" == "view" ]]; then
      case "$3" in
        26|260) printf '%s\\n' '{"state":"CLOSED","title":"fixture"}'; exit 0 ;;
      esac
    fi

    exit 1
    """)

    File.chmod!(Path.join(bin, "gh"), 0o755)

    try do
      fun.(%{bin: bin, target: target})
    after
      File.rm_rf!(root)
    end
  end
end
