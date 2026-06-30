# Retrospective: mailglass

> Living retrospective. New milestones are appended at the top. Cross-milestone trends section grows over time.

---

## Milestone: v1.14 — Operator IA & Lived-Experience Redesign

**Shipped 2026-06-30** — 7 phases (118–124), 15 requirements, audit `status: passed`.
**Linked-version release:** mailglass 1.10.1 / mailglass_admin 1.10.1 / mailglass_inbound 1.5.3, inbound pinned `{:mailglass, "== 1.10.1"}`.

**What worked:**
- **Method inversion delivered.** Top-down JTBD/IA-led redesign + adversarial persona-critic loop caught taste/redundancy/IA problems that bottom-up structural gates can't (false-active nav, redundant overview cards, homepage-that-points-elsewhere).
- **Surface-by-surface, biggest-impact-first** ordering with each surface inheriting the prior's cleaned-up patterns; full pillar re-score + judgment-gate arming consolidated into Phase 123.
- **The release ceremony's fix-forward discipline held** under a remarkable pile-up of surprises (below), shipping a genuinely-green release rather than a rubber-stamped one.

**Key lessons (the hard ones this cycle):**
- **Deferred verification is a debt that comes due at the worst time.** The 128-commit body was built entirely on local `main` and never CI'd; phases 119–123 deferred browser/persona re-shoots ("demo unrunnable in-env", cached evidence). The release push was the first real CI run and surfaced **7 operator-browser-gate regressions** — 2 genuine a11y bugs (preview backdrop `aria-pressed`, inbound reveal ARIA disclosure), 3 stale specs, 1 CI-only Linux-Chromium gallery overflow. Run the real gate before claiming a surface green.
- **Local hex can't see fresh advisories.** A coordinated EEF advisory disclosure (plug, then cowlib/cowboy/postgrex/phoenix/mint/req/decimal — ~16 CVEs) was invisible to local `publish.check` (hex v2.4.2 stale advisory DB) and only blocked on the CI/publish runner. Always validate `hex.audit` on a runner before trusting a clean local publish.check.
- **Some advisories are unfixable.** cowlib EEF-CVE-2026-43966/43969 have no patched release and cowlib is an unavoidable transitive web-stack dep. Added a **narrow, documented, CVE-ID-specific allowlist** to `publish.check`'s hex.audit gate (every other/fixable advisory still hard-blocks; regression-tested). Revisit when cowlib ships a fix.
- **Recover unpublished cuts as a fresh patch, not by moving tags.** The 1.10.0/1.10.0/1.5.2 cut (tags at `f0c84ec0`) never published (publish gate blocked). Rather than force-move release tags, let RP cut a clean **1.10.1/1.10.1/1.5.3** (repeat the `fix(inbound)` re-pin == 1.10.1); the unpublished 1.10.0 tags remain harmless phantoms. `mix.lock` isn't shipped, but the publish gate audits the lock *at the tag* — so the fix must be in the tagged tree.
- **Self-approval is blocked on RP PRs** → admin-squash-merge is the path (a human-pushed squash also dodges the bot-merge `gate-ci-green` anti-recursion gap). Racing publish-hex fan-outs are idempotent noise — one run publishes all three; the losers fail on "already published."

**Release outcome:** 1.10.1/1.10.1/1.5.3 live on Hex; consumer + post-publish smoke green; first linked-version cut since 1.9.0/1.9.0/1.5.1 (v1.13).

---

## Milestone: v1.13 — Admin Design-System Stress Test & UX Uplift (v3)

**Shipped 2026-06-21** — 9 phases (109–117), 41 requirements, audit `status: passed`.
**Linked-version MINOR release:** mailglass 1.8.0 / mailglass_admin 1.8.0 / mailglass_inbound 1.5.0,
inbound re-pinned `{:mailglass, "== 1.8.0"}` (D-13). Third lived-experience admin design-system pass
(after v1.7/v1.11), distinguished by D-29: the v1.11 ratchet passed in the lab yet the real
`make demo` app still surfaced usability traps. Light/dark/system at every width, WCAG 2.2 AA,
multi-tenant stress fixtures, axe-JSON + score-baseline ratchet — no product-capability growth.

### What shipped

Bottom-up fractal uplift: token/gate foundation (109) → public primitives incl. canonical
`stat_card` + 3-way theme picker (110) → unified filter components (111) → tenant seam auto-selecting
the sole tenant from the core read model (112) → responsive table→card data display (113) → composed
group geometry (114) → motion contract (115) → multi-tenant persona cohort + ratchet-arm with axe
baseline and the 24-defect usability sweep (116) → release cut + milestone closeout (117). Two genuine
product fixes also landed: `mg-focus-ring` on the mobile detail-back buttons (WCAG 2.4.11) and
preview frame-theme independence across the admin-chrome theme toggle.

### What worked

- **Tighten-then-re-baseline held again.** Gates were tightened inside each phase with the full
  pillar re-score deferred to the final ratchet-arm phase (116) — the re-baseline could not regress
  silently. The v1.11 pattern carried cleanly into a second consecutive design-system milestone.
- **The executable Bucket-A manifest.** Every one of the 24 usability defects cites a guard literal
  (gate name / e2e title / axe ref / persona literal) asserted to physically exist, so a renamed or
  deleted guard fails the manifest rather than passing vacuously — closure was mechanical, not asserted.
- **Advisory-aware `gate-ci-green` did its job.** The Demo/Operator browser lanes are non-blocking;
  the release wasn't held hostage by an intermittent demo seeding flake.
