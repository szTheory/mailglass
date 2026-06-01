---
phase: 67
slug: demo-app-foundation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-01
---

# Phase 67 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| demo app -> public package contract | Demo wiring must not create stable Mailglass API guarantees. | Demo dependency declarations and documentation. |
| rich demo -> reference host | Rich demo work must not pollute the narrow trust-proof host. | Source files and scope documentation. |
| Phoenix process -> browser evidence runner | The evidence runner must not start assertions before the app is ready. | HTTP readiness signal from demo container to evidence runner. |
| npm registry -> evidence image | Browser test dependency resolution must not drift away from the lockfile. | npm package and Playwright browser dependency installation. |
| browser evidence -> demo database | Reset must be deterministic and safe only for demo data. | Scripted reset request and seeded demo-table data. |
| evidence artifacts -> public API claims | Future screenshots/checkpoints must not become stable contract truth. | Evidence labels, README wording, and phase verification claims. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-67-01 | Tampering | `reference/host_app` boundary | mitigate | Scope-lock assertions scan host files for rich-demo marker tokens and fail on drift; verified by `mix verify.phase67`. | closed |
| T-67-02 | Spoofing | Hex dependency mode | mitigate | `MAILGLASS_DEMO_DEPS=hex` switches demo dependencies to published Hex constraints including `mailglass_inbound ~> 0.3.0`; README documents published-smoke command. | closed |
| T-67-03 | Denial of service | Compose readiness | mitigate | Demo container exposes `/health`; `demo_e2e` depends on `demo` with `condition: service_healthy`; verified by Compose config in `mix verify.phase67`. | closed |
| T-67-04 | Tampering | Browser dependency setup | mitigate | `demo_e2e` uses `npm --prefix assets ci --no-audit --no-fund`, `playwright install --with-deps chromium`, and cache volumes/env; verified by `mix verify.phase67`. | closed |
| T-67-05 | Tampering | demo reset path | mitigate | Reset implementation remains under `MailglassDemo*`, requires `DEMO_EVIDENCE_RESET_TOKEN` for `/demo/evidence/reset`, uses constant-time token comparison, and has reset determinism plus security tests. | closed |
| T-67-06 | Repudiation | Phase 67 verification lane | mitigate | Root `mix verify.phase67` bundles host scope lock, demo-app tests, Compose config validation, and source assertions; README labels evidence as adoption evidence, not stable public API. | closed |

---

## Verification Evidence

| Threat ID | Evidence |
|-----------|----------|
| T-67-01 | `test/reference_host/scope_lock_contract_test.exs:54` defines forbidden rich-demo tokens; `mix verify.phase67` ran 3 scope-lock tests with 0 failures. |
| T-67-02 | `reference/demo_app/mix.exs:44` through `reference/demo_app/mix.exs:60` defines Hex-mode dependency switching; `reference/demo_app/README.md:49` documents the published-smoke command. |
| T-67-03 | `reference/demo_app/lib/mailglass_demo_web/router.ex:26` exposes `/health`; `compose.demo.yml:41` and `compose.demo.yml:71` health-gate demo readiness. |
| T-67-04 | `compose.demo.yml:74` through `compose.demo.yml:81` uses lockfile install, Playwright Chromium install, and cache volumes; root alias asserts these strings in `mix.exs:233`. |
| T-67-05 | `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex:141` through `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex:196` authorize evidence reset with a configured token and secure comparison; `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs:10` verifies deterministic reset. |
| T-67-06 | `mix.exs:233` defines `verify.phase67`; `reference/demo_app/README.md:36` through `reference/demo_app/README.md:37` bounds evidence artifacts as non-public API. |

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-01 | 6 | 6 | 0 | Codex |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-01
