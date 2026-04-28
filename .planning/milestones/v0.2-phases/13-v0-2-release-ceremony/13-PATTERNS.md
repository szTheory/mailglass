# Phase 13: v0.2 Release Ceremony - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 25
**Analogs found:** 21 / 25

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `CHANGELOG.md` | docs | release-ledger | `CHANGELOG.md` (`0.1.0` curated entry at lines 179-249) | role-match |
| `mailglass_admin/CHANGELOG.md` | docs | release-ledger | `mailglass_admin/CHANGELOG.md` (`0.1.1` coordinated sibling entry at lines 1-19) | exact |
| `README.md` | docs | request-response | `README.md` install + quickstart sections at lines 42-108 | exact |
| `MAINTAINING.md` | docs | runbook | `MAINTAINING.md` release runbook at lines 79-119 | exact |
| `guides/getting-started.md` | docs | request-response | `README.md` install + quickstart sections at lines 42-108 | role-match |
| `guides/upgrading-from-v0_1.md` | docs | transform | `guides/upgrading-from-v0_1.md` current codemod guide at lines 1-102 | exact |
| `guides/migration-from-swoosh.md` | docs | transform | `test/mailglass/docs_migration_smoke_test.exs` at lines 7-30 | role-match |
| `guides/authoring-mailables.md` | docs | request-response | `README.md` mailable example at lines 82-104 | role-match |
| `guides/unsubscribe.md` | docs | request-response | existing Tier 1 docs gate baseline in `lib/mix/tasks/mailglass.docs.check.ex` lines 22-49 | partial |
| `guides/dkim-setup.md` | docs | request-response | existing Tier 1 docs gate baseline in `lib/mix/tasks/mailglass.docs.check.ex` lines 22-49 | partial |
| `guides/webhooks.md` | docs | runbook | `guides/webhooks.md` runbook presence via `## 7. Statement timeout runbook` and `lib/mix/tasks/mailglass.docs.check.ex` lines 22-49 | partial |
| `.github/workflows/release-please.yml` | CI workflow | event-driven | `.github/workflows/release-please.yml` lines 24-96 | exact |
| `.github/workflows/publish-hex.yml` | CI workflow | event-driven | `.github/workflows/publish-hex.yml` lines 35-245 | exact |
| `.github/workflows/post-publish-smoke.yml` | CI workflow | event-driven | `.github/workflows/post-publish-smoke.yml` lines 24-360 | exact |
| `release-please-config.json` | config | event-driven | `release-please-config.json` linked-versions plugin | exact |
| `.release-please-manifest.json` | config | event-driven | `.release-please-manifest.json` version map | exact |
| `lib/mix/tasks/mailglass.publish.check.ex` | mix-task | batch | `lib/mix/tasks/mailglass.publish.check.ex` lines 6-157 | exact |
| `lib/mix/tasks/mailglass.docs.check.ex` | mix-task | batch | `lib/mix/tasks/mailglass.docs.check.ex` lines 6-62 | exact |
| `lib/mix/tasks/mailglass.upgrade.v0_2.ex` | mix-task | transform | `lib/mix/tasks/mailglass.upgrade.v0_2.ex` + `test/mailglass/upgrade/v0_2_test.exs` | exact |
| `test/mailglass/upgrade/v0_2_test.exs` | test | transform | `test/mailglass/upgrade/v0_2_test.exs` lines 17-113 | exact |
| `test/mailglass/docs_migration_smoke_test.exs` | test | transform | `test/mailglass/docs_migration_smoke_test.exs` lines 7-30 | exact |
| `test/mailglass/install/install_idempotency_test.exs` | test | file-I/O | `test/mailglass/install/install_idempotency_test.exs` lines 9-100 | exact |
| `test/mailglass/install/install_first_preview_smoke_test.exs` | test | file-I/O | `test/mailglass/install/install_first_preview_smoke_test.exs` lines 6-23 | exact |
| `mailglass_admin/test/mailglass_admin/post_installer_smoke_test.exs` | test | request-response | `mailglass_admin/test/mailglass_admin/post_installer_smoke_test.exs` lines 8-48 | exact |
| `test/fixtures/release_please_sed_test.sh` | shell-test | batch | `test/fixtures/release_please_sed_test.sh` lines 1-29 | exact |
| `test/example/README.md` | docs | file-I/O | `test/example/README.md` golden snapshot sections at lines 7-167 | exact |

