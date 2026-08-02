# Domain Pitfalls: v2.4 Outbound First-Adopter Correctness

**Domain:** Phoenix transactional email, durable asynchronous delivery, and RFC 8058 compliance
**Researched:** 2026-08-02
**Confidence:** HIGH for repository findings; MEDIUM for provider-outcome classification, which must be validated against each supported adapter.

## Critical Pitfalls

### Pitfall 1: Claiming zero-config SingleTenant while retaining a hard process-stamp gate

**What goes wrong:** `Tenancy.current/0` already returns `"default"` for `SingleTenant`, but `deliver/2`, `deliver_later/2`, and `deliver_many/2` call `assert_stamped!/0`, which only reads the process dictionary. A clean host can therefore follow the documented no-config path and fail before rendering or persistence.

**Why it happens:** The tenant ID fallback and the safety assertion are individually reasonable but have incompatible meanings. Tests normally stamp `"test-tenant"` in `MailerCase`, hiding the public path.

**How to avoid:** Make the default resolver explicitly satisfy the outbound context precondition, while preserving a hard error for every configured custom resolver with no stamp. Test process inheritance boundaries too: Oban worker, task fallback, and webhook resolution must use the same literal `"default"` contract.

**Warning signs:** Any test setup that always invokes `Tenancy.put_current/1`; a generated host that only compiles and mounts `/dev/mail`; an outbound error of `:unstamped` under the documented default config.

**Phase to address:** Foundation contract and migration phase, before async work.

---

### Pitfall 2: Changing one recipient field but still sending a multi-recipient envelope

**What goes wrong:** `primary_recipient/1` persists only the first `to` address and derives idempotency from it, while the original Swoosh email can retain additional `to`, `cc`, or `bcc` recipients. One delivery row/job can then dispatch multiple recipients; a replay, suppression decision, audit row, and provider status all become incorrectly attributed to the first address.

**Why it happens:** The schema documentation says “one row per (Message, recipient, provider),” but only persistence normalizes the first recipient. Fake-adapter tests that assert one observed message do not prove the SMTP/API envelope cardinality.

**How to avoid:** Validate exactly one supported envelope recipient before both sync persistence and async enqueue; reject or explicitly split all unsupported recipient shapes before idempotency. Include `to`, `cc`, `bcc`, duplicate/case-normalized addresses, and empty recipient lists in contract tests. Do not silently discard recipients.

**Warning signs:** `Delivery.recipient` is one address while adapter input has more; content/idempotency collisions between a one-recipient and multi-recipient message; provider logs show multiple accepted recipients for one delivery ID.

**Phase to address:** Foundation contract phase.

---

### Pitfall 3: Treating a partial async reconstruction as wire-equivalent delivery

**What goes wrong:** `base_delivery_attrs/3` stores HTML, generated text, subject, and headers in `metadata`; rehydration rebuilds a minimal email with only `to`, subject, bodies, and headers. It loses from/reply-to, cc/bcc semantics, attachments, assigns/options, and potentially header representation. A later code change can make sync work while queued mail changes identity or content.

**Why it happens:** Oban args correctly avoid serializing `%Message{}`, but the replacement snapshot is undocumented and embedded in the adopter-visible `metadata` bag. Current happy-path tests use simple text messages and the in-process fallback.

**How to avoid:** Define a versioned, internal, JSON-safe wire snapshot with an allowlisted supported surface; store it separately from adopter metadata. Rehydrate only from that snapshot, reject unsupported features before enqueue, and add sync-vs-Oban-manual adapter-capture equality tests for every supported field.

**Warning signs:** `delivery.metadata` contains `rendered_html`, `subject`, or arbitrary host data; changing a mailable module changes the behavior of an already queued job; async tests do not restart/reload the delivery before performing the job.

**Phase to address:** Durable async fidelity phase.

---

### Pitfall 4: Calling “retry safe” after an ambiguous provider result

