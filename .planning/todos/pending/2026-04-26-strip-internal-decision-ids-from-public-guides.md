---
created: 2026-04-26T19:30:00.000Z
title: Strip internal decision IDs (D-NN) from public guides
area: docs
files:
  - guides/webhooks.md (confirmed leak)
  - guides/multi-tenancy.md (likely)
  - guides/telemetry.md (likely)
  - guides/*.md (sweep all)
  - https://hexdocs.pm/mailglass/webhooks.html (current leak)
priority: v0.1.2 (or v0.2)
resolves_phase: 8
resolves_req: REL-02
---

## Problem

Public adopter-facing guides published to HexDocs contain references to
internal GSD planning artifacts that are noise to adopters and make the docs
look weird and hard to read.

Concrete example from https://hexdocs.pm/mailglass/webhooks.html:

> ## 2. Multi-tenant patterns (D-12)
>
> Mailglass resolves the tenant AFTER the signature verifies (D-13
> "verify-first, tenant-second"). Three resolver shapes ship: …

The `D-12` / `D-13` parenthetical references are GSD planning artifacts
(decision IDs from `.planning/PROJECT.md` Key Decisions table). They are
load-bearing for maintainers — every D-NN encodes a locked rationale —
but they are confusing and distracting to adopters who:

- Have no `.planning/` directory to look up `D-NN` in
- Don't know GSD or the milestone-close ritual
- See them as cryptic in-jokes that erode trust in the documentation

The same likely applies to `LINT-NN`, `REQ-NN` (CORE/AUTHOR/PERSIST/...),
`TS-NN`, `DF-NN`, `IB-NN`, `AF-NN`, and possibly phase numbers (`Plan 04-06`,
`Phase 07.1`) anywhere they leak into adopter-facing prose.

## What "weird and hard to read" actually means

Adopters expect docs that explain what the library does and why a particular
pattern is recommended. They don't expect engineering-process metadata.
`D-13 "verify-first, tenant-second"` would read fine as just `verify-first,
tenant-second` — the quoted phrase already conveys the rule; the `D-13`
prefix is pure noise from the adopter's perspective.

## Recommended fix

1. Sweep `guides/*.md` for the patterns:
   - `D-\d+`
   - `LINT-\d+`
   - `REQ-[A-Z]+-\d+` (CORE/AUTHOR/PERSIST/TENANT/TRANS/SEND/TRACK/HOOK/COMP/PREV/TEST/INST/CI/DOCS/BRAND)
   - `TS-\d+`, `DF-\d+`, `DV-\d+`, `IB-\d+`, `AF-\d+`
   - Phase / Plan references like `Phase 04-06`, `Plan 02-05`, `Phase 07.1`
2. For each match, decide:
   - **Drop the parenthetical** when the adjacent prose already conveys the
     decision (most common; the `(D-13)` example above)
   - **Rephrase** to keep the rationale without the ID (e.g. "for the same
     reason mailglass forbids tracking on auth-carrying messages — privacy
     compliance" instead of "(D-08)")
   - **Move to maintainer-only doc** if the audience is wrong for that section
3. Add a Credo or doctest-style guard so future doc PRs flag re-introductions:
   - Quick win: a script in `mix mailglass.publish.check` that greps the
     `extras` files for the patterns and warns
   - Stronger: a custom Credo check `Mailglass.Credo.NoInternalDecisionIdInGuides`
     that runs only over files referenced from `mix.exs:extras`

## Why this is v0.1.2 (or v0.2), not v0.1.1

This shipped in both v0.1.0 and v0.1.1 HexDocs. Cosmetic but visible. Bundle
with the existing v0.1.2 doc-hygiene fixes:

- `2026-04-26-exclude-claude-md-from-hexdocs.md` (CLAUDE.md leak)

The same sweep can address both — the underlying smell is "internal
maintainer artifacts leaking into adopter-facing docs."

## Acceptance criteria

- [ ] No `D-\d+` references in any file under `guides/`
- [ ] No `LINT-\d+`, `REQ-XXX-\d+`, `TS-\d+`, `DF-\d+` references in `guides/`
- [ ] No `Phase NN` / `Plan NN-MM` references in `guides/` (unless explaining
      project history in a clearly-labeled section)
- [ ] Spot-check rendered HexDocs for `webhooks`, `multi-tenancy`, `telemetry`
      — adopter-facing prose only
- [ ] Optional: lint guard prevents regression
