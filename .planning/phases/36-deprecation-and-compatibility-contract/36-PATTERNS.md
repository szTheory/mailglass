# Phase 36: Deprecation and Compatibility Contract - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/compatibility.md` or equivalent canonical compatibility guide | documentation | informational | `guides/unsubscribe.md`, `guides/migration-from-swoosh.md` | role-match |
| `guides/upgrading-to-v1_0.md` or equivalent canonical `0.x -> 1.0` guide | documentation | transform | `guides/upgrading-from-v0_1.md` | exact |
| `docs/api_stability.md` | documentation | informational | `docs/api_stability.md` | exact |
| `mailglass_admin/docs/api_stability.md` | documentation | informational | `mailglass_admin/docs/api_stability.md` | exact |
| `README.md` | documentation | informational | `README.md` | exact |
| `mailglass_admin/README.md` | documentation | informational | `mailglass_admin/README.md` | exact |
| `MAINTAINING.md` | documentation | batch | `MAINTAINING.md` | exact |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `mailglass_admin/mix.exs` | config | batch | `mailglass_admin/mix.exs` | exact |
| `lib/mix/tasks/mailglass.docs.check.ex` | task | batch | `lib/mix/tasks/mailglass.docs.check.ex` | exact |
| `lib/mix/tasks/mailglass.stability.check.ex` | task | batch | `lib/mix/tasks/mailglass.stability.check.ex` | exact |
| `test/mailglass/docs_contract_test.exs` | test | contract | `test/mailglass/docs_contract_test.exs` | exact |
| `test/mailglass/docs_migration_smoke_test.exs` | test | contract | `test/mailglass/docs_migration_smoke_test.exs` | exact |
| `test/mailglass/docs/compatibility_guide_test.exs` or equivalent new docs test | test | contract | `test/mailglass/docs/unsubscribe_guide_test.exs` | role-match |
| `scripts/verify_support_contract.sh` | utility | batch | `scripts/verify_support_contract.sh` | exact |
| `.github/workflows/ci.yml` and/or `.github/workflows/advisory-matrix.yml` | config | batch | `.github/workflows/ci.yml`, `.github/workflows/advisory-matrix.yml` | exact |

## Pattern Assignments

### Canonical compatibility guide (`guides/compatibility.md` or equivalent)

**Analog:** `guides/unsubscribe.md`, `guides/migration-from-swoosh.md`, `README.md`

**Guide structure pattern** (`guides/unsubscribe.md:1-29`, `guides/migration-from-swoosh.md:1-32`):
```markdown
# RFC 8058 Unsubscribe

This guide is the adopter contract for ...

## 1) Configure ...
## 2) Mount ...
## 3) Use ...
```

```markdown
# Migration from raw Swoosh

## Prerequisites
- ...

## 1) Install ...
## 2) Move ...
```

**Contract-entrypoint wording pattern** (`README.md:130-144`):
```markdown
The canonical `v1.x` contract inventory for the core package lives in
[`docs/api_stability.md`](docs/api_stability.md).

Use that document, not root-module reachability, as the source of truth for:
```

**Planner guidance:** make the new guide the single adopter-facing source for versioning policy, deprecation policy, support matrix, and links to subordinate guides. Keep the tone narrow and declarative. Use numbered sections, bullets, short code-free policy prose, and explicit exception clauses.

### Canonical `0.x -> 1.0` upgrade guide (`guides/upgrading-to-v1_0.md` or equivalent)

**Analog:** `guides/upgrading-from-v0_1.md`

**Before/after migration pattern** (`guides/upgrading-from-v0_1.md:5-54`):
```markdown
## Before/After Examples

# v0.1 Mailable
...

# v0.2 Mailable
...
```

**Codemod + warning-channel pattern** (`guides/upgrading-from-v0_1.md:56-112`):
```markdown
`mix mailglass.upgrade.v0_2` is an Igniter-backed codemod. Use it as a dry-run first, then apply once the diff looks right.

## Ambiguous Cases / Recipes

The codemod rewrites only the eight setters above...

Skipping unknown Swoosh.Email function: put_provider_option/2...
```

