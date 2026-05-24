---
phase: 47-inbound-test-helpers-generators
reviewed: 2026-05-24T13:15:00Z
depth: standard
iteration: 2
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
  warning: 2
  info: 4
  total: 7
status: issues_found
---

# Phase 47: Code Review Report (Iteration 2 — re-review)

**Reviewed:** 2026-05-24T13:15:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

This is a re-review after iteration 1 (11 findings) and a fix run that resolved
the 7 critical+warning findings (CR-01, WR-01..WR-06).

**Iteration-1 fixes are genuinely resolved.** I re-read every changed surface and
ran the suites deterministically (`--seed 0`):

- CR-01 (broken README/MailboxCase example) — both the README (`README.md:42-54`)
  and the `MailboxCase` moduledoc (`mailbox_case.ex:64-79`) now drive ONE
  assertion per capture with an inline single-consume note. Fixed.
- WR-01 (version drift) — `mix.exs @version` `0.1.0`, all `TestAssertions`
  `@doc since:` tags `"0.1.0"`, `api_stability.md` `@since 0.1.0`, README pins
  `{:mailglass_inbound, "~> 0.1"}` / `{:mailglass, "~> 1.0"}`. The new
  pin-tracking docs-contract test passes (13/13). Fixed.
- WR-02 ("most recent" → FIFO) — zero "most recent" strings remain; the six
  outcome/routing `@doc`s now say "the next captured inbound (oldest unconsumed;
  `assert_received` is FIFO …)". Fixed.
- WR-03 (broken scaffold hint) — `gen.mailbox` now threads the generated mailbox
  into the stub and emits a runnable `Fixtures.build_inbound_message/…` →
  `Test.Ingress.receive_inbound/…` → `assert_inbound_accepted()` hint. Generator
  tests pass (6/6). Fixed (but see WR-07 for a residual struct-surface concern).
- WR-04 (self-contradictory matcher error) — explicit non-binary `:from`/`:to`
  flunk clauses now precede the catch-all; regression test asserts the accurate
  message and absence of "Unsupported matcher key". Fixed.
- WR-05 (unreset SES CertCache) — `Fixtures.build_ses_sns_payload/1` carries a
  `{: .warning}` admonition and `Test.Ingress` has a "SES cross-test hygiene"
  section. Fixed (documentation route, as the review permitted).
- WR-06 (untested raw_mime dedupe via `receive_inbound/2`) — two new tests in the
  `receive_inbound/2` block (SendGrid convergence + fingerprint discrimination);
  suite passes (8/8). Fixed.

Suite status this run: generators 15/15, inbound docs-contract 13/13, the four
DB-backed inbound suites 35/35, clean `mix compile --warnings-as-errors` and
`mix compile --no-optional-deps --warnings-as-errors` for the inbound package.

**However, this re-review surfaced a previously-undetected BLOCKER.** Two of the
four shipped Testing helpers do not compose for two of their documented providers:
`Test.Ingress.receive_provider_payload/3` cannot succeed for `:sendgrid` or
`:mailgun` with the shipped `Fixtures` payloads — it raises unconditionally. This
is phase-47 code (introduced in commit 6e27951) on a Hex-published, `@since 0.1.0`
adopter-facing contract, and it is empirically reproduced below. The prior review
missed it because the only `receive_provider_payload` tests cover `:postmark` and
`:ses`; `:sendgrid` and `:mailgun` have no driver-level test (WR-08).

The four Info findings (IN-01..IN-04) were intentionally left unfixed in
iteration 1; I re-evaluated each and all four still apply (unchanged).

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `Test.Ingress.receive_provider_payload/3` is broken for `:sendgrid` and `:mailgun` — raises unconditionally with the shipped `Fixtures`

**File:** `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex:225-240`
(`build_request/3` for `:sendgrid`/`:mailgun`), with
`mailglass_inbound/lib/mailglass_inbound/fixtures.ex:160-233`
(`build_sendgrid_payload/1` / `build_mailgun_payload/1`)

**Issue:** `Fixtures` and `Test.Ingress` are both shipped, Hex-published,
`@since 0.1.0` Testing-surface helpers (`api_stability.md:97-115`). The driver's
own `receive_provider_payload/3` doc lists `:sendgrid` and `:mailgun` as
supported payload shapes produced by `Fixtures` (`ingress.ex:142-145`) and the
whole purpose of `receive_provider_payload` is to "run the **real** provider
`verify!`/`normalize` seam" (`ingress.ex:135-138`). For two of those four
providers, the helpers cannot be composed at all:

**SendGrid — broken two ways:**

1. `build_request(:sendgrid, %{raw_mime:, headers:, params:}, opts)`
   (`ingress.ex:225-235`) reads the request `headers` from the **payload map**,
   so it **silently ignores** the caller's `opts[:headers]`. By contrast the
   `:postmark` clause correctly uses `Keyword.get(opts, :headers, [])`
   (`ingress.ex:214-223`) — an inconsistency that is itself the bug.
