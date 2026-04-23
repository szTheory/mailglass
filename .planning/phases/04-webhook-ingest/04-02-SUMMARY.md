---
phase: 04-webhook-ingest
plan: 02
subsystem: webhook
tags: [plug, postmark, basic_auth, secure_compare, cidr, anymail_taxonomy, iodata, nimble_options]

# Dependency graph
requires:
  - phase: 04-webhook-ingest
    plan: 01
    provides: "V02 migration (mailglass_webhook_events table), :reconciled internal type, Mailglass.WebhookCase + WebhookFixtures, 7 fixture JSONs, :public_key extra_application, Repo.query!/2 passthrough"
  - phase: 01-foundation
    provides: "Mailglass.Config NimbleOptions schema, Mailglass.SignatureError + ConfigError hierarchies, Mailglass.Error behaviour, brand-voiced error messages"
  - phase: 02-persistence-tenancy
    provides: "Mailglass.Events.Event schema (the struct returned by normalize/2), @anymail_event_types + @mailglass_internal_types closed atom sets"
provides:
  - "Mailglass.Webhook.Provider sealed two-callback @behaviour (verify!/3 + normalize/2) — the contract Plan 03 (SendGrid) and Plan 04 (Plug) build against"
  - "Mailglass.Webhook.CachingBodyReader.read_body/2 — Plug :body_reader MFA module with iodata accumulation across {:more, _, _} chunks; conn.private[:raw_body] storage convention"
  - "Mailglass.Webhook.Providers.Postmark — Basic Auth verifier via Plug.Crypto.secure_compare/2, opt-in IPv4 CIDR allowlist, exhaustive RecordType → Anymail taxonomy mapping"
  - ":postmark NimbleOptions sub-tree in Mailglass.Config (enabled, basic_auth, ip_allowlist)"
  - "SignatureError @types extended to 10 atoms (7 new Phase 4 D-21 + 3 legacy Phase 1); Plan 05 formalizes api_stability.md lock"
  - "ConfigError @types extended with :webhook_verification_key_missing + :webhook_caching_body_reader_missing"
  - "Documented pattern: provider identity stashed in Event.metadata with STRING keys (JSONB roundtrip safety per revision W9)"
