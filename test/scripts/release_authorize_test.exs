defmodule Mailglass.Scripts.ReleaseAuthorizeTest do
  # scripts/release_authorize.sh replaces the hand-built ledger authorization
  # PR (#311 copied six values from an artifact by hand). It must write exactly
  # the authorized fields, validate before the ledger moves, print the CANDIDATE
  # digest, and never commit, push or open a PR unless given --pr.
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/release_authorize.sh")
  @policy Path.join(@repo_root, "scripts/release_policy.exs")
  @run_id "40365897654"
  @candidate_digest String.duplicate("4", 64)

  @fake_gh ~S"""
  #!/usr/bin/env bash
  set -euo pipefail
  printf 'gh %s\n' "$*" >> "$COMMAND_LOG"
  case "$1 $2" in
    "api repos/szTheory/mailglass/actions/runs/${FAKE_RUN_ID}") printf '%s' "$FAKE_RUN_JSON" ;;
    "run download")
      [ "$3" = "$FAKE_RUN_ID" ] && [ "$7" = "release-proposal-candidate-${FAKE_RUN_ID}" ] || exit 1
      mkdir -p "$9"
      printf '%s' "$FAKE_CANDIDATE" > "$9/proposal-candidate.json" ;;
    *) echo "unexpected gh call: $*" >&2; exit 1 ;;
  esac
  """

  @fake_git ~S"""
  #!/usr/bin/env bash
  set -euo pipefail
  printf 'git %s\n' "$*" >> "$COMMAND_LOG"
  [ "$1" = "-C" ] && shift 2
  case "$1 ${2:-}" in
    "fetch "*) exit 0 ;;
    "worktree add") mkdir -p "$4" ;;
    "worktree remove") rm -rf "$4" ;;
    *) echo "unexpected git call: $*" >&2; exit 1 ;;
  esac
  """

  @fake_mix ~S"""
  #!/usr/bin/env bash
  set -euo pipefail
  printf 'mix %s\n' "$*" >> "$COMMAND_LOG"
  case "$*" in
    *"-- validate-candidate "*)
      printf 'candidate_valid=true\ncandidate_digest=%s\n' "$FAKE_CANDIDATE_DIGEST" ;;
    *"-- validate-authorization "*)
      [ "${*: -1}" = "$FAKE_CANDIDATE_DIGEST" ] || exit 1
      printf 'authorized=true\n' ;;
    *) echo "unexpected mix call: $*" >&2; exit 1 ;;
  esac
  """

  @fake_validate_target ~S"""
  #!/usr/bin/env bash
  printf 'validate-target %s\n' "$*" >> "$COMMAND_LOG"
  [ "${FAKE_VALIDATE_TARGET_STATUS:-0}" = 0 ] || exit 1
  printf 'active=true core=2.8.0 admin=2.8.0 inbound=2.5.0\n'
  """

  setup_all do
    Code.require_file(@policy)
    :ok
  end

  setup do
    root = Path.join(System.tmp_dir!(), "release-authorize-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(root) end)

    for dir <- ["bin", "scripts"], do: File.mkdir_p!(Path.join(root, dir))

    install!(Path.join(root, "scripts/release_authorize.sh"), File.read!(@script))

    install!(
      Path.join(root, "scripts/release_policy_validate_target.sh"),
      @fake_validate_target
    )

    install!(Path.join(root, "bin/gh"), @fake_gh)
    install!(Path.join(root, "bin/git"), @fake_git)
    install!(Path.join(root, "bin/mix"), @fake_mix)

    target = Path.join(root, "release-target.json")
    File.write!(target, Jason.encode!(inactive_ledger(), pretty: true))
    %{root: root, target: target}
  end

  test "writes exactly the authorized fields, which the real policy accepts", ctx do
    {out, status} = run(ctx, [@run_id, "--target", ctx.target])
    assert status == 0, out
    assert out =~ "CANDIDATE DIGEST (pass this to the protected dispatches): #{@candidate_digest}"

    written = ctx.target |> File.read!() |> Jason.decode!()
    before = inactive_ledger()

    assert written ==
             before
             |> Map.put("status", "authorized")
             |> Map.merge(Map.take(candidate(), ["candidate_versions", "proposal_identity"]))
             |> put_in(
               ["publishable_content", "digest"],
               candidate()["publishable_content"]["digest"]
             )
             |> put_in(["states", "capture"], "captured")
             |> put_in(["states", "authorization"], "authorized")

    # The real policy, not a shim, accepts the written ledger end to end.
    assert {:ok, _} = policy(:validate_candidate, [written, candidate()])
    assert {:ok, digest} = policy(:candidate_digest, [written])
    assert {:ok, _} = policy(:validate_authorization_digest, [written, digest])
    # Negative control: the content digest is not the candidate digest.
    assert {:error, _} =
             policy(:validate_authorization_digest, [
               written,
               candidate()["publishable_content"]["digest"]
             ])

    log = File.read!(Path.join(ctx.root, "command.log"))
    assert log =~ "worktree add --detach"
    assert log =~ "validate-target"
    refute log =~ ~r/git .*(commit|push|switch)/
    refute log =~ "gh pr"
    refute File.exists?(Path.join(ctx.root, "head"))
  end

  test "refuses and leaves the ledger untouched when anything is off", ctx do
    original = File.read!(ctx.target)

    malformed_head = put_in(candidate(), ["proposal_identity", "head_sha"], "$(touch pwned)")

    hostile = [
      {%{"FAKE_RUN_JSON" => run_json(".github/workflows/ci.yml", "success")},
       "not a successful completed release-please.yml run"},
      {%{"FAKE_RUN_JSON" => run_json(".github/workflows/release-please.yml", "failure")},
       "not a successful completed release-please.yml run"},
      {%{"FAKE_CANDIDATE" => Jason.encode!(malformed_head)},
       "not a well-formed proposal candidate"},
      {%{"FAKE_CANDIDATE" => Jason.encode!(Map.put(candidate(), "status", "authorized"))},
       "not a well-formed proposal candidate"},
      {%{"FAKE_VALIDATE_TARGET_STATUS" => "1"}, "validate-target rejected"},
      {%{"FAKE_CANDIDATE_DIGEST" => "not-a-digest"}, "did not report a candidate digest"}
    ]

    for {overrides, message} <- hostile do
      {out, status} = run(ctx, [@run_id, "--target", ctx.target], overrides)
      assert status != 0, "unexpectedly authorized with #{inspect(overrides)}"
      assert out =~ message, out
      assert File.read!(ctx.target) == original
    end

    # An already-authorized ledger is never re-authorized over.
    :ok = File.write(ctx.target, Jason.encode!(Map.put(inactive_ledger(), "status", "published")))

    {out, status} = run(ctx, [@run_id, "--target", ctx.target])
    assert status != 0
    assert out =~ "the release ledger is not inactive"

    for args <- [[], ["12;rm"], [@run_id, "--pr", "--target", ctx.target]] do
      {_out, status} = run(ctx, args)
      assert status != 0, "accepted #{inspect(args)}"
    end
  end

  defp run(ctx, args, overrides \\ %{}) do
    env =
      %{
        "PATH" => Path.join(ctx.root, "bin") <> ":" <> System.get_env("PATH", ""),
        "COMMAND_LOG" => Path.join(ctx.root, "command.log"),
        "FAKE_RUN_ID" => @run_id,
        "FAKE_RUN_JSON" => run_json(".github/workflows/release-please.yml", "success"),
        "FAKE_CANDIDATE" => Jason.encode!(candidate()),
        "FAKE_CANDIDATE_DIGEST" => @candidate_digest
      }
      |> Map.merge(overrides)

    System.cmd("bash", [Path.join(ctx.root, "scripts/release_authorize.sh") | args],
      cd: ctx.root,
      env: Map.to_list(env),
      stderr_to_stdout: true
    )
  end

  defp install!(path, body) do
    File.write!(path, body)
    File.chmod!(path, 0o755)
  end

  defp policy(fun, args), do: apply(Module.concat([Mailglass, ReleasePolicy]), fun, args)

  defp run_json(path, conclusion) do
    Jason.encode!(%{"path" => path, "status" => "completed", "conclusion" => conclusion})
  end

  defp candidate do
    %{
      "candidate_versions" => %{
        "mailglass" => "2.8.0",
        "mailglass_admin" => "2.8.0",
        "mailglass_inbound" => "2.5.0"
      },
      "proposal_identity" => %{
        "head_sha" => String.duplicate("b", 40),
        "source_sha" => String.duplicate("c", 40)
      },
      "publishable_content" => %{
        "algorithm" => "sha256",
        "digest" => String.duplicate("a", 64),
        "excludes" => [".planning/release-target.json"]
      }
    }
  end

  # The live ledger shape after the 2.7.0 close-out: inactive, baselines 2.7.0.
  defp inactive_ledger do
    %{
      "baselines" => %{
        "mailglass" => "2.7.0",
        "mailglass_admin" => "2.7.0",
        "mailglass_inbound" => "2.4.0"
      },
      "candidate_versions" => nil,
      "final_identity" => %{"tag_sha" => nil},
      "package_set" => ["mailglass", "mailglass_admin", "mailglass_inbound"],
      "proposal_identity" => %{"head_sha" => nil, "source_sha" => nil},
      "publishable_content" => %{
        "algorithm" => "sha256",
        "digest" => nil,
        "excludes" => [".planning/release-target.json"]
      },
      "required_evidence_identifiers" => %{
        "hex_package_endpoints" => %{
          "mailglass" => "https://hex.pm/api/packages/mailglass",
          "mailglass_admin" => "https://hex.pm/api/packages/mailglass_admin",
          "mailglass_inbound" => "https://hex.pm/api/packages/mailglass_inbound"
        },
        "hex_release_checksums" => %{
          "mailglass" => String.duplicate("1", 64),
          "mailglass_admin" => String.duplicate("2", 64),
          "mailglass_inbound" => String.duplicate("3", 64)
        },
        "hex_release_endpoints" => %{
          "mailglass" => "https://hex.pm/api/packages/mailglass/releases/2.7.0",
          "mailglass_admin" => "https://hex.pm/api/packages/mailglass_admin/releases/2.7.0",
          "mailglass_inbound" => "https://hex.pm/api/packages/mailglass_inbound/releases/2.4.0"
        },
        "historical_tag" => "mailglass-v2.7.0",
        "historical_tag_sha" => "f2c91e40a4338c85a735142192f2278b939cd67c"
      },
      "schema_version" => 1,
      "states" => %{
        "authorization" => "unauthorized",
        "capture" => "inactive",
        "publication" => "not_started"
      },
      "status" => "inactive"
    }
  end
end
