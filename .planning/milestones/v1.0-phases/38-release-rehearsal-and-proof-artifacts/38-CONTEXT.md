# Phase 38: Release Rehearsal and Proof Artifacts - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Rehearse the `v1.0` release end to end and produce fresh proof artifacts that
show the documented install, upgrade, packaging, docs, and sibling-package
release story is trustworthy.

This phase is about proving the already-defined `v1.x` contract with honest,
repeatable release evidence. It is not a new runtime-feature phase, not a broad
installer redesign, not a new compatibility-policy phase, and not a general CI
overhaul beyond what is required to make release proof durable and trustworthy.

</domain>

<decisions>
## Implementation Decisions

### Overall release-proof posture
- **D-38-01:** Phase 38 should default to one coherent recommendation set and
  only re-open choices that materially affect:
  - the public `v1.0` release contract
  - irreversible publish posture
  - security/trust semantics
  - long-term maintainer burden in a meaningful way
- **D-38-02:** Keep the release proof narrow and honest. Prefer a small number
  of durable, semantically meaningful proofs over a broad ceremony that mixes
  required truth with optional nice-to-haves.
- **D-38-03:** Repo-enforceable proof should stay repo-enforced. The manual
  checklist should cover only human/external steps that the repo cannot prove by
  itself.

### Install rehearsal default
- **D-38-04:** The canonical fresh-install rehearsal should stay aligned with
  the repo’s existing release-day smoke contract:
  - create a fresh Phoenix host from the published tag/version
  - add `mailglass` and `mailglass_admin`
  - run `mix deps.get`
  - run `mix mailglass.install`
  - run `mix compile --warnings-as-errors`
  - boot the endpoint
  - verify `GET /dev/mail/` returns HTTP 200
- **D-38-05:** The default install rehearsal host should be
  `phx.new --no-ecto --no-mailer --install`, because that matches the current
  fastest revert-window smoke and the existing workflow/test contract.
- **D-38-06:** The generated `config :swoosh, :api_client, false` sentinel is
  part of the release-proof contract for fresh hosts and must remain explicitly
  verified.
- **D-38-07:** A deeper Ecto-enabled onboarding smoke may exist, but it should
  be a secondary proof lane, not the default release-window rehearsal. The
  default path should optimize for fast trustworthy release/revert feedback.

### Upgrade rehearsal default
- **D-38-08:** The canonical upgrade rehearsal should use
  `guides/upgrading-to-v1_0.md` as the single authority and treat
  `guides/upgrading-from-v0_1.md` and `guides/migration-from-swoosh.md` as
  subordinate references only.
- **D-38-09:** The upgrade target state should be the stable lane:
  - `Mailglass.deliver*`
  - native `Mailglass.Message` setters
  - `Mailglass.Message.update_swoosh/2` only as the advanced escape hatch
  - matched `mailglass` and `mailglass_admin` release lines when both ship
- **D-38-10:** The default release rehearsal should assume the latest supported
  `0.3.x -> 1.0` path, not older historical upgrade lanes.
- **D-38-11:** `Mailglass.Message.new/2` should be treated as release-blocking
  for strict adopters because it emits real deprecation warnings under
  `--warnings-as-errors`.
- **D-38-12:** Raw `%Swoosh.Email{}` delivery and `Mailglass.Outbound.send/2`
  remain compatibility-lane bridges, but they should be documented and tested as
  transitional paths, not normalized as the preferred `1.x` posture.
- **D-38-13:** The default upgrade rehearsal gate should be strict and
  recommendation-first:
  - `mix verify.docs.migration`
  - `mix verify.stability_contract`
  - `mix docs --warnings-as-errors`
  - `cd mailglass_admin && mix docs --warnings-as-errors` when admin ships

### Proof artifacts default
- **D-38-14:** Canonical Phase 38 proof should be committed in-repo, not left
  primarily as ephemeral GitHub workflow summaries or transient temp
  directories.
- **D-38-15:** The default artifact shape should be one coherent proof bundle
  that captures:
  - tarball/package contents truth
  - HexDocs input truth
  - sibling-version/pin truth
  - release rehearsal evidence
- **D-38-16:** Tarball proof should build on the existing publish-check
  allowlists and summary data rather than inventing a second packaging checker.
- **D-38-17:** HexDocs proof should capture the exact docs inputs that define
  what will be published:
  - package `files`
  - docs `extras`
  - docs grouping
  - source URL / source reference patterns
- **D-38-18:** Sibling-package proof should make the linked-version release
  contract durable and inspectable, including the release manifest versions and
  the exact `mailglass_admin` publish-mode dependency pin.
