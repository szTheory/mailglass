# Maintaining Mailglass

This document covers the release flow and maintenance protocols for Mailglass.

## Current protected release and recovery path

Executable controls and exact GitHub, Git, and Hex evidence are authoritative;
this section is the human entry point for that current state-based path. It does
not grant release authority that the controls do not grant.

1. Start from a preserved, clean repository state and run:

       mix mailglass.repo.hygiene --check --format json

   Treat a malformed, unavailable, pending, stale, wrong-SHA, or mismatched
   artifact/summary result as non-success. Record unavailable acquisition as
   `cannot-check`; do not translate it into an absent condition or a pass.
2. Ordinary push, schedule, and blank-digest dispatch are proposal-only: they
   may create or synchronize a Release Please proposal, but cannot merge, tag,
   or publish. Review that proposal and its exact identity without treating a
   release-please run as protected authority.
3. The only release boundary is a **protected exact-candidate dispatch** of
   `.github/workflows/release-please.yml` with a nonempty candidate digest.
   That digest must exactly validate the tracked release target, and the
   dispatcher must receive a fresh exact repository-admin authorization from
   GitHub. A candidate mismatch, blank digest, unavailable authorization, or
   non-admin response is non-success, never a recovery shortcut.
4. Inspect the resulting exact run/SHA rather than a branch name or a latest
   run. Use `node scripts/ci_monitor.cjs inspect <run-id>` and
   `node scripts/ci_monitor.cjs artifacts <run-id>` to bind the conclusion and
   retained artifacts to that exact run. Any malformed, stale, wrong-SHA, or
   mismatched artifact/summary evidence is non-success.
5. Require current-main scheduled-control evidence for `release-please`,
   `repo-hygiene`, and `post-publish-smoke`; a manual dispatch does not replace
   scheduled evidence. Each applicable row must have matching event, run,
   workflow-SHA, and retained-artifact provenance, ending in pass or its
   defined evidence-backed blocked disposition. `pending` and `cannot-check`
   do not satisfy the requirement.
6. After publication, perform immutable post-publish target validation through
   the protected `post-publish-smoke` path. Its explicit dispatch inputs are
   the exact published versions and immutable 40-character target SHA; do not
   substitute `main`, a release-event no-op, or a different identity. Preserve
   the exact target result and its artifacts before describing recovery as
   complete.

Historical procedures below remain provenance only. They are not an alternate
current runbook and do not supersede the protected exact-candidate and
repository-admin conditions above.

## Trust runner checkpoint handoff

Use `mix verify.reference_host.journey` as the canonical trust-runner command.
By default it writes the checkpoint artifact to
`tmp/mailglass_trust_runner/checkpoint.json`.

This trust-runner flow and reference-host evidence are usage-proof artifacts,
not API-contract truth. Stable guarantee semantics are defined by the canonical
stability inventories in [`docs/api_stability.md`](docs/api_stability.md) and
[`mailglass_inbound/docs/api_stability.md`](mailglass_inbound/docs/api_stability.md),
with executable contract truth enforced through
`mix verify.stability_contract`.

Checkpoint consumers should require these keys exactly:

- `schema_version`
- `claim_boundary`
- `checkpoint_count`
- `checkpoint_sha256`
- `checkpoints`

Validate artifacts with
`bash scripts/check_trust_runner_checkpoint.sh --checkpoint tmp/mailglass_trust_runner/checkpoint.json`.

Phase 58 extends this contract with signed-negative webhook and non-happy-path
diagnosis semantics; it does not redefine or rename the Phase 57 stage keys.

## Snapshot Update Protocol

When the installer output or golden files change:

1. Run `mix verify.installer.golden`.
2. If the failure is expected, update the golden files in `test/fixtures/`.
3. Commit the updated fixtures with a `chore: update installer golden files` message.

## Publish Summary Snapshot Protocol

The files under `.planning/publish/*-publish-summary.json` are tracked release
proof snapshots, not scratch output.

- Refresh them with `mix mailglass.publish.check` for the affected package(s).
- Review the diff together with the paired `*-files.expected` allowlist diff.
- Commit the snapshot update when the underlying package contents or version
  truth changed intentionally.

Do not gitignore these files: `test/mailglass/stability_contract_test.exs`
reads the inbound summary directly as part of the sibling-package release
contract.

## Tarball Allowlist Protocol

Adding a file under a published package's `lib/` changes what ships to Hex, and
`mix mailglass.publish.check` blocks the release until the new file is recorded:

```
Delivery blocked: package files diff. Files added since last allowlist
update: ["lib/mailglass/<new_file>.ex"]
```

