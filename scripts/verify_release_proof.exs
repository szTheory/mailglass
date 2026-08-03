#!/usr/bin/env elixir

# Verifies the release ledger against one protected publish run. The run ID is
# deliberately read from the ledger: callers cannot substitute a different green
# run as evidence for a candidate.
defmodule Mailglass.ReleaseProofVerifier do
  @workflow_path ".github/workflows/publish-hex.yml"
  @workflow_name "publish-hex"
  @environment "hex-publish"

  def run(argv) do
    with {:ok, options} <- options(argv),
         {:ok, ledger} <- read_ledger(options.ledger),
         {:ok, target} <- read_json(".planning/release-target.json"),
         {:ok, evidence} <- evidence(ledger, options),
         :ok <- validate(ledger, target, evidence, options.stage) do
      IO.puts("release proof verified for #{ledger["candidate"]["tag"]}")
    else
      {:error, message} ->
        IO.puts(:stderr, "release proof verification failed: #{message}")
        System.halt(1)
    end
  end

  defp options(["--" | argv]), do: options(argv)

  defp options(argv) do
    case argv do
      ["--ledger", ledger, "--fixture", fixture, "--stage", stage] ->
        {:ok, %{ledger: ledger, fixture: fixture, stage: stage}}

      ["--ledger", ledger, "--stage", stage] ->
        {:ok, %{ledger: ledger, fixture: nil, stage: stage}}

      _ ->
        {:error,
         "usage: verify_release_proof.exs --ledger LEDGER [--fixture EVIDENCE] --stage prepublication|complete"}
    end
  end

  defp read_ledger(path) do
    with {:ok, source} <- File.read(path),
         json <-
           if(String.starts_with?(String.trim_leading(source), "{"),
             do: source,
             else: fenced_ledger(source)
           ),
         {:ok, decoded} <- Jason.decode(json) do
      {:ok, decoded}
    else
      _ -> {:error, "ledger must contain one valid release-proof JSON document"}
    end
  end

  defp fenced_ledger(source) do
    case Regex.run(~r/```release-proof\s*\n(.*?)\n```/s, source) do
      [_, json] -> json
      _ -> ""
    end
  end

  defp read_json(path) do
    with {:ok, source} <- File.read(path),
         {:ok, decoded} <- Jason.decode(source),
         do: {:ok, decoded}
  end

  defp evidence(_ledger, %{fixture: fixture}) when is_binary(fixture), do: read_json(fixture)

  defp evidence(ledger, %{fixture: nil}) do
    run_id = get_in(ledger, ["publication", "run_id"])
    run_url = get_in(ledger, ["publication", "run_url"])

    if is_integer(run_id) and is_binary(run_url) and
         String.contains?(run_url, "/actions/runs/#{run_id}") do
      # `gh api` uses the authenticated GitHub CLI but never mutates remote state.
      case System.cmd("gh", ["api", "repos/{owner}/{repo}/actions/runs/#{run_id}"],
             stderr_to_stdout: true
           ) do
        {body, 0} ->
          Jason.decode(body)

        {body, _} ->
          {:error, "could not read ledger-bound GitHub run #{run_id}: #{String.trim(body)}"}
      end
    else
      {:error, "ledger publication.run_id and publication.run_url are required"}
    end
  end

  defp validate(ledger, target, evidence, stage) do
    candidate = ledger["candidate"] || %{}
    publication = ledger["publication"] || %{}
    selected = ledger["release_packages"]
    versions = ledger["target_versions"]
    checksums = ledger["archive_checksums"]

    with :ok <- exact("ledger workflow path", publication["workflow_path"], @workflow_path),
         :ok <- exact("ledger workflow name", publication["workflow_name"], @workflow_name),
         :ok <- exact("ledger environment", publication["environment"], @environment),
         :ok <-
           exact("workflow path", evidence["workflow_path"] || evidence["path"], @workflow_path),
         :ok <-
           exact("workflow name", evidence["workflow_name"] || evidence["name"], @workflow_name),
         :ok <- exact("candidate SHA", evidence["head_sha"], candidate["sha"]),
         :ok <- exact("tag dereference", evidence["tag_sha"], candidate["sha"]),
         :ok <- protected?(evidence),
         :ok <- exact_set("resolver-selected packages", selected, target["release_packages"]),
         :ok <- exact_map("target versions", versions, target["packages"]),
         :ok <- exact_set("publish jobs", evidence["publish_jobs"], publish_jobs(selected)),
         :ok <- exact_artifacts(evidence["published_packages"], selected, versions, checksums),
         :ok <- stage_valid?(stage) do
      :ok
    end
  end

  defp protected?(evidence) do
    if evidence["environment"] == @environment and evidence["environment_approved"] == true,
      do: :ok,
      else: {:error, "hex-publish environment approval is required"}
  end

  defp exact_artifacts(packages, selected, versions, checksums) when is_list(packages) do
    actual = Map.new(packages, fn package -> {package["name"], package} end)

    with :ok <- exact_set("published package set", Map.keys(actual), selected),
         :ok <-
           Enum.reduce_while(selected, :ok, fn name, :ok ->
             package = actual[name] || %{}

             if package["version"] == versions[name] and package["checksum"] == checksums[name] and
                  valid_checksum?(package["checksum"]),
                do: {:cont, :ok},
                else: {:halt, {:error, "artifact mismatch for #{name}"}}
           end) do
      :ok
    end
  end

  defp exact_artifacts(_, _, _, _), do: {:error, "published package artifact evidence is required"}

  defp publish_jobs(selected) do
    Enum.map(selected, fn
      "mailglass" -> "publish-core"
      package -> "publish-#{String.replace_prefix(package, "mailglass_", "")}"
    end)
  end

  defp exact(_label, actual, expected) when actual == expected and not is_nil(expected), do: :ok
  defp exact(label, _actual, _expected), do: {:error, "#{label} mismatch"}

  defp exact_set(label, actual, expected) when is_list(actual) and is_list(expected) do
    if Enum.sort(actual) == Enum.sort(expected), do: :ok, else: {:error, "#{label} mismatch"}
  end

  defp exact_set(label, _, _), do: {:error, "#{label} mismatch"}
  defp exact_map(_label, actual, expected) when actual == expected and is_map(actual), do: :ok
  defp exact_map(label, _, _), do: {:error, "#{label} mismatch"}
  defp valid_checksum?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/i, value)
  defp stage_valid?(stage) when stage in ["prepublication", "complete"], do: :ok
  defp stage_valid?(_), do: {:error, "stage must be prepublication or complete"}
end

Mailglass.ReleaseProofVerifier.run(System.argv())
