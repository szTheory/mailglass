---
phase: 01-foundation
plan: 03
subsystem: infra
tags: [config, telemetry, repo, idempotency, nimble-options, persistent-term, stream-data, phase-1, wave-2]

requires:
  - phase: 01-01
    provides: "Project scaffold + OTP Application with Code.ensure_loaded? guard for Mailglass.Config.validate_at_boot!/0 + Wave 0 test stubs (config_test, telemetry_test, repo_test, idempotency_key_test) under @moduletag :skip ready to de-skip + NimbleOptions 1.1 and StreamData 1.3 already in deps."
  - phase: 01-02
    provides: "Mailglass.ConfigError with closed :type atom set (:missing | :invalid | :conflicting | :optional_dep_missing) and new/2 builder — consumed by Mailglass.Repo.repo/0 for the unset-:repo failure path."
provides:
  - "Mailglass.Config — NimbleOptions-validated schema (adapter, theme, telemetry, renderer, tenancy, suppression_store), new!/1 builder, validate_at_boot!/0 that reads Application env and caches brand theme in :persistent_term (D-19), get_theme/0 O(1) reader; sole caller of Application.compile_env* per LINT-08."
  - "Mailglass.Telemetry — 4-level span helpers (span/3 generic, render_span/2 named), execute/3 for non-span emits, attach_default_logger/1 with module-attribute handler id, @moduledoc event catalog locking the Phase 1 event shape and the D-31 whitelist/forbidden metadata contract."
  - "Mailglass.Repo — slim Phase 1 facade; transact/1 delegates to the host repo via Application.get_env(:mailglass, :repo); repo/0 resolver raises Mailglass.ConfigError.new(:missing, context: %{key: :repo}) when unset; SQLSTATE 45A01 translation documented as a forward-reference stub for Phase 2's events-ledger trigger."
  - "Mailglass.IdempotencyKey — pure utility; for_webhook_event(provider, event_id) returns 'provider:event_id' and for_provider_message_id(provider, message_id) returns 'provider:msg:message_id'; sanitize/1 strips [^\\x20-\\x7E] (control chars, DEL, non-ASCII) and caps at 512 bytes (T-IDEMP-001)."
  - "Four test files de-skipped and wired to real assertions: config_test (7 tests), telemetry_test (5 tests + 1 StreamData property across 1000 runs proving no PII leak), repo_test (4 tests incl. FakeRepo fixture), idempotency_key_test (10 tests)."
affects: [phase-01-plan-04-optional-deps, phase-01-plan-05-components, phase-01-plan-06-renderer, phase-2-persistence-tenancy, phase-3-outbound, phase-4-webhooks, phase-5-admin, phase-6-credo, phase-7-installer]

tech-stack:
  added:
    - "NimbleOptions 1.1 schema validation with docs interpolation via NimbleOptions.docs(@schema)"
    - ":persistent_term-cached brand theme (read on every render, written once at boot)"
    - "StreamData property test harness — first real property test in the repo (11-key whitelist subset check across 1000 generated metadata maps)"
    - "ExUnit.CaptureLog integration for isolating :telemetry.handler.failure log output in the T-HANDLER-001 regression test"
  patterns:
    - "NimbleOptions schema declared BEFORE @moduledoc so NimbleOptions.docs(@schema) interpolates into the generated documentation"
    - "validate_at_boot!/0 reads Application.get_all_env(:mailglass) |> Keyword.take(known_keys) — narrow read so unrelated app-env keys don't leak into NimbleOptions validation"
    - ":persistent_term key shape {Module, :topic} so every caller reads from the same namespaced key (Mailglass.Config writes, Mailglass.Components.Theme.get/0 will read in Plan 05)"
    - ":telemetry.span/3 unconditionally merges :telemetry_span_context into event metadata for OTel correlation (library machinery, not PII); property tests strip it before asserting the whitelist invariant"
    - "StreamData metadata generation via list_of(tuple({key, value})) |> Enum.into(%{}) — avoids StreamData.map_of/2's uniq-key requirement exhausting a small key space"
    - "Module-private repo/0 resolver pattern (accrue convention): every public Repo facade function calls repo() which raises Mailglass.ConfigError on unset :repo, failing fast before any database round-trip"

