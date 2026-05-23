---
phase: 46-mailgun-ses-inbound-ingress
plan: 02
subsystem: api
tags: [inbound, webhook, mailgun, hmac, replay-cache, mime, dedupe, idempotency, multipart]

# Dependency graph
requires:
  - phase: 46-mailgun-ses-inbound-ingress (Plan 01)
    provides: "Widened Ingress.Provider verify!/2 contract ({:ok, facts} | {:replay} | {:control_plane, status}), net-new MailglassInbound.SignatureError, four-provider plug allowlist + dual SignatureError rescue"
  - phase: 45-inbound-telemetry-idempotency-foundation
    provides: "MailglassInbound.MIME.parse/1 never-raising parser + MIMEError closed-type error"
  - phase: 15-mailgun-webhook-provider
    provides: "Mailglass.Webhook.Providers.MailgunReplayCache (running core ETS cache) + HMAC math reference"
provides:
  - "MailglassInbound.Ingress.Providers.Mailgun — flat-field HMAC-SHA256 verify over timestamp<>token, replay no-op via the running core MailgunReplayCache, two-mode (parsed + raw-MIME) normalize into %InboundMessage{} + evidence, case-insensitive Message-Id extraction"
  - "Mailgun-scoped partial unique fingerprint index (mailglass_inbound_records_mailgun_fingerprint_idx)"
  - "Ingress.Persist Mailgun load_duplicate clause: Message-Id via generic anchor + MD5(raw_mime) fingerprint fallback"
