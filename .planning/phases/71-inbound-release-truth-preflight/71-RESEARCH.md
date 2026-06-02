# Phase 71: Inbound Release Truth Preflight - Research

**Researched:** 2026-06-02
**Status:** Ready for planning
**Question:** What do I need to know to plan Phase 71 well?

## Executive Summary

Phase 71 should be a narrow release-truth preflight for REL-01 and PROOF-01.
The repo already has the strongest implementation seam: `mix
mailglass.publish.check --package mailglass_inbound`. That task builds and
unpacks the inbound tarball, compares the committed allowlist, checks required
files, verifies the changelog section, checks Mix metadata and manifest version
parity, enforces the `MIX_PUBLISH=true` `mailglass` dependency pin, verifies prod
dependency resolution, compiles the package in isolation, captures
`hex.audit`/`hex.outdated`, and writes the publish-summary snapshot.

The likely planning work is therefore not to invent a new verifier. It is to
tighten stale release-truth assertions and docs/runbook boundaries around the
existing verifier:

- Assert exact inbound `1.0.0` truth where Phase 71 needs exact truth, not just
  SemVer-shaped truth.
- Reconcile or classify stale inbound version claims in README/runbook/reference
  dependency pins.
- Keep provider-live and ecosystem checks advisory unless a release claim
  explicitly depends on them.
- Refresh/prove `.planning/publish/mailglass_inbound-publish-summary.json`
  through the existing publish-check lane.

## Current Source And Package Truth

Confirmed current truth:

- `.release-please-manifest.json` sets `"mailglass_inbound": "1.0.0"`.
- `mailglass_inbound/mix.exs` sets `@version "1.0.0"`.
- `mailglass_inbound/mix.exs` uses `MIX_PUBLISH=true` to switch from path dep to
  `{:mailglass, "== 1.3.0"}`.
- `release-please-config.json` links only `mailglass` and `mailglass_admin` in
  the `mailglass-sibling-group`; `mailglass_inbound` is an independent package
  release line.
- `.planning/publish/mailglass_inbound-publish-summary.json` records
  `"version": "1.0.0"`, `"manifest_version": "1.0.0"`,
  `"mailglass_inbound_publish_pin": "== 1.3.0"`, and linked versions
  `{mailglass: 1.3.0, mailglass_admin: 1.3.0, mailglass_inbound: 1.0.0}`.
- `.planning/publish/mailglass_inbound-files.expected` matches the intended
  inbound package file list including docs, migrations, library files, and
  package-local Mix tasks.
- `mailglass_inbound/README.md` and `mailglass_inbound/docs/inbound-install.md`
  already use `{:mailglass_inbound, "~> 1.0"}`.

Known stale or potentially Phase 71-relevant contradictions:

- Root `README.md` still describes `mailglass_inbound` as `v0.5+`, says it is
  outside the `v1.x` stability promise for the milestone, and lists package
  status as `v0.5+`.
- `MAINTAINING.md` release smoke example still says to add
  `{:mailglass_inbound, "~> 0.3"}`.
- `MAINTAINING.md` fallback example says to dispatch with `mailglass-v1.0.0`;
  Phase 71 should decide whether this is a stale example needing inbound-aware
  wording now or Phase 73 release-record scope.
- `reference/host_app/mix.exs` still pins `{:mailglass_inbound, "~> 0.3"}`.
- `reference/demo_app/mix.exs` still uses `{:mailglass_inbound, "~> 0.3.0"}` in
  published Hex mode.
- `reference/host_app` and `reference/demo_app` lockfiles currently resolve
  published `mailglass_inbound` `0.3.0`; because inbound `1.0.0` is not yet
  published, lockfile updates are likely Phase 73 post-publish smoke evidence,
  not Phase 71 source-truth work.
- `guides/compatibility-and-deprecations.md` still contains `Through
  mailglass_inbound 0.x` rows. Phase 72 owns broader DOC-01/DOC-02 stale-claim
  guard work, but Phase 71 may need to classify this explicitly as non-blocking
  unless a release-truth check depends on it.

## Existing Verification Seams

### `lib/mix/tasks/mailglass.publish.check.ex`