**Troubleshooting/footer pattern** (`guides/upgrading-from-v0_1.md:142-161`):
```markdown
## Troubleshooting

### Codemod skips my mailables
- ...

---

*Last updated: 2026-05-03 (Phase 31 ships at v0.1).*
```

**Planner guidance:** keep the existing guide style: explicit before/after code, ordered steps, ambiguous-case section, strict-CI notes, and troubleshooting. For Phase 36, add a deprecation inventory table with replacement, warning channel, `--warnings-as-errors` impact, and support-until version.

### Stability inventories (`docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`)

**Analog:** existing package-local inventory docs

**Contract posture pattern** (`docs/api_stability.md:21-89`, `mailglass_admin/docs/api_stability.md:10-43`):
```markdown
### `stable`
- ...

### `internal`
- ...

### `sibling-package-only`
- ...
```

```markdown
### `stable`
- `MailglassAdmin.Router.mailglass_admin_routes/2`
...

### `internal`
- LiveView modules, component modules, layouts...
```

**Legacy/non-stable wording pattern** (`docs/api_stability.md:124-145`):
```markdown
Generator and legacy-upgrade tasks remain useful tooling, but they are not part
of the narrow `v1.x` stable contract unless and until they are listed here.
```

**Planner guidance:** do not move the full compatibility story into these files. Keep them as stable/internal inventories, then add links outward to the canonical compatibility guide and the canonical upgrade guide. If deprecated or legacy bridges are called out here, keep them inventory-style and terse.

### Root README contract pointers

**Analog:** `README.md`

**API stability entrypoint pattern** (`README.md:130-144`):
```markdown
## API Stability

The canonical `v1.x` contract inventory for the core package lives in
[`docs/api_stability.md`](docs/api_stability.md).
```

**Packages table pattern** (`README.md:195-201`):
```markdown
| `mailglass`         | `v1.x` contract inventory documented in `docs/api_stability.md` | ... |
| `mailglass_admin`   | Narrow `v1.x` admin contract documented separately | ... |
| `mailglass_inbound` | v0.5+ | ... |
```

**Documentation index pattern** (`README.md:218-234`):
```markdown
- [`guides/upgrading-from-v0_1.md`](guides/upgrading-from-v0_1.md) —
  codemod-backed upgrade path for existing adopters
```

**Planner guidance:** add one compatibility-guide link in the API Stability or Documentation section, then adjust package/support wording there. Do not duplicate detailed support policy inside the README.

### Admin README contract pointers

**Analog:** `mailglass_admin/README.md`

**Narrow-contract wording pattern** (`mailglass_admin/README.md:13-26`):
```markdown
That contract is intentionally narrow:

- stable: router macros...
- internal: LiveView modules, component modules, DOM/CSS shape...
```

**Sibling-package installation pattern** (`mailglass_admin/README.md:28-39`):
```markdown
{:mailglass, "~> 0.3"},
{:mailglass_admin, "~> 0.3", only: :dev}
```

**Planner guidance:** mirror the root README posture. Point to the same canonical compatibility guide, explicitly note matched release lines, and avoid inventing an independently drifting admin support promise.

### Maintainer release/support docs

**Analog:** `MAINTAINING.md`

**Required vs advisory verification pattern** (`MAINTAINING.md:25-47`):
```markdown
Before merging any PR, ensure:
- `scripts/verify_support_contract.sh`
- `Support Contract Core`
- `Support Contract Admin`
- `Compile No Optional Deps`

The following checks are advisory signal, not branch-protection truth:
- `Core Full Suite Advisory`
- `Provider Compatibility Advisory`
- `Provider Live Advisory`
```

