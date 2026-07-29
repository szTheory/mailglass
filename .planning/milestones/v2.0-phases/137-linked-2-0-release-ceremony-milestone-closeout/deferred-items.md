# Deferred / Out-of-Scope Items — Phase 137

## Plan 01

### Pre-existing trust-lane contract test failure (out of scope)

- **Test:** `test/mailglass/publish/ci_trust_lane_contract_test.exs:8`
  — "clean-baseline trust lane remains publish-gate-only and verifies Hex-sourced host"
- **Assertion that fails:** `refute job =~ ~r/^    if:/m` (trust-lane job in
  `.github/workflows/ci.yml` should not carry a job-level `if:` gate). The job now
  has `if: needs.changes.outputs.code == 'true'`.
- **Why deferred (not fixed here):** This assertion targets `ci.yml` job structure.
  Neither `ci.yml` nor the contract test was modified by Plan 01 — both are
  byte-identical to the pre-plan commit `98cc27b1`. The failure is fully orthogonal
  to this plan's scope (`~> 2.0` sibling pins + reference-baseline schema adoption).
  It is **not** schema-qualified contract drift (D-07) — no table-location expectation
  is involved. Per the executor SCOPE BOUNDARY rule, only issues directly caused by
  this task's changes are auto-fixed.
- **Status:** Logged for a future CI-hygiene pass; does not block the 2.0 release
  pre-conditions this plan lands.

### Reference-baseline lock regeneration (deferred to Plan 02 by design)

- `reference/host_app/mix.lock` + `reference/demo_app/mix.lock` were NOT regenerated:
  the `~> 2.0` siblings are not yet on Hex (they publish in Plan 02). `mix deps.get`
  correctly fails version-solving (`mailglass ~> 2.0 doesn't match any versions`).
  Locks left untouched — no fabricated entries, no transitive drift. Re-resolve is
  the Plan 02 post-publish consumer/baseline verification step.
