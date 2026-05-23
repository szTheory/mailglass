# Phase 47: Inbound Test Helpers + Generators - Context

**Gathered:** 2026-05-23 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

An adopter writing their first mailbox gets **full DX parity with outbound**:
`use MailglassInbound.MailboxCase`, call `assert_inbound_accepted/1` (or one of 4
matcher styles), drive the **real** persist+route+execute path with
`MailglassInbound.Test.Ingress`, build provider payloads **in code** (no `.eml`
files), and scaffold mailbox/router/route via **Igniter** generators.

**In scope:** ITEST-01..07 (test helpers) + IGEN-01..04 (generators) — 11 REQs.

**Out of scope (later phases):**
- Inbound admin LiveView (the consumer of these test helpers' patterns) → Phase 48.
- Operator tooling (`mailglass.inbound.{doctor,replay,prune}`) → Phase 49.
- Inbound testing/generator **docs** (`docs/inbound-testing.md`) → Phase 50 (IDOC-02).
- Any new provider, new crypto, new persistence behavior — Phase 46 shipped those.

This phase ships **test ergonomics + scaffolding**, not runtime features or UI.
</domain>

<decisions>
## Implementation Decisions

### Area 1 — Module packaging (lib vs test/support, which package)
- **D-47-01:** All four adopter-facing helpers ship in **`mailglass_inbound/lib/`**
  (packaged to Hex via the existing `files: ~w(lib …)` manifest at
  `mailglass_inbound/mix.exs:113`) — NOT `test/support/`:
  - `MailglassInbound.TestAssertions` (ITEST-01..04)
  - `MailglassInbound.MailboxCase` (ITEST-05, an `ExUnit.CaseTemplate`)
  - `MailglassInbound.Test.Ingress` (ITEST-06)
  - `MailglassInbound.Fixtures` (ITEST-07)
  This is the one deliberate **extension beyond outbound parity**: outbound is
  asymmetric — `Mailglass.TestAssertions` ships in `lib/` (its moduledoc says so
  explicitly) but `Mailglass.MailerCase` lives **only** in `test/support/` and is
  NOT in core's package manifest. ITEST-05 + IGEN-01's generated test stub both
  require adopters to `use MailglassInbound.MailboxCase`, which only works if the
  module is in the shipped artifact. Swoosh sets the same upstream precedent
  (ships `Swoosh.TestAssertions`, no case template).
- **D-47-02:** ExDoc-group the four under a new **"Testing"** group, slotting into
  the existing `Stable`/`Internal` grouping (`mailglass_inbound/mix.exs:133-143`).
  Keep them dependency-light: `ExUnit.CaseTemplate`/`ExUnit.Assertions` are
  available in the adopter's `:test` env — **no `:ex_unit` runtime dep** needed.

### Area 2 — `Test.Ingress` fake-provider seam (the real write path)
- **D-47-03:** `MailglassInbound.Test.Ingress` drives the **production write path**
  by calling `MailglassInbound.Ingress.Persist.persist/2` (DB unique-index dedupe)
  then `MailglassInbound.Execution.execute/2` (**sync**) directly. It does **NOT**
  fake a `Plug.Conn` through `Ingress.Plug`, and there is **no new
  `trigger_event/3`-style shim** — the "single fake-provider seam" is the existing
  provider `verify!`/`normalize` + `Persist` + `Execution` chain plus the opt
  injection already present in the plug/providers (`provider_module:`, `routes:`/
  `router:`/`repo:`, SES `s3_fetcher:`).
- **D-47-04:** Two entry points:
  - `receive_inbound/2` — takes a `%InboundMessage{}` (or `Fixtures`-built message)
    + `router:`/`routes:` opt → persist + sync execute.
  - `receive_provider_payload/3` — takes a raw provider payload, runs the **real**
    provider `verify!`/`normalize` seam, then the same persist+execute path.
  Both mirror the shipped 1000-replay convergence proof
  (`test/mailglass_inbound/properties/inbound_idempotency_convergence_test.exs:99-102`),
  which drives `execute/2` sync precisely because async `dispatch/2`
  (Oban/Task.Supervisor) yields non-deterministic `ExecutionRun` counts.
- **D-47-05:** The outbound `Mailglass.Adapters.Fake.trigger_event/3` analogy
  (`lib/mailglass/adapters/fake.ex:169-195`) is **shape-different** — it simulates
  a downstream webhook event on an already-delivered message. Inbound has no
  "delivery row to look up," so do not force that shape onto `Test.Ingress`.

### Area 3 — Generators (Igniter source-editing vs file writes, placement)
- **D-47-06:** All three generators are **Igniter mix tasks** (`use
  Igniter.Mix.Task`) and live in **core `mailglass/lib/mix/tasks/`** alongside the
  existing `mailglass.gen.*` family — NOT in `mailglass_inbound`. Rationale: every
  one of the 12 existing mix tasks lives in core; `mailglass_inbound` declares no
  Igniter dep (`mailglass_inbound/mix.exs:65-92`), whereas root `mix.exs:164`
  declares `{:igniter, "~> 0.7", runtime: false}` (resolved 0.8.0). Generators
  reference inbound modules via string templates, so cross-package placement buys
  nothing.
- **D-47-07:** `gen.mailbox` (IGEN-01) and `gen.inbound_router` (IGEN-02) use
  Igniter **creation** (`Igniter.Project.Module.create_module` +
  `Igniter.create_new_file`), exactly like `mailglass.gen.mailable.ex:10-61`.
  `gen.mailbox` scaffolds: mailbox module (behaviour + default `process/1`
  callback) + a `route/2` stub in the configured router + an ExUnit test stub that
  `use MailglassInbound.MailboxCase`.
- **D-47-08:** `gen.inbound_route` (IGEN-03) uses Igniter **Sourceror-zipper
  source-editing** to insert a `route/2` clause into an **existing** router module
  **idempotently** — find the `defmodule` that has `use MailglassInbound.Router`,
  append a `route(Mailbox, recipient: …, subject: …, headers: …)` node as the last
  statement in its body, after a pre-check that scans existing `route/2` nodes for
  the same mailbox+pattern (no duplicate insert on re-run). Precedent for the
  zipper edit + dry-run is `mailglass.upgrade.v0_2.ex:33-88`. The router DSL target
  is the `@mailglass_inbound_routes` accumulator + `route/2` macro +
  `__before_compile__` at `mailglass_inbound/lib/mailglass_inbound/router.ex:39-72`.
- **D-47-09:** `--dry-run` (IGEN-04) comes **free from Igniter's built-in flag**
  (with `use Igniter.Mix.Task`), reinforced by the
  `Igniter.assign(igniter, :dry_run?, true)` force-pattern in `upgrade.v0_2.ex`.
  IGEN-04's wording "matching `mix mailglass.install` v0.5 hardening" describes the
  *DX intent* (preview before apply) — but `install.ex` uses a bespoke
  `Installer.Plan`/`Apply` engine; do **not** copy that engine. Igniter's `--dry-run`
  is the correct, simpler precedent (`gen.mailable` + `upgrade.v0_2` already use it).

### Area 4 — SES SNS signed fixture (ITEST-07)
- **D-47-10:** `MailglassInbound.Fixtures.build_ses_sns_payload/1` builds a valid
  X.509-signed SNS notification **entirely in code**: mint a fresh RSA-2048
  keypair, build the SNS envelope, compute the byte-sorted canonical string, sign
  with `:public_key.sign(canonical, :sha, private_key)`, base64 into `"Signature"`,
  and **prime the real `Mailglass.Webhook.Providers.SES.CertCache.put/3`** so
  `fetch_public_key/1` is a cache hit (skips the `:httpc` cert fetch). There is
  **NO `.pem` on disk** and **NO `CertCache.Fake`** (it does not exist anywhere in
  the repo). Extract the proven helpers from
  `mailglass_inbound/test/mailglass_inbound/ingress/ses_provider_test.exs:287-352`
  (`sign_notification`, `canonical_string`, `sign_canonical`,
  `generate_sns_keypair`); outbound's `test/support/webhook_fixtures.ex:194-246`
  uses the identical approach. The SES Action:S3 body path is served by the
  already-shipped `MailglassInbound.S3Fetcher.Fake` via the `s3_fetcher:` config
  seam — no AWS needed.
- **D-47-11:** `Fixtures` also builds: canonical `%InboundMessage{}`, Postmark JSON,
  SendGrid form-encoded, and Mailgun multipart payloads — all from code, **no
  `.eml` files** in `test/fixtures/` (avoids real-PII commits, the locked
  anti-pattern in REQUIREMENTS.md "Out of Scope").

### ROADMAP corrections (verified against code — supersede the ROADMAP framing)
- **D-47-12:** **`:async_execution_impl` does not exist** in either package. The
  outbound HI-01 snapshot/restore (`test/support/mailer_case.ex:120-204`) snapshots
  `:async_adapter` + `:async_adapter_impl`; inbound selects its runner via
  `MailglassInbound.OptionalDeps.Oban.runner()` (Oban vs Task.Supervisor,
  `execution.ex:21`) with **no global `_impl` key**. `MailboxCase`'s real job is to
  make **sync `execute/2` the default test path** and snapshot/restore whatever
  app-env the fixtures actually mutate (e.g. SES `:s3_fetcher` / `:s3_retry_opts`,
  any Oban testing-mode global) — NOT to snapshot a nonexistent key. The planner
  must confirm the exact global state to snapshot (see canonical_refs research note).
- **D-47-13:** **`SES.CertCache.Fake` does not exist** — the ROADMAP "hardest
  sub-task" assumed one. Superseded by D-47-10 (in-memory keypair + real
  `CertCache.put/3`).

