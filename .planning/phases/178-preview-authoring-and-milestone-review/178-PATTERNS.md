# Phase 178: Preview Authoring and Milestone Review - Pattern Map

**Mapped:** 2026-10-29
**Files analyzed:** 31 new or modified (17 source/test, 8 browser/spec, 3 script/doc, 3 planning evidence)
**Analogs found:** 30 / 31 (1 partial: the Phase 178 candidate script; the 173 script is a mechanics donor, not a drop-in)

All analog paths below were verified git-tracked (`git ls-files --error-unmatch`). None is a gitignored runtime mirror. Line numbers are from the current working tree at `63c01ffd`.

Environment for every `mix` call: `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` (do not edit `.tool-versions`).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` (edit) | component | request-response (LiveView form) | itself + `inbound/evidence_card.ex:84` (button), `field_error/1` (id association) | exact |
| `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` (edit) | component | request-response | itself (`menu/1`, `mailable_menu_label/1`) | exact |
| `mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex` (NEW) | utility (pure) | transform | `preview/return_context.ex` | role-match |
| `mailglass_admin/test/support/fixtures/mailables.ex` (edit) | test fixture | n/a | itself (`HappyMailer.preview_props/0`, lines 15-31) | exact |
| `mailglass_admin/test/mailglass_admin/preview/scenario_label_test.exs` (NEW) | test (pure) | transform | `preview/return_context_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/{voice,preview_live,discovery}_test.exs` (edit) | test | request-response | themselves | exact |
| `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs` (NEW) | test (contract) | file-I/O + transform | `bucket_a_coverage_test.exs` + `test/support/phase_artifacts.ex` + P177 detector/teeth shape | role-match |
| `mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs` (NEW) | test (contract) | request-response | `phase175_prohibition_contract_test.exs` (457 lines), `phase177_prohibition_contract_test.exs` | exact |
| `reference/persona_spec/quick_view_scenarios.json` (edit) | config/manifest | batch | itself (`preview-chrome-*` rows, `feedback` rows) | exact |
| `reference/persona_spec/quick_view_scenarios.ex` (edit) | utility (pure builder) | transform | itself (`preview_chrome/1`, 250-271; `story_meta/1`, 273-281) | exact |
| `reference/demo_app/storybook/preview_authoring.story.exs` (NEW) | story | render-only | `reference/demo_app/storybook/preview_chrome.story.exs` | exact |
| `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` (edit) | test | transform | its own `@tag :phase177` tests (582-673) | exact |
| `reference/demo_app/assets/e2e/phase178-stories.spec.js` (NEW) | browser test | render-only | `reference/demo_app/assets/e2e/phase177-stories.spec.js` | exact |
| `reference/demo_app/assets/e2e/quick-views.spec.js` (edit, 300-303) | browser test | file-I/O | itself | exact |
| `mailglass_admin/e2e/structural.spec.js` (edit) | browser test | request-response | itself (1790-1862, 1688-1740, 2376-2400) | exact |
| `mailglass_admin/e2e/flows.spec.js` (edit, 734) | browser test | request-response | itself | exact |
| `mailglass_admin/e2e/phase176-filters.spec.js` (edit, 599-652) | browser test | request-response | `structural.spec.js:1790` / `phase175-inbound.spec.js:246` | role-match |
| `mailglass_admin/e2e/phase177-health.spec.js`, `phase177-account.spec.js` (add real-zoom cases) | browser test | request-response | `phase170-journey.spec.js:366-395` (auth + extension) | role-match |
| `mailglass_admin/e2e/support/real-zoom.cjs` (NEW, optional) | utility | request-response | the 12-line recipe in `phase175-inbound.spec.js:246-275` | role-match |
| `mailglass_admin/docs/phase174-review.md` (edit, line 20; claims at 85, 94) | doc | n/a | itself | exact |
| `scripts/check_phase174_evidence.cjs:276` + `storybook-fidelity.spec.js:139` (limit wording only) | script/spec | file-I/O | themselves | exact |
| `scripts/check_phase178_candidate.sh` (NEW) | script | batch/file-I/O | `scripts/check_phase173_candidate.sh` (mechanics only) | partial |
| `.planning/phases/178-.../178-AUTOMATION.md` (NEW) | doc | n/a | `177-AUTOMATION.md`, `175-AUTOMATION.md` | exact |
| `.planning/phases/178-.../178-DELIVERY.md` (NEW) | doc | n/a | `.planning/milestones/v2.9-phases/173-consistency-and-delivery-evidence/173-DELIVERY.md` | exact |
| `.planning/phases/178-.../178-COST-DISPOSITION.json` (NEW) | evidence record | batch | `174-COST-DISPOSITION.json` | exact |

---

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` (component, request-response) - PRVUX-05, PRVUX-06

**Analog:** itself; button style from `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:84`.

**Restore button: before** (`assigns_form.ex:62-66`):
```heex
<div class="flex flex-wrap gap-2">
  <button type="button" class="btn btn-ghost min-h-11 px-5" phx-click="reset_assigns">
    Reset assigns
  </button>
</div>
```
**Precedent class string to copy verbatim** (`evidence_card.ex:84`):
```
mg-focus-ring btn btn-ghost min-h-11 px-md border border-base-300 w-full sm:ml-auto sm:w-auto
```
Keep the wrapper `flex flex-wrap` div: `sm:ml-auto` only end-aligns inside a flex parent. Keep `phx-click="reset_assigns"`. Note the old button lacked `mg-focus-ring`; the precedent has it. Only use classes already in `priv/static/app.css` (research verified `sm:ml-auto`, `sm:w-auto`, `border-base-300`, `min-h-11`, `px-md`). Absent: `sm:flex-row`, `sm:justify-end`, `sm:items-center`, `wrap-anywhere`. Do not run `mix mailglass_admin.assets.build` blindly (token-parity landmine).

**Helper removal target** (`assigns_form.ex:304-316`, delete) and call sites to remove: `<.field_help id={@help_id} text={@help_text} />` at lines 93, 116, 139, 167, 194 and 281; `assign(:help_text, help_text_for(...))` at line 298; `assign(:help_id, ...)` at 292 only if no longer used.

