---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 07
subsystem: mailglass_inbound-ingress
tags: [security, pii, telemetry, credo, egress, TELE-06]
gap_closure: true
wave: 2
requires:
  - "45-05 (.credo.exs path-scope widening + check-behavior pins; landed Wave 0)"
provides:
  - "PII-safe persist-failure egress: static 500 body + PII-free error_kind in telemetry stop-meta"
  - "NoPiiInResponseBody egress Credo check (closes the response-body PII hole logs/telemetry checks miss)"
  - "Fixture test pinning the original inspect(reason) leak shape"
affects:
  - "mailglass_inbound ingress plug error path"
  - "lib/mailglass/webhook/ + mailglass_inbound/.../ingress/ lint surface (now egress-guarded)"
tech-stack:
  added: []
  patterns:
    - "Static closed-code response body on egress (mirror core webhook plug send_resp(conn, 500, \"\"))"
    - "PII detail routed to telemetry stop-meta as a classified atom, never the response/log"
    - "Path-gated custom Credo check (mirror NoFullResponseInLogs skeleton, target response-body sinks)"
key-files:
  created:
    - credo_checks/no_pii_in_response_body.ex
    - test/mailglass/credo/no_pii_in_response_body_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
    - .credo.exs
decisions:
  - "Status stays 500 on persist failure: SendGrid Inbound Parse drops 4xx with no retry; downgrading would permanently lose the email on a transient DB error. A DB error is operational, not an Anymail rejection."
  - "Narrowed NoPiiInResponseBody bare-variable fragments to reason/changeset (NOT body/resp/payload): the JSON helper's generic `send_resp(status, body)` would false-positive. inspect/changeset structural checks catch the real leak vectors regardless of variable name."
  - "log_persist_failure/1 logs only changeset field NAMES via traverse_errors (Map.keys), never the changes values (PII)."
metrics:
  duration: ~4 min
  completed: 2026-05-23
  tasks: 3
  files_changed: 5
requirements: [TELE-06]
---

# Phase 45 Plan 07: PII-Safe Persist-Failure Egress + NoPiiInResponseBody Guard Summary

Closed a recipient-PII leak on the inbound ingress error path — a transient persist failure
was interpolating `inspect(reason)` (an `%Ecto.Changeset{}` carrying recipient subject/from/to/
body fields) into the JSON 500 body sent to the provider — by returning a static closed code,
moving debuggable detail to a PII-free telemetry `error_kind`, and adding a path-scoped
`NoPiiInResponseBody` Credo check (with fixture test) so "no PII in response bodies" is
enforceable rather than convention.

## What Was Built

### Task 1 — PII-safe persist-failure egress (`58a56a4`)
- `plug.ex` `do_call/3` `{:error, reason}` branch now sends a static
  `%{status: "error", reason: "persist_failed"}` body (no `inspect`, no interpolation of `reason`).
- Status retained at **500** (correct retry signal for all four providers; SendGrid drops 4xx).
- Added `classify_persist_error/1` → `:changeset_invalid` | `:not_found` | atom pass-through | `:unknown`,
  attached to the span stop-metadata as `error_kind:` (alongside `provider/tenant_id/status/byte_size`).
  `reason` itself is never added to metadata or passed to exception metadata (this is an `{:error, _}`
  tuple, not a raise — `:stop` enrichment is the right channel).
- Added optional scrubbed `log_persist_failure/1`: logs only changeset **field names** via
  `Ecto.Changeset.traverse_errors/2 |> Map.keys()` — never the `changes` values.
- The three rescue clauses (401/422/500-config) are byte-for-byte unchanged (still emit closed
  `Atom.to_string(e.type)` codes).
- Added a regression test: a changeset carrying PII (`alice@secret.example`, `Confidential merger
  terms`) returns a 500 with body `persist_failed` and the test asserts none of the PII / the string
  `Ecto.Changeset` appears in `resp_body`. Extended `FakePersistence` to honor a
  `:mailglass_inbound_persist_error` process flag (additive; existing `{:ok, ...}` behavior unchanged).

### Task 2 — NoPiiInResponseBody egress Credo check + registration (`0af7b9f`)
- `credo_checks/no_pii_in_response_body.ex` (`Mailglass.Credo.NoPiiInResponseBody`,
  `use Credo.Check, category: :warning, base_priority: :high`). Path-gated `run/2` mirroring the
  `NoFullResponseInLogs` skeleton, but targets **response-body sinks** (`send_resp`, `send_json`,
  `put_resp_body`) in both bare-local and qualified (`Plug.Conn.send_resp`) forms. Flags an argument
  head containing an `inspect(...)` application, an `%Ecto.Changeset{}` literal, or a bare error-like
  variable (name contains `reason`/`changeset`).
