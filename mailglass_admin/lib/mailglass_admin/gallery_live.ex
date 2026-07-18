defmodule MailglassAdmin.GalleryLive do
  @moduledoc """
  Dev-only component gallery at /dev/mail/gallery.

  Renders every shared component × every state × light, dark, and inherited-theme side-by-side
  from an in-code specimen list. No DB access. No mailable scan. No
  __preview_session__ assigns.

  Each specimen cell is anchored with a stable `data-testid="gallery-{component}-{state}"`
  and contains `data-theme="mailglass-light"`, `data-theme="mailglass-dark"`, and
  no-explicit-theme system wrappers so a single structural assertion covers all theme modes.

  Route: /dev/mail/gallery (mounted inside the preview live_session — dev-only by
  the adopter's `if dev_routes` wrapping).

  ## Coverage

  - icon
  - logo
  - flash (error, info, success, warning kinds)
  - badge (warning, stub)
  - status_badge (22 atoms + phantom nil)
  - nav_link, nav_pill (active, inactive, hover-ready,
    focus-visible, disabled, long-label)
  - tenant_chip (with-tenant, no-tenant, long-tenant,
    non-ascii-tenant)
  - theme_picker (system-selected, light-selected, dark-selected,
    hover-ready, focus-visible, disabled)
  - stat_card (neutral, info, success, warning, error, empty,
    loading, unavailable, long-label, long-value)
  - orientation_strip (deliveries, inbound, preview)
  - shell is the full page layout — not a gallery specimen
  - deliveries_list (populated-unselected, populated-selected, empty)
  - detail_header (shown, absent) — operator variant only
  - filters_form (empty, filled) — static assigns, no phx-submit
  - filter_field (text-empty, select-filled, invalid, disabled,
    readonly-text, readonly-select-display, section)
  - filters_form (empty, filled, invalid) — static assigns, no phx-submit
  - support_cards (tier1-shown, tier1-hidden)
  - suppression_card (present, absent)
  - timeline (populated, highlighted-event, empty, single, mixed-tones, many)
  - replay_modal (closed) — open states require live event
  - routing_trace (empty, all-passing, first-failing)
  - evidence_card (no-evidence, redacted, revealed, denied)
  - device_frame (inactive-btn)
  - tabs (inactive-tab)
  - sidebar (mailable-collapsed, mailable-expanded, scenario-active)
  - data_state (empty, error, permission-denied, stale)
  - deliveries_list-table (populated table/cards, data-state, long-value stress)
  - records_list-table (populated table/cards, data-state, long-value stress)
  - fjordline_stress (non-ascii-names, long-id, long-mailable, nil-reject) —
    library-pure mirrors of the `fjordline-aps` persona edge values (RATCHET-02)

  ## fjordline-aps persona mirror (RATCHET-02 / 116-04)

  The `:fjordline_stress` specimens reproduce — with the EXACT literals the
  `fjordline-aps` demo persona uses (`MailglassDemo.Personas.specimen_literals/0`,
  plan 116-01) — the four non-ASCII / long-ID / long-module-name / nil-reject edge
  values so the persona drift-guard (`persona_drift_guard_test.exs`) stays green.
  The literals are inlined here as source text (NOT a runtime call) because the
  persona spec is compiled only into the admin `:test` build, never `:dev`/prod —
  the dev gallery route cannot reference it. The drift-guard reads this file as
  text and asserts byte-consistency with the spec. Long values use
  `truncate`/`overflow-hidden text-ellipsis` at weight 400 so they never overflow.

  Boundary classification: submodule auto-classifies into the
  `MailglassAdmin` root boundary.
  """

  use Phoenix.LiveView

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.Shell
  alias MailglassAdmin.Operator.DeliveriesList
  alias MailglassAdmin.Operator.DetailHeader
  alias MailglassAdmin.Operator.FiltersForm
  alias MailglassAdmin.Operator.SupportCards
  alias MailglassAdmin.Operator.SuppressionCard
  alias MailglassAdmin.Operator.Timeline
  alias MailglassAdmin.Operator.ReplayModal
  alias MailglassAdmin.Inbound.RecordsList
  alias MailglassAdmin.Inbound.RoutingTrace
  alias MailglassAdmin.Inbound.EvidenceCard
  alias MailglassAdmin.Preview.DeviceFrame
  alias MailglassAdmin.Preview.Tabs
  alias MailglassAdmin.Preview.Sidebar

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "mailglass — Component Gallery")
      |> assign(:specimens, specimens())

    {:ok, socket}
  end

  # The gallery is a static, dev-only audit surface: it renders live components
  # (deliveries_list rows, evidence_card reveal, replay_modal close, etc.) purely
  # for visual inspection. Those components emit their own phx-click handlers, so a
  # human clicking a specimen would otherwise raise and tear down the LiveView. This
  # catch-all absorbs every specimen interaction as an intentional no-op.
  @impl true
  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content px-md py-xl">
      <h1 class="text-display font-bold tracking-tight text-base-content mb-lg">
        Component Gallery
      </h1>

      <div class="space-y-3xl">
        <%= for {component, states} <- grouped_specimens(@specimens) do %>
          <section>
            <h2 class="text-heading font-bold tracking-tight text-base-content mb-lg">
              {component_label(component)}
            </h2>
            <div class="grid gap-lg">
              <%= for {state, assigns_map} <- states do %>
                <div
                  data-testid={"gallery-#{component}-#{state}"}
                  class="rounded-box border border-base-300 bg-base-200 p-md space-y-sm"
                >
                  <p class="text-label font-bold text-secondary">
                    {component_label(component)} — {state}
                  </p>
                  <!-- Theme wrappers stack full-width below md and only share a
                       row at md+ so each wrapper gets the full cell width at the
                       320/390 matrix floors — card-based specimens (timeline,
                       tables) need the full width to fit (RATCHET-02 overflow
                       gate). flex-1 at narrow widths gave ~88px columns that no
                       card layout fits. -->
                  <div class="flex flex-col gap-md md:flex-row md:flex-wrap">
                    <div
                      data-theme="mailglass-light"
                      class="rounded-field border border-base-300 bg-base-100 p-sm min-w-0 w-full md:flex-1"
                    >
                      <.render_specimen
                        component={component}
                        assigns_map={assigns_map}
                        specimen_id={"#{component}-#{state}-light"}
                      />
                    </div>
                    <div
                      data-theme="mailglass-dark"
                      class="rounded-field border border-base-300 bg-base-100 p-sm min-w-0 w-full md:flex-1"
                    >
                      <.render_specimen
                        component={component}
                        assigns_map={assigns_map}
                        specimen_id={"#{component}-#{state}-dark"}
                      />
                    </div>
                    <div
                      data-testid={"gallery-#{component}-#{state}-system"}
                      class="rounded-field border border-base-300 bg-base-100 p-sm min-w-0 w-full md:flex-1"
                    >
                      <.render_specimen
                        component={component}
                        assigns_map={assigns_map}
                        specimen_id={"#{component}-#{state}-system"}
                      />
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Specimen rendering dispatcher
  # ---------------------------------------------------------------------------

  defp render_specimen(%{component: :icon} = assigns) do
    ~H"""
    <Components.icon name={@assigns_map[:name]} class={@assigns_map[:class] || "w-5 h-5"} />
    """
  end

  defp render_specimen(%{component: :logo} = assigns) do
    ~H"""
    <Components.logo class={@assigns_map[:class]} />
    """
  end

  defp render_specimen(%{component: :flash} = assigns) do
    ~H"""
    <Components.flash kind={@assigns_map[:kind]} message={@assigns_map[:message]} />
    """
  end

  defp render_specimen(%{component: :badge} = assigns) do
    ~H"""
    <Components.badge variant={@assigns_map[:variant]} />
    """
  end

  defp render_specimen(%{component: :status_badge} = assigns) do
    ~H"""
    <Components.status_badge status={@assigns_map[:status]} size={@assigns_map[:size] || :sm} />
    """
  end

  defp render_specimen(%{component: :nav_link} = assigns) do
    ~H"""
    <Components.nav_link
      label={@assigns_map[:label]}
      icon={@assigns_map[:icon]}
      href={@assigns_map[:href]}
      active={@assigns_map[:active] || false}
      disabled={@assigns_map[:disabled] || false}
    />
    """
  end

  defp render_specimen(%{component: :nav_pill} = assigns) do
    ~H"""
    <Components.nav_pill
      label={@assigns_map[:label]}
      href={@assigns_map[:href]}
      active={@assigns_map[:active] || false}
      disabled={@assigns_map[:disabled] || false}
    />
    """
  end

  defp render_specimen(%{component: :tenant_chip} = assigns) do
    ~H"""
    <Components.tenant_chip tenant={@assigns_map[:tenant]} />
    """
  end

  defp render_specimen(%{component: :theme_picker} = assigns) do
    ~H"""
    <Components.theme_picker
      selected={@assigns_map[:selected] || :system}
      disabled={@assigns_map[:disabled] || false}
      event={@assigns_map[:event]}
      name={@assigns_map[:name] || "gallery_theme_#{@specimen_id}"}
    />
    """
  end

  defp render_specimen(%{component: :stat_card} = assigns) do
    ~H"""
    <Components.stat_card
      label={@assigns_map[:label]}
      value={@assigns_map[:value]}
      severity={@assigns_map[:severity] || :neutral}
      severity_label={@assigns_map[:severity_label]}
      state={@assigns_map[:state] || :ready}
      empty_text={@assigns_map[:empty_text] || "No data yet"}
      loading_text={@assigns_map[:loading_text] || "Resolving"}
      unavailable_text={@assigns_map[:unavailable_text] || "Unavailable"}
    />
    """
  end

  defp render_specimen(%{component: :orientation_strip} = assigns) do
    ~H"""
    <Shell.orientation_strip surface={@assigns_map[:surface]} />
    """
  end

  defp render_specimen(%{component: :data_state} = assigns) do
    ~H"""
    <Components.data_state
      kind={@assigns_map[:kind]}
      title={@assigns_map[:title]}
      body={@assigns_map[:body]}
    />
    """
  end

  defp render_specimen(%{component: :deliveries_list} = assigns) do
    ~H"""
    <DeliveriesList.deliveries_list
      deliveries={@assigns_map[:deliveries]}
      selected_delivery={@assigns_map[:selected_delivery]}
      data_state={@assigns_map[:data_state]}
    />
    """
  end

  defp render_specimen(%{component: :records_list} = assigns) do
    ~H"""
    <RecordsList.records_list
      records={@assigns_map[:records]}
      selected_record={@assigns_map[:selected_record]}
      data_state={@assigns_map[:data_state]}
      empty_state={@assigns_map[:empty_state] || :truly_empty}
    />
    """
  end

  defp render_specimen(%{component: :detail_header} = assigns) do
    ~H"""
    <DetailHeader.detail_header
      delivery={@assigns_map[:delivery]}
      replay_targets={@assigns_map[:replay_targets]}
      latest_replay={@assigns_map[:latest_replay]}
    />
    """
  end

  defp render_specimen(%{component: :filter_field} = assigns) do
    ~H"""
    <Components.filter_field
      field={@assigns_map[:field]}
      type={@assigns_map[:type] || :text}
      label={@assigns_map[:label]}
      help={@assigns_map[:help]}
      error={@assigns_map[:error]}
      options={@assigns_map[:options] || []}
      prompt={@assigns_map[:prompt]}
      disabled={@assigns_map[:disabled] || false}
      readonly={@assigns_map[:readonly] || false}
      display_value={@assigns_map[:display_value]}
      submit_readonly={Map.get(@assigns_map, :submit_readonly, true)}
      placeholder={@assigns_map[:placeholder]}
    />
    """
  end

  defp render_specimen(%{component: :filter_section} = assigns) do
    ~H"""
    <Components.filter_section title={@assigns_map[:title]} description={@assigns_map[:description]}>
      <p class="text-label text-secondary">{@assigns_map[:body]}</p>
    </Components.filter_section>
    """
  end

  defp render_specimen(%{component: :filters_form} = assigns) do
    ~H"""
    <FiltersForm.fields
      form={@assigns_map[:form]}
      event_values={@assigns_map[:event_values]}
      window_options={@assigns_map[:window_options]}
      errors={@assigns_map[:errors] || %{}}
    />
    """
  end

  defp render_specimen(%{component: :support_cards} = assigns) do
    ~H"""
    <SupportCards.support_cards
      support_summary={@assigns_map[:support_summary]}
      support_state={@assigns_map[:support_state]}
      suppression_count={@assigns_map[:suppression_count]}
    />
    """
  end

  defp render_specimen(%{component: :suppression_card} = assigns) do
    ~H"""
    <SuppressionCard.suppression_card suppression_state={@assigns_map[:suppression_state]} />
    """
  end

  defp render_specimen(%{component: :timeline} = assigns) do
    ~H"""
    <Timeline.timeline
      timeline_events={@assigns_map[:timeline_events]}
      highlight_event_id={@assigns_map[:highlight_event_id]}
    />
    """
  end

  defp render_specimen(%{component: :replay_modal} = assigns) do
    ~H"""
    <ReplayModal.replay_modal
      open?={@assigns_map[:open?]}
      delivery={@assigns_map[:delivery]}
      replay_targets={@assigns_map[:replay_targets]}
      selected_target_id={@assigns_map[:selected_target_id]}
    />
    """
  end

  defp render_specimen(%{component: :routing_trace} = assigns) do
    ~H"""
    <RoutingTrace.routing_trace trace={@assigns_map[:trace]} />
    """
  end

  defp render_specimen(%{component: :evidence_card} = assigns) do
    ~H"""
    <EvidenceCard.evidence_card
      evidence={@assigns_map[:evidence]}
      reveal_state={@assigns_map[:reveal_state]}
      can_reveal?={Map.get(@assigns_map, :can_reveal?, true)}
    />
    """
  end

  defp render_specimen(%{component: :device_frame} = assigns) do
    ~H"""
    <DeviceFrame.device_frame device_width={@assigns_map[:device_width]} />
    """
  end

  defp render_specimen(%{component: :tabs} = assigns) do
    ~H"""
    <Tabs.tabs
      active_tab={@assigns_map[:active_tab]}
      html_body={@assigns_map[:html_body] || ""}
      text_body={@assigns_map[:text_body] || ""}
      raw_envelope={@assigns_map[:raw_envelope] || ""}
      headers={@assigns_map[:headers] || []}
      device_width={@assigns_map[:device_width] || 768}
      render_nonce={@assigns_map[:render_nonce] || 1}
    />
    """
  end

  defp render_specimen(%{component: :sidebar} = assigns) do
    ~H"""
    <Sidebar.sidebar
      mailables={@assigns_map[:mailables]}
      current_mailable={@assigns_map[:current_mailable]}
      current_scenario={@assigns_map[:current_scenario]}
      device_width={@assigns_map[:device_width] || 768}
    />
    """
  end

  # ---------------------------------------------------------------------------
  # Composed-group specimens (D-10) — the dispatcher DELEGATES to the public
  # composed_*/1 fns below so the gallery route and the plan-04 Floki proof
  # (`render_component(&GalleryLive.composed_*/1, %{})`) render the IDENTICAL
  # tree. These specimens are structural / data-free; the per-primitive `awk`
  # dispatcher assertion does NOT apply to them (different shape, RESEARCH).
  # ---------------------------------------------------------------------------

  defp render_specimen(%{component: :composed_support_triage} = assigns) do
    ~H"""
    <div data-testid="gallery-composed-support-triage">
      <.composed_support_triage />
    </div>
    """
  end

  defp render_specimen(%{component: :composed_routing_evidence} = assigns) do
    ~H"""
    <div data-testid="gallery-composed-routing-evidence">
      <.composed_routing_evidence />
    </div>
    """
  end

  defp render_specimen(%{component: :composed_detail_timeline} = assigns) do
    ~H"""
    <div data-testid="gallery-composed-detail-timeline">
      <.composed_detail_timeline />
    </div>
    """
  end

  # fjordline-aps persona mirror (RATCHET-02). The :delivered / reject_reason: nil
  # edge renders the SAME timeline component the live view uses (no extra
  # wrapping div — the timeline card has its own min-content floor and must sit
  # directly in the full-width cell to stay overflow-clean, matching the existing
  # gallery-timeline-* specimens). The branch is selected by an :event key.
  defp render_specimen(%{component: :fjordline_stress, assigns_map: %{event: event}} = assigns)
       when not is_nil(event) do
    ~H"""
    <Timeline.timeline
      timeline_events={[@assigns_map[:event]]}
      highlight_event_id={@assigns_map[:highlight_event_id]}
    />
    """
  end

  # The non-ASCII-names / long-ID / long-mailable edges are plain text values.
  # Long values carry `truncate`/`overflow-hidden text-ellipsis` at weight 400 so
  # the matrix resize loop (gallery-matrix.spec.js) proves zero horizontal
  # overflow at every width × theme. The inlined literals are the EXACT spec
  # values (see the module doc for why this is source text, not a runtime call).
  defp render_specimen(%{component: :fjordline_stress} = assigns) do
    ~H"""
    <div class="min-w-0 space-y-sm">
      <p class="text-label font-bold uppercase text-secondary truncate" title={@assigns_map[:caption]}>
        {@assigns_map[:caption]}
      </p>
      <%= for line <- @assigns_map[:lines] do %>
        <p
          class="text-body font-normal text-base-content truncate overflow-hidden text-ellipsis"
          title={line}
        >
          {line}
        </p>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Public composed-group functions (D-10) — capturable as
  # `&MailglassAdmin.GalleryLive.composed_*/1`. Each wraps `<div data-region>`
  # around calls to the SAME group-assembling component functions the live
  # views call (operator_live.ex / inbound_live.ex), in the SAME order — NEVER
  # a hand-copied HEEx tree (Pitfall 5). They take bare assigns and supply their
  # own data-free / minimal structural assigns so a render-time proof can
  # capture them with `%{}`. The `data-group-card` lands on each group's outer
  # shell once plan 03 swaps `<.card>` into the group modules.
  # ---------------------------------------------------------------------------

  @doc false
  # Operator detail column: detail_header + support_cards + timeline + suppression_card
  # (operator_live.ex:579-593 order).
  def composed_support_triage(assigns) do
    assigns =
      assigns
      |> assign(:suppression_state, nil)
      |> assign(:latest_replay, nil)
      |> assign(:highlight_event_id, nil)
      |> assign(:delivery, %{
        id: "del_01JXABCDEF",
        recipient: "j*@e******.com",
        status: :delivered,
        mailable: "MyApp.WelcomeMailer",
        tenant_id: "acme-corp",
        provider: "postmark",
        stream: :transactional,
        last_event_type: :delivered,
        last_event_at: ~U[2026-06-14 12:00:00Z],
        provider_message_id: "msg_abc123"
      })

    ~H"""
    <div data-region class="space-y-4">
      <DetailHeader.detail_header
        delivery={@delivery}
        replay_targets={%{status: :unavailable, reason: :no_webhook}}
        latest_replay={@latest_replay}
      />
      <SupportCards.support_cards
        support_summary={
          %{
            failed_ingest: %{count: 0, latest: nil},
            orphan_backlog: %{count: 0, oldest: nil},
            replay_outcomes: %{counts: %{failed: 0, noop: 0, replayed: 0}, latest: nil},
            reconcile_facts: %{
              reconciled_count: 0,
              still_unmatched_count: 0,
              latest_reconciled: nil
            }
          }
        }
        support_state={%{focused_card: nil, drilldown_banner: nil}}
        suppression_count={0}
      />
      <Timeline.timeline timeline_events={[]} highlight_event_id={@highlight_event_id} />
      <SuppressionCard.suppression_card suppression_state={@suppression_state} />
    </div>
    """
  end

  @doc false
  # Inbound routing+evidence group: routing_trace + evidence_card
  # (inbound_live.ex:493-500 routing/evidence pairing).
  def composed_routing_evidence(assigns) do
    assigns = assign(assigns, :evidence, nil)

    ~H"""
    <div data-region class="space-y-4">
      <RoutingTrace.routing_trace trace={[]} />
      <EvidenceCard.evidence_card evidence={@evidence} reveal_state={:redacted} can_reveal?={true} />
    </div>
    """
  end

  @doc false
  # Inbound detail column head: inbound detail_header + inbound timeline
  # (inbound_live.ex:491-492 order).
  def composed_detail_timeline(assigns) do
    assigns =
      assign(assigns, :detail, %{
        record: %{
          id: "rec-1",
          tenant_id: "tenant-a",
          provider: "mailgun",
          envelope_recipient: "a****@e******.com",
          subject: "Hello",
          received_at: ~U[2026-05-24 10:00:00Z]
        },
        mailbox: "MyApp.SupportMailbox",
        outcome: :accept,
        outcome_reason: nil,
        evidence: nil
      })

    ~H"""
    <div data-region class="space-y-4">
      <MailglassAdmin.Inbound.DetailHeader.detail_header detail={@detail} />
      <MailglassAdmin.Inbound.Timeline.timeline runs={[]} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Specimen list — one entry per STATE-LD row × state atom
  # ---------------------------------------------------------------------------

  @specimens [
    # STATE-LD-01: icon — rest (aria-hidden always)
    {:icon, "rest", %{name: "hero-envelope", class: "w-5 h-5"}},

    # STATE-LD-02: logo — rest (role="img" aria-label="mailglass")
    {:logo, "rest", %{class: nil}},

    # STATE-LD-03: flash — four kinds
    {:flash, "error-kind",
     %{kind: :error, message: "Delivery blocked: recipient is on the suppression list"}},
    {:flash, "info-kind", %{kind: :info, message: "Reloaded: WelcomeMailer.ex"}},
    {:flash, "success-kind",
     %{kind: :success, message: "Webhook replayed: event recorded in the ledger"}},
    {:flash, "warning-kind",
     %{kind: :warning, message: "Draft only — Mailable has no preview_props/0 defined"}},

    # STATE-LD-04: badge — warning and stub
    {:badge, "warning", %{variant: :warning}},
    {:badge, "stub", %{variant: :stub}},

    # STATE-LD-05: status_badge — 22 atoms + phantom nil
    {:status_badge, "dispatched", %{status: :dispatched, size: :sm}},
    {:status_badge, "queued", %{status: :queued, size: :sm}},
    {:status_badge, "sent", %{status: :sent, size: :sm}},
    {:status_badge, "delivered", %{status: :delivered, size: :sm}},
    {:status_badge, "deferred", %{status: :deferred, size: :sm}},
    {:status_badge, "bounced", %{status: :bounced, size: :sm}},
    {:status_badge, "failed", %{status: :failed, size: :sm}},
    {:status_badge, "rejected", %{status: :rejected, size: :sm}},
    {:status_badge, "complained", %{status: :complained, size: :sm}},
    {:status_badge, "unsubscribed", %{status: :unsubscribed, size: :sm}},
    {:status_badge, "opened", %{status: :opened, size: :sm}},
    {:status_badge, "clicked", %{status: :clicked, size: :sm}},
    {:status_badge, "autoresponded", %{status: :autoresponded, size: :sm}},
    {:status_badge, "unknown", %{status: :unknown, size: :sm}},
    {:status_badge, "accepted", %{status: :accepted, size: :sm}},
    {:status_badge, "no_match", %{status: :no_match, size: :sm}},
    {:status_badge, "ignore", %{status: :ignore, size: :sm}},
    {:status_badge, "failed_ingest", %{status: :failed_ingest, size: :sm}},
    {:status_badge, "webhook_replay_requested", %{status: :webhook_replay_requested, size: :sm}},
    {:status_badge, "webhook_replay_succeeded", %{status: :webhook_replay_succeeded, size: :sm}},
    {:status_badge, "webhook_replay_failed", %{status: :webhook_replay_failed, size: :sm}},
    {:status_badge, "reconciled", %{status: :reconciled, size: :sm}},
    # phantom nil fallback — badge-outline
    {:status_badge, "phantom-nil", %{status: nil, size: :sm}},

    # STATE-LD-06: nav_link — active, inactive, hover-ready, focus-visible, disabled, long-label
    # loading not applicable: nav_link is immediate navigation; disabled covers unavailable navigation.
    {:nav_link, "active",
     %{label: "Deliveries", icon: "hero-paper-airplane", href: "#", active: true}},
    {:nav_link, "inactive",
     %{label: "Deliveries", icon: "hero-paper-airplane", href: "#", active: false}},
    {:nav_link, "hover-ready",
     %{label: "Inbound", icon: "hero-inbox-arrow-down", href: "#", active: false}},
    {:nav_link, "focus-visible", %{label: "Preview", icon: "hero-eye", href: "#", active: false}},
    {:nav_link, "disabled",
     %{label: "Analytics unavailable", icon: "hero-chart-bar", href: "#", disabled: true}},
    {:nav_link, "long-label",
     %{
       label: "Deliveries needing operator review before the account handoff",
       icon: "hero-paper-airplane",
       href: "#",
       active: false
     }},

    # STATE-LD-06: nav_pill — active, inactive, hover-ready, focus-visible, disabled, long-label
    # loading not applicable: nav_pill is immediate navigation; disabled covers unavailable navigation.
    {:nav_pill, "active", %{label: "All", href: "#", active: true}},
    {:nav_pill, "inactive", %{label: "All", href: "#", active: false}},
    {:nav_pill, "hover-ready", %{label: "Bounced", href: "#", active: false}},
    {:nav_pill, "focus-visible", %{label: "Deferred", href: "#", active: false}},
    {:nav_pill, "disabled", %{label: "Archived", href: "#", disabled: true}},
    {:nav_pill, "long-label",
     %{label: "Needs attention before retry window closes", href: "#", active: false}},

    # STATE-LD-07: tenant_chip — read-only with-tenant, no-tenant, long-tenant, non-ascii-tenant
    # hover/focus/disabled/loading not applicable: tenant_chip is non-interactive in Phase 110.
    {:tenant_chip, "with-tenant", %{tenant: "acme-corp"}},
    {:tenant_chip, "no-tenant", %{tenant: nil}},
    {:tenant_chip, "long-tenant",
     %{tenant: "tenant_01JXWIDEVALUE000000000000000000000000000000000000"}},
    {:tenant_chip, "non-ascii-tenant", %{tenant: "Muenchen-Tokyo-テナント"}},

    # STATE-LD-08: theme_picker — selected, hover-ready, focus-visible, disabled
    # loading not applicable: theme_picker is immediate; Phase 112 owns async persistence/no-FOUC.
    {:theme_picker, "system-selected", %{selected: :system}},
    {:theme_picker, "light-selected", %{selected: :light}},
    {:theme_picker, "dark-selected", %{selected: :dark}},
    {:theme_picker, "hover-ready", %{selected: :system}},
    {:theme_picker, "focus-visible", %{selected: :light}},
    {:theme_picker, "disabled", %{selected: :system, disabled: true}},

    # Phase 110: stat_card — severity, placeholder, loading, unavailable, and long-content states
    # hover/focus not applicable: stat_card remains non-interactive unless a future consumer makes it actionable.
    {:stat_card, "neutral", %{label: "All clear", value: "0", severity: :neutral}},
    {:stat_card, "info", %{label: "Queued", value: "12", severity: :info}},
    {:stat_card, "success", %{label: "Delivered", value: "98%", severity: :success}},
    {:stat_card, "warning", %{label: "Needs attention", value: "3", severity: :warning}},
    {:stat_card, "error", %{label: "Failed", value: "2", severity: :error}},
    {:stat_card, "empty", %{label: "Events", value: nil, state: :empty, severity: :neutral}},
    {:stat_card, "loading",
     %{
       label: "Delivery rate",
       value: nil,
       state: :loading,
       loading_text: "Loading",
       severity: :info
     }},
    {:stat_card, "unavailable",
     %{
       label: "Provider health",
       value: nil,
       state: :unavailable,
       unavailable_text: "Unavailable",
       severity: :error
     }},
    {:stat_card, "long-label",
     %{
       label: "Deliveries requiring operator review before the retry window closes",
       value: "42",
       severity: :success
     }},
    {:stat_card, "long-value",
     %{
       label: "Trace ID",
       value: "trace_01JXWIDEVALUE000000000000000000000000000000000000",
       severity: :warning
     }},

    # STATE-LD-09: orientation_strip — deliveries, inbound, preview
    {:orientation_strip, "deliveries", %{surface: :deliveries}},
    {:orientation_strip, "inbound", %{surface: :inbound}},
    {:orientation_strip, "preview", %{surface: :preview}},

    # STATE-LD-11: deliveries_list — populated-unselected, populated-selected, empty
    {:deliveries_list, "populated-unselected",
     %{
       deliveries: [
         %{
           id: "del_01JXABCDEF",
           recipient: "j*@e******.com",
           status: :delivered,
           tenant_id: "acme-corp",
           provider: "postmark",
           last_event_type: :delivered,
           last_event_at: ~U[2026-06-14 12:00:00Z]
         },
         %{
           id: "del_01JXGHIJKL",
           recipient: "a*@m****.io",
           status: :bounced,
           tenant_id: "acme-corp",
           provider: "sendgrid",
           last_event_type: :bounced,
           last_event_at: ~U[2026-06-14 11:45:00Z]
         }
       ],
       selected_delivery: nil
     }},
    {:deliveries_list, "populated-selected",
     %{
       deliveries: [
         %{
           id: "del_01JXABCDEF",
           recipient: "j*@e******.com",
           status: :delivered,
           tenant_id: "acme-corp",
           provider: "postmark",
           last_event_type: :delivered,
           last_event_at: ~U[2026-06-14 12:00:00Z]
         },
         %{
           id: "del_01JXGHIJKL",
           recipient: "a*@m****.io",
           status: :bounced,
           tenant_id: "acme-corp",
           provider: "sendgrid",
           last_event_type: :bounced,
           last_event_at: ~U[2026-06-14 11:45:00Z]
         }
       ],
       selected_delivery: %{id: "del_01JXABCDEF"}
     }},
    {:deliveries_list, "empty", %{deliveries: [], selected_delivery: nil}},

    # STATE-LD-12: detail_header — shown (operator variant only for gallery)
    {:detail_header, "shown",
     %{
       delivery: %{
         id: "del_01JXABCDEF",
         recipient: "j*@e******.com",
         status: :delivered,
         mailable: "MyApp.WelcomeMailer",
         tenant_id: "acme-corp",
         provider: "postmark",
         stream: :transactional,
         last_event_type: :delivered,
         last_event_at: ~U[2026-06-14 12:00:00Z],
         provider_message_id: "msg_abc123"
       },
       replay_targets: %{status: :unavailable, reason: :no_webhook},
       latest_replay: nil
     }},

    # Phase 111: filter_field — text-empty, select-filled, invalid, disabled,
    # readonly-text, readonly-select-display
    {:filter_field, "text-empty",
     %{
       field:
         Phoenix.HTML.FormData.to_form(
           %{"provider" => ""},
           as: :gallery_filter_field,
           id: "gallery-filter-field-text-empty-form"
         )[:provider],
       type: :text,
       label: "Provider",
       help: "Filter by provider key, for example postmark.",
       placeholder: "postmark"
     }},
    {:filter_field, "select-filled",
     %{
       field:
         Phoenix.HTML.FormData.to_form(
           %{"status" => "delivered"},
           as: :gallery_filter_field,
           id: "gallery-filter-field-select-filled-form"
         )[:status],
       type: :select,
       label: "Status",
       help: "Filter by delivery status.",
       prompt: "Any status",
       options: [{"Delivered", "delivered"}, {"Bounced", "bounced"}]
     }},
    {:filter_field, "invalid",
     %{
       field:
         Phoenix.HTML.FormData.to_form(
           %{"status" => "unknown"},
           as: :gallery_filter_field,
           id: "gallery-filter-field-invalid-form"
         )[:status],
       type: :select,
       label: "Status",
       help: "Filter by delivery status.",
       error: "Status was not applied. Choose a listed status.",
       prompt: "Any status",
       options: [{"Delivered", "delivered"}, {"Bounced", "bounced"}]
     }},
    {:filter_field, "disabled",
     %{
       field:
         Phoenix.HTML.FormData.to_form(
           %{"provider" => "postmark"},
           as: :gallery_filter_field,
           id: "gallery-filter-field-disabled-form"
         )[:provider],
       type: :text,
       label: "Provider",
       help: "Filter by provider key, for example postmark.",
       disabled: true
     }},
    {:filter_field, "readonly-text",
     %{
       field:
         Phoenix.HTML.FormData.to_form(
           %{"provider" => "postmark"},
           as: :gallery_filter_field,
           id: "gallery-filter-field-readonly-text-form"
         )[:provider],
       type: :text,
       label: "Provider",
       help: "Filter by provider key, for example postmark.",
       readonly: true
     }},
    {:filter_field, "readonly-select-display",
     %{
       field:
         Phoenix.HTML.FormData.to_form(
           %{"status" => "delivered"},
           as: :gallery_filter_field,
           id: "gallery-filter-field-readonly-select-display-form"
         )[:status],
       type: :select,
       label: "Status",
       help: "Filter by delivery status.",
       readonly: true,
       display_value: "Delivered",
       options: [{"Delivered", "delivered"}, {"Bounced", "bounced"}]
     }},

    # Phase 111: filter_section — section
    {:filter_section, "section",
     %{
       title: "Filters",
       description: "Group related controls under one legend.",
       body:
         "The legend stays visible, and the grouped fields below inherit the shared form contract."
     }},

    # STATE-LD-13: filters_form — empty and filled (static assigns, no phx-submit)
    {:filters_form, "empty",
     %{
       form:
         Phoenix.HTML.FormData.to_form(
           %{
             "tenant_id" => "",
             "provider" => "",
             "status" => "",
             "event" => "",
             "window_hours" => "24"
           },
           as: :filters,
           id: "gallery-filters-empty"
         ),
       status_values: [:delivered, :bounced, :deferred],
       event_values: [:delivered, :bounced],
       window_options: [{"Last 24 hours", "24"}, {"Last 7 days", "168"}]
     }},
    {:filters_form, "filled",
     %{
       form:
         Phoenix.HTML.FormData.to_form(
           %{
             "tenant_id" => "acme-corp",
             "provider" => "postmark",
             "status" => "delivered",
             "event" => "",
             "window_hours" => "168"
           },
           as: :filters,
           id: "gallery-filters-filled"
         ),
       status_values: [:delivered, :bounced, :deferred],
       event_values: [:delivered, :bounced],
       window_options: [{"Last 24 hours", "24"}, {"Last 7 days", "168"}]
     }},
    {:filters_form, "invalid",
     %{
       form:
         Phoenix.HTML.FormData.to_form(
           %{
             "tenant_id" => "tenant-123",
             "provider" => "postmark",
             "status" => "unknown",
             "event" => "delivered",
             "window_hours" => "168"
           },
           as: :filters,
           id: "gallery-filters-invalid"
         ),
       status_values: [:delivered, :bounced, :deferred],
       event_values: [:delivered, :bounced],
       window_options: [{"Last 24 hours", "24"}, {"Last 7 days", "168"}],
       errors: %{"event" => "Status was not applied. Choose a listed status."}
     }},

    # STATE-LD-14: support_cards — tier1-shown and tier1-hidden
    {:support_cards, "tier1-shown",
     %{
       support_summary: %{
         failed_ingest: %{
           count: 3,
           latest: %{
             provider_event_id: "evt_abc123",
             webhook_event_id: "whe_xyz789"
           }
         },
         orphan_backlog: %{count: 0, oldest: nil},
         replay_outcomes: %{
           counts: %{failed: 0, noop: 0, replayed: 0},
           latest: nil
         },
         reconcile_facts: %{
           reconciled_count: 0,
           still_unmatched_count: 0,
           latest_reconciled: nil
         }
       },
       support_state: %{focused_card: nil, drilldown_banner: nil},
       suppression_count: 2
     }},
    {:support_cards, "tier1-hidden",
     %{
       support_summary: %{
         failed_ingest: %{count: 0, latest: nil},
         orphan_backlog: %{count: 0, oldest: nil},
         replay_outcomes: %{
           counts: %{failed: 0, noop: 0, replayed: 0},
           latest: nil
         },
         reconcile_facts: %{
           reconciled_count: 0,
           still_unmatched_count: 0,
           latest_reconciled: nil
         }
       },
       support_state: %{focused_card: nil, drilldown_banner: nil},
       suppression_count: 0
     }},

    # STATE-LD-15: suppression_card — present and absent
    {:suppression_card, "present",
     %{
       suppression_state: %{
         scope: :global,
         reason: :bounced,
         stream: :transactional,
         source: "provider:postmark",
         reversibility: :immutable
       }
     }},
    {:suppression_card, "absent", %{suppression_state: nil}},

    # STATE-LD-16: timeline — populated, highlighted-event, empty
    {:timeline, "populated",
     %{
       timeline_events: [
         %{
           id: "evt_01JXABC",
           type: :queued,
           occurred_at: ~U[2026-06-14 11:59:00Z],
           metadata: %{},
           reject_reason: nil
         },
         %{
           id: "evt_01JXDEF",
           type: :delivered,
           occurred_at: ~U[2026-06-14 12:00:00Z],
           metadata: %{},
           reject_reason: nil
         }
       ],
       highlight_event_id: nil
     }},
    {:timeline, "highlighted-event",
     %{
       timeline_events: [
         %{
           id: "evt_01JXABC",
           type: :queued,
           occurred_at: ~U[2026-06-14 11:59:00Z],
           metadata: %{},
           reject_reason: nil
         },
         %{
           id: "evt_01JXDEF",
           type: :delivered,
           occurred_at: ~U[2026-06-14 12:00:00Z],
           metadata: %{},
           reject_reason: nil
         }
       ],
       highlight_event_id: "evt_01JXDEF"
     }},
    {:timeline, "empty", %{timeline_events: [], highlight_event_id: nil}},

    # State coverage for the redesigned rail (1 / 3+ / many, mixed tones): a lone
    # event reads as the intentional "Latest", mixed tones prove dot↔badge accord,
    # and a long run exercises the continuous connector + stagger cap.
    {:timeline, "single",
     %{
       timeline_events: [
         %{
           id: "evt_01JXSOLO",
           type: :delivered,
           occurred_at: ~U[2026-06-14 12:00:00Z],
           metadata: %{"provider" => "postmark", "source" => "webhook"},
           reject_reason: nil
         }
       ],
       highlight_event_id: nil
     }},
    {:timeline, "mixed-tones",
     %{
       timeline_events: [
         %{
           id: "evt_01JXT01",
           type: :sent,
           occurred_at: ~U[2026-06-14 11:58:00Z],
           metadata: %{"provider" => "postmark", "source" => "api"},
           reject_reason: nil
         },
         %{
           id: "evt_01JXT02",
           type: :deferred,
           occurred_at: ~U[2026-06-14 11:59:00Z],
           metadata: %{"provider" => "postmark", "source" => "webhook"},
           reject_reason: nil
         },
         %{
           id: "evt_01JXT03",
           type: :bounced,
           occurred_at: ~U[2026-06-14 12:00:00Z],
           metadata: %{"provider" => "postmark", "source" => "webhook"},
           reject_reason: :blocked
         }
       ],
       highlight_event_id: nil
     }},
    {:timeline, "many",
     %{
       timeline_events: [
         %{id: "evt_01JXN01", type: :queued, occurred_at: ~U[2026-06-14 11:55:00Z], metadata: %{"provider" => "postmark", "source" => "api"}, reject_reason: nil},
         %{id: "evt_01JXN02", type: :sent, occurred_at: ~U[2026-06-14 11:56:00Z], metadata: %{"provider" => "postmark", "source" => "api"}, reject_reason: nil},
         %{id: "evt_01JXN03", type: :dispatched, occurred_at: ~U[2026-06-14 11:57:00Z], metadata: %{"provider" => "postmark", "source" => "webhook"}, reject_reason: nil},
         %{id: "evt_01JXN04", type: :delivered, occurred_at: ~U[2026-06-14 11:58:00Z], metadata: %{"provider" => "postmark", "source" => "webhook"}, reject_reason: nil},
         %{id: "evt_01JXN05", type: :opened, occurred_at: ~U[2026-06-14 11:59:00Z], metadata: %{"provider" => "postmark", "source" => "webhook"}, reject_reason: nil},
         %{id: "evt_01JXN06", type: :clicked, occurred_at: ~U[2026-06-14 12:00:00Z], metadata: %{"provider" => "postmark", "source" => "webhook"}, reject_reason: nil}
       ],
       highlight_event_id: nil
     }},

    # STATE-LD-17: replay_modal — closed (open states require live event)
    {:replay_modal, "closed",
     %{
       open?: false,
       delivery: nil,
       replay_targets: nil,
       selected_target_id: nil
     }},

    # STATE-LD-18: routing_trace — empty, all-passing, first-failing
    {:routing_trace, "empty", %{trace: []}},
    {:routing_trace, "all-passing",
     %{
       trace: [
         %{
           mailbox: "MyApp.SupportMailbox",
           verdicts: [
             {:recipient, "support@myapp.com", "support@myapp.com", true},
             {:subject, nil, "Re: your order", true}
           ]
         }
       ]
     }},
    {:routing_trace, "first-failing",
     %{
       trace: [
         %{
           mailbox: "MyApp.SupportMailbox",
           verdicts: [
             {:recipient, "support@myapp.com", "b*****@e******.com", false},
             {:subject, nil, "Re: your order", true}
           ]
         }
       ]
     }},

    # STATE-LD-19: evidence_card — no-evidence, redacted, revealed, denied
    {:evidence_card, "no-evidence", %{evidence: nil, reveal_state: :redacted, can_reveal?: true}},
    {:evidence_card, "redacted",
     %{
       evidence: %{
         provider: "sendgrid",
         raw_payload: nil,
         raw_mime: nil,
         verification_facts: %{"dkim" => true, "spf" => :pass}
       },
       reveal_state: :redacted,
       can_reveal?: true
     }},
    {:evidence_card, "revealed",
     %{
       evidence: %{
         provider: "sendgrid",
         raw_payload:
           "Received: from mail.sendgrid.net\r\nFrom: sender@example.com\r\nTo: recipient@example.com\r\n\r\nBody here.",
         raw_mime: nil,
         verification_facts: %{"dkim" => true, "spf" => :pass}
       },
       reveal_state: :revealed,
       can_reveal?: true
     }},
    {:evidence_card, "denied",
     %{
       evidence: %{
         provider: "sendgrid",
         raw_payload: nil,
         raw_mime: nil,
         verification_facts: %{"dkim" => true}
       },
       reveal_state: :denied,
       can_reveal?: false
     }},

    # STATE-LD-20: device_frame — inactive-btn (static assigns, no phx-click)
    {:device_frame, "inactive-btn", %{device_width: 768}},

    # STATE-LD-21: tabs — inactive-tab (static assigns showing the tab strip)
    {:tabs, "inactive-tab",
     %{
       active_tab: :text,
       html_body: "",
       text_body: "Plain text preview of the Mailable.",
       raw_envelope: "",
       headers: [],
       device_width: 768,
       render_nonce: 1
     }},

    # STATE-LD-22: sidebar — mailable-collapsed, mailable-expanded, scenario-active
    {:sidebar, "mailable-collapsed",
     %{
       mailables: [
         {MyApp.WelcomeMailer, [{:default, %{}}]},
         {MyApp.PasswordResetMailer, [{:reset, %{}}]}
       ],
       current_mailable: nil,
       current_scenario: nil
     }},
    {:sidebar, "mailable-expanded",
     %{
       mailables: [
         {MyApp.WelcomeMailer, [{:default, %{}}, {:"with-name", %{name: "Ada"}}]},
         {MyApp.PasswordResetMailer, [{:reset, %{}}]}
       ],
       current_mailable: MyApp.WelcomeMailer,
       current_scenario: nil
     }},
    {:sidebar, "scenario-active",
     %{
       mailables: [
         {MyApp.WelcomeMailer, [{:default, %{}}, {:"with-name", %{name: "Ada"}}]},
         {MyApp.PasswordResetMailer, [{:reset, %{}}]}
       ],
       current_mailable: MyApp.WelcomeMailer,
       current_scenario: :"with-name"
     }},

    # Phase 113: data_state — four distinct kinds (DATA-03)
    {:data_state, "empty",
     %{kind: :empty, title: "No deliveries", body: "No deliveries have been recorded yet."}},
    {:data_state, "error",
     %{
       kind: :error,
       title: "Delivery data unavailable",
       body:
         "Delivery data could not be loaded. Refresh the page or adjust the filters, then try again."
     }},
    {:data_state, "permission-denied",
     %{
       kind: :permission_denied,
       title: "Access restricted",
       body:
         "You do not have access to this account's mail operations. Ask an administrator to grant access."
     }},
    {:data_state, "stale",
     %{
       kind: :stale,
       title: "Data may be out of date",
       body: "Showing Deliveries as of 14:32. Refresh to load the latest."
     }},

    # Phase 113: deliveries_list — table/cards populated state (DATA-01)
    {:deliveries_list, "table-populated",
     %{
       deliveries: [
         %{
           id: "del_01JXABCDEF",
           recipient: "j*@e******.com",
           status: :delivered,
           tenant_id: "acme-corp",
           provider: "postmark",
           last_event_type: :delivered,
           last_event_at: ~U[2026-06-14 12:00:00Z]
         },
         %{
           id: "del_01JXGHIJKL",
           recipient: "a*@m****.io",
           status: :bounced,
           tenant_id: "acme-corp",
           provider: "sendgrid",
           last_event_type: :bounced,
           last_event_at: ~U[2026-06-14 11:45:00Z]
         }
       ],
       selected_delivery: nil,
       data_state: nil
     }},

    # Phase 113: deliveries_list — data-state error branch (DATA-03)
    {:deliveries_list, "data-state-error",
     %{deliveries: [], selected_delivery: nil, data_state: :error}},

    # Phase 113: deliveries_list — long-value stress (DATA-05)
    {:deliveries_list, "long-value-stress",
     %{
       deliveries: [
         %{
           id: "del_01JXWIDEVALUE000000000000000000000000000000000000",
           recipient: "b*****@enterprise-example-company-name.co.uk",
           status: :deferred,
           tenant_id: "tenant_01JXWIDEVALUE000000000000000000000000",
           provider: "postmark-enterprise-relay",
           last_event_type: :deferred,
           last_event_at: ~U[2026-06-14 23:59:59Z]
         }
       ],
       selected_delivery: nil,
       data_state: nil
     }},

    # Phase 113: records_list — table/cards populated state (DATA-01)
    {:records_list, "table-populated",
     %{
       records: [
         %{
           id: "inb_01JXABCDEF",
           envelope_recipient: "s*@m***.io",
           outcome: :accepted,
           mailbox: "MyApp.SupportMailbox",
           tenant_id: "acme-corp",
           provider: "sendgrid",
           received_at: ~U[2026-06-14 12:00:00Z]
         },
         %{
           id: "inb_01JXGHIJKL",
           envelope_recipient: "b*@e******.com",
           outcome: :no_match,
           mailbox: nil,
           tenant_id: "acme-corp",
           provider: "postmark",
           received_at: ~U[2026-06-14 11:45:00Z]
         }
       ],
       selected_record: nil,
       data_state: nil,
       empty_state: :truly_empty
     }},

    # Phase 113: records_list — data-state error branch (DATA-03)
    {:records_list, "data-state-error",
     %{records: [], selected_record: nil, data_state: :error, empty_state: :truly_empty}},

    # Phase 113: records_list — long-value stress (DATA-05)
    {:records_list, "long-value-stress",
     %{
       records: [
         %{
           id: "inb_01JXWIDEVALUE000000000000000000000000000000000000",
           envelope_recipient: "b*****@enterprise-example-company-name.co.uk",
           outcome: :accepted,
           mailbox: "MyApp.VeryLongSupportMailbox.HandlesAllIncomingMessages",
           tenant_id: "tenant_01JXWIDEVALUE000000000000000000000000",
           provider: "sendgrid-enterprise-relay",
           received_at: ~U[2026-06-14 23:59:59Z]
         }
       ],
       selected_record: nil,
       data_state: nil,
       empty_state: :truly_empty
     }},

    # Phase 114: composed-group specimens (D-10) — each delegates to a public
    # composed_*/1 fn that calls the SAME group-assembling fns the live views
    # call. Data-free / minimal assigns: these are structural specimens.
    {:composed_support_triage, "operator-detail", %{}},
    {:composed_routing_evidence, "inbound-routing", %{}},
    {:composed_detail_timeline, "inbound-detail", %{}},

    # Phase 116 RATCHET-02: fjordline-aps persona mirror. These specimens carry
    # the EXACT literals the demo persona uses (MailglassDemo.Personas, plan
    # 116-01) so the persona drift-guard stays byte-consistent. The "fjordline"
    # token in these state names activates the drift-guard's gallery-intent
    # heuristic; the four literal VALUES below are what it asserts byte-present.
    #
    # Non-ASCII display names (Latin-extended + CJK) at weight 400, truncate.
    {:fjordline_stress, "fjordline-non-ascii-names",
     %{
       caption: "fjordline-aps from[].name (non-ASCII)",
       lines: ["Bjørn Hansen", "山田太郎"]
     }},
    # Long ULID-class delivery ID — must truncate, never overflow.
    {:fjordline_stress, "fjordline-long-id",
     %{
       caption: "fjordline-aps delivery ID (long ULID-class)",
       lines: ["del_01JXW9ZQKB3V1N4P2RMT7FHCG"]
     }},
    # Long Mailable module name (>= 60 chars) — truncates identically.
    {:fjordline_stress, "fjordline-long-mailable",
     %{
       caption: "fjordline-aps Mailable module name (long)",
       lines: ["Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName"]
     }},
    # Null branch: a :delivered event with reject_reason: nil renders NO
    # reject-reason badge (nil = legitimate absence, not an error).
    {:fjordline_stress, "fjordline-nil-reject",
     %{
       caption: "fjordline-aps :delivered event (reject_reason: nil → no badge)",
       lines: [],
       # Short event ID matches the existing gallery-timeline-* specimens so the
       # mono (non-truncating) ID stays overflow-clean at the 768 three-column
       # width. The edge value under test is reject_reason: nil (no badge), not
       # the ID — the fjordline namespacing lives in the state/caption.
       event: %{
         id: "evt_01JXFJD",
         type: :delivered,
         occurred_at: ~U[2026-06-14 12:00:00Z],
         metadata: %{},
         reject_reason: nil
       }
     }}
  ]

  defp specimens, do: @specimens

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Group the flat specimen list into [{component, [{state, assigns_map}]}]
  defp grouped_specimens(specimens) do
    specimens
    |> Enum.reduce([], fn {component, state, assigns_map}, acc ->
      case List.keyfind(acc, component, 0) do
        nil ->
          acc ++ [{component, [{state, assigns_map}]}]

        {^component, states} ->
          List.keyreplace(acc, component, 0, {component, states ++ [{state, assigns_map}]})
      end
    end)
  end

  # Human-readable label for component atoms — domain nouns verbatim
  defp component_label(:icon), do: "icon"
  defp component_label(:logo), do: "logo"
  defp component_label(:flash), do: "flash"
  defp component_label(:badge), do: "badge"
  defp component_label(:status_badge), do: "status_badge"
  defp component_label(:nav_link), do: "nav_link"
  defp component_label(:nav_pill), do: "nav_pill"
  defp component_label(:tenant_chip), do: "tenant_chip"
  defp component_label(:theme_picker), do: "theme_picker"
  defp component_label(:stat_card), do: "stat_card"
  defp component_label(:orientation_strip), do: "orientation_strip"
  defp component_label(:deliveries_list), do: "deliveries_list"
  defp component_label(:detail_header), do: "detail_header"
  defp component_label(:filter_field), do: "filter_field"
  defp component_label(:filter_section), do: "filter_section"
  defp component_label(:filters_form), do: "filters_form"
  defp component_label(:support_cards), do: "support_cards"
  defp component_label(:suppression_card), do: "suppression_card"
  defp component_label(:timeline), do: "timeline"
  defp component_label(:replay_modal), do: "replay_modal"
  defp component_label(:routing_trace), do: "routing_trace"
  defp component_label(:evidence_card), do: "evidence_card"
  defp component_label(:device_frame), do: "device_frame"
  defp component_label(:tabs), do: "tabs"
  defp component_label(:sidebar), do: "sidebar"
  defp component_label(:data_state), do: "data_state"
  defp component_label(:records_list), do: "records_list"
  defp component_label(:composed_support_triage), do: "composed_support_triage"
  defp component_label(:composed_routing_evidence), do: "composed_routing_evidence"
  defp component_label(:composed_detail_timeline), do: "composed_detail_timeline"
  defp component_label(:fjordline_stress), do: "fjordline_stress"
end
