---
phase: 45-inbound-telemetry-idempotency-foundation
reviewed: 2026-05-23T00:00:00Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - .credo.exs
  - .github/workflows/ci.yml
  - credo_checks/no_bare_optional_dep_reference.ex
  - credo_checks/telemetry_event_convention.ex
  - lib/mailglass/optional_deps/gen_smtp.ex
  - mailglass_inbound/config/config.exs
  - mailglass_inbound/config/dev.exs
  - mailglass_inbound/config/prod.exs
  - mailglass_inbound/config/test.exs
  - mailglass_inbound/docs/api_stability.md
  - mailglass_inbound/lib/mailglass_inbound/execution.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
  - mailglass_inbound/lib/mailglass_inbound/mime.ex
  - mailglass_inbound/lib/mailglass_inbound/mime_error.ex
  - mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex
  - mailglass_inbound/lib/mailglass_inbound/router/matcher.ex
  - mailglass_inbound/lib/mailglass_inbound/telemetry.ex
  - mailglass_inbound/mix.exs
  - mailglass_inbound/test/mailglass_inbound/mime_error_test.exs
  - mailglass_inbound/test/mailglass_inbound/mime_test.exs
  - mailglass_inbound/test/mailglass_inbound/properties/inbound_idempotency_convergence_test.exs
  - mailglass_inbound/test/mailglass_inbound/pub_sub/topics_test.exs
  - mailglass_inbound/test/mailglass_inbound/telemetry_test.exs
  - mailglass_inbound/test/support/test_repo.ex
  - mailglass_inbound/test/test_helper.exs
  - test/mailglass/optional_deps/gen_smtp_test.exs
findings:
  critical: 1
  warning: 5
  info: 5
  total: 11
status: issues_found
---

# Phase 45: Code Review Report

**Reviewed:** 2026-05-23
**Depth:** standard
**Files Reviewed:** 28
**Status:** issues_found

## Summary

This phase adds the inbound telemetry span surface, a never-raising standalone
MIME parser, the package-local `MIMEError`, a PubSub topic builder, a post-commit
broadcast in the ingress plug, and the TELE-08 1000-run idempotency convergence
property — plus widens two custom Credo checks and the `.credo.exs` scope to cover
the `mailglass_inbound` sibling.

The telemetry whitelist discipline is well-enforced in tests (`assert_pii_free`
across all four spans), the never-raise MIME contract is genuinely exercised
against the real `:mimemail` parser, and the convergence property drives a real
Postgres write path. However, two of the phase's headline lint/security guarantees
do not hold:

1. **The `NoBareOptionalDepReference` guard does not protect gen_smtp at all**
   (BLOCKER) — it keys on a non-existent `GenSmtp` Elixir module while gen_smtp is
   reached exclusively through the Erlang atoms `:mimemail` / `:gen_smtp_client`,
   so a bare `:mimemail.decode(...)` anywhere in inbound code would compile and pass
   CI. Both `.credo.exs` comments and the gateway moduledoc assert the guard works.
2. **The boundary-bomb / deep-nesting guard in `MailglassInbound.MIME` provides no
   DoS protection** (WARNING) — `:mimemail.decode/2` (which has no recursion limit)
   fully parses the entire nesting depth *before* the `collect_leaves` depth guard
   runs against the already-decoded tree.

Two further lint-coverage gaps (the `TelemetryEventConvention` check never inspects
`:telemetry.span/3`, and there is no `--no-optional-deps` compile lane for inbound)
mean the phase's "now lints inbound" claims are partially inert.

## Critical Issues

### CR-01: `NoBareOptionalDepReference` silently fails to gate gen_smtp (`:mimemail` / `:gen_smtp_client`)

**File:** `.credo.exs:33` (and `credo_checks/no_bare_optional_dep_reference.ex:62`)
**Issue:**
gen_smtp is an Erlang library. It has **no Elixir `GenSmtp` module** — every access
goes through the Erlang module atoms `:mimemail` (the parser) and
`:gen_smtp_client` (the availability probe), as `lib/mailglass/optional_deps/gen_smtp.ex:46,72`
confirms (`Code.ensure_loaded?(:gen_smtp_client)`, `:mimemail.decode(...)`).

