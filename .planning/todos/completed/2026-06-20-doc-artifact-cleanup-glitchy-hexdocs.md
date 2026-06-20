---
type: todo
status: completed
created: 2026-06-20
completed: 2026-06-20
priority: medium
area: docs
resolves_phase: null
tags: [docs, hexdocs, moduledoc, cleanup, gsd-artifact-leakage]
---

# Doc cleanup: glitchy HexDocs — empty parens, pipe-broken tables, leaked artifacts (DONE)

Maintainer flagged that the docs "look glitchy" with GSD plan/phase-name
artifacting, empty parens, and broken code formatting. Four defect classes,
all resolved 2026-06-20.

## Resolution

| # | Defect class | Resolution | Commit |
|---|---|---|---|
| 1 | Empty `()` residue in moduledocs (125 lines) | Removed (doc/comment-aware, space-gated) | `35a2d2ae` |
| 2 | `\|`-broken markdown tables (9 rows) | Escaped `\|` in code spans on table rows | `35a2d2ae` |
| 3 | Leaked `CATEGORY-NN` REQ-IDs (155 occ) | Stripped from rendered docstrings | `81a9c406` |
| 4 | "the design contract" / "this milestone phase" / `D-NN` / `Phase NN` filler (~90 occ) | Stripped + prose rewritten | `bd6f0638` |
| — | Regression guard | `NoPlanningArtifactComments` now bans bare `CATEGORY-NN` in docstrings (curated prefixes, excludes SHA-256/UTF-8) | `bd6f0638` |

## Key decisions

- **Rendered docs only.** REQ-IDs in source `#` comments kept as maintainer
  traceability (116 preserved); the new Credo pattern is docstring-scoped so
  comments don't turn CI red.
- **Pipe fix** only touched `guides/telemetry.md` + `guides/webhooks.md` — other
  guides use `|` as real delimiters between separate code spans (left alone).
- **Curated prefix allowlist** for the strip + the check, so real-world tokens
  (`SHA-256`, `UTF-8`, `OTP-27`) are never clobbered.
- Cascading prior-mangling cleaned: dangling commas, empty backticks, `/ .`,
  `in )`, `-06's`, the 22-item `STATE-LD` gallery list (→ clean bullet list).

## Verification

- Docstring artifact sweep across all 3 packages: **0 remaining**.
- `mix credo --strict`: **found no issues**.
- `NoPlanningArtifactComments` test: **6/6** (added: docstring REQ-ID flagged,
  comment REQ-ID allowed, `SHA-256`/`UTF-8` not flagged).
- Core + admin compile clean (`--warnings-as-errors`). Doc prose only — no code
  logic changed.

## Note for the next Hex release

These are repo-artifact fixes; HexDocs will pick them up on the next publish.
The `mailglass_inbound` standalone build currently fails a pre-existing
dependency-version mismatch (`~> 1.0` got `0.3.20`) unrelated to this work.

## Source

Flagged by maintainer 2026-06-20. Live examples:
https://mailglass.hexdocs.pm/Mailglass.RateLimiter.html#content (parens/IDs),
https://mailglass.hexdocs.pm/telemetry.html (pipe-broken telemetry table).
