#!/usr/bin/env elixir

# Deterministically derives release ownership from each package's own reachable
# tag. It deliberately does not calculate versions: Release Please remains the
# version authority; this script only proves that the declared target covers the
# exact changed package set.

defmodule Mailglass.ReleasePackageResolver do
  @packages [
    %{name: "mailglass", tag_prefix: "mailglass-v", paths: ["lib/", "priv/gettext/", "guides/"], files: ~w(mix.exs LICENSE README.md CHANGELOG.md MAINTAINING.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md)},
    %{name: "mailglass_admin", tag_prefix: "mailglass_admin-v", paths: ["mailglass_admin/"], files: []},
    %{name: "mailglass_inbound", tag_prefix: "mailglass_inbound-v", paths: ["mailglass_inbound/"], files: []}
  ]

  def run(arguments) do
    with {:ok, options} <- parse_options(arguments),
         {:ok, target} <- read_target(options.target),
         {:ok, bases} <- package_bases(options.repo),
         {:ok, selected} <- selected_packages(options.repo, bases),
         :ok <- validate_target(target, selected) do
      IO.puts(json(selected, bases))
    else
      {:error, message} ->
        IO.puts(:stderr, "release package resolver: #{message}")
        System.halt(1)
    end
  end

  defp parse_options(["--repo", repo, "--target", target]), do: {:ok, %{repo: repo, target: target}}
  defp parse_options(["--target", target, "--repo", repo]), do: {:ok, %{repo: repo, target: target}}
  defp parse_options(_), do: {:error, "usage: resolve_release_packages.exs --repo REPOSITORY --target RELEASE_TARGET_JSON"}

  defp read_target(path) do
    with {:ok, source} <- File.read(path),
         [_, status] <- Regex.run(~r/"status"\s*:\s*"([^"]+)"/, source),
         true <- status == "active" || {:error, "release target status must be active"},
         [_, list] <- Regex.run(~r/"release_packages"\s*:\s*\[([^\]]*)\]/s, source),
         packages <- Regex.scan(~r/"([^"]+)"/, list, capture: :all_but_first) |> List.flatten(),
         [_, package_block] <- Regex.run(~r/"packages"\s*:\s*\{([^}]*)\}/s, source),
         versions <- Regex.scan(~r/"([^"]+)"\s*:\s*"([^"]+)"/, package_block, capture: :all_but_first) |> Enum.map(&List.to_tuple/1) |> Map.new(),
         true <- Enum.all?(packages, &Map.has_key?(versions, &1)) || {:error, "release target has package without a version"} do
      {:ok, %{packages: packages, versions: versions}}
    else
      {:error, _} = error -> error
      _ -> {:error, "release target is not valid JSON with status, release_packages, and packages"}
    end
  end

  defp package_bases(repo) do
    Enum.reduce_while(@packages, {:ok, %{}}, fn package, {:ok, bases} ->
      case newest_tag(repo, package) do
        {:ok, tag} -> {:cont, {:ok, Map.put(bases, package.name, tag)}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp newest_tag(repo, package) do
    tags = git(repo, ["tag", "--list", "#{package.tag_prefix}*"]) |> lines()

    case Enum.sort_by(tags, &semver_key(String.replace_prefix(&1, package.tag_prefix, "")), :desc) do
      [] -> {:ok, nil}
      [tag | _] ->
        case git_status(repo, ["merge-base", "--is-ancestor", tag, "HEAD"]) do
          0 -> {:ok, tag}
          _ -> {:error, "latest #{package.name} tag #{tag} is not an ancestor of the candidate"}
        end
    end
  end

  defp selected_packages(repo, bases) do
    selected =
      @packages
      |> Enum.filter(fn package -> package_changed?(repo, package, Map.fetch!(bases, package.name)) end)
      |> Enum.map(& &1.name)

    # The core and admin packages are one public compatibility line. Inbound is
    # intentionally absent from this closure and can remain independently releasable.
    linked = if Enum.any?(selected, &(&1 in ["mailglass", "mailglass_admin"])), do: ["mailglass", "mailglass_admin" | selected], else: selected
    {:ok, Enum.uniq(linked) |> Enum.sort_by(&package_order/1)}
  end

  defp package_changed?(repo, package, nil), do: git(repo, ["ls-files"]) |> lines() |> Enum.any?(&owned?(package, &1))
  defp package_changed?(repo, package, base), do: git(repo, ["diff", "--name-only", "#{base}..HEAD"]) |> lines() |> Enum.any?(&owned?(package, &1))

  defp owned?(%{paths: paths, files: files}, path), do: path in files or Enum.any?(paths, &String.starts_with?(path, &1))

  defp validate_target(%{packages: target_packages, versions: versions}, selected) do
    actual = target_packages |> Enum.uniq() |> Enum.sort_by(&package_order/1)

    cond do
      actual != selected -> {:error, "release target package set mismatch: derived #{Enum.join(selected, ",")} but target declares #{Enum.join(actual, ",")}"}
      Enum.any?(selected, &(not valid_version?(Map.get(versions, &1)))) -> {:error, "release target has an invalid package version"}
      true -> :ok
    end
  end

  defp valid_version?(version), do: is_binary(version) and Regex.match?(~r/^\d+\.\d+\.\d+(?:[-.][0-9A-Za-z.-]+)?$/, version)
  defp package_order("mailglass"), do: 0
  defp package_order("mailglass_admin"), do: 1
  defp package_order("mailglass_inbound"), do: 2
  defp package_order(_), do: 99
  defp semver_key(version), do: version |> String.split(~r/[-.]/) |> Enum.map(&(Integer.parse(&1) |> case do {value, ""} -> value; _ -> -1 end))
  defp lines(output), do: output |> String.split("\n", trim: true) |> Enum.sort()
  defp git(repo, arguments), do: System.cmd("git", arguments, cd: repo, stderr_to_stdout: true) |> elem(0)
  defp git_status(repo, arguments), do: System.cmd("git", arguments, cd: repo, stderr_to_stdout: true) |> elem(1)

  defp json(selected, bases) do
    package_json = selected |> Enum.map(&"\"#{&1}\"") |> Enum.join(",")
    base_json = bases |> Enum.sort() |> Enum.map(fn {name, tag} -> "\"#{name}\":" <> if(tag, do: "\"#{tag}\"", else: "null") end) |> Enum.join(",")
    "{\"release_packages\":[#{package_json}],\"bases\":{#{base_json}}}"
  end
end

Mailglass.ReleasePackageResolver.run(System.argv())
