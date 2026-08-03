defmodule Mailglass.Scripts.ReleasePackageResolverTest do
  use ExUnit.Case, async: true

  @resolver Path.expand("../../scripts/resolve_release_packages.exs", __DIR__)

  test "selects only package-owned source and packaged documentation since each package tag" do
    with_repo(fn repo ->
      commit(repo, "initial package contents", %{
        "lib/mailglass.ex" => "defmodule Mailglass do end\n",
        "guides/getting-started.md" => "# Guide\n",
        "mailglass_admin/lib/mailglass_admin.ex" => "defmodule MailglassAdmin do end\n",
        "mailglass_inbound/lib/mailglass_inbound.ex" => "defmodule MailglassInbound do end\n"
      })

      tag(repo, "mailglass-v1.0.0")
      tag(repo, "mailglass_admin-v1.0.0")
      tag(repo, "mailglass_inbound-v1.0.0")
      commit(repo, "core guide", %{"guides/getting-started.md" => "# Updated guide\n"})

      assert selected(repo, ["mailglass", "mailglass_admin"]) == ["mailglass", "mailglass_admin"]
    end)
  end

  test "links core and admin for either public compatibility surface while inbound stays independent" do
    with_repo(fn repo ->
      seed_tagged_packages(repo)

      commit(repo, "admin public API", %{
        "mailglass_admin/lib/mailglass_admin/public.ex" => "defmodule Public do end\n"
      })

      assert selected(repo, ["mailglass", "mailglass_admin"]) == ["mailglass", "mailglass_admin"]
    end)

    with_repo(fn repo ->
      seed_tagged_packages(repo)

      commit(repo, "inbound API", %{
        "mailglass_inbound/lib/mailglass_inbound/parser.ex" => "defmodule Parser do end\n"
      })

      assert selected(repo, ["mailglass_inbound"]) == ["mailglass_inbound"]
    end)
  end

  test "ignores unrelated repository files and treats package first releases as selected" do
    with_repo(fn repo ->
      seed_tagged_packages(repo)
      commit(repo, "planning only", %{".planning/note.md" => "no package content\n"})
      assert selected(repo, []) == []
    end)

    with_repo(fn repo ->
      commit(repo, "first core release", %{"lib/mailglass.ex" => "defmodule Mailglass do end\n"})
      assert selected(repo, ["mailglass", "mailglass_admin"]) == ["mailglass", "mailglass_admin"]
    end)
  end

  test "fails closed when the newest package tag is not an ancestor of the candidate" do
    with_repo(fn repo ->
      seed_tagged_packages(repo)
      cmd!("git", ["checkout", "-b", "divergent"], cd: repo)
      commit(repo, "divergent core", %{"lib/divergent.ex" => "defmodule Divergent do end\n"})
      tag(repo, "mailglass-v9.9.9")
      cmd!("git", ["checkout", "main"], cd: repo)
      commit(repo, "candidate core", %{"lib/candidate.ex" => "defmodule Candidate do end\n"})

      {output, status} = resolve(repo, target(repo, ["mailglass", "mailglass_admin"]))
      assert status != 0
      assert output =~ "not an ancestor"
    end)
  end

  test "rejects release targets with omitted or mechanically included packages" do
    with_repo(fn repo ->
      seed_tagged_packages(repo)
      commit(repo, "inbound only", %{"mailglass_inbound/docs/guide.md" => "# Inbound\n"})

      {missing_output, missing_status} = resolve(repo, target(repo, []))
      assert missing_status != 0
      assert missing_output =~ "release target package set mismatch"

      {extra_output, extra_status} =
        resolve(repo, target(repo, ["mailglass", "mailglass_admin", "mailglass_inbound"]))

      assert extra_status != 0
      assert extra_output =~ "release target package set mismatch"
    end)
  end

  defp selected(repo, expected) do
    {output, 0} = resolve(repo, target(repo, expected))

    Regex.scan(~r/"release_packages":\[([^\]]*)\]/, output)
    |> List.first()
    |> Enum.at(1)
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim(&1, "\""))
  end

  defp resolve(repo, target_path) do
    System.cmd("elixir", [@resolver, "--repo", repo, "--target", target_path],
      stderr_to_stdout: true
    )
  end

  defp with_repo(fun) do
    repo =
      Path.join(
        System.tmp_dir!(),
        "mailglass-release-resolver-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(repo)
    cmd!("git", ["init", "-b", "main"], cd: repo)
    cmd!("git", ["config", "user.email", "resolver@example.test"], cd: repo)
    cmd!("git", ["config", "user.name", "Resolver Test"], cd: repo)

    try do
      fun.(repo)
    after
      File.rm_rf(repo)
    end
  end

  defp seed_tagged_packages(repo) do
    commit(repo, "initial package contents", %{
      "lib/mailglass.ex" => "defmodule Mailglass do end\n",
      "mailglass_admin/lib/mailglass_admin.ex" => "defmodule MailglassAdmin do end\n",
      "mailglass_inbound/lib/mailglass_inbound.ex" => "defmodule MailglassInbound do end\n"
    })

    tag(repo, "mailglass-v1.0.0")
    tag(repo, "mailglass_admin-v1.0.0")
    tag(repo, "mailglass_inbound-v1.0.0")
  end

  defp commit(repo, message, files) do
    Enum.each(files, fn {path, body} ->
      full_path = Path.join(repo, path)
      File.mkdir_p!(Path.dirname(full_path))
      File.write!(full_path, body)
    end)

    cmd!("git", ["add", "."], cd: repo)
    cmd!("git", ["commit", "-m", message], cd: repo)
  end

  defp tag(repo, name), do: cmd!("git", ["tag", name], cd: repo)

  defp cmd!(command, arguments, options) do
    case System.cmd(command, arguments, options ++ [stderr_to_stdout: true]) do
      {_output, 0} ->
        :ok

      {output, status} ->
        flunk("#{command} #{Enum.join(arguments, " ")} failed (#{status}): #{output}")
    end
  end

  defp target(repo, packages) do
    path = Path.join(repo, "release-target.json")

    File.write!(
      path,
      Jason.encode!(%{
        "status" => "active",
        "release_packages" => packages,
        "packages" => %{
          "mailglass" => "2.4.0",
          "mailglass_admin" => "2.4.0",
          "mailglass_inbound" => "2.1.1"
        }
      })
    )

    path
  end
end
