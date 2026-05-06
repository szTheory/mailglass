# Phase 38: Release Rehearsal and Proof Artifacts - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/mailglass.publish.check.ex` | utility | transform | `lib/mix/tasks/mailglass.publish.check.ex` | exact |
| `mix.exs` | config | transform | `mix.exs` | exact |
| `mailglass_admin/mix.exs` | config | transform | `mailglass_admin/mix.exs` | exact |
| `mailglass_admin/test/mailglass_admin/mix_config_test.exs` | test | transform | `mailglass_admin/test/mailglass_admin/mix_config_test.exs` | exact |
| `test/mailglass/install/install_first_preview_smoke_test.exs` | test | request-response | `test/mailglass/install/install_first_preview_smoke_test.exs` | exact |
| `.github/workflows/post-publish-smoke.yml` | config | batch | `.github/workflows/post-publish-smoke.yml` | exact |
| `test/mailglass/docs_migration_smoke_test.exs` | test | transform | `test/mailglass/docs_migration_smoke_test.exs` | exact |
| `guides/upgrading-to-v1_0.md` | utility | transform | `guides/upgrading-to-v1_0.md` | exact |
| `README.md` | utility | transform | `README.md` | exact |
| `guides/getting-started.md` | utility | transform | `guides/getting-started.md` | exact |
| `MAINTAINING.md` | utility | batch | `MAINTAINING.md` | exact |
| `.github/workflows/publish-hex.yml` | config | batch | `.github/workflows/publish-hex.yml` | exact |
| `.github/workflows/release-please.yml` | config | batch | `.github/workflows/release-please.yml` | exact |
| `.github/workflows/branch-protection-drift.yml` | config | batch | `.github/workflows/branch-protection-drift.yml` | exact |
| `scripts/setup_branch_protection.sh` | utility | batch | `scripts/setup_branch_protection.sh` | exact |
| `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-01-PREPUBLISH-PROOF.md` | utility | transform | `.planning/milestones/v0.4-phases/27-release-install-closure/27-02-EVIDENCE.md` | partial |
| `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-02-REHEARSAL-EVIDENCE.md` | utility | request-response | `.planning/milestones/v0.2-phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md` | role-match |
| `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md` | utility | batch | `MAINTAINING.md` | role-match |
| `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md` | utility | batch | `.planning/milestones/v0.2-phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md` | role-match |
| `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-BRANCH-PROTECTION-NOTE.md` | utility | batch | `.github/workflows/branch-protection-drift.yml` + `scripts/setup_branch_protection.sh` | partial |

`38-01/02/03` filenames above are inferred from `38-RESEARCH.md` slice boundaries and `38-VALIDATION.md` task groupings; exact names remain discretionary, but planner should keep them phase-local and one-file-per-proof concern.

## Pattern Assignments

### `lib/mix/tasks/mailglass.publish.check.ex` (utility, transform)

**Analog:** `lib/mix/tasks/mailglass.publish.check.ex`

**CLI + staged step pattern** (`lib/mix/tasks/mailglass.publish.check.ex:46-58`, `85-158`):
```elixir
def run(argv) do
  {opts, rest, invalid} = OptionParser.parse(argv, strict: [package: :string, keep: :boolean])
  validate_cli!(rest, invalid)

  with_disabled_otel(fn ->
    Mix.Task.run("app.start")

    packages(opts[:package])
    |> Enum.each(fn package ->
      execute_package(package, opts[:keep] == true)
    end)
  end)
end
```
```elixir
{counts, ctx} = step(counts, :create, package, "capture file list", ctx, &capture_file_list/1)
{counts, ctx} = step(counts, :unchanged, package, "compare allowlist", ctx, &verify_allowlist/1)
{counts, ctx} = step(counts, :unchanged, package, "check linked-version constraint", ctx, &verify_linked_constraint/1)
{counts, ctx} = step(counts, :update, package, "write reviewer summary", ctx, &write_summary/1)
```

**Context loading pattern** (`180-214`):
```elixir
manifest = read_manifest(Path.join(repo_root, ".release-please-manifest.json"))

%{
  package: package,
  package_name: to_string(package),
  source_path: source_path,
  version: version,
  manifest: manifest,
  manifest_version: manifest_version(manifest, package),
  expected_file: Path.join(repo_root, ".planning/publish/#{package}-files.expected"),
  summary_path: System.get_env("GITHUB_STEP_SUMMARY")
}
```

