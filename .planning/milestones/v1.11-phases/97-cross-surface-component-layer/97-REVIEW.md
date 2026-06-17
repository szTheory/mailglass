---
phase: 97-cross-surface-component-layer
reviewed: 2026-06-14T16:52:20Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
  - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/device_frame.ex
  - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/router.ex
  - mailglass_admin/e2e/structural.spec.js
findings:
  critical: 0
  warning: 5
  info: 6
  total: 11
status: issues_found
---

# Phase 97: Code Review Report

**Reviewed:** 2026-06-14T16:52:20Z
**Depth:** standard (Elixir/Phoenix/HEEx)
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 97 stands up the cross-surface shared-component layer plus a dev-only component
gallery LiveView (`/dev/mail/gallery`). The security posture is sound: the gallery does no
DB access, no session reads, no `__preview_session__` assigns, mounts inside the dev-only
`live_session :mailglass_admin_preview` block (inheriting the adopter `if dev_routes`
wrapping), uses pre-masked fake data, and the operator/inbound surfaces keep their auth gate.
The whitelisted `__preview_session__`/`__operator_session__` seams remain intact and no PII
leaks into the gallery.

No Critical defects were found. The substantive findings are: (1) a forced-true boolean bug
in the gallery's `evidence_card` dispatch that masks the `denied`/`can_reveal?: false`
specimen state, (2) the gallery renders interactive specimens carrying `phx-click` handlers
the gallery has no `handle_event` for — clicking any specimen crashes the dev LiveView, and
(3) several spec-mandated token-conformance replacements (`px-5`, arbitrary
`tracking-[0.08em]`) were left unapplied across the detail headers, support cards, replay
modal, and operator live, which the UI-SPEC Typography/Spacing sections mark as
conformance-gate violations.

## Warnings

### WR-01: Gallery `evidence_card` dispatch forces `can_reveal?` to always be `true`

**File:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex:321`
**Issue:** The dispatcher passes `can_reveal?={@assigns_map[:can_reveal?] || true}`. In Elixir
`false || true` evaluates to `true`, so the `denied` specimen (`can_reveal?: false`, line 689)
and any future `can_reveal?: false` cell silently render as if reveal were permitted. The
`|| true` idiom defeats the entire point of carrying the boolean. The specimen state matrix
(STATE-LD-19) intends to exercise the denied/cannot-reveal path; this collapses it. (The
current `EvidenceCard.evidence_card/1` body does not branch on `can_reveal?`, so the visible
blast radius today is nil — but this is a latent correctness bug that will produce a wrong
specimen the moment `can_reveal?` is wired into the card, and it is the exact `x || true`
anti-pattern the adversarial pass exists to catch.)
**Fix:**
```elixir
# can_reveal? defaults to true at the attr level (evidence_card.ex:27),
# so pass the map value through and let the attr default handle nil:
<EvidenceCard.evidence_card
  evidence={@assigns_map[:evidence]}
  reveal_state={@assigns_map[:reveal_state]}
  can_reveal?={Map.get(@assigns_map, :can_reveal?, true)}
/>
```

### WR-02: Gallery specimens carry `phx-click` handlers with no `handle_event` receiver — clicking crashes the LiveView

**File:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex` (whole module — no `handle_event/3` defined)
**Issue:** `GalleryLive` defines only `mount/3` and `render/1`; it has no `handle_event/3`
clauses. Yet it renders live specimens whose source markup carries `phx-click`:
`device_frame` (`set_device`), `tabs` (`set_tab`), `deliveries_list` rows (`select_delivery`),
`support_cards` (`open_support_exemplar`), `replay_modal` (`close_replay` / `choose_replay_target`),
and `evidence_card` (`reveal_raw`). In LiveView a `phx-click` whose event has no matching
`handle_event/3` raises at runtime and tears down the LiveView process — the gallery is the
visual-audit surface a developer is expected to click around in. The `theme_toggle` and
`nav_link`/`nav_pill` specimens were correctly inlined with the `phx-click`/`navigate` removed
or pointed at `#`, showing the author was aware of the hazard, but the delegated full-component
specimens were not neutralized.
**Fix:** Add a catch-all no-op handler so dev clicks degrade to nothing instead of a crash:
```elixir
@impl true
def handle_event(_event, _params, socket), do: {:noreply, socket}
```
A catch-all is acceptable here precisely because the gallery is a static dev specimen surface
with no real state to mutate; alternatively render the interactive specimens with their
`phx-click` stripped (as was done for `theme_toggle`).

