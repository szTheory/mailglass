---
phase: 160-certification-documentation-and-release
plan: 06
subsystem: protected-release-and-exact-hex-certification
tags: [release, hex, github-actions, exact-hex, generated-host, provenance]
requires:
  - phase: 160-05
    provides: immutable three-package candidate with digest-bound maintainer authorization
provides:
  - protected publication of the exact authorized core, admin, and inbound package set
  - immutable GitHub release, tag, and Hex checksum evidence for all three packages
  - completed exact-Hex generated-host and trust-runner adoption evidence
affects: [milestone-closeout, published-package-canary, release-recovery]
tech-stack:
  added: []
  patterns: [protected-control-plane-recovery, immutable-target-retry, artifact-hash-ledger]
key-files:
  created:
    - .planning/phases/160-certification-documentation-and-release/160-06-SUMMARY.md
  modified:
    - .planning/release-target.json
    - .github/workflows/publish-hex.yml
    - .github/workflows/post-publish-smoke.yml
    - test/mailglass/publish/post_publish_smoke_contract_test.exs
    - test/scripts/reconcile_release_versions_test.exs
    - test/scripts/release_policy_contract_test.exs
key-decisions:
  - "Publication remained bound exclusively to candidate digest 91353fe852bdace582d3d19e6f5f53583ffd53ec9317db7cc37c6d55e574a1e4 and immutable tag SHA 0f0b06861b1cbb2e89f44ea4f40db754effc4017."
  - "Immutable-tag CI recovery used a protected main control plane only after proving tag ancestry and exact publishable-content digest equality; every publish job still checked out the immutable tag."
  - "The release target closed only after the successful smoke artifact's two checkpoint hashes were independently verified and recorded."
patterns-established:
  - "Protected control-plane recovery: a mutable workflow fix may govern validation only after exact immutable shipped-content equality is proven."
  - "Adoption evidence is accepted from one successful immutable-target run and bound by separate generated-host and trust-runner SHA-256 digests."
requirements-completed: [REL-04]
coverage:
  - id: D1
    description: "The exact authorized core, admin, and inbound artifacts were published through protected automation with immutable release, tag, and Hex checksum evidence."
    requirement: REL-04
    verification:
      - kind: integration
        ref: "scripts/verify_published_release.sh .planning/release-target.json"
        status: pass
      - kind: other
        ref: "https://github.com/szTheory/mailglass/actions/runs/32416453778"
        status: pass
    human_judgment: false
  - id: D2
    description: "A disposable exact-Hex host installed all three public versions and completed both 10-stage dependency-order journeys plus the five-stage trust-runner proof."
    requirement: REL-04
    verification:
      - kind: e2e
        ref: "https://github.com/szTheory/mailglass/actions/runs/32425143336"
        status: pass
      - kind: integration
        ref: "test/mailglass/publish/post_publish_smoke_contract_test.exs and test/reference_host/trust_runner_checkpoint_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The completed release ledger binds the successful smoke run to the immutable tag and to independently verified generated-host and trust-runner checkpoint hashes."
    requirement: REL-04
    verification:
      - kind: other
        ref: "mix run --no-start --no-compile --no-deps-check --require scripts/release_policy.exs -e 'Mailglass.ReleasePolicy.cli(System.argv())' -- verify-complete .planning/release-target.json"
        status: pass
    human_judgment: false
duration: 5h 14m
completed: 2026-08-20
status: complete
---

# Phase 160 Plan 06: Protected Publication and Exact-Hex Adoption Summary

**The digest-authorized package family is public and certified from one immutable tag through a production-shaped exact-Hex adoption journey.**

## Performance

- **Duration:** 5h 14m
- **Started:** 2026-08-20T17:41:01Z
- **Completed:** 2026-08-20T22:54:49Z
- **Tasks:** 3
- **Files modified:** 7 repository artifacts plus protected GitHub release state

## Accomplishments

- Published `mailglass 2.5.0`, `mailglass_admin 2.5.0`, and `mailglass_inbound 2.2.0` through protected workflow run `32416453778`, bound to candidate digest `91353fe8…` and final tag SHA `0f0b0686…`.
- Recorded three distinct GitHub release IDs, three tag SHAs equal to the final tag, and the three live Hex checksums without accepting partial publication.
- Passed protected smoke run `32425143336`: exact registry and HexDocs checks, consumer install, non-retraction checks, disposable-host boot, two complete 10-stage generated-host journeys, the five-stage trust runner, and checkpoint artifact validation.
- Closed `.planning/release-target.json` as `completed` with generated-host digest `0dc107c1…` and trust-runner digest `24858ca8…` after `SHA256SUMS` and the trust checkpoint contract both verified independently.

## Task Commits

1. **Task 1: Confirm external merge/tag/publication execution** — maintainer supplied the exact `publish 91353fe8…` blocking-human authorization; no repository commit was appropriate for the decision alone.
2. **Task 2: Run protected publication for the exact authorized candidate** — `70fbc65d` (`feat`)
3. **Task 3: Prove exact-Hex adoption and close the release target** — `e6e058b6` (`feat`)

