# Domain Pitfalls — v1.7 Admin UI/UX & IA Polish

**Domain:** Node-free Phoenix LiveView design-system hardening + IA + motion + seed data, mailglass_admin v2 polish milestone (GSD phases 74–79)
**Researched:** 2026-06-03
**Confidence:** HIGH (grounded in actual source files + confirmed blueprint constraints; no speculative claims)

---

## Critical Pitfalls

### Pitfall 1: Tailwind JIT silently drops dynamically constructed class names

**What goes wrong:**
A developer writes a class string like `"badge-#{status}"` or `"gap-#{size}"` in HEEx. The standalone Tailwind binary scans for literal strings; it never evaluates Elixir interpolation. The class is tree-shaken to nothing. The page renders without that style and no error appears — locally or in CI. The bundle gate (`git diff --exit-code priv/static/`) passes because a rebuild was done, but the rebuilt bundle just doesn't contain the missing class. The failure only surfaces visually.

**Why it happens:**
The badge-atom consolidation work (Phase 76) requires mapping status atoms to CSS class strings. It is natural to reach for `"badge-#{atom}"`. Developers from JS frameworks expect build-time scanning to handle dynamic usage. The zero-Node setup (standalone Tailwind binary, no PostCSS plugins) makes it even harder to get IDE warnings.

**Warning signs:**
- Any string with `#{}` in a HEEx class attribute or in the return value of a `badge_class/1`-style function
- A visual element that renders with no color/style despite having class logic
- The rebuilt bundle size is smaller than expected after adding new badge variants

**How to avoid:**
Return only literal complete strings from `badge_class/1` and any helper that produces CSS classes. Each atom maps to a full string: `do: "badge-success"` not `do: "badge-#{color}"`. The unified badge atom in `components.ex` must enumerate every possible status string as a literal. Add a test that calls `badge_class/1` or its equivalent for every atom in the taxonomy table and asserts a non-empty, non-interpolated string result — this catches future authors adding dynamic paths.

**Phase to address:** Phase 76 (badge atom consolidation); acceptance criterion: zero interpolated class strings in `badge_class/1` or any extracted helper.

---

### Pitfall 2: Editing HEEx without rebuilding and committing `priv/static/app.css`

**What goes wrong:**
A developer adds or changes Tailwind utility classes in any `.ex` file, runs the local server which hot-reloads fine (Tailwind binary is watching), but forgets to run `mix mailglass_admin.assets.build` and commit the rebuilt `priv/static/app.css` in the same branch. CI runs `git diff --exit-code priv/static/` after a fresh build and fails the check. This blocks merge and requires a follow-up fixup commit.

The inverse also happens: a developer rebuilds but does NOT commit the bundle. The check passes locally (`git diff` sees nothing staged) but fails in CI because CI does a fresh build from source.

**Why it happens:**
There is no Node build step to automate this in the contributor workflow. The rebuild is a `mix` task but it is easy to forget in the "just add a class" pattern. Token-migration work in Phase 76 touches many files across `support_cards.ex`, `operator_live.ex`, `inbound_live.ex`, and their subcomponents — each file change is a bundle-invalidation event.

**Warning signs:**
- CI `git diff --exit-code priv/static/` step fails on a PR that has HEEx changes
- Local visual looks correct but CI fails the asset gate
- The commit diff contains `.ex` changes but no `priv/static/app.css` change

**How to avoid:**
Add "rebuild + commit bundle" as a mandatory checklist item on every PR template or phase plan for Phases 75–78. Run `mix mailglass_admin.assets.build && git diff priv/static/` before pushing. The Phase 79 verification gate re-runs the build and asserts clean diff as a final closeout check.

**Phase to address:** All HEEx-touching phases (75, 76, 77, 78); enforcement gate in Phase 79.

---

### Pitfall 3: daisyUI 5 class drift — using classes that no longer exist or changed semantics

**What goes wrong:**
daisyUI 5 (the version in use) renamed or removed several classes from daisyUI 4. A developer writes a class from memory or a web search result that references an older daisyUI version. Examples: `badge-ghost` instead of `badge-outline`, component classes that were restructured. The class is emitted by Tailwind (it was defined in the daisyUI plugin) but has no visual effect or a wrong effect.

**Why it happens:**
daisyUI 5 was a major breaking release. Web search results, Stack Overflow answers, and the daisyUI v4 docs are still widely indexed and returned. The badge taxonomy consolidation work in Phase 76 requires explicitly enumerating all badge variants — if the list is sourced from memory or stale docs, wrong class names enter the codebase.

**Warning signs:**
- A badge renders unstyled (no color) despite having a class
- Visual inspection shows the class is present in DevTools but no styles match
- The class name came from a search result dated before daisyUI 5's release

