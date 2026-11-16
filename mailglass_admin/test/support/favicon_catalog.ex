defmodule MailglassAdmin.TestSupport.FaviconCatalog do
  @moduledoc false

  @schema "mailglass.favicon_catalog.v1"
  @repo_root Path.expand("../../..", __DIR__)
  @engines ~w(chromium firefox webkit)
  @schemes ~w(light dark)
  @sizes [16, 24, 32]
  @dprs [1, 2]
  @light_backgrounds [
    %{"id" => "white", "color" => "#ffffff"},
    %{"id" => "offwhite", "color" => "#f9f9fb"},
    %{"id" => "tab-grey", "color" => "#dee1e6"}
  ]
  @dark_backgrounds [
    %{"id" => "chrome", "color" => "#35363a"},
    %{"id" => "black", "color" => "#202124"},
    %{"id" => "purple", "color" => "#2b2a33"}
  ]
  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>
  @png_cap 5_000_000
  @max_png_chunks 1024
  @max_dimension 64
  @light_glass {24, 149, 194}
  @dark_glass {70, 182, 232}
  @light_pane {10, 100, 136}
  @dark_pane {168, 228, 247}

  @manifest_keys ~w(schema catalogId startedAt capturedAt sourceRevision source served producer engines matrix metrics diagnostics limits captures)
  @capture_keys ~w(file engine engineVersion scheme size dpr background width height bytes sha256)
  @metrics %{
    "inkContrastRatio" => 1.15,
    "minimumGlyphWidthFraction" => 0.8,
    "minimumGlyphHeightFraction" => 0.5,
    "stemSampleHeightFraction" => 0.75,
    "minimumGapPhysicalPixelsPerDpr" => 1,
    "minimumLightGlassContrast" => 3.0,
    "minimumGreyGlassContrast" => 2.5,
    "minimumDarkGlassContrast" => 4.5,
    "minimumPaneContrastAt24And32" => 1.3,
    "crossEngineInkMaskIoU" => 0.9
  }

  @doc "Returns failures for one immutable favicon raster catalog."
  def validate_catalog(dir, repo_root) do
    id = Path.basename(dir)

    case File.lstat(dir) do
      {:ok, %File.Stat{type: :directory}} ->
        case read_regular_file(Path.join(dir, "manifest.json")) do
          {:ok, bytes} ->
            case Jason.decode(bytes) do
              {:ok, manifest} when is_map(manifest) -> validate_manifest(dir, repo_root, manifest)
              {:ok, _} -> ["#{id}: manifest must be an object"]
              {:error, reason} -> ["#{id}: manifest is unreadable (#{inspect(reason)})"]
            end

          {:error, reason} ->
            ["#{id}: manifest is unreadable (#{inspect(reason)})"]
        end

      {:ok, _} ->
        ["#{id}: catalog path must be a real directory"]

      {:error, reason} ->
        ["#{id}: catalog directory is unreadable (#{inspect(reason)})"]
    end
  rescue
    _ -> ["#{Path.basename(dir)}: manifest is malformed or cannot be validated safely"]
  end

  @doc "Failures for the pinned source artwork that is distributed with this repository."
  def source_asset_failures(repo_root) do
    with {:ok, %{"shipped" => shipped}} when is_list(shipped) <-
           read_json(Path.join(repo_root, "brandbook/brand.pin.json")) do
      required = %{
        "brandbook/v2/favicon-16-light.png" => {16, 16},
        "brandbook/v2/favicon-16-dark.png" => {16, 16},
        "brandbook/v2/favicon-32-light.png" => {32, 32},
        "brandbook/v2/favicon-32-dark.png" => {32, 32},
        "brandbook/v2/avatar-512-light.png" => {512, 512},
        "brandbook/v2/avatar-512-dark.png" => {512, 512},
        "brandbook/v2/social-card-1280x640.png" => {1280, 640}
      }

      pin_entries = shipped |> Enum.filter(&is_map/1) |> Map.new(&{&1["to"], &1})

      media_failures =
        Enum.flat_map(required, fn {rel, {width, height}} ->
          case File.read(Path.join(repo_root, rel)) do
            {:ok, bytes} ->
              entry = pin_entries[rel]
              expected = %{"w" => width, "h" => height}

              hash_failures =
                if entry && entry["sha256"] == sha256(bytes) &&
                     entry["bytes"] == byte_size(bytes),
                   do: [],
                   else: ["#{rel}: bytes do not match the brand pin"]

              png_failures = png_header_failures(rel, bytes, expected)

              size_failures =
                if rel == "brandbook/v2/social-card-1280x640.png" and
                     byte_size(bytes) >= 1_000_000,
                   do: ["#{rel}: social card must be smaller than 1 MB"],
                   else: []

              hash_failures ++ png_failures ++ size_failures

            {:error, reason} ->
              ["#{rel}: cannot read pinned PNG (#{inspect(reason)})"]
          end
        end)

      media_failures ++ svg_mark_failures(repo_root, pin_entries)
    else
      {:ok, _} -> ["brandbook/brand.pin.json has no shipped asset list"]
      {:error, reason} -> ["brandbook/brand.pin.json is unreadable (#{inspect(reason)})"]
    end
  end

  @doc "Decodes bounded 8-bit RGBA PNG bytes, validating chunk CRCs and all PNG row filters."
  def decode_png(bytes) when is_binary(bytes) and byte_size(bytes) <= @png_cap do
    with <<@png_signature, rest::binary>> <- bytes,
         {:ok, chunks} <- parse_chunks(rest, [], 0),
         [{"IHDR", ihdr} | _] <- chunks,
         <<width::unsigned-big-32, height::unsigned-big-32, 8, 6, 0, 0, 0>> <- ihdr,
         true <- width in 1..@max_dimension and height in 1..@max_dimension,
         idat when is_binary(idat) <-
           chunks
           |> Enum.filter(&(elem(&1, 0) == "IDAT"))
           |> Enum.map(&elem(&1, 1))
           |> IO.iodata_to_binary(),
         {:ok, raw} <- bounded_inflate(idat, (width * 4 + 1) * height),
         {:ok, pixels} <- unfilter_rows(raw, width, height) do
      {:ok, %{width: width, height: height, pixels: pixels}}
    else
      false -> {:error, :png_dimensions_out_of_bounds}
      nil -> {:error, :png_idat_missing}
      {:error, _} = error -> error
      _ -> {:error, :png_malformed_or_unsupported}
    end
  rescue
    _ -> {:error, :png_malformed_or_unsupported}
  end

  def decode_png(_), do: {:error, :png_too_large}

  @doc "Pure raster checks used by focused pale, thin and merged-mark mutation tests."
  def raster_failures(width, height, pixels, background, size, dpr) do
    mask = ink_mask(pixels, width, height, background)
    shape_failures(mask, width, height, size, dpr)
  end

  defp validate_manifest(dir, repo_root, manifest) do
    id = Path.basename(dir)

    schema_failures =
      exact_keys(manifest, @manifest_keys, "#{id} manifest") ++
        check(manifest["schema"] == @schema, "#{id}: schema must be #{@schema}") ++
        check(manifest["catalogId"] == id, "#{id}: catalogId must equal the directory name") ++
        check(
          valid_timestamp?(manifest["startedAt"]),
          "#{id}: startedAt must be an ISO timestamp"
        ) ++
        check(
          valid_timestamp?(manifest["capturedAt"]),
          "#{id}: capturedAt must be an ISO timestamp"
        ) ++
        check(
          manifest["sourceRevision"] == read_pin_commit(repo_root),
          "#{id}: sourceRevision differs from the current pin"
        ) ++
        check(manifest["metrics"] == @metrics, "#{id}: metric definitions are missing or changed") ++
        check(
          manifest["limits"] == %{
            "pngFiles" => 120,
            "totalPngBytes" => @png_cap,
            "engineTimeoutMs" => 90_000
          },
          "#{id}: resource limits differ from the plan"
        )

    source_failures = source_bindings(manifest, repo_root, id)
    engine_failures = engine_bindings(manifest, id)
    matrix_failures = matrix_bindings(manifest, id)
    diag_failures = diagnostics_failures(manifest, id)
    {capture_failures, captures} = capture_bindings(dir, repo_root, manifest, id)
    pixel_failures = pixel_contract_failures(captures, manifest, id)
    file_failures = catalog_files_failures(dir, manifest, id)

    schema_failures ++
      source_failures ++
      engine_failures ++
      matrix_failures ++
      diag_failures ++
      capture_failures ++ pixel_failures ++ file_failures
  end

  defp source_bindings(manifest, repo_root, id) do
    source = manifest["source"]
    served = manifest["served"]
    producer = manifest["producer"]

    expected_source = %{"path" => "brandbook/v2/favicon.svg"}
    expected_served = %{"path" => "mailglass_admin/priv/static/favicon.svg"}
    expected_producer = %{"path" => "mailglass_admin/e2e/favicon-capture.cjs"}

    source_shape = exact_keys(source, ~w(path sha256 bytes), "#{id} source")
    served_shape = exact_keys(served, ~w(path sha256), "#{id} served source")
    producer_shape = exact_keys(producer, ~w(path sha256), "#{id} producer")

    source_shape ++
      served_shape ++
      producer_shape ++
      check(
        is_map(source) and source["path"] == expected_source["path"],
        "#{id}: source path is not the pinned favicon"
      ) ++
      check(
        is_map(served) and served["path"] == expected_served["path"],
        "#{id}: served path is not the Admin favicon"
      ) ++
      check(
        is_map(producer) and producer["path"] == expected_producer["path"],
        "#{id}: producer path is wrong"
      ) ++
      compare_file(repo_root, source, "#{id} source") ++
      compare_file(repo_root, served, "#{id} served") ++
      compare_file(repo_root, producer, "#{id} producer") ++
      case read_json(Path.join(repo_root, "brandbook/brand.pin.json")) do
        {:ok, %{"shipped" => shipped}} when is_list(shipped) ->
          source_path = if is_map(source), do: source["path"], else: nil

          entry =
            Enum.find(shipped, fn
              item when is_map(item) -> item["to"] == source_path
              _ -> false
            end)

          check(
            entry != nil and entry["sha256"] == source["sha256"] and
              entry["bytes"] == source["bytes"],
            "#{id}: source is not bound to the brand pin"
          )

        _ ->
          ["#{id}: brand pin cannot be read"]
      end
  end

  defp engine_bindings(%{"engines" => engines}, id) when is_list(engines) do
    names = Enum.map(engines, fn engine -> if is_map(engine), do: engine["name"], else: nil end)

    check(
      Enum.sort(names) == Enum.sort(@engines),
      "#{id}: engines must be chromium, firefox and webkit exactly once"
    ) ++
      check(length(names) == length(Enum.uniq(names)), "#{id}: duplicate engine entry") ++
      Enum.flat_map(engines, fn
        engine when is_map(engine) ->
          probe = engine["themeProbe"]

          exact_keys(engine, ~w(name version themeProbe), "#{id} engine") ++
            check(engine["name"] in @engines, "#{id}: unknown engine #{inspect(engine["name"])}") ++
            check(
              is_binary(engine["version"]) and String.trim(engine["version"]) != "",
              "#{id}: engine version is missing"
            ) ++
            exact_keys(probe, ~w(lightSha256 darkSha256 different), "#{id} theme probe") ++
            check(
              is_map(probe) and probe["different"] == true and
                probe["lightSha256"] != probe["darkSha256"],
              "#{id}: engine theme probe did not distinguish light and dark"
            )

        _ ->
          ["#{id}: engine entry must be an object"]
      end)
  end

  defp engine_bindings(_manifest, id), do: ["#{id}: engines must be an array"]

  defp matrix_bindings(manifest, id) do
    expected_backgrounds = %{"light" => @light_backgrounds, "dark" => @dark_backgrounds}

    expected = %{
      "schemes" => @schemes,
      "sizes" => @sizes,
      "dprs" => @dprs,
      "backgrounds" => expected_backgrounds,
      "cells" => 108
    }

    exact_keys(manifest["matrix"], Map.keys(expected), "#{id} matrix") ++
      check(
        manifest["matrix"] == expected,
        "#{id}: capture matrix differs from the required 3×2×3×2×3 grid"
      )
  end

  defp diagnostics_failures(manifest, id) do
    diagnostics = manifest["diagnostics"]
    keys = ~w(safariLightArtworkOnDarkSurfaces safariTabChromeObserved note)

    exact_keys(diagnostics, keys, "#{id} diagnostics") ++
      check(
        is_map(diagnostics) and diagnostics["safariTabChromeObserved"] == false,
        "#{id}: Playwright must not claim real Safari tab chrome was observed"
      ) ++
      check(
        is_map(diagnostics) and
          is_binary(diagnostics["note"]) and
          String.contains?(diagnostics["note"], "does not observe real Safari tab chrome"),
        "#{id}: Safari limitation is not disclosed"
      ) ++
      safari_simulation_failures(diagnostics, id)
  end

  defp safari_simulation_failures(%{"safariLightArtworkOnDarkSurfaces" => rows}, id)
       when is_list(rows) do
    expected = Enum.map(@dark_backgrounds, & &1["color"])

    failures =
      check(
        Enum.map(rows, fn row -> if is_map(row), do: row["background"], else: nil end) ==
          expected,
        "#{id}: Safari-risk simulation backgrounds differ"
      ) ++
        Enum.flat_map(rows, fn row ->
          exact_keys(row, ~w(background glassContrast overlapContrast), "#{id} Safari simulation") ++
            diagnostic_ratio_failures(row, id)
        end)

    failures
  end

  defp safari_simulation_failures(_, id), do: ["#{id}: Safari-risk simulation must be an array"]

  defp diagnostic_ratio_failures(row, id) when is_map(row) do
    bg = parse_hex(row["background"])
    glass = row["glassContrast"]
    overlap = row["overlapContrast"]

    check(is_number(glass), "#{id}: Safari glass diagnostic must be numeric") ++
      check(is_number(overlap), "#{id}: Safari overlap diagnostic must be numeric") ++
      check(
        is_number(glass) and abs(glass - contrast(@light_glass, bg)) < 0.001,
        "#{id}: Safari glass diagnostic is not derived from the light SVG fill"
      ) ++
      check(
        is_number(overlap) and abs(overlap - contrast(@light_pane, bg)) < 0.001,
        "#{id}: Safari overlap diagnostic is not derived from the light SVG fill"
      ) ++
      check(is_number(glass) and glass >= 3.0, "#{id}: Safari-risk glass contrast is below 3.0") ++
      check(
        is_number(overlap) and overlap >= 1.5,
        "#{id}: Safari-risk overlap contrast is below 1.5"
      )
  end

  defp diagnostic_ratio_failures(_, id), do: ["#{id}: Safari simulation row must be an object"]

  defp capture_bindings(dir, _repo_root, %{"captures" => records} = manifest, id)
       when is_list(records) do
    errors = []

    {failures, decoded} =
      Enum.reduce(records, {errors, []}, fn
        record, {failures, decoded} when is_map(record) ->
          file = record["file"]

          relative_safe =
            is_binary(file) and file not in ["", ".", ".."] and Path.basename(file) == file and
              not String.contains?(file, "\\")

          valid_cell =
            record["engine"] in @engines and record["scheme"] in @schemes and
              record["size"] in @sizes and record["dpr"] in @dprs

          valid_dimensions =
            valid_cell and is_integer(record["width"]) and is_integer(record["height"]) and
              record["width"] == record["size"] * record["dpr"] and
              record["height"] == record["size"] * record["dpr"]

          record_failures =
            exact_keys(record, @capture_keys, "#{id} capture") ++
              check(relative_safe, "#{id}: capture path is not a basename") ++
              check(
                record["file"] == capture_filename(record),
                "#{id}: capture filename does not encode its matrix cell"
              ) ++
              check(
                valid_cell,
                "#{id}: capture cell has an unknown dimension"
              ) ++
              check(
                valid_dimensions,
                "#{id}: PNG dimensions do not match CSS size and DPR"
              )

          path =
            if relative_safe, do: Path.join(dir, file), else: Path.join(dir, "__invalid__.png")

          case read_regular_file(path) do
            {:ok, bytes} ->
              hash_failures =
                check(
                  byte_size(bytes) == record["bytes"],
                  "#{id}/#{file}: byte count differs from manifest"
                ) ++
                  check(
                    sha256(bytes) == record["sha256"],
                    "#{id}/#{file}: SHA-256 differs from manifest"
                  )

              case decode_png(bytes) do
                {:ok, png} ->
                  dimension_failures =
                    check(
                      png.width == record["width"] and png.height == record["height"],
                      "#{id}/#{file}: decoded IHDR dimensions differ from manifest"
                    )

                  next_decoded =
                    if record_failures == [],
                      do: [%{record: record, png: png} | decoded],
                      else: decoded

                  {failures ++ record_failures ++ hash_failures ++ dimension_failures,
                   next_decoded}

                {:error, reason} ->
                  {failures ++
                     record_failures ++
                     hash_failures ++ ["#{id}/#{file}: PNG decode failed (#{inspect(reason)})"],
                   decoded}
              end

            {:error, reason} ->
              {failures ++
                 record_failures ++
                 ["#{id}/#{file}: PNG is missing or unreadable (#{inspect(reason)})"], decoded}
          end

        _record, {failures, decoded} ->
          {failures ++ ["#{id}: capture entry must be an object"], decoded}
      end)

    cells = records |> Enum.filter(&is_map/1) |> Enum.map(&cell_key/1)

    versions =
      case manifest["engines"] do
        engines when is_list(engines) ->
          engines
          |> Enum.filter(&is_map/1)
          |> Map.new(&{&1["name"], &1["version"]})

        _ ->
          %{}
      end

    version_failures =
      records
      |> Enum.filter(&is_map/1)
      |> Enum.flat_map(fn record ->
        check(
          record["engineVersion"] == versions[record["engine"]],
          "#{id}/#{record["file"]}: engine version differs from catalog"
        )
      end)

    duplicate_failures =
      check(length(cells) == length(Enum.uniq(cells)), "#{id}: duplicate capture cells")

    count_failures =
      check(
        length(records) == 108 and length(records) <= 120,
        "#{id}: expected 108 capture records, within the 120 PNG cap"
      )

    byte_failures =
      check(
        records
        |> Enum.filter(&is_map/1)
        |> Enum.map(fn record ->
          if is_integer(record["bytes"]) and record["bytes"] >= 0, do: record["bytes"], else: 0
        end)
        |> Enum.sum() <= @png_cap,
        "#{id}: capture PNG bytes exceed the 5 MB cap"
      )

    expected_cells = expected_cell_keys()

    matrix_failures =
      check(
        MapSet.new(cells) == MapSet.new(expected_cells),
        "#{id}: capture records omit or add a required matrix cell"
      )

    {failures ++
       version_failures ++
       duplicate_failures ++ count_failures ++ byte_failures ++ matrix_failures, decoded}
  end

  defp capture_bindings(_dir, _repo_root, _manifest, id),
    do: {["#{id}: captures must be an array"], []}

  defp pixel_contract_failures(decoded, manifest, id) do
    fills = svg_fill_failures(manifest, id)

    analyzed =
      Enum.map(decoded, fn %{record: record, png: png} = capture ->
        background = record["background"]
        mask = ink_mask(png.pixels, png.width, png.height, background)
        shape = shape_failures(mask, png.width, png.height, record["size"], record["dpr"])
        color_failures = color_metric_failures(png.pixels, record, background)

        alpha_failures =
          check(
            all_opaque?(png.pixels),
            "#{id}/#{record["file"]}: capture tile contains transparency"
          )

        {Map.put(capture, :mask, mask), shape ++ color_failures ++ alpha_failures}
      end)

    shape_failures = Enum.flat_map(analyzed, fn {_capture, errors} -> errors end)
    iou_failures = cross_engine_iou_failures(Enum.map(analyzed, &elem(&1, 0)), id)
    source_fill_fails = fills
    shape_failures ++ iou_failures ++ source_fill_fails
  end

  defp color_metric_failures(pixels, record, background) do
    expected =
      if record["scheme"] == "light",
        do: {@light_glass, @light_pane, @dark_glass, @dark_pane},
        else: {@dark_glass, @dark_pane, @light_glass, @light_pane}

    {glass, pane, wrong_glass, wrong_pane} = expected
    glass_pixel = nearest_rgb(pixels, glass)
    pane_pixel = nearest_rgb(pixels, pane)
    bg = parse_hex(background)
    glass_ratio = contrast(glass_pixel, bg)
    pane_to_glass = contrast(pane_pixel, glass_pixel)
    correct_glass_distance = distance(glass_pixel, glass)
    wrong_glass_distance = distance(nearest_rgb(pixels, wrong_glass), wrong_glass)
    correct_pane_distance = distance(pane_pixel, pane)
    wrong_pane_distance = distance(nearest_rgb(pixels, wrong_pane), wrong_pane)

    glass_min =
      if record["scheme"] == "dark",
        do: 4.5,
        else: if(background == "#dee1e6", do: 2.5, else: 3.0)

    file = record["file"]

    check(
      glass_ratio >= glass_min,
      "#{file}: glass contrast #{Float.round(glass_ratio, 3)} is below #{glass_min}"
    ) ++
      check(
        record["size"] < 24 or pane_to_glass >= 1.3,
        "#{file}: pane-to-glass contrast #{Float.round(pane_to_glass, 3)} is below 1.3"
      ) ++
      check(
        correct_glass_distance <= wrong_glass_distance,
        "#{file}: raster does not use the matching scheme's glass color"
      ) ++
      check(
        correct_pane_distance <= wrong_pane_distance,
        "#{file}: raster does not use the matching scheme's pane color"
      )
  end

  defp svg_fill_failures(_manifest, id) do
    source = Path.join(@repo_root, "brandbook/v2/favicon.svg")

    case File.read(source) do
      {:ok, bytes} ->
        text = String.upcase(bytes)
        expected = ["#1895C2", "#0A6488", "#46B6E8", "#A8E4F7"]

        check(
          Enum.all?(expected, &String.contains?(text, &1)),
          "#{id}: pinned SVG fill colors differ from metric authorities"
        )

      _ ->
        ["#{id}: pinned SVG is unreadable for fill-color validation"]
    end
  end

  defp cross_engine_iou_failures(captures, id) do
    captures
    |> Enum.group_by(fn %{record: record} ->
      {record["scheme"], record["size"], record["dpr"], record["background"]}
    end)
    |> Enum.flat_map(fn {cell, group} ->
      pairs =
        for first <- group,
            second <- group,
            first.record["engine"] < second.record["engine"],
            do: {first, second}

      check(length(group) == 3, "#{id}: missing engine capture for #{inspect(cell)}") ++
        Enum.flat_map(pairs, fn {first, second} ->
          intersection = MapSet.size(MapSet.intersection(first.mask, second.mask))
          union = MapSet.size(MapSet.union(first.mask, second.mask))
          iou = if union == 0, do: 0.0, else: intersection / union

          check(
            iou >= 0.9,
            "#{id}: cross-engine ink-mask IoU #{Float.round(iou, 3)} is below 0.9 for #{inspect(cell)}"
          )
        end)
    end)
  end

  defp shape_failures(mask, width, height, size, dpr) do
    points = MapSet.to_list(mask)

    if points == [] do
      ["raster has no visible ink"]
    else
      xs = Enum.map(points, &elem(&1, 0))
      ys = Enum.map(points, &elem(&1, 1))
      min_x = Enum.min(xs)
      max_x = Enum.max(xs)
      min_y = Enum.min(ys)
      max_y = Enum.max(ys)
      glyph_width = max_x - min_x + 1
      glyph_height = max_y - min_y + 1
      sample_y = min_y + round((glyph_height - 1) * 0.75)

      runs =
        x_runs(
          Enum.filter(points, &(elem(&1, 1) == sample_y))
          |> Enum.map(&elem(&1, 0))
          |> Enum.sort()
        )

      gaps =
        runs
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [{_a, end_a}, {start_b, _b}] -> start_b - end_a - 1 end)

      check(glyph_width >= width * 0.8, "raster glyph width #{glyph_width}/#{width} is below 80%") ++
        check(
          glyph_height >= height * 0.5,
          "raster glyph height #{glyph_height}/#{height} is below 50%"
        ) ++
        check(
          length(runs) == 3,
          "raster has #{length(runs)} stem runs at 75% glyph height, expected 3"
        ) ++
        check(
          Enum.all?(gaps, &(&1 >= dpr)),
          "raster stem opening is smaller than one physical pixel per DPR"
        ) ++
        check(size == width / dpr, "raster dimensions do not match logical size and DPR")
    end
  end

  defp ink_mask(pixels, width, height, background) do
    bg = parse_hex(background)

    {mask, _index} =
      for <<r, g, b, _a <- pixels>>, reduce: {MapSet.new(), 0} do
        {mask, index} ->
          pixel = {r, g, b}
          x = rem(index, width)
          y = div(index, width)
          next = if contrast(pixel, bg) >= 1.15, do: MapSet.put(mask, {x, y}), else: mask
          {next, index + 1}
      end

    if MapSet.size(mask) <= width * height, do: mask, else: MapSet.new()
  end

  defp x_runs([]), do: []
  defp x_runs([first | rest]), do: x_runs(rest, first, first, [])
  defp x_runs([], start, last, runs), do: Enum.reverse([{start, last} | runs])
  defp x_runs([x | rest], start, last, runs) when x == last + 1, do: x_runs(rest, start, x, runs)
  defp x_runs([x | rest], start, last, runs), do: x_runs(rest, x, x, [{start, last} | runs])

  defp nearest_rgb(pixels, target) do
    nearest_rgb_bytes(pixels, target, nil, 1.0e100)
  end

  defp nearest_rgb_bytes(<<>>, _target, best, _distance), do: best

  defp nearest_rgb_bytes(<<r, g, b, _a, rest::binary>>, target, best, best_distance) do
    pixel = {r, g, b}
    candidate_distance = distance(pixel, target)

    if candidate_distance < best_distance,
      do: nearest_rgb_bytes(rest, target, pixel, candidate_distance),
      else: nearest_rgb_bytes(rest, target, best, best_distance)
  end

  defp distance({r, g, b}, {x, y, z}),
    do: :math.sqrt((r - x) * (r - x) + (g - y) * (g - y) + (b - z) * (b - z))

  defp contrast(first, second) when is_binary(second), do: contrast(first, parse_hex(second))

  defp contrast(first, second) do
    a = luminance(first)
    b = luminance(second)
    (max(a, b) + 0.05) / (min(a, b) + 0.05)
  end

  defp luminance({r, g, b}) do
    [r, g, b]
    |> Enum.map(fn channel ->
      value = channel / 255
      if value <= 0.04045, do: value / 12.92, else: :math.pow((value + 0.055) / 1.055, 2.4)
    end)
    |> then(fn [r, g, b] -> r * 0.2126 + g * 0.7152 + b * 0.0722 end)
  end

  defp parse_hex("#" <> <<r1, r2, g1, g2, b1, b2>>) do
    {String.to_integer(<<r1, r2>>, 16), String.to_integer(<<g1, g2>>, 16),
     String.to_integer(<<b1, b2>>, 16)}
  end

  defp parse_hex(_), do: {0, 0, 0}

  defp all_opaque?(pixels), do: all_opaque?(pixels, true)
  defp all_opaque?(<<>>, result), do: result

  defp all_opaque?(<<_r, _g, _b, a, rest::binary>>, result),
    do: all_opaque?(rest, result and a == 255)

  defp expected_cell_keys do
    for engine <- @engines,
        scheme <- @schemes,
        size <- @sizes,
        dpr <- @dprs,
        background <- if(scheme == "light", do: @light_backgrounds, else: @dark_backgrounds),
        do: {engine, scheme, size, dpr, background["color"]}
  end

  defp cell_key(record),
    do: {record["engine"], record["scheme"], record["size"], record["dpr"], record["background"]}

  defp capture_filename(record) do
    backgrounds = if record["scheme"] == "light", do: @light_backgrounds, else: @dark_backgrounds
    background = Enum.find(backgrounds, &(&1["color"] == record["background"]))
    background_id = if background, do: background["id"], else: "unknown"

    "#{record["engine"]}__#{record["scheme"]}__#{record["size"]}__#{record["dpr"]}x__#{background_id}.png"
  end

  defp catalog_files_failures(dir, manifest, id) do
    expected =
      ["manifest.json" | Enum.map(manifest["captures"] || [], & &1["file"])] |> Enum.sort()

    actual = Path.join(dir, "*") |> Path.wildcard() |> Enum.map(&Path.basename/1) |> Enum.sort()
    check(actual == expected, "#{id}: catalog contains missing or unlisted files")
  end

  defp svg_mark_failures(repo_root, pin_entries) do
    Enum.flat_map(
      [
        "brandbook/v2/mailglass-mark-light.svg",
        "brandbook/v2/mailglass-mark-dark.svg",
        "brandbook/v2/favicon.ico"
      ],
      fn rel ->
        case File.read(Path.join(repo_root, rel)) do
          {:ok, bytes} ->
            entry = pin_entries[rel]

            check(
              entry != nil and entry["sha256"] == sha256(bytes) and
                entry["bytes"] == byte_size(bytes),
              "#{rel}: bytes do not match the brand pin"
            )

          {:error, reason} ->
            ["#{rel}: cannot read pinned source asset (#{inspect(reason)})"]
        end
      end
    )
  end

  defp compare_file(root, map, label) when is_map(map) do
    rel = map["path"]
    path = if is_binary(rel), do: Path.expand(rel, root), else: ""

    if is_binary(rel) and path != root and String.starts_with?(path, root <> "/") do
      case File.read(path) do
        {:ok, bytes} ->
          check(map["sha256"] == sha256(bytes), "#{label}: SHA-256 differs from current file") ++
            if(Map.has_key?(map, "bytes"),
              do:
                check(
                  map["bytes"] == byte_size(bytes),
                  "#{label}: byte count differs from current file"
                ),
              else: []
            )

        {:error, reason} ->
          ["#{label}: file is unreadable (#{inspect(reason)})"]
      end
    else
      ["#{label}: path is unsafe"]
    end
  end

  defp compare_file(_root, _map, label), do: ["#{label}: binding must be an object"]

  defp read_pin_commit(root) do
    with {:ok, pin} <- read_json(Path.join(root, "brandbook/brand.pin.json")), do: pin["commit"]
  end

  defp read_json(path) do
    case File.read(path) do
      {:ok, bytes} -> Jason.decode(bytes)
      error -> error
    end
  end

  defp read_regular_file(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular}} -> File.read(path)
      {:ok, _stat} -> {:error, :not_regular_file}
      {:error, reason} -> {:error, reason}
    end
  end

  defp exact_keys(map, keys, label) when is_map(map) do
    check(
      Enum.sort(Map.keys(map)) == Enum.sort(keys),
      "#{label}: object has unexpected or missing keys"
    )
  end

  defp exact_keys(_, _keys, label), do: ["#{label}: must be an object"]

  defp valid_timestamp?(value) when is_binary(value),
    do: match?({:ok, _, _}, DateTime.from_iso8601(value))

  defp valid_timestamp?(_), do: false

  defp check(true, _message), do: []
  defp check(false, message), do: [message]
  defp check(nil, message), do: [message]

  defp sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

  defp png_header_failures(file, bytes, capture) do
    case png_ihdr(bytes) do
      {:ok, %{width: w, height: h}} ->
        check(
          w == capture["w"] and h == capture["h"],
          "#{file}: PNG dimensions differ from expected #{capture["w"]}x#{capture["h"]}"
        )

      {:error, reason} ->
        ["#{file}: PNG header is invalid (#{inspect(reason)})"]
    end
  end

  defp png_ihdr(
         <<@png_signature, 13::unsigned-big-32, "IHDR", width::unsigned-big-32,
           height::unsigned-big-32, bit_depth, color_type, compression, filter, interlace,
           crc::unsigned-big-32, _rest::binary>>
       ) do
    ihdr =
      <<"IHDR", width::unsigned-big-32, height::unsigned-big-32, bit_depth, color_type,
        compression, filter, interlace>>

    valid =
      width > 0 and height > 0 and width <= 8192 and height <= 8192 and
        bit_depth in [1, 2, 4, 8, 16] and color_type in [0, 2, 3, 4, 6] and
        compression == 0 and filter == 0 and interlace in [0, 1] and
        :erlang.crc32(ihdr) == crc

    if valid, do: {:ok, %{width: width, height: height}}, else: {:error, :ihdr_invalid}
  end

  defp png_ihdr(_), do: {:error, :ihdr_missing_or_truncated}

  defp parse_chunks(<<>>, acc, _count) do
    chunks = Enum.reverse(acc)
    types = Enum.map(chunks, &elem(&1, 0))

    cond do
      List.first(types) != "IHDR" -> {:error, :ihdr_order}
      List.last(types) != "IEND" -> {:error, :iend_missing}
      Enum.count(types, &(&1 == "IHDR")) != 1 -> {:error, :ihdr_duplicate}
      Enum.count(types, &(&1 == "IEND")) != 1 -> {:error, :iend_duplicate}
      not Enum.member?(types, "IDAT") -> {:error, :idat_missing}
      true -> {:ok, chunks}
    end
  end

  defp parse_chunks(<<length::unsigned-big-32, rest::binary>>, acc, count)
       when length <= @png_cap and count < @max_png_chunks do
    if byte_size(rest) < length + 8 do
      {:error, :chunk_truncated}
    else
      <<type::binary-size(4), data::binary-size(length), expected_crc::unsigned-big-32,
        tail::binary>> = rest

      if :erlang.crc32(type <> data) != expected_crc do
        {:error, :chunk_crc}
      else
        chunk = {type, data}

        if type == "IEND" and tail != <<>>,
          do: {:error, :trailing_bytes},
          else: parse_chunks(tail, [chunk | acc], count + 1)
      end
    end
  end

  defp parse_chunks(_rest, _acc, count) when count >= @max_png_chunks,
    do: {:error, :png_chunk_count_exceeded}

  defp parse_chunks(_, _acc, _count), do: {:error, :chunk_malformed}

  defp bounded_inflate(data, expected) do
    z = :zlib.open()
    :ok = :zlib.inflateInit(z)

    try do
      inflate_chunks(z, data, [], 0, expected)
    after
      :zlib.inflateEnd(z)
      :zlib.close(z)
    end
  end

  defp inflate_chunks(z, input, acc, size, cap) do
    case :zlib.safeInflate(z, input) do
      {status, output} when status in [:continue, :finished] ->
        binary = IO.iodata_to_binary(output)
        next_size = size + byte_size(binary)

        if next_size > cap do
          {:error, :decompressed_size_exceeds_ihdr}
        else
          next = [binary | acc]

          if status == :finished,
            do: {:ok, next |> Enum.reverse() |> IO.iodata_to_binary()},
            else: inflate_chunks(z, <<>>, next, next_size, cap)
        end

      _ ->
        {:error, :zlib_dictionary_or_malformed}
    end
  end

  defp unfilter_rows(raw, width, height) do
    stride = width * 4
    expected = (stride + 1) * height

    if byte_size(raw) != expected,
      do: {:error, :decoded_length_mismatch},
      else: do_unfilter(raw, stride, height, <<>>, [])
  end

  defp do_unfilter(<<>>, _stride, 0, _previous, rows),
    do: {:ok, rows |> Enum.reverse() |> IO.iodata_to_binary()}

  defp do_unfilter(raw, stride, count, previous, rows)
       when count > 0 and byte_size(raw) >= stride + 1 do
    <<filter, row::binary-size(stride), rest::binary>> = raw

    if filter in 0..4 do
      decoded = unfilter_row(filter, row, previous, 4)
      do_unfilter(rest, stride, count - 1, decoded, [decoded | rows])
    else
      {:error, :row_filter_invalid}
    end
  end

  defp do_unfilter(_, _stride, _count, _previous, _rows), do: {:error, :row_filter_invalid}

  defp unfilter_row(0, row, _previous, _bpp), do: row

  defp unfilter_row(filter, row, previous, bpp) do
    raw = :binary.bin_to_list(row)
    prev = :binary.bin_to_list(previous)

    {result, _rev} =
      Enum.with_index(raw)
      |> Enum.reduce({[], []}, fn {value, index}, {decoded, rev} ->
        left = if index >= bpp, do: Enum.at(rev, bpp - 1), else: 0
        up = Enum.at(prev, index, 0)
        up_left = if index >= bpp, do: Enum.at(prev, index - bpp, 0), else: 0

        predictor =
          case filter do
            1 -> left
            2 -> up
            3 -> div(left + up, 2)
            4 -> paeth(left, up, up_left)
          end

        byte = rem(value + predictor, 256)
        {[byte | decoded], [byte | rev]}
      end)

    result |> Enum.reverse() |> :erlang.list_to_binary()
  end

  defp paeth(a, b, c) do
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)

    cond do
      pa <= pb and pa <= pc -> a
      pb <= pc -> b
      true -> c
    end
  end
end
