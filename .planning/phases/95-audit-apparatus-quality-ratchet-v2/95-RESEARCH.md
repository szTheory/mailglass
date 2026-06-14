# Phase 95: Audit Apparatus + Quality-Ratchet v2 — Research

**Researched:** 2026-06-13
**Domain:** Quality-ratchet apparatus — ExUnit score-baseline gate, GAP register schema,
Playwright structural assertions, LLM-scored PNG matrix
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Canonical 6-pillar rubric is the **project's own** `design-system.md:104-121`
  set — **Spacing / Radius / Color / Type / Elevation / Motion+A11y** — NOT the generic
  `gsd-ui-review` pillars. The `gsd-ui-review` grade scale is the *method*; the D-01
  pillars are the *rubric target*.
- **D-02:** Fresh GAP register at `.planning/RATCHET-GAP-REGISTER.md` (milestone-root),
  IDs restart at **GAP-01**. v1.7 `74-GAP-REGISTER.md` is frozen — do NOT migrate or reopen.
  Schema = v1.7 columns + `status` / `run_id` / `first_seen_run`. Idempotent re-run semantics
  active from Phase 103; stable IDs are the join key.
- **D-03:** Committed baseline at `mailglass_admin/docs/ui-baseline-scores.json`, keyed
  `surface → pillar → theme → score`. Single agreed path — ExUnit reader, harness output,
  and gitignore must all agree.
- **D-04:** Meet-or-beat assertion is a **fail-closed ExUnit test**
  (`ratchet_baseline_test.exs`) in the always-run required `verify.support_contract.admin`
  lane — mirroring `token_parity_test.exs`. Pure file I/O + Jason; no Postgres/Node/Playwright.
- **D-05:** First-run = establish-and-freeze. This phase validates shape/range/coverage.
  Meet-or-beat regression teeth turn on at Phase 103. Test must NOT be a vacuous no-op.
- **D-06:** New `structural.spec.js` wired into the existing **`operator_browser_gate`**
  lane (ci.yml:645-716). No new harness. Node in dev harness only — excluded from Hex tarball.
- **D-07:** LLM scoring is **maintainer-run local**, not CI. Screenshots from existing
  `ui-audit.sh` (18 cells). Only JSON committed; PNGs gitignored.
- **D-08:** Commit order: (1) GAP register file → (2) ExUnit baseline assertion → (3)
  Playwright structural spec → (4) seed run. Every commit green.

### Claude's Discretion

- Exact GAP register markdown layout + whether citation/idempotency check is a shell
  script vs ExUnit checker vs documented review rule.
- Exact ExUnit test name/module and score scale/range.
- Exact Playwright assertion selectors + accent-allowlist expression.
- LLM scoring invocation shape (mix/script wrapper vs GSD subagent).

### Deferred Ideas (OUT OF SCOPE)

- Gallery-cell structural + LLM-score cells (Phase 97 builds the gallery).
- Meet-or-beat regression enforcement + sev-4/5 closeout + reopen/skip re-run (Phase 103).
- Hard-flip of advisory typography/tracking gates (Phases 98/99, per Phase 94 D-08).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RATCHET-01 | Committed score baseline keyed `component × pillar × theme`; `gsd-ui-review` grade per cell; closeout asserts meet-or-beats prior value | JSON shape, score range, ExUnit assertion structure, graded cell count |
| RATCHET-02 | Carried-forward GAP register: stable `GAP-NN` IDs, status/run_id columns, idempotent reopen/skip, anti-churn sev≥3 citation gate | Schema, column shape, citation-gate implementation choice |
| RATCHET-04 | Playwright structural assertions on 6 machine-checkable facts; wired into `operator_browser_gate` | Concrete assertion recipe per fact, accent-allowlist expression, current-state risk flags |
| RATCHET-05 | LLM-scored 18-cell PNG matrix against 6-pillar rubric; committed baseline JSON; PNGs gitignored | Screenshot-to-scoring pipeline, harness invocation, gitignore coverage |
</phase_requirements>

---

## Summary

Phase 95 is a pure apparatus-standup phase: no UI markup is changed; the surfaces are
measured, not fixed. Four layers of tooling are built in commit-ordered sequence so that
every commit is green, the apparatus validates itself on first run, and downstream phases
(97–102) can cite the resulting GAP register and the Phase 103 re-run can assert score
improvement without a test rewrite.

The critical architectural insight is that **two intentionally different grids exist**: the
PNG evidence grid (`surface × viewport × theme`, 18 cells) and the score-baseline grid
(`surface × pillar × theme`, 36 cells). These must be kept distinct and their relationship
documented. The ExUnit assertion establishes and validates the 36-cell graded shape now;
the meet-or-beat comparison across runs turns on at Phase 103.

The project already has all the raw materials: `ui-audit.sh` produces the 18 PNGs,
`operator.spec.js` has every Playwright pattern needed, `token_parity_test.exs` is the
exact ExUnit template, and `74-GAP-REGISTER.md` provides the proven register column shape.
Phase 95 assembles these into the ratchet apparatus rather than inventing anything new.

**Primary recommendation:** Follow D-08 commit order strictly. The apparatus must be green
at every step so the seed run in commit 4 can fail informatively (gap rows populated) rather
than failing structurally. Use a documented review rule (not a script) for the citation gate
so Phase 103 can validate by human review; the Playwright structural spec is the machine
gate that replaces the citation-script need.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Score baseline storage | File/Docs layer | — | JSON file in `docs/`; consumed by ExUnit at test time, no runtime component |
| Meet-or-beat assertion | ExUnit test suite | CI required lane | Pure file I/O — no DB or browser; fits the `verify.support_contract.admin` pattern |
| GAP register | Planning artifact (`.planning/`) | Human review | Cross-phase markdown artifact; not code, not tested by machine |
| Anti-churn citation gate | Documented review rule | PR process | Machine-checkable only at PR review; no script adds value here (see rationale below) |
| Playwright structural facts | Browser test (`operator_browser_gate`) | CI required lane | Facts require a running server + real DOM; Playwright is the right layer |
| LLM scoring + PNG capture | Local maintainer step | GSD subagent | Non-deterministic pixels; D-07 bans CI promotion; agent-browser + scoring prompt |
| gitignore coverage | Root `.gitignore` + admin `.gitignore` | — | `tmp/ui-audit/` covered by `/tmp/` rule in both; JSON path must NOT be under tmp/ |