- **Human-identity merge avoided the anti-recursion stall.** Merging via `--admin` (BLOCKED state,
  only `guard-release-trigger` required) ran CI on the merge SHA under a human identity, so the bot
  anti-recursion gap that stalls `publish-hex` `gate-ci-green` never triggered.

### Key lessons / friction

- **Lesson (repeat of v1.12, sharper): a frozen origin means the release body has never run full CI.**
  The 227-commit v1.13 body executed locally on `main` with targeted gates; pushing it for the release
  surfaced 3 latent regressions on first real CI — a `mix format` comment in `events/event.ex`, 2
  Dialyzer Ecto map-projection spec artifacts (`operator/{deliveries,tenants}.ex`, suppressed), and
  16 stale browser specs from the Phase-113 responsive migration (`*-list-card` selectors, visible-row
  filtering, oklab-unparseable contrast helpers, focus-modality + transition-race fixes). The standing
  fix remains: a full-CI dry run before the release ceremony, not just targeted phase gates.
- **Lesson: a published core can raise a NEW transitive requirement the sibling lock can't satisfy.**
  publish-inbound/admin failed because `mailglass 1.8.0` requires `premailex ~> 1.0` while the sibling
  `mix.lock` still pinned `premailex 0.3.x` → "the lock is incompatible with mailglass" / version
  solving failed. Registry-cache and `HEX_HOME=$(mktemp -d)` attempts were red herrings — the real fix
  was `mix deps.unlock --all` before the sibling `deps.get` in `publish-hex.yml` (`ceee3835`), now
  permanent in the pipeline. When core bumps a dep floor, the siblings' locks must be unlocked at
  publish time, not just refreshed.
- **Friction: premature cancel of a slow publish run.** Long Hex-index polling made an in-flight
  publish look hung; cancelling it cost a re-dispatch. Read the run's actual elapsed time, not the
  polling wall-clock, before assuming a stall.
- **Playwright modality is subtle.** `:focus-visible` only triggers on keyboard modality — a
  programmatic `.focus()` after a mouse `.click()` won't show the ring, and a 90ms `outline-color`
  transition races the measurement. Tab-to-focus + settle-the-transition + `getImageData` (oklab-safe)
  was the durable shape.

### Follow-up (non-blocking)

