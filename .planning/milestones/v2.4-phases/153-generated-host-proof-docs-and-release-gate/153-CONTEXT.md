# Phase 153: Generated-Host Proof, Docs, and Release Gate - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning
**Mode:** Auto-discussed from locked requirements, completed Phases 149-152, prior release evidence, and codebase assumptions audit

<domain>
## Phase Boundary

Prove the complete first-adopter journey in a disposable, production-shaped Phoenix/Ecto/Postgres host using only supported package and host APIs; make that proof fail closed on configuration, schema, queue, and input drift; reconcile the executable public guidance; and release only the packages changed by the v2.4 work before repeating the journey against the exact published versions. This phase owns the generated-host harness, production readiness and operator-mount proof, documentation convergence, release selection, and post-publication evidence. It does not add providers, recipient fan-out, admin visual work, host product policy, or fixture-only Mailglass test seams.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<specifics>
## Specific Ideas

- Replace the current trust runner's file/fake stages with one checkpointed journey whose stages are install, migrate, boot/readiness, sync parity, actively-polled async parity, negative controls, signed feedback, one-click replay/enforcement, operator mount, and package identity.
- Give every host run a unique database/schema and deterministic sentinel IDs, then emit a bounded JSON proof manifest with package lock identities and checkpoint hashes.
- Run the exact journey twice: package-shaped local mode before publication and exact Hex mode afterward. Only dependency source and expected package versions should differ.
- Keep the generated host after failure when explicitly requested for diagnosis, but make normal CI cleanup deterministic.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and completed runtime contracts

- `.planning/ROADMAP.md` §Phase 153 and `.planning/REQUIREMENTS.md` ADOPT-01..06 / REL-17.
- `.planning/PROJECT.md` — v2.4 adopter goal, ownership boundaries, and package policy.
- `.planning/phases/149-first-send-contract-foundation/149-CONTEXT.md` and verification — public first-send, tenancy, recipient, renderer, and preflight contract.
- `.planning/phases/150-private-envelope-and-atomic-durable-enqueue/150-CONTEXT.md` and verification — package-private envelope, atomic job, and canonical queue/readiness contract.
- `.planning/phases/151-unified-dispatch-honest-outcomes-and-payload-lifecycle/151-CONTEXT.md` and verification — provider-input parity, outcome, scrubbing, retention, and real-worker contract.
- `.planning/phases/152-atomic-one-click-suppression-convergence/152-CONTEXT.md` and verification — signed one-click convergence, replay, scope, and post-commit contract.

### Host, installer, operations, and documentation

- `scripts/consumer_install_smoke.sh`, `reference/host_app/`, and `dev/mix/tasks/mailglass.trust.run.ex` — reusable orchestration plus the current shallow/fake seams that must be replaced.
- `lib/mix/tasks/mailglass.install.ex`, `lib/mix/tasks/mailglass.gen.migration.ex`, `lib/mailglass/migration.ex`, and `lib/mailglass/migrations/postgres.ex` — public install/migration boundary.
- `lib/mailglass/config.ex`, `lib/mailglass/optional_deps/oban.ex`, and `lib/mailglass/outbound/worker.ex` — production readiness and canonical queue boundary.
- `README.md`, `guides/getting-started.md`, `guides/authoring-mailables.md`, `guides/rate-limiting.md`, `guides/production-go-live-checklist.md`, `guides/multi-tenancy.md`, `guides/compatibility-and-deprecations.md`, and admin packaging guidance/tests — executable published documentation surface.

### Release authority and prior evidence

- `.planning/milestones/v2.3-phases/148-release-and-adoption-proof/` — prior protected release and consumer-proof patterns, including limitations superseded here.
- `.planning/release-target.json`, `release-please-config.json`, `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, and `.github/workflows/post-publish-smoke.yml` — release-set, protected publication, and published-consumer mechanisms.
- `lib/mix/tasks/mailglass.publish.check.ex` and package `mix.exs` files — package contents, versions, and dry-run validation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `scripts/consumer_install_smoke.sh` already creates a fresh Phoenix application and supports path and exact-Hex dependency modes, but currently generates `--no-ecto`, proves only compile/boot/dev mail UI, and must be expanded or complemented for Phase 153.
- The prior Phase 148 release workflows already enforce protected CI, changed linked-package posture, registry wait, Hex-only locks, and post-publish artifacts.
- Public outbound, webhook, one-click, migration, readiness, maintenance, and admin modules already contain most runtime behavior; Phase 153 should expose and integrate them rather than recreate them in the host.
- Phase 149-152 focused tests provide canonical negative inputs and expected durable outcomes that can be transplanted into production-shaped host checkpoints.

### Known Gaps

- `reference/host_app` uses broad package ranges, starts only its Repo, and lacks the production outbound/Oban configuration required by ADOPT-01..04.
- The current trust runner treats multiple stages as file checks and its webhook proof injects fake persistence/execution modules and source-loads local code.
- The migration generator currently emits an incomplete historical subset rather than wrapping the full current versioned Mailglass migration contract.
- Existing operator routes are guarded by dev-route configuration rather than proving an authenticated production mount.
- Several published guides contain stale table-count, async-reconstruction, or version-posture language that predates the Phase 149-152 behavior.

### Integration Points

- The generated host's capture adapter must observe the same public provider input consumed by sync dispatch and the real Oban worker.
- The prepublication journey must feed protected publish selection, and the release event must feed the exact-version post-publication rerun.
- Release artifacts must bind the changed-package decision to actual package contents and the generated host's lockfile, not only declared version strings.

</code_context>

<deferred>
## Deferred Ideas

- New provider implementations, transport classes, multiple-recipient fan-out, HEEx assigns, sent-message snapshot viewing, and ecosystem adapters.
- Admin visual polish or a redesigned operator product; Phase 153 proves production availability of the existing surface.
- Alpha-owned notification preferences, authentication, billing, support, paging, mobile activation, and external launch gates.
- Generalizing Mailglass into a full deployment orchestrator; the host proof remains a release gate and reference journey.

</deferred>

---

*Phase: 153-generated-host-proof-docs-and-release-gate*
*Context gathered: 2026-08-03*
