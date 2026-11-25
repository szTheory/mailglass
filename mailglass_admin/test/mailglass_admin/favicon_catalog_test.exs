defmodule MailglassAdmin.FaviconCatalogTest do
  use ExUnit.Case, async: false

  alias MailglassAdmin.TestSupport.FaviconCatalog

  @repo_root Path.expand("../../..", __DIR__)
  @catalog_root Path.join(@repo_root, ".planning/research/brand-v2-adoption/favicon-catalog")
  @accepted_catalog_id "favicon-299c1aa-20261116T231912Z"
  @catalog_relative_root ".planning/research/brand-v2-adoption/favicon-catalog"
  @provenance_relative_dir "mailglass_admin/test/fixtures/favicon_provenance"
  @provenance_record_name "accepted-producer.json"
  @provenance_snapshot_name "accepted-producer.cjs"
  @producer_relative_path "mailglass_admin/e2e/favicon-capture.cjs"
  @historical_producer_sha256 "bff05d778648d4d900c9e977e89227ea3290ede9490e1e7fd5de28bdda7f6ee3"
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

    failures = FaviconCatalog.validate_catalog(dir, @repo_root)

    assert Enum.any?(failures, &String.contains?(&1, "engine entry must be an object"))
    assert Enum.any?(failures, &String.contains?(&1, "capture entry must be an object"))
    assert Enum.any?(failures, &String.contains?(&1, "Safari limitation is not disclosed"))
  end

  test "catalog manifests and capture PNGs reject symlinks and dot paths" do
    root = temporary_catalog()
    catalog = Path.join(root, "catalog")
    File.mkdir_p!(catalog)

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

  test "accepted historical producer validates from a Git-free source archive" do
    {root, catalog} = git_free_accepted_repo()

    refute File.exists?(Path.join(root, ".git"))
    assert FaviconCatalog.validate_catalog(catalog, root) == []
  end

  test "historical provenance files are bounded, regular files with authenticated bytes" do
    {root, catalog} = git_free_accepted_repo()
    record_path = provenance_path(root, @provenance_record_name)
    snapshot_path = provenance_path(root, @provenance_snapshot_name)
    record_bytes = File.read!(record_path)
    snapshot_bytes = File.read!(snapshot_path)

    File.rm!(record_path)
    assert_provenance_invalid(catalog, root, "historical producer provenance record")
    File.write!(record_path, "{")
    assert_provenance_invalid(catalog, root, "historical producer provenance record")
    File.write!(record_path, String.duplicate(" ", 16_385))
    assert_provenance_invalid(catalog, root, "historical producer provenance record")
    File.write!(record_path, record_bytes)

    File.rm!(snapshot_path)
    assert_provenance_invalid(catalog, root, "historical producer snapshot")
    File.write!(snapshot_path, <<0, snapshot_bytes::binary-size(byte_size(snapshot_bytes) - 1)>>)
    assert_provenance_invalid(catalog, root, "historical producer snapshot")
    File.write!(snapshot_path, snapshot_bytes <> "x")
    assert_provenance_invalid(catalog, root, "historical producer snapshot")
    File.write!(snapshot_path, snapshot_bytes)

    outside_record_root = temporary_directory!("favicon-provenance-record")
    outside_record = Path.join(outside_record_root, "record.json")

    File.write!(outside_record, record_bytes)
    File.rm!(record_path)
    File.ln_s!(outside_record, record_path)
    assert_provenance_invalid(catalog, root, "historical producer provenance record")
    File.rm!(record_path)
    File.write!(record_path, record_bytes)
    File.rm!(outside_record)

    outside_snapshot_root = temporary_directory!("favicon-provenance-snapshot")
    outside_snapshot = Path.join(outside_snapshot_root, "snapshot.cjs")

    File.write!(outside_snapshot, snapshot_bytes)
    File.rm!(snapshot_path)
    File.ln_s!(outside_snapshot, snapshot_path)
    assert_provenance_invalid(catalog, root, "historical producer snapshot")
    File.rm!(snapshot_path)
    File.write!(snapshot_path, snapshot_bytes)
    File.rm!(outside_snapshot)
  end

  test "historical provenance record fields cannot self-authorize substitutions" do
    {root, catalog} = git_free_accepted_repo()
    record_path = provenance_path(root, @provenance_record_name)
    original = record_path |> File.read!() |> Jason.decode!()

    for key <- Map.keys(original) do
      changed = Map.update!(original, key, &substitute_provenance_value/1)
      File.write!(record_path, Jason.encode!(changed))
      assert_provenance_invalid(catalog, root, "historical producer provenance record")
    end

    File.write!(record_path, Jason.encode!(Map.put(original, "unknown", true)))
    assert_provenance_invalid(catalog, root, "historical producer provenance record")
    File.write!(record_path, Jason.encode!(Map.delete(original, "producerGitBlob")))
    assert_provenance_invalid(catalog, root, "historical producer provenance record")

    File.write!(
      record_path,
      Jason.encode!(Map.put(original, "commands", %{"unexpected" => true}))
    )

    assert_provenance_invalid(catalog, root, "historical producer provenance record")
  end

  test "a fixture parent symlink cannot supply historical provenance" do
    {root, catalog} = git_free_accepted_repo()
    fixture_dir = Path.join(root, @provenance_relative_dir)
    moved_dir = fixture_dir <> "-moved"

    external_root = temporary_directory!("favicon-provenance-dir")
    external_dir = Path.join(external_root, "fixture-link-target")
    File.cp_r!(fixture_dir, external_dir)
    File.rename!(fixture_dir, moved_dir)
    File.ln_s!(external_dir, fixture_dir)

    assert_provenance_invalid(catalog, root, "historical producer provenance record")
  end

  test "historical selection uses raw manifest bytes and future catalogs require the current producer" do
    {root, accepted_catalog} = git_free_accepted_repo()
    accepted_manifest_path = Path.join(accepted_catalog, "manifest.json")
    accepted_manifest_bytes = File.read!(accepted_manifest_path)

    assert FaviconCatalog.validate_catalog(accepted_catalog, root) == []
    File.write!(accepted_manifest_path, accepted_manifest_bytes <> " ")
    assert_invalid_at(accepted_catalog, root, "producer: SHA-256 differs from current file")
    File.write!(accepted_manifest_path, accepted_manifest_bytes)

    synthetic_catalog =
      Path.join(Path.dirname(accepted_catalog), "favicon-synthetic-current-producer")

    copy_catalog_dir(accepted_catalog, synthetic_catalog)
    synthetic_manifest_path = Path.join(synthetic_catalog, "manifest.json")
    synthetic_manifest = synthetic_manifest_path |> File.read!() |> Jason.decode!()
    producer_path = Path.join(root, @producer_relative_path)
    current_producer_bytes = File.read!(producer_path)

    synthetic_manifest =
      Map.put(synthetic_manifest, "catalogId", Path.basename(synthetic_catalog))

    synthetic_manifest =
      put_in(synthetic_manifest, ["producer", "sha256"], sha256(current_producer_bytes))

    File.write!(synthetic_manifest_path, Jason.encode!(synthetic_manifest, pretty: true) <> "\n")
    File.rm_rf!(Path.join(root, @provenance_relative_dir))

    refute File.exists?(Path.join(root, ".git"))
    assert FaviconCatalog.validate_catalog(synthetic_catalog, root) == []

    File.write!(producer_path, current_producer_bytes <> "\n")
    assert_invalid_at(synthetic_catalog, root, "producer: SHA-256 differs from current file")

    synthetic_manifest = read_manifest(synthetic_catalog)

    synthetic_manifest =
      put_in(synthetic_manifest, ["producer", "sha256"], @historical_producer_sha256)

    File.write!(synthetic_manifest_path, Jason.encode!(synthetic_manifest, pretty: true) <> "\n")
    assert_invalid_at(synthetic_catalog, root, "producer: SHA-256 differs from current file")
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

  test "PNG decoder expands RGB screenshots into opaque RGBA pixels" do
    assert {:ok, %{width: 1, height: 1, pixels: <<24, 149, 194, 255>>}} =
             FaviconCatalog.decode_png(png_rgb(1, 1, <<0, 24, 149, 194>>))
  end

  test "RGB PNG decoder applies all row filters with three-byte pixels" do
    source_rows =
      for y <- 1..5 do
        for x <- 1..2, into: <<>> do
          <<y * 10 + x, y * 20 + x, y * 30 + x>>
        end
      end

    filtered =
      source_rows
      |> Enum.with_index()
      |> Enum.reduce({<<>>, <<>>}, fn {row, index}, {scanlines, previous} ->
        filter = rem(index, 5)
        encoded = filter_row(filter, row, previous, 3)
        {scanlines <> <<filter>> <> encoded, row}
      end)
      |> elem(0)

    expected =
      for row <- source_rows, into: <<>> do
        for <<r, g, b <- row>>, into: <<>>, do: <<r, g, b, 255>>
      end

    assert {:ok, %{width: 2, height: 5, pixels: pixels}} =
             FaviconCatalog.decode_png(png_rgb(2, 5, filtered))

    assert pixels == expected
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

  defp temporary_directory!(prefix), do: temporary_directory!(prefix, 0)

  defp temporary_directory!(prefix, attempts) when attempts < 64 do
    path =
      Path.join(
        System.tmp_dir!(),
        "#{prefix}-#{System.unique_integer([:positive])}"
      )

    case File.mkdir(path) do
      :ok ->
        on_exit(fn -> File.rm_rf!(path) end)
        path

      {:error, :eexist} ->
        temporary_directory!(prefix, attempts + 1)

      {:error, reason} ->
        raise "cannot create owned temporary directory #{inspect(path)}: #{inspect(reason)}"
    end
  end

  defp temporary_directory!(prefix, _attempts) do
    raise "cannot allocate an exclusive temporary directory for #{inspect(prefix)}"
  end

  defp temporary_catalog do
    temporary_directory!("favicon-catalog-contract")
  end

  defp git_free_accepted_repo do
    root = temporary_directory!("favicon-provenance-contract")

    source_catalog = Path.join(@catalog_root, @accepted_catalog_id)
    catalog = Path.join([root, @catalog_relative_root, @accepted_catalog_id])
    File.mkdir_p!(catalog)
    copy_catalog_dir(source_catalog, catalog)

    for relative <- [
          "brandbook/brand.pin.json",
          "brandbook/v2/favicon.svg",
          "mailglass_admin/priv/static/favicon.svg",
          @producer_relative_path
        ] do
      copy_repo_file(root, relative)
    end

    fixture_dir = Path.join(root, @provenance_relative_dir)
    File.mkdir_p!(fixture_dir)

    for name <- [@provenance_record_name, @provenance_snapshot_name] do
      File.cp!(provenance_path(@repo_root, name), Path.join(fixture_dir, name))
    end

    {root, catalog}
  end

  defp copy_repo_file(root, relative) do
    destination = Path.join(root, relative)
    File.mkdir_p!(Path.dirname(destination))
    File.cp!(Path.join(@repo_root, relative), destination)
  end

  defp copy_catalog_dir(source, destination) do
    File.mkdir_p!(destination)

    for name <- File.ls!(source) do
      File.cp!(Path.join(source, name), Path.join(destination, name))
    end
  end

  defp provenance_path(root, name), do: Path.join([root, @provenance_relative_dir, name])

  defp assert_provenance_invalid(catalog, root, message) do
    failures = FaviconCatalog.validate_catalog(catalog, root)
    assert Enum.any?(failures, &String.contains?(&1, message)), inspect(failures)
  end

  defp assert_invalid_at(catalog, root, message) do
    failures = FaviconCatalog.validate_catalog(catalog, root)
    assert Enum.any?(failures, &String.contains?(&1, message)), inspect(failures)
  end

  defp substitute_provenance_value(value) when is_binary(value), do: value <> "-substituted"
  defp substitute_provenance_value(value) when is_integer(value), do: value + 1
  defp substitute_provenance_value(value) when is_list(value), do: value ++ ["substituted"]

  defp sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

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
    target = temporary_directory!("favicon-catalog-test")

    for file <- Path.wildcard(Path.join(source, "*")),
        do: File.cp!(file, Path.join(target, Path.basename(file)))

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

  defp png_rgb(width, height, scanlines) do
    ihdr = <<width::unsigned-big-32, height::unsigned-big-32, 8, 2, 0, 0, 0>>

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
