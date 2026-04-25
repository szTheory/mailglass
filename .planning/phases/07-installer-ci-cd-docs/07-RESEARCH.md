# Phase 7: Installer + CI/CD + Docs — Research

**Researched:** 2026-04-24  
**Phase:** 07-installer-ci-cd-docs  
**Goal:** Plan a phase that turns the existing codebase into a release-ready package set with a safe installer, split and secure CI/CD, and trustworthy docs contracts.  
**Confidence:** HIGH (phase context is already decision-rich and implementation-convergent with prior patterns)

## Summary

Phase 7 is a **release-hardening and adoption phase**. It should not introduce new runtime product behavior; it should lock reliability around behavior that already exists. The planning focus is:

1. **Installer reliability:** `mix mailglass.install` must be deterministic, idempotent, conflict-safe, and reviewable.
2. **CI/CD discipline:** split workflows, stable required checks, advisory provider-live lane, secure release + publish gates.
3. **Docs as executable contracts:** ExDoc + 9 guides + snippet/doctest contracts that fail fast when APIs drift.
4. **Brand consistency:** error/log/doc copy matches the project voice without becoming vague or cute.

The phase is high leverage because it converts good internals into a low-friction adopter experience and a safe release operation.

## Locked Constraints to Preserve

From phase context, requirements, and project rules, treat these as non-negotiable:

- **Installer strategy is fixed:** hybrid operation engine (`create_file`, `ensure_snippet`, `ensure_block`, `run_task`) with explicit ownership boundaries.
- **Reruns must never clobber user edits:** write `.mailglass_conflict_*` sidecars and leave target files untouched on ambiguity.
- **Manifest-driven idempotency:** install metadata in `.mailglass.toml` with path/hash tracking.
- **Golden diff strategy is fixed:** full-tree snapshot with narrow normalization.
- **CI topology is split-by-concern:** no monolithic workflow.
- **Required checks are stable and explicit:** avoid churn in check names once introduced.
- **Provider-live tests are advisory only:** `schedule` + `workflow_dispatch`, never merge-blocking.
- **Release Please linked versions required:** root + `mailglass_admin` move together.
- **Hex publish security model is strict:** protected ref + environment approvals; no publish secret in PR jobs.
- **Core package remains no-Node:** installer/docs/CI must not introduce Node into `mailglass`.
- **Optional dep gateway discipline remains mandatory:** keep `mix compile --no-optional-deps --warnings-as-errors` as a first-class gate.

## Current Baseline (What Planning Must Account For)

Observed baseline gaps (important for plan sizing):

- No `Mix.Tasks.Mailglass.Install` module yet.
- No `test/example/` host app fixture yet.
- Only one workflow exists (`.github/workflows/ci.yml`), and it currently:
  - is monolithic,
  - uses tag-based actions (`@v4`, `@v1`) instead of SHA pins,
  - ignores markdown-only changes (`paths-ignore` includes `**/*.md`) which conflicts with docs-contract gating.
- No `dependency-review.yml`, `actionlint.yml`, `release-please.yml`, `publish-hex.yml`, `provider-live.yml`, or PR-title check workflow yet.
- Root maintainer docs are missing (`MAINTAINING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`).
- Root `LICENSE`/`CHANGELOG.md` are missing while `mix.exs` package whitelist expects them.
- Docs are still skeletal for Phase 7 scope:
  - `mix.exs` docs config is minimal (`main/source_url/source_ref` only),
  - only one guide currently exists (`guides/webhooks.md`),
  - no docs-contract test harness yet.

These are expected for current phase progression; they should directly drive plan decomposition.

## Standard Stack

Use existing project choices; avoid introducing novel tools unless required.

