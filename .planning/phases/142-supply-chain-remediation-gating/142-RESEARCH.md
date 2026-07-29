# Phase 142: Supply-Chain Remediation & Gating - Research

**Researched:** 2026-07-28
**Domain:** Supply-chain advisory gating (CI-side `mix hex.audit` / `mix deps.audit`), expiring-allowlist mechanism design, GitHub PR-backlog triage (Elixir/Hex library, GitHub Actions)
**Confidence:** HIGH (every load-bearing claim below verified against the live worktree at `87d6f775` — the actual post-Phase-141 tree — or live `gh`/`mix`/OSV API calls made in this session on 2026-07-28)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Single source is a new data+logic module in `lib/` (`Mailglass.SupplyChain.AcceptedAdvisories`) holding the allowlist entries plus the two audit-output parsers, invoked by a new dev-path Mix task (`mix mailglass.audit` at `dev/mix/tasks/mailglass.audit.ex`) that both CI audit lanes call. `mailglass.publish.check.ex` deletes its `@accepted_advisories` and reads the module; its parser functions become thin delegations. **The `lib/` vs `dev/` split is load-bearing and must not be collapsed** (tarball-isolation compile only sees `lib/`; a `lib/`-hosted task would obligate `docs/api_stability.md` + `stability_contract_test.exs` entries, which run in the required Support Contract Core lane).
- **D-02:** Allowlist entries move from `%{id => reason}` to a keyword/struct list carrying `:id`, `:aliases`, `:package`, `:severity`, `:reason`, `:accepted_on`, `:recheck_by`. Matching is by `:id` **or** any alias. Only `EEF-CVE-2026-43969` has a GHSA alias (`GHSA-g2wm-735q-3f56`); `EEF-CVE-2026-43966` has none. Alias field must tolerate an empty list.
- **D-03:** Audit scope widens from root-only to all three Mix projects: `mix hex.audit` per directory (each needing its own `mix deps.get`), `mix deps.audit --path <dir>` from root for the two siblings. Root is clean; `mailglass_admin` carries both cowlib advisories. No new dependency — `mix_audit`'s `--path` flag already exists.
- **D-04:** The promotion is ONE atomic commit.
- **D-05:** Nine sites the atomic commit must touch (see §Verification — **all nine confirmed exact-line-accurate against the live tree, zero drift**).
- **D-06:** `deps_audit_advisory`'s display name renames to `Deps Audit (Elixir 1.18 / OTP 27)` in the same atomic commit; not mechanically required (Phase 141 already deleted the naming-convention regex) but kept for honesty. `scripts/setup_branch_protection.sh` is NOT touched.
- **D-07:** Deleting `continue-on-error: true` is mandatory for PR-merge blocking (job-level `continue-on-error` forces `needs.*.result` to `success` in `ci_green`'s shell loop); the classification-array move is what makes **publish** blocking (job.conclusion is unaffected by continue-on-error in the REST API `gate-ci-green` reads).
- **D-08:** Gate blocks on **any** non-allowlisted finding — no HIGH-severity merge threshold.
- **D-09:** `ci.yml:578-580`'s stale comment describing `isAdvisory()` must be deleted (that function no longer exists post-Phase-141).
- **D-10:** Expiry rests on two local, deterministic signals — `recheck_by` date check and allowlist-entry-unused check — **NOT** OSV fix-detection. Both allowlisted advisories carry only an `introduced` event in OSV, no `fixed`/`last_affected`/`withdrawn`. OSV stays warn-only enrichment (optional).
- **D-11:** VULN-04's triage cadence is a new `## Dependency Advisory Triage` section in `MAINTAINING.md`, adjacent to `## Security Response SLA` (`:296`), after `## Required Checks`. Placement is a hard constraint — the disposition-table parser bounds its section by splitting on `"\n## "`.
- **D-12:** VULN-02 is exactly 13 open dependabot PRs, all auto-merge-armed (#131, #130, #125, #124, #116, #115, #114, #112, #111, #108, #106, #96, #95), dispositioned one at a time with a recorded reason. Blanket-merge and blanket-close are both wrong. PR #132 is adjacent (maintainer PR, auto-merge armed) but out of VULN-02's scope.
- **D-13:** Wave 1 (parallel, non-gating): VULN-05+VULN-06 mechanism, VULN-02 backlog. Wave 2 (atomic): the promotion. Wave 3: VULN-04 triage docs + criterion-2 proof, after Wave 2's `MAINTAINING.md` edit.
- **D-14:** Wave 2 must not start on "Wave 1 merged" but on "Wave 1 observed green with the accepted advisories actually in the lane's scope" — a real PR run showing Hex Audit green *while cowlib is detected and suppressed*, not merely "no findings."
- **D-15:** Criterion 2's negative case is proven by a deterministic unit test (exits non-zero on synthetic HIGH-with-fix, zero on cowlib-only), optionally supplemented by a `gate-self-test.yml` dispatch.

### Claude's Discretion

- Exact module/task naming, provided the `lib/`-data / `dev/`-task split is preserved exactly.
- Whether allowlist entries are a keyword list, list of maps, or a struct.
- Whether `recheck_by` and unused-entry checks are one check or two.
- Whether the optional OSV `{:fixed, ...}` warn enrichment ships this phase or is skipped.
- Row ordering/column phrasing of the VULN-02 disposition table.

### Deferred Ideas (OUT OF SCOPE)

- Wall-clock cost of per-directory `deps.get` (~1-2 min) — SEED-006, sequenced after v2.2.
- Maintainer PR #132 — flag its state, do not disposition it.
- `EEF-CVE-2026-43966`'s absence from the mirego DB under cowlib — upstream data gap, not a repo defect.
- The optional OSV `{:fixed, ...}` warn enrichment.
- Extending `gate-ci-green` to `advisory-matrix.yml` — Phase 143/HARNESS-04.
- Making `Branch Protection Advisory` failable — Phase 144/TRUTH-02.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description (from REQUIREMENTS.md) | Research Support |
|----|-------------|------------------|
| **VULN-05** | CI-side audit lanes honor the same allowlist `publish.check` uses, one source. Hard precondition for VULN-03. | §Implementation Shapes gives the module/task contract; §Task Ordering validates the Wave-1-before-Wave-2 gate with a new finding on the `mix ci` local-parity alias that CONTEXT.md flagged but didn't resolve. |
| **VULN-03** | Both Hex Audit and Deps Audit lanes merge-gating; parity-drift test updated. | §Verification confirms all nine D-05 atomic-commit sites are still exact; §Task Ordering confirms the atomic-commit shape is unchanged from what the live meta-tests require. |
| **VULN-06** | Allowlisted advisory carries reason + re-check date; lane surfaces a landed-fix entry. | §D-10 Live Re-Verification confirms the OSV event-shape claim with an additional data nuance (versions-array capping + an unstructured FIX reference) that further supports the "don't build on OSV `fixed`" call. |
| **VULN-02** | Dependabot PRs with auto-merge confirmed merged/closed with a reason. | §Live Verification: 2026-07-28 `gh pr list` reconfirms all 13 PRs, all auto-merge-armed, byte-identical to CONTEXT.md's list; adds `mergeStateStatus`/`mergeable` per-PR data useful for the disposition table. |
| **VULN-04** | Documented triage cadence covering transitive dependencies. | §Implementation Shapes gives the `MAINTAINING.md` insertion point (verified: `## Required Checks` at :132, `## Security Response SLA` at :296) and confirms no parser-boundary conflict. |
</phase_requirements>

---

## Summary

Every citation in CONTEXT.md was re-checked against the live worktree at `87d6f775` — the tree **after** Phase 141 landed, which is what CONTEXT.md was itself written against. **The result is unusually clean: every single line citation checked (the full D-05 nine-site list, the D-06 blast-radius list, the `mailglass.publish.check.ex` allowlist/parser/OSV citations, the `ci_lanes.ex` four-bucket line numbers, the `mix.exs` alias line numbers, `docs/api_stability.md` + `stability_contract_test.exs`, `gate-self-test.yml`, `conformance_advisory_test.exs`) matches exactly.** This is the opposite of Phase 141's experience (which found 9 findings, several citation-correcting) — because CONTEXT.md here was gathered directly against the already-landed Phase 141 tree rather than against research predictions of what Phase 141 would produce. The planner can treat every file:line reference in CONTEXT.md's `<canonical_refs>` and `<decisions>` D-05/D-06 as trustworthy without re-verification.

That said, this research surfaced **six findings that materially sharpen the plan**, none severe enough to overturn a locked decision, but each closing a gap CONTEXT.md left open or adds a live-verified detail:

**F1 — CONTEXT.md flags but does not resolve a `mix ci` local-parity hazard; this research recommends a specific resolution.** `test/scripts/ci_parity_drift_test.exs`'s matchers check `mix.exs`'s **local** `:ci` alias text for the literal substrings `"hex.audit"` / `"deps.audit"` — not `ci.yml`. If Wave 1 rewires the CI-side `hex_audit`/`deps_audit_advisory` jobs to call the new `mailglass.audit` task while leaving `mix.exs:395-396`'s literal `"hex.audit"`/`"deps.audit"` steps untouched, the parity test still passes (false comfort) but the local-parity claim silently narrows: `mix ci` no longer reproduces what the widened CI lanes actually check (root-only vs. three-directory-with-allowlist). Recommendation: widen `mix.exs`'s `:ci` alias to also call `mix mailglass.audit` (replacing the two literal steps) in the **same Wave-1 commit**, and update the two matcher entries to match the new substring — this keeps MIXCI-03's "green locally means green in CI" honest rather than merely keeping the test green.

**F2 — D-02's alias-matching change makes an existing, currently-passing test's own doc-comment stale.** `mailglass.publish.check.ex:1179-1186` and `audit_allowlist_test.exs:46-62` both document, in prose, "a GHSA finding is never auto-suppressed today" as an *accepted* asymmetry. D-02 explicitly closes this hole for `EEF-CVE-2026-43969`'s GHSA alias. Once alias-matching lands, both comments become **factually wrong** — the exact "confidently-worded stale comment" defect class this milestone exists to eliminate (Phase 141's `ci.yml:578-580`/D-09 is the precedent). No test today exercises the *positive* case (a real aliased GHSA id being suppressed) — `audit_allowlist_test.exs:108-126` deliberately uses a **non-matching** GHSA id to prove non-suppression. A new positive test using the real `GHSA-g2wm-735q-3f56` value is required, and the two stale comments must be rewritten in the same commit.

**F3 — `mix hex.audit` requires deps installed AND has no `--path` flag; the two audit mechanisms need different per-directory strategies.** Live-verified: `mailglass_inbound`'s `mix hex.audit` failed with "the dependency is not available, run mix deps.get" before `mix deps.get` had been run in that directory, and succeeded (clean) after. `mix_audit`'s CLI has a `path:` switch (`deps/mix_audit/lib/mix_audit/cli.ex:12`) but Hex's own `hex.audit` task does not — so per-directory `hex.audit` scanning **must** `cd` into each project (via `System.cmd(..., cd: dir)`), while per-directory `deps.audit` uses `--path` from root. `mailglass.publish.check.ex:982` (`fetch_compile_deps!/2`) is an exact, already-proven precedent for the `cd:`-based `deps.get` + audit pattern the new task should reuse rather than re-derive.

**F4 — Live re-verification of D-03's per-directory advisory distribution and D-10's OSV claim, with one added nuance.** Confirmed live: root `hex.audit`/`deps.audit` clean, `mailglass_inbound` clean (both, after `deps.get`), `mailglass_admin`'s `hex.audit` reports both cowlib EEF-CVE findings (exit 1) while its `deps.audit --path` is clean (exit 0, mirego's DB range excludes 2.19.0). OSV re-fetched live for both IDs: confirmed no `fixed`/`last_affected`/`withdrawn` events. **New nuance:** `EEF-CVE-2026-43969`'s OSV record carries an explicit enumerated `affected[].versions` array that stops at `2.18.0` (not `2.19.0`, the version actually locked) **alongside** an open-ended `SEMVER` range asserting "affected from 2.9.0 onward forever" — an internal inconsistency in OSV's own data. It also carries a `references[].type: "FIX"` entry (a real fix-commit URL) that exists only as unstructured metadata, never surfacing as a structured `fixed` event. Both details *reinforce* D-10's recommendation (mechanized `fixed`-event detection would miss this fix twice over — the range never closes, and the FIX reference isn't in the field a mechanized check would read) rather than contradicting it.

