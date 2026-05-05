# Domain Pitfalls

**Domain:** `mailglass` v1.0 stability lock for a Phoenix/Elixir transactional email framework
**Researched:** 2026-05-05
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Declaring stability before the contract is actually coherent
**What goes wrong:** `mailglass` tells two stories at once: `docs/api_stability.md` says the public API was "completely frozen" in `v0.2`, while project planning still treats `v1.0` as the real stability lock. Adopters cannot tell whether `v0.x` is effectively stable already or whether more churn is still fair game.
**Why it happens:** closed atom sets, stable internals, and product-level support promises get mixed together as if they were the same thing.
**Consequences:** trust loss, "you broke your promise" issues, and maintainers boxed in by earlier wording.
**Prevention:** pick one authoritative contract for `v1.0` and make everything else subordinate to it. Separate:
- locked invariants
- public API surface
- supported runtime matrix
- deprecation/removal policy
- best-effort internals
**Warning signs:** docs or code comments say "public", "supported", "stable", or "frozen" inconsistently; README, changelog, and `api_stability.md` disagree; maintainers justify breaking changes with "that was only internal" after documenting it.
**Phase to address:** Phase 1: Stability Contract Audit

### Pitfall 2: Accidentally freezing far more surface area than intended
**What goes wrong:** in Elixir, documented modules, macros, structs, types, route helpers, and mix tasks quickly become de facto public API. `mailglass` already exposes route macros, `use` macros, mix tasks, test helpers, Ecto-backed structs, and admin/router helpers. If v1.0 ships without an explicit allowlist, adopters will couple to whatever compiles.
**Why it happens:** BEAM libraries make internals easy to call; `@doc false` helps with docs, but exported functions and macros still exist. `mailglass_admin` is especially vulnerable because mount helpers and session callbacks are exported for framework reasons.
**Consequences:** trivial refactors become semver-major work; support tickets appear for internals the maintainer never meant to own.
**Prevention:** publish an explicit public-surface allowlist for both `mailglass` and `mailglass_admin`. Everything else is reserved/internal. Add CI that snapshots:
- documented public modules/functions
- public macros
- public mix tasks
- stable struct fields and closed atom sets
**Warning signs:** adopters are told to call `Mailglass.Operator.*`, `Mailglass.OptionalDeps.*`, router/session helper functions, or internal schemas directly; new exported module appears without a contract review.
**Phase to address:** Phase 1: Stability Contract Audit

### Pitfall 3: Keeping escape hatches that silently freeze the underlying engine
**What goes wrong:** `Mailglass.Message.update_swoosh/2` is the right escape hatch for uncommon cases, but every documented escape hatch encourages downstream reliance on `Swoosh.Email` shape and behavior. If `mailglass` later wants to change its internal engine boundary, v1.0 adopters will treat that as a breaking change.
**Why it happens:** escape hatches feel cheap before `1.0`, but post-`1.0` they are part of the contract.
**Consequences:** internal implementation choices become permanent; provider-specific support burden shifts back onto the maintainer.
**Prevention:** keep exactly one escape hatch and define its scope narrowly: "`update_swoosh/2` exists, but provider-specific behavior inside the callback is adopter-owned." Do not add more raw-engine escape hatches before `v1.0`.
**Warning signs:** docs show raw `Swoosh.Email.*` usage as a normal pattern; support requests ask `mailglass` to guarantee provider-specific mutations; more public specs mention `Swoosh` or `%Oban.Job{}`.
**Phase to address:** Phase 1: Stability Contract Audit

### Pitfall 4: Weak deprecation UX that shifts migration cost onto adopters
**What goes wrong:** a library claims stability but only provides ad hoc warnings, sparse upgrade docs, or no codemod path. In Elixir this is worse because compile-time warnings become CI failures for teams using `--warnings-as-errors`.
**Why it happens:** maintainers treat deprecation as a note in the changelog instead of a product workflow.
**Consequences:** minor upgrades feel dangerous; adopters pin old versions; support burden spikes around every non-trivial rename.
**Prevention:** follow the stronger pattern used by Elixir/Phoenix/Django:
- soft deprecate in docs/changelog first when possible
- hard deprecate only when the replacement is already proven
- never remove before the next major
- provide an upgrade guide for every user-visible deprecation
- provide a codemod when the migration is mechanical
`mailglass` already did this well for the `v0.1` to `v0.2` mailable shift; v1.0 should turn that into policy, not a one-off success.
**Warning signs:** only one `@deprecated` remains in the tree despite prior surface churn; deprecations lack "use X instead"; upgrade docs lag the current release; changelog says "breaking" but no migration path exists.
**Phase to address:** Phase 2: Deprecation and Upgrade Contract

