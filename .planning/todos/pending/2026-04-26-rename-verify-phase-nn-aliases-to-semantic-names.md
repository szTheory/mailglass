---
created: 2026-04-26T16:11:01.069Z
title: Rename `verify.phase_NN` aliases to semantic, self-documenting names
area: tooling
files:
  - mix.exs:43-46
  - mix.exs:143-186
  - README.md (Installation section references `mix verify.phase_07`)
  - https://hexdocs.pm/mailglass/readme.html#installation
priority: v0.1.1
---

## Problem

`mix.exs` defines four `verify.phase_NN`-style aliases:

- `verify.phase_02` (lines 43, 143)
- `verify.phase_03` (lines 44, 150)
- `verify.phase_04` (lines 45, 160)
- `verify.phase_07` (lines 46, 186)

The phase numbers are an internal GSD planning artifact — meaningful to maintainers, **meaningless to adopters**. The README's Installation section currently tells adopters to run `mix verify.phase_07`, which is opaque from the outside ("which phase? whose? why 07?").

Surfaced when reviewing the published HexDocs at https://hexdocs.pm/mailglass/readme.html#installation during the v0.1.0 publish ceremony.

## Solution

Rename each alias to describe **what it does**, not which GSD phase introduced it. Suggested mapping (verify against the actual alias bodies in `mix.exs`):

| Current | Likely intent | Suggested replacement |
|---------|---------------|----------------------|
| `verify.phase_02` | persistence + tenancy migration / repo verify | `verify.persistence` |
| `verify.phase_03` | outbound delivery / send pipeline | `verify.outbound` |
| `verify.phase_04` | webhook ingest / signature verify | `verify.webhooks` |
| `verify.phase_07` | installer + golden + admin smoke | `verify.installer` |

Implementation steps:

1. Read each alias body in `mix.exs:143–225` to confirm what it actually orchestrates.
2. Add the new semantic alias names (don't remove the old ones immediately — tag them deprecated).
3. Update README.md, MAINTAINING.md, and any HexDocs `extras` that reference the old names.
4. After one minor version, remove the deprecated `verify.phase_NN` aliases.

Track for v0.1.1 alongside the installer router-anchor fix and the Swoosh `:api_client` default config.
