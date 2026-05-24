---
phase: 47-inbound-test-helpers-generators
plan: 04
subsystem: mailglass_inbound (test helpers)
tags: [inbound, test-helpers, mailbox-case, case-template, packaging, exdoc, docs-contract]
requires:
  - MailglassInbound.TestAssertions (Plan 03 — imported by the using-block)
  - MailglassInbound.Test.Ingress (Plan 03 — capture driver used in self-tests)
  - MailglassInbound.Fixtures (Plan 01 — code-built message builder)
  - Application.get_env(:mailglass_inbound, :repo) (adopter repo facade resolution)
  - Mailglass.Webhook.Providers.SES.CertCache.reset/0 (process-global ETS reset)
  - MailglassInbound.S3Fetcher.Fake.reset/0 (process-dict reset)
  - Mailglass.Tenancy.put_current/1
  - Mailglass.PubSub (core server) + MailglassInbound.PubSub.Topics.inbound_record_inserted/1
provides:
  - MailglassInbound.MailboxCase (ExUnit.CaseTemplate, ITEST-05)
  - mix.exs ExDoc "Testing" group for the four adopter-facing helpers (D-47-02)
  - docs-contract assertion that the four Testing helpers are documented
affects:
  - mailglass_inbound Hex package (MailboxCase ships in lib/; the four helpers grouped under a Testing ExDoc surface)
  - Phase 50 docs pass (the README/api_stability Testing section is the seed)