**What goes wrong:** The worker returns any exception as an Oban error. If the adapter times out after the provider accepted the message, Oban retries and Mailglass can send duplicate email. Existing delivery idempotency protects enqueue rows, not provider acceptance; current dispatch has no durable “attempting/ambiguous” claim before the external call.

**Why it happens:** Database transactions cannot atomically include ESP delivery, and `max_attempts: 20` looks like reliability. `status: :failed` also conflates permanent rejection, local configuration failure, and unknown remote outcome.

**How to avoid:** Document at-least-once behavior prominently; classify errors into permanent/no-retry, transient/retry, and ambiguous/repair-required based on adapter evidence. Persist an attempt/uncertain fact before or immediately around the call, make re-dispatch concurrency-safe, and provide reconciler/operator recovery rather than promising exactly-once delivery.

**Warning signs:** Retrying all adapter errors; a delivery marked failed after a timeout without a provider lookup path; tests only exercise explicit adapter failures, never "accepted remotely then connection lost".

**Phase to address:** Durable async fidelity and retry-classification phase.

---

### Pitfall 5: Making one-click POST idempotent only at the event layer

**What goes wrong:** `UnsubscribeController` inserts/reuses the `:unsubscribed` event and invokes a configured lifecycle multi, but the core `AutoSuppress` projection is not in that transaction. A 200 response can be returned while the stream-scoped suppression is absent until later resync, allowing a subsequent send in the gap. Replayed POSTs can also run lifecycle work more than once unless it keys off the canonical event.

**Why it happens:** The existing webhook-driven projector is eventually consistent and its conflict target makes replay rows look harmless. The v2.3 flow proves eventual stream suppression, not post-commit atomic prevention.

**How to avoid:** Insert/reuse the canonical event and insert the address-stream suppression in the same `Repo.multi`, with the same schema prefix and conflict semantics. Only run new-fact side effects/broadcast after commit. Test POST concurrent with a send and POST replay, proving exactly one event, one suppression, 200 responses, and blocked future operational/bulk send while transactional remains allowed.

**Warning signs:** The controller never calls `AutoSuppress`; success is asserted solely by HTTP 200/event count; a resync job is required for one-click correctness; schema-isolation tests run with `search_path` including `mailglass`.

**Phase to address:** Compliance atomicity phase.

---

### Pitfall 6: Solving serialization by retaining message content indefinitely

**What goes wrong:** Queued HTML, text, subject, headers, recipient, and URL/token-bearing headers are stored in `deliveries.metadata`, an explicitly adopter-facing non-PII bag. Successful delivery currently leaves that content behind indefinitely, exposing it in normal database/operator queries, backups, exports, and error inspection.

**Why it happens:** A durable queue needs a snapshot, and JSONB is convenient. “Telemetry contains no PII” can give a false sense that persistence is privacy bounded.

**How to avoid:** Move internal queue payload to a separately named/store-backed, access-bounded field or table; allowlist serializable fields; scrub content atomically after confirmed successful dispatch; establish a bounded retention/deletion worker for terminal and abandoned queued records; keep only operational facts/adopter metadata in the delivery. Define recovery behavior for payload corruption and retention expiry.

**Warning signs:** `metadata` grows with rendered bodies or List-Unsubscribe tokens; a sent delivery can still render exact content days later; migration/backfill leaves legacy payloads; retention tests check only successful sends and not failed, exhausted, or orphaned jobs.

**Phase to address:** Async payload privacy and retention phase, coupled to async fidelity.

---

### Pitfall 7: Green release proof that never runs the documented production path

**What goes wrong:** The present generated-host smoke uses `--no-ecto`, does not configure or start Postgres/Oban, and only boots then requests `/dev/mail/`. It cannot detect the documented queue typo (`:mailglass` in the go-live guide vs worker `:mailglass_outbound`), migration/prefix failures, fail-open Task fallback, sync/async semantic drift, unsubscribe atomicity, or production operator wiring.

**Why it happens:** Compile, endpoint boot, and a dev-mail route are fast stable signals. `MailerCase` additionally defaults to stamps, an inline async implementation, Fake adapter sharing, and special Oban modes, so it is intentionally unlike a host process topology.

