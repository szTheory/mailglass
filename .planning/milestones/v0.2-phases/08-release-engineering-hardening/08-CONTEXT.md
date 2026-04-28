# Phase 8: Release-Engineering Hardening - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Close 12 v0.1.2 release-engineering debt items (REL-01..12) and re-tighten quality gates (Tests, Credo, Dialyzer) before any API-freezing work begins in Phase 9. This is mostly mechanical debt-clearing — five gray areas were discussed (Dialyzer triage, Tests gate hardening, Credo strict scope, Release Please extra-files, release-please-action v5 timing); the rest of the phase is locked by REQUIREMENTS.md success criteria.

**In scope:**
- REL-01: `publish-hex.yml` + `post-publish-smoke.yml` → `on: release: types: [published]` + `mix hex.info` pre-check idempotency guard
- REL-02: HexDocs hygiene — exclude `CLAUDE.md`, strip `D-NN`/`LINT-NN` IDs from public guides, `mix mailglass.docs.check` CI gate
- REL-03: Rename `verify.phase_NN` aliases to semantic names with deprecated pass-throughs
- REL-04: Wire installer goldens into `mix mailglass.publish.check`
- REL-05: Release Please managed-mix-exs `extra-files` no-op resolution (Path 2 sed step → harden + document)
- REL-06: Advisory Matrix DB-setup + Elixir 1.17 compile fixes
- REL-07: Unskip 2 `install_idempotency` tests; managed-snippet drift detection
- REL-08: Re-batch + merge 6 closed Dependabot PRs
- REL-09: Refresh Actions SHA pins for 2026-Q2
- REL-10: Tests gate halt-on-failure (citext OID-cache fix + AsyncAdapter behaviour + sandbox isolation)
- REL-11: `mix credo --strict` enabled with documented baseline (Oban-pattern)
- REL-12: Dialyzer re-tightened — REMOVE `--ignore-exit-status`; triage 230 → ≤15 annotated `.dialyzer_ignore.exs` entries

**Out of scope (deferred to Phase 9 or later):**
- Mailable API redesign / `import Swoosh.Email` removal at `mailable.ex:129` → Phase 9
- Rename `is_error?/1` → `error?/1` → Phase 9 (folded into API redesign; suppressed inline until then)
- release-please-action v5.0.0 upgrade → Phase 13 (4 days of public soak; defer near release moment)
- `mailglass_inbound` packaging hardening → v0.5+
- `:underspecs` Dialyzer flag opt-in → revisit after the ≤15-entry target is hit

</domain>

<decisions>
## Implementation Decisions

### REL-12: Dialyzer Triage Strategy

