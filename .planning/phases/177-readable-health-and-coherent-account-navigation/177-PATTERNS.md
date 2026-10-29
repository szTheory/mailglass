# Phase 177: Readable Health and Coherent Account Navigation - Pattern Map

**Mapped:** 2026-10-28
**Files analyzed:** 47 (14 new, 33 modified; counting each coupled test/e2e edit as one row)
**Analogs found:** 45 / 47 (2 have no direct analog, see "No Analog Found")
**Tracked-source gate (#3645):** every analog path below was verified with `git ls-files --error-unmatch` (all TRACKED). No gitignored mirror path appears in this document. All paths are relative to `/Users/jon/projects/mailglass`.

Reading order for the planner: File Classification -> Shared Patterns (apply to many plans) -> Pattern Assignments (per file) -> Do-Not-Copy list -> No Analog Found.

---

## File Classification

### Library (mailglass_admin/lib/mailglass_admin)

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `preview/return_context.ex` (NEW) | utility (pure validator + href builder) | transform | `mount_path.ex` (pure `@moduledoc false`, total fallback clauses) + `theme.ex:80-97` (query decode/encode) | role-match |
| `controllers/theme_controller.ex` (MOD) | controller | request-response | itself (`:49-61`) + `router_test.exs:130-152` | exact (self) |
| `preview_live.ex` (MOD) | component (LiveView) | request-response / URL-state | itself (`handle_params` 98-191, builders 682-693, 779-846) | exact (self) |
| `preview/sidebar.ex` (MOD) | component | URL-state | itself (`scenario_path` 394-398) | exact (self) |
| `operator/shell.ex` (MOD) | component | request-response | itself (`shell/1` 156-224, `account_context/1` 226-318, `tenant_switch_path/2` 99-111) | exact (self) |
| `surface_nav.ex` (MOD) | component | request-response | itself + `components.ex` `nav_link/nav_pill` (243-355) | exact (self) |
| `operator/health_overview.ex` (MOD) | component | transform (assigns to HEEx) | itself (full file, 175 lines) | exact (self) |
| `operator_live.ex` (MOD) | LiveView | request-response | itself (`:695-810`, `:525-540`, `:147-151`) | exact (self) |
| `inbound_live.ex` (MOD) | LiveView | request-response | itself (`:171-175`, `:189-205`, `:545-600`) | exact (self) |
| `router.ex` (MOD, one docs sentence only) | config/docs | n/a | itself (`:48-49`, `:61-62`) | exact (self) |
| `assets/css/app.css` + `priv/static/app.css` (MOD) | config (CSS bundle) | n/a | `.operator-deliveries-layout` (`app.css:678-681`), `.mg-inbound-replay-dialog` (`:335-338`) | exact |
| `docs/design-system.md` (MOD) | docs | n/a | itself (`:188-210`) | exact (self) |

### Tests (mailglass_admin/test, e2e)

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `test/mailglass_admin/preview/return_context_test.exs` (NEW) | test (pure unit) | transform | `test/mailglass_admin/mount_path_test.exs` | exact |
| `test/mailglass_admin/phase177_return_navigation_test.exs` (NEW) | test (connected) | request-response | `test/mailglass_admin/preview_live_test.exs` (330-380, 770-795) + `phase176_prohibition_contract_test.exs` (`operator_conn`, 1088-1099) | role-match |
| `test/mailglass_admin/phase177_account_scope_test.exs` (NEW) | test (component) | transform | `test/mailglass_admin/operator/shell_test.exs` | exact |
| `test/mailglass_admin/phase177_prohibition_contract_test.exs` (NEW) | test (contract, mutation-proven) | transform + request-response | `phase175_prohibition_contract_test.exs` (component corpus) + `phase176_prohibition_contract_test.exs` (connected + detectors) | exact |
| `test/mailglass_admin/health_population_test.exs` (NEW) | test (golden fingerprint) | request-response | `operator_live_test.exs` Health block (`:4622-4750`, `:5700-5800`) | role-match |
| `test/mailglass_admin/operator/health_overview_test.exs` (NEW) | test (component) | transform | `test/mailglass_admin/operator/results_status_test.exs` + `phase175_prohibition_contract_test.exs` `render_component` usage | role-match |
| `test/support/endpoint_case.ex` (MOD) | test support | config | itself (`:43-125`, `:349-383`) | exact (self) |
| `test/mailglass_admin/router_test.exs` (MOD, add ThemeController cases + `refute return_*`) | test | request-response | itself (`:83-152`, `:195-293`) | exact (self) |
| Coupled-assertion edits: `shell_test.exs:216`, `preview_live_test.exs:358-365`, `voice_test.exs:65`, `operator_live_test.exs` (4639-40, 4761, 5713/5736/5782/5799, 5737, 5756, 5791, 2728), `persona_cohort_test.exs:116` (MOD) | test | n/a | themselves | exact (self) |
| `test/mailglass_admin/quick_view_projection_test.exs` (MOD, add `@tag :phase177` table) | test | transform | itself `@tag :phase176` test (`:310-348`) | exact (self) |
| `e2e/phase177-return-navigation.spec.js`, `e2e/phase177-account.spec.js`, `e2e/phase177-health.spec.js` (NEW; planned as three specs, plans 177-01/06/08) | test (Playwright) | request-response | `e2e/phase176-filters.spec.js` (1-20, AxeBuilder) + `e2e/phase169-journey.spec.js` (350-366, geometry) | role-match |
| `e2e/support/account.cjs` (NEW, visible-only Account locator helper) | test support | n/a | `e2e/support/storybook-axe-supplement.cjs` (CommonJS helper under `e2e/support`) | role-match |
| e2e edits: `phase169-journey.spec.js:52,357,367`; `flows.spec.js`; `structural.spec.js`; `inbound-layout.spec.js`; `phase170-journey.spec.js`; `phase175-inbound.spec.js` (MOD) | test | n/a | themselves | exact (self) |

### Reference / demo / stories / planning

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `reference/demo_app/lib/mailglass_demo_web/router.ex` (MOD, Preview `navigation`) | config | n/a | itself (`:104-148`) | exact (self) |
| `reference/demo_app/lib/mailglass_demo_web/admin_auth.ex` (MOD, logged-out `to:`) | middleware (auth adapter) | request-response | itself + `mailglass_admin/test/support/endpoint_case.ex` `TestOperatorAuth` first clause (`:368-371`) | role-match |
| `reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs` (NEW; plan 177-10) | test | request-response | `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` | role-match |
| `reference/demo_app/assets/e2e/phase177-return.spec.js` (NEW) | test (Playwright) | request-response | `reference/demo_app/assets/e2e/phase176-filters.spec.js` (`loginTo`, 1-8) | exact |
| `reference/demo_app/storybook/health_overview.story.exs` (NEW) | story | transform | `reference/demo_app/storybook/delivery_investigation.story.exs` | exact |
| `reference/demo_app/storybook/account_scope.story.exs` (NEW) | story | transform | `reference/demo_app/storybook/inbound_evidence.story.exs` | exact |
| `reference/demo_app/storybook/preview_chrome.story.exs` (NEW) | story | transform | `delivery_investigation.story.exs` + `storybook/primitives/nav_link.story.exs` (nav-in-theme-wrapper) | role-match |
| `reference/persona_spec/quick_view_scenarios.ex` (MOD, new builders) | utility (pure builder) | transform | itself `inbound_evidence/1` (`:138-169`) | exact (self) |
| `reference/persona_spec/quick_view_scenarios.json` (MOD, new scenarios + `fb-health-crowding`/`fb-account-context`) | config (manifest) | n/a | itself: `inbound-evidence-*` scenario objects; `fb-delivery-*` automated entries (`:1347-1352`) | exact (self) |
| `reference/demo_app/assets/e2e/` story-inventory spec (NEW, optional) | test | n/a | `reference/demo_app/assets/e2e/inbound-evidence.spec.js` | exact |
| `.planning/phases/177-.../177-AUTOMATION.md`, `177-HEALTH-COMPARISON.md` (NEW) | docs (evidence record) | n/a | `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md` | role-match |
| Temporary A/B comparison story/spike (NEW, throwaway, scratchpad) | story/spike | transform | `delivery_investigation.story.exs` (+ story-local `composition: :a \| :b` attr) | role-match |

---

## Shared Patterns

### SP-1. Closed-set / "do not accept input" (security spine of UXF-10)

**Source:** CONTEXT D-01/D-02/D-05; `mailglass_admin/lib/mailglass_admin/mount_path.ex` (total functions, binary guard, safe fallback).
**Apply to:** `preview/return_context.ex`, `operator/shell.ex` (minting), `preview_live.ex`, `controllers/theme_controller.ex`.

Rules every plan must hold:
- `return_surface` is compared **as a string** against `~w(overview deliveries inbound)`. Never `String.to_atom`.
- The destination path always comes from the **host-configured** `navigation` map (`:overview_path | :deliveries_path | :inbound_path`); only the opaque `tenant_id` value is inserted, and only through `URI.encode_query`.
- `return_tenant_id` is only ever placed **inside an `href`/query string**. Never in text nodes, `page_title`, flash, `data-*`, `aria-*`, logs, or telemetry (D-11, P2).
- `PreviewLive` gets **no** `:selected_tenant_id` / `:tenant_id` / `:account_labels` assigns (P8). Session whitelists in `router.ex` stay byte-identical.

### SP-2. Query merge via `URI.query_decoder` / `URI.encode_query` (never string concat)

**Source:** `mailglass_admin/lib/mailglass_admin/theme.ex:80-97`, `preview_live.ex:835-846` (`append_query_without_theme/2`), `operator/shell.ex:146-155` (`@switch_query_keys` + `preserved_switch_query/1`).
**Apply to:** `ReturnContext` (replace-in-place `tenant_id`), every Preview URL builder, `ThemeController`.

```elixir
# theme.ex:80-97  (precedent to copy for ReturnContext.put_tenant/2 and query_pairs append)
def strip_theme_query(path_or_uri) when is_binary(path_or_uri) do
  parsed = URI.parse(path_or_uri)
  path = parsed.path || "/"
  append_query_without_theme(path, parsed.query || "")
end

defp append_query_without_theme(path, query) do
  query =
    query
    |> URI.query_decoder()
    |> Enum.reject(fn {key, _value} -> key == "theme" end)
    |> URI.encode_query()

  case query do
    "" -> path
    query -> path <> "?" <> query
  end
end
```

**Direct-entry byte-identity rule (Pitfall 4):** `query_pairs(nil) == []` and each builder must return the original string unchanged when the list is empty, so existing assertions keep passing: `preview_live_test.exs:790` (`assert_patch(view, base_path <> "?width=375")`), theme redirect assertions (`:278, :723, :797, :862`), and nav hrefs (`:363-365`). Golden-test no-context outputs **before** editing builders.

### SP-3. Cross-live_session links are plain `href` through the shared nav primitives

**Source:** `mailglass_admin/lib/mailglass_admin/components.ex:243-355`; `surface_nav.ex:32-48`.
**Apply to:** `surface_nav.ex`, the Preview Back link, operator -> Preview link.

```elixir
# components.ex nav_link/1 with navigate={false}  (renders <.link href>, aria-current, 44px target)
def nav_link(%{navigate: false} = assigns) do
  ~H"""
  <.link
    href={@href}
    aria-current={@active && "page"}
    class={[
      "mg-focus-ring flex min-h-11 items-center gap-sm rounded-field px-sm text-body transition-colors ease-out",
      "duration-(--duration-fast)",
      nav_link_class(@active)
    ]}
    {@rest}
  >
    <.icon name={@icon} class="h-5 w-5 shrink-0" />
    <span class="mg-nav-label truncate">{@label}</span>
  </.link>
  """
end
```

`@rest` is a `:global` attr, so `id`, `data-testid`, `aria-describedby` pass through. Scoped items and the Preview item MUST go through `Components.nav_link` / `nav_pill` (PRIMITIVE-DRIFT-GATE).

### SP-4. Conformance gates that new HEEx must satisfy (`mailglass_admin/scripts/check-conformance.sh`)

**Apply to:** every edited/new `.ex` under `lib/` (HealthOverview, Shell, SurfaceNav, PreviewLive, ReturnContext).

| Gate | Rule that bites this phase |
|---|---|
| PRIMITIVE-DRIFT (`:36-87`) | No private `defp nav_link/nav_pill/...`; the copied class signature `mg-focus-ring flex min-h-11 items-center rounded-field px-sm text-body transition-colors ease-out duration-\(--duration-fast\)` is forbidden outside `components.ex`. The UI-SPEC Back-link classes (`inline-flex ... gap-xs ... hover:text-base-content`) do **not** match it; do not "tidy" them into that signature. |
| TYPE-GATE (`:274`) | No `text-sm/xs/xl/2xl/3xl/base`; use `text-label/body/heading/display`. |
| BOLD-GATE (`:282`) | `font-bold` only; never `font-medium`/`font-semibold`. |
| GAP-GATE (`:294`) | No `gap-3/4/6`; use `gap-xs/sm/md/lg/xl` (and `gap-x-sm gap-y-xs`). |
| ICON-EXISTS-GATE (`:148-251`) | Every `hero-*` must exist in `assets/vendor/heroicons-inline.js`. UI-SPEC allowlist: `hero-arrow-uturn-left`, `hero-chevron-down`, `hero-arrow-path`, `hero-exclamation-triangle`, `hero-minus-circle`, `hero-check-circle`, `hero-building-office-2`. Do NOT use `hero-arrow-left`. |
| HEX / Z-INDEX / FOCUS-RING (`:335-361`) | No raw hex; use `mg-layer-*`; use `mg-focus-ring`. |
| STATCARD-GATE (`:128-146`) | Health must not reintroduce `card bg-base-200 border ... rounded-box p-md`, `text-display font-bold`, or `<.stat` in `operator_live.ex`. |

### SP-5. Test file conventions for Phase 177

**Source:** `phase175_prohibition_contract_test.exs:17-23, 428-456`; `phase176_prohibition_contract_test.exs:1-44, 1088-1099`; `results_status_test.exs:1-8`.
**Apply to:** all new `test/mailglass_admin/phase177_*_test.exs`, `health_population_test.exs`, `operator/health_overview_test.exs`.

- Connected or component tests: `use MailglassAdmin.LiveViewCase, async: false` (imports `Phoenix.LiveViewTest`, `Plug.Conn`, `Phoenix.ConnTest`; sets `@endpoint`; sandbox + `Tenancy.put_current("test-tenant")`; `live_view_case.ex:1-41`). Pure unit: `use ExUnit.Case, async: true`.
- Tag every new test `@moduletag :phase177` (same convention as `@moduletag :phase176`).
- Shared matching helpers (copy verbatim from phase175 `:428-456`):

```elixir
defp visible_text(html) do
  html
  |> Floki.parse_fragment!()
  |> Floki.filter_out("script")
  |> Floki.text(sep: " ")
  |> String.replace(~r/\s+/, " ")
end

defp violations(text, patterns), do: Enum.filter(patterns, &Regex.match?(&1, text))

defp assert_clean(corpus, patterns, label) do
  for text <- corpus do
    hits = violations(text, patterns)
    assert hits == [],
           "#{label}: #{inspect(Enum.map(hits, &Regex.source/1))} matched #{inspect(text)}"
  end
end
```

- Operator session helper (copy from phase176 `:1088-1099`, because `operator_live_test.exs` helpers are `defp` and not importable):

```elixir
defp operator_conn(conn, session \\ %{}) do
  now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  base = %{
    "current_user_id" => "operator-1",
    "tenant_id" => @tenant_id,
    "auth_method" => "password",
    "recent_auth_at" => now
  }

  Plug.Test.init_test_session(conn, Map.merge(base, session))
end
```

- Patch-kind assertion helper (phase176 `:1062-1066`): `assert_receive {^ref, {:patch, ^topic, %{kind: ^kind, to: to}}}`.
- **Do not** add tests above any registered `@tag :skip` in files covered by `scripts/check_test_exceptions.sh`. That script scans `test/mailglass` and `mailglass_inbound/test` only (RESEARCH Pitfall 9), so admin tests are exempt, but prefer new files over growing `voice_test.exs`.

### SP-6. Bundle rebuild + token-parity guard

**Source:** `assets/css/app.css` (source) and `priv/static/app.css` (committed, canonical); RESEARCH Pitfall 7.
**Apply to:** the CSS plan and any plan adding Tailwind utilities (`min-h-11` on links, `@[30rem]:` variants).

Sequence after any class change: `mix mailglass_admin.assets.build` -> run `token_parity_test.exs` + `assets_test.exs` -> if daisyUI theme blocks differ, restore them from the committed bundle and keep only new-utility hunks -> commit `priv/static/app.css` in the same change. After every Playwright run: `git status --short mailglass_admin/priv/static` and restore if dirty. Variants must be static literals (`@[30rem]:flex-row`, never interpolated).

### SP-7. Local toolchain prefix

Every mix command: `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix ...` (project memory `project_local_elixir_toolchain_gap`). Do not edit `.tool-versions`.

---

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/preview/return_context.ex` (NEW; utility, transform)

**Analogs:** `mailglass_admin/lib/mailglass_admin/mount_path.ex` (shape: `@moduledoc false`, `@spec`, binary-guarded clause + total fallback), `theme.ex:80-97` (query round-trip), `operator/shell.ex:99-111` (`tenant_switch_path/2` building `path <> "?" <> URI.encode_query(...)`).

**Total-function shape to copy** (`mount_path.ex:15-26`):

```elixir
@doc "Returns the absolute mount-base path for a request/document path."
@spec base(String.t() | nil) :: String.t()
def base(request_path) when is_binary(request_path) do
  segments = request_path |> String.trim("/") |> String.split("/", trim: true)
  "/" <> Enum.join(strip(segments), "/")
end

def base(_request_path), do: "/"
```

**Core algorithm** (adapt RESEARCH Pattern 1; sketch, not shipped code):

```elixir
@surfaces ~w(overview deliveries inbound)

def resolve(%{"return_surface" => s, "return_tenant_id" => t}, navigation)
    when is_binary(s) and is_binary(t) and s in @surfaces do
  with path when is_binary(path) <- nav_path(navigation, s),   # string OR atom key (see operator_live.ex:147-151)
       true <- local_path?(path),
       true <- valid_tenant_id?(t) do
    %{surface: s, tenant_id: t, href: put_tenant(path, t),
      query_pairs: [{"return_surface", s}, {"return_tenant_id", t}]}
  else
    _ -> nil
  end
end
def resolve(_, _), do: nil          # list/map values, missing keys, unknown surface

def query_pairs(nil), do: []
def query_pairs(%{query_pairs: pairs}), do: pairs

# replace-in-place so "/ops/mail?tenant_id=browser-tenant" never gains a second tenant_id
defp put_tenant(path, t) do
  uri = URI.parse(path)
  pairs = URI.query_decoder(uri.query || "") |> Enum.to_list()
  pairs = List.keystore(pairs, "tenant_id", 0, {"tenant_id", t})
  URI.to_string(%{uri | query: URI.encode_query(pairs)})
end
```

**Validation set (D-02):** surface in closed list; configured path non-nil, starts with `/`, not `//`, no `\`, no scheme/host; id is `String.valid?/1`, `byte_size` in `1..255`, no `\p{Cc}` control characters, not blank. Add `operator_href/3` (operator side, mints the Preview href: skip when no Account is selected or `preview_path` is not a local absolute path, A3) and a `local_path?/1` public helper reused by `Shell`.

**Navigation key tolerance:** `navigation` arrives atom-keyed from the session (`router.ex:406-411`, `navigation_opts/1`), but both LiveViews already tolerate string keys:

```elixir
# operator_live.ex:147-151  (copy the tolerance, not a new helper shape)
defp navigation_path(%{"navigation" => navigation}, key) when is_map(navigation) do
  blank_to_nil(Map.get(navigation, key) || Map.get(navigation, Atom.to_string(key)))
end
```

**Must not:** log, emit telemetry, `String.to_atom`, or raise on any input (test with a 10k-char surface and list/map-valued params).

---

### `mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex` (MOD; controller, request-response)

**Analog:** itself, `:49-61` (stale CONTEXT ref `:11-19`; the real range is `:49-61`).

**Current code to replace** (`theme_controller.ex:52-61`):

```elixir
defp sanitized_return_to(return_to, mount_path) when is_binary(return_to) do
  parsed = URI.parse(return_to)

  cond do
    parsed.scheme || parsed.host -> mount_path
    String.starts_with?(return_to, "//") -> mount_path
    not String.starts_with?(parsed.path || "", mount_path) -> mount_path
    true -> Theme.strip_theme_query(return_to)
  end
end
```

**Change (D-08):** keep the `cond` shape; replace the third clause with a segment-boundary check: `path == mount_path or String.starts_with?(path, String.trim_trailing(mount_path, "/") <> "/")` (special-case `mount_path == "/"`); add clauses rejecting any `\` and any `//` in the path; optionally reject `.`/`..`/`%2e` segments (RESEARCH A2, recommended). `Theme.strip_theme_query/1` and `PreviewLive.append_query_without_theme/2` already keep `return_*` params, so **no new code** for return-param persistence (Pitfall 5); prove with a test only.

**Regression tests go beside** `router_test.exs:130-152` (`describe "theme persistence route"`), mirroring the existing style:

```elixir
test "rejects external return urls", %{conn: conn} do
  conn = get(conn, "/ops/mail/theme/dark?return_to=https://evil.example/phish")
  assert redirected_to(conn) == "/ops/mail"
end
```

New cases (all mounted at `/ops/mail`): `/ops/mailx`, `/ops/mail%2e%2e/x`, `/ops/mail\\x`, `/ops/mail//x`, `/dev/mail/x`; keep every existing valid case green (`:83-152`).

---

### `mailglass_admin/lib/mailglass_admin/preview_live.ex` (MOD; LiveView, URL-state)

**Analog:** itself. Edit sites and shape:

| Site | Lines | Change |
|---|---|---|
| `handle_params` show clause | `98-161` | `params = params_with_query(params, uri)` already merges the query (`:871-879`); add `assign(:return_context, ReturnContext.resolve(params, socket.assigns.admin_navigation))` in the success branch **and** in the `{:preview_props_raised, ...}` and `_ ->` not-found branches (otherwise the Back link vanishes on a bad scenario URL). |
| `handle_params` index clause | `163-191` | assign the context before `first_scenario_path`; when there are no previewable mailables (`"#"`) the empty state still renders the Back link. |
| `first_scenario_path/3` | `682-693` | add a context arg; `build_capture_url(path, width, query_pairs)`. |
| `build_capture_url/2` | `798` | `base_path <> "?width=" <> width` -> accept `query_pairs`, `URI.encode_query([{"width", width} | pairs])`; when `pairs == []` output must be byte-identical to today. |
| `sync_patch_capture_url_state/1` | `779-796` | pass `socket.assigns.return_context`; this builder currently **drops every unknown param** (the bug being fixed). |
| `preview_surface_paths/1` | `743-762` | Health/Deliveries/Inbound -> per-surface derivation from each `navigation` entry + the same validated `tenant_id` (each from its own `navigation_path/2`); Preview item -> mount path plus `query_pairs`. |
| `preview_theme_path/2` | `807-846` | **no code change** (`return_to` already keeps other query params); add test T10. Keep `put_frame_query` call verbatim (comment `:807-815`). |
| `render/1` | `303-365` | `:actions` slot keeps only `theme_picker` (already the case at `:317-325`); pass `return_href`/`return_surface` + scope header mode to both `SurfaceNav.nav` calls (`:326-346`); replace the subtitle at `:349-351`. |

**Current builder code being extended** (`preview_live.ex:779-798`):

```elixir
defp sync_patch_capture_url_state(socket) do
  current_mailable = socket.assigns.current_mailable
  current_scenario = socket.assigns.current_scenario

  if is_atom(current_mailable) and is_atom(current_scenario) and current_scenario != :__error__ and
       is_binary(socket.assigns.base_path) do
    push_patch(
      socket,
      to:
        build_capture_url(
          socket.assigns.base_path,
          Integer.to_string(socket.assigns.device_width)
        )
    )
  else
    socket
  end
end

defp build_capture_url(base_path, width), do: base_path <> "?width=" <> width
```

**Subtitle** (`preview_live.ex:349-351`) becomes the exact UI-SPEC string (equality-asserted by the prohibition contract; `preview_props/0` inside `<code class="mono">`):
`Renders the scenarios in each Mailable's preview_props/0. It doesn't read Deliveries or Inbound messages from any Account.`

**Must not:** read `return_context` to change what the preview frame renders (independent-rendering test: frame HTML identical with/without params).

---

### `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` (MOD; component, URL-state)

**Analog:** itself. `picker/1` and `menu/1` gain a `:return_query` attr (list of `{k, v}` pairs, default `[]`) threaded to the two `patch=` call sites (`:186-187`, `:285-286`) and to `broken_path/2` (callers ~`:237`, `:315`).

**Current helper to extend** (`sidebar.ex:385-402`):

```elixir
defp scenario_path(mount_path, mod, scenario, width, _admin_chrome_theme) do
  scenario_base_path(mount_path, mod, scenario) <>
    "?width=" <>
    Integer.to_string(width)
end

defp broken_path(mount_path, mod) do
  scenario_base_path(mount_path, mod, "__error__")
end
```

Reuse the `ReturnContext`/SP-2 helper so the no-context output stays `...?width=N` byte-for-byte. Existing call-site shape to extend:

```elixir
<.link
  patch={scenario_path(@mount_path, @mod, scenario_name, @device_width, @admin_chrome_theme)}
```

---

### `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (MOD; component, request-response)

**Analog:** itself. Three changes.

**1. Mint the Preview href once** (covers `OperatorLive` and `InboundLive`, because both render `Shell.shell/1`). `shell/1` already receives `active` (`values: [:overview, :deliveries, :inbound]`, `:157`), `preview_path`, `selected_tenant_id`. Pass the minted href to both `SurfaceNav.nav` calls (`:193-213`). Sketch from RESEARCH "Code Examples":

```elixir
@surface_for %{overview: "overview", deliveries: "deliveries", inbound: "inbound"}

defp preview_href(assigns) do
  with true <- is_binary(assigns.selected_tenant_id) and assigns.selected_tenant_id != "",
       true <- ReturnContext.local_path?(assigns.preview_path) do
    ReturnContext.append(assigns.preview_path, [
      {"return_surface", @surface_for[assigns.active]},
      {"return_tenant_id", assigns.selected_tenant_id}
    ])
  else
    _ -> assigns.preview_path
  end
end
```

**2. Re-home `account_context/1` from the `:actions` slot into the scope-group header.** Current slot usage to remove (`shell.ex:179-192`):

```elixir
<:actions>
  <.account_context
    selected_tenant_id={@selected_tenant_id}
    tenant_options={@tenant_options}
    account_labels={@account_labels}
    page_uri={@page_uri}
  />
  <Components.theme_picker selected={@theme_choice} event="set_theme" />
</:actions>
```

After the change `:actions` holds only `theme_picker`. The Account control is rendered **inside** `SurfaceNav.nav` (header slot), in both the sidebar and the mobile copies.

**3. `account_context/1` body (`shell.ex:226-318`) is the markup to adapt.** Keep: `<details ... data-dismiss-outside>`, `summary` `mg-focus-ring flex min-h-11 ...`, `ul aria-label="Available Accounts"`, per-option `.link patch={tenant_switch_path(@page_uri, tenant.id)}` with `data-testid="operator-account-option"`, `data-account-id`, `data-dismiss-menu`, 44px rows, sr-only `operator-account-id`, polite switch status. Change:

```elixir
# shell.ex:242-300  fragments that must change
<details :if={@tenant_options != []} ...>                              # -> render <details> only when length(tenant_options) >= 2 (D-10)
  aria-label={"Change Account: #{@selected_label || "Choose Account"}"} # -> "Choose an Account" (header fallback only; :250, :259, :298)
<ul ... class="mg-scope-menu ... absolute left-0 top-full sm:left-auto sm:right-0 ...">   # -> md+: left-0 at capped width; <md: left-0 right-0 (no right-anchored popover at 320)
phx-click={JS.show(to: "#operator-account-switch-status-#{index}", display: "block")}      # -> id must be layout-suffixed
id={"operator-account-switch-status-#{index}"}                                              # -> "operator-account-switch-status-#{@layout}-#{index}"
<div :if={@tenant_options == []} ...> ... {@selected_label || "Choose Account"}             # -> 0 Accounts: "No Accounts yet"; 1 Account: static name; no chevron/menu
```

Header variants (UI-SPEC): 2+ Accounts -> `<details>` switcher (selected name, or "Choose an Account" when none selected); exactly 1 -> static eyebrow + name; 0 -> static eyebrow + "No Accounts yet"; **Inbound `:unavailable`** (Pitfall 3) -> neutral eyebrow + selected label if any, else static "Choose an Account", never "No Accounts yet". Add a `tenant_state` attr to `shell/1` and `account_context/1` to carry this; `OperatorLive` already has `@tenant_state` (`operator_live.ex:1200-1203`), `InboundLive` has `:unavailable` (`inbound_live.ex:189-205`).

**Duplicate-render landmine (Pitfall 2):** `AdminShell` renders both `:sidebar` (`hidden ... md:block`) and `:mobile_nav` (`md:hidden`) always (`admin_shell.ex:54-71`). Add a `layout` argument and suffix every `id` / `aria-labelledby` / `aria-describedby` target / `JS.show(to:)` selector; keep base `data-testid`s and add `data-layout`.

**Retain unchanged:** `tenant_switch_path/2` (`:99-111`), `@switch_query_keys` (`:146`), `surface_paths/4` (`:57-65`), `tenant_selector/1` (`:386-440`, including its "Choose Account" label asserted by `voice_test.exs:297`, `operator_live_test.exs:2568`, `inbound_live_test.exs:108`), the five retained `text-primary` accents listed in UI-SPEC.

---

### `mailglass_admin/lib/mailglass_admin/surface_nav.ex` (MOD; component, request-response)

**Analog:** itself (77 lines, read in full) + `Components.nav_link/nav_pill` (SP-3).

**Current structure** (`surface_nav.ex:8-51`): a flat `@items` list in order Health, Preview, Deliveries, Inbound; one `<nav aria-label="Mailglass sections" data-testid={"surface-nav-#{@layout}"}>`; `nav_link` for `:sidebar`, `nav_pill` for `:mobile`.

```elixir
@items [
  %{key: :overview, label: "Health", icon: "hero-check-circle"},
  %{key: :preview, label: "Preview", icon: "hero-eye"},
  %{key: :deliveries, label: "Deliveries", icon: "hero-paper-airplane"},
  %{key: :inbound, label: "Inbound", icon: "hero-inbox-arrow-down"}
]
```

**Target shape (UI-SPEC section B):** keep **one** `<nav>` landmark; inside it, in DOM = visual order: (1) optional Back link (first focusable), (2) `<div data-account-scope role="group" aria-labelledby={header_id} aria-describedby={desc_id}>` with header slot then Health, Deliveries, Inbound (Inbound only when `inbound_available?` and path present, existing `item_path/2` logic at `:62-70`), (3) `mt-md border-t border-base-300 pt-md` block with Preview and the caption "Not tied to an Account" (`aria-describedby` from the Preview link). Split `@items` into `@scoped_items` (overview, deliveries, inbound) and the Preview item. New attrs/slots: `slot :scope_header`, `attr :return_href`, `attr :return_surface`, `attr :layout_id` (or reuse `@layout`) for unique ids, `attr :describe_scope?`. The sr-only description text is **derived from rendered items**: "Applies to Health, Deliveries and Inbound." / "Applies to Health and Deliveries." (never names Inbound when absent; prohibition P9).

**Preview-page header (D-11):** the header slot renders a static `<p data-testid="preview-scope-label" class="text-label font-bold text-secondary">Scoped to an Account</p>`, not focusable, no `operator-account*` testid, no `aria-describedby`.

Existing test that must be updated deliberately: `shell_test.exs:216` (`labels == ["Health", "Preview", "Deliveries", "Inbound"]` -> `["Health", "Deliveries", "Inbound", "Preview"]`).

---

### `mailglass_admin/lib/mailglass_admin/operator/health_overview.ex` (MOD; component, transform)

**Analog:** itself (read in full this session). Split `overview/1` into function components `observation/1`, `verdict/1`, `issue_list/1`, `notices/1`, `activity/1` (each: `attr`s in, HEEx out; no state), with `overview/1` as the thin composition.

**Keep verbatim** (population/links are locked, D-16): the verdict `cond` (`:17-33`, except the empty title), `Components.field_help` calls (`:74-78`, `:112-116`, `:140-144`), link attributes `patch={issue.path}` for `:deliveries` and `navigate={issue.path}` for `:inbound` (`:58-73`), `data-testid={issue.testid <> "-link"}`, the activity `Map.has_key?(@states, :inbound_activity)` guard (`:137`), `panel_name/1` (`:171-174`).

**Change table:**

| Current | Lines | New |
|---|---|---|
| outer `div class="grid gap-lg lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]"` | `38` | size container + single column: `<div class="operator-health-layout min-w-0" data-testid="operator-health-layout">` + `<div class="operator-health-column min-w-0" data-testid="operator-health-column">`; width via **named CSS class** (42rem), NOT `max-w-2xl` (48px trap, Pitfall 1) |
| issue rows `<div :for ... divide-y>` | `48-82` | `<ul class="divide-y divide-base-300 border-y border-base-300">` of `<li data-testid={issue.testid}>` |
| count `p.mono ... text-heading font-bold tabular-nums` | `54` | `p class="min-w-10 shrink-0 text-right text-body font-bold tabular-nums text-base-content"` + `data-testid={issue.testid <> "-count"}` (new; replaces the four `p.mono` Floki selectors) |
| link class `... py-xs ...` | `62, 70` | `inline-flex min-h-11 items-center ...` (44px) |
| `"Last retrieved"` | `79` | `"Not refreshed"` |
| notice `<p ... role="status" ...>` + `"last retrieved <ts>."` / `"could not be loaded."` | `84-97` | no `role`; copy per panel: `"{Panel} wasn't refreshed. Showing results from <timestamp>."` / `"{Panel} couldn't be loaded."` Keep as **static template text** so `html =~ "couldn't"` works (Pitfall 6). |
| `"No recent mail activity"` | `28` | `"No mail activity in this period"` |
| detail `"Some checks could not be updated."` | `21` | `"Some checks couldn't be updated. Refresh to try again."` |
| activity `h2 text-body font-bold` | `105` | still `h2`, styled `text-label font-bold text-secondary`, section separated by `mt-lg border-t border-base-300 pt-md` |
| `sm:flex-row sm:gap-xl lg:flex-col lg:gap-md` | `108` | container query: `flex-col gap-sm @[30rem]:flex-row @[30rem]:gap-xl` (static literals; wrapper carries `@container` or `.operator-health-layout`) |
| `"Activity unavailable"` | `133, 161` | `"Outbound activity unavailable"` / `"Inbound activity unavailable"` |

**Absorb observation markup from `operator_live.ex:743-769`** into `observation/1` (attrs: window copy string, window help string, `observed_at`). `health_window_copy/1` (`:2812-2826`) and `health_window_description/1` (`:2828-2835`) stay `defp` in `OperatorLive`; pass the **resulting strings** plus `@health_observed_at`. Target: `role="group"` + `aria-label="Health check period and freshness"`, `flex flex-wrap items-center gap-x-sm gap-y-xs text-label text-secondary`, no `order-*`, no `sm:` split, Refresh with a stable `min-width` and the existing label swap:

```elixir
# operator_live.ex:759-767  (button to carry over; remove order-2/sm:order-none)
<button type="button" phx-click="retry_health" class="btn btn-ghost order-2 min-h-11 sm:order-none">
  <Components.icon name="hero-arrow-path" class="h-4 w-4" />
  <span class="[.phx-click-loading_&]:hidden">Refresh health</span>
  <span class="hidden [.phx-click-loading_&]:inline">Refreshing…</span>
</button>
```

**No `order-*`, `flex-row-reverse`, or `lg:` viewport breakpoints anywhere in this module** (D-17, gate G2). Stat cards / `Components.card` are banned for Health.

---

### `mailglass_admin/lib/mailglass_admin/operator_live.ex` (MOD; LiveView)

**Analog:** itself.

- `render/1` (`:695-730`): pass `tenant_state={@tenant_state}` to `Shell.shell` (and keep passing `preview_path`; minting lives in Shell). Current call shape:

```elixir
<MailglassAdmin.Operator.Shell.shell
  active={@view}
  preview_path={@preview_path}
  overview_path={@overview_path}
  deliveries_path={@deliveries_path}
  inbound_path={@inbound_path}
  inbound_available?={@inbound_available?}
  ...
  selected_tenant_id={@selected_tenant_id}
  tenant_options={@tenant_options}
  account_labels={@account_labels}
  page_uri={@page_uri}
```

- Health region (`:739-807`): delete the inline observation `div` (`:743-769`), keep the `div[data-testid=operator-overview-health]` wrapper and the `HealthOverview.overview issues={health_issues(...)}` call (add `window_copy`, `window_description`, `observed_at` attrs).
- `retry_health` (`:525-540`): only the failure toast copy changes -> `"Some health checks couldn't be refreshed. Showing the last results retrieved."` (success copy "Email health refreshed." unchanged; `health-tooltips.spec.js:58` asserts it).
- `health_issues/7` (`:2849-2931`) is **not edited** (populations, order, filter at `:2929-2930`). The population golden pins it.

### `mailglass_admin/lib/mailglass_admin/inbound_live.ex` (MOD; LiveView)

**Analog:** itself. Pass `tenant_state={@tenant_state}` into `Shell.shell` (`:545-600`); the `:unavailable` state at `:189-205` and its page card (`:580-587`) stay as is. No other change.

---

### `mailglass_admin/lib/mailglass_admin/router.ex` (MOD, optional one sentence)

**Analog:** itself, `:48-49` and `:61-62`. Add at most one docs sentence that Preview `:navigation` paths should point directly at the operator surfaces. **No new option, no schema change, no session key** (D-03). Session callbacks `__preview_session__/2` / `__operator_session__/2` stay byte-identical; guard test is `router_test.exs:195-293` (see next section).

---

### `mailglass_admin/assets/css/app.css` (+ rebuilt `priv/static/app.css`) (MOD)

**Analogs in the same file:** container-query precedent `.operator-deliveries-layout` (`app.css:678-681`), fixed-rem cap precedent `.mg-inbound-replay-dialog { max-width: 42rem }` (`:335-338`).

```css
/* app.css:678-681 */
.operator-deliveries-layout {
  container-type: inline-size;
}
```

Add beside it: `.operator-health-layout { container-type: inline-size; }` and `.operator-health-column { max-width: 42rem; }`.

**Rewrite the narrow-chrome block** (`app.css:690-748`, `@media (max-width: 767px)`): delete the Account-specific rules (`[data-testid="operator-account-context"]` grid placement, `> details`, `.mg-scope-menu`, `operator-account-switcher` width, the `> span > .text-secondary {display:none}` rule that hides the "Account" eyebrow, `operator-account-label {max-width:none}`). **Keep** the topbar grid + `[data-testid="admin-shell-actions"] > fieldset[aria-label="Appearance"]` placement rules (`:703-719`), because `PreviewLive` also uses `admin-shell-topbar` / `admin-shell-actions` (Pitfall 10). `.mg-scope-identity { max-width: 18rem }` (`:340-342`) and `.mg-scope-menu` width (`:344`) must be reconciled with "Account name wraps, never truncates" and the full-band menu below `md`.

Then follow SP-6 (rebuild, parity tests, commit bundle). Add an ExUnit assertion in a Phase 177 test that the shipped bundle contains the 42rem rule for the column class.

### `mailglass_admin/docs/design-system.md` (MOD)

**Analog:** itself, `:188-210`. Amend (a) `:193-195` "...such as the observation period or section title, stays separate." -> period and timestamp are both observation basis; Refresh stays adjacent to the timestamp; (b) `:209-210` "No activity shows a neutral “No recent mail activity”." -> "No mail activity in this period". Add a docs-contract assertion in a Phase 177 test so the amendment cannot regress (`token_parity_test.exs:196-230` reads this guide but pins other strings).

---

### `mailglass_admin/test/mailglass_admin/preview/return_context_test.exs` (NEW; test, pure)

**Analog:** `mailglass_admin/test/mailglass_admin/mount_path_test.exs` (describe-per-function, tiny table-like asserts, `use ExUnit.Case, async: true`).

```elixir
defmodule MailglassAdmin.MountPathTest do
  use ExUnit.Case, async: true
  alias MailglassAdmin.MountPath

  describe "base/1" do
    test "index path is its own mount base" do
      assert MountPath.base("/dev/mail") == "/dev/mail"
    end
    ...
    test "nil / non-binary returns root" do
      assert MountPath.base(nil) == "/"
      assert MountPath.base(:nope) == "/"
    end
```

Table (RESEARCH Wave 0): unknown surface; list/map-valued params; blank / 256-byte / non-UTF-8 / control-char `return_tenant_id`; missing or non-local configured path (`nil`, `"https://x"`, `"//x"`, `"/\\x"`); injection values (`a&view=x`, `#f`, `"><svg>`, U+202E) must round-trip as a percent-encoded **value** and never alter other query keys; replace-in-place of an existing `tenant_id` in a configured path (`"/ops/mail?tenant_id=browser-tenant&view=deliveries"`); 10k-char surface does not raise or create atoms; deterministic seeded loop (no new dependency). `@moduletag :phase177`.

---

### `mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs` (NEW; test, connected)

**Analogs:** `preview_live_test.exs` (setup `:51-60`; nav href asserts `:358-365`; `set_device` / `set_theme` flow `:770-795`) and `phase176_prohibition_contract_test.exs` (`operator_conn`, `assert_patch_kind`, `live/2` against `/ops/mail`).

**Preview flow pattern to copy** (`preview_live_test.exs:770-795`):

```elixir
base_path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
{:ok, view, _html} = live(conn, base_path <> "?width=768")

render_click(view, "set_device", %{"width" => "375"})
assert_patch(view, base_path <> "?width=375")

render_click(view, "set_theme", %{"theme" => "dark"})

assert_redirect(
  view,
  "/dev/mail/theme/dark?return_to=" <> URI.encode_www_form(base_path <> "?width=375")
)
```

Extend each with `&return_surface=deliveries&return_tenant_id=t` and assert survival through: index redirect, scenario patch, `set_device` patch, theme round-trip (follow `/theme/dark?return_to=` then `live/2`). Also: Back link first in nav with surface-only text, never the Account; custom mounts `/alt/dev/console` <-> `/secure/console`; direct-entry/tampered renders identical chrome (no back link, static host paths, no echo); unauthorized Account on arrival:

```elixir
# operator_live_test.exs:1084-1091 pattern
assert {:error, {:redirect, %{to: "/login"}}} = live(operator_conn(conn), "/ops/mail?tenant_id=forbidden-account")
```

(also for `/secure/console` and `/ops/mail/inbound`). Operator -> Preview href: `Floki`-parse the rendered Preview link; assert `return_surface`/`return_tenant_id` present only when an Account is selected, per surface, with no top-level `tenant_id`, and untouched when `preview_path` is non-local. Preview frame HTML identical with/without params.

**Do not claim** a `push_patch` Account switch re-runs host auth (deferred gap, CONTEXT).

### `mailglass_admin/test/support/endpoint_case.ex` (MOD)

**Analog:** itself. Two edits.

1. Denying clause, inserted **before** the generic `authorize(:operator_access, %{actor: actor})` (`:377`), after the existing nil/"blocked" clauses (`:368-375`):

```elixir
# existing (endpoint_case.ex:368-375)
def authorize(:operator_access, %{actor: %{subject_id: nil}}) do
  {:error, :unauthorized, %{message: "Operator access requires a signed-in actor.", to: "/login"}}
end

def authorize(:operator_access, %{actor: %{subject_id: "blocked"}}) do
  {:error, :unauthorized, %{message: "Operator access denied.", to: "/login"}}
end

# NEW (before the generic %{actor: actor} clause)
def authorize(:operator_access, %{params: %{"tenant_id" => "forbidden-account"}}) do
  {:error, :unauthorized, %{message: "Operator access denied.", to: "/login"}}
end
```

`params` is `:not_mounted_at_router`-shaped for non-router mounts; the pattern match on `%{params: %{"tenant_id" => ...}}` already protects that. `TestOperatorHook :audit` (`:320-346`) reads `session["auth_method"]`, not params, so it does not interfere.

2. Add `navigation:` to the two alt mounts: Preview alt (`:60-72`) -> `overview_path: "/secure/console"`, `deliveries_path: "/secure/console?view=deliveries"`, `inbound_path: "/secure/console/inbound"`; operator alt (`:107-124`) -> `navigation: [preview_path: "/alt/dev/console"]`. Existing users of these mounts only assert asset hrefs (`admin_asset_url_test.exs:75-92`, `assets_test.exs:89`, `e2e/admin-assets.spec.js:132-159`).

---

### `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs` (NEW; test, component)

**Analog:** `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` (`use MailglassAdmin.LiveViewCase, async: false`; `render_component(&Shell.orientation_strip/1, ...)`; `rendered_to_string(~H"""<Shell.shell ...>""")` + `Floki.parse_fragment`).

```elixir
# shell_test.exs  (pattern for rendering the full shell and reading nav labels)
html =
  rendered_to_string(~H"""
  <Shell.shell
    active={:overview}
    preview_path="/dev/mail"
    overview_path="/ops/mail?tenant_id=northstar"
    deliveries_path="/ops/mail?tenant_id=northstar&view=deliveries"
    inbound_path="/ops/mail/inbound?tenant_id=northstar"
    inbound_available?={true}
    title="Email health"
  >
    body
  </Shell.shell>
  """)

{:ok, doc} = Floki.parse_fragment(html)
labels =
  doc
  |> Floki.find(~s([data-testid="surface-nav-sidebar"] a))
  |> Enum.map(&Floki.text/1)
  |> Enum.map(&String.trim/1)
```

Cover: header variants for 0 / 1 / 2+ Accounts (with and without selection), Inbound `:unavailable` not "No Accounts yet", long/Unicode/RTL/emoji/HTML-looking label wraps and is HEEx-escaped (Fjordline), group semantics (`role="group"` labelled by header; items exactly {Health, Deliveries, Inbound?}; Preview outside), **unique ids per layout** (collect all `id` attributes across the rendered document; assert no duplicates). There is currently **no ExUnit coverage** of the switcher (only Playwright), so every header variant needs a new test. Put shell_test edits below existing tests (SP-5).

---

### `mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs` (NEW; test, contract)

**Analogs:** `phase175_prohibition_contract_test.exs` (corpus + pattern sets + "detectors have teeth" + `assert_clean`) for the component/copy rules; `phase176_prohibition_contract_test.exs` (`LiveViewCase`, connected `live/2`, detector functions returning violation lists, `describe "P<n> ..."` per rule) for the route rules.

**Skeleton to copy** (phase176 `:1-44` header, `:46-` teeth, `:213-235` connected rule, `:964-1009` detector style):

```elixir
defmodule MailglassAdmin.Phase177ProhibitionContractTest do
  @moduledoc """
  Machine-checked form of the Phase 177 must-NOT prohibitions (UXF-09, UXF-10, OUTUX-06; D-19).
  ... each prohibition was additionally proven red by a temporary source mutation
  (recorded in the plan SUMMARY).
  """
  use MailglassAdmin.LiveViewCase, async: false
  @moduletag :phase177

  describe "detectors have teeth (fail-first proof)" do
    test "the P1 detector rejects a Preview with an Account picker" do
      violating = ~s(<div data-testid="operator-account-switcher"><details>...</details></div>)
      assert preview_account_control_violations(violating) != []
      assert preview_account_control_violations("<p>Scoped to an Account</p>") == []
    end
    ...
  end

  describe "P1 Preview renders no Account control" do
    test "valid return context and direct entry", %{conn: conn} do
      {:ok, _view, html} = live(conn, preview_path_with_context())
      assert preview_account_control_violations(html) == []
    end
  end
```

```elixir
# phase176 :964-975  detector style: returns a list of human-readable violations ([] == clean)
defp toolbar_violations(html) do
  doc = Floki.parse_document!(html)
  empty? = Floki.find(doc, "[data-testid='operator-empty-filtered']") != [] or ...
  if empty? and Floki.find(doc, "#operator-filters") == [],
    do: ["an empty Deliveries pane renders without the #operator-filters toolbar"],
    else: []
end
```

**Rule list (CONTEXT D-19 + UI-SPEC P1-P9), each with a teeth test and a clean-state test:**
P1 no `[data-testid^="operator-account"]` / `<details>` / `<select>` Account picker on Preview; P2 canary `return_tenant_id=zz-canary-7f3` never appears in Preview HTML outside `href` attributes; P3 no `sample data` / `demo data` / Account-data provenance claim (regex set, phase175 style); P4 operator -> Preview href has no top-level `tenant_id`; P5 Preview never inside `[data-account-scope]`, and group links are exactly the visible scoped items; P6 subtitle equals the exact UI-SPEC string; P7 no picker (`<details>`, chevron, option) with fewer than 2 Accounts; P8 `__preview_session__/2` / `__operator_session__/2` keys unchanged (reuse `router_test.exs` assertions + `refute Map.has_key?(session, "return_surface" | "return_tenant_id")`) and no Account assigns on `PreviewLive`; P9 `aria-describedby` target text omits Inbound when absent. Plus: issue order independent of count (swapped-count fixture renders identical classes and order), no severity words derived from count, every issue keeps a deep link, Back link text never contains an Account name, no `order-` class inside `operator-overview-health`, no `role="status"` on `[data-testid^="operator-health-"]` notices (scope the check; `operator-results-status` and switch status legitimately use `role="status"`, Pitfall 11).

Author every must-NOT `verification: test` (CLAUDE.md D-52). Template-level reference: `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs`.

---

### `mailglass_admin/test/mailglass_admin/health_population_test.exs` (NEW; test, golden)

**Analog:** `operator_live_test.exs` Health block. **Capture before ANY Health markup edit** (commit the golden on the pre-refactor tree; gate G5).

Existing Floki population read to adapt (`operator_live_test.exs:5705-5712`, `:5736-5737`):

```elixir
[initial_card] =
  Floki.find(
    Floki.parse_document!(html),
    "[data-testid='operator-overview-health-failures']"
  )

assert Floki.text(hd(Floki.find(initial_card, "p.mono"))) |> String.trim() == "1"   # <- breaks: counts lose `mono`; use "<testid>-count"
```

Fingerprint = list of `{data-testid, count, link href}` over `[data-testid='operator-overview-health'] [data-testid^='operator-health-deliveries-'], [data-testid^='operator-health-inbound-'], [data-testid^='operator-overview-health-']`, compared to a committed literal list. Add: swapped-counts mutation (order is count-independent), stale rows tagged "Not refreshed", inbound absent -> no inbound rows/notice/activity.

**Fixture caveat (verified):** `insert_support_summary_fixture!/0`, `insert_delivery!/1`, `operator_conn/2`, `operator_path/1`, `hours_ago/1` are `defp` in `operator_live_test.exs` and cannot be imported. The new file must define local helpers (copy phase176 `:1052-1099` for `operator_conn`/`insert_delivery!`/`hours_ago`) or use public `OperatorFixtures` (`seed_phase169_scenario!/0` `:185`, `seed_phase169_health_partial!/0` `:516`, `seed_persona_cohort!/0` `:704`, `arm_reader_fault!/3` `:628`). No single public fixture seeds all eight Health categories (4 delivery statuses + inbound failed/no_match + webhook failed/orphan); the golden plan must compose one.

---

### `mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs` (NEW; test, component)

**Analogs:** `operator/results_status_test.exs` (pure, `@moduletag :phase176`, tiny helper) and phase175 `render_component(&Mod.fun/1, assigns)` + `visible_text/1`.

Render `HealthOverview.overview/1` (and the new sub-components) directly with fixed `issues`/`activity`/`states` maps (keys `count,label,help,testid,surface,path,stale?`); assert: observation `role="group"` contains period + timestamp + Refresh; activity section follows status in DOM; no `order-` classes; no `role="status"` on notices; no `mono`/`text-heading` on counts; `min-h-11` on issue links; unavailable/stale never "No issues found"; each state in the UI-SPEC state matrix; use `Floki.text/1` for copy with apostrophes (Pitfall 6).

---

### `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` (MOD; add `@tag :phase177` table)

**Analog:** the `@tag :phase176` test at `:310-348` (a `{scenario, header_needles, card_needles}` table, `for ... <- table do`, `render_component` on production components).

```elixir
@tag :phase176
test "Phase 176 retained Inbound evidence scenarios render through production components" do
  table = [
    {:normal_contacts, ["Alex Rivera", ...], ["Reveal raw source", ...]},
    ...
  ]

  for {id, header_needles, card_needles} <- table do
    scenario = QuickViewScenarios.inbound_evidence(id)
    header = render_component(&InboundDetailHeader.detail_header/1, detail: scenario.detail, account_labels: scenario.account_labels)
    ...
```

New `@tag :phase177` tests: Health scenarios render through `HealthOverview.overview/1`; a connected assertion that the story assigns' issue population equals the LiveView-derived population for the same seed (G5). Do **not** export `health_issues/7` for the story (it is `defp`).

---

### Existing-test edits (MOD; coupled assertions that WILL break)

Per RESEARCH "Existing assertions that WILL break" (the "five" in CONTEXT is a floor). Edit deliberately, in place:

| File:line | Old | New |
|---|---|---|
| `operator_live_test.exs:4639-4640`, `persona_cohort_test.exs:116` | `"No recent mail activity"` | `"No mail activity in this period"` |
| `operator_live_test.exs:4761` | `refute html =~ "No recent mail activity"` | refute the new string (else it becomes vacuous) |
| `operator_live_test.exs:5713,5736,5782,5799` | `Floki.find(card, "p.mono")` | `"[data-testid='<testid>-count']"` |
| `operator_live_test.exs:5737` | `=~ "Last retrieved"` | `"Not refreshed"` |
| `operator_live_test.exs:5756` | `"could not be loaded"` | `"couldn't be loaded"` |
| `operator_live_test.exs:5791` | toast `"Some health data could not be refreshed."` | new toast copy |
| `operator_live_test.exs:2728` | `html =~ ~s(href="/dev/mail")` | href now carries `?return_surface=...&amp;return_tenant_id=...` when an Account is selected |
| `shell_test.exs:216` | `["Health", "Preview", "Deliveries", "Inbound"]` | `["Health", "Deliveries", "Inbound", "Preview"]` |
| `preview_live_test.exs:358-359`, `voice_test.exs:65` | `"See how your emails look in HTML and plain text."` | UI-SPEC subtitle |

`voice_test.exs:297`, `operator_live_test.exs:2568`, `inbound_live_test.exs:108` assert the body `tenant_selector` "Choose Account" label: **leave unchanged**.

---

### `mailglass_admin/e2e/phase177-{return-navigation,account,health}.spec.js` (NEW; Playwright; the single planned spec was split into three, see plans 177-01, 177-06/07, 177-08)

**Analogs:** `e2e/phase176-filters.spec.js` (login/seed helper `:8-20`, `AxeBuilder`, `WCAG_TAGS`) and `e2e/phase169-journey.spec.js` (`page.evaluate` geometry capture `:350-366`; reader-fault arming `:38-47`).

```js
// phase176-filters.spec.js:1-20  (copy the preamble and openBrowserTenant verbatim)
const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const tenantId = "browser-tenant";
const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];

async function openBrowserTenant(page, { scenario, subject, tenant = tenantId, returnPath } = {}) {
  await page.context().clearCookies();
  const reset = await page.request.get(`/ops/browser-reset${scenario ? `?scenario=${scenario}` : ""}`);
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(returnPath || `/ops/mail?tenant_id=${tenant}`);
  ...
  await page.goto(`/ops/browser-login?tenant_id=${tenant}&return_to=${returnTo}${subjectParam}`);
```

```js
// phase169-journey.spec.js:350-358  geometry pattern; replace metricColumns (:357,:367) with single-column + width check
const healthGeometry = await page.evaluate(() => ({
  viewport: window.innerWidth,
  overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
  ...
  metricColumns: getComputedStyle(document.querySelector('[data-testid="operator-overview-health"] > div:nth-child(2)')).gridTemplateColumns.split(" ").length   // <- remove
}));
...
expect(healthGeometry.metricColumns).toBe(width < 1024 ? 1 : 2);                                                         // <- remove
```

Replace with `page.getByTestId("operator-health-column")` + `getBoundingClientRect().width <= 42*16+1`. Gates to implement: G1 `scrollWidth - clientWidth <= 1`; G2 `compareDocumentPosition` vs bounding boxes; G3 observation group cohesion (gap thresholds); G4 every link/button in `operator-overview-health` >= 44px (only `field_help` >= 24x24); G6 text cues; G7 new `AxeBuilder` scan of `/ops/mail?tenant_id=browser-tenant` (and `?scenario=phase169-health-partial`, armed reader fault) with `WCAG_TAGS`, asserting zero violations (Health is **not** in the axe baseline matrix: `e2e/axe-baseline.spec.js:37-38` covers deliveries/inbound/preview only, Pitfall 8). Widths 320/390/768/1024/1280/1440; Account control visible at 320/375/768/1280/1440; Browser Back from operator returns to Preview; every issue deep link lands on a filtered view showing the matching count; Refresh focus retention. Seed scenarios: `/ops/browser-reset?scenario=phase169-health-partial` etc. (`endpoint_case.ex:140-190`). Kill any stale port-4101 server before final runs (A7).

### `mailglass_admin/e2e/support/account.cjs` (NEW; helper) and Account-selector call-site migration (MOD)

**Analog for the helper file:** `e2e/support/storybook-axe-supplement.cjs` (CommonJS under `e2e/support`, consumed via `require("./support/...")` as in `storybook-axe.spec.js:3-4`). Use `.cjs` (precedent) rather than the `account.js` name floated in RESEARCH.

**Call sites that hit strict-mode duplicates** (sidebar + mobile copies both in DOM): `flows.spec.js:845-847, 926-928, 957-962, 1049-1052, 1477-1519, 1949-1951, 2010, 2080`; `structural.spec.js:2546-2573`; `inbound-layout.spec.js:195`; `phase170-journey.spec.js:391`; `phase175-inbound.spec.js:297` (15+ references). One helper returning a `:visible`-filtered locator for `operator-account-switcher` / `-option` / `-label` / `-id` / `-switch-status`; existing precedent for visible filtering is `.filter({ visible: true })` in `flows.spec.js:371`:

```js
await page.getByTestId("operator-account-switcher").click();                    // flows.spec.js:845  <- now ambiguous
const row = page.getByTestId("operator-delivery-row").filter({ visible: true }).first();   // precedent for visible-only
```

Also re-verify (do not assume) `flows.spec.js:1298-1337` and `phase168-plan03-acceptance.spec.js:58` (`getByRole("link", {name: "Preview"|"Health"...})`): names are unchanged and "Back to Health" does not match `exact: true`.

### `reference/demo_app/assets/e2e/phase177-return.spec.js` (NEW; demo Playwright, LV 1.1.33)

**Analog:** `reference/demo_app/assets/e2e/phase176-filters.spec.js` `loginTo` helper (`:1-8`):

```js
async function loginTo(page, target) {
  await page.goto(`/demo/login?return_to=${encodeURIComponent(target)}`);
  await page.locator("[data-phx-main].phx-connected").waitFor();
}
```

Journey: log in at `/ops/mail?tenant_id=fjordline-aps&view=deliveries`, click Preview, assert "Back to Deliveries" returns to the Fjordline Deliveries view (dynamic return, not static Northstar), Browser Back from operator returns to Preview; logged-out direct entry to `/ops/mail...` goes to `/demo/login?return_to=<encoded arrival path?query>` and, after login, lands on the requested Account and surface (D-07; plan 177-10). Advisory lane (project convention).

---

### `reference/demo_app/lib/mailglass_demo_web/router.ex` (MOD) and `admin_auth.ex` (MOD) and `test/mailglass_demo_web/phase177_navigation_test.exs` (NEW)

**Router** (`router.ex:104-148`), Preview `navigation` today wraps each target in a static Northstar login redirect:

```elixir
navigation: [
  overview_path: "/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar",
  deliveries_path: "/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar%26view%3Ddeliveries",
  inbound_path: "/demo/login?return_to=%2Fops%2Fmail%2Finbound%3Ftenant_id%3Dnorthstar"
]
```

becomes `overview_path: "/ops/mail"`, `deliveries_path: "/ops/mail?view=deliveries"`, `inbound_path: "/ops/mail/inbound"` (D-07). The operator mount's `navigation: [preview_path: "/dev/mail"]` (`:140`) stays. Do **not** touch dashboard login links (`page_controller_dashboard_test.exs:20-21`, `docs_contract_test.exs:26-32`, `Makefile:84-94`, `guides/run-the-demo.md`). No pin changes; revert transitive lock drift (swoosh / phoenix / boundary) before committing (project memory).

**AdminAuth** has no logged-out `to:` today (`admin_auth.ex` read in full): every clause matches `%{actor: %{subject_id: subject_id}} when is_binary(subject_id)` and the catch-all returns only `%{message: ...}`, so logged-out hits go to `unauthorized_path: "/"` (`router.ex:146`). Add one clause above the catch-all, using the `deny/4` seam (`operator/mount.ex` `deny/4`: `to = Map.get(details, :to, opts[:unauthorized_path])`) and the test adapter's first clause as the shape precedent:

```elixir
# endpoint_case.ex TestOperatorAuth first clause (shape to mirror)
def authorize(:operator_access, %{actor: %{subject_id: nil}}) do
  {:error, :unauthorized, %{message: "Operator access requires a signed-in actor.", to: "/login"}}
end

# demo, new clause: SUPERSEDED. The plain "/demo/login" form below contradicts locked D-07.
# Plan 177-10 uses to: "/demo/login?return_to=" <> URI.encode_www_form(path_and_query) instead.
def authorize(:operator_access, %{actor: %{subject_id: nil}}),
  do: {:error, :unauthorized, %{message: "demo operator login required", to: "/demo/login"}}
```

**Superseded (revision BLOCKER 1):** the claim that the auth context lacks the request path is wrong. The context carries `socket`, and `Phoenix.LiveView.get_connect_info(socket, :uri)` returns `%URI{path: conn.request_path, query: conn.query_string}` on the disconnected render (LV 1.1.33 and 1.2.13 `conn_connect_info/2`), which is the only render a logged-out request reaches. Plan 177-10 builds `return_to` from it, falling back to `/ops/mail` plus the `tenant_id`/`view` params. The existing `safe_return_to/1` (`page_controller.ex:155-185`) validates it, so a logged-out Fjordline or Inbound return lands on the requested Account and surface (D-07). RESEARCH A1 is marked RESOLVED/REFUTED.

**Demo ExUnit test** (`phase177_navigation_test.exs`) for the new clause: a pure `AdminAuth.authorize(:operator_access, %{actor: %{subject_id: nil}, params: %{...}})` fallback assertion plus conn-level logged-out Fjordline return rows (plan 177-10), use `use MailglassDemo.ConnCase, async: false` as in `page_controller_security_test.exs:1-4`:

```elixir
test "login only redirects to local operator paths", %{conn: conn} do
  conn = get(conn, "/demo/login", %{"return_to" => "//evil.example/phish"})
  assert redirected_to(conn) == "/ops/mail?tenant_id=#{DemoData.tenant_id()}"
end
```

---

### Stories: `health_overview.story.exs`, `account_scope.story.exs`, `preview_chrome.story.exs` (NEW)

**Analog:** `reference/demo_app/storybook/delivery_investigation.story.exs` (86 lines, read in full). Copy structure exactly:

```elixir
defmodule Storybook.DeliveryInvestigation do
  @moduledoc false
  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias MailglassDemo.QuickViewScenarios
  def container, do: :iframe

  def template do
    """
    <div data-theme-owner="delivery-investigation-story" data-theme-preference="system" data-theme-resolved="light" data-theme-os="light" data-theme="mailglass-light" style="min-height: 900px" class="mg-admin-root bg-base-100 p-md text-base-content">
      ...
      <fieldset aria-label="Review theme" data-testid="delivery-investigation-review-theme" style="position: fixed; ...">
        <legend style="padding: 0 4px;">Review theme</legend>
        <label ...><input type="radio" name="delivery-investigation-review-theme" value="light" ...>Light</label>
        <label ...><input type="radio" name="delivery-investigation-review-theme" value="dark" ...>Dark</label>
        <label ...><input type="radio" name="delivery-investigation-review-theme" value="system" checked ...>System</label>
      </fieldset>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    for id <- [:northstar_complete, :fjordline_long_unicode, ...] do
      %Variation{id: id, attributes: QuickViewScenarios.delivery_investigation(id)}
    end
  end

  def render_case(assigns) do
    ~H"""
    <main data-testid="delivery-investigation-story" data-scenario-id={@scenario_id} data-state={@state} class="... mx-auto max-w-6xl space-y-md px-md pb-md">
      <header class="space-y-xs"> ... <p class="text-label text-secondary">Static rendering only. ...</p></header>
      <DetailHeader.detail_header delivery={@delivery} account_labels={@account_labels} />
      ...
    </main>
    """
  end

  def function, do: &__MODULE__.render_case/1
end
```

Per story: unique `data-theme-owner` / `*-review-theme` testid (`health-overview-story`, `account-scope-story`, `preview-chrome-story`), `data-scenario-id` / `data-state` on `<main>`, and render the **production** components (`HealthOverview.overview/1`, the Account header/`SurfaceNav.nav`). Stories are **flat top-level** files (`delivery_investigation.story.exs`, `inbound_evidence.story.exs`, URL `/dev/storybook/<name>`). RESEARCH names `storybook/operator/health.story.exs`; there is no `storybook/operator/` folder or `_operator.index.exs`, so prefer the flat naming unless the plan also adds an index file like `storybook/_primitives.index.exs`.

Variation lists (D-21): HealthOverview -> Northstar normal, Helios empty, stale, unavailable, Fjordline long/Unicode; Account control -> none, one, many, long label; Preview chrome -> valid return, direct entry. Stories prove rendering only.

### `reference/persona_spec/quick_view_scenarios.ex` + `.json` (MOD)

**Analog (builder):** `inbound_evidence/1` (`quick_view_scenarios.ex:138-169`): `Enum.find` on `entry["rendered"] == true and entry["variation_id"] == variation_id and String.starts_with?(entry["id"], "<prefix>-")`, `raise ArgumentError` on unknown id, return a map of exactly the assigns the production component accepts, plus `scenario_id`, `variation_id`, `role_job`, `state`, `proof_boundary`, `account_labels: MailglassDemo.Personas.account_labels()`.

```elixir
def inbound_evidence(scenario_id) when is_atom(scenario_id) do
  variation_id = Atom.to_string(scenario_id)

  scenario =
    Enum.find(@manifest["scenarios"], fn entry ->
      entry["rendered"] == true and entry["variation_id"] == variation_id and
        String.starts_with?(entry["id"], "inbound-evidence-")
    end)

  if is_nil(scenario),
    do: raise(ArgumentError, "unknown retained Inbound evidence scenario #{variation_id}")
  ...
```

New builders `health_overview/1`, `account_scope/1`, `preview_chrome/1`. Health scenarios must carry the issue maps (`count,label,help,testid,surface,path,stale?`), `activity`, and `states` **directly in JSON** (`health_issues/7` is private to `OperatorLive`).

**Analog (manifest object):** the `inbound-evidence-evidence-denied` scenario: keys `id, story_path, theme_owner, theme_picker_testid, variation_id, role_job, source[], cohort, state, reason, owning_requirements[], proof_boundary ("story-render-only"), feedback_ids[], rendered: true, projection{...}`. Story paths `/dev/storybook/health_overview` etc.

**Feedback entries to close** (`quick_view_scenarios.json:1253-1262` `fb-health-crowding`, `:1289-1298` `fb-account-context`; both `scenario_ids: []`, `status: "pending"`). Precedent for the closed form (`:1347-1352`):

```json
"scenario_ids": ["delivery-investigation-suppression-stale", ...],
"status": "automated",
"disposition": "Account-scoped Refresh uses a real retry and preserves retained evidence as stale on failure; ...",
"evidence_pointer": ".planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08"
```

Set `status: "automated"`, fill `scenario_ids` with the new scenario ids, rewrite `disposition`, point `evidence_pointer` at `.planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md#<anchor>`. No script validates `evidence_pointer`, but write the file. Do not blindly add scenarios to `axe_selection` (Phase 176 kept it at 20).

**Optional inventory spec:** `reference/demo_app/assets/e2e/inbound-evidence.spec.js` pattern (read manifest, assert exact retained ids, `story_path`, `theme_owner`, `theme_picker_testid`, `proof_boundary === "story-render-only"`).

---

### `177-AUTOMATION.md` and `177-HEALTH-COMPARISON.md` (NEW; planning docs)

**Analog:** `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md` (heading "Phase N automated proof and reproduction", opening disclaimer that it does not claim provider delivery / hosted CI / owner aesthetic verdict, "Reproduce and check" fenced commands, run-identity table, per-requirement anchors referenced by `evidence_pointer`). `177-HEALTH-COMPARISON.md` records the A vs B protocol results (widths 288/358/480/736/992/1152 + real main width, scenarios, G1-G7 numbers, tie-breakers, winner, reason), per UI-SPEC "Bounded comparison".

### Temporary A vs B comparison spike (NEW; throwaway)

**Analog:** `delivery_investigation.story.exs` + a story-local `composition: :a | :b` attribute. Production code gets **no** `layout` attr or toggle (D-15). Build both candidates from the same production sub-components; drive from a scratchpad Playwright spec; delete the losing candidate. Environment note (A4): demo Storybook needs the demo app booted (`mix phx.server` in `reference/demo_app` or `make demo`); not executed during research.

---

## Do-Not-Copy List (traps inside the analogs)

| Analog location | What not to carry over | Why |
|---|---|---|
| `health_overview.ex:38` | `grid gap-lg lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]` | viewport breakpoint 2:1 grid is the defect (D-14) |
| `health_overview.ex:54` | `mono ... text-heading font-bold` on counts | UI-SPEC D-16 reading: body size, no mono |
| `health_overview.ex:62,70` | links with only `py-xs` | must be `min-h-11` |
| `health_overview.ex:88` | `role="status"` on persistent notices | double-announce with toast (D-17) |
| `health_overview.ex:108` | `sm:flex-row ... lg:flex-col` | use container query `@[30rem]:` |
| `operator_live.ex:748-767` | `order-3`, `order-2`, `sm:order-none`, `contents`, `sm:ml-auto`, `text-right` | `order-*` reordering removed (D-17) |
| `shell.ex:250,259,298` | header fallback `"Choose Account"` | becomes "Choose an Account" (header only; `tenant_selector` at `:431` keeps "Choose Account") |
| `shell.ex:257-279,304-315` | unsuffixed `operator-account-switch-status-#{index}` ids | duplicate render (sidebar + mobile) |
| `shell.ex:263` | `sm:left-auto sm:right-0` menu anchoring | right-anchored popover breaks at narrow widths |
| `surface_nav.ex:8-13` | flat `@items` order with Preview second | Preview leaves the scoped run; order is Health, Deliveries, Inbound, divider, Preview |
| `sidebar.ex:394-398`, `preview_live.ex:798` | builders that rebuild the query from scratch | silently drop `return_*` (the bug) |
| `theme_controller.ex:58` | bare `String.starts_with?(path, mount_path)` | accepts `/ops/mailx` |
| `app.css:690-748` | topbar grid rules placing the Account control in a second row; eyebrow-hiding rule | contradicts the new placement and UI-SPEC |
| any class `max-w-2xl` / `max-w-xl` / `max-w-3xl` | n/a | resolves to `--spacing-*` (48px / 32px / 64px) in this repo, not rem container widths (Pitfall 1); use the named `.operator-health-column` |
| `operator_live_test.exs` private helpers | n/a | `defp`, not importable; copy phase176 helpers instead |

---

## No Analog Found

| File / Concern | Role | Data Flow | Reason / Fallback |
|---|---|---|---|
| Scope-group header with Account control inside a `role="group"` nav block (SurfaceNav + Shell) | component | request-response | No existing "control heads its nav group" component. Compose from `Shell.account_context/1` markup (header) + `Components.nav_link/nav_pill` (items) + UI-SPEC section B. |
| Container-query geometry gate suite (G1-G4, G6) as Playwright assertions | test | request-response | Existing specs measure overflow/font sizes (`phase169-journey.spec.js:350-366`) but no `compareDocumentPosition`-vs-bounding-box (DOM order = visual order), cohesion-gap, or 44px-per-link gates. Write new `page.evaluate` helpers; follow the `healthGeometry` evaluate shape. |

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/**`, `mailglass_admin/test/{mailglass_admin,support}/**`, `mailglass_admin/e2e/**`, `mailglass_admin/assets/css/app.css`, `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/docs/design-system.md`, `reference/demo_app/{lib,storybook,assets/e2e,test}/**`, `reference/persona_spec/**`, `.planning/phases/175-*`.
**Files scanned (read or grepped):** ~55.
**Upstream docs read in full:** 177-CONTEXT.md, 177-RESEARCH.md (652 lines, two pages), 177-UI-SPEC.md.
**Corrections to CONTEXT/RESEARCH picked up while mapping:**
- `ThemeController` sanitizer is at `:49-61`, not `:11-19`.
- `insert_support_summary_fixture!/0` (named as reusable in RESEARCH) is a `defp` in `operator_live_test.exs` and cannot be reused; use public `OperatorFixtures` or local copies.
- Stories in this repo are flat top-level files; `storybook/operator/` does not exist.
- E2E helper precedent is `.cjs` under `e2e/support`.
**Pattern extraction date:** 2026-10-28