key-files:
  created:
    - "lib/mailglass/config.ex — NimbleOptions-validated runtime config; @schema declared pre-moduledoc for doc interpolation; validate_at_boot!/0 caches theme in :persistent_term and optionally attaches default telemetry logger"
    - "lib/mailglass/telemetry.ex — 4-level span helpers + execute/3 + attach_default_logger/1 + handle_event/4; @moduledoc event catalog locks Phase 1 events ([:mailglass, :render, :message]) and the D-31 whitelist/forbidden metadata contract"
    - "lib/mailglass/repo.ex — thin facade over host-configured Ecto.Repo; transact/1 delegates to repo().transact/2; repo/0 raises Mailglass.ConfigError.new(:missing, context: %{key: :repo}) when unset; immutability-translation helper stubbed as forward reference for Phase 2"
    - "lib/mailglass/idempotency_key.ex — pure utility; for_webhook_event/2 and for_provider_message_id/2; sanitize/1 strips non-printable-ASCII + caps at 512 bytes (T-IDEMP-001)"
  modified:
    - "test/mailglass/config_test.exs — @moduletag :skip removed; 7 real assertions across new!/1 (happy + invalid-key + invalid-type), validate_at_boot!/0 (returns :ok + caches theme), get_theme/0"
    - "test/mailglass/telemetry_test.exs — @moduletag :skip removed; 5 tests covering render_span :stop + :start events, T-HANDLER-001 handler-isolation regression (CaptureLog isolates :telemetry.handler.failure noise), execute/3 raw-event emit, attach_default_logger/1 idempotency; 1 StreamData property asserts the D-31 metadata whitelist across 1000 generated renders"
    - "test/mailglass/repo_test.exs — @moduletag :skip removed; 4 tests using a FakeRepo fixture; raises Mailglass.ConfigError on unset :repo + delegates on configured repo + propagates {:error, reason} tuples"
    - "test/mailglass/idempotency_key_test.exs — @moduletag :skip removed; 10 tests covering format, determinism, control-char stripping (0x00, 0x01), DEL (0x7F), non-ASCII stripping, 512-byte cap, provider disambiguation, webhook-vs-message-id namespace disjointness"
    - "mix.exs — dropped the Mailglass.Config.validate_at_boot!/0 forward-reference MFA from elixirc_options no_warn_undefined (Plan 01-01 flagged it as 'removes naturally when Plan 03 lands Config'; Config now exists, --warnings-as-errors passes without the suppression)"

key-decisions:
  - ":telemetry_span_context is stripped before the whitelist subset check in the StreamData property test. The telemetry library's merge_ctx/2 unconditionally injects an opaque span-correlation reference term into every event's metadata for OTel bridging (D-32 documents OTel correlation as adopter-owned). It is library machinery, not adopter-supplied metadata, and carries no PII. Exempting it keeps the whitelist guard pointed at real metadata keys without forcing our render_span/2 wrapper to strip a key that every downstream OTel bridge depends on."
  - "The T-HANDLER-001 regression test wraps render_span in ExUnit.CaptureLog to isolate the :telemetry library's Logger.error log line ('Handler \"...\" has failed and has been detached') from test output. :telemetry.execute/3 catches handler exceptions internally and emits [:telemetry, :handler, :failure] — the caller's pipeline return value flows through unchanged, which is what we assert. CaptureLog keeps the regression log noise out of CI output without masking real failures."
  - "The StreamData metadata generator builds the input map from list_of(tuple({key, value})) |> Enum.into(%{}) rather than StreamData.map_of/2. map_of/2 enforces unique keys in its generated map; with an 11-element whitelist and list sizes ranging 0..15, map_of hit TooManyDuplicatesError almost immediately. The list-of-tuples + Enum.into shape allows duplicate keys (last one wins), deduplicates naturally, and still exercises the 'subset of whitelist' invariant across the full 1000-run check."
  - "Mailglass.Repo.transact/1 calls repo().transact(fun, opts) — Ecto 3.13+ transact/2 API, not the deprecated transaction/1. Transact accepts a zero-arity function returning {:ok, v} | {:error, reason} and rolls back on :error without Ecto.Repo.rollback/1. The Phase 2 events-ledger append path relies on this tuple-rollback semantics, so we ship transact/1 (not transaction/1) as the sole Phase 1 export."
  - "Dropped the forward-reference {Mailglass.Config, :validate_at_boot!, 0} MFA from elixirc_options no_warn_undefined in mix.exs. Plan 01-01 added it with a comment flagging removal at Plan 03 lands Config; leaving the stale entry obscures the real optional-dep surface (Oban, OpenTelemetry, MJML, GenSmtp, Sigra). Removing it verified no compile regressions via force-rebuild in both --warnings-as-errors lanes."