---

## Standard Stack

### Core (no new packages required)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Jason | ~> 1.4 (already dep) | Parse `ui-baseline-scores.json` in ExUnit | Already in `mix.exs` deps (unrestricted `:only`); same pattern as `token_parity_test.exs` |
| Playwright | existing (Node 22 harness) | `structural.spec.js` assertions | Already in `operator_browser_gate` lane; no new install |
| ExUnit | built-in | `ratchet_baseline_test.exs` | Project standard; mirrors `token_parity_test.exs` shape |

[ASSUMED] No new Hex or npm packages are required. The existing `jason`, Playwright, and
ExUnit cover all four layers.

### Supporting (dev-harness tools, not shipped)

| Tool | Purpose | Node/Hex | Hex-tarball excluded? |
|------|---------|---------|----------------------|
| agent-browser CLI | Screenshot capture for `ui-audit.sh` | external binary | N/A (not a dep) |
| `mailglass_admin.assets.build` | Bundle rebuild for bundle-clean gate | Mix task (existing) | Dev/test only |

### Installation

No new packages. All existing deps are sufficient.

---

## Package Legitimacy Audit

> No new packages are installed in this phase. The entire apparatus runs on existing deps
> (Jason, Playwright, ExUnit). Package Legitimacy Gate does not apply.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Maintainer run (local, ad-hoc)
  ui-audit.sh
    └─ agent-browser screenshots → tmp/ui-audit/{surface}-{vp}-{theme}.png (gitignored)
         └─ LLM scoring subagent (D-01 pillars as rubric)
              └─ mailglass_admin/docs/ui-baseline-scores.json  ◄── COMMITTED
                                          │
                        ┌─────────────────┘
                        │
                        ▼
CI: verify.support_contract.admin
  ratchet_baseline_test.exs
    ├─ reads ui-baseline-scores.json
    ├─ validates shape (36 cells present)     ← Phase 95: ESTABLISH-AND-FREEZE
    ├─ validates score range (1–4 per cell)
    └─ meet-or-beat comparison               ← Phase 103: REGRESSION TEETH

CI: operator_browser_gate
  structural.spec.js
    ├─ /ops/mail (Deliveries/Operator surface)
    ├─ /ops/mail/inbound (Inbound surface)
    └─ /dev/mail (Preview surface)
         └─ 6 fact assertions per surface (ARIA, focus, touch, font-weight, accent, motion)

.planning/RATCHET-GAP-REGISTER.md  (milestone-root, human-maintained)
    ├─ GAP-01..NN rows from Phase 95 first run
    └─ anti-churn citation gate (Phase 98–103 PRs must cite sev≥3 row)
```

### Recommended Project Structure

```
mailglass_admin/
├── docs/
│   └── ui-baseline-scores.json          # D-03: committed graded baseline
├── e2e/
│   ├── operator.spec.js                 # existing — NOT modified
│   └── structural.spec.js              # NEW: 6-fact structural assertions
└── test/mailglass_admin/
    └── ratchet_baseline_test.exs        # NEW: D-04/D-05 shape+range assertion

.planning/
└── RATCHET-GAP-REGISTER.md             # D-02: milestone-root, fresh at GAP-01
```

---

## Key Design Decisions — Resolved

### 1. Graded cell count: 36 cells (not 18)

The **PNG evidence matrix** is `surface × viewport × theme`: 3 × 3 × 2 = **18 PNGs** (what
`ui-audit.sh` produces). These are the raw evidence used to inform scores.

The **score baseline JSON** (D-03) is `surface × pillar × theme`: 3 × 6 × 2 = **36 graded
cells**. The LLM scorer examines all viewport PNGs for a given `surface/theme` pair and
assigns ONE score per pillar. Multiple viewports inform one pillar score — they are the
evidence, not independent graded cells.

[VERIFIED: design-system.md:104-121, CONTEXT.md D-07 explicit reconciliation]

**Surfaces (3):** `deliveries` (Operator `/ops/mail`), `inbound` (`/ops/mail/inbound`),
`preview` (`/dev/mail`)

**Pillars (6):** Spacing, Radius, Color, Type, Elevation, Motion+A11y

**Themes (2):** light, dark

**Total graded cells: 36**

### 2. Score range: 1–4 (aligned with `gsd-ui-review` grade scale)

The `gsd-ui-review` workflow uses a 4-point scale per pillar (Score: N/4 per pillar in
the summary table). [VERIFIED: ~/.claude/get-shit-done/workflows/ui-review.md:122-131]

The ratchet baseline should use the same 1–4 integer scale (1 = severe / non-conformant;
4 = excellent / fully on-brand) to be comparable to the `gsd-ui-review` method output.
This makes Phase 103 meet-or-beat semantics natural: score must be >= prior committed score.

**JSON schema for `ui-baseline-scores.json`:**

```json
{
  "run_id": "2026-06-13-phase-95-baseline",
  "schema_version": 1,
  "pillar_rubric": "design-system.md:104-121",
  "grade_scale": "1-4 (1=non-conformant, 2=significant-gaps, 3=mostly-conformant, 4=excellent)",
  "surfaces": {
    "deliveries": {
      "Spacing": { "light": 3, "dark": 3 },
      "Radius":  { "light": 4, "dark": 4 },
      "Color":   { "light": 3, "dark": 2 },
      "Type":    { "light": 2, "dark": 2 },
      "Elevation": { "light": 3, "dark": 3 },
      "Motion+A11y": { "light": 3, "dark": 3 }
    },
    "inbound": { ... },
    "preview": { ... }
  }
}
```

(Actual scores filled in by the LLM scoring step in commit 4 of D-08.)

**ExUnit shape assertion (Phase 95 — establish-and-freeze):**

```elixir
@surfaces ["deliveries", "inbound", "preview"]
@pillars  ["Spacing", "Radius", "Color", "Type", "Elevation", "Motion+A11y"]
@themes   ["light", "dark"]
@valid_scores 1..4

