# Phase 36: Deprecation and Compatibility Contract - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish one narrow, explicit `1.x` compatibility promise for `mailglass` and
`mailglass_admin`, including versioning/deprecation policy, support matrix, and
the canonical `0.x -> 1.0` upgrade path.

This phase is about making the existing stability contract usable for adopters
and maintainers. It is not a broad compatibility-matrix expansion, not a new
runtime feature phase, not a Swoosh replacement project, and not a promise to
stabilize every legacy or transitional surface that happens to remain callable.

</domain>

<decisions>
## Implementation Decisions

### Canonical compatibility docs
- **D-36-01:** Publish one canonical root compatibility guide separate from the
  stability inventories. Keep `docs/api_stability.md` and
  `mailglass_admin/docs/api_stability.md` focused on stable/internal surface
  inventory; they should point to the compatibility guide rather than absorb
  support policy, upgrade steps, and deprecation rules.
- **D-36-02:** README, admin README, maintainers docs, and ExDoc extras should
  all point to the same canonical compatibility guide instead of carrying
  partially independent policy text.

### Support matrix posture
- **D-36-03:** The support matrix should be narrow, semantic, and honest rather
  than aspirational. Document supported floors and tested lanes, not a large
  combinatorial matrix the repo does not prove.
- **D-36-04:** The documented `1.x` runtime/support posture should align with
  current package metadata and project boundaries:
  - Elixir `~> 1.18`
  - OTP `27+`
  - Phoenix `~> 1.8`
  - Phoenix LiveView `~> 1.1`
  - Ecto / Ecto SQL `~> 3.13`
  - Postgres 14+
- **D-36-05:** Postgres-only remains part of the compatibility contract.
  `mailglass` should not imply support for broader database/runtime
  combinations just because adjacent libraries are broader.
- **D-36-06:** `mailglass_admin` should be documented as a matched sibling, not
  an independently drifting package. Matching release lines are required, and
  publish-time exact pinning remains the source of truth for released package
  compatibility.
- **D-36-07:** `mailglass_inbound` remains outside the `v1.x` compatibility
  promise for this milestone.
- **D-36-08:** Optional dependencies should be documented as supported
  integration lanes when present, while the core compile/support contract stays
  green without them. Do not elevate optional third-party ecosystems to equal
  weight with the core stable contract.

### Stable lane vs compatibility lane
- **D-36-09:** The canonical `1.x` adopter-facing API posture is
  Message-first and root-entrypoint-first:
  - `Mailglass.deliver*`
  - native `Mailglass.Message` setters
  - `Mailglass.Message.update_swoosh/2` as the one blessed advanced Swoosh
    escape hatch
- **D-36-10:** Phase 36 should define two distinct lanes:
  - **Stable lane**: the documented `1.x` front door
  - **Compatibility lane**: a small, explicitly bounded set of retained legacy
    bridges that exist to make `0.x -> 1.0` upgrades low-friction
- **D-36-11:** The compatibility lane should stay small and non-expanding after
  `1.0`. It exists to ease adoption, not to freeze every reachable historical
  surface.
- **D-36-12:** `Mailglass.Outbound.send/2` must stop living in an ambiguous
  half-public state. Downstream work should treat it as a legacy compatibility
  bridge, not as part of the preferred stable front door. Root `Mailglass`
  delivery verbs remain canonical.

### Deprecation policy
- **D-36-13:** No documented adopter-facing API deprecated in `1.x` should be
  removed before `v2.0`, except for narrow security, data-loss, signature
  verification, or severe correctness emergencies that are explicitly called
  out in release notes.
- **D-36-14:** Every deprecated or legacy-supported path must have a documented
  replacement. “Supported” without a replacement path is not acceptable in the
  `1.x` compatibility contract.
- **D-36-15:** Distinguish two kinds of retained old paths in docs:
  - **Deprecated (warning-emitting)**: supported through `1.x`, but expected
    to break strict consumer builds that run with `--warnings-as-errors`
  - **Legacy supported alias/path (non-warning)**: old path still works
    silently, has a documented replacement, and must carry an explicit support
    horizon no earlier than `v2.0`
