# Phase 142: Supply-Chain Remediation & Gating - Context

**Gathered:** 2026-07-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Every dependency advisory this repository can detect — direct or transitive — either blocks a merge or
carries a recorded, time-boxed exception. Nothing accumulates silently the way `hpax` and the 13-PR
dependabot backlog did.

**In scope:** VULN-05, VULN-03, VULN-06, VULN-02, VULN-04.

**Out of scope** (inherited from `.planning/REQUIREMENTS.md` "Out of Scope", binding):
- **No new dependency.** `mix_audit ~> 2.1` (`mix.exs:190`) and `mix hex.audit` already ship; the OSV
  staleness gate already ships. Locked by `.planning/research/v2.2/SUMMARY.md`.
- **CI topology rewrite** — no splitting, merging, or restructuring workflows beyond what a named
  requirement demands. The one authorized job-shape change is deleting `continue-on-error: true` from
  `deps_audit_advisory` and renaming its display name (D-08).
- **Re-classifying any lane other than Hex Audit and Deps Audit.** Phase 141 recorded the full 24-row
  disposition table; this phase executes exactly the two `promote` rows it recorded, and touches no other row.
- **A release cut**, product features, admin UI work.
- **Test-harness work** (HARNESS-01..04, Phase 143), the `if: pat_present`-skip-but-still-green shape
  (TRUTH-02, Phase 144), `ICON-EXISTS-GATE` verification (CONFORM-02, Phase 144), the publish fan-out race
  (TRUTH-08, Phase 144).
- **Extending `gate-ci-green` to inspect `advisory-matrix.yml`** — Phase 143/HARNESS-04. Both audit lanes
  live in `ci.yml`, which `gate-ci-green` already sees.
</domain>

<decisions>
## Implementation Decisions

### Shared Allowlist Mechanism (VULN-05)

- **D-01:** The single source is a new **data + logic module in `lib/`** — recommended
  `Mailglass.SupplyChain.AcceptedAdvisories` — holding the allowlist entries plus the two audit-output
  parsers, invoked by a new **dev-path** Mix task `mix mailglass.audit` at `dev/mix/tasks/mailglass.audit.ex`
  that both CI audit lanes call. `mix mailglass.publish.check` deletes its `@accepted_advisories` and reads
  the module; its `@doc false` parser functions become thin delegations so
  `test/mailglass/publish/audit_allowlist_test.exs` keeps working.
  - Rationale: the allowlist and both parsers already exist as private state of one Mix task
    (`lib/mix/tasks/mailglass.publish.check.ex:62`, `:1113`, `:1188`) and are already `@doc false`-public
    *solely for testability* — extraction is a move, not a redesign.
  - **The `lib/` vs `dev/` split is load-bearing and must not be collapsed:**
    - Data in `lib/` because the tarball-isolation compile at `mailglass.publish.check.ex:936-965` compiles
      `lib/` alone. A `dev/`-hosted allowlist means `publish.check` emits an undefined-module warning there
      and the shipped package silently loses its allowlist at publish time.
    - Task in `dev/` because `dev/` is on `elixirc_paths` for `:dev`/`:test` only (`mix.exs:114-116`) and is
      excluded from the Hex `files:` list. A `lib/`-hosted task would obligate entries in
      `docs/api_stability.md:53,133` **and** `test/mailglass/stability_contract_test.exs:43-50`, which runs
      in the **required** Support Contract Core lane — red lane if missed.
  - Precedent: `dev/mix/tasks/mailglass.repo.hygiene.ex:1-20` invoked by
    `.github/workflows/repo-hygiene.yml:43` is the shipped pattern for a maintainer task CI runs from repo root.

