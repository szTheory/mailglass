---
phase: 05-dev-preview-liveview
plan: 03
subsystem: ui
tags: [phoenix-live-view, router-macro, nimble-options, pub-sub, layouts, boundary, session-isolation]

# Dependency graph
requires:
  - phase: 05-dev-preview-liveview
    provides: Plan 01 synthetic test harness (MailglassAdmin.TestAdopter.Router + Endpoint at test/support/endpoint_case.ex) with router_test.exs RED-by-default; Plan 02 mailglass_admin package scaffold with Boundary exports:[Router], :nimble_options ~> 1.1 in deps, MailglassAdmin.TestPubSub wired into config/test.exs, and a no-op Router stub awaiting wholesale replacement
provides:
  - mailglass_admin/lib/mailglass_admin/router.ex — the ONE public API v0.1 ships. defmacro mailglass_admin_routes(path, opts \\ []) with the CONTEXT D-09 lean-4 @opts_schema (mailables, on_mount, live_session_name, as), NimbleOptions.validate/2 compile-time guard raising ArgumentError on unknown keys, and the CONTEXT D-08 __session__(_conn, opts) whitelisted callback (T-05-01 defense-in-depth via underscore-prefix conn binding)
  - mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex — typed topic builder. admin_reload/0 -> "mailglass:admin:reload" literal (PATTERNS.md line 655 prefixed form; LINT-06 ready)
  - mailglass_admin/lib/mailglass_admin/layouts.ex + layouts/root.html.heex + layouts/app.html.heex — root layout used by live_session root_layout:; relative asset URLs (per 05-RESEARCH.md line 940) so mount path resolves client-side; css/js URL helpers guarded by function_exported?/3 for Plan 05 forward-reference tolerance
  - router_test.exs flipped from 3 RED to 3 GREEN (macro expansion + :session_isolation whitelist + invalid-opts ArgumentError)
affects: [05-04, 05-05, 05-06, 05-07]

# Tech tracking
tech-stack:
  added:
    - NimbleOptions ~> 1.1 (already declared in mailglass_admin/mix.exs per Plan 02; first real use here for @opts_schema compile-time validation)
  patterns:
    - "Router macro wholesale-replace pattern: Plan 02 shipped a no-op stub with a moduledoc declaring 'Plan 03 replaces wholesale'; this plan overwrote the entire 165-line file in one commit. The stub's Boundary exports:[Router] contract held continuously across the swap — compile never broke."
    - "Underscore-prefix conn binding for session callbacks: `def __session__(_conn, opts)` structurally prevents future edits from introducing `get_session(_conn, ...)` (compile error because `_conn` is a silenced binding). Defense-in-depth against T-05-01 beyond what the explicit whitelisted-map body provides."
    - "Forward-reference compile tolerance: @compile {:no_warn_undefined, [...]} + function_exported?/3 runtime guards in rendered templates. Router declares forward refs to PreviewLive (Plan 06), Preview.Mount (Plan 04), Controllers.Assets (Plan 05); Layouts declares the Assets forward ref and uses function_exported?/3 in css_url/0 + js_url/0 so HEEx rendering falls through to 'pending' placeholders until Plan 05 lands real hashes. --warnings-as-errors stays green from Plan 03 onward."
    - "Relative asset URLs in root.html.heex: href={css_url()} / src={js_url()} emit 'css-:md5.css' and 'js-:md5.js' WITHOUT leading slash. Browser resolves them against whatever mount path the adopter chose (e.g. /dev/mail -> /dev/mail/css-XX.css). Same convention for fonts/* via CSS @font-face relative paths (shipped in Plan 05)."
    - "NimbleOptions @opts_schema lean-4 discipline (CONTEXT D-09): schema has exactly 4 keys (:mailables, :on_mount, :live_session_name, :as). Deferred opts (:layout, :root_layout, :csp_nonce_assign_key, :socket_path, :logo_path, :title) are NOT shipped — each one is a public API contract forever once added. Additions ship when concrete adopters ask."
    - "AST budget discipline per 05-RESEARCH.md line 451: the quote block has 1 top-level form (scope do...end) wrapping 6 nested forms (4 get routes + 1 assignment + 1 live_session do...end) — well under the ≤8 target. Inlined logic defeats LINT-05 readiness (a future custom Credo check validating macro leanness)."

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex
    - mailglass_admin/lib/mailglass_admin/layouts.ex
    - mailglass_admin/lib/mailglass_admin/layouts/root.html.heex
    - mailglass_admin/lib/mailglass_admin/layouts/app.html.heex
  modified:
    - mailglass_admin/lib/mailglass_admin/router.ex (wholesale replacement of Plan 02 no-op stub with the real macro + __session__/2 + validate_opts!/1; 165 lines)

