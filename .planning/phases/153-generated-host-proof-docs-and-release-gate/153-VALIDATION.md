---
phase: 153-generated-host-proof-docs-and-release-gate
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-03
requirements: [ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04, ADOPT-05, ADOPT-06, REL-17]
---

# Phase 153 Validation Strategy

## Test Infrastructure

Mailglass already has ExUnit, Ecto SQL sandbox support, PostgreSQL integration tests, workflow contract tests, `mix ci`, package checks, and the Phase 148 release automation. Phase 153 adds a package-shaped generated-host harness and focused contracts before extending production behavior. No new external test dependency is required.

The generated-host harness must create a new application in a temporary directory, use a dedicated PostgreSQL database/schema, consume built-and-unpacked package artifacts in local mode or exact Hex versions in public mode, and clean up its database and filesystem on both success and failure. Tests must not import `MailerCase`, the repository `TestRepo`, fixture adapters, or private modules.

## Wave 0 Test Assets

- [ ] `scripts/generated_host_proof.sh` — canonical isolated host lifecycle, package build/unpack, database allocation, stage selection, and cleanup.
- [ ] `dev/mailglass/generated_host/journey.ex` — one shared local/Hex downstream journey.
- [ ] `dev/mailglass/generated_host/host_template.ex` — fresh-host files and configuration driven by public APIs.
- [ ] `test/generated_host/package_boundary_test.exs` — rejects repository-path/private-helper leakage and validates archive manifests.
- [ ] `test/mailglass/migration_generator_divergence_test.exs` — generated migration equals canonical public migration behavior.
- [ ] `test/mailglass/docs_contract_test.exs` — parses and executes marked documentation contracts.
- [ ] `test/scripts/release_package_resolver_test.exs` — synthetic git histories for package selection.

Wave 0 is incomplete until Plan 01 creates the generated-host harness and first boundary/migration contracts. Every later plan extends that same runner instead of introducing a parallel proof path.

## Per-Plan Verification Matrix

| Plan | Requirement | Automated proof | Failure signal |
|------|-------------|-----------------|----------------|
| 153-01 | ADOPT-01 | `mix test test/mailglass/migration_generator_divergence_test.exs test/generated_host/package_boundary_test.exs --seed 0` and local bootstrap stage | Package/private-boundary leak, migration divergence, install/compile/migrate failure |
| 153-02 | ADOPT-02 | Generated-host delivery tests and `--stage delivery` | No actively polling Oban job, sync/async provider mismatch, lifecycle loss |
| 153-03 | ADOPT-03 | Generated-host negative-control tests and `--stage negative` | False accepted/queued/sent state or any provider/durable side effect |
| 153-04 | ADOPT-04 | Generated-host feedback/one-click tests and `--stage http` | Invalid signature accepted, durable convergence missing, replay creates effects, suppressed send reaches provider |
| 153-05 | ADOPT-05 | Preflight/task tests, production operator tests, and `--stage readiness` | Missing prerequisite passes, secret leaks, anonymous operator access, `dev_routes` production reliance |
| 153-06 | ADOPT-06 | `mix test test/mailglass/docs_contract_test.exs`, `mix mailglass.docs.check`, and `--stage docs` | Unparseable/unexecutable examples or stale contract claim |
| 153-07 | REL-17 | Resolver/workflow tests, full `DEP_MODE=local` journey, `mix ci`, selected package checks, protected candidate-SHA CI | Derived/target mismatch, bypass path, local proof failure, candidate CI failure |
| 153-08 | REL-17 | Workflow/verifier fixture tests, blocking exact-candidate checkpoint, ledger-bound protected publication verifier, and full `DEP_MODE=hex bash scripts/generated_host_proof.sh --stage all` journey | Wrong workflow/environment, absent approval, SHA/tag/package/version/checksum/ledger mismatch, unprotected publication, public journey failure, or missing HexDocs |

## Behavioral Coverage

### Happy-path journey

1. Generate an ordinary Ecto/Phoenix host and configure its own Repo and isolated Postgres schema.
2. Install package-shaped dependencies, compile, generate the complete Mailglass migration wrapper, migrate, and boot.
3. Configure a capture adapter and a genuinely running Oban queue named `mailglass_outbound`.
4. Send the same unstamped default-tenant mail synchronously and asynchronously; compare normalized provider input.
5. Assert queued/running/completed job states, lifecycle records, and scrubbed payload retention.
6. Deliver signed feedback and one-click HTTP requests; verify durable event/ledger convergence and suppression.
7. Run production preflight, reject anonymous operator access, and accept authenticated operator access.
8. Execute or parse documented public examples.
9. Run the identical stages against exact public Hex versions after protected publication.

