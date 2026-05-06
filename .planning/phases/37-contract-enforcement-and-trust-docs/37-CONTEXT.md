# Phase 37: Contract Enforcement and Trust Docs - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Enforce the documented `v1.x` contract and publish canonical trust docs for
testing and admin semantics so adopters and maintainers can rely on the
documented surface without depending on internals or maintainer memory.

This phase strengthens proof and documentation around the already-declared
surface. It does not add new runtime features, does not broaden the stable
contract, does not freeze admin DOM/LiveView internals, and does not introduce
a heavyweight manifest or ABI-style enforcement system.

</domain>

<decisions>
## Implementation Decisions

### Proof workflow
- **D-37-01:** Phase 37 should ship one semantic repo-root stability proof
  workflow, not a generated manifest snapshot or export-diff system.
- **D-37-02:** The proof workflow should compose the existing repo-native
  primitives:
  - compiled-doc contract tests
  - Tier 1 docs-truth checks
  - narrow public-surface leak checks
  - sibling-package contract assertions
  - `mix compile --no-optional-deps --warnings-as-errors`
- **D-37-03:** Contract enforcement should validate the surfaces explicitly
  named in canonical docs and inventories, not treat raw exports, ExDoc
  visibility, or framework-required reachability as the contract by
  themselves.
- **D-37-04:** Proof failures should stay semantic and actionable. Prefer
  targeted checks that say which promised seam drifted over noisy xref/export
  scanners that would surprise maintainers and accidentally freeze internals.
- **D-37-05:** Heavy manifest/snapshot proof artifacts are deferred. If the
  project wants richer release artifacts, that belongs in Phase 38’s release
  rehearsal work, not this phase’s narrow trust-contract goal.

### Testing contract
- **D-37-06:** `guides/testing.md` should become the one canonical
  adopter-facing testing contract. `docs/api_stability.md` remains the locked
  inventory/spec appendix, not the primary teaching surface.
- **D-37-07:** The testing guide should be story-shaped in this order:
  - `deliver/2` baseline
  - `deliver_later/2` baseline
  - optional Oban lanes
  - cross-process / browser / LiveView allowance patterns
  - PubSub / webhook assertion lane
  - footguns and strict-CI posture
- **D-37-08:** The stable default testing path is:
  - `Mailglass.Adapters.Fake`
  - `Mailglass.TestAssertions`
  - async-safe process-local assertions
  This path should require no optional dependencies and no hidden global test
  mutations.
- **D-37-09:** Cross-process guidance should prefer explicit ownership transfer
  (`Fake.allow/2` and normal Ecto sandbox allowance patterns) before any
  shared/global mode. Shared/global mode should be documented as the
  non-async fallback, not the default.
- **D-37-10:** The Oban testing story should stay narrow and explicit:
  - `:inline`
  - `:manual`
  Both must be documented as `async: false` lanes with the required
  `oban_jobs` table and no extra mode matrix.
- **D-37-11:** Testing docs must describe helper behavior exactly as shipped.
  The public guide should align with implementation details such as:
  - `last_mail/0` reading Fake-backed delivery state rather than consuming the
    process mailbox
  - `wait_for_mail/1` taking a timeout-based wait path
  - `MailerCase` setup behavior and its async/shared-mode boundaries

### Admin trust semantics
- **D-37-12:** The canonical admin trust-doc story should stay semantic and
  seam-centered:
  - router macros
  - documented options
  - auth behavior
  - session contract
  - mount semantics
  - destructive-action semantics
  It should not document DOM, selectors, component APIs, LiveView module
  names, or internal mount-hook plumbing as stable.
- **D-37-13:** The stable admin contract should explicitly promise:
  - `MailglassAdmin.Router` macros and documented options as the mount seam
  - `MailglassAdmin.Auth.authorize/2` as the stable adopter-owned auth seam
  - explicit operator session-key semantics for `subject_id`, optional
    `tenant_id`, optional `auth_method`, and optional `recent_auth_at`
  - mount-time authorization for `:operator_access`
  - action-time authorization for `:destructive_action`
  - exact-target, tenant-scoped, ledger-audited replay semantics with honest
    `new work` vs `no change` outcomes
- **D-37-14:** Replay and reconcile must stay clearly distinct in docs. Replay
  is one exact stored webhook target rerun through local semantics; reconcile
  is the background-first orphan sweep and not a delivery-detail replay tool.