### WR-03: Spec-mandated token replacements not applied — `px-5` and arbitrary `tracking-[0.08em]` remain (conformance-gate violations)

**File:** `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:32,36,40,44,48,52,60,72`;
`mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex:54,58,62,66,70,74,82,91`;
`mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:95,103,136,140`;
`mailglass_admin/lib/mailglass_admin/operator/support_cards.ex:67,73,113,119`;
`mailglass_admin/lib/mailglass_admin/operator_live.ex:387,388,404`
**Issue:** The UI-SPEC Typography section states "Arbitrary `tracking-[…]` values are BANNED
(conformance gate violation)" and the Spacing section lists `px-5` (20px) at
`detail_header.ex:21` as a value Phase 97 "replaces with `px-md` or `px-lg` (STATE-LD-12)".
The `text-xl → text-heading` swap was applied (good), but the sibling `px-5` and
`tracking-[0.08em]` arbitrary values were left throughout the operator/inbound detail headers,
replay modal, support cards, and operator_live CTAs. `filters_form.ex` *was* correctly cleaned
(no `tracking-[…]`), which makes the omission elsewhere an inconsistency, not a deliberate
deferral. These will trip the conformance gate the spec describes.
**Fix:** Replace `tracking-[0.08em]` with the global heading/label tracking (drop the arbitrary
value entirely — `text-label font-bold uppercase text-secondary` per the filters_form precedent)
and replace `px-5` with `px-md`/`px-lg` on the affected buttons. Apply the same edit
`filters_form.ex` already received.

### WR-04: `shell.ex` sidebar/header use arbitrary `tracking-[0.12em]` and global flash uses `role="alert"`/`role="status"` split that diverges from the spec's single-container contract

**File:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:125` (`tracking-[0.12em]`),
`mailglass_admin/lib/mailglass_admin/operator/shell.ex:286-297` (flash regions)
**Issue:** Two items. (a) `shell.ex:125` carries `tracking-[0.12em]`, another arbitrary
`tracking-[…]` value the Typography conformance gate bans. (b) The Accessibility Contract
specifies `role="status"` + `aria-live="polite"` on the flash container (STATE-LD-03 /
components.ex), but `flash_region/1` here splits info into `role="status"` (no `aria-live`)
and error into `role="alert"`. `role="alert"` carries an implicit `aria-live="assertive"`,
which is defensible for errors, but neither region declares an explicit `aria-live`, and the
info `role="status"` without `aria-live="polite"` means screen readers that don't map
`role=status` to a live region won't announce the success flash. Since these flash banners are
rendered after `phx-mounted` motion, an explicit live-region attribute is the safe contract.
**Fix:** Drop `tracking-[0.12em]` (use the bare `uppercase` label treatment). Add explicit
`aria-live="polite"` to the info region and `aria-live="assertive"` to the error region (or
align with the shared `components.ex` flash that the spec marks already-compliant).

### WR-05: `operator_live.ex` overview/nav CTAs use `btn-sm` alongside `min-h-11` — the documented touch-target regression the spec calls out

**File:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:344,354`
**Issue:** The two overview "View Deliveries" / "View Inbound" links use
`class="btn btn-primary btn-sm min-h-11"`. The UI-SPEC (STATE-LD-08/14/20) and the e2e spec's
own FACT-2 note (`structural.spec.js:124-129`) document that `btn-sm` overrides `min-h-11`,
computing to ~21px — below the 44px non-negotiable touch-target floor. The structural test was
deliberately written to *pass with a GAP note* rather than fail, so CI will not catch this; the
violation is real on a primary navigation CTA at mobile width. Phase 97's per-component contract
explicitly removed `btn-sm` from `support_cards` and `device_frame`; the operator_live overview
CTAs retain it.
**Fix:** Drop `btn-sm` from both links (`class="btn btn-primary min-h-11"`), matching the
treatment applied to `support_cards.ex` buttons.

## Info

### IN-01: `support_cards` tier-2 separator can render a leading orphan "·" when both tier-1 cards are shown

