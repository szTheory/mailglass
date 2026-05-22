---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 03
subsystem: api
tags: [gen_smtp, mimemail, mime, rfc5322, optional-deps, error-contract, jason, credo, mailglass_inbound]

# Dependency graph
requires:
  - phase: 45-01
    provides: gen_smtp 1.3.0 as inbound optional dep, NoBareOptionalDepReference covering inbound, api_stability MIMEError inventory entry, cross-package Credo coverage
provides:
  - Mailglass.OptionalDeps.GenSmtp.decode/2 — never-raising RFC 5322 parse seam over :mimemail.decode/2 (core 1.2.0)
  - MailglassInbound.MIMEError — package-local defexception with closed :type set, :cause excluded from JSON
  - MailglassInbound.MIME.parse/1,2 — standalone never-raising MIME parser returning {:ok, %{headers, parts, attachments, inline}} or MIMEError
  - boundary-bomb / deep-nesting max-depth guard (T-45-12) on the internal repr build
affects: [46, "Mailgun/SES raw-MIME ingress (first consumer of MIME.parse/1)"]

# Tech tracking
tech-stack:
  added: ["uses :mimemail (gen_smtp 1.3.0) via the GenSmtp gateway — no new deps; gen_smtp already pinned in 45-01"]
  patterns:
    - "Optional-dep parse seam: a never-raising decode/2 in the gateway wrapping try/rescue + catch :throw + catch :exit, returning {:ok, _} | {:error, {kind, reason}}"
    - "Gateway call sites alias with a distinct root segment (as: OptionalGenSmtp) so NoBareOptionalDepReference treats the call as sanctioned (mirrors OptionalOban in Execution)"
    - "Recursion depth guard via a local throw sentinel caught inside the public function — keeps the never-raise contract while bounding boundary-bomb DoS"

key-files:
  created:
    - lib/mailglass/optional_deps/gen_smtp.ex (extended with decode/2)
    - test/mailglass/optional_deps/gen_smtp_test.exs
    - mailglass_inbound/lib/mailglass_inbound/mime_error.ex
    - mailglass_inbound/test/mailglass_inbound/mime_error_test.exs
    - mailglass_inbound/lib/mailglass_inbound/mime.ex
    - mailglass_inbound/test/mailglass_inbound/mime_test.exs
  modified:
    - CHANGELOG.md
    - mailglass_inbound/CHANGELOG.md

key-decisions:
  - "Used `alias Mailglass.OptionalDeps.GenSmtp, as: OptionalGenSmtp` instead of the RESEARCH skeleton's plain `GenSmtp` alias — the NoBareOptionalDepReference check (widened to inbound by 45-01) keys on the call-site root segment, so a plain `GenSmtp.decode` alias trips it. The OptionalGenSmtp idiom matches the existing OptionalOban call site in MailglassInbound.Execution."
  - "Internal repr shape (D-45-14 discretion): %{headers, parts, attachments, inline} where parts/attachments/inline are flattened leaf maps %{type, subtype, headers, params, body[, filename]}. Inline = explicit `inline` disposition WITH a filename (Content-ID images); inline text without a filename stays in :parts."
  - "Max-depth guard implemented as a thrown sentinel atom caught inside parse/2 — avoids threading {:error, _} through Enum.flat_map recursion while keeping the never-raise contract intact. Default depth 100; configurable via :max_depth opt."
  - "Added an Unreleased section to both CHANGELOGs (Keep a Changelog format) — the repo uses Release Please managed sections with no standing Unreleased block, so I prepended one after the intro prose."

patterns-established:
  - "Never-raising optional-dep parse seam: the gateway owns try/rescue + catch :throw + catch :exit; the consumer translates the tagged tuple into the public error struct"
  - "Gateway alias-root idiom: `as: Optional<Dep>` so the bare-reference Credo check recognizes the sanctioned call"

requirements-completed: [MIME-01, MIME-02, MIME-04]

# Metrics
duration: 13min
completed: 2026-05-22
---

# Phase 45 Plan 03: Standalone Never-Raising MIME Parser Summary

