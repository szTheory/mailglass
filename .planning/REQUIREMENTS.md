# Requirements: Mailglass v2.6 Engineering Quality Ratchet

**Defined:** 2026-08-16
**Core Value:** Email you can see, audit, and trust before it ships.

## v2.6 Requirements

### Adopter and Migration Truth

- [x] **ADOPT-01**: A generated Ecto host receives the documented core and inbound `up/0`/`down/0` migration wrappers rather than hand-written or toy DDL.
- [x] **ADOPT-02**: An adopter can target an explicit repo with `--repo`; implicit inference succeeds only when exactly one configured Ecto repo exists.
- [x] **ADOPT-03**: `--upgrade` creates a fresh timestamped migration whose rollback returns to the previously applied package schema version, without rewriting applied migrations.
- [x] **ADOPT-04**: Offline upgrade generation accepts an explicit prior version and rejects invalid or non-older versions.
- [x] **ADOPT-05**: The known legacy toy migration is detected and has an explicit fail-closed repair path that never destroys ambiguous or populated data.
- [x] **ADOPT-06**: Migration version detection distinguishes an absent anchor from malformed metadata or query failure and fails closed for the latter cases.

### Delivery Correctness and Resource Bounds

- [x] **EXEC-01**: Concurrent core and inbound token-bucket refills cannot grant more capacity than configured and do not lose sub-token elapsed time.
- [x] **EXEC-02**: Rate-limit ETS storage evicts idle keys, has a bounded maximum cardinality, and fails closed when capacity remains exhausted.
- [x] **EXEC-03**: Durable batch delivery commits projections, events, private payloads, and Oban jobs atomically or reports failure without stranded queued rows.
- [x] **EXEC-04**: Task-supervisor fallback has bounded concurrency and reports spawn saturation/failure instead of claiming a delivery was queued.
- [x] **EXEC-05**: Provider outcomes carry a closed transient/permanent retry classification; transport, timeout, 429, and 5xx failures retry while permanent outcomes are discarded.
- [x] **EXEC-06**: Serializable delivery errors contain no provider body preview or recipient/message content.
- [x] **EXEC-07**: Tracking telemetry reports successful and failed ledger writes truthfully while preserving fail-open HTTP behavior.
- [x] **EXEC-08**: Persisted/job closed-set strings are converted through explicit mappings, never unbounded atom creation.

### Inbound Security and Failure Semantics

- [x] **INB-01**: Pre-verification SES certificate work has bounded concurrency, single-flight misses, strict SNS paths, short negative caching, timeouts, and response-size limits.
- [x] **INB-02**: Inbound S3 retrieval rejects objects larger than the configured 40 MiB default before full materialization.
- [x] **INB-03**: S3 transient and permanent failures are classified accurately and unknown exhausted failures retain the permanent failure shape.
- [x] **INB-04**: Authenticated permanent inbound failures create durable replayable dead evidence before an acknowledgement stops provider redelivery.
- [x] **INB-05**: Inbound verification and normalization use one explicit verified-request value with no process-dictionary or legacy arity coupling.
- [x] **INB-06**: Provider router macros evaluate only validated literal AST rather than unrestricted quoted code.
- [x] **INB-07**: Replay/certificate caches and inbound rate-limit tables cannot grow without bound under unique attacker-controlled keys.

### Data and Lifecycle Correctness

- [x] **DATA-01**: Inbound MIME deduplication uses explicit SHA-256 bytes with a dual-write/read and bounded backfill path; existing installs remain compatible through the transition.
- [x] **DATA-02**: Fingerprint and suppression lookups use their indexed columns without function-casting the indexed side.
- [x] **DATA-03**: Suppression stores may implement positional bulk lookup; stores without it retain a compatible chunked fallback.
- [x] **DATA-04**: Batch delivery performs bounded suppression-query work without changing single-batch outcome semantics.
- [x] **DATA-05**: Suppression resync pages records, deduplicates keys, bulk-loads existing rows, and upserts in bounded chunks.
- [x] **DATA-06**: Core and inbound retention prune in bounded `SKIP LOCKED` batches backed by matching age/source indexes.
- [x] **DATA-07**: Webhook batches bulk-load delivery state and reuse parsed JSON while preserving the exact raw signed body.
- [x] **DATA-08**: Future populated-table migrations follow expand/contract, bounded lock/statement timeouts, and concurrent-index policy without modifying shipped migrations.

### Architecture and Compatibility

- [ ] **ARCH-01**: Core and inbound have zero compile-connected cycles, enforced in CI.
- [ ] **ARCH-02**: Runtime configuration is validated once into an additive `%Mailglass.Runtime{}` value while existing application-env façades remain compatible.
- [ ] **ARCH-03**: Core and inbound capability boundaries expose narrow APIs and explicit sibling integration ports rather than depending on the entire root implementation.
- [ ] **ARCH-04**: Stable Outbound and Config modules remain public façades while mixed orchestration, persistence, dispatch, schema, and registry responsibilities move behind them.
- [ ] **ARCH-05**: Inbound Plug retains its public Plug contract while provider verification, normalization, persistence, broadcast, and response policy move behind an explicit pipeline.
- [ ] **ARCH-06**: Duplicated shared business logic has one owner without collapsing the independently released core and inbound packages.

### CI, Testing, and Maintainability Ratchets

