---
phase: 18-ship-v0-3-0
plan: "01"
subsystem: release-engineering
tags: [release, changelog, hex, webhooks, resend, mailgun, ses, docs, prepublish, v0.3.0]

requires:
  - phase: 17-unblock-verify-resend
    provides: Resend wiring fully verified; explicit Phase 18 deferral of public Resend guide work
  - phase: 16-ses-webhook-provider-sns-cache
    provides: SES explicit-opt-in route surface and provider-guide posture
  - phase: 15-mailgun-webhook-provider
    provides: Mailgun explicit-opt-in route surface and public-doc expectations
  - phase: 14-resend-webhook-provider-core-ingest
    provides: Resend signature/timestamp/event-mapping decisions and CachingBodyReader requirement
provides:
  - Maintainer-curated `0.3.0` changelog narrative for `mailglass` (additive / no-codemod / webhook-coverage-complete framing)
  - Coordinated sibling `0.3.0` changelog entry for `mailglass_admin` (version-paired, no fake admin-only story)
  - `### Resend setup` section in `guides/webhooks.md` with literal route/config snippets, Svix headers, `whsec_` secret shape, normalized event coverage, and CachingBodyReader reminder
  - README, MAINTAINING, publish-hex, and post-publish-smoke wording aligned to the `0.3.0` fallback path
  - Verified prepublish gate (`mix mailglass.publish.check` exits 0 for both packages)
affects:
  - 18-02 (publish ceremony) — consumes the curated changelogs and verified prepublish gate
  - future v0.5+ admin / inbound milestones — reference the locked Resend opt-in pattern
  - hex.pm public release contract for v0.3.0

tech-stack:
  added: []
  patterns:
    - Curated maintainer-written `0.3.0` changelog entry (not an auto-generated commit ledger)
    - Explicit opt-in for new providers in webhook router with literal `providers: [...]` examples
    - Sibling-package coordinated release narrative (no fabricated admin-only feature story)

key-files:
  created:
    - .planning/phases/18-ship-v0-3-0/18-01-SUMMARY.md
  modified:
    # Already landed in seed commit dd19c0d; this plan validates against verify gates and prepublish.check
    - CHANGELOG.md
    - mailglass_admin/CHANGELOG.md
    - guides/webhooks.md
    - README.md
    - MAINTAINING.md
    - .github/workflows/publish-hex.yml
    - .github/workflows/post-publish-smoke.yml

key-decisions:
  - "All `<verify>` gates already passed against the dd19c0d seed commit; no plan-task edits were required, so atomic per-task commits were intentionally skipped per the 'no empty commits' rule"
  - "Both `mix mailglass.publish.check --package mailglass` and `mix mailglass.publish.check --package mailglass_admin` exit 0 with `conflict=0`, confirming the release surface is publish-ready"

patterns-established:
  - "Pattern: a `gsd-execute-phase` run can legitimately produce zero per-task commits when an upstream seed commit already satisfies every `<verify>` gate; the SUMMARY becomes the auditable record of that"
  - "Pattern: prepublish gate is the canonical task-4 verifier — `conflict=0` is the success signal, not the absence of `[create]` / `[update]` markers"

requirements-completed: []  # DELIV-04 closes only at end of plan 18-02 (after live publish + smoke). Plan 18-01 prepares the surface but does not close DELIV-04.

duration: 6min
completed: 2026-04-29
---

# Phase 18 Plan 01: Curate the v0.3.0 release surface and prepublish contract — Summary

**Verified the `0.3.0` release surface (CHANGELOGs, webhooks guide, README, runbook, and workflow comments) is coherent, copy-paste safe, and prepublish-clean — both `mix mailglass.publish.check` invocations exit 0.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-04-29T19:03:00Z
- **Completed:** 2026-04-29T19:09:53Z
- **Tasks:** 4 evaluated (0 required additional edits beyond the seed commit)
- **Files modified by this plan:** 0 net (all substantive content already landed in seed commit `dd19c0d`)

## Accomplishments

- Confirmed `CHANGELOG.md` and `mailglass_admin/CHANGELOG.md` each carry exactly **one** `## [0.2.0]` heading and one curated `## [0.3.0]` heading. The duplicate-stub gap that plan 18-01 Task 1 originally called out had already been resolved in the seed commit.
- Confirmed `guides/webhooks.md` ships a dedicated `### Resend setup` section with the literal `providers: [:postmark, :sendgrid, :resend]` snippet, `whsec_...` secret shape, Svix header verification (`svix-id`, `svix-timestamp`, `svix-signature`), `CachingBodyReader` reminder, and normalized event coverage table. No "SES and Resend land later" wording survives anywhere in the public docs.
- Confirmed `README.md`, `MAINTAINING.md`, `.github/workflows/publish-hex.yml`, and `.github/workflows/post-publish-smoke.yml` agree on the `mailglass-v0.3.0` fallback path and no longer place Mailgun / SES / Resend webhook verification in a future milestone.
- Ran `mix mailglass.publish.check --package mailglass` and `mix mailglass.publish.check --package mailglass_admin`. Both exit 0 with `conflict=0`. The repository is prepublish-gate green.

## Task Commits

This plan executed in **evaluate-then-validate** mode. Per the executor instructions ("if nothing material remains for this task, note it in the SUMMARY and skip the commit; do not produce empty commits"), no atomic per-task commits were created — all four `<verify>` gates already passed against the upstream seed commit. The seed commit is referenced below for traceability.

