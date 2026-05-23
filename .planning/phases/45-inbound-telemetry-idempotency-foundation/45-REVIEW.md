---
phase: 45-inbound-telemetry-idempotency-foundation
reviewed: 2026-05-23T12:10:35Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - .credo.exs
  - credo_checks/no_pii_in_response_body.ex
  - credo_checks/stream_policy_consistent.ex
  - credo_checks/telemetry_event_convention.ex
  - lib/mailglass/optional_deps/gen_smtp.ex
  - test/mailglass/credo/checks_have_tests_test.exs
  - test/mailglass/credo/integration_test.exs
  - test/mailglass/credo/no_pii_in_response_body_test.exs
  - test/mailglass/credo/stream_policy_consistent_test.exs
  - test/mailglass/credo/telemetry_event_convention_test.exs
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 45: Code Review Report

**Reviewed:** 2026-05-23T12:10:35Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

> Scope note: this report covers **gap-closure round 2** (REQ TELE-06) — the 10
> files in the round-2 file list. It supersedes the earlier 17-file round-1 report
> that previously occupied this path.

## Summary

Round 2 broadened three custom Credo checks (`NoPiiInResponseBody`,
`StreamPolicyConsistent`, `TelemetryEventConvention`), registered
`StreamPolicyConsistent` in `.credo.exs`, added an "unregistered check" guard to
the `checks_have_tests` meta-test, refreshed the integration corpus to source
params live from `.credo.exs`, and added a doc-only clarification to
`OptionalDeps.GenSmtp`.

The work is functionally correct against the **current** codebase: all 93 tests
in `test/mailglass/credo/` pass, and `mix credo --strict` reports zero issues on
all 376 source files. Verified empirically:

- The meta-test correctly reconciles every `credo_checks/*.ex` against the live
  `.credo.exs` registration; `StreamPolicyConsistent` is registered exactly once,
  and `flatten_checks/1` does not mis-trigger the `:enabled/:extra/:disabled`
  grouping branch on the module-keyed list.
- The `.credo.exs` "WR-04 correction" comment is accurate:
  `NoBareOptionalDepReference.root_module/1` returns `Module.concat([root])` from
  the literal first alias segment and does NOT resolve aliases, so the `GenSmtp`
  map key is genuinely vestigial and CR-01 coverage rides on the
  `:mimemail`/`:gen_smtp_client` atom keys as documented. No coverage regression.
- The `GenSmtp.available?/0` doc addition is accurate
  (`Code.ensure_loaded?(:gen_smtp_client)` returns a boolean for the Erlang atom).
  The gen_smtp.ex change is doc-only with no behavioral impact.

The findings below are **soundness/robustness gaps in the new lint logic**, not
current breakage. Two newly-added rules over-match on plausible *future* code
shapes and would emit false positives that break `mix credo --strict` (exit 16).
They are WARNING (not BLOCKER) because they do not fire on today's code — but for
guard code whose entire purpose is precision, false positives erode trust and
invite blanket suppression, the exact "inert guard" failure this phase set out to
eliminate. All findings were reproduced against the shipped check modules.

## Warnings

### WR-01: `bare_body_variable_leak?` flags ANY bare body variable, not just error/PII terms

**File:** `credo_checks/no_pii_in_response_body.ex:192-208`

**Issue:** The mandated bare-variable rule treats the last positional arg of a
sink call as a leak whenever it is a bare local variable not in the
`jason_encoded_vars` carve-out. The ONLY carve-out is a variable bound to
`Jason.encode!/encode`. Every other bare body variable is flagged regardless of
its contents. Reproduced against the shipped module (filename
`lib/mailglass/webhook/foo.ex`, in scope):

```elixir
# FALSE POSITIVE — closed-code map hoisted into a var, then passed bare:
def run(conn) do
  body = %{status: "ok"}
  send_resp(conn, 200, body)       # flagged (1 issue) — no PII present
end

# FALSE POSITIVE — a plain string ID in body position:
def run(conn, message_id) do
  send_resp(conn, 200, message_id) # flagged (1 issue) — no PII present
end
```

