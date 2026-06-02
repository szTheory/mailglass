# Backlog seed: admin relative-asset-URL styling robustness

> **Origin.** Surfaced during the `ui/design-system-polish` pass (2026-06-02)
> while visually auditing the operator + inbound surfaces. Pre-existing — the
> asset-URL strategy long predates this work — but the new shared operator shell
> makes `/inbound` a first-class, linkable destination, which raises the
> visibility of the failure mode. Documented in
> `mailglass_admin/docs/design-system.md` ("Known limitations") so adopters and
> future work both see it.

## Problem

`mailglass_admin` serves its CSS/fonts via **relative** URLs (e.g.
`<link href="css-<md5>">`) so the bundle resolves under any adopter-chosen mount
path without the library knowing that path. The consequence is that a page is
only styled when the relative `css-<md5>` happens to resolve to the operator
mount root where the asset route is emitted (`<mount>/css-:md5`). Whether it
does depends on the **document URL's trailing slash + depth**:

- `/ops/mail/` (trailing slash) → resolves to `/ops/mail/css-…` ✓ styled
- `/ops/mail` (no slash) → resolves to `/ops/css-…` ✗ unstyled
- `/ops/mail/inbound` (no slash) → resolves to `/ops/mail/css-…` ✓ styled
- `/ops/mail/inbound/` (trailing slash) → `/ops/mail/inbound/css-…` ✗ unstyled

In normal use this is invisible: operators enter at the mount root and navigate
in-app (LiveView live navigation keeps the stylesheet loaded across screens). It
bites on a **hard refresh / deep link / bookmark** of the "wrong" URL form,
which renders **unstyled**. The admin Playwright gate doesn't catch it because it
asserts structure/order/`data-testid`/text, not pixels.

## Goal

Make the admin dashboard render styled at **every** canonical URL form (with or
without trailing slash, root or `/inbound`, on refresh and deep link), without
giving up adopter mount-path portability.

## Candidate approaches (evaluate, don't pre-commit)

- [ ] **A — Root-relative anchored asset URL.** Compute the asset path from the
  request/mount path at render time (the LiveViews already derive `base_path`
  in `handle_params`) and emit a non-trailing-slash-sensitive href. Risk: the
  dead-render layout helper (`MailglassAdmin.Layouts.css_url/0`) currently has no
  mount context.
- [ ] **B — Emit asset routes at the `/inbound` sub-scope too**, so relative
  resolution lands for the child route regardless. Smaller blast radius; only
  fixes the child-route axis, not the trailing-slash axis.
- [ ] **C — `<base href>` in the root layout** set to the mount root. Fixes all
  relative resolution at once; must be derived per-mount and must not break the
  relative font URLs or LiveView's own socket path.
- [ ] **D — Canonicalize the URL** (redirect `/ops/mail` → `/ops/mail/`). Cheap
  but only addresses the root axis and adds a redirect hop.

## Acceptance

- [ ] **AAU-01** — Loading the operator dashboard at its canonical adopter URL
  (no trailing slash) renders fully styled on first paint.
- [ ] **AAU-02** — Hard refresh on `/inbound` (and on a deep delivery/record
  URL) renders fully styled.
- [ ] **AAU-03** — Works under an arbitrary adopter mount path (not just the demo
  app's `/ops/mail`), preserving the no-Node / committed-bundle / relative-font
  strategy.
- [ ] **AAU-04** — A browser-evidence assertion (agent-browser or Playwright)
  proves styling loaded (e.g. a computed-style check), so the gate catches
  regressions that bounding-box assertions miss.
- [ ] **AAU-05** — Asset-URL behavior documented in
  `mailglass_admin/docs/design-system.md` is updated once the fix lands.

## Notes

- The relative-URL rationale is real (mount-path portability + the committed,
  fingerprinted single bundle). Any fix must keep that property — this is a
  refinement of the serving strategy, not a rip-out.
- The frozen router contract (`mailglass_admin_routes/2`,
  `mailglass_operator_routes/2`) should not need new adopter-facing options; the
  fix should live behind the existing macros / internal layout + asset routes.