| Concern | Standard choice for this phase | Notes |
|---|---|---|
| Installer engine | Mix task + internal operation structs/modules | Keep logic in Elixir; no external scaffolding tools |
| File generation | `Mix.Generator` + custom anchored patch helpers | Combine safe creates with controlled shared-file mutations |
| Conflict tracking | `.mailglass.toml` manifest + sidecar files | Deterministic rerun behavior and conflict dedupe |
| Golden regression | ExUnit integration tests + full-tree snapshot fixture | Minimal normalization only (timestamps, temp paths, secrets) |
| CI platform | GitHub Actions | Split workflows by concern |
| Release automation | Release Please manifest mode + linked versions | Coordinated release PRs for root and `mailglass_admin` |
| Package validation | `mix hex.build`/publish dry-run + explicit tarball size checks | Enforce CI-05 thresholds |
| Docs generation | ExDoc `~> 0.40` + extras + groups | `llms.txt` comes automatically |
| Docs trust contracts | ExUnit doc-contract tests + doctests | Parse/compile snippets and verify referenced tasks/routes/config |
| Style/voice guard | Existing brand book + direct wording checks in docs review | Reinforces BRAND-02 and BRAND-03 |

## Architecture Patterns

### 1) Installer Architecture (INST-01, INST-02, INST-03)

Plan around a two-stage model:

1. **Plan stage:** compute operations and statuses without mutating files (supports `--dry-run`).
2. **Apply stage:** execute operations in deterministic order, record outcomes, emit concise status lines.

Recommended operation contract:

- `create_file` for installer-owned new files.
- `ensure_snippet` for small anchored inserts in shared files.
- `ensure_block` for managed begin/end blocks in shared files.
- `run_task` for follow-up actions (for example migration generation through supported task APIs).

Ownership model to preserve:

- **Installer-owned files:** create-or-conflict (never blind overwrite).
- **Adopter-shared files** (`router.ex`, `runtime.exs`, etc.): anchored/managed block edits only.
- **Migrations:** generated via migration task flow, not inlined SQL content.

Conflict behavior:

- If target drift cannot be safely merged, write sidecar: `.mailglass_conflict_<target>_<reason>`.
- Keep original file unchanged.
- Provide manual merge instructions in CLI output.

Manifest behavior:

- Store template/version/path/hash metadata in `.mailglass.toml`.
- On rerun, compare current file hash with expected hash from previous install.
- Mark `unchanged`/`update`/`conflict` deterministically.

### 2) Golden Installer Diff Pattern (INST-03)

Use two complementary test paths:

- **Fresh-install golden:** run installer on a clean host fixture, snapshot full output tree.
- **Second-run idempotency:** rerun installer with no manual edits; assert zero file modifications.

Also include:

- **Edited-host conflict test:** modify a managed region intentionally, rerun, assert sidecar creation and no clobber.
- **`--no-admin` variant test:** assert expected omissions and stable output.

Normalization should be intentionally narrow (timestamps, generated secrets, temp paths), otherwise reviewers lose signal.

### 3) CI/CD Workflow Topology (CI-01..CI-07, TEST-04)

Use split workflows with stable check names:

- `ci.yml` (required): format, compile, compile `--no-optional-deps`, test lane, custom credo, dialyzer, docs warnings-as-errors, hex audit, installer golden, admin smoke.
- `dependency-review.yml` (required on PR).
- `actionlint.yml` (required on workflow changes / PRs).
- `pr-title.yml` (required conventional-commit title check).
- `provider-live.yml` (advisory only: `schedule` + `workflow_dispatch`, runs `@tag :provider_live`).
- `release-please.yml` (push to `main`).
- `publish-hex.yml` (release ref + environment approvals only).

Security and supply-chain rules:

- Pin all third-party `uses:` actions to commit SHA.
- Set least-privilege workflow permissions by default.
- Keep `HEX_API_KEY` in protected GitHub Environment only.
- Ensure PR workflows and forks cannot access publish secrets.
- Add Dependabot coverage for both `mix` and `github-actions`.

### 4) Docs Trust Pyramid (DOCS-01..DOCS-05, BRAND-03)

Apply hybrid verification:

1. **Doctests** for pure API contracts.
2. **Snippet compile checks** for README/guides quick-start blocks.
3. **Host-app docs smoke checks** for onboarding flows (tasks/routes/config snippets resolve to real code).

ExDoc information architecture:

- `main: "getting-started"`.
- 9 guide extras required by DOCS-02.
- module groups and guide groups to make docs navigable.
- source links with version refs for traceability.

Docs-contract checks should verify:

- referenced mix task names exist,
- config examples validate against `Mailglass.Config.new!/1` schema,
- admin route examples match real router macro/path shape,
- migration guide steps are executable against a fixture host.