**Release runbook truthfulness pattern** (`MAINTAINING.md:102-147`):
```markdown
Check `actions/workflows/ci.yml` ...
The current release path emits package tags such as `mailglass-v<version>`
and `mailglass_admin-v<version>`.
...
The post-publish-smoke workflow ... does not respect the 60-minute window.
```

**Planner guidance:** if Phase 36 changes support-contract verification names or adds compatibility-specific checks, update this doc first and keep the required/advisory split honest. This file is the analog for any release/support verification prose.

### Root `mix.exs`

**Analog:** `mix.exs`

**Preferred envs pattern** (`mix.exs:36-67`):
```elixir
def cli do
  [
    preferred_envs: [
      "verify.support_contract.core": :test,
      "verify.provider_compatibility": :test,
      "verify.docs.contract": :test,
      "verify.docs.migration": :test
    ]
  ]
end
```

**Semantic alias + deprecated pass-through pattern** (`mix.exs:171-258`):
```elixir
"verify.installer": [
  "test test/mailglass/install test/mailglass/docs_contract_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors --exclude flaky"
],

"verify.support_contract.core": [
  "test test/mailglass/docs_contract_test.exs ... --warnings-as-errors"
],

"verify.docs.contract": [
  "test test/mailglass/docs_contract_test.exs --warnings-as-errors"
]
```

**ExDoc extras/grouping pattern** (`mix.exs:292-358`):
```elixir
extras: [
  "README.md",
  "docs/api_stability.md",
  "guides/getting-started.md",
  ...
  "guides/migration-from-swoosh.md",
  "MAINTAINING.md"
],
groups_for_extras: [
  Overview: ["README.md"],
  Contract: ["docs/api_stability.md"],
  Guides: [...],
  Maintainers: ["MAINTAINING.md", ...]
]
```

**Planner guidance:** add the new canonical compatibility doc and canonical upgrade doc through `extras` plus `groups_for_extras`, not ad hoc. If a new verification alias is needed, follow the semantic alias pattern first; only add a deprecated pass-through if the audience already depends on an older name.

### Admin `mix.exs`

**Analog:** `mailglass_admin/mix.exs`

**Exact sibling pinning pattern** (`mailglass_admin/mix.exs:107-132`):
```elixir
defp mailglass_dep do
  if System.get_env("MIX_PUBLISH") == "true" do
    {:mailglass, "== 0.3.2"}
  else
    {:mailglass, path: "..", override: true}
  end
end
```

**Admin support-contract alias pattern** (`mailglass_admin/mix.exs:134-156`):
```elixir
"verify.support_contract.admin": [
  "test test/mailglass_admin/post_installer_smoke_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors"
]
```

**Admin ExDoc grouping pattern** (`mailglass_admin/mix.exs:176-193`):
```elixir
extras: [
  "README.md",
  "docs/api_stability.md"
],
groups_for_extras: [
  Overview: ["README.md"],
  Contract: ["docs/api_stability.md"]
]
```

**Planner guidance:** use this file as the source of truth for matched sibling release lines and any admin-specific compatibility verification alias. If the root package gets a new compatibility guide, decide explicitly whether admin ExDoc links to it or just points to it from README/docs prose.

### Docs-contract checker

**Analog:** `lib/mix/tasks/mailglass.docs.check.ex`

**Tier-1 path and token-table pattern** (`lib/mix/tasks/mailglass.docs.check.ex:23-114`):
```elixir
@tier1_paths [
  "README.md",
  "mailglass_admin/README.md",
  "guides/getting-started.md",
  ...
]

@tier1_surface_rules %{
  "README.md" => %{required: [...], forbidden: [...]},
  ...
}
```

**CLI + deterministic failure pattern** (`lib/mix/tasks/mailglass.docs.check.ex:116-145`):
```elixir
{opts, rest, invalid} = OptionParser.parse(argv, strict: [path: :string])
validate_cli!(rest, invalid)
...
Mix.raise("Delivery blocked: #{length(issues)} Tier 1 docs issue(s) found.")
```

