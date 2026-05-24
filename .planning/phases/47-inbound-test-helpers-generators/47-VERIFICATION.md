---
phase: 47-inbound-test-helpers-generators
verified: 2026-05-24T12:40:00Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
---

# Phase 47: Inbound Test Helpers + Generators Verification Report

**Phase Goal:** An adopter writing their first mailbox can `use MailglassInbound.MailboxCase`, call `assert_inbound_accepted/1` (or one of 4 matcher styles), drive the real persist+route+execute path with `MailglassInbound.Test.Ingress`, build provider payloads in code (no `.eml` files on disk), and scaffold the mailbox/router/route via Igniter generators — with full DX parity to outbound's `Mailglass.MailerCase` + `Mailglass.TestAssertions` + `mix mailglass.gen.mailable`.
**Verified:** 2026-05-24T12:40:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Must-haves merged from ROADMAP Success Criteria (5) + the 4 plans' frontmatter `truths`. The
SC2 routing/outcome arities (`/1`, `/2`) and the SC3 "frozen clock"/`:async_execution_impl`
HI-01-snapshot wording are superseded by CONTEXT decisions D-47-12/13 (verified honored as
documented — see Truth 5 and Notes).

| #  | Truth (Success Criterion) | Status | Evidence |
| -- | ------------------------- | ------ | -------- |
| 1  | SC1: 4 matcher styles of `assert_inbound_received` fire correctly against captured inbound; `assert_no_inbound_received/0` refutes | ✓ VERIFIED | `test_assertions.ex:84-139` defines all 4 macro heads (no-arg presence; `{:%{}}` struct pattern; `{:fn}` predicate; keyword via `__match_keyword__/2`). `test_assertions_test.exs:45-89` exercises every style incl. `assert_inbound_received(to: "team@example.com")` (the exact SC1 example, line 65), wrong-value + unsupported-key failures. Negative: `assert_no_inbound_received/0` (`test_assertions.ex:275-279`) tested both paths (`:143-151`). Suite: 44 tests, 0 failures. |
| 2  | SC2: outcome assertions key off locked atoms; routing assertions work against `__mailglass_inbound_routes__/0` reflection | ✓ VERIFIED | `assert_inbound_{accepted,ignored,rejected,bounced}` (`test_assertions.ex:193-219`) → `__assert_outcome__` reads `outcome.outcome` against the locked enum (`mailbox.ex:22`: `:accept \| :ignore \| {:reject,_} \| {:bounce,_}`). `assert_inbound_routed_to`/`assert_inbound_no_match` match the persisted route map (`:242-267`). Router reflection `__mailglass_inbound_routes__/0` confirmed at `router.ex:64-69`. Tests: each outcome matches its atom + refutes others; both routing assertions positive + refutation (`test_assertions_test.exs:92-141`). |
| 3  | SC3: `use MailglassInbound.MailboxCase` sets up sandbox + PubSub + per-test fixtures; `set_mailglass_inbound_global` race structurally prevented (D-47-12 sync-execution honored) | ✓ VERIFIED | `mailbox_case.ex:77-133`: `use ExUnit.CaseTemplate`; `using` imports TestAssertions + aliases Fixtures/Test; setup does `Sandbox.start_owner!` on app-env repo, `Tenancy.put_current`, CertCache+S3Fake resets, best-effort `Phoenix.PubSub.subscribe(Mailglass.PubSub, …)`, `Sandbox.stop_owner` on exit. **D-47-12 honored as documented:** source contains NO `TestRepo`/`:async_execution_impl`/`:async_adapter_impl`/`name: __MODULE__` literal (grep clean); snapshots nothing. `mailbox_case_test.exs:46-79` asserts no-TestRepo-literal + no-async-key-leak across a run. |
| 4  | SC4: `Test.Ingress.receive_inbound/2` + `receive_provider_payload/3` drive production write path end-to-end; `Fixtures` builds Postmark/SendGrid/Mailgun/SES-SNS entirely from code, no `.eml` on disk | ✓ VERIFIED | `test/ingress.ex:182-191`: real `Persist.persist/2` → `Execution.execute(_, source: :fresh)` (SYNC) → `send(self(), {:inbound, …})`; `dispatch` token appears only in moduledoc/comment, never as a call (grep). `receive_provider_payload/3` runs real per-provider `verify!`/`normalize` (`:198-260`). `fixtures.ex` builds all 4 payloads from code; SES mints ephemeral RSA-2048 + primes real `CertCache.put` (`:298`) + `S3Fetcher.Fake.put` (`:301`). **No `.eml`/`.pem`/`test/fixtures/` anywhere** (find clean). Convergence (1 record + 1 fresh run) tested for Postmark id-dedupe AND SES raw_mime-dedupe (`ingress_test.exs:69-116`). |
| 5  | SC5: `gen.mailbox` / `gen.inbound_router` / `gen.inbound_route` scaffold/extend idempotently; all 3 support `--dry-run` | ✓ VERIFIED | gen.inbound_route (`:84-124`) idempotent via `find_and_update_module` + `move_to_function_call_in_current_scope`/`argument_equals?`, `placement: :after` keyword form. gen.mailbox (`:51-76`) creates `@behaviour MailglassInbound.Mailbox` + `process/1`→`:accept`, reuses `InboundRoute.add_route/4` (not re-implemented), test stub `use MailglassInbound.MailboxCase`, missing-router notice. gen.inbound_router (`:44-55`) creates `use MailglassInbound.Router` + sample route. No `dry_run` in any schema (Igniter global switch = IGEN-04). Generator suite: 15 tests, 0 failures (run-twice `assert_unchanged`, single-statement-body, dry-run, missing-router). |
| 6  | Fixtures builds canonical `%InboundMessage{}` from code with one call (Plan 01) | ✓ VERIFIED | `fixtures.ex:78-97` `build_inbound_message/1` — address-shaped lists, defaulted `tenant_id`. |
| 7  | Each provider payload round-trips through the REAL `verify!`/`normalize` to a valid `%InboundMessage{}`; SES passes real `SES.verify!` via primed CertCache (Plan 01) | ✓ VERIFIED | `fixtures_test.exs` references `SES.verify!`; suite green (8 fixtures tests within the 44). `receive_provider_payload/3` drives the unweakened real seam. |
| 8  | `Test.Ingress` replay converges to 1 record + 1 fresh run incl. raw_mime dedupe (Plan 03) | ✓ VERIFIED | `ingress_test.exs:69-116` asserts `record_count()==1` + `fresh_run_count()==1` for id-dedupe AND raw_mime-dedupe (SES). |
| 9  | gen.inbound_route on a single-statement router body places route after `use` and compiles (Plan 02) | ✓ VERIFIED | `add_code/3` single-child block promotion; single-statement-body case present in generator self-tests (15 green). |
| 10 | The four Testing helpers ship in the Hex artifact under a new ExDoc Testing group; docs-contract asserts them (Plan 04) | ✓ VERIFIED | `mix.exs:142-146` `Testing:` group lists all 4; `files: ~w(lib …)` (`:113`) globs lib (nested `lib/mailglass_inbound/test/ingress.ex` ships). `docs_contract_test.exs:30-44` asserts the 4 (passes within the suite). |
| 11 | `mix compile --no-optional-deps --warnings-as-errors` stays green for inbound with all 4 helpers in lib/ (Plan 04) | ✓ VERIFIED | Ran in-process: exit 0 (41 files compiled, no warnings-as-errors). Confirms no helper references `Oban`/`ExAws`/`Plug.Test`. |
| 12 | No `.eml`/real-PII/`.pem` written to disk or committed (Plans 01/04) | ✓ VERIFIED | `find mailglass_inbound -name '*.eml' -o -name '*.pem'` → none; no `test/fixtures/` dir; SES keypair ephemeral/in-memory; `.pem` token exists only as in-memory HTTPS cert-URL ETS key (TrustPolicy-required suffix). |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `mailglass_inbound/lib/mailglass_inbound/fixtures.ex` | Code-built canonical msg + 4 provider payload builders (ITEST-07) | ✓ VERIFIED | 386 lines; all 5 builders; CertCache.put + S3Fetcher.Fake.put present; no `.eml`/`.pem`/`CertCache.Fake` literal; wired by ingress_test + assertions_test + mailbox_case. |
| `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex` | Real persist+route+execute driver + capture seam (ITEST-06) | ✓ VERIFIED | 261 lines; `send(self(), {:inbound,` present; `Persist.persist` + `Execution.execute` (sync); zero `dispatch` calls (moduledoc-only token). |
| `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex` | 4 matcher styles + outcome + routing + negative (ITEST-01..04) | ✓ VERIFIED | 280 lines; `defmacro assert_inbound_received` (4 heads) + outcome/routing/negative; `import ExUnit.Assertions` (no `:ex_unit` dep). |
| `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` | ExUnit.CaseTemplate (ITEST-05) | ✓ VERIFIED | 134 lines; `use ExUnit.CaseTemplate`; app-env repo resolution w/ raise; no TestRepo/async-key/`name: __MODULE__` literal. |
| `lib/mix/tasks/mailglass.gen.inbound_route.ex` | Idempotent zipper route insert + shared add-route helper (IGEN-03) | ✓ VERIFIED | 140 lines; `use Igniter.Mix.Task`; `find_and_update_module`; `placement: :after`; exports `add_route/4` reused by gen.mailbox. |
| `lib/mix/tasks/mailglass.gen.inbound_router.ex` | Router scaffold (IGEN-02) | ✓ VERIFIED | 56 lines; emits `use MailglassInbound.Router` + sample route. |
| `lib/mix/tasks/mailglass.gen.mailbox.ex` | Mailbox + route stub + MailboxCase test stub (IGEN-01) | ✓ VERIFIED | 126 lines; `@behaviour MailglassInbound.Mailbox` + `process/1`→`:accept`; reuses `InboundRoute.add_route/4`; test stub `use MailglassInbound.MailboxCase`. |
| 7 corresponding `*_test.exs` self-tests | Behavior coverage | ✓ VERIFIED | All 7 exist (fixtures 171, ingress 150, assertions 170, mailbox_case 82, gen route 110, gen router 48, gen mailbox 86 lines). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `test/ingress.ex` | `Ingress.Persist.persist/2` | real persist w/ routes/router/repo opts | ✓ WIRED | `ingress.ex:182` |
| `test/ingress.ex` | `Execution.execute/2` | SYNC (never dispatch/2) | ✓ WIRED | `ingress.ex:183`; no `dispatch` call |
| `test_assertions.ex` | `{:inbound,…}` mailbox tuple | `assert_received`/`refute_received` | ✓ WIRED | 8 occurrences `:86-277` |
| `fixtures.ex` | `SES.CertCache` | `CertCache.put/3` priming | ✓ WIRED | `fixtures.ex:298` |
| `fixtures.ex` | `S3Fetcher.Fake` | `S3Fetcher.Fake.put/3` | ✓ WIRED | `fixtures.ex:301` |
| `mailbox_case.ex` | `Application.get_env(:mailglass_inbound, :repo)` | adopter repo (never TestRepo) | ✓ WIRED | `mailbox_case.ex:93` |
| `mailbox_case.ex` | `CertCache.reset` + `S3Fetcher.Fake.reset` | per-setup process-global reset | ✓ WIRED | `mailbox_case.ex:110-111` |
| `gen.inbound_route.ex` | `find_and_update_module/3` | append route in do-block | ✓ WIRED | `gen.inbound_route.ex:87` |
| `gen.mailbox.ex` | `gen.inbound_route.ex` | reuse `add_route`/`route_already_present?` | ✓ WIRED | `gen.mailbox.ex:56-75` |
| `mix.exs` | ExDoc `Testing` group | the four helper modules listed | ✓ WIRED | `mix.exs:142-146` |