This fires in `publish-hex`'s `prepublish-summary` job — *before* `gate-ci-green`
— so the publish fan-out stops with every publish job skipped. Nothing reaches
Hex. That is the gate working: a new file entered a published tarball and it
refused to ship it unreviewed.

Update the allowlist in the same PR that adds the file:

1. Run `mix mailglass.publish.check --package <pkg> --keep`.
2. Copy `_publish_check/<pkg>-files.actual` over
   `.planning/publish/<pkg>-files.expected`. Do not hand-edit — the ordering
   is generated.
3. Re-run without `--keep` and confirm `conflict=0`.

If the file should *not* ship, exclude it in `mix.exs` under `:package :files`
instead. Dev-only Mix tasks belong in `dev/`, which is on `elixirc_paths` for
`:dev`/`:test` only and never enters the tarball.

Note that `.planning/` is in release-please's `exclude-paths`, so an
allowlist-only commit is **not** release-triggering. If a tag has already been
cut without the allowlist update, the fix cannot reach that tag by merging to
`main` — the publish workflow checks out the tag ref, not `main`. Either retag
or cut a new patch version.

## JTBD Docs Refresh Protocol

The JTBD docs are a two-file system:

- `guides/jobs.md` is the **public adopter ramp-up guide**
- `.planning/research/JTBD-COVERAGE.md` is the **internal source of truth**

Always refresh the internal map first, then project the stable Built rows into
the public guide.

### Refresh order

1. Read the current:
   - `guides/jobs.md`
   - `.planning/research/JTBD-COVERAGE.md`
   - `README.md`
   - `CHANGELOG.md`
   - `.planning/PROJECT.md`
   - `.planning/ROADMAP.md`
   - `.planning/REQUIREMENTS.md`
   - `.planning/STATE.md`
2. Reconcile shipped behavior against live code. When planning artifacts
   disagree, prefer live code, then `PROJECT.md`, then `ROADMAP.md`, then phase
   summaries/verification, and treat `STATE.md` as last-resort bookkeeping.
3. Run a primary-source ecosystem sanity check before changing priority claims.
   Current comparison set:
   - Rails Action Mailer
   - Rails Action Mailbox
   - Anymail
   - Laravel Mail
   - Resend inbound docs
4. Update `.planning/research/JTBD-COVERAGE.md`:
   - refresh built/planned/deferred statuses
   - refresh the active gap list
   - refresh the priority ordering
   - refresh the diminishing-returns line
   - append a row to the refresh log
5. Update `guides/jobs.md` from that map:
   - stable shipped jobs only
   - keep the narrative, adopter-facing framing
   - keep inbound summarized separately, noting its own independent `2.x` contract
     and routing readers to `mailglass_inbound/docs/api_stability.md`
6. Refresh dates in both files with exact calendar dates.
7. Update README or docs navigation only if the JTBD docs became harder to
   discover.
8. Run the docs contract tests before merging.

### Guardrails

- Do not let `guides/jobs.md` become a roadmap doc.
- Do not let `JTBD-COVERAGE.md` become feature-inventory churn; it is about
  adopter jobs, gaps, and priority.
- If external research reveals only convenience asks, do not promote them above
  trust-proof or inbound-maturity work.

## Required Checks

