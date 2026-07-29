# Phase 139: Admin asset first-load/deep-link proof - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 6 new/modified targets
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mailglass_admin/test/support/endpoint_case.ex` | route / test support | request-response | `mailglass_admin/test/support/endpoint_case.ex` | exact |
| `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs` | test | request-response | `mailglass_admin/test/mailglass_admin/preview_live_test.exs` | role-match |
| `mailglass_admin/e2e/admin-assets.spec.js` | test | request-response + event-driven browser network | `mailglass_admin/e2e/operator.spec.js`, `mailglass_admin/e2e/structural.spec.js` | role-match |
| `mailglass_admin/lib/mailglass_admin/layouts.ex` | utility / layout helper | transform + request-response | `mailglass_admin/lib/mailglass_admin/layouts.ex` | exact, conditional |
| `mailglass_admin/lib/mailglass_admin/mount_path.ex` | utility | transform | `mailglass_admin/lib/mailglass_admin/mount_path.ex` | exact, conditional |
| `mailglass_admin/test/mailglass_admin/mount_path_test.exs` | test | transform | `mailglass_admin/test/mailglass_admin/mount_path_test.exs` | exact, conditional |

Conditional files are only for narrow hardening if the proof exposes an edge case. The default phase path is test/support proof while preserving `MountPathHook -> MountPath.base/1 -> Layouts.css_url/1`.

## Pattern Assignments

### `mailglass_admin/test/support/endpoint_case.ex` (route / test support, request-response)

**Analog:** `mailglass_admin/test/support/endpoint_case.ex`

**Imports / router macro pattern** (lines 19-22):
```elixir
use Phoenix.Router
import Phoenix.LiveView.Router
import MailglassAdmin.Router
```

**Browser pipeline pattern** (lines 34-41):
```elixir
pipeline :browser do
  plug(:accepts, ["html"])
  plug(:fetch_session)
  plug(:fetch_live_flash)
  plug(:put_root_layout, html: {MailglassAdmin.Layouts, :root})
  plug(:protect_from_forgery)
  plug(:put_secure_browser_headers)
end
```

**Preview mount pattern** (lines 43-52):
```elixir
scope "/dev" do
  pipe_through(:browser)

  mailglass_admin_routes("/mail",
    mailables: [
      :"Elixir.MailglassAdmin.Fixtures.HappyMailer",
      :"Elixir.MailglassAdmin.Fixtures.StubMailer",
      :"Elixir.MailglassAdmin.Fixtures.BrokenMailer"
    ]
  )
end
```

**Operator/inbound mount pattern** (lines 55-81):
```elixir
scope "/ops" do
  pipe_through(:browser)

  get("/browser-ready", MailglassAdmin.TestAdopter.BrowserSessionController, :ready)
  get("/browser-reset", MailglassAdmin.TestAdopter.BrowserSessionController, :reset)
  get("/browser-login", MailglassAdmin.TestAdopter.BrowserSessionController, :create)

  mailglass_operator_routes("/mail",
    auth: MailglassAdmin.TestOperatorAuth,
    session: [
      subject_id: "current_user_id",
      tenant_id: "tenant_id",
      auth_method: "auth_method",
      recent_auth_at: "recent_auth_at"
    ],
    on_mount: [{MailglassAdmin.TestOperatorHook, :audit}],
    unauthorized_path: "/login",
    inbound_router: MailglassAdmin.TestSupport.InboundTestRouter
  )
end
```

**Browser login fixture pattern** (lines 106-123):
```elixir
def create(conn, params) do
  conn = Plug.Conn.fetch_query_params(conn)
  params = Map.merge(conn.query_params, params)

  tenant_id = Map.get(params, "tenant_id", "browser-tenant")
  return_to = Map.get(params, "return_to", "/ops/mail?tenant_id=#{tenant_id}")
  subject_id = Map.get(params, "subject_id", "operator-1")
  now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  conn
  |> Plug.Conn.put_session("current_user_id", subject_id)
  |> Plug.Conn.put_session("subject_id", subject_id)
  |> Plug.Conn.put_session("tenant_id", tenant_id)
  |> Plug.Conn.put_session("auth_method", "password")
  |> Plug.Conn.put_session("recent_auth_at", now)
  |> Plug.Conn.put_resp_header("cache-control", "no-store")
  |> Phoenix.Controller.redirect(to: return_to)
