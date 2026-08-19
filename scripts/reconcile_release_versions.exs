defmodule Mailglass.ReleaseVersionReconciler do
  @moduledoc false

  @packages ~w(mailglass mailglass_admin mailglass_inbound)
  @manifest_keys %{
    "mailglass" => ".",
    "mailglass_admin" => "mailglass_admin",
    "mailglass_inbound" => "mailglass_inbound"
  }
  @mix_paths %{
    "mailglass" => "mix.exs",
    "mailglass_admin" => "mailglass_admin/mix.exs",
    "mailglass_inbound" => "mailglass_inbound/mix.exs"
  }
  @target_path ".planning/release-target.json"
  @sha1 ~r/\A[0-9a-f]{40}\z/
  @sha256 ~r/\A[0-9a-f]{64}\z/

  def packages, do: @packages

  def reconcile(%{"repository" => repository, "hex" => hex}) do
    with {:ok, repository_by_name} <- validate_record_set(repository, :repository),
         {:ok, hex_by_name} <- validate_record_set(hex, :hex),
         :ok <- validate_repository(repository_by_name),
         :ok <- validate_hex(hex_by_name),
         :ok <- validate_live_constraints(repository_by_name, hex_by_name) do
      baselines = Map.new(@packages, &{&1, hex_by_name[&1]["release_version"]})

      drift =
        @packages
        |> Enum.reduce(%{}, fn name, differences ->
          repository_version = repository_by_name[name]["version"]
          live_version = baselines[name]

          if repository_version == live_version do
            differences
          else
            Map.put(differences, name, %{repository: repository_version, live: live_version})
          end
        end)

      report = %{
        status: if(map_size(drift) == 0, do: "reconciled", else: "drift"),
        package_set: @packages,
        baselines: baselines,
        repository: Map.new(@packages, &{&1, repository_by_name[&1]["version"]}),
        constraints: dependency_constraints(repository_by_name),
        evidence: evidence_from_hex(hex_by_name),
        drift: drift
      }

      if map_size(drift) == 0, do: {:ok, report}, else: {:drift, report}
    end
  end

  def reconcile(_), do: error(:malformed_fixture, "expected repository and hex record lists")

  def parse_repository(root) do
    with {:ok, manifest} <- read_json(Path.join(root, ".release-please-manifest.json")),
         :ok <- validate_manifest_keys(manifest),
         {:ok, versions} <- parse_mix_versions(root),
         {:ok, admin_constraint} <- parse_dependency(root, "mailglass_admin/mix.exs", "mailglass"),
         {:ok, admin_inbound_constraint} <-
           parse_dependency(root, "mailglass_admin/mix.exs", "mailglass_inbound"),
         {:ok, inbound_constraint} <-
           parse_dependency(root, "mailglass_inbound/mix.exs", "mailglass") do
      records = [
        repository_record("mailglass", versions["mailglass"], manifest["."], %{}),
        repository_record(
          "mailglass_admin",
          versions["mailglass_admin"],
          manifest["mailglass_admin"],
          %{
            "mailglass" => admin_constraint,
            "mailglass_inbound" => admin_inbound_constraint
          }
        ),
        repository_record(
          "mailglass_inbound",
          versions["mailglass_inbound"],
          manifest["mailglass_inbound"],
          %{"mailglass" => inbound_constraint}
        )
      ]

      case validate_record_set(records, :repository) do
        {:ok, by_name} ->
          case validate_repository(by_name) do
            :ok -> {:ok, records}
            {:error, _} = failure -> failure
          end

        {:error, _} = failure ->
          failure
      end
    end
  end

  def fetch_live(getter \\ &curl_get/1) do
    Enum.reduce_while(@packages, {:ok, []}, fn name, {:ok, records} ->
      package_endpoint = package_endpoint(name)

      with {:ok, package} <- fetch_json(getter, package_endpoint),
           {:ok, latest} <- package_latest_release(name, package),
           release_endpoint = release_endpoint(name, latest),
           {:ok, release} <- fetch_json(getter, release_endpoint),
           {:ok, record} <- live_record(name, package_endpoint, release_endpoint, package, release) do
        {:cont, {:ok, records ++ [record]}}
      else
        {:error, _} = failure -> {:halt, failure}
      end
    end)
  end

  def inactive_target(baselines, evidence) do
    %{
      "schema_version" => 1,
      "status" => "inactive",
      "package_set" => @packages,
      "baselines" => baselines,
      "candidate_versions" => nil,
      "required_evidence_identifiers" => evidence,
      "proposal_identity" => %{"head_sha" => nil, "source_sha" => nil},
      "publishable_content" => %{
        "algorithm" => "sha256",
        "digest" => nil,
        "excludes" => [@target_path]
      },
      "final_identity" => %{"tag_sha" => nil},
      "states" => %{
        "capture" => "inactive",
        "authorization" => "unauthorized",
        "publication" => "not_started"
      }
    }
  end

  def validate_inactive_target(target) when is_map(target) do
    with :ok <-
           exact_keys(target, [
             "schema_version",
             "status",
             "package_set",
             "baselines",
             "candidate_versions",
             "required_evidence_identifiers",
             "proposal_identity",
             "publishable_content",
             "final_identity",
             "states"
           ]),
         :ok <- exact_value(target, "schema_version", 1),
         :ok <- exact_value(target, "status", "inactive"),
         :ok <- exact_value(target, "package_set", @packages),
         :ok <- validate_versions(target["baselines"], :baseline),
         :ok <- exact_value(target, "candidate_versions", nil),
         :ok <- validate_evidence(target["required_evidence_identifiers"], target["baselines"]),
         :ok <- exact_value(target, "proposal_identity", %{"head_sha" => nil, "source_sha" => nil}),
         :ok <-
           exact_value(target, "publishable_content", %{
             "algorithm" => "sha256",
             "digest" => nil,
             "excludes" => [@target_path]
           }),
         :ok <- exact_value(target, "final_identity", %{"tag_sha" => nil}),
         :ok <-
           exact_value(target, "states", %{
             "capture" => "inactive",
             "authorization" => "unauthorized",
             "publication" => "not_started"
           }) do
      {:ok, target}
    end
  end

  def validate_inactive_target(_), do: error(:invalid_target, "target must be an object")

  def validate_activation(target, reviewed) when is_map(target) and is_map(reviewed) do
    with :ok <- exact_value(target, "schema_version", 1),
         :ok <- exact_value(target, "status", "captured"),
         :ok <- exact_value(target, "package_set", @packages),
         :ok <- validate_versions(target["baselines"], :baseline),
         :ok <- validate_versions(target["candidate_versions"], :candidate),
         :ok <- validate_advances(target["baselines"], target["candidate_versions"]),
         :ok <- exact_value(target, "candidate_versions", reviewed["candidate_versions"]),
         :ok <- validate_proposal_identity(target["proposal_identity"]),
         :ok <- exact_value(target, "proposal_identity", reviewed["proposal_identity"]),
         :ok <- validate_publishable_content(target["publishable_content"]),
         :ok <-
           exact_value(
             target["publishable_content"],
             "digest",
             get_in(reviewed, ["publishable_content", "digest"])
           ),
         :ok <- exact_value(target, "final_identity", %{"tag_sha" => nil}),
         :ok <-
           exact_value(target, "states", %{
             "capture" => "captured",
             "authorization" => "unauthorized",
             "publication" => "not_started"
           }) do
      {:ok, target}
    end
  end

  def validate_activation(_, _),
    do: error(:invalid_candidate, "candidate and review must be objects")

  def write_inactive_target(path, baselines, evidence) do
    target = inactive_target(baselines, evidence)

    with {:ok, _} <- validate_inactive_target(target),
         :ok <- File.mkdir_p(Path.dirname(path)),
         encoded <- Jason.encode_to_iodata!(target, pretty: true),
         temporary = path <> ".tmp",
         :ok <- File.write(temporary, [encoded, "\n"]),
         :ok <- File.rename(temporary, path) do
      {:ok, target}
    end
  end

  def live_reconciliation(root \\ File.cwd!(), getter \\ &curl_get/1) do
    with {:ok, repository} <- parse_repository(root),
         {:ok, hex} <- fetch_live(getter) do
      reconcile(%{"repository" => repository, "hex" => hex})
    end
  end

  def cli(argv, root \\ File.cwd!()) do
    case argv do
      ["--fixture", path] ->
        with {:ok, fixture} <- read_json(Path.expand(path, root)) do
          render_result(reconcile(fixture))
        else
          {:error, reason} -> render_result({:error, reason})
        end

      ["--check-live"] ->
        render_result(live_reconciliation(root))

      ["--validate-inactive-target", path] ->
        with {:ok, target} <- read_json(Path.expand(path, root)) do
          render_result(validate_inactive_target(target))
        else
          {:error, reason} -> render_result({:error, reason})
        end

      ["--write-inactive-target", path, "--historical-tag", tag, "--historical-tag-sha", sha] ->
        with true <- Regex.match?(@sha1, sha) || error(:invalid_tag_sha, sha),
             {:ok, report} <- live_reconciliation(root),
             evidence <-
               report.evidence
               |> Map.put("historical_tag", tag)
               |> Map.put("historical_tag_sha", sha),
             {:ok, target} <-
               write_inactive_target(Path.expand(path, root), report.baselines, evidence) do
          render_result({:ok, target})
        else
          {:drift, report} -> render_result({:drift, report})
          {:error, reason} -> render_result({:error, reason})
        end

      _ ->
        render_result(
          error(
            :usage,
            "use --fixture PATH, --check-live, --validate-inactive-target PATH, or --write-inactive-target PATH --historical-tag TAG --historical-tag-sha SHA"
          )
        )
    end
  end

  defp validate_record_set(records, kind) when is_list(records) do
    names = Enum.map(records, &(is_map(&1) && &1["name"]))
    unknown = Enum.reject(names, &(&1 in @packages))
    duplicates = names -- Enum.uniq(names)
    missing = @packages -- names

    cond do
      unknown != [] -> error(reason(kind, :unknown), inspect(unknown))
      duplicates != [] -> error(reason(kind, :duplicate), inspect(Enum.uniq(duplicates)))
      missing != [] -> error(reason(kind, :missing), inspect(missing))
      length(records) != length(@packages) -> error(reason(kind, :unknown), "record count mismatch")
      true -> {:ok, Map.new(records, &{&1["name"], &1})}
    end
  end

  defp validate_record_set(_, kind), do: error(reason(kind, :malformed), "records must be a list")

  defp validate_repository(by_name) do
    with :ok <- validate_repository_records(by_name),
         :ok <- linked_core_admin(by_name),
         :ok <- dependency_admits(by_name, "mailglass_admin", "mailglass"),
         :ok <- dependency_admits(by_name, "mailglass_admin", "mailglass_inbound"),
         :ok <- dependency_admits(by_name, "mailglass_inbound", "mailglass") do
      :ok
    end
  end

  defp validate_live_constraints(repository, hex) do
    live_versions = Map.new(@packages, &{&1, hex[&1]["release_version"]})

    [
      {"mailglass_admin", "mailglass"},
      {"mailglass_admin", "mailglass_inbound"},
      {"mailglass_inbound", "mailglass"}
    ]
    |> Enum.reduce_while(:ok, fn {owner, dependency}, :ok ->
      constraint = get_in(repository, [owner, "dependencies", dependency])
      live_version = live_versions[dependency]

      if is_binary(constraint) and Version.match?(live_version, constraint) do
        {:cont, :ok}
      else
        {:halt, error(:constraint_mismatch, "#{owner}->#{dependency} rejects live #{live_version}")}
      end
    end)
  end

  defp validate_repository_records(by_name) do
    Enum.reduce_while(@packages, :ok, fn name, :ok ->
      record = by_name[name]

      cond do
        not stable_version?(record["version"]) ->
          {:halt, error(:malformed_repository, "#{name} source version")}

        not stable_version?(record["manifest_version"]) ->
          {:halt, error(:malformed_repository, "#{name} manifest version")}

        record["version"] != record["manifest_version"] ->
          {:halt, error(:conflicting_repository, "#{name} source/manifest disagreement")}

        not is_map(record["dependencies"]) ->
          {:halt, error(:malformed_repository, "#{name} dependencies")}

        true ->
          {:cont, :ok}
      end
    end)
  end

  defp linked_core_admin(by_name) do
    if by_name["mailglass"]["version"] == by_name["mailglass_admin"]["version"] do
      :ok
    else
      error(:linked_version_mismatch, "mailglass and mailglass_admin must match")
    end
  end

  defp dependency_admits(by_name, owner, dependency) do
    constraint = get_in(by_name, [owner, "dependencies", dependency])
    version = by_name[dependency]["version"]

    cond do
      not is_binary(constraint) ->
        error(:missing_constraint, "#{owner}->#{dependency}")

      not valid_requirement?(constraint) ->
        error(:malformed_constraint, "#{owner}->#{dependency}")

      not Version.match?(version, constraint) ->
        error(:constraint_mismatch, "#{owner}->#{dependency}")

      true ->
        :ok
    end
  end

  defp validate_hex(by_name) do
    Enum.reduce_while(@packages, :ok, fn name, :ok ->
      case validate_hex_record(name, by_name[name]) do
        :ok -> {:cont, :ok}
        {:error, _} = failure -> {:halt, failure}
      end
    end)
  end

  defp validate_hex_record(name, record) do
    cond do
      record["package_name"] != name ->
        error(:conflicting_hex, "#{name} package identity")

      not stable_version?(record["latest_stable_version"]) ->
        error(:malformed_hex, "#{name} latest stable version")

      not stable_version?(record["release_version"]) ->
        error(:malformed_hex, "#{name} exact release version")

      record["latest_stable_version"] != record["release_version"] ->
        error(:conflicting_hex, "#{name} package/release disagreement")

      not is_nil(record["retirement"]) ->
        error(:retired_hex, "#{name} #{record["release_version"]}")

      not is_binary(record["checksum"]) or not Regex.match?(@sha256, record["checksum"]) ->
        error(:malformed_hex, "#{name} checksum")

      record["has_docs"] != true ->
        error(:malformed_hex, "#{name} docs evidence")

      record["package_endpoint"] != package_endpoint(name) ->
        error(:conflicting_hex, "#{name} package endpoint")

      record["release_endpoint"] != release_endpoint(name, record["release_version"]) ->
        error(:conflicting_hex, "#{name} release endpoint")

      true ->
        :ok
    end
  end

  defp parse_mix_versions(root) do
    Enum.reduce_while(@packages, {:ok, %{}}, fn name, {:ok, versions} ->
      path = Path.join(root, @mix_paths[name])

      with {:ok, source} <- File.read(path),
           [version] <-
             Regex.scan(~r/^\s*@version\s+"([^"]+)"\s*$/m, source, capture: :all_but_first),
           [value] <- version,
           true <- stable_version?(value) do
        {:cont, {:ok, Map.put(versions, name, value)}}
      else
        {:error, reason} -> {:halt, error(:source_read_failed, "#{path}: #{inspect(reason)}")}
        _ -> {:halt, error(:malformed_repository, "exactly one valid @version required in #{path}")}
      end
    end)
  end

  defp parse_dependency(root, relative, dependency) do
    path = Path.join(root, relative)

    with {:ok, source} <- File.read(path),
         matches <-
           Regex.scan(
             ~r/\{\s*:#{Regex.escape(dependency)}\s*,\s*"([^"]+)"/,
             source,
             capture: :all_but_first
           ),
         [[constraint]] <- matches,
         true <- valid_requirement?(constraint) do
      {:ok, constraint}
    else
      {:error, reason} -> error(:source_read_failed, "#{path}: #{inspect(reason)}")
      _ -> error(:malformed_constraint, "exactly one #{dependency} tuple required in #{path}")
    end
  end

  defp validate_manifest_keys(manifest) when is_map(manifest) do
    expected = Map.values(@manifest_keys) |> Enum.sort()
    actual = Map.keys(manifest) |> Enum.sort()

    if actual == expected do
      :ok
    else
      error(:manifest_package_set, "expected #{inspect(expected)}, got #{inspect(actual)}")
    end
  end

  defp validate_manifest_keys(_), do: error(:malformed_manifest, "manifest must be an object")

  defp package_latest_release(name, package) do
    releases = package["releases"]
    latest = package["latest_stable_version"]

    cond do
      package["name"] != name ->
        error(:conflicting_hex, "#{name} package response identity")

      not stable_version?(latest) or not is_list(releases) ->
        error(:malformed_hex, "#{name} package response")

      true ->
        matching = Enum.filter(releases, &(is_map(&1) && &1["version"] == latest))

        case matching do
          [%{} = summary] ->
            if is_nil(summary["retirement"]),
              do: {:ok, latest},
              else: error(:retired_hex, "#{name} #{latest}")

          [] ->
            error(:missing_hex, "#{name} latest release record")

          _ ->
            error(:duplicate_hex, "#{name} latest release record")
        end
    end
  end

  defp live_record(name, package_endpoint, release_endpoint, package, release) do
    record = %{
      "name" => name,
      "package_name" => package["name"],
      "latest_stable_version" => package["latest_stable_version"],
      "release_version" => release["version"],
      "retirement" => release["retirement"],
      "checksum" => release["checksum"],
      "has_docs" => release["has_docs"],
      "package_endpoint" => package_endpoint,
      "release_endpoint" => release_endpoint
    }

    case validate_hex_record(name, record) do
      :ok -> {:ok, record}
      {:error, _} = failure -> failure
    end
  end

  defp fetch_json(getter, url) do
    case getter.(url) do
      {:ok, body} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, value} when is_map(value) -> {:ok, value}
          {:ok, _} -> error(:malformed_hex, "#{url} returned non-object JSON")
          {:error, reason} -> error(:malformed_hex, "#{url}: #{Exception.message(reason)}")
        end

      {:error, reason} ->
        error(:hex_lookup_failed, "#{url}: #{inspect(reason)}")

      other ->
        error(:hex_lookup_failed, "#{url}: #{inspect(other)}")
    end
  end

  defp curl_get(url) do
    case System.cmd(
           "curl",
           [
             "--fail",
             "--silent",
             "--show-error",
             "--location",
             "--proto",
             "=https",
             "--max-time",
             "20",
             url
           ],
           stderr_to_stdout: true
         ) do
      {body, 0} -> {:ok, body}
      {output, status} -> {:error, %{status: status, output: String.trim(output)}}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp read_json(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, value} <- Jason.decode(contents) do
      {:ok, value}
    else
      {:error, %Jason.DecodeError{} = reason} ->
        error(:malformed_json, "#{path}: #{Exception.message(reason)}")

      {:error, reason} ->
        error(:read_failed, "#{path}: #{inspect(reason)}")
    end
  end

  defp repository_record(name, version, manifest_version, dependencies) do
    %{
      "name" => name,
      "version" => version,
      "manifest_version" => manifest_version,
      "dependencies" => dependencies
    }
  end

  defp dependency_constraints(by_name) do
    %{
      "mailglass_admin->mailglass" =>
        get_in(by_name, ["mailglass_admin", "dependencies", "mailglass"]),
      "mailglass_admin->mailglass_inbound" =>
        get_in(by_name, ["mailglass_admin", "dependencies", "mailglass_inbound"]),
      "mailglass_inbound->mailglass" =>
        get_in(by_name, ["mailglass_inbound", "dependencies", "mailglass"])
    }
  end

  defp evidence_from_hex(by_name) do
    %{
      "hex_package_endpoints" => Map.new(@packages, &{&1, by_name[&1]["package_endpoint"]}),
      "hex_release_endpoints" => Map.new(@packages, &{&1, by_name[&1]["release_endpoint"]}),
      "hex_release_checksums" => Map.new(@packages, &{&1, by_name[&1]["checksum"]})
    }
  end

  defp validate_evidence(evidence, baselines) when is_map(evidence) do
    package_endpoints = evidence["hex_package_endpoints"]
    release_endpoints = evidence["hex_release_endpoints"]
    release_checksums = evidence["hex_release_checksums"]
    historical_tag = evidence["historical_tag"]
    historical_sha = evidence["historical_tag_sha"]

    cond do
      Map.keys(evidence) |> Enum.sort() !=
          Enum.sort([
            "hex_package_endpoints",
            "hex_release_endpoints",
            "hex_release_checksums",
            "historical_tag",
            "historical_tag_sha"
          ]) ->
        error(:invalid_package_set, "evidence fields")

      package_endpoints != Map.new(@packages, &{&1, package_endpoint(&1)}) ->
        error(:invalid_evidence, "Hex package endpoints")

      release_endpoints != Map.new(@packages, &{&1, release_endpoint(&1, baselines[&1])}) ->
        error(:invalid_evidence, "Hex release endpoints")

      not is_map(release_checksums) or
        Map.keys(release_checksums) |> Enum.sort() != Enum.sort(@packages) or
          Enum.any?(release_checksums, fn {_name, checksum} ->
            not is_binary(checksum) or not Regex.match?(@sha256, checksum)
          end) ->
        error(:invalid_evidence, "Hex release checksums")

      not is_binary(historical_tag) or historical_tag == "" ->
        error(:invalid_evidence, "historical tag")

      not is_binary(historical_sha) or not Regex.match?(@sha1, historical_sha) ->
        error(:invalid_evidence, "historical tag SHA")

      true ->
        :ok
    end
  end

  defp validate_evidence(_, _), do: error(:invalid_evidence, "evidence must be an object")

  defp validate_versions(versions, kind) when is_map(versions) do
    cond do
      Map.keys(versions) |> Enum.sort() != Enum.sort(@packages) ->
        error(:invalid_package_set, "#{kind} package set")

      Enum.any?(versions, fn {_name, version} -> not stable_version?(version) end) ->
        error(:invalid_version, "#{kind} versions")

      versions["mailglass"] != versions["mailglass_admin"] ->
        error(:linked_version_mismatch, "#{kind} core/admin versions")

      true ->
        :ok
    end
  end

  defp validate_versions(_, kind), do: error(:invalid_version, "#{kind} versions")

  defp validate_advances(baselines, candidates) do
    if Enum.all?(@packages, &(Version.compare(candidates[&1], baselines[&1]) == :gt)) do
      :ok
    else
      error(:candidate_not_new, "automation proposal must advance every package")
    end
  end

  defp validate_proposal_identity(%{"head_sha" => head, "source_sha" => source}) do
    if is_binary(head) and Regex.match?(@sha1, head) and is_binary(source) and
         Regex.match?(@sha1, source) do
      :ok
    else
      error(:invalid_proposal_identity, "head/source SHA")
    end
  end

  defp validate_proposal_identity(_), do: error(:invalid_proposal_identity, "proposal identity")

  defp validate_publishable_content(%{
         "algorithm" => "sha256",
         "digest" => digest,
         "excludes" => [@target_path]
       }) do
    if is_binary(digest) and Regex.match?(@sha256, digest) do
      :ok
    else
      error(:invalid_content_digest, "publishable content digest")
    end
  end

  defp validate_publishable_content(_), do: error(:invalid_content_digest, "publishable content")

  defp exact_value(container, key, expected) when is_map(container) do
    if Map.get(container, key) == expected,
      do: :ok,
      else: error(:target_mismatch, "#{key} does not match reviewed value")
  end

  defp exact_value(_, key, _), do: error(:target_mismatch, "#{key} is absent")

  defp exact_keys(container, expected) when is_map(container) do
    if Enum.sort(Map.keys(container)) == Enum.sort(expected),
      do: :ok,
      else: error(:invalid_package_set, "target fields")
  end

  defp stable_version?(value) when is_binary(value) do
    case Version.parse(value) do
      {:ok, %Version{pre: [], build: nil}} -> true
      _ -> false
    end
  end

  defp stable_version?(_), do: false

  defp valid_requirement?(value) when is_binary(value) do
    match?({:ok, _}, Version.parse_requirement(value))
  end

  defp valid_requirement?(_), do: false

  defp package_endpoint(name), do: "https://hex.pm/api/packages/#{name}"
  defp release_endpoint(name, version), do: "#{package_endpoint(name)}/releases/#{version}"

  defp reason(:repository, suffix), do: String.to_atom("#{suffix}_repository")
  defp reason(:hex, suffix), do: String.to_atom("#{suffix}_hex")

  defp error(reason, details), do: {:error, %{reason: reason, details: details}}

  defp render_result({kind, report}) when kind in [:ok, :drift, :error] do
    status = if kind == :ok, do: 0, else: 2
    {status, Jason.encode!(%{result: Atom.to_string(kind), report: report}, pretty: true)}
  end
end

if Mix.env() != :test do
  {status, output} = Mailglass.ReleaseVersionReconciler.cli(System.argv())
  IO.puts(output)
  if status != 0, do: System.halt(status)
end
