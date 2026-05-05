# Technology Stack

**Project:** mailglass  
**Researched:** 2026-05-05  
**Scope:** v1.0 Stability Lock stack additions and deliberate non-additions

## Recommendation

For `v1.0`, **do not add new runtime dependencies**. The right move is to lock the public contract using Elixir/Hex/ExDoc primitives already in the repo and add a small amount of **internal release-contract tooling**:

- `@since`, `@deprecated`, and `@doc deprecated:` metadata on every public module/function/type/callback that is part of the `1.x` contract
- ExDoc extras and grouping for a first-class stability/deprecation/upgrade story
- public API contract tests driven from compiled docs (`Code.fetch_docs/1`) plus explicit allowlists
- release-contract CI aliases covering docs, tarball contents, upgrade smoke, and deprecated-call detection
- compatibility policy docs that clearly separate:
  - stable public API
  - internal/private modules
  - optional integration seams
  - provider-specific behavior that is best-effort rather than guaranteed

This is the least-surprising, most idiomatic Elixir path. Phoenix/Ecto/Plug/Elixir itself all rely on SemVer, changelogs, deprecations, and docs-driven upgrade guidance rather than extra compatibility frameworks. `mailglass` should do the same.

## Keep As-Is

### Core Runtime
| Technology | Version/Range | Decision | Why |
|------------|---------------|----------|-----|
| Elixir | `~> 1.18` floor | Keep | Already aligned with current repo and avoids a late pre-`v1.0` floor change. |
| OTP | `27+` floor | Keep | Same reason; stability milestone should reduce variables, not add them. |
| Phoenix / Plug / LiveView | current repo ranges | Keep | No architecture change is needed to promise API stability. |
| Ecto / Ecto SQL / Postgrex | current repo ranges | Keep | Existing persistence stack is already part of the intended stable core. |
| Swoosh | current repo range | Keep | `mailglass` composes on Swoosh; the milestone is about contract clarity, not replacing the transport layer. |
| Boundary / Credo / Dialyzer / ExDoc / Hex | existing tooling | Keep | These are already the right primitives for public-surface discipline and release proof. |

### Deliberate Non-Change
| Area | Decision | Why |
|------|----------|-----|
| Runtime deps | Add none | Stability lock should shrink uncertainty, not expand it. |
| Optional deps | Add none | Oban/OpenTelemetry/MJML/gen_smtp/sigra are already enough variability. |
| Supported DBs | Stay Postgres-only | A support-matrix expansion right before `v1.0` weakens the promise. |
| Supported frameworks | Stay Phoenix-first | Do not dilute the contract with “framework-agnostic” ambitions now. |

## Additions Needed

### 1. Documentation Contract
Use existing `ex_doc ~> 0.40` and Elixir doc metadata rather than new doc tooling.

| Addition | Type | Integration Point | Why |
|----------|------|-------------------|-----|
| `guides/stability-policy.md` | new guide | `mix.exs` docs extras | One canonical promise for SemVer, support window, and what counts as public API. |
| `guides/deprecations.md` | new guide | `mix.exs` docs extras | Track active deprecations with version introduced, replacement, and earliest removal. |
| `guides/upgrading-to-v1.md` or `guides/upgrading.md` refresh | guide | existing guides set | Make `0.x -> 1.0` adoption boring. |
| `guides/support-matrix.md` | guide | docs extras | Declare required/advisory environment coverage and optional-dependency guarantees. |
| ExDoc grouping | docs config | root + `mailglass_admin/mix.exs` | Separate stable API, extension points, and internal/admin-only surfaces. |

**Required doc rules**

- Every public module/function/type/callback in the `1.x` contract gets `@since`.
- Every deprecated API gets both `@deprecated` and `@doc deprecated:`.
- Internal modules should prefer `@moduledoc false`; do not rely on `@doc false` to simulate privacy on otherwise public modules.
- `docs/api_stability.md` should evolve from “freeze-until-vNext” into a true `1.x` contract, not a pre-`1.0` note.

### 2. Public API Contract Testing
Add internal test/script tooling, not external packages.