The honest repo-root entrypoint is `mix verify.stability_contract` or
`scripts/verify_support_contract.sh`. They run the three required
branch-protection buckets plus the inbound sibling-package docs lane in sequence:
- `Support Contract Core`
- `Support Contract Admin`
- `mailglass_inbound` docs contract (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`)
- `Compile No Optional Deps`

Branch protection requires exactly **two** contexts: `CI Green` and
`Guard Release Trigger` (`scripts/setup_branch_protection.sh`, asserted by
GATE-01 in `test/scripts/required_checks_test.exs`). The five merge-gating
lanes below (`compile_no_optional_deps`, `installer_host_smoke`,
`support_contract_core`, `support_contract_admin`, `trust_lane_repo_head`) are
the members of `ci_green.needs` — they gate a merge through the `CI Green`
aggregator, they are **not** required contexts in their own right. Confusing a
`ci_green.needs` member with a required context is the job-`id`-vs-display-`name`
mismatch that opened this milestone.

Release trust claims also require green trust evidence beyond the required
branch-protection contexts: the clean-baseline and published-version trust
journeys must complete, and the `trust-runner-repo-head`,
`trust-runner-clean-baseline`, and `trust-runner-published` checkpoint artifacts
must be present and valid.

Owner-applied branch protection:
- `GH_TOKEN=<admin-pat> ./scripts/setup_branch_protection.sh main`

Read-only branch-protection verification:
- `./scripts/verify-branch-protection.sh --print-expected`
- `./scripts/verify-branch-protection.sh --print-expected-json`
- `GH_TOKEN=<admin-pat> ./scripts/verify-branch-protection.sh main`

When those checks pass, they prove the current compatibility contract described
in [`guides/compatibility-and-deprecations.md`](guides/compatibility-and-deprecations.md):
runtime floors, matched sibling-package docs wiring for `mailglass_inbound`,
matched `mailglass_admin` release truth, and the classification/disposition
table below. Do not claim broader support than those repo artifacts prove.

This table is the single classification statement for the section. It answers
two questions a table cell cannot hold on its own:

1. **Two axes.** This table is the *classification* axis — "what does this
   lane block?" `Mailglass.CILanes.advisory_lanes/0` answers a different
   question — "does `mix ci` reproduce this lane locally?" A lane is routinely
   in both (`Dialyzer` is locally reproduced *and* publish-gating).
2. **Never promote a *statically-named* matrix lane into the exact-equality
   required set.** GitHub appends matrix values to a matrix job's `name:` at
   runtime **only when that `name:` contains no matrix expression**, so
   `gate-ci-green` would report a promoted statically-named matrix lane
   `(missing)` and block every publish. `dialyzer`, `operator_browser_gate` and
   `preview_capture_advisory` are the three `ci.yml` matrix lanes today, and all
   three are statically named — the rule applies to them in full.

   The carve-out: a matrix job that interpolates **every** matrix axis into its
   own `name:` gets no appended suffix, because there is nothing left to
   disambiguate. `advisory-matrix.yml`'s jobs are all of this shape, which is why
   exact-equality matching is safe for them and why the § "Advisory Matrix Lanes"
   table below names them leg-by-leg. Verified against live API responses for
   both shapes; see `.planning/phases/143-test-harness-truth/143-RESEARCH.md`
   § "Runtime vs Declared Job Names". The distinction is machine-checked by
   `Mailglass.CIYaml.expanded_matrix_job_names/1`, which refuses to expand a
   statically-named matrix job rather than guessing its suffix.

`classification` is one of `required`, `advisory`, `publish-gating`,
`structural`. `disposition` is one of `promote`, `keep-with-reason`, `retire`.
`promote` records a recommendation only — it does not mean the lane has been
executed into that state; see each `promote` row's `reason` cell.

| job id | display name | classification | disposition | reason |
|---|---|---|---|---|
| `compile_no_optional_deps` | `Compile No Optional Deps (Elixir 1.18 / OTP 27)` | required | keep-with-reason | Optional-deps gateway is a locked engineering-DNA guarantee. |
| `installer_host_smoke` | `Installer Host Smoke` | required | keep-with-reason | Shift-left consumer-install proof; promoted from advisory. |
| `support_contract_core` | `Support Contract Core (Elixir 1.18 / OTP 27)` | required | keep-with-reason | Stability/API contract. |
| `support_contract_admin` | `Support Contract Admin (Elixir 1.18 / OTP 27)` | required | keep-with-reason | Sibling-package release truth. |
| `trust_lane_repo_head` | `Trust Lane Repo Head (Elixir 1.18 / OTP 27)` | required | keep-with-reason | Repo-head trust journey. |
| `deps_audit_advisory` | `Deps Audit (Elixir 1.18 / OTP 27)` | required | keep-with-reason | Promoted from advisory (Phase 142/VULN-03) and renamed to drop the misleading "Advisory" suffix from its display name — a merge-gating lane whose name still says advisory is the signal-honesty defect this milestone exists to fix (D-06). The shared allowlist (Phase 142/VULN-05) makes it trustworthy enough to merge-gate. |
| `operator_browser_gate` | `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)` | advisory | keep-with-reason | Node/Playwright; zero-Node is an adopter guarantee, so this stays advisory. One of the three matrix lanes - never promote to the exact-equality required set. |
| `demo_browser_evidence` | `Demo Browser Evidence (Docker Compose / Chromium)` | advisory | keep-with-reason | Docker-compose demo evidence; slow, environment-fragile. |
| `preview_capture_advisory` | `Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22)` | advisory | keep-with-reason | Node/Playwright preview capture. One of the three matrix lanes - never promote to the exact-equality required set. |
| `format_check` | `Format Check (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | Cheap hygiene; reproduced by `mix ci.fast`. |
| `compile_warnings` | `Compile Warnings as Errors (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | Reproduced by `mix ci.fast`. |
| `mix_task_tests` | `Mix Task Tests (Elixir 1.18 / OTP 27)` | required | keep-with-reason | Generator/CLI and CI-contract surface; a failure blocks CI Green and merge. |
| `inbound_test` | `Inbound Test (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | Sibling package on its own version line. |
| `inbound_compile_no_optional_deps` | `Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | Sibling optional-deps gateway. |
| `credo_strict` | `Credo Strict (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | Custom Credo checks enforce domain rules at lint time. |
| `conformance_gates` | `Design System Conformance (shell gates)` | publish-gating | keep-with-reason | Split from `credo_strict` per CONFORM-04; publish-gating per D-09. |
| `dialyzer` | `Dialyzer (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | Slow; publish-gating is the right cost/benefit. One of the three matrix lanes - never promote to the exact-equality required set. |
| `docs_warnings_as_errors` | `Docs Warnings as Errors (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | HexDocs quality gate; a broken docs build ships to hex.pm. |
| `hex_audit` | `Hex Audit (Elixir 1.18 / OTP 27)` | required | keep-with-reason | Promoted from publish-gating (Phase 142/VULN-03): the shared allowlist (`Mailglass.SupplyChain.AcceptedAdvisories`, Phase 142/VULN-05) makes the lane trustworthy enough to merge-gate — a non-accepted advisory now blocks a PR, not just a Hex publish. |
| `installer_golden_gate` | `Installer Golden Gate (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | Golden-file installer output; no local-parity step. |
| `trust_lane_clean_baseline` | `Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)` | publish-gating | keep-with-reason | Required for release trust claims above; GATE-01 (D-04) forbids making it a required context. Publish-gating is the only classification satisfying both. |
| `branch_protection_advisory` | `Branch Protection Advisory` | publish-gating | keep-with-reason | Classification goes live when Phase 144/TRUTH-02 makes it failable - today its only substantive step is `continue-on-error: true`, so the job never fails. Its name says "advisory" but its behavior is publish-gating (D-04). |
| `changes` | `Detect Non-Doc Changes` | structural | keep-with-reason | Path filter; every other lane's `if:` reads `needs.changes.outputs.code`. Not a check. |
| `ci_green` | `CI Green` | structural | keep-with-reason | Aggregator; it is one of the two branch-protection contexts - required at the context level, not as a leaf. Must never appear in `REQUIRED_LANES` - that would be a self-referential gate. |

This table is verified against `Mailglass.CILanes` (`test/support/ci_lanes.ex`) by `test/scripts/lane_classification_drift_test.exs` — editing one without the other fails CI.

Required inbound release proof is deterministic repo/package/workflow evidence:
source and manifest parity, `mix mailglass.publish.check --package mailglass_inbound`,
publish-summary output, release workflow tag/package selection, and post-publish
Hex/HexDocs/smoke evidence when that publish phase runs.
Provider-live checks and ecosystem canaries remain advisory unless a specific
release claim explicitly depends on them.

The 24-row table above covers `ci.yml` only. The separate `advisory-matrix.yml`
workflow carries seven more lanes, enumerated leg-by-leg in the next section.
None of them is a member of `ci_green.needs`, so **none gates a merge** — but
"gates nothing at all" is no longer the whole story: two of the seven are the
declared publish-gating pair for HARNESS-04. None of the seven carries a runtime
matrix suffix, because each interpolates every matrix axis into its own `name:`;
the carve-out in point 2 above explains why, and why exact-equality matching is
safe for them.

`Provider Live Advisory` remains a cron and `workflow_dispatch` canary. It is not a merge blocker.

## Advisory Matrix Lanes

`.github/workflows/advisory-matrix.yml` runs on push to `main`, pull requests to
`main`, a nightly cron (`21 4 * * *`), and `workflow_dispatch`. Its four jobs
expand to **seven runtime lanes**, one per `strategy.matrix.include:` row. This
table is the classification statement for those seven; the § "Required Checks"
table above covers `ci.yml` and nothing else. Keeping them under separate
headings is structural, not stylistic — `lane_classification_drift_test.exs`
bounds each table's parser by its own top-level heading and asserts an exact row
count for each, so a row filed under the wrong heading fails CI.

**Names here are runtime names.** Every job in this workflow interpolates each
matrix axis into its `name:`, so GitHub reports them fully substituted with no
appended ` (<matrix values>)` suffix — unlike `ci.yml`'s statically-named matrix
jobs. `Mailglass.CIYaml.expanded_matrix_job_names/1` computes exactly this set
from the workflow source, and the drift test asserts it set-equals
`Mailglass.CILanes.advisory_matrix_gating_lanes/0` ∪
`advisory_matrix_advisory_lanes/0`.

**Two of these seven gate a Hex publish; the other five gate nothing.** As of
Phase 143 plan 13, `gate-ci-green` reads `advisory-matrix.yml` as well as
`ci.yml`, and the two Elixir 1.18 / OTP 27 `Core Full Suite` legs block a
publish when they are red, cancelled, skipped, or absent. Their rows therefore
read `publish-gating` / `keep-with-reason`, which is the honest current state —
they were `advisory` / `promote` while the promotion was only a recommendation.
The verdict, its evidence, and its accepted costs are recorded in
`.planning/phases/143-test-harness-truth/143-GATING-DECISION.md`. The remaining
five rows stay `advisory`: classified, enumerated, warned on, never blocking.

**Gating the two floor legs is wider than the lane name reads.** They are steps
of the `core_full_suite` job, which also runs `mix deps.get` and
`mix ecto.create -r MailglassInbound.TestRepo` inside `mailglass_inbound`, and
then `mix verify.schema_prefix`. Gating the lane gates those three steps too. The
next-toolchain legs run none of them.

| job id | display name | classification | disposition | reason |
|---|---|---|---|---|
| `core_full_suite` | `Core Full Suite (Elixir 1.18 / OTP 27 / schema public)` | publish-gating | keep-with-reason | The HARNESS-04 publish-gating pair, live since Phase 143 plan 13. Elixir 1.18 / OTP 27 is the `~> 1.18` floor `mix.exs` states, so gating it preserves LD-13's floor-coincidence invariant. Also gates the inbound `deps.get`, the inbound `ecto.create`, and `mix verify.schema_prefix`. Renamed from `core_full_suite_advisory` (D-21): a lane that gates a publish must not call itself advisory. |
| `core_full_suite` | `Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)` | publish-gating | keep-with-reason | Second schema axis of the same job (D-06). The isolated `mailglass` schema exercises the Phase 134 migration entrypoint end-to-end; its executed-count floor is pinned separately from `public`'s because `test_helper.exs` excludes `:public_only` here. |
| `core_full_suite_next_toolchain_advisory` | `Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema public)` | advisory | keep-with-reason | Forward-compatibility canary on the next Elixir/OTP line; renamed from job key `core_latest_elixir_advisory` (D-21), since *latest* implies preferred while *next* reads as the canary it is. Carries `if: github.event_name != 'pull_request'`, so its absence on a PR run is a designed outcome, not a missing lane. Never gate the next line — that is LD-13's invariant read backwards. |
| `core_full_suite_next_toolchain_advisory` | `Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema mailglass)` | advisory | keep-with-reason | Second schema axis of the canary. Enforces the suite floors measured on the 1.18 legs, with a `>=` comparison, so a real divergence reds an advisory job visibly instead of passing silently. |
| `provider_compatibility_advisory` | `Provider Compatibility Advisory (Elixir 1.18 / OTP 27)` | advisory | keep-with-reason | `mix verify.provider_compatibility`. Advisory by the fake-adapter-is-the-gate DNA: real-provider surface checks inform, they do not block. |
| `mailglass_inbound_dual_schema_advisory` | `Inbound Full Suite Advisory (schema public)` | advisory | keep-with-reason | Not gated despite being green (D-20): it pins `--seed 0` specifically to dodge the known phase-45 property-test pool flake, and a lane whose green depends on a seed chosen to avoid a known nondeterminism is not trustworthy enough to gate a publish. Revisit when the pin is removed. |
| `mailglass_inbound_dual_schema_advisory` | `Inbound Full Suite Advisory (schema mailglass)` | advisory | keep-with-reason | Second schema axis of the inbound suite (D-13 / INB-03). Same `--seed 0` reasoning as the row above. |

Note that `job id` repeats across rows here and display names do not: one job
expands to one runtime lane per matrix row. That is the opposite of the
§ "Required Checks" table, where each row is a distinct job.

This table is verified against `Mailglass.CILanes` and against
`advisory-matrix.yml` itself by `test/scripts/lane_classification_drift_test.exs` —
editing any one of the three without the others fails CI.

## Bus Factor & Continuity

Mailglass is single-maintainer at v0.1. The release pipeline is intentionally
hands-free after the repo-proved gates pass: `gate-ci-green` checks the release
SHA and the `hex-publish` environment has no required reviewers. This is
documented honestly here rather than presented as a stronger human approval
control than it is. Multi-owner Hex transition is deferred to v0.5, when
production adopters exist (D-26 rationale: at v0.1 the asymmetry of a co-owner
being able to `mix hex.publish` from their own machine bypassing GitHub
governance is a worse footgun than the bus-factor risk it solves).

If `szTheory` is unreachable for more than 30 days, the community can request a
Hex.pm package transfer by opening a public issue titled
`Maintainer-unreachable: requesting Hex transfer` on
https://github.com/szTheory/mailglass/issues — Hex.pm's public maintainer-transfer
process can be initiated from there.

## Retract Decision Tree

Five rules. Bias toward patch over retract — three retractions in your first six
months tells evaluators "don't bet on this lib."

1. **Data-loss / security / signature bypass / fails to compile.**
   Run `mix hex.retire <pkg> <ver> security|invalid --message "<140 chars>"`
   AND ship `<ver+1>` immediately.
2. **User-visible breakage with workaround.**
   Do NOT retire. Patch within 7 days. Add a CHANGELOG entry.
   If the fix changes a documented compatibility bridge or support claim, update
   `guides/compatibility-and-deprecations.md` in the same patch.
3. **Cosmetic / docs / non-runtime.**
   Do NOT retire. Roll into next planned patch.
4. **Published less than 60 minutes ago AND zero downloads.**
   Run `mix hex.publish --revert <ver>` (only window where unpublish works —
   also bounded by Hex.pm's 24-hour initial-release window).
5. **Already retired and false alarm.**
   Run `mix hex.retire <pkg> <ver> --unretire`.

### `~>` Sibling Pin: Rollback Lever for a Bad Core Patch

As of v1.15 Phase 125, `mailglass_inbound` and `mailglass_admin` use pessimistic
`~>` constraints on `mailglass` core instead of exact `==` pins. This changed the
resolver's degrees of freedom: a core patch release now auto-resolves into `~>`
sibling adopters' dependency graphs (previously the `==` wall blocked it structurally).

**If a bad core patch slips through and reaches adopters via the `~>` constraint:**

```
mix hex.retire mailglass X.Y.Z security|invalid --message "<140 chars describing the issue>"
```

This tells the Hex resolver to stop selecting that version. Follow immediately
with a fixed `X.Y.(Z+1)` core release so the `~>` constraint resolves to the
safe version instead. The sibling packages themselves need no change — their
`~>` constraint automatically picks up the new patch.

**Contrast with the old `==` behavior:** with exact pins, a bad core patch could
never silently reach inbound adopters because the inbound `== X.Y.Z` constraint
would hold them on the prior version until a deliberate paired inbound release.
`mix hex.retire` is the explicit replacement for that structural guarantee.

## Dependency Advisory Triage

Not every advisory arrives as a dependabot pull request. Dependabot can only
ever propose a fix for a *direct* dependency it controls the version
constraint for — it cannot auto-file a fix for a Hex transitive dependency
whose advisory can only be closed by bumping a *parent* package's version
constraint. That is documented upstream Dependabot behavior, not a repo
defect. The `hpax` advisory this milestone opened on is the literal case: no
PR was ever possible for it, and the finding sat unactioned until someone read
`mix hex.audit` and `mix deps.audit` output directly. Reading raw audit output
by hand is therefore the only path for that class of advisory, not a fallback
for when the PR queue is running behind.

**Who:** `szTheory`, the sole maintainer (see "Bus Factor & Continuity" above).

**What:** run `mix mailglass.audit --kind hex` (which wraps `mix hex.audit`)
and `mix mailglass.audit --kind deps` (which wraps `mix deps.audit`) locally,
or read the `Hex Audit` / `Deps Audit` CI job logs on `main` (both cover all
three Mix projects — root, `mailglass_admin`, `mailglass_inbound`). This is a
different activity from clearing the open dependabot PR queue: the PR queue
only ever proposes a fix for a direct dependency, so a clean queue proves
nothing about a transitive finding with no PR attached to it.

**How often:** weekly, aligned with `.github/dependabot.yml`'s existing weekly
schedule, plus immediately whenever `Hex Audit` or `Deps Audit` goes red on
`main` — both lanes are merge-gating as of Phase 142/VULN-03, so a red state is
visible the moment it happens instead of waiting for the next scheduled pass.

**Response expectation, by severity** — bounded to what one unpaid maintainer
can sustainably keep, matching the Security Response SLA numbers below:
written to be kept, not aspired to.

- **HIGH / CRITICAL:** within 14 days — a patch, or a dated allowlist
  exception recorded with a reason and a `recheck_by` date. Mirrors the
  "Mitigation or workaround for critical issues" number below.
- **MEDIUM:** within 30 days.
- **LOW:** at the next scheduled weekly triage — no forced timeline.

A missed cycle does not lose signal: the next `mix hex.audit`/`mix deps.audit`
run re-surfaces every outstanding advisory from scratch, so nothing is
silently dropped, only delayed. Mailglass is single-maintainer (see "Bus
Factor & Continuity" above), so concurrent-maintainer triage races are out of
scope for this cadence — that is an already-documented posture, not a new gap
this section invents.

## Security Response SLA

Single-maintainer numbers, written to be kept rather than aspired to.

- **Acknowledgement of report:** within 72 hours.
- **Mitigation or workaround for critical issues:** within 14 days.
- **Public security advisory:** published alongside the fix.

Critical issue classes are listed in `SECURITY.md` (`## Critical Classes`).
Reports go through the disclosure address documented there or via GitHub
Private Vulnerability Reporting if no email is reachable.