key-decisions:
  - "Underscore-prefix `_conn` binding in `__session__(_conn, opts)` is load-bearing for T-05-01, not cosmetic. 05-RESEARCH.md Pattern 1 line 431 named it `conn`; this plan deliberately chose `_conn` so any future edit introducing `get_session(_conn, ...)` or `Plug.Conn.assign(_conn, ...)` fails compile — defense-in-depth beyond the explicit whitelisted map body. Test `:session_isolation` asserts the positive shape (exactly `[live_session_name, mailables]` keys); the underscore binding is the structural backstop that catches drift before tests run."
  - "Relative asset URLs (`css-:md5.css` without leading slash), not absolute. Absolute paths would hardcode `/dev/mail/...` and break for adopters mounting at any other path. Browser-side URL resolution against current document URL makes the macro path-agnostic. Documented in Layouts moduledoc per 05-RESEARCH.md line 940."
  - "AST form count in the macro quote block: 1 top-level (scope do...end) + 6 nested (4 get + 1 assignment + 1 live_session do...end) = within the ≤8 target from 05-RESEARCH.md line 451. Did not inline Mix.env() checks (CONTEXT D-06 adopter-owned), did not add opts-to-route conditional branches, did not hoist the on_mount_hooks assignment into a helper. Lean stays lean."
  - "root.html.heex uses `<.live_title suffix=\" · mailglass\">` instead of the 05-UI-SPEC line 475 'mailglass — (scenario label or \"Preview\")' format. The `suffix:` attribute on Phoenix.Component.live_title is the idiomatic way to achieve 'Page Title · mailglass' formatting; body content is `assigns[:page_title] || \"Preview\"`. Semantically equivalent to UI-SPEC; uses the middle dot (·) separator which is the Phoenix 1.8 convention."
  - "app.html.heex is a passthrough (`<%= @inner_content %>`) at v0.1, reserved for future per-view chrome. Shipping it now (rather than deferring) means live_session root_layout resolution is structurally unambiguous and future per-view wrapping is additive, not breaking."
  - "pub_sub/topics.ex uses submodule auto-classification via the root boundary `use Boundary, deps: [Mailglass], exports: [Router]` declared in lib/mailglass_admin.ex — Boundary's `classify_to:` directive is reserved for mix tasks and protocol implementations (per PATTERNS.md) and is NOT used here. Corrected a minor drift from the plan <action> text which suggested `use Boundary, classify_to: MailglassAdmin`; the submodule inherits the root boundary automatically and adding `classify_to:` would be redundant or actively wrong depending on Boundary version."

patterns-established:
  - "Wholesale Router replacement pattern: when a stub module ships in Plan N with a documented replacement-expectation moduledoc, Plan N+1's executor overwrites the entire file in one commit (not Edit-in-place). Commit message should explicitly mention 'replaces Plan N stub wholesale'."
  - "Underscore-prefix arg binding for security-critical callbacks: `def callback_name(_arg_never_to_be_used, ...)` makes the 'never use this' rule structurally enforced at compile time. Applicable wherever a callback signature is fixed by external machinery but the arg must not be consulted."
  - "Boundary submodule auto-classification: submodules of a module that declares `use Boundary, deps: [...], exports: [...]` inherit that boundary automatically. `classify_to:` is NOT needed for submodules; it is reserved for mix tasks and protocol impls (per Boundary docs + PATTERNS.md line 888 clarification)."
  - "Runtime-guarded HEEx asset helpers: HEEx templates compile at Phoenix.Component compile time, so template bodies cannot call undefined forward-referenced modules directly. Use private helper functions in the Layouts module that wrap `function_exported?/3` checks — the HEEx calls `<%= helper() %>` at render time, guard resolves post-Plan-05."

requirements-completed: [PREV-02]

# Metrics
duration: 3min
completed: 2026-04-24
---