**How to avoid:**
Verify every daisyUI component class against the installed version. Run `cat mailglass_admin/assets/css/app.css | grep "@plugin\|daisyui"` to confirm the installed plugin and version. Cross-reference the daisyUI 5 component documentation (not v4 docs) for the exact class names. The canonical badge taxonomy table produced in Phase 74 should list only daisyUI-5-verified class names, and Phase 76 implementation must stay within that table.

**Phase to address:** Phase 74 (audit + taxonomy table); Phase 76 (badge atom implementation).

---

### Pitfall 4: "Restructure-then-tokenize" order inverted — tokenizing inside an unrestructured layout

**What goes wrong:**
A developer migrates `support_cards.ex` from `text-sm` to `text-body` and `gap-3` to `gap-sm` while the 2×2 flat grid structure is still in place. The token migration is complete by grep, the gate passes, but then the support-card grid redesign (primary/secondary hierarchy, demoting zero-state cards) requires touching the same lines again to rewrite the layout. The token classes are on the wrong elements or are inherited from the wrong container. The redesign undoes some of the token migration. The developer re-migrates tokens. Two churn passes where one would suffice; risk of inconsistency increases with each pass.

**Why it happens:**
Token migration feels "safe" and parallelizable. The restructure feels "bigger." Developers do the easy thing first. The blueprint explicitly warns about this trap but it requires discipline at the moment of execution to honor the order.

**Warning signs:**
- The support-card grid still shows `xl:grid-cols-2` flat layout after token migration is marked complete
- Token migration PRs touch `support_cards.ex` before Phase 75/76 has decided on the new hierarchy structure
- A Phase 76 PR re-edits the same lines that were token-migrated earlier in the same phase

**How to avoid:**
Within Phase 76, explicitly sequence the work: (1) redesign the support-card hierarchy (structure, new primary/secondary split, new container markup), (2) then token-migrate the final markup. Do not begin `support_cards.ex` token migration until the new layout structure is committed and reviewed. The Phase 74 UI-SPEC must specify the new support-card layout before Phase 76 starts, not during.

**Phase to address:** Phase 74 (finalize support-card layout in UI-SPEC); Phase 76 (honor restructure-first order).

---

### Pitfall 5: Badge taxonomy consolidation silently changes a status's color

**What goes wrong:**
The three existing `badge_class/1` copies disagree on at least one status. For example, `deliveries_list.ex` maps `:suppressed` to `badge-warning`, but if `timeline.ex` maps the analogous event type differently, or the new unified atom makes a different judgment, operators who have learned to read color as a forensic signal see a color change without any code notice. `:suppressed` was orange (warning), now it is outlined/grey — an operator glancing at the list draws the wrong conclusion about severity.

**Why it happens:**
The consolidation goal is "one definition," but the three copies were independently authored and may have divergent opinions baked in. Choosing which copy "wins" is a semantic decision, not just a mechanical deduplication. The person doing the consolidation may not realize the copies disagree until they are side-by-side.

**Warning signs:**
- Diffing the three `badge_class/1` implementations reveals the same atom maps to different CSS classes
- The Phase 74 taxonomy table was produced without comparing all three implementations
- The consolidated implementation was derived from only one source file

**How to avoid:**
Phase 74 must produce the canonical status-badge taxonomy table by explicitly comparing all three implementations side-by-side, noting every disagreement, and making a deliberate decision for each conflict (not silently defaulting to one copy). The Phase 74 UI-SPEC deliverable includes this table. Phase 76 implementation is gated on the Phase 74 table being signed-off. Add a test that asserts the specific CSS class for every status in the taxonomy — this makes future regressions visible rather than silent.

**Phase to address:** Phase 74 (conflict inventory and taxonomy table decision); Phase 76 (implementation and regression test).

---

### Pitfall 6: Entrance motion firing on every LiveView patch instead of only on mount

**What goes wrong:**
`motion-reveal` (and `motion-timeline`) rely on CSS `animation`. In Phoenix LiveView, when the server pushes a diff, the existing DOM node is patched in place — the animation class is already present, no re-mount occurs, so the animation does not re-fire. This is correct behavior for stable components. However: if a component's container element gets a new `id` or is conditionally rendered via `:if` that toggles to true, LiveView replaces the DOM node, the class is applied on insertion, and the animation fires again. The problem is introduced when Phase 76/77 adds motion to components that use `:if` guards on the detail pane — each filter change that toggles a result on/off will retrigger the entrance animation. Result: an operator filtering deliveries sees a flash/bounce on every keystroke.

**Why it happens:**
Developers test motion on initial page load, where everything looks smooth. They do not test the "filter, select, filter again" operator workflow where the same animation fires on every state change. The `motion-reveal` class on `<div class="motion-reveal space-y-4">` in `operator_live.ex:332` is already there; if Phase 77 adds more `motion-reveal` wrappers around detail-pane content that is toggled via `:if`, the behavior becomes jarring.

**Warning signs:**
- A `motion-reveal` class is on an element that is conditionally rendered via `:if` or conditional `assigns`
- Changing a filter or selecting a different row causes a visible animation on every change, not just on initial load
- The motion element's parent has a dynamic `id` tied to `delivery_id` or `inbound_id`