test "ui-baseline-scores.json has all 36 cells with scores in range 1-4" do
  # Assert 3 surfaces × 6 pillars × 2 themes = 36 cells present, each 1-4
  ...
end
```

**Phase 103 adds:** load the prior committed baseline, assert `new_score >= prior_score`
per cell. The function is extracted in Phase 95 as a separate private `compare_baselines/2`
that raises if any cell regresses — Phase 103 only calls it.

### 3. GAP register schema

[VERIFIED: 74-GAP-REGISTER.md:26-36 column precedent, CONTEXT.md D-02]

New columns added beyond the v1.7 shape:

| Column | Description |
|--------|-------------|
| `GAP-NN` | Stable ID — never renumber (starts at GAP-01 in this new file) |
| `surface` | deliveries / inbound / preview / all |
| `component:line` | Path relative to `mailglass_admin/lib/` and line number |
| `pillar` | One of the 6 D-01 pillars |
| `sev` | 1–5 (severity rubric — same as v1.7) |
| `evidence PNG` | `tmp/ui-audit/{surface}-{vp}-{theme}.png` (gitignored path reference) |
| `fix sketch` | Concise implementation direction |
| `status` | `open` / `fixed` / `downgraded` |
| `run_id` | Run that first opened / last touched this row |
| `first_seen_run` | Run ID of initial discovery |

**Anti-churn gate implementation: documented review rule (not a script).**

Rationale: The citation check is structurally identical to "did the PR author cite a row?",
which is a human-readable PR description check. A shell script would need to parse arbitrary
commit messages or PR bodies — brittle and adds no value that a PR template + reviewer
checklist doesn't provide more reliably. The Playwright structural spec provides the
machine-checkable gate; the register provides the citation anchor. This mirrors the v1.7
precedent exactly: the anti-churn contract in `74-GAP-REGISTER.md:17-22` was a documented
rule, not a script. The RATCHET-GAP-REGISTER.md header should reproduce the rule verbatim.

**Validate by running it:** during Phase 103 closeout, the maintainer reviews each sev-4/5
row to confirm it has been fixed or downgraded. This is the idempotent reopen/skip logic:
a re-run that finds a regression on a row marked `fixed` reopens it; a row already `open`
with the same finding is skipped (no duplicate rows). This logic is documented in the
register header and validated by the maintainer during the Phase 103 re-run step.

### 4. Playwright structural spec: concrete assertion recipe

[VERIFIED: operator.spec.js patterns, playwright.config.cjs boot mechanism]

**File:** `mailglass_admin/e2e/structural.spec.js`
**Lane:** `operator_browser_gate` (ci.yml:645-716) — picked up automatically because
`playwright.config.cjs` sets `testDir: "./e2e"` which glob-matches all `*.spec.js` files.
No change to `playwright.config.cjs` or `ci.yml` needed.

**The 3 surfaces and their boot paths:**

```js
// Operator / Deliveries surface
await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=...`);
await page.goto(`/ops/mail?tenant_id=browser-tenant`);

// Inbound surface
await page.goto(`/ops/mail/inbound?tenant_id=browser-tenant`);

// Preview surface — empty state via test route (per existing operator.spec.js:301)
await page.goto(`/ops/browser-preview-empty`);
```

**Assertion recipe per fact:**

#### Fact 1: ARIA roles/states
```js
// Pattern from operator.spec.js:56-57
await expect(page.getByTestId("operator-delivery-row").first())
  .toHaveAttribute("aria-selected", "true");  // after click
await expect(page.getByRole("dialog"))
  .toHaveAttribute("aria-modal", "true");      // when modal open
await expect(page.getByRole("navigation")
  .getByRole("link", { current: true }))
  .toHaveAttribute("aria-current", "page");
```

#### Fact 2: ≥44px touch targets
```js
// Pattern from operator.spec.js:45-50 (boundingBox)
const box = await page.getByRole("button").first().boundingBox();
expect(box).not.toBeNull();
expect(box.height).toBeGreaterThanOrEqual(44);
// Assert on nav links, primary CTAs, and row click targets
```

#### Fact 3: font-weight ∈ {400, 700}
```js
// Pattern from operator.spec.js — getComputedStyle variant
const weight = await page.locator("body").evaluate(
  el => getComputedStyle(el).fontWeight
);
expect(["400", "700"]).toContain(weight);
// Spot-check heading, body, label elements across each surface
```

#### Fact 4: reduced-motion collapses durations
```js
// Pattern from operator.spec.js:229 — emulateMedia BEFORE navigation
await page.emulateMedia({ reducedMotion: "reduce" });
// After page load, verify animated elements are not stuck invisible
// The existing reduced-motion test is the precedent; structural.spec.js
// extends it to all 3 surfaces
```

#### Fact 5: visible focus rings
```js
// No precedent in operator.spec.js — new in structural.spec.js
const link = page.getByRole("link").first();
await link.focus();
const outline = await link.evaluate(
  el => getComputedStyle(el).outline
);
// Assert outline is not "none" and not "0px none rgb(0,0,0)"
expect(outline).not.toBe("0px none rgb(0, 0, 0)");
expect(outline).not.toMatch(/^none/);
```

#### Fact 6: accent-only-on-allowlist
```js
// Accent color (Glass #277B96) should appear only on allowlisted selectors.
// Allowlist (from design-system.md:51-54):
//   - selected-row border
//   - primary CTA (button.btn-primary)
//   - active nav node
//   - focus emphasis (outline/ring)
//
// Assertion strategy: query ALL elements, compute their color/background-color,
// flag any element that has the accent hex and is NOT on the allowlist.
// Use CSS selector approach rather than exhaustive DOM walk:
const ACCENT_LIGHT = "rgb(39, 123, 150)";  // Glass #277B96
const allowlistedSelectors = [
  "[aria-selected='true']",
  ".btn-primary",
  "[aria-current='page']",
  ":focus-visible",
];
// For each non-allowlisted element bearing the accent color: test fails.
// Implementation: structural.spec.js checks a curated set of elements
// (not full DOM walk) — nav links, body text, cards, dividers — and
// asserts none resolve to the accent color.
```

