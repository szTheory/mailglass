---
phase: 47-inbound-test-helpers-generators
reviewed: 2026-05-24T00:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - lib/mix/tasks/mailglass.gen.inbound_route.ex
  - lib/mix/tasks/mailglass.gen.inbound_router.ex
  - lib/mix/tasks/mailglass.gen.mailbox.ex
  - mailglass_inbound/README.md
  - mailglass_inbound/docs/api_stability.md
  - mailglass_inbound/lib/mailglass_inbound/fixtures.ex
  - mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex
  - mailglass_inbound/lib/mailglass_inbound/test/ingress.ex
  - mailglass_inbound/lib/mailglass_inbound/test_assertions.ex
  - mailglass_inbound/mix.exs
  - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
  - mailglass_inbound/test/mailglass_inbound/fixtures_test.exs
  - mailglass_inbound/test/mailglass_inbound/mailbox_case_test.exs
  - mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs
  - mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs
  - test/mix/tasks/mailglass.gen.inbound_route_test.exs
  - test/mix/tasks/mailglass.gen.inbound_router_test.exs
  - test/mix/tasks/mailglass.gen.mailbox_test.exs
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: issues_found
---

# Phase 47: Code Review Report

**Reviewed:** 2026-05-24T00:00:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Phase 47 ships four Hex-public Testing helpers (`Fixtures`, `Test.Ingress`,
`TestAssertions`, `MailboxCase`) plus three Igniter generators. The **security
posture is sound**: the SES fixture mints an ephemeral in-memory RSA-2048
keypair, stores only the PUBLIC key in the ETS `CertCache`, never writes a
`.pem`/`.eml` to disk, uses `:crypto.strong_rand_bytes` for cert-URL
uniqueness, and the private key never leaves the function scope. No hardcoded
secrets, no command/path injection, no PII in telemetry (the driver-exercised
`Execution.execute/2` span carries only `mailbox`/`outcome`/`source`). Generator
tests are green (15/15), and the SES forged-signature negative test proves the
real verifier is genuinely exercised.

The defects are concentrated in **public-facing documentation and scaffold
correctness** — which matter disproportionately here because these are the
canonical onboarding artifacts for a published library. The headline issue
(CR-01) is that the primary copy-paste usage example shipped in BOTH the README
and the `MailboxCase` moduledoc does not work: it drives one capture and then
runs two consuming `assert_received`-based assertions, so the second always
fails. This is empirically reproduced below. A cluster of warnings covers
version-metadata drift (`@since 0.2.0` on a 0.1.0 package; README `~> 0.3.2`),
inaccurate "most recent" FIFO semantics in the assertion docs, a generator
scaffold whose own commented hint references undefined functions and a wrong
option, a self-contradictory matcher error message, and an unbounded
process-global `CertCache` growth path that is not reset on the
`receive_provider_payload` SES lane.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Shipped README / MailboxCase usage example is broken — second assertion always fails

**File:** `mailglass_inbound/README.md:42-47` and
`mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex:67-74`

**Issue:** The canonical onboarding example shows one drive followed by two
assertions:

```elixir
{:ok, _} = Test.Ingress.receive_inbound(message, routes: my_routes())
assert_inbound_received(subject: "Welcome")
assert_inbound_accepted()
```

`Test.Ingress.drive/3` (`lib/mailglass_inbound/test/ingress.ex:187`) sends
exactly ONE `{:inbound, message, outcome, route}` tuple per drive. Every
`assert_inbound_*` macro reads it with `assert_received`, which **consumes** the
matched message from the process mailbox. So `assert_inbound_received(subject:
"Welcome")` consumes the only tuple, and `assert_inbound_accepted()` then finds
an empty mailbox and raises `ExUnit.AssertionError`. This was reproduced
directly:

```
RESULT: second assertion FAILED - documented example is broken
```

The package's own test files already encode the correct discipline ("Each
`assert_*` consumes ONE captured tuple ... so drive one capture per assertion",
`test_assertions_test.exs:55-68`, `mailbox_case_test.exs:27-42`), which proves
the maintainers know the constraint — but the shipped public examples violate
it. An adopter copying the README/moduledoc snippet hits a red test on first
contact with the library.