- **D-38-19:** Release evidence should include one committed rehearsal/release
  record with concrete values such as:
  - publish workflow run URL
  - post-publish smoke run URL
  - tag used
  - Hex index confirmation
  - HexDocs URLs
  - fallback path used or explicitly not needed

### Manual checklist posture
- **D-38-20:** The manual release checklist should cover only external or
  human-gated steps:
  - GitHub Environment approval
  - branch-protection / GitHub settings verification
  - tag-based fallback dispatch if publish fan-out fails
  - live Hex / HexDocs verification
  - the 60-minute manual smoke and revert decision window
- **D-38-21:** Every manual checklist item should require explicit proof data,
  not vague confirmation. Prefer run URLs, tag names, HTTP results, timer
  boundaries, and approver identity over “looks good” prose.
- **D-38-22:** The 60-minute revert window and zero-download decision remain
  fundamentally external/temporal constraints. Document them explicitly rather
  than pretending the repo can fully automate them.
- **D-38-23:** Branch-protection verification remains accepted external closeout
  debt unless Phase 38 also repairs the currently stale branch-protection helper
  assets. Until then, the checklist must call this out honestly.

### Release engineering ergonomics
- **D-38-24:** Downstream planning should prefer reusing and exporting evidence
  from existing proof seams:
  - `mix mailglass.publish.check`
  - committed tarball allowlists
  - `verify.stability_contract`
  - docs checks
  - post-publish smoke workflow
  rather than creating parallel proof systems.
- **D-38-25:** Where external precedent is helpful, Phase 38 should borrow:
  - Hex’s prepublish inspectability and post-publish consumer test posture
  - Elixir/Django/Rails style deprecate-before-break honesty
  - SQLAlchemy’s staged migration model where warnings are resolved before the
    major-version cut
- **D-38-26:** The developer experience goal is “least surprise for serious
  adopters”: one canonical install story, one canonical upgrade story, one
  canonical release-proof bundle, and one narrow honest manual checklist.

### the agent's Discretion
- Exact filenames and directory layout for the committed proof bundle.
- Exact mix-task/script export shape used to persist publish-check and docs
  inputs into durable artifacts.
- Exact wording and formatting of the release evidence/checklist docs.
- Exact whether/how to add a secondary Ecto-enabled onboarding smoke lane, as
  long as it stays secondary to the canonical fast release-window rehearsal.

</decisions>

<specifics>
## Specific Ideas

- The recommended install proof follows the ecosystem norm of testing the
  published package from a disposable consumer app, not only from path deps or
  repo fixtures.
- The recommended upgrade proof follows the strongest cross-ecosystem pattern:
  stage the migration before the major cut, document one canonical path, and
  resolve warning-producing bridges before calling the release clean.
- The recommended proof-artifact posture is “committed summary of truth,” not
  “keep every workflow log forever.” Durable artifacts should summarize exactly
  the release-relevant evidence a maintainer or adopter would need to audit.
- The recommended manual-checklist posture mirrors successful library release
  practice: automate what the repo can truly prove, but keep irreversible
  external steps explicit and honest.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — Phase 38 goal, requirements, and success criteria.
- `.planning/PROJECT.md` — `v1.0` stability-lock framing, maintainer budget,
  and release-proof goal.
- `.planning/REQUIREMENTS.md` — `RELS-01..04` requirement definitions.
- `.planning/STATE.md` — current milestone/phase position.
- `.planning/METHODOLOGY.md` — decisive-by-default and recommendation-first
  posture for release/upgrade work.
- `.planning/phases/36-deprecation-and-compatibility-contract/36-CONTEXT.md` —
  locked compatibility and upgrade posture.
- `.planning/phases/37-contract-enforcement-and-trust-docs/37-CONTEXT.md` —
  locked trust-doc and proof-workflow posture.

### Canonical release/install/upgrade docs
- `MAINTAINING.md` — maintainer release runbook, 60-minute smoke window, and
  manual external checks.
- `README.md` — public install and quickstart story.
- `guides/getting-started.md` — canonical onboarding path details.
- `guides/compatibility-and-deprecations.md` — canonical `1.x`
  compatibility/deprecation posture.
- `guides/upgrading-to-v1_0.md` — canonical latest `0.x -> 1.0` upgrade guide.
- `guides/upgrading-from-v0_1.md` — subordinate codemod-focused migration
  reference.
- `guides/migration-from-swoosh.md` — subordinate raw-Swoosh migration
  reference.

### Existing proof and release-engineering seams
- `.github/workflows/publish-hex.yml` — canonical publish workflow, prepublish
  summary, CI gate, environment approval, and indexing waits.
- `.github/workflows/post-publish-smoke.yml` — canonical post-publish smoke and
  fallback dispatch contract.
