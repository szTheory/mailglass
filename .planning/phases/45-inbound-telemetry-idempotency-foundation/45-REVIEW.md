---
phase: 45-inbound-telemetry-idempotency-foundation
reviewed: 2026-05-23T12:30:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - .credo.exs
  - .github/workflows/ci.yml
  - credo_checks/no_pii_in_response_body.ex
  - credo_checks/telemetry_event_convention.ex
  - lib/mailglass/optional_deps/gen_smtp.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
  - mailglass_inbound/lib/mailglass_inbound/mime.ex
  - mailglass_inbound/mix.exs
  - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
  - mailglass_inbound/test/mailglass_inbound/mime_test.exs
  - test/mailglass/credo/checks_have_tests_test.exs
  - test/mailglass/credo/credo_config_sentinel_test.exs
  - test/mailglass/credo/no_bare_optional_dep_reference_test.exs
  - test/mailglass/credo/no_pii_in_response_body_test.exs
  - test/mailglass/credo/require_atomic_unsubscribe_headers_test.exs
  - test/mailglass/credo/stream_policy_consistent_test.exs
  - test/mailglass/credo/telemetry_event_convention_test.exs
findings:
  critical: 1
  warning: 5
  info: 2
  total: 8
status: issues_found
---

# Phase 45: Code Review Report

**Reviewed:** 2026-05-23T12:30:00Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

Phase 45 is a gap-closure cycle that closes a prior review's CR-01 (inert
`NoBareOptionalDepReference`), WR-02 (`TelemetryEventConvention` missing
`:telemetry.span/3`), WR-03 (missing inbound `--no-optional-deps` CI lane),
the inbound plug PII-egress leak, and two doc-honesty Info items.

The headline fixes are mostly sound and verified empirically:

- **CR-01 is genuinely fixed.** The `:mimemail` / `:gen_smtp_client` atom keys
  in `.credo.exs gated_modules` make `NoBareOptionalDepReference` fire on a bare
  `:mimemail.decode(...)` call (confirmed by running the check). The config
  sentinel and behavior tests pin both layers.
- **The plug.ex PII-egress fix is correct for the actual code path.** The persist
  failure branch returns a static `%{status: "error", reason: "persist_failed"}`
  body, keeps status 500 (correct retry signal for all four providers), and routes
  detail to PII-free telemetry. The new `log_persist_failure/1` logs only
  changeset *field names* via `traverse_errors`, never `changes` values.
- **The doc-honesty corrections are accurate.** The gen_smtp `:undef` taxonomy
  (a class-`:error` caught by `rescue`, not `catch :exit`) and the `:max_depth`
  "not a DoS defense" caveat are both factually correct improvements.

The five changed-Credo test suites and the core test run pass (25 tests, 0
failures in the changed checks). However, adversarial probing surfaced one defect
of the *same class this phase exists to eliminate*, plus several guards whose new
tests certify coverage the guards do not actually deliver:

1. **A second inert Credo guard ships unregistered** (`StreamPolicyConsistent`) —
   defined, now tested (added this phase), but never wired into `.credo.exs`, so
   `mix credo` never runs it. This is the exact CR-01 defect family, and the new
   test masks it.
2. **The WR-02 span clause never fires on real inbound code.** Every inbound
   telemetry event name is routed through a wrapper whose `:telemetry.span` call
   takes a *variable* prefix, so the convention check (which only matches literal
   atom lists) is inert against the package it was widened to cover.
3. **`NoPiiInResponseBody` has real false negatives** for the most likely future
   regression shapes (a changeset variable not named `reason`/`changeset`, and a
   payload assembled in a prior variable).
4. **The `.credo.exs` rationale comment for the retained `GenSmtp` alias key is
   factually wrong** about why that key is load-bearing.

None of the false-negative gaps is an *active* PII leak — current production code
is clean — so they are WARNING, not BLOCKER. The inert `StreamPolicyConsistent`
guard is classified BLOCKER because it is a never-running safety check whose new
test falsely certifies enforcement, which is precisely the failure mode this
gap-closure phase was chartered to close.

## Critical Issues

### CR-01: `StreamPolicyConsistent` is a registered-nowhere, never-run safety guard — and this phase added a test that falsely certifies it