### Behavioral Spot-Checks / Probe Execution

| Check | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| 4 plans' inbound scoped suites | `mix test fixtures_test ingress_test test_assertions_test mailbox_case_test docs_contract_test --seed 0` | 44 tests, 0 failures | ✓ PASS |
| 3 core generator suites | `mix test test/mix/tasks/mailglass.gen.{inbound_route,inbound_router,mailbox}_test.exs --seed 0` | 15 tests, 0 failures | ✓ PASS |
| no-optional-deps compile gate (inbound) | `mix compile --no-optional-deps --warnings-as-errors` | exit 0 (41 files) | ✓ PASS |
| Full inbound suite (regression) | `mix test --seed 0` | 1 property, 209 tests, 0 failures | ✓ PASS |

All probes executed in this verifier's own process — not trusted from SUMMARY.md.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
| ----------- | ----------- | ------ | -------- |
| ITEST-01 (4 matcher styles) | 47-03 | ✓ SATISFIED | `test_assertions.ex:84-139`; Truth 1 |
| ITEST-02 (outcome assertions, locked atoms) | 47-03 | ✓ SATISFIED | `test_assertions.ex:193-233`; Truth 2 |
| ITEST-03 (routing assertions vs reflection) | 47-03 | ✓ SATISFIED | `test_assertions.ex:242-267` + `router.ex:64-69`; Truth 2 |
| ITEST-04 (negative assertion) | 47-03 | ✓ SATISFIED | `test_assertions.ex:275-279`; Truth 1 |
| ITEST-05 (MailboxCase) | 47-04 | ✓ SATISFIED | `mailbox_case.ex`; Truth 3 |
| ITEST-06 (Test.Ingress real write path, fake seam) | 47-03 | ✓ SATISFIED | `test/ingress.ex`; Truth 4 |
| ITEST-07 (Fixtures code-built, no `.eml`) | 47-01 | ✓ SATISFIED | `fixtures.ex`; Truths 6/7/12 |
| IGEN-01 (gen.mailbox) | 47-02 | ✓ SATISFIED | `gen.mailbox.ex`; Truth 5 |
| IGEN-02 (gen.inbound_router) | 47-02 | ✓ SATISFIED | `gen.inbound_router.ex`; Truth 5 |
| IGEN-03 (gen.inbound_route idempotent) | 47-02 | ✓ SATISFIED | `gen.inbound_route.ex`; Truths 5/9 |
| IGEN-04 (`--dry-run` all generators) | 47-02 | ✓ SATISFIED | no `dry_run` in any schema (Igniter global); dry-run cases in 3 self-tests; Truth 5 |