- **D-08-01:** Triage approach is **flag-tune + fix-cheap + ignore-structural + document-rest** (Oban + Ash hybrid). Add `flags: [:error_handling, :missing_return, :no_opaque, :no_match, :underspecs]` to the `:dialyzer` config in both `mix.exs` files. The `:no_opaque` + `:no_match` flags kill the entire Elixir 1.18 opaque-type warning cascade (elixir-lang/elixir#14837) which accounts for a large fraction of the 230 findings. Re-run dialyzer after flag tuning; expect 230 → 30–60. Fix everything that's a one-line `@spec` correction or genuine bug. Add residuals to `.dialyzer_ignore.exs` with `# Reason: <one-line>` comments above each tuple.
- **D-08-02:** **Per-package ignore files** — `.dialyzer_ignore.exs` lives at root of `mailglass/` and `mailglass_admin/` separately (each has its own `mix.exs` and PLT). `mailglass_inbound` deferred — N/A here.
- **D-08-03:** Ignore-file format is **`--format ignore_file_strict`** (pins to `{file, short_description}` tuples — stable against line-number drift). Regex entries banned in favor of explicit tuples — they don't fail `--list-unused-filters` cleanly.
- **D-08-04:** **`list_unused_filters: true`** in `mix.exs` `:dialyzer` config so CI fails loudly when a future fix invalidates an existing ignore (prevents silent drift).
- **D-08-05:** **`scripts/check_dialyzer_ignore.sh`** — simple `grep`-based CI gate (no Elixir runtime needed) that fails the build if any `.dialyzer_ignore.exs` entry is missing a `# Reason:` comment on the preceding line. Runs as a step in the `dialyzer` CI job before `mix dialyzer`.
- **D-08-06:** PLT cache key in `ci.yml` MUST include `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ hashFiles('**/mix.lock') }}`. OTP 27 minor-version bumps invalidate the PLT silently otherwise.
- **D-08-07:** **1-day triage tripwire.** If `.dialyzer_ignore.exs` has > 15 entries after one focused triage day, STOP — open a v0.3 "Dialyzer-deep-clean" research phase rather than padding the file. The cap is the signal, not the goal.
- **D-08-08:** Ban `@dialyzer {:nowarn_function, ...}` source-level pragmas — all suppressions live in the centralized ignore file. Add a Credo-check candidate to LINT backlog (defer authoring; not a Phase 8 deliverable).
- **D-08-09:** `--ignore-exit-status` is REMOVED from `ci.yml` Dialyzer step. Default `mix dialyzer` already halts on warnings (verified against Dialyxir 1.4.7). Do NOT add `--halt-exit-status` (does not exist as a Dialyxir flag — STATE.md correction propagates here).

### REL-10: Tests Gate Re-Tightening

- **D-08-10:** **citext OID-cache fix** — extract the per-checkout probe into `Mailglass.TestSupport.CitextProbe` (new module under `test/support/`); call `CitextProbe.run/1` from `test_helper.exs` (cold start) AND from every CaseTemplate's `setup` block (`DataCase`, `MailerCase`, `WebhookCase`, `AdminCase`). Retain `disconnect_on_error_codes: [:internal_error]` in `config/test.exs`. Five-iteration retry loop matches the existing `persistence_integration_test.exs` `probe_until_clean/5` idiom. **Reject** custom `Postgrex.Types` module — citext is built-in; custom module doesn't help with mid-run extension drop/recreate. **Reject** skipping citext in test envs — schema drift between test/prod hides bugs.
- **D-08-11:** **Async ownership pattern — AsyncAdapter behaviour (user-confirmed).** Introduce `Mailglass.Outbound.AsyncAdapter` behaviour with two implementations:
  - `Mailglass.Outbound.AsyncAdapter.TaskSupervisor` — prod default; current `Mailglass.TaskSupervisor.start_child/1` path
  - `Mailglass.Outbound.AsyncAdapter.Inline` — test default; runs the dispatch synchronously under the calling process's connection
  
  Mirrors the existing `Mailglass.Clock` injection pattern. Configured via `Application.get_env(:mailglass, :async_adapter, TaskSupervisor)` (matching the pattern of the existing `:async_adapter` config key — confirm name in plan). `MailerCase` defaults to `:inline`; opt-in `set_mailglass_global` flips to `:task_supervisor` + `Sandbox.mode(repo, {:shared, self()})` + forces `async: false`. **Rejected:** `$callers`-based auto-allowance (silently fails because `Mailglass.TaskSupervisor` is a top-level supervisor, not in the test process's `$callers` chain). **Rejected:** threading `Sandbox.allow/3` into library code (leaks test concerns into prod).
- **D-08-12:** **CaseTemplate hardening** — `MailerCase` moduledoc documents the rule: "tests that exercise real async dispatch use `set_mailglass_global` + `async: false`; all other tests get `:inline` dispatcher." `DataCase`/`WebhookCase`/`AdminCase` get `CitextProbe.run/1` in their `setup`. Audit pass identifies the ~11 currently-failing tests; tag the genuinely shared-state ones with `@tag async: false` (mirrors existing `@tag oban: :manual` precedent).
- **D-08-13:** **3-PR rollout sequence** for the Tests gate flip:
  - **PR-A:** Ship `CitextProbe` + `AsyncAdapter` behaviour + `:inline` test default + CaseTemplate hardening. Keep `continue-on-error: true` on the existing Tests lane. Acceptance: 5 consecutive `mix test --warnings-as-errors --seed <random>` runs locally pass.
  - **PR-B:** Add new CI lane `tests-strict` running `mix test --warnings-as-errors` without `continue-on-error`, NOT marked required. Run advisory in parallel with the existing lane for ~1 week (≥5 random-seed runs). Existing lane keeps `continue-on-error: true` during this window.
  - **PR-C:** Flip the existing lane to halt-on-failure (`continue-on-error: false`); delete the advisory lane; mark the strict gate as required in branch protection. **Branch-protection update is `szTheory`-only** (admin action — flag in plan).
- **D-08-14:** Random seed retained in CI (no `--seed 0` pin). Deterministic seed is a debugging aid, not a CI strategy — masks ordering bugs.
- **D-08-15:** AsyncAdapter behaviour MUST honor `Mailglass.Tenancy.with_tenant/2` re-stamping (D-21) — the `:inline` impl re-stamps the tenant context the same way the prod path does, to keep test/prod parity.

### REL-11: Credo --strict Scope (Oban-Style Hybrid)

- **D-08-16:** **`strict: true`** in `.credo.exs`; `--mute-exit-status` REMOVED from `ci.yml` Credo step; `continue-on-error: false`. Custom checks (LINT-01..12) stay at default priority — they already block at default and need no elevation.
- **D-08-17:** **Fix in Phase 8** (Phase-9-stable, won't be churned by API redesign):
  - 5 Warning findings (real bugs / `length/1` on test data, `comparison will always return true`)
  - 4 `Refactor.Nesting` / `CyclomaticComplexity` hotspots inside `installer/apply.ex` and `webhook/providers/postmark.ex`
  - 1 `%Postgrex.Result{}` `@spec` leak in `Mailglass.Repo`
  - `@moduledoc false` added to two test fixtures (`Mailglass.FakeFixtures.TrackingMailer`, `Mailglass.FakeFixtures.TestMailer`) — don't disable the `Readability.ModuleDoc` check; it's high-signal in `lib/`.
- **D-08-18:** **Document baseline disables** in `.credo.exs` `:disabled_checks` — Oban pattern, with `# Reason:` + `# Tracking:` comment block above each entry:
  - `Credo.Check.Refactor.Apply` — Reason: stylistic; conflicts with deliberate `apply/3` use in adapter dispatch. Tracking: permanent.
  - `Credo.Check.Refactor.LongQuoteBlocks` — Reason: macro-heavy library; `quote do` blocks in `Mailable`/`MailglassAdmin.Router` are intentionally long for use injection. Tracking: permanent.
  - `Credo.Check.Readability.AliasOrder` — Reason: low signal in a 33k-LOC codebase with mixed nesting depth. Tracking: permanent (Oban posture).
  - `Credo.Check.Design.AliasUsage` — Reason: 102 findings, 99% in test files where nested-module-aliases are deliberate scoping. Tracking: permanent.
  - `Credo.Check.Readability.PreferImplicitTry` — Reason: explicit `try`/`rescue` in `webhook/providers/sendgrid.ex` and `webhook/plug.ex` documents the rescue-and-rewrap contract for `Mailglass.SignatureError`. Tracking: permanent (house style).
  - Tag any tracked-to-Phase-9 entries (e.g., `is_error?/1`) with `# Tracking: Phase 9 rename` so they get re-evaluated when API redesign lands.
- **D-08-19:** **`scripts/check_credo_suppressions.sh`** — simple grep CI gate (paired with the dialyzer one — same shape) asserting every `false`-tuple in `.credo.exs` `:disabled_checks` is preceded by both a `# Reason:` AND `# Tracking:` line. Runs as a step in the `credo_strict` CI job before `mix credo --strict`.
- **D-08-20:** Predicate function `Mailglass.Error.is_error?/1` — **DO NOT** rename in Phase 8. Suppress inline with `# credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames -- Tracking: Phase 9 rename to error?/1` until Phase 9 lands the rename as part of API redesign.
- **D-08-21:** `:included` config stays `["lib/", "test/"]` — do NOT add `credo_checks/` (Credo would lint its own checks → false positives). Document this in a `.credo.exs` comment to prevent future "fix."

### REL-05: Release Please `extra-files` No-Op Resolution + v5 Timing

- **D-08-22:** **Keep + harden the Path 2 sed step** as the steady-state mitigation. **Reject** TypeScript plugin authorship — directly violates "no Node toolchain anywhere" engineering DNA (D-13-style). **Reject** `version.exs` refactor — Hex tarball packaging + `Code.eval_file` load-order risk introduces more failure modes than the sed currently has.
- **D-08-23:** **Hardening additions** to the sed step:
  - Add `shellcheck` of the workflow run-block in CI
  - Unit/fixture test runs the sed against a fixture `mix.exs` and asserts the output (lives in `test/fixtures/release_please_sed_test.sh` or similar)
  - Add an `exit 1` guard if the regex matches **zero** lines — catches future renaming of the dep tuple
  - Generalize the path/dep handling into a small bash loop iterating over a workflow-level array of `{path, dep_atom}` pairs, so adding `mailglass_inbound` at v0.5 is a one-line config change
- **D-08-24:** **Compile-time anchor** for the sed regex — add an assertion (test in `mix_config_test.exs` OR a 13th custom Credo check) that `mailglass_admin/mix.exs` declares the dep in the literal `{:mailglass, "== <semver>"}` form the sed regex anchors on. Prefer the test path (lower friction; `mix_config_test.exs` already exists). Naming: `TEST-XX: mix.exs dep-pin regex anchor stability assertion` — flag for the planner to assign a REQ-ID if treated as a separate gate.
- **D-08-25:** **Document in `CONTRIBUTING.md`** — section title "Why we sed mix.exs after release-please runs" with: empirical no-op observation reference, recursion-safety guarantee (GITHUB_TOKEN), pointer to the lessons-learned TODO marked "decided steady state." If `CONTRIBUTING.md` doesn't yet exist, scaffold it as part of REL-05's plan.
- **D-08-26:** **release-please-action v5.0.0 upgrade — DEFER to Phase 13** (release ceremony). Phase 8 keeps the pin at `googleapis/release-please-action@5c625bfb5d1ff62eadeeb3772007f7f66fdcf071` (v4.4.1, 2026-02-20). Rationale: v5.0.0 has 4 days of public soak as of 2026-04-26; Node 24 runtime introduces regression surface; bundling the upgrade into Phase 13 places it in a release moment where someone is already paying close attention. Open a tracking note in `.planning/STATE.md` blockers/concerns or a v0.3 backlog item.

### Cross-Cutting Themes (auto-applied across all 4 areas)

- **D-08-27:** **"Documented decisions, not silent suppressions"** — both Dialyzer and Credo ignore/disable lists use the same `# Reason:` comment convention enforced by paired CI shell scripts (`scripts/check_dialyzer_ignore.sh` + `scripts/check_credo_suppressions.sh`). Same shape, same enforcement style — auditable in PR review.
- **D-08-28:** **Oban as project archetype.** Where multiple Elixir libs offered patterns (Phoenix, Ecto, Ash, Bamboo, Swoosh, Oban), mailglass picks Oban's posture: strict-with-curated-disables Credo, `:no_opaque` Dialyzer flags, `:inline` testing mode for async work, top-level supervised dispatcher with explicit ownership opt-out. Justification: Oban is the closest mailglass analog (custom-checks-as-real-contract, batteries-included, hard Postgres dep, Phoenix-adjacent).
- **D-08-29:** **Phase 9 firewall.** Decisions in Phase 8 explicitly avoid touching modules slated for Phase 9 redesign (`Mailable`, `Message`, `Outbound` mailer DSL, `import Swoosh.Email` site at `mailable.ex:129`). The Credo Refactor fixes target `installer/apply.ex` and `webhook/providers/postmark.ex` precisely because they are Phase-9-stable. The AsyncAdapter behaviour lands in Phase 8 by user decision (over the alternative of deferring to Phase 9), with the understanding that Phase 9 may evaluate whether to expose it on the public API surface — for now it stays internal.

### Claude's Discretion

- Exact CI step ordering within `ci.yml` (where to place the new `tests-strict` lane, where the new shell-script gate steps slot in) — planner decision.
- Specific bash-loop syntax for the generalized sed step in REL-05 — implementation detail.
- Whether the `mix_config_test.exs` regex-anchor assertion (D-08-24) is one test or split across multiple — planner judgment.
- Audit pass to identify which of the ~11 currently-failing tests need `@tag async: false` vs which can run async with the `:inline` adapter — derive from a `mix test --seed <random>` 3x run during planning.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 8 — Requirements + Pitfalls
- `.planning/REQUIREMENTS.md` — Pillar C / REL-01..REL-12 rows (lines 59–72)
- `.planning/research/PITFALLS.md` §REL-01 (CRITICAL — `on: release:` trigger correction; lines 469–490)
- `.planning/research/PITFALLS.md` §REL-02 (HIGH — Dialyzer 230 findings triage; lines 493–514)
- `.planning/research/PITFALLS.md` §CROSS-02 (HIGH — dep conflict matrix on adopter upgrade; lines 542–563)
- `.planning/research/SUMMARY.md` "Five corrections" paragraph (lines 18–19) — Dialyzer flag, publish trigger, Multi ordering, controller-in-core, mailable injection site

### v0.1.2 Debt TODOs (each REL- maps to one or more)
- `.planning/todos/pending/2026-04-26-publish-hex-workflow-run-gate-cant-detect-tag-creation.md` (REL-01)
- `.planning/todos/pending/2026-04-26-post-publish-smoke-version-resolution-bug.md` (REL-01 sibling)
- `.planning/todos/pending/2026-04-26-exclude-claude-md-from-hexdocs.md` (REL-02)
- `.planning/todos/pending/2026-04-26-strip-internal-decision-ids-from-public-guides.md` (REL-02)
- `.planning/todos/pending/2026-04-26-rename-verify-phase-nn-aliases-to-semantic-names.md` (REL-03)
- `.planning/todos/pending/2026-04-26-add-installer-goldens-to-publish-check.md` (REL-04)
- `.planning/todos/pending/2026-04-26-release-please-extra-files-no-op-on-managed-mix-exs.md` (REL-05)
- `.planning/todos/pending/2026-04-26-advisory-matrix-failing-db-setup-and-1-17-compat.md` (REL-06)

### Engineering DNA + Brand
- `/Users/jon/projects/mailglass/CLAUDE.md` "Engineering DNA — Conventions That Are Non-Negotiable" section
- `.planning/PROJECT.md` Engineering DNA section + "Pluggable behaviours over magic" + "Errors as a public API contract" + "Custom Credo checks at lint time" + "no Node toolchain anywhere" (D-13)

### Codebase Files Phase 8 Will Touch
- `mix.exs` (root) — `:dialyzer` config, `aliases/0` rename, `extras:` / `groups_for_extras:` (CLAUDE.md exclusion)
- `mailglass_admin/mix.exs` — same `:dialyzer` config, separate `.dialyzer_ignore.exs`, `extras:` / `groups_for_extras:`
- `.credo.exs` — `strict: true`, `:disabled_checks` baseline with comment convention
- `.github/workflows/ci.yml` — Tests/Credo/Dialyzer step changes, new `tests-strict` lane, PLT cache key fix, `continue-on-error` removals, ignore-script gate steps
- `.github/workflows/publish-hex.yml` — `on: release: types: [published]` + `mix hex.info` pre-check
- `.github/workflows/post-publish-smoke.yml` — same trigger swap
- `.github/workflows/release-please.yml` — sed-step hardening (shellcheck, exit-1 guard, bash-loop generalization)
- `.github/workflows/advisory-matrix.yml` — DB setup + 1.17 compile fixes
- `lib/mailglass/outbound.ex` — `Task.Supervisor.start_child` call sites become AsyncAdapter dispatches (lines 437, 607 — verify in plan)
- `test/support/` — new `Mailglass.TestSupport.CitextProbe` module
- `test/support/case_templates/` — `MailerCase`, `DataCase`, `WebhookCase`, `AdminCase` setup hardening
- `scripts/check_dialyzer_ignore.sh` (new)
- `scripts/check_credo_suppressions.sh` (new)
- `CONTRIBUTING.md` — REL-05 section (or scaffold if missing)
- `guides/*.md` — D-NN/LINT-NN strip pass + `mix mailglass.docs.check` grep gate
- `lib/mix/tasks/mailglass.docs.check.ex` (new) — internal-ID grep CI gate
- `mix_config_test.exs` — REL-05 dep-pin regex anchor assertion

### Ecosystem Prior Art Cited
- [Oban `mix.exs` + `.credo.exs`](https://github.com/oban-bg/oban) — Dialyzer flags, strict-with-disables Credo, inline-mode testing
- [Ash Framework `mix.exs`](https://github.com/ash-project/ash/blob/main/mix.exs) — `:no_opaque, :no_match` flag for Elixir 14837
- [Dialyxir 1.4.7](https://hexdocs.pm/dialyxir/readme.html) — flag verification, ignore-file format
- [Ecto.Adapters.SQL.Sandbox](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html) — shared-mode + Caller Tracking docs
- [Oban Testing](https://hexdocs.pm/oban/testing.html) — `:inline` mode pattern (mailglass mirrors for AsyncAdapter)
- [Elixir issue #14837](https://github.com/elixir-lang/elixir/issues/14837) — 1.18 opaque-type Dialyzer regression (justifies `:no_opaque`)
- [release-please-action v4.4.1 ↔ v5.0.0](https://github.com/googleapis/release-please-action/releases) — Node 24 runtime, defer rationale

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Mailglass.Clock` injection pattern** (`lib/mailglass/clock.ex` + `Mailglass.Clock.System` / `Mailglass.Clock.Frozen`) — exact template for the new `Mailglass.Outbound.AsyncAdapter` behaviour. Same Application-env-keyed injection, same prod-default + test-default split, same boundary-test posture.
- **Oban testing config** (existing `MailerCase` with `oban: :inline` default + `oban: :manual` opt-in) — extend the same `set_mailglass_global` pattern to flip the AsyncAdapter from `:inline` → `:task_supervisor`.
- **`probe_until_clean/5` helper in `persistence_integration_test.exs`** — extracts directly into `Mailglass.TestSupport.CitextProbe.run/1`. The 5-iteration retry loop semantics carry over.
- **`Mailglass.OptionalDeps` gateway pattern** (`available?/0` + `@compile {:no_warn_undefined, ...}`) — not re-used in Phase 8, but the comment-convention idea (every entry has a documented reason) is the same shape that REL-11/REL-12 ignore lists adopt.
- **`mix_config_test.exs`** at `mailglass_admin/test/` (lines 79–83 already document `Code.string_to_quoted` evaluation of the deps function under load isolation) — natural home for the REL-05 dep-pin regex anchor assertion (D-08-24).
- **Existing `MailerCase.async_adapter` env isolation** (mentioned in REL-10 row) — already a hooked seam; the new AsyncAdapter behaviour can subsume it.

### Established Patterns

- **"Pluggable behaviours over magic"** (PROJECT.md) — `Mailglass.Tenancy`, `Mailglass.Clock`, `Mailglass.Adapters` (Fake/Swoosh), `Mailglass.OptionalDeps`. The new `Mailglass.Outbound.AsyncAdapter` slots into this pattern as the 5th first-class behaviour. Narrow callbacks: `dispatch(fun, opts)` is likely the only callback.
- **"Custom Credo checks at lint time"** — 12 checks in `credo_checks/`; the dialyzer-ignore comment validator and credo-suppressions comment validator are NOT custom Credo checks (they're shell scripts in `scripts/`) because they validate config files (`.dialyzer_ignore.exs`, `.credo.exs`), not Elixir source. Different tool for a different surface.
- **"Errors as a public API contract"** — informs the `# Reason:` comment convention on ignore/disable lists. Each entry is a public commitment about a known-unfixable type/style signature, just as `Mailglass.Error{:type}` is a public commitment about a closed atom set.
- **PLT caching with key composition** — already in `ci.yml`; the fix is to ensure `${{ matrix.otp }}` is part of the key (verify in plan).

### Integration Points

- **`Mailglass.TaskSupervisor`** — top-level supervised in `Mailglass.Application`. The AsyncAdapter `TaskSupervisor` impl wraps `Task.Supervisor.start_child(Mailglass.TaskSupervisor, fun, opts)`. The `Inline` impl just calls `fun.()`. **Critical:** `:inline` impl MUST re-stamp tenant context via `Mailglass.Tenancy.with_tenant/2` (D-21) for prod-test parity — see D-08-15.
- **Outbound `deliver_later/2` call sites** — `lib/mailglass/outbound.ex` lines 437 + 607 (verify exact lines in plan; counts may have drifted post-publish). Each call to `Task.Supervisor.start_child` becomes `AsyncAdapter.dispatch/2`.
- **Existing CI Dialyzer step** at `ci.yml:251–260` — `continue-on-error: true` + `mix dialyzer --halt-exit-status`. Phase 8 transforms this into: `continue-on-error: false` + `mix dialyzer` (the `--halt-exit-status` flag does not exist; default already halts; `--ignore-exit-status` was the advisory flag, removed by D-08-09).
- **Existing CI Credo step** at `ci.yml:195–204` — `mix credo --mute-exit-status`. Phase 8 transforms this into: `continue-on-error: false` + `mix credo --strict` (preceded by `scripts/check_credo_suppressions.sh`).
- **Existing CI Tests step** at `ci.yml:155–168` — `continue-on-error: true` + `mix test --warnings-as-errors`. Phase 8's PR-A leaves this untouched, PR-B adds an advisory `tests-strict` lane, PR-C flips this lane to `continue-on-error: false`.

</code_context>

<specifics>
## Specific Ideas

- **Oban as the project archetype** — explicitly cited across all 4 research areas. When a Phase 8 implementation question has multiple plausible Elixir-ecosystem answers, prefer the Oban convention.
- **Same-shape comment convention across Dialyzer + Credo suppression lists** — `# Reason: <one-line>` on the line immediately preceding each entry, validated by paired shell scripts. Auditable in PR review at a glance.
- **1-day Dialyzer triage tripwire** — if the budget blows, that's a signal to spawn a v0.3 Dialyzer-deep-clean phase, not to pad the ignore file. Discipline is what makes the file durable.
- **3-PR rollout for the Tests gate** — slow on purpose; ships green throughout; PR-C's branch-protection update is the only `szTheory`-admin step.
- **AsyncAdapter is internal-for-now.** Phase 9 may decide to elevate it to the public API surface (it's a natural extension point for adopters wanting a custom supervisor strategy). For Phase 8, document it as an internal seam with `@moduledoc false`. The user explicitly chose this path over deferring to Phase 9.

</specifics>

<deferred>
## Deferred Ideas

### Deferred to Phase 9 (Mailable API Redesign + Freeze)
- **Rename `Mailglass.Error.is_error?/1` → `error?/1`** — folded into the API redesign (already breaking-changes territory). Phase 8 suppresses inline with `# credo:disable-for-next-line ... -- Tracking: Phase 9 rename`. (D-08-20)
- **AsyncAdapter behaviour public-surface decision** — Phase 9 evaluates whether to elevate `Mailglass.Outbound.AsyncAdapter` from internal seam to documented public-surface extension point in `api_stability.md` v2. (D-08-29)

### Deferred to Phase 13 (Release Ceremony)
- **release-please-action v5.0.0 upgrade** — Node 24 runtime + 4 days public soak as of 2026-04-26. Re-evaluate at Phase 13 against whatever v5.x SHA is current. (D-08-26)

### Deferred to v0.3 (or later)
- **Dialyzer overflow** — if more than 15 ignore entries are needed after Phase 8's 1-day triage, open a "Dialyzer-deep-clean" research phase rather than padding. (D-08-07)
- **Custom Credo check banning `@dialyzer {:nowarn_function, ...}` source pragmas** — backlog item, not Phase 8 deliverable. (D-08-08)
- **`:underspecs` Dialyzer flag** — opt-in only after the ≤15-entry baseline is hit. Useful for a public-API library but noisy on initial triage.

### Deferred to v0.5+
- **`mailglass_inbound` packaging hardening** — extend the bash-loop generalization in REL-05 to include the third sibling pin. The loop's data structure (`{path, dep_atom}` array) is designed to make this a one-line change. (D-08-23)

### Reviewed Todos (not folded)
None — all 9 v0.1.2 todos in `.planning/todos/pending/` are explicitly mapped to REL- requirements in this phase.

</deferred>

---

*Phase: 8 - Release-Engineering Hardening*
*Context gathered: 2026-04-26*