### Claude's Discretion
- Exact `TestAssertions` macro/function signatures and the message-capture
  mechanism (process-dictionary mailbox vs PubSub subscription vs ETS), provided
  the 4 matcher styles + outcome + routing + negative assertions all work in the
  test process scope.
- Exact `Test.Ingress` opt names and return shape, provided it drives sync
  `execute/2` on the real persist path.
- Exact generated template contents (mailbox/router/route/test stubs).
- Exact `Fixtures` function names and option shapes.
- Exact app-env keys `MailboxCase` snapshots (pending the D-47-12 confirmation).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked posture
- `.planning/ROADMAP.md` — Phase 47 goal, success criteria, hardest sub-tasks
  (note: two of its "hardest sub-task" premises are corrected by D-47-12/13).
- `.planning/REQUIREMENTS.md` — ITEST-01..07, IGEN-01..04 exact wording.
- `.planning/PROJECT.md` — fake-adapter-first (D-13), no-`.eml`-on-disk posture,
  one-maintainer honesty, errors-as-contract.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, recommendation-first.
- `.planning/STATE.md` — current v1.2 milestone position.
- `.planning/phases/45-inbound-telemetry-idempotency-foundation/45-CONTEXT.md` —
  the sync `execute/2` vs async `dispatch/2` distinction + PubSub topic
  (`MailglassInbound.PubSub.Topics.inbound_record_inserted/1`) MailboxCase subscribes to.
