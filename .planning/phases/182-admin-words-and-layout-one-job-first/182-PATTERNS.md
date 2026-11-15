# Phase 182: Admin Words and Layout, One Job First - Pattern Map

**Mapped:** 2026-11-15
**Files analyzed:** 22 new files (plus 14 existing-file edits referenced only where a pattern shift is needed)
**Analogs found:** 22 / 22 files (3 sub-concerns inside them have no analog, listed under "No Analog Found")
**Scope:** Prioritises the NEW files. Existing-file edits are already inventoried in 182-RESEARCH.md "Blast Radius by Plan"; this file adds only the analog excerpts and the traps the mapping surfaced. Every analog path below was verified git-TRACKED (`git ls-files --error-unmatch`); no gitignored mirror path appears.

## Findings that change plan content (read first)

These were found while mapping and are NOT in 182-CONTEXT.md or 182-RESEARCH.md.

1. **`brandbook/v2/status-marks.json` (CONTEXT D-10) will turn a required core test red.** `brandbook/v2` is an `owned_dirs` entry in `brandbook/brand.pin.json`. `Mailglass.BrandPin.verify/3` (`scripts/brand_pin.exs:358-375`) reports any file in an owned dir that is not in `shipped` as `{:asset_unlisted, path}`, and `test/scripts/brand_pin_test.exs:122-126` ("verifies against the real tree") runs it in the core suite. A derived JSON has no zip member, so it cannot be a `shipped` entry. **Place it outside owned dirs**, for example `brandbook/status-marks.json` beside `brandbook/tokens.json` (the pin test and `Mailglass.BrandPin` do not enumerate `brandbook/` top level). Also `test/scripts/brand_pin_test.exs:50` forbids `mailglass-brand-book.html` anywhere in the tree, so the extractor must read the book HTML from the pinned zip in memory and never write it to disk.
2. **`catalog/` runs every spec in it.** `reference/demo_app/assets/playwright.catalog.config.cjs` sets `testDir: "./catalog"`, and the driver spawns `playwright test --config=playwright.catalog.config.cjs` with no file argument (`capture-before-catalog.cjs:509-513`). A new `catalog/phase182-journey.spec.js` would run inside the BEFORE driver (and `before-catalog.spec.js` would run inside the AFTER driver). Both spawn sites need a positional spec path.
3. **The closest analog for D-10 is `Components.logo/1` + `logo_assets_contract_test.exs`, not `status_badge`.** It already does "inline `<svg>` component, path data asserted equal to a pinned file, detectors with teeth". Copy that shape for the pane mark.
4. **`mailglass_admin` runs `test --warnings-as-errors`** (`mix.exs:216-218`). An unused `defp` helper copied from an analog test fails the whole lane. Copy only the helpers each new test calls.
5. **Conformance gates constrain every new HEEx line** (required lane `conformance_gates`, `mailglass_admin/scripts/check-conformance.sh`): TYPE-GATE (no `text-sm|xs|xl|2xl|3xl|text-base`), BOLD-GATE (no `font-medium|semibold`), GAP-GATE (no `gap-3|4|6`), HEX-GATE (no hex colour in `color...#fff` context), BADGE-GATE (no `defp badge_class`), and SPACE-GATE (no raw numeric `p-N|m-N|gap-N|space-y-N` in the eight group surfaces: `operator/support_cards.ex`, `suppression_card.ex`, `detail_header.ex`, `timeline.ex`, and the four inbound ones). The verdict block placed inside `detail_header.ex` must use `gap-sm/md/lg`, `p-md`, `space-y-sm`, never `gap-2` or `mt-1`.
6. **`OperatorFixtures.insert_delivery!/1` and `insert_event!/2` are private (`defp`, `operator_fixtures.ex:899-933`).** New seeds must be new public `def seed_phase182_*!` functions inside that module. `Delivery.changeset/1` casts `bounced_at`, `terminal`, `delivered_at`, `complained_at`, `suppressed_at` (`lib/mailglass/outbound/delivery.ex:127-131`), so `insert_delivery!(%{bounced_at: ts, terminal: true, last_event_type: :opened})` works directly.
7. **`Mailglass.Generators.delivery_fixture/1` cannot set the new projection columns** (`test/support/generators.ex:79-100` casts only tenant, mailable, stream, recipient, adapter_ref, provider, last_event_type, last_event_at, metadata, idempotency_key, status). The core projection test must insert through `Delivery.changeset/1 |> TestRepo.insert()` (as `projector_test.exs:235-249` does) or drive `Projector.update_projections/2`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/mailglass/operator/deliveries_projection_test.exs` | test (core, DB) | CRUD / read-model | `test/mailglass/operator/deliveries_test.exs` + `test/mailglass/outbound/projector_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs` | test (contract, mutation-proven) | transform / render scan | `phase175_prohibition_contract_test.exs` (+ `status_map_test.exs` for source-enumerated matrices) | exact |
| `mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs` | test (contract: render + source + JS scan) | transform / render scan | `root_theme_ownership_contract_test.exs` (+ `copy_contract_test.exs` for badge text) | exact |
| `mailglass_admin/test/mailglass_admin/phase182_journey_test.exs` | test (LiveViewTest journey + dead render) | request-response | `operator_live_test.exs` (search/patch) + `root_theme_ownership_contract_test.exs` (cookie dead render) | exact |
| `mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs` (recommended 5th file) | test (contract) | render scan | `voice_test.exs` + `phase177_prohibition_contract_test.exs` | role-match |
| `mailglass_admin/test/mailglass_admin/phase182_status_marks_test.exs` (or fold into time/status file) | test (component vs pinned JSON) | transform | `logo_assets_contract_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/after_catalog_manifest_test.exs` | test (manifest validator + `gate/1`) | batch / file-I/O | `before_catalog_manifest_test.exs` | exact |
| `mailglass_admin/test/support/catalog_validators.ex` | test-support (pure validators) | transform | helpers inside `before_catalog_manifest_test.exs` + `test/support/glyph_scan.ex` / `contrast.ex` (module shape) | exact |
| `mailglass_admin/test/support/operator_fixtures.ex` (add `seed_phase182_*!`) | test-support (fixtures) | CRUD | same file, `seed_phase169_scenario!/0` | exact |
| `reference/demo_app/lib/mailglass_demo/journey_seed.ex` | seed module | batch / CRUD | `reference/demo_app/lib/mailglass_demo/catalog_seed.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex` | utility (pure, total) | transform | `mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex` | exact |
| `mailglass_admin/test/mailglass_admin/operator/mailer_name_test.exs` | test (unit) | transform | `preview/scenario_label_test.exs` | exact |
| `brandbook/status-marks.json` (NOT under `brandbook/v2`, see Finding 1) | config / pinned data | file-I/O | `brandbook/brand.pin.json` (provenance fields) + `brandbook/tokens.json` | role-match |
| `scripts/brand_status_marks.exs` | script (extract + verify) | file-I/O / batch | `scripts/brand_pin.exs` (`read_members/3`, `sha256_hex/1`, `cli/2`) | role-match |
| `Components.status_mark/1`, `Components.delivery_badge/1` (edit `components.ex`) | component | request-response | `Components.logo/1` (inline svg) + `Components.status_badge/1` | exact |
| `Components.verdict/1` (edit `components.ex`) + `Copy.verdict/2`, `cause_sentence/1`, `cause_or_fallback/1`, `orphan_count_label/1` (edit `copy.ex`) | component + pure data | transform | `Copy` comprehension-generated clauses (`copy.ex:148-152`) + `Components.outcome_badge/1` | role-match |
| `Components.timestamp/1` format (edit) | component | transform | itself (`components.ex:1518-1619`) | exact |
| Assets JS `FMT` (edit `controllers/assets.ex:104-128`) | JS (embedded) | event-driven | itself | exact |
| `reference/demo_app/assets/catalog/capture-before-catalog.cjs` after- mode | script (driver) | batch / file-I/O | itself | exact |
| `reference/demo_app/assets/catalog/phase182-journey.spec.js` | e2e (advisory, evidence producer) | request-response | `catalog/before-catalog.spec.js` (+ `e2e/persona-screenshots.spec.js` header) | exact |
| `.planning/research/brand-v2-adoption/after-catalog/after-<sha7>-<stamp>/` (+ `review/`) | evidence | file-I/O | `before-catalog/before-9eb9dee-20261115T022124Z/` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` split (existing) | component wrapper | request-response | itself + `FORM-DRIFT-GATE` | exact |