- **D-02:** Allowlist entries move from `%{id => reason_string}` to a keyword/struct list carrying `:id`,
  `:aliases`, `:package`, `:severity`, `:reason`, `:accepted_on`, `:recheck_by`. Matching is by `:id` **or**
  any alias.
  - Rationale: `mix hex.audit` keys the cowlib findings as `EEF-CVE-2026-43966` / `EEF-CVE-2026-43969` while
    `mix_audit` reports only the GHSA form. `mailglass.publish.check.ex:1179-1186` already documents this
    asymmetry as an accepted hole ("a GHSA finding is never auto-suppressed today"). Once one allowlist feeds
    both lanes and both lanes are merge-gating, that hole becomes a self-inflicted merge lockout with no
    allowlist entry capable of fixing it.
  - Note from research: only `EEF-CVE-2026-43969` has a GHSA alias (`GHSA-g2wm-735q-3f56`);
    `EEF-CVE-2026-43966` has **no** GHSA alias and is **absent from the mirego DB under cowlib entirely**.
    The alias field must tolerate an empty alias list.

- **D-03:** The audit scope widens from root-only to **all three Mix projects**: `mix hex.audit` run per
  directory (root, `mailglass_admin`, `mailglass_inbound`, each needing its own `mix deps.get`), and
  `mix deps.audit --path <dir>` run from root for the two siblings.
  - Rationale — **verified live, not inferred:** root `mix hex.audit` and `mix deps.audit` are both **clean
    today**, while `mailglass_admin`'s `mix hex.audit` reports both allowlisted cowlib advisories (cowlib
    2.19.0 is in `mailglass_admin/mix.lock:7`, absent from the root lock). `ci.yml:567-568` runs bare
    `mix hex.audit` at root only. Without widening, the promotion is safety-theater: the lane cannot see the
    repository's only live advisories, the allowlist stays dead code, and ROADMAP criterion 2's "a PR
    touching only already-accepted cowlib advisories merges cleanly" is untestable.
  - **No new dependency required:** `mix_audit`'s CLI accepts `--path`
    (`deps/mix_audit/lib/mix_audit/cli.ex:12`), and `mix deps.audit --path mailglass_admin` was verified
    working from root with `mix_audit` declared only in the root project (`mix.exs:190`).
  - Cost: per-directory `deps.get` adds ~1-2 min to two lanes that are about to become merge-gating. Note it
    as a SEED-006 input; do not optimize here.

### Lane Promotion & Drift-Test Blast Radius (VULN-03)

- **D-04:** The promotion is **ONE atomic commit**. Splitting it across commits leaves `main` with a red
  publish-gating lane (`mix_task_tests`) and a `gate-ci-green` whose `REQUIRED_LANES` disagrees with
  `ci_green.needs` — reproducing the exact registry-disagreement defect Phase 141 just closed.