Protected recovery commits landed separately on `main`: `271f4145` (immutable-tag CI recovery), `229421a9` (consumer Postgres service), and `b56bb134` (disposable-host Swoosh configuration).

## Files Created/Modified

- `.planning/release-target.json` — final tag, publication, Hex checksum, smoke-run, and checkpoint-digest ledger.
- `.github/workflows/publish-hex.yml` — fail-closed control-SHA recovery that preserves immutable-tag publication inputs.
- `.github/workflows/post-publish-smoke.yml` — Postgres-backed consumer smoke and installer-equivalent disposable-host Swoosh configuration.
- `test/mailglass/publish/post_publish_smoke_contract_test.exs` — protected workflow recovery and adoption contracts.
- `test/scripts/reconcile_release_versions_test.exs` — authorized/published immutable tree recognition.
- `test/scripts/release_policy_contract_test.exs` — control-plane recovery fail-closed assertions.
- `.planning/phases/160-certification-documentation-and-release/160-06-SUMMARY.md` — durable release and recovery record.

## Decisions Made

- Kept both user gates bound to exact candidate digest `91353fe852bdace582d3d19e6f5f53583ffd53ec9317db7cc37c6d55e574a1e4`; retired candidate digests were never reused.
- Used no local Hex credentials and no manual `mix hex.publish`; all irreversible publication occurred inside the protected publisher.
- Recovered immutable-tag CI through protected `main` only after tag ancestry and publishable-content equality were proven; the publisher continued checking out the immutable tag for every package job.
- Left the target `published` through both failed smoke attempts and marked it `completed` only after the successful artifact was downloaded and verified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Immutable release tag could not satisfy corrected CI metadata and demo-lock checks**

- **Found during:** Task 2 protected publication gate
- **Issue:** Final-tag CI saw Phoenix demo-lock drift and a release metadata assertion that recognized only the proposal branch, leaving the immutable tag red.
- **Fix:** PR #221 added a fail-closed protected control-SHA recovery, refreshed the demo lock, and taught metadata reconciliation to recognize the exact authorized/published candidate tree.
- **Files modified:** `.github/workflows/publish-hex.yml`, `reference/demo_app/mix.lock`, `test/scripts/reconcile_release_versions_test.exs`, `test/scripts/release_policy_contract_test.exs`
- **Verification:** PR and protected-main CI, both full-suite schemas, content-digest equality, and protected publisher run `32416453778` passed.
- **Committed in:** `271f4145`

**2. [Rule 3 - Blocking] Consumer smoke lacked the Postgres service required by its canonical script**

- **Found during:** Task 3, smoke run `32418673903`
- **Issue:** All exact public packages resolved and compiled, but `mix ecto.create` reached an empty `localhost:5432`.
- **Fix:** PR #224 provisioned the pinned Postgres service and added workflow contract assertions for the service and health check.
- **Files modified:** `.github/workflows/post-publish-smoke.yml`, `test/mailglass/publish/post_publish_smoke_contract_test.exs`
- **Verification:** 34 green PR checks, both full suites, and the next protected smoke's consumer job passed.
- **Committed in:** `229421a9`

**3. [Rule 3 - Blocking] Disposable reference host omitted the installer's no-client Swoosh setting**

- **Found during:** Task 3, smoke run `32420736163`
- **Issue:** The consumer and retirement jobs passed, but the deeper host boot tried to start Swoosh's absent Hackney client.
- **Fix:** PR #225 added the installer-equivalent `config :swoosh, :api_client, false` while failing closed on any pre-existing host API-client setting; construction order is contract-tested.
- **Files modified:** `.github/workflows/post-publish-smoke.yml`, `test/mailglass/publish/post_publish_smoke_contract_test.exs`
- **Verification:** 34 green PR checks, both full suites, and final protected smoke run `32425143336` passed end-to-end.
- **Committed in:** `b56bb134`

---

**Total deviations:** 3 auto-fixed blocking issues. **Impact on plan:** The fixes strengthened the protected release and smoke control planes without changing package contents, admin/operator behavior, the authorized candidate, or the immutable release tag.

## Issues Encountered

- Failed smoke attempts remained visible through issue #223 and never advanced the release ledger. The successful final run closed the tracker automatically.
- The first local acceptance rerun found a stale nested `mailglass_inbound` dependency cache; a lock-respecting `mix deps.get` refreshed Swoosh 1.27.0 locally, after which the exact command passed with 14 tests and zero failures.

## User Setup Required

None - no external service configuration remains.

## Next Phase Readiness

Phase 160 has no remaining plans. REL-04 is backed by immutable publication and adoption evidence, and the v2.6 milestone is ready for phase verification and milestone closeout.

## Self-Check: PASSED

- `.planning/release-target.json` reports `completed=true` under the release policy.
- Protected publication and adoption runs both concluded successfully.
- Artifact hashes, all 20 generated-host stages, and all five trust-runner stages verified.
- Required focused tests passed with 14 tests and zero failures.

---
*Phase: 160-certification-documentation-and-release*
*Completed: 2026-08-20*
