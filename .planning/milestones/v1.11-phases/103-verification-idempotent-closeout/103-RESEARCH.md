# Phase 103: Verification + Idempotent Closeout - Research

**Researched:** 2026-06-16
**Domain:** Closeout verification / idempotent quality-ratchet activation / prepare-only release ceremony (Elixir/Phoenix, zero-Node-toolchain admin lib)
**Confidence:** HIGH (all line-number/file-shape claims verified against live code this session)

## Summary

Phase 103 is a verification-and-closeout gate, not a build phase. The 15 binding decisions in
`103-CONTEXT.md` (D-01..D-15) are research-backed and locked; this research confirms the live-code
reality each decision rests on and surfaces the exact file shapes, line numbers, command
invocations, gate wiring, and ordering hazards a planner needs to execute them verifiably. **Every
GAP-fix citation, every test-file line number, and every release-config claim in CONTEXT was
verified against the working tree and holds** — with two discrepancies worth the planner's
attention (both are CONTEXT being *more correct* than stale docs, not errors).

The phase has four mechanical work products: (1) restructure `ui-baseline-scores.json` to
schema_version 2 `{prior, current}` and activate `compare_baselines/2` + an anti-vacuity run_id
guard in `ratchet_baseline_test.exs` (a pure ADD — three edits, no rewrite of the comparator);
(2) flip six GAP rows (GAP-01/04/06/07/08/09) from `open`→`fixed` against verified-present live
code, preserving `first_seen_run`; (3) confirm the full gate battery green (token-parity,
two conformance scripts + the root motion gate, Playwright structural, the now-armed LLM-score
floor, bundle-clean); (4) write a prepare-only release readiness note that changes nothing Release
Please owns, then regenerate the milestone audit LAST.

**Primary recommendation:** Execute strictly in the D-15 order (reconcile GAP register → activate
ratchet + fresh re-score → all-gates verification → prepare-only readiness note → regenerate audit
last). The single highest-leverage correctness control is the D-04 anti-vacuity guard: without
`assert b["prior"]["run_id"] != b["current"]["run_id"]`, a forgotten promotion makes the entire
36-cell ratchet a trivial self-comparison that passes green while proving nothing — exactly the
vacuous gate Phase 95 D-05 forbids.

<user_constraints>
## User Constraints (from 103-CONTEXT.md)

### Locked Decisions (D-01..D-15 — verbatim intent, binding; do NOT re-litigate)

**Score-Baseline Persistence & Meet-or-Beat Activation (RATCHET-01)**
- **D-01:** Restructure `mailglass_admin/docs/ui-baseline-scores.json` into a single file with two
  keyed blocks — `prior` (frozen floor) and `current` (latest measured run) — each carrying its own
  `run_id` + `surfaces` map. Bump `schema_version` 1 → 2 and update the `schema_version == 1`
  assertion in `ratchet_baseline_test.exs:46`.
- **D-02:** Migrate existing flat scores (run_id `2026-06-13-phase-95-baseline`) into the `prior`
  block unchanged. The Phase 103 **fresh re-run + re-score** populates `current` with a new
  `run_id: 2026-06-16-phase-103`. (User locked "fresh re-run + re-score" — preview Motion+A11y at
  2/2 should rise after 100/101/102; the re-score is real, not a re-affirmation.)
- **D-03:** Activate the only-forward ratchet by replacing the `if false, do:
  compare_baselines(%{}, %{})` guard at `ratchet_baseline_test.exs:40` with a real call site:
  `compare_baselines(b["prior"], b["current"])`. Pure ADD per Phase 95 D-05 — do NOT rewrite
  `compare_baselines/2` (lines 87-104).
- **D-04:** Add an **anti-vacuity guard**: assert `b["prior"]["run_id"] != b["current"]["run_id"]`.
- **D-05:** REJECTED — `git show HEAD:.../ui-baseline-scores.json` as the prior source. Unsafe
  (`.git` not in Hex tarball; zero-process-dep DNA). Commit the baseline as a reviewable file.
- **D-06:** Document the **promotion step** (copy previous `current` → `prior`, write fresh
  `current`) in the register's "Seed Run Procedure".

**GAP Register Reconciliation (RATCHET-02)**
- **D-07:** Close open rows by **verify-already-fixed-and-flip** (`open → fixed`): re-run audit,
  confirm finding ABSENT in *live code*, flip status, stamp `run_id: 2026-06-16-phase-103`,
  **preserve `first_seen_run`**. No new fix code.
- **D-08:** Per-row close calls (all `fixed`, each with a proving citation):
  - GAP-06 (sev-4) → fixed — `operator_live.ex:409` (`md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]`)
  - GAP-07 (sev-3) → fixed — `operator_live.ex:419` (`text-label uppercase font-bold text-secondary`; zero `tracking-[`)
  - GAP-08 (sev-3) → fixed — `deliveries_list.ex:18,23` (`filters_active?` split + reset CTA)
  - GAP-09 (sev-3) → fixed — `operator_fixtures.ex` (`:suppressed` + `hours_ago(6/7)` rows)
  - GAP-01 (sev-3) → fixed — `support_cards.ex:56/102/152` (`min-h-11`; zero `btn-sm`)
  - GAP-04 (sev-2) → fixed — `inbound/filters_form.ex` (`text-label uppercase font-bold text-secondary`)
