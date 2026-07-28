# Feature Research — v2.2 CI Signal Integrity & Supply-Chain Hygiene

**Domain:** Maintainer-facing CI/release-engineering capabilities for a mature, single-maintainer,
3-package Elixir/Hex OSS library (not adopter-facing product features)
**Researched:** 2026-07-28
**Confidence:** HIGH for repo-specific findings (read directly from `.github/workflows/`,
`test/support/ci_lanes.ex`, `MAINTAINING.md`, `mailglass_admin/scripts/check-conformance.sh`);
MEDIUM-HIGH for general OSS-ecosystem conventions (web-verified against GitHub's own guidance,
current as of publication dates checked)

## Framing

This is a maintenance/trust-restoration milestone, not product expansion. "Table stakes" here
means *what a well-run single-maintainer Elixir/Hex OSS repo is expected to have*, not what an
adopter of mailglass-the-library expects. "Differentiator" means *above and beyond* what peer
repos (Phoenix, Ecto, Ash, Oban, Bandit — the same 10-repo comparison set used in
`CICD-RELEASE-HARDENING.md`) typically bother with. "Anti-feature" is reserved for things that
look like they belong in this milestone but are actually SEED-006 (speed/efficiency) work in
disguise, or that would constitute the locked-out CI topology rewrite.

Mapped downstream to phases 141 (VULN), 143 (CONFORM), 144 (TRUTH). Phase 142 (HARNESS) is out of
this document's question scope (covered by SEED-007) and only referenced where a pattern overlaps.

---

## Feature Landscape

