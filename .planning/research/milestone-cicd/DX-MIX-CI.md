# DX: `mix ci` local↔CI parity for a 3-package Elixir library

> Decision-ready design for a single local-parity command in `mailglass` +
> the `CONTRIBUTING.md` fix. Written to be executed with minimal further
> thinking. Locked recommendation is in §B; everything else is the rationale.

**Problem (given, from the CI/CD audit — not re-derived):**
- No `mix ci` alias, no CI-mirroring Makefile target.
- The closest aggregate, `verify.stability_contract` (mix.exs:301–307), covers
  only the **contract** lanes (Support Contract Core/Admin/Inbound-docs + docs
  check + no-optional-deps compile). It does **not** run Trust Lane, Installer
  Host Smoke, format, credo, dialyzer, or the full test suite.
- `CONTRIBUTING.md:20` points contributors at the **deprecated**
  `mix verify.phase_07` (mix.exs:271–272 — an installer-only subset, scheduled
  for removal). A contributor running the documented command exercises a
  fraction of what merge requires → the exact local↔CI parity gap this milestone
  closes.

**The 5 REQUIRED merge gates** (branch protection, per MAINTAINING.md:153–158):

| CI job name (required context) | Command | Needs |
|---|---|---|
| `Support Contract Core` | `mix verify.support_contract.core` | Postgres |
| `Support Contract Admin` | `cd mailglass_admin && mix verify.support_contract.admin` | Postgres |
| `Compile No Optional Deps` | `mix compile --no-optional-deps --warnings-as-errors` | — |
| `Trust Lane Repo Head` | build `reference/host_app` (dev) → `mix verify.reference_host.journey` → checkpoint contract | Postgres |
| `Installer Host Smoke` | `bash scripts/consumer_install_smoke.sh` (DEP_MODE=path) | Postgres + network (`phx.new`) |

**Advisory lanes** (NOT branch protection, MAINTAINING.md:180–200): Format
Check, Compile Warnings as Errors, Mix Task Tests, Inbound Test, Inbound Compile
No Optional Deps, Operator Browser Gate (Node/Playwright), Preview Capture
Advisory (Node), Demo Browser Evidence (Docker), Core Full Suite Advisory,
Provider Compatibility Advisory, Credo Strict, Dialyzer, Docs Warnings-as-Errors,
Hex Audit, Installer Golden Gate, Branch Protection Advisory.

Note: several "advisory" lanes (Format, Credo, Dialyzer, Docs) are the standard
pre-merge hygiene that CONTRIBUTING/MAINTAINING already tell maintainers to run
(MAINTAINING.md:139–142). "Advisory" here means *not a branch-protection
context*, not *skip locally*. A good `mix ci` runs them.

---

## A. Competitor pattern table

Evidence gathered by reading the actual `mix.exs aliases`, `CONTRIBUTING`,
`.check.exs`, and CI workflows of each project (raw GitHub sources, June 2026).

