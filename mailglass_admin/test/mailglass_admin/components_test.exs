defmodule MailglassAdmin.ComponentsTest do
  @moduledoc """
  Regression tests for the unified Components.status_badge/1 atom and
  Components.normalize_inbound_outcome/1 adapter.

  Covers all 24 atoms across the four frozen taxonomy tables from
  74-UI-SPEC.md: 14 outbound delivery statuses, 6 inbound message outcomes,
  4 timeline event markers, plus the normalize_inbound_outcome/1 adapter
  (Wave 0 Nyquist requirement per 76-VALIDATION.md DS-01).

  Each atom gets its own named test with three independent assertions
  (CSS class, hero-* icon, text label). No Enum.each or comprehensions over
  atom lists — per-atom named tests prevent the Pitfall-5 failure mode where
  a loop masks divergent atoms by stopping at the first failure.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MailglassAdmin.Components

  describe "status_badge/1 — outbound delivery statuses (14 atoms)" do
    test "dispatched renders badge-primary + paper-airplane icon" do
      html = render_component(&Components.status_badge/1, status: :dispatched, size: :sm)
      assert html =~ "badge-primary"
      assert html =~ "hero-paper-airplane"
      assert html =~ "Dispatched"
    end

    test "queued renders badge-primary + arrow-path icon" do
      html = render_component(&Components.status_badge/1, status: :queued, size: :sm)
      assert html =~ "badge-primary"
      assert html =~ "hero-arrow-path"
      assert html =~ "Queued"
    end

    test "sent renders badge-primary + paper-airplane icon" do
      html = render_component(&Components.status_badge/1, status: :sent, size: :sm)
      assert html =~ "badge-primary"
      assert html =~ "hero-paper-airplane"
      assert html =~ "Sent"
    end

    test "delivered renders badge-success + check-circle icon" do
      html = render_component(&Components.status_badge/1, status: :delivered, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-check-circle"
      assert html =~ "Delivered"
    end

    test "deferred renders badge-warning + exclamation-triangle icon" do
      html = render_component(&Components.status_badge/1, status: :deferred, size: :sm)
      assert html =~ "badge-warning"
      assert html =~ "hero-exclamation-triangle"
      assert html =~ "Deferred"
    end

    test "bounced renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :bounced, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Bounced"
    end

    test "failed renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :failed, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Failed"
    end

    test "rejected renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :rejected, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Rejected"
    end

    test "complained renders badge-error + exclamation-circle icon" do
      html = render_component(&Components.status_badge/1, status: :complained, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-exclamation-circle"
      assert html =~ "Complained"
    end

    test "unsubscribed renders badge-warning + bell-slash icon" do
      html = render_component(&Components.status_badge/1, status: :unsubscribed, size: :sm)
      assert html =~ "badge-warning"
      assert html =~ "hero-bell-slash"
      assert html =~ "Unsubscribed"
    end

    test "opened renders badge-success + envelope-open icon" do
      html = render_component(&Components.status_badge/1, status: :opened, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-envelope-open"
      assert html =~ "Opened"
    end

    test "clicked renders badge-success + hand-thumb-up icon" do
      html = render_component(&Components.status_badge/1, status: :clicked, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-hand-thumb-up"
      assert html =~ "Clicked"
    end

    test "autoresponded renders badge-outline + arrow-uturn-left icon" do
      html = render_component(&Components.status_badge/1, status: :autoresponded, size: :sm)
      assert html =~ "badge-outline"
      assert html =~ "hero-arrow-uturn-left"
      assert html =~ "Autoresponded"
    end

    test "unknown renders badge-outline + question-mark-circle icon" do
      html = render_component(&Components.status_badge/1, status: :unknown, size: :sm)
      assert html =~ "badge-outline"
      assert html =~ "hero-question-mark-circle"
      assert html =~ "Unknown"
    end
  end

  describe "status_badge/1 — inbound message outcomes (6 atoms)" do
    test "accepted renders badge-success + check-circle icon" do
      html = render_component(&Components.status_badge/1, status: :accepted, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-check-circle"
      assert html =~ "Accepted"
    end

    test "no_match renders badge-warning + exclamation-triangle icon" do
      html = render_component(&Components.status_badge/1, status: :no_match, size: :sm)
      assert html =~ "badge-warning"
      assert html =~ "hero-exclamation-triangle"
      assert html =~ "No match"
    end

    test "rejected (inbound) renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :rejected, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Rejected"
    end

    test "bounced (inbound) renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :bounced, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Bounced"
    end

    test "ignore renders badge-outline + minus-circle icon" do
      html = render_component(&Components.status_badge/1, status: :ignore, size: :sm)
      assert html =~ "badge-outline"
      assert html =~ "hero-minus-circle"
      assert html =~ "Ignored"
    end

    test "failed_ingest renders badge-error + exclamation-circle icon" do
      html = render_component(&Components.status_badge/1, status: :failed_ingest, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-exclamation-circle"
      assert html =~ "Ingest failed"
    end
  end

  describe "status_badge/1 — timeline event markers (4 atoms)" do
    test "webhook_replay_requested renders badge-outline + arrow-path icon" do
      html =
        render_component(&Components.status_badge/1, status: :webhook_replay_requested, size: :sm)

      assert html =~ "badge-outline"
      assert html =~ "hero-arrow-path"
      assert html =~ "Replay requested"
    end

    test "webhook_replay_succeeded renders badge-success + check-circle icon (conflict resolution 4)" do
      html =
        render_component(&Components.status_badge/1, status: :webhook_replay_succeeded, size: :sm)

      assert html =~ "badge-success"
      assert html =~ "hero-check-circle"
      assert html =~ "Replay succeeded"
    end

    test "webhook_replay_failed renders badge-error + x-circle icon" do
      html =
        render_component(&Components.status_badge/1, status: :webhook_replay_failed, size: :sm)

      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Replay failed"
    end

    test "reconciled renders badge-warning + exclamation-triangle icon" do
      html = render_component(&Components.status_badge/1, status: :reconciled, size: :sm)
      assert html =~ "badge-warning"
      assert html =~ "hero-exclamation-triangle"
      assert html =~ "Reconciled"
    end
  end

  describe "normalize_inbound_outcome/1" do
    test "maps :accept to :accepted" do
      assert Components.normalize_inbound_outcome(:accept) == :accepted
    end

    test "maps :reject to :rejected" do
      assert Components.normalize_inbound_outcome(:reject) == :rejected
    end

    test "maps :bounce to :bounced" do
      assert Components.normalize_inbound_outcome(:bounce) == :bounced
    end

    test "passes :no_match through unchanged" do
      assert Components.normalize_inbound_outcome(:no_match) == :no_match
    end

    test "passes :ignore through unchanged" do
      assert Components.normalize_inbound_outcome(:ignore) == :ignore
    end

    test "passes nil through unchanged" do
      assert Components.normalize_inbound_outcome(nil) == nil
    end
  end

  describe "nav_link/1 primitive contract" do
    test "active/current nav_link renders aria-current page, icon, visible label, and non-color cue" do
      html =
        render_component(&Components.nav_link/1,
          label: "Deliveries",
          icon: "hero-paper-airplane",
          href: "/ops/mail",
          active: true
        )

      assert_all(html, [
        ~s(aria-current="page"),
        "hero-paper-airplane",
        ">Deliveries</span>",
        "border-primary",
        "font-bold"
      ])
    end

    test "inactive nav_link omits aria-current and keeps hover-ready class contract" do
      html =
        render_component(&Components.nav_link/1,
          label: "Inbound",
          icon: "hero-inbox-arrow-down",
          href: "/ops/mail/inbound"
        )

      refute html =~ ~s(aria-current="page")
      assert_all(html, ["hover:bg-base-100/60", "hover:text-base-content", "text-secondary"])
    end

    test "disabled nav_link has aria-disabled true and no LiveView navigation attribute" do
      html =
        render_component(&Components.nav_link/1,
          label: "Inbound unavailable",
          icon: "hero-inbox-arrow-down",
          href: "/ops/mail/inbound",
          disabled: true
        )

      assert html =~ ~s(aria-disabled="true")
      refute html =~ "data-phx-link"
      refute html =~ ~s(href=)
    end

    test "nav_link exposes focus-visible token contract" do
      html =
        render_component(&Components.nav_link/1,
          label: "Deliveries",
          icon: "hero-paper-airplane",
          href: "/ops/mail"
        )

      assert html =~ "mg-focus-ring"
    end

    test "nav_link long-content state truncates with a title" do
      label = "Deliveries with exceptionally long operator context"

      html =
        render_component(&Components.nav_link/1,
          label: label,
          icon: "hero-paper-airplane",
          href: "/ops/mail"
        )

      assert html =~ ~s(title="#{label}")
      assert html =~ "truncate"
    end

    test "nav_link loading not applicable in Phase 110" do
      html =
        render_component(&Components.nav_link/1,
          label: "Deliveries",
          icon: "hero-paper-airplane",
          href: "/ops/mail"
        )

      refute html =~ "aria-busy"
      refute html =~ "Resolving"
    end
  end

  describe "nav_pill/1 primitive contract" do
    test "active/current nav_pill renders aria-current page and selected cue" do
      html =
        render_component(&Components.nav_pill/1,
          label: "Deliveries",
          href: "/ops/mail",
          active: true
        )

      assert_all(html, [
        ~s(aria-current="page"),
        "bg-primary/10",
        "font-bold",
        ">Deliveries</span>"
      ])
    end

    test "inactive nav_pill omits aria-current and keeps hover-ready class contract" do
      html = render_component(&Components.nav_pill/1, label: "Inbound", href: "/ops/mail/inbound")

      refute html =~ ~s(aria-current="page")
      assert_all(html, ["text-secondary", "hover:text-base-content"])
    end

    test "disabled nav_pill has aria-disabled true and no LiveView navigation attribute" do
      html =
        render_component(&Components.nav_pill/1,
          label: "Inbound unavailable",
          href: "/ops/mail/inbound",
          disabled: true
        )

      assert html =~ ~s(aria-disabled="true")
      refute html =~ "data-phx-link"
      refute html =~ ~s(href=)
    end

    test "nav_pill exposes focus-visible token contract" do
      html = render_component(&Components.nav_pill/1, label: "Deliveries", href: "/ops/mail")

      assert html =~ "mg-focus-ring"
    end

    test "nav_pill long-content state truncates with a title" do
      label = "Inbound records with an intentionally long label"
      html = render_component(&Components.nav_pill/1, label: label, href: "/ops/mail/inbound")

      assert html =~ ~s(title="#{label}")
      assert html =~ "truncate"
    end

    test "nav_pill loading not applicable in Phase 110" do
      html = render_component(&Components.nav_pill/1, label: "Inbound", href: "/ops/mail/inbound")

      refute html =~ "aria-busy"
      refute html =~ "Resolving"
    end
  end

  describe "tenant_chip/1 primitive contract" do
    test "tenant_chip with tenant renders icon and read-only tenant text" do
      html = render_component(&Components.tenant_chip/1, tenant: "tenant-alpha")

      assert_all(html, [
        "hero-building-office-2",
        "tenant-alpha",
        "Tenant currently in view: tenant-alpha"
      ])

      refute html =~ "phx-click"
    end

    test "tenant_chip no tenant renders explicit empty state copy" do
      html = render_component(&Components.tenant_chip/1, tenant: nil)

      assert html =~ "No tenant selected"
      assert html =~ ~s(title="Tenant currently in view")
    end

    test "tenant_chip long tenant ID truncates with title" do
      tenant = "tenant-00000000-1111-2222-3333-444444444444"
      html = render_component(&Components.tenant_chip/1, tenant: tenant)

      assert html =~ ~s(title="Tenant currently in view: #{tenant}")
      assert html =~ "truncate"
    end

    test "tenant_chip supports non-ASCII tenant text" do
      html = render_component(&Components.tenant_chip/1, tenant: "Muenchen-Tokyo-テナント")

      assert html =~ "Muenchen-Tokyo-テナント"
    end

    test "tenant_chip read-only non-loading applicability is explicit" do
      html = render_component(&Components.tenant_chip/1, tenant: "tenant-alpha")

      refute html =~ "aria-busy"
      refute html =~ "Resolving"
      refute html =~ "tabindex"
      refute html =~ ~s(role="button")
    end
  end

  describe "theme_picker/1 primitive contract" do
    test "theme_picker system selected renders fieldset legend and exactly three radio inputs" do
      html = render_component(&Components.theme_picker/1, selected: :system)

      assert_all(html, ["<fieldset", "<legend", "Theme", "System", "Light", "Dark"])
      assert radio_count(html) == 3
      assert html =~ ~r/value="system"[^>]*checked/
    end

    test "theme_picker light selected checks the light radio" do
      html = render_component(&Components.theme_picker/1, selected: :light)

      assert html =~ ~r/value="light"[^>]*checked/
    end

    test "theme_picker dark selected checks the dark radio" do
      html = render_component(&Components.theme_picker/1, selected: :dark)

      assert html =~ ~r/value="dark"[^>]*checked/
    end

    test "theme_picker disabled state disables the fieldset and option radios" do
      html = render_component(&Components.theme_picker/1, selected: :system, disabled: true)

      assert html =~ "<fieldset"
      assert html =~ "disabled"
      assert radio_count(html) == 3
    end

    test "theme_picker hover-ready and focus-visible option contracts are present" do
      html = render_component(&Components.theme_picker/1, selected: :system)

      assert_all(html, [
        "hover:bg-base-100",
        "hover:text-base-content",
        "mg-focus-ring",
        "min-h-11",
        "min-w-11"
      ])
    end

    test "theme_picker event passthrough renders set_theme phx-click and per-option values" do
      html = render_component(&Components.theme_picker/1, selected: :system, event: "set_theme")

      assert html =~ ~s(phx-click="set_theme")

      assert_all(html, [
        ~s(phx-value-theme="system"),
        ~s(phx-value-theme="light"),
        ~s(phx-value-theme="dark")
      ])
    end

    test "theme_picker uses native radios and no aria-pressed toggle buttons" do
      html = render_component(&Components.theme_picker/1, selected: :system)

      assert radio_count(html) == 3
      refute html =~ "aria-pressed"
      refute html =~ ~s(data-theme="system")
      refute html =~ "localStorage"
      refute html =~ "matchMedia"
    end

    test "theme_picker loading not applicable in Phase 110" do
      html = render_component(&Components.theme_picker/1, selected: :system)

      refute html =~ "aria-busy"
      refute html =~ "Resolving"
    end
  end

  describe "stat_card/1 primitive contract" do
    test "stat_card neutral severity renders icon plus visible label plus semantic color" do
      html =
        render_component(&Components.stat_card/1,
          label: "All clear",
          value: 0,
          severity: :neutral
        )

      assert_stat_markers(html, "hero-minus-circle", "All clear", "text-secondary")
    end

    test "stat_card info severity renders icon plus visible label plus semantic color" do
      html =
        render_component(&Components.stat_card/1, label: "Queued", value: 12, severity: :info)

      assert_stat_markers(html, "hero-question-mark-circle", "Info", "text-primary")
    end

    test "stat_card success severity renders icon plus visible label plus semantic color" do
      html =
        render_component(&Components.stat_card/1,
          label: "Delivered",
          value: 144,
          severity: :success
        )

      assert_stat_markers(html, "hero-check-circle", "Healthy", "text-success")
    end

    test "stat_card warning severity renders icon plus visible label plus semantic color" do
      html =
        render_component(&Components.stat_card/1, label: "Deferred", value: 3, severity: :warning)

      assert_stat_markers(html, "hero-exclamation-triangle", "Needs attention", "text-warning")
    end

    test "stat_card error severity renders icon plus visible label plus semantic color" do
      html =
        render_component(&Components.stat_card/1, label: "Failed", value: 2, severity: :error)

      assert_stat_markers(html, "hero-x-circle", "Problem", "text-error")
    end

    test "stat_card empty/no-data state renders meaningful copy" do
      html = render_component(&Components.stat_card/1, label: "Events", value: nil, state: :empty)

      assert html =~ "No data yet"
      refute html =~ ">—<"
    end

    test "stat_card loading/resolving state is applicable and exposes aria-busy" do
      html =
        render_component(&Components.stat_card/1,
          label: "Delivery health",
          state: :loading,
          severity: :info
        )

      assert html =~ ~s(aria-busy="true")
      assert html =~ "Resolving"
    end

    test "stat_card unavailable state renders explicit unavailable copy" do
      html =
        render_component(&Components.stat_card/1,
          label: "Provider status",
          state: :unavailable,
          severity: :error
        )

      assert html =~ "Unavailable"
      assert html =~ "Problem"
    end

    test "stat_card long-label state truncates with title" do
      label = "Delivery health metric with an intentionally long descriptive label"

      html =
        render_component(&Components.stat_card/1, label: label, value: 42, severity: :success)

      assert html =~ ~s(title="#{label}")
      assert html =~ "truncate"
    end

    test "stat_card long-value state is tabular and whitespace-nowrap with title" do
      value = "123456789012345678901234567890"

      html =
        render_component(&Components.stat_card/1,
          label: "Volume",
          value: value,
          severity: :neutral
        )

      assert_all(html, ["tabular-nums", "whitespace-nowrap", ~s(title="#{value}")])
    end

    test "stat_card is non-interactive unless a future attr makes it actionable" do
      html =
        render_component(&Components.stat_card/1, label: "Volume", value: 1, severity: :neutral)

      refute html =~ "phx-click"
      refute html =~ "tabindex"
      refute html =~ ~s(role="button")
    end
  end

  describe "filter_field/1 and filter_section/1 primitive contract" do
    test "filter_section renders a fieldset with visible legend and slotted fields" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Components.filter_section title="Filters">
          <p data-testid="slotted-filter-field">Status field</p>
        </Components.filter_section>
        """)

      assert_all(html, ["<fieldset", "<legend", "Filters", ~s(data-testid="slotted-filter-field")])
    end

    test "filter_field text input connects label, help, error, invalid state, and form metadata" do
      form = filters_form(%{"status" => "deferred"})

      html =
        render_component(&Components.filter_field/1,
          field: form[:status],
          type: :text,
          label: "Status",
          help: "Filter deliveries by delivery status.",
          error: "Status was not applied. Choose a listed status."
        )

      assert_all(html, [
        ~s(<label for="filters_status"),
        ~s(id="filters_status"),
        ~s(name="filters[status]"),
        ~s(value="deferred"),
        ~s(id="filters_status-help"),
        ~s(id="filters_status-error"),
        ~s(aria-describedby="filters_status-help filters_status-error"),
        ~s(aria-invalid="true"),
        "Filter deliveries by delivery status.",
        "Action needed",
        "Status was not applied. Choose a listed status."
      ])
    end
  end

  defp assert_all(html, markers) do
    Enum.each(markers, fn marker -> assert html =~ marker end)
  end

  defp assert_stat_markers(html, icon, label, color_class) do
    assert_all(html, [icon, label, color_class, "tabular-nums", "whitespace-nowrap"])
  end

  defp radio_count(html), do: length(Regex.scan(~r/type="radio"/, html))

  defp filters_form(params) do
    Phoenix.HTML.FormData.to_form(params, as: :filters)
  end
end
