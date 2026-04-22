---
phase: 01-foundation
reviewed: 2026-04-22T16:10:00Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - mix.exs
  - config/config.exs
  - config/dev.exs
  - config/test.exs
  - config/prod.exs
  - config/runtime.exs
  - lib/mailglass.ex
  - lib/mailglass/application.ex
  - lib/mailglass/error.ex
  - lib/mailglass/errors/send_error.ex
  - lib/mailglass/errors/template_error.ex
  - lib/mailglass/errors/signature_error.ex
  - lib/mailglass/errors/suppressed_error.ex
  - lib/mailglass/errors/rate_limit_error.ex
  - lib/mailglass/errors/config_error.ex
  - lib/mailglass/config.ex
  - lib/mailglass/telemetry.ex
  - lib/mailglass/repo.ex
  - lib/mailglass/idempotency_key.ex
  - lib/mailglass/message.ex
  - lib/mailglass/optional_deps.ex
  - lib/mailglass/optional_deps/oban.ex
  - lib/mailglass/optional_deps/opentelemetry.ex
  - lib/mailglass/optional_deps/mjml.ex
  - lib/mailglass/optional_deps/gen_smtp.ex
  - lib/mailglass/optional_deps/sigra.ex
  - lib/mailglass/components.ex
  - lib/mailglass/components/theme.ex
  - lib/mailglass/components/css.ex
  - lib/mailglass/components/layout.ex
  - lib/mailglass/template_engine.ex
  - lib/mailglass/template_engine/heex.ex
  - lib/mailglass/renderer.ex
  - lib/mailglass/compliance.ex
  - lib/mailglass/gettext.ex
  - docs/api_stability.md
  - test/support/fixtures.ex
  - test/support/mocks.ex
  - test/test_helper.exs
  - test/mailglass/renderer_test.exs
  - test/mailglass/compliance_test.exs
  - test/mailglass/telemetry_test.exs
findings:
  critical: 0
  high: 0
  medium: 2
  low: 6
  total: 8
status: issues_found
---

# Phase 01-foundation: Code Review Report

**Reviewed:** 2026-04-22T16:10:00Z
**Depth:** standard
**Files Reviewed:** 41 (source + tests + config + fixtures)
**Status:** issues_found (2 medium, 6 low — no critical or high-severity findings)

## Summary

Phase 1 lands a thoughtful, well-documented foundation layer: six defexception
modules with the closed `:type` contract, Config with NimbleOptions + persistent_term
theme, 4-level telemetry with the D-31 metadata whitelist, the HEEx component set
with surgical VML, and a clean pure-function Renderer pipeline that respects the
D-15 plaintext-before-inlining ordering.

The critical security invariants are intact:

- **T-PII-001 (telemetry whitelist):** Renderer emits only `%{tenant_id, mailable}` —
  both whitelisted. The StreamData property test runs 1000 checks per run.
- **T-PII-002 (Jason.Encoder `:cause` exclusion):** all six error modules derive
  `Jason.Encoder` with `only: [:type, :message, :context]`. `:cause` and per-kind
  fields (`:delivery_id`, `:provider`, `:retry_after_ms`) are deliberately
  excluded.
- **T-IDEMP-001 (idempotency key sanitization):** control chars, DEL, and non-ASCII
  are stripped; 512-byte cap applied. Doctest covers 0x00 case.
- **T-HANDLER-001 (telemetry handler isolation):** implicitly satisfied via
  `:telemetry.span/3`; regression test captures the library's auto-detach log.
- **D-14 (VML preservation):** golden-fixture test guards Premailex regressions.
- **D-22 (`data-mg-*` strip):** the terminal regex pass runs after inlining;
  tests assert strip completeness.
- **D-15 (plaintext pre-VML):** `to_plaintext` runs on pre-inlined HTML;
  `{:comment, _}` node handler in the walker skips MSO conditional blocks.