patterns-established:
  - "NimbleOptions schema-before-moduledoc: @schema must be declared before @moduledoc so NimbleOptions.docs(@schema) interpolates the generated options docs into the module documentation. Every Mailglass module that takes validated options (future: Mailable opts, Adapter opts) follows this shape."
  - ":persistent_term namespaced-key pattern: {Module, :topic} tuples so the writer module and any reader can both express the key without accidental collision. Mailglass.Config writes {Mailglass.Config, :theme}; Phase 5 admin will write e.g. {Mailglass.Admin, :session_secret}."
  - "4-level telemetry path + :start/:stop/:exception suffix at every emit site: [:mailglass, :domain, :resource, :action] prefix; Phase 1 render is [:mailglass, :render, :message, :start|:stop|:exception]. Phase 2 events will emit [:mailglass, :persist, :event, :*]; Phase 3 sends [:mailglass, :send, :message, :*]; Phase 4 webhooks [:mailglass, :webhook, :verify, :*] + [:mailglass, :webhook, :ingest, :*]; Phase 5 preview [:mailglass, :preview, :render, :*]."
  - "Named span helper per domain: render_span/2 today; send_span/2, persist_span/2, webhook_verify_span/2, preview_render_span/2 per domain as those domains land in their owning phases. Helper bodies are ~5 lines, wrap :telemetry.span/3, preserve the caller's return value."
  - "Host-repo facade with runtime-resolved repo/0: every Mailglass.Repo public function calls repo() which reads :mailglass :repo at call time and raises Mailglass.ConfigError if unset. Phase 2 events append, Phase 3 delivery upsert, and Phase 4 webhook ingest all route through this facade."
  - "IdempotencyKey namespace disambiguation via 'msg:' infix: for_webhook_event returns 'provider:id' while for_provider_message_id returns 'provider:msg:id'. The infix keeps the two namespaces provably disjoint in the UNIQUE partial index even when the provider happens to reuse a string across the two id types."

requirements-completed: [CORE-02, CORE-03, CORE-04, CORE-05]

duration: 10min
completed: 2026-04-22
---

# Phase 1 Plan 3: Config + Telemetry + Repo + IdempotencyKey Summary

**Four zero-dep foundation modules land — NimbleOptions-validated runtime config with `:persistent_term`-cached brand theme, 4-level telemetry span helpers with a lint-time-enforceable metadata whitelist (proved at runtime via a 1000-run StreamData property), the host-Repo facade that every Phase 2+ DB write routes through, and a pure idempotency-key utility that sanitizes non-printable-ASCII before keys reach the UNIQUE partial index.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-22T14:50:00Z (estimated — Plan 01-02 completed 14:46)
- **Completed:** 2026-04-22T14:57:30Z (approx. per last commit `f76be5c`)
- **Tasks:** 2 / 2
- **Files created:** 4 (config.ex, telemetry.ex, repo.ex, idempotency_key.ex)
- **Files modified:** 5 (4 test files + mix.exs forward-ref cleanup)