| Library | Aggregate local command | Form | Ordered cheap-first? | Notable flags | CONTRIBUTING points at it? | Applicability to mailglass |
|---|---|---|---|---|---|---|
| **Oban** | `mix test.ci` | **mix alias** (list) | ✅ format → unused-deps → credo → test → dialyzer | `deps.unlock --check-unused`, `credo --strict`, `test --raise` | ✅ "Run `mix test.ci`…" | **Direct template.** Postgres via docker-compose; `preferred_envs` pins alias to `:test`; `test.setup`/`test.reset` DB aliases. Copy the shape. |
| **Ash** | `mix check` | **ex_check** + `.check.exs` | ✅ (ex_check default order) | `hex.audit`, `sobelow`, `credo --strict`, `--check-unused` | ✅ "run `mix check`" | Validates the ex_check route; the only surveyed lib using `hex.audit`. But adds a dep + hides the step list; mailglass's gates are too bespoke (trust lane, installer smoke, cd-into-siblings) for ex_check's tool auto-detection. **Don't adopt ex_check — borrow its ordering.** |
| **Req** | `mix test.all` (tests only) | mix alias (fn, adapter fanout) | n/a | **`deps.get --check-locked`**, **`compile --no-optional-deps --warnings-as-errors`** | no CONTRIBUTING | Contributes two flags mailglass's DNA needs: lockfile-strict install + the no-optional-deps compile. Copy the flags. |
| **Ecto / ecto_sql** | `mix test.all` | mix alias (fn) | n/a | multi-adapter fanout via `ECTO_ADAPTER` env | README only | Fanout pattern is for multi-DB; mailglass is single-Postgres. **Not applicable.** |
| **Finch** | none (loose CI steps) | — | ✅ in CI | format → unused-deps → compile-w-a-e → credo → test → dialyzer | none | Good reference for the *full* chain incl. credo+dialyzer, but no single command. Mirror the chain, add the command. |
| **Igniter / Ash CI** | `.check.exs` (thin) | ex_check + reusable workflow | ✅ | `credo --strict` alias; real gate = shared CI workflow | no CONTRIBUTING | Inverts the advice (canonical gate = CI workflow, thin local). mailglass wants the opposite: local command IS canonical. |
| **Phoenix** | none — `mix test` only | — | — | compile-w-a-e (lint leg only) | "make sure tests pass" | Counter-example. Rigor from version matrix, not a rich command. Don't copy. |
| **Bandit** | none (external reusable wf) | — | — | full lint in external repo | no CONTRIBUTING | Counter-example — contributor has nothing to run locally. Don't copy. |
| **Broadway / Nx / Tesla / Livebook** | none | — | — | minimal (format + compile-w-a-e + test) | none / no command | Counter-examples. Nx's monorepo model = CI matrix over `working_directory` (the matrix is the loop), not a root cd-script. Not our sibling-release model. |
| **Rails 8.1 `bin/ci`** | `bin/ci` → `config/ci.rb` DSL | executable script + declarative DSL | ✅ setup → style → security audits → tests | `step "Title", cmd`; timed per-step report; `success?` conditional; `--fail-fast` | generated by default | **Transfer the ergonomics:** named per-step timed report, aggregate pass/fail, non-zero exit, CI YAML *calls the command* (one definition of "green"). |
| **cargo (`.cargo/config.toml [alias]`)** | `cargo ci` | alias (single expansion) | — | can't chain multiple commands | — | Alias = short name only; needs a runner for a body. Mix aliases *can* chain, so we don't need the two-layer split. |
| **cargo-make `ci-flow`** | `cargo make ci-flow` | task runner + shipped base | ✅ pre/post hooks | shipped-base + project-override | — | "shipped default + delta override" is nice but overkill here. |
| **`just` (justfile)** | `just ci` | external binary | ✅ recipe deps | no `.PHONY`, no tab footgun, static errors | — | Nice optional wrapper, but an **extra required tool**. Keep `mix ci` as the primary entry; `just`/`make` may thinly wrap it, never replace it. |
| **npm scripts** | `npm run ci` | package.json script | ✅ `&&` short-circuits | `npm ci` = lockfile-strict install | — | The `npm ci` reproducible-install idea → `mix deps.get` + lock-clean check belongs in the **full/CI tier**, not the fast loop. |

**Cross-ecosystem DX principles distilled:** fail-fast cheap-first ordering
(format/lint before spinning up Postgres); "reproduce CI locally" via one command
that CI itself calls (no YAML/local drift); tier fast (pre-commit) vs full
(pre-push/CI) where fast is a strict subset; external-service checks (DB, browser)
are either skip-with-clear-note or a separate opt-in target.

---

## B. LOCKED recommendation: tiered mix aliases, `mix ci` as the canonical command

### B.0 Decisions made (so you don't have to)