2. `Fixtures.build_sendgrid_payload/1` returns `headers:
   [{"content-type", "multipart/form-data"}]` (`fixtures.ex:181`) with **no**
   `authorization` header. SendGrid `verify!` requires one
   (`sendgrid.ex` `verify_basic_auth!`: raises `SignatureError(:missing_header)`
   when no `authorization` header is present).

Because the driver ignores `opts[:headers]` for SendGrid, an adopter cannot
inject the missing auth header. Even supplying both
`config: %{basic_auth: {u,p}}` **and** a correct `authorization` header opt still
raises — reproduced directly:

```
SENDGRID with caller-supplied config+header RESULT:
  {:raised, Mailglass.SignatureError, "Webhook signature failed: signature header is missing"}
FIXTURE HEADERS (note: no authorization): [{"content-type", "multipart/form-data"}]
```

**Mailgun — structurally impossible with the fixture:**

`Mailgun.verify!` requires `timestamp`, `token`, and `signature` params
(`mailgun.ex` `fetch_signature_fields!`) plus a `signing_key` config.
`Fixtures.build_mailgun_payload/1` produces none of those signature params
(`fixtures.ex:220-232` — only `recipient`/`sender`/`from`/`to`/`subject`/
`body-plain`/`message-headers`/`attachment-count`), so there is **no** config
that makes it pass. Reproduced directly:

```
MAILGUN receive_provider_payload RESULT:
  {:raised, MailglassInbound.SignatureError, "Inbound signature failed: a required signing field is missing"}
```

So `receive_provider_payload(:mailgun, Fixtures.build_mailgun_payload(...), …)`
can never succeed, and `receive_provider_payload(:sendgrid, …)` can never succeed
with the shipped fixture/driver. Both fixtures only round-trip through
`Provider.normalize/1` directly (which is what `fixtures_test.exs:70-111`
actually exercises — never through `verify!`-then-normalize). An adopter
following the docs to test SendGrid or Mailgun provider parsing end to end hits
an unconditional raise. This is phase-47 code (commit 6e27951, in scope), not
pre-existing.

**Fix:** Two parts.

1. Make the SendGrid `build_request` clause honor caller headers like Postmark
   does, merging/overriding the fixture's headers with `opts[:headers]`:

   ```elixir
   defp build_request(:sendgrid, %{raw_mime: raw_mime, headers: headers, params: params}, opts) do
     request = %Request{
       provider: :sendgrid,
       raw_body: raw_mime,
       headers: Keyword.get(opts, :headers, headers),
       params: params,
       raw_mime: raw_mime
     }

     {request, Keyword.get(opts, :config, %{})}
   end
   ```

2. Either (a) make the fixtures emit a payload that passes the real `verify!`
   for `:sendgrid` (include an `authorization` header consistent with a documented
   default `basic_auth`) and `:mailgun` (emit signed `timestamp`/`token`/`signature`
   params against a documented default signing key — mirroring how
   `build_ses_sns_payload/1` already self-signs against a primed cert), so
   `receive_provider_payload` works out of the box; OR (b) if the fixtures are
   intentionally verify!-incompatible, remove `:sendgrid`/`:mailgun` from the
   `receive_provider_payload/3` supported-shape list (`ingress.ex:142-145`) and
   document that those fixtures are for the direct `normalize` lane /
   `receive_inbound/2` only. Option (a) is strongly preferred — it is the SES
   fixture's own already-shipped pattern and keeps the documented contract whole.
   Whichever path, add the WR-08 driver-level tests so this cannot regress.

## Warnings

### WR-07: Shipped Testing helpers and the `gen.mailbox` scaffold steer adopters to construct the `@moduledoc false` internal `%MailglassInbound.Router.Route{}` struct

**File:** `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex:114`
(`:routes` doc) and `lib/mix/tasks/mailglass.gen.mailbox.ex:125` (generated stub),
against `mailglass_inbound/lib/mailglass_inbound/router/route.ex:2`
(`@moduledoc false`)

**Issue:** `MailglassInbound.Router.Route` is an internal struct
(`route.ex:2` is `@moduledoc false`) and appears in **neither** the `stable` nor
the `testing` inventory of `api_stability.md`. Yet:

1. `Test.Ingress.receive_inbound/2`'s documented `:routes` option says to pass
   `[%MailglassInbound.Router.Route{}]` (`ingress.ex:114`).
2. The WR-03 fix made `gen.mailbox` emit a literal
   `%MailglassInbound.Router.Route{mailbox: …}` in the generated test stub
   (`mailbox.ex:125`).

The README and `MailboxCase` moduledoc deliberately use the abstract
`routes: my_routes()` and never name the struct, which suggests the maintainers
intend adopters to build routes via `use MailglassInbound.Router` + the
`:router` option, not by hand-constructing the internal struct. The shipped
`Test.Ingress` doc and the generated scaffold contradict that by guiding adopters
to a `@moduledoc false`, contract-unlisted struct as the canonical happy path.
If `Route`'s shape ever changes, every adopter test that copied the scaffold
breaks against a struct that was never promised stable.

**Fix:** Pick one and make it consistent across `Test.Ingress`'s `:routes` doc,
the `gen.mailbox` scaffold, the README, and `api_stability.md`:

