# Phase 144: Signal & Drift Integrity - Context

**Gathered:** 2026-07-31 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the remaining CI, branch-protection, conformance, and release signals honest: a check that cannot
verify its subject must be visibly non-green; scheduled branch-protection comparison must catch the
job-id-versus-display-name regression class; the existing icon gate must cover dynamic icon names; linked
release tags must not race; and release-trigger recovery must be visibly idempotent.

**In scope:** CONFORM-02, TRUTH-02, TRUTH-03, TRUTH-04, TRUTH-06, TRUTH-08.

**Out of scope:** rebuilding `ICON-EXISTS-GATE`, rewriting CI topology, adding adopter-facing product
surface, optimizing pipeline latency, re-planning the already-shipped 2026-07-28 remediation, or cutting a
release.
</domain>

<decisions>
## Implementation Decisions

### Honest Verification Outcomes

- **D-01:** Standardize all three unavailable-verification paths on an explicit, visibly failing outcome
  using the repository's established `if: always()` plus explicit-failure pattern and a precise remediation
  message. The three surfaces are `.github/workflows/branch-protection-drift.yml`'s reassertion job,
  `.github/workflows/ci.yml`'s Branch Protection Advisory job, and `mailglass.repo.hygiene`'s
  `branch_protection` sub-check. Missing credentials, missing tooling, or an inaccessible endpoint must be
  distinguishable from verified drift and from verified no-drift.

- **D-02:** `Branch Protection Advisory` remains publish-gating under the Phase 141 three-tier lane
  contract when its cannot-check path becomes genuinely failable. Do not let the truth fix accidentally
  reclassify or demote the lane.

- **D-03:** Put the recurring read-only protection comparison in the existing scheduled
  `.github/workflows/branch-protection-drift.yml`; do not create another workflow or desired-state
  registry. `scripts/setup_branch_protection.sh --print-expected-json` remains the canonical expected-state
  generator, and `scripts/verify-branch-protection.sh` remains the normalized live comparison seam.

- **D-04:** Add an anti-vacuous workflow-contract regression test that specifically proves the protected
  status context uses the reported job display name rather than the YAML job id. Follow the existing
  contract-test patterns in `test/scripts/required_checks_test.exs` and
  `test/scripts/guard_release_trigger_test.exs`; a parser that matches nothing must fail.

### Dynamic Icon Integrity

- **D-05:** Extend verification of the existing `ICON-EXISTS-GATE`; do not rebuild or broaden its product
  purpose. Use a deliberately missing dynamic `hero-*` value in a throwaway test fixture to prove names
  resolved through `@icon`, `option.icon`, `stat_severity_icon/1`, interpolation, or lookup maps are checked
  against the vendored icon inventory. The negative fixture must fail the real gate and be removed after
  the proof.

- **D-06:** The lasting implementation must cover the dynamic-construction class, not hardcode the two
  historical missing icons or merely add their literal names to a scan. Preserve the existing vendored
  inventory as the source of truth and add no dependency.

### Linked-Release Fan-out

- **D-07:** Give `.github/workflows/publish-hex.yml` and
  `.github/workflows/post-publish-smoke.yml` a release-independent concurrency key so both tag events from
  one linked-version release train serialize rather than racing in ref-specific groups. Fix both identical
  patterns in this phase; do not defer the smoke workflow independently.

- **D-08:** Preserve the existing idempotent successful no-op for an already-published version. A
  redundant serialized run must report success with "nothing to do," never turn a release that shipped
  successfully into a failed release signal.

### Release-Trigger Recovery

- **D-09:** Treat `.github/workflows/release-please.yml`'s existing hourly scheduled recovery as the
  selected TRUTH-04 fix. Preserve its preflight handling of fully present tags, partial release state, and
  `autorelease: tagged`; add durable contract evidence and maintainer-facing documentation proving the
  recovery is visible, idempotent, and cannot double-fire alongside another trigger.

- **D-10:** Do not replace the release triggers or introduce a new topology solely to remove the bounded
  schedule delay. The accepted tradeoff is recovery on the existing hourly cadence, provided the delay and
  recovery behavior are durably documented where future release maintainers will find them.

### the agent's Discretion

- Exact step names, remediation wording, and test-file boundaries, provided each outcome remains distinct
  and anti-vacuous.
