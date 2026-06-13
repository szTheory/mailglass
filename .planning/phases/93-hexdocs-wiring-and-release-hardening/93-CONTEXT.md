# Phase 93: HexDocs Wiring and Release Hardening - Context

**Gathered:** 2026-06-13 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 93 wires all three packages to ship the sealed-flap brand on HexDocs with
their next natural release, and hardens the release pipeline so it can never
again cut a release from brand/planning-only commits.

This phase owns **HEXD-01, HEXD-02, RELH-01, RELH-02 only**. It does NOT:
- cut any Hex release (logo/favicon config rides the next natural release;
  HexDocs latency is an accepted, locked decision)
- redesign the brand book, change tokens, or touch logo artwork beyond adding
  `width`/`height` attributes required by ex_doc
- re-propagate brand to README / social / admin surfaces (Phase 92 owned those)
- edit `.planning/milestones/` archives (frozen)

The folder rename (Phase 91) and surface propagation (Phase 92) are complete;
all asset paths here reference the post-rename canonical `brandbook/`.
</domain>

<decisions>
## Implementation Decisions

### HexDocs logo/favicon wiring (HEXD-01)
- **D-01:** Wire `brandbook/assets/logo-mark.svg` as `logo:` and
  `brandbook/assets/favicon.svg` as `favicon:` in the `docs/0` config of all
  three packages. The square mark and 16-grid favicon are the only variants
  legible in ex_doc's 48×48 display area; the lockup / typemark / with-tagline
  variants are anti-recommended for `logo:`.
- **D-02:** Add explicit `width`/`height` **directly to the two canonical
  SVGs** — `brandbook/assets/logo-mark.svg` → `width="164" height="156"`
  (matching `viewBox="-12 32 164 156"`), `brandbook/assets/favicon.svg` →
  `width="16" height="16"` (matching `viewBox="0 0 16 16"`). Do NOT create
  ex_doc-only duplicate copies. Every existing embed
  (`brandbook/index.html`/`landing-page.html` `<img>` with its own `width=`,
  `<link rel="icon">`) overrides or ignores intrinsic size, and this honors the
  brand-audit rule "exact asset use, no per-package copies"
  (`brandbook/brand-audit.md`).
- **D-03:** Reference the assets via **relative paths into the canonical
  `brandbook/`** — root: `brandbook/assets/...`; `mailglass_admin` /
  `mailglass_inbound`: `../brandbook/assets/...`. No per-package copies. No
  change to any package's `:files` allowlist (ex_doc auto-copies `logo:` /
  `favicon:` into the doc output; the Hex tarball does not need the source).
- **D-04:** Add `favicon:` to **all three** packages — ex_doc 0.40.1 supports
  the `favicon:` option across the board (verified version-pinned).
- **D-05:** Accept the known tradeoff: `mix docs` from an unpacked Hex tarball
  alone cannot resolve `../brandbook/` — nobody builds docs that way for these
  packages (HexDocs ships the prebuilt output; docs are only ever built from
  the monorepo checkout).

### Release-safety & verification (HEXD-02)
- **D-06:** All mix.exs edits (and the SVG `width`/`height` additions) land as
  **`docs:` / `chore:` commits** — non-bumping under release-please defaults,
  so they propose no version bump and create no release PR. **This phase cuts
  no Hex release.** The wiring is inert on hexdocs.pm until each package's next
  natural release (accepted, locked: HexDocs latency).
- **D-07:** Verify with a **local `mix docs` build for each of the three
  packages**: confirm the logo and favicon appear in the generated
  `doc/assets/` output and that no new warnings are emitted.
