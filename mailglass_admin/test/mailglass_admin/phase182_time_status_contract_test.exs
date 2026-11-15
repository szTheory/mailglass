defmodule MailglassAdmin.Phase182TimeStatusContractTest do
  @moduledoc """
  BRADM-02 required-lane proof (lane `support_contract_admin`): no admin screen shows a time
  without its zone, and no delivery status is an icon or a colour alone.

  Three layers, so a screen, a component or a string added later cannot escape:

    * render scan: every state in `MailglassAdmin.TestSupport.ScreenRegistry` is mounted
      (Preview, the Gallery, the Operator overview, every Activity page over the status
      grid, a Quick view and a Full detail for every last event type and every status, the
      replay modal, the Inbound list and detail) and its HTML is checked. Every `<time>` has
      `datetime` and visible text that ends in a zone token. Every other timestamp-shaped
      string has a zone token within 12 characters. Every `[data-mg-status]` holds exactly
      one `svg[aria-hidden=true]` and a class word. Every `.badge` has text, and a badge that
      reads a class word without the mark fails unless it is an inbound outcome.
    * registry and source: the LiveView routes of the test adopter router must equal the
      registry, a module that exports `__live__/0` or `__components__/0` must be registered
      or listed, and `strftime`, `to_iso8601`, `DateTime.to_string`, a hand-written badge
      and raw HTML may appear in `lib/mailglass_admin` only where a named allow-list says
      why.
    * static JS: the `FMT` the browser localizer uses keeps `timeZoneName` and `en-US`.

  Every detector is a pure function proven on planted violations and clean controls, so a
  scan cannot go vacuous (the "detectors have teeth" blocks), and each scan asserts a floor
  on what it saw. The browser run of the localizer under `America/New_York` and
  `Pacific/Auckland` is advisory and lives in the 182-06 catalog journey spec; this file is
  the required proof, and it never cites that spec.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias Mailglass.Operator.Deliveries
  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.{Components, Copy, GalleryLive, OperatorLive, PreviewLive}
  alias MailglassAdmin.Controllers.Assets
  alias MailglassAdmin.Operator.{DeliveriesList, DetailHeader, QuickView}
  alias MailglassAdmin.TestSupport.{InboundFixtures, OperatorFixtures, ScreenRegistry}
  alias MailglassInbound.InboundRecords.ExecutionRun

  @tenant_id "browser-tenant"
  @at ~U[2026-11-15 14:05:09.123456Z]

  @lib_dir Path.expand("../../lib", __DIR__)
  @scope_dir Path.join(@lib_dir, "mailglass_admin")

  # The words a `[data-mg-status]` may show: the five class words and Queued, which is the
  # Sent class with a qualifier word (179 D-03).
  @class_words Enum.map(Copy.class_labels(), & &1.label) ++ [Copy.status_label(:queued)]
  @class_word_by_class Map.new(Copy.class_labels(), &{Atom.to_string(&1.class), [&1.label]})
                       |> Map.update!("sent", &(&1 ++ [Copy.status_label(:queued)]))

  # A zone token ends a visible time: UTC, GMT with an optional hour offset, a numeric
  # offset, or a 2-5 letter abbreviation (EST, CEST). AM and PM are not zones.
  @zone_end ~r/(?:\bUTC|\bGMT(?:[+-]\d{1,2})?|[+-]\d{4}|\b(?!(?:AM|PM)\b)[A-Z]{2,5})\s*\z/
  # Beside other text a zone is at least three letters (UTC, EST, CEST), so a two-letter
  # word such as ID is not mistaken for one.
  @zone_token ~r/\bUTC\b|\bGMT(?:[+-]\d{1,2})?\b|[+-]\d{4}\b|\b[A-Z]{3,5}\b/
  @zone_window 12
  @timestamp_shapes [
    ~r/\d{4}-\d{2}-\d{2}/,
    ~r/\b\d{1,2}:\d{2}\b/,
    ~r/\b[A-Z][a-z]{2} \d{1,2}, \d{4}\b/
  ]

  # -- source scan tables --------------------------------------------------------

  @time_fn ~r/\bstrftime\b|\bto_iso8601\b|DateTime\.to_string/
  @badge_re ~r/class="[^"]*\bbadge\b|"badge\s/
  @raw_re ~r/Phoenix\.HTML\.raw\b|(?<![\w.])raw\(/
  # A <time> element opens at the start of a line or straight after another tag, and `<time`
  # is followed by a space, `>` or a line end. Prose that names the element ("patches a
  # <time>" in a comment) has a word before it and is not one; @doc and @moduledoc text is
  # blanked first (see `blank_docs/1`).
  @time_element ~r/(?:^\s*|>)<time(?:\s|>|$)/m

  # Modules that own the formatting and the badge: the scan does not apply to them.
  @owners ["components.ex", "copy.ex"]

  # Each entry names a file and why it may hold the pattern. The "named allow-lists are
  # load-bearing" test fails if an entry no longer matches anything, so a stale entry
  # cannot stay behind and quietly widen the rule.
  @time_allowed %{
    "preview_live.ex" =>
      "the sample email Date header: an RFC 2822 header with its +0000 zone, a fixture " <>
        "header shown in the Preview, never an admin time"
  }

  @badge_allowed %{
    "operator/suppression_card.ex" =>
      "the current-match chip: names a suppression scope and carries no class word",
    "operator/support_cards.ex" =>
      "the Read-only chip: an access mode, not a status, and carries no class word",
    "inbound/timeline.ex" =>
      "the source chip (Initial processing, Replay): provenance, not a delivery status",
    "inbound/routing_trace.ex" =>
      "the provider and source chip: provenance, not a delivery status"
  }

  @raw_allowed %{
    "layouts/root.html.heex" =>
      "the inline localizer script: a compile-time constant, never user data"
  }

  # The one file outside `lib/mailglass_admin` that formats a time. It stamps the date a
  # vendored stylesheet was fetched; no screen renders it. Asserting it is the only hit
  # means widening the scan later is a deliberate edit.
  @outside_scope_time_fn "mix/tasks/mailglass_admin.daisyui.update.ex"

  # -- registry ------------------------------------------------------------------

  describe "screen registry (D-18)" do
    test "the live routes of the test adopter router are exactly the registry" do
      routes = Phoenix.Router.routes(MailglassAdmin.TestAdopter.Router)
      pairs = ScreenRegistry.live_route_pairs(routes)

      assert length(pairs) >= 5, "the router yielded #{length(pairs)} live pairs; vacuous"

      violations = route_violations(pairs, Map.keys(ScreenRegistry.registry()))
      assert_none(violations)
    end

    test "every loaded admin module that exports __live__/0 or __components__/0 is registered" do
      entries = loaded_module_entries()

      # Non-vacuity: today four LiveViews and a few dozen component modules exist.
      assert Enum.count(entries, & &1.live?) >= 4
      assert Enum.count(entries, & &1.components?) >= 25

      violations =
        module_violations(
          entries,
          ScreenRegistry.registry() |> Map.keys() |> Enum.map(&elem(&1, 0)),
          ScreenRegistry.known_component_modules()
        )

      assert_none(violations)
    end

    test "every state kind a component names exists, and every registry kind has a state" do
      kinds = MapSet.new(ScreenRegistry.kinds())

      for {module, kind} <- ScreenRegistry.known_component_modules() do
        assert kind in [:every_screen, :gallery] or MapSet.member?(kinds, kind),
               "#{inspect(module)} names #{inspect(kind)}, which is not a registered state kind"
      end

      produced = ScreenRegistry.states(all_worlds_with_fake_ids()) |> Enum.map(& &1.kind)

      assert Enum.sort(Enum.uniq(produced)) == ScreenRegistry.kinds(),
             "a registered kind has no state builder, or a builder makes an unregistered kind"

      assert length(produced) >= 10, "fewer than 10 registered screen states: #{length(produced)}"
    end
  end

  # -- render scan ---------------------------------------------------------------

  describe "render scan over every registered state (D-18)" do
    test "Preview and the Gallery show every time with a zone and every status with a word",
         %{conn: conn} do
      states = ScreenRegistry.states(%{static: true})
      results = scan_states(conn, states)

      assert_clean(results)
      # The Gallery is the specimen sheet for the components: it must show real timestamps
      # and real status badges, or the scan above passed over an empty page.
      gallery = Enum.find(results, &(&1.state.kind == :gallery))
      assert gallery.times >= 3, "the Gallery rendered #{gallery.times} <time> elements"
      assert gallery.marks >= 5, "the Gallery rendered #{gallery.marks} status marks"
      report(:static, results)
    end

    test "the Operator over the 170-cell status grid, every Activity page, Quick view and Full detail",
         %{conn: conn} do
      grid = OperatorFixtures.seed_phase182_status_grid!()
      universe = grid_universe()

      # The persisted grid is every cell the schema can store; the cells with no last event
      # type are not storable (`last_event_type` is NOT NULL) and are rendered in memory
      # below. Together they are the full status x last event x confirmed universe.
      statuses = length(Ecto.Enum.values(Delivery, :status))
      events = length(Delivery.__event_types__())

      assert grid.count == statuses * events * 2
      assert grid.count + statuses * 2 == universe
      assert universe == statuses * (events + 1) * 2
      assert length(grid.rows) == grid.count

      results = scan_states(conn, ScreenRegistry.states(%{grid: grid}))
      assert_clean(results)

      kinds = results |> Enum.map(& &1.state.kind) |> Enum.frequencies()
      assert kinds.operator_overview == 1
      assert kinds.activity_page == div(grid.count + 19, 20)
      assert kinds.quick_view >= events and kinds.full_detail >= events

      pages = Enum.filter(results, &(&1.state.kind == :activity_page))

      assert Enum.sum(Enum.map(pages, & &1.marks)) >= grid.count,
             "the Activity pages showed fewer status marks than the #{grid.count} persisted rows"

      # The in-memory cells complete the 170.
      nil_results = scan_nil_cells()
      # One list of every nil-cell row, then a Quick view and a detail header per row.
      assert length(nil_results) == 1 + statuses * 2 * 2
      assert_clean(nil_results)

      marks = Enum.sum(Enum.map(results ++ nil_results, & &1.marks))
      times = Enum.sum(Enum.map(results ++ nil_results, & &1.times))

      assert marks >= universe,
             "#{marks} [data-mg-status] across the grid, floor is the #{universe} cells"

      assert times >= 100, "#{times} <time> elements across the grid, floor is 100"
      report(:grid, results ++ nil_results)
    end

    test "no operator read model sends a false lifecycle flag (C-4)" do
      OperatorFixtures.seed_phase182_status_grid!()

      page =
        Deliveries.list_recent_deliveries_page(
          %{tenant_id: @tenant_id, window_hours: 168, page: 1},
          per_page: 20
        )

      assert length(page.entries) == 20
      assert page.outcome_groups != []
      assert_none(false_flags(page.entries ++ page.outcome_groups))
    end

    test "the journey histories, with their events, show every time and status with its mark",
         %{conn: conn} do
      journey = OperatorFixtures.seed_phase182_journey!()
      results = scan_states(conn, ScreenRegistry.states(%{journey: journey}))

      assert_clean(results)
      assert length(results) == 2 * map_size(journey.ids)

      # Every detail leads with its verdict mark, and the histories carry events, so each
      # timeline shows at least its own recorded times beside the verdict.
      details = Enum.filter(results, &(&1.state.kind == :full_detail))
      assert Enum.all?(details, &(&1.marks >= 1))
      assert Enum.all?(details, &(&1.times >= 1))

      report(:journey, results)
    end

    test "the replay modal state shows its times with a zone", %{conn: conn} do
      replay = OperatorFixtures.seed_phase169_replay!("one")
      results = scan_states(conn, ScreenRegistry.states(%{replay: replay}))

      assert [%{state: %{kind: :replay_modal}}] = results
      assert_clean(results)
      report(:replay, results)
    end

    test "a provider time is a zoned timestamp, and a Full detail shows it", %{conn: conn} do
      timeline = OperatorFixtures.seed_phase169_timeline_101!()
      results = scan_states(conn, ScreenRegistry.states(%{timeline: timeline}))

      assert_clean(results)
      [%{times: times}] = results
      assert times >= 3, "the 101-event timeline rendered #{times} <time> elements"
      report(:timeline, results)
    end

    test "the Inbound list and every record's detail", %{conn: conn} do
      OperatorFixtures.reset!()

      record_ids =
        for outcome <- ExecutionRun.__outcomes__() do
          seed_inbound!(outcome)
        end

      results =
        scan_states(
          conn,
          ScreenRegistry.states(%{inbound: %{record_ids: record_ids, tenant_id: @tenant_id}})
        )

      assert_clean(results)
      assert length(results) == 1 + 2 * length(ExecutionRun.__outcomes__())

      # Every record shows its received time and an outcome badge on the list and in detail.
      assert Enum.sum(Enum.map(results, & &1.times)) >= length(record_ids)
      assert Enum.sum(Enum.map(results, & &1.badges)) >= length(record_ids)

      # The inbound Failed outcome reads a class word and keeps its icon: the exemption the
      # mark rule makes for it must have been exercised, or the rule is untested here.
      assert Enum.sum(Enum.map(results, & &1.exempt)) >= 1,
             "no inbound outcome badge reading a class word was scanned"

      report(:inbound, results)
    end

    test "an unavailable time is the word Unavailable and no <time> element" do
      html = render_component(&Components.timestamp/1, at: nil)
      scan = scan_html("timestamp at nil", html)

      assert String.trim(ScreenRegistry.visible_text(html)) == "Unavailable"
      assert scan.times == 0
      assert scan.violations == []
      refute html =~ "<time"
    end
  end

  # -- source scan and static JS ---------------------------------------------------

  describe "source scan (D-18)" do
    test "time formatting, hand-written badges and raw HTML stay in their owners" do
      sources = lib_sources()

      assert length(sources) > 30, "the lib glob found #{length(sources)} files; vacuous"

      assert List.keymember?(sources, "components.ex", 0),
             "components.ex is missing from the scan"

      assert List.keymember?(sources, "layouts/root.html.heex", 0)

      violations =
        Enum.flat_map(sources, fn {rel, source} ->
          scan_source(rel, source) ++ scan_time_tags(rel, source)
        end)

      assert_none(violations)
    end

    test "Components.timestamp/1 is the only <time> emitter" do
      sources = Map.new(lib_sources())
      components = Map.fetch!(sources, "components.ex")

      # Non-vacuity: timestamp/1 has its two branches, copyable and plain.
      assert length(Regex.scan(@time_element, blank_docs(components))) == 2
      assert {_first, _last} = timestamp_range(blank_docs(components))

      others =
        for {rel, source} <- sources,
            rel != "components.ex",
            Regex.match?(@time_element, blank_docs(source)),
            do: rel

      assert others == [], "a <time> element outside Components.timestamp/1 in #{inspect(others)}"
    end

    test "every named allow-list entry still matches something" do
      sources = Map.new(lib_sources())

      for {allowed, pattern, label} <- [
            {@time_allowed, @time_fn, "time"},
            {@badge_allowed, @badge_re, "badge"},
            {@raw_allowed, @raw_re, "raw"}
          ],
          {rel, reason} <- allowed do
        source = Map.get(sources, rel)
        assert source, "#{label} allow-list names #{rel}, which does not exist"
        assert is_binary(reason) and reason != "", "#{rel} needs a reason"

        assert Enum.any?(String.split(source, "\n"), &Regex.match?(pattern, &1)),
               "#{label} allow-list entry #{rel} no longer matches anything; remove it"
      end
    end

    test "the Mix task is the only time formatter outside the scanned tree" do
      hits =
        @lib_dir
        |> Path.join("**/*.{ex,heex}")
        |> Path.wildcard()
        |> Enum.reject(&String.starts_with?(&1, @scope_dir <> "/"))
        |> Enum.filter(&Regex.match?(@time_fn, File.read!(&1)))
        |> Enum.map(&Path.relative_to(&1, @lib_dir))

      assert hits == [@outside_scope_time_fn],
             "time formatting outside lib/mailglass_admin is #{inspect(hits)}; widen the scan " <>
               "to cover it or move it into the scanned tree"
    end
  end

  describe "static JS (D-18)" do
    test "the localizer keeps a zone token and a fixed locale" do
      js = Assets.js_body()

      assert_none(js_violations(js))
      # Non-vacuity: the block under test is really the one that serves the localizer.
      assert js =~ "timeZoneName"
      assert js =~ ~s|toLocaleString("en-US"|
    end
  end

  # -- teeth ---------------------------------------------------------------------

  describe "detectors have teeth (fail-first proof)" do
    test "a time without a zone, or with the wrong ending, is flagged" do
      planted = [
        {~s|<time datetime="2026-11-15T14:05:00Z">14:05</time>|, :time_without_zone},
        {~s|<time datetime="2026-11-15T14:05:00Z">Nov 15, 2026, 2:05 PM</time>|,
         :time_without_zone},
        {~s|<time datetime="2026-11-15T14:05:00Z">Nov 15, 2026, 2:05 pm</time>|,
         :time_without_zone},
        {~s|<time datetime="2026-11-15T14:05:00Z">Nov 15, 2026, 2:05 PM utc</time>|,
         :time_without_zone},
        {~s|<time>Nov 15, 2026, 2:05 PM UTC</time>|, :time_without_datetime}
      ]

      for {html, rule} <- planted do
        assert rule in rules(scan_html("planted", html).violations),
               "planted violation not flagged as #{rule}: #{html}"
      end
    end

    test "a title on a timestamp, an aria-label on a time, or a copy name that omits the time is flagged" do
      titled =
        ~s|<time datetime="2026-11-15T14:05:00Z" title="exact">Nov 15, 2026, 2:05 PM UTC</time>|

      labelled =
        ~s|<time datetime="2026-11-15T14:05:00Z" aria-label="Recorded at x">Nov 15, 2026, 2:05 PM UTC</time>|

      button = fn attrs ->
        ~s|<button data-timestamp-copy="true" #{attrs}><time datetime="2026-11-15T14:05:00Z">Nov 15, 2026, 2:05 PM UTC</time></button>|
      end

      copy_titled =
        ~s|<button data-copy-value="x" title="Click to copy" aria-label="Copy ID: x">x</button>|

      for {html, rule} <- [
            {titled, :time_labelled},
            {labelled, :time_labelled},
            {button.(~s|aria-label="Copy timestamp as UTC: 2026-11-15 14:05:00 UTC"|),
             :copy_label_omits_time},
            {button.(
               ~s|aria-label="Copy Nov 15, 2026, 2:05 PM UTC (copies the exact UTC value)" title="x"|
             ), :time_titled},
            {copy_titled, :time_titled}
          ] do
        assert rule in rules(scan_html("planted", html).violations),
               "planted violation not flagged as #{rule}: #{html}"
      end

      clean =
        button.(~s|aria-label="Copy Nov 15, 2026, 2:05 PM UTC (copies the exact UTC value)"|)

      assert scan_html("control", clean).violations == []
    end

    test "zone tokens in every spelling are accepted" do
      for zone <- ["UTC", "EST", "EDT", "CEST", "GMT+13", "GMT-8", "GMT", "+0530", "-0800"] do
        html = ~s|<time datetime="2026-11-15T14:05:00Z">Nov 15, 2026, 2:05 PM #{zone}</time>|

        assert scan_html("control", html).violations == [],
               "clean control was flagged with zone #{zone}"
      end
    end

    test "a timestamp-shaped string outside a time needs a zone within #{@zone_window} characters" do
      for planted <- [
            "<p>Last checked 2026-11-15 14:05</p>",
            "<p>Sent at 2:05 PM</p>",
            "<p>Received Nov 15, 2026</p>"
          ] do
        assert :bare_timestamp in rules(scan_html("planted", planted).violations),
               "planted bare time not flagged: #{planted}"
      end

      for clean <- [
            "<p>Last checked 2026-11-15 14:05 UTC</p>",
            "<p>Sent at 2:05 PM EST</p>",
            "<p>Sent Nov 15, 2026, 2:05 PM UTC</p>",
            "<p>Date: Sat, 15 Nov 2026 14:05:00 +0000</p>"
          ] do
        assert scan_html("control", clean).violations == [], "clean control flagged: #{clean}"
      end
    end

    test "a provider's raw time and an exact tooltip value are not visible times" do
      html =
        ~s|<p><span data-raw-provider-time>Provider time, as reported: 2026-11-15 14:05:00</span></p>| <>
          ~s|<span role="tooltip">2026-11-15 14:05:00.000000 UTC • Click to copy</span>|

      assert scan_html("control", html).violations == []
    end

    test "an icon-only badge is flagged" do
      planted = ~s|<span class="badge"><svg aria-hidden="true" width="17"></svg></span>|
      assert :badge_empty in rules(scan_html("planted", planted).violations)
    end

    test "a status with two marks, a labelled mark, or a word outside the class words is flagged" do
      two_marks =
        ~s|<span class="badge" data-mg-status="sent"><svg aria-hidden="true"></svg><svg aria-hidden="true"></svg>Sent</span>|

      labelled =
        ~s|<span class="badge" data-mg-status="sent"><svg aria-hidden="true" aria-label="Sent"></svg>Sent</span>|

      titled =
        ~s|<span class="badge" title="Sent" data-mg-status="sent"><svg aria-hidden="true"></svg>Sent</span>|

      shown =
        ~s|<span class="badge" data-mg-status="sent"><svg></svg>Sent</span>|

      foreign =
        ~s|<span class="badge" data-mg-status="sent"><svg aria-hidden="true"></svg>Dispatched</span>|

      mismatched =
        ~s|<span class="badge" data-mg-status="failed"><svg aria-hidden="true"></svg>Delivered</span>|

      unknown_class =
        ~s|<span class="badge" data-mg-status="bounced"><svg aria-hidden="true"></svg>Failed</span>|

      for {html, rule} <- [
            {two_marks, :status_mark_count},
            {labelled, :status_mark_labelled},
            {titled, :status_mark_labelled},
            {shown, :status_mark_count},
            {foreign, :status_word_unknown},
            {mismatched, :status_word_class_mismatch},
            {unknown_class, :status_class_unknown}
          ] do
        assert rule in rules(scan_html("planted", html).violations),
               "planted violation not flagged as #{rule}: #{html}"
      end
    end

    test "a class word on a badge with a Heroicon and no mark is flagged, except an inbound outcome" do
      icon = ~s|<span class="hero-check-circle w-3 h-3" aria-hidden="true"></span>|
      delivered = ~s|<span class="badge badge-success">#{icon}Delivered</span>|

      assert :badge_class_word_without_mark in rules(scan_html("planted", delivered).violations)

      for word <- ["Sent", "Delayed", "Failed", "Not sent", "Queued"] do
        planted = ~s|<span class="badge">#{icon}#{word}</span>|

        assert :badge_class_word_without_mark in rules(scan_html("planted", planted).violations),
               "a #{word} badge with no mark was not flagged"
      end

      inbound = ~s|<span data-mg-context="inbound" class="badge badge-error">#{icon}Failed</span>|
      bare = ~s|<span class="badge badge-error">#{icon}Failed</span>|

      assert scan_html("inbound control", inbound).violations == []
      assert :badge_class_word_without_mark in rules(scan_html("same badge", bare).violations)
    end

    test "a real status badge and a real timestamp are clean" do
      for status <- [:sent, :queued, :delivered, :failed] do
        html = render_component(&Components.status_badge/1, status: status, context: :delivery)
        scan = scan_html("status #{status}", html)
        assert_none(scan.violations)
        assert scan.marks == 1
      end

      for {class, word} <- [delayed: "Delayed", not_sent: "Not sent"] do
        html =
          render_component(&Components.status_badge/1,
            status: :deferred,
            delivery_class: class,
            word: word,
            context: :delivery
          )

        scan = scan_html("class #{class}", html)
        assert_none(scan.violations)
        assert scan.marks == 1
      end

      for copyable <- [true, false] do
        html = render_component(&Components.timestamp/1, at: @at, copyable: copyable)
        scan = scan_html("timestamp", html)
        assert_none(scan.violations)
        assert scan.times == 1
      end
    end

    test "a hand-written badge, a time formatter or raw HTML outside its owner is flagged" do
      planted = [
        {"operator_live.ex", ~s|<span class="badge">Failed</span>|, :hand_written_badge},
        {"operator_live.ex", ~s|class={["badge badge-outline", @x]}|, :hand_written_badge},
        {"operator/new_card.ex", ~s|Calendar.strftime(at, "%H:%M")|, :time_format_outside_owner},
        {"operator/new_card.ex", ~s|DateTime.to_iso8601(at) <> " UTC"|,
         :time_format_outside_owner},
        {"operator/new_card.ex", ~s|"\#{DateTime.to_string(at)}"|, :time_format_outside_owner},
        {"operator/new_card.ex", ~s|Phoenix.HTML.raw(html)|, :raw_html}
      ]

      for {rel, source, rule} <- planted do
        assert [%{rule: ^rule, path: ^rel, line: 1}] = scan_source(rel, source),
               "planted #{rule} in #{rel} was not flagged: #{source}"
      end
    end

    test "owners, named allowances and comments are not flagged" do
      for {rel, source} <- [
            {"components.ex", ~s|Calendar.strftime(at, "%b %-d")|},
            {"components.ex", ~s|<span class="badge">x</span>|},
            {"copy.ex", ~s|DateTime.to_iso8601(at)|},
            {"preview_live.ex", ~s|Calendar.strftime(now, "%a, %d %b %Y %H:%M:%S +0000")|},
            {"operator/support_cards.ex", ~s|<span class="badge badge-outline">Read-only</span>|},
            {"layouts/root.html.heex", ~s|<%= Phoenix.HTML.raw(js_inline()) %>|},
            {"operator_live.ex", ~s|# Calendar.strftime is formatted in Components|}
          ] do
        assert scan_source(rel, source) == [], "clean control flagged in #{rel}: #{source}"
      end

      # A named allowance is for one rule only: preview_live.ex may format a Date header,
      # not hold a hand-written badge.
      assert [%{rule: :hand_written_badge}] =
               scan_source("preview_live.ex", ~s|<span class="badge">x</span>|)
    end

    test "a <time> element outside Components.timestamp/1 is flagged, even inside components.ex" do
      timestamp = """
        def timestamp(assigns) do
          ~H\"\"\"
          <time datetime={@at}>x</time>
          \"\"\"
        end

        def other(assigns) do
          ~H\"\"\"
          <time>bare</time>
          \"\"\"
        end
      """

      assert [%{rule: :time_element_outside_timestamp, line: 9}] =
               scan_time_tags("components.ex", timestamp)

      assert [%{rule: :time_element_outside_timestamp, line: 1}] =
               scan_time_tags("operator_live.ex", "<time datetime={@at}>x</time>")

      assert scan_time_tags("operator_live.ex", "<p>sometimes</p>") == []
    end

    test "a false lifecycle flag in a read model is flagged, a nil or a boolean terminal is not" do
      assert [%{rule: :false_lifecycle_flag}] = false_flags([%{bounced_at: false}])
      assert false_flags([%{bounced_at: nil, terminal: false, suppressed_at: true}]) == []
    end

    test "a false lifecycle flag reads as a recorded fact, so a producer must send true or nil" do
      # C-4 at the screen level: the verdict reads any non-nil value as present, so a row
      # that carries `bounced_at: false` is Failed. The core projection test owns the
      # producer; this documents what a false flag would do to a screen.
      row =
        Map.merge(hd(nil_cell_rows()), %{
          status: :sent,
          last_event_type: :sent,
          delivery_confirmed: false,
          delivered_at: nil,
          bounced_at: false
        })

      assert MailglassAdmin.StatusMap.delivery_class(row) == :failed
      html = render_component(&Components.delivery_badge/1, row: row)
      assert scan_html("false flag", html).violations == []
      assert ScreenRegistry.visible_text(html) == "Failed"

      assert MailglassAdmin.StatusMap.delivery_class(%{row | bounced_at: nil}) == :sent
    end

    test "a FMT without a zone name, or a localizer with no fixed locale, is flagged" do
      good =
        ~s|const FMT = { hour: "numeric", timeZoneName: "short" }; d.toLocaleString("en-US", FMT)|

      no_zone = ~s|const FMT = { hour: "numeric" }; d.toLocaleString("en-US", FMT)|

      no_locale =
        ~s|const FMT = { hour: "numeric", timeZoneName: "short" }; d.toLocaleString(undefined, FMT)|

      no_fmt = ~s|d.toLocaleString("en-US", {timeZoneName: "short"})|

      assert js_violations(good) == []
      assert :fmt_without_zone_name in rules(js_violations(no_zone))
      assert :localizer_locale in rules(js_violations(no_locale))
      assert :fmt_missing in rules(js_violations(no_fmt))
    end

    test "a route missing from the registry, or a stale registry entry, is flagged" do
      registry = [{PlantedLive, :index}, {MailglassAdmin.OperatorLive, :index}]

      extra_route = [
        {MailglassAdmin.OperatorLive, :index},
        {NewLive, :index},
        {PlantedLive, :index}
      ]

      assert [%{rule: :route_unregistered}] = route_violations(extra_route, registry)

      fewer_routes = [{MailglassAdmin.OperatorLive, :index}]
      assert [%{rule: :route_stale}] = route_violations(fewer_routes, registry)

      assert route_violations(Enum.sort(registry), registry) == []
    end

    test "live_route_pairs reads the LiveView routes of a planted route list" do
      routes = [
        %{metadata: %{phoenix_live_view: {OperatorLive, :index, [], %{}}}},
        %{metadata: %{phoenix_live_view: {OperatorLive, :index, [], %{}}}},
        %{metadata: %{}},
        %{metadata: %{phoenix_live_view: {GalleryLive, :show, [], %{}}}}
      ]

      assert ScreenRegistry.live_route_pairs(routes) ==
               Enum.sort([{OperatorLive, :index}, {GalleryLive, :show}])
    end

    test "an unregistered LiveView module, or an unlisted component module, is flagged" do
      entries = [
        %{module: MailglassAdmin.OperatorLive, live?: true, components?: true},
        %{module: Planted.Live, live?: true, components?: false},
        %{module: Planted.Card, live?: false, components?: true},
        %{module: Planted.Plain, live?: false, components?: false}
      ]

      violations =
        module_violations(entries, [MailglassAdmin.OperatorLive], %{
          MailglassAdmin.OperatorLive => :operator_overview
        })

      assert Enum.sort(rules(violations)) == [
               :component_module_unregistered,
               :live_module_unregistered
             ]

      # A listed module that no longer exists is stale.
      stale =
        module_violations(
          [%{module: MailglassAdmin.OperatorLive, live?: true, components?: true}],
          [MailglassAdmin.OperatorLive],
          %{MailglassAdmin.OperatorLive => :operator_overview, Gone.Module => :gallery}
        )

      assert rules(stale) == [:component_module_stale]
    end

    test "visible_text drops scripts, tooltips and raw provider times and keeps the rest" do
      html =
        ~s|<p>Shown 2:05 PM UTC</p><script>var t = "14:05"</script>| <>
          ~s|<span role="tooltip">2026-11-15 14:05:00 UTC</span>| <>
          ~s|<span data-raw-provider-time>raw 14:05</span><style>.a{}</style>|

      assert ScreenRegistry.visible_text(html) == "Shown 2:05 PM UTC"
    end
  end

  # -- detectors (pure) ------------------------------------------------------------

  # One scan of an HTML string. Returns the violations and the counts a floor reads.
  defp scan_html(label, html) do
    doc = Floki.parse_document!(html)
    times = Floki.find(doc, "time")
    badges = Floki.find(doc, ".badge")
    marked = Floki.find(doc, "[data-mg-status]")

    violations =
      Enum.flat_map(times, &time_violations(label, &1)) ++
        Enum.flat_map(
          Floki.find(doc, "button[data-timestamp-copy]"),
          &copy_time_violations(label, &1)
        ) ++
        Enum.flat_map(Floki.find(doc, "[data-copy-value]"), &copy_title_violations(label, &1)) ++
        shape_violations(label, ScreenRegistry.visible_text(html)) ++
        Enum.flat_map(badges, &badge_violations(label, &1)) ++
        Enum.flat_map(marked, &mark_violations(label, &1))

    # Inbound outcome badges that read a class word (an inbound Failed) are exempt from the
    # mark rule; the count lets a scan prove the exemption was exercised.
    exempt =
      Enum.count(badges, fn badge ->
        Floki.attribute(badge, "data-mg-context") == ["inbound"] and
          node_text(badge) in @class_words
      end)

    %{
      violations: violations,
      times: length(times),
      badges: length(badges),
      marks: length(marked),
      exempt: exempt
    }
  end

  defp time_violations(label, time) do
    text = node_text(time)

    List.flatten([
      if(Floki.attribute(time, "title") ++ Floki.attribute(time, "aria-label") == [],
        do: [],
        else: [violation(:time_labelled, label, text)]
      ),
      if(blank?(Floki.attribute(time, "datetime")),
        do: [violation(:time_without_datetime, label, text)],
        else: []
      ),
      if(Regex.match?(@zone_end, text),
        do: [],
        else: [violation(:time_without_zone, label, text)]
      )
    ])
  end

  # D-09 and WCAG 2.5.3 Label in Name: a <time> carries no title and no aria-label of its
  # own (its visible text is its name), and the control that copies it names itself with
  # text that contains the visible time.
  defp copy_time_violations(label, button) do
    [time | _] = Floki.find(button, "time")
    visible = node_text(time)
    name = button |> Floki.attribute("aria-label") |> List.first("")

    List.flatten([
      if(String.contains?(name, visible),
        do: [],
        else: [
          violation(:copy_label_omits_time, label, "#{inspect(name)} omits #{inspect(visible)}")
        ]
      ),
      if(Floki.attribute(button, "title") == [],
        do: [],
        else: [violation(:time_titled, label, visible)]
      )
    ])
  end

  defp copy_title_violations(label, node) do
    if Floki.attribute(node, "title") == [],
      do: [],
      else: [violation(:time_titled, label, node_text(node))]
  end

  # A timestamp-shaped string outside a <time> (the <time> text is checked above) needs a
  # zone token starting within @zone_window characters after it.
  defp shape_violations(label, text) do
    for shape <- @timestamp_shapes,
        [{start, len}] <- Regex.scan(shape, text, return: :index),
        rest = binary_part(text, start + len, byte_size(text) - start - len),
        not zone_within?(rest) do
      shown = binary_part(text, start, len) <> " ... " <> String.slice(rest, 0, 30)
      violation(:bare_timestamp, label, shown)
    end
  end

  defp zone_within?(rest) do
    case Regex.run(@zone_token, rest, return: :index) do
      [{offset, _length}] -> offset <= @zone_window
      nil -> false
    end
  end

  defp badge_violations(label, badge) do
    text = node_text(badge)
    marked? = Floki.attribute(badge, "data-mg-status") != []
    inbound? = Floki.attribute(badge, "data-mg-context") == ["inbound"]

    cond do
      text == "" ->
        [violation(:badge_empty, label, badge_summary(badge))]

      text in @class_words and not marked? and not inbound? ->
        [violation(:badge_class_word_without_mark, label, text)]

      true ->
        []
    end
  end

  defp mark_violations(label, status) do
    word = node_text(status)
    [class] = Floki.attribute(status, "data-mg-status")
    svgs = Floki.find(status, "svg")
    hidden = Floki.find(status, "svg[aria-hidden=true]")

    labelled? =
      Floki.attribute(status, "aria-label") != [] or Floki.attribute(status, "title") != [] or
        Floki.find(status, "[aria-label],[title]") != []

    List.flatten([
      if(length(svgs) != 1 or length(hidden) != 1,
        do: [
          violation(
            :status_mark_count,
            label,
            "#{length(svgs)} svg, #{length(hidden)} hidden: #{word}"
          )
        ],
        else: []
      ),
      if(labelled?, do: [violation(:status_mark_labelled, label, word)], else: []),
      cond do
        word not in @class_words ->
          [violation(:status_word_unknown, label, word)]

        not Map.has_key?(@class_word_by_class, class) ->
          [violation(:status_class_unknown, label, class)]

        word not in Map.fetch!(@class_word_by_class, class) ->
          [violation(:status_word_class_mismatch, label, "#{class}: #{word}")]

        true ->
          []
      end
    ])
  end

  defp scan_source(rel, source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.reject(fn {line, _n} -> Regex.match?(~r/^\s*#/, line) end)
    |> Enum.flat_map(fn {line, n} ->
      for {pattern, rule, allowed} <- [
            {@time_fn, :time_format_outside_owner, Map.keys(@time_allowed)},
            {@badge_re, :hand_written_badge, Map.keys(@badge_allowed)},
            {@raw_re, :raw_html, Map.keys(@raw_allowed)}
          ],
          Regex.match?(pattern, line),
          rel not in @owners and rel not in allowed do
        %{rule: rule, path: rel, line: n, text: String.trim(line)}
      end
    end)
  end

  # Components.timestamp/1 is the only place a <time> element is written. Outside
  # components.ex any `<time` is a violation; inside it, only within the body of
  # `def timestamp(assigns)`.
  defp scan_time_tags(rel, source) do
    source = blank_docs(source)
    allowed = if rel == "components.ex", do: timestamp_range(source)

    for {line, n} <- source |> String.split("\n") |> Enum.with_index(1),
        Regex.match?(@time_element, line),
        not Regex.match?(~r/^\s*#/, line),
        not (is_tuple(allowed) and n in elem(allowed, 0)..elem(allowed, 1)//1) do
      %{rule: :time_element_outside_timestamp, path: rel, line: n, text: String.trim(line)}
    end
  end

  # The first and last line of `def timestamp(assigns) do ... end` (the copyable and plain
  # branches), or nil when the source has no such function.
  defp timestamp_range(source) do
    lines = source |> String.split("\n") |> Enum.with_index(1)

    with {_, first} <-
           Enum.find(lines, fn {line, _} -> line =~ ~r/^\s*def timestamp\(assigns\) do$/ end),
         {_, last} <-
           Enum.find(lines, fn {line, n} ->
             n > first and line =~ ~r/^\s*end$/ and indent(line) == indent_at(lines, first)
           end) do
      {first, last}
    else
      _ -> nil
    end
  end

  # Replaces the text of every @doc and @moduledoc heredoc with blank lines, so a sentence
  # that names an element is not mistaken for one and line numbers stay the same.
  defp blank_docs(source) do
    Regex.replace(~r/@(?:module)?doc\s+"""(.*?)"""/s, source, fn whole, _body ->
      String.replace(whole, ~r/[^\n]/, "")
    end)
  end

  defp indent_at(lines, n), do: lines |> Enum.at(n - 1) |> elem(0) |> indent()
  defp indent(line), do: byte_size(line) - byte_size(String.trim_leading(line))

  defp js_violations(js) do
    fmt =
      case Regex.run(~r/const FMT = \{(.*?)\}/s, js, capture: :all_but_first) do
        [body] -> body
        _ -> nil
      end

    List.flatten([
      if(is_nil(fmt),
        do: [violation(:fmt_missing, "Assets.js_body/0", "no `const FMT = {...}`")],
        else: []
      ),
      if(fmt && not String.contains?(fmt, "timeZoneName"),
        do: [violation(:fmt_without_zone_name, "Assets.js_body/0", fmt)],
        else: []
      ),
      if(String.contains?(js, ~s|toLocaleString("en-US"|),
        do: [],
        else: [violation(:localizer_locale, "Assets.js_body/0", "no toLocaleString(\"en-US\")")]
      )
    ])
  end

  # StatusMap reads any non-nil lifecycle value as "recorded", so a producer must send a
  # timestamp, `true` or `nil`, never `false` (C-4). `terminal` is a real boolean and is
  # not one of the keys.
  @lifecycle_flags [:delivered_at, :bounced_at, :complained_at, :suppressed_at]

  defp false_flags(maps) do
    for map <- maps, key <- @lifecycle_flags, Map.get(map, key) == false do
      violation(:false_lifecycle_flag, "operator read model", "#{key}: false")
    end
  end

  defp route_violations(route_pairs, registered_pairs) do
    unregistered = Enum.sort(route_pairs -- registered_pairs)
    stale = Enum.sort(registered_pairs -- route_pairs)

    Enum.map(unregistered, &violation(:route_unregistered, "router", inspect(&1))) ++
      Enum.map(stale, &violation(:route_stale, "registry", inspect(&1)))
  end

  # `entries`: `[%{module:, live?:, components?:}]`. `registered_live` is the list of
  # LiveView modules in the registry; `known` is `known_component_modules/0`.
  defp module_violations(entries, registered_live, known) do
    live =
      for %{module: module, live?: true} <- entries, module not in registered_live do
        violation(:live_module_unregistered, "registry", inspect(module))
      end

    components =
      for %{module: module, components?: true} <- entries, not Map.has_key?(known, module) do
        violation(:component_module_unregistered, "known components", inspect(module))
      end

    exporting = for %{module: module, components?: true} <- entries, do: module

    stale =
      for {module, _kind} <- known, module not in exporting do
        violation(:component_module_stale, "known components", inspect(module))
      end

    live ++ components ++ stale
  end

  # -- helpers -------------------------------------------------------------------

  defp violation(rule, path, text), do: %{rule: rule, path: path, line: nil, text: text}
  defp rules(violations), do: Enum.map(violations, & &1.rule)
  defp blank?(values), do: values == [] or Enum.any?(values, &(String.trim(&1) == ""))

  defp node_text(node),
    do: node |> Floki.text(sep: " ") |> String.replace(~r/\s+/, " ") |> String.trim()

  defp badge_summary(badge), do: badge |> Floki.raw_html() |> String.slice(0, 120)

  # Fails with the formatted violations only (file, line, rule, text and the fix), not the
  # raw list ExUnit would print for a failed `== []`.
  defp assert_none([]), do: :ok

  defp assert_none(violations) do
    shown = Enum.take(violations, 20)
    more = length(violations) - length(shown)
    suffix = if more > 0, do: "\n... and #{more} more", else: ""
    flunk("#{length(violations)} violation(s):\n" <> format_violations(shown) <> suffix)
  end

  defp format_violations(violations) do
    Enum.map_join(violations, "\n", fn v ->
      where = if v.line, do: "#{v.path}:#{v.line}", else: v.path
      "#{where} [#{v.rule}] #{inspect(v.text)}. Fix: #{fix(v.rule)}"
    end)
  end

  defp fix(:time_without_zone),
    do: "render every time through Components.timestamp/1, which always ends in its zone"

  defp fix(:time_labelled),
    do: "a <time> carries no title and no aria-label: its visible text is its name (WCAG 2.5.3)"

  defp fix(:time_titled),
    do: "a timestamp or copy control carries no title attribute: the accessible text is the label"

  defp fix(:copy_label_omits_time),
    do: "the copy control's aria-label must contain the visible time text (WCAG 2.5.3)"

  defp fix(:time_without_datetime),
    do: "a <time> needs a datetime attribute: use Components.timestamp/1"

  defp fix(:bare_timestamp),
    do:
      "a time or date in text needs its zone right after it; render it through Components.timestamp/1"

  defp fix(:badge_empty), do: "a status is always a word: put the class word beside the mark"

  defp fix(:badge_class_word_without_mark),
    do:
      "draw a delivery class through Components.status_badge/1 with context: :delivery " <>
        "(an inbound outcome sets context: :inbound and keeps its icon)"

  defp fix(:status_mark_count),
    do: "a status holds exactly one aria-hidden svg mark and nothing else drawn"

  defp fix(:status_mark_labelled),
    do: "the mark carries no aria-label or title: the word is the accessible name"

  defp fix(:status_word_unknown), do: "the word must be a Copy.class_labels/0 label or Queued"
  defp fix(:status_class_unknown), do: "data-mg-status must be one of the five delivery classes"

  defp fix(:status_word_class_mismatch),
    do: "the word must be the label of the class in data-mg-status"

  defp fix(:time_format_outside_owner),
    do:
      "format a time only in Components (display_time/1, exact_utc/1) or add a named allow-list entry with a reason"

  defp fix(:hand_written_badge),
    do:
      "draw a status through Components.status_badge/1, or add a named allow-list entry with a reason"

  defp fix(:time_element_outside_timestamp),
    do: "write a <time> only inside Components.timestamp/1; call it instead of a second emitter"

  defp fix(:raw_html), do: "never render raw HTML outside the root layout's localizer script"
  defp fix(:fmt_missing), do: "the browser localizer needs a `const FMT = {...}`"

  defp fix(:fmt_without_zone_name),
    do: "FMT must set timeZoneName so a localized time keeps its zone"

  defp fix(:localizer_locale), do: "the localizer must call toLocaleString(\"en-US\", FMT)"

  defp fix(:false_lifecycle_flag),
    do: "send a timestamp, true or nil: StatusMap reads any non-nil lifecycle value as recorded"

  defp fix(:route_unregistered),
    do: "add the {module, action} to ScreenRegistry.registry/0 with its states"

  defp fix(:route_stale),
    do: "remove the {module, action} from ScreenRegistry.registry/0; no route mounts it"

  defp fix(:live_module_unregistered), do: "add the LiveView module to ScreenRegistry.registry/0"

  defp fix(:component_module_unregistered),
    do:
      "list the module in ScreenRegistry.known_component_modules/0 with the state or specimen that renders it"

  defp fix(:component_module_stale),
    do: "remove the module from ScreenRegistry.known_component_modules/0"

  defp assert_clean(results) do
    assert_none(Enum.flat_map(results, & &1.violations))
  end

  defp lib_sources do
    @scope_dir
    |> Path.join("**/*.{ex,heex}")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, @scope_dir), File.read!(&1)})
  end

  defp loaded_module_entries do
    {:ok, modules} = :application.get_key(:mailglass_admin, :modules)

    for module <- Enum.sort(modules), Code.ensure_loaded?(module) do
      %{
        module: module,
        live?: function_exported?(module, :__live__, 0),
        components?: function_exported?(module, :__components__, 0)
      }
    end
  end

  # The full status x last event x confirmed universe, from the schema's own accessors.
  defp grid_universe do
    length(Ecto.Enum.values(Delivery, :status)) * (length(Delivery.__event_types__()) + 1) * 2
  end

  defp all_worlds_with_fake_ids do
    rows =
      for status <- Ecto.Enum.values(Delivery, :status),
          last <- Delivery.__event_types__(),
          confirmed <- [true, false],
          do: %{
            id: "#{status}-#{last}-#{confirmed}",
            status: status,
            last_event_type: last,
            confirmed: confirmed
          }

    %{
      static: true,
      grid: %{rows: rows, count: length(rows)},
      journey: %{ids: %{bounce: "journey-bounce"}},
      replay: %{delivery_id: "replay-delivery"},
      timeline: %{delivery_id: "timeline-delivery"},
      inbound: %{record_ids: ["record-1"], tenant_id: @tenant_id}
    }
  end

  # -- mounting ------------------------------------------------------------------

  defp scan_states(conn, states) do
    for state <- states do
      html = mount_state(conn, state)
      Map.put(scan_html(state.label, html), :state, state)
    end
  end

  defp mount_state(conn, state) do
    conn =
      if state.route in [{PreviewLive, :index}, {PreviewLive, :show}, {GalleryLive, :index}],
        do: conn,
        else: operator_conn(conn)

    case state.mount do
      :dead ->
        conn |> get(state.path) |> html_response(200)

      :live ->
        view = mount(conn, state.path)
        for {event, payload} <- state.hooks, do: render_hook(view, event, payload)

        if state.expect do
          assert has_element?(view, state.expect),
                 "#{state.label} (#{state.path}) never reached #{state.expect}"
        end

        render(view)
    end
  end

  # Some screens answer with a redirect that normalises the URL (the Preview adds a width).
  # Follow it, as a browser does, so the scan reads the screen the operator lands on.
  defp mount(conn, path, hops \\ 3) do
    case live(conn, path) do
      {:ok, view, _html} ->
        view

      {:error, {kind, %{to: to}}}
      when kind in [:redirect, :live_redirect, :live_patch] and hops > 0 ->
        mount(conn, to, hops - 1)
    end
  end

  # The cells with no last event type are not storable, so they render through the
  # components directly: one list holding every row, then a Quick view and a header per row.
  defp scan_nil_cells do
    rows = nil_cell_rows()

    list =
      render_component(&DeliveriesList.deliveries_list/1,
        deliveries: rows,
        page_meta: %{
          total_count: length(rows),
          page: 1,
          per_page: 20,
          total_pages: 1,
          has_previous?: false,
          has_next?: false
        }
      )

    quick =
      for row <- rows do
        {"nil cell Quick view #{row.id}",
         render_component(&QuickView.quick_view/1,
           delivery: row,
           full_path: "/ops/mail?delivery_id=#{row.id}&full=1",
           close_path: "/ops/mail"
         )}
      end

    detail =
      for row <- rows do
        {"nil cell detail #{row.id}",
         render_component(&DetailHeader.detail_header/1, delivery: row)}
      end

    for {label, html} <- [{"nil cell list", list}] ++ quick ++ detail do
      Map.put(scan_html(label, html), :state, %{label: label})
    end
  end

  defp nil_cell_rows do
    for status <- Ecto.Enum.values(Delivery, :status), confirmed <- [true, false] do
      %{
        id: "nil-cell-#{status}-#{confirmed}",
        tenant_id: @tenant_id,
        recipient: "nil-#{status}-#{confirmed}@example.com",
        subject: nil,
        status: status,
        provider: "postmark",
        stream: :transactional,
        mailable: "MyApp.AccountMailer",
        provider_message_id: nil,
        last_event_type: nil,
        last_event_at: @at,
        inserted_at: @at,
        delivery_confirmed: confirmed,
        bounced_at: nil,
        terminal: nil,
        delivered_at: if(confirmed, do: @at),
        complained_at: nil,
        suppressed_at: if(status == :suppressed, do: @at)
      }
    end
  end

  defp seed_inbound!(:no_match),
    do:
      InboundFixtures.seed_no_match!(@tenant_id, recipient: "inbound-no-match@example.com").record.id

  defp seed_inbound!(:accept),
    do:
      InboundFixtures.seed_matched!(@tenant_id, recipient: "inbound-accept@example.com").record.id

  defp seed_inbound!(outcome) do
    record =
      InboundFixtures.insert_record!(@tenant_id, recipient: "inbound-#{outcome}@example.com")

    evidence = InboundFixtures.insert_evidence!(@tenant_id, record.id)
    InboundFixtures.insert_run!(@tenant_id, record.id, evidence.id, outcome: outcome)
    record.id
  end

  # Observed counts, printed only when asked, so a plan summary can record them.
  defp report(label, results) do
    if System.get_env("PHASE182_REPORT") do
      counts =
        for key <- [:times, :badges, :marks], into: %{states: length(results)} do
          {key, results |> Enum.map(&Map.fetch!(&1, key)) |> Enum.sum()}
        end

      IO.puts("PHASE182 #{label}: #{inspect(counts)}")
    end
  end

  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
  end
end
