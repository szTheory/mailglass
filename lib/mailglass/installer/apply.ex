defmodule Mailglass.Installer.Apply do
  @moduledoc """
  Applies installer operations with deterministic ordering and outcome labels.
  """

  alias Mailglass.Installer.Conflict
  alias Mailglass.Installer.Manifest
  alias Mailglass.Installer.Operation
  alias Mailglass.Installer.Templates

  @type result_map :: %{
          operations: [Operation.t()],
          counts: %{
            create: non_neg_integer(),
            update: non_neg_integer(),
            unchanged: non_neg_integer(),
            conflict: non_neg_integer()
          },
          manifest_path: String.t(),
          dry_run?: boolean()
        }

  @doc """
  Runs the installer plan and classifies each operation as
  `:create | :update | :unchanged | :conflict`.
  """
  @spec run([Operation.t()], keyword()) :: {:ok, result_map()} | {:error, term()}
  def run(plan, opts) when is_list(plan) and is_list(opts) do
    manifest_path = Keyword.get(opts, :manifest_path, Manifest.default_path())
    dry_run? = Keyword.get(opts, :dry_run, false)

    with {:ok, manifest} <- Manifest.load(manifest_path),
         {:ok, operations, next_manifest} <- apply_operations(plan, manifest, opts),
         :ok <- maybe_write_manifest(next_manifest, manifest_path, dry_run?) do
      {:ok,
       %{
         operations: operations,
         counts: count_statuses(operations),
         manifest_path: manifest_path,
         dry_run?: dry_run?
       }}
    end
  end

  @spec apply_operations([Operation.t()], Manifest.t(), keyword()) ::
          {:ok, [Operation.t()], Manifest.t()} | {:error, term()}
  defp apply_operations(plan, manifest, opts) do
    sorted_plan =
      Enum.sort_by(plan, fn op ->
        {op.kind, to_string(op.path || "")}
      end)

    case Enum.reduce_while(sorted_plan, {:ok, [], manifest}, &reduce_operation(&1, &2, opts)) do
      {:ok, operations, next_manifest} ->
        {:ok, Enum.reverse(operations), Manifest.with_run_metadata(next_manifest)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec reduce_operation(Operation.t(), {:ok, [Operation.t()], Manifest.t()}, keyword()) ::
          {:cont, {:ok, [Operation.t()], Manifest.t()}} | {:halt, {:error, term()}}
  defp reduce_operation(op, {:ok, operations, manifest}, opts) do
    case apply_operation(op, manifest, opts) do
      {:ok, applied_op, next_manifest} ->
        {:cont, {:ok, [applied_op | operations], next_manifest}}

      {:error, reason} ->
        {:halt, {:error, reason}}
    end
  end

  @spec apply_operation(Operation.t(), Manifest.t(), keyword()) ::
          {:ok, Operation.t(), Manifest.t()} | {:error, term()}
  defp apply_operation(%Operation{kind: :create_file} = op, manifest, opts),
    do: apply_create_file(op, manifest, opts)

  defp apply_operation(%Operation{kind: :ensure_snippet} = op, manifest, opts),
    do: apply_ensure_snippet(op, manifest, opts)

  defp apply_operation(%Operation{kind: :ensure_block} = op, manifest, opts),
    do: apply_ensure_block(op, manifest, opts)

  defp apply_operation(%Operation{kind: :run_task} = op, manifest, opts),
    do: apply_run_task(op, manifest, opts)

  defp apply_operation(%Operation{kind: kind}, _manifest, _opts),
    do: {:error, {:unknown_operation_kind, kind}}

  @spec apply_create_file(Operation.t(), Manifest.t(), keyword()) ::
          {:ok, Operation.t(), Manifest.t()} | {:error, term()}
  defp apply_create_file(%Operation{path: path, payload: payload} = op, manifest, opts) do
    proposed_contents = to_string(payload)
    force? = Keyword.get(opts, :force, false)
    dry_run? = Keyword.get(opts, :dry_run, false)

    case File.read(path) do
      {:ok, current_contents} ->
        proposed_hash = Manifest.hash(proposed_contents)
        current_hash = Manifest.hash(current_contents)
        tracked_hash = Manifest.path_hash(manifest, path)

        cond do
          current_hash == proposed_hash ->
            ok_file_status(op, :unchanged, :already_matches, current_contents, manifest)

          force? ->
            with :ok <- write_file(path, proposed_contents, dry_run?) do
              ok_file_status(op, :update, :forced_overwrite, proposed_contents, manifest)
            end

          tracked_hash != nil and tracked_hash == current_hash ->
            with :ok <- write_file(path, proposed_contents, dry_run?) do
              ok_file_status(op, :update, :managed_update, proposed_contents, manifest)
            end

          true ->
            conflict_file_status(op, manifest, :unmanaged_drift, proposed_contents, opts)
        end

      {:error, :enoent} ->
        with :ok <- write_file(path, proposed_contents, dry_run?) do
          ok_file_status(op, :create, :new_file, proposed_contents, manifest)
        end

      {:error, reason} ->
        {:error, {:file_read_failed, path, reason}}
    end
  end

  @spec apply_ensure_snippet(Operation.t(), Manifest.t(), keyword()) ::
          {:ok, Operation.t(), Manifest.t()} | {:error, term()}
  defp apply_ensure_snippet(%Operation{path: path, payload: payload} = op, manifest, opts) do
    anchor = Map.fetch!(payload, :anchor)
    snippet = Map.fetch!(payload, :snippet)
    force? = Keyword.get(opts, :force, false)
    dry_run? = Keyword.get(opts, :dry_run, false)

    case File.read(path) do
      {:ok, current_contents} ->
        cond do
          String.contains?(current_contents, snippet) ->
            ok_file_status(op, :unchanged, :snippet_present, current_contents, manifest)

          true ->
            case insert_after_anchor(current_contents, anchor, snippet) do
              {:ok, updated_contents} ->
                with :ok <- write_file(path, updated_contents, dry_run?) do
                  ok_file_status(op, :update, :snippet_inserted, updated_contents, manifest)
                end

              :anchor_missing when force? ->
                updated_contents = append_with_spacing(current_contents, snippet)

                with :ok <- write_file(path, updated_contents, dry_run?) do
                  ok_file_status(op, :update, :forced_append, updated_contents, manifest)
                end

              :anchor_missing ->
                conflict_file_status(op, manifest, :anchor_not_found, snippet, opts)
            end
        end

      {:error, :enoent} when force? ->
        with :ok <- write_file(path, snippet, dry_run?) do
          ok_file_status(op, :create, :forced_create_missing_target, snippet, manifest)
        end

      {:error, :enoent} ->
        conflict_file_status(op, manifest, :target_missing, snippet, opts)

      {:error, reason} ->
        {:error, {:file_read_failed, path, reason}}
    end
  end

  @spec apply_ensure_block(Operation.t(), Manifest.t(), keyword()) ::
          {:ok, Operation.t(), Manifest.t()} | {:error, term()}
  defp apply_ensure_block(%Operation{path: path, payload: payload} = op, manifest, opts) do
    start_marker = Map.fetch!(payload, :start_marker)
    end_marker = Map.fetch!(payload, :end_marker)
    body = Map.fetch!(payload, :body)
    anchor = Map.fetch!(payload, :anchor)
    managed_block = Templates.managed_block(start_marker, end_marker, body)
    force? = Keyword.get(opts, :force, false)
    dry_run? = Keyword.get(opts, :dry_run, false)

    case File.read(path) do
      {:ok, current_contents} ->
        cond do
          String.contains?(current_contents, managed_block) ->
            ok_file_status(op, :unchanged, :managed_block_present, current_contents, manifest)

          true ->
            case replace_managed_block(current_contents, start_marker, end_marker, managed_block) do
              {:ok, updated_contents} ->
                with :ok <- write_file(path, updated_contents, dry_run?) do
                  ok_file_status(op, :update, :managed_block_updated, updated_contents, manifest)
                end

              :markers_missing ->
                case insert_after_anchor(current_contents, anchor, managed_block) do
                  {:ok, updated_contents} ->
                    with :ok <- write_file(path, updated_contents, dry_run?) do
                      ok_file_status(
                        op,
                        :update,
                        :managed_block_inserted,
                        updated_contents,
                        manifest
                      )
                    end

                  :anchor_missing when force? ->
                    updated_contents = append_with_spacing(current_contents, managed_block)

                    with :ok <- write_file(path, updated_contents, dry_run?) do
                      ok_file_status(op, :update, :forced_block_append, updated_contents, manifest)
                    end

                  :anchor_missing ->
                    conflict_file_status(op, manifest, :anchor_not_found, managed_block, opts)
                end

              :partial_markers when force? ->
                updated_contents = append_with_spacing(current_contents, managed_block)

                with :ok <- write_file(path, updated_contents, dry_run?) do
                  ok_file_status(op, :update, :forced_block_repair, updated_contents, manifest)
                end

              :partial_markers ->
                conflict_file_status(op, manifest, :managed_block_drift, managed_block, opts)
            end
        end

      {:error, :enoent} when force? ->
        with :ok <- write_file(path, managed_block, dry_run?) do
          ok_file_status(op, :create, :forced_create_missing_target, managed_block, manifest)
        end

      {:error, :enoent} ->
        conflict_file_status(op, manifest, :target_missing, managed_block, opts)

      {:error, reason} ->
        {:error, {:file_read_failed, path, reason}}
    end
  end

  @spec apply_run_task(Operation.t(), Manifest.t(), keyword()) ::
          {:ok, Operation.t(), Manifest.t()} | {:error, term()}
  defp apply_run_task(%Operation{payload: payload} = op, manifest, opts) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    task = Map.fetch!(payload, :task)
    args = Map.get(payload, :args, [])

    if dry_run? do
      {:ok, %{op | status: :unchanged, reason: :dry_run}, manifest}
    else
      try do
        Mix.Task.reenable(task)
        Mix.Task.run(task, args)
        {:ok, %{op | status: :update, reason: :task_executed}, manifest}
      rescue
        error ->
          {:error, {:task_run_failed, task, Exception.message(error)}}
      end
    end
  end

  @spec conflict_file_status(Operation.t(), Manifest.t(), atom(), String.t(), keyword()) ::
          {:ok, Operation.t(), Manifest.t()} | {:error, term()}
  defp conflict_file_status(op, manifest, reason, proposed_contents, opts) do
    path = op.path || ""

    case Conflict.write_sidecar(path, reason, proposed_contents, opts) do
      {:ok, sidecar_path} ->
        {:ok, %{op | status: :conflict, reason: %{reason: reason, sidecar: sidecar_path}}, manifest}

      {:error, failure_reason} ->
        {:error, failure_reason}
    end
  end

  @spec ok_file_status(Operation.t(), Operation.status(), atom(), String.t(), Manifest.t()) ::
          {:ok, Operation.t(), Manifest.t()}
  defp ok_file_status(op, status, reason, resulting_contents, manifest) do
    next_manifest =
      manifest
      |> Manifest.put_hash(op.path, Manifest.hash(resulting_contents))

    {:ok, %{op | status: status, reason: reason}, next_manifest}
  end

  @spec write_file(String.t(), String.t(), boolean()) :: :ok | {:error, term()}
  defp write_file(path, contents, true) when is_binary(path) and is_binary(contents), do: :ok

  defp write_file(path, contents, false) when is_binary(path) and is_binary(contents) do
    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, contents) do
      :ok
    else
      {:error, reason} -> {:error, {:file_write_failed, path, reason}}
    end
  end

  @spec insert_after_anchor(String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | :anchor_missing
  defp insert_after_anchor(contents, anchor, insertion) do
    case String.split(contents, anchor, parts: 2) do
      [before, after_part] ->
        updated =
          before <>
            anchor <>
            "\n" <>
            String.trim_trailing(insertion) <>
            "\n" <>
            String.trim_leading(after_part, "\n")

        {:ok, updated}

      _ ->
        :anchor_missing
    end
  end

  @spec replace_managed_block(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | :markers_missing | :partial_markers
  defp replace_managed_block(contents, start_marker, end_marker, replacement_block) do
    has_start? = String.contains?(contents, start_marker)
    has_end? = String.contains?(contents, end_marker)

    cond do
      has_start? and has_end? ->
        pattern = ~r/#{Regex.escape(start_marker)}.*?#{Regex.escape(end_marker)}/s

        if Regex.match?(pattern, contents) do
          {:ok,
           Regex.replace(pattern, contents, String.trim_trailing(replacement_block), global: false)}
        else
          :partial_markers
        end

      has_start? or has_end? ->
        :partial_markers

      true ->
        :markers_missing
    end
  end

  @spec append_with_spacing(String.t(), String.t()) :: String.t()
  defp append_with_spacing(contents, addition) do
    String.trim_trailing(contents) <> "\n\n" <> String.trim_trailing(addition) <> "\n"
  end

  @spec maybe_write_manifest(Manifest.t(), String.t(), boolean()) :: :ok | {:error, term()}
  defp maybe_write_manifest(_manifest, _path, true), do: :ok
  defp maybe_write_manifest(manifest, path, false), do: Manifest.write(manifest, path)

  @spec count_statuses([Operation.t()]) ::
          %{
            create: non_neg_integer(),
            update: non_neg_integer(),
            unchanged: non_neg_integer(),
            conflict: non_neg_integer()
          }
  defp count_statuses(operations) do
    Enum.reduce(operations, %{create: 0, update: 0, unchanged: 0, conflict: 0}, fn operation, acc ->
      case operation.status do
        :create -> Map.update!(acc, :create, &(&1 + 1))
        :update -> Map.update!(acc, :update, &(&1 + 1))
        :unchanged -> Map.update!(acc, :unchanged, &(&1 + 1))
        :conflict -> Map.update!(acc, :conflict, &(&1 + 1))
        _ -> acc
      end
    end)
  end
end