**Proof export pattern** (`966-1020`):
```elixir
summary =
  [
    "## Pre-publish check: #{ctx.package_name} v#{ctx.version}",
    "",
    "| Field | Value |",
    "|---|---|",
    "| Package | #{ctx.package_name} |",
    "| Version delta | #{version_delta} |",
    "| File count | #{length(ctx.files)} |",
    "| Total size | #{ctx.total_bytes} (#{size_mb} MB) |"
  ] ++
    Enum.map(top_files, fn file -> "| #{file.path} | #{file.size} |" end)

File.write!(ctx.summary_path, Enum.join(summary, "\n") <> "\n", [:append])
```

Use this exact step-oriented style for any Phase 38 export additions. Do not create a second checker; add export/summarization around existing facts.

---

### `mix.exs` and `mailglass_admin/mix.exs` (config, transform)

**Analogs:** `mix.exs`, `mailglass_admin/mix.exs`

**Root package/files/docs pattern** (`mix.exs:288-345`):
```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    source_ref_pattern: "mailglass-sibling-group-v%{version}",
    files:
      ~w(lib priv/gettext guides mix.exs LICENSE README.md CHANGELOG.md MAINTAINING.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md)
  ]
end

defp docs do
  [
    main: "getting-started",
    homepage_url: @source_url,
    source_url: @source_url,
    source_ref: "v#{@version}",
    extras: [...],
    groups_for_extras: [...]
  ]
end
```

**Sibling package exact-pin + docs pattern** (`mailglass_admin/mix.exs:126-132`, `162-199`):
```elixir
defp mailglass_dep do
  if System.get_env("MIX_PUBLISH") == "true" do
    {:mailglass, "== 0.3.2"}
  else
    {:mailglass, path: "..", override: true}
  end
end
```
```elixir
defp package do
  [
    name: "mailglass_admin",
    source_ref_pattern: "mailglass-sibling-group-v%{version}",
    links: %{
      "GitHub" => @source_url,
      "HexDocs" => "https://hexdocs.pm/mailglass_admin"
    },
    files: ~w(lib priv/static docs .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
  ]
end
```

For docs-input proof artifacts, copy these exact data sources: `package.files`, `docs.extras`, `docs.groups_for_extras`, `source_url`, `source_ref`, and `source_ref_pattern`.

---

### `mailglass_admin/test/mailglass_admin/mix_config_test.exs` (test, transform)

**Analog:** `mailglass_admin/test/mailglass_admin/mix_config_test.exs`

**Published-pin proof pattern** (`45-53`, `107-121`):
```elixir
System.put_env("MIX_PUBLISH", "true")
version = Mix.Project.config()[:version]
dep_tuple = evaluate_mailglass_dep()

assert {:mailglass, pin} = dep_tuple
assert pin == "== #{version}"
```
```elixir
sed_anchor = ~r/\{:mailglass, "== \d+\.\d+\.\d+"\}/

assert Regex.match?(sed_anchor, source),
       """
       release-please.yml sed step anchors on the literal
       `{:mailglass, "== <semver>"}` form.
       """
```

If Phase 38 changes sibling-version proof wording or export shape, keep this test as the authoritative behavioral proof for the literal publish-mode pin.

---

### `test/mailglass/install/install_first_preview_smoke_test.exs` and `.github/workflows/post-publish-smoke.yml` (test/config, request-response + batch)

**Analogs:** `test/mailglass/install/install_first_preview_smoke_test.exs`, `.github/workflows/post-publish-smoke.yml`

**Repo-local install smoke assertions** (`test/mailglass/install/install_first_preview_smoke_test.exs:7-37`):
```elixir
assert runtime =~ "config :swoosh, :api_client, false"
refute runtime =~ ~r/^\s*config :swoosh, :api_client, Swoosh\.ApiClient\.Finch\b/m

workflow = File.read!(workflow_path)
assert workflow =~ "Run mix mailglass.install"
assert workflow =~ "Compile, fail on warnings"
assert workflow =~ "Boot endpoint and curl /dev/mail/"
assert workflow =~ "GET /dev/mail/ → HTTP ${STATUS}"
```

