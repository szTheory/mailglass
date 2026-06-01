# Phase 69: Click - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` | controller | request-response | `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` | exact |
| `reference/demo_app/lib/mailglass_demo_web/router.ex` | route | request-response | `reference/demo_app/lib/mailglass_demo_web/router.ex` | exact |
| `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` | test | request-response | `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` | exact |
| `reference/demo_app/test/mailglass_demo_web/page_controller_home_test.exs` (implied) | test | request-response | `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` | role-match |
| `reference/demo_app/README.md` (+ optional root `README.md` pointer tweak) | config | transform | `reference/demo_app/README.md` | exact |

## Pattern Assignments

### `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` (controller, request-response)

**Analog:** `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex`

**Imports pattern** (lines 1-5):
```elixir
defmodule MailglassDemoWeb.PageController do
  use Phoenix.Controller, formats: [:html]

  alias MailglassDemo.DemoData
  def health(conn, _params), do: text(conn, "ok")
```

**Core hub pattern** (lines 7-10, 91-103, 107-113):
```elixir
def home(conn, _params) do
  summary = DemoData.summary()
  html(conn, """ ... """)
  ...
  <a class="card" href="/dev/mail">...</a>
  <a class="card" href="/demo/login?return_to=/ops/mail?tenant_id=#{summary.tenant_id}">...</a>
  <a class="card" href="/demo/login?return_to=/ops/mail/inbound?tenant_id=#{summary.tenant_id}">...</a>
  ...
  <form method="post" action="/demo/reset">
    <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}">
```

**Auth/session + redirect guard** (lines 122-130, 159-168, 173-177):
```elixir
def login(conn, params) do
  return_to = safe_return_to(Map.get(params, "return_to"))
  conn
  |> put_session("demo_subject_id", "demo-operator")
  |> put_session("demo_tenant_id", DemoData.tenant_id())
  |> redirect(to: return_to)
end

defp safe_return_to(return_to) when is_binary(return_to) do
  uri = URI.parse(return_to)
  if is_nil(uri.scheme) and is_nil(uri.host) and operator_path?(uri.path), do: return_to, else: default_operator_path()
end
```

**Error/forbidden response pattern** (lines 141-156):
```elixir
if authorized_evidence_reset?(conn) do
  conn |> put_status(:ok) |> json(%{status: "ok", warning: "...", summary: DemoData.summary()})
else
  conn |> put_status(:forbidden) |> json(%{error: "forbidden"})
end
```

---

### `reference/demo_app/lib/mailglass_demo_web/router.ex` (route, request-response)

**Analog:** `reference/demo_app/lib/mailglass_demo_web/router.ex`

**Imports + pipeline pattern** (lines 1-16):
```elixir
defmodule MailglassDemoWeb.Router do
  use Phoenix.Router
  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import Plug.Conn
  import MailglassAdmin.Router
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
  end
```

**Route wiring pattern** (lines 22-35, 37-63):
```elixir
scope "/", MailglassDemoWeb do
  pipe_through(:browser)
  get("/", PageController, :home)
  get("/demo/login", PageController, :login)
  post("/demo/reset", PageController, :reset)
end

scope "/ops" do
  pipe_through(:browser)
  mailglass_operator_routes("/mail", auth: MailglassDemoWeb.AdminAuth, ...)
end
```

---

### `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` (test, request-response)

**Analog:** `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs`

**Test module/setup pattern** (lines 1-17):
```elixir
defmodule MailglassDemoWeb.PageControllerSecurityTest do
  use MailglassDemo.ConnCase, async: false
  alias MailglassDemo.DemoData
  setup do
    previous_token = System.get_env("DEMO_EVIDENCE_RESET_TOKEN")
    System.put_env("DEMO_EVIDENCE_RESET_TOKEN", "test-demo-reset-token")
    on_exit(fn -> ... end)
  end
```

**Security assertion pattern** (lines 19-35):
```elixir
conn = get(conn, "/demo/login", %{"return_to" => "//evil.example/phish"})
assert redirected_to(conn) == "/ops/mail?tenant_id=#{DemoData.tenant_id()}"

conn = post(conn, "/demo/evidence/reset")
assert json_response(conn, 403) == %{"error" => "forbidden"}
```

---

### `reference/demo_app/test/mailglass_demo_web/page_controller_home_test.exs` (implied new test, request-response)

**Analog:** `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs`

**Reuse ConnCase request/assert style** (lines 1-3, 19-29 from analog):
```elixir
use MailglassDemo.ConnCase, async: false
conn = get(conn, "/")
assert html_response(conn, 200) =~ "Northstar Ops"
```

**Recommended content assertions for Phase 69 scope:**
- dashboard links: `/dev/mail`, `/demo/login?return_to=/ops/mail?tenant_id=northstar`, `/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar`
- destructive reset wording present in dashboard and/or evidence endpoint warning copy
- seeded summary labels present (`Deliveries`, `Ledger Events`, `Inbound Records`, `Suppressions`)

---

### `reference/demo_app/README.md` (+ optional `README.md`) (config/docs, transform)

**Analog:** `reference/demo_app/README.md` (primary), `README.md` (pointer style)

**Canonical quickstart/list pattern** (lines 5-19, 20-29):
```markdown
## Quickstart
...
- Demo dashboard: http://localhost:4015
- Preview: http://localhost:4015/dev/mail
- Outbound operator: http://localhost:4015/demo/login?return_to=/ops/mail?tenant_id=northstar
- Inbound operator: http://localhost:4015/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar
...
Destructive note: this reset truncates seeded demo tables before reseeding ...
```

**Boundary language pattern** (lines 36-37, 66-68):
```markdown
Future artifact label: `demo_browser_evidence.v1`. This is adoption evidence only; demo DOM, selectors, routes, and copy are not stable public API.
...
does not define stable Mailglass API guarantees.
```

## Shared Patterns

### Safe Operator Redirects
**Source:** `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex:159-177`  
**Apply to:** Dashboard/operator navigation and any login return-to changes
```elixir
if is_nil(uri.scheme) and is_nil(uri.host) and operator_path?(uri.path) do
  return_to
else
  default_operator_path()
end
```

### Demo-Only Session/Auth Glue
**Source:** `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex:122-130`, `reference/demo_app/lib/mailglass_demo_web/router.ex:52-62`, `reference/demo_app/lib/mailglass_demo_web/admin_auth.ex:1-23`  
**Apply to:** Outbound/inbound operator card flows
```elixir
|> put_session("demo_subject_id", "demo-operator")
...
mailglass_operator_routes("/mail", auth: MailglassDemoWeb.AdminAuth, session: [...], unauthorized_path: "/")
```

### Destructive Reset Contract
**Source:** `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex:141-151`, `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs:37-47`, `reference/demo_app/README.md:26-28`  
**Apply to:** Dashboard reset card copy, docs wording, and tests
```elixir
warning: "Destructive demo reset endpoint: truncates and reseeds demo evidence tables."
```

### Controller-Test Style
**Source:** `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs:1-47`  
**Apply to:** New Phase 69 dashboard coverage tests
```elixir
use MailglassDemo.ConnCase, async: false
conn = get(conn, "/demo/login", %{"return_to" => ...})
assert redirected_to(conn) == ...
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `reference/demo_app/**`, root `README.md`, `test/**`  
**Files scanned:** 9  
**Pattern extraction date:** 2026-06-01
