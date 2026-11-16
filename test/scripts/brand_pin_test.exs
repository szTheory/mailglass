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

  # The `init` contract: the four assets `init` writes (and `parse` requires). Not the whole
  # pin; see @extension_assets.
  @required_assets [
    "brandbook/v2/OFL-AtkinsonHyperlegibleMono.txt",
    "brandbook/v2/OFL-AtkinsonHyperlegibleNext.txt",
    "brandbook/v2/OFL-FunnelDisplay.txt",
    "brandbook/v2/brand.json"
  ]

  # What update/extend add from the reviewed zip: Admin fonts, brand marks and launch media.
  # Test-owned, so a pin-only edit of the shipped list fails here.
  @fonts_dir "mailglass_admin/priv/static/fonts"
  @extension_assets [
    @fonts_dir <> "/OFL-AtkinsonHyperlegibleMono.txt",
    @fonts_dir <> "/OFL-AtkinsonHyperlegibleNext.txt",
    @fonts_dir <> "/OFL-FunnelDisplay.txt",
    @fonts_dir <> "/a-display-600.woff2",
    @fonts_dir <> "/a-mono-400.woff2",
    @fonts_dir <> "/a-mono-600.woff2",
    @fonts_dir <> "/ui-400.woff2",
    @fonts_dir <> "/ui-400i.woff2",
    @fonts_dir <> "/ui-600.woff2",
    "brandbook/v2/favicon.svg",
    "brandbook/v2/mailglass-mark-light.svg",
    "brandbook/v2/mailglass-mark-dark.svg",
    "brandbook/v2/favicon.ico",
    "brandbook/v2/favicon-16-light.png",
    "brandbook/v2/favicon-16-dark.png",
    "brandbook/v2/favicon-32-light.png",
    "brandbook/v2/favicon-32-dark.png",
    "brandbook/v2/avatar-512-light.png",
    "brandbook/v2/avatar-512-dark.png",
    "brandbook/v2/social-card-1280x640.png",
    "brandbook/v2/mailglass-lockup-dark.svg",
    "brandbook/v2/mailglass-lockup-light.svg"
  ]
  @expected_shipped Enum.sort(@required_assets ++ @extension_assets)
  @expected_owned_dirs ["brandbook/v2", @fonts_dir]

  # Members of the v2 book zip that must never enter the tree (the three distinctive names;
  # tracked v1 files such as brandbook/index.html are not covered by this check).
  @forbidden_basenames ["BRAND.md", "mailglass-brand-book.html", "mailglass-one-page.html"]
  @skipped_dirs [".git", "deps", "_build", "node_modules", "tmp"]

  setup_all do
    Application.put_env(:mailglass, :script_library_mode, true)
    Code.require_file(@script)
    :ok
  end

  defp pin(function, args), do: apply(Mailglass.BrandPin, function, args)

  defp real_pin do
    @pin_path |> File.read!() |> Jason.decode!()
  end

  # Copies every owned directory of the real pin into tmp_dir and returns {read_file,
  # list_dir} closures rooted there.
  defp tmp_tree(tmp_dir) do
    for dir <- real_pin()["owned_dirs"] do
      source = Path.join(@repo_root, dir)
      dest = Path.join(tmp_dir, dir)
      File.mkdir_p!(dest)
      for name <- File.ls!(source), do: File.cp!(Path.join(source, name), Path.join(dest, name))
    end

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

    test "ships exactly the four init assets plus the twenty-two declared extension assets" do
      assert real_pin()["shipped"] |> Enum.map(& &1["to"]) |> Enum.sort() == @expected_shipped
      assert length(@expected_shipped) == 26
    end

    test "owns exactly brandbook/v2 and the admin fonts directory, never priv/static itself" do
      owned = real_pin()["owned_dirs"]

      assert Enum.sort(owned) == Enum.sort(@expected_owned_dirs)
      refute "mailglass_admin/priv/static" in owned
    end

    test "every shipped asset sits under an owned directory and licenses match their origin" do
      for entry <- real_pin()["shipped"] do
        assert Enum.any?(@expected_owned_dirs, &String.starts_with?(entry["to"], &1 <> "/"))

        expected_license = if String.contains?(entry["from"], "fonts/"), do: "OFL-1.1", else: "MIT"
        assert entry["license"] == expected_license
      end
    end

    test "is not a vacuous pass: the manifest and the owned directories are non-empty" do
      real = real_pin()

      assert length(real["shipped"]) >= 16
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

    test "(e2) an owned directory emptied of every file gives :asset_missing for each listed file",
         %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      dir = tmp_path(tmp_dir, "brandbook/v2")
      for name <- File.ls!(dir), do: File.rm!(Path.join(dir, name))

      issues = issues!(verify(real_pin(), closures))

      for to <- @required_assets, do: assert({:asset_missing, to} in issues)
      assert issue_tags(issues) == [:asset_missing]
    end

    test "(c3) a flipped byte in a shipped font gives :asset_hash_mismatch for that path only",
         %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      to = @fonts_dir <> "/ui-400.woff2"

      mutate!(tmp_dir, to, fn <<byte, rest::binary>> -> <<Bitwise.bxor(byte, 1), rest::binary>> end)
      issues = issues!(verify(real_pin(), closures))

      assert {:asset_hash_mismatch, to} in issues
      assert issue_tags(issues) == [:asset_hash_mismatch]
      assert length(issues) == 1
    end

    test "(d2) a stray file in the fonts directory, a retired font name included, gives :asset_unlisted",
         %{tmp_dir: tmp_dir} do
      closures = tmp_tree(tmp_dir)
      File.write!(tmp_path(tmp_dir, @fonts_dir <> "/retired-face-400.woff2"), "wOF2 smuggled")
      File.write!(tmp_path(tmp_dir, @fonts_dir <> "/.DS_Store"), "finder")

      issues = issues!(verify(real_pin(), closures))

      assert {:asset_unlisted, @fonts_dir <> "/retired-face-400.woff2"} in issues
      assert {:asset_unlisted, @fonts_dir <> "/.DS_Store"} in issues
      assert issue_tags(issues) == [:asset_unlisted]
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
            "mailglass_admin/priv/static/x",
            "mailglass_admin/priv/static/app.css",
            "mailglass_admin/priv/static/fonts/../app.css",
            "mailglass_admin/priv/static/fonts"
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

  # ---------------------------------------------------------------------------
  # Advisory online check and reviewed update procedure, over synthetic in-memory zips.
  # The getter is injected, so nothing here touches the network.

  @zip_root "mailglass-brand/"
  @old_commit String.duplicate("a", 40)
  @new_commit String.duplicate("b", 40)

  defp synthetic_files(seed) do
    %{
      "brand.json" =>
        Jason.encode!(%{"version" => "2.0", "date" => "November 13, 2026", "seed" => seed}),
      "assets/fonts/OFL-FunnelDisplay.txt" => "funnel license #{seed}\n",
      "assets/fonts/OFL-AtkinsonHyperlegibleNext.txt" => "next license #{seed}\n",
      "assets/fonts/OFL-AtkinsonHyperlegibleMono.txt" => "mono license #{seed}\n"
    }
    |> Map.merge(extension_files(seed))
  end

  # One distinct member per `extend` asset, so a wrong `from`/`to` pairing changes bytes.
  defp extension_files(seed) do
    woff2 =
      for name <- ~w(a-display-600 ui-400 ui-600 ui-400i a-mono-400 a-mono-600), into: %{} do
        {"assets/fonts/web/#{name}.woff2", "wOF2 #{name} #{seed}"}
      end

    svg =
      for {member, label} <- [
            {"assets/logo/mailglass-lockup-light.svg", "lockup light"},
            {"assets/logo/mailglass-lockup-dark.svg", "lockup dark"},
            {"assets/icon/favicon.svg", "favicon"},
            {"assets/icon/favicon-32-light.svg", "light mark"},
            {"assets/icon/favicon-32-dark.svg", "dark mark"}
          ],
          into: %{} do
        {member, "<svg xmlns=\"http://www.w3.org/2000/svg\"><!-- #{label} #{seed} --></svg>\n"}
      end

    static_media =
      for member <- [
            "assets/icon/favicon.ico",
            "assets/icon/favicon-16-light.png",
            "assets/icon/favicon-16-dark.png",
            "assets/icon/favicon-32-light.png",
            "assets/icon/favicon-32-dark.png",
            "assets/avatar/mailglass-avatar-512-light.png",
            "assets/avatar/mailglass-avatar-512-dark.png",
            "assets/social/mailglass-social-card-1280x640.png"
          ],
          into: %{} do
        {member, "fixture bytes for #{member} #{seed}"}
      end

    Map.merge(woff2, svg) |> Map.merge(static_media)
  end

  defp build_zip(files) do
    entries = for {name, data} <- Enum.sort(files), do: {String.to_charlist(name), data}
    {:ok, {_name, zip}} = :zip.create(~c"book.zip", entries, [:memory])
    zip
  end

  defp book_zip(files, extra \\ %{}) do
    files
    |> Map.new(fn {from, data} -> {@zip_root <> from, data} end)
    |> Map.merge(extra)
    |> build_zip()
  end

  defp sha(data), do: pin(:sha256_hex, [data])

  # A pin whose shipped hashes come from `files` and whose zip hash and size come from `zip`.
  defp synthetic_pin(files, zip, commit \\ @old_commit) do
    real = real_pin()

    shipped =
      for entry <- real["shipped"] do
        data = Map.fetch!(files, entry["from"])
        %{entry | "sha256" => sha(data), "bytes" => byte_size(data)}
      end

    %{
      real
      | "commit" => commit,
        "url" => pin(:zip_url, [real["repo"], commit]),
        "sha256" => sha(zip),
        "size" => byte_size(zip),
        "shipped" => shipped
    }
  end

  # The pin as it stood before `extend`: the four `init` assets in one owned directory.
  defp base_pin(files, zip) do
    full = synthetic_pin(files, zip)

    %{
      full
      | "owned_dirs" => ["brandbook/v2"],
        "shipped" => Enum.filter(full["shipped"], &(&1["to"] in @required_assets))
    }
  end

  defp getter_returning(zip) do
    test_pid = self()

    fn url ->
      send(test_pid, {:fetched, url})
      {:ok, zip}
    end
  end

  defp no_network, do: fn url -> flunk("unexpected download of #{url}") end

  defp tree_files(dir) do
    dir
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, dir))
    |> Enum.sort()
  end

  describe "advisory zip check (check_zip/2)" do
    setup do
      files = synthetic_files("a")
      zip = book_zip(files)
      %{files: files, zip: zip}
    end

    test "a zip whose hash, size and members match the pin gives :ok", %{files: files, zip: zip} do
      assert pin(:check_zip, [synthetic_pin(files, zip), zip]) == :ok
    end

    test "a zip hash that differs from the pin gives :zip_hash_mismatch",
         %{files: files, zip: zip} do
      real = synthetic_pin(files, zip)
      tampered = %{real | "sha256" => flip_hex(real["sha256"])}

      issues = issues!(pin(:check_zip, [tampered, zip]))

      assert {:zip_hash_mismatch, sha(zip)} in issues
      assert issue_tags(issues) == [:zip_hash_mismatch]
    end

    test "a size that differs from the pin gives :zip_size_mismatch at the right hash",
         %{files: files, zip: zip} do
      real = synthetic_pin(files, zip)

      issues = issues!(pin(:check_zip, [%{real | "size" => real["size"] + 1}, zip]))

      assert {:zip_size_mismatch, byte_size(zip)} in issues
      assert issue_tags(issues) == [:zip_size_mismatch]
    end

    test "a member whose bytes differ from the pin gives :zip_member_mismatch", %{files: files} do
      altered = Map.put(files, "brand.json", Jason.encode!(%{"version" => "9.9", "date" => "x"}))
      zip = book_zip(altered)

      issues = issues!(pin(:check_zip, [synthetic_pin(files, zip), zip]))

      assert {:zip_member_mismatch, "brand.json"} in issues
      assert issue_tags(issues) == [:zip_member_mismatch]
    end

    test "a pin-listed member absent from the zip gives :zip_member_missing", %{files: files} do
      from = "assets/fonts/OFL-FunnelDisplay.txt"
      zip = files |> Map.delete(from) |> book_zip()

      issues = issues!(pin(:check_zip, [synthetic_pin(files, zip), zip]))

      assert {:zip_member_missing, from} in issues
    end

    test "a pin whose from contains .. is rejected by parse before any zip read" do
      tampered = with_first_shipped(real_pin(), &%{&1 | "from" => "../x"})

      issues = issues!(pin(:check_zip, [tampered, "these bytes are not a zip"]))

      assert {:path_unsafe, "../x"} in issues
      refute :zip_unreadable in issue_tags(issues)
    end

    test "bytes that are not a zip give :zip_unreadable", %{files: files, zip: zip} do
      garbage = "these bytes are not a zip"

      issues = issues!(pin(:check_zip, [synthetic_pin(files, zip), garbage]))

      assert :zip_unreadable in issue_tags(issues)
    end

    test "members are read by pin-listed names only, never by names the archive supplies",
         %{files: files} do
      zip = book_zip(files, %{"mailglass-brand/../evil.txt" => "hostile"})

      assert pin(:check_zip, [synthetic_pin(files, zip), zip]) == :ok
    end
  end

  describe "update and init procedure over an injected getter" do
    @describetag :tmp_dir

    test "update refuses a zip whose hash differs from --expect-sha256 and writes nothing",
         %{tmp_dir: tmp_dir} do
      old_files = synthetic_files("old")
      current = synthetic_pin(old_files, book_zip(old_files))
      new_zip = book_zip(synthetic_files("new"))
      wrong = String.duplicate("0", 64)

      assert pin(:update, [
               current,
               [commit: @new_commit, expect_sha256: wrong, target_dir: tmp_dir],
               getter_returning(new_zip)
             ]) == {:error, :zip_hash_mismatch}

      assert_received {:fetched, url}
      assert url == pin(:zip_url, [current["repo"], @new_commit])
      assert File.ls!(tmp_dir) == []
    end

    test "update refuses a malformed commit or expected hash before any download",
         %{tmp_dir: tmp_dir} do
      files = synthetic_files("old")
      current = synthetic_pin(files, book_zip(files))

      for opts <- [
            [commit: "abc123", expect_sha256: String.duplicate("0", 64)],
            [commit: @new_commit, expect_sha256: "nope"],
            [commit: @new_commit]
          ] do
        assert {:error, {:bad_option, _}} =
                 pin(:update, [current, [target_dir: tmp_dir] ++ opts, no_network()])
      end

      assert File.ls!(tmp_dir) == []
    end

    test "update refuses a current pin that does not parse", %{tmp_dir: tmp_dir} do
      tampered = %{real_pin() | "shipped" => []}

      assert {:error, {:pin_invalid, issues}} =
               pin(:update, [
                 tampered,
                 [
                   commit: @new_commit,
                   expect_sha256: String.duplicate("0", 64),
                   target_dir: tmp_dir
                 ],
                 no_network()
               ])

      assert :manifest_empty in issue_tags(issues)
      assert File.ls!(tmp_dir) == []
    end

    test "update refuses a zip that lacks a pin-listed member and writes nothing",
         %{tmp_dir: tmp_dir} do
      old_files = synthetic_files("old")
      current = synthetic_pin(old_files, book_zip(old_files))
      from = "assets/fonts/OFL-AtkinsonHyperlegibleMono.txt"
      new_zip = "new" |> synthetic_files() |> Map.delete(from) |> book_zip()

      assert pin(:update, [
               current,
               [commit: @new_commit, expect_sha256: sha(new_zip), target_dir: tmp_dir],
               getter_returning(new_zip)
             ]) == {:error, {:zip_member_missing, from}}

      assert File.ls!(tmp_dir) == []
    end

    test "update refuses a zip missing a newly declared asset before any write",
         %{tmp_dir: tmp_dir} do
      old_files = synthetic_files("old")
      current = synthetic_pin(old_files, book_zip(old_files))
      from = "assets/icon/favicon.ico"
      new_zip = "new" |> synthetic_files() |> Map.delete(from) |> book_zip()

      assert pin(:update, [
               current,
               [commit: @new_commit, expect_sha256: sha(new_zip), target_dir: tmp_dir],
               getter_returning(new_zip)
             ]) == {:error, {:zip_member_missing, from}}

      assert File.ls!(tmp_dir) == []
    end

    test "update twice with the same zip writes a byte-identical pin and byte-identical assets",
         %{tmp_dir: tmp_dir} do
      old_files = synthetic_files("old")
      current = synthetic_pin(old_files, book_zip(old_files))
      new_files = synthetic_files("new")
      new_zip = book_zip(new_files)
      opts = [commit: @new_commit, expect_sha256: sha(new_zip), target_dir: tmp_dir]
      pin_file = Path.join(tmp_dir, "brandbook/brand.pin.json")

      assert {:ok, updated} = pin(:update, [current, opts, getter_returning(new_zip)])
      first_pin = File.read!(pin_file)
      first_assets = for to <- @expected_shipped, do: File.read!(tmp_path(tmp_dir, to))

      assert {:ok, ^updated} = pin(:update, [current, opts, getter_returning(new_zip)])
      assert File.read!(pin_file) == first_pin
      assert for(to <- @expected_shipped, do: File.read!(tmp_path(tmp_dir, to))) == first_assets

      assert {:ok, ^updated} = pin(:update, [updated, opts, getter_returning(new_zip)])
      assert File.read!(pin_file) == first_pin

      assert updated["commit"] == @new_commit
      assert updated["url"] == pin(:zip_url, [updated["repo"], @new_commit])
      assert updated["sha256"] == sha(new_zip)
      assert updated["size"] == byte_size(new_zip)
      assert updated["book"] == %{"version" => "2.0", "date" => "2026-11-13"}
      assert first_pin |> Jason.decode!() == updated
      assert String.ends_with?(first_pin, "}\n")

      for entry <- updated["shipped"] do
        assert File.read!(tmp_path(tmp_dir, entry["to"])) == new_files[entry["from"]]
      end

      closures = {pin(:tree_read_file, [tmp_dir]), pin(:tree_list_dir, [tmp_dir])}
      assert verify(updated, closures) == :ok
      assert pin(:check_zip, [updated, new_zip]) == :ok
    end

    test "update writes the pin with a stable key order", %{tmp_dir: tmp_dir} do
      files = synthetic_files("old")
      current = synthetic_pin(files, book_zip(files))
      new_zip = book_zip(synthetic_files("new"))
      opts = [commit: @new_commit, expect_sha256: sha(new_zip), target_dir: tmp_dir]

      assert {:ok, _} = pin(:update, [current, opts, getter_returning(new_zip)])

      keys =
        tmp_dir
        |> Path.join("brandbook/brand.pin.json")
        |> File.read!()
        |> then(&Regex.scan(~r/^  "([a-z_0-9]+)":/m, &1))
        |> Enum.map(&List.last/1)

      assert keys ==
               ~w(repo commit url sha256 size book root owned_dirs shipped note)
    end

    test "init refuses when a pin already exists, writes nothing and never downloads",
         %{tmp_dir: tmp_dir} do
      pin_file = Path.join(tmp_dir, "brandbook/brand.pin.json")
      File.mkdir_p!(Path.dirname(pin_file))
      File.write!(pin_file, "existing pin bytes\n")

      assert pin(:init, [
               [commit: @new_commit, expect_sha256: String.duplicate("0", 64), target_dir: tmp_dir],
               no_network()
             ]) == {:error, :pin_exists}

      assert File.read!(pin_file) == "existing pin bytes\n"
      assert tree_files(tmp_dir) == ["brandbook/brand.pin.json"]
    end

    test "init refuses a zip whose hash differs from --expect-sha256 and writes nothing",
         %{tmp_dir: tmp_dir} do
      zip = book_zip(synthetic_files("new"))

      assert pin(:init, [
               [commit: @new_commit, expect_sha256: String.duplicate("0", 64), target_dir: tmp_dir],
               getter_returning(zip)
             ]) == {:error, :zip_hash_mismatch}

      assert File.ls!(tmp_dir) == []
    end

    test "init writes the pin and the four assets from an expected zip", %{tmp_dir: tmp_dir} do
      files = synthetic_files("new")
      zip = book_zip(files)

      assert {:ok, created} =
               pin(:init, [
                 [commit: @new_commit, expect_sha256: sha(zip), target_dir: tmp_dir],
                 getter_returning(zip)
               ])

      assert created["book"] == %{"version" => "2.0", "date" => "2026-11-13"}
      assert tree_files(tmp_dir) == Enum.sort(["brandbook/brand.pin.json" | @required_assets])

      closures = {pin(:tree_read_file, [tmp_dir]), pin(:tree_list_dir, [tmp_dir])}
      assert verify(created, closures) == :ok
      assert pin(:check_zip, [created, zip]) == :ok
    end

    test "fetch refuses a url that is not https and never calls the getter" do
      assert pin(:fetch, ["http://example.com/book.zip", no_network()]) ==
               {:error, :url_not_https}
    end
  end

  describe "extend procedure over an injected getter (D-18)" do
    @describetag :tmp_dir

    defp extend_opts(pin_map, tmp_dir, extra \\ []) do
      [expect_sha256: pin_map["sha256"], target_dir: tmp_dir] ++ extra
    end

    defp extend_fixture do
      files = synthetic_files("base")
      zip = book_zip(files)
      %{files: files, zip: zip, base: base_pin(files, zip)}
    end

    test "writes exactly the expected tree and a pin that verifies and matches the zip",
         %{tmp_dir: tmp_dir} do
      %{files: files, zip: zip, base: base} = extend_fixture()

      assert length(base["shipped"]) == 4

      assert {:ok, extended} =
               pin(:extend, [base, extend_opts(base, tmp_dir), getter_returning(zip)])

      assert_received {:fetched, url}
      assert url == base["url"]

      assert extended["shipped"] |> Enum.map(& &1["to"]) |> Enum.sort() == @expected_shipped
      assert Enum.sort(extended["owned_dirs"]) == Enum.sort(@expected_owned_dirs)

      assert tree_files(tmp_dir) ==
               Enum.sort(["brandbook/brand.pin.json" | @expected_shipped])

      for entry <- extended["shipped"] do
        assert File.read!(tmp_path(tmp_dir, entry["to"])) == files[entry["from"]]
        assert entry["sha256"] == sha(files[entry["from"]])
        assert entry["bytes"] == byte_size(files[entry["from"]])
      end

      assert extended["commit"] == base["commit"]
      assert extended["sha256"] == base["sha256"]
      assert extended["note"] == base["note"]

      closures = {pin(:tree_read_file, [tmp_dir]), pin(:tree_list_dir, [tmp_dir])}
      assert verify(extended, closures) == :ok
      assert pin(:check_zip, [extended, zip]) == :ok

      assert tmp_dir |> Path.join("brandbook/brand.pin.json") |> File.read!() |> Jason.decode!() ==
               extended
    end

    test "the three OFL texts ship to both directories from the same zip member",
         %{tmp_dir: tmp_dir} do
      %{zip: zip, base: base} = extend_fixture()

      assert {:ok, extended} =
               pin(:extend, [base, extend_opts(base, tmp_dir), getter_returning(zip)])

      for name <- ~w(OFL-FunnelDisplay OFL-AtkinsonHyperlegibleNext OFL-AtkinsonHyperlegibleMono) do
        from = "assets/fonts/#{name}.txt"
        tos = for %{"from" => ^from, "to" => to} <- extended["shipped"], do: to

        assert Enum.sort(tos) == ["brandbook/v2/#{name}.txt", "#{@fonts_dir}/#{name}.txt"]
      end
    end

    test "twice is byte-identical, from the base pin and from the extended pin",
         %{tmp_dir: tmp_dir} do
      %{zip: zip, base: base} = extend_fixture()
      opts = extend_opts(base, tmp_dir)
      pin_file = Path.join(tmp_dir, "brandbook/brand.pin.json")

      assert {:ok, extended} = pin(:extend, [base, opts, getter_returning(zip)])
      first_pin = File.read!(pin_file)
      first_tree = for to <- @expected_shipped, do: File.read!(tmp_path(tmp_dir, to))

      assert {:ok, ^extended} = pin(:extend, [base, opts, getter_returning(zip)])
      assert File.read!(pin_file) == first_pin

      assert {:ok, ^extended} = pin(:extend, [extended, opts, getter_returning(zip)])
      assert File.read!(pin_file) == first_pin
      assert for(to <- @expected_shipped, do: File.read!(tmp_path(tmp_dir, to))) == first_tree
      assert String.ends_with?(first_pin, "}\n")
    end

    test "reads a local zip with --zip and never calls the getter", %{tmp_dir: tmp_dir} do
      %{zip: zip, base: base} = extend_fixture()
      zip_path = Path.join(tmp_dir, "local.zip")
      target = Path.join(tmp_dir, "repo")
      File.write!(zip_path, zip)

      assert {:ok, extended} =
               pin(:extend, [
                 base,
                 extend_opts(base, target, zip: zip_path),
                 no_network()
               ])

      assert length(extended["shipped"]) == 16
    end

    test "refuses a local zip that hashes differently from the pin and writes nothing",
         %{tmp_dir: tmp_dir} do
      %{base: base} = extend_fixture()
      zip_path = Path.join(tmp_dir, "other.zip")
      target = Path.join(tmp_dir, "repo")
      File.write!(zip_path, book_zip(synthetic_files("other")))

      assert pin(:extend, [base, extend_opts(base, target, zip: zip_path), no_network()]) ==
               {:error, :zip_hash_mismatch}

      refute File.exists?(target)
    end

    test "refuses an unreadable --zip path before any download", %{tmp_dir: tmp_dir} do
      %{base: base} = extend_fixture()
      missing = Path.join(tmp_dir, "absent.zip")
      target = Path.join(tmp_dir, "repo")

      assert {:error, {:zip_file_unreadable, :enoent}} =
               pin(:extend, [base, extend_opts(base, target, zip: missing), no_network()])

      refute File.exists?(target)
    end

    test "refuses a downloaded zip whose hash differs from the pin and writes nothing",
         %{tmp_dir: tmp_dir} do
      %{base: base} = extend_fixture()
      other = book_zip(synthetic_files("other"))

      assert pin(:extend, [base, extend_opts(base, tmp_dir), getter_returning(other)]) ==
               {:error, :zip_hash_mismatch}

      assert File.ls!(tmp_dir) == []
    end

    test "refuses a zip whose size differs from the pin, even at the pinned hash",
         %{tmp_dir: tmp_dir} do
      %{zip: zip, base: base} = extend_fixture()
      resized = %{base | "size" => base["size"] + 1}

      assert pin(:extend, [resized, extend_opts(resized, tmp_dir), getter_returning(zip)]) ==
               {:error, :zip_size_mismatch}

      assert File.ls!(tmp_dir) == []
    end

    test "refuses an --expect-sha256 that differs from the pin before any download",
         %{tmp_dir: tmp_dir} do
      %{base: base} = extend_fixture()
      wrong = String.duplicate("0", 64)

      assert pin(:extend, [
               base,
               [expect_sha256: wrong, target_dir: tmp_dir],
               no_network()
             ]) == {:error, {:expect_sha256_not_pinned, wrong}}

      assert {:error, {:bad_option, _}} =
               pin(:extend, [base, [expect_sha256: "nope", target_dir: tmp_dir], no_network()])

      assert {:error, {:bad_option, _}} =
               pin(:extend, [base, [target_dir: tmp_dir], no_network()])

      assert File.ls!(tmp_dir) == []
    end

    test "refuses a zip that lacks an extension member before any write", %{tmp_dir: tmp_dir} do
      %{files: files} = extend_fixture()
      from = "assets/logo/mailglass-lockup-dark.svg"
      zip = files |> Map.delete(from) |> book_zip()
      base = base_pin(files, zip)

      assert pin(:extend, [base, extend_opts(base, tmp_dir), getter_returning(zip)]) ==
               {:error, {:zip_member_missing, from}}

      assert File.ls!(tmp_dir) == []
    end

    test "refuses a pinned entry that no longer matches its zip member", %{tmp_dir: tmp_dir} do
      %{zip: zip, base: base} = extend_fixture()
      tampered = with_first_shipped(base, &%{&1 | "sha256" => flip_hex(&1["sha256"])})
      [first | _] = base["shipped"]

      assert pin(:extend, [tampered, extend_opts(tampered, tmp_dir), getter_returning(zip)]) ==
               {:error, {:shipped_member_mismatch, first["from"]}}

      assert File.ls!(tmp_dir) == []
    end

    test "refuses an entry whose to is already pinned from a different member",
         %{tmp_dir: tmp_dir} do
      %{files: files, zip: zip, base: base} = extend_fixture()
      to = @fonts_dir <> "/ui-400.woff2"
      data = files["brand.json"]

      conflicting = %{
        "from" => "brand.json",
        "to" => to,
        "sha256" => sha(data),
        "bytes" => byte_size(data),
        "license" => "OFL-1.1"
      }

      crowded = %{
        base
        | "owned_dirs" => @expected_owned_dirs,
          "shipped" => base["shipped"] ++ [conflicting]
      }

      assert pin(:extend, [crowded, extend_opts(crowded, tmp_dir), getter_returning(zip)]) ==
               {:error, {:extension_conflict, to}}

      assert File.ls!(tmp_dir) == []
    end

    test "refuses a current pin that does not parse", %{tmp_dir: tmp_dir} do
      tampered = %{real_pin() | "shipped" => []}

      assert {:error, {:pin_invalid, issues}} =
               pin(:extend, [tampered, extend_opts(tampered, tmp_dir), no_network()])

      assert :manifest_empty in issue_tags(issues)
      assert File.ls!(tmp_dir) == []
    end

    test "never takes a name from the archive: a hostile extra member is ignored",
         %{tmp_dir: tmp_dir} do
      %{files: files} = extend_fixture()
      zip = book_zip(files, %{"mailglass-brand/../evil.txt" => "hostile"})
      base = base_pin(files, zip)

      assert {:ok, _extended} =
               pin(:extend, [base, extend_opts(base, tmp_dir), getter_returning(zip)])

      assert tree_files(tmp_dir) ==
               Enum.sort(["brandbook/brand.pin.json" | @expected_shipped])
    end
  end

  describe "command line" do
    test "verify reads the real pin and tree" do
      assert pin(:cli, [["verify"]]) == {0, "brand pin ok"}
    end

    test "help says verify is the merge-blocking check and check is advisory" do
      assert {0, text} = pin(:cli, [["help"]])

      assert text =~ "merge-blocking"
      assert text =~ "ADVISORY"
      assert text =~ "update --commit <sha> --expect-sha256 <hex>"
    end

    test "an unknown command prints help and exits 2" do
      assert {2, text} = pin(:cli, [["bogus"]])
      assert text =~ "Usage:"
    end

    test "help names the extend verb and the --zip fallback" do
      assert {0, text} = pin(:cli, [["help"]])

      assert text =~ "extend --expect-sha256 <hex> [--zip <path>]"
      assert text =~ "Idempotent"
    end

    test "update and init without both flags exit 2" do
      assert {2, _} = pin(:cli, [["update"], no_network()])
      assert {2, _} = pin(:cli, [["init", "--commit", @new_commit], no_network()])
    end

    test "extend without --expect-sha256 or with a stray argument exits 2" do
      assert {2, text} = pin(:cli, [["extend"], no_network()])
      assert text =~ "usage: extend --expect-sha256"
      assert {2, _} = pin(:cli, [["extend", "--expect-sha256"], no_network()])

      assert {2, _} =
               pin(:cli, [
                 ["extend", "--expect-sha256", real_pin()["sha256"], "stray"],
                 no_network()
               ])
    end

    test "extend against the real pin refuses an --expect-sha256 that is not the pin, before any download" do
      args = ["extend", "--expect-sha256", String.duplicate("0", 64)]

      assert {1, output} = pin(:cli, [args, no_network()])
      assert output =~ "extend refused"
      assert output =~ "expect_sha256_not_pinned"
    end

    test "extend against the real pin refuses a different zip and writes nothing" do
      zip = book_zip(synthetic_files("new"))
      args = ["extend", "--expect-sha256", real_pin()["sha256"]]

      before_pin = File.read!(@pin_path)

      assert {1, output} = pin(:cli, [args, getter_returning(zip)])
      assert output =~ "zip_hash_mismatch"
      assert File.read!(@pin_path) == before_pin
    end

    test "init against the real tree refuses because the pin exists, before any download" do
      args = ["init", "--commit", @new_commit, "--expect-sha256", String.duplicate("0", 64)]

      assert {1, output} = pin(:cli, [args, no_network()])
      assert output =~ "pin_exists"
    end

    test "update against the real pin refuses a zip with the wrong hash before any write" do
      zip = book_zip(synthetic_files("new"))
      args = ["update", "--commit", @new_commit, "--expect-sha256", String.duplicate("0", 64)]

      assert {1, output} = pin(:cli, [args, getter_returning(zip)])
      assert output =~ "zip_hash_mismatch"
    end

    test "check reports a zip that does not match the real pin and exits 1" do
      zip = book_zip(synthetic_files("new"))

      assert {1, output} = pin(:cli, [["check"], getter_returning(zip)])
      assert output =~ "zip_hash_mismatch"
      assert_received {:fetched, url}
      assert url == real_pin()["url"]
    end

    test "check reports a failed download and exits 1" do
      assert {1, output} = pin(:cli, [["check"], fn _url -> {:error, :nxdomain} end])
      assert output =~ "could not download"
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

  describe "CLI entrypoint under MIX_ENV=test (CR-01)" do
    @tag timeout: 300_000
    test "verify is not vacuous: it prints its verdict" do
      {output, status} =
        System.cmd("mix", ["run", "--no-start", @script, "verify"],
          env: [{"MIX_ENV", "test"}],
          stderr_to_stdout: true
        )

      assert output =~ "brand pin ok"
      assert status == 0
    end
  end
end
