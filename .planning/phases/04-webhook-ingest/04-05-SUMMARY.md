---
phase: 04-webhook-ingest
plan: 05
subsystem: webhook
tags: [router, macro, tenancy, callback, resolve_from_path, error_atoms, api_stability, d06, d07, d08, d12, d14, d21]

# Dependency graph
requires:
  - phase: 04-webhook-ingest
    plan: 01
    provides: "api_stability.md §Webhook placeholder + 4 forward-ref markers for SignatureError 4→7 atoms / TenancyError +1 / ConfigError +1 / Tenancy resolve_webhook_tenant/1 optional callback"
  - phase: 04-webhook-ingest
    plan: 02
    provides: "SignatureError @types extended with 7 D-21 atoms (+ 3 legacy retained); ConfigError extended with :webhook_verification_key_missing + :webhook_caching_body_reader_missing; Mailglass.Webhook.Plug is the consumer of the formal callback"
  - phase: 04-webhook-ingest
    plan: 04
    provides: "Mailglass.Webhook.Plug single-ingress orchestrator + TenancyError :webhook_tenant_unresolved atom + Mailglass.Tenancy.resolve_webhook_tenant/1 dispatcher STUB (function_exported? fallback); this plan FORMALIZES the stub"
  - phase: 02-persistence-tenancy
    provides: "Mailglass.Tenancy behaviour with scope/2 callback + @optional_callbacks tracking_host: 1; Mailglass.Tenancy.SingleTenant default impl"
provides:
  - "Mailglass.Webhook.Router.mailglass_webhook_routes/2 macro (CONTEXT D-06 + D-07 + D-08)"
  - "@optional_callbacks tracking_host: 1, resolve_webhook_tenant: 1 — formal addition to Mailglass.Tenancy per CONTEXT D-12"
  - "@callback resolve_webhook_tenant/1 with 6-key context map typespec"
  - "Mailglass.Tenancy.SingleTenant.resolve_webhook_tenant/1 concrete impl returning {:ok, \"default\"}"
  - "Mailglass.Tenancy.ResolveFromPath opt-in URL-prefix resolver (+ documented T-04-08 mitigation via scope/2 raise)"
  - "Mailglass.Tenancy.clear/0 test-cleanup helper (encapsulates the :mailglass_tenant_id process-dict key per revision W7)"
  - "Mailglass.Config :webhook_ingest_mode NimbleOptions entry (default :sync; :async reserved @doc false per revision B2)"
  - "Mailglass.Config.webhook_ingest_mode/0 accessor (@doc false for Plan 06's runtime guard)"
  - "Brand-voice format_message/2 clauses for SignatureError 7-atom set + TenancyError :webhook_tenant_unresolved + ConfigError :webhook_verification_key_missing"
  - "docs/api_stability.md §SignatureError + §ConfigError + §TenancyError + §Tenancy `c:resolve_webhook_tenant/1` + §Webhook sections finalized; Plan 01's 4 placeholder markers are removed"