## Pattern Assignments

### `CHANGELOG.md` (docs, release-ledger)

**Analog:** `CHANGELOG.md`

**Curated release-entry pattern** (`CHANGELOG.md:179-229`):
```markdown
## [0.1.0] - 2026-04-25

Mailglass is the framework layer Swoosh deliberately leaves out of its
transport-only core: ...
This is a validation release ...

### Added
- ...
### Security
- ...
```

**Generated ledger pattern to avoid leading with** (`CHANGELOG.md:8-29`):
```markdown
## [0.1.1](...) (2026-04-26)

### Features
* **installer:** ...

### Bug Fixes
* **post-publish-smoke:** ...
```

**What to copy:** use the `0.1.0` shape for the top of the `0.2.0` entry: short maintainer narrative first, then categorized ledger underneath. Keep the `0.1.1` compare-link/date formatting if the release remains Release Please managed.

**Planner note:** there is no existing entry with explicit `breaking changes`, `upgrade path`, `dependency matrix`, and `rollback` headings. That structure is new work.

---

### `mailglass_admin/CHANGELOG.md` (docs, release-ledger)

**Analog:** `mailglass_admin/CHANGELOG.md`

**Sibling-version coordination pattern** (`mailglass_admin/CHANGELOG.md:3-19`):
```markdown
All notable changes to `mailglass_admin` will be documented in this file.
Format follows Keep a Changelog.
Versioning coordinated with `mailglass` core via Release Please linked-versions.

## [0.1.1](...) (2026-04-26)
### Bug Fixes
* **release-please:** bump mailglass_admin -> mailglass dep pin ...
```

**What to copy:** keep the sibling entry short, explicitly coordinated with core, and action-oriented. Phase 13 can extend this by adding one short paragraph that says whether adopters need to do anything beyond the core upgrade.

---

### `README.md` and Tier 1 guide updates (docs, request-response / transform)

**Analogs:** `README.md`, `lib/mix/tasks/mailglass.docs.check.ex`, `test/mailglass/docs_migration_smoke_test.exs`

**Install + quickstart pattern** (`README.md:42-108`):
```markdown
## Installation
...
mix deps.get
mix mailglass.install
mix ecto.migrate

## Quickstart
...
mix verify.phase_07
...
Preview mailables in dev at `http://localhost:4000/dev/mail`
```

**Docs gate baseline** (`lib/mix/tasks/mailglass.docs.check.ex:22-49`):
```elixir
@banned_patterns [~r/\bD-\d{2,3}\b/, ~r/\bLINT-\d{2}\b/]
...
if leaks == [] do
  Mix.shell().info("[mailglass.docs.check] OK ...")
else
  ...
  Mix.raise("Delivery blocked: #{length(leaks)} internal ID(s) leaked into guides/*.md")
end
```

**Guide-smoke pattern** (`test/mailglass/docs_migration_smoke_test.exs:7-30`):
```elixir
code = extract_block_after_heading(@guide_path, "End-to-End Example")
assert {:ok, _quoted} = Code.string_to_quoted(code)

email =
  Swoosh.Email.new()
  |> Swoosh.Email.to("migrated@example.com")
...
assert {:ok, _delivery} = Mailglass.deliver(email)
```

**What to copy:** Tier 1 docs should keep the repo’s current pattern of executable commands and compileable examples. Extend the docs gate with low-noise checks rather than broad prose linting, and use guide-smoke tests when a guide contains a canonical migration path.

**Planner note:** there is no existing stale-version/API-marker checker for Tier 1 docs. Current docs enforcement only catches leaked internal IDs.

---

### `MAINTAINING.md` (docs, runbook)

**Analog:** `MAINTAINING.md`

**Release runbook pattern** (`MAINTAINING.md:79-119`):
```markdown
## Release Runbook

1. Verify CI green on `main` for the SHA to be released.
2. Merge the release-please PR.
3. Approve the `hex-publish` deployment ...
4. Within 60 minutes of publish: smoke-install in a fresh Phoenix app.
   ...
   If anything fails ... `mix hex.publish --revert` ...