- **`cohort:58` demo seeding flake** — intermittent shared-DB seeding race in the demo Playwright
  lane; advisory-only (didn't block publish) but worth hardening with a deterministic per-test seed.
- **No `gsd-retrospective` skill is installed** in this environment, so this entry was authored
  directly against the milestone audit's release-engineering notes rather than generated.

---

## Milestone: v1.12 — Adopter Onboarding & Day-2 Confidence

**Shipped 2026-06-17** — 5 phases (104–108), 13 requirements, audit `status: passed`.
**The first real linked-version Hex release since 1.6.2:** mailglass 1.7.0 / mailglass_admin
1.7.0 / mailglass_inbound 1.4.0, with inbound re-pinned `{:mailglass, "== 1.7.0"}` (D-13).

### What shipped

Installer now fails closed (`Mix.raise`) on an unmanaged `Plug.Parsers` conflict — closing the
silent-prod-401 footgun — with a `--force` escape hatch and a `mix mailglass.doctor` static
webhook-wiring check; a config-first README quickstart + week-1 learning arc; go-live and
errors/troubleshooting day-2 guides; inbound replay-modal a11y parity; then the release cut.

### What worked

- **Push-before-merge caught real bugs.** The v1.7–v1.12 body had never run through full CI
  (phases executed locally, gated on targeted commands). Pushing it to `main` *before* merging the
  release PR surfaced six genuine regressions that would otherwise have shipped or stalled the
  publish. This sequencing is the single biggest lesson — see below.
- **Allowlist-first publish hygiene.** Regenerating `*-files.expected` for all three packages
  before the release PR merged caught 9 unpublished file additions (core +5, admin +3, inbound +1).
- **The fail-closed installer worked exactly as designed** — it (correctly) blocked the consumer
  smoke, which is what flagged that the smoke needed `--force`.
- **Hands-free pipeline mostly held;** tags + GitHub Releases + publish fan-out fired automatically
  off the merge.

### Key lessons / friction

- **Lesson: run full CI on milestone work before the release ceremony, not just targeted gates.**
  Local phase execution (`execute-phase` on main with targeted commands) never exercised Format
  Check, Dialyzer, `mix docs --warnings-as-errors`, `mix mailglass.docs.check`, Installer Host
  Smoke, or the demo Playwright lane. All six were red on first real CI. A "full-CI dry run" before
  the release phase would move these left.
- **Lesson: validate the WHOLE lane, not one step.** I fixed `mix docs --warnings-as-errors`,
  re-pushed, and the Docs lane *still* failed — on its second step `mix mailglass.docs.check`
  (a stale `~> 0.3` required token contradicting phase 105's `~> 1.6` bump). Run every step a CI
  lane runs.
- **Lesson: cross-artifact reconciliation gaps.** Phase 105 bumped the migration-guide pin and the
  contract test but missed `mix mailglass.docs.check`'s required-token list. When a doc value is
  asserted in more than one place, grep for ALL of them.
- **Racing fan-outs are still noisy.** Three `publish-hex` runs fired (one per release event); two
  `publish-core` jobs failed as already-published race-losers, and the first post-publish-smoke
  false-negatived on a Hex-index timeout. None were real; all disproven directly against Hex. A
  re-dispatched post-publish-smoke went fully green.
- **Hands-free auto-merge did not fire.** Non-required advisory lanes (Core Full Suite, Provider
  Compatibility) were red and Release Please's hourly cron kept regenerating the PR head, so
  auto-merge never caught a settled-green window. Resolved with a maintainer admin-override merge
  after explicit go/no-go, with all branch-protection-required checks green.

### Follow-up (non-blocking)

- Harden `publish-hex.yml` `gate-ci-green` `isAdvisory()`: "Demo Browser Evidence" matches neither
  the `ADVISORY_LANES` list nor the `" Advisory ("` naming convention, so a red Demo Browser
  Evidence lane would block publish despite not being a branch-protection required check. Fixing the
  test green sidestepped it this release; classify it advisory by name to match the documented rule.

---

## Milestone: v1.11 — mailglass_admin Design-System Uplift

**Shipped:** 2026-06-16
**Phases:** 10 (94-103) | **Plans:** 42

### What Was Built

The `mailglass_admin` UI was re-baselined onto the canonical fable brand tokens and
then fractally uplifted — component → group → page — across all three surfaces
(Operator, Inbound, Preview) to award-winning quality in light + dark at every width.
The root cause was concrete and measurable: the admin's `app.css` never consumed
`brandbook/tokens.css`, so every border drew in the accent color, cards sat one
brand-role off, and dark muted text was sub-AA. Phase 94 fixed the token foundation
behind a fail-closed token-parity gate; Phases 95-96 stood up an idempotent
quality ratchet and a five-dossier research layer of adversarially-synthesized LOCKED
DECISIONS; Phase 97 uplifted the shared components and shipped a dev-only gallery
LiveView; Phases 98-100 uplifted each surface (the structurally-thin Inbound surface
was the heaviest lift, gaining an overview tier and reworked RoutingTrace/EvidenceCard);
Phases 101-102 ran global microcopy and motion passes; Phase 103 closed out with the
meet-or-beat ratchet armed (36/36 cells, 15 improved, zero regressions), all 6 CI
gates green, and the release ceremony staged prepare-only.

### What Worked

- **Gates-first (tighten-then-re-baseline).** Landing the tightened conformance + motion
  grep gates and the fail-closed token-parity test BEFORE the token swap meant the
  re-baseline literally could not regress silently — the build broke on drift.
- **Front-loaded research dossier → LOCKED DECISION blocks.** Phase 96's five dossiers
  let every downstream build phase cite a stable `MOTION-LD`/`IA-LD`/`STATE-LD`/`DARK-LD`/
  `COPY-LD` decision ID without re-reading the research body — clean decision provenance.
- **The idempotent GAP register + meet-or-beat ratchet.** A single carried-forward
  `GAP-NN` register with run-ids and a sev≥3 citation gate, plus a committed score
  baseline, made the milestone's "only-forward" guarantee mechanical rather than aspirational.
- **Dev-only gallery as the audit surface.** The Storybook-lens LiveView with stable
  `data-testid` cells gave the structural-assertion and LLM-score layers an exhaustive,
  DB-free target — satisfying the zero-Node hard rule without a real Storybook.
- **Self-verifying close.** Every phase produced a `passed` VERIFICATION.md and the audit
  cross-referenced three sources (REQUIREMENTS traceability, VERIFICATION tables, SUMMARY
  frontmatter) — zero human UAT needed.

### What Was Inefficient

- **A stale 2026-06-15 audit** reported three unsatisfied requirements (COPY-01,
  MOTION-01/02) and three missing phases (101/102/103) that were in fact complete;
  Phase 103-04 had to regenerate the audit (`gaps_found` → `passed`) as the explicit
  D-15-ordered last step. Audit currency is fragile when phases land fast.
- **Nyquist validation lagged** — 96/97/101 have no VALIDATION.md and 102/103 are draft.
  Non-blocking (all VERIFICATION.md passed) but it leaves the Nyquist layer `partial`.
- **Leftover phase dirs** (v1.10 91-93 + 999.x backlog) still in `.planning/phases/`
  keep inflating `milestone.complete` counts, forcing manual stat correction every close.

### Patterns Established

- **Tighten-then-re-baseline** as the safe order for any foundational token/CSS swap.
- **Adversarially-synthesized LOCKED DECISION blocks** as the consumable interface between
  a research phase and the build phases that cite it.
- **Schema-2 `{prior, current}` score baseline with an anti-vacuity guard** as the
  meet-or-beat ratchet shape (activated only at closeout to avoid mid-milestone churn).
- **PENDING ceremony action documented in the audit** when a release step (inbound
  exact-pin re-pin) is unknowable until the Release Please PR merges — deferred, not skipped.

### Key Lessons

- Regenerate the milestone audit as the *last* closeout step (D-15 ordering); a
  fast-moving milestone will outrun any earlier audit snapshot.
- A measurable root cause ("every border draws in the accent color") makes a
  design-system milestone falsifiable and gate-able — far stronger than "feels off-brand."
- Prepare-only release posture (v1.7 precedent) cleanly decouples adopter-visible-quality
  work from the Hex release decision; the linked-version bump can wait for a real cut.

### Cost Observations

- Model mix: predominantly the balanced profile (config `model_profile: balanced`).
- Phases: 10 (94-103) across 2026-06-13 → 2026-06-16 (≈4 days).
- Notable: Phase 96's five-dossier research fanned out to parallel subagents; the heaviest
  single build lift was Phase 99 (Inbound), the structurally-thinnest surface.

---

## Milestone: v1.10 — Brand Adoption

**Shipped:** 2026-06-13
**Phases:** 3 (91-93) | **Plans:** 9

### What Was Built

The A/B-winning fable brand became the project's one canonical identity. The
v1.9 book was adopted as canonical `brandbook/` via `git mv` (codex removed from
the active tree, history preserving it at `09a84dd4`); the root README gained the
sealed-flap brand header; a 2400×1260 og-card.png was committed for GitHub social
preview; ex_doc `logo:`/`favicon:` was wired into all three packages pointing at
canonical `brandbook/` assets (with SVG width/height added for ex_doc 0.40.x);
the admin placeholder wordmark was replaced with a theme-safe `currentColor`
lockup. Release hardening rode along: `exclude-paths` on the root `.` package plus
a required `guard-release-trigger` PR lint (offline 6-case fixture) so
brand/planning-only commits can never cut a release again, and the 1.6.x
accidental-release aftermath was reconciled to released truth 1.6.2/1.6.2/1.3.1.
No Hex release was cut by this milestone.

### What Worked

- **Research pre-settled the mechanics.** `ADOPTION-MECHANICS.md` nailed ex_doc
  0.40.1 logo/favicon semantics, the viewBox→width/height requirement, the
  Playwright og-card command, release-please trigger safety, and an exhaustive
  reference sweep (only CLAUDE.md + design-system.md were tracked consumers)
  before any phase planned. Execution was mostly mechanical as a result.
- **Strictly linear 91→92→93** matched the real dependency (every later surface
  references the post-rename `brandbook/` path), so no wave thrash.
- **Incident-driven hardening.** RELH-01/02 turned the 1.6.x accidental-release
  pain into durable guardrails (belt-and-suspenders: config exclude-paths +
  CI lint) rather than a one-off fix.

### What Was Inefficient

- `milestone.complete` over-counted scope again — it swept the dormant 999.x
  backlog dirs into phase/plan/task stats (5/15/35) and bled their
  accomplishments (comment cleanup, preview-capture) plus two empty `One-liner:`
  lines into the MILESTONES.md entry. Corrected by hand to true scope (3/9).
  This is a recurring CLI footgun documented in user memory.
- A couple of Phase 92/93 SUMMARY files lacked the parseable `**One-liner:**`
  field, so auto-extraction produced blanks — curated accomplishments by hand.

### Patterns Established

- **Required CI commit-type guard for non-code paths** (`guard-release-trigger`):
  any bump-triggering PR whose changed files are entirely under brand/planning
  paths fails the lint — a reusable defense for repo-artifact milestones.
- **Canonical-folder adoption via `git mv` + same-commit codex removal**, with a
  re-pathed quality gate proving nothing broke in the move.

### Key Lessons

- For repo-artifact milestones, lean on non-release-triggering commit types
  (`docs:`/`chore:`/`test:`) and verify the guard with an offline fixture — don't
  trust release-please defaults implicitly when an incident already proved them
  insufficient under a root `.` package path.
- Trust live Hex over in-repo manifests for version truth: RELH-02 confirmed the
  release-state memory (1.6.2) was correct and the in-repo manifest (1.6.1) was
  stale. Reconcile to what actually published.
- Keep correcting `milestone.complete` output to true milestone scope until the
  999.x backlog dirs are archived out of `.planning/phases/`.

### Cost Observations

- Two-day milestone (2026-06-12 → 2026-06-13), 9 plans across 3 phases.
- Mostly mechanical adoption + reconciliation; research front-loaded into one
  pre-settled mechanics doc kept per-phase planning light.

---

## Milestone: v1.9 — Brand Book Fable (A/B Brand System)

**Shipped:** 2026-06-12
**Phases:** 6 (85-90) | **Plans:** 7

### What Was Built

A complete competing fable brand book (256 KB, all text artifacts): forensic
differentiation brief, contrast-proven two-tier tokens
(light+dark parity, computed WCAG matrix), the sealed-flap logo system (8
assets, color program + mono master, OS-dark-adaptive favicon), a
self-contained HTML book with live theme toggle / keyboard gallery /
runtime-computed contrast matrix, landing + email specimens, four portable
SVGs, and a domain-noun copy library. Maintainer A/B verdict vs the codex
baseline: "I LOVE THE NEW BRANDBOOK."

### What Worked

- The bounded tournament fixed v1.8's thrash: diverse-by-axis option sets,
  pre-flight constraint screening, rendered evidence strips, and
  single-parameter variant rounds kept every maintainer touchpoint decisive.
  rejection_count stayed 0 across four rounds.
- Multimodal self-audit (Playwright render → read → fix → re-render) before
  every presentation caught ~10 real craft defects the maintainer never saw.
- Differentiation brief before any artifact: verified codex defects only,
  killed six false differentiators early, kept the A/B honest.
- Express-path CONTEXT.md from the approved plan kept the full GSD cycle
  fast without skipping gates.

### What Was Inefficient

- Two subagent crashes (529 overload, socket close) — both recovered cleanly
  from committed state because executors commit per task; the promotion
  crash cost one re-verification pass.
- The maintainer-directed round 4 exceeded the round-3 hard cap; the
  protocol needed a documented extension path (recorded fallback winner)
  rather than treating direction as rejection.

### Patterns Established

- Tournament protocol with hard pauses, pre-flight tables, evidence strips,
  circuit breaker, and maintainer-extension clause.
- Standing brand constraints C-15 (no broken reads) and C-16 (envelope by
  light only) are binding on future brand work.
- Gate phases re-prove all upstream in-phase gates on final state in one
  scripted run.

### Key Lessons

- Maintainers respond to renders, not descriptions — every creative decision
  point shipped with actual-size, both-theme, in-context renders, and every
  selection round converged in one reply.
- Honest verdicts build trust: round 4's "4B does NOT read envelope at any
  size" and the codex strengths register cost nothing and kept the A/B
  credible.

### Cost Observations

- Sessions: 1 (plus the maintainer's async picks); ~15 subagents across
  research/plan/check/execute/verify.
- Notable: known gsd-sdk count-inflation gotchas hit at both phase.complete
  and milestone.complete; corrected manually per the established playbook.

---

## Milestone: v1.8 — Brand System and Repo-Ready Brandbook

**Closed superseded:** 2026-06-11 (audit `gaps_found`, accepted)
**Phases:** 3 of 5 through GSD (80-82) | **Plans:** 5

### What Was Built

- Row-addressable brand audit and `BRAND-GAP-*` register (Phase 80).
- Source brandbook + JSON/CSS token system preserving the brand center (Phase 81).
- Logo option evidence and review artifact (Phase 82-01); the selection
  checkpoint and final-asset promotion resolved out-of-band when a separate
  session selected `concept-07r-no-idot-02-tighter-gap` and finished the
  brandbook around it (frozen at `09a84dd4`). Phases 83-84 superseded.

### What Worked

- Phases 80-81 ran clean through discuss/plan/execute/verify with small,
  auditable plans.
- Freezing the out-of-band result as an explicit baseline commit kept the
  audit trail honest instead of retro-claiming GSD completion.

### What Was Inefficient

- The logo phase thrashed badly: 18 option SVGs (A-R) plus 10 concept variants
  rejected across unbounded regeneration rounds before an out-of-band session
  landed the selection. Options were not diverse by construction, were not
  pre-screened against small-size/mono/dark renders, and rounds had no cap.
- Milestone-blocking human checkpoints with open-ended option sets stall
  indefinitely; the work escaped GSD entirely to resolve.

### Patterns Established

- Out-of-band resolution protocol: record the decision in the open
  CHECKPOINT.md, write SUMMARY.md files marking plans resolved-out-of-band,
  freeze the result as a baseline commit, close the milestone as superseded
  with the audit attached.

### Key Lessons

- Structure human creative-selection checkpoints as bounded tournaments:
  diverse-by-axis option sets, pre-flight constraint screening, rendered
  evidence (16px/32px/mono/dark/in-context), capped refinement rounds, and a
  circuit breaker to discussion after consecutive full rejections. This is
  encoded in the v1.9 plan.
- Shipped artifacts must be grepped for planning-language leakage; v1.8's
  `tokens.json` shipped "Phase 84" references.

### Cost Observations

- Sessions: ~4 (phases 80-82 GSD, plus the out-of-band brandbook session).
- Notable: the unbounded logo checkpoint consumed more iterations than all
  other v1.8 work combined.

---

## Milestone: v1.7 — Admin UI: IA & Design-System Polish v2

**Shipped:** 2026-06-05
**Phases:** 6 (74-79) | **Plans:** 22
**Coverage:** 19/19 v1.7 requirements | **Audit:** passed (7/7 seams, 3/3 flows)

### What Was Built

- A Phase 74 evidence-only gate (scored gap register, frozen UI-SPEC with a canonical status-badge taxonomy, before-baseline screenshots, assertion inventory) that every build phase had to cite before merging.
- Shell-level `Shell.orientation_strip/1` parity across Deliveries/Inbound/Preview plus an in-library Operator Overview landing added entirely within `OperatorLive.handle_params/3` — no router-macro change.
- One unified `Components.status_badge/1` atom replacing five divergent `badge_class/1` copies, a full token migration of every admin HEEx file, and a Tier1/Tier2 support-card triage hierarchy, with the rebuilt bundle committed behind a self-contained `heroicons-inline.js` plugin.
- Motion discipline (record-keyed ids fixing the `motion-reveal` re-fire, reduced-motion / ≤300ms enforced by a grep gate), fully-expressive seed data reaching every screen state, and a self-verified closeout (10 green Playwright tests + conformance/bundle gates, no human UAT).

### What Worked

- The anti-churn contract (no build task without a sev≥3 gap-register citation) kept a "polish" milestone from sprawling — every change traced to a scored, evidenced defect.
- Front-loading a frozen UI-SPEC + taxonomy table in Phase 74 made the five-way `badge_class/1` conflict a mechanical consolidation in Phase 76 instead of a design argument mid-build.
- Shift-left self-verification (Phases 75/77/79 ran the e2e/conformance suites themselves and fixed defects in-phase) meant closeout had no human-UAT backlog to drain.
- Grep-enforceable conformance (token scale, motion vocabulary, bundle-clean diff) turned brand-discipline guardrails into CI gates rather than review opinions.

### What Was Inefficient

- Phase 76 left its human-UAT/verification artifacts in `partial`/`human_needed` state even though Phases 77 and 79 actually exercised the deferred checks; the pre-close audit then flagged them as "open," needing an explicit acknowledge-and-document step at close.
- The `gsd-sdk milestone.complete` CLI scanned all of `.planning/phases/` (including leftover 999.x backlog dirs from v1.3) and miscounted the milestone as 8 phases / 28 plans / 40 tasks with 6 non-v1.7 accomplishments — MILESTONES.md and STATE.md needed manual correction to the real 6 phases / 22 plans.
- Two VALIDATION records (Phases 75, 78) stayed in draft after verification passed — the same draft-Nyquist-bookkeeping drift seen in v1.5.

### Patterns Established

- Treat a frozen spec + scored gap register as the merge gate for any "quality/polish" milestone, so subjective UI work becomes evidence-backed and bounded.
- When a downstream phase subsumes an upstream phase's deferred human checks, record the closure explicitly in the later phase's artifact so the upstream status isn't mistaken for open work at close.
- For admin-only milestones under linked-version releases, keep the release ceremony prepare-only (bump the inbound exact-pin, let the pipeline own publish) and label core/inbound CHANGELOG entries administrative.

### Key Lessons

1. Flip a phase's verification/UAT status when downstream work closes its deferred checks — don't leave `human_needed` as a trailing artifact for the milestone-close audit to trip over.
2. The leftover-phase-dir cleanup debt is now actively harming closeout accuracy (inflated CLI counts) — run `/gsd-cleanup` before the next milestone, not "later."
3. Anti-churn citation gates are worth the overhead on polish milestones; they are the difference between bounded design-system hardening and open-ended redesign.

---

## Milestone: v1.5 — Demo Evidence and Click-Around Confidence

**Shipped:** 2026-06-02
**Phases:** 4 | **Plans:** 8
**Coverage:** 14/14 v1.5 requirements

### What Was Built

- Separate `reference/demo_app` with local-path and published-Hex dependency modes, health-gated Compose startup, cache-aware browser setup, and deterministic reset proof.
- Deterministic Northstar B2B SaaS Ops corpus covering outbound deliveries, inbound records, suppressions, webhook targets, replay lineage, and six realistic preview mailer scenarios.
- Guided dashboard hub and canonical demo README that point maintainers into real preview, outbound operator, and inbound operator surfaces.
- Automated browser evidence lane: `mix verify.phase69` drives Playwright through the dashboard/preview/outbound/inbound paths and writes bounded `demo_browser_evidence.v1` checkpoint evidence.

### What Worked

- Keeping `reference/host_app` narrow while adding `reference/demo_app` avoided turning trust proof into a second product.
- The Phase 68 fixture corpus gave Phase 69 and 70 stable, realistic data to exercise instead of superficial route checks.
- Replacing human UAT with browser/docs automation closed subjective click-around checks without treating DOM shape as stable API.

### What Was Inefficient

- The milestone audit was run too early and went stale after Phases 68-70 landed, so closeout needed a manual audit refresh.
- Phase 70 became bookkeeping because its implementation work landed during Phase 69 automation, which required explicit reconciliation to avoid a phantom future phase.
- Validation files for Phases 68 and 69 stayed in draft wording after verification passed and had to be cleaned up during closeout.

### Patterns Established

- Rich demo apps should be adoption evidence artifacts with explicit non-contract boundaries.
- Browser evidence should click real mounted surfaces and emit bounded checkpoint artifacts, not promote selectors, routes, or copy as public API.
- A retained `HUMAN-UAT.md` can be closed as history when automated replacement evidence is recorded and passing.

### Key Lessons

1. Rerun the milestone audit after the last phase is reconciled, especially when a later phase closes work that landed in an earlier phase.
2. Keep demo proof tied to realistic domain stories; route-only smoke tests are not enough for adopter confidence.
3. If a phase becomes reconciliation-only, say so in the summary and verification artifact so closeout can distinguish it from missing implementation.

---

## Milestone: v1.4 — Inbound Stability Lock

**Shipped:** 2026-06-01
**Phases:** 4 | **Plans:** 12
**Coverage:** 13/13 v1.4 requirements

### What Was Built

- Semantics-first `mailglass_inbound` stable/testing/internal/deferred contract inventory.
- Package-owned inbound compiled-doc and docs-contract proof lane, delegated by root `mix verify.stability_contract`.
- Canonical inbound adoption, compatibility, operator, testing, and admin trust documentation with fail-closed drift checks.
- Explicit `mailglass_inbound` `1.0.0` candidate decision with aligned source, manifest, README/install pins, release notes, and publish-proof evidence.

### What Worked

- Keeping the milestone scoped to contract stability prevented provider, matcher, replay API, and synthetic UI expansion.
- The Phase 63 inventory gave Phase 64 and 65 a concrete contract taxonomy to enforce rather than re-litigating public surface boundaries.
- Phase 66 converted release posture from a judgment call into a binary evidence-backed decision.

### What Was Inefficient

- The first milestone audit was run before Phase 66 existed, so closeout needed a fresh inline audit after the phase landed.
- ROADMAP detail checkboxes for Phase 65 drifted from the executed summaries and had to be reconciled during archival.

### Patterns Established

- Stable means semantic contract, not module reachability or ExDoc visibility.
- Package-local support-contract lanes should own package-specific compiled-doc proof, with the root alias delegating.
- Candidate-version release truth must align across source, release manifest, README/install docs, changelog, and publish summary before closeout.

### Key Lessons

1. Run the milestone audit after the final release-position phase, not before it.
2. Public provider support should be documented through the stable plug/options seam, not provider module APIs.
3. Release-position decisions are clearer when they include both the selected path and the fallback path if a late blocker appears.

---

## Milestone: v1.3 — Adopter Trust Proof

**Shipped:** 2026-05-31
**Phases:** 7 | **Plans:** 18
**Coverage:** 16/16 v1.3 requirements

### What Was Built

- Maintained Phoenix reference host app with clean-checkout setup, public-seam-only integration, and explicit proof-scope contract.
- Deterministic `mix verify.reference_host.journey` runner with stable `trust_runner.v1` checkpoint evidence.
- Required repo-head and clean-baseline trust lanes, plus post-publish published-version trust proof for the current Hex release line.
- Reference-host and trust-entry documentation that routes guarantee semantics to canonical stability inventories and executable contract checks.

### What Worked

- The narrow proof-scope lock prevented reference-host work from expanding into a second product.
- Shared checkpoint semantics let local, CI, and release proof paths converge on one evidence contract.
- The Phase 62 gap closure was small and targeted because the previous phases had already isolated release-line truth from the rest of the workflow.

### What Was Inefficient

- Phase numbering had drifted from the original 53-56 roadmap snapshot, leaving STATE.md stale until closeout.
- Clean-baseline/published-version proof initially validated an older release line, which required an inserted closure phase before archive.

### Patterns Established

- Treat reference apps as usage proof artifacts, not public API contract sources.
- Version-specific Hex guards should be non-evaluating and fail closed on stale lock entries.
- Trust claims need both repo-head and published-version evidence before milestone close.

### Key Lessons

1. Release-line truth belongs in an executable guard, not prose or lockfile inspection by convention.
2. Documentation boundary enforcement is valuable when a reference app could otherwise imply accidental API guarantees.
3. Branch-protection trust lanes need live verification in the audit, not just workflow-file inspection.

---

## Milestone: v0.1 — Validation Release

**Shipped:** 2026-04-26 (v0.1.0 + v0.1.1 on Hex.pm)
**Phases:** 8 (7 planned + 1 inserted) | **Plans:** 61
**Timeline:** 2026-04-21 → 2026-04-26 (6 calendar days)
**Codebase:** ~33k LOC Elixir, 319 commits
**Coverage:** 84/84 v1 REQ-IDs

### What Was Built

- **Phase 1 — Foundation**: Zero-dep modules + pure-function HEEx renderer pipeline with MSO Outlook VML fallbacks; structured `Mailglass.Error` hierarchy; OptionalDeps gateway pattern; `Mailglass.Config` (NimbleOptions + `:persistent_term`); 4-level telemetry convention with PII whitelist.
- **Phase 2 — Persistence + Tenancy**: Append-only `mailglass_events` ledger with SQLSTATE 45A01 immutability trigger; multi-tenancy first-class on every schema; idempotency via partial UNIQUE; `Outbound.Projector` single-writer for Delivery projection columns; `SuppressionStore` behaviour + Ecto impl.
- **Phase 3 — Transport + Send Pipeline**: Fake adapter built first as merge-blocking release gate; full hot path (Mailable → preflight → render → Multi(Delivery + Event) → Adapter → Multi(Delivery update + Event)); Phoenix.Token-signed click rewriting; ETS rate limiter; tracking off by default with `NoTrackingOnAuthStream` lint enforcement.
- **Phase 4 — Webhook Ingest**: Postmark + SendGrid HMAC-verified, parsed to Anymail event taxonomy verbatim, written through one Ecto.Multi with replay-safe idempotency; orphan reconciliation worker; 1000-replay StreamData convergence property.
- **Phase 5 — Dev Preview LiveView**: `mailglass_admin` sibling package with mailable sidebar, `preview_props/0` auto-discovery, device + dark toggles, HTML/Text/Raw/Headers tabs; daisyUI 5 + Tailwind v4 with no Node toolchain required of adopters.
- **Phase 6 — Custom Credo + Boundary**: 12 domain-rule lint checks operationalizing engineering DNA at lint time; `boundary` enforcement of module hierarchy.
- **Phase 7 — Installer + CI/CD + Docs**: `mix mailglass.install` with idempotent `.mailglass_conflict_*` sidecars; golden-diff CI; full GHA pipeline (format, compile w/ warnings-as-errors, no-optional-deps lane, ExUnit, Credo strict, Dialyzer, docs); Release Please linked-versions; protected-ref Hex publish; ExDoc with 9 guides.
- **Phase 07.1 — Publish to Hex.pm (INSERTED)**: Closed installer blockers G-1..G-5 surfaced by milestone audit; v0.1.0 + v0.1.1 shipped to Hex.

### What Worked

- **Research-driven phase planning** for Phases 2, 4, 5 (the three flagged for `/gsd-research-phase`). The research output materially shaped plan structure — particularly Phase 2's `metadata jsonb` projection columns shape and Phase 4's SendGrid ECDSA on OTP 27 `:crypto` recipe.
- **Wave-based parallelization** within phases. Phase 3's 12-plan structure (5 original waves + 5 gap-closure plans) absorbed mid-wave credit exhaustion via cherry-pick recovery without losing the sequential commit history.
- **Fake adapter built FIRST as merge gate** (D-13). Every PR validated against Fake; real-provider sandbox tests stayed advisory-only on daily cron + `workflow_dispatch`. Discipline held all the way through to v0.1.1 ship.
- **Engineering DNA carried over from prior libs** (accrue/lattice_stripe/sigra/scrypath). Patterns that were 4-of-4 convergent (telemetry shape, error hierarchy, sibling packages, append-only ledger, OptionalDeps gateway) planned directly from synthesis without research delay.
- **Custom Credo checks built LAST (Phase 6) against real code** rather than first. Avoided the known time-sink of fighting an immature lint surface against immature library code.
- **Append-only ledger + idempotency partial UNIQUE** combo — the 1000-replay StreamData property test passed clean once the `inserted_at: nil` sentinel pattern was settled (UUIDv7 schemas client-autogenerate `id` before INSERT).
- **Boundary library** caught two cross-layer regressions during Phase 4 that would have shipped silently otherwise.

### What Was Inefficient

- **The v0.1.1 ship cycle surfaced 5 latent release-engineering bugs** that the v0.1.0 ship didn't catch:
  1. release-please's `extra-files` generic updater silently no-ops on a `mix.exs` already managed by the `elixir` release-type — discovered after two failed annotation attempts; fixed via workflow `sed` step.
  2. `publish-hex.yml`'s `workflow_run` gate `head_branch` startsWith check is dead code (head_branch is always `main`); manual `workflow_dispatch` was used for both v0.1.0 and v0.1.1.
  3. `post-publish-smoke.yml` has the same `head_branch` bug — VERSION resolved to literal `"main"`, so smoke timed out.
  4. Installer golden snapshots embed package version literals and were not regenerated as part of release-please's PR — recovery required force-moving v0.1.1 tags.
  5. `CLAUDE.md` leaks into HexDocs at https://hexdocs.pm/mailglass/claude.html (`mix.exs:262` extras).
- **Phase 5 + Phase 7 shipped without VERIFICATION.md** initially. Audit caught it; Phase 07.1 backfilled. Procedural gap, not substantive — but the audit's "missing VERIFICATION.md = blocker" rule is correct.
- **Wave 1 of Phase 3 spawned 5 parallel agents but credits ran out mid-wave**. Recovery was clean (cherry-pick from worktrees, restart 2 plans whose worktree work was incomplete) but cost a session.
- **Phase 7 admin_smoke_gate CI job matched zero tests for two ship cycles** (v0.1.0 + part of v0.1.1) before being noticed. Caught by audit; closed in 07.1-06 by adding `@tag :admin_smoke` tests.
- **Bare `mix test` citext-OID-cache race** when migration_test.exs runs concurrently with async tests. Worked around with `disconnect_on_error_codes` + per-test probe; full architectural fix deferred (Phase 6 deferred-items.md).

### Patterns Established

- **Decimal-phase insertion** for urgent post-roadmap work (Phase 07.1 to fix installer blockers + ship to Hex). Clean semantics: integer phases = planned, decimal = inserted.
- **Audit-fix-reaudit loop** before milestone close. v0.1 milestone audit at 2026-04-25 returned `gaps_found` (G-1..G-5); Phase 07.1 closed gaps; refreshed audit at close returned `passed`.
- **Repo write path SQLSTATE translation at exactly four sites** (`insert/2`, `update/2`, `delete/2`, `transact/1`). Single `translate_postgrex_error/2` defp is the one translation point. Pattern documented for future append-only schemas.
- **`Mailglass.Tenancy` public API as the only stamping path**. Raw `Process.put(:mailglass_tenant_id, …)` retired in Plan 02-04; `LINT-03 NoUnscopedTenantQueryInLib` enforces.
- **`:telemetry.span/3` directly when per-request enrichment needed; `Mailglass.Telemetry.execute/3` wrapper for closed-metadata calls**. The wrapper closes metadata at call time and cannot express enrichment — using it would regress Plan 04-04's deviation fix. Pattern documented in Plan 04-08.
- **Multi.run-then-Multi.run flat composition** for webhook ingest, NOT nested `Repo.multi` inside `Multi.run`. Nested form broke transaction scoping; flat form keeps everything in one transaction with correct rollback (Plan 04-06 revision W4).
- **Closed-atom-set reflectors on schemas** (e.g. `Event.types/0` returns the Anymail taxonomy + `:reconciled` internal). Pattern matches by struct + `__struct__` module comparison instead of literal `match?(%Mod{}, err)` to satisfy Elixir 1.19 type narrowing.

### Key Lessons

1. **Release Please's `extra-files` generic updater is fragile around release-type-managed files.** Document this for v0.1.2 fix; consolidate with the publish-hex.yml + post-publish-smoke.yml head_branch fix into a single tag-push trigger workflow.
2. **Audit-driven milestone close is non-negotiable.** The v0.1 audit caught installer blockers G-1..G-5 that would have shipped behind a green CI gate (the golden test fixture drove a simulated path, not real `Apply.run`). Re-running the audit BEFORE close, after fixes, is the loop that should be standardized.
3. **Procedural gaps (missing VERIFICATION.md) are real blockers in `/gsd-audit-milestone` even when the substantive verification is observable.** Don't skip the bookkeeping; it's the audit's only entry point for retroactive verification.
4. **Bleeding-edge floor (D-06) costs more than expected at the type-checker boundary.** Elixir 1.19 type narrowing forced `__struct__` comparison instead of literal struct pattern matching for error-type discrimination tests. Document the workaround once; expect more friction at every minor version.
5. **CLAUDE.md being shipped to HexDocs is a documentation hygiene smell.** Easy to fix; the embarrassment is a reminder that mix.exs `extras` deserves careful curation.
6. **Plan a "release engineering" mini-phase ahead of the FIRST Hex publish.** v0.1.0 + v0.1.1 both required manual `workflow_dispatch` because the auto-publish gate was dead code. Catching this before v0.1.0 would have saved an hour of recovery.

### Cost Observations

- **Cycle length**: 6 calendar days for 8 phases / 61 plans / ~33k LOC. High velocity sustained by GSD discipline.
- **Recovery overhead**: ~1 session lost to Wave 1 mid-wave credit exhaustion (Phase 3); ~30 min on each of 5 release-engineering bug recoveries during v0.1.1 ship.
- **Audit overhead**: 1 audit cycle (gaps_found → fix → passed). Worth it — caught installer blockers that would have shipped.
- **Phase research overhead**: Phases 2, 4, 5 research passes added value proportional to flag accuracy. Phases 1, 3, 6, 7 planned directly from synthesis without delay.

---

## Cross-Milestone Trends

*To be populated as future milestones complete.*
