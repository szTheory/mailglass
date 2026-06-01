# Phase 67: Demo App Foundation - Research

**Date:** 2026-06-01
**Status:** Complete

## Research Question

What needs to be known to plan Phase 67 well?

Phase 67 is not a blank-slate demo build. `reference/demo_app` already exists
with a Phoenix app, Repo, Endpoint, Router, migrations, deterministic seed data,
Compose stack, Dockerfile, README, and a starter Playwright suite. The plan
should harden the foundation and make the proof paths explicit rather than
recreating the app.

## Current Release Truth

Checked with `mix hex.info` on 2026-06-01:

- `mailglass`: latest config line is `{:mailglass, "~> 1.3"}` with recent
  release `1.3.0` on 2026-05-29.
- `mailglass_admin`: latest config line is `{:mailglass_admin, "~> 1.3"}` with
  recent release `1.3.0` on 2026-05-29.
- `mailglass_inbound`: latest config line is `{:mailglass_inbound, "~> 0.3.0"}`
  with recent release `0.3.0` on 2026-05-29.

Implication: the current `reference/demo_app/mix.exs` Hex-mode constraints are
directionally correct, but the inbound constraint should be tightened from
`~> 0.3` to `~> 0.3.0` unless the release line changes before execution.

## Existing Foundation

- `reference/demo_app/mix.exs` already implements dual dependency mode through
  `MAILGLASS_DEMO_DEPS=hex`, using local path dependencies by default.
- The Mix aliases already include `setup`, `ecto.setup`, `ecto.reset`,
  `demo.reset`, and `demo.e2e`.
- `reference/demo_app/config/config.exs` wires Mailglass, MailglassAdmin, and
  MailglassInbound through public configuration seams.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` mounts `/dev/mail`,
  `/ops/mail`, `/ops/mail/inbound`, and representative inbound provider routes.
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` already truncates seeded
  tables with `RESTART IDENTITY CASCADE` and reseeds outbound, inbound,
  suppression, evidence, and replay data.
- `compose.demo.yml` already has the right three-service shape: Postgres, demo
  app, and browser evidence runner. It also already preserves cache-aware
  volumes for Mix, Hex, npm, Playwright browsers, and package deps/build dirs.

## Gaps To Plan

### Boundary and dependency proof

`reference/host_app` must remain the narrow trust-proof app. The plan should add
an explicit guard that Phase 67 changes do not move rich-demo behavior into
`reference/host_app` and do not widen Mailglass public API guarantees.

Hex mode is present but should be executable as a smoke proof. A focused
verification command should prove local mode and Hex mode independently.

### Compose readiness

`compose.demo.yml` currently waits for `demo_db` health before starting `demo`,
but `demo_e2e` waits only for `demo` `service_started`. Phase 67 should add a
real Phoenix readiness path and make browser evidence wait on `service_healthy`.

The evidence runner currently installs browser dependencies with
`npm --prefix assets install` and `npx playwright install chromium`. The plan
should switch to lockfile-respecting `npm ci` and make browser system
dependencies deterministic. The lowest-risk path is to install Playwright
browser dependencies in `reference/demo_app/Dockerfile` with the existing Debian
base and run `npx --prefix assets playwright install --with-deps chromium` from
the image or evidence command.

### Reset and evidence foundation

The demo has a POST reset form and `mix demo.reset`, but browser evidence needs
a deterministic reset path that does not depend on scraping CSRF form state. The
plan should add a demo-only reset path or scriptable command for the evidence
runner and make the destructive wording unmistakable.

Phase 70 will own complete browser evidence. Phase 67 should prepare stable
startup, reset, and artifact paths without treating demo DOM, selectors, routes,
or copy as stable public API.

## Validation Architecture

Phase 67 should validate with fast source assertions plus one focused runtime
proof:

- `mix test test/reference_host/scope_lock_contract_test.exs` to protect the
  host-app boundary.
- `mix cmd --cd reference/demo_app mix test` or a focused demo-app test file for
  `DemoData.reset!/0`, router mounts, and health/reset paths.
- `MAILGLASS_DEMO_DEPS=hex mix deps.get --only prod` in `reference/demo_app` to
  prove published-package mode resolves.
- `docker compose -f compose.demo.yml config` as a cheap Compose syntax proof.
- A focused `mix verify.phase67` alias or script that combines the fast proofs
  and can be reused before Phase 68 starts.

## Planning Recommendations

Create three plans:

1. Boundary and dependency-mode proof: tighten Hex constraints, add local/Hex
   smoke commands, and protect `reference/host_app`.
2. Compose readiness and deterministic browser dependency setup: add health
   route/check, switch evidence install to `npm ci`, and make `demo_e2e` wait on
   healthy demo service.
3. Reset and evidence-foundation proof: add scriptable deterministic reset,
   destructive wording, bounded artifact path/schema notes, and a reusable
   Phase 67 verification lane.

## RESEARCH COMPLETE