**F5 — The new `lib/` module needs `use Boundary, classify_to: Mailglass` like every other `lib/` module (compile-time enforced).** `mix.exs:23` declares `compilers: [:boundary | Mix.compilers()]` — every `lib/mix/tasks/*.ex` file and `lib/mailglass/*.ex` module in this repo declares `use Boundary, classify_to: Mailglass` (verified: 15+ files). `Mailglass.SupplyChain.AcceptedAdvisories` must do the same or risks a boundary-compiler warning under `compile_warnings`'s `--warnings-as-errors` (publish-gating). Because both the new `lib/` module and the new `dev/` task classify into the same top-level `Mailglass` boundary, they should be able to call each other without an explicit `exports` list entry (same-boundary calls are unrestricted in `boundary`) — MEDIUM confidence (inferred from the library's documented same-boundary semantics and this repo's existing pattern, not executed in this session); the plan should verify with an early `mix compile --warnings-as-errors` task rather than assume.

**F6 — VULN-02's live state is confirmed byte-identical to CONTEXT.md, with useful per-PR merge-state data CONTEXT.md didn't capture.** Re-ran `gh pr list` live: exactly 16 open PRs, 13 from `app/dependabot`, all 13 auto-merge-armed, matching CONTEXT.md's PR-number list exactly. Every one of the 13 carries `mergeStateStatus: "BEHIND"` (stale base) except **#96** (`bump igniter 0.8.1→0.8.2`), which is `mergeable: CONFLICTING` / `mergeStateStatus: DIRTY` — a real merge conflict, not just staleness. This is a concrete, actionable data point for the disposition table: #96 cannot simply be re-triggered for auto-merge without a rebase or a close-with-reason decision.