**Consumer-install workflow steps** (`.github/workflows/post-publish-smoke.yml:230-323`):
```yaml
consumer-install:
  name: Consumer install (Phoenix host)
  needs: [cron-guard, wait-for-hexdocs]
```
```yaml
- name: Generate Phoenix host project
  run: |
    mix phx.new sandbox --module Sandbox --app sandbox --no-ecto --no-mailer --install
- name: Run mix mailglass.install
  run: mix mailglass.install
- name: Compile, fail on warnings
  run: |
    mix compile --warnings-as-errors 2>&1 | tee compile.log
- name: Boot endpoint and curl /dev/mail/
  run: |
    STATUS=$(curl -fs -o /dev/null -w "%{http_code}" http://localhost:4000/dev/mail/)
    echo "GET /dev/mail/ → HTTP ${STATUS}"
```

**Version-resolution/fallback guard** (`1-16`, `39-84`):
```yaml
workflow_dispatch:
  # fallback-only for manual recovery or rehearsal;
  # supply the published tag via `inputs.tag`.
```
```js
if (eventName === 'workflow_dispatch' && inputVersion) {
  core.setOutput('should_run', 'true');
  core.setOutput('version', inputVersion);
}
```

Any new install evidence doc should mirror this exact command order and sentinel wording.

---

### `test/mailglass/docs_migration_smoke_test.exs` and `guides/upgrading-to-v1_0.md` (test/utility, transform)

**Analogs:** `test/mailglass/docs_migration_smoke_test.exs`, `guides/upgrading-to-v1_0.md`

**Canonical-upgrade-authority proof** (`test/mailglass/docs_migration_smoke_test.exs:25-42`):
```elixir
assert canonical =~ "canonical latest-`0.x` to `1.0` upgrade guide"
assert canonical =~ "| surface | replacement | warning channel | `--warnings-as-errors` impact | support-until version | proof artifact |"
assert canonical =~ "Mailglass.Outbound.send/2"
assert canonical =~ "mix mailglass.upgrade.v0_2"

assert older =~ "subordinate codemod reference"
assert swoosh =~ "subordinate raw-Swoosh migration reference"
```

**Strict proof commands** (`guides/upgrading-to-v1_0.md:214-230`):
```bash
mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors
mix docs --warnings-as-errors
mix compile --no-optional-deps --warnings-as-errors
```
```bash
cd mailglass_admin
mix docs --warnings-as-errors
```

**Guide structure to preserve** (`guides/upgrading-to-v1_0.md:3-15`, `31-43`, `136-142`):
```md
This is the canonical latest-`0.x` to `1.0` upgrade guide for Mailglass.
...
Your `1.0` target state is:
- delivery through `Mailglass.deliver/2`
- message authoring through native `Mailglass.Message` setters
- matched `mailglass` and `mailglass_admin` release lines
```

Phase 38 upgrade rehearsal evidence should quote commands and outcomes from this guide, not invent a second upgrade script.

---

### `README.md` and `guides/getting-started.md` (utility, transform)

**Analogs:** `README.md`, `guides/getting-started.md`

**Public install-story shape** (`README.md:36-56`, `65-74`):
```md
## Installation
...
{:mailglass, "~> 0.3"},
{:mailglass_admin, "~> 0.3", only: [:dev]}
```
```bash
mix deps.get
mix mailglass.install
mix ecto.migrate
mix compile
```

**Guide shape** (`guides/getting-started.md:12-19`, `33-54`, `56-77`):
```md
## 1) Install and verify
```
```bash
mix deps.get
mix mailglass.install
mix ecto.migrate
mix compile
```
```elixir
if Application.compile_env(:my_app, :dev_routes) do
  scope "/dev" do
    pipe_through :browser
    mailglass_admin_routes "/mail"
  end
end
```

If these docs are touched for Phase 38, keep them recommendation-first and aligned with the smoke workflow wording.

---

### `MAINTAINING.md`, `.github/workflows/publish-hex.yml`, and `.github/workflows/release-please.yml` (utility/config, batch)

**Analogs:** `MAINTAINING.md`, `.github/workflows/publish-hex.yml`, `.github/workflows/release-please.yml`