- **D-09:** Bright-line honesty: `status: fixed` REQUIRES absence in live code; `status: downgraded`
  is reserved for present-but-not-worth-fixing. **No downgrades this phase.**
- **D-10:** Trigger vs evidence: the stale `v1.11-MILESTONE-AUDIT.md` is only the *signal*; flip
  against live `component:line` + fresh PNG only.

**Release Prepare-Only + Milestone Audit (CLOSE)**
- **D-11:** "Prepare-only" = change **nothing** Release Please owns. Deliverable is a readiness note
  recording: linked group is `mailglass`+`mailglass_admin` (inbound independent); manifest left at
  `1.6.2/1.6.2/1.3.1`; `exclude-paths` still scopes core away from
  admin/inbound/brandbook/.planning/prompts (RELH-01 intact).
- **D-12:** A linked bump IS pending (not zero-change): v1.11 `feat:`/`fix:` on `mailglass_admin/`
  paths + linked-versions → Release Please will open a ~1.6.2 → 1.7.0 linked-group bump once armed.
- **D-13:** Record the inbound exact-pin re-pin as the single **pending** ceremony action — **do NOT
  perform it now**. Target core version is unknowable pre-PR; re-pin lands later as `fix(inbound):`
  post-bump.
- **D-14:** Regenerate the milestone audit **LAST**, via `gsd-audit-milestone`, only AFTER the GAP
  register is reconciled and the ratchet is activated.

**Closeout Ordering**
- **D-15:** reconcile GAP register → activate meet-or-beat ratchet (+ fresh re-score) → run
  all-gates verification → write prepare-only readiness note → **regenerate milestone audit last**.

### Claude's Discretion
- Exact schema_version 2 JSON layout (key ordering; whether `pillar_rubric`/`grade_scale` live at
  top level or per-block) — as long as D-01/D-04 hold.
- Whether the anti-vacuity `run_id` guard lives in `setup_all` or its own test.
- The DELIVERIES/INBOUND/PREVIEW re-score method (multimodal subagent vs structured manual review).

### Deferred Ideas (OUT OF SCOPE)
- The actual Hex publish (post-milestone decision, v1.7 precedent).
- The inbound `fix(inbound):` exact-pin re-pin to the new core version (lands later, post-PR).
</user_constraints>

<phase_requirements>
## Phase Requirements

No net-new requirement is anchored here. Phase 103 verifies all v1.11 REQ-IDs. The
closeout-relevant ones:

| ID | Description | Research Support |
|----|-------------|------------------|
| RATCHET-01 | Committed `component × pillar × theme` score baseline + meet-or-beat closeout assertion (only-forward) | `ui-baseline-scores.json` schema-2 restructure (D-01/02) + `compare_baselines/2` call-site activation (D-03) + anti-vacuity guard (D-04); comparator verified present at `ratchet_baseline_test.exs:87-104` |
| RATCHET-02 | One carried-forward GAP register, stable IDs, run_ids, reopen/skip idempotency, sev≥3 citation gate | Six GAP fixes verified present in live code; flip `open→fixed` preserving `first_seen_run` (D-07/08); idempotent semantics already documented in register |
| CLOSE (REQUIREMENTS.md "Release posture: prepare-only") | Stage the ceremony; decide real-cut later | Manifest/config verified untouched-and-correct; pending inbound re-pin deferred (D-11/12/13); audit regenerated last (D-14) |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Score-baseline persistence + meet-or-beat assertion | Test harness (ExUnit, `verify.support_contract.admin`) | Committed JSON file (`docs/`) | Pure `File`+`Jason` decode, fail-closed in a required CI lane — no process deps (matches Betterer/insta/jest-snapshot canon) |
| 18-cell PNG capture | Local/ad-hoc shell (`ui-audit.sh`) | reference/demo_app (data source) | Non-deterministic pixels keep it OUT of CI (D-07); evidence-only |
| Re-score (PNG → 36-cell grid) | Human/subagent judgment | committed JSON | Score grid (`surface × pillar × theme`) is intentionally a different keying than the PNG evidence grid (`surface × vp × theme`) |
| GAP register reconciliation | Planning artifact (`.planning/RATCHET-GAP-REGISTER.md`) | live `lib/` code (evidence) | Register is the citation anchor; flips must cite live `component:line`, never the stale audit |
| Gate confirmation | CI (`ci.yml` lanes) + local mix aliases | shell conformance scripts | All gates already wired; Phase 103 only re-confirms green |
| Release prepare-only | Release Please config/manifest (read-only) | readiness note (SUMMARY/STATE) | Humans never touch version numbers/CHANGELOG/manifest; conventional commits drive the bump |
| Milestone audit regeneration | `gsd-audit-milestone` skill | per-phase `*-VERIFICATION.md` | Skill reads VERIFICATION.md files and overwrites the audit; must run last |

## DISCREPANCIES (highest-value planner findings)

These are the deltas between what `103-CONTEXT.md` / stale docs claim and what live code shows.
In every case CONTEXT is correct; the stale artifacts are the trigger, not the evidence (D-10).