- **D-05:** The nine sites the atomic commit must touch, including hardcoded counts that will otherwise fail
  as designed:
  1. `.github/workflows/ci.yml` — `ci_green.needs` (`:1150-1155`) **and** the `for job_result in` loop
     (`:1157-1176`); both must change together.
  2. `.github/workflows/ci.yml:581` — delete `continue-on-error: true` (see D-07 for why this is mandatory).
  3. `.github/workflows/ci.yml:575-580` — delete the now-false comment block (see D-09).
  4. `test/support/ci_lanes.ex` — add both to `@required_lanes` (`:80`); remove from `@advisory_lanes_ci`
     (`:95-96`), `@advisory_classified_lanes` (`:112`), `@publish_gating_lanes` (`:130`).
  5. `.github/workflows/publish-hex.yml` — `REQUIRED_LANES` (`:204`), `ADVISORY_LANES` (`:228`),
     `PUBLISH_GATING_LANES` (`:238`).
  6. `MAINTAINING.md:197` and `:210` — classification → `required`, disposition → `keep-with-reason`.
     (Both rows today read disposition `promote` with the text "Phase 142/VULN-03 executes the promotion" —
     Phase 141 wrote this phase's instruction into the table.)
  7. `test/scripts/lane_classification_drift_test.exs:71` — count 4 → 3.
  8. `test/scripts/lane_classification_drift_test.exs:88` — count 13 → 12; `:143` — count 5 → 7.
  9. `test/scripts/ci_parity_drift_test.exs:161` — `== 5` → `== 7`.
  - `lane_classification_drift_test.exs:236-272` additionally asserts all 24 `ci.yml` jobs classify and total
    exactly 24. The promotion keeps the total at 24 (5+4+13+2 → 7+3+12+2); only per-bucket counts move.
  - All of these are wired into CI via `verify.ci_lane_contract` (`mix.exs:296-298`, run by `mix_task_tests`).

- **D-06:** `deps_audit_advisory`'s display name is renamed to `Deps Audit (Elixir 1.18 / OTP 27)` in the same
  atomic commit. `scripts/setup_branch_protection.sh` is **NOT** touched.
  - Rationale: a merge-gating lane named "Advisory" is precisely the signal-honesty defect this milestone
    exists to fix; Phase 141 set the rename precedent (`credo_strict` → `Design System Conformance`).
  - **Corrected by research:** the rename is *not* mechanically required. Phase 141 D-04 already deleted the
    `/ Advisory \(/` convention regex — `gate-ci-green` now classifies by explicit array membership
    (`publish-hex.yml:228-266`). The rename is kept for honesty, not mechanism.
  - Non-`.planning` blast radius: `ci.yml:571`, `ci_lanes.ex:96,112`, `publish-hex.yml:229`,
    `ci_parity_drift_test.exs:114,188`, `MAINTAINING.md:197`.
  - Branch protection is locked to exactly `{CI Green, Guard Release Trigger}` and
    `required_checks_test.exs:45-58` asserts that set exactly. A leaf promotion under the `CI Green`
    aggregate needs no protection change; touching the script risks re-creating the job-id-vs-display-name
    incident that opened this milestone.

- **D-07:** **Deleting `continue-on-error: true` is mandatory for PR blocking, and the reason is not the one
  the code comment gives.** Research established the mechanics authoritatively:
  - `gate-ci-green` reads `job.conclusion` from `listJobsForWorkflowRun` (`publish-hex.yml:293-296`, `:315`).
    Job-level `continue-on-error` does **not** mask that value — the lane already lands in `notGreen` today.
    It is the *classification* (`ADVISORY_LANES` membership at `publish-hex.yml:228-233` → `core.warning`
    only, `:356-361`) that suppresses it. So moving the name between arrays is what makes **publish** block.
  - `ci_green` (`ci.yml:1146-1173`) evaluates `needs.<job>.result`, which job-level `continue-on-error`
    forces to `success`. So for **PR merge** blocking, adding to `ci_green.needs` **and** deleting
    `continue-on-error` are both required — neither alone works.
  - Job-level vs step-level differ: step-level → job `conclusion: success`; job-level → job
    `conclusion: failure` but `needs.*.result: success`. Source: `github/docs`
    `workflow-syntax.md` L896-898 and L1176-1180.
  - Residual uncertainty is one-directional and safe: if the job-level REST `conclusion` were `success`
    instead, deleting `continue-on-error` becomes necessary for `gate-ci-green` too — which this phase does
    anyway.

- **D-08:** The gate blocks on **any** non-allowlisted finding, matching `publish.check`'s existing
  semantics. **No HIGH-severity merge threshold is introduced.**
  - Rationale: `mailglass.publish.check.ex:1068-1110` and `:1142-1177` already hard-block on any non-accepted
    finding at publish. A merge-time severity threshold would let a PR merge green and then fail the publish
    gate — the exact "green that lies" class this milestone closes.
    `.planning/research/v2.2/PITFALLS.md:187-201` asks for *an* escape valve shipped atomically with the
    promotion; the expiring allowlist (D-10) supplies it.
  - Accepted consequence: a MEDIUM/LOW advisory with no fix blocks merges until someone adds a dated
    allowlist entry — a one-line edit with a recorded reason. That is the intended forcing function, not an
    outage.

- **D-09:** `ci.yml:578-580`'s comment is **factually stale and must be deleted, not preserved.** It claims
  classification works via *"the `\"Advisory (\"` naming convention is what publish-hex.yml gate-ci-green's
  `isAdvisory()` matches"*. There is no `isAdvisory()` in `publish-hex.yml` anymore — Phase 141 D-04 replaced
  it with explicit `classify()`/`startsWithAny()` array membership.

### Exception Expiry, Backlog & Triage (VULN-06 / VULN-02 / VULN-04)

- **D-10:** **Expiry rests on two local, deterministic signals — NOT on OSV fix-detection.** This is a
  research-driven revision of the obvious approach; do not re-litigate it back to the OSV `fixed` event.
  1. **`recheck_by` date check (offline, deterministic).** An entry whose `recheck_by` is in the past
     hard-fails the lane, naming the entry.
  2. **Allowlist-entry-unused check (offline, deterministic).** After the audit runs, any allowlist entry
     matching no current finding hard-fails with *"allowlist entry X matches no current finding — remove
     it."* This is pure local truth, requires no schema assumptions, and cannot go stale.
  - **Why not the OSV `fixed` event** — verified live against `api.osv.dev`: both allowlisted advisories
    (`EEF-CVE-2026-43966`, `EEF-CVE-2026-43969`) carry `affected[].ranges[].events: [{"introduced": "2.9.0"}]`
    only. **No `fixed`. No `last_affected`. No `withdrawn`.** Both were `modified` 2026-07-14 — *after* the
    fix commits — and still assert every version ≥ 2.9.0 is affected forever. EEF *can* populate `fixed`
    (`EEF-CVE-2026-54892` plug, `EEF-CVE-2026-56811` phoenix, `EEF-CVE-2026-54893` swoosh,
    `EEF-CVE-2026-8466` cowboy all do) — it simply has not for these two. A gate built on that field would
    silently never fire for exactly the entries it exists to police: worse than no gate, because it
    manufactures confidence.
  - **The unused-entry check would fire today**, which is the proof it works: mirego's DB closes cowlib's
    range at `<= 2.16.1`, so `mix deps.audit` already stops flagging cowlib 2.19.0 — while the allowlist
    rationale text still reads *"no upstream fix as of 2.17.1"*, already stale by two minor versions.
  - **OSV stays warn-only enrichment.** Keep the existing `withdrawn` hard-block
    (`mailglass.publish.check.ex:1233-1240`). Optionally extend `classify_osv_response/2` to a
    `{:fixed, id, version}` warn when a `fixed`/`last_affected` event exists and is ≤ the resolved dep
    version — but treat its **absence as "no signal", never as evidence the entry is still valid.** Preserve
    the documented fail-open HTTP contract at `:1245-1262`.

- **D-11:** VULN-04's triage cadence is a new `## Dependency Advisory Triage` section in `MAINTAINING.md`,
  placed adjacent to `## Security Response SLA` (`MAINTAINING.md:296`) and **after** `## Required Checks`.
  - **Placement is a hard constraint, not a preference:** the disposition-table parser bounds its section by
    splitting on `"\n## "` (`lane_classification_drift_test.exs:607-611`), rejects rows whose cell count
    isn't 7, and asserts **exactly 24 rows** (`:455-468`). A markdown table added *inside* the Required
    Checks section breaks a publish-gating meta-test.
  - Not `SECURITY.md` (`:11-24` is entirely adopter-facing inbound report intake) and not `CONTRIBUTING.md`
    (contributor-facing). `MAINTAINING.md` is the maintainer runbook and already carries the SLA numbers.
  - Content must satisfy VULN-04 literally: who reads raw `mix hex.audit` output (not just the dependabot PR
    queue), how often, response expectation by severity, and the plain statement that **Dependabot cannot
    auto-file a Hex transitive fix requiring a parent bump** — documented upstream behavior, not a repo
    defect — so reading audit output directly is the only path for that class.

- **D-12:** VULN-02 is exactly **13 open dependabot PRs, every one with auto-merge armed** — #131, #130,
  #125, #124, #116, #115, #114, #112, #111, #108, #106, #96, #95 — dispositioned **one at a time** with a
  recorded reason (`gh pr close --comment`, or merge), plus a disposition table in the phase artifact.
  - Verified live via authenticated `gh` (as `szTheory`): 16 open PRs, 13 authored by `app/dependabot`, all
    showing `autoMergeRequest` non-null.
  - **Blanket-merging is wrong** (`.planning/research/v2.2/PITFALLS.md:676-681`): several are visibly
    superseded by already-merged siblings (#114 credo-in-admin vs merged #78 credo-in-root; #115 and #125
    both bump `phoenix_live_view` to 1.2.8 in different directories). Blanket merge lands stale branches
    whose base has moved 3+ weeks and can conflict with the 2026-07-28 remediation.
  - **Blanket-closing is equally wrong** — #108 (`erlef/setup-beam`) is genuinely wanted; the action is
    SHA-pinned in every workflow.
  - Maintainer PR #132 (auto-merge armed, `BEHIND`) is **flagged as adjacent but out of VULN-02's scope** —
    the requirement says "dependency PR".

### Wave Ordering — a hard sequencing constraint, not a preference

- **D-13:** **Wave 1** — two independent, parallelizable plans, zero gating change:
  1. VULN-05 + VULN-06 mechanism (D-01, D-02, D-03, D-10). Lanes stay non-required and
     `deps_audit_advisory` keeps `continue-on-error` through this wave.
  2. VULN-02 backlog disposition (D-12). Pure GitHub-side work; touches no file in plan 1's set.

  **Wave 2** — one atomic plan, the promotion (D-04..D-09).

  **Wave 3** — VULN-04 triage docs (D-11) + criterion-2 proof. Written after the task name is final and
  after Wave 2's `MAINTAINING.md` table edit, so two plans never edit that file concurrently.

- **D-14:** **Wave 2 must not start on "Wave 1 merged" — it starts on "Wave 1 observed green with the
  accepted advisories actually in the lane's scope."** Required exit evidence: a real PR run log showing the
  Hex Audit lane green *while cowlib is in scope* — i.e. both cowlib advisories detected **and** suppressed
  by the allowlist, not merely "no findings."
  - Rationale: root `mix hex.audit` is clean today. A Wave 1 that quietly stayed root-only would look green
    for the wrong reason and hand Wave 2 a false precondition — precisely the vacuous-green class this
    milestone exists to eliminate. This is VULN-05's "hard precondition for VULN-03" made mechanical.

- **D-15:** Criterion 2's negative case is proven by a **deterministic unit test** — the task exits non-zero
  on synthetic HIGH-with-fix output and zero on cowlib-only output — optionally supplemented by a
  `gate-self-test.yml` dispatch with `check_name: "Hex Audit ("` for the lane-level probe
  (`gate-self-test.yml:19-22` already accepts a leaf-lane prefix).

### Folded Todos

- **`2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md`** — folded into VULN-06. Phase 141
  explicitly deferred it to this phase, and D-10's unused-entry check automates exactly what the todo asks a
  human to remember. **The todo is already actionable today**: mirego's DB no longer flags cowlib 2.19.0.
  The plan should either remove the now-unused entry or record why it must stay (the `hex.audit`/EEF side
  still flags it), and close the todo.

### Claude's Discretion

- Exact module name (`Mailglass.SupplyChain.AcceptedAdvisories` vs. an alternative) and task name
  (`mix mailglass.audit`) — kept decisive per METHODOLOGY.md; the planner may adjust to fit existing naming
  style, provided the `lib/`-data / `dev/`-task split of D-01 is preserved exactly.
- Whether the allowlist entries are a keyword list, a list of maps, or a small struct.
- Whether `recheck_by` failures and unused-entry failures are one check or two, provided both are
  deterministic and both hard-fail.
- Whether the optional OSV `{:fixed, ...}` warn enrichment ships in this phase or is skipped entirely — D-10
  makes it explicitly optional, and skipping it is an acceptable outcome.
- Row ordering and column phrasing of the VULN-02 disposition table in the phase artifact.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` § "Phase 142" — goal + 5 success criteria (authoritative phase boundary)
- `.planning/REQUIREMENTS.md` — VULN-05, VULN-03, VULN-06, VULN-02, VULN-04 full text; the binding
  "Out of Scope" list
- `.planning/phases/141-lane-truth-foundation/141-CONTEXT.md` — **load-bearing.** D-01 (CILanes
  authoritative), D-02 (three-bucket model), D-04 (convention regex deleted), D-05 (MAINTAINING.md
  disposition table), D-07 ("promote" recorded as recommendation; this phase executes it)
- `.planning/STATE.md` § "v2.2 Milestone Intent" — the hidden-third-tier finding
- `.planning/METHODOLOGY.md` — decisive-by-default; escalate only on publish/trust posture
- `.planning/research/v2.2/SUMMARY.md` — locks "no new dependency"
- `.planning/research/v2.2/PITFALLS.md:187-201` (escape valve must ship atomically with promotion),
  `:676-681` (do not blanket-merge the dependabot backlog)
- `lib/mix/tasks/mailglass.publish.check.ex` — `:62` (allowlist), `:936-965` (tarball-isolation compile),
  `:1068-1110` / `:1142-1177` (block-on-any semantics), `:1113` / `:1188` (parsers),
  `:1179-1186` (the GHSA/EEF asymmetry hole), `:1218-1295` (OSV staleness gate)
- `test/support/ci_lanes.ex` — the authoritative registry (`:80`, `:95-96`, `:112`, `:130`)
- `.github/workflows/ci.yml` — `:545-568` (`hex_audit`), `:570-601` (`deps_audit_advisory`),
  `:1146-1176` (`ci_green`)
- `.github/workflows/publish-hex.yml` — `:204`, `:228`, `:238`, `:258` (the four arrays), `:293-321`
  (conclusion reading + classify), `:356-361` (advisory → warning only)
- `test/scripts/lane_classification_drift_test.exs` — `:71`, `:88`, `:143` (counts), `:236-272` (24-job
  totality), `:455-468` + `:607-611` (MAINTAINING.md table parser bounds)
- `test/scripts/ci_parity_drift_test.exs` — `:113-114`, `:161`, `:187-188`
- `test/scripts/required_checks_test.exs:45-58` — GATE-01, the exact branch-protection set
- `MAINTAINING.md` — `:190-215` (24-row table; rows `:197`, `:210`), `:296-306` (Security Response SLA)
- `docs/api_stability.md:53,133` + `test/mailglass/stability_contract_test.exs:43-50` — the stable Mix-task
  contract D-01 deliberately avoids
- `dev/mix/tasks/mailglass.repo.hygiene.ex` + `.github/workflows/repo-hygiene.yml:37-43` — the dev-task
  precedent
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/mix/tasks/mailglass.publish.check.ex:62` — `@accepted_advisories`, 2 cowlib entries, reason strings
  only, **no dates** (D-02 adds them).
- `:1113` / `:1188` — `unaccepted_audit_findings/1` and `unaccepted_deps_audit_findings/1`, already
  `@doc false`-public for testability. Extraction is a move.
- `:1218-1231` — `check_osv_advisory_staleness/0`; `:1233-1240` — `classify_osv_response/2` (matches only
  `%{"withdrawn" => _}` today); `:1245-1262` — `osv_get/1` with a documented hard fail-open contract;
  `:1269-1295` — block on `:stale`, warn on `:error`.
- `test/mailglass/publish/audit_allowlist_test.exs` — 160 lines of parser/classifier unit tests that move
  with the extraction; `:133-161` covers the classifier.
- `dev/mix/tasks/mailglass.repo.hygiene.ex:1-20` + `repo-hygiene.yml:37-43` — dev-path task invoked by CI
  from repo root, contract-tracked at `stability_contract_test.exs:49`.
- `deps/mix_audit/lib/mix_audit/cli.ex:4-13` — `--path`, `--ignore-advisory-ids`, `--ignore-file`,
  `--format`. Verified: `mix deps.audit --path mailglass_admin` works from root.
- `.github/workflows/gate-self-test.yml:19-22` — parameterized deliberate-failure probe; `check_name`
  accepts a leaf-lane prefix.
- `test/scripts/conformance_advisory_test.exs:66-79` — precedent for asserting a `ci.yml` step block and
  **refuting** `continue-on-error: true`.

### Established Patterns

- **One registry, meta-tests as the seam.** `test/support/ci_lanes.ex` is authoritative;
  `publish-hex.yml`, `ci.yml`, and `MAINTAINING.md` are declarations verified against it.
- **Anti-vacuity guard on every parser.** Hardcoded expected counts plus negative-control tests that inject
  a removal and assert the drift helper reports it (`lane_classification_drift_test.exs:162-229`,
  `:521-550`). Every count change is a deliberate edit, never a deletion.
- **Fail-open on network, fail-closed on data.** `osv_get/1` never raises and never blocks;
  `verify_osv_freshness/1` blocks only on the deterministic verdict. D-10 extends this posture rather than
  breaking it.
- **Brand-voice failure messages.** Every gate message begins "Delivery blocked: …" and names the fix
  (`mailglass.publish.check.ex:1094-1099`). New allowlist-expiry messages follow suit.

### Integration Points

- `ci.yml:545-568` — `hex_audit`: no `strategy:`, no `continue-on-error`,
  `if: needs.changes.outputs.code == 'true'`.
- `ci.yml:570-601` — `deps_audit_advisory`, `continue-on-error: true` at `:581`, stale comment at `:575-580`.
- `ci.yml:1146-1176` — `ci_green`: `needs:` and the shell result loop must change together.
- `publish-hex.yml:301-307` — `REQUIRED_LANES` uses **exact** equality, safe here because neither audit job
  declares a matrix; `lane_classification_drift_test.exs:125-140` machine-enforces that invariant.
- `ci_parity_drift_test.exs:113-114` (matchers keyed on the `hex.audit` / `deps.audit` step substrings) and
  `:187-188` (stale-matcher MapSet) — these break if the `mix ci` alias steps at `mix.exs:395-396` change to
  `mailglass.audit`. Either keep both audit invocations discoverable in the alias, or update the matcher and
  the MapSet in the same commit.
- `MAINTAINING.md:197` and `:210` already carry disposition `promote` with the literal text "Phase
  142/VULN-03 executes the promotion" — Phase 141 wrote this phase's instruction into the table.
</code_context>

<specifics>
## Specific Ideas

- **The OSV fix-detection reversal is the phase's most important non-obvious finding.** The intuitive
  mechanism for VULN-06 — "query OSV, see the fix landed, flag the stale exception" — was tested against
  live data and **fails silently for exactly the two entries it would police**. The honest local checks
  (`recheck_by` date, unused-entry) replace it. A future reader tempted to "improve" VULN-06 by adding the
  OSV `fixed` lookup should read D-10 first.
- **Live verification, not inference, settled three assumptions**: the per-directory advisory distribution
  (root clean, `mailglass_admin` carrying both cowlib findings), the 13-PR dependabot backlog with
  auto-merge armed on every one, and the OSV records' actual event shape. Phase 141 set this precedent by
  checking branch protection via direct API call rather than trusting the setup script; this phase follows it.
- **The allowlist's own rationale text is already stale** — it says "no upstream fix as of 2.17.1" while the
  lock is at cowlib 2.19.0 and mirego's range closes at 2.16.1. The exception aged out silently, which is a
  live demonstration of the exact failure VULN-06 exists to prevent. Worth stating in the phase artifact as
  the motivating example.
- **`ci.yml:578-580`'s comment describes a mechanism that no longer exists.** Phase 141 removed
  `isAdvisory()`. Deleting the comment is part of the work, not incidental tidying — a stale comment about
  the classification mechanism is the same defect class the milestone is closing.

</specifics>

<deferred>
## Deferred Ideas

- **Wall-clock cost of per-directory `deps.get` on two now-merge-gating lanes (~1-2 min)** — SEED-006,
  deliberately sequenced after v2.2. Note it in the plan; do not optimize here.
- **Maintainer PR #132** (auto-merge armed, `BEHIND`) — adjacent to VULN-02 but not a dependency PR. Flag
  its state in the phase artifact; do not disposition it as part of this requirement.
- **`EEF-CVE-2026-43966`'s absence from the mirego DB under cowlib** — an upstream data gap, not a repo
  defect. D-02's alias-tolerant matching handles it; filing it upstream is out of scope.
- **The optional OSV `{:fixed, ...}` warn enrichment** — explicitly optional per D-10. If skipped, VULN-06
  is still fully satisfied by the two deterministic local checks.
- **Extending `gate-ci-green` to `advisory-matrix.yml`** — Phase 143/HARNESS-04.
- **Making `Branch Protection Advisory` failable** — Phase 144/TRUTH-02.

### Reviewed Todos (not folded)

None — the single matched todo was folded (see Folded Todos above).
</deferred>