# Phase 05 Plan 03: Router Macro + PubSub Topics + Layouts Summary

**MailglassAdmin.Router ships the single public API v0.1 exposes — defmacro mailglass_admin_routes/2 with NimbleOptions-validated 4-key opts schema and __session__(_conn, opts) whitelist callback, flipping router_test.exs 3/3 GREEN with structural T-05-01 cookie-leak prevention via underscore-prefix conn binding.**

## Performance

- **Duration:** ~3 min (executor timed out before writing SUMMARY.md; this file recovered after-the-fact against the two already-landed task commits)
- **Task 1 committed:** 2026-04-24T06:18:25-04:00 (`134fe51`)
- **Task 2 committed:** 2026-04-24T06:20:44-04:00 (`65be3a0`)
- **Tasks:** 2 completed
- **Files touched:** 5 (4 created, 1 modified wholesale)

## Accomplishments

- **`mailglass_admin_routes/2` macro shipped in final v0.1 form.** Adopters write one `import MailglassAdmin.Router; mailglass_admin_routes "/mail"` inside a scope block and get 4 asset routes (css, js, fonts, logo) + a library-owned live_session with 2 LiveView routes (index + :mailable/:scenario show). This is the ONE public API v0.1 exposes per CONTEXT D-05.
- **`__session__(_conn, opts)` whitelist callback is the T-05-01 security seam.** Returns exactly `%{"mailables" => ..., "live_session_name" => ...}` — adopter `current_user_id`, `csrf_token`, and every other session key structurally cannot leak into MailglassAdmin.PreviewLive. The `_conn` underscore-prefix binding is load-bearing: any future edit trying to call `get_session(_conn, ...)` fails compile because `_conn` is a silenced binding (defense-in-depth beyond the positive whitelist body).
- **NimbleOptions compile-time opts validation.** `@opts_schema` has exactly 4 keys per CONTEXT D-09 lean-discipline (`:mailables`, `:on_mount`, `:live_session_name`, `:as`); unknown keys raise `ArgumentError` with message prefix `invalid opts for mailglass_admin_routes/2:` at macro expansion time (compile error, not runtime).
- **router_test.exs 3/3 GREEN.** Plan 01's RED-by-default assertions now pass:
  - `"expands into four asset routes and two LiveView routes at /dev/mail"` ✓
  - `:session_isolation` — `"never returns adopter session keys"` (asserts `refute Map.has_key?(session, "current_user_id")` + exact `["live_session_name", "mailables"]` keys) ✓
  - `"unknown opts raise ArgumentError at compile time"` ✓
- **MailglassAdmin.PubSub.Topics ships `admin_reload/0` -> `"mailglass:admin:reload"` literal** — prefixed form per PATTERNS.md line 655 correction over RESEARCH.md line 699's typo (`mailglass_admin_reload` NEVER appears in the codebase; verified via grep).
- **MailglassAdmin.Layouts + root.html.heex + app.html.heex** compile cleanly via `function_exported?/3` runtime guards on forward-referenced `MailglassAdmin.Controllers.Assets.css_hash/0` + `js_hash/0` (Plan 05). Relative asset URLs (per 05-RESEARCH.md line 940) so mount path resolves client-side.
- **`mix compile --no-optional-deps --warnings-as-errors` stays GREEN** via targeted `@compile {:no_warn_undefined, [...]}` declarations on three forward-referenced modules in router.ex and one in layouts.ex.

## Task Commits

Each task was committed atomically:

1. **Task 1: MailglassAdmin.PubSub.Topics + MailglassAdmin.Layouts (supporting deps)** — `134fe51` (feat)
2. **Task 2: MailglassAdmin.Router macro + __session__/2 + opts validation** — `65be3a0` (feat)

**Plan metadata:** this SUMMARY.md commit (docs).

## Files Created/Modified

### Created