**How to avoid:**
Anchor entrance animations to element insertion, not to a wrapping container that is always present. Use a stable `id` on the animated element keyed to the displayed record (`id={"detail-#{@delivery_id}"}`), so that selecting a new record causes LiveView to replace the element and re-run the animation — but only once per record selection, not on every patch. Do not apply `motion-reveal` to containers that are patched in place on filter changes. Phase 77 plan must include a "motion triggers per user action" test matrix.

**Phase to address:** Phase 77 (motion implementation); acceptance criterion: verify motion fires once on record select, not on every filter patch.

---

### Pitfall 7: Animating height, width, or padding (layout jank)

**What goes wrong:**
A developer adds a CSS transition or animation on `height`, `max-height`, `width`, or `padding` to create an "expand/collapse" or "accordion" effect on support cards or orientation content. This forces the browser to recalculate layout on every animation frame (layout thrash), producing visible jank at 390px and 768px where reflow is more expensive. The brand motion vocabulary explicitly prohibits height/width animation (`animate transform/opacity only`) but it is tempting when collapsing a zero-state support card.

**Why it happens:**
The support-card redesign (Phase 76) changes the grid to primary/secondary hierarchy. The "secondary/compact" row is a new layout state. Making the transition between states smooth is a natural impulse. `transition-all` or `transition-height` is the naive reach.

**Warning signs:**
- Any `transition-height`, `transition-max-height`, `transition-padding`, or `transition-all` in HEEx
- A CSS keyframe that animates `height: auto` or `max-height: 0 → max-height: 500px`
- Visible jank on mobile (390px) during support-card state changes

**How to avoid:**
The support-card hierarchy change (zero-state cards demoted to a compact summary row) should be a static layout difference, not an animated transition. Apply the compact layout based on the data at render time; do not animate between the two states. If a soft transition between card states is genuinely needed, use `opacity` only (crossfade via `motion-tab-swap`) on a key-change that causes LiveView to swap the element. No height animation, ever.

**Phase to address:** Phase 76 (support-card redesign); Phase 77 (motion audit).

---

### Pitfall 8: Missing `prefers-reduced-motion` neutralization on new motion additions

**What goes wrong:**
The CSS already has a global `@media (prefers-reduced-motion: reduce)` block that sets `animation-duration: 0.01ms` on `*, ::before, ::after`. Any motion that goes through a standard CSS `animation` rule is automatically neutralized. However: if Phase 77 introduces motion via inline `style` attributes (`style="animation-duration: 220ms"`), via Phoenix.LiveView.JS transition parameters, or via a custom CSS class that is not an `animation` but a `transition` on a non-covered property, the global block may not catch it. Vestibular disorder users experience motion sickness.

**Why it happens:**
The existing coverage is comprehensive for `animation`. Developers adding new `JS.transition/2` calls for enter/exit effects may not realize the JS-driven transitions are separate from the CSS animation system. LiveView.JS `transition` applies classes for a tick then removes them; if those classes use properties not covered by the reduced-motion block, the motion fires regardless.

**Warning signs:**
- New `JS.transition/2` calls in Phase 77 that use custom class names not in the six named vocabulary motions
- `style="..."` attributes with explicit `animation-duration` or `transition-duration` that override the global block
- Any `transition-` class on a property other than `colors` / `opacity` / `transform`

**How to avoid:**
Restrict motion additions to the six named vocabulary motions (`motion-reveal`, `motion-timeline`, `motion-tab-swap`, `motion-overlay`, `row-state`, `flash`). Every new `JS.transition/2` call must use only class names from this vocabulary. If a genuinely new motion type is needed, add it to the CSS vocabulary block and verify the `@media (prefers-reduced-motion)` block covers it. Phase 77 acceptance criterion: test under `prefers-reduced-motion: reduce` (can be forced via Playwright `page.emulateMedia({ reducedMotion: 'reduce' })`) and confirm no visible movement.

**Phase to address:** Phase 77 (motion implementation and verification).

---

### Pitfall 9: Motion duration exceeds 300ms or uses non-ease-out easing

**What goes wrong:**
The design system caps all motion at 300ms and requires ease-out only. A developer adds a new reveal or adds a `duration-` override in HEEx that pushes a transition past 300ms, or uses `ease-in-out` or `ease-linear` (both present in Tailwind utilities and easy to reach for). The brand metaphor ("content arrives by becoming visible") is violated and the UI feels sluggish on operator surfaces where high-frequency actions occur.

**Why it happens:**
300ms feels fast at design time on a fast machine with a large viewport. At 390px or on a lower-power device, 300ms can already feel too slow. The natural pull is toward "a bit more smoothness" which translates to longer durations. `ease-in-out` is the most commonly used easing and is the Tailwind default for `transition` utilities.