**Fix:** Either drive once per assertion in the examples, or document the
single-consume semantics explicitly. Minimal correct form:

```elixir
test "accepts a welcome message" do
  message = Fixtures.build_inbound_message(subject: "Welcome")

  {:ok, %{outcome: %{outcome: :accept}, route: %{mailbox: MyApp.WelcomeMailbox}}} =
    Test.Ingress.receive_inbound(message, routes: my_routes())

  # ONE assertion per drive (assert_received consumes the captured tuple):
  assert_inbound_received(subject: "Welcome")
end
```

If two assertions on a single message are desired, drive twice (distinct
`provider_message_id` to avoid dedupe, as `mailbox_case_test.exs:37` does), or
add a non-consuming combined matcher. Apply the same fix to both the README and
the `MailboxCase` moduledoc.

## Warnings

### WR-01: Version metadata drift across mix.exs, `@since` tags, and README deps

**File:** `mailglass_inbound/mix.exs:4`,
`mailglass_inbound/lib/mailglass_inbound/test_assertions.ex:83,107,116,130,192,…`,
`mailglass_inbound/README.md:61-62`

**Issue:** Three mutually inconsistent version numbers ship to HexDocs/Hex:

- `mix.exs` `@version "0.1.0"` (also drives `docs source_ref: "v0.1.0"`).
- Every new `TestAssertions` macro carries `@doc since: "0.2.0"` (and
  `api_stability.md` references `@since 0.2.0` for `SignatureError`/`S3FetchError`).
  HexDocs will render "since 0.2.0" for symbols published in a `0.1.0` artifact —
  a version that does not exist and is *higher* than the package version.
- README install snippet pins `{:mailglass_inbound, "~> 0.3.2"}` and
  `{:mailglass, "~> 0.3.2"}` — a third, unrelated number that will not resolve
  against a `0.1.0` publish.

**Fix:** Pick one truth. If this slice publishes as `0.2.0`, bump
`mix.exs @version` to `0.2.0` and update README deps to `~> 0.2`. If it
publishes as `0.1.0`, change the `@doc since:` tags to `"0.1.0"` and the README
pins to `~> 0.1`. Add a docs-contract assertion that the README dep pin's major.minor
matches `Mix.Project.config()[:version]` so this cannot drift again.

### WR-02: `TestAssertions` outcome/routing assertions document "most recent" but read FIFO (oldest)

**File:** `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex:190,198,206,214,238,254`

**Issue:** The moduledoc and per-macro `@doc`s repeatedly say "the most recent
captured inbound was accepted / ignored / rejected / bounced / routed". The
implementation uses `assert_received`, which matches the **oldest** unconsumed
matching message (process mailbox is FIFO), not the most recent. Reproduced:

```
assert_received matched: :first   # two sends (:first then :second), got :first
```

If an adopter drives two messages and then asserts an outcome, they assert
against the FIRST message's outcome while believing it is the latest — a silent
wrong-assertion trap that the one-drive-per-assertion happy path hides.

**Fix:** Replace "most recent" with accurate language, e.g. "the next captured
inbound (oldest unconsumed; `assert_received` is FIFO and consumes the matched
tuple)". This pairs naturally with the CR-01 fix.

### WR-03: `gen.mailbox` test scaffold's commented hint references undefined functions and a non-existent option

**File:** `lib/mix/tasks/mailglass.gen.mailbox.ex:111-124`

**Issue:** The generated test stub `use MailglassInbound.MailboxCase` and then
comments:

```elixir
# message = build_inbound_message(recipient: "support@example.com")
# assert :accept = process(message)
```

Three problems if an adopter uncomments these (the explicit purpose of a
scaffold hint):

1. `MailboxCase` only `alias`es `Fixtures` (`mailbox_case.ex:82`); it does NOT
   `import` it. `build_inbound_message/1` is undefined in the test scope — it
   must be `Fixtures.build_inbound_message(...)`.
2. `build_inbound_message/1` has no `:recipient` option
   (`fixtures.ex:78-97` accepts `:to` / `:envelope_recipient`); `:recipient` is
   silently ignored, so the resulting message would not have the intended
   recipient.
