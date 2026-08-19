defmodule Mailglass.Scripts.WorkflowHardeningContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @workflow_paths Path.wildcard(Path.join(@repo_root, ".github/workflows/*.yml"))
  @postgres_image "postgres:16-alpine@sha256:cf78e76683b9ca8c5733cbbdce6c9262b45b6767934dd0a95e671f9a0fc20685"
  @elixir_image "hexpm/elixir:1.18.4-erlang-27.3.4.13-debian-bookworm-20260623-slim@sha256:ca09419f742ec4040ccb4d9949324f73d3d2c364cacad56686d68d6327eb45f2"
  @job_write_permissions %{
    "gate-self-test.yml" => %{"self-test" => ["contents", "pull-requests"]},
    "release-please.yml" => %{"release-please" => ["contents", "pull-requests"]},
    "publish-hex.yml" => %{"gate-ci-green" => ["actions"]},
    "provider-live.yml" => %{"notify_provider_live_failure" => ["issues"]},
    "post-publish-smoke.yml" => %{
      "notify-on-failure" => ["issues"],
      "close-publish-smoke-tracker-on-success" => ["issues"]
    }
  }

  test "every workflow job has one bounded explicit timeout and mutations fail loud" do
    for path <- @workflow_paths, {job, block} <- job_blocks(File.read!(path)) do
      assert_timeout!(path, job, block)
    end

    path = Path.join(@repo_root, ".github/workflows/actionlint.yml")
    source = File.read!(path)
    broken = String.replace(source, ~r/^    timeout-minutes: \d+\n/m, "", global: false)
    [{job, block} | _] = job_blocks(broken)

    assert_raise ExUnit.AssertionError, fn -> assert_timeout!(path, job, block) end
  end

  test "workflow defaults are read-only and writes exist only on approved jobs" do
    for path <- @workflow_paths do
      source = File.read!(path)
      assert readonly_default?(source), "#{path} grants workflow-wide write permission"

      approved = Map.get(@job_write_permissions, Path.basename(path), %{})

      for {job, block} <- job_blocks(source) do
        writes =
          Regex.scan(~r/^      ([a-z-]+): write$/m, block, capture: :all_but_first)
          |> List.flatten()

        assert Enum.sort(writes) == Enum.sort(Map.get(approved, job, [])),
               "#{Path.basename(path)} job #{job} write permissions drifted"
      end
    end

    source = File.read!(Path.join(@repo_root, ".github/workflows/actionlint.yml"))

    globally_writable =
      String.replace(source, "  contents: read", "  contents: write", global: false)

    refute readonly_default?(globally_writable)
  end

  test "all Postgres services and repository Dockerfiles use approved immutable inputs" do
    workflow_text = Enum.map_join(@workflow_paths, "\n", &File.read!/1)

    images =
      Regex.scan(~r/^        image: (postgres:\S+)$/m, workflow_text, capture: :all_but_first)
      |> List.flatten()

    assert images != []
    assert immutable_postgres?(workflow_text)

    refute immutable_postgres?(
             String.replace(workflow_text, @postgres_image, "postgres:16-alpine", global: false)
           )

    for dockerfile <- ["dev/toolchain/Dockerfile", "reference/demo_app/Dockerfile"] do
      source = File.read!(Path.join(@repo_root, dockerfile))
      assert immutable_dockerfile?(source)
      refute source =~ ~r/^FROM [^\s@]+$/m
    end

    toolchain = File.read!(Path.join(@repo_root, "dev/toolchain/Dockerfile"))

    refute immutable_dockerfile?(
             String.replace(
               toolchain,
               "@sha256:ca09419f742ec4040ccb4d9949324f73d3d2c364cacad56686d68d6327eb45f2",
               ""
             )
           )

    assert File.read!(Path.join(@repo_root, "dev/toolchain/Dockerfile")) =~
             ~r/apt-get install .*\bjq\b/
  end

  test "Dependabot covers every supported dependency ecosystem including both Docker roots" do
    source = File.read!(Path.join(@repo_root, ".github/dependabot.yml"))

    for {ecosystem, directory} <- [
          {"mix", "/"},
          {"mix", "/mailglass_admin"},
          {"mix", "/mailglass_inbound"},
          {"github-actions", "/"},
          {"docker", "/dev/toolchain"},
          {"docker", "/reference/demo_app"}
        ] do
      assert dependabot_entry?(source, ecosystem, directory)
    end

    without_toolchain =
      String.replace(source, "    directory: \"/dev/toolchain\"\n", "", global: false)

    refute dependabot_entry?(without_toolchain, "docker", "/dev/toolchain")
  end

  test "Docker toolchain pin exactly matches the supported patch pair" do
    versions = File.read!(Path.join(@repo_root, ".tool-versions"))
    elixir = Regex.run(~r/^elixir (\S+)$/m, versions, capture: :all_but_first) |> hd()
    otp = Regex.run(~r/^erlang (\S+)$/m, versions, capture: :all_but_first) |> hd()

    assert toolchain_matches?(@elixir_image, elixir, otp)
    refute toolchain_matches?(@elixir_image, elixir, "27.3.4.12")

    assert File.read!(Path.join(@repo_root, "scripts/assert_gating_toolchain.sh")) =~
             "actual_otp=\"$(erl"
  end

  defp assert_timeout!(path, job, block) do
    values =
      Regex.scan(~r/^    timeout-minutes: (\d+)$/m, block, capture: :all_but_first)
      |> List.flatten()

    assert length(values) == 1, "#{Path.basename(path)} job #{job} needs exactly one timeout"
    timeout = values |> hd() |> String.to_integer()
    assert timeout in 1..360, "#{Path.basename(path)} job #{job} timeout is unbounded"
  end

  defp readonly_default?(source) do
    top = source |> String.split("\njobs:\n", parts: 2) |> hd()
    not Regex.match?(~r/^  [a-z-]+: write$/m, top)
  end

  defp immutable_postgres?(source) do
    images =
      Regex.scan(~r/^        image: (postgres:\S+)$/m, source, capture: :all_but_first)
      |> List.flatten()

    images != [] and Enum.uniq(images) == [@postgres_image]
  end

  defp immutable_dockerfile?(source), do: source =~ "FROM #{@elixir_image}\n"

  defp dependabot_entry?(source, ecosystem, directory) do
    source =~
      ~r/package-ecosystem: "#{Regex.escape(ecosystem)}"\n    directory: "#{Regex.escape(directory)}"/
  end

  defp toolchain_matches?(image, elixir, otp), do: image =~ "hexpm/elixir:#{elixir}-erlang-#{otp}-"

  defp job_blocks(source) do
    [_before, jobs] = String.split(source, "\njobs:\n", parts: 2)
    lines = String.split(jobs, "\n")

    starts =
      lines
      |> Enum.with_index()
      |> Enum.filter(fn {line, _} -> Regex.match?(~r/^  [A-Za-z0-9_-]+:$/, line) end)

    Enum.map(starts, fn {header, index} ->
      job = header |> String.trim() |> String.trim_trailing(":")

      block =
        lines
        |> Enum.drop(index)
        |> Enum.take_while(fn line ->
          line == header or not Regex.match?(~r/^  [A-Za-z0-9_-]+:$/, line)
        end)
        |> Enum.join("\n")

      {job, block}
    end)
  end
end
