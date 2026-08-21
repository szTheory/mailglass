---
phase: 158-simplify-architecture-without-breaking-adopters
verified: 2026-08-17T12:01:32Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
---

# Phase 158: Simplify Architecture Without Breaking Adopters — Verification

## Goal

Core and inbound have explicit, cycle-free ownership and narrow integration seams while existing v2 public façades continue to work.

## Goal Achievement

| Must-have | Evidence | Result |
|---|---|---|
| ARCH-01: no compile-connected cycle can reach users | `test/scripts/architecture_boundary_test.exs` parses both package xref graphs, rejects core-to-inbound AST edges, and tests cycle/CI bypass mutations; CI runs it in the required core support lane. | Verified |
| ARCH-02: one validated additive runtime value with compatible config façades | `Mailglass.Runtime` owns the validated cached config and source fingerprint; `Mailglass.Config` delegates compatibility accessors. Runtime/config/schema tests pass, including refresh and secret-inspection assertions. | Verified |
| ARCH-03: explicit narrow integration ports | `mailglass_inbound/test/mailglass_inbound/architecture_port_test.exs` AST-enforces exact inbound-to-core port allowlists and rejects unapproved root/core calls and raw application-env reads. | Verified |
| ARCH-04: stable Outbound and Config façades hide separated responsibilities | `Mailglass.Outbound` remains the public delivery façade while preflight, routes, persistence, dispatch, and async collaborators own their respective work; focused outbound and public-seam tests pass. | Verified |
| ARCH-05: public Plugs use explicit pipelines | Core `Mailglass.Webhook.Pipeline` and inbound `MailglassInbound.Ingress.Pipeline` own their lifecycles behind retained Plug callbacks; focused Plug, ingest, persistence, mailbox-execution, and pipeline tests pass. | Verified |
| ARCH-06: shared behavior has one owner without package merger | Core/inbound remain independently compiling packages; their allowed cross-package calls are explicit ports and both package xref graphs report no cycles. | Verified |

## Observable Architecture Evidence

- `test/scripts/architecture_boundary_test.exs` makes the compile-cycle and CI-lane checks fail-closed: it verifies the exact required-lane command and rejects disabled steps, permissive `continue-on-error`, and `|| true` / `; true` bypasses.
- The same guard scope-checks every Phase 158 commit across full history, rejects admin/operator UI paths, migrations, added provider paths, and package-collapse changes, and includes synthetic mutation controls.
- `test/reference_host/public_seams_contract_test.exs` proves the retained Config/Outbound façade inventory and that Runtime, Runtime.Schema, and outbound collaborators are not public host seams.
- `mailglass_inbound/test/mailglass_inbound/architecture_port_test.exs` is path-specific rather than a broad prefix allowlist, so a newly introduced inbound dependency must be declared deliberately.

## Fresh Automated Evidence

| Command | Result |
|---|---|
| Root focused architecture/runtime/outbound/webhook/public-seam suite with `--warnings-as-errors` | Passed: 1 property and 188 tests, 0 failures. |
| Inbound focused architecture/Plug/pipeline/persistence/MIME/SES suite with `--warnings-as-errors` | Passed: 115 tests, 0 failures. |
| Root and inbound `mix xref graph --format cycles` | Passed: both report `No cycles found`. |
| Root and inbound compilation with optional dependencies disabled | Passed. |
| Root `mix ci` | Stops at Credo (see residual Phase 159 debt below). |
| Inbound `mix ci` | Stops at `mix format --check-formatted` on pre-existing repository-wide formatting drift (see residual Phase 159 debt below). |

## Residual Quality Debt (Phase 159 Scope)

The full-CI failures are not Phase 158 architecture or adopter-contract defects. Phase 159 is explicitly responsible for the single deterministic full quality gate and formatted baseline.

- Root Credo reports two refactor findings in inbound replay and webhook ingest tests, plus warnings in migration comments, inbound optional-dependency routing, and `Runtime.ses_http_client/0`.
- The SES warning is an existing direct `Application.get_env(:mailglass, :ses, [])` implementation hook moved from `Mailglass.Webhook.Providers.SES` into the runtime owner during the config consolidation; it preserves the prior fallback behavior and is covered by focused tests. Phase 159 should reconcile the Credo rule with this validated internal hook.
- Inbound formatting reports multiple existing files across providers, persistence, router, schemas, and tests; no files were reformatted as part of this verification.

These are maintainability-gate follow-ups, not reasons to alter the passed Phase 158 result.

## Requirement Coverage

| Requirement | Coverage | Status |
|---|---|---|
| ARCH-01 | Required-lane architecture guard, xref cycles, CI mutation controls | Verified |
| ARCH-02 | Runtime ownership and Config compatibility tests | Verified |
| ARCH-03 | Inbound AST port allowlist contract | Verified |
| ARCH-04 | Outbound collaborator and public-seam contracts | Verified |
| ARCH-05 | Core and inbound Plug/pipeline lifecycle tests | Verified |
| ARCH-06 | Independent package compilation and explicit cross-package seams | Verified |

## Anti-Pattern Scan

No Phase 158 blocking defects found:

- No core/inbound compile cycles or direct undeclared sibling dependencies.
- No optional architecture guard or CI bypass path.
- No exposed replacement public seam for Runtime or outbound internals.
- No Phase 158 admin/operator UI scope expansion.

## Human Verification

None required. The phase concerns code boundaries and compatibility contracts covered by executable tests.

## Gaps

None for the Phase 158 goal. Repository-wide Credo/format normalization remains intentionally deferred to Phase 159.
