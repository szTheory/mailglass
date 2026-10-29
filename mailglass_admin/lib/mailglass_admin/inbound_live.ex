defmodule MailglassAdmin.InboundLive do
  @moduledoc """
  Read-only operator dashboard for recent inbound records, execution lineage,
  and routing reflection.

  Sibling of `MailglassAdmin.OperatorLive` (clone, not a refactor). The
  screen keeps filter and selection state in URL params so refresh, back/forward
  navigation, and copied links preserve the current operator context.

  All inbound data access crosses a runtime `apply/3` edge through
  `MailglassAdmin.OptionalDeps.MailglassInbound`. This module never
  references the optional inbound modules directly, so the `--no-optional-deps`
  compile lane stays green: when `mailglass_inbound` is absent the gateway module is
  elided, `gateway_available?/0` returns `false`, and every data call presents an
  unavailable state instead of a false empty result.

  Tenant-required-or-empty: a blank/missing tenant renders the empty state
  and never leaks another tenant's record id or recipient. The read-model enforces
  the tenant where-clause + `Tenancy.scope/2`; this LiveView adds the
  `load_inbound_records(%{"tenant_id" => ""})` short-circuit head as defense in depth.
  Tenant-scoped operator actions must never widen visibility outside the current tenant.
  """

  use Phoenix.LiveView

  alias MailglassAdmin.Components
  alias MailglassAdmin.Inbound.DestructiveAction
  alias MailglassAdmin.Inbound.DetailHeader
  alias MailglassAdmin.Inbound.EvidenceCard
  alias MailglassAdmin.Inbound.FiltersForm
  alias MailglassAdmin.Inbound.Overview
  alias MailglassAdmin.Inbound.QuickView
  alias MailglassAdmin.Inbound.ReadResult
  alias MailglassAdmin.Inbound.RecordsList
  alias MailglassAdmin.Inbound.ReplayModal
  alias MailglassAdmin.Inbound.RoutingTrace
  alias MailglassAdmin.Inbound.Timeline
  alias MailglassAdmin.Operator.Accounts
  alias MailglassAdmin.Operator.FilterCommit
  alias MailglassAdmin.Operator.ResultsStatus
  alias MailglassAdmin.Operator.Tenants, as: TenantSelector
  alias Phoenix.LiveView.JS

  @gateway MailglassAdmin.OptionalDeps.MailglassInbound

  # The closed outcome allow-list. Hard-coded here (and asserted against the
  # read-model in the inbound test) so the LiveView has no compile-time reference
  # to MailglassInbound — keeping the --no-optional-deps lane clean.
  @outcome_values [:no_match, :accept, :ignore, :no_change, :reject, :bounce, :failed]
  @default_window_hours 168
  @inbound_records_per_page 20
  @outcome_filter_error "Mailbox outcome was not applied. Choose a listed outcome."
  @window_filter_error "Time window was not applied. Choose a positive listed time window."
  @window_options [
    {"Last 24 hours", "24"},
    {"Last 7 days", "168"},
    {"Last 30 days", "720"}
  ]
  @zero_summary %{
    total: 0,
    outcomes: %{
      no_match: 0,
      accept: 0,
      ignore: 0,
      no_change: 0,
      reject: 0,
      bounce: 0,
      failed: 0
    },
    unclassified: 0,
    no_match_rate: 0.0
  }

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: send(self(), :canonicalize_tenant)

    # The declared inbound router module is surfaced in the operator
    # session (router.ex __operator_session__) as an atom, never cookie-sourced.
    # The routing-trace card reflects its routes via the runtime gateway.
    inbound_router = session_inbound_router(session)
    tenant_id = session_tenant_id(session)

    # Live updates (IADM-05): subscribe on the CONNECTED mount only, to
    # the per-tenant inbound stream via the builder (never a literal — LINT-06 /
    # V9). The producer is `mailglass_inbound`; the payload is id-only and PII-free
    # (Pitfall 6), so handle_info re-fetches tenant-scoped before prepending.
    if connected?(socket) and is_binary(tenant_id) and tenant_id != "" do
      Phoenix.PubSub.subscribe(
        Mailglass.PubSub,
        MailglassAdmin.PubSub.Topics.inbound_record_inserted(tenant_id)
      )
    end

    {:ok,
     socket
     |> assign_new(:operator_actor, fn -> nil end)
     |> assign_new(:operator_auth, fn -> %{status: :unknown, recent_auth?: false} end)
     |> assign(:records, [])
     |> assign(:records_page_meta, empty_page_meta())
     |> assign(:inbound_summary, @zero_summary)
     |> assign(:records_read_state, :ok)
     |> assign(:summary_read_state, :ok)
     |> assign(:detail_read_state, :ok)
     |> assign(:timeline_read_state, :not_requested)
     |> assign(:timeline_read_at, nil)
     |> assign(:provider_options_state, :ok)
     |> assign(:empty_state, :no_tenant)
     |> assign(:full_detail?, false)
     |> assign(:selected_record, nil)
     |> assign(:selected_outside_results?, false)
     |> assign(:quick_view_focus_surface, nil)
     |> assign(:quick_view_focus_return_id, nil)
     |> assign(:detail, nil)
     |> assign(:runs, [])
     |> assign(:routing_trace, [])
     |> assign(:reveal_state, :redacted)
     |> assign(:focus_reveal_after_redact, false)
     |> assign(:inbound_router, inbound_router)
     |> assign(:detail_error, nil)
     |> assign(:data_state, nil)
     |> assign(:replay_modal_open?, false)
     |> assign(:replay_review, nil)
     |> assign(:replay_pending_review_id, nil)
     |> assign(:replay_consumed_review_id, nil)
     |> assign(:replay_feedback, nil)
     |> assign(:replay_dialog_feedback, nil)
     |> assign(:replay_eligibility, nil)
     |> assign(:replay_trigger_id, "inbound-replay-open-btn")
     |> assign(:base_path, "/inbound")
     |> assign(:page_uri, "/inbound")
     |> assign(:dark_chrome, false)
     |> assign(:theme_choice, :system)
     |> assign(:theme_cookie, session_theme_cookie(session))
     |> assign(:preview_path, session_navigation_path(session, :preview_path))
     |> assign(:account_labels, session_account_labels(session))
     |> assign(:tenant_options, [])
     |> assign(:tenant_options_state, :ok)
     |> assign(:tenant_state, :none)
     |> assign(:selected_tenant_id, nil)
     |> assign(:outcome_values, @outcome_values)
     |> assign(:window_options, @window_options)
     |> assign(:filter_params, default_filter_params())
     |> assign(:filter_form, to_form(default_filter_params(), as: :filters))
     |> assign(:filter_errors, %{})
     |> assign(:filter_error_source, nil)
     |> assign(:filter_url_invalid, %{})
     |> assign(:inbound_loaded_for, nil)
     |> assign(:inbound_loaded_at, nil)
     |> assign(:results_status_text, initial_results_status_text())
     |> assign(:pending_commit_kind, nil)
     |> assign(:last_commit_kind, nil)
     |> assign(:page_title, "mailglass — Inbound")}
  end

  defp session_inbound_router(session) when is_map(session),
    do: Map.get(session, "inbound_router")

  defp session_inbound_router(_session), do: nil

  defp session_tenant_id(session) when is_map(session), do: Map.get(session, "tenant_id")
  defp session_tenant_id(_session), do: nil

  # Persisted theme cookie surfaced via the operator session callback; the shell
  # resolves theme from it when the URL carries no explicit ?theme= override.
  defp session_theme_cookie(session) when is_map(session),
    do: Map.get(session, "admin_chrome_theme_cookie")

  defp session_theme_cookie(_session), do: nil

  defp session_navigation_path(%{"navigation" => navigation}, key) when is_map(navigation) do
    blank_to_nil(Map.get(navigation, key) || Map.get(navigation, Atom.to_string(key)))
  end

  defp session_navigation_path(_session, _key), do: nil

  defp session_account_labels(session) when is_map(session),
    do: Accounts.normalize_labels(Map.get(session, "account_labels"))

  defp session_account_labels(_session), do: %{}

  @impl true
  def handle_params(params, uri, socket) do
    if redirect_path = MailglassAdmin.Theme.legacy_query_redirect_path(params, uri) do
      {:noreply, redirect(socket, to: redirect_path)}
    else
      {filter_params, filter_errors} = normalize_filter_params_with_errors(params)

      {tenant_options, tenant_options_state} =
        ReadResult.fetch(fn ->
          TenantSelector.list_tenants(socket.assigns.operator_actor,
            account_labels: socket.assigns.account_labels
          )
        end)
        |> case do
          {:ok, options} -> {options, :ok}
          {:error, :read_unavailable} -> {[], :read_unavailable}
        end

      selected_tenant_id = blank_to_nil(filter_params["tenant_id"])
      theme_choice = MailglassAdmin.Operator.Shell.theme_choice(%{}, socket.assigns.theme_cookie)

      tenant_state =
        if tenant_options_state == :read_unavailable and is_nil(selected_tenant_id) do
          :unavailable
        else
          tenant_state(selected_tenant_id, tenant_options, Map.has_key?(params, "tenant_id"))
        end

      {provider_options, provider_options_state} = load_provider_options(filter_params)

      socket =
        socket
        |> settle_commit_kind()
        |> assign(:base_path, URI.parse(uri).path || "/inbound")
        |> assign(:page_uri, uri)
        |> assign(:dark_chrome, theme_choice == :dark)
        |> assign(:theme_choice, theme_choice)
        |> assign(:filter_params, filter_params)
        |> assign(
          :filter_form,
          to_form(filter_draft_params(params, filter_params, filter_errors), as: :filters)
        )
        |> assign(:filter_errors, filter_errors)
        |> assign(:filter_error_source, if(map_size(filter_errors) > 0, do: :url))
        |> assign(:filter_url_invalid, filter_errors)
        |> assign(:tenant_options, tenant_options)
        |> assign(:tenant_options_state, tenant_options_state)
        |> assign(:tenant_state, tenant_state)
        |> assign(:selected_tenant_id, selected_tenant_id)
        |> assign(:provider_options, provider_options)
        |> assign(:provider_options_state, provider_options_state)

      socket =
        if is_nil(blank_to_nil(params["inbound_id"])),
          do: assign(socket, :quick_view_focus_surface, nil),
          else: socket

      if connected?(socket) and tenant_state == :auto_select do
        send(self(), :canonicalize_tenant)
      end

      cond do
        tenant_state == :auto_select ->
          {:noreply, clear_surface_state(socket) |> close_replay_modal()}

        tenant_state in [:select_required, :none, :unavailable] ->
          {:noreply, clear_surface_state(socket) |> close_replay_modal()}

        true ->
          {:noreply,
           socket
           |> assign_inbound_state(
             filter_params,
             blank_to_nil(params["inbound_id"]),
             params["full"] == "1" and not is_nil(blank_to_nil(params["inbound_id"]))
           )
           |> close_replay_modal()}
      end
    end
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    commit_filters(socket, filters, :enter)
  end

  # phx-auto-recover: after a reconnect the browser resends the form it still holds. Treat
  # it as a commit that never adds history (D-11): valid and different restores the URL
  # with replace, invalid stays a draft, identical is a no-op.
  def handle_event("recover_filters", %{"filters" => filters}, socket) do
    commit_filters(socket, filters, :recover)
  end

  def handle_event("recover_filters", _params, socket), do: {:noreply, socket}

  def handle_event("set_theme", %{"theme" => theme}, socket) do
    {:noreply,
     redirect(socket,
       to: MailglassAdmin.Operator.Shell.set_theme_path(socket.assigns.page_uri, theme)
     )}
  end

  def handle_event("validate_filters", %{"filters" => filters} = params, socket) do
    commit_filters(socket, filters, FilterCommit.kind_for_target(params["_target"]))
  end

  def handle_event("select_inbound", %{"id" => inbound_id} = params, socket) do
    focus_surface =
      if params["surface"] in ["desktop", "mobile"], do: params["surface"], else: nil

    {:noreply,
     push_patch(assign(socket, :quick_view_focus_surface, focus_surface),
       to:
         build_path(
           socket.assigns.base_path,
           socket.assigns.filter_params,
           inbound_id,
           socket.assigns.dark_chrome
         )
     )}
  end

  # Keyboard mirror of the `‹ ›` buttons + Enter/Escape, bound only while the Quick
  # view is open. Unknown keys are no-ops.
  def handle_event("detail_key", %{"key" => key}, socket) do
    case key do
      k when k in ["ArrowUp", "ArrowLeft", "k"] ->
        navigate_record(socket, "prev")

      k when k in ["ArrowDown", "ArrowRight", "j"] ->
        navigate_record(socket, "next")

      "Enter" ->
        case socket.assigns.selected_record do
          %{id: id} ->
            {:noreply,
             push_patch(socket,
               to:
                 detail_path(
                   socket.assigns.base_path,
                   socket.assigns.filter_params,
                   id,
                   socket.assigns.dark_chrome,
                   true
                 )
             )}

          _ ->
            {:noreply, socket}
        end

      "Escape" ->
        {:noreply,
         push_patch(socket,
           to:
             build_path(
               socket.assigns.base_path,
               socket.assigns.filter_params,
               nil,
               socket.assigns.dark_chrome
             )
         )}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("clear_filters", _params, socket) do
    path =
      build_path(
        socket.assigns.base_path,
        %{"tenant_id" => socket.assigns.selected_tenant_id || ""},
        nil,
        socket.assigns.dark_chrome
      )

    # Clear with nothing applied changes nothing: no patch, no history entry. It still
    # resets a draft that was typed but never committed.
    if same_location?(socket.assigns.page_uri, path) do
      {:noreply,
       socket
       |> assign(:filter_form, to_form(socket.assigns.filter_params, as: :filters))
       |> assign(:filter_errors, %{})
       |> assign(:filter_error_source, nil)}
    else
      {:noreply, push_commit(socket, path, :clear)}
    end
  end

  def handle_event("open_replay", params, socket) do
    case fresh_replay_snapshot(socket) do
      {:ok, record, eligibility} ->
        review = replay_review(record, eligibility)

        {:noreply,
         socket
         |> assign(:replay_review, review)
         |> assign(:replay_dialog_feedback, nil)
         |> assign(:replay_trigger_id, replay_trigger_id(params))
         |> assign(:replay_modal_open?, true)}

      {:error, :cross_tenant} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Replay blocked: this action is not authorized for the current operator."
         )}

      {:error, _reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Select an InboundMessage to review its recorded Mailbox before replay."
         )}
    end
  end

  def handle_event("review_replay_again", _params, socket) do
    case fresh_replay_snapshot(socket) do
      {:ok, record, eligibility} ->
        {:noreply,
         socket
         |> assign(:replay_review, replay_review(record, eligibility))
         |> assign(:replay_dialog_feedback, nil)
         |> assign(:replay_pending_review_id, nil)}

      {:error, :cross_tenant} ->
        {:noreply,
         replay_dialog_feedback(
           socket,
           :error,
           "Replay blocked: this action is not authorized for the current operator. Review the selected record again."
         )}

      {:error, reason} ->
        {:noreply,
         replay_dialog_feedback(
           socket,
           :error,
           "The selected Inbound message could not be checked again. " <>
             replay_error_copy(reason)
         )}
    end
  end

  def handle_event("close_replay", _params, socket) do
    {:noreply, close_replay_modal(socket)}
  end

  # Retry re-reads the committed filters in place: no patch, no history entry (D-14).
  def handle_event("retry_inbound", _params, socket) do
    {:noreply,
     assign_inbound_state(
       socket,
       socket.assigns.filter_params,
       requested_inbound_id(socket),
       socket.assigns.full_detail?
     )}
  end

  def handle_event("refresh_inbound_timeline", _params, socket) do
    {:noreply, refresh_selected_timeline(socket)}
  end

  # Evidence reveal (IADM-02) — capability-gated by the :reveal_raw atom over the
  # SAME Auth.authorize/3 seam as replay (no new auth surface, -09). On grant
  # the evidence card renders the raw payload read-only; on denial the redacted
  # placeholder stays and a brand-voice line explains the gate.
  def handle_event("reveal_raw", _params, socket) do
    reveal_state = authorize_reveal(socket)

    # PII-free reveal-audit count (D-12). authorize_reveal/1 stays a PURE auth
    # helper returning the reveal_state atom; the outcome mapping + emit live
    # HERE at the call-site (:revealed -> :granted, :denied -> :denied). Metadata
    # is tenant_id / record_id / outcome ONLY — never payload/body/headers/
    # recipient (CLAUDE.md telemetry PII rule). Fire-and-forget: it must not
    # change control flow.
    emit_reveal_telemetry(socket, reveal_outcome(reveal_state))

    {:noreply, assign(socket, :reveal_state, reveal_state)}
  end

  # Re-redact (D-11) — collapse a revealed payload back to :redacted with NO
  # authorize call (collapsing never widens access; no fourth state atom). Focus
  # returns to the reveal button via the focus sentinel keyed on :reveal_state.
  def handle_event("re_redact_raw", _params, socket) do
    {:noreply,
     socket
     |> assign(:reveal_state, :redacted)
     |> assign(:focus_reveal_after_redact, true)}
  end

  # Replay confirmation re-reads the reviewed Account, record and eligibility,
  # then authorizes the fresh record immediately before the tenant-scoped replay.
  def handle_event("confirm_replay", _params, socket) do
    case socket.assigns do
      %{detail_error: error} when not is_nil(error) ->
        {:noreply,
         replay_feedback(
           socket,
           :error,
           "Replay blocked: this action is not authorized for the current operator."
         )}

      %{replay_modal_open?: false, replay_consumed_review_id: consumed}
      when not is_nil(consumed) ->
        {:noreply,
         replay_feedback(socket, :error, "Replay was already submitted for this review.")}

      %{replay_consumed_review_id: consumed, replay_review: %{review_id: consumed}}
      when not is_nil(consumed) ->
        {:noreply,
         replay_dialog_feedback(socket, :error, "Replay was already submitted for this review.")}

      %{replay_pending_review_id: pending, replay_review: %{review_id: pending}}
      when not is_nil(pending) ->
        {:noreply,
         replay_dialog_feedback(socket, :error, "Replay is already in progress for this review.")}

      %{replay_modal_open?: true, replay_review: %{review_id: review_id}} ->
        socket =
          socket
          |> assign(:replay_pending_review_id, review_id)
          |> assign(:replay_consumed_review_id, review_id)

        {:noreply, submit_replay_review(socket)}

      _assigns ->
        {:noreply,
         replay_dialog_feedback(
           socket,
           :error,
           "Replay review is no longer open. Review the record again before confirming."
         )}
    end
  end

  # Live update (IADM-05 / -11, Pitfall 6): the broadcast payload is id-only.
  # Re-fetch the record TENANT-SCOPED through the gateway; if it resolves to nil
  # (foreign tenant or filtered out) drop it; otherwise PREPEND to the list WITHOUT
  # stealing the current selection or resetting filters.
  @impl true
  def handle_info(:canonicalize_tenant, %{assigns: %{tenant_state: :auto_select}} = socket) do
    [tenant] = socket.assigns.tenant_options

    {:noreply,
     push_patch(socket,
       to: MailglassAdmin.Operator.Shell.tenant_switch_path(socket.assigns.page_uri, tenant.id),
       replace: true
     )}
  end

  def handle_info({:inbound_record_inserted, record_id, _meta}, socket) do
    {:noreply, prepend_live_record(socket, record_id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    paths =
      MailglassAdmin.Operator.Shell.surface_paths(
        assigns.base_path,
        :inbound,
        assigns.dark_chrome,
        blank_to_nil(assigns.filter_params["tenant_id"])
      )

    assigns =
      assign(assigns,
        preview_path: assigns.preview_path,
        overview_path: paths.overview,
        deliveries_path: paths.deliveries,
        inbound_path: paths.inbound,
        inbound_available?: MailglassAdmin.Operator.Shell.inbound_available?()
      )

    ~H"""
    <MailglassAdmin.Operator.Shell.shell
      active={:inbound}
      preview_path={@preview_path}
      overview_path={@overview_path}
      deliveries_path={@deliveries_path}
      inbound_path={@inbound_path}
      inbound_available?={@inbound_available?}
      dark_chrome={@dark_chrome}
      theme_choice={@theme_choice}
      selected_tenant_id={@selected_tenant_id}
      tenant_options={@tenant_options}
      tenant_state={@tenant_state}
      account_labels={@account_labels}
      page_uri={@page_uri}
      title="Inbound records"
      subtitle="Follow each received message through routing and mailbox processing."
      flash={@flash}
    >
      <%= if @tenant_state in [:select_required, :none, :unavailable] do %>
        <%= if @tenant_state == :unavailable do %>
          <div data-testid="inbound-tenant-options-unavailable">
            <Components.data_state
              kind={:error}
              title="Account options unavailable"
              body="Account options could not be loaded. Refresh the page or try again shortly."
            />
          </div>
        <% else %>
          <MailglassAdmin.Operator.Shell.tenant_selector
            state={@tenant_state}
            tenant_options={@tenant_options}
            current_uri={@page_uri}
          />
        <% end %>
      <% else %>
        <%!-- One persistent status region: it exists from first render and its text changes
            only when a read settles, never on drafts. --%>
        <div
          id="inbound-results-status"
          data-testid="inbound-results-status"
          role="status"
          aria-live="polite"
          aria-atomic="true"
          class="sr-only"
        >
          {@results_status_text}
        </div>
        <%= cond do %>
          <% @records == [] and @records_read_state == :ok and @empty_state == :truly_empty and not filters_active?(@filter_params) and @filter_errors == %{} -> %>
            <%!-- Genuine no-data: a single calm pane only — inbound-empty-truly + orientation strip.
                  The filters toolbar, the Open-record CTA, the Inbound.Overview health strip, and the
                  entire master-detail grid (and therefore the "Select an InboundMessage…" helper nested
                  inside it) are all withheld (D-02/D-05 — the filters toolbar is the only scope-widening
                  vector). An in-flight invalid filter submission (@filter_errors non-empty) is NOT genuine
                  no-data — the toolbar stays so the operator sees the recovery copy and Clear-filters. --%>
            <div class="space-y-lg">
              <section
                data-testid="inbound-deliveries-empty-pane"
                class="card min-w-0 rounded-box border border-base-300 bg-base-200 p-0"
              >
                <RecordsList.records_list
                  records={[]}
                  page_meta={@records_page_meta}
                  previous_page_path={
                    pagination_path(@base_path, @filter_params, @dark_chrome, :previous)
                  }
                  next_page_path={pagination_path(@base_path, @filter_params, @dark_chrome, :next)}
                  empty_state={:truly_empty}
                />
              </section>
              <MailglassAdmin.Operator.Shell.orientation_strip surface={:inbound} />
            </div>
          <% true -> %>
            <%= if @full_detail? and (@selected_record || @detail_error) do %>
              <%!-- FULL DETAIL: the complete InboundMessage on its own, full width
                  (list hidden). Reached from Quick view's "Open full detail" or &full=1. --%>
              <div data-testid="inbound-detail-column" class="space-y-md">
                <.link
                  patch={
                    build_path(
                      @base_path,
                      @filter_params,
                      @selected_record && @selected_record.id,
                      @dark_chrome
                    )
                  }
                  data-testid="inbound-detail-back"
                  id="inbound-detail-back"
                  phx-mounted={JS.focus(to: "#inbound-detail-back")}
                  class="mg-focus-ring btn btn-ghost !h-11 min-h-11"
                >
                  <Components.icon name="hero-arrow-uturn-left" class="mr-xs h-4 w-4" />
                  {if @selected_record, do: "Back to quick view", else: "Back to inbound records"}
                </.link>

                <p
                  :if={@selected_outside_results?}
                  data-testid="inbound-selection-outside-results"
                  class="text-label text-secondary"
                >
                  This inbound message is outside your current results.
                </p>

                <div
                  :if={@replay_feedback && !@replay_modal_open?}
                  id="inbound-replay-feedback"
                  data-testid="inbound-replay-feedback"
                  role="status"
                  aria-live="polite"
                  class={[
                    "rounded-box border p-sm text-body",
                    if(@replay_feedback && @replay_feedback.kind == :error,
                      do: "border-error bg-error/10 text-base-content",
                      else: "border-success bg-success/10 text-base-content"
                    )
                  ]}
                >
                  {@replay_feedback && @replay_feedback.text}
                </div>

                <%= if @detail do %>
                  <div
                    id={"inbound-detail-#{@detail.record.id}"}
                    data-region
                    class="motion-reveal space-y-md"
                  >
                    <DetailHeader.detail_header detail={@detail} account_labels={@account_labels} />
                    <Timeline.timeline
                      runs={@runs}
                      read_state={@timeline_read_state}
                      read_at={@timeline_read_at}
                    />
                    <RoutingTrace.routing_trace
                      :if={@detail[:outcome] == :no_match}
                      trace={@routing_trace}
                    />
                    <EvidenceCard.evidence_card
                      evidence={@detail[:evidence]}
                      reveal_state={@reveal_state}
                      received_at={Map.get(@detail[:record] || %{}, :received_at)}
                    />
                  </div>
                <% else %>
                  <div
                    data-testid="inbound-detail-error"
                    class="card rounded-box border border-error bg-base-100 p-lg"
                  >
                    <Components.data_state
                      kind={:error}
                      title="Message unavailable"
                      body={detail_error_copy(@detail_error)}
                    />
                  </div>
                <% end %>
              </div>
            <% else %>
              <%!-- LIST PAGE: filters + scoped summary + full-width records list.
                  The Quick view overlay (below) sits on top when a record is focused. --%>
              <section
                data-testid="inbound-filters"
                class="mg-inbound-filters border-b border-base-300 pb-md"
              >
                <button
                  type="button"
                  phx-click={
                    JS.toggle_class("mg-inbound-filters-open", to: "#inbound-filter-panel")
                    |> JS.toggle_attribute({"aria-expanded", "true", "false"})
                  }
                  data-testid="inbound-filters-toggle"
                  aria-controls="inbound-filter-panel"
                  aria-expanded="false"
                  class="btn btn-ghost !h-11 min-h-11 md:hidden"
                >
                  Filters
                  <span :if={applied_filter_count(@filter_params) > 0} class="font-normal">
                    ({applied_filter_count(@filter_params)} applied)
                  </span>
                  <Components.icon name="hero-chevron-down" class="h-4 w-4" />
                </button>

                <div id="inbound-filter-panel" class="hidden md:block">
                  <.form
                    for={@filter_form}
                    id="inbound-filters"
                    phx-change="validate_filters"
                    phx-submit="apply_filters"
                    phx-auto-recover="recover_filters"
                    class="mt-md grid gap-md md:mt-0 xl:grid-cols-[minmax(0,1fr)_auto] xl:items-end"
                  >
                    <p
                      :if={@provider_options_state != :ok}
                      data-testid="inbound-provider-options-unavailable"
                      class="text-label text-secondary xl:col-span-2"
                    >
                      Provider options could not be loaded. The current account and filters are unchanged.
                    </p>
                    <FiltersForm.fields
                      form={@filter_form}
                      provider_options={@provider_options}
                      outcome_values={@outcome_values}
                      window_options={@window_options}
                      errors={@filter_errors}
                      committed_search={@filter_params["search"] || ""}
                    />

                    <div class="flex flex-wrap gap-sm">
                      <button
                        type="button"
                        phx-click="clear_filters"
                        class="btn btn-ghost min-h-11 px-md"
                      >
                        Clear filters
                      </button>
                    </div>
                  </.form>
                </div>

                <%!-- Outside the collapsible panel so the label stays visible when the mobile
                    panel is closed. Not live-announced: the invalid field already is (D-12/D-13).
                    The URL note follows the committed URL (D-13): it stays while the URL carries an
                    invalid value, whatever the draft does. The draft note shows whenever a change
                    event leaves the draft invalid (D-12). Both may show together; each is true. --%>
                <p
                  :if={@filter_error_source == :draft}
                  data-testid="filters-draft-pending-note"
                  class="mt-sm text-label text-secondary"
                >
                  Showing results for your previous filters until the highlighted field is fixed.
                </p>
                <p
                  :if={map_size(@filter_url_invalid) > 0}
                  data-testid="filters-url-invalid-note"
                  class="mt-sm text-label text-secondary"
                >
                  <span :for={note <- url_invalid_notes(@filter_url_invalid)} class="block">{note}</span>
                </p>
              </section>

              <%= if @summary_read_state == :ok do %>
                <Overview.overview summary={@inbound_summary} filters={@filter_params} />
              <% else %>
                <div data-testid="inbound-summary-unavailable">
                  <Components.data_state
                    kind={:error}
                    title={
                      if @summary_read_state == :package_unavailable,
                        do: "Inbound support is unavailable",
                        else: "Inbound summary unavailable"
                    }
                    body={
                      if @summary_read_state == :package_unavailable,
                        do:
                          "The optional inbound package is not available in this deployment. Inbound counts are not being shown.",
                        else:
                          "Inbound summary counts could not be loaded. Refresh the page or try again shortly."
                    }
                  />
                </div>
              <% end %>

              <section data-testid="inbound-master-detail" class="mt-lg">
                <aside
                  data-testid="inbound-records-list-card"
                  class="min-w-0"
                >
                  <RecordsList.records_list
                    heading="Received messages"
                    records={@records}
                    page_meta={@records_page_meta}
                    account_labels={@account_labels}
                    show_account?={false}
                    previous_page_path={
                      pagination_path(@base_path, @filter_params, @dark_chrome, :previous)
                    }
                    next_page_path={pagination_path(@base_path, @filter_params, @dark_chrome, :next)}
                    first_page_path={
                      build_path(
                        @base_path,
                        Map.put(@filter_params, "page", "1"),
                        nil,
                        @dark_chrome
                      )
                    }
                    selected_record={@selected_record}
                    empty_state={@empty_state}
                    data_state={@data_state}
                    loaded_at={@inbound_loaded_at}
                  />
                </aside>
              </section>
            <% end %>

            <%!-- Quick view (peek) overlay: a record is focused and we are NOT in Full detail. --%>
            <%!-- Return focus to the selected row after the URL-driven quick view is removed. --%>
            <span
              :if={not @full_detail? and (@selected_record != nil or @detail_error != nil)}
              data-testid="inbound-quick-view-focus-return"
              data-focus-return-id={@quick_view_focus_return_id}
              phx-mounted={JS.focus(to: "#inbound-quick-view-close")}
              phx-remove={
                if @quick_view_focus_return_id,
                  do: JS.focus(to: "##{@quick_view_focus_return_id}"),
                  else: %JS{}
              }
            />
            <QuickView.quick_view
              :if={not @full_detail? and (@selected_record != nil or @detail_error != nil)}
              record={@selected_record}
              replay_eligibility={@replay_eligibility}
              replay_open?={@replay_modal_open?}
              detail_error={@detail_error}
              outside_results?={@selected_outside_results?}
              account_labels={@account_labels}
              full_path={
                detail_path(
                  @base_path,
                  @filter_params,
                  @selected_record && @selected_record.id,
                  @dark_chrome,
                  true
                )
              }
              close_path={build_path(@base_path, @filter_params, nil, @dark_chrome)}
              previous_path={
                neighbor_path(
                  "prev",
                  @records,
                  @selected_record,
                  @base_path,
                  @filter_params,
                  @dark_chrome,
                  false
                )
              }
              next_path={
                neighbor_path(
                  "next",
                  @records,
                  @selected_record,
                  @base_path,
                  @filter_params,
                  @dark_chrome,
                  false
                )
              }
              position={record_position(@records, @selected_record, @records_page_meta)}
              keyboard?={not @replay_modal_open?}
            />

            <%!-- The modal hook contains focus; this sentinel returns focus to the trigger when it closes. --%>
            <span
              :if={@replay_modal_open?}
              phx-remove={JS.focus(to: "##{@replay_trigger_id}")}
            />

            <%!-- Re-redact focus return (D-11): a one-shot sentinel returns focus to the reveal disclosure button after collapsing a revealed payload. --%>
            <span
              :if={@focus_reveal_after_redact}
              phx-mounted={JS.focus(to: "#inbound-evidence-reveal-btn")}
            />
            <ReplayModal.replay_modal
              open?={@replay_modal_open?}
              record={selected_record_struct(@detail) || @selected_record}
              review={@replay_review}
              feedback={@replay_dialog_feedback}
            />
        <% end %>
      <% end %>
    </MailglassAdmin.Operator.Shell.shell>
    """
  end

  # ---------------------------------------------------------------------------
  # State aggregation — list + selected record + timeline + detail in one pass
  # through the runtime gateway (apply/3). No bare optional-inbound reference.
  # ---------------------------------------------------------------------------

  # Resolve the requested ID independently of the current list page/filter for both
  # Quick view and Full detail. The exact detail read is tenant-scoped by the gateway;
  # timeline, routing and evidence are loaded only for Full detail.
  #
  # Selecting (or re-selecting) a record collapses the evidence card back to redacted —
  # reveal is a per-view capability action, never sticky across selections.
  defp assign_inbound_state(socket, filter_params, selected_inbound_id, full?) do
    query_key = inbound_query_key(filter_params)

    {records_page, records_read_state} =
      case load_inbound_records_page(filter_params) do
        {_page, :read_unavailable}
        when socket.assigns.records != [] and socket.assigns.inbound_loaded_for == query_key ->
          # Same query, failed re-read: keep the rows on screen under a labelled stale panel.
          {Map.put(socket.assigns.records_page_meta, :entries, socket.assigns.records), :stale}

        result ->
          result
      end

    records = Map.get(records_page, :entries, [])

    {empty_state, records_read_state} =
      empty_state_for(filter_params, records_page, records_read_state)

    {summary, summary_read_state} = load_inbound_summary(filter_params)

    # The load time belongs to the rows on screen: stamped only by a successful read and
    # carried unchanged through a failed one (a new-query failure shows no rows at all).
    inbound_loaded_at =
      if records_read_state == :ok,
        do: DateTime.utc_now() |> DateTime.truncate(:second),
        else: socket.assigns.inbound_loaded_at

    inbound_loaded_for =
      if records_read_state == :ok, do: query_key, else: socket.assigns.inbound_loaded_for

    socket =
      socket
      |> assign(:full_detail?, full?)
      |> assign(:records, records)
      |> assign(:records_page_meta, page_meta_without_entries(records_page))
      |> assign(:inbound_summary, summary)
      |> assign(:records_read_state, records_read_state)
      |> assign(:inbound_loaded_for, inbound_loaded_for)
      |> assign(:inbound_loaded_at, inbound_loaded_at)
      |> assign(
        :results_status_text,
        ResultsStatus.text(%{
          collection: :inbound,
          state: results_status_state(records_read_state),
          count: Map.get(records_page, :total_count),
          filters_active?: filters_active?(filter_params),
          loaded_at: inbound_loaded_at
        })
      )
      |> assign(:summary_read_state, summary_read_state)
      |> assign(:empty_state, empty_state)
      |> assign(:reveal_state, :redacted)
      |> assign(:focus_reveal_after_redact, false)

    {detail, detail_read_state} = load_selected_detail(filter_params, selected_inbound_id)

    {runs, timeline_read_state} =
      if full? do
        load_selected_timeline(filter_params, selected_inbound_id, detail)
      else
        {[], :not_requested}
      end

    timeline_read_at = if full? and timeline_read_state == :ok, do: DateTime.utc_now(), else: nil

    selected_record =
      find_selected_record(records, selected_inbound_id) || list_projection_from_detail(detail)

    detail_error = detail_error_for(selected_inbound_id, detail, detail_read_state)

    replay_eligibility =
      replay_eligibility_for(filter_params, selected_inbound_id, detail, detail_read_state)

    selected_outside_results? =
      records_read_state == :ok and not is_nil(selected_record) and
        is_nil(find_selected_record(records, selected_inbound_id))

    quick_view_focus_return_id =
      case {socket.assigns.quick_view_focus_surface, selected_record} do
        {surface, %{id: id}} when surface in ["desktop", "mobile"] ->
          if Enum.any?(records, &(&1.id == id)),
            do: "inbound-record-open-#{surface}-#{id}"

        _ ->
          nil
      end

    socket
    |> assign(:selected_record, selected_record)
    |> assign(:selected_outside_results?, selected_outside_results?)
    |> assign(:quick_view_focus_return_id, quick_view_focus_return_id)
    |> assign(:detail, if(full?, do: detail, else: nil))
    |> assign(:replay_eligibility, replay_eligibility)
    |> assign(:runs, runs)
    |> assign(:detail_read_state, detail_read_state)
    |> assign(:timeline_read_state, timeline_read_state)
    |> assign(:timeline_read_at, timeline_read_at)
    |> assign(:replay_feedback, nil)
    |> assign(:replay_dialog_feedback, nil)
    |> assign(
      :routing_trace,
      if(full?, do: routing_trace_for(socket.assigns.inbound_router, detail), else: [])
    )
    |> assign(:detail_error, detail_error)
    |> assign(:data_state, records_data_state(records_read_state))
  end

  defp tenant_state(nil, [], _tenant_param_present?), do: :none
  defp tenant_state(nil, [_tenant], false), do: :auto_select
  defp tenant_state(nil, _tenants, _tenant_param_present?), do: :select_required
  defp tenant_state(_selected_tenant_id, _tenants, _tenant_param_present?), do: :selected

  defp clear_surface_state(socket) do
    socket
    |> assign(:pending_commit_kind, nil)
    |> assign(:last_commit_kind, nil)
    |> assign(:full_detail?, false)
    |> assign(:records, [])
    |> assign(:records_page_meta, empty_page_meta())
    |> assign(:inbound_summary, @zero_summary)
    |> assign(:records_read_state, :ok)
    |> assign(:summary_read_state, :ok)
    |> assign(:detail_read_state, :ok)
    |> assign(:replay_eligibility, nil)
    |> assign(:timeline_read_state, :not_requested)
    |> assign(:timeline_read_at, nil)
    |> assign(:provider_options_state, :ok)
    |> assign(:empty_state, :no_tenant)
    |> assign(:selected_record, nil)
    |> assign(:selected_outside_results?, false)
    |> assign(:quick_view_focus_surface, nil)
    |> assign(:quick_view_focus_return_id, nil)
    |> assign(:detail, nil)
    |> assign(:runs, [])
    |> assign(:routing_trace, [])
    |> assign(:reveal_state, :redacted)
    |> assign(:focus_reveal_after_redact, false)
    |> assign(:detail_error, nil)
    |> assign(:data_state, nil)
  end

  # Routing-trace data (IADM-04) — ONLY for a :no_match record. Reflected from the
  # adopter's declared inbound router via the runtime gateway (-06); the view
  # never re-implements match semantics. Any other outcome (or no detail) yields
  # [] so the card is omitted entirely.
  defp routing_trace_for(_inbound_router, nil), do: []

  defp routing_trace_for(inbound_router, %{outcome: :no_match, record: record}) do
    if gateway_available?() do
      apply(@gateway, :explain_routes, [inbound_router, record])
    else
      []
    end
  end

  defp routing_trace_for(_inbound_router, _detail), do: []

  # ---------------------------------------------------------------------------
  # Replay confirm flow (IADM-03) — tenant gate + capability gate + structured
  # error → UI-SPEC copy.
  # ---------------------------------------------------------------------------

  # The modal is a review snapshot, not an authorization token. Opening or
  # refreshing it reads the selected ID again inside the active Account and
  # then reads the recorded Mailbox eligibility for that exact record.
  defp fresh_replay_snapshot(socket) do
    selected_id = current_selected_record_id(socket)
    tenant_id = socket.assigns.filter_params["tenant_id"]

    cond do
      not is_binary(selected_id) or selected_id == "" ->
        if socket.assigns.detail_error, do: {:error, :cross_tenant}, else: {:error, :no_selection}

      not is_binary(tenant_id) or tenant_id == "" ->
        {:error, :cross_tenant}

      true ->
        case load_detail(socket.assigns.filter_params, selected_id) do
          {%{record: record}, :ok}
          when is_map(record) and record.id == selected_id and record.tenant_id == tenant_id ->
            eligibility =
              case read_replay_eligibility(record.id, record.tenant_id) do
                {:ok, result} ->
                  result

                {:error, reason} ->
                  %{status: :ineligible, reason: eligibility_failure_reason(reason)}
              end

            {:ok, record, eligibility}

          {nil, :ok} ->
            {:error, :cross_tenant}

          {_detail, :read_unavailable} ->
            {:error, :read_unavailable}

          {_detail, :package_unavailable} ->
            {:error, :package_unavailable}

          _other ->
            {:error, :cross_tenant}
        end
    end
  end

  defp current_selected_record_id(%{assigns: %{detail: %{record: record}}}),
    do: Map.get(record, :id)

  defp current_selected_record_id(%{assigns: %{selected_record: %{id: record_id}}}),
    do: record_id

  defp current_selected_record_id(_socket), do: nil

  defp replay_review(record, eligibility) do
    %{
      review_id: System.unique_integer([:positive]),
      tenant_id: record.tenant_id,
      record_id: record.id,
      eligibility: eligibility
    }
  end

  defp replay_trigger_id(%{"origin" => "quick"}), do: "inbound-quick-replay-open-btn"
  defp replay_trigger_id(_params), do: "inbound-replay-open-btn"

  defp submit_replay_review(socket) do
    result =
      with {:ok, record} <- revalidate_replay_review(socket),
           {:ok, authorized_socket} <-
             DestructiveAction.authorize(
               socket,
               socket.assigns.operator_auth[:adapter],
               record
             ),
           {:ok, replay_result} <- replay_record(record) do
        {:ok, authorized_socket, record, replay_result}
      end

    case result do
      {:ok, authorized_socket, _record, replay_result} ->
        record_id = socket.assigns.replay_review.record_id

        authorized_socket
        |> close_replay_modal()
        |> assign_inbound_state(
          socket.assigns.filter_params,
          record_id,
          socket.assigns.full_detail?
        )
        |> push_event("mailglass:toast", %{
          message: replay_result_copy(replay_result),
          error: false
        })

      {:error, :stale_review} ->
        replay_dialog_feedback(
          socket,
          :error,
          "Replay review is stale. Review again to check the selected record and recorded Mailbox."
        )

      {:error, :no_selection} ->
        replay_dialog_feedback(
          socket,
          :error,
          "The selected Inbound message could not be checked. Review the record again before confirming."
        )

      {:error, :cross_tenant} ->
        replay_dialog_feedback(
          socket,
          :error,
          "Replay blocked: this action is not authorized for the current operator. Review the selected record again."
        )

      {:error, {:auth, message}} ->
        replay_dialog_feedback(socket, :error, message)

      {:error, reason} ->
        replay_dialog_feedback(
          socket,
          :error,
          "Replay could not be started. No run was recorded. " <>
            replay_error_copy(reason) <> " Review again to check the record before retrying."
        )
    end
  end

  defp replay_dialog_feedback(socket, kind, message) do
    socket
    |> assign(:replay_pending_review_id, nil)
    |> assign(:replay_dialog_feedback, %{kind: kind, text: message})
  end

  defp replay_feedback(socket, kind, message) do
    socket
    |> assign(:replay_pending_review_id, nil)
    |> assign(:replay_feedback, %{kind: kind, text: message})
    |> put_flash(if(kind == :error, do: :error, else: :info), message)
  end

  @doc false
  def replay_result_copy(%{status: status}) when status in [:queued, :requested],
    do: "Replay requested. The runtime reported that this replay is queued."

  def replay_result_copy(%{outcome: :failed}),
    do: "Replay run recorded. Mailbox execution failed."

  def replay_result_copy(%{outcome: :no_change}),
    do: "Replay run recorded. Mailbox outcome: No change."

  def replay_result_copy(%{outcome: :accept}),
    do: "Replay run recorded. Mailbox outcome: Accepted."

  def replay_result_copy(%{outcome: :ignore}),
    do: "Replay run recorded. Mailbox outcome: Ignored."

  def replay_result_copy(%{outcome: :reject}),
    do: "Replay run recorded. Mailbox outcome: Rejected."

  def replay_result_copy(%{outcome: :bounce}),
    do: "Replay run recorded. Mailbox outcome: Bounced."

  def replay_result_copy(%{outcome: :no_match}),
    do: "Replay run recorded. Mailbox outcome: No mailbox matched."

  def replay_result_copy(_result),
    do: "Replay run recorded. Mailbox outcome is unavailable."

  defp refresh_selected_timeline(socket) do
    case socket.assigns do
      %{full_detail?: true, detail: %{record: %{id: record_id}}} ->
        refresh_selected_timeline_for(socket, record_id)

      _assigns ->
        socket
    end
  end

  defp refresh_selected_timeline_for(socket, record_id) do
    {runs, read_state} = load_timeline(socket.assigns.filter_params, record_id)

    socket
    |> assign(:runs, if(read_state == :ok, do: runs, else: []))
    |> assign(:timeline_read_state, read_state)
    |> maybe_assign_timeline_read_at(read_state)
  end

  defp maybe_assign_timeline_read_at(socket, :ok),
    do: assign(socket, :timeline_read_at, DateTime.utc_now())

  defp maybe_assign_timeline_read_at(socket, _read_state), do: socket

  # The modal is a review snapshot, not an authorization token. Confirmation
  # requires the same open review, Account and selected ID, then repeats both
  # tenant-scoped reads before the host authorization decision.
  defp revalidate_replay_review(
         %{
           assigns: %{
             replay_modal_open?: true,
             replay_review: %{
               tenant_id: reviewed_tenant,
               record_id: reviewed_id,
               eligibility: reviewed_eligibility
             }
           }
         } = socket
       ) do
    cond do
      not eligible_replay_target?(reviewed_eligibility) ->
        {:error,
         {:replay_mailbox_missing,
          %{reason: Map.get(reviewed_eligibility, :reason, :invalid_mailbox)}}}

      socket.assigns.filter_params["tenant_id"] != reviewed_tenant ->
        {:error, :stale_review}

      current_detail_record_id(socket) != reviewed_id ->
        {:error, :stale_review}

      true ->
        reread_replay_target(socket, reviewed_tenant, reviewed_id, reviewed_eligibility)
    end
  end

  defp revalidate_replay_review(%{assigns: %{detail_error: error}})
       when not is_nil(error),
       do: {:error, :cross_tenant}

  defp revalidate_replay_review(_socket), do: {:error, :review_not_open}

  defp current_detail_record_id(%{assigns: %{detail: %{record: record}}}),
    do: Map.get(record, :id)

  defp current_detail_record_id(_socket), do: nil

  defp reread_replay_target(socket, reviewed_tenant, reviewed_id, reviewed_eligibility) do
    case load_detail(socket.assigns.filter_params, reviewed_id) do
      {%{record: record}, :ok}
      when is_map(record) and record.id == reviewed_id and record.tenant_id == reviewed_tenant ->
        case read_replay_eligibility(reviewed_id, reviewed_tenant) do
          {:ok, fresh_eligibility} when fresh_eligibility == reviewed_eligibility ->
            {:ok, record}

          {:ok, _changed_eligibility} ->
            {:error, :stale_review}

          {:error, :not_found} ->
            {:error, :cross_tenant}

          {:error, reason} ->
            {:error, reason}
        end

      {nil, :ok} ->
        {:error, :cross_tenant}

      {_detail, :read_unavailable} ->
        {:error, :read_unavailable}

      {_detail, :package_unavailable} ->
        {:error, :package_unavailable}

      _other ->
        {:error, :stale_review}
    end
  end

  defp eligible_replay_target?(%{status: :eligible, mailbox: mailbox}),
    do: is_binary(mailbox) and mailbox != ""

  defp eligible_replay_target?(_eligibility), do: false

  defp read_replay_eligibility(record_id, tenant_id) do
    if gateway_available?() do
      case ReadResult.fetch(fn ->
             {:eligibility, apply(@gateway, :eligibility, [record_id, [tenant_id: tenant_id]])}
           end) do
        {:ok, {:eligibility, {:ok, %{status: :eligible, mailbox: mailbox} = result}}}
        when is_binary(mailbox) and mailbox != "" ->
          {:ok, result}

        {:ok, {:eligibility, {:ok, %{status: :ineligible, reason: reason} = result}}}
        when reason in [
               :no_prior_match,
               :execution_history_missing,
               :invalid_mailbox,
               :mailbox_unavailable,
               :missing_evidence
             ] ->
          {:ok, result}

        {:ok, {:eligibility, {:error, :not_found}}} ->
          {:error, :not_found}

        {:error, :read_unavailable} ->
          {:error, :read_unavailable}

        _other ->
          {:error, :read_unavailable}
      end
    else
      {:error, :package_unavailable}
    end
  end

  defp eligibility_failure_reason(:not_found), do: :record_unavailable
  defp eligibility_failure_reason(:read_unavailable), do: :read_unavailable
  defp eligibility_failure_reason(:package_unavailable), do: :package_unavailable
  defp eligibility_failure_reason(_reason), do: :read_unavailable

  # `record` is already tenant-resolved (read-model load) AND verify_tenant/2 has
  # confirmed record.tenant_id == active tenant. Thread that tenant_id into the
  # tenant-scoped replay/2 (T-49-17): the admin gate is now backed by a replay seam
  # that refuses cross-tenant ids by construction, not just by this caller's check.
  defp replay_record(%{id: record_id, tenant_id: tenant_id}) do
    if gateway_available?() do
      apply(@gateway, :replay, [record_id, [tenant_id: tenant_id]])
    else
      {:error, :unavailable}
    end
  end

  # Map the structured replay errors to UI-SPEC copy by matching the tuple/struct,
  # never the message string (CLAUDE.md rule 7).
  #
  # `:replay_mailbox_missing` carries a `:reason` that distinguishes three
  # genuinely different situations. Collapsing them into one "mailbox module not
  # found" line misattributed all three — most damagingly for `:invalid_mailbox`,
  # where it read as a misconfiguration the operator could fix when in fact
  # nothing they can do will make the row replayable.
  defp replay_error_copy({:replay_mailbox_missing, %{reason: :invalid_mailbox}}),
    do:
      "Replay unavailable: this message was received before mailglass_inbound 2.6 recorded a durable route binding, so its mailbox cannot be resolved safely. Messages received since then replay normally."

  defp replay_error_copy({:replay_mailbox_missing, %{reason: :no_prior_match}}),
    do:
      "Replay unavailable: no mailbox matched this message when it was received, so there is no route to replay it through."

  defp replay_error_copy({:replay_mailbox_missing, %{reason: :execution_history_missing}}),
    do: "Replay unavailable: this message has no recorded execution history to replay from."

  defp replay_error_copy({:replay_mailbox_missing, _details}),
    do: "Replay unavailable: this message has no resolvable mailbox route."

  defp replay_error_copy(:not_found),
    do:
      "This inbound message is unavailable in the selected Account or current results. Refresh the page or adjust the filters, then try again."

  defp replay_error_copy(:unavailable),
    do: "Replay blocked: the inbound package is not available."

  defp replay_error_copy(:read_unavailable),
    do:
      "Replay blocked: inbound data is temporarily unavailable. Refresh the page or try again shortly."

  defp replay_error_copy(:package_unavailable),
    do: "Replay blocked: inbound support is not available."

  defp replay_error_copy(_reason),
    do:
      "This inbound message is unavailable in the selected Account or current results. Refresh the page or adjust the filters, then try again."

  defp empty_state_for(%{"tenant_id" => tenant_id}, _page, _read_state)
       when tenant_id in [nil, ""],
       do: {:no_tenant, :ok}

  defp empty_state_for(_filter_params, _page, read_state) when read_state != :ok,
    do: {:filtered, read_state}

  defp empty_state_for(filter_params, page, :ok) do
    entries = Map.get(page, :entries, [])

    cond do
      Map.get(page, :total_count, 0) > 0 and
          Map.get(page, :page, 1) > Map.get(page, :total_pages, 0) ->
        {:out_of_range, :ok}

      entries != [] ->
        {:filtered, :ok}

      filters_active?(filter_params) ->
        {:filtered, :ok}

      true ->
        case tenant_has_inbound_history?(filter_params) do
          {:ok, true} -> {:filtered, :ok}
          {:ok, false} -> {:truly_empty, :ok}
          {:error, read_state} -> {:filtered, read_state}
        end
    end
  end

  defp filters_active?(filter_params) do
    Enum.any?(["provider", "search", "outcome"], fn key ->
      not is_nil(blank_to_nil(Map.get(filter_params, key)))
    end) or
      non_default_window?(Map.get(filter_params, "window_hours")) or
      non_default_window?(Map.get(filter_params, "recent_window_hours"))
  end

  # Committed filters only (the URL-backed params, never the draft), so the mobile toggle
  # tells the truth about what the list is narrowed by. The default window is not a filter.
  defp applied_filter_count(filter_params) do
    window_applied? = non_default_window?(Map.get(filter_params, "window_hours"))

    ["search", "outcome", "provider"]
    |> Enum.count(&(not is_nil(blank_to_nil(Map.get(filter_params, &1)))))
    |> Kernel.+(if window_applied?, do: 1, else: 0)
  end

  defp non_default_window?(nil), do: false
  defp non_default_window?(""), do: false

  defp non_default_window?(value) do
    parse_positive_integer(value) != @default_window_hours
  end

  defp tenant_has_inbound_history?(filter_params) do
    {records, read_state} = load_inbound_records(tenant_history_params(filter_params))

    case read_state do
      :ok -> {:ok, Enum.any?(records)}
      unavailable -> {:error, unavailable}
    end
  end

  defp tenant_history_params(filter_params) do
    %{
      "tenant_id" => filter_params["tenant_id"],
      "provider" => "",
      "outcome" => "",
      "window_hours" => Integer.to_string(@default_window_hours * 5200),
      "search" => ""
    }
  end

  # ---------------------------------------------------------------------------
  # Live-update prepend (IADM-05) — tenant-scoped re-fetch, no selection/filter theft.
  # ---------------------------------------------------------------------------

  defp prepend_live_record(socket, record_id) do
    filter_params = socket.assigns.filter_params

    case fetch_live_record(filter_params, record_id) do
      nil ->
        socket

      record ->
        records = socket.assigns.records

        if Enum.any?(records, &(&1.id == record.id)) do
          socket
        else
          assign(socket, :records, [record | records])
        end
    end
  end

  # Re-fetch the inserted record tenant-scoped. Reuses the list read-model and
  # picks the matching id so the projection shape matches the existing list rows
  # (and a foreign-tenant / filtered-out id resolves to nil).
  defp fetch_live_record(%{"tenant_id" => ""}, _record_id), do: nil

  defp fetch_live_record(filter_params, record_id) do
    case load_inbound_records(filter_params) do
      {records, :ok} -> Enum.find(records, &(&1.id == record_id))
      {_records, _unavailable} -> nil
    end
  end

  # Tenant-required-or-empty (-04) — the load-bearing security head BEFORE any
  # data call. A blank tenant yields [] without touching the gateway.
  defp load_inbound_records(%{"tenant_id" => tenant_id}) when tenant_id in [nil, ""],
    do: {[], :ok}

  defp load_inbound_records(filter_params) do
    case load_inbound_records_page(filter_params) do
      {page, :ok} -> {Map.fetch!(page, :entries), :ok}
      {_page, unavailable} -> {[], unavailable}
    end
  end

  # Provider filter options (mirrors Operator.load_provider_options/1): distinct
  # providers seen for the selected account within the window, plus the currently
  # selected provider so a chosen-but-unseen value never silently drops from the
  # select. Empty when there is no tenant or the inbound gateway is unavailable.
  defp load_provider_options(filter_params) do
    selected_provider = blank_to_nil(filter_params["provider"])

    {providers, state} =
      case blank_to_nil(filter_params["tenant_id"]) do
        nil ->
          {[], :ok}

        tenant_id ->
          if gateway_available?() do
            filters = %{
              tenant_id: tenant_id,
              window_hours:
                parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
            }

            case ReadResult.fetch(fn -> apply(@gateway, :list_providers, [filters, []]) end) do
              {:ok, providers} -> {providers, :ok}
              {:error, :read_unavailable} -> {[], :read_unavailable}
            end
          else
            {[], :package_unavailable}
          end
      end

    providers =
      if selected_provider && selected_provider not in providers do
        [selected_provider | providers]
      else
        providers
      end

    options =
      providers
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort_by(&String.downcase/1)
      |> Enum.map(&{provider_label(&1), &1})

    {options, state}
  end

  defp provider_label("sendgrid"), do: "SendGrid"
  defp provider_label("postmark"), do: "Postmark"
  defp provider_label("mailgun"), do: "Mailgun"
  defp provider_label("ses"), do: "SES"

  defp provider_label(provider) when is_binary(provider) do
    provider
    |> String.replace(["_", "-"], " ")
    |> String.split(" ", trim: true)
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp load_inbound_records_page(%{"tenant_id" => tenant_id}) when tenant_id in [nil, ""],
    do: {empty_page_meta(), :ok}

  defp load_inbound_records_page(filter_params) do
    inbound_read(
      fn ->
        apply(@gateway, :list_records_page, [
          %{
            tenant_id: filter_params["tenant_id"],
            provider: blank_to_nil(filter_params["provider"]),
            outcome: cast_enum(filter_params["outcome"], @outcome_values),
            window_hours:
              parse_positive_integer(filter_params["window_hours"]) || @default_window_hours,
            search: blank_to_nil(filter_params["search"]),
            page: parse_positive_integer(filter_params["page"]) || 1,
            per_page: @inbound_records_per_page
          },
          []
        ])
      end,
      empty_page_meta()
    )
  end

  defp load_inbound_summary(%{"tenant_id" => tenant_id})
       when tenant_id in [nil, ""],
       do: {@zero_summary, :ok}

  defp load_inbound_summary(filter_params) do
    summary_filters = %{
      tenant_id: filter_params["tenant_id"],
      provider: blank_to_nil(filter_params["provider"]),
      window_hours:
        parse_positive_integer(filter_params["window_hours"]) || @default_window_hours,
      search: blank_to_nil(filter_params["search"])
    }

    inbound_read(fn -> apply(@gateway, :summary, [summary_filters, []]) end, @zero_summary)
  end

  defp load_detail(%{"tenant_id" => tenant_id}, _selected_inbound_id) when tenant_id in [nil, ""],
    do: {nil, :ok}

  defp load_detail(_filter_params, nil), do: {nil, :ok}

  defp load_detail(filter_params, selected_inbound_id) do
    if valid_uuid?(selected_inbound_id) do
      inbound_read(
        fn ->
          apply(@gateway, :detail, [
            %{tenant_id: filter_params["tenant_id"], inbound_record_id: selected_inbound_id},
            []
          ])
        end,
        nil
      )
    else
      {nil, :ok}
    end
  end

  defp load_timeline(%{"tenant_id" => tenant_id}, _selected_inbound_id)
       when tenant_id in [nil, ""],
       do: {[], :ok}

  defp load_timeline(_filter_params, nil), do: {[], :ok}

  defp load_timeline(filter_params, selected_inbound_id) do
    if valid_uuid?(selected_inbound_id) do
      inbound_read(
        fn ->
          apply(@gateway, :timeline, [
            %{tenant_id: filter_params["tenant_id"], inbound_record_id: selected_inbound_id},
            []
          ])
        end,
        []
      )
    else
      {[], :ok}
    end
  end

  defp inbound_read(read, fallback) do
    if gateway_available?() do
      case ReadResult.fetch(read) do
        {:ok, value} -> {value, :ok}
        {:error, :read_unavailable} -> {fallback, :read_unavailable}
      end
    else
      {fallback, :package_unavailable}
    end
  end

  defp find_selected_record(_records, nil), do: nil
  defp find_selected_record(records, inbound_id), do: Enum.find(records, &(&1.id == inbound_id))

  defp load_selected_detail(filter_params, selected_inbound_id),
    do: load_detail(filter_params, selected_inbound_id)

  defp replay_eligibility_for(_filter_params, nil, _detail, _detail_read_state), do: nil

  defp replay_eligibility_for(filter_params, selected_id, %{record: record}, :ok)
       when is_binary(selected_id) and is_map(record) do
    tenant_id = filter_params["tenant_id"]

    if Map.get(record, :id) == selected_id and Map.get(record, :tenant_id) == tenant_id do
      case read_replay_eligibility(selected_id, tenant_id) do
        {:ok, eligibility} -> eligibility
        {:error, reason} -> %{status: :ineligible, reason: eligibility_failure_reason(reason)}
      end
    else
      %{status: :ineligible, reason: :record_unavailable}
    end
  end

  defp replay_eligibility_for(_filter_params, _selected_id, _detail, :read_unavailable),
    do: %{status: :ineligible, reason: :read_unavailable}

  defp replay_eligibility_for(_filter_params, _selected_id, _detail, :package_unavailable),
    do: %{status: :ineligible, reason: :package_unavailable}

  defp replay_eligibility_for(_filter_params, _selected_id, _detail, _detail_read_state),
    do: %{status: :ineligible, reason: :record_unavailable}

  defp load_selected_timeline(_filter_params, nil, _detail), do: {[], :not_requested}
  defp load_selected_timeline(_filter_params, _selected_inbound_id, nil), do: {[], :not_requested}

  defp load_selected_timeline(filter_params, selected_inbound_id, _detail),
    do: load_timeline(filter_params, selected_inbound_id)

  defp list_projection_from_detail(nil), do: nil

  defp list_projection_from_detail(%{record: record} = detail) do
    %{
      id: Map.get(record, :id),
      tenant_id: Map.get(record, :tenant_id),
      provider: Map.get(record, :provider),
      provider_message_id: Map.get(record, :provider_message_id),
      message_id: Map.get(record, :message_id),
      envelope_recipient: Map.get(record, :envelope_recipient),
      subject: Map.get(record, :subject),
      received_at: Map.get(record, :received_at),
      inserted_at: Map.get(record, :inserted_at),
      suppression_flagged: Map.get(record, :suppression_flagged),
      outcome: Map.get(detail, :outcome),
      mailbox: Map.get(detail, :mailbox)
    }
  end

  defp valid_uuid?(value) when is_binary(value) do
    match?({:ok, _uuid}, Ecto.UUID.cast(value))
  end

  defp valid_uuid?(_value), do: false

  # Foreign and missing IDs keep identical non-disclosing copy. Read failures use
  # distinct global/package states because the ID was not successfully checked.
  defp detail_error_for(nil, _detail, _read_state), do: nil
  defp detail_error_for(_inbound_id, _detail, :package_unavailable), do: :package_unavailable
  defp detail_error_for(_inbound_id, _detail, :read_unavailable), do: :read_unavailable
  defp detail_error_for(_inbound_id, nil, _read_state), do: :not_found
  defp detail_error_for(_inbound_id, _detail, _read_state), do: nil

  defp detail_error_copy(:package_unavailable),
    do: "Inbound support is unavailable. The selected record could not be checked."

  defp detail_error_copy(:read_unavailable),
    do:
      "This record could not be checked because inbound data is temporarily unavailable. Refresh the page or try again shortly."

  defp detail_error_copy(_reason),
    do:
      "This inbound message could not be loaded in the selected Account. Check the record ID and try again."

  defp records_data_state(:ok), do: nil
  defp records_data_state(:package_unavailable), do: :package_unavailable
  defp records_data_state(:read_unavailable), do: :read_unavailable
  defp records_data_state(:stale), do: :stale

  defp results_status_state(:ok), do: :ready
  defp results_status_state(:stale), do: :stale
  defp results_status_state(_unavailable), do: :error

  defp initial_results_status_text do
    ResultsStatus.text(%{
      collection: :inbound,
      state: :ready,
      count: 0,
      filters_active?: false,
      loaded_at: nil
    })
  end

  # The committed query a successful read belongs to. A failed re-read of the same key
  # keeps its rows as stale; any other key is a new query and shows an error instead.
  defp inbound_query_key(filter_params),
    do:
      Map.take(filter_params, [
        "tenant_id",
        "provider",
        "outcome",
        "search",
        "window_hours",
        "page"
      ])

  defp requested_inbound_id(socket) do
    with %URI{query: query} when is_binary(query) <- URI.parse(socket.assigns.page_uri),
         id when is_binary(id) <- URI.decode_query(query)["inbound_id"] do
      blank_to_nil(id)
    else
      _ -> nil
    end
  end

  defp url_invalid_notes(filter_errors) do
    [
      {"outcome", "Showing results without the Mailbox outcome filter."},
      {"window_hours", "Showing results for the default time window instead."}
    ]
    |> Enum.filter(fn {field, _note} -> Map.has_key?(filter_errors, field) end)
    |> Enum.map(&elem(&1, 1))
  end

  defp selected_record_struct(nil), do: nil
  defp selected_record_struct(%{record: record}), do: record

  defp gateway_available? do
    inbound_gateway_enabled?() and Code.ensure_loaded?(@gateway) and @gateway.available?()
  end

  defp inbound_gateway_enabled? do
    Application.get_env(:mailglass_admin, :inbound_gateway_available?, true)
  end

  # Rides the existing Auth.authorize/3 atom() action type with :reveal_raw — no
  # new auth module/plug/behaviour (-09). Returns :revealed on grant, :denied
  # otherwise. The adapter arrives from the operator Mount hook.
  defp authorize_reveal(socket) do
    adapter = socket.assigns.operator_auth[:adapter]

    if is_atom(adapter) and not is_nil(adapter) do
      case MailglassAdmin.Auth.authorize(adapter, :reveal_raw, %{
             actor: socket.assigns.operator_actor
           }) do
        {:ok, _result} -> :revealed
        {:error, _reason, _details} -> :denied
      end
    else
      :denied
    end
  end

  # Maps the pure authorize_reveal/1 reveal_state atom to a telemetry outcome at
  # the call-site (NOT inside the pure helper). :revealed -> :granted, anything
  # else (:denied) -> :denied.
  defp reveal_outcome(:revealed), do: :granted
  defp reveal_outcome(_other), do: :denied

  # PII-free reveal-audit emit (D-12). mailglass_admin has no telemetry today, so
  # this is a single fire-and-forget :telemetry.execute/3 (not a full span).
  # Metadata is whitelisted to tenant_id / record_id / outcome — NEVER
  # payload/body/headers/recipient/email (CLAUDE.md PII rule). Durable persisted
  # reveal-audit is deferred (Phase 123+).
  defp emit_reveal_telemetry(socket, outcome) do
    :telemetry.execute(
      [:mailglass_admin, :inbound, :reveal_raw, :stop],
      %{count: 1},
      %{
        tenant_id: blank_to_nil(socket.assigns.filter_params["tenant_id"]),
        record_id: reveal_record_id(socket.assigns.detail),
        outcome: outcome
      }
    )
  end

  defp reveal_record_id(%{record: %{id: id}}), do: id
  defp reveal_record_id(_detail), do: nil

  # ---------------------------------------------------------------------------
  # URL <-> filter param plumbing (cloned from OperatorLive).
  # ---------------------------------------------------------------------------

  defp default_filter_params do
    %{
      "tenant_id" => "",
      "provider" => "",
      "outcome" => "",
      "window_hours" => Integer.to_string(@default_window_hours),
      "search" => "",
      "page" => "1"
    }
  end

  # A rejected outcome or window stays in the draft so the select never contradicts its
  # error (D-12). Only a field that actually carries an error keeps its raw value, so a
  # blank or zero-padded value normalizes quietly instead of becoming a "Custom period".
  defp filter_draft_params(params, normalized, filter_errors) do
    Enum.reduce(["outcome", "window_hours"], normalized, fn key, draft ->
      if Map.has_key?(filter_errors, key) and Map.has_key?(params, key),
        do: Map.put(draft, key, normalize_string(Map.get(params, key))),
        else: draft
    end)
  end

  defp normalize_filter_params_with_errors(params) do
    defaults = default_filter_params()

    {outcome, outcome_error} =
      normalize_enum_filter(params, "outcome", @outcome_values, @outcome_filter_error)

    {window_hours, window_error} = normalize_window_filter(params, defaults)

    filter_params = %{
      "tenant_id" => normalize_string(Map.get(params, "tenant_id", defaults["tenant_id"])),
      "provider" => normalize_string(Map.get(params, "provider", defaults["provider"])),
      "outcome" => outcome,
      "window_hours" => window_hours,
      "search" => normalize_string(Map.get(params, "search", defaults["search"])),
      "page" => normalize_page(params, defaults)
    }

    {filter_params,
     filter_error_map([
       {"outcome", outcome_error},
       {"window_hours", window_error}
     ])}
  end

  defp close_replay_modal(socket) do
    socket
    |> assign(:replay_modal_open?, false)
    |> assign(:replay_review, nil)
    |> assign(:replay_pending_review_id, nil)
  end

  # Full-detail path = the record's URL plus `full=1`, merged into the params map (not
  # appended) so it sorts with the other keys. build_path drops a nil id (and page=1);
  # we only add `full` when there is an id to attach it to.
  defp detail_path(base_path, filter_params, inbound_id, dark_chrome, full?) do
    filter_params =
      if full? and not is_nil(inbound_id),
        do: Map.put(filter_params, "full", "1"),
        else: filter_params

    build_path(base_path, filter_params, inbound_id, dark_chrome)
  end

  # Prev/next id within the loaded page, relative to the current selection. Returns nil
  # at the page edges (no wrap) and when there is no selection.
  defp neighbor_id(records, %{id: id}, dir) do
    count = length(records)

    case Enum.find_index(records, &(&1.id == id)) do
      nil ->
        nil

      index ->
        case neighbor_index(index, dir, count) do
          nil -> nil
          neighbor -> records |> Enum.at(neighbor) |> record_id()
        end
    end
  end

  defp neighbor_id(_records, _selected, _dir), do: nil

  defp neighbor_index(index, "prev", _count) when index > 0, do: index - 1
  defp neighbor_index(index, "next", count) when index < count - 1, do: index + 1
  defp neighbor_index(_index, _dir, _count), do: nil

  defp record_id(%{id: id}), do: id
  defp record_id(_record), do: nil

  defp neighbor_path(dir, records, selected_record, base_path, filter_params, dark_chrome, full?) do
    case neighbor_id(records, selected_record, dir) do
      nil -> nil
      id -> detail_path(base_path, filter_params, id, dark_chrome, full?)
    end
  end

  # "N of M" position across the whole result set (page offset + local index).
  defp record_position(records, %{id: id}, page_meta) do
    with index when is_integer(index) <- Enum.find_index(records, &(&1.id == id)),
         total when is_integer(total) <- Map.get(page_meta, :total_count) do
      page = Map.get(page_meta, :page, 1)
      per_page = Map.get(page_meta, :per_page, @inbound_records_per_page)
      %{index: (page - 1) * per_page + index + 1, total: total}
    else
      _ -> nil
    end
  end

  defp record_position(_records, _selected, _page_meta), do: nil

  defp navigate_record(socket, dir) do
    case neighbor_id(socket.assigns.records, socket.assigns.selected_record, dir) do
      nil ->
        {:noreply, socket}

      id ->
        {:noreply,
         push_patch(socket,
           to:
             detail_path(
               socket.assigns.base_path,
               socket.assigns.filter_params,
               id,
               socket.assigns.dark_chrome,
               socket.assigns.full_detail?
             )
         )}
    end
  end

  # True when a target path points at the same location as the current URL — same path
  # and same query params (order-independent). Used to skip needless re-renders.
  defp same_location?(current_uri, target_path) do
    current = URI.parse(current_uri)
    target = URI.parse(target_path)

    # Entry URLs often omit window_hours while commit targets carry it, so both queries are
    # canonicalized (default window filled) before the comparison.
    (current.path || "/") == (target.path || "/") and
      canonical_location_query(current.query) == canonical_location_query(target.query)
  end

  defp canonical_location_query(query) do
    (query || "")
    |> URI.decode_query()
    |> FilterCommit.canonical_current_query()
    |> URI.decode_query()
  end

  # Every filter change is a commit (D-01). The Account comes from the server, never the
  # payload (D-09); an invalid draft stays a draft and never patches; a commit that
  # resolves to the current location is a no-op.
  defp commit_filters(socket, filters, kind) do
    filters = FilterCommit.commit_params(filters, socket.assigns.selected_tenant_id)
    {normalized, filter_errors} = normalize_filter_params_with_errors(filters)

    if map_size(filter_errors) == 0 do
      path = build_path(socket.assigns.base_path, normalized, nil, socket.assigns.dark_chrome)

      # A commit that lands on the current URL would still re-run handle_params and
      # re-render for nothing; skip it and just keep the draft in step.
      if same_location?(socket.assigns.page_uri, path) do
        {:noreply,
         socket
         |> assign(
           :filter_form,
           to_form(filter_draft_params(filters, normalized, filter_errors), as: :filters)
         )
         |> assign(:filter_errors, %{})
         |> assign(:filter_error_source, nil)}
      else
        {:noreply, push_commit(socket, path, kind)}
      end
    else
      {:noreply,
       socket
       |> assign(
         :filter_form,
         to_form(filter_draft_params(filters, normalized, filter_errors), as: :filters)
       )
       |> assign(:filter_errors, filter_errors)
       |> assign(:filter_error_source, :draft)}
    end
  end

  # The only place a commit patch is pushed. The pending kind is assigned here and nowhere
  # else, so a no-op or invalid commit can never mislabel the next non-commit patch.
  defp push_commit(socket, path, kind) do
    replace? = FilterCommit.history_kind(kind, socket.assigns.last_commit_kind) == :replace

    socket
    |> assign(:pending_commit_kind, kind)
    |> push_patch(to: path, replace: replace?)
  end

  # Moves the kind of the commit that produced this patch into last_commit_kind. A patch
  # that arrives without a pending kind (Back/Forward, pagination links, the Account
  # canonicalization) is not a commit and ends any in-flight search edit.
  defp settle_commit_kind(socket) do
    socket
    |> assign(:last_commit_kind, socket.assigns.pending_commit_kind)
    |> assign(:pending_commit_kind, nil)
  end

  defp build_path(base_path, filter_params, inbound_id, _dark_chrome) do
    params =
      filter_params
      |> Map.put("inbound_id", inbound_id)
      |> Enum.reject(fn
        {"page", "1"} -> true
        {_key, value} -> is_nil(blank_to_nil(value))
      end)
      |> Map.new()

    case FilterCommit.encode_query(params) do
      "" -> base_path
      query -> base_path <> "?" <> query
    end
  end

  defp pagination_path(base_path, filter_params, _dark_chrome, direction) do
    page = parse_positive_integer(filter_params["page"]) || 1

    next_page =
      case direction do
        :previous -> max(page - 1, 1)
        :next -> page + 1
      end

    filter_params = Map.put(filter_params, "page", Integer.to_string(next_page))
    build_path(base_path, filter_params, nil, false)
  end

  # V5 input-validation allow-list: an outcome outside the closed set casts to nil
  # (the filter is dropped) and never reaches SQL.
  defp cast_enum("", _allowed), do: nil

  defp cast_enum(value, allowed) when is_binary(value) do
    enum = String.to_existing_atom(value)
    if enum in allowed, do: enum, else: nil
  rescue
    ArgumentError -> nil
  end

  defp cast_enum(_value, _allowed), do: nil

  defp parse_positive_integer(value) when is_integer(value) and value > 0, do: value

  defp parse_positive_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _ -> nil
    end
  end

  defp parse_positive_integer(_value), do: nil

  defp normalize_page(params, defaults) do
    params
    |> Map.get("page", defaults["page"])
    |> parse_positive_integer()
    |> case do
      nil -> defaults["page"]
      page -> Integer.to_string(page)
    end
  end

  defp empty_page_meta do
    %{
      entries: [],
      total_count: 0,
      page: 1,
      per_page: @inbound_records_per_page,
      total_pages: 0,
      has_previous?: false,
      has_next?: false
    }
  end

  defp page_meta_without_entries(page) when is_map(page), do: Map.delete(page, :entries)

  defp normalize_enum_filter(params, field, allowed, message) do
    value = normalize_string(Map.get(params, field, ""))

    cond do
      value == "" -> {"", nil}
      enum_string_allowed?(value, allowed) -> {value, nil}
      true -> {"", message}
    end
  end

  defp enum_string_allowed?(value, allowed) do
    Enum.any?(allowed, &(Atom.to_string(&1) == value))
  end

  defp normalize_window_filter(params, defaults) do
    raw_value = Map.get(params, "window_hours", defaults["window_hours"])
    raw_string = normalize_string(raw_value)

    case parse_positive_integer(raw_value) do
      integer when is_integer(integer) ->
        {Integer.to_string(integer), nil}

      nil when raw_string == "" ->
        {Integer.to_string(@default_window_hours), nil}

      nil ->
        {Integer.to_string(@default_window_hours), @window_filter_error}
    end
  end

  defp filter_error_map(entries) do
    entries
    |> Enum.reject(fn {_field, error} -> is_nil(error) end)
    |> Map.new()
  end

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(_value), do: ""

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
