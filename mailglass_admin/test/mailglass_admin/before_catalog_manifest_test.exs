defmodule MailglassAdmin.BeforeCatalogManifestTest do
  @moduledoc """
  Validates every committed "before" catalog under
  `.planning/research/brand-v2-adoption/before-catalog/<catalog_id>/` (BRPIPE-03).

  Lane: this file runs in the required `support_contract_admin` lane
  (`mix verify.support_contract.admin`, the whole test directory). The capture run itself is
  not CI and the demo browser lanes are advisory; this test is what makes the catalog more
  than an unverified claim. It must land in the same PR as the catalog, because a
  `.planning`-only change skips the lane.

  ## What is checked, for every catalog directory

    * the manifest has the closed `mailglass.before_catalog.v1` schema (no unknown key, no
      missing key, no environment values);
    * every listed PNG exists with the recorded sha256, byte size and a valid PNG header whose
      IHDR width and height match the manifest, every aria sidecar exists with its recorded
      sha256, and nothing else is in the directory (only `manifest.json`, `cases.json`, the
      optional `superseded.json`, the listed PNGs and the listed aria sidecars);
    * file names are slugs confined to the catalog directory (a traversal name is red);
    * `git_sha` is 40 hex characters whose first seven are the sha7 in the `catalog_id`, the
      capture was taken on a clean tree (`dirty` false, both recheck flags true), image count
      and bytes are within the 80 image / 15,000,000 byte budget and `nested_theme_attr_count`
      is 0;
    * the seeded delivery cases follow the milestone stop line (D-22): the catalog seed text
      carries no retry-timing phrase and no `"reason"`/`"cause"` metadata key, and the
      committed `cases.json` keeps the two nil-reason seeded cases free of any rejection
      reason and any error;
    * no committed text names the demo reset token or an email address outside the reserved
      example domains.

  ## Source binding (D-24, refined)

  The manifest cannot hold the commit that adds it, and `main` is squash-merged, so after merge
  the recorded source commit is not in `main`'s history. A perpetual "git_sha is an ancestor of
  HEAD" check would therefore be red or skipped, and the required lane's checkout is depth 1,
  so it could not run there anyway. This test never shells out to git and never needs a git
  object. It binds the catalog to the repository through working-tree bytes, on every run:

    1. `source.bundle.sha256` must equal the sha256 of the served `css-<md5>` asset recorded in
       the same manifest (and the blob shas must agree), so the manifest is internally honest.
    2. The checkout's `mailglass_admin/priv/static/app.css` (sha256) and
       `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` (git blob sha1) are
       recomputed from file bytes. While both equal the manifest's recorded values the catalog
       is LIVE and must carry no `superseded.json`.
    3. While either differs the catalog is SUPERSEDED: `<catalog_id>/superseded.json` is
       accepted only if its `superseded_by.bundle_sha256` equals the checkout's CURRENT app.css
       sha256 and its `superseded_by.root_layout_git_blob_sha` equals the checkout's CURRENT
       root layout blob sha1. A missing, malformed or wrong marker is red, and so is a
       once-valid marker after any further bundle or root-layout change.

  The red message prints the catalog id, the checkout's current two values and the two fixes.
  Hand-off: the token swap PR (Phase 181) adds `<catalog_id>/superseded.json` whose
  `superseded_by` equals the new bundle sha256 and root layout blob sha1 in the same change;
  every later bundle or root-layout change updates `superseded_by` in its own PR (one marker
  update per change); the catalog PNGs, `cases.json` and `manifest.json` never change.

  ## Disclosed limits (nothing in this test catches these)

    * A PR that rewrites `source.bundle`, `served.assets` and `source.root_layout` in
      `manifest.json` in lockstep to new bytes passes the LIVE branch. That class is
      review-only (it would also change the manifest sha256 that Phases 182-183 cite, which a
      reviewer sees in the diff).
    * Only the bundle bytes and the root layout are durably bound. `lib/**`,
      `brandbook/tokens.css`, `reference/demo_app/lib` and `assets/` are verified only once, when
      the phase PR opens, by the recorded render-input diff; after merge, a catalog made stale
      by those inputs is caught by Phase 182's reviewer, not by this lane.

  ## Teeth

  Every rule has a mutation case on a synthetic catalog built in a temp directory (a flipped
  byte, an unlisted PNG, `dirty: true`, an over-cap budget, a traversal name, each source
  binding branch including a well-formed marker that names the wrong bytes and a marker made
  stale by a further change, and each seeded-case rule). The validators are pure functions of
  a catalog directory and options (`repo_root:`, `seed_source:`), so a planted bad input goes
  through the same code path as the committed catalog and the pass is not vacuous.
  """

  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)
  @catalog_root Path.join(@repo_root, ".planning/research/brand-v2-adoption/before-catalog")
  @seed_source_path Path.join(@repo_root, "reference/demo_app/lib/mailglass_demo/catalog_seed.ex")
  @bundle_rel "mailglass_admin/priv/static/app.css"
  @layout_rel "mailglass_admin/lib/mailglass_admin/layouts/root.html.heex"

  @schema "mailglass.before_catalog.v1"
  @superseded_schema "mailglass.before_catalog.superseded.v1"
  @cap_images 80
  @cap_bytes 15_000_000
  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>
  @reset_token "mailglass-dev-demo"

  @top_keys ~w(schema catalog_id run_id source_revision source_digest source served cases tools
               determinism budget nested_theme_attr_count captures)
  @source_keys ~w(git_sha dirty branch tree_sha committed_at bundle root_layout recheck)
  @bundle_keys ~w(path sha256 git_blob_sha)
  @layout_keys ~w(path git_blob_sha)
  @recheck_keys ~w(clean head_unchanged)
  @served_keys ~w(assets server_started_at)
  @asset_keys ~w(url_path sha256 matches_disk matches_git_blob git_blob_sha)
  @cases_ref_keys ~w(file sha256)
  @tools_keys ~w(playwright chromium node os script_sha256)
  @determinism_keys ~w(tz locale fixed_time seed_anchor_utc reduced_motion animations dsf
                       fonts_loaded double_capture_identical)
  @budget_keys ~w(image_count total_bytes cap_images cap_bytes)
  @capture_keys ~w(id file sha256 bytes w h screen route fixture state case viewport theme
                   root_theme_attr tier aria_file aria_sha256 stop_line_hits)
  @superseded_keys ~w(schema catalog_id superseded_by superseded_in reason)
  @superseded_by_keys ~w(bundle_sha256 root_layout_git_blob_sha)

  @case_slugs ~w(typo-bounce send-failed sent-no-report unicode-recipient nil-reason-bounce
                 deferred-no-retry delivered-no-open long-recipient complained manual-suppressed)
  @seeded_slugs ~w(typo-bounce send-failed sent-no-report unicode-recipient)
  @case_keys ~w(source delivery_id provider_message_id recipient scenario status reject_reason
                last_error_present metadata_keys)

  @reserved_domains ~w(example.com example.net example.org)
  @reserved_suffixes ~w(.example.com .example .local .test .invalid .localhost)

  # ---------------------------------------------------------------------------------------
  # The committed catalog
  # ---------------------------------------------------------------------------------------

  describe "the committed before-catalog" do
    test "the catalog directory exists and holds at least one catalog" do
      assert File.dir?(@catalog_root), "#{rel(@catalog_root)} is missing"
      assert [_ | _] = catalog_dirs(), "#{rel(@catalog_root)} holds no catalog directory"
    end

    test "every catalog directory validates, and each has at least one capture" do
      for dir <- catalog_dirs() do
        assert {:ok, manifest} = read_json(Path.join(dir, "manifest.json"))
        assert [_ | _] = manifest["captures"], "#{Path.basename(dir)} lists no capture"

        failures = validate_catalog(dir)
        assert failures == [], failure_message(dir, failures)

        {:ok, state} = binding_state(manifest, @repo_root)
        IO.puts("catalog #{Path.basename(dir)}: #{state |> elem(0) |> state_label()}")
      end
    end
  end

  # ---------------------------------------------------------------------------------------
  # Teeth: synthetic catalog, every rule proven red
  # ---------------------------------------------------------------------------------------

  describe "teeth: file and budget rules" do
    setup :fixture

    test "the unmutated synthetic catalog is clean (positive control)", fx do
      assert validate(fx) == []
    end

    test "a flipped PNG byte names the sha256 mismatch", fx do
      png = Path.join(fx.dir, fx.png_names |> hd())
      <<first, rest::binary>> = File.read!(png)
      File.write!(png, <<Bitwise.bxor(first, 0xFF), rest::binary>>)
      assert_red(validate(fx), "sha256 mismatch")
    end

    test "an unlisted PNG names the unlisted file", fx do
      File.write!(Path.join(fx.dir, "extra__any__default__375__light.png"), "x")
      assert_red(validate(fx), "unlisted file")
    end

    test "an unlisted aria sidecar and a nested directory are unlisted files too", fx do
      File.mkdir_p!(Path.join(fx.dir, "aria"))
      File.write!(Path.join(fx.dir, "aria/extra.yml"), "- heading\n")
      File.mkdir_p!(Path.join(fx.dir, "sub"))
      File.write!(Path.join(fx.dir, "sub/x.png"), "x")
      failures = validate(fx)
      assert_red(failures, "unlisted file aria/extra.yml")
      assert_red(failures, "unlisted file sub/x.png")
    end

    test "dirty true is red", fx do
      update_manifest(fx, &put_in(&1, ["source", "dirty"], true))
      assert_red(validate(fx), "dirty")
    end

    test "a failed recheck flag is red", fx do
      update_manifest(fx, &put_in(&1, ["source", "recheck", "clean"], false))
      assert_red(validate(fx), "recheck")
    end

    test "image_count 81 is red", fx do
      update_manifest(fx, &put_in(&1, ["budget", "image_count"], 81))
      assert_red(validate(fx), "image_count")
    end

    test "total_bytes over the cap is red", fx do
      update_manifest(fx, &put_in(&1, ["budget", "total_bytes"], @cap_bytes + 1))
      assert_red(validate(fx), "total_bytes")
    end

    test "a traversal file name is rejected", fx do
      update_manifest(fx, fn manifest ->
        update_in(manifest, ["captures", Access.at(0), "file"], fn _ -> "../x.png" end)
      end)

      assert_red(validate(fx), "slug")
    end

    test "nested_theme_attr_count 1 is red", fx do
      update_manifest(fx, &Map.put(&1, "nested_theme_attr_count", 1))
      assert_red(validate(fx), "nested_theme_attr_count")
    end

    test "an unknown top-level key is red", fx do
      update_manifest(fx, &Map.put(&1, "env", %{"HOME" => "/home/someone"}))
      assert_red(validate(fx), "unknown key")
    end

    test "a missing top-level key is red", fx do
      update_manifest(fx, &Map.delete(&1, "determinism"))
      assert_red(validate(fx), "missing key")
    end

    test "a PNG whose header width differs from the manifest is red", fx do
      update_manifest(fx, fn manifest ->
        update_in(manifest, ["captures", Access.at(0), "w"], &(&1 + 1))
      end)

      assert_red(validate(fx), "IHDR")
    end

    test "a file that is not a PNG is red", fx do
      png = Path.join(fx.dir, hd(fx.png_names))
      File.write!(png, "not a png")
      refresh_capture_hashes(fx)
      assert_red(validate(fx), "PNG")
    end

    test "a git_sha whose first seven characters differ from the catalog_id is red", fx do
      update_manifest(fx, fn manifest ->
        sha = "ffffffff" <> String.duplicate("0", 32)

        manifest
        |> put_in(["source", "git_sha"], sha)
        |> Map.put("source_revision", sha)
      end)

      assert_red(validate(fx), "sha7")
    end
  end

  describe "teeth: privacy rules" do
    setup :fixture

    test "the demo reset token in the manifest is red", fx do
      update_manifest(fx, &put_in(&1, ["tools", "os"], "linux #{@reset_token}"))
      assert_red(validate(fx), "reset token")
    end

    test "a non-reserved email in an aria sidecar is red; reserved domains are clean", fx do
      aria = Path.join(fx.dir, hd(fx.aria_names))

      File.write!(
        aria,
        "- text: a@b.example\n- text: x@example.com\n- text: zoë@northstar.example\n"
      )

      refresh_capture_hashes(fx)
      assert validate(fx) == []

      File.write!(aria, "- text: someone@gmail.com\n")
      refresh_capture_hashes(fx)
      assert_red(validate(fx), "someone@gmail.com")
    end
  end

  describe "teeth: source binding" do
    setup :fixture

    test "(i) unmodified copies and no marker is clean and LIVE", fx do
      assert validate(fx) == []
      {:ok, manifest} = read_json(Path.join(fx.dir, "manifest.json"))
      assert {:ok, {:live, _}} = binding_state(manifest, fx.repo_root)
    end

    test "(ii) one bundle byte changed and no marker is red, naming superseded.json and recapture",
         fx do
      change_bundle(fx)
      failures = validate(fx)
      assert_red(failures, "superseded.json")
      assert_red(failures, "recapture")
    end

    test "(iii) the root layout changed and no marker is red", fx do
      change_layout(fx)
      assert_red(validate(fx), "superseded.json")
    end

    test "(iv) a bundle change with a marker naming the checkout's current bytes is clean", fx do
      change_bundle(fx)
      write_marker(fx, current_values(fx))
      assert validate(fx) == []
    end

    test "(iv) a root layout change with a marker naming the current bytes is clean", fx do
      change_layout(fx)
      write_marker(fx, current_values(fx))
      assert validate(fx) == []
    end

    test "(v) unmodified copies plus a well-formed marker is red: marked superseded but still matches",
         fx do
      write_marker(fx, current_values(fx))
      assert_red(validate(fx), "marked superseded but still matches")
    end

    test "(vi) a marker naming the recorded values is red", fx do
      change_bundle(fx)
      recorded = recorded_values(fx)
      write_marker(fx, recorded)
      assert_red(validate(fx), "superseded_by")
    end

    test "(vi) a marker with the wrong catalog_id is red", fx do
      change_bundle(fx)
      write_marker(fx, current_values(fx), %{"catalog_id" => "before-0000000-20200101T000000Z"})
      assert_red(validate(fx), "catalog_id")
    end

    test "(vi) a marker with an unknown key is red", fx do
      change_bundle(fx)
      write_marker(fx, current_values(fx), %{"approved_by" => "someone"})
      assert_red(validate(fx), "unknown key")
    end

    test "(vi) a malformed marker is red", fx do
      change_bundle(fx)
      File.write!(Path.join(fx.dir, "superseded.json"), "{not json")
      assert_red(validate(fx), "superseded.json")
    end

    test "(x) a well-formed marker with the wrong bundle_sha256 is red and prints the current value",
         fx do
      change_bundle(fx)
      current = current_values(fx)
      wrong = %{current | "bundle_sha256" => String.duplicate("a", 64)}
      write_marker(fx, wrong)
      failures = validate(fx)
      assert_red(failures, "superseded_by.bundle_sha256")
      assert_red(failures, current["bundle_sha256"])
    end

    test "(x) a well-formed marker with the wrong root layout blob is red and prints the current value",
         fx do
      change_layout(fx)
      current = current_values(fx)
      wrong = %{current | "root_layout_git_blob_sha" => String.duplicate("b", 40)}
      write_marker(fx, wrong)
      failures = validate(fx)
      assert_red(failures, "superseded_by.root_layout_git_blob_sha")
      assert_red(failures, current["root_layout_git_blob_sha"])
    end

    test "(xi) a once-valid marker is red after a further bundle change", fx do
      change_bundle(fx)
      write_marker(fx, current_values(fx))
      assert validate(fx) == []

      File.write!(bundle_path(fx), File.read!(bundle_path(fx)) <> "/* later change */\n")
      assert_red(validate(fx), "superseded_by.bundle_sha256")
    end

    test "(xi) a once-valid marker is red after a further root layout change", fx do
      change_bundle(fx)
      write_marker(fx, current_values(fx))
      assert validate(fx) == []

      File.write!(layout_path(fx), File.read!(layout_path(fx)) <> "<!-- later change -->\n")
      assert_red(validate(fx), "superseded_by.root_layout_git_blob_sha")
    end

    test "(vii) source.bundle.sha256 differing from the served css sha256 is red", fx do
      update_manifest(fx, &put_in(&1, ["source", "bundle", "sha256"], String.duplicate("c", 64)))
      assert_red(validate(fx), "served css")
    end

    test "a served css blob sha that differs from source.bundle is red", fx do
      update_manifest(fx, fn manifest ->
        update_in(manifest, ["served", "assets", Access.at(0), "git_blob_sha"], fn _ ->
          String.duplicate("d", 40)
        end)
      end)

      assert_red(validate(fx), "git_blob_sha")
    end

    test "a stale server (served bytes differ from disk) is red", fx do
      update_manifest(fx, fn manifest ->
        update_in(manifest, ["served", "assets", Access.at(0), "matches_disk"], fn _ -> false end)
      end)

      assert_red(validate(fx), "matches_disk")
    end

    test "a server started before the source commit is red", fx do
      update_manifest(
        fx,
        &put_in(&1, ["served", "server_started_at"], "2000-01-01T00:00:00.000Z")
      )

      assert_red(validate(fx), "server_started_at")
    end
  end

  describe "teeth: seeded-case rules (D-22)" do
    setup :fixture

    test "a planted retry-timing phrase in the seed text is red" do
      for phrase <- [
            "next try at noon",
            "we will retry",
            "retry at 10:00",
            "Retrying soon",
            "WILL RETRY"
          ] do
        assert_red(seed_text_failures("# #{phrase}\n"), "retry-timing")
      end
    end

    test "planted metadata keys named reason, cause or a retry time are red" do
      for key <- ["reason", "cause", "retry_at", "next_retry_at"] do
        assert_red(seed_text_failures(~s|%{"#{key}" => "x"}|), "metadata key")
      end

      assert seed_text_failures("defmodule CatalogSeed do\n  @reject :invalid\nend\n") == []
    end

    test "the committed seed text is clean" do
      assert seed_text_failures(File.read!(@seed_source_path)) == []
    end

    test "a planted phrase in the seed source fails the catalog", fx do
      failures = validate(fx, seed_source: "# will retry\n")
      assert_red(failures, "retry-timing")
    end

    test "reason added to the sent-no-report metadata_keys is red", fx do
      update_cases(fx, fn cases ->
        update_in(
          cases,
          ["cases", "sent-no-report", "metadata_keys"],
          &(["reason" | &1] |> Enum.sort())
        )
      end)

      assert_red(validate(fx), "sent-no-report")
    end

    test "last_error_present true on unicode-recipient is red", fx do
      update_cases(fx, &put_in(&1, ["cases", "unicode-recipient", "last_error_present"], true))
      assert_red(validate(fx), "unicode-recipient")
    end

    test "a reject_reason on a nil-reason seeded case is red", fx do
      update_cases(fx, &put_in(&1, ["cases", "sent-no-report", "reject_reason"], "other"))
      assert_red(validate(fx), "nil-reason")
    end

    test "typo-bounce must carry reject_reason invalid", fx do
      update_cases(fx, &put_in(&1, ["cases", "typo-bounce", "reject_reason"], nil))
      assert_red(validate(fx), "typo-bounce")
    end

    test "send-failed must be failed with its own recorded error and no reason", fx do
      update_cases(fx, &put_in(&1, ["cases", "send-failed", "last_error_present"], false))
      assert_red(validate(fx), "send-failed")
    end

    test "a missing case and a wrong seeded count are red", fx do
      update_cases(fx, &update_in(&1, ["cases"], fn cases -> Map.delete(cases, "complained") end))
      assert_red(validate(fx), "ten cases")
    end

    test "cases.json changed without a manifest update is red", fx do
      path = Path.join(fx.dir, "cases.json")
      File.write!(path, File.read!(path) <> "\n")
      assert_red(validate(fx), "cases.json")
    end
  end

  # ---------------------------------------------------------------------------------------
  # Validators: pure functions of a catalog directory plus options. Nothing here shells out.
  # ---------------------------------------------------------------------------------------

  defp validate_catalog(dir, opts \\ []) do
    repo_root = Keyword.get(opts, :repo_root, @repo_root)
    seed_source = Keyword.get_lazy(opts, :seed_source, fn -> File.read!(@seed_source_path) end)

    case read_json(Path.join(dir, "manifest.json")) do
      {:ok, manifest} when is_map(manifest) ->
        shape_failures(manifest, dir) ++
          file_failures(manifest, dir) ++
          budget_failures(manifest, dir) ++
          binding_failures(manifest, dir, repo_root) ++
          cases_failures(manifest, dir, seed_source) ++
          privacy_failures(dir)

      {:ok, _other} ->
        ["manifest.json must be a JSON object"]

      {:error, reason} ->
        ["manifest.json is unreadable: #{inspect(reason)}"]
    end
  end

  defp failure_message(dir, failures) do
    lines = Enum.map_join(failures, "\n", &"  - #{&1}")

    "#{rel(dir)} fails validation:\n#{lines}\n" <>
      "The catalog PNGs, cases.json and manifest.json are immutable evidence: recapture under a " <>
      "new catalog_id instead of editing them. A moved bundle or root layout needs a current " <>
      "superseded.json (see this test's moduledoc)."
  end

  # -- shape ------------------------------------------------------------------------------

  defp shape_failures(manifest, dir) do
    id = Path.basename(dir)
    source = manifest["source"]
    served = manifest["served"]
    determinism = manifest["determinism"]

    exact_keys(manifest, @top_keys, "manifest") ++
      check(manifest["schema"] == @schema, "schema must be #{@schema}") ++
      check(manifest["catalog_id"] == id, "catalog_id must equal the directory name #{id}") ++
      check(
        Regex.match?(~r/\Abefore-[0-9a-f]{7}-\d{8}T\d{6}Z\z/, id),
        "the directory name #{id} must be before-<sha7>-<YYYYMMDDTHHMMSSZ>"
      ) ++
      check(
        is_binary(manifest["run_id"]) and
          Regex.match?(~r/\Amailglass-evidence-\d{14}-\d+-\d+\z/, manifest["run_id"]),
        "run_id must look like mailglass-evidence-<stamp>-<pid>-<rand>"
      ) ++
      check(hex?(manifest["source_digest"], 64), "source_digest must be 64 hex characters") ++
      source_shape_failures(source, manifest, id) ++
      served_shape_failures(served, source) ++
      exact_keys(manifest["cases"], @cases_ref_keys, "cases") ++
      check(
        is_map(manifest["cases"]) and manifest["cases"]["file"] == "cases.json",
        "cases.file must be cases.json"
      ) ++
      tools_failures(manifest["tools"]) ++
      determinism_failures(determinism) ++
      exact_keys(manifest["budget"], @budget_keys, "budget") ++
      check(manifest["nested_theme_attr_count"] == 0, "nested_theme_attr_count must be 0") ++
      capture_shape_failures(manifest["captures"])
  end

  defp source_shape_failures(source, manifest, id) when is_map(source) do
    sha7 =
      case Regex.run(~r/\Abefore-([0-9a-f]{7})-/, id) do
        [_, sha7] -> sha7
        _ -> nil
      end

    git_sha = source["git_sha"]
    bundle = source["bundle"]
    layout = source["root_layout"]
    recheck = source["recheck"]

    exact_keys(source, @source_keys, "source") ++
      check(hex?(git_sha, 40), "source.git_sha must be 40 hex characters") ++
      check(
        is_binary(git_sha) and sha7 != nil and String.slice(git_sha, 0, 7) == sha7,
        "source.git_sha must start with the sha7 in the catalog_id (#{inspect(sha7)})"
      ) ++
      check(manifest["source_revision"] == git_sha, "source_revision must equal source.git_sha") ++
      check(
        source["dirty"] == false,
        "source.dirty must be false: the capture needs a clean tree"
      ) ++
      check(
        is_binary(source["branch"]) and source["branch"] != "",
        "source.branch must be a string"
      ) ++
      check(hex?(source["tree_sha"], 40), "source.tree_sha must be 40 hex characters") ++
      check(
        match?({:ok, _, _}, parse_time(source["committed_at"])),
        "source.committed_at must be ISO-8601"
      ) ++
      exact_keys(bundle, @bundle_keys, "source.bundle") ++
      check(
        is_map(bundle) and bundle["path"] == @bundle_rel,
        "source.bundle.path must be #{@bundle_rel}"
      ) ++
      check(
        is_map(bundle) and hex?(bundle["sha256"], 64),
        "source.bundle.sha256 must be 64 hex characters"
      ) ++
      check(
        is_map(bundle) and hex?(bundle["git_blob_sha"], 40),
        "source.bundle.git_blob_sha must be 40 hex characters"
      ) ++
      exact_keys(layout, @layout_keys, "source.root_layout") ++
      check(
        is_map(layout) and layout["path"] == @layout_rel,
        "source.root_layout.path must be #{@layout_rel}"
      ) ++
      check(
        is_map(layout) and hex?(layout["git_blob_sha"], 40),
        "source.root_layout.git_blob_sha must be 40 hex characters"
      ) ++
      exact_keys(recheck, @recheck_keys, "source.recheck") ++
      check(
        is_map(recheck) and recheck["clean"] == true and recheck["head_unchanged"] == true,
        "source.recheck.clean and source.recheck.head_unchanged must both be true (recheck before promote)"
      )
  end

  defp source_shape_failures(_source, _manifest, _id), do: ["source must be an object"]

  defp served_shape_failures(served, source) when is_map(served) do
    assets = served["assets"]
    bundle = if is_map(source), do: source["bundle"], else: nil

    asset_failures =
      if is_list(assets) and assets != [] do
        Enum.flat_map(Enum.with_index(assets), fn {asset, index} ->
          label = "served.assets[#{index}]"

          exact_keys(asset, @asset_keys, label) ++
            check(
              is_map(asset) and hex?(asset["sha256"], 64),
              "#{label}.sha256 must be 64 hex characters"
            ) ++
            check(
              is_map(asset) and hex?(asset["git_blob_sha"], 40),
              "#{label}.git_blob_sha must be 40 hex characters"
            ) ++
            check(
              is_map(asset) and asset["matches_disk"] == true,
              "#{label}.matches_disk must be true (stale server)"
            ) ++
            check(
              is_map(asset) and asset["matches_git_blob"] == true,
              "#{label}.matches_git_blob must be true (stale server)"
            )
        end)
      else
        ["served.assets must be a non-empty list"]
      end

    css =
      if is_list(assets),
        do:
          Enum.find(
            assets,
            &(is_map(&1) and is_binary(&1["url_path"]) and
                Regex.match?(~r|/css-[0-9a-f]{32}\z|, &1["url_path"]))
          ),
        else: nil

    css_failures =
      cond do
        css == nil ->
          ["served.assets must include the css-<md5> bundle"]

        is_map(bundle) ->
          check(
            css["sha256"] == bundle["sha256"],
            "source.bundle.sha256 must equal the served css asset sha256"
          ) ++
            check(
              css["git_blob_sha"] == bundle["git_blob_sha"],
              "source.bundle.git_blob_sha must equal the served css asset git_blob_sha"
            )

        true ->
          []
      end

    started_failures =
      with {:ok, started, _} <- parse_time(served["server_started_at"]),
           true <- is_map(source),
           {:ok, committed, _} <- parse_time(source["committed_at"]) do
        check(
          DateTime.compare(started, committed) == :gt,
          "served.server_started_at must be later than source.committed_at (the server was restarted after the commit)"
        )
      else
        _ -> ["served.server_started_at and source.committed_at must be ISO-8601"]
      end

    exact_keys(served, @served_keys, "served") ++
      asset_failures ++ css_failures ++ started_failures
  end

  defp served_shape_failures(_served, _source), do: ["served must be an object"]

  defp tools_failures(tools) when is_map(tools) do
    exact_keys(tools, @tools_keys, "tools") ++
      Enum.flat_map(~w(playwright chromium node os), fn key ->
        check(
          is_binary(tools[key]) and tools[key] != "",
          "tools.#{key} must be a non-empty string"
        )
      end) ++
      check(hex?(tools["script_sha256"], 64), "tools.script_sha256 must be 64 hex characters")
  end

  defp tools_failures(_), do: ["tools must be an object"]

  defp determinism_failures(det) when is_map(det) do
    exact_keys(det, @determinism_keys, "determinism") ++
      check(det["tz"] == "UTC", "determinism.tz must be UTC") ++
      check(det["locale"] == "en-US", "determinism.locale must be en-US") ++
      check(
        Map.has_key?(det, "fixed_time") and det["fixed_time"] == nil,
        "determinism.fixed_time must be null (the seed minute is recorded instead)"
      ) ++
      check(
        match?({:ok, _, _}, parse_time(det["seed_anchor_utc"])),
        "determinism.seed_anchor_utc must be ISO-8601"
      ) ++
      check(det["reduced_motion"] == "reduce", "determinism.reduced_motion must be reduce") ++
      check(det["animations"] == "disabled", "determinism.animations must be disabled") ++
      check(det["dsf"] == 1, "determinism.dsf must be 1") ++
      check(
        is_list(det["fonts_loaded"]) and det["fonts_loaded"] != [] and
          Enum.all?(det["fonts_loaded"], &is_binary/1),
        "determinism.fonts_loaded must list the loaded font faces"
      ) ++
      check(
        det["double_capture_identical"] == true,
        "determinism.double_capture_identical must be true"
      )
  end

  defp determinism_failures(_), do: ["determinism must be an object"]

  defp capture_shape_failures(captures) when is_list(captures) and captures != [] do
    ids = Enum.map(captures, &if(is_map(&1), do: &1["id"], else: nil))

    unique = check(length(Enum.uniq(ids)) == length(ids), "captures must have unique ids")

    unique ++
      Enum.flat_map(Enum.with_index(captures), fn {capture, index} ->
        label = "captures[#{index}]"

        if is_map(capture) do
          exact_keys(capture, @capture_keys, label) ++
            check(hex?(capture["sha256"], 64), "#{label}.sha256 must be 64 hex characters") ++
            check(
              hex?(capture["aria_sha256"], 64),
              "#{label}.aria_sha256 must be 64 hex characters"
            ) ++
            check(
              pos_int?(capture["bytes"]) and pos_int?(capture["w"]) and pos_int?(capture["h"]),
              "#{label} bytes, w and h must be positive integers"
            ) ++
            check(capture["theme"] in ["light", "dark"], "#{label}.theme must be light or dark") ++
            check(
              capture["root_theme_attr"] == "mailglass-#{capture["theme"]}",
              "#{label}.root_theme_attr must be mailglass-<theme>"
            ) ++
            check(capture["tier"] in ~w(A B C D E), "#{label}.tier must be A, B, C, D or E") ++
            check(is_integer(capture["viewport"]), "#{label}.viewport must be an integer") ++
            check(
              is_list(capture["stop_line_hits"]) and
                Enum.all?(capture["stop_line_hits"], &is_binary/1),
              "#{label}.stop_line_hits must be a list of strings"
            )
        else
          ["#{label} must be an object"]
        end
      end)
  end

  defp capture_shape_failures(_), do: ["captures must be a non-empty list"]

  # -- files ------------------------------------------------------------------------------

  defp file_failures(manifest, dir) do
    captures = list(manifest["captures"]) |> Enum.filter(&is_map/1)

    per_capture =
      Enum.flat_map(captures, fn capture ->
        png_failures(capture, dir) ++ aria_failures(capture, dir)
      end)

    cases_file = Path.join(dir, "cases.json")

    cases_failures =
      case File.read(cases_file) do
        {:ok, bytes} ->
          expected = get_in(manifest, ["cases", "sha256"])

          check(
            sha256(bytes) == expected,
            "cases.json sha256 mismatch: manifest.cases.sha256 does not match the file (cases.json is immutable)"
          )

        {:error, _} ->
          ["cases.json is missing"]
      end

    per_capture ++ cases_failures ++ unlisted_failures(captures, dir)
  end

  defp png_failures(capture, dir) do
    file = capture["file"]
    id = capture["id"]

    cond do
      not (is_binary(file) and Regex.match?(~r/\A[a-z0-9_.-]+\.png\z/, file)) ->
        [
          "capture #{inspect(id)}: file #{inspect(file)} is not a slug name (separators and traversal are rejected)"
        ]

      file != "#{id}.png" ->
        ["capture #{inspect(id)}: file #{file} must be #{id}.png"]

      true ->
        path = Path.join(dir, file)

        with :ok <- confined(path, dir),
             {:ok, %File.Stat{type: :regular}} <- File.lstat(path),
             {:ok, bytes} <- File.read(path) do
          check(
            sha256(bytes) == capture["sha256"],
            "#{file}: sha256 mismatch against the manifest (the PNG changed)"
          ) ++
            check(
              byte_size(bytes) == capture["bytes"],
              "#{file}: byte size differs from the manifest"
            ) ++
            png_header_failures(file, bytes, capture)
        else
          _ ->
            [
              "#{file}: listed in the manifest but missing, unreadable, not a regular file or outside the catalog directory"
            ]
        end
    end
  end

  defp png_header_failures(file, bytes, capture) do
    case bytes do
      <<signature::binary-size(8), 13::unsigned-big-32, "IHDR", width::unsigned-big-32,
        height::unsigned-big-32, bit_depth, color_type, compression, filter, interlace,
        ihdr_crc::unsigned-big-32, _rest::binary>> ->
        ihdr = binary_part(bytes, 12, 17)

        check(signature == @png_signature, "#{file}: bad PNG signature") ++
          check(
            width > 0 and height > 0 and compression == 0 and filter == 0 and interlace in [0, 1] and
              bit_depth in [1, 2, 4, 8, 16] and color_type in [0, 2, 3, 4, 6],
            "#{file}: invalid PNG IHDR fields"
          ) ++
          check(:erlang.crc32(ihdr) == ihdr_crc, "#{file}: PNG IHDR checksum mismatch") ++
          check(
            width == capture["w"] and height == capture["h"],
            "#{file}: PNG IHDR is #{width}x#{height} but the manifest records #{capture["w"]}x#{capture["h"]}"
          )

      _ ->
        ["#{file}: not a PNG (invalid or incomplete IHDR header)"]
    end
  end

  defp aria_failures(capture, dir) do
    aria = capture["aria_file"]
    id = capture["id"]

    cond do
      not (is_binary(aria) and Regex.match?(~r{\Aaria/[a-z0-9_.-]+\.yml\z}, aria)) ->
        ["capture #{inspect(id)}: aria_file #{inspect(aria)} is not a slug name under aria/"]

      aria != "aria/#{id}.yml" ->
        ["capture #{inspect(id)}: aria_file must be aria/#{id}.yml"]

      true ->
        path = Path.join(dir, aria)

        with :ok <- confined(path, dir),
             {:ok, %File.Stat{type: :regular}} <- File.lstat(path),
             {:ok, bytes} <- File.read(path) do
          check(
            sha256(bytes) == capture["aria_sha256"],
            "#{aria}: sha256 mismatch against the manifest"
          )
        else
          _ -> ["#{aria}: listed in the manifest but missing, unreadable or not a regular file"]
        end
    end
  end

  defp unlisted_failures(captures, dir) do
    allowed =
      ["manifest.json", "cases.json", "superseded.json"] ++
        Enum.flat_map(captures, fn capture -> [capture["file"], capture["aria_file"]] end)

    dir
    |> files_under()
    |> Enum.reject(&(&1 in allowed))
    |> Enum.map(
      &"unlisted file #{&1} (only manifest.json, cases.json, superseded.json and the listed PNGs and aria sidecars are allowed)"
    )
  end

  # Every non-directory entry under dir, as a path relative to dir (symlinks included).
  defp files_under(dir) do
    dir
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.reject(fn path ->
      match?({:ok, %File.Stat{type: :directory}}, File.lstat(path))
    end)
    |> Enum.map(&Path.relative_to(&1, dir))
    |> Enum.sort()
  end

  defp confined(path, dir) do
    expanded = Path.expand(path)
    root = Path.expand(dir)
    if String.starts_with?(expanded, root <> "/"), do: :ok, else: :error
  end

  # -- budget -----------------------------------------------------------------------------

  defp budget_failures(manifest, _dir) do
    budget = manifest["budget"]
    captures = list(manifest["captures"]) |> Enum.filter(&is_map/1)
    sum = captures |> Enum.map(&(&1["bytes"] || 0)) |> Enum.filter(&is_integer/1) |> Enum.sum()

    if is_map(budget) do
      check(
        budget["cap_images"] == @cap_images and budget["cap_bytes"] == @cap_bytes,
        "budget caps must record #{@cap_images} images and #{@cap_bytes} bytes"
      ) ++
        check(
          is_integer(budget["image_count"]) and budget["image_count"] <= @cap_images,
          "budget.image_count must be at most #{@cap_images}"
        ) ++
        check(
          budget["image_count"] == length(captures),
          "budget.image_count must equal the number of captures (#{length(captures)})"
        ) ++
        check(
          is_integer(budget["total_bytes"]) and budget["total_bytes"] <= @cap_bytes,
          "budget.total_bytes must be at most #{@cap_bytes}"
        ) ++
        check(
          budget["total_bytes"] == sum,
          "budget.total_bytes must equal the sum of the capture bytes (#{sum})"
        )
    else
      []
    end
  end

  # -- source binding ---------------------------------------------------------------------

  # {:ok, {:live | :superseded, current}} | {:error, message}
  defp binding_state(manifest, repo_root) do
    bundle_path = Path.join(repo_root, @bundle_rel)
    layout_path = Path.join(repo_root, @layout_rel)

    with {:ok, css} <- File.read(bundle_path),
         {:ok, layout} <- File.read(layout_path) do
      current = %{
        bundle_sha256: sha256(css),
        bundle_blob: git_blob_sha(css),
        layout_blob: git_blob_sha(layout)
      }

      recorded_bundle = get_in(manifest, ["source", "bundle", "sha256"])
      recorded_layout = get_in(manifest, ["source", "root_layout", "git_blob_sha"])

      state =
        if current.bundle_sha256 == recorded_bundle and current.layout_blob == recorded_layout,
          do: :live,
          else: :superseded

      {:ok, {state, current}}
    else
      {:error, reason} ->
        {:error,
         "the checkout's bundle or root layout is unreadable under #{repo_root}: #{inspect(reason)}"}
    end
  end

  defp state_label(:live), do: "LIVE"
  defp state_label(:superseded), do: "SUPERSEDED (current superseded.json)"

  defp binding_failures(manifest, dir, repo_root) do
    id = Path.basename(dir)

    case binding_state(manifest, repo_root) do
      {:error, message} ->
        ["#{id}: #{message}"]

      {:ok, {:live, current}} ->
        consistency =
          check(
            get_in(manifest, ["source", "bundle", "git_blob_sha"]) == current.bundle_blob,
            "#{id}: source.bundle.git_blob_sha disagrees with the checkout bytes whose sha256 it records"
          )

        marker =
          if File.exists?(Path.join(dir, "superseded.json")) do
            [
              "#{id}: superseded.json is present but the catalog is marked superseded but still matches the checkout (bundle and root layout equal the recorded values). Remove superseded.json: a marker on a live catalog is a false claim."
            ]
          else
            []
          end

        consistency ++ marker

      {:ok, {:superseded, current}} ->
        marker_failures(dir, id, current)
    end
  end

  defp fix_hint(id, current) do
    "Fix, either: (1) recapture under a new catalog_id with " <>
      "reference/demo_app/assets/catalog/capture-before-catalog.cjs, or (2) add or update " <>
      "#{id}/superseded.json with superseded_by " <>
      ~s|{"bundle_sha256": "#{current.bundle_sha256}", "root_layout_git_blob_sha": "#{current.layout_blob}"}| <>
      " in the same change (the catalog PNGs, cases.json and manifest.json stay unchanged)."
  end

  defp marker_failures(dir, id, current) do
    hint = fix_hint(id, current)
    label = "#{id}/superseded.json"

    case read_json(Path.join(dir, "superseded.json")) do
      {:error, :enoent} ->
        [
          "#{id}: the admin bundle or the root layout changed since this catalog was captured " <>
            "(checkout app.css sha256 #{current.bundle_sha256}, root layout blob #{current.layout_blob}) " <>
            "and there is no superseded.json. #{hint}"
        ]

      {:error, reason} ->
        ["#{label} is unreadable (#{inspect(reason)}). #{hint}"]

      {:ok, marker} when is_map(marker) ->
        by = marker["superseded_by"]

        exact_keys(marker, @superseded_keys, label) ++
          check(
            marker["schema"] == @superseded_schema,
            "#{label}: schema must be #{@superseded_schema}"
          ) ++
          check(
            marker["catalog_id"] == id,
            "#{label}: catalog_id must equal the directory name #{id}"
          ) ++
          check(
            non_empty?(marker["superseded_in"]),
            "#{label}: superseded_in must name the change that moved the bytes"
          ) ++
          check(non_empty?(marker["reason"]), "#{label}: reason must be a non-empty string") ++
          exact_keys(by, @superseded_by_keys, "#{label} superseded_by") ++
          check(
            is_map(by) and by["bundle_sha256"] == current.bundle_sha256,
            "#{label}: superseded_by.bundle_sha256 is #{inspect(is_map(by) && by["bundle_sha256"])} but the checkout's current app.css sha256 is #{current.bundle_sha256}. #{hint}"
          ) ++
          check(
            is_map(by) and by["root_layout_git_blob_sha"] == current.layout_blob,
            "#{label}: superseded_by.root_layout_git_blob_sha is #{inspect(is_map(by) && by["root_layout_git_blob_sha"])} but the checkout's current root layout blob is #{current.layout_blob}. #{hint}"
          )

      {:ok, _other} ->
        ["#{label} must be a JSON object. #{hint}"]
    end
  end

  # -- seeded cases (D-22) ----------------------------------------------------------------

  defp cases_failures(manifest, dir, seed_source) do
    seed_text_failures(seed_source) ++
      case read_json(Path.join(dir, "cases.json")) do
        {:ok, data} when is_map(data) ->
          if get_in(manifest, ["cases", "sha256"]) ==
               sha256(File.read!(Path.join(dir, "cases.json"))) do
            cases_semantic_failures(data)
          else
            # The sha mismatch is already reported by file_failures/2; do not trust the content.
            []
          end

        {:ok, _} ->
          ["cases.json must be a JSON object"]

        {:error, reason} ->
          ["cases.json is unreadable: #{inspect(reason)}"]
      end
  end

  # Static check over the catalog seed module text: pure function of a string.
  defp seed_text_failures(text) do
    check(
      not Regex.match?(~r/next try|will retry|retry at|retrying/i, text),
      "catalog_seed.ex contains a retry-timing phrase (next try, will retry, retry at, retrying): the stop line forbids seeded retry copy"
    ) ++
      check(
        not Regex.match?(~r/"(reason|cause|retry_at|next_retry_at)"/, text),
        ~s|catalog_seed.ex contains a "reason", "cause", "retry_at" or "next_retry_at" metadata key literal: the stop line forbids seeded cause or retry copy|
      )
  end

  # Semantic check over the committed cases.json.
  defp cases_semantic_failures(data) do
    cases = data["cases"]

    if is_map(cases) do
      slugs = cases |> Map.keys() |> Enum.sort()

      shape =
        check(
          map_size(cases) == 10 and slugs == Enum.sort(@case_slugs),
          "cases.json must list exactly the ten cases #{inspect(Enum.sort(@case_slugs))}, found #{inspect(slugs)}"
        ) ++
          check(
            match?({:ok, _, _}, parse_time(data["seed_anchor_utc"])),
            "cases.json seed_anchor_utc must be ISO-8601"
          ) ++
          Enum.flat_map(cases, fn {slug, entry} ->
            exact_keys(entry, @case_keys, "cases.json #{slug}")
          end)

      if slugs != Enum.sort(@case_slugs) or not Enum.all?(Map.values(cases), &is_map/1) do
        shape
      else
        shape ++ seeded_case_failures(cases)
      end
    else
      ["cases.json must hold a cases object"]
    end
  end

  defp seeded_case_failures(cases) do
    seeded = for {slug, %{"source" => "catalog_seed"}} <- cases, do: slug
    keys = ["scenario", "subject"]

    nil_reason =
      for {slug, entry} <- cases,
          entry["source"] == "catalog_seed",
          entry["reject_reason"] == nil and entry["last_error_present"] == false,
          do: slug

    check(
      Enum.sort(seeded) == Enum.sort(@seeded_slugs),
      "exactly four cases must come from catalog_seed (#{inspect(@seeded_slugs)}), found #{inspect(Enum.sort(seeded))}"
    ) ++
      check(
        Enum.sort(nil_reason) == ["sent-no-report", "unicode-recipient"],
        "the nil-reason seeded cases must be exactly sent-no-report and unicode-recipient (no reject_reason, no last_error), found #{inspect(Enum.sort(nil_reason))}"
      ) ++
      Enum.flat_map(["sent-no-report", "unicode-recipient"], fn slug ->
        entry = cases[slug] || %{}

        check(
          entry["reject_reason"] == nil and entry["last_error_present"] == false and
            entry["metadata_keys"] == keys,
          "#{slug} is a nil-reason case: reject_reason must be null, last_error_present false and metadata_keys exactly #{inspect(keys)} (no reason or cause key)"
        )
      end) ++
      check(
        (cases["typo-bounce"] || %{})["reject_reason"] == "invalid" and
          (cases["typo-bounce"] || %{})["metadata_keys"] == keys,
        "typo-bounce must carry reject_reason \"invalid\" and metadata_keys #{inspect(keys)}"
      ) ++
      check(
        (cases["send-failed"] || %{})["status"] == "failed" and
          (cases["send-failed"] || %{})["reject_reason"] == nil and
          (cases["send-failed"] || %{})["last_error_present"] == true and
          (cases["send-failed"] || %{})["metadata_keys"] == keys,
        "send-failed must be status \"failed\" with reject_reason null, last_error_present true (the adapter's own recorded error) and metadata_keys #{inspect(keys)}"
      ) ++
      check(
        (cases["manual-suppressed"] || %{})["scenario"] == "incident_update",
        "manual-suppressed must be the DemoData row whose scenario is incident_update"
      )
  end

  # -- privacy ----------------------------------------------------------------------------

  defp privacy_failures(dir) do
    texts =
      for file <- files_under(dir),
          file in ["manifest.json", "cases.json", "superseded.json"] or
            String.starts_with?(file, "aria/"),
          match?({:ok, %File.Stat{type: :regular}}, File.lstat(Path.join(dir, file))),
          {:ok, text} <- [File.read(Path.join(dir, file))],
          String.valid?(text),
          do: {file, text}

    Enum.flat_map(texts, fn {file, text} ->
      token =
        check(not String.contains?(text, @reset_token), "#{file} contains the demo reset token")

      emails =
        for email <- unreserved_emails(text),
            do: "#{file} names an email address outside the reserved example domains: #{email}"

      token ++ emails
    end)
  end

  defp unreserved_emails(text) do
    ~r/[\p{L}\p{N}._%+\-]+@([\p{L}\p{N}\-]+(?:\.[\p{L}\p{N}\-]+)+)/u
    |> Regex.scan(text)
    |> Enum.reject(fn [_email, domain] ->
      domain = String.downcase(domain)
      domain in @reserved_domains or Enum.any?(@reserved_suffixes, &String.ends_with?(domain, &1))
    end)
    |> Enum.map(&hd/1)
    |> Enum.uniq()
  end

  # ---------------------------------------------------------------------------------------
  # Small helpers
  # ---------------------------------------------------------------------------------------

  defp check(true, _message), do: []
  defp check(false, message), do: [message]
  defp check(nil, message), do: [message]

  defp exact_keys(map, keys, label) when is_map(map) do
    actual = Map.keys(map)
    unknown = actual -- keys
    missing = keys -- actual

    check(
      unknown == [],
      "#{label}: unknown key(s) #{inspect(Enum.sort(unknown))} (the schema is closed)"
    ) ++
      check(missing == [], "#{label}: missing key(s) #{inspect(Enum.sort(missing))}")
  end

  defp exact_keys(_other, _keys, label), do: ["#{label} must be an object"]

  defp hex?(value, length),
    do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{#{length}}\z/, value)

  defp pos_int?(value), do: is_integer(value) and value > 0
  defp non_empty?(value), do: is_binary(value) and String.trim(value) != ""
  defp list(value) when is_list(value), do: value
  defp list(_), do: []

  defp parse_time(value) when is_binary(value), do: DateTime.from_iso8601(value)
  defp parse_time(_), do: :error

  defp sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

  # The same blob hash `git hash-object` computes: sha1("blob <size>\0" <> bytes).
  defp git_blob_sha(bytes) do
    Base.encode16(:crypto.hash(:sha, ["blob ", Integer.to_string(byte_size(bytes)), 0, bytes]),
      case: :lower
    )
  end

  defp read_json(path) do
    case File.read(path) do
      {:ok, bytes} ->
        case Jason.decode(bytes) do
          {:ok, value} -> {:ok, value}
          {:error, error} -> {:error, {:invalid_json, Exception.message(error)}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp catalog_dirs do
    case File.ls(@catalog_root) do
      {:ok, names} ->
        names
        |> Enum.reject(&String.starts_with?(&1, "."))
        |> Enum.map(&Path.join(@catalog_root, &1))
        |> Enum.filter(&File.dir?/1)
        |> Enum.sort()

      {:error, _} ->
        []
    end
  end

  defp rel(path), do: Path.relative_to(path, @repo_root)

  defp assert_red(failures, fragment) do
    assert Enum.any?(failures, &String.contains?(&1, fragment)),
           "expected a failure containing #{inspect(fragment)}, got:\n" <>
             Enum.map_join(failures, "\n", &"  - #{&1}")
  end

  # ---------------------------------------------------------------------------------------
  # Synthetic catalog fixture for the teeth
  # ---------------------------------------------------------------------------------------

  defp validate(fx, opts \\ []) do
    validate_catalog(
      fx.dir,
      Keyword.merge(
        [repo_root: fx.repo_root, seed_source: "defmodule CatalogSeed do\nend\n"],
        opts
      )
    )
  end

  def fixture(_context) do
    tmp =
      Path.join(
        System.tmp_dir!(),
        "mailglass-admin-before-catalog-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp)
    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(tmp) end)

    # A tmp repository root holding copies of the two bound inputs.
    repo_root = Path.join(tmp, "repo")

    for relative <- [@bundle_rel, @layout_rel] do
      File.mkdir_p!(Path.dirname(Path.join(repo_root, relative)))
      File.cp!(Path.join(@repo_root, relative), Path.join(repo_root, relative))
    end

    id = "before-1234567-20261115T000000Z"
    dir = Path.join(tmp, "catalog/#{id}")
    File.mkdir_p!(Path.join(dir, "aria"))

    css = File.read!(Path.join(repo_root, @bundle_rel))
    layout = File.read!(Path.join(repo_root, @layout_rel))

    captures =
      for {slug, index} <-
            Enum.with_index([
              "overview__fjordline-aps__default__375__light",
              "gallery__any__default__1440__dark"
            ]) do
        {w, h} = {8 + index, 6}
        png = tiny_png(w, h, index)
        aria = "- heading \"Deliveries\" [level=1]\n- text: mira.chen@northstar.example\n"
        File.write!(Path.join(dir, "#{slug}.png"), png)
        File.write!(Path.join(dir, "aria/#{slug}.yml"), aria)

        %{
          "id" => slug,
          "file" => "#{slug}.png",
          "sha256" => sha256(png),
          "bytes" => byte_size(png),
          "w" => w,
          "h" => h,
          "screen" => hd(String.split(slug, "__")),
          "route" => "/ops/mail?tenant_id=fjordline-aps",
          "fixture" => "fjordline-aps",
          "state" => "default",
          "case" => nil,
          "viewport" => if(index == 0, do: 375, else: 1440),
          "theme" => if(index == 0, do: "light", else: "dark"),
          "root_theme_attr" => if(index == 0, do: "mailglass-light", else: "mailglass-dark"),
          "tier" => if(index == 0, do: "A", else: "D"),
          "aria_file" => "aria/#{slug}.yml",
          "aria_sha256" => sha256(aria),
          "stop_line_hits" => []
        }
      end

    cases = good_cases()
    cases_text = Jason.encode!(cases, pretty: true) <> "\n"
    File.write!(Path.join(dir, "cases.json"), cases_text)

    css_sha = sha256(css)
    css_blob = git_blob_sha(css)

    manifest = %{
      "schema" => @schema,
      "catalog_id" => id,
      "run_id" => "mailglass-evidence-20261115000000-1-1",
      "source_revision" => "1234567" <> String.duplicate("a", 33),
      "source_digest" => String.duplicate("e", 64),
      "source" => %{
        "git_sha" => "1234567" <> String.duplicate("a", 33),
        "dirty" => false,
        "branch" => "main",
        "tree_sha" => String.duplicate("b", 40),
        "committed_at" => "2026-11-15T00:00:00.000Z",
        "bundle" => %{"path" => @bundle_rel, "sha256" => css_sha, "git_blob_sha" => css_blob},
        "root_layout" => %{"path" => @layout_rel, "git_blob_sha" => git_blob_sha(layout)},
        "recheck" => %{"clean" => true, "head_unchanged" => true}
      },
      "served" => %{
        "assets" => [
          %{
            "url_path" => "/dev/mail/css-" <> String.duplicate("0", 32),
            "sha256" => css_sha,
            "matches_disk" => true,
            "matches_git_blob" => true,
            "git_blob_sha" => css_blob
          },
          %{
            "url_path" => "/dev/mail/js-" <> String.duplicate("1", 32),
            "sha256" => String.duplicate("2", 64),
            "matches_disk" => true,
            "matches_git_blob" => true,
            "git_blob_sha" => String.duplicate("3", 40)
          }
        ],
        "server_started_at" => "2026-11-15T00:05:00.000Z"
      },
      "cases" => %{"file" => "cases.json", "sha256" => sha256(cases_text)},
      "tools" => %{
        "playwright" => "1.60.0",
        "chromium" => "148.0.0.0",
        "node" => "v26.0.0",
        "os" => "linux 6 x64",
        "script_sha256" => String.duplicate("4", 64)
      },
      "determinism" => %{
        "tz" => "UTC",
        "locale" => "en-US",
        "fixed_time" => nil,
        "seed_anchor_utc" => "2026-11-15T00:04:00Z",
        "reduced_motion" => "reduce",
        "animations" => "disabled",
        "dsf" => 1,
        "fonts_loaded" => ["Inter 400 normal"],
        "double_capture_identical" => true
      },
      "budget" => %{
        "image_count" => 2,
        "total_bytes" => captures |> Enum.map(& &1["bytes"]) |> Enum.sum(),
        "cap_images" => @cap_images,
        "cap_bytes" => @cap_bytes
      },
      "nested_theme_attr_count" => 0,
      "captures" => captures
    }

    File.write!(Path.join(dir, "manifest.json"), Jason.encode!(manifest, pretty: true) <> "\n")

    {:ok,
     %{
       tmp: tmp,
       dir: dir,
       id: id,
       repo_root: repo_root,
       png_names: Enum.map(captures, & &1["file"]),
       aria_names: Enum.map(captures, & &1["aria_file"])
     }}
  end

  defp good_cases do
    seeded = fn slug, extra ->
      Map.merge(
        %{
          "source" => "catalog_seed",
          "delivery_id" =>
            "01a1dcf8-0000-7000-8000-" <> String.pad_leading("#{:erlang.phash2(slug)}", 12, "0"),
          "provider_message_id" => "pm-cat-#{slug}-001",
          "recipient" => "someone@northstar.example",
          "scenario" => "catalog_#{String.replace(slug, "-", "_")}",
          "status" => "sent",
          "reject_reason" => nil,
          "last_error_present" => false,
          "metadata_keys" => ["scenario", "subject"]
        },
        extra
      )
    end

    demo = fn slug, extra ->
      Map.merge(
        %{
          "source" => "demo_data",
          "delivery_id" =>
            "01a1dcf8-1111-7000-8000-" <> String.pad_leading("#{:erlang.phash2(slug)}", 12, "0"),
          "provider_message_id" => "pm-demo-#{slug}",
          "recipient" => "ops@northstar.example",
          "scenario" => slug,
          "status" => "sent",
          "reject_reason" => nil,
          "last_error_present" => false,
          "metadata_keys" => ["scenario", "subject"]
        },
        extra
      )
    end

    %{
      "seed_anchor_utc" => "2026-11-15T00:04:00Z",
      "cases" => %{
        "typo-bounce" => seeded.("typo-bounce", %{"reject_reason" => "invalid"}),
        "send-failed" =>
          seeded.("send-failed", %{
            "status" => "failed",
            "last_error_present" => true,
            "provider_message_id" => nil
          }),
        "sent-no-report" => seeded.("sent-no-report", %{}),
        "unicode-recipient" => seeded.("unicode-recipient", %{}),
        "nil-reason-bounce" => demo.("nil-reason-bounce", %{}),
        "deferred-no-retry" => demo.("deferred-no-retry", %{}),
        "delivered-no-open" => demo.("delivered-no-open", %{}),
        "long-recipient" => demo.("long-recipient", %{}),
        "complained" => demo.("complained", %{}),
        "manual-suppressed" =>
          demo.("manual-suppressed", %{"scenario" => "incident_update", "status" => "suppressed"})
      }
    }
  end

  # A small, valid RGB PNG (signature, IHDR, one IDAT, IEND, each chunk with its CRC).
  defp tiny_png(w, h, seed) do
    row = <<0, :binary.copy(<<rem(40 + seed * 37, 256), 120, 200>>, w)::binary>>
    raw = :binary.copy(row, h)

    @png_signature <>
      chunk("IHDR", <<w::unsigned-big-32, h::unsigned-big-32, 8, 2, 0, 0, 0>>) <>
      chunk("IDAT", :zlib.compress(raw)) <>
      chunk("IEND", <<>>)
  end

  defp chunk(type, data) do
    <<byte_size(data)::unsigned-big-32, type::binary, data::binary,
      :erlang.crc32([type, data])::unsigned-big-32>>
  end

  defp update_manifest(fx, fun) do
    path = Path.join(fx.dir, "manifest.json")
    manifest = path |> File.read!() |> Jason.decode!() |> fun.()
    File.write!(path, Jason.encode!(manifest, pretty: true) <> "\n")
  end

  # Rewrites cases.json and keeps manifest.cases.sha256 in step, so only the content rule is tested.
  defp update_cases(fx, fun) do
    path = Path.join(fx.dir, "cases.json")
    cases = path |> File.read!() |> Jason.decode!() |> fun.()
    text = Jason.encode!(cases, pretty: true) <> "\n"
    File.write!(path, text)
    update_manifest(fx, &put_in(&1, ["cases", "sha256"], sha256(text)))
  end

  # After a PNG or aria file is rewritten on purpose, record the new hashes so only the
  # content rule under test can fail.
  defp refresh_capture_hashes(fx) do
    update_manifest(fx, fn manifest ->
      update_in(manifest, ["captures"], fn captures ->
        Enum.map(captures, fn capture ->
          png = File.read!(Path.join(fx.dir, capture["file"]))
          aria = File.read!(Path.join(fx.dir, capture["aria_file"]))

          capture
          |> Map.put("sha256", sha256(png))
          |> Map.put("bytes", byte_size(png))
          |> Map.put("aria_sha256", sha256(aria))
        end)
      end)
      |> then(fn m ->
        put_in(
          m,
          ["budget", "total_bytes"],
          m["captures"] |> Enum.map(& &1["bytes"]) |> Enum.sum()
        )
      end)
    end)
  end

  defp bundle_path(fx), do: Path.join(fx.repo_root, @bundle_rel)
  defp layout_path(fx), do: Path.join(fx.repo_root, @layout_rel)

  defp change_bundle(fx),
    do: File.write!(bundle_path(fx), File.read!(bundle_path(fx)) <> "/* moved */\n")

  defp change_layout(fx),
    do: File.write!(layout_path(fx), File.read!(layout_path(fx)) <> "<!-- moved -->\n")

  # The values a correct marker must carry, computed from the (possibly mutated) tmp checkout.
  defp current_values(fx) do
    %{
      "bundle_sha256" => fx |> bundle_path() |> File.read!() |> sha256(),
      "root_layout_git_blob_sha" => fx |> layout_path() |> File.read!() |> git_blob_sha()
    }
  end

  defp recorded_values(fx) do
    {:ok, manifest} = read_json(Path.join(fx.dir, "manifest.json"))

    %{
      "bundle_sha256" => get_in(manifest, ["source", "bundle", "sha256"]),
      "root_layout_git_blob_sha" => get_in(manifest, ["source", "root_layout", "git_blob_sha"])
    }
  end

  defp write_marker(fx, superseded_by, overrides \\ %{}) do
    marker =
      Map.merge(
        %{
          "schema" => @superseded_schema,
          "catalog_id" => fx.id,
          "superseded_by" => superseded_by,
          "superseded_in" => "feat(admin): brand v2 token swap",
          "reason" => "the admin bundle was regenerated from the v2 tokens"
        },
        overrides
      )

    File.write!(Path.join(fx.dir, "superseded.json"), Jason.encode!(marker, pretty: true) <> "\n")
  end
end
