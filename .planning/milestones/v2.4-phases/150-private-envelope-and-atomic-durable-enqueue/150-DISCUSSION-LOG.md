# Phase 150: Private Envelope and Atomic Durable Enqueue - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-08-02
**Phase:** 150-private-envelope-and-atomic-durable-enqueue
**Mode:** assumptions
**Areas analyzed:** Private payload boundary, Versioned envelope codec, Atomic durable enqueue, Adapter readiness, Legacy compatibility

## Assumptions Presented

### Private payload boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| A one-to-one, schema-prefixed `Outbound.Payload` record separates private transport content from public Delivery metadata. | Confident | `.planning/research/ARCHITECTURE.md`; `lib/mailglass/outbound.ex`; `lib/mailglass/outbound/delivery.ex` |
| New enqueue writes only adopter public metadata to Delivery and keeps all reconstruction content private. | Confident | `base_delivery_attrs/3` and `rehydrate_message/1` in `lib/mailglass/outbound.ex`; ENVL-01 |

### Versioned envelope codec
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| A versioned allowlisted codec captures the complete supported prepared Swoosh field surface and rejects executable/arbitrary terms. | Confident | `.planning/research/ARCHITECTURE.md`; `.planning/research/STACK.md`; `%Swoosh.Email{}` field contract |
| Supported path/upload attachments are materialized once into durable bytes; unsupported or unreadable forms fail before queueing. | Likely | `deps/swoosh/lib/swoosh/attachment.ex`; ENVL-02; `.planning/research/SUMMARY.md` attachment gap |
| Provider options are accepted only when recursively JSON-safe and deterministically keyed. | Likely | ENVL-02; current Swoosh provider-options escape hatch in `guides/authoring-mailables.md` |

### Atomic durable enqueue
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Delivery, queued Event, Payload, and Oban job commit in one Ecto.Multi per envelope. | Confident | Existing `enqueue_oban/3`; `Mailglass.OptionalDeps.Oban.insert/3`; ENVL-05 |
| `deliver_many/2` reuses that per-envelope boundary rather than inserting jobs after commit. | Confident | Current `insert_batch/1` then `enqueue_batch_jobs/1` stranded-work window; `.planning/research/ARCHITECTURE.md` |

### Adapter readiness
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Explicit `:oban` selection fails closed and never falls back; explicit `:task_supervisor` remains non-durable development/test behavior. | Confident | ENVL-06/07; current fallback in `enqueue_via_async_adapter/3`; `lib/mailglass/config.ex` |
| Readiness and production contract checks enforce the worker's compile-time `:mailglass_outbound` queue. | Confident | `lib/mailglass/outbound/worker.ex`; stale `:mailglass` guide example; ENVL-08 |

### Legacy compatibility
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New jobs read private payloads; a narrow legacy metadata reader preserves already queued pre-v2.4 rows without pretending they have full fidelity. | Likely | Current metadata rehydration; `.planning/research/ARCHITECTURE.md`; ENVL-05 forward-compatibility criterion |

## Corrections Made

No corrections — `--auto` accepted all Confident/Likely assumptions using the project's decisive-by-default methodology.

## Auto-Resolved

- Attachment persistence: selected materialization of supported path/upload content into durable private bytes; unsupported forms fail explicitly.
- Provider options: selected a recursively JSON-safe allowlist with deterministic key normalization.
- Legacy rows: selected a narrow compatibility reader rather than lossy backfill or silent abandonment.

## Methodology Applied

- **Decisive-By-Default Research Posture:** existing repository and milestone research supported a cohesive default, so routine implementation choices were locked without another interview round.
- **Honest Surface Area:** the async field set is explicit; unsupported attachment/options shapes fail rather than being silently accepted or dropped.
- **Recommendation-First Synthesis:** one coherent private-envelope and atomic-enqueue design was selected across storage, codec, readiness, and compatibility.