**Warning signs:**
- `duration-300` or higher on a new motion element
- `ease-in-out` or `ease-linear` class on any animated element
- Transition feel is sluggish on mobile

**How to avoid:**
Use only named duration tokens (`duration-(--duration-instant)`, `duration-(--duration-fast)`, `duration-(--duration-reveal)`, `duration-(--duration-flash)`) — all are ≤300ms by design. Use only `ease-out` (the `--ease-out` token). Phase 77 plan should include a grep: `grep -rn "duration-3[0-9][0-9]\|duration-4\|duration-5\|ease-in-out\|ease-linear" mailglass_admin/lib/ mailglass_admin/assets/`.

**Phase to address:** Phase 77 (motion implementation); Phase 79 (conformance grep gate).

---

### Pitfall 10: `demo.spec.js` heading/seed-count assertions break when IA headings or Operator Overview route changes

**What goes wrong:**
`reference/demo_app/assets/e2e/demo.spec.js` asserts exact heading text:

```
page.getByRole("heading", { name: "Deliveries", exact: true })
page.getByRole("heading", { name: "Inbound records", exact: true })
```

Phase 75 adds a new Operator Overview landing at `/ops/mail/` and normalizes page titles/subtitles/headings. If "Deliveries" becomes "Outbound deliveries" or the landing page heading changes, the exact-match assertions fail. Phase 78 expands seed data significantly — if `demo.spec.js` or `operator.spec.js` had assertions like `toHaveCount(6)` (the current delivery seed count), those break. The e2e suite fails and blocks merge.

**Why it happens:**
The IA changes (Phase 75) and seed expansion (Phase 78) are scoped correctly as "in-scope deliverables," but the spec updates are a separate file in a separate directory from the feature work. It is easy to commit the heading rename without updating the spec. The spec file only runs in CI (Playwright), not in development iteration.

**Warning signs:**
- A PR containing `operator_live.ex` heading changes does not touch `demo.spec.js` or `operator.spec.js`
- A PR expanding `seeds.exs` does not update count assertions in either spec
- CI Playwright step fails after IA or seed changes

**How to avoid:**
Phase 74 (audit) must explicitly inventory every string assertion in `demo.spec.js` and `operator.spec.js` that references page headings, section labels, or seed-count assumptions. Produce an "assertion inventory" table. Every Phase 75 heading change and every Phase 78 seed-count change must update the corresponding assertion in the same commit. Acceptance criterion: Playwright passes in the same PR, not as a follow-up.

**Phase to address:** Phase 74 (inventory assertions); Phase 75 (update heading assertions in same commit); Phase 78 (update count assertions in same commit).

---

### Pitfall 11: Bumping mailglass version pins in `reference/host_app` or `demo_app` as part of this milestone

**What goes wrong:**
`reference/host_app` and `reference/demo_app` have version pins that are frozen baselines. Bumping them is a coordinated 5-file change (2 `mix.exs` + 2 `mix.lock` + `check_clean_baseline_hex_only.sh` + `ci_trust_lane_contract_test.exs`). A developer doing demo seed or IA work notices the reference apps are pinned to an older version and "helpfully" bumps them to the current `1.4.5` in the same PR. This breaks the frozen baseline contract, causes the baseline CI lane to fail in unexpected ways, and introduces transitive lock drift.

**Why it happens:**
The admin UI work legitimately touches `reference/demo_app/priv/repo/seeds.exs` and `reference/demo_app/assets/e2e/demo.spec.js` — both are demo-data and UI files, not dependency files. The `mix.exs` is in the same directory and the version looks stale. The developer bumps it reflexively.

**Warning signs:**
- A Phase 75–78 PR diff includes changes to `reference/demo_app/mix.exs` or `reference/host_app/mix.exs`
- `mix.lock` changes in either reference directory outside a planned baseline bump
- CI baseline lane fails on "unexpected version" after an IA or seed PR

**How to avoid:**
Explicitly call out in every Phase 75–79 plan: "Do NOT touch `mix.exs` version pins or `mix.lock` in `reference/host_app` or `reference/demo_app`. Those are frozen baselines and require a separate coordinated 5-file change." Demo seed data and e2e spec changes in `reference/demo_app/` are fine. Only dependency files are off-limits.

**Phase to address:** Phase 74 (note in scope constraints); Phases 75, 77, 78 plans (explicit do-not-touch guardrail).

---

### Pitfall 12: Linked-version release mechanics — admin minor bump drags all siblings

**What goes wrong:**
This milestone touches only `mailglass_admin`. But Release Please's linked-versions plugin is configured with `separate-pull-requests: false`, and `mailglass_admin/mix.exs` pins `{:mailglass, "== <version>"}`. When Phase 79 produces a release, an admin `1.5.0` bump mechanically creates a matched `mailglass` 1.5.0 and `mailglass_inbound` 1.5.0 release even though no core or inbound API changed. The CHANGELOG entries for core and inbound will be empty or contain only "Bump version to match admin." This is correct behavior but surprises adopters who see three package releases for what looks like admin-only work.

