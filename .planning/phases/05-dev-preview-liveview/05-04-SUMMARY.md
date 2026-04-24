---
phase: 05-dev-preview-liveview
plan: 04
subsystem: ui
tags: [phoenix-live-view, on-mount, reflection, graceful-failure, boundary, mailable-discovery]

# Dependency graph
requires:
  - phase: 05-dev-preview-liveview
    provides: Plan 01 RED-by-default discovery_test.exs (6 tests targeting explicit-list / :no_previews / raising / auto_scan / non-mailable ArgumentError shapes) + HappyMailer/StubMailer/BrokenMailer fixtures; Plan 02 mailglass_admin package skeleton with Boundary exports; Plan 03 Router macro's on_mount_hooks = opts[:on_mount] ++ [MailglassAdmin.Preview.Mount] expansion + __session__/2 whitelist populating session["mailables"]
provides:
  - mailglass_admin/lib/mailglass_admin/preview/discovery.ex — `MailglassAdmin.Preview.Discovery.discover/1` with the CONTEXT D-13 three-arm return shape (`[{atom, map}]` / `:no_previews` / `{:error, String.t()}`), graceful try/rescue around `preview_props/0`, and 05-RESEARCH.md Pitfall 7 shape validation rejecting non-list returns + non-map scenario values
  - mailglass_admin/lib/mailglass_admin/preview/mount.ex — `MailglassAdmin.Preview.Mount.on_mount/4` reading session `"mailables"` (default `:auto_scan`) → `Discovery.discover/1` → `assign(:mailables)` → `{:cont, socket}`; v0.1 always-cont contract
  - discovery_test.exs flipped from 6 RED to 6 GREEN — PREV-03 reflection contract locked against three fixture mailables + non-mailable ArgumentError path + :auto_scan OTP walk
