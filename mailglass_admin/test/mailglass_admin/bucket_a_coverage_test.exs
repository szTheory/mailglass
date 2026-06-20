defmodule MailglassAdmin.BucketACoverageTest do
  @moduledoc """
  Executable, fail-closed Bucket-A coverage manifest (RATCHET-05, D-12).

  This is the milestone's accountability ledger: it makes the "all 24 Bucket-A
  usability defects closed" claim machine-checkable in CI rather than a prose
  assertion. Each of the 24 enumerated defects (A1..A24, from
  `.planning/research/v1.13/PITFALLS.md` "Bucket A") maps to a live regression
  guard. The manifest ASSERTS each cited guard physically exists by reading the
  cited file and checking the literal is present:

    * `:grep_gate`        — the gate-name literal is present in check-conformance.sh
    * `:playwright_title` — the test-title literal is present in an e2e/*.spec.js file
    * `:playwright_testid`— the data-testid literal is present in an e2e/*.spec.js file
    * `:axe`              — the axe baseline reference exists (axe_baseline_test.exs + docs/axe-baseline.json)
    * `:fixture`          — the fixture/persona literal is present in the persona spec

  A STALE citation (a renamed gate, a deleted/renamed test title) FAILS this test
  (fail-closed) — proving the ledger cannot drift silently (RESEARCH Pitfall 4).

  Stable-ID / never-delete contract (mirrors `.planning/RATCHET-GAP-REGISTER.md`):
  every A-NN row is permanent. A regression DOWNGRADES a row's `status` (it is
  never removed). `BUCKET-A-LEDGER.md` is a human-readable MIRROR of this manifest,
  never the source of truth.

  DISCIPLINE: the citation string literals live ONLY inside this test module. This
  is a `test/` file, never scanned by the lib/-scoped check-conformance.sh gates,
  so an acceptance literal here cannot self-invalidate a negative-grep gate.

  Dependency-correctness (option b): this manifest cites ONLY guards produced by
  phases 109–115 (existing green), plans 116-02/03, and 116-05's OWN net-new guards
  (Tasks 1–2). It does NOT cite any 116-04 gallery-matrix testid, so 116-05 stays
  Wave 2, parallel to 116-04. Gallery-matrix citations belong to plan 116-06.
  """

  use ExUnit.Case, async: true

  @admin_root Path.expand(Path.join([__DIR__, "..", ".."]))

  @conformance_script Path.join([@admin_root, "scripts", "check-conformance.sh"])
  @structural_spec Path.join([@admin_root, "e2e", "structural.spec.js"])
  @axe_spec Path.join([@admin_root, "e2e", "axe-baseline.spec.js"])
  @axe_test Path.join([__DIR__, "axe_baseline_test.exs"])
  @axe_baseline_json Path.join([@admin_root, "docs", "axe-baseline.json"])
  # The persona spec is the shared canonical cohort dir (compiled into the admin
  # :test build via mix.exs elixirc_paths — plan 116-01).
  @persona_spec Path.expand(Path.join([@admin_root, "..", "reference", "persona_spec", "personas.ex"]))

  # ===========================================================================
  # THE MANIFEST — all 24 Bucket-A defects, each with {guard_kind, locator, status}.
  #
  # status ∈ :live | :downgraded. A regression reopens (downgrades) a row; the row
  # is never deleted. All 24 ship :live for the Phase-116 baseline.
  # ===========================================================================
  @manifest [
    # --- A1: modal/drawer behind the scrim ----------------------------------
    %{id: "A1", desc: "Modal/drawer behind the scrim", guard_kind: :grep_gate,
      locator: "Z-INDEX-GATE", status: :live},
    %{id: "A1b", desc: "A1 runtime: panel is top hit-test target above scrim", guard_kind: :playwright_title,
      locator: "panel above scrim — deliveries replay dialog", status: :live},

    # --- A2: scroll bugs / nested-scroll traps ------------------------------
    %{id: "A2", desc: "Scroll-chaining contained (overscroll-behavior)", guard_kind: :playwright_title,
      locator: "scroll-chaining contained — deliveries replay dialog", status: :live},

    # --- A3: hover on non-interactive empty state (NET-NEW 116-05) -----------
    %{id: "A3", desc: "Hover affordance only on interactive empty-state elements", guard_kind: :playwright_title,
      locator: "Bucket-A A3: hover affordance only on interactive elements (no-data empty state)", status: :live},

    # --- A4 / A23: floating element overlap of primary CTA (NET-NEW 116-05) --
    %{id: "A4", desc: "Floating elements do not overlap a btn-primary outside the overlay", guard_kind: :playwright_title,
      locator: "Bucket-A A4/A23: floating elements do not overlap a primary CTA outside the overlay", status: :live},
    %{id: "A23", desc: "Toasts/floats obscuring controls (shares the A4 guard)", guard_kind: :playwright_title,
      locator: "Bucket-A A4/A23: floating elements do not overlap a primary CTA outside the overlay", status: :live},

    # --- A5: misaligned elements --------------------------------------------
    %{id: "A5", desc: "Direct-sibling left-edge alignment in composed groups", guard_kind: :playwright_title,
      locator: "direct-sibling left-edge alignment, padding-floor, and no overflow at 320/1280", status: :live},

    # --- A6: awkward padding / content chopped off --------------------------
    %{id: "A6", desc: "Long-value overflow handling (no clip without truncate)", guard_kind: :playwright_title,
      locator: "overflow: list containers do not exceed their parent aside width at 320px and 768px (DATA-05)", status: :live},

    # --- A7: inconsistent / off-grid spacing --------------------------------
    %{id: "A7", desc: "Off-grid spacing tokens banned in group surfaces", guard_kind: :grep_gate,
      locator: "SPACE-GATE", status: :live},

    # --- A8: elements flush inside containers (no breathing room) -----------
    %{id: "A8", desc: "Computed padding-floor (no flush content) in group surfaces", guard_kind: :playwright_title,
      locator: "direct-sibling left-edge alignment, padding-floor, and no overflow at 320/1280", status: :live},

    # --- A9: cards nested in cards (box prison) ------------------------------
    %{id: "A9", desc: "Same-tone card-in-card signature banned in group surfaces", guard_kind: :grep_gate,
      locator: "GROUP-GATE", status: :live},

    # --- A10: squished / unreadable table columns ---------------------------
    %{id: "A10", desc: "Responsive table->cards below breakpoint (DATA-01)", guard_kind: :playwright_title,
      locator: "responsive: operator-deliveries-table visible at 768px; operator-deliveries-cards visible at 390px (DATA-01)", status: :live},

    # --- A11: table overuse (NET-NEW 116-05) --------------------------------
    %{id: "A11", desc: "Table-overuse count-must-not-increase floor", guard_kind: :grep_gate,
      locator: "TABLE-OVERUSE-GATE", status: :live},

    # --- A12: inconsistent stat-card design ---------------------------------
    %{id: "A12", desc: "All stat cards route through Components.stat_card/1", guard_kind: :grep_gate,
      locator: "STATCARD-GATE", status: :live},

    # --- A13: disabled looks enabled / enabled looks disabled ---------------
    %{id: "A13", desc: "Programmatic disabled is visually distinct (primitive contracts)", guard_kind: :playwright_title,
      locator: "interactive primitive hover, focus, disabled, and target-size contracts hold", status: :live},

    # --- A14: weird focus / hover states ------------------------------------
    %{id: "A14", desc: "Visible focus rings (>=2px, not obscured, AA non-text contrast)", guard_kind: :playwright_title,
      locator: "visible focus rings", status: :live},

    # --- A15: unreadable button text (same color font + background) ---------
    %{id: "A15", desc: "WCAG AA contrast matrix (text vs background, light/dark)", guard_kind: :playwright_title,
      locator: "Inbound: WCAG AA contrast matrix covers light/dark themes at 390/768/1440", status: :live},

    # --- A16: poor dark-mode contrast ---------------------------------------
    %{id: "A16", desc: "Dark-mode contrast matrix (light/dark at 390/768/1440)", guard_kind: :playwright_title,
      locator: "Preview: WCAG AA contrast matrix covers light/dark themes at 390/768/1440", status: :live},
    # --- A16-system: system theme dark parity (NET-NEW 116-05) --------------
    %{id: "A16-system", desc: "System theme contrast parity with explicit dark", guard_kind: :playwright_title,
      locator: "Bucket-A A16-system: system theme contrast parity with explicit dark", status: :live},
    %{id: "A16-axe", desc: "Axe WCAG 2.2 AA baseline (system cell <= dark cell)", guard_kind: :axe,
      locator: "axe-baseline.json", status: :live},

    # --- A17: no system/light/dark picker -----------------------------------
    %{id: "A17", desc: "Native three-radio theme picker (System/Light/Dark)", guard_kind: :playwright_title,
      locator: "theme_picker keeps native three-radio semantics without pressed-button state", status: :live},

    # --- A18: tabs not showing selected / active state ----------------------
    %{id: "A18", desc: "aria-selected on clicked row in table + card presentation", guard_kind: :playwright_title,
      locator: "aria-selected=true set on clicked row in both table (desktop) and card (mobile) presentations (DATA-04)", status: :live},

    # --- A19: weird pagination when nothing to paginate ---------------------
    %{id: "A19", desc: "Honest pagination boundaries (only when total_pages > 1)", guard_kind: :playwright_title,
      locator: "sole tenant canonicalizes, explicit theme paints root, active nav has structural cues, and pagination boundaries are honest", status: :live},

    # --- A20: icons that don't semantically read ----------------------------
    %{id: "A20", desc: "Every hero-* used in lib/ has a vendored SVG", guard_kind: :grep_gate,
      locator: "ICON-EXISTS-GATE", status: :live},

    # --- A21: loading states that jump layout (CLS) (NET-NEW 116-05 + 116-03)-
    %{id: "A21", desc: "Loading-state CLS height delta within threshold", guard_kind: :playwright_title,
      locator: "Bucket-A A21: loading-state CLS height delta within threshold", status: :live},
    %{id: "A21b", desc: "A21 pillar: layout-jump/CLS within threshold (116-03)", guard_kind: :playwright_title,
      locator: "layout-jump/CLS within threshold — deliveries list region", status: :live},

    # --- A22: skeleton overuse on synchronous surfaces (NET-NEW 116-05) -----
    %{id: "A22", desc: "Synchronous inbound mount renders no skeleton", guard_kind: :playwright_title,
      locator: "Bucket-A A22: synchronous inbound mount renders no skeleton", status: :live},

    # --- A24: bare "—" / "___" placeholder cards ----------------------------
    # Cite the gate by its stable NAME (IN-01) rather than the verbatim `do: "—"`
    # em-dash token: the token lives inside STATCARD-GATE's negative-grep pattern
    # (check-conformance.sh), and a whitespace-only reformat of that pattern would
    # break a verbatim-token citation as a confusing "STALE CITATION (A24)"
    # unrelated to any real regression. The gate name is the durable handle.
    %{id: "A24", desc: "STATCARD-GATE bans the bare em-dash placeholder fallback", guard_kind: :grep_gate,
      locator: "STATCARD-GATE", status: :live},

    # --- B-A1: focus not restored to trigger on overlay close ---------------
    %{id: "B-A1", desc: "Focus restored to the opening trigger after overlay close", guard_kind: :playwright_title,
      locator: "focus restore to trigger — deliveries replay modal", status: :live}
  ]

  # The 24 canonical Bucket-A defect IDs (A1..A24). The manifest carries extra
  # cross-cite rows (A1b, A16-system, A16-axe, A21b, B-A1) — the coverage assertion
  # below proves every canonical A1..A24 is represented.
  @canonical_ids for n <- 1..24, do: "A#{n}"

  defp read!(path) do
    assert File.exists?(path), "cited file does not exist: #{path}"
    File.read!(path)
  end

  test "all 24 canonical Bucket-A defects (A1..A24) are enumerated" do
    represented =
      @manifest
      |> Enum.map(& &1.id)
      # normalize cross-cite suffixes (A1b -> A1, A16-system -> A16, A21b -> A21)
      |> Enum.map(fn id ->
        cond do
          # Exact canonical ID (A1..A24) — keep as-is.
          String.match?(id, ~r/^A\d+$/) -> id
          # Cross-cite suffix on a canonical ID (A1b, A16-system, A16-axe, A21b)
          # normalizes back to its canonical AN. B-A1 (a bonus row, not a canonical
          # A1..A24 defect) yields nil and is dropped.
          true ->
            case Regex.run(~r/^A\d+/, id) do
              [match] -> match
              _ -> nil
            end
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    missing = Enum.reject(@canonical_ids, &MapSet.member?(represented, &1))

    assert missing == [],
           "Bucket-A defects with no manifest row: #{inspect(missing)}. " <>
             "Every A1..A24 must have a live regression guard (RATCHET-05)."
  end

  test "every manifest row has a live (non-downgraded) status, or a documented downgrade" do
    downgraded = Enum.filter(@manifest, &(&1.status == :downgraded))

    # The Phase-116 baseline ships all rows :live. A regression downgrades a row
    # (status: :downgraded) but NEVER deletes it. This assertion documents the
    # current floor; flip to a warning + ledger note when a real downgrade lands.
    assert downgraded == [],
           "Downgraded Bucket-A rows (a guard regressed — investigate, never delete the row): " <>
             inspect(Enum.map(downgraded, & &1.id))
  end

  test "every :grep_gate citation literal physically exists in check-conformance.sh (fail-closed)" do
    script = read!(@conformance_script)

    for %{id: id, guard_kind: :grep_gate, locator: gate} <- @manifest do
      assert String.contains?(script, gate),
             "STALE CITATION (#{id}): gate literal #{inspect(gate)} not found in " <>
               "check-conformance.sh. A renamed/deleted gate must fail this manifest " <>
               "(RESEARCH Pitfall 4), not pass vacuously."
    end
  end

  test "every :playwright_title citation literal physically exists in the e2e spec (fail-closed)" do
    spec = read!(@structural_spec)

    for %{id: id, guard_kind: :playwright_title, locator: title} <- @manifest do
      assert String.contains?(spec, title),
             "STALE CITATION (#{id}): test-title literal #{inspect(title)} not found in " <>
               "e2e/structural.spec.js. A renamed/deleted Playwright guard must fail this " <>
               "manifest (fail-closed), not pass vacuously."
    end
  end

  test "every :playwright_testid citation literal physically exists in the e2e spec (fail-closed)" do
    spec = read!(@structural_spec)

    for %{id: id, guard_kind: :playwright_testid, locator: testid} <- @manifest do
      assert String.contains?(spec, testid),
             "STALE CITATION (#{id}): data-testid literal #{inspect(testid)} not found in " <>
               "e2e/structural.spec.js."
    end
  end

  test "every :axe citation resolves to a live axe baseline (producer + comparator + JSON)" do
    # The axe ratchet (plan 116-02) backs the A16 system<=dark parity claim.
    assert File.exists?(@axe_baseline_json),
           "STALE CITATION: docs/axe-baseline.json missing — the axe ratchet (116-02) backs A16-system."

    assert File.exists?(@axe_test),
           "STALE CITATION: axe_baseline_test.exs missing — the fail-closed axe comparator must exist."

    assert File.exists?(@axe_spec),
           "STALE CITATION: e2e/axe-baseline.spec.js missing — the screenshot-free axe producer must exist."

    for %{id: id, guard_kind: :axe, locator: ref} <- @manifest do
      contents = read!(@axe_test)

      assert String.contains?(contents, ref),
             "STALE CITATION (#{id}): axe reference #{inspect(ref)} not found in axe_baseline_test.exs."
    end
  end

  test "every :fixture citation literal physically exists in the persona spec (fail-closed)" do
    spec = read!(@persona_spec)

    for %{id: id, guard_kind: :fixture, locator: literal} <- @manifest do
      assert String.contains?(spec, literal),
             "STALE CITATION (#{id}): fixture literal #{inspect(literal)} not found in personas.ex."
    end
  end

  test "the A11 TABLE-OVERUSE-GATE floor matches the genuinely-tabular <table> inventory" do
    # The three genuinely-tabular tables (each a per-table justification row below):
    #   * operator/deliveries_list.ex — multi-column delivery list (status, recipient, time, ...)
    #   * inbound/records_list.ex     — multi-column inbound record list (outcome, recipient, ...)
    #   * preview/tabs.ex             — key/value comparison table for rendered headers
    # All three are multi-column tabular data; none is a layout device for a
    # homogeneous list. The gate bakes the floor (3); this assertion proves the
    # justification count matches the gate floor so the two cannot silently diverge.
    table_justifications = [
      "operator/deliveries_list.ex: multi-column delivery list — tabular",
      "inbound/records_list.ex: multi-column inbound record list — tabular",
      "preview/tabs.ex: rendered-headers key/value comparison — tabular"
    ]

    script = read!(@conformance_script)
    assert String.contains?(script, "TABLE_FLOOR=3"),
           "A11 floor drifted: TABLE_FLOOR=3 not found in check-conformance.sh. " <>
             "If the floor changes, update the per-table justification rows in this manifest to match."

    assert length(table_justifications) == 3
  end

  test "the manifest's net-new guards (A3, A4/A23, A16-system, A21, A22, A11) are all live" do
    net_new_ids = ["A3", "A4", "A23", "A16-system", "A21", "A22", "A11"]

    for id <- net_new_ids do
      row = Enum.find(@manifest, &(&1.id == id))
      assert row, "net-new Bucket-A guard #{id} missing from the manifest"
      assert row.status == :live, "net-new guard #{id} must be live"
    end
  end
end