### 5) Release/Publish Architecture (CI-04, CI-07, CI-05)

Release Please manifest should coordinate:

- root package (`mailglass`),
- `mailglass_admin`.

Keep linked-version behavior:

- coordinated bumps,
- `mailglass_admin` exact dependency pin to matching core version.

Publish flow:

1. Release Please merge/tag on protected branch.
2. Publish workflow runs on release ref only.
3. Publish `mailglass` first, then `mailglass_admin` (dependency availability ordering).
4. Enforce tarball file whitelist and size caps pre-publish.

## Sequencing Recommendations

A planner should avoid parallelizing items that produce unstable gate names or circular dependencies.

### Suggested Wave Order

1. **Wave 0 — Scaffolding and Contracts**
   - Define installer operation model and manifest format.
   - Define required CI check names and workflow list.
   - Define docs contract harness shape.
   - Add/align root release artifacts expected by package whitelist (license/changelog/docs policy files).

2. **Wave 1 — Installer Core**
   - Implement `mix mailglass.install` core engine.
   - Implement `--dry-run`, `--no-admin`, `--force`.
   - Implement sidecar conflict handling and status output.

3. **Wave 2 — Installer Golden Suite**
   - Create `test/example/` fixture host.
   - Add fresh install, rerun idempotency, conflict, and `--no-admin` golden checks.
   - Add stable snapshot regeneration path.

4. **Wave 3 — Docs Surface + Contracts**
   - Expand ExDoc config and add 9 guides.
   - Implement README/guides contract tests and migration guide smoke flow.
   - Add maintainer/security/contributing/code-of-conduct docs.
   - Run voice pass for direct wording and brand tone.

5. **Wave 4 — CI Split + Required Gates**
   - Split workflows and pin action SHAs.
   - Add required PR title check, dependency review, actionlint.
   - Add required CI matrix and docs/audit/no-optional-deps gates.
   - Add advisory provider-live workflow.

6. **Wave 5 — Release + Publish Security**
   - Add Release Please manifest/config.
   - Add protected publish workflow with environment approvals.
   - Add tarball content/size assertions for both packages.

7. **Wave 6 — Final Convergence**
   - Ensure `mix verify.phase<NN>` alias consistency for Phase 7.
   - Verify under-5-minute installer journey.
   - Freeze required-check names and phase verification commands.

## Requirement Mapping Considerations

This table is intended to be plan-slice ready.

| REQ ID | Planning considerations | Primary artifacts to add/update |
|---|---|---|
| TEST-04 | Provider-live tests must exist but remain advisory-only; never required checks | `provider-live.yml`, tagged tests (`@tag :provider_live`), notification path |
| INST-01 | Installer must generate context, mounts, default templates, runtime config, optional Oban worker stub, `--no-admin` behavior | `lib/mix/tasks/mailglass.install.ex`, installer templates, install operation modules |
| INST-02 | Idempotency and conflict sidecars are core behavior, not polish | manifest file design, conflict sidecar writer, rerun tests |
| INST-03 | Golden diff must be reviewable and deterministic | `test/example/` host fixture, snapshot tests, normalization helpers |
| INST-04 | Keep one focused verify task per concern and stable phase verifier conventions | `mix.exs` alias additions (`verify.phase_07` and supporting granular aliases) |
| CI-01 | Split workflows by concern; include all listed gates | `.github/workflows/*.yml` set |
| CI-02 | Required matrix is intentionally narrow (1 required cell), wider matrix advisory | matrix strategy in `ci.yml` + optional nightly workflow |
| CI-03 | Conventional commit policy enforced via PR title check | `pr-title.yml` or equivalent required check |
| CI-04 | Release Please manifest + linked versions for root/admin | `release-please.yml`, `release-please-config.json`, `.release-please-manifest.json` |
| CI-05 | Tarball whitelist and size budgets must be automated and blocking | package file lists, tarball-size check step/scripts |
| CI-06 | SHA-pin all third-party actions; Dependabot watches workflows and mix deps | workflow `uses:` pins, `.github/dependabot.yml` |
| CI-07 | Publish secret isolation and protected release flow | `publish-hex.yml`, GitHub Environment usage and permissions |
| DOCS-01 | ExDoc main/source/version/grouping and extras as canonical docs spine | `mix.exs` docs config |
| DOCS-02 | Exactly 9 required guides, each ending with runnable flow | `guides/*.md` suite |
| DOCS-03 | Migration guide must be executable and behavior-preserving | `guides/migration-from-swoosh.md` + migration smoke test |
| DOCS-04 | Doc-contract tests are required gate, not best-effort | docs contract test modules + CI step |
| DOCS-05 | Root maintainer/security docs are release artifacts | `MAINTAINING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` |
| BRAND-02 | Error/log strings must remain specific, clear, and non-cute | targeted copy pass across installer/task/log surfaces |
| BRAND-03 | Docs wording should prefer direct language (for example “preview”) | guide/README editorial pass and docs review checklist |

