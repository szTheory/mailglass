# Phase 1: Foundation — Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Zero-dep foundation modules (Error hierarchy, Config, Telemetry, Repo.transact wrapper, IdempotencyKey) plus a pure-function HEEx rendering pipeline (Message, Components, TemplateEngine behaviour + HEEx impl, Renderer, Compliance header stubs). At the close of Phase 1, a developer can call `Mailglass.Renderer.render(message)` on a HEEx-based mailable and receive `{html_body, text_body}` with CSS inlined and plaintext auto-generated in <50ms, without any persistence, transport, or processes.

**13 REQ-IDs:** CORE-01..07 (foundations), AUTHOR-02..05 (components + render pipeline + Gettext + TemplateEngine), COMP-01..02 (RFC-required header stubs).

**Out of scope for this phase (lands later):** Mailable behaviour (Phase 3), Outbound facade (Phase 3), Delivery/Event/Suppression schemas (Phase 2), Adapter behaviour (Phase 3), Webhook plug (Phase 4), Admin LiveView (Phase 5), Credo checks (Phase 6), Installer (Phase 7).

</domain>

<decisions>
## Implementation Decisions

### Error hierarchy (CORE-01)

- **D-01:** Ship **six sibling `defexception` modules** — `Mailglass.SendError`, `Mailglass.TemplateError`, `Mailglass.SignatureError`, `Mailglass.SuppressedError`, `Mailglass.RateLimitError`, `Mailglass.ConfigError`. No parent struct. "Struct hierarchy" in PROJECT.md is the shared behaviour contract + naming, not a parent type.
- **D-02:** `Mailglass.Error` is a **namespace + behaviour module**, not a struct. It exports: `@type t :: union of six error structs`, `@callback type(t) :: atom`, `@callback retryable?(t) :: boolean`, and public helpers `is_error?/1`, `kind/1`, `retryable?/1`, `root_cause/1`.
- **D-03:** **Common field set on every error struct:** `:type` (closed atom, acts as sub-kind discriminator), `:message` (formatted once in `new/1`; Exception protocol requires the field), `:cause` (another exception struct OR nil — wraps adapter/crypto/provider errors), `:context` (`%{atom => primitive}` map, PII-free).
- **D-04:** **Per-kind field specializations** — only where justified by Dialyzer precision:
  - `RateLimitError.retry_after_ms :: non_neg_integer`
  - `SignatureError.provider :: atom`
  - `SendError.delivery_id :: binary | nil`
- **D-05:** All six are `defexception` (raisable). Bang variants (`deliver!/2`, `Config.validate!/0`, `Webhook.Plug` on signature mismatch) use `raise`; non-bang callers get `{:error, struct}` with the same structure.
- **D-06:** **`Jason.Encoder` derived on `[:type, :message, :context]` only** — `:cause` is deliberately excluded from JSON serialization to prevent recursive emission of adapter structs that may carry provider payloads with recipient PII.
- **D-07:** **Closed `:type` atom set per struct**, documented in `api_stability.md` §Errors. Automated test asserts `ErrorModule.__types__/0` matches the documented list. Adding a value requires CHANGELOG entry + `@since` annotation (minor version); removals require a major version bump.
  - `SendError.type ∈ :adapter_failure | :rendering_failed | :preflight_rejected | :serialization_failed`
  - `TemplateError.type ∈ :heex_compile | :missing_assign | :helper_undefined | :inliner_failed`
  - `SignatureError.type ∈ :missing | :malformed | :mismatch | :timestamp_skew`
  - `SuppressedError.type ∈ :address | :domain | :tenant_address` (matches `Suppression.scope`)
  - `RateLimitError.type ∈ :per_domain | :per_tenant | :per_stream`
  - `ConfigError.type ∈ :missing | :invalid | :conflicting | :optional_dep_missing`
- **D-08:** **Pattern-match by struct only.** Matching `%{message: "..."}` or `String.contains?(err.message, "...")` is forbidden. `message/1` is computed from `:type`/`:cause`/`:context` inside `new/1` — adopters match on `:type` and `__struct__`, not message content. Enforced by Credo check `NoErrorMessageStringMatch` in Phase 6.
- **D-09:** **Retry policy defaults encoded via `retryable?/1`.** `SignatureError` and `ConfigError` return `false` (crash + supervise). `SendError`, `RateLimitError`, `SuppressedError` return context-dependent booleans (caller decides). `TemplateError` returns `false` in prod (fix the template), `true` under Oban retry in dev.