**How to avoid:** Generate a new Phoenix+Ecto+Postgres host with published/path dependency modes; configure the exact `:mailglass_outbound` Oban queue; run migrations; assert that missing/unready Oban makes durable `deliver_later/2` fail closed (never Task fallback); use a recording adapter to compare sync and manually executed Oban payloads; POST/replay unsubscribe and send afterward; mount and query production operations. Make this a release blocker and assert docs snippets/queue names against executable constants.

**Warning signs:** Smoke command has `--no-ecto`; no `oban_jobs` table exists; proof only checks a dev route; tests set `async_adapter: :task_supervisor` rather than exercising default production selection; documentation names a queue not used by `Worker`.

**Phase to address:** Production preflight, generated-host proof, and documentation-contract phase.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Persist wire content in `Delivery.metadata` | No migration or serializer design | PII leaks into an adopter-facing bag and cannot be lifecycle-managed | Never for v2.4's durable path |
| Task fallback when Oban is absent/unready | Demo and unit tests still send | Durable API silently becomes best-effort and jobs vanish on restart | Only an explicit non-durable development adapter, never default production behavior |
| Retry every adapter exception | Simple worker | Duplicate sends after ambiguous remote acceptance | Never; unknown outcome requires an honest repair path |
| Resync suppression after one-click POST | Reuses webhook projector | Compliance gap permits an immediately subsequent send | Only for historical repair, never primary RFC 8058 path |
| Reusing MailerCase defaults as production proof | Fast tests | Stamps, inline adapter, and Fake hide host wiring faults | Unit coverage only, alongside host proof |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Oban | Configure `queues: [mailglass: 10]` because the guide says so | Configure and preflight `:mailglass_outbound`; verify an inserted job is executable by the host's running Oban |
| ESP adapters | Treat timeout as failed/not-sent | Preserve provider correlation/attempt state and classify it as ambiguous until adapter-specific reconciliation says otherwise |
| Postgres migrations | Add payload storage without prefix, backfill, index, or rollback checks | Test migration from v2.3 data under hostile `search_path`; bound locks and prove legacy content scrubbing |
| RFC 8058 router/controller | Assert POST returns 200 | Verify event + address-stream suppression commit atomically and replay stays one fact; do not change transactional behavior |
| Docs/install generator | Update prose but not executable smoke | Parse/check canonical queue names and run a generated host through the exact documented commands |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Large rendered payloads kept in delivery JSONB | Slow operator queries, backup growth, vacuum pressure | Separate bounded payload store, scrub terminal rows, index only operational columns | Immediately for attachment-like/bulk content; becomes acute with backlog |
| Adapter call inside unsubscribe/send DB transaction | Locked rows and exhausted pool during ESP latency | Keep provider calls outside DB transactions; reserve atomic multis for local facts | Any provider outage or queue spike |
| Retry storm with no attempt claim | Concurrent jobs duplicate provider calls | Unique job plus delivery-level dispatch claim/locking and classified retry | First timeout/restart under concurrency |

## Security and Privacy Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Store raw rendered headers/body in normal metadata | Sensitive URLs/tokens and content exposed beyond operational need | Internal allowlisted payload, access boundary, scrub/retention tests, backup-aware policy |
| Use `String.to_atom/1` on persisted mailable data | Atom-table exhaustion from database-sourced values | Retain existing `to_existing_atom` discipline; preferably eliminate mailable-module rehydration dependency |
| Fail open to Task.Supervisor for production durable mail | Unobservable message loss after node restart | Explicit production readiness check and error when durable backend is unavailable |
| Use a one-click token as permission to touch unscoped rows without exact tenant handling | Cross-tenant suppression/write error | Verify token, fetch intentionally unscoped, then stamp the delivery tenant for the entire atomic multi |

## Looks Done But Isn't Checklist

