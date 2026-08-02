# Phase 141: Lane Truth Foundation - Context

**Gathered:** 2026-07-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Every CI lane in this repository carries exactly one recorded, machine-verified classification instead of
five disagreeing registries and an undocumented default bucket — and the `phases.clear` tooling defect that
deleted planning artifacts twice is written down where a third occurrence would be recognized.

**In scope:** TRUTH-09, TRUTH-07, TRUTH-05, CONFORM-04, HIST-01.

**Out of scope** (inherited from `.planning/REQUIREMENTS.md` "Out of Scope", binding):
- CI topology rewrite — no splitting, merging, or restructuring workflows beyond what a named requirement
  demands. The one exception is CONFORM-04's `credo_strict` job split, pre-authorized by research as
  "a rename + one job-boundary split, not a redesign."
- Promoting any lane to merge-gating (that is Phase 142/VULN-03 for the audit lanes, and Phase 143/HARNESS-04
  for Core Full Suite). Phase 141 **classifies and records**; it does not change what blocks a merge.
- A release cut, product features, admin UI work, rebuilding `ICON-EXISTS-GATE`.
- Fixing the `if: pat_present`-skip-but-still-green shape (TRUTH-02, Phase 144) or the audit-allowlist
  plumbing (VULN-05, Phase 142) — Phase 141 records their lanes' dispositions, it does not implement them.
</domain>

<decisions>
## Implementation Decisions

### Registry Reconciliation (TRUTH-07, TRUTH-09)

- **D-01:** `Mailglass.CILanes` (`test/support/ci_lanes.ex`) is the single authoritative registry. The other
  registries are verified against it by a test that fails on drift — not maintained independently.