---

## Pattern Assignments

### `test/mailglass/operator/deliveries_projection_test.exs` (core test, read-model)

**Analogs:** `/Users/jon/projects/mailglass/test/mailglass/operator/deliveries_test.exs`, `/Users/jon/projects/mailglass/test/mailglass/outbound/projector_test.exs`

**Header and aliases** (`deliveries_test.exs:1-5`):
```elixir
defmodule Mailglass.Operator.DeliveriesTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Generators
  alias Mailglass.Operator.Deliveries
```
Name the new module `Mailglass.Operator.DeliveriesProjectionTest`. `Mailglass.DataCase` (`test/support/data_case.ex`) checks out the sandbox and stamps `"test-tenant"`; always pass an explicit unique `tenant_id` (the existing file uses `"summary-tenant"`, `"tenant-exact"`) so `async: true` rows never collide.

**Seeding the new columns (D-05 test 1).** `delivery_fixture/1` cannot set them, so insert through the changeset (`projector_test.exs:235-249`):
```elixir
defp insert_delivery(overrides \\ %{}) do
  attrs =
    Map.merge(
      %{
        tenant_id: "test-tenant",
        mailable: "MyApp.UserMailer.welcome/1",
        stream: :transactional,
        recipient: "user@example.com",
        last_event_type: :queued,
        last_event_at: DateTime.utc_now()
      },
      overrides
    )

  attrs |> Delivery.changeset() |> TestRepo.insert()
end
```
For the bounce-then-open history prefer driving the real projector so `terminal` and `bounced_at` are what production writes (`projector_test.exs:11-21`, `:119-128` pattern):
```elixir
{:ok, delivery} = insert_delivery()
{:ok, after_bounce} = delivery |> Projector.update_projections(build_event(:bounced)) |> TestRepo.update()
{:ok, after_open}   = after_bounce |> Projector.update_projections(build_event(:opened)) |> TestRepo.update()
```
(`build_event/2` builds a `%Mailglass.Events.Event{id: Ecto.UUID.generate(), type:, occurred_at:, normalized_payload: %{}, metadata: %{}}`, `projector_test.exs:253-260`.) The projector sets `bounced_at` once (`projector.ex:112-120`) and latches `terminal` one way on `delivered|bounced|complained|rejected|failed|suppressed` (`projector.ex:48`, `:126-134`).

**Core read pattern under test** (`deliveries.ex:70-87` for groups, `:119-135` for projection; both edited by D-05). Assertion shape to copy (`deliveries_test.exs:32-44`, `:316-361`):
```elixir
page = Deliveries.list_recent_deliveries_page(%{tenant_id: "summary-tenant", provider: "postmark"}, per_page: 1)
assert Enum.sum(Enum.map(page.outcome_groups, & &1.count)) == 3
assert MapSet.new(Enum.map(page.outcome_groups, & &1.last_event_type)) == MapSet.new([...])

assert %{id: id, tenant_id: "tenant-exact", ...} =
         Deliveries.get_delivery(%{tenant_id: "tenant-exact", delivery_id: target.id}, [])
```
Additive-only guard (D-05 test 4): assert the OLD keys (`id tenant_id mailable stream recipient subject provider provider_message_id status last_event_type delivery_confirmed last_event_at inserted_at`) are present with `Map.has_key?/2`, never `Map.keys(row) == [...]` (CONTEXT: "do not pin the exact key set").

**Traps:** (a) RESEARCH C-4: in `outcome_groups`, assert the producer never emits `false` for `bounced_at`/`complained_at`/`suppressed_at` (value must be `true` or `nil`): `refute Enum.any?(page.outcome_groups, &(Map.get(&1, :bounced_at) == false))`. (b) `scripts/check_test_exceptions.sh` scans `test/mailglass`: no `@tag :skip`, `@tag :flaky`, `Process.sleep(`, `pg_sleep(`. (c) Mutation evidence (drop `bounced_at`, then `terminal`, from the select) is recorded in the plan SUMMARY, not in the file.

---

### `mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs` (contract test, render scan)

**Analog:** `/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs` (the METHODOLOGY mutation template named in D-17), with `status_map_test.exs` for source-enumerated universes.

**Module header, imports** (`phase175...:17-23`):
```elixir
use ExUnit.Case, async: true

import Phoenix.LiveViewTest

alias MailglassAdmin.Inbound.ReplayModal, as: InboundReplayModal
alias MailglassAdmin.InboundLive
alias MailglassAdmin.Operator.{RepairState, ReplayAction, ReplayModal, SuppressionCard}
```
For Phase 182 alias `MailglassAdmin.{Components, Copy}`, `MailglassAdmin.Operator.{QuickView, DetailHeader, Timeline, SuppressionCard}`, `Mailglass.Events.Event`, `Mailglass.Suppression.Entry`, `Mailglass.Outbound.Delivery`.

**Pattern sets + "detectors have teeth" block** (`phase175...:25-93`) is the structure to copy verbatim in shape:
```elixir
@retry_pressure [
  ~r/automatic(ally)? retr/i,
  ~r/will retry/i,
  ~r/retrying (in|now|automatically)/i,
  ...
]

describe "detectors have teeth (fail-first proof)" do
  test "every pattern set rejects a known violation" do
    for {patterns, violation} <- [
          {@retry_pressure, "Replay failed. We will retry automatically."}
        ] do
      assert violations(violation, patterns) != [],
             "pattern set must catch #{inspect(violation)}"
    end
  end

  test "negated disclaimers are not mistaken for claims" do
    assert violations("This replay was not sent.", @delivery_outcome_claims) == []
  end
end
```
Phase 182 pattern set (D-19): `next try`, `will retry`, `retrying`, `retry window`, `we'll try again`, `try again (at|in)`, `automatic`, a clock-time shape after "try", with a negation guard for "not retried". The allow-list (D-19): "Retry details" (`operator_live.ex:859`), "Retry suppression read" (`suppression_card.ex:118`), "Retry replay review" (`replay_action.ex:81`), inbound "Retry messages", "before retrying" (`inbound_live.ex:1231`). Prove the allow-list by a teeth case that a bare `/retr/` ban would flag them.

**Visible-text and matching helpers** (`phase175...:428-456`; copy only what is called, Finding 4):
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
    assert hits == [], "#{label}: #{inspect(Enum.map(hits, &Regex.source/1))} matched #{inspect(text)}"
  end
end
```

**Source-enumerated matrix (never hand-copied lists).** `status_map_test.exs:56-83` and `:206-211`:
```elixir
defp universe do
  (Event.__types__() ++ Ecto.Enum.values(Delivery, :status) ++ Delivery.__event_types__() ++ ...)
  |> Enum.uniq() |> Enum.sort()
end

defp grid do
  for status <- Ecto.Enum.values(Delivery, :status),
      last <- [nil | Event.__types__()],
      confirmed <- [true, false],
      do: row(status, last, confirmed)
