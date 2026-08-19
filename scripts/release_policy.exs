defmodule Mailglass.ReleasePolicy do
  @moduledoc false

  @packages ~w(mailglass mailglass_admin mailglass_inbound)
  @target_keys ~w(schema_version status package_set baselines candidate_versions required_evidence_identifiers proposal_identity publishable_content final_identity states)
  @evidence_keys ~w(hex_package_endpoints hex_release_endpoints hex_release_checksums historical_tag historical_tag_sha)
  @publication_evidence_keys ~w(candidate_digest workflow_run_url release_ids tag_shas hex_release_checksums)
  @adoption_evidence_keys ~w(workflow_run_url target_ref checkpoint_digests)
  @checkpoint_keys ~w(generated_host trust_runner)
  @sha1 ~r/\A[0-9a-f]{40}\z/
  @sha256 ~r/\A[0-9a-f]{64}\z/
  @workflow_run_url ~r/\Ahttps:\/\/github\.com\/szTheory\/mailglass\/actions\/runs\/[1-9][0-9]*\z/

  def packages, do: @packages

  def validate_target(target) when is_map(target) do
    with :ok <- exact_keys(target, @target_keys),
         :ok <- exact_value(target, "schema_version", 1),
         :ok <- exact_package_set(target["package_set"]),
         :ok <- versions(target["baselines"]),
         :ok <- linked_core_admin(target["baselines"]),
         :ok <- evidence(target["required_evidence_identifiers"], target["baselines"]),
         :ok <- proposal(target["proposal_identity"]),
         :ok <- content(target["publishable_content"]),
         :ok <- lifecycle(target) do
      {:ok, target}
    end
  end

  def validate_target(_), do: error(:invalid_target)

  def validate_candidate(target, reviewed) when is_map(reviewed) do
    with {:ok, target} <- validate_target(target),
         :ok <- candidate_lifecycle(target),
         :ok <- exact_keys(reviewed, ~w(candidate_versions proposal_identity publishable_content)),
         :ok <- versions(reviewed["candidate_versions"]),
         :ok <- linked_core_admin(reviewed["candidate_versions"]),
         :ok <- proposal(reviewed["proposal_identity"]),
         :ok <- reviewed_content(reviewed["publishable_content"]),
         :ok <- exact_value(target, "candidate_versions", reviewed["candidate_versions"]),
         :ok <- exact_value(target, "proposal_identity", reviewed["proposal_identity"]),
         :ok <-
           exact_value(
             target["publishable_content"],
             "digest",
             reviewed["publishable_content"]["digest"]
           ),
         :ok <- advances(target["baselines"], target["candidate_versions"]) do
      {:ok, target}
    end
  end

  def validate_candidate(_, _), do: error(:invalid_candidate)

  def expected_tags(target) do
    with {:ok, target} <- validate_target(target),
         :ok <- candidate_lifecycle(target) do
      {:ok, Enum.map(@packages, &tag(&1, target["candidate_versions"][&1]))}
    end
  end

  def manifest_versions(manifest) when is_map(manifest) do
    expected = %{
      "." => "mailglass",
      "mailglass_admin" => "mailglass_admin",
      "mailglass_inbound" => "mailglass_inbound"
    }

    with :ok <- exact_keys(manifest, Map.keys(expected)),
         true <-
           Enum.all?(manifest, fn {_key, version} -> valid_version?(version) end) or
             error(:invalid_manifest),
         :ok <-
           linked_core_admin(%{
             "mailglass" => manifest["."],
             "mailglass_admin" => manifest["mailglass_admin"]
           }) do
      {:ok, Map.new(@packages, fn package -> {package, manifest[manifest_key(package)]} end)}
    else
      false -> error(:invalid_manifest)
      {:error, _} = failure -> failure
    end
  end

  def manifest_versions(_), do: error(:invalid_manifest)

  def manifest_tags(manifest) do
    with {:ok, versions} <- manifest_versions(manifest) do
      {:ok, Enum.map(@packages, &tag(&1, versions[&1]))}
    end
  end

  def validate_manifest_source(manifest, source_versions) do
    with {:ok, manifest_versions} <- manifest_versions(manifest),
         :ok <- versions(source_versions),
         :ok <- exact_value(%{"versions" => manifest_versions}, "versions", source_versions) do
      :ok
    end
  end

  def validate_release_ref(target, ref, source_versions)
      when is_binary(ref) and is_map(source_versions) do
    with {:ok, target} <- validate_target(target),
         :ok <- candidate_lifecycle(target),
         :ok <- versions(source_versions),
         :ok <- linked_core_admin(source_versions),
         :ok <- exact_value(target, "candidate_versions", source_versions),
         {:ok, tags} <- expected_tags(target),
         true <- ref in tags or error(:untrusted_ref) do
      {:ok, source_versions}
    else
      false -> error(:untrusted_ref)
      {:error, _} = failure -> failure
    end
  end

  def validate_release_ref(_, _, _), do: error(:untrusted_ref)

  def validate_published_target(target) do
    with {:ok, target} <- validate_target(target),
         :ok <- exact_value(target, "status", "published") do
      {:ok, target}
    end
  end

  def validate_completed_target(target) do
    with {:ok, target} <- validate_target(target),
         :ok <- exact_value(target, "status", "completed") do
      {:ok, target}
    end
  end

  def candidate_digest(target) do
    with {:ok, target} <- validate_target(target),
         :ok <- candidate_identity_lifecycle(target) do
      {:ok, candidate_digest_value(target)}
    end
  end

  def validate_authorization_digest(target, digest) when is_binary(digest) do
    with {:ok, target} <- validate_target(target),
         :ok <- exact_value(target, "status", "authorized"),
         {:ok, expected} <- candidate_digest(target),
         true <- digest == expected or error(:authorization_digest_mismatch) do
      {:ok, target}
    else
      false -> error(:authorization_digest_mismatch)
      {:error, _} = failure -> failure
    end
  end

  def validate_authorization_digest(_, _), do: error(:authorization_digest_mismatch)

  def validate_capture_digest(target, digest) when is_binary(digest) do
    with {:ok, target} <- validate_target(target),
         :ok <- exact_value(target, "status", "captured"),
         {:ok, expected} <- candidate_digest(target),
         true <- digest == expected or error(:capture_digest_mismatch) do
      {:ok, target}
    else
      false -> error(:capture_digest_mismatch)
      {:error, _} = failure -> failure
    end
  end

  def source_versions(root) when is_binary(root) do
    result =
      @packages
      |> Enum.reduce_while({:ok, %{}}, fn package, {:ok, versions} ->
        path = Path.join(root, mix_path(package))

        with {:ok, source} <- File.read(path),
             [[version]] <-
               Regex.scan(~r/^[\t ]*@version "([^"]+)"[\t ]*$/m, source, capture: :all_but_first),
             true <- valid_version?(version) do
          {:cont, {:ok, Map.put(versions, package, version)}}
        else
          _ -> {:halt, error(:invalid_source_versions)}
        end
      end)

    with {:ok, versions} <- result,
         :ok <- linked_core_admin(versions) do
      {:ok, versions}
    end
  end

  def cli(["validate-candidate", target_path, reviewed_path]) do
    with {:ok, target} <- read_json(target_path),
         {:ok, reviewed} <- read_json(reviewed_path),
         {:ok, target} <- validate_candidate(target, reviewed),
         {:ok, digest} <- candidate_digest(target) do
      IO.write("candidate_valid=true\n")
      IO.write("candidate_digest=#{digest}\n")
    else
      _ -> System.halt(1)
    end
  end

  def cli(["validate-source-manifest", manifest_path, root]) do
    with {:ok, manifest} <- read_json(manifest_path),
         {:ok, source_versions} <- source_versions(root),
         :ok <- validate_manifest_source(manifest, source_versions) do
      IO.write("manifest_valid=true\n")
    else
      _ -> System.halt(1)
    end
  end

  def cli(["verify-published", target_path]) do
    with {:ok, target} <- read_json(target_path),
         {:ok, target} <- validate_published_target(target) do
      IO.write("published=true\n")
      emit_release_identity(target)
    else
      _ -> System.halt(1)
    end
  end

  def cli(["verify-complete", target_path]) do
    with {:ok, target} <- read_json(target_path),
         {:ok, target} <- validate_completed_target(target) do
      IO.write("completed=true\n")
      emit_release_identity(target)

      IO.write(
        "adoption_workflow_run_url=#{target["final_identity"]["adoption_evidence"]["workflow_run_url"]}\n"
      )
    else
      _ -> System.halt(1)
    end
  end

  def cli(["expected-tags", manifest_path | target_paths]) when length(target_paths) <= 1 do
    manifest_result = fn ->
      with {:ok, json} <- File.read(manifest_path), {:ok, manifest} <- Jason.decode(json) do
        manifest_tags(manifest)
      end
    end

    result =
      case target_paths do
        [target_path] ->
          with {:ok, json} <- File.read(target_path), {:ok, target} <- Jason.decode(json) do
            case expected_tags(target) do
              {:ok, _} = candidate -> candidate
              {:error, %{reason: :inactive_candidate}} -> manifest_result.()
              {:error, _} = failure -> failure
            end
          end

        [] ->
          manifest_result.()
      end

    case result do
      {:ok, tags} -> Enum.each(tags, &IO.puts/1)
      _ -> System.halt(1)
    end
  end

  def cli(["validate-target", target_path, ref, root]) do
    with {:ok, json} <- File.read(target_path),
         {:ok, target} <- Jason.decode(json),
         {:ok, versions} <- source_versions(root),
         {:ok, manifest} <- read_json(Path.join(root, ".release-please-manifest.json")),
         :ok <- validate_manifest_source(manifest, versions),
         {:ok, versions} <- validate_release_ref(target, ref, versions) do
      IO.write("active=true\n")

      Enum.each(packages(), fn package ->
        output_name =
          if package == "mailglass",
            do: "core",
            else: String.replace_prefix(package, "mailglass_", "")

        IO.write("#{output_name}=#{versions[package]}\n")
      end)
    else
      _ -> System.halt(1)
    end
  end

  def cli(["validate-authorization", target_path, digest]) do
    with {:ok, json} <- File.read(target_path),
         {:ok, target} <- Jason.decode(json),
         {:ok, _target} <- validate_authorization_digest(target, digest) do
      IO.write("authorized=true\n")
    else
      _ -> System.halt(1)
    end
  end

  def cli(["validate-captured-dispatch", target_path, digest]) do
    with {:ok, json} <- File.read(target_path),
         {:ok, target} <- Jason.decode(json),
         {:ok, target} <- validate_capture_digest(target, digest) do
      IO.write("captured=true\n")
      IO.write("candidate_digest=#{digest}\n")
      IO.write("content_digest=#{target["publishable_content"]["digest"]}\n")
      IO.write("proposal_head=#{target["proposal_identity"]["head_sha"]}\n")
      IO.write("source_sha=#{target["proposal_identity"]["source_sha"]}\n")

      Enum.each(packages(), fn package ->
        key =
          if package == "mailglass",
            do: "core",
            else: String.replace_prefix(package, "mailglass_", "")

        IO.write("#{key}=#{target["candidate_versions"][package]}\n")
      end)
    else
      _ -> System.halt(1)
    end
  end

  def cli(["completed-versions", target_path]) do
    with {:ok, json} <- File.read(target_path),
         {:ok, target} <- Jason.decode(json),
         {:ok, target} <- validate_completed_target(target) do
      IO.write("completed=true\n")
      IO.write("core=#{target["candidate_versions"]["mailglass"]}\n")
      IO.write("admin=#{target["candidate_versions"]["mailglass_admin"]}\n")
      IO.write("inbound=#{target["candidate_versions"]["mailglass_inbound"]}\n")
      IO.write("tag_sha=#{target["final_identity"]["tag_sha"]}\n")
      IO.write("target_ref=#{target["final_identity"]["tag_sha"]}\n")
    else
      _ -> System.halt(1)
    end
  end

  def cli(["authorized-versions", target_path]) do
    with {:ok, json} <- File.read(target_path),
         {:ok, target} <- Jason.decode(json),
         {:ok, target} <- validate_target(target),
         true <- target["status"] in ["authorized", "published"] or error(:invalid_lifecycle) do
      IO.write("completed=false\n")
      IO.write("authorized=true\n")
      IO.write("core=#{target["candidate_versions"]["mailglass"]}\n")
      IO.write("admin=#{target["candidate_versions"]["mailglass_admin"]}\n")
      IO.write("inbound=#{target["candidate_versions"]["mailglass_inbound"]}\n")
      {:ok, digest} = candidate_digest(target)
      IO.write("status=#{target["status"]}\n")
      IO.write("candidate_digest=#{digest}\n")
      IO.write("content_digest=#{target["publishable_content"]["digest"]}\n")
      IO.write("proposal_head=#{target["proposal_identity"]["head_sha"]}\n")
      IO.write("source_sha=#{target["proposal_identity"]["source_sha"]}\n")
      IO.write("tag_sha=#{target["final_identity"]["tag_sha"] || ""}\n")
    else
      _ -> System.halt(1)
    end
  end

  def cli(["validate-protected-dispatch", target_path, digest]) do
    with {:ok, json} <- File.read(target_path),
         {:ok, target} <- Jason.decode(json),
         {:ok, target} <- validate_authorization_digest(target, digest) do
      IO.write("authorized=true\n")
      IO.write("candidate_digest=#{digest}\n")
      IO.write("content_digest=#{target["publishable_content"]["digest"]}\n")
      IO.write("proposal_head=#{target["proposal_identity"]["head_sha"]}\n")
      IO.write("source_sha=#{target["proposal_identity"]["source_sha"]}\n")
    else
      _ -> System.halt(1)
    end
  end

  def cli(["capture-candidate", target_path, root, head_sha, source_sha, content_digest]) do
    with {:ok, json} <- File.read(target_path),
         {:ok, target} <- Jason.decode(json),
         {:ok, target} <- validate_target(target),
         :ok <- exact_value(target, "status", "inactive"),
         {:ok, versions} <- source_versions(root),
         {:ok, manifest} <- read_json(Path.join(root, ".release-please-manifest.json")),
         :ok <- validate_manifest_source(manifest, versions),
         :ok <- advances(target["baselines"], versions),
         true <- (sha1?(head_sha) and sha1?(source_sha)) or error(:invalid_proposal),
         true <- sha256?(content_digest) or error(:invalid_content) do
      candidate = %{
        "candidate_versions" => versions,
        "proposal_identity" => %{"head_sha" => head_sha, "source_sha" => source_sha},
        "publishable_content" => %{
          "algorithm" => "sha256",
          "digest" => content_digest,
          "excludes" => [".planning/release-target.json"]
        }
      }

      IO.puts(Jason.encode!(candidate))
    else
      _ -> System.halt(1)
    end
  end

  def cli(_), do: System.halt(1)

  defp lifecycle(target) do
    with :ok <- exact_keys(target["states"], ~w(capture authorization publication)) do
      case {target["status"], target["states"]} do
        {"inactive",
         %{
           "capture" => "inactive",
           "authorization" => "unauthorized",
           "publication" => "not_started"
         }} ->
          with :ok <- exact_value(target, "candidate_versions", nil),
               :ok <-
                 exact_value(target, "proposal_identity", %{"head_sha" => nil, "source_sha" => nil}),
               :ok <- exact_value(target["publishable_content"], "digest", nil),
               :ok <- candidate_final_identity(target["final_identity"]),
               do: :ok

        {status,
         %{
           "capture" => "captured",
           "authorization" => authorization,
           "publication" => "not_started"
         }}
        when status in ["captured", "authorized"] and
               authorization in ["unauthorized", "authorized"] ->
          if status == "authorized" == (authorization == "authorized") do
            with :ok <- versions(target["candidate_versions"]),
                 :ok <- linked_core_admin(target["candidate_versions"]),
                 :ok <- advances(target["baselines"], target["candidate_versions"]),
                 :ok <- candidate_final_identity(target["final_identity"]),
                 :ok <- reviewed_content(target["publishable_content"]),
                 do: :ok
          else
            error(:invalid_lifecycle)
          end

        {status,
         %{"capture" => "captured", "authorization" => "authorized", "publication" => "published"}} ->
          if status in ["published", "completed"] do
            with :ok <- versions(target["candidate_versions"]),
                 :ok <- linked_core_admin(target["candidate_versions"]),
                 :ok <- advances(target["baselines"], target["candidate_versions"]),
                 :ok <- reviewed_content(target["publishable_content"]),
                 :ok <- published_final_identity(target, status),
                 do: :ok
          else
            error(:invalid_lifecycle)
          end

        _ ->
          error(:invalid_lifecycle)
      end
    end
  end

  defp candidate_lifecycle(target) do
    if target["status"] in ["captured", "authorized"] and target["states"]["capture"] == "captured" do
      :ok
    else
      error(:inactive_candidate)
    end
  end

  defp candidate_identity_lifecycle(target) do
    if target["status"] in ["captured", "authorized", "published", "completed"] and
         target["states"]["capture"] == "captured" do
      :ok
    else
      error(:inactive_candidate)
    end
  end

  defp exact_package_set(value) when is_list(value) and value == @packages, do: :ok
  defp exact_package_set(_), do: error(:invalid_package_set)

  defp versions(value) when is_map(value) do
    with :ok <- exact_keys(value, @packages),
         true <- Enum.all?(Map.values(value), &valid_version?/1) or error(:invalid_versions) do
      :ok
    else
      false -> error(:invalid_versions)
      {:error, _} = failure -> failure
    end
  end

  defp versions(_), do: error(:invalid_versions)

  defp linked_core_admin(%{"mailglass" => version, "mailglass_admin" => version}), do: :ok
  defp linked_core_admin(_), do: error(:linked_versions_diverge)

  defp evidence(value, baselines) when is_map(value) do
    with :ok <- exact_keys(value, @evidence_keys),
         :ok <-
           endpoint_map(value["hex_package_endpoints"], fn package ->
             "https://hex.pm/api/packages/#{package}"
           end),
         :ok <-
           endpoint_map(value["hex_release_endpoints"], fn package ->
             "https://hex.pm/api/packages/#{package}/releases/#{baselines[package]}"
           end),
         :ok <- checksum_map(value["hex_release_checksums"]),
         true <-
           value["historical_tag"] == "mailglass-v#{baselines["mailglass"]}" or
             error(:invalid_evidence),
         true <- sha1?(value["historical_tag_sha"]) or error(:invalid_evidence),
         do: :ok
  end

  defp evidence(_, _), do: error(:invalid_evidence)

  defp endpoint_map(value, builder) when is_map(value) do
    if exact_keys(value, @packages) == :ok and Enum.all?(@packages, &(value[&1] == builder.(&1))),
      do: :ok,
      else: error(:invalid_evidence)
  end

  defp endpoint_map(_, _), do: error(:invalid_evidence)

  defp checksum_map(value) when is_map(value) do
    if exact_keys(value, @packages) == :ok and Enum.all?(Map.values(value), &sha256?/1),
      do: :ok,
      else: error(:invalid_evidence)
  end

  defp checksum_map(_), do: error(:invalid_evidence)

  defp proposal(value) when is_map(value) do
    with :ok <- exact_keys(value, ~w(head_sha source_sha)),
         head = value["head_sha"],
         source = value["source_sha"],
         true <-
           (is_nil(head) and is_nil(source)) or (sha1?(head) and sha1?(source)) or
             error(:invalid_proposal),
         do: :ok
  end

  defp proposal(_), do: error(:invalid_proposal)

  defp content(value) when is_map(value) do
    with :ok <- exact_keys(value, ~w(algorithm digest excludes)),
         true <-
           (value["algorithm"] == "sha256" and
              value["excludes"] == [".planning/release-target.json"]) or error(:invalid_content),
         true <- is_nil(value["digest"]) or sha256?(value["digest"]) or error(:invalid_content),
         do: :ok
  end

  defp content(_), do: error(:invalid_content)

  defp reviewed_content(value) when is_map(value) do
    with :ok <- content(value), true <- sha256?(value["digest"]) or error(:invalid_content), do: :ok
  end

  defp reviewed_content(_), do: error(:invalid_content)

  defp candidate_final_identity(value) do
    exact_value(%{"final_identity" => value}, "final_identity", %{"tag_sha" => nil})
  end

  defp published_final_identity(target, status) when is_map(target) do
    value = target["final_identity"]

    with :ok <- exact_keys(value, ~w(tag_sha publication_evidence adoption_evidence)),
         true <- sha1?(value["tag_sha"]) or error(:invalid_final_identity),
         candidate_digest = candidate_digest_value(target),
         :ok <-
           publication_evidence(
             value["publication_evidence"],
             value["tag_sha"],
             candidate_digest
           ),
         :ok <- adoption_evidence(value["adoption_evidence"], status, value["tag_sha"]) do
      :ok
    else
      false -> error(:invalid_final_identity)
      {:error, _} = failure -> failure
    end
  end

  defp published_final_identity(_, _), do: error(:invalid_final_identity)

  defp publication_evidence(value, tag_sha, candidate_digest) when is_map(value) do
    with :ok <- exact_keys(value, @publication_evidence_keys),
         :ok <- exact_value(value, "candidate_digest", candidate_digest),
         :ok <- workflow_run_url(value["workflow_run_url"]),
         :ok <- positive_integer_map(value["release_ids"]),
         :ok <- matching_tag_sha_map(value["tag_shas"], tag_sha),
         :ok <- checksum_map(value["hex_release_checksums"]) do
      :ok
    end
  end

  defp publication_evidence(_, _, _), do: error(:invalid_publication_evidence)

  defp adoption_evidence(nil, "published", _tag_sha), do: :ok

  defp adoption_evidence(value, "completed", tag_sha) when is_map(value) do
    with :ok <- exact_keys(value, @adoption_evidence_keys),
         :ok <- workflow_run_url(value["workflow_run_url"]),
         :ok <- exact_value(value, "target_ref", tag_sha),
         :ok <- exact_keys(value["checkpoint_digests"], @checkpoint_keys),
         true <-
           Enum.all?(Map.values(value["checkpoint_digests"]), &sha256?/1) or
             error(:invalid_adoption_evidence) do
      :ok
    else
      false -> error(:invalid_adoption_evidence)
      {:error, _} = failure -> failure
    end
  end

  defp adoption_evidence(_, _, _), do: error(:invalid_adoption_evidence)

  defp positive_integer_map(value) when is_map(value) do
    if exact_keys(value, @packages) == :ok and
         Enum.all?(Map.values(value), &(is_integer(&1) and &1 > 0)) and
         length(Enum.uniq(Map.values(value))) == length(@packages),
       do: :ok,
       else: error(:invalid_publication_evidence)
  end

  defp positive_integer_map(_), do: error(:invalid_publication_evidence)

  defp matching_tag_sha_map(value, tag_sha) when is_map(value) do
    if exact_keys(value, @packages) == :ok and
         Enum.all?(Map.values(value), &(&1 == tag_sha and sha1?(&1))),
       do: :ok,
       else: error(:invalid_publication_evidence)
  end

  defp matching_tag_sha_map(_, _), do: error(:invalid_publication_evidence)

  defp workflow_run_url(value) do
    if is_binary(value) and Regex.match?(@workflow_run_url, value),
      do: :ok,
      else: error(:invalid_workflow_run_url)
  end

  defp advances(baselines, candidates) do
    if Enum.all?(@packages, &(compare_versions(candidates[&1], baselines[&1]) == :gt)),
      do: :ok,
      else: error(:candidate_not_new)
  end

  defp compare_versions(left, right) do
    {:ok, parsed_left} = Version.parse(left)
    {:ok, parsed_right} = Version.parse(right)
    Version.compare(parsed_left, parsed_right)
  end

  defp tag("mailglass", version), do: "mailglass-v#{version}"
  defp tag(package, version), do: "#{package}-v#{version}"
  defp mix_path("mailglass"), do: "mix.exs"
  defp mix_path(package), do: "#{package}/mix.exs"
  defp manifest_key("mailglass"), do: "."
  defp manifest_key(package), do: package

  defp valid_version?(value) when is_binary(value) do
    case Version.parse(value) do
      {:ok, %Version{pre: [], build: nil}} -> true
      _ -> false
    end
  end

  defp valid_version?(_), do: false
  defp sha1?(value), do: is_binary(value) and Regex.match?(@sha1, value)
  defp sha256?(value), do: is_binary(value) and Regex.match?(@sha256, value)

  defp exact_keys(map, keys) when is_map(map) and is_list(keys),
    do: if(Map.keys(map) |> Enum.sort() == Enum.sort(keys), do: :ok, else: error(:invalid_schema))

  defp exact_value(map, key, expected),
    do: if(Map.get(map, key) == expected, do: :ok, else: error(:identity_mismatch))

  defp canonical_json(value) when is_map(value) do
    encoded =
      value
      |> Enum.sort_by(fn {key, _value} -> key end)
      |> Enum.map_join(",", fn {key, nested} ->
        Jason.encode!(key) <> ":" <> canonical_json(nested)
      end)

    "{" <> encoded <> "}"
  end

  defp canonical_json(value) when is_list(value),
    do: "[" <> Enum.map_join(value, ",", &canonical_json/1) <> "]"

  defp canonical_json(value), do: Jason.encode!(value)

  defp candidate_digest_value(target) do
    payload =
      Map.take(target, [
        "schema_version",
        "package_set",
        "baselines",
        "candidate_versions",
        "required_evidence_identifiers",
        "proposal_identity",
        "publishable_content"
      ])

    :crypto.hash(:sha256, canonical_json(payload)) |> Base.encode16(case: :lower)
  end

  defp read_json(path) do
    with {:ok, json} <- File.read(path), {:ok, value} <- Jason.decode(json), do: {:ok, value}
  end

  defp emit_release_identity(target) do
    IO.write("core=#{target["candidate_versions"]["mailglass"]}\n")
    IO.write("admin=#{target["candidate_versions"]["mailglass_admin"]}\n")
    IO.write("inbound=#{target["candidate_versions"]["mailglass_inbound"]}\n")
    IO.write("tag_sha=#{target["final_identity"]["tag_sha"]}\n")

    IO.write(
      "publication_workflow_run_url=#{target["final_identity"]["publication_evidence"]["workflow_run_url"]}\n"
    )
  end

  defp error(reason), do: {:error, %{reason: reason}}
end

# `mix run FILE --flag` only evaluates FILE; it does not call cli/1. Fail the
# historical verification spellings loudly so they can never report a false
# green. Supported callers use `--require FILE -e '...cli(System.argv())' --`
# and pass command names without a leading `--`.
case System.argv() do
  [flag | _]
  when flag in ["--validate-candidate", "--verify-published", "--verify-complete"] ->
    IO.puts(:stderr, "unsupported direct release-policy invocation: #{flag}")
    System.halt(64)

  _ ->
    :ok
end