**Risk flags — facts that may currently fail on the live surfaces:**

| Fact | Risk | Recommendation |
|------|------|----------------|
| Font-weight | `text-xl` violations (Phase 94 D-08 advisory gates) may synthesize incorrect weights | Assert at the body/paragraph level rather than on heading elements with known violations; flag the violation as a GAP row |
| Accent-only-on-allowlist | Phase 94 fixed the border/card accent bug; accent should now be confined — LOW risk of failure post-94 | Assert; if it fails, record as GAP |
| Focus rings | Not uniformly enforced in current components (GAP candidate) | Assert; failure populates a GAP row, does not block Phase 95 gate (the apparatus is measuring, not requiring perfection) |
| ARIA roles | Existing suite already asserts `aria-selected`, `aria-current` — HIGH confidence these pass | Assert; these are likely green |
| Touch targets | Nav links and primary buttons likely ≥44px; dense timeline rows may not be | Assert primary interactive targets; record any failures as GAP rows |
| Reduced-motion | Existing test covers delivery detail pane; structural.spec.js extends to all 3 surfaces | Assert; existing test green → HIGH confidence |

**Critical gate decision:** structural assertions must be written to pass NOW (measuring
current-state fact, not requiring perfect conformance). Facts that reveal genuine violations
should PASS the structural spec assertion (because the apparatus is recording a baseline, not
requiring pre-fix perfection) while generating GAP rows.

**Exception:** machine-checkable facts that are binary and whose violations are pre-existing
known regressions (e.g. a button with height=28px) should still fail the assertion — the
structural spec IS the regression gate. The planner must decide whether each fact assertion
is "fail-only-on-new-regression" or "fail-on-any-violation" for each fact.

Recommended split:
- ARIA roles/states: fail-on-any-violation (these are correctness facts, not aesthetic)
- ≥44px touch targets: fail-on-any-violation for PRIMARY interactive elements; advisory note GAP for dense-list rows
- font-weight: fail-on-any-violation (400/700 is binary)
- reduced-motion: fail-on-any-violation
- visible focus rings: fail-on-any-violation (a11y)
- accent-only-on-allowlist: fail-on-any-violation (post-94 this should be clean)

### 5. LLM scoring harness

[VERIFIED: ui-audit.sh:1-18, CONTEXT.md D-07, design-system.md visual audit loop]

**Invocation shape (recommended: GSD subagent, not a Mix task).**

A scoring GSD subagent invoked by the maintainer is the right shape because:
- It has multimodal capability to read the 18 PNGs
- It can apply the D-01 pillar rubric as a structured scoring prompt
- The output is a structured JSON that maps directly to D-03
- No Mix task infrastructure needed (no Elixir subprocess that calls Claude API)

**Step-by-step scoring procedure (to be documented in RATCHET-GAP-REGISTER.md header):**

```bash
# 1. Boot the reference demo (with seed data)
cd reference/demo_app
mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs
mix phx.server &  # binds port 4015

# 2. Capture 18 PNGs
mailglass_admin/scripts/ui-audit.sh
# Output: tmp/ui-audit/{surface}-{vp}-{theme}.png (18 files)

# 3. LLM scoring — maintainer hands PNGs to a multimodal model subagent
# with the 6-pillar rubric (design-system.md:104-121) and the 1-4 grade scale.
# Prompt structure:
#   For each surface × theme pair (6 pairs):
#     - Supply the 3 viewport PNGs (390, 768, 1440)
#     - Score each of the 6 pillars 1-4
#     - Cite specific evidence for scores < 4 (these become GAP rows)

# 4. Write scores to JSON
# mailglass_admin/docs/ui-baseline-scores.json (D-03 path)

# 5. Commit JSON (NOT the PNGs — they remain in gitignored tmp/ui-audit/)
git add mailglass_admin/docs/ui-baseline-scores.json
```

**gitignore coverage (verified):**

- `tmp/ui-audit/` is covered by `/tmp/` rule in BOTH root `.gitignore` (line 14) and
  `mailglass_admin/.gitignore` (line 11). [VERIFIED: .gitignore read]
- `mailglass_admin/docs/ui-baseline-scores.json` is under `docs/` which is in the
  `package[:files]` whitelist in `mix.exs` — it IS committed. No gitignore change needed.
- The PNG path convention (`tmp/ui-audit/`) is durable; `ui-audit.sh` uses `$OUT` which
  defaults to `tmp/ui-audit` (line 37).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Score range validation | Custom range-check logic | ExUnit `assert score in 1..4` + `Enum.reduce` | Already how `token_parity_test.exs` collects all mismatches before asserting |
| Citation-gate enforcement | Shell script parsing commit messages | Documented review rule in register header | Message parsing is brittle; human PR review is the correct layer |
| Screenshot capture | Custom Playwright screenshot spec | Existing `ui-audit.sh` (agent-browser) | Already works; do NOT duplicate with a Playwright screenshot loop in CI |
| Hex-tarball exclusion for PNGs | Custom Mix packaging rule | Existing `/tmp/` gitignore rule | PNGs are in `tmp/`; `mix.exs :files` already excludes `tmp/` |

**Key insight:** Every tool needed already exists in this codebase. Phase 95 is assembly, not invention.

---

## Common Pitfalls

### Pitfall 1: Confusing the 18-cell PNG grid with the 36-cell scored grid
**What goes wrong:** Planner writes ExUnit assertions for 18 cells (surface×viewport×theme)
instead of 36 cells (surface×pillar×theme).
**Why it happens:** The phrase "18-cell matrix" appears in requirements but refers to the
PNG evidence grid, not the scored baseline.
**How to avoid:** CONTEXT.md D-07 explicitly reconciles these: PNGs = evidence capture
(18), JSON baseline = graded (36). Keep separate, document the link.
**Warning signs:** JSON schema has a `viewports` key instead of a `pillars` key.

