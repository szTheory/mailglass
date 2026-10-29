defmodule MailglassAdmin.FeedbackLedgerTest do
  @moduledoc """
  UIQ-04 / D-08: the owner-feedback ledger in
  `reference/persona_spec/quick_view_scenarios.json` is checked by a
  phase-independent rule. Every row whose status is not `pending` must name
  scenarios (or carry the connected-real-route-only boundary) and an
  `evidence_pointer` that resolves to a real file and heading. No `owner_phase`
  value is consulted, so the rule survives phase archival.
  """

  use ExUnit.Case, async: true

  @moduletag :phase178

  alias MailglassAdmin.TestSupport.FeedbackLedger
  alias MailglassDemo.QuickViewScenarios

  @ledger_source Path.expand("../support/feedback_ledger.ex", __DIR__)

  @expected_row_ids ~w(
    fb-health-crowding
    fb-preview-reset
    fb-preview-identity
    fb-account-context
    fb-auto-apply-filters
    fb-quiet-quick-view-arrows
    fb-raw-source-hierarchy
    fb-suppression-refresh
    fb-inbound-addresses
    fb-storybook-fidelity
    fb-replay-review
    fb-technical-details
  )

  describe "real manifest" do
    test "Phase 178 ledger: every non-pending row satisfies the D-08 rule" do
      assert FeedbackLedger.rule_violations(
               QuickViewScenarios.feedback(),
               QuickViewScenarios.scenarios(),
               FeedbackLedger.repo_root()
             ) == []
    end

    test "Phase 178 ledger: the repo root contains the planning tree" do
      assert File.dir?(Path.join(FeedbackLedger.repo_root(), ".planning"))
    end

    test "Phase 178 ledger: the manifest keeps exactly the 12 rows in their current order (D-07)" do
      assert Enum.map(QuickViewScenarios.feedback(), & &1["id"]) == @expected_row_ids
    end

    test "Phase 178 ledger: every row links only to scenarios that link back" do
      assert FeedbackLedger.link_violations(
               QuickViewScenarios.feedback(),
               QuickViewScenarios.scenarios()
             ) == []
    end

    test "Phase 178 ledger: row ids are unique" do
      assert FeedbackLedger.duplicate_ids(QuickViewScenarios.feedback()) == []
    end

    test "Phase 178 ledger: the one open row is the partial fidelity row, so none can hide" do
      assert FeedbackLedger.open_rows(QuickViewScenarios.feedback()) == %{
               pending: [],
               partial: ["fb-storybook-fidelity"]
             }
    end

    test "Phase 178 ledger: the Preview rows are automated and link the preview-authoring scenarios both ways" do
      reset = row!("fb-preview-reset")
      identity = row!("fb-preview-identity")

      assert reset["status"] == "automated"
      assert identity["status"] == "automated"

      assert reset["scenario_ids"] == ~w(
               preview-authoring-typed-values preview-authoring-no-editable
               preview-authoring-field-error
             )

      assert identity["scenario_ids"] == ~w(
               preview-authoring-typed-values preview-authoring-long-unicode
               preview-authoring-duplicate-label
             )

      assert reset["evidence_pointer"] ==
               ".planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#preview-authoring-prvux-05-prvux-06"

      assert identity["evidence_pointer"] ==
               ".planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#readable-scenario-selector-prvux-07"

      for {row, ids} <- [{reset, reset["scenario_ids"]}, {identity, identity["scenario_ids"]}],
          id <- ids do
        assert row["id"] in scenario!(id)["feedback_ids"]
      end

      assert FeedbackLedger.rule_violations(
               [reset, identity],
               QuickViewScenarios.scenarios(),
               FeedbackLedger.repo_root()
             ) == []

      assert FeedbackLedger.link_violations(
               [reset, identity],
               QuickViewScenarios.scenarios()
             ) == []
    end

    test "Phase 178 ledger: every non-pending evidence pointer is path or path#anchor" do
      for row <- QuickViewScenarios.feedback(), row["status"] != "pending" do
        pointer = row["evidence_pointer"]

        refute String.match?(pointer, ~r/\s/), "#{row["id"]} pointer is prose: #{pointer}"
        assert length(String.split(pointer, "#")) in [1, 2], "#{row["id"]} has two anchors"
      end
    end

    test "Phase 178 ledger: the filters row is closed on its connected-only boundary" do
      row = row!("fb-auto-apply-filters")

      assert row["status"] == "automated"
      assert row["proof_boundary"] == "connected-real-route-only"
      assert row["scenario_ids"] == []
      assert row["disposition"] =~ "mailglass_admin/e2e/phase176-filters.spec.js"

      assert File.regular?(
               Path.join(
                 FeedbackLedger.repo_root(),
                 "mailglass_admin/e2e/phase176-filters.spec.js"
               )
             )

      other_boundary_rows =
        for r <- QuickViewScenarios.feedback(),
            r["id"] != row["id"],
            r["proof_boundary"],
            do: r["id"]

      assert other_boundary_rows == [], "only the filters row carries a feedback proof_boundary"
    end

    test "Phase 178 ledger: Inbound contact scenarios back-link fb-inbound-addresses" do
      contacts =
        ~w(normal-contacts long-local-part unicode spoofed-display-name many-recipients missing-headers unparseable)
        |> Enum.map(&"inbound-evidence-#{&1}")

      row = row!("fb-inbound-addresses")
      assert row["status"] == "automated"
      assert row["scenario_ids"] == contacts

      for id <- contacts do
        assert "fb-inbound-addresses" in scenario!(id)["feedback_ids"]
      end
    end

    test "Phase 178 ledger: raw-source scenarios back-link fb-raw-source-hierarchy" do
      evidence =
        ~w(unknown empty-revealed large-revealed denied)
        |> Enum.map(&"inbound-evidence-evidence-#{&1}")

      row = row!("fb-raw-source-hierarchy")
      assert row["status"] == "automated"
      assert row["scenario_ids"] == evidence

      for id <- evidence do
        assert "fb-raw-source-hierarchy" in scenario!(id)["feedback_ids"]
      end
    end

    test "Phase 178 ledger: the four fidelity scenarios keep both back-links" do
      for id <- ~w(qv-delivery-first qv-delivery-last qv-delivery-empty qv-inbound-empty) do
        assert scenario!(id)["feedback_ids"] == [
                 "fb-quiet-quick-view-arrows",
                 "fb-storybook-fidelity"
               ]
      end
    end
  end

  describe "detectors have teeth (fail-first proof)" do
    @scenarios [
      %{"id" => "s-one", "feedback_ids" => ["r-ok"]},
      %{"id" => "s-two", "feedback_ids" => []}
    ]

    test "Phase 178 ledger: a non-pending row with no scenarios and no boundary is flagged" do
      with_root(%{"docs/a.md" => "# A\n"}, fn root ->
        row = ledger_row("r-bare", "automated", [], "docs/a.md")

        assert FeedbackLedger.rule_violations([row], @scenarios, root) ==
                 [{"r-bare", :no_scenarios_and_no_boundary}]
      end)
    end

    test "Phase 178 ledger: empty scenario_ids are legal with the connected-only boundary" do
      with_root(%{"docs/a.md" => "# A\n"}, fn root ->
        row =
          "r-bound"
          |> ledger_row("automated", [], "docs/a.md")
          |> Map.put("proof_boundary", "connected-real-route-only")

        assert FeedbackLedger.rule_violations([row], @scenarios, root) == []
      end)
    end

    test "Phase 178 ledger: another proof_boundary value does not excuse empty scenario_ids" do
      with_root(%{"docs/a.md" => "# A\n"}, fn root ->
        row =
          "r-other"
          |> ledger_row("resolved", [], "docs/a.md")
          |> Map.put("proof_boundary", "story-render-only")

        assert FeedbackLedger.rule_violations([row], @scenarios, root) ==
                 [{"r-other", :no_scenarios_and_no_boundary}]
      end)
    end

    test "Phase 178 ledger: an unresolvable path is flagged" do
      with_root(%{}, fn root ->
        row = ledger_row("r-gone", "automated", ["s-one"], "docs/missing.md")

        assert FeedbackLedger.rule_violations([row], @scenarios, root) ==
                 [{"r-gone", {:pointer, :missing}}]
      end)
    end

    test "Phase 178 ledger: a bad anchor on an existing file is flagged" do
      with_root(%{"docs/a.md" => "# A\n\n## Real heading\n"}, fn root ->
        bad = ledger_row("r-anchor", "automated", ["s-one"], "docs/a.md#no-such-heading")
        good = ledger_row("r-fine", "automated", ["s-one"], "docs/a.md#real-heading")

        assert FeedbackLedger.rule_violations([bad, good], @scenarios, root) ==
                 [{"r-anchor", {:pointer, {:anchor_not_found, "no-such-heading"}}}]
      end)
    end

    test "Phase 178 ledger: a prose pointer is flagged" do
      with_root(%{}, fn root ->
        row = ledger_row("r-prose", "resolved", ["s-one"], "Pending Phase 178 evidence.")

        assert FeedbackLedger.rule_violations([row], @scenarios, root) ==
                 [{"r-prose", {:pointer, :prose_pointer}}]
      end)
    end

    test "Phase 178 ledger: a scenario id that does not exist is flagged" do
      with_root(%{"docs/a.md" => "# A\n"}, fn root ->
        row = ledger_row("r-ghost", "automated", ["s-one", "s-ghost"], "docs/a.md")

        assert FeedbackLedger.rule_violations([row], @scenarios, root) ==
                 [{"r-ghost", {:unknown_scenario, "s-ghost"}}]
      end)
    end

    test "Phase 178 ledger: a pending row is ignored by the rule but listed as open" do
      with_root(%{}, fn root ->
        pending = ledger_row("r-open", "pending", [], "Pending Phase 178 evidence.")
        partial = ledger_row("r-half", "partial", ["s-one"], "docs/missing.md")

        assert FeedbackLedger.rule_violations([pending], @scenarios, root) == []
        assert FeedbackLedger.rule_violations([partial], @scenarios, root) != []

        assert FeedbackLedger.open_rows([
                 pending,
                 partial,
                 ledger_row("r-done", "automated", [], "x")
               ]) ==
                 %{pending: ["r-open"], partial: ["r-half"]}
      end)
    end

    test "Phase 178 ledger: the rule does not look at owner_phase" do
      with_root(%{"docs/a.md" => "# A\n"}, fn root ->
        for phase <- ["174", "178", "999", nil] do
          row =
            "r-phase"
            |> ledger_row("automated", [], "docs/a.md")
            |> Map.put("owner_phase", phase)

          assert FeedbackLedger.rule_violations([row], @scenarios, root) ==
                   [{"r-phase", :no_scenarios_and_no_boundary}]
        end
      end)
    end

    test "Phase 178 ledger: a phases pointer resolves from a milestone archive alone" do
      files = %{
        ".planning/milestones/v9.9-phases/777-demo/777-VERIFICATION.md" =>
          "# V\n\n## Truths (A)\n"
      }

      with_root(files, fn root ->
        assert {:ok, path} =
                 FeedbackLedger.resolve_pointer(
                   ".planning/phases/777-demo/777-VERIFICATION.md#truths-a",
                   root
                 )

        assert path ==
                 Path.join(root, ".planning/milestones/v9.9-phases/777-demo/777-VERIFICATION.md")
      end)
    end

    test "Phase 178 ledger: a phases pointer present in the live tree and an archive is ambiguous" do
      files = %{
        ".planning/phases/777-demo/777-VERIFICATION.md" => "# V\n",
        ".planning/milestones/v9.9-phases/777-demo/777-VERIFICATION.md" => "# V\n"
      }

      with_root(files, fn root ->
        assert FeedbackLedger.resolve_pointer(
                 ".planning/phases/777-demo/777-VERIFICATION.md",
                 root
               ) ==
                 {:error, :ambiguous}
      end)
    end

    test "Phase 178 ledger: a phases pointer present in two archives is ambiguous, in none is missing" do
      files = %{
        ".planning/milestones/v8.0-phases/777-demo/777-VERIFICATION.md" => "# V\n",
        ".planning/milestones/v9.9-phases/777-demo/777-VERIFICATION.md" => "# V\n"
      }

      with_root(files, fn root ->
        assert FeedbackLedger.resolve_pointer(
                 ".planning/phases/777-demo/777-VERIFICATION.md",
                 root
               ) ==
                 {:error, :ambiguous}

        assert FeedbackLedger.resolve_pointer(
                 ".planning/phases/888-none/888-VERIFICATION.md",
                 root
               ) ==
                 {:error, :missing}
      end)
    end

    test "Phase 178 ledger: a live phases pointer resolves when no archive holds it" do
      with_root(%{".planning/phases/777-demo/777-VERIFICATION.md" => "# V\n"}, fn root ->
        assert {:ok, path} =
                 FeedbackLedger.resolve_pointer(
                   ".planning/phases/777-demo/777-VERIFICATION.md",
                   root
                 )

        assert path == Path.join(root, ".planning/phases/777-demo/777-VERIFICATION.md")
      end)
    end

    test "Phase 178 ledger: absolute, traversing and glob-shaped pointers are rejected" do
      with_root(%{"docs/a.md" => "# A\n"}, fn root ->
        for pointer <- ["../../etc/hosts", "docs/../../etc/hosts", "/etc/hosts"] do
          assert FeedbackLedger.resolve_pointer(pointer, root) == {:error, :outside_repo},
                 "#{pointer} was not rejected as outside the repo"
        end

        assert FeedbackLedger.resolve_pointer("docs/*.md", root) == {:error, :invalid_path}

        assert FeedbackLedger.resolve_pointer(".planning/phases/*/x.md", root) ==
                 {:error, :invalid_path}
      end)
    end

    test "Phase 178 ledger: empty and non-string pointers are rejected" do
      with_root(%{}, fn root ->
        for pointer <- [nil, "", 42] do
          assert FeedbackLedger.resolve_pointer(pointer, root) == {:error, :empty_pointer}
        end

        assert FeedbackLedger.resolve_pointer("#only-an-anchor", root) == {:error, :empty_path}
      end)
    end

    test "Phase 178 ledger: anchors follow GitHub slugs, repeats and fences" do
      body = """
      # Title

      ## Health composition (OUTUX-06)

      ## Account scope and Preview return (UXF-09, UXF-10)

      ## Repeat

      ## Repeat

      ```
      ## Hidden in a fence
      ```
      """

      with_root(%{"docs/a.md" => body}, fn root ->
        for anchor <-
              ~w(title health-composition-outux-06 account-scope-and-preview-return-uxf-09-uxf-10 repeat repeat-1) do
          assert {:ok, _} = FeedbackLedger.resolve_pointer("docs/a.md##{anchor}", root),
                 "#{anchor} should resolve"
        end

        for anchor <- ["hidden-in-a-fence", "repeat-2", "Title"] do
          assert {:error, {:anchor_not_found, ^anchor}} =
                   FeedbackLedger.resolve_pointer("docs/a.md##{anchor}", root)
        end

        assert FeedbackLedger.resolve_pointer("docs/a.md#", root) == {:error, :empty_anchor}
      end)
    end

    test "Phase 178 ledger: slug/1 keeps Unicode letters and drops punctuation" do
      assert FeedbackLedger.slug("Health composition (OUTUX-06)") == "health-composition-outux-06"
      assert FeedbackLedger.slug("  Zażółć gęślą_jaźń! ") == "zażółć-gęślą_jaźń"
      assert FeedbackLedger.slug("A `code` & B") == "a-code--b"
    end

    test "Phase 178 ledger: a row listing a scenario that does not back-link it is flagged" do
      rows = [
        ledger_row("r-ok", "automated", ["s-one"], "x"),
        ledger_row("r-nolink", "automated", ["s-two"], "x"),
        ledger_row("r-ghost", "automated", ["s-ghost"], "x"),
        ledger_row("r-none", "pending", [], "x")
      ]

      assert FeedbackLedger.link_violations(rows, @scenarios) == [
               {"r-nolink", {:missing_backlink, "s-two"}},
               {"r-ghost", {:unknown_scenario, "s-ghost"}}
             ]
    end

    test "Phase 178 ledger: duplicate row ids are flagged once each" do
      rows =
        for id <- ~w(a b a c a b), do: ledger_row(id, "automated", [], "x")

      assert FeedbackLedger.duplicate_ids(rows) == ["a", "b"]
      assert FeedbackLedger.duplicate_ids(Enum.take(rows, 3) |> Enum.take(-2)) == []
    end
  end

  describe "STORY-07 accounting" do
    test "Phase 178 accounting: a row whose only scenario is unrendered with no boundary reports zero stories and is flagged" do
      rows = [
        %{"id" => "r-none", "owner_requirements" => ["X-1"], "scenario_ids" => ["s-ghost"]},
        %{"id" => "r-ok", "owner_requirements" => ["X-2"], "scenario_ids" => ["s-story"]},
        %{
          "id" => "r-conn",
          "owner_requirements" => ["X-3"],
          "scenario_ids" => [],
          "proof_boundary" => "connected-real-route-only"
        }
      ]

      scenarios = [
        %{"id" => "s-ghost", "rendered" => false, "story_path" => nil},
        %{"id" => "s-story", "rendered" => true, "story_path" => "/dev/storybook/x"}
      ]

      accounting = FeedbackLedger.story_accounting(rows, scenarios)

      assert [
               %{id: "r-none", stories: 0, unrendered_linked: 1},
               %{id: "r-ok", stories: 1, unrendered_linked: 0},
               %{id: "r-conn", stories: 0, unrendered_linked: 0}
             ] = accounting

      assert FeedbackLedger.story_accounting_violations(accounting) == [
               {"r-none", :no_story_and_no_boundary}
             ]
    end

    test "Phase 178 accounting: every real row has a story or the connected-only boundary, and only filters has none" do
      accounting =
        FeedbackLedger.story_accounting(
          QuickViewScenarios.feedback(),
          QuickViewScenarios.scenarios()
        )

      assert length(accounting) == 12
      assert FeedbackLedger.story_accounting_violations(accounting) == []

      assert for(%{stories: 0, id: id} <- accounting, do: id) == ["fb-auto-apply-filters"]

      assert Enum.all?(
               accounting,
               &(&1.stories >= 1 or &1.boundary =~ "connected-real-route-only")
             )
    end

    test "Phase 178 accounting: the Preview rows count their three authoring stories each" do
      by_id =
        Map.new(
          FeedbackLedger.story_accounting(
            QuickViewScenarios.feedback(),
            QuickViewScenarios.scenarios()
          ),
          &{&1.id, &1}
        )

      assert %{stories: 3, unrendered_linked: 0, boundary: "story-render-only"} =
               by_id["fb-preview-reset"]

      assert %{stories: 3, unrendered_linked: 0, boundary: "story-render-only"} =
               by_id["fb-preview-identity"]
    end

    test "Phase 178 accounting: unrendered_linked_scenarios keeps linked non-stories and omits the rest" do
      rows = [
        %{"id" => "r-a", "scenario_ids" => ["s-unrendered", "s-nopath", "s-story"]},
        %{"id" => "r-b", "scenario_ids" => ["s-unrendered"]}
      ]

      scenarios = [
        %{
          "id" => "s-unrendered",
          "rendered" => false,
          "story_path" => nil,
          "proof_boundary" => "connected-real-route-only",
          "feedback_ids" => ["r-a", "r-b"]
        },
        %{
          "id" => "s-nopath",
          "rendered" => true,
          "story_path" => nil,
          "proof_boundary" => "story-render-only",
          "feedback_ids" => ["r-a"]
        },
        %{
          "id" => "s-story",
          "rendered" => true,
          "story_path" => "/dev/storybook/x",
          "proof_boundary" => "story-render-only",
          "feedback_ids" => ["r-a"]
        },
        %{
          "id" => "s-unlinked",
          "rendered" => false,
          "story_path" => nil,
          "proof_boundary" => "connected-real-route-only",
          "feedback_ids" => []
        },
        %{
          "id" => "s-self-linked",
          "rendered" => false,
          "story_path" => "",
          "proof_boundary" => "connected-real-route-only",
          "feedback_ids" => ["r-other"]
        }
      ]

      assert FeedbackLedger.unrendered_linked_scenarios(rows, scenarios) == [
               %{
                 scenario_id: "s-nopath",
                 feedback_ids: ["r-a"],
                 rendered: true,
                 story_path: nil,
                 proof_boundary: "story-render-only"
               },
               %{
                 scenario_id: "s-self-linked",
                 feedback_ids: ["r-other"],
                 rendered: false,
                 story_path: "",
                 proof_boundary: "connected-real-route-only"
               },
               %{
                 scenario_id: "s-unrendered",
                 feedback_ids: ["r-a", "r-b"],
                 rendered: false,
                 story_path: nil,
                 proof_boundary: "connected-real-route-only"
               }
             ]

      assert [%{id: "r-a", stories: 1, unrendered_linked: 2}, %{id: "r-b", unrendered_linked: 1}] =
               FeedbackLedger.story_accounting(rows, scenarios)
    end

    test "Phase 178 accounting: a linked non-story with an empty boundary is flagged" do
      entries = [
        %{scenario_id: "ok", proof_boundary: "connected-real-route-only"},
        %{scenario_id: "blank", proof_boundary: ""},
        %{scenario_id: "missing", proof_boundary: nil}
      ]

      assert FeedbackLedger.boundary_violations(entries) == [
               {"blank", :empty_boundary},
               {"missing", :empty_boundary}
             ]
    end

    test "Phase 178 accounting: on the real manifest every linked non-story carries a boundary" do
      entries =
        FeedbackLedger.unrendered_linked_scenarios(
          QuickViewScenarios.feedback(),
          QuickViewScenarios.scenarios()
        )

      assert FeedbackLedger.boundary_violations(entries) == []
      assert Enum.all?(entries, &(&1.proof_boundary == "connected-real-route-only"))
      assert Enum.all?(entries, &(&1.rendered != true or &1.story_path in [nil, ""]))
    end

    test "Phase 178 accounting: the Retained stories table equals the computed accounting row for row" do
      assert FeedbackLedger.accounting_doc_violations(
               automation_doc(),
               QuickViewScenarios.feedback(),
               QuickViewScenarios.scenarios()
             ) == []
    end

    test "Phase 178 accounting: the doc names the Phase 175 Delivery path and its agreement tests" do
      doc = automation_doc()

      assert doc =~ "Phase 175 Northstar and Fjordline facts match scoped Delivery projections"
      assert doc =~ "Fjordline Delivery pure facts match the tenant-scoped production projection"
      assert doc =~ "delivery-investigation-"
      assert doc =~ "pure-only (story-render-only)"
      assert doc =~ "mailglass_admin/e2e/phase176-filters.spec.js"

      projection_test = File.read!(Path.expand("quick_view_projection_test.exs", __DIR__))

      assert projection_test =~
               "Phase 175 Northstar and Fjordline facts match scoped Delivery projections"

      assert projection_test =~
               "Fjordline Delivery pure facts match the tenant-scoped production projection"
    end

    test "Phase 178 accounting: editing a count, dropping or adding a row in a fixture copy of the doc fails" do
      rows = QuickViewScenarios.feedback()
      scenarios = QuickViewScenarios.scenarios()
      doc = automation_doc()

      [first_row | _] = FeedbackLedger.accounting_table_rows(rows, scenarios)
      [id, reqs, stories | rest] = first_row
      original = "| " <> Enum.join(first_row, " | ") <> " |"
      assert doc =~ original

      edited_count = "| " <> Enum.join([id, reqs, "99" | rest], " | ") <> " |"
      refute stories == "99"

      assert [{:accounting_missing_row, ^first_row} | _] =
               FeedbackLedger.accounting_doc_violations(
                 String.replace(doc, original, edited_count),
                 rows,
                 scenarios
               )

      assert FeedbackLedger.accounting_doc_violations(
               String.replace(doc, original <> "\n", ""),
               rows,
               scenarios
             ) != []

      extra = "| fb-invented | X-1 | 1 | 0 | story-render-only |\n"

      assert Enum.any?(
               FeedbackLedger.accounting_doc_violations(
                 String.replace(doc, original <> "\n", original <> "\n" <> extra),
                 rows,
                 scenarios
               ),
               &match?({:accounting_extra_row, ["fb-invented" | _]}, &1)
             )

      assert FeedbackLedger.accounting_doc_violations("# nothing here\n", rows, scenarios) != []
    end

    test "Phase 178 accounting: swapping two table rows in a fixture copy of the doc fails" do
      rows = QuickViewScenarios.feedback()
      scenarios = QuickViewScenarios.scenarios()
      doc = automation_doc()

      [first, second | _] =
        for cells <- FeedbackLedger.accounting_table_rows(rows, scenarios),
            do: "| " <> Enum.join(cells, " | ") <> " |"

      swapped = String.replace(doc, first <> "\n" <> second, second <> "\n" <> first)
      refute swapped == doc

      assert [{:accounting_row_order, _body}] =
               FeedbackLedger.accounting_doc_violations(swapped, rows, scenarios)
    end

    test "Phase 178 accounting: the Linked scenarios table equals the manifest and fails when it drifts" do
      rows = QuickViewScenarios.feedback()
      scenarios = QuickViewScenarios.scenarios()
      doc = automation_doc()

      [first | _] = FeedbackLedger.linked_table_rows(rows, scenarios)
      line = "| " <> Enum.join(first, " | ") <> " |"
      assert doc =~ line

      assert [{:linked_missing_row, ^first} | _] =
               FeedbackLedger.accounting_doc_violations(
                 String.replace(doc, line <> "\n", ""),
                 rows,
                 scenarios
               )

      extra = "| qv-invented | fb-x | false | null | connected-real-route-only |\n"

      assert Enum.any?(
               FeedbackLedger.accounting_doc_violations(
                 String.replace(doc, line <> "\n", line <> "\n" <> extra),
                 rows,
                 scenarios
               ),
               &match?({:linked_extra_row, ["qv-invented" | _]}, &1)
             )

      stale_count =
        String.replace(
          doc,
          ~r/^Linked scenarios without a story render: \d+$/m,
          "Linked scenarios without a story render: 99"
        )

      assert {:linked_count, 99} in FeedbackLedger.accounting_doc_violations(
               stale_count,
               rows,
               scenarios
             )
    end

    test "Phase 178 accounting: the table parser reads the first table under a heading only" do
      markdown = """
      ## Section

      intro

      | A | B |
      | --- | --- |
      | 1 | two words |
      | 3 | 4 |

      ### Sub

      | C |
      | - |
      | z |
      """

      assert FeedbackLedger.table_after(markdown, "## Section") ==
               {:ok, ["A", "B"], [["1", "two words"], ["3", "4"]]}

      assert FeedbackLedger.table_after(markdown, "### Sub") == {:ok, ["C"], [["z"]]}
      assert FeedbackLedger.table_after(markdown, "## Absent") == {:error, :heading_not_found}

      assert FeedbackLedger.table_after("## Section\n\ntext only\n", "## Section") ==
               {:error, :table_not_found}
    end
  end

  describe "no phase coupling" do
    test "Phase 178 ledger: the rule functions do not reference owner_phase" do
      source = File.read!(@ledger_source)

      refute references_owner_phase?(source),
             "FeedbackLedger must not consult owner_phase (D-08 phase independence)"
    end

    test "Phase 178 ledger: the owner_phase scan has teeth" do
      assert references_owner_phase?(~s|Enum.filter(rows, &(&1["owner_phase"] == "178"))|)
      assert references_owner_phase?(~s|row.owner_phase|)
      refute references_owner_phase?(~s|row["status"] == "pending"|)
    end
  end

  # The automation record may sit in the live phase directory or, once the
  # milestone is archived, in exactly one archive; resolve it the same way the
  # ledger resolves evidence pointers.
  defp automation_doc do
    pointer = ".planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md"
    assert {:ok, file} = FeedbackLedger.resolve_pointer(pointer, FeedbackLedger.repo_root())
    File.read!(file)
  end

  defp references_owner_phase?(source), do: String.contains?(source, "owner_phase")

  defp row!(id),
    do: Enum.find(QuickViewScenarios.feedback(), &(&1["id"] == id)) || flunk("no row #{id}")

  defp scenario!(id),
    do: Enum.find(QuickViewScenarios.scenarios(), &(&1["id"] == id)) || flunk("no scenario #{id}")

  defp ledger_row(id, status, scenario_ids, pointer) do
    %{
      "id" => id,
      "status" => status,
      "scenario_ids" => scenario_ids,
      "evidence_pointer" => pointer,
      "owner_phase" => "178"
    }
  end

  # Builds a throwaway repository root under the system temp dir, runs `fun`
  # with it, and removes the directory this test created.
  defp with_root(files, fun) do
    root = Path.join(System.tmp_dir!(), "feedback-ledger-#{System.unique_integer([:positive])}")

    try do
      for {relative, content} <- files do
        path = Path.join(root, relative)
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, content)
      end

      File.mkdir_p!(root)
      fun.(root)
    after
      File.rm_rf!(root)
    end
  end
end