The check resolves the call-site root with `root_module/1`. For a bare call
`:mimemail.decode(raw)` it returns `{:ok, :mimemail}`, then does
`Map.fetch(gated_modules, :mimemail)`. But `.credo.exs` keys gen_smtp on the Elixir
alias `GenSmtp` (which is the atom `:"Elixir.GenSmtp"`), so the fetch misses and the
`with` short-circuits to `nil` — **no issue is ever raised**. The check therefore
does nothing for gen_smtp: a bare `:mimemail.decode(...)` written anywhere in
`mailglass_inbound/lib/` outside the gateway would compile clean and pass `mix credo --strict`.

This defeats a non-negotiable convention ("Optional deps gated through
`Mailglass.OptionalDeps.*`") and contradicts the explicit claims in
`.credo.exs:36-39` ("this prefix makes the check flag any bare reference in inbound
code outside the gateway (Plan 03 depends on this guard)") and the gateway moduledoc
`lib/mailglass/optional_deps/gen_smtp.ex:15-17` ("bare references elsewhere are
forbidden by the `NoBareOptionalDepReference` Credo check"). Oban/OpenTelemetry/Mjml/
Sigra are unaffected because those are real Elixir modules; only gen_smtp is broken.

**Fix:** Key the gen_smtp entry on the Erlang module atoms actually used at call
sites, not the phantom `GenSmtp` alias:
```elixir
gated_modules: %{
  Oban => [Mailglass.OptionalDeps.Oban, MailglassInbound.OptionalDeps.Oban],
  OpenTelemetry => Mailglass.OptionalDeps.OpenTelemetry,
  Mjml => Mailglass.OptionalDeps.Mjml,
  # gen_smtp is Erlang-only; gate on the atoms used at call sites:
  :mimemail => [Mailglass.OptionalDeps.GenSmtp, MailglassInbound.OptionalDeps.GenSmtp],
  :gen_smtp_client => [Mailglass.OptionalDeps.GenSmtp, MailglassInbound.OptionalDeps.GenSmtp],
  Sigra => Mailglass.OptionalDeps.Sigra
}
```
Add a regression test (a fixture module with a bare `:mimemail.decode/1` reference
outside the gateway must produce a Credo issue), since the existing tests evidently
did not cover the Erlang-atom path.

## Warnings

### WR-01: MIME deep-nesting guard provides no boundary-bomb protection (T-45-12)

**File:** `mailglass_inbound/lib/mailglass_inbound/mime.ex:125-152, 172-193`
**Issue:**
`decode_and_build/2` calls `OptionalGenSmtp.decode(raw)` **first**, which invokes
`:mimemail.decode/2`. `mimemail.erl` has no recursion/depth limit (verified — no
`depth`/`limit` guard exists in the dep source), so it eagerly parses the entire
multipart tree to whatever depth the attacker chose. Only *after* that fully-decoded
tree is returned does `collect_leaves/3` re-walk it and `throw(@depth_exceeded)` on
overflow. The `:max_depth` guard therefore limits re-traversal of an
already-parsed structure — it cannot stop the boundary-bomb DoS it is documented to
defend (moduledoc line 21, `mime_test.exs:116` "boundary-bomb / deep-nesting guard
(T-45-12, V5)"). The test passes only because gen_smtp successfully decodes 50 valid
levels; it gives false confidence that the threat is mitigated.
**Fix:** Either (a) enforce a depth/size bound on the *raw bytes* before handing them
to `:mimemail.decode/2` (e.g. cap boundary-marker count or total byte size up front),
or (b) update the moduledoc/test to state plainly that the guard bounds the
internal representation only and does **not** mitigate decoder-side recursion, and
track the real DoS mitigation as a follow-up. Do not leave a control documented as
protective when it is not.

### WR-02: `TelemetryEventConvention` check never inspects `:telemetry.span/3` — inbound spans are unenforced

**File:** `credo_checks/telemetry_event_convention.ex:30-52` (config `.credo.exs:53-54`)
**Issue:**
The `.credo.exs` change widens `required_root` to `[:mailglass, :mailglass_inbound]`
so the convention "lints" the inbound package. But the check's `walk/5` only matches
`{{:., _, [:telemetry, :execute]}, ...}` — it never matches `:telemetry.span`. Every
one of the four new inbound events is emitted via `:telemetry.span/3`
(`telemetry.ex:136`), and the existing core span surfaces use `:telemetry.span/3`
too. So the widened root list is inert: no inbound (or core) span event is ever
checked for the 4-segment / `:mailglass_inbound`-root convention. The module's own
docstring claims the "4-level convention [is enforced] at lint time," which is not
true for span-based events.
**Fix:** Extend `walk/5` to also match `:telemetry.span/3` calls. Note `span/3`
takes a *prefix* list (e.g. `[:mailglass_inbound, :ingress, :request]`) that the
runtime expands with `:start`/`:stop`/`:exception`, so the literal must be checked
as `length(prefix) >= min_segments - 1` for span prefixes. Add a fixture test
covering both `:telemetry.execute` and `:telemetry.span` to lock the behavior.

### WR-03: No `--no-optional-deps` compile lane for `mailglass_inbound`

**File:** `.github/workflows/ci.yml:85-111` (and the `inbound_test` job at 166-237)
**Issue:**
CLAUDE.md mandates "CI lane `mix compile --no-optional-deps --warnings-as-errors`
is mandatory." The `compile_no_optional_deps` job runs only at the repo root for
core mailglass. The inbound sibling has its own optional deps (`{:oban, optional:
true}`, `{:gen_smtp, optional: true}` — `mix.exs:59,65`) and an explicit degraded
fallback (MIME-02 `:gen_smtp_unavailable`), but the `inbound_test` job runs
`mix deps.get` (fetches all, including optionals) and never compiles inbound without
them. The `:gen_smtp_unavailable` path is exercised only through the
`gen_smtp_available?: false` test seam, never through a real no-optional-deps
compile. A bare optional-dep reference that resolves only when the dep is present
(and which CR-01 shows Credo will not catch for gen_smtp) would slip through CI
entirely.
**Fix:** Add an inbound `compile_no_optional_deps` job mirroring the core one, run
from `working-directory: mailglass_inbound` with `mix compile --no-optional-deps
--warnings-as-errors`.

### WR-04: `decode_route` builds atoms from job args via `Module.concat/1` (atom-injection vector + dead branch)

**File:** `mailglass_inbound/lib/mailglass_inbound/execution.ex:242-251`
**Issue:**
`load/2` decodes the persisted Oban job arg `"mailbox"` through `decode_route/2` →
`mailbox_module/1`. The legitimate enqueue path always writes
`Atom.to_string(module)` (`route_mailbox/1`, line 257), i.e. an `"Elixir."`-prefixed
string, which hits the safe `String.to_existing_atom` clause (line 250). The second
clause `mailbox |> String.split(".") |> Module.concat()` (line 251) is therefore
dead for legitimate flows, but it remains reachable with tampered/corrupt job args
and **creates a brand-new atom from external input** (`Module.concat` does not
require pre-existing atoms), an atom-table-exhaustion vector. The `rescue
ArgumentError` on line 245 only guards the `to_existing_atom` branch; `Module.concat`
never raises, so the unsafe path is unguarded.
**Fix:** Drop the `Module.concat` clause and treat any non-`"Elixir."`-prefixed
mailbox as invalid:
```elixir
defp mailbox_module("Elixir." <> _rest = mailbox), do: String.to_existing_atom(mailbox)
defp mailbox_module(_mailbox), do: raise(ArgumentError, "unknown mailbox")
```
The surrounding `rescue ArgumentError -> {:error, :invalid_job_args}` then covers it.
(The identical pattern in `internal/replay.ex:107-108`, out of this review's scope,
should be fixed too.)

### WR-05: 500 error response inlines `inspect(reason)`, which can leak message PII

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:84`
**Issue:**
On `{:error, reason}` from `persistence.persist/2`, the plug returns
`send_json(conn, 500, %{status: "error", reason: inspect(reason)})`. When `reason`
is an Ecto changeset from `insert_record/4` (a real DB/validation error), `inspect`
renders its `changes` map, which contains `subject`, `from`, `to`, `text_body`,
`html_body`, etc. — exactly the fields CLAUDE.md forbids exposing. Even though this
goes to the provider rather than logs/telemetry, leaking recipient/sender/subject/
body bytes in an error response contradicts the project's strict no-PII posture and
the "don't put full response/payload in logs" rule. (The line is wrapped, not newly
introduced, this phase, but it is the new telemetry-tuple return path so it is in
scope.)
**Fix:** Return a stable, PII-free reason and do not serialize the raw error:
```elixir
{:error, _reason} ->
  resp = send_json(conn, 500, %{status: "error", reason: "persist_failed"})
```
Log a structured, whitelisted summary internally instead of echoing `inspect(reason)`
to the wire.

## Info

### IN-01: Gateway moduledoc misattributes `:undef` to the `catch :exit` clause

**File:** `lib/mailglass/optional_deps/gen_smtp.ex:30-33`
**Issue:** The moduledoc says `:exit`/`:undef` from missing `:iconv` is "caught by
`catch :exit`." An `:undef` (calling `iconv:convert/3` when the module is absent)
raises `UndefinedFunctionError`, which is an *error* and is caught by the `rescue`
clause (surfaced as `{:error, {:error, e}}`), not by `catch :exit`. The never-raise
contract still holds, but the documented mapping is wrong.
**Fix:** Correct the moduledoc to attribute `:undef`/`UndefinedFunctionError` to the
`rescue` branch; reserve the `catch :exit` description for genuine `exit(reason)`.

### IN-02: New stable modules missing from ExDoc `Stable` group

**File:** `mailglass_inbound/mix.exs:111-121`
**Issue:** `docs/api_stability.md:27-28` declares `MailglassInbound.PubSub.Topics`
and `MailglassInbound.MIMEError` as `stable`, but the `groups_for_modules: [Stable:
[...]]` list in `mix.exs` still contains only the original six modules. The two new
stable surfaces will render outside the Stable heading in generated docs,
contradicting the contract inventory.
**Fix:** Add `MailglassInbound.PubSub.Topics` and `MailglassInbound.MIMEError` to the
`Stable` group.

### IN-03: `@doc since:` annotations reference unreleased versions

**File:** `mailglass_inbound/mix.exs:4`; `mime.ex:92,107`, `mime_error.ex:43`,
`pub_sub/topics.ex:31`, `telemetry.ex:71,86,101,119`; `lib/mailglass/optional_deps/gen_smtp.ex:68`
**Issue:** Inbound's package version is `@version "0.1.0"` but the new public
functions are annotated `@doc since: "0.2.0"`; the core gateway `decode/2` is
`@doc since: "1.2.0"` while core is at 1.0.0. HexDocs will show "since" tags for
versions that do not yet exist. This is the conventional forward-reference for an
in-flight release, but if the version bump is missed at publish time the docs become
inconsistent.
**Fix:** Ensure the release ceremony bumps `@version` to match (`0.2.0` inbound /
`1.2.0` core) before publish, or hold the `@since` tags until the bump lands.

### IN-04: Execution telemetry reports outcome even when the run insert fails

**File:** `mailglass_inbound/lib/mailglass_inbound/execution.ex:40-60`
**Issue:** `stop_metadata` is computed from `normalized_result` (derived from
`attrs` via `change_execution_run`) *before* `insert_execution_run` runs, then
returned verbatim from the span regardless of insert success. If
`insert_execution_run` returns `{:error, _}`, the `:stop` event still reports e.g.
`outcome: :accept` for a run that was never persisted, and the failure is not
reflected in `:status`/metadata. Observability is mildly misleading (no functional
bug — the caller still receives the error tuple).
**Fix:** Branch the stop metadata on the insert result (e.g. attach `status: :error`
when `insert_execution_run` fails) so the span reflects what actually persisted.

### IN-05: Property test runs `truncate_all/0` twice per iteration

**File:** `mailglass_inbound/test/mailglass_inbound/properties/inbound_idempotency_convergence_test.exs:78, 95-96`
**Issue:** `truncate_all/0` is called once in `setup` and again at the top of the
property body. The setup call is redundant — the body truncates before every
generated iteration anyway, and the setup truncation is immediately followed by the
first iteration's truncation. Harmless, but the duplicate `TRUNCATE ... CASCADE`
adds noise to an already long 1000-run job.
**Fix:** Drop the `truncate_all()` call from `setup` (or document why both are
intentional); the per-iteration truncation is the load-bearing one.

---

_Reviewed: 2026-05-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