- **D-08:** Wire against the **currently-locked ex_doc 0.40.1**. The pending
  dependabot bump to 0.40.3 (PR #77) is orthogonal — `logo:` / `favicon:`
  semantics are unchanged between those versions — and must not block this
  phase.

### RELH-01 — release-please path hardening
- **D-09:** Harden via an **enforced CI commit-type lint** (user-confirmed).
  The check fails any PR whose commits touch **only** brand/planning paths
  (`brandbook/`, `.planning/`, `prompts/`) while using a bump-triggering
  conventional-commit type (`feat`, `fix`, or a `!`/`BREAKING CHANGE`). This is
  reliably enforceable and does not depend on release-please supporting
  per-path exclusion for a root-located package.
- **D-10:** The researcher should still **confirm whether release-please offers
  a clean config-level path exclusion** for the root `"."` package; if a clean
  mechanism exists it may be adopted *in addition*, but the CI lint is the
  primary, committed mechanism (do not block RELH-01 on a config approach that
  may not exist). Root cause being hardened: the root `"."` package claims
  commits in EVERY path (proven twice in the 1.6.x incident — brandbook `feat`
  → core 1.6.0; `fix(inbound)` → core 1.6.2).

### RELH-02 — 1.6.x aftermath reconciliation
- **D-11:** **Investigate Hex live first, then reconcile** (user-confirmed).
  The in-repo state is internally consistent at **1.6.1/1.6.1/1.3.0** (manifest
  `.release-please-manifest.json`, all three `@version`, inbound pin
  `{:mailglass, "== 1.6.1"}`), but the release-state memory claims Hex shipped
  **1.6.2/1.6.2/1.3.1**, and **no `mailglass-v1.6.x` package tags exist
  locally** (only the `v1.6` milestone tag). Phase 93 must establish
  authoritative truth from Hex (`mix hex.info mailglass` / `mailglass_admin` /
  `mailglass_inbound`) before changing anything.
- **D-12:** Once truth is established: disposition the stale/unpublished 1.6.x
  tags (delete or document), bump the inbound exact-pin to the **released** core
  version via the established `fix(inbound):` dance, and correct the `.planning`
  release-state memory + docs to the final version truth.
- **D-13:** If the in-flight release train has **not settled** at execution
  time, **record the blocker** in the phase artifacts and stop short of
  guessing final version truth — do not force a reconciliation against an
  unsettled Hex state (roadmap-anticipated external dependency).

### the agent's Discretion
- Exact CI lint implementation form for RELH-01 (new workflow job vs. extending
  an existing one; shell/script vs. action), as long as it is an enforced
  required check covering the brand/planning path set.
- Exact `width`/`height` literal placement and attribute ordering in the SVG
  root elements, as long as values match each viewBox aspect.
- Exact `docs:` commit message wording and how many commits the wiring splits
  into.
- Tag-disposition method for RELH-02 (delete vs. annotate-and-document), chosen
  once Hex truth is known.

### Folded Todos
None — the pending "refresh outbound admin UI look and feel" todo is a
design-system follow-up, out of Phase 93 scope.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 93 goal, success criteria, the RELH-02
  external-dependency note, strict 91→92→93 sequencing.
- `.planning/REQUIREMENTS.md` — HEXD-01, HEXD-02, RELH-01, RELH-02 and the
  v1.10 scope locks (no Hex release cut by this milestone's commits).
- `.planning/STATE.md` — v1.10 current position, pre-settled decisions, locked
  HexDocs-latency decision.
- `.planning/PROJECT.md` — v1.10 milestone intent; D-19 brand-identity decision
  record (pointer-supersession bookkeeping).

### Pre-settled research (authoritative for mechanics)
- `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md` — §1 ex_doc
  0.40.1 `logo:`/`favicon:` semantics + SVG width/height gap + relative-path
  strategy; §2 release-please trigger safety (defaults, non-bumping commit
  types, the root-`"."`-claims-everything behavior).

### Brand assets and constraints
- `brandbook/assets/logo-mark.svg` — `logo:` source (viewBox-only today; add
  width/height).
- `brandbook/assets/favicon.svg` — `favicon:` source (viewBox-only today; add
  width/height).
- `brandbook/brand-audit.md` — "exact asset use, no broad brandbook inclusion"
  constraint that the no-copies path strategy satisfies.
- `.planning/milestones/v1.9-phases/87-logo-tournament/87-decision-record.md` —
  sealed-flap usage rules, C-15/C-16 (binding on every propagated surface).

### Release-engineering source files
- `release-please-config.json`, `.release-please-manifest.json` — current
  package config (root `"."` claims all paths) and recorded versions
  (1.6.1/1.6.1/1.3.0).
- `.github/workflows/release-please.yml`, `pr-title.yml`, `ci.yml` —
  trigger/path-filter behavior the RELH-01 lint must integrate with.
- `mailglass_inbound/mix.exs` (`@version`, `mailglass_dep/0` pin + the
  fix(inbound) comment) — the exact-pin dance for RELH-02.
- `mix.exs:355` / `mailglass_admin/mix.exs:214` / `mailglass_inbound/mix.exs:147`
  — the three `docs/0` configs to extend.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- All three `docs/0` private functions already exist; only `logo:`/`favicon:`
  keys are missing — additive change, no restructuring.
- `brandbook/assets/logo-mark.svg` (164×156) and `favicon.svg` (16×16) are the
  purpose-drawn small-format marks; both are outlined-path SVGs (LOGO-08), so
  ex_doc/Chromium font substitution is moot.
- The `fix(inbound):` exact-pin dance is documented in-repo
  (`mailglass_inbound/mix.exs` comment) and in release-engineering memory —
  reuse it verbatim for RELH-02.

### Established Patterns
- Non-release-triggering commit discipline (`docs:`/`chore:`/`test:`) is the
  standing v1.10 rule; release-please defaults make these non-bumping.
- ex_doc auto-copies `logo:`/`favicon:` into doc output → no `:files` allowlist
  churn (the publish-allowlist `*-files.expected` proofs stay untouched).
- The release pipeline self-heals several stuck-release modes
  (gate-ci-green CI-dispatch, hourly cron) — relevant background for RELH-02
  but not modified by this phase.

### Integration Points
- The RELH-01 CI lint plugs into the existing PR-gate workflow set
  (`pr-title.yml` already allowlists `docs`/`chore`; `ci.yml` `paths-ignore`
  covers `.planning/**` + `prompts/**`). The lint must run even on
  brand/planning-only PRs (which currently skip `ci.yml`) — placement matters.
- RELH-02 touches the live release manifest + inbound pin; sequence so the
  inbound pin bump rides a real `fix(inbound):` release, never a hand-edit that
  reds main (Pitfall: PRE-bumping the pin to an unpublished core).
</code_context>

<specifics>
## Specific Ideas

- The RELH-01 path set to guard: `brandbook/`, `.planning/`, `prompts/`
  (the dirs the v1.10 sweep proved are brand/planning-only and that the 1.6.x
  incident fired from).
- ex_doc version is pinned at **0.40.1** today; wire against it, ignore the
  in-flight 0.40.3 dependabot PR (#77) for this phase.
- SVG width/height values are fixed by existing viewBoxes: 164×156 (logo-mark),
  16×16 (favicon).
</specifics>

<deferred>
## Deferred Ideas

- Propagating the brand into HexDocs **extras/guides styling** beyond the logo
  (custom CSS, themed guide pages) — listed under REQUIREMENTS "Future
  Requirements", out of v1.10 scope.
- ex_doc 0.40.3 upgrade (dependabot #77) — orthogonal dependency bump, handled
  on its own PR track.
- Forcing a Hex release to make the new logo visible on hexdocs.pm sooner — the
  HexDocs-latency decision is locked; logos ride the next natural release.

### Reviewed Todos (not folded)
- `refresh outbound admin UI look and feel`
  (`.planning/todos/pending/2026-06-13-refresh-outbound-admin-ui-look-and-feel.md`)
  — design-system follow-up from Phase 92 human UAT; not HexDocs/release work,
  out of Phase 93 scope.
</deferred>
