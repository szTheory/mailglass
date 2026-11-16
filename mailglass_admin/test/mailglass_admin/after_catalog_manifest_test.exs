defmodule MailglassAdmin.AfterCatalogManifestTest do
  @moduledoc """
  Proves the Phase 182 "after" catalog and its independent review (BRADM-07, D-21), and proves
  that the proof can fail.

  Lane: this file runs in the required `support_contract_admin` lane
  (`mix verify.support_contract.admin`, the whole test directory). The capture run and the review
  are not CI; this test is what makes them more than an unverified claim. It must land in the same
  PR as the catalog, because a `.planning`-only change skips the admin lane.

  ## What is proven, for every catalog directory under `after-catalog/`

    * `manifest.json` has the closed `mailglass.after_catalog.v1` schema, was captured on a clean
      tree, and lists exactly the fourteen scenario ids and two injected-defect calibration ids;
      every PNG and aria sidecar matches its recorded sha256 and header, and nothing else is in the
      directory (the review files are bound by name and sha256 in `review/review-manifest.json`);
    * the served bundle bytes equal the committed bundle, the demo container PID and start time are
      recorded, and the server started later than the script (a stale container is red);
    * the catalog is bound to the checkout's current `app.css` sha256 and root layout blob (LIVE),
      or carries a current `superseded.json` (the same rule as the before catalog);
    * the password-reset seed holds no retry-timing phrase and no `"reason"`/`"cause"` metadata key,
      and the seeded cases keep the nil-reason bounce free of any reason;
    * no committed text names the demo reset token or an email address outside the reserved
      example domains;
    * the review is independent and honest: every verdict passes `ReviewGate.validate_verdict/2`
      (closed schema, every `evidence_quote` a literal substring of the aria sidecar, a pass cites a
      rule), every verdict names inputs only from {after PNG, before PNG, aria sidecar, `rubric.md`,
      the scenario goal}, the A/B orders of the first two judges of a paired scenario come from the
      recorded seed, and `ReviewGate.gate/1` returns `{:pass, []}` for the whole catalog;
    * the reviewer's power to reject is calibrated: at least five Phase 180 before screenshots
      presented as the candidate, two injected defects and one known-good capture, each judged like
      a scenario, and the gate is red if any known-bad passed or the known-good was rejected.

  ## Teeth

  Every rule has a mutation case on a synthetic catalog built in a temp directory: a flipped
  verdict, an unlisted file, a hallucinated quote, a dropped calibration list, a passing known-bad,
  a verdict input outside the allowed set (a PLAN.md), a mismatched screenshot sha256, and a server
  start that is not later than the script start. The validators are pure functions of a catalog
  directory and options (`repo_root:`), so a planted bad input goes through the same code path as
  the committed catalog and the pass is not vacuous. The gate itself has one case per branch of its
  rule, and its outcome is shown to be independent of verdict order.

  ## Disclosed limits (nothing in this test catches these)

    * Whether the reviewer was truly a fresh, isolated agent is a property of how the verdicts were
      produced, not of the files. The test proves what the files can show: the recorded inputs, the
      substring check, the calibration outcome and the seeded orders.
    * A PR that rewrites `manifest.json` together with its recorded bundle bytes passes the LIVE
      branch; that class is review-only, as it is for the before catalog.
  """

  use ExUnit.Case, async: false

  import MailglassAdmin.TestSupport.CatalogValidators

  alias MailglassAdmin.TestSupport.ReviewGate

  @repo_root Path.expand("../../..", __DIR__)
  @before_root_rel ".planning/research/brand-v2-adoption/before-catalog"
  @seed_source_path Path.join(@repo_root, "reference/demo_app/lib/mailglass_demo/journey_seed.ex")

  @schema "mailglass.after_catalog.v1"
  @review_schema "mailglass.after_catalog.review.v1"
  @cap_images 80
  @cap_bytes 15_000_000
  @reset_token "mailglass-dev-demo"

  @top_keys ~w(schema catalog_id run_id source_revision source_digest source served cases tools
               determinism budget nested_theme_attr_count captures script_started_at server)
  @source_keys ~w(git_sha dirty branch tree_sha committed_at bundle root_layout recheck)
  @bundle_keys ~w(path sha256 git_blob_sha)
  @layout_keys ~w(path git_blob_sha)
  @recheck_keys ~w(clean head_unchanged)
  @served_keys ~w(assets server_started_at)
  @asset_keys ~w(url_path sha256 matches_disk matches_git_blob git_blob_sha)
  @server_keys ~w(container_pid started_at)
  @cases_ref_keys ~w(file sha256)
  @tools_keys ~w(playwright chromium node os script_sha256)
  @determinism_keys ~w(tz locale fixed_time seed_anchor_utc reduced_motion animations dsf
                       fonts_loaded double_capture_identical)
  @budget_keys ~w(image_count total_bytes cap_images cap_bytes)
  @capture_keys ~w(id file sha256 bytes w h screen route fixture state case viewport theme
                   root_theme_attr tier aria_file aria_sha256 stop_line_hits)

  @review_keys ~w(schema catalog_id manifest_sha256 rng_seed rubric_sha256 scenarios calibration
                  prior_iterations)
  @scenario_keys ~w(scenario_id after_png after_png_sha256 aria aria_sha256 before_png
                    before_png_sha256 goal verdicts)
  @calibration_keys ~w(id kind expect png png_sha256 aria aria_sha256 verdicts)
  @verdict_entry_keys ~w(judge file sha256 order inputs)
  @prior_keys ~w(catalog_id rejected)
  @rubric_rel "review/rubric.md"
  @review_manifest_rel "review/review-manifest.json"

  # The fixed scenario ids (D-21, checker W2). The driver holds the same list; a test below
  # checks every id literally appears in the driver and the spec.
  @scenario_ids [
    "deliveries__northstar__reset-search__375__light",
    "deliveries__northstar__reset-search__375__dark",
    "deliveries__northstar__reset-search__1440__light",
    "delivery-detail__reset-typo-bounce__default__375__light",
    "delivery-detail__reset-typo-bounce__default__375__dark",
    "delivery-detail__reset-typo-bounce__default__1440__light",
    "delivery-detail__reset-nil-reason-bounce__default__375__light",
    "delivery-detail__reset-deferred__default__375__light",
    "delivery-detail__reset-suppressed__default__375__light",
    "delivery-detail__reset-sent-no-report__default__375__light",
    "delivery-detail__reset-bounce-then-open__default__375__light",
    "deliveries__northstar__empty-search__375__light",
    "deliveries__northstar__default__1440__light",
    "delivery-detail__typo-bounce__default__375__light"
  ]
  # The two scenarios that pair with an identically named Phase 180 capture. Every other scenario
  # has `before: null` and is judged `after_only`.
  @paired_ids [
    "deliveries__northstar__default__1440__light",
    "delivery-detail__typo-bounce__default__375__light"
  ]
  @defect_ids [
    "calib-defect-no-zone__reset-typo-bounce__default__375__light",
    "calib-defect-no-status-word__reset-typo-bounce__default__375__light"
  ]
  @known_good_scenario "delivery-detail__reset-typo-bounce__default__375__light"
  @known_good_id "calib-known-good__reset-typo-bounce__default__375__light"
  @before_as_after_sources [
    "delivery-detail__typo-bounce__default__375__light",
    "delivery-detail__typo-bounce__default__375__dark",
    "deliveries__northstar__default__1440__light",
    "deliveries__northstar__default__375__dark",
    "delivery-detail__typo-bounce__default__1440__light"
  ]
  @journey_slugs ~w(pw-sent-no-report pw-typo-bounce pw-bounce-then-open pw-nil-reason-bounce
                    pw-deferred pw-suppressed)
  @allowed_input_extras [@rubric_rel, "goal"]

  # ---------------------------------------------------------------------------------------
  # The committed catalog
  # ---------------------------------------------------------------------------------------

  describe "capture tooling" do
    test "the capture driver lists every scenario and calibration id" do
      driver =
        File.read!(
          Path.join(@repo_root, "reference/demo_app/assets/catalog/capture-before-catalog.cjs")
        )

      for id <- @scenario_ids ++ @defect_ids do
        assert driver =~ ~s("#{id}"), "the capture driver does not list #{id}"
      end
    end

    test "the journey seed holds no retry-timing phrase and no reason or cause metadata key" do
      assert seed_text_failures(File.read!(@seed_source_path)) == []
    end
  end

  # ---------------------------------------------------------------------------------------
  # ReviewGate: one case per branch of the gate rule
  # ---------------------------------------------------------------------------------------

  describe "ReviewGate.gate/1" do
    test "(a) two valid passes in different orders pass" do
      assert gate_for([
               scenario("s1", [pass("s1", "a", "after_first"), pass("s1", "b", "before_first")],
                 paired: true
               )
             ]) ==
               {:pass, []}
    end

    test "(a2) two valid passes on an unpaired scenario (after_only) pass" do
      assert gate_for([
               scenario("s1", [pass("s1", "a", "after_only"), pass("s1", "b", "after_only")])
             ]) ==
               {:pass, []}
    end

    test "(b) one pass and one valid reject: the reject stands" do
      assert {:reject, messages} =
               gate_for([
                 scenario("s1", [pass("s1", "a", "after_only"), reject("s1", "b", "after_only")])
               ])

      assert Enum.any?(
               messages,
               &(&1 =~ "[reject] s1" and &1 =~ "R-TIME-1" and &1 =~ "no third independent judge")
             )
    end

    test "(c) one pass, one valid reject and a third judge's pass: passes" do
      verdicts = [
        pass("s1", "a", "after_only"),
        reject("s1", "b", "after_only"),
        pass("s1", "c", "after_only")
      ]

      assert gate_for([scenario("s1", verdicts)]) == {:pass, []}
    end

    test "(d) two valid rejects block even with a third pass" do
      verdicts = [
        reject("s1", "a", "after_only"),
        reject("s1", "b", "after_only"),
        pass("s1", "c", "after_only")
      ]

      assert {:reject, messages} = gate_for([scenario("s1", verdicts)])
      assert Enum.count(messages, &(&1 =~ "two or more valid rejects")) == 2
    end

    test "(d2) a third judge's reject after two passes still blocks (any reject blocks)" do
      verdicts = [
        pass("s1", "a", "after_only"),
        pass("s1", "b", "after_only"),
        reject("s1", "c", "after_only")
      ]

      assert {:reject, [message]} = gate_for([scenario("s1", verdicts)])
      assert message =~ "[reject] s1" and message =~ "judge c"
    end

    test "(e) one pass and one unverifiable reject: the reject is dropped and one valid verdict is red" do
      unverifiable =
        reject("s1", "b", "after_only", quote_text: "text that is not in the aria sidecar")

      assert {:reject, messages} =
               gate_for([scenario("s1", [pass("s1", "a", "after_only"), unverifiable])])

      assert Enum.any?(
               messages,
               &(&1 =~ "[red] s1" and &1 =~ "at least two distinct judges" and &1 =~ "replacement")
             )
    end

    test "(f) one pass, one unverifiable reject and a replacement pass: passes" do
      unverifiable =
        reject("s1", "b", "after_only", quote_text: "text that is not in the aria sidecar")

      verdicts = [pass("s1", "a", "after_only"), unverifiable, pass("s1", "c", "after_only")]
      assert gate_for([scenario("s1", verdicts)]) == {:pass, []}
    end

    test "(g) a pass whose quote fails the substring check is red, not dropped" do
      hallucinated = pass("s1", "b", "after_only", quote_text: "an invented sentence")

      assert {:reject, messages} =
               gate_for([scenario("s1", [pass("s1", "a", "after_only"), hallucinated])])

      assert Enum.any?(messages, &(&1 =~ "[red] s1" and &1 =~ "hallucinated evidence"))
    end

    test "(h) a pass citing no rule is red" do
      empty = pass("s1", "b", "after_only") |> Map.put("rules", [])

      assert {:reject, messages} =
               gate_for([scenario("s1", [pass("s1", "a", "after_only"), empty])])

      assert Enum.any?(messages, &(&1 =~ "[red] s1" and &1 =~ "must cite at least one rule"))
    end

    test "(i) the first two judges of a paired scenario in the same order are red" do
      verdicts = [pass("s1", "a", "after_first"), pass("s1", "b", "after_first")]

      assert {:reject, messages} = gate_for([scenario("s1", verdicts, paired: true)])
      assert Enum.any?(messages, &(&1 =~ "different orders"))
    end

    test "(i2) a verdict order that contradicts whether a before screenshot was shown is red" do
      assert {:reject, unpaired} =
               gate_for([
                 scenario("s1", [pass("s1", "a", "after_first"), pass("s1", "b", "after_only")])
               ])

      assert Enum.any?(unpaired, &(&1 =~ "no before screenshot (expected after_only)"))

      assert {:reject, paired} =
               gate_for([
                 scenario("s1", [pass("s1", "a", "after_only"), pass("s1", "b", "before_first")],
                   paired: true
                 )
               ])

      assert Enum.any?(paired, &(&1 =~ "shown with a before screenshot"))
    end

    test "(i3) a verdict filed under another scenario is red" do
      assert {:reject, messages} =
               gate_for([
                 scenario("s1", [pass("s1", "a", "after_only"), pass("s2", "b", "after_only")])
               ])

      assert Enum.any?(messages, &(&1 =~ "names scenario \"s2\" but is filed under \"s1\""))
    end

    test "(j) a known-bad calibration item passed by any judge is red" do
      for judges <- [
            [pass("c1", "a", "after_only"), pass("c1", "b", "after_only")],
            [pass("c1", "a", "after_only"), reject("c1", "b", "after_only")],
            [
              reject("c1", "a", "after_only"),
              reject("c1", "b", "after_only"),
              pass("c1", "c", "after_only")
            ]
          ] do
        calibration = [
          known_bad("c1", judges),
          known_bad("c2", rejected_pair("c2"), "injected_defect"),
          known_good("c3")
        ]

        assert {:reject, messages} =
                 ReviewGate.gate(%{scenarios: [good_scenario()], calibration: calibration})

        assert Enum.any?(messages, &(&1 =~ "[red] calibration \"c1\"" and &1 =~ "known-bad")),
               inspect(messages)
      end
    end

    test "(k) the known-good rejected is red" do
      calibration = [
        known_bad("c1", rejected_pair("c1")),
        known_bad("c2", rejected_pair("c2"), "injected_defect"),
        known_good("c3", [reject("c3", "a", "after_only"), reject("c3", "b", "after_only")])
      ]

      assert {:reject, messages} =
               ReviewGate.gate(%{scenarios: [good_scenario()], calibration: calibration})

      assert Enum.any?(messages, &(&1 =~ "known-good was rejected"))
    end

    test "(k2) a calibration set missing a kind is red" do
      calibration = [known_bad("c1", rejected_pair("c1")), known_good("c3")]

      assert {:reject, messages} =
               ReviewGate.gate(%{scenarios: [good_scenario()], calibration: calibration})

      assert Enum.any?(messages, &(&1 =~ "holds no injected_defect item"))

      assert {:reject, empty} = ReviewGate.gate(%{scenarios: [good_scenario()], calibration: []})
      assert length(Enum.filter(empty, &(&1 =~ "holds no"))) == 3
    end

    test "(l) zero scenarios is red" do
      assert {:reject, messages} =
               ReviewGate.gate(%{scenarios: [], calibration: good_calibration()})

      assert Enum.any?(messages, &(&1 =~ "zero scenarios"))
    end

    test "(l2) a scenario with fewer than two verdicts or none is red" do
      assert {:reject, one} = gate_for([scenario("s1", [pass("s1", "a", "after_only")])])
      assert Enum.any?(one, &(&1 =~ "has 1"))
      assert {:reject, none} = gate_for([scenario("s1", [])])
      assert Enum.any?(none, &(&1 =~ "has 0"))
    end

    test "(l3) the same judge twice counts once" do
      assert {:reject, messages} =
               gate_for([
                 scenario("s1", [pass("s1", "a", "after_only"), pass("s1", "a", "after_only")])
               ])

      assert Enum.any?(messages, &(&1 =~ "appears twice"))
    end

    test "(m) the outcome is identical under any shuffle of every verdict list" do
      :rand.seed(:exsss, {182, 6, 21})

      catalogs = [
        [
          scenario("s1", [
            pass("s1", "a", "after_only"),
            reject("s1", "b", "after_only"),
            pass("s1", "c", "after_only")
          ])
        ],
        [
          scenario(
            "s1",
            [
              pass("s1", "a", "after_first"),
              pass("s1", "b", "before_first"),
              pass("s1", "c", "after_first")
            ],
            paired: true
          )
        ],
        [
          scenario("s1", [
            reject("s1", "a", "after_only"),
            reject("s1", "b", "after_only"),
            pass("s1", "c", "after_only")
          ])
        ],
        [
          scenario("s1", [
            pass("s1", "a", "after_only"),
            reject("s1", "b", "after_only", quote_text: "not in the aria"),
            pass("s1", "c", "after_only")
          ])
        ],
        [
          scenario("s1", [
            pass("s1", "a", "after_only"),
            pass("s1", "b", "after_only", quote_text: "not in the aria")
          ])
        ]
      ]

      for scenarios <- catalogs do
        expected = gate_for(scenarios)

        for _ <- 1..25 do
          shuffled = Enum.map(scenarios, &%{&1 | verdicts: Enum.shuffle(&1.verdicts)})

          shuffled_calibration =
            Enum.map(good_calibration(), &%{&1 | verdicts: Enum.shuffle(&1.verdicts)})

          assert ReviewGate.gate(%{
                   scenarios: Enum.shuffle(shuffled),
                   calibration: Enum.shuffle(shuffled_calibration)
                 }) ==
                   expected
        end
      end
    end

    test "assign_orders/2 is deterministic and the two judges always differ" do
      for seed <- [1, 182, 99_999], id <- @paired_ids do
        {first, second} = ReviewGate.assign_orders(seed, id)
        assert {first, second} == ReviewGate.assign_orders(seed, id)
        assert Enum.sort([first, second]) == ["after_first", "before_first"]
      end
    end
  end

  # ---------------------------------------------------------------------------------------
  # Verdict schema
  # ---------------------------------------------------------------------------------------

  describe "verdict schema (ReviewGate.validate_verdict/2)" do
    test "a good verdict is clean (positive control)" do
      assert ReviewGate.validate_verdict(pass("s1", "a", "after_only"), aria()) == []
      assert ReviewGate.validate_verdict(reject("s1", "a", "after_only"), aria()) == []
    end

    test "an unknown key is red (the schema is closed, there is no override field)" do
      failures =
        ReviewGate.validate_verdict(
          Map.put(pass("s1", "a", "after_only"), "override", true),
          aria()
        )

      assert_red(failures, "unknown key(s) [\"override\"]")
    end

    test "a verdict outside pass/reject and an order outside the three values are red" do
      assert_red(
        ReviewGate.validate_verdict(
          Map.put(pass("s1", "a", "after_only"), "verdict", "maybe"),
          aria()
        ),
        "must be \"pass\" or \"reject\""
      )

      assert_red(
        ReviewGate.validate_verdict(
          Map.put(pass("s1", "a", "after_only"), "order", "sideways"),
          aria()
        ),
        "order must be one of"
      )
    end

    test "a pass with no rules, a pass citing a failed rule and a reject citing none are red" do
      assert_red(
        ReviewGate.validate_verdict(Map.put(pass("s1", "a", "after_only"), "rules", []), aria()),
        "must cite at least one rule"
      )

      failed =
        Map.put(pass("s1", "a", "after_only"), "rules", [
          rule("R-TIME-1", false, "time: Nov 15, 2026, 2:05 PM UTC")
        ])

      assert_red(ReviewGate.validate_verdict(failed, aria()), "must not cite a failed rule")

      assert_red(
        ReviewGate.validate_verdict(
          Map.put(reject("s1", "a", "after_only"), "rules", [
            rule("R-TIME-1", true, "time: Nov 15, 2026, 2:05 PM UTC")
          ]),
          aria()
        ),
        "reject must cite at least one failed rule"
      )
    end

    test "an evidence quote that is not a substring of the aria text is a hallucinated quote" do
      verdict = pass("s1", "a", "after_only", quote_text: "Delivered at 9:99 PM UTC")

      assert_red(
        ReviewGate.validate_verdict(verdict, aria()),
        "not a literal substring of the aria sidecar"
      )

      assert %{schema: [], quotes: [_]} = ReviewGate.verdict_failures(verdict, aria())
    end

    test "an unknown rule id, a non-boolean ok and an empty quote or region are red" do
      bad = [
        %{"id" => "R-NOPE-9", "ok" => "yes", "evidence_quote" => "", "screenshot_region" => ""}
      ]

      failures =
        ReviewGate.validate_verdict(Map.put(pass("s1", "a", "after_only"), "rules", bad), aria())

      assert_red(failures, "id must be one of")
      assert_red(failures, "ok must be true or false")
      assert_red(failures, "evidence_quote must be a non-empty string")
      assert_red(failures, "screenshot_region must be a non-empty string")
    end

    test "a non-reserved email address in a quote or the reasons is red" do
      text = aria() <> "- text: someone@gmail.com\n"
      verdict = pass("s1", "a", "after_only", quote_text: "someone@gmail.com")

      assert_red(
        ReviewGate.validate_verdict(verdict, text),
        "outside the reserved example domains"
      )

      reasons =
        Map.put(pass("s1", "a", "after_only"), "reasons", "Mail went to someone@gmail.com.")

      assert_red(
        ReviewGate.validate_verdict(reasons, aria()),
        "outside the reserved example domains"
      )
    end

    test "a verdict that is not an object is red" do
      assert_red(ReviewGate.validate_verdict("pass", aria()), "must be a JSON object")
    end
  end

  # ---------------------------------------------------------------------------------------
  # Shared validators behave exactly as the private originals
  # ---------------------------------------------------------------------------------------

  describe "CatalogValidators" do
    test "sha256 and git_blob_sha match known vectors (git hash-object)" do
      assert sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
      assert git_blob_sha("") == "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"
      assert git_blob_sha("hello\n") == "ce013625030ba8dba906f756967f9e9ca394464a"
    end

    test "exact_keys names unknown and missing keys and rejects a non-map" do
      assert exact_keys(%{"a" => 1, "b" => 2}, ["a", "b"], "x") == []
      assert [unknown] = exact_keys(%{"a" => 1, "z" => 2, "b" => 3}, ["a", "b"], "x")
      assert unknown =~ "unknown key(s) [\"z\"]"
      assert [missing] = exact_keys(%{"a" => 1}, ["a", "b"], "x")
      assert missing =~ "missing key(s) [\"b\"]"
      assert exact_keys([], ["a"], "x") == ["x must be an object"]
    end

    test "read_json distinguishes a missing file from invalid JSON" do
      tmp = tmp_dir()
      File.write!(Path.join(tmp, "good.json"), ~s({"a": 1}))
      File.write!(Path.join(tmp, "bad.json"), "{nope")
      assert read_json(Path.join(tmp, "good.json")) == {:ok, %{"a" => 1}}
      assert {:error, {:invalid_json, _}} = read_json(Path.join(tmp, "bad.json"))
      assert read_json(Path.join(tmp, "missing.json")) == {:error, :enoent}
    end

    test "png_header_failures accepts a tiny PNG and names each broken header" do
      capture = %{"w" => 8, "h" => 6}
      png = tiny_png(8, 6, 1)
      assert png_header_failures("a.png", png, capture) == []

      assert [_] =
               png_header_failures("a.png", png, %{"w" => 9, "h" => 6})
               |> Enum.filter(&(&1 =~ "records 9x6"))

      assert ["a.png: not a PNG" <> _] =
               png_header_failures("a.png", "not a png at all, just bytes", capture)

      <<head::binary-size(29), crc_byte, rest::binary>> = png
      corrupt = <<head::binary, Bitwise.bxor(crc_byte, 0xFF), rest::binary>>

      assert Enum.any?(
               png_header_failures("a.png", corrupt, capture),
               &(&1 =~ "IHDR checksum mismatch")
             )
    end

    test "unreserved_emails flags only addresses outside the reserved domains" do
      text = "a@northstar.example b@example.com c@gmail.com d@corp.test e@x.org"
      assert unreserved_emails(text) == ["c@gmail.com", "e@x.org"]
    end

    test "binding_state is live, superseded with a current marker, or unbound" do
      tmp = tmp_dir()
      repo = copy_bound_inputs(tmp)
      dir = Path.join(tmp, "after-1234567-20261115T000000Z")
      File.mkdir_p!(dir)
      css = File.read!(Path.join(repo, bundle_rel()))
      layout = File.read!(Path.join(repo, layout_rel()))

      manifest = %{
        "source" => %{
          "bundle" => %{"sha256" => sha256(css), "git_blob_sha" => git_blob_sha(css)},
          "root_layout" => %{"git_blob_sha" => git_blob_sha(layout)}
        }
      }

      assert {:live, _} = binding_state(manifest, dir, repo)
      assert binding_failures(manifest, dir, repo) == []

      File.write!(Path.join(repo, bundle_rel()), css <> "/* moved */")
      assert {:unbound, message} = binding_state(manifest, dir, repo)
      assert message =~ "no superseded.json"

      moved = File.read!(Path.join(repo, bundle_rel()))

      marker = %{
        "schema" => "mailglass.after_catalog.superseded.v1",
        "catalog_id" => Path.basename(dir),
        "superseded_by" => %{
          "bundle_sha256" => sha256(moved),
          "root_layout_git_blob_sha" => git_blob_sha(layout)
        },
        "superseded_in" => "a test change",
        "reason" => "the bundle moved"
      }

      File.write!(Path.join(dir, "superseded.json"), Jason.encode!(marker))
      assert {:superseded, ^marker} = binding_state(manifest, dir, repo)
      assert binding_failures(manifest, dir, repo) == []

      # A marker made stale by a further change is not valid.
      File.write!(Path.join(repo, bundle_rel()), moved <> "/* moved again */")
      assert {:unbound, stale} = binding_state(manifest, dir, repo)
      assert stale =~ "superseded_by.bundle_sha256 is not the checkout's current"

      # A marker on a live catalog is a false claim.
      File.write!(Path.join(repo, bundle_rel()), css)
      assert [message] = binding_failures(manifest, dir, repo)
      assert message =~ "a marker on a live catalog is a false claim"
    end
  end

  # ---------------------------------------------------------------------------------------
  # Seed text (the stop line applies to the journey seed too)
  # ---------------------------------------------------------------------------------------

  describe "seed text" do
    test "a retry-timing phrase or a reason/cause/retry key literal is red; plain text is clean" do
      assert seed_text_failures("defmodule S do\n  @subject \"Reset your password\"\nend\n") == []

      assert_red(
        seed_text_failures("# the provider will retry in 5 minutes"),
        "retry-timing phrase"
      )

      assert_red(seed_text_failures("# Next try at 2:12 PM"), "retry-timing phrase")

      assert_red(
        seed_text_failures(~s(metadata: %{"reason" => "mailbox full"})),
        "metadata key literal"
      )

      assert_red(seed_text_failures(~s(%{"cause" => 1})), "metadata key literal")
      assert_red(seed_text_failures(~s(%{"next_retry_at" => 1})), "metadata key literal")
    end
  end

  # ---------------------------------------------------------------------------------------
  # Teeth: a synthetic catalog, every rule proven red
  # ---------------------------------------------------------------------------------------

  describe "detectors have teeth" do
    setup :fixture

    test "the unmutated synthetic catalog is clean (positive control)", fx do
      assert validate(fx) == []
    end

    test "a flipped verdict (a scenario pass flipped to reject with no failed rule) is red", fx do
      id = "deliveries__northstar__reset-search__375__light"
      rewrite_verdict(fx, id, "a", &Map.put(&1, "verdict", "reject"))
      assert_red(validate(fx), "a reject must cite at least one failed rule")
    end

    test "a scenario reject that stands blocks the gate", fx do
      id = "delivery-detail__reset-deferred__default__375__light"
      rewrite_verdict(fx, id, "a", fn _ -> reject(id, "a", "after_only") end)
      assert_red(validate(fx), "[reject] #{id}")
    end

    test "a hallucinated quote on a pass is red", fx do
      id = "delivery-detail__reset-suppressed__default__375__light"

      rewrite_verdict(fx, id, "b", fn _ ->
        pass(id, "b", "after_only", quote_text: "Delivered to the inbox.")
      end)

      assert_red(validate(fx), "not a literal substring of the aria sidecar")
    end

    test "an unlisted file is red", fx do
      File.write!(Path.join(fx.dir, "review/verdicts/extra.a.json"), "{}")
      assert_red(validate(fx), "unlisted file review/verdicts/extra.a.json")
      File.write!(Path.join(fx.dir, "notes.md"), "x")
      assert_red(validate(fx), "unlisted file notes.md")
    end

    test "a dropped calibration list is red", fx do
      update_review(fx, &Map.put(&1, "calibration", []))
      failures = validate(fx)
      assert_red(failures, "holds no before_as_after item")
      assert_red(failures, "at least five before_as_after")
    end

    test "a dropped injected-defect calibration item is red", fx do
      update_review(fx, fn review ->
        Map.update!(review, "calibration", fn items ->
          Enum.reject(items, &(&1["kind"] == "injected_defect"))
        end)
      end)

      failures = validate(fx)
      assert_red(failures, "holds no injected_defect item")
      assert_red(failures, "exactly two injected_defect")
    end

    test "a known-bad that a judge passed is red", fx do
      id = hd(fx.calibration_ids)

      for judge <- ["a", "b"] do
        rewrite_verdict(fx, id, judge, fn _ ->
          pass(id, judge, "after_only")
          |> Map.put("rules", [rule("R-WORDS-1", true, "heading \"Deliveries\" [level=1]")])
        end)
      end

      assert_red(validate(fx), "a known-bad passed")
    end

    test "a verdict input outside the allowed set (the plan) is red", fx do
      id = "deliveries__northstar__reset-search__375__light"

      update_review(fx, fn review ->
        update_in(
          review,
          [
            "scenarios",
            Access.filter(&(&1["scenario_id"] == id)),
            "verdicts",
            Access.at(0),
            "inputs"
          ],
          fn inputs ->
            inputs ++ [".planning/phases/182-admin-words-and-layout-one-job-first/182-06-PLAN.md"]
          end
        )
      end)

      assert_red(validate(fx), "182-06-PLAN.md\" is outside the allowed set")
    end

    test "a verdict that omits a required input is red", fx do
      id = "deliveries__northstar__reset-search__375__light"

      update_review(fx, fn review ->
        update_in(
          review,
          [
            "scenarios",
            Access.filter(&(&1["scenario_id"] == id)),
            "verdicts",
            Access.at(0),
            "inputs"
          ],
          fn inputs ->
            Enum.reject(inputs, &(&1 == @rubric_rel))
          end
        )
      end)

      assert_red(validate(fx), "must list exactly")
    end

    test "a mismatched screenshot sha256 in the review manifest is red", fx do
      id = "deliveries__northstar__reset-search__375__light"

      update_review(fx, fn review ->
        put_in(
          review,
          ["scenarios", Access.filter(&(&1["scenario_id"] == id)), "after_png_sha256"],
          String.duplicate("0", 64)
        )
      end)

      assert_red(validate(fx), "after_png_sha256 does not match the manifest capture")
    end

    test "a flipped PNG byte names the sha256 mismatch", fx do
      png = Path.join(fx.dir, "#{hd(@scenario_ids)}.png")
      <<first, rest::binary>> = File.read!(png)
      File.write!(png, <<Bitwise.bxor(first, 0xFF), rest::binary>>)
      assert_red(validate(fx), "sha256 mismatch")
    end

    test "a server start that is not later than the script start is red", fx do
      update_manifest(fx, fn manifest ->
        manifest
        |> put_in(["server", "started_at"], "2026-11-15T00:00:30.000Z")
        |> put_in(["served", "server_started_at"], "2026-11-15T00:00:30.000Z")
      end)

      assert_red(validate(fx), "must be later than script_started_at")
    end

    test "a verdict whose A/B order does not come from the recorded seed is red", fx do
      id = hd(@paired_ids)
      {first, _} = ReviewGate.assign_orders(fx.rng_seed, id)
      flipped = if first == "after_first", do: "before_first", else: "after_first"

      update_review(fx, fn review ->
        put_in(
          review,
          [
            "scenarios",
            Access.filter(&(&1["scenario_id"] == id)),
            "verdicts",
            Access.at(0),
            "order"
          ],
          flipped
        )
      end)

      assert_red(validate(fx), "must come from rng_seed")
    end

    test "a stale manifest_sha256 binding is red", fx do
      update_manifest(fx, &put_in(&1, ["determinism", "dsf"], 1))

      File.write!(
        Path.join(fx.dir, "manifest.json"),
        File.read!(Path.join(fx.dir, "manifest.json")) <> "\n"
      )

      assert_red(validate(fx), "manifest_sha256 does not match manifest.json")
    end

    test "a rubric that lost the stop-line override or a rule id is red", fx do
      File.write!(Path.join(fx.dir, @rubric_rel), "R-TIME-1 only\n")
      failures = validate(fx)
      assert_red(failures, "rubric_sha256")
      assert_red(failures, "Stop-line override")
    end

    test "an unreserved email or the reset token in a committed text is red", fx do
      File.write!(
        Path.join(fx.dir, "aria/#{hd(@scenario_ids)}.yml"),
        "- text: maya@gmail.com #{@reset_token}\n"
      )

      failures = validate(fx)
      assert_red(failures, "outside the reserved example domains: maya@gmail.com")
      assert_red(failures, "contains the demo reset token")
    end

    test "dirty true, an unclean recheck and a budget over the cap are red", fx do
      update_manifest(fx, fn manifest ->
        manifest
        |> put_in(["source", "dirty"], true)
        |> put_in(["source", "recheck", "clean"], false)
        |> put_in(["budget", "total_bytes"], @cap_bytes + 1)
      end)

      failures = validate(fx)
      assert_red(failures, "source.dirty must be false")
      assert_red(failures, "recheck")
      assert_red(failures, "total_bytes")
    end

    test "a scenario or calibration id that is missing from the capture list is red", fx do
      update_manifest(fx, fn manifest ->
        update_in(manifest, ["captures"], fn captures ->
          Enum.reject(captures, &(&1["id"] == hd(@defect_ids)))
        end)
      end)

      assert_red(validate(fx), "captures must be exactly")
    end

    test "a journey case that reads back a reason on the nil-reason bounce is red", fx do
      update_cases(fx, fn cases ->
        put_in(
          cases,
          ["journey", "cases", "pw-nil-reason-bounce", "bounce_reject_reason"],
          "invalid"
        )
      end)

      assert_red(validate(fx), "pw-nil-reason-bounce must read back a nil bounce_reject_reason")
    end

    test "a binding to bundle bytes that moved is red without a marker", fx do
      File.write!(
        Path.join(fx.repo_root, bundle_rel()),
        File.read!(Path.join(fx.repo_root, bundle_rel())) <> "/* moved */"
      )

      assert_red(validate(fx), "no superseded.json")
    end
  end

  # ---------------------------------------------------------------------------------------
  # Validators: pure functions of a catalog directory plus options
  # ---------------------------------------------------------------------------------------

  defp validate_catalog(dir, opts) do
    repo_root = Keyword.get(opts, :repo_root, @repo_root)

    case read_json(Path.join(dir, "manifest.json")) do
      {:ok, manifest} when is_map(manifest) ->
        shape_failures(manifest, dir) ++
          file_failures(manifest, dir) ++
          budget_failures(manifest) ++
          binding_failures(manifest, dir, repo_root) ++
          cases_failures(manifest, dir) ++
          review_failures(manifest, dir, repo_root) ++
          privacy_failures(dir)

      {:ok, _other} ->
        ["manifest.json must be a JSON object"]

      {:error, reason} ->
        ["manifest.json is unreadable: #{inspect(reason)}"]
    end
  end

  # -- shape ------------------------------------------------------------------------------

  defp shape_failures(manifest, dir) do
    id = Path.basename(dir)

    exact_keys(manifest, @top_keys, "manifest") ++
      check(manifest["schema"] == @schema, "schema must be #{@schema}") ++
      check(manifest["catalog_id"] == id, "catalog_id must equal the directory name #{id}") ++
      check(
        Regex.match?(~r/\Aafter-[0-9a-f]{7}-\d{8}T\d{6}Z\z/, id),
        "the directory name #{id} must be after-<sha7>-<YYYYMMDDTHHMMSSZ>"
      ) ++
      check(
        is_binary(manifest["run_id"]) and
          Regex.match?(~r/\Amailglass-evidence-\d{14}-\d+-\d+\z/, manifest["run_id"]),
        "run_id must look like mailglass-evidence-<stamp>-<pid>-<rand>"
      ) ++
      check(hex?(manifest["source_digest"], 64), "source_digest must be 64 hex characters") ++
      source_shape_failures(manifest["source"], manifest, id) ++
      served_shape_failures(manifest["served"], manifest["source"]) ++
      server_failures(manifest) ++
      exact_keys(manifest["cases"], @cases_ref_keys, "cases") ++
      check(
        is_map(manifest["cases"]) and manifest["cases"]["file"] == "cases.json",
        "cases.file must be cases.json"
      ) ++
      tools_failures(manifest["tools"]) ++
      determinism_failures(manifest["determinism"]) ++
      exact_keys(manifest["budget"], @budget_keys, "budget") ++
      check(manifest["nested_theme_attr_count"] == 0, "nested_theme_attr_count must be 0") ++
      capture_shape_failures(manifest["captures"])
  end

  defp source_shape_failures(source, manifest, id) when is_map(source) do
    sha7 =
      case Regex.run(~r/\Aafter-([0-9a-f]{7})-/, id) do
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
      check(non_empty?(source["branch"]), "source.branch must be a string") ++
      check(hex?(source["tree_sha"], 40), "source.tree_sha must be 40 hex characters") ++
      check(
        match?({:ok, _, _}, parse_time(source["committed_at"])),
        "source.committed_at must be ISO-8601"
      ) ++
      exact_keys(bundle, @bundle_keys, "source.bundle") ++
      check(
        is_map(bundle) and bundle["path"] == bundle_rel(),
        "source.bundle.path must be #{bundle_rel()}"
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
        is_map(layout) and layout["path"] == layout_rel(),
        "source.root_layout.path must be #{layout_rel()}"
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
          )

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

    exact_keys(served, @served_keys, "served") ++ asset_failures ++ css_failures
  end

  defp served_shape_failures(_served, _source), do: ["served must be an object"]

  # D-21 served SHA: the demo container PID is recorded and the server started after the script did.
  defp server_failures(manifest) do
    server = manifest["server"]

    exact_keys(server, @server_keys, "server") ++
      check(
        is_map(server) and pos_int?(server["container_pid"]),
        "server.container_pid must be a positive integer"
      ) ++ server_time_failures(manifest, server)
  end

  defp server_time_failures(manifest, server) when is_map(server) do
    with {:ok, script, _} <- parse_time(manifest["script_started_at"]),
         {:ok, started, _} <- parse_time(server["started_at"]) do
      check(
        DateTime.compare(started, script) == :gt,
        "server.started_at must be later than script_started_at (the server was restarted by this run)"
      ) ++
        check(
          is_map(manifest["served"]) and
            manifest["served"]["server_started_at"] == server["started_at"],
          "served.server_started_at must equal server.started_at"
        ) ++ committed_failures(manifest["source"], started)
    else
      _ -> ["server.started_at and script_started_at must be ISO-8601"]
    end
  end

  defp server_time_failures(_manifest, _server), do: []

  defp committed_failures(source, started) when is_map(source) do
    case parse_time(source["committed_at"]) do
      {:ok, committed, _} ->
        check(
          DateTime.compare(started, committed) == :gt,
          "server.started_at must be later than source.committed_at (the server was restarted after the commit)"
        )

      _ ->
        []
    end
  end

  defp committed_failures(_source, _started), do: []

  defp tools_failures(tools) when is_map(tools) do
    exact_keys(tools, @tools_keys, "tools") ++
      Enum.flat_map(~w(playwright chromium node os), fn key ->
        check(non_empty?(tools[key]), "tools.#{key} must be a non-empty string")
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
        "determinism.fixed_time must be null"
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
    expected = Enum.sort(@scenario_ids ++ @defect_ids)

    check(length(Enum.uniq(ids)) == length(ids), "captures must have unique ids") ++
      check(
        Enum.sort(ids) == expected,
        "captures must be exactly the 14 scenario ids and the 2 calibration defect ids; missing #{inspect(expected -- ids)}, unexpected #{inspect(ids -- expected)}"
      ) ++
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
            check(
              capture["tier"] == if(capture["id"] in @defect_ids, do: "X", else: "J"),
              "#{label}.tier must be J for a scenario and X for a calibration defect"
            ) ++
            check(is_integer(capture["viewport"]), "#{label}.viewport must be an integer") ++
            check(
              capture["stop_line_hits"] == [],
              "#{label}.stop_line_hits must be empty: the page promised a retry"
            )
        else
          ["#{label} must be an object"]
        end
      end)
  end

  defp capture_shape_failures(_), do: ["captures must be a non-empty list"]

  # -- files ------------------------------------------------------------------------------

  defp file_failures(manifest, dir) do
    captures = manifest["captures"] |> list() |> Enum.filter(&is_map/1)

    per_capture =
      Enum.flat_map(captures, fn capture ->
        png_failures(capture, dir) ++ aria_failures(capture, dir)
      end)

    cases_failures =
      case File.read(Path.join(dir, "cases.json")) do
        {:ok, bytes} ->
          check(
            sha256(bytes) == get_in(manifest, ["cases", "sha256"]),
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

  # Everything in the directory must be listed: the captures and their sidecars, the fixed files, and the
  # review files named (with a sha256) in review-manifest.json.
  defp unlisted_failures(captures, dir) do
    allowed =
      ["manifest.json", "cases.json", "superseded.json", @rubric_rel, @review_manifest_rel] ++
        Enum.flat_map(captures, fn capture -> [capture["file"], capture["aria_file"]] end) ++
        listed_verdict_files(dir)

    dir
    |> files_under()
    |> Enum.reject(&(&1 in allowed))
    |> Enum.map(
      &"unlisted file #{&1} (only manifest.json, cases.json, superseded.json, the listed PNGs and aria sidecars, #{@rubric_rel}, #{@review_manifest_rel} and the verdict files it lists are allowed)"
    )
  end

  defp listed_verdict_files(dir) do
    case read_json(Path.join(dir, @review_manifest_rel)) do
      {:ok, %{} = review} ->
        entries = list(review["scenarios"]) ++ list(review["calibration"])

        for entry <- entries,
            is_map(entry),
            verdict <- list(entry["verdicts"]),
            is_map(verdict),
            is_binary(verdict["file"]),
            do: verdict["file"]

      _ ->
        []
    end
  end

  # -- budget -----------------------------------------------------------------------------

  defp budget_failures(manifest) do
    budget = manifest["budget"]
    captures = manifest["captures"] |> list() |> Enum.filter(&is_map/1)
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

  # -- seeded cases -----------------------------------------------------------------------

  # cases.json holds both seeds: { catalog: <CatalogSeed payload>, journey: <JourneySeed payload> }.
  defp cases_failures(manifest, dir) do
    case read_json(Path.join(dir, "cases.json")) do
      {:ok, %{} = data} ->
        if get_in(manifest, ["cases", "sha256"]) ==
             sha256(File.read!(Path.join(dir, "cases.json"))) do
          cases_semantic_failures(data, manifest)
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

  defp cases_semantic_failures(data, manifest) do
    journey = get_in(data, ["journey", "cases"])
    catalog = get_in(data, ["catalog", "cases"])

    if is_map(journey) and is_map(catalog) do
      keys = ["scenario", "subject"]

      check(
        Enum.sort(Map.keys(journey)) == Enum.sort(@journey_slugs),
        "cases.json journey must list exactly the six password-reset cases #{inspect(Enum.sort(@journey_slugs))}, found #{inspect(Enum.sort(Map.keys(journey)))}"
      ) ++
        Enum.flat_map(@journey_slugs, fn slug ->
          entry = journey[slug] || %{}

          check(
            entry["source"] == "journey_seed" and entry["last_error_present"] == false and
              entry["metadata_keys"] == keys,
            "#{slug} must come from journey_seed with last_error_present false and metadata_keys #{inspect(keys)} (no reason or cause key)"
          )
        end) ++
        check(
          (journey["pw-nil-reason-bounce"] || %{})["bounce_reject_reason"] == nil and
            (journey["pw-nil-reason-bounce"] || %{})["bounced"] == true,
          "pw-nil-reason-bounce must read back a nil bounce_reject_reason on a bounced row (a nil reason is never given a cause)"
        ) ++
        check(
          (journey["pw-typo-bounce"] || %{})["bounce_reject_reason"] == "invalid",
          "pw-typo-bounce must read back bounce_reject_reason \"invalid\""
        ) ++
        check(
          (journey["pw-bounce-then-open"] || %{})["bounced"] == true and
            (journey["pw-bounce-then-open"] || %{})["last_event_type"] == "opened" and
            (journey["pw-bounce-then-open"] || %{})["terminal"] == true,
          "pw-bounce-then-open must be a bounced, terminal row whose latest event is an open"
        ) ++
        check(
          (journey["pw-suppressed"] || %{})["status"] == "suppressed" and
            (journey["pw-suppressed"] || %{})["suppression_reason"] == "hard_bounce",
          "pw-suppressed must be a suppressed row with a hard_bounce suppression entry"
        ) ++
        check(
          (catalog["typo-bounce"] || %{})["source"] == "catalog_seed",
          "catalog.typo-bounce must be the CatalogSeed row (the id that pairs with the Phase 180 capture)"
        ) ++
        route_failures(manifest, journey, catalog)
    else
      ["cases.json must hold journey.cases and catalog.cases objects"]
    end
  end

  # A detail capture's route must open the delivery its case names, so cases.json and the PNGs agree.
  defp route_failures(manifest, journey, catalog) do
    for capture <- list(manifest["captures"]),
        is_map(capture),
        capture["screen"] in [
          "delivery-detail",
          "calib-defect-no-zone",
          "calib-defect-no-status-word"
        ],
        slug = case_for(capture["case"], journey, catalog),
        slug != nil,
        not String.contains?(capture["route"] || "", "delivery_id=#{slug["delivery_id"]}") do
      "capture #{capture["id"]}: its route does not open the delivery #{slug["delivery_id"]} that cases.json names for #{capture["case"]}"
    end
  end

  defp case_for("reset-" <> rest, journey, _catalog), do: journey["pw-" <> rest]
  defp case_for(slug, _journey, catalog) when is_binary(slug), do: catalog[slug]
  defp case_for(_, _, _), do: nil

  # Static check over the journey seed module text: pure function of a string.
  defp seed_text_failures(text) do
    check(
      not Regex.match?(~r/next try|will retry|retry at|retrying/i, text),
      "journey_seed.ex contains a retry-timing phrase (next try, will retry, retry at, retrying): the stop line forbids seeded retry copy"
    ) ++
      check(
        not Regex.match?(~r/"(reason|cause|retry_at|next_retry_at)"/, text),
        ~s|journey_seed.ex contains a "reason", "cause", "retry_at" or "next_retry_at" metadata key literal: the stop line forbids seeded cause or retry copy|
      )
  end

  # -- privacy ----------------------------------------------------------------------------

  defp privacy_failures(dir) do
    texts =
      for file <- files_under(dir),
          file in [
            "manifest.json",
            "cases.json",
            "superseded.json",
            @rubric_rel,
            @review_manifest_rel
          ] or
            String.starts_with?(file, "aria/") or String.starts_with?(file, "review/verdicts/"),
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

  # -- review -----------------------------------------------------------------------------

  defp review_failures(manifest, dir, repo_root) do
    case read_json(Path.join(dir, @review_manifest_rel)) do
      {:error, :enoent} ->
        ["#{@review_manifest_rel} is missing: the catalog has not been reviewed"]

      {:error, reason} ->
        ["#{@review_manifest_rel} is unreadable: #{inspect(reason)}"]

      {:ok, %{} = review} ->
        review_shape_failures(review, manifest, dir) ++
          rubric_failures(review, dir) ++
          calibration_set_failures(review) ++ gate_failures(review, dir, repo_root)

      {:ok, _} ->
        ["#{@review_manifest_rel} must be a JSON object"]
    end
  end

  defp review_shape_failures(review, manifest, dir) do
    manifest_bytes = File.read!(Path.join(dir, "manifest.json"))

    exact_keys(review, @review_keys, "review-manifest") ++
      check(
        review["schema"] == @review_schema,
        "review-manifest schema must be #{@review_schema}"
      ) ++
      check(
        review["catalog_id"] == manifest["catalog_id"],
        "review-manifest catalog_id must equal the manifest catalog_id"
      ) ++
      check(
        review["manifest_sha256"] == sha256(manifest_bytes),
        "review-manifest manifest_sha256 does not match manifest.json (the review is bound to the captured evidence)"
      ) ++
      check(
        is_integer(review["rng_seed"]),
        "review-manifest rng_seed must be an integer (the seed of the A/B order)"
      ) ++
      check(
        hex?(review["rubric_sha256"], 64),
        "review-manifest rubric_sha256 must be 64 hex characters"
      ) ++
      check(
        is_list(review["scenarios"]) and is_list(review["calibration"]) and
          is_list(review["prior_iterations"]),
        "review-manifest scenarios, calibration and prior_iterations must be lists"
      ) ++
      Enum.flat_map(list(review["prior_iterations"]), fn prior ->
        exact_keys(prior, @prior_keys, "prior_iterations entry") ++
          check(
            is_map(prior) and non_empty?(prior["catalog_id"]) and is_list(prior["rejected"]) and
              Enum.all?(prior["rejected"], &is_binary/1),
            "prior_iterations entries need a catalog_id and a rejected list of scenario ids"
          )
      end) ++
      check(
        review["scenarios"]
        |> list()
        |> Enum.map(&(is_map(&1) and &1["scenario_id"]))
        |> Enum.sort() ==
          Enum.sort(@scenario_ids),
        "review-manifest must hold exactly the 14 scenario ids"
      )
  end

  defp rubric_failures(review, dir) do
    case File.read(Path.join(dir, @rubric_rel)) do
      {:ok, rubric} ->
        check(
          sha256(rubric) == review["rubric_sha256"],
          "#{@rubric_rel} does not match review-manifest rubric_sha256 (rubric_sha256)"
        ) ++
          for id <- ReviewGate.rule_ids(), not String.contains?(rubric, id) do
            "#{@rubric_rel} does not carry the rule id #{id}"
          end ++
          check(
            String.contains?(rubric, "Stop-line override"),
            "#{@rubric_rel} does not state the Stop-line override (the stop line wins over the book's retry sentences)"
          )

      {:error, _} ->
        ["#{@rubric_rel} is missing"]
    end
  end

  defp calibration_set_failures(review) do
    items = list(review["calibration"]) |> Enum.filter(&is_map/1)
    kinds = Enum.frequencies_by(items, & &1["kind"])
    ids = Enum.map(items, & &1["id"])

    check(
      Map.get(kinds, "before_as_after", 0) >= 5,
      "calibration needs at least five before_as_after items, found #{Map.get(kinds, "before_as_after", 0)}"
    ) ++
      check(
        Map.get(kinds, "injected_defect", 0) == 2,
        "calibration needs exactly two injected_defect items, found #{Map.get(kinds, "injected_defect", 0)}"
      ) ++
      check(
        Map.get(kinds, "known_good", 0) == 1,
        "calibration needs exactly one known_good item, found #{Map.get(kinds, "known_good", 0)}"
      ) ++
      check(length(Enum.uniq(ids)) == length(ids), "calibration ids must be unique") ++
      check(
        items
        |> Enum.filter(&(&1["kind"] == "injected_defect"))
        |> Enum.map(& &1["id"])
        |> Enum.sort() == Enum.sort(@defect_ids),
        "the injected_defect items must be the two calibration defect captures #{inspect(@defect_ids)}"
      ) ++
      check(
        items |> Enum.filter(&(&1["kind"] == "known_good")) |> Enum.map(& &1["id"]) == [
          @known_good_id
        ],
        "the known_good item must be #{@known_good_id}"
      )
  end

  # Builds the gate input from the files and returns every failure the build itself finds. The gate runs
  # on whatever could be read, so one missing verdict file does not hide the rest.
  defp gate_failures(review, dir, repo_root) do
    case gate_input(dir, review, repo_root) do
      {:ok, %{scenarios: scenarios, calibration: calibration}} ->
        case ReviewGate.gate(%{scenarios: scenarios, calibration: calibration}) do
          {:pass, []} -> []
          {:reject, messages} -> messages
        end

      {:error, failures, %{scenarios: scenarios, calibration: calibration}} ->
        failures ++
          case ReviewGate.gate(%{scenarios: scenarios, calibration: calibration}) do
            {:pass, []} -> []
            {:reject, messages} -> messages
          end
    end
  end

  # {:ok, input} | {:error, failures, partial_input}
  defp gate_input(dir, review, repo_root) do
    manifest_captures =
      case read_json(Path.join(dir, "manifest.json")) do
        {:ok, %{"captures" => captures}} -> Map.new(list(captures), &{&1["id"], &1})
        _ -> %{}
      end

    seed = review["rng_seed"]

    {scenario_failures, scenarios} =
      review["scenarios"]
      |> list()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&scenario_item(&1, manifest_captures, seed, dir, repo_root))
      |> Enum.unzip()

    {calibration_failures, calibration} =
      review["calibration"]
      |> list()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&calibration_item(&1, manifest_captures, dir, repo_root))
      |> Enum.unzip()

    failures = List.flatten(scenario_failures ++ calibration_failures)

    input = %{
      scenarios: Enum.reject(scenarios, &is_nil/1),
      calibration: Enum.reject(calibration, &is_nil/1)
    }

    if failures == [], do: {:ok, input}, else: {:error, failures, input}
  end

  @before_png_pattern ~r|\A\.planning/research/brand-v2-adoption/before-catalog/before-[0-9a-f]{7}-\d{8}T\d{6}Z/[a-z0-9_.-]+\.png\z|
  @before_aria_pattern ~r|\A\.planning/research/brand-v2-adoption/before-catalog/before-[0-9a-f]{7}-\d{8}T\d{6}Z/aria/[a-z0-9_.-]+\.yml\z|

  defp scenario_item(entry, captures, seed, dir, repo_root) do
    id = entry["scenario_id"]
    label = "review scenario #{inspect(id)}"
    capture = Map.get(captures, id, %{})
    paired = id in @paired_ids

    before_failures =
      cond do
        paired ->
          before_pair_failures(entry, id, label, repo_root)

        true ->
          check(
            entry["before_png"] == nil and entry["before_png_sha256"] == nil,
            "#{label}: has no before counterpart, so before_png and before_png_sha256 must be null (judged after_only)"
          )
      end

    base_failures =
      exact_keys(entry, @scenario_keys, label) ++
        check(entry["after_png"] == "#{id}.png", "#{label}: after_png must be #{id}.png") ++
        check(
          entry["after_png_sha256"] == capture["sha256"],
          "#{label}: after_png_sha256 does not match the manifest capture (the screenshot the judges saw is not the committed one)"
        ) ++
        check(entry["aria"] == "aria/#{id}.yml", "#{label}: aria must be aria/#{id}.yml") ++
        check(
          entry["aria_sha256"] == capture["aria_sha256"],
          "#{label}: aria_sha256 does not match the manifest capture"
        ) ++
        check(non_empty?(entry["goal"]), "#{label}: goal must be a one-line string") ++
        before_failures

    aria_text = read_text(Path.join(dir, "aria/#{id}.yml"))

    allowed = allowed_inputs([entry["after_png"], entry["aria"], entry["before_png"]])
    required_with = [entry["after_png"], entry["aria"]] ++ @allowed_input_extras

    {verdict_failures, verdicts} =
      verdict_entries(entry, id, label, allowed, required_with, entry["before_png"], dir)

    order_failures = seeded_order_failures(paired, id, label, seed, verdicts)

    item = %{id: id, paired: paired, aria: aria_text, verdicts: Enum.map(verdicts, & &1.verdict)}
    {base_failures ++ verdict_failures ++ order_failures, item}
  end

  defp before_pair_failures(entry, id, label, repo_root) do
    path = entry["before_png"]

    check(
      is_binary(path) and Regex.match?(@before_png_pattern, path) and
        Path.basename(path) == "#{id}.png",
      "#{label}: before_png must be the Phase 180 capture of exactly this id (pairing is by exact id)"
    ) ++
      case is_binary(path) and File.read(Path.join(repo_root, path)) do
        {:ok, bytes} ->
          check(
            sha256(bytes) == entry["before_png_sha256"],
            "#{label}: before_png_sha256 does not match the before PNG"
          )

        _ ->
          ["#{label}: before_png is missing or unreadable"]
      end
  end

  defp calibration_item(entry, captures, dir, repo_root) do
    id = entry["id"]
    label = "review calibration #{inspect(id)}"
    kind = entry["kind"]

    expect_failures =
      check(
        entry["expect"] == if(kind == "known_good", do: "pass", else: "reject"),
        "#{label}: a #{kind} item must expect #{if kind == "known_good", do: "pass", else: "reject"}"
      )

    {png_rel, aria_rel, source_failures} =
      calibration_sources(entry, id, kind, label, captures, dir, repo_root)

    base_failures =
      exact_keys(entry, @calibration_keys, label) ++
        expect_failures ++
        source_failures

    aria_text = read_text(resolve_path(aria_rel, dir, repo_root))
    allowed = allowed_inputs([png_rel, aria_rel])
    required_with = [png_rel, aria_rel] ++ @allowed_input_extras

    {verdict_failures, verdicts} =
      verdict_entries(entry, id, label, allowed, required_with, nil, dir)

    item = %{
      id: id,
      kind: kind,
      expect: entry["expect"],
      paired: false,
      aria: aria_text,
      verdicts: Enum.map(verdicts, & &1.verdict)
    }

    {base_failures ++ verdict_failures, item}
  end

  # {png path, aria path, failures}. The path is the one recorded in the review manifest.
  defp calibration_sources(entry, id, kind, label, captures, dir, repo_root) do
    png = entry["png"]
    aria = entry["aria"]

    {expected_png, expected_aria} =
      case kind do
        "before_as_after" ->
          source = String.replace_prefix(id, "calib-before__", "")

          {Regex.match?(@before_png_pattern, png || "") and
             Path.basename(png || "") == "#{source}.png",
           Regex.match?(@before_aria_pattern, aria || "") and
             Path.basename(aria || "") == "#{source}.yml"}

        "injected_defect" ->
          {png == "#{id}.png", aria == "aria/#{id}.yml"}

        "known_good" ->
          {png == "#{@known_good_scenario}.png", aria == "aria/#{@known_good_scenario}.yml"}

        _ ->
          {false, false}
      end

    capture =
      case kind do
        "injected_defect" -> Map.get(captures, id, %{})
        "known_good" -> Map.get(captures, @known_good_scenario, %{})
        _ -> %{}
      end

    source_ids_ok =
      kind != "before_as_after" or
        String.replace_prefix(id, "calib-before__", "") in @before_as_after_sources

    failures =
      check(
        expected_png,
        "#{label}: png #{inspect(png)} is not the screenshot a #{kind} item must show"
      ) ++
        check(
          expected_aria,
          "#{label}: aria #{inspect(aria)} is not the aria sidecar a #{kind} item must carry"
        ) ++
        check(
          source_ids_ok,
          "#{label}: a before_as_after item must come from the Phase 180 Activity and delivery-detail captures #{inspect(@before_as_after_sources)}"
        ) ++
        file_sha_failures(png, entry["png_sha256"], label <> " png", dir, repo_root) ++
        file_sha_failures(aria, entry["aria_sha256"], label <> " aria", dir, repo_root) ++
        if(capture == %{},
          do: [],
          else:
            check(
              entry["png_sha256"] == capture["sha256"],
              "#{label}: png_sha256 does not match the manifest capture"
            ) ++
              check(
                entry["aria_sha256"] == capture["aria_sha256"],
                "#{label}: aria_sha256 does not match the manifest capture"
              )
        )

    {png, aria, failures}
  end

  defp file_sha_failures(path, sha, label, dir, repo_root) when is_binary(path) do
    case File.read(resolve_path(path, dir, repo_root)) do
      {:ok, bytes} ->
        check(sha256(bytes) == sha, "#{label}: sha256 does not match the file #{path}")

      {:error, _} ->
        ["#{label}: #{path} is missing or unreadable"]
    end
  end

  defp file_sha_failures(_path, _sha, label, _dir, _repo_root),
    do: ["#{label}: path must be a string"]

  # Paths under the Phase 180 before-catalog are repo-relative; everything else is relative to the catalog.
  defp resolve_path(path, dir, repo_root) when is_binary(path) do
    resolved =
      if String.starts_with?(path, @before_root_rel <> "/"),
        do: Path.join(repo_root, path),
        else: Path.join(dir, path)

    root =
      if String.starts_with?(path, @before_root_rel <> "/"),
        do: Path.join(repo_root, @before_root_rel),
        else: dir

    if confined(resolved, root) == :ok, do: resolved, else: Path.join(root, "__outside__")
  end

  defp resolve_path(_path, dir, _repo_root), do: Path.join(dir, "__missing__")

  defp read_text(path) do
    case File.read(path) do
      {:ok, text} -> text
      {:error, _} -> ""
    end
  end

  # The only inputs a judge may be given: the after PNG, the before PNG, the aria sidecar, rubric.md and the goal.
  defp allowed_inputs(paths), do: Enum.filter(paths, &is_binary/1) ++ @allowed_input_extras

  # Validates each verdict entry against the files; returns {failures, [%{judge, verdict}]} for every
  # verdict file that could be read and decoded.
  defp verdict_entries(entry, id, label, allowed, required_with, before_png, dir) do
    entries = list(entry["verdicts"])

    results =
      for ventry <- entries do
        vlabel = "#{label} verdict #{inspect(is_map(ventry) && ventry["judge"])}"

        if is_map(ventry) do
          file = "review/verdicts/#{id}.#{ventry["judge"]}.json"
          path = Path.join(dir, file)
          paired_view? = ventry["order"] in ["after_first", "before_first"]

          required =
            if paired_view? and before_png, do: required_with ++ [before_png], else: required_with

          inputs = list(ventry["inputs"])

          {file_failures, verdict} =
            case File.read(path) do
              {:ok, bytes} ->
                sha_failures =
                  check(
                    sha256(bytes) == ventry["sha256"],
                    "#{vlabel}: sha256 does not match #{file} (the verdict was edited)"
                  )

                case Jason.decode(bytes) do
                  {:ok, %{} = decoded} -> {sha_failures, decoded}
                  _ -> {sha_failures ++ ["#{vlabel}: #{file} is not a JSON object"], nil}
                end

              {:error, _} ->
                {["#{vlabel}: #{file} is missing"], nil}
            end

          failures =
            exact_keys(ventry, @verdict_entry_keys, vlabel) ++
              check(ventry["file"] == file, "#{vlabel}: file must be #{file}") ++
              check(is_list(ventry["inputs"]), "#{vlabel}: inputs must be a list") ++
              for(
                input <- inputs,
                input not in allowed,
                do:
                  "#{vlabel}: input #{inspect(input)} is outside the allowed set (after PNG, before PNG, aria sidecar, #{@rubric_rel}, goal)"
              ) ++
              check(
                Enum.sort(inputs) == Enum.sort(required),
                "#{vlabel}: inputs must list exactly #{inspect(Enum.sort(required))}, got #{inspect(Enum.sort(inputs))}"
              ) ++ file_failures

          {failures,
           verdict && %{judge: ventry["judge"], order: ventry["order"], verdict: verdict}}
        else
          {["#{label}: a verdicts entry must be an object"], nil}
        end
      end

    {failures, verdicts} = Enum.unzip(results)
    {List.flatten(failures), Enum.reject(verdicts, &is_nil/1)}
  end

  # The A/B order of judges a and b of a paired scenario comes from the recorded seed; the manifest's own
  # `order` must also match the order in the verdict file.
  defp seeded_order_failures(paired, id, label, seed, verdicts) do
    mismatch =
      for %{order: order, verdict: verdict} <- verdicts, verdict["order"] != order do
        "#{label}: the manifest records order #{inspect(order)} but the verdict file says #{inspect(verdict["order"])}"
      end

    seeded =
      if paired and is_integer(seed) do
        {first, second} = ReviewGate.assign_orders(seed, id)
        expected = %{"a" => first, "b" => second}

        for %{judge: judge, order: order} <- verdicts,
            Map.has_key?(expected, judge),
            expected[judge] != order do
          "#{label}: judge #{judge} order #{inspect(order)} must come from rng_seed #{seed} (expected #{expected[judge]})"
        end
      else
        []
      end

    mismatch ++ seeded
  end

  # ---------------------------------------------------------------------------------------
  # Small helpers
  # ---------------------------------------------------------------------------------------

  defp assert_red(failures, fragment) do
    assert Enum.any?(failures, &String.contains?(&1, fragment)),
           "expected a failure containing #{inspect(fragment)}, got:\n" <>
             Enum.map_join(failures, "\n", &"  - #{&1}")
  end

  defp tmp_dir do
    tmp =
      Path.join(
        System.tmp_dir!(),
        "mailglass-admin-after-catalog-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp)
    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(tmp) end)
    tmp
  end

  defp copy_bound_inputs(tmp) do
    repo_root = Path.join(tmp, "repo")

    for relative <- [bundle_rel(), layout_rel()] do
      File.mkdir_p!(Path.dirname(Path.join(repo_root, relative)))
      File.cp!(Path.join(@repo_root, relative), Path.join(repo_root, relative))
    end

    repo_root
  end

  # ---------------------------------------------------------------------------------------
  # Gate fixtures: verdict builders over one aria text
  # ---------------------------------------------------------------------------------------

  defp aria do
    "- heading \"Activity\" [level=1]\n- time: Nov 15, 2026, 2:05 PM UTC\n- text: pw-typo-bounce@northstar.example\n"
  end

  defp rule(id, ok, quote_text),
    do: %{
      "id" => id,
      "ok" => ok,
      "evidence_quote" => quote_text,
      "screenshot_region" => "page heading"
    }

  defp pass(id, judge, order, opts \\ []) do
    quote_text = Keyword.get(opts, :quote_text, "heading \"Activity\" [level=1]")

    %{
      "scenario_id" => id,
      "judge" => judge,
      "order" => order,
      "verdict" => "pass",
      "rules" => [
        rule("R-WORDS-1", true, quote_text),
        rule("R-TIME-1", true, "time: Nov 15, 2026, 2:05 PM UTC")
      ],
      "reasons" => "The words and the time zone follow the book."
    }
  end

  defp reject(id, judge, order, opts \\ []) do
    quote_text = Keyword.get(opts, :quote_text, "time: Nov 15, 2026, 2:05 PM UTC")

    %{
      "scenario_id" => id,
      "judge" => judge,
      "order" => order,
      "verdict" => "reject",
      "rules" => [rule("R-TIME-1", false, quote_text)],
      "reasons" => "The time reads as a bare time."
    }
  end

  defp scenario(id, verdicts, opts \\ []),
    do: %{id: id, paired: Keyword.get(opts, :paired, false), aria: aria(), verdicts: verdicts}

  defp good_scenario,
    do: scenario("g1", [pass("g1", "a", "after_only"), pass("g1", "b", "after_only")])

  defp rejected_pair(id), do: [reject(id, "a", "after_only"), reject(id, "b", "after_only")]

  defp known_bad(id, verdicts, kind \\ "before_as_after"),
    do: %{id: id, kind: kind, expect: "reject", paired: false, aria: aria(), verdicts: verdicts}

  defp known_good(id, verdicts \\ nil) do
    verdicts = verdicts || [pass(id, "a", "after_only"), pass(id, "b", "after_only")]
    %{id: id, kind: "known_good", expect: "pass", paired: false, aria: aria(), verdicts: verdicts}
  end

  defp good_calibration do
    [
      known_bad("c1", rejected_pair("c1")),
      known_bad("c2", rejected_pair("c2"), "injected_defect"),
      known_good("c3")
    ]
  end

  defp gate_for(scenarios),
    do: ReviewGate.gate(%{scenarios: scenarios, calibration: good_calibration()})

  # ---------------------------------------------------------------------------------------
  # Synthetic catalog fixture for the teeth
  # ---------------------------------------------------------------------------------------

  defp validate(fx, opts \\ []) do
    validate_catalog(fx.dir, Keyword.merge([repo_root: fx.repo_root], opts))
  end

  @fixture_seed 1_821_821
  @fixture_before_dir "before-1234567-20261114T000000Z"

  def fixture(_context) do
    tmp = tmp_dir()
    repo_root = copy_bound_inputs(tmp)
    before_dir = Path.join(repo_root, "#{@before_root_rel}/#{@fixture_before_dir}")
    File.mkdir_p!(Path.join(before_dir, "aria"))

    id = "after-1234567-20261115T000000Z"
    dir = Path.join(tmp, "catalog/#{id}")
    File.mkdir_p!(Path.join(dir, "aria"))
    File.mkdir_p!(Path.join(dir, "review/verdicts"))

    css = File.read!(Path.join(repo_root, bundle_rel()))
    layout = File.read!(Path.join(repo_root, layout_rel()))
    cases = fixture_cases()
    cases_text = Jason.encode!(cases, pretty: true) <> "\n"
    File.write!(Path.join(dir, "cases.json"), cases_text)

    captures =
      for {cid, index} <- Enum.with_index(@scenario_ids ++ @defect_ids) do
        png = tiny_png(8 + rem(index, 5), 6, index)
        aria_text = fixture_aria(cid)
        File.write!(Path.join(dir, "#{cid}.png"), png)
        File.write!(Path.join(dir, "aria/#{cid}.yml"), aria_text)
        fixture_capture(cid, index, png, aria_text, cases)
      end

    # The Phase 180 captures a before_as_after item and a paired scenario read from.
    before_ids = Enum.uniq(@before_as_after_sources ++ @paired_ids)

    for {bid, index} <- Enum.with_index(before_ids) do
      File.write!(Path.join(before_dir, "#{bid}.png"), tiny_png(9, 7, index + 40))

      File.write!(
        Path.join(before_dir, "aria/#{bid}.yml"),
        "- heading \"Deliveries\" [level=1]\n- text: #{bid}\n"
      )
    end

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
        "bundle" => %{"path" => bundle_rel(), "sha256" => css_sha, "git_blob_sha" => css_blob},
        "root_layout" => %{"path" => layout_rel(), "git_blob_sha" => git_blob_sha(layout)},
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
        "fonts_loaded" => ["Atkinson Hyperlegible Next 400 normal"],
        "double_capture_identical" => true
      },
      "budget" => %{
        "image_count" => length(captures),
        "total_bytes" => captures |> Enum.map(& &1["bytes"]) |> Enum.sum(),
        "cap_images" => @cap_images,
        "cap_bytes" => @cap_bytes
      },
      "nested_theme_attr_count" => 0,
      "captures" => captures,
      "script_started_at" => "2026-11-15T00:04:30.000Z",
      "server" => %{"container_pid" => 4242, "started_at" => "2026-11-15T00:05:00.000Z"}
    }

    File.write!(Path.join(dir, "manifest.json"), Jason.encode!(manifest, pretty: true) <> "\n")
    rubric = fixture_rubric()
    File.write!(Path.join(dir, @rubric_rel), rubric)

    {scenarios, calibration, calibration_ids} = fixture_review_items(dir, captures, before_dir)

    review = %{
      "schema" => @review_schema,
      "catalog_id" => id,
      "manifest_sha256" => sha256(File.read!(Path.join(dir, "manifest.json"))),
      "rng_seed" => @fixture_seed,
      "rubric_sha256" => sha256(rubric),
      "scenarios" => scenarios,
      "calibration" => calibration,
      "prior_iterations" => [
        %{
          "catalog_id" => "after-1234567-20261114T000000Z",
          "rejected" => ["deliveries__northstar__empty-search__375__light"]
        }
      ]
    }

    File.write!(Path.join(dir, @review_manifest_rel), Jason.encode!(review, pretty: true) <> "\n")

    {:ok,
     %{
       tmp: tmp,
       dir: dir,
       id: id,
       repo_root: repo_root,
       rng_seed: @fixture_seed,
       calibration_ids: calibration_ids
     }}
  end

  defp fixture_rubric do
    ids = Enum.join(ReviewGate.rule_ids(), "\n")

    "# Review rubric\n\n#{ids}\n\n## Stop-line override\n\nThe stop line wins over the book's retry sentences.\n"
  end

  # Aria text per capture. The injected-defect shots carry the defect in their sidecar; every sidecar
  # holds the quotes the synthetic verdicts cite.
  defp fixture_aria(cid) do
    base =
      "- heading \"Activity\" [level=1]\n- text: #{cid}\n- text: pw-typo-bounce@northstar.example\n"

    cond do
      String.starts_with?(cid, "calib-defect-no-zone") ->
        base <> "- time: Nov 15, 2026, 2:05 PM\n"

      true ->
        base <> "- time: Nov 15, 2026, 2:05 PM UTC\n"
    end
  end

  defp fixture_capture(cid, index, png, aria_text, cases) do
    slug =
      cond do
        String.contains?(cid, "__reset-") ->
          cid |> String.split("__") |> Enum.at(1) |> String.replace_prefix("reset-", "pw-")

        true ->
          nil
      end

    delivery_id =
      cond do
        slug != nil and String.starts_with?(cid, "delivery-detail__") ->
          cases["journey"]["cases"][slug]["delivery_id"]

        String.starts_with?(cid, "calib-defect-") ->
          cases["journey"]["cases"]["pw-typo-bounce"]["delivery_id"]

        cid == "delivery-detail__typo-bounce__default__375__light" ->
          cases["catalog"]["cases"]["typo-bounce"]["delivery_id"]

        true ->
          nil
      end

    [screen, second | _] = String.split(cid, "__")
    theme = if String.ends_with?(cid, "__dark"), do: "dark", else: "light"

    %{
      "id" => cid,
      "file" => "#{cid}.png",
      "sha256" => sha256(png),
      "bytes" => byte_size(png),
      "w" => 8 + rem(index, 5),
      "h" => 6,
      "screen" => screen,
      "route" =>
        if(delivery_id,
          do: "/ops/mail?tenant_id=northstar&view=deliveries&delivery_id=#{delivery_id}&full=1",
          else: "/ops/mail?tenant_id=northstar&view=deliveries"
        ),
      "fixture" => "northstar",
      "state" => "default",
      "case" => if(delivery_id, do: second, else: nil),
      "viewport" => if(String.contains?(cid, "__1440__"), do: 1440, else: 375),
      "theme" => theme,
      "root_theme_attr" => "mailglass-#{theme}",
      "tier" => if(String.starts_with?(cid, "calib-defect-"), do: "X", else: "J"),
      "aria_file" => "aria/#{cid}.yml",
      "aria_sha256" => sha256(aria_text),
      "stop_line_hits" => []
    }
  end

  defp fixture_cases do
    journey =
      Map.new(@journey_slugs, fn slug ->
        {slug,
         %{
           "source" => "journey_seed",
           "delivery_id" =>
             "01a1e1b1-0000-7000-8000-" <> String.pad_leading("#{:erlang.phash2(slug)}", 12, "0"),
           "provider_message_id" => "pm-jrn-#{slug}-001",
           "recipient" => "#{slug}@northstar.example",
           "scenario" => "journey_#{String.replace(slug, "-", "_")}",
           "status" => if(slug == "pw-suppressed", do: "suppressed", else: "sent"),
           "last_event_type" => if(slug == "pw-bounce-then-open", do: "opened", else: "bounced"),
           "bounced" => slug in ["pw-typo-bounce", "pw-bounce-then-open", "pw-nil-reason-bounce"],
           "terminal" => slug not in ["pw-sent-no-report", "pw-deferred"],
           "suppressed" => slug == "pw-suppressed",
           "bounce_reject_reason" =>
             case slug do
               "pw-typo-bounce" -> "invalid"
               "pw-bounce-then-open" -> "bounced"
               _ -> nil
             end,
           "suppression_reason" => if(slug == "pw-suppressed", do: "hard_bounce", else: nil),
           "last_error_present" => false,
           "metadata_keys" => ["scenario", "subject"]
         }}
      end)

    %{
      "catalog" => %{
        "seed_anchor_utc" => "2026-11-15T00:04:00Z",
        "cases" => %{
          "typo-bounce" => %{
            "source" => "catalog_seed",
            "delivery_id" => "01a1e1b1-1111-7000-8000-000000000001"
          }
        }
      },
      "journey" => %{"seed_anchor_utc" => "2026-11-15T00:04:01Z", "cases" => journey}
    }
  end

  # Writes the verdict files and returns the review-manifest scenario and calibration entries.
  defp fixture_review_items(dir, captures, before_dir) do
    by_id = Map.new(captures, &{&1["id"], &1})
    rubric_rel = @rubric_rel
    before_rel = "#{@before_root_rel}/#{@fixture_before_dir}"

    scenarios =
      for sid <- @scenario_ids do
        capture = by_id[sid]
        paired = sid in @paired_ids
        {first, second} = ReviewGate.assign_orders(@fixture_seed, sid)

        orders =
          if paired,
            do: [{"a", first}, {"b", second}],
            else: [{"a", "after_only"}, {"b", "after_only"}]

        before_png = if paired, do: "#{before_rel}/#{sid}.png"
        base_inputs = [capture["file"], capture["aria_file"], rubric_rel, "goal"]

        verdicts =
          for {judge, order} <- orders do
            inputs = if paired, do: base_inputs ++ [before_png], else: base_inputs
            write_verdict(dir, sid, judge, pass(sid, judge, order), order, inputs)
          end

        %{
          "scenario_id" => sid,
          "after_png" => capture["file"],
          "after_png_sha256" => capture["sha256"],
          "aria" => capture["aria_file"],
          "aria_sha256" => capture["aria_sha256"],
          "before_png" => before_png,
          "before_png_sha256" =>
            if(paired, do: sha256(File.read!(Path.join(before_dir, "#{sid}.png")))),
          "goal" => "Check #{sid} against the rubric.",
          "verdicts" => verdicts
        }
      end

    before_items =
      for source <- @before_as_after_sources do
        cid = "calib-before__#{source}"
        png = "#{before_rel}/#{source}.png"
        aria_path = "#{before_rel}/aria/#{source}.yml"

        template =
          reject(cid, "a", "after_only")
          |> Map.put("rules", [rule("R-WORDS-1", false, "heading \"Deliveries\" [level=1]")])

        {cid, "before_as_after", "reject", png, aria_path,
         sha256(File.read!(Path.join(before_dir, "#{source}.png"))),
         sha256(File.read!(Path.join(before_dir, "aria/#{source}.yml"))), template}
      end

    defect_items =
      for cid <- @defect_ids do
        capture = by_id[cid]

        quote_text =
          if String.contains?(cid, "no-zone"),
            do: "time: Nov 15, 2026, 2:05 PM",
            else: "text: #{cid}"

        rid = if String.contains?(cid, "no-zone"), do: "R-TIME-1", else: "R-STATUS-1"

        {cid, "injected_defect", "reject", capture["file"], capture["aria_file"],
         capture["sha256"], capture["aria_sha256"],
         reject(cid, "a", "after_only") |> Map.put("rules", [rule(rid, false, quote_text)])}
      end

    good = by_id[@known_good_scenario]

    good_item =
      {@known_good_id, "known_good", "pass", good["file"], good["aria_file"], good["sha256"],
       good["aria_sha256"], pass(@known_good_id, "a", "after_only")}

    calibration =
      for {cid, kind, expect, png, aria_path, png_sha, aria_sha, template} <-
            before_items ++ defect_items ++ [good_item] do
        inputs = [png, aria_path, rubric_rel, "goal"]

        verdicts =
          for judge <- ["a", "b"] do
            verdict =
              Map.merge(template, %{
                "scenario_id" => cid,
                "judge" => judge,
                "order" => "after_only"
              })

            write_verdict(dir, cid, judge, verdict, "after_only", inputs)
          end

        %{
          "id" => cid,
          "kind" => kind,
          "expect" => expect,
          "png" => png,
          "png_sha256" => png_sha,
          "aria" => aria_path,
          "aria_sha256" => aria_sha,
          "verdicts" => verdicts
        }
      end

    {scenarios, calibration, Enum.map(calibration, & &1["id"])}
  end

  defp write_verdict(dir, id, judge, verdict, order, inputs) do
    file = "review/verdicts/#{id}.#{judge}.json"
    text = Jason.encode!(verdict, pretty: true) <> "\n"
    File.write!(Path.join(dir, file), text)

    %{
      "judge" => judge,
      "file" => file,
      "sha256" => sha256(text),
      "order" => order,
      "inputs" => inputs
    }
  end

  # Rewrites one verdict file and records its new sha256, so only the content rule under test can fail.
  defp rewrite_verdict(fx, id, judge, fun) do
    file = "review/verdicts/#{id}.#{judge}.json"
    path = Path.join(fx.dir, file)
    verdict = path |> File.read!() |> Jason.decode!() |> fun.()
    text = Jason.encode!(verdict, pretty: true) <> "\n"
    File.write!(path, text)

    update_review(fx, fn review ->
      Enum.reduce(["scenarios", "calibration"], review, fn key, acc ->
        Map.update!(acc, key, fn entries ->
          Enum.map(entries, fn entry ->
            if (entry["scenario_id"] || entry["id"]) == id do
              Map.update!(entry, "verdicts", fn verdicts ->
                Enum.map(
                  verdicts,
                  &if(&1["judge"] == judge, do: Map.put(&1, "sha256", sha256(text)), else: &1)
                )
              end)
            else
              entry
            end
          end)
        end)
      end)
    end)
  end

  defp update_review(fx, fun) do
    path = Path.join(fx.dir, @review_manifest_rel)
    review = path |> File.read!() |> Jason.decode!() |> fun.()
    File.write!(path, Jason.encode!(review, pretty: true) <> "\n")
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

  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>

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
end