- **D-02:** The classification becomes **three named buckets, not two**. Add an explicit publish-gating
  bucket (recommended name: `@publish_gating_lanes` / `publish_gating_lanes/0`) alongside `required_lanes/0`
  and `advisory_lanes/0`. Every currently-hidden `ci.yml` job defaults into it, so **today's effective
  publish posture is preserved byte-for-byte**. The tier stops being *hidden* without becoming *removed*.
  - Rationale: 5 of the 14 hidden jobs are deliberately publish-gating per `MAINTAINING.md:160-164`
    ("release trust claims also require green trust evidence beyond the required branch-protection
    contexts"). Collapsing to two buckets would either let a Hex publish proceed with red Dialyzer / red
    audit lanes, or promote them to merge-gating — contradicting D-04 for Trust Lane Clean Baseline and
    lengthening every PR's critical path (the SEED-006 cost).
  - **User-confirmed decision.** This was escalated per METHODOLOGY.md's release/publish-posture bar and
    answered explicitly: "Name the third tier."

- **D-03:** Because D-02 deviates from TRUTH-09's literal wording ("classified as merge-gating **or**
  advisory"), this phase **amends TRUTH-09's text in `.planning/REQUIREMENTS.md`** to the three-bucket model.
  The requirement's *intent* — "no job may sit in neither and thereby block publish by accident" — is met in
  full; the letter is updated so the requirement and the implementation do not themselves become a sixth
  disagreeing registry. Do not silently satisfy one and violate the other.

- **D-04:** Delete the `/ Advisory \(/` convention regex at `publish-hex.yml:269`. `gate-ci-green` enumerates
  all three sets explicitly instead.
  - Rationale: the regex requires a leading space **and** a literal `(` after "Advisory", so
    `Branch Protection Advisory` (`ci.yml:1080`) already escapes it today — a lane whose own name says
    "advisory" is publish-blocking in principle. A convention-based matcher keeps minting new hidden lanes
    as jobs are added. (Currently moot only because that job's substantive step carries
    `continue-on-error: true` at `ci.yml:1108`; Phase 144/TRUTH-02 makes it failable, at which point the
    misclassification goes live.)

### Disposition Table (TRUTH-05)

- **D-05:** The written disposition table lives in **`MAINTAINING.md` §"Required Checks"**, rewritten as one
  table with columns `job id | display name | classification | disposition | reason`. No new `.planning/`
  register is created.
  - Rationale: `ci_lanes.ex:16` already cites `MAINTAINING.md:152-191` as authoritative — honoring that
    citation is cheaper than relocating it. `MAINTAINING.md` survives milestone archival and is readable by
    outside contributors; the existing register precedents (`.planning/RATCHET-GAP-REGISTER.md`,
    `.planning/research/v1.14/DEFECT-REGISTER.md`) are both milestone-scoped and would not.

- **D-06:** A new meta-test in `test/scripts/` (sibling to `required_checks_test.exs`) parses
  `publish-hex.yml`'s JS array literals and `MAINTAINING.md`'s table rows and asserts them against
  `ci_lanes.ex`. It carries an anti-vacuity guard in the style of `required_checks_test.exs:30-34` and
  `:102-107` — a parser that silently matches nothing must fail loudly, not pass.
  - **No new dependency.** `required_checks_test.exs:159-267` already hand-parses shell arrays, heredoc
    bullets, YAML job keys/`name:`/`needs:`/`if:` clauses. Parsing two JS arrays and a markdown table is the
    same technique. `.planning/research/v2.2/SUMMARY.md` locks "no new dependency" for this milestone.

- **D-07:** Every lane in the reconciled set carries a disposition of **promote / keep-with-reason / retire**.
  "Promote" here means *recorded as the recommendation* — the actual promotion of Hex Audit and Deps Audit is
  Phase 142/VULN-03's work and must not be executed in this phase.

### CONFORM-04 — Rename and Job Split

- **D-08:** `credo_strict` **splits into two jobs**, not merely renamed:
  - `credo_strict` — display name unchanged (`Credo Strict (Elixir 1.18 / OTP 27)`), now honest because it
    runs only `mix credo --strict` + `check_credo_suppressions.sh`.
  - `conformance_gates` — new job, recommended display name
    `Design System Conformance (Elixir 1.18 / OTP 27)`, running `check_motion_conformance.sh` +
    `check-conformance.sh` + `check-conformance-advisory.sh`.
  - Rationale: ROADMAP criterion 3 requires that a maintainer can tell **"from the name alone"** which of the
    two failed — a single composite name cannot satisfy that. `.planning/research/v2.2/SUMMARY.md`
    pre-authorizes the split as in-scope.

- **D-09:** Both resulting jobs land in the **publish-gating bucket** (D-02), preserving current effective
  status. Neither becomes merge-gating in this phase.

- **D-10:** **The rename has zero branch-protection blast radius — verified live, not inferred.**
  `gh api repos/szTheory/mailglass/branches/main/protection --jq '.required_status_checks.contexts'` returned
  exactly `["CI Green","Guard Release Trigger"]` on 2026-07-28, matching
  `scripts/setup_branch_protection.sh:17-20` and the assertion at `test/scripts/required_checks_test.exs:45-58`.
  No `ci.yml` leaf is a required context, so no renamed display name can linger as a stale required check.

- **D-11:** Exact-string sites that must move **atomically** with the split: `ci.yml:395`, `ci_lanes.ex:63`,
  `test/scripts/ci_parity_drift_test.exs:109` (matcher map key) and `:187` (anti-vacuity `matcher_lanes`
  MapSet), the new `gate-ci-green` entry, and the `MAINTAINING.md` table row.

- **D-12:** Do **not** add a `mix ci` matcher entry claiming local parity for the new conformance lane.
  `mix.exs:364-394` shows the `ci`/`ci.fast` aliases run `credo --strict` but **none** of the three
  conformance shell scripts. The new lane belongs in the module-doc "intentional exclusions" list
  (`ci_lanes.ex:29-46`), not in `advisory_lanes_ci`.

- **D-13:** Accept the ~2-3 min wall-clock cost of the extra runner (duplicated `setup-beam` / `deps.get` /
  cache). Note it in the plan as a SEED-006 input; do not optimize it here — that milestone is deliberately
  sequenced after v2.2.

### Adjacent Truth-Gaps Folded In (user-selected)

- **D-14:** **`CONTRIBUTING.md:116` is corrected.** It is a *fifth* registry the milestone scope did not
  count, claiming branch protection requires `Tests`, `Credo Strict`, `Dialyzer`, `actionlint`, and
  `PR title (semantic)` — **all five are wrong** (truth: `CI Green` + `Guard Release Trigger`, confirmed live
  per D-10). Leaving it would make the reconciliation incomplete by its own standard.

- **D-15:** **`MAINTAINING.md`'s internal self-contradiction is resolved.** Lines 134-142 list
  `mix credo --strict` and `mix dialyzer` as required-before-merge; lines 180-191 list them as advisory; lines
  153-158 carry the true required set. Unavoidable to fix, since `MAINTAINING.md` is the file being made
  authoritative by D-05.

### HIST-01 — Planning-History Integrity

- **D-16:** **The artifact restoration is already complete and byte-exact — budget no restoration work.**
  `b5fed519` ("docs: start milestone v2.1") deleted 48 files under `.planning/phases/132-*`…`137-*`;
  `a629fb82` restored all 48 under `.planning/milestones/v2.0-phases/`. A per-file SHA comparison against
  `b5fed519^` found **0 missing, 0 differing**. Re-deriving them risks overwriting good artifacts from a
  stale blob.

- **D-17:** The apparent gaps in `134` and `136` are **not deletion damage**. Those phases genuinely never had
  `CONTEXT.md` / `DISCUSSION-LOG.md` — they went straight to planning without a discuss step
  (`dc26471c docs(134): create phase plan`). Do not "restore" files that never existed.

- **D-18:** The **only remaining HIST-01 work is writing the defect record.** Create
  `.planning/TOOLING-DEFECTS.md` at the `.planning/` root — deliberately milestone-independent, unlike both
  existing register precedents, because the whole point is surviving a milestone boundary. It must carry a
  recognize-on-re-run symptom line: *`cleared: N` reported with no `milestones/<version>-phases/` directory
  written.*
  - Today the defect is recorded **only** in the commit body of `70099869`. A grep of `.planning/**/*.md` and
    `CLAUDE.md` finds `phases.clear` nowhere except `REQUIREMENTS.md:137` and `ROADMAP.md:59` as the
    requirement itself. A commit message is not "somewhere a future run would recognize it as a repeat" — the
    defect fired twice, and the second catch was luck.
  - **Recurrence risk is live:** v2.2's own milestone close invokes the same command against phases 141-144.

- **D-19:** The defect record is written as a **dated note with mitigations**, not a blanket "this command
  destroys data" warning. Verified 2026-07-28 against the installed `gsd-sdk v1.42.3`
  (`~/.claude/gsd-core/bin/lib/milestone.cjs`): `phases.clear` now archives rather than hard-deletes
  (`#1871`), refuses to run against uncommitted phase work (`#1447`), and accepts an explicit
  `--archive-version <outgoing>` override (`#2288`) precisely because `new-milestone` runs
  `state.milestone-switch` **before** `phases.clear`, so a live STATE.md read would file the archive under the
  *incoming* milestone. The record should therefore prescribe: pass `--archive-version` explicitly, and
  verify `milestones/<version>-phases/` exists after the run.

### Claude's Discretion

- Exact bucket accessor naming (`publish_gating_lanes/0` vs. an alternative) — kept decisive per
  METHODOLOGY.md; the planner may adjust to fit `ci_lanes.ex`'s existing naming style.
- The precise column set and row ordering of the `MAINTAINING.md` disposition table.
- Whether the meta-test is one file or split across two, provided the anti-vacuity guard holds.
- Whether `changes` and `ci_green` (both structural, not check lanes) get their own classification or a
  documented "structural — not a check lane" marker; either satisfies criterion 2 as long as neither sits
  unrecorded.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 141 goal + 5 success criteria (authoritative phase boundary)
- `.planning/REQUIREMENTS.md` — TRUTH-09, TRUTH-07, TRUTH-05, CONFORM-04, HIST-01 full text; the binding
  "Out of Scope" list. **Note D-03: TRUTH-09's wording is amended by this phase.**
- `.planning/STATE.md` §"v2.2 Milestone Intent" — the hidden-third-tier finding and the roadmap's
  regroup-by-dependency rationale
- `.planning/METHODOLOGY.md` — three active lenses; all three fired (see DISCUSSION-LOG)
- `.planning/research/v2.2/SUMMARY.md` — locks "no new dependency"; pre-authorizes the `credo_strict` split
- `.planning/research/v2.2/ARCHITECTURE.md:130-200` — near-complete tier table + concrete file list
  (**do not re-litigate**)
- `.planning/research/v2.2/PITFALLS.md:488-494` — "a real behavior change smuggled inside a cosmetic rename"
- `MAINTAINING.md` — lines 134-142, 153-158, 160-164, 180-191 (the registry being reconciled)
- `test/support/ci_lanes.ex` — the registry becoming authoritative
- `.github/workflows/ci.yml`, `.github/workflows/publish-hex.yml` — the lanes and the gate
- `CONTRIBUTING.md:116` — the fifth registry (D-14)
</canonical_refs>

<code_context>
## Existing Code Insights

### Ground truth: `gate-ci-green`'s exact matching logic (`publish-hex.yml:190-291`)

1. **Scope:** inspects **only `ci.yml`** runs on the tagged SHA (`workflow_id: 'ci.yml'`, line 229). Jobs from
   `advisory-matrix.yml`, `provider-live.yml`, `actionlint.yml`, `pr-title.yml`, and
   `guard-release-trigger.yml` are **never seen** — this is the seam Phase 143/HARNESS-04 will extend.
2. **Required:** exact string equality `j.name === lane` against a hardcoded 5-element `REQUIRED_LANES`
   (lines 204-210, matched at 252-259). Missing job → block. `conclusion !== 'success'` (including
   `skipped`) → block.
3. **Advisory predicate** (lines 267-269):
   `ADVISORY_LANES.some(lane => jobName.startsWith(lane)) || / Advisory \(/.test(jobName)`, where
   `ADVISORY_LANES = ['Operator Browser Gate', 'Demo Browser Evidence']`.
4. **The hidden tier** (lines 273-282): `conclusion !== 'success' && conclusion !== 'skipped'` AND
   `!isAdvisory` AND `!REQUIRED_LANES.includes` → `core.setFailed`, publish blocked. Publish-gating without
   being merge-gating.
5. **Advisory failures** (lines 284-291): `core.warning` only.

### Ground truth: all 23 `ci.yml` jobs

**5 required · 4 advisory-recognized · 14 hidden third tier.** (Roadmap and research said "9+"/11-12; the
three additional are `changes`, `ci_green`, and `Branch Protection Advisory`.)

| line | job id | display name | in `ci_green.needs`? | effective tier |
|---|---|---|---|---|
| 23 | `changes` | `Detect Non-Doc Changes` | No | HIDDEN |
| 66 | `format_check` | `Format Check (Elixir 1.18 / OTP 27)` | No | HIDDEN |
| 91 | `compile_warnings` | `Compile Warnings as Errors (Elixir 1.18 / OTP 27)` | No | HIDDEN |
| 116 | `compile_no_optional_deps` | `Compile No Optional Deps (Elixir 1.18 / OTP 27)` | **Yes** | Required |
| 144 | `installer_host_smoke` | `Installer Host Smoke` | **Yes** | Required |
| 178 | `support_contract_core` | `Support Contract Core (Elixir 1.18 / OTP 27)` | **Yes** | Required |
| 230 | `mix_task_tests` | `Mix Task Tests (Elixir 1.18 / OTP 27)` | No | HIDDEN |
| 286 | `inbound_test` | `Inbound Test (Elixir 1.18 / OTP 27)` | No | HIDDEN |
| 356 | `inbound_compile_no_optional_deps` | `Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)` | No | HIDDEN |
| 394 | `credo_strict` | `Credo Strict (Elixir 1.18 / OTP 27)` | No | HIDDEN ← CONFORM-04 target |
| 436 | `dialyzer` | `Dialyzer (Elixir 1.18 / OTP 27)` | No | HIDDEN |
| 501 | `docs_warnings_as_errors` | `Docs Warnings as Errors (Elixir 1.18 / OTP 27)` | No | HIDDEN |
| 528 | `hex_audit` | `Hex Audit (Elixir 1.18 / OTP 27)` | No | HIDDEN ← Phase 142/VULN-03 target |
| 553 | `deps_audit_advisory` | `Deps Audit Advisory (Elixir 1.18 / OTP 27)` | No | Advisory (regex) |
| 585 | `installer_golden_gate` | `Installer Golden Gate (Elixir 1.18 / OTP 27)` | No | HIDDEN |
| 635 | `support_contract_admin` | `Support Contract Admin (Elixir 1.18 / OTP 27)` | **Yes** | Required |
| 696 | `operator_browser_gate` | `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)` | No | Advisory (array) |
| 769 | `demo_browser_evidence` | `Demo Browser Evidence (Docker Compose / Chromium)` | No | Advisory (array) |
| 795 | `preview_capture_advisory` | `Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22)` | No | Advisory (regex) |
| 929 | `trust_lane_repo_head` | `Trust Lane Repo Head (Elixir 1.18 / OTP 27)` | **Yes** | Required |
| 1005 | `trust_lane_clean_baseline` | `Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)` | No | HIDDEN (D-04 says not-required; `MAINTAINING.md:160-164` implies publish-gating IS intended) |
| 1079 | `branch_protection_advisory` | `Branch Protection Advisory` | No | HIDDEN — regex misses it (no `(` after "Advisory"). Moot only because its substantive step is `continue-on-error: true` (line 1108); **Phase 144/TRUTH-02 makes this live** |
| 1129 | `ci_green` | `CI Green` | n/a (aggregator) | HIDDEN (blocking-if-red desirable but undeclared) |

`ci_green.needs` (`ci.yml:1133-1138`) lists exactly the 5 required job ids and is set-equality-enforced
against `CILanes.required_lanes/0` by `required_checks_test.exs:96-126` (GATE-03). **No equivalent test
exists for `publish-hex.yml` — that is the gap this phase closes.**

### The five disagreeing registries

| # | Registry | Location | How it disagrees |
|---|---|---|---|
| 1 | `Mailglass.CILanes` | `test/support/ci_lanes.ex:51-76` | Calls Credo Strict / Dialyzer / Hex Audit / Docs Warnings **advisory** — they are publish-gating. Omits 7 lanes entirely. |
| 2 | `gate-ci-green` JS | `publish-hex.yml:204-210`, `:220-223`, `:267-269` | Regex misses `Branch Protection Advisory`; nothing enumerates the 14-job third bucket. |
| 3 | `MAINTAINING.md` advisory prose | lines 180-191 | 11 short, unparenthesized names — **not matchable** against `ci.yml` `name:` strings. Omits 9 lanes. |
| 4 | `MAINTAINING.md` "Required Checks" prose | lines 134-142 | Lists credo/dialyzer as required-before-merge; contradicts registry 3 **and** lines 153-158. |
| 5 | `CONTRIBUTING.md:116` | one sentence | Claims 5 required contexts; **all 5 wrong**. |

### Lanes outside `ci.yml` (invisible to `gate-ci-green`)

`advisory-matrix.yml`: `core_full_suite_advisory` + `core_latest_elixir_advisory` (**two job ids sharing one
display-name template**, line 20/133), `provider_compatibility_advisory` (:219),
`mailglass_inbound_dual_schema_advisory` (:273 — `Inbound Full Suite Advisory`, **named in no registry**).
Also `provider-live.yml:599/:650`, `guard-release-trigger.yml:868` (a *required* context),
`actionlint.yml:802`, `pr-title.yml:834`, `branch-protection-drift.yml:550`, `gate-self-test.yml:30`,
`repo-hygiene.yml:742` (no `name:` field — defaults to `hygiene`).

### Reusable seams (no new dependency)

- `test/scripts/required_checks_test.exs:159-267` — hand-rolled parsers for shell arrays
  (`parse_required_checks`), heredoc bullets, YAML job keys→`name:` (`parse_ci_job_names`), `needs:` lists
  (`parse_ci_green_needs`), `if:` clauses. Anti-vacuity guards at `:30-34`, `:102-107`.
- `test/scripts/conformance_advisory_test.exs:66-79` — precedent for asserting on a *step block* inside
  `ci.yml` and refuting `continue-on-error: true`.
- `.github/workflows/gate-self-test.yml` — deliberate-failure-probe pattern, parameterized by `check_name`
  (lines 19-22); already supports polling a specific leaf lane. (Phase 143 reuses this; noted here because
  Phase 141 establishes the meta-test seam it builds on.)

### Integration points

- `ci_lanes.ex:16` — docstring citing `MAINTAINING.md:152-191` by line number
- `ci_lanes.ex:29-46` — module-doc "intentional exclusions" list (where the new conformance lane belongs)
- `ci_parity_drift_test.exs:109`, `:187` — matcher map key + anti-vacuity MapSet (rename blast sites)
- `scripts/setup_branch_protection.sh:17-20` — `REQUIRED_CHECKS=("CI Green" "Guard Release Trigger")`
</code_context>

<specifics>
## Specific Ideas

- **"Name the third tier" was the user's explicit call**, chosen over two literal alternatives, on the
  grounds that preserving publish posture beats satisfying TRUTH-09's letter. The plan must state
  *explicitly* which of the two it does — this choice must never be made by omission (per
  `.planning/research/v2.2/PITFALLS.md:488-494`).
- Live branch protection was verified by direct API call rather than inferred from
  `setup_branch_protection.sh` — a job-`id`-vs-display-`name` mismatch between script and live state is
  literally this milestone's originating incident, so the script alone was not accepted as proof.
- The defect record's value is its **symptom line**, not its narrative. Someone re-running the command must
  recognize the failure from what they see on screen.
</specifics>

<deferred>
## Deferred Ideas

- **Re-pointing `ci_lanes.ex:16`'s citation to `MAINTAINING.md`** — offered and **not selected** for this
  phase. Recorded consequence: D-05 rewrites the cited section, so the hardcoded `152-191` line range will
  go stale, which is Pitfall 9 (the confidently-worded citation nobody re-checks) inside the phase that
  exists to remove it. If the planner finds the range broken by its own edits, fixing it is a one-line
  mechanical correction — flagged here rather than silently folded in.
- **`Inbound Full Suite Advisory` (`advisory-matrix.yml:273`)** — offered and **not selected**. A lane named
  in no registry at all. Outside `ci.yml`, so `gate-ci-green` never sees it and it cannot join the hidden
  tier; classifying it would widen scope toward the `advisory-matrix.yml` seam that Phase 143/HARNESS-04
  owns.
- **Promoting Hex Audit / Deps Audit to merge-gating** — Phase 142/VULN-03. Phase 141 records the
  disposition only.
- **Making `Branch Protection Advisory` actually failable** — Phase 144/TRUTH-02. Phase 141 only records that
  its classification goes live when that lands.
- **Extending `gate-ci-green` to inspect `advisory-matrix.yml`** — Phase 143/HARNESS-04.
- **Wall-clock cost of the extra conformance runner** — SEED-006, deliberately sequenced after v2.2.

### Reviewed Todos (not folded)

- `2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` (match score 0.9) — **not folded.**
  Keyword-matched on "advisory/publish/check", but it is VULN-06's territory in **Phase 142**, and
  `.planning/REQUIREMENTS.md` already tracks it under "Future Requirements" pending an external upstream fix.
  VULN-06's re-check mechanism should surface it automatically once that fix lands.
</deferred>