end
```
Phase 182 matrix: `[nil | Event.__reject_reasons__()]` (7 values, `event.ex:137`) x `[:bounced, :rejected, :failed, :deferred, :delivered]`, plus `[nil | Entry.__reasons__()]` (`entry.ex:138`). Assert `cell_count == product of the enumerated sizes`, and positive assertions: non-nil reason shows its own cause word; nil on Failed/Bounced/Not sent shows EXACTLY `"No reason was recorded for this email."`; nil on Delivered shows no cause line; Quick view shows NEITHER a cause word NOR the fallback (RESEARCH C-3).

**Structural rule (D-04).** Copy the generation style of `Copy` (`copy.ex:148-152`) for `cause_sentence/1`: a comprehension over the enum with no `nil` clause, so the test can `assert_raise FunctionClauseError, fn -> apply(Copy, :cause_sentence, [nil]) end` (call through `apply/3` as `status_map_test.exs:86-88` does, "so the compiler's type checker does not see a literal"):
```elixir
for {atom, %{label: label, icon: icon, class: class}} <- @statuses do
  def status_label(unquote(atom)), do: unquote(label)
  ...
end
```
and `copy_contract_test.exs:548-552` for the raise assertion style:
```elixir
for fun <- [:status_label, :status_icon, :status_class], value <- [nil, :subscribed] do
  assert_raise FunctionClauseError, fn -> apply(Copy, fun, [value]) end
end
```

**Rendering call shape** (`phase175...:408-414`): `render_component(&SuppressionCard.suppression_card/1, suppression_state: state, read_state: read_state) |> visible_text()`. For Full detail use `render_component(&DetailHeader.detail_header/1, ...)`; the Quick view component is `MailglassAdmin.Operator.QuickView.quick_view/1` (`quick_view.ex:26-39`, required attrs `full_path`, `close_path`).

**Mutations to record in the plan summary (D-19):** interpolate a nil reason; add "will retry" to the Delayed copy; delete an enum clause; skip a reason in the matrix; render the fallback on Quick view.

---

### `mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs` (contract test: render scan + source scan + JS check)

**Analog:** `/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs` (three-layer: dead-render document counts, static scan, teeth). It is the template for the source-scan layer, vacuity floor, and pure `(path, source)` detectors fed planted violations.

**Header** (`root_theme_ownership...:28-45`):
```elixir
use MailglassAdmin.LiveViewCase, async: false

@theme_cookie MailglassAdmin.Theme.cookie_name()
@tenant_id "test-tenant"
@lib_dir Path.expand("../../lib", __DIR__)
@root_layout "mailglass_admin/layouts/root.html.heex"
```
`MailglassAdmin.LiveViewCase` (`test/support/live_view_case.ex`) provides `@endpoint`, `live/2`, `get/2`, per-test sandbox owner, `conn:`.

**Source scan with vacuity floor** (`root_theme_ownership...:129-139`):
```elixir
test "only the root layout owns the theme and nothing under lib re-declares tokens" do
  sources = lib_sources()

  assert length(sources) > 30,
         "the lib glob found #{length(sources)} files; the scan is vacuous"

  assert List.keymember?(sources, @root_layout, 0), "#{@root_layout} is missing from the scan"
  assert scan(sources) == [], format_violations(scan(sources))
end
```
`lib_sources/0` (`:287-294`): `@lib_dir |> Path.join("**/*.{ex,heex}") |> Path.wildcard() |> Enum.sort() |> Enum.map(&{Path.relative_to(&1, @lib_dir), File.read!(&1)})`. Phase 182 scan: `strftime`, `to_iso8601`, `DateTime.to_string`, and hand-written `class="badge` only in `components.ex`, `copy.ex` and the named allow-list (`results_status.ex`, `support_cards.ex`, `preview_live.ex:1184`). RESEARCH C-5 adds three non-status chips to allow-list by file (`operator/suppression_card.ex:36`, `inbound/timeline.ex:84`, `inbound/routing_trace.ex:58`) and recommends `data-mg-status` on genuine status badges so the render scan targets `[data-mg-status]`, not `.badge`.

**Pure detectors fed planted violations (teeth)** (`:149-222`):
```elixir
test "a nested theme attribute is flagged in every spelling, in any file" do
  for planted <- [~s|<div data-theme="mailglass-light">|, ...] do
    assert [%{rule: :nested_theme_owner, line: 1}] =
             scan_source("mailglass_admin/preview/tabs.ex", planted),
           "planted violation was not flagged: #{planted}"
  end
end

test "reads, state markers and unrelated properties are not flagged" do
  for clean <- [~s|<div data-theme-owner="preview-authoring-story">|, ...] do
    assert [] = scan_source("mailglass_admin/components.ex", clean), "clean control was flagged: #{clean}"
  end
end
```
and the violation record + message (`:244-282`): `%{rule: :x, path:, line:, text: String.trim(text)}`, with `format_violations/1` naming file, line and the fix.

**Zone-token render scan (D-18 layer 1).** Visible-text helper as in `copy_contract_test.exs:354-360` (script-stripped; also drop hidden tooltip nodes `[role=tooltip]`, `[data-copy-value]` text, and the `datetime` attribute). Zone token regex per RESEARCH C-14: `UTC`, `[A-Z]{2,5}`, `[+-]\d{4}`, `GMT[+-]\d`. Each `<time>` must have `datetime` and visible text ending in a zone token.

**Badge scan** (`copy_contract_test.exs:362-367`):
```elixir
defp badge_text(status) do
  (&Components.status_badge/1)
  |> render_component(status: status, size: :sm)
  |> visible_text()
  |> String.trim()
end
```
Phase 182 asserts each `[data-mg-status]` has exactly one `aria-hidden="true"` mark and a visible word in `Copy.statuses()` labels or `Copy.class_labels()`.

**Screen registry (D-18 layer 2).** No existing analog in the repo (grep for `Router.routes`, `__live__`, `__components__` found only `status_map_test.exs:71`), use the recipe verified in RESEARCH Pattern 4: `Phoenix.Router.routes(MailglassAdmin.TestAdopter.Router)` and `route.metadata.phoenix_live_view = {mod, action, opts, extra}`; `Code.ensure_loaded?(m)` BEFORE `function_exported?(m, :__live__, 0)`; reverse check over `:application.get_key(:mailglass_admin, :modules)`. The router under test is `test/support/endpoint_case.ex:9-60` (mounts at `/dev/mail`, `/ops/mail`, `/alt/dev/...`, `/secure/console`). Floor assertion on scanned `<time>`/badge counts to prevent a vacuous pass.

**JS static check.** `MailglassAdmin.Controllers.Assets.js_body/0` is public (`assets_test.exs:164-175` calls it), so the `FMT` check reads the real served bytes:
```elixir
admin_js = MailglassAdmin.Controllers.Assets.js_body()
assert admin_js =~ "window.MailglassAdminHooks"
```
extract `const FMT = {...}` with a regex over `admin_js` and assert it contains `timeZoneName`. Mutation: remove `timeZoneName` from `assets.ex:108-111`.

**Mutations to record (D-18):** drop " UTC" from `utc_string`; add a bare `<time>` in a new component; make a badge icon-only; hardcode `<span class="badge">` in a LiveView; remove `timeZoneName`; add a registry-missing LiveView module; set a mark `aria-label`; emit a `false` flag.

---

### `mailglass_admin/test/mailglass_admin/phase182_journey_test.exs` (LiveViewTest journey + cookie dead render)

**Analogs:** `/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs` (search/patch idiom, fixtures) and `root_theme_ownership_contract_test.exs` (cookie dead render, `operator_conn`, `with_theme`).