## Accomplishments

- **Mailglass.Config** ships with the Phase 1 schema (adapter, theme w/ colors + fonts sub-maps, telemetry.default_logger, renderer.css_inliner + plaintext, tenancy, suppression_store; `:repo` declared but not required in Phase 1 per plan notes). `new!/1` validates and returns a plain keyword list; `validate_at_boot!/0` reads `Application.get_all_env/1`, validates against the schema, caches the brand theme in `:persistent_term` (D-19), and optionally attaches the default telemetry logger. `get_theme/0` provides an O(1) read for renderers.
- **Mailglass.Telemetry** lands the 4-level event convention verbatim: generic `span/3` wraps `:telemetry.span/3` preserving the caller's return value; `render_span/2` is the Phase 1 named helper for `[:mailglass, :render, :message]`; `execute/3` one-shot for non-span emits; `attach_default_logger/1` uses a module-attribute handler id so the attach/detach sequence is idempotent. The `@moduledoc` locks the Phase 1 event catalog and documents the whitelist + forbidden metadata keys (D-31).
- **Mailglass.Repo** ships the slim Phase 1 facade exactly as CONTEXT.md Claude's-discretion notes describe: `transact/1` delegates to the host repo via Ecto 3.13+ `transact/2` API (not the deprecated `transaction/1`); private `repo/0` resolver raises `Mailglass.ConfigError.new(:missing, context: %{key: :repo})` on unset config. The SQLSTATE 45A01 translation point is documented as a commented forward-reference stub inside the module for Phase 2 to activate alongside the immutability trigger.
- **Mailglass.IdempotencyKey** ships `for_webhook_event/2` ("provider:event_id") and `for_provider_message_id/2` ("provider:msg:message_id"); `sanitize/1` strips `[^\x20-\x7E]` (control chars 0x00-0x1F, DEL 0x7F, non-ASCII) and caps at 512 bytes before the key lands in the UNIQUE partial index. The `msg:` infix guarantees namespace disjointness between the two key types.
- **Tests** de-skipped and wired to real assertions across four files. The telemetry StreamData property runs 1000 checks proving that no user-supplied metadata key escapes the whitelist (T-PII-001 runtime evidence to complement Phase 6's lint-time enforcement). The T-HANDLER-001 test verifies `:telemetry.span/3`'s internal try/catch: a handler that raises is auto-detached by the library, `[:telemetry, :handler, :failure]` is emitted, and the render_span caller's return value flows through unchanged.
- **`mix compile --warnings-as-errors`** and **`mix compile --no-optional-deps --warnings-as-errors`** both exit 0. **`mix test`** exits 0 with **58 tests + 1 property, 0 failures, 14 skipped** (Wave 0 stubs owned by Plans 01-04 / 01-05 / 01-06).

## Task Commits

1. **Task 1: Config + Telemetry** — `0f5d86d` (feat)
2. **Task 2: Repo + IdempotencyKey** — `4b40ea8` (feat)
3. **Follow-up: drop stale forward-ref from mix.exs no_warn_undefined** — `f76be5c` (chore)

Both tasks were marked `tdd="true"` in the plan. RED/GREEN evidence:

- Task 1 RED: `mix test test/mailglass/config_test.exs test/mailglass/telemetry_test.exs` pre-implementation → 13 failures (all `UndefinedFunctionError` for `Mailglass.Config.*` and `Mailglass.Telemetry.*`).
- Task 1 GREEN: same command post-implementation → 1 property + 12 tests, 0 failures.
- Task 2 RED: `mix test test/mailglass/repo_test.exs test/mailglass/idempotency_key_test.exs` pre-implementation → 14 failures (all `UndefinedFunctionError` for `Mailglass.Repo.transact/1` and `Mailglass.IdempotencyKey.*`).
- Task 2 GREEN: same command post-implementation → 14 tests, 0 failures.

## Files Created/Modified

| File | Purpose |
|------|---------|
| `lib/mailglass/config.ex` | NimbleOptions schema (6 fields + nested colors/fonts/renderer/telemetry), `new!/1`, `validate_at_boot!/0` (Application.get_all_env → validate → :persistent_term cache + optional logger attach), `get_theme/0` |
| `lib/mailglass/telemetry.ex` | `span/3`, `render_span/2`, `execute/3`, `attach_default_logger/1`, `handle_event/4`, `format_event/3`; `@moduledoc` event catalog locks Phase 1 event shape and metadata policy |
| `lib/mailglass/repo.ex` | `transact/1` delegates via Ecto 3.13+ `transact/2`; private `repo/0` raises `Mailglass.ConfigError` on unset `:repo`; commented immutability-translation stub for Phase 2 |
| `lib/mailglass/idempotency_key.ex` | `for_webhook_event/2`, `for_provider_message_id/2` (`msg:` infix for namespace disjointness), `sanitize/1` (strip `[^\x20-\x7E]` + cap @ 512 bytes) |
| `test/mailglass/config_test.exs` | 7 tests: `new!/1` happy + unknown key + invalid type, `validate_at_boot!/0` returns `:ok` + caches theme, `get_theme/0` returns keyword list |
| `test/mailglass/telemetry_test.exs` | 5 tests + 1 property: `:stop` + `:start` event shape, T-HANDLER-001 (CaptureLog-isolated), `execute/3` raw, `attach_default_logger/1` idempotency, 1000-run StreamData whitelist property |
| `test/mailglass/repo_test.exs` | 4 tests: unset-`:repo` raises ConfigError + carries correct `:type`/`:context`; configured FakeRepo delegates + propagates `{:error, reason}` |
| `test/mailglass/idempotency_key_test.exs` | 10 tests: format, determinism, 0x00/0x01 sanitization, DEL (0x7F) sanitization, non-ASCII stripping, 512-byte cap, provider disambiguation, webhook-vs-message-id namespace disjointness, provider_message_id control-char stripping |
| `mix.exs` | Dropped the Plan 01-01 forward-reference MFA `{Mailglass.Config, :validate_at_boot!, 0}` from `elixirc_options[:no_warn_undefined]` — Config now exists and the suppression is no longer needed |

## Decisions Made

- **`:telemetry_span_context` exempted from whitelist check.** `:telemetry.span/3`'s internal `merge_ctx/2` unconditionally injects an opaque span-correlation reference term into every event's metadata for OTel bridging (D-32). It is library machinery — adopter code never writes it — and carries no PII. The property test strips it before the subset check. Documented inline at the top of `telemetry_test.exs` so future readers understand why one key is waived.
- **T-HANDLER-001 test uses `ExUnit.CaptureLog`.** `:telemetry.execute/3` catches handler exceptions internally, emits `[:telemetry, :handler, :failure]`, and auto-detaches the failing handler via a `Logger.error` line. The pipeline return value flows through unchanged (which is what we assert), but the `Logger.error` noise would pollute CI output every run. CaptureLog isolates the expected log without masking real test failures; we even `tap` the captured log to assert the "has been detached" fragment is present, turning the log noise into a positive signal.
- **StreamData metadata generator uses `list_of(tuple/2) |> Enum.into(%{})`, not `StreamData.map_of/2`.** `map_of/2` enforces unique keys during map construction. With an 11-element whitelist and list sizes 0..15, duplicate-key retries exhausted `StreamData.TooManyDuplicatesError` immediately. The list-of-tuples shape allows duplicate keys (`Enum.into/2` deduplicates naturally, last one wins) and still exercises the "metadata keys ⊂ whitelist" invariant across the full 1000-run check.
- **`Mailglass.Repo.transact/1` targets Ecto 3.13+ `transact/2`.** The plan explicitly calls out preferring `transact/2` over the deprecated `transaction/2`. `transact/2` accepts a zero-arity function returning `{:ok, v} | {:error, reason}` and rolls back on `:error` without requiring `Ecto.Repo.rollback/1`. The Phase 2 events-ledger append path relies on the tuple-rollback semantics, so we ship `transact/1` (not `transaction/1`) as the only Phase 1 export.
- **Dropped the stale `{Mailglass.Config, :validate_at_boot!, 0}` forward-reference from `mix.exs`.** Plan 01-01 explicitly documented this as a "removes naturally when Plan 03 lands Config" entry. Config now exists; both `--warnings-as-errors` lanes compile cleanly without the suppression. Leaving it in place would clutter the genuine optional-dep surface list (Oban, OpenTelemetry, MJML, GenSmtp, Sigra). Force-rebuild on both compile lanes confirmed no regressions before commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] `:telemetry_span_context` injected by `:telemetry.span/3` broke the initial property-test assertion**