### MSO / Outlook VML fallback strategy (AUTHOR-02)

- **D-10:** **Surgical VML.** AUTHOR-02's "every component renders with MSO Outlook VML fallback wrapper" is interpreted as "the component set, taken together, renders correctly in classic Outlook — VML where Word engine genuinely requires it, not everywhere." Per-component spec below.
- **D-11:** **VML per component:**

  | Component | VML? | Pattern |
  |---|---|---|
  | `<.preheader>` | no | `display:none` + zero-width padding; `mso-hide:all` |
  | `<.container>` | no | 600px centered `<table>`, `mso-table-lspace/rspace:0pt` |
  | `<.section>` | no | full-width `<table>` + inner `<td>` padding, `mso-line-height-rule:exactly` |
  | `<.row>` | **yes (ghost table)** | `<!--[if mso]><table role="presentation"><tr><![endif]-->` wrapping `display:inline-block` divs |
  | `<.column>` | **yes (ghost td)** | `<!--[if mso]><td valign="top" width="..."><![endif]--> ... <!--[if mso]></td><![endif]-->` |
  | `<.heading>` | no | `<h1>`/`<h2>` inside `<td>` + `mso-line-height-rule:exactly` |
  | `<.text>` | no | `<p>` inside `<td>` + `mso-line-height-rule:exactly` |
  | `<.button>` | **yes (`<v:roundrect>`)** | bulletproof button with HTML fallback (`mso-hide:all` on `<a>`) |
  | `<.img>` | no | explicit `width`/`height` attributes + `-ms-interpolation-mode:bicubic` |
  | `<.link>` | no | inline `color:` + `text-decoration:` on both `<a>` AND wrapping `<span>` |
  | `<.hr>` | no | zero-height `<table>` + 1px border-top `<td>` |

- **D-12:** **Layout `<head>` emits once** (in `Mailglass.Components.layout/1`):
  - `<!--[if gte mso 9]><xml><o:OfficeDocumentSettings><o:AllowPNG/><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml><![endif]-->` — fixes 120-DPI image scaling in classic Outlook Windows.
  - `<meta name="color-scheme" content="light">` + `<meta name="supported-color-schemes" content="light">` — designed for light mode only in v0.1.