### Pitfall 5: Promising a compatibility matrix broader than one maintainer can actually support
**What goes wrong:** a `v1.0` badge tempts libraries to say "Phoenix/Elixir compatible" in broad terms. For `mailglass`, every extra dimension multiplies cost: Elixir, OTP, Phoenix, LiveView, Ecto, Postgres, optional deps, provider adapters, and sibling packages.
**Why it happens:** teams confuse "declared floor" with "tested support matrix."
**Consequences:** false confidence, flaky CI, slow releases, and support debates over combinations that were never really covered.
**Prevention:** keep the promise narrow and explicit. Recommended direction:
- support the current stated floor only: Elixir `~> 1.18`, OTP `27+`, Phoenix `~> 1.8`, Postgres only
- document optional deps as opt-in feature lanes, not universally supported combinations
- test the floor and the current latest patch of supported lanes
- state that floor bumps happen only in majors unless required by security/ecosystem breakage
**Tradeoff:** a wider matrix improves adoption optics but is the wrong bargain for a one-person maintainer. A narrow, honest matrix is less surprising.
**Warning signs:** advisory jobs fail for long periods; docs imply support for versions not exercised in CI; optional deps are described as "supported" without separate verification lanes.
**Phase to address:** Phase 2: Compatibility and Support Window

### Pitfall 6: Treating `mailglass_admin` like a stable operator platform without defining the support boundary
**What goes wrong:** once a library ships an admin UI, users assume stronger guarantees around auth hooks, tenant scoping, incident workflows, replay semantics, masked data, and long-term operator ergonomics. If v1.0 is vague here, library users will build automation or internal runbooks around unstable UI/read-model details.
**Why it happens:** UI surfaces look productized even when only part of them is intended as API.
**Consequences:** support burden moves from "library semantics" to "operator workflow regressions"; UI copy or read-model changes become breaking changes in practice.
**Prevention:** define what is stable in `mailglass_admin`:
- route macros and mount contract
- auth behaviour/callback expectations
- operator action semantics
- read-model guarantees, if any
Everything else should be explicitly non-contractual presentation detail.
**Warning signs:** guides describe admin screens as canonical support interfaces without naming stable extension points; adopters scrape HTML or couple to assigns/read-model internals; docs imply hosted-service-style operator guarantees.
**Phase to address:** Phase 3: Admin Support Contract

### Pitfall 7: Docs drift turns a stable library into an unstable experience
**What goes wrong:** the code is stable, but docs, guides, changelog, and install flow disagree. Swoosh's changelog repeatedly includes discoverability and provider-doc fixes; Symfony Mailer users complained when migration guidance lagged the Swiftmailer sunset. `mailglass` already has signals of drift risk, such as outdated guide timestamps and conflicting status language across core docs.
**Why it happens:** docs are treated as follow-up work instead of release-blocking surface.
**Consequences:** repeated support questions, failed installs, confused upgrades, and erosion of v1.0 credibility.
**Prevention:** make docs parity a release gate:
- README scope/status must match milestone reality
- every public mix task and route macro must have one canonical guide
- upgrade guides must be current or explicitly archived
- docs smoke tests should verify links, package status wording, and supported provider/runtime tables
**Warning signs:** changelog introduces a user-facing behavior with no guide update; README still describes old package status; docs reference future phases as if shipped.
**Phase to address:** Phase 3: Docs and Positioning Sweep

### Pitfall 8: Release process surprises across sibling packages
**What goes wrong:** `mailglass` and `mailglass_admin` publish together but drift in dependency pins, docs, or smoke coverage. Fresh-host install flow passes in-repo but fails post-publish. Hex docs publish automatically, so a bad tarball or stale docs bundle becomes user-visible immediately.
**Why it happens:** sibling packages multiply ceremony, and the hardest failures appear only after publish.
**Consequences:** broken upgrades, emergency patch releases, and high-support release days.
**Prevention:** run a release rehearsal before `v1.0` that proves:
- linked versions are correct
- fresh Phoenix install works from Hex, not path deps
- admin package pins the exact core version
- docs published for the exact tag
- required CI buckets and manual branch-protection steps are spelled out
**Warning signs:** publish workflows require release-day sed/workarounds; post-publish smoke fixes recur in changelog history; manual external checks are undocumented or easy to skip.
**Phase to address:** Phase 4: Release Rehearsal and Proof Artifacts

## Moderate Pitfalls

### Pitfall 1: Letting provider quirks expand the v1.0 contract by accident
**What goes wrong:** mail provider behavior changes, and adopters expect `mailglass` to smooth every edge forever because it normalized provider webhooks once.
**Prevention:** keep provider normalization stable at the documented event layer, not at every provider-specific raw field. Raise explicit errors for unsupported provider features instead of silently best-effort behavior.