3. `process/1` is defined on the mailbox module, not in the test scope — the
   bare `process(message)` call is undefined.

The whole value proposition of `gen.mailbox` is a working starting point; its
own hint does not compile and uses a wrong option.

**Fix:** Make the scaffold hint accurate and runnable, e.g.:

```elixir
# message = Fixtures.build_inbound_message(to: "support@example.com")
# assert :accept = MyApp.Inbound.Support.process(message)
```

or, better, demonstrate the actual capture lane the helpers exist for:

```elixir
# message = Fixtures.build_inbound_message(subject: "hi")
# {:ok, _} = Test.Ingress.receive_inbound(message, routes: [%MailglassInbound.Router.Route{mailbox: MyApp.Inbound.Support}])
# assert_inbound_accepted()
```

### WR-04: `__match_keyword__` emits a self-contradictory error for non-binary `:from`/`:to`

**File:** `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex:148-155,169-173`

**Issue:** The `:from`/`:to` clauses are guarded `when is_binary(v)`. A non-binary
value (e.g. `from: ["alice@example.com"]` — the same address-list shape the
struct actually stores) falls through to the catch-all `{key, _}` clause and
flunks with:

```
Unsupported matcher key: :from. Supported: :subject, :from, :to, :tenant, :provider, :envelope_recipient
```

The message lists `:from` as both unsupported and supported — contradictory and
actively misleading. Reproduced verbatim above. An adopter who passes the
natural list shape gets told `:from` is an unknown key.

**Fix:** Add explicit clauses that reject a non-binary `:from`/`:to` with an
accurate message, e.g.:

```elixir
{:from, v} ->
  flunk("from matcher expects a bare address string, got: #{inspect(v)}")
{:to, v} ->
  flunk("to matcher expects a bare address string, got: #{inspect(v)}")
```

placed before the catch-all so the guard fall-through can no longer reach it.

### WR-05: `Test.Ingress.receive_provider_payload(:ses, …)` primes the process-global `CertCache` ETS but never resets it

**File:** `mailglass_inbound/lib/mailglass_inbound/fixtures.ex:296-298` (prime),
`mailglass_inbound/lib/mailglass_inbound/test/ingress.ex` (driver does not reset)

**Issue:** `build_ses_sns_payload/1` calls
`CertCache.put(cert_url, public_key, future)` with a 24h TTL into the
**process-global** ETS table `:mailglass_webhook_ses_cert_cache` (confirmed
`cert_cache.ex`: `:ets.insert`, no per-process scoping). The cert URL is unique
per call and the entry is never evicted within a TTL window. `MailboxCase.setup`
and `FixturesTest`/`Test.IngressTest` reset it, but the shipped Testing surface
does not require `MailboxCase`. An adopter who calls
`receive_provider_payload(:ses, …)` from plain `async: true` ExUnit cases
(a supported usage per `api_stability.md` "driven from their own test suites")
accumulates one global ETS cert entry per SES fixture for the whole run, and the
global table is shared across concurrent async tests. This is a cross-test
shared-state / cleanliness hazard the moduledoc's "the only shared-state hygiene
is the per-setup ETS reset" claim only covers when `MailboxCase` is used.

**Fix:** Document prominently in `Fixtures.build_ses_sns_payload/1` and
`Test.Ingress` that SES fixtures require `CertCache.reset()` (or `MailboxCase`)
between tests, OR have the SES fixture register an `ExUnit.Callbacks.on_exit`
cleanup of just the URL it primed. Minimal:

```elixir
# in build_ses_sns_payload/1, after CertCache.put(...):
# (only when running under ExUnit) ExUnit.Callbacks.on_exit(fn -> CertCache.reset() end)
```

Prefer the documentation fix if the helper must stay free of an `:ex_unit`
runtime dependency at call time.

### WR-06: Documented `Test.Ingress` raw_mime-dedupe path for SendGrid/SES via `receive_inbound/2` is untested

**File:** `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex:101-104`
(doc instructs `evidence: %{raw_mime: ...}`),
`mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs:103-117`
(covers SES only via `receive_provider_payload`)