All 11 declared requirement IDs accounted for and satisfied. (REQUIREMENTS.md checkboxes still `[ ]` and traceability table "Pending" — normal: the orchestrator flips these at phase.complete AFTER verification.) No ORPHANED requirements: REQUIREMENTS.md line 233 maps Phase 47 to exactly ITEST-01..07 + IGEN-01..04, all claimed by the 4 plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | — | — | No `TBD`/`FIXME`/`XXX` debt markers; no `TODO`/`HACK`/`PLACEHOLDER`/"not implemented" in any of the 7 phase-modified lib/task files. No stub/empty-impl patterns — every module drives real production seams. |

### Human Verification Required

None. This is a test-ergonomics + scaffolding phase whose deliverables are entirely
verifiable programmatically (test suites + compile gate + grep invariants), all of which
were executed in-process and passed. No visual/UX/external-service surface.

### Gaps Summary

No gaps. All 5 ROADMAP Success Criteria and all 12 merged must-haves are verified against
real, substantive, wired, data-flowing code, corroborated by 4 independently-run probes
(44 + 15 scoped tests, no-optional-deps compile exit 0, full inbound suite 209 tests + 1
property green) and a clean anti-pattern scan.

**Two ROADMAP-wording deviations — both intentional and documented, NOT gaps:**