**Why it happens:**
Linked-version releases are a deliberate D-01 decision. The mechanical coupling is correct. The pitfall is not the behavior — it is forgetting to document it, and then making a last-minute decision to "fix" it by unlinking versions, which would break the `== <version>` pin.

**Warning signs:**
- Planning documents that assume "this is admin-only, no release ceremony needed for core"
- A PR author trying to skip the Release Please linked-version entry for core/inbound
- Release notes that don't acknowledge the admin-only nature of the content changes

**How to avoid:**
Phase 74 (or the milestone kickoff) should include a note: "Release ceremony will produce matched `1.5.0` across all three packages; core and inbound changelogs will be administrative version-bump entries only. This is expected and correct." Do not attempt to decouple versions. Include one-line "admin UI polish release" CHANGELOG entries for core and inbound when the release PR is opened.

**Phase to address:** Phase 74 (note in milestone scope); Phase 79 (include in release ceremony checklist).

---

### Pitfall 13: IA freeze violation — building Phase 76/77 on an unfrozen IA

**What goes wrong:**
Phase 75 adds the Operator Overview route and generalizes `orientation_strip` to all three surfaces. Phase 76 builds the badge atom and redesigns support cards. If Phase 75 work is still in flux (e.g., the Operator Overview route path or heading text is not finalized) when Phase 76 begins building components that reference those headings or link into that route, Phase 76 work requires rework when Phase 75 finalizes. The badge atom may reference a route that changes. The support-card "View all deliveries" link may reference a heading that changes.

**Why it happens:**
In parallel execution (the blueprint notes Phases 77/78 ride alongside 75/76), there is pressure to start Phase 76 early. The IA is "mostly done." The two-day difference feels minor.

**Warning signs:**
- Phase 76 work begins before Phase 75 PR is merged and IA headings/routes are final
- Phase 74 UI-SPEC does not include final route paths or exact heading text for the Operator Overview
- Phase 76 components contain heading strings that are still under discussion

**How to avoid:**
The anti-churn contract in the blueprint is the prevention: freeze IA and taxonomy table at end of Phase 74. "Freeze" means committed to main, not just drafted. Phase 76 does not start implementation until Phase 75 is merged and the IA is locked. Phase 74 deliverable must include exact heading strings and exact route paths for the Operator Overview, not placeholders.

**Phase to address:** Phase 74 (freeze IA in UI-SPEC deliverable); Phase 75 (merge before Phase 76 implementation begins).

---

### Pitfall 14: Scope expansion without a gap-register citation

**What goes wrong:**
A developer doing Phase 76 token migration notices the preview surface also has `text-sm` drift and adds preview token migration to the same PR. No Phase 74 gap-register row covers the preview surface at severity ≥ 3. The work is added as "while we're here." This violates the anti-churn contract, adds untested scope, and may ripple into preview-specific e2e assertions that were not in the Phase 74 assertion inventory.

**Why it happens:**
Token migration is mechanical and "obviously right." The surface is right there. The additional work looks small. The gap register feels like bureaucracy when the fix is obvious.

**Warning signs:**
- A PR description that does not cite a gap-register row ID
- A PR that touches files outside the surfaces scoped in Phase 74 (e.g., `preview_live.ex` during Phase 76 which is scoped to operator/inbound surfaces)
- Incremental "while we're here" additions that each feel minor but cumulatively drift the phase scope

**How to avoid:**
The anti-churn contract is absolute: no build task ships without a sev ≥ 3 gap-register row from Phase 74. When genuinely-valid out-of-scope issues are discovered during execution, add them to a backlog row for a future phase rather than expanding the current phase. The Phase 74 gap register is the only gate.

**Phase to address:** Phase 74 (establish gap register with severity scores); all build phases (enforce citation requirement).

---

### Pitfall 15: Mobile (390px) audit skipped — `lg:` and `xl:` breakpoints leave small screens broken

**What goes wrong:**
The operator master-detail is `lg:grid-cols-[minmax(22rem,28rem)_1fr]` — below `lg` (1024px) it collapses. The support-card grid is `xl:grid-cols-2` — below `xl` (1280px) it stacks. The operator shell sidebar is `md:flex hidden` — below `md` (768px) it disappears entirely. At 390px (iPhone 14 base), operators see a completely different layout from the one developed at 1440px. The new Operator Overview route (Phase 75) and support-card hierarchy redesign (Phase 76) can introduce regressions at small viewports that are invisible during development.

**Why it happens:**
Development happens at laptop resolution. The screenshot audit script runs at 1440px unless explicitly configured for 390px. Mobile breakpoints are considered, but the actual 390px render is never screenshot-reviewed because the developer assumes the Tailwind responsive utilities are sufficient.

