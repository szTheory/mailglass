# Feature Research — v1.13 Admin Design-System Stress Test & UX Uplift (v3)

**Domain:** Mountable Phoenix LiveView operator/admin dashboard (`mailglass_admin`, 3 surfaces: Operator `/ops/mail`, Inbound `/ops/mail/inbound`, Preview `/dev/mail`)
**Researched:** 2026-06-18
**Confidence:** HIGH (mature design systems + Elixir-ecosystem admin UIs are well-documented and convergent; project-specific constraints grounded in shipped code + v1.11 LOCKED decisions)

> **This dossier EXTENDS v1.11.** It does not re-derive v1.11's locked IA (`IA-LD-01..09`),
> component-state (`STATE-LD-01..22`), microcopy (`COPY-LD-01..16`), motion, or dark-mode
> decisions. Where a v1.11 lock already settles a question, this file references it and builds
> the *next* layer (system theme, stress fixtures, multi-tenant selector, honest pagination,
> operator-under-stress clarity) on top. Anything tagged "already locked" is **not** re-litigated.

---

## How to read this: fractal levels × personas

Features below are organized by the milestone's **fractal levels** (foundations → primitives →
forms → app-shell/nav → data-display → component-groups → pages/flows), then cross-cut by the
**5 personas / JTBD**:

| Persona | JTBD on these surfaces | Primary surface |
|---------|------------------------|-----------------|
| **P1 Evaluator** — dev sizing up the lib | "Is this polished and trustworthy enough to adopt?" | Preview, then Operator |
| **P2 Integrator** — dev wiring it in | "Did my mailable render / route correctly?" | Preview, Inbound |
| **P3 Maintainer** — dev debugging their own app | "Why did *this* delivery fail in *my* code?" | Operator, Inbound |
| **P4 Operator/SRE** — monitoring under stress | "What's broken right now, how bad, what do I do?" | Operator (Overview), Inbound |
| **P5 Security reviewer** — auditing dangerous actions | "What does replay/reveal-raw actually do, and is it safe?" | Operator/Inbound replay + EvidenceCard |

Every feature carries **Complexity** (LOW/MED/HIGH), the **fractal level**, the **persona(s)**
it serves, and **dependency-on-existing** (what shipped code or v1.11 lock it builds on).

---

## Source systems mined (right AND wrong)

