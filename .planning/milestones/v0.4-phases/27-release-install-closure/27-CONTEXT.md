# Phase 27: release-install-closure - Context

**Gathered:** 2026-05-01 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the two known release/install gaps before the v0.4 milestone ships:

- REL-17: fresh-host install must no longer fail because of Swoosh API client defaults.
- REL-18: post-publish smoke must no longer rely on the manual version-resolution workaround.

This phase is closure work on the existing installer + publish/smoke contract, not a broader release-engineering redesign.
</domain>

<decisions>
## Implementation Decisions

### Installer Runtime Default
- **D-27-01:** The installer-generated Swoosh runtime default should align with Mailglass's package-level default posture by using `config :swoosh, :api_client, false`, not `Swoosh.ApiClient.Finch`.
- **D-27-02:** Phase 27 should close the fresh-host crash by making the installed config honest and dependency-light, not by introducing a stronger HTTP-client opinion than the core package already claims.

### Smoke Contract Boundary
- **D-27-03:** REL-17 is judged against the full fresh-host smoke contract already exercised in-repo: add deps, run `mix mailglass.install`, compile with warnings as errors, boot the endpoint, and verify `GET /dev/mail/` succeeds.
- **D-27-04:** A narrower compile-only or config-file-only proof is insufficient for Phase 27 because the known failure mode is an adopter-path boot/install regression.

### Release-Day Version Source
- **D-27-05:** REL-18 should keep the current release-event-driven publish/smoke topology and treat `github.event.release.tag_name` as the canonical release-day version source.
- **D-27-06:** `workflow_dispatch tag=...` remains a fallback-only path for manual recovery and rehearsal, not part of the normal milestone ship contract.
- **D-27-07:** Scheduled smoke runs remain a separate health-check path and may resolve the latest public release independently, but that path must not define release-day correctness.

### Release Closure Evidence
- **D-27-08:** Closing Phase 27 includes updating current planning/state artifacts so the manual `workflow_dispatch tag=...` workaround is recorded as historical evidence, not as an active requirement for shipping.
- **D-27-09:** Historical evidence of prior workarounds should be preserved in milestone archives, but current-state docs must reflect the post-fix contract.

### the agent's Discretion
- Exact workflow step names, helper extraction boundaries, and validation-step placement, as long as release-day version resolution remains anchored on the release tag and manual dispatch stays fallback-only.
- Exact installer template wording around Swoosh config, as long as the generated config is honest about Mailglass not pinning a specific API client by default.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md`
- `.planning/phases/25-deliverability-doctor/25-CONTEXT.md`
- `.planning/phases/26-runtime-per-tenant-adapter-resolution/26-CONTEXT.md`
- `lib/mailglass/installer/templates.ex`
- `lib/mix/tasks/mailglass.install.ex`
- `test/mailglass/install/install_first_preview_smoke_test.exs`
- `test/mailglass/install/install_golden_test.exs`
- `.github/workflows/publish-hex.yml`
- `.github/workflows/post-publish-smoke.yml`
- `.planning/milestones/v0.3-phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md`

External reference used to lock the installer default decision:
- Swoosh docs: `https://hexdocs.pm/swoosh/Swoosh.html`
- Swoosh Finch client docs: `https://hexdocs.pm/swoosh/Swoosh.ApiClient.Finch.html`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Installer.Templates.runtime_config_body/0` is the current seam that writes the installer-managed Swoosh runtime block.
- `Mix.Tasks.Mailglass.Install` plus `Mailglass.Installer.Apply` already provide the deterministic installer write path and conflict semantics.
- `test/mailglass/install/install_first_preview_smoke_test.exs` already encodes the canonical fresh-host smoke contract that Phase 27 needs to preserve.
- `Mix.Tasks.Mailglass.Publish.Check` and `Mailglass.Publish.InstallerGoldenCheck` already gate publish-time installer drift and provide the release-check boundary for package hygiene.
- `post-publish-smoke.yml` already has a dedicated `cron-guard` version-resolution path and explicit direct `needs` wiring for downstream jobs.

### Established Patterns
- Release-day workflows are triggered by `on: release: types: [published]`, with `workflow_dispatch` retained as fallback/rehearsal rather than primary path.
- The repo prefers explicit idempotency guards and early contract validation in workflows over relying on GitHub event quirks.
- Current project methodology favors one coherent public default and rejects brochure-style config surfaces that imply stronger guarantees than runtime actually provides.
- Prior phase contexts lock a decisive-by-default posture: choose a coherent default locally and escalate only for high-impact contract changes.

### Integration Points
- Installer closure work centers on `lib/mailglass/installer/templates.ex`, with downstream verification through install smoke tests and the release smoke workflow.
- Release/smoke closure work centers on `.github/workflows/publish-hex.yml` and `.github/workflows/post-publish-smoke.yml`.
- Planning/docs closure touches current-state planning artifacts that still describe Issue #25 and Issue #9 as active carry-forward gaps.
</code_context>

<specifics>
## Specific Ideas

- The right Phase 27 posture is to close the adopter-visible path, not just the internal release-engineering narrative.
- The installer should not silently choose a stronger Swoosh runtime opinion than Mailglass itself documents at the package level.
- Release-day success should be provable from the published release event path without maintainers needing to remember the old manual tag workaround.
</specifics>

<deferred>
## Deferred Ideas

- Broader release-engineering redesign beyond these two closure items remains out of scope for Phase 27.
- Reconsidering the overall release topology (for example, moving to a different trigger family entirely) is deferred unless needed to satisfy REL-18.
- Any broader installer UX expansion beyond fixing the known Swoosh API client default mismatch is deferred.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 27 directly.
</deferred>