**`MailglassInbound.MIME.parse/1` turns raw RFC 5322 into a stable `%{headers, parts, attachments, inline}` repr via a never-raising `GenSmtp.decode/2` gateway seam that absorbs all three `:mimemail` escape mechanisms (erlang:error / throw / :exit), with a package-local `MIMEError` (closed type set, `:cause` excluded from JSON) and a boundary-bomb depth guard — the standalone producer for Phase 46 raw-MIME ingress.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-05-22T22:41:40Z
- **Completed:** 2026-05-22T22:54:42Z
- **Tasks:** 3 (all TDD: RED → GREEN)
- **Files modified:** 8 (across six task commits)

## Accomplishments
- `Mailglass.OptionalDeps.GenSmtp.decode/2` (core, `@since "1.2.0"`) wraps `:mimemail.decode/2` in `try/rescue` AND `catch :throw` AND `catch :exit`, prepending the mandatory `{:encoding, :none}` (skips iconv, which gen_smtp does not bundle — verified `:iconv` is absent in the worktree) and `{:allow_missing_version, true}`. It never raises: `erlang:error` → `{:error, {:error, _}}`, `throw` → `{:error, {:throw, _}}`, `:exit` → `{:error, {:exit, _}}`. `:mimemail` is now in the `@compile` no-warn list and referenced ONLY inside this gateway.
- `MailglassInbound.MIMEError` is a package-local `defexception` mirroring `Mailglass.ConfigError`: closed `:type` set `[:inbound_mime_invalid, :gen_smtp_unavailable]`, `@derive {Jason.Encoder, only: [:type, :message, :context]}` (excludes `:cause` so raw payload fragments do not leak — T-45-13), `__types__/0` contract helper, `@since "0.2.0"`. It does NOT implement the core `Mailglass.Error` behaviour or join its `@type` union.
- `MailglassInbound.MIME.parse/1,2` returns `{:ok, %{headers, parts, attachments, inline}}` or `{:error, %MIMEError{}}`, never raising (MIME-04). It branches on gateway `available?/0` for the MIME-02 degraded `:gen_smtp_unavailable` fallback, classifies attachments (`disposition == "attachment"`) and inline parts with filename resolution (`disposition_params["filename"] || content_type_params["name"]`), recurses multipart bodies and `message/rfc822`, and bounds recursion with a max-depth guard (T-45-12, default 100) — verified `:mimemail` itself happily decodes 120+ nested levels, so the guard is the real DoS mitigation.
- All access to `:mimemail` flows through the gateway; the no-bare-`:mimemail` invariant holds repo-wide. Core `mix compile --no-optional-deps --warnings-as-errors` exits 0; `mix credo --strict` exits 0 across 366 files (2714 mods/funs).

## Task Commits

Each task was committed atomically (TDD: test → feat):

1. **Task 1: GenSmtp gateway never-raising decode/2 seam** - `1716686` (test) → `7f0b8e0` (feat)
2. **Task 2: MailglassInbound.MIMEError defexception + contract test** - `6f38f02` (test) → `05b1164` (feat)
3. **Task 3: MailglassInbound.MIME parser (never-raise, degraded fallback)** - `3e8d54e` (test) → `05bb6f1` (feat)

**Plan metadata:** committed separately (worktree mode — SUMMARY committed by this agent; STATE/ROADMAP owned by the orchestrator after wave merge).

_No REFACTOR commits were needed — both Task 1 and the parser followed the locked RESEARCH skeletons; the only post-GREEN edits were a Credo-alias correction and an unused-variable fix, folded into the GREEN commits before staging._

## Files Created/Modified
- `lib/mailglass/optional_deps/gen_smtp.ex` - extended with `decode/2` (never-raising MIME parse seam), `:mimemail` added to `@compile` no-warn list, moduledoc documents the three escape mechanisms
- `test/mailglass/optional_deps/gen_smtp_test.exs` - 8 tests: success 5-tuple, the two reachable escape mechanisms (erlang:error + throw), opts merge, guard
- `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` - `MailglassInbound.MIMEError` package-local defexception
- `mailglass_inbound/test/mailglass_inbound/mime_error_test.exs` - 5 tests: `__types__/0`, fields, `Exception.message/1`, `:cause` excluded from JSON, package-local
- `mailglass_inbound/lib/mailglass_inbound/mime.ex` - `MailglassInbound.MIME.parse/1,2`, internal repr builder, depth guard, filename resolution
- `mailglass_inbound/test/mailglass_inbound/mime_test.exs` - 10 tests: MIME-01 canonical/multipart/inline, MIME-04 never-raise (4 inputs), MIME-02 degraded fallback, T-45-12 depth guard
- `CHANGELOG.md` - core 1.2.0 Unreleased entry for `decode/2`
- `mailglass_inbound/CHANGELOG.md` - inbound 0.2.0 Unreleased entry for `MIMEError`

