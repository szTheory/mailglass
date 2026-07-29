# Phase 137: Linked 2.0 release ceremony + milestone closeout - Context

**Gathered:** 2026-07-03 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Design Phase F of v2.0 Postgres Schema Isolation. Cut the **linked-version 2.0 release**
— `mailglass` + `mailglass_admin` both to `2.0.0` (release-please linked-versions group),
plus a paired `mailglass_inbound` bump — through the v1.15-hardened pipeline (`mix ci`
tiers, `CI Green` fan-in gate). Apply the coordinated reference-baseline update, prove
consumer + post-publish smoke green, then audit + archive the milestone.

**In scope:** version-trigger mechanism, sibling dep-pin edits, reference-baseline advance,
smoke verification, milestone audit + archive. **Out of scope:** any product/schema-behavior
change (that all landed in 132–136); this phase ships what's built, it does not build.

Requirements: REL-01, REL-02, REL-03.
</domain>

<decisions>
## Implementation Decisions

### Version-trigger mechanism (the 2.0.0 major)
- **D-01:** No `feat!:`/`BREAKING CHANGE:` marker is banked in 132–136 (all commits are
  `feat()/fix()/docs()/test()/ci()`), so left alone release-please would cut 1.12.0/1.12.0/1.7.0.
  Force the major with an explicit **`Release-As: 2.0.0`** footer on an empty commit for the
  linked core+admin group, and a **separate `Release-As: 2.0.0`** footer for standalone
  `mailglass_inbound`. Prefer `Release-As` over a `BREAKING CHANGE:` footer — `Release-As`
  names the exact target; a breaking footer only guarantees "a major," not "2.0.0."
- **D-02:** **Rehearse before merge (user-chosen).** Open/inspect the release-please PR and
  confirm it targets `2.0.0`/`2.0.0` (linked core+admin) AND `2.0.0` (inbound) BEFORE merging —
  this catches any per-component path-attribution issue with RP v5's handling of the empty
  `Release-As` commit. Do NOT belt-and-suspenders pre-edit `.release-please-manifest.json`;
  the manifest edit is the documented fallback only if the dry-run PR shows wrong targets.

### Sibling dep-pin edits (manual, pre-release)
- **D-03:** The `{:mailglass, "~> ..."}` constraints in `mailglass_admin/mix.exs` (currently
  `~> 1.10`) and `mailglass_inbound/mix.exs` (currently `~> 1.10 and >= 1.10.2`) do NOT
  auto-update on release — release-please's sed only rewrites README/display pins, never
  `mix.exs`. Hand-edit both to `~> 2.0` (in the `MIX_PUBLISH == "true"` branch of each
  `mailglass_dep/0`) and commit before the RP PR opens, or `publish-admin`/`publish-inbound`
  fail version-solving against a 2.0 core after core has already published.

### Inbound version + floor
- **D-04:** Bump `mailglass_inbound` to **2.0.0** (not the minor 1.7.0 RP would score). Phase 135
  gave inbound its own breaking changes: 7 loose `change/0` migrations → version-dispatcher
  pattern, and default schema moved to `mailglass`. Semver-major.
- **D-05:** Inbound's core constraint becomes **`{:mailglass, "~> 2.0"}`** — drop the
  `and >= 1.10.2` floor (it only ever excluded the broken 1.10.0/1.10.1 core builds; no analog
  on the fresh 2.0 line). Keep the loosened `~>` — do NOT reintroduce an `==` re-pin (that
  retires the v1.15 keystone win). **The design dossier's `== <core>` language (§3.7 L372,
  §3.9 L398, Phase F L555) is STALE** — superseded by the v1.15 loosened-pin keystone; override it.

### Reference baseline advance
- **D-06:** `~> 1.0` → `~> 2.0` is a **real mix.exs + mix.lock edit this time** for both
  `reference/host_app` and `reference/demo_app` — the "one-command bump" only held within 1.x
  (a major crosses the tilde boundary). The `check_clean_baseline_hex_only.sh` guard is
  version-agnostic (asserts `:hex` source + well-formed version, no hardcoded version list),
  so no script/contract-test edit is needed for the version move itself. Regenerate the lock
  siblings-only (no transitive drift); demo_app needs `MAILGLASS_DEMO_DEPS=hex`.
- **D-07:** **Adopt the new `mailglass` default schema in the reference baseline (user-chosen)** —
  do NOT pin `config :mailglass, :schema, "public"`. The frozen baseline should dogfood the
  real 2.0 behavior an adopter gets (tables land in `mailglass.*`). **Consequence the planner
  must handle:** this relocates the baseline's tables, so the trust-journey checkpoint contract
  (`check_trust_runner_checkpoint.sh` / `ci_trust_lane_contract_test.exs`) may need updating to
  expect the schema-qualified shape — treat any drift as an intended baseline advance, not a
  regression. Verify the trust-journey + clean-baseline lanes green under the new schema before
  declaring REL-02.