**Header** (`operator_live_test.exs:1-22`):
```elixir
use MailglassAdmin.LiveViewCase, async: false

alias MailglassAdmin.TestSupport.OperatorFixtures
alias MailglassAdmin.TestRepo

@tenant_id "test-tenant"
@base_path "/ops/mail"
```
NOTE: `OperatorFixtures` seeds tenant `"browser-tenant"` (`operator_fixtures.ex:13`), `operator_live_test.exs` uses `"test-tenant"`. The new `seed_phase182_*!` must pick one deliberately and the test's `operator_conn/1` session `"tenant_id"` and the URL `tenant_id` param must match it.

**Search-commit idiom (D-20: "`render_change` on the filter form asserts the `?search=` patch").** The repo's established way is the helpers at `operator_live_test.exs:4214-4235` (private, copy them), used at `:3072-3079`:
```elixir
defp filter_change(field, overrides) do
  %{
    "_target" => ["filters", field],
    "filters" =>
      Map.merge(%{"search" => "", "window_hours" => "168", "event" => "", "provider" => ""}, overrides)
  }
end

defp assert_patch_kind(view, kind) do
  %{proxy: {ref, topic, _pid}} = view
  assert_receive {^ref, {:patch, ^topic, %{kind: ^kind, to: to}}}
  to
end
...
render_hook(view, "validate_filters", filter_change("search", %{"search" => "a"}))
assert_patch_kind(view, :push)
```
Form-submit alternative (`operator_live_test.exs:188-207`):
```elixir
view
|> form("#operator-filters", filters: %{"provider" => "postmark", "window_hours" => "168"})
|> render_submit()
assert_patch(view, operator_path(%{"tenant_id" => @tenant_id, ..., "view" => "deliveries"}))
```
Keep id `filters_search` and form id `operator-filters` (RESEARCH C-6: 18 e2e uses plus `operator_live_test.exs:3518,4235`). The search input carries `phx-debounce="300"`, `phx-hook="FilterSearchSync"` (`:3510-3525`).

**Summary and row selectors.** Summary section `data-testid="operator-delivery-summary"` with stat cards `id="delivery-summary-<key>"` (`operator_live.ex:997-1026`; keys `:delivered :attention :awaiting`). Row selector `[data-testid='operator-delivery-row']` (`operator_live_test.exs:35`); Quick view `[data-testid="operator-quick-view"]`, full link `[data-testid="operator-quick-view-full"]` (`:462`); detail header `[data-testid='operator-detail-header']` (`:929`), detail container `#delivery-detail-<id>` (`:971`). Open a row: `view |> element(".operator-deliveries-table button[phx-value-id='#{delivery.id}']") |> render_click()` (`:442`).

**Dead-render theme assertion (D-20: `get(conn, path)` with cookie).** Copy verbatim from `root_theme_ownership_contract_test.exs:306-343` (these helpers are private there):
```elixir
defp assert_root_only(html, count, value, surface) do
  owners = html |> Floki.parse_document!() |> Floki.find("[data-theme]")
  occurrences = length(Regex.scan(~r/\sdata-theme=/, html))
  assert length(owners) == count and occurrences == count, "..."
  case owners do
    [] -> :ok
    [{tag, attrs, _children}] ->
      assert tag == "html"
      assert List.keyfind(attrs, "data-theme", 0) == {"data-theme", value}
  end
end

defp with_theme(conn, nil), do: conn
defp with_theme(conn, cookie),
  do: Plug.Conn.put_req_header(conn, "cookie", "#{@theme_cookie}=#{cookie}")
```
with modes `[{"dark", 1, "mailglass-dark"}, {"light", 1, "mailglass-light"}, {nil, 0, nil}]` (`:40-44`) and `operator_conn/2` (`:319-343`). The existing file already covers `/ops/mail?tenant_id=...` for all three modes; the Phase 182 test adds the same on the JOURNEY detail route (`...&view=deliveries&delivery_id=<id>&full=1`) so the claim is made for the screen this phase changed. Use `html_response(conn, 200)` after `get/2`, since LiveViewTest does not render the root layout (CONTEXT D-20).

**Fixtures.** Add `def seed_phase182_journey!/0` to `operator_fixtures.ex` following `seed_phase169_scenario!/0` (`:185-230`): `reset!()` first, insert rows through the private helpers, return a map of ids. Required rows (D-16): password-reset Sent-no-report, bounce, bounce-then-open (`bounced_at` set, `terminal: true`, `last_event_type: :opened`), nil-reason bounce, deferred, suppressed (with an `insert_suppression!/1` row so the card renders), complained. Use module-only `mailable:` like production (`"Mailglass.Example.BrowserMailer"` style, RESEARCH C-9) plus one `Module.function` row for the seeded plain-name case; reserved `@example.com` recipients only.

**Mutations to record:** delete the Sent rule line; drop `bounced_at` then `terminal` from the projection select; reorder detail so the timeline precedes the verdict (assert DOM order); omit the search patch; emit `bounced_at: false` from `outcome_groups`.

---

### `mailglass_admin/test/mailglass_admin/phase182_status_marks_test.exs` (component equals pinned JSON)

**Analog:** `/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs` (and `Components.logo/1`, `components.ex:73-102`).

**Moduledoc + shape to copy** (`logo_assets_contract_test.exs:1-37`, `:40-70`): explicit lane statement ("Required lane: `support_contract_admin`"), a "what is proven" list, "The checks are pure `(input) -> [failure]` functions and the detectors-have-teeth block plants one violation per check". Setup:
```elixir
use ExUnit.Case, async: true
import Phoenix.LiveViewTest, only: [render_component: 2]
alias MailglassAdmin.Components
alias MailglassAdmin.TestSupport.Contrast

@admin_root Path.expand("../..", __DIR__)
@repo_root Path.expand("..", @admin_root)
@tokens_path Path.join(@repo_root, "brandbook/tokens.json")

setup_all do
  %{rendered: render_component(&Components.logo/1, class: "h-6 w-auto shrink-0"), ...}
end
```
**Rendered-markup parse** (`:336-368`; note Floki lower-cases attribute names, hence `"viewbox"`):
```elixir
defp pinned_paths(svg) do
  ~r/<path fill="([^"]*)" d="([^"]*)"\/>/ |> Regex.scan(svg) |> Enum.map(fn [_all, fill, d] -> {fill, d} end)
end

defp parse_logo(markup) do
  [svg] = markup |> Floki.parse_fragment!() |> Floki.find("svg")
  paths = svg |> Floki.find("path") |> Enum.map(...)
```
and the pure comparison (`:381-`): `path_identity_failures(rendered, light, dark)` returning `[String.t()]`. For marks: load `brandbook/status-marks.json` with `Jason`, render each of the five marks through `Components.status_mark/1`, and assert every `x y width height d stroke-width` and the role-to-`--mg-color-*` mapping equal the JSON. Role mapping binds to `contrast_contract_test.exs:76-92` `@book_binding` (`"status-sent" => {"text","surface"}`, `"status-delivered" => {"success-text","surface"}`, `"status-delayed" => {"warning-text","surface"}`, `"status-failed" => {"error-text","surface"}`, `"status-notsent" => {"text-muted","surface"}`).

**Contrast reuse (do not hand-roll WCAG math).** `MailglassAdmin.TestSupport.Contrast.ratio/2` and `resolve_tokens/1` (`test/support/contrast.ex`) with `brandbook/tokens.json`; the 3:1 mark-vs-surface assertion for light and dark sits beside the existing status pairs.