- **COMP-01 / COMP-02 (RFC headers):** Date (RFC 2822), Message-ID (128-bit hex),
  MIME-Version, Mailglass-Mailable — all injected only when absent, never
  overwritten. Elixir. prefix stripped from module names.
- **CORE-06 (optional-dep gateway):** all five gateways use
  `Code.ensure_loaded?/1` + `@compile {:no_warn_undefined, ...}`; Sigra is
  conditionally compiled.
- **Config as sole `Application.compile_env*` caller:** verified — `grep -n
  compile_env lib/` returns zero matches outside `config.ex`'s moduledoc
  reference. All runtime reads go through `Application.get_env`.

The findings below are quality and correctness observations, not security holes.
Two medium findings concern idempotency-key collision shapes that will matter
when Phase 4's webhook ingest path goes live. Six lows are polish items
— an API-doc drift, a theme-cache-unset fallback subtlety, a brittle use of
Phoenix internals, and similar.

## Medium

### MD-01: IdempotencyKey namespace-disjointness claim is not guaranteed when `event_id` contains `:msg:`

**File:** `lib/mailglass/idempotency_key.ex:10-14` (moduledoc claim) / `lib/mailglass/idempotency_key.ex:44-48` (implementation)
**Issue:** The moduledoc states "The `msg:` infix on provider-message-id keys keeps the two namespaces disjoint so a webhook event id and a provider message id that happen to share a string value never collide." However, `for_webhook_event/2` interpolates `event_id` unsanitized into `"#{provider}:#{event_id}"` — if a provider's webhook `event_id` is literally `"msg:abc"`, the resulting key is `"postmark:msg:abc"`, which is indistinguishable from `for_provider_message_id(:postmark, "abc")` → `"postmark:msg:abc"`. Same issue applies to `event_id` values containing unescaped `:` — the b-tree UNIQUE partial index cannot distinguish `for_webhook_event(:postmark, "foo:bar")` from `for_webhook_event(:postmark, "foo")` called with some other structure.

Real-world risk is low today (no provider ships `event_id` values with `msg:` prefixes or embedded `:` as of 2026 — Postmark/SendGrid/Mailgun all use opaque alphanumeric IDs). But the claim in the moduledoc is stronger than the implementation provides, and the contract shapes Phase 4 webhook dedupe. A provider change down the line could introduce silent collisions.

**Fix:** One of:

1. **Document the precondition** by tightening the moduledoc: "Provider event IDs must not contain the literal substring `msg:` or unescaped `:`. In practice this holds for all providers mailglass supports." This is the smallest change.
2. **Escape the separator** — e.g., percent-encode `:` inside the input strings before interpolation: `event_id |> String.replace(":", "%3A")`. Loses human-readability of keys but eliminates the collision shape entirely.
3. **Reserve a non-printable separator** — use `\x1F` (unit separator, an ASCII control char) between provider and id, which the sanitizer then strips. But sanitize strips `\x1F` so this doesn't work with the current pipeline. Would require restructuring sanitize to apply per-component.

Recommendation: pick (1) for Phase 1 (tighten the doc) and revisit in Phase 4 when the webhook ingest path actually builds these keys. Open a `.planning/FUTURE.md` entry tracking the hardening.

### MD-02: Renderer wraps error results inside `render_span`, so `:exception` telemetry never fires for error returns

**File:** `lib/mailglass/renderer.ex:63-85`
**Issue:** `Mailglass.Renderer.render/2` wraps the entire pipeline in
`Telemetry.render_span(metadata, fn -> ... end)`. The inner function returns
`{:ok, %Message{}}` or `{:error, %TemplateError{}}`. Because `render_span`
only delegates to `:telemetry.span/3`, and `:telemetry.span/3` only emits
`:exception` when the function **raises** (not when it returns an error tuple),
a `{:error, %TemplateError{type: :inliner_failed}}` return path emits a normal
`:stop` event with no indication that the render failed. Operators
monitoring `[:mailglass, :render, :message, :exception]` will miss every
template/inliner failure. The `:stop` metadata carries `%{tenant_id, mailable}`
only — no `:status` field to distinguish success from error.