**describedby: before** (`assigns_form.ex:330-331`) and target shape:
```elixir
defp described_by(key, nil), do: help_id(key)
defp described_by(key, _error), do: help_id(key) <> " " <> error_id(key)
# target: nil for editable no-error (HEEx omits aria-describedby={nil});
#         error_id(key) alone when an error is rendered;
#         the single form-level note id for read-only fields, only when that note is rendered.
```
**Keep as-is:** `field_error/1` (254-261, `<p id={@id} class="mt-1 text-label text-error">`), `aria-invalid`, the `(atom)`/`(map)`/struct badges (`readonly_field/1`, 263-284, `{@label} <span ...>({@type_badge})</span>`), `aria-readonly="true"`, `data-readonly-display="true"` and the read-only `div` attributes otherwise (the Preview axe baseline cell `aria-allowed-attr: 1` in `docs/axe-baseline.json` very likely comes from that `div`; changing its attributes silently changes a baseline cell, see Pitfall A1 in RESEARCH).

**Form-level note placement:** render it in `assigns_form/1` (lines 40-69) next to the existing `editable_values?/1` branch. Compute presence with a sibling predicate built on the existing `editable_value?/1` (321-324):
```elixir
defp editable_values?(assigns),
  do: Enum.any?(assigns, fn {_key, value} -> editable_value?(value) end)
# add: defp readonly_values?(assigns), do: Enum.any?(assigns, fn {_k, v} -> not editable_value?(v) end)
```
**Gotcha not in RESEARCH:** `AssignsForm.field/1` is public and rendered standalone by tests (`preview_live_test.exs:1068-1100`, `render_component(&AssignsForm.field/1, key: :mode, value: :preview)`). If `readonly_field/1` points `aria-describedby` at a note that only `assigns_form/1` renders, the standalone render has a dangling id. Pass the note id into `field/1` as an optional `attr :note_id, :string, default: nil` (set by `assigns_form/1`), so standalone output carries no describedby.

**humanize:** `assigns_form.ex:335-338` keeps empty segments (so `a__b` yields a double space). Replace with a delegate to the shared `ScenarioLabel.humanize/1` (see below). Field labels `:user_name` ("User name"), `:admin?` ("Admin?") are pinned by `structural.spec.js:2382,2389` and must not change.

**Error strings that stay verbatim** (`preview_live.ex:1038-1042`):
```elixir
defp parse_error(default) when is_integer(default), do: "Enter a whole number."
defp parse_error(default) when is_float(default), do: "Enter a decimal number."
defp parse_error(%Date{}), do: "Enter a valid calendar date."
defp parse_error(default) when is_boolean(default), do: "Choose true or false."
defp parse_error(_), do: "Enter a valid value."
```
**Handler that must stay byte-identical** (`preview_live.ex:262-280`, `reset_assigns`): `lookup_scenario_defaults` -> `assign(:scenario_defaults/:current_assigns, defaults)`, `draft_assigns %{}`, `field_errors %{}`, `rerender()`.

---

### `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` (component, request-response) - PRVUX-07

**Analog:** itself.

**Current trigger identity to replace** (`sidebar.ex:123-134`):
```heex
<span id="preview-email-menu-active-identity" data-testid="preview-email-menu-active-identity"
  class="block min-w-0 flex-1 whitespace-normal [overflow-wrap:anywhere] text-body">
  <span class="font-bold text-base-content">{@current_mailable_label}</span>
  <span :if={@current_scenario_label} class="font-normal text-secondary">
    {" · "}{@current_scenario_label}
  </span>
</span>
```
Keep: the `id`, `data-testid`, `whitespace-normal [overflow-wrap:anywhere]`, no `truncate`, no `title`, and the `aria-labelledby="preview-email-menu-label preview-email-menu-active-identity"` on the `<summary>` (asserted at `preview_live_test.exs:~500-506`). Target structure per RESEARCH Pin Inventory: primary humanized scenario (bold) / secondary Mailable leaf (`text-secondary`) / monospace wrapping technical line `inspect(mod)` + raw atom (`font-mono text-label`). Drop the `·` join.

**Current option row to replace** (`sidebar.ex:216`, inside `mailable_menu_entry/1` at 184-228):
```heex
<span class="min-w-0 flex-1 truncate">{Atom.to_string(scenario_name)}</span>
```
Replace with a wrapping two-line block (`min-w-0 flex-1 whitespace-normal [overflow-wrap:anywhere]`): humanized primary + visible monospace raw atom. The `Components.icon name="hero-check"` sibling (217-221) and `scenario_selected?/4` logic stay.

**Preserve unchanged (D-05):**
```elixir
# sidebar.ex:419-424 - URLs keep the raw atom and carry the Phase 177 return query
defp scenario_path(mount_path, mod, scenario, width, _admin_chrome_theme, return_query) do
  ReturnContext.append_query(
    scenario_base_path(mount_path, mod, scenario) <> "?width=" <> Integer.to_string(width),
    return_query)
end
```
Panel group label keeps `title={inspect(@mod)}` (`sidebar.ex:271`, pinned by `structural.spec.js:1541-1543`) and stays namespace-free in visible text (pins at `preview_live_test.exs:219`, `structural.spec.js:1538`). Only the leaf-collision fallback may extend the visible text with a namespace suffix.

**Static open state for the story (RESEARCH Pattern 2):** add `attr(:open, :boolean, default: false)` to `menu/1` (attrs at 82-89) and render `<details open={@open} ...>` at line 113. Default output must stay byte-identical.

**Callers:** `PreviewLive` calls `Sidebar.menu` at `preview_live.ex:371` and `:491`, both with `mailables={@mailables}`; build the label map inside `menu/1` from `assigns.mailables` so neither caller changes. `Sidebar.picker/1` (45-80) and `sidebar/1` stay untouched (GalleryLive consumes them, `gallery_live.ex:431`).

**Special label** to preserve: `current_scenario_label(:__error__)` returns `"render error"` (`sidebar.ex:384`); `ScenarioLabel` must keep this behavior (and fall back to the raw atom when humanizing yields an empty string).