### Pitfall 2: Turning internal data models into public integration points
**What goes wrong:** adopters start querying `mailglass_*` tables or depending on Ecto schema struct fields directly because they are visible and useful.
**Prevention:** document DB tables as implementation detail unless explicitly exported. Stable integration points should be library APIs, telemetry, or guides, not incidental schema shape.

### Pitfall 3: Forgetting that compile-time behavior is part of the UX contract
**What goes wrong:** Phoenix/Plug/Elixir upgrades introduce new warnings or deprecations and downstream users hit failures because `mailglass` encourages `--warnings-as-errors`.
**Prevention:** keep a forward-looking advisory lane for upcoming Elixir/Phoenix changes, but do not promise support until the lane is green and documented.

## Lessons from Other Ecosystems

| Library / ecosystem | What they did right | What they did wrong | What `mailglass` should copy or avoid |
|---------------------|---------------------|---------------------|---------------------------------------|
| Elixir / Phoenix / Plug | Soft-deprecate before warning, document deprecations, keep minors broadly compatible | Minor releases can still surface new warnings or break buggy assumptions | Copy their deprecation discipline; do not promise "no surprises" beyond documented API |
| Django | Formal deprecation runway across feature releases | More process overhead | Copy the explicit removal timeline |
| Rails | Clear maintenance policy and versioning explanation | Rails minors may contain API changes, which is fine for Rails but not for a Hex library promising semver stability | Avoid Rails-style "minor may break" semantics |
| Anymail | Excellent support-window clarity; explicit note that undocumented internals are not semver surface; raises explicit errors when providers silently ignore features | External provider churn still leaks into release cadence | Copy the "documented surface only" stance and explicit unsupported-feature errors |
| Swoosh | Good long-term utility, active changelog, frequent doc/discoverability fixes | Optional-dep and provider-doc clarity required repeated follow-up work; version-floor bumps still matter | Keep docs/install/provider guidance release-blocking, not aspirational |
| Swiftmailer | Eventually replaced legacy architecture with a cleaner design | Waited too long to reset architecture; short EOL notice frustrated users | If any architectural reset is still needed, do it before `v1.0`, not right after |

## Smallest Useful Guardrail Set

1. One canonical `v1.0` stability contract covering public surface, support window, and deprecation policy.
2. CI-enforced public API snapshot for documented modules/macros/mix tasks/types.
3. Written deprecation workflow: soft -> hard -> remove-next-major, with upgrade guide and codemod requirement for mechanical changes.
4. Narrow support promise: exact runtime floor plus explicitly named optional-dependency lanes.
5. Release rehearsal from Hex on a fresh Phoenix app, including sibling-package and docs verification.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 1: Stability Contract Audit | Freezing the wrong surface, especially macros/helpers/schemas | Publish public allowlist; snapshot it in CI; resolve the `v0.2 freeze` vs `v1.0 lock` wording conflict |
| Phase 2: Deprecation and Compatibility Contract | Broad, vague support promises and weak migration UX | Write support window policy; require replacement path, warnings, docs, and codemod rules for deprecations |
| Phase 3: Admin Support + Docs Sweep | UI/read-model details become accidental API; docs drift persists | Define admin contract explicitly; add docs parity checks to release gates |
| Phase 4: Release Rehearsal + Proof Artifacts | Publish-day surprises across sibling packages and fresh installs | Rehearse full Hex release from clean host; verify docs, pins, smoke install, and required checks |

## Sources

- `mailglass` planning/docs/codebase: `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`, `README.md`, `docs/api_stability.md`, `guides/upgrading-from-v0_1.md`, `.github/workflows/advisory-matrix.yml`
- Elixir compatibility and deprecations: https://hexdocs.pm/elixir/main/compatibility-and-deprecations.html
- Elixir deprecation attributes and guidance: https://hexdocs.pm/elixir/1.12/Module.html
- ExDoc metadata (`deprecated`, `since`): https://hexdocs.pm/ex_doc/readme.html
- Hex publish behavior and docs publishing: https://hex.pm/docs/publish
- Phoenix changelog and deprecation examples: https://hexdocs.pm/phoenix/changelog.html
- Plug changelog and deprecation examples: https://hexdocs.pm/plug/changelog.html
- Oban support-window policy: https://hexdocs.pm/oban/2.19.0/changelog.html
- Rails maintenance policy: https://guides.rubyonrails.org/maintenance_policy.html
- Django release/deprecation policy: https://docs.djangoproject.com/en/4.2/internals/release-process/
- Anymail stable docs and changelog: https://anymail.dev/en/stable/index.html, https://anymail.dev/en/v12.0/changelog/
- Swiftmailer end-of-life and migration context: https://symfony.com/blog/the-end-of-swiftmailer, https://swiftmailer.symfony.com/docs/introduction.html
