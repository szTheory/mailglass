# Phase 7: Installer + CI/CD + Docs - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 ships the adopter-facing installation experience, production-grade CI/CD release pipeline, and trustworthy docs contracts for `mailglass` and `mailglass_admin`. The scope is:
- `mix mailglass.install` from zero to first preview-styled message in under 5 minutes
- installer idempotency + conflict sidecars + golden-diff regression guard
- complete GitHub Actions release discipline for PR CI, advisory provider-live checks, release automation, and protected Hex publish
- ExDoc + guide architecture + compile-time docs contracts so examples stay true to real APIs

This phase does not add new runtime product capabilities. It locks delivery quality around the capabilities already built in Phases 1-6.

</domain>

<decisions>
## Implementation Decisions

### Installer Write Strategy
- **D-01:** `mix mailglass.install` uses a hybrid operation engine: `create_file`, `ensure_snippet`, `ensure_block`, and `run_task`.
- **D-02:** File ownership is explicit by operation type: owned files are create-or-conflict, shared host files are anchor/managed-block patch only, migrations are composed through `mix mailglass.gen.migration` (never inlined DDL).
- **D-03:** Reruns never clobber user edits. On ambiguity or drift, installer writes `.mailglass_conflict_*` sidecars and leaves target files unchanged.
- **D-04:** Installer tracks deterministic install metadata in an install manifest (`.mailglass.toml`) with target hashes to support safe reruns and conflict dedupe.
- **D-05:** CLI output is status-first (`create`, `update`, `unchanged`, `conflict`) with concise next-step guidance and clear manual merge instructions.
- **D-06:** Installer exposes `--dry-run` and keeps `--no-admin`; `--force` is supported as explicit destructive opt-in only.

### Installer Golden-Diff Contract
- **D-07:** Golden testing uses full-tree snapshot diff for `test/example` with minimal normalization for nondeterministic values (timestamps, temp paths, generated secrets).
- **D-08:** Core test matrix is mandatory: fresh install, second-run idempotency, user-modified conflict sidecar behavior, and `--no-admin` variant output.
- **D-09:** Snapshot regeneration uses one explicit maintainer workflow (single command path) and requires PR-visible golden diffs for behavior changes.
- **D-10:** Installer integration tests run `async: false` and reenable Mix tasks between rerun assertions to avoid false positives from one-shot task state.

### CI/CD Topology and Release Discipline
- **D-11:** CI topology is split-by-concern workflows (not one monolith): core CI, dependency review, actionlint, PR title convention checks, provider-live advisory, release-please, publish-hex.
- **D-12:** Required PR checks are stable and explicit: format/compile lanes, no-optional-deps compile, test lane, custom Credo, dialyzer, docs warnings-as-errors, dependency review, actionlint, conventional-commit title.
- **D-13:** Markdown path ignore is removed for docs-relevant CI checks so docs-only changes still run contract validation.
- **D-14:** Provider live checks remain advisory (`schedule` + `workflow_dispatch`), never merge-blocking.
- **D-15:** Release Please uses manifest + linked versions for root and `mailglass_admin`, with coordinated release PRs.
- **D-16:** Hex publish runs only from protected release flow via GitHub Environment approvals; `HEX_API_KEY` is never exposed to PR jobs.
- **D-17:** CI enforces tarball size/content constraints for both packages before publish.

### Docs Contract Enforcement and IA
- **D-18:** Docs verification uses a hybrid trust pyramid: doctests for public APIs, fenced-snippet compile checks for README/guides, and host-app smoke docs checks for onboarding-critical flows.
- **D-19:** ExDoc becomes the canonical docs spine with `main: "getting-started"` and full guide extras; README stays concise and points to guides/API.
- **D-20:** Docs contracts verify task names and config snippets against real code (`mix` task existence, NimbleOptions-valid config shape, route/path parity).
- **D-21:** Guide suite is task-oriented and runnable end-to-end; each guide ends with an executable minimal flow.
- **D-22:** Maintainer docs (`MAINTAINING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`) are shipped and versioned as first-class release artifacts.

### GSD Preference Shift-Left
- **D-23:** Set `workflow.research_before_questions = true` in `.planning/config.json` to front-load recommendations and reduce repetitive questioning in future discuss sessions.
- **D-24:** High-impact choices remain explicitly surfaced for user override; shift-left applies to default depth, not unilateral lock-in.