### Smoke verification (no code change expected)
- **D-08:** `post-publish-smoke.yml` is already 2.0-ready — the missing-checkout fix
  (commit 67f4b33d) is present and inbound-compat detection is `~>`-aware (greps
  `(==|~>|>=)`, not a bare `== ` literal). `scripts/consumer_install_smoke.sh` writes
  self-consistent `== 2.0.0` sibling pins that resolve against inbound's `~> 2.0` core pin.
  Verify these empirically (dry-run / post-publish), do NOT pre-edit the smoke scripts.

### Milestone closeout (REL-03)
- **D-09:** Standard GSD closeout: `gsd-audit-milestone` (132–136 vs schema-isolation intent)
  → `gsd-complete-milestone` → `gsd-cleanup`. **Manually correct MILESTONES.md/STATE.md to the
  true 132–137 span** — gsd-sdk `milestone.complete`/`phase.complete` over-count leftover phase
  dirs (999.x backlog) and can inflate stats / mis-flag last-phase. RP auto-creates the three
  `-v2.0.0` tags. Refresh the MEMORY release-state file and CLAUDE.md current-state line to
  `2.0.0 / 2.0.0 / 2.0.0`.

### Standing release lessons to dogfood (from prior cuts)
- **D-10:** Follow the documented pipeline lessons: push-before-merge surfaces never-CI'd
  regressions (expect a "CI-the-body" catch on first real CI of the accumulated 132–136 body);
  validate the WHOLE publish lane not just required jobs; **racing fan-outs mean a red
  `publish-hex` run does NOT imply a failed publish** (admin `needs:[publish-core,publish-inbound]`
  can succeed while core/inbound tag-runs red on transient TLS) — VERIFY via `mix hex.info` +
  consumer smoke, never the run status.

### Claude's Discretion
- Exact ordering of the pre-release edit commit(s) vs. the empty `Release-As` commit(s), and
  whether the two `Release-As` footers ride one commit or two, is left to the planner/executor
  provided the dry-run PR (D-02) confirms correct targets before merge.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/milestone-schema-isolation/SCHEMA-ISOLATION-DESIGN.md` §3.7–3.9, §5 Phase F
  — decisions of record. **CAVEAT:** its `== <core>` inbound-pin language is STALE (see D-05).
- `release-please-config.json` + `.release-please-manifest.json` — linked-versions group
  (`mailglass` + `mailglass_admin`); inbound is standalone.
- `.github/workflows/release-please.yml` — Release-As handling, tag mapping (L59–66), the
  README/display-pin sed step (does NOT touch mix.exs, L115–120).
- `.github/workflows/post-publish-smoke.yml` — checkout fix (67f4b33d), `~>`-aware inbound-compat.
- `scripts/consumer_install_smoke.sh` — consumer smoke body (phx.new → deps → install → boot →
  assert `GET /dev/mail/` == 200).
- `scripts/check_clean_baseline_hex_only.sh` + `test/mailglass/publish/ci_trust_lane_contract_test.exs`
  — version-agnostic trust-lane guards.
- `mailglass_admin/mix.exs` (L147 pin) + `mailglass_inbound/mix.exs` (L143 pin) — hand-edit targets.
- `reference/host_app/mix.exs` (L35–37) + `reference/demo_app/mix.exs` — baseline constraints.
- MEMORY (durable release gotchas — read before publish):
  `project_v1_15_release_state` (loosened-`~>` keystone, racing fan-outs, post-publish-smoke fix),
  `project_reference_baseline_coupling` (version-agnostic guard; coordinated advance),
  `project_release_engineering_gotchas`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The v1.15-hardened release pipeline is the vehicle: `mix ci` tiers, `CI Green` fan-in gate,
  release-please auto-merge on green, `publish-hex` environment (no required reviewer),
  post-publish-smoke + consumer-install smoke — all in place, no rebuild.
- Version-agnostic trust-lane guards mean the baseline version move needs no script edits.

### Established Patterns
- Linked-versions plugin drags admin with core; inbound is bumped independently by RP scoring
  (hence the standalone `Release-As` for inbound).
- Baseline advance = coordinated mix.exs + mix.lock change across host_app + demo_app,
  siblings-only lock diff, `MAILGLASS_DEMO_DEPS=hex` for demo_app.

### Integration Points
- Inbound `~> 2.0` core pin is the load-bearing edit that lets the fan-out resolve at publish.
- Reference baseline adopting the `mailglass` default schema (D-07) couples to the trust-journey
  checkpoint contract — the one place a schema change ripples into an existing test/guard.
</code_context>

<specifics>
## Specific Ideas

- User explicitly chose: baseline **adopts the new `mailglass` default** (dogfoods real 2.0
  behavior), and the version trigger is **rehearsed via RP dry-run PR before merge** (not a
  belt-and-suspenders manifest pre-edit).
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within the release-ceremony phase scope.

### Reviewed Todos (not folded)
None matched this phase.
</deferred>