- **D-37-15:** The following remain intentionally internal for `v1.x`:
  - LiveView modules
  - component modules
  - DOM/CSS shape
  - event names
  - modal layout/details
  - internal assign names
  - internal mount modules and implementation wiring

### Recommendation-first downstream posture
- **D-37-16:** Downstream research, planning, and execution for trust-doc,
  compatibility, admin, release, and testing work should default to one-shot,
  recommendation-first synthesis rather than broad option menus.
- **D-37-17:** Re-open choices only when they materially change:
  - the public contract
  - user trust semantics
  - tenant/auth boundaries
  - long-term maintainer burden
  - required release/verification posture
- **D-37-18:** This phase should inherit the existing recommendation-first
  methodology and push it left: agents should make coherent default decisions
  whenever repo evidence, ecosystem norms, and prior context already point to
  an honest answer.

### the agent's Discretion
- Exact file names and section ordering for new trust docs.
- Exact composition of the repo-root proof alias, as long as it remains one
  semantic entrypoint built from lightweight repo-native checks.
- Exact test file layout used to prove the testing and admin trust-doc stories.
- Exact wording for examples and warnings, as long as they stay narrow,
  explicit, and truthful.

</decisions>

<specifics>
## Specific Ideas

- Use the successful ecosystem pattern of one canonical story plus executable
  proof:
  - Swoosh/Bamboo/Rails for mail testing ergonomics
  - Ecto SQL Sandbox for `allow` before shared mode
  - Oban for explicit `:inline` vs `:manual` testing lanes
  - Phoenix LiveView security model, LiveDashboard, and Oban Web for
    mountable admin semantics with adopter-owned auth
- Preserve the narrow stable-vs-internal split already established by Phase 35
  and Phase 36 instead of letting “reachable” or “visible in docs” expand the
  contract implicitly.
- Keep failures humane: “this promised seam drifted” is the right tone, not
  “some exported function changed so CI is red.”

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — Phase 37 goal, requirements, and success criteria.
- `.planning/PROJECT.md` — `v1.0` stability-lock posture and one-maintainer
  honesty constraints.
- `.planning/REQUIREMENTS.md` — `PROOF-01..04` requirement definitions.
- `.planning/STATE.md` — current milestone/phase position.
- `.planning/METHODOLOGY.md` — honest-surface and recommendation-first posture.
- `.planning/phases/36-deprecation-and-compatibility-contract/36-CONTEXT.md` —
  locked compatibility/deprecation posture inherited by this phase.

### Current contract and compatibility source of truth
- `docs/api_stability.md` — canonical core stable/internal/sibling inventory.
- `mailglass_admin/docs/api_stability.md` — canonical admin stable/internal
  inventory.
- `guides/compatibility-and-deprecations.md` — canonical compatibility policy
  and strict-CI posture.
- `guides/upgrading-to-v1_0.md` — deprecation-DX inventory proof shape that
  Phase 37 should preserve.

### Existing proof and maintainer workflow surfaces
- `lib/mix/tasks/mailglass.stability.check.ex` — current narrow leak checker.
- `lib/mix/tasks/mailglass.docs.check.ex` — current Tier 1 docs-truth checker.
- `scripts/verify_support_contract.sh` — current repo-root support-contract
  entrypoint.
- `mix.exs` — semantic verify aliases, compile lane, and core support-contract
  bucket wiring.
- `mailglass_admin/mix.exs` — admin support-contract alias and docs grouping.
- `MAINTAINING.md` — required checks, release posture, and honest
  support-contract framing.
- `.github/workflows/ci.yml` — current required CI buckets and support-contract
  lanes.

### Existing testing contract surfaces
- `guides/testing.md` — adopter-facing testing guide that should become the
  canonical trust doc.
- `lib/mailglass/test_assertions.ex` — stable adopter-facing testing helper
  surface.
- `test/support/mailer_case.ex` — canonical library test harness semantics and
  async/shared/Oban boundaries.
- `test/support/data_case.ex` — canonical sandbox/tenant test posture.
- `test/support/oban_helpers.ex` — optional Oban test support.
- `test/mailglass/test_assertions_test.exs` — helper behavior proof.
- `test/mailglass/mailer_case_test.exs` — MailerCase behavior proof.
- `test/mailglass/test_assertions_pubsub_test.exs` — PubSub-backed assertion
  proof.