This is the primary preflight lane. Relevant behaviors already exist:

- `--package mailglass_inbound` selects only inbound.
- `load_package_context/1` reads the package `mix.exs`, module attributes,
  `.release-please-manifest.json`, root version, expected allowlist path, and
  publish-summary path.
- `verify_metadata/1` fails if package version does not match manifest version.
- `verify_deps/1` and `verify_linked_constraint/1` fail if a sibling package
  does not publish with an exact `mailglass` version matching root `@version`.
- `build_tarball/1` runs `mix hex.build --unpack` with `MIX_PUBLISH=true` for
  sibling packages.
- `verify_allowlist/1` compares actual unpacked tarball files against
  `.planning/publish/mailglass_inbound-files.expected`.
- `verify_required_files/1` checks core required package artifacts and
  package-specific required docs.
- `verify_prod_deps/1` validates prod dependency resolution.
- `verify_compile/1` compiles the unpacked tarball in isolation.
- `write_summary/1` writes the tracked publish summary consumed by release
  contract tests.

Planning implication: add only targeted assertions around exact Phase 71 truth
or stale runbook/docs evidence that the existing lane does not already pin.

### `test/mailglass/stability_contract_test.exs`

The existing root release automation test is intentionally ceremony-agnostic:

- It asserts the inbound manifest entry exists with any SemVer-shaped value.
- It asserts inbound `@version` and the `MIX_PUBLISH=true` `mailglass` dep are
  SemVer-shaped, not exact `1.0.0` / `1.3.0`.
- It asserts the inbound publish summary has a `"mailglass_inbound"` key with
  any SemVer-shaped value.

Planning implication: Phase 71 should probably add a focused test or update this
test to assert the current v1.6 truth exactly enough for REL-01, without making
future release ceremonies brittle. A good pattern is a phase-specific
`describe` block or helper that ties exact assertions to the current manifest
and summary rather than hard-coding broad forever-contract claims.

### `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`

This already covers many inbound package docs contracts. It does not appear to
own root README package-table truth, maintainer release smoke pins, or
reference app published Hex pins. Phase 72 owns broader docs stale-claim guards,
so Phase 71 should avoid expanding this test beyond REL-01/PROOF-01 blockers.

### `test/mailglass/docs_contract_test.exs`

This already pins the required-vs-advisory verification contract in
`MAINTAINING.md`:

- Required branch-protection contexts are listed.
- Advisory lanes include `Core Full Suite Advisory`, `Provider Compatibility
  Advisory`, and `Provider Live Advisory`.
- `Provider Live Advisory` is explicitly not a merge blocker.

Planning implication: Phase 71 may only need to refine release-runbook wording
or add a small assertion for inbound-specific release proof boundaries if the
current prose can be misread as provider-live being release-blocking.

## Release Workflow Topology

### `release-please-config.json`

The topology is already correct for Phase 71:

- `mailglass` (`.`) and `mailglass_admin` are linked.
- `mailglass_inbound` is not in the linked-version plugin.

### `.github/workflows/release-please.yml`

The release-please sync step already:

- Reads the core version from `.release-please-manifest.json` `["."]`.
- Syncs `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs` `mailglass`
  dep pins to the core version.
- Reads the independent inbound version from
  `.release-please-manifest.json["mailglass_inbound"]`.
- Syncs `mailglass_inbound/README.md` install pin to inbound major.minor.
- Syncs root/admin README pins to the core major.minor.

Planning implication: Phase 71 should not force a core/admin release or rewrite
release-please topology. It may add test coverage that the sync step still
mentions inbound separately and reads inbound's own manifest entry for README
pin sync.

### `.github/workflows/publish-hex.yml`

Relevant behavior:

- `workflow_dispatch` accepts package choices including `mailglass_inbound`.
- `prepublish-summary` runs `mix mailglass.publish.check --package
  mailglass_inbound` unless dispatch selected only core/admin.
- `publish-core` can be skipped for `package=mailglass_inbound`.
- `publish-inbound` is present later in the workflow and should be inspected by
  execution before editing, but topology comments already show admin waits on
  inbound and inbound does not require forcing admin.