affects: [04-03, 04-04, 04-05, 04-06, 04-07, 04-08, 04-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Sealed @moduledoc false Provider behaviour (port of lib/mailglass/adapter.ex pattern for webhooks)"
    - "iodata accumulation in :body_reader with IO.iodata_to_binary/1 flatten on final :ok (diverges from lattice_stripe's overwrite-on-more, required for SendGrid batches)"
    - "Two independent Plug.Crypto.secure_compare/2 calls per credential half (not single compare of the concat) — avoids leaking user vs pass boundary timing"
    - "Provider identity in Event.metadata with STRING keys (revision W9) — avoids adding nullable :provider column to mailglass_events + keeps ledger's append-only schema pristine"
    - "CIDR matching via :inet.parse_address/1 + Bitwise shift (no new dep; IPv4-only at v0.1)"
    - "Exhaustive defp map_record_type/1 clauses with explicit TypeCode numerics — no silent catch-all to non-:unknown atom (D-05 + D-23 forward-ref)"
    - "Synthetic provider_event_id construction: RecordType:ID_or_MessageID:first-timestamp — Postmark has no canonical event ID across RecordTypes, so we make UNIQUE deterministic per logical event"
    - "Additive extension of Mailglass.Config NimbleOptions schema; mirrors :tracking and :rate_limit keyword sub-tree shape"

key-files:
  created:
    - "lib/mailglass/webhook/provider.ex"
    - "lib/mailglass/webhook/caching_body_reader.ex"
    - "lib/mailglass/webhook/providers/postmark.ex"
    - "test/mailglass/webhook/caching_body_reader_test.exs"
    - "test/mailglass/webhook/providers/postmark_test.exs"
  modified:
    - "lib/mailglass/errors/signature_error.ex (@types extended to 10 atoms; 7 new D-21 + 3 legacy retained)"
    - "lib/mailglass/errors/config_error.ex (@types + :webhook_verification_key_missing + :webhook_caching_body_reader_missing; 2 new format_message clauses)"
    - "lib/mailglass/config.ex (:postmark NimbleOptions sub-tree added alongside :tracking/:rate_limit)"
    - "test/mailglass/error_test.exs (__types__/0 assertions updated for the expanded closed sets)"
    - "test/mailglass/errors/config_error_test.exs (length assertion 7 → 9; explicit Phase 4 atoms test added)"

key-decisions:
  - "Provider identity (`provider`, `provider_event_id`) lives in Event.metadata with STRING keys, NOT as new columns on the mailglass_events ledger. Ledger stays pristine-append-only; Plan 04 Ingest reads metadata keys to populate mailglass_webhook_events UNIQUE columns. Rule 1 deviation from plan's original %Event{provider: :postmark, provider_event_id: ...} shape."
  - "SignatureError @types keeps legacy Phase 1 atoms (:missing, :malformed, :mismatch) alongside the 7 new Phase 4 D-21 atoms. lib/mailglass/error.ex + test/mailglass/error_test.exs reference legacy atoms and would break if removed. Plan 05 formalizes consolidation in api_stability.md without touching runtime compatibility."
  - "ConfigError gets TWO new atoms (:webhook_verification_key_missing + :webhook_caching_body_reader_missing) per revision B4 — distinct atoms enable adopter-side Grafana alerts / log-scrapers to distinguish 'missing secret' from 'plug wiring gap'."
  - "Bitwise import is inline (import Bitwise at top of module) rather than `use Bitwise` — the latter is OTP 27 deprecated. bsl/bsr/bor available after import without macro expansion."
  - "CIDR matching is IPv4-only at v0.1 — `ip_in_cidr?/3` guards `when is_tuple(remote_ip)` and pattern-matches the 4-tuple shape. v0.5 may extend to IPv6 (Claude's Discretion per plan's design space)."
  - "`verify_ip_allowlist!/1` raises :malformed_header when the allowlist is set but remote_ip is not forwarded by the plug — surfaces the wiring gap explicitly instead of silent allow-through."
  - "Synthetic provider_event_id = '\\#{RecordType}:\\#{ID_or_MessageID}:\\#{first_timestamp}' — Postmark has no canonical single-field event ID; this construction makes `(provider, provider_event_id)` UNIQUE deterministic per logical event (replay-safe)."
  - "Spam_complaint fixture has TypeCode 100 — but the normalize/2 match clauses check `RecordType: \"SpamComplaint\"` BEFORE any TypeCode inspection, so the fixture correctly maps to :complained (TypeCode irrelevant for RecordType=SpamComplaint)."
  - "Test uses `Mailglass.WebhookFixtures.load_postmark_fixture/1` directly rather than the `stub_postmark_fixture/1` import from WebhookCase. ExUnit.CaseTemplate's `using opts do` block's imports don't reliably propagate through the nested `use Mailglass.MailerCase` chain (Rule 3 workaround); module-qualified calls sidestep the issue and make the fixture source explicit."

patterns-established:
  - "Sealed webhook Provider behaviour @moduledoc false with two callbacks isolating crypto from taxonomy — verify!/3 raises, normalize/2 is pure"
  - "Conn-free verifier contract (raw_body + headers + config tuple) so v0.5 SES SQS polling + inbound testing paths can reuse the Provider behaviour without adapter work"
  - "iodata-accumulating Plug :body_reader: list-on-more, flatten-on-ok with IO.iodata_to_binary/1"
  - "Per-provider config sub-trees in Mailglass.Config NimbleOptions schema (`:postmark`, `:sendgrid` follows in Plan 03)"
  - "Provider identity stored in Event.metadata with STRING keys — scales to N providers without schema migrations"
  - "Exhaustive defp clauses for RecordType + TypeCode mapping; unmapped cases Logger.warning + fall through to :unknown (NEVER silent catch-all to a non-:unknown taxonomy atom)"

requirements-completed: [HOOK-01, HOOK-03]
# Note: HOOK-05 (Anymail taxonomy + Logger.warning fallthrough) is fully implemented
# for Postmark in this plan; Plan 03 ships the SendGrid half, at which point HOOK-05
# is complete. Marking HOOK-01 + HOOK-03 only to avoid double-counting.

# Metrics
duration: 13min
completed: 2026-04-23
---

# Phase 4 Plan 2: Webhook Ingest Wave 1A — Provider behaviour + CachingBodyReader + Postmark Summary

**Sealed two-callback `Mailglass.Webhook.Provider` behaviour, iodata-accumulating `Mailglass.Webhook.CachingBodyReader`, Postmark Basic Auth verifier + opt-in CIDR allowlist + exhaustive Anymail normalizer, and the `:postmark` NimbleOptions sub-tree — the foundational request-side primitives every Phase 4 wave composes against.**

## Performance

- **Duration:** ~13 min
- **Started:** 2026-04-23T20:39:56Z
- **Completed:** 2026-04-23T20:52:50Z
- **Tasks:** 3 (Task 3 executed first as precondition, then Task 1, then Task 2)
- **Commits:** 3 task commits (plus a metadata commit after this SUMMARY lands)
- **Files created:** 5
- **Files modified:** 5

## Accomplishments

- **Provider behaviour (`lib/mailglass/webhook/provider.ex`):** Sealed two-callback contract per D-01. `@moduledoc false` enforces the v0.1 sealed lock (PROJECT D-10 defers Mailgun/SES/Resend to v0.5). Callbacks: `verify!/3(raw_body, headers, config) :: :ok` (raises `%SignatureError{}`) + `normalize/2(raw_body, headers) :: [Event.t()]` (pure). Conn-free contract per D-02 — portable to v0.5 SES SQS polling and inbound testing without `%Plug.Conn{}` leakage.
- **CachingBodyReader (`lib/mailglass/webhook/caching_body_reader.ex`):** Plug `:body_reader` MFA module per D-09 verbatim. Accumulates iodata across `{:more, _, _}` chunks and flattens on final `{:ok, _, _}` — required for SendGrid batch payloads up to 128 events (~3 MB). Stores in `conn.private[:raw_body]` (library-reserved; matches lattice_stripe convention, diverges from accrue's `conn.assigns` cons-list per D-09). Adopter-side wiring documented in the moduledoc.
- **Postmark provider (`lib/mailglass/webhook/providers/postmark.ex`):** Basic Auth verifier via two independent `Plug.Crypto.secure_compare/2` calls (timing-attack safe; compared per credential half per D-04). Optional IPv4 CIDR allowlist — off by default, `:inet.parse_address/1` + Bitwise shift for membership test. Exhaustive `normalize/2` with 14 explicit `defp map_record_type/1` clauses covering Delivery/Bounce (7 TypeCodes) / SpamComplaint / Open / Click / SubscriptionChange (2 branches), plus 2 fallthrough-with-`Logger.warning` clauses ensuring no silent catch-all. Provider identity stashed in `Event.metadata` with STRING keys (revision W9) for JSONB roundtrip safety.
- **:postmark NimbleOptions sub-tree (`lib/mailglass/config.ex`):** Additive schema entry with `enabled: true` default, `basic_auth: {user, pass} | nil`, and `ip_allowlist: [cidr_string]` (default `[]`). Mirrors the `:tracking` / `:rate_limit` keyword sub-tree shape — one consistent config shape across mailglass providers.
- **Error atom set extensions:** `Mailglass.SignatureError.@types` extended to 10 atoms (the 7 new D-21 atoms + the 3 Phase 1 legacy atoms retained for backward compatibility with `lib/mailglass/error.ex` + `error_test.exs`). `Mailglass.ConfigError.@types` extended with `:webhook_verification_key_missing` + `:webhook_caching_body_reader_missing` (per revision B4 — distinct atoms for distinct adopter alerting). Both with brand-voiced `format_message/2` clauses. Plan 05 formalizes the `docs/api_stability.md` lock.
- **Test coverage (35 tests, 0 failures):** 5 tests for `CachingBodyReader.read_body/2` covering single-chunk, iodata flatten, nil initial accumulator, and the `conn.private` storage contract. 30 tests for `Postmark.verify!/3` + `normalize/2` covering Basic Auth happy path, all 4 failure atoms, IP allowlist on+off+unforwarded-remote_ip, single-address CIDR, plus every documented RecordType + TypeCode mapping, unmapped fallthrough with `Logger.warning`, malformed JSON, and the synthetic `provider_event_id` construction shape.

## Task Commits

Tasks were executed in dependency order (Task 3 first as precondition, then Task 1, then Task 2) and committed atomically:

1. **Task 3: Extend SignatureError + ConfigError atom sets** — `140a635` (feat) — 3 files, 133 insertions, 14 deletions. Precondition for Task 2's Postmark module which needs to raise the new atoms.
2. **Task 1: Webhook.Provider behaviour + CachingBodyReader** — `e944967` (feat) — 3 new files, 187 insertions.
3. **Task 2: Postmark provider + :postmark NimbleOptions + tests** — `0aa3681` (feat) — 4 files changed, 596 insertions, 3 deletions.

**Plan metadata:** _pending final commit after SUMMARY.md + STATE.md updates_.

## Files Created/Modified

### Created

- `lib/mailglass/webhook/provider.ex` — sealed two-callback behaviour (`verify!/3` + `normalize/2`) with `@moduledoc false`
- `lib/mailglass/webhook/caching_body_reader.ex` — Plug `:body_reader` MFA module with iodata accumulation + flattening
- `lib/mailglass/webhook/providers/postmark.ex` — Postmark Basic Auth verifier + CIDR allowlist + Anymail normalizer + synthetic provider_event_id construction
- `test/mailglass/webhook/caching_body_reader_test.exs` — 5 tests (single-chunk, iodata flatten, nil initial, empty body, storage-location contract)
- `test/mailglass/webhook/providers/postmark_test.exs` — 30 tests across 4 describe blocks covering verify!/3 + normalize/2 surface

### Modified

- `lib/mailglass/errors/signature_error.ex` — `@types` list extended from 4 → 10 atoms (7 new D-21 + 3 legacy); 7 new brand-voiced `format_message/2` clauses; `@type t` union updated; moduledoc rewritten to document the extension
- `lib/mailglass/errors/config_error.ex` — `@types` list extended with `:webhook_verification_key_missing` + `:webhook_caching_body_reader_missing` (9 atoms total); 2 new `format_message/2` clauses; `@type t` union updated; moduledoc updated
- `lib/mailglass/config.ex` — `:postmark` keyword sub-tree added to `@schema`; appended after `:clock`
- `test/mailglass/error_test.exs` — two `__types__/0` assertions updated for the new closed sets (10 atoms for SignatureError; 9 atoms for ConfigError) with explanatory comments tying to D-21 and revision B4
- `test/mailglass/errors/config_error_test.exs` — `length(__types__()) == 7` updated to `== 9`; new test asserting presence of the two Phase 4 atoms

## Decisions Made

- **Provider identity in `Event.metadata` (STRING keys), not as struct columns.** The plan's original `%Event{provider: :postmark, provider_event_id: "..."}` shape doesn't fit the shipped schema — the `%Mailglass.Events.Event{}` struct has neither field, and adding them would require a schema migration (architectural change, Rule 4). But V02 already carries provider + provider_event_id on `mailglass_webhook_events` as the UNIQUE `(provider, provider_event_id)` index columns. The correct composition is: normalize/2 stashes provider identity in `Event.metadata` with string keys; Plan 04's Ingest Multi reads `metadata["provider"]` + `metadata["provider_event_id"]` to populate the webhook_events row. This preserves the append-only ledger's schema and matches revision W9's JSONB-roundtrip discipline. Documented in the Postmark module's moduledoc.
- **Legacy SignatureError atoms retained alongside new D-21 atoms.** `lib/mailglass/error.ex` at line 14 still mentions the legacy "missing, malformed, mismatch, stale" in its `@moduledoc`, and `error_test.exs` lines 15-16 + 62-65 + 105 + 124 all reference legacy atoms. Rather than rewrite them now (out of scope for Task 3's "precondition shim"), the legacy atoms are preserved in `@types` and given identical `format_message/2` clauses. Plan 05 consolidates naming in `docs/api_stability.md` without breaking runtime.
- **Two new ConfigError atoms, not one.** `:webhook_verification_key_missing` covers missing provider signing secrets (Postmark basic_auth, SendGrid public_key). `:webhook_caching_body_reader_missing` is separate per revision B4 — adopters need distinct Grafana alerts / log-scrapers for "plug wiring gap" vs "missing secret." Plan 04's Plug will raise the latter.
- **Bitwise imported inline.** `import Bitwise` is placed at the top of the Postmark module; `use Bitwise` is OTP 27 deprecated. After import, `bsl/2`, `bsr/2`, `bor/2` are available directly without macro-expansion overhead.
- **IPv4-only at v0.1.** `ip_in_cidr?/3` guards `when is_tuple(remote_ip)` and pattern-matches a 4-tuple; IPv6 CIDR support deferred to v0.5 (Claude's Discretion per plan's "exact NimbleOptions schema keys" design space). The guard ensures unexpected IP shapes fall through to `false` without crashing.
- **`verify_ip_allowlist!/1` raises when allowlist-set-but-remote_ip-missing.** Rather than silently allowing (which would bypass the allowlist entirely when the plug forgets to forward `remote_ip`), `verify_ip_allowlist!/1` raises `:malformed_header` with a detail hint in context. Surfaces the wiring gap explicitly to adopters.
- **Synthetic `provider_event_id` construction.** Postmark's webhook payloads use different ID fields per RecordType (`ID` for Bounce, `MessageID` for Delivery/Open/Click, `ID` + `MessageID` for SpamComplaint). The shape `"#{RecordType}:#{id_or_message_id}:#{first_timestamp}"` makes the UNIQUE `(provider, provider_event_id)` index (V02) deterministic for replays of the same logical event. Documented in inline comments.
- **Executed Task 3 first despite being listed third in the plan.** Task 2 (Postmark module) raises the new SignatureError atoms — the module cannot compile without them present in `@types`. The plan's action for Task 3 calls this out as a precondition. Tracked under "Task reordering" rather than "Deviation" since the plan explicitly allows it.
- **Module-qualified fixture loader in tests.** `Mailglass.WebhookFixtures.load_postmark_fixture/1` used directly instead of the `stub_postmark_fixture/1` imported via `Mailglass.WebhookCase`. The ExUnit.CaseTemplate's `using opts do` block's `import` directives don't reliably propagate through the nested `use Mailglass.MailerCase` chain — subsequent plans can either debug that (out of scope for 04-02) or continue using module-qualified calls. The explicit call is arguably clearer at the test call site anyway.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan's `%Event{provider: :postmark, provider_event_id: ...}` shape doesn't fit the shipped schema**

- **Found during:** Task 2 initial implementation + re-read of `lib/mailglass/events/event.ex`
- **Issue:** The plan's Task 2 action specified `%Event{type: type, provider: :postmark, provider_event_id: id, reject_reason: ..., metadata: %{...}}`. The shipped `%Mailglass.Events.Event{}` struct has no `:provider` field and no `:provider_event_id` field — those columns live on `mailglass_webhook_events` (V02), not `mailglass_events`. Building the struct with unknown fields fails at compile time (`Mailglass.Events.Event does not have field :provider`).
- **Fix:** Provider identity is stashed in `Event.metadata` with STRING keys: `metadata: %{"provider" => "postmark", "provider_event_id" => id, "record_type" => ..., "message_id" => ...}`. Matches revision W9's JSONB-roundtrip-safety discipline and avoids a schema migration. Plan 04's Ingest layer will read `metadata["provider"]` + `metadata["provider_event_id"]` to populate the `mailglass_webhook_events` row's UNIQUE columns.
- **Files modified:** `lib/mailglass/webhook/providers/postmark.ex` (build_event/1 shape); `test/mailglass/webhook/providers/postmark_test.exs` (assertions switched from `event.provider == :postmark` to `event.metadata["provider"] == "postmark"`)
- **Verification:** `mix compile --warnings-as-errors --no-optional-deps` exits 0; all 30 Postmark tests pass
- **Committed in:** `0aa3681` (Task 2 commit)

**2. [Rule 1 — Bug] Pre-existing ConfigErrorTest assertion broke after atom-set extension**

- **Found during:** Full-suite run after Task 3
- **Issue:** `test/mailglass/errors/config_error_test.exs:19` asserted `length(ConfigError.__types__()) == 7`. Task 3 adds two new atoms, so the length is now 9.
- **Fix:** Updated assertion to `== 9`; added a new test asserting `:webhook_verification_key_missing in types` and `:webhook_caching_body_reader_missing in types`.
- **Files modified:** `test/mailglass/errors/config_error_test.exs`
- **Verification:** 6/6 tests in that file pass; full suite is 0 failures.
- **Committed in:** `0aa3681` (Task 2 commit — grouped with the NimbleOptions Postmark work since both touch the config surface)

**3. [Rule 3 — Blocking] `stub_postmark_fixture/1` import from `Mailglass.WebhookCase` not in scope**

- **Found during:** First attempt to compile `postmark_test.exs`
- **Issue:** The `using opts do quote do ... end end` block in `Mailglass.WebhookCase` imports `stub_postmark_fixture: 1` via `import Mailglass.WebhookCase, only: [...]`. When the test module invokes `use Mailglass.WebhookCase, async: false`, the nested `use Mailglass.MailerCase, unquote(opts)` call apparently interferes with the subsequent imports — the function was reported undefined at compile time. Debugging the CaseTemplate macro chain is out of scope for Plan 04-02.
- **Fix:** Call `Mailglass.WebhookFixtures.load_postmark_fixture/1` directly in test bodies instead of the imported `stub_postmark_fixture/1` shim. Tests stayed clean, assertions unchanged. Future plans can either debug the CaseTemplate interaction or continue using module-qualified calls.
- **Files modified:** `test/mailglass/webhook/providers/postmark_test.exs` (`stub_postmark_fixture(` → `Mailglass.WebhookFixtures.load_postmark_fixture(` replace-all)
- **Verification:** All 30 Postmark tests pass.
- **Committed in:** `0aa3681` (Task 2 commit)

**4. [Rule 1 — Bug] `error_test.exs` hardcoded `__types__/0` assertions for both SignatureError (4 atoms) and ConfigError (7 atoms)**

- **Found during:** Running `mix test test/mailglass/error_test.exs` after Task 3
- **Issue:** Two assertions bound to the pre-Phase-4 closed atom sets. Direct consequence of the atom-set extension in Task 3.
- **Fix:** Both assertions updated to the new closed sets (10 atoms SignatureError; 9 atoms ConfigError) with comments tying to D-21 + revision B4.
- **Files modified:** `test/mailglass/error_test.exs`
- **Verification:** 18/18 tests pass.
- **Committed in:** `140a635` (Task 3 commit — the atom-set extension owns its test-contract update)

---

**Total deviations:** 4 auto-fixed (3 × Rule 1 bug, 1 × Rule 3 blocking).

**Impact on plan:** All four were direct consequences of the plan's Task 3 pre-condition (shipping new atoms that break test contracts) or the plan's Task 2 action text (which referenced `%Event{provider:, provider_event_id:}` fields that don't exist on the shipped schema). None represent scope creep. The Rule 3 CaseTemplate interaction is a workaround, not a behaviour change — fixture content is identical regardless of import path.

## Threat Flags

None. The threat surface introduced by Plan 04-02 matches the plan's `<threat_model>` exactly: `T-04-01` (spoofing) mitigated by the timing-safe `Plug.Crypto.secure_compare/2` + IP allowlist; `T-04-03` (tampering) mitigated by `CachingBodyReader` capturing raw bytes before any parser can re-encode; `T-04-04` (info disclosure) mitigated by `SignatureError` + `Logger.warning` messages containing only atom + provider, never IP or headers or payload. All three mitigations are verified by tests in this plan's test suite.

## Issues Encountered

- **`ExUnit.CaseTemplate` `using opts do` import propagation flake.** The `import Mailglass.WebhookCase, only: [stub_postmark_fixture: 1, ...]` inside the `quote do ... end` block of `WebhookCase.using/2` doesn't reliably land in the test module when `use Mailglass.MailerCase, unquote(opts)` is also in the same block. Module-qualified calls sidestep the issue cleanly. Worth investigating in Plan 04-04 when multiple WebhookCase consumers exist and more helpers need to be imported.
- **Pre-existing citext OID staleness continues to cause transient full-suite failures** on 10-minute-plus full runs, already documented in `.planning/phases/02-persistence-tenancy/deferred-items.md`. The issue is intermittent — a second full run after the citext-dropping migration test typically clears it. Phase 4 work does not affect the underlying DB state, so this remains a Phase 6 architectural fix candidate.

## User Setup Required

None. Phase 4 Wave 1A is library-only code; adopter config keys (`config :mailglass, :postmark, basic_auth: {"user", "pass"}`) will be documented in `guides/webhooks.md` (Phase 7, per CONTEXT decisions).

## Next Phase Readiness

Plan 04-02 unblocks every remaining Phase 4 plan:

- **Plan 03 (SendGrid verifier + normalizer)** — can declare `@behaviour Mailglass.Webhook.Provider` and implement the same two-callback surface. SendGrid-specific `verify!/3` uses `:public_key.der_decode/2` + `:public_key.verify/4` (per CONTEXT D-03 + RESEARCH §Pattern 2); the Provider contract is crypto-agnostic. Plan 03 also adds the `:sendgrid` NimbleOptions sub-tree alongside the `:postmark` tree this plan shipped.
- **Plan 04 (`Mailglass.Webhook.Plug` + `Mailglass.Webhook.Router`)** — can dispatch against `Mailglass.Webhook.Provider` via a `case provider` exhaustive match; CachingBodyReader is already wired adopter-side (the plug reads `conn.private[:raw_body]`). Plan 04's plug is responsible for forwarding `conn.remote_ip` into `Postmark.verify!/3`'s config map when the allowlist is configured (the plug is the Conn→tuple adapter per D-02).
- **Plan 05 (SignatureError finalization + `api_stability.md`)** — will consolidate the 10 atoms in `SignatureError.@types` down to the 7 D-21 atoms (by removing `:missing`, `:malformed`, `:mismatch` after migrating the handful of legacy raise sites in `lib/mailglass/error.ex` + test assertions). Full `docs/api_stability.md` §Webhook Errors section lands in Plan 05.
- **Plan 06 (Ingest Multi)** — will read `Event.metadata["provider"]` and `Event.metadata["provider_event_id"]` to populate the `mailglass_webhook_events` UNIQUE index columns. The string-key discipline makes this a simple `Map.fetch!/2` — no atom/string conversion needed.

**Blockers or concerns:** None.

**Phase 4 progress:** 2 of 9 plans complete.

## Self-Check: PASSED

Verified:

- `lib/mailglass/webhook/provider.ex` — FOUND
- `lib/mailglass/webhook/caching_body_reader.ex` — FOUND
- `lib/mailglass/webhook/providers/postmark.ex` — FOUND
- `test/mailglass/webhook/caching_body_reader_test.exs` — FOUND
- `test/mailglass/webhook/providers/postmark_test.exs` — FOUND
- Commit `140a635` (Task 3 — atom-set extension) — FOUND in `git log --all`
- Commit `e944967` (Task 1 — Provider + CachingBodyReader) — FOUND
- Commit `0aa3681` (Task 2 — Postmark + config + tests) — FOUND
- `mix compile --warnings-as-errors --no-optional-deps` — exits 0
- `mix test test/mailglass/webhook/` — 35 tests, 0 failures
- `mix verify.phase_02` — 59 tests, 0 failures (474 excluded)
- `mix verify.phase_03` — 62 tests, 0 failures (471 excluded, 2 skipped)
- `mix verify.phase_04` — 0 tests, 0 failures (correct — Wave 1A; Wave 4 ships first `:phase_04_uat`-tagged tests)
- Full `mix test --exclude flaky` — 525 tests + 6 properties, 0 failures (4 skipped)
- `Mailglass.Webhook.Provider.behaviour_info(:callbacks)` → `[verify!: 3, normalize: 2]` (introspection confirms sealed contract)
- `Mailglass.Webhook.Providers.Postmark` declares `@behaviour Mailglass.Webhook.Provider` and exports both callback functions (verified via `module_info`)

---
*Phase: 04-webhook-ingest*
*Completed: 2026-04-23*
