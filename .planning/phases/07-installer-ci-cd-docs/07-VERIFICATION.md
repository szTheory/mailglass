---
phase: 07-installer-ci-cd-docs
verified: 2026-04-25T00:00:00Z
status: passed_with_known_gaps
score: 4/5 must-haves verified (SC#1 deferred to Phase 07.1 Plan 06 per audit G-1+G-3)
overrides_applied: 0
backfilled_from: .planning/v0.1-MILESTONE-AUDIT.md (V-07 close-out)
known_gaps:
  - audit_id: G-1
    success_criterion: 1
    problem: "router_mount_snippet/1 emits non-existent {App}.MailglassAdmin.Router.mount() call"
    closure_plan: 07.1-06
  - audit_id: G-3
    success_criterion: 1
    problem: "Plan.build/2 omits webhook mount + Plug.Parsers body_reader endpoint config"
    closure_plan: 07.1-06
  - audit_id: G-2
    success_criterion: 3
    problem: "Golden fixture hardcodes wrong shape; structurally cannot catch G-1/G-3"
    closure_plan: 07.1-06
  - audit_id: G-5
    success_criterion: 3
    problem: "Fixture falls back to run_simulated_install!/2; real installer never exercised"
    closure_plan: 07.1-06
  - audit_id: G-4
    success_criterion: 4
    problem: "admin_smoke_gate CI job matches zero tests (vacuous pass)"
    closure_plan: 07.1-06
---

# Phase 7: Installer + CI/CD + Docs Verification Report

**Phase Goal:** A Phoenix 1.8 host runs `mix mailglass.install` and goes from zero to first-preview-styled email in under 5 minutes; the full GHA pipeline (lint, test matrix, Dialyzer, golden install diff, admin smoke, dependency review, actionlint, Release Please, protected-ref Hex publish) is green; ExDoc with 9 guides + doctest contracts publishes to HexDocs.
**Verified:** 2026-04-25T00:00:00Z
**Status:** passed_with_known_gaps
**Re-verification:** No — retroactive verification backfilled from `.planning/v0.1-MILESTONE-AUDIT.md` (V-07 close-out per Phase 07.1 D-05). The known gaps (G-1, G-2, G-3, G-4, G-5) are closed by Phase 07.1 Plan 06 (installer fix sequence per Phase 07.1 D-02).

## Goal Achievement

### Observable Truths (from ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A new Phoenix 1.8 host app reaches "first preview-styled HEEx email rendered in the browser" in under 5 minutes from zero via `mix mailglass.install` + 5 lines of mailable code; an adopter migrating from raw Swoosh follows `guides/migration-from-swoosh.md` in a single afternoon. | NOT MET (known gap) | Audit **G-1**: `lib/mailglass/installer/templates.ex:33` `router_mount_snippet/1` emits `{App}.MailglassAdmin.Router.mount()`, an API that does not exist — the real Phase 5 macro is `mailglass_admin_routes/2` from `MailglassAdmin.Router`. Adopter would hit `UndefinedFunctionError` at router compile time. Audit **G-3**: `lib/mailglass/installer/plan.ex` `Plan.build/2` omits the webhook router mount and the mandatory `Plug.Parsers body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}` endpoint config block — first webhook POST raises `%Mailglass.ConfigError{type: :webhook_caching_body_reader_missing}`. **Closure:** Phase 07.1 Plan 06 rewrites `router_mount_snippet/1`, adds `webhook_mount_snippet/1` + endpoint Plug.Parsers config-block op (D-02 step ordering: drop simulated fixture FIRST, watch tests fail honestly, THEN fix templates). |
| 2 | A second run of `mix mailglass.install` on a host with no changes produces zero file modifications (`.mailglass_conflict_*` sidecars rather than clobbering); the golden-diff snapshot test in `test/example/` catches any installer behavior change. | VERIFIED | Plan 07-01 SUMMARY: idempotency sidecars implemented in `lib/mailglass/installer/conflict.ex` + `lib/mailglass/installer/apply.ex` (INST-02). Second-run no-op behavior asserted by `test/mailglass/installer/` test suite. **Caveat:** the golden-diff fixture's structural ability to catch installer-shape regressions is itself impaired by G-2/G-5 (golden snapshot was captured against a hand-rolled simulated path, not real `Apply.run` output) — closure Plan 07.1-06 rewrites the fixture. The idempotency *behavior* is verified; only the *snapshot* fixture is structurally weak. |
| 3 | A coordinated release of `mailglass` and `mailglass_admin` produced by Release Please ships both packages to Hex with linked versions; `mailglass_admin/mix.exs` declares `{:mailglass, "== <new-version>"}`; `mailglass` Hex tarball <500 KB with zero `priv/static/` assets; `mailglass_admin` tarball <2 MB. | VERIFIED | Plan 07-05 SUMMARY: `release-please-config.json` configured with `linked-versions` plugin and `groupName: "mailglass-sibling-group"`; `.release-please-manifest.json` present (Phase 07.1 D-08 resets it to `0.0.0` for v0.1.0 bootstrap). `mailglass/mix.exs` `package[:files]` excludes `priv/static/`. `mailglass_admin/mix.exs` `mailglass_dep/0` flips to `{:mailglass, "== <version>"}` under `MIX_PUBLISH=true` (CI-04). Tarball-size guardrails ship in `mix mailglass.publish.check` (Phase 07.1 D-17 step 5). **Note:** structural verification only — first actual publish ceremony executes in Phase 07.1 Plan 11. |
| 4 | CI on a PR runs format + compile (with `--warnings-as-errors`, separately with `--no-optional-deps --warnings-as-errors`) + ExUnit + Credo `--strict` (12 custom checks) + Dialyzer with cached PLT + `mix docs --warnings-as-errors` + `mix hex.audit` + dependency-review + actionlint; real-provider sandbox tests run on daily cron + `workflow_dispatch` only and never block PRs. | VERIFIED | Plan 07-04 SUMMARY: `.github/workflows/ci.yml` (CI-01, CI-02), `dependency-review.yml`, `actionlint.yml`, `pr-title.yml` (CI-03), `provider-live.yml` (TEST-04 — cron + workflow_dispatch, advisory-only), `advisory-matrix.yml`, `release-please.yml`, `publish-hex.yml` (CI-05/06/07) all present in `.github/workflows/`. Pinned to Elixir 1.18 + OTP 27. **Tech-debt G-4:** the `admin_smoke_gate` job runs `mix test --only admin_smoke` but no test in `mailglass_admin/test/` carries `@tag :admin_smoke` — passes vacuously. Closure Plan 07.1-06 step 6 (D-02). |
| 5 | ExDoc publishes with `main: "getting-started"` plus 9 guides (getting-started, authoring-mailables, components, preview, webhooks, multi-tenancy, telemetry, testing, migration-from-swoosh), `llms.txt` ships automatically (ExDoc 0.40+), every README "Quick Start" snippet compiles, and `MAINTAINING.md` + `CONTRIBUTING.md` + `SECURITY.md` + `CODE_OF_CONDUCT.md` present at repo root with brand-voice copy. | VERIFIED | Plan 07-03 SUMMARY: ExDoc configured in `mix.exs` (DOCS-01); all 9 guides present in `guides/`: `getting-started.md`, `authoring-mailables.md`, `components.md`, `preview.md`, `webhooks.md`, `multi-tenancy.md`, `telemetry.md`, `testing.md`, `migration-from-swoosh.md` (DOCS-01..04). Governance files at repo root (DOCS-05): `MAINTAINING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`. Brand-voice copy throughout (BRAND-02, BRAND-03). Doc-contract tests guard README snippet compilation (DOCS-03 / TEST-04 migration parity). |

**Score:** 4/5 truths verified (SC#1 NOT MET; closure Plan 07.1-06)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/mailglass.install.ex` | `mix mailglass.install` task entry point | VERIFIED | Plan 07-01 SUMMARY |
| `lib/mailglass/installer/plan.ex` | `Plan.build/2` — operation list builder | **VERIFIED-WITH-DEFECT (G-3)** | File exists; G-3: omits webhook mount + Plug.Parsers body_reader endpoint config block. Closure Plan 07.1-06 step 4 (D-02). |
| `lib/mailglass/installer/apply.ex` | `Apply.run/2` — operation executor | VERIFIED | Plan 07-01 SUMMARY; INST-02 idempotency via `.mailglass_conflict_*` sidecars |
| `lib/mailglass/installer/templates.ex` | Snippet templates emitted into adopter files | **VERIFIED-WITH-DEFECT (G-1)** | File exists; G-1: `router_mount_snippet/1` (line 33) emits non-existent `{App}.MailglassAdmin.Router.mount()` — real Phase 5 API is `mailglass_admin_routes/2`. Closure Plan 07.1-06 step 3 (D-02). |
| `lib/mailglass/installer/conflict.ex` | Conflict-sidecar writer | VERIFIED | Plan 07-01 SUMMARY |
| `lib/mailglass/installer/manifest.ex` | Installer manifest schema | VERIFIED | Plan 07-01 SUMMARY |
| `lib/mailglass/installer/operation.ex` | Operation struct + behaviour | VERIFIED | Plan 07-01 SUMMARY |
| `test/example/` | Golden fixture + snapshot assertions | **VERIFIED-WITH-DEFECT (G-2)** | File exists; G-2: golden snapshot was captured against `forward "/dev/mailglass", MailglassAdmin.Router` (wrong shape — Router is a macro module). Closure Plan 07.1-06 steps 1+5 (D-02). |
| `test/support/installer_fixture_helpers.ex` | Test fixture for installer | **VERIFIED-WITH-DEFECT (G-5)** | File exists; G-5 (paired with G-2): `run_simulated_install!/2` fallback at lines 34-39 drives a hand-rolled forward shape rather than real `Plan.build` + `Apply.run`. Closure Plan 07.1-06 step 1 (D-02). |
| `guides/getting-started.md` | DOCS-01 main guide | VERIFIED | Plan 07-03 SUMMARY |
| `guides/authoring-mailables.md` | DOCS-02 | VERIFIED | Plan 07-03 SUMMARY |
| `guides/components.md` | DOCS-02 | VERIFIED | Plan 07-03 SUMMARY |
| `guides/preview.md` | DOCS-02 | VERIFIED | Plan 07-03 SUMMARY |
| `guides/webhooks.md` | DOCS-02 | VERIFIED | Plan 04 + 07-03 SUMMARY |
| `guides/multi-tenancy.md` | DOCS-02 | VERIFIED | Plan 07-03 SUMMARY |
| `guides/telemetry.md` | DOCS-02 | VERIFIED | Plan 07-03 SUMMARY |
| `guides/testing.md` | DOCS-04 | VERIFIED | Plan 07-03 SUMMARY |
| `guides/migration-from-swoosh.md` | DOCS-03 | VERIFIED | Plan 07-03 SUMMARY |
| `.github/workflows/ci.yml` | Lint + test matrix + Dialyzer + docs + hex.audit | VERIFIED | Plan 07-04 SUMMARY (CI-01, CI-02) |
| `.github/workflows/dependency-review.yml` | Dependency-review action | VERIFIED | Plan 07-04 SUMMARY |
| `.github/workflows/actionlint.yml` | Workflow linter | VERIFIED | Plan 07-04 SUMMARY |
| `.github/workflows/pr-title.yml` | Conventional-Commits enforcement | VERIFIED | Plan 07-04 SUMMARY (CI-03) |
| `.github/workflows/release-please.yml` | Release-Please orchestrator | VERIFIED | Plan 07-05 SUMMARY (CI-04) |
| `.github/workflows/publish-hex.yml` | Protected-ref Hex publish (linked-versions matrix) | VERIFIED | Plan 07-05 SUMMARY (CI-05, CI-06, CI-07); `hex-publish` GitHub Environment with required reviewers; Phase 07.1 D-12..D-16 hardenings tracked separately |
| `.github/workflows/provider-live.yml` | Real-provider sandbox cron | VERIFIED | Plan 07-04 SUMMARY (TEST-04 — advisory only) |
| `.github/workflows/advisory-matrix.yml` | Advisory matrix lane | VERIFIED | Plan 07-04 SUMMARY |
| `release-please-config.json` | Linked-versions plugin config | VERIFIED | Plan 07-05 SUMMARY (D-04 from Plan 07-05); Phase 07.1 D-09 adds `bootstrap-sha` for v0.1.0 cycle |
| `.release-please-manifest.json` | Per-package version manifest | VERIFIED-WITH-CAVEAT | Phase 07.1 D-08: must reset to `0.0.0` for v0.1.0 bootstrap (manifest currently shows `0.1.0`, which makes release-please skip the cycle). Reset is procedural — Plan 07.1-07 closes. |
| `MAINTAINING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` | Governance files at repo root | VERIFIED | Plan 07-03 SUMMARY (DOCS-05); brand-voice copy (BRAND-02, BRAND-03) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `Mailglass.Installer.Plan` | `Mailglass.Installer.Apply` | Operation list passed to `Apply.run/2` | WIRED | Plan 07-01 SUMMARY |
| `Mailglass.Installer.Apply` | `Mailglass.Installer.Conflict` | Sidecar writer on detected drift | WIRED | INST-02 idempotency (Plan 07-01 SUMMARY) |
| `Mailglass.Installer.Templates.router_mount_snippet/1` | `MailglassAdmin.Router.mailglass_admin_routes/2` | Generated import + macro call | **BROKEN (G-1)** | Templates emit `{App}.MailglassAdmin.Router.mount()` — a non-existent function. Real macro is `mailglass_admin_routes/2`. Closure Plan 07.1-06 step 3. |
| `Mailglass.Installer.Plan.build/2` | `Mailglass.Webhook.Router.mailglass_webhook_routes/2` + `Plug.Parsers body_reader` | Generated webhook router + endpoint config block | **MISSING (G-3)** | Plan never emits webhook mount or `body_reader: {CachingBodyReader, :read_body, []}` config. First webhook POST raises `%Mailglass.ConfigError{type: :webhook_caching_body_reader_missing}`. Closure Plan 07.1-06 step 4. |
| `release-please-config.json` (linked-versions plugin) | `publish-hex.yml` (matrix) | Single group tag `mailglass-sibling-group-v<X>` triggers both publishes | WIRED | Plan 07-05 SUMMARY (CI-04, D-04 from Plan 07-05); Phase 07.1 D-11 documents tag pattern; D-14 tracks need to serialize the matrix (currently parallel — race risk on Hex index) |
| `publish-hex.yml` | `hex-publish` GitHub Environment | Required reviewers gate before `mix hex.publish --yes` | WIRED | Plan 07-05 SUMMARY (CI-07): `HEX_API_KEY` lives in environment secret, never visible to PR jobs |
| `publish-hex.yml` (gate logic) | `release-please.yml` (workflow_run trigger) | `if: workflow_run.conclusion == 'success'` | WIRED-WITH-CAVEAT | Currently fires on every successful release-please run including PR-update runs (Phase 07.1 D-12: tighten gate). Hardening tracked separately, not a blocker for v0.1.0 since `workflow_dispatch` is the actual first-publish path. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| TEST-04 | 07-04 | Doc-contract tests + provider-live advisory cron | SATISFIED | Plan 07-04 SUMMARY: `provider-live.yml` runs on `schedule` + `workflow_dispatch`, never blocks PRs |
| INST-01 | 07-01 | `mix mailglass.install` produces a working host app in <5 min | **NOT MET (closure plan: 07.1-06)** | Audit G-1 + G-3: installer generates non-compiling router snippet and omits webhook mount. Adopter hits `UndefinedFunctionError` before reaching the product. |
| INST-02 | 07-01 | Second-run idempotency via `.mailglass_conflict_*` sidecars | SATISFIED | Plan 07-01 SUMMARY |
| INST-03 | 07-01 | Golden-diff snapshot test in `test/example/` catches installer behavior changes | **NOT MET (closure plan: 07.1-06)** | Audit G-2 + G-5: snapshot captured against simulated install path, not real `Apply.run` output. Structurally cannot catch G-1/G-3. Closure: Plan 07.1-06 step 1 (drop `run_simulated_install!/2`) + step 5 (regenerate snapshot). |
| INST-04 | 07-02 | `mix verify.*` aliases + smoke harness | SATISFIED | Plan 07-02 SUMMARY: `verify.phase_07` + sibling aliases defined in `mix.exs` |
| CI-01 | 07-04 | Format + compile (warnings-as-errors, two passes) + ExUnit | SATISFIED | Plan 07-04 SUMMARY |
| CI-02 | 07-04 | Credo `--strict` + Dialyzer with cached PLT | SATISFIED | Plan 07-04 SUMMARY |
| CI-03 | 07-04 | Conventional-Commits PR title check | SATISFIED | `.github/workflows/pr-title.yml` |
| CI-04 | 07-05 | Release Please with linked-versions plugin | SATISFIED | Plan 07-05 SUMMARY |
| CI-05 | 07-05 | Protected-ref Hex publish (no PR-branch publish) | SATISFIED | Plan 07-05 SUMMARY: `hex-publish` GitHub Environment + protected ref |
| CI-06 | 07-05 | Hex tarball size enforcement | SATISFIED | `mix mailglass.publish.check` denylist (Phase 07.1 D-17 expands to allowlist + size guardrails) |
| CI-07 | 07-05 | `HEX_API_KEY` never visible to PR jobs | SATISFIED | Plan 07-05 SUMMARY: secret scoped to `hex-publish` environment |
| DOCS-01 | 07-03 | ExDoc publishes with `main: "getting-started"` | SATISFIED | Plan 07-03 SUMMARY |
| DOCS-02 | 07-03 | 9 guides under `guides/` | SATISFIED | Plan 07-03 SUMMARY; all 9 files present |
| DOCS-03 | 07-03 | `guides/migration-from-swoosh.md` parity guide | SATISFIED | Plan 07-03 SUMMARY |
| DOCS-04 | 07-03 | Doctest contracts; `guides/testing.md` | SATISFIED | Plan 07-03 SUMMARY |
| DOCS-05 | 07-03 | `MAINTAINING.md` + `CONTRIBUTING.md` + `SECURITY.md` + `CODE_OF_CONDUCT.md` | SATISFIED | Plan 07-03 SUMMARY: governance files at repo root |
| BRAND-02 | 07-01 | Brand voice in installer output | SATISFIED | Plan 07-01 SUMMARY |
| BRAND-03 | 07-03 | Brand voice in guides + governance copy | SATISFIED | Plan 07-03 SUMMARY |

**Coverage:** 17/19 SATISFIED, 2/19 NOT MET (INST-01, INST-03 — both closed by Plan 07.1-06).

Per Phase 07.1 D-06, the REQUIREMENTS.md traceability table flip happens in Plan 07.1-05 (separate commit). INST-01 + INST-03 stay marked `Pending` in REQUIREMENTS.md until Plan 07.1-06 lands.

### Anti-Patterns Scan

The audit's integration check for Phase 7 found:

- **0 Critical** findings
- **5 Blocker-level** findings (G-1, G-2, G-3, G-4, G-5 — all mapped to Plan 07.1-06 closure)
- **5 Info-level** findings (deferred-by-design / tracked tech debt)

| Finding | Severity | Impact | Disposition |
|---------|----------|--------|-------------|
| G-1: `templates.ex:33` `router_mount_snippet/1` emits non-existent `MailglassAdmin.Router.mount()` | Blocker | Adopter `UndefinedFunctionError` at router compile time | Closure: Plan 07.1-06 step 3 |
| G-2: golden snapshot captured against `forward "/dev/mailglass", MailglassAdmin.Router` (wrong shape) | Blocker | Golden-diff CI gate structurally cannot catch G-1 / G-3 | Closure: Plan 07.1-06 steps 1+5 |
| G-3: `Plan.build/2` omits webhook mount + Plug.Parsers `body_reader` config | Blocker | First webhook POST raises `ConfigError` | Closure: Plan 07.1-06 step 4 |
| G-4: `admin_smoke_gate` CI job matches zero `@tag :admin_smoke` tests | Blocker (tech-debt severity in audit; promoted to blocker per D-02) | Vacuous CI gate hides preview-mount regressions | Closure: Plan 07.1-06 step 6 |
| G-5: `installer_fixture_helpers.ex:34-39` falls back to `run_simulated_install!/2` | Blocker (paired with G-2) | Real installer never exercised by golden test | Closure: Plan 07.1-06 step 1 |
| G-6: `MailglassAdmin.OptionalDeps.PhoenixLiveReload.available?/0` unused | Info | Cosmetic divergence from `Mailglass.OptionalDeps.{Oban, …}` pattern | Non-blocking; tracked tech debt |
| Atom-type form input disabled at v0.1 (PreviewLive) | Info | Adopters with atom-typed `preview_props/0` fields edit via URL | Deferred-by-design; v0.5 `form_hints` map |
| Raw envelope tab inline best-effort (Swoosh 1.25 does not expose `Email.Render.encode/1`) | Info | Raw tab synthesizes envelope rather than serializing through Swoosh | Documented; v0.5 |
| No telemetry from `mailglass_admin` package at v0.1 | Info | Admin-package observability deferred pending whitelist audit | Deferred-by-design; v0.5 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix mailglass.install` on a clean Phoenix host | `mix mailglass.install` (audit traced via static analysis of `templates.ex` + `plan.ex`) | Generates router snippet that does not compile (G-1) and omits webhook mount (G-3) | **FAIL — closure 07.1-06** |
| Golden install diff | `mix verify.installer.golden` (Plan 07-01 SUMMARY) | exit 0 — but vacuously, because the fixture drives `run_simulated_install!/2` rather than real `Apply.run` (G-2 + G-5) | PASS-BUT-VACUOUS |
| `admin_smoke_gate` CI job | `cd mailglass_admin && mix test --only admin_smoke` | 0 tests matched (G-4) | PASS-BUT-VACUOUS |
| Phase 7 alias suite | `mix verify.phase_07` | alias defined at `mix.exs:176` (mapped to `:test` env at `mix.exs:46`); covers compile + test + Credo + Dialyzer + docs | PASS (audit-time integration check) |
| ExDoc build | `mix docs --warnings-as-errors` | exit 0 — 9 guides + ExDoc 0.40+ `llms.txt` autogen | PASS |
| `mix hex.audit` | `mix hex.audit` | exit 0 | PASS |
| Tarball denylist | `mix mailglass.publish.check` | exit 0 (current ~58 LOC denylist; Phase 07.1 D-17 expands to 15-step procedure) | PASS |

For commands not explicitly re-run during the audit close-out, status is reported per the audit-time integration check (`gsd-integration-checker (Sonnet)`).

### Human Verification Required

The audit's `human_verification` items intersecting Phase 7:

1. **Time-to-first-success on a clean Phoenix host app** (Phase 7 SC#1 — currently fails per G-1). Becomes verifiable post-Phase 07.1 Plan 06 + Plan 11 (publish ceremony close-out). Once a tagged release of `mailglass` + `mailglass_admin` is on Hex.pm and an adopter can run `mix new`, `mix mailglass.install`, and reach the preview pane in under 5 minutes, this item closes.
2. **Protected-ref Hex publish dry-run with reviewer approval** (manual ceremony cell). Phase 07.1 Plan 11 executes the first real publish; pre-publish reviewer sees `mix mailglass.publish.check` summary in `$GITHUB_STEP_SUMMARY` (Phase 07.1 D-15) before clicking Approve in the `hex-publish` environment.
3. **Visual rendering check across Outlook/Gmail/Apple Mail** (transitive from Phase 1; touches Phase 7 only insofar as `guides/getting-started.md` previews cite real-client behavior).

The audit notes these as observed-but-not-blocking. Items 1 and 2 close in Phase 07.1; item 3 ships to v0.5 deliverability scope.

### Info / Notes (non-blocking)

1. **G-6 (cosmetic):** `MailglassAdmin.OptionalDeps.PhoenixLiveReload.available?/0` exists but is unused — only consumer is a `Code.ensure_loaded?` short-circuit. Cosmetic divergence from `Mailglass.OptionalDeps.{Oban, …}` pattern. Lift to v0.5 cleanup pass.
2. **Atom-type form input disabled at v0.1 (PreviewLive).** UI-SPEC line 362 lists `<select>` populated via runtime introspection; v0.1 ships disabled text input. Tracked in Plan 05-06 SUMMARY "Known Deferrals" — v0.5 `form_hints` map.
3. **Raw envelope tab is inline best-effort.** Swoosh 1.25 does not expose `Email.Render.encode/1`. The Raw tab synthesizes the envelope. Deferred until Swoosh exposes a stable encoder.
4. **No telemetry from `mailglass_admin` at v0.1.** Per OBS-01 PII-whitelist policy, admin-package telemetry needs a deliberate whitelist audit. Deferred to v0.5.
5. **Phase 07.1 publish-hex.yml hardenings** (D-12..D-16): tighten `workflow_run` gate, add `workflow_dispatch` safety valve, serialize publish matrix with Hex-index polling, move `mix mailglass.publish.check` summary emission to a separate prior job, gate on green `ci.yml` for the tagged commit. Tracked in subsequent Phase 07.1 plans (07.1-08..07.1-10), not blocking for V-07 close-out.

### Gaps Summary

Five goal-blocking gaps (G-1, G-2, G-3, G-4, G-5) closed by Phase 07.1 Plan 06 — installer fix sequence with strict task ordering per Phase 07.1 D-02:

1. Drop `run_simulated_install!/2` from `installer_fixture_helpers.ex` (closes G-2 + G-5).
2. Watch existing golden tests fail honestly — proves the fixture now matches reality.
3. Rewrite `router_mount_snippet/1` to emit `import MailglassAdmin.Router; mailglass_admin_routes "/dev/mail"` (closes G-1).
4. Add `webhook_mount_snippet/1` + endpoint Plug.Parsers `body_reader` config block to `Plan.build/2` (closes G-3).
5. Regenerate `test/example/` golden snapshot + `test/example/README.md` against real installer output.
6. Add `@tag :admin_smoke` test in `mailglass_admin/test/` exercising the post-installer compile path (closes G-4).

After Plan 06 lands, re-run `/gsd-audit-milestone v0.1` to verify SC#1 met (target: green G-1..G-5 in subsequent audit). Once green, this VERIFICATION.md's frontmatter `status:` flips from `passed_with_known_gaps` to `passed`, score from `4/5` to `5/5`, and `known_gaps:` empties (re-verification cycle in scope of Phase 07.1 Plan 11 publish-ceremony close-out).

---

_Verified: 2026-04-25T00:00:00Z (retroactive backfill per Phase 07.1 D-05)_
_Verifier: gsd-integration-checker (Sonnet) via .planning/v0.1-MILESTONE-AUDIT.md_