tech-stack:
  added: []
  patterns:
    - ExUnit.CaseTemplate that resolves the adopter repo from app-env (never a TestRepo literal)
    - Case template that snapshots NO app-env (inbound sync execution is structural via Test.Ingress)
    - Best-effort PubSub subscribe to the CORE Mailglass.PubSub server (the inbound plug's broadcast target)
    - Source-literal invariants enforced by self-test (refute source =~ "TestRepo" / "async_*_impl")
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex
    - mailglass_inbound/test/mailglass_inbound/mailbox_case_test.exs
  modified:
    - mailglass_inbound/mix.exs
    - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
    - mailglass_inbound/docs/api_stability.md
    - mailglass_inbound/README.md
decisions:
  - "MailboxCase snapshots/restores NO application-env key (D-47-12): inbound achieves synchronous execution structurally via Test.Ingress driving execute/2, so there is no async-mode key to flip and therefore no leak surface — only ETS/process-dict resets + Sandbox.stop_owner."
  - "The forbidden literals (TestRepo, async_adapter_impl/async_execution_impl) were scrubbed from the SOURCE entirely — including moduledoc prose and comments — because the threat-model invariant (T-47-13/14) and the self-test assert their literal absence, not merely their semantic absence."
  - "PubSub subscription is wrapped best-effort (try/rescue/catch): the send-based capture from Test.Ingress is the primary assertion path, so adopters who do not run a PubSub server must not have setup fail."
  - "The MailboxCase self-test drives one capture per assert_* call (assert_received consumes one tuple each) and uses distinct provider_message_ids so the second drive is a fresh :accept, not a deduped :skipped — mirrors the Test.IngressTest discipline."
metrics:
  duration: ~20m
  completed: 2026-05-24
  tasks: 2
  files: 6
---

# Phase 47 Plan 04: MailboxCase + Testing Helpers Packaging Summary

`MailglassInbound.MailboxCase` (ITEST-05) — the shipped `ExUnit.CaseTemplate`
adopters `use` — ties Plans 01/03 into adopter DX: the `using` block imports
`TestAssertions` and aliases `Fixtures`/`Test`, setup checks out an Ecto sandbox
on the adopter's app-env repo (never a `TestRepo` literal), sets tenancy, resets
the only process-global state the inbound fixtures touch (CertCache ETS +
S3Fetcher.Fake process-dict), and — critically — snapshots **no** app-env key
because inbound sync execution is structural. All four Testing helpers now ship
to Hex under a new ExDoc "Testing" group asserted by the docs-contract test.

## What Was Built

**Task 1 — `MailglassInbound.MailboxCase`** (`feat` b7bf5e5)
- `use ExUnit.CaseTemplate` with a `using do quote do … end` injecting
  `import MailglassInbound.TestAssertions` and `alias MailglassInbound.{Fixtures, Test}`.
- `setup tags do … end`:
  1. Resolve `repo = Application.get_env(:mailglass_inbound, :repo) || raise …`
     (no `TestRepo` literal — Pitfall 1 / T-47-14), then
     `Sandbox.start_owner!(repo, shared: not tags[:async])`.
  2. Tenancy from `@tag tenant:` (`:unset → nil`, default `"test-tenant"`) →
     `Mailglass.Tenancy.put_current/1`.
  3. Reset `Mailglass.Webhook.Providers.SES.CertCache` (ETS) and
     `MailglassInbound.S3Fetcher.Fake` (process-dict) every setup (T-47-16).
  4. Snapshot/restore NOTHING in app-env (D-47-12 / T-47-13).
  5. Best-effort `Phoenix.PubSub.subscribe(Mailglass.PubSub,
     MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id))` —
     server name `Mailglass.PubSub` (Correction B), wrapped try/rescue/catch.
  6. `on_exit` → `Sandbox.stop_owner(pid)`.
- Ships in `lib/`; references only core/runtime modules (no Oban/ExAws/Plug.Test —
  Pitfall 6). No `name: __MODULE__` singleton.
- Self-test (`mailbox_case_test.exs`) covers all three locked assertions:
  (1) a `Test.Ingress` capture persists + asserts inside the case with no
  connection error (proving the app-env-repo checkout works), (2) the MailboxCase
  source contains no `TestRepo` literal and resolves the repo from app-env,
  (3) no app-env leak — env unchanged across a case run and no `:async_*` key set
  by the case (plus the source carries no async-snapshot machinery).

**Task 2 — packaging + docs-contract** (`feat` f62d3ae)
- `mix.exs`: new `Testing:` group in `groups_for_modules` listing
  `TestAssertions`, `MailboxCase`, `Test.Ingress`, `Fixtures`, between `Stable:`
  and `Internal:`. No `:ex_unit` dep added; the `lib` glob already ships all
  four (including the nested `lib/mailglass_inbound/test/ingress.ex`).
- `docs_contract_test.exs`: new test asserts the four Testing modules appear in
  README + api_stability.md (mirrors the stable-module loop).
- `api_stability.md` + `README.md`: a `testing` surface section documenting the
  four helpers (keeps the docs-contract assertion satisfied and seeds Phase 50).

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_case_test.exs test/mailglass_inbound/docs_contract_test.exs --seed 0` → **15 tests, 0 failures**.
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` → **exit 0** (MailboxCase references no Oban/ExAws/Plug.Test).
- `MIX_PUBLISH=true mix hex.build --unpack` → all four Testing helpers present under `lib/`: `fixtures.ex`, `mailbox_case.ex`, `test_assertions.ex`, and the nested `test/ingress.ex`. No manifest gap.
- No `:ex_unit` dep in `mix.exs` (D-47-02).
- Acceptance greps on `mailbox_case.ex`: no `TestRepo` literal; `Application.get_env(:mailglass_inbound, :repo)` present with raise-if-unset; no `async_execution_impl`/`async_adapter_impl`; no `MailglassInbound.PubSub` server reference (subscribe targets `Mailglass.PubSub`); both `CertCache.reset`/`S3Fetcher.Fake.reset` present; no `name: __MODULE__`.
- `mix format --check-formatted` → clean on all six files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `-x` is not a supported `mix test` flag in this Elixir version**
- **Found during:** Task 1 verification.
- **Issue:** The plan's `<verify>` used `mix test … -x`; this Elixir rejects `-x` ("Unknown option").
- **Fix:** Ran the same verification with `--max-failures 1` (the modern equivalent) during iteration, and `--seed 0` for the final green. No production code affected.
- **Files modified:** none.

**2. [Rule 1 - Test correctness] One capture per `assert_*` + distinct messages per drive**
- **Found during:** Task 1 GREEN run.
- **Issue:** `assert_inbound_received/1` and `assert_inbound_accepted/0` each consume one `{:inbound, …}` tuple via `assert_received`; a single drive left the second assertion with nothing to read. A naive fix (re-driving the SAME message) deduped to `%{status: :skipped}`, so `assert_inbound_accepted/0` then saw a non-`:accept` outcome.
- **Fix:** Drive one capture per assertion, and use a distinct `provider_message_id` for the second drive so it is a fresh `:accept` run (mirrors the `Test.IngressTest` discipline documented in the Plan 03 summary).
- **Files modified:** `test/mailglass_inbound/mailbox_case_test.exs`.
- **Commit:** b7bf5e5.

**3. [Rule 1 - Invariant] Scrubbed forbidden literals from moduledoc/comments**
- **Found during:** Task 1 GREEN run.
- **Issue:** The self-test (and threat invariants T-47-13/14) assert the SOURCE contains no literal `TestRepo`, `async_adapter_impl`, or `async_execution_impl`. My first-draft moduledoc/comment prose mentioned `MailglassInbound.TestRepo` (explaining why self-tests work) and `:async_adapter_impl` (contrasting with `Mailglass.MailerCase`), tripping `refute source =~ …`.
- **Fix:** Rephrased the moduledoc + comments to avoid the literal tokens entirely while preserving the explanation (e.g. "the support repo under `test/support`", "its async-mode application-env keys"). The meaning is unchanged; the literal invariant is now satisfied.
- **Files modified:** `lib/mailglass_inbound/mailbox_case.ex`.
- **Commit:** b7bf5e5.

### Notes
- `mix deps.get` was run in the fresh worktree before the first test (fetches only already-locked deps — not a package install; `mix.lock` unchanged). Same posture as Plans 01/03; executors exclude `mix.lock` and the orchestrator owns lockfile integration.
- The MailboxCase self-test (`mailbox_case_test.exs`) was authored and committed under Task 1 (its `<verify>` runs it). Task 2 added only the packaging + docs-contract files; the self-test was already in place.

## Known Stubs

None. `MailboxCase` drives the real persist + sync-execute seam through
`Test.Ingress` and the real app-env repo resolution; no placeholder/empty/mock
data path exists.

## Threat Flags

None. No new network endpoint, auth path, or schema surface is introduced beyond
the plan's threat register (T-47-13..16), all mitigated as designed: MailboxCase
writes no app-env key (no leak surface — T-47-13), resolves the repo from app-env
with the `TestRepo` literal forbidden in source and self-test-asserted absent
(T-47-14), grows the public Hex surface only by the four intended adopter-facing
helpers confirmed via `mix hex.build` with the support repo staying in
`test/support` (T-47-15), and resets the shared CertCache ETS in setup (T-47-16).

## Self-Check: PASSED

- FOUND: `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` (134 lines, `use ExUnit.CaseTemplate`)
- FOUND: `mailglass_inbound/test/mailglass_inbound/mailbox_case_test.exs`
- FOUND commits: b7bf5e5 (feat — MailboxCase + self-test), f62d3ae (feat — packaging + docs-contract)
- Acceptance greps verified: no `TestRepo` literal, app-env repo resolution present, no `async_*_impl`, no `MailglassInbound.PubSub` server ref, both resets present, no `name: __MODULE__`.