**File-scan issue emission pattern** (`lib/mix/tasks/mailglass.docs.check.ex:155-199`):
```elixir
content = File.read!(path)
...
Mix.shell().error("[mailglass.docs.check] required Tier 1 token missing in #{path}: ...")
```

**Planner guidance:** extend this task with new guide paths and required/forbidden compatibility tokens rather than building a new heavy docs linter. This is the best analog for compatibility-guide drift checks and support-matrix honesty checks.

### Stability-check exemptions / deprecation metadata seam

**Analog:** `lib/mix/tasks/mailglass.stability.check.ex`

**Exemption inventory pattern** (`lib/mix/tasks/mailglass.stability.check.ex:8-18`, `54-66`):
```elixir
Exemptions (escape hatches and internals):
- `Mailglass.Message.update_swoosh/2` (official escape hatch)
- `Mailglass.Message.new/2` (deprecated v0.1 API)
- `Mailglass.Outbound.send/2` (deprecated v0.1 API)
```

```elixir
defp exempt?("lib/mailglass/message.ex", line) do
  String.contains?(line, "update_swoosh(") or String.contains?(line, "new(")
end

defp exempt?("lib/mailglass/outbound.ex", line) do
  String.contains?(line, "send(")
end
```

**Planner guidance:** there is no dedicated machine-readable deprecation registry yet. The closest existing pattern is a small explicit exemption list plus doc prose. If Phase 36 needs deprecation metadata, keep it lightweight and inventory-driven rather than introducing complex compile-time warning infrastructure.

### Docs contract tests

**Analog:** `test/mailglass/docs_contract_test.exs`, `test/mailglass/docs/unsubscribe_guide_test.exs`

**Whole-doc token assertions pattern** (`test/mailglass/docs_contract_test.exs:5-21`, `41-49`, `133-145`):
```elixir
readme = File.read!("README.md")
assert readme =~ "docs/api_stability.md"
refute readme =~ "v0.1 in development"
```

```elixir
maintaining = File.read!("MAINTAINING.md")
assert maintaining =~ "Support Contract Core"
assert maintaining =~ "Provider Live Advisory"
```

**Guide-specific contract test pattern** (`test/mailglass/docs/unsubscribe_guide_test.exs:4-48`):
```elixir
guide = File.read!("guides/unsubscribe.md")
assert guide =~ "GET /mailglass/unsubscribe/:token"
...
docs = Mix.Project.config()[:docs]
assert "guides/unsubscribe.md" in docs[:extras]
```

**Planner guidance:** add one new guide-focused test file for the compatibility guide if the assertions become too large for `docs_contract_test.exs`. Use direct string assertions plus `Mix.Project.config()[:docs]` checks; keep tests simple and explicit.

### Migration/upgrade smoke tests

**Analog:** `test/mailglass/docs_migration_smoke_test.exs`, `test/support/docs_helpers.ex`

**Code-block extraction pattern** (`test/support/docs_helpers.ex:4-25`):
```elixir
def extract_code_blocks(path) do
  content = File.read!(path)
  Regex.scan(~r/```(?:elixir|bash|sql)\n(.*?)\n```/s, content)
end
```

**Guide snippet parse/smoke pattern** (`test/mailglass/docs_migration_smoke_test.exs:7-50`):
```elixir
code = extract_block_after_heading(@guide_path, "End-to-End Example")
assert code
assert {:ok, _quoted} = Code.string_to_quoted(code)

assert {:ok, _delivery} = Mailglass.deliver(email)
```

**Planner guidance:** reuse this pattern for any canonical upgrade guide with code samples. Parse snippets, assert key replacement paths are present, and keep one real smoke test for a retained compatibility lane such as raw `%Swoosh.Email{}` delivery.

### Support-contract script and workflows

**Analog:** `scripts/verify_support_contract.sh`, `.github/workflows/ci.yml`, `.github/workflows/advisory-matrix.yml`