- Registered in `.credo.exs` (`extra_checks`, beside the other PII/egress checks) scoped to
  `["lib/mailglass/webhook/", "mailglass_inbound/lib/mailglass_inbound/ingress/"]` — the only
  surfaces that build provider response bodies.

### Task 3 — Fixture test for the check (`4182af5`)
- `test/mailglass/credo/no_pii_in_response_body_test.exs`, `run_check/2` helper + `setup_all` starting
  `:credo`, mirroring the analog. Uses an **in-scope** filename
  (`mailglass_inbound/lib/mailglass_inbound/ingress/fixture.ex`) for the flagged cases (avoids the
  filename trap). Cases:
  (a) `inspect(reason)` in `send_json` → 1 issue (pins the original leak);
  (b) `inspect(changeset)` in `send_resp` → 1 issue;
  (c) `%Ecto.Changeset{}` literal → 1 issue;
  (d) fixed static body → `[]`;
  (e) JSON helper's `send_resp(status, body)` → `[]` (no false positive);
  (f) out-of-scope `lib/mailglass/outbound/foo.ex` with `inspect(reason)` → `[]` (path-gating).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Narrowed NoPiiInResponseBody bare-variable fragments to avoid a self-inflicted false positive**
- **Found during:** Task 2.
- **Issue:** The plan specified `suspicious_fragments: ~w(reason changeset error resp body payload)`.
  But the `send_json/3` helper (the legitimate JSON encoder) calls `send_resp(status, body)` where
  `body = Jason.encode!(payload)` — a generic encoded-binary variable. The fragment `body` (and
  `payload`/`resp`) would flag this safe helper, making `mix credo --strict` fail the green-credo
  acceptance criterion (Task 2 AC #4) and the JSON-helper passing case (Task 3 case e).
- **Fix:** Narrowed the default `suspicious_fragments` to `["reason", "changeset"]` (error-specific
  names). The genuine leak vectors — `inspect(...)` and `%Ecto.Changeset{}` literals — are caught
  structurally regardless of variable name, so coverage of the original leak is preserved. Documented
  the rationale in the check's `param_defaults` comment and moduledoc.
- **Files modified:** `credo_checks/no_pii_in_response_body.ex` (within Task 2 commit `0af7b9f`).
- **Verification:** A standalone AST-walk replication confirmed all 7 fixture shapes match
  expectations (original leak / inspect-changeset / changeset-literal / bare-reason → flagged; static
  body / JSON helper / rescue clause → clean).

## Authentication Gates
None.

## Verification Notes

**Toolchain caveat (as the plan flagged):** deps are unfetched locally (`no _build`, `no credo dep`),
so `mix test` / `mix credo --strict` cannot run in this worktree. CI is the proof
(`inbound_test` job for the plug test; `credo_strict` job + the credo check-test run).

Local proofs performed:
- `Code.string_to_quoted/1` parse-check on all three source/test files → all PARSE OK.
- Standalone Elixir replication of the check's AST-matching logic against 7 fixture shapes →
  all matched expected flag/no-flag (a/b/c/d/e/f + bare-reason-var).
- Source greps confirm: `persist_failed` present and `inspect(reason)` absent in the error branch;
  `error_kind`/`classify_persist_error` present; status 500 retained; 3 rescue `Atom.to_string(e.type)`
  clauses intact; `.credo.exs` registers `NoPiiInResponseBody` with both scoped prefixes.
- Scanned both in-scope egress surfaces (webhook plug + ingress dir) for remaining banned
  response-body shapes → none. All webhook `send_resp` calls use static empty (`""`) bodies; the
  ingress error branch now uses the static closed code. So the new check is green in CI (the only real
  violation was the one Task 1 fixed).

**Pre-existing, out-of-scope (left untouched):** `plug.ex` `safe_broadcast/2` `catch :exit` clause uses
`Logger.debug("... #{inspect(reason)}")`. This is a `Logger.debug` call, not a response-body sink — the
new check does not inspect it, and `NoFullResponseInLogs` only flags `:info/:warning/:error`. Outside
this plan's scope; not modified.

## Known Stubs
None. No hardcoded UI-flowing empties, placeholders, or TODO/FIXME introduced.

## Self-Check: PASSED
- `credo_checks/no_pii_in_response_body.ex` — FOUND
- `test/mailglass/credo/no_pii_in_response_body_test.exs` — FOUND
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` — FOUND (modified)
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` — FOUND (modified)
- `.credo.exs` — FOUND (modified)
- Commit `58a56a4` (Task 1) — FOUND
- Commit `0af7b9f` (Task 2) — FOUND
- Commit `4182af5` (Task 3) — FOUND
