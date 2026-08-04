# Phase 153: Generated-Host Proof, Docs, and Release Gate - Research

**Researched:** 2026-08-03
**Domain:** Phoenix/Ecto/Postgres consumer-host acceptance proof, release gating, and published documentation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Disposable adopter host and package boundary

- **D-01:** The canonical proof creates a fresh stock Phoenix host with Ecto and PostgreSQL in a disposable directory. It must not treat the repository's existing reference host, a pre-populated demo application, or source-file existence checks as equivalent evidence.
- **D-02:** Before publication, the same host journey consumes package-shaped local artifacts or paths that exercise the Hex package allowlists and public compile surface. After publication, a second clean host installs exact versions from Hex with no path or git dependencies.
- **D-03:** The host uses only documented adopter APIs and host-owned integration modules. It may implement a small capture provider adapter through the public adapter contract, but may not load repository test support, `MailerCase`, the repo-local `TestRepo`, fake persistence/execution modules, hidden tenant stamps, inline workers, or private Mailglass modules.
- **D-04:** The generated host installs the Mailglass package family required by its mounted journey. `mailglass` and `mailglass_admin` remain the linked release line; `mailglass_inbound` remains independently versioned and is consumed at its already-published compatible version unless an actual source/package change makes it part of the changed set.

### Real schema, queue, and delivery proof

- **D-05:** The host runs the public generated migration wrapper against a unique non-`public` schema, then proves all current Mailglass tables and migration-version state exist only where configured. A generator that emits an incomplete historical table subset is a release blocker and must be corrected at the public generator boundary.
- **D-06:** The positive durable path starts a real Oban instance with an actively polling positive-concurrency `mailglass_outbound` queue. Enqueue followed by inline/manual worker invocation, test draining, or direct `perform/1` does not satisfy the proof.
- **D-07:** An unstamped `Mailglass.Tenancy.SingleTenant` caller sends one supported message synchronously and the equivalent message asynchronously as tenant `"default"`. The host capture adapter records canonical provider input, and the proof compares supported wire fields while excluding timing and provider-generated values.
- **D-08:** The async proof observes the real queued job transition and durable delivery/event/payload lifecycle through public or host-owned database observations. It must show provider dispatch occurred through polling and that successful settlement scrubs private queued content according to the Phase 151 contract.

### Fail-closed negative controls

- **D-09:** Missing Oban, an unavailable instance, a missing `mailglass_outbound` queue, and a wrong queue each run as independent host controls and must fail before a false `:queued` result, job, delivery/event/payload quartet, provider capture, or background task appears.
- **D-10:** Missing migrations, wrong schema configuration, and schema-version drift each fail production readiness or the attempted operation with bounded actionable errors. No control may pass merely because a default `search_path` finds objects in `public`.
- **D-11:** Zero/multiple recipients and unsupported payload or provider-option shapes fail before rendering side effects, durable mutation, queue insertion, or provider capture. Every negative control includes explicit zero-side-effect assertions so the gate is non-vacuous.

### Feedback and unsubscribe journey

- **D-12:** Provider feedback enters through a real signed HTTP webhook path configured exactly as an adopter would configure it. The host verifies the signature and asserts the durable event/ledger result after commit; injected fake persistence or direct internal ingest calls are prohibited.
- **D-13:** The host obtains a real signed one-click URL for an originating stream delivery, sends the RFC 8058 POST through HTTP, replays it, and proves one canonical event/suppression pair with the exact privacy-preserving response contract.
- **D-14:** After the replay, the host attempts a new same-tenant/address/stream send through the public outbound boundary and observes preflight suppression. Transactional or unrelated-stream controls remain sendable so the proof cannot hide accidental scope widening.

### Production operations and executable guidance

- **D-15:** One callable production preflight covers configured repo/schema accessibility, selected adapter shape, webhook signature-verification configuration, running canonical Oban queue, payload-maintenance scheduling or documented manual fallback, and an authenticated production-available operator mount. Ordinary library boot remains compatible with supported non-production/optional-dependency use.
- **D-16:** The operator proof mounts the existing admin capability in production-shaped router configuration without relying on `:dev_routes`. This phase changes availability, authentication/configuration, and proof only; it does not redesign the admin UI.
- **D-17:** README, Getting Started, authoring, rate-limit, production, multi-tenancy, compatibility/deprecations, and admin packaging guidance are executed or structurally extracted against the generated host. They must consistently describe the current 2.x single-recipient, default-tenant, canonical-queue, payload-lifecycle, schema, webhook, and package-boundary contracts.
- **D-18:** Documentation gates validate commands and code blocks, not only keyword presence. Stale claims such as an incomplete table count, metadata-based async reconstruction, dev-only operator availability, or outdated version posture block release.