| Addition | Type | Integration Point | Why |
|----------|------|-------------------|-----|
| Public API snapshot test | ExUnit | `test/` in root and admin | Detect accidental new public modules/functions/types/callbacks before release. |
| Stable-surface allowlist | repo file | `test/support` or `docs/` data file | Make contract drift explicit in PRs. |
| Deprecation inventory test | ExUnit/script | CI alias | Ensure every deprecated item has docs, replacement, and removal policy text. |
| Package contents smoke | Mix task/script | release CI | Verify tarballs contain all required docs/assets and no accidental internals. |
| Previous-version upgrade fixture | fixture app test | CI | Prove `0.x -> 1.0` install/compile/docs path on a clean adopter app. |

**Implementation pattern**

- Build the contract from `Code.fetch_docs/1`, not from AST scraping.
- Assert on:
  - public modules
  - public functions/macros
  - public types/callbacks
  - `@since` presence on stable API
  - deprecation metadata completeness
- Keep optional-deps adapters and internal plumbing out of the stable snapshot unless explicitly promised.

This is idiomatic for Elixir because docs are part of the compiled artifact and HexDocs is already the public source of truth.

### 3. Release-Contract CI
Add aliases/jobs, not more CI vendors.

| Addition | Type | Integration Point | Why |
|----------|------|-------------------|-----|
| `mix verify.stability` | alias | root `mix.exs` | Single gate for the milestone. |
| `mix verify.stability_admin` | alias | `mailglass_admin/mix.exs` | Keep sibling-package contract explicit. |
| `mix xref deprecated` check | script/alias | CI | Fail when library code still calls APIs it marked deprecated. |
| `mix hex.build --unpack` smoke | release CI | existing publish flow | Verify exact tarball contents before Hex publish. |
| `mix hex.package diff` against last release | release checklist/script | release flow | Produce a human-reviewable package delta for every release. |
| advisory latest-version lane | CI job | existing advisory matrix | Detect future Elixir/OTP breakage without widening required support prematurely. |

**Recommended gate composition**

`verify.stability` should cover:

1. docs build with warnings treated as failures
2. public API contract tests
3. docs/deprecation contract tests
4. tarball unpack smoke
5. upgrade fixture smoke
6. provider/support-contract tests already considered release-critical

## Policy Recommendations For `mailglass`

### Versioning

- Adopt strict SemVer for `mailglass` and `mailglass_admin` `1.x`.
- In `1.x`:
  - patch = bug fixes and doc fixes only
  - minor = additive features, new extension points, new stable atoms only
  - major = removals, contract rewrites, changed semantics that require adopter code changes

### Deprecation

- For `mailglass`, the least-surprise policy is:
  - deprecations may be introduced in `1.x`
  - deprecated APIs remain available for all of `1.x`
  - removals wait for `2.0`
- If an old shim is too risky to keep forever, mark it deprecated in docs and changelog, but do not remove it before `2.0`.
- Use compile-time warnings via `@deprecated`; do **not** invent a runtime deprecation warning system.

### Upgrade Guarantees

- Guarantee that a project on `1.x` can upgrade to later `1.y` without schema rewrites caused solely by `mailglass` API churn.
- Guarantee that documented stable structs/errors/event atoms remain additive-only within `1.x`.
- Do **not** guarantee undocumented internal modules, admin implementation details, or optional-dependency internals.

## What Successful Libraries Did Right

| Library | What they did right | Mailglass takeaway |
|---------|---------------------|--------------------|
| Elixir | Explicit soft/hard/remove deprecation stages and major-only removals | Publish a real deprecation lifecycle, not “we’ll figure it out later.” |
| Phoenix / Ecto / Plug | Changelog-led evolution with warnings and additive minors | Keep the contract doc + changelog as the truth, not scattered comments. |
| Rails | Breaking changes are paired with prior deprecations | Never surprise adopters with a `1.x` behavior break hidden in release notes. |
| Django | Deprecation timelines name the replacement and expected removal window | Every mailglass deprecation should name replacement and earliest removal version. |
| Anymail | Strong SemVer language, explicit support-drop notices, concrete version pin guidance | When support posture changes, say it directly and give adopters a pin/escape hatch. |
| Swoosh | Good test ergonomics and improved docs discoverability | Production adoption proof is not just runtime correctness; it is easy-to-trust docs and tests. |