- `.github/workflows/release-please.yml` — linked-version release wiring and
  sibling pin rewrite.
- `.github/workflows/branch-protection-drift.yml` — branch-protection reassert
  workflow and external-debt boundary.
- `.github/workflows/ci.yml` — support-contract and docs-as-errors truth.
- `lib/mix/tasks/mailglass.publish.check.ex` — package/tarball verification,
  summary generation, and proof-export seam.
- `lib/mix/tasks/mailglass.docs.check.ex` — Tier 1 docs truth verification.
- `lib/mix/tasks/mailglass.stability.check.ex` — narrow semantic proof posture.
- `scripts/verify_support_contract.sh` — repo-root proof entrypoint.
- `scripts/setup_branch_protection.sh` — branch-protection desired-state script.

### Existing tests and fixtures that already prove the target story
- `test/mailglass/install/install_first_preview_smoke_test.exs` — release-day
  fresh-host smoke contract mirror.
- `test/mailglass/install/install_idempotency_test.exs` — installer snippet and
  idempotency sharp edges.
- `test/mailglass/docs_migration_smoke_test.exs` — canonical upgrade-doc and
  parity smoke proof.
- `test/mailglass/compatibility_contract_test.exs` — compatibility-lane
  inventory proof.
- `test/mailglass/stability_contract_test.exs` — root proof wiring assertions.
- `mailglass_admin/test/mailglass_admin/mix_config_test.exs` — publish-mode
  sibling pin guard.
- `test/support/installer_fixture_helpers.ex` — disposable host harness and
  known installer footguns.
- `.planning/publish/mailglass-files.expected` — committed core package allowlist.
- `.planning/publish/mailglass_admin-files.expected` — committed admin package
  allowlist.
- `.planning/milestones/v0.2-phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md`
  — prior committed rehearsal artifact shape.
- `.planning/milestones/v0.4-phases/27-release-install-closure/27-02-EVIDENCE.md`
  — prior release/install evidence shape.

### External precedents and ecosystem priors
- `https://hex.pm/docs/publish` — Hex guidance to inspect package metadata,
  publish from CI carefully, and test the published package from a consumer app.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` — `mix hex.publish`
  dry-run, revert window, and `mix hex.build --unpack` inspection guidance.
- `https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html` — docs generation and
  `--warnings-as-errors` posture.
- `https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html` —
  soft/hard deprecation and major-version removal posture.
- `https://docs.djangoproject.com/en/4.2/internals/release-process/` —
  deprecate-before-remove and docs-backport honesty.
- `https://guides.rubyonrails.org/v7.1/maintenance_policy.html` — narrow
  support windows and explicit bug/security release posture.
- `https://docs.sqlalchemy.org/en/20/changelog/migration_20.html` — staged
  migration model and warning-driven major-version readiness.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix mailglass.publish.check` already performs the hard parts of tarball
  proof: unpack, allowlist diff, required/denylist checks, isolated compile,
  size checks, and `hex.audit`.
- The repo already has a tag-pinned post-publish consumer-install workflow and
  a matching repo-local smoke test. Phase 38 should keep those aligned instead
  of inventing a second install proof story.
- The canonical upgrade guide, docs migration smoke test, compatibility
  contract test, and `verify.stability_contract` alias already define a strong
  upgrade-proof baseline.
- Release Please, manifest linking, and admin publish-mode exact pinning already
  provide the raw materials for sibling-version proof.

### Established Patterns
- The project prefers one canonical guide plus executable proof.
- The project prefers narrow honest surfaces over aspirational breadth.
- The project already distinguishes repo-native proof from external/manual
  release truth.
- Linked sibling releases and tag-based fallback dispatch are already part of
  the accepted release posture.

### Integration Points
- Phase 38 should connect `publish-hex`, post-publish smoke, docs checks,
  stability checks, tarball allowlists, and maintainer docs into one durable
  release-proof bundle.
- If proof artifacts are exported from existing tasks, they should reuse the
  current summary/check data rather than recompute packaging truth elsewhere.
- Manual checklist docs must align with real GitHub/Hex external constraints and
  explicitly call out any remaining stale helper assets or accepted debt.

</code_context>

<deferred>
## Deferred Ideas

- Broad installer redesign or generalized snippet-anchor hardening beyond what
  Phase 38 needs for trustworthy release proof.
- Replacing the current release-please sibling pin rewrite with an entirely
  different release automation architecture.
- Broad CI or branch-protection redesign outside the narrow stale-helper fixes
  required to keep the release checklist honest.
- Expanding compatibility promises beyond the current narrow `v1.x` surface.

</deferred>

---

*Phase: 38-release-rehearsal-and-proof-artifacts*
*Context gathered: 2026-05-05*