affects: [05-05, 05-06, 07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CONTEXT D-13 graceful-failure reflection: try/rescue wraps mod.preview_props() and returns `{module, {:error, Exception.format(...)}}` as presentation data — discovery NEVER raises, the LiveView sidebar branches on the tuple shape to render a warning badge + error card. An adopter mailable that raises at preview time cannot take down the dashboard."
    - "05-RESEARCH.md Pitfall 7 shape validation addition: Pattern 3's bare pass-through `{mod, mod.preview_props()}` was extended with a validate_scenarios/1 stage so [{atom, function}] or `:not_a_list` returns surface as `{:error, shape_violation_message}` — catching the mistake at discovery time instead of rendering time."
    - "Session-callback → on_mount chain: MailglassAdmin.Router.__session__/2 emits the whitelisted map; adopter `on_mount` hooks run first (so they can short-circuit); MailglassAdmin.Preview.Mount runs last and populates :mailables; PreviewLive.mount/3 inherits the assign. Plan 06 PreviewLive never calls Discovery directly."
    - "Defensive Map.get(session, \"mailables\", :auto_scan) in on_mount: even if an upstream hook mutates the session map or the test path skips the Router macro entirely, defaulting to :auto_scan keeps discovery running instead of raising."

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/preview/discovery.ex (140 lines)
    - mailglass_admin/lib/mailglass_admin/preview/mount.ex (52 lines)
  modified: []

key-decisions:
  - "Omitted `use Boundary, classify_to: MailglassAdmin` from both submodules. Plan <action> text directed adding it at the top of each file, but Plan 03 established (and documented in `MailglassAdmin.PubSub.Topics` + `MailglassAdmin.Layouts`) that submodules of `MailglassAdmin` auto-classify into the root boundary declared in `lib/mailglass_admin.ex`. Boundary's `classify_to:` directive is reserved for mix tasks and protocol implementations. Applying it here would either be a no-op (older Boundary) or emit an ambiguous-classification warning (current Boundary). Decision: follow the Plan 03 convention. Documented inline in each moduledoc under a 'Boundary classification' heading."
  - "Kept Plan 04's 05-RESEARCH.md Pitfall 7 shape validation addition over Pattern 3's bare `{mod, mod.preview_props()}`. The shape violation path ({:error, shape_violation_message}) is strictly more defensive than the research pattern: a mailable whose preview_props/0 returns `[{:scenario, fn a -> a end}]` would otherwise propagate the function through to the type-inferred form renderer where it'd fail with a cryptic FunctionClauseError during render. Catching it at discovery gives the adopter a clear error card matching the T-05-04b threat mitigation."
  - "on_mount hook returns `{:cont, socket}` unconditionally at v0.1. The dashboard has no auth at v0.1 (CONTEXT D-01 dev-only scope); v0.5's prod-admin mount will ship a separate on_mount (or replace this one) with auth gating. Keeping the v0.1 contract always-cont keeps the adopter-facing on_mount surface simple and obvious — no `{:halt, ...}` branches anywhere in the file means no security-critical conditional to review."
  - "No telemetry emitted in either module at v0.1. The cost of shipping the wrong metadata whitelist once is permanent (PII leak in adopter telemetry handlers). Discovery is a hot-path function — PII-relevant metadata is the scenario defaults map itself (`%{user_name: ..., email: ...}`). v0.5 adds a whitelisted `mailables_count` counter once the whitelist has been reviewed; v0.1 skips the entire surface."
  - "`import Phoenix.Component, only: [assign: 3]` (narrow import) instead of `alias Phoenix.Component` + `Component.assign/3`. The narrow import keeps the call site idiomatic (`assign(socket, :mailables, mailables)` matches Phoenix 1.8 LiveView conventions) without pulling the rest of Phoenix.Component into scope."

patterns-established:
  - "Three-arm reflection return shape (healthy-scenarios / `:no_previews` / `{:error, msg}`): the LiveView/UI branches on the second tuple element as presentation data. Graceful-failure code paths return `:error` tuples as normal flow, NOT via raising. Applicable anywhere library code reflects on adopter-defined optional callbacks."
  - "Shape-validation-at-discovery pattern: when an optional callback has a documented return-shape contract but nothing structurally enforces it, validate at the boundary (discovery call site) rather than deep in the rendering stack. The adopter sees `{:error, 'preview_props/0 must return ...'}` immediately instead of a FunctionClauseError five frames deep."
  - "Map.get(session, \"key\", default) defensive-default pattern for on_mount hooks: session maps are assumed whitelisted by the session callback, but defaulting to a safe value keeps test paths that bypass the Router macro functional."

requirements-completed: [PREV-03]

# Metrics
duration: 3min
completed: 2026-04-24
---

# Phase 05 Plan 04: Preview Discovery + on_mount Hook Summary

**MailglassAdmin.Preview.Discovery ships the CONTEXT D-13 three-arm graceful-failure reflector over `__mailglass_mailable__/0`-marked modules, and MailglassAdmin.Preview.Mount wires it into the Router macro's on_mount chain — flipping discovery_test.exs 6/6 GREEN so Plan 06 PreviewLive inherits `@mailables` pre-populated on mount.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-24T10:43:25Z
- **Task 1 committed:** 2026-04-24T10:44:27Z (`f232393`)
- **Task 2 committed:** 2026-04-24T10:45:54Z (`6a2c1ca`)
- **Completed:** 2026-04-24T10:46:34Z
- **Tasks:** 2 completed
- **Files created:** 2
- **Warm scan cost:** **2.87 ms** for the project's own loaded application list (3 fixture mailables: `MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}`). Well under the 50ms empirical target from 05-RESEARCH.md line 618 for a 10,000-module umbrella. Measurement method: `MIX_ENV=test mix run --no-start -e` with one warm-up call preceding the `:timer.tc` measurement.

## Accomplishments

- **`MailglassAdmin.Preview.Discovery.discover/1` ships the CONTEXT D-13 three-arm return shape.** Healthy mailables yield `[{scenario_atom, defaults_map}, ...]`; mailables with the marker but no `preview_props/0` yield the `:no_previews` sentinel; mailables whose `preview_props/0` raises OR returns an invalid shape yield `{:error, String.t()}`. Discovery NEVER raises — LiveView renders error cards as presentation data.
- **T-05-04 mitigated structurally.** `BrokenMailer.preview_props/0`'s `raise "boom"` propagates as `{MailglassAdmin.Fixtures.BrokenMailer, {:error, formatted_stacktrace}}` — the dashboard stays live. Test `raising preview_props/0 yields {:error, formatted_stacktrace}` asserts the contract.
- **T-05-04b mitigated via shape validation.** `preview_props/0` returning `:not_a_list` or `[{:scenario, fn assigns -> assigns end}]` (per 05-RESEARCH.md Pitfall 7) surfaces as `{:error, shape_violation_message}` rather than crashing the type-inferred form renderer five frames deep with a FunctionClauseError.
- **`MailglassAdmin.Preview.Mount.on_mount/4` wires Discovery into the Router's on_mount chain.** Reads `session["mailables"]` (default `:auto_scan`), calls `Discovery.discover/1`, assigns `:mailables` on socket, returns `{:cont, socket}`. Plan 06 PreviewLive.mount/3 inherits the assign — no direct Discovery coupling in the LiveView.
- **discovery_test.exs 6/6 GREEN.** Plan 01's RED-by-default assertions now pass:
  - `discover/1 with explicit list explicit list returns scenarios for healthy mailable` ✓
  - `discover/1 with explicit list stub mailable yields :no_previews sentinel` ✓
  - `discover/1 with explicit list raising preview_props/0 yields {:error, formatted_stacktrace}` ✓
  - `discover/1 with explicit list non-mailable module raises ArgumentError with actionable message` ✓
  - `discover/1 with :auto_scan auto_scan returns a list of {module, scenarios} tuples` ✓
  - `discover/1 with :auto_scan auto_scan includes fixture mailables when their OTP app is loaded` ✓
- **`mix compile --no-optional-deps --warnings-as-errors` stays GREEN.** The Router's `@compile {:no_warn_undefined, [MailglassAdmin.Preview.Mount, ...]}` forward reference declared in Plan 03 is now partially satisfied by the real Preview.Mount module; Discovery needs no forward-reference declaration (only mailglass_core types it references exist today).

## Task Commits

Each task was committed atomically:

1. **Task 1: MailglassAdmin.Preview.Discovery with graceful failure + shape validation** — `f232393` (feat)
2. **Task 2: MailglassAdmin.Preview.Mount on_mount hook** — `6a2c1ca` (feat)

**Plan metadata:** this SUMMARY.md commit (docs).

## Files Created/Modified

### Created

- `mailglass_admin/lib/mailglass_admin/preview/discovery.ex` — 140 lines. Module shell with `@type scenario/reflection/result`, `@spec discover(:auto_scan | [module()]) :: [result()]`, two `def discover/1` clauses (`:auto_scan` + `is_list(mods)`), private helpers `loaded_apps/0`, `modules_for_app/1`, `mailable?/1` (three-condition `and` with rescue tail), `reflect/1` (try/rescue around `mod.preview_props()` + shape-validation branch), `validate_scenarios/1` (list-shape + non-list clause), and `valid_scenario?/1` (`{atom, map}` predicate). No telemetry.
- `mailglass_admin/lib/mailglass_admin/preview/mount.ex` — 52 lines. `import Phoenix.Component, only: [assign: 3]`, `alias MailglassAdmin.Preview.Discovery`, single `def on_mount(:default, _params, session, socket)` clause returning `{:cont, assign(socket, :mailables, Discovery.discover(session["mailables"] || :auto_scan))}`. No Logger / telemetry / PubSub calls; no `:halt` tuple.

### Modified

None — both files are net-new under `mailglass_admin/lib/mailglass_admin/preview/` (directory created by this plan).

## Decisions Made

1. **Omitted `use Boundary, classify_to: MailglassAdmin` from both submodules per Plan 03 convention.** The plan's `<action>` text directed adding it; Plan 03 documented (in `MailglassAdmin.PubSub.Topics` + `MailglassAdmin.Layouts` moduledocs) that submodules auto-classify into the root boundary declared in `lib/mailglass_admin.ex`. `classify_to:` is reserved for mix tasks and protocol implementations per Boundary docs. Applied inline documentation in each moduledoc under a 'Boundary classification' heading.

2. **Kept the 05-RESEARCH.md Pitfall 7 shape validation extension.** Pattern 3 in 05-RESEARCH.md lines 601-614 shows a bare `{mod, mod.preview_props()}` pass-through. The plan <action> explicitly added `validate_scenarios/1` as the correction. Confirmed it's load-bearing: `[{:scenario, fn a -> a end}]` passes validation without it (tuple shape is `{atom, _}`) and propagates a function where a map is expected, causing a FunctionClauseError at render time. The addition catches the mistake at discovery.

3. **v0.1 always-cont on_mount contract.** No `{:halt, ...}` branch anywhere. v0.5 prod-admin ships its own auth-gating on_mount or replaces this one; keeping v0.1 simple means the adopter surface is "this module unconditionally adds `:mailables`."

4. **No telemetry in either module.** Discovery is a hot-path function called on every mount + every LiveReload broadcast. PII risk surfaces in scenario defaults maps (which may contain user emails or other PII-bearing struct snapshots). v0.5 adds a whitelisted `mailables_count` counter; v0.1 skips the surface entirely per CLAUDE.md "No PII in telemetry" rule.

5. **Defensive `Map.get(session, "mailables", :auto_scan)` in on_mount.** The Router's `__session__/2` returns exactly `%{"mailables" => ..., "live_session_name" => ...}` so the key is always present under normal operation. The default is load-bearing for test paths that construct a LiveView socket directly (bypassing `live_session`) — such tests can omit the key and get sane discovery behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan `<action>` text for both files specified `use Boundary, classify_to: MailglassAdmin`**

- **Found during:** Task 1 (writing discovery.ex) and Task 2 (writing mount.ex) — identical issue
- **Issue:** Plan `<action>` for both files directed adding `use Boundary, classify_to: MailglassAdmin` at the top of each submodule. Plan 03's SUMMARY.md documents the same drift and its correction: submodules of `MailglassAdmin` auto-classify into the root boundary declared in `lib/mailglass_admin.ex`. Applying `classify_to:` is either redundant (Boundary's auto-classification already runs) or emits an ambiguous-classification warning depending on Boundary version. Under `--warnings-as-errors` a warning would fail Plan 04's verification step 2.
- **Fix:** Omitted `use Boundary, classify_to: MailglassAdmin` from both files. Added a 'Boundary classification' paragraph to each moduledoc explicitly documenting the auto-classification behavior so future readers don't try to re-add the directive.
- **Files modified:** mailglass_admin/lib/mailglass_admin/preview/discovery.ex, mailglass_admin/lib/mailglass_admin/preview/mount.ex
- **Verification:** `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` exits 0; no Boundary warnings.
- **Committed in:** f232393 (Task 1 discovery.ex) + 6a2c1ca (Task 2 mount.ex)