- **Found during:** Task 1 GREEN verification (`mix test test/mailglass/telemetry_test.exs`).
- **Issue:** The initial property test implementation asserted `MapSet.subset?(MapSet.new(keys), MapSet.new(@whitelisted_keys))` against the raw metadata map received by the telemetry handler. The first property run failed with `Metadata contained non-whitelisted keys: [:telemetry_span_context]`. `:telemetry.span/3`'s internal `merge_ctx/2` unconditionally merges this key into every event's metadata for OTel span correlation — it is not adopter-supplied and carries no PII, but the raw subset check flagged it as a whitelist violation.
- **Fix:** Added a `@telemetry_infrastructure_keys [:telemetry_span_context]` module attribute, strip it from the observed keys before the subset check, and documented the reason in a multi-line comment at the top of the test module. The mailglass whitelist guards adopter-supplied metadata; library-injected correlation terms are out of scope.
- **Files modified:** `test/mailglass/telemetry_test.exs`
- **Verification:** Property now passes all 1000 runs.
- **Committed in:** `0f5d86d` (Task 1 commit).

**2. [Rule 3 — Blocking] `StreamData.map_of/2` exhausts the small 11-element whitelist key space**

- **Found during:** Task 1 GREEN verification (`mix test test/mailglass/telemetry_test.exs`).
- **Issue:** After fixing deviation #1, the property test failed on the ~8th StreamData run with `StreamData.TooManyDuplicatesError: too many (10) non-unique elements were generated consecutively`. `map_of/2` enforces unique keys during generation; with an 11-element key pool and list sizes of 0..15, duplicate retries blew past the generator's 10-duplicate ceiling almost immediately.
- **Fix:** Replaced `StreamData.map_of(member_of(keys), value_gen)` with `StreamData.list_of(tuple({member_of(keys), value_gen})) |> Enum.into(%{})`. The list-of-tuples shape allows duplicate keys (`Enum.into/2` deduplicates, last-write-wins) and still exercises the "subset of whitelist" invariant across 1000 runs.
- **Files modified:** `test/mailglass/telemetry_test.exs`
- **Verification:** Property runs 1000 checks cleanly; empty-map, partial-map, and full-map cases all exercised.
- **Committed in:** `0f5d86d` (Task 1 commit).

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking test-harness issues that surfaced only when the test actually ran against real implementations).
**Impact on plan:** Scope unchanged. Both fixes were local to `test/mailglass/telemetry_test.exs` and are documented inline so future readers understand why the test shape differs from a naive `map_of` + `MapSet.new` pairing. The production modules (`config.ex`, `telemetry.ex`, `repo.ex`, `idempotency_key.ex`) are unchanged from the plan's <action> blocks.

