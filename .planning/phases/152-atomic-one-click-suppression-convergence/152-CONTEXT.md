# Phase 152: Atomic One-Click Suppression Convergence - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning
**Mode:** Auto-discussed from locked requirements, prior unsubscribe contracts, and codebase evidence

<domain>
## Phase Boundary

Make a valid built-in RFC 8058 POST converge atomically into the canonical unsubscribe event and an immediately enforceable stream-scoped suppression. This phase owns transactionality, replay/concurrency behavior, tenant and schema-prefix safety, HTTP success/failure semantics, and post-commit lifecycle effects for one-click unsubscribe. It does not add new suppression scopes, redesign token formats, build Phase 153's generated-host proof, or change the Phase 151 delivery/payload lifecycle.

</domain>

<decisions>
## Implementation Decisions

### Token authority and derived scope

- **D-01:** The signed one-click token identifies a Delivery; it does not carry independent authority for tenant, recipient, or stream. The server derives the tenant, normalized recipient address, and originating stream from the stored Delivery.
- **D-02:** The initial Delivery lookup remains the existing narrowly audited unscoped lookup by opaque Delivery ID only. After resolving the tenant, every event and suppression read/write runs inside restored tenant context and against the configured schema prefix.
- **D-03:** A missing Delivery, invalid/tampered token, or expired token is a privacy-preserving no-op. These cases retain the exact empty HTTP 200 response and reveal no delivery existence or token-validity distinction.

### Atomic canonical convergence

- **D-04:** One database transaction must create or reuse both durable facts: the canonical `unsubscribed` event for the originating Delivery and one immutable `address_stream` suppression with reason `unsubscribe` for the derived tenant/address/stream. Neither fact may commit alone.
- **D-05:** Event identity remains delivery-based through the canonical `unsubscribe:<delivery_id>` idempotency key. Suppression identity is the existing tenant/address/scope/stream uniqueness contract. Implementation may use conflict-safe insertion plus refetch, but a uniqueness race must converge rather than become a false failure.
- **D-06:** Concurrent and replayed valid POSTs converge on the same event/suppression pair. Every successful convergence returns the required exact empty HTTP 200 response; it never produces duplicate durable facts.
- **D-07:** An actual database/convergence failure returns a non-success response and leaves no partial event/suppression pair. It must not be disguised as the privacy-preserving 200 used for invalid, expired, or absent-token targets.

### Immediate enforcement and scope isolation

- **D-08:** The suppression address uses the project's canonical normalized-recipient representation, and the stream comes from the originating Delivery. No request parameter or token field may widen or substitute that scope.
- **D-09:** Once the transaction commits, the next preflight for the same tenant/address/stream is blocked. An `address_stream` unsubscribe must not block transactional mail or mail in unrelated streams.
- **D-10:** Immediate enforcement is proved through the real preflight/send boundary, not only by asserting that a suppression row exists.

### Post-commit side effects

- **D-11:** Database mutation completes before any host lifecycle callback or broadcast. The existing one-click path's in-`Ecto.Multi` lifecycle behavior is superseded where necessary to enforce this ordering.
- **D-12:** Callbacks and broadcasts are best-effort post-commit effects. Their failure cannot roll back or partially alter the Mailglass event/suppression pair, and it cannot cause a valid committed unsubscribe to be reported as a failed database convergence.
- **D-13:** External/host side effects run only for the request that newly creates the convergence. Replays and uniqueness-race losers do not emit duplicate callbacks or broadcasts.
- **D-14:** Side-effect payloads contain only bounded, non-sensitive domain facts already appropriate for the host integration; the signed token and private message content are never forwarded.

### Tenant and schema hardening

- **D-15:** Every operation added to an `Ecto.Multi`, including conflict resolution and refetch, receives the configured prefix explicitly where required by Ecto. Correctness must not depend on the connection's `search_path`.
- **D-16:** Hostile-`search_path` tests must include decoy or absent default-schema data and prove that both durable facts land only in the configured tenant-safe schema.
- **D-17:** Failure injection must prove rollback of the complete pair, a non-success response, and zero callback/broadcast effects.

### Compatibility and evidence

- **D-18:** Preserve the public one-click route and exact empty success-body contract. Internal lifecycle seams may evolve to post-commit execution, but unrelated public callback compatibility should be retained where it does not conflict with D-11 through D-13.
- **D-19:** Contract tests must cover first POST, serial replay, true concurrent replay, uniqueness races, invalid/expired/missing targets, transaction rollback, post-commit effect failure, suppression preflight enforcement, stream isolation, tenant isolation, and hostile schema search paths.

### the agent's Discretion

