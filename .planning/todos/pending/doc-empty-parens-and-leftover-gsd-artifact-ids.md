---
type: todo
status: pending
created: 2026-06-20
priority: medium
area: docs
resolves_phase: null
tags: [docs, hexdocs, moduledoc, cleanup, gsd-artifact-leakage]
---

# Doc cleanup: empty `()` parens + leftover GSD artifact IDs in moduledocs

## What

Two related doc-hygiene defects, both traceable to a prior GSD artifact-reference cleanup
pass that stripped internal IDs out of public docs:

1. **Empty parens left behind.** Removing a trailing artifact ref (e.g. `(RATE-01)`)
   left a dangling empty `()` in the prose. Example on the live HexDocs:
   > "Leaky-bucket continuous refill ():"
   — https://mailglass.hexdocs.pm/Mailglass.RateLimiter.html#content
   The user reports this pattern appears in **many** places across the docs, not just
   `RateLimiter` — so this needs a repo-wide sweep, not a one-off fix.

2. **Internal GSD artifact IDs still leaking into reader-facing docs.** The same page
   still shows internal requirement IDs like `(RATE-01)` in the moduledoc. These are
   GSD planning artifacts (REQ-IDs) with zero value to a library reader — they should
   have been removed by the cleanup too. Need to audit moduledocs / `@doc` strings for
   leaked `(XXX-NN)`-style artifact references and strip them.

## Why it matters

Public HexDocs are the adopter's first impression. Dangling `()` reads as a rendering
bug; leaked internal IDs read as planning-doc bleed-through. Both undercut the
"thoughtful maintainer" brand voice (CLAUDE.md → Brand & Voice).

## Suggested approach (for the follow-up phase/quick task)

- Repo-wide grep for empty/near-empty parens in doc strings:
  `grep -rn '([[:space:]]*)' lib/ */lib/` (tune to avoid false positives like `fn ()`),
  and specifically `(): `, ` ()`, `( )`.
- Repo-wide grep for leaked artifact IDs in `@moduledoc`/`@doc`:
  e.g. `grep -rnE '\([A-Z]{2,}-[0-9]+\)' lib/ */lib/` then filter to doc contexts.
- Fix across all three packages (`mailglass`, `mailglass_admin`, `mailglass_inbound`).
- Rebuild/spot-check HexDocs preview to confirm the `RateLimiter` page is clean.

## Source

Flagged by maintainer 2026-06-20 during Phase 114 execution; explicitly deferred so as
not to distract from the active milestone. Live example:
https://mailglass.hexdocs.pm/Mailglass.RateLimiter.html#content
