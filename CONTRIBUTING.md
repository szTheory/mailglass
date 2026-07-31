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
   — runs `mix format --check-formatted`,
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

## Verifying on the gating toolchain (Elixir 1.18.4 / OTP 27)

`mix ci` runs on **whatever Elixir you have installed**. Every gating CI lane
runs **Elixir 1.18.4 / OTP 27** (`.tool-versions`, and the `elixir: "1.18" /
otp: "27"` matrix rows in `.github/workflows/ci.yml` and
`advisory-matrix.yml`). Maintainers are routinely a version line ahead, and this
repo has already shipped a change that was green on 1.19 and failed **every**
gating lane — an ExUnit process label that only exists from Elixir 1.19.0 (see
`test/support/sandbox_ownership.ex`, "Why the context, and not a process
label"). If you touch anything version-sensitive — ExUnit internals, `:crypto`,
stdlib edge behavior, or a timing bound — verify it here before you push:

```bash
make toolchain                                  # full core suite, schema public
make toolchain MAILGLASS_SCHEMA=mailglass       # the second D-06 schema axis
make toolchain CMD='mix test path/to/file.exs --seed 961019'
make toolchain CMD='mix dialyzer'               # MIX_ENV=test, as CI runs it
make toolchain-shell                            # poke around interactively
make toolchain-version                          # prove the pin, ~2s
make toolchain-clean                            # reset after a version bump
```

Everything runs in Docker (`compose.toolchain.yml` +
`dev/toolchain/Dockerfile`); no `asdf install` and no second Erlang build on
your machine. The stack is namespaced `mailglass-toolchain`, so it never
collides with `make demo`.

Two properties are load-bearing and worth knowing about:

- **`deps/` and `_build/` are container-private named volumes.** Your host tree
  is compiled by *your* Elixir; sharing either directory would let the two
  toolchains overwrite each other's artifacts, so every switch would be a full
  rebuild and your host `mix test` could silently run 1.18-built beams. The
  cost is one cold compile the first time (a few minutes on 2 vCPU), cached
  after that.
- **The container is capped at 2 vCPU / 4 GB** — the GitHub-hosted
  `ubuntu-latest` runner's size. That is what makes a duration measured here a
  usable predictor of the CI clock; an unthrottled run on a modern laptop is
  roughly 7x faster and will under-report any timing-sensitive bound. Override
  with `MAILGLASS_TOOLCHAIN_CPUS=8` for a quick smoke run, but measure bounds at
  the default.

Every `make toolchain` invocation first runs
`scripts/assert_gating_toolchain.sh`, which refuses to continue unless the
container really is the Elixir/OTP pair `.tool-versions` declares — so a future
version bump that leaves `dev/toolchain/Dockerfile` behind fails loudly instead
of quietly reporting green for a toolchain nothing gates on. It then drops and
recreates the test DB, because a suite that passes against a stale schema has
not proven anything.

When you bump `.tool-versions`, bump the `FROM` line in
`dev/toolchain/Dockerfile` and `reference/demo_app/Dockerfile` (they share the
pin) and run `make toolchain-clean`.

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

`release-please.yml` runs on pushes to `main`, direct `workflow_dispatch`, and
its hourly schedule at minute 17. When the **release PR** (`chore: release main`)
is merged by GitHub-native auto-merge, the resulting push is authored by
`GITHUB_TOKEN`; GitHub suppresses that recursive push event. Symptom: the
manifest on `main` is at the new version and the release PR is merged with label
`autorelease: pending`, but no `mailglass-vX.Y.Z` GitHub release exists and Hex
still shows the prior version.

**Automatic recovery:** the scheduled run at minute 17 checks this state hourly,
so recovery waits for the next hourly run — up to one hour. The recorded
incidents cost roughly 30 minutes. Its preflight is idempotent: all expected tags
already present and an `autorelease: tagged` label are successful no-ops. A
partial linked-tag state fails deliberately and requires reconciliation before
another release action can run.

**Direct manual recovery:** use `workflow_dispatch` for the existing
release-please workflow when waiting for the hourly recovery is inappropriate.
The preflight permits a pending untagged release and the `RELEASE_PLEASE_PAT`
release creation emits the canonical `release: published` fan-out to
`publish-hex.yml`.

**Last resort:** manually creating the missing GitHub releases remains the
canonical `release: published` fan-out when the workflow path cannot be used.

## One-time setup: branch protection automation

`main` is protected with exactly two required status checks (`CI Green`,
`Guard Release Trigger`). Individual `ci.yml` leaf lanes are deliberately
**not** required contexts — see `MAINTAINING.md` § "Required Checks" for
every lane's classification and disposition. This protection is configured
idempotently by `scripts/setup_branch_protection.sh` and re-asserted daily
by `.github/workflows/branch-protection-drift.yml`.

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
