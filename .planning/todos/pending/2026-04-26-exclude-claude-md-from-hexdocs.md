---
created: 2026-04-26T16:45:00.000Z
title: Exclude CLAUDE.md from published HexDocs
area: docs
files:
  - mix.exs:247-263 (extras list)
  - mix.exs:264-283 (groups_for_extras)
  - https://hexdocs.pm/mailglass/claude.html (current leak)
priority: v0.1.2
---

## Problem

`CLAUDE.md` is being published as a top-level page in HexDocs at
https://hexdocs.pm/mailglass/claude.html — visible to every adopter browsing
the package docs. It currently sits under the "Overview" group right next to
README.md.

`CLAUDE.md` is **internal contributor / AI-assistant guidance**:

- Points at `.planning/` artifacts that don't ship with the Hex tarball
- Exposes GSD workflow conventions, brand notes, "things not to do" rules
  framed for maintainers, not adopters
- References file paths and decisions (`D-01..D-20`, `LINT-01..LINT-12`)
  that are meaningless without the planning directory

It belongs in the GitHub repo, not the public package documentation. Adopters
should land on README.md and the `guides/` extras — that's the curated
adopter-facing surface.

Surfaced by user during v0.1.1 cycle (2026-04-26) when reviewing live
HexDocs after the v0.1.0 publish.

## Root cause

Two locations in the **root** `mix.exs` (the `mailglass` package config):

```elixir
# mix.exs:247-263
extras: [
  "README.md",
  "guides/getting-started.md",
  ...
  "CODE_OF_CONDUCT.md",
  "CLAUDE.md"        # ← remove
],
groups_for_extras: [
  Overview: ["README.md", "CLAUDE.md"],   # ← remove "CLAUDE.md"
  ...
]
```

`mailglass_admin/mix.exs` does **not** include CLAUDE.md in extras, so only
the core package needs the fix.

## Solution

Two-line edit in `mix.exs`:

1. Drop `"CLAUDE.md"` from the `extras:` list (mix.exs:262).
2. Reduce the Overview group to just `["README.md"]` (mix.exs:265), or drop
   the group entirely if README.md is fine standing alone.

No other references to CLAUDE.md elsewhere in mix.exs need changing.

## Verification

After publish:

- `curl -fsI https://hexdocs.pm/mailglass/<new-version>/claude.html` → 404
- HexDocs sidebar at https://hexdocs.pm/mailglass/<new-version>/ no longer
  shows a "CLAUDE" entry under any group
- README.md still renders correctly under Overview

## Why v0.1.2 (not v0.1.1)

v0.1.1 is a hotfix scoped to two adopter-blocking bugs (installer router
anchor + Swoosh api_client default). The CLAUDE.md leak is cosmetic — it's
embarrassing but doesn't break adopter installs. Bundle this with the
verify.phase_NN rename (other documentation polish) into v0.1.2 so v0.1.1
ships fast and clean.

## Belt-and-suspenders option

To prevent regression, also consider adding to `package` definition in
`mix.exs`:

```elixir
files: ~w(lib priv mix.exs README.md LICENSE.md ...) -- ["CLAUDE.md"]
```

…to defensively exclude `CLAUDE.md` from the Hex tarball itself, even if it
gets re-added to extras by mistake. Cheap insurance.