**Issue:** `receive_inbound/2` documents that for raw_mime-dedupe providers the
caller must pass `evidence: %{raw_mime: ...}` so replays dedupe. The persist
layer's dedupe for `sendgrid`/`ses`/`mailgun`-with-nil-provider-id keys on
`md5(evidence.raw_mime)` (`persist.ex:112-200`). The default evidence is
`%{raw_payload: %{}}` (no `raw_mime`). No test drives a sendgrid/ses canonical
message through `receive_inbound/2` with `evidence: %{raw_mime: ...}` and
asserts convergence — the only convergence proofs use `provider_message_id`
dedupe (`receive_inbound` Postmark) or `receive_provider_payload` (SES). If the
nil-fingerprint path collapses unrelated messages to the same hash, no test
would catch it. This is a coverage gap on a documented public contract, not a
proven defect.

**Fix:** Add a `receive_inbound/2` convergence test for a SendGrid (or
SES-with-nil-provider-id) canonical message passing `evidence: %{raw_mime: ...}`,
asserting `record_count() == 1` and `fresh_run_count() == 1` on replay; and a
companion test that two distinct raw_mime payloads produce two records (proving
the fingerprint discriminates).

## Info

### IN-01: `gen.inbound_router` scaffolds a `route` to a non-existent `SampleMailbox`

**File:** `lib/mix/tasks/mailglass.gen.inbound_router.ex:53`

**Issue:** The generated router emits `route SampleMailbox, recipient:
"support@example.com"`. `MailglassInbound.Router.route/2` only `Macro.expand`s
the alias and stores the atom without verifying the module exists or implements
the behaviour (`router.ex:48-62`), so the file compiles, but `SampleMailbox`
resolves to a module that does not exist. This is acceptable as a documented
copy-edit starting point, but a reader may be surprised that the scaffold's
sample route silently points at nothing.

**Fix:** Optional. Either add a trailing comment clarifying `SampleMailbox` is a
placeholder to replace, or scaffold the sample route commented out.

### IN-02: `parse_module/1` accepts arbitrary strings and mints odd atoms

**File:** `lib/mix/tasks/mailglass.gen.inbound_route.ex:139`,
`lib/mix/tasks/mailglass.gen.mailbox.ex:56`

**Issue:** `Module.concat([arg])` on a malformed mailbox arg (e.g. an email
string) produces atoms like `:"Elixir.support@example.com"`, which then render
oddly via `inspect/1` in `route_code/2`. This is user error surfacing in
user-visible generated output rather than a security issue (no eval, no
injection), but there is no validation that the positional `mailbox` looks like
a module name.

**Fix:** Optional. Validate the mailbox arg matches a module-name shape
(`~r/^[A-Z]\w*(\.[A-Z]\w*)*$/`) in `info/2` positional handling or at parse
time, and emit a clear error otherwise.

### IN-03: `assert_inbound_received` predicate clause does not handle captured-function syntax

**File:** `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex:117,131`

**Issue:** The predicate clause matches only `{:fn, _, _}` (anonymous `fn ->`).
A captured function (`&pred/1`, AST `{:&, _, _}`) falls through to the keyword
clause and calls `__match_keyword__(msg, &pred/1)`, which fails its
`is_list(params)` guard with a raw `FunctionClauseError` rather than a clean
message. Edge case; the documented usage is `fn`.

**Fix:** Optional. Add a `{:&, _, _}` clause mirroring the `{:fn, _, _}` branch,
or document that the predicate must be an anonymous-function literal.

### IN-04: `Test.Ingress` moduledoc "emits no telemetry of its own" can read as "drives no telemetry"

**File:** `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex:64-66`

**Issue:** The driver itself adds no spans (accurate), but it drives
`Execution.execute/2`, which emits an `execution_span` with `mailbox`,
`outcome`, `source` metadata. That metadata is PII-free and convention-compliant
(verified against `execution.ex:44-49`), so there is no violation — but a reader
auditing PII posture might mis-read the line as "no telemetry fires on this
path."

**Fix:** Optional. Clarify to "adds no telemetry of its own (the
`Execution.execute/2` it drives emits the normal PII-free execution span)".

---

_Reviewed: 2026-05-24T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