The moduledoc (lines 56-65) claims "a static map/binary literal is not a bare
variable, so the legitimate closed-code body stays clean" — but that only holds
when the closed code is written *inline*. The instant a maintainer hoists a
static map into a local for readability (or returns a message-id string), the
rule fires. That is precisely the documented-safe shape (return a static body,
route detail to telemetry) being penalized.

It is clean today only because every current sink call in
`lib/mailglass/webhook/plug.ex` and
`mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` uses an inline literal
(`""`, `%{...}`) or the carved-out `body = Jason.encode!(payload)`.

**Fix:** Narrow the body-variable rule to fire only when the body variable name is
plausibly an error/PII term — reuse the `suspicious_fragments` substring match for
the body-position variable (catching `reason`/`changeset`/`err`, and add
`payload` so WR-03's two-step shape still trips) instead of flagging every
non-Jason bare variable. Legitimate `body`/`message_id`/`resp` locals then stop
tripping. If the broad rule is intentional, at minimum widen the carve-out beyond
Jason to any variable bound to a literal map/binary so hoisted closed-code bodies
stay clean.

### WR-02: `span_wrapper_name?` over-matches any `"span"`-prefixed function name

**File:** `credo_checks/telemetry_event_convention.ex:168-170` (used by the two
new `walk/5` clauses at lines 126-160)

**Issue:** A telemetry span wrapper is identified by
`String.starts_with?(Atom.to_string(fn_name), "span")`. This matches far more
than `span` / `span_with_enrichment`: `spanish_words`, `span_count`, `spanner`,
`spans`, etc. Any function whose name starts with the four letters "span", called
with a literal atom-list first arg and ≥2 args, is validated as a telemetry event
and flagged if its root is not `:mailglass`. Reproduced against the shipped
module (configured params `[:mailglass, :mailglass_inbound]`, min 4):

```elixir
spanish_words([:hola, :mundo, :foo], %{}, fn -> :ok end)  # FALSE POSITIVE (1 issue)
span([:col, :start], %{}, [])                             # FALSE POSITIVE (1 issue)
```

The check is path-scoped to the whole `lib/` and `test/` tree, so any unrelated
`span`-prefixed function taking a literal atom list anywhere becomes a false
positive that breaks `mix credo --strict`. Latent today (no such function
exists), but the matcher is broader than the documented intent ("`span` or
`span_*`"), and the in-code comment (lines 164-167) itself describes the narrower
intent the code does not enforce.

**Fix:** Match the wrapper name with an underscore boundary (or an explicit
allowlist) instead of a bare prefix:

```elixir
defp span_wrapper_name?(fn_name) when is_atom(fn_name) do
  name = Atom.to_string(fn_name)
  name == "span" or String.starts_with?(name, "span_")
end
```

This still covers `span_with_enrichment` while rejecting
`spanish_words`/`spanner`.

### WR-03: `def_head?` exclusion suppresses real leaks when a def head and call share a line

**File:** `credo_checks/no_pii_in_response_body.ex:210-212` (with
`collect_def_head_sigs/2` at 243-268)

**Issue:** Function-definition heads colliding with a sink name are excluded from
the bare-variable rule by recording `{name, line}` and skipping any call-shaped
node with a matching name+line. Because the exclusion key is the *line number*
(not AST node identity), a single-line function definition that also calls a
same-named sink on that line suppresses the genuine call too. Reproduced against
the shipped module (in-scope filename):

```elixir
# def head AND call both on line 2 -> def_head_sigs holds {:send_resp, 2},
# so the real recursive call is ALSO excluded -> 0 issues (leak missed):
def send_resp(conn, status, body), do: send_resp(conn, status, body)
```

An edge case (a local function shadowing a Plug sink name and calling it on one
physical line), but a soundness hole in a security guard: the exclusion is meant
to distinguish a definition from a call and fails when both share a line.
Multi-line and multi-clause definitions are handled correctly (verified: a
separate-line leak call is still flagged).

**Fix:** Distinguish the def head from call sites structurally rather than by line
number — match the `{:def/:defp, _, [head | _]}` wrapper during the postwalk and
skip only that inner head node by identity, or carry a definition flag, so a call
on the same line as its definition is not collaterally excluded.

### WR-04: `contains_inspect?` matches any local function named `inspect`, not only Kernel.inspect

**File:** `credo_checks/no_pii_in_response_body.ex:270-283`

**Issue:** `contains_inspect?/1` flags any bare `{:inspect, _, [_ | _]}` call as a
PII leak, keying purely on the atom `:inspect`. This is correct for
`Kernel.inspect/1,2`, but it also matches an unrelated project-local `inspect/n`
helper that has nothing to do with rendering a term. Within the narrow
webhook+ingress scope this is unlikely, but the matcher makes no attempt to
confirm the call resolves to `Kernel.inspect`. The qualified `Kernel.inspect(...)`
form is handled; the bare form trusts the name alone.

Lower severity than WR-01/WR-02 (tiny scope; a local function named `inspect` is
rare), but recorded because the same name-only, no-resolution assumption underlies
WR-01/WR-02 — this check family consistently trades precision for simplicity, and
that posture should be visible.

**Fix:** Either accept the trade-off and document the name-collision boundary in
the moduledoc "Boundary" section (which today documents only the multi-hop
dataflow boundary), or scope the bare-`inspect` match out should a local
`inspect/n` ever land in the webhook/ingress namespaces. No code change strictly
required if documented alongside the other boundaries.

## Info

### IN-01: `dangerous_body?` re-walks every argument's full subtree three times per sink call

**File:** `credo_checks/no_pii_in_response_body.ex:169-184`

**Issue:** For each sink call, `dangerous_body?` runs `contains_inspect?`,
`contains_changeset_literal?`, and `contains_bare_error_variable?` over every
argument, and each does its own independent `Macro.prewalk` over the arg subtree —
three full prewalks per arg, no short-circuit. Lint-time only (not a runtime perf
issue, out of v1 scope as perf); noted for maintainability.

**Fix:** If touched later, fold the three structural predicates into one
`Macro.prewalk` per body arg with an early-exit accumulator.

### IN-02: Two near-identical `walk/5` span-wrapper clauses differ only in call shape

**File:** `credo_checks/telemetry_event_convention.ex:126-142` and `144-160`

**Issue:** The bare-local-call clause and the qualified-remote-call clause have
identical bodies (same `span_wrapper_name?` guard, same `validate(...)` call,
same `threshold: min_segments - 1`); only the binding pattern differs. Acceptable
for AST clauses, but a shared helper would remove ~15 duplicated lines and prevent
the two forms from drifting.

**Fix:** Extract the shared body to a private `validate_span_wrapper/7` invoked
from both clauses after destructuring. Optional.

### IN-03: `flatten_checks/1` config-normalization helper is duplicated across test files

**File:** `test/mailglass/credo/checks_have_tests_test.exs:78-88` (also in
`test/mailglass/credo/integration_test.exs:366-376`, and per its own comment in
`credo_config_sentinel_test.exs`)

**Issue:** The `:checks` normalization helper is copied verbatim into at least
three test files; the comments explicitly state they "must stay consistent" /
"cannot drift" — a manual invariant enforced only by reviewer diligence. A change
to the `.credo.exs` `:checks` shape would require updating all copies in lockstep.

**Fix:** Extract `flatten_checks/1` (plus the shared `registered_check_modules` /
`load_checks` shape) into a `test/support/` helper and import it, collapsing the
drift surface to a single definition.

---

_Reviewed: 2026-05-23T12:10:35Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