---

### `mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex` (NEW; utility, transform) - PRVUX-07 / D-06

**Analog:** `mailglass_admin/lib/mailglass_admin/preview/return_context.ex` (pure, closed-set, total functions, `@moduledoc false` with a `#` design comment, `@type t`, `@doc` + `@spec` on public functions).

**Shape to copy** (`return_context.ex:1-45`):
```elixir
defmodule MailglassAdmin.Preview.ReturnContext do
  @moduledoc false

  # Closed-set ... Every function here is total. ... nothing in this module emits diagnostics

  @type t :: %{...}

  @doc """..."""
  @spec resolve(map(), map() | nil) :: t() | nil
  def resolve(%{...} = params, navigation) when ... do
```
Apply: `@moduledoc false`, a comment block stating the rules, one public `build/1 :: [{module, reflection}] -> labels`, one public `humanize/1`, lookups that are total (unknown module or scenario returns a raw-atom fallback, never raises).

**Rules (all derived from verified source):**
```elixir
# humanize: drop empty segments (collapses "__"), capitalize first only; empty result falls back to raw atom
def humanize(atom) when is_atom(atom) do
  case atom |> Atom.to_string() |> String.split("_", trim: true) do
    [] -> Atom.to_string(atom)
    [first | rest] -> Enum.join([String.capitalize(first) | rest], " ")
  end
end
```
Leaf extraction to reuse (`sidebar.ex:369-374`, `module_parts/1`):
```elixir
case String.split(inspect(mod), ".") do
  [single] -> {nil, single}
  parts -> {parts |> Enum.drop(-1) |> Enum.join("."), List.last(parts)}
end
```
- Scenario collision: group by `{mod, humanized}`, any group > 1 uses the raw atom string as primary for each member.
- Module leaf collision: extend each colliding module's label with trailing namespace segments until unique (shortest distinguishing suffix). `{mod, :no_previews}` and `{mod, {:error, _}}` entries participate in the leaf set.
- Invariant to test over any discovered set: `{module_label, primary}` pairs are unique.
- No atom creation from input; all inputs are already-loaded atoms from `Discovery.discover/1`.

---

### `mailglass_admin/test/mailglass_admin/preview/scenario_label_test.exs` (NEW; test, transform)

**Analog:** `mailglass_admin/test/mailglass_admin/preview/return_context_test.exs` (directory `test/mailglass_admin/preview/` already exists).

**Shape** (`return_context_test.exs:1-20`, `46-50`):
```elixir
defmodule MailglassAdmin.Preview.ScenarioLabelTest do
  use ExUnit.Case, async: true
  @moduletag :phase178
  alias MailglassAdmin.Preview.ScenarioLabel
  ...
  describe "..." do
    for surface <- [...] do
      test "rejects unknown surface #{inspect(surface)}" do  # comprehension-generated cases
```
Cases required by D-06/RESEARCH: sentence case; `__` collapse (`:welcome_überraschung_東京__with_a_deliberately_long_name`); `:__error__` and `:_` raw-atom fallback; same-module scenario collision (`:a__b` vs `:a_b`); cross-namespace leaf collision. For the leaf collision use plain atoms (`Foo.Account.Mailer`, `Bar.Account.Mailer`) as `{mod, [{:welcome, %{}}]}` tuples; `inspect/1` works on atoms that are not defined modules, so no new fixture Mailable and no discovery-count shift. Uniqueness invariant test over `Discovery.discover([HappyMailer, StubMailer, BrokenMailer])`.

---

### `mailglass_admin/test/support/fixtures/mailables.ex` (fixture edit) - D-06

**Analog:** itself, `HappyMailer.preview_props/0` (lines 15-31):
```elixir
welcome_überraschung_東京__with_a_deliberately_long_name: %{
  user_name: "Ada", plan: :free, admin?: false
}
```
Append ONE scenario at the END of the keyword list (order is asserted), `welcome_überraschung_東京_with_a_deliberately_long_name` (single underscore), same assigns shape. Also add the matching render function (see `welcome_default/1` at line 33 for the `new() |> Mailglass.Message....put_function(...)` shape). Pins that must change in the same commit: `discovery_test.exs:20-26` (exact `Keyword.keys` list) and `preview_live_test.exs:118` (`"5 emails"` -> `"6 emails"`). Preview Capture Advisory counts are not fixed pins (`capture_manifest_test.exs` uses its own explicit lists), so no further edits; do not add a new Mailable module.

---

### `mailglass_admin/test/mailglass_admin/{voice,preview_live}_test.exs` and `e2e/{flows,structural}.spec.js` (pin rewrites)

**Do not rediscover these; RESEARCH "Pin Inventory" is authoritative.** Verified line numbers this session:

| Pin | Location |
|---|---|
| "Reset assigns" text | `voice_test.exs:114-115` (keep the "verb + noun, not bare Reset" message); `preview_live_test.exs:1062`; `e2e/flows.spec.js:734` |
| reset behavior test (must stay green, event name unchanged) | `preview_live_test.exs:~975-998` (`render_click(view, "reset_assigns", %{})` at 990) |
| error + help describedby | `preview_live_test.exs:1022` (becomes `aria-describedby="assigns-#{key}-error"`); `1071-1072`, `1084-1085`, `1095` (per-field `-help` ids go away) |
| read-only wording | `preview_live_test.exs:1034`, `1120` (`"edit it in the Mailable scenario"` moves to the form-level note) |
| trigger raw atom / no namespace | `preview_live_test.exs:201-202`, `481-482`, `511-512`; `structural.spec.js:1518, 1520, 1590, 1651, 1698, 1824` |
| panel stays namespace-free | `preview_live_test.exs:219`; `structural.spec.js:1538`, `1541-1543` (group-label `title`) |
| field help/describedby in browser | `structural.spec.js:2387, 2392, 2397` (rewrite the case at 2376) |

**Option clicking in browser tests** uses `page.getByTestId("preview-email-menu-option").filter({ hasText: longScenario })` (`structural.spec.js:1693`). With a visible monospace raw-atom line inside each option, `hasText` still matches; the single-underscore collision scenario does NOT contain the double-underscore string, so the existing selector stays unique.