5. Post the release link ...
```

**What to copy:** maintainer-facing docs in this repo are explicit, operational, and include fallback semantics inline. Phase 13 runbook additions should stay in numbered-step form and spell out the canonical fallback path instead of implying it.

---

### `.github/workflows/release-please.yml` (CI workflow, event-driven)

**Analog:** `.github/workflows/release-please.yml`

**Pinned-action + custom sync pattern** (`.github/workflows/release-please.yml:16-22,24-32`):
```yaml
- id: release
  uses: googleapis/release-please-action@5c625b...
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    config-file: release-please-config.json
    manifest-file: .release-please-manifest.json

# Path 2 fix: release-please's `extra-files` generic updater silently
# no-ops ...
```

**Guarded sed-sync pattern** (`.github/workflows/release-please.yml:53-82,84-96`):
```bash
NEW_VERSION=$(jq -r '.["mailglass_admin"]' .release-please-manifest.json)
...
matches=$(grep -cE "\{:${dep}, \"== [0-9]+\.[0-9]+\.[0-9]+\"\}" "$path" || true)
if [ "$matches" -eq 0 ]; then
  echo "ERROR: sed anchor regex matched zero lines in $path." >&2
  exit 1
fi

sed -i -E "s/\{:${dep}, \"== ...\"\}/{:${dep}, \"== ${NEW_VERSION}\"}/" "$path"
...
git commit -m "chore(release-please): sync ..."
```

**What to copy:** release mechanics here favor pinned actions, explicit comments, and hard guards around nonstandard behavior. Any Phase 13 rehearsal or token-path adjustment should preserve that style.

---

### `.github/workflows/publish-hex.yml` (CI workflow, event-driven)

**Analog:** `.github/workflows/publish-hex.yml`

**Dual-entry publish invocation pattern** (`.github/workflows/publish-hex.yml:3-25`):
```yaml
on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      tag: ...
      dry_run: ...
      package: ...
```

**Prepublish summary + CI gate pattern** (`.github/workflows/publish-hex.yml:35-69,71-109`):
```yaml
prepublish-summary:
  ...
  - run: mix mailglass.publish.check --package mailglass ...
  - run: mix mailglass.publish.check --package mailglass_admin ...

gate-ci-green:
  ...
  if (data.total_count === 0) {
    core.setFailed(`Delivery blocked: no ci.yml runs found ...`);
  }
```

**Idempotent publish pattern** (`.github/workflows/publish-hex.yml:135-171,220-245`):
```bash
VERSION=$(grep -E '@version "[0-9]' mix.exs ...)
if mix hex.info mailglass "${VERSION}" 2>/dev/null | grep -q "Released:"; then
  echo "Version ${VERSION} of mailglass already on Hex — skipping publish ..."
fi
...
mix hex.publish --yes
...
until mix hex.info mailglass "${VERSION}" 2>/dev/null; do
  ...
done
```

**Sibling publish dependency pattern** (`.github/workflows/publish-hex.yml:210-219`):
```yaml
working-directory: mailglass_admin
env:
  MIX_PUBLISH: "true"
run: mix deps.get
```

**What to copy:** Phase 13 publish work should extend the existing `release` + `workflow_dispatch` split rather than inventing a second publish workflow. The repo already treats manual dispatch as the fallback path.

---

### `.github/workflows/post-publish-smoke.yml` (CI workflow, event-driven)

**Analog:** `.github/workflows/post-publish-smoke.yml`

**Trigger normalization pattern** (`.github/workflows/post-publish-smoke.yml:24-99`):
```javascript
const normalizeVersion = (value) => {
  ...
  const match = raw.match(/(?:^|[-/])v?(\d+\.\d+\.\d+(?:[-\w.+]+)?)/);
  return match ? match[1] : raw.replace(/^v/, "");
};
...
core.setOutput('should_run', 'true');
core.setOutput('version', version);
```

**Wait-for-index / wait-for-docs pattern** (`.github/workflows/post-publish-smoke.yml:101-192`):
```bash
until mix hex.info mailglass "${VERSION}" >/dev/null 2>&1; do
  ...
done
...
until curl -fsI "https://hexdocs.pm/mailglass/${VERSION}/" >/dev/null 2>&1; do
  ...
done
```

**Consumer-install smoke pattern** (`.github/workflows/post-publish-smoke.yml:223-285`):
```yaml
- run: mix archive.install hex phx_new --force
- run: mix phx.new sandbox --module Sandbox --app sandbox --no-ecto --no-mailer --install
- run: mix deps.get
- run: mix mailglass.install
- run: mix compile --warnings-as-errors
- run: mix phx.server & ... curl -fsI http://localhost:4000/dev/mail/
```

**Failure-notification pattern** (`.github/workflows/post-publish-smoke.yml:328-360`):
```yaml
notify-on-failure:
  if: failure() && needs.cron-guard.outputs.should_run == 'true'
  ...
  uses: actions/github-script@...
