# Phase 41: SendGrid Ingress And Mailbox Routing - Pattern Map

**Mapped:** 2026-05-06  
**Files analyzed:** existing inbound ingress, persistence, replay, router, and mailbox seams  
**Analogs found:** strong matches for all three roadmap plans

Phase 41 should extend the exact seams Phase 40 introduced instead of inventing parallel architecture. The code already has the right boundary lines: ingress orchestration in `Ingress.Plug`, provider-specific normalization in `Ingress.Providers.*`, transactional receive truth in `Ingress.Persist`, route selection in `Router.Matcher`, and outcome normalization in `InboundRecords`.

## File Classification

| Likely Phase 41 File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex` | service | request-response | `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex` | exact-provider |
| `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` | middleware | request-response | current `mailglass_inbound` plug | exact-flow |
| `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | service | CRUD | current `mailglass_inbound` persist seam | exact-transaction |
| `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` | service | CRUD/transform | current `InboundRecords` outcome normalization | exact-boundary |
| `mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex` or generalized replay module | schema | append-only history | `inbound_records/replay_run.ex` | rename-or-extend |
| `mailglass_inbound/lib/mailglass_inbound/execution.ex` or `mailbox_runner.ex` | service | side effects | outbound/webhook post-transaction posture + mailbox contract | new-but-clear |
| `mailglass_inbound/lib/mailglass_inbound/replay.ex` | service | request-response | current replay truth model in tests | new surface over stored truth |
| `mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs` | test | request-response | `ingress/postmark_provider_test.exs` | exact-test-shape |
| `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` | test | request-response | current ingress plug tests | extend-existing |
| `mailglass_inbound/test/mailglass_inbound/replay_test.exs` | test | CRUD/behavior | current replay lineage tests | extend-existing |

## Pattern Assignments

### `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex`

**Analog:** `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex`

**Copy these rules**

- keep the provider seam conn-free
- keep verification/config checks explicit and fail closed
- return one normalized canonical message plus evidence facts
- isolate provider parsing quirks here, not in the stable public struct

**Phase 41 adaptation**

- parse `multipart/form-data` params instead of JSON
- require the raw MIME `email` part and explicit config help when absent
- use SendGrid `envelope` data for `envelope_recipient`
- keep spam verdicts, auth results, multipart field names, raw MIME, and attachment blobs in evidence

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`

**Analog:** current `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`

**Copy this orchestration pattern**

- verify first
- resolve tenant second
- normalize through the provider module
- persist before any mailbox execution
- map outcomes to explicit HTTP responses

**Phase 41 adaptation**

- support `provider: :sendgrid` without widening the public plug story
- after a successful persist, invoke execution outside the transaction
- continue returning `200` once receive truth is durably stored, even when execution later records non-success outcomes

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`

**Analog:** current `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`

**Copy this transaction pattern**

- one transaction for canonical plus evidence receive truth
- perform duplicate detection inside the same snapshot
- return a compact post-commit handoff result to the caller

**Phase 41 adaptation**

- preserve current Postmark duplicate behavior
- add a provider-specific SendGrid dedupe anchor using a raw-MIME fingerprint
- return matched mailbox identity or `:no_match` so execution can run post-commit
- keep mailbox execution out of this module

---

### `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex`

**Analog:** current `InboundRecords` replay outcome normalization

**Copy this data-shaping pattern**

- centralize outcome normalization at the persistence boundary
- keep append-only semantics by exposing inserts, not updates
- classify semantic outcomes separately from execution failures

**Phase 41 adaptation**

- generalize from replay-only rows to execution rows with `source: :fresh | :replay`
- preserve the current mailbox outcome mapping rules
- add support for `:no_match` as a first-class execution result distinct from `:ignore`

---

### `mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex`

**Analog:** itself

**Copy what matters**

- append-only shape
- links to `inbound_record` and `inbound_evidence`
- explicit outcome / failure normalization

**Phase 41 adaptation**

- either rename to a neutral execution model or expand the schema in place
- add execution source and any small metadata needed for replay/fresh distinction
- avoid storing mutable “latest execution” state on the canonical row

---

### `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex`

**Analog:** itself

**Copy this discipline**

- keep first-match-wins routing
- keep route matching pure over `%InboundMessage{}`
- do not grow matcher semantics as part of Phase 41

**Phase 41 adaptation**

- use the matched route as execution input
- preserve `:no_match` as an explicit outcome in lineage

---

### `mailglass_inbound/lib/mailglass_inbound/mailbox.ex`

**Analog:** itself

**Copy this contract**

- only `:accept`, `:ignore`, `{:reject, reason}`, `{:bounce, reason}` are semantic mailbox outcomes
- raised exceptions, exits, throws, and invalid shapes are execution failures

**Phase 41 adaptation**

- introduce one internal runner that traps execution failures and records them
- do not widen the public mailbox callback surface

## Candidate File Sets By Plan

### 41-01: SendGrid Parse Verification And Normalization

- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex`
- `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex`
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`
- `mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs`
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs`

### 41-02: Mailbox Execution And Append-Only Fresh Lineage

- `mailglass_inbound/lib/mailglass_inbound/execution.ex` or `mailbox_runner.ex`
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex`
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex` or generalized replay schema
- `mailglass_inbound/priv/repo/migrations/*_generalize_replay_runs_to_execution_lineage.exs`
- `mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs`
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs`

### 41-03: Replay, Provider-Specific Dedupe, And Contract Proof

- `mailglass_inbound/lib/mailglass_inbound/replay.ex`
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex`
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex` or generalized replay schema
- `mailglass_inbound/priv/repo/migrations/*_add_sendgrid_fingerprint_and_execution_lineage_fields.exs`
- `mailglass_inbound/README.md`
- `mailglass_inbound/docs/api_stability.md`
- `mailglass_inbound/docs/sendgrid_ingress.md`
- `mailglass_inbound/test/mailglass_inbound/replay_test.exs`
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`

## Recommendation

Do not split execution truth into a second unrelated internal model. The cleanest pattern match is to broaden the existing replay lineage into neutral execution lineage and then expose replay as one specific execution source over stored canonical/evidence truth.
