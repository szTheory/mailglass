# Thread: Project Convergence Posture

**Opened:** 2026-05-31  
**Status:** open  
**Priority:** high  
**Owner:** maintainer

## Question

How should future milestone planning remember that Mailglass is approaching
product-complete, so new sessions do not reopen the same "are we done yet?"
conversation by default?

## Current Read

- `mailglass` core is effectively product-complete for the original
  transactional email framework thesis.
- `mailglass_admin` is past minimum credible and now mostly in trust,
  maintenance, and precision-polish territory.
- `mailglass_inbound` is feature-credible, but still needs a dedicated
  stability-lock milestone before carrying the same long-lived compatibility
  posture as core/admin.
- v1.3 closed the major adoption-confidence gap by proving a maintained
  Phoenix reference host and deterministic trust evidence.

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

## Release Implication

The next recommended milestone remains `v1.4 Inbound Stability Lock`.

After that milestone:

- promote `mailglass_inbound` to `1.0.0` if the contract lock is real, or
- cut one final explicit `0.x` confidence release with "next is 1.0" framing if
  the contract still needs soak.

Do not open additional feature-growth work before making that release-position
decision.

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
