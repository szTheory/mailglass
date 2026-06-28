defmodule MailglassAdmin.VoiceTest do
  @moduledoc """
  RED-by-default coverage for BRAND-01 voice/tone enforcement against the
  rendered PreviewLive HTML — asserts the brand book "clear / exact /
  confident / warm / technical — a thoughtful maintainer" tone by matching
  canonical strings from 05-UI-SPEC §Copywriting Contract and refuting
  banned exclamations ("Oops!", "Whoops", "Uh oh", "Something went wrong").

  Plan 06 renders the PreviewLive HEEx with the exact strings from 05-UI-SPEC
  Component Inventory and Copywriting Contract and turns these RED tests
  green.

  Plan 101-02 extends coverage to all three admin surfaces: Preview, Operator,
  and Inbound. Banned-word assertions run script-stripped to avoid the
  phoenix.mjs "noops" false positive. Flash-only strings are covered by
  source-level grep guards (D-11).
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.Fixtures.{HappyMailer, StubMailer, BrokenMailer}
  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.Shell
  alias MailglassAdmin.TestSupport.OperatorFixtures

  # Data-driven banned-word list (D-09, COPY-LD-09). Each entry is checked
  # case-insensitively against script-stripped HTML on every surface.
  @banned_words ~w[oops whoops "uh oh" "something went wrong"]

  describe "banned exclamations (05-UI-SPEC §Copywriting Contract)" do
    test "are absent from rendered UI", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"mailables" => [HappyMailer]})
      {:ok, _view, html} = live(conn, "/dev/mail")
      # Strip inlined <script>…</script> blocks before checking brand voice.
      # Phoenix inlines phoenix.mjs which contains "noops" (a logger no-op utility).
      # Checking the full HTML produces a false positive on that dep-JS token.
      # The brand-voice rule applies to the rendered UI markup, not embedded scripts.
      # See project memory: voice_test "Oops" is dep-JS noise.
      lower = html |> strip_scripts() |> String.downcase()

      Enum.each(@banned_words, fn word ->
        refute lower =~ word,
               "brand voice: #{inspect(word)} must never appear in admin UI (Preview surface)"
      end)
    end
  end

  describe "canonical brand copy (05-UI-SPEC Copywriting Contract)" do
    test "sidebar + empty state strings appear verbatim", %{conn: conn} do
      conn =
        Plug.Test.init_test_session(conn, %{
          "mailables" => [HappyMailer, StubMailer, BrokenMailer]
        })

      {:ok, _view, html} = live(conn, "/dev/mail")

      # Sidebar heading
      assert html =~ "Mailables"

      # Start page shown when nothing is selected (mailables present)
      assert html =~ "Render a real Message before you send it"

      # Stub-mailable empty-state copy
      assert html =~ "No previews defined"

      # Error-card heading appears ONLY when BrokenMailer is loaded (D-10 generalized copy)
      assert html =~ "This Mailable raised while rendering"
    end

    test "empty-mailables onboarding leads with the brandbook Empty string verbatim", %{
      conn: conn
    } do
      # No mailables in the session -> the empty-mailables onboarding arm renders.
      conn = Plug.Test.init_test_session(conn, %{"mailables" => []})

      {:ok, _view, html} = live(conn, "/dev/mail")

      # Brandbook-canonical Mailable Empty string (brandbook/copy/microcopy.md:17),
      # rendered VERBATIM with the generator name + literal backtick (D-09). Mirror
      # of the operator brandbook-string grep pattern.
      assert html =~ "No mailables discovered yet. Define one with `mix mailglass.gen.mailable`",
             "D-09: empty-mailables onboarding must lead with the brandbook Empty string verbatim"
    end

    test "button labels use verb+noun form", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"mailables" => [HappyMailer]})

      {:ok, _view, html} =
        live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

      assert html =~ "Render preview",
             "primary CTA must be the verb+noun 'Render preview' (not bare 'Render')"

      assert html =~ "Reset assigns",
             "secondary action must be the verb+noun 'Reset assigns' (not bare 'Reset')"
    end
  end

  describe "live reload info log (Plan 06 persistent_term gating)" do
    # LiveReload topic subscription info log fires exactly once per boot.
    # Depends on Plan 06 landing :persistent_term gating from 05-PATTERNS.md
    # §":persistent_term once-per-BEAM gating". Defer assertion until then.
    @tag :skip
    test "LiveReload topic subscription info log fires exactly once per boot" do
      flunk("skipped until Plan 06 lands persistent_term-gated info log")
    end
  end

  describe "Operator surface (/ops/mail)" do
    test "banned words absent from Operator surface", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, "/ops/mail")
      lower = html |> strip_scripts() |> String.downcase()

      Enum.each(@banned_words, fn word ->
        refute lower =~ word,
               "brand voice: #{inspect(word)} must never appear in admin UI (Operator surface)"
      end)
    end

    test "canonical COPY-LD strings present in Operator surface initial render", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, "/ops/mail?view=deliveries&tenant_id=test-tenant")

      # LD-11: orientation tip — "Delivery never arrived? Start here."
      # Rendered via Shell.orientation_strip surface={:deliveries} in the deliveries branch.
      assert html =~ "Delivery never arrived? Start here.",
             "LD-11: orientation tip must use domain noun Delivery (not Email)"

      # Spot-check: deliveries heading confirming operator surface renders correctly.
      assert html =~ "Deliveries",
             "Operator surface must render the deliveries heading on initial mount"
    end
  end

  describe "Inbound surface (/ops/mail/inbound)" do
    test "banned words absent from Inbound surface", %{conn: conn} do
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, "/ops/mail/inbound")
      lower = html |> strip_scripts() |> String.downcase()

      Enum.each(@banned_words, fn word ->
        refute lower =~ word,
               "brand voice: #{inspect(word)} must never appear in admin UI (Inbound surface)"
      end)
    end

    test "canonical COPY-LD strings present in Inbound surface initial render", %{conn: conn} do
      conn = operator_conn(conn)

      # Mount with a provider filter that can never match — forces the :filtered empty state
      # so the filtered-empty data_state is present in the first render. In no-match the
      # master-detail grid stays, so LD-16 (select prompt) and LD-03 (filtered body) are present.
      {:ok, _view, html} =
        live(conn, "/ops/mail/inbound?tenant_id=voice-test-tenant&provider=no-such-provider")

      # LD-12: orientation tip — inbound surface. The orientation strip is now
      # empty-pane-only (Phase 121 D-04): it no longer renders on this no-match
      # mount, so assert LD-12 against the component directly (the byte-frozen
      # :inbound copy, D-08). HEEx HTML-escapes the apostrophe in "didn't" as &#39;.
      strip_html = render_component(&Shell.orientation_strip/1, surface: :inbound)

      assert strip_html =~ "InboundMessage didn&#39;t route as expected? Inspect the routing trace.",
             "LD-12: orientation tip must use InboundMessage domain noun"

      # LD-16: rendered-pane select prompt (inbound-empty-detail div, always rendered
      # when no record is selected).
      assert html =~
               "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence.",
             "LD-16: no-selection prompt must use InboundMessage and Mailbox domain nouns"

      # LD-03: filtered empty-state body — Phase 113 UI-SPEC updated to "No records match
      # the current filters." (data_state/1 routes through title "No records" + this body).
      assert html =~ "No records match the current filters.",
             "LD-03: filtered empty state must be present (UI-SPEC copy from Phase 113)"
    end
  end

  # Asserts banned exclamations are absent from a script-stripped rendered HTML
  # fragment, mirroring the per-surface @banned_words loop (D-12).
  defp refute_banned_words(html, context) do
    lower = html |> strip_scripts() |> String.downcase()

    Enum.each(@banned_words, fn word ->
      refute lower =~ word,
             "brand voice: #{inspect(word)} must never appear (#{context})"
    end)
  end

  describe "data_state copy (FLOW-04 permission_denied / stale, D-12)" do
    test "deliveries permission_denied: banned-free + locked verbatim present" do
      html =
        render_component(&Components.data_state/1,
          kind: :permission_denied,
          title: "Access restricted",
          body:
            "You do not have access to this tenant's mail operations. " <>
              "Ask an administrator to grant access."
        )

      refute_banned_words(html, "deliveries permission_denied")
      assert html =~ "Access restricted"
      assert html =~ "You do not have access to this tenant&#39;s mail operations."
      # No existence leak: copy never names a tenant id or the missing permission.
      refute html =~ "tenant_id"
    end

    test "inbound permission_denied: banned-free + locked verbatim present" do
      html =
        render_component(&Components.data_state/1,
          kind: :permission_denied,
          title: "Access restricted",
          body:
            "You do not have access to this tenant's inbound routing. " <>
              "Ask an administrator to grant access."
        )

      refute_banned_words(html, "inbound permission_denied")
      assert html =~ "Access restricted"
      assert html =~ "You do not have access to this tenant&#39;s inbound routing."
    end

    test "deliveries stale: banned-free + locked verbatim present" do
      html =
        render_component(&Components.data_state/1,
          kind: :stale,
          title: "Data may be out of date",
          body: "Showing Deliveries as of 14:32. Refresh to load the latest."
        )

      refute_banned_words(html, "deliveries stale")
      assert html =~ "Data may be out of date"
      assert html =~ "Showing Deliveries as of 14:32. Refresh to load the latest."
    end

    test "inbound stale: banned-free + locked verbatim present" do
      html =
        render_component(&Components.data_state/1,
          kind: :stale,
          title: "Data may be out of date",
          body: "Showing InboundMessages as of 14:32. Refresh to load the latest."
        )

      refute_banned_words(html, "inbound stale")
      assert html =~ "Data may be out of date"
      assert html =~ "Showing InboundMessages as of 14:32. Refresh to load the latest."
    end
  end

  describe "tenant failure modes (FLOW-02 D-06 — 0 / 1 / >=2)" do
    test "no tenants exist (0): banned-free + locked verbatim present" do
      html =
        render_component(&Shell.tenant_selector/1,
          state: :none,
          tenant_options: [],
          current_uri: "/ops/mail"
        )

      refute_banned_words(html, "tenant state :none")
      assert html =~ "No tenants available"
      assert html =~ "Send a Message with a tenant_id"
    end

    test "tenant switcher (>=2): banned-free + locked verbatim + per-tenant link" do
      html =
        render_component(&Shell.tenant_selector/1,
          state: :select_required,
          tenant_options: [%{id: "tenant-a", label: "tenant-a"}, %{id: "tenant-b", label: "tenant-b"}],
          current_uri: "/ops/mail"
        )

      refute_banned_words(html, "tenant state :select_required")
      assert html =~ "Select a tenant"
      assert html =~ "inspect its Deliveries and inbound routing"
      # Domain nouns enforced as POSITIVE assertions only (D-12) — never a ban grep.
      assert html =~ "Select tenant", "per-tenant link label must be present"
    end

    test "sole tenant (1): picker testid is ABSENT (auto-select proven, D-06)", %{conn: conn} do
      # Seed exactly one distinct tenant (browser-tenant). deny_reveal?: false omits
      # the second "deny-reveal" inbound tenant, so list_tenants returns one row and
      # mounting without a ?tenant_id= param drives tenant_state -> :auto_select,
      # which renders NO picker.
      OperatorFixtures.seed_browser_scenario!(deny_reveal?: false)
      conn = operator_conn(conn)
      {:ok, _view, html} = live(conn, "/ops/mail")

      refute html =~ ~s(data-testid="tenant-selector"),
             "sole-tenant mount must auto-select and render no tenant picker (D-06)"

      refute_banned_words(html, "sole-tenant auto-select")
    end
  end

  describe "Flash string source guards (action-only strings)" do
    # Flash strings only render after a user action (put_flash/3 in event handlers),
    # so they cannot be asserted against a first-render. Assert at source level (D-11).

    test "inbound replay-success flash uses InboundMessage domain noun" do
      source = File.read!("lib/mailglass_admin/inbound_live.ex")

      assert source =~ "InboundMessage's timeline",
             "LD-13: replay flash must use InboundMessage not generic 'message'"
    end

    test "inbound no-selection flash matches LD-16 locked string" do
      source = File.read!("lib/mailglass_admin/inbound_live.ex")

      assert source =~
               ~s|"Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence."|,
             "LD-16: no-selection put_flash must use the locked LD-16 string"
    end
  end

  # Strips inlined <script>…</script> blocks from HTML before brand-voice checks.
  # Phoenix inlines phoenix.mjs which contains "noops" (a logger no-op utility).
  # Without stripping, the banned-word check produces a false positive on that token.
  # See project memory: voice_test "Oops" is dep-JS noise.
  defp strip_scripts(html) do
    Regex.replace(~r/<script\b[^>]*>.*?<\/script>/si, html, "")
  end

  # Builds an authenticated operator connection using the same session shape as
  # OperatorLive and InboundLive tests (operator Auth gate).
  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => "test-tenant",
      "auth_method" => "password",
      "recent_auth_at" => now
    })
  end
end
