---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 08
subsystem: inbound-mime
tags: [docs, mime, optional-deps, honesty, gap-closure]
requires:
  - mailglass_inbound/lib/mailglass_inbound/mime.ex (existing representation-depth guard seam)
  - lib/mailglass/optional_deps/gen_smtp.ex (existing never-raise decode/2 gateway)
provides:
  - Honest mime.ex moduledoc + contract bullet (representation-depth guard, not boundary-bomb defense)
  - Phase 46 deferral note for provider-fed deep-nesting DoS hardening
  - Corrected gen_smtp.ex moduledoc attributing the :undef backstop to rescue
affects:
  - mailglass_inbound documentation (ExDoc)
  - mailglass core optional-deps documentation (ExDoc)
tech-stack:
  added: []
  patterns:
    - "Recurrence-guardrail convention: a 'protects against X' moduledoc claim must point at a test named for X, or be downgraded to 'bounds Y' + a Phase-N deferral note"
    - "ExDoc `> #### Note {: .info}` admonition for scope-of-protection caveats"
key-files:
  created: []
  modified:
    - mailglass_inbound/lib/mailglass_inbound/mime.ex
    - mailglass_inbound/test/mailglass_inbound/mime_test.exs
    - lib/mailglass/optional_deps/gen_smtp.ex
decisions:
  - "Keep the :max_depth guard (deterministic ceiling on the iterated representation; the seam Phase 46's real decoder limit plugs into) and correct the docs rather than removing the guard"
  - "Real provider-fed deep-nesting (boundary-bomb) DoS hardening stays deferred to Phase 46 — not pulled into scope"
metrics:
  duration: ~6 min
  completed: 2026-05-23
  tasks: 2
  files: 3
---

# Phase 45 Plan 08: DOC Honesty — Moduledoc Claim Corrections Summary

Corrected two moduledocs (and one test describe) that asserted protections the code does not deliver: relabeled the mime.ex `:max_depth` guard as a representation-walk ceiling (not a boundary-bomb decoder limit) with a Phase 46 deferral note, and reattributed the gen_smtp.ex `:undef` backstop to `rescue` (not `catch :exit`). Doc/test-only — no behavior change, never-raise (MIME-04) preserved.

## What Was Built

**Task 1 — mime.ex docs honesty + test describe rename (commit `75a7658`):**
- Added an ExDoc `> #### Note {: .info}` admonition to the `MailglassInbound.MIME` moduledoc stating precisely what `:max_depth` does (bounds the depth of the internal representation walk — `collect_leaves/3` over the already-decoded tree — giving a deterministic structured ceiling) and does NOT do (does not limit the underlying `:mimemail` decoder recursion, which fully parses to any depth before the guard runs; therefore does not by itself defend against provider-fed deep-nesting / boundary-bomb DoS). The note records that real decoder-level DoS hardening is a Phase 46 concern that plugs into this same seam.
- Fixed the contract bullet: `or the deep-nesting guard tripped` → `or the representation exceeded :max_depth` so the `:inbound_mime_invalid` cause list is accurate.
- Fixed the `:max_depth` option doc: `before the boundary-bomb guard trips` → `before the representation-depth guard trips`, with a pointer to the moduledoc note (default note kept).
- Renamed the `mime_test.exs` describe from `"parse/2 — boundary-bomb / deep-nesting guard (T-45-12, V5)"` to `"parse/2 — representation max_depth guard (MIME-04)"`. Test bodies (the deeply-nested-multipart never-raise / MIME-04 assertions and the within-max_depth parse assertion) are unchanged — the diff is exactly one line.

**Task 2 — gen_smtp.ex `:undef` attribution fix (commit `0d500f6`):**
- Reworded the "MIME parse seam — never raises" three-mechanism list so each escape is attributed to the clause that actually absorbs it:
  - `rescue` now covers raised `erlang:error` reasons **and** the `:undef` backstop (when `decode/2` is reached without the `available?/0` gate and `:mimemail` is absent, the call raises a class-`:error` `UndefinedFunctionError` → caught by `rescue`; the normal degraded path returns `:gen_smtp_unavailable` upstream before `decode/2` is ever called).
  - `catch :exit` now references only the `iconv:convert/3` EXIT signal (defensive, since the mandatory `{:encoding, :none}` opt skips iconv).
- Retained the closing "all three are load-bearing for the never-raise contract (MIME-04)" note.
- `decode/2` (the `rescue` + `catch :throw` + `catch :exit` clauses) is unchanged — moduledoc prose only.

## Verification

- **Source proof (run locally):**
  - mime.ex contains `> #### Note {: .info}`; no `deep-nesting guard tripped` and no `boundary-bomb guard` remain (the word "boundary-bomb" survives only inside the new Note, where it correctly describes what the guard does NOT defend against); contract bullet reads "or the representation exceeded `:max_depth`".
  - mime_test.exs describe no longer contains "boundary-bomb"; it references `max_depth` / `MIME-04`. `git diff` on the test file is a single line (describe rename only) — bodies unchanged.
  - mime.ex code unchanged: `decode_and_build/2`, `collect_leaves/3`, and the `@depth_exceeded` sentinel are all intact; the `git diff` shows no code-line changes (doc-only).
  - gen_smtp.ex `:undef`/`UndefinedFunctionError` is described under `rescue`; the `catch :exit` bullet references only the iconv exit; `decode/2` code unchanged (moduledoc-only diff).
- **CI-deferred (per plan `<verify>` — inbound deps unfetched in this worktree, toolchain caveat):**
  - `cd mailglass_inbound && mix test mailglass_inbound/test/mailglass_inbound/mime_test.exs` — the renamed describe's tests still pass (bodies unchanged).
  - `mix docs --warnings-as-errors` (inbound + core) — the `{: .info}` admonition renders without warnings.
  - `mix test` (core) — existing gen_smtp tests pass (no behavior change).

## Deviations from Plan

None — plan executed exactly as written. Doc/test-only, no behavior change, no public-API change. The underlying boundary-bomb DoS hardening stays deferred to Phase 46 as instructed (not pulled into scope). Rules 1-4 did not trigger.

## Known Stubs

None. No new code, no placeholders, no unwired data sources. The deferred Phase 46 work is documented as an explicit deferral note in the mime.ex moduledoc (intentional, scoped to a future phase), not a silent stub.

## Self-Check: PASSED

- mailglass_inbound/lib/mailglass_inbound/mime.ex — FOUND (modified, doc-only)
- mailglass_inbound/test/mailglass_inbound/mime_test.exs — FOUND (modified, describe-only)
- lib/mailglass/optional_deps/gen_smtp.ex — FOUND (modified, moduledoc-only)
- Commit 75a7658 (Task 1) — present on branch
- Commit 0d500f6 (Task 2) — present on branch