- [ ] **SingleTenant:** A test clears the process dictionary in a clean host and proves sync, async, and verified webhook facts all use `"default"`; a custom resolver still raises when unstamped.
- [ ] **Exactly one recipient:** Adapter-capture tests reject multi-`to`, `cc`, and `bcc`; no path merely records the first address.
- [ ] **Renderer/plaintext:** Explicit `text_body`, text-only mail, `html_body: nil`, and documented renderer options have contract tests in both sync and Oban execution.
- [ ] **Durable async:** A worker reloads a persisted snapshot in a fresh process and produces the same supported provider input as sync; unsupported fields fail before enqueue.
- [ ] **Retry:** Test remote-accepted/locally-timeout as ambiguous, prove no automatic claim of exactly-once, and assert permanent/suppressed errors do not retry.
- [ ] **One-click:** Concurrent/replayed POST plus immediate send proves one event, one stream suppression, post-commit broadcast, and no transaction-only partial success.
- [ ] **Privacy:** Successful, failed, exhausted, and orphaned jobs all have deterministic payload lifecycle/retention assertions; delivery metadata never contains queue content.
- [ ] **Release proof:** A new Phoenix/Postgres host migrates, starts Oban on `mailglass_outbound`, exercises sync/async/provider feedback/unsubscribe/admin, and fails for missing Oban or documentation drift.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Incorrect queue/dead jobs | MEDIUM | Stop broad sending, repair host queue config, identify queued deliveries/jobs, then manually reconcile/re-enqueue only deliveries with safe attempt state. |
| Partial one-click suppression | HIGH | Immediately add the affected address-stream suppression records from canonical events, audit sends in the gap, then deploy atomic transaction and replay tests. |
| Duplicate delivery after timeout | HIGH | Preserve provider IDs/logs, deduplicate operationally with provider evidence, contact affected recipients if needed, then alter retry policy; do not blindly replay all failed rows. |
| Queued payload privacy exposure | HIGH | Restrict operator/database access, scrub existing payloads with an audited migration, rotate exposed tokens where feasible, confirm backups/retention policy, then deploy the bounded store. |
| Bad migration/prefix rollout | MEDIUM | Pause workers, restore from tested backup or forward-migrate under the configured schema, validate row counts/indexes, and restart only after host preflight passes. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| SingleTenant process-stamp contradiction | Foundation contract and migration | Clean default vs custom-resolver unstamped tests across send/job/webhook |
| Multi-recipient envelope ambiguity | Foundation contract | Adapter-capture matrix rejects unsupported recipient fields before DB/job insertion |
| Async snapshot semantic loss | Durable async fidelity | Sync vs fresh Oban-worker serialized provider-input equality matrix |
| Ambiguous retry duplicates | Retry classification | Inject timeout-after-accept, permanent rejection, and suppression; inspect job retry/state transitions |
| One-click eventual suppression | Compliance atomicity | Concurrent POST/send transaction test under hostile schema search path |
| Content retention in metadata | Privacy and retention | DB inspection plus terminal/exhausted/orphan lifecycle tests and migration backfill proof |
| False-green generated host/docs | Production preflight and release proof | New Phoenix+Postgres host executes documented commands and intentionally fails queue/Oban/doc-drift variants |

## Sources

- Repository evidence: `lib/mailglass/outbound.ex`, `lib/mailglass/outbound/worker.ex`, `lib/mailglass/outbound/delivery.ex`, `lib/mailglass/renderer.ex`, `lib/mailglass/tenancy.ex`, `lib/mailglass/compliance/unsubscribe_controller.ex`, and `lib/mailglass/suppression/auto_suppress.ex` (HIGH).
- Repository release/test evidence: `scripts/consumer_install_smoke.sh`, `test/support/mailer_case.ex`, `guides/b2c-first-adopter.md`, `guides/production-go-live-checklist.md`, and v2.3 audit (HIGH).
- Provider-outcome retry taxonomy is a design requirement to validate against each adapter's current official documentation before implementation (MEDIUM).

---
*Pitfalls research for: mailglass v2.4 Outbound First-Adopter Correctness*
*Researched: 2026-08-02*