**Component pattern for `Components.status_mark/1`** (copy the inline-svg structure of `logo/1`, `components.ex:73-102`; attributes, not CSS classes, so no bundle rebuild):
```heex
<svg width="17" height="20" viewBox="0 0 100 120" aria-hidden="true" focusable="false">
  <rect width="100" height="120" fill="var(--mg-color-success-text)"/>
  <path d="M24 62L43 82L77 38" fill="none" stroke="var(--mg-color-surface)" stroke-width="13"/>
</svg>
```
Geometry for all five marks is in RESEARCH "Pane-mark geometry" (extracted from the pinned book). The mark is `aria-hidden="true"`, no `aria-label`, no `title` (D-10). Wrap in the existing `badge badge-outline` (in the bundle; `badge-ghost` is NOT) via `Components.status_badge/1`'s structure (`components.ex:1363-1369`):
```heex
<span class={["badge text-label whitespace-nowrap", size_class(@size), status_class(@status)]}>
  <span class={[status_icon(@status), "w-3 h-3"]} aria-hidden="true"></span>{status_label(@status)}
</span>
```
Register a gallery specimen for every new component: `gallery_live.ex:195-197` (`defp render_specimen(%{component: :status_badge} = assigns)`) and the specimen tuples at `:636-642` (`{:status_badge, "delivered", %{status: :delivered, size: :sm}}`).

---

### `mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs` (recommended; BRADM-03/04/05 teeth)

**Analogs:** `voice_test.exs` (script-stripped render scan across Preview/Operator/Inbound, `@banned_words` list, `strip_scripts/1`) and `copy_contract_test.exs:679-703` (vocabulary binding).

**Vocabulary binding pattern** (`copy_contract_test.exs:679-689`):
```elixir
test "every wired entry's on-screen word appears in a string literal outside Copy" do
  literals = scanned_files() |> Enum.flat_map(&(&1 |> File.read!() |> strip_noise() |> quoted_literals()))

  for %{wired: true, on_screen: word} <- Copy.vocabulary() do
    assert Enum.any?(literals, &String.contains?(&1, word)),
           "#{inspect(word)} is marked wired in Copy.vocabulary/0 but no screen string uses it"
  end
end
```
Flipping `:admin`, `:activity`, `:unmatched_reports` to `wired: true` (`copy.ex:80-109`) makes this test bind them automatically. Also update `copy_contract_test.exs:620-622` and `:702` (`assert Enum.all?(Copy.class_labels(), &(&1.wired == false))`) per RESEARCH C-8 (Part B rewrite to the row-level class badge).

**`wired_class_violations/1` (the pin that bites Plan 2)** (`copy_contract_test.exs:454-463`):
```elixir
defp wired_class_violations(class_labels) do
  for %{wired: true, class: class, label: label} <- class_labels,
      atom <- Map.keys(Copy.statuses()),
      StatusMap.classify(atom) == class,
      text = badge_text(atom),
      text != label or Enum.any?(@retired_words, &String.contains?(text, &1)),
      do: {class, atom, text}
end
```
Rewrite to bind the ROW-LEVEL class badge (render the new class badge for an exemplar row per class; word must equal the class label), keep the teeth case at `:515-522` meaningful.

**Render-scan pattern from `voice_test.exs:36-52`:**
```elixir
{:ok, _view, html} = live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")
lower = html |> strip_scripts() |> String.downcase()
Enum.each(@banned_words, fn word -> refute lower =~ word, "..." end)
```
For BRADM-03 refute "Deliveries" as a visible/aria noun on registered screens except the single gloss line.

---

### `mailglass_admin/test/mailglass_admin/after_catalog_manifest_test.exs` and `mailglass_admin/test/support/catalog_validators.ex`

**Analog:** `/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs` (1,615 lines; every validator is `defp`, RESEARCH C-11).

**Extract ONLY the pure helpers into `catalog_validators.ex`** (module shape: `MailglassAdmin.TestSupport.GlyphScan` / `Contrast`, moduledoc "compiled from `test/support` (`elixirc_paths(:test)`), so it never ships in the Hex tarball"; admin `mix.exs:87`). Candidates, with source lines:

- `check/2` (`:1227-1229`), `exact_keys/3` (`:1231-1243`), `hex?/2` (`:1245-1246`), `non_empty?`, `list/1`, `pos_int?`, `parse_time/1`
- `sha256/1` and `git_blob_sha/1` (`:1256-1263`)
```elixir
defp sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

# The same blob hash `git hash-object` computes: sha1("blob <size>\0" <> bytes).
defp git_blob_sha(bytes) do
  Base.encode16(:crypto.hash(:sha, ["blob ", Integer.to_string(byte_size(bytes)), 0, bytes]), case: :lower)
end
```
- `read_json/1` (`:1265-1276`), `files_under/1` + `confined/2` (`:910-925`), `png_header_failures/3` (`:845-867`, IHDR + CRC32 check), `binding_state/2` (`:963-989`, LIVE vs SUPERSEDED against the working-tree bytes).

Leave the before test's rules and `@case_slugs`-specific code untouched (CONTEXT: "`before_catalog_manifest_test.exs` stays green"). Switch the before test to call the shared helpers only if the diff stays mechanical; otherwise duplicate the ~6 helpers in the new support module and leave the before test alone (lower risk, RESEARCH C-11 allows a thinner validator).

**Shape of the top-level validator** (`:492-511`):
```elixir
defp validate_catalog(dir, opts \\ []) do
  repo_root = Keyword.get(opts, :repo_root, @repo_root)
  case read_json(Path.join(dir, "manifest.json")) do
    {:ok, manifest} when is_map(manifest) ->
      shape_failures(manifest, dir) ++ file_failures(manifest, dir) ++ budget_failures(manifest, dir) ++
        binding_failures(manifest, dir, repo_root) ++ ... ++ privacy_failures(dir)
    {:ok, _other} -> ["manifest.json must be a JSON object"]
    {:error, reason} -> ["manifest.json is unreadable: #{inspect(reason)}"]
  end
end
```
Every validator returns `[String.t()]`; the committed-catalog test asserts `failures == []` with `failure_message/2` (`:513-520`), the teeth block feeds a synthetic catalog built in a tmp dir by `fixture/1` (`:1314-1360`, tmp repo root holding copies of `@bundle_rel` and `@layout_rel`, `tiny_png/3`, `update_manifest/2`) and uses `assert_red(failures, fragment)` (`:1294-1298`).

**Adapt for the AFTER catalog (differences the planner must encode):**
- Root `.planning/research/brand-v2-adoption/after-catalog/`; id regex `\Aafter-[0-9a-f]{7}-\d{8}T\d{6}Z\z` (before test hard-codes `before-`, `:534`); schema string `mailglass.after_catalog.v1`; a new top-level key set that adds `review` (the before `@top_keys` are closed, `:94-95`).
- `unlisted_failures/2` (`:896-907`) allows only `manifest.json, cases.json, superseded.json` + listed PNG/aria; the after catalog must additionally allow `review/rubric.md`, `review/verdicts/<scenario_id>.<judge>.json`, `review/review-manifest.json`, each bound by sha256 in `review-manifest.json`.
- Binding: same LIVE/SUPERSEDED rule against current `app.css` sha256 and root-layout blob (`:963-1022`, marker validation `:1024-1080`). The after catalog is captured LAST, so it should be LIVE on merge; the before catalog's `superseded.json` (`superseded_by.bundle_sha256` `8c57857f...b89b`, `root_layout_git_blob_sha` `c89fca34...7b519`, file at `.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json`) must be updated in the same change as any bundle edit (D-23).
- Verdict schema `{scenario_id, judge, order, verdict: pass|reject, rules: [{id, ok, evidence_quote, screenshot_region}], reasons}`; `evidence_quote` must be a literal substring of the aria sidecar (aria sidecars look like `- heading "Deliveries" [level=1]`, `aria/<id>.yml`); a pass citing no rule is rejected; pure `gate/1` unit-tested (two judges per scenario, any reject blocks, red on missing/invalid verdict or failed calibration, calibration known-bads must reject).
- Provenance precedent for closed-key verdict/approval schemas and a self-comparison rejection: `mailglass_admin/e2e/support/storybook-axe.cjs` (`exactKeys`, `validateApproval`, "report and approved findings use the same evidence run (self-comparison)", `:330-406`).
- Privacy: reuse `unreserved_emails/1` (`:1190-1223`) and the reset-token check.

