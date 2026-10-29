defmodule MailglassAdmin.Phase177ProhibitionContractTest do
  @moduledoc """
  Machine-checked form of the Phase 177 must-NOT prohibitions (UXF-09, UXF-10,
  OUTUX-06; D-19, D-52).

  Each prohibition reduces to a forbidden control, a forbidden value, a
  forbidden claim or a forbidden structure on a closed set of rendered states,
  so this file enumerates those states and refutes the violation. Every rule is
  a detector that returns a violation list: `[]` means clean. The "detectors
  have teeth" block feeds each detector a known violation and a known clean
  fixture, so a pass here is not vacuous, and each rule was additionally proven
  red by a temporary source mutation (recorded in the plan SUMMARY) and
  reverted.

  Positive behavior (Back round trip, scope group order, Health population)
  stays in the LiveView and browser suites; this file only owns the
  prohibitions.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @moduletag :phase177

  alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]
  @preview_base "/dev/mail"
  @scenario_base "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"

  describe "detectors have teeth (fail-first proof)" do
    test "the P1 detector rejects an Account switcher, an Account details and a disabled control" do
      switcher = ~s(<nav><div data-testid="operator-account-switcher">Acme</div></nav>)

      details =
        ~s(<div data-testid="admin-shell-sidebar"><details><summary>Account</summary></details></div>)

      select = ~s(<div data-testid="admin-shell-topbar"><select name="tenant"></select></div>)

      disabled =
        ~s(<div data-testid="admin-shell-topbar"><button disabled aria-label="Account">A</button></div>)

      for fragment <- [switcher, details, select, disabled] do
        assert preview_account_control_violations(fragment) != [],
               "P1 detector missed #{inspect(fragment)}"
      end
    end

    test "the P1 detector accepts the static scope label" do
      clean = """
      <div data-testid="admin-shell-sidebar">
        <nav data-testid="surface-nav-sidebar">
          <p data-testid="preview-scope-label">Scoped to an Account</p>
        </nav>
      </div>
      """

      assert preview_account_control_violations(clean) == []
    end
  end

  describe "P1 Preview renders no Account control" do
    test "direct entry renders no Account control", %{conn: conn} do
      {:ok, _view, html} = live(preview_conn(conn), @scenario_base <> "?width=768")

      assert preview_account_control_violations(html) == []

      assert Floki.find(Floki.parse_document!(html), ~s([data-testid="preview-scope-label"])) !=
               []
    end

    test "a valid return context renders no Account control", %{conn: conn} do
      conn = preview_conn(conn)

      assert {:error, {:redirect, %{to: to}}} =
               live(conn, @preview_base <> "?return_surface=overview&return_tenant_id=tenant-b")

      assert to =~ "return_tenant_id=tenant-b"

      {:ok, _view, html} = live(conn, to)

      assert preview_account_control_violations(html) == []

      assert Floki.find(Floki.parse_document!(html), ~s([data-testid="preview-return-link"])) !=
               []
    end

    test "a tampered return context renders no Account control", %{conn: conn} do
      conn = preview_conn(conn)

      {:error, {:redirect, %{to: to}}} =
        live(conn, @preview_base <> "?return_surface=https://evil.example&return_tenant_id=x")

      {:ok, _view, html} = live(conn, to)

      assert preview_account_control_violations(html) == []
    end
  end

  # -- detectors ---------------------------------------------------------------

  # P1: Preview reads no Account data, so its chrome (topbar, both nav copies,
  # page header) holds no Account control of any kind: no `operator-account*`
  # testid anywhere on the page, no `<details>` or `<select>` in the chrome, and
  # no disabled control that names an Account.
  defp preview_account_control_violations(html) do
    doc = Floki.parse_document!(html)

    testid_hits =
      for node <- Floki.find(doc, ~s([data-testid^="operator-account"])) do
        "Account control #{inspect(testid(node))} rendered on Preview"
      end

    chrome = chrome_nodes(doc)

    picker_hits =
      for tag <- ["details", "select"], _node <- Floki.find(chrome, tag) do
        "<#{tag}> rendered in Preview chrome"
      end

    disabled_hits =
      for node <- Floki.find(chrome, "[disabled], [aria-disabled='true']"),
          node |> Floki.raw_html() |> String.downcase() |> String.contains?("account") do
        "disabled Account control rendered in Preview chrome"
      end

    testid_hits ++ picker_hits ++ disabled_hits
  end

  # -- rendering and parsing helpers -------------------------------------------

  # The Preview chrome: topbar, sidebar, mobile nav and page header. The Preview
  # frame and the mailable menu in the page body are authored by adopters and
  # are never part of the chrome.
  defp chrome_nodes(doc) do
    Floki.find(
      doc,
      ~s([data-testid="admin-shell-topbar"], [data-testid="admin-shell-sidebar"], ) <>
        ~s([data-testid="admin-shell-mobile-nav"], [data-testid="admin-shell-page-header"])
    )
  end

  defp testid(node), do: node |> Floki.attribute("data-testid") |> List.first()

  defp preview_conn(conn),
    do: Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
end