1. **Form = mix alias lists, not a Mix.Task, not `ex_check`, not a shell script.**
   - Oban proves a plain alias list is enough and adds zero deps (honors the
     "no adopter Node / minimal dev tooling" DNA — an alias needs nothing).
   - `ex_check` would need a dep and its tool auto-detection can't model
     mailglass's bespoke gates (trust lane builds `reference/host_app`,
     installer smoke shells out, admin/inbound need `cmd --cd`). Rejected.
   - A `bin/ci` script (Rails-style) is tempting for the pretty per-step report,
     but Elixir contributors expect `mix <verb>`; a script fragments the
     interface and duplicates the `preferred_envs`/`MIX_ENV` handling Mix gives
     free. Rejected as the *primary* entry; a thin `make ci` wrapper is fine.
   - Mix aliases chain natively (`&&`-equivalent, fail-fast on first non-zero),
     so we get the Rails ordering benefit without a DSL.

2. **Tiering = three tiers.** Fast pre-commit (`mix ci.fast`), full local-parity
   (`mix ci`), and opt-in browser (`mix ci.browser`). Rationale: `mix ci` must be
   runnable by any contributor with Postgres + network in one shot and mirror the
   5 required gates + standard hygiene; the Node/Playwright + Docker lanes are
   advisory and heavy, so they're a separate opt-in target (Rails `test:system`
   precedent) — this also honors "zero-Node is *adopter*-facing": `mix ci.browser`
   needing Node does NOT violate the guarantee.

3. **3-package structure = a root alias that `cmd --cd`s into siblings**, mirroring
   the existing `verify.stability_contract` (mix.exs:303–304) which already does
   `cmd --cd mailglass_admin …` / `cmd --cd mailglass_inbound …`. One command,
   run from repo root. Do NOT require contributors to remember three separate
   `cd && mix` invocations. (Nx's per-package CI-matrix model doesn't fit our
   linked-sibling release structure.)

4. **Postgres-needing steps are IN `mix ci`** (with a `mix ci.setup` that
   creates the DBs), because every one of the 5 required gates except the
   compile lane needs Postgres — a "fast local that skips DB" would not be
   CI-parity. Contributors already need Postgres for `mix test` today
   (CONTRIBUTING.md:9). We make that prerequisite explicit.

