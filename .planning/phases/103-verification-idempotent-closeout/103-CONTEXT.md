# Phase 103: Verification + Idempotent Closeout - Context

**Gathered:** 2026-06-16 (assumptions mode + research-driven recommendations)
**Status:** Ready for planning

<domain>
## Phase Boundary

The single closeout gate for v1.11 (mailglass_admin Design-System Uplift). **No net-new
product code.** This phase verifies the whole milestone and leaves the quality apparatus in
a clean, idempotent, only-forward state. Concretely it must:

1. Re-run the full 18-cell PNG audit matrix and **genuinely re-score** all 36 cells
   (`surface × pillar × theme`); assert every cell meets-or-beats its prior committed
   baseline; commit the new scores as the floor the next run must beat.
2. Close every open sev-4/5 GAP row (and the sev-3/2 rows that are also resolved); leave the
   carried-forward GAP register idempotent.
3. Confirm all CI gates green — token-parity, tightened conformance + motion grep, Playwright
   structural assertions, LLM-score floor, `git diff --exit-code priv/static/` bundle-clean.
4. Stage the linked-version release ceremony **prepare-only**; regenerate the milestone audit.

**Out of scope** (scope locks carry forward from v1.11): no core/inbound functional changes,
no new routes/features, no edits to `brandbook/` or core email HEEx components, no actual Hex
publish, no version-number / CHANGELOG / manifest hand-edits.
</domain>

<decisions>
## Implementation Decisions

### Score-Baseline Persistence & Meet-or-Beat Activation (RATCHET-01)

- **D-01:** Restructure `mailglass_admin/docs/ui-baseline-scores.json` into a single file with
  two keyed blocks — `prior` (the frozen floor) and `current` (the latest measured run) — each
  carrying its own `run_id` + `surfaces` map. This keeps the single agreed path (D-03 lock)
  while giving `compare_baselines/2` two genuinely-different operands in one decode. Bump
  `schema_version` 1 → 2 and update the `schema_version == 1` assertion in
  `ratchet_baseline_test.exs:46` accordingly.
- **D-02:** Migrate the existing flat scores (run_id `2026-06-13-phase-95-baseline`) into the
  `prior` block unchanged. The Phase 103 **fresh re-run + re-score** populates `current` with a
  new `run_id: 2026-06-16-phase-103`. (User locked "fresh re-run + re-score" — preview
  Motion+A11y at 2/2 should rise after the 100/101/102 passes; the re-score is real, not a
  re-affirmation.)
- **D-03:** Activate the only-forward ratchet by replacing the `if false, do:
  compare_baselines(%{}, %{})` guard at `ratchet_baseline_test.exs:40` with a real call site:
  `compare_baselines(b["prior"], b["current"])`. This is a pure ADD per the Phase 95 D-05
  contract ("103 only adds the prior-vs-current diff, not a rewrite") — do not rewrite
  `compare_baselines/2` (lines 87-104).
- **D-04:** Add an **anti-vacuity guard**: assert `b["prior"]["run_id"] != b["current"]["run_id"]`
  so a forgotten promotion (prior copied verbatim into current) fails loudly instead of passing
  as a trivial 36-cell self-comparison. This is the mechanical defense against the vacuous-gate
  footgun Phase 95 D-05 forbids.
- **D-05:** REJECTED — `git show HEAD:.../ui-baseline-scores.json` as the prior source. Unsafe:
  `docs/` ships inside the Hex tarball but `.git` does not, so `mix test` from an unpacked
  package or a shallow/sandboxed CI checkout would read empty → vacuous pass. Also violates the
  zero-process-dep, pure-`File`+`Jason` test DNA. (Ecosystem precedent: Betterer, Rust `insta`,
  jest snapshots, type-coverage all commit the baseline as a reviewable file, never a git
  self-diff.)
- **D-06:** Document the **promotion step** (copy previous `current` → `prior`, write fresh
  `current`) in the register's "Seed Run Procedure" so the next milestone's re-run advances the
  floor without fighting the apparatus.

### GAP Register Reconciliation (RATCHET-02)

- **D-07:** Close all currently-open rows by **verify-already-fixed-and-flip** (`open → fixed`):
  re-run the audit, confirm each finding ABSENT in *live code* (not in the stale audit doc),
  flip status, stamp `run_id: 2026-06-16-phase-103`, and **preserve `first_seen_run`** (the
  permanent introduction anchor). No new fix code — the fixes already landed in Phases 98–100.