This is not a security issue, and the current tests assert shape only (not
exception-vs-stop branching), so the suite stays green. But it degrades
observability at a Phase 1 emit site that Phase 5's preview LiveView will
consume for timing indicators.

**Fix:** Either (a) add `:status` to the whitelist and thread `:ok | :error`
through the stop metadata:

```elixir
Telemetry.render_span(metadata, fn ->
  case do_render(message, opts) do
    {:ok, rendered} -> {result, Map.put(metadata, :status, :ok)}
    {:error, _} = err -> {err, Map.put(metadata, :status, :error)}
  end
end)
```

Requires `Mailglass.Telemetry.span/3` to accept a `{result, updated_metadata}`
return shape from the inner fn (the helper currently discards any caller
override by re-passing the original `metadata`). Or (b) document the contract:
`:exception` fires only on raise; error-tuple returns show up as `:stop`
events, and observability of the error payload is the caller's responsibility.
`:status` as a whitelisted key already exists in D-31, so (a) is the cleaner
option.

## Low

### LO-01: `docs/api_stability.md` is out of date for `RateLimitError.retry_after_ms` default

**File:** `docs/api_stability.md:102`
**Issue:** The doc says `retry_after_ms :: non_neg_integer()` (default `0`). The
implementation matches, but the module's `new/2` accepts `:retry_after_ms` as a
top-level opt **in addition to** reading it from `:context.retry_after_ms` for
message formatting. That dual-entry behaviour (documented in the 01-02 SUMMARY
Decisions) is not mentioned in `api_stability.md` — adopters reading the stability
doc see only the struct field, not the builder option. Minor documentation drift.

**Fix:** In `docs/api_stability.md` under `Mailglass.RateLimitError`, add a
sentence: "The builder `RateLimitError.new/2` accepts `:retry_after_ms` as a
top-level option; it populates the struct field and, when also present in
`:context`, is used for message formatting." One line, no behaviour change.

### LO-02: `Mailglass.Components.Theme.color/1` silently returns Glass (`#277B96`) for every known token when the cache is empty

**File:** `lib/mailglass/components/theme.ex:30-42`
**Issue:** When `Mailglass.Config.validate_at_boot!/0` has NOT been called,
`Mailglass.Config.get_theme/0` returns `[]`, so `Theme.color(:ink)` returns
the default `#277B96` (Glass) instead of the actual ink value (`#0D1B2A`).
Headings in a never-booted environment render teal instead of navy. The
moduledoc does say "unknown tokens fall back to sensible defaults" — but `:ink`
is NOT an unknown token; it's a canonical brand token. The fallback applies
uniformly to empty/unset caches, which produces visually wrong (but
structurally valid) output.

Realistically, every production path calls `validate_at_boot!/0` via
`Mailglass.Application.start/2`, and `RendererTest` calls it in its setup block.
But the fallback is easy to mis-read as "my ink heading is broken" during
development when a test forgot to call the validator.

**Fix:** Consider making `Theme.color/1` raise a helpful `Mailglass.ConfigError`
when the cache is empty AND the token is a known brand token (`:ink`, `:glass`,
`:ice`, `:mist`, `:paper`, `:slate`). Unknown tokens still fall back to Glass.
This turns a silent-wrong-color into a loud misconfig error, matching the
project's fail-fast posture. Alternatively, ship the brand defaults as a
module attribute and return them directly when the cache is empty — still
silent but at least returns the right color.

### LO-03: `render_slot_to_binary/2` depends on `Phoenix.Component.__render_slot__/3`, a private API