- **D-36-16:** Warning behavior should be documented honestly per path.
  Downstream docs should say whether a retained path is compiler-warning,
  task-warning, docs-only, or silent. Do not flatten these into one generic
  “deprecated but supported” bucket.
- **D-36-17:** Patch releases should avoid introducing new deprecations except
  for security/correctness emergencies. Minor releases may add deprecations but
  should not remove documented deprecated APIs.

### Upgrade-path shape
- **D-36-18:** Publish one canonical “latest released `0.x` -> `1.0`” guide.
  Existing guides such as `guides/upgrading-from-v0_1.md` and
  `guides/migration-from-swoosh.md` should become subordinate step references,
  not the whole upgrade story.
- **D-36-19:** The canonical upgrade guide should explicitly name:
  - legacy entrypoints that remain acceptable through `1.x`
  - legacy entrypoints that should be migrated immediately for strict CI users
  - required code changes
  - expected warning behavior
  - matched-version sibling-package expectations
- **D-36-20:** The codemod and transitional migration tasks remain useful
  tooling, but they should not be accidentally promoted into long-term stable
  contract surface.

### Strict-CI and DX posture
- **D-36-21:** Warnings-as-errors adopters are a first-class audience in this
  phase. The compatibility contract should explicitly tell them which retained
  paths are effectively unsafe for new code because they emit warnings under
  strict compile/test settings.
- **D-36-22:** Do not add clever new warning infrastructure just to simulate a
  larger compatibility story. Favor honest docs, small inventories, and light
  enforcement checks over maintainability-heavy warning systems.
- **D-36-23:** Phase 37 should inherit a proof shape that validates a
  deprecation-DX inventory: surface, replacement, warning channel,
  `--warnings-as-errors` impact, support-until version, and proof artifact.

### Recommendation-first downstream posture
- **D-36-24:** Downstream research, planning, and execution for compatibility,
  deprecation, release, and trust-doc phases should default to one-shot,
  recommendation-first synthesis. Re-open choices only when they materially
  affect public contract, maintainer support burden, or user trust semantics.
- **D-36-25:** For this phase, downstream agents should prefer the narrowest
  honest compatibility promise that preserves smooth upgrades from the latest
  real `0.x` line.

### the agent's Discretion
- Exact canonical guide filename and section ordering.
- Exact wording for the support matrix and exception clauses, as long as they
  remain narrow, explicit, and truthful.
- Exact doc/test/check locations used to enforce the deprecation-DX inventory.
- Exact handling of maintainer-facing `verify.phase_*` aliases, as long as
  their support horizon and audience are documented honestly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — Phase 36 goal, requirements, and success criteria.
- `.planning/PROJECT.md` — current `v1.0` stability-lock framing, narrow
  support posture, and warnings-as-errors adopter concern.
- `.planning/REQUIREMENTS.md` — `COMPAT-01..04` requirement definitions.
- `.planning/STATE.md` — current milestone/phase position.
- `.planning/METHODOLOGY.md` — honest surface area and
  recommendation-first synthesis posture.

### Current stability inventories
- `docs/api_stability.md` — canonical core stable/internal inventory that
  compatibility policy must complement, not replace.
- `mailglass_admin/docs/api_stability.md` — canonical admin stable/internal
  inventory and sibling-package seam posture.

### Current public docs and release posture
- `README.md` — public install, package, and compatibility entrypoint.
- `mailglass_admin/README.md` — admin package public entrypoint.
- `MAINTAINING.md` — maintainer release flow, smoke-install path, and required
  verification truth.
- `guides/upgrading-from-v0_1.md` — existing transitional codemod-backed
  upgrade guide that should become subordinate to the canonical `0.x -> 1.0`
  guide.
- `guides/migration-from-swoosh.md` — current incremental migration posture for
  raw `%Swoosh.Email{}` adopters.

### Current implementation seams that define compatibility reality
- `lib/mailglass/message.ex` — `Message.new/2` deprecation and native-setter
  front door.
- `lib/mailglass/outbound.ex` — current `deliver` / `send` compatibility shape,
  including raw `%Swoosh.Email{}` acceptance.
- `lib/mix/tasks/mailglass.upgrade.v0_2.ex` — transitional codemod task.
- `lib/mix/tasks/mailglass.docs.check.ex` — current docs-contract checker that
  will need to enforce the new compatibility story.
