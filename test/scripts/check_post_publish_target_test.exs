defmodule Mailglass.Scripts.CheckPostPublishTargetTest do
  # Each test shells out to git against its own temp directory pair.
  use ExUnit.Case, async: false

  @moduledoc """
  Executes `scripts/check_post_publish_target.sh` for real, in both modes.

  Phase 166 (GREEN/CTRL, milestone v2.8 "Truthful Repo") added a `--baseline-mode`
  flag that bypasses the 64-hex `publishable_content.digest` requirement, because a
  closed-out ledger sets that digest to null by construction and the scheduled proof
  could otherwise never pass between releases.

  The only coverage that shipped with it was a substring match against the workflow
  YAML (`resolver =~ "baseline_mode=true"`), which passes whether or not the script
  behaves correctly — exactly the shape of vacuous green this milestone exists to
  eliminate (code review 166-REVIEW.md WR-01). These tests run the script.

  What must stay true:

    * baseline mode bypasses ONLY the digest check;
    * every guard that runs before the digest check — the exact-40-hex ref regex, the
      exact-SemVer-triple assertions, the linked core/admin equality, and the
      three-tag resolution — still runs and still rejects in baseline mode;
    * the live-dispatch path still hard-fails on a null digest, so the bypass is not
      reachable without the flag.
  """

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/check_post_publish_target.sh")

  @core "2.6.0"
  @admin "2.6.0"
  @inbound "2.3.0"

  describe "guards that precede the digest check still reject in baseline mode" do
    test "a ref that is not exactly 40 lowercase hex characters is rejected" do
      in_fixture(fn fixture ->
        for bad_ref <- [
              String.duplicate("a", 39),
              String.duplicate("a", 41),
              String.upcase(String.duplicate("a", 40)),
              "not-a-sha"
            ] do
          {output, status} = run_baseline(fixture, target_ref: bad_ref)

          assert status == 1, "expected #{inspect(bad_ref)} to be rejected in baseline mode"
          assert output =~ "target_ref must be an exact 40-character lowercase commit SHA"
        end
      end)
    end

    test "a version that is not an exact stable SemVer triple is rejected" do
      in_fixture(fn fixture ->
        for bad_version <- ["2.6", "2.6.0.1", "v2.6.0", "2.6.0-rc.1", "~> 2.6"] do
          {output, status} = run_baseline(fixture, core: bad_version, admin: bad_version)

          assert status == 1, "expected #{inspect(bad_version)} to be rejected in baseline mode"
          assert output =~ "candidate version is not exact stable SemVer"
        end
      end)
    end

    test "diverging linked core/admin versions are rejected" do
      in_fixture(fn fixture ->
        {output, status} = run_baseline(fixture, admin: "2.5.0")

        assert status == 1
        assert output =~ "linked core/admin versions diverge"
      end)
    end

    test "a tag that does not resolve to target_ref is rejected" do
      in_fixture(fn fixture ->
        # Move one of the three required tags onto a second, unrelated commit.
        File.write!(Path.join(fixture.origin, "drift.txt"), "drift\n")
        git!(fixture.origin, ["add", "drift.txt"])
        git!(fixture.origin, ["commit", "-m", "drift"])
        git!(fixture.origin, ["tag", "-f", "mailglass_inbound-v#{@inbound}"])

        {output, status} = run_baseline(fixture)

        assert status == 1
        assert output =~ "does not resolve to target_ref"
      end)
    end

    test "a missing required tag is rejected" do
      in_fixture(fn fixture ->
        git!(fixture.origin, ["tag", "-d", "mailglass_admin-v#{@admin}"])

        {output, status} = run_baseline(fixture)

        assert status == 1
        assert output =~ "required tag is unavailable"
      end)
    end
  end

  describe "the digest bypass is scoped to baseline mode" do
    test "baseline mode accepts a null digest and says so in its output" do
      in_fixture(fn fixture ->
        {output, status} = run_baseline(fixture)

        assert status == 0, "baseline mode must be able to pass against a closed-out ledger"
        assert output =~ "post-publish target verified"
        assert output =~ "ref=#{fixture.sha}"
        assert output =~ "tags=3"
        assert output =~ "baseline mode"
      end)
    end

    test "the live-dispatch path still hard-fails on the same null digest" do
      in_fixture(fn fixture ->
        {output, status} = run(fixture, [])

        assert status == 1,
               "without --baseline-mode the null digest must still be a hard failure, " <>
                 "otherwise the bypass is reachable on the live path"

        assert output =~ "authorized content digest is missing or malformed"
      end)
    end

    test "the live-dispatch path also rejects a malformed non-null digest" do
      in_fixture(%{"digest" => String.duplicate("z", 64)}, fn fixture ->
        {output, status} = run(fixture, [])

        assert status == 1
        assert output =~ "authorized content digest is missing or malformed"
      end)
    end
  end

  test "a missing required argument exits 64 in either mode" do
    in_fixture(fn fixture ->
      for extra <- [[], ["--baseline-mode"]] do
        {_output, status} =
          System.cmd(
            "bash",
            [@script, "--repo", fixture.repo, "--target", fixture.target] ++ extra,
            stderr_to_stdout: true
          )

        assert status == 64
      end
    end)
  end

  defp run_baseline(fixture, overrides \\ []) do
    run(fixture, ["--baseline-mode"], overrides)
  end

  defp run(fixture, extra, overrides \\ []) do
    args = [
      "--repo",
      fixture.repo,
      "--target",
      fixture.target,
      "--target-ref",
      Keyword.get(overrides, :target_ref, fixture.sha),
      "--core",
      Keyword.get(overrides, :core, @core),
      "--admin",
      Keyword.get(overrides, :admin, @admin),
      "--inbound",
      Keyword.get(overrides, :inbound, @inbound)
    ]

    System.cmd("bash", [@script | args] ++ extra, stderr_to_stdout: true)
  end

  # Builds an `origin` repository carrying the three required tags plus a clone of
  # it to act as the workflow's control checkout, so the script's real
  # `git fetch origin +refs/tags/...` runs without any network access.
  defp in_fixture(publishable_content \\ %{"digest" => nil}, fun) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "check-post-publish-target-#{System.unique_integer([:positive])}"
      )

    origin = Path.join(dir, "origin")
    repo = Path.join(dir, "repo")
    File.mkdir_p!(origin)

    try do
      git!(origin, ["init", "--initial-branch", "main"])
      git!(origin, ["config", "user.email", "test@example.com"])
      git!(origin, ["config", "user.name", "test"])
      File.write!(Path.join(origin, "README.md"), "baseline\n")
      git!(origin, ["add", "README.md"])
      git!(origin, ["commit", "-m", "baseline"])

      for tag <- [
            "mailglass-v#{@core}",
            "mailglass_admin-v#{@admin}",
            "mailglass_inbound-v#{@inbound}"
          ] do
        git!(origin, ["tag", tag])
      end

      {sha, 0} = System.cmd("git", ["-C", origin, "rev-parse", "HEAD"])
      sha = String.trim(sha)

      assert {_output, 0} = System.cmd("git", ["clone", origin, repo], stderr_to_stdout: true)

      target = Path.join(dir, "release-target.json")

      File.write!(
        target,
        Jason.encode!(%{
          "schema_version" => 1,
          "status" => "inactive",
          "publishable_content" => publishable_content
        })
      )

      fun.(%{dir: dir, origin: origin, repo: repo, target: target, sha: sha})
    after
      File.rm_rf!(dir)
    end
  end

  defp git!(dir, args) do
    assert {_output, 0} = System.cmd("git", ["-C", dir | args], stderr_to_stdout: true)
  end
end
