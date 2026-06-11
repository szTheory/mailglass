# Phase 71: Inbound Release Truth Preflight - Patterns

**Mapped:** 2026-06-02
**Status:** Ready for planning

## Purpose

Map the files Phase 71 is likely to touch to the closest existing codebase
patterns so execution can stay narrow and repo-native.

## Existing Pattern: Release Truth Tests

**Primary analog:** `test/mailglass/stability_contract_test.exs`

Current pattern:

- Read release workflow/config/source files with `File.read!/1`.
- Assert release topology with focused string or regex checks.
- Keep future ceremonies resilient by checking SemVer shape where the assertion
  is a long-lived topology contract.
- Assert tracked publish-summary snapshots exist and expose required keys.

Phase 71 adaptation:

- Add a focused current-release-truth test that ties exact inbound `1.0.0` truth
  to the current v1.6 preflight, preferably by comparing values across
  `.release-please-manifest.json`, `mailglass_inbound/mix.exs`,
  `mailglass_inbound/CHANGELOG.md`, and
  `.planning/publish/mailglass_inbound-publish-summary.json`.
- Keep topology assertions ceremony-resilient where future releases should not
  require test rewrites.

## Existing Pattern: Docs Contract Tests

**Primary analog:** `test/mailglass/docs_contract_test.exs`

Current pattern:

- Root README and maintainer-runbook claims are pinned by small ExUnit tests.
- Required-vs-advisory proof boundaries are asserted as exact wording tokens in
  `MAINTAINING.md`.
- The tests prefer durable concepts and canonical file references over long
  prose snapshots.

Phase 71 adaptation:

- If `README.md` or `MAINTAINING.md` changes, update tests in the same file.
- Pin only Phase 71 blockers: inbound `1.0` source/package truth and
  required-vs-advisory release-proof boundary.
- Leave broad stale-claim guard expansion to Phase 72.

## Existing Pattern: Package Preflight Task

**Primary analog:** `lib/mix/tasks/mailglass.publish.check.ex`

Current pattern:

- Use `--package` selector for sibling-package-specific preflight.
- Build with `MIX_PUBLISH=true` for sibling packages.
- Compare unpacked package files to `.planning/publish/*-files.expected`.
- Verify metadata, manifest parity, dependency shape, prod dependency
  resolution, isolated compile, and advisory audit/outdated output.
- Write `.planning/publish/*-publish-summary.json` as tracked release proof.

Phase 71 adaptation:

- Prefer running this task as the release-truth proof lane.
- Do not duplicate tarball/package logic in a new task.
- Add assertions around summary contents only if REL-01 truth is not already
  directly pinned.

## Existing Pattern: Release Workflow Topology

**Primary analogs:**

- `.github/workflows/release-please.yml`
- `.github/workflows/publish-hex.yml`
- `release-please-config.json`

Current pattern:

- `mailglass` and `mailglass_admin` are linked.
- `mailglass_inbound` has its own release-please package entry and is not in
  the linked-version plugin.
- Release-please sync step updates inbound's `mailglass` dep pin from the core
  manifest version and inbound README pin from inbound's own manifest version.
- Publish workflow supports `package=mailglass_inbound` and has a dedicated
  `publish-inbound` job.

Phase 71 adaptation:

- Preserve independent inbound release topology.
- Test the topology if it is not already tested exactly enough.
- Avoid forcing core/admin release work into Phase 71.

## Existing Pattern: Phase 66 Release Evidence

**Primary analogs:**

- `.planning/milestones/v1.4-phases/66-release-position-decision/66-01-SUMMARY.md`
- `mailglass_inbound/CHANGELOG.md`

Current pattern:

- Record fresh command evidence before making release-position claims.
- Phrase release notes as operational evidence, not marketing.
- Route canonical compatibility truth to `mailglass_inbound/docs/api_stability.md`
  and `guides/compatibility-and-deprecations.md`.

Phase 71 adaptation:

- Treat Phase 66 as the source of the `1.0.0` decision.
- Phase 71 should prove current truth agrees with that decision and classify
  stale claims, not reopen the release-position decision.

## Likely Write Set

Expected high-confidence write candidates:

- `test/mailglass/stability_contract_test.exs`
- `test/mailglass/docs_contract_test.exs`
- `README.md`
- `MAINTAINING.md`
- `.planning/publish/mailglass_inbound-publish-summary.json` only if refreshed
  by `mix mailglass.publish.check --package mailglass_inbound`

Conditional / likely deferred:

- `reference/host_app/mix.exs` and `reference/demo_app/mix.exs`: stale published
  Hex pins are real, but updating to `~> 1.0` before inbound is published can
  break Hex-mode smoke. Prefer Phase 73 unless Phase 71 adds an explicit
  source-preparation reason.
- `guides/compatibility-and-deprecations.md`: known `0.x` horizon drift, but
  Phase 72 owns broad DOC-01/DOC-02 contract docs and stale-claim guards.
- `mailglass_inbound/docs/*`: only if a direct REL-01/PROOF-01 contradiction is
  discovered during execution.

## Verification Pattern

Use focused verification matched to touched surfaces:

- Always: `mix mailglass.publish.check --package mailglass_inbound`
- Always: `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors`
- If root README or `MAINTAINING.md` changes:
  `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors`
- If inbound docs change:
  `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`

