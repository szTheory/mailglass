defmodule MailglassAdmin.FaviconCatalogTest do
  use ExUnit.Case, async: false

  alias MailglassAdmin.TestSupport.FaviconCatalog

  @repo_root Path.expand("../../..", __DIR__)
  @catalog_root Path.join(@repo_root, ".planning/research/brand-v2-adoption/favicon-catalog")
  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  test "pinned source media has valid hashes, PNG dimensions and bounded social-card size" do
    assert FaviconCatalog.source_asset_failures(@repo_root) == []
  end

  test "social preview handoff has complete URLs, read-back checks and no personal avatar step" do
    checklist =
      @repo_root
      |> Path.join(".planning/research/brand-v2-adoption/SOCIAL-UPLOAD-CHECKLIST.md")
      |> File.read!()

    assert checklist =~ "https://github.com/szTheory/mailglass/settings"
    assert checklist =~ "https://github.com/szTheory/mailglass"
    assert checklist =~ "usesCustomOpenGraphImage"
    assert checklist =~ "openGraphImageUrl"
    assert checklist =~ "1280 × 640"
    assert checklist =~ "No image was uploaded"
    assert checklist =~ "Do not upload the artwork to https://github.com/settings/profile"
    assert checklist =~ "Safari tab appearance remains unobserved"
  end

  test "malformed nested manifest values fail closed" do
    dir = temporary_catalog()

    manifest = %{
      "engines" => [nil],
      "diagnostics" => %{
        "safariLightArtworkOnDarkSurfaces" => [],
        "safariTabChromeObserved" => false,
        "note" => 42
      },
      "captures" => [nil]
    }

    File.write!(Path.join(dir, "manifest.json"), Jason.encode!(manifest))
    on_exit(fn -> File.rm_rf!(dir) end)

    failures = FaviconCatalog.validate_catalog(dir, @repo_root)

    assert Enum.any?(failures, &String.contains?(&1, "engine entry must be an object"))
    assert Enum.any?(failures, &String.contains?(&1, "capture entry must be an object"))
    assert Enum.any?(failures, &String.contains?(&1, "Safari limitation is not disclosed"))
  end

  test "catalog manifests and capture PNGs reject symlinks and dot paths" do
    root = temporary_catalog()
    catalog = Path.join(root, "catalog")
    File.mkdir_p!(catalog)
    on_exit(fn -> File.rm_rf!(root) end)

    manifest_catalog = Path.join(root, "manifest-link-catalog")
    File.mkdir_p!(manifest_catalog)
    outside_manifest = Path.join(root, "outside.json")
    File.write!(outside_manifest, "{}")
    File.ln_s!(outside_manifest, Path.join(manifest_catalog, "manifest.json"))

    manifest_failures = FaviconCatalog.validate_catalog(manifest_catalog, @repo_root)

    assert Enum.any?(
             manifest_failures,
             &String.contains?(&1, "manifest is unreadable (:not_regular_file)")
           )

    outside = Path.join(root, "outside.png")
    image = png(1, 1, <<0, 24, 149, 194, 255>>)
    File.write!(outside, image)

    filename = "chromium__light__16__1x__white.png"
    File.ln_s!(outside, Path.join(catalog, filename))

    manifest = catalog_manifest(catalog, filename, image)
    File.write!(Path.join(catalog, "manifest.json"), Jason.encode!(manifest))

    failures = FaviconCatalog.validate_catalog(catalog, @repo_root)

    assert Enum.any?(
             failures,
             &String.contains?(&1, "PNG is missing or unreadable (:not_regular_file)")
           )

    dot_catalog = Path.join(root, "dot-catalog")
    File.mkdir_p!(dot_catalog)
    dot_manifest = catalog_manifest(dot_catalog, "..", image)
    File.write!(Path.join(dot_catalog, "manifest.json"), Jason.encode!(dot_manifest))

    dot_failures = FaviconCatalog.validate_catalog(dot_catalog, @repo_root)
    assert Enum.any?(dot_failures, &String.contains?(&1, "capture path is not a basename"))
  end

  test "every committed favicon catalog is source-bound and independently pixel-validated" do
    dirs = catalog_dirs()

    assert dirs != [],
           "capture a favicon catalog with node mailglass_admin/e2e/favicon-capture.cjs --capture"

    for dir <- dirs do
      assert FaviconCatalog.validate_catalog(dir, @repo_root) == [],
             "invalid #{Path.basename(dir)}: #{inspect(FaviconCatalog.validate_catalog(dir, @repo_root))}"
    end
  end

  test "thin, pale and merged-blob mark mutants fail the raster shape contract" do
    good =
      raster(32, 32, fn x, y ->
        cond do
          y in 8..23 and x in 2..5 -> {24, 149, 194}
          y in 8..23 and x in 14..17 -> {10, 100, 136}
          y in 8..23 and x in 26..29 -> {24, 149, 194}
          true -> {255, 255, 255}
        end
      end)

    assert FaviconCatalog.raster_failures(32, 32, good, "#ffffff", 32, 1) == []

    thin =
      raster(32, 32, fn x, y ->
        if y in 12..19 and x in [3, 16, 28], do: {24, 149, 194}, else: {255, 255, 255}
      end)

    assert Enum.any?(
             FaviconCatalog.raster_failures(32, 32, thin, "#ffffff", 32, 1),
             &String.contains?(&1, "height")
           )

    pale =
      raster(32, 32, fn x, y ->
        if y in 8..23 and (x in 2..5 or x in 14..17 or x in 26..29),
          do: {250, 250, 252},
          else: {255, 255, 255}
      end)

    assert FaviconCatalog.raster_failures(32, 32, pale, "#ffffff", 32, 1) != []

    blob =
      raster(32, 32, fn x, y ->
        if y in 8..23 and x in 2..29, do: {24, 149, 194}, else: {255, 255, 255}
      end)

    assert Enum.any?(
             FaviconCatalog.raster_failures(32, 32, blob, "#ffffff", 32, 1),
             &String.contains?(&1, "stem runs")
           )
  end

  test "a valid oversized raster is refused before decompression" do
    oversized = png(65, 65, :binary.copy(<<0>>, (65 * 4 + 1) * 65))
    assert {:error, :png_dimensions_out_of_bounds} = FaviconCatalog.decode_png(oversized)
  end

  test "a valid PNG with too many chunks is refused before parsing the remaining chunks" do
    ihdr = <<1::unsigned-big-32, 1::unsigned-big-32, 8, 6, 0, 0, 0>>
    ancillary = for _ <- 1..1025, into: <<>>, do: chunk("tEXt", <<>>)
    idat = chunk("IDAT", :zlib.compress(<<0, 24, 149, 194, 255>>))
    bytes = @png_signature <> chunk("IHDR", ihdr) <> ancillary <> idat <> chunk("IEND", <<>>)

    assert {:error, :png_chunk_count_exceeded} = FaviconCatalog.decode_png(bytes)
  end

  test "PNG decoder applies all five row filters" do
    source_rows =
      for y <- 1..5 do
        for x <- 1..2, into: <<>> do
          <<y * 10 + x, y * 20 + x, y * 30 + x, 255>>
        end
      end

    filtered =
      source_rows
      |> Enum.with_index()
      |> Enum.reduce({<<>>, <<>>}, fn {row, index}, {scanlines, previous} ->
        filter = rem(index, 5)
        encoded = filter_row(filter, row, previous, 4)
        {scanlines <> <<filter>> <> encoded, row}
      end)
      |> elem(0)

    assert {:ok, %{width: 2, height: 5, pixels: pixels}} =
             FaviconCatalog.decode_png(png(2, 5, filtered))

    assert pixels == IO.iodata_to_binary(source_rows)
  end

  test "catalog mutation cases reject stale source, forged metrics, missing engines and duplicate cells" do
    dir = catalog!()

    stale = copy_catalog(dir)
    mutate_manifest(stale, &put_in(&1, ["source", "sha256"], String.duplicate("0", 64)))
    assert_invalid(stale, "source")

    forged = copy_catalog(dir)
    mutate_manifest(forged, &put_in(&1, ["metrics", "inkContrastRatio"], 0.1))
    assert_invalid(forged, "metric definitions")

    missing_engine = copy_catalog(dir)

    mutate_manifest(
      missing_engine,
      fn manifest ->
        update_in(manifest["engines"], fn engines ->
          Enum.reject(engines, fn engine -> engine["name"] == "firefox" end)
        end)
      end
    )

    assert_invalid(missing_engine, "engines must be")

    duplicate = copy_catalog(dir)

    mutate_manifest(duplicate, fn manifest ->
      update_in(manifest["captures"], &(&1 ++ [hd(&1)]))
    end)

    assert_invalid(duplicate, "duplicate capture cells")
  end

  test "changed pixels, path traversal and unlisted files are refused" do
    dir = catalog!()
    manifest = read_manifest(dir)
    capture = hd(manifest["captures"])

    changed = copy_catalog(dir)
    image = Path.join(changed, capture["file"])
    bytes = File.read!(image)
    offset = min(55, byte_size(bytes) - 20)
    <<before::binary-size(offset), byte, after_bytes::binary>> = bytes
    File.write!(image, before <> <<Bitwise.bxor(byte, 1)>> <> after_bytes)
    assert_invalid(changed, "SHA-256 differs")

    traversed = copy_catalog(dir)
    mutate_manifest(traversed, &put_in(&1, ["captures", Access.at(0), "file"], "../escape.png"))
    assert_invalid(traversed, "basename")

    unlisted = copy_catalog(dir)
    File.write!(Path.join(unlisted, "extra.png"), "unlisted")
    assert_invalid(unlisted, "unlisted files")
  end

  defp catalog_dirs do
    @catalog_root
    |> Path.join("favicon-*")
    |> Path.wildcard()
    |> Enum.filter(&File.dir?/1)
    |> Enum.sort()
  end

  defp temporary_catalog do
    path =
      Path.join(
        System.tmp_dir!(),
        "favicon-catalog-contract-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end

  defp catalog_manifest(dir, file, image) do
    pin = @repo_root |> Path.join("brandbook/brand.pin.json") |> File.read!() |> Jason.decode!()
    source = manifest_binding("brandbook/v2/favicon.svg", true)
    served = manifest_binding("mailglass_admin/priv/static/favicon.svg", false)
    producer = manifest_binding("mailglass_admin/e2e/favicon-capture.cjs", false)

    capture = %{
      "file" => file,
      "engine" => "chromium",
      "engineVersion" => "test",
      "scheme" => "light",
      "size" => 16,
      "dpr" => 1,
      "background" => "#ffffff",
      "width" => 16,
      "height" => 16,
      "bytes" => byte_size(image),
      "sha256" => Base.encode16(:crypto.hash(:sha256, image), case: :lower)
    }

    %{
      "schema" => "mailglass.favicon_catalog.v1",
      "catalogId" => Path.basename(dir),
      "startedAt" => DateTime.to_iso8601(DateTime.utc_now()),
      "capturedAt" => DateTime.to_iso8601(DateTime.utc_now()),
      "sourceRevision" => pin["commit"],
      "source" => source,
      "served" => served,
      "producer" => producer,
      "engines" => [],
      "matrix" => %{},
      "metrics" => %{},
      "diagnostics" => %{
        "safariLightArtworkOnDarkSurfaces" => [],
        "safariTabChromeObserved" => false,
        "note" => "does not observe real Safari tab chrome"
      },
      "limits" => %{},
      "captures" => [capture]
    }
  end

  defp manifest_binding(path, include_bytes?) do
    bytes = @repo_root |> Path.join(path) |> File.read!()

    binding = %{
      "path" => path,
      "sha256" => Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)
    }

    if include_bytes?, do: Map.put(binding, "bytes", byte_size(bytes)), else: binding
  end

  defp catalog!, do: List.last(catalog_dirs()) || flunk("no captured favicon catalog exists")

  defp copy_catalog(source) do
    target =
      Path.join(System.tmp_dir!(), "favicon-catalog-test-#{System.unique_integer([:positive])}")

    File.mkdir_p!(target)

    for file <- Path.wildcard(Path.join(source, "*")),
        do: File.cp!(file, Path.join(target, Path.basename(file)))

    on_exit(fn -> File.rm_rf!(target) end)
    target
  end

  defp read_manifest(dir),
    do: dir |> Path.join("manifest.json") |> File.read!() |> Jason.decode!()

  defp mutate_manifest(dir, fun) do
    dir
    |> Path.join("manifest.json")
    |> File.write!(Jason.encode!(fun.(read_manifest(dir)), pretty: true) <> "\n")
  end

  defp assert_invalid(dir, contains) do
    failures = FaviconCatalog.validate_catalog(dir, @repo_root)
    assert Enum.any?(failures, &String.contains?(&1, contains)), inspect(failures)
  end

  defp raster(width, height, pixel_fun) do
    for y <- 0..(height - 1), x <- 0..(width - 1), into: <<>> do
      {r, g, b} = pixel_fun.(x, y)
      <<r, g, b, 255>>
    end
  end

  defp png(width, height, scanlines) do
    ihdr = <<width::unsigned-big-32, height::unsigned-big-32, 8, 6, 0, 0, 0>>

    @png_signature <>
      chunk("IHDR", ihdr) <> chunk("IDAT", :zlib.compress(scanlines)) <> chunk("IEND", <<>>)
  end

  defp chunk(type, data) do
    type_data = type <> data

    <<byte_size(data)::unsigned-big-32, type_data::binary,
      :erlang.crc32(type_data)::unsigned-big-32>>
  end

  defp filter_row(0, row, _previous, _bpp), do: row

  defp filter_row(filter, row, previous, bpp) do
    raw = :binary.bin_to_list(row)
    prev = :binary.bin_to_list(previous)

    raw
    |> Enum.with_index()
    |> Enum.map(fn {value, index} ->
      left = if index >= bpp, do: Enum.at(raw, index - bpp), else: 0
      up = Enum.at(prev, index, 0)
      up_left = if index >= bpp, do: Enum.at(prev, index - bpp, 0), else: 0

      predictor =
        case filter do
          1 -> left
          2 -> up
          3 -> div(left + up, 2)
          4 -> test_paeth(left, up, up_left)
        end

      rem(value - predictor + 256, 256)
    end)
    |> :erlang.list_to_binary()
  end

  defp test_paeth(a, b, c) do
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
