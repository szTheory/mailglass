---
phase: 67-demo-app-foundation
verified: 2026-06-01T20:05:00Z
status: passed
score: 10/10 must-haves verified
overrides_applied: 0
---

# Phase 67: Demo App Foundation Verification Report

**Phase Goal:** Demo App Foundation for v1.5 Demo Evidence and Click-Around Confidence.
**Verified:** 2026-06-01T20:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | D-01 D-02 D-03: `reference/demo_app` remains the rich Phoenix demo and `reference/host_app` remains a narrow trust-proof host. | ✓ VERIFIED | `reference/host_app/SCOPE.md` explicitly routes rich demo to `reference/demo_app`; scope-lock test blocks rich-demo markers in host files. |
| 2 | D-04 D-05 D-06: local path mode is default, `MAILGLASS_DEMO_DEPS=hex` resolves published packages, and the switch is demo-app wiring only. | ✓ VERIFIED | `reference/demo_app/mix.exs` uses `hex_deps?` env gate and local `path:` deps by default. |
| 3 | Published Hex truth on 2026-06-01 is `mailglass ~> 1.3`, `mailglass_admin ~> 1.3`, and `mailglass_inbound ~> 0.3.0`. | ✓ VERIFIED | Present in `reference/demo_app/mix.exs` hex branches. |
| 4 | D-07 D-08 D-09: `compose.demo.yml` is the canonical local click-around entry and keeps Postgres, Phoenix demo, and browser evidence as separate concerns with cache-aware volumes. | ✓ VERIFIED | `compose.demo.yml` has separate `demo_db`, `demo`, `demo_e2e` services and named cache volumes for Mix/Hex/npm/Playwright/build/deps. |
| 5 | D-10: browser evidence waits for a real Phoenix readiness or healthcheck path through `service_healthy`, not only `service_started`. | ✓ VERIFIED | `demo` has `/health` probe; `demo_e2e.depends_on.demo.condition: service_healthy`; route/controller implement `GET /health` => `ok`. |
| 6 | D-11 D-12: browser dependency installation uses lockfile-respecting `npm ci` and deterministic Playwright browser dependencies while preserving a future clean/no-cache lane. | ✓ VERIFIED | `demo_e2e` command uses `npm --prefix assets ci` and `playwright install --with-deps chromium`; cache env/volumes retained. |
| 7 | D-13 D-14 D-15 D-16: setup/reset aliases stay idiomatic, `mix demo.reset` stays deterministic, and reset wording is explicitly destructive. | ✓ VERIFIED | `demo_data.ex` truncates with `RESTART IDENTITY CASCADE`; README reset note says destructive/truncates; demo reset test proves deterministic rerun counts. |
| 8 | D-17 D-18 D-19: dashboard/login/reset, `/dev/mail`, and `/ops/mail` remain demo-only surfaces using public seams and simple demo-only auth. | ✓ VERIFIED | Router/controller keep these in `MailglassDemoWeb`; login sets demo session keys; security tests cover return_to and reset-token auth. |
| 9 | D-20 D-21 D-22: stable startup/reset/artifact paths for future `demo_browser_evidence.v1` without making DOM/selectors/routes/copy stable public API. | ✓ VERIFIED | README includes `demo_browser_evidence.v1` and explicit non-stable-public-API wording; `mix verify.phase67` provides reusable startup/reset checks. |
| 10 | D-23 D-24: copy stays calm, evidence-first, and uses Mailglass domain language. | ✓ VERIFIED | README/dashboard copy includes preview, delivery, suppression, inbound record, evidence, routing trace, replay, tenant. |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `reference/demo_app/mix.exs` | Dual dependency mode with current published constraints | ✓ VERIFIED | Exists, substantive, wired via `hex_deps?/0` + dependency funcs. |
| `reference/demo_app/README.md` | Boundary and dependency-mode quickstart wording | ✓ VERIFIED | Includes dependency modes, destructive reset, evidence boundary text. |
| `test/reference_host/scope_lock_contract_test.exs` | Executable host/demo boundary guard | ✓ VERIFIED | Asserts required scope tokens and forbids rich demo markers. |
| `compose.demo.yml` | Canonical stack with health-gated evidence and cache volumes | ✓ VERIFIED | Healthchecks + `service_healthy` + cache volumes present. |
| `reference/demo_app/Dockerfile` | Deterministic demo/evidence dependency base | ✓ VERIFIED | Stable base image + system deps; compose command handles deterministic npm/playwright install. |
| `reference/demo_app/lib/mailglass_demo/demo_data.ex` | Deterministic seeded reset contract | ✓ VERIFIED | `truncate!` + deterministic seed functions + summary query. |
| `mix.exs` | Repo-root Phase 67 verification lane | ✓ VERIFIED | `verify.phase67` alias includes scope-lock, demo tests, compose config, and source assertions. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `compose.demo.yml` | `reference/demo_app/lib/mailglass_demo_web/router.ex` | healthcheck URL `/health` | WIRED | Healthcheck path matches router `get "/health"`. |
| `router.ex` | `page_controller.ex` | `post "/evidence/reset", PageController, :evidence_reset` | WIRED | Route and controller action both present. |
| `PageController.evidence_reset/2` | `DemoData.reset!/0` | direct function call | WIRED | Authorized path calls reset and returns summary JSON. |
| `PageController.home/2` | `DemoData.summary/0` | summary assignment and interpolation | WIRED | Dynamic counts/tenant rendered in dashboard HTML. |
| `demo.spec.js` | evidence reset API | `request.post("/demo/evidence/reset")` | WIRED | Before-each reset call with required token header. |
| `mix.exs` alias `verify.phase67` | phase proof commands | alias sequence | WIRED | Includes scope-lock test, demo app tests, compose config, and rg assertions. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `page_controller.ex` home | `summary` | `DemoData.summary()` | Yes (Repo aggregates + SQL count query) | ✓ FLOWING |
| `page_controller.ex` evidence_reset | `summary` JSON field | `DemoData.summary()` after `DemoData.reset!()` | Yes (DB reset + reseed + live recount) | ✓ FLOWING |
| `demo_data.ex` reset path | seeded table counts | `truncate!` + `seed_outbound!` + `seed_inbound!` | Yes (actual inserts via Repo/InboundRecords APIs) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Demo compose config validates with required reset token | `DEMO_EVIDENCE_RESET_TOKEN=phase67-verify docker compose -f compose.demo.yml config` | `COMPOSE_OK` | ✓ PASS |
| Demo test suite passes deterministic/security checks | `cd reference/demo_app && mix test` | 5 tests, 0 failures (orchestrator evidence) | ✓ PASS |
| Phase verification lane is executable | `mix verify.phase67` | passed (orchestrator evidence) | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Step 7c probes | `find scripts -path '*/tests/probe-*.sh'` + phase grep | No phase-67 probes declared/found | ? SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DEMO-01 | 67-01, 67-03 | Separate rich demo app without changing narrow host | ✓ SATISFIED | `reference/demo_app` runnable paths and `reference/host_app` scope lock + marker-blocking test. |
| DEMO-02 | 67-01, 67-03 | Switch demo between local path deps and published Hex constraints | ✓ SATISFIED | `reference/demo_app/mix.exs` `hex_deps?/0` + explicit hex constraints + README command. |
| DX-01 | 67-02, 67-03 | Start Postgres + demo app via Docker Compose | ✓ SATISFIED | `compose.demo.yml` includes `demo_db` and `demo`; compose config validates. |
| DX-02 | 67-02, 67-03 | Preserve Mix/build/npm/browser caches across iterations | ✓ SATISFIED | Named volumes for Mix/Hex/npm/Playwright/root+app+package deps/_build retained. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `reference/demo_app/README.md` | 55 | `JTBD` matched `TBD` regex substring | ℹ️ Info | Not a debt marker; false-positive substring only. |

### Gaps Summary

No must-have, artifact, requirement, or wiring gaps were found in Phase 67 implementation.

---

_Verified: 2026-06-01T20:05:00Z_
_Verifier: the agent (gsd-verifier)_