**Runbook/checklist pattern** (`MAINTAINING.md:107-160`):
```md
1. **Verify CI green on `main` for the SHA to be released.**
2. **Merge the release-please PR.**
3. **Approve the `hex-publish` deployment in the GitHub Environment UI.**
4. **Within 60 minutes of publish: smoke-install in a fresh Phoenix app.**
```
```md
If publish succeeds but smoke does not fan out, use `workflow_dispatch` on
`.github/workflows/post-publish-smoke.yml` with that same core tag.
```

**Prepublish summary + environment gate pattern** (`.github/workflows/publish-hex.yml:41-107`, `148-209`):
```yaml
prepublish-summary:
  ...
  - name: Pre-publish check for mailglass
    run: |
      echo "## mailglass" >> "$GITHUB_STEP_SUMMARY"
      mix mailglass.publish.check --package mailglass 2>&1 | tee -a "$GITHUB_STEP_SUMMARY"
```
```yaml
publish-core:
  needs: [gate-ci-green]
  environment: hex-publish
```

**Linked-version sync pattern** (`.github/workflows/release-please.yml:29-37`, `47-103`):
```yaml
# linked-version dep pin is custom, so the release PR is not a vanilla
# release-please artifact.
```
```bash
NEW_VERSION=$(jq -r '.["mailglass_admin"]' .release-please-manifest.json)
sed -i -E "s/\{:${dep}, \"== [0-9]+\.[0-9]+\.[0-9]+\"\}/{:${dep}, \"== ${NEW_VERSION}\"}/" "$path"
git commit -m "chore(release-please): sync mailglass_admin -> mailglass dep pin to == $NEW_VERSION"
```

For Phase 38 release-proof docs, copy the repo's current distinction: repo-proved steps stay in workflow/task outputs; external steps demand explicit run URLs, approver identity, tag, Hex/HexDocs URLs, and timer result.

---

### `.github/workflows/branch-protection-drift.yml` and `scripts/setup_branch_protection.sh` (config/utility, batch)

**Analogs:** `.github/workflows/branch-protection-drift.yml`, `scripts/setup_branch_protection.sh`

**Honest external-debt pattern** (`.github/workflows/branch-protection-drift.yml:12-16`, `30-58`):
```yaml
# Requires the BRANCH_PROTECTION_PAT secret
# If the secret is unset, the job no-ops and posts a notice in the
# workflow summary.
```
```yaml
- name: Check for BRANCH_PROTECTION_PAT secret
  ...
  echo "BRANCH_PROTECTION_PAT secret not set."
```

**Helper asset pattern** (`scripts/setup_branch_protection.sh:28-31`, `35-47`, `68-77`):
```bash
if [ -z "${GH_TOKEN:-}" ]; then
  echo "Delivery blocked: GH_TOKEN not set. Provide an admin PAT with 'repo' scope."
  exit 1
fi
```
```bash
REQUIRED_CHECKS=(
  "Tests (Elixir 1.18 / OTP 27)"
  "Credo Strict (Elixir 1.18 / OTP 27)"
  "Dialyzer (Elixir 1.18 / OTP 27)"
  "actionlint"
  "PR title (semantic)"
)
```

If planner keeps branch protection manual for Phase 38, the checklist should explicitly reference this as non-authoritative helper state rather than claiming repo enforcement.

---

### New Phase-Local Proof Docs (utility)

#### `38-01-PREPUBLISH-PROOF.md`

**Analogs:** `.planning/milestones/v0.4-phases/27-release-install-closure/27-02-EVIDENCE.md`, `lib/mix/tasks/mailglass.publish.check.ex:966-1020`

**Doc shape to copy** (`27-02-EVIDENCE.md:1-19`):
```md
# Phase 27 — REL-18 Rehearsal Evidence

**Proof selected:** ...
**Date deferred:** ...
**Forward-pointer:** ...

## Why deferred
- ...

## Pre-shipping confidence
- ...
```

Use that compact summary style, but populate it with Phase 38 facts: allowlist source files, manifest versions, publish-check summary data, docs inputs, and sibling pin truth.

#### `38-02-REHEARSAL-EVIDENCE.md` and `38-03-RELEASE-RECORD.md`

**Analog:** `.planning/milestones/v0.2-phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md`