**Teeth (D-21):** flip a verdict to pass; add an unlisted file; plant a hallucinated quote; drop the calibration set; make a known-bad calibration pass. The test must land in the same PR as the catalog because `.planning`-only PRs skip the admin lane (before test moduledoc `:6-10`).

---

### `reference/demo_app/lib/mailglass_demo/journey_seed.ex` (seed module)

**Analog:** `/Users/jon/projects/mailglass/reference/demo_app/lib/mailglass_demo/catalog_seed.ex` (330 lines). Mirror its structure exactly; RESEARCH C-10: do NOT edit `catalog_seed.ex`, `demo_data.ex`, or `personas.ex` (persona drift guard, before-catalog test reads `catalog_seed.ex` text).

**Imports/aliases and constants** (`catalog_seed.ex:30-37`):
```elixir
import Ecto.Query, only: [from: 2]

alias Mailglass.Events.Event
alias Mailglass.Outbound.Delivery
alias MailglassDemo.Repo

@tenant "northstar"
@sentinel "CATALOG_CASES_JSON="
```
Use `@sentinel "JOURNEY_CASES_JSON="` (distinct) and expose `def sentinel, do: @sentinel`.

**Entry point** (`:60-82`): `seed!/0` takes `anchor = DateTime.utc_now() |> DateTime.truncate(:second)`, builds rows, `verify_seeded!(cases)`, then `IO.puts(@sentinel <> Jason.encode!(payload))`.

**Row builder + projector** (`:197-235`) is the load-bearing part (it keeps `bounced_at`/`terminal` consistent, which is exactly what the bounce-then-open row needs):
```elixir
defp delivery!(attrs) do
  defaults = %{tenant_id: @tenant, adapter_ref: Delivery.default_adapter_ref(), terminal: false,
               idempotency_key: "demo-delivery-#{attrs[:provider_message_id]}"}
  defaults |> Map.merge(attrs) |> Delivery.changeset() |> Repo.insert!()
end

# Mirrors DemoData.event!/4: insert the ledger event, then project it onto the
# delivery so `terminal` and the lifecycle timestamps stay consistent.
defp event!(delivery, type, occurred_at, metadata, opts \\ []) do
  key_source = Keyword.get(opts, :key_id, delivery.provider_message_id)
  event =
    %{tenant_id: @tenant, delivery_id: delivery.id, type: type, occurred_at: occurred_at,
      reject_reason: Keyword.get(opts, :reject_reason),
      idempotency_key: "demo-event-cat-#{key_source}-#{type}-#{DateTime.to_unix(occurred_at)}",
      metadata: metadata, normalized_payload: %{"recipient" => delivery.recipient}}
    |> Event.changeset() |> Repo.insert!()

  Repo.get!(Delivery, delivery.id) |> Mailglass.Outbound.Projector.update_projections(event) |> Repo.update!()
  event
end
```
Use different id prefixes (`pm-jrn-`, `demo-delivery-jrn-`, `demo-event-jrn-`) so nothing collides with `pm-cat-` / `pm-demo-`. Example row builder shape (`:84-112`, `typo_bounce!`): `delivery!(%{mailable: "MailglassDemoWeb.Mailers.AccountMailer.password_reset", stream: :transactional, recipient: "...@northstar.example", provider: "postmark", provider_message_id: "pm-jrn-...", status: :sent, last_event_type: ..., last_event_at: minutes_ago(anchor, N), metadata: %{"scenario" => "journey_...", "subject" => "..."}})` then `event!/5` for `:sent`, `:bounced` (with `reject_reason: :invalid`), and a later `:opened` for bounce-then-open.

**Read-back verification** (`:261-327`): `case_entry/2` reads values back from the stored row, never restates insert attrs; `verify_seeded!/1` + `expect!/3` raise on mismatch. Keep the same discipline, including a nil `reject_reason` for the nil-reason case.

**Stop-line guard the before test applies to `catalog_seed.ex` (`before_catalog_manifest_test.exs:1102-1113`, `seed_text_failures/1`)**: no retry-timing phrase and no `"reason"`/`"cause"` metadata key. `journey_seed.ex` is not scanned by the before test, so add the equivalent seed-text check to `after_catalog_manifest_test.exs` and obey it in the file.

**Wiring:** the driver's `SEED_EXPR` (`capture-before-catalog.cjs:41`) and `runSeed` (`:182-189`) parse ONE sentinel line from stdout. In after mode run both seeds (`MailglassDemo.CatalogSeed.seed!(); MailglassDemo.JourneySeed.seed!()`) and read both sentinels, or have `JourneySeed.seed!` print the merged map. `DemoData.reset!/0` never calls it (RESEARCH C-18), so the advisory `./e2e` lane will not see these rows.

---

### `mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex` + its unit test

**Analog:** `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex` and `mailglass_admin/test/mailglass_admin/preview/scenario_label_test.exs`.

**Module conventions to copy** (`scenario_label.ex:1-15`): `@moduledoc false`; a header comment stating the module is pure and total, only reads data it is given, "no atom is ever created from a label", and emits no diagnostics.

**Humanize rule to reuse, as a BINARY clause** (RESEARCH: `ScenarioLabel.humanize/1` is `when is_atom(atom)` only, `scenario_label.ex:31-39`):
```elixir
def humanize(atom) when is_atom(atom) do
  raw = Atom.to_string(atom)
  case raw |> String.split("_") |> Enum.reject(&(&1 == "")) do
    [] -> raw
    [first | rest] -> Enum.join([String.capitalize(first) | rest], " ")
  end
end
```
Add an additive `humanize(binary)` clause (or a private copy in `MailerName`). Do NOT add a new `String.capitalize` to `lib` without updating `@capitalize_baseline` (`copy_contract_test.exs:131-148`); a clause inside `ScenarioLabel` is already counted in the baseline only if it already uses `String.capitalize`, so verify by running `copy_contract_test.exs` (RESEARCH "Anti-Patterns").

**Leaf extraction** (`scenario_label.ex:149`): `defp leaf(mod), do: mod |> inspect() |> String.split(".") |> List.last()`; for a binary `mailable`, split on `"."`, treat a trailing lower-case-initial segment as the function (seeded `Module.function`), otherwise the module leaf (production stores module only, `persistence.ex:15,222,236`, RESEARCH C-9). Totality: nil, blank, trailing dots, odd casing all return a string, never raise.

**Test shape** (`scenario_label_test.exs:34-65`, `:207-214`): `describe` per function with plain `assert` equalities, `@source Path.expand("../../../lib/mailglass_admin/...", __DIR__)`, and the no-atoms source check:
```elixir
test "the module never creates atoms or emits diagnostics" do
  source = File.read!(@source)
  refute source =~ "String.to_atom"
  refute source =~ "Logger"
  refute source =~ ":telemetry"
end
```
Add a runtime check that `:erlang.system_info(:atom_count)` is unchanged across calls (RESEARCH Security Domain). The tooltip render (`role="tooltip"`, `aria-describedby` target present, no `title`, full identity also visible, `break-words`) is asserted against `Components.module_identity/1` (`components.ex:656-673`, wraps `field_help`; used at `detail_header.ex:68-76` with `segments={2}`).

---

### `brandbook/status-marks.json` and `scripts/brand_status_marks.exs`

**Analogs:** `/Users/jon/projects/mailglass/brandbook/brand.pin.json` (provenance fields) and `/Users/jon/projects/mailglass/scripts/brand_pin.exs`.

**Provenance fields to copy** from `brand.pin.json`: `"repo"`, `"commit"`, `"sha256"` of the zip (`ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`), `"root": "mailglass-brand/"`. The layout suggested in RESEARCH "Suggested `brandbook/status-marks.json` layout" stands; ONLY the location changes (Finding 1).