| System | What it does RIGHT (steal) | What it does WRONG (avoid) |
|--------|----------------------------|----------------------------|
| **IBM Carbon** | Status-indicator pattern (shape+color+label, never color-alone); strict notification taxonomy (inline / toast / actionable / modal); explicit "skeleton ≠ spinner" loading guidance; DataTable with built-in empty/loading/batch states | Carbon's density can feel cold/enterprise; its notification set deliberately *omits* persistent banners (teams bolt them on) — don't assume a banner primitive exists |
| **Shopify Polaris** | `IndexTable` vs `ResourceList` decision is explicit (table when scanning columns, list/card when scanning *items*); `Banner` with tone+title+action; `EmptyState` with illustration+heading+primary action; "tone" vocabulary (info/success/warning/critical) maps cleanly to status | Polaris over-uses illustrations in empty states (heavy, brand-specific — we have a zero-asset/zero-Node constraint); its mobile story is weaker than its desktop story |
| **Atlassian ADS** | `EmptyState` taxonomy (no-data vs no-results vs error vs no-permission — *four distinct templates*); inline-message vs flag (transient) vs section-message (persistent) separation; "principle of least surprise" in nav active-state | Flag/toast over-reliance trains users to ignore transient feedback; ADS is huge — cherry-pick, don't import the mental model wholesale |
| **GOV.UK DS + Service Manual** | Content design (plain words, name the cause); "one thing per page"; **error summary at top linking to fields**; labels visible above controls (never placeholder-as-label); "don't show pagination if one page"; nav labels = destination not state | GOV.UK is deliberately low-density / single-column — operator audit surfaces need *more* density than GOV.UK defaults; don't copy its whitespace-maximal layout for data tables |
| **Phoenix LiveDashboard** | Idiomatic LiveView admin chrome; nav tabs + live-updating tables with zero client JS; sortable/paginated server-streamed tables; "this node / all nodes" context switcher is a clean tenant-selector analog | Visually utilitarian (it's a dev tool, not a design exemplar) — meets-the-bar, not award-winning; tables can overflow horribly on narrow viewports |
| **Oban Web** | Best-in-class Elixir operator UI: severity-first queue health, live counts, filter chips, detail drawer, bulk actions with confirm; dark mode done well; this is the closest peer to our Operator surface | Commercial/closed — can't copy code; its density assumes a wide viewport (weak < 768px) |
| **Backpex** | LiveView CRUD admin with tables/filters/pagination/themes (daisyUI-based, same stack as us!); proves tables + multi-theme picker work zero-Node in LiveView | CRUD-generic — not audit-shaped; its tables go straight to "squished" on mobile (the exact failure we must avoid) |
| **Kaffy / AshAdmin** | Auto-generated admin from schema/resources; Kaffy's dashboard cards + AshAdmin's resource nav show the "auto-list everything" pattern | Auto-generation = generic, low-craft UI; both demonstrate the *anti-pattern* of table-for-everything and no empty-state design — instructive as "what not to ship" |

Sources at end.

---

## Feature Landscape

### Level 0 — Foundations

#### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Fractal level / Persona / Depends-on |
|---------|--------------|------------|---------------------------------------|
| Formal **z-index layer system** (named tokens: base / sticky-nav / dropdown / overlay-scrim / modal / toast) | Every mature DS (Carbon, Polaris) names elevation layers; ad-hoc `z-50` causes the "modal-behind-scrim" bug already in the PROJECT bug list | LOW | Foundations · P4/P5 · builds on `brandbook/tokens.css` `--mg-*` (v1.11 TOKEN-01) |
| **Motion tokens** as named durations/easings (already partly locked) | Consistent motion needs named tokens, not inline `duration-200`; Emil Kowalski / Carbon both tokenize | LOW | Foundations · all · v1.11 MOTION-LD-* already locked easing/duration — extend with system-theme parity only |
| **Focus-ring token** applied uniformly (`focus-visible:ring-2 ring-primary`) | WCAG 2.4.7; v1.11 already flagged missing rings on nav/tabs/rows | LOW | Foundations · P5/a11y · v1.11 STATE-LD-06/11/21 already specify the ring — this milestone *audits coverage* |
| **Semantic surface/elevation tokens** with light+dark+**system** parity | Theme switching only scales with role-named tokens (`color-surface-raised`), not raw hex — universally agreed | LOW | Foundations · all · v1.11 TOKEN-01..05 locked light/dark — **system is the new delta** |

#### Differentiators

| Feature | Value Proposition | Complexity | Fractal level / Persona / Depends-on |
|---------|-------------------|------------|---------------------------------------|
| **Zero one-off values gate** (lint/grep gate: no arbitrary `tracking-[...]`, `text-xl`, `z-50`, hex) | "No off-token values" is provable, not aspirational; extends the v1.11 ratchet to foundations | MED | Foundations · maintainer · v1.11 RATCHET-03 conformance gates — widen the regex set |

---

### Level 1 — Primitive components & Level 2 — Form controls

> v1.11 `STATE-LD-01..22` already locked the per-state matrix (rest/hover/focus/active/disabled/
> loading/selected/error/empty/long-content) for **every existing component**. This milestone's
> job is **coverage proof across the widened matrix** (× system theme × new viewports 320/wide ×
> WCAG 2.2 AA), not new state definitions.

#### Table Stakes

| Feature | Why Expected | Complexity | Fractal level / Persona / Depends-on |
|---------|--------------|------------|---------------------------------------|
| Every primitive verified in **light/dark/system × 320→wide × all interaction states** | Award-winning bar = no broken state at any width/theme; WAI-ARIA APG conformance | MED | Primitives · all · extends v1.11 STATE-LD-* (add system + 320px column) |
| **44×44 touch targets** resolved (the `btn-sm` vs `min-h-11` tension) | Repeatedly flagged in v1.11 (theme_toggle, support_cards CTAs, device_frame, evidence_card reveal); WCAG 2.5.8 (AA, 24×24 min; we hold 44) | LOW | Primitives/forms · P4 mobile · v1.11 STATE-LD-08/14/19/20 flagged this for "Phase 97 verify" — **verify + lock the compiled bundle truth** |
| **Labels visible above controls**, never placeholder-as-label | GOV.UK + NNGroup hard rule; filter labels already locked to `text-label` token | LOW | Forms · P3/P4 · v1.11 IA-LD-04 / STATE-LD-13 already locked — audit for stragglers |
| **Disabled vs enabled visually unambiguous** (the "disabled-looking-enabled" bug) | In PROJECT bug list; users hate clicking a control that looks dead, or skipping one that looks dead but works | LOW | Forms · P4/P5 · new audit — define a disabled-opacity+cursor token rule |

#### Differentiators

| Feature | Value Proposition | Complexity | Fractal level / Persona / Depends-on |
|---------|-------------------|------------|---------------------------------------|
| **Component-lab "Storybook-lens"** matrix surface (`/dev/mail/gallery` extended to component × state × theme × viewport) | One screen proves the whole matrix; doubles as visual-regression surface; in-house (zero-Node) beats PhoenixStorybook for our constraint | HIGH | Primitives · maintainer/P1 · v1.11 GALLERY-01/02 shipped the seed gallery — **widen the matrix axes** |
| **Skeleton loaders** (not spinners) for any async list/detail | Carbon: skeletons preserve layout, reduce perceived latency; spinners feel slower and shift layout | MED | Primitives · P3/P4 · v1.11 MOTION (skeletons mentioned) — adopt as the standard loading primitive |

---

### Level 3 — App-shell & navigation

#### Table Stakes

| Feature | Why Expected | Complexity | Fractal level / Persona / Depends-on |
|---------|--------------|------------|---------------------------------------|
| **Active-state wayfinding** with `aria-current="page"` + visible active treatment | Principle of least surprise; "where am I?" must be answerable in <1s; already locked | LOW | App-shell · all · v1.11 IA-LD-06 + STATE-LD-06 locked — audit consistency across nav_link/nav_pill |
| **Theme picker: system / light / dark with SYSTEM as default** | THE headline fix. Today only a light↔dark toggle. Every mature DS defaults to OS preference and offers manual override (3-way) | MED | App-shell · all · **replaces** the binary `theme_toggle` (shell.ex:260) — see "Theme Picker" deep-dive |
| **Nav labels = destination nouns, never state** ("Deliveries" not "Deliveries (3 failed)") | GOV.UK hard rule; already locked | — | App-shell · all · v1.11 IA-LD-06 (no change, just don't regress) |
| **Responsive app-shell** sidebar (≥768) ↔ pill/drawer nav (320–767) without layout break | Mobile-first 320→wide is the milestone bar; sidebar is `hidden md:flex` today | MED | App-shell · P4 mobile · extends shell.ex layout to 320px |

#### Theme Picker — deep dive (HEADLINE FEATURE)

**What good systems do (LOVE):** Default to `prefers-color-scheme` (respect the choice the user
already made at the OS level); offer an explicit 3-way control (System / Light / Dark); persist the
*override* (not the resolved value) so "System" keeps tracking OS changes live via a
`matchMedia('(prefers-color-scheme)')` change listener; use a `<select>` or segmented radio group
(3 options → segmented is fine, Carbon/Polaris pattern); show which is *active* including resolving
"System → currently dark."

**What users HATE:** A site that ignores their OS dark preference and blasts white on load (FOUC of
the wrong theme); a toggle that *looks* binary but silently strips the system-tracking ability; an
override that doesn't persist across reloads; a flash of the wrong theme before JS runs.

**Project-specific guidance (mountable-library constraints):**
- **System must be the default** (PROJECT target). Resolve via CSS `@media (prefers-color-scheme)`
  AND a `data-theme` attribute the picker sets to `system` | `mailglass-light` | `mailglass-dark`.
- **Host-app-friendly:** must NOT hijack the host app's theme. The picker controls only the admin
  surface chrome (`data-theme` on the admin root div, already the v1.11 STATE-LD-10 mechanism).
  Persist the override in a **scoped key** (e.g. `mailglass_admin:theme`) so it never collides with
  the host's own theme storage.
- **Zero-Node / no-FOUC:** the "System" default is pure CSS (`@media` query resolves before paint).
  The override needs a tiny inline read of the scoped store before first paint — acceptable
  (LiveView/CSS-only; no client-hook framework). Avoid a JS-only theme that flashes.
- **Preview surface dark chrome** was a v1.11 GAP-03 (param ignored). The 3-way picker must also
  drive the Preview chrome — closes the dark-preview gap.
- **Anti-feature:** a full per-tenant or per-user *persisted-server-side* theme. Out of scope —
  it's a host-app concern; client-scoped persistence is the right altitude.

#### Differentiators

| Feature | Value Proposition | Complexity | Depends-on |
|---------|-------------------|------------|------------|
| **Live system-theme tracking** (re-render on OS theme change while open) | Polish signal evaluators notice; cheap with `matchMedia` listener | LOW | App-shell · P1 · new |
| **Skip-to-content link** + landmark roles on shell | A11y completeness (WCAG 2.4.1); keyboard/SR users | LOW | App-shell · P5/a11y · new |

---

### Level 4 — Data-display patterns

This is the densest, most differentiating level. Three deep-dives below.

#### Tables vs Cards vs Lists — decision heuristic (deep dive)

**The convergent rule (Polaris IndexTable vs ResourceList, NNGroup, Carbon):**

| Use a **TABLE** when | Use a **LIST/CARD** when |
|----------------------|--------------------------|
| User **compares across columns** (status vs time vs provider) | User **scans down items** and acts on one |
| Data is homogeneous, columnar, multi-attribute | Each item is a rich, self-contained record |
| Viewport is wide enough for all key columns | Viewport is narrow (320–767) OR columns would squish |

**When squished tables FAIL (what users HATE):** horizontal scroll that hides the identifier
column; columns crushed to 2-char width; text truncated to "Del…"; the user "crossing lines"
reading a row because nothing is pinned. Backpex/Kaffy ship exactly this on mobile — the cautionary
exemplar.

**The winning responsive pattern (steal from the NNGroup/Sonneil/Appnroll research + Polaris):**
**Table at ≥768px, collapse to stacked label:value cards at <768px** (the "row-to-card" transform).
Each card surfaces the identifier prominently, then label:value pairs. NOT horizontal-scroll. NOT a
squished mini-table.

**Project-specific guidance:**
- **Deliveries list & Inbound records list:** these are the master pane of a master-detail
  (v1.11 IA-LD-03 already locked the 40/60 and 33/67 splits). At ≥768 they can be tabular; at
  320–767 they MUST become stacked cards (selected-row state preserved per STATE-LD-11). This is
  the **anti-squish lock** to add.
- **Timeline / RoutingTrace / EvidenceCard:** already correctly NOT tables (vertical event/clause
  lists) — keep them as lists. Don't "tableize" a timeline.
- **SupportCards triage grid:** correctly cards, not a table — v1.11 IA-LD-05 locked the order.
- **Anti-feature: a sortable/filterable mega-table of everything** (the Kaffy/AshAdmin auto-admin
  default). Our surfaces are audit-shaped (master-detail + triage), not CRUD-list-shaped. Filters
  are plain (not facets) per v1.11 IA analysis.

| Feature | Tag | Complexity | Fractal / Persona / Depends-on |
|---------|-----|------------|--------------------------------|
| **Row-to-card responsive transform** for Deliveries + Inbound lists at <768px | **Table stakes** | MED | Data-display · P4 mobile · extends STATE-LD-11 (master list) |
| Pin/keep identifier column visible (no identifier loss on scroll) | **Table stakes** | LOW | Data-display · P3/P4 · new lock |
| In-house tables-vs-cards discipline gate (grep for `<table>` on narrow-only surfaces) | **Differentiator** | MED | Data-display · maintainer · ratchet extension |

#### Stat / KPI cards — consistency, overflow, truncation (deep dive)

**What good systems do:** consistent card anatomy (label + value + optional delta/severity +
optional action); a **single card component** reused (Polaris/Carbon); reserve space for the value
so long numbers don't reflow; truncate the *label* with a tooltip, never the *value*; severity
encoded with shape+color+text (Carbon status-indicator), never color alone.

**What users HATE (and the PROJECT bug list confirms): "clipped stat-card labels"** — a label
chopped mid-word because the card width assumed short labels; inconsistent card heights creating a
ragged grid; a "12,345" value wrapping to two lines and breaking alignment; color-only severity an
SRE can't parse at a glance or in colorblind/dark mode.

**Project-specific guidance:**
- **One canonical stat-card component** for the Operator Overview health tiles (orphan-backlog,
  recent-failure, suppression-count) and the Inbound at-a-glance tier (v1.11 IA-LD-09). Consistent
  anatomy: `label` (truncate + `title` tooltip), `value` (tabular-nums, no-wrap, reserved width),
  `severity` (status-indicator: icon+color+text), optional `drilldown CTA` (44px).
- **Overflow rule:** label truncates with ellipsis + accessible full text; value uses
  `tabular-nums` and never wraps; long tenant IDs / non-ASCII handled (stress fixtures cover this).
- **Severity, not just count:** a "3 failed ingests" tile must read *bad* (error color + icon +
  "Needs attention"), a "0 orphans" tile must read *calm* — the Tier1/Tier2 distinction
  (v1.11 IA-LD-05) already encodes this; this milestone makes the visual severity unmistakable.

| Feature | Tag | Complexity | Fractal / Persona / Depends-on |
|---------|-----|------------|--------------------------------|
| Single canonical **stat-card** with fixed anatomy across Overview + Inbound tiers | **Table stakes** | MED | Data-display · P4 · extends SupportCards (IA-LD-05) + Inbound tier (IA-LD-09) |
| **Label truncation + tooltip; value never truncates/wraps** (`tabular-nums`, reserved width) | **Table stakes** (fixes named bug) | LOW | Data-display · P4 · new lock |
| **Severity-first** stat cards (icon+color+text, not color-alone) | **Differentiator** | LOW | Data-display · P4/P5 colorblind · Carbon status-indicator |

#### Pagination / stream affordances (deep dive)

**The convergent rule (GOV.UK explicit; Polaris/Carbon):** **don't render pagination when there's
one page.** Show a result count ("12 Deliveries"); show pagination controls only when count >
page-size; disable (not hide) prev/next at the boundaries with `aria-disabled`; for live streams,
prefer "load more" or live-append over numbered pages.

**What users HATE:** a pagination bar showing "Page 1 of 1" with both arrows dead — pure noise;
pagination that resets filter/URL state (v1.11 already locked URL-serialized state — IA-LD); a
"load more" that silently does nothing at the end.

**Project-specific guidance:**
- Operator/Inbound lists are a **bounded 168h window** (small sets per v1.11 IA analysis), often
  one page. **Default to NO pagination chrome**; show only a count. Add pagination affordance
  *only* when a stress fixture (high-count tenant) overflows the window — and even then, the
  honest-affordance rule applies.
- LiveView **streams** (`phx-update="stream"`) are the idiomatic append mechanism (LiveDashboard
  pattern). Use streams for live updates, not numbered pagination, where data grows live.
- **Anti-feature:** infinite scroll on an audit surface — breaks deep-linkability and "find the
  one failed delivery" scanning. Keep bounded window + count + optional explicit load-more.

| Feature | Tag | Complexity | Fractal / Persona / Depends-on |
|---------|-----|------------|--------------------------------|
| **Result count always; pagination chrome only when >1 page** | **Table stakes** | LOW | Data-display · all · GOV.UK rule; new lock |
| Boundary-disabled (not hidden) prev/next with `aria-disabled` | **Table stakes** | LOW | Data-display · a11y · new |
| LiveView `stream` for live-append lists | **Differentiator** | MED | Data-display · P4 · idiomatic LiveView |

#### Empty / Error / Permission-denied / Stale / Loading states (deep dive)

**The four-template rule (Atlassian ADS, the cleanest taxonomy — steal this):**

| State | Template | Project mapping |
|-------|----------|-----------------|
| **No-data** (nothing exists yet) | Explain what will appear + how to make it appear | "No Deliveries yet — appear here once your app sends" (v1.11 COPY-LD-02) |
| **No-results** (filters exclude everything) | Name the filter cause + offer **reset filters** | "No Deliveries match your filters" + reset action (COPY-LD-01) |
| **Error** (load failed) | Name the cause + recovery action | cause-naming pattern (COPY-LD-07/08) |
| **No-permission** | Explain access needed, don't dead-end | **NEW — not yet covered** |
| **Stale** (data may be outdated) | Timestamp + refresh affordance | **NEW — not yet covered** |
| **Loading** | Skeleton (not spinner), preserve layout | COPY-LD-15 label + skeleton primitive |

**What users HATE:** a blank white pane (no explanation); an error that says "Oops!" (banned —
COPY-LD-09); a no-results state with no way to clear filters; a permission-denied that looks like a
crash; stale data with no "as of" timestamp (an SRE acting on 10-min-old numbers during an
incident is dangerous).

**Project-specific guidance:**
- v1.11 already locked **no-data / no-results / error** copy + placement (COPY-LD-01..08,
  IA-LD-07). This milestone adds the **two missing templates**:
  - **No-permission:** the operator routes mount behind host auth (`auth:` option, jobs.md J9).
    A scoped/denied operator should see a cause-naming "You don't have access to this tenant's mail
    operations" — NOT a blank page or raw 403. This is the **"No tenant selected" dead-end fix**
    elevated: distinguish *no tenant chosen* (pick one) from *no access* (ask an admin).
  - **Stale:** live surfaces should show an "as of HH:MM" / "updated just now" indicator and a
    refresh affordance, so P4 never acts on stale counts during an incident.
- **Loading:** adopt skeletons (Carbon guidance) for any async master/detail; the v1.11 motion
  dossier already permits skeletons.

| Feature | Tag | Complexity | Fractal / Persona / Depends-on |
|---------|-----|------------|--------------------------------|
| No-data / no-results / error states (all 3 surfaces) | **Table stakes** | — | already locked (COPY-LD-01..08, IA-LD-07) — audit only |
| **Permission-denied** state (distinct from no-tenant + from crash) | **Table stakes (NEW)** | MED | Data-display · P5/P4 · `auth:` mount (J9); kills "No tenant selected" dead-end |
| **Stale-data indicator** ("as of HH:MM" + refresh) on live surfaces | **Differentiator** | MED | Data-display · P4 SRE · new |
| **Skeleton** loading state for master/detail | **Differentiator** | MED | Data-display · P3/P4 · v1.11 MOTION |

---

### Level 5 — Component groups (meta-components)

#### Operator-under-stress clarity (deep dive — P4/P5 critical)

**The "five-second test" (operator-dashboard research + Carbon status-indicator):** an SRE under
stress must answer in 5 seconds: **(1) current state — is it OK or not? (2) what needs attention
(severity-ranked)? (3) where do I look / what do I do next?** Three-tier hierarchy: North-Star
health → supporting indicators → diagnostic detail.

**What good systems do:** severity-ranked items (not every threshold breach equally loud); a clear
summary→diagnostic drill path; status communicated by shape+color+**label** (never color alone);
dangerous actions gated by explicit confirm with consequence text.

**What users HATE:** a wall of equal-weight cards where the one fire is buried; color-only status an
SRE can't parse in dark mode / colorblind / glance; a "Replay" button that fires irreversibly with
no consequence preview; not knowing whether a number is current.

**Project-specific guidance:**
- The **Operator Overview** (shipped v1.7, surfaces orphan-backlog / recent-failure / suppression
  health) IS the North-Star tier. v1.11 IA-LD-05 ordered Tier1 (actionable, non-zero) before Tier2
  (calm/zero). This milestone makes severity **unmistakable and color-independent** (icon + label +
  color) and ensures the **drill path** from a hot tile → the filtered Deliveries list is one click.
- **Dangerous actions (P5):** Replay (re-dispatches, writes a new Event) and Reveal-raw-source
  (PII) are the dangerous actions. v1.11 STATE-LD-17 locked the replay modal (role=dialog, Escape,
  focus-trap, consequence copy COPY-LD-13) and STATE-LD-19 locked EvidenceCard redacted/revealed/
  denied. This milestone **audits** that consequence text states risk/irreversibility plainly and
  that confirm is deliberate (absent-when-disabled, not greyed — STATE-LD-17).
- **Next-action clarity:** the orientation strip (STATE-LD-09, COPY-LD-11/12) already gives
  symptom→action tips. Keep; ensure it's the *first* thing on an empty detail pane.

| Feature | Tag | Complexity | Fractal / Persona / Depends-on |
|---------|-----|------------|--------------------------------|
| **Severity encoded by icon+label+color** (never color-alone) on all status/stat surfaces | **Table stakes** | LOW | Component-groups · P4/P5/colorblind · Carbon status-indicator; extends status_badge (STATE-LD-05) |
| **One-click drill** from a hot health tile → filtered list | **Differentiator** | MED | Component-groups · P4 · Overview (v1.7) + URL-state (v1.11 IA) |
| **Consequence + risk copy** audited on every dangerous action (replay, reveal-raw) | **Table stakes** | LOW | Component-groups · P5 · audit STATE-LD-17/19 + COPY-LD-13 |
| **Stress-fixture cohort** (2–3 tenant personas × no-data/one/many/long-ID/non-ASCII/high-count/null/error) | **Differentiator** | HIGH | Component-groups · all · the proving substrate for every state above |

#### Multi-tenant SELECTOR UX (deep dive — kills the named dead-end)

**What good systems do (M365 tenant switcher, Clerk OrganizationSwitcher):** **auto-select when
there's exactly one** tenant (don't make the user pick from a list of one); a **switcher** (not a
free-text box) listing accessible tenants when there are many; show the *current* tenant
prominently; pin/favorite frequent ones; switching preserves context where safe.

**What users HATE (and the PROJECT bug list confirms):** a tenant picker that exists when there's
**only one tenant** ("a pointless single-tenant picker"); a **"No tenant selected" dead-end** where
you must magically know/type a tenant ID with no list (the exact v1.13-triggering bug); a switcher
that loses your place; free-text tenant entry (typo → empty results → "is it broken?").

**Project-specific guidance (the tenant_chip today is read-only — shell.ex:245):**
- **Auto-select sole tenant:** if the host resolves exactly one tenant in scope, select it
  automatically and render the chip as *informational* (no picker affordance). Kills the
  "pointless single-tenant picker."
- **List, don't free-type:** when multiple tenants are in scope, replace the "type an ID" dead-end
  with a **tenant switcher** listing the available tenants (the stress-fixture cohort gives this a
  reason to exist — 2–3 personas). v1.11 IA-LD-07(a) already says "No tenant selected" should be a
  cause-naming empty state — this milestone upgrades it from *prose* to an *actionable list*.
- **Distinguish no-tenant-chosen from no-access:** see the permission-denied state above. "Pick a
  tenant" (here's the list) ≠ "you don't have access" (ask an admin) ≠ "no tenants exist yet."
- **Host-app-friendly:** the admin does NOT own tenant identity — the host's `Mailglass.Tenancy`
  resolves scope (jobs.md J10). The selector lists what the host exposes; it must not invent or
  persist tenant identity server-side. Current-tenant lives in URL state (v1.11 IA — deep-linkable).
- **Anti-features:** a global cross-tenant "all tenants" mega-view (data-leak risk, and tenancy is
  first-class-isolated by design — D-09); a tenant *management* CRUD (create/invite) — that's the
  host app's job, not a mail-ops console.

| Feature | Tag | Complexity | Fractal / Persona / Depends-on |
|---------|-----|------------|--------------------------------|
| **Auto-select sole tenant** (no picker when count==1) | **Table stakes** | MED | Component-groups · P3/P4 · tenant_chip (shell.ex:245), Tenancy (J10) |
| **Tenant switcher list** when count>1 (replaces free-text dead-end) | **Table stakes** | MED | Component-groups · P3/P4 · IA-LD-07(a), stress fixtures |
| Current-tenant shown prominently; switch preserves URL/filter context | **Table stakes** | LOW | Component-groups · P4 · URL-state (v1.11 IA) |
| Pin/favorite frequent tenants | **Anti-feature (defer)** | — | over-engineered for a mail-ops console with a bounded tenant set |
| Cross-tenant "all tenants" view | **Anti-feature** | — | data-leak risk; violates first-class tenant isolation (D-09) |

---

### Level 6 — Pages & flows

#### Table Stakes

| Feature | Why Expected | Complexity | Fractal / Persona / Depends-on |
|---------|--------------|------------|---------------------------------------|
| **GOV.UK-style IA** — one clear job per surface, named landmarks, breadcrumb/back where master-detail | Principle of least surprise; already largely locked | MED | Pages · all · v1.11 IA-LD-01..09 — audit + extend to 320px |
| **Per-persona happy/error/boundary/edge path** reachable by seeded URL | v1.7 SEED-01/02 + v1.11 made every state URL-reachable; extend to new states (permission, stale, system-theme) | MED | Pages · all · v1.7/v1.11 seed work + new stress fixtures |
| **Coherent spacing/hierarchy** across groups (no chopped padding / misalignment) | In PROJECT bug list ("chopped padding, inconsistent spacing, misalignment") | MED | Pages · P1 evaluator · spacing tokens (foundations) |

#### Differentiators

| Feature | Value Proposition | Complexity | Depends-on |
|---------|-------------------|------------|------------|
| **Idempotent no-regression ratchet** extended to system-theme × WCAG 2.2 AA × 320/wide | Proves award-winning bar is *held*, not just *reached*; the v1.11 differentiator, widened | HIGH | Pages · maintainer · v1.11 RATCHET-01..05 |
| **Microcopy pass** (recovery-oriented, domain-noun-consistent, "Oops" banned) across new states | Voice consistency is a craft signal evaluators feel | LOW | Pages · P1/P3 · v1.11 COPY-LD-01..16 — extend to permission/stale copy |

---

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **PhoenixStorybook dependency** for the component lab | "Real Storybook" feels professional | New dep; pulls a build/JS story; violates zero-Node + minimal-deps scope lock | In-house `/dev/mail/gallery` matrix (already seeded v1.11) — decision brief leans in-house |
| **Squished responsive table** (horizontal scroll / crushed columns on mobile) | "Just make the table responsive" | Hides identifier, breaks scanning — the exact named bug | Row-to-card transform <768px |
| **Sortable/filterable mega-table of everything** (Kaffy/AshAdmin auto-admin) | "Show me all the data" | Audit surfaces are master-detail + triage, not CRUD lists; tableizing kills the workflow | Plain filters + master-detail + triage cards (v1.11 locked) |
| **Pagination bar that's always visible** | "Tables have pagination" | "Page 1 of 1" with dead arrows is noise | Count always; pagination only when >1 page (GOV.UK) |
| **Server-persisted per-user/per-tenant theme** | "Remember my theme everywhere" | Mountable library must not own user/theme storage; collides with host | Client-scoped override + System default |
| **Cross-tenant "all tenants" dashboard** | "One view of everything" | Data-leak risk; violates first-class tenant isolation (D-09) | Per-tenant scope + tenant switcher |
| **Tenant CRUD (create/invite/manage)** in the picker | "Manage tenants here" | That's host-app identity, not mail-ops | Switcher lists host-exposed tenants only |
| **Infinite scroll** on audit lists | "Modern feel" | Breaks deep-linkability + "find the one failure" scanning | Bounded window + count + explicit load-more |
| **Spinner-everywhere loading** | "Show it's loading" | Layout shift; feels slower than skeletons | Skeleton loaders (Carbon) |
| **Color-only severity** | "Cleaner look" | Fails colorblind / dark-mode / glance under stress (WCAG 1.4.1) | Icon + label + color (Carbon status-indicator) |
| **Illustration-heavy empty states** (Polaris-style) | "Friendlier" | Brand-specific assets; weight; zero-asset constraint | Icon + heading + actionable sub-copy (already locked) |

---

## Feature Dependencies

```
Foundations: semantic tokens + z-index system + motion/focus tokens (light/dark/SYSTEM)
    └──requires──> Theme picker (system/light/dark, system default)
                        └──enhances──> Preview dark chrome (closes v1.11 GAP-03)

Stress-fixture cohort (2–3 tenant personas × edge data)
    └──required-by──> Multi-tenant selector (needs >1 tenant to be meaningful)
    └──required-by──> Stat-card overflow/truncation proof (needs long-ID/non-ASCII/high-count)
    └──required-by──> Empty/no-results/no-permission/stale state proof
    └──required-by──> Row-to-card responsive proof (needs many/long rows)

Multi-tenant selector
    ├──auto-select (count==1)  ──kills──> "pointless single-tenant picker" bug
    └──switcher (count>1)      ──kills──> "No tenant selected" dead-end (with permission-denied split)

Stat-card canonical component
    └──requires──> severity-first encoding (icon+label+color)
    └──enhances──> operator-under-stress 5-second test

Honest pagination  ──conflicts──> infinite scroll / always-on pagination bar
Row-to-card        ──conflicts──> squished responsive table
System-theme       ──conflicts──> server-persisted theme

Idempotent ratchet (extended) ──gates──> every feature above (meet-or-beat, no regression)
```

### Dependency Notes

- **Stress fixtures are the keystone.** Almost every data-display and state feature is only
  *provable* against a fixture cohort that includes the edge cases (long IDs, non-ASCII,
  high-count, null, error). Build the cohort early — it's the substrate for the whole milestone.
- **Multi-tenant selector requires the fixtures** (a switcher over one fake tenant proves nothing).
- **Theme picker requires foundations** (system-theme parity in every token) before it can be
  proven across the gallery matrix.
- **The ratchet gates everything** (v1.11 precedent): widen its axes (system, WCAG 2.2 AA, 320/wide)
  before scoring, so "award-winning" is held, not just claimed.

---

## MVP Definition (for this quality milestone)

### Launch With (must ship this milestone)

- [ ] **Theme picker: system / light / dark, system default** — the headline fix; host-friendly, scoped persistence, drives Preview chrome too
- [ ] **Stress-fixture cohort (2–3 tenant personas + edge data)** — the proving substrate
- [ ] **Multi-tenant selector** — auto-select sole tenant + switcher list (kills both named bugs)
- [ ] **Permission-denied state** distinct from no-tenant and from crash
- [ ] **Stat-card canonical component** — label-truncate+tooltip, value-never-wraps, severity-first (fixes "clipped labels")
- [ ] **Row-to-card responsive transform** for Deliveries + Inbound lists <768px (kills squished tables)
- [ ] **Honest pagination** — count always, controls only when >1 page
- [ ] **44×44 touch-target resolution** (the btn-sm/min-h-11 tension) — verified in compiled bundle
- [ ] **Foundations: z-index layer system + token coverage in light/dark/system** (fixes modal-behind-scrim)
- [ ] **Usability-bug sweep** (modal-behind-scrim, scroll traps, hover on non-interactive heroes, misalignment, chopped padding, disabled-looking-enabled)
- [ ] **Extended idempotent ratchet** (system theme + WCAG 2.2 AA + 320/wide)

### Add After (if capacity)

- [ ] **Stale-data indicator** ("as of HH:MM" + refresh) on live surfaces — P4 SRE polish
- [ ] **Skeleton loaders** for master/detail — perceived-latency polish
- [ ] **LiveView streams** for live-append lists — idiomatic, if a fixture needs live growth
- [ ] **Component-lab matrix** widened to full component×state×theme×viewport — strong audit surface but high effort

### Future / Out of Scope

- [ ] Pin/favorite tenants — over-engineered for a bounded mail-ops tenant set
- [ ] PhoenixStorybook — deferred to decision brief, leaning in-house (zero-Node)
- [ ] Server-persisted theme, cross-tenant view, tenant CRUD — anti-features (host-app concerns / leak risk)

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Theme picker (system/light/dark, system default) | HIGH | MED | P1 |
| Multi-tenant selector (auto-select + switcher) | HIGH | MED | P1 |
| Stress-fixture cohort | HIGH (enabler) | HIGH | P1 |
| Stat-card canonical + overflow/truncation fix | HIGH | MED | P1 |
| Row-to-card responsive transform | HIGH | MED | P1 |
| Permission-denied state | MED | MED | P1 |
| Honest pagination | MED | LOW | P1 |
| 44px touch-target resolution | MED | LOW | P1 |
| z-index layer system + foundations parity | MED | LOW | P1 |
| Severity-first encoding (icon+label+color) | MED | LOW | P1 |
| Usability-bug sweep | HIGH | MED | P1 |
| Extended ratchet | MED (proof) | HIGH | P1 |
| Stale-data indicator | MED | MED | P2 |
| Skeleton loaders | MED | MED | P2 |
| LiveView streams | LOW | MED | P3 |
| Component-lab full matrix | MED | HIGH | P2/P3 |
| Pin/favorite tenants | LOW | MED | P3 (likely never) |

**Priority key:** P1 = must have for this milestone · P2 = should have, add when possible · P3 = future

---

## Competitor / Source Feature Analysis

| Pattern | Carbon | Polaris | GOV.UK | Oban Web / LiveDashboard | Our Approach |
|---------|--------|---------|--------|--------------------------|--------------|
| Theme picker | data-theme tokens, system honored | light/dark tokens | light only (no dark) | dark done well (Oban), basic (LiveDashboard) | **3-way system/light/dark, system default, host-scoped** |
| Tables vs cards | DataTable + skeletons | IndexTable vs ResourceList (explicit) | low-density tables | server-streamed tables (squish on mobile) | **table ≥768, row-to-card <768** |
| Stat/KPI cards | status-indicator (shape+color+label) | reused card, tone vocab | n/a | queue-health tiles (Oban) | **canonical card, severity-first, label-truncate/value-no-wrap** |
| Empty/error states | DataTable empty/error built-in | EmptyState + Banner | error summary + content design | minimal | **4-template taxonomy (+ permission +stale NEW)** |
| Pagination | numbered + boundary disable | pagination component | **hide if one page** | live tables, some pagination | **count always, chrome only >1 page** |
| Multi-tenant select | n/a | n/a | n/a | "this node/all nodes" (LiveDashboard) | **auto-select sole + switcher list, no free-text** |
| Operator-under-stress | status-indicator + notification taxonomy | tone + Banner | n/a | severity-first queue health (Oban — best peer) | **5-sec test: state/severity/next-action; drill path** |
| Nav active-state | aria-current + visible | selected + aria-current | destination labels | tab active-state | **aria-current + visible (already locked v1.11)** |

---

## Sources

Mature design systems:
- [Carbon — Status indicator pattern](https://carbondesignsystem.com/patterns/status-indicator-pattern/)
- [Carbon — Notification usage](https://carbondesignsystem.com/components/notification/usage/)
- [Shopify Polaris — Banner](https://polaris-react.shopify.com/components/feedback-indicators/banner)
- [GOV.UK Design System](https://design-system.service.gov.uk/) and Service Manual (IA, content design, pagination "don't show if one page")
- Atlassian Design System — EmptyState (no-data / no-results / error / no-permission), inline-message vs flag vs section-message

Theme picker:
- [Smashing Magazine — Setting and persisting color scheme preferences](https://www.smashingmagazine.com/2024/03/setting-persisting-color-scheme-preferences-css-javascript/)
- [MDN — prefers-color-scheme](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-color-scheme)
- [Aleksandr Hovhannisyan — The Perfect Theme Switch Component](https://www.aleksandrhovhannisyan.com/blog/the-perfect-theme-switch/)
- [Muzli — Dark Mode Design Systems: Patterns, Tokens, Hierarchy](https://muz.li/blog/dark-mode-design-systems-a-complete-guide-to-patterns-tokens-and-hierarchy/)

Tables vs cards (responsive):
- [Sonneil Tech — Responsive data tables for mobile](https://sonneiltech.com/2020/11/how-to-make-responsive-data-tables-for-mobile-platforms/)
- [Appnroll (Medium) — 5 practical solutions for responsive data tables](https://medium.com/appnroll-publication/5-practical-solutions-to-make-responsive-data-tables-ff031c48b122)
- [Toptal — Mobile dashboard UI best practices](https://www.toptal.com/designers/dashboard-design/mobile-dashboard-ui)

Multi-tenant selector:
- [Microsoft 365 admin — Manage multiple tenants / tenant switcher](https://learn.microsoft.com/en-us/microsoft-365/admin/multi-tenant/manage)
- [Clerk — Multi-tenant auth / OrganizationSwitcher](https://clerk.com/blog/how-to-build-multitenant-authentication-with-clerk)

Operator-under-stress:
- [Carbon — Status indicator pattern](https://carbondesignsystem.com/patterns/status-indicator-pattern/) (severity = shape+color+label)
- [iFactory — Smart infrastructure monitoring: what good looks like](https://ifactoryapp.com/industries/infrastructure-management/smart-infrastructure-monitoring-dashboard-good-looks) (5-second test, three-tier hierarchy)

Elixir/Phoenix ecosystem admin UIs (idiomatic reference): Phoenix LiveDashboard, Oban Web, Backpex (daisyUI/LiveView, same stack), Kaffy, AshAdmin.

Project-internal (LOCKED — extended not redone):
- `.planning/research/v1.11/IA.md` (IA-LD-01..09), `COMPONENT-STATES.md` (STATE-LD-01..22), `MICROCOPY.md` (COPY-LD-01..16), `DARK-MODE.md`, `MOTION.md`
- `.planning/PROJECT.md` (v1.13 scope, D-09 tenant isolation, named bugs), `guides/jobs.md` (J9 operator, J10 multi-tenant)
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (tenant_chip, theme_toggle, orientation_strip)

---
*Feature research for: mailglass_admin design-system stress test & UX uplift (v1.13)*
*Researched: 2026-06-18*
