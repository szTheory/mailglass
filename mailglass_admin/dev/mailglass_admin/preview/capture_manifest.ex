defmodule MailglassAdmin.Preview.CaptureManifest do
  @moduledoc """
  Deterministic manifest/checkpoint contract writer for preview capture output.
  """

  alias MailglassAdmin.Preview.CaptureState

  @schema_version "preview_capture.v1"
  @claim_boundary "preview-pipeline confidence only; not cross-client parity"

  @type sha_mode :: :identity | :files

  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @spec claim_boundary() :: String.t()
  def claim_boundary, do: @claim_boundary

  @spec screenshot_name(CaptureState.t()) :: String.t()
  def screenshot_name(%CaptureState{} = state) do
    module_slug =
      state.mailable
      |> inspect()
      |> String.replace_prefix("Elixir.", "")
      |> String.replace(".", "__")

    scenario = Atom.to_string(state.scenario)
    theme = Atom.to_string(state.theme)

    "#{module_slug}--#{scenario}--w#{state.width}--#{theme}.png"
  end

  @spec build_entries([CaptureState.t()], String.t(), sha_mode()) :: [map()]
  def build_entries(states, output_dir, sha_mode) when is_list(states) and is_binary(output_dir) do
    states
    |> Enum.map(&entry_for_state(&1, output_dir, sha_mode))
    |> Enum.sort_by(&entry_sort_key/1)
  end

  @spec write_from_states!([CaptureState.t()], [map()], keyword()) :: %{manifest: map(), checkpoint: map()}
  def write_from_states!(states, skipped, opts) when is_list(states) and is_list(skipped) do
    output_dir = Keyword.fetch!(opts, :output_dir)
    sha_mode = Keyword.get(opts, :sha_mode, :identity)
    manifest_path = Keyword.fetch!(opts, :manifest_path)
    checkpoint_path = Keyword.fetch!(opts, :checkpoint_path)

    entries = build_entries(states, output_dir, sha_mode)
    write!(entries, skipped, manifest_path: manifest_path, checkpoint_path: checkpoint_path)
  end

  @spec write!([map()], [map()], keyword()) :: %{manifest: map(), checkpoint: map()}
  def write!(entries, skipped, opts) when is_list(entries) and is_list(skipped) do
    manifest_path = Keyword.fetch!(opts, :manifest_path)
    checkpoint_path = Keyword.fetch!(opts, :checkpoint_path)

    normalized_entries = Enum.sort_by(entries, &entry_sort_key/1)
    normalized_skipped = skipped |> Enum.map(&normalize_skipped/1) |> Enum.sort_by(&skipped_sort_key/1)

    manifest = %{
      "schema_version" => @schema_version,
      "claim_boundary" => @claim_boundary,
      "captures" => normalized_entries,
      "skipped" => normalized_skipped
    }

    checkpoint = %{
      "schema_version" => @schema_version,
      "claim_boundary" => @claim_boundary,
      "capture_count" => Enum.count(normalized_entries),
      "skipped_count" => Enum.count(normalized_skipped),
      "matrix_sha256" => matrix_sha256(normalized_entries),
      "captures" => normalized_entries
    }

    write_json!(manifest_path, manifest)
    write_json!(checkpoint_path, checkpoint)

    %{manifest: manifest, checkpoint: checkpoint}
  end

  defp entry_for_state(%CaptureState{} = state, output_dir, sha_mode) do
    path = screenshot_name(state)
    absolute_path = Path.join(output_dir, path)

    %{
      "mailable" => inspect(state.mailable),
      "scenario" => Atom.to_string(state.scenario),
      "width" => state.width,
      "theme" => Atom.to_string(state.theme),
      "path" => path,
      "sha256" => sha256_for(absolute_path, state, path, sha_mode)
    }
  end

  defp sha256_for(path, state, relative_path, :files) do
    case File.read(path) do
      {:ok, contents} ->
        Base.encode16(:crypto.hash(:sha256, contents), case: :lower)

      {:error, _reason} ->
        identity_sha256(state, relative_path)
    end
  end

  defp sha256_for(_path, state, relative_path, :identity), do: identity_sha256(state, relative_path)

  defp identity_sha256(state, relative_path) do
    [
      inspect(state.mailable),
      Atom.to_string(state.scenario),
      Integer.to_string(state.width),
      Atom.to_string(state.theme),
      relative_path
    ]
    |> Enum.join("|")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp normalize_skipped(%{mailable: mailable, reason: reason, details: details}) do
    %{
      "mailable" => inspect(mailable),
      "reason" => Atom.to_string(reason),
      "details" => details
    }
  end

  defp normalize_skipped(other) do
    %{
      "mailable" => inspect(Map.get(other, :mailable)),
      "reason" => to_string(Map.get(other, :reason)),
      "details" => Map.get(other, :details)
    }
  end

  defp write_json!(path, payload) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, Jason.encode_to_iodata!(payload, pretty: true))
  end

  defp matrix_sha256(entries) do
    entries
    |> Enum.map(fn entry ->
      [
        entry["mailable"],
        entry["scenario"],
        Integer.to_string(entry["width"]),
        entry["theme"],
        entry["path"],
        entry["sha256"]
      ]
      |> Enum.join("|")
    end)
    |> Enum.join("\n")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp entry_sort_key(entry) do
    {entry["mailable"], entry["scenario"], entry["width"], entry["theme"], entry["path"],
     entry["sha256"]}
  end

  defp skipped_sort_key(entry) do
    {entry["mailable"], entry["reason"], entry["details"] || ""}
  end
end