---

### `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs` (NEW; contract test, file-I/O) - UIQ-04 / D-08

**Analogs (compose three):**
1. **Reading repo files fail-closed, with named "STALE CITATION" messages:** `bucket_a_coverage_test.exs` lines 36-56 and 328-331.
```elixir
@admin_root Path.expand(Path.join([__DIR__, "..", ".."]))
defp read!(path) do
  assert File.exists?(path), "cited file does not exist: #{path}"
  File.read!(path)
end
```
Repo root from an admin test is `Path.join([__DIR__, "..", "..", ".."])` (admin tests have no existing `.planning/` reader; this is the first).
2. **Dual-location "exactly one must exist" resolver:** `test/support/phase_artifacts.ex` (core `test/support`, NOT on the admin `elixirc_paths`, and hard-coded to the v2.7 archive root, so do not alias it). Copy the logic into the test file as a private helper:
```elixir
# phase_artifacts.ex:34-52, 66-71 (shape to copy)
candidates = [Path.join(repo_root, relative), Path.join([repo_root, ".planning/milestones/v2.10-phases", rest])]
case Enum.filter(candidates, &File.exists?/1) do
  [path] -> path
  []   -> raise ArgumentError, "... missing from both the live phase directory and the milestone archive"
  many -> raise ArgumentError, "... ambiguous - present at #{Enum.join(many, " and ")}"
end
```
Make the archive root a glob over `.planning/milestones/v*-phases/` so it survives the archive (RESEARCH A3, v2.7 precedent broke 58 tests).
3. **Detector returns violations, teeth block, clean-state block:** `phase177_prohibition_contract_test.exs:87-120` (`describe "detectors have teeth (fail-first proof)"`), where each rule has a known-violating fixture and a known-clean fixture, and `assert violations == []` against the real data.

**Data access:** `MailglassDemo.QuickViewScenarios` is compiled into the admin test build (`mix.exs:87`, `elixirc_paths(:test)` includes `reference/persona_spec`). `quick_view_scenarios.ex` today exposes only `scenarios/0` (line 19); add `def feedback, do: @manifest["feedback"]` beside it. Alias convention: `alias MailglassDemo.QuickViewScenarios` (`quick_view_projection_test.exs:20`).

**Rule (D-08), as a detector:** for each row with `status != "pending"`: `scenario_ids != []` OR `proof_boundary == "connected-real-route-only"` (additive field; only the filters row carries it), AND `evidence_pointer` is `path` or `path#anchor` that resolves (anchor via GitHub-style heading slug: lowercase, drop punctuation except `-`/`_`, spaces to `-`; e.g. `177-AUTOMATION.md#health-composition-outux-06` resolves from heading `## Health composition (OUTUX-06)`). Also assert each `scenario_ids` entry exists in `scenarios()` and lists the row id in its `feedback_ids`. Phase-close invariant: no row is `"pending"` or `"partial"`. Teeth fixtures: a pending row, empty `scenario_ids` without a boundary, an unresolvable path, a bad anchor, a post-archive path.

**Row count:** `quick-views.spec.js:299` asserts `manifest.feedback` has length 12; do not add rows.

---

### `mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs` (NEW) - D-15

**Analogs:** `phase175_prohibition_contract_test.exs` (template named in CONTEXT) and `phase177_prohibition_contract_test.exs`.

**Module head to copy** (`phase177_prohibition_contract_test.exs:20-36`):
```elixir
use MailglassAdmin.LiveViewCase, async: false
@moduletag :phase177          # use :phase178
alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}
@fixture_mailables [HappyMailer, StubMailer, BrokenMailer]
@scenario_base "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
@package_root Path.expand("../..", __DIR__)
```
(P175 uses plain `ExUnit.Case, async: true` + `Phoenix.LiveViewTest.render_component/2`; pick that for component-only rules.)

**Structure to copy:**
- `describe "detectors have teeth (fail-first proof)"` feeds each detector a violation and a clean fixture (`phase175:71-93`, `phase177:87-120`).
- Pattern sets as module attributes of regexes + `violations(text, patterns)` / `assert_clean(corpus, patterns, label)` (`phase175:447-456`).
- Rendered-text helpers (`phase175:428-445`):
```elixir
defp visible_text(html), do: html |> Floki.parse_fragment!() |> Floki.filter_out("script") |> Floki.text(sep: " ") |> String.replace(~r/\s+/, " ")
defp control_labels(html), do: ... Floki.find("button, a, [phx-click]") ...
```
- Source-scan rule (docs/specs), P177 `doc_files()` pattern at `phase177:842-855` (`@package_root`, `File.read!`, `length(files) > N` non-vacuity guard).