## Decisions Made
See `key-decisions` in frontmatter. The load-bearing one: the RESEARCH parse skeleton used a plain `alias Mailglass.OptionalDeps.GenSmtp` + `GenSmtp.decode/available?` call. That trips the `NoBareOptionalDepReference` Credo check (widened to inbound by 45-01), which keys on the call-site **root alias segment** (`GenSmtp`, a gated dep root) and only exempts calls whose enclosing module is itself a gateway. The established codebase idiom (`MailglassInbound.Execution` aliases `MailglassInbound.OptionalDeps.Oban, as: OptionalOban`) is to alias with a non-gated root segment, so I used `as: OptionalGenSmtp`. This still routes through the sanctioned gateway and keeps Credo green.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aliased the GenSmtp gateway as OptionalGenSmtp to satisfy NoBareOptionalDepReference**
- **Found during:** Task 3
- **Issue:** The RESEARCH-locked parse skeleton's `GenSmtp.decode`/`GenSmtp.available?` calls (via `alias Mailglass.OptionalDeps.GenSmtp`) were flagged by `NoBareOptionalDepReference` because the check matches the call-site root alias segment (`GenSmtp`, a gated dep root) and only exempts gateway-internal calls. `mix credo --strict` failed with 2 warnings.
- **Fix:** Aliased `Mailglass.OptionalDeps.GenSmtp, as: OptionalGenSmtp` and called `OptionalGenSmtp.decode`/`OptionalGenSmtp.available?`, mirroring the existing `OptionalOban` idiom in `MailglassInbound.Execution`. Added an explanatory code comment.
- **Files modified:** mailglass_inbound/lib/mailglass_inbound/mime.ex
- **Verification:** `mix credo --strict` exits 0; all MIME tests still pass.
- **Committed in:** 05bb6f1 (Task 3 GREEN commit)

**2. [Rule 1 - Bug] Removed an unused `body` binding in to_internal/2**
- **Found during:** Task 3
- **Issue:** `to_internal/2` pattern-matched `body` from the top-level 5-tuple but built leaves via `collect_leaves(top, ...)`, leaving `body` unused — `mix compile --warnings-as-errors` flagged it.
- **Fix:** Renamed the binding to `_body`.
- **Files modified:** mailglass_inbound/lib/mailglass_inbound/mime.ex
- **Verification:** Core `mix compile --no-optional-deps --warnings-as-errors` exits 0 (no mime.ex warnings).
- **Committed in:** 05bb6f1 (Task 3 GREEN commit)

**3. [Rule 1 - Bug] Excluded the defexception-injected :__exception__ field in my own struct-fields test**
- **Found during:** Task 2 (test authoring)
- **Issue:** My RED test asserted the struct's `Map.keys/1` equal `[:cause, :context, :message, :type]`, but `defexception` injects `:__exception__`, so the assertion failed against the correct implementation.
- **Fix:** Dropped `:__exception__` before the comparison in the test.
- **Files modified:** mailglass_inbound/test/mailglass_inbound/mime_error_test.exs
- **Verification:** All 5 MIMEError tests pass.
- **Committed in:** 6f38f02 / 05b1164 (test fix folded into the Task 2 RED test before staging GREEN)

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking). All necessary to complete the tasks with the project's lint/compile gates green. No scope creep — every change is within the plan's named files plus the deferred-items log.

