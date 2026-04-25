# Phase 07: Installer + CI/CD + Docs — Pattern Map

**Mapped:** 2026-04-24  
**Scope:** `INST-01..04`, `CI-01..07`, `DOCS-01..05`, `BRAND-02..03`

## Likely Target Files (Phase 7)

### Installer + golden tests
- `lib/mix/tasks/mailglass.install.ex` (new)
- `lib/mailglass/installer/` (new modules: operation planner/apply/manifest/conflict writer)
- `test/example/` (new fixture host tree + snapshots)
- `test/mailglass/install/*_test.exs` (new idempotency/conflict/`--no-admin`/golden tests)
- `mix.exs` (modify aliases with `verify.phase_07` + focused installer/doc verify tasks)

### CI decomposition
- `.github/workflows/ci.yml` (modify; remove markdown path-ignore and keep required checks stable)
- `.github/workflows/dependency-review.yml` (new)
- `.github/workflows/actionlint.yml` (new)
- `.github/workflows/pr-title.yml` (new)
- `.github/workflows/provider-live.yml` (new advisory lane)
- `.github/dependabot.yml` (new; cover both `mix.lock` + workflow action pins)

### Docs + contracts
- `mix.exs` (modify `docs/0`: extras/groups/source refs)
- `README.md` (modify: concise + truthful quickstart)
- `guides/getting-started.md` (new)
- `guides/authoring-mailables.md` (new)
- `guides/components.md` (new)
- `guides/preview.md` (new)
- `guides/multi-tenancy.md` (new)
- `guides/telemetry.md` (new)
- `guides/testing.md` (new)
- `guides/migration-from-swoosh.md` (new)
- `test/mailglass/docs_contract_test.exs` (new)

### Release hardening
- `.github/workflows/release-please.yml` (new)
- `release-please-config.json` (new)
- `.release-please-manifest.json` (new)
- `.github/workflows/publish-hex.yml` (new; protected environment only)
- `mix.exs` + `mailglass_admin/mix.exs` (modify/confirm package file whitelist + tarball checks)
- `LICENSE` (new, root)
- `CHANGELOG.md` (new, root)
- `CONTRIBUTING.md` / `MAINTAINING.md` / `SECURITY.md` / `CODE_OF_CONDUCT.md` (new, root)

---

## 1) Installer Idempotency Pattern

| Target file area | Role | Data/control flow implications | Closest analog(s) | Copyable pattern notes |
|---|---|---|---|---|
| `lib/mix/tasks/mailglass.install.ex` | User-facing command and status UX | Parse flags (`--dry-run`, `--no-admin`, `--force`) -> build plan -> apply in deterministic order -> print `create/update/unchanged/conflict` lines | `lib/mix/tasks/mailglass.reconcile.ex`, `lib/mix/tasks/mailglass.webhooks.prune.ex` | Keep task skeleton: `OptionParser.parse/2`, `Mix.Task.run("app.start")`, explicit `Mix.shell().info/error`; return non-zero on unresolved conflicts |
| `lib/mailglass/installer/operation*.ex` | Operation engine (`create_file`, `ensure_snippet`, `ensure_block`, `run_task`) | Two-stage flow: plan (no mutation) then apply (mutation + manifest update). Shared host files must only be anchor/block patched | `lib/mailglass/events.ex` (deterministic conflict/no-op branching), current mix task modules (clear status output) | Use explicit statuses and deterministic branch points; avoid "best effort" rewrites when anchors drift |
| `lib/mailglass/installer/manifest.ex` + `.mailglass.toml` | Install state + hash tracking | Read manifest hash -> compare file hash -> classify `unchanged/update/conflict`; dedupe repeat conflicts by same reason/hash | `lib/mailglass/events.ex` (`on_conflict` semantics + replay detection by stable sentinel) | Track hashes as first-class state, not inferred from current file contents alone |
| `test/example/` + installer integration tests | Golden diff + rerun guarantees | Fresh install snapshot, second-run no-op, user-edited conflict sidecar, `--no-admin` branch | `test/mailglass/components/vml_preservation_test.exs`, `test/support/fixtures.ex`, `test/mailglass/properties/idempotency_convergence_test.exs` | Keep fixture-root helpers and narrow normalization tokens only (`<MIGRATION_TS>`, `<TMP_PATH>`, `<SECRET>`) |

Concrete snippet shape to reuse:

```elixir
{opts, _rest, _invalid} =
  OptionParser.parse(argv, strict: [dry_run: :boolean, no_admin: :boolean, force: :boolean])

plan = Mailglass.Installer.Plan.build(opts)
result = Mailglass.Installer.Apply.run(plan, opts)

Enum.each(result.operations, fn op ->
  Mix.shell().info("[#{op.status}] #{op.path}")
end)
```

```elixir
case {manifest_hash_for(path), current_hash(path)} do
  {hash, hash} -> :unchanged
  {_, _} when safe_to_patch?(path, op) -> :update
  _ -> {:conflict, write_sidecar(path, op, reason: :anchor_drift)}
end
```

---

## 2) CI Workflow Decomposition Pattern