- `lib/mix/tasks/mailglass.stability.check.ex` — current stability-check
  exemptions for deprecated/legacy surfaces.
- `mix.exs` — package version floor, ExDoc extras/groups, and deprecated
  maintainer alias posture.
- `mailglass_admin/mix.exs` — exact sibling pinning, version floor, and
  deprecated maintainer alias posture.
- `.github/workflows/ci.yml` — current compile/support truth and strict
  warnings lanes.
- `scripts/verify_support_contract.sh` — honest repo-root support-contract
  entrypoint.

### External precedents and ecosystem priors
- `https://semver.org/` — semantic versioning requirement to declare a public
  API and deprecate before incompatible removal.
- `https://hexdocs.pm/elixir/1.15.5/compatibility-and-deprecations.html` —
  explicit compatibility exceptions, warning-aware posture, and staged
  deprecation policy from the core language.
- `https://github.com/elixir-ecto/ecto` — supported-branch posture and stable
  API focus for a successful Elixir library.
- `https://readme.hex.pm/swoosh/1.3.1` — clean composable email-library API and
  separation-of-concerns precedent in the immediate ecosystem.
- `https://guides.rubyonrails.org/maintenance_policy.html` — explicit support
  windows and “deprecate before breaking” precedent from a widely adopted web
  framework.
- `https://docs.djangoproject.com/en/4.2/internals/release-process/` —
  deprecation-shim timing and explicit warnings/removal cadence precedent.
- `https://docs.sqlalchemy.org/20/changelog/migration_20.html` — strong
  migration-mode, warnings, and staged-upgrade precedent for a mature library
  moving users across a major-version boundary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The repo already has canonical surface-inventory docs for both core and admin
  packages. Phase 36 should extend that doc architecture rather than invent a
  new contract model.
- `mailglass.docs.check` already gives the project a release-blocking way to
  enforce Tier 1 compatibility wording after the new canonical guide is added.
- `mailglass.stability.check` already models a light-touch “prove the contract”
  posture and can later grow a deprecation-inventory check without heavy
  machinery.
- The current upgrade guides already contain useful migration content; they
  should be folded under one canonical `0.x -> 1.0` path rather than replaced
  wholesale.

### Established Patterns
- The project prefers narrow honest surfaces over brochure-style breadth.
- The project already treats `--warnings-as-errors` as part of contract truth,
  not merely maintainer preference.
- Sibling packages are intentionally linked and published together rather than
  treated as independent drifting products.
- Transitional tooling may ship, but it is not automatically stable contract
  surface.

### Integration Points
- Phase 36 should connect roadmap requirements, public guides, ExDoc extras,
  docs-check enforcement, and maintainers docs into one compatibility story.
- The canonical compatibility guide should become the shared source for README,
  admin README, and maintainers docs references.
- The deprecation policy must align code annotations, docs wording, strict CI
  lanes, and future trust-doc enforcement in Phase 37.

</code_context>

<specifics>
## Specific Ideas

- Best blended precedent for this phase:
  - SemVer: declare the public API first
  - Elixir: explicit compatibility exceptions and “remove only on major”
  - Rails/Django: deprecate before break; say exactly how long support lasts
  - SQLAlchemy: warn early, give a migration mode, and make upgrades testable
- Desired adopter experience:
  - one compatibility page
  - one upgrade guide
  - one clear answer for strict CI users
  - zero guessing about sibling versions or optional-dependency expectations
- Desired maintainer experience:
  - small honest policy
  - low-overhead proof checks
  - no accidental expansion of legacy support burden

</specifics>

<deferred>
## Deferred Ideas

- Broad runtime matrix expansion beyond the documented floors actually proven by
  CI and release rehearsal.
- Making optional third-party integrations first-class equal-weight guarantees
  inside the `1.x` stable contract.
- Adding heavyweight runtime deprecation telemetry or custom warning systems.
- Stabilizing every currently reachable legacy/transitional surface instead of
  keeping a small explicit compatibility lane.

</deferred>

---

*Phase: 36-deprecation-and-compatibility-contract*
*Context gathered: 2026-05-05*
