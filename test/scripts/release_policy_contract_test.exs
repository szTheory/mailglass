defmodule Mailglass.Scripts.ReleasePolicyContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @expected_tags Path.join(@repo_root, "scripts/release_policy_expected_tags.sh")
  @validate_target Path.join(@repo_root, "scripts/release_policy_validate_target.sh")
  @release_please Path.join(@repo_root, ".github/workflows/release-please.yml")
  @publish Path.join(@repo_root, ".github/workflows/publish-hex.yml")

  test "active target deterministically selects only its owned release tags" do
    in_tmp(fn dir ->
      manifest = write_json(dir, "manifest.json", %{"." => "9.9.9", "mailglass_inbound" => "8.8.8"})

      target =
        write_json(dir, "target.json", %{
          "status" => "active",
          "release_packages" => ["mailglass", "mailglass_admin"],
          "packages" => %{
            "mailglass" => "2.4.0",
            "mailglass_admin" => "2.4.0",
            "mailglass_inbound" => "2.1.1"
          }
        })

      assert {"mailglass-v2.4.0\nmailglass_admin-v2.4.0\n", 0} =
               run(@expected_tags, [manifest, target])
    end)
  end

  test "manifest fallback is deterministic and invalid release inputs fail closed" do
    in_tmp(fn dir ->
      manifest = write_json(dir, "manifest.json", %{"." => "1.2.3", "mailglass_inbound" => "4.5.6"})
      assert {"mailglass-v1.2.3\nmailglass_inbound-v4.5.6\n", 0} = run(@expected_tags, [manifest])

      for target <- [
            %{"status" => "active", "release_packages" => [], "packages" => %{}},
            %{"status" => "active", "release_packages" => ["unknown"], "packages" => %{}}
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

  test "target validation accepts only source-matching linked core/admin tags" do
    in_tmp(fn dir ->
      File.mkdir_p!(Path.join(dir, "mailglass_admin"))
      File.mkdir_p!(Path.join(dir, "mailglass_inbound"))
      File.write!(Path.join(dir, "mix.exs"), "  @version \"2.4.0\"\n")
      File.write!(Path.join(dir, "mailglass_admin/mix.exs"), "  @version \"2.4.0\"\n")
      File.write!(Path.join(dir, "mailglass_inbound/mix.exs"), "  @version \"2.1.1\"\n")

      target =
        write_json(dir, "target.json", %{
          "status" => "active",
          "packages" => %{
            "mailglass" => "2.4.0",
            "mailglass_admin" => "2.4.0",
            "mailglass_inbound" => "2.1.1"
          }
        })

      for tag <- ["mailglass-v2.4.0", "mailglass_admin-v2.4.0"] do
        assert {output, 0} = run(@validate_target, [target, tag, dir])
        assert output =~ "active=true\ncore=2.4.0\nadmin=2.4.0\ninbound=2.1.1\n"
      end

      assert {output, status} = run(@validate_target, [target, "mailglass_inbound-v2.1.1", dir])
      assert status != 0
      assert output =~ "not an authorized linked release tag"

      File.write!(Path.join(dir, "mailglass_inbound/mix.exs"), "  @version \"2.1.0\"\n")
      assert {output, status} = run(@validate_target, [target, "mailglass-v2.4.0", dir])
      assert status != 0
      assert output =~ "Release target mismatch"
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
    end

    broken =
      String.replace(release, "scripts/release_policy_expected_tags.sh", "true", global: true)

    refute broken =~ "scripts/release_policy_expected_tags.sh"
  end

  defp run(script, args), do: System.cmd("bash", [script | args], stderr_to_stdout: true)

  defp write_json(dir, name, value) do
    path = Path.join(dir, name)
    File.write!(path, Jason.encode!(value))
    path
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
end