## Issues Encountered

- **Pre-existing OTLP exporter warning at test boot.** The `OTLP exporter module opentelemetry_exporter not found` warning continues to fire at application start because `:opentelemetry` is pulled as an optional dep. Not a compile warning (does not affect `--warnings-as-errors`); continues to document for continuity. Adopters add `{:opentelemetry_exporter, "~> 1.7"}` to their own deps if they want OTLP export.

## Self-Check

- File verification:
  - FOUND: `lib/mailglass/config.ex`
  - FOUND: `lib/mailglass/telemetry.ex`
  - FOUND: `lib/mailglass/repo.ex`
  - FOUND: `lib/mailglass/idempotency_key.ex`
  - FOUND: `test/mailglass/config_test.exs` (de-skipped)
  - FOUND: `test/mailglass/telemetry_test.exs` (de-skipped)
  - FOUND: `test/mailglass/repo_test.exs` (de-skipped)
  - FOUND: `test/mailglass/idempotency_key_test.exs` (de-skipped)
- Commit verification:
  - FOUND: `0f5d86d` (Task 1 — Config + Telemetry)
  - FOUND: `4b40ea8` (Task 2 — Repo + IdempotencyKey)
  - FOUND: `f76be5c` (chore — drop stale forward-ref)
- Gate verification:
  - `mix compile --warnings-as-errors` exits 0
  - `mix compile --no-optional-deps --warnings-as-errors` exits 0
  - `mix test test/mailglass/config_test.exs test/mailglass/telemetry_test.exs test/mailglass/repo_test.exs test/mailglass/idempotency_key_test.exs` exits 0 (35 tests + 1 property, 0 failures)
  - `mix test` exits 0 (58 tests + 1 property, 0 failures, 14 skipped — Wave 0 stubs owned by Plans 01-04 / 01-05 / 01-06)
  - `grep -c Application.compile_env lib/mailglass/config.ex` returns 1 (moduledoc docstring reference only; zero runtime calls — the only mention inside a string documents the LINT-08 convention)
  - `grep -q :persistent_term.put lib/mailglass/config.ex` succeeds (inside `validate_at_boot!/0`)
  - No new untracked files, no accidental deletions (verified via `git diff --diff-filter=D --name-only HEAD~3 HEAD`)

