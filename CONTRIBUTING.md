# Contributing to Mailglass

We welcome contributions! Mailglass is developed using a phase-based roadmap found in [`.planning/PROJECT.md`](.planning/PROJECT.md).

## Local Setup

Prerequisites:

- **Elixir ~> 1.18 / OTP 27+** (the supported floor).
- **PostgreSQL** running locally (the test suite and every contract lane are
  DB-backed). Defaults expect `postgres`/`postgres` on `localhost:5432`; override
  with `POSTGRES_HOST` / `POSTGRES_USER` / `POSTGRES_PASSWORD`.
- **Node 22+** — only if you run the optional admin browser gate
  (`mix ci.browser`). It is NOT needed for a normal contribution: mailglass's
  zero-Node guarantee is for *adopters*, and the required checks need no Node.

Steps:

1. Clone the repo.
2. Install dependencies: `mix deps.get`.
3. Create the test databases: `mix ci.setup`
   (creates `Mailglass.TestRepo` and the inbound test DB).
4. Run the tests: `mix test`.

To click around the admin UI against seeded data — the fastest way to iterate on
`mailglass_admin` — run the demo with Docker: `make demo`
(see [`guides/run-the-demo.md`](guides/run-the-demo.md)).

## Development Workflow

1. Create a branch.
2. Implement your changes and add tests.
3. **Inner loop (fast, seconds, no DB):** `mix ci.fast`
   — runs `mix format --check-formatted`, unused-deps check,
   `compile --warnings-as-errors` (with and without optional deps), and
   `mix credo --strict`. Run this often.
4. **Before you push — full local↔CI parity:** `mix ci`
   — run from the repo root. Mirrors every required merge gate plus the standard
   hygiene lanes across all three sibling packages: the core and admin support
   contracts, the full core test suite, inbound tests, `mix dialyzer`,
   `mix docs --warnings-as-errors`, `mix hex.audit`, the reference-host **trust
   lane**, and the **installer host smoke** (which generates a throwaway Phoenix
   app, so this step needs network access and takes a few minutes — it runs
   last, after everything cheap has already passed).
   Requires Postgres; the installer step also requires network access.
5. **(Optional) Admin browser gate:** `mix ci.browser`
   — runs the Playwright operator-UI checks. Needs Node 22+ and downloads a
   Chromium build. This lane is advisory (it does not block merge), so skip it
   unless you touched the admin UI.
6. Open a PR.

If a step in `mix ci` fails, it names the failing check and stops there
(fail-fast). Fix it and re-run — `mix ci` is safe to run repeatedly.

> Prefer `make`? `make ci`, `make ci-fast`, and `make ci-browser` are thin
> wrappers around the Mix aliases above.

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

## How release-please syncs README install pins (and what it no longer does)

`.github/workflows/release-please.yml` runs a `sed` step on the
`release-please--branches--main` PR branch after the action runs. It syncs:

- The `{:mailglass_inbound, "~> X.Y"}` install hint in `mailglass_inbound/README.md`
  to the new inbound major.minor.
- The `{:mailglass, "~> X.Y"}` and `{:mailglass_admin, "~> X.Y"}` install hints
  in the three READMEs to the new core major.minor.
- The `mailglass_inbound_publish_pin` field in
  `.planning/publish/mailglass_inbound-publish-summary.json` to the new `~>` constraint.

**What the sed step does NOT touch:** the sibling `mix.exs` core-dep declarations.
As of v1.15 Phase 125 the sibling packages use hand-maintained pessimistic `~>` constraints
(`mailglass_inbound` uses `~> 1.10 and >= 1.10.2`, `mailglass_admin` uses `~> 1.10`).
A core **patch** release requires no sibling change at all. A core **minor** (e.g. 1.11.0)
requires a deliberate `fix(inbound):` commit in `mailglass_inbound/mix.exs` updating the
floor — asserting "verified against core 1.11" — before or alongside the release PR.

**Recursion-safety guarantee:** the sync push uses `GITHUB_TOKEN`, which by
GitHub's anti-recursion guarantee does NOT trigger further workflow runs.

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
