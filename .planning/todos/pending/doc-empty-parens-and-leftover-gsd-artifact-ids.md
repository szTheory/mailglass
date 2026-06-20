---
type: todo
status: pending
created: 2026-06-20
updated: 2026-06-20
priority: medium
area: docs
resolves_phase: null
tags: [docs, hexdocs, moduledoc, cleanup, gsd-artifact-leakage]
---

# Doc cleanup: glitchy HexDocs — empty parens, pipe-broken tables, leaked REQ-IDs

Three reader-facing doc-hygiene defect classes, all traceable to prior GSD
artifact-reference strip passes that left residue in public docs.

## Status

| # | Defect class | Status | Where |
|---|---|---|---|
| 1 | Empty `()` residue in moduledocs | ✅ DONE (commit `35a2d2ae`) | 125 lines / 41 core modules |
| 2 | `\|`-broken markdown tables | ✅ DONE (commit `35a2d2ae`) | 9 rows: `guides/telemetry.md`, `guides/webhooks.md` |
| 3 | Leaked REQ-ID tokens (`CATEGORY-NN`) in docstrings/comments | ⏳ REMAINING | ~274 occurrences across ~40 modules |

## 1. Empty parens — DONE

Removing a trailing `(XXX-NN)` ref left a dangling `()` / `():` in prose
(e.g. RateLimiter "continuous refill ():"). Fixed with a doc/comment-aware,
space-gated sweep (`/tmp/fix_empty_parens.py`): only touches `@doc`/`@moduledoc`
heredocs and `#` comments, skips fenced code, and is space-gated so real
`foo()` / `Mix.shell().info()` calls are never matched. Leftover leading
punctuation (`( ): per-domain` → `per-domain`, `(). Full-span` → `Full-span`)
cleaned. 73 remaining `()` matches are all legitimate chained-call code.

## 2. Pipe-broken tables — DONE

Unescaped `|` inside inline-code WITHIN markdown table cells was parsed by
GFM/ExDoc as a column delimiter, so
`` `[:mailglass, :webhook, :ingest, :start | :stop | :exception]` `` rendered as
un-fonted text with pipes collapsed to spaces (the symptom the maintainer saw on
telemetry.html). Fixed by escaping `|` → `\|` *inside code spans on table rows
only* (`/tmp/fix_table_pipes.py`); cell-delimiter pipes untouched, idempotent.
Only `telemetry.md` (6) + `webhooks.md` (3) were affected — other guides use `|`
as real delimiters between separate code spans and were correctly left alone.

## 3. Leaked REQ-ID tokens — REMAINING (the big one)

**~274 `CATEGORY-NN` REQ-ID tokens** still embedded in `lib/` docstrings and
comments — `TRANS-01`, `RATE-01`, `LINT-12`, `IOPS-05`, `CORE-07`, `WR-02`,
`TRACK-03`, `DATA-03`, `IADM-04`, `HOOK-06`, `MIME-03`, etc. These are the "GSD
plan/phase name artifacting" the maintainer flagged. Split roughly: ~130 in `#`
comments (not rendered in HexDocs) + ~144 in rendered `@doc`/`@moduledoc`/config
`doc:` strings (the reader-facing noise).

### Why CI didn't catch them

`credo_checks/no_planning_artifact_comments.ex` already encodes the policy
("Planning-artifact tokens are not allowed in source comments/docstrings.
Rewrite with behavior-focused rationale") and scans BOTH comments and
docstrings — but its `banned_patterns` only match `REQ-…`, `D-NN`, `Phase N`,
`Plan N`, `GSD`, `[ASSUMED…]`. It does **not** match the bare `CATEGORY-NN`
form, which is the dominant leaked shape. **Fix should also extend this check**
so the class can't regress.

### Hazards (why this needs care, not a blind sed)

- **False positives:** `[A-Z]{2,5}-[0-9]+` also matches real tokens —
  `SHA-256`, `RFC-5321`, `OTP-27`, `P-256`. Must strip against a **curated
  allowlist of real project REQ-ID prefixes** only (derive from
  `.planning/REQUIREMENTS.md` + `PROJECT.md` "Validated Requirements" + archived
  milestone REQUIREMENTS — the set spans ALL milestones, not just current).
- **Embedded forms vary:** trailing `(TRANS-01).` (clean to strip) vs
  `(CORE-03, CORE-09)` lists vs inline `LINT-12 NoDirectDateTimeNow` (ID prefixes
  a real identifier — strip just the ID, keep the name) vs `per RATE-01`.
- **Pre-mangled spots** (prior strip already damaged the prose — fix by hand):
  - `lib/mailglass/tracking.ex:3` — `Off by default per TRACK-01 / .`
  - `lib/mailglass/config.ex:467` — `` `LINT-08` Credo check in ).``
  - `lib/mailglass/mailable.ex:31` — `(TRACK-01 /  project-level)` (double space)
  - `lib/mailglass/repo.ex:94` — `Added in   so ...` (stripped ref left a gap)
  - `lib/mailglass/template_engine.ex:13` — `See AUTHOR-05 in REQUIREMENTS.md.`
    (pure planning bleed-through — drop the sentence)

### Suggested approach for the follow-up pass

1. Build the curated REQ-ID prefix allowlist (all milestones).
2. Decide scope: rendered docstrings only, or comments too? The Credo check's
   intent says **both** — but `#` comments carry maintainer traceability the
   project may value; confirm with maintainer before stripping comments.
3. Precise stripper for clean patterns (` (PREFIX-NN)`, `(PREFIX-NN, …)`,
   `PREFIX-NN <Identifier>`, `per PREFIX-NN`) with whitespace/punct cleanup;
   dry-run + review full diff before applying.
4. Hand-fix the pre-mangled spots above.
5. Extend `no_planning_artifact_comments.ex` `banned_patterns` to cover the
   curated `PREFIX-NN` set; run `mix credo --strict` + the check's test.
6. Compile `--warnings-as-errors`; spot-check a rebuilt HexDocs page.
7. Fix across all three packages.

## Source

Flagged by maintainer 2026-06-20 (Phase 114 → again during v1.13 planning).
Classes 1 & 2 fixed same day (commit `35a2d2ae`). Live examples:
https://mailglass.hexdocs.pm/Mailglass.RateLimiter.html#content (parens),
https://mailglass.hexdocs.pm/telemetry.html (pipe-broken telemetry table).