## Don't Hand-Roll

- **Release automation:** do not replace Release Please with custom scripts.
- **Workflow linting logic:** use `actionlint`; do not build custom YAML validators.
- **Optional dependency behavior:** continue using existing optional-deps gateway patterns; do not special-case CI here.
- **Installer AST patching engine:** avoid full AST/token patching now; use the locked hybrid model.
- **Doc parser infrastructure:** keep docs-contract checks lightweight and explicit (snippets/tasks/routes/config), not a custom markdown runtime.
- **Publish secret handling:** do not expose publish secrets to general CI jobs for convenience.

## Common Pitfalls

High-probability failure modes for this phase:

1. **`paths-ignore` hides docs regressions** (current `ci.yml` ignores markdown); docs contracts never run on docs-only changes.
2. **Installer rewrites shared files unsafely** without sidecar fallback.
3. **Golden tests become noisy** due to over-broad normalization.
4. **Required check names churn** during implementation, causing branch protection drift.
5. **Action tags not SHA-pinned** (supply-chain risk).
6. **Publish workflow leaks `HEX_API_KEY`** into PR context.
7. **Release Please config misses nested package updates** (root/admin version drift).
8. **Doc examples rot silently** because docs render but are not executed/validated.
9. **Root package publish fails late** due to missing whitelisted release files.
10. **Brand voice drift** into vague or marketing-heavy wording in installer/docs.

## Code Examples

### Installer Operation Model (shape)

```elixir
defmodule Mailglass.Installer.Operation do
  @type t ::
          {:create_file, path :: String.t(), contents :: String.t()}
          | {:ensure_snippet, path :: String.t(), anchor :: String.t(), snippet :: String.t()}
          | {:ensure_block, path :: String.t(), start_marker :: String.t(), end_marker :: String.t(), body :: String.t()}
          | {:run_task, task :: String.t(), args :: [String.t()]}
end
```

### Release Please Manifest Shape (conceptual)

```json
{
  ".": "0.1.0",
  "mailglass_admin": "0.1.0"
}
```

```json
{
  "packages": {
    ".": { "release-type": "elixir" },
    "mailglass_admin": { "release-type": "elixir" }
  },
  "plugins": ["linked-versions"],
  "separate-pull-requests": false
}
```

### Docs-Contract Check Concept

```elixir
test "README quick start references real mix tasks" do
  snippet = Docs.extract_section!("README.md", "Quickstart")
  assert {:ok, _quoted} = Code.string_to_quoted(snippet)
  assert Mix.Task.get("mailglass.install")
  assert Mix.Task.get("mailglass.reconcile")
end
```

## Validation Architecture

Use this as the default gate architecture for Nyquist generation.

### Gate Layers

1. **Unit/contract layer (fast):**
   - installer operation planner/apply behavior tests,
   - docs snippet parsing/tests,
   - route/task/config contract checks.

2. **Integration layer (medium):**
   - fresh installer run in fixture host,
   - rerun idempotency + conflict sidecar scenarios,
   - admin smoke verification lane.

3. **Pipeline layer (required CI):**
   - formatting/compile/test/credo/dialyzer/docs/audit,
   - golden install diff,
   - dependency review + actionlint + PR title check.

4. **Advisory layer (scheduled/manual):**
   - provider-live tests only.