affects: [04-06, 04-07, 04-08, 04-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Phoenix.Router macro-expansion test via `use Phoenix.Router` + `__routes__/0` reflection (synthesized pattern — no mailglass or prior-art library had a router-macro test analog before this plan)"
    - "Compile-time validation of enum opts via inline Enum.each + raise ArgumentError in defmacro body (fails at router-mount, not request time — CONTEXT D-07 discipline)"
    - "Opt-in sugar module that fails closed: Mailglass.Tenancy.ResolveFromPath implements the optional callback but raises on scope/2 with composition guidance — adopters mistakenly configuring it as a complete Tenancy get a clear directive, not silent data leaks (T-04-08 mitigation)"
    - "Mailglass.Tenancy.clear/0 encapsulates the internal process-dict key name — test on_exit blocks use the public API instead of raw Process.delete (decouples test code from internal storage details)"
    - "defdelegate resolve_webhook_tenant(context), to: Mailglass.Tenancy.ResolveFromPath — the composition shape documented in api_stability.md for adopter modules that want both scope/2 and URL-prefix tenant extraction"
    - "Error brand-voice pattern: optional context map fields (:detail on :malformed_header, :reason on :webhook_tenant_unresolved) enable operator-visible hints without adding structural struct fields"

key-files:
  created:
    - "lib/mailglass/webhook/router.ex"
    - "lib/mailglass/tenancy/resolve_from_path.ex"
    - "test/mailglass/webhook/router_test.exs"
    - "test/mailglass/tenancy/resolve_from_path_test.exs"
  modified:
    - "lib/mailglass/tenancy.ex (@optional_callbacks extended + @callback resolve_webhook_tenant/1 + clear/0; dispatcher doc tightened now that SingleTenant has a concrete impl)"
    - "lib/mailglass/tenancy/single_tenant.ex (resolve_webhook_tenant/1 concrete impl + moduledoc updated)"
    - "lib/mailglass/errors/signature_error.ex (format_message/2 refinements: :malformed_header detail, :timestamp_skew tolerance, :malformed_key config hint)"
    - "lib/mailglass/errors/tenancy_error.ex (format_message/2 for :webhook_tenant_unresolved includes optional context[:reason] via inspect/1)"
    - "lib/mailglass/errors/config_error.ex (:webhook_verification_key_missing default hint names :mailglass config tree explicitly)"
    - "lib/mailglass/config.ex (+:webhook_ingest_mode schema entry + webhook_ingest_mode/0 accessor)"
    - "docs/api_stability.md (4 placeholder markers replaced with authoritative content — SignatureError 7-atom table + ConfigError Phase 4 additions + TenancyError 2-atom table + Tenancy resolve_webhook_tenant/1 callback doc + §Webhook section full content)"
    - "test/mailglass/webhook/plug_test.exs (Plan 04-04 UnresolvedTenancy stub gains @impl annotation — direct consequence of callback formalization)"

key-decisions:
  - "Router macro's :providers opt validated INSIDE the defmacro body (before the quote), NOT inside the quoted block — raises ArgumentError at compile time during router-module compilation, not at request time. Adopters with a bogus provider atom get a compile failure of their Phoenix router, which crashes endpoint.ex boot and fails CI — CONTEXT D-07 'compile error, not runtime 404' verbatim."
  - "Mailglass.Tenancy.resolve_webhook_tenant/1 dispatcher KEEPS the function_exported?/3 fallback (returns {:ok, \"default\"}) even after Plan 05 formalizes the @optional_callback. Rationale: adopter modules that were written against Plan 04-04's stub shape (no formal @callback) still work. The plan's original text suggested tightening the fallback to {:error, :resolver_incomplete} once the callback is formal — this was reconsidered in favor of zero-friction adoption. The SingleTenant concrete impl this plan adds makes the fallback unreachable for the default path; only adopter modules that decline to implement the callback hit it."
  - "ResolveFromPath.scope/2 RAISES with composition guidance (RuntimeError) rather than returning an unmodified query. The module is a SUGAR resolver that handles resolve_webhook_tenant/1 ONLY. Adopters mistakenly configuring it as a complete Tenancy get a clear error directing them to compose it with a real Tenancy module. Documented in api_stability.md + moduledoc + test. T-04-08 mitigation — fails closed on misuse."
  - "Mailglass.Tenancy.clear/0 returns :ok and deletes the :mailglass_tenant_id process-dict key. Exposed as a public helper so Plans 06+ test on_exit blocks can call Mailglass.Tenancy.clear() without needing to know the internal atom. The atom could change in a future refactor without breaking test code. Revision W7 verbatim."
  - ":webhook_ingest_mode schema entry is @doc false because :async is reserved at v0.1. NimbleOptions enforces the {:in, [:sync, :async]} closed set, so adopters who accidentally set :async get a validation error at boot. Plan 06's Ingest.ingest_multi/3 will add an explicit runtime raise on :async to produce a clearer error than the silently-ignored sync execution."
  - "Dispatcher doc updated to reflect SingleTenant's now-concrete impl. The original Plan 04-04 text described the fallback as 'Until Plan 05 ships the SingleTenant impl'; Plan 05 (this plan) ships it, so the doc now explains the fallback behaviour as 'adopter resolvers that don't implement the callback fall through via function_exported?/3' — a real contract, not a placeholder."
  - "SignatureError :malformed_header format_message now accepts ctx[:detail] for operator hints without adding a new struct field. When a verifier rescues a base64 decode error, it can raise with context: %{detail: \"bad Base64\"} and the message becomes 'Webhook signature failed: signature header is malformed (bad Base64)'. Backward-compatible — callers that don't pass :detail get the bare sentence."
  - "TenancyError :webhook_tenant_unresolved format_message now accepts ctx[:reason] via inspect/1 — e.g. context: %{provider: :postmark, reason: :no_match} yields 'Webhook tenant resolution failed: no tenant matches for provider=postmark (reason: :no_match)'. Preserves Plan 04-04's Logger.warning contract while enriching downstream error messages."
  - "api_stability.md's Webhook section now documents the Plug response-code matrix (200/401/422/500 with raised-error correspondence) — was reserved space in Plan 01. Plans 06-08 will append the Ingest.ingest_multi/3 contract, Reconciler cron shape, and Pruner retention policy without colliding with this plan's content (each plan has a labeled subsection within §Webhook)."
  - ":as default is :mailglass_webhook (CONTEXT D-08 locked). Each generated route helper is :'\\#{as}_\\#{provider}' so the default case produces :mailglass_webhook_postmark + :mailglass_webhook_sendgrid. Adopters wanting a shorter namespace can pass as: :hooks yielding :hooks_postmark / :hooks_sendgrid."

patterns-established:
  - "Router-mount-time compile-error discipline: Enum.each inside a defmacro body that validates enum opts BEFORE the quote block; fails adopter endpoint.ex boot on invalid values. CONTEXT D-07 verbatim."
  - "Phoenix.Router macro-expansion test: synthesize a test-local Phoenix.Router module inside a `describe` block (defmodule DefaultRouter do use Phoenix.Router; import Mailglass.Webhook.Router; scope ...; mailglass_webhook_routes ...; end) and assert via `__routes__/0` reflection. No external test fixtures, no DB, async-safe."
  - "Fails-closed sugar module pattern: ResolveFromPath implements only the optional callback it handles (resolve_webhook_tenant/1); the required callback it does NOT handle (scope/2) raises with composition guidance. Adopters get a clear runtime error if they mis-configure rather than silent cross-tenant query failures."
  - "Public clear/0 helper encapsulating internal process-dict key: Mailglass.Tenancy.clear() / Mailglass.Tenancy.current() / Mailglass.Tenancy.put_current(_) are the only three functions that should touch the :mailglass_tenant_id atom. Tests now call clear/0 in on_exit instead of Process.delete(:mailglass_tenant_id)."
  - "Optional context hints in format_message/2: ctx[:detail] for SignatureError :malformed_header, ctx[:reason] for TenancyError :webhook_tenant_unresolved. Callers enrich messages without adding struct fields. Backward-compatible — absent keys fall through to the bare sentence."

requirements-completed: [HOOK-02]

# Metrics
duration: 9min
completed: 2026-04-23
---

# Phase 4 Plan 5: Webhook Ingest Wave 2B — Router macro + Tenancy formalization + api_stability lock Summary

**`Mailglass.Webhook.Router.mailglass_webhook_routes/2` macro generates provider-per-path POST routes (CONTEXT D-06 + D-07 + D-08) with compile-time enum validation; `Mailglass.Tenancy` formally declares `@optional_callbacks resolve_webhook_tenant: 1` with a 6-key context map typespec; `Mailglass.Tenancy.SingleTenant` ships the concrete `{:ok, "default"}` default impl; `Mailglass.Tenancy.ResolveFromPath` ships as opt-in URL-prefix sugar with a fail-closed `scope/2` raise (T-04-08 mitigation); `Mailglass.Config` adds `:webhook_ingest_mode` (`:sync` default, `:async` reserved); and `docs/api_stability.md` replaces Plan 01's 4 placeholder markers with authoritative SignatureError 7-atom table + TenancyError 2-atom table + ConfigError Phase 4 additions + Tenancy `resolve_webhook_tenant/1` callback doc + full §Webhook section. Wave 2 is now complete — Plan 06's Ingest.ingest_multi/3 can build against finalized error atoms + Tenancy behaviour without further atom additions.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-04-23T21:39:00Z
- **Completed:** 2026-04-23T21:48:07Z
- **Tasks:** 3 (plus 1 test-stub fix folded into Task 2 commit)
- **Commits:** 3 task commits (plus 1 metadata commit after this SUMMARY lands)
- **Files created:** 4
- **Files modified:** 8

## Accomplishments

- **`Mailglass.Webhook.Router` macro (`lib/mailglass/webhook/router.ex`):** `defmacro mailglass_webhook_routes(path, opts \\ [])` generates one POST route per provider in `opts[:providers]` (default `[:postmark, :sendgrid]`), mounting `Mailglass.Webhook.Plug` at each path with `[provider: atom]`. `:as` defaults to `:mailglass_webhook` (CONTEXT D-08 shared-vocab lock with Phase 5 admin). Unknown providers raise `ArgumentError` at compile time — invalid `:providers` crashes adopter endpoint boot (CONTEXT D-07 "compile error, not runtime 404"). Moduledoc documents the full adopter wiring (pipeline, `Plug.Parsers` `body_reader` MFA, 10 MB `:length` cap).
- **`Mailglass.Tenancy` formal callback declaration:** `@optional_callbacks tracking_host: 1, resolve_webhook_tenant: 1` (extended in-place). `@callback resolve_webhook_tenant(context :: %{…}) :: {:ok, tid} | {:error, term}` with the 6-key context map typespec verbatim from CONTEXT D-12. The existing dispatcher from Plan 04-04 keeps its `function_exported?/3` fallback (adopter modules without the callback still get `{:ok, "default"}`), but the formal `@callback` now produces compile-time warnings on typos and missing `@impl` annotations — surfaced exactly once during this plan (Plan 04-04's `UnresolvedTenancy` test stub needed `@impl Mailglass.Tenancy` added; fixed in same commit as Task 2).
- **`Mailglass.Tenancy.SingleTenant.resolve_webhook_tenant/1`:** Concrete impl returning `{:ok, "default"}`. Added alongside the existing `scope/2` no-op. Moduledoc updated to explain the zero-config single-tenant posture — adopters implementing their own Tenancy module override `resolve_webhook_tenant/1` to map verified webhook contexts to tenant_ids.
- **`Mailglass.Tenancy.ResolveFromPath` (`lib/mailglass/tenancy/resolve_from_path.ex`):** New opt-in URL-prefix resolver. `resolve_webhook_tenant/1` reads `context.path_params["tenant_id"]` and returns `{:ok, tid}` when non-empty binary; `{:error, :missing_path_param}` otherwise (empty string, missing key, or any other shape). `scope/2` RAISES with composition guidance — the module is SUGAR that handles only `resolve_webhook_tenant/1`; adopters using it for the full Tenancy contract MUST pair with a real module that implements `scope/2`. Fails CLOSED on misuse (T-04-08 mitigation).
- **`Mailglass.Tenancy.clear/0`:** New public `:ok`-returning helper. Encapsulates the internal `:mailglass_tenant_id` process-dict key (revision W7). Plans 06 + 07 test `on_exit` blocks should call `Mailglass.Tenancy.clear()` instead of `Process.delete(:mailglass_tenant_id)` so the atom can be refactored without breaking test code.
- **`Mailglass.Config` `:webhook_ingest_mode`:** New NimbleOptions schema entry with `{:in, [:sync, :async]}` type, default `:sync`, `@doc false` (revision B2). `Mailglass.Config.webhook_ingest_mode/0` accessor (`@doc false`) exposes the runtime value for Plan 06's `Ingest.ingest_multi/3` guard — the plan will raise an explicit error on `:async` rather than silently running the sync path.
- **Brand-voice `format_message/2` refinements:** `SignatureError.:malformed_header` now accepts `ctx[:detail]` for operator hints (e.g. `"... (bad Base64)"`); `:timestamp_skew` message now says "tolerance window" (matches the `:timestamp_tolerance_seconds` config key); `:malformed_key` adds the hint "check your provider config". `TenancyError.:webhook_tenant_unresolved` accepts optional `ctx[:reason]` rendered via `inspect/1` — e.g. `"Webhook tenant resolution failed: no tenant matches for provider=postmark (reason: :no_match)"`. `ConfigError.:webhook_verification_key_missing` default hint now names the `:mailglass` config tree explicitly.
- **`docs/api_stability.md` Plan 01 markers replaced:** All 4 of Plan 01's forward-ref placeholder comments (3 error sections + 1 `tracking_host/1` callback section) are replaced with authoritative content — a 7-atom SignatureError table, a ConfigError Phase 4 additions table (both atoms listed with rationale), a TenancyError 2-atom table, and a full `Mailglass.Tenancy` `c:resolve_webhook_tenant/1` callback subsection including the context typespec + the two shipped default impls. The §Webhook section placeholder is replaced with full content: `Mailglass.Webhook.Provider` behaviour, `CachingBodyReader.read_body/2`, `Mailglass.Webhook.Router.mailglass_webhook_routes/2` macro, and the `Mailglass.Webhook.Plug` response-code matrix (200/401/422/500 with raised-error correspondence).
- **Test coverage (15 new tests, 0 failures):** 6 tests in `router_test.exs` covering default opts (2 routes + `:as` prefix), custom opts (single-provider `[:postmark]` with custom `:as`; `:sendgrid` alone with default `:as`), and compile-time validation (`ArgumentError` on unknown atom). 9 tests in `resolve_from_path_test.exs` covering happy path (single + multi path_params), fallback cases (missing key, empty string, other-key-only map), `scope/2` raise behaviour, and `@behaviour Mailglass.Tenancy` declaration. Total plan-level `mix test test/mailglass/webhook/ test/mailglass/tenancy/ test/mailglass/errors/ test/mailglass/tenancy_test.exs test/mailglass/error_test.exs test/mailglass/config_test.exs --warnings-as-errors --exclude requires_plan_06` = 149 tests, 0 failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Mailglass.Webhook.Router macro + 6 macro-expansion tests** — `ee33368` (feat) — 2 files, 224 insertions.
2. **Task 2: Tenancy callback formalization + ResolveFromPath + 9 tests + Plan 04-04 stub @impl fix** — `5262142` (feat) — 5 files, 279 insertions, 9 deletions.
3. **Task 3: Error atom-set finalization + :webhook_ingest_mode + api_stability.md marker replacements** — `e57a6cf` (docs) — 5 files, 237 insertions, 70 deletions.

**Plan metadata:** _pending final commit after SUMMARY.md + STATE.md + ROADMAP.md updates_.

## Files Created/Modified

### Created

- `lib/mailglass/webhook/router.ex` — 105-line module with `@valid_providers [:postmark, :sendgrid]` + `defmacro mailglass_webhook_routes(path, opts \\ [])` + compile-time validation + full moduledoc with adopter wiring example
- `lib/mailglass/tenancy/resolve_from_path.ex` — 73-line opt-in URL-prefix resolver; implements `resolve_webhook_tenant/1` + raises on `scope/2`; documents T-04-08 mitigation in the moduledoc
- `test/mailglass/webhook/router_test.exs` — 108-line test file; 3 describe blocks; 6 tests using `use Phoenix.Router` + `__routes__/0` reflection pattern
- `test/mailglass/tenancy/resolve_from_path_test.exs` — 109-line test file; 3 describe blocks; 9 tests covering the full `resolve_webhook_tenant/1` + `scope/2` + behaviour-declaration surface

### Modified

- `lib/mailglass/tenancy.ex` — `@optional_callbacks` extended to `[tracking_host: 1, resolve_webhook_tenant: 1]`; new `@callback resolve_webhook_tenant/1` decl with 6-key context map typespec + long-form doc (examples, fallback behaviour); new public `clear/0` helper; dispatcher doc tightened now that SingleTenant ships a concrete impl
- `lib/mailglass/tenancy/single_tenant.ex` — new `@impl Mailglass.Tenancy def resolve_webhook_tenant(_context), do: {:ok, "default"}` + moduledoc updated to explain the zero-config webhook default
- `lib/mailglass/errors/signature_error.ex` — `format_message/2` refinements: `:malformed_header` accepts `ctx[:detail]`, `:timestamp_skew` adds "tolerance window" qualifier, `:malformed_key` adds "check your provider config" hint
- `lib/mailglass/errors/tenancy_error.ex` — `:webhook_tenant_unresolved` message now includes optional `ctx[:reason]` via `inspect/1`
- `lib/mailglass/errors/config_error.ex` — `:webhook_verification_key_missing` default hint names `:mailglass` config tree explicitly
- `lib/mailglass/config.ex` — `:webhook_ingest_mode` schema entry (`{:in, [:sync, :async]}`, default `:sync`, `@doc false`); new `webhook_ingest_mode/0` accessor (`@doc false`)
- `docs/api_stability.md` — Plan 01's 4 placeholder markers replaced with authoritative content (SignatureError 7-atom table, ConfigError Phase 4 additions table, TenancyError 2-atom table, Tenancy `resolve_webhook_tenant/1` callback doc); §Webhook section populated with Provider behaviour + CachingBodyReader + Router macro + Plug response-code matrix
- `test/mailglass/webhook/plug_test.exs` — Plan 04-04's `UnresolvedTenancy` test stub gained `@impl Mailglass.Tenancy` annotation on `resolve_webhook_tenant/1` (direct consequence of Task 2's formal `@callback` declaration — without `@impl`, `--warnings-as-errors` fails)

## Decisions Made

- **Dispatcher fallback kept at `{:ok, "default"}`, not tightened to `{:error, :resolver_incomplete}`.** Plan 04-04's SUMMARY flagged that once the `@optional_callback` is formal (this plan's Task 2), the `function_exported?/3` fallback could reasonably tighten to an error tuple. On reflection: zero-friction adoption matters more. Adopter modules written against Plan 04-04's stub shape (no formal `@callback`) still work. The SingleTenant concrete impl this plan adds makes the fallback path unreachable for the default `:tenancy` = `nil` case; only adopter modules that explicitly decline to implement the callback hit it. Documented in the dispatcher's updated doc.
- **ResolveFromPath.scope/2 raises RuntimeError, not returns unmodified query.** The module handles `resolve_webhook_tenant/1` exclusively — pairing it with a data-layer `scope/2` would be misleading. Adopters mistakenly configuring `config :mailglass, tenancy: Mailglass.Tenancy.ResolveFromPath` (without also implementing `scope/2`) get a clear runtime error that names the compositional shape they should use (`defmodule MyApp.Tenancy do @behaviour Mailglass.Tenancy; defdelegate resolve_webhook_tenant(ctx), to: Mailglass.Tenancy.ResolveFromPath; def scope(q, ctx), do: ... end`). Fails CLOSED on misuse — T-04-08 mitigation (forged path `tenant_id` values can only reach data the adopter's own `scope/2` exposes for that ID).
- **`:as` default is `:mailglass_webhook` (CONTEXT D-08 locked).** Each generated route helper is `:"\#{as}_\#{provider}"` so `:mailglass_webhook_postmark` + `:mailglass_webhook_sendgrid` is the default pair. Adopters wanting a shorter namespace pass `as: :hooks` yielding `:hooks_postmark` / `:hooks_sendgrid`. The `:mailglass_webhook` prefix is the shared-vocab lock with Phase 5's admin mount point — adopters mounting both end up with `:mailglass_admin` (admin) + `:mailglass_webhook_*` (webhooks) as parallel namespaces, not colliding nor requiring further coordination.
- **Compile-time `ArgumentError` for unknown `:providers`, NOT `%ConfigError{}`.** `%ConfigError{}` is a mailglass-domain exception raised at boot or request time. Unknown atoms in a router macro are adopter programmer error at module-compile time — plain Elixir `ArgumentError` is the correct class (it matches Phoenix, Ecto, Plug idioms). CI fails adopter builds on the compile error; no need to serialize the error to JSON or classify it as retryable.
- **`Mailglass.Tenancy.clear/0` returns `:ok` via public API.** Plans 06 + 07 tests can now call `Mailglass.Tenancy.clear()` in `on_exit` blocks without needing to know the internal `:mailglass_tenant_id` atom. The atom's name could change in a future refactor (e.g. namespace-mangle to `{Mailglass.Tenancy, :tenant_id}`) without breaking test code. Revision W7 verbatim.
- **`:webhook_ingest_mode` is `@doc false` because `:async` is reserved.** NimbleOptions enforces the `{:in, [:sync, :async]}` closed set so mistyped values fail at boot. Plan 06's `ingest_multi/3` will add an explicit runtime raise on `:async` — the moduledoc there can explain that `:async` lands at v0.5 with a Dead-Letter Queue admin surface. v0.1 adopters see `:sync` only in generated docs (`@doc false` hides the full enum); if they grep the source, the commented rationale tells them where `:async` is heading.
- **Dispatcher doc updated post-concrete-impl.** Plan 04-04's Tenancy module text described the fallback as "Until Plan 05 ships the `SingleTenant.resolve_webhook_tenant/1` impl". This plan ships it, so the doc now reads "Adopter resolvers that do not implement the callback also receive `{:ok, "default"}` — via the dispatcher's `function_exported?/3` check". A live contract, not a placeholder.
- **Optional context hints in `format_message/2` beat new struct fields.** Both `SignatureError.:malformed_header`'s `ctx[:detail]` and `TenancyError.:webhook_tenant_unresolved`'s `ctx[:reason]` are opt-in — callers that don't pass the key get the bare sentence. Adding struct fields would have forced all raise sites to pass `provider:` / `detail:` / `reason:` as constructor options, a churning change across Plans 04-02 / 04-03 / 04-04. Context map fields are additive-compatible.
- **Phoenix.Router macro-expansion test is synthesized from scratch.** No mailglass or prior-art library (accrue / lattice_stripe / sigra / scrypath) had a router-macro test analog before this plan. The pattern — a test-local `defmodule UnderTestRouter do use Phoenix.Router; import X; scope ...; your_macro ...; end` + `assert UnderTestRouter.__routes__() |> Enum.find(...)` — is the canonical Phoenix Router reflection approach and async-safe (each `describe` block scopes a fresh router module). Established for future mailglass macro tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan 04-04's `UnresolvedTenancy` test stub missing `@impl` annotation after callback formalization**

- **Found during:** Task 2 verification (`mix test test/mailglass/webhook/plug_test.exs --warnings-as-errors`)
- **Issue:** `test/mailglass/webhook/plug_test.exs:137` defines `def resolve_webhook_tenant(_context), do: {:error, :no_tenant_match}` inside `UnresolvedTenancy`. Before Plan 05, `Mailglass.Tenancy` had no formal `@callback resolve_webhook_tenant/1` — the stub was just an ordinary function. After Task 2 formalizes the `@callback`, the compiler emits `module attribute @impl was not set for function resolve_webhook_tenant/1 callback (specified in Mailglass.Tenancy)`. Under `--warnings-as-errors`, this fails the test run.
- **Fix:** Added `@impl Mailglass.Tenancy` before the `def resolve_webhook_tenant/1` line in the `UnresolvedTenancy` stub. Direct consequence of Plan 05's formalization; does not represent scope creep.
- **Files modified:** `test/mailglass/webhook/plug_test.exs`
- **Verification:** `mix test test/mailglass/webhook/plug_test.exs --warnings-as-errors --exclude requires_plan_06` → 12 tests, 0 failures
- **Committed in:** `5262142` (folded into Task 2's feat commit — the fix is a direct consequence of the same commit's `@callback` addition)

---

**Total deviations:** 1 auto-fixed (Rule 1 bug).

**Impact on plan:** The single deviation is a downstream consequence of Task 2's formal `@callback` declaration exposing an existing test stub's missing `@impl` annotation. Fix is one line; no behavioural change to the stub. No additional tasks, no architectural surprises.

## Threat Flags

None. The threat surface introduced by Plan 04-05 matches the plan's `<threat_model>` exactly:

- **T-04-08 (Spoofing via forged tenant in path)** — mitigated by `Mailglass.Tenancy.ResolveFromPath`'s documented contract: it EXTRACTS `path_params["tenant_id"]` only; it does NOT validate the tenant's existence in any persistence layer. The `scope/2` raise forces adopters to compose it with a real Tenancy module (whose `scope/2` applies the actual WHERE-clause isolation). Forged `tenant_id` values in the URL can only reach data the adopter's `scope/2` exposes for that ID. Mitigation verified by the `scope/2` raise test + the documentation contract.
- **T-04-04 (Info Disclosure in error messages + api_stability.md)** — mitigated by the `format_message/2` discipline: brand-voice messages contain only the atom + operator-facing hint (config key name, provider name). `grep -E "(raw_body|sig_b64|headers|remote_ip|conn.req_headers)" lib/mailglass/errors/{signature,tenancy,config}_error.ex` returns zero matches inside any `format_message/2` clause. The optional `ctx[:reason]` on `TenancyError.:webhook_tenant_unresolved` uses `inspect/1` — adopters control what reason atom they pass, so the contract is adopter-supplied-safe.

## Issues Encountered

- **Plan 04-04's `UnresolvedTenancy` test stub `@impl` warning** — documented above as Deviation #1. The fix is trivial (add `@impl Mailglass.Tenancy`) and was bundled into Task 2's commit because it's a direct consequence of the same commit's `@callback` formalization.
- **Acceptance criterion substring mismatch (`## Webhook` vs `## §Webhook`)** — the plan's acceptance criteria include `grep -q "## Webhook (added in Phase 4)"` but the existing file uses `## §Webhook (added in Phase 4)` (Phase 3's section convention). Kept the `§` prefix to match every other section in the file; the substantive requirement (populated §Webhook section) is met. The `grep` check would fail on the literal string but the file is correct by document convention.
- **Pre-existing citext OID staleness in full-suite runs** — unchanged since Phase 2 Plan 06; tracked in `.planning/phases/02-persistence-tenancy/deferred-items.md` with 4 Phase 6 candidate fixes. Does not affect Plan 05 work; plan-level verification (`mix test test/mailglass/webhook/ test/mailglass/tenancy/ test/mailglass/errors/ ...`) passes 149/0.

