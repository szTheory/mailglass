defmodule MailglassDemoWeb.Phase177NavigationTest do
  @moduledoc """
  Phase 177 UXF-10 / D-07: the demo Preview mount points straight at the
  operator surfaces, and a logged-out operator who follows a Preview return link
  is sent through the demo login and lands on the Account they came from.
  """

  use MailglassDemo.ConnCase, async: false

  @moduletag :phase177

  alias MailglassDemoWeb.AdminAuth

  @fjordline_deliveries "/ops/mail?view=deliveries&tenant_id=fjordline-aps"

  defp login_to(conn) do
    # Reads the login redirect target the way a browser follows it.
    location = redirected_to(conn)
    uri = URI.parse(location)
    assert uri.path == "/demo/login"
    conn |> recycle() |> get(location)
  end

  describe "logged-out deny form (D-07)" do
    test "Phase 177 logged-out /ops/mail redirects to demo login with return_to", %{conn: conn} do
      conn = get(conn, "/ops/mail")

      assert redirected_to(conn) == "/demo/login?return_to=%2Fops%2Fmail"
    end

    test "Phase 177 logged-out Fjordline Deliveries return lands on Fjordline after login", %{
      conn: conn
    } do
      conn = get(conn, @fjordline_deliveries)

      assert redirected_to(conn) ==
               "/demo/login?return_to=" <> URI.encode_www_form(@fjordline_deliveries)

      logged_in = login_to(conn)
      assert redirected_to(logged_in) == @fjordline_deliveries

      landed = logged_in |> recycle() |> get(redirected_to(logged_in))
      {:ok, doc} = landed |> html_response(200) |> Floki.parse_document()

      label = doc |> Floki.find(~s([data-testid="operator-account-label"])) |> Floki.text()
      assert label =~ "Fjordline"
      refute label =~ "Northstar"
    end

    test "Phase 177 logged-out Inbound return lands on Fjordline Inbound", %{conn: conn} do
      conn = get(conn, "/ops/mail/inbound?tenant_id=fjordline-aps")

      assert "/demo/login?return_to=" <> encoded = redirected_to(conn)
      assert URI.decode_www_form(encoded) == "/ops/mail/inbound?tenant_id=fjordline-aps"

      logged_in = login_to(conn)
      assert redirected_to(logged_in) == "/ops/mail/inbound?tenant_id=fjordline-aps"
    end

    test "Phase 177 hostile arrival query never leaves the operator path", %{conn: conn} do
      conn = get(conn, "/ops/mail?tenant_id=x&return_to=%2F%2Fevil.example")

      # The arrival query is carried only as an encoded value, never as a host.
      refute URI.parse(redirected_to(conn)).host

      logged_in = login_to(conn)
      final = redirected_to(logged_in)

      assert String.starts_with?(final, "/ops/mail")
      refute URI.parse(final).host

      for header_conn <- [conn, logged_in],
          value <- get_resp_header(header_conn, "location") do
        refute URI.parse(value).host
      end
    end

    test "Phase 177 oversized arrival falls back to the bounded params path", %{conn: conn} do
      long = String.duplicate("a", 3000)
      conn = get(conn, "/ops/mail?tenant_id=fjordline-aps&view=deliveries&junk=#{long}")

      assert redirected_to(conn) ==
               "/demo/login?return_to=" <>
                 URI.encode_www_form("/ops/mail?tenant_id=fjordline-aps&view=deliveries")
    end

    test "Phase 177 adapter fallback without a socket keeps tenant_id and view only" do
      context = %{
        actor: %{subject_id: nil},
        params: %{"tenant_id" => "fjordline-aps", "view" => "deliveries", "x" => "y"}
      }

      assert {:error, :unauthorized,
              %{
                message: "demo operator login required",
                to: to
              }} = AdminAuth.authorize(:operator_access, context)

      assert to ==
               "/demo/login?return_to=" <>
                 URI.encode_www_form("/ops/mail?tenant_id=fjordline-aps&view=deliveries")

      assert {:error, :unauthorized, %{to: "/demo/login?return_to=%2Fops%2Fmail"}} =
               AdminAuth.authorize(:operator_access, %{actor: %{subject_id: nil}, params: %{}})

      assert {:ok, _} =
               AdminAuth.authorize(:operator_access, %{actor: %{subject_id: "demo-operator"}})

      assert {:error, :unauthorized, details} =
               AdminAuth.authorize(:destructive_action, %{actor: %{subject_id: nil}})

      refute Map.has_key?(details, :to)
    end
  end

  describe "Preview navigation (D-07)" do
    test "Phase 177 Preview with Fjordline return context renders the Back link", %{conn: conn} do
      conn = get(conn, "/dev/mail?return_surface=deliveries&return_tenant_id=fjordline-aps")
      scenario_url = redirected_to(conn)

      pairs = scenario_url |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
      assert pairs["return_surface"] == "deliveries"
      assert pairs["return_tenant_id"] == "fjordline-aps"

      html = conn |> recycle() |> get(scenario_url) |> html_response(200)
      {:ok, doc} = Floki.parse_document(html)

      links = Floki.find(doc, ~s([data-testid="preview-return-link"]))
      assert links != []

      for link <- links do
        assert Floki.text(link) =~ "Back to Deliveries"
      end

      assert [href] = links |> Floki.attribute("href") |> Enum.uniq()
      uri = URI.parse(href)
      assert uri.path == "/ops/mail"

      assert URI.decode_query(uri.query) == %{
               "view" => "deliveries",
               "tenant_id" => "fjordline-aps"
             }
    end

    test "Phase 177 Preview without context points directly at the operator surfaces", %{
      conn: conn
    } do
      conn = get(conn, "/dev/mail")
      html = conn |> recycle() |> get(redirected_to(conn)) |> html_response(200)
      {:ok, doc} = Floki.parse_document(html)

      hrefs = doc |> Floki.find("a") |> Floki.attribute("href")

      assert "/ops/mail" in hrefs
      assert "/ops/mail?view=deliveries" in hrefs
      assert "/ops/mail/inbound" in hrefs
      assert Floki.find(doc, ~s([data-testid="preview-return-link"])) == []
      refute Enum.any?(hrefs, &String.contains?(&1, "/demo/login"))
    end
  end

  describe "referrer policy (T-177-23)" do
    test "Phase 177 operator and Preview responses carry strict-origin-when-cross-origin", %{
      conn: conn
    } do
      operator = get(conn, "/ops/mail")
      assert get_resp_header(operator, "referrer-policy") == ["strict-origin-when-cross-origin"]

      index = get(build_conn(), "/dev/mail")
      assert get_resp_header(index, "referrer-policy") == ["strict-origin-when-cross-origin"]

      scenario =
        index
        |> recycle()
        |> get(redirected_to(index))

      assert get_resp_header(scenario, "referrer-policy") == ["strict-origin-when-cross-origin"]
    end
  end
end