## Historical release procedures

The following Phase 38 and Phase 73 v1 procedures are retained for historical
provenance and their original-version applicability only. They are non-current:
do not use their auto-merge, fan-out, manual smoke, tag, or fallback language as
authority for a current release or recovery. The current protected path is the
one at the start of this document.

Five historical steps. Step 4 had a literal 60-minute timer — that was the last
revert window before the published artifact became permanent.

Use the Phase 38 release-day proof forms while running these steps:
- `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md`
- `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md`

For the inbound-only `mailglass_inbound 1.0.0` slice, use the inbound-specific companion forms:
- `.planning/phases/73-inbound-1-0-publish-evidence/73-01-RELEASE-RECORD.md`
- `.planning/phases/73-inbound-1-0-publish-evidence/73-01-RELEASE-CHECKLIST.md`

The archived Phase 38 forms remain the linked core/admin v1.0 record; the Phase 73 forms cover
the inbound-only slice.

The checklist separates repo-proved gates from manual/external proof and forces
explicit capture of the tag, workflow run URLs, approver identity, fallback
usage, Hex/HexDocs checks, branch-protection result, and 60-minute outcome.

1. **Verify CI green on `main` for the SHA to be released.**
   Check `actions/workflows/ci.yml` — required because publish-hex.yml gates
   on this SHA via the `gate-ci-green` job (per Plan 08, D-16).
   The required release-truth buckets are:
   - `Support Contract Core (Elixir 1.18 / OTP 27)`
   - `Support Contract Admin (Elixir 1.18 / OTP 27)`
   - `Compile No Optional Deps (Elixir 1.18 / OTP 27)`
   - `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`
   - `Installer Host Smoke` (shift-left consumer-install smoke; promoted from advisory)
   - Phase 38 prepublish proof/export bundle (`38-01-PREPUBLISH-PROOF.md`)
   - Phase 38 install/upgrade rehearsal artifact (`38-02-REHEARSAL-EVIDENCE.md`)
   - Trust-runner checkpoint artifacts:
     `trust-runner-repo-head`, `trust-runner-clean-baseline`, and
     `trust-runner-published`

   The post-publish trust journey is the EVID-03 sentinel. It must be green
   before milestone trust claims or v1.3 closeout language is accepted.