5. **Installer Host Smoke IS in `mix ci`** (it's a required gate) but gated
   behind a documented network prerequisite; it's the slowest step so it runs
   **last** (fail-fast means the cheap stuff fails first). It already has a
   fast in-process counterpart (`install_compile_test.exs`) folded into the
   contract lanes, so a contributor who can't run `phx.new` still gets 90% signal.

6. **`mix ci` mirrors the required gates + the hygiene advisories that gate
   nothing but everyone runs** (format, credo, dialyzer, docs, hex.audit,
   compile-warnings, deps-lock hygiene). It does NOT try to reproduce the
   Node/Docker browser lanes (those → `mix ci.browser`) or the provider-live
   canaries (cron-only). This is "CI-parity for what a PR must pass," not "every
   job in ci.yml."

### B.1 Root `mix.exs` — add to `aliases/0`

Add these entries to `defp aliases do` in the repo-root `mix.exs` (alongside the
existing `verify.*` aliases). Ordering inside each alias is **cheap → expensive,
fail-fast**.

```elixir
# ---------------------------------------------------------------------------
# Local↔CI parity (CICD milestone). `mix ci` is the ONE command a contributor
# runs before opening a PR: it mirrors the 5 required branch-protection gates
# plus the standard hygiene lanes, across all three sibling packages.
#
# Tiers:
#   mix ci.fast   — seconds, no DB/network. Pre-commit loop (format+credo+compile).
#   mix ci        — full local parity. Needs Postgres + network (phx.new). Pre-push.
#   mix ci.browser— opt-in Node/Playwright admin browser gate (advisory in CI).
#
# CI (.github/workflows/ci.yml) keeps its per-job step split for legible,
# parallel, matrix-gated checks — but the SUM of `mix ci` + `mix ci.browser`
# equals the mergeable surface, so "green locally" means "green in CI".
# ---------------------------------------------------------------------------

# Create every test DB the parity run needs (core, admin, inbound siblings).
"ci.setup": [
  "ecto.create -r Mailglass.TestRepo --quiet",
  "cmd --cd mailglass_inbound mix ecto.create -r MailglassInbound.TestRepo --quiet"
],

# Fast tier — no Postgres, no network. The pre-commit / inner-loop gate.
"ci.fast": [
  "format --check-formatted",
  "deps.unlock --check-unused",
  "compile --warnings-as-errors",
  "compile --no-optional-deps --warnings-as-errors",
  "credo --strict"
],

# Full local parity — run from repo ROOT. Requires Postgres (+ network for the
# installer smoke step at the end). Mirrors the 5 required gates + hygiene.
ci: [
  # 1. Cheap static gates first (fail-fast).
  "ci.fast",
  # 2. Contract + full test lanes (core), Postgres-backed.
  "ci.setup",
  "verify.support_contract.core",
  "test --warnings-as-errors --exclude flaky",
  # 3. Sibling packages (admin needs its own support contract; inbound its tests).
  "cmd --cd mailglass_admin mix verify.support_contract.admin",
  "cmd --cd mailglass_inbound mix compile --no-optional-deps --warnings-as-errors",
  "cmd --cd mailglass_inbound mix test --exclude property --seed 0",
  # 4. Docs + supply-chain hygiene (advisory lanes, but everyone runs them).
  "docs --warnings-as-errors",
  "mailglass.docs.check",
  "hex.audit",
  # 5. Dialyzer (slow; after tests).
  "dialyzer",
  # 6. Required trust lane — builds reference host in dev, runs the journey.
  "cmd --cd reference/host_app mix deps.get",
  "cmd --cd reference/host_app env MIX_ENV=dev mix compile",
  "verify.reference_host.journey",
  "cmd bash scripts/check_trust_runner_checkpoint.sh",
  # 7. Installer Host Smoke — required, SLOWEST, needs network (phx.new). Last.
  "cmd env DEP_MODE=path MAILGLASS_PATH=#{File.cwd!()} bash scripts/consumer_install_smoke.sh"
],

# Opt-in browser gate (Node + Playwright). Advisory in CI; zero-Node is an
# ADOPTER guarantee, so requiring Node HERE is fine (dev/CI tooling).
"ci.browser": [
  "ci.setup",
  "cmd --cd mailglass_admin npm ci",
  "cmd --cd mailglass_admin npx playwright install --with-deps chromium",
  "cmd --cd mailglass_admin npm run test:operator-browser"
]
```

> **Note on `#{File.cwd!()}`:** alias entries are evaluated when `mix` loads the
> project, so `File.cwd!()` resolves to the repo root at invocation time — the
> same value `MAILGLASS_PATH: ${{ github.workspace }}` gets in CI. If you prefer
> zero interpolation, drop that step from the alias and instead have `make ci`
> export `MAILGLASS_PATH=$(pwd)` before calling `mix ci` (see §B.4).

### B.2 `cli/0` `preferred_envs` — pin the new aliases to `:test`

Elixir 1.18 no longer auto-promotes `:test` for nested `mix test` inside aliases
(mix.exs:40–43 already documents this). Add to the `preferred_envs` list in
`def cli`:

```elixir
ci: :test,
"ci.fast": :test,
"ci.setup": :test,
"ci.browser": :test,
```

(`ci.fast` is `:test` too so its `compile --warnings-as-errors` matches the env
the test lanes compile under, catching test-only warnings in the fast loop.)

### B.3 Sibling packages — add matching `ci` aliases (optional but recommended)

For a contributor working *inside* `mailglass_admin/` or `mailglass_inbound/`,
give each sibling its own `mix ci` so the "is this green?" verb is uniform
(cargo-make "same contract per package" idea). These are thin — the root `mix ci`
already fans out, so these are for the inner-loop-in-a-subdir case.

**`mailglass_admin/mix.exs` aliases/0:**
```elixir
"ci.fast": [
  "format --check-formatted",
  "compile --no-optional-deps --warnings-as-errors",
  "credo --strict"
],
ci: [
  "ci.fast",
  "verify.support_contract.admin"
],
```
Add `ci: :test, "ci.fast": :test` to its `cli/0 preferred_envs`.

**`mailglass_inbound/mix.exs` aliases/0:**
```elixir
"ci.fast": [
  "format --check-formatted",
  "compile --no-optional-deps --warnings-as-errors"
],
ci: [
  "ci.fast",
  "verify.support_contract.inbound",
  "test --exclude property --seed 0"
],
```
Add `ci: :test, "ci.fast": :test` to its `cli/0 preferred_envs`.

### B.4 `Makefile` — add a thin `ci` wrapper (optional, discoverability only)

The root `Makefile` is demo-only today. Add a discoverable pass-through so
`make ci` works for muscle-memory, without duplicating logic (Rails "CI YAML
calls the command" applied to Make):

```makefile
.PHONY: ci ci-fast ci-browser

ci: ## Run the full local↔CI parity suite (needs Postgres + network)
	@MAILGLASS_PATH="$$(pwd)" mix ci

ci-fast: ## Fast static checks only (format + credo + compile). Pre-commit loop.
	@mix ci.fast

ci-browser: ## Opt-in admin browser gate (Node + Playwright)
	@mix ci.browser
```
(Add `ci ci-fast ci-browser` to the existing `.PHONY` line and they auto-appear
in `make help`.)

### B.5 CI wiring (out of scope to change now, but the parity contract)

Do **not** rip out the per-job ci.yml split — parallel, matrix-gated, legible
per-check status is worth keeping (every surveyed lib keeps it). The parity
guarantee is a **documented invariant**, enforced by an existing test:
`mailglass_admin`/core already have contract tests asserting alias shapes. Add
(future, small) a test asserting the union of `ci` + `ci.browser` sub-steps
⊇ the required + advisory CI job commands, so drift between ci.yml and the alias
fails loudly. This is the "one definition of green" backstop.

---

## C. Exact `CONTRIBUTING.md` replacement text

Replace the **Local Setup** and **Development Workflow** sections
(CONTRIBUTING.md:5–21) with the following. This removes the deprecated
`mix verify.phase_07` pointer and gives a least-surprise, prerequisite-honest
command.

````markdown
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
````

Leave the rest of CONTRIBUTING.md (Commit Guidelines, PR Expectations, the
release-mechanics sections) unchanged.

---

## D. Rationale tied to DX principles + repo DNA

- **Local↔CI parity (the whole point).** `mix ci` + `mix ci.browser` together
  reproduce the mergeable surface. CONTRIBUTING now points at the command that
  *actually* mirrors merge, closing the `verify.phase_07` gap. Following Rails
  8.1's `bin/ci` and Oban's `mix test.ci`: one definition of "green," runnable
  identically by a human and (via the union-check test) provably ⊇ CI's gates.
- **Fast feedback / fail-fast.** Three tiers put the seconds-long static checks
  (`ci.fast`) in the inner loop, and inside `mix ci` the order is strictly
  cheap→expensive: format/credo/compile → contract+tests → dialyzer → trust
  lane → installer smoke (network, slowest) last. A two-second format failure
  never waits on Postgres or `phx.new`. This is the universal CI ordering
  principle and matches Oban/Finch/Rails ordering exactly.
- **Actionable failure.** Mix aliases stop at the first non-zero step and print
  which task failed; each `verify.*` sub-lane is already a named, scoped concern.
  No opaque mega-log.
- **Reproducibility.** `ci.fast` includes `deps.unlock --check-unused`
  (Oban/Ash/Req precedent) so lock hygiene is caught locally; the installer smoke
  runs against the working tree with path deps (already the CI design,
  ci.yml:136–141) so "works on my machine" and "works in CI" converge.
- **Engineering DNA respected.**
  - *No adopter Node:* the required/hygiene tiers use zero Node; Node lives only
    in the opt-in `ci.browser` (dev/CI tooling — explicitly allowed per the
    "zero-Node is adopter-facing" memory).
  - *Optional-deps gateway:* `compile --no-optional-deps --warnings-as-errors`
    is in `ci.fast` (core) and repeated for inbound, mirroring the mandatory CI
    lane and the DNA rule.
  - *Sibling linked-release structure:* the root `ci` alias fans out with
    `cmd --cd`, exactly like the existing `verify.stability_contract`, so it fits
    the 3-package repo without per-package release coupling.
  - *Contract-as-truth:* `mix ci` runs the same `verify.support_contract.*` and
    `mailglass.docs.check` lanes that define the stability contract, so a
    contributor can't accidentally break the public contract undetected.
- **Least surprise / respect for contributor time.** Prerequisites are stated up
  front (Postgres always; network only for the installer step; Node only for the
  optional browser gate). The heavy installer step is last and has an in-process
  counterpart, so a contributor without `phx.new` network access still gets
  almost-complete signal from the earlier steps.

---

## E. What NOT to do / footguns

1. **Don't keep pointing CONTRIBUTING at `mix verify.phase_07`.** It's a
   deprecated installer-only subset (mix.exs:271–272) scheduled for removal.
   When the deprecated `verify.phase_NN` pass-throughs are deleted next cycle,
   the CONTRIBUTING command would 404. This fix removes that coupling.
2. **Don't make `mix ci` a Mix.Task or a `bin/ci` script as the primary entry.**
   Elixir contributors reach for `mix <verb>`; a script fragments the interface,
   re-implements `preferred_envs`/`MIX_ENV`, and can't be composed by other
   aliases. Keep it an alias list. (A thin `make ci` wrapper is fine; a *required*
   `just`/script is not.)
3. **Don't adopt `ex_check` for this.** Its tool auto-detection can't model the
   bespoke gates (trust lane compiles `reference/host_app`; installer smoke
   shells out; siblings need `cmd --cd`). You'd fight the config more than a
   plain alias, and add a dep. Borrow its *ordering*, not the tool.
4. **Don't fold the browser/Docker lanes into `mix ci`.** Node + Playwright +
   `npx playwright install` + Docker-compose demo evidence are slow, advisory,
   and would make the default parity command un-runnable for a backend-only
   contributor — and they'd smuggle a Node requirement into the default path,
   muddying the zero-Node message. Keep them in `ci.browser` / leave demo
   evidence to CI + `make demo-e2e`.
5. **Don't drop the trust lane or installer smoke from `mix ci`.** They are
   REQUIRED branch-protection gates. `verify.stability_contract` omits both —
   that omission is exactly today's parity gap. If a contributor's environment
   truly can't run them (no network), document the fallback (run `ci.fast` +
   `ci.setup` + contract lanes) rather than silently narrowing the default.
6. **Don't let `mix ci` and `ci.yml` drift.** They are intentionally two
   surfaces (aliases for humans, per-job matrix for CI legibility/parallelism).
   Add the union-check test (§B.5) so a new required CI job that isn't reflected
   in the alias fails a test — otherwise parity rots the moment someone adds a
   gate to YAML only.
7. **Don't forget `preferred_envs`.** Every new alias that nests `mix test` or
   env-sensitive compile MUST be listed in `cli/0 preferred_envs` as `:test`, or
   it raises the "set MIX_ENV explicitly" error before running (documented at
   mix.exs:40–43). This is the #1 way the alias will appear "broken" on first run.
8. **Don't hardcode DB names/hosts in the alias.** `ci.setup` uses the same
   `ecto.create -r <Repo>` the CI jobs use; Postgres connection comes from env
   (`POSTGRES_HOST`/`_USER`/`_PASSWORD`), matching ci.yml. Keep it env-driven so
   local and CI resolve identically.
9. **Don't run `mix compile --no-optional-deps --force` against the shared
   `_build`** as a parity step — per the repo memory, it pollutes the shared
   build and the `/inbound` route is compile-time-gated/order-sensitive. The
   alias uses plain `--no-optional-deps` (no `--force`), matching ci.yml:109.
10. **Don't drift the `reference/host_app` pin as a side effect.** The trust-lane
    step in `mix ci` runs `mix deps.get` + `mix compile` in `reference/host_app`;
    that's build-only and won't touch pins. Do not add `mix deps.update` there —
    the reference baseline is a frozen coordinated 5-file artifact (per repo
    memory); bumping it is a deliberate change, never a CI side effect.
````