**File:** `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex:165-178`
**Issue:** When `failed_ingest.count > 0` AND `orphan_backlog.count > 0`, neither the
"No failures" nor "No orphan backlog" span renders, so the conditional inter-span "·" (line 168)
is also suppressed — but the unconditional "·" at line 175 still renders immediately before
"Active suppressions", producing a leading dot with no preceding content. Cosmetic only.
**Fix:** Gate the line-175 separator on whether any preceding tier-2 span actually rendered, or
build the tier-2 row from a filtered list joined with "·" rather than hand-placed separators.

### IN-02: Gallery `grouped_specimens/1` uses `acc ++ [...]` and `List.keyreplace` in a reduce — O(n²) append

**File:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex:744-752`
**Issue:** The grouping reduce appends to the tail of the accumulator (`acc ++ [...]`) and
re-scans with `List.keyfind`/`List.keyreplace` per element. Correctness is fine and the
specimen list is tiny/static (performance is explicitly out of v1 review scope), but the idiom
is awkward for a list that could be expressed with `Enum.group_by/2` preserving order. Noted
for maintainability, not correctness.
**Fix:** `Enum.chunk_by`/`Enum.group_by` over the flat list, or build a keyword accumulator and
`Enum.reverse` once. Optional.

### IN-03: Gallery dispatch rebinds `assigns` via `Map.merge`/`Map.put` then reads `@var` — works but obscures the function-component contract

**File:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex:154-236`
**Issue:** The `nav_link`/`nav_pill`/`tenant_chip`/`theme_toggle` specimen clauses pull values
out of `assigns.assigns_map`, then `Map.merge`/`Map.put` them back onto `assigns` before the
`~H` block reads `@active`/`@label`/`@tenant`. This duplicates the real `Shell` markup inline
(because those are `defp` in `Shell`) and risks drift: the inlined nav_link classes at
`gallery_live.ex:166-172` must be kept byte-identical to `shell.ex:207-213` by hand. A future
edit to the real nav_link focus-ring will not propagate to the gallery copy, silently making the
gallery specimen lie. Consider promoting the shared nav primitives to public function components
so the gallery can call them directly.
**Fix:** Make `nav_link`/`nav_pill`/`tenant_chip`/`theme_toggle` public (`def`) in `Shell` and
call them from the gallery, eliminating the duplicated markup. Optional refactor.

### IN-04: Gallery has no `<nav>`/skip-link and uses raw spacing literals `space-y-3xl` — acceptable for a dev surface but inconsistent with operator chrome

**File:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex:75-115`
**Issue:** The gallery page chrome (`px-md py-xl`, `space-y-3xl`, `gap-lg`) uses design tokens
correctly, and as a dev-only audit surface it intentionally omits the operator shell, nav
landmark, and orientation strip (per CONTEXT D-01..D-04). No action required — recorded only to
confirm the omission is by-design, not an oversight.
**Fix:** None. Documented as intentional.

### IN-05: `tabs.ex` content panes use raw `h-[600px]` arbitrary height and `font-mono` rather than the `.mono` token class

**File:** `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:143,149,155` (`h-[600px]`),
`:143,149,159,166,169` (`font-mono`)
**Issue:** The Typography section names `.mono` (or `code`/`pre`) as the monospace mechanism; the
panes use raw `font-mono`. The panes also hardcode `h-[600px]` (and the iframe `height: 600px`
inline). These are pre-existing preview-tab utilities, not new to Phase 97's component contract,
and `pre`/`code` get IBM Plex Mono globally anyway. Low-priority token-discipline drift.
**Fix:** Prefer the `mono` class over `font-mono` for consistency; consider a height token if one
exists. Optional.

### IN-06: `evidence_card` `can_reveal?` attribute is declared and threaded but never read in the render body — dead attribute

**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:27` (and the gallery
threading at `gallery_live.ex:321`)
**Issue:** `attr :can_reveal?` is declared and the gallery passes it, but `evidence_card/1`
gates the reveal button purely on `@evidence && @reveal_state != :revealed` — `can_reveal?` is
never consulted. It is forward-compatible scaffolding (mirrors the inbound suppression-flag
pattern), but as written it is a dead input that gives a false sense the card enforces the
capability. This is also why WR-01's `|| true` bug is currently invisible.
**Fix:** Either wire `can_reveal?` into the reveal-button `:if` (`@can_reveal? && @evidence &&
@reveal_state != :revealed`) so the attribute does real work, or document it explicitly as
reserved scaffolding. Coordinate with WR-01's fix.

---

_Reviewed: 2026-06-14T16:52:20Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