2. **Merge the release-please PR.**
   Squash-merge keeps the changelog history linear.
   Review the release PR diff before merge. This repo uses a custom
   mailglass_admin dep-pin sync step, so the generated PR is load-bearing.
   The current release path emits package tags such as `mailglass-v<version>`
   and `mailglass_admin-v<version>`.
   If a broad milestone PR was squash-merged under a non-releasable subject
   and release-please skips the cut, recover with a tiny follow-up commit that
   carries a `Release-As: <intended-version>` footer. Do not hand-edit
   `.release-please-manifest.json` to force the version.
3. **Monitor the hands-free publish fan-out.**
   Review the pre-publish summary in the workflow run page (rendered by the
   `prepublish-summary` job per D-15) after `gate-ci-green` passes and the
   publish jobs fan out. Verify the file count, total size, CHANGELOG excerpt,
   and top files all match expectations.
   Record the tag, publish workflow run URL, `gate-ci-green` result, and publish
   fan-out status in `38-03-RELEASE-RECORD.md`.
   - **Package order:** The workflow guarantees `mailglass` (core) publishes first, then `mailglass_inbound`, then `mailglass_admin`. Admin waits on inbound to avoid sibling-package Hex indexing races.
   - **Idempotency:** All three publish steps check `mix hex.info` first and skip the publish command if the version is already live, making the workflow safe to retry.
   - **Core Full Suite is a publish gate (HARNESS-04).** `gate-ci-green` reads
     `advisory-matrix.yml` as well as `ci.yml`. The two Elixir 1.18 / OTP 27
     `Core Full Suite` legs block the publish when either is red, cancelled,
     skipped, or absent. The other five advisory-matrix lanes only warn.
     - **The gate DISPATCHES the run; it does not look one up.** A release-please
       bot-merged release SHA has zero `advisory-matrix.yml` runs — GitHub raises
       no workflow for a `GITHUB_TOKEN` event, and that workflow has no `release:`
       trigger. So `gate-ci-green` dispatches it on the release tag and waits, under
       one 30-minute deadline shared with the `ci.yml` self-heal. Expect roughly ten
       extra minutes of cold-cache release wall-clock. A missing run is a stall, not
       a pass: the gate blocks rather than reporting success it did not observe.
     - **Override, for a block with no regression behind it.** The gated job also
       runs the inbound `mix deps.get`, the inbound `mix ecto.create`, and
       `mix verify.schema_prefix`, so a Hex outage or a Postgres hiccup can block a
       release that has nothing wrong with it. Recover without a code change by
       dispatching with the override:

           gh workflow run publish-hex.yml \
             -f tag=mailglass-v<version> -f package=all -f dry_run=false \
             -f skip_core_full_suite_gate=true \
             -f core_full_suite_gate_skip_reason="<why>"

       It is **dispatch-only and inert on the `release` event** — the hands-free
       path can never self-skip its own gate. The reason is required, is echoed to
       the run summary, and the run logs a warning naming the override as an
       exception. Prefer re-running the lane
       (`gh workflow run advisory-matrix.yml --ref <tag>`) and re-dispatching the
       publish; reach for the override when the lane cannot be made green for a
       reason that is not about this release's code. An override reached for
       reflexively is a gate that has been removed without anyone recording it.
   - **Fallback path:** If the Release Please tag/release exists but `publish-hex` did not fan out, dispatch `.github/workflows/publish-hex.yml` manually (with `package=all`, `dry_run=false`, and `core_full_suite_gate_skip_reason="n/a"` — that input is required on every dispatch, and `n/a` is the right answer when you are not overriding anything). **Do not dispatch from `main`**. Always use the reviewed release tag for the package being recovered so the publish run is pinned to the exact commit Release Please tagged. For an inbound-only `mailglass_inbound-v1.0.0` publish or recovery, dispatch `package=mailglass_inbound` pinned to the `mailglass_inbound-v1.0.0` tag; the fan-out skips `publish-core` and does NOT trigger `publish-admin`, so no `mailglass`/`mailglass_admin` release is forced. The `publish-inbound`/`publish-admin` success/skipped gating is a security control — do not loosen it.
