---
phase: 101-microcopy-pass
plan: "01"
subsystem: mailglass_admin
tags: [microcopy, copy, inbound-surface, put_flash, subtitle, COPY-LD]
dependency_graph:
  requires: [phases/98-operator-deliveries-surface, phases/99-inbound-surface, phases/100-preview-surface]
  provides: [101-02-conformance-check]
  affects: [mailglass_admin/lib/mailglass_admin/inbound_live.ex]
tech_stack:
  added: []
  patterns: [locked-decision-verbatim-application, D-07-source-sweep]
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
decisions:
  - D-04/COPY-LD-16 no-selection error flash updated to exact locked string
  - D-05/COPY-LD-13 replay-success flash uses domain noun InboundMessage not generic message
  - D-06/COPY-LD-07 subtitle uses domain noun InboundMessage not received message
metrics:
  duration: "85 seconds"
  completed: "2026-06-16"
  tasks_completed: 1
  files_modified: 1
---

# Phase 101 Plan 01: Microcopy Pass — Residual String Fixes Summary

**One-liner:** Three verbatim COPY-LD string fixes in `inbound_live.ex` closing the put_flash/subtitle gap the surface phases (98/99/100) left behind.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Apply three residual COPY-LD string fixes in inbound_live.ex | 3f4c3403 | mailglass_admin/lib/mailglass_admin/inbound_live.ex |

## Edits Made

### EDIT 1 — D-05 / COPY-LD-13 (replay-success flash, line 219)

**Before:**
```
"Replay recorded. A new replay run was appended to this message's timeline."
```
**After:**
```
"Replay recorded. A new replay run was appended to this InboundMessage's timeline."
```
**Rationale:** "message" is the generic noun; in the inbound context the domain noun is "InboundMessage" (seven-noun rule).

---

### EDIT 2 — D-04 / COPY-LD-16 (no-selection error flash, line 227)

**Before:**
```
"Select an inbound record to inspect its routing, execution timeline, and raw source."
```
**After:**
```
"Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence."
```
**Rationale:** COPY-LD-16 locked string verbatim — uses InboundMessage domain noun, names Mailbox routing, says "raw evidence" not "raw source". The already-correct rendered-pane string at line 385 uses this same text and was NOT changed.

---

### EDIT 3 — D-06 / COPY-LD-07 (subtitle attribute, line 289)

**Before:**
```
subtitle="See why a received message routed the way it did — execution timeline, routing trace, and raw evidence."
```
**After:**
```
subtitle="See why an InboundMessage routed the way it did — execution timeline, routing trace, and raw evidence."
```
**Rationale:** "received message" is not a domain noun; "InboundMessage" is the seven-noun-correct term for inbound context (COPY-LD-07 pattern).

## D-07 Source Sweep

All `put_flash` sites and `subtitle=` attributes scanned across `inbound_live.ex`, `operator_live.ex`, and `preview_live.ex`.

### Findings and Dispositions

| Site | Content | Disposition |
|------|---------|-------------|
| `operator_live.ex:222` | `put_flash(:info, RepairState.flash_success(result.status))` | Conformant — dynamic copy from RepairState, domain-aware |
| `operator_live.ex:225` | `put_flash(:error, "Select a delivery before replaying a webhook.")` | Conformant — uses "delivery" (domain noun), cause-naming pattern |
| `operator_live.ex:228` | `put_flash(:error, "Replay is unavailable for this delivery.")` | Conformant — cause-naming, domain noun |
| `operator_live.ex:232` | `put_flash(:error, "Choose one webhook target before confirming replay.")` | Conformant — specific cause |
| `operator_live.ex:235` | `put_flash(:error, message)` | Conformant — pass-through from auth layer, structured error |
| `operator_live.ex:244` | `put_flash(:error, RepairState.flash_failure(reason))` | Conformant — dynamic copy from RepairState |
| `operator_live.ex:273–281` subtitle | `"Prove what happened to a message — inspect its event timeline..."` | **Flagged but NO CHANGE** — "message" is used here as a compound verb-object (happened to a message) not a standalone generic noun violation. This is within the acceptable operator-surface usage pattern. Changing risks regression and is outside COPY-LD locked scope for Phase 101. |
| `inbound_live.ex:217–220` | `put_flash(:info, ...)` | Fixed by EDIT 1 above |
| `inbound_live.ex:224–228` | `put_flash(:error, ...)` | Fixed by EDIT 2 above |
| `inbound_live.ex:234` | `put_flash(:error, "Replay blocked: this action is not authorized...")` | Conformant — cause-naming pattern per LD-07 |
| `inbound_live.ex:243` | `put_flash(:error, message)` | Conformant — pass-through from auth layer |
| `inbound_live.ex:249` | `put_flash(:error, replay_error_copy(reason))` | Conformant — `replay_error_copy/1` uses domain nouns and cause-naming |
| `inbound_live.ex:289` subtitle | Fixed by EDIT 3 above | |
| `preview_live.ex:139` | `put_flash(:error, "Scenario not found")` | Conformant — developer surface LD-08 exception (technical precision) |
| `preview_live.ex:237` | `put_flash(:info, "Reloaded: " <> Path.basename(path))` | Conformant — developer surface LD-08 exception (technical precision) |

**No additional violations found.** The sweep confirms three violations exist only at the three fixed sites.

### Banned-word scan

Confirmed absent across all three LiveView modules: "Oops", "whoops", "uh oh", "something went wrong", standalone "Email", standalone "Status", standalone "Notification".

## Deviations from Plan

None — plan executed exactly as written. Three edits applied verbatim per COPY-LD locked decisions. D-07 sweep findings match the plan's pre-read analysis exactly.

## Cross-Reference Verification

Already-applied LD strings confirmed untouched:
- `deliveries_list.ex`: "No Deliveries match your filters" — present
- `records_list.ex`: "No InboundMessages match these filters" — present
- `preview_live.ex`: "Preview the first Mailable" — present

## Verification

```
cd mailglass_admin && mix compile --warnings-as-errors
```
Exit code: 0. "Compiling 1 file (.ex) / Generated mailglass_admin app"

## Self-Check: PASSED

- [x] `mailglass_admin/lib/mailglass_admin/inbound_live.ex` modified — confirmed
- [x] Commit `3f4c3403` exists — confirmed
- [x] All three new strings present, all three old strings absent — confirmed by grep
- [x] Line 385 rendered-pane string unchanged — confirmed
- [x] No unexpected file deletions