**Evidence-record shape** (`13-04-REHEARSAL.md:1-18`, `21-37`):
```md
# Phase 13 Plan 04 Release Rehearsal

Date: ...
Scope: ...

Rehearsal ref: ...
Release Please run URL: ...
Publish rehearsal run URL: ...
Smoke evidence URL: ...
Outcome: ...
Fallback decision: ...
```
```md
## Evidence
- ...

## Rehearsed Contract For 0.2.0
1. ...
```

Use this exact "header facts first, then evidence bullets, then rehearsed contract" pattern for both install/upgrade rehearsal evidence and the real release record.

#### `38-03-RELEASE-CHECKLIST.md`

**Analog:** `MAINTAINING.md:107-160`

Keep the checklist as a numbered maintainer runbook with proof-value fields, not prose paragraphs. Each item should demand concrete capture: tag, workflow run URL, approver identity, timestamp, HTTP 200, Hex package URL, HexDocs URL, revert-window outcome.

## Shared Patterns

### Existing checks are the source of truth
**Source:** `lib/mix/tasks/mailglass.publish.check.ex:85-158`, `lib/mix/tasks/mailglass.docs.check.ex:188-205`
```elixir
{counts, ctx} = step(counts, :update, package, "write reviewer summary", ctx, &write_summary/1)
...
if issues == [] do
  Mix.shell().info("[mailglass.docs.check] OK — Tier 1 docs match the stability contract.")
else
  Mix.raise("Delivery blocked: #{length(issues)} Tier 1 docs issue(s) found.")
end
```
Apply to all Phase 38 work: export or summarize existing truth, do not re-derive it.

### Literal branded failure messages
**Source:** `lib/mix/tasks/mailglass.publish.check.ex:66-80`, `scripts/setup_branch_protection.sh:28-31`
```elixir
Mix.raise("Delivery blocked: unknown args #{flags}")
```
```bash
echo "Delivery blocked: GH_TOKEN not set. Provide an admin PAT with 'repo' scope."
```
New automation/docs-facing proof commands should preserve this direct "Delivery blocked:" failure style.

### Install smoke must stay mirror-aligned across test and workflow
**Source:** `test/mailglass/install/install_first_preview_smoke_test.exs:30-35`, `.github/workflows/post-publish-smoke.yml:285-323`
```elixir
assert workflow =~ "Run mix mailglass.install"
assert workflow =~ "GET /dev/mail/ → HTTP ${STATUS}"
```
```yaml
- name: Run mix mailglass.install
- name: Boot endpoint and curl /dev/mail/
```
Any phase-local rehearsal doc should follow this same command order verbatim.

### Upgrade proof is guide-backed, not fixture-invented
**Source:** `test/mailglass/docs_migration_smoke_test.exs:25-42`, `guides/upgrading-to-v1_0.md:214-230`
```elixir
assert canonical =~ "canonical latest-`0.x` to `1.0` upgrade guide"
```
```bash
mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors
mix docs --warnings-as-errors
```
Any upgrade rehearsal artifact should report the canonical guide and these strict commands as the authority.

### Manual-only release truth must name evidence fields
**Source:** `MAINTAINING.md:125-160`, `.planning/milestones/v0.2-phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md:6-18`
```md
Release Please run URL: ...
Publish rehearsal run URL: ...
Smoke evidence URL: ...
Outcome: ...
Fallback decision: ...
```
```md
Approve the `hex-publish` deployment in the GitHub Environment UI.
Within 60 minutes of publish: smoke-install in a fresh Phoenix app.
```
Use explicit fields, never "looks good" text.

## No Analog Found

None. Every Phase 38 surface has a close repo analog, even where the exact phase-local filenames remain discretionary.

## Metadata

**Analog search scope:** `.planning/phases/38-release-rehearsal-and-proof-artifacts/`, `.planning/milestones/v0.2-phases/13-v0-2-release-ceremony/`, `.planning/milestones/v0.4-phases/27-release-install-closure/`, `.github/workflows/`, `lib/mix/tasks/`, `test/mailglass/install/`, `test/mailglass/`, `mailglass_admin/test/mailglass_admin/`, repo-root docs, `guides/`, `scripts/`, `.planning/publish/`

**Files scanned:** 18 direct analog files + 2 phase input files

**Pattern extraction date:** 2026-05-06