### Pitfall 2: Making the Phase 95 ExUnit test a vacuous no-op
**What goes wrong:** Test passes trivially because there is no prior baseline to compare
against, so the assertion does nothing.
**Why it happens:** "First run = nothing to beat" is misread as "test passes on any input."
**How to avoid:** D-05 explicitly forbids a vacuous no-op. The Phase 95 assertion MUST
validate shape (all 36 cells present), range (scores 1–4), and schema_version. These are
real assertions that can fail.
**Warning signs:** Test body is `assert true` or `assert length(scores) > 0`.

### Pitfall 3: Playwright structural.spec.js picks up by glob but needs the server to start
**What goes wrong:** `structural.spec.js` is picked up by `testDir: "./e2e"` automatically,
but the `webServer` boot in `playwright.config.cjs` has a 300s timeout (line 36) —
adequate for the existing tests but a risk if structural spec adds new server-state setup.
**How to avoid:** Re-use the existing `openOperator` helper (or equivalent) for the 3
surfaces. Do NOT add a new server or database reset path — the existing
`/ops/browser-reset` + `/ops/browser-login` route handles it.
**Warning signs:** `structural.spec.js` imports a new server fixture or calls `mix run`
directly.

### Pitfall 4: Font-weight assertion fails on computed system font fallback
**What goes wrong:** `getComputedStyle(el).fontWeight` returns `"400"` even when
`font-medium` is applied because the font-face fallback normalizes weights.
**Why it happens:** If Inter (the brand font) is not loaded in the test browser,
the system font may not have 500/600 variants, causing the browser to round to 400.
**How to avoid:** Assert the CSS property `fontWeight` on elements known to have
`font-bold` applied (should return `"700"`) and on body text (should return `"400"`).
Do NOT assert `"500"` or `"600"` will be absent from computed styles in this way —
assert the elements that SHOULD be 400 or 700 ARE 400 or 700.

### Pitfall 5: Accent-allowlist assertion catches legitimate dark-mode accent use
**What goes wrong:** The assertion flags legitimate accent use (e.g. the theme-toggle
button SVG fill, the active nav item underline) as non-allowlist violations.
**Why it happens:** The allowlist is defined in CSS class terms but computed styles
return RGB values — it's easy to miss an allowlisted element.
**How to avoid:** Define the allowlist as CSS selectors checked BEFORE asserting the
accent is absent. Run the allowlist check against the current surfaces and verify
manually during the seed run (commit 4).

### Pitfall 6: Committing GAP rows before the assertion is green
**What goes wrong:** Commit 4 (seed run) creates GAP rows for violations that are
actually ExUnit or Playwright failures — creating confusing "is this a test bug or a
real gap?" ambiguity.
**How to avoid:** D-08 commit order: ExUnit and Playwright tests must be green on
commits 2 and 3 BEFORE running the seed (commit 4). GAP rows from the LLM scoring are
separate from test failures.

### Pitfall 7: `ui-baseline-scores.json` path disagreement between harness and ExUnit
**What goes wrong:** The LLM scorer writes to one path; the ExUnit test reads from
another; the gitignore excludes the wrong path.
**Why it happens:** Three consumers of one agreed path; easy to drift.
**How to avoid:** D-03 locks the path as `mailglass_admin/docs/ui-baseline-scores.json`.
The ExUnit reader must use `Application.app_dir(:mailglass_admin, "priv")` pattern OR an
explicit relative path computed from `__DIR__`. The scoring harness docs must show the
exact same path. Validate by running `cat mailglass_admin/docs/ui-baseline-scores.json`
after the scoring step.

---

## Code Examples

### ExUnit ratchet baseline test — shape/range assertion (D-04/D-05)

```elixir
# Source: token_parity_test.exs pattern mirrored for ratchet baseline
defmodule MailglassAdmin.RatchetBaselineTest do
  @moduledoc """
  Fail-closed score-baseline assertion (RATCHET-01).

  Phase 95: establishes and validates shape/range/coverage of the 36-cell
  score baseline (3 surfaces × 6 pillars × 2 themes).

  Phase 103 adds: load prior baseline, assert no cell regresses (only-forward).
  The `compare_baselines/2` private function below is the Phase 103 hook point —
  it exists in Phase 95 but is never called until Phase 103 enables it.

  If this test fails with "missing cell", the scoring step was incomplete.
  If it fails with "score out of range", the LLM scored outside 1-4.
  """
  use ExUnit.Case, async: true

  @scores_path Path.join([
    Application.app_dir(:mailglass_admin, "priv"),
    "..", "..", "docs",  # adjust relative to app_dir
    "ui-baseline-scores.json"
  ])

  @surfaces ["deliveries", "inbound", "preview"]
  @pillars ["Spacing", "Radius", "Color", "Type", "Elevation", "Motion+A11y"]
  @themes ["light", "dark"]
  @valid_scores 1..4

  setup_all do
    assert File.exists?(@scores_path),
           "ui-baseline-scores.json not found — run the LLM scoring step (D-07) first"
    {:ok, baseline: Jason.decode!(File.read!(@scores_path))}
  end

  test "schema_version is present and supported", %{baseline: b} do
    assert b["schema_version"] == 1,
           "Expected schema_version 1, got #{inspect(b["schema_version"])}"
  end

  test "all 36 graded cells are present (3 surfaces × 6 pillars × 2 themes)", %{baseline: b} do
    missing =
      for surface <- @surfaces, pillar <- @pillars, theme <- @themes do
        score = get_in(b, ["surfaces", surface, pillar, theme])
        if score == nil, do: "#{surface}.#{pillar}.#{theme}", else: nil
      end
      |> Enum.reject(&is_nil/1)

    assert missing == [],
           "Missing cells (#{length(missing)}):\n#{Enum.join(missing, "\n")}\n" <>
             "Run the LLM scoring step to fill all 36 cells."
  end

  test "all 36 scores are in the valid range 1-4", %{baseline: b} do
    out_of_range =
      for surface <- @surfaces, pillar <- @pillars, theme <- @themes do
        score = get_in(b, ["surfaces", surface, pillar, theme])
        if score not in @valid_scores,
          do: "#{surface}.#{pillar}.#{theme}: #{inspect(score)}",
          else: nil
      end
      |> Enum.reject(&is_nil/1)

    assert out_of_range == [],
           "Scores out of range 1-4 (#{length(out_of_range)}):\n" <>
             Enum.join(out_of_range, "\n")
  end

  # Phase 103 hook point — called by the closeout re-run assertion.
  # In Phase 95 this function exists but is never called.
  # Phase 103 only ADDS the call site: compare_baselines(prior_baseline, current_baseline)
  defp compare_baselines(prior, current) do
    regressions =
      for surface <- @surfaces, pillar <- @pillars, theme <- @themes do
        prior_score = get_in(prior, ["surfaces", surface, pillar, theme]) || 0
        current_score = get_in(current, ["surfaces", surface, pillar, theme]) || 0
        if current_score < prior_score,
          do: "#{surface}.#{pillar}.#{theme}: #{prior_score} → #{current_score} (REGRESSION)",
          else: nil
      end
      |> Enum.reject(&is_nil/1)

    assert regressions == [],
           "Score regressions (#{length(regressions)}) — only-forward ratchet violated:\n" <>
             Enum.join(regressions, "\n")
  end
end
```

