defmodule MailglassAdmin.Phase178ProhibitionContractTest do
  @moduledoc """
  Machine-checked form of the Phase 178 must-NOT prohibitions (PRVUX-05 to
  PRVUX-07, UIQ-04, UIQ-06, STORY-07; D-15, D-52).

  Seven rules, each a detector that returns a violation list (`[]` is clean):

    * P1: no generic per-field type helper string and no editable `-help` id.
    * P2: no dangling `aria-describedby` or `aria-labelledby` id.
    * P3: the selected scenario's exact technical identity is visible text in
      the selector trigger, never only a `title` attribute.
    * P4: no raw scenario atom is the only primary label of a non-colliding
      scenario.
    * P5: the `reset_assigns` event name and its restore/clear behavior are
      unchanged.
    * P6: no owner-feedback row is pending or partial at phase close.
    * P7: no spec that sets `style.zoom` calls it real zoom, actual 200% or
      200% zoom.

  The "detectors have teeth" block feeds each detector a known violation and a
  known clean fixture, so a pass here is not vacuous. Each rule was also proven
  red by a temporary source mutation, recorded in `178-AUTOMATION.md` under
  "Prohibition contract (D-15)" and reverted. This file runs in the
  merge-blocking admin lane (`mix verify.support_contract.admin`).

  Positive behavior (typed fields, selector layout, real-zoom geometry) stays in
  the LiveView and browser suites; this file only owns the prohibitions.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @moduletag :phase178

  alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}
  alias MailglassAdmin.Preview.{AssignsForm, Discovery, ScenarioLabel, Sidebar}
  alias MailglassAdmin.TestSupport.FeedbackLedger
  alias MailglassDemo.QuickViewScenarios

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]
  @typed_path "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values"
  @package_root Path.expand("../..", __DIR__)
  @repo_root Path.expand("..", @package_root)

  # P1: the per-field helpers Phase 178 removed (plan 178-01).
  @generic_helpers ["Text value.", "Whole number.", "Decimal number.", "Toggle on or off."]

  # P7: wording that claims a real (browser-level) zoom.
  @real_zoom_phrases [~r/real zoom/i, ~r/actual 200%/i, ~r/200% zoom/i]
  @spec_test_boundary ~r/(?=\btest(?:\.(?:describe(?:\.\w+)?|only|skip|fixme|fail|slow))?\s*\()/
  @spec_string_literal ~r/"(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*'|`(?:[^`\\]|\\.)*`/s

  @typed_assigns %{
    label: "Original",
    quantity: 3,
    ratio: 1.5,
    enabled?: true,
    due_on: ~D[2026-10-09],
    metadata: %{source: "fixture"},
    mode: :preview,
    scheduled_at: ~U[2026-10-09 12:00:00Z],
    pair: {:a, 1},
    address: %URI{host: "example.test"}
  }

  setup %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
    {:ok, conn: conn}
  end

  describe "detectors have teeth (fail-first proof)" do
    test "the P1 detector rejects a generic helper string and an editable -help id" do
      for fragment <- [
            ~s(<p id="assigns-quantity-help">Whole number.</p>),
            ~s(<input id="assigns-x" aria-describedby="assigns-x-help"/><p id="assigns-x-help">Anything</p>),
            ~s(<p>Text value.</p>),
            ~s(<p>Decimal number.</p>),
            ~s(<p>Toggle on or off.</p>),
            ~s(<p>Date.</p>)
          ] do
        assert generic_helper_violations(fragment) != [],
               "P1 detector missed #{inspect(fragment)}"
      end

      clean =
        ~s(<label for="assigns-quantity">Quantity</label><input id="assigns-quantity"/><p id="assigns-quantity-error">Enter a whole number.</p>)

      assert generic_helper_violations(clean) == []
    end

    test "the P2 detector rejects a dangling describedby and labelledby id" do
      assert dangling_id_violations(~s(<div aria-describedby="nope"></div>)) ==
               [{"aria-describedby", "nope"}]

      assert dangling_id_violations(~s(<p id="a"></p><div aria-labelledby="a missing"></div>)) ==
               [{"aria-labelledby", "missing"}]

      assert dangling_id_violations(
               ~s(<p id="a"></p><div aria-describedby="a" aria-labelledby="a"></div>)
             ) == []
    end

    test "the P3 detector rejects an identity that lives only in a title attribute" do
      title_only =
        ~s(<details><summary data-testid="preview-email-menu-trigger"><span title="M.x">Welcome</span></summary></details>)

      visible =
        ~s(<details><summary data-testid="preview-email-menu-trigger"><span>Welcome</span><span data-testid="preview-email-menu-active-technical">M.x</span></summary></details>)

      assert title_only_identity_violations(title_only, "M.x") != []
      assert title_only_identity_violations(visible, "M.x") == []
      assert title_only_identity_violations(~s(<p>no trigger</p>), "M.x") != []
    end

    test "the P4 detector rejects a raw atom primary and accepts colliding raw atoms" do
      raw = option_html("welcome_default", "welcome_default")
      humanized = option_html("Welcome default", "welcome_default")

      assert raw_primary_violations(raw, MapSet.new()) == [{"welcome_default", "welcome_default"}]
      assert raw_primary_violations(humanized, MapSet.new()) == []

      # A genuinely colliding pair keeps the raw atom to tell the two apart.
      assert raw_primary_violations(raw, MapSet.new(["welcome_default"])) == []
    end

    test "the P5 detector rejects a reset that leaves a field error, a draft or the wrong event" do
      stale_error =
        reset_page(
          ~s(<input id="assigns-quantity" value="3"/>),
          ~s(<p id="assigns-quantity-error">Enter a whole number.</p>)
        )

      stale_draft = reset_page(~s(<input id="assigns-quantity" value="8items"/>), "")

      wrong_event =
        String.replace(
          reset_page(~s(<input id="assigns-quantity" value="3"/>), ""),
          "reset_assigns",
          "reset"
        )

      restored = reset_page(~s(<input id="assigns-quantity" value="3"/>), "")

      assert reset_violations(stale_error, "quantity", "3") != []
      assert reset_violations(stale_draft, "quantity", "3") != []
      assert reset_violations(wrong_event, "quantity", "3") != []
      assert reset_violations(restored, "quantity", "3") == []
    end

    test "the P6 detector rejects a pending or partial feedback row" do
      assert FeedbackLedger.open_rows([%{"id" => "fb-a", "status" => "partial"}]) ==
               %{pending: [], partial: ["fb-a"]}

      assert FeedbackLedger.open_rows([%{"id" => "fb-b", "status" => "pending"}]) ==
               %{pending: ["fb-b"], partial: []}

      assert FeedbackLedger.open_rows([%{"id" => "fb-c", "status" => "automated"}]) ==
               %{pending: [], partial: []}
    end

    test "the P7 detector rejects a style.zoom test that claims real zoom" do
      for {title, body} <- [
            {"keeps controls at real zoom", ~s(el.style.zoom = "2";)},
            {"keeps controls at actual 200% in the browser", ~s(el.style.zoom = "2";)},
            {"keeps controls under 200% zoom", ~s(document.documentElement.style.zoom = zoom;)},
            {"neutral title", ~s|el.style.zoom = "2"; expect(x, "real zoom keeps it").toBe(1);|}
          ] do
        source = ~s|test("#{title}", async ({ page }) => { #{body} });|

        assert [{"fixture.spec.js", _title}] =
                 css_zoom_label_violations([{"fixture.spec.js", source}]),
               "P7 detector missed #{inspect(title)}"
      end
    end

    test "the P7 detector accepts CSS-zoom wording and real-zoom tests that do not use style.zoom" do
      css_only =
        ~s|test("keeps controls under CSS zoom 2x", async () => { el.style.zoom = "2"; });|

      real_only =
        ~s|test("actual 200% Chromium zoom keeps Close usable", async () => { await cdp.send("x"); });|

      two_tests =
        ~s|test("real zoom stays usable", async () => { await cdp.send("x"); });\n| <>
          ~s|test("CSS zoom 2x stays usable", async () => { el.style.zoom = "2"; });|

      assert css_zoom_label_violations([
               {"a.spec.js", css_only},
               {"b.spec.js", real_only},
               {"c.spec.js", two_tests}
             ]) == []
    end
  end

  describe "P1: no generic per-field helper and no editable -help id" do
    test "assigns_form/1 renders none for typed, editable-only, read-only, mixed and error states" do
      for {name, html} <- assigns_form_states() do
        assert_clean(generic_helper_violations(html), "P1 violated in #{name}")
      end
    end

    test "the typed_values page renders none on mount, after an invalid edit and after Restore defaults",
         %{conn: conn} do
      {:ok, view, mounted} = live(conn, @typed_path)
      invalid = render_change(view, "assigns_changed", %{"assigns" => %{"quantity" => "8items"}})
      reset = render_click(view, "reset_assigns", %{})

      for {name, html} <- [mounted: mounted, invalid: invalid, reset: reset] do
        assert_clean(generic_helper_violations(html), "P1 violated on the #{name} page")
      end
    end

    test "the selector menu renders no generic helper or -help id", %{conn: _conn} do
      for {name, html} <- menu_states() do
        assert_clean(generic_helper_violations(html), "P1 violated in menu state #{name}")
      end
    end
  end

  describe "P2: no dangling aria-describedby or aria-labelledby id" do
    test "assigns_form/1 resolves every reference in every state" do
      for {name, html} <- assigns_form_states() do
        assert_clean(dangling_id_violations(html), "P2 violated in #{name}")
      end
    end

    test "the selector menu resolves every reference, closed and open" do
      for {name, html} <- menu_states() do
        assert_clean(dangling_id_violations(html), "P2 violated in menu state #{name}")
      end
    end

    test "every typed_values page state resolves its references", %{conn: conn} do
      {:ok, view, mounted} = live(conn, @typed_path)
      invalid = render_change(view, "assigns_changed", %{"assigns" => %{"quantity" => "8items"}})
      reset = render_click(view, "reset_assigns", %{})

      for {name, html} <- [mounted: mounted, invalid: invalid, reset: reset] do
        assert_clean(dangling_id_violations(html), "P2 violated on the #{name} page")
      end
    end
  end

  describe "P3: the exact identity is visible text in the trigger" do
    test "every fixture scenario shows ScenarioLabel.technical/2 in the trigger text" do
      scenarios =
        for {mod, list} <- discovered(), is_list(list), {scenario, _defaults} <- list do
          {mod, scenario}
        end

      # The render-error entry has no function, so its identity is the module.
      scenarios = scenarios ++ [{BrokenMailer, :__error__}]

      assert length(scenarios) >= 7, "expected the HappyMailer scenarios plus the render error"

      for {mod, scenario} <- scenarios do
        html = render_menu(current_mailable: mod, current_scenario: scenario)
        technical = ScenarioLabel.technical(mod, scenario)

        assert title_only_identity_violations(html, technical) == [],
               "P3 violated for #{inspect(mod)}.#{scenario}"
      end
    end

    test "the live scenario page shows the identity in the trigger", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert title_only_identity_violations(
               html,
               ScenarioLabel.technical(HappyMailer, :welcome_default)
             ) == []
    end
  end

  describe "P4: no raw atom is the only primary label of a non-colliding scenario" do
    test "the open menu never shows a raw atom as the primary of a non-colliding option" do
      colliding = colliding_atoms(discovered())

      assert colliding != MapSet.new(), "fixture must include one colliding pair (non-vacuity)"

      for current <- [nil, :welcome_default, :typed_values] do
        html = render_menu(current_mailable: HappyMailer, current_scenario: current)

        assert raw_primary_violations(html, colliding) == [],
               "P4 violated with #{inspect(current)}"
      end
    end

    test "non-colliding primaries equal ScenarioLabel.humanize/1 and colliding ones keep the atom" do
      colliding = colliding_atoms(discovered())
      options = html_options(render_menu([]))

      assert length(options) == 6

      for {primary, technical} <- options do
        if MapSet.member?(colliding, technical) do
          assert primary == technical
        else
          assert primary == ScenarioLabel.humanize(String.to_existing_atom(technical))
        end
      end
    end
  end

  describe "P5: reset_assigns is unchanged" do
    test "Restore defaults fires reset_assigns, restores the default and clears every field error",
         %{conn: conn} do
      {:ok, view, mounted} = live(conn, @typed_path)

      assert [button] =
               mounted
               |> Floki.parse_fragment!()
               |> Floki.find(~s(button[phx-click="reset_assigns"]))

      assert String.trim(Floki.text(button)) == "Restore defaults"

      invalid =
        render_change(view, "assigns_changed", %{
          "assigns" => %{"quantity" => "8items", "label" => "Long draft 東京"}
        })

      # Non-vacuity: the edit produced a draft and a field error to be cleared.
      assert invalid =~ ~s(id="assigns-quantity-error")
      assert invalid =~ ~s(value="8items")

      reset = render_click(view, "reset_assigns", %{})

      assert reset_violations(reset, "quantity", "3") == []
      assert reset_violations(reset, "label", "Original") == []
      refute reset =~ ~r/id="assigns-[^"]*-error"/
    end
  end

  describe "P6: no feedback row is pending or partial" do
    test "the real manifest has no open row" do
      assert FeedbackLedger.open_rows(QuickViewScenarios.feedback()) ==
               %{pending: [], partial: []}
    end
  end

  describe "P7: no style.zoom test says real zoom" do
    test "no spec in the Admin or demo e2e trees labels CSS zoom as real zoom" do
      files =
        [
          Path.join(@package_root, "e2e/*.spec.js"),
          Path.join(@repo_root, "reference/demo_app/assets/e2e/*.spec.js")
        ]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.map(&{Path.relative_to(&1, @repo_root), File.read!(&1)})

      assert length(files) > 15, "expected the e2e specs, read #{length(files)} (vacuous scan)"

      # Non-vacuity: the scan sees at least one real style.zoom test to judge.
      assert Enum.any?(files, fn {_path, source} -> String.contains?(source, "style.zoom") end)

      assert css_zoom_label_violations(files) == []
    end
  end

  # -- detectors ---------------------------------------------------------------

  # P1: [{:generic_helper | :help_id | :help_ref, value}] on the assigns form.
  defp generic_helper_violations(html) do
    doc = Floki.parse_fragment!(html)
    texts = doc |> text_nodes() |> Enum.map(&String.trim/1)

    text_hits =
      for text <- texts, helper <- @generic_helpers, String.contains?(text, helper) do
        {:generic_helper, helper}
      end

    date_hits = for text <- texts, text == "Date.", do: {:generic_helper, "Date."}

    id_hits =
      for node <- Floki.find(doc, "[id]"),
          id <- Floki.attribute(node, "id"),
          assigns_help_id?(id),
          do: {:help_id, id}

    ref_hits =
      for node <- Floki.find(doc, "[aria-describedby]"),
          value <- Floki.attribute(node, "aria-describedby"),
          token <- String.split(value),
          assigns_help_id?(token),
          do: {:help_ref, token}

    text_hits ++ date_hits ++ id_hits ++ ref_hits
  end

  # The assigns form owns the `assigns-<key>-help` id family; other chrome (the
  # backdrop toggle's `preview-backdrop-help`) is a different control.
  defp assigns_help_id?(id),
    do: String.starts_with?(id, "assigns-") and String.ends_with?(id, "-help")

  # P2: [{attribute, dangling_token}].
  defp dangling_id_violations(html) do
    doc = Floki.parse_fragment!(html)

    ids =
      doc
      |> Floki.find("[id]")
      |> Enum.flat_map(&Floki.attribute(&1, "id"))
      |> MapSet.new()

    for attribute <- ["aria-describedby", "aria-labelledby"],
        element <- Floki.find(doc, "[#{attribute}]"),
        value <- Floki.attribute(element, attribute),
        token <- String.split(value),
        not MapSet.member?(ids, token),
        do: {attribute, token}
  end

  # P3: the trigger's visible text (attributes excluded) must contain the exact
  # technical identity. A title attribute carrying it does not count.
  defp title_only_identity_violations(html, technical) do
    doc = Floki.parse_fragment!(html)

    case Floki.find(doc, ~s([data-testid="preview-email-menu-trigger"])) do
      [trigger] ->
        visible = trigger |> Floki.text(sep: " ") |> collapse()

        if String.contains?(visible, technical) do
          []
        else
          titled? = trigger |> Floki.raw_html() |> String.contains?(~s(title="#{technical}"))
          [{:not_visible, technical, if(titled?, do: :title_only, else: :absent)}]
        end

      other ->
        [{:trigger_count, length(other)}]
    end
  end

  # P4: [{primary, technical}] for every option whose visible primary is the raw
  # atom string although the scenario does not collide and humanizes differently.
  defp raw_primary_violations(html, colliding) do
    for {primary, technical} <- html_options(html),
        primary == technical,
        not MapSet.member?(colliding, technical),
        ScenarioLabel.humanize(String.to_existing_atom(technical)) != technical,
        do: {primary, technical}
  end

  # P5: violations after Restore defaults for one field: a leftover field error,
  # a leftover draft value, or a button that no longer fires reset_assigns.
  defp reset_violations(html, key, default) do
    doc = Floki.parse_fragment!(html)

    error_hits =
      for node <- Floki.find(doc, ~s([id^="assigns-"][id$="-error"])),
          id <- Floki.attribute(node, "id"),
          do: {:field_error_left, id}

    value_hits =
      case Floki.find(doc, "#assigns-#{key}") do
        [input] ->
          case Floki.attribute(input, "value") do
            [^default] -> []
            other -> [{:not_default, key, other}]
          end

        other ->
          [{:field_count, key, length(other)}]
      end

    event_hits =
      case Floki.find(doc, ~s(button[phx-click="reset_assigns"])) do
        [_button] -> []
        other -> [{:reset_button_count, length(other)}]
      end

    error_hits ++ value_hits ++ event_hits
  end

  # P7: [{spec_file, test_title}] for every test block that sets style.zoom and
  # whose title or string literals claim real zoom, actual 200% or 200% zoom.
  defp css_zoom_label_violations(files) do
    for {path, source} <- files,
        block <- Regex.split(@spec_test_boundary, source),
        String.contains?(block, "style.zoom"),
        literals = @spec_string_literal |> Regex.scan(block) |> Enum.map(&hd/1),
        Enum.any?(literals, fn literal ->
          Enum.any?(@real_zoom_phrases, &Regex.match?(&1, literal))
        end),
        do: {path, List.first(literals)}
  end

  # -- fixtures and rendering --------------------------------------------------

  defp assigns_form_states do
    editable = %{label: "Ada", quantity: 3, ratio: 1.5, enabled?: false, due_on: ~D[2026-10-09]}
    readonly = %{plan: :free, metadata: %{source: "fixture"}}
    mixed = %{user_name: "Ada", plan: :free}

    errors = %{
      quantity: "Enter a whole number.",
      ratio: "Enter a decimal number.",
      due_on: "Enter a valid calendar date."
    }

    drafts = %{quantity: "8items", ratio: "2.75tail", due_on: "2026-02-30"}

    [
      typed: [scenario_assigns: @typed_assigns],
      editable_only: [scenario_assigns: editable],
      read_only_only: [scenario_assigns: readonly],
      mixed: [scenario_assigns: mixed],
      empty: [scenario_assigns: %{}],
      typed_with_errors: [
        scenario_assigns: @typed_assigns,
        draft_assigns: drafts,
        field_errors: errors
      ],
      editable_with_errors: [
        scenario_assigns: editable,
        draft_assigns: drafts,
        field_errors: errors
      ]
    ]
    |> Enum.map(fn {name, attrs} ->
      {name, render_component(&AssignsForm.assigns_form/1, attrs)}
    end)
  end

  defp menu_states do
    for {name, overrides} <- [
          closed_none: [current_mailable: nil, current_scenario: nil, open: false],
          open_none: [current_mailable: nil, current_scenario: nil, open: true],
          closed_scenario: [open: false],
          open_scenario: [open: true],
          open_mailable_only: [current_scenario: nil, open: true],
          open_long_identity: [
            current_scenario: :welcome_überraschung_東京__with_a_deliberately_long_name,
            open: true
          ]
        ] do
      {name, render_menu(overrides)}
    end
  end

  defp render_menu(overrides) do
    attrs =
      Keyword.merge(
        [
          mailables: discovered(),
          current_mailable: HappyMailer,
          current_scenario: :welcome_default,
          device_width: 375,
          admin_chrome_theme: nil,
          mount_path: "/dev/mail"
        ],
        overrides
      )

    render_component(&Sidebar.menu/1, attrs)
  end

  defp discovered, do: Discovery.discover(@fixture_mailables)

  defp option_html(primary, technical) do
    ~s(<a href="/dev/mail/MailglassAdmin.Fixtures.HappyMailer/#{technical}" data-testid="preview-email-menu-option">) <>
      ~s(<span data-testid="preview-email-menu-option-label">#{primary}</span>) <>
      ~s(<span data-testid="preview-email-menu-option-technical">#{technical}</span></a>)
  end

  defp reset_page(input, error) do
    ~s(<form id="preview-assigns-form">#{input}#{error}) <>
      ~s(<button type="button" phx-click="reset_assigns">Restore defaults</button></form>)
  end

  # [{visible_primary, technical_atom_string}] for every scenario option, active
  # or not, across all fixture mailables.
  defp html_options(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find(
      ~s(a[data-testid="preview-email-menu-option"], a[data-testid="preview-email-menu-active-option"])
    )
    |> Enum.map(fn link ->
      [label] = Floki.find(link, ~s([data-testid="preview-email-menu-option-label"]))
      [technical] = Floki.find(link, ~s([data-testid="preview-email-menu-option-technical"]))
      {label |> Floki.text() |> collapse(), technical |> Floki.text() |> collapse()}
    end)
  end

  # Scenario atoms whose humanized labels collide within one Mailable, computed
  # from ScenarioLabel.humanize/1 alone (never from the label table under test).
  defp colliding_atoms(mailables) do
    for {_mod, list} <- mailables, is_list(list), reduce: MapSet.new() do
      acc ->
        scenarios = Enum.map(list, &elem(&1, 0))
        keyed = Enum.group_by(scenarios, &collision_key(ScenarioLabel.humanize(&1)))

        keyed
        |> Map.values()
        |> Enum.filter(&(length(&1) > 1))
        |> List.flatten()
        |> Enum.map(&Atom.to_string/1)
        |> Enum.into(acc)
    end
  end

  defp collision_key(label) do
    case :unicode.characters_to_nfc_binary(label) do
      normalized when is_binary(normalized) -> String.downcase(normalized)
      _invalid -> String.downcase(label)
    end
  end

  defp text_nodes(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &text_nodes/1)
  defp text_nodes(text) when is_binary(text), do: [text]
  defp text_nodes({_tag, _attrs, children}), do: text_nodes(children)
  defp text_nodes(_other), do: []

  defp assert_clean(violations, label),
    do: assert(violations == [], "#{label}: #{inspect(violations)}")

  defp collapse(text), do: text |> String.split() |> Enum.join(" ")
end