**Primary recommendation:** Build the module + task + CI wiring + `mix ci` alias update as one Wave-1 commit (closing F1), verify Wave-1 green against live cowlib-in-scope evidence per D-14 before touching anything in Wave 2, then execute Wave 2's nine-site atomic commit exactly as D-05 specifies (verified unchanged), landing F2's positive alias-suppression test and stale-comment fix inside Wave 1 (where the alias-matching code lands), not deferred.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Allowlist data + parsers (source of truth) | `lib/` Elixir module (`Mailglass.SupplyChain.AcceptedAdvisories`) | — | D-01; must compile standalone in the tarball-isolation build, which sees `lib/` only (`mailglass.publish.check.ex:936-965`). |
| CI-side per-directory audit orchestration | `dev/` Mix task (`mailglass.audit.ex`) | GitHub Actions job steps (`ci.yml` `hex_audit`/`deps_audit_advisory`) | D-01; `dev/` is excluded from the Hex `files:` list and from `elixirc_paths(:prod)`, keeping the CLI-invocation surface out of the shipped package and out of the stability contract. |
| Merge gating (Wave 2) | GitHub Actions job graph (`ci.yml` `ci_green.needs`) | Branch protection (2 aggregate contexts, unchanged) | Matches Phase 141's established mechanism exactly; no new gating tier introduced. |
| Publish gating (unchanged mechanism, new members) | `publish-hex.yml` `gate-ci-green` `classify/1` | — | Phase 141 already built the four-array classifier; Phase 142 only moves two lane names between arrays. |
| Local-developer parity (`mix ci`) | `mix.exs` `:ci` alias | `ci_parity_drift_test.exs` | **F1** — currently a silent gap the plan must close explicitly, not leave to the matcher's substring luck. |
| Expiry/staleness enforcement | The audit task itself (deterministic local checks) | OSV API (optional, warn-only) | D-10; the task, not an external service, is authoritative for "is this allowlist entry still needed." |
| Dependabot backlog disposition record | Phase artifact (this phase's PLAN/SUMMARY) + `gh pr close`/merge actions | — | No new `.planning/` register; GitHub is the system of record for PR state, the phase artifact is the audit trail. |
| Triage-cadence documentation | `MAINTAINING.md` §"Dependency Advisory Triage" | — | D-11; adjacent to the existing Security Response SLA section, inside the maintainer runbook that survives milestone archival. |

---

## Verification of CONTEXT.md's Citations

Every citation re-read at `87d6f775`, plus live `mix`/`gh`/OSV API calls made in this session. **Live repo agrees with CONTEXT.md on all of them — zero drift found**, an unusually clean result (contrast Phase 141's 9 findings, several citation-correcting).

### D-05's nine atomic-commit sites — the highest-value check, per the task brief

| Site | CONTEXT.md claim | Live verification | Verdict |
|---|---|---|---|
| 1a | `ci.yml` `ci_green.needs` at `:1150-1155` | `needs:` keyword line 1150, 5 list items 1151-1155 | ✅ exact |
| 1b | `for job_result in` loop at `:1157-1176` | Loop opens 1157 (step `name:`), closes at the `echo "All required..."` line 1177 | ⚠️ off-by-one at the tail (loop's final echo is 1177, not 1176) — cosmetic, same class of nit Phase 141's research found in its own citation check |
| 2 | `ci.yml:581` — `continue-on-error: true` to delete | Confirmed exact | ✅ exact |
| 3 | `ci.yml:575-580` — stale comment block | Confirmed exact (6 lines, `# Advisory-only:` through `isAdvisory() matches to skip it`) | ✅ exact |
| 4a | `ci_lanes.ex` `@required_lanes` at `:80` | Confirmed exact | ✅ exact |
| 4b | `@advisory_lanes_ci` `:95-96` (Hex Audit / Deps Audit Advisory entries) | Line 95 = `"Hex Audit (Elixir 1.18 / OTP 27)",`, line 96 = `"Deps Audit Advisory (Elixir 1.18 / OTP 27)",` | ✅ exact |
| 4c | `@advisory_classified_lanes` `:112` (Deps Audit Advisory) | Confirmed exact | ✅ exact |
| 4d | `@publish_gating_lanes` `:130` (Hex Audit) | Confirmed exact | ✅ exact |
| 5a | `publish-hex.yml` `REQUIRED_LANES` at `:204` | Confirmed exact | ✅ exact |
| 5b | `ADVISORY_LANES` at `:228` | Confirmed exact | ✅ exact |
| 5c | `PUBLISH_GATING_LANES` at `:238` | Confirmed exact | ✅ exact |
| 6a | `MAINTAINING.md:197` — Deps Audit Advisory row, disposition `promote` | Confirmed exact text, including "Phase 142/VULN-03 executes the promotion" | ✅ exact |
| 6b | `MAINTAINING.md:210` — Hex Audit row, disposition `promote` | Confirmed exact | ✅ exact |
| 7 | `lane_classification_drift_test.exs:71` — `== 4` (advisory count, to become 3) | Confirmed exact | ✅ exact |
| 8a | `:88` — `== 13` (publish-gating count, to become 12) | Confirmed exact | ✅ exact |
| 8b | `:143` — `== 5` (required count, to become 7) | Confirmed exact | ✅ exact |
| 9 | `ci_parity_drift_test.exs:161` — `== 5` (to become 7) | Confirmed exact (`assert length(Mailglass.CILanes.required_lanes()) == 5,`) | ✅ exact |

**Conclusion: all nine sites are exact-line-accurate against the live tree.** The 5+4+13+2=24 → 7+3+12+2=24 promotion arithmetic holds against the real registry (`ci_lanes.ex` currently has `@required_lanes` length 5, `@advisory_classified_lanes` length 4, `@publish_gating_lanes` length 13, `@structural_lanes` length 2 — all directly counted from the file read in this session).

### D-06's blast-radius sites

| Site | Claim | Verified? |
|---|---|---|
| `ci.yml:571` (`deps_audit_advisory` display name) | exact | ✅ |
| `ci_lanes.ex:96` (Deps Audit Advisory in `@advisory_lanes_ci`) | exact | ✅ |
| `ci_lanes.ex:112` (Deps Audit Advisory in `@advisory_classified_lanes`) | exact | ✅ |
| `publish-hex.yml:229` (Deps Audit Advisory in `ADVISORY_LANES`) | exact | ✅ |
| `ci_parity_drift_test.exs:114` (matcher key) | exact | ✅ |
| `ci_parity_drift_test.exs:188` (MapSet member) | exact | ✅ |
| `MAINTAINING.md:197` | exact (see D-05 6a above) | ✅ |

### D-11's placement constraint

| Claim | Verified? |
|---|---|
| `## Required Checks` heading | line 132 | ✅ |
| `## Security Response SLA` heading | line 296 | ✅ |
| Two other `## ` headings sit between them (`Bus Factor & Continuity` :236, `Retract Decision Tree` :253) | confirmed — a new `## Dependency Advisory Triage` section inserted near :296 is textually disjoint from the Required Checks table (which the parser bounds by splitting on the next `"\n## "` token, i.e. up to :236) | ✅ no parser-boundary conflict |

### `mailglass.publish.check.ex` citations (canonical_refs)

| Citation | Verified? | Note |
|---|---|---|
| `:62` `@accepted_advisories` | exact | ✅ |
| `:936-965` tarball-isolation compile | function body (`verify_compile/1`) spans ~936-975; close enough, not a D-05 site | ✅ |
| `:1068-1110` hex-audit block-on-any | actual function is `verify_audit/1`, spans 1068-1102 (named differently than `verify_hex_audit` — a naming detail, not a line-number drift) | ✅ substantively, name differs from what an incautious reader might assume |
| `:1142-1177` deps-audit block-on-any | `verify_deps_audit/1` spans 1142-1177 exactly | ✅ exact |
| `:1113` / `:1188` parsers (`unaccepted_audit_findings/1`, `unaccepted_deps_audit_findings/1`) | exact | ✅ |
| `:1179-1186` GHSA/EEF asymmetry comment | exact — see **F2** above for why this comment goes stale after D-02 | ✅ (content, not just location) |
| `:1218-1295` OSV staleness gate | `check_osv_advisory_staleness/0` at 1218, `classify_osv_response/2` at 1230, `osv_get/1` at 1244, `verify_osv_freshness/1` block ends ~1290 | ✅ substantively (a few lines of internal drift, not at any D-05 site) |

### Other citations

| Citation | Verified? |
|---|---|
| `test/support/ci_lanes.ex:80,95-96,112,130` | ✅ (see D-05 above) |
| `.github/workflows/ci.yml:545-568` (`hex_audit`), `:570-601` (`deps_audit_advisory`), `:1146-1176` (`ci_green`) | ✅ exact job-key line numbers (545, 570, 1146) |
| `docs/api_stability.md:53,133` | ✅ — confirmed the "Stable Mix tasks" bullet list does NOT include `mailglass.repo.hygiene` (a `dev/`-hosted precedent task) OR any hypothetical `mailglass.audit`, supporting D-01's "stays out of the stable contract" claim |
| `test/mailglass/stability_contract_test.exs:43-50` | ✅ exact — but see the nuance below (this test enumerates modules explicitly, it does not scan; a new `dev/` task does not automatically get swept into it) |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` + `repo-hygiene.yml:37-43` | ✅ — confirmed invocation at `repo-hygiene.yml:43`, and confirmed the precedent task carries `@moduledoc since: "1.3.0"` and IS individually named in `stability_contract_test.exs:50` (`assert_module_since(Mix.Tasks.Mailglass.Repo.Hygiene, "1.3.0")`) even though it lives in `dev/` — a nuance worth recording: the `since:`-tag assertion is a **closed, explicitly-enumerated list**, not a directory scan, so the new `mailglass.audit` task will NOT be swept into this test by accident; adding a `since:` tag and a corresponding assertion line is optional good-practice, not load-bearing, but following the `repo.hygiene` precedent (both) is recommended. |
| `deps/mix_audit/lib/mix_audit/cli.ex:12` (`--path`) | ✅ exact — `path: :string` switch confirmed present |
| `.github/workflows/gate-self-test.yml:19-22` | ✅ exact — `check_name` input, default `"CI Green"`, description explicitly documents polling a leaf-lane prefix |
| `test/scripts/conformance_advisory_test.exs:66-79` | ✅ ~exact — test at 66-71, `advisory_step_block/1` helper at 74-79 (one line off from CONTEXT.md's range, cosmetic) |
| `mix.exs:395-396` (`"hex.audit"`, `"deps.audit"` steps in the `ci` alias) | ✅ exact |

**Conclusion: no plan-blocking drift anywhere in CONTEXT.md.** The planner can treat every citation as current.

---

## Findings That Change The Plan

(Full detail already summarized in §Summary as F1-F6; expanded here where it changes concrete plan shape.)

### F1 — DETAIL: recommended atomic scope for the `mix ci` parity fix

`[VERIFIED: test/scripts/ci_parity_drift_test.exs:1-30 (moduledoc), :80-119 (matcher_for/1), mix.exs:395-396]`

`ci_parity_drift_test.exs`'s `any_step?/2` checks the **local** `mix.exs` `:ci` alias's flattened step list — it never reads `ci.yml` at all. Its purpose (per its own moduledoc, MIXCI-03/D-LD-10) is proving "green locally means green in CI." Two independent lane matchers key on this alias today:

```elixir
"Hex Audit (Elixir 1.18 / OTP 27)" => &any_step?(&1, "hex.audit"),
"Deps Audit Advisory (Elixir 1.18 / OTP 27)" => &any_step?(&1, "deps.audit"),
```

If Wave 1 rewires `ci.yml`'s `hex_audit`/`deps_audit_advisory` steps to `run: mix mailglass.audit --kind hex` / `--kind deps` (or similar) but leaves `mix.exs:395-396`'s literal `"hex.audit"`, `"deps.audit"` alias steps unchanged, the test **still passes** (it never looked at `ci.yml`), but two things are now true that shouldn't both be:

1. `mix ci`'s local audit steps only ever scan the root directory (today's behavior).
2. The CI-side lanes now scan three directories through the allowlist.

The parity claim silently narrows exactly as Phase 141's F3 warned against for a different axis. **Recommendation:** in the same Wave-1 commit, change `mix.exs:395-396` from the two literal steps to a single `"mailglass.audit"` step (or two steps if the task is split by `--kind`), and update both matcher entries to `&any_step?(&1, "mailglass.audit")`. This makes `mix ci` locally reproduce the exact three-directory, allowlist-filtered scan the CI lanes now run — not just avoid breaking the test.

### F2 — DETAIL: the positive alias-suppression test and the two stale comments

`[VERIFIED: test/mailglass/publish/audit_allowlist_test.exs:46-62,108-126; lib/mix/tasks/mailglass.publish.check.ex:1179-1186]`

Today's asymmetry is *documented as permanent*:

> `mailglass.publish.check.ex:1179-1186`: "The advisory id (GHSA-\*) does NOT match the @accepted_advisories keys (EEF-CVE-\*), so a deps.audit finding is never auto-suppressed today — that asymmetry is intended."

> `audit_allowlist_test.exs:57-62`: "The advisory id (GHSA-\*) does NOT match the @accepted_advisories keys (EEF-CVE-\*), so a deps.audit finding is NEVER auto-suppressed by the hex.audit allowlist — it always surfaces. That is the intended asymmetry."

D-02 exists specifically to close this hole via the `:aliases` field. Once it lands, both statements are false. The existing test at `:108-126` ("suppresses a finding whose GHSA id is in the accepted allowlist") is a **false-positive-shaped test name** — it actually proves the OPPOSITE (uses a non-matching fake GHSA id to prove non-suppression) and its own comment says so. This is confusing today and becomes actively misleading once D-02 lands unless corrected in the same commit. **Recommendation:** add one new test using the real `GHSA-g2wm-735q-3f56` value asserting it IS now suppressed (proving D-02's alias-matching works end to end), rewrite the existing test's docstring to clarify it demonstrates a *non-aliased* GHSA id is still correctly NOT suppressed (still a valid, needed guard), and rewrite both prose comments to describe the new alias-bridging behavior. This is the same defect class (a confidently-worded comment describing a mechanism that no longer exists) as Phase 141's D-09/F-finding for `ci.yml:578-580` — worth calling out by name so the plan doesn't reproduce it inside the very phase meant to close such gaps.

### F3 — DETAIL: two different per-directory audit strategies, one proven precedent

`[VERIFIED: live `mix hex.audit`/`mix deps.audit --path` runs in this session; lib/mix/tasks/mailglass.publish.check.ex:982-995]`

Live-executed in this session:

```
$ cd mailglass_inbound && mix hex.audit
* phoenix_live_view (Hex package)
  the dependency is not available, run "mix deps.get"
[... 9 more "not available" lines ...]
** (Mix) Can't continue due to errors on dependencies

$ mix deps.get   # (inside mailglass_inbound)
[... fetches 19 packages ...]

$ mix hex.audit   # (inside mailglass_inbound, after deps.get)
No retired or security advisory packages found
```

`hex.audit` needs deps installed in the target directory to run at all (matches D-03's "each needing its own `mix deps.get`" claim exactly, now empirically confirmed rather than inferred) and has **no `--path` flag** — it must be invoked with the working directory actually changed (or `cd:` opt), unlike `mix_audit`'s `deps.audit --path`. The existing `fetch_compile_deps!/2` (`mailglass.publish.check.ex:982`) is an exact, already-proven pattern for this:

```elixir
defp fetch_compile_deps!(compile_root, ctx) do
  {output, status} =
    System.cmd("mix", ["deps.get"], cd: compile_root, env: mix_env(ctx), stderr_to_stdout: true)
  # ...
end
```

**Recommendation:** the new task's per-directory `hex.audit` invocation should mirror this exact `System.cmd(..., cd: dir)` shape (fetch, then audit, same `cd:`), rather than shelling to `cd dir && mix hex.audit` via a wrapping shell command, or inventing a new subprocess pattern. `deps.audit`'s two sibling invocations use `--path <dir>` from root instead (no `cd:` needed, confirmed live: `mix deps.audit --path mailglass_admin` runs cleanly from the repo root with `mix_audit` declared only in the root project).

### F4 — DETAIL: OSV data nuance strengthens D-10, does not weaken it

`[VERIFIED: live GET https://api.osv.dev/v1/vulns/EEF-CVE-2026-43966 and .../43969, 2026-07-28]`

Both records re-fetched live. `EEF-CVE-2026-43966`: `affected[].ranges: [{"type":"SEMVER","events":[{"introduced":"2.9.0"}]}]` — confirmed no `fixed`, no `last_affected`, no `withdrawn`, matching D-10 exactly. `EEF-CVE-2026-43969` carries the same open-ended SEMVER range **plus** a second, independent signal: an explicit `affected[].versions` enumeration that lists `2.9.0` through `2.18.0` — **stopping short of `2.19.0`**, the version actually in `mailglass_admin/mix.lock`. It also carries a `references[{"type":"FIX","url":"https://github.com/erlef/cowlib/commit/177953dd..."}]` entry — a genuine fix-commit link that exists **only** as unstructured reference metadata, never as a structured `fixed` event. Two independent OSV fields (the enumerated versions list, and the FIX reference type) both carry information a naive "is version ≥ any `fixed` event" check would never see, and one of them (the versions enumeration) is itself internally inconsistent with the open-ended SEMVER range in the SAME record. This is additional, concrete evidence — beyond D-10's original citation — that a mechanized "watch OSV for the fix landing" gate would have been unreliable even accounting for fields D-10 didn't examine. No change to D-10's recommendation; this strengthens its rationale for the plan's Wave-1 write-up.

### F5 — DETAIL: Boundary compiler applies to the new `lib/` module

`[VERIFIED: mix.exs:23 (`compilers: [:boundary | Mix.compilers()]`); grep of 15 `lib/` files declaring `use Boundary, classify_to: Mailglass`]`

Every existing `lib/mix/tasks/*.ex` file and every `lib/mailglass/*.ex` module declares `use Boundary, classify_to: Mailglass` (or a sub-boundary with explicit `deps:`/`exports:`, for `lib/mailglass.ex` and `lib/mailglass/events.ex`). `Mailglass.SupplyChain.AcceptedAdvisories` should follow the plain `classify_to: Mailglass` pattern, matching `Mix.Tasks.Mailglass.Publish.Check` (its nearest sibling). Because both this new module and the new `dev/mailglass.audit.ex` task classify into the same top-level `Mailglass` boundary, they should be callable from each other without an `exports:` list entry — `boundary` only restricts cross-boundary calls, and both are in the same one. **MEDIUM confidence** (inferred from the library's documented same-boundary-call semantics and this repo's own uniform pattern; not executed in this session because doing so would require writing source files, which this read-only research phase avoids). The plan should verify this with `mix compile --warnings-as-errors` as an early, cheap acceptance check rather than assume it, and should not skip declaring `use Boundary` on the new module on the theory that it's "just data" — `Mix.Tasks.Mailglass.Publish.Check` (which is comparably just orchestration logic) still declares it.

### F6 — DETAIL: live VULN-02 re-verification with per-PR merge-state data

`[VERIFIED: gh pr list --repo szTheory/mailglass --state open --json number,title,author,autoMergeRequest,mergeable,mergeStateStatus, 2026-07-28]`

```
total open PRs: 16
dependabot PRs: 13  (#131, #130, #125, #124, #116, #115, #114, #112, #111, #108, #106, #96, #95)
```

Byte-identical to CONTEXT.md's D-12 list. All 13 carry a non-null `autoMergeRequest`. Per-PR `mergeStateStatus`:

| PR | mergeStateStatus | mergeable |
|---|---|---|
| #131, #130, #125, #124, #116, #115, #114, #112, #111, #108, #106, #95 | `BEHIND` | `MERGEABLE` |
| **#96** (igniter 0.8.1→0.8.2) | `DIRTY` | **`CONFLICTING`** |

`#96` is the one entry with a genuine merge conflict, not merely a stale base — worth flagging explicitly in the disposition table as "needs rebase or close-with-reason," not "safe to re-arm." Maintainer PR **#132** (docs guides), out of VULN-02's scope per CONTEXT.md, is also confirmed still open, `autoMergeRequest` armed, `mergeStateStatus: BEHIND` — unchanged from CONTEXT.md's snapshot. Two other non-dependabot PRs exist and are irrelevant to VULN-02 (#129, #104 — both `CONFLICTING`/`DIRTY`, both maintainer-authored, both `autoMergeRequest: null`).

---

## Standard Stack

**No new dependency, tool, or GitHub Action anywhere in this phase.** `.planning/research/v2.2/SUMMARY.md:32` locks this for the whole milestone, and CONTEXT.md D-03/D-01 reconfirm it specifically for Phase 142. Every mechanism needed already ships:

| Component | Version | Purpose | Confirmed live this session |
|---|---|---|---|
| `mix_audit` | `~> 2.1` (`mix.exs:190`) | `mix deps.audit` — transitive-dependency scanning against mirego's `elixir-security-advisories` DB | `--path` flag exists (`deps/mix_audit/lib/mix_audit/cli.ex:12`); `mix deps.audit --path mailglass_admin` runs clean from root |
| Hex's built-in `hex.audit` | ships with the `hex` archive | Direct + resolved-lock scanning against Hex's own EEF-CVE database | `mix hex.audit` at root = clean; inside `mailglass_admin` (deps present) = 2 findings, exit 1; inside `mailglass_inbound` (after `deps.get`) = clean |
| OSV.dev REST API | `api.osv.dev/v1/vulns/{id}` | Optional staleness enrichment (D-10, warn-only) | Both allowlisted IDs fetched live; confirmed event shape (no `fixed`) |
| `System.cmd/3` `cd:` opt | stdlib | Per-directory subprocess invocation | Already the proven pattern at `mailglass.publish.check.ex:982` |
| `Boundary` | `~> 0.10` (`mix.exs:166`) | Compile-time module classification, already gates `lib/` | New `lib/` module must declare `use Boundary, classify_to: Mailglass` (F5) |

No installation steps. No version-verification section needed — nothing new is being added to `mix.lock`.

---

## Package Legitimacy Audit

**Not applicable — this phase installs no external packages.** Every mechanism (`mix_audit`, `hex.audit`, the OSV REST API, `Boundary`) is already a dependency of this repository, already used by `mailglass.publish.check.ex` or `ci.yml` today. No `npm view` / `pip index` / `cargo search` verification is needed. Any recommendation introducing a new package during planning or execution should be treated as a direct violation of the milestone's locked "no new dependency" constraint (`.planning/research/v2.2/SUMMARY.md:32`, CONTEXT.md D-03/D-01).

---

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────────────┐
                         │  Mailglass.SupplyChain.AcceptedAdvisories  (lib/)
                         │  - allowlist entries (id/aliases/package/
                         │    severity/reason/accepted_on/recheck_by)
                         │  - unaccepted_audit_findings/1
                         │  - unaccepted_deps_audit_findings/1
                         │  - expired_entries/1, unused_entries/2  (D-10)
                         └───────────────┬───────────────────────┘
                                         │ called by (same Boundary)
              ┌──────────────────────────┼───────────────────────────┐
              │                          │                           │
   ┌──────────▼─────────┐   ┌────────────▼───────────┐   ┌───────────▼────────────┐
   │ Mix.Tasks.Mailglass.│   │ Mix.Tasks.Mailglass.    │   │ Mix.Tasks.Mailglass.   │
   │ Publish.Check       │   │ Audit  (dev/)           │   │ Publish.Check's        │
   │ (lib/, unchanged     │   │ - per-directory hex.audit│  │ parsers become thin    │
   │  entrypoint, delegates│  │   (cd: root/admin/inbound)│  │ delegations to the    │
   │  to the new module)  │   │ - per-directory deps.audit│  │ new lib/ module        │
   └──────────┬───────────┘   │   (--path admin/inbound) │   └────────────────────────┘
              │                │ - filter through allowlist│
              │                │ - exit non-zero on any    │
              │                │   non-accepted finding    │
              │                └────────────┬───────────────┘
              │                             │ invoked by
              │              ┌──────────────┴───────────────┐
              │              │                               │
   ┌──────────▼───────┐ ┌────▼─────────────────┐   ┌─────────▼──────────────┐
   │ Hex publish gate   │ │ ci.yml: hex_audit job │   │ mix.exs :ci alias       │
   │ (mailglass.publish.│ │ ci.yml: deps_audit_    │   │ (F1 — must reproduce   │
   │  check --package)  │ │ advisory job          │   │  the same 3-dir scan   │
   │ Already hard-blocks│ │ (Wave 2: both move    │   │  locally, MIXCI-03)    │
   │  today (unchanged) │ │  into ci_green.needs  │   └─────────────────────────┘
   └────────────────────┘ │  + required_lanes/0)  │
                           └────────────────────────┘
```

### Recommended Project Structure

```
lib/
└── mailglass/
    └── supply_chain/
        └── accepted_advisories.ex     # NEW — Mailglass.SupplyChain.AcceptedAdvisories
dev/
└── mix/
    └── tasks/
        └── mailglass.audit.ex         # NEW — Mix.Tasks.Mailglass.Audit
test/
├── mailglass/
│   ├── supply_chain/
│   │   └── accepted_advisories_test.exs   # NEW — data/parser unit tests
│   └── publish/
│       └── audit_allowlist_test.exs        # MODIFIED (F2's positive alias test)
└── mix/
    └── tasks/
        └── mailglass_audit_test.exs        # NEW — auto-included by verify.mix_tasks (no wiring needed)
```

### Pattern 1: Thin-delegation preserves the existing public test surface

**What:** `Mix.Tasks.Mailglass.Publish.Check.unaccepted_audit_findings/1` and `.unaccepted_deps_audit_findings/1` keep their existing 1-arity, `@doc false`-public signature, but their body becomes a one-line delegation:

```elixir
# lib/mix/tasks/mailglass.publish.check.ex — AFTER D-01
@doc false
def unaccepted_audit_findings(output),
  do: Mailglass.SupplyChain.AcceptedAdvisories.unaccepted_audit_findings(output)

@doc false
def unaccepted_deps_audit_findings(output),
  do: Mailglass.SupplyChain.AcceptedAdvisories.unaccepted_deps_audit_findings(output)
```

**When to use:** exactly here — `test/mailglass/publish/audit_allowlist_test.exs` calls `Check.unaccepted_audit_findings(output)` today (verified, `audit_allowlist_test.exs:23,33,38,42`); this pattern requires zero changes to that test file's call sites while the real implementation and the `@accepted_advisories` list itself move to the new module.

**Example (verified current shape, to be moved+wrapped):**
```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex:1113-1131 (current, pre-extraction)
@doc false
def unaccepted_audit_findings(output) do
  lines = String.split(output, "\n")
  retired = if Enum.any?(lines, &(&1 =~ ~r/retired/i)) and
               not Enum.any?(lines, &(&1 =~ ~r/No retired packages found/i)),
            do: ["retired package(s) present"], else: []
  advisories =
    lines
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^\s+(\S+)\s+\S+\s+-\s+(\S+)\s+\(/, line) do
        [_, pkg, id] -> [{pkg, id}]
        _ -> []
      end
    end)
    |> Enum.reject(fn {_pkg, id} -> Map.has_key?(@accepted_advisories, id) end)  # <- D-02 changes this reject to alias-aware matching
    |> Enum.map(fn {pkg, id} -> "#{pkg} #{id}" end)
  retired ++ advisories
end
```

### Pattern 2: Per-directory audit orchestration with allowlist filtering

**What:** the new `mailglass.audit` task runs each directory's audit command, checks exit status, and — only on non-zero — parses and filters through the shared allowlist, aggregating findings across all scanned directories before deciding its own exit code. Mirrors `verify_audit/1`'s and `verify_deps_audit/1`'s existing per-package status-check/parse/filter shape (`mailglass.publish.check.ex:1068-1102`, `:1142-1177`) but runs the loop across `["", "mailglass_admin", "mailglass_inbound"]` (or the `hex.audit`/`deps.audit`-appropriate subset) instead of the tarball-isolation single directory.

**When to use:** both the `hex_audit` and `deps_audit_advisory` `ci.yml` jobs, and the local `mix ci` alias (F1).

### Anti-Patterns to Avoid

- **Re-deriving the `cd:`-based subprocess pattern instead of reusing `fetch_compile_deps!/2`'s shape.** A shell-string `cd dir && mix hex.audit` invocation is harder to test, harder to capture stderr from cleanly, and diverges from this repo's one existing precedent for exactly this problem (F3).
- **Leaving `mix.exs`'s `:ci` alias untouched while widening the CI-side audit lanes.** Silently narrows the MIXCI-03 local-parity guarantee (F1) — the exact defect class (a claim that quietly stops being true, with a test that still passes) this milestone exists to eliminate.
- **Building the OSV `{:fixed, ...}` staleness gate as the primary mechanism.** Locked out by D-10 and reinforced by F4's live re-verification — do not resurrect this even as a "small addition," since the optional warn-only enrichment is explicitly allowed and sufficient.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Per-directory `mix deps.get` before an audit | A new subprocess-spawning helper | `System.cmd("mix", ["deps.get"], cd: dir, ...)`, the exact pattern at `mailglass.publish.check.ex:982` | Already proven, already exercised by the publish gate on every release. |
| Parsing `mix hex.audit` / `mix deps.audit` human output | A new regex/parser from scratch | The two existing `@doc false` parsers (`unaccepted_audit_findings/1`, `unaccepted_deps_audit_findings/1`), moved (not rewritten) per D-01 | Already unit-tested (`audit_allowlist_test.exs`, 163 lines) against real tool output shapes, including the multi-line `deps.audit` block format. |
| Detecting whether an allowlisted advisory's upstream fix has landed | An OSV `fixed`-event watcher | The two local deterministic checks (`recheck_by` date, unused-entry) — D-10 | Live-verified (F4) that OSV's structured fields are unreliable for this specific pair of advisories; a mechanized OSV-fixed gate would silently never fire. |
| Per-directory audit scope | A generic "scan every mix.exs in the repo" framework | The three-directory literal list (root, `mailglass_admin`, `mailglass_inbound`) — matches `dependabot.yml`'s existing three `mix` ecosystem entries exactly | This repo has exactly three Mix projects, verified via `dependabot.yml`; a generalized scanner is over-engineering for a fixed, small, known set. |
| Expiry-date comparison | A date library or new dependency | `Date.compare(Date.utc_today(), recheck_by) == :gt` (stdlib) | No existing `Date.compare`/`~D[...]` pattern exists anywhere in `lib/`/`dev/` today (grepped, zero hits) — this is genuinely new territory for the codebase, but stdlib `Date` is sufficient; no reason to add a dependency for it. |

**Key insight:** every hand-rollable piece of this phase already has an in-repo precedent within `mailglass.publish.check.ex` — the work is extraction and per-directory looping, not new mechanism design. The one genuinely novel piece (date-based expiry) is a one-line stdlib comparison, not infrastructure.

---

## Common Pitfalls

### Pitfall 1: Wiring `ci.yml` to the new task before the allowlist-suppression logic is proven correct

**What goes wrong:** `hex_audit` is publish-gating (not merge-gating) today, but it is currently green (root is clean). If Wave 1 rewires its step to call the new task before the allowlist correctly suppresses `mailglass_admin`'s two live cowlib findings, the lane goes red on Hex publish — a self-inflicted instance of Pitfall 3 from `.planning/research/v2.2/PITFALLS.md:187-201`, scoped to Wave 1 instead of Wave 2.
**Why it happens:** the module, the task, and the `ci.yml` step rewiring feel like three separable increments, but D-14's live-verification gate implies they cannot ship independently without a red window.
**How to avoid:** land the module, the task (with the allowlist filtering fully implemented, not stubbed), and the `ci.yml` rewiring for BOTH jobs in one Wave-1 commit — do not stage "wire the step first, add filtering later."
**Warning signs:** a plan task that adds the `ci.yml` step change before the allowlist filtering logic has a passing unit test against real `mailglass_admin` `hex.audit` output.

### Pitfall 2: Trusting `ci_parity_drift_test.exs` staying green as proof of local/CI parity

**What goes wrong:** per F1, the parity test only checks `mix.exs`'s literal alias text for a substring — it never reads `ci.yml`. A widened CI-side scan with an unwidened local alias passes this test while silently breaking the parity claim it exists to protect.
**Why it happens:** the test's own name ("drift test") implies it catches this class of problem; its actual mechanism (substring match on the local alias only) does not.
**How to avoid:** treat "does `mix ci` reproduce the widened three-directory scan" as a manual acceptance criterion in the plan, not something the existing test proves for free.
**Warning signs:** a plan that widens `ci.yml`'s audit jobs but doesn't touch `mix.exs:395-396`.

### Pitfall 3: Letting D-02's alias-matching land without updating the two stale "GHSA never suppressed" comments

**What goes wrong:** per F2, two prose comments (one in source, one in the test file) explicitly assert a permanent asymmetry that D-02 closes. Left unedited, a future maintainer reading either comment is told something false — the exact class of defect (`ci.yml:578-580`) Phase 141 closed elsewhere in this same milestone.
**How to avoid:** rewrite both comments in the same commit that lands alias-matching, and add the positive test using the real `GHSA-g2wm-735q-3f56` value.
**Warning signs:** a diff that adds `:aliases`-based matching but leaves `audit_allowlist_test.exs:57-62` or `mailglass.publish.check.ex:1179-1186`'s prose untouched.

### Pitfall 4: Blanket-processing the dependabot backlog

**What goes wrong:** per D-12 (already locked, reinforced by F6's live data) — #96 has a real merge conflict (`CONFLICTING`/`DIRTY`), not just staleness; treating all 13 uniformly (merge-all or close-all) either lands a broken merge attempt on #96 or discards genuinely-wanted updates (e.g. #108, the SHA-pinned `erlef/setup-beam` bump).
**How to avoid:** the disposition table must record per-PR reasoning, and #96 specifically needs a rebase-or-close decision, not a blind re-trigger of auto-merge.
**Warning signs:** a plan task phrased as "merge all 13 dependabot PRs" or "close all 13 dependabot PRs" without enumeration.

### Pitfall 5: Skipping `use Boundary, classify_to: Mailglass` on the new `lib/` module

**What goes wrong:** per F5, `mix.exs:23` runs the boundary compiler on every build; `compile_warnings` (publish-gating) runs `mix compile --warnings-as-errors`. An undeclared module in `lib/` risks a boundary warning turning into a build failure.
**How to avoid:** declare it, matching every sibling `lib/mix/tasks/*.ex` file; verify early with `mix compile --warnings-as-errors`.
**Warning signs:** a plan that treats the new module as "just data" and omits the Boundary declaration on that basis.

---

## Code Examples

### Existing per-package audit pattern (to be widened to a per-directory loop)

```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex:1068-1102 (verify_audit/1, current)
defp verify_audit(ctx) do
  audit_root = compile_root(ctx)
  fetch_compile_deps!(audit_root, ctx)

  {output, status} =
    System.cmd("mix", ["hex.audit"], cd: audit_root, env: mix_env(ctx), stderr_to_stdout: true)

  if status != 0 do
    case unaccepted_audit_findings(output) do
      [] ->
        accepted = @accepted_advisories |> Map.values() |> Enum.join("; ")
        Map.put(ctx, :audit_output,
          String.trim(output) <> "\n\n[mailglass.publish.check] hex.audit findings are all in the " <>
          "accepted-advisories allowlist (no upstream fix available) — delivery allowed: #{accepted}")
      unaccepted ->
        fail_step("run hex.audit",
          "Delivery blocked: mix hex.audit reported non-accepted issues for #{ctx.package} " <>
          "(#{Enum.join(unaccepted, ", ")}). A fix is available — bump the dep. Full output:\n#{String.trim(output)}")
    end
  else
    Map.put(ctx, :audit_output, output)
  end
end
```

The new task's per-directory loop is this same status-check/parse/filter shape, applied `Enum.each`/`Enum.reduce` style over `["", "mailglass_admin", "mailglass_inbound"]` for `hex.audit` (each needing its own `deps.get` first, per F3), aggregating unaccepted findings across all three before deciding the task's own exit code — brand-voice failure messages ("Delivery blocked: ...", naming the fix) should follow the same convention.

### Live-verified `mix hex.audit` behavior by directory (this session)

```
$ mix hex.audit                              # root
No retired or security advisory packages found   (exit 0)

$ cd mailglass_admin && mix hex.audit
Advisories:
  cowlib 2.19.0 - EEF-CVE-2026-43969 (LOW)     aka: CVE-2026-43969, GHSA-g2wm-735q-3f56
  cowlib 2.19.0 - EEF-CVE-2026-43966 (MEDIUM)  aka: CVE-2026-43966
Found packages with security advisories           (exit 1)

$ mix deps.audit --path mailglass_admin      # from root
No vulnerabilities found.                          (exit 0 — mirego DB range excludes 2.19.0)

$ cd mailglass_inbound && mix deps.get && mix hex.audit
No retired or security advisory packages found   (exit 0)
```

### Live-verified OSV record shape (both allowlisted IDs, re-fetched this session)

```json
// EEF-CVE-2026-43966
{"aliases":["CVE-2026-43966"], "modified":"2026-07-14T03:30:07...",
 "affected":[{"ranges":[{"type":"SEMVER","events":[{"introduced":"2.9.0"}]}]}]}
 // no "fixed", no "last_affected", no "withdrawn" anywhere in the record

// EEF-CVE-2026-43969
{"aliases":["CVE-2026-43969","GHSA-g2wm-735q-3f56"], "modified":"2026-07-14T03:30:04...",
 "affected":[
   {"ranges":[{"type":"SEMVER","events":[{"introduced":"2.9.0"}]}],
    "versions":["2.9.0",...,"2.18.0"]},                          // stops at 2.18.0, not 2.19.0 (F4)
   {"ranges":[{"type":"GIT","events":[{"introduced":"<commit>"}]}], "versions":[...same cap...]}],
 "references":[{"type":"FIX","url":"https://github.com/erlef/cowlib/commit/177953dd..."}]}
 // FIX reference exists but is never surfaced as a structured "fixed" event (F4)
```

---

## State of the Art

| Old Approach (pre-Phase-142) | Current Approach (this phase) | When Changed | Impact |
|---|---|---|---|
| `@accepted_advisories` lives only inside `mailglass.publish.check.ex`, publish-time-only enforcement | Shared `Mailglass.SupplyChain.AcceptedAdvisories`, enforced at both CI and publish time | This phase (D-01) | CI-side lanes gain the same allowlist logic; no more "publish is the only place a non-accepted advisory blocks anything." |
| `ci.yml`'s `hex_audit` runs bare `mix hex.audit` at root only, zero allowlist awareness | Per-directory, allowlist-filtered scan via the new task | This phase (D-03, D-01) | The lane can now see the repository's only live advisories (in `mailglass_admin`) instead of always passing vacuously. |
| GHSA-keyed `deps.audit` findings can never match EEF-CVE-keyed allowlist entries | Alias-based matching bridges the two ID namespaces | This phase (D-02) | Closes a documented, previously-accepted hole (F2). |
| Allowlist entries carry only a reason string, no expiry | Entries carry `recheck_by` + two deterministic staleness checks | This phase (D-10) | Prevents the exact "rationale text says 2.17.1, lock is at 2.19.0" staleness the allowlist itself already exhibits today (per CONTEXT.md `<specifics>`). |

**Deprecated/outdated:** the two stale prose comments identified in F2 (`mailglass.publish.check.ex:1179-1186`, `audit_allowlist_test.exs:57-62`) describing the GHSA/EEF asymmetry as permanent — must be rewritten as part of this phase's own work, not left as historical artifacts.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Same-boundary (`classify_to: Mailglass`) modules can call each other's public functions without an explicit `exports:` entry | F5, Architecture Patterns | Low-Medium — if wrong, `mix compile --warnings-as-errors` fails immediately and loudly at the first build, which the plan should run early regardless; no silent failure mode. |
| A2 | A single `mailglass.audit` task with a `--kind hex\|deps` flag is the right shape, vs. two separate tasks | Architecture Patterns, Pattern 2 | Low — this is explicitly Claude's Discretion per CONTEXT.md; either shape satisfies D-01's `lib/`-data/`dev/`-task split. |
| A3 | The new task does not need to be added to `stability_contract_test.exs`'s enumerated `assert_module_since` list to pass CI | §Verification, `mailglass.repo.hygiene` nuance | Low — directly verified: the test enumerates modules by name, does not scan a directory: confirmed by reading the test file. |
| A4 | `mix.exs`'s `:ci` alias should be widened to call the new task (F1's recommendation), rather than accepting a narrower local-parity claim | F1 | Medium — this is a recommendation, not a locked decision; CONTEXT.md's own `<code_context>` flagged the tension without resolving it ("either keep both audit invocations discoverable... or update the matcher"). If the planner chooses the "just update the matcher" branch instead, MIXCI-03's parity guarantee narrows silently — a real but bounded risk, not a correctness bug. |

**If this table is empty:** N/A — see above.

---

## Open Questions

1. **Should the new task expose one command with `--kind` or two separate Mix tasks?**
   - What we know: both satisfy D-01's `lib/`-data / `dev/`-task split; the two `ci.yml` jobs (`hex_audit`, `deps_audit_advisory`) are separate jobs today and can each invoke a distinctly-named command either way.
   - What's unclear: naming ergonomics only — no functional difference.
   - Recommendation: single task, `--kind` flag (mirrors `mailglass.publish.check`'s own `--package` flag convention at `mailglass.publish.check.ex:12`), but this is explicitly Claude's Discretion — the planner should pick and record the choice explicitly rather than let it emerge implicitly across tasks.

2. **Does `mix ci`'s local alias get widened to the full three-directory scan (F1's recommendation), and is the cost (extra `deps.get` in `mailglass_admin`/`mailglass_inbound` on every local `mix ci` run) acceptable?**
   - What we know: SEED-006 (wall-clock/CI-cost work) is explicitly deferred past this milestone; F1's fix adds real local wall-clock cost to `mix ci`, not just CI wall-clock cost.
   - What's unclear: whether the maintainer would rather accept a documented, narrower local-parity claim (Claude's Discretion equivalent: "the matcher-only fix") to avoid that local cost.
   - Recommendation: widen it (F1) and record the added cost as a SEED-006 input alongside the already-flagged per-directory `deps.get` cost in CI — treating local and CI cost as one combined, already-deferred line item rather than two separate open questions.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir / OTP | all Elixir work | ✓ | 1.18.4 / 27.3.4.13 (`.tool-versions`) | — |
| `mix_audit` | `mix deps.audit --path` | ✓ | `~> 2.1` (already a dep, `mix.exs:190`) | — |
| `hex.audit` | per-directory scanning | ✓ | ships with the `hex` archive | — |
| Network access to `api.osv.dev` | live OSV re-check, optional D-10 enrichment | ✓ | confirmed in this session for both allowlisted IDs | fail-open per the existing `osv_get/1` contract (never blocks) |
| `gh` CLI (authenticated) | VULN-02 backlog verification | ✓ | verified against `repos/szTheory/mailglass`, live `gh pr list` succeeded | — |
| PostgreSQL | NOT needed — `hex.audit`/`deps.audit` touch no DB | n/a | — | — |
| Network access to fetch `mailglass_admin`/`mailglass_inbound` deps | per-directory `deps.get` (D-03) | ✓ | confirmed live (`mailglass_inbound`'s `mix deps.get` succeeded, 19 packages) | — |

**Missing dependencies with no fallback:** none.

---

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (Elixir 1.18 / OTP 27) |
| Config file | `test/test_helper.exs` — boots `Mailglass.TestRepo`, but **not needed** by this phase's own new tests (audit parsing/orchestration touches no DB) |
| New test locations | `test/mailglass/supply_chain/accepted_advisories_test.exs` (new), `test/mix/tasks/mailglass_audit_test.exs` (new, auto-included), `test/mailglass/publish/audit_allowlist_test.exs` (modified per F2) |
| `test/mix/tasks/` auto-inclusion | **Already wired — no new CI step needed.** `verify.mix_tasks` (`mix.exs:287`, run inside the `mix_task_tests` job, `ci.yml:230`) is `"test test/mix/tasks/ --warnings-as-errors"`, a directory glob. A new `mailglass_audit_test.exs` there is picked up automatically. |
| Quick run | `MIX_ENV=test mix test test/mailglass/supply_chain/ test/mix/tasks/mailglass_audit_test.exs test/mailglass/publish/audit_allowlist_test.exs --no-start` |
| Full suite | `mix ci` (needs Postgres + network for unrelated lanes; this phase's own tests don't need either) |

### Success Criteria → Concrete Checks

| # | Criterion | Runnable check | Runs where |
|---|---|---|---|
| 1 | `hex_audit` CI lane honors the shared allowlist, landed+green before criterion 2 | `mix mailglass.audit --kind hex` locally against `mailglass_admin`'s real cowlib findings, exit 0; a real PR run showing `Hex Audit` green with cowlib detected-and-suppressed (D-14's exact requirement) | Local + **CI, human-observed once** (checkpoint) |
| 1b | The allowlist genuinely filters, not vacuously passes | Deliberate-drift probe: temporarily remove one `@entries` item, confirm the task now exits non-zero on `mailglass_admin`'s real findings, revert | Human, once, mirroring the `lane_classification_drift_test.exs` negative-control precedent Phase 141 established |
| 2 | Both lanes merge-gating; new HIGH-with-fix blocks, cowlib-only merges clean | D-15's deterministic unit test (synthetic HIGH-with-fix output → task exits non-zero; cowlib-only real output → exits zero) | CI (new task's own test suite) |
| 2b | The 24-job classification totality (5+4+13+2→7+3+12+2=24) still holds after promotion | `mix verify.ci_lane_contract` (the Phase-141-built meta-test, now exercising Wave 2's edits) | CI (`mix_task_tests`, publish-gating) |
| 2c | Local `mix ci` parity is not silently narrowed (F1) | `mix ci`'s audit step(s) invoke the same `mailglass.audit` command the CI lanes do; `ci_parity_drift_test.exs` passes with the UPDATED matcher (not the stale one) | Local + CI |
| 3 | Every allowlisted advisory has a reason + `recheck_by`; expired/unused entries flagged | Unit tests on `expired_entries/1` (a past-dated `recheck_by` fails loud) and `unused_entries/2` (an entry matching no current finding fails loud — F4/D-10 confirm this fires TODAY against the real allowlist's stale "no upstream fix as of 2.17.1" rationale text once `deps.audit`'s clean-for-cowlib result is fed in) | CI |
| 4 | All 13 dependabot PRs dispositioned | `gh pr list --repo szTheory/mailglass --state open --json number,author,autoMergeRequest` returns zero `app/dependabot` entries with non-null `autoMergeRequest`, OR each remaining one has a recorded reason in the phase artifact | Human, once, at phase close |
| 5 | Triage cadence documented, names who/how-often/response-by-severity, states the transitive-PR limitation | `grep -A 20 '## Dependency Advisory Triage' MAINTAINING.md` shows all three elements; `lane_classification_drift_test.exs`'s section-boundary parser still finds exactly 24 rows in `## Required Checks` (i.e., the new section didn't get inserted inside the table's bounds) | CI (existing meta-test, unmodified) + human read |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/supply_chain/ test/mix/tasks/mailglass_audit_test.exs --warnings-as-errors`
- **Per wave merge:** `mix ci.fast` (compile + credo must stay green; Wave 2 touches `mix.exs`/`ci_lanes.ex` again) + `mix verify.ci_lane_contract`
- **Phase gate:** full `mix ci` green, plus a real PR-run observation of D-14's Wave-1-green-with-cowlib-in-scope evidence, recorded in the phase SUMMARY (mirroring Phase 141's Task-3 checkpoint pattern at `141-06-SUMMARY.md`).

### Wave 0 Gaps

- [ ] `lib/mailglass/supply_chain/accepted_advisories.ex` — new module (covers VULN-05, VULN-06)
- [ ] `dev/mix/tasks/mailglass.audit.ex` — new task (covers VULN-05)
- [ ] `test/mailglass/supply_chain/accepted_advisories_test.exs` — new (covers VULN-06's expiry checks)
- [ ] `test/mix/tasks/mailglass_audit_test.exs` — new, auto-included by the existing `verify.mix_tasks` alias, **no `ci.yml`/`mix.exs` wiring needed** (unlike Phase 141's F2, this directory is already wired)
- [ ] `test/mailglass/publish/audit_allowlist_test.exs` — modify per F2 (positive alias-suppression test + updated docstrings)

No framework install needed. No new dependency.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | This phase touches no auth surface. |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Marginal | The task parses `mix hex.audit`/`mix deps.audit` **local subprocess output**, not untrusted network input — existing regex-based parsers (`unaccepted_audit_findings/1` etc.) are the precedent, already hardened against malformed/empty output (anti-vacuity tests exist). |
| V6 Cryptography | No | — |
| V14 Configuration (supply-chain specific) | **Yes — this is the phase's core domain** | `mix hex.audit` / `mix deps.audit` against Hex's EEF-CVE DB and mirego's `elixir-security-advisories` DB, respectively; never hand-roll a vulnerability database. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Allowlist entry silently outliving its justification (the exact defect VULN-06 targets) | Tampering (of trust, not code) | D-10's two deterministic local checks (`recheck_by` expiry, unused-entry detection) — no reliance on an external service's structured fields, per F4's live-verified unreliability finding |
| A transitive-dependency advisory (no direct-dep PR possible) going unnoticed indefinitely — the `hpax` precedent this milestone exists to close | Information Disclosure / Repudiation (of due diligence) | VULN-04's documented triage cadence explicitly names reading raw `mix hex.audit`/`mix deps.audit` output, not just the dependabot PR queue, as the only path for this class |
| A stale dependabot PR (auto-merge armed, base moved weeks ago) merging a conflicting or superseded change automatically | Tampering | VULN-02's per-PR disposition, not blanket processing; F6 identifies #96 as the one PR with a real conflict today |
| OSV/Hex API outage during a scan silently blocking or silently passing | Denial of Service (self-inflicted) | Fail-open contract already proven at `osv_get/1` (`mailglass.publish.check.ex:1244-1261`) — D-10 keeps OSV enrichment optional/warn-only precisely so an outage there cannot block anything; the LOCAL `hex.audit`/`deps.audit` calls themselves are not network-optional (they need the resolved lock + Hex API), matching today's existing publish-gate behavior — no new failure mode introduced |

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on this phase |
|---|---|
| "Don't call `Swoosh.Mailer.deliver/1` directly" etc. — engineering-DNA list | Not applicable; this phase touches no mail-sending code path. |
| Custom Credo checks at lint time | The new `lib/`/`dev/` files must pass `mix credo --strict` (publish-gating `credo_strict` lane, and `mix ci.fast` locally) — no exemption needed, no new Credo check required for this phase. |
| Errors are specific and composed; brand voice ("Delivery blocked: ...") | The new task's failure messages must follow the existing convention exactly, e.g. `"Delivery blocked: mix hex.audit reported non-accepted issues for <dir> (...). A fix is available — bump the dep."` — mirror `mailglass.publish.check.ex:1096-1099`'s phrasing, not a generic error. |
| Don't pattern-match errors by message string | N/A — this phase adds no new `%Mailglass.Error{}` types; the task's exit codes are the only interface. |
| `.planning/` tracked in git; commit but don't push without confirmation | The VULN-02 disposition table (a phase artifact) and any `.planning/`-only commits follow the existing convention. |
| Conventional Commits enforced; `docs(state):` for STATE.md | Wave 1/2/3 commits should use `ci:`/`feat:`/`test:`/`docs:` types appropriately — mirroring Phase 141's precedent (`aa004dd7` feat, `abe92a3d` test, `920f853c` docs) — never a releasing type on a `.planning/`-only or docs-only commit if the milestone intends to stay repo-artifact-only during this window (confirm current release posture before committing; v2.2 ships no Hex release per `.planning/STATE.md` "v2.2 Scope Locks"). |
| Decision Policy — research first, decide, escalate rarely | F1-F6 above were decided here with live evidence rather than escalated; F1 is the one genuine open-question candidate (§Open Questions #2) but the reversibility test (`.planning/METHODOLOGY.md`) favors "just pick the recommended option" since it's a cheap, later-reversible cost trade, not a strategic fork. |

---

## Sources

### Primary (HIGH confidence — read directly in this worktree at `87d6f775`, or executed live, 2026-07-28)
- `lib/mix/tasks/mailglass.publish.check.ex` (full read of the allowlist, both parsers, both `verify_*` functions, OSV staleness gate)
- `test/mailglass/publish/audit_allowlist_test.exs` (full read, 163 lines)
- `.github/workflows/ci.yml` (`hex_audit`, `deps_audit_advisory`, `ci_green` job bodies, exact line numbers)
- `.github/workflows/publish-hex.yml` (`REQUIRED_LANES`/`ADVISORY_LANES`/`PUBLISH_GATING_LANES`/`STRUCTURAL_LANES`, `classify/1`)
- `test/support/ci_lanes.ex` (full read, all four classification buckets + accessors)
- `MAINTAINING.md` (full section-header scan, exact rows for `hex_audit`/`deps_audit_advisory`)
- `test/scripts/lane_classification_drift_test.exs`, `test/scripts/ci_parity_drift_test.exs` (exact count assertions, matcher table)
- `mix.exs` (aliases, `elixirc_paths`, `compilers`, `preferred_cli_env`, dependency list)
- `docs/api_stability.md`, `test/mailglass/stability_contract_test.exs`
- `dev/mix/tasks/mailglass.repo.hygiene.ex`, `.github/workflows/repo-hygiene.yml`
- `.github/dependabot.yml`, `.github/workflows/gate-self-test.yml`, `test/scripts/conformance_advisory_test.exs`
- `deps/mix_audit/lib/mix_audit/cli.ex`
- Live shell execution: `mix hex.audit` (root, `mailglass_admin`, `mailglass_inbound`), `mix deps.audit` (root, `--path mailglass_admin`, `--path mailglass_inbound`), `mix deps.get` (`mailglass_inbound`)
- Live GitHub REST via `gh pr list --repo szTheory/mailglass --state open --json number,title,author,autoMergeRequest,mergeable,mergeStateStatus`
- Live OSV.dev REST: `GET https://api.osv.dev/v1/vulns/EEF-CVE-2026-43966`, `.../EEF-CVE-2026-43969`
- `.planning/phases/141-lane-truth-foundation/141-RESEARCH.md` and all six `141-0N-SUMMARY.md` files (what Phase 141 actually landed, cross-checked against the live tree)
- `.planning/todos/pending/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` (the folded todo, full read)

### Secondary (MEDIUM confidence)
- Boundary library same-boundary-call semantics (F5, A1) — inferred from this repo's own uniform usage pattern across 15+ files, not independently verified against the `boundary` package's own documentation in this session, and not executed via a real compile in this read-only research phase.

### Tertiary (LOW confidence)
- None. Every claim in this document is either verified against the live repo/live API in this session, or explicitly flagged MEDIUM above with its risk noted in the Assumptions Log.

---

## Metadata

**Confidence breakdown:**
- CONTEXT.md citation accuracy: **HIGH** — every citation re-read against the live tree; zero drift found (D-05's nine sites, D-06's blast radius, all canonical_refs)
- Live per-directory advisory distribution (D-03): **HIGH** — directly executed `mix hex.audit`/`mix deps.audit` in all three directories this session
- OSV event-shape claim (D-10): **HIGH** — directly fetched both records live this session, with an additional nuance (F4) beyond CONTEXT.md's own citation
- VULN-02 backlog state (D-12): **HIGH** — directly re-queried via authenticated `gh` this session, byte-identical to CONTEXT.md plus new per-PR merge-state detail
- F1 (`mix ci` parity gap) and its recommended fix: **HIGH** on the gap's existence (test mechanism read directly), **MEDIUM** on the specific fix being the maintainer's preferred resolution (an open question, not a locked call)
- F5 (Boundary same-boundary calls): **MEDIUM** — inferred, not executed; flagged explicitly for early verification

**Research date:** 2026-07-28
**Valid until:** 2026-08-27 (30 days) — or immediately invalid if `ci.yml`'s job set, `mix.lock`/`mailglass_admin/mix.lock`'s advisory-relevant entries, or either OSV record changes. Re-run the live `mix hex.audit`/`mix deps.audit` and OSV fetch commands before implementing if meaningful time has passed, per this repo's own established "verify live, don't trust the citation" precedent (Phase 141).