**Warning signs:**
- Phase 74 screenshot matrix does not include 390px screenshots for the new Operator Overview and support-card hierarchy
- Phase 75 or Phase 76 PRs have no 390px screenshots in the review
- The support-card compact row (Phase 76) is designed only at `xl:` breakpoint

**How to avoid:**
Phase 74 audit must explicitly include 390px across the full matrix for all three surfaces. The `scripts/ui-audit.sh` URL matrix must include a 390px viewport run. Phase 75 (Operator Overview) and Phase 76 (support-card redesign) acceptance criteria must include 390px screenshot review. At 390px, the master-detail collapses to list-only; ensure the new Operator Overview provides a coherent experience at that width before list layout takes over.

**Phase to address:** Phase 74 (include 390px in audit matrix); Phase 75 (Operator Overview 390px acceptance criterion); Phase 76 (support-card hierarchy 390px acceptance criterion).

---

### Pitfall 16: Deep-link unstyled CSS bug — scope decision deferred but left ambiguous

**What goes wrong:**
A hard refresh on a deep URL (e.g., `/ops/mail?tenant_id=foo&delivery_id=bar`) loads the page unstyled because the relative CSS URL resolves against the deep path, not the mount root. This is documented in `design-system.md` and `mailglass_admin/docs/design-system.md`. Phase 75 is the decision point for whether fixing it is in scope. If the decision is not made explicitly and recorded — either "in scope, here is the fix" or "explicitly deferred to backlog" — then Phase 79 (verification) hits the bug during its full audit matrix, flags it as a sev-4/5 gap, and the closeout fails because there is an open sev-4/5 row with no disposition.

**Why it happens:**
The fix touches a stable seam (asset-serving strategy). The blueprint says it needs an explicit decision. Deferring the decision to "later in the milestone" creates a cliff at Phase 79 closeout when the open gap row cannot be closed without either implementing the fix or explicitly lowering its severity with documented rationale.

**Warning signs:**
- Phase 75 plan does not include a section "Decision: deep-link fix in/out of scope"
- Phase 79 gap register has an open sev-4/5 row for the deep-link bug
- The bug is visible in the Phase 79 audit matrix but there is no Phase 74 gap-register row for it

**How to avoid:**
Phase 75 (not Phase 79) must make the explicit decision: in scope or explicitly deferred. If deferred, create a Phase 74 gap-register row for it at the appropriate severity and record the deferral rationale. Phase 79's success criterion is "zero open sev-4/5 rows" — this only works if every sev-4/5 item has either been fixed or been explicitly dispositioned with a rationale and downgraded severity. Do not leave it as an implicit assumption.

**Phase to address:** Phase 74 (register gap, assign severity); Phase 75 (explicit in/out decision); Phase 79 (verify disposition, not open).

---

### Pitfall 17: PII exposure via new telemetry spans or operator-observable fields

**What goes wrong:**
Phase 75 (Operator Overview) shows at-a-glance health: orphan backlog count, recent failure count, suppression count. Phase 78 (seed data) adds rich recipient/subject data for truncation testing. A developer adds a telemetry event from the Operator Overview mount that includes a recipient address in the metadata (e.g., to surface "most recent failed recipient"), or a new LiveView assign that logs the actual recipient for debugging. This violates the non-negotiable rule: telemetry metadata never includes `:to`, `:from`, `:body`, `:subject`, `:recipient`, or any PII.

**Why it happens:**
Operator UX work is about surfacing evidence. The natural next step from "show failure count" is "show who failed." Adding `:recipient` to a telemetry span payload feels like useful debug context during development.

**Warning signs:**
- A new telemetry event in `operator_live.ex` or `operator/shell.ex` that references `delivery.recipient`, `delivery.to`, or any address field
- A new LiveView logging call that includes raw email addresses
- Phase 78 seeds include real-looking email addresses that are surfaced unmasked in the Operator Overview (not through `Components.mask_recipient/1`)

**How to avoid:**
Any new telemetry span added during Phases 75–77 must be reviewed against the PII whitelist: counts, statuses, IDs, latencies only. The `Mailglass.Credo.NoTelemetryPII` Credo check (LINT-05) enforces this at lint time. For the Operator Overview at-a-glance health numbers, use only aggregate counts — never the raw record. Ensure `Components.mask_recipient/1` is used for any per-delivery display in the new overview route, consistent with existing operator surfaces.

