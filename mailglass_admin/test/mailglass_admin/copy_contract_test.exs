defmodule MailglassAdmin.CopyContractTest do
  @moduledoc """
  Contract for the words an operator sees for a status: `MailglassAdmin.Copy` owns
  every status label, icon and badge class, and nothing else in `mailglass_admin/lib`
  may carry its own copy of them.

  Three layers, because each one alone misses something:

    1. Golden table. A map written as literals in this file, independent of
       `Copy`, equals `Copy.statuses/0` for all 25 badge atoms. A changed label,
       icon or class goes red here. Layer 2 alone cannot see it, because it compares
       rendered text with `Copy`, which would have changed too.
    2. Render. Every atom goes through `status_badge/1`, `outcome_badge/1` and
       `message_identity/1` (both contexts) and the visible text, with scripts
       stripped, equals the `Copy` label by exact binary equality. A hardcoded
       literal that differs from `Copy` goes red here.
    3. Closed-set source scan of `mailglass_admin/lib` outside `copy.ex`. Layer 3a
       counts quoted literals exactly equal to a status label, per file, against a
       recorded baseline, in both directions. A hardcoded copy of a label that
       renders the same text is invisible to layer 2 and goes red here. Layer 3b
       binds the closed set of phrases that carry a status word inside a longer
       string or as HEEx text.

  Label equality is exact binary equality after script stripping and whitespace
  collapse (for example the ASCII hyphen in "Auto-replied"); there is no case
  folding or normalization.

  Surfaces that render a status, and what covers each:

    * `status_badge/1`, `outcome_badge/1`, `message_identity/1`: layer 2 render.
    * `Operator.Timeline`, `Operator.QuickView`, `Operator.DeliveriesList`,
      `Operator.DetailHeader`, `Operator.FiltersForm`, `Operator.SupportCards`,
      `Operator.SuppressionCard`, `Inbound.FiltersForm`, `Inbound.Overview`,
      `Inbound.RecordsList`, `Inbound.Timeline`, `OperatorLive`, `InboundLive`,
      `Operator.Shell`, `Inbound.DetailHeader`: layer 3 source scan. Layer 3a counts
      quoted literals exactly equal to a status label; layer 3b binds the phrases that
      carry a status word, each recorded as deferred with its file and line. Their
      mounted rendering stays pinned by the existing LiveView tests.
    * `gallery_live.ex` is excluded because it holds specimen fixtures, and
      `copy.ex` is excluded because it is the owner.

  Layer 3a does not see phrase surfaces. A status word inside a phrase, for example
  the `OperatorLive` overview tiles "Failed deliveries", "Bounced deliveries",
  "Rejected deliveries" and "Delayed deliveries", is outside `Copy` in this phase and
  is bound only by the layer 3b closed set. Routing those phrases through `Copy` is
  deferred to the phase that changes the words on screen. The same deferral covers
  a known divergence: `:deferred` reads "Deferred" on the badge and "Delayed
  deliveries" on the overview tile (`operator_live.ex` line 2859 at commit 062a4cfa).

  Lowercase status words inside prose (for example `outcome_help/2` and the tile help
  sentences) are out of scope: `outcome_help/2` is status-keyed prose and stays
  unmoved in this phase, and enforcing the prose rule belongs to the later phases
  that change screen words.

  The retired-word rule has two parts. Part A binds: no retired word leaks onto
  another atom's badge. Part B ("absent where mapped") binds the row-level class badge:
  for every class label marked `wired: true` in `Copy.class_labels/0`, the badge that
  `Components.delivery_badge/1` renders for an exemplar row of that class reads the plain
  class word and none of the retired words. All five class labels are wired (Phase 182),
  so Part B binds all five. The atom-level badges keep their event words, so Part B no
  longer walks them: a bounced event is still "Bounced" on the timeline and Failed on the
  row. Its teeth are proven below with a synthetic wired entry.

  Each rule was proven red by a temporary source mutation, recorded in the plan
  SUMMARY and reverted. The teeth block proves each detector goes red on a planted
  known-bad input, so a pass is not vacuous.
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.{Components, Copy, StatusMap}

  @lib_dir Path.expand("../../lib", __DIR__)
  @excluded_files ["mailglass_admin/copy.ex", "mailglass_admin/gallery_live.ex"]

  # Layer 1 golden table, written from the pre-change clause families in
  # components.ex (commit 12acab86). Independent of Copy by construction.
  @golden %{
    dispatched: {"Dispatched", "hero-paper-airplane", "badge-primary"},
    queued: {"Queued", "hero-arrow-path", "badge-primary"},
    sent: {"Sent", "hero-paper-airplane", "badge-primary"},
    delivered: {"Delivered", "hero-check-circle", "badge-success"},
    deferred: {"Deferred", "hero-exclamation-triangle", "badge-warning"},
    bounced: {"Bounced", "hero-x-circle", "badge-error"},
    failed: {"Failed", "hero-x-circle", "badge-error"},
    rejected: {"Rejected", "hero-x-circle", "badge-error"},
    complained: {"Complained", "hero-exclamation-circle", "badge-error"},
    unsubscribed: {"Unsubscribed", "hero-bell-slash", "badge-warning"},
    opened: {"Opened", "hero-envelope-open", "badge-success"},
    clicked: {"Clicked", "hero-hand-thumb-up", "badge-success"},
    autoresponded: {"Auto-replied", "hero-arrow-uturn-left", "badge-outline"},
    unknown: {"Unknown", "hero-question-mark-circle", "badge-outline"},
    accepted: {"Accepted", "hero-check-circle", "badge-success"},
    no_match: {"Unrouted", "hero-exclamation-triangle", "badge-warning"},
    ignore: {"Ignored", "hero-minus-circle", "badge-outline"},
    no_change: {"No change", "hero-minus-circle", "badge-outline"},
    missing_history: {"No history", "hero-question-mark-circle", "badge-outline"},
    failed_ingest: {"Ingest failed", "hero-exclamation-circle", "badge-error"},
    webhook_replay_requested: {"Replay requested", "hero-arrow-path", "badge-outline"},
    webhook_replay_succeeded: {"Replay succeeded", "hero-check-circle", "badge-success"},
    webhook_replay_failed: {"Replay failed", "hero-x-circle", "badge-error"},
    reconciled: {"Reconciled", "hero-exclamation-triangle", "badge-warning"},
    suppressed: {"Suppressed", "hero-minus-circle", "badge-warning"}
  }

  @golden_unknown {"Unknown", "hero-question-mark-circle", "badge-outline"}

  @retired_words ["Accepted", "Deferred", "Suppressed"]

  # Every status label the badge can show, plus the fallback.
  @labels @golden
          |> Map.values()
          |> Enum.map(&elem(&1, 0))
          |> Kernel.++(["Unknown"])
          |> Enum.uniq()

  # Layer 3a baselines, measured on the tree after the label clause families moved to
  # Copy. Changing a number is a reviewed decision, not a way to make the test pass.
  @literal_baseline %{
    "mailglass_admin/components.ex" => 3,
    "mailglass_admin/inbound/filters_form.ex" => 8,
    "mailglass_admin/inbound/overview.ex" => 3,
    "mailglass_admin/operator/deliveries_list.ex" => 1,
    "mailglass_admin/operator/detail_header.ex" => 1,
    "mailglass_admin/operator/filters_form.ex" => 1,
    "mailglass_admin/operator/timeline.ex" => 1,
    "mailglass_admin/operator_live.ex" => 1
  }

  # Computed labels a literal scan cannot see: String.capitalize on an atom.
  @capitalize_baseline %{
    "mailglass_admin/components.ex" => 1,
    "mailglass_admin/inbound_live.ex" => 1,
    "mailglass_admin/operator_live.ex" => 1,
    "mailglass_admin/inbound/filters_form.ex" => 1,
    "mailglass_admin/operator/support_cards.ex" => 2,
    "mailglass_admin/operator/timeline.ex" => 1,
    "mailglass_admin/preview/scenario_label.ex" => 1,
    "mailglass_admin/operator/detail_header.ex" => 1,
    "mailglass_admin/operator/suppression_card.ex" => 1,
    "mailglass_admin/operator/quick_view.ex" => 1,
    "mailglass_admin/operator/deliveries_list.ex" => 1,
    "mailglass_admin/operator/filters_form.ex" => 1
  }

  # Layer 3b: the closed set of phrases that carry a status word inside a longer
  # string or as HEEx text. `line_at` is the line at commit 062a4cfa, for traceability
  # only; it is never asserted because lines shift. `atom` is the status the phrase
  # speaks for (nil when the word is used in another sense).
  @status_phrases [
    %{
      path: "mailglass_admin/operator_live.ex",
      phrase: "Failed deliveries",
      word: "Failed",
      atom: :failed,
      line_at: 2854,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator_live.ex",
      phrase: "Bounced deliveries",
      word: "Bounced",
      atom: :bounced,
      line_at: 2856,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator_live.ex",
      phrase: "Rejected deliveries",
      word: "Rejected",
      atom: :rejected,
      line_at: 2858,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator_live.ex",
      phrase: "Delayed deliveries",
      word: "Delayed",
      atom: :deferred,
      line_at: 2859,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator_live.ex",
      phrase: "Failed webhook attempts",
      word: "Failed",
      atom: :failed_ingest,
      line_at: 2831,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator_live.ex",
      phrase: "Failed inbound processing",
      word: "Failed",
      atom: :failed,
      line_at: 2886,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator_live.ex",
      phrase: "Unrouted inbound messages",
      word: "Unrouted",
      atom: :no_match,
      line_at: 2888,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/inbound_live.ex",
      phrase: "Replay requested. The runtime reported that this replay is queued.",
      word: "Replay requested",
      atom: :webhook_replay_requested,
      line_at: 1251,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/inbound_live.ex",
      phrase: "Replay run recorded. Mailbox outcome: No change.",
      word: "No change",
      atom: :no_change,
      line_at: 1257,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/inbound_live.ex",
      phrase: "Replay run recorded. Mailbox outcome: Accepted.",
      word: "Accepted",
      atom: :accepted,
      line_at: 1260,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/inbound_live.ex",
      phrase: "Replay run recorded. Mailbox outcome: Ignored.",
      word: "Ignored",
      atom: :ignore,
      line_at: 1263,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/inbound_live.ex",
      phrase: "Replay run recorded. Mailbox outcome: Rejected.",
      word: "Rejected",
      atom: :rejected,
      line_at: 1266,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/inbound_live.ex",
      phrase: "Replay run recorded. Mailbox outcome: Bounced.",
      word: "Bounced",
      atom: :bounced,
      line_at: 1269,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/components.ex",
      phrase: "Delivered to",
      word: "Delivered",
      atom: nil,
      line_at: 587,
      disposition: :not_a_status
    },
    %{
      path: "mailglass_admin/operator/shell.ex",
      phrase: "Failed ingest? Review the provider signature log.",
      word: "Failed",
      atom: :failed_ingest,
      line_at: 598,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator/timeline.ex",
      phrase: "Unknown event",
      word: "Unknown",
      atom: :unknown,
      line_at: 267,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator/support_cards.ex",
      phrase: "Failed webhook attempts in the selected Account window.",
      word: "Failed",
      atom: :failed_ingest,
      line_at: 155,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator/support_cards.ex",
      phrase: "Reconciled Events",
      word: "Reconciled",
      atom: :reconciled,
      line_at: 251,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/operator/support_cards.ex",
      phrase: "Failed webhook attempts unavailable",
      word: "Failed",
      atom: :failed_ingest,
      line_at: 332,
      disposition: :deferred
    },
    %{
      path: "mailglass_admin/inbound/detail_header.ex",
      phrase: "Delivered to address",
      word: "Delivered",
      atom: nil,
      line_at: 99,
      disposition: :not_a_status
    },
    %{
      path: "mailglass_admin/inbound/detail_header.ex",
      phrase: "Delivered to",
      word: "Delivered",
      atom: nil,
      line_at: 94,
      disposition: :not_a_status
    },
    %{
      path: "mix/tasks/mailglass_admin.daisyui.update.ex",
      phrase: "Failed to fetch",
      word: "Failed",
      atom: nil,
      line_at: 70,
      disposition: :not_a_status
    }
  ]

  # Status words for layer 3b: the golden labels plus the two class labels that have
  # no badge of their own.
  @phrase_words @labels ++ ["Delayed", "Not sent"]

  @quoted_re ~r/"((?:[^"\\\n]|\\.)*)"/
  @doc_heredoc_re ~r/@(?:module)?doc\s+(?:~[sS])?"""\n.*?"""/s
  @word_re Regex.compile!(
             "\\b(?:" <> Enum.map_join(@phrase_words, "|", &Regex.escape/1) <> ")\\b"
           )
  @heex_re Regex.compile!(
             "(?:>|^[ \\t]*)((?:" <>
               Enum.map_join(@phrase_words, "|", &Regex.escape/1) <> ")\\b[^<\\n]*)"
           )

  # -- helpers ------------------------------------------------------------------

  defp visible_text(html) do
    html
    |> Floki.parse_fragment!()
    |> Floki.filter_out("script")
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
  end

  defp badge_text(status) do
    (&Components.status_badge/1)
    |> render_component(status: status, size: :sm)
    |> visible_text()
    |> String.trim()
  end

  defp relative(file), do: Path.relative_to(file, @lib_dir)

  defp scanned_files do
    @lib_dir
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.reject(&(relative(&1) in @excluded_files))
    |> Enum.sort()
  end

  # Source with @moduledoc/@doc heredocs removed and whole-line comments dropped.
  defp strip_noise(source) do
    @doc_heredoc_re
    |> Regex.replace(source, "")
    |> String.split("\n")
    |> Enum.reject(&Regex.match?(~r/^\s*#/, &1))
  end

  defp quoted_literals(lines) do
    Enum.flat_map(lines, fn line ->
      @quoted_re |> Regex.scan(line, capture: :all_but_first) |> Enum.map(&hd/1)
    end)
  end

  defp count_label_literals(source) do
    source |> strip_noise() |> quoted_literals() |> Enum.count(&(&1 in @labels))
  end

  defp count_capitalize(source) do
    source
    |> strip_noise()
    |> Enum.count(&String.contains?(&1, "String.capitalize"))
  end

  defp per_file(fun) do
    for file <- scanned_files(),
        count = fun.(File.read!(file)),
        count > 0,
        into: %{},
        do: {relative(file), count}
  end

  # Only the paths whose count differs: {path, found, recorded}.
  defp count_diff(observed, recorded) do
    for path <- Enum.sort(Enum.uniq(Map.keys(observed) ++ Map.keys(recorded))),
        Map.get(observed, path, 0) != Map.get(recorded, path, 0),
        do: {path, Map.get(observed, path, 0), Map.get(recorded, path, 0)}
  end

  # {path, phrase} pairs for status words inside longer strings or as HEEx text.
  defp phrases_in(path, source) do
    lines = strip_noise(source)

    quoted =
      lines
      |> quoted_literals()
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 not in @labels and Regex.match?(@word_re, &1)))

    heex =
      lines
      |> Enum.flat_map(fn line ->
        @heex_re |> Regex.scan(line, capture: :all_but_first) |> Enum.map(&hd/1)
      end)
      |> Enum.map(&String.trim/1)

    MapSet.new(quoted ++ heex, &{path, &1})
  end

  defp scanned_phrases do
    scanned_files()
    |> Enum.map(&phrases_in(relative(&1), File.read!(&1)))
    |> Enum.reduce(MapSet.new(), &MapSet.union/2)
  end

  # Retired words that leaked onto another atom's badge. `texts` is atom => visible text.
  defp retired_leaks(texts) do
    for {atom, text} <- texts,
        {golden_label, _, _} = Map.fetch!(@golden, atom),
        golden_label not in @retired_words,
        word <- @retired_words,
        String.contains?(text, word),
        do: {atom, word}
  end

  # An exemplar operator row per delivery class, fully keyed the way get_delivery/2
  # returns it on a current core. Part B renders the row-level class badge for each.
  @exemplar_base %{
    status: :sent,
    last_event_type: :sent,
    provider: "postmark",
    delivery_confirmed: false,
    bounced_at: nil,
    terminal: nil,
    delivered_at: nil,
    complained_at: nil,
    suppressed_at: nil
  }

  @exemplar_rows %{
    sent: @exemplar_base,
    delivered:
      Map.merge(@exemplar_base, %{
        last_event_type: :delivered,
        delivery_confirmed: true,
        delivered_at: ~U[2026-11-15 12:00:00Z],
        terminal: true
      }),
    delayed: Map.merge(@exemplar_base, %{last_event_type: :deferred}),
    failed:
      Map.merge(@exemplar_base, %{
        last_event_type: :bounced,
        bounced_at: ~U[2026-11-15 12:00:00Z],
        terminal: true
      }),
    not_sent:
      Map.merge(@exemplar_base, %{
        last_event_type: :suppressed,
        suppressed_at: ~U[2026-11-15 12:00:00Z],
        terminal: true
      })
  }

  defp class_badge_text(class) do
    (&Components.delivery_badge/1)
    |> render_component(row: Map.fetch!(@exemplar_rows, class))
    |> visible_text()
    |> String.trim()
  end

  # Per-class rule for class labels that are wired: the row-level class badge reads the
  # plain class word and none of the retired words. Returns {class, text} violations.
  defp wired_class_violations(class_labels) do
    for %{wired: true, class: class, label: label} <- class_labels,
        text = class_badge_text(class),
        text != label or Enum.any?(@retired_words, &String.contains?(text, &1)),
        do: {class, text}
  end

  # -- teeth --------------------------------------------------------------------

  describe "detectors have teeth" do
    test "the literal counter counts a quoted status literal and ignores docs and comments" do
      assert count_label_literals(~s|def a, do: "Delivered"|) == 1

      assert count_label_literals(~S'''
             @doc """
             "Delivered"
             """
             def a, do: :ok
             ''') == 0

      assert count_label_literals(~s|# "Delivered"\ndef a, do: :ok|) == 0
    end

    test "the capitalize counter counts a computed label and ignores comments" do
      assert count_capitalize("def a(x), do: String.capitalize(to_string(x))") == 1
      assert count_capitalize("# String.capitalize(x)\ndef a, do: :ok") == 0
    end

    test "the phrase detector collects status words inside longer strings and HEEx text" do
      assert phrases_in("fixture.ex", ~s|def a, do: "Failed deliveries"|) ==
               MapSet.new([{"fixture.ex", "Failed deliveries"}])

      assert phrases_in("fixture.ex", "<dt>Reconciled Events</dt>") ==
               MapSet.new([{"fixture.ex", "Reconciled Events"}])

      assert phrases_in("fixture.ex", "    Failed webhook attempts unavailable\n") ==
               MapSet.new([{"fixture.ex", "Failed webhook attempts unavailable"}])
    end

    test "the phrase detector ignores comments, exact labels and doc heredocs" do
      assert phrases_in("fixture.ex", ~s|# "Failed deliveries"|) == MapSet.new()
      assert phrases_in("fixture.ex", ~s|# <dt>Reconciled Events</dt>|) == MapSet.new()
      assert phrases_in("fixture.ex", ~s|def a, do: "Delivered"|) == MapSet.new()

      assert phrases_in("fixture.ex", ~S'''
             @doc """
             "Failed deliveries"
             """
             def a, do: :ok
             ''') == MapSet.new()
    end

    test "retired-word guard Part A flags a retired word on another atom's badge" do
      assert retired_leaks(%{delivered: "Deferred"}) == [delivered: "Deferred"]
      assert retired_leaks(%{deferred: "Deferred", accepted: "Accepted"}) == []
    end

    test "retired-word guard Part B flags a wired class label the badge does not read" do
      # The delayed exemplar badge reads "Delayed". A planted entry that names another
      # word for that class is flagged, so the rule is not vacuous.
      violations = wired_class_violations([%{class: :delayed, label: "Deferred", wired: true}])

      assert violations == [{:delayed, "Delayed"}]

      assert wired_class_violations([%{class: :delayed, label: "Delayed", wired: true}]) == []
      assert wired_class_violations([%{class: :delayed, label: "Deferred", wired: false}]) == []
    end

    test "every class exemplar renders its own word, so Part B has one case per class" do
      assert Map.keys(@exemplar_rows) |> Enum.sort() ==
               Enum.sort(StatusMap.classes() -- [:not_a_delivery_status])

      for %{class: class, label: label} <- Copy.class_labels() do
        assert class_badge_text(class) == label
      end
    end

    test "visible_text strips a planted script element" do
      assert visible_text("<p>Hello</p><script>var Delivered = 1</script>") |> String.trim() ==
               "Hello"
    end
  end

  # -- layer 1: golden ----------------------------------------------------------

  describe "layer 1: golden table" do
    test "Copy.statuses/0 equals the golden table for all 25 atoms" do
      copy =
        Map.new(Copy.statuses(), fn {atom, %{label: label, icon: icon, class: class}} ->
          {atom, {label, icon, class}}
        end)

      assert map_size(@golden) == 25
      assert copy == @golden
    end

    test "Copy.unknown/0 is the verbatim fallback" do
      %{label: label, icon: icon, class: class} = Copy.unknown()
      assert {label, icon, class} == @golden_unknown
    end

    test "the strict functions raise for nil and for :subscribed" do
      for fun <- [:status_label, :status_icon, :status_class], value <- [nil, :subscribed] do
        assert_raise FunctionClauseError, fn -> apply(Copy, fun, [value]) end
      end
    end

    test "the *_or_unknown functions carry the one sanctioned fallback" do
      assert Copy.status_label_or_unknown(nil) == "Unknown"
      assert Copy.status_icon_or_unknown(nil) == "hero-question-mark-circle"
      assert Copy.status_class_or_unknown(nil) == "badge-outline"
      assert Copy.status_label_or_unknown(:delivered) == "Delivered"
    end
  end

  # -- layer 2: render ----------------------------------------------------------

  describe "layer 2: render" do
    test "status_badge renders the Copy label, icon and class for every atom" do
      # Compared with Copy, not the golden table: this layer proves the render path
      # reads Copy. Layer 1 owns the literal values.
      for atom <- Map.keys(Copy.statuses()) do
        html = render_component(&Components.status_badge/1, status: atom, size: :sm)

        assert badge_text(atom) == Copy.status_label(atom)
        assert html =~ Copy.status_icon(atom)
        assert html =~ Copy.status_class(atom)
        refute html =~ "data-mg-status"
      end
    end

    # Phase 182 (D-10): in a delivery context the four atoms whose label is a class word
    # draw the pane mark and the Copy label. In an inbound or context-free badge they keep
    # the Heroicon, so an inbound :failed never reads as a delivery failure.
    test "the four class-word atoms draw the mark in a delivery context and the icon elsewhere" do
      for atom <- [:sent, :queued, :delivered, :failed] do
        label = Copy.status_label(atom)

        delivery =
          render_component(&Components.status_badge/1,
            status: atom,
            size: :sm,
            context: :delivery
          )

        assert visible_text(delivery) |> String.trim() == label
        assert delivery =~ "data-mg-status"
        assert [_] = delivery |> Floki.parse_fragment!() |> Floki.find("svg[aria-hidden=true]")
        refute delivery =~ Copy.status_icon(atom)

        for context <- [:inbound, nil] do
          html =
            render_component(&Components.status_badge/1,
              status: atom,
              size: :sm,
              context: context
            )

          assert html =~ Copy.status_icon(atom)
          refute html =~ "data-mg-status"
          assert visible_text(html) |> String.trim() == label
        end
      end
    end

    test "every other atom keeps its Heroicon in a delivery context" do
      for atom <- Map.keys(Copy.statuses()) -- [:sent, :queued, :delivered, :failed] do
        html =
          render_component(&Components.status_badge/1,
            status: atom,
            size: :sm,
            context: :delivery
          )

        assert html =~ Copy.status_icon(atom)
        refute html =~ "data-mg-status"
      end
    end

    test "a missing status renders the single sanctioned fallback" do
      html = render_component(&Components.status_badge/1, status: nil, size: :sm)
      {label, icon, class} = @golden_unknown

      assert badge_text(nil) == label
      assert html =~ icon
      assert html =~ class
    end

    test "outcome_badge and message_identity carry the label in both contexts" do
      for atom <- Map.keys(Copy.statuses()), context <- [:delivery, :inbound] do
        label = Copy.status_label(atom)

        outcome =
          (&Components.outcome_badge/1)
          |> render_component(id: "outcome-#{atom}", status: atom, context: context)
          |> visible_text()

        identity =
          (&Components.message_identity/1)
          |> render_component(
            id: "identity-#{atom}",
            subject: "Subject line",
            recipient: "someone@example.com",
            status: atom,
            context: context
          )
          |> visible_text()

        assert outcome =~ label,
               "outcome_badge #{inspect(atom)}/#{context} lost #{inspect(label)}"

        assert identity =~ label,
               "message_identity #{inspect(atom)}/#{context} lost #{inspect(label)}"
      end
    end

    test "retired words do not leak onto another atom's badge (Part A)" do
      texts = Map.new(Map.keys(Copy.statuses()), &{&1, badge_text(&1)})

      assert retired_leaks(texts) == []
    end

    test "every wired class label is the plain word on its row-level class badge (Part B)" do
      assert Enum.all?(Copy.class_labels(), & &1.wired)
      assert wired_class_violations(Copy.class_labels()) == []
    end
  end

  # -- layer 3: source scan -----------------------------------------------------

  describe "layer 3a: quoted status literals outside Copy" do
    test "per-file counts equal the recorded baseline in both directions" do
      observed = per_file(&count_label_literals/1)

      assert observed == @literal_baseline,
             "Quoted status literals outside MailglassAdmin.Copy changed " <>
               "(path, found, recorded): #{inspect(count_diff(observed, @literal_baseline))}. " <>
               "Route the word through MailglassAdmin.Copy, or update @literal_baseline " <>
               "deliberately."
    end

    test "per-file String.capitalize counts equal the recorded computed-label baseline" do
      observed = per_file(&count_capitalize/1)

      assert observed == @capitalize_baseline,
             "A computed status label appeared or moved " <>
               "(path, found, recorded): #{inspect(count_diff(observed, @capitalize_baseline))}. " <>
               "Route the word through MailglassAdmin.Copy, or update @capitalize_baseline " <>
               "deliberately."
    end
  end

  describe "layer 3b: status words inside phrases" do
    test "the collected phrase set equals @status_phrases in both directions" do
      recorded = MapSet.new(@status_phrases, &{&1.path, &1.phrase})
      found = scanned_phrases()

      new = MapSet.difference(found, recorded) |> Enum.sort()
      stale = MapSet.difference(recorded, found) |> Enum.sort()

      assert {new, stale} == {[], []},
             "Status-word phrases changed. New phrase surfaces: #{inspect(new)}. Recorded " <>
               "entries no longer found (removed or reworded): #{inspect(stale)}. Route the " <>
               "phrase through MailglassAdmin.Copy, or add it to @status_phrases with a " <>
               "disposition deliberately."
    end

    # 22, not 23: Phase 182 rewrote the Needs attention summary help to describe the
    # delivery-class rule in lowercase prose ("failed, were delayed, or were not
    # sent"), so it no longer carries a capitalised status word and left the set.
    test "the recorded set is the 22 planned entries" do
      assert length(@status_phrases) == 22
      assert length(Enum.uniq_by(@status_phrases, &{&1.path, &1.phrase})) == 22
      assert Enum.all?(@status_phrases, &(&1.disposition in [:deferred, :not_a_status]))
    end

    test "every recorded phrase names its status word" do
      for %{phrase: phrase, word: word} <- @status_phrases do
        assert String.contains?(phrase, word), "#{inspect(phrase)} does not contain #{word}"
      end
    end
  end

  # -- vocabulary ---------------------------------------------------------------

  describe "vocabulary binding" do
    test "every wired entry's on-screen word appears in a string literal outside Copy" do
      literals =
        scanned_files()
        |> Enum.flat_map(&(&1 |> File.read!() |> strip_noise() |> quoted_literals()))

      for %{wired: true, on_screen: word} <- Copy.vocabulary() do
        assert Enum.any?(literals, &String.contains?(&1, word)),
               "#{inspect(word)} is marked wired in Copy.vocabulary/0 but no screen string uses it"
      end
    end

    test "vocabulary and class label entries are present as data, and the class labels are wired" do
      for entry <- Copy.vocabulary() ++ Copy.class_labels() do
        assert is_boolean(entry.wired)
      end

      for %{public_name: public, on_screen: word, gloss: gloss} <- Copy.vocabulary() do
        assert public != "" and word != "" and gloss != ""
      end

      for %{label: label} <- Copy.class_labels(), do: assert(label != "")
      assert Enum.any?(Copy.vocabulary(), &(&1.wired == true))
      assert Enum.all?(Copy.class_labels(), &(&1.wired == true))
    end
  end
end