### Claude's Discretion
- Exact snippet marker format and block-marker wording for installer-managed sections
- Concrete normalization token names used in golden test harness (`<MIGRATION_TS>`, `<TMP_PATH>`, etc.)
- Workflow file naming conventions and job partitioning details, as long as required-check semantics stay stable
- Exact docs contract test module split and helper naming

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and Requirement Sources
- `.planning/ROADMAP.md` — Phase 7 goal, success criteria, and scope guardrails
- `.planning/REQUIREMENTS.md` — INST-01..04, CI-01..07, DOCS-01..05, BRAND-02..03
- `.planning/PROJECT.md` — locked engineering DNA, release, and voice constraints
- `.planning/STATE.md` — current phase progression and continuity

### Prior Context to Preserve
- `.planning/phases/06-custom-credo-boundary/06-CONTEXT.md` — lint/boundary enforcement already in place and must remain CI-integrated
- `.planning/phases/05-dev-preview-liveview/05-CONTEXT.md` — `mailglass_admin` packaging and assets constraints that Phase 7 release/docs must honor
- `.planning/phases/04-webhook-ingest/04-CONTEXT.md` — existing guide and webhook operational contracts to keep docs coherent

### Current Code and CI Surfaces
- `mix.exs` — existing verify aliases and package/docs metadata to extend
- `mailglass_admin/mix.exs` — package files whitelist, admin verify alias, sibling version discipline
- `.github/workflows/ci.yml` — current workflow baseline to refactor into split-by-concern topology
- `README.md` — onboarding contract that must become runnable and truthful
- `guides/webhooks.md` — existing guide quality baseline and style
- `lib/mix/tasks/mailglass.reconcile.ex` — existing task style and UX copy baseline
- `lib/mix/tasks/mailglass.webhooks.prune.ex` — existing task style and UX copy baseline
- `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex` — existing build-task naming/ergonomics
- `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.watch.ex` — existing watch-task naming/ergonomics
- `mailglass_admin/lib/mix/tasks/mailglass_admin.daisyui.update.ex` — existing update-task pattern

### Workflow Configuration
- `.planning/config.json` — updated discuss preference (`workflow.research_before_questions`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` verify aliases already establish phase-gate naming conventions; Phase 7 should extend, not replace.
- `mailglass_admin/mix.exs` already implements strict package file whitelisting and `verify.phase_05` static-asset diff gate.
- Existing Mix tasks in `lib/mix/tasks/` and `mailglass_admin/lib/mix/tasks/` provide the expected CLI UX tone and structure for new installer/docs tasks.
- Existing CI workflow provides baseline cache/service patterns for Elixir + Postgres lanes.

### Established Patterns
- Optional dependency discipline and no-optional-deps compile gate are already codified; all new workflows must preserve this lane.
- Existing docs and guide style are direct and operational; new guides should follow the same voice.
- Golden-style fixture testing already exists in prior phases and should be mirrored for installer snapshots.

### Integration Points
- Installer must patch adopter host files (`router.ex`, `runtime.exs`) without assuming exact formatting.
- Installer must compose with migration generation instead of duplicating migration logic.
- CI pipeline expansion must remain compatible with current required Elixir/OTP floor and package layout.
- Docs contracts must align README, ExDoc, and real tasks/routes/config in one enforceable loop.

</code_context>

<specifics>
## Specific Ideas

- Prefer operation-plan architecture for installer internals (`plan` then `apply`) so future diff previews and `--dry-run` are natural, not bolted on.
- Keep conflict sidecars human-mergeable: include target path, reason, and proposed replacement snippet with clear separators.
- Make PR review easy: golden diffs must be readable by humans, not hash-only manifests.
- Keep CI feedback fast: split required checks so failures identify the exact subsystem quickly.
- Use docs sections consistently in API docs: **What it does**, **Options**, **Returns**, **Errors**, **Telemetry**.

</specifics>

<deferred>
## Deferred Ideas

- Full AST/token-preserving patch engine for all installer edits (possible v0.5+ once installer surface stabilizes)
- Workflow-call reusable GH Actions abstraction layer (defer until split workflows settle)
- Always-on heavy host-app smoke docs checks for every PR (start selective; revisit after baseline runtime is measured)

### Reviewed Todos (not folded)
None — no pending todos matched Phase 7.

</deferred>

---

*Phase: 07-installer-ci-cd-docs*
*Context gathered: 2026-04-24*
