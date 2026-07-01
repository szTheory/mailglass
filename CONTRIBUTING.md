# Contributing to Mailglass

We welcome contributions! Mailglass is developed using a phase-based roadmap found in [`.planning/PROJECT.md`](.planning/PROJECT.md).

## Local Setup

1. Clone the repo.
2. Install dependencies: `mix deps.get`.
3. Setup the test database: `mix ecto.setup` (or `mix ecto.create -r Mailglass.TestRepo`).
4. Run tests: `mix test`.

To see the admin UI working against seeded data — the fastest way to iterate on
`mailglass_admin` — run the click-around demo with Docker: `make demo` (see
[`guides/run-the-demo.md`](guides/run-the-demo.md)).

## Development Workflow

1. Create a branch.
2. Implement your changes and add tests.
3. Inner loop (seconds, no DB/network): `mix ci.fast` — format, unused-deps,
   compile (incl. `--no-optional-deps`) as warnings-as-errors, and Credo.
4. Before pushing: `mix ci` — the full local↔CI parity run. It mirrors the
   required branch-protection gates plus hygiene across all three sibling
   packages, so a green `mix ci` means a green PR. **Prerequisites:** a running
   Postgres (as for `mix test`); `mix ci.setup` creates the sibling test DBs.
5. Optional (needs Node): `mix ci.browser` runs the admin operator browser gate
   (Playwright/Chromium). This is advisory in CI — the zero-Node guarantee is
   for *adopters*, so dev/CI tooling using Node is fine.
6. Submit a PR.

## Commit Guidelines

Use Conventional Commits:
- `feat: ...` for new features
- `fix: ...` for bug fixes
- `docs: ...` for documentation changes
- `chore: ...` for maintenance

## PR Expectations

- All CI checks must pass.
- New features must include documentation and tests.
- Maintain atomic commits.

## Why we sed mix.exs after release-please runs

Release Please's `extra-files` generic updater silently no-ops on a `mix.exs`
already managed by the `elixir` release-type. The `{:mailglass, "== <ver>"}`
pin in `mailglass_admin/mix.exs` therefore never gets rewritten by the action
itself.

`.github/workflows/release-please.yml` syncs the pin via a `sed` step on the
release-please PR branch after the action runs. This is the **steady-state
mitigation** rather than authoring a TypeScript plugin (which would violate
the "no Node toolchain anywhere" engineering DNA) or refactoring to
`version.exs` (which adds Hex tarball + `Code.eval_file` load-order risk).

**Recursion-safety guarantee:** the sync push uses `GITHUB_TOKEN`, which by
GitHub's anti-recursion guarantee does NOT trigger further workflow runs.

**Sed-anchor stability:** `mailglass_admin/test/mailglass_admin/mix_config_test.exs`
asserts the dep tuple in `mailglass_admin/mix.exs` matches the literal
`{:mailglass, "== <semver>"}` shape the sed regex anchors on. Any future
rename of the dep tuple form will fail this test loudly — update the sed
regex (in `release-please.yml`) and this section together.

**Pointer:** see `.planning/todos/pending/2026-04-26-release-please-extra-files-no-op-on-managed-mix-exs.md`
for the empirical observation history.

## If a release publishes but the tags/publish never fire

`release-please.yml` runs only `on: push: main`. When the **release PR**
(`chore: release main`) is merged by GitHub-native **auto-merge**, the resulting
push is authored by `GITHUB_TOKEN`, and GitHub's anti-recursion guarantee
suppresses the `push` event — so release-please does **not** re-run to tag the
release, and the `release: published` fan-out in `publish-hex.yml` never starts.
Symptom: the manifest on `main` is at the new version and the release PR is
merged with label `autorelease: pending`, but no `mailglass-vX.Y.Z` GitHub
release exists and Hex still shows the prior version.

**Recovery:** land any subsequent commit on `main` via a **non-`GITHUB_TOKEN`
identity** (e.g. a maintainer merging a small PR with `gh pr merge` rather than
arming auto-merge). That push wakes release-please; its preflight sees the
`pending`, untagged release PR, creates the `vX.Y.Z` releases (via
`RELEASE_PLEASE_PAT`), and the `release: published` events drive `publish-hex`.
The publish jobs are idempotent (`mix hex.info` guards), so a re-trigger is
always safe. Manually creating the releases with `gh release create <tag>` is an
equivalent fallback — `release: published` is the canonical publish trigger.

## One-time setup: branch protection automation

`main` is protected with required status checks (`Tests`, `Credo Strict`,
`Dialyzer`, `actionlint`, `PR title (semantic)`). This protection is
configured idempotently by `scripts/setup_branch_protection.sh` and
re-asserted daily by `.github/workflows/branch-protection-drift.yml`.

To enable the drift-detection workflow, add a repo secret
`BRANCH_PROTECTION_PAT`:

1. Generate a fine-grained PAT scoped to `szTheory/mailglass` with
   **Administration: Read and write** permission. (Settings → Developer
   settings → Personal access tokens → Fine-grained tokens.)
2. Add it as a repo secret named `BRANCH_PROTECTION_PAT`. (Repo settings
   → Secrets and variables → Actions → New repository secret.)
3. Run `Branch Protection Drift` once via the Actions tab to confirm.

Without the secret, the drift workflow no-ops and posts a notice in its
workflow summary. Without it, you can still call the script directly:

```bash
GH_TOKEN=<admin-PAT> scripts/setup_branch_protection.sh main
```

## Verifying the Tests gate blocks failing PRs

`scripts/check_tests_gate.sh` runs in CI's `actionlint` job and fails
if `continue-on-error: true` is reintroduced on the Tests job. Static
guard.

For an end-to-end check, run the `Gate Self-Test` workflow via the
Actions tab. It creates a temporary branch with a synthetic
`assert false`, opens a draft PR, polls until the Tests check
finishes, asserts FAILED, then closes the PR and deletes the branch.
~5 minutes round-trip.
