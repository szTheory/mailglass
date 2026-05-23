# Phase 47: Inbound Test Helpers + Generators - Research

**Researched:** 2026-05-23
**Domain:** Elixir test-DX tooling (ExUnit case templates, code-built provider fixtures) + Igniter 0.8 code generators/codemods
**Confidence:** HIGH (every load-bearing claim is grounded in repo-local source read this session; the two CONTEXT-deferred items are resolved against the actual vendored Igniter 0.8.0 and the actual inbound runtime modules)

## Summary

This phase ships the inbound sibling of outbound's test DX, plus three Igniter generators. Almost all of the implementation surface is *mirror-an-existing-pattern* work: the four test helpers mirror `Mailglass.TestAssertions` / `Mailglass.MailerCase`, the SES signed-fixture helpers are extracted verbatim from a working test, the persist→sync-execute driver generalizes a shipped property test, and two of the three generators copy `mailglass.gen.mailable.ex`. The novel surface is small and well-bounded: (1) the inbound message-capture mechanism (there is no outbound-style `Fake.Storage` doing `send/2`, so `Test.Ingress` must do the capture itself), and (2) the IGEN-03 idempotent zipper edit.

Both CONTEXT-deferred research items are now resolved with concrete answers. **IGEN-03** uses `Igniter.Project.Module.find_and_update_module/3` (positions the zipper at the module's do-block) + a `Igniter.Code.Function.move_to_function_call_in_current_scope/4` pre-scan for duplicate `route/2` nodes + `Igniter.Code.Common.add_code/3` to append — and the relevant functions are **byte-identical between Igniter 0.8.0 (root, where generators live) and 0.7.9 (inbound)**, so the version drift is API-irrelevant. **D-47-12 is confirmed correct**: there is no `:async_execution_impl` key anywhere; `MailboxCase`'s real job is to make sync `execute/2` the default path and to snapshot/reset the *process-global* state the fixtures actually touch — which is `CertCache` (ETS) and the SES process-dictionary stash, NOT a mythical async-impl app-env key.

**One CONTEXT premise is wrong against the code and must be corrected before planning** (see "CONTEXT vs. Code Collisions"): `MailglassInbound.TestRepo` lives in `mailglass_inbound/test/support/test_repo.ex`, NOT `lib/` as canonical_refs line 210 / code_context line 250 state. This is load-bearing: `MailboxCase` ships in `lib/` and adopters `use` it, so it cannot reference `TestRepo` — it must resolve the adopter's repo via `Application.get_env(:mailglass_inbound, :repo)`.

**Primary recommendation:** Build the four helpers in `mailglass_inbound/lib/` mirroring the named outbound anchors; `MailboxCase` resolves the repo from app-env (never hardcodes TestRepo), defaults to sync `execute/2`, and resets `CertCache` + `S3Fetcher.Fake` in setup. `Test.Ingress` captures by `send`ing a `{:inbound, ...}` tuple to the test process so `TestAssertions` can `assert_received` (the inbound analog of outbound's `{:mail, _}`). All three generators are `use Igniter.Mix.Task` in core `lib/mix/tasks/`; gen.mailbox/gen.inbound_router copy gen.mailable, gen.inbound_route uses `find_and_update_module/3` + dup-scan + `add_code`. `--dry-run` is a free global Igniter switch — write zero code for it.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-47-01:** All four adopter-facing helpers ship in **`mailglass_inbound/lib/`** (packaged to Hex via `files: ~w(lib …)` at `mailglass_inbound/mix.exs:113`) — NOT `test/support/`: `MailglassInbound.TestAssertions` (ITEST-01..04), `MailglassInbound.MailboxCase` (ITEST-05, an `ExUnit.CaseTemplate`), `MailglassInbound.Test.Ingress` (ITEST-06), `MailglassInbound.Fixtures` (ITEST-07). This is the one deliberate extension beyond outbound parity (outbound never shipped `MailerCase`). Swoosh sets the precedent (ships `Swoosh.TestAssertions`, no case template).
- **D-47-02:** ExDoc-group the four under a new **"Testing"** group (`mailglass_inbound/mix.exs:133-143`). Keep dependency-light: `ExUnit.CaseTemplate`/`ExUnit.Assertions` are available in the adopter's `:test` env — **no `:ex_unit` runtime dep**.
- **D-47-03:** `Test.Ingress` drives the production write path by calling `Ingress.Persist.persist/2` then `Execution.execute/2` (**sync**) directly. NOT a faked `Plug.Conn`; NO new `trigger_event/3` shim. The "single fake-provider seam" is the existing provider `verify!`/`normalize` + `Persist` + `Execution` chain + the opt injection already present (`provider_module:`, `routes:`/`router:`/`repo:`, SES `s3_fetcher:`).
- **D-47-04:** Two entry points: `receive_inbound/2` (takes a `%InboundMessage{}`/Fixtures-built message + `router:`/`routes:` opt → persist + sync execute) and `receive_provider_payload/3` (raw provider payload → real provider `verify!`/`normalize` seam → same persist+execute). Both mirror the 1000-replay convergence proof (`test/.../inbound_idempotency_convergence_test.exs:99-102`), which drives `execute/2` sync because async `dispatch/2` yields non-deterministic `ExecutionRun` counts.
- **D-47-05:** The outbound `Fake.trigger_event/3` analogy is shape-different (simulates a downstream webhook on an already-delivered message). Inbound has no "delivery row to look up" — do not force that shape onto `Test.Ingress`.
- **D-47-06:** All three generators are Igniter mix tasks (`use Igniter.Mix.Task`) in **core `mailglass/lib/mix/tasks/`** alongside the existing `mailglass.gen.*` family — NOT in `mailglass_inbound`. Every one of the 12 existing mix tasks lives in core; `mailglass_inbound` declares no Igniter dep; root `mix.exs:164` declares `{:igniter, "~> 0.7", runtime: false}` (resolved 0.8.0).
- **D-47-07:** `gen.mailbox` (IGEN-01) and `gen.inbound_router` (IGEN-02) use Igniter creation (`create_module` + `create_new_file`), like `mailglass.gen.mailable.ex:10-61`. `gen.mailbox` scaffolds: mailbox module (behaviour + default `process/1`) + a `route/2` stub in the configured router + an ExUnit test stub that `use MailglassInbound.MailboxCase`.
- **D-47-08:** `gen.inbound_route` (IGEN-03) uses Igniter Sourceror-zipper source-editing to insert a `route/2` clause into an existing router **idempotently** — find the `defmodule` with `use MailglassInbound.Router`, append `route(Mailbox, recipient: …, subject: …, headers: …)` as the last body statement, after a pre-check scanning existing `route/2` nodes for the same mailbox+pattern. Precedent: `mailglass.upgrade.v0_2.ex:33-88`. DSL target: `@mailglass_inbound_routes` accumulator + `route/2` macro + `__before_compile__` at `router.ex:39-72`.
- **D-47-09:** `--dry-run` (IGEN-04) comes free from Igniter's built-in flag (with `use Igniter.Mix.Task`), reinforced by the `Igniter.assign(igniter, :dry_run?, true)` force-pattern in `upgrade.v0_2.ex`. Do **not** copy `install.ex`'s bespoke `Installer.Plan`/`Apply` engine.
- **D-47-10:** `Fixtures.build_ses_sns_payload/1` builds a valid X.509-signed SNS notification entirely in code (RSA-2048 keypair, SNS envelope, byte-sorted canonical string, `:public_key.sign(canonical, :sha, private_key)`, base64 → `"Signature"`) and primes the real `Mailglass.Webhook.Providers.SES.CertCache.put/3`. NO `.pem` on disk, NO `CertCache.Fake` (doesn't exist). Extract proven helpers from `ses_provider_test.exs:287-352`. SES Action:S3 body served by `S3Fetcher.Fake` via the `s3_fetcher:` seam — no AWS.
- **D-47-11:** `Fixtures` also builds: canonical `%InboundMessage{}`, Postmark JSON, SendGrid form-encoded, Mailgun multipart — all from code, no `.eml` files (avoids real-PII commits, locked anti-pattern in REQUIREMENTS.md Out of Scope).
- **D-47-12:** `:async_execution_impl` does not exist in either package. Inbound selects its runner via `MailglassInbound.OptionalDeps.Oban.runner()` with no global `_impl` key. `MailboxCase`'s real job: make sync `execute/2` the default test path and snapshot/restore whatever app-env the fixtures mutate — NOT snapshot a nonexistent key. Planner must confirm the exact global state.
- **D-47-13:** `SES.CertCache.Fake` does not exist. Superseded by D-47-10 (in-memory keypair + real `CertCache.put/3`).

### Claude's Discretion

- Exact `TestAssertions` macro/function signatures and the message-capture mechanism (process-dictionary mailbox vs PubSub subscription vs ETS), provided the 4 matcher styles + outcome + routing + negative assertions all work in the test process scope.
- Exact `Test.Ingress` opt names and return shape, provided it drives sync `execute/2` on the real persist path.
- Exact generated template contents (mailbox/router/route/test stubs).
- Exact `Fixtures` function names and option shapes.
- Exact app-env keys `MailboxCase` snapshots (pending the D-47-12 confirmation — **now resolved below**).

### Deferred Ideas (OUT OF SCOPE)

- `docs/inbound-testing.md` documenting these helpers (IDOC-02) → Phase 50.
- Admin LiveView that consumes the routing-trace patterns → Phase 48.
- A synthetic-inbound dev tool (Conductor-style) → deferred to v1.2.1 (security design pass).
- Broader fixture fuzzing beyond the canonical provider shapes — not needed for this phase's DX goal.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ITEST-01 | `TestAssertions` 4 matcher styles for `assert_inbound_received/1` (no-arg / keyword / fn / pattern) | Mirror `Mailglass.TestAssertions` macro dispatch (`lib/mailglass/test_assertions.ex:86-159`). Capture mechanism resolved below: `Test.Ingress` `send`s `{:inbound, %InboundMessage{}, outcome}`; macros wrap `assert_received {:inbound, _, _}`. |
| ITEST-02 | Outcome assertions `assert_inbound_{accepted,rejected,ignored,bounced}/1` keyed off locked outcome atoms | `mailbox.ex:22` outcomes `:accept \| :ignore \| {:reject, r} \| {:bounce, r}`; `execute/2` normalizes via `normalize_result/1` (`execution.ex:228`). Map: accepted→`:accept`, rejected→`{:reject,_}`, ignored→`:ignore`, bounced→`{:bounce,_}`. |
| ITEST-03 | Routing assertions `assert_inbound_routed_to/2` + `assert_inbound_no_match/1` | `__mailglass_inbound_routes__/0` reflection (`router.ex:64-72`) + `Router.Matcher.match/2` (`matcher.ex:8`). The persisted result carries `route: %{status: :matched, mailbox: …}` or `%{status: :no_match}` (`persist.ex:281-293`). |
| ITEST-04 | Negative `assert_no_inbound_received/0` | Macro wrapping `refute_received {:inbound, _, _}` (mirror `assert_no_mail_sent` at `test_assertions.ex:206`). |
| ITEST-05 | `MailboxCase` ExUnit case template: sandbox + pub_sub subscription + per-test fixtures + HI-01 snapshot/restore | `ExUnit.CaseTemplate`; structure from `test/support/mailer_case.ex:120-204` but **adapt per D-47-12** (resolved below). Repo from `Application.get_env(:mailglass_inbound, :repo)`, NOT TestRepo. |
| ITEST-06 | `Test.Ingress` drives real persist+route+execute with a single fake-provider seam | `Persist.persist/2` (`persist.ex:19`) → `Execution.execute/2` (`execution.ex:37`), generalizing `inbound_idempotency_convergence_test.exs:99-102`. |
| ITEST-07 | `Fixtures` builds canonical `%InboundMessage{}` + Postmark JSON / SendGrid form / Mailgun multipart / SES SNS, all from code | Provider input shapes from `providers/{postmark,sendgrid,mailgun,ses}.ex`; SES signed helpers from `ses_provider_test.exs:287-352`. |
| IGEN-01 | `mix mailglass.gen.mailbox <Module>` scaffolds mailbox + behaviour + default callback + route stub + test stub using `MailboxCase` | Copy `mailglass.gen.mailable.ex`; the route stub uses the IGEN-03 zipper edit (shared helper). |
| IGEN-02 | `mix mailglass.gen.inbound_router <Module>` scaffolds a new router with macro DSL + sample route | `create_module` with `use MailglassInbound.Router` + one `route/2` example. |
| IGEN-03 | `mix mailglass.gen.inbound_route <pattern> <Mailbox>` adds a route to an existing router idempotently | `find_and_update_module/3` + dup-scan + `add_code/3` (full sketch below). |
| IGEN-04 | All generators support `--dry-run` | Free global Igniter switch (`Igniter.Mix.Task.Info` `@global_options` includes `dry_run: :boolean`). |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Test assertions (`TestAssertions`) | Adopter test process | — | Reads the calling process's mailbox (`assert_received`); naturally `async: true`-safe |
| Test case setup (`MailboxCase`) | Adopter test process + Ecto Sandbox + PubSub | core Mailglass app (CertCache ETS owner) | Per-test process owns sandbox checkout; subscribes to tenant PubSub topic; resets process-global ETS |
| Real write-path driver (`Test.Ingress`) | Library runtime (Persist + Execution) | Adopter's host repo | Drives the production persist→execute chain synchronously in the test process |
| Fixture construction (`Fixtures`) | Pure functions + process-global CertCache prime | `S3Fetcher.Fake` (process-dict) | Code-built payloads; SES path primes the shared ETS cert cache + per-process S3 fake |
| Generators (`gen.mailbox/router/route`) | Build-time (Igniter mix task, core package) | Adopter source tree (Sourceror AST) | Mix tasks run at dev time; edit/create adopter `.ex` files via Igniter |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `igniter` | 0.8.0 (root `mix.lock`) | Generator + codemod framework for IGEN-01..04 | Already the project's generator engine (`gen.mailable`, `upgrade.v0_2`); vendored at `deps/igniter/` [VERIFIED: mix.lock + deps/igniter/mix.exs:8] |
| `sourceror` | ~> 1.4 (Igniter dep) | Zipper-based AST editing for IGEN-03 | Igniter's underlying AST tool; `upgrade.v0_2.ex` already uses `Sourceror.Zipper` directly [VERIFIED: mix.lock igniter deps] |
| `ex_unit` | bundled with OTP/Elixir | `CaseTemplate` + `Assertions` for the four helpers | Ships with the runtime; available at compile-time on the load path even without a deps entry (proven: outbound `Mailglass.TestAssertions` does `import ExUnit.Assertions` in `lib/` and compiles) [VERIFIED: lib/mailglass/test_assertions.ex:55 compiles in package] |
| `:public_key` / `:crypto` | OTP 27 (bundled) | SES SNS X.509 sign in Fixtures | Already in outbound `extra_applications: [:logger, :crypto, :public_key]` (`mix.exs:32`); inbound SES tests use `:public_key.generate_key`/`sign` [VERIFIED: ses_provider_test.exs:343-352] |
| `jason` | (existing) | Postmark/SES JSON fixture encoding | Already used by every provider's normalize [VERIFIED: postmark.ex:25, ses_provider_test.exs:263] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `nimble_options` | ~> 1.1 (existing) | Validates `route/2` opts | Indirect — the router macro validates; generators emit valid opt shapes [VERIFIED: router.ex:75] |
| `stream_data` | ~> 1.3 (test-only) | Property tests | Optional for fixture round-trip property tests; already the convergence-proof backbone [VERIFIED: mailglass_inbound/mix.exs deps] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Test.Ingress` `send`ing `{:inbound,…}` to capture | Subscribe to PubSub topic `inbound_record_inserted/1` | PubSub payload is PII-free `{:inbound_record_inserted, record_id, %{provider, record_type}}` (`plug.ex:525`) — lacks the `%InboundMessage{}` + outcome the assertions need. Use PubSub for the *live-update* path (Phase 48 admin), `send` for the *assertion* path. **Recommend `send`.** |
| Igniter zipper edit for IGEN-03 | Regex/string append to the router file | String editing cannot detect existing `route/2` nodes for idempotency, breaks on formatting variance. **Recommend Igniter.** |
| `find_and_update_module/3` | `Igniter.Code.Module.find_and_update_module` (Code namespace) | The `Igniter.Project.Module` version handles file location + index + format; the `Code` namespace is lower-level. **Recommend `Project.Module`.** |

**Installation:** No new dependencies. Igniter is already a root dev/build dep; ExUnit/crypto/public_key are bundled. The four helpers add NO runtime deps (D-47-02 confirmed: ExUnit is not a Hex dep, it's an OTP application).

## Package Legitimacy Audit

> This phase installs **zero new external packages**. Every dependency it uses is already in the respective `mix.lock` (verified this session) or is bundled with OTP/Elixir.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| igniter | Hex | mature (0.8.0) | high (ash-project) | github.com/ash-project/igniter | n/a (already locked) | Already in mix.lock — no new install |
| sourceror | Hex | mature | high | github.com/doorgan/sourceror | n/a | Transitive via Igniter — no new install |
| ex_unit / crypto / public_key | OTP/Elixir bundled | n/a | n/a | erlang/otp, elixir-lang | n/a | Standard library — never installed |

**Packages removed due to slopcheck [SLOP] verdict:** none (no new packages)
**Packages flagged as suspicious [SUS]:** none

*slopcheck not run because no `mix deps.get`/`npm install`/`pip install` occurs in this phase. The phase is pure test-helper + generator code on top of an already-locked dependency graph.*

## Architecture Patterns

### System Architecture Diagram

```
ADOPTER TEST PROCESS (async:true-capable)
│
│  use MailglassInbound.MailboxCase
│    ├─ setup: Sandbox.start_owner!(repo_from_app_env, shared: not async?)
│    ├─ setup: Tenancy.put_current(tenant)  + PubSub.subscribe(inbound_record_inserted topic)
│    ├─ setup: CertCache.reset()  +  S3Fetcher.Fake.reset()   ← process-global / process-dict resets
│    └─ on_exit: restore snapshotted app-env (see D-47-12 key list) + stop_owner
│
├──────────────► MailglassInbound.Fixtures
│                  build_inbound_message/1 ─► %InboundMessage{}
│                  build_postmark_payload/1 ─► JSON (MessageID, Headers[], FromFull…)
│                  build_sendgrid_payload/1 ─► {raw_mime, form params}
│                  build_mailgun_payload/1  ─► multipart params (signature triple OR body-mime)
│                  build_ses_sns_payload/1  ─► signed SNS JSON  +  CertCache.put(url, pubkey, ttl)
│                                                               +  S3Fetcher.Fake.put(bucket,key,mime)
│
├──────────────► MailglassInbound.Test.Ingress
│   receive_inbound(message, router|routes)        receive_provider_payload(provider, payload, opts)
│        │                                                  │
│        │                                          provider.verify!(request, config)   ← REAL verify
│        │                                          provider.normalize(request)         ← REAL normalize
│        │                                                  │  (build handoff like plug.ex:470)
│        ▼                                                  ▼
│   Ingress.Persist.persist(handoff, [routes:|router:, repo:])   ← REAL DB write + dedupe + Matcher
│        │  returns %{status, inbound_record, inbound_evidence, route, message}
│        ▼
│   Execution.execute(persisted, source: :fresh)  ← SYNC (NOT dispatch/2) — runs mailbox.process/1,
│        │                                            inserts ExecutionRun, returns normalized outcome
│        ▼
│   send(test_pid, {:inbound, message, outcome, route})   ← the CAPTURE seam (inbound analog of {:mail,_})
│
└──────────────► MailglassInbound.TestAssertions
     assert_inbound_received/1   (4 styles, macros over assert_received {:inbound, msg, _, _})
     assert_inbound_accepted/1 / _rejected / _ignored / _bounced   (match outcome atom)
     assert_inbound_routed_to/2 / assert_inbound_no_match/1         (match route map)
     assert_no_inbound_received/0   (refute_received)


GENERATORS (core mailglass package, dev/build time — Igniter 0.8.0)
  mix mailglass.gen.mailbox <M>        ─► create_module(mailbox) + add route via IGEN-03 helper + create test stub
  mix mailglass.gen.inbound_router <M> ─► create_module(router with use Router + sample route)
  mix mailglass.gen.inbound_route <p> <M> ─► find_and_update_module(router):
                                              scan existing route/2 (move_to_function_call_in_current_scope)
                                              → if absent, add_code(route(M, …)) at end of body
  --dry-run on all three ─► FREE (Igniter global switch)
```

### Recommended Project Structure

```
mailglass_inbound/lib/mailglass_inbound/
├── test_assertions.ex     # MailglassInbound.TestAssertions (ITEST-01..04) — ships to Hex
├── mailbox_case.ex        # MailglassInbound.MailboxCase (ITEST-05) — ExUnit.CaseTemplate, ships to Hex
├── fixtures.ex            # MailglassInbound.Fixtures (ITEST-07) — ships to Hex
└── test/
    └── ingress.ex         # MailglassInbound.Test.Ingress (ITEST-06) — ships to Hex
                           # NOTE: module is MailglassInbound.Test.Ingress; place under lib/.../test/

mailglass/lib/mix/tasks/   # core package (Igniter lives here)
├── mailglass.gen.mailbox.ex          # IGEN-01
├── mailglass.gen.inbound_router.ex   # IGEN-02
└── mailglass.gen.inbound_route.ex    # IGEN-03 (+ shared zipper-edit helper used by gen.mailbox)
```

> Placement caveat: `MailglassInbound.Test.Ingress` is a `MailglassInbound.Test.*` module that must ship in the Hex artifact (it's adopter-facing). It belongs under `lib/mailglass_inbound/test/ingress.ex` (a `lib/` path, despite the `Test` in the name) so the `files: ~w(lib …)` manifest packages it. Do NOT put it in `test/support/` — that path is not in the package manifest.

### Pattern 1: Inbound capture seam (the message-capture mechanism — Claude's Discretion, resolved)

**What:** Outbound captures sent mail because `Mailglass.Adapters.Fake.Storage` calls `send(owner, {:mail, %Message{}})` on every delivery; `assert_mail_sent` is a macro over `assert_received {:mail, _}` (`test_assertions.ex:34-37, 86-90`). Inbound has no equivalent storage doing the `send/2` — `execute/2` just inserts an `ExecutionRun` and returns the outcome (`execution.ex:52-60`). So the capture seam must live in `Test.Ingress`.

**When to use:** Always — this is how all four `assert_inbound_*` families read.

**Example (recommended seam):**
```elixir
# Source: pattern derived from lib/mailglass/test_assertions.ex:34-37 (outbound {:mail,_})
#         + mailglass_inbound/lib/mailglass_inbound/execution.ex:40-60 (execute/2 return)
defmodule MailglassInbound.Test.Ingress do
  alias MailglassInbound.{Execution, InboundMessage}
  alias MailglassInbound.Ingress.Persist

  def receive_inbound(%InboundMessage{} = message, opts \\ []) do
    handoff = %{
      tenant_id: message.tenant_id,
      provider: message.provider,
      message: message,
      evidence: Keyword.get(opts, :evidence, %{raw_payload: %{}})
    }

    persist_opts = Keyword.take(opts, [:routes, :router, :repo])

    with {:ok, persisted} <- Persist.persist(handoff, persist_opts),
         {:ok, outcome} <- Execution.execute(persisted, source: :fresh) do
      # THE CAPTURE SEAM: send to the calling test process so TestAssertions can assert_received.
      send(self(), {:inbound, message, outcome, persisted.route})
      {:ok, %{message: message, outcome: outcome, route: persisted.route, persisted: persisted}}
    end
  end
end
```
The matching assertion macro:
```elixir
# Source: mirrors lib/mailglass/test_assertions.ex:86-119 macro dispatch
defmacro assert_inbound_received do
  quote do: assert_received {:inbound, _msg, _outcome, _route}
end
```

> **Why `send(self(), …)` and not PubSub:** `Test.Ingress` runs synchronously *in the test process*, so `send(self(), …)` lands the tuple in the same mailbox `assert_received` reads — no subscription, no cross-process ownership, naturally `async: true`-safe (each process has its own mailbox). The PubSub `inbound_record_inserted` broadcast (`plug.ex:519-527`) carries only `{record_id, %{provider, record_type}}` — insufficient for outcome/routing assertions. Subscribe to PubSub only if you also want to assert the realtime fan-out fired (optional).

### Pattern 2: `MailboxCase` repo resolution + state reset (ITEST-05, D-47-12 resolved)

**What:** `MailboxCase` is an `ExUnit.CaseTemplate`. Its `using/1` injects `import MailglassInbound.TestAssertions`; its `setup` checks out a sandbox connection on the **adopter's** repo, subscribes to the tenant PubSub topic, resets process-global fixtures, and snapshots/restores app-env on exit.

**When to use:** Every adopter mailbox test (and the generated test stub).

**Example:**
```elixir
# Source: structure from test/support/mailer_case.ex:100-209 (HI-01), adapted per D-47-12.
defmodule MailglassInbound.MailboxCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import MailglassInbound.TestAssertions
      alias MailglassInbound.{Fixtures, Test}
    end
  end

  setup tags do
    # Resolve the ADOPTER's repo — NEVER MailglassInbound.TestRepo (that's the
    # library's own internal test repo in test/support, absent from adopter apps).
    repo = Application.get_env(:mailglass_inbound, :repo) ||
             raise "config :mailglass_inbound, :repo must be set for MailboxCase"

    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(repo, shared: not tags[:async])

    tenant_id = Map.get(tags, :tenant, "test-tenant")
    if tenant_id, do: Mailglass.Tenancy.put_current(tenant_id)

    # Process-global / process-dict resets (the REAL state fixtures touch — see D-47-12).
    Mailglass.Webhook.Providers.SES.CertCache.reset()      # process-global ETS
    MailglassInbound.S3Fetcher.Fake.reset()                # current-process dict

    if tenant_id do
      Phoenix.PubSub.subscribe(
        MailglassInbound.PubSub,  # confirm the PubSub name the inbound app starts
        MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id)
      )
    end

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
```

### Pattern 3: IGEN-03 idempotent route insertion (the deferred zipper item, fully resolved)

**What:** Find the router module (`defmodule` with `use MailglassInbound.Router`), scan for an existing `route(SameMailbox, …)` call, and append a new `route/2` as the last body statement only if absent.

**When to use:** `gen.inbound_route` (and the route-stub step inside `gen.mailbox`).

**Worked sketch (grounded in vendored Igniter 0.8.0 source — functions verified line-identical in 0.7.9):**
```elixir
# Source (all verified this session, root deps/igniter/ @ 0.8.0):
#   Igniter.Project.Module.find_and_update_module/3  — module.ex:201-236
#   Igniter.Code.Common.move_to_do_block/1           — common.ex:895 (called internally by find_and_update_module)
#   Igniter.Code.Function.move_to_function_call_in_current_scope/4 — function.ex:243
#   Igniter.Code.Function.argument_equals?/3         — function.ex:990
#   Igniter.Code.Common.add_code/3                   — common.ex:330 (placement: :after default)
# Precedent for the task shell + forced dry-run: lib/mix/tasks/mailglass.upgrade.v0_2.ex:22-43

defmodule Mix.Tasks.Mailglass.Gen.InboundRoute do
  use Boundary, classify_to: Mailglass
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing) do
    %Igniter.Mix.Task.Info{
      # --dry-run is a FREE global switch — do NOT add it to schema (Igniter.Mix.Task.Info @global_options).
      schema: [router: :string, recipient: :string, subject: :string],
      positional: [:pattern, :mailbox]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    router  = Module.concat([igniter.args.options[:router] || default_router(igniter)])
    mailbox = Module.concat([igniter.args.positional.mailbox])
    recipient = igniter.args.positional.pattern   # or from options

    route_code = "route(#{inspect(mailbox)}, recipient: #{inspect(recipient)})"

    {:ok, igniter} =
      Igniter.Project.Module.find_and_update_module(igniter, router, fn zipper ->
        # zipper is positioned at the module's DO-BLOCK (find_and_update_module calls move_to_do_block).
        if route_already_present?(zipper, mailbox, recipient) do
          {:ok, zipper}                                  # IDEMPOTENT: no-op on re-run
        else
          # Append as the last statement of the extendable do-block.
          {:ok, Igniter.Code.Common.add_code(zipper, route_code, placement: :after)}
        end
      end)

    igniter
  end

  # Scan the current (do-block) scope for an existing route/2 whose 0th arg == mailbox.
  defp route_already_present?(zipper, mailbox, _recipient) do
    case Igniter.Code.Function.move_to_function_call_in_current_scope(
           zipper, :route, 2,
           fn call_zipper -> Igniter.Code.Function.argument_equals?(call_zipper, 0, mailbox) end
         ) do
      {:ok, _} -> true
      :error -> false
    end
  end
end
```

> **Two zipper subtleties the planner must verify in execution (HIGH-value test targets):**
> 1. `find_and_update_module/3` hands the updater a zipper at the do-block via `move_to_do_block/1` (`module.ex:207`). `add_code/3` with `placement: :after` appends within the extendable block (`common.ex:380-403`). If the body has exactly one statement (e.g. only `use MailglassInbound.Router`), the do-block may be a single expression, not a `{:__block__, …}`. Confirm `add_code` correctly promotes a single-child do-block to a block (it handles `super_upwards` + single-child cases at `common.ex:405+`; `maybe_move_to_block/1` exists at `common.ex:954`). **Self-test both the empty-routes router and the multi-route router.**
> 2. `argument_equals?/3` compares the 0th arg to `mailbox`. The router source has the mailbox as an `{:__aliases__, …}` AST node. Verify `argument_equals?` resolves aliases (it uses `nodes_equal?` internally) — if not, the dup-scan misses and re-runs double-insert. **The idempotency self-test (run task twice, `assert_unchanged` on the second) catches this directly.**

### Pattern 4: Generator creation (IGEN-01/02, copy gen.mailable)

**What:** `create_module/3` + `create_new_file/3`, exactly as `mailglass.gen.mailable.ex:58-61`.

**Example (gen.mailbox skeleton):**
```elixir
# Source: lib/mix/tasks/mailglass.gen.mailable.ex:10-61
igniter
|> Igniter.Project.Module.create_module(mailbox_module, """
  @behaviour MailglassInbound.Mailbox

  @impl MailglassInbound.Mailbox
  def process(%MailglassInbound.InboundMessage{} = _message) do
    :accept
  end
""")
|> add_route_to_router(router_module, mailbox_module, recipient)   # reuse IGEN-03 helper
|> Igniter.create_new_file(test_path, test_stub_using_mailbox_case)
```

### Anti-Patterns to Avoid

- **Copying `install.ex`'s `Installer.Plan`/`Apply` engine for `--dry-run`** — `install.ex` is NOT an Igniter task (it uses raw `OptionParser`, `lib/mix/tasks/mailglass.install.ex:33`). Igniter's built-in `--dry-run` (global switch, `Igniter.Mix.Task.Info` @global_options) is the correct, zero-code precedent. (D-47-09)
- **Referencing `MailglassInbound.TestRepo` from `MailboxCase`** — TestRepo is the library's *internal* test repo in `test/support/`, absent from adopter apps. Resolve the adopter repo from app-env. (See CONTEXT collision below.)
- **Snapshotting a `:async_execution_impl` app-env key** — it does not exist. (D-47-12)
- **Reaching for `SES.CertCache.Fake`** — does not exist; prime the real ETS cache. (D-47-10/13)
- **Driving `dispatch/2` in `Test.Ingress`** — async, non-deterministic `ExecutionRun` counts. Use `execute/2`. (D-47-03/04, proven by convergence test `:99-102`)
- **Keying inbound assertions off a "delivery row"** — there is none; key off the dispatched `%InboundMessage{}` + outcome. (D-47-05)
- **Committing `.eml` files** — locked anti-pattern (REQUIREMENTS.md Out of Scope); build from code. (D-47-11)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Append a `route/2` to an existing router idempotently | Regex/string manipulation of the router file | `find_and_update_module/3` + `move_to_function_call_in_current_scope/4` + `add_code/3` | Survives formatting variance, detects duplicates, reformats output. (`module.ex:201`, `function.ex:243`, `common.ex:330`) |
| `--dry-run` preview | Custom plan/diff/apply engine (like `install.ex`) | Igniter's global `--dry-run` switch | Built into every `use Igniter.Mix.Task`; renders the diff automatically. (`info.ex:79`) |
| RSA-2048 keypair + SNS canonical-string + signature | Bespoke crypto | Extract `generate_sns_keypair`/`canonical_string`/`sign_canonical`/`sign_notification` from `ses_provider_test.exs:287-352` | Proven against the real `SES.verify!`; identical to outbound `webhook_fixtures.ex:194-228`. |
| Persist→execute write path in tests | Re-implementing the DB write + dedupe + matcher | `Ingress.Persist.persist/2` + `Execution.execute/2` | The production path; generalizing the shipped 1000-replay proof guarantees fidelity. |
| Provider payload → canonical message | Hand-parsing | The real provider `verify!`/`normalize` (`receive_provider_payload/3`) | Tests the actual normalization, not a test-only copy. (`plug.ex:404-434`) |
| SES S3 body in tests | A real S3 client or a new fake | `S3Fetcher.Fake` via `s3_fetcher:` config seam | Already shipped, process-dict isolated. (`s3_fetcher/fake.ex`) |
| Generator self-tests | Booting a real Mix project | `Igniter.Test` harness (`test_project/1`, `assert_creates/3`, `assert_has_patch/3`, `assert_unchanged/2`) | The project already uses it (`mailglass.gen.mailable_test.exs:3-7`). |

**Key insight:** This phase is ~90% extraction and composition of already-proven code. The hand-rolling risk is concentrated in exactly two spots — the inbound capture seam (resolved: `send(self(), {:inbound,…})`) and the IGEN-03 zipper idempotency (resolved: dup-scan + `add_code`). Everything else is "lift this working block into a shipped module."

## Runtime State Inventory

> This is a test-tooling phase (new `lib/` modules + new mix tasks), NOT a rename/refactor/migration. No existing runtime state is being mutated. The relevant "state" question is instead *what global/process state the new helpers themselves touch* — captured here so `MailboxCase`'s snapshot/reset is complete (this is the substance of D-47-12).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — `Test.Ingress` writes to the adopter's sandboxed test DB, rolled back per test by `Sandbox.stop_owner`. | None — sandbox handles cleanup. |
| Live service config | None — no external service touched (S3 is faked via `s3_fetcher:`, SNS certs are in-memory). | None. |
| OS-registered state | None. | None. |
| Process-global state the fixtures touch | **(1) `Mailglass.Webhook.Providers.SES.CertCache`** — a *public, named ETS table* `:mailglass_webhook_ses_cert_cache` owned by `CertCache.Supervisor`/`TableOwner` in the **core Mailglass app** (`lib/.../ses/cert_cache/table_owner.ex:22`, `application.ex:36`). `Fixtures.build_ses_sns_payload/1` calls `CertCache.put/3` (`cert_cache.ex:60`). Two `async: true` tests priming the same cert URL race. **(2) SES process-dictionary stash** `Process.put({SES, :verified}, …)` set in `verify!` and consumed in `normalize` (`providers/ses.ex:47,57`) — process-local, self-clearing (`verify!` deletes stale stash first, `:57`). | `MailboxCase` setup MUST call `CertCache.reset/0` (`cert_cache.ex:67`). SES-fixture tests should be `async: false` OR use distinct cert URLs per test. The process-dict stash needs no cross-test action (fresh process per test). |
| Process-dict state the fixtures touch | **`MailglassInbound.S3Fetcher.Fake`** — stores canned responses + counts in the *calling process's* dictionary (`s3_fetcher/fake.ex:25-36`). Naturally `async: true`-safe. | `MailboxCase` setup SHOULD call `S3Fetcher.Fake.reset/0` for hygiene (no cross-process bleed, but clears intra-process leftovers). |
| App-env keys read (NOT mutated) | `:mailglass_inbound, :repo` — read by `MailglassInbound.Repo` facade (`repo.ex:38`) AND must be read by `MailboxCase` to resolve the sandbox repo. `:mailglass_inbound, :async_adapter` — read by `OptionalDeps.Oban.runner/0` (`optional_deps.ex:43`), but ONLY consulted in `dispatch/2`, which `Test.Ingress` does NOT call. | `MailboxCase` READS `:repo`; it does not need to write it. It does NOT need to snapshot `:async_adapter` because the sync `execute/2` path never reads it. |
| App-env keys to snapshot/restore (the HI-01 concern) | **D-47-12 RESOLVED: there is NO app-env key `MailboxCase` must mutate-then-restore.** Outbound's HI-01 snapshot exists because `MailerCase` *writes* `:async_adapter`/`:async_adapter_impl` to force sync delivery (`mailer_case.ex:131,179`). Inbound achieves sync execution **structurally** — `Test.Ingress` calls `execute/2` directly — so `MailboxCase` never writes an async-mode app-env key, and therefore has nothing to snapshot/restore. The only "restore" is `Sandbox.stop_owner` + `CertCache.reset` on the next test's setup. | **If a future test exercises `dispatch/2`** (async), it would read `:mailglass_inbound, :async_adapter`; only then would a snapshot/restore of THAT key be warranted. For Phase 47's sync-default `MailboxCase`, snapshot nothing. Document this explicitly so the planner does not invent a snapshot. |
| Build artifacts | None new beyond compiled `.beam` for the new modules. The generators' OUTPUT (adopter files) is created in adopter projects, not this repo. | None. |

**The canonical question answered:** After `MailboxCase` setup runs, the only process-global state mutated is the `CertCache` ETS table (reset, not snapshot) and the per-process sandbox checkout (stopped on exit). There is no global app-env key to snapshot/restore — the D-47-12 correction is confirmed against the code.

## Common Pitfalls

### Pitfall 1: `MailboxCase` hardcodes `MailglassInbound.TestRepo`
**What goes wrong:** Adopters `use MailglassInbound.MailboxCase`; their app has no `MailglassInbound.TestRepo` module → `UndefinedFunctionError` at sandbox checkout.
**Why it happens:** CONTEXT.md states TestRepo is in `lib/` (it is NOT — see CONTEXT collision); copying outbound's `MailerCase` which reads `Application.get_env(:mailglass, :repo, Mailglass.TestRepo)` with a TestRepo fallback (`mailer_case.ex:151`).
**How to avoid:** Resolve `Application.get_env(:mailglass_inbound, :repo)` with NO TestRepo fallback (raise a clear error if unset). The library's own MailboxCase self-tests set `:repo` to `MailglassInbound.TestRepo` via config (already done at `config/test.exs:11`).
**Warning signs:** `MailboxCase` source contains the literal `TestRepo`.

### Pitfall 2: SES fixture tests flake under `async: true` (shared ETS race)
**What goes wrong:** Two concurrent tests prime the same `@cert_url` in the process-global `CertCache` ETS table with different keypairs; one test's `verify!` reads the other's public key → spurious `:bad_signature`.
**Why it happens:** `CertCache` is a `:public` named ETS table (`table_owner.ex:22`), not process-scoped. The existing `ses_provider_test.exs` is `async: false` precisely for this.
**How to avoid:** Make SES-fixture-driven tests `async: false`, OR have `Fixtures.build_ses_sns_payload/1` mint a unique cert URL per call (e.g. include a random suffix) so concurrent tests never collide. `MailboxCase` should reset CertCache in setup regardless.
**Warning signs:** Intermittent `:bad_signature` only when the suite runs in parallel (echoes the documented inbound-suite flake in MEMORY.md).

### Pitfall 3: IGEN-03 double-inserts on re-run (idempotency miss)
**What goes wrong:** Running `gen.inbound_route` twice appends two identical `route/2` calls.
**Why it happens:** The dup-scan's `argument_equals?/3` fails to resolve the `{:__aliases__, …}` mailbox AST against the `mailbox` module atom, so the existing route is never detected.
**How to avoid:** Verify `argument_equals?` (or `nodes_equal?`) resolves aliases; write an explicit "run task twice → `assert_unchanged` on second" self-test (Igniter.Test provides `assert_unchanged/2`).
**Warning signs:** The second `apply_igniter!` produces a non-empty diff.

### Pitfall 4: `add_code` on a single-statement router body
**What goes wrong:** A freshly-generated router whose body is only `use MailglassInbound.Router` is not a `{:__block__, …}`; naïve append produces malformed AST or appends in the wrong place.
**Why it happens:** Single-expression do-blocks aren't extendable blocks until promoted.
**How to avoid:** Rely on `add_code/3`'s built-in single-child handling (`common.ex:405+`); self-test the empty-routes router case explicitly.
**Warning signs:** Generated router fails to compile, or the route lands above `use`.

### Pitfall 5: `Test.Ingress` evidence omission breaks SendGrid/Mailgun/SES dedupe
**What goes wrong:** `receive_inbound/2` passes an empty `evidence` map; SendGrid/Mailgun/SES dedupe on `md5(raw_mime)` when `provider_message_id` is nil (`persist.ex:111-198`), so missing `raw_mime` makes every replay look new (dedupe fails silently).
**Why it happens:** Postmark dedupes on `provider_message_id` so empty evidence "works" for Postmark and masks the gap.
**How to avoid:** `Fixtures`-built messages for SendGrid/Mailgun/SES must include `evidence: %{raw_mime: …}`. Document the per-provider dedupe key. Cross-test with a SendGrid replay.
**Warning signs:** A 2-replay test inserts 2 `InboundRecord`s for SendGrid/Mailgun/SES.

### Pitfall 6: Helpers in `lib/` fail `mix compile --no-optional-deps --warnings-as-errors`
**What goes wrong:** A helper references an optional-dep module (e.g. `Oban`, `ExAws`) directly → compile warning → CI fails the mandatory no-optional-deps lane.
**Why it happens:** The four helpers ship in `lib/` and are subject to the same compile lane as runtime code.
**How to avoid:** The helpers should reference ONLY core/runtime modules. `Test.Ingress` calls `Persist`/`Execution` (which internally gate Oban via `OptionalDeps.Oban`). Don't reference `Oban`/`ExAws`/`Plug.Test` from the helpers. ExUnit references are fine (bundled).
**Warning signs:** `mix compile --no-optional-deps --warnings-as-errors` (the mandatory lane per CLAUDE.md) flags the new modules.

## Code Examples

### IGEN-04 dry-run is free (the whole "implementation")
```elixir
# Source: deps/igniter/lib/mix/task/info.ex:77-91 — @global_options includes dry_run: :boolean
# Any `use Igniter.Mix.Task` task accepts --dry-run with zero extra code.
# `mix mailglass.gen.inbound_route support@x.com MyApp.SupportMailbox --dry-run`
# renders the diff and exits without writing. No schema entry, no handler needed.
```

### Forcing dry-run-by-default (only if a generator should default to preview)
```elixir
# Source: lib/mix/tasks/mailglass.upgrade.v0_2.ex:33-43
# upgrade.v0_2 makes dry-run the DEFAULT and requires --apply. Generators
# should NOT do this (gen.mailable applies by default); this is shown only as
# the documented force-pattern if a route edit warrants preview-first.
igniter =
  if igniter.args.options[:apply], do: igniter,
  else: Igniter.assign(igniter, :dry_run?, true)
```

### SES signed-SNS fixture (extract verbatim into Fixtures)
```elixir
# Source: mailglass_inbound/test/.../ses_provider_test.exs:287-352 (proven against real SES.verify!)
defp generate_sns_keypair do
  private_key = :public_key.generate_key({:rsa, 2048, 65537})
  {{:RSAPublicKey, elem(private_key, 2), elem(private_key, 3)}, private_key}
end

defp sign_canonical(canonical, private_key),
  do: :public_key.sign(canonical, :sha, private_key) |> Base.encode64()

defp canonical_string(payload, "Notification") do
  ~w(Message MessageId Subject Timestamp TopicArn Type)
  |> Enum.filter(&Map.has_key?(payload, &1))
  |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
end
# In Fixtures.build_ses_sns_payload/1: build envelope → canonical → sign → put "Signature"
# → CertCache.put(cert_url, public_key, future) → (Action:S3) S3Fetcher.Fake.put(bucket, key, raw_mime)
```

### Generator self-test (mirror gen.mailable_test, add idempotency for IGEN-03)
```elixir
# Source: test/mix/tasks/mailglass.gen.mailable_test.exs:3-42 + deps/igniter/lib/igniter/test.ex
use ExUnit.Case
import Igniter.Test

test "gen.inbound_route is idempotent" do
  igniter = test_project(app_module: Test)
            |> Igniter.compose_task("mailglass.gen.inbound_router", ["Test.InboundRouter"])
            |> apply_igniter!()

  once  = Igniter.compose_task(igniter, "mailglass.gen.inbound_route",
            ["support@x.com", "Test.SupportMailbox"]) |> apply_igniter!()
  twice = Igniter.compose_task(once, "mailglass.gen.inbound_route",
            ["support@x.com", "Test.SupportMailbox"])

  assert_unchanged(twice)   # second run must be a no-op
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.eml` fixture files on disk | Code-built provider payloads | Project-locked from v1.1 | No real-PII commits; ITEST-07 |
| `Igniter.Code.Common.add_code(zipper, code, :after)` (atom 3rd arg) | `add_code(zipper, code, placement: :after)` (keyword) | Igniter ≥ ~0.5 | Atom form is deprecated and logs a warning (`common.ex:334-348`); use keyword form |
| `module_exists?/2` | `module_exists/2` | Igniter (current) | `?` form deprecated (`module.ex:177`); prefer non-`?` |

**Deprecated/outdated:**
- `Igniter.Code.Common.add_code/3` atom-placement arg — use `placement: :atom` keyword (`common.ex:334`).
- The CONTEXT claim that `TestRepo` is in `lib/` — outdated/incorrect (see collision section).

## CONTEXT vs. Code Collisions

> Per the brief: "If a CONTEXT decision turns out to be wrong against the code, say so explicitly with evidence." One collision found; it is load-bearing.

### COLLISION 1 (must fix before planning): `MailglassInbound.TestRepo` is NOT in `lib/`

- **CONTEXT claims:** canonical_refs line 210 — *"`mailglass_inbound/lib/mailglass_inbound/test_repo.ex` — inbound already has a TestRepo in `lib/` (not test/support)"*; code_context line 250-251 repeats *"`MailglassInbound.TestRepo` already exists in `lib/` — inbound's established test-repo convention."*
- **Code says:** The only `test_repo.ex` is at `mailglass_inbound/test/support/test_repo.ex` (verified: `find` returns exactly one file; `ls lib/mailglass_inbound/test_repo.ex` → No such file). Its moduledoc: *"Adopters do NOT use this module."* `mix.exs` `elixirc_paths(:test): ["lib", "test/support"]` compiles it only in `:test`. It is NOT in the `files: ~w(lib …)` package manifest, so it does NOT ship to Hex.
- **Why it matters:** D-47-01 ships `MailboxCase` in `lib/` for adopters to `use`. If `MailboxCase` references `TestRepo` (because CONTEXT said it's a `lib/` convention), it will fail in every adopter app and would also need to be in the package manifest (it isn't). The correct design: `MailboxCase` resolves the adopter's repo from `Application.get_env(:mailglass_inbound, :repo)` (the same facade `MailglassInbound.Repo` uses at `repo.ex:38`). The library's own MailboxCase self-tests work because `config/test.exs:11` sets `:repo` to `MailglassInbound.TestRepo`.
- **Net:** The *spirit* of CONTEXT (inbound has an established test-repo convention) is right; the *location claim* is wrong. Plan `MailboxCase` to resolve repo from app-env, never to name `TestRepo`.

### Non-collisions (CONTEXT confirmed correct against code)

- **D-47-12 (`:async_execution_impl` does not exist):** CONFIRMED. `grep` across both packages finds zero references; `execute/2` reads `:inbound_records`/`:source`/`:repo` only (`execution.ex:40-43`); runner selection reads `:mailglass_inbound, :async_adapter` only in `dispatch/2` (`optional_deps.ex:43`). The async-mode app-env key MailboxCase would snapshot **does not need snapshotting** because the sync path never writes it.
- **D-47-13 (`SES.CertCache.Fake` does not exist):** CONFIRMED. Only `CertCache` (real ETS) exists; no `.Fake` variant anywhere.
- **D-47-06 (Igniter 0.8.0 in root):** CONFIRMED. Root `mix.lock` pins `igniter 0.8.0`; inbound pins `0.7.9`. Generators live in core → 0.8.0 applies. **De-risking bonus:** the four functions IGEN-03 uses are byte-identical between 0.8.0 and 0.7.9 and `usage-rules.md` is identical — so even the version drift is API-irrelevant for this phase.
- **D-47-02 (no `:ex_unit` runtime dep):** CONFIRMED. Outbound `Mailglass.TestAssertions` ships in `lib/` with `import ExUnit.Assertions` and compiles in the package; ExUnit is a bundled OTP application on the compile load path.
- **D-47-03/04 (sync `execute/2`, opt seams):** CONFIRMED. `persist/2` signature is `(handoff_t, opts)` with `repo:`/`routes:`/`router:` (`persist.ex:19-22, 281-292`); `execute/2` is `(persisted, opts)` sync (`execution.ex:37-60`); convergence test drives exactly this pair (`:99-102`).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The inbound app starts a PubSub named `MailglassInbound.PubSub` and `MailboxCase` can subscribe to `Topics.inbound_record_inserted/1`. | MailboxCase Pattern 2 | LOW — if the name differs, subscription is optional anyway (the `send`-based capture is the primary path). Planner should confirm the PubSub name from `MailglassInbound.Application` + `PubSub.Topics`. |
| A2 | `Igniter.Code.Function.argument_equals?/3` resolves `{:__aliases__,…}` mailbox AST against a module atom for the dup-scan. | IGEN-03 Pattern 3 | MEDIUM — if it doesn't, idempotency misses and double-inserts. Mitigated by the mandatory "run twice → assert_unchanged" self-test, which catches it deterministically. |
| A3 | `MailglassInbound.Test.Ingress` placed at `lib/mailglass_inbound/test/ingress.ex` is packaged by `files: ~w(lib …)`. | Project Structure | LOW — `lib/**` is globbed; verify the path is under `lib/` (it is). The docs-contract test should assert the module is documented under the new "Testing" group. |
| A4 | Capturing via `send(self(), {:inbound, …})` is the chosen mechanism (Claude's Discretion). | Capture seam Pattern 1 | LOW — it's the direct analog of outbound `{:mail,_}` and is async-safe. Alternative (PubSub) is documented but insufficient for outcome assertions. |
| A5 | `MailboxCase` should reset `CertCache` even for non-SES tests. | MailboxCase setup | LOW — `reset/0` is cheap (`:ets.delete_all_objects`); harmless for non-SES tests, prevents cross-test bleed for SES ones. |

## Open Questions

1. **PubSub name + whether MailboxCase should subscribe by default.**
   - What we know: the plug broadcasts `{:inbound_record_inserted, record_id, %{provider, record_type}}` to `Topics.inbound_record_inserted(tenant_id)` (`plug.ex:519-527`). CONTEXT integration-points (line 264) names `MailglassInbound.PubSub.Topics.inbound_record_inserted/1`.
   - What's unclear: the exact PubSub server name the inbound app boots, and whether the assertion DX needs the subscription at all (the `send`-based capture doesn't).
   - Recommendation: Plan the subscription as optional/best-effort in `MailboxCase` setup (wrap in a `Code.ensure_loaded?`/`try`), and base the four `assert_inbound_*` families on the `send`-captured `{:inbound, …}` tuple. Confirm the PubSub name during Wave 0.

2. **Should `gen.mailbox` find-or-create the router, or require it to exist?**
   - What we know: D-47-07 says gen.mailbox adds "a route stub in the configured router." gen.inbound_router (IGEN-02) creates a router.
   - What's unclear: behavior when no router exists yet.
   - Recommendation: If the target router module isn't found, `gen.mailbox` should either create a minimal one (compose `gen.inbound_router`) or emit an actionable Igniter notice ("run mix mailglass.gen.inbound_router first"). Prefer the notice (simpler, explicit). Decide during planning.

3. **`receive_provider_payload/3` config plumbing for SES (`s3_fetcher:`, `cert_cache_ttl_seconds`).**
   - What we know: the plug builds a per-provider `config` map; SES uses `%{s3_fetcher: …, cert_cache_ttl_seconds: …}` (`ses_provider_test.exs:240`), Postmark/SendGrid use `%{basic_auth: …}`, Mailgun uses `%{signing_key: …}`.
   - What's unclear: how `receive_provider_payload/3` surfaces these — a single `config:` opt vs. per-provider defaults.
   - Recommendation: Accept a `config:` opt passed straight to `provider.verify!/2,3`; default SES `s3_fetcher:` to `S3Fetcher.Fake`. Mirror `plug.ex:404-434` dispatch. Settle exact opt shape during planning (Claude's Discretion per D-47).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Igniter | IGEN-01..04 generators | ✓ (vendored) | 0.8.0 (root), 0.7.9 (inbound) | — |
| Sourceror | IGEN-03 zipper | ✓ (Igniter dep) | ~> 1.4 | — |
| ExUnit | all four helpers | ✓ (OTP bundled) | bundled | — |
| `:public_key`/`:crypto` | SES SNS fixtures | ✓ (OTP bundled, in extra_applications) | OTP 27 | — |
| Postgres + `MailglassInbound.TestRepo` | library self-tests of `Test.Ingress`/`MailboxCase` | ✓ (CI inbound job; `mix ecto.create -r MailglassInbound.TestRepo`) | — | — |
| `Igniter.Test` harness | generator self-tests | ✓ (`deps/igniter/lib/igniter/test.ex`) | 0.8.0 | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none — the phase adds no new external dependency.

## Validation Architecture

> nyquist_validation is enabled (`.planning/config.json` → `workflow.nyquist_validation: true`). This phase is test-tooling, so validation = self-testing the helpers + compiling generator output + round-tripping fixtures through the REAL verifiers.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled) + `Igniter.Test` (for generators) + StreamData (optional, for fixture round-trips) |
| Config file | `mailglass_inbound/config/test.exs` (sets `:repo` → `TestRepo`, Sandbox pool); `mailglass_inbound/test/test_helper.exs` (migrates + starts TestRepo, `:manual` sandbox); core: `test/test_helper.exs` |
| Quick run command (inbound helpers) | `cd mailglass_inbound && mix test test/mailglass_inbound/<helper>_test.exs --seed 0` |
| Quick run command (generators) | `mix test test/mix/tasks/mailglass.gen.inbound_route_test.exs` (core package) |
| Full suite command | inbound: `cd mailglass_inbound && mix test --seed 0` (use `--seed 0` per MEMORY.md inbound-flake note); core: `mix test` (note ~57 unrelated Oban failures in worktrees per MEMORY.md — scope per-file) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ITEST-01 | 4 matcher styles each pass on a captured `{:inbound,…}` and fail otherwise | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs -x` | ❌ Wave 0 |
| ITEST-02 | each outcome assertion matches its atom, refutes the others | unit | same file | ❌ Wave 0 |
| ITEST-03 | routed_to matches the matched mailbox; no_match asserts `%{status: :no_match}` | unit | same file | ❌ Wave 0 |
| ITEST-04 | `assert_no_inbound_received/0` passes when nothing sent, fails when one is | unit | same file | ❌ Wave 0 |
| ITEST-05 | `MailboxCase` checks out sandbox on app-env repo, resets CertCache/S3Fake, no app-env leak | integration | `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_case_test.exs --seed 0` | ❌ Wave 0 |
| ITEST-06 | `Test.Ingress.receive_inbound/2` + `receive_provider_payload/3` converge (replay N → 1 record + 1 fresh run) | integration | `cd mailglass_inbound && mix test test/mailglass_inbound/test/ingress_test.exs --seed 0` | ❌ Wave 0 |
| ITEST-07 | each `Fixtures.build_*` payload round-trips through the REAL provider `verify!`/`normalize` to a valid `%InboundMessage{}`; SES signed payload passes `SES.verify!` | integration | `cd mailglass_inbound && mix test test/mailglass_inbound/fixtures_test.exs --seed 0` | ❌ Wave 0 |
| IGEN-01 | `gen.mailbox` creates mailbox + test stub + route; generated mailbox compiles | unit (Igniter.Test) | `mix test test/mix/tasks/mailglass.gen.mailbox_test.exs` | ❌ Wave 0 |
| IGEN-02 | `gen.inbound_router` creates a router with `use Router` + sample route that compiles | unit (Igniter.Test) | `mix test test/mix/tasks/mailglass.gen.inbound_router_test.exs` | ❌ Wave 0 |
| IGEN-03 | adds a route to an existing router; **run twice → `assert_unchanged`** (idempotency) | unit (Igniter.Test) | `mix test test/mix/tasks/mailglass.gen.inbound_route_test.exs` | ❌ Wave 0 |
| IGEN-04 | `--dry-run` produces a diff and writes nothing | unit (Igniter.Test) | covered in each gen test via diff/refute_creates | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the single helper/generator file's test (`mix test <file> --seed 0`).
- **Per wave merge:** inbound full suite `cd mailglass_inbound && mix test --seed 0` + core gen tests `mix test test/mix/tasks/`.
- **Phase gate:** both suites green (inbound `--seed 0`; core gen tasks per-file) + `mix compile --no-optional-deps --warnings-as-errors` green for inbound (the helpers must not reference optional deps) + `mix credo --strict` (custom checks) + docs-contract test passes with the new "Testing" group + `mix hex.build` dry check that the four modules are in the artifact.

### Wave 0 Gaps
- [ ] `mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs` — covers ITEST-01..04
- [ ] `mailglass_inbound/test/mailglass_inbound/mailbox_case_test.exs` — covers ITEST-05 (incl. "no app-env leak" + "repo resolves from app-env, not TestRepo literal")
- [ ] `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs` — covers ITEST-06 (incl. a SendGrid/SES dedupe replay per Pitfall 5)
- [ ] `mailglass_inbound/test/mailglass_inbound/fixtures_test.exs` — covers ITEST-07 (each payload through the real verifier; SES signed → `SES.verify!`)
- [ ] `test/mix/tasks/mailglass.gen.mailbox_test.exs` — covers IGEN-01 (core package, mirror `mailglass.gen.mailable_test.exs`)
- [ ] `test/mix/tasks/mailglass.gen.inbound_router_test.exs` — covers IGEN-02
- [ ] `test/mix/tasks/mailglass.gen.inbound_route_test.exs` — covers IGEN-03 (incl. idempotency + single-statement-body + dry-run cases)
- [ ] Framework install: none — ExUnit, Igniter.Test, StreamData all present.

## Security Domain

> `security_enforcement` is `null` in config (absent = enabled). This is a test-tooling phase; security relevance is narrow but real because Fixtures mints signing keys and primes a signature cache.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface added |
| V3 Session Management | no | n/a |
| V4 Access Control | yes (tenancy) | `MailboxCase` sets `Tenancy.put_current/1`; `Test.Ingress` persists tenant-scoped records — fixtures must carry a `tenant_id` so tests can't accidentally assert across tenants |
| V5 Input Validation | yes | Fixtures build provider payloads that flow through the REAL `verify!`/`normalize` (which validate); generators emit `route/2` opts validated by NimbleOptions (`router.ex:75`) |
| V6 Cryptography | yes | SES fixtures use `:public_key.generate_key`/`sign` (OTP crypto) — never hand-rolled. Keys are ephemeral, in-memory, per-test; NO `.pem` on disk (D-47-10) |
| V7 Errors & Logging | yes (PII) | Helpers must not log/embed PII in telemetry; failure messages may embed caller-supplied values in the adopter's own test output only (mirrors outbound `test_assertions.ex:47-52`) |

### Known Threat Patterns for {test helpers + generators on Elixir}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Real-PII `.eml` fixtures committed to git | Information Disclosure | Code-built fixtures only; locked anti-pattern (D-47-11) |
| Signed-fixture keypair reused/leaked into the artifact | Spoofing / Info Disclosure | Ephemeral in-memory keypair per `Fixtures` call; never written to disk; never shipped |
| Generated mailbox stub enables open/click tracking on auth flows | Tampering | n/a inbound (no tracking surface), but generated test stub should use neutral `:accept`; no auth heuristics |
| `MailboxCase` leaks a global app-env value across tests | Tampering (test pollution) | D-47-12: MailboxCase writes NO async-mode app-env key (sync `execute/2` structurally); only ETS reset + sandbox stop — no leak surface to begin with |
| Cross-tenant assertion in tests | Elevation/Access Control | Fixtures default a `tenant_id`; `Test.Ingress` honors it; assertions read the captured message's tenant |
| Telemetry PII via helper code | Information Disclosure | Helpers emit no telemetry; the underlying `execute/2`/`persist/2` spans are already PII-whitelisted (covered by `NoPIIInTelemetry` Credo check, TELE-06) |

## Project Constraints (from CLAUDE.md)

- **Adopter-exported test helpers live in `lib/`** (the `Mailglass.TestAssertions` precedent); internal-never-shipped helpers stay in `test/support/`. → D-47-01 ships the four in `lib/`; `TestRepo` correctly stays in `test/support/`.
- **No `name: __MODULE__` singletons in library code.** → The helpers and generators must not register named processes. (Inbound TestRepo already honors this: "never uses `name: __MODULE__`".)
- **Errors as a public API contract** — closed `:type` atom set, pattern-match by struct not message. → Any new error surfaced by helpers/generators must follow the `%Mailglass.Error{}` / `MailglassInbound.SignatureError` contract; assertion failure messages are ExUnit `flunk`/`assert`, not domain errors.
- **Telemetry: never PII; handlers that raise must not break business logic.** → Helpers emit no telemetry; don't add any that carries `:to`/`:from`/`:subject`/etc.
- **Append-only `mailglass_inbound_records`** — UPDATE/DELETE raises; TRUNCATE CASCADE is the only bulk reset (`inbound_idempotency_convergence_test.exs:140-147`). → `Test.Ingress`/`MailboxCase` rely on Sandbox rollback, not DELETE; any bulk-reset helper must TRUNCATE CASCADE.
- **Optional deps gated through gateway modules; `mix compile --no-optional-deps --warnings-as-errors` is mandatory.** → The four `lib/` helpers must reference NO optional-dep module directly (Pitfall 6).
- **Custom Credo checks at lint time.** → Run `mix credo --strict` + the relevant `test/mailglass/credo/` if any check touches the new files; per MEMORY.md, validate by running Credo, not grep.
- **Sibling packages with linked-version releases.** → New inbound `lib/` modules raise the inbound surface; ensure `mailglass_inbound/mix.exs` ExDoc + docs-contract test cover them (the modified `test/mailglass/docs_contract_test.exs` in git status is the outbound contract — the inbound one is `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`).
- **Brand voice in errors/messages.** → Assertion `flunk` messages should be specific and composed ("No inbound message received in this test process"), never "Oops!".
- **`mailglass_inbound` is outside the `v1.x` stability promise for now** — but these helpers ARE adopter-facing and ship to Hex; treat their signatures as a contract within v1.2.

## Sources

### Primary (HIGH confidence)
- `deps/igniter/` (vendored Igniter 0.8.0) — `usage-rules.md`, `lib/igniter/project/module.ex` (`find_and_update_module/3`, `create_module/4`), `lib/igniter/code/common.ex` (`add_code/3`, `move_to_do_block/1`), `lib/igniter/code/function.ex` (`move_to_function_call_in_current_scope/4`, `argument_equals?/3`, `function_call?/3`), `lib/mix/task/info.ex` (@global_options dry_run), `lib/igniter/test.ex` (test harness). Version confirmed `0.8.0` (`deps/igniter/mix.exs:8`, `mix.lock`). 0.7.9 vs 0.8.0 diff: relevant functions byte-identical, usage-rules identical.
- `mailglass_inbound/lib/mailglass_inbound/` — `execution.ex` (execute/2 sync, no `_impl` key), `optional_deps.ex` (runner/0 reads `:async_adapter`), `ingress/persist.ex` (persist/2 signature + dedupe), `router.ex` (DSL + reflection), `router/matcher.ex`, `mailbox.ex` (outcome atoms), `repo.ex` (app-env repo facade), `ingress/plug.ex` (provider dispatch + handoff + PubSub), `ingress/providers/{postmark,sendgrid,mailgun,ses}.ex` (payload shapes + verify!/normalize arities), `ingress/provider.ex` (behaviour), `s3_fetcher/fake.ex` (process-dict isolation), `ingress/request.ex`.
- `mailglass_inbound/test/` — `support/test_repo.ex` (TestRepo location collision evidence), `test_helper.exs`, `mailglass_inbound/ingress/ses_provider_test.exs:1-352` (signed-SNS helpers + seams), `mailglass_inbound/properties/inbound_idempotency_convergence_test.exs:60-190` (persist→sync-execute driver), async posture across the suite.
- `mailglass_inbound/mix.exs` — `files:` manifest (`:113`), ExDoc grouping (`:133-143`), deps (no `:ex_unit`).
- `mailglass_inbound/config/test.exs` — `:repo` → TestRepo, Sandbox pool.
- core `mailglass/` — `lib/mailglass/test_assertions.ex` (4-style macros + `{:mail,_}` capture), `test/support/mailer_case.ex:100-209` (HI-01 snapshot structure), `lib/mix/tasks/mailglass.gen.mailable.ex` (creation precedent), `lib/mix/tasks/mailglass.upgrade.v0_2.ex` (zipper + dry-run-default precedent), `lib/mix/tasks/mailglass.install.ex` (the WRONG, non-Igniter precedent), `test/mix/tasks/mailglass.gen.mailable_test.exs` (Igniter.Test self-test pattern), `lib/mailglass/webhook/providers/ses/cert_cache.ex` + `cert_cache/table_owner.ex` (process-global ETS), `test/support/webhook_fixtures.ex:194-228` (outbound SNS keypair), `mix.exs` (extra_applications, igniter dep).
- `.planning/config.json` — nyquist_validation true, security_enforcement null.

### Secondary (MEDIUM confidence)
- CONTEXT.md D-47-01..13 (cross-checked against code; one location claim corrected).
- MEMORY.md notes (inbound suite flake → `--seed 0`; Credo via run-not-grep; bare `mix test` worktree failures).

### Tertiary (LOW confidence)
- A1 (PubSub server name) — inferred from CONTEXT integration-points; not directly read this session. Flagged for Wave 0 confirmation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every library already locked; versions read from mix.lock.
- Architecture (capture seam, MailboxCase, Test.Ingress): HIGH — grounded in the exact outbound analog + the inbound execute/2/persist/2 signatures.
- IGEN-03 zipper idiom: HIGH — functions read from vendored 0.8.0 source and confirmed identical in 0.7.9; two execution subtleties flagged with self-tests.
- D-47-12 resolution: HIGH — `grep` + source read confirm no `:async_execution_impl`; the snapshot-nothing conclusion is structural.
- TestRepo collision: HIGH — `find`/`ls` evidence is unambiguous.
- Pitfalls: HIGH — each is anchored to a specific code line or a documented existing flake.
- PubSub name (A1): LOW — the one un-read detail; non-blocking (capture is `send`-based).

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 (30 days — stable; Igniter is vendored so no drift risk, and the inbound runtime modules are shipped/frozen for v1.2)
