# Phase 18 Research: Ship v0.3.0

**Date:** 2026-04-29
**Research scope:** Release-surface drift, provider-guide alignment, publish ceremony reuse, and proof expectations for `mailglass` / `mailglass_admin` `0.3.0`.

## Recommendation

Split Phase 18 into **2 plans**:

1. **Plan 18-01 — release surface + prepublish alignment**
   - Own all maintainer-written public artifacts and stale wording cleanup before the irreversible cut.
   - Refresh the curated `0.3.0` changelog story, sibling changelog coordination, Resend docs, README milestone positioning, and any runbook/workflow wording that still hard-codes `0.2.0` examples or outdated provider coverage claims.
   - This plan should end with repo-local proof that the docs and prepublish contract are internally coherent.

2. **Plan 18-02 — real publish + smoke + completion evidence**
   - Own the actual Hex publish ceremony, fresh-host smoke, Hex/HexDocs verification, durable evidence, and milestone completion markers.
   - Keep irreversible actions isolated from editorial/doc updates.

This matches the successful Phase 13 shape: do the reversible trust-building work first, then perform the real release with explicit evidence capture.

## Locked Constraints To Preserve

- Keep the `0.3.0` changelog **curated and maintainer-written**, not generated-ledger-first.
- Frame `0.3.0` as **webhook coverage complete** without implying automatic provider enablement or a migration-heavy release.
- `guides/webhooks.md` must keep the current structure: shared webhook plumbing first, explicit provider sections second.
- Resend remains **explicit opt-in**; the zero-arg `mailglass_webhook_routes "/webhooks"` surface stays narrow.
- Reuse existing machinery: `mix mailglass.publish.check`, `publish-hex.yml`, `post-publish-smoke.yml`, and `MAINTAINING.md`.
- Avoid heavyweight release dossiers. One durable publish-evidence artifact is enough.

## Current Drift / Findings

### 1. Duplicate generated changelog entries still exist

- `CHANGELOG.md` contains two `0.2.0` headings: a generated stub and the curated entry.
- `mailglass_admin/CHANGELOG.md` has the same duplicate `0.2.0` pattern.

This is release-surface debt. Plan 18-01 should not append a clean `0.3.0` entry while leaving obvious duplicate-history clutter untouched.

### 2. Public webhook guide is stale about provider coverage

- `guides/webhooks.md` still says: SES and Resend “land later”.
- The guide already documents Mailgun and SES as shipped providers, so the intro is now contradictory.
- Resend is already implemented and wired. The guide needs a dedicated Resend setup section with literal route/config/examples and a clear `CachingBodyReader` dependency reminder.

### 3. README milestone positioning is stale

- `README.md` still places Mailgun / SES / Resend verification under `v0.5`.
- That claim is now wrong after Phases 15-17 and would undercut the `0.3.0` release story if left unchanged.

### 4. Release runbook/workflow comments still use `0.2.0` examples

- `MAINTAINING.md`, `publish-hex.yml`, and `post-publish-smoke.yml` include `0.2.0`-specific fallback examples.
- They are not wrong structurally, but Phase 18 should align them with the next cut so the maintainer runbook matches the actual release being shipped.

## Recommended Plan Split

## Plan 18-01: Curate the release surface and prepublish contract

**Suggested files:**

- `CHANGELOG.md`
- `mailglass_admin/CHANGELOG.md`
- `guides/webhooks.md`
- `README.md`
- `MAINTAINING.md`
- `.github/workflows/publish-hex.yml`
- `.github/workflows/post-publish-smoke.yml`

**What it should do:**

- Add a maintainer-written `0.3.0` entry in `CHANGELOG.md`.
- Keep the changelog focused on three adopter questions: what changed, who should care, and whether any migration/urgent action is required.
- Explicitly state this is **not** a codemod / migration release.
- Add a short coordinated `0.3.0` entry in `mailglass_admin/CHANGELOG.md`.
- Remove the stale “land later” story from `guides/webhooks.md`.
- Add a literal `### Resend setup` section:
  - `mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid, :resend]`
  - `config :mailglass, :resend, enabled: true, secret: System.fetch_env!("RESEND_WEBHOOK_SECRET"), timestamp_tolerance_seconds: 300`
  - `whsec_...` secret shape
  - `svix-id`, `svix-timestamp`, `svix-signature` verification summary
  - supported normalized coverage
- Update README positioning so provider coverage and milestone history reflect reality.
- Align runbook/workflow comments with the `0.3.0` cut and fallback path.

**Why this should be its own plan:**