### Changed-package release and post-publication gate

- **D-19:** Determine the release set from actual package-source and packaged-doc changes since each package's last published tag, cross-check it against `.planning/release-target.json`, and fail on either omitted changed packages or mechanically included unchanged siblings. The workflow's broad manual `all` default is not release authority.
- **D-20:** `mailglass` and `mailglass_admin` remain linked when either linked package requires the coordinated version train. `mailglass_inbound` is not republished unless its own changed package surface requires it; compatibility consumption is not a reason to publish it.
- **D-21:** No live publish occurs until the package-shaped local journey, full repository gates, security/validation evidence, version/changelog/package checks, exact release-target check, and protected CI evidence are green. The release version is derived by the established Release Please/versioning mechanism rather than guessed in Phase 153 planning.
- **D-22:** Publication uses the existing protected release and Hex workflows without bypass overrides. Completion requires registry/HexDocs availability and a fresh exact-version Hex-only generated-host journey that repeats the positive, negative, feedback, unsubscribe, readiness, and operator evidence relevant after installation.
- **D-23:** A credential or external protected-environment requirement may pause only the irreversible publication step. All local implementation, package dry-runs, workflow validation, and prepublication evidence continue first; no artifact may claim REL-17 complete until the exact public versions pass the clean consumer journey.

### the agent's Discretion

- Exact disposable-host orchestration language and artifact schema, provided local and published modes share the same behavioral journey.
- Whether the public migration repair extends the existing generator or introduces a clearly documented wrapper, provided a stock host receives the complete current schema through supported APIs.
- Exact capture-adapter storage mechanism inside the generated host, provided it implements only public contracts and produces deterministic PII-free evidence.
- Exact production-preflight task/module composition and operator authentication example, provided every D-15 dimension is behaviorally checked.
- Exact release-proof artifact names and hashes, provided they bind package versions, source commit, host inputs, commands, checkpoints, and zero-side-effect negative controls without credentials or message content.

### Deferred Ideas (OUT OF SCOPE)

- New provider implementations, transport classes, multiple-recipient fan-out, HEEx assigns, sent-message snapshot viewing, and ecosystem adapters.
- Admin visual polish or a redesigned operator product; Phase 153 proves production availability of the existing surface.
- Alpha-owned notification preferences, authentication, billing, support, paging, mobile activation, and external launch gates.
- Generalizing Mailglass into a full deployment orchestrator; the host proof remains a release gate and reference journey.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| ADOPT-01 | Clean Phoenix/Ecto/Postgres host installs package family, schema-isolated migrations, and public APIs. | Replace `--no-ecto` smoke path and repair generated migration wrapper; share path/Hex harness. |
| ADOPT-02 | Default-tenant sync/real-Oban async have equivalent input. | Host capture adapter plus polling-observed durable queue checkpoint. |
| ADOPT-03 | Queue/schema/input negative controls fail before effects. | Independent process/config variants and DB/capture/job count assertions. |
| ADOPT-04 | Signed feedback and replayed one-click enforce suppression. | Real router HTTP requests with host-configured Postmark key and token URL. |
| ADOPT-05 | Production preflight and authenticated operator mount work. | Public readiness composition plus non-`dev_routes` router mount. |
| ADOPT-06 | Public guidance is executable and consistent. | Extend docs checker with executable-code-block/host commands and stale-claim assertions. |
| REL-17 | Publish only changed packages and prove exact public versions. | Changed-set resolver, protected workflow proof artifact, existing Hex/HexDocs wait and post-publish job. |
</phase_requirements>

## Summary

Phase 153 should be one behavioral journey, parameterized only by dependency origin: package-shaped local artifacts before publication and exact Hex versions after it. The current `scripts/consumer_install_smoke.sh` is a useful fresh-host shell but intentionally uses `mix phx.new --no-ecto --no-mailer`; it can only prove installer/compile/dev-preview boot today. The current trust runner is also not evidence for this phase because its install/preview/send stages are file-existence checks and its webhook evidence calls repo-local proof code. [VERIFIED: codebase grep]