- **D-13:** **Dark mode deferred to v0.5** with explicit reasoning: Outlook.com partial-invert is unfixable without per-adopter tuning; shipping half-right dark mode violates "modern, not trendy" and sets adopter expectations we can't meet. v0.5 revisits with proper `dark:` token variants.
- **D-14:** **Premailex must preserve conditional comments.** Set `keep_conditional_comments: true` (or equivalent — see Premailex issue #36). Golden fixture test in `test/mailglass/components/vml_preservation_test.exs` guards the regression.
- **D-15:** **Floki plaintext runs on the pre-VML logical component tree** — not the final HTML. `Mailglass.Renderer.to_plaintext/1` walks the component tree before the VML wrapper step, so VML artifacts (`v:roundrect`, ghost-table markers) never leak into plaintext output.

### Component API style (AUTHOR-02)

- **D-16:** **Per-component hybrid with brand-theme tokens.** Follow Phoenix 1.8 `core_components.ex` conventions (slot + `class` + `:global` rest). Split by role:
  - **Content** (`<.heading>`, `<.text>`, `<.link>`, `<.button>`) → slot + `class` + enum variants/tones.
  - **Layout** (`<.container>`, `<.section>`, `<.row>`, `<.column>`) → slot + `class` + enum bg tokens.
  - **Atomic** (`<.img>`, `<.hr>`, `<.preheader>`) → attribute-only, self-closing.
- **D-17:** **`attr :class, :any, default: nil`** on every component. **`attr :rest, :global, include: ~w(id data-* aria-*)`** on every component. **Content components deliberately exclude `style` from `:global`** — refuses the React Email "inline-style merges with component defaults" footgun.
- **D-18:** **Variant enums with compile-time warnings** via `values:` lists. Stable API surface, documented in `api_stability.md`.
  - `<.button>` — `variant: :primary | :secondary | :ghost`, `tone: :glass` default
  - `<.heading>` — `level: 1..4`, `align: :left | :center | :right`, `tone: :ink | :glass | :slate`
  - `<.text>` — `size: :sm | :base | :lg`, `tone: :ink | :slate`, `align`
  - `<.link>` — `tone: :glass | :ink`
  - `<.container>` / `<.section>` — `bg: :paper | :mist | :ink | :custom` + `bg_hex` escape
  - `<.row>` — `gap: integer`
  - `<.column>` — `width: integer | :auto`, `valign: :top | :middle | :bottom`
  - `<.hr>` — `tone: :mist | :slate`
  - `<.img>` — `alt` **required attribute** (enforces accessibility at compile time)
  - `<.preheader>` — `text: string` required
- **D-19:** **Theming model: compile-time theme map, cached via `:persistent_term`, emitted as fully-inlined `style="..."` attributes.** CSS variables are NOT used in final HTML (inconsistent email-client support). Theme lives in `config :mailglass, :theme`; `Mailglass.Config` validates via NimbleOptions; `Mailglass.Components.Theme.get/0` reads the cached map at render time.

  ```elixir
  config :mailglass, :theme,
    colors: %{
      ink: "#0D1B2A", glass: "#277B96", ice: "#A6EAF2",
      mist: "#EAF6FB", paper: "#F8FBFD", slate: "#5C6B7A"
    },
    fonts: %{
      body: ~s('Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif),
      display: ~s('Inter Tight', 'Inter', sans-serif),
      mono: ~s('IBM Plex Mono', ui-monospace, monospace)
    }
  ```

- **D-20:** **Class composition:** no external library. Inline HEEx list-literal pattern (`class={["btn", @class, variant_class(@variant)]}`) from core_components. Private helper `Mailglass.Components.CSS.merge_style/2` returns a single inlined `style="..."` string where needed.
- **D-21:** **Escape hatch:** `attr :class, :any` + `attr :rest, :global`. For truly custom shapes, adopters write raw HEEx tables — documented, not glamorous. No `<.bare_button>` primitive ships in v0.1.
- **D-22:** **Plaintext extraction via `data-mg-plaintext` strategies.** Each content component emits `data-mg-plaintext="<strategy>"` on its root node. `Mailglass.Renderer.to_plaintext/1` is a custom Floki walker (not bare `Floki.text/1`):
  - `<.button>`, `<.link>` → `:link_pair` → `"Label (url)"`
  - `<.img>` → `:text` → alt-text as content (no `"image:"` prefix)
  - `<.hr>` → `:divider` → `"\n---\n"`
  - `<.heading>` → `:heading_block` → wraps in blank lines; level 1 uppercases
  - `<.preheader>` → `:skip` → excluded from plaintext
  - `<.text>` → `:text` → default
  - A terminal Floki pass strips all `data-mg-*` attributes from the final HTML wire.
- **D-23:** **Gettext integration is adopter-responsibility inside slots.** No `:gettext_backend` attribute on any component. Adopters write `<.heading><%= dgettext("emails", "Welcome, %{name}", name: @user.name) %></.heading>`. `<.preheader text={…}>` is the only attribute-translated exception (no slot to translate in).
- **D-24:** **No slot module constraints.** LiveView has no child-module enforcement. Document convention ("`<.row>` intends to contain `<.column>`"); dev-only `Logger.warning` fires from the Floki post-processor if a non-`<.column>` direct child appears inside a `<.row>`.
- **D-25:** **HTML-native attribute names only.** `href`, `src`, `alt`, `width`, `height` keep their native meaning. Brand tokens live in enum attrs (`tone`, `variant`, `bg`), never in color-named attrs like `background-color`. Avoids the MJML dashed-name parallel-mental-model cost.

### Telemetry enforcement (CORE-03)

- **D-26:** **Convention + Phase 6 Credo, no runtime wrapper.** `:telemetry.execute/3` already isolates handler exceptions (per-handler try/catch, auto-detach, emits `[:telemetry, :handler, :failure]`). Adding mailglass-side try/rescue is either dead code or worse — swallows the meta-event operators need. CORE-03's "handlers must not break the pipeline" is already satisfied.
- **D-27:** **`Mailglass.Telemetry` Phase 1 surface:**
  - **Named span helpers per domain** — `render_span/2` in Phase 1. Others land in their owning phases: `send_span`/`batch_span` (Phase 3), `persist_span`/`events_append_span` (Phase 2), `webhook_verify_span`/`webhook_ingest_span` (Phase 4), `preview_render_span` (Phase 5). Each helper is ~15 lines, co-located with its domain, wraps `:telemetry.span/3` bare.
  - **Low-level `execute/3`** for non-span emits (rare counter events). Prepends `:mailglass`; the handful of call sites using it are acceptable grep-cost.
  - **`attach_default_logger/1`** — mirrors Oban/lattice_stripe precedent.
  - **`@moduledoc` event catalog** — every event mailglass will ever emit, with measurement/metadata tables. Single source of truth for adopters.
- **D-28:** **No runtime meta-filtering.** A whitelist regression that silently drops `:tenant_id` is catastrophic in multi-tenant systems. Credo (Phase 6) catches drift at lint time — runtime does not need a parallel guardrail.
- **D-29:** **No compile-time macro validation.** Module-size bloat + opaque to readers. Phase 6 Credo AST walk is sufficient and visible in CI logs.
- **D-30:** **4-level event path at every emit site:** `[:mailglass, :domain, :resource, :action]` with `:start | :stop | :exception` suffix. Phase 1 emits `[:mailglass, :render, :message, :start|:stop|:exception]`.
- **D-31:** **Metadata whitelist (enforced at lint time in Phase 6):** `:tenant_id, :mailable, :provider, :status, :message_id, :delivery_id, :event_id, :latency_ms, :recipient_count, :bytes, :retry_count`. **Forbidden (PII):** `:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`.
- **D-32:** **OpenTelemetry is adopter-owned.** `opentelemetry_telemetry` already bridges any `[:*, :start]`/`[:*, :stop]` pair via the auto-added `telemetry_span_context` metadata. Mailglass does NOT ship `attach_otel/0` — it would duplicate a third-party contract and create cross-SDK maintenance burden. `Mailglass.OptionalDeps.OpenTelemetry.available?/0` exists only for future internal gating.
- **D-33:** **Phase 1 property test:** `test/mailglass/telemetry_test.exs` attaches a handler to `[:mailglass | _]`, drives 1000 StreamData-generated renders, asserts every `:stop` event's metadata keys are a subset of the whitelist and every event includes `:tenant_id` (once multi-tenancy lands in Phase 2, test expands; Phase 1 version uses a placeholder `tenant_id: "single_tenant"`).

### Shared discretion / Claude's discretion

- `Mailglass.Config` NimbleOptions schema starts minimal in Phase 1 (covers theme, telemetry, renderer knobs, optional-dep flags) and expands in each subsequent phase — Config stays the sole user of `Application.compile_env*` per LINT-08.
- `Mailglass.Repo.transact/1` scaffolds in Phase 1 with no tests (no schemas yet) — genuine usage lands in Phase 2. Ship the wrapper + `@doc` + a placeholder doctest; LINT checks in Phase 6 will catch misuse.
- `Mailglass.IdempotencyKey` format: `"#{provider}:#{provider_event_id}"` (CORE-05 locked). Sanitization / length-cap heuristics are Claude's call.
- Exact error `message` string formatting per `:type` — brand-voice-conformant ("Delivery blocked: recipient is on the suppression list", never "Oops!").
- `boundary` block shape at Phase 1 — declare blocks only for modules that exist in Phase 1 (Error, Config, Telemetry, Repo, IdempotencyKey, Message, Components, TemplateEngine, Renderer, Compliance). Empty-skeleton blocks for later phases are premature.
- `Mailglass.Components.layout/1` exact HEEx structure (meta tags, viewport, media-query hoisting) — follow the patterns in the referenced research, no new constraints.

### Folded todos

None — no pending todos matched Phase 1.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project locked context

- `.planning/PROJECT.md` — Key Decisions D-01..D-20 (project-level, pre-existing, locked). Gray-area D-01..D-33 in this CONTEXT.md are phase-local.
- `.planning/REQUIREMENTS.md` — §Foundations (CORE-01..07), §Authoring (AUTHOR-02..05), §Compliance (COMP-01..02). The 13 REQ-IDs delivered by Phase 1.
- `.planning/ROADMAP.md` — Phase 1 success criteria (5 checks) + pitfalls guarded against (LIB-02, LIB-07, OBS-01, OBS-04, DIST-04, MAINT-04).
- `.planning/STATE.md` — current position + D-06, D-17, D-18 noted as load-bearing for Phase 1.

### Research synthesis

- `.planning/research/SUMMARY.md` §Executive Summary, §Key Findings, §Implications for Roadmap → Phase 1 (Layer 0 + 1).
- `.planning/research/STACK.md` — verified Apr 2026 versions for every required + optional dep; `mix compile --no-optional-deps` lane; optional-dep gateway pattern.
- `.planning/research/ARCHITECTURE.md` §1 (module catalog), §2.1 (hot-path data flow), §3 (process architecture — stateless for Phase 1), §5 (behaviour boundaries — TemplateEngine is the one pluggable seam in Phase 1), §6 (Layer 0 + 1 build order), §7 (boundary enforcement blocks).
- `.planning/research/PITFALLS.md` — LIB-02, LIB-07, OBS-01, OBS-04, DIST-04, MAINT-04 (the six pitfalls Phase 1 must structurally prevent).

### Engineering DNA + domain language

- `prompts/mailglass-engineering-dna-from-prior-libs.md` §2.4 (Errors as public API contract), §2.5 (Telemetry 4-level convention), §2.8 (Custom Credo checks), §3.6 (append-only ledger — forward reference for Phase 2). The distilled patterns from accrue / lattice_stripe / sigra / scrypath.
- `prompts/mailer-domain-language-deep-research.md` §13 — canonical vocabulary (Mailable / Message / Delivery / Event / InboundMessage / Mailbox / Suppression). Phase 1 ships `Mailglass.Message` — naming must match.
- `prompts/Phoenix needs an email framework not another mailer.md` — founding thesis; the gap mailglass fills.

### Brand + ecosystem

- `prompts/mailglass-brand-book.md` — palette (Ink #0D1B2A, Glass #277B96, Ice #A6EAF2, Mist #EAF6FB, Paper #F8FBFD, Slate #5C6B7A), typography (Inter, Inter Tight, IBM Plex Mono), mobile-first, no glassmorphism/lens-flares/literal-broken-glass. Theme map in D-19 is lifted directly from here.
- `prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` — current ecosystem state; informs dep version choices.

### Best-practice references

- `prompts/elixir-best-practices-deep-research.md` — telemetry/observability conventions; error-handling idioms.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — public API stability (`api_stability.md` shape), `:since` annotations.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Release Please linked-versions, Hex publish discipline (forward reference to Phase 7).
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` §1-§4 — process architecture patterns; confirms "mostly functional, one ETS" direction (Phase 3+).
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix 1.8 conventions.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — `Phoenix.Component` idioms, `attr/3` + `slot/3` patterns (informs D-16..D-25).
- `prompts/ecto-best-practices-deep-research.md` — forward reference for Phase 2.

### Forward-created artifacts (Phase 1 deliverables referenced by later phases)

- `api_stability.md` — this file is **created in Phase 1** and locks:
  - `Mailglass.Adapter` return shape (stubbed; adapter implementation lands Phase 3)
  - `Mailglass.Error` hierarchy + closed `:type` atom sets per D-07
  - `Mailglass.Components` attr/slot surface + variant enum values per D-18
  - `Mailglass.Telemetry` event catalog (Phase 1 subset; expands per phase)
  - Versioning policy (`:since` / minor-add / major-remove)

### External standards

- RFC 8058 — `List-Unsubscribe-Post` header (deferred to v0.5; `Mailglass.Compliance` stubs in Phase 1 reserve the namespace).
- Anymail event taxonomy — https://anymail.dev/en/stable/sending/tracking/ — locked in D-14 (project-level); Phase 4 consumes it.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

**None — greenfield repo.** The project root currently contains only `CLAUDE.md`, `.planning/`, and `prompts/`. No `lib/`, no `mix.exs`, no prior modules. Phase 1 creates the initial `mix.exs` + `lib/mailglass.ex` + the module set described in D-01..D-33.

### Established Patterns (inherited from prior libraries, not present in this repo)

The `prompts/mailglass-engineering-dna-from-prior-libs.md` distills patterns from four shipped libraries (accrue, lattice_stripe, sigra, scrypath). Phase 1 imports these patterns verbatim — they are established in the ecosystem, not in this working directory:

- **Named telemetry span helpers** (lattice_stripe pattern) — D-27.
- **Error struct per kind conforming to a narrow behaviour** (partial — Oban/Ecto sibling pattern + lattice_stripe protocol discipline) — D-01..D-09.
- **`Mailglass.Config` as the sole `Application.compile_env*` caller** (4-of-4 convergent across prior libs) — enforced by Phase 6 Credo.
- **Optional-dep gateway modules with `@compile {:no_warn_undefined, ...}` declared once** (4-of-4 convergent) — CORE-06.
- **`Repo.transact/1` Ecto.Multi wrapper** (accrue pattern) — scaffolded in Phase 1, used Phase 2+.

### Integration Points

- **New code connects via `mix.exs`** — first commit on Phase 1 creates the application. Required deps from `.planning/research/STACK.md`: `:ecto_sql`, `:postgrex`, `:phoenix`, `:swoosh`, `:nimble_options`, `:telemetry`, `:gettext`, `:premailex`, `:floki`, `:plug`. Optional deps: `:oban`, `:opentelemetry`, `:mjml`, `:gen_smtp`, `:sigra`.
- **`boundary` blocks** land in Phase 1 for every module delivered (per CORE-07). Blocks for modules created in later phases are added as those phases execute — no empty skeletons.
- **Reference implementations from the user's own prior libraries** (sibling projects at `~/projects/accrue`, `~/projects/lattice_stripe`, `~/projects/sigra`, `~/projects/scrypath`) — researcher and planner may read these directly to crib proven patterns when research flags a named analog.

</code_context>

<specifics>
## Specific Ideas

- **Error voice discipline.** Error messages are concrete, structured, composed. "Delivery blocked: recipient is on the suppression list" — not "Oops!" or "Something went wrong." Brand book locks this in `prompts/mailglass-brand-book.md`.
- **`<.button>` as the Surgical-VML flagship.** The bulletproof-button pattern (`<v:roundrect arcsize="..." fillcolor="..." strokecolor="..."><w:anchorlock/><center>...`) with `mso-hide:all` HTML fallback — copy verbatim from Campaign Monitor's buttons.cm pattern. This is the one component where VML complexity is justified because it's the one component that visibly breaks in classic Outlook without it.
- **Preheader as a first-class component, not a string.** `<.preheader text={...}/>` hidden with `display:none` + `max-height:0` + `overflow:hidden` + `mso-hide:all`, padded with repeated `&#8199;&#65279;&zwnj;` to push additional content out of Gmail's preview-pane pull. The preheader pattern is a known hack — ship it as a component so adopters don't have to get it right.
- **`data-mg-plaintext` strategy attribute.** The plaintext walker must know structure, not just text content. A custom walker (not `Floki.text/1`) keyed off `data-mg-plaintext="link_pair|text|heading_block|divider|skip"` produces readable plaintext from the logical component tree, then a terminal pass strips all `data-mg-*` from the HTML wire.
- **Theme map resolved via `:persistent_term`.** The theme is read on every render; `:persistent_term.get/1` is the right primitive — no ETS, no GenServer. Resolved at `Mailglass.Config.validate!/0` boot time.
- **Required `alt` on `<.img>` is the accessibility floor.** Decorative images pass `alt=""`. Omitting the attribute is a compile error. This is deliberate and opinionated.

</specifics>

<deferred>
## Deferred Ideas

- **Dark-mode theme variants** — deferred to v0.5 (D-13). Outlook.com partial-invert is unfixable without per-adopter tuning; light-mode-only v0.1 is a coherent product choice, not a gap.
- **`<.bare_button>` / primitive component set** — adopters who need fully custom shapes write raw HEEx tables. Re-evaluate at v0.5 if sufficient adopter friction surfaces.
- **MJML template engine `Mailglass.TemplateEngine.MJML`** — AUTHOR-05 defers implementation; Phase 1 ships the behaviour + HEEx default. Optional-dep-gated via `:mjml` Hex package (the Rust NIF — not `:mrml`). Phase 1 guide documents the opt-in, no implementation.
- **`Mailglass.OptionalDeps.OpenTelemetry.attach_otel/0` helper** — adopter-owned via `opentelemetry_telemetry` for v0.1 (D-32). Re-evaluate at v0.5 if friction warrants.
- **`tailwind-merge`-style class composition helper** — not shipped. Brand styles are inline, not Tailwind; the problem is meaningfully smaller in email context than in admin UI.
- **`telemetry_registry` for event discovery** — optional dep, not adopted; `@moduledoc` event catalog is sufficient for v0.1. Re-evaluate at v0.5 if multiple adopter integrations need programmatic discovery.
- **`Jason.Encoder` on `:cause` chain** — deliberately excluded (D-06); adopters walk via `Mailglass.Error.root_cause/1` if they need the chain serialized.

### Reviewed Todos (not folded)

None — no todos existed for Phase 1.

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-04-22*
