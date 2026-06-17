# Thread: Project Convergence Posture

**Opened:** 2026-05-31
**Status:** open (durable convergence record)
**Priority:** high
**Owner:** maintainer
**Last updated:** 2026-06-16 (post-v1.11; see "Current Read" + "Release Implication")

## Question

How should future milestone planning remember that Mailglass is approaching
product-complete, so new sessions do not reopen the same "are we done yet?"
conversation by default?

## Current Read (refreshed 2026-06-16, post-v1.11)

- `mailglass` core is effectively product-complete for the original
  transactional email framework thesis. **(unchanged)**
- `mailglass_admin` is fully on the canonical fable brand as of v1.11 and is in
  precision-polish territory only.
- `mailglass_inbound` **completed its stability lock** (v1.4) and shipped `1.0.0`
  (v1.6); now at `1.3.1`, carrying the same long-lived compatibility posture as
  core/admin. The "needs a dedicated stability-lock milestone" condition is DONE.
- v1.3 closed the major adoption-confidence gap (maintained Phoenix reference host
  + deterministic trust evidence); v1.5 added the richer demo app.
- **Remaining weak axis (only one):** adopter onboarding / day-2 DX — broken README
  quickstart, a silent webhook-`Plug.Parsers` 401 footgun, no "week 1" guide arc,
  no go-live checklist, scattered error docs. Tracked in
  `adopter-onboarding-day2-confidence.md` as the recommended next wedge. This is
  conversion/friction work, NOT feature growth — consistent with the posture below.

## Posture

After inbound stability lock, default to "silence on the wire":

- maintenance and release hygiene,
- docs truth and stability-contract upkeep,
- small adopter-pull fixes,
- narrow strategic work only when the user explicitly chooses it.

Do not default to another broad feature-growth milestone. Super-duper polish,
provider breadth, transport expansion, synthetic dev UI, and ecosystem
integrations are allowed later, but only as explicit strategic choices with a
clear adopter problem and scoped non-goals.

## Release Implication (refreshed 2026-06-16)

The original release-position decision is RESOLVED: `mailglass_inbound` `1.0.0` shipped (v1.6);
core/admin/inbound now at `1.6.2 / 1.6.2 / 1.3.1`.

**New live release implication:** v1.7 through v1.11 (admin polish + brand + design-system uplift)
were all cut **prepare-only** — that quality work is NOT yet on Hex. The next milestone (or its
close) should **cut the staged linked-version release** (admin-minor drags matched core+inbound)
and perform the PENDING inbound exact-pin re-pin (D-13) when the Release Please PR merges. Do not
keep accumulating prepare-only milestones — publish so adopters actually get the polish.

Do not open additional feature-growth work; the only sanctioned next milestone is the
onboarding/day-2 conversion wedge (which is friction-removal + the release cut, not capability).

## Promotion Rules

- Treat core/admin feature expansion as exceptional.
- Treat inbound broadening as exceptional after stability lock.
- Require clear adopter pull for new providers, transports, ecosystem
  integrations, or synthetic tooling.
- Prefer recipes/docs over first-party implementation when the integration is
  narrow, provider-specific, or high-maintenance.
- Preserve one-person maintainer sustainability over completeness theater.

## Exit Signal

This thread can close after inbound stability lock ships and the project has
either:

- promoted `mailglass_inbound` to a stable `1.0.0` release line, or
- made an explicit maintenance-mode decision with a documented remaining
  strategic backlog.
