# Phase 180: Reproducible Admin Bundle and Before-Catalog - Pattern Map

**Mapped:** 2026-11-14 (source HEAD `7a848162`, tree clean; read-only mapping)
**Files analyzed:** 31 new or modified file groups (listed in File Classification)
**Analogs found:** 28 with a strong or role-match analog / 31 (3 partial, see "No Analog Found")
**Tracked-source gate (#3645):** every analog path below was checked with `git ls-files` and is git-tracked. No `.gsd/capabilities` mirror paths appear. Paths in `mailglass_admin/` are relative to the repo root unless prefixed `./`.

All line numbers were read at HEAD `7a848162`. Re-grep before editing if `main` moves (RESEARCH "Valid until 2026-11-28").

## File Classification

### BRPIPE-01 (reproducible bundle, `--check`, required-lane wiring)

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/assets/css/app.css` (MODIFY, +1 directive) | config (Tailwind source) | transform | itself, lines 11-14 | exact (in place) |
| `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex` (MODIFY, `--check`) | mix task (shipped) | batch / request-response CLI | `mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex` | role-match |
| `mailglass_admin/dev/mailglass_admin/assets_check.ex` (NEW, non-shipped compare; name discretionary) | utility | file-I/O + subprocess | `mailglass_admin/dev/mailglass_admin/preview/chromium.ex` + `.../preview/capture_manifest.ex` | role-match |
| `mailglass_admin/mix.exs` (MODIFY aliases + comment) | config | n/a | itself, lines 184-217 | exact (in place) |
| `mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs` (NEW) | test (contract + mutation) | file-I/O, static | `phase175_prohibition_contract_test.exs` (teeth) + `test/scripts/required_checks_test.exs` (CI wiring) | role-match (two analogs) |
| False-claim prose: `mailglass_admin/.gitattributes:2`, `mailglass_admin/.gitignore:21`, `lib/mix/tasks/mailglass_admin.assets.watch.ex:17`, `docs/design-system.md:19-23`, `assets.build.ex` moduledoc, `mix.exs` comment ~188-191 (MODIFY) | docs/comments | n/a | n/a | n/a |
| `.github/workflows/ci.yml` `support_contract_admin` (OPTIONAL: `fetch-depth: 0`) | config | n/a | `changes` job checkout, ci.yml:30-33 | exact |

### BRPIPE-02 (`<html>` owns the theme)

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/admin_shell.ex` (MODIFY, delete attr line 16 + `data-theme` line 33) | component | render | `layouts/root.html.heex:2` (the surviving owner) | exact |
| `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (MODIFY, delete line 198) | component | render | n/a (deletion) | n/a |
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` (MODIFY, delete 318 + helper 740) | LiveView | render | n/a (deletion) | n/a |
| `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` (MODIFY, delete 66 + helper 183-186, add backdrop wrapper) | component | render | RESEARCH Code Example 5 + its own `tab_content(:html)` iframe styling, lines 97-118 | role-match |
| `mailglass_admin/lib/mailglass_admin/gallery_live.ex` (MODIFY, delete 138/148 wrappers, moduledoc 10) | LiveView | render | its own `-system` wrapper (kept), lines 156-165 | exact (in place) |
| `mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs` (NEW; name discretionary) | test (static scan + dead-render count + teeth) | request-response + file-I/O | `copy_contract_test.exs` (lib scan + teeth) + `router_test.exs:191-200` (`get/2` root `<html>`) + `operator_live_test.exs:2750-2760` (`live/2` + cookie) | role-match (three analogs) |
| `mailglass_admin/test/mailglass_admin/admin_shell_test.exs` (MODIFY lines 17, 38) | test | render | itself | exact (in place) |
| `mailglass_admin/test/mailglass_admin/preview_live_test.exs` (MODIFY 96, 991, 1028-1072) | test | request-response | itself | exact (in place) |
| `mailglass_admin/e2e/theme-ownership.spec.js` (NEW) | test (browser, advisory) | request-response | `e2e/structural.spec.js:828` (`applyThemeEmulation`) + `e2e/flows.spec.js:43-62` (`loginOperator`) + `e2e/admin-assets.spec.js:296-300` | role-match |
| `mailglass_admin/e2e/support/theme.cjs` (NEW optional; P6: `applyThemeEmulation` is not importable) | utility | n/a | `mailglass_admin/e2e/support/account.cjs` | role-match |
| e2e rework: `structural.spec.js`, `flows.spec.js`, `gallery-matrix.spec.js`, `phase168-plan03-acceptance.spec.js`; demo `persona-screenshots.spec.js:203` (MODIFY) | test (browser) | request-response | themselves | exact (in place) |

### BRPIPE-03 (before-catalog)

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `reference/demo_app/lib/mailglass_demo/catalog_seed.ex` (NEW; 4 cases) | seed module | CRUD (insert) | `reference/persona_spec/personas.ex` `materialize!/3` (lines 195-254) + `reference/demo_app/lib/mailglass_demo/demo_data.ex` `delivery!/1` `event!/4` (707-769) | role-match |
| `reference/demo_app/assets/catalog/before-catalog.spec.js` (NEW, OUTSIDE `./e2e`, F9) | test/producer (browser) | file-I/O (screenshots) | `reference/demo_app/assets/e2e/persona-screenshots.spec.js` | role-match |
| `reference/demo_app/assets/playwright.catalog.config.cjs` (NEW) | config | n/a | `reference/demo_app/assets/playwright.config.cjs` | exact |
| catalog driver script (clean-tree gate, stage, validate, promote; name discretionary, e.g. `reference/demo_app/assets/catalog/promote-catalog.cjs` or a `scripts/` bash wrapper) | utility/script | file-I/O | `reference/demo_app/assets/scripts/evidence-output-path.cjs` + `check-persona-reset-target.cjs` + `scripts/run_demo_browser_evidence.sh` | partial |
| `.planning/research/brand-v2-adoption/before-catalog/<catalog_id>/{manifest.json,*.png,aria/*}` (NEW artifacts) | evidence | file-I/O | `MailglassAdmin.Preview.CaptureManifest` JSON shape; identity fields from `scripts/run_demo_browser_evidence.sh` | partial |
| `mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs` (NEW) | test (manifest validator + teeth) | file-I/O | `brand_v2_compat_policy_test.exs` + `test/mailglass_admin/preview/capture_manifest_test.exs` + `dev/.../capture_manifest.ex` `validate_png!` | role-match |

---

## Pattern Assignments

### `mailglass_admin/assets/css/app.css` (config, transform)

**Analog:** itself. Insert one directive after the existing `@source` pair.

**Existing block** (lines 11-14):
```css
@import "tailwindcss" source(none);

@source "../css";
@source "../../lib";
```

**Target** (RESEARCH Code Example 2, verified on Tailwind 4.1.12: 136,877 bytes, `cmp` identical to the committed bundle):
```css
@source "../css";
@source "../../lib";
@source not inline("prose");   /* Phase 180 D-03: copy.ex gloss text contains the bare word "prose" */
```
Do NOT use `@source not "../../lib/mailglass_admin/copy.ex"`: it drops `badge-primary`, `hero-bell-slash`, `hero-envelope-open`, `hero-hand-thumb-up` (F13). `.max-w-prose` must still be emitted (5 real uses).
**Commit kind:** `chore(admin):` (F12: `assets/` is shippable but not a `lib` behaviour change). Separate commit from `lib/` and `priv/static`.

---

### `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex` (mix task, CLI)

**Analog:** `mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex` (OptionParser strict, loud `Mix.raise`, brand-voice failure text).

**Current file** (whole file, 29 lines; the false claim is lines 19-20):
```elixir
defmodule Mix.Tasks.MailglassAdmin.Assets.Build do
  use Boundary, classify_to: MailglassAdmin
  @shortdoc "Build mailglass_admin CSS bundle (production, minified)"
  @moduledoc """ ... CI runs this followed by `git diff --exit-code priv/static/` ... """
  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("tailwind", ["default", "--minify"])
  end
end
```
Keep `use Boundary, classify_to: MailglassAdmin` (line 2). It is required because the module name is `Mix.Tasks.*`, outside the `MailglassAdmin` namespace.

**CLI parsing pattern to copy** (`preview.capture.ex` lines 40-56, 88-107):
```elixir
@impl Mix.Task
def run(argv) do
  {opts, rest, invalid} =
    OptionParser.parse(argv, strict: [base_url: :string, ..., dry_run: :boolean])

  validate_cli!(opts, rest, invalid)
  ...
end

defp validate_cli!(opts, rest, invalid) do
  if rest != [] do
    Mix.raise("Preview capture blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
  end
  if invalid != [] do
    invalid_flags = invalid |> Enum.map(fn {key, _value} -> "--#{key}" end) |> Enum.join(", ")
    Mix.raise("Preview capture blocked: unknown option(s) #{invalid_flags}")
  end
  ...
end
```
Adapt with `strict: [check: :boolean]`. Default (no flag) keeps `Mix.Task.run("tailwind", ["default", "--minify"])` unchanged.

**Failure message contract (D-02, brand voice):** include both sizes, the first differing offset, and the exact fix: `run mix mailglass_admin.assets.build and commit priv/static/app.css`. Specific and composed, never "Oops".

**Compile-time reference rule (P11):** `Tailwind.*` is a dep `only: [:dev, :test]`; the shipped task must not reference it at compile time (existing task uses the string `Mix.Task.run("tailwind", ...)`). Delegate to the `dev/` module through a guarded `Code.ensure_loaded?` + `apply/3`, and raise a clear "maintainer-only" message when absent, or add `@compile {:no_warn_undefined, Tailwind}` if the logic stays inline. Mirror the repo's optional-dep gateway idiom (`Code.ensure_loaded?(...)` + `apply/3`, as in `MailglassAdmin.OptionalDeps.MailglassInbound`).
**Moduledoc inputs list (D-08):** `assets/css/app.css`, `assets/vendor/*.js` (daisyUI 5.5.19), `lib/**` (scanner), `../brandbook/tokens.css`, Tailwind binary version.
**Commit kind:** `refactor(admin):` or `fix(admin):` (touches `lib/`), own commit.

---

### `mailglass_admin/dev/mailglass_admin/assets_check.ex` (utility, file-I/O + subprocess) NEW

**Analog 1:** `mailglass_admin/dev/mailglass_admin/preview/chromium.ex` (non-shipped `dev/` module; `System.cmd` wrapper that returns tagged tuples, never raises on non-zero exit).

**Subprocess pattern** (chromium.ex lines 40-55):
```elixir
timeout = Keyword.get(opts, :timeout, @default_timeout)
task = Task.async(fn -> System.cmd(binary, args, stderr_to_stdout: true) end)

case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
  {:ok, {output, exit_code}} ->
    if exit_code == 0, do: :ok, else: {:error, {:command_failed, exit_code, String.trim(output)}}
  nil ->
    {:error, {:command_failed, 124, "... timed out after #{timeout}ms"}}
end
```
**Analog 2:** `dev/mailglass_admin/preview/capture_manifest.ex` for byte validation and "raise `ArgumentError` with a message naming the cause" (lines 180-190, 218-241).

**Module name and Boundary:** use `MailglassAdmin.AssetsCheck` (or `MailglassAdmin.Assets.Check`). `capture_manifest.ex` is `MailglassAdmin.Preview.CaptureManifest` and has no `use Boundary`, because modules under the `MailglassAdmin` namespace are already in that boundary (`lib/mailglass_admin.ex:45`). Only the `Mix.Tasks.*` modules need `classify_to`. A module outside the namespace would trip `--warnings-as-errors` ("not included in any boundary").

**Core body:** take the verified prototype in `180-RESEARCH.md` "Code Examples 1" (lines 373-402). Load-bearing facts:
- Read profile with `Tailwind.config_for!(:default)`; rewrite only the `"--output=" <> _` entry (F1: a trailing `--output` is comma-joined and litters `priv/static/`); append `"--minify"`.
- `System.cmd(Tailwind.bin_path(), args, cd: cfg[:cd], env: %{"BROWSERSLIST_IGNORE_OLD_DATA" => "1"}, stderr_to_stdout: true)`.
- `unless File.exists?(Tailwind.bin_path()), do: Tailwind.install()` with NO rescue (fail closed, D-06).
- Return `{:error, {:drift, fresh_size, committed_size, first_diff_offset}}`, `{:error, {:committed_unreadable, reason}}`, `{:error, {:tailwind_failed, status, out}}`, or `:ok`. Always `File.rm(tmp)` in `after`.
- Accept `opts` (`:cd`, `:committed`, an injectable `:installer`) so tests can aim it at a tmp tree and inject a raising installer without touching global `Application` env (memory: Clock global async leak).
Observed: HEAD without directive `{:drift, 139137, 136877, 74051}`; byte flip `{:drift, 136877, 136877, 1000}`; truncated `{:drift, 136877, 5000, 5000}`; deleted `{:committed_unreadable, :enoent}`.

---

### `mailglass_admin/mix.exs` (config, aliases)

**Analog:** itself. Current block, lines 184-217:
```elixir
  # Step 4 is the PREV-06 / CONTEXT D-04 merge gate — bundle drift CI check.   # line 191 (false claim)
  defp aliases do
    [
      ...
      "verify.preview": [                                   # 207
        "compile --no-optional-deps --warnings-as-errors",
        "test --warnings-as-errors --exclude flaky",
        "mailglass_admin.assets.build",
        "cmd git diff --exit-code priv/static/"             # no workflow runs this
      ],
      "verify.support_contract.admin": [                    # 213
        "test --warnings-as-errors"
      ],
      "verify.phase_05": ["verify.preview"]                 # 217
```
**Target:** add `"mailglass_admin.assets.build --check"` as the FIRST step of `verify.support_contract.admin`; re-point `verify.preview`'s last step at `"mailglass_admin.assets.build --check"` (keep the alias name: `scripts/check_phase173_candidate.sh:245` invokes `mix verify.preview` and `scripts/test_check_phase173_candidate.sh:582` asserts the log text). Fix the comment at ~188-191. `preferred_envs` for both aliases is already `:test` (lines 40-42), so the first step runs where the `:tailwind` dep exists (`only: [:dev, :test]`).
**Unverified (A3/P12):** the alias's first step relies on Mix compiling the project to find the task from a cold `_build`. Prove once from a clean clone.
**Commit kind:** `ci(admin):` or `chore(admin):` (mix.exs is shippable per F12), separate from `lib/`.

---

### `mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs` (test, contract + mutation) NEW

**Analog A (teeth + moduledoc discipline):** `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs`.

**Moduledoc + case header** (lines 1-17): state what is machine-checked, say the "detectors have teeth" block makes a pass non-vacuous, name the lane. `use ExUnit.Case, async: true`.

**Teeth block shape** (lines 71-93):
```elixir
describe "detectors have teeth (fail-first proof)" do
  test "every pattern set rejects a known violation" do
    for {patterns, violation} <- [{@receipt_claims, "The provider confirmed receipt of this message."}, ...] do
      assert violations(violation, patterns) != [], "pattern set must catch #{inspect(violation)}"
    end
  end
  test "negated disclaimers are not mistaken for claims" do ... end
end
```
and helper (447-456): `defp violations(text, patterns)`, `defp assert_clean(corpus, patterns, label)` whose assertion message names the label and the matched text.

**Analog B (hermetic tmp tree):** `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs` lines 798-815:
```elixir
# Builds a throwaway repository root under the system temp dir, runs `fun`
# with it, and removes the directory this test created.
defp with_root(files, fun) do
  root = Path.join(System.tmp_dir!(), "feedback-ledger-#{System.unique_integer([:positive])}")
  try do
    for {relative, content} <- files do
      path = Path.join(root, relative)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, content)
    end
    File.mkdir_p!(root)
    fun.(root)
  after
    File.rm_rf!(root)
  end
end
```
Extend it to `File.cp_r!` the `assets/` (852 KB) and `lib/` (388 KB) trees plus `brandbook/tokens.css` into a tmp tree that preserves the `mailglass_admin/` and `brandbook/` relative layout (the CSS imports `../../../brandbook/tokens.css`), mutate the copy, then call the compare with `cd:` at the copy (RESEARCH Pattern 4). Plant `tracking-widest` (absent from the committed bundle) not `underline` (present).
Also `capture_manifest_test.exs:273-283` `tmp_dir/1` (`System.tmp_dir!()` + `System.unique_integer([:positive])`, `File.rm_rf!` then `File.mkdir_p!`) is the simpler single-dir variant.

**Analog C (task-level assertions):** `mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs`:
```elixir
test "rejects unknown flags loudly" do
  assert_raise Mix.Error, ~r/unknown option\(s\)/, fn -> run_task!(["--wat"]) end
end
defp run_task!(argv) do                       # lines 109-116
  Mix.Task.reenable(@task_name)
  Mix.Task.reenable("app.start")
  capture_io(fn -> Mix.Tasks.MailglassAdmin.Preview.Capture.run(argv) end)
end
```
Use this for `Mix.Tasks.MailglassAdmin.Assets.Build.run(["--check"])`; assert the raised `Mix.Error` message `=~ "mix mailglass_admin.assets.build"`. P13: never byte-compare stdout of a nested `mix` (build-lock notice flake); test in-process and match with `=~`.

**Analog D (CI wiring assertion, "lane that never runs"):** `test/scripts/required_checks_test.exs`:
```elixir
@ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)          # line 5
defp extract_job_block(source, job_key) do                                    # lines 441-448
  marker = "  #{job_key}:\n"
  case String.split(source, marker, parts: 2) do
    [_, rest] -> marker <> (rest |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2) |> hd())
    _ -> ""
  end
end
```
and the negative-control idiom (lines 125-137): `String.replace(ci_source, "      - changes\n", "", global: false)` then `assert_raise ExUnit.AssertionError`. From the admin test dir the path is `Path.expand("../../../.github/workflows/ci.yml", __DIR__)` (same `@repo_root Path.expand("../../..", __DIR__)` idiom as `brand_v2_compat_policy_test.exs:27`).
Wiring cases to write: the `support_contract_admin` job block contains `mix verify.support_contract.admin` and is `needs.changes.outputs.code`-gated; `Mix.Project.config()[:aliases][:"verify.support_contract.admin"]` is a list with no file allow-list (every step is a string with no `test/…` path arg) and its first step is `"mailglass_admin.assets.build --check"` (alias lookup precedent: `mix_config_test.exs:13-30`, `Mix.Project.config()`). `ci_green.needs` containing `support_contract_admin` is ALREADY proven by core `test/scripts/required_checks_test.exs` (GATE-03, set-equality with `config/quality/ci_policy.exs:56-60`); do not duplicate beyond a cheap substring check.

**Hygiene (D-06):** no `@tag :skip`, no `Process.sleep` (`config/test_exceptions.exs` is `file:line` keyed; admin tests are not scanned by `scripts/check_test_exceptions.sh`, F15, but keep the rule). The file is picked up automatically because `verify.support_contract.admin` runs the whole directory.
**Fail-closed case:** inject `installer: fn -> raise "download failed" end` and `assert_raise`; no rescue into a pass.
**Mutations to show red then restore (RESEARCH "Mutation checks"):** delete the `@source not inline("prose")` line; flip a byte; truncate; delete; plant `tracking-widest` in tmp `lib/`; remove the alias step or the ci.yml run line (tmp copies of the text).
**Commit kind:** `test(admin):` (non-shippable; a `fix:` with only test and `.planning` paths fails Guard Release Trigger, F12).

---

### `mailglass_admin/lib/mailglass_admin/admin_shell.ex` (component, render) BRPIPE-02

**Analog:** the one surviving theme owner, `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex:2`:
```heex
<html lang="en" data-theme={root_theme(assigns)}>
```
fed by `layouts.ex:70-85` (`root_theme/1` prefers `admin_chrome_theme`, falls back to the cookie, else `nil`) and `theme.ex:51-53`:
```elixir
def data_theme(:dark), do: "mailglass-dark"
def data_theme(:light), do: "mailglass-light"
def data_theme(_choice), do: nil
```
**Deletions (D-11):** `admin_shell.ex:16` `attr(:theme_attr, :string, default: nil)` and `:33` `data-theme={@theme_attr}` (keep `data-testid={@testid}` and the `mg-admin-root ...` class, D-14). Callers: `operator/shell.ex:198` `theme_attr={Theme.data_theme(@theme_choice)}`; `preview_live.ex:318` `theme_attr={admin_theme_attr(@admin_chrome_theme)}` and helper `:740` `defp admin_theme_attr(theme), do: MailglassAdmin.Theme.data_theme(theme)` (remove the helper, otherwise an unused-private-function warning fails `--warnings-as-errors`). Keep `Theme.data_theme/1`.
**Landmine:** `scripts/check-conformance.sh:416` greps `layouts.ex`, `layouts/root.html.heex`, `operator_live.ex`, `inbound_live.ex` for `'mailglass-system|data-theme="system"|root_theme.*system|system.*data-theme'` and fails the required `conformance_gates` lane. Do not write a comment that contains both "system" and "data-theme" (or `root_theme` and "system") in those four files.
**Plan-summary honesty (D-15):** removing `admin_shell.ex:33` is a latent-defect fix; no visible shell-vs-`<html>` disagreement was reproduced. Say so.

---

### `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` (component, render) BRPIPE-02

**Analog:** its own `tab_content(%{active_tab: :html})` iframe (lines 97-118) for how the iframe is already styled inline, plus RESEARCH Code Example 5 (probe-verified in Chromium and WebKit).

**Current tabpanel** (lines 60-72):
```heex
<div ...
  data-preview-frame-theme={preview_frame_theme_attr(tab, @preview_frame_dark_chrome)}
  data-theme={preview_frame_data_theme_attr(tab, @preview_frame_dark_chrome)}      <!-- DELETE (line 66) -->
  data-testid={if(@active_tab == tab, do: "preview-pane")}
  role="tabpanel" ...
```
**Keep** `data-preview-frame-theme` and `preview_frame_theme_attr/2` (lines 178-181): it is a state marker used by `preview_live_test.exs` and 12+ e2e lines (P7). **Delete** `preview_frame_data_theme_attr/2` (lines 183-186).

**Current iframe** (lines 106-113):
```heex
<iframe
  srcdoc={@html_body}
  sandbox="allow-same-origin"
  style={"width: #{@device_width}px; height: 600px; border: 1px solid var(--color-base-300); border-radius: var(--radius-box); background: var(--color-base-100);"}
  phx-update="ignore"
  id={"preview-iframe-" <> Integer.to_string(@render_nonce)}
  title="Email HTML preview — browser rendering only"
/>
```
**Target** (F4: `color-scheme` on the iframe element alone gives NO visible toggle; use a wrapper):
```heex
<div data-testid="preview-frame-backdrop"
     style={"color-scheme: #{if @preview_frame_dark_chrome, do: "dark", else: "light"}; background: Canvas"}>
  <iframe srcdoc={@html_body} sandbox="allow-same-origin" style="color-scheme: light; ..." ... />
</div>
```
`tab_content/1` does not currently receive `preview_frame_dark_chrome`; add `attr(:preview_frame_dark_chrome, :boolean, default: false)` and pass it at the `<.tab_content ...>` call (line 74). No `data-theme`, no `--color-*`/`--mg-*` assignment, no new CSS rule (bundle stays byte-identical; verify with `--check`). The `Canvas` keyword is clean for the `HEX-GATE` (it only flags `color[^#]*#RRGGBB` in `.ex`). Text, headers and raw tabs follow the admin theme. State in the plan summary that the visible backdrop change moves from "whole panel" to "email stage" (a named visible change, not a token change).

---

### `mailglass_admin/lib/mailglass_admin/gallery_live.ex` (LiveView, render) BRPIPE-02

**Analog:** its own surviving third wrapper (lines 158-166). Current specimen row (wrappers at lines 138, 148, 158):
```heex
<div class="flex flex-col gap-md xl:flex-row xl:flex-wrap">
  <div data-theme="mailglass-light" class="rounded-field border ..."> <.render_specimen ... specimen_id={"#{component}-#{state}-light"} /> </div>   <!-- 138 area: DELETE -->
  <div data-theme="mailglass-dark"  class="rounded-field border ..."> <.render_specimen ... specimen_id={"#{component}-#{state}-dark"} />  </div>   <!-- 148 area: DELETE -->
  <div data-testid={"gallery-#{component}-#{state}-system"} class="rounded-field border ..."> <.render_specimen ... specimen_id={"#{component}-#{state}-system"} /> </div>   <!-- KEEP -->
```
Keep the `-system` wrapper and its testid (low-churn: `phase168-plan03-acceptance.spec.js` reads six `-system` testids, `gallery-matrix.spec.js` discovers cells by `data-testid^='gallery-'` and excludes `-system`). Collapsing to one specimen also removes the 182 duplicate `id`s that make `live/2` raise "Duplicate id found while testing LiveView" (F10/P5). Update moduledoc lines ~3-11 (it documents the three wrappers) but keep the substring `/dev/mail/gallery` (`token_parity_test.exs:200`).
**Gallery light/dark matrix moves to e2e:** loop cookie + `emulateMedia` + `goto` per theme (see theme-ownership spec below).

---

### `mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs` (test, static scan + dead-render count) NEW

**Analog A (lib static scan + teeth):** `mailglass_admin/test/mailglass_admin/copy_contract_test.exs`.

**Scan helper** (lines 73-74, 369-377):
```elixir
@lib_dir Path.expand("../../lib", __DIR__)
defp relative(file), do: Path.relative_to(file, @lib_dir)

defp scanned_files do
  @lib_dir
  |> Path.join("**/*.ex")
  |> Path.wildcard()
  |> Enum.reject(&(relative(&1) in @excluded_files))
  |> Enum.sort()
end
```
Adapt the glob to `**/*.{ex,heex}`; allow only `layouts/root.html.heex` for `data-theme=`; also reject any `--mg-`/`--color-` assignment in inline `style=` and Tailwind arbitrary-property classes (`[--mg-color-background:#fff]`). Detectors must be pure functions of `(path, source)` so the teeth block can feed them a planted string, as `copy_contract_test.exs:467-510` does (`assert count_label_literals(~s|def a, do: "Delivered"|) == 1`).

**Analog B (root `<html>` from `get/2`):** `mailglass_admin/test/mailglass_admin/router_test.exs:191-200` (`use MailglassAdmin.EndpointCase, async: false`; `@theme_cookie MailglassAdmin.Theme.cookie_name()` at line 13):
```elixir
conn =
  conn
  |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=light")
  |> get("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

assert html_response(conn, 200) =~ ~s|<html lang="en" data-theme="mailglass-light">|
```
Use `get/2` for the gallery (`/dev/mail/gallery`; `live/2` raises on duplicate ids at HEAD).

**Analog C (root `<html>` from `live/2`, F3: the first dead render includes the root layout):** `operator_live_test.exs:2750-2760` (`use MailglassAdmin.LiveViewCase, async: false`):
```elixir
conn = conn |> operator_conn() |> Plug.Conn.put_req_header("cookie", "#{@theme_cookie}=dark")
{:ok, _view, html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))
assert html =~ ~s|<html lang="en" data-theme="mailglass-dark">|
```
`operator_conn/2` is a private helper in that file (lines 4268-4282, plus `get_session_map/1` at 4284) and again in `inbound_live_test.exs:3893`; copy it, do not import. Preview needs no session: `preview_live_test.exs:1031-1034` uses `conn |> Plug.Conn.put_req_header("cookie", ...) |> live("/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")`.

**Count assertion (RESEARCH Code Example 3):** `assert length(Regex.scan(~r/\sdata-theme=/, html)) == 1` for cookie dark/light and `== 0` for system. Measured at HEAD (the red-first reproduction): preview 4/4/2, operator 2/2/0, inbound 2/2/0, gallery 245/245/244. Prefer a Floki element count (`Floki.parse_document!(html) |> Floki.find("[data-theme]")`, as `preview_live_test.exs:85-96` `preview_pane_attrs/1` does) as the primary assertion and keep the regex count as the cross-check the research measured. **Write the failing reproduction first and record it red on current code** before the six deletions.
**Surfaces:** preview show, operator, inbound (`live/2`), gallery (`get/2`). Do not target `/dev/storybook` (Open Question 1, A7).
**Lane:** REQUIRED (`verify.support_contract.admin`, whole directory). The Playwright spec is advisory.
**Commit kind:** `test(admin):`.

---

### `mailglass_admin/test/mailglass_admin/admin_shell_test.exs` and `preview_live_test.exs` (test, rework)

**`admin_shell_test.exs` before** (line 17 passes the attr; line 38 asserts it):
```elixir
<AdminShell.shell
  testid="example-shell"
  theme_attr="mailglass-dark"          # line 17: an undeclared attr is a compile warning; CI runs --warnings-as-errors
...
assert html =~ ~s(data-theme="mailglass-dark")     # line 38
```
**After:** drop line 17, replace line 38 with `refute html =~ "data-theme"`; keep the other assertions.

**`preview_live_test.exs` before** (lines 1028-1075, test "preview frame theme toggle does not mutate admin shell data-theme"; `preview_pane_attrs/1` at 85-96 reads `data-theme`): asserts `data-theme="mailglass-light"` on the pane and `~r/data-preview-frame-theme="light"[^>]+data-theme="mailglass-light"/`. **After:** keep the `data-preview-frame-theme` assertions (light then dark after `render_click(view, "toggle_preview_frame_theme", %{})`), drop every `data_theme` map key, and assert `preview-frame-backdrop` renders `color-scheme: dark` after the toggle and `data-theme` count stays at the root only. Rework, do not delete without a replacement (D-12). Lines to touch: 96, 991, 1028-1043, 1056, 1065, 1069, 1072.
Tests that must stay green unchanged: `router_test.exs:198,207,216,227`, `operator_live_test.exs:2760,2777`, `inbound_live_test.exs:2665,2683`, `components_test.exs:953`, `brand_test.exs:77`, `token_parity_test.exs`.

---

### `mailglass_admin/e2e/theme-ownership.spec.js` (browser test, advisory lane) NEW

**Analog:** `mailglass_admin/e2e/structural.spec.js` (theme emulation), `e2e/flows.spec.js` (login), `e2e/admin-assets.spec.js` (assertion style), `playwright.config.cjs` (the config auto-boots `OperatorBrowserServer` at `/ops/browser-ready`; no config change needed).

**Theme emulation, copy verbatim** (`structural.spec.js:828-834`; P6: file-local, no `module.exports`, so copy or extract to `e2e/support/theme.cjs` in the shape of `e2e/support/account.cjs` with a trailing `module.exports = {...}`):
```js
async function applyThemeEmulation(page, theme) {
  if (theme === "system") {
    await page.emulateMedia({ colorScheme: "dark" });
  } else {
    await page.emulateMedia({ colorScheme: null });
  }
}
```
The new matrix needs the OS axis independent of the cookie axis, so extend it to `emulateMedia({ colorScheme: os })` BEFORE navigation.

**Login helper to duplicate** (`flows.spec.js:43-62`; per-file duplication is the repo convention, flows.spec.js header says "no shared module exists today"):
```js
async function loginOperator(page, returnTo, subjectId = "operator-1", sessionTenantId = tenantId, resetScenario = null, recentAuthAt = null) {
  await page.context().clearCookies();          // so add the theme cookie AFTER login
  const resetResponse = await page.request.get(`/ops/browser-reset${...}`);
  expect(resetResponse.ok()).toBeTruthy();
  ...
  await page.goto(loginURL);
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
```
Constants at file top: `const tenantId = "browser-tenant"; const baseURL = process.env.OPERATOR_BASE_URL || \`http://127.0.0.1:${process.env.BROWSER_SERVER_PORT || "4101"}\`;`.

**Assertion style** (`admin-assets.spec.js:296-300`, must stay green):
```js
await expect(page.locator("html"), `${routeCase.name} dark query sets root theme before color checks`).toHaveAttribute("data-theme", "mailglass-dark");
```
**Measurement skeleton:** RESEARCH Code Example 4 (add the cookie `mailglass_admin_theme_v2` with `ctx.addCookies([{ name, value: "light"|"dark", url: base }])`; absent = system; `getComputedStyle(el).getPropertyValue("--color-base-100")` for html, `preview-pane`, `#mg-copy-toast`, the modal). Measured red at HEAD in 2 of 4 combinations (pane `#f8fbfd` vs html `#0d1b2a`).
**Wait pattern:** `await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();` (`phase177-health.spec.js:23`). `.mg-admin-root` stays a class (D-14).
**Lane:** ADVISORY (`operator_browser_gate`). Do not cite as required proof (D-13). Run locally as `cd mailglass_admin && npx playwright test --config=playwright.config.cjs --workers=1 e2e/theme-ownership.spec.js`.

**Existing e2e that pins nested attributes (rework, not delete):** `phase168-plan03-acceptance.spec.js:29,36,39,45,54,61` (`operatorShell`/`previewShell` `data-theme`; flip to "html owns it"); `flows.spec.js:827,831,863,869` (frame toggle) and `1296-1327` (picker asserts `.mg-admin-root` `data-theme`; re-target to `html`) and `1336-1380`, `2343`; `structural.spec.js:446,453-465,1509-1522,1525-1536,1672-1691,1724-1730,1805-1809,2184,2465-2466,2505-2570,2990-3193,3467` (38 `primitiveWrapper(` uses); `gallery-matrix.spec.js` (`themeWrapper` machinery lines 16-18, 77-80, 128-148, 225-259; gallery moves to a per-theme outer loop); demo `persona-screenshots.spec.js:201-204` (`getByTestId("gallery-theme_picker-dark-selected").locator('[data-theme="mailglass-dark"]')`). The Preview a11y backdrop test (`flows.spec.js:852-872`) asserts `pane` background changes (`expect(afterBg).not.toBe(beforeBg)`): move that read to the new `preview-frame-backdrop` testid (P7). Stay green: `admin-assets.spec.js:296-300`, `phase176-filters.spec.js:372`, Storybook specs. Run `axe-baseline.spec.js` without `PERSIST_AXE_BASELINE` afterwards.

---

### `reference/demo_app/lib/mailglass_demo/catalog_seed.ex` (seed module, CRUD insert) NEW

**Analog 1:** `reference/persona_spec/personas.ex` `materialize!/3` (lines ~195-254): a standalone module that takes `(repo, occurred_at)` and inserts through the real changesets, without `DemoData`'s private helpers.
```elixir
alias Mailglass.Events.Event
alias Mailglass.Outbound.Delivery
...
delivery =
  %{
    tenant_id: @fjordline, mailable: payload.long_mailable, stream: :transactional,
    recipient: payload.recipient, adapter_ref: Delivery.default_adapter_ref(),
    provider: "postmark", provider_message_id: payload.long_delivery_id,
    status: :sent, last_event_type: payload.event_type, last_event_at: occurred_at,
    terminal: true, delivered_at: occurred_at,
    idempotency_key: "demo-delivery-#{payload.long_delivery_id}",
    metadata: %{"persona" => @fjordline, "subject" => "Welcome to Fjordline A/S", ...}
  }
  |> Delivery.changeset()
  |> repo.insert!()

%{tenant_id: @fjordline, delivery_id: delivery.id, type: payload.event_type, occurred_at: occurred_at,
  reject_reason: payload.reject_reason,
  idempotency_key: "demo-event-#{payload.long_delivery_id}-#{payload.event_type}-#{DateTime.to_unix(occurred_at)}",
  metadata: %{"provider" => "postmark", "source" => "webhook"},
  normalized_payload: %{"recipient" => delivery.recipient}}
|> Event.changeset()
|> repo.insert!()
```
**Analog 2:** `reference/demo_app/lib/mailglass_demo/demo_data.ex` `event!/4` (lines 749-769), which must be mirrored so the projection stays consistent:
```elixir
event = %{tenant_id: @tenant, delivery_id: delivery.id, type: type, occurred_at: occurred_at,
          idempotency_key: "demo-event-#{delivery.provider_message_id}-#{type}-#{DateTime.to_unix(occurred_at)}",
          metadata: metadata, normalized_payload: %{"recipient" => delivery.recipient}}
        |> Event.changeset() |> Repo.insert!()
Repo.get!(Delivery, delivery.id) |> Mailglass.Outbound.Projector.update_projections(event) |> Repo.update!()
```
and `delivery!/1` (707-725) defaults (`adapter_ref: Delivery.default_adapter_ref()`, `terminal: false`, `idempotency_key: "demo-delivery-#{provider_message_id}"`, `:queued`/`:suppressed` get a nil `provider_message_id`, subject written into `metadata["subject"]`).

**Constraints for the new module:**
- Do NOT edit `DemoData` or `reference/persona_spec/personas.ex` (D-22; `persona_drift_guard_test.exs` and demo e2e counts depend on them). Call the new module only from the catalog run.
- `DemoData.reset!` keeps its anchor in the process dictionary (`@anchor_key`, line 19; `seed_anchor/0` line 907) and TRUNCATEs everything (lines 884-898), so the catalog seed must run AFTER every reset (P8) and compute its own `DateTime.utc_now() |> DateTime.truncate(:second)` anchor with relative offsets (recency window default is 168 h, `operator_live.ex:48`).
- Use a distinct provider_message_id prefix (for example `pm-cat-...`) so the `demo-delivery-<id>` / `demo-event-...` idempotency keys cannot collide with the existing seed (the reset race in `demo_data.ex:21-29` was a duplicate `provider_msg_id`).
- Only 4 cases are truly missing (F7): hard bounce to a typo domain; send-time `status: :failed` with `last_error` (schema `field(:last_error, :map)`, `delivery.ex:122`, shape `%{type: atom, message: binary, module: binary}`); a sent row with no report (`last_event_type: :sent`, no later event); a unicode recipient. `reject_reason` is an `Ecto.Enum` over `[:invalid, :bounced, :timed_out, :blocked, :spam, :unsubscribed, :other]` (`event.ex:73`). Seed onto Northstar (`tenant_id: "northstar"`).
- Invocation precedent: `reference/demo_app/mix.exs:93` `"demo.reset": ["run priv/repo/seeds.exs"]` and `priv/repo/seeds.exs` (`Mix.Task.run("app.start")` then call the module). Plan decision needed: who orders reset then catalog seed then capture. Recommended: the driver script owns the order (reset through the guarded Node helper, then `docker compose exec demo mix run -e 'MailglassDemo.CatalogSeed.seed!()'`, then the spec in a no-reset mode), because the existing spec resets in `beforeEach`.
- No telemetry or PII concern: all addresses are synthetic `*.example`.
**Commit kind:** `chore(demo):` or `test(demo):` (`reference/**` is shippable-classified by Guard Release Trigger, F12; verify the kind before committing).

---

### `reference/demo_app/assets/catalog/before-catalog.spec.js` + `playwright.catalog.config.cjs` (producer, file-I/O) NEW

**Analog:** `reference/demo_app/assets/e2e/persona-screenshots.spec.js` and `reference/demo_app/assets/playwright.config.cjs`.

**Placement (F9):** the demo config is `testDir: "./e2e"` and `test:e2e:ci` runs the whole directory plus `check-demo-browser-evidence.cjs`, so a spec in `./e2e` would run inside the advisory `demo_browser_evidence` lane and `make demo-e2e`. Put it under `assets/catalog/` with its own config whose `testDir: "./catalog"`.

**Config to copy** (`playwright.config.cjs`, whole file 54 lines; keep `workers: 1` with its comment about the destructive shared-DB reset, `externalServer = Boolean(process.env.DEMO_BASE_URL)`, `baseURL` from `DEMO_BASE_URL` or `PORT`, `expect: { timeout: 5_000 }`); change only `testDir` and drop the `webServer` block (the catalog always targets an explicit external demo).

**Routing + login + theme to copy** (persona-screenshots.spec.js):
```js
const { resetDisposableEvidence } = require("../scripts/check-persona-reset-target.cjs");   // line 54: reuse unchanged
const PERSONAS = ["northstar", "fjordline-aps", "helios-void"];                              // line 63
function urlFor(surface, persona, theme) { ... `/ops/mail?tenant_id=${persona}` ... }        // lines 115-129
async function openOperator(page, targetUrl) {                                               // lines 134-140
  const returnTo = encodeURIComponent(targetUrl);
  await page.goto(`/demo/login?return_to=${returnTo}`);
  await page.goto(targetUrl);
}
test.beforeEach(async ({ request }) => { await resetDisposableEvidence(request); });         // lines 150-152
```
**Deliberate departures from the analog (D-19):** the analog theme-switches with `?theme=` and `waitForLoadState("networkidle")` (lines 175, 36-38). The catalog must set the cookie `mailglass_admin_theme_v2` (D-10) plus `emulateMedia`, wait for `[data-phx-main].phx-connected` (`phase177-return.spec.js:5`), never `networkidle`, and use `fullPage: true`, `animations: "disabled"`, `caret: "hide"`, `reducedMotion: "reduce"` (`storybook-hooks.spec.js:182` precedent: `page.emulateMedia({ reducedMotion: "reduce" })`), context options `timezoneId: "UTC"`, `locale: "en-US"`, `deviceScaleFactor: 1`. Assert `document.fonts.check("400 16px Inter")` (`admin-assets.spec.js` precedent `document.fonts.check("400 14px Inter")`).

**Served-vs-disk identity pattern to reuse** (persona-screenshots.spec.js:238-315, the "working preview readiness" test): fetch the css URL found on the page (`/dev/mail/css-<md5>`), `crypto.createHash("md5")` equals the route digest, `sha256` of served bytes equals `sha256` of `mailglass_admin/priv/static/app.css` on disk (and `git show <sha>:mailglass_admin/priv/static/app.css`), then `execFileSync("git", ["rev-parse","HEAD"], { cwd: repoRoot })` with the `DEMO_CANDIDATE_REVISION` override (inside the container the bind-mounted repo trips "dubious ownership"). F5: `hooks.js` is not served by itself; hash the `js-<md5>` bundle and assert it contains the disk `hooks.js` bytes, or record disk and git-blob hashes only.
**Manifest identity fields (D-23):** `run_id`, `source_revision`, `source_digest` as in `scripts/run_demo_browser_evidence.sh` (lines ~560-566, 624-628); do NOT write `DEMO_EVIDENCE_RESET_TOKEN` or other env values into the manifest.
**Output:** write into the ignored staging dir `.planning/research/brand-v2-adoption/before-catalog/.cache/<catalog_id>/` (verified ignored by `.gitignore:45` `/.planning/research/**/.cache/`; the final path is NOT ignored; `git check-ignore -v` confirmed), validate, then promote.
**Budget (D-21):** fail past 80 images or 15 MB; record `budget {image_count, total_bytes, cap_bytes}`.
**Lane:** the run is not CI. The manifest test is the required proof (D-24/D-25).

---

### Catalog driver / promote script (file-I/O guard) NEW (name discretionary)

**Analogs (partial):**
- `reference/demo_app/assets/scripts/evidence-output-path.cjs` (whole file, 29 lines): path confinement to a root plus a per-segment `fs.lstatSync(...).isSymbolicLink()` walk:
```js
if (resolved !== EVIDENCE_ROOT && !resolved.startsWith(`${EVIDENCE_ROOT}${path.sep}`)) { throw new Error(...) }
...
if (fs.lstatSync(current).isSymbolicLink()) { throw new Error(`Demo browser evidence path contains a symlink: ${current}`); }
```
- `reference/demo_app/assets/scripts/check-persona-reset-target.cjs` `resetDisposableEvidence` (explicit loopback origin allow-list `SAFE_HOSTS`, `PROJECT_ID` regex, `/health` project-id header match): reuse unchanged for the destructive reset.
- `scripts/run_demo_browser_evidence.sh` lines 1-3, 38-46: `#!/usr/bin/env bash`, `set -euo pipefail`, `ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`, and "`Refusing to reuse existing evidence output owned by another run`" exit 1. Mirror that refusal for an existing `catalog_id`.
**Steps (D-17/D-19):** (1) refuse if `git status --porcelain --untracked-files=all` is non-empty excluding the staging dir (P10: harnesses that run `mix mailglass_admin.assets.build`, `scripts/run_demo_browser_evidence.sh:350`, would otherwise dirty the tree; safe only after D-03 lands); (2) compute `catalog_id = before-<sha7>-<UTCstamp>`; (3) capture into `.cache/`; (4) validate budget, hashes, same-state double capture identical; (5) promote by `fs.renameSync` of the whole directory to the tracked path, refusing if it exists (prevents `gsd-sdk query commit` from sweeping a half-written catalog). Filename slug regex `[a-z0-9_.-]+`, no path separators.

---

### `mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs` (test, manifest validator) NEW

**Analog A (repo-relative reads, failure message naming the file, parser guards against a vacuous pass):** `mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs`:
```elixir
@policy_path Path.expand("../../../docs/brand-v2-compatibility.md", __DIR__)   # line 25
@repo_root Path.expand("../../..", __DIR__)                                      # line 27
...
assert failures(compat_rows!()) == [], failure_message(failures(compat_rows!()))   # line 489
```
and its `describe "teeth"` (line 670+): feed each verifier a planted bad row and assert the reason names the cause (`assert reason =~ fragment`); `failure_message/1` (line 331) names the file and the row. Its header explains a "guards against a false green" list (must parse, must not be empty); do the same (assert at least one capture, the directory exists, exactly one `catalog_id` directory or the named one).
**Analog B (PNG validation + sha256):** `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex`:
```elixir
@png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>        # line 10
@max_png_dimension 32_768                                   # line 11
...
Base.encode16(:crypto.hash(:sha256, contents), case: :lower)   # line 207
defp validate_png!(contents, relative_path) do                  # lines 218-241 (IHDR width/height/crc check)
```
The test is `async: true`-safe (read-only). Use `@repo_root` and `Path.join(@repo_root, ".planning/research/brand-v2-adoption/before-catalog")`.
**Analog C (tmp-dir mutation):** `capture_manifest_test.exs:273-283` `tmp_dir/1`, copy the catalog into a tmp dir and mutate the copy: flip a PNG byte, add an unlisted PNG, set `"dirty": true`, exceed the byte cap, remove a listed file. Every mutation must go red; path-traversal in a manifest `file` name must be rejected (Security Domain: confine reads to the catalog directory).
**Checks (D-24):** manifest shape; each listed file exists with the recorded sha256 and a valid PNG header; no unlisted `*.png`; `git_sha` matches `~r/\A[0-9a-f]{40}\z/`; ancestry via `git merge-base --is-ancestor <sha> HEAD` ONLY when `git rev-parse --is-shallow-repository` prints `false` (F8: `support_contract_admin` uses a depth-1 checkout; or add `fetch-depth: 0` to that job, mirroring `ci.yml:30-33`); `dirty == false`; `image_count <= 80`, `total_bytes <= 15 MB`; `nested_theme_attr_count == 0`. Git precedent for tests: `test/mix/tasks/mailglass.repo.hygiene_test.exs:779-783` `{output, 0} = System.cmd("git", args, cd: repo, stderr_to_stdout: true)`.
**Landing constraint (F8):** `support_contract_admin` is `if: needs.changes.outputs.code == 'true'` and `.planning/**` is docs-only (except `.planning/publish/`), so a PNG-only PR skips the lane. Land the catalog in the SAME PR as this test file.
**Lane:** REQUIRED, admin `verify.support_contract.admin` (whole directory, no registration needed, D-25). If it were placed under core `test/mailglass/`, `scripts/check_test_exceptions.sh` would scan it (no `@tag :skip`, no `Process.sleep`) and only the full core suite would run it. Recommendation: admin.
**Commit kind:** `test(admin):`; catalog artifacts `docs:`.

---

## Shared Patterns

### Contract-test discipline (applies to all three new ExUnit files)
**Source:** `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs` lines 1-17, 71-93, 447-456.
- Moduledoc states what is machine-checked and in which lane; `use ExUnit.Case, async: true` unless an HTTP-endpoint case template needs `async: false` (`router_test.exs`, `operator_live_test.exs`).
- A "detectors have teeth" block feeds each detector a known violation and a known clean fixture. Each rule is ALSO proven red by a temporary source mutation recorded in the plan SUMMARY, then reverted (METHODOLOGY mutation protocol).
- Failure messages name the cause and the fix (`brand_v2_compat_policy_test.exs` `failure_message/1`, line 331).
- No `@tag :skip`, no `Process.sleep`, no edits above any registered `config/test_exceptions.exs` `file:line` entry.
- Never mutate global `Application` env in an async test (memory: Clock global async leak); inject through opts.
- Run `cd mailglass_admin && mix format --check-formatted` locally (the CI format gate is root-only, D-09).

### Error and failure-message voice
**Source:** `dev/mix/tasks/mailglass_admin.preview.capture.ex:82-84, 101` (`"Preview capture blocked: CI requires exactly --mailables ..."`).
**Apply to:** the `--check` `Mix.raise`, the manifest-test messages, the catalog script refusals. State the cause and the exact command. Never "Oops".

### Optional-dep and compile-time safety
**Source:** `lib/mix/tasks/mailglass_admin.assets.build.ex:2` and `mix.exs:72-88` (`elixirc_paths(:dev) = ["lib", "dev"]`, `(:test) = ["lib", "test/support", "dev", @persona_spec_dir]`, `(_) = ["lib"]`).
**Apply to:** `Tailwind.*` references live in `dev/` only. `dev/` is compiled in `:dev` and `:test`, excluded from the Hex `files:` list (`mix.exs` package `files: ~w(lib priv/static docs ...)`), so the shipped `lib/` task never compile-references `Tailwind`. Do not add `compile --warnings-as-errors` to the new gate: it already fails at HEAD on the unrelated `MailglassDemo.QuickViewScenarios is not included in any boundary` warning (RESEARCH Anti-Patterns).

### Theme ownership contract (single source)
**Source:** `lib/mailglass_admin/layouts/root.html.heex:2`, `layouts.ex:70-85`, `theme.ex:51-53`, cookie `MailglassAdmin.Theme.cookie_name()` (`"mailglass_admin_theme_v2"`).
**Apply to:** every BRPIPE-02 file. `<html data-theme>` from the cookie; attribute absent for system; the picker is a full round trip (`operator_live.ex:274-279` redirect to `/theme/<segment>`, `router.ex:353`, `ThemeController`). No client JS. No class or inline style may re-declare `--mg-*` or `--color-*` (the same defect under another name).

### Lane assignment (state per requirement; never cite an advisory lane as proof)
| Requirement | Required-lane proof | Advisory only |
|---|---|---|
| BRPIPE-01 | `mix verify.support_contract.admin` alias step 1 (`--check`) + `bundle_reproducibility_contract_test.exs` | optional throwaway draft PR showing `CI Green` red |
| BRPIPE-02 | `root_theme_ownership_contract_test.exs` + reworked `admin_shell_test.exs` / `preview_live_test.exs` | `e2e/theme-ownership.spec.js` (`operator_browser_gate`, `ci_policy.exs:145`) |
| BRPIPE-03 | `before_catalog_manifest_test.exs` (same PR as the catalog) | the capture run itself, demo Playwright |
All required work is picked up by the existing `support_contract_admin` job (`ci.yml:886-946`, `local_alias: "verify.support_contract.admin"` in `config/quality/ci_policy.exs:56-60`). No new `ci.yml` job, no `CILanes` registration, root `mix.exs` untouched (D-25).

### Commit-kind map (Guard Release Trigger, F12; one open PR at a time)
| Path class | Kind |
|---|---|
| `mailglass_admin/lib/**`, `priv/static/app.css` behaviour | `fix(admin):` or `refactor(admin):`, own commit |
| `mailglass_admin/assets/css/app.css`, `mix.exs`, `.github/workflows/ci.yml`, scripts | `chore(admin):` / `ci:` (shippable-classified, separate commits) |
| `mailglass_admin/test/**`, `dev/**`, `e2e/**` (release-please `exclude-paths`) | `test(admin):` / `chore(admin):` (a `fix:` whose diff is only tests and `.planning` fails the guard) |
| `.planning/**`, `*.md` | `docs:` |
`CLAUDE.md` is NOT edited in this phase (owner sign-off); record the false "CI runs `git diff --exit-code`" line as a Phase 183 follow-up.

### Playwright conventions
**Source:** `mailglass_admin/e2e/flows.spec.js:1-62`, `structural.spec.js:828`, `reference/demo_app/assets/e2e/persona-screenshots.spec.js`.
`emulateMedia` BEFORE navigation; add theme cookies AFTER `loginOperator` (it calls `page.context().clearCookies()`); wait on `[data-phx-main].phx-connected`; per-file helper duplication is the repo convention; `workers: 1` against any shared-DB demo; evidence is never a pixel-diff baseline (root `.gitignore` lines ~40-45).

### Staging then promote for any `.planning/` artifact
**Source:** `.gitignore:45` `/.planning/research/**/.cache/` (confirmed ignored); memory `gsd-sdk query commit` sweeps ALL dirty `.planning/` paths.
**Apply to:** the catalog capture only. Write into `.cache/`, validate, atomic rename to `.planning/research/brand-v2-adoption/before-catalog/<catalog_id>/`, never overwrite.

---

## No Analog Found

| File | Role | Data Flow | Reason / fallback |
|---|---|---|---|
| Catalog capture producing a TRACKED PNG set plus `manifest.json` | producer | file-I/O | The only existing screenshot producer (`persona-screenshots.spec.js`) writes to the git-ignored `.cache/` and emits no manifest. Closest: that spec for routing/login/readiness, `CaptureManifest` (`dev/mailglass_admin/preview/capture_manifest.ex`) for JSON shape and sha256 per file, `scripts/run_demo_browser_evidence.sh` for `run_id`/`source_revision`/`source_digest`. Use RESEARCH F5/F6/F9 and CONTEXT D-18/D-19/D-23. |
| Atomic stage-validate-promote of a `.planning/` directory | script | file-I/O | No existing promote step. Compose from `evidence-output-path.cjs` (confinement, symlink walk) and the "Refusing to reuse existing evidence output" idiom in `scripts/run_demo_browser_evidence.sh:38-46`. |
| Reset-then-catalog-seed ordering across the Docker boundary | orchestration | request-response + exec | No precedent for running a Mix seed after `POST /demo/evidence/reset` from outside the container. Closest: `"demo.reset": ["run priv/repo/seeds.exs"]` (`reference/demo_app/mix.exs:93`). Plan decision (see catalog_seed section). |
| `--check` byte-compare of a generated Tailwind bundle | utility | subprocess | No existing generated-artifact drift gate in `mailglass_admin` (that is the defect). Use RESEARCH Code Example 1 (verified prototype) over `chromium.ex` for the subprocess shape. |
| Per-theme Preview iframe backdrop via wrapper `color-scheme` + `Canvas` | component | render | No precedent; RESEARCH Code Example 5 is probe-verified in Chromium and WebKit. Firefox unverified (A5), visual only. |

## Metadata

**Analog search scope:** `mailglass_admin/{lib,dev,test,e2e,assets,scripts}`, `mailglass_admin/{mix.exs,config,playwright.config.cjs}`, `reference/{demo_app,persona_spec}`, `test/scripts`, `scripts/`, `.github/workflows/ci.yml`, `config/quality/ci_policy.exs`, `test/support/ci_lanes.ex`.
**Files read:** 38 (plus targeted line-range reads of 60+ more for line numbers).
**Tracked-source gate:** 39 analog paths verified with `git ls-files`; all tracked.
**Pattern extraction date:** 2026-11-14