**Rules to implement (D-15 candidates), with the detector each needs:**
1. No generic per-field type helper strings ("Text value.", "Whole number.", "Decimal number.", "Date.", "Toggle on or off.") in `assigns_form/1` output for every value type, plus no `id$="-help"` on editable fields.
2. No dangling describedby: collect every token of every `aria-describedby` / `aria-labelledby` in a rendered fragment (Floki `attribute/2`) and assert each id exists in the same fragment. Run on `assigns_form/1` for typed_values, no-editable, error states, and on `Sidebar.menu/1`.
3. No `title`-only identity: the technical identity (`inspect(mod)` + atom) appears as visible text in the trigger/options, not only in a `title` attribute.
4. No raw-atom-only primary label: primary text for a non-colliding scenario is the humanized form.
5. Reset handler behavior unchanged: pin `phx-click="reset_assigns"` on the button and exercise `render_click(view, "reset_assigns", %{})` (clear drafts/errors).
6. No ledger row left `pending` or `partial` (delegate to the ledger test's detector or re-run on real data).
7. CSS zoom never labelled real zoom: scan e2e spec sources with `Regex.scan(~r/test\("([^"]*)"/, source)`; a test whose title says "real zoom" / "actual 200%" must not contain `style.zoom`.

**Mutation table (D-52 / "mutation-proven"):** Phase 177's moduledoc says each rule "was additionally proven red by a temporary source mutation (recorded in the plan SUMMARY) and reverted" (`phase177:9-13`). Record the table (rule, mutation applied, observed red test, revert command) in the plan SUMMARY or `178-AUTOMATION.md`. Revert with path-specific `git checkout -- <file>`; the working tree is dirty with unrelated `.planning/` files, so never `git checkout .` or `git stash -a`.

---

### `reference/persona_spec/quick_view_scenarios.{json,ex}` - STORY-07 / D-09, UIQ-04 / D-07

**Builder analog:** `quick_view_scenarios.ex:250-271` (`preview_chrome/1`) plus `story_meta/1` (273-281).
```elixir
def preview_chrome(scenario_id) when is_atom(scenario_id) do
  variation_id = Atom.to_string(scenario_id)
  scenario = Enum.find(@manifest["scenarios"], fn entry ->
    entry["rendered"] == true and entry["variation_id"] == variation_id and
      String.starts_with?(entry["id"], "preview-chrome-")
  end)
  if is_nil(scenario), do: raise(ArgumentError, "unknown retained Preview chrome scenario #{variation_id}")
  projection = scenario["projection"]
  scenario |> story_meta() |> Map.merge(...)
end
```
Add `preview_authoring/1` beside it with prefix `"preview-authoring-"` (the Phase 177 prefix filters `health-overview-`/`account-scope-`/`preview-chrome-` in `quick_view_projection_test.exs:645-647` and `phase177-stories.spec.js:45-47` will not match it). Raise `ArgumentError, "unknown retained Preview authoring scenario ..."` for unknown ids (tested like `quick_view_projection_test.exs:607-609`). Convert JSON strings to atoms/structs with small private clauses (existing `nav_key/1` style, 295-301) and never `String.to_atom` input.

**JSON row shape** (copy `preview-chrome-valid-return` row; every key is asserted by `quick_view_projection_test.exs:651-663`):
`id story_path theme_owner theme_picker_testid variation_id role_job source cohort state reason owning_requirements proof_boundary feedback_ids rendered projection`, with `proof_boundary: "story-render-only"`, `rendered: true`, `theme_owner: "preview-authoring-story"`, `theme_picker_testid: "preview-authoring-review-theme"` (must equal `owner minus "-story"` + `"-review-theme"`, asserted at line 661-662), `story_path: "/dev/storybook/preview_authoring"`. Variations from D-09: typed values, no editable values, field error, long/Unicode identity, duplicate label. Link each to `fb-preview-reset` / `fb-preview-identity` in `feedback_ids`. Do NOT add them to `axe_selection` (stays 20; `storybook-axe.cjs:52-100` hard-checks the selected/empty counts and `phase177-stories.spec.js:66-75` pins 20).

**Ledger correction (D-07), edit in place** (rows verified this session):
| Row | Now | Close with |
|---|---|---|
| `fb-auto-apply-filters` | pending, `scenario_ids: []`, prose pointer | `status: "automated"`, add `"proof_boundary": "connected-real-route-only"`, pointer `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VERIFICATION.md#observable-truths-roadmap-success-criteria` (headings exist at lines 71-173), cite `mailglass_admin/e2e/phase176-filters.spec.js` |
| `fb-raw-source-hierarchy` | pending | scenario_ids = the `inbound-evidence-evidence-*` ids; pointer to `176-VERIFICATION.md#requirements-coverage` (INUX-06) |
| `fb-inbound-addresses` | pending | scenario_ids = `inbound-evidence-normal-contacts/long-local-part/unicode/spoofed-display-name/many-recipients/missing-headers/unparseable`; pointer as above (INUX-05) |
| `fb-storybook-fidelity` | partial, has `pending_phases: ["178"]` | drop `pending_phases`, `status: "automated"` (or `resolved`), pointer to a `178-AUTOMATION.md#...` heading, add the new authoring scenario ids |
| `fb-preview-reset`, `fb-preview-identity` | pending, `scenario_ids: []` | scenario_ids = the new `preview-authoring-*` ids; pointer to `178-AUTOMATION.md#...` |
Also add `fb-inbound-addresses` and `fb-raw-source-hierarchy` to `feedback_ids` of the 11 `inbound-evidence-*` scenarios (today each lists only `fb-storybook-fidelity`). Normalize every `evidence_pointer` to `path` or `path#anchor`; move prose (for example the long `fb-quiet-quick-view-arrows` and `fb-storybook-fidelity` pointers) into `disposition`. Status values in use: `automated`, `resolved`, `pending`, `partial`.

---

### `reference/demo_app/storybook/preview_authoring.story.exs` (NEW; story, render-only) - STORY-07

**Analog:** `reference/demo_app/storybook/preview_chrome.story.exs` (70 lines, exact). Also `health_overview.story.exs` for a second composition.

**Copy this skeleton** (`preview_chrome.story.exs:1-34`, `69-70`):
```elixir
defmodule Storybook.PreviewChrome do
  @moduledoc false
  use PhoenixStorybook.Story, :component
  use Phoenix.Component
  alias MailglassDemo.QuickViewScenarios
  def container, do: :iframe
  def template do
    """
    <div data-theme-owner="preview-chrome-story" data-theme-preference="system" data-theme-resolved="light" data-theme-os="light" data-theme="mailglass-light" style="min-height: 900px" class="mg-admin-root bg-base-100 p-md text-base-content">
      ... <fieldset aria-label="Review theme" data-testid="preview-chrome-review-theme" ...> (Light/Dark/System radios) ...
      <.psb-variation/>
    </div>
    """
  end
  def variations do
    for id <- [:valid_return, :direct_entry] do
      %Variation{id: id, attributes: QuickViewScenarios.preview_chrome(id)}
    end
  end
  def render_case(assigns) do ~H"""<main data-testid="preview-chrome-story" data-scenario-id={@scenario_id} data-state={@state} ...> ... """ end
  def function, do: &__MODULE__.render_case/1
end
```
Rename to `Storybook.PreviewAuthoring`, owner `preview-authoring-story`, picker testid `preview-authoring-review-theme`, root `data-testid="preview-authoring-story"`. `render_case/1` must render production `MailglassAdmin.Preview.AssignsForm.assigns_form/1` and `MailglassAdmin.Preview.Sidebar.menu/1` (with `open` for the collision variation). No other registry to edit: Storybook auto-discovers `*.story.exs`, and `git grep` for `preview_chrome` finds no index file.

**Story-file source test** to add in `quick_view_projection_test.exs`, copying lines 612-632: `assert preview =~ "Storybook.PreviewAuthoring"`, `=~ "QuickViewScenarios.preview_authoring"`, `=~ "AssignsForm.assigns_form"`, `=~ "Sidebar.menu"`, and `{:defmodule, _, _} = Code.string_to_quoted!(source)`.

---

### `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` (edit; test) - STORY-07

**Analog:** its own Phase 177 block, lines 582-673, tagged `@tag :phase177`. Use `@tag :phase178`.
- Render-through-production-component test: `preview_chrome_html/1` (703-720) uses `rendered_to_string(~H"""...""")`; for Phase 178 call `render_component(&AssignsForm.assigns_form/1, scenario_assigns: ..., draft_assigns: ..., field_errors: ...)` (as `preview_live_test.exs:1056-1062` does) and `render_component(&Sidebar.menu/1, ...)` (as `preview_live_test.exs:487`).
- Shape test: copy 634-664 and change the id list/prefix (`preview-authoring-`).
- Assert `proof_boundary == "story-render-only"` and scenario ids derived from variation ids (`quick_view_projection_test.exs:595-597` pattern).
- Pure-only boundary: do not add a persisted/projection-agreement test for Preview (D-09 says no fabricated projection check). Instead one test asserts the live Preview render equals the story's facts for the typed-values scenario.

---

### `reference/demo_app/assets/e2e/phase178-stories.spec.js` (NEW) and `quick-views.spec.js` (edit)

**Analog:** `phase177-stories.spec.js` (shown in full above).
```js
const STORIES = { "/dev/storybook/preview_chrome": { owner: "preview-chrome-story", picker: "preview-chrome-review-theme", story: "preview-chrome-story", roots: [...] } };
const prefix = `iframe-storybook_${storyPath.split("/").pop()}-variation-${scenario.variation_id}`;
const frame = page.frameLocator(`iframe[id^="${prefix}"]`);
await expect(root).toHaveAttribute("data-scenario-id", scenario.id);
```
Filter by `/^preview-authoring-/`; assert `manifest.axe_selection.length === 20` and no authoring entries in it. It is advisory (needs the demo Storybook on :4015).

**`quick-views.spec.js:300-303` replacement.** The stale assertion (verbatim) requires 175-178 rows to be `pending` except three automated ones:
```js
const automatedPhase175Feedback = new Set(["fb-technical-details", "fb-suppression-refresh", "fb-replay-review"]);
expect(manifest.feedback.filter(feedback => ["175", "176", "177", "178"].includes(feedback.owner_phase))
  .every(feedback => automatedPhase175Feedback.has(feedback.id)
    ? feedback.owner_phase === "175" && feedback.status === "automated"
    : feedback.status === "pending")).toBe(true);
```
Replace with a phase-independent structural check only (non-empty `disposition`/`evidence_pointer`, status not in the pending set) and delegate the full rule to the ExUnit ledger test. Keep the test title `Phase174 delivery scenario manifest accounts for rendered and real-route-only cases` (it is in `REQUIRED_PHASE174_TESTS`, so the title is a checker pin). Keep `expect(manifest.feedback).toHaveLength(12)` (line 299) and the per-row non-empty assertions (lines 300-306 area). Note the Demo pilot runs the whole demo suite, so this stale assertion currently fails the D-12 pilot.

---

### Real-zoom browser cases (UIQ-06 / D-10)

**Primary analog for Preview selector + restore:** `structural.spec.js:1790-1862`, title `"Phase 171 rendered: actual 200% zoom retains preview controls and long identity at 320 CSS px"` (keep the `Phase 171` prefix; `gsd-regression-gate.sh` greps it).
```js
const extensionPath = path.resolve(__dirname, "support/browser-zoom-extension");
const zoomContext = await chromium.launchPersistentContext("", {
  channel: "chromium", headless: true, viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2,
  args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`]
});
...
const serviceWorker = zoomContext.serviceWorkers()[0] || await zoomContext.waitForEvent("serviceworker");
const zoom = await serviceWorker.evaluate(async () => {
  const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
  if (!tab?.id) throw new Error("The active browser tab is unavailable");
  await chrome.tabs.setZoom(tab.id, 2);
  return chrome.tabs.getZoom(tab.id);
});
expect(zoom, "real Chromium tab zoom factor").toBe(2);
await expect.poll(() => zoomPage.evaluate(() => window.devicePixelRatio)).toBe(initialDpr * 2);
await zoomPage.setViewportSize({ width: 640, height: 900 });
await expect.poll(() => zoomPage.evaluate(() => window.innerWidth)).toBe(320);
```
Extend this case (or add a sibling `Phase 178 ...` case in the same file, so the regression gate's `Preview:`/`Phase 17x` grep still runs it) with: the Restore defaults button reaches `boundingBox().width/height >= 44`, stays inside 320 px, no page overflow, the technical-identity line wraps (`scrollWidth <= clientWidth + 1`). Narrow-width selector pattern: `structural.spec.js:1688-1740` (`page.setViewportSize({ width: 320, ... })`, open menu, click `preview-email-menu-option` filtered by `hasText`).

**Authenticated routes (Health, Account control, quick-view overlay):** copy `phase170-journey.spec.js:352-395` (reuse `storageState` from the logged-in page in `launchPersistentContext`, then `goto('/ops/browser-login?tenant_id=...&return_to=...')`) or the in-page login in `phase175-inbound.spec.js:246-285` (full receipt object `{tabZoom, initial, effective}` + `expect(effective.devicePixelRatio / initial.devicePixelRatio).toBe(2)`). Use `visibleByTestId`/`accountSwitcher` from `mailglass_admin/e2e/support/account.cjs` for the Account control (sidebar and mobile-band copies both exist in the DOM). `phase177-health.spec.js` helpers `openHealth(page, {scenario, theme})` (lines 14-27) get you to Health; neither phase-177 spec contains any zoom case today.

**CSS-zoom cases to migrate or relabel** (`phase176-filters.spec.js:599-652`): they use `document.documentElement.style.zoom = zoom` (lines 607, 622). Either replace with the recipe above or rename the titles to say "CSS zoom" (title strings at 599 and 615 currently say "200% zoom"; the prohibition rule #7 scans these).

**Optional shared helper** `e2e/support/real-zoom.cjs`: extract the 12-line setup for NEW cases only; do not refactor the six existing copies (`flows.spec.js:919,2024`, `phase170-journey.spec.js:368`, `phase175-inbound.spec.js:246`, `structural.spec.js:1792`).

**Phase 174 quick-view zoom and checker coupling:** `storybook-fidelity.spec.js:139` writes the limit string `"Browser zoom reconciliation is owned by Phase 178."`; `check_phase174_evidence.cjs:276` requires `evidenceLimits.some(/Phase 178/i)`; `check_phase174_evidence.test.cjs:213` carries the same string in its fixture. The checker compares fidelity case ids with an exact set (RESEARCH Pitfall 6), so do NOT add new `appendFidelityEvidence` case ids. Put the quick-view real-zoom case in the Operator Browser Gate (connected `?id=` overlay) and reword the limit so `/Phase 178/i` still matches.

---

### `mailglass_admin/docs/phase174-review.md` (doc edit) - D-11

Line 20 currently reads `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 \` followed by `bash scripts/run_demo_browser_evidence.sh --phase174 --pilot`. Change only the Erlang pin to `27.3.4.15`. No test pins that string (`phase174-review-claims.test.cjs` does not reference ASDF). Lines 85 and 94 state that real zoom and STORY-07 "remain Phase 178 work"; update those claims to the closed state with the same commit if the closure is real, otherwise leave and cite in `178-AUTOMATION.md`.

---

### `scripts/check_phase178_candidate.sh` (NEW; script) - UIQ-08 / D-14

**Analog (mechanics only):** `scripts/check_phase173_candidate.sh`. **Not directly reusable:** its first loop requires phase 168-172 summaries under `.planning/phases/` (they now live in `.planning/milestones/v2.9-phases/`), it expects six `assets/baselines/phase173` PNGs, it hard-wires `OWNER_ACCEPTANCE_STATUS="unverified"` (so `FINAL_STATUS` is always `incomplete`), it is not executable (`-rw-r--r--`), and it pins `ASDF_ERLANG_VERSION=27.3.4.13`. Write a slim sibling that copies these pieces:

- Fail helper and clean check (`:9-20`):
```bash
fail() { printf 'phase173 candidate gate: %s\n' "$*" >&2; exit 1; }
```
- Detached worktree at the exact SHA (`:51-53`, `:60-65`):
```bash
RUN_PARENT="$(mktemp -d /tmp/mailglass-phase173.XXXXXXXX)"
git worktree add --detach --no-checkout "$CANDIDATE_WORKTREE" "$ORIGIN_SHA"
[[ "$(git -C "$CANDIDATE_WORKTREE" rev-parse HEAD)" == "$ORIGIN_SHA" ]] || fail "..."
```
- Demo lockfile restore after Compose bumps swoosh (`:22-32`, `restore_candidate_demo_lock`): compares `git rev-parse "$SHA:reference/demo_app/mix.lock"` with `git hash-object` after `git restore`.
- Free-port allocation refusing demo defaults, unique project name (`:258-276`):
```bash
REVIEW_PROJECT="mailglass-phase173-review-${SHA:0:8}-$RUN_SUFFIX"   # use mailglass-phase178-review-...
compose() { MAILGLASS_DEMO_HTTP_PORT="$HTTP_PORT" MAILGLASS_DEMO_DB_PORT="$DB_PORT" docker compose -p "$REVIEW_PROJECT" -f "$ROOT_DIR/compose.demo.yml" "$@"; }
compose up --build --detach --wait --wait-timeout 600 demo
```
- Route probes and CSS identity (`:289-330`): `curl --silent --location --output ... --write-out '%{http_code}' --max-time 30`; extract the versioned CSS link with `/href=["']([^"']*\/dev\/mail\/css-[a-f0-9]{32})["']/`; compare sha256 of `mailglass_admin/assets/css/app.css` (source), `mailglass_admin/priv/static/app.css` (built) and the fetched `served.css`.
- Teardown block printed from the record (`:558-559`): `docker compose -p "$REVIEW_PROJECT" -f "$WORKTREE/compose.demo.yml" down` and `git worktree remove "$WORKTREE"`.
Phase 178 routes to probe (from RESEARCH): `/dev/mail`, `/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin`, `/dev/storybook/preview_authoring`, `/dev/storybook/preview_chrome`, `/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar`. Add the exact-SHA `gh` check for `CI Green` and `Guard Release Trigger` (read-only). The running `mailglass-storybook-review-demo` project on 4015/5415 is the owner's earlier preview; do not touch it. Make the file executable (`chmod +x`) or invoke it with `bash`.

---

### `178-DELIVERY.md`, `178-AUTOMATION.md`, `178-COST-DISPOSITION.json` (planning evidence)

- **Runbook format:** `173-DELIVERY.md` (`.planning/milestones/v2.9-phases/173-consistency-and-delivery-evidence/`): sections "Start and open the candidate" (command + recorded JSON path), numbered review routes with full URLs, source/built/served CSS identity paragraph, "Checks and evidence limits" (CI is `CI Green` for the exact SHA, read-only gh check, no merge/publish), retention note, and "Scoped cleanup after review" with the two teardown commands. Do not use `make demo-down` for cleanup (it targets the retained feedback preview).
- **AUTOMATION format:** `177-AUTOMATION.md` / `175-AUTOMATION.md`: "Reproduce and check" block (all commands with the ASDF pins; demo mix.lock drift reminder), then per-requirement sections whose HEADINGS become the ledger anchors (e.g. `## Health composition (OUTUX-06)` -> `#health-composition-outux-06`), each with "Merge-blocking evidence" bullets and explicit "Limits:" lines. Use these heading names exactly in the ledger `evidence_pointer`s you write. 175 also has "Feedback and ownership" and "Placement, cost, and limits" sections to copy for UIQ-04/UIQ-07.
- **Cost record:** `174-COST-DISPOSITION.json`: `schema_version`, `source_revision`, `run_id`, `input_hashes` (raw GitHub run/jobs JSON), `observed_delta_ms`, `added_cost` (`baseline` run 40414024714 / job 121891818059 / head `e326da4d...`, `candidate`, `wall_ms`, `runner_minutes`, `limitation`), `budget` (`added_wall_minutes: 5`, `added_runner_minutes: 10`, `disposition`, `wall_within_budget`, `wall_exceedance_ms`, `recommendation`), `final_cost_path`. Report per-job deltas (Demo pilot, Operator gate, Support Contract Admin) and the `CI Green` wall delta separately, with expected (`playwright --list`: 300 / 109 at research time) vs executed counts.
- **Hosted identity trap:** a `pull_request` run uses the merge SHA, so `check_phase174_evidence.cjs --require-ci` (which compares `ciJob.head_sha`, `github.sha` and `execution.source_revision`) cannot pass on the PR run. The identity-bound cost evidence needs one `workflow_dispatch` of `ci.yml` on the candidate branch, as Phase 174 did (run 40498413906). The single owner checkpoint must name push, draft PR (non-bumping `chore(ui): ...` title) and the dispatch.