**Zip-member read, in memory, hash-first** (`scripts/brand_pin.exs:435-450`):
```elixir
defp read_members(zip_bin, root, froms) do
  case :zip.zip_open(zip_bin, [:memory]) do
    {:ok, handle} ->
      try do
        Enum.reduce_while(froms, {:ok, %{}}, fn from, {:ok, acc} ->
          case :zip.zip_get(String.to_charlist(root <> from), handle) do
```
Members are read by names the PIN lists, never names the archive supplies. The extractor must (a) verify the zip sha256 against `brand.pin.json` before reading any member, (b) support a local `--zip <path>` like `extend` does (`brand_pin.exs:563-575`, "hashed identically"), (c) slice `mailglass-brand/mailglass-brand-book.html` (member sha256 `1699d693...04db8`) for the five canonical `svg.stm` shapes, (d) emit `brandbook/status-marks.json`, never the HTML. Entry point and library mode (`brand_pin.exs:1005-1015`, fail-closed CLI unless `:script_library_mode`) are the template for the CLI wrapper:
```elixir
unless Application.get_env(:mailglass, :script_library_mode, false) do
  {status, output} = Mailglass.BrandPin.cli(System.argv())
  IO.puts(output)
  if status != 0, do: System.halt(status)
end
```
Reuse `Mailglass.BrandPin.sha256_hex/1` (`brand_pin.exs:128`). Invoke as `mix run --no-start scripts/brand_status_marks.exs <cmd>` so Jason is loaded.

**Required-lane vs advisory split (mirror 179 D-19):** the committed JSON + the component-equals-JSON test (`phase182_status_marks_test.exs`) are required; the zip byte-check (online) is advisory. A core test for the script (like `test/scripts/brand_pin_test.exs`: hermetic, injected getter, tmp dir, header comment on lines 3-5) is optional but follows that file's pattern.

---

### `reference/demo_app/assets/catalog/capture-before-catalog.cjs` (after- mode) and `catalog/phase182-journey.spec.js`

**Analogs:** the driver and `before-catalog.spec.js` themselves.

**Hard-coded places to parameterise** (all verified):
- `capture-before-catalog.cjs:36` `const SCHEMA = "mailglass.before_catalog.v1";`
- `:39` `const CATALOG_DIR_REL = ".planning/research/brand-v2-adoption/before-catalog";`
- `:41` `const SEED_EXPR = "MailglassDemo.CatalogSeed.seed!()";` and `:42` `const SENTINEL = "CATALOG_CASES_JSON=";`
- `:474` `const catalogId = \`before-${source.git_sha.slice(0, 7)}-${utcStamp(now)}\`;`
- `:405` `fs.readFileSync(path.join(assetsDir, "catalog/before-catalog.spec.js"))` (script hash input)
- `:509-513` the spawn: `["test", "--config=playwright.catalog.config.cjs"]` with no spec path (Finding 2)

Add `--mode after` (`parseArgs`, `:77-89`; unknown options `refuse(...)`), keep `before` default byte-identical so the committed before-catalog stays reproducible. Everything else carries over unchanged and satisfies D-21's served-SHA rules already: `assertCleanTree` (`:95-103`, `git status --porcelain --untracked-files=all`), `contentIdentity` (`:105-116`, working-tree bytes equal `HEAD:` blob), `restartDemo` (`:147-169`, recreates the container and requires `StartedAt` later than the commit time), `validate` (`:328-383`, served css sha256 equals the recorded bundle, revision match, nested theme count 0, no relative time, reserved-domain emails, reset token), `refuse` on re-use of a catalog id (`:477`), promotion by atomic rename after a second clean-tree check (`:557-559`).

**Staging contract the spec must honour** (`before-catalog.spec.js:17-31` header; `:354-358` `writeStaged`; `:518-552` per-capture record):
- env: `DEMO_BASE_URL`, `CATALOG_STAGING_DIR`, `CATALOG_CASES_FILE`, `CATALOG_ONLY`, `DEMO_CANDIDATE_REVISION` (`requireEnv`, `:41-47`)
- outputs under staging: `<id>.png`, `aria/<id>.yml`, `records/<id>.json`, `determinism.json`, `served.json`
- per capture: set the theme cookie `mailglass_admin_theme_v2` + `emulateMedia({colorScheme, reducedMotion: "reduce"})` BEFORE navigation (`prepareContext`, `:336-340`); wait for `[data-phx-main].phx-connected` (`connected`, `:187-189`); `settle()` loads Inter and waits `time[data-local-time]:not([data-localized])` to vanish (`:284-303`); screenshot via `shoot()` with a discarded warm-up shot (`:364-373`); `animations: "disabled"`, `caret: "hide"`.
- login for operator screens: `await page.goto('/demo/login?return_to=' + encodeURIComponent(target)); await page.goto(target); await connected(page);` (`openOperator`, `:199-203`).
- reuse the `served identity` test (`:448-515`) and the determinism self-test (`:425-446`) verbatim in the after spec (they feed `validate()`).

**Before/after screenshot pairing for the reviewer (D-21):** read before-catalog PNGs from `.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/` (e.g. `delivery-detail__<case>__default__375__light.png`, `cases.json` slugs `typo-bounce nil-reason-bounce deferred-no-retry manual-suppressed sent-no-report ...`). `STOP_LINE` probe at `before-catalog.spec.js:36` (`/next try at|will retry/i`) stays in the after spec as a deterministic backstop.

**Journey assertions (D-20, advisory):** `scrollWidth <= innerWidth`, 44px control height, `document.fonts.check("400 16px Inter")`, `.phx-connected` before each step, `timezoneId` `America/New_York` and `Pacific/Auckland` via `test.use({ timezoneId })` and a zone-token regex after `data-localized`. Place the spec in `catalog/` (RESEARCH C-18/A4) and set the playwright spec filter (Finding 2). Playwright config context (`playwright.catalog.config.cjs`): `timezoneId: "UTC"`, `locale: "en-US"`, `deviceScaleFactor: 1`, `reducedMotion: "reduce"`, `workers: 1`, `testDir: "./catalog"`, no `webServer`.

---

### `Components.timestamp/1`, `copy_value/1` and the localizer (edits, pattern shift only)

**Analog:** the current code, `components.ex:1518-1559` (timestamp), `:1569-1582` (copy_value), `:1604-1619` (`utc_string/1`), `controllers/assets.ex:104-128` (localizer).

Excerpt to change (`components.ex:1606-1619` today produces `"2026-06-14 14:32:05.000000 UTC"`):
```elixir
defp utc_string(%DateTime{} = at) do
  base = Calendar.strftime(at, "%Y-%m-%d %H:%M:%S")
  {microseconds, precision} = at.microsecond
  ...
  base <> fraction <> " UTC"
end
```
Target visible form (verified in RESEARCH C-14): `Calendar.strftime(at, "%b %-d, %Y, %-I:%M %p") <> " UTC"` giving `Nov 15, 2026, 2:05 PM UTC`, while `data-utc`, `data-copy-value` and the tooltip keep the full-precision value (so keep a second private formatter for the exact value; every `utc_string/1` call site in `:1530-1556` (data-copy-value, aria-label, data-utc, visible text, tooltip, title) needs re-pointing deliberately; `datetime=` at `:1535`/`:1549` stays ISO8601). Keep the pinned tooltip text `"... UTC • Click to copy"` (`components_test.exs:636`). Remove `title=` at `:1552` and `:1576`; the `aria-label` on the non-copyable `<time>` (`:1553`, "Recorded at ...") and the copy button's (`:1531`) must contain their visible text (WCAG 2.5.3).

