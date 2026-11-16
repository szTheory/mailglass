defmodule MailglassAdmin.Phase182WordsContractTest do
  @moduledoc """
  BRADM-03, BRADM-04 and BRADM-05 required-lane proof (lane `support_contract_admin`): the
  admin says Activity, Admin and Account where the brand book says them, and it never
  renames anything an adopter depends on.

  The words rule scans every state in `MailglassAdmin.TestSupport.ScreenRegistry` (the same
  screens the time and status contract scans, so a new screen is caught by both). For each
  state it reads the words a reader meets: the page text (scripts and styles removed, hover
  and screen-reader text kept, because a help sentence is still a sentence), the values of
  `aria-label`, `title`, `alt`, `placeholder` and `aria-description`, and the document
  `<title>`. Three case-insensitive word-boundary detectors run over that text:

    * `deliveries` as the screen's name (the singular domain noun `delivery` is not flagged:
      "Delivery timeline" and "one row per delivery" stay),
    * `operator` and `operators`,
    * `tenant` and `tenants` (`tenant_id` is a code identifier, not a word: it stays).

  BRADM-05 adds two more rules the same way. The orphan sentence reads "N provider reports
  match no email" (singular "1 provider report matches no email") at every site that shows a
  count, from `Operator.OrphanCount.label/1`. The mailer shows its plain name as an accessible
  help trigger whose tooltip holds the stored identity, and the identity is also printed in
  full beside it, so a touch reader never depends on hover. Fixture data must not use the
  retired words (a mailer called `OperatorMailer` would read "Operator mailer"): a fixture
  that did would be indistinguishable from a regression.

  Every detector is a pure function proven on planted violations and clean controls, so the
  scan cannot go vacuous ("detectors have teeth"), and the scan asserts a floor on what it
  read. The advisory e2e pins for these words move in plan 182-05; this file is the required
  proof and never cites them.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.{GalleryLive, OperatorLive, PreviewLive}
  alias MailglassAdmin.Inbound.DestructiveAction
  alias MailglassAdmin.Operator.{DeliveriesList, DetailHeader, OrphanCount, Shell, SupportCards}
  alias MailglassAdmin.Preview.ReturnContext
  alias MailglassAdmin.TestSupport.{InboundFixtures, OperatorFixtures, ScreenRegistry}
  alias MailglassInbound.InboundRecords.ExecutionRun

  @tenant_id "browser-tenant"
  @at ~U[2026-11-15 14:05:09.123456Z]
  @gloss "Every email your app sent, one row per delivery."

  # The three words that leave screen text. Each rule is a case-insensitive regex that needs a
  # word of its own: `Deliveries`, `deliveries`, `OPERATOR` and `Operator's` are all caught.
  # A fragment of an identifier is data, not a word, so the match may not touch a word
  # character or a hyphen: the singular `delivery`, the code identifiers `tenant_id` and
  # `deliveries_path`, and an Account id an adopter chose (`browser-tenant`) are not flagged.
  @rules [
    {:deliveries_word, ~r/(?<![\w-])deliveries(?![\w-])/iu},
    {:operator_word, ~r/(?<![\w-])operators?(?![\w-])/iu},
    {:tenant_word, ~r/(?<![\w-])tenants?(?![\w-])/iu}
  ]

  # Attributes a reader or a screen reader meets as words.
  @word_attributes ~w(aria-label aria-description title alt placeholder)

  defmodule DenyAdapter do
    @moduledoc false
    # An adopter auth module that denies with no message, so the denial the Inbound replay
    # shows is mailglass's own default sentence.
    @behaviour MailglassAdmin.Auth

    @impl true
    def authorize(:replay_inbound, _context), do: {:error, :unauthorized, %{}}
  end

  # -- Activity identity (Task 1) --------------------------------------------------

  describe "Activity identity (BRADM-03, D-11)" do
    setup %{conn: conn} do
      journey = OperatorFixtures.seed_phase182_journey!()
      {:ok, conn: operator_conn(conn), journey: journey}
    end

    test "the Activity screen reads Activity in its nav, <title>, h1 and gloss", %{conn: conn} do
      html = conn |> dead_get(activity_path()) |> html_response(200)
      doc = Floki.parse_document!(html)

      title = title_of(html)
      assert title =~ "Activity", "the <title> is #{inspect(title)}"

      h1s = doc |> Floki.find("h1") |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
      assert h1s == ["Activity"], "the h1 is #{inspect(h1s)}"

      gloss = doc |> Floki.find("h1 + p") |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
      assert gloss == [@gloss], "the paragraph under the h1 is #{inspect(gloss)}"

      # The nav names the screen Activity in both layouts and still points at the same
      # route: the label changed, the path did not.
      nav_links =
        doc
        |> Floki.find("[data-testid=surface-nav-scope-items] a")
        |> Enum.filter(fn link ->
          link |> Floki.attribute("href") |> Enum.any?(&String.contains?(&1, "view=deliveries"))
        end)

      assert length(nav_links) >= 2, "the Activity nav link is missing from a layout"

      for link <- nav_links do
        text = link |> Floki.text() |> String.replace(~r/\s+/, " ") |> String.trim()
        assert text == "Activity", "a nav link reads #{inspect(text)}"
      end

      # The description a screen reader hears for the scope group is built from the labels.
      assert [description | _] =
               doc
               |> Floki.find("[data-testid=surface-nav-scope-description]")
               |> Enum.map(&(&1 |> Floki.text() |> String.trim()))

      assert description =~ "Activity"
      refute description =~ ~r/deliveries/i
    end

    test "the overview keeps its own name and an Admin document title", %{conn: conn} do
      html = conn |> dead_get(overview_path()) |> html_response(200)
      doc = Floki.parse_document!(html)

      assert title_of(html) =~ "Admin"
      assert doc |> Floki.find("h1") |> Floki.text() |> String.trim() == "Email health"
    end

    test "routes, ids and the nav key keep their old names (gloss, don't rename)", %{conn: conn} do
      html = conn |> dead_get(activity_path()) |> html_response(200)

      # The old word is still the URL and the test id: only the screen text moved.
      assert html =~ "view=deliveries"
      assert html =~ ~s(data-testid="operator-deliveries-list-card")
    end
  end

  # -- the words scan ---------------------------------------------------------------

  describe "words scan over every registered state (D-11, D-18)" do
    test "no registered state shows Deliveries, operator or tenant as a word", %{conn: conn} do
      scan = scan_all_worlds(conn)

      # Non-vacuity: Preview (3), the Activity pages and Quick views and details over the
      # status grid (51), the nine journey histories (18), the replay modal, the 101-event
      # timeline and the Inbound list and records (15) are 89 states today.
      assert scan.read >= 85, "the scan read #{scan.read} states, floor is 85"
      assert scan.read_text >= 100_000, "the scan read #{scan.read_text} bytes of page text"

      report_inventory(scan)
      assert_none(scan.hits)
    end
  end

  describe "states the registry does not carry (BRADM-03, BRADM-04, D-11)" do
    test "the Activity list with no rows and with filters matching nothing says Activity",
         %{conn: conn} do
      OperatorFixtures.reset!()

      truly =
        scan_extra(
          conn,
          "Activity with no rows",
          activity_path(),
          "[data-testid=operator-empty-truly]"
        )

      assert_none(truly.hits)
      assert truly.text =~ "No activity in this time window"
      assert truly.text =~ "No emails have been recorded for this Account"

      OperatorFixtures.seed_phase182_journey!()

      filtered =
        scan_extra(
          conn,
          "Activity with filters matching nothing",
          activity_path(%{"search" => "zz-no-such-address@example.com"}),
          "[data-testid=operator-empty-filtered]"
        )

      assert_none(filtered.hits)
      assert filtered.text =~ "No activity matches the current filters"

      beyond =
        scan_extra(
          conn,
          "Activity beyond the last page",
          activity_path(%{"page" => "99"}),
          "[data-testid=data-state-empty]"
        )

      assert_none(beyond.hits)
      assert beyond.text =~ "No activity on this page"

      # The old word is not what a reader sees in any of the three.
      for page <- [truly, filtered, beyond], do: refute(page.text =~ ~r/deliveries/i)
    end

    test "a delivery link that does not resolve says Return to Activity", %{conn: conn} do
      OperatorFixtures.seed_phase182_journey!()
      unknown = Ecto.UUID.generate()

      for {label, delivery_id} <- [{"invalid", "not-a-uuid"}, {"unknown", unknown}],
          {mode, extra} <- [{"quick view", %{}}, {"full detail", %{"full" => "1"}}] do
        page =
          scan_extra(
            conn,
            "#{label} delivery link, #{mode}",
            activity_path(Map.merge(%{"delivery_id" => delivery_id}, extra)),
            nil
          )

        assert_none(page.hits)
        assert page.text =~ "Return to Activity"
      end
    end

    test "no Account selected reads with Account and no operator word", %{conn: conn} do
      # Two Accounts, none chosen: the selector every surface shows.
      selector =
        render_component(&Shell.tenant_selector/1,
          state: :select_required,
          tenant_options: [
            %{id: "acct-a", label: "Acme Support"},
            %{id: "acct-b", label: "Beacon"}
          ],
          current_uri: "/ops/mail"
        )

      assert_none(scan_html("tenant selector, two Accounts", selector, nil))
      text = ScreenRegistry.visible_text(selector)
      assert text =~ "Choose an Account"
      assert text =~ "Select an Account to see its activity."

      # No Account has activity: the empty selector.
      none =
        render_component(&Shell.tenant_selector/1,
          state: :none,
          tenant_options: [],
          current_uri: "/ops/mail"
        )

      assert_none(scan_html("tenant selector, no Accounts", none, nil))
      assert ScreenRegistry.visible_text(none) =~ "No Accounts with mail activity"

      # One Account, the bare overview URL: the card that points at Activity.
      OperatorFixtures.seed_phase182_journey!()
      html = conn |> operator_conn() |> dead_get("/ops/mail") |> html_response(200)
      assert_none(scan_html("bare overview, one Account", html, title_of(html)))
      text = ScreenRegistry.visible_text(html)
      assert text =~ "Select an Account to see its activity."
      assert text =~ "Go to Activity"
    end

    test "the Inbound list and its denial sentence say admin account, not operator" do
      # The Inbound list's own no-Account copy (inbound/records_list.ex) is a component
      # sentence; render it the way the screen does.
      html =
        render_component(&MailglassAdmin.Inbound.RecordsList.records_list/1,
          records: [],
          empty_state: :no_tenant,
          data_state: :empty,
          page_meta: %{
            total_count: 0,
            page: 1,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      assert_none(scan_html("inbound no Account", html, nil))
      assert ScreenRegistry.visible_text(html) =~ "Select an Account to see its inbound messages."

      # The default denial an Inbound replay shows when the adopter's auth names no message.
      socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, operator_actor: nil}}
      assert {:error, {:auth, message}} = DestructiveAction.authorize(socket, DenyAdapter, %{})
      assert_none(scan_text("default denial", message))
      assert message =~ "admin account"
    end
  end

  describe "Preview return link (BRADM-03, D-11)" do
    test "a return from Activity reads Back to Activity and the page carries no plural word",
         %{conn: conn} do
      path =
        "/dev/mail?" <>
          URI.encode_query(%{"return_surface" => "deliveries", "return_tenant_id" => @tenant_id})

      view = mount(conn, path)

      assert has_element?(view, ~s([data-testid="preview-return-link"]), "Back to Activity")
      html = render(view)
      assert_none(scan_html("Preview with a return from Activity", html, nil))
      refute ScreenRegistry.visible_text(html) =~ ~r/deliveries/i

      # The three labels come from the closed set, one per surface.
      for {surface, label} <- [
            {"overview", "Back to Health"},
            {"deliveries", "Back to Activity"},
            {"inbound", "Back to Inbound"}
          ] do
        assert ReturnContext.back_label(surface) == label
      end
    end
  end

  describe "retired words stay out of the source (BRADM-03, BRADM-04)" do
    test "no lib string says the old screen word, the operator sentences or the old tiles" do
      sources = lib_sources()

      # Floor: the scan read every lib file, not a handful.
      assert map_size(sources) >= 60, "read #{map_size(sources)} lib files"

      assert_none(retired_violations(sources))
    end

    test "the retired-phrase detector flags each retired phrase and spares the new words" do
      for phrase <- retired_phrases() do
        found = retired_in("planted.ex", ~s|def copy, do: "#{phrase}"|)
        assert found != [], "the detector missed #{inspect(phrase)}"
      end

      for clean <- [
            "Back to Activity",
            "Return to Activity",
            "this admin account",
            "Failed emails"
          ] do
        assert retired_in("clean.ex", ~s|def copy, do: "#{clean}"|) == [], clean
      end

      # A comment or a doc names the old word freely.
      assert retired_in("doc.ex", "# Back to Deliveries was the old label") == []
    end
  end

  # -- detectors have teeth ------------------------------------------------------------

  # -- the orphan sentence (Task 3, D-12) -----------------------------------------------------

  describe "the provider-report sentence (BRADM-05, D-12)" do
    test "label/1 is exact for 0, 1, 2, 11 and 1000, with no grouping or abbreviation" do
      assert OrphanCount.label(0) == "0 provider reports match no email"
      assert OrphanCount.label(1) == "1 provider report matches no email"
      assert OrphanCount.label(2) == "2 provider reports match no email"
      assert OrphanCount.label(11) == "11 provider reports match no email"
      assert OrphanCount.label(1000) == "1000 provider reports match no email"
    end

    test "a negative, fractional or missing count raises instead of inventing a sentence" do
      for bad <- [-1, 1.5, 1.0, nil, "3", :three] do
        assert_raise FunctionClauseError, fn -> OrphanCount.label(bad) end
      end
    end

    test "the Support cards read the sentence for one, many, none and unknown counts" do
      one = support_cards_html(1, 2)
      assert ScreenRegistry.visible_text(one) =~ "1 provider report matches no email"
      refute ScreenRegistry.visible_text(one) =~ "1 provider reports"

      many = support_cards_html(5, 2)
      assert ScreenRegistry.visible_text(many) =~ "5 provider reports match no email"

      none = support_cards_html(0, 0)

      assert ScreenRegistry.visible_text(none) =~
               "0 provider reports match no email in this window"

      refute has_card?(none, "support-card-orphan-backlog-tier1")

      unknown = support_cards_html(nil, 0)

      assert ScreenRegistry.visible_text(unknown) =~
               "Provider reports that match no email are unavailable"

      for html <- [one, many, none, unknown] do
        assert_none(scan_html("support cards", html, nil))
        refute ScreenRegistry.visible_text(html) =~ ~r/unmatched|orphan/i
      end

      # The reconciliation count has its own label, not the sentence.
      assert ScreenRegistry.visible_text(many) =~ "Provider reports still matching no email"
    end
  end

  # -- the mailer (Task 3, D-13) -----------------------------------------------------------------

  describe "the mailer on Full detail and in the list (BRADM-05, D-13)" do
    test "a seeded Module.function reads as its function and a module alone as its leaf",
         %{conn: conn} do
      journey = OperatorFixtures.seed_phase182_journey!()

      cases = [
        {:sent_no_report, "Password reset",
         "MailglassAdmin.Fixtures.AccountMailer.password_reset"},
        {:bounce, "Account mailer", "MailglassAdmin.Fixtures.AccountMailer"}
      ]

      for {case_id, name, identity} <- cases do
        view = mount(operator_conn(conn), detail_path(journey.ids[case_id]))
        html = render(view)

        assert mailer_row_violations(html, name, identity) == [], "#{case_id}"
        assert_none(scan_html("detail #{case_id}", html, nil))

        # The Mailer row sits in the field grid, not in the collapsed Technical details,
        # and the old Mailable row is gone from them.
        assert has_element?(view, "[data-testid=operator-detail-mailer]")

        refute has_element?(
                 view,
                 "#delivery-detail-technical [data-testid=operator-detail-mailer]"
               )

        refute has_element?(view, "#delivery-detail-mailable")
      end
    end

    # Core persists `inspect(rendered.mailable)`, so a message built without a mailable is
    # stored as the text "nil". That is a missing mailer, not one named Nil (WR-03).
    test "a nil, blank or persisted-nil mailable renders no mailer row and no invented name" do
      for mailable <- [nil, "", "   ", "\n", "...", "nil", " nil\n"] do
        html =
          render_component(&DetailHeader.detail_header/1, delivery: row(%{mailable: mailable}))

        refute html =~ "operator-detail-mailer", "mailable #{inspect(mailable)} drew a row"
        refute ScreenRegistry.visible_text(html) =~ "Mailer"
        refute html =~ "delivery-detail-mailer"
      end
    end

    test "a hostile stored mailable is escaped in the name, the tooltip and the visible identity (T-182-10)" do
      hostile = "<img src=x onerror=alert(1)>.Mailer<script>alert(2)</script>"

      html = render_component(&DetailHeader.detail_header/1, delivery: row(%{mailable: hostile}))
      doc = Floki.parse_fragment!(html)

      # Text, not markup: no element the stored value could have opened exists.
      assert Floki.find(doc, "img") == []
      assert Floki.find(doc, "script") == []
      refute html =~ "<img"
      refute html =~ "<script"

      [row] = Floki.find(doc, "[data-testid=operator-detail-mailer]")
      assert Floki.text(row) =~ "<img src=x onerror=alert(1)>"
    end

    test "list rows show the plain name in both layouts, and nothing for a nil mailable",
         %{conn: conn} do
      journey = OperatorFixtures.seed_phase182_journey!()
      view = mount(operator_conn(conn), activity_path())

      names =
        view
        |> render()
        |> Floki.parse_document!()
        |> Floki.find("[data-testid=operator-delivery-mailer]")
        |> Enum.map(&(&1 |> Floki.text() |> String.trim()))

      # Nine rows in the table and nine cards, each with its mailer.
      assert length(names) == 2 * map_size(journey.ids)
      assert Enum.sort(Enum.uniq(names)) == ["Account mailer", "Password reset"]

      rows = [
        row(%{mailable: nil}),
        row(%{id: "row-2", mailable: "   "}),
        row(%{id: "row-3", mailable: "nil"})
      ]

      html =
        render_component(&DeliveriesList.deliveries_list/1,
          deliveries: rows,
          page_meta: %{
            total_count: 3,
            page: 1,
            total_pages: 1,
            has_previous?: false,
            has_next?: false
          }
        )

      refute html =~ "operator-delivery-mailer"
    end

    test "no element in the Mailer row carries a title, and the identity wraps", %{conn: conn} do
      journey = OperatorFixtures.seed_phase182_journey!()
      html = conn |> operator_conn() |> mount(detail_path(journey.ids.bounce)) |> render()

      [row] =
        html |> Floki.parse_document!() |> Floki.find("[data-testid=operator-detail-mailer]")

      assert Floki.find(row, "[title]") == []
      assert Floki.attribute(row, "[title]", "title") == []

      [identity] = Floki.find(row, "[data-testid=operator-detail-mailer-identity]")
      assert "break-words" in class_tokens(identity)
      assert "mono" in class_tokens(identity)
    end
  end

  describe "detectors have teeth (fail-first proof)" do
    test "each detector flags its planted word, in any case and with an apostrophe" do
      for planted <- ["Deliveries", "deliveries pagination", "All DELIVERIES", "no deliveries"] do
        assert :deliveries_word in rules(scan_text("planted", planted)), planted
      end

      for planted <- ["Operator", "operator's", "OPERATOR", "operators", "operator’s"] do
        assert :operator_word in rules(scan_text("planted", planted)), planted
      end

      for planted <- ["Tenant", "tenants", "TENANT"] do
        assert :tenant_word in rules(scan_text("planted", planted)), planted
      end
    end

    test "the singular domain noun and code identifiers are not flagged" do
      for clean <- [
            "delivery",
            "Delivery timeline",
            "one row per delivery",
            "tenant_id",
            "Account maps to tenant_id in code",
            "deliveries_path",
            "Undelivered",
            "Account browser-tenant",
            "tenant-a",
            "operator-detail"
          ] do
        assert scan_text("clean", clean) == [], "#{inspect(clean)} must not be flagged"
      end
    end

    test "a word inside a script is not page text, and a word in an attribute is" do
      script =
        ~s(<main><script>var deliveries_path = "Deliveries operator tenant";</script>ok</main>)

      assert scan_html("script", script, nil) == []

      for {html, rule} <- [
            {~s(<nav aria-label="Deliveries pagination">x</nav>), :deliveries_word},
            {~s(<a href="#" title="Operator">x</a>), :operator_word},
            {~s(<img alt="Tenant logo" src="x">), :tenant_word},
            {~s(<input placeholder="Search deliveries">), :deliveries_word}
          ] do
        assert rule in rules(scan_html("attribute", html, nil)), html
      end
    end

    test "a word in the document <title> is flagged" do
      assert :deliveries_word in rules(scan_html("title", "<main>ok</main>", "Deliveries"))

      assert :operator_word in rules(
               scan_html("title", "<main>ok</main>", "mailglass — Operator")
             )

      assert scan_html("title", "<main>ok</main>", "mailglass — Activity") == []
    end

    test "the mailer row detector flags each way the row can fail the reader" do
      name = "Password reset"
      identity = "MyApp.AccountMailer.password_reset"
      good = mailer_html(name, identity)
      assert mailer_row_violations(good, name, identity) == []

      mutants = [
        {:identity_not_visible,
         String.replace(
           good,
           ~r{<span data-testid="operator-detail-mailer-identity".*?</span>}s,
           ""
         )},
        {:trigger_titled, String.replace(good, "<button ", ~s(<button title="#{identity}" ))},
        {:row_titled, String.replace(good, "<dd ", ~s(<dd title="x" ))},
        {:identity_not_wrapped, String.replace(good, "break-words", "truncate")},
        {:identity_not_mono, String.replace(good, "mono block", "block")},
        {:identity_hidden,
         String.replace(
           good,
           ~s(data-testid="operator-detail-mailer-identity"),
           ~s(data-testid="operator-detail-mailer-identity" hidden)
         )},
        {:identity_hidden, String.replace(good, "mono block", "mono sr-only")},
        {:tooltip_differs, Regex.replace(~r/(role="tooltip"[^>]*>)[^<]*/, good, "\\1other")},
        {:description_missing,
         String.replace(
           good,
           ~s(<span id="delivery-detail-mailer" class="sr-only">#{identity}</span>),
           ""
         )},
        {:trigger_text_differs,
         Regex.replace(~r/>\s*#{Regex.escape(name)}\s*</, good, ">Mailer<", global: false)},
        {:row_in_technical_details, ~s(<div id="delivery-detail-technical">#{good}</div>)}
      ]

      for {rule, html} <- mutants do
        assert rule in mailer_row_violations(html, name, identity),
               "the detector missed #{rule}: #{inspect(mailer_row_violations(html, name, identity))}"
      end

      assert mailer_row_violations("<div></div>", name, identity) == [:row_missing]
    end

    test "hover and screen-reader text count as words a reader meets" do
      tooltip = ~s(<span role="tooltip">Deliveries with a recorded event</span>)
      assert :deliveries_word in rules(scan_html("tooltip", tooltip, nil))

      sr_only = ~s(<span class="sr-only">Select an Account to see scoped operator data.</span>)
      assert :operator_word in rules(scan_html("sr-only", sr_only, nil))
    end

    test "a provider's raw time string is not page text mailglass wrote" do
      raw = ~s(<span data-raw-provider-time>operator deliveries tenant</span>)
      assert scan_html("raw", raw, nil) == []
    end
  end

  # -- reading a page ---------------------------------------------------------------------

  # Every hit for one page: the document `<title>` (when there is one), the page text and
  # the word-bearing attributes, each run through the three detectors.
  defp scan_html(label, html, title) do
    doc = Floki.parse_document!(html)

    attribute_values =
      for attribute <- @word_attributes,
          value <- doc |> Floki.find("[#{attribute}]") |> Floki.attribute(attribute),
          do: value

    [title | [words_text(doc) | attribute_values]]
    |> Enum.reject(&is_nil/1)
    |> Enum.flat_map(&scan_text(label, &1))
    |> Enum.uniq()
  end

  # The text a reader or a screen reader meets. Unlike `ScreenRegistry.visible_text/1`, hover
  # tooltips stay in: help text is the product's words too. Scripts and styles do not, and a
  # provider's raw time string is the provider's text, not mailglass's.
  defp words_text(doc) do
    doc
    |> Floki.filter_out("script")
    |> Floki.filter_out("style")
    |> Floki.filter_out("[data-raw-provider-time]")
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # The pure detector: `[%{rule, state, text}]` for one string, `text` being the matched
  # word with a little context so a hit can be found in the source.
  defp scan_text(label, text) when is_binary(text) do
    for {rule, regex} <- @rules,
        [{start, _length}] <- Regex.scan(regex, text, return: :index) do
      from = max(String.length(binary_part(text, 0, start)) - 30, 0)
      %{rule: rule, state: label, text: String.slice(text, from, 70)}
    end
  end

  defp rules(hits), do: hits |> Enum.map(& &1.rule) |> Enum.uniq()

  # -- mounting -----------------------------------------------------------------------------

  # Seeds each world the registry knows, one at a time (every seed resets the tables), reads
  # every state of it and returns `%{read: states, read_text: bytes, hits: [...]}`.
  defp scan_all_worlds(conn) do
    worlds = [
      fn -> %{static: true} end,
      fn -> %{grid: OperatorFixtures.seed_phase182_status_grid!()} end,
      fn -> %{journey: OperatorFixtures.seed_phase182_journey!()} end,
      fn -> %{replay: OperatorFixtures.seed_phase169_replay!("one")} end,
      fn -> %{timeline: OperatorFixtures.seed_phase169_timeline_101!()} end,
      fn -> %{inbound: seed_inbound_world!()} end
    ]

    Enum.reduce(worlds, %{read: 0, read_text: 0, hits: []}, fn seed, acc ->
      pages = for state <- ScreenRegistry.states(seed.()), do: scan_state(conn, state)

      %{
        read: acc.read + length(pages),
        read_text: acc.read_text + (pages |> Enum.map(& &1.text_bytes) |> Enum.sum()),
        hits: acc.hits ++ Enum.flat_map(pages, & &1.hits)
      }
    end)
  end

  defp scan_state(conn, state) do
    html = mount_html(conn, state)
    title = document_title(conn, state, html)

    %{
      hits: scan_html(state.label, html, title),
      text_bytes: byte_size(words_text(Floki.parse_document!(html)))
    }
  end

  # A state the registry does not carry: mount `path` (an Operator path), optionally wait
  # for `expect`, and read it like any registered state.
  defp scan_extra(conn, label, path, expect) do
    state = %{
      label: label,
      kind: :extra,
      route: {OperatorLive, :index},
      path: path,
      mount: :live,
      hooks: [],
      expect: expect
    }

    html = mount_html(conn, state)
    title = document_title(conn, state, html)

    %{
      hits: scan_html(label, html, title),
      text: ScreenRegistry.visible_text(html)
    }
  end

  defp mount_html(conn, state) do
    conn = if public?(state), do: conn, else: operator_conn(conn)

    case state.mount do
      :dead ->
        conn |> dead_get(state.path) |> html_response(200)

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

  # A LiveView's connected render has no root layout, so the `<title>` comes from a dead
  # render of the same path (following the redirect a screen may normalise to).
  defp document_title(_conn, %{mount: :dead}, html), do: title_of(html)

  defp document_title(conn, state, _html) do
    conn = if public?(state), do: conn, else: operator_conn(conn)

    conn
    |> dead_render(state.path, 3)
    |> title_of()
  end

  # The test endpoint carries no body parser, so a dead render reads its params from the
  # `params` argument of `get/3`, not from the query string of the path.
  defp dead_get(conn, path) do
    %URI{path: base, query: query} = URI.parse(path)
    get(conn, base, URI.decode_query(query || ""))
  end

  defp dead_render(conn, path, hops) do
    resp = dead_get(conn, path)

    case resp.status do
      status when status in [301, 302] and hops > 0 ->
        dead_render(conn, redirected_to(resp, status), hops - 1)

      200 ->
        resp.resp_body

      status ->
        flunk("#{path} answered #{status} to a dead render")
    end
  end

  defp title_of(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("title")
    |> Floki.text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp public?(state),
    do: state.route in [{PreviewLive, :index}, {PreviewLive, :show}, {GalleryLive, :index}]

  # Some screens answer with a redirect that normalises the URL (the Preview adds a width).
  # Follow it, as a browser does, so the scan reads the screen the reader lands on.
  defp mount(conn, path, hops \\ 3) do
    case live(conn, path) do
      {:ok, view, _html} ->
        view

      {:error, {kind, %{to: to}}}
      when kind in [:redirect, :live_redirect, :live_patch] and hops > 0 ->
        mount(conn, to, hops - 1)
    end
  end

  # One record per execution outcome, so the Inbound list and every kind of detail (and the
  # sentences each carries) are read.
  defp seed_inbound_world! do
    OperatorFixtures.reset!()

    record_ids =
      for outcome <- ExecutionRun.__outcomes__() do
        seed_inbound!(outcome)
      end

    %{record_ids: record_ids, tenant_id: @tenant_id}
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

  defp activity_path(extra \\ %{}) do
    query = Map.merge(%{"view" => "deliveries", "tenant_id" => @tenant_id}, extra)
    "/ops/mail?" <> URI.encode_query(query)
  end

  defp overview_path, do: "/ops/mail?" <> URI.encode_query(%{"tenant_id" => @tenant_id})

  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
  end

  # -- Task 3 helpers ------------------------------------------------------------------------------

  defp detail_path(id), do: activity_path(%{"delivery_id" => id, "full" => "1"})

  defp row(attrs) do
    Map.merge(
      %{
        id: "row-1",
        tenant_id: @tenant_id,
        recipient: "reader@example.com",
        subject: "Reset your password",
        status: :sent,
        provider: "postmark",
        stream: :transactional,
        mailable: "MyApp.AccountMailer",
        provider_message_id: nil,
        last_event_type: :sent,
        last_event_at: @at,
        inserted_at: @at,
        delivery_confirmed: false,
        bounced_at: nil,
        terminal: nil,
        delivered_at: nil,
        complained_at: nil,
        suppressed_at: nil
      },
      attrs
    )
  end

  defp support_cards_html(orphan_count, still_unmatched) do
    render_component(&SupportCards.support_cards/1,
      support_summary: %{
        failed_ingest: %{count: 0, latest: nil},
        orphan_backlog: %{count: orphan_count, oldest: nil},
        replay_outcomes: %{counts: %{failed: 0, noop: 0, replayed: 0}, latest: nil},
        reconcile_facts: %{
          reconciled_count: 1,
          still_unmatched_count: still_unmatched,
          latest_reconciled: nil
        }
      },
      support_state: %{focused_card: nil, drilldown_banner: nil},
      suppression_count: 0
    )
  end

  defp has_card?(html, testid),
    do: html |> Floki.parse_fragment!() |> Floki.find(~s([data-testid="#{testid}"])) != []

  defp class_tokens(node),
    do: node |> Floki.attribute("class") |> Enum.flat_map(&String.split/1)

  # The pure detector for the Mailer row of Full detail: `[]` when the row is right, else the
  # rules it breaks. Right means: a trigger whose visible text is the plain name, a hidden
  # description (the target of `aria-describedby`) and a tooltip that both hold the stored
  # identity, the identity also printed in full in a `mono` element that wraps, no `title`
  # anywhere in the row, and the row outside the collapsed Technical details.
  defp mailer_row_violations(html, name, identity) do
    doc = Floki.parse_fragment!(html)

    case Floki.find(doc, "[data-testid=operator-detail-mailer]") do
      [] ->
        [:row_missing]

      [row] ->
        triggers = Floki.find(row, "button[aria-describedby]")
        described_by = triggers |> Floki.attribute("aria-describedby") |> List.first()
        tooltip = row |> Floki.find("[role=tooltip]") |> text_of()

        description =
          if described_by, do: doc |> Floki.find("[id=\"#{described_by}\"]") |> text_of()

        visible = Floki.find(row, "[data-testid=operator-detail-mailer-identity]")

        checks = [
          {:row_in_technical_details,
           Floki.find(doc, "#delivery-detail-technical [data-testid=operator-detail-mailer]") !=
             []},
          {:trigger_missing, length(triggers) != 1},
          {:trigger_text_differs, triggers != [] and text_of(triggers) != name},
          {:trigger_titled,
           Floki.find(triggers, "[title]") != [] or Floki.attribute(triggers, "title") != []},
          {:row_titled, Floki.find(row, "[title]") != []},
          {:description_missing, is_nil(described_by) or description != identity},
          {:tooltip_differs, tooltip != identity},
          {:identity_not_visible, visible == [] or text_of(visible) != identity},
          {:identity_not_wrapped,
           visible != [] and "break-words" not in class_tokens(hd(visible))},
          {:identity_not_mono, visible != [] and "mono" not in class_tokens(hd(visible))},
          {:identity_hidden, visible != [] and hidden?(hd(visible))}
        ]

        for {rule, true} <- checks, do: rule

      _several ->
        [:row_duplicated]
    end
  end

  # Hidden from a reader or a screen reader: the `hidden` attribute, `aria-hidden`, an inline
  # `display:none`, or the `hidden` and `sr-only` utility classes.
  defp hidden?(node) do
    tokens = class_tokens(node)

    Floki.attribute(node, "hidden") != [] or
      Floki.attribute(node, "aria-hidden") == ["true"] or
      Enum.any?(Floki.attribute(node, "style"), &(&1 =~ ~r/display\s*:\s*none/)) or
      "hidden" in tokens or "sr-only" in tokens
  end

  defp text_of(nodes), do: nodes |> Floki.text() |> String.replace(~r/\s+/, " ") |> String.trim()

  # A real Mailer row, the way DetailHeader draws it, for the detector's planted mutants.
  defp mailer_html(name, identity) do
    render_component(&DetailHeader.detail_header/1, delivery: row(%{mailable: identity}))
    |> Floki.parse_fragment!()
    |> Floki.find("[data-testid=operator-detail-mailer]")
    |> Floki.raw_html()
    |> then(fn html ->
      assert text_of(Floki.parse_fragment!(html) |> Floki.find("button")) == name
      html
    end)
  end

  # -- retired words in the source ------------------------------------------------------------

  # Sentences and labels this plan retired. A lib string that says one of them again is a
  # regression the render scan might not reach (a denial sentence only shows when auth
  # denies). Comments and docs may name the old word, so they are blanked first.
  defp retired_phrases do
    [
      "Back to Deliveries",
      "Back to deliveries",
      "Go to Deliveries",
      "Return to deliveries",
      "return to deliveries",
      "Deliveries pagination",
      "scoped operator data",
      "current operator",
      "Failed deliveries",
      "Bounced deliveries",
      "Rejected deliveries",
      "Delayed deliveries",
      "No deliveries",
      "Unmatched events",
      "Unmatched Events",
      "Unmatched webhook evidence",
      "Still unmatched",
      "Oldest unmatched"
    ]
  end

  defp retired_violations(sources) do
    Enum.flat_map(sources, fn {rel, source} -> retired_in(rel, source) end)
  end

  defp retired_in(rel, source) do
    code =
      source
      |> String.split("\n")
      |> Enum.reject(&(&1 |> String.trim_leading() |> String.starts_with?("#")))
      |> Enum.join("\n")

    for phrase <- retired_phrases(), String.contains?(code, phrase) do
      %{rule: :retired_phrase, state: rel, text: phrase}
    end
  end

  defp lib_sources do
    root = Path.expand("../../lib", __DIR__)

    for path <- Path.wildcard(Path.join(root, "**/*.{ex,heex}")), into: %{} do
      {Path.relative_to(path, root), File.read!(path)}
    end
  end

  # -- reporting and failures ---------------------------------------------------------------

  defp assert_none([]), do: :ok

  defp assert_none(hits) do
    lines =
      hits
      |> Enum.uniq_by(&{&1.rule, &1.text})
      |> Enum.take(25)
      |> Enum.map_join("\n", fn hit ->
        "  #{hit.rule} in #{inspect(hit.state)}: #{inspect(hit.text)}\n    fix: #{fix(hit.rule)}"
      end)

    flunk("#{length(hits)} word violation(s):\n#{lines}")
  end

  defp fix(:deliveries_word),
    do: "the screen is called Activity; a row is still a delivery (singular), a list is emails"

  defp fix(:operator_word), do: "say Admin on screen; Operator stays in code and docs"
  defp fix(:tenant_word), do: "say Account on screen; tenant_id stays in code and URLs"

  defp fix(:retired_phrase),
    do: "this sentence was reworded; use the Activity, Admin and Account words"

  # Printed only when asked, so a plan summary can record the inventory.
  defp report_inventory(%{read: read, hits: hits}) do
    if System.get_env("PHASE182_REPORT") do
      IO.puts("PHASE182 WORDS read #{read} states, #{length(hits)} hits")

      hits
      |> Enum.group_by(&{&1.rule, &1.text})
      |> Enum.sort_by(fn {{rule, text}, _} -> {rule, text} end)
      |> Enum.each(fn {{rule, text}, group} ->
        IO.puts("PHASE182 WORDS #{rule} x#{length(group)} #{inspect(text)}")
      end)
    end
  end
end