end
```

**EndpointCase test harness pattern** (lines 274-291):
```elixir
use ExUnit.CaseTemplate

using do
  quote do
    import Plug.Conn
    import Phoenix.ConnTest
    alias MailglassAdmin.TestAdopter.Router.Helpers, as: Routes
    @endpoint MailglassAdmin.TestSupport.AdminBootstrap.endpoint()
  end
end

setup_all do
  MailglassAdmin.TestSupport.AdminBootstrap.setup_all()
end

setup do
  {:ok, conn: MailglassAdmin.TestSupport.AdminBootstrap.build_conn()}
end
```

**How to apply:** Add alternate test-only scopes beside the existing `/dev` and `/ops` scopes. Reuse the same public macros and pass unique `live_session_name` values; do not add public asset-root options.

---

### `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs` (test, request-response)

**Analog:** `mailglass_admin/test/mailglass_admin/preview_live_test.exs`

**Test module setup pattern** (lines 13-28):
```elixir
use MailglassAdmin.LiveViewCase, async: false

alias MailglassAdmin.Fixtures.{HappyMailer, StubMailer, BrokenMailer}

@fixture_mailables [HappyMailer, StubMailer, BrokenMailer]

setup %{conn: conn} do
  conn = Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
  {:ok, conn: conn}
end
```

**First HTML stylesheet assertion pattern** (lines 73-80):
```elixir
test "dead-render <head> stylesheet href is absolute under the mount path",
     %{conn: conn} do
  html = conn |> get("/dev/mail") |> html_response(200)

  assert html =~ ~r|<link[^>]*rel="stylesheet"[^>]*href="/dev/mail/css-[0-9a-f]+"|
  refute html =~ ~s(href="css-)
end
```

**Deep-link LiveView route pattern** (lines 151-177):
```elixir
{:ok, _view, html} =
  live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

assert html =~ ~s(data-testid="preview-header-controls")

{:ok, _view, html} =
  live(conn, "/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__")

assert html =~ ~s(data-testid="preview-render-error")
```

**Query/deep-link pattern** (lines 263-279):
```elixir
path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=375&theme=dark"
{:ok, _view, html} = live(conn, path)

assert html =~ "width: 375px"
assert html =~ ~s|data-theme="mailglass-dark"|
```

**Operator/inbound authenticated conn pattern** (`mailglass_admin/test/mailglass_admin/inbound_live_test.exs` lines 1636-1649):
```elixir
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
```

**Root layout query theme proof pattern** (`mailglass_admin/test/mailglass_admin/inbound_live_test.exs` lines 1577-1592):
```elixir
test "?theme=dark themes the inbound ROOT <html>, not just the shell", %{conn: conn} do
  conn = operator_conn(conn)

  {:ok, _view, html} =
    live(conn, inbound_path(%{"tenant_id" => @tenant_id, "theme" => "dark"}))

  assert html =~ ~s|<html lang="en" data-theme="mailglass-dark">|
end
```

**Parser helper pattern when extracting exact hrefs** (`mailglass_admin/test/mailglass_admin/operator/shell_test.exs` lines 136-156):
```elixir
defp current_nav_labels(html) do
  {:ok, doc} = Floki.parse_fragment(html)

  doc
  |> Floki.find(~s([aria-current="page"]))
  |> Enum.map(&Floki.text/1)
  |> Enum.map(&String.trim/1)
end

defp current_nav_classes(html) do
  {:ok, doc} = Floki.parse_fragment(html)

  doc
  |> Floki.find(~s([aria-current="page"]))
  |> Enum.map(fn node ->
    node
    |> Floki.attribute("class")
    |> List.first()
    |> to_string()
  end)
end
```

**Asset response assertion pattern** (`mailglass_admin/test/mailglass_admin/assets_test.exs` lines 14-31, 47-56):
```elixir
hash = MailglassAdmin.Controllers.Assets.css_hash()
conn = get(conn, "/dev/mail/css-#{hash}")

assert conn.status == 200

content_type = get_resp_header(conn, "content-type") |> List.first()
assert content_type =~ "text/css"

conn = get(conn, "/dev/mail/fonts/inter-400.woff2")
assert conn.status == 200

content_type = get_resp_header(conn, "content-type") |> List.first()
assert content_type =~ "font/woff2"
```

**How to apply:** Build an explicit matrix of first HTML paths. For each row, perform `get(conn, path) |> html_response(200)`, extract the stylesheet href, assert it starts with the effective mount root plus `/css-`, and refute bare `href="css-` plus nested route leakage like `/gallery/css-` and `/inbound/css-`. Use `operator_conn/1` for `/ops/mail` and `/ops/mail/inbound`.

---

### `mailglass_admin/e2e/admin-assets.spec.js` (test, request-response + event-driven browser network)

**Analogs:** `mailglass_admin/e2e/operator.spec.js`, `mailglass_admin/e2e/structural.spec.js`, `mailglass_admin/e2e/gallery-matrix.spec.js`

**Imports and constants pattern** (`operator.spec.js` lines 1-8):
```javascript
const { test, expect } = require("@playwright/test");

const tenantId = "browser-tenant";
```

**Authenticated operator navigation pattern** (`operator.spec.js` lines 17-23):
```javascript
async function openOperator(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
}
```

**Reusable login helper pattern** (`structural.spec.js` lines 58-74):
```javascript
async function loginOperator(page, returnTo, subjectId = "operator-1", sessionTenantId = tenantId) {
  await page.context().clearCookies();
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const loginParams = new URLSearchParams({
    tenant_id: sessionTenantId,
    return_to: returnTo,
    subject_id: subjectId
  });

  const loginPath = `/ops/browser-login?${loginParams.toString()}`;
  const loginURL = new URL(loginPath, baseURL).toString();
  await page.goto(loginURL);
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`tenant_id=${sessionTenantId}`));
}
```

**Direct preview/deep-link navigation pattern** (`structural.spec.js` lines 104-124):
```javascript
async function openPreviewIndex(page, query = "") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
}

async function openPreviewScenario(page, query = "theme=light") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-header-controls")).toBeVisible();
}

async function openPreviewError(page, query = "theme=light") {
  await page.context().clearCookies();
  await page.goto(`/dev/mail/MailglassAdmin.Fixtures.BrokenMailer/__error__${query ? "?" + query : ""}`);
  await expect(page.getByTestId("preview-shell")).toBeVisible();
  await expect(page.getByTestId("preview-render-error")).toBeVisible();
}
```

**Direct gallery navigation pattern** (`gallery-matrix.spec.js` lines 60-63):
```javascript
async function openGallery(page) {
  await page.goto("/dev/mail/gallery");
  await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();
}
```

**Computed style assertion pattern** (`structural.spec.js` lines 964-999):
```javascript
test("Operator: body text is 400, first h1 heading is 700", async ({ page }) => {
  await openOperator(page);

  const bodyWeight = await page.locator("body").evaluate(
    el => getComputedStyle(el).fontWeight
  );
  expect(bodyWeight).toBe("400");

  const h1Weight = await page.getByRole("heading", { level: 1 }).first().evaluate(
    el => getComputedStyle(el).fontWeight
  );
  expect(h1Weight).toBe("700");
});
```

**CSS font URL dependency to prove** (`mailglass_admin/assets/css/app.css` lines 148-186):
```css
/* URLs are RELATIVE (./fonts/...) so the browser resolves them against
   whatever mount path the adopter chose. */
@font-face {
  font-family: 'Inter';
  font-weight: 400;
  font-display: swap;
  src: url('./fonts/inter-400.woff2') format('woff2');
}
```

**Playwright config pattern** (`mailglass_admin/playwright.config.cjs` lines 10-23):
```javascript
module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: {
    timeout: 5_000
  },
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["github"], ["list"]] : "list",
  use: {
    baseURL,
    trace: "on-first-retry"
  },
  webServer: {
    command: 'MIX_ENV=test mix run --no-halt -e "MailglassAdmin.TestSupport.OperatorBrowserServer.run!()"',
```

**Serialized browser gate command** (`mailglass_admin/package.json` lines 4-6):
```json
"scripts": {
  "test:operator-browser": "mix mailglass_admin.assets.build && playwright test --config=playwright.config.cjs --workers=1"
}
```

**How to apply:** Keep the spec screenshot-free. Add a helper that attaches `page.on("requestfailed")` and `page.on("response")` before each direct `page.goto`, filters `request.resourceType()` to `stylesheet` and `font`, asserts no failures, asserts `status() === 200`, asserts stylesheet content type includes `text/css`, asserts font content type includes `font/woff2`, and asserts asset URL path starts with the expected mount root. Then assert token-backed computed styles such as body `fontWeight`, `fontFamily`, `backgroundColor`, or h1 weight.

---

### `mailglass_admin/lib/mailglass_admin/layouts.ex` (utility / layout helper, transform + request-response, conditional)

**Analog:** `mailglass_admin/lib/mailglass_admin/layouts.ex`

**Imports / embed pattern** (lines 1-16):
```elixir
defmodule MailglassAdmin.Layouts do
  @moduledoc false

  use Phoenix.Component

  @compile {:no_warn_undefined, [MailglassAdmin.Controllers.Assets]}

  embed_templates "layouts/*"
end
```

**CSS URL pattern** (lines 25-31):
```elixir
defp css_url(assigns) do
  if Code.ensure_loaded?(MailglassAdmin.Controllers.Assets) and
       function_exported?(MailglassAdmin.Controllers.Assets, :css_hash, 0) do
    mounted_asset_url(assigns, "css-" <> MailglassAdmin.Controllers.Assets.css_hash())
  else
    mounted_asset_url(assigns, "css-pending.css")
  end
end
```

**Mount-aware URL fallback pattern** (lines 34-51):
```elixir
defp mounted_asset_url(%{mount_path: mount_path}, filename) when is_binary(mount_path) do
  Path.join(mount_path, filename)
end

defp mounted_asset_url(%{conn: %Plug.Conn{request_path: request_path}}, filename) do
  request_path
  |> asset_mount_path()
  |> Path.join(filename)
end

defp mounted_asset_url(_assigns, filename), do: filename

defp asset_mount_path(request_path), do: MailglassAdmin.MountPath.base(request_path)
```

**Root layout emission pattern** (`mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` lines 1-11):
```heex
<!DOCTYPE html>
<html lang="en" data-theme={root_theme(assigns)}>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
    <link rel="stylesheet" href={css_url(assigns)} />
    <script><%= Phoenix.HTML.raw(js_inline()) %></script>
```

**How to apply:** Only edit if the new tests prove a real first-HTML edge case. Preserve the assign-first path (`%{mount_path: mount_path}`), then the legacy `@conn` fallback, then the final filename fallback.

---

### `mailglass_admin/lib/mailglass_admin/mount_path.ex` (utility, transform, conditional)

**Analog:** `mailglass_admin/lib/mailglass_admin/mount_path.ex`

**Core transform pattern** (lines 18-29):
```elixir
@doc "Returns the absolute mount-base path for a request/document path."
@spec base(String.t() | nil) :: String.t()
def base(request_path) when is_binary(request_path) do
  segments =
    request_path
    |> String.trim("/")
    |> String.split("/", trim: true)

  "/" <> Enum.join(strip(segments), "/")
end

def base(_request_path), do: "/"
```

**Route-shape stripping pattern** (lines 31-45):
```elixir
defp strip([]), do: []

defp strip(segments) do
  last = List.last(segments)

  preview_mailable? =
    segments
    |> Enum.at(-2, "")
    |> module_segment?()

  cond do
    last in ["gallery", "inbound"] -> Enum.drop(segments, -1)
    preview_mailable? -> Enum.drop(segments, -2)
    true -> segments
  end
end
```

**Module-segment heuristic** (lines 48-51):
```elixir
@doc "Heuristic: does a path segment look like an Elixir module name?"
@spec module_segment?(String.t()) :: boolean()
def module_segment?(segment),
  do: String.contains?(segment, ".") and String.match?(segment, ~r/^(Elixir\.)?[A-Z]/)
```

**How to apply:** If alternate or deep-link proof fails, harden `strip/1` with the narrowest route-shape rule and pair it with `mount_path_test.exs`. Do not introduce router options or config.

---

### `mailglass_admin/test/mailglass_admin/mount_path_test.exs` (test, transform, conditional)

**Analog:** `mailglass_admin/test/mailglass_admin/mount_path_test.exs`

**Test setup pattern** (lines 1-10):
```elixir
defmodule MailglassAdmin.MountPathTest do
  @moduledoc """
  Pure coverage for `MailglassAdmin.MountPath.base/1`
  """
  use ExUnit.Case, async: true

  alias MailglassAdmin.MountPath
end
```

**Route-shape assertions** (lines 13-39):
```elixir
test "index path is its own mount base" do
  assert MountPath.base("/dev/mail") == "/dev/mail"
  assert MountPath.base("/admin/preview") == "/admin/preview"
end

test "show path drops the trailing mailable + scenario segments" do
  assert MountPath.base("/dev/mail/MyApp.UserMailer/welcome") == "/dev/mail"
  assert MountPath.base("/admin/preview/MyApp.UserMailer/welcome") == "/admin/preview"
end

test "preview_props error path drops mailable + __error__" do
  assert MountPath.base("/dev/mail/MyApp.UserMailer/__error__") == "/dev/mail"
end

test "gallery and inbound drop only their own trailing segment" do
  assert MountPath.base("/dev/mail/gallery") == "/dev/mail"
  assert MountPath.base("/ops/mail/inbound") == "/ops/mail"
end

test "single-segment and root mounts" do
  assert MountPath.base("/mail") == "/mail"
  assert MountPath.base("/mail/MyApp.UserMailer/welcome") == "/mail"
end
```

**How to apply:** Add any newly discovered route shapes here before editing `MountPath.base/1`. Keep this file pure and async.

## Shared Patterns

### Router-Scoped Asset Routes

**Source:** `mailglass_admin/lib/mailglass_admin/router.ex`
**Apply to:** `endpoint_case.ex`, `admin_asset_url_test.exs`, `admin-assets.spec.js`

**Macro asset emission** (lines 216-230, 257-280, 286-292):
```elixir
scope path, alias: false, as: false do
  MailglassAdmin.Router.__asset_routes__()
  MailglassAdmin.Router.__theme_routes__()

  on_mount_hooks =
    opts[:on_mount] ++ [MailglassAdmin.Preview.Mount, MailglassAdmin.MountPathHook]

  live_session session_name,
    session: {MailglassAdmin.Router, :__preview_session__, [opts]},
    on_mount: on_mount_hooks,
    root_layout: {MailglassAdmin.Layouts, :root} do
    live "/", MailglassAdmin.PreviewLive, :index
    live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show
    live "/gallery", MailglassAdmin.GalleryLive, :index
  end
end

defmacro __asset_routes__ do
  quote do
    get "/css-:md5", MailglassAdmin.Controllers.Assets, :css
    get "/js-:md5", MailglassAdmin.Controllers.Assets, :js
    get "/fonts/:name", MailglassAdmin.Controllers.Assets, :font
    get "/logo.svg", MailglassAdmin.Controllers.Assets, :logo
  end
end
```

### Mount Path Assign Flow

**Source:** `mailglass_admin/lib/mailglass_admin/mount_path_hook.ex`
**Apply to:** layout and first-HTML assertions

**Hook pattern** (lines 48-67):
```elixir
def on_mount(_arg, _params, session, socket) do
  cookie_theme = explicit_cookie_theme(session)

  socket =
    socket
    |> assign(:mount_path, nil)
    |> assign(:admin_chrome_theme, cookie_theme)
    |> assign(:admin_chrome_theme_cookie, cookie_theme)
    |> Phoenix.LiveView.attach_hook(:mailglass_mount_path, :handle_params, &put_mount_path/3)

  {:cont, socket}
end

defp put_mount_path(params, uri, socket) do
  path = uri |> URI.parse() |> Map.get(:path)

  {:cont,
   socket
   |> assign(:mount_path, MountPath.base(path))
   |> assign(:admin_chrome_theme, resolve_theme(params, socket.assigns[:admin_chrome_theme_cookie]))}
end
```

### Asset Controller Responses

**Source:** `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`
**Apply to:** ExUnit direct asset checks and Playwright network assertions

**Serving/content-type pattern** (lines 117-142):
```elixir
def init(action) when action in [:css, :js, :font, :logo], do: action

def call(conn, :css), do: serve(conn, @css, "text/css; charset=utf-8")
def call(conn, :js), do: serve(conn, @js, "application/javascript; charset=utf-8")
def call(conn, :logo), do: serve(conn, @logo, "image/svg+xml")

def call(conn, :font) do
  name = conn.params["name"]

  with {:ok, path} <- resolve_font(name),
       {:ok, bytes} <- File.read(path) do
    serve(conn, bytes, "font/woff2")
  else
    _ ->
      conn
      |> send_resp(404, "")
      |> halt()
  end
end

defp serve(conn, body, content_type) do
  conn
  |> put_resp_header("content-type", content_type)
  |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
  |> send_resp(200, body)
  |> halt()
end
```

### Browser Server / Serialized Gate

**Source:** `mailglass_admin/test/support/operator_browser_server.ex`, `mailglass_admin/package.json`
**Apply to:** `admin-assets.spec.js`

**Server bootstrap pattern** (`operator_browser_server.ex` lines 11-31):
```elixir
def run! do
  IO.puts("[operator-browser-server] booting")

  port =
    System.get_env("BROWSER_SERVER_PORT", "4101")
    |> String.to_integer()

  {:ok, _} = Application.ensure_all_started(:mailglass)

  AdminBootstrap.setup_all(port: port, server: true, pool: :sandbox, ensure_repo: true)

  owner = AdminBootstrap.start_server_owner!(ownership_timeout: @server_ownership_timeout)

  OperatorFixtures.seed_browser_scenario!()
end
```

**Command pattern** (`package.json` lines 4-6):
```json
"scripts": {
  "test:operator-browser": "mix mailglass_admin.assets.build && playwright test --config=playwright.config.cjs --workers=1"
}
```

### LiveView Test Harness

**Source:** `mailglass_admin/test/support/live_view_case.ex`
**Apply to:** `admin_asset_url_test.exs`

**Harness pattern** (lines 17-40):
```elixir
using opts do
  quote do
    use ExUnit.Case, unquote(opts)
    import Plug.Conn
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest
    alias MailglassAdmin.TestAdopter.Router.Helpers, as: Routes
    alias MailglassAdmin.TestRepo
    @endpoint MailglassAdmin.TestSupport.AdminBootstrap.endpoint()
  end
end

setup_all do
  MailglassAdmin.TestSupport.AdminBootstrap.setup_all()
end

setup do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MailglassAdmin.TestRepo, shared: true)
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

  MailglassAdmin.TestSupport.CitextProbe.run(repo: MailglassAdmin.TestRepo)
  Mailglass.Tenancy.put_current("test-tenant")

  {:ok, conn: MailglassAdmin.TestSupport.AdminBootstrap.build_conn()}
end
```

## No Analog Found

| File / Subpattern | Role | Data Flow | Reason |
|-------------------|------|-----------|--------|
| `mailglass_admin/e2e/admin-assets.spec.js` stylesheet/font network collector | test helper | event-driven browser network | Existing Playwright specs use `page.goto`, DOM assertions, and `getComputedStyle`, but no codebase spec currently captures `page.on("response")` / `page.on("requestfailed")` for `stylesheet` and `font` resource types. Use `139-RESEARCH.md` Pattern 3 for this helper. |

## Metadata

**Analog search scope:** `mailglass_admin/test`, `mailglass_admin/e2e`, `mailglass_admin/lib/mailglass_admin`, `mailglass_admin/assets/css`, `mailglass_admin/playwright.config.cjs`, `mailglass_admin/package.json`
**Files scanned:** 24
**Pattern extraction date:** 2026-07-07