**Phase to address:** Phase 75 (Operator Overview implementation); Phase 77 (motion instrumentation); Phase 79 (PII audit in conformance grep gate).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Token-migrate files in isolation without redesigning layout first | Fast grep-green on conformance gate | Token classes on wrong elements; second migration pass needed when layout changes | Never in v1.7 — Phase 76 mandate is restructure-first |
| Leave one `badge_class/1` copy as "canonical" without deleting others | No deletion risk | Three copies re-diverge over time; next operator reads wrong color | Never — delete all three copies, add regression test |
| Run `ui-audit.sh` only at 1440px | Fast audit iteration | Mobile regressions invisible until Phase 79 | Only for rapid inner-loop iteration; Phase 79 must include 390px |
| Skip bundle commit until Phase 79 | Reduces branch churn | Every PR fails the CI asset gate if bundle not committed | Never — rebuild + commit in the same PR as the HEEx change |
| Add `motion-reveal` to a list container that is always in the DOM | Easy "make it animate" | Animation fires only on first page load, not on navigation | Acceptable only if the container is keyed by record ID so a new record causes re-insertion |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Tailwind standalone binary + daisyUI 5 | Using `badge-ghost` (daisyUI v4) instead of `badge-outline` (v5) | Verify class names against the installed plugin; do not trust web search results that predate daisyUI 5 |
| Phoenix LiveView JS + CSS animation | Adding `JS.transition/2` using class names not in the six named motion vocabulary | Only use named vocabulary classes; add new vocabulary entries to CSS first, verify `prefers-reduced-motion` coverage |
| Release Please linked-versions | Assuming admin-only changes skip the core/inbound release PR | All three packages always release together; write administrative CHANGELOG entries for core and inbound |
| `reference/demo_app/mix.exs` | Bumping the mailglass version pin "while in the directory" to match latest | Frozen baseline — do not touch `mix.exs` or `mix.lock`; only seeds and e2e files are in scope |
| `Components.mask_recipient/1` | Displaying raw `delivery.recipient` in the new Operator Overview health panel | Use `mask_recipient/1` for all per-delivery display; use aggregate counts only for health panel |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Operator Overview that is another dashboard requiring its own learning | Operators are disoriented at a "meta" landing — they wanted deliveries | One screen that answers the ONE operator question ("prove what happened") and routes directly to Deliveries/Inbound; the overview is a portal, not a dashboard |
| Orientation strip text that reads like documentation | Operators skip it as boilerplate | Write each strip bullet as a symptom-first action ("Email never arrived? Start here") not a feature description |
| Support-card hierarchy that buries the high-count card | Operators miss the most important signal | Primary/secondary hierarchy: non-zero-count cards first and prominent; zero-state cards compact, not hidden |
| Badge color changes without operator communication | Operators trust learned color meanings; a color change reads as "the status changed," not "the badge was updated" | Freeze taxonomy in Phase 74 before any code change; document the reasoning for each resolved conflict |
| Motion on every filter patch | Operators doing rapid forensic searches see distracting animation on every keystroke | Anchor motion to record-level `id` changes, not container-level presence |

---

## "Looks Done But Isn't" Checklist

