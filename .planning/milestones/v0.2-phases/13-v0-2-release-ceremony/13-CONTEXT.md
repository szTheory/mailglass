# Phase 13: v0.2 Release Ceremony - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `mailglass` `0.2.0` and `mailglass_admin` `0.2.0` with a release process that is trustworthy, low-surprise, and migration-friendly for existing adopters and downstream OSS packages.

This phase delivers:
- curated `0.2.0` release notes and changelog narrative
- an end-to-end adopter walkthrough validation pass
- a targeted but strict public-doc audit for the v0.2 surface
- the coordinated Release Please -> Hex publish -> post-publish smoke ceremony

This phase does **not** deliver:
- broad compatibility guarantees across arbitrary customized Phoenix apps
- a generalized docs perfection pass over every published page
- a release-engineering platform rewrite during the `0.2.0` cut
- the deferred `release-please-action` v5 upgrade itself

</domain>

<decisions>
## Implementation Decisions

### Release narrative and changelog shape

- **D-13-01:** `mailglass` `0.2.0` uses a **maintainer-narrative changelog entry**, not a plain generated commit ledger.
- **D-13-02:** The `mailglass` `0.2.0` changelog entry must open with a short curated maintainer summary that explains what changed, who should care, and why this release exists.
- **D-13-03:** The top of the `mailglass` `0.2.0` entry must include explicit sections for:
  - breaking / upgrade-required changes
  - exact upgrade path (`mix mailglass.upgrade.v0_2`)
  - minimum dependency matrix
  - ambiguous-case escape hatch via `Mailglass.Message.update_swoosh/2`
  - rollback procedure
  - behavior changes adopters will feel immediately (API surface, stream policy, unsubscribe, suppression behavior)
- **D-13-04:** The categorized ledger (`Added`, `Changed`, `Fixed`) still exists under the curated top section, but it is secondary to the migration story.
- **D-13-05:** `mailglass_admin` `0.2.0` may use a shorter linked changelog entry, provided it clearly states that it is version-coordinated with `mailglass` core and whether adopters need to take any action.
- **D-13-06:** Do not ship `0.2.0` with internal phase IDs, plan IDs, or commit-scope archaeology leading the public release story.

**Why:** This release is not a routine patch. It is the release that asks downstream OSS packages to trust `mailglass ~> 0.2` as a stable public contract. The changelog must therefore act as the entrypoint for migration confidence, not just as a historical ledger.

### Adopter walkthrough validation contract

- **D-13-07:** REL-14 uses a **narrow but strict blocking contract**, not a broad compatibility matrix.
- **D-13-08:** The blocking contract is **A+**:
  - fresh Phoenix 1.8.5 host install proof
  - happy-path v0.1 adopter migration proof
  - one sentinel ambiguous-case fixture proving warning behavior and no silent bad rewrite
- **D-13-09:** The fresh-host proof must verify:
  - dependency add succeeds
  - `mix mailglass.install` succeeds
  - `mix compile --warnings-as-errors` succeeds
  - preview endpoint boots and responds successfully
- **D-13-10:** The happy-path upgrade proof must verify that a committed v0.1 adopter fixture using the eight supported setter patterns upgrades with zero manual edits for non-ambiguous cases and still compiles cleanly.
- **D-13-11:** The sentinel ambiguous-case fixture must verify:
  - unsupported or ambiguous Swoosh usage is **not** silently rewritten
  - `IO.warn` is emitted
  - the warning includes the migration-guide URL
  - the documented `update_swoosh/2` escape hatch resolves the case cleanly
- **D-13-12:** Broader matrices are **advisory only** for this phase:
  - umbrella apps
  - unusual router/layout structures
  - mixed or drifted repos
  - rollback semantics in dirty worktrees
  - multiple host variants beyond the committed sentinel fixtures
- **D-13-13:** The rollback procedure documented for adopters must be framed explicitly as a disposable-fixture or git-clean workflow, not as a promise that mailglass can safely auto-recover arbitrary dirty repositories.

**Why:** This is the least-surprise contract for an Elixir/Phoenix installer/codemod library. It proves the public promise without accidentally expanding the long-term support surface into “works across every customized existing Phoenix app.”

### Public-doc audit bar

- **D-13-14:** REL-15 uses a **tiered docs gate**, not an all-pages-are-equal release block.
- **D-13-15:** **Tier 1 release-blocking docs** are:
  - `README.md`
  - `guides/getting-started.md`
  - `guides/upgrading-from-v0_1.md`
  - `guides/migration-from-swoosh.md`
  - `guides/authoring-mailables.md`
  - `guides/unsubscribe.md`
  - `guides/dkim-setup.md`
  - `guides/webhooks.md`
- **D-13-16:** Tier 1 docs must be fully v0.2-native in commands, API examples, version references, and deliverability/compliance behavior.
- **D-13-17:** **Tier 2 follow-up docs** are:
  - `guides/components.md`
  - `guides/preview.md`
  - `guides/testing.md`
  - `guides/multi-tenancy.md`
  - `guides/telemetry.md`