- `.planning/phases/46-mailgun-ses-inbound-ingress/46-CONTEXT.md` — the provider
  payload shapes Fixtures must build + the SES `s3_fetcher:` / `CertCache` seams.

### Outbound DX assets to mirror (code anchors)
- `lib/mailglass/test_assertions.ex` — the 4 matcher styles + assertion API ITEST-01..04 mirror;
  moduledoc explains why it lives in `lib/` (adopter-exported).
- `test/support/mailer_case.ex` — ESPECIALLY lines 120-204 (HI-01 snapshot/restore
  of `:async_adapter`/`:async_adapter_impl`) — structural template for MailboxCase,
  but adapt per D-47-12 (no `:async_execution_impl`; inbound makes sync `execute/2` default).
- `lib/mailglass/adapters/fake.ex` (+ `fake/storage.ex`, `fake/supervisor.ex`) —
  the `trigger_event/3` seam; note D-47-05 (shape-different, do not force onto Test.Ingress).
- `test/support/fixtures.ex`, `test/support/webhook_fixtures.ex` (esp. lines 194-246,
  RSA keypair + canonical SNS sign + `CertCache.put`), `test/support/fake_fixtures.ex`
  — outbound fixture patterns ITEST-07 mirrors.

### Generators to mirror (code anchors)
- `lib/mix/tasks/mailglass.gen.mailable.ex` — the `use Igniter.Mix.Task` +
  `create_module` + `create_new_file` creation precedent for gen.mailbox/gen.inbound_router.
