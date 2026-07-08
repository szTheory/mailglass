# Backlog seed: admin relative-asset-URL styling robustness

> **Resolved in v2.1 Phase 139.** This seed was promoted on 2026-07-07 and
> closed by the Phase 139 admin asset first-load/deep-link proof (`AAU-01..04`,
> `GATE-03`). Approach A remains the selected strategy: root-relative asset URLs
> computed from the effective mount path via the existing
> `MountPathHook`/`MountPath`/layout `css_url` mechanism. Approaches B-D remain
> rejected as primary fixes because Phase 139 proved the narrower mechanism
> satisfies the route matrix.
>
> **Origin.** Surfaced during the `ui/design-system-polish` pass (2026-06-02)
> while visually auditing the operator + inbound surfaces. Pre-existing — the
> asset-URL strategy long predates this work — but the new shared operator shell
> makes `/inbound` a first-class, linkable destination, which raises the
> visibility of the failure mode. Documented in
> `mailglass_admin/docs/design-system.md` so adopters and future work both see
> the resolved behavior and the regression gate.

## Problem

`mailglass_admin` used to depend on relative stylesheet href resolution for its
CSS/fonts, which made styling sensitive to document URL depth and trailing slash
shape. v2.1 Phase 139 closed that gap by proving mount-rooted stylesheet hrefs
and CSS-relative font responses under the effective admin mount path.

The resolved behavior is now: hard refreshes and direct deep links stay styled
across preview, scenario, error, gallery, operator, inbound, query deep-link,
and alternate mount routes. The focused Phase 139 browser proof checks network
responses and token-backed computed styles so a styling regression fails the
gate instead of passing as a DOM-only structure assertion.

## Goal

Keep the admin dashboard styled at **every** verified canonical URL form (root,
nested, query, alternate mount, hard refresh, and direct deep link), without
giving up adopter mount-path portability.

## Candidate approaches

- [x] **A — Root-relative anchored asset URL.** Compute the asset path from the
  request/mount path at render time (the LiveViews already derive `base_path`
  in `handle_params`) and emit a non-trailing-slash-sensitive href. Risk: the
  dead-render layout helper (`MailglassAdmin.Layouts.css_url/0`) currently has no
  mount context. **Selected and proven in v2.1 Phase 139.**
- [ ] **B — Emit asset routes at the `/inbound` sub-scope too**, so relative
  resolution lands for the child route regardless. Smaller blast radius; only
  fixes the child-route axis, not the trailing-slash axis.
- [ ] **C — `<base href>` in the root layout** set to the mount root. Fixes all
  relative resolution at once; must be derived per-mount and must not break the
  relative font URLs or LiveView's own socket path.
- [ ] **D — Canonicalize the URL** (redirect `/ops/mail` → `/ops/mail/`). Cheap
  but only addresses the root axis and adds a redirect hop.

## Acceptance

- [x] **AAU-01** — Loading the operator dashboard at its canonical adopter URL
  (no trailing slash) renders fully styled on first paint.
- [x] **AAU-02** — Hard refresh on `/inbound` (and on a deep delivery/record
  URL) renders fully styled.
- [x] **AAU-03** — Works under an arbitrary adopter mount path (not just the demo
  app's `/ops/mail`), preserving the no-Node / committed-bundle / relative-font
  strategy.
- [x] **AAU-04** — A browser-evidence assertion (agent-browser or Playwright)
  proves styling loaded (e.g. a computed-style check), so the gate catches
  regressions that bounding-box assertions miss.
- [x] **AAU-05** — Asset-URL behavior documented in
  `mailglass_admin/docs/design-system.md` is updated once the fix lands.

## Notes

- The relative-URL rationale is real (mount-path portability + the committed,
  fingerprinted single bundle). Any fix must keep that property — this is a
  refinement of the serving strategy, not a rip-out.
- The frozen router contract (`mailglass_admin_routes/2`,
  `mailglass_operator_routes/2`) should not need new adopter-facing options; the
  fix should live behind the existing macros / internal layout + asset routes.
- Phase 139/GATE-03 evidence: first-HTML href assertions passed for the route
  matrix, and the serialized `admin asset hard load` Playwright proof passed
  CSS/font network and computed-style checks across default and alternate mount
  roots.