- **D-08:** Per-row close calls — all `fixed`, each with a proving citation recorded in the
  register:
  - GAP-06 (sev-4) → fixed — `operator_live.ex:409` `md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]` (old `minmax(22rem,28rem)` gone)
  - GAP-07 (sev-3) → fixed — `operator_live.ex:419` `text-label uppercase font-bold text-secondary`; zero `tracking-[` remaining
  - GAP-08 (sev-3) → fixed — `deliveries_list.ex:18,23` `filters_active?` splits `operator-empty-filtered` / `operator-empty-truly` + reset CTA
  - GAP-09 (sev-3) → fixed — `operator_fixtures.ex` seeds `:suppressed` + `hours_ago(6/7)` rows reaching the required states by URL
  - GAP-01 (sev-3) → fixed — `support_cards.ex:56/102/152` carry `min-h-11`; zero `btn-sm`
  - GAP-04 (sev-2) → fixed — `inbound/filters_form.ex` labels use `text-label uppercase font-bold text-secondary`
- **D-09:** Bright-line honesty rule (apply on every flip): `status: fixed` REQUIRES the finding
  be absent in live code; `status: downgraded` is reserved for findings that are *present but
  deliberately not worth fixing* (with rationale). **No downgrades in this phase** — every open
  row is genuinely fixed. Never downgrade a fixed finding (it falsifies the meet-or-beat
  baseline); never flip-to-fixed a finding still present (rubber-stamp).
- **D-10:** Trigger vs evidence: the stale `v1.11-MILESTONE-AUDIT.md` is only the *signal* that
  reconciliation is owed — never the basis for a flip. Flip against the live `component:line`
  and a fresh PNG run only. After the flip the register is idempotent-clean: confirmed-fixed
  rows skip on re-run, regressions reopen.

### Release Prepare-Only + Milestone Audit (CLOSE)

- **D-11:** "Prepare-only" = change **nothing** Release Please owns. The deliverable is a Phase
  103 readiness note (SUMMARY/STATE) recording a verification checklist: linked group is
  `mailglass` + `mailglass_admin` (inbound independent); `.release-please-manifest.json` left at
  `1.6.2/1.6.2/1.3.1` untouched; `release-please-config.json` root `exclude-paths` still scopes
  core away from `mailglass_admin`/`mailglass_inbound`/`brandbook`/`.planning`/`prompts`
  (RELH-01 hardening intact).
- **D-12:** A linked bump IS pending (not zero-change): v1.11 `feat:`/`fix:` commits on
  `mailglass_admin/` paths + the linked-versions plugin mean Release Please will open a
  ~1.6.2 → 1.7.0 linked-group bump once the pipeline is armed. The inbound `{:mailglass,
  "== 1.6.2"}` pin (`mailglass_inbound/mix.exs:127`) will go stale against the new core.
- **D-13:** Record the inbound exact-pin re-pin as the single **pending** ceremony action —
  **do NOT perform it now**. The target core version is whatever Release Please computes from
  the conventional commits (unknowable pre-PR); the re-pin lands later as a `fix(inbound):`
  commit, post-bump. A guessed pin desyncs the reference/demo baseline (a coordinated 5-file
  change).
- **D-14:** Regenerate the milestone audit **LAST**, via the `gsd-audit-milestone` skill
  (overwrites `.planning/v1.11-MILESTONE-AUDIT.md`, reads per-phase `*-VERIFICATION.md`). Run it
  only AFTER the GAP register is reconciled (D-07/08) and the ratchet is activated (D-03) so it
  truthfully flips `gaps_found → passed` rather than re-reporting the stale 2026-06-15 gaps
  (which falsely list COPY-01/MOTION-01/MOTION-02 as unsatisfied — those phases are now
  complete).

### Closeout Ordering (locked)

- **D-15:** reconcile GAP register → activate meet-or-beat ratchet (+ fresh re-score) → run
  all-gates verification (token-parity, conformance + motion grep, Playwright structural,
  LLM-score floor, bundle-clean) → write prepare-only readiness note → **regenerate milestone
  audit last**.

### Claude's Discretion

- Exact `schema_version` 2 JSON layout details (key ordering, whether `pillar_rubric`/`grade_scale`
  live at top level or per-block) — planner/executor choice, as long as D-01/D-04 hold.
- Whether the anti-vacuity `run_id` guard lives in `setup_all` or its own test — either is fine.
- The DELIVERIES/INBOUND/PREVIEW re-score method (multimodal subagent vs structured manual
  review of the 18 PNGs) per the register's Seed Run Procedure Step 3.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 103 success criteria (~line 305) + v1.11 scope locks.
- `.planning/RATCHET-GAP-REGISTER.md` — the carried-forward GAP register; "Idempotent Re-Run
  Semantics", "Seed Run Procedure", "Severity Rubric" sections. Rows to flip: GAP-01/04/06/07/08/09.
- `mailglass_admin/docs/ui-baseline-scores.json` — committed 36-cell score baseline; restructure to
  `{prior, current}` (D-01/D-02).
- `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` — `if false` guard at line 40 to
  activate; `compare_baselines/2` at 87-104 (call, do not rewrite); `schema_version == 1` assertion
  at line 46 to bump.