## Self-Check: PASSED

## Next Phase Readiness

- **Plan 01-04 (Message + OptionalDeps)** can now `use Mailglass.Telemetry` span helpers inside the Message struct constructor if it opts to emit a counter event, and can raise `Mailglass.ConfigError.new(:optional_dep_missing, context: %{dep: :oban | :opentelemetry | :mjml | :gen_smtp | :sigra})` from the gateway modules. The Error hierarchy from 01-02 is already wired; this plan added the config surface those gateways will be resolved against.
- **Plan 01-05 (Components)** will read `Mailglass.Config.get_theme/0` at render time to inline brand colors/fonts. The `:persistent_term`-cached theme is the exact read path D-19 specifies — no ETS, no GenServer, O(1) per render.
- **Plan 01-06 (Renderer)** will wrap the pipeline in `Mailglass.Telemetry.render_span/2`, using the exact `[:mailglass, :render, :message]` event path locked by this plan. The metadata whitelist runtime proof (T-PII-001) is now in place, so the Phase 6 lint check that duplicates the guard at compile time has a runtime regression-baseline to test against.
- **Phase 2 (Persistence + Tenancy)** consumes `Mailglass.Repo.transact/1` for the events-ledger append path and activates the commented-out immutability-translation stub (SQLSTATE 45A01 → `Mailglass.EventLedgerImmutableError` reraise). The facade is ready for that drop-in.
- **Phase 3 (Send pipeline)** consumes `Mailglass.IdempotencyKey.for_provider_message_id/2` for the `UNIQUE (provider, provider_message_id)` dedup; Phase 4 webhook ingest consumes `for_webhook_event/2` for the `UNIQUE (idempotency_key) WHERE idempotency_key IS NOT NULL` partial index. Both namespace disjointness and sanitization are proven in tests.

---
*Phase: 01-foundation*
*Completed: 2026-04-22*