4. **Within 60 minutes of publish: smoke-install in a fresh Phoenix app.**
   Set a literal timer when approving the deployment.
   Run:

       mix archive.install hex phx_new --force
       mix phx.new sandbox --no-ecto --no-mailer --install
       cd sandbox
      # add {:mailglass, "~> 1.3"}, {:mailglass_admin, "~> 1.3"}, {:mailglass_inbound, "~> 1.0"} to deps
       mix deps.get && mix mailglass.install && mix compile --warnings-as-errors
       mix phx.server  # visit http://localhost:4000/dev/mail/

   If anything fails AND the publish was less than 60 minutes ago AND zero
   downloads have happened, the Retract Decision Tree rule 4
   (`mix hex.publish --revert`) is reachable. After 60 minutes the only
   options are retire-then-patch (rule 1) or patch-only (rule 2).
Keep the published support story honest: if the smoke or support-contract
   checks reveal a mismatch with the documented matrix or upgrade posture, fix
   the guide and package metadata together rather than carrying split truth.
   For inbound-slice changes, rerun `mix verify.stability_contract` so the
   repo-root lane proves the canonical `mailglass_inbound` docs and support
   posture before you publish.
   If you need to reproduce the v0.2 codemod or rollback story during this
   window, do it in a disposable fixture or git-clean worktree only. The
   public rollback contract is git-based review/revert of the upgrade diff,
   not cleanup of arbitrary dirty repositories.

   The post-publish-smoke workflow (`.github/workflows/post-publish-smoke.yml`,
   Plan 09) runs the same smoke automatically — but it does not respect the
   60-minute window. Run the manual smoke during the window regardless.
   If publish succeeds but smoke does not fan out, use `workflow_dispatch` on
   `.github/workflows/post-publish-smoke.yml` with that same core tag.
   Record the post-publish smoke run URL, whether fallback dispatch was used,
   Hex/HexDocs URLs, and the final 60-minute decision in the Phase 38 release
   record.
5. **Post the release link to Elixir Forum #libraries section** (post-publish, optional
   — performed by maintainer on their own cadence; not gated by Phase 07.1's
   milestone-shipped marker per CONTEXT line 14 / line 351).
   Body equals the GitHub Release narrative (CHANGELOG entry verbatim plus
   one framing paragraph for 0.x.0 minor bumps; verbatim CHANGELOG only for
   patches).