---

**Total deviations:** 1 auto-fixed (1 Rule 3 blocking — same planning discrepancy with Boundary semantics documented in Plan 03 SUMMARY.md Deviation #1).
**Impact on plan:** The deviation corrects a carryover from CONTEXT/PATTERNS text that predates Plan 03's Boundary-semantics clarification. No scope creep — both affected files are in the plan's files_modified list. The acceptance criterion "`use Boundary, classify_to: MailglassAdmin` at top" is superseded by the more-correct auto-classification discipline.

## Issues Encountered

**1. Plan `<verification>` bullet 3 contradicts its own `<acceptance_criteria>`.** The final bullet says `grep -R '__mailglass_mailable__' mailglass_admin/lib/mailglass_admin/preview/discovery.ex` "returns exactly one match (the function_exported? call)". Actual count after satisfying `<acceptance_criteria>` bullet "Contains a `mailable?/1` helper that checks three conditions via `and` (Code.ensure_loaded?, function_exported?, marker returns true)": 3 matches (1 moduledoc + 2 code: `function_exported?` call + `mod.__mailglass_mailable__()` invocation). The acceptance criteria are authoritative; the grep bullet is off by two. Noted here for traceability — no action taken, the module is structured per its own spec.

## User Setup Required

None — this plan creates library code only. No external services, no env vars, no dashboard configuration.

## Notes for Plan 06 Executor

**1. `@mailables` assign is already populated by on_mount.** Plan 06's `MailglassAdmin.PreviewLive.mount/3` does NOT need to call `Discovery.discover/1` directly. The socket inherits `:mailables` from the on_mount hook; `mount/3` focuses on:
- Subscribing to `MailglassAdmin.PubSub.Topics.admin_reload/0` via `Phoenix.PubSub.subscribe`
- Setting UI defaults (`:device`, `:dark_chrome`, `:tab`, `:page_title`, etc. per 05-UI-SPEC)
- Resolving the initial `:mailable` and `:scenario` selection from params

**2. Error-card copy must be loaded from the `:error` tuple verbatim.** The `{:error, msg}` string shape is the contract between Discovery and the LiveView's error card (05-UI-SPEC lines 386-404). The three failure modes produce these message shapes — Plan 06's error card renders them as `<pre>` text:

- **Raising `preview_props/0`** (tested by BrokenMailer fixture):
  ```
  ** (RuntimeError) boom — deliberate fixture raise for Discovery test coverage
      (mailglass_admin 0.1.0) test/support/fixtures/mailables.ex:61: MailglassAdmin.Fixtures.BrokenMailer.preview_props/0
      ...
  ```
  First line is `** (ErrorModule) message` via `Exception.format(:error, e, __STACKTRACE__)`. Plan 06's error card should preserve the monospace formatting (`<pre>`).

- **`preview_props/0` returns non-list:** `"preview_props/0 must return a list of {atom, map} tuples, got: :not_a_list"` (literal from validate_scenarios/1 non-list clause; the `:not_a_list` is `inspect(raw)`).

- **`preview_props/0` returns a list with a non-map second element:** `"preview_props/0 must return [{atom(), map()}] but got an entry whose second element is not a map: {:scenario, #Function<0.121690855/1 in BadShape.NonMapValue.preview_props/0>}"` (literal from validate_scenarios/1 list clause; the tuple after `:` is `inspect(bad)` where `bad` is the first failing entry).

**3. `MailglassAdmin.Preview.Mount` is structurally simple and tested indirectly.** Plan 01's preview_live_test.exs mounts the full LiveView (via `MailglassAdmin.LiveViewCase`) which exercises the on_mount chain end-to-end. No separate preview_mount_test.exs exists — the Mount hook's correctness is asserted by PreviewLive tests reading `@mailables` after mount. If Plan 06 adds a direct assertion, the shape is:

```elixir
{:cont, socket} = MailglassAdmin.Preview.Mount.on_mount(:default, %{}, %{"mailables" => :auto_scan}, socket_fixture)
assert is_list(socket.assigns.mailables)
```

**4. Forward-reference `@compile {:no_warn_undefined, [MailglassAdmin.Preview.Mount, ...]}` in Router remains.** Plan 03's declaration lists `MailglassAdmin.Preview.Mount` as a forward reference; now that this plan ships the module, that entry is redundant but harmless. Safe to leave until Plans 05/06 land their modules and a Phase-5-completion-gate sweep removes all three at once.

## TDD Gate Compliance

This plan has `type: execute` (not `type: tdd`), but the RED-to-GREEN transition for discovery_test.exs (Plan 01 RED 6 → Plan 04 GREEN 6) is the structural equivalent of a plan-level GREEN gate for PREV-03's reflection portion. `git log` shows `test(05-01): add nine RED-by-default test files per 05-VALIDATION map` (`1a58dcc`) as the RED commit and `feat(05-04): add MailglassAdmin.Preview.Discovery with graceful failure` (`f232393`) as the GREEN commit that flips discovery_test.exs.

## Threat Flags

No new threat surface beyond the plan's `<threat_model>` register.

- **T-05-04 (Denial of Service via mailable `preview_props/0` raising at runtime)** mitigated structurally. `Discovery.reflect/1` wraps `mod.preview_props()` in try/rescue and returns `{:error, Exception.format(...)}`. BrokenMailer fixture test `raising preview_props/0 yields {:error, formatted_stacktrace}` asserts the contract.
- **T-05-04b (Tampering via `preview_props/0` returning unexpected shape)** mitigated via `validate_scenarios/1` + `valid_scenario?/1`. Non-list returns and list items with non-map second elements yield `{:error, shape_violation_message}` instead of propagating to the renderer. Note: discovery_test.exs does not currently cover this path (the BrokenMailer test covers the raise path only). Plan 06 or a future test hardening pass should add a fixture with `def preview_props, do: [{:s, fn a -> a end}]` to assert the shape-violation message format against its `<pre>` error card.

## Known Stubs

None introduced by this plan.

## Self-Check

Verified before declaring plan complete:

- [x] Both new files exist on disk:
  - `mailglass_admin/lib/mailglass_admin/preview/discovery.ex` (140 lines)
  - `mailglass_admin/lib/mailglass_admin/preview/mount.ex` (52 lines)
- [x] Two task commits in `git log`:
  - `f232393` — `feat(05-04): add MailglassAdmin.Preview.Discovery with graceful failure`
  - `6a2c1ca` — `feat(05-04): add MailglassAdmin.Preview.Mount on_mount hook`
- [x] `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` exits 0
- [x] `cd mailglass_admin && mix test test/mailglass_admin/discovery_test.exs` exits 0 (6 tests, 0 failures)
- [x] `cd mailglass_admin && mix test test/mailglass_admin/{discovery,router,mix_config}_test.exs` exits 0 (13 tests total across Plans 02/03/04, 0 failures)
- [x] discovery.ex contains `defmodule MailglassAdmin.Preview.Discovery`, `@spec discover(:auto_scan | [module()])`, two `def discover/1` clauses, `mailable?/1` with three-condition `and` + rescue tail, `reflect/1` with try/rescue + validate_scenarios branch, `validate_scenarios/1` (list + non-list clauses), `valid_scenario?/1` (`{atom, map}` predicate)
- [x] mount.ex contains `defmodule MailglassAdmin.Preview.Mount`, `def on_mount(:default, _params, session, socket)` (4-arity with `:default` first arg), returns `{:cont, socket}` tuple, calls `Discovery.discover/1` with session `"mailables"` (default `:auto_scan` via `Map.get`), uses `Phoenix.Component.assign/3` to set `:mailables`
- [x] Neither file contains `Logger.*`, `:telemetry.*`, or `Phoenix.PubSub.*` calls (grep confirms); mount.ex contains no `{:halt, ...}` tuple (grep of `:halt` shows only the moduledoc reference to adopter hooks short-circuiting)
- [x] discovery.ex `grep -R '__mailglass_mailable__'` returns 3 matches (1 moduledoc + 2 code — plan's `<verification>` bullet says "exactly one" but `<acceptance_criteria>` requires two code references; the criteria are authoritative, see Issues Encountered #1)
- [x] Warm scan cost measured at 2.87 ms against 3 fixture mailables — well under 50ms target

## Self-Check: PASSED

All created files exist; both task commits are in `git log`; all `<verification>` criteria exit 0 (modulo the grep count contradiction in the plan's own spec, noted transparently); discovery_test.exs 6/6 GREEN; acceptance criteria met (with one documented Boundary-semantics deviation consistent with Plan 03's precedent).

---
*Phase: 05-dev-preview-liveview*
*Completed: 2026-04-24*