- The implementation technique used to resolve dynamic icon values, provided it proves the whole bounded
  dynamic class and does not rebuild the gate.
- The exact shared concurrency-group string, provided it is independent of tag/ref and is identical in
  intent across publish and post-publish smoke.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 144 goal and five success criteria; authoritative phase boundary.
- `.planning/REQUIREMENTS.md` — binding CONFORM-02 and TRUTH-02/03/04/06/08 definitions plus milestone
  scope locks.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, and recommendation-first lenses used
  to select the bounded approaches above.
- `.planning/phases/141-lane-truth-foundation/141-CONTEXT.md` — authoritative three-tier lane contract,
  Branch Protection Advisory classification, and fail-loud/anti-vacuity precedents.
- `.planning/phases/143-test-harness-truth/143-CONTEXT.md` — release-gate fan-out constraints and
  anti-vacuity evidence patterns.
- `scripts/setup_branch_protection.sh` — canonical expected branch-protection JSON.
- `scripts/verify-branch-protection.sh` — canonical read-only live branch-protection comparison.
- `.github/workflows/branch-protection-drift.yml` — existing scheduled drift owner and one cannot-check
  surface.
- `.github/workflows/ci.yml` — Branch Protection Advisory cannot-check surface and its current lane wiring.
- `dev/mix/tasks/mailglass.repo.hygiene.ex` — `branch_protection` hygiene outcome semantics.
- `mailglass_admin/scripts/check-conformance.sh` — existing `ICON-EXISTS-GATE` implementation.
- `mailglass_admin/lib/mailglass_admin/components.ex` — dynamic icon call sites the gate must cover.
- `.github/workflows/publish-hex.yml` — publish concurrency and already-published no-op behavior.
- `.github/workflows/post-publish-smoke.yml` — identical ref-scoped concurrency pattern to fix alongside
  publishing.
- `.github/workflows/release-please.yml` — scheduled anti-recursion recovery and idempotency preflight.
- `test/scripts/required_checks_test.exs` and `test/scripts/guard_release_trigger_test.exs` — established
  anti-vacuity workflow-contract test patterns.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `scripts/setup_branch_protection.sh --print-expected-json` already emits the desired protection state;
  no second expected-state representation is needed.
- `scripts/verify-branch-protection.sh` already normalizes and compares live protection read-only.
- The test suite already has parsers and negative-control patterns for required contexts and release-trigger
  workflow contracts.
- `publish-hex.yml` already treats a version found on Hex as a successful no-op, which is the required
  behavior for a redundant serialized run.
- `release-please.yml` already has scheduled and manual recovery plus a state-aware preflight; this phase
  needs durable proof and documentation rather than a replacement mechanism.

### Established Patterns

- Phase 141's lane registry has three explicit tiers. Truth fixes must preserve those classifications.
- Cannot-check outcomes fail loud and name the unavailable precondition; they do not collapse into drift or
  no-drift.
- Contract parsers require anti-vacuity assertions so syntax drift cannot turn a test green by matching
  nothing.
- Maintenance work reuses existing scripts and workflow seams and adds no dependency or CI topology.

### Integration Points

- Branch-protection truth joins the scheduled workflow, the two shell scripts, the CI advisory lane, the
  repo-hygiene Mix task, and workflow contract tests.
- Dynamic icon verification joins the conformance shell gate, component helper outputs, and the vendored
  Heroicon inventory.
- Release fan-out integrity joins both tag-triggered workflows through a release-independent serialization
  contract while leaving their package checks idempotent.
- Release-trigger recovery joins the hourly schedule, release-state preflight, contract tests, and durable
  maintainer documentation.
</code_context>

<specifics>
## Specific Ideas

- The dynamic-icon negative control should resemble a real computed call site rather than a literal string
  planted solely where the current grep already looks.
- The branch-protection regression must encode the historical failure precisely: protection required the
  job id `guard-release-trigger`, while GitHub reported the display name `Guard Release Trigger`.
- "Cannot verify" messages should state the failed precondition and recovery action so maintainers do not
  need to inspect implementation code to distinguish infrastructure failure from actual drift.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within the fixed Phase 144 boundary. Pipeline optimization remains sequenced to
SEED-006 after this milestone.
</deferred>