- **D-13-18:** If a Tier 2 doc contains a command, API example, or behavioral statement that is actually broken or misleading on v0.2, it is automatically promoted to Tier 1 blocking status.
- **D-13-19:** The docs gate should optimize for adopter trust, not generic polish theater. The docs that users copy from or depend on for newly shipped contracts are the ones that block release.
- **D-13-20:** `mix mailglass.docs.check` should be considered a foundation, not the full gate. Planning may extend doc checks for Tier 1 stale-version / stale-API markers if that can be done with low false-positive risk.

**Why:** For this kind of Hex library, the homepage, install path, upgrade path, and newly load-bearing compliance/deliverability guides are where trust is won or lost. Making every public page equally release-blocking would add noise and ceremony without proportional user benefit.

### Release mechanics risk posture

- **D-13-21:** `mailglass` should ship `0.2.0` on the currently pinned `release-please-action` v4 path. Do **not** upgrade to v5 during this release ceremony.
- **D-13-22:** The deferred `release-please-action` v5 upgrade should happen in a dedicated follow-up PR after `0.2.0`, with its own rehearsal.
- **D-13-23:** The real pre-ship ceremony risk is **trigger semantics and workflow invocation**, not staying on v4 for one more cut.
- **D-13-24:** Before `0.2.0`, perform one explicit release rehearsal on the current path to confirm:
  - linked-version Release Please behavior
  - `mailglass_admin` dep-pin sync behavior
  - the actual publish invocation path
  - the expected post-publish smoke path
- **D-13-25:** Planning/execution must resolve the current ambiguity around `GITHUB_TOKEN`-triggered downstream workflows before the cut:
  - either switch Release Please to a PAT / GitHub App token that permits the intended follow-on workflow behavior
  - or declare `workflow_dispatch` the canonical publish/smoke path for `0.2.0` and document that explicitly in the runbook
- **D-13-26:** If Release Please creates the release/tag but the workflow fails mid-ceremony, the fallback path is manual `workflow_dispatch` of publish/smoke against the known tag, not improvisation.
- **D-13-27:** The existing custom `sed` pin-sync path is accepted for `0.2.0`. The ceremony should treat review of the generated release PR diff as mandatory, because this repository is not a vanilla Release Please setup.

**Why:** The release ceremony should be boring. Changing the release controller during the same cut adds novelty without meaningful user-facing value, while this repository already has enough custom release mechanics to make “fewer moving parts” the right default.

### Downstream agent discretion and default decision posture

- **D-13-28:** Downstream planning and execution agents should operate in a **decisive-by-default** mode for this phase.
- **D-13-29:** Do **not** escalate routine implementation questions back to the user when the choice is local, reversible, and does not materially alter the release contract.
- **D-13-30:** Only escalate if a choice would materially change one of:
  - the public release contract
  - publish safety / irreversibility
  - migration semantics
  - compliance or deliverability claims
  - a user-facing doc statement that could mislead adopters
- **D-13-31:** When several implementation approaches satisfy the locked decisions, choose the one that is most idiomatic for Elixir/Phoenix/Hex OSS, least surprising for adopters, and lowest ceremony for a single maintainer.

### the agent's Discretion

- Exact changelog prose, as long as the required sections and migration signals are present
- Exact fixture naming and file layout for happy-path and sentinel ambiguous-case validation
- Exact mechanism for extending docs checks, provided it stays low-noise and Tier-1-focused
- Exact rehearsal shape for the release mechanics dry run
- Exact phrasing in the maintainer runbook for manual fallback paths

</decisions>

<specifics>
## Specific Ideas

- The changelog should act like a maintainer speaking directly to an adopter who is deciding whether to trust `~> 0.2`, not like a generated pile of commit scopes.
- The upgrade guide should be the deep dive; the changelog should be the front door.
- The codemod contract should feel safe: “automatic where clearly safe, explicit warning where not.”
- Tier 1 docs are the docs users copy from or depend on for newly load-bearing behaviors. Those need zero ambiguity.
- Release-day engineering should favor boring, rehearsed mechanics over version-chasing.
- Strong DX for this phase means:
  - no silent codemod surprises
  - no misleading docs on the main adoption path
  - no unnecessary ceremony or blocker noise
  - no re-asking the user about routine implementation details

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 13 scope and requirements
- `.planning/ROADMAP.md` — Phase 13 goal, success criteria, and planned release-ceremony work
- `.planning/REQUIREMENTS.md` — `REL-13` through `REL-16`
- `.planning/PROJECT.md` — milestone goal, trust posture, maintainer voice, and one-maintainer constraints
- `.planning/STATE.md` — current milestone state and recent phase context

