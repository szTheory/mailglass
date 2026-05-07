# Phase 38 — Release Rehearsal Evidence

Date: 2026-05-06  
Scope: Canonical install rehearsal, secondary first-send proof, and strict `0.3.x -> 1.0` upgrade rehearsal.  
Workflow run URL: not run (repo-local rehearsal only)

## Install rehearsal proof

- Canonical workflow file: `.github/workflows/post-publish-smoke.yml`
- Canonical fresh-host command: `mix phx.new sandbox --module Sandbox --app sandbox --no-ecto --no-mailer --install`
- Command outcome: `actionlint .github/workflows/post-publish-smoke.yml` passed.
- Command outcome: `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors` passed.
- Command outcome: `mix test test/mailglass/install/install_first_send_smoke_test.exs --warnings-as-errors` passed.
- Fast-lane truth preserved:
  - release-window smoke still verifies `config :swoosh, :api_client, false`
  - release-window smoke still boots the endpoint and requires `GET /dev/mail/` `HTTP 200`
- First-send workflow proof:
  - guide path: `guides/getting-started.md`
  - supporting test: `test/mailglass/install/install_first_send_smoke_test.exs`
  - proof result: guide retains `mix ecto.migrate`, `subject("Welcome")`, and `Mailglass.deliver()` and the local fake-adapter send path executed successfully

## Upgrade rehearsal proof

- Version pair: latest supported `0.3.x -> 1.0`
- Canonical guide: `guides/upgrading-to-v1_0.md`
- Supporting subordinate references:
  - `guides/upgrading-from-v0_1.md`
  - `guides/migration-from-swoosh.md`
- Command outcome: `mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` passed.
- Command outcome: `mix verify.docs.migration` passed.
- Command outcome: `mix verify.stability_contract` passed.
- Command outcome: `mix docs --warnings-as-errors` passed.
- Admin docs build result: `cd mailglass_admin && mix docs --warnings-as-errors` passed.
- Strict-lane notes:
  - `guides/upgrading-to-v1_0.md` now names `mix verify.docs.migration` and `mix verify.stability_contract` as the canonical proof commands.
  - `Mailglass.Message.new/2` remains explicitly documented as release-blocking for strict adopters because it still emits a real deprecation warning under `--warnings-as-errors`.

## Evidence summary

- Install rehearsal stayed recommendation-first: the no-Ecto published-package lane remains the canonical release-window gate.
- The deeper Ecto-backed first-send lane is present as supporting executable proof, not as a replacement for the fast smoke.
- The latest `0.3.x -> 1.0` upgrade path now has one authoritative guide plus repo-local strict verification evidence.