---

## Shared Patterns

### Class availability (committed CSS bundle)
**Source:** `mailglass_admin/priv/static/app.css` (verified present by RESEARCH): `sm:ml-auto`, `sm:w-auto`, `[overflow-wrap:anywhere]`, `border-base-300`, `font-mono`, `text-label`, `text-secondary`, `min-h-11`, `whitespace-normal`, `break-words`, `break-all`, `gap-xs`, `flex-wrap`, `justify-end`, `items-start`, `space-y-sm`. Absent: `sm:flex-row`, `sm:justify-end`, `sm:items-center`, `wrap-anywhere`.
**Apply to:** `assigns_form.ex`, `sidebar.ex`, story render_case. If a plan needs an absent class it must add a named asset-rebuild task plus `git diff --exit-code priv/static/` and the token-parity test.

### Rendered-id closure (no dangling describedby)
**Source (new, derive from `phase175` helpers):** collect tokens from every `aria-describedby` and `aria-labelledby` in a Floki-parsed fragment, assert each id exists in the same fragment.
**Apply to:** `assigns_form/1` states (typed values, no editable, error, read-only only), `Sidebar.menu/1`, the prohibition contract, and the new Playwright restore/selector case.

### Detector + teeth + clean state (D-52 prohibition tests)
**Source:** `phase177_prohibition_contract_test.exs:87-120` and `phase175_prohibition_contract_test.exs:71-93`.
**Apply to:** `phase178_prohibition_contract_test.exs`, `feedback_ledger_test.exs`. Every rule: one violating fixture asserted red, one clean fixture asserted green, one run on real data.