**Repo-root orchestration pattern** (`scripts/verify_support_contract.sh:1-13`):
```bash
cd "$ROOT_DIR"
mix verify.support_contract.core

cd "$ROOT_DIR/mailglass_admin"
mix verify.support_contract.admin

cd "$ROOT_DIR"
mix compile --no-optional-deps --warnings-as-errors
```

**Required workflow job pattern** (`.github/workflows/ci.yml:107-158`, `390-412`):
```yaml
support_contract_core:
  name: Support Contract Core (Elixir 1.18 / OTP 27)
  ...
  - name: Run core support contract
    run: mix verify.support_contract.core
```

```yaml
- name: Install admin deps
  working-directory: mailglass_admin
  run: mix deps.get
- name: Run admin support contract
  run: cd mailglass_admin && mix verify.support_contract.admin
```

**Advisory workflow pattern** (`.github/workflows/advisory-matrix.yml:20-132`):
```yaml
core_full_suite_advisory:
  name: Core Full Suite Advisory ...

provider_compatibility_advisory:
  name: Provider Compatibility Advisory ...
  - name: Run provider compatibility advisory
    run: mix verify.provider_compatibility
```

**Planner guidance:** keep compatibility contract proof in required jobs only when it is deterministic and branch-protection-worthy. Preserve the repo-root shell entrypoint plus separate required/advisory GitHub jobs.

## Shared Patterns

### One canonical doc, many pointers
**Sources:** `README.md:130-144`, `mailglass_admin/README.md:13-26`, `docs/api_stability.md:17-19`, `mailglass_admin/docs/api_stability.md:120-130`

Apply to all user-facing compatibility docs updates. The repo pattern is: one canonical contract page, inventory docs stay narrow, and other docs point to that page instead of duplicating policy.

### Honest stable vs internal vs legacy framing
**Sources:** `docs/api_stability.md:21-89`, `lib/mix/tasks/mailglass.stability.check.ex:12-18`

Apply to deprecation metadata, support-matrix prose, and replacement-path tables. The repo already distinguishes stable surfaces, internal surfaces, and legacy bridges. Phase 36 should preserve that precision rather than flattening everything into "public".

### Semantic verify alias first
**Sources:** `mix.exs:41-67`, `mix.exs:171-258`, `mailglass_admin/mix.exs:134-156`

Apply to any new compatibility verification tasks. Add semantic alias names first, keep deprecated pass-throughs only when continuity matters, and bind `preferred_envs` explicitly for composite `mix test` aliases.

### Light enforcement over heavy machinery
**Sources:** `lib/mix/tasks/mailglass.docs.check.ex:23-199`, `test/mailglass/docs_contract_test.exs:52-59`

Apply to docs and compatibility proof. Existing enforcement is small and deterministic: string/token checks, task existence checks, snippet parsing, and thin alias/workflow wrappers. Keep Phase 36 in that style.

### Exact sibling release matching
**Source:** `mailglass_admin/mix.exs:107-132`

Apply to all matched-version compatibility wording. The actual release contract is exact publish-time pinning with a local path dep in development; docs and tests should describe that exact behavior.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Dedicated deprecation metadata registry module/file (if proposed) | utility | transform | No current machine-readable deprecation registry exists. Existing analogs are doc inventories and explicit exemption lists only. |
| Standalone support-matrix contract test with structured parser (if proposed) | test | contract | Current docs tests use direct string assertions, not table parsers or schema-driven markdown validation. |

## Metadata

**Analog search scope:** `guides/`, `docs/`, `README.md`, `MAINTAINING.md`, `mix.exs`, `mailglass_admin/mix.exs`, `lib/mix/tasks/`, `test/mailglass/`, `test/support/`, `scripts/`, `.github/workflows/`, `.planning/phases/31-*`, `.planning/phases/34-*`
**Files scanned:** 21
**Pattern extraction date:** 2026-05-05