- Internal module/function names for the convergence service and post-commit effect runner.
- Whether concurrency is implemented with conflict-target inserts, locks, or a compatible combination, provided D-04 through D-07 hold under real concurrent database tests.
- Exact non-success HTTP status for a genuine convergence failure, provided it is stable, documented, and never an empty success.
- The minimal compatibility adapter needed to move the current lifecycle hook out of `Ecto.Multi` while preserving unaffected host integrations.
- Exact broadcast topic/event name where the existing projector convention already supplies a compatible choice.

</decisions>

<specifics>
## Specific Ideas

- Treat one-click handling as a convergence operation whose result distinguishes `created`, `already_converged`, `privacy_noop`, and `failed`; only `created` schedules post-commit effects.
- Use database uniqueness as the concurrency authority and return the canonical persisted rows after either the insert or conflict path.
- Keep the HTTP surface deliberately boring: a byte-empty 200 for privacy no-ops and successful convergence, with no token or row identifiers in the body.
- Verify the behavioral outcome by attempting sends: same stream is suppressed immediately, while transactional and unrelated-stream sends proceed.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and phase boundary

- `.planning/ROADMAP.md` §Phase 152 — goal, requirements, and five success criteria.
- `.planning/REQUIREMENTS.md` §One-click suppression convergence — UNSUB-07..11.
- `.planning/PROJECT.md` — v2.4 milestone scope, maintenance posture, compatibility policy, and release boundary.

### Upstream unsubscribe and send contracts

- `.planning/milestones/v0.2-phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md` and its verification artifacts — original route, token, response, event, and lifecycle behavior.
- `.planning/milestones/v0.2-phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md` — original unsubscribe-to-stream-suppression mapping and suppression convergence decisions.
- `.planning/phases/149-first-send-contract-foundation/149-CONTEXT.md` — current preflight, normalization, suppression-scope, tenancy, and prefix decisions.
- `.planning/phases/149-first-send-contract-foundation/149-VERIFICATION.md` — executable evidence for preflight and suppression enforcement.
- `.planning/phases/149-first-send-contract-foundation/149-VALIDATION.md` — automated tenant, schema-prefix, privacy, and preflight controls that Phase 152 must preserve.
- `.planning/phases/151-unified-dispatch-honest-outcomes-and-payload-lifecycle/151-CONTEXT.md` — current send boundary and explicitly deferred Phase 152 ownership.

### Public compatibility and operations

- `docs/api_stability.md` — compatibility promises for public callbacks and error behavior.
- `guides/production-go-live-checklist.md` — suppression and one-click production expectations.
- `guides/compatibility-and-deprecations.md` — supported upgrade and deprecation expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The built-in one-click controller already verifies the signed token, performs the narrow Delivery lookup, restores tenant context, and returns the exact empty success response for privacy no-ops.
- `Mailglass.Events.append_multi/3` and the event partial unique index provide the canonical delivery-scoped unsubscribe idempotency seam.
- Existing suppression storage and uniqueness constraints provide the durable tenant/address/scope/stream convergence authority.
- `Mailglass.Repo.multi/1` and Phase 149 prefix-aware operations provide established transaction and hostile-`search_path` patterns.
- Existing lifecycle and projector/broadcast modules provide host-effect seams, though the one-click invocation must move after commit.

### Established Patterns

- Resolve tenant identity from trusted persisted state before entering tenant-scoped work.
- Add explicit Ecto prefixes to every Multi operation; never inherit correctness from ambient `search_path`.
- Suppression matching is normalized and scope-aware; stream-scoped records do not widen to global/transactional suppression.
- Public unsubscribe responses are privacy-preserving and byte-empty.

### Integration Points

- The current one-click controller appends the event transactionally but does not create the suppression in the same transaction.
- The current lifecycle hook is invoked inside the controller's Multi, which conflicts with the locked post-commit ordering and must be adapted deliberately.
- Existing projector broadcasting is a reusable post-commit pattern.
- Preflight suppression evaluation is the downstream enforcement boundary for UNSUB-09.

</code_context>

<deferred>
## Deferred Ideas

- Generated Phoenix host, production-shaped Oban proof, broad executable adopter journey, and release ceremony — Phase 153.
- New suppression scopes, unsubscribe preference centers, GET-based unsubscribe semantics, or token-format redesign.
- Phase 151 provider-dispatch and private-payload lifecycle changes.
- Exactly-once guarantees for arbitrary external host systems; Phase 152 guarantees no duplicate invocation from Mailglass replays/concurrency within its process boundary.

</deferred>

---

*Phase: 152-atomic-one-click-suppression-convergence*
*Context gathered: 2026-08-03*
