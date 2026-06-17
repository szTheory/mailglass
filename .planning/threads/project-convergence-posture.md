# Thread: Project Convergence Posture

**Opened:** 2026-05-31
**Status:** open (durable convergence record)
**Priority:** high
**Owner:** maintainer
**Last updated:** 2026-06-17 (post-v1.12; see "Current Read" + "Release Implication")

## Question

How should future milestone planning remember that Mailglass is approaching
product-complete, so new sessions do not reopen the same "are we done yet?"
conversation by default?

## Current Read (refreshed 2026-06-17, post-v1.12)

- **The last weak axis is now closed.** v1.12 shipped the onboarding/day-2 wedge (installer
  fail-closed + `mix mailglass.doctor`, fixed README, learning arc, go-live + troubleshooting
  guides, inbound replay-modal a11y) **and cut the first real Hex release since 1.6.2** —
  1.7.0 / 1.7.0 / 1.4.0 live, inbound re-pinned `== 1.7.0`. The "prepare-only backlog" is drained.
- A 2026-06-17 repo-local source sweep (3 packages) confirms **no foundational or important-but-narrow
  gap remains**: outbound core, 5 outbound + 4 inbound providers with signature verification, 4 admin
  LiveViews, both `mix mailglass.doctor` (wiring) and `mix mail.doctor` (deliverability), ~248 test
  files, Fake adapter gate, ~24 guides, two runnable reference apps. Done-% ≈ **93–95% (near-done /
  diminishing returns)**.
- **There is no recommended next feature milestone.** The honest next move is explicit quiet
  maintenance. Only concrete open items are maintenance-tier (see `release-pipeline-maintenance.md`):
  `gate-ci-green` advisory-classifier gap for "Demo Browser Evidence", and the deferred reference
  baseline pin bump (`~> 1.4` → `~> 1.7`). Neither needs a milestone — a `/gsd-quick` or todo suffices.
- Pre-v1.12 read (kept for history):

### Prior read (refreshed 2026-06-16, post-v1.11)

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

## Release Implication (RESOLVED 2026-06-17)

Both prior release implications are now CLOSED. `mailglass_inbound` `1.0.0` shipped (v1.6); and the
v1.7–v1.11 prepare-only backlog was **published by v1.12** — live truth is now
`1.7.0 / 1.7.0 / 1.4.0`, inbound re-pinned `{:mailglass, "== 1.7.0"}` (D-13). No prepare-only debt
remains. Future milestones should follow the "actually cut at close" rule (D-28) rather than
re-accumulating staged releases.

The onboarding/day-2 conversion wedge (the only sanctioned next milestone as of 2026-06-16) is
**done**. Do not open additional feature-growth work without explicit adopter pull + scoped non-goals.

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
