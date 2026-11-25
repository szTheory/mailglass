defmodule MailglassAdmin.RootThemeOwnershipContractTest do
  @moduledoc """
  BRPIPE-02 required-lane proof: `<html>` is the only owner of the admin theme.

  A nested theme attribute re-declares the whole `--color-*` and `--mg-*` token
  set inside its subtree, so the region repaints with the wrong tokens whenever
  it disagrees with the cookie or the OS scheme. A class or an inline style that
  assigns those custom properties is the same defect under a new name.

  Three layers, all in the required `support_contract_admin` lane:

    * document counts: every dead-render document the admin returns carries one
      theme attribute (on `<html>`) for an explicit cookie and none for system;
    * a static scan of `mailglass_admin/lib` for nested owners and token
      assignments;
    * teeth: the scan detectors are pure functions, proven on planted
      violations and clean controls so the scan cannot go vacuous.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @theme_cookie MailglassAdmin.Theme.cookie_name()
  @tenant_id "test-tenant"
  @preview_path "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
  @operator_path "/ops/mail?tenant_id=" <> @tenant_id
  @inbound_path "/ops/mail/inbound?tenant_id=" <> @tenant_id
  @gallery_path "/dev/mail/gallery"

  @lib_dir Path.expand("../../lib", __DIR__)
  @root_layout "mailglass_admin/layouts/root.html.heex"

  # {cookie value (nil = no cookie = system), expected owners, expected root value}
  @modes [
    {"dark", 1, "mailglass-dark"},
    {"light", 1, "mailglass-light"},
    {nil, 0, nil}
  ]

  describe "document-level theme ownership" do
    for {cookie, count, value} <- @modes do
      mode = cookie || "system"

      test "preview show document carries #{count} theme owner for #{mode}", %{conn: conn} do
        {:ok, _view, html} = live(with_theme(conn, unquote(cookie)), @preview_path)
        assert_root_only(html, unquote(count), unquote(value), "preview show")
      end

      test "operator document carries #{count} theme owner for #{mode}", %{conn: conn} do
        conn = conn |> operator_conn() |> with_theme(unquote(cookie))
        {:ok, _view, html} = live(conn, @operator_path)
        assert_root_only(html, unquote(count), unquote(value), "operator")
      end

      test "inbound document carries #{count} theme owner for #{mode}", %{conn: conn} do
        conn = conn |> operator_conn() |> with_theme(unquote(cookie))
        {:ok, _view, html} = live(conn, @inbound_path)
        assert_root_only(html, unquote(count), unquote(value), "inbound")
      end

      # The gallery is read with get/2: it is the largest document the admin
      # returns, so it is also the surface a nested wrapper multiplied fastest.
      test "gallery document carries #{count} theme owner for #{mode}", %{conn: conn} do
        conn = conn |> with_theme(unquote(cookie)) |> get(@gallery_path)
        assert_root_only(html_response(conn, 200), unquote(count), unquote(value), "gallery")
      end
    end
  end

  describe "gallery renders one specimen per state" do
    test "every state cell holds exactly one specimen wrapper", %{conn: conn} do
      doc = conn |> get(@gallery_path) |> html_response(200) |> Floki.parse_document!()

      # A cell is a gallery element that contains specimen wrappers. Inner
      # composed-layout wrappers (gallery-composed-*) contain none, so they are
      # not cells.
      cells =
        for element <- Floki.find(doc, ~s([data-testid^="gallery-"])),
            [testid] <- [Floki.attribute(element, "data-testid")],
            not String.ends_with?(testid, "-system"),
            wrappers = Floki.find(element, ~s([data-testid$="-system"])),
            wrappers != [] do
          {testid, Enum.flat_map(wrappers, &Floki.attribute(&1, "data-testid"))}
        end

      assert cells != [], "the gallery rendered no state cells"
      assert Enum.uniq_by(cells, &elem(&1, 0)) == cells, "a state cell is rendered more than once"

      for {testid, wrappers} <- cells do
        assert wrappers == [testid <> "-system"],
               "#{testid} must hold exactly one #{testid}-system wrapper, found #{inspect(wrappers)}"
      end

      specimen_count = doc |> Floki.find(~s([data-testid$="-system"])) |> length()

      assert specimen_count == length(cells),
             "#{specimen_count} specimen wrappers for #{length(cells)} state cells"
    end

    test "every id value in the gallery document is unique", %{conn: conn} do
      duplicates =
        conn
        |> get(@gallery_path)
        |> html_response(200)
        |> Floki.parse_document!()
        |> Floki.find("[id]")
        |> Enum.flat_map(&Floki.attribute(&1, "id"))
        |> Enum.frequencies()
        |> Enum.filter(fn {_id, n} -> n > 1 end)
        |> Enum.map(&elem(&1, 0))

      assert duplicates == [],
             "#{length(duplicates)} duplicated id values: " <>
               inspect(Enum.sort(duplicates))
    end

    test "live/2 mounts the gallery without a duplicate-id raise", %{conn: conn} do
      {:ok, _view, html} = live(conn, @gallery_path)
      assert html =~ "Component Gallery"
    end
  end

  describe "static ownership scan" do
    test "only the root layout owns the theme and nothing under lib re-declares tokens" do
      sources = lib_sources()

      assert length(sources) > 30,
             "the lib glob found #{length(sources)} files; the scan is vacuous"

      assert List.keymember?(sources, @root_layout, 0), "#{@root_layout} is missing from the scan"

      assert scan(sources) == [], format_violations(scan(sources))
    end

    test "the root layout sets the attribute on the html element, exactly once" do
      source = File.read!(Path.join(@lib_dir, @root_layout))

      assert [_one] = Regex.scan(~r/\sdata-theme\s*=/, source)
      assert source =~ ~r/<html[^>]*\sdata-theme=\{root_theme\(assigns\)\}/
    end
  end

  describe "detectors have teeth" do
    test "a nested theme attribute is flagged in every spelling, in any file" do
      for planted <- [
            ~s|<div data-theme="mailglass-light">|,
            ~s|<div data-theme={@theme_attr}>|,
            ~s|<div data-theme = "mailglass-dark">|,
            ~s|el.setAttribute("data-theme", "dark")|,
            ~s|Map.put(attrs, "data-theme", theme)|,
            ~s|%{"data-theme": theme}|,
            ~s|document.body.dataset.theme = "dark"|
          ] do
        assert [%{rule: :nested_theme_owner, line: 1}] =
                 scan_source("mailglass_admin/preview/tabs.ex", planted),
               "planted violation was not flagged: #{planted}"
      end
    end

    test "the root layout may set the attribute only on the html element" do
      assert [] = scan_source(@root_layout, ~s|<html lang="en" data-theme={root_theme(assigns)}>|)

      assert [%{rule: :nested_theme_owner, line: 2}] =
               scan_source(
                 @root_layout,
                 ~s|<html lang="en" data-theme={root_theme(assigns)}>\n<div data-theme="mailglass-light">|
               )
    end

    test "a token assignment is flagged in an inline style, an arbitrary class and css text" do
      for planted <- [
            ~s|<div style="--color-base-100: #fff">|,
            ~s|<div style={"--mg-color-background: \#{bg}"}>|,
            ~s|<div class="p-sm [--mg-color-background:#fff]">|,
            ~s|<div class="[&>*]:[--color-base-100:#000]">|,
            ~s|  --mg-color-surface:#fff;|
          ] do
        assert [%{rule: :token_declaration, line: 1}] =
                 scan_source("mailglass_admin/components.ex", planted),
               "planted violation was not flagged: #{planted}"
      end
    end

    test "reads, state markers and unrelated properties are not flagged" do
      for clean <- [
            ~s|<div data-theme-owner="preview-authoring-story">|,
            ~s|<div data-preview-frame-theme="light">|,
            ~s|<div style="border: 1px solid var(--color-base-300)">|,
            ~s|<div class="bg-[var(--color-base-200)] text-base-content">|,
            ~s|<div style="color-scheme: dark; background: Canvas">|,
            ~s|tooltip.style.setProperty("--mg-tooltip-arrow-x", arrow)|,
            ~s|document.querySelector("[data-theme]")|,
            ~s|[data-theme=mailglass-dark] .mg-card { color: red }|
          ] do
        assert [] = scan_source("mailglass_admin/components.ex", clean),
               "clean control was flagged: #{clean}"
      end
    end

    test "violations name the file, the line and the fix" do
      [theme, token] =
        scan([
          {"mailglass_admin/operator/shell.ex", ~s|ok\n<div data-theme="x">|},
          {"mailglass_admin/components.ex", ~s|<div style="--mg-x: 1">|}
        ])

      assert theme.path == "mailglass_admin/operator/shell.ex" and theme.line == 2
      assert token.path == "mailglass_admin/components.ex" and token.line == 1

      message = format_violations([theme, token])
      assert message =~ "mailglass_admin/operator/shell.ex:2"
      assert message =~ "only layouts/root.html.heex may set the theme attribute"
      assert message =~ "mailglass_admin/components.ex:1"
      assert message =~ "read tokens with var()"
    end
  end

  # -- scan: pure functions of (path, source) so the teeth block can feed them ---

  # An owner is the attribute written as markup (`data-theme=`), a quoted
  # attribute name handed to a builder or to JS, or `dataset.theme =`. A
  # `[data-theme=...]` selector reads the attribute, it does not set it.
  defp theme_owner_patterns do
    [
      ~r/(?<![\w\-\[])data-theme\s*=/,
      ~r/["']data-theme["']\s*(?:,|:|=>)/,
      ~r/dataset\.theme\s*=/
    ]
  end

  # A declaration, not a read: `--mg-x: 1` and `[--mg-x:1]`, never `var(--mg-x)`.
  defp token_declaration, do: ~r/--(?:mg|color)-[a-z0-9-]+\s*:/

  defp scan(sources) do
    Enum.flat_map(sources, fn {path, source} -> scan_source(path, source) end)
  end

  defp scan_source(path, source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {text, line} ->
      [
        theme_owner_hit(path, line, text),
        token_declaration_hit(path, line, text)
      ]
      |> Enum.reject(&is_nil/1)
    end)
  end

  defp theme_owner_hit(path, line, text) do
    owner? = Enum.any?(theme_owner_patterns(), &Regex.match?(&1, text))
    root_html_line? = path == @root_layout and String.contains?(text, "<html")

    if owner? and not root_html_line? do
      %{rule: :nested_theme_owner, path: path, line: line, text: String.trim(text)}
    end
  end

  defp token_declaration_hit(path, line, text) do
    if Regex.match?(token_declaration(), text) do
      %{rule: :token_declaration, path: path, line: line, text: String.trim(text)}
    end
  end

  defp format_violations(violations) do
    Enum.map_join(violations, "\n", fn
      %{rule: :nested_theme_owner} = v ->
        "#{v.path}:#{v.line} sets the theme attribute (#{v.text}). " <>
          "Fix: only layouts/root.html.heex may set the theme attribute, on <html>; " <>
          "delete it and let the cookie-driven root decide."

      %{rule: :token_declaration} = v ->
        "#{v.path}:#{v.line} declares a --mg-*/--color-* custom property (#{v.text}). " <>
          "Fix: read tokens with var(), never assign them in a class or inline style."
    end)
  end

  defp lib_sources do
    @lib_dir
    |> Path.join("**/*.{ex,heex}")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, @lib_dir), File.read!(&1)})
  end

  # -- helpers ------------------------------------------------------------------

  defp assert_root_only(html, count, value, surface) do
    owners = html |> Floki.parse_document!() |> Floki.find("[data-theme]")
    occurrences = length(Regex.scan(~r/\sdata-theme=/, html))

    assert length(owners) == count and occurrences == count,
           "#{surface}: expected #{count} data-theme owner(s), found #{length(owners)} " <>
             "element(s) and #{occurrences} attribute occurrence(s). " <>
             "Only the root <html> may own the theme."

    case owners do
      [] ->
        :ok

      [{tag, attrs, _children}] ->
        assert tag == "html", "#{surface}: the single theme owner is <#{tag}>, expected <html>"
        assert List.keyfind(attrs, "data-theme", 0) == {"data-theme", value}
    end
  end

  defp with_theme(conn, nil), do: conn

  defp with_theme(conn, cookie),
    do: Plug.Conn.put_req_header(conn, "cookie", "#{@theme_cookie}=#{cookie}")

  defp operator_conn(conn, session \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.configure_session(renew: false)
    |> then(fn conn ->
      Plug.Test.init_test_session(conn, Map.merge(get_session_map(conn), session))
    end)
  end

  defp get_session_map(conn) do
    %{
      "current_user_id" => Plug.Conn.get_session(conn, "current_user_id"),
      "tenant_id" => Plug.Conn.get_session(conn, "tenant_id"),
      "auth_method" => Plug.Conn.get_session(conn, "auth_method"),
      "recent_auth_at" => Plug.Conn.get_session(conn, "recent_auth_at")
    }
  end
end
