---
phase: 138-schema-prefix-no-search-path-hardening
verified: 2026-07-07T22:06:47Z
status: passed
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 138: Schema-prefix No-search-path Hardening Verification Report

**Phase Goal:** Fix concrete missing-prefix runtime risks found after v2.0, prove them under hostile no-search-path conditions, and add a static recurrence guard/focused verification lane for schema-prefix hardening.
**Verified:** 2026-07-07T22:06:47Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Mailglass.Webhook.Replay` projection updates are fixed/proven under hostile `search_path`. | VERIFIED | `test/mailglass/schema_prefix_hardening_test.exs:116` creates the replay proof, forces `SET search_path TO public` at line 135, calls `Replay.execute/1` at lines 137-143, and asserts replayed status/new event count plus configured-schema projection/public absence at lines 145-150. Source callback uses `repo.update(changeset, Repo.multi_opts())` in `lib/mailglass/webhook/replay.ex:324`. |
| 2 | Unsubscribe replay/idempotency conflict lookups are fixed/proven under hostile `search_path`. | VERIFIED | `test/mailglass/schema_prefix_hardening_test.exs:160` posts the same unsubscribe token twice after forcing public search path and asserts one configured-schema event plus zero public-schema events at lines 172-173. `lib/mailglass/compliance/unsubscribe_controller.ex:120` resolves duplicate conflict rows with `repo.one!(query, Repo.multi_opts())` at line 130. |
| 3 | The hostile runtime proof checks configured-schema rows directly and proves matching public-schema rows were not touched. | VERIFIED | Delivery proof queries `mailglass.mailglass_deliveries` and `public.mailglass_deliveries` at `test/mailglass/schema_prefix_hardening_test.exs:232` and `:246`; unsubscribe proof counts `mailglass/public.mailglass_events` by idempotency key at lines 260-278. |
| 4 | Raw repo calls and transaction callbacks touching mailglass tables are explicitly prefixed, facade-routed, or allowlisted as schema-agnostic. | VERIFIED | Known callback sites use explicit opts: replay `repo.update(..., Repo.multi_opts())`, unsubscribe `repo.one!(..., Repo.multi_opts())`, fake adapter `repo.update(Mailglass.Repo.multi_opts())`, reconciler `repo.update(Repo.multi_opts())`, and inbound raw repo calls use `schema_opts()`. `mix credo --strict` ran through the registered guard with no issues. |
| 5 | Fake adapter and webhook reconciler projection updates carry explicit prefix opts and duplicate no-op paths do not update projections or broadcast. | VERIFIED | Fake adapter skips duplicate projection write when `event.inserted_at` is nil at `lib/mailglass/adapters/fake.ex:177` and only broadcasts in the non-duplicate branch at line 192. Reconciler skips no-op projection/broadcast for nil `inserted_at` at `lib/mailglass/webhook/reconciler.ex:209`/`:218` and fallback branch `:392`/`:401`. Focused duplicate tests snapshot projections and assert no broadcast in `test/mailglass/adapters/fake_test.exs:334`, `test/mailglass/webhook/reconciler_test.exs:110`, and `test/mailglass/webhook/replay_test.exs:131`. |
| 6 | A custom Credo guard blocks raw repo/Multi recurrence under `mix credo --strict`. | VERIFIED | `Mailglass.Credo.RawRepoPrefixContract` exists in `credo_checks/raw_repo_prefix_contract.ex:1`; it scopes production paths and protected schema/table sources at lines 5-52. `.credo.exs:87` registers the check with core and inbound schemas. The verifier run of `mix verify.schema_prefix` included strict Credo over 480 files and found no issues. |
| 7 | `RawRepoPrefixContract` covers `ReplayRun` and function-local `Config` alias handling. | VERIFIED | `ReplayRun` is in default guard schema modules at `credo_checks/raw_repo_prefix_contract.ex:15` and production config at `.credo.exs:97`; tests flag an unprefixed `ReplayRun` raw repo call at `test/mailglass/credo/raw_repo_prefix_contract_test.exs:500` and assert config registration at line 521. Function-local alias behavior is tested both ways: wrong core/inbound alias is rejected at line 448, correct inbound local `Config` alias is accepted at line 841. |
| 8 | Inbound repo-option extension points keep the facade as default and make raw-repo prefix contracts explicit/tested. | VERIFIED | Default facades remain in `MailglassInbound.Internal.Replay.replay/2` (`Keyword.get(opts, :repo, MailglassInbound.Repo)` at `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex:26`), `Execution.load/2` (`Repo` default at `mailglass_inbound/lib/mailglass_inbound/execution.ex:84`), and the mix task (`MailglassInbound.Repo` default at `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex:63`). Contract tests use a capture repo in `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs:13`. |
| 9 | Supplied raw repos for inbound replay/load/selector paths receive `prefix: MailglassInbound.Config.schema()`. | VERIFIED | `schema_opts/0` returns the inbound configured prefix in replay (`mailglass_inbound/lib/mailglass_inbound/internal/replay.ex:14`), execution (`mailglass_inbound/lib/mailglass_inbound/execution.ex:17`), and mix task (`mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex:138`). Raw reads pass those opts at replay lines 60, 71, 111, 124; execution lines 112 and 124; selector line 146. Tests assert every captured raw repo call has the configured prefix at `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs:244`. |
| 10 | Inbound `Execution.load/2` requires serialized tenant id, tenant-scopes record/evidence queries, and checks evidence belongs to the record. | VERIFIED | `Execution.load/2` pattern requires `"mailglass_tenant_id"` and non-empty binary tenant at `mailglass_inbound/lib/mailglass_inbound/execution.ex:72`. Record load scopes by `record.id` and `record.tenant_id` plus `Tenancy.scope/2` at lines 106-112. Evidence load scopes by evidence id, inbound record id, and tenant id at lines 115-124. Contract test asserts query field coverage for `:id`, `:tenant_id`, and `:inbound_record_id` at `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs:120` and lines 254-262. |
| 11 | A focused verification lane runs the hostile runtime proofs and static guard. | VERIFIED | `mix.exs:83` sets `"verify.schema_prefix": :test`; alias at `mix.exs:313` runs hostile core schema-prefix tests, raw guard tests via a fresh `mix test` subprocess, strict Credo, and inbound contract tests. Verifier ran `mix verify.schema_prefix`; it passed with 4 hostile tests, 69 guard tests, strict Credo with no issues, and 5 inbound tests. |
| 12 | The broad dual-schema advisory matrix remains a canary, not the only proof. | VERIFIED | Core advisory comments at `.github/workflows/advisory-matrix.yml:105` state the dual-schema full-suite job is a broad canary and not the fail-closed proof because harness search_path can mask runtime calls; inbound comments at line 343 say the same and name `mix verify.schema_prefix` as the focused no-search-path proof. The workflow also runs the focused proof at line 125. |
| 13 | `mix verify.schema_prefix` exists and passes, including hostile tests, raw guard tests, strict Credo, and inbound contract tests. | VERIFIED | Verifier-run command `mix verify.schema_prefix` exited 0. Output: 4 schema-prefix tests, 69 `RawRepoPrefixContract` tests, Credo strict over 480 files with no issues, and 5 inbound schema-prefix contract tests all passed. |

**Score:** 13/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/mailglass/schema_prefix_hardening_test.exs` | Hostile no-search-path runtime proofs | VERIFIED | Exists, substantive, tagged `:schema_prefix`, includes `PrefixedWrapperMigration`, public-search-path forcing, configured/public schema assertions. |
| `lib/mailglass/webhook/replay.ex` | Explicit prefix opts for replay projection callback | VERIFIED | `repo.update(changeset, Repo.multi_opts())` in projector apply callback. |
| `lib/mailglass/compliance/unsubscribe_controller.ex` | Explicit prefix opts for unsubscribe conflict lookup | VERIFIED | Conflict sentinel branch calls `repo.one!(query, Repo.multi_opts())`. |
| `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs` | Inbound raw-repo contract tests | VERIFIED | Capture repo tests replay, execution load, mailbox safety, and mix task selector prefix opts. |
| `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` | Inbound replay raw repo prefix opts | VERIFIED | Default facade retained; every raw `repo.one/2` path passes `schema_opts()`. |
| `mailglass_inbound/lib/mailglass_inbound/execution.ex` | Inbound execution load prefix/tenant contract | VERIFIED | Requires serialized tenant id; record and evidence loads are tenant-scoped and prefixed. |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` | Inbound replay selector prefix opts | VERIFIED | Default facade retained; selector query uses `repo.all(schema_opts())`. |
| `lib/mailglass/adapters/fake.ex` | Fake adapter projection prefix opts and duplicate no-op | VERIFIED | Duplicate event path skips projection and broadcast; normal projection update uses `Mailglass.Repo.multi_opts()`. |
| `lib/mailglass/webhook/reconciler.ex` | Reconciler projection prefix opts and duplicate no-op | VERIFIED | Both compiled branches skip nil-inserted duplicate events and use `Repo.multi_opts()` for projection writes. |
| `credo_checks/raw_repo_prefix_contract.ex` | Static recurrence guard | VERIFIED | Production-path-scoped custom Credo check with protected core/inbound schemas, table sources, repo/Multi functions, and prefix helper validation. |
| `test/mailglass/credo/raw_repo_prefix_contract_test.exs` | Static guard regression tests | VERIFIED | 69-test verifier run covers failing and allowed call shapes, ReplayRun, alias handling, string table sources, helper owners, and facade allowances. |
| `.credo.exs` | Credo registration | VERIFIED | Registers `Mailglass.Credo.RawRepoPrefixContract` with core and inbound schema modules including `ReplayRun`. |
| `mix.exs` | Focused alias and preferred env | VERIFIED | `verify.schema_prefix` preferred env and alias present. |
| `.github/workflows/advisory-matrix.yml` | Canary/proof comments | VERIFIED | Comments accurately distinguish broad canary coverage from focused fail-closed proof. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/mailglass/webhook/replay.ex` | `lib/mailglass/repo.ex` | Raw callback `repo.update` uses `Repo.multi_opts()` | VERIFIED | Manual trace confirms source link at `replay.ex:329`; gsd regex helper false-negative was due to the plan's invalid regex shape. |
| `lib/mailglass/compliance/unsubscribe_controller.ex` | `lib/mailglass/repo.ex` | Raw callback `repo.one!` uses `Repo.multi_opts()` | VERIFIED | Manual trace confirms `unsubscribe_controller.ex:130`; gsd regex helper false-negative was due to the plan's invalid regex shape. |
| `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` | `mailglass_inbound/lib/mailglass_inbound/config.ex` | `schema_opts/0` returns `MailglassInbound.Config.schema()` | VERIFIED | Source line 14. |
| `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs` | Inbound raw repo extension paths | Capture repo asserts raw repo opts | VERIFIED | Capture repo records opts at lines 38-40; `assert_prefixed_calls/1` checks `Keyword.get(opts, :prefix) == Config.schema()` at lines 244-251. |
| `.credo.exs` | `credo_checks/raw_repo_prefix_contract.ex` | `extra_checks` registration | VERIFIED | Registered at `.credo.exs:87`. |
| `mix.exs` | Focused proof files | Alias runs hostile, raw guard, strict Credo, inbound contract tests | VERIFIED | Alias lines 313-317. |
| `.github/workflows/advisory-matrix.yml` | `mix verify.schema_prefix` | Advisory canary comments name focused proof | VERIFIED | Core lines 105-111; inbound lines 343-348. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `Webhook.Replay` hostile proof | Delivery projection row | Configured-schema delivery/webhook rows inserted through facade, replay executed under public search_path, projection asserted by fully qualified SQL | Yes | VERIFIED |
| Unsubscribe hostile proof | Unsubscribe event count | Configured-schema delivery row, two controller POSTs under public search_path, event counts asserted by fully qualified SQL | Yes | VERIFIED |
| Inbound raw repo contract | Captured repo opts and queryables | Capture repo records actual calls made by replay/load/selector code paths | Yes | VERIFIED |
| RawRepoPrefixContract | Credo issues list | Guard tests feed source snippets through the actual Credo check; strict Credo runs project files | Yes | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Focused schema-prefix proof lane | `mix verify.schema_prefix` | Exit 0; 4 hostile tests, 69 guard tests, strict Credo no issues, 5 inbound tests | PASS |
| Duplicate/no-op replay/reconciler/fake adapter behavior | `mix test test/mailglass/adapters/fake_test.exs test/mailglass/webhook/reconciler_test.exs test/mailglass/webhook/replay_test.exs --warnings-as-errors` | Exit 0; 32 tests, 0 failures | PASS |
| Artifact presence/substance | `gsd_run query verify.artifacts` for all four plans | 14/14 artifacts passed helper checks | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| None declared | Not applicable | No `probe-*.sh` scripts were declared by the phase plans or summaries | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SCHEMA-01 | 138-01 | Webhook replay updates projections in configured schema under hostile no-search-path conditions | SATISFIED | Hostile runtime test lines 116-150; `repo.update(..., Repo.multi_opts())`; `mix verify.schema_prefix` passed. |
| SCHEMA-02 | 138-01 | Unsubscribe conflict lookup reads configured schema under hostile no-search-path conditions | SATISFIED | Hostile POST-twice test lines 160-173; `repo.one!(..., Repo.multi_opts())`; `mix verify.schema_prefix` passed. |
| SCHEMA-03 | 138-03 | Raw repo/callback calls are prefixed/facade/allowlisted with static recurrence guard | SATISFIED | Fake/reconciler/replay/unsubscribe/inbound source opts; registered `RawRepoPrefixContract`; strict Credo passed. |
| SCHEMA-04 | 138-02 | Inbound repo-option extension points default to facade or prove raw-repo prefix contract | SATISFIED | Defaults retained; `schema_opts()` threaded through replay/load/selector; inbound contract tests passed. |
| GATE-01 | 138-04 | Focused schema-prefix verification lane exists and runs runtime/static proofs | SATISFIED | `mix.exs` alias lines 313-317; verifier ran `mix verify.schema_prefix` successfully. |
| GATE-02 | 138-04 | Advisory matrix remains a broad canary and docs/comments identify focused proof | SATISFIED | Advisory matrix comments core/inbound identify broad canary and focused no-search-path proof. |

No orphaned Phase 138 requirements were found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.credo.exs` | 239 | `TODO` in an explanatory comment disabling `Credo.Check.Design.TagTODO` | INFO | The line references tracked REL-07 follow-up context and predates this phase's goal surface; not a Phase 138 blocker. |

No untracked `TBD`, `FIXME`, `XXX`, placeholder implementation, hardcoded-empty user-visible data, or stub returns were found in the phase-touched source/test files.

### Human Verification Required

None.

### Gaps Summary

No gaps found. The phase goal is achieved: the named runtime risks are fixed/proven under hostile no-search-path conditions, the inbound raw-repo contract is explicit and tested, recurrence is guarded by strict Credo, and the focused verification lane is executable and green.

---

_Verified: 2026-07-07T22:06:47Z_
_Verifier: the agent (gsd-verifier)_