affects: [46-03-ses-ingress, phase-50-inbound-setup-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Reimplement (not extract) JSON-coupled crypto over flat form fields: inbound Mailgun verifies the SAME HMAC math as outbound but reads top-level form fields instead of the nested JSON signature object, leaving v1.x-stable core verify!/3 untouched"
    - "Reuse the running core MailgunReplayCache.check_and_put/2 (never re-supervised) for the replay no-op; reset/0 between test runs"
    - "Two-mode normalize branched on params[\"body-mime\"] presence (payload field, not URL suffix) — raw-MIME routes through the never-raising MIME.parse/1, parsed mode builds from flat fields"
    - "Provider-specific dedupe: Message-Id (generic provider-agnostic index) primary, MD5(raw_mime) fingerprint (new provider-scoped partial unique index) fallback"

key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/ingress/providers/mailgun.ex
    - mailglass_inbound/priv/repo/migrations/20260523120000_add_mailgun_fingerprint_index.exs
    - mailglass_inbound/test/mailglass_inbound/ingress/mailgun_provider_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
    - mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs

key-decisions:
  - "verify!/2 reimplements the ~15-line HMAC over flat form fields (D-46-08); does NOT call core Mailgun.verify!/3 (which Jason.decodes and expects a nested signature object — RESEARCH Pitfall 1)"
  - "Mailgun load_duplicate is a split clause: Message-Id-present rows resolve via the shared load_by_provider_message_id/4 (generic anchor + generic index, DRIFT #2); no-Message-Id rows use the MD5 fingerprint path (new mailgun index, DRIFT #3). A single combined clause was required because Mailgun rows DO carry a provider_message_id (unlike SendGrid), so the SendGrid fingerprint-only clause would have shadowed the generic Message-Id dedupe"
  - "RFC-5322 address/datetime/header helpers were copied (not shared) into mailgun.ex — they are pure and copy cleanly per the phase pattern map; duplicating keeps the provider self-contained without churning sendgrid.ex or introducing a shared module mid-phase"
  - "normalize/2 compatibility shim added to satisfy the still-required behaviour callback (mirrors sendgrid.ex:64-67); the plug dispatches Mailgun through the struct-arity normalize/1"

patterns-established:
  - "Flat-field HMAC reimplementation: extract timestamp/token/signature from request.params (not JSON), :crypto.mac + Plug.Crypto.secure_compare + verify_timestamp! + replay guard, returning the widened {:ok, facts} | {:replay} contract"
  - "Branch-on-payload-field two-mode normalize (params[\"body-mime\"]) feeding the never-raising MIME.parse/1 with a flat-field fallback + parse_warnings on MIME error"

requirements-completed: [MGUN-01, MGUN-02, MGUN-03]

# Metrics
duration: 38min
completed: 2026-05-23
---

# Phase 46 Plan 02: Mailgun Inbound Ingress Summary

**The Mailgun inbound provider: flat-field HMAC-SHA256 verify over `timestamp<>token` (reimplemented, not extracted, to leave stable outbound untouched), a `{:replay}` no-op reusing the running core replay cache, two-mode (parsed + raw-MIME) normalization into `%InboundMessage{}` with raw evidence, and Message-Id-then-MD5-fingerprint dedupe backed by a new Mailgun-scoped partial unique index.**

## Performance

- **Duration:** ~38 min
- **Started:** 2026-05-23T15:34:00Z
- **Completed:** 2026-05-23T16:00:00Z
- **Tasks:** 2
- **Files modified:** 5 (3 created, 2 modified)

## Accomplishments

- `MailglassInbound.Ingress.Providers.Mailgun` `verify!/2`: reimplements HMAC-SHA256 over the FLAT form-field triple (`params["timestamp"]`/`["token"]`/`["signature"]`, D-46-08), constant-time `Plug.Crypto.secure_compare`, timestamp tolerance + future-skew, and a replay guard via the RUNNING core `MailgunReplayCache.check_and_put/2` (D-46-02, never re-supervised). Authentic POST → `{:ok, %{auth: :hmac}}`; forgery → `MailglassInbound.SignatureError(:bad_signature, provider: :mailgun)`; replay → `{:replay}` 200 no-op (never a raise/401).
- `extract_message_id/1`: pulls the RFC `Message-Id` case-insensitively from the `message-headers` JSON `[name, value]` pairs list (D-46-10); the `token` (replay nonce) is never used for dedupe.
- `normalize/1` two modes branched on `params["body-mime"]` presence (D-46-09, RESEARCH Open Question 3): RAW-MIME mode routes `body-mime` through the never-raising `MailglassInbound.MIME.parse/1` (malformed MIME → `parse_warnings`, falls back to flat fields, never raises); PARSED mode builds the canonical message from `body-plain`/`body-html`/`stripped-*` + `message-headers` + Mailgun address fields. Provider quirks stay in the evidence map (`raw_payload`/`raw_headers`/`raw_mime`/`verification_facts`/`parse_warnings`/`attachment_blobs`); the public `%InboundMessage{}` struct is not widened (MGUN-03).
- Attachments captured into `attachment_blobs` as `"index:filename" => bytes` for both parsed-mode (`attachment-N` flat fields) and raw-MIME-mode (MIME repr attachments).
- New migration `20260523120000_add_mailgun_fingerprint_index.exs`: Mailgun-scoped partial unique index `where: "provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL"` (DRIFT #3). Does NOT recreate the `raw_mime_fingerprint` generated column (already created by `20260506220000`) and adds no Message-Id index (the generic `_postmark_idempotency_idx` already covers Mailgun Message-Id rows, DRIFT #2).
- `Ingress.Persist` Mailgun `load_duplicate` clause: Message-Id present → generic anchor query; absent → `md5(raw_mime)` fingerprint query against the new index. Postgres-backed tests prove both convergence paths.

## Task Commits

1. **Task 1: Mailgun flat-field HMAC verify + replay no-op + Message-Id extraction (TDD)** — `57bfc11` (test, RED) → `466f656` (feat, GREEN)
2. **Task 2: Mailgun normalize (parsed + raw-MIME) + evidence; fingerprint migration + persist dedupe (TDD)** — `5e04a73` (feat; RED normalize tests + GREEN implementation in one commit after the RED tests were appended to the same test file)

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/mailgun.ex` — Mailgun provider (verify!/2 flat-field HMAC + replay; normalize/1 two modes; extract_message_id/1; copied RFC-5322 helpers) (created)
- `mailglass_inbound/priv/repo/migrations/20260523120000_add_mailgun_fingerprint_index.exs` — Mailgun-scoped MD5 fingerprint partial unique index (created)
- `mailglass_inbound/test/mailglass_inbound/ingress/mailgun_provider_test.exs` — 20 tests: verify (HMAC/forged/missing/skew/replay/config), extract_message_id, normalize (parsed/raw-MIME/evidence), reuse-running-cache guard (created)
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` — Mailgun load_duplicate clause (Message-Id + fingerprint fallback) + shared load_by_provider_message_id/4 helper (modified)
- `mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs` — 3 new Postgres-backed tests: same-Message-Id dedupe, no-Message-Id identical-raw dedupe, migration documentation (modified)

## Decisions Made

- **Reimplement, not extract (Mailgun HMAC):** core `Mailgun.verify!/3` `Jason.decode`s the body and expects a nested `%{"signature" => %{...}}` object — wrong for inbound's flat form fields. The ~15-line HMAC math was reimplemented over `request.params` rather than refactoring stable outbound code (D-46-01 override clause; RESEARCH Pattern 1).
- **Split Mailgun dedupe clause (corrected during build):** the plan/PATTERNS analog was the SendGrid fingerprint-only clause, but SendGrid rows always have `provider_message_id: nil` while Mailgun rows carry the Message-Id. A naive copy of the SendGrid clause matched on `"mailgun"` and returned `nil` for fingerprint-absent rows, shadowing the generic Message-Id dedupe. Resolved by splitting into a Message-Id-present clause (delegates to the shared `load_by_provider_message_id/4`) and a Message-Id-absent fingerprint clause. (See Deviations Rule 1.)
- **Copied RFC-5322 helpers:** the SendGrid address/datetime/header helpers are `defp` and pure; copying them into `mailgun.ex` (per PATTERNS line 113: "copy cleanly") kept the provider self-contained and avoided touching the shipped SendGrid provider or inventing a shared module mid-phase.
- **normalize/2 shim:** the behaviour still requires `normalize/2` (only `verify!: 2, verify!: 3` are `@optional_callbacks`). A thin `normalize/2` compatibility shim (mirroring `sendgrid.ex:64-67`) was added so the module compiles clean under `--warnings-as-errors`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched declared dependencies (empty deps/ in fresh worktree)**
- **Found during:** Setup (before Task 1 could compile/test)
- **Issue:** `deps/` was empty in the fresh worktree; tests could not compile.
- **Fix:** Ran `mix deps.get` — declared deps already pinned in the committed `mix.lock` (NOT a new package install, so not excluded by the Rule 3 package-install carve-out).
- **Files modified:** none (environment setup)
- **Commit:** N/A

**2. [Rule 3 - Blocking] normalize/2 behaviour callback unimplemented under --warnings-as-errors**
- **Found during:** Task 1 (clean-compile requirement)
- **Issue:** `@behaviour MailglassInbound.Ingress.Provider` requires `normalize/2`; implementing only `verify!/2` left it unimplemented, failing `mix compile --warnings-as-errors` (a plan verification gate).
- **Fix:** Added a `normalize/2` compatibility shim + `normalize/1` (placeholder in Task 1, real two-mode body in Task 2), mirroring SendGrid's shim. The behaviour marks `verify!` optional but not `normalize`, so the shim is the in-scope fix (no Plan-01 behaviour edit needed).
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/ingress/providers/mailgun.ex`
- **Commit:** `466f656` (Task 1), completed in `5e04a73` (Task 2)

**3. [Rule 1 - Bug] Mailgun fingerprint-only dedupe clause would shadow Message-Id dedupe**
- **Found during:** Task 2 (writing the persist clause from the SendGrid analog)
- **Issue:** Copying the SendGrid `load_duplicate(repo, _, "mailgun", _message, evidence)` fingerprint-only clause would have matched ALL Mailgun rows and returned `nil` whenever no `raw_mime` fingerprint existed — preventing Mailgun rows WITH a Message-Id from ever hitting the generic Message-Id dedupe (Elixir matches the first clause only; no fall-through). This would break MGUN dedupe for the common parsed-mode case (Message-Id present, no raw MIME).
- **Fix:** Split the Mailgun clause into a Message-Id-present clause (delegating to a new shared `load_by_provider_message_id/4` extracted from the generic clause) and a Message-Id-absent fingerprint clause.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`
- **Verification:** Both Postgres-backed dedupe tests pass (same-Message-Id → 1 record; no-id identical-raw → 1 record).
- **Commit:** `5e04a73` (Task 2)

---

**Total deviations:** 3 (1 environment, 1 blocking compile, 1 correctness bug)
**Impact on plan:** All deviations were necessary for compilation or correctness. No scope creep — files stayed within the declared set; no overlap with the parallel 46-03 (SES) plan. `mix.lock` was left unmodified (deps.get used the committed lock).

## Issues Encountered

- gen_smtp's `mimemail` decoder emits `[debug]` log lines during raw-MIME parse tests — log noise only, not failures. Left as-is (debug-level, not surfaced at default log level in production).
- `mix ecto.migrate -r MailglassInbound.TestRepo` does not find the migration directory via the default path; the test_helper computes the path via `:code.priv_dir(:mailglass_inbound)` and runs all migrations at startup, so the new index is applied automatically on test run. Verified via the live dedupe SQL in the Postgres-backed tests.

## Threat Model Coverage

- **T-46-10 (Spoofing):** HMAC-SHA256 over `timestamp<>token` via `:crypto.mac` + constant-time `Plug.Crypto.secure_compare`; forgery raises `MailglassInbound.SignatureError(:bad_signature)` → 401 no-recovery. Tested (forged signature + missing fields).
- **T-46-11 (Replay/Tampering):** `check_and_put/2` on the RUNNING core cache → `{:replay}` 200 no-op, no second InboundRecord; cache reused, not re-supervised. Tested (same token twice → `{:ok}` then `{:replay}`).
- **T-46-12 (Tampering — timestamp skew):** `verify_timestamp!` tolerance + future-skew raises `:timestamp_skew`. Tested (stale + future timestamps).
- **T-46-13 (Tampering — dup insert):** dedupe on `(tenant_id, provider, Message-Id)` via generic index + MD5(raw_mime) fingerprint fallback via the new mailgun index; `token` never used for dedupe. Tested (both Postgres-backed convergence paths).
- **T-46-14 (DoS — raw-MIME parse):** `MailglassInbound.MIME.parse/1` never raises + records `parse_warnings`; a malformed body yields a degraded record, not a crash. Tested (malformed body-mime).
- **T-46-15 (Info Disclosure):** PII (recipient/subject/body) stays in tenant-scoped evidence/records; `verify_facts` is PII-free (`%{auth: :hmac}`). `select_safe_headers/1` strips `authorization`.

## Self-Check: PASSED

All created files verified on disk; all task commits (`57bfc11`, `466f656`, `5e04a73`) present in git history. Both compile lanes (`--warnings-as-errors`, `--no-optional-deps --warnings-as-errors`) green; 26 plan tests + 53 full-ingress tests pass with 0 failures.