Localizer (`assets.ex:107-128`) target:
```js
const FMT = { year: "numeric", month: "short", day: "numeric",
              hour: "numeric", minute: "2-digit", timeZoneName: "short" }
...
localValue = d.toLocaleString("en-US", FMT)      // was: undefined
el.textContent = localValue
// stop: el.setAttribute("aria-label", `Recorded at ${localValue} local time`)
```
The one existing assertion that recomputes the local string is `e2e/operator.spec.js:713-728` (`toLocaleString(undefined, {...})` and `toHaveAttribute("aria-label", /local time$/)`); update it in the same change.

---

### `Components.filter_field` `:search` type and `FiltersForm` split (edit; FORM-DRIFT-GATE)

**Analog:** `Components.filter_field/1` (`components.ex:886-946`) and `mailglass_admin/scripts/check-conformance.sh` FORM-DRIFT-GATE (lines ~90-127): wrapper files must call `Components.filter_field` / `filter_section` and contain none of `<label|input|select|textarea`. Add `:search` to the `attr(:type, :atom, values: [:text, :number, :select, :textarea, :checkbox])` list (`:890`) and render `type="search"` in the `<input>` branch (`:935-946`, `type={Atom.to_string(@type)}` already works for any atom in the `:if` list, which must include `:search`). Keep `id="filters_search"` and form id `operator-filters`.

---

## Shared Patterns

### Mutation-proven contract-test protocol
**Source:** `phase175_prohibition_contract_test.exs` (moduledoc `:1-15`, teeth `:71-93`), `copy_contract_test.exs:465-528`, `root_theme_ownership_contract_test.exs:149-222`, `logo_assets_contract_test.exs:1-37`
**Apply to:** all four `phase182_*` files, `phase182_status_marks_test.exs`, `after_catalog_manifest_test.exs`
Rules, as practised in all four analogs: (1) every check is a pure `(input) -> [failure]` function; (2) a `describe "detectors have teeth"` block feeds each detector a planted violation AND a clean control (negation guard, allow-list); (3) a vacuity floor on the scanned corpus size (`length(sources) > 30`, cell count equals the product of enumerated sizes); (4) failure messages name file, line and the fix; (5) the real-source mutation (edit lib, watch red, revert) is recorded in the plan SUMMARY, never committed.

### Visible-text extraction
**Source:** `copy_contract_test.exs:354-360`, `phase175...:428-434`, `voice_test.exs` (`strip_scripts/1`)
**Apply to:** every render scan
```elixir
html |> Floki.parse_fragment!() |> Floki.filter_out("script") |> Floki.text(sep: " ") |> String.replace(~r/\s+/, " ")
```
Scripts carry "noops" and zone tokens (RESEARCH "Don't Hand-Roll"). For the time scan also exclude `[role=tooltip]` and the `datetime` attribute (D-18).

### Source-enumerated universes (no hand-copied lists)
**Source:** `status_map_test.exs:56-83,206-211`; accessors `Mailglass.Events.Event.__types__/0` (`event.ex:133`), `__reject_reasons__/0` (`:137`), `Mailglass.Suppression.Entry.__reasons__/0` (`entry.ex:138`), `Mailglass.Outbound.Delivery.__event_types__/0` (`delivery.ex:176`), `Ecto.Enum.values(Delivery, :status)`.
**Apply to:** cause matrix, time/status grid (210 cells), words scan.

### Dead-render vs connected render
**Source:** `root_theme_ownership_contract_test.exs:60-64` (`get/2` + `html_response(conn, 200)` for the gallery) and `:48-52` (`live/2` html for the operator)
**Apply to:** `phase182_journey_test.exs`, `phase182_time_status_contract_test.exs`. `live/2` html includes the root layout for the first (dead) render in this repo's tests; CONTEXT D-20 requires `get/2` for the theme claim.

### Operator session helper
**Source:** `root_theme_ownership_contract_test.exs:319-343` (`operator_conn/2`, sets `current_user_id`, `tenant_id`, `auth_method`, `recent_auth_at`); `operator_live_test.exs` has the same.
**Apply to:** every LiveView test of `/ops/mail`.

### Admin conformance gates on new markup
**Source:** `mailglass_admin/scripts/check-conformance.sh` (see Finding 5)
**Apply to:** every new/edited HEEx line in `lib/`. Use token classes `text-label`, `text-body`, `font-bold`, `gap-sm|md|lg`, `p-md`, `space-y-sm`, `min-h-11`; no hex colour (use `var(--mg-color-...)`); `Components.status_badge/1` stays the only status-colour definition.

### Bundle and font discipline
**Source:** CONTEXT D-23, RESEARCH Pitfalls 5-6, `glyph_scan.ex`/`glyph_contract_test.exs`
**Apply to:** any plan that adds a Tailwind class to `lib/` or the root layout: run `mix mailglass_admin.assets.build`, then `--check`; commit `priv/static/app.css`; update `before-catalog/before-9eb9dee-20261115T022124Z/superseded.json` (`superseded_by.bundle_sha256`, `root_layout_git_blob_sha`) in the same change. New copy uses `•` (U+2022), `’`, `—`, `…`, `−`; never `·` or arrows (170-codepoint subset). SVG attributes and inline `style="color: var(--mg-color-...)"` add no class, so the pane mark needs no rebuild.

### Pre-flight order (cheap first)
**Source:** CONTEXT D-24, RESEARCH Validation Architecture. Run from `/Users/jon/projects/mailglass/mailglass_admin` with `export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`: `mix format --check-formatted`, `mix mailglass_admin.assets.build --check`, scoped contract files `--seed 0`, new phase files, then `bash scripts/check_test_exceptions.sh` at the repo root, core `mix compile --warnings-as-errors` + `mix credo --strict` if core changed, then the full lanes.

---

## No Analog Found

| File / concern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| Screen registry via `Phoenix.Router.routes/1` + `__live__/0` reverse check (inside `phase182_time_status_contract_test.exs`) | test helper | transform | No existing test enumerates routes or `__live__/0` (grep: only `status_map_test.exs:71` reads `__components__/0`). Use the recipe verified by running it in RESEARCH Pattern 4 (10 LiveView routes, 5 `{module, action}` pairs; `Code.ensure_loaded?/1` before `function_exported?/3`). Partial analog for the "test fails if a new module is unregistered" idea: `copy_contract_test.exs:371-377` (`scanned_files/0`) and `root_theme_ownership...:287-294` (`lib_sources/0`). |
| Pure `gate/1` review gate (two judges, any-reject-blocks, calibration) | pure function | transform | New logic. Structural precedent only: `storybook-axe.cjs` `validateApproval/compareFindings` (closed-key schema + self-comparison rejection). Put it in `test/support/catalog_validators.ex` (or a sibling `review_gate.ex`) as a pure module with exhaustive unit tests. |
| Brand-book HTML slicing for `svg.stm` fragments | script | file-I/O | No code reads the book HTML today (it is deliberately not in the tree; `brand_pin_test.exs:50` forbids it). Only the zip-member read mechanics in `brand_pin.exs:435-450` apply. |

## Metadata

**Analog search scope:** `/Users/jon/projects/mailglass/mailglass_admin/{lib,test,e2e,scripts}`, `/Users/jon/projects/mailglass/{lib/mailglass/operator,lib/mailglass/outbound,test/mailglass,test/scripts,test/support,scripts,brandbook}`, `/Users/jon/projects/mailglass/reference/demo_app/{lib,assets/catalog,assets/e2e}`, `/Users/jon/projects/mailglass/.planning/research/brand-v2-adoption/`
**Files read for excerpts:** 34 (plus targeted greps over lib/test/scripts)
**Tracked-source gate:** every cited analog path verified with `git ls-files --error-unmatch`; none is a gitignored mirror.
**Pattern extraction date:** 2026-11-15