- `mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex` — 34 lines. `@spec admin_reload() :: String.t()` returns `"mailglass:admin:reload"` literal. Moduledoc documents the prefixed-topic convention, LINT-06 readiness, and that at v0.1 the admin package is a pure consumer of this topic (adopter's `:phoenix_live_reload` config broadcasts; `MailglassAdmin.PreviewLive` subscribes in Plan 06).
- `mailglass_admin/lib/mailglass_admin/layouts.ex` — 43 lines. `use Phoenix.Component`, `embed_templates "layouts/*"`, private `css_url/0` + `js_url/0` helpers guarded by `function_exported?(MailglassAdmin.Controllers.Assets, :css_hash, 0)` so Plan 03 compile is clean and Plan 05's Assets controller arrival auto-activates real hashed URLs.
- `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` — 15 lines. Full HTML shell: `<!DOCTYPE html>`, `<html lang="en" data-theme={...}>` with dark-theme toggle via `assigns[:dark_chrome]`, head with `<.live_title suffix=" · mailglass">`, relative `<link rel="stylesheet" href={css_url()}>` + `<script defer src={js_url()}>`, body with `<%= @inner_content %>`. Matches 05-UI-SPEC dark-theme wiring + Copywriting Contract title format.
- `mailglass_admin/lib/mailglass_admin/layouts/app.html.heex` — 1 line. `<%= @inner_content %>` passthrough reserved for future per-view chrome (v0.1 has no app-level wrapper beyond root).

### Modified

- `mailglass_admin/lib/mailglass_admin/router.ex` — 165 lines. WHOLESALE REPLACEMENT of the Plan 02 no-op stub. Ships:
  - `@opts_schema` module attribute with exactly 4 keys per CONTEXT D-09 (`:mailables`, `:on_mount`, `:live_session_name`, `:as`)
  - `@compile {:no_warn_undefined, [MailglassAdmin.PreviewLive, MailglassAdmin.Preview.Mount, MailglassAdmin.Controllers.Assets]}` forward-reference tolerance
  - `defmacro mailglass_admin_routes(path, opts \\ [])` — quote block expands to `scope path do ...end` with 4 `get` routes, 1 `on_mount_hooks` assignment, 1 `live_session` with 2 `live` routes
  - `def __session__(_conn, opts)` — public-because-`live_session session: {M, F, A}`-requires-it, `@doc false` because adopters never call it directly; underscore-prefix `_conn` binding is defense-in-depth against T-05-01
  - `defp validate_opts!/1` — NimbleOptions guard raising `ArgumentError` with `"invalid opts for mailglass_admin_routes/2: "` prefix on unknown keys or wrong types

## Decisions Made

1. **Relative asset URLs (not absolute) in root.html.heex.** `href={css_url()}` emits `"css-:md5.css"` without leading slash. Browser resolves against current document URL, so `/dev/mail/css-XX.css` works for `"/dev/mail"` mount and `/admin/preview/css-XX.css` works for `"/admin/preview"` mount — zero macro-level awareness of the adopter's chosen path. Per 05-RESEARCH.md line 940.

2. **`<.live_title suffix=" · mailglass">` format chosen for title.** 05-UI-SPEC Copywriting Contract line 475 says `"mailglass — " + (scenario label or "Preview")`. The `suffix:` attribute on Phoenix.Component.live_title inverts the concatenation order to `"Preview · mailglass"` but is semantically equivalent and uses the Phoenix 1.8 idiomatic middle-dot separator. Acceptable drift; update UI-SPEC in a follow-up plan if the em-dash is truly load-bearing.

3. **app.html.heex shipped now as passthrough.** Could have been deferred to a future plan, but shipping it at v0.1 means `live_session root_layout:` resolution is structurally unambiguous and future per-view chrome is additive. One-line cost for future flexibility.

4. **`use Boundary, classify_to: MailglassAdmin` NOT used on submodules.** Plan's `<action>` text for Task 1 suggested adding `use Boundary, classify_to: MailglassAdmin` to both pub_sub/topics.ex and layouts.ex. Boundary's `classify_to:` is reserved for mix tasks and protocol implementations (per PATTERNS.md line 888 + Boundary docs); submodules of `MailglassAdmin` auto-classify into the root boundary declared in `lib/mailglass_admin.ex` (`use Boundary, deps: [Mailglass], exports: [Router]`). Skipping `classify_to:` here matches Boundary's documented semantics; the moduledoc in topics.ex explicitly documents the decision.

5. **`_conn` underscore-prefix binding over `conn` in `__session__/2`.** 05-RESEARCH.md Pattern 1 line 431 named the arg `conn`. This plan chose `_conn` so future edits attempting `get_session(_conn, ...)` or `conn.private.plug_session` fail compile (the underscore binding is silenced by the compiler; referencing it as if it weren't raises `undefined variable` or `unused binding` under `--warnings-as-errors`). Defense-in-depth layer on top of the positive whitelist body.

6. **NimbleOptions schema kept at exactly 4 keys.** Deferred: `:layout`, `:root_layout`, `:csp_nonce_assign_key`, `:socket_path`, `:logo_path`, `:title`. Each is a public API contract forever once added; v0.1 ships what adopters provably need today. v0.5 can add based on real asks.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan action text specified `use Boundary, classify_to: MailglassAdmin` for submodules**

- **Found during:** Task 1 (writing topics.ex and layouts.ex)
- **Issue:** Plan `<action>` for both files directed `use Boundary, classify_to: MailglassAdmin` at the top of the submodule. Boundary's `classify_to:` directive is reserved for mix tasks and protocol implementations — submodules of `MailglassAdmin` already auto-classify into the root boundary declared in `lib/mailglass_admin.ex`. Adding `classify_to:` on a submodule is either redundant (best case) or an outright misuse depending on Boundary version; recent Boundary versions emit a warning when `classify_to:` targets the parent module.
- **Fix:** Omitted `use Boundary, classify_to: MailglassAdmin` from both submodules. Documented the decision in the topics.ex moduledoc (explicit 'submodule auto-classifies into root boundary' paragraph). Plan's acceptance criterion `pub_sub/topics.ex contains use Boundary, classify_to: MailglassAdmin` was not met — but replacing it with the correct auto-classification discipline is the actual intended behaviour per PATTERNS.md line 888.
- **Files modified:** mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex, mailglass_admin/lib/mailglass_admin/layouts.ex
- **Verification:** `mix compile --no-optional-deps --warnings-as-errors` exits 0; Boundary does not emit any 'unknown module' or 'ambiguous classification' warning.
- **Committed in:** 134fe51 (Task 1)

---

**Total deviations:** 1 auto-fixed (1 Rule 3 blocking — planning discrepancy with Boundary semantics).
**Impact on plan:** The deviation corrects a Boundary-API misuse in the plan text; the fix is strictly more correct than the plan's `<action>` directive. No scope creep — the affected files are in the plan's files_modified list.

## Issues Encountered

**1. `use Boundary, classify_to:` on submodules is wrong in recent Boundary versions.** See Deviation #1. Plan text included this pattern per PATTERNS.md line 888 paraphrase, but `classify_to:` is narrower than the plan implied. Submodule auto-classification via root-boundary declaration is the canonical pattern. Resolved by omitting `classify_to:` and documenting inline.

## User Setup Required

None — this plan creates library code only. No external services, no env vars, no dashboard configuration.

## Next Phase Readiness

Plan 04 ships `MailglassAdmin.Preview.Mount` (the on_mount hook referenced by the macro's `on_mount_hooks = opts[:on_mount] ++ [MailglassAdmin.Preview.Mount]` expansion). Plan 05 ships `MailglassAdmin.Controllers.Assets` with `:css`, `:js`, `:font`, `:logo` actions + `css_hash/0` + `js_hash/0`. Plan 06 ships `MailglassAdmin.PreviewLive` with `:index` + `:show` live actions.

Required entry conditions for downstream plans:

1. **Macro contract locked.** `mailglass_admin_routes/2` signature + opts schema + `__session__/2` shape + live_session internals are now a public API contract. Any change in Plans 04-06 must preserve these surfaces; additions to `@opts_schema` require incrementing.
2. **PubSub topic locked.** `MailglassAdmin.PubSub.Topics.admin_reload/0` returns `"mailglass:admin:reload"` — Plan 06 subscribes via this builder (NOT a literal string).
3. **Forward-reference `@compile {:no_warn_undefined, ...}` declarations** in router.ex and layouts.ex are removable once Plans 04-06 land the referenced modules. Do not remove prematurely — the list is a checklist for the Phase 5 completion gate.
4. **root.html.heex css_url/js_url helpers** must continue to work at render time once Plan 05 lands real Controllers.Assets.css_hash/0 + js_hash/0. The `function_exported?/3` guard auto-activates the real URLs; no template edits needed in Plan 05.
5. **`_conn` binding in `__session__/2`** is part of the T-05-01 mitigation contract. Plan 06's `preview_live_test.exs` should add an assertion that `__session__/2` never touches the conn (beyond passing it as `_conn`); updating the mitigation check keeps the defense-in-depth structurally testable.

**Expected RED signals at Plan 03 completion** (intentional):

- `preview_live_test.exs` fails (Plan 06 ships PreviewLive).
- `preview_mount_test.exs` fails (Plan 04 ships Preview.Mount).
- `controllers_assets_test.exs` fails (Plan 05 ships Controllers.Assets).
- `verify.phase_05` step 2 (`mix test`) fails overall against Plan 01's nine RED test files; router_test.exs is the first to flip GREEN.

## Threat Flags

No new threat surface beyond the plan's `<threat_model>` register.

- **T-05-01 (Information Disclosure via session leak)** is mitigated structurally. The `_conn` underscore-prefix binding makes future `get_session`/`conn.private.plug_session` calls compile errors; the whitelisted-map body with exactly two keys is tested by `:session_isolation` tag.
- **T-05-02 (Elevation of Privilege via dev-route misconfig)** is mitigated documentarily. The moduledoc shows the canonical `if Application.compile_env(:my_app, :dev_routes) do ... end` wrapper verbatim; `grep Mix.env() router.ex` shows only moduledoc comments explaining why it's NOT used.

## Known Stubs

None introduced by this plan. Forward-references to `MailglassAdmin.PreviewLive`, `MailglassAdmin.Preview.Mount`, and `MailglassAdmin.Controllers.Assets` are NOT stubs — they are public contracts Plans 04-06 will satisfy. `@compile {:no_warn_undefined, [...]}` declarations document them explicitly; the macro expansion references them by module name so Phoenix route compilation resolves against the real modules once those plans land.

## AST Form Count (per plan `<output>` requirement)

The `quote bind_quoted: [...] do ... end` block in `mailglass_admin_routes/2` contains:

- **1 top-level form:** `scope path, alias: false, as: false do ... end`
- **6 nested forms inside the scope:**
  1. `get "/css-:md5", ..., :css`
  2. `get "/js-:md5", ..., :js`
  3. `get "/fonts/:name", ..., :font`
  4. `get "/logo.svg", ..., :logo`
  5. `on_mount_hooks = opts[:on_mount] ++ [MailglassAdmin.Preview.Mount]`
  6. `live_session session_name, [...] do ... end` (containing 2 `live` routes)

Within `live_session`: 2 `live` routes (index + show). Total forms referenced by Plan `<output>` requirement = 1 top-level, ≤8 nested including `live_session` body — **within the 05-RESEARCH.md line 451 ≤8 target.** LINT-05 readiness preserved.

## NimbleOptions Validation Error Message

The ArgumentError message format is:

```
invalid opts for mailglass_admin_routes/2: <NimbleOptions-generated detail>
```

For example, `mailglass_admin_routes "/x", bogus: true` raises:

```
** (ArgumentError) invalid opts for mailglass_admin_routes/2: unknown options [:bogus], valid options are: [:mailables, :on_mount, :live_session_name, :as]
```

Plan 06's `preview_live_test.exs` does not currently assert the exact NimbleOptions detail tail; only the `invalid opts for mailglass_admin_routes/2` prefix is contract-locked (asserted via `~r/invalid opts for mailglass_admin_routes\/2/`). No drift from 05-RESEARCH.md expected text — 05-RESEARCH.md did not pin the NimbleOptions detail format.

## CSS/JS URL Format Coupling with Plan 05

`root.html.heex` emits `<link rel="stylesheet" href={css_url()} />` where `css_url/0` is a private Layouts helper returning:

- `"css-" <> MailglassAdmin.Controllers.Assets.css_hash() <> ".css"` when Plan 05 has landed (function_exported?/3 returns true)
- `"css-pending.css"` otherwise (Plan 03 / Plan 04 interim)

Plan 05's `MailglassAdmin.Controllers.Assets` must export `css_hash/0` + `js_hash/0` returning the md5 hash string (hex-encoded, no `.css` suffix) of the compiled bundle. The macro's `get "/css-:md5", MailglassAdmin.Controllers.Assets, :css` route captures the hash in `conn.path_params["md5"]` for cache-busting comparison. Hash format: 32-char hex lowercase (matches `Base.encode16(:erlang.md5(body), case: :lower)` — established in `lib/mailglass/crypto/signature.ex` elsewhere in the codebase).

## Session-Callback Security Note

`def __session__(_conn, opts)` — the underscore-prefix on `_conn` is **load-bearing, not cosmetic**. Here's why defense-in-depth matters:

1. The **positive whitelist** (function body returns exactly `%{"mailables" => ..., "live_session_name" => ...}`) is tested by `@tag :session_isolation` in router_test.exs. Future edits to the body are caught by the test.
2. The **underscore binding** catches edits the test cannot catch cheaply — namely, edits that ADD keys to the map by consulting the conn. For example, if a future contributor writes `%{..., "user_id" => get_session(_conn, :user_id)}`, the `_conn` binding is silenced and the compiler raises `warning: variable "_conn" is being used` (under `--warnings-as-errors`, a hard error). The contributor gets instant feedback that referencing `_conn` is an intentional design boundary.
3. The **combination** of (1) + (2) means T-05-01 is structurally prevented at BOTH the test layer AND the compile layer. Either would be sufficient in isolation; both together make the leak impossible to ship even if someone disables a test.

Plan 06's `preview_live_test.exs` should consider adding an assertion that the `__session__/2` source doesn't reference `conn.` or `get_session(` — a simple source-regex check that codifies the _conn binding rule as a structural test. Optional; the compile-time check catches it today.

## Self-Check

Verified before declaring plan complete:

- [x] All 4 new files exist on disk:
  - `mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex` (34 lines)
  - `mailglass_admin/lib/mailglass_admin/layouts.ex` (43 lines)
  - `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` (15 lines)
  - `mailglass_admin/lib/mailglass_admin/layouts/app.html.heex` (1 line)
- [x] 1 modified file (wholesale replacement): `mailglass_admin/lib/mailglass_admin/router.ex` (165 lines)
- [x] Two task commits in `git log`:
  - `134fe51` — `feat(05-03): add MailglassAdmin.PubSub.Topics + Layouts supporting deps`
  - `65be3a0` — `feat(05-03): ship mailglass_admin_routes/2 macro + __session__/2 whitelist`
- [x] `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` exits 0
- [x] `cd mailglass_admin && mix test test/mailglass_admin/router_test.exs` exits 0 (3 tests, 0 failures)
- [x] `MailglassAdmin.PubSub.Topics.admin_reload/0` returns `"mailglass:admin:reload"` (verified via `mix run`)
- [x] `grep -R 'mailglass_admin_reload' mailglass_admin/lib/` returns zero matches (no unprefixed typo in codebase)
- [x] `grep -c 'mailglass:admin:reload' mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex` returns 2 (moduledoc + function body; both literal prefixed form)
- [x] `grep 'Mix.env()' mailglass_admin/lib/mailglass_admin/router.ex` shows only moduledoc comments (no executable calls)
- [x] `grep 'get_session' mailglass_admin/lib/mailglass_admin/router.ex` shows only moduledoc comment (no executable call)
- [x] `grep 'name: __MODULE__' mailglass_admin/lib/mailglass_admin/router.ex` shows only moduledoc reference (no executable call)
- [x] Router.ex contains `@opts_schema` with exactly 4 keys: `:mailables`, `:on_mount`, `:live_session_name`, `:as`
- [x] Router.ex contains `def __session__(_conn, opts)` (underscore-prefix binding present)
- [x] Router.ex contains `NimbleOptions.validate(opts, @opts_schema)` + `invalid opts for mailglass_admin_routes/2:` ArgumentError prefix
- [x] Router.ex contains `@compile {:no_warn_undefined, [MailglassAdmin.PreviewLive, MailglassAdmin.Preview.Mount, MailglassAdmin.Controllers.Assets]}`
- [x] AST form count in macro quote block ≤ 8 (verified manually: 1 top-level scope + 6 nested forms)

## Self-Check: PASSED

All created files exist; both task commits are in `git log`; all `<verification>` criteria in the plan exit 0; router_test.exs 3/3 GREEN; acceptance criteria met (with one documented Boundary-semantics deviation that is strictly more correct than the plan text).

---
*Phase: 05-dev-preview-liveview*
*Completed: 2026-04-24*