- [ ] **QUAL-01**: Root formatting covers inbound and the repository has one formatted baseline.
- [x] **QUAL-02**: Protected `CI Green` fails when change detection fails or any code lane required for a code change is skipped.
- [ ] **QUAL-03**: Deterministic core/inbound suites, warning/no-optional builds, support contracts, Mix tasks, Credo, conformance, Dialyzer, docs, audits, trust, and installer smoke all block code merges through `CI Green`.
- [ ] **QUAL-04**: Browser/demo/preview/admin-visual, next-toolchain, provider-live, clean-baseline, and publish-only evidence remain advisory and cannot masquerade as merge proof.
- [ ] **QUAL-05**: Repository validation uses locked dependencies; package-scoped caches and exact toolchain pins cannot cross incompatible package/toolchain/environment boundaries.
- [ ] **QUAL-06**: Core and inbound test jobs enforce a measured non-decreasing coverage floor plus explicit critical-path contract tests.
- [ ] **QUAL-07**: Inbound ships under Dialyzer; shipped-library code has no ignored warnings and maintainer-only ignores cannot increase.
- [ ] **QUAL-08**: Standard complexity/nesting checks permit no new exceptions and existing expiring exceptions ratchet downward.
- [ ] **QUAL-09**: Every skipped/flaky test has an owner, reason, and expiry; expired entries fail CI, and async behavior tests use deterministic acknowledgements instead of sleeps/permissive states.
- [ ] **QUAL-10**: Repeated Beam/cache/dependency setup is centralized without changing required check identity, and release policy logic is versioned/tested outside large inline YAML scripts.
- [ ] **QUAL-11**: Dependency updates are grouped across sibling packages, Docker inputs are tracked, job timeouts are explicit, and write permissions exist only on mutation jobs.

### Certification and Release

- [ ] **REL-01**: A real generated Phoenix/Ecto/Postgres host proves fresh install, send/queue persistence, schema upgrade, rollback, idempotent rerun, custom module, multi-repo, and non-public prefix behavior.
- [ ] **REL-02**: Current v2 API/stability documentation identifies additive interfaces, real deprecations, and v3 removal targets without stale phase/version claims.
- [ ] **REL-03**: Live Hex versions and repository manifests are reconciled before the protected release candidate is created.
- [ ] **REL-04**: The protected pipeline publishes additive core/admin and inbound releases and passes exact-Hex post-publish adoption proof without admin/operator UI changes.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Admin/operator UI behavior, styling, navigation, or visual polish | Explicitly deferred; this milestone may only run compatibility and linked-release checks against admin. |
| Breaking removal or renaming of public v2 APIs | Compatibility posture is additive-only; removals wait for v3. |
| New providers, notification policy, auth, billing, support, mobile, or SRE ownership | Remain host/sibling responsibilities and are unrelated to the quality ratchet. |
| Collapsing core, admin, and inbound into one package | Their release and stability boundaries are valuable and remain locked. |
| Arbitrary line-count refactors, blanket async conversion, or vanity coverage targets | Changes require a proven correctness, ownership, or signal benefit. |
| Rewriting already shipped migrations | Applied migration history is immutable. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADOPT-01 | Phase 155 | Complete |
| ADOPT-02 | Phase 155 | Complete |
| ADOPT-03 | Phase 155 | Complete |
| ADOPT-04 | Phase 155 | Complete |
| ADOPT-05 | Phase 155 | Complete |
| ADOPT-06 | Phase 155 | Complete |
| QUAL-02 | Phase 155 | Complete |
| EXEC-01 | Phase 156 | Complete |
| EXEC-02 | Phase 156 | Complete |
| EXEC-03 | Phase 156 | Complete |
| EXEC-04 | Phase 156 | Complete |
| EXEC-05 | Phase 156 | Complete |
| EXEC-06 | Phase 156 | Complete |
| EXEC-07 | Phase 156 | Complete |
| EXEC-08 | Phase 156 | Complete |
| INB-01 | Phase 157 | Complete |
| INB-02 | Phase 157 | Complete |
| INB-03 | Phase 157 | Complete |
| INB-04 | Phase 157 | Complete |
| INB-05 | Phase 157 | Complete |
| INB-06 | Phase 157 | Complete |
| INB-07 | Phase 157 | Complete |
| DATA-01 | Phase 157 | Complete |
| DATA-02 | Phase 157 | Complete |
| DATA-03 | Phase 157 | Complete |
| DATA-04 | Phase 157 | Complete |
| DATA-05 | Phase 157 | Complete |
| DATA-06 | Phase 157 | Complete |
| DATA-07 | Phase 157 | Complete |
| DATA-08 | Phase 157 | Complete |
| ARCH-01 | Phase 158 | Pending |
| ARCH-02 | Phase 158 | Pending |
| ARCH-03 | Phase 158 | Pending |
| ARCH-04 | Phase 158 | Pending |
| ARCH-05 | Phase 158 | Pending |
| ARCH-06 | Phase 158 | Pending |
| QUAL-01 | Phase 159 | Pending |
| QUAL-03 | Phase 159 | Pending |
| QUAL-04 | Phase 159 | Pending |
| QUAL-05 | Phase 159 | Pending |
| QUAL-06 | Phase 159 | Pending |
| QUAL-07 | Phase 159 | Pending |
| QUAL-08 | Phase 159 | Pending |
| QUAL-09 | Phase 159 | Pending |
| QUAL-10 | Phase 159 | Pending |
| QUAL-11 | Phase 159 | Pending |
| REL-01 | Phase 160 | Pending |
| REL-02 | Phase 160 | Pending |
| REL-03 | Phase 160 | Pending |
| REL-04 | Phase 160 | Pending |

---
*Requirements defined: 2026-08-16*
*Last updated: 2026-08-16 after the approved multi-dimensional engineering audit.*