**File:** `test/mailglass/credo/stream_policy_consistent_test.exs:1-52`, `credo_checks/stream_policy_consistent.ex:1-111`, `.credo.exs:1-107`

**Issue:**
`credo_checks/stream_policy_consistent.ex` defines `Mailglass.Credo.StreamPolicyConsistent`,
a real guard enforcing "tracking-enabled mailables must declare an explicit
`:bulk`/`:operational` stream" — directly adjacent to the CLAUDE.md
open/click-tracking discipline. It is **not registered in `.credo.exs`** (it never
has been — `git log -S StreamPolicyConsistent -- .credo.exs` is empty), so
`mix credo --strict` never executes it. The check is inert config: defined,
tested, never run.

This phase's commit `258644c test(45-09): cover the two pre-existing uncovered
Credo checks` added `stream_policy_consistent_test.exs` to satisfy the
`checks_have_tests_test` meta-guard. The test passes against hand-passed params,
so it gives a green check that *implies* the stream-policy rule is enforced when
it is not. This is the identical "claimed-but-inert guard" defect class as the
CR-01 this phase is closing — and the meta-guard has a blind spot that lets it
through: `checks_have_tests_test.exs:18` asserts only that a test *file exists*,
never that the check is *registered in `.credo.exs`*.

Verified empirically: 17 files in `credo_checks/*.ex`, but only 16 modules appear
in `.credo.exs`; the missing one is `Mailglass.Credo.StreamPolicyConsistent`.

(Supporting context, out of file scope: `test/mailglass/credo/integration_test.exs`
keeps a *duplicate, now-stale* hardcoded `@extra_checks` list that also omits
`StreamPolicyConsistent` and still carries the pre-CR-01 / pre-WR-02 params —
`required_root: :mailglass` singular and no `:mimemail` key. It cannot catch this
drift.)

**Fix:**
Register the check in `.credo.exs extra_checks` so it actually runs:

```elixir
# .credo.exs — add to extra_checks
{Mailglass.Credo.StreamPolicyConsistent, []},
```

Then close the meta-guard blind spot so an unregistered check fails CI instead of
passing on test-existence alone. Extend `checks_have_tests_test.exs` (or add a
companion to `credo_config_sentinel_test.exs`) to assert every `credo_checks/*.ex`
module is present in the shipped `.credo.exs` checks list:

```elixir
test "every custom Credo check is registered in .credo.exs" do
  {config, _} = Code.eval_file(".credo.exs")

  registered =
    config.configs
    |> hd()
    |> Map.fetch!(:checks)
    |> Enum.map(fn
      {mod, _params} -> mod
      mod when is_atom(mod) -> mod
    end)
    |> MapSet.new()

  defined =
    "credo_checks/*.ex"
    |> Path.wildcard()
    |> Enum.map(fn p ->
      Module.concat([Mailglass, Credo, Macro.camelize(Path.basename(p, ".ex"))])
    end)

  unregistered = Enum.reject(defined, &MapSet.member?(registered, &1))
  assert unregistered == [], "Defined-but-unregistered Credo checks: #{inspect(unregistered)}"
end
```

## Warnings

### WR-01: WR-02's `:telemetry.span/3` clause never fires on real inbound code — the package it was widened to cover is uncovered

**File:** `credo_checks/telemetry_event_convention.ex:52-63`, `.credo.exs:66-67`

**Issue:**
The new span-aware clause is correct in isolation (a literal
`:telemetry.span([:wrong_app, :x], ...)` is flagged; a 3-segment
`[:mailglass_inbound, :ingress, :request]` prefix passes — both verified). But
**every** real telemetry emission in both packages routes the literal event name
through a wrapper before reaching `:telemetry.span`. In
`mailglass_inbound/lib/mailglass_inbound/telemetry.ex:135-136`:

```elixir
defp span(event_prefix, metadata, fun) do
  :telemetry.span(event_prefix, metadata, fn -> ... end)   # event_prefix is a VARIABLE
end
```

The literal lists live in the named helpers (`span([:mailglass_inbound, :persist,
:record], ...)`), which call the *private* `span/3`, not `:telemetry.span`. The
check's `literal_atom_list/1` returns `:error` for a variable, so the clause is a
no-op against production. Confirmed: `grep ':telemetry\.\(span\|execute\)(\[:'`
over `lib/` and `mailglass_inbound/lib/` returns zero matches, and running the
check over the real `telemetry.ex` produces 0 issues. WR-02 therefore adds test
coverage for a code shape that does not exist in the codebase while leaving the
inbound event names it targets unvalidated. (The pre-existing `:telemetry.execute`
clause shares this limitation; WR-02 inherits rather than introduces it, but the
WR-02 charter — "cover the inbound sibling package's events" — is not met.)

**Fix:**
Either (a) document explicitly that the check only guards *direct literal* call
sites and is a tripwire for accidental bare `:telemetry.*` use, not a verifier of
the wrapper-routed event names; or (b) extend the check to also validate literal
atom-list arguments passed to the package's own span wrappers at their definition
site (`MailglassInbound.Telemetry.*_span`, `Mailglass.Webhook.Telemetry.*_span`),
where the event name *is* a literal. Option (b) is the only one that actually
closes WR-02.

### WR-02: `NoPiiInResponseBody` misses a changeset variable not named `reason`/`changeset`

**File:** `credo_checks/no_pii_in_response_body.ex:125-183`

**Issue:**
`dangerous_body?/2` flags an arg only if it contains `inspect(...)`, an
`%Ecto.Changeset{}` *literal*, or a *variable whose name* contains `reason`/
`changeset`. A raw changeset (or any PII-bearing error term) bound to a
differently-named variable escapes all three. Verified by running the check:

```elixir
send_json(conn, 500, %{status: "error", detail: err})   # `err` holds a changeset → 0 issues
```

The real-world leak vector is an error *variable*, and developers routinely name
it `e`, `err`, `error`, or `result`. Today's code is clean, so this is a latent
gap that would let a future regression of this shape ship undetected — directly
undermining the "No PII on egress" invariant the check exists to enforce.

**Fix:**
Broaden `suspicious_fragments` to cover the common error-variable names
(`["reason", "changeset", "error", "err"]`), and/or treat any *bare local
variable* (not a literal, not a static map/binary) appearing directly as a
response-body arg as suspicious on these two narrow egress surfaces — the
documented-safe shape is a static map/binary or a JSON-encoded `body`, both of
which are distinguishable from a bare error var. Add a regression test mirroring
`plug_test.exs:200` but with the error bound to `err`.

### WR-03: `NoPiiInResponseBody` misses a payload assembled in a prior variable

**File:** `credo_checks/no_pii_in_response_body.ex:105-131`

**Issue:**
The check only inspects the AST *inside the sink call's args*. A two-step
construction defeats it because the `inspect`/changeset lives in a separate `=`
assignment node, not within the sink call:

```elixir
payload = %{status: "error", detail: inspect(changeset)}
send_json(conn, 500, payload)            # arg is just `payload` → 0 issues (verified)
```

The current plug.ex inlines the map, so no active leak; but this is the obvious
refactor a future maintainer would make, and it would silently bypass the guard.

**Fix:**
This is the harder structural case (intra-function dataflow). At minimum,
document the limitation in the check's `@explanations` so reviewers know the
guard assumes inline construction. A pragmatic mitigation: flag a bare-variable
sink arg (per WR-02's fix) on these surfaces, which catches `send_json(conn, 500,
payload)` regardless of how `payload` was built. The legitimate `send_json`
helper's internal `send_resp(status, body)` would need to stay excluded — its
`body` is a Jason-encoded binary, already carved out per the design note at
lines 11-17; verify any broadened rule keeps that case green.

### WR-04: `.credo.exs` rationale for the retained `GenSmtp` alias key is factually incorrect

**File:** `.credo.exs:36-39`

**Issue:**
The comment claims the `GenSmtp` map key is "retained because inbound `mime.ex`
reaches the gateway via `alias Mailglass.OptionalDeps.GenSmtp, as: OptionalGenSmtp`,
whose call root resolves to the `GenSmtp` alias — that path must keep passing."
This is wrong. Credo operates on raw AST and does not resolve aliases. The call
`OptionalGenSmtp.decode(raw)` resolves to root `OptionalGenSmtp`, which is **not**
a key in `gated_modules` at all — so the call passes by *missing the map
entirely*, not by matching the `GenSmtp` key. Verified empirically: the aliased
call yields 0 issues, and a bare `GenSmtp.decode(...)` (a module that does not
even exist — gen_smtp is the Erlang `:gen_smtp`) is what the `GenSmtp` key
actually matches. The `GenSmtp` alias key is therefore effectively dead for every
real call site; the CR-01 fix rides entirely on the `:mimemail` /
`:gen_smtp_client` atom keys.

A future maintainer trusting this comment could "fix" a perceived gap by
renaming the alias to `GenSmtp` (re-introducing the original inert-key bug) or
remove the atom keys believing the alias key covers mime.ex.

**Fix:**
Correct the comment to state the truth: the `GenSmtp` key matches only a literal
`GenSmtp.<fn>` call (which no Elixir code makes, since the dep is the Erlang
`:gen_smtp`); the aliased `OptionalGenSmtp.decode/2` call passes because its root
is not gated; the live CR-01 coverage is the `:mimemail` / `:gen_smtp_client`
atom keys. Consider dropping the `GenSmtp` key (and the `Mjml`/`Sigra` analogues
if equally vestigial) unless a literal `GenSmtp.*` call site is expected.

### WR-05: `integration_test.exs` carries a stale, duplicated copy of `.credo.exs` check params (drift risk)

**File:** `.credo.exs:6-67` (in scope) vs `test/mailglass/credo/integration_test.exs:6-60` (out of direct scope; flagged because it weakens verification of the in-scope config)

**Issue:**
`integration_test.exs` hardcodes its own `@extra_checks` that has *not* been
updated for this phase: it still has `TelemetryEventConvention` with
`required_root: :mailglass` (singular, pre-WR-02) and `NoBareOptionalDepReference`
*without* the `:mimemail`/`:gen_smtp_client` atom keys (pre-CR-01). Because it is
a hand-maintained duplicate, it can neither detect nor protect against `.credo.exs`
drift, and it is now silently inconsistent with the shipped config that the
`credo_config_sentinel_test` pins. The sentinel test prevents *some* drift
(specific keys) but the integration test's stale copy will keep diverging and
exercises params that no longer match production.

**Fix:**
Have `integration_test.exs` load the real config via `Code.eval_file(".credo.exs")`
(as `credo_config_sentinel_test.exs:16` already does) instead of duplicating it,
so the integration run exercises the actual shipped params and cannot drift.

## Info

### IN-01: gen_smtp gateway `available?/0` and `decode/2` are gated by different modules

**File:** `lib/mailglass/optional_deps/gen_smtp.ex:51,77`

**Issue:**
`available?/0` checks `Code.ensure_loaded?(:gen_smtp_client)` while `decode/2`
calls `:mimemail.decode/2`. These are two distinct modules from the same Hex
package. In a partial/corrupt install where `:gen_smtp_client` loads but
`:mimemail` does not, `available?/0` returns `true` and `decode/2` hits the
`:undef` rescue path — which the moduledoc now correctly documents as the
backstop. This is acceptable (the never-raise contract holds and surfaces
`{:error, {:error, %UndefinedFunctionError{}}}`), but the availability predicate
and the actual decode dependency being different modules is a subtle coupling
worth a one-line note.

**Fix:** Add a sentence to `available?/0`'s doc noting it probes
`:gen_smtp_client` as a proxy for the package, and that `:mimemail` absence is
handled by `decode/2`'s `:undef` rescue rather than the predicate.

### IN-02: `included` path widening to `mailglass_inbound/test/` will lint test fixtures with the full strict ruleset

**File:** `.credo.exs:120`

**Issue:**
The `included` list now covers `mailglass_inbound/test/`. The core `.credo.exs`
already documents (lines 199-204, `NegatedConditionsWithElse: false`) that test
files use guard idioms the strict ruleset dislikes. Widening to inbound tests may
surface new strict findings in inbound test fixtures (e.g. the deliberate
`if not ...` optional-dep guards, nested module aliases) that were previously
unlinted. This is a deliberate, documented widening (D-45 Wave 0), so it is
expected — flagged only so that any resulting inbound-test Credo noise is
attributed to this intentional change rather than treated as a new defect.

**Fix:** None required. If inbound test fixtures trip strict checks, prefer
narrow per-finding suppressions with `# Reason:`/`# Tracking:` blocks (per the
`check_credo_suppressions.sh` gate) over reverting the widening.

---

_Reviewed: 2026-05-23T12:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