## Issues Encountered
- **Pre-existing inbound `--no-optional-deps` Oban warning (out of scope, logged to deferred-items.md).** `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` exits 1 due to `Mailglass.Oban.TenancyMiddleware.wrap_perform/2 is undefined`, referenced from `mailglass_inbound/lib/.../execution/worker.ex:37` (a file 45-03 does not touch). Verified pre-existing by removing both 45-03 files and re-running the identical compile — the same warning still fires. This is a cross-package reference that breaks when Oban is stripped from the core dep under the worktree's Elixir 1.19/OTP 28 toolchain; CI pins 1.18/OTP 27 with the proper dependency graph. The **core** no-optional-deps compile (which Task 1's gateway change affects) exits 0, and 45-03 adds zero new warnings. Out of scope per the scope boundary; a targeted fix belongs to an inbound Oban-seam plan.
- **Worktree `mix deps.get` rewrites the core `mix.lock` (carry-over from 45-01).** Running `mix deps.get` (required to make `mix credo`/`mix test`/`mix compile` runnable in the worktree) re-resolves core deps to newer 1.19/28 versions, churning `mix.lock`. 45-03 changes no core deps, so I reverted `mix.lock` to the phase base before every commit and confirmed the committed lock is byte-identical to the base (`201170e…`). The inbound `mix.lock` (gen_smtp, pinned by 45-01) is also unchanged. Verification runs were performed with the lock synced to the installed deps, then the lock restored for staging.
- **`:mimemail` emits `:debug`-level logging during decode** — visible in test output because the test env runs at `:debug`. It is `:mimemail`'s own logging, not from any 45-03 module; production log levels (`:info`+) suppress it. No action taken (pre-existing library behavior).

## Threat Flags
None — no new security-relevant surface beyond the plan's threat model. The three planned DoS/disclosure mitigations are in place and tested: T-45-10 (never-raise across all three escape mechanisms), T-45-11 (`{:encoding, :none}` skips iconv + `catch :exit` backstop), T-45-12 (max-depth guard), T-45-13 (`:cause` excluded from `Jason.encode!`).

## Known Stubs
None. `MailglassInbound.MIME` is a fully-functional standalone producer. It is intentionally NOT wired into any provider normalize path this phase (D-45-18) — that is the documented plan, not a stub; Phase 46 is the first consumer. The internal repr is populated from real `:mimemail` output, not placeholder data.

## User Setup Required
None — no external service configuration required. `gen_smtp` is an already-resolved optional dependency.

## Next Phase Readiness
- Phase 46 (Mailgun/SES raw-MIME ingress) can call `MailglassInbound.MIME.parse/1` to turn provider raw-MIME payloads into the stable `%{headers, parts, attachments, inline}` repr, with a guaranteed never-raise contract and structured `MIMEError` on malformed input.
- The `:gen_smtp_unavailable` degraded path lets Phase 46 surface a clean error when the optional dep is absent rather than crashing.
- Note for Phase 46: leaf `:body` bytes are NOT UTF-8-transcoded (`{:encoding, :none}` skips iconv); a consumer needing UTF-8 text must transcode using the part's `content_type_params["charset"]`. Documented in the `MailglassInbound.MIME` moduledoc.
- Note for the orchestrator/verifier: the committed core `mix.lock` is intentionally unchanged from the phase base; do not interpret the worktree's locally-upgraded `deps` as a committed change. The inbound `--no-optional-deps` Oban warning is pre-existing (logged to deferred-items.md), not introduced by this plan.

## Self-Check: PASSED

- All 6 created files present on disk (verified via `[ -f ]`).
- All 6 task commits present in git history (1716686, 7f0b8e0, 6f38f02, 05b1164, 3e8d54e, 05bb6f1).
- Core `mix.lock` confirmed byte-identical to the phase base (`201170e…`); inbound `mix.lock` unchanged (`ae2f34…`).
- Core `mix compile --no-optional-deps --warnings-as-errors` exits 0; `mix credo --strict` exits 0; gateway test 8/8; inbound suite (excl. property) 80/80; MIME + MIMEError tests 15/15.
- No bare `:mimemail` reference anywhere in `lib/` or `mailglass_inbound/lib/` outside the gateway.

---
*Phase: 45-inbound-telemetry-idempotency-foundation*
*Completed: 2026-05-22*
