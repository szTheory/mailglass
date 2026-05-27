# Thread: Next Milestone - Adopter Trust Proof

**Opened:** 2026-05-27  
**Status:** open  
**Priority:** high  
**Owner:** maintainer

## Question

What is the thinnest maintained reference host app that proves mailglass
adopter trust end to end without becoming a second product?

## Current Recommendation

- Select this as the next milestone wedge.
- Keep the host app focused on one representative install -> preview -> send ->
  webhook -> operator path.
- Add a CI lane to keep the artifact honest over time.

## Scope Guardrails

- No broad provider matrix in this milestone.
- No transport-class expansion (`gen_smtp` listener).
- No ecosystem grab-bag integrations.

## Exit Signal

This thread closes when a milestone is opened with explicit done-enough criteria
for the reference host app and those criteria are mapped to phase requirements.