**File:** `lib/mailglass/components.ex:386-390`
**Issue:** The helper calls `Phoenix.Component.__render_slot__/3` directly
— the double-underscore prefix indicates private-by-convention internals.
Phoenix.LiveView upgrades are free to change this signature or remove it. The
current usage is documented in the code and in the 01-05 SUMMARY, and the
public `render_slot/2` macro cannot be used here because it requires `~H`
context. This is a real constraint of the VML-conditional-comment workaround.

**Fix:** Leave it in place but add a compile-time guard so a Phoenix upgrade
that breaks the reference fails loudly with an actionable message:

```elixir
# At module level, outside any function:
unless function_exported?(Phoenix.Component, :__render_slot__, 3) do
  raise "Phoenix.Component.__render_slot__/3 is unavailable — " <>
        "Mailglass.Components.button relies on this internal helper " <>
        "(see render_slot_to_binary/2). Phoenix.LiveView upgrade may have " <>
        "renamed or removed the function."
end
```

Alternatively, add an entry to `.planning/PITFALLS.md` (or wherever Phase 1
tracks follow-up debt) so a future Phoenix bump surfaces this as a known hot
spot to regress-test first.

### LO-04: Renderer's HEEx path passes empty assigns (`%{}`) — adopter-supplied assigns have no in-phase entry point

**File:** `lib/mailglass/renderer.ex:91`
**Issue:** `HEEx.render(fun, %{}, opts)` always passes `%{}` as assigns. This
works for self-contained function components (the adopter closes over their
data inside `fn assigns -> ~H"..." end`), but there is no way to pass a
separate `assigns` map from `Renderer.render/2` down to the HEEx engine. This
is a Phase 1 constraint — Phase 3 `Mailglass.Mailable` will likely want to
thread assigns explicitly — but it is not signposted in the Renderer moduledoc
or in `docs/api_stability.md`.

**Fix:** One-line Renderer moduledoc note: "Phase 1 callers must build
self-contained function components (closing over their data). Phase 3's
`Mailglass.Mailable` introduces an assigns-threading convention." Prevents
adopters from assuming they can pass an assigns map through `render/2`.

### LO-05: `Mailglass.Error.is_error?/1` violates Elixir naming convention (already in known-gaps list)

**File:** `lib/mailglass/error.ex:75`
**Issue:** Acknowledged in the task prompt as a known deferred lint gap
(LINT-06 Phase 6 lands Credo). Re-flagging here only so the review artifact
is complete. The guideline is: predicates that are NOT guards use a `?`
suffix alone (`error?/1`), and guard-safe predicates use the `is_*` prefix
(no `?`). The current name `is_error?/1` combines both and flags under
`mix credo --strict`.

**Fix:** Defer per prompt (Phase 6 Credo touchup). When touched, rename to
`error?/1` with a `@deprecated "Use error?/1 instead"` alias preserving the
current name for one minor version. Same rename convention prior libraries
used (accrue had this exact transition documented).

### LO-06: `Mailglass.Application.maybe_warn_missing_oban/0` fires a `Logger.warning` at boot in environments without Oban, even when the adopter does not use `deliver_later`

**File:** `lib/mailglass/application.ex:26-34`
**Issue:** Any boot without Oban loaded produces a Logger warning referring to
`deliver_later/2` — a function that does not exist yet (lands Phase 3). Adopters
who run Phase 1 mailglass (today) as a dependency will see a warning about a
feature that is not yet wired, which is confusing. The warning is fired
unconditionally whenever Oban is absent — not only when `deliver_later` is
actually called.

**Fix:** Either (a) gate the warning behind `Mix.env() == :prod` so it only
fires in production (dev/test boots stay silent); or (b) defer the warning
emission until Phase 3 lands `deliver_later/2` and the fallback-to-Task.Supervisor
path actually exists. Recommendation: (b) — remove the warning function from
`Application.start/2` for Phase 1 and re-introduce it in Phase 3 alongside the
function it warns about. Keeps the noise aligned with functionality.

---

_Reviewed: 2026-04-22T16:10:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