### DISC-1 — GAP-06/07 line numbers: CONTEXT (409/419) correct; register (397/404) STALE
`RATCHET-GAP-REGISTER.md` rows GAP-06 and GAP-07 still cite `operator_live.ex:397` and `:404`
respectively (the line numbers at first-seen in Phase 98). The fixes are now at **`409`** and
**`419`** [VERIFIED: grep of `lib/mailglass_admin/operator_live.ex` this session]. CONTEXT D-08
cites the correct current lines. **Planner action:** when flipping the rows, the planner may
update the `component:line` to the current line (this is a "last touch" field) OR leave it — but
the *flip evidence/citation* recorded must reference the verified current lines (409/419). This is
exactly the D-10 "trigger vs evidence" distinction made concrete: the register's own line numbers
are stale; do not treat them as evidence.

### DISC-2 — Inbound re-pin: v1.7/Phase-79 PERFORMED it; Phase-103/D-13 DEFERS it
The cited precedent `79-04-SUMMARY.md` *performed* the inbound exact-pin re-pin during its
prepare-only phase — it updated `mailglass_inbound/mix.exs` from `== 1.4.5` → `== 1.5.0` as a
`chore(79):` commit, because in v1.7 the target core version was already known/decided. Phase 103
D-13 **deliberately defers** the re-pin because the target core version is unknowable pre-PR (it's
whatever Release Please computes from the conventional commits). **This is not a contradiction — it
is a deliberate divergence from precedent, and the planner must NOT "follow the precedent" by
editing the pin.** The pin currently reads `{:mailglass, "== 1.6.2"}` at
`mailglass_inbound/mix.exs:127` [VERIFIED: read this session] and must stay untouched. Record the
re-pin as the single pending ceremony action only. (Footgun: a guessed pin desyncs the
reference/demo baseline — a coordinated 5-file change per the project's reference-baseline-coupling
memory.)

### DISC-3 — Stale milestone audit falsely reports 101/102/103 missing
`.planning/v1.11-MILESTONE-AUDIT.md` (dated 2026-06-15, status `gaps_found`) claims "no
`.planning/phases/101-*` directory exists", same for 102 and 103, and lists COPY-01/MOTION-01/
MOTION-02 as `unsatisfied`. **All false now:** phases 101 and 102 are complete WITH passing
`VERIFICATION.md` files [VERIFIED: `ls` this session — both present]. This staleness is precisely
why D-14 regenerates the audit LAST. The planner must NOT trust any number in the current audit
file; it is the trigger for reconciliation, never the basis for a flip (D-10).

### DISC-4 — Phase 103 has NO VERIFICATION.md yet (and the audit needs one)
`gsd-audit-milestone` reads per-phase `*-VERIFICATION.md` files. Phases 94-102 all have one;
Phase 103 does not yet [VERIFIED: glob returned zero matches]. The closeout must *produce* a
`103-*-VERIFICATION.md` (during execute/verify-work) **before** the audit is regenerated, or the
audit will re-report Phase 103 as "missing/not started" and stay `gaps_found`. This is an ordering
dependency the planner must encode: VERIFICATION.md for 103 exists → THEN regenerate audit.

## Live-Code Verification Results (proof the flips are honest)

All six GAP fixes confirmed PRESENT in the working tree this session — flips are honest, not
rubber-stamps:

| GAP | Claim (D-08) | Verified state | Verdict |
|-----|--------------|----------------|---------|
| GAP-06 | grid percentages replace `minmax(22rem,28rem)` | `operator_live.ex:409` = `class="mt-6 grid gap-lg md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]"`; no `minmax(` remains | FIXED ✓ |
| GAP-07 | `text-label uppercase font-bold text-secondary`; no `tracking-[` | `operator_live.ex:419` = `<h2 class="text-label uppercase font-bold text-secondary">`; `grep tracking-\[` returns NONE | FIXED ✓ |
| GAP-08 | `filters_active?` splits filtered/truly-empty + reset CTA | `deliveries_list.ex:12` `attr :filters_active?`; `:18` testid split `operator-empty-filtered`/`operator-empty-truly`; `:39` `operator-empty-reset` button | FIXED ✓ |
| GAP-09 | seeds `:suppressed` + `hours_ago(6/7)` reachable by URL | `operator_fixtures.ex`: `hours_ago(6)` at L128, `status: :suppressed` at L136, `browser-suppressed@example.com` | FIXED ✓ |
| GAP-01 | `min-h-11`, no `btn-sm` | `support_cards.ex:56/102/152` all `class="btn btn-primary px-md mt-sm min-h-11"`; `grep btn-sm` returns NONE | FIXED ✓ |
| GAP-04 | labels use token | `inbound/filters_form.ex:20/33/46/66/82` = `text-label uppercase font-bold text-secondary` | FIXED ✓ |

**Test-file anchors (CONTEXT line claims) all hold** [VERIFIED: read `ratchet_baseline_test.exs`]:
- Line 40: `if false, do: compare_baselines(%{}, %{})` — present, exact.
- Line 46: `assert b["schema_version"] == 1` — present, exact.
- Lines 87-104: `defp compare_baselines(prior, current)` — present; reads
  `get_in(prior, ["surfaces", surface, pillar, theme])` and asserts no `current < prior`. The
  function signature already expects `prior`/`current` maps each containing a `"surfaces"` key —
  so feeding it `b["prior"]` and `b["current"]` (each a block with its own `"surfaces"`) works
  with **zero changes to the function body**.