| Target file area | Role | Data/control flow implications | Closest analog(s) | Copyable pattern notes |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | Required core quality gates | PR/push -> stable named jobs for compile/test/credo/dialyzer/docs/hex audit + installer/docs checks | Existing `.github/workflows/ci.yml`, `mix.exs` verify aliases | Preserve cache/service setup blocks; remove `**/*.md` ignore so docs-only PRs still run docs contracts |
| `dependency-review.yml`, `actionlint.yml`, `pr-title.yml` | Required policy checks | Separate concern-specific workflows so failures are localized and branch protection names remain stable | Current CI check naming style + phase verify alias naming in `mix.exs` | Keep one check per concern (no mega workflow); use stable workflow/job names from day one |
| `provider-live.yml` | Advisory provider lane | `schedule` + `workflow_dispatch` only; tagged tests run outside merge-blocking path | `ROADMAP`/`REQUIREMENTS` advisory semantics + current CI structure | Keep lane explicitly non-required and isolated from PR path |
| `.github/dependabot.yml` | Supply-chain maintenance | Action SHA pin updates + mix dependency updates flow through normal PR checks | `.github/workflows/ci.yml` note already calling for SHA pinning | Configure `package-ecosystem: github-actions` and `package-ecosystem: mix` |

Concrete snippet shape to reuse:

```yaml
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
```

```yaml
services:
  postgres:
    image: postgres:16-alpine
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
```

```yaml
- name: Run phase gate
  run: mix verify.phase_07
```

---

## 3) Docs/Guide Contract Pattern

| Target file area | Role | Data/control flow implications | Closest analog(s) | Copyable pattern notes |
|---|---|---|---|---|
| `mix.exs` (`docs/0`) | ExDoc information architecture | Guide extras and grouping become canonical docs surface; CI fails on doc warnings | Current `mix.exs` docs config (`main: "getting-started"` already present) | Extend, do not replace: keep `source_url/source_ref`; add extras/groups incrementally |
| `README.md` + `guides/*.md` | Adopter onboarding contract | Quickstart/guides must map to real tasks/routes/config; each guide ends with runnable flow | `README.md` existing quickstart, `guides/webhooks.md` style | Keep step-based headings + footgun callouts + explicit code blocks using real module/task names |
| `test/mailglass/docs_contract_test.exs` | Drift detector between docs and code | Extract snippets -> parse/compile -> assert real Mix tasks/config schema/routes exist | `mailglass_admin/test/mailglass_admin/mix_config_test.exs`, `test/mailglass/mailable_test.exs` (source parsing patterns) | Use `Code.string_to_quoted/1` and explicit API existence assertions instead of fragile text matching |

Concrete snippet shape to reuse:

```elixir
snippet = Docs.extract_fenced!("README.md", "Quickstart")
assert {:ok, _quoted} = Code.string_to_quoted(snippet)
assert Mix.Task.get("mailglass.install")
assert Mix.Task.get("mailglass.reconcile")
```

```elixir
cfg =
  Mailglass.Config.new!(
    tenancy: Mailglass.Tenancy.SingleTenant
  )

assert cfg.tenancy == Mailglass.Tenancy.SingleTenant
```

---

## 4) Release Workflow Hardening Pattern

| Target file area | Role | Data/control flow implications | Closest analog(s) | Copyable pattern notes |
|---|---|---|---|---|
| `release-please-config.json` + `.release-please-manifest.json` | Coordinated versioning for root + admin | Merge to main -> release PR with linked version bumps -> tags for both packages | `mailglass_admin/mix.exs` `mailglass_dep/0` exact pin pattern | Keep linked-versions + `separate-pull-requests: false` so sibling versions never drift |
| `.github/workflows/release-please.yml` | Release PR automation | Push to main triggers release orchestration only (no publish secrets) | Existing `.github/workflows/ci.yml` structure (concurrency + explicit job naming) | Separate release creation from publish; keep minimal permissions |
| `.github/workflows/publish-hex.yml` | Protected publish path | Release ref only -> environment approval -> tarball checks -> publish `mailglass` then `mailglass_admin` | `mailglass_admin/mix.exs` package whitelist + `verify.phase_05` artifact gate (`git diff --exit-code`) | Encode pre-publish checks as blocking steps; never expose `HEX_API_KEY` in PR jobs |
| Root release docs/artifacts (`LICENSE`, `CHANGELOG.md`, maintainer docs) | Required release completeness + maintainer contract | Missing release artifacts fail packaging/docs/reviewer trust late; include before publish flow | `mix.exs`/`mailglass_admin/mix.exs` package file whitelists and release comments | Treat maintainer docs as versioned release assets, not post-release cleanup |

Concrete snippet shape to reuse:

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

```json
{
  ".": "0.1.0",
  "mailglass_admin": "0.1.0"
}
```

```bash
# pre-publish gate idea (blocking)
mix hex.build
# assert tarball includes only whitelisted files + enforce size budget
```

---

## Planner/Executor Notes

- Lock required check names early and treat them as API: branch protection depends on stable labels.
- Prefer deterministic status outputs and sidecar conflicts over silent "best guess" rewrites.
- Keep docs-contract checks explicit and small (task existence, snippet parsing, config schema, route parity).
- Keep release creation and publish as separate workflows with separate permissions and secret scopes.