- [ ] **Bundle committed:** `priv/static/app.css` updated and committed in the same PR as any HEEx change — verify with `git diff priv/static/` before pushing
- [ ] **Badge classes are literal strings:** zero interpolated class names in `badge_class/1` or any helper — verify with `grep -n "#{"` in all badge helper functions
- [ ] **Three badge copies deleted:** `deliveries_list.ex:80`, `timeline.ex:130`, `inbound/records_list.ex:97` — verify they are absent and all callers route through `components.ex`
- [ ] **Regression test for badge taxonomy:** test calls every atom in the taxonomy table and asserts the exact expected CSS class — verify test exists and covers all statuses
- [ ] **Token conformance grep clean:** zero `text-sm`, `text-base`, `text-xs`, `font-medium`, `font-semibold`, `gap-3`, `gap-4`, `gap-6`, ad-hoc `z-[0-9]+`, hex colors in HEEx — run the Phase 74 grep gate
- [ ] **390px screenshots captured:** Phase 74 audit matrix includes 390px for all three surfaces — verify `tmp/ui-audit/` contains 390px frames
- [ ] **IA heading assertions updated:** `demo.spec.js` and `operator.spec.js` exact-text assertions match new heading text — verify Playwright passes
- [ ] **Seed-count assertions updated:** any `toHaveCount()` or count-dependent assertions in specs updated to match Phase 78 expanded seeds
- [ ] **No `mix.exs` pin bumps in reference apps:** `reference/host_app/mix.exs` and `reference/demo_app/mix.exs` are unchanged — verify with `git diff reference/`
- [ ] **Deep-link decision recorded:** Phase 75 plan includes explicit "in scope / explicitly deferred" decision for the deep-link unstyled bug
- [ ] **Motion does not re-fire on filter patches:** test operator workflow: filter → select → filter again, confirm no repeated entrance animation — manual verification in audit loop
- [ ] **No height/width/padding animation:** `grep -rn "transition-height\|transition-max-height\|transition-padding\|transition-all" mailglass_admin/lib/ mailglass_admin/assets/` returns zero results
- [ ] **prefers-reduced-motion passes:** Playwright `reducedMotion: 'reduce'` run shows no visible movement
- [ ] **No PII in new telemetry:** all new telemetry event metadata contains only counts/statuses/IDs/latencies — review every new `telemetry_execute` call in Phases 75–77
- [ ] **Gap register citation present:** every build task in Phase plans cites a Phase 74 gap-register row at sev ≥ 3

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Dynamic class names emitted, badge silently unstyled | LOW | Replace interpolated strings with a literal lookup map/case; rebuild bundle; regression test |
| Bundle committed without rebuild (CI fails) | LOW | Run `mix mailglass_admin.assets.build && git add priv/static/app.css && git commit --fixup` |
| Badge taxonomy consolidation changed a color | MEDIUM | Revert the specific atom mapping in the unified badge atom; add a regression test for the correct color; ship a patch release |
| Entrance motion fires on every filter patch | MEDIUM | Add record-level `id` to the motion-bearing element (e.g., `id={"detail-#{@delivery_id}"}`); no structural changes needed |
| `demo.spec.js` broken by heading change | LOW | Update the exact-match string in the spec; confirm Playwright passes locally |
| Reference-app version pin accidentally bumped | MEDIUM | Revert the `mix.exs` change; verify `mix.lock` is also reverted; do NOT attempt a baseline bump as a workaround without the full 5-file coordinated change |
| Deep-link bug discovered open in Phase 79 without disposition | HIGH | Either implement the asset-path fix (new scope, new phase) or explicitly downgrade severity and record the rationale in the gap register before Phase 79 closeout |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Dynamic class name JIT tree-shaking | Phase 76 (badge atom implementation) | Grep for `#{` in badge helpers; visual smoke of every badge variant |
| Missing bundle rebuild + commit | Every HEEx-touching phase (75–78) | `git diff --exit-code priv/static/` in Phase 79 gate |
| daisyUI 5 class drift | Phase 74 (taxonomy table) | Compare class names against installed plugin |
| Restructure-then-tokenize order | Phase 74 (UI-SPEC finalizes support-card structure) | Support-card hierarchy committed before token migration begins |
| Badge consolidation silent color change | Phase 74 (three-way conflict inventory + taxonomy decision) | Regression test covering all atoms |
| Entrance motion on every patch | Phase 77 (motion implementation) | Manual: filter + select + filter, confirm one animation per record selection |
| Height/width animation jank | Phase 76 (support-card redesign), Phase 77 (motion polish) | Grep for `transition-height`; visual at 390px |
| prefers-reduced-motion gap | Phase 77 (motion implementation) | Playwright `reducedMotion: 'reduce'` run |
| Motion > 300ms / non-ease-out | Phase 77 (motion implementation) | Grep for `duration-3[0-9][0-9]` and `ease-in-out` |
| e2e spec breakage from IA heading changes | Phase 74 (assertion inventory) + Phase 75 (same-commit spec update) | Playwright passes in Phase 75 PR |
| e2e spec breakage from seed count changes | Phase 74 (assertion inventory) + Phase 78 (same-commit spec update) | Playwright passes in Phase 78 PR |
| Frozen baseline version pin bump | Phases 75–78 plan guardrails | `git diff reference/host_app/mix.exs reference/demo_app/mix.exs` clean |
| Linked-version release surprise | Phase 74 (milestone scope note) | Release ceremony checklist acknowledges all-three-package bump |
| IA freeze violation / re-touch | Phase 74 (UI-SPEC freeze) + Phase 75 (merge before Phase 76 starts) | Phase 76 PR does not touch IA headings or route paths |
| Scope expansion without gap-register citation | All build phases | Every task in phase plans includes gap-register row reference |
| Mobile 390px breakpoint regressions | Phase 74 (audit at 390px) + Phase 75/76 (acceptance criteria) | Screenshots at 390px in Phase 74 baseline and Phase 79 full matrix |
| Deep-link bug undispositioned | Phase 75 (explicit decision) | Phase 79 has no open sev-4/5 rows without disposition |
| PII in new telemetry | Phases 75–77 (implementation discipline) + LINT-05 Credo check | Phase 79 conformance grep; `mix credo --strict` passes |

---

## Sources

- `/Users/jon/.claude/plans/mailglass-context-handoff-serene-noodle.md` — approved milestone blueprint (constraints, risks, weak spots, phase breakdown)
- `/Users/jon/projects/mailglass/mailglass_admin/docs/design-system.md` — CSS architecture, token layers, motion vocabulary, conformance checklist, known limitations
- `/Users/jon/projects/mailglass/.planning/PROJECT.md` — engineering DNA, PII rules, telemetry contract, brand constraints, linked-version mechanics
- Live source inspection: `operator/deliveries_list.ex`, `operator/timeline.ex`, `inbound/records_list.ex`, `operator/support_cards.ex`, `operator_live.ex`, `components.ex`, `operator/shell.ex`, `assets/css/app.css`
- Live spec inspection: `reference/demo_app/assets/e2e/demo.spec.js`, `mailglass_admin/e2e/operator.spec.js`

---
*Pitfalls research for: mailglass_admin v1.7 Admin UI/UX & IA Polish — phases 74–79*
*Researched: 2026-06-03*