### Prior phase and release-engineering context
- `.planning/phases/08-release-engineering-hardening/08-CONTEXT.md` — locked release-engineering decisions, including deferral of the `release-please-action` v5 upgrade
- `.planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md` — unsubscribe/release-guide expectations that shape Tier 1 docs
- `.planning/phases/12-auto-suppression-soft-bounce-escalation/12-CONTEXT.md` — suppression and webhook behavior now exposed in v0.2 docs and release messaging

### Core release-facing docs
- `CHANGELOG.md` — core package changelog shape to be reworked for `0.2.0`
- `mailglass_admin/CHANGELOG.md` — sibling package release messaging
- `README.md` — published entrypoint and Tier 1 release blocker
- `guides/getting-started.md` — HexDocs landing guide and Tier 1 release blocker
- `guides/upgrading-from-v0_1.md` — primary v0.2 migration guide
- `guides/migration-from-swoosh.md` — external adoption path
- `guides/authoring-mailables.md` — primary authoring API guide
- `guides/unsubscribe.md` — release-blocking deliverability/compliance guide
- `guides/dkim-setup.md` — release-blocking DKIM verification guide
- `guides/webhooks.md` — webhook and auto-suppression behavior guide

### Release workflows and runbook
- `.github/workflows/release-please.yml` — release PR generation and custom dep-pin sync path
- `.github/workflows/publish-hex.yml` — publish ceremony and gate shape
- `.github/workflows/post-publish-smoke.yml` — post-publish smoke contract
- `MAINTAINING.md` — release runbook and manual smoke / fallback expectations
- `release-please-config.json` — Release Please configuration
- `.release-please-manifest.json` — linked-version manifest state

### Relevant implementation and validation code
- `lib/mix/tasks/mailglass.publish.check.ex` — pre-publish contract and changelog presence gate
- `lib/mix/tasks/mailglass.docs.check.ex` — current docs gate baseline
- `lib/mix/tasks/mailglass.upgrade.v0_2.ex` — codemod behavior and warning contract
- `lib/mix/tasks/mailglass.install.ex` — installer contract
- `mailglass_admin/mix.exs` — linked-version dependency pin shape
- `test/mailglass/install/install_idempotency_test.exs` — installer drift/idempotency baseline

### Ecosystem references that informed these decisions
- Phoenix installation and generator docs — https://hexdocs.pm/phoenix/installation.html
- Phoenix LiveView changelog / quick upgrade guide — https://hexdocs.pm/phoenix_live_view/changelog.html
- Oban changelog — https://hexdocs.pm/oban/changelog.html
- Igniter upgrade task docs — https://ash-project.github.io/igniter/Mix.Tasks.Igniter.Upgrade.html
- Keep a Changelog — https://keepachangelog.com/en/1.0.0/
- Release Please Action docs — https://github.com/googleapis/release-please-action
- GitHub workflow trigger semantics — https://docs.github.com/en/actions/how-tos/writing-workflows/choosing-when-your-workflow-runs/triggering-a-workflow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `post-publish-smoke.yml` already provides a strong fresh-host install/boot baseline for the release ceremony. Phase 13 should extend this shape rather than inventing a new matrix from scratch.
- `mailglass.publish.check` already enforces presence of a non-empty changelog section and gives a natural place to keep the ceremony strict.
- `mailglass.docs.check` already establishes the pattern of fail-loud doc contract checks and can be extended if needed.
- `mailglass.upgrade.v0_2` already exists as the codemod seam; Phase 13 should harden its warning contract and surrounding docs rather than redesign the task.
- `MAINTAINING.md` already carries a real release runbook and is the right place to make the publish fallback path explicit.

### Established Patterns

- mailglass favors explicit, documented contracts over hidden magic.
- The project already uses release-time verification and smoke tests as real gates, not ornamental checks.
- Optional or non-routine maintenance upgrades are usually deferred out of high-risk ceremonies rather than bundled into them.
- Public trust is built through strong docs and guided migrations, not by claiming universal automation coverage.

### Integration Points

- Changelog narrative and migration guide need to agree exactly with the behavior of `mix mailglass.upgrade.v0_2`.
- Tier 1 docs need to align with the actual v0.2 API surface and deliverability behavior shipped in Phases 9-12.
- The publish runbook, release workflow, and post-publish smoke workflow need a single explicit story about how the cut is invoked and recovered if automation partially fails.
- Release PR diff review is load-bearing because the repository uses custom linked-version pin syncing.

</code_context>

<deferred>
## Deferred Ideas

- Upgrade `googleapis/release-please-action` to v5 in a dedicated post-`0.2.0` PR with its own rehearsal
- Broader migration-compatibility matrix across umbrella apps and highly customized existing Phoenix hosts
- Full polish pass over Tier 2 docs once the `0.2.x` line is stable
- Project-wide codification of the “decisive by default, escalate only on truly impactful decisions” preference outside this phase if it proves broadly useful across GSD workflows

</deferred>

---

*Phase: 13-v0-2-release-ceremony*
*Context gathered: 2026-04-28*