### Table Stakes (a well-run OSS repo has these)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Scheduled vulnerability audit run, independent of PR traffic** | Dependabot's alert graph only fires on `mix.lock` changes it detects and only for *direct* advisories it can map to a GHSA; a repo that only audits "when a PR happens to touch deps" misses transitive CVEs (this repo's own `hpax` HIGH proved it — dependabot never filed it). A cron-triggered `mix hex.audit` / `mix deps.audit` run against the current lockfile, independent of any PR, is the baseline. | LOW | Already exists as `advisory-matrix.yml`'s implicit cron coverage is missing for audit specifically — `hex_audit`/`deps_audit_advisory` in `ci.yml` only run on `pull_request`/`push` (gated by `needs: [changes]` path-filter), not `schedule:`. Adding a `schedule:` trigger (mirroring `repo-hygiene.yml`'s daily cron) closes the "nobody touched deps this week so nobody audited" gap. |
| **Written, severity-tiered response SLA** | The 2026 GitHub Blog / community consensus (see Sources) converges on the same shape every mature project lands on independently: acknowledge fast, patch by severity tier, don't let "eventually" stand in for a number. `MAINTAINING.md` already has this shape for **inbound-reported** vulnerabilities (`## Security Response SLA`: 72h ack / 14-day mitigation for critical). VULN-04 needs the mirror-image doc for **outbound-discovered** advisories (routine `hex.audit`/`deps.audit` findings) — a distinct process from "someone emailed us a CVE." | LOW | Pure documentation + a disposition record shape (see below); no new tooling required beyond what VULN-01/03 already produce as evidence. |
| **A disposition record for every accepted advisory (not just a bare allowlist)** | An allowlist entry that's just an ID with no date/rationale/revisit-trigger is how the cowlib entries would have silently outlived their justification (`CICD-RELEASE-HARDENING.md` §4.3 flagged exactly this risk before it happened). The `@accepted_advisories` map in `mailglass.publish.check.ex` already carries a human-readable reason string per entry — the missing piece is the *documented cadence* that forces someone to look at it again, not the data shape. | LOW | Already-present pattern: `@accepted_advisories` (lines 62-67 of `lib/mix/tasks/mailglass.publish.check.ex`) is the disposition record. VULN-04 formalizes the cadence that revisits it; it does not need a new record format. |
| **CI treats "transitive" as a first-class advisory source, not an edge case** | `mix hex.audit` (Hex registry retirements/advisories) and `mix deps.audit` (mix_audit / GitHub Advisory DB) already both run in `ci.yml` and *both* cover transitive deps by construction — `mix.lock` has no direct/transitive distinction, the audit tools scan the whole resolved graph. The gap this milestone is closing is not "add transitive scanning" (it already exists) but "make the scheduled/triage **process** explicitly say transitive deps are in scope," because the human failure mode was reading only the dependabot PR list (which is direct-only) and treating that as the audit. | LOW | Documentation + cadence fix, not a tooling gap. Cheapest, highest-leverage item in VULN. |
| **A required check that actually fires on every PR it's supposed to gate, with a set-equality meta-test proving it** | This is the exact class of bug (id vs. display-name mismatch) that opened this milestone. The pattern that prevents recurrence is not "be more careful" — it's an executable meta-test that parses the workflow YAML and asserts required-context strings are byte-identical to what the job actually reports, run on every change to the workflow or the script. | LOW-MEDIUM | Already exists as the pattern: `test/scripts/required_checks_test.exs` (GATE-03) does this for the 5 required lanes. TRUTH-03's "regression guard" is the same pattern applied specifically to the `guard-release-trigger` id/name distinction that caused the incident — likely a small addition to the existing meta-test rather than a new one. |
| **A read-only scheduled comparison of live branch protection against a checked-in expected-config generator** | `scripts/setup_branch_protection.sh --print-expected-json` already exists and is the canonical expected-state generator; the gap is a *scheduled, PAT-gated* job that fetches live settings and diffs them, on a cadence independent of any human remembering to check. | LOW | `branch-protection-drift.yml` already exists and already runs daily — **but it's actually the apply workflow** ("Branch Protection Apply" / `reassert-protection` job), not a read-only drift *detector*. It writes protection when a PAT is present; it does not compare-and-report when one isn't (`if: steps.check-pat.outputs.pat_present == 'true'` skips both checkout and the actual verification step, and the job still reports `success` because nothing failed — this is TRUTH-02's exact bug, read directly from the file). TRUTH-03 needs an actual **comparison** step whose absence of a PAT still produces a non-success conclusion (`neutral` at minimum), not a silently-skipped step inside an always-green job. |
| **Skipped ≠ green for any check whose entire job is "verify something."** | A verification job that no-ops when its precondition (PAT, credential, network) is missing must not report the same conclusion as "I checked and it's fine." This is general CI hygiene, not Elixir-specific — GitHub's own guidance on required checks explicitly warns about checks that silently pass when path-filtered or skipped becoming permanently-green traps. | LOW | Mechanical fix: replace the `if:`-guarded skip with a job that always runs a comparison step, and have that step explicitly `exit 1` (or use `::warning::` + a distinguishable `neutral` conclusion) when it cannot obtain the PAT, rather than omitting the step and returning `success` by default. |
| **`repo-hygiene` distinguishing "I checked and it's broken" from "I couldn't check"** | Same class of bug as TRUTH-02, one level down: `repo-hygiene.yml`'s hygiene check currently reports a 403 (no admin-scoped token in that job's `GH_TOKEN`) as "drift," which is a false positive that trains the maintainer to ignore the signal — the opposite of the trust this milestone restores. | LOW-MEDIUM | `repo-hygiene.yml` already uses `secrets.RELEASE_HYGIENE_PAT \|\| secrets.GITHUB_TOKEN` — the `GITHUB_TOKEN` fallback almost certainly cannot read branch-protection settings (needs admin:repo-scoped), so its `branch_protection` sub-check 403s whenever the PAT secret is absent/rotated, and today that 403 gets bucketed as the same "drift" status as a real live-vs-expected mismatch. Needs a distinct status value (e.g. `unchecked`/`inconclusive`) for the auth-failure case. |
| **Fail-closed detection of a referenced-but-unvendored icon (or any static asset the runtime resolves by name at render time)** | "Renders invisible, nothing catches it" is a known class of defect anywhere a template references an asset by string key resolved outside the type system (icon fonts, image sprites, i18n keys). The industry answer is always the same shape: statically enumerate every reference, statically enumerate every vendored asset, diff, fail the build on any reference with no matching asset. mailglass already has two other instances of exactly this pattern (`PRIMITIVE-DRIFT-GATE`, `FORM-DRIFT-GATE` in `check-conformance.sh`) — CONFORM-02 is the same shape applied to the icon name space specifically. | LOW-MEDIUM | Fully mechanical once scoped correctly. `<.icon name="hero-X">` call sites are greppable (`grep -rEn 'hero-[a-z0-9-]+'` across `.ex`/`.heex`), and the vendored set is the `icons` object key list inside `mailglass_admin/assets/vendor/heroicons-inline.js` (23 keys today, confirmed by direct read). The two prior misses (`hero-check`, `hero-information-circle`) happened because nothing diffed those two lists; the fix is a diff, not new tooling. **Edge case to scope explicitly:** dynamic icon names built from data (`<.icon name={@icon} class=...>`, `<.icon name={option.icon} .../>`, `<.icon name={stat_severity_icon(@severity)} />` — all present in `components.ex`) are not string-literal-greppable; the gate must either (a) statically resolve every `defp ..._icon(...)` clause's literal return values as the effective reference set, or (b) accept that dynamic sites need a runtime assertion / test-time enumeration instead of a pure grep, and say so explicitly rather than silently under-covering them (which is exactly how the original two icons slipped through — they may have been literal, but the fix must not repeat the "looked static, wasn't fully" mistake). |
| **CI lane names that describe what actually fails them** | A required/advisory lane's `name:` is the *only* signal a maintainer sees in the PR checks list and in Slack/email notifications; if the name says "Credo Strict" and the job also runs three shell gates plus Credo, a red run reads as "lint failed" and gets deprioritized for weeks — this repo's own post-mortem for CONFORM-04. The naming convention already used elsewhere in this file (`Support Contract Core`, `Trust Lane Repo Head`, `Compile No Optional Deps`) is descriptive-of-content, not descriptive-of-one-underlying-tool — CONFORM-04 is aligning one straggler lane to the convention every other lane already follows. | LOW | Rename `credo_strict`/`"Credo Strict (...)"` to something that names the composite (e.g. `"Lint & Conformance (...)"` or split into a separate job so Credo and conformance report independently — see Feature Dependencies below for the tradeoff). Touches `ci.yml` `name:`, `Mailglass.CILanes.@advisory_lanes_ci`, `MAINTAINING.md`'s advisory list, and any other literal string match (verified: `test/support/ci_lanes.ex` is the only other place the literal string is declared as a lane identity — no branch-protection dependency since it's advisory, not required). |