Planning implication: Phase 71 should avoid changing publish ceremony behavior
unless a direct contradiction is found. Phase 73 owns run/record evidence.

## Required Versus Advisory Boundary

Current `MAINTAINING.md` already distinguishes:

- Required branch-protection contexts.
- Additional release trust evidence.
- Advisory checks including provider live.
- Provider-live canary is cron/`workflow_dispatch`, not a merge blocker.

Phase 71 should keep this boundary:

- Required proof: repo source/package truth, `mix mailglass.publish.check
  --package mailglass_inbound`, CI/tag truth, publish workflow mechanics, Hex
  and HexDocs evidence once Phase 73 runs, and post-publish smoke/install proof.
- Advisory proof: provider-live checks, ecosystem canaries, Elixir Forum post,
  and any checks not tied to a specific release claim.

Planning implication: If wording changes are needed, make them in
`MAINTAINING.md` and back them with existing or focused docs-contract tests.

## Recommended Plan Shape

One focused plan is likely enough:

1. Add/adjust tests for exact inbound release-truth preflight:
   - manifest/source/summary all agree on `mailglass_inbound` `1.0.0`;
   - inbound `MIX_PUBLISH=true` dependency pin agrees with core `1.3.0`;
   - release-please config keeps inbound independent from the linked
     core/admin group;
   - release-please sync step updates inbound from its own manifest entry;
   - publish summary records allowlist/required files and publish pin truth.
2. Fix only Phase 71-blocking stale truth:
   - root README package-status wording if it directly contradicts current
     `1.0.0` source truth;
   - maintainer smoke dependency example from `~> 0.3` to current inbound
     `~> 1.0`;
   - possibly published Hex mode pins in reference apps if this phase chooses
     source-preparation truth over post-publish lockfile truth. Do not update
     lockfiles to unpublished inbound `1.0.0` unless the execution plan proves
     that published Hex mode still resolves.
3. Preserve broader stale-claim guard work for Phase 72:
   - compatibility rows saying `Through mailglass_inbound 0.x`;
   - broad public wording around contract routing;
   - executable stale-claim guards for all docs surfaces.
4. Run deterministic verification:
   - `mix mailglass.publish.check --package mailglass_inbound`;
   - `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors`;
   - `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` if
     `MAINTAINING.md` or root README assertions change;
   - `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`
     only if inbound package docs change.

## Risks And Constraints

- `mix mailglass.publish.check --package mailglass_inbound` is the heavyweight
  but correct proof lane. It can touch
  `.planning/publish/mailglass_inbound-publish-summary.json` when package truth
  changes; the execution plan should require reviewing and committing any
  intentional diff.
- Updating reference app published Hex pins to `~> 1.0` before the actual Hex
  publish may make published Hex smoke mode unresolvable. Prefer documenting
  this as a Phase 73 post-publish update unless the plan can prove no current
  verification lane uses those pins before publish.
- Root README broad wording overlaps with Phase 72. Phase 71 should only fix
  direct contradictions needed for REL-01 preflight truth.
- Do not run live provider checks or ecosystem canaries as release blockers.
- Do not force a core/admin release. The release topology deliberately keeps
  inbound independent.

## Files To Prioritize During Planning

- `test/mailglass/stability_contract_test.exs`
- `test/mailglass/docs_contract_test.exs`
- `lib/mix/tasks/mailglass.publish.check.ex`
- `.release-please-manifest.json`
- `release-please-config.json`
- `.github/workflows/release-please.yml`
- `.github/workflows/publish-hex.yml`
- `mailglass_inbound/mix.exs`
- `mailglass_inbound/CHANGELOG.md`
- `mailglass_inbound/README.md`
- `.planning/publish/mailglass_inbound-files.expected`
- `.planning/publish/mailglass_inbound-publish-summary.json`
- `README.md`
- `MAINTAINING.md`
- `reference/host_app/mix.exs`
- `reference/demo_app/mix.exs`

## Research Complete

Planning can proceed. The planner should create a tightly scoped executable plan
that reinforces the existing publish-check lane instead of replacing it.

