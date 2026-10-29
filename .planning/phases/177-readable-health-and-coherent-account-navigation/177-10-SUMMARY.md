---
phase: 177-readable-health-and-coherent-account-navigation
plan: "10"
subsystem: ui
tags: [demo, navigation, preview, return-context, host-auth]
status: complete

requires:
  - phase: 177-03
    provides: Preview return context threading and the Back link
provides:
  - "Demo Preview navigation points directly at /ops/mail, /ops/mail?view=deliveries, /ops/mail/inbound"
  - "MailglassDemoWeb.AdminAuth logged-out :operator_access deny with to: /demo/login?return_to=<arrival path and query>"
  - "Demo ExUnit proof (9 tests) and advisory Playwright spec (2 tests)"
  - "MailglassAdmin.Router :navigation doc sentence (D-03)"
affects: [177-11]

plan_head_before: 18365071a0425689cc505dd72708ad3345f997f7
plan_head_after: 79ff8a9e04b2ca1f3d06252ffb47de6b60ac72cf

actuals:
  tokens: 9000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Host adapter builds the post-login return from Phoenix.LiveView.get_connect_info(socket, :uri); the existing login safe_return_to/1 stays the single validator"

key-files:
  created:
    - reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs
    - reference/demo_app/assets/e2e/phase177-return.spec.js
  modified:
    - reference/demo_app/lib/mailglass_demo_web/router.ex
    - reference/demo_app/lib/mailglass_demo_web/admin_auth.ex
    - mailglass_admin/lib/mailglass_admin/router.ex

key-decisions:
  - "D-07 deny form: arrival path and query via get_connect_info(:uri), capped at 2048 bytes, fallback /ops/mail plus binary tenant_id/view (each 1..255 bytes) through URI.encode_query/1"
  - "guides/run-the-demo.md and reference/demo_app/README.md left unchanged: they describe login links only and make no Preview-return claim"

requirements-completed: ["UXF-10"]

coverage:
  - id: D1
    description: "Demo Preview nav targets the operator surfaces; logged-in and logged-out Fjordline Deliveries/Inbound returns land on Fjordline; hostile and oversized arrivals stay on /ops/mail; referrer policy asserted"
    requirement: UXF-10
    verification:
      - kind: integration
        ref: "reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs#Phase 177 logged-out Fjordline Deliveries return lands on Fjordline after login"
        status: pass
    human_judgment: false
  - id: D2
    description: "Router docs gain one :navigation sentence; no option, session key or api_stability.md change"
    requirement: UXF-10
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/router_test.exs (22 tests) and full admin suite (995 tests, 0 failures)"
        status: pass
    human_judgment: false
---

# Phase 177 Plan 10: Demo Preview Return and Logged-out Account Return Summary

**The reference demo now returns Preview to the originating Account (Fjordline) both logged in and logged out, through a host-owned `return_to` deny form built from the arrival URI; mailglass gained one docs sentence and no new option.**

## Accomplishments

- Demo Preview `navigation` replaced the three static Northstar `/demo/login?return_to=...` wrappers with `/ops/mail`, `/ops/mail?view=deliveries`, `/ops/mail/inbound` (operator mount untouched).
- `AdminAuth.authorize(:operator_access, context)` (after the logged-in clause) denies with `to: "/demo/login?return_to=" <> URI.encode_www_form(return_path(context))`. `return_path/1` uses `arrival_uri/1` (`get_connect_info(socket, :uri)`, only for a `%Phoenix.LiveView.Socket{}`), falling back to `params_path/1` when the URI is nil or longer than 2048 bytes. The login `safe_return_to/1` is unchanged.
- Demo ExUnit proves: logged-out `/ops/mail` -> `return_to=%2Fops%2Fmail`; logged-out Fjordline Deliveries follows login and lands on exactly `/ops/mail?view=deliveries&tenant_id=fjordline-aps` with the account label showing Fjordline; Inbound equivalent; hostile `return_to` query keeps every Location header host-less; oversized arrival uses the bounded fallback; socketless fallback drops unknown params; other actions keep the original catch-all; Preview Back link href decodes to the Fjordline Deliveries URL; no-context Preview nav hrefs are the three direct paths; `referrer-policy: strict-origin-when-cross-origin` on `/ops/mail` and Preview responses.
- `MailglassAdmin.Router` moduledoc `:navigation` bullet: paths should point directly at operator surfaces, not login or wrapper URLs. `git diff -U0` = 3 added lines in that bullet only.

## Commands and results

- Red run before implementation: 9 tests, 8 failures. After: `MIX_ENV=test mix test phase177_navigation_test.exs page_controller_security_test.exs --seed 0 --trace` -> 21 tests, 0 failures; trace includes "Phase 177 logged-out Fjordline Deliveries return lands on Fjordline after login".
- Advisory demo browser: `npm run test:e2e -- phase177-return.spec.js` -> 2 passed. The combined run with `demo.spec.js --grep "Phase 177 demo|Preview"` printed 2 passed and 2 failed; the 2 failures (`dashboard links to preview and operator surfaces`, `preview distinguishes the public component and AtlasDesk HTML authoring paths`) fail in `beforeEach` at `POST /demo/evidence/reset` (`response.ok()` false) because `DEMO_EVIDENCE_RESET_TOKEN` is not set in this shell. Environmental, before any Preview assertion runs; not caused by this plan. demo-e2e-exit recorded as 0 (non-blocking lane).
- `mailglass_admin`: `router_test.exs` 22 tests, 0 failures; full `mix test --seed 0` 995 tests, 0 failures, 1 excluded; `mix format --check-formatted lib/mailglass_admin/router.ex` clean.
- Acceptance greps: `to: "/demo/login"}` in admin_auth.ex 0; `get_connect_info` 1 (baseline 0); `return_to=%2Fops%2Fmail` in router.ex 0 (baseline 3); `return_surface|return_tenant_id` in admin router.ex 0.
- `git diff --quiet` on `reference/demo_app/mix.lock`, `reference/demo_app/mix.exs` and `mailglass_admin/docs/api_stability.md` holds after all runs.

## Deviations from Plan

**1. [Process] `mix format --check-formatted` on `admin_auth.ex` reports pre-existing drift**
- The `:destructive_action` clause line (untouched, pre-existing) exceeds the formatter's line length. I formatted only the new test file and left `admin_auth.ex`'s pre-existing drift alone (scope boundary; a bare format would reflow unrelated lines).

**2. [Own-test correction] Back link appears twice**
- The Preview renders the Back link in sidebar and mobile layouts; the test asserts all instances share one href instead of expecting a single element. No code change.

**Total deviations:** 1 process note, 1 own-test fix. **Impact:** none on scope.

## Known Stubs

None.

## Threat Flags

None. T-177-22 (open redirect) mitigated with a fixed `/demo/login?return_to=` prefix, encoding, size cap and the unchanged `safe_return_to/1`, covered by the hostile-query and oversized tests. T-177-23 asserted by the referrer-policy test. No package or lockfile change.

## Self-Check: PASSED

- Created and modified files exist; commits 6eccfe5b and 79ff8a9e reachable from HEAD.