- `lib/mix/tasks/mailglass.upgrade.v0_2.ex` (lines 33-88) — the ONLY existing
  Sourceror-zipper source-editing + `--dry-run` precedent; the model for gen.inbound_route.
- `lib/mix/tasks/mailglass.install.ex` — IGEN-04 names its v0.5 `--dry-run`
  hardening, but its bespoke `Installer.Plan`/`Apply` engine is the WRONG precedent
  for Igniter generators; use Igniter's built-in `--dry-run` instead.
- `lib/mix/tasks/mailglass.gen.migration.ex`, `mailglass.gen.unsubscribe.ex` —
  additional generator precedents.

### Inbound package surface (targets)
- `mailglass_inbound/lib/mailglass_inbound/router.ex` (lines 39-72) — the
  `@mailglass_inbound_routes` accumulator + `route/2` macro + `__before_compile__`
  the generators scaffold/edit + the `__mailglass_inbound_routes__/0` reflection
  ITEST-03 routing assertions read.
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` — how routing match
  works (routing assertions).
- `mailglass_inbound/lib/mailglass_inbound/mailbox.ex` (line 22) — LOCKED outcome
  atoms `:accept | :ignore | {:reject, reason} | {:bounce, reason}`; ITEST-02 maps
  accepted→:accept, rejected→{:reject,_}, ignored→:ignore, bounced→{:bounce,_}.
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` — `execute/2` (sync, the
  real write path Test.Ingress drives) vs `dispatch/2` (async).
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` — `persist/2` (DB
  unique-index dedupe, the first half of the Test.Ingress chain).
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/{postmark,sendgrid,mailgun,ses}.ex`
  — payload shapes Fixtures must build.
- `mailglass_inbound/lib/mailglass_inbound/s3_fetcher/fake.ex` — the SES S3 fake
  Fixtures' SES Action:S3 path uses via the `s3_fetcher:` seam.
- `mailglass_inbound/lib/mailglass_inbound/test_repo.ex` — inbound already has a
  TestRepo in `lib/` (not test/support); existing inbound test setup convention.
- `mailglass_inbound/test/mailglass_inbound/ingress/ses_provider_test.exs` (lines
  26-352) — the proven code-built X.509-signed SNS fixture helpers to extract into Fixtures.
- `mailglass_inbound/test/mailglass_inbound/properties/inbound_idempotency_convergence_test.exs`
  (lines 99-102) — the canonical persist→sync-execute driver Test.Ingress mirrors.
- `mailglass_inbound/mix.exs` (lines 113, 133-143) — `files:` package manifest +
  ExDoc grouping the four helpers slot into.
- `mailglass_inbound/lib/mailglass_inbound/optional_deps/oban.ex` — `runner()`
  selection (the real async seam, replacing the mythical `:async_execution_impl`).

### Research notes for the phase researcher (plan-phase)
- **Igniter 0.8 source-editing idiom for IGEN-03:** confirm the exact 0.8 API for
  "find the `defmodule` with `use MailglassInbound.Router` and append a `route/2`
  call as the last body statement, idempotently." Candidates:
  `Igniter.Project.Module.find_and_update_module`, `Igniter.Code.Common.add_code`,
  zipper navigation. Vendored at `mailglass_inbound/deps/igniter/` (read
  `usage-rules.md`, `lib/igniter/code/common.ex`, `lib/igniter/project/module.ex`)
  — repo-local, not a web task.
