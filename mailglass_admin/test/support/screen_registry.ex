defmodule MailglassAdmin.TestSupport.ScreenRegistry do
  @moduledoc """
  Test-only. The list of admin screens and screen states that a whole-admin contract scans,
  so a screen cannot escape a rule by being new.

  Phase 182 introduced it for the time and status contract
  (`phase182_time_status_contract_test.exs`), and it is public so a later contract that
  scans the same screens (the Phase 182 words contract) reads one list instead of copying
  a second one. It is compiled with `elixirc_paths(:test)` and is never part of the
  published package.

  Four things live here:

    * `registry/0`: every `{LiveView module, action}` the test adopter router mounts, each
      with the kinds of state a scan renders for it. A contract compares this map's keys to
      `Phoenix.Router.routes/1` of `MailglassAdmin.TestAdopter.Router`, so a new LiveView
      route fails until it is registered here.
    * `known_component_modules/0`: every module that exports `__components__/0`, with the
      screen state or gallery specimen that renders it. A new component module fails the
      same contract until it is listed.
    * `states/1`: the concrete screen states (a path, and any LiveView events to send after
      it mounts) for the fixtures a caller has seeded.
    * `visible_text/1`: the text a reader sees, the one place that decides what a scan
      counts as visible.
  """

  alias MailglassAdmin.{GalleryLive, InboundLive, OperatorLive, PreviewLive}

  @tenant_id "browser-tenant"
  @operator_path "/ops/mail"
  @inbound_path "/ops/mail/inbound"
  @preview_index_path "/dev/mail"
  @preview_show_path "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
  @gallery_path "/dev/mail/gallery"
  # OperatorLive lists 20 deliveries per page (`@deliveries_per_page`). A drift here means
  # fewer pages are scanned, which the grid floors in the contract turn into a failure.
  @activity_per_page 20

  @registry %{
    {PreviewLive, :index} => [:preview_index],
    {PreviewLive, :show} => [:preview_show],
    {GalleryLive, :index} => [:gallery],
    {OperatorLive, :index} => [
      :operator_overview,
      :activity_page,
      :quick_view,
      :full_detail,
      :full_detail_provider_time,
      :replay_modal
    ],
    {InboundLive, :index} => [:inbound_list, :inbound_detail]
  }

  # module => the state kind (a `registry/0` value) or `:gallery` specimen that renders it.
  # `:every_screen` is for a module every screen is drawn through.
  @known_component_modules %{
    MailglassAdmin.AdminShell => :every_screen,
    MailglassAdmin.Components => :every_screen,
    MailglassAdmin.GalleryLive => :gallery,
    MailglassAdmin.Inbound.DetailHeader => :inbound_detail,
    MailglassAdmin.Inbound.EvidenceCard => :inbound_detail,
    MailglassAdmin.Inbound.FiltersForm => :inbound_list,
    MailglassAdmin.Inbound.Overview => :inbound_list,
    MailglassAdmin.Inbound.QuickView => :inbound_detail,
    MailglassAdmin.Inbound.RecordsList => :inbound_list,
    MailglassAdmin.Inbound.ReplayModal => :gallery,
    MailglassAdmin.Inbound.RoutingTrace => :inbound_detail,
    MailglassAdmin.Inbound.Timeline => :inbound_detail,
    MailglassAdmin.InboundLive => :inbound_list,
    MailglassAdmin.Layouts => :every_screen,
    MailglassAdmin.Operator.DeliveriesList => :activity_page,
    MailglassAdmin.Operator.DetailHeader => :full_detail,
    MailglassAdmin.Operator.FiltersForm => :activity_page,
    MailglassAdmin.Operator.HealthOverview => :operator_overview,
    MailglassAdmin.Operator.QuickView => :quick_view,
    MailglassAdmin.Operator.ReplayAction => :replay_modal,
    MailglassAdmin.Operator.ReplayModal => :replay_modal,
    MailglassAdmin.Operator.Shell => :every_screen,
    MailglassAdmin.Operator.SupportCards => :full_detail,
    MailglassAdmin.Operator.SuppressionCard => :full_detail,
    MailglassAdmin.Operator.Timeline => :full_detail_provider_time,
    MailglassAdmin.OperatorLive => :operator_overview,
    MailglassAdmin.Preview.AssignsForm => :preview_show,
    MailglassAdmin.Preview.DeviceFrame => :preview_show,
    MailglassAdmin.Preview.Sidebar => :preview_show,
    MailglassAdmin.Preview.Tabs => :preview_show,
    MailglassAdmin.PreviewLive => :preview_show,
    MailglassAdmin.SurfaceNav => :every_screen
  }

  @doc """
  `%{{live_view_module, action} => [state_kind]}`. The keys must equal the live routes of
  `MailglassAdmin.TestAdopter.Router` (see `live_route_pairs/1`).
  """
  def registry, do: @registry

  @doc "`%{module => state_kind | :gallery | :every_screen}` for every `__components__/0` module."
  def known_component_modules, do: @known_component_modules

  @doc "Every state kind `registry/0` names, sorted."
  def kinds, do: @registry |> Map.values() |> List.flatten() |> Enum.sort()

  @doc """
  The distinct `{module, action}` pairs mounted by LiveView routes in `routes`, sorted.

  Takes the list `Phoenix.Router.routes/1` returns, so a test can feed it a planted route
  list as well as the real one.
  """
  def live_route_pairs(routes) when is_list(routes) do
    routes
    |> Enum.flat_map(fn
      %{metadata: %{phoenix_live_view: {module, action, _opts, _extra}}} -> [{module, action}]
      _route -> []
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc "The live route pairs of the test adopter router, from `Phoenix.Router.routes/1`."
  def live_routes, do: live_route_pairs(Phoenix.Router.routes(MailglassAdmin.TestAdopter.Router))

  @doc """
  The screen states for the fixtures present in `fixtures`.

  Each key opts one world in, so a caller seeds one world at a time (every seed resets the
  tables):

    * `:static` (any value): the Preview index and show screens and the Gallery
    * `:grid`: the map `OperatorFixtures.seed_phase182_status_grid!/0` returns
    * `:journey`: the map `OperatorFixtures.seed_phase182_journey!/0` returns (nine
      password-reset histories with their events, so the timeline draws event badges)
    * `:replay`: the map `OperatorFixtures.seed_phase169_replay!/1` returns
    * `:timeline`: the map `OperatorFixtures.seed_phase169_timeline_101!/0` returns
    * `:inbound`: `%{record_ids: [id], tenant_id: tenant}`

  A state is `%{label:, kind:, route:, path:, mount:, hooks:, expect:}`. `mount` is `:live`
  (mount with `live/2` and read the connected render) or `:dead` (read the dead render with
  `get/2`): the Gallery repeats a few element ids across its specimens by design, which a
  LiveViewTest re-render rejects, so it is read once as a document. `hooks` are
  `{event, payload}` pairs to send with `render_hook/3` after a LiveView mounts, and
  `expect` is a selector that must be on the page, so a scan cannot pass over a screen that
  failed to reach the state it is named for.
  """
  def states(%{} = fixtures) do
    Enum.flat_map([:static, :grid, :journey, :replay, :timeline, :inbound], fn world ->
      case Map.fetch(fixtures, world) do
        {:ok, data} -> world_states(world, data)
        :error -> []
      end
    end)
  end

  defp world_states(:static, _data) do
    [
      state("Preview index", :preview_index, {PreviewLive, :index}, @preview_index_path),
      state("Preview show", :preview_show, {PreviewLive, :show}, @preview_show_path),
      %{state("Gallery", :gallery, {GalleryLive, :index}, @gallery_path) | mount: :dead}
    ]
  end

  defp world_states(:grid, %{rows: rows, count: count}) do
    pages = div(count + @activity_per_page - 1, @activity_per_page)

    pages_states =
      for page <- 1..pages//1 do
        state(
          "Activity page #{page} of #{pages}",
          :activity_page,
          {OperatorLive, :index},
          operator_path(%{"view" => "deliveries", "page" => Integer.to_string(page)})
        )
      end

    detail_states =
      for row <- representative_rows(rows), mode <- [:quick_view, :full_detail] do
        label = "#{mode_label(mode)} #{row.status}/#{row.last_event_type}/#{row.confirmed}"

        %{
          state(label, mode, {OperatorLive, :index}, delivery_path(row.id, mode))
          | expect: mode_expect(mode)
        }
      end

    [
      state(
        "Operator overview",
        :operator_overview,
        {OperatorLive, :index},
        operator_path(%{})
      )
    ] ++ pages_states ++ detail_states
  end

  defp world_states(:journey, %{ids: ids}) do
    for {case_id, id} <- Enum.sort(ids), mode <- [:quick_view, :full_detail] do
      %{
        state(
          "#{mode_label(mode)} journey #{case_id}",
          mode,
          {OperatorLive, :index},
          delivery_path(id, mode)
        )
        | expect: mode_expect(mode)
      }
    end
  end

  defp world_states(:replay, %{delivery_id: delivery_id}) do
    [
      %{
        state(
          "Replay modal",
          :replay_modal,
          {OperatorLive, :index},
          delivery_path(delivery_id, :quick_view)
        )
        | hooks: [{"open_replay", %{"origin" => "quick_view"}}],
          expect: "[data-testid='operator-replay-modal']"
      }
    ]
  end

  defp world_states(:timeline, %{delivery_id: delivery_id}) do
    [
      %{
        state(
          "Full detail with a provider time",
          :full_detail_provider_time,
          {OperatorLive, :index},
          delivery_path(delivery_id, :full_detail)
        )
        | expect: "#delivery-detail-verdict"
      }
    ]
  end

  defp world_states(:inbound, %{record_ids: record_ids}) do
    detail_states =
      for id <- record_ids, mode <- [:quick, :full] do
        query = %{"tenant_id" => @tenant_id, "inbound_id" => id}
        query = if mode == :full, do: Map.put(query, "full", "1"), else: query

        %{
          state(
            "Inbound #{mode} detail #{id}",
            :inbound_detail,
            {InboundLive, :index},
            @inbound_path <> "?" <> URI.encode_query(query)
          )
          | expect: inbound_expect(mode)
        }
      end

    [
      state(
        "Inbound list",
        :inbound_list,
        {InboundLive, :index},
        @inbound_path <> "?" <> URI.encode_query(%{"tenant_id" => @tenant_id})
      )
    ] ++ detail_states
  end

  defp state(label, kind, route, path),
    do: %{
      label: label,
      kind: kind,
      route: route,
      path: path,
      mount: :live,
      hooks: [],
      expect: nil
    }

  # One row per last event type (a confirmed :sent row) and one per status (an unconfirmed
  # row that last said :sent): every last event type and every status reaches a Quick view
  # and a Full detail without opening every cell of the grid.
  defp representative_rows(rows) do
    by_last =
      for last <- rows |> Enum.map(& &1.last_event_type) |> Enum.uniq(),
          row =
            Enum.find(rows, &(&1.status == :sent and &1.last_event_type == last and &1.confirmed)),
          do: row

    by_status =
      for status <- rows |> Enum.map(& &1.status) |> Enum.uniq(),
          row =
            Enum.find(
              rows,
              &(&1.status == status and &1.last_event_type == :sent and not &1.confirmed)
            ),
          do: row

    Enum.uniq_by(by_last ++ by_status, & &1.id)
  end

  defp inbound_expect(:quick), do: "[data-testid='inbound-quick-view']"
  defp inbound_expect(:full), do: "[data-testid='inbound-detail-header']"

  defp mode_label(:quick_view), do: "Quick view"
  defp mode_label(:full_detail), do: "Full detail"

  defp mode_expect(:quick_view), do: "[data-testid='operator-quick-view']"
  defp mode_expect(:full_detail), do: "#delivery-detail-verdict"

  defp operator_path(extra) do
    @operator_path <> "?" <> URI.encode_query(Map.put(extra, "tenant_id", @tenant_id))
  end

  defp delivery_path(id, :quick_view),
    do: operator_path(%{"view" => "deliveries", "delivery_id" => id})

  defp delivery_path(id, :full_detail),
    do: operator_path(%{"view" => "deliveries", "delivery_id" => id, "full" => "1"})

  @doc """
  The text a reader sees on a page or fragment, with whitespace collapsed.

  Removed first: scripts and styles (they carry words like "noops" and zone tokens), every
  `[role=tooltip]` node (its exact UTC value is hover text, not the visible time), and every
  `[data-raw-provider-time]` node (a provider's raw string is labelled as such and is not a
  time mailglass vouches for). Attributes are never part of the text.
  """
  def visible_text(html) when is_binary(html) do
    html
    |> Floki.parse_document!()
    |> Floki.filter_out("script")
    |> Floki.filter_out("style")
    |> Floki.filter_out("[role=tooltip]")
    |> Floki.filter_out("[data-raw-provider-time]")
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