- Lines 51-81: the 36-cell shape/range tests read `get_in(b, ["surfaces", ...])` directly off the
  top-level decode. **HAZARD (see Pitfall 1):** after the schema-2 restructure, `"surfaces"` is no
  longer at top level — these three tests will break unless updated to read from a block.

## Standard Stack

No new packages. This phase is verification and uses only existing project tooling.

| Tool | Version | Purpose | Already present? |
|------|---------|---------|------------------|
| ExUnit | (Elixir 1.18 / OTP 27) | `ratchet_baseline_test.exs` fail-closed assertions | yes |
| Jason | (project dep) | decode `ui-baseline-scores.json` | yes (used at `ratchet_baseline_test.exs:42`) |
| Playwright | (admin `package.json`) | structural assertions, `--workers=1` | yes |
| `agent-browser` CLI | >=0.27 | `ui-audit.sh` PNG capture | local prereq (not CI) |
| Release Please | (GitHub Action) | linked-version bump (do not touch config) | yes |
| `gsd-audit-milestone` skill | installed at `~/.claude/skills/gsd-audit-milestone` | regenerate milestone audit | yes |

**Installation:** none.

## Package Legitimacy Audit

Not applicable — Phase 103 installs no external packages. (Per the protocol: a phase that installs
nothing skips this gate.)

## Architecture Patterns

### Closeout data-flow diagram

```
                          ┌──────────────────────────────────────────────┐
   D-15 ORDER →           │ STEP 1: Reconcile GAP register                │
                          │  live lib/ code  ──(verify ABSENT)──►          │
                          │  RATCHET-GAP-REGISTER.md: 6 rows open→fixed    │
                          │  preserve first_seen_run; stamp run_id 103     │
                          └───────────────────────┬──────────────────────┘
                                                  │ (register clean)
                          ┌───────────────────────▼──────────────────────┐
                          │ STEP 2: Activate ratchet + fresh re-score      │
                          │  ui-audit.sh ──18 PNGs──► re-score ──► 36 cells│
                          │  ui-baseline-scores.json:                      │
                          │    schema_version 1→2                          │
                          │    {prior: old flat run, current: new run}     │
                          │  ratchet_baseline_test.exs:                    │
                          │    L40  if false ──► compare_baselines(        │
                          │              b["prior"], b["current"])         │
                          │    L46  == 1 ──► == 2                           │
                          │    + anti-vacuity: prior.run_id != current.run_id
                          │    + fix L51-81 surfaces lookups (block-scoped) │
                          └───────────────────────┬──────────────────────┘
                                                  │ (test green locally)
                          ┌───────────────────────▼──────────────────────┐
                          │ STEP 3: All-gates verification (green)         │
                          │  token-parity · check-conformance.sh ·         │
                          │  check-conformance-advisory.sh ·               │
                          │  scripts/check_motion_conformance.sh ·         │
                          │  Playwright structural (--workers=1) ·         │
                          │  ratchet LLM-score floor (now armed) ·         │
                          │  git diff --exit-code priv/static/             │
                          └───────────────────────┬──────────────────────┘
                                                  │ (all green)
                          ┌───────────────────────▼──────────────────────┐
                          │ STEP 4: Prepare-only readiness note            │
                          │  verify (READ ONLY): manifest 1.6.2/1.6.2/     │
                          │   1.3.1 · linked group = core+admin · inbound  │
                          │   pin == 1.6.2 untouched · exclude-paths intact│
                          │  record pending re-pin as the ONE deferred step│
                          └───────────────────────┬──────────────────────┘
                                                  │
                          ┌───────────────────────▼──────────────────────┐
                          │ STEP 5 (LAST): write 103 VERIFICATION.md, then │
                          │  gsd-audit-milestone v1.11 ──overwrites──►     │
                          │  .planning/v1.11-MILESTONE-AUDIT.md (→ passed) │
                          └───────────────────────────────────────────────┘
```

