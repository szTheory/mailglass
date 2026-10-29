defmodule MailglassAdmin.QuickViewProjectionTest do
  use MailglassAdmin.LiveViewCase, async: false

  import Ecto.Query
  import Phoenix.Component, only: [sigil_H: 2]

  alias Mailglass.Operator.Deliveries
  alias Mailglass.Events.Event
  alias Mailglass.Tenancy
  alias MailglassAdmin.Inbound.DetailHeader, as: InboundDetailHeader
  alias MailglassAdmin.Inbound.EvidenceCard
  alias MailglassAdmin.Inbound.QuickView, as: InboundQuickView
  alias MailglassAdmin.OptionalDeps.MailglassInbound
  alias MailglassAdmin.Operator.DetailHeader
  alias MailglassAdmin.Operator.HealthOverview
  alias MailglassAdmin.Operator.Shell
  alias MailglassAdmin.SurfaceNav
  alias MailglassAdmin.Operator.QuickView, as: DeliveryQuickView
  alias MailglassAdmin.TestSupport.{InboundFixtures, OperatorFixtures}
  alias MailglassDemo.QuickViewScenarios

  @tag :phase175
  test "Phase 175 Northstar and Fjordline facts match scoped Delivery projections" do
    for {scenario_id, tenant_id} <- [
          {:northstar_complete, "northstar"},
          {:fjordline_long_unicode, "fjordline-aps"}
        ] do
      OperatorFixtures.seed_persona_cohort!()
      Tenancy.put_current(tenant_id)

      page =
        Deliveries.list_recent_deliveries_page(
          %{tenant_id: tenant_id, window_hours: 168},
          per_page: 20
        )

      assert [persisted] = page.entries
      assert page.total_count == 1

      pure = QuickViewScenarios.delivery_investigation(scenario_id)
      expected = pure.delivery

      assert persisted.tenant_id == tenant_id
      assert persisted.tenant_id == expected.tenant_id
      assert persisted.recipient == expected.recipient
      assert persisted.subject == expected.subject
      assert persisted.provider == expected.provider
      assert persisted.provider_message_id == expected.provider_message_id
      assert persisted.mailable == expected.mailable
      assert persisted.status == expected.status
      assert persisted.last_event_type == expected.last_event_type
      assert persisted.stream == expected.stream

      # The materializer generates Delivery IDs and independently anchors event times.
      assert persisted.id != expected.id
      assert %DateTime{} = persisted.last_event_at
      assert %DateTime{} = expected.last_event_at
      assert pure.position == %{index: 1, total: page.total_count}

      persisted_html =
        render_component(&DetailHeader.detail_header/1, Map.put(pure, :delivery, persisted))

      pure_html = render_component(&DetailHeader.detail_header/1, pure)

      assert rendered_text(persisted_html) =~ persisted.id
      assert rendered_text(pure_html) =~ expected.id
      assert rendered_text(persisted_html) =~ pure.account_labels[tenant_id]
      assert rendered_text(pure_html) =~ pure.account_labels[tenant_id]
      assert rendered_text(persisted_html) =~ expected.recipient
      assert rendered_text(pure_html) =~ expected.recipient
    end
  end

  test "Fjordline Delivery pure facts match the tenant-scoped production projection" do
    OperatorFixtures.seed_persona_cohort!()
    Tenancy.put_current("fjordline-aps")

    page =
      Deliveries.list_recent_deliveries_page(
        %{tenant_id: "fjordline-aps", window_hours: 168},
        per_page: 20
      )

    assert [persisted] = page.entries
    assert page.total_count == 1

    pure = QuickViewScenarios.delivery(:fjordline_single_unicode)
    expected = pure.delivery

    assert persisted.tenant_id == "fjordline-aps"
    assert persisted.recipient == expected.recipient
    assert persisted.subject == expected.subject
    assert persisted.provider == expected.provider
    assert persisted.provider_message_id == expected.provider_message_id
    assert persisted.mailable == expected.mailable
    assert persisted.status == expected.status
    assert persisted.last_event_type == expected.last_event_type

    # These timestamps are independently anchored by each materializer.
    assert %DateTime{} = persisted.last_event_at
    assert %DateTime{} = expected.last_event_at
    assert pure.position == %{index: 1, total: page.total_count}

    # The persona's legitimate nil reject reason is outside this list projection.
    assert %Event{reject_reason: nil} =
             TestRepo.one(
               from(event in Event,
                 where: event.tenant_id == "fjordline-aps" and event.type == :delivered,
                 select: event
               )
             )

    persisted_html =
      render_component(
        &DeliveryQuickView.quick_view/1,
        Map.put(pure, :delivery, persisted)
      )

    pure_html = render_component(&DeliveryQuickView.quick_view/1, pure)

    for html <- [persisted_html, pure_html] do
      text = rendered_text(html)
      assert text =~ expected.recipient
      assert text =~ expected.subject
      assert text =~ "Fjordline A/S"
      assert text =~ "POSTMARK"
      assert text =~ "Delivered"
    end

    assert rendered_text(persisted_html) =~ persisted.id
    assert rendered_text(pure_html) =~ expected.id
  end

  test "normal Inbound facts match the scoped production projection at position 3 of 6" do
    pure = QuickViewScenarios.inbound(:northstar_normal)
    expected = pure.record

    newer_times = [
      DateTime.add(expected.received_at, 3_600),
      DateTime.add(expected.received_at, 1_800)
    ]

    older_times = [
      DateTime.add(expected.received_at, -1_800),
      DateTime.add(expected.received_at, -3_600),
      DateTime.add(expected.received_at, -5_400)
    ]

    Enum.each(newer_times ++ older_times, fn received_at ->
      InboundFixtures.seed_matched!(expected.tenant_id,
        provider: expected.provider,
        recipient: "neighbor-#{DateTime.to_unix(received_at)}@northstar.example",
        subject: "Neighbor record",
        received_at: received_at,
        mailbox: MyApp.Mailboxes.SupportMailbox
      )
    end)

    %{record: inserted} =
      InboundFixtures.seed_matched!(expected.tenant_id,
        provider: expected.provider,
        recipient: expected.envelope_recipient,
        subject: expected.subject,
        received_at: expected.received_at,
        mailbox: MyApp.Mailboxes.SupportMailbox
      )

    Tenancy.put_current(expected.tenant_id)

    page =
      MailglassInbound.list_records_page(
        %{tenant_id: expected.tenant_id, window_hours: 168},
        per_page: 20
      )

    assert page.total_count == 6
    index = Enum.find_index(page.entries, &(&1.id == inserted.id))
    assert index == 2
    persisted = Enum.at(page.entries, index)
    assert persisted.id == inserted.id
    assert persisted.tenant_id == expected.tenant_id
    assert persisted.envelope_recipient == expected.envelope_recipient
    assert persisted.subject == expected.subject
    assert persisted.provider == expected.provider
    assert persisted.outcome == expected.outcome

    assert DateTime.truncate(persisted.received_at, :second) ==
             DateTime.truncate(expected.received_at, :second)

    assert persisted.mailbox == expected.mailbox

    persisted_html =
      render_component(
        &InboundQuickView.quick_view/1,
        Map.put(pure, :record, persisted)
      )

    pure_html = render_component(&InboundQuickView.quick_view/1, pure)

    for html <- [persisted_html, pure_html] do
      text = rendered_text(html)
      assert text =~ expected.envelope_recipient
      assert text =~ expected.subject
      assert text =~ pure.account_labels[expected.tenant_id]
      assert text =~ String.upcase(expected.provider)
      assert text =~ "Accepted"
      assert text =~ "SupportMailbox"
      assert text =~ "3 of 6"
    end

    assert rendered_text(persisted_html) =~ persisted.id
    assert rendered_text(pure_html) =~ expected.id
    assert pure.position == %{index: index + 1, total: page.total_count}
  end

  test "Unicode Inbound facts stay exact and foreign Account rows remain excluded" do
    pure = QuickViewScenarios.inbound(:fjordline_single_unicode)
    expected = pure.record

    %{record: inserted} =
      InboundFixtures.seed_matched!(expected.tenant_id,
        provider: expected.provider,
        recipient: expected.envelope_recipient,
        subject: expected.subject,
        received_at: expected.received_at,
        mailbox: MyApp.Mailboxes.SupportMailbox
      )

    %{record: foreign} =
      InboundFixtures.seed_matched!("other-account",
        provider: "postmark",
        recipient: "foreign@example.test",
        subject: "Foreign Account message",
        received_at: expected.received_at
      )

    Tenancy.put_current(expected.tenant_id)

    page =
      MailglassInbound.list_records_page(
        %{tenant_id: expected.tenant_id, window_hours: 168},
        per_page: 20
      )

    assert [persisted] = page.entries
    assert page.total_count == 1
    assert persisted.id == inserted.id
    assert persisted.tenant_id == expected.tenant_id
    assert persisted.envelope_recipient == expected.envelope_recipient
    assert persisted.subject == expected.subject
    assert persisted.provider == expected.provider
    assert persisted.outcome == expected.outcome

    assert DateTime.truncate(persisted.received_at, :second) ==
             DateTime.truncate(expected.received_at, :second)

    assert persisted.mailbox == expected.mailbox

    persisted_html =
      render_component(
        &InboundQuickView.quick_view/1,
        Map.put(pure, :record, persisted)
      )

    pure_html = render_component(&InboundQuickView.quick_view/1, pure)

    for html <- [persisted_html, pure_html] do
      text = rendered_text(html)
      assert text =~ expected.envelope_recipient
      assert text =~ expected.subject
      assert text =~ pure.account_labels[expected.tenant_id]
      assert text =~ String.upcase(expected.provider)
      assert text =~ "Accepted"
      assert text =~ "SupportMailbox"
    end

    assert rendered_text(persisted_html) =~ persisted.id
    assert rendered_text(pure_html) =~ expected.id
    refute Enum.any?(page.entries, &(&1.id == foreign.id))
    assert pure.position == %{index: 1, total: page.total_count}
  end

  test "Helios stays absent and unavailable Inbound remains an honest rendering-only state" do
    OperatorFixtures.seed_persona_cohort!()
    Tenancy.put_current("helios-void")

    delivery_page =
      Deliveries.list_recent_deliveries_page(
        %{tenant_id: "helios-void", window_hours: 168},
        per_page: 20
      )

    assert delivery_page.entries == []

    assert Code.ensure_loaded?(MailglassAdmin.OptionalDeps.MailglassInbound)

    inbound_page =
      MailglassInbound.list_records_page(%{tenant_id: "helios-void", window_hours: 168},
        per_page: 20
      )

    assert inbound_page.entries == []

    unavailable = QuickViewScenarios.inbound(:selected_unavailable)
    assert unavailable.record == nil
    assert unavailable.detail_error == :read_unavailable

    html = render_component(&InboundQuickView.quick_view/1, unavailable)
    assert html =~ "temporarily unavailable"
    refute html =~ "SupportMailbox"
    refute html =~ "Record ID"
  end

  @tag :phase176
  test "Phase 176 retained Inbound evidence scenarios render through production components" do
    long_local =
      "very.long.local.part.with.many.dotted.segments.that.never.breaks@mail-gateway.subdomain.example.com"

    # {scenario, markup the header must contain, markup the card must contain}
    table = [
      {:normal_contacts, ["Alex Rivera", "alex.rivera@example.com", "Northstar Billing"],
       ["Reveal raw source", "Raw provider source"]},
      {:long_local_part, [long_local], []},
      {:unicode, ["用户@例子.广告", "Zoë Ångström-Łukasiewicz", "zoe@example.com"], []},
      {:spoofed_display_name,
       ["billing@paypal.example", "sender@mailer.example", "inbound-address-spoof-cue"], []},
      {:many_recipients, ["Show 2 more", "recipient5@example.com", "recipient7@example.com"], []},
      {:missing_headers, ["No From header", "No To header", "Not recorded by provider"], []},
      {:unparseable, ["Unparseable address", "not an address"], []},
      {:evidence_unknown, [], ["Payload size", "Header count"]},
      {:evidence_empty_revealed, [], ["Provider sent an empty payload.", "Hide raw source"]},
      {:evidence_large_revealed, [], ["inbound-evidence-raw", "Line 40: synthetic body text"]},
      {:evidence_denied, [], ["permission to reveal raw source."]}
    ]

    for {id, header_needles, card_needles} <- table do
      scenario = QuickViewScenarios.inbound_evidence(id)

      header =
        render_component(&InboundDetailHeader.detail_header/1,
          detail: scenario.detail,
          account_labels: scenario.account_labels
        )

      card =
        render_component(&EvidenceCard.evidence_card/1,
          evidence: scenario.evidence,
          reveal_state: scenario.reveal_state,
          received_at: scenario.received_at
        )

      assert header =~ ~s(data-testid="inbound-detail-header"), "#{id} header"
      assert header =~ ~s(data-testid="inbound-contact-delivered-to"), "#{id} delivered-to"
      assert card =~ ~s(data-testid="inbound-evidence-card"), "#{id} card"
      assert scenario.proof_boundary == "story-render-only"
      assert scenario.scenario_id == "inbound-evidence-" <> String.replace("#{id}", "_", "-")

      for needle <- header_needles do
        assert header =~ needle, "#{id}: header should contain #{inspect(needle)}"
      end

      for needle <- card_needles do
        assert card =~ needle, "#{id}: card should contain #{inspect(needle)}"
      end

      # No retained fixture may show a masked-looking address.
      refute header =~ ~r/\w\*{2,}@/, "#{id}: masked-looking address in header"
    end

    # Defining facts that need more than a substring.
    assert render_scenario(:normal_contacts).header =~ "Provider message ID"
    assert render_scenario(:normal_contacts).header =~ "mg-176-normal-contacts"
    assert render_scenario(:spoofed_display_name).header =~ "inbound-address-spoof-cue"
    refute render_scenario(:normal_contacts).header =~ "inbound-address-spoof-cue"

    assert scenario_header_text(:many_recipients) |> count("@example.com") >= 7

    # Unknown size and count read Unavailable, never 0 bytes.
    unknown = render_scenario(:evidence_unknown).card
    assert fact(unknown, "Payload size") == "Unavailable"
    assert fact(unknown, "Header count") == "Unavailable"
    refute rendered_text(unknown) =~ "0 bytes"
    refute unknown =~ ~s(data-testid="inbound-evidence-raw")

    # A genuinely empty payload is a known zero, revealed with its own copy.
    empty = render_scenario(:evidence_empty_revealed).card
    assert fact(empty, "Payload size") == "0 bytes"
    assert empty =~ ~s(aria-expanded="true")
    assert empty =~ ~s(data-testid="inbound-evidence-raw")

    # Multi-KB revealed source: scrollable focusable <pre> and a thousands-separated size.
    large = render_scenario(:evidence_large_revealed).card
    assert large =~ ~r/<pre[^>]*tabindex="0"/
    assert fact(large, "Payload size") =~ ~r/^\d{1,3}(,\d{3})+ bytes$/

    # Denied: the denied copy shows and no payload byte reaches the markup.
    denied = render_scenario(:evidence_denied).card
    assert denied =~ ~s(data-testid="inbound-evidence-denied")
    refute denied =~ "DENIED-SENTINEL-176-08"
    refute denied =~ ~s(data-testid="inbound-evidence-raw")

    assert_raise ArgumentError, ~r/unknown retained Inbound evidence scenario/, fn ->
      QuickViewScenarios.inbound_evidence(:no_such_scenario)
    end
  end

  @health_overview_keys ~w(issues activity states deliveries_path inbound_path window_copy
                           window_description observed_at)a

  @health_issue_testids ~w(
    operator-health-deliveries-failed
    operator-health-deliveries-bounced
    operator-health-deliveries-rejected
    operator-health-deliveries-deferred
    operator-health-inbound-failed
    operator-health-inbound-no_match
    operator-overview-health-failures
    operator-overview-health-orphans
  )

  @tag :phase177
  test "Phase 177 northstar_normal Health scenario renders through the production component" do
    scenario = QuickViewScenarios.health_overview(:northstar_normal)

    assert scenario.scenario_id == "health-overview-northstar-normal"
    assert scenario.variation_id == "northstar_normal"
    assert scenario.state == "normal-no-issues"
    assert scenario.proof_boundary == "story-render-only"
    assert is_binary(scenario.role_job)

    assigns = Map.take(scenario, @health_overview_keys)
    assert Enum.sort(Map.keys(assigns)) == Enum.sort(@health_overview_keys)

    html = render_component(&HealthOverview.overview/1, assigns)
    assert html =~ ~s(data-testid="operator-health-layout")
    assert html =~ "No issues found"

    for issue <- scenario.issues do
      assert html =~ ~s(data-testid="#{issue.testid}"), "#{issue.testid} row"
    end

    assert_raise ArgumentError, ~r/unknown retained Health scenario/, fn ->
      QuickViewScenarios.health_overview(:no_such_scenario)
    end
  end

  @tag :phase177
  test "Phase 177 northstar_normal Health scenario matches the population the real route derives" do
    OperatorFixtures.seed_persona_cohort!()
    scenario = QuickViewScenarios.health_overview(:northstar_normal)

    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{
        "current_user_id" => "operator-1",
        "tenant_id" => "northstar",
        "auth_method" => "password",
        "recent_auth_at" => now
      })

    {:ok, _view, live_html} = live(conn, "/ops/mail?tenant_id=northstar")

    region =
      live_html
      |> Floki.parse_document!()
      |> Floki.find("[data-testid='operator-overview-health']")

    live_issues =
      for node <- Floki.find(region, "[data-testid]"),
          testid = node |> Floki.attribute("data-testid") |> List.first(),
          testid in @health_issue_testids do
        count =
          region
          |> Floki.find("[data-testid='#{testid}-count']")
          |> Floki.text()
          |> String.trim()
          |> String.to_integer()

        {testid, count}
      end

    manifest_issues = Enum.map(scenario.issues, &{&1.testid, &1.count})
    assert live_issues == manifest_issues

    # Activity totals come from the same derivation; an empty issue list alone
    # would make the comparison vacuous.
    live_activity =
      for id <- ~w(operator-health-outbound-activity operator-health-inbound-activity) do
        region
        |> Floki.find("[data-testid='#{id}'] .tabular-nums")
        |> Floki.text()
        |> String.trim()
        |> String.to_integer()
      end

    assert live_activity == [scenario.activity.deliveries.total, scenario.activity.inbound.total]
    assert live_activity == [1, 0]
  end

  @tag :phase177
  test "Phase 177 retained Health scenarios render their defining states through production markup" do
    # {scenario, markup that must appear, markup that must not appear}
    table = [
      {:helios_empty, ["No mail activity in this period"], ["<ul", "Needs attention"]},
      {:stale,
       [
         "Not refreshed",
         "Needs attention",
         ~r/Webhook processing wasn(&#39;|')t refreshed/,
         "Showing results from"
       ], []},
      {:unavailable,
       [
         "Health check incomplete",
         ~r/couldn(&#39;|')t be loaded\./,
         "Inbound activity unavailable"
       ], ["No issues found"]},
      {:fjordline_long_unicode, ["1234567890", "&lt;img src=x onerror=alert(1)&gt;", "山田太郎", "😀"],
       ["<img src=x"]}
    ]

    for {id, needles, absent} <- table do
      scenario = QuickViewScenarios.health_overview(id)
      assert scenario.proof_boundary == "story-render-only"
      assert scenario.scenario_id == "health-overview-" <> String.replace("#{id}", "_", "-")

      html =
        render_component(&HealthOverview.overview/1, Map.take(scenario, @health_overview_keys))

      assert html =~ ~s(data-testid="operator-health-layout"), "#{id} layout"

      for needle <- needles,
          do: assert(html =~ needle, "#{id}: should contain #{inspect(needle)}")

      for needle <- absent,
          do: refute(html =~ needle, "#{id}: must not contain #{inspect(needle)}")

      for issue <- scenario.issues do
        assert html =~ ~s(data-testid="#{issue.testid}"), "#{id}: #{issue.testid} row"
      end
    end
  end

  @tag :phase177
  test "Phase 177 retained Account scope scenarios render the control inside the scope group" do
    # {scenario, markup that must appear, markup that must not appear}
    table = [
      {:none, ["No Accounts yet"], ["<details", "operator-account-option"]},
      {:one, ["Northstar Logistics"], ["<details", "operator-account-option"]},
      {:many, ["<details", "Available Accounts", "Helios Trial", "Fjordline A/S"],
       ["No Accounts yet"]},
      {:long_label, ["&lt;b&gt;bold&lt;/b&gt;", "山田太郎", "😀", "break-words"], ["<b>bold</b>"]}
    ]

    for {id, needles, absent} <- table do
      scenario = QuickViewScenarios.account_scope(id)
      assert scenario.proof_boundary == "story-render-only"
      assert scenario.scenario_id == "account-scope-" <> String.replace("#{id}", "_", "-")

      html = account_scope_html(scenario)
      assert html =~ ~s(data-testid="operator-account-context"), "#{id} control"
      assert html =~ ~s(data-testid="surface-nav-scope-group"), "#{id} scope group"
      assert html =~ "Applies to Health, Deliveries and Inbound.", "#{id} scope description"

      for needle <- needles,
          do: assert(html =~ needle, "#{id}: should contain #{inspect(needle)}")

      for needle <- absent,
          do: refute(html =~ needle, "#{id}: must not contain #{inspect(needle)}")
    end

    many = account_scope_html(QuickViewScenarios.account_scope(:many))
    assert length(String.split(many, ~s(data-testid="operator-account-option"))) - 1 == 3

    assert_raise ArgumentError, ~r/unknown retained Account scope scenario/, fn ->
      QuickViewScenarios.account_scope(:no_such_scenario)
    end
  end

  @tag :phase177
  test "Phase 177 retained Preview chrome scenarios show a plain return and never an Account" do
    valid = preview_chrome_html(QuickViewScenarios.preview_chrome(:valid_return))
    assert valid =~ ~s(data-testid="preview-return-link")
    assert valid =~ "Back to Deliveries"
    assert valid =~ ~s(data-testid="preview-scope-label")
    assert valid =~ "Not tied to an Account"

    direct = preview_chrome_html(QuickViewScenarios.preview_chrome(:direct_entry))
    refute direct =~ ~s(data-testid="preview-return-link")
    assert direct =~ ~s(data-testid="preview-scope-label")

    for {id, html} <- [valid_return: valid, direct_entry: direct] do
      scenario = QuickViewScenarios.preview_chrome(id)
      assert scenario.proof_boundary == "story-render-only"
      assert scenario.scenario_id == "preview-chrome-" <> String.replace("#{id}", "_", "-")
      assert html =~ ~s(data-testid="surface-nav-sidebar")

      visible = Regex.replace(~r/<[^>]*>/, html, "")

      for forbidden <- ["Fjordline", "Northstar", "fjordline-aps", "northstar", "Helios"] do
        refute visible =~ forbidden, "#{id}: visible text names #{forbidden}"
      end
    end

    assert_raise ArgumentError, ~r/unknown retained Preview chrome scenario/, fn ->
      QuickViewScenarios.preview_chrome(:no_such_scenario)
    end
  end

  @tag :phase177
  test "Phase 177 Account scope and Preview chrome story files compose their production components" do
    account = File.read!(story_path("account_scope.story.exs"))
    assert {:defmodule, _, _} = Code.string_to_quoted!(account)
    assert account =~ "Storybook.AccountScope"
    assert account =~ "QuickViewScenarios.account_scope"
    assert account =~ "Shell.account_context"
    assert account =~ "SurfaceNav.nav"

    preview = File.read!(story_path("preview_chrome.story.exs"))
    assert {:defmodule, _, _} = Code.string_to_quoted!(preview)
    assert preview =~ "Storybook.PreviewChrome"
    assert preview =~ "QuickViewScenarios.preview_chrome"
    assert preview =~ "SurfaceNav.nav"

    health = File.read!(story_path("health_overview.story.exs"))

    for id <- ~w(northstar_normal helios_empty stale unavailable fjordline_long_unicode) do
      assert health =~ id, "Health story must list #{id}"
    end
  end

  @tag :phase177
  test "Phase 177 manifest carries the eleven retained scenarios with the full object shape" do
    ids = ~w(
      health-overview-northstar-normal health-overview-helios-empty health-overview-stale
      health-overview-unavailable health-overview-fjordline-long-unicode
      account-scope-none account-scope-one account-scope-many account-scope-long-label
      preview-chrome-valid-return preview-chrome-direct-entry
    )

    retained =
      QuickViewScenarios.scenarios()
      |> Enum.filter(
        &String.starts_with?(&1["id"], ["health-overview-", "account-scope-", "preview-chrome-"])
      )

    assert Enum.sort(Enum.map(retained, & &1["id"])) == Enum.sort(ids)

    required =
      ~w(id story_path theme_owner theme_picker_testid variation_id role_job source cohort
                  state reason owning_requirements proof_boundary feedback_ids rendered projection)

    for scenario <- retained do
      for key <- required,
          do: assert(Map.has_key?(scenario, key), "#{scenario["id"]} lacks #{key}")

      assert scenario["proof_boundary"] == "story-render-only"
      assert scenario["rendered"] == true
      owner = String.replace_suffix(scenario["theme_owner"], "-story", "")
      assert scenario["theme_picker_testid"] == owner <> "-review-theme"
    end
  end

  @tag :phase177
  test "Phase 177 Health story file composes the production component from the manifest builder" do
    source = File.read!(story_path("health_overview.story.exs"))
    assert {:defmodule, _, _} = Code.string_to_quoted!(source)
    assert source =~ "Storybook.HealthOverview"
    assert source =~ "QuickViewScenarios.health_overview"
    assert source =~ "HealthOverview.overview"
  end

  defp account_scope_html(s) do
    assigns = %{s: s}

    rendered_to_string(~H"""
    <SurfaceNav.nav
      active={@s.active}
      scope={:account}
      layout={@s.layout}
      preview_path={@s.preview_path}
      overview_path={@s.overview_path}
      deliveries_path={@s.deliveries_path}
      inbound_path={@s.inbound_path}
      inbound_available?={@s.inbound_available?}
    >
      <:scope_header>
        <Shell.account_context
          layout={@s.layout}
          selected_tenant_id={@s.selected_tenant_id}
          tenant_options={@s.tenant_options}
          tenant_state={@s.tenant_state}
          account_labels={@s.account_labels}
          page_uri={@s.page_uri}
        />
      </:scope_header>
    </SurfaceNav.nav>
    """)
  end

  defp preview_chrome_html(s) do
    assigns = %{s: s}

    rendered_to_string(~H"""
    <SurfaceNav.nav
      active={@s.active}
      scope={:preview}
      layout={@s.layout}
      preview_path={@s.preview_path}
      overview_path={@s.overview_path}
      deliveries_path={@s.deliveries_path}
      inbound_path={@s.inbound_path}
      inbound_available?={@s.inbound_available?}
      return_href={@s.return_href}
      return_label={@s.return_label}
    />
    """)
  end

  defp story_path(name),
    do: Path.expand("../../../reference/demo_app/storybook/#{name}", __DIR__)

  defp render_scenario(id) do
    scenario = QuickViewScenarios.inbound_evidence(id)

    %{
      header:
        render_component(&InboundDetailHeader.detail_header/1,
          detail: scenario.detail,
          account_labels: scenario.account_labels
        ),
      card:
        render_component(&EvidenceCard.evidence_card/1,
          evidence: scenario.evidence,
          reveal_state: scenario.reveal_state,
          received_at: scenario.received_at
        )
    }
  end

  defp scenario_header_text(id),
    do: id |> render_scenario() |> Map.fetch!(:header) |> rendered_text()

  defp count(text, needle), do: length(String.split(text, needle)) - 1

  # The value of one fact in the evidence card's <dl>, whitespace-collapsed.
  defp fact(card_html, label) do
    [_, value] =
      Regex.run(
        ~r/<dt[^>]*>\s*#{Regex.escape(label)}\s*<\/dt>\s*<dd[^>]*>(.*?)<\/dd>/s,
        card_html
      )

    value |> rendered_text() |> String.split() |> Enum.join(" ")
  end

  defp rendered_text(html), do: Regex.replace(~r/<[^>]*>/, html, "")
end
