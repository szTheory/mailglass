# Phase 46 Deferred Items

Out-of-scope discoveries logged during execution. Do NOT fix in this phase.

## 46-03 Task 2

- **Pre-existing core warning under `--no-optional-deps`:** `warning: unknown module
  Mailglass.Outbound.Worker is listed as an export` at `lib/mailglass/outbound.ex:75`.
  Emitted by the core `mailglass` path-dep when compiled with Oban stripped; the
  worker is Oban-gated. NOT caused by 46-03 changes and does NOT fail the lane
  (exit 0). Out of scope (core file, not inbound). Surfaced for a future core cleanup.