### Scoped test commands
**Source:** `177-AUTOMATION.md` "Reproduce and check".
```sh
cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs test/mailglass_admin/discovery_test.exs --seed 0
cd mailglass_admin && CI=1 BROWSER_SERVER_PORT=4131 npx playwright test --config=playwright.config.cjs e2e/structural.spec.js --grep "Phase 171|Phase 178" --workers=1   # direct npx; no asset rebuild
node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs
bash mailglass_admin/scripts/check-conformance.sh
```
Admin CI lane `mix verify.support_contract.admin` is `["test --warnings-as-errors"]` (`mix.exs:213-215`), the whole suite, so every new admin test file is merge-blocking automatically. Format touched admin files individually (`mix format <file>`); the CI format gate is root-only.

### Commit hygiene
`.planning/HANDOFF.json` is deleted and several `.planning/research/*` and `seeds/*` files are modified in the working tree; `prompt.txt` is untracked. Use path-scoped commits and check `git show --stat HEAD` after any `gsd-sdk` commit (it stages all dirty `.planning/` paths). Do not touch `.planning/release-target.json`.

---

## No Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| Readable disambiguation of colliding Mailable leaves across namespaces (`ScenarioLabel` module-level) | utility | transform | No existing code computes a "shortest distinguishing namespace suffix"; `module_parts/1` only splits leaf from namespace. Use RESEARCH Pattern 1 rules and test with synthetic atoms. |
| Form-level read-only note with an id-closure guarantee | component | request-response | No existing form-level note component; closest is `field_help/1` (the thing being removed) and `field_error/1` for the id association style. |
| Admin test that reads `.planning/` via a dual-location resolver | test | file-I/O | Only core has this (`test/support/phase_artifacts.ex`, v2.7 only); admin tests never read `.planning/`. Copy the logic privately (above). |
| stat_card font-role receipt for `fb-storybook-fidelity` | browser test | file-I/O | The sandbox-serif reset probe lives in `storybook-fidelity.spec.js:449-460, 631-665` (`readComputedRoles`) but is bound to the delivery/inbound quick-view cases, and the 174 checker is exact-set coupled. Plan it as a Chromium-side computed-style assertion on `reference/demo_app/storybook/primitives/stat_card.story.exs` that does not append a new fidelity case id, or extend the checker deliberately with updated fixtures. |
| `check_phase178_candidate.sh` as a whole | script | batch | 173 script is a mechanics donor only (see above). |

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/{preview,inbound,operator}`, `mailglass_admin/test/**`, `mailglass_admin/e2e/**`, `mailglass_admin/{docs,scripts}`, `reference/persona_spec`, `reference/demo_app/{storybook,assets/e2e}`, `scripts/`, `test/support/`, `.planning/{phases,milestones/v2.9-phases}`, `.github/workflows/ci.yml` (jobs at 954, 1042, 1072).
**Files scanned:** ~45 read in full or by targeted range; ~40 grep/ls probes.
**Pattern extraction date:** 2026-10-29
