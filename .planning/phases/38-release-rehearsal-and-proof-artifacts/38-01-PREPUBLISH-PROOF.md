# Phase 38 — Prepublish Proof Bundle

Proof date: 2026-05-06  
Phase requirement: `RELS-03`  
Backing exports: `.planning/publish/mailglass-publish-summary.json`, `.planning/publish/mailglass_admin-publish-summary.json`

## Tarball/package truth

- Canonical exported truth lives in `.planning/publish/mailglass-publish-summary.json` and `.planning/publish/mailglass_admin-publish-summary.json`.
- Those files are written by `mix mailglass.publish.check` from the existing tarball build, allowlist, required-file, metadata, dependency, and linked-version checks in `lib/mix/tasks/mailglass.publish.check.ex`.
- Current exported package facts:
  - `mailglass`: `version` `0.3.2`, `manifest_version` `0.3.2`, `tarball_size` `994471`, `expected_file` `.planning/publish/mailglass-files.expected`
  - `mailglass_admin`: `version` `0.3.2`, `manifest_version` `0.3.2`, `tarball_size` `366742`, `expected_file` `.planning/publish/mailglass_admin-files.expected`
- The allowlist sources stay committed in `.planning/publish/mailglass-files.expected` and `.planning/publish/mailglass_admin-files.expected`; Phase 38 refreshed them to match the current shipped tarball surface instead of leaving older package truth in place.
- Source-of-truth files for this section:
  - `mix.exs`
  - `mailglass_admin/mix.exs`
  - `.planning/publish/mailglass-files.expected`
  - `.planning/publish/mailglass_admin-files.expected`
  - `lib/mix/tasks/mailglass.publish.check.ex`

## HexDocs input truth

- The proof exports snapshot the exact docs inputs that define what HexDocs will publish:
  - `extras`
  - `groups_for_extras`
  - `source_url`
  - `source_ref` or `source_ref_pattern`
- `mailglass-publish-summary.json` captures the core package Tier 1 docs inputs from `mix.exs`.
- `mailglass_admin-publish-summary.json` captures the admin package Tier 1 docs inputs from `mailglass_admin/mix.exs`.
- Current canonical docs-input sources:
  - `mix.exs`
  - `mailglass_admin/mix.exs`
  - `.planning/publish/mailglass-publish-summary.json`
  - `.planning/publish/mailglass_admin-publish-summary.json`
- This bundle is the human-readable index for those fields; the JSON exports remain the auditable machine-readable proof.

## Sibling release truth

- `.release-please-manifest.json` remains the canonical linked-version source for both packages.
- The exports record the current linked release line as:
  - `mailglass`: `0.3.2`
  - `mailglass_admin`: `0.3.2`
- `mailglass_admin-publish-summary.json` also records the exact publish-mode sibling pin under `mailglass_admin_publish_pin`.
- Current pin truth:
  - `mailglass_admin_publish_pin`: `== 0.3.2`
- Source-of-truth files for sibling release behavior:
  - `.release-please-manifest.json`
  - `mailglass_admin/mix.exs`
  - `.github/workflows/release-please.yml`

## Release rehearsal evidence

- This file is the authoritative Phase 38 proof bundle.
- Install and upgrade rehearsal detail now lives in `38-02-REHEARSAL-EVIDENCE.md`; this section keeps the authoritative highlights.
- Current repo-local rehearsal highlights:
  - Install rehearsal: `actionlint .github/workflows/post-publish-smoke.yml` passed and the canonical fresh-host mirror remained `mix phx.new sandbox --module Sandbox --app sandbox --no-ecto --no-mailer --install`.
  - First-send workflow proof: `mix test test/mailglass/install/install_first_send_smoke_test.exs --warnings-as-errors` passed, keeping `guides/getting-started.md` aligned with the `mix ecto.migrate` + `Mailglass.deliver()` path.
  - Upgrade rehearsal: `mix verify.docs.migration` and `mix verify.stability_contract` both passed against the canonical `guides/upgrading-to-v1_0.md` path.
  - Docs-as-errors proof: `mix docs --warnings-as-errors` and `cd mailglass_admin && mix docs --warnings-as-errors` both passed.
- Release-record highlights from `38-03-RELEASE-RECORD.md`:
  - `Release type`: `rehearsal`
  - `Tag`: `mailglass-v0.3.2 (rehearsal target)`
  - `Publish workflow run URL`: `not run`
  - `Post-publish smoke run URL`: `not run`
  - `Fallback path used`: `not run`
  - `Branch-protection verification result`: accepted external closeout debt
- Supporting release-flow sources already tied to this bundle:
  - `.github/workflows/publish-hex.yml`
  - `.github/workflows/post-publish-smoke.yml`
  - `MAINTAINING.md`
