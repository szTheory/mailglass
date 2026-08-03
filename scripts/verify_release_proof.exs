#!/usr/bin/env elixir

defmodule Mailglass.ReleaseProofVerifier do
  @workflow_path ".github/workflows/publish-hex.yml"
  @workflow_name "publish-hex"
  @environment "hex-publish"
  @ci_path ".github/workflows/ci.yml"
  @advisory_path ".github/workflows/advisory-matrix.yml"
  @advisory_jobs [
    "Core Full Suite (Elixir 1.18 / OTP 27 / schema public)",
    "Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)"
  ]
  @pr_only_required_checks ["Guard Release Trigger"]

  def run(argv) do
    with {:ok, options} <- options(argv),
         {:ok, ledger} <- read_ledger(options.ledger),
         {:ok, target} <- read_json(".planning/release-target.json"),
         {:ok, evidence} <- evidence(ledger, target, options),
         :ok <- validate(ledger, target, evidence, options.stage) do
      IO.puts("release proof verified for #{get_in(ledger, ["candidate", "tag"])}")
    else
      {:error, message} ->
        IO.puts(:stderr, "release proof verification failed: #{message}")
        System.halt(1)
    end
  end

  defp options(["--" | argv]), do: options(argv)

  defp options(argv) do
    case argv do
      ["--ledger", ledger, "--fixture", fixture, "--stage", stage]
      when stage in ["prepublication", "complete"] ->
        {:ok, %{ledger: ledger, fixture: fixture, stage: stage}}

      ["--ledger", ledger, "--stage", stage] when stage in ["prepublication", "complete"] ->
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

  defp evidence(_ledger, _target, %{fixture: fixture}) when is_binary(fixture),
    do: read_json(fixture)

  defp evidence(ledger, target, %{fixture: nil, stage: "prepublication"}) do
    with {:ok, common} <- live_common(ledger, target, :prepublication),
         {:ok, ci} <- live_candidate_ci(ledger, common["candidate_head"]),
         {:ok, releases} <- live_hex_releases(target, false) do
      {:ok, Map.merge(common, Map.merge(ci, %{"hex_releases" => releases}))}
    end
  end

  defp evidence(ledger, target, %{fixture: nil, stage: "complete"}) do
    with {:ok, common} <- live_common(ledger, target, :complete),
         {:ok, publication} <- live_publication(ledger, target),
         {:ok, releases} <- live_hex_releases(target, true) do
      {:ok, Map.merge(common, Map.merge(publication, %{"hex_releases" => releases}))}
    end
  end

  defp live_common(ledger, target, stage) do
    candidate = ledger["candidate"] || %{}
    tag = candidate["tag"]
    sha = candidate["sha"]

    with {:ok, candidate_head} <- candidate_head(stage, sha),
         {:ok, tag_sha} <- tag_sha(stage, tag),
         {:ok, resolver} <- resolver_evidence(target),
         {:ok, checksums} <- archive_evidence(stage, target),
         {:ok, environment} <- environment_evidence(),
         {:ok, source_versions} <- source_versions() do
      {:ok,
       %{
         "candidate_head" => candidate_head,
         "tag_sha" => tag_sha,
         "resolver_packages" => resolver["release_packages"],
         "resolver_bases" => resolver["bases"],
         "archive_checksums" => checksums,
         "environment_protection" => environment,
         "source_versions" => source_versions
       }}
    end
  end

  defp candidate_head(:prepublication, _sha), do: git(["rev-parse", "HEAD"])
  defp candidate_head(:complete, sha) when is_binary(sha), do: {:ok, sha}
  defp candidate_head(:complete, _sha), do: {:error, "ledger candidate SHA is required"}

  defp tag_sha(:prepublication, tag) when is_binary(tag),
    do: git(["rev-parse", "--verify", "refs/tags/#{tag}^{commit}"])

  defp tag_sha(:complete, tag) when is_binary(tag), do: remote_tag_sha(tag)
  defp tag_sha(_, _), do: {:error, "ledger candidate tag is required"}

  defp remote_tag_sha(tag) do
    with {:ok, ref} <- gh_json("repos/{owner}/{repo}/git/ref/tags/#{tag}") do
      peel_tag(ref["object"], 0)
    end
  end

  defp peel_tag(%{"type" => "commit", "sha" => sha}, _depth), do: {:ok, sha}

  defp peel_tag(%{"type" => "tag", "sha" => sha}, depth) when depth < 5 do
    with {:ok, object} <- gh_json("repos/{owner}/{repo}/git/tags/#{sha}") do
      peel_tag(object["object"], depth + 1)
    end
  end

  defp peel_tag(_, _), do: {:error, "candidate tag does not dereference to a commit"}

  defp resolver_evidence(target) do
    temp = temp_dir!("mailglass-release-resolver")

    try do
      with :ok <- command_ok("git", ["clone", "--quiet", "--no-hardlinks", ".", temp]),
           :ok <- delete_target_tags(temp, target),
           {body, 0} <-
             System.cmd(
               "elixir",
               [
                 "scripts/resolve_release_packages.exs",
                 "--repo",
                 ".",
                 "--target",
                 ".planning/release-target.json"
               ],
               cd: temp,
               stderr_to_stdout: true
             ),
           {:ok, decoded} <- Jason.decode(String.trim(body)) do
        {:ok, decoded}
      else
        {body, status} when is_binary(body) and is_integer(status) ->
          {:error, "release resolver failed: #{String.trim(body)}"}

        {:error, _} = error ->
          error

        _ ->
          {:error, "release resolver returned invalid evidence"}
      end
    after
      File.rm_rf(temp)
    end
  end

  defp delete_target_tags(repo, target) do
    tags =
      Enum.map(target["release_packages"] || [], fn
        "mailglass" -> "mailglass-v#{get_in(target, ["packages", "mailglass"])}"
        package -> "#{package}-v#{get_in(target, ["packages", package])}"
      end)

    Enum.each(tags, fn tag ->
      System.cmd("git", ["tag", "--delete", tag], cd: repo, stderr_to_stdout: true)
    end)

    :ok
  end

  defp archive_evidence(:complete, _target), do: {:ok, %{}}

  defp archive_evidence(:prepublication, target) do
    temp = temp_dir!("mailglass-release-archives")

    try do
      Enum.reduce_while(target["release_packages"] || [], {:ok, %{}}, fn package, {:ok, acc} ->
        version = get_in(target, ["packages", package])
        output = Path.join(temp, "#{package}-#{version}.tar")
        cwd = if package == "mailglass", do: File.cwd!(), else: Path.join(File.cwd!(), package)
        env = if package == "mailglass", do: [], else: [{"MIX_PUBLISH", "true"}]

        case System.cmd("mix", ["hex.build", "--output", output],
               cd: cwd,
               env: env,
               stderr_to_stdout: true
             ) do
          {_body, 0} -> {:cont, {:ok, Map.put(acc, package, sha256!(output))}}
          {body, _} -> {:halt, {:error, "could not build #{package} archive: #{String.trim(body)}"}}
        end
      end)
    after
      File.rm_rf(temp)
    end
  end

  defp source_versions do
    files = %{
      "mailglass" => "mix.exs",
      "mailglass_admin" => "mailglass_admin/mix.exs",
      "mailglass_inbound" => "mailglass_inbound/mix.exs"
    }

    Enum.reduce_while(files, {:ok, %{}}, fn {package, path}, {:ok, acc} ->
      case Regex.run(~r/@version\s+"([^"]+)"/, File.read!(path)) do
        [_, version] -> {:cont, {:ok, Map.put(acc, package, version)}}
        _ -> {:halt, {:error, "could not read source version for #{package}"}}
      end
    end)
  end

  defp environment_evidence do
    with {:ok, environment} <- gh_json("repos/{owner}/{repo}/environments/#{@environment}") do
      reviewer_rule =
        Enum.find(environment["protection_rules"] || [], &(&1["type"] == "required_reviewers")) ||
          %{}

      {:ok,
       %{
         "name" => environment["name"],
         "id" => environment["id"],
         "can_admins_bypass" => environment["can_admins_bypass"],
         "prevent_self_review" => reviewer_rule["prevent_self_review"],
         "required_reviewers" =>
           Enum.map(reviewer_rule["reviewers"] || [], fn reviewer ->
             get_in(reviewer, ["reviewer", "login"]) || get_in(reviewer, ["reviewer", "slug"])
           end)
           |> Enum.reject(&is_nil/1)
           |> Enum.sort()
       }}
    end
  end

  defp live_candidate_ci(ledger, sha) do
    prepublication = ledger["prepublication"] || %{}

    with {:ok, ci} <- ledger_run(prepublication["ci"], @ci_path, sha),
         {:ok, advisory} <- ledger_run(prepublication["advisory"], @advisory_path, sha),
         {:ok, protection} <-
           gh_json("repos/{owner}/{repo}/branches/main/protection/required_status_checks"),
         {:ok, checks} <-
           gh_json("repos/{owner}/{repo}/commits/#{sha}/check-runs?filter=latest&per_page=100"),
         {:ok, ci_jobs} <- run_jobs(ci["id"]),
         {:ok, advisory_jobs} <- run_jobs(advisory["id"]) do
      {:ok,
       %{
         "ci_runs" => %{
           "ci" => Map.put(ci, "jobs", ci_jobs),
           "advisory" => Map.put(advisory, "jobs", advisory_jobs)
         },
         "branch_protection_contexts" => protection["contexts"] || [],
         "required_checks" => checks["check_runs"] || []
       }}
    end
  end

  defp ledger_run(%{"run_id" => id, "run_url" => url}, expected_path, sha)
       when is_integer(id) and is_binary(url) do
    with {:ok, run} <- gh_json("repos/{owner}/{repo}/actions/runs/#{id}"),
         true <- run_url_matches?(run, url) || {:error, "ledger CI run URL mismatch"},
         true <-
           workflow_path(run["path"]) == expected_path ||
             {:error, "ledger CI workflow path mismatch"},
         true <- run["head_sha"] == sha || {:error, "ledger CI candidate SHA mismatch"},
         true <-
           (run["status"] == "completed" and run["conclusion"] == "success") ||
             {:error, "ledger CI run is not green"} do
      {:ok, run}
    else
      {:error, _} = error -> error
      _ -> {:error, "ledger CI run evidence is invalid"}
    end
  end

  defp ledger_run(_, _, _), do: {:error, "ledger prepublication CI run IDs and URLs are required"}

  defp live_publication(ledger, _target) do
    publication = ledger["publication"] || %{}
    run_id = publication["run_id"]
    run_url = publication["run_url"]

    with true <-
           (is_integer(run_id) and is_binary(run_url)) ||
             {:error, "ledger publication run is required"},
         {:ok, run} <- gh_json("repos/{owner}/{repo}/actions/runs/#{run_id}"),
         {:ok, jobs} <- run_jobs(run_id),
         {:ok, approvals} <- gh_json("repos/{owner}/{repo}/actions/runs/#{run_id}/approvals"),
         {:ok, deployments} <- deployment_evidence(run, jobs),
         {:ok, artifact} <- release_artifact(run_id) do
      {:ok,
       %{
         "publish_run" => run,
         "publish_jobs" => jobs,
         "approvals" => approvals,
         "deployments" => deployments,
         "release_artifact" => artifact
       }}
    else
      {:error, _} = error -> error
      _ -> {:error, "ledger publication evidence is invalid"}
    end
  end

  defp run_jobs(run_id) do
    with {:ok, body} <-
           gh_json("repos/{owner}/{repo}/actions/runs/#{run_id}/jobs?filter=latest&per_page=100") do
      {:ok, body["jobs"] || []}
    end
  end

  defp deployment_evidence(run, jobs) do
    with {:ok, deployments} <-
           gh_json(
             "repos/{owner}/{repo}/deployments?sha=#{run["head_sha"]}&environment=#{@environment}&per_page=100"
           ) do
      deployments
      |> Enum.reduce_while({:ok, []}, fn deployment, {:ok, acc} ->
        case gh_json("repos/{owner}/{repo}/deployments/#{deployment["id"]}/statuses") do
          {:ok, statuses} ->
            matching_job =
              Enum.find(jobs, fn job ->
                Enum.any?(statuses, &String.contains?(&1["log_url"] || "", "/job/#{job["id"]}"))
              end)

            evidence = %{
              "id" => deployment["id"],
              "sha" => deployment["sha"],
              "ref" => deployment["ref"],
              "environment" => deployment["environment"],
              "job_id" => matching_job && matching_job["id"],
              "states" => Enum.map(statuses, & &1["state"])
            }

            {:cont, {:ok, [evidence | acc]}}

          {:error, _} = error ->
            {:halt, error}
        end
      end)
    end
  end

  defp release_artifact(run_id) do
    name = "phase-153-release-proof-#{run_id}"

    with {:ok, listing} <-
           gh_json(
             "repos/{owner}/{repo}/actions/runs/#{run_id}/artifacts?name=#{name}&per_page=100"
           ),
         [artifact] <-
           Enum.filter(listing["artifacts"] || [], &(&1["name"] == name and not &1["expired"])),
         {:ok, decoded} <- download_release_artifact(run_id, name, artifact["digest"]) do
      {:ok, decoded}
    else
      [] ->
        {:error, "ledger-bound Phase 153 artifact is missing or expired"}

      [_ | _] ->
        {:error, "ledger-bound Phase 153 artifact is ambiguous"}

      {:error, _} = error ->
        error

      _ ->
        {:error, "ledger-bound Phase 153 artifact is invalid"}
    end
  end

  defp download_release_artifact(run_id, name, digest) do
    temp = temp_dir!("mailglass-release-artifact")

    try do
      case System.cmd(
             "gh",
             ["run", "download", Integer.to_string(run_id), "--name", name, "--dir", temp],
             stderr_to_stdout: true
           ) do
        {_body, 0} ->
          with {:ok, decoded} <- read_json(Path.join(temp, "phase-153.json")) do
            {:ok, Map.put(decoded, "artifact_digest", digest)}
          end

        {body, _status} ->
          {:error, "could not download ledger-bound Phase 153 artifact: #{String.trim(body)}"}
      end
    after
      File.rm_rf(temp)
    end
  end

  defp live_hex_releases(target, require_present?) do
    Enum.reduce_while(target["release_packages"] || [], {:ok, %{}}, fn package, {:ok, acc} ->
      version = get_in(target, ["packages", package])
      url = "https://hex.pm/api/packages/#{package}/releases/#{version}"

      case http_get(url) do
        {:ok, 200, body} when require_present? ->
          with {:ok, release} <- Jason.decode(body),
               {:ok, 200, tarball} <-
                 http_get("https://repo.hex.pm/tarballs/#{package}-#{version}.tar") do
            value = %{
              "version" => release["version"],
              "checksum" => release["checksum"],
              "tarball_checksum" => sha256(tarball),
              "has_docs" => release["has_docs"],
              "retirement" => release["retirement"]
            }

            {:cont, {:ok, Map.put(acc, package, value)}}
          else
            _ -> {:halt, {:error, "could not read exact Hex artifact for #{package} #{version}"}}
          end

        {:ok, 404, _body} when not require_present? ->
          {:cont, {:ok, Map.put(acc, package, nil)}}

        {:ok, 200, _body} when not require_present? ->
          {:halt, {:error, "target version is already occupied on Hex: #{package} #{version}"}}

        {:ok, 404, _body} when require_present? ->
          {:halt, {:error, "target version is missing from Hex: #{package} #{version}"}}

        {:ok, status, _body} ->
          {:halt, {:error, "Hex returned HTTP #{status} for #{package} #{version}"}}

        {:error, message} ->
          {:halt, {:error, message}}
      end
    end)
  end

  defp validate(ledger, target, evidence, "prepublication") do
    with :ok <- common_valid?(ledger, target, evidence),
         :ok <-
           exact_map(
             "candidate archive checksums",
             evidence["archive_checksums"],
             ledger["archive_checksums"]
           ),
         :ok <- versions_unoccupied?(evidence["hex_releases"], ledger["release_packages"]),
         :ok <- prepublication_ci_valid?(ledger, evidence) do
      :ok
    end
  end

  defp validate(ledger, target, evidence, "complete") do
    with :ok <- common_valid?(ledger, target, evidence),
         :ok <- publication_valid?(ledger, evidence),
         :ok <- exact_hex_valid?(ledger, evidence["hex_releases"]) do
      :ok
    end
  end

  defp common_valid?(ledger, target, evidence) do
    candidate = ledger["candidate"] || %{}
    publication = ledger["publication"] || %{}
    selected = ledger["release_packages"]
    versions = ledger["target_versions"]
    expected_tag = "mailglass-v#{get_in(target, ["packages", "mailglass"])}"

    with :ok <- exact("ledger workflow path", publication["workflow_path"], @workflow_path),
         :ok <- exact("ledger workflow name", publication["workflow_name"], @workflow_name),
         :ok <- exact("ledger environment", publication["environment"], @environment),
         :ok <- exact("candidate tag", candidate["tag"], expected_tag),
         :ok <- sha?("candidate SHA", candidate["sha"]),
         :ok <- exact("candidate checkout", evidence["candidate_head"], candidate["sha"]),
         :ok <- exact("tag dereference", evidence["tag_sha"], candidate["sha"]),
         :ok <- exact_set("resolver-selected packages", evidence["resolver_packages"], selected),
         :ok <- exact_set("release target packages", selected, target["release_packages"]),
         :ok <- exact_map("target versions", versions, target["packages"]),
         :ok <- exact_map("source versions", evidence["source_versions"], versions),
         :ok <- checksum_map?(ledger["archive_checksums"], selected),
         :ok <-
           environment_valid?(
             publication["environment_protection"],
             evidence["environment_protection"]
           ) do
      :ok
    end
  end

  defp environment_valid?(ledger, live) when is_map(ledger) and is_map(live) do
    reviewer = ledger["required_reviewer"]

    with :ok <- exact("protected environment name", live["name"], @environment),
         true <- is_integer(live["id"]) || {:error, "protected environment id is missing"},
         :ok <-
           exact("environment admin bypass", live["can_admins_bypass"], ledger["can_admins_bypass"]),
         :ok <-
           exact(
             "environment self review",
             live["prevent_self_review"],
             ledger["prevent_self_review"]
           ),
         true <-
           (is_binary(reviewer) and reviewer in (live["required_reviewers"] || [])) ||
             {:error, "required environment reviewer mismatch"} do
      :ok
    else
      {:error, _} = error -> error
      _ -> {:error, "protected environment evidence is invalid"}
    end
  end

  defp environment_valid?(_, _), do: {:error, "protected environment evidence is required"}

  defp prepublication_ci_valid?(ledger, evidence) do
    runs = evidence["ci_runs"] || %{}
    prepublication = ledger["prepublication"] || %{}
    ci = runs["ci"] || %{}
    advisory = runs["advisory"] || %{}

    with :ok <- run_valid?(ci, prepublication["ci"], @ci_path),
         :ok <- run_valid?(advisory, prepublication["advisory"], @advisory_path),
         :ok <- job_success?(ci["jobs"], "CI Green"),
         :ok <-
           Enum.reduce_while(@advisory_jobs, :ok, &reduce_job_success(&1, advisory["jobs"], &2)),
         :ok <-
           required_checks_valid?(
             evidence["branch_protection_contexts"],
             evidence["required_checks"]
           ) do
      :ok
    end
  end

  defp run_valid?(run, ledger_run, path) when is_map(run) and is_map(ledger_run) do
    with :ok <- exact("CI run id", run["id"], ledger_run["run_id"]),
         true <- run_url_matches?(run, ledger_run["run_url"]) || {:error, "CI run URL mismatch"},
         :ok <- exact("CI workflow path", workflow_path(run["path"]), path),
         :ok <- exact("CI run status", run["status"], "completed"),
         :ok <- exact("CI run conclusion", run["conclusion"], "success") do
      :ok
    end
  end

  defp run_valid?(_, _, _), do: {:error, "exact CI run evidence is required"}

  defp required_checks_valid?(contexts, checks)
       when is_list(contexts) and is_list(checks) and contexts != [] do
    Enum.reduce_while(contexts, :ok, fn context, :ok ->
      matching_check = Enum.find(checks, &(&1["name"] == context))

      cond do
        is_nil(matching_check) and context in @pr_only_required_checks ->
          {:cont, :ok}

        is_map(matching_check) and matching_check["status"] == "completed" and
            matching_check["conclusion"] == "success" ->
          {:cont, :ok}

        true ->
          {:halt, {:error, "required protected check is not green: #{context}"}}
      end
    end)
  end

  defp required_checks_valid?(_, _),
    do: {:error, "live branch-protection check evidence is required"}

  defp publication_valid?(ledger, evidence) do
    publication = ledger["publication"] || %{}
    candidate = ledger["candidate"] || %{}
    run = evidence["publish_run"] || %{}
    selected = ledger["release_packages"]
    expected_jobs = publish_jobs(selected)

    successful_jobs =
      Enum.filter(evidence["publish_jobs"] || [], fn job ->
        job["name"] in expected_jobs and job["status"] == "completed" and
          job["conclusion"] == "success"
      end)

    with :ok <- exact("publish run id", run["id"], publication["run_id"]),
         true <-
           run_url_matches?(run, publication["run_url"]) || {:error, "publish run URL mismatch"},
         :ok <- exact("workflow path", workflow_path(run["path"]), @workflow_path),
         :ok <- exact("workflow name", run["name"], @workflow_name),
         true <-
           run["event"] in ["release", "workflow_dispatch"] ||
             {:error, "publish run event mismatch"},
         :ok <- exact("publish run SHA", run["head_sha"], candidate["sha"]),
         :ok <- exact("publish run status", run["status"], "completed"),
         :ok <- exact("publish run conclusion", run["conclusion"], "success"),
         :ok <- exact_set("publish jobs", Enum.map(successful_jobs, & &1["name"]), expected_jobs),
         :ok <- publish_steps_valid?(successful_jobs, selected),
         :ok <-
           approval_valid?(
             evidence["approvals"],
             get_in(publication, ["environment_protection", "required_reviewer"])
           ),
         :ok <- deployments_valid?(evidence["deployments"], successful_jobs, candidate),
         :ok <- release_artifact_valid?(evidence["release_artifact"], ledger) do
      :ok
    else
      {:error, _} = error -> error
      _ -> {:error, "protected publish evidence is invalid"}
    end
  end

  defp publish_steps_valid?(jobs, selected) do
    Enum.reduce_while(selected, :ok, fn package, :ok ->
      job_name = publish_job(package)
      step_name = publish_step(package)
      job = Enum.find(jobs, &(&1["name"] == job_name)) || %{}

      if Enum.any?(
           job["steps"] || [],
           &(&1["name"] == step_name and &1["conclusion"] == "success")
         ),
         do: {:cont, :ok},
         else: {:halt, {:error, "publish step did not succeed for #{package}"}}
    end)
  end

  defp approval_valid?(approvals, reviewer) when is_list(approvals) and is_binary(reviewer) do
    if Enum.any?(approvals, fn approval ->
         approval["state"] == "approved" and
           get_in(approval, ["user", "login"]) == reviewer and
           Enum.any?(approval["environments"] || [], &(&1["name"] == @environment))
       end),
       do: :ok,
       else: {:error, "hex-publish environment approval is required"}
  end

  defp approval_valid?(_, _), do: {:error, "hex-publish environment approval is required"}

  defp deployments_valid?(deployments, jobs, candidate) when is_list(deployments) do
    Enum.reduce_while(jobs, :ok, fn job, :ok ->
      if Enum.any?(deployments, fn deployment ->
           deployment["job_id"] == job["id"] and deployment["sha"] == candidate["sha"] and
             deployment["ref"] == candidate["tag"] and deployment["environment"] == @environment and
             "success" in (deployment["states"] || [])
         end),
         do: {:cont, :ok},
         else: {:halt, {:error, "approved successful deployment is missing for #{job["name"]}"}}
    end)
  end

  defp deployments_valid?(_, _, _), do: {:error, "protected deployment evidence is required"}

  defp release_artifact_valid?(artifact, ledger) when is_map(artifact) do
    with :ok <- exact("artifact ref", artifact["ref"], get_in(ledger, ["candidate", "tag"])),
         :ok <-
           exact(
             "artifact candidate SHA",
             artifact["candidate_sha"],
             get_in(ledger, ["candidate", "sha"])
           ),
         :ok <-
           exact_set(
             "artifact package set",
             artifact["release_packages"],
             ledger["release_packages"]
           ),
         :ok <- exact_map("artifact versions", artifact["packages"], ledger["target_versions"]),
         true <-
           String.starts_with?(artifact["artifact_digest"] || "", "sha256:") ||
             {:error, "GitHub artifact digest is missing"} do
      :ok
    else
      {:error, _} = error -> error
      _ -> {:error, "ledger-bound release artifact is invalid"}
    end
  end

  defp release_artifact_valid?(_, _), do: {:error, "ledger-bound release artifact is required"}

  defp exact_hex_valid?(ledger, releases) when is_map(releases) do
    selected = ledger["release_packages"]

    with :ok <- exact_set("published package set", Map.keys(releases), selected),
         :ok <-
           Enum.reduce_while(selected, :ok, fn package, :ok ->
             release = releases[package] || %{}
             expected_version = get_in(ledger, ["target_versions", package])
             expected_checksum = get_in(ledger, ["archive_checksums", package])

             if release["version"] == expected_version and release["checksum"] == expected_checksum and
                  release["tarball_checksum"] == expected_checksum and release["has_docs"] == true and
                  is_nil(release["retirement"]),
                do: {:cont, :ok},
                else: {:halt, {:error, "exact Hex artifact mismatch for #{package}"}}
           end) do
      :ok
    end
  end

  defp exact_hex_valid?(_, _), do: {:error, "exact Hex artifact evidence is required"}

  defp versions_unoccupied?(releases, selected) when is_map(releases) and is_list(selected) do
    if Enum.all?(selected, &is_nil(releases[&1])),
      do: :ok,
      else: {:error, "one or more target versions are already occupied on Hex"}
  end

  defp versions_unoccupied?(_, _), do: {:error, "Hex version-availability evidence is required"}

  defp publish_jobs(selected), do: Enum.map(selected, &publish_job/1)
  defp publish_job("mailglass"), do: "publish-core"
  defp publish_job(package), do: "publish-#{String.replace_prefix(package, "mailglass_", "")}"
  defp publish_step("mailglass"), do: "Publish mailglass to Hex.pm"
  defp publish_step("mailglass_admin"), do: "Publish mailglass_admin to Hex.pm"
  defp publish_step("mailglass_inbound"), do: "Publish mailglass_inbound to Hex.pm"

  defp reduce_job_success(name, jobs, :ok) do
    case job_success?(jobs, name) do
      :ok -> {:cont, :ok}
      {:error, _} = error -> {:halt, error}
    end
  end

  defp job_success?(jobs, name) when is_list(jobs) do
    if Enum.any?(
         jobs,
         &(&1["name"] == name and &1["status"] == "completed" and &1["conclusion"] == "success")
       ),
       do: :ok,
       else: {:error, "required job is not green: #{name}"}
  end

  defp job_success?(_, name), do: {:error, "required job is not green: #{name}"}

  defp checksum_map?(checksums, selected) when is_map(checksums) and is_list(selected) do
    if Enum.sort(Map.keys(checksums)) == Enum.sort(selected) and
         Enum.all?(selected, &valid_checksum?(checksums[&1])),
       do: :ok,
       else: {:error, "candidate archive checksum map mismatch"}
  end

  defp checksum_map?(_, _), do: {:error, "candidate archive checksum map mismatch"}

  defp sha?(_label, value) when is_binary(value) and byte_size(value) == 40 do
    if Regex.match?(~r/\A[0-9a-f]{40}\z/i, value),
      do: :ok,
      else: {:error, "candidate SHA is invalid"}
  end

  defp sha?(label, _), do: {:error, "#{label} is invalid"}
  defp exact(_label, actual, expected) when actual == expected and not is_nil(expected), do: :ok
  defp exact(label, _actual, _expected), do: {:error, "#{label} mismatch"}

  defp exact_set(label, actual, expected) when is_list(actual) and is_list(expected) do
    if Enum.sort(actual) == Enum.sort(expected), do: :ok, else: {:error, "#{label} mismatch"}
  end

  defp exact_set(label, _, _), do: {:error, "#{label} mismatch"}
  defp exact_map(_label, actual, expected) when actual == expected and is_map(actual), do: :ok
  defp exact_map(label, _, _), do: {:error, "#{label} mismatch"}
  defp valid_checksum?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/i, value)
  defp workflow_path(path) when is_binary(path), do: path |> String.split("@", parts: 2) |> hd()
  defp workflow_path(_), do: nil

  defp run_url_matches?(run, expected) when is_map(run) and is_binary(expected) do
    expected == run["html_url"] or
      expected == "#{run["html_url"]}/attempts/#{run["run_attempt"]}"
  end

  defp run_url_matches?(_, _), do: false

  defp git(arguments) do
    case System.cmd("git", arguments, stderr_to_stdout: true) do
      {body, 0} -> {:ok, String.trim(body)}
      {body, _} -> {:error, "git #{Enum.join(arguments, " ")} failed: #{String.trim(body)}"}
    end
  end

  defp command_ok(command, arguments) do
    case System.cmd(command, arguments, stderr_to_stdout: true) do
      {_body, 0} -> :ok
      {body, _} -> {:error, "#{command} failed: #{String.trim(body)}"}
    end
  end

  defp gh_json(endpoint) do
    case System.cmd("gh", ["api", endpoint], stderr_to_stdout: true) do
      {body, 0} ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          _ -> {:error, "GitHub API returned invalid JSON for #{endpoint}"}
        end

      {body, _} ->
        {:error, "GitHub API failed for #{endpoint}: #{String.trim(body)}"}
    end
  end

  defp http_get(url) do
    temp = Path.join(System.tmp_dir!(), "mailglass-http-#{System.unique_integer([:positive])}")

    try do
      case System.cmd(
             "curl",
             [
               "--silent",
               "--show-error",
               "--location",
               "--output",
               temp,
               "--write-out",
               "%{http_code}",
               url
             ],
             stderr_to_stdout: true
           ) do
        {status, 0} ->
          case Integer.parse(String.trim(status)) do
            {code, ""} -> {:ok, code, File.read!(temp)}
            _ -> {:error, "HTTP client returned an invalid status for #{url}"}
          end

        {body, _} ->
          {:error, "HTTP request failed for #{url}: #{String.trim(body)}"}
      end
    after
      File.rm(temp)
    end
  end

  defp sha256!(path), do: path |> File.read!() |> sha256()
  defp sha256(body), do: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)

  defp temp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.mkdir_p!(path)
    path
  end
end

Mailglass.ReleaseProofVerifier.run(System.argv())