- If hand-built routes are a supported testing input, document
  `MailglassInbound.Router.Route` (at least its `:mailbox`/`:recipient`/`:subject`
  fields) as part of the `testing` surface in `api_stability.md` and give it a
  real `@moduledoc`.
- Otherwise, change the `gen.mailbox` scaffold and the `Test.Ingress` `:routes`
  example to drive routing through a `use MailglassInbound.Router` module + the
  `:router` option (the path the README already implies), so no adopter is told
  to construct the internal struct.

### WR-08: No driver-level test exercises `receive_provider_payload/3` for `:sendgrid` or `:mailgun` — the gap that let CR-01 ship

**File:** `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs:126-163`
(`receive_provider_payload/3` describe block covers `:postmark` and `:ses` only)

**Issue:** The `receive_provider_payload/3` tests cover Postmark
(`ingress_test.exs:127`) and SES (`ingress_test.exs:148`). There is no test
driving `receive_provider_payload(:sendgrid, …)` or
`receive_provider_payload(:mailgun, …)`, even though both are listed as supported
payload shapes (`ingress.ex:142-145`) and both have shipped `Fixtures` builders.
This is precisely the coverage hole that let CR-01 reach iteration 2 undetected:
the SendGrid round-trip is tested only through direct `Sendgrid.normalize/1`
(`fixtures_test.exs:70-91`), never through the driver's `verify!`-first seam, so
the driver's silent `opts[:headers]` drop and the fixture's missing auth header
were never exercised together.

**Fix:** After fixing CR-01, add `receive_provider_payload/3` tests for
`:sendgrid` and `:mailgun` that assert `{:ok, %{outcome: %{outcome: :accept}}}`
(or the documented duplicate/convergence behavior) — mirroring the existing
Postmark/SES tests. These tests must fail today and pass after CR-01 is fixed,
proving the helpers compose for all four advertised providers.

## Info

### IN-01: `gen.inbound_router` scaffolds a `route` to a non-existent `SampleMailbox` (unchanged from iteration 1)

**File:** `lib/mix/tasks/mailglass.gen.inbound_router.ex:53`

**Issue:** The generated router still emits
`route SampleMailbox, recipient: "support@example.com"`. `Router.route/2` only
`Macro.expand`s the alias and stores the atom without verifying the module exists
(`router.ex:48-62`), so the file compiles but `SampleMailbox` resolves to a
non-existent module. Acceptable as a documented copy-edit starting point, but a
reader may be surprised the sample route points at nothing. Still applies.

**Fix:** Optional. Add a trailing comment clarifying `SampleMailbox` is a
placeholder, or scaffold the sample route commented out.

### IN-02: `parse_module/1` accepts arbitrary strings and mints odd atoms (unchanged from iteration 1)

**File:** `lib/mix/tasks/mailglass.gen.inbound_route.ex:139`,
`lib/mix/tasks/mailglass.gen.mailbox.ex:56`

**Issue:** `Module.concat([arg])` on a malformed mailbox arg (e.g. an email
string) produces atoms like `:"Elixir.support@example.com"`, which render oddly
via `inspect/1` in `route_code/2`. No validation that the positional `mailbox`
looks like a module name. User-error surfacing in generated output, not a
security issue — these are developer-run CLI tasks, not network-facing, so no
atom-exhaustion DoS. Still applies.

**Fix:** Optional. Validate the mailbox/router arg matches
`~r/^[A-Z]\w*(\.[A-Z]\w*)*$/` and emit a clear error otherwise.

### IN-03: `assert_inbound_received` predicate clause does not handle captured-function syntax (unchanged from iteration 1)

**File:** `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex:117,131`

**Issue:** Re-verified by AST probe: the predicate clause matches only
`{:fn, _, _}` (anonymous `fn ->`). A captured function (`&pred/1`, AST
`{:&, _, _}`) falls through to the keyword clause and calls
`__match_keyword__(msg, &pred/1)`, which fails its `is_list(params)` guard with a
raw `FunctionClauseError` rather than a clean message. (Empty-list and runtime-
variable args route to the keyword clause too, but degrade gracefully.) Edge
case; documented usage is the `fn` literal. Still applies.

**Fix:** Optional. Add a `{:&, _, _}` clause mirroring the `{:fn, _, _}` branch,
or document that the predicate must be an anonymous-function literal.

### IN-04: `Test.Ingress` moduledoc "emits no telemetry of its own" can read as "drives no telemetry" (unchanged from iteration 1)

**File:** `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex:80-82`

**Issue:** The line now reads "It emits no telemetry of its own and adds no PII
spans." The "of its own" qualifier helps slightly, but the driver does drive
`Execution.execute/2`, which emits a PII-free `execution_span`
(`execution.ex:46-59`). A reader auditing PII posture could still mis-read this
as "no telemetry fires on this path." No violation (the span is convention-
compliant and PII-free). Still mildly applies.

**Fix:** Optional. Clarify to "adds no telemetry of its own (the
`Execution.execute/2` it drives emits the normal PII-free execution span)".

---

_Reviewed: 2026-05-24T13:15:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
