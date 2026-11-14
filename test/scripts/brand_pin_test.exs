defmodule Mailglass.Scripts.BrandPinTest do
  use ExUnit.Case, async: true

  # Hermetic by construction. `verify/3` and `check_zip/2` are pure over injected closures and
  # binaries, no test touches the network, and every mutation writes only under its own
  # ExUnit tmp_dir (a copy of brandbook/v2/), never the repository tree.

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/brand_pin.exs")
  @pin_path Path.join(@repo_root, "brandbook/brand.pin.json")
  @gitignore_path Path.join(@repo_root, "brandbook/.gitignore")

  # Test-owned on purpose: a pin-only edit of the zip hash fails here. A deliberate bump
  # (scripts/brand_pin.exs update) edits this constant and the pin in one chore(brand) commit.
  @expected_zip_sha256 "ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b"

  @required_assets [
    "brandbook/v2/OFL-AtkinsonHyperlegibleMono.txt",
    "brandbook/v2/OFL-AtkinsonHyperlegibleNext.txt",
    "brandbook/v2/OFL-FunnelDisplay.txt",
    "brandbook/v2/brand.json"
  ]

  # Members of the v2 book zip that must never enter the tree (the three distinctive names;
  # tracked v1 files such as brandbook/index.html are not covered by this check).
  @forbidden_basenames ["BRAND.md", "mailglass-brand-book.html", "mailglass-one-page.html"]
  @skipped_dirs [".git", "deps", "_build", "node_modules", "tmp"]

  setup_all do
    Code.require_file(@script)
    :ok
  end

  defp pin(function, args), do: apply(Mailglass.BrandPin, function, args)

  defp real_pin do
    @pin_path |> File.read!() |> Jason.decode!()
  end

  # Copies brandbook/v2/ into tmp_dir and returns {read_file, list_dir} closures rooted there.
  defp tmp_tree(tmp_dir) do
    source = Path.join(@repo_root, "brandbook/v2")
    dest = Path.join(tmp_dir, "brandbook/v2")
    File.mkdir_p!(dest)
    for name <- File.ls!(source), do: File.cp!(Path.join(source, name), Path.join(dest, name))
    {pin(:tree_read_file, [tmp_dir]), pin(:tree_list_dir, [tmp_dir])}
  end

  defp verify(pin_map, {read_file, list_dir}), do: pin(:verify, [pin_map, read_file, list_dir])

  defp issues!(result) do
    assert {:error, issues} = result
    issues
  end

  defp tmp_path(tmp_dir, to), do: Path.join(tmp_dir, to)

  defp mutate!(tmp_dir, to, fun) do
    path = tmp_path(tmp_dir, to)
    File.write!(path, fun.(File.read!(path)))
  end

  defp flip_hex(<<char, rest::binary>>) do
    <<if(char == ?0, do: ?1, else: ?0), rest::binary>>
  end

  defp with_first_shipped(pin_map, fun) do
    [first | rest] = pin_map["shipped"]
    %{pin_map | "shipped" => [fun.(first) | rest]}
  end

  defp with_to(pin_map, to), do: with_first_shipped(pin_map, &%{&1 | "to" => to})

  defp issue_tags(issues), do: issues |> Enum.map(&elem(&1, 0)) |> Enum.uniq()

  describe "the committed pin" do
    test "decodes and parses" do
      assert {:ok, parsed} = pin(:parse, [real_pin()])
      assert parsed["repo"] == "szTheory/mailglass-brand"
    end

    test "records the zip hash the test owns" do
      assert pin(:check_expected_sha256, [real_pin(), @expected_zip_sha256]) == :ok
    end

    test "pins a full commit and a commit-derived url" do
      real = real_pin()

      assert real["commit"] =~ ~r/\A[0-9a-f]{40}\z/
      assert real["url"] == pin(:zip_url, [real["repo"], real["commit"]])
    end

    test "verifies against the real tree" do
      assert pin(:verify, [
               real_pin(),
               pin(:tree_read_file, [@repo_root]),
               pin(:tree_list_dir, [@repo_root])
             ]) ==
               :ok
    end

    test "ships exactly the four required assets" do
      assert real_pin()["shipped"] |> Enum.map(& &1["to"]) |> Enum.sort() == @required_assets
    end

    test "is not a vacuous pass: the manifest and the owned directories are non-empty" do
      real = real_pin()

      assert length(real["shipped"]) >= 4
      assert real["owned_dirs"] != []
    end
  end

  describe "tamper cases name their cause" do
    @describetag :tmp_dir

    test "a clean copy of brandbook/v2 verifies, so every case below fails for its own cause",
         %{tmp_dir: tmp_dir} do
      assert verify(real_pin(), tmp_tree(tmp_dir)) == :ok
    end

    test "(a) an edited shipped sha256 gives :asset_hash_mismatch for that asset",
         %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      tampered = with_first_shipped(real_pin(), &%{&1 | "sha256" => flip_hex(&1["sha256"])})
      [first | _] = real_pin()["shipped"]

      assert {:asset_hash_mismatch, first["to"]} in issues!(verify(tampered, closures))
    end

    test "(b) an edited top-level zip hash still parses and is caught by the test-owned constant" do
      real = real_pin()
      mutated_hex = flip_hex(real["sha256"])
      mutated = %{real | "sha256" => mutated_hex}

      assert {:ok, _} = pin(:parse, [mutated])

      assert {:zip_hash_unexpected, mutated_hex} in issues!(
               pin(:check_expected_sha256, [mutated, @expected_zip_sha256])
             )
    end

    test "(c) an appended byte gives :asset_size_mismatch", %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      to = "brandbook/v2/brand.json"

      mutate!(tmp_dir, to, &(&1 <> "x"))
      issues = issues!(verify(real_pin(), closures))

      assert {:asset_size_mismatch, to} in issues
      refute {:asset_hash_mismatch, to} in issues
    end

    test "(c) a one-byte change at equal size gives :asset_hash_mismatch", %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      to = "brandbook/v2/brand.json"

      mutate!(tmp_dir, to, fn <<byte, rest::binary>> -> <<Bitwise.bxor(byte, 1), rest::binary>> end)
      issues = issues!(verify(real_pin(), closures))

      assert {:asset_hash_mismatch, to} in issues
      refute {:asset_size_mismatch, to} in issues
    end

    test "(c2) a CRLF rewrite of a text asset gives :asset_size_mismatch, a zero-byte copy too",
         %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      to = "brandbook/v2/OFL-FunnelDisplay.txt"
      original = File.read!(tmp_path(tmp_dir, to))
      crlf = String.replace(original, "\n", "\r\n")

      assert byte_size(crlf) > byte_size(original)

      File.write!(tmp_path(tmp_dir, to), crlf)
      assert {:asset_size_mismatch, to} in issues!(verify(real_pin(), closures))

      File.write!(tmp_path(tmp_dir, to), "")
      assert {:asset_size_mismatch, to} in issues!(verify(real_pin(), closures))
    end

    test "(d) unlisted files in an owned directory, hidden and nested included, give :asset_unlisted",
         %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      File.write!(tmp_path(tmp_dir, "brandbook/v2/extra.txt"), "smuggled")
      File.write!(tmp_path(tmp_dir, "brandbook/v2/.extra"), "hidden")
      File.mkdir_p!(tmp_path(tmp_dir, "brandbook/v2/sub"))
      File.write!(tmp_path(tmp_dir, "brandbook/v2/sub/deep.txt"), "nested")

      issues = issues!(verify(real_pin(), closures))

      assert {:asset_unlisted, "brandbook/v2/extra.txt"} in issues
      assert {:asset_unlisted, "brandbook/v2/.extra"} in issues
      assert {:asset_unlisted, "brandbook/v2/sub/deep.txt"} in issues
    end

    test "(e) a deleted listed asset gives :asset_missing", %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      to = "brandbook/v2/OFL-FunnelDisplay.txt"
      File.rm!(tmp_path(tmp_dir, to))

      issues = issues!(verify(real_pin(), closures))

      assert {:asset_missing, to} in issues
      assert issue_tags(issues) == [:asset_missing]
    end

    test "(e2) an owned directory emptied of every file gives :asset_missing for all four",
         %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      dir = tmp_path(tmp_dir, "brandbook/v2")
      for name <- File.ls!(dir), do: File.rm!(Path.join(dir, name))

      issues = issues!(verify(real_pin(), closures))

      for to <- @required_assets, do: assert({:asset_missing, to} in issues)
      assert issue_tags(issues) == [:asset_missing]
    end

    test "(f) an empty shipped list gives :manifest_empty" do
      issues = issues!(pin(:parse, [%{real_pin() | "shipped" => []}]))

      assert :manifest_empty in issue_tags(issues)
    end

    test "(f) a manifest missing a required asset gives :required_asset_absent" do
      [dropped | kept] = real_pin()["shipped"]
      issues = issues!(pin(:parse, [%{real_pin() | "shipped" => kept}]))

      assert {:required_asset_absent, dropped["to"]} in issues
    end

    test "(g) unsafe or out-of-tree paths give :path_unsafe and are rejected before any read" do
      reader = fn path -> flunk("read #{path} before the pin parsed") end
      lister = fn dir -> flunk("listed #{dir} before the pin parsed") end

      for unsafe <- [
            "../x",
            "/etc/x",
            "brandbook/v2/../../x",
            "brandbook/v2/a\\b",
            "brandbook/v2/a\0b",
            "brandbook/v2//x",
            "mailglass_admin/priv/static/x"
          ] do
        issues = issues!(pin(:verify, [with_to(real_pin(), unsafe), reader, lister]))

        assert {:path_unsafe, unsafe} in issues
      end
    end

    test "(g) an unsafe zip member name gives :path_unsafe" do
      for unsafe <- ["../x", "/etc/x", "assets/../../x"] do
        tampered = with_first_shipped(real_pin(), &%{&1 | "from" => unsafe})

        assert {:path_unsafe, unsafe} in issues!(pin(:parse, [tampered]))
      end
    end

    test "(h) a 39-character commit gives :pin_malformed" do
      short = binary_part(real_pin()["commit"], 0, 39)

      assert :pin_malformed in issue_tags(issues!(pin(:parse, [%{real_pin() | "commit" => short}])))
    end

    test "(h) a url that is not the commit-derived url gives :url_not_derived" do
      mutable = "https://sztheory.github.io/mailglass-brand/mailglass-brand.zip"
      issues = issues!(pin(:parse, [%{real_pin() | "url" => mutable}]))

      assert {:url_not_derived, mutable} in issues
    end

    test "an unexpected top-level key or a non-object gives :pin_malformed" do
      assert :pin_malformed in issue_tags(issues!(pin(:parse, [Map.put(real_pin(), "extra", 1)])))
      assert :pin_malformed in issue_tags(issues!(pin(:parse, [[]])))
    end

    test "(i) verify is idempotent for a clean copy and for a tampered copy", %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)

      assert verify(real_pin(), closures) == verify(real_pin(), closures)
      assert verify(real_pin(), closures) == :ok

      File.write!(tmp_path(tmp_dir, "brandbook/v2/extra.txt"), "smuggled")
      mutate!(tmp_dir, "brandbook/v2/brand.json", &(&1 <> "x"))

      first = verify(real_pin(), closures)
      assert first == verify(real_pin(), closures)
      assert {:error, _} = first
    end
  end

  describe "the full brand book stays out of the repository tree" do
    test "the detector has teeth against known-bad paths" do
      bad = [
        "brand/BRAND.md",
        "mailglass-brand/brand.json",
        "downloads/mailglass-brand.zip",
        "docs/BRAND.md",
        "site/mailglass-brand-book.html",
        "site/mailglass-one-page.html"
      ]

      assert forbidden_paths(bad ++ ["brandbook/v2/brand.json", "brandbook/index.html"]) == bad
    end

    @tag :tmp_dir
    test "the filesystem fallback walk finds a planted book and skips dependency trees",
         %{tmp_dir: tmp_dir} do
      File.mkdir_p!(Path.join(tmp_dir, "brand"))
      File.write!(Path.join(tmp_dir, "brand/BRAND.md"), "planted")
      File.mkdir_p!(Path.join(tmp_dir, "deps/pkg"))
      File.write!(Path.join(tmp_dir, "deps/pkg/book.zip"), "vendored")
      File.mkdir_p!(Path.join(tmp_dir, "mailglass_admin/node_modules/x"))
      File.write!(Path.join(tmp_dir, "mailglass_admin/node_modules/x/y.zip"), "vendored")

      assert tree_paths_by_walk(tmp_dir) == ["brand/BRAND.md"]
    end

    test "no path under brand/, no zip, and none of the book's distinctive files is in the tree" do
      assert forbidden_paths(repo_paths()) == []
    end

    test "brandbook/.gitignore ignores a locally unzipped book inside brandbook/" do
      lines = @gitignore_path |> File.read!() |> String.split("\n")

      assert "/brand/" in lines
      assert "/mailglass-brand/" in lines
    end
  end

  defp forbidden_paths(paths) do
    Enum.filter(paths, fn path ->
      String.starts_with?(path, "brand/") or String.starts_with?(path, "mailglass-brand/") or
        String.ends_with?(path, ".zip") or Path.basename(path) in @forbidden_basenames
    end)
  end

  # Tracked and untracked-but-not-ignored paths. Falls back to a filesystem walk when git is
  # absent or cannot list the tree, so the check is never skipped silently.
  defp repo_paths do
    with git when is_binary(git) <- System.find_executable("git"),
         {output, 0} <-
           System.cmd(git, ["ls-files", "-co", "--exclude-standard"],
             cd: @repo_root,
             stderr_to_stdout: true
           ) do
      String.split(output, "\n", trim: true)
    else
      _unavailable -> tree_paths_by_walk(@repo_root)
    end
  end

  defp tree_paths_by_walk(root, dir \\ nil) do
    dir = dir || root

    dir
    |> File.ls!()
    |> Enum.sort()
    |> Enum.flat_map(fn name ->
      path = Path.join(dir, name)

      case File.lstat(path) do
        _ when name in @skipped_dirs -> []
        {:ok, %File.Stat{type: :directory}} -> tree_paths_by_walk(root, path)
        {:ok, %File.Stat{}} -> [Path.relative_to(path, root)]
        {:error, _reason} -> []
      end
    end)
  end
end
