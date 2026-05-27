# Technology Stack

**Project:** mailglass  
**Researched:** 2026-05-27  
**Milestone scope:** v1.3 Adopter Trust Proof (maintained Phoenix reference host app + clean-baseline CI journey)

## Recommendation

For v1.3, keep the shipped `mailglass`/`mailglass_admin`/`mailglass_inbound`
runtime stack intact and add a thin, maintained **reference host app proof
layer** around it.

This milestone should add:

1. one committed Phoenix reference host app artifact (maintained, not throwaway),
2. one required CI lane proving the full adopter journey in-repo, and
3. one clean-baseline CI lane proving the same journey from a fresh host app.

This milestone should **not** add new transport classes, broad provider
expansion, or product-like UI scope.

## Keep As-Is (No New Foundational Research)

- Elixir floor: `~> 1.18`
- OTP floor: `27+`
- Phoenix stack: `phoenix ~> 1.8`, `phoenix_live_view ~> 1.1`, `plug ~> 1.18`
- Persistence: Postgres-only (`ecto_sql ~> 3.13`, `postgrex ~> 0.22`)
- Core mail layer: `swoosh ~> 1.25`
- Optional dependency gateway policy remains unchanged (`Mailglass.OptionalDeps.*`)
- CI realism posture remains: required lanes for deterministic proof, advisory
  lanes for broader ecosystem drift detection

These are already shipped and validated; v1.3 work is integration proof, not
stack re-foundation.

## v1.3 Stack Additions and Changes (New Work Only)

| Tool / Library / Service | Version awareness | Why it matters | Integration points |
|---|---|---|---|
| Phoenix reference host app (committed artifact in repo) | Generate with Phoenix 1.8 toolchain; keep Elixir/OTP floors aligned with core | Creates a durable, inspectable adopter-proof app instead of fixture snapshots only | New `examples/` (or equivalent) app wired with `mailglass`, `mailglass_admin`, and optional `mailglass_inbound` seams |
| `phx_new` archive in CI for clean-baseline generation | Pin to vetted `1.8.x` patch in required lane; run latest `1.8.x` in advisory lane | Proves "fresh adopter can install and run" against current Phoenix generator behavior | Clean-baseline workflow step: generate app -> add deps -> run install -> execute proof scenario |
| `mix mailglass.install` as canonical integration entrypoint | Use shipped installer; no forked install script | Keeps trust proof coupled to real adoption path and catches installer regressions | Both committed reference app refresh process and clean-baseline lane run installer directly |
| Outbound send proof via `Mailglass.Adapters.Fake` + `config :swoosh, :api_client, false` | No new provider SDK versions required | Proves send path and event persistence without external network/provider flakiness | Reference scenario triggers send and asserts persisted delivery/event behavior locally |
| Webhook ingest proof via signed fixture payloads (single representative provider path) | Reuse existing provider verifier stack; no provider matrix expansion in v1.3 | Demonstrates ingest + normalization + troubleshooting loop deterministically | Scenario posts signed webhook payload to host app webhook endpoint and verifies ledger/admin visibility |
| Postgres service container in CI (`postgres:16-alpine`) | Match existing CI service version to avoid environment skew | Full trust path (send + webhook + operator troubleshooting) needs real DB-backed state | Required CI lane boots Postgres, runs migrations, executes end-to-end scenario |
| ExUnit + ConnTest/LiveView assertions for operator troubleshooting proof | Stay on current Phoenix testing stack; do not introduce browser-E2E requirement | Gives stable operator-proof checks without adding Node/browser flake to required lane | Scenario asserts key operator surfaces (events timeline/evidence/replayability) through server-side tests |
| Dedicated trust-proof verify alias (e.g. `mix verify.reference_host`) | Keep preferred env explicit (`:test`) like existing `verify.*` aliases | Makes the milestone proof repeatable locally and in CI with one command | Root mix aliases + CI job invoke single trust-proof gate |

## CI Shape for Trust Proof

### Required lane (new)

Add one required CI job that proves:

1. install (`mix mailglass.install`)
2. preview route boots
3. send persists evidence
4. webhook ingest appends normalized event(s)
5. operator troubleshooting surface can inspect that evidence

Use a real Postgres service container and deterministic fixtures; do not call
external provider APIs.

### Clean-baseline lane (new or expanded from existing smoke)

Keep the existing "fresh host" posture, but expand from preview-only smoke into
the full trust journey. The lane should still generate a brand-new Phoenix app
instead of relying only on committed app files.

### Advisory lane (optional but recommended)

Run the same clean-baseline flow on a schedule with latest compatible generator
patches to detect ecosystem drift early without blocking every PR.

## Version and Currentness Verification Strategy

Use a lightweight, explicit verification loop so stack guidance stays current:

1. **Milestone-open snapshot:** record current versions for Phoenix stack,
   `phx_new`, Elixir/OTP, and CI action SHAs.
2. **Required-lane pinning:** keep required trust-proof lane pinned to vetted
   Elixir/OTP and `phx_new` patch versions for deterministic gating.
3. **Advisory drift checks:** schedule a non-blocking run using latest allowed
   patch versions in the same major/minor compatibility window.
4. **Dependency audits:** run `mix hex.outdated` and `mix hex.audit` on cadence;
   promote upgrades only when trust-proof lanes stay green.
5. **Workflow pin hygiene:** continue SHA-pinning third-party GitHub Actions and
   refresh pins deliberately (not ad hoc) with rerun evidence.

## What Not To Add In v1.3

- No new foundational runtime dependencies in core packages.
- No transport-class expansion (`gen_smtp` listener work stays out of this milestone).
- No broad provider matrix expansion for reference proof (one representative
  webhook ingest path is enough).
- No Cloudflare forwarding slice in this milestone.
- No synthetic inbound composer/devtool expansion here.
- No second-product UI ambition for the reference app; keep it a proof host, not
  a polished demo app.
- No browser/Playwright-only required gate for v1.3 trust proof (keep required
  lane server-side deterministic; browser checks can remain advisory).

## Maintainer Sustainability Notes

- Keep the reference host app thin and contract-oriented so it remains
  maintainable by one maintainer.
- Prefer fixture-driven deterministic tests over live-provider integration for
  required CI.
- Keep "API contract truth" in core docs and contract tests; reference app is
  usage/operations proof, not a replacement contract source.

## Sources

- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/research/milestone-candidates/06-adopter-trust-proof.md`
- `.planning/research/milestone-candidates/SYNTHESIS.md`
- `.planning/threads/next-milestone-adopter-trust-proof.md`
- `.github/workflows/ci.yml`
- `.github/workflows/post-publish-smoke.yml`
- `mix.exs`
- `mailglass_admin/mix.exs`
- `mailglass_inbound/mix.exs`