### Zero-effect negative controls

For missing Oban, missing/wrong/stopped queue, absent migration, schema drift, malformed recipient, malformed payload, invalid signature, and one-click replay, assert the expected public error and all three negative surfaces: no provider capture, no Oban job accepted when the prerequisite fails, and no false sent/queued durable lifecycle state. HTTP rejections must also prove no durable feedback/suppression mutation unless the request is the first valid event.

### Release proof

The release ledger is evidence, not a manually asserted checklist. Each row records the immutable candidate SHA/tag, exact package/version/checksum, protected workflow path/name, environment approval/protection, command or job, timestamp, result, and artifact/workflow URL. D-21 requires every reversible row green before Plan 08. Plan 08 then blocks for explicit one-way publication confirmation; after approval, D-23 permits an operational pause only for protected publication credentials/authentication and never permits bypassing a failed, absent, or drifted check.

## Security Validation

- Signed feedback and one-click requests cover invalid signature, expired request, malformed body, tenant/stream mismatch, and replay.
- Operator routes cover anonymous denial and authenticated success in production configuration.
- Preflight output is checked for secret redaction.
- Generated temporary database/schema names are allowlisted before cleanup; destructive cleanup never targets a broad path or database.
- Hex mode rejects path overrides and floating version constraints; checksums and installed application versions must match release outputs.
- Release workflows prove environment protection, immutable candidate SHA, exact resolver/target agreement, concurrency protection, and absence of direct publish bypasses.

## Multi-Source Coverage Audit

| Source | Item(s) | Plan coverage | Status |
|--------|---------|---------------|--------|
| GOAL | Fresh production-shaped host proves the public first-adopter journey | 153-01 through 153-06 | COVERED |
| GOAL | Contract/configuration drift blocks release | 153-06, 153-07 | COVERED |
| GOAL | Exact public artifacts repeat the proof | 153-08 | COVERED |
| REQ | ADOPT-01 | 153-01 | COVERED |
| REQ | ADOPT-02 | 153-02 | COVERED |
| REQ | ADOPT-03 | 153-03 | COVERED |
| REQ | ADOPT-04 | 153-04 | COVERED |
| REQ | ADOPT-05 | 153-05 | COVERED |
| REQ | ADOPT-06 | 153-06 | COVERED |
| REQ | REL-17 | 153-07, 153-08 | COVERED |
| RESEARCH | Shared package-shaped local/Hex generated-host journey | 153-01, 153-07, 153-08 | COVERED |
| RESEARCH | Complete migration wrapper and divergence guard | 153-01 | COVERED |
| RESEARCH | Real Oban, lifecycle, and zero-effect negative proof | 153-02, 153-03 | COVERED |
| RESEARCH | HTTP feedback/one-click and production readiness | 153-04, 153-05 | COVERED |
| RESEARCH | Executable documentation and deterministic release resolver | 153-06, 153-07 | COVERED |
| CONTEXT | D-01–D-05 | 153-01 | COVERED |
| CONTEXT | D-06–D-08 | 153-02 | COVERED |
| CONTEXT | D-09–D-11 | 153-03 | COVERED |
| CONTEXT | D-12–D-14 | 153-04 | COVERED |
| CONTEXT | D-15–D-16 | 153-05 | COVERED |
| CONTEXT | D-17–D-18 | 153-06 | COVERED |
| CONTEXT | D-19–D-21 | 153-07 | COVERED |
| CONTEXT | D-22 | 153-08 | COVERED |
| CONTEXT | D-23 | 153-08 | COVERED |
| CONTEXT | Deferred ideas | None included | EXCLUDED |

No source item is missing, no deferred idea is planned, and no phase split is required: each plan remains within one vertical concern and approximately half an executor context.

## Exit Criteria

- All focused tests, `mix ci`, documentation checks, and selected package checks are green.
- The local package-shaped journey passes every stage in a fresh host without repository-private helpers.
- Protected CI is green for the exact immutable candidate SHA and resolver/target package sets agree.
- Publication occurs only through the protected workflow.
- The same full journey passes using exact public Hex versions and HexDocs are visible.
- `153-RELEASE-PROOF.md` contains observed evidence for every gate and no inferred success.