- **D-47-12 confirmation:** identify the exact global app-env `MailboxCase` must
  snapshot/restore (SES `:s3_fetcher`/`:s3_retry_opts`, Oban testing-mode global) —
  there is NO `:async_execution_impl` key. Repo-internal clarification.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.TestAssertions` (lib/, adopter-exported) is the direct API template
  for the 4 matcher styles + outcome/negative assertions.
- `Mailglass.MailerCase` (test/support/) lines 120-204 give the HI-01
  snapshot/restore *structure* — adapt the keys per D-47-12.
- The shipped 1000-replay convergence proof is a working `persist → sync execute`
  driver — Test.Ingress generalizes it.
- `ses_provider_test.exs:287-352` + `webhook_fixtures.ex:194-246` are working
  code-built X.509-signed SNS fixtures — extract, don't reinvent.
- `mailglass.gen.mailable.ex` (creation) + `mailglass.upgrade.v0_2.ex`
  (source-editing) are the two Igniter precedents the generators split across.
- `S3Fetcher.Fake` + the `s3_fetcher:` config seam already serve SES S3 bodies
  in tests.
- `MailglassInbound.TestRepo` already exists in `lib/` — inbound's established
  test-repo convention.

### Established Patterns
- Fake-adapter-first (D-13): the in-memory/fake path is the test default.
- Adopter-exported test helpers live in `lib/` (TestAssertions precedent); only
  internal-never-shipped helpers stay in `test/support/`.
- Generators are Igniter mix tasks in core `lib/mix/tasks/`; `--dry-run` is an
  Igniter built-in.
- Drive sync `execute/2` in tests, never async `dispatch/2` (non-deterministic).
- No `.eml`/no real-PII fixtures on disk — build payloads from code.
- Inbound-local closed-type errors; LOCKED mailbox outcome atoms.

### Integration Points
- `MailboxCase` → ExUnit.CaseTemplate + sandbox (`MailglassInbound.TestRepo`) +
  PubSub subscription (`MailglassInbound.PubSub.Topics.inbound_record_inserted/1`,
  Phase 45) + per-test fixtures + app-env snapshot/restore.
- `Test.Ingress` → `Ingress.Persist.persist/2` → `Execution.execute/2` (sync);
  `receive_provider_payload/3` also → provider `verify!`/`normalize` seam.
- `Fixtures` → provider payload builders + `SES.CertCache.put/3` (signed SNS) +
  `S3Fetcher.Fake` (SES S3 body).
- Generators → Igniter (root dep) → core `lib/mix/tasks/`; gen.inbound_route →
  Sourceror-zipper edit of `MailglassInbound.Router` DSL.
- `TestAssertions` routing assertions → `__mailglass_inbound_routes__/0` reflection +
  `Router.Matcher`.
</code_context>

<specifics>
## Specific Ideas

- Mental model: Phase 47 is the **inbound sibling of outbound's test DX** —
  `TestAssertions`/`MailerCase`/`gen.mailable` — but with one deliberate upgrade:
  the case template is **shipped** (outbound never shipped `MailerCase`), because
  ITEST-05 promises adopters `use MailglassInbound.MailboxCase`.
- The single highest-risk trap is copying outbound's HI-01 snapshot of
  `:async_adapter_impl` and inventing a parallel `:async_execution_impl` for
  inbound — that key does not exist. MailboxCase makes sync `execute/2` the default
  and snapshots the SES/Oban app-env the fixtures actually touch (D-47-12).
- The second trap is reaching for a nonexistent `SES.CertCache.Fake`; the real
  path is an in-memory RSA keypair primed into the real `CertCache` (D-47-10).
- One public-contract decision is locked here to the recommended default: shipping
  `MailglassInbound.MailboxCase` (+ the other three helpers) in `lib/` so they land
  in the Hex package (D-47-01). Confirmed by the project owner.
</specifics>

<deferred>
## Deferred Ideas

- `docs/inbound-testing.md` documenting these helpers (IDOC-02) → Phase 50.
- Admin LiveView that consumes the routing-trace patterns → Phase 48.
- A synthetic-inbound dev tool (Conductor-style) → deferred to v1.2.1 (security
  design pass needed) per STATE.md.
- Broader fixture fuzzing beyond the canonical provider shapes — not needed for
  this phase's DX goal.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 47 scope.
</deferred>

---

*Phase: 47-inbound-test-helpers-generators*
*Context gathered: 2026-05-23 (assumptions mode)*