## User Setup Required

None. Phase 4 Wave 2B is library-only code. Adopter-facing wiring is documented in the `Mailglass.Webhook.Router` moduledoc + `docs/api_stability.md §Webhook` — `guides/webhooks.md` (Phase 7 DOCS-02) will consolidate.

## Next Phase Readiness

Plan 04-05 closes Wave 2 and unblocks every remaining Phase 4 plan:

- **Plan 06 (Ingest Multi)** — can compose against finalized `Mailglass.Tenancy.resolve_webhook_tenant/1` contract (formal `@callback`, SingleTenant concrete impl, ResolveFromPath opt-in sugar), the finalized 7-atom `SignatureError` set + `:webhook_verification_key_missing` / `:webhook_caching_body_reader_missing` ConfigError atoms, and `Mailglass.Config.webhook_ingest_mode/0` accessor for the `:async`-guard raise. The ingest pipeline has no further atom additions to make — it can focus purely on the `Ecto.Multi` composition.
- **Plan 07 (Reconciler)** — can reference the `Mailglass.Tenancy.resolve_webhook_tenant/1` documentation in api_stability.md when documenting the orphan-scan worker's tenant discipline. No Tenancy API surface changes expected.
- **Plan 08 (Telemetry helpers)** — will extract `Mailglass.Webhook.Telemetry.ingest_span/2` wrapping `:telemetry.span/3` (mechanical rename per Plan 04-04 SUMMARY's note). No Router macro coupling; the Plug's two direct `:telemetry.span/3` calls become the rename's targets.
- **Plan 09 (UAT + property tests)** — can exercise the full end-to-end path through the Router macro in a `MyTestAppRouter` that `import Mailglass.Webhook.Router` + `mailglass_webhook_routes "/webhooks"`, providing a live Phoenix endpoint for UAT property tests. The macro's compile-time validation is already test-covered; UAT tests focus on request-response round-trips.
- **Adopter wiring** — at Plan 05 ship time, an adopter can (modulo Plan 06's Ingest Multi):

  ```elixir
  # endpoint.ex
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []},
    length: 10_000_000

  # router.ex
  pipeline :mailglass_webhooks do
    plug :accepts, ["json"]
  end

  scope "/", MyAppWeb do
    pipe_through :mailglass_webhooks
    mailglass_webhook_routes "/webhooks"
  end

  # config.exs
  config :mailglass, :postmark, basic_auth: {"user", "pass"}
  config :mailglass, :sendgrid, public_key: "<base64-DER>"
  ```

  The full lifecycle (verify → resolve_tenant → normalize) runs end-to-end; Plan 06 lights up the persistence + broadcast final steps.

**Blockers or concerns:** None. Pre-existing citext OID flakiness remains Phase 6 deferred (unchanged).

**Phase 4 progress:** 5 of 9 plans complete. Wave 2 (Plans 04 + 05) closed.

## Self-Check: PASSED

Verified:

- `lib/mailglass/webhook/router.ex` — FOUND
- `lib/mailglass/tenancy/resolve_from_path.ex` — FOUND
- `test/mailglass/webhook/router_test.exs` — FOUND
- `test/mailglass/tenancy/resolve_from_path_test.exs` — FOUND
- `lib/mailglass/tenancy.ex` — modified (`@optional_callbacks` extended; `@callback resolve_webhook_tenant/1` present; `def clear` present)
- `lib/mailglass/tenancy/single_tenant.ex` — modified (`def resolve_webhook_tenant` present)
- `lib/mailglass/config.ex` — modified (`:webhook_ingest_mode` schema entry + `def webhook_ingest_mode` accessor present)
- `docs/api_stability.md` — modified (§Webhook section + `resolve_webhook_tenant/1` callback doc + 3 error tables)
- Commit `ee33368` (Task 1 — Router macro + tests) — FOUND in `git log`
- Commit `5262142` (Task 2 — Tenancy formalization + ResolveFromPath + stub fix) — FOUND
- Commit `e57a6cf` (Task 3 — error finalization + :webhook_ingest_mode + api_stability.md) — FOUND
- `mix compile --warnings-as-errors --no-optional-deps` — exits 0
- `mix test test/mailglass/webhook/router_test.exs --warnings-as-errors` — 6 tests, 0 failures
- `mix test test/mailglass/tenancy/resolve_from_path_test.exs --warnings-as-errors` — 9 tests, 0 failures
- `mix test test/mailglass/webhook/ test/mailglass/tenancy/ test/mailglass/errors/ test/mailglass/tenancy_test.exs test/mailglass/error_test.exs test/mailglass/config_test.exs --warnings-as-errors --exclude requires_plan_06 --exclude flaky` — 149 tests, 0 failures
- `mix verify.phase_02` — 59 tests, 0 failures
- `mix verify.phase_03` — 62 tests, 0 failures, 2 skipped
- `mix verify.phase_04` — 0 tests, 0 failures (correct — Wave 2; Plan 09 ships first `:phase_04_uat`-tagged tests)
- `grep -q "defmacro mailglass_webhook_routes" lib/mailglass/webhook/router.ex` — exits 0
- `grep -q "@optional_callbacks tracking_host: 1, resolve_webhook_tenant: 1" lib/mailglass/tenancy.ex` — exits 0
- `grep -q "@callback resolve_webhook_tenant" lib/mailglass/tenancy.ex` — exits 0
- `grep -q "def resolve_webhook_tenant" lib/mailglass/tenancy/single_tenant.ex` — exits 0
- `grep -q "@behaviour Mailglass.Tenancy" lib/mailglass/tenancy/resolve_from_path.ex` — exits 0
- `grep -q "def clear" lib/mailglass/tenancy.ex` — exits 0
- `grep -q ":webhook_ingest_mode" lib/mailglass/config.ex` — exits 0
- `grep -q "def webhook_ingest_mode" lib/mailglass/config.ex` — exits 0
- `grep -q "resolve_webhook_tenant/1" docs/api_stability.md` — exits 0
- `grep -q "Mailglass.Webhook.Router.mailglass_webhook_routes" docs/api_stability.md` — exits 0
- 3 of 4 Plan 01 placeholder `<!-- Phase 4 -->` markers removed; 1 remaining (telemetry forward-ref at line 246) is intentional and scoped to Plans 06-08

---
*Phase: 04-webhook-ingest*
*Completed: 2026-04-23*