```

**What to copy:** this is the strongest analog for REL-14 and REL-16. Phase 13 rehearsal and smoke work should extend this workflow shape rather than build a separate matrix.

---

### `lib/mix/tasks/mailglass.publish.check.ex` (mix-task, batch)

**Analog:** `lib/mix/tasks/mailglass.publish.check.ex`

**Ordered-contract pattern** (`lib/mix/tasks/mailglass.publish.check.ex:6-40`):
```elixir
@moduledoc """
Verify the published tarball before Hex.pm release.
...
## Pre-publish checks (in order)
  1. Installer goldens ...
  7. Check CHANGELOG section
  10. Check linked-version constraint
  12. Compile tarball in isolation
"""
```

**Step-runner pattern** (`lib/mix/tasks/mailglass.publish.check.ex:84-157`):
```elixir
{counts, ctx} = step(counts, :unchanged, package, "check CHANGELOG section", ctx, &verify_changelog/1)
...
Mix.shell().info(
  "Pre-publish check result for #{ctx.package}: create=#{counts.create} ..."
)
```

**What to copy:** release-facing mix tasks here are strict, ordered, and brand their failures as `Delivery blocked: ...`. If Phase 13 adds changelog-narrative or size-budget enforcement, `mailglass.publish.check` is the right seam.

---

### `lib/mix/tasks/mailglass.upgrade.v0_2.ex` + upgrade tests (mix-task/test, transform)

**Analogs:** `lib/mix/tasks/mailglass.upgrade.v0_2.ex`, `test/mailglass/upgrade/v0_2_test.exs`

**Current codemod transform pattern** (`lib/mix/tasks/mailglass.upgrade.v0_2.ex:11-34,47-66`):
```elixir
use Igniter.Mix.Task
...
if igniter.args.options[:apply] do
  igniter
else
  Igniter.assign(igniter, :dry_run?, true)
end
...
IO.warn("Skipping unknown Swoosh.Email function: #{function_name}/#{length(args || [])}")
```

**AST test harness pattern** (`test/mailglass/upgrade/v0_2_test.exs:17-113`):
```elixir
igniter
|> Igniter.Project.Module.create_module(MyApp.Dummy, """ ... """)
|> Igniter.compose_task(Mix.Tasks.Mailglass.Upgrade.V0_2)
|> apply_igniter!()

assert_file_content(igniter, "lib/my_app/dummy.ex", """ ... """)
```

**What to copy:** use Igniter test-project fixtures for safe-rewrite assertions, and add explicit tests for ambiguous-case warning text instead of relying on docs alone.

**Planner note:** there is no current test that asserts the warning includes a migration-guide URL, and no committed real v0.1 host fixture upgraded end-to-end by `mix mailglass.upgrade.v0_2`.

---

### Installer, smoke, and rehearsal tests (tests/docs, file-I/O / request-response)

**Analogs:** `test/mailglass/install/install_idempotency_test.exs`, `test/mailglass/install/install_first_preview_smoke_test.exs`, `mailglass_admin/test/mailglass_admin/post_installer_smoke_test.exs`, `test/example/README.md`, `test/fixtures/release_please_sed_test.sh`

**Idempotency + force-repair pattern** (`test/mailglass/install/install_idempotency_test.exs:9-25,37-100`):
```elixir
run_install!(fixture_root, [])
...
assert before_second_run == after_second_run
...
run_install!(fixture_root, ["--force"])
assert runtime_conflict_sidecars(fixture_root) == []
```

**Time-bounded scaffold smoke pattern** (`test/mailglass/install/install_first_preview_smoke_test.exs:6-23`):
```elixir
@tag timeout: 300_000
...
run_install!(fixture_root, [])
...
assert elapsed_ms < 300_000
```

**Route/endpoint smoke pattern** (`mailglass_admin/test/mailglass_admin/post_installer_smoke_test.exs:24-48`):
```elixir
@tag :admin_smoke
conn = get(conn, "/dev/mail/")
assert conn.status in [200, 302]
...
routes = MailglassAdmin.TestAdopter.Router.__routes__()
assert Enum.any?(routes, fn r -> r.verb == :get and r.path == "/dev/mail" end)
```

**Fixture-host golden ledger pattern** (`test/example/README.md:7-24,33-55,114-166`):
```markdown
Golden snapshots are stored in this file so updates are visible in pull requests.
...
- config/runtime.exs sha256:...
...
@@ lib/example_web/router.ex
defmodule ExampleWeb.Router do
  ...
  mailglass_admin_routes "/mail"
