# Phase 130: Supply chain + workflow hygiene - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning
**Source:** Synthesized from milestone decision-of-record (`.planning/research/milestone-cicd/SYNTHESIS.md`, LD-4/LD-11/LD-13) + ROADMAP + REQUIREMENTS. No separate discuss-phase round-trip — decisions are maintainer-locked at milestone open (2026-07-01).

<domain>
## Phase Boundary

Add supply-chain and workflow-hygiene guards that **never red an open PR under an unfixable-advisory wave** (the v1.14 self-inflicted-outage class), while making the release gate strict. Five slices, all CI/tooling — no library/product code:

1. **SUPPLY-01** — `mix deps.audit` (mix_audit) runs **advisory (non-blocking) on PR**, **blocking only at the publish gate**. A simulated unfixable advisory reds the publish gate but NOT open PRs.
2. **SUPPLY-02** — `dependabot.yml` watches the `mailglass_admin` and `mailglass_inbound` sibling locks (not the frozen `reference/` baselines).
3. **SUPPLY-03** — the cowlib allowlist gets a **forcing function**: OSV-staleness is a loud CI warning on every run + a hard block at publish, **fail-OPEN on OSV API outage**.
4. **SUPPLY-04** — `actionlint` gates `.github/workflows/**` changes on PR and fails a malformed workflow PR (+ dependency-review per LD-11).
5. **SUPPLY-05** — a latest-Elixir advisory row (1.19 / OTP 28) runs **non-blocking on push+cron only**, never blocks; the floor-coincidence invariant (LD-13) is documented.

**Out of scope:** any `lib/` change, the release cut itself (Phase 131), Dialyzer promotion (LD-7, gated on Phase 129 which is done but promotion is deferred to a deliberate later step).

## Current-state (verified 2026-07-01 — narrows the work)

- `.github/workflows/actionlint.yml` **already exists**: PR-triggered on `.github/workflows/*.yml|*.yaml` + `scripts/check_tests_gate.sh`, SHA-pinned `rhysd/actionlint@914e7df…` (v1.7.12), plus a Tests-gate check. SUPPLY-04's actionlint scaffolding is largely present — the gap is (a) confirming it fails a *malformed* workflow PR, and (b) whether dependency-review is wanted/added.
- `.github/workflows/advisory-matrix.yml` **already exists**: triggers on push+PR+cron+dispatch, matrix currently `elixir 1.18 / otp 27` only, with a REL-06 comment about the removed 1.17 row. SUPPLY-05 = add a `1.19 / OTP 28` row (advisory, and it should NOT run on PR — verify trigger scope) + document LD-13.
- `.github/dependabot.yml` currently watches only `mix` + `github-actions` at `directory: "/"`. SUPPLY-02 = add sibling directories for `mailglass_admin` + `mailglass_inbound`.
- `lib/mix/tasks/mailglass.publish.check.ex` owns `@accepted_advisories` (lines ~60-64: two cowlib advisory IDs) and the hex.audit gate (~line 1052-1102). SUPPLY-01/03 hook the publish gate here.
- `mix_audit` is **not currently a dependency** (grep found no `:mix_audit` dep, no `deps.audit` alias) — it must be added.

</domain>

<decisions>
## Implementation Decisions (all LOCKED — from SYNTHESIS.md)

### SUPPLY-01 — mix_audit advisory-on-PR, blocking-at-release (LD-4)
- Add `mix deps.audit` as an **advisory (non-blocking) PR lane** — it must NEVER red an open PR. Rationale: required-blocking on every PR would, under a v1.14-style unfixable transitive CVE, red every open PR across all three packages until a maintainer allowlists — a self-inflicted outage for a quiet-maintenance lib.
- Block **only at the publish gate** (`publish.check`, which already owns the allowlist lifecycle).
- A simulated unfixable advisory must red the publish gate but NOT open PRs (this is a testable success criterion).

### SUPPLY-02 — dependabot sibling coverage
- `dependabot.yml` adds `mix` ecosystem entries for the `mailglass_admin` and `mailglass_inbound` sibling directories (their own `mix.lock`s), NOT the frozen `reference/` baseline apps (those are deliberately pinned — see the reference-baseline-coupling constraint).

### SUPPLY-03 — cowlib OSV-staleness forcing function (LD-4)
- The cowlib allowlist entries in `@accepted_advisories` get a forcing function so a stale allowlist is noticed: **loud CI warning on every run** + a **hard block at publish** if the advisory is no longer present in OSV (i.e., upstream fixed it and the allowlist should be removed).
- **Fail-OPEN on OSV API outage** — a third-party blip must never block a security *patch* or the pipeline.