- `test/mailglass/docs_contract_test.exs` — Tier 1 docs verification surface.

### Existing admin semantics surfaces
- `mailglass_admin/README.md` — current operator/auth/replay contract summary.
- `mailglass_admin/lib/mailglass_admin/router.ex` — stable router contract and
  explicit session whitelist.
- `mailglass_admin/lib/mailglass_admin/auth.ex` — stable adopter-owned auth
  behavior.
- `mailglass_admin/lib/mailglass_admin/operator/mount.ex` — mount-time
  authorization semantics.
- `mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex` —
  action-time destructive auth semantics.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — replay flow and
  exact-target semantics.
- `mailglass_admin/test/mailglass_admin/router_test.exs` — router/session proof.
- `mailglass_admin/test/mailglass_admin/auth_test.exs` — auth behavior proof.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — operator
  access, replay, and stale-auth proof.
- `guides/operator-incident-support.md` — replay vs reconcile trust semantics.

### External ecosystem precedents
- `https://hexdocs.pm/elixir/writing-documentation.html` — `Code.fetch_docs/1`,
  `:since`, and deprecation metadata as contract truth.
- `https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html` — explicit
  allowance vs shared-mode testing posture.
- `https://hexdocs.pm/phoenix_ecto/Phoenix.Ecto.SQL.Sandbox.html` — browser and
  cross-process sandbox guidance.
- `https://hexdocs.pm/oban/testing.html` — `:inline` and `:manual` testing
  modes.
- `https://hexdocs.pm/phoenix_live_view/security-model.html` — LiveView
  mount-time and action-time auth model.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html` —
  mountable admin/dashboard auth posture.
- `https://hexdocs.pm/swoosh/Swoosh.TestAssertions.html` — familiar assertion
  surface precedent.
- `https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html` — cross-process mail
  testing precedent.
- `https://hexdocs.pm/bamboo/Bamboo.Test.html` — explicit shared-mode testing
  precedent.
- `https://guides.rubyonrails.org/testing.html` — mature mailer/job testing
  teaching pattern.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mailglass.docs.check` already provides a release-blocking docs-truth layer
  for Tier 1 guides and can absorb the testing/admin trust-doc story.
- `mailglass.stability.check` already establishes the project’s preferred proof
  shape: narrow semantic enforcement over broad export policing.
- `scripts/verify_support_contract.sh` already gives the repo one honest
  root-level proof entrypoint that Phase 37 can strengthen instead of replacing.
- `Mailglass.TestAssertions`, `MailerCase`, `DataCase`, and Oban helpers
  already provide a strong adopter-facing testing surface; the main gap is
  canonical storytelling and exact docs alignment.
- `MailglassAdmin.Router`, `MailglassAdmin.Auth`, and the operator auth/replay
  modules already implement the semantic admin contract that the docs should
  formalize.

### Established Patterns
- The repo prefers explicit semantic contracts over inferred reachability.
- Warnings-as-errors is treated as part of user-facing contract truth.
- Stable/internal/sibling-only classification is already the canonical way to
  talk about surface area.
- Optional dependencies stay optional in the default contract and are documented
  as extra lanes rather than baseline assumptions.
- Exact-target and tenant-safe semantics are preferred over convenience
  shortcuts that could surprise operators.

### Integration Points
- Phase 37 should connect canonical docs, compiled-doc tests, docs-contract
  checks, support-contract aliases, and CI buckets into one coherent proof
  story.
- The testing trust doc should connect public guide examples directly to
  `Mailglass.TestAssertions`, `MailerCase`, and the support-contract docs lane.
- The admin trust doc should connect router macros, auth behavior, operator
  tests, and incident-support guidance without promoting UI internals to
  contract status.

</code_context>

<deferred>
## Deferred Ideas

- Generated contract manifests or ABI/export snapshots for release artifacts.
- Any contract that freezes admin DOM, CSS, component APIs, or LiveView
  internals for `v1.x`.
- Broad testing-doc sprawl across multiple guides instead of one canonical
  trust doc.
- New runtime warning infrastructure, auth systems, or broader compatibility
  promises beyond the existing narrow `v1.x` contract.
- Repo-wide GSD workflow/config changes beyond the already-documented
  recommendation-first methodology; if desired, that is separate workflow work.

</deferred>

---

*Phase: 37-contract-enforcement-and-trust-docs*
*Context gathered: 2026-05-05*