### GAP register header — anti-churn rule verbatim

```markdown
---
milestone: v1.11
artifact: ratchet-gap-register
stable_ids: true
created: 2026-06-13
supersedes: .planning/milestones/v1.7-phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md
---

# RATCHET-GAP-REGISTER — v1.11 Design-System Uplift

> Fresh baseline as of Phase 95 (2026-06-13). IDs restart at GAP-01; no namespace
> collision with the frozen v1.7 register (separate file). DO NOT reopen or modify
> v1.7's 74-GAP-REGISTER.md.

## Anti-Churn Contract

Every build task in Phases 98–103 MUST cite a row from this register at severity ≥ 3.
No citation → no merge. Rows are never renumbered once assigned.

## Idempotent Re-Run Semantics (active from Phase 103)

On re-run: a regressed cell reopens its GAP-NN row (stamp with new run_id). A row
marked `fixed` whose finding is confirmed absent is skipped. A row marked `open`
with the same finding is skipped (no duplicates). The `run_id` field records the
last touch; `first_seen_run` never changes.

## Column Schema

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch | status | run_id | first_seen_run |
...
```

### Playwright structural spec skeleton

```javascript
// Source: operator.spec.js patterns extended
const { test, expect } = require("@playwright/test");

const tenantId = "browser-tenant";
const ACCENT_LIGHT_RGB = "rgb(39, 123, 150)";   // Glass #277B96

// Allowlisted selectors that may legitimately carry the accent color
const ACCENT_ALLOWLIST = [
  "[aria-selected='true']",
  "[aria-current='page']",
  ".btn-primary",
  ":focus-visible",
];

async function openOperatorSurface(page) {
  await page.request.get("/ops/browser-reset");
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
}

test.describe("structural assertions — 6 pillar facts", () => {
  test.describe("operator / deliveries surface", () => {
    test("ARIA: selected row has aria-selected=true", async ({ page }) => {
      await openOperatorSurface(page);
      await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
      await page.getByTestId("operator-delivery-row").first().click();
      await expect(page.getByTestId("operator-delivery-row").first())
        .toHaveAttribute("aria-selected", "true");
    });

    test("touch targets: primary interactive elements >= 44px", async ({ page }) => {
      await openOperatorSurface(page);
      await page.setViewportSize({ width: 390, height: 844 });
      const btn = page.getByRole("button").first();
      const box = await btn.boundingBox();
      expect(box).not.toBeNull();
      expect(box.height).toBeGreaterThanOrEqual(44);
    });

    test("font-weight: body text is 400, bold text is 700", async ({ page }) => {
      await openOperatorSurface(page);
      const bodyWeight = await page.locator("body").evaluate(
        el => getComputedStyle(el).fontWeight
      );
      expect(["400", "700"]).toContain(bodyWeight);
    });

    test("reduced-motion: suppresses animation on all 3 surfaces", async ({ page }) => {
      await page.emulateMedia({ reducedMotion: "reduce" });
      await openOperatorSurface(page);
      // Preview surface via existing test route
      await page.goto("/ops/browser-preview-empty");
      await expect(page.getByTestId("preview-orientation")).toBeVisible();
    });

    test("focus rings: interactive elements have visible outline on focus", async ({ page }) => {
      await openOperatorSurface(page);
      const link = page.getByRole("link").first();
      await link.focus();
      const outline = await link.evaluate(el => getComputedStyle(el).outlineWidth);
      expect(parseFloat(outline)).toBeGreaterThan(0);
    });
  });

  // ... inbound and preview surface describe blocks follow same shape
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| v1.7 GAP register (74-GAP-REGISTER.md, frozen) | New RATCHET-GAP-REGISTER.md starting at GAP-01 | Phase 95 | Fresh baseline against Phase 94 corrected brand; v1.7 IDs permanently retired |
| Ad-hoc visual audit notes | Committed `ui-baseline-scores.json` with ExUnit shape gate | Phase 95 | Machine-checkable baseline; Phase 103 can assert only-forward improvement |
| LLM scoring via free-form review | Structured 6-pillar × 1-4 rubric per surface × theme | Phase 95 | Comparable across runs; enables meet-or-beat arithmetic |
| Playwright operator suite only | Operator suite + structural facts suite | Phase 95 | Machine-checks 6 pillar facts that ExUnit cannot reach |

**Deprecated/outdated:**
- v1.7 `74-GAP-REGISTER.md`: frozen, do NOT reopen. Its GAP-01..22 IDs are permanently retired in this context (new register is a separate file, so no namespace collision).
- Generic `gsd-ui-review` pillar names in any score baseline: replaced by D-01 project pillars.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Playwright `testDir: "./e2e"` automatically picks up `structural.spec.js` with no config change | Playwright structural spec | If Playwright uses a whitelist spec file list, `ci.yml` must be updated |
| A2 | `/ops/browser-reset` and `/ops/browser-login` routes work from `structural.spec.js` without modification | Playwright structural spec | Boot fails; need to check if routes are scoped to operator.spec.js only |
| A3 | No new npm packages are required for `structural.spec.js` | Standard Stack | If Playwright's `getComputedStyle` evaluate API requires a newer Playwright version, update `package.json` |
| A4 | The score path `Application.app_dir(:mailglass_admin, "priv")` resolves correctly at test time for reading `docs/ui-baseline-scores.json` | ExUnit test | May need `Path.join([__DIR__, "..", "..", "docs", "ui-baseline-scores.json"])` instead |
| A5 | `gsd-ui-review` 1–4 grade scale (N/4 per pillar) maps to integers 1, 2, 3, 4 | Score range | If the scale is 0–4 or fractional, the range assertion must be adjusted |

---

## Open Questions

1. **`structural.spec.js` auto-pickup vs. explicit registration**
   - What we know: `playwright.config.cjs` sets `testDir: "./e2e"` with no explicit `testMatch` filter.
   - What's unclear: Whether Playwright uses all files matching `*.spec.js` under `testDir` by default.
   - Recommendation: Verify by checking if `operator.spec.js` is the only spec or if other specs exist. The default Playwright behavior is glob `**/*.spec.{js,ts}` — `structural.spec.js` will be picked up automatically.

2. **`Application.app_dir` path for `docs/ui-baseline-scores.json`**
   - What we know: `token_parity_test.exs` uses `Application.app_dir(:mailglass_admin, "priv")` to reach `priv/static/app.css` (inside the app directory). `docs/` is NOT under `priv/`.
   - What's unclear: Whether `app_dir` resolves to a path where `../../docs/` exists.
   - Recommendation: Use `Path.join([__DIR__, "..", "..", "docs", "ui-baseline-scores.json"])` (three levels up from `test/mailglass_admin/`) as the safer pattern. Validate by running the test.

3. **Accent-allowlist completeness for dark theme**
   - What we know: Phase 94 corrected the accent-as-border bug; accent should now be confined.
   - What's unclear: Whether dark theme has any additional accent surfaces not in the light allowlist (e.g. different selected-row treatment).
   - Recommendation: Run `ui-audit.sh` and visually verify dark theme surfaces before finalizing the allowlist in `structural.spec.js`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir 1.18 / OTP 27 | ExUnit ratchet baseline test | Yes (CI matrix) | 1.18 / OTP 27 | — |
| Node 22 | operator_browser_gate Playwright lane | Yes (CI matrix) | Node 22 | — |
| Playwright / Chromium | structural.spec.js | Yes (existing lane) | CI: `npx playwright install` | — |
| Jason | `ratchet_baseline_test.exs` | Yes (existing dep) | ~> 1.4 | — |
| agent-browser CLI | `ui-audit.sh` screenshot capture | Maintainer-local | Per-machine | Must be installed by maintainer before seed run |
| PostgreSQL | operator_browser_gate (server boot) | Yes (CI service) | 16-alpine | — |

**Missing dependencies with no fallback:**
- `agent-browser` CLI must be installed locally before commit 4 (seed run). It is not a CI dep and is not checked in CI. Document this in the phase plan as a local prerequisite.

**Missing dependencies with fallback:**
- None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) + Playwright 1.x (existing) |
| ExUnit config | `mailglass_admin/test/test_helper.exs` |
| Playwright config | `mailglass_admin/playwright.config.cjs` |
| Quick ExUnit run | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs` |
| Full support-contract run | `cd mailglass_admin && mix verify.support_contract.admin` |
| Playwright run | `cd mailglass_admin && npm run test:operator-browser` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RATCHET-01 | 36 graded cells present, scores 1–4 | ExUnit unit | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs -x` | ❌ Wave 0 |
| RATCHET-01 | `ui-baseline-scores.json` committed and readable | ExUnit unit | same | ❌ Wave 0 |
| RATCHET-02 | GAP register file exists with correct schema | Human review | Manual — reviewer checks PR description cites GAP row | ❌ Wave 0 (file creation) |
| RATCHET-04 | 6 structural facts pass on 3 surfaces | Playwright structural | `cd mailglass_admin && npm run test:operator-browser` | ❌ Wave 0 |
| RATCHET-05 | LLM scores JSON committed, PNGs gitignored | ExUnit + manual | `mix test ...ratchet_baseline_test.exs` (shape); `git status tmp/ui-audit/` (gitignore check) | ❌ Wave 0 |

**First-run vs. regression distinction:**

| Validation Layer | Phase 95 (establish) | Phase 103 (regression) |
|-----------------|----------------------|------------------------|
| ExUnit shape assertion | ACTIVE — validates all 36 cells present, scores 1–4 | ACTIVE — unchanged |
| ExUnit meet-or-beat | INACTIVE — `compare_baselines/2` exists but is not called | ACTIVE — Phase 103 adds the call site |
| Playwright structural spec | ACTIVE — facts pass/fail on current surfaces | ACTIVE — regression on any fact fails CI |
| GAP register citation | ACTIVE — documented review rule for downstream phases | ACTIVE — same rule |

**"Validate by running it" protocol for each requirement:**

- **RATCHET-01:** Run `cd mailglass_admin && mix verify.support_contract.admin`. The
  `ratchet_baseline_test.exs` is listed explicitly in the alias. Green = shape + range pass.
- **RATCHET-02:** GAP register is validated by human review during Phase 95 seed step +
  PR review. Machine validation is not applicable to a markdown artifact.
- **RATCHET-04:** Run `cd mailglass_admin && npm run test:operator-browser`. The
  `structural.spec.js` is picked up by `testDir: "./e2e"`. Green = 6 facts pass on 3 surfaces.
- **RATCHET-05:** Run the LLM scoring step (D-07 procedure), then run
  `mix test test/mailglass_admin/ratchet_baseline_test.exs`. Green = JSON is well-formed,
  36 cells, scores 1–4.

### Sampling Rate

- **Per task commit:** `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs -x`
- **Per wave merge:** `cd mailglass_admin && mix verify.support_contract.admin && npm run test:operator-browser`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` — covers RATCHET-01/05
- [ ] `mailglass_admin/e2e/structural.spec.js` — covers RATCHET-04
- [ ] `mailglass_admin/docs/ui-baseline-scores.json` — initial placeholder (valid JSON, all 36 cells at score 0 or null) needed so the ExUnit test compiles; real scores populated in commit 4 of D-08
- [ ] `.planning/RATCHET-GAP-REGISTER.md` — header + schema; rows populated in commit 4

*(Framework install: none — Playwright and ExUnit already configured)*

---

## Security Domain

> The security domain is not directly applicable to this phase. Phase 95 creates test
> infrastructure, a planning artifact (GAP register), and a committed JSON score file.
> No authentication, session management, data persistence, or cryptography is introduced.

**Applicable ASVS categories:**

| ASVS Category | Applies | Note |
|---------------|---------|------|
| V2 Authentication | No | No auth code changes |
| V3 Session Management | No | No session code changes |
| V4 Access Control | No | |
| V5 Input Validation | Partial | `ratchet_baseline_test.exs` reads JSON from a committed file — validate schema before asserting (done via ExUnit assertions on the parsed structure) |
| V6 Cryptography | No | |

**PII minimization:** `structural.spec.js` uses the existing browser-tenant test scenario.
The test tenant fixture data uses non-real emails (e.g. `browser-tenant@example.com`).
No PII is introduced by this phase.

---

## Sources

### Primary (HIGH confidence)
- `mailglass_admin/docs/design-system.md:104-121` — canonical 6-pillar rubric (D-01)
- `mailglass_admin/scripts/ui-audit.sh` — 18-cell PNG matrix definition, gitignore path
- `mailglass_admin/e2e/operator.spec.js` — Playwright assertion patterns to mirror
- `mailglass_admin/playwright.config.cjs` — boot mechanism, testDir, lane wiring
- `mailglass_admin/test/mailglass_admin/token_parity_test.exs` — ExUnit template to mirror
- `mailglass_admin/mix.exs` — `verify.support_contract.admin` alias composition, `jason` dep
- `.github/workflows/ci.yml:586-716` — `support_contract_admin` + `operator_browser_gate` jobs
- `.planning/milestones/v1.7-phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:26-36` — column shape
- `.planning/milestones/v1.7-phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md:17-22` — anti-churn contract
- `.planning/milestones/v1.7-phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md:143-151` — closeout/idempotent-rerun precedent
- `.gitignore:14` + `mailglass_admin/.gitignore:11` — `/tmp/` rule covering `tmp/ui-audit/`
- `~/.claude/get-shit-done/workflows/ui-review.md:122-131` — 1-4 grade scale per pillar
- `.planning/phases/95-audit-apparatus-quality-ratchet-v2/95-CONTEXT.md` — D-01..D-08 locked decisions

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` — RATCHET-01/02/04/05 requirement text and acceptance criteria
- `.planning/ROADMAP.md` — Phase 95 success criteria + Phase 103 dependency
- `.planning/phases/94-token-re-baseline-onto-canonical-brand/94-CONTEXT.md` — D-10 gates-first pattern, D-02 parity-test wiring

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all deps already in the repo; no new packages
- Architecture: HIGH — directly verified from existing code patterns
- ExUnit shape: HIGH — mirrors token_parity_test.exs exactly
- Playwright assertions: MEDIUM-HIGH — patterns verified from operator.spec.js; accent-allowlist and focus-ring assertions are new (no exact precedent), but patterns are standard Playwright
- GAP register schema: HIGH — directly extends proven v1.7 shape
- LLM scoring harness: MEDIUM — GSD subagent invocation is the recommended shape; exact prompt structure is Claude's discretion

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 (stable domain — test patterns and file structures do not change rapidly)

---

## RESEARCH COMPLETE

**Phase:** 95 - Audit Apparatus + Quality-Ratchet v2
**Confidence:** HIGH

### Key Findings

- **36 graded cells, not 18:** PNG evidence grid is 18 cells (surface×viewport×theme); score baseline grid is 36 cells (surface×pillar×theme). These are intentionally different keyings — the planner must document the link, not conflate them.
- **ExUnit test template is exact:** `token_parity_test.exs` is the precise structural model. The new `ratchet_baseline_test.exs` mirrors its module layout, `Application.app_dir` path pattern, `setup_all`, collect-all-mismatches-before-asserting, and failure message conventions. The `compare_baselines/2` function must exist in Phase 95 (even though uncalled) so Phase 103 only adds the call site, not a rewrite.
- **Playwright auto-pickup confirmed:** `playwright.config.cjs:testDir = "./e2e"` picks up all `*.spec.js` files; no change to `playwright.config.cjs` or `ci.yml` needed. `structural.spec.js` inherits the full `operator_browser_gate` setup (Postgres, server boot, Chromium install).
- **gitignore coverage verified:** `tmp/ui-audit/` is covered by the root `.gitignore:14` (`/tmp/`) AND `mailglass_admin/.gitignore:11` (`/tmp/`). The committed JSON path (`mailglass_admin/docs/ui-baseline-scores.json`) is under `docs/` which is in the Hex tarball `mix.exs :files` whitelist — it will be committed correctly.
- **Citation gate is a documented review rule, not a script:** This mirrors the v1.7 precedent exactly. The Playwright structural spec provides the machine gate; the register provides the citation anchor for PR review.

### File Created

`.planning/phases/95-audit-apparatus-quality-ratchet-v2/95-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | All deps verified as existing in repo |
| ExUnit baseline test | HIGH | `token_parity_test.exs` is a direct template |
| GAP register schema | HIGH | Directly extends verified v1.7 shape |
| Playwright structural spec | MEDIUM-HIGH | Patterns verified; focus ring + accent assertions are new but use standard Playwright evaluate API |
| LLM scoring harness | MEDIUM | GSD subagent shape is recommended; exact invocation is Claude's discretion |
| Graded cell count | HIGH | Explicitly reconciled in CONTEXT.md D-07 and design-system.md |

### Open Questions

- Whether `Application.app_dir` resolves to a path where `../../docs/` is reachable (A4 — use `__DIR__` relative path as fallback)
- Accent-allowlist completeness for dark theme needs visual verification during seed run (Q3)

### Ready for Planning

Research complete. Planner can now create PLAN.md files for Phase 95 using the D-08
commit sequence as the wave structure and the code examples above as the implementation
templates.