- These changes are reversible, reviewable, and directly affect user trust.
- They should land before the actual publish step so `mix mailglass.publish.check` and the pre-publish summary reflect the final release story.

## Plan 18-02: Publish, smoke, capture evidence, and mark the milestone complete

**Suggested files:**

- `.planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md`
- `.planning/ROADMAP.md`
- `.planning/PROJECT.md`
- `MAINTAINING.md` only if the real ceremony reveals a wording mismatch

**What it should do:**

- Run or directly monitor the protected `0.3.0` publish ceremony on the reviewed release tag.
- Record:
  - release tag / SHA
  - publish workflow URL
  - environment approval outcome
  - `mailglass` publish result
  - `mailglass_admin` publish result
  - smoke workflow URL
  - `mix hex.info` results for both packages
  - HexDocs HTTP 200 checks for both packages
  - fresh-host smoke result inside the 60-minute window
- Update `ROADMAP.md` to mark Phase 18 complete and reflect the final plan count.
- Update `PROJECT.md` so `DELIV-04` is complete and the milestone state reflects the shipped release.

**Why this should stay separate:**

- This is the irreversible part of the phase.
- Evidence and completion markers should be written only after the release is actually live.

## File-Level Touch Points

### Changelog / release messaging

- `CHANGELOG.md`
- `mailglass_admin/CHANGELOG.md`

### Adopter docs

- `guides/webhooks.md`
- `README.md`

### Publish contract

- `MAINTAINING.md`
- `.github/workflows/publish-hex.yml`
- `.github/workflows/post-publish-smoke.yml`
- `lib/mix/tasks/mailglass.publish.check.ex`

### Implementation truth sources for Resend docs

- `lib/mailglass/webhook/router.ex`
- `lib/mailglass/webhook/plug.ex`
- `lib/mailglass/webhook/providers/resend.ex`
- `lib/mailglass/webhook/caching_body_reader.ex`
- `test/mailglass/webhook/providers/resend_webhook_plug_test.exs`

## Verification Traps

### Trap 1: Docs can silently overstate the route surface

The default route mount still excludes Mailgun / SES / Resend. Any example that implies Resend is mounted by default is wrong.

### Trap 2: Resend docs can mention signatures without the raw-body prerequisite

`Mailglass.Webhook.CachingBodyReader` is load-bearing. The guide must connect the raw-byte requirement to Svix verification explicitly.

### Trap 3: Release notes can drift into fake migration urgency

Phase 18 context is explicit: `0.3.0` is additive, not a `0.2.0`-style migration release. Avoid upgrade theater.

### Trap 4: Publish evidence should not be invented ahead of time

The publish-evidence file belongs to real execution. Plan 18-01 should not fabricate URLs, approvals, or smoke results.

### Trap 5: Completion markers must follow actual public visibility

Do not mark `DELIV-04` complete in `PROJECT.md` until both packages are live and installable.

## Minimum Proof Bar

### Before publish

- `mix mailglass.publish.check --package mailglass`
- `mix mailglass.publish.check --package mailglass_admin`
- local review that changelog, README, webhooks guide, and runbook tell the same `0.3.0` story

### After publish

- `mix hex.info mailglass 0.3.0`
- `mix hex.info mailglass_admin 0.3.0`
- `https://hexdocs.pm/mailglass/0.3.0/` returns HTTP 200
- `https://hexdocs.pm/mailglass_admin/0.3.0/` returns HTTP 200
- fresh Phoenix-host smoke passes within the 60-minute window

## Suggested Evidence Artifact

Use a single file:

- `.planning/phases/18-ship-v0-3-0/18-02-PUBLISH-EVIDENCE.md`

It should be a factual release log, not a ceremony dossier.

## Rationale Summary

- Two plans are enough because the phase naturally splits into reversible trust work and irreversible publish work.
- The biggest risks are not code correctness in webhook internals; they are **misleading public claims** and **release-proof drift**.
- Phase 13 already established the right release posture. Phase 18 should reuse that posture with lighter migration framing and stronger provider-coverage alignment.

## RESEARCH COMPLETE

- Recommended split: `18-01` docs/changelog/runbook alignment, `18-02` real publish/smoke/evidence.
- Highest-priority drift found: duplicate `0.2.0` changelog entries, stale “SES and Resend land later” intro, and README still pushing provider coverage to `v0.5`.
- Resend docs must stay explicit-opt-in and must mention `CachingBodyReader` + `whsec_...` literally.
- Publish and smoke workflows are structurally sufficient; likely edits are wording/example alignment, not mechanism redesign.
- Completion markers belong only after both Hex packages and both HexDocs pages are live.
