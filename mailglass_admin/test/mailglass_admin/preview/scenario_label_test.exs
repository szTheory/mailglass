defmodule MailglassAdmin.Preview.ScenarioLabelTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  # Phase 178 (PRVUX-07, D-04..D-06): the pure label table behind the Preview
  # selector. Synthetic module atoms are used for the collision tables, so no
  # new fixture Mailables are needed and discovery counts do not move.
  @moduletag :phase178

  alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}
  alias MailglassAdmin.Preview.{Discovery, ScenarioLabel, Sidebar}

  @source Path.expand("../../../lib/mailglass_admin/preview/scenario_label.ex", __DIR__)

  defp primary(labels, mod, scenario), do: ScenarioLabel.scenario_label(labels, mod, scenario)

  defp pairs(labels, mailables) do
    for {mod, reflection} <- mailables,
        is_list(reflection),
        {scenario, _defaults} <- reflection do
      {ScenarioLabel.module_label(labels, mod), primary(labels, mod, scenario)}
    end
  end

  defp assert_unique_pairs(mailables) do
    labels = ScenarioLabel.build(mailables)
    all = pairs(labels, mailables)
    assert all == Enum.uniq(all), "duplicate {module_label, primary} pairs: #{inspect(all)}"
    labels
  end

  describe "humanize/1" do
    test "sentence-cases snake_case scenario atoms" do
      assert ScenarioLabel.humanize(:welcome_default) == "Welcome default"
      assert ScenarioLabel.humanize(:user_name) == "User name"
      assert ScenarioLabel.humanize(:welcome) == "Welcome"
    end

    test "keeps a trailing question mark" do
      assert ScenarioLabel.humanize(:admin?) == "Admin?"
    end

    test "collapses double underscores instead of emitting a double space" do
      label = ScenarioLabel.humanize(:welcome_überraschung_東京__with_a_deliberately_long_name)

      assert label == "Welcome überraschung 東京 with a deliberately long name"
      refute label =~ "  "
    end

    test "drops leading and trailing underscores" do
      assert ScenarioLabel.humanize(:_leading) == "Leading"
      assert ScenarioLabel.humanize(:trailing_) == "Trailing"
    end

    test "falls back to the raw string when no segment remains" do
      assert ScenarioLabel.humanize(:_) == "_"
      assert ScenarioLabel.humanize(:__) == "__"
    end
  end

  describe "technical/2" do
    test "names the Mailable function that defines the scenario" do
      assert ScenarioLabel.technical(HappyMailer, :welcome_default) ==
               "MailglassAdmin.Fixtures.HappyMailer.welcome_default"
    end

    test "the render-error scenario is the module alone" do
      assert ScenarioLabel.technical(BrokenMailer, :__error__) ==
               "MailglassAdmin.Fixtures.BrokenMailer"
    end
  end

  describe "build/1 scenario collisions" do
    test "distinct humanized labels stay humanized" do
      labels =
        ScenarioLabel.build([{HappyMailer, [welcome_default: %{}, welcome_enterprise: %{}]}])

      assert primary(labels, HappyMailer, :welcome_default) == "Welcome default"
      assert primary(labels, HappyMailer, :welcome_enterprise) == "Welcome enterprise"
    end

    test "scenarios whose humanized labels collide use their raw atom string" do
      labels = ScenarioLabel.build([{HappyMailer, [a__b: %{}, a_b: %{}]}])

      assert primary(labels, HappyMailer, :a__b) == "a__b"
      assert primary(labels, HappyMailer, :a_b) == "a_b"
    end

    test "a collision does not disturb a non-colliding sibling" do
      labels = ScenarioLabel.build([{HappyMailer, [a__b: %{}, a_b: %{}, other: %{}]}])

      assert primary(labels, HappyMailer, :other) == "Other"
    end

    test "case-only variants are treated as duplicates" do
      labels = ScenarioLabel.build([{HappyMailer, [{:a_bc, %{}}, {:a_Bc, %{}}]}])

      assert primary(labels, HappyMailer, :a_bc) == "a_bc"
      assert primary(labels, HappyMailer, :a_Bc) == "a_Bc"
    end

    test "NFC and NFD variants are treated as duplicates" do
      composed = :"caf\u00E9"
      decomposed = :"cafe\u0301"

      labels = ScenarioLabel.build([{HappyMailer, [{composed, %{}}, {decomposed, %{}}]}])

      assert primary(labels, HappyMailer, composed) == "caf\u00E9"
      assert primary(labels, HappyMailer, decomposed) == "cafe\u0301"
      refute primary(labels, HappyMailer, composed) == primary(labels, HappyMailer, decomposed)
    end

    test "render error keeps its label" do
      labels = ScenarioLabel.build([{BrokenMailer, {:error, "boom"}}])

      assert primary(labels, BrokenMailer, :__error__) == "render error"
    end
  end

  describe "build/1 Mailable labels" do
    test "an unshared leaf stays the leaf" do
      labels =
        ScenarioLabel.build([{HappyMailer, [welcome_default: %{}]}, {StubMailer, :no_previews}])

      assert ScenarioLabel.module_label(labels, HappyMailer) == "HappyMailer"
      assert ScenarioLabel.module_label(labels, StubMailer) == "StubMailer"
    end

    test "a shared leaf takes the shortest distinguishing namespace suffix" do
      labels =
        ScenarioLabel.build([
          {Foo.Account.Mailer, [w: %{}]},
          {Bar.Account.Mailer, [w: %{}]},
          {Baz.Mailer, :no_previews}
        ])

      assert ScenarioLabel.module_label(labels, Foo.Account.Mailer) == "Foo.Account.Mailer"
      assert ScenarioLabel.module_label(labels, Bar.Account.Mailer) == "Bar.Account.Mailer"
      assert ScenarioLabel.module_label(labels, Baz.Mailer) == "Baz.Mailer"
    end

    test "a one-segment module collides with a namespaced one" do
      labels = ScenarioLabel.build([{Mailer, [w: %{}]}, {App.Mailer, [w: %{}]}])

      assert ScenarioLabel.module_label(labels, Mailer) == "Mailer"
      assert ScenarioLabel.module_label(labels, App.Mailer) == "App.Mailer"
    end

    test ":no_previews and error entries take part in leaf collisions" do
      labels =
        ScenarioLabel.build([
          {One.Mailer, :no_previews},
          {Two.Mailer, {:error, "boom"}},
          {Three.Mailer, [w: %{}]}
        ])

      assert ScenarioLabel.module_label(labels, One.Mailer) == "One.Mailer"
      assert ScenarioLabel.module_label(labels, Two.Mailer) == "Two.Mailer"
      assert ScenarioLabel.module_label(labels, Three.Mailer) == "Three.Mailer"
    end

    test "a duplicate module entry is deduplicated" do
      labels = ScenarioLabel.build([{HappyMailer, [w: %{}]}, {HappyMailer, [w: %{}]}])

      assert ScenarioLabel.module_label(labels, HappyMailer) == "HappyMailer"
      assert map_size(labels.modules) == 1
    end
  end

  describe "unique {module_label, primary_label} pairs" do
    test "hold over the discovered fixture Mailables" do
      mailables = Discovery.discover([HappyMailer, StubMailer, BrokenMailer])

      labels = assert_unique_pairs(mailables)

      assert primary(labels, HappyMailer, :welcome_default) == "Welcome default"
    end

    test "hold over synthetic sets with scenario and Mailable collisions" do
      assert_unique_pairs([
        {Foo.Account.Mailer, [w: %{}, w_: %{}, _w: %{}]},
        {Bar.Account.Mailer, [w: %{}, w__: %{}]},
        {Baz.Mailer, [{:a_bc, %{}}, {:a_Bc, %{}}, {:a__bc, %{}}]},
        {Mailer, [x: %{}]},
        {App.Mailer, [x: %{}]},
        {Stub.Mailer, :no_previews}
      ])
    end
  end

  describe "total lookups" do
    test "unknown module and scenario fall back without raising" do
      labels = ScenarioLabel.build([])

      assert labels == %{modules: %{}, scenarios: %{}}
      assert ScenarioLabel.module_label(labels, Unknown.Deep.Mailer) == "Mailer"
      assert ScenarioLabel.module_label(labels, Solo) == "Solo"
      assert primary(labels, Unknown.Deep.Mailer, :some_scenario) == "some_scenario"
    end

    test "technical identity for an unselected scenario is the module alone" do
      assert ScenarioLabel.technical(HappyMailer, nil) == "MailglassAdmin.Fixtures.HappyMailer"
    end
  end

  describe "source and escaping" do
    test "the module never creates atoms or emits diagnostics" do
      source = File.read!(@source)

      refute source =~ "String.to_atom"
      refute source =~ "Logger"
      refute source =~ ":telemetry"
    end

    test "markup-looking and bidi scenario names are escaped in the rendered menu" do
      hostile = String.to_atom("<script>alert(1)</script>_\u202Eevil")

      html =
        render_component(&Sidebar.menu/1,
          mailables: [{Hostile.Mailer, [{hostile, %{}}]}],
          current_mailable: Hostile.Mailer,
          current_scenario: hostile,
          device_width: 768,
          admin_chrome_theme: nil,
          mount_path: "/dev/mail"
        )

      refute html =~ "<script>alert(1)"
      assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
    end
  end
end
