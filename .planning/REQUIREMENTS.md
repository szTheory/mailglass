# Requirements: v1.3 Release Discipline & Repo Truth

## Goal

Make Mailglass release and repository hygiene repeatable, automated, and
consumer-ready before the next product milestone.

## Release Hygiene

- [ ] **RH-01** — Preserve dirty/ahead local state before cleanup on a named `preserve/*` branch.
- [ ] **RH-02** — Start release-discipline implementation from a clean `origin/main` work branch.
- [ ] **RH-03** — Provide `mix mailglass.repo.hygiene --check --format text|json`.
- [ ] **RH-04** — Provide `mix mailglass.repo.hygiene --apply` with deterministic safe actions only.
- [ ] **RH-05** — Fail hygiene checks for dirty worktree, ahead/behind drift, missing CI truth, ambiguous open PRs, or release-workflow drift.
- [ ] **RH-06** — Add a scheduled/manual repo-hygiene workflow that uploads JSON readiness evidence.

## Release Workflow

- [ ] **RELH-01** — Restore release fan-out by using `RELEASE_PLEASE_PAT` for Release Please release creation.
- [ ] **RELH-02** — Keep tag-pinned `workflow_dispatch` as the permanent fallback; never publish from `main`.
- [ ] **RELH-03** — Publish sibling packages deterministically: `mailglass`, then `mailglass_inbound`, then `mailglass_admin`.
- [ ] **RELH-04** — Preserve the `hex-publish` protected environment and manual approval.
- [ ] **RELH-05** — Keep post-publish smoke aligned with the published core and compatible inbound package versions.

## Repo Truth

- [ ] **TRUTH-01** — Record open PR dispositions for #17, #27, #28, #29, #30, #37, #38, and #39.
- [ ] **TRUTH-02** — Document the clean-state gate and release trigger model in `MAINTAINING.md`.
- [ ] **TRUTH-03** — Update planning state so v1.3 is the active milestone and later feature milestones inherit this discipline.

## Acceptance

The milestone is accepted when `mix mailglass.repo.hygiene --check --format json`
produces a machine-readable readiness summary, the workflow contracts enforce
deterministic publish order, and maintainers have one documented clean-state
procedure before release or milestone work.