5. **Release layer (protected):**
   - Release Please coordinated versions,
   - publish dry-run + publish with environment approvals,
   - tarball content/size checks.

### Requirement-to-Validation Matrix

| REQ ID | Validation idea | Example gate/command |
|---|---|---|
| TEST-04 | Provider-live tagged tests run only in advisory workflow | `provider-live.yml` + `mix test --only provider_live` |
| INST-01 | Installer generates all expected artifacts and routes/config snippets | integration test in fixture host asserting file/tree and snippets |
| INST-02 | Second run produces no changes; drift creates sidecar only | rerun idempotency + conflict scenario tests |
| INST-03 | Golden snapshot drift is explicit and reviewable in PRs | golden diff test + CI fail on unreviewed snapshot change |
| INST-04 | Phase verify alias exists and remains focused | `mix verify.phase_07` in CI |
| CI-01 | All required workflows exist and run intended checks | workflow presence + required checks list |
| CI-02 | Required matrix exactly stable cell(s), wide matrix advisory | matrix assertions in required/advisory workflows |
| CI-03 | PR title conventional commit check blocks invalid titles | required `pr-title` check |
| CI-04 | Coordinated release PR updates root and admin versions together | Release Please manifest/plugin behavior test |
| CI-05 | Tarball file list and size thresholds enforced pre-publish | tarball validation script/step for both packages |
| CI-06 | Action SHA pinning and Dependabot configs present | lint/check workflow + config assertions |
| CI-07 | Publish secret only available in protected environment | workflow permissions review + environment-gated publish job |
| DOCS-01 | ExDoc main/source refs/extras/groups configured correctly | `mix docs --warnings-as-errors` |
| DOCS-02 | All 9 guides present and end with runnable flow sections | docs contract test scanning guide endings |
| DOCS-03 | Migration guide steps execute against fixture host without behavior regression | migration smoke integration test |
| DOCS-04 | README/guides snippets compile and reference real tasks/routes/config | doc-contract test suite in CI |
| DOCS-05 | Maintainer/security docs exist and are shipped | file presence checks + package file checks |
| BRAND-02 | Error/log copy reviewed for clarity/specificity | string-level review checklist + targeted tests for installer messages |
| BRAND-03 | Docs language review enforces direct wording | docs editorial checklist in PR template/review step |

### Recommended Verification Commands

- `mix verify.phase_07` (aggregate phase gate)
- `mix test --only installer_golden`
- `mix test --only docs_contract`
- `mix docs --warnings-as-errors`
- `mix compile --no-optional-deps --warnings-as-errors`
- `mix credo --strict`
- `mix dialyzer --halt-exit-status`
- `mix hex.audit`

## Planning Notes for Downstream PLAN.md Generation

- Keep plan slices **vertical and independently verifiable**: installer engine, golden harness, docs contracts, CI split, release security.
- Lock required check names early and avoid renaming later in the phase.
- Treat workflow additions as code that needs tests/review, not “ops setup.”
- Put maintainers docs near the end but before release workflow finalization so they document the exact shipped process.
- Keep one explicit “snapshot regeneration” path for installer goldens to avoid ad-hoc fixture edits.

## Sources

- `.planning/phases/07-installer-ci-cd-docs/07-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/research/STACK.md`
- `.planning/research/PITFALLS.md`
- `.planning/research/SUMMARY.md`
- `CLAUDE.md`
- `mix.exs`
- `mailglass_admin/mix.exs`
- `.github/workflows/ci.yml`
- `README.md`
- `guides/webhooks.md`
- `mailglass_admin/README.md`
- `mailglass_admin/CHANGELOG.md`
- `lib/mix/tasks/mailglass.reconcile.ex`
- `lib/mix/tasks/mailglass.webhooks.prune.ex`
- `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex`
- `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.watch.ex`
- `mailglass_admin/lib/mix/tasks/mailglass_admin.daisyui.update.ex`

## Metadata

- Repo-local `.cursor/rules/` present: **no** files found.
- Repo-local `.cursor/skills/` present: **no** files found.
- Repo-local `.agents/skills/` present: **no** files found.
- Planning implication: rely on existing `.planning/` and project-level guidance artifacts as the canonical discipline source.
