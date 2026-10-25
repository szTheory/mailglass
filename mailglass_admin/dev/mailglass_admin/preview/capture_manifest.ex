defmodule MailglassAdmin.Preview.CaptureManifest do
  @moduledoc """
  Deterministic manifest/checkpoint contract writer for preview capture output.
  """

  alias MailglassAdmin.Preview.CaptureState

  @schema_version "preview_capture.v1"
  @claim_boundary "preview-pipeline confidence only; not cross-client parity"
  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>
  @max_png_dimension 32_768
  @max_png_pixels 268_435_456

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

  @spec build_entries([CaptureState.t()], String.t(), sha_mode(), map()) :: [map()]
  def build_entries(states, output_dir, sha_mode, provenance \\ %{})

  def build_entries(states, output_dir, sha_mode, provenance)
      when is_list(states) and is_binary(output_dir) and is_map(provenance) do
    states
    |> Enum.map(&entry_for_state(&1, output_dir, sha_mode, provenance))
    |> Enum.sort_by(&entry_sort_key/1)
  end

  @spec write_from_states!([CaptureState.t()], [map()], keyword()) :: %{
          manifest: map(),
          checkpoint: map()
        }
  def write_from_states!(states, skipped, opts) when is_list(states) and is_list(skipped) do
    output_dir = Keyword.fetch!(opts, :output_dir)
    sha_mode = Keyword.get(opts, :sha_mode, :identity)
    provenance = Keyword.get(opts, :provenance, %{})
    manifest_path = Keyword.fetch!(opts, :manifest_path)
    checkpoint_path = Keyword.fetch!(opts, :checkpoint_path)

    entries = build_entries(states, output_dir, sha_mode, provenance)

    write!(entries, skipped,
      manifest_path: manifest_path,
      checkpoint_path: checkpoint_path,
      capture_mode: if(sha_mode == :files, do: "actual", else: "identity_only")
    )
  end

  @spec write!([map()], [map()], keyword()) :: %{manifest: map(), checkpoint: map()}
  def write!(entries, skipped, opts) when is_list(entries) and is_list(skipped) do
    manifest_path = Keyword.fetch!(opts, :manifest_path)
    checkpoint_path = Keyword.fetch!(opts, :checkpoint_path)

    normalized_entries = Enum.sort_by(entries, &entry_sort_key/1)

    normalized_skipped =
      skipped |> Enum.map(&normalize_skipped/1) |> Enum.sort_by(&skipped_sort_key/1)

    capture_mode = Keyword.get(opts, :capture_mode, "identity_only")
    if capture_mode == "actual", do: validate_entry_css_identity!(normalized_entries)
    review_complete = capture_mode == "actual" and normalized_entries != []

    manifest = %{
      "schema_version" => @schema_version,
      "claim_boundary" => @claim_boundary,
      "capture_mode" => capture_mode,
      "review_complete" => review_complete,
      "captures" => normalized_entries,
      "skipped" => normalized_skipped
    }

    checkpoint = %{
      "schema_version" => @schema_version,
      "claim_boundary" => @claim_boundary,
      "capture_mode" => capture_mode,
      "review_complete" => review_complete,
      "capture_count" => Enum.count(normalized_entries),
      "skipped_count" => Enum.count(normalized_skipped),
      "matrix_sha256" => matrix_sha256(normalized_entries),
      "captures" => normalized_entries
    }

    write_json!(manifest_path, manifest)
    write_json!(checkpoint_path, checkpoint)

    %{manifest: manifest, checkpoint: checkpoint}
  end

  defp validate_entry_css_identity!(entries) do
    Enum.each(entries, fn entry ->
      assets = Map.get(entry, "assets", %{})
      build_sha = get_in(assets, ["build", "sha256"])
      served_sha = get_in(assets, ["served", "sha256"])

      unless is_binary(build_sha) and build_sha == served_sha do
        raise ArgumentError, "built and served CSS SHA-256 values must match for actual capture"
      end
    end)
  end

  defp entry_for_state(%CaptureState{} = state, output_dir, sha_mode, provenance) do
    path = screenshot_name(state)
    absolute_path = Path.join(output_dir, path)

    identity = %{
      "mailable" => inspect(state.mailable),
      "scenario" => Atom.to_string(state.scenario),
      "width" => state.width,
      "theme" => Atom.to_string(state.theme),
      "path" => path
    }

    case sha_mode do
      :files ->
        validate_actual_provenance!(provenance)

        Map.merge(identity, %{
          "route" => state.url,
          "interaction_state" => "initial_render",
          "source_relation" => "candidate_render; no paired before/after baseline",
          "candidate" => normalize_map(provenance.candidate),
          "browser" => normalize_map(provenance.browser),
          "assets" => normalize_assets(provenance.assets),
          "sha256" => sha256_for(absolute_path, output_dir, path)
        })

      :identity ->
        Map.put(identity, "sha256", identity_sha256(state, path))
    end
  end

  defp validate_actual_provenance!(provenance) do
    candidate = Map.get(provenance, :candidate, %{})
    browser = Map.get(provenance, :browser, %{})
    assets = Map.get(provenance, :assets, %{})

    require_value!(Map.get(candidate, :revision), "candidate revision")
    require_boolean!(Map.get(candidate, :dirty), "candidate dirty state")
    require_value!(Map.get(browser, :name), "browser name")
    require_value!(Map.get(browser, :version), "browser version")

    for asset <- [:source, :build, :served] do
      metadata = Map.get(assets, asset, %{})
      require_value!(Map.get(metadata, :path) || Map.get(metadata, :url), "#{asset} asset path")
      require_sha256!(Map.get(metadata, :sha256), "#{asset} asset sha256")
    end

    if get_in(assets, [:build, :sha256]) != get_in(assets, [:served, :sha256]) do
      raise ArgumentError, "built and served CSS SHA-256 values must match for actual capture"
    end
  end

  defp normalize_assets(assets) do
    Map.new([:source, :build, :served], fn kind ->
      {Atom.to_string(kind), normalize_map(Map.fetch!(assets, kind))}
    end)
  end

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp require_value!(value, _label) when is_binary(value) and value != "", do: :ok
  defp require_value!(_value, label), do: raise(ArgumentError, "#{label} is required")

  defp require_boolean!(value, _label) when is_boolean(value), do: :ok
  defp require_boolean!(_value, label), do: raise(ArgumentError, "#{label} is required")

  defp require_sha256!(value, label) do
    unless is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/, value) do
      raise ArgumentError, "#{label} must be a lowercase SHA-256 digest"
    end
  end

  defp sha256_for(path, output_dir, relative_path) do
    expanded_dir = Path.expand(output_dir)
    expanded_path = Path.expand(path)
    relative = Path.relative_to(expanded_path, expanded_dir)

    if relative in ["..", ""] or String.starts_with?(relative, "../") or
         Path.type(relative) == :absolute do
      raise ArgumentError, "capture path must stay inside the output directory"
    end

    case File.lstat(expanded_path) do
      {:ok, %{type: :regular}} ->
        case File.read(expanded_path) do
          {:ok, contents} ->
            validate_png!(contents, relative_path)
            Base.encode16(:crypto.hash(:sha256, contents), case: :lower)

          {:error, _reason} ->
            raise ArgumentError, "PNG file is unreadable: #{relative_path}"
        end

      _ ->
        raise ArgumentError, "PNG file is unreadable or not a regular file: #{relative_path}"
    end
  end

  defp validate_png!(contents, relative_path) do
    case contents do
      <<signature::binary-size(8), 13::unsigned-big-32, "IHDR", width::unsigned-big-32,
        height::unsigned-big-32, bit_depth, color_type, compression, filter, interlace,
        ihdr_crc::unsigned-big-32, _rest::binary>> ->
        ihdr_data = binary_part(contents, 12, 17)

        valid_dimensions? =
          width > 0 and height > 0 and width <= @max_png_dimension and
            height <= @max_png_dimension and width * height <= @max_png_pixels

        valid_format? =
          valid_bit_depth?(color_type, bit_depth) and compression == 0 and filter == 0 and
            interlace in [0, 1]

        unless signature == @png_signature and valid_dimensions? and valid_format? and
                 :erlang.crc32(ihdr_data) == ihdr_crc do
          raise ArgumentError, "PNG file has an invalid or incomplete IHDR: #{relative_path}"
        end

      _ ->
        raise ArgumentError, "PNG file has an invalid or incomplete IHDR: #{relative_path}"
    end
  end

  defp valid_bit_depth?(0, depth), do: depth in [1, 2, 4, 8, 16]
  defp valid_bit_depth?(2, depth), do: depth in [8, 16]
  defp valid_bit_depth?(3, depth), do: depth in [1, 2, 4, 8]
  defp valid_bit_depth?(4, depth), do: depth in [8, 16]
  defp valid_bit_depth?(6, depth), do: depth in [8, 16]
  defp valid_bit_depth?(_color_type, _depth), do: false

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