### SUPPLY-04 — actionlint on workflow PRs (LD-11)
- `actionlint` gates `.github/workflows/**` changes on PR and fails a malformed workflow PR. (Scaffolding exists — close the gap + verify.)
- Add dependency-review on workflow/dep PRs per LD-11 ("actionlint + dependency-review are highest-leverage").
- All third-party actions **SHA-pinned** (project non-negotiable; Dependabot watches `.github/workflows/`).

### SUPPLY-05 — latest-Elixir advisory row + floor-coincidence invariant (LD-13)
- Add a `1.19 / OTP 28` advisory matrix row that runs **non-blocking, push+cron only** (never on PR, never blocking).
- Document the **floor-coincidence invariant (LD-13)**: declining a *min-supported* floor row is correct TODAY because required-pin == declared-floor == 1.18 (REL-06 precedent). The written invariant: **whenever the required pin advances past 1.18, either add a 1.18 floor row to the required lane or raise the declared `elixir:` floor** — never let the tested version outrun the declared `~> 1.18`.

### Cross-cutting method
- Every phase pushes a `phase/NN` branch and requires green CI (dogfood the v1.14 post-mortem fix) so the release ceremony (Phase 131) is a confirmation, not a discovery. Simulated-advisory tests should prove the PR-vs-publish asymmetry without needing a real CVE.

### Claude's Discretion
- Exact mix_audit dep version (latest on Hex), alias wiring, and which package(s) get the advisory lane.
- OSV-staleness check implementation shape (script vs inline in publish.check; OSV API vs `mix hex.audit` cross-check) — as long as it satisfies loud-warn-always / block-at-publish / fail-open.
- dependency-review action choice + SHA pin.
- Whether the advisory row lives in `advisory-matrix.yml` (likely) or a new workflow.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Decision-of-record (authoritative — wins over dossiers)
- `.planning/research/milestone-cicd/SYNTHESIS.md` — LD-4 (mix_audit + OSV advisory-on-PR/block-at-release), LD-11 (actionlint + dependency-review), LD-13 (floor-coincidence invariant). §0 ground-truth corrections; §2 adoption sequence.
- `.planning/research/milestone-cicd/CICD-RELEASE-HARDENING.md` — raw release-eng dossier (version/line-stale; SYNTHESIS wins on conflict).

### Live files this phase edits
- `.github/dependabot.yml` — add sibling `mix` directories (SUPPLY-02).
- `.github/workflows/advisory-matrix.yml` — 1.19/OTP28 row + trigger scoping (SUPPLY-05).
- `.github/workflows/actionlint.yml` — existing; close SUPPLY-04 gap + dependency-review.
- `.github/workflows/ci.yml` — advisory mix_audit PR lane (SUPPLY-01).
- `lib/mix/tasks/mailglass.publish.check.ex` — `@accepted_advisories` (~60-64), hex.audit gate (~1052-1102): publish-time mix_audit block + OSV-staleness forcing function (SUPPLY-01/03).
- `mix.exs` — add `:mix_audit` dep + alias.

### Requirements + roadmap
- `.planning/REQUIREMENTS.md` — SUPPLY-01..05 (lines 85-98).
- `.planning/ROADMAP.md` — Phase 130 section (line 207+).

### Constraints to respect
- `~/.claude/projects/-Users-jon-projects-mailglass/memory/project_reference_baseline_coupling.md` — `reference/` apps are frozen; dependabot must NOT watch them.
- CLAUDE.md — all third-party GitHub Actions SHA-pinned; publish only from protected ref; brand-voice error messages.

</canonical_refs>

<specifics>
## Specific Ideas

- The whole phase is a hedge against the **v1.14 advisory-wave outage**: the design invariant is "a supply-chain guard must never red an *open PR* under an unfixable transitive CVE; it may only red the *publish gate*." Every SUPPLY item is measured against that.
- OSV-staleness "forcing function" mirrors the same latent-staleness class SYNTHESIS.md flags for cache keys and sed anchors — the goal is that an allowlist entry can't silently outlive its upstream advisory.
- SUPPLY-04/05 are partly scaffolded already — expect the plans to be smaller than the ROADMAP prose implies; the researcher should quantify the true delta.

</specifics>

<deferred>
## Deferred Ideas

- Dialyzer / format / credo / compile-warnings promotion to *required* (LD-7) — deliberately deferred, not part of Phase 130.
- The real Hex release cut + consumer/post-publish smoke (LD-1) — Phase 131.
- `deps.unlock --check-unused` orphaned-transitive cleanup (castore, unicode_util_compat) — deferred follow-up noted in Phase 128 decisions.

</deferred>

---

*Phase: 130-supply-chain-workflow-hygiene*
*Context synthesized: 2026-07-01 from SYNTHESIS.md decision-of-record*