## Footguns To Avoid

| Footgun | Why it is bad | Do instead |
|---------|---------------|-----------|
| Adding an API-diff dependency/toolchain | More maintenance, little leverage versus docs-driven tests | Build a small internal contract test around `Code.fetch_docs/1`. |
| Treating all public modules as stable by default | Freezes accidental surface forever | Explicitly whitelist the `1.x` stable surface. |
| Using `@doc false` on random functions in public modules | Hidden docs are still callable API in Elixir | Move internals into `@moduledoc false` modules. |
| Emitting runtime deprecation logs | Noisy, harder to test, non-idiomatic | Use compile-time `@deprecated` and docs metadata. |
| Promising optional-dependency behavior as fully stable | Explodes the matrix for a one-maintainer project | Promise stable core behavior; treat optional integrations as bounded extension seams. |
| Expanding support matrix now | Multiplies risk right before `v1.0` | Freeze the matrix and document it clearly. |
| Shipping `v1.0` without proof artifacts | “Stable” becomes marketing instead of engineering | Require upgrade smoke, tarball smoke, docs contract, and API contract in CI. |

## Explicit Non-Recommendations

- **Do not add** a new runtime compatibility layer, plugin system, or behavior abstraction solely for future-proofing.
- **Do not add** OpenAPI/JSON-schema style contract tooling; the public contract is Elixir API + guides, not HTTP.
- **Do not add** external changelog SaaS, doc-hosting replacements, or versioned-doc infra beyond HexDocs.
- **Do not add** more optional adapters/providers in this milestone.
- **Do not add** a formal LTS branch or backport policy for pre-`1.0` lines; for a one-maintainer library, that is promise inflation.
- **Do not add** automatic codemod machinery unless a real `1.x -> 2.0` break eventually forces it.
- **Do not change** the version floors in this milestone unless a dependency forces it for security or correctness.

## Cohesive Recommendation Set For mailglass

1. Keep the runtime stack exactly as it is.
2. Upgrade the docs stack, not the dependency stack: stability policy, deprecations, support matrix, and `v1.0` upgrade guide.
3. Add public API contract tests based on compiled docs and explicit allowlists for both `mailglass` and `mailglass_admin`.
4. Add a release-contract CI gate that proves docs quality, tarball contents, upgrade path, and stable-surface discipline.
5. Promise a conservative `1.x` policy: additive minors, compile-time deprecations, no removals before `2.0`.
6. Explicitly keep optional integrations, internal modules, and future inbound work outside the `v1.0` stability promise.

This is the most idiomatic Elixir/Phoenix direction and the best fit for mailglass’s stated values: principle of least surprise, strong architecture, maintainable scope, and production-trustworthy adoption.

## Sources

- Elixir compatibility and deprecations: https://hexdocs.pm/elixir/1.18.4/compatibility-and-deprecations.html
- Elixir writing documentation (`@since`, `@deprecated`, `@doc false`, `Code.fetch_docs/1`): https://hexdocs.pm/elixir/writing-documentation.html
- ExDoc `mix docs` grouping/extras behavior: https://hexdocs.pm/ex_doc/0.38.0/Mix.Tasks.Docs.html
- Hex `mix hex.build --unpack`: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html
- Hex `mix hex.publish`: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html
- Hex `mix hex.package diff`: https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html
- SemVer 2.0.0: https://semver.org/
- Rails maintenance policy: https://guides.rubyonrails.org/maintenance_policy.html
- Django release process and deprecation policy: https://docs.djangoproject.com/en/4.2/internals/release-process/
- Django deprecation timeline: https://docs.djangoproject.com/en/dev/internals/deprecation/
- Swoosh testing docs: https://hexdocs.pm/swoosh/Swoosh.html
- Swoosh sandbox adapter docs: https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html
- Swoosh changelog: https://hexdocs.pm/swoosh/changelog.html
- Anymail SemVer/release notes: https://anymail.dev/en/v2.2/release_notes/
- Anymail changelog and deprecation examples: https://anymail.dev/en/latest/changelog/
- Anymail SendGrid support-status warning example: https://anymail.dev/en/stable/esps/sendgrid/