```

**Shell regression harness pattern** (`test/fixtures/release_please_sed_test.sh:16-29`):
```bash
set -euo pipefail
...
sed -i -E "s/\{:mailglass, \"== ...\"\}/{:mailglass, \"== ${NEW_VERSION}\"}/" "${TMP}/mix.exs"
diff -u "${FIXTURE_DIR}/mix.exs.after" "${TMP}/mix.exs"
```

**What to copy:** Phase 13 validation should prefer fixture-backed, fail-loud smoke tests over mock-heavy unit tests. The repo already uses temporary host apps, golden ledgers, route assertions, and tiny shell regression harnesses for release-critical mechanics.

## Shared Patterns

### Brand-voice failure messages
**Sources:** `lib/mix/tasks/mailglass.publish.check.ex:65-79`, `lib/mix/tasks/mailglass.docs.check.ex:40-60`, `.github/workflows/publish-hex.yml:100-109`
**Apply to:** release tasks, workflow failure output, doc gates
```elixir
Mix.raise("Delivery blocked: ...")
```

### Linked-version sibling release contract
**Sources:** `release-please-config.json`, `.release-please-manifest.json`, `mailglass_admin/mix.exs:107-120`
**Apply to:** changelog coordination, Release Please review, publish workflow
```json
"plugins": [
  {
    "type": "linked-versions",
    "groupName": "mailglass-sibling-group",
    "components": ["mailglass", "mailglass_admin"]
  }
]
```
```elixir
if System.get_env("MIX_PUBLISH") == "true" do
  {:mailglass, "== 0.1.1"}
else
  {:mailglass, path: "..", override: true}
end
```

### Smoke first waits, then exercises real adopter path
**Sources:** `.github/workflows/post-publish-smoke.yml:101-192,223-285`, `MAINTAINING.md:95-113`
**Apply to:** publish/smoke/rehearsal work
```bash
until mix hex.info ...; do ...; done
until curl -fsI "https://hexdocs.pm/..." >/dev/null 2>&1; do ...; done
mix phx.new sandbox ...
mix mailglass.install
mix compile --warnings-as-errors
curl -fsI http://localhost:4000/dev/mail/
```

### Public docs are treated as executable contract surfaces
**Sources:** `test/mailglass/docs_migration_smoke_test.exs:7-30`, `lib/mix/tasks/mailglass.docs.check.ex:22-49`
**Apply to:** Tier 1 docs and upgrade guide
```elixir
code = extract_block_after_heading(@guide_path, "End-to-End Example")
assert {:ok, _quoted} = Code.string_to_quoted(code)
```

## No Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `CHANGELOG.md` v0.2.0 curated migration-front-door entry | docs | release-ledger | No existing entry includes explicit `breaking changes`, `upgrade path`, `minimum dependency matrix`, `escape hatch`, and `rollback` sections in one release note. |
| Release rehearsal workflow or script for pre-cut dry run | workflow/script | event-driven | Repo has publish + post-publish smoke, but no dedicated rehearsal artifact that exercises the current Release Please path before the real cut. |
| Tier 1 stale-version / stale-API docs gate | mix-task/test | batch | Existing `mailglass.docs.check` only blocks leaked internal IDs; it does not detect `~> 0.1`, stale alias names, or outdated command surfaces. |
| Real v0.1 adopter fixture upgrade test for `mix mailglass.upgrade.v0_2` | test | transform | Current upgrade tests are AST-level only; no existing fixture proves zero-manual-edit upgrade for safe cases and warning-path behavior for ambiguous cases. |

## Metadata

**Analog search scope:** root docs, `guides/`, `.github/workflows/`, `lib/mix/tasks/`, `test/mailglass/`, `mailglass_admin/test/`, `test/example/`, prior Phase 8 artifacts  
**Project instructions read:** `CLAUDE.md`  
**Skills directories present:** none under repo-local `.claude/skills/` or `.agents/skills/`  
**Pattern extraction date:** 2026-04-28