### Differentiators (above what peer OSS repos bother with)

| Feature | Value Proposition | Complexity | Notes |
|---------|--------------------|------------|-------|
| **Staleness-checked security allowlist (OSV re-query on every audit run)** | Of the 10 flagship Elixir repos surveyed in `CICD-RELEASE-HARDENING.md`, only Ash runs any in-CI security scanning at all, and none of them auto-expire an accepted-advisory allowlist entry against upstream fix status. A check that queries OSV (or re-runs `hex.audit`/`deps.audit` and diffs) for each `@accepted_advisories` entry and fails loudly when a `fixed` event now exists turns "remember to revisit" into an enforced gate — this is explicitly recommended in `CICD-RELEASE-HARDENING.md` §4.3 and not yet built. | MEDIUM | Real complexity: needs network access to OSV (or re-parsing `hex.audit` output for the specific advisory id), a fail-open posture on OSV outage (a third-party blip must never block a security *patch* — already a locked principle in this repo per LD-4), and a decision on where it runs (advisory CI step, `publish.check`, or both). This is genuinely differentiated work, not mechanical — flag for its own requirement, don't fold it silently into VULN-03. |
| **Time-boxed / dated allowlist entries with an enforced max-age** | Complements the above: an entry with an "Accepted 2026-06-30" comment is *documentation* of intent; a test asserting no entry is older than N days without a re-affirmation date is *enforcement* of the cadence VULN-04 is establishing. Belt-and-suspenders with the OSV staleness check — catches the case where OSV has no `fixed` event yet but a human should still eyeball it periodically (e.g., a vendor advisory feed lag). | LOW-MEDIUM | A single Elixir test (`Enum.each(@accepted_advisories, fn {id, _} -> assert age_days(id) < 180 end)`) reading dated comments or a small `%{id => accepted_on: ~D[...]}` structure instead of a bare reason string. Cheap once the disposition-record shape (table stakes, above) exists — this differentiator is really "the disposition record, made self-enforcing." |
| **A single Elixir-side source of truth for advisory-lane identity, mirroring what already exists for required lanes** | `Mailglass.CILanes` already solved this exact problem for required-vs-advisory *identity* (GATE-03/MIXCI-03 meta-tests). TRUTH-05's "every lane gets a recorded disposition" and TRUTH-07's "reconcile the three definitions of advisory" (10 in `ci_lanes.ex`, 2-pattern-matched in `publish-hex.yml`'s `ADVISORY_LANES` + regex, 11 in `MAINTAINING.md`) point at the same root cause `CILanes` was built to prevent: multiple hand-maintained copies of the same classification drifting apart. Extending `CILanes` (or a parallel `disposition/0` map: `%{lane => :required \| :promoted \| :kept_with_reason \| :retired}`) with a meta-test that the YAML/MAINTAINING.md copies agree is the differentiated move — most peer repos don't have even one source of truth for this, let alone reconcile three. | MEDIUM | This is the most structurally interesting item in TRUTH. It's not pure documentation — it needs a data shape that can express "kept advisory, here's why" distinctly from "just hasn't been looked at," and a meta-test enforcing agreement across `ci_lanes.ex`, `publish-hex.yml`'s `ADVISORY_LANES`/regex classifier, and `MAINTAINING.md`'s prose list. Real but bounded design work — not a topology rewrite (no lane moves, no new workflow files required). |
| **Gating an audit lane while an already-known, currently-unfixable advisory is allowlisted** | Most projects either (a) never gate on audit at all (9/10 flagship repos), or (b) gate and then get blocked indefinitely by exactly this scenario, which is why they don't gate. Doing both — gate AND keep shipping through a documented, expiring exception — is the differentiated combination this milestone is aiming for, and it is *only* safe with the staleness-check + disposition-record + severity-threshold pieces above all present. Attempting VULN-03 without them reproduces the "an unfixable transitive CVE reds every open PR" outage `SYNTHESIS.md` LD-4 already named as the failure mode to avoid. | — (rolls up the above) | See Feature Dependencies — this is a composite, not a standalone unit. |

### Anti-Features (would look right for this milestone but aren't)

| Feature | Why it looks appealing here | Why problematic | Alternative |
|---------|-------------------------------|------------------|--------------|
| **Auto-remediation / auto-merge for dependency PRs** | "If VULN-03 gates on audit, why not also auto-merge the fix?" feels like a natural next step while touching the same code. | This is exactly the failure mode that created VULN-02's backlog: 13 dependabot PRs were left with auto-merge enabled and silently stuck behind the branch-protection bug for 24 days, invisible because nothing was watching them. Auto-merge on security PRs needs the exact signal-integrity guarantees this milestone is *building*, not consuming before they exist. Sequencing violation, not a wrong idea per se. | VULN-02 disposition the existing backlog by hand this milestone; revisit auto-merge policy only after TRUTH's lane-truth work is proven, and only as an explicit future decision, not a side effect of VULN-03. |
| **Reducing audit/matrix scope, parallelizing lanes, or shrinking wall-clock as part of "making the gate practical"** | Promoting Hex Audit to required (VULN-03) and adding scheduled runs (VULN-04) both touch workflow YAML, which invites "while I'm in here, let's speed this up too." | This is explicitly SEED-006's charter, and the milestone's own non-goal states it directly: "Optimizing a pipeline whose greens are not trustworthy just makes it lie faster." Any change whose primary justification is speed/cost rather than correctness belongs to SEED-006, sequenced *after* this milestone by design. | Land the correctness fix with whatever wall-clock cost it has; log a SEED-006 candidate note if a specific slowness is discovered, don't fix it here. |
| **A new consolidated CI workflow / merging lanes into fewer jobs** | CONFORM-04's rename touches `credo_strict`; TRUTH-07's reconciliation touches lane classification; it would be easy to "clean up" by merging or restructuring jobs while already editing `ci.yml`. | Explicit locked non-goal: "No CI topology rewrite... the lane structure is sound; only the honesty of its signals changes." Splitting `credo_strict` into two jobs (Credo vs. conformance) is a **defensible micro-exception** worth flagging as a decision point (see below) but merging/restructuring beyond single-lane renames is out of scope. | Rename in place, or split exactly one job into two if that's the cleanest way to make names honest — do not restructure the broader job graph, `needs:` chains, or matrix shape. |
| **Building a general-purpose "asset existence" framework/DSL for the icon check** | CONFORM-02 says "close the invisible-icon class permanently, not just the two instances" — that phrasing invites over-engineering into a generic pluggable asset-registry system. | The actual defect class is narrow (one Tailwind plugin, one fixed icon set, one call-site pattern) and peer-repo precedent (this repo's own `PRIMITIVE-DRIFT-GATE`/`FORM-DRIFT-GATE`) is a plain grep-and-diff shell gate, not a framework. A framework adds surface area and a new abstraction to maintain for a problem that's fully solved by one more section in an existing 599-line shell script. | Add one more gate section to `check-conformance.sh` (or a sibling script if it needs Elixir-side static analysis for the dynamic-icon-name edge case) using the same pattern as the existing gates. |
| **Retroactive vulnerability disclosure / CVE-filing process for the already-patched `hpax`/cowlib/etc. advisories** | VULN-04's cadence work naturally raises "should we have filed something, notified users, etc. for the 24-day window." | Out of scope for this milestone by its own framing (trust-restoration of *signals*, not incident-response/PR work) and not implied by any REQ-ID in the scope doc. Conflating it in would expand VULN into disclosure/communications territory nobody asked for. | If warranted, that's a separate decision for the maintainer outside GSD phase scope — do not fold into VULN-03/04. |

---

## Feature Dependencies

```
VULN-04 (documented triage cadence, incl. transitive)
    └──produces the disposition-record convention that──> VULN-03 (promote Hex Audit to gating)
                                                                 └──requires──> staleness-checked
                                                                                 allowlist (differentiator)
                                                                 └──requires──> CI-side allowlist wired
                                                                                 into the `hex_audit` job
                                                                                 (currently bare `mix hex.audit`,
                                                                                 NO allowlist honoring —
                                                                                 gating it as-is would red on
                                                                                 the already-accepted cowlib
                                                                                 advisories immediately)

TRUTH-05 (every advisory lane gets a disposition)
    └──requires──> TRUTH-07 (reconcile the 3 definitions of "advisory":
                              ci_lanes.ex=10, publish-hex.yml ADVISORY_LANES=2+regex,
                              MAINTAINING.md prose=11 — they must agree on ONE list
                              before a disposition can be recorded against it)

TRUTH-02 (skipped ≠ green)
    └──blocks──> TRUTH-03 (scheduled drift verification + regression guard)
                     (today's branch-protection-drift.yml IS the TRUTH-02 bug: it's an
                     apply-workflow that silently no-ops-and-reports-success with no PAT;
                     TRUTH-03 needs an actual compare step that inherits the TRUTH-02 fix,
                     not a second workflow bolted alongside the buggy one)

TRUTH-06 (repo-hygiene: blocked vs cannot-check)
    ──same root pattern as──> TRUTH-02 (a check's "I couldn't verify" state must never
                                          collapse into the same status as "verified: fine")

CONFORM-04 (rename the misleading lane)
    └──should land before or atomic-with──> CONFORM-02 (new build-time icon gate)
        (adding a NEW hard-fail gate to a job still named "Credo Strict" repeats the exact
        mistake this phase exists to fix — a maintainer scanning PR checks for "did the new
        icon gate run" won't find it under that name)

Icon existence gate (CONFORM-02) ──conflicts-if-naive-with──> dynamic icon name call sites
    (`<.icon name={@icon}>`, `name={option.icon}`, `name={stat_severity_icon(@severity)}`)
        (a pure string-literal grep under-covers these; must either statically resolve
        `defp ..._icon/1` return clauses or explicitly document the gap — see Table Stakes)
```

### Dependency Notes

- **VULN-04 must land conceptually before VULN-03 is *safe*, even if phases execute in the
  written order.** The cadence doc defines what "disposition" means (promote / keep-with-reason /
  retire) and what counts as an acceptable exception; VULN-03's gating logic needs that vocabulary
  to know what to do when a new HIGH lands with no fix. Sequencing them the other way risks gating
  first and inventing the exception process under pressure during the next real advisory — which
  is close to what already happened once (cowlib).
- **VULN-03 is not just "add `hex_audit` to `ci_green.needs`."** The `hex_audit` job in `ci.yml`
  today runs bare `mix hex.audit` with zero allowlist logic, while `mailglass.publish.check.ex`'s
  `@accepted_advisories` allowlist only applies at the *publish* gate. If VULN-03 promotes the
  CI-side lane to required without also wiring the same (or an equivalent) allowlist into it, the
  lane will immediately and permanently red on the still-open cowlib advisories the moment it's
  promoted — self-inflicting the exact "unfixable CVE reds every PR" outage `SYNTHESIS.md` LD-4
  was written to prevent. The allowlist logic needs a shared home (extract from `publish.check`
  into a module both the CI step and the publish gate call, or have the CI step shell out through
  the same mix task in check-only mode) — this is real design surface, not a one-line `needs:` edit.
- **TRUTH-02 and TRUTH-06 are the same bug pattern in two different files.** Fixing the pattern
  once (a `verified | drift | unchecked` tri-state instead of a `success | failure` binary, with
  "unchecked" never rendering as a green check) and applying it to both
  `branch-protection-drift.yml` and `repo-hygiene.yml`'s `branch_protection` sub-check is cheaper
  and more consistent than two bespoke fixes.
- **TRUTH-03 does not need a new workflow file.** `branch-protection-drift.yml` already runs daily
  and already calls `scripts/setup_branch_protection.sh`, which already has a
  `--print-expected-json` mode built for exactly this comparison. The gap is that the existing
  workflow *applies* protection (when a PAT exists) rather than *comparing and reporting drift*
  (when it doesn't) — TRUTH-03 is adding the read-only compare path to (or alongside) the existing
  job, not standing up new infrastructure. Read closely, this may even be a rename/refocus of the
  existing workflow rather than an addition — a phase-planning decision, not a research one.
- **CONFORM-04 and CONFORM-02 should land together or CONFORM-04 first.** Adding new gate logic to
  a mislabeled job just grows the mislabeling problem the phase exists to fix.
- **The `credo_strict` job split is the one place a *narrow* structural change (splitting one job
  into two) is defensible without violating the "no CI topology rewrite" lock** — it's a rename +
  one job boundary, not a redesign of triggers, matrix, or `needs:` graph. Flag this as an explicit
  phase-143 decision point rather than assuming rename-in-place is always sufficient: if Credo and
  conformance failures need genuinely independent signals (e.g., so `gate-self-test.yml` or a future
  required-lane promotion can target them separately), splitting is the more honest fix; if they'll
  always be looked at together, a rename alone is simpler and lower-risk. Either way it must be
  reflected consistently in `ci.yml`, `Mailglass.CILanes`, and `MAINTAINING.md`'s advisory list.

---

## MVP Definition

Framed as "what closes the remaining v2.2 scope" rather than a product MVP — there is no v1.x/v2+
staging here, this milestone either lands the remaining REQ-IDs or it doesn't. Grouped by
complexity/risk instead, to inform phase sequencing.

### Mechanical / low-risk (do first, unlocks everything else)

- [ ] VULN-04 cadence doc (table stakes, pure documentation) — defines vocabulary VULN-03 needs
- [ ] TRUTH-07 reconcile the 3 advisory-lane definitions into one (table stakes) — defines the set
      TRUTH-05 dispositions
- [ ] CONFORM-04 rename the misleading lane (table stakes) — should precede CONFORM-02
- [ ] TRUTH-02 fix skip-reports-green in the branch-protection workflow (table stakes)
- [ ] TRUTH-06 repo-hygiene blocked-vs-cannot-check distinction (table stakes) — same fix pattern
      as TRUTH-02

### Requires real design surface (do after the above)

- [ ] VULN-03 promote Hex Audit to gating, WITH the shared allowlist wired into the CI-side lane
      (table stakes + differentiator combo — do not ship the gate without the allowlist wiring)
- [ ] CONFORM-02 build-time icon-existence gate, explicitly scoping the dynamic-name call sites
      (table stakes, mechanical for literals, needs a real decision for the 4 dynamic call sites)
- [ ] TRUTH-03 scheduled drift verification + regression guard (table stakes, depends on TRUTH-02
      landing first so the comparison step it adds isn't laundered through the same bug)
- [ ] TRUTH-05 every advisory lane gets a recorded disposition (table stakes, depends on TRUTH-07)

### Genuinely differentiated, higher complexity — scope carefully

- [ ] OSV staleness re-check for allowlisted advisories (differentiator, MEDIUM complexity, needs
      fail-open-on-outage design)
- [ ] Dated/max-age enforcement on allowlist entries (differentiator, LOW-MEDIUM, cheap once the
      disposition record shape exists)

### Explicitly not this milestone

- [ ] Auto-remediation / auto-merge policy changes (anti-feature — sequencing violation)
- [ ] Any wall-clock/cost/matrix-shrinking change (anti-feature — SEED-006)
- [ ] Generalized asset-existence framework (anti-feature — over-engineering the icon fix)
- [ ] Job-graph/trigger topology restructuring beyond the one defensible `credo_strict` split
      (anti-feature — locked non-goal)

---

## Feature Prioritization Matrix

| Feature | Trust-Restoration Value | Implementation Cost | Priority |
|---------|--------------------------|----------------------|----------|
| VULN-04 triage cadence doc | HIGH | LOW | P1 |
| TRUTH-07 reconcile advisory definitions | HIGH | LOW-MEDIUM | P1 |
| TRUTH-02 skip≠green fix | HIGH | LOW | P1 |
| TRUTH-06 repo-hygiene blocked-vs-cannot-check | MEDIUM | LOW-MEDIUM | P1 |
| CONFORM-04 lane rename | MEDIUM | LOW | P1 |
| VULN-03 promote Hex Audit + allowlist wiring | HIGH | MEDIUM | P1 |
| CONFORM-02 icon existence gate (literals) | HIGH | LOW-MEDIUM | P1 |
| CONFORM-02 icon existence gate (dynamic call sites) | MEDIUM | MEDIUM | P2 |
| TRUTH-03 scheduled drift + regression guard | HIGH | LOW-MEDIUM | P1 |
| TRUTH-05 lane disposition recording | MEDIUM | MEDIUM | P1 |
| OSV staleness re-check | MEDIUM | MEDIUM | P2 |
| Dated allowlist max-age enforcement | LOW-MEDIUM | LOW-MEDIUM | P2 |
| TRUTH-04 release-trigger anti-recursion (fix or accept) | MEDIUM | LOW (if "formally accept") / MEDIUM (if "fix") | P1 (decision), P2 (fix) |
| TRUTH-08 self-racing publish fan-out | LOW-MEDIUM | LOW | P2 |

**Priority key:** P1 = needed to satisfy the phase's REQ-IDs as scoped; P2 = strengthens the
milestone but is a legitimate cut-line if time is tight (differentiator-tier or lower-severity
truth items).

---

## Precedent Analysis (how peer/mature OSS repos handle each capability)

| Capability | Flagship Elixir repos (Phoenix/Ecto/Ash/Oban/Bandit/etc., per `CICD-RELEASE-HARDENING.md`) | GitHub-ecosystem general practice | mailglass's approach |
|---|---|---|---|
| Scheduled vuln audit | Only Ash runs in-CI scanning (hex.audit + mix_audit + sobelow + Scorecard) at all; none surveyed run it specifically on a `schedule:` trigger independent of PR/push | Dependabot alerts + a documented severity SLA (24h critical-triage / 72h-patch is the pattern GitHub's own blog and community writeups converge on) is the dominant shape | Add `schedule:` to existing `hex_audit`/`deps_audit_advisory` jobs; write the VULN-04 SLA doc alongside the existing inbound-report SLA already in `MAINTAINING.md` |
| Gating audit lane w/ unfixable advisory | 9/10 don't gate on audit at all, precisely to avoid this trap; Ash is the outlier and its allowlist lifecycle isn't public in the research | Standard pattern: severity threshold + time-boxed/expiring allowlist entries + documented exception, never a bare "ignore forever" list | Extend the existing `@accepted_advisories` disposition-record pattern with staleness re-checks; wire the same allowlist into the CI-side `hex_audit` lane before promoting it |
| Advisory-lane disposition discipline | No surveyed repo has an explicit "every advisory lane must be promoted/kept/retired" policy — most just accumulate advisory lanes indefinitely | N/A — this is closer to internal engineering-org practice (error-budget / SLO review cadences) than an OSS convention | `Mailglass.CILanes` already solved lane-identity truth for required lanes; extend the same seam to carry disposition, backed by a meta-test reconciling the 3 existing copies |
| Icon/asset existence at build time | Not surveyed directly (none of the 10 repos ship a LiveView admin UI with a name-keyed icon plugin), but the general "referenced-key vs. registered-key diff, fail closed" pattern is standard in i18n-key-checking and sprite-checking tooling across ecosystems | Framework-agnostic convention: static grep/AST enumeration of references, diff against the registered set, fail the build — never a runtime-only check for something resolvable at compile/build time | Same shape as this repo's own `PRIMITIVE-DRIFT-GATE`/`FORM-DRIFT-GATE` in `check-conformance.sh` — extend the existing script, don't build new tooling |
| Branch-protection drift detection | Not a surveyed pattern in the 10-repo set (none manage 3 linked sibling packages with the same required-context fragility) | GitHub's own required-status-check troubleshooting docs warn explicitly about checks that silently pass when skipped/path-filtered becoming permanently-green traps — the exact TRUTH-02 bug | `scripts/setup_branch_protection.sh --print-expected-json` already exists as the expected-state generator; `branch-protection-drift.yml` already runs daily but needs its skip-path fixed to a real compare-and-report |
| CI lane naming discipline | 7/10 flagship repos name jobs by matrix dimension (`test / elixir 1.19 / otp 28`) rather than by tool; none surveyed name a job after one tool while running a different tool's failure inside it | General convention: a required/advisory check's display name is the only signal surfaced in the PR UI and notification emails — name it for what it verifies, not for the first tool historically added to the job | Every other mailglass lane (`Support Contract Core`, `Trust Lane Repo Head`, `Compile No Optional Deps`) already follows content-describing naming; `credo_strict` is the sole straggler |

---

## Sources

- Repo-primary (HIGH confidence, read directly 2026-07-28):
  `.github/workflows/ci.yml`, `.github/workflows/publish-hex.yml`,
  `.github/workflows/branch-protection-drift.yml`, `.github/workflows/repo-hygiene.yml`,
  `.github/workflows/guard-release-trigger.yml`, `.github/workflows/advisory-matrix.yml`,
  `test/support/ci_lanes.ex`, `MAINTAINING.md`, `lib/mix/tasks/mailglass.publish.check.ex`,
  `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/lib/mailglass_admin/components.ex`,
  `mailglass_admin/assets/vendor/heroicons-inline.js`
- Milestone/prior-research (HIGH confidence, project-authored):
  `.planning/PROJECT.md` (v2.2 section), `.planning/research/v2.2/MILESTONE-SCOPE.md`,
  `.planning/seeds/SEED-006-ci-cd-efficiency-audit.md`,
  `.planning/research/milestone-cicd/SYNTHESIS.md`,
  `.planning/research/milestone-cicd/CICD-RELEASE-HARDENING.md`
- Ecosystem/general-practice (MEDIUM-HIGH confidence, web-verified 2026-07-28):
  - [5 tips for prioritizing Dependabot alerts — The GitHub Blog](https://github.blog/security/supply-chain-security/5-tips-for-prioritizing-dependabot-alerts/)
  - [16 Best Practices for Reducing Dependabot Noise — Andrew Nesbitt](https://nesbitt.io/2026/01/10/16-best-practices-for-reducing-dependabot-noise.html)
  - [Dependency cooldowns: a simple supply chain fix](https://christian-schneider.net/blog/dependency-cooldowns-supply-chain-defense/)
  - [Dependabot user-defined rules for security updates — GitHub Changelog](https://github.blog/changelog/2023-10-26-dependabot-user-defined-rules-for-security-updates-and-alerts-enforcement-of-auto-triage-rules-and-presets-for-organizations-public-beta/)
  - [Troubleshooting required status checks — GitHub Docs](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks)
  - [How to Configure Status Checks in GitHub Actions — OneUptime](https://oneuptime.com/blog/post/2026-01-26-status-checks-github-actions/view)

---
*Feature research for: mailglass v2.2 CI Signal Integrity & Supply-Chain Hygiene*
*Researched: 2026-07-28*