1. **Outcome/routing assertion arities.** SC2 / REQUIREMENTS ITEST-02/03 say
   `assert_inbound_{accepted,…}/1`, `assert_inbound_routed_to/2`, `assert_inbound_no_match/1`.
   The implementation ships arity-0 outcome assertions, `assert_inbound_routed_to/1`, and
   `assert_inbound_no_match/0`. These are **macros** that read the captured `{:inbound, …}`
   tuple from the process mailbox; the only meaningful argument (the expected mailbox for
   `routed_to`) is the lone arg, while the expected outcome is encoded in the macro name.
   The behavioral contract ("key off the locked mailbox outcome atoms" / "work against
   `__mailglass_inbound_routes__/0` reflection") is fully met and self-tested both ways.
   Exact signatures are explicitly Claude's Discretion (D-47). This is a wording-level arity
   difference, not a functional shortfall.

2. **SC3 mechanism (frozen clock + `:async_execution_impl` HI-01 snapshot).** SC3 / ITEST-05
   describe lifting outbound's HI-01 snapshot/restore of `:async_execution_impl` and a frozen
   clock. CONTEXT decisions **D-47-12/13 supersede this**: `:async_execution_impl` does not
   exist in either package; inbound achieves the same race-prevention guarantee
   *structurally* (sync `execute/2` via `Test.Ingress`, snapshot nothing — no leak surface).
   The prompt directs verifying D-47-12 was honored *as documented* — it was: MailboxCase
   snapshots nothing and `mailbox_case_test.exs` asserts no `:async_*` key leaks. No frozen
   clock is needed because there is no async runner to freeze in the sync test path. This is
   a verified-correct supersession, not an unmet criterion.

**If the developer wants the VERIFICATION record to formally acknowledge these documented
ROADMAP-wording deviations** (rather than leave them as inline notes), add to this file's
frontmatter:

```yaml
overrides:
  - must_have: "assert_inbound outcome/routing assertion arities (/1, /2) per SC2"
    reason: "Macros read the captured tuple from the process mailbox; arities are macro-name-encoded per D-47 discretion. Behavioral contract (locked atoms + route reflection) fully met and self-tested."
    accepted_by: "szTheory"
    accepted_at: "2026-05-24T12:40:00Z"
  - must_have: "MailboxCase HI-01 snapshot of :async_execution_impl + frozen clock per SC3"
    reason: "Superseded by D-47-12/13: key does not exist; sync execution is structural (snapshot nothing). Honored as documented."
    accepted_by: "szTheory"
    accepted_at: "2026-05-24T12:40:00Z"
```

Note: overrides are optional here — the phase goal is achieved and status is already `passed`
because both deviations are documented design decisions that satisfy the underlying intent.

---

_Verified: 2026-05-24T12:40:00Z_
_Verifier: Claude (gsd-verifier)_