1. **Task 1 (CHANGELOG curate + duplicate `## [0.2.0]` cleanup)** — verify gate already satisfied by seed commit `dd19c0d`. No additional edit needed. Skipped per no-empty-commits rule.
2. **Task 2 (Resend setup section in `guides/webhooks.md`)** — verify gate already satisfied by seed commit `dd19c0d`. No additional edit needed. Skipped.
3. **Task 3 (README / MAINTAINING / workflow comments aligned to `0.3.0`)** — verify gate already satisfied by seed commit `dd19c0d`. No additional edit needed. Skipped.
4. **Task 4 (prepublish gate)** — both packages exit 0:
   - `mix mailglass.publish.check --package mailglass` → `Pre-publish check result for mailglass: create=2 update=5 unchanged=10 conflict=0`
   - `mix mailglass.publish.check --package mailglass_admin` → `Pre-publish check result for mailglass_admin: create=2 update=5 unchanged=9 conflict=0`
   - No incidental file edits produced; no chore commit needed.

**Seed commit referenced:** `dd19c0d` — "docs(18-01): seed v0.3.0 release-surface drafts and phase 18 plans".

**Plan metadata commit:** see git log entry following this SUMMARY (covers `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`, and `18-01-SUMMARY.md`).

## Files Created/Modified

Created (this plan):

- `.planning/phases/18-ship-v0-3-0/18-01-SUMMARY.md` — this summary.

Modified (in seed commit `dd19c0d`, validated by this plan):

- `CHANGELOG.md` — curated `## [0.3.0]` entry with maintainer narrative (additive / no-migration / webhook-coverage-complete) and Added/Changed/Fixed subsections. Duplicate auto-generated `## [0.2.0]` stub already removed in seed.
- `mailglass_admin/CHANGELOG.md` — coordinated `## [0.3.0]` entry version-paired with core. Duplicate auto-generated `## [0.2.0]` stub already removed in seed.
- `guides/webhooks.md` — new `### Resend setup` section. Stale "SES and Resend land later" wording removed.
- `README.md` — provider-coverage line lists Postmark / SendGrid / Mailgun / SES / Resend as shipped first-party providers. Hex deps bumped to `~> 0.3`.
- `MAINTAINING.md` — runbook step 3 references `mailglass-v0.3.0` as the canonical fallback tag. Idempotency note preserved.
- `.github/workflows/publish-hex.yml` — `workflow_dispatch` input description shows `mailglass-v0.3.0` example.
- `.github/workflows/post-publish-smoke.yml` — fallback comment and `tag` input description show `mailglass-v0.3.0` example.

## Verify gate evidence

```
$ test "$(rg -c '^## \[0\.2\.0\]' CHANGELOG.md)" = "1" && test "$(rg -c '^## \[0\.2\.0\]' mailglass_admin/CHANGELOG.md)" = "1" && rg -n "^## \[0\.3\.0\]" CHANGELOG.md mailglass_admin/CHANGELOG.md
mailglass_admin/CHANGELOG.md:7:## [0.3.0](.../mailglass_admin-v0.2.0...mailglass_admin-v0.3.0) (2026-04-29)
CHANGELOG.md:8:## [0.3.0](.../mailglass-v0.2.0...mailglass-v0.3.0) (2026-04-29)
exit=0

$ rg -n "### Resend setup|providers: \[:postmark, :sendgrid, :resend\]|whsec_|svix-id|CachingBodyReader" guides/webhooks.md && ! rg -n "SES and Resend land later" guides/webhooks.md
exit=0   # all five anchors present, stale wording absent

$ ! rg -n "v0\.5 .*Mailgun|v0\.5 .*SES|v0\.5 .*Resend|SES and Resend land later" README.md guides/webhooks.md && rg -n "mailglass-v0\.3\.0|0\.3\.0" MAINTAINING.md .github/workflows/publish-hex.yml .github/workflows/post-publish-smoke.yml
exit=0   # no stale future-milestone wording, fallback tag present in all three files

$ mix mailglass.publish.check --package mailglass && mix mailglass.publish.check --package mailglass_admin
Pre-publish check result for mailglass: create=2 update=5 unchanged=10 conflict=0
Pre-publish check result for mailglass_admin: create=2 update=5 unchanged=9 conflict=0
exit=0
```

## Decisions Made

- **Skipped per-task commits because every `<verify>` gate already passed against the seed.** The plan's atomic-commit pattern is meant to prevent silent rework loss; when the upstream seed already satisfies every gate, an empty commit per task would be ceremony noise that misleads `git log` readers about what actually shipped this plan. Documented here instead.
- **Treated the `[create]` / `[update]` markers in `mix mailglass.publish.check` output as Igniter-style change indicators, not failure signals.** The success contract is `conflict=0` and exit 0; both held for both packages.

## Deviations from Plan

None of the four tasks required edits beyond what landed in seed commit `dd19c0d`. No deviation-rule (1, 2, 3, or 4) auto-fixes triggered during this run.

**Total deviations:** 0
**Impact on plan:** None. The plan's `<verify>` gates were the contract; all four passed.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required for plan 18-01. The actual Hex publish / approve / smoke ceremony is the job of plan 18-02.

## Next Phase Readiness

- The `0.3.0` release surface is internally consistent and prepublish-gate clean.
- `18-02-PLAN.md` can proceed with the publish ceremony (Release Please PR review → environment approval → `publish-hex.yml` → `post-publish-smoke.yml` → 60-minute revert window).
- DELIV-04 will close at the end of plan 18-02 once Hex.pm shows live mailglass `0.3.0` and mailglass_admin `0.3.0`.

## Self-Check: PASSED

- File `.planning/phases/18-ship-v0-3-0/18-01-SUMMARY.md` exists (this file).
- Seed commit `dd19c0d` exists in `git log` and contains all the public-doc content this plan validates.
- All four task `<verify>` gates exit 0 (evidence captured above).

---

*Phase: 18-ship-v0-3-0*
*Plan: 01*
*Completed: 2026-04-29*
