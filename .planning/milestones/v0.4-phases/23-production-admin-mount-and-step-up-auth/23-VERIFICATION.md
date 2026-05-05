---
phase: 23-production-admin-mount-and-step-up-auth
verified: 2026-05-01T16:48:33Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
---

# Phase 23: Production Admin Mount and Step-Up Auth Verification Report

**Phase Goal:** Make the operator surface production-mountable and establish the step-up auth seam required for later destructive actions.
**Verified:** 2026-05-01T16:48:33Z
**Status:** passed

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Preview and operator routes no longer share one `live_session`. | ✓ VERIFIED | `mailglass_admin_routes/2` mounts only preview routes, while `mailglass_operator_routes/2` mounts the operator route through its own `live_session` in [mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:128). |
| 2 | Adopters can mount the production operator surface without mounting preview routes in the same scope. | ✓ VERIFIED | The new public `mailglass_operator_routes/2` macro exists and is exercised under `/ops/mail` in [mailglass_admin/test/support/endpoint_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/endpoint_case.ex:42). |
| 3 | Preview and operator session callbacks are explicit and narrowly whitelisted. | ✓ VERIFIED | `__preview_session__/2` returns only `mailables` and `live_session_name`, while `__operator_session__/2` maps only the configured auth keys in [mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:219). |
| 4 | Operator access is enforced through a stack-agnostic mount seam. | ✓ VERIFIED | `MailglassAdmin.Operator.Mount` calls `MailglassAdmin.Auth.authorize/3` and redirects on denial in [mailglass_admin/lib/mailglass_admin/operator/mount.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/mount.ex:18). |
| 5 | Future destructive actions have a normalized recent-auth contract to call. | ✓ VERIFIED | `MailglassAdmin.Auth` normalizes actor metadata and preserves `:unauthorized` / `:stale_auth` outcomes in [mailglass_admin/lib/mailglass_admin/auth.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/auth.ex:1). |
| 6 | The read-only operator LiveView still renders correctly after the auth split. | ✓ VERIFIED | `OperatorLive` now carries auth-related assigns without adding destructive handlers in [mailglass_admin/lib/mailglass_admin/operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:24). |
| 7 | Unauthorized operator mounts are rejected predictably. | ✓ VERIFIED | `operator_live_test.exs` covers missing and blocked actor redirects in [mailglass_admin/test/mailglass_admin/operator_live_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs:179). |
| 8 | Package docs now distinguish dev preview mounting from production operator mounting. | ✓ VERIFIED | [mailglass_admin/README.md](/Users/jon/projects/mailglass/mailglass_admin/README.md:1) documents both surfaces and keeps auth ownership with the adopter. |

## Commands Run

| Command | Result | Status |
| --- | --- | --- |
| `cd mailglass_admin && mix test test/mailglass_admin/router_test.exs test/mailglass_admin/auth_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | `21 tests, 0 failures` | ✓ PASS |
| `cd mailglass_admin && mix compile --warnings-as-errors` | `Generated mailglass_admin app` | ✓ PASS |
| `cd mailglass_admin && mix test test/mailglass_admin/post_installer_smoke_test.exs --warnings-as-errors` | `2 tests, 0 failures` | ✓ PASS |

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| `ADMIN-01` | ✓ SATISFIED | Production operator mounting now uses `mailglass_operator_routes/2`, a dedicated mount hook, and updated README guidance. |
| `ADMIN-05` | ✓ SATISFIED | `MailglassAdmin.Auth` and `MailglassAdmin.Operator.Mount` establish the server-side recent-auth seam for later destructive actions. |

## Gaps Summary

No Phase 23 implementation gaps were found against the plan must-haves or requirement mapping. Destructive replay and suppression-removal controls remain intentionally out of scope for this phase.

---

_Verified: 2026-05-01T16:48:33Z_
_Verifier: Codex_