- `mailglass_admin/scripts/ui-audit.sh` — 18-cell PNG capture matrix (Seed Run Procedure). PNGs are
  gitignored (D-07 ban on pixel-diff) — never commit them.
- `mailglass_admin/scripts/check-conformance.sh` + `check-conformance-advisory.sh` — conformance /
  motion grep gates.
- `mailglass_admin/mix.exs` — `verify.preview` + `verify.support_contract.admin` aliases (where the
  ratchet test is CI-gated; bundle-clean `git diff --exit-code priv/static/`).
- `.github/workflows/ci.yml` — gate wiring (conformance ~399-410, structural Playwright ~685-737).
- `.planning/phases/95-audit-apparatus-quality-ratchet-v2/95-CONTEXT.md` — Phase 95 D-05 design
  intent ("103 only adds the prior-vs-current diff"; forbids a vacuous gate).
- `.planning/milestones/v1.7-phases/79-verification-and-visual-regression-hardening/79-04-SUMMARY.md`
  — prepare-only release precedent (inbound exact-pin re-pin is the ONLY pre-publish ceremony step).
- `release-please-config.json` + `.release-please-manifest.json` — linked group + manifest;
  **do not hand-edit** (Release Please owns them).
- `mailglass_inbound/mix.exs` (line 127) — the `{:mailglass, "== 1.6.2"}` exact-pin; pending
  `fix(inbound):` re-pin, deferred (D-13).
- `.planning/v1.11-MILESTONE-AUDIT.md` — STALE (status `gaps_found`, dated 2026-06-15, predates
  completed phases 101/102/103). Regenerate via `gsd-audit-milestone` (D-14).
- Live code proving GAP fixes: `mailglass_admin/lib/mailglass_admin/operator_live.ex` (409, 419),
  `.../operator/deliveries_list.ex` (18-44), `.../operator/support_cards.ex` (56/102/152),
  `.../inbound/filters_form.ex` (labels), `mailglass_admin/test/support/operator_fixtures.ex`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `compare_baselines/2` is already written (`ratchet_baseline_test.exs:87-104`) — Phase 103 only
  adds the call site + the schema-2 restructure + anti-vacuity guard. The 36-cell
  shape/range/coverage tests (lines 45-81) already pass and need only the `schema_version` bump.
- `scripts/ui-audit.sh` already captures the 18-cell PNG matrix keyed `{surface}-{vp}-{theme}`,
  including preview dark via `?theme=dark` (Phase 100). Reuse as-is for the fresh re-run.
- The conformance + motion grep gates were already tightened in Phase 94 (RATCHET-03); Phase 103
  only re-confirms them green, not re-tightens.

### Established Patterns
- Committed-snapshot-as-source-of-truth for the only-forward ratchet (matches Betterer / `insta` /
  jest-snapshot / type-coverage ecosystem canon). No process deps, no git archaeology — pure
  `File` + `Jason`, fail-closed in a required CI lane (`verify.preview`).
- GAP register is append-only / stable-ID / idempotent: `first_seen_run` never changes; `run_id`
  records the last touch; `fixed` rows skip on re-run; regressions reopen.
- Linked-version releases: humans never touch version numbers / CHANGELOG / manifest — conventional
  commits drive the bump; the inbound exact-pin is the lone manual re-pin, done post-bump.

### Integration Points
- `ratchet_baseline_test.exs` is gated by the `verify.preview` mix alias → CI. Activating the
  comparator makes the only-forward assertion automatically merge-blocking.
- `gsd-audit-milestone` skill reads per-phase `*-VERIFICATION.md` files and overwrites
  `.planning/v1.11-MILESTONE-AUDIT.md` — it must run after register + ratchet are reconciled.
- The reference/demo baseline (reference/host_app, reference/demo_app) is coupled to the inbound
  exact-pin — another reason D-13 defers the re-pin (avoids the coordinated 5-file drift +
  demo_app swoosh lock drift).
</code_context>

<specifics>
## Specific Ideas

- Fresh re-run + re-score is explicitly user-locked (not re-affirmation of Phase 95 numbers).
- All three research areas were investigated via parallel advisor subagents (ratchet persistence,
  GAP reconciliation, prepare-only release); the decisions above reflect the synthesized
  recommendations, two of which corrected the first-pass codebase assumptions (D-05 rejected
  `git show HEAD:`; D-12 corrected the "zero version change" premise).
</specifics>

<deferred>
## Deferred Ideas

- The actual Hex publish (cutting the real linked-version release) is a post-milestone decision
  (v1.7 precedent), not part of this prepare-only closeout.
- The inbound `fix(inbound):` exact-pin re-pin to the new core version lands later in the release
  pipeline, after Release Please computes the target version.

### Reviewed Todos (not folded)
None — analysis stayed within phase scope.
</deferred>
