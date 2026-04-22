---
gsd_state_version: 1.0
milestone: v0.1
milestone_name: milestone
status: planning
stopped_at: Phase 2 context gathered
last_updated: "2026-04-22T16:37:38.136Z"
last_activity: 2026-04-22
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-21)

**Core value:** Email you can see, audit, and trust before it ships.
**Current focus:** Phase 01 — foundation

## Current Position

Phase: 2
Plan: Not started
Status: Ready to plan
Last activity: 2026-04-22

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 6
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| — | — | — | — |
| 01 | 6 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: — (no execution history yet)

*Updated after each plan completion.*
| Phase 01 P01-01 | 8min | 2 tasks | 20 files |
| Phase 01 P02 | 5min | 2 tasks | 9 files |
| Phase 01 P03 | 10min | 2 tasks | 9 files |
| Phase 01 P04 | 4min | 2 tasks tasks | 7 files files |
| Phase 01 P05 | 8 | 3 tasks | 8 files |
| Phase 01 P06 | 12min | 2 tasks | 8 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (D-01..D-20 — all locked at initialization).

Most load-bearing for Phase 1:

- **D-06**: Bleeding-edge floor — Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+.
- **D-17**: Custom Credo checks enforce domain rules (operationalized in Phase 6, but their forbidden patterns must be avoided from Phase 1 code).
- **D-18**: HEEx + Phoenix.Component is the default renderer; MJML is opt-in via the `:mjml` Hex package (NOT `:mrml` — corrected in research).
- Swoosh :api_client deferred to adopter via config :swoosh, :api_client, false — mailglass does not pin an HTTP transport
- Flat root Boundary on Mailglass (deps: [], exports: []) — classifies Mailglass.* modules without constraining internal deps; sub-boundaries land with later plans
- Mailglass.Config.validate_at_boot!/0 added to elixirc_options no_warn_undefined as MFA tuple forward reference until Plan 03 lands Config
- Struct-discrimination tests use __struct__ module comparison (err.__struct__ == Mailglass.TemplateError) instead of literal match?(%Mod{}, err) — Elixir 1.19 type checker narrows terms statically, so literal mismatch patterns trip --warnings-as-errors. Runtime struct-module comparison tests the same contract without the type-narrowing conflict.
- RateLimitError.new/2 accepts both :retry_after_ms as a top-level option (populates the struct field) and context.retry_after_ms (for message formatting). Plan showed bind-rebind via %RateLimitError{err | retry_after_ms: ms}; direct option is cleaner for callers.
- Mailglass.Error.root_cause/1 terminates on non-mailglass causes — when :cause is a plain Exception without its own :cause field (e.g. %RuntimeError{}), walking stops there. Third-party exceptions become leaves in the cause chain.
- Mailglass.Config uses :persistent_term with namespaced key {Mailglass.Config, :theme} — write once at validate_at_boot!/0, read O(1) on every render; no ETS, no GenServer per D-19
- :telemetry.span/3 auto-injects :telemetry_span_context for OTel span correlation — exempted from the D-31 metadata whitelist in tests because it is library machinery, not adopter-supplied PII (documented inline in telemetry_test.exs)
- StreamData metadata generator for the whitelist property test uses list_of(tuple/2) + Enum.into(%{}) instead of map_of/2 — the 11-element whitelist key space is too small for map_of's uniq-key generator, which hit TooManyDuplicatesError on the 8th run
- Mailglass.Repo.transact/1 delegates via Ecto 3.13+ transact/2 (tuple-rollback semantics), not the deprecated transaction/1 — Phase 2 events-ledger append relies on the {:ok,_}/{:error,_} rollback contract
- Mailglass.Message.new/2 uses Keyword.get with per-option defaults — uniform builder regardless of opt count, pattern-matches %Swoosh.Email{} on input
- Mailglass.OptionalDeps.Sigra is conditionally compiled via if Code.ensure_loaded?(Sigra) do ... end — matches accrue-sigra pattern where Sigra itself expects the module to not exist when :sigra absent; callers probe existence via Code.ensure_loaded?(Mailglass.OptionalDeps.Sigra), not available?/0
- OpenTelemetry gateway probes :otel_tracer (stable API surface), not the package atom :opentelemetry (not a loadable module) — matches accrue/integrations and PATTERNS.md line 814
- render_slot_to_binary/2 calls Phoenix.Component.__render_slot__/3 directly with nil for the changed tracker — the public render_slot/2 is a macro that only works inside ~H. Needed for button/1's VML branch where slot content must be a binary suitable for splicing into a raw MSO conditional block.
- Button :variant and :tone are orthogonal. :tone picks the brand color (glass/ink/slate); :variant picks the rendering mode (primary=fill, secondary=ice-tint, ghost=transparent). Both resolve to concrete hex values before entering the VML block — classic Outlook cannot resolve brand tokens in v:roundrect fillcolor/strokecolor.
- <.img> :alt is required at compile time via attr :alt, :string, required: true. Phoenix.Component's compile-time check emits 'missing required attribute "alt"' whenever <.img> is used without it — under --warnings-as-errors that's a hard failure. The accessibility floor cannot be bypassed by omission.
- img_no_alt_test.exs stays @moduletag :skip. Compile-time checks can't be tested by running them at test runtime — compiling a fixture module inside the test suite would FAIL the entire suite because the compile error propagates. The stub exists as documentation of the contract.
- HEEx does not interpolate expressions inside HTML comments. VML-bearing components (row, column, button) pre-build MSO conditional blocks as strings, wrap with Phoenix.HTML.raw/1, and embed via expression holes. The <a> HTML fallback uses normal HEEx because the if-not-mso boundary terminates the comment per HTML parser rules.
- Renderer sub-boundary pattern: use Boundary, deps: [Mailglass] + root-level exports controls the CORE-07 call surface from a single source of truth. Future sub-boundaries (Outbound/Events/Webhook/Admin) follow the same shape; the root exports list grows monotonically.
- HEEx function components in test fixtures must bind 'assigns' by exact name (not '_assigns') because the ~H sigil macro-expands a reference to assigns even when the template has no interpolations. Using the prefixed name causes 'requires a variable named assigns to exist' at fixture-build time.
- Renderer plaintext walker runs on the pre-VML HTML tree (D-15) BEFORE Premailex CSS inlining. Pipeline: render_html -> to_plaintext (pre-VML) -> inline_css (Premailex) -> strip_mg_attributes. Premailex adds VML wrappers/OfficeDocumentSettings that must never leak into text_body.
- Compliance supports both map-shaped and list-shaped Swoosh.Email.headers via dual pattern-match clauses. Current Swoosh 1.25 uses a map, but a future schema change won't silently break the Phase 1 contract.

### Pending Todos

None yet.

### Blockers/Concerns

- **Premailex (MEDIUM-confidence dep)**: last release Jan 2025, no credible replacement. Flag as "watch this dep" through v0.5; revisit at v0.5 retro per SUMMARY.md gaps.
- **`mailglass_inbound` deferred to v0.5+**: shares webhook plumbing with v0.5 deliverability work; intentionally not in v0.1 roadmap.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: --stopped-at
Stopped at: Phase 2 context gathered
Resume file: --resume-file

**Planned Phase:** 1 (Foundation) — 6 plans — 2026-04-22T14:18:01.914Z