Use a generated host that owns its Repo, minimal capture adapter, router, authenticated session endpoint/plugs, and proof task. It must use published public runtime APIs, start real Oban with `mailglass_outbound: > 0`, issue HTTP for webhooks and one-click POST, and query only host-owned database observations. The common runner should produce bounded JSON evidence (IDs/hashes/statuses only), retain failed hosts only under an explicit diagnostic flag, and clean normal runs deterministically. [VERIFIED: codebase grep]

**Primary recommendation:** Build a single disposable-host journey runner with `local` and `hex` dependency modes; make it the prepublication required gate and the post-publication exact-version gate.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Host creation, package source injection, cleanup, manifest | CLI / CI | Filesystem | The runner owns isolation and records resolved package identities. [VERIFIED: codebase grep] |
| Migration/schema proof | Database / Storage | Host CLI | Ecto runs generated wrapper; catalog queries prove objects are in configured schema. [VERIFIED: codebase grep] |
| Async dispatch proof | API / Backend | Database / Storage | Oban worker polls persisted job and Mailglass writes durable lifecycle records. [VERIFIED: codebase grep] |
| Capture parity | API / Backend | Host-owned adapter | A public adapter contract observes canonical provider input for both paths. [VERIFIED: codebase grep] |
| Webhook/unsubscribe proof | Frontend server (router) | API / Backend | Real HTTP routes verify/configure input then commit durable facts. [VERIFIED: codebase grep] |
| Operator availability | Frontend server (router) | Browser / Client | Adopter router controls production auth scope; admin macro supplies LiveView routes. [VERIFIED: codebase grep] |
| Release selection/public proof | CI/CD | Hex registry | Workflow determines changed packages and repeats the consumer journey after publication. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Phoenix | existing host family `~> 1.8` | Generate/router/HTTP host | Existing consumer script and reference host already use Phoenix 1.8 conventions. [VERIFIED: codebase grep] |
| Ecto SQL + Postgrex | existing host family `~> 3.13` / `~> 0.22` | Real Repo, migrations, schema queries | Required by the public migration and durable Mailglass contracts. [VERIFIED: codebase grep] |
| Oban | host dependency `~> 2.23` | Polling async execution | Hex identifies current 2.23.1 (2026-08-03); queues run only outside manual/inline modes, so proof must use normal supervised mode. [CITED: https://hexdocs.pm/oban/Oban.html] |
| Jason | existing host family `~> 1.4` | Bounded proof manifest and webhook JSON | Existing host and package already rely on it. [VERIFIED: codebase grep] |

### Supporting

| Tool | Purpose | When to use |
|---|---|---|
| `mix phx.new` | Fresh stock host | Every local and Hex proof run. [VERIFIED: codebase grep] |
| `mix phx.routes` | Router surface check | Assert production operator/webhook/unsubscribe routes are compiled. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |
| Existing `mix mailglass.publish.check` | Allowlist, tarball, changelog, metadata, prod resolution and isolated compile checks | Each actually selected package before protected publication. [VERIFIED: codebase grep] |

**Installation:** The generated host must add only its own normal Phoenix/Ecto/Postgres/Oban dependencies plus selected Mailglass package dependencies; it must not add repository test support or private Mailglass modules. [VERIFIED: 153-CONTEXT.md]

## Package Legitimacy Audit

| Package | Registry | Current registry evidence | Verdict | Disposition |
|---|---|---|---|---|
| `oban` | Hex | `mix hex.info oban` reported 2.23.1 on 2026-08-03, Apache-2.0, `oban-bg/oban`, 201,058 seven-day downloads. [CITED: https://hex.pm/packages/oban] | Approved | Use the official package already used by the repository; host pin/range must be aligned with root lockfile compatibility. |

The package-legitimacy seam supports only npm/PyPI/crates, not Hex; no unsupported verdict was invented. No new Mailglass package is introduced. [VERIFIED: package-legitimacy CLI usage]

## Architecture Patterns

### System Architecture Diagram

```text
mode=local (package-shaped paths) OR mode=hex (exact versions)
        │
        ▼
fresh phx.new + Ecto/Postgres host ──► public install + generated migration wrapper
        │                                      │
        │                                      ▼
        ├────► non-public schema/catalog checks + migration version
        │
        ▼
host supervision: Repo + real Oban(mailglass_outbound > 0) + endpoint
        │
        ├──► sync public send ─┐
        ├──► async public send ─► persisted job ─► polling worker ─► capture adapter
        │                      │                                  │
        │                      └──► DB delivery/event/payload lifecycle ┘
        ├──► HTTP signed webhook ─► verified ingest ─► durable ledger/event
        ├──► HTTP one-click POST x2 ─► convergence/suppression ─► next-send preflight
        └──► production authenticated operator route
        │
        ▼
PII-free proof manifest (inputs, package locks, checkpoint hashes, status)
        │
        ├── prepublish: changed-set + package checks + protected CI
        └── postpublish: Hex/HexDocs wait + same hex journey + retained artifact
```

### Recommended Project Structure

```text
scripts/generated_host_proof.sh                  # canonical common local/hex host lifecycle
scripts/check_generated_host_proof.sh            # manifest/schema validator
scripts/consumer_install_smoke.sh                 # preserve as quick install/boot smoke or delegate
dev/mix/tasks/mailglass.generated_host.proof.ex  # root task if Elixir controls checkpoints
dev/mix/tasks/mailglass.production.preflight.ex  # callable public readiness composition
reference/host_app/                               # update only as production-mount example; not proof substitute
test/generated_host/                      # runner, negative-control, manifest contract tests
test/mailglass/                           # generator/preflight/docs/release selection contracts
.github/workflows/                        # protected prepublish and postpublish orchestration
```

### Pattern 1: Same journey, two dependency modes

**What:** Make the runner accept `DEP_MODE=local|hex`, exact versions for `hex`, and a shared checkpoint suite. Local mode must package-check/build package-shaped artifacts (not source-load private files); Hex mode must prohibit path and git dependency forms after a clean dependency resolve. [VERIFIED: 153-CONTEXT.md]

**Why:** Existing smoke already parameterizes `path|hex`, but path mode currently proves the working tree and Hex mode is only a quick installer/boot smoke. This phase needs equivalent behavior rather than two divergent scripts. [VERIFIED: codebase grep]

### Pattern 2: Polling-observed asynchronous assertion

**What:** Start a normal Oban supervisor with `queues: [mailglass_outbound: positive_integer]`, enqueue through `Mailglass.deliver_later/2`, and poll bounded host DB/capture state until terminal success; assert the job left an available/executing state and payload was scrubbed after successful settlement. Do not use `Oban.drain_queue`, `perform/1`, inline mode, or manual test mode as the acceptance signal. [CITED: https://hexdocs.pm/oban/testing.html]

### Pattern 3: One negative control per isolated host invocation

**What:** Vary one configuration/input condition per run, then assert an actionable bounded failure and counts for jobs, deliveries, events, payloads, render/capture records remain unchanged. Use unique DB/schema/sentinel IDs so a `public` fallback cannot make a control vacuously pass. [VERIFIED: 153-CONTEXT.md]

### Pattern 4: Public router proof

**What:** Host router uses `Mailglass.Webhook.Router.mailglass_webhook_routes/2` or equivalent public plug mount and `mailglass_operator_routes/2` inside a normal authenticated production scope; issue actual HTTP requests and validate route compilation with `mix phx.routes`. The host’s auth module is adopter-owned and passes only documented session keys. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]

### Anti-Patterns to Avoid

- **Reference-host equivalence:** `reference/host_app` uses broad package ranges, starts only `Repo`, and guards mounts with `:dev_routes`; it cannot satisfy D-01/D-06/D-16. [VERIFIED: codebase grep]
- **File existence as proof:** Current trust stages `:install`, `:preview`, and `:send` only call `require_file!`; replace rather than rename them. [VERIFIED: codebase grep]
- **Fake test seams:** No `MailerCase`, repo-local `TestRepo`, fake persistence/execution, direct `perform/1`, or private Mailglass module call is admissible. [VERIFIED: 153-CONTEXT.md]
- **Search-path dependence:** A configured non-public schema must be validated through catalog queries, not object lookup that can fall through to `public`. [VERIFIED: codebase grep]
- **Broad release default as authority:** `workflow_dispatch` currently defaults to `all`; changed-set computation and release target must decide the release set. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Version/publication orchestration | New publishing pipeline | Existing Release Please, protected `publish-hex.yml`, and post-publish smoke | They already bind tag checkout, protected CI, Hex/HexDocs polling, retraction checks, and artifacts. [VERIFIED: codebase grep] |
| Public schema DDL | Copy of all versioned migration DDL in host | Public `Mailglass.Migration.up/1` via repaired generated Ecto wrapper | Keeps generator and shipped package contract as the single migration boundary. [VERIFIED: codebase grep] |
| Async simulation | Custom in-process worker execution | Real normal-mode Oban supervisor and its persisted queue | Oban manual/inline modes disable background queues, so they cannot prove polling. [CITED: https://hexdocs.pm/oban/testing.html] |
| Webhook/unsubscribe behavior | Reimplemented signature/token logic | Published router/plug and unsubscribe routes | Existing public code owns verification and convergence behavior. [VERIFIED: codebase grep] |
| Documentation gate parsing | Keyword-only grep | Existing `mix mailglass.docs.check` plus compile/run generated snippets | Existing checker has Tier-1 rules; this phase must add behavioral execution. [VERIFIED: codebase grep] |

## Common Pitfalls

### Pitfall 1: Generator still emits a historical subset
**What goes wrong:** `mailglass.gen.migration` currently creates one `mailglass_events` table inside `change/0`, while public `Mailglass.Migration` dispatches versions 1–7. [VERIFIED: codebase grep]
**Avoidance:** Generate `up/0`/`down/0` wrapper that calls `Mailglass.Migration`; add a stock-host migration test that enumerates all expected tables and verifies version in the configured schema only.

### Pitfall 2: Oban configuration checks but does not poll
**What goes wrong:** `Mailglass.OptionalDeps.Oban.ready?/1` inspects loaded dependency/configured queue, but it does not prove a live producer dispatches work. [VERIFIED: codebase grep]
**Avoidance:** Require observable job state transition plus adapter capture and durable lifecycle under a deadline.

### Pitfall 3: Negative proof has pre-existing state
**What goes wrong:** Shared schemas, capture rows, or queue records can make zero-side-effect assertions meaningless. [ASSUMED]
**Avoidance:** Fresh database/schema and deterministic sentinel per run; include before/after counts and no capture/task evidence in manifest.

### Pitfall 4: Production operator is still dev-only
**What goes wrong:** Current reference router wraps both mounts in `if Application.compile_env(..., :dev_routes, false)`. [VERIFIED: codebase grep]
**Avoidance:** Add a dedicated production-shaped scope with authentication and explicit allowed session keys; prove unauthorized and authorized paths separately.

### Pitfall 5: Release logic silently republishs or skips a package
**What goes wrong:** Existing release target hard-codes current three package versions while workflows have broad manual `all` selection. [VERIFIED: codebase grep]
**Avoidance:** Compute source + packaged-doc diff against each package tag; fail if it disagrees with release-target selection in either direction, then feed that same list to prepublish/publish/postpublish proof.

## Code Examples

### Correct public migration wrapper

```elixir
# Source: lib/mailglass/migration.ex public API
defmodule Sandbox.Repo.Migrations.MailglassInstall do
  use Ecto.Migration

  def up, do: Mailglass.Migration.up()
  def down, do: Mailglass.Migration.down()
end
```

### Production-shaped Oban configuration

```elixir
# Source: official Oban configuration + Mailglass canonical worker queue
config :sandbox, Oban,
  repo: Sandbox.Repo,
  queues: [mailglass_outbound: 1, mailglass_maintenance: 1]
```

`testing: :inline` and `testing: :manual` are invalid for the acceptance journey because they disable supervised queues/plugins. [CITED: https://hexdocs.pm/oban/testing.html]

### Production operator mount

```elixir
# Source: mailglass_admin/lib/mailglass_admin/router.ex
scope "/ops" do
  pipe_through [:browser, :require_authenticated_operator]

  mailglass_operator_routes "/mail",
    auth: SandboxWeb.MailglassAdminAuth,
    session: [subject_id: "operator_id", tenant_id: "operator_tenant_id"],
    unauthorized_path: "/sign-in"
end
```

## State of the Art

| Old approach | Current required approach | Impact |
|---|---|---|
| `--no-ecto` installer/preview boot smoke | Generated Ecto/Postgres host with non-public schema and actual migration wrapper | Proof covers the durable contract users install. [VERIFIED: codebase grep] |
| File/fake trust stages | HTTP/DB/queue-observed checkpoints | Evidence detects runtime integration drift rather than source existence. [VERIFIED: 153-CONTEXT.md] |
| Fixed three-package release target | Diff-derived changed set, with linked core/admin rule and independent inbound rule | Avoids both omitted changes and mechanical sibling publication. [VERIFIED: 153-CONTEXT.md] |

## Likely Files and Responsibilities

| File | Change |
|---|---|
| `scripts/consumer_install_smoke.sh` | Refactor or delegate so a fresh Ecto host can serve the shared journey rather than only quick `--no-ecto` smoke. [VERIFIED: codebase grep] |
| `scripts/generated_host_proof.sh` (new) | Disposable host lifecycle, local/Hex dependency injection, deterministic cleanup/keep-on-failure, and entrypoint to host proof task. [ASSUMED] |
| generated host template/files under `scripts/` or `reference/host_app/` | Host-owned Repo, capture adapter, endpoint/router/auth, runtime config, proof task and migrations. Exact location is discretionary; never reuse source test support. [ASSUMED] |
| `lib/mix/tasks/mailglass.gen.migration.ex` | Replace incomplete historical migration emission with public wrapper. [VERIFIED: codebase grep] |
| `lib/mix/tasks/mailglass.production.preflight.ex` and/or `lib/mailglass/production_preflight.ex` (new) | One callable D-15 readiness report with bounded actionable failures. [ASSUMED] |
| `dev/mix/tasks/mailglass.trust.run.ex` | Replace shallow stage pipeline or redirect to generated-host runner; evolve checkpoint schema and validator. [VERIFIED: codebase grep] |
| `test/reference_host/*`, `test/generated_host/*` (new), `test/mailglass/shipped_migration_divergence_test.exs` | Contract tests for runner stages/manifests, public migration completeness, and negative controls. [VERIFIED: codebase grep] |
| `reference/host_app/*` | Update only to demonstrate production operator mount/package posture or retire it from canonical proof claims. [VERIFIED: codebase grep] |
| `README.md`, named `guides/*.md`, `mailglass_admin/README.md`, `mailglass_admin/docs/operator-trust.md` | Align 2.x recipient, default tenant, canonical queue, schema, payload, webhook, and operator claims; make examples executable. [VERIFIED: 153-CONTEXT.md] |
| `lib/mix/tasks/mailglass.docs.check.ex`, `test/mailglass/docs_contract_test.exs` | Enforce current guidance and command/code-block structure beyond keywords. [VERIFIED: codebase grep] |
| `.planning/release-target.json`, `.github/workflows/publish-hex.yml`, `.github/workflows/post-publish-smoke.yml`, `test/scripts/*` | Diff-derived release selection, protected prepublish journey, exact Hex rerun, and workflow contracts. [VERIFIED: codebase grep] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/Mix/OTP | Generate and run host | ✓ | OTP 28 detected; project `.tool-versions` remains CI authority | none |
| PostgreSQL CLI | Schema proof/local diagnosis | ✓ | psql 14.17 | CI already uses Postgres 16 service. [VERIFIED: codebase grep] |
| Docker | Optional local Postgres | ✓ | 29.5.2 | local installed Postgres / CI service |
| curl | HTTP endpoint/webhook/unsubscribe proof | ✓ | 8.7.1 | none |
| Hex | exact published mode | ✓ | `mix hex.info oban` succeeded | no local substitute for postpublish proof |

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit; root `mix ci` plus sibling support-contract aliases. [VERIFIED: codebase grep] |
| Config | `mix.exs`; generated host adds its own normal config/runtime files. [VERIFIED: codebase grep] |
| Quick run | `mix test test/mailglass/shipped_migration_divergence_test.exs test/reference_host/ --warnings-as-errors` after DB setup. [ASSUMED] |
| Full suite | `mix ci` then package-shaped generated-host journey. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| ADOPT-01 | Stock host install, non-public complete migration, public boot | integration | `DEP_MODE=local bash scripts/generated_host_proof.sh --stage migrate` | ❌ Wave 0 |
| ADOPT-02 | Sync/real-polled async parity and lifecycle | integration | `... --stage async-parity` | ❌ Wave 0 |
| ADOPT-03 | Independent queue/schema/input fail-closed controls | integration | `... --stage negative-controls` | ❌ Wave 0 |
| ADOPT-04 | Signed webhook + one-click replay/enforcement HTTP | integration | `... --stage feedback-unsubscribe` | ❌ Wave 0 |
| ADOPT-05 | Preflight + auth production operator mount | integration | `... --stage readiness-operator` | ❌ Wave 0 |
| ADOPT-06 | Executable docs and stale claims | unit/contract | `mix mailglass.docs.check && mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ extend |
| REL-17 | Changed set + pre/post publish selected exact package proof | workflow/contract | `mix test test/scripts/ --warnings-as-errors` and protected workflows | ✅ extend |

### Wave 0 Gaps

- [ ] Create a generated-host proof runner and host-owned proof modules.
- [ ] Add manifest validator that rejects credentials, recipient/message/token content, missing stage identity, and missing zero-effect evidence.
- [ ] Add contract tests for public generated migration full current schema (including V01–V07), production preflight, release-set diff, and workflow wiring.
- [ ] Add a CI service-backed job that runs local package-shaped proof before publication and exact Hex proof after publication.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Adopter-owned authenticated operator mount; verify authorized and denied paths. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Explicit `subject_id`/tenant session whitelist in operator macro, never full session pass-through. [VERIFIED: codebase grep] |
| V4 Access Control | yes | `MailglassAdmin.Auth` `:operator_access` through production router scope. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Real webhook signature verification plus preflight invalid-input controls before effects. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Existing signed webhook and Phoenix-token one-click verification; do not reimplement signing. [VERIFIED: codebase grep] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Unsigned/forged webhook | Spoofing | HTTP route with configured signature key; assert failure precedes durable writes. [VERIFIED: 153-CONTEXT.md] |
| Production admin accidentally exposed | Elevation of privilege | Authenticated normal router scope and denied-route assertion. [VERIFIED: codebase grep] |
| Proof artifact leaks PII/secret/token | Information disclosure | Emit only hashes, versions, stage status, bounded IDs/counts; validate schema before upload. [VERIFIED: 153-CONTEXT.md] |
| `public` schema masks misconfiguration | Tampering | Unique non-public schema plus catalog-qualified assertions. [VERIFIED: 153-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `scripts/generated_host_proof.sh` is the canonical runner; templates remain under `dev/mailglass/generated_host/`. | Likely Files | RESOLVED — all plans, workflows, and validation use this single entry point. |
| A2 | A separate public production-preflight task/module is needed rather than extending an existing task. | Likely Files | Could duplicate an existing public readiness surface. |
| A3 | The suggested focused test command is suitable after host runner exists. | Validation | Exact test topology may use host commands instead. |

## Open Questions

1. **(RESOLVED) Where should host-owned fixture source live?**
   - Resolution: `scripts/generated_host_proof.sh` is the single runner entry point. Runner-owned templates live under `dev/mailglass/generated_host/` and are copied into the temporary application only after an unmodified fresh `mix phx.new` completes. `reference/host_app` remains reference material and is never the release gate.

2. **(RESOLVED) How should changed packaged docs be attributed?**
   - Resolution: one auditable resolver owns the package manifest/allowlist and compares each package against its own latest reachable package tag. The same resolver applies the core/admin linked-release rule, preserves inbound independence, and rejects any release-target omission or extra package.

## Sources

### Primary (HIGH confidence)
- `.planning/phases/153-generated-host-proof-docs-and-release-gate/153-CONTEXT.md` — locked scope and acceptance controls.
- Repository source and tests named in that context — installer, migration, queue, trust runner, router, docs, and release workflows.
- `.planning/phases/149-*` through `152-*` context/verification artifacts — completed runtime contracts.
- `.planning/milestones/v2.3-phases/148-release-and-adoption-proof/148-RELEASE-PROOF.md` — prior protected/Hex proof pattern and its superseded limitations.

### Secondary (MEDIUM confidence)
- [Oban testing configuration](https://hexdocs.pm/oban/testing.html) — manual/inline modes disable queues/plugins.
- [Oban configuration](https://hexdocs.pm/oban/Oban.html) — queue concurrency and normal-mode runtime behavior.
- [Phoenix router documentation](https://hexdocs.pm/phoenix/Phoenix.Router.html) — router pipelines and `mix phx.routes` verification.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing pinned project stack plus official Oban/Phoenix docs.
- Architecture: HIGH — driven by locked decisions and current implementation gaps.
- Pitfalls: HIGH — directly observed generator, host, trust-runner, and workflow behavior; one isolation assertion is explicitly assumed.

**Valid until:** 2026-09-02 for implementation surfaces; recheck Hex versions immediately before publication.