### Pattern 1: schema_version 2 `{prior, current}` restructure (D-01/D-02)
**What:** One JSON file, two keyed blocks, each self-contained.
**When to use:** This phase only.
**Recommended shape** (Claude's-discretion layout — satisfies D-01/D-04 and minimizes test churn):

```json
{
  "schema_version": 2,
  "prior": {
    "run_id": "2026-06-13-phase-95-baseline",
    "surfaces": { "deliveries": { "Spacing": {"light":3,"dark":3}, ... }, ... }
  },
  "current": {
    "run_id": "2026-06-16-phase-103",
    "surfaces": { "deliveries": { ... }, ... }
  },
  "pillar_rubric": "design-system.md:104-121",
  "grade_scale": "1-4 (1=non-conformant, 2=significant-gaps, 3=mostly-conformant, 4=excellent)"
}
```
The `prior` block is the existing flat scores migrated **unchanged** (D-02). `pillar_rubric` /
grade_scale may live at top level (shown) or be duplicated per-block — planner's discretion.

### Pattern 2: pure-ADD comparator activation (D-03 — Phase 95 D-05 contract)
**What:** Three edits to `ratchet_baseline_test.exs`, never a rewrite of `compare_baselines/2`.
1. Line 40: `if false, do: compare_baselines(%{}, %{})` → call it for real. Because the comparator
   reads `["surfaces", ...]` off each operand, the live call is
   `compare_baselines(b["prior"], b["current"])`. Note `b` is the `:baseline` set in `setup_all`;
   the cleanest call site is its own test reading the `%{baseline: b}` context (the discretion D-04
   allows: own test or in `setup_all`).
2. Line 46: `assert b["schema_version"] == 1` → `== 2`.
3. Add the anti-vacuity assertion: `assert b["prior"]["run_id"] != b["current"]["run_id"]`.
4. **Required (not in CONTEXT, surfaced here):** update the 36-cell shape test (L51-63) and
   range test (L65-81) so their `get_in(b, ["surfaces", ...])` reads from a block (e.g. iterate
   `["prior","current"]` or read `b["current"]["surfaces"]`). See Pitfall 1.

### Pattern 3: GAP flip preserving `first_seen_run` (D-07)
**What:** For each of the six rows: `status: open → fixed`, `run_id → 2026-06-16-phase-103`,
`first_seen_run` UNCHANGED, append a "fixed in Phase NN — `component:line` <token>" note in the
`fix sketch`/status column (matching the format already used for the closed GAP-02/03/05 rows).
This is exactly how GAP-02/03/05 were already closed — copy that row idiom.

### Anti-Patterns to Avoid
- **Vacuous gate:** promoting `prior` = `current` verbatim (forgotten re-score) → 36-cell
  self-comparison passes meaninglessly. The D-04 guard is the mechanical defense; do not skip it.
- **Flip-to-fixed without live-code proof:** rubber-stamping off the stale audit (D-09/D-10 ban).
- **Editing the inbound pin / manifest / config:** Release Please owns them (D-11/13; DISC-2).
- **Rewriting `compare_baselines/2`:** Phase 95 D-05 forbids; it already works as-is.
- **Regenerating the audit before 103's VERIFICATION.md exists:** re-reports 103 missing (DISC-4).
- **Committing PNGs:** `tmp/` is gitignored (`mailglass_admin/.gitignore:11`); never commit, never
  write under `priv/static/` (would trip the bundle gate).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Only-forward score comparison | A new diff function | Existing `compare_baselines/2` (L87-104) | Already written, tested-by-construction; Phase 95 D-05 mandates ADD-only |
| Prior-baseline source | `git show HEAD:...` archaeology | Committed `prior` block in the same file | D-05 rejected git-self-diff (`.git` absent from Hex tarball; pure File+Jason DNA) |
| Milestone audit | Hand-written audit prose | `gsd-audit-milestone` skill | Reads VERIFICATION.md files, cross-references REQUIREMENTS/ROADMAP, spawns integration checker |
| Version bump / CHANGELOG / manifest | Hand-edits | Release Please (conventional commits) | Humans never touch these (CLAUDE.md; D-11) |
| PNG capture matrix | New screenshot script | `scripts/ui-audit.sh` as-is | Already captures the 18 cells incl. preview dark via `?theme=dark` (Phase 100) |

**Key insight:** Phase 103 is deliberately a thin activation layer. The apparatus was built in
Phases 94/95 and tightened in 94 (RATCHET-03); 103 only flips switches and confirms green. Every
temptation to "build" something is a signal to re-read the relevant D-decision.

## Runtime State Inventory

> This is a verification/closeout phase, not a rename/refactor. Included for the few state-bearing
> artifacts the planner must treat as data, not code.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `ui-baseline-scores.json` is a *committed data file* (ships in Hex tarball — `mix.exs:210` `files: ~w(... docs ...)`). The schema-2 restructure is a **data migration** of the file, plus a **code edit** to the test that reads it. | Both: migrate JSON (D-01/02) AND edit `ratchet_baseline_test.exs` (D-03) |
| Live service config | Release Please manifest `1.6.2/1.6.2/1.3.1` + `release-please-config.json` linked group — config Release Please owns; verify-only, never edit | None (read-only verification, D-11) |
| OS-registered state | None — verified by inspection (no Task Scheduler/launchd/cron in this phase). The CI lanes that run the gates are in `ci.yml`, already wired. | None |
| Secrets/env vars | `HEX_API_KEY` (Actions secret, already set) — not touched; `MIX_PUBLISH=true` toggles the inbound pin branch (`mailglass_inbound/mix.exs:126`) — not exercised in prepare-only | None |
| Build artifacts | `priv/static/` compiled bundle — must be clean (`git diff --exit-code priv/static/`). No markup changes in 103, so the bundle should already be clean from Phase 102's rebuild. | Re-confirm clean; rebuild only if a gate forces it (it should not) |

**Nothing found** in OS-registered state and secrets (beyond the read-only notes above) — verified
by inspection of `ci.yml`, `mix.exs`, and the release config this session.

## Common Pitfalls

### Pitfall 1: schema-2 restructure breaks the three existing 36-cell tests
**What goes wrong:** The shape test (L51-63) and range test (L65-81) read
`get_in(b, ["surfaces", surface, pillar, theme])` directly off the top-level decode. After D-01
moves `surfaces` under `prior`/`current`, those reads return `nil` → "Missing cells (36)" failure.
**Why it happens:** CONTEXT D-01/D-03 only mention bumping the `schema_version` assertion and
activating the comparator; it does not enumerate the two coverage tests that also dereference
`["surfaces"]`.
**How to avoid:** When restructuring, update L51-81 to validate the `current` block (and ideally
`prior` too). Simplest: change the comprehensions to read `get_in(b, [block, "surfaces", ...])`
iterating `block <- ["prior", "current"]`, or point them at `b["current"]["surfaces"]`. This is a
mechanical follow-on edit, not a comparator rewrite (still honors Phase 95 D-05).
**Warning signs:** `mix test test/mailglass_admin/ratchet_baseline_test.exs` fails with "Missing
cells (36)" or "schema_version" mismatch after the JSON edit.

### Pitfall 2: vacuous self-comparison passes green (the D-04 footgun)
**What goes wrong:** A forgotten re-score → `current` is a verbatim copy of `prior` (same run_id)
→ `compare_baselines` compares a block to itself → zero regressions → green, but proves nothing.
**How to avoid:** The D-04 `prior.run_id != current.run_id` assertion. Do not skip it — it is the
sole mechanical guard against the exact failure Phase 95 D-05 calls out.
**Warning signs:** `current.run_id == "2026-06-13-phase-95-baseline"` (the prior id) in the JSON.

### Pitfall 3: Playwright flakiness without `--workers=1`
**What goes wrong:** Structural assertions are order-/concurrency-sensitive against a single demo
app; parallel workers cause intermittent reds.
**How to avoid:** The `test:operator-browser` npm script already pins `--workers=1`
(`mailglass_admin/package.json:5`). Invoke gates via that script, not ad-hoc `playwright test`.
The stale audit even flags this: "Structural/browser gates are deterministic with --workers=1;
keep that serialization in mind for final closeout."
**Warning signs:** Intermittent structural reds that pass on re-run.

### Pitfall 4: regenerating the audit too early → it re-reports 103 missing (DISC-3/4)
**What goes wrong:** Running `gsd-audit-milestone` before the GAP register is reconciled, the
ratchet activated, AND `103-*-VERIFICATION.md` written → the audit re-reports the stale gaps and
stays `gaps_found`.
**How to avoid:** D-14/D-15: audit LAST, after register + ratchet + 103 VERIFICATION.md.
**Warning signs:** audit still lists GAP-06 open or Phase 103 "not started".

### Pitfall 5: editing the inbound pin to a guessed version (DISC-2)
**What goes wrong:** Following the v1.7/Phase-79 precedent and bumping `mailglass_inbound/mix.exs`
to a guessed `== 1.7.0` → desyncs the frozen reference/demo baseline (coordinated 5-file change),
and the real target is whatever Release Please computes (unknowable now).
**How to avoid:** D-13 — record the re-pin as pending; do NOT perform it. Leave `== 1.6.2`.
**Warning signs:** `mailglass_inbound/mix.exs` in the staged diff.

### Pitfall 6: voice_test "Oops" false-positive is dep-JS noise (known flake)
**What goes wrong:** `voice_test.exs` substring-matches "n**oops**" in inlined Phoenix dep JS
(`phoenix.mjs`) — a pre-existing failure that tracks the phoenix/LV version, unrelated to this
phase.
**How to avoid:** Exclude this specific pre-existing failure from the phase pass/fail judgment;
do not weaken the test. (From project memory `project_voice_test_noops_dep_js.md`.)
**Warning signs:** a `voice_test` red that mentions phoenix.mjs / inlined JS.

## Code Examples

### Activating the comparator (D-03) — the call site
```elixir
# ratchet_baseline_test.exs — REPLACE line 40's `if false, do: compare_baselines(%{}, %{})`
# with a real test (planner discretion: own test or fold into setup_all).
test "only-forward ratchet: no cell regresses prior committed baseline", %{baseline: b} do
  # D-04 anti-vacuity guard — a forgotten promotion fails loudly here.
  assert b["prior"]["run_id"] != b["current"]["run_id"],
         "prior and current share run_id #{inspect(b["prior"]["run_id"])} — " <>
           "the re-score was not promoted; this would be a vacuous self-comparison."

  compare_baselines(b["prior"], b["current"])
end
```
*Source: synthesized from live `ratchet_baseline_test.exs:87-104` (comparator reads
`["surfaces", ...]` off each operand) — VERIFIED this session.*

### GAP-row flip idiom (D-07) — match existing closed-row format
```
| GAP-06 | deliveries | mailglass_admin/operator_live.ex:409 | Spacing | 4 | tmp/ui-audit/deliveries-768-light.png | Fixed in Phase 98: master-detail now md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%] (minmax(22rem,28rem) removed). | fixed | 2026-06-16-phase-103 | 2026-06-14-phase-98 |
```
*Source: the existing closed rows GAP-02/03/05 in `RATCHET-GAP-REGISTER.md` use exactly this
"Fixed in Phase NN: ..." status-cell convention with `first_seen_run` preserved.*

### Re-run capture (Seed Run Procedure, D-06)
```bash
# Step 1: boot demo app
cd reference/demo_app && mix ecto.create && mix ecto.migrate \
  && mix run priv/repo/seeds.exs && mix phx.server   # :4015
# Step 2 (separate shell): capture 18 PNGs
cd mailglass_admin && bash scripts/ui-audit.sh        # → tmp/ui-audit/*.png (gitignored)
# Step 3: re-score 6 surface×theme pairs → 36 cells (multimodal subagent OR manual PNG review)
# Step 4/5: write current block into docs/ui-baseline-scores.json; commit ONLY the JSON
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 79 prepare-only PERFORMED the inbound re-pin to a known target | Phase 103 DEFERS the re-pin (target unknowable pre-PR) | This milestone (D-13) | Planner must NOT copy the v1.7 precedent's pin edit (DISC-2) |
| schema_version 1 flat `{surfaces}` | schema_version 2 `{prior, current}` each with surfaces | This phase (D-01) | Three existing tests need block-scoped lookups (Pitfall 1) |
| `if false` inert comparator | live `compare_baselines(prior, current)` + anti-vacuity guard | This phase (D-03/04) | Only-forward ratchet becomes merge-blocking in CI |

**Deprecated/outdated:**
- `.planning/v1.11-MILESTONE-AUDIT.md` (2026-06-15) — stale; regenerate last (DISC-3, D-14).
- `RATCHET-GAP-REGISTER.md` GAP-06/07 line numbers (397/404) — stale; current is 409/419 (DISC-1).
- `verify.phase_05` alias — deprecated pass-through to `verify.preview` (REL-03); use the latter.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The fresh re-score will meet-or-beat every prior cell (esp. preview Motion+A11y rising from 2/2 after Phases 100/101/102) | D-02 / Pattern 1 | If a cell genuinely regressed, the now-armed ratchet fails (correctly) — surfaces real work, not a research error. Planner should expect a real re-score, and if any cell would drop, that's a finding, not a number to fudge. |
| A2 | Release Please will compute a ~1.6.2 → 1.7.0 linked bump (minor) from the v1.11 `feat:` commits | D-12 | If it computes a different bump (patch/major), the readiness-note version is illustrative only; nothing in 103 hard-codes it. Low risk — prepare-only changes nothing. |
| A3 | The three structural-spec `skip`s (count=3) are intentional (e.g. the `:focus-visible` matches() limitation at L113) and not regressions | Gate confirmation | If a skip masks a real regression, a gate could pass falsely. Planner should eyeball the 3 skips during gate confirmation. |

**Note:** A1/A2/A3 are flagged so the planner gates them. They are not blocking — they are
"confirm during execution" items, not locked facts.

## Open Questions

1. **Does the fresh re-score produce any cell below its prior value?**
   - What we know: Phases 100/101/102 uplifted preview/motion/copy; preview Motion+A11y was the
     lowest cell (2/2). The expectation is rise, not fall.
   - What's unclear: actual re-scored values won't exist until Step 2 runs.
   - Recommendation: run the re-score honestly (D-02); if any cell would drop, that is a genuine
     regression to investigate, not a number to adjust — the armed ratchet is doing its job.

2. **Which 36-cell coverage-test fix shape does the planner prefer (iterate both blocks vs only
   `current`)?**
   - What we know: both satisfy Pitfall 1; iterating `["prior","current"]` validates both blocks.
   - Recommendation: iterate both blocks (validates the migrated `prior` too) — but this is
     Claude's-discretion JSON-layout territory (D-01 discretion clause).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Postgres (demo app) | `ui-audit.sh` re-run, browser gates | assume ✓ (project standard) | — | — |
| `agent-browser` CLI | `ui-audit.sh` PNG capture | local-only prereq | >=0.27 | re-score is local/ad-hoc; not a CI blocker |
| Playwright + chromium | structural gate | ✓ in CI (`npx playwright install`) | per `package.json` | — |
| `gsd-audit-milestone` skill | D-14 audit regen | ✓ `~/.claude/skills/gsd-audit-milestone` | — | — |
| Elixir 1.18 / OTP 27 | all mix gates | ✓ project standard | 1.18 / 27 | — |

**Missing dependencies with no fallback:** none identified.
**Missing dependencies with fallback:** `agent-browser` is a local prereq for the PNG re-run; if
unavailable on the execution machine, the re-score (Step 2) can't capture fresh PNGs — but PNG
capture is explicitly local/ad-hoc and never CI-gated (D-07), so this blocks the re-score step
only, not the CI gates.

## Validation Architecture

> `workflow.nyquist_validation` is not explicitly false in `.planning/config.json` (treat as
> enabled). The stale audit shows it as `true`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18 / OTP 27) + Playwright (Node 22, admin only) |
| Config file | `mailglass_admin/playwright.config.cjs`; mix aliases in `mailglass_admin/mix.exs:180-194` |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` |
| Full suite command | `cd mailglass_admin && mix verify.support_contract.admin` (incl. ratchet + token-parity) and `mix verify.preview` (full admin test + assets build + bundle-clean) |

### Phase Requirements → Test Map
| Req | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|-------------|
| RATCHET-01 | only-forward meet-or-beat across 36 cells + anti-vacuity | unit | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` | ✅ (needs D-03/04 edits) |
| RATCHET-02 | register idempotent-clean (6 rows fixed) | doc + live-code grep | grep verifications above (no automated register test; manual + flips) | ✅ live code |
| token-parity | admin theme values match brandbook tokens | unit | bundled in `verify.support_contract.admin` (`token_parity_test.exs`) | ✅ |
| conformance (5 gates) | no design-system violations in lib/ | shell | `bash mailglass_admin/scripts/check-conformance.sh` | ✅ |
| conformance advisory (type-lg/xl + track) | no large type / arbitrary tracking | shell | `bash mailglass_admin/scripts/check-conformance-advisory.sh` | ✅ |
| motion gate (Phase 74 frozen) | no banned animation/easing in lib + app.css | shell | `bash scripts/check_motion_conformance.sh` | ✅ |
| structural (6 pillar facts) | focus rings, ARIA, ≥44px, weights, reduced-motion | e2e | `cd mailglass_admin && npm run test:operator-browser` (`--workers=1`) | ✅ |
| bundle-clean | no uncommitted `priv/static/` drift | shell | `git diff --exit-code priv/static/` (inside `verify.preview`) | ✅ |

### Sampling Rate
- **Per task commit:** the relevant single gate (e.g. ratchet unit test after the JSON/test edits).
- **Per wave merge:** `mix verify.support_contract.admin` + the three conformance shell scripts.
- **Phase gate:** the full battery above all green, then `/gsd:verify-work`.

### Wave 0 Gaps
- None — all gate infrastructure exists. The only "new" test surface is the **edits** to
  `ratchet_baseline_test.exs` (activate comparator, bump schema assertion, anti-vacuity guard,
  fix the two coverage tests per Pitfall 1) — modifications, not net-new files.
- `103-*-VERIFICATION.md` must be produced during verify-work (does not exist yet — DISC-4).

## Security Domain

> `security_enforcement` is not set to false in config (treat as enabled). This phase ships no
> product code, no new routes, no auth, no input-handling, no crypto — it edits a test, a JSON
> data file, and planning docs, and confirms existing gates.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | no auth code touched |
| V3 Session Management | no | demo-session login is exercised by `ui-audit.sh` only (existing) |
| V4 Access Control | no | no access-control changes |
| V5 Input Validation | no | no user-input surfaces added |
| V6 Cryptography | no | no crypto; `HEX_API_KEY` is read-only via the existing `hex-publish` environment |

### Known Threat Patterns for this phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Vacuous quality gate (false assurance) | Repudiation/Tampering | D-04 anti-vacuity run_id guard (in scope, primary control) |
| Accidental release train (root `.` claims all paths) | Tampering | `exclude-paths` in `release-please-config.json` (RELH-01) — verify intact (D-11), do not edit |
| Secret exposure to PR jobs | Information disclosure | `hex-publish` GitHub Environment isolates `HEX_API_KEY`; prepare-only never publishes |

## Sources

### Primary (HIGH confidence — verified in working tree this session)
- `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` (lines 40, 46, 51-81, 87-104)
- `mailglass_admin/docs/ui-baseline-scores.json` (schema_version 1, flat surfaces)
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` (409, 419 — GAP-06/07)
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` (56/102/152 — GAP-01)
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` (12/18/39 — GAP-08)
- `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` (20/33/46/66/82 — GAP-04)
- `mailglass_admin/test/support/operator_fixtures.ex` (128/136 — GAP-09)
- `mailglass_admin/mix.exs` (180-194 aliases; 210 Hex `files` incl `docs`)
- `mailglass_admin/scripts/{ui-audit.sh,check-conformance.sh,check-conformance-advisory.sh}`
- `scripts/check_motion_conformance.sh`
- `mailglass_admin/package.json:5` (`test:operator-browser` `--workers=1`)
- `mailglass_admin/e2e/structural.spec.js` (41 tests, 3 skips)
- `.github/workflows/ci.yml` (conformance ~399-410; admin support contract ~641; browser gate ~660)
- `release-please-config.json`, `.release-please-manifest.json` (linked group, manifest 1.6.2/1.6.2/1.3.1)
- `mailglass_inbound/mix.exs:127` (`{:mailglass, "== 1.6.2"}`)
- `.planning/v1.11-MILESTONE-AUDIT.md` (stale, 2026-06-15)
- `.planning/RATCHET-GAP-REGISTER.md` (rows GAP-01..09; stale lines on 06/07)
- `~/.claude/skills/gsd-audit-milestone/SKILL.md` + `~/.claude/get-shit-done/workflows/audit-milestone.md`
- `.planning/milestones/v1.7-phases/79-.../79-04-SUMMARY.md` (prepare-only precedent — DISC-2)
- `.planning/phases/95-.../95-CONTEXT.md` (D-05 "103 only adds the diff" contract)

### Secondary (MEDIUM)
- Project memories: `project_voice_test_noops_dep_js.md`, `project_reference_baseline_coupling.md`,
  `project_v1_6_2_release_state.md` (release gotchas; RELH-01 context).

### Tertiary (LOW)
- None — no WebSearch needed; phase is entirely internal to this repo.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all tooling verified present.
- Architecture (restructure + activation): HIGH — every line number verified against live code;
  comparator signature confirmed compatible with `{prior,current}` blocks unchanged.
- Pitfalls: HIGH — Pitfall 1 (coverage-test breakage) found by reading the actual test body, not
  inferred; the rest are corroborated by live config + project memory.
- Discrepancies: HIGH — DISC-1..4 each verified by direct file inspection this session.

**Research date:** 2026-06-16
**Valid until:** 2026-06-23 (7 days — fast-moving closeout against an active working tree; re-verify
GAP line numbers and VERIFICATION.md presence immediately before planning if the tree has changed)
