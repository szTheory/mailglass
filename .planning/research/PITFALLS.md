# Pitfalls Research — v0.2 NEW Surfaces Only

**Domain:** Phoenix-native transactional email framework — v0.2 "Production-Credible Core"
**Researched:** 2026-04-26
**Confidence:** HIGH (grounded in 4 prior shipped Elixir/Phoenix OSS libs + RFC analysis + Sourceror + Phoenix.Token ecosystem knowledge; field-knowledge supplements tagged)

> **This file covers NEW pitfalls specific to v0.2 feature surfaces only.**
> The 42 v0.1 pitfalls (LIB-01..07, MAIL-01..09, DIST-01..09, PHX-01..05, OBS-01..04, TEST-01..04, CI-01..05, MAINT-01..04) are archived in `.planning/milestones/v0.1-research/PITFALLS.md` and are not repeated here.

---

## Pitfall Namespace for v0.2

| Prefix | Domain |
|--------|--------|
| API-NN | Public API freeze + codemod task |
| UNSUB-NN | RFC 8058 List-Unsubscribe implementation |
| SUPP-NN | Auto-suppression + soft-bounce escalation |
| STREAM-NN | Message-stream policy enforcement |
| REL-NN | Release-engineering hardening |
| CROSS-NN | Cross-cutting / integration pitfalls |

---

## Critical Pitfalls

### API-01: Unintended Freeze of an Internal Helper via `api_stability.md`

**ID:** API-01
**Severity:** HIGH
**Phase:** Phase 9 (API Redesign + Freeze)

**What goes wrong:**
`api_stability.md` v2 enumerates every exported function in `Mailglass.*` to mark it public. An internal helper — say `Mailglass.Message.Builders.set_reply_to_internal/2` — is accidentally listed because the author ran `mix docs` and copy-pasted the output without filtering. From that moment it is part of the frozen surface. v0.3 needs to rename it; now the rename is a breaking change that forces a major version bump and breaks downstream pinners.

**Why it happens:**
Automation (grepping module exports, `mix docs` output) is faster than manual triage. Internal helpers are public functions in Elixir's module system — there is no `private module` concept. The distinction between "exported by module" and "part of the public API" must be made explicitly.

**How to avoid:**
- All internal functions in `lib/mailglass/` must be tagged with `@doc false` before `api_stability.md` is generated. CI gate: `mix docs --warnings-as-errors` — any undocumented public function in a non-internal module fails. This forces an intentional `@doc false` or a real docstring, making the choice visible.
- `api_stability.md` v2 lists only modules with explicit `@moduledoc` that does NOT include the phrase `Internal API — subject to change without notice`. A custom script (`mix mailglass.stability.check`) diffs current exports against `api_stability.md` and fails CI if anything unreviewed is added or removed.
- Use `@doc false` + module names ending in `.Internal`, `.Impl`, or `.Builders` as the convention. `mix mailglass.stability.check` rejects any `@doc false` function in a non-`.Internal` module (warns; doesn't block) — catching cases where a helper is accidentally public.

**Warning signs:**
- `api_stability.md` lists more than 60 functions across the core surface (v0.2 is a focused freeze, not exhaustive).
- A function named `_internal`, `_impl`, or with a `do_` prefix appears in `api_stability.md`.
- v0.3 PR renames something in `api_stability.md` without a major version bump.

---

### API-02: Codemod Silently Rewrites an Ambiguous `import Swoosh.Email` Site

**ID:** API-02
**Severity:** HIGH
**Phase:** Phase 9 (API Redesign + Codemod)

**What goes wrong:**
`mix mailglass.upgrade.v0_2` finds `import Swoosh.Email` in an adopter's mailable module and rewrites call sites — e.g., `subject("Welcome")` becomes `Mailglass.Message.subject("Welcome", message)`. But the same module also uses `subject/1` from a custom DSL the adopter wrote. Sourceror's pattern matching can't distinguish the two call sites without type context. The codemod rewrites the wrong one. Adopter behavior changes silently.

**Why it happens:**
Sourceror operates on AST patterns, not types. `subject("Welcome")` and `MyDSL.subject("Welcome")` are indistinguishable in the AST without looking at the import chain. The codemod assumes any bare `subject/1` in a module that has `import Swoosh.Email` was imported from Swoosh.

**How to avoid:**
- Before rewriting, check that the target function is ONLY in scope via `import Swoosh.Email` — if any other `import` or `alias` in scope exports the same function name/arity, emit a warning and **skip** the rewrite, printing a human-readable diagnostic: `Skipped: ambiguous call to subject/1 at lib/my_app/user_mailer.ex:42 — multiple imports in scope. Rewrite manually.`
- Add an integration test: a fixture file with both `import Swoosh.Email` and a local module that exports `subject/1`, run the codemod against it, assert the output is unchanged (the codemod declined to rewrite).
- The codemod must NEVER have a "best-guess" silent rewrite. Ambiguity → warn + skip, always.

**Warning signs:**
- Codemod output doesn't print a line for every file it touched.
- A fixture mailable with `import Swoosh.Email` and a local `subject/1` produces a rewritten output.
- The codemod has no `--warn-ambiguous` flag in its help text.

---

### API-03: `update_swoosh/2` Removed — Adopters Lose Raw Swoosh Escape Hatch

**ID:** API-03
**Severity:** HIGH
**Phase:** Phase 9 (API Redesign)

**What goes wrong:**
The v0.2 API redesign hides Swoosh behind `Mailglass.Message` field setters. The author, focused on the clean public surface, removes `update_swoosh/2` as "implementation detail." Adopters who used undocumented Swoosh features (custom headers, BCC, in-reply-to, MIME part ordering) now have no escape route. They cannot upgrade to v0.2 without losing functionality. They file issues. The author must ship a breaking hotfix or leave adopters stuck on v0.1.

**Why it happens:**
"If we hide Swoosh, we should hide ALL of Swoosh" — logical but wrong. The escape hatch is precisely the documented acknowledgment that mailglass can't wrap every Swoosh capability. Removing it makes the abstraction a cage.

**How to avoid:**
- `update_swoosh/2 :: (Mailglass.Message.t(), (Swoosh.Email.t() -> Swoosh.Email.t())) -> Mailglass.Message.t()` is a **named, documented, stable public API** in `api_stability.md` v2. Never remove it from the freeze list.
- The migration guide (`guides/migration-v0-2.md`) MUST include a section "Accessing raw Swoosh features" that shows `update_swoosh/2` usage explicitly.
- Doctest: `msg |> update_swoosh(fn e -> Swoosh.Email.header(e, "X-Custom", "value") end)` — verifying the escape hatch works and is tested.
- The codemod task must NOT rewrite `update_swoosh/2` call sites — they are already using the stable interface.

**Warning signs:**
- `update_swoosh/2` is absent from `api_stability.md` v2.
- The migration guide has no section on Swoosh-native features.
- A PR removes `update_swoosh/2` with the commit message "cleanup — internal only."

---

### API-04: Doctest Contracts Not Updated After v0.2 Redesign

**ID:** API-04
**Severity:** MEDIUM
**Phase:** Phase 9 (API Redesign)

**What goes wrong:**
The v0.2 Mailable API replaces `Swoosh.Email.t()` return types with `Mailglass.Message.t()`. `@spec` annotations are updated. But `@doc` examples in the guide pages still show `%Swoosh.Email{to: [{"Alice", "alice@example.com"}]}` return values. Adopters copy the guide example, their code type-checks fine (they're on Elixir 1.18 where the type checker catches this), but the guides are lies. Adopters file confusion issues; trust in the documentation degrades.

**Why it happens:**
Doctests in module files are run by `mix test`, but code blocks in `.livemd` guide pages or `guides/*.md` files are not automatically tested unless they're hooked up explicitly. Authors update the module-level doctests (which CI catches) but forget the narrative guides.

**How to avoid:**
- All fenced code blocks in `guides/*.md` that show calling mailglass APIs must use the `elixir` language tag and be tested by a dedicated `DocContractTest` module that runs them via `ExUnit.DocTest.doctest_file/1` (or the equivalent `Code.compile_string` harness from v0.1 TEST-05).
- CI gate: `mix test --only doc_contract` fails if any guide code block produces an error or the wrong output shape.
- After the API redesign, a pass through all guide files replacing `%Swoosh.Email{}` with `%Mailglass.Message{}` return values must be a checklist item in Phase 9's plan.

**Warning signs:**
- `guides/getting-started.md` still references `%Swoosh.Email{}` after v0.2 ships.
- `mix test --only doc_contract` is not a named alias in `.github/workflows/ci.yml`.
- A guide shows a function that no longer exists (e.g., `Mailglass.Mailable.build_email/2`).

---

### UNSUB-01: List-Unsubscribe Header URL Exceeds RFC 5322 998-Octet Line Limit

**ID:** UNSUB-01
**Severity:** CRITICAL
**Phase:** Phase 10 (RFC 8058 Unsubscribe)

**What goes wrong:**
The generated `List-Unsubscribe: <https://app.example.com/unsubscribe/<phoenix-token>>` URL is 1,020 characters because the tenant ID is a UUID, the signed token includes full metadata, and the base URL is long. RFC 5322 §2.1.1 limits header lines to 998 octets (excluding CRLF). Some MTA implementations reject the message outright rather than folding the header. Adopters discover this only when bulk senders fail silently against certain receiving MTAs.

**Why it happens:**
`Phoenix.Token.sign/4` produces a token whose length grows with the payload size. Phoenix tokens are not length-bounded. The URL is assembled by string concatenation without any length check.

**How to avoid:**
- The `Mailglass.Compliance.unsubscribe_url/2` function MUST assert `byte_size(url) <= 900` (conservative limit below 998 to leave room for `List-Unsubscribe: <>` wrapper overhead). If the assertion fails, raise a `Mailglass.ComplianceError` with a message that states the URL length and the RFC limit.
- Token payload MUST be minimal: only `{delivery_id: UUID, salt_version: integer}`. Never embed the email address, tenant name, or full metadata in the token. The controller resolves metadata from the delivery record using `delivery_id`.
- Property test (StreamData): generate tenants with long UUIDs and mailables with long module names, assert `unsubscribe_url/2` always returns a URL under 900 bytes.

**Warning signs:**
- Token payload includes `email` or `tenant_name` fields.
- URL generated for a staging environment with a long hostname is >900 bytes.
- No assertion or test covers URL byte length.

---

### UNSUB-02: `List-Unsubscribe-Post` Omitted on `:bulk` Stream — Gmail/Yahoo Compliance Failure

**ID:** UNSUB-02
**Severity:** CRITICAL
**Phase:** Phase 10 (RFC 8058 Unsubscribe)

**What goes wrong:**
`List-Unsubscribe: <https://...>` is injected correctly on `:bulk` stream messages. But `List-Unsubscribe-Post: List-Unsubscribe=One-Click` is accidentally omitted (maybe it's added in a separate step that's skipped, or the header name has a typo). Gmail's bulk-sender enforcement (mandatory since Feb 2024, permanent 550 rejection after November 2025) requires BOTH headers. Adopters send months of `:bulk` mail without noticing deliverability degrading until reputation damage compounds.

**Why it happens:**
The two headers are specified in two different RFCs (RFC 2369 + RFC 8058). Implementations that add them separately — rather than atomically — risk the second being missing. A typo (`List-Unsubscribe-Post:` vs `List-Unsubscribe-Post :`) is also invisible in Swoosh header maps.

**How to avoid:**
- `Mailglass.Compliance.inject_unsubscribe_headers/2` is a single function that atomically sets BOTH headers and is the ONLY path to setting either. It is impossible to set one without the other.
- Custom Credo check `RequireAtomicUnsubscribeHeaders` flags any call to `Swoosh.Email.header/3` (or `Mailglass.Message.header/3`) where the header name is `"List-Unsubscribe"` or `"List-Unsubscribe-Post"` — both must always go through `inject_unsubscribe_headers/2`.
- Integration test: build a `:bulk` message, send through the full pipeline, assert BOTH `List-Unsubscribe` and `List-Unsubscribe-Post: List-Unsubscribe=One-Click` are present in the final `Swoosh.Email.headers` map.
- Spelling test: assert the exact string `"List-Unsubscribe-Post"` and value `"List-Unsubscribe=One-Click"` (RFC-mandated exact strings) in the header map.

**Warning signs:**
- A test for `:bulk` stream messages checks only `List-Unsubscribe` presence, not `List-Unsubscribe-Post`.
- Any call to `Swoosh.Email.header(email, "List-Unsubscribe", ...)` outside `Mailglass.Compliance`.
- The Credo check `RequireAtomicUnsubscribeHeaders` is not in the Credo config.

---

### UNSUB-03: Token Signed With Rotated-Out Salt Breaks In-Flight Unsubscribe Links

**ID:** UNSUB-03
**Severity:** HIGH
**Phase:** Phase 10 (RFC 8058 Unsubscribe)

**What goes wrong:**
`Phoenix.Token.sign/4` is called with a configured salt (e.g., `"mailglass_unsub_v1"`). An operator rotates the salt to `"mailglass_unsub_v2"`. All unsubscribe links from emails sent before the rotation are now invalid — `Phoenix.Token.verify/4` returns `{:error, :invalid}`. Users click "unsubscribe," get a 400 error, and remain subscribed. They file spam reports instead. The rotation window problem is exactly the same as JWT key rotation but less understood in the Phoenix ecosystem.

**Why it happens:**
Salt rotation is treated as a config-only change, with no thought given to tokens already embedded in delivered emails. Emails have long TTLs (some users open mail days or weeks later). A 24-hour rotation window is insufficient.

**How to avoid:**
- Support MULTIPLE valid salts simultaneously. Config: `unsub_salts: ["mailglass_unsub_v2", "mailglass_unsub_v1"]`. Sign with `List.first/1`. Verify by trying each salt in order, returning success on the first match.
- A `Mailglass.Compliance.UnsubscribeToken` module wraps this multi-salt logic. It MUST NOT be possible to configure fewer than 2 salts (NimbleOptions validates minimum length 2) during any rotation.
- Document a minimum rotation window: keep the old salt in the list for the `max_age` token lifetime (default: 30 days). The CHANGELOG and upgrade guide MUST mention this.
- Property test: sign a token with salt index 0, remove it from the front, verify still works with remaining salts.

**Warning signs:**
- `unsub_salts` config is a single string, not a list.
- No test covers token verification with a rotated salt.
- The rotation guide says "just change the salt in config."

---

### UNSUB-04: One-Click POST Endpoint Slow Response Causes Provider Retries — Duplicate `:unsubscribed` Events

**ID:** UNSUB-04
**Severity:** HIGH
**Phase:** Phase 10 (RFC 8058 Unsubscribe)

**What goes wrong:**
Gmail's one-click unsubscribe POST times out after 5 seconds. The mailglass unsubscribe controller accepts the POST, starts writing to the database (suppression insert + event append), but the DB is under load and the transaction takes 6 seconds. Gmail retries. Two identical POSTs are now in flight. Both pass token verification. The first transaction commits. The second transaction commits a duplicate event row (if idempotency is on delivery_id only, not on the request itself). The event ledger now has two `:unsubscribed` events for one user action.

**Why it happens:**
The one-click handler is implemented as a synchronous DB write inside a Phoenix controller action. No idempotency key is derived from the POST itself. The `mailglass_events` idempotency index guards webhook replays (keyed on `provider:event_id`) but not on direct user-action retries.

**How to avoid:**
- The unsubscribe controller MUST respond 200 OK immediately (before any DB write), then process the suppression asynchronously via `Task.Supervisor` or an Oban job. RFC 8058 §2 only requires the response to acknowledge receipt, not confirm persistence.
- The idempotency key for unsubscribe events MUST include the token itself (or a hash of it), not just the delivery_id: `"unsub:#{Base.encode16(:crypto.hash(:sha256, token))}"`. This makes concurrent retries idempotent.
- Integration test: simulate two concurrent POSTs to the unsubscribe endpoint with the same token, assert exactly one event row is inserted.

**Warning signs:**
- The unsubscribe controller action has a DB write before `conn |> send_resp(200, "")`.
- The idempotency key for the unsubscribe event is only `"unsub:#{delivery_id}"`.
- No test exercises concurrent POST to the endpoint.

---

### UNSUB-05: `List-Unsubscribe` Header Omitted From DKIM `h=` — Tampering Possible

**ID:** UNSUB-05
**Severity:** HIGH
**Phase:** Phase 10 (RFC 8058 Unsubscribe)

**What goes wrong:**
DKIM is configured with `h=from:to:subject:date:message-id`. `List-Unsubscribe` and `List-Unsubscribe-Post` are not in the `h=` tag. A man-in-the-middle or compromised ESP can replace the unsubscribe URL without breaking DKIM validation. The receiver sees a valid DKIM signature but the unsubscribe link now points to an attacker-controlled endpoint.

**Why it happens:**
DKIM header selection is typically driven by the ESP's dashboard or a static config list. Authors don't know that RFC 6376 §5.4.1 recommends signing all mutable headers — and `List-Unsubscribe` is exactly the kind of mutable header that matters.

**How to avoid:**
- The documentation guide `guides/dkim-setup.md` MUST include a required `h=` tag template that includes `list-unsubscribe:list-unsubscribe-post`. It MUST be marked as a `> **Required**` admonition, not optional.
- `mix mailglass.gen.unsubscribe` (the generator task) generates code with a comment: `# Ensure list-unsubscribe is in your DKIM h= tag — see guides/dkim-setup.md`.
- A `mix mail.doctor` check (v0.5 scope, but the generator hint lands in v0.2) warns if the configured DKIM header list omits `list-unsubscribe`.
- Integration test assertion: after building a `:bulk` message through the pipeline, verify the returned `Mailglass.Message` has a metadata field `required_dkim_headers` that includes `"list-unsubscribe"` and `"list-unsubscribe-post"`.

**Warning signs:**
- `guides/dkim-setup.md` example `h=` tag omits `list-unsubscribe`.
- `mix mailglass.gen.unsubscribe` output has no comment about DKIM.

---

### UNSUB-06: Unsubscribe Route Collides With Adopter App's Own `/unsubscribe` Route

**ID:** UNSUB-06
**Severity:** MEDIUM
**Phase:** Phase 10 (RFC 8058 Unsubscribe)

**What goes wrong:**
`mix mailglass.gen.unsubscribe` generates a controller and adds `get "/unsubscribe/:token", MailglassUnsubController, :unsubscribe` to the router. The adopter's app already has `get "/unsubscribe", MyApp.PreferencesController, :index`. Phoenix router matches routes greedily; the mailglass route may shadow the adopter's route depending on ordering. Worse: the adopter follows the generator output literally and introduces the conflict without noticing it compiles fine — only a runtime 404 or wrong-controller response surfaces the bug.

**Why it happens:**
Generator tasks that emit raw router code cannot know what routes already exist in the adopter's router. Hard-coding a path like `/unsubscribe` is a land-grab.

**How to avoid:**
- The generator MUST emit routes under a configurable scope prefix, defaulting to `/mailglass/unsubscribe/:token` (not `/unsubscribe/:token`).
- The generator output includes a comment: `# Mount under any path — configure :mailglass_unsubscribe_path in config.exs to change the default.`
- The generator reads the adopter's existing `router.ex` via Sourceror, checks for any existing routes with the same path pattern, and warns if a collision is detected: `Warning: existing route at /unsubscribe may conflict with the generated route.`
- Integration test: generate against a fixture router that already has `/unsubscribe`, assert the warning is printed.

**Warning signs:**
- Generator outputs `get "/unsubscribe/:token"` without a scope or configurable prefix.
- No collision-detection logic in the generator.
- The generator documentation says "add this to your router" without mentioning potential conflicts.

---

### SUPP-01: Auto-Suppression `ON CONFLICT DO NOTHING` Inside Multi — Replay Creates Phantom Events

**ID:** SUPP-01
**Severity:** CRITICAL
**Phase:** Phase 11 (Auto-Suppression)

**What goes wrong:**
The webhook ingest `Ecto.Multi` looks like: `Multi.insert(:suppression, suppression_changeset, on_conflict: :nothing)` followed by `Multi.insert(:event, event_changeset)`. On replay (provider retries the same webhook), the event row hits the UNIQUE idempotency index and the whole Multi rolls back — returning `{:ok, :replayed}` as intended. But if the suppression insert fires first with `on_conflict: :nothing` and the event insert is second, a replayed webhook can insert the suppression (no conflict) without inserting the event (conflict rolls back), leaving a suppression row with no corresponding event. The audit ledger is now inconsistent — suppression exists but no event explains why.

**Why it happens:**
Developers put the suppression insert before the event insert in the Multi chain. The event is the replay-idempotency anchor; it must come first so a conflict on the event aborts the entire Multi before any side effects occur.

**How to avoid:**
- **Invariant:** The event row (`Multi.insert(:event, ...)`) with its idempotency key MUST be the first step in any webhook-ingest Multi. All other side effects (suppression insert, delivery status update) must come AFTER the event step.
- Custom Credo check `MultiEventFirstInWebhookIngest`: any `Ecto.Multi` expression in a webhook handler module that does not have `:event` as its first named step is flagged as an error.
- Property test (StreamData): run HOOK-07's 1000-replay convergence test for the auto-suppression flow. Assert: after N replays, exactly 1 event row and at most 1 suppression row, and the suppression row always has a corresponding event row.

**Warning signs:**
- `Ecto.Multi.insert(:suppression, ...)` appears before `Ecto.Multi.insert(:event, ...)` in any webhook handler.
- The 1000-replay convergence test is scoped only to the event table, not the suppression table.
- A suppression row exists with no corresponding `mailglass_events` row for the same delivery.

---

### SUPP-02: Soft-Bounce Escalation Evaluated Synchronously Per Webhook — DB Load Amplification

**ID:** SUPP-02
**Severity:** HIGH
**Phase:** Phase 11 (Auto-Suppression)

**What goes wrong:**
Every incoming `:deferred` webhook event triggers a synchronous DB query: `SELECT COUNT(*) FROM mailglass_events WHERE delivery_id IN (SELECT id FROM mailglass_deliveries WHERE recipient = $1) AND type = 'deferred' AND occurred_at > now() - interval '7 days'`. Under load — e.g., a provider sending 1,000 webhook events in a burst — this produces 1,000 concurrent count queries against the same tables. Postgres connection pool saturates. Other webhook processing stalls. The rate-limit on the provider side causes retries which amplify the load further.

**Why it happens:**
The escalation check feels natural as an in-request synchronous step (the data is fresh, the result is needed to decide suppression). Authors don't consider webhook burst patterns.

**How to avoid:**
- Soft-bounce escalation MUST be an asynchronous step: the webhook ingest Multi records the event, then enqueues an Oban job (or `Task.Supervisor.async_nolink` if Oban absent) to evaluate the escalation window. The job runs at lower concurrency than the webhook ingest pipeline.
- Fallback (no Oban): escalation runs in a `Task.Supervisor` worker with a default max concurrency of 5. Document this as a performance consideration in the Oban optional-dep guide.
- The escalation query MUST have a covering index: `CREATE INDEX mailglass_events_soft_bounce_idx ON mailglass_events (recipient, type, occurred_at) WHERE type = 'deferred'`. The migration that adds auto-suppression MUST include this index.
- Load test (not CI-blocking, in the advisory cron): simulate 1,000 concurrent `:deferred` webhook events, assert P95 ingest latency < 50ms.

**Warning signs:**
- The soft-bounce escalation function is called synchronously inside the webhook plug handler.
- No index exists on `(recipient, type, occurred_at)` in `mailglass_events`.
- The Oban worker for escalation has the same queue and concurrency as the webhook ingest worker.

---

### SUPP-03: Soft-Bounce Window Resets on Every Event — Fixed vs Sliding Window Ambiguity

**ID:** SUPP-03
**Severity:** HIGH
**Phase:** Phase 11 (Auto-Suppression)

**What goes wrong:**
The soft-bounce escalation policy is documented as "5 soft bounces in 7 days." The implementation uses a sliding 7-day window anchored to `now()`. But an adopter reads the docs and assumes a fixed window (Mon–Sun), configures a daily Oban job to "reset" the counter at midnight, and ends up with a different escalation behavior than what mailglass computes. Or: the implementation resets the window start on every new soft bounce ("last 7 days from most recent bounce"), making it impossible to escalate an address that bounces weekly — one bounce every 8 days never triggers escalation even after months.

**Why it happens:**
"Sliding window" is ambiguous in English. The three common implementations (fixed calendar window, sliding anchor-to-now, sliding anchor-to-last-event) produce dramatically different escalation behavior but look identical in the docs.

**How to avoid:**
- Document the EXACT semantics in one sentence in `api_stability.md`: "Escalation triggers when COUNT(soft_bounce events WHERE occurred_at > now() - interval '7 days') >= threshold, evaluated at the time of each new soft_bounce event." This is anchor-to-now, not anchor-to-last-event.
- Unit test: insert 4 soft bounce events across 8 days (alternating recent + old), verify the count query returns the correct in-window count.
- Property test: generate random event timestamps and threshold values, assert the escalation decision matches the reference formula.
- The `Mailglass.AutoSuppression.should_escalate?/2` function is pure (takes events list + config), enabling deterministic unit testing without DB queries.

**Warning signs:**
- The escalation check is a raw SQL query, not a call to a pure function with a testable interface.
- The docs use the phrase "in the last 7 days" without specifying whether "last" means from now or from the most recent event.
- No unit test isolates the escalation decision from the DB query.

---

### SUPP-04: Auto-Suppression on `:complained` Without Correct GDPR Interpretation

**ID:** SUPP-04
**Severity:** CRITICAL
**Phase:** Phase 11 (Auto-Suppression)

**What goes wrong:**
An adopter reads the auto-suppression docs and tries to build a "GDPR right-to-be-forgotten" flow that removes suppressions after a data-deletion request. They reason: "the user complained, they're suppressed; if we delete their data, we should remove the suppression too." They implement a delete on `mailglass_suppressions` for `:complained` entries. Now the user, whose data was deleted (including their complaint record), can be re-subscribed accidentally and receive mail again — which is the opposite of GDPR intent AND a CAN-SPAM violation.

OR: more subtly, the mailglass docs don't emphasize strongly enough that `:complained` suppression MUST be permanent and non-reversible, leading an adopter to build an admin UI that allows manual unsuppression of complained addresses.

**Why it happens:**
`:complained` and `:unsubscribed` look symmetric in the suppression store. Developers treat them the same way. The legal asymmetry (complaint = permanent; unsubscribe = can be re-subscribed with fresh consent) is not obvious from data structure alone.

**How to avoid:**
- `mailglass_suppressions.reason` = `:complained` entries MUST have `expires_at = NULL` (no expiry) enforced by a Postgres check constraint: `CHECK (reason != 'complained' OR expires_at IS NULL)`. The migration includes this constraint.
- `Mailglass.Suppression.remove/2` (used by the admin UI) MUST refuse to delete a `:complained` suppression, returning `{:error, %Mailglass.Error{type: :permanent_suppression}}`. The admin LiveView must show a prominent warning on any `:complained` row.
- The `GDPR right-to-be-forgotten` guide section explicitly states: "Complaint suppressions survive data deletion. If you delete a user's personal data, copy the suppressed address hash (not the address itself) to a separate blocklist before deletion, so future re-registration with the same address remains suppressed."
- Custom Credo check: flag any `Mailglass.Repo.delete/1` on a `Suppression` changeset that doesn't pass through `Mailglass.Suppression.remove/2` (the enforcing wrapper).

**Warning signs:**
- `mailglass_suppressions` has no check constraint on `expires_at` for `:complained` reason.
- `Mailglass.Suppression.remove/2` accepts any reason without special-casing `:complained`.
- The docs section on GDPR says "remove suppressions as appropriate" without distinguishing complaint from unsubscribe.

---

### SUPP-05: `mix mailglass.suppressions.resync` Projects Events Across All Tenants Without Scope — Cross-Tenant Leak

**ID:** SUPP-05
**Severity:** CRITICAL
**Phase:** Phase 11 (Auto-Suppression)

**What goes wrong:**
`mix mailglass.suppressions.resync` rebuilds the suppression table from the event ledger. The naive implementation queries `SELECT * FROM mailglass_events WHERE type IN ('bounced', 'complained', 'unsubscribed')` without a `WHERE tenant_id = ?` clause, then inserts suppression rows for all tenants at once. In a SaaS multi-tenant app, this means Tenant A's bounced recipient email is now visible (and suppressed) in Tenant B's context. This is TENANT-03 violation — cross-tenant data leak via admin operation.

**Why it happens:**
Mix tasks run as privileged admin operations; developers assume "admin sees everything" and omit tenant scoping. Mix tasks use `Repo` directly, bypassing `Mailglass.Tenancy.scope/2`, which normally enforces tenant isolation.

**How to avoid:**
- `mix mailglass.suppressions.resync` MUST accept a `--tenant-id` flag and process exactly one tenant per invocation. Running without `--tenant-id` raises a usage error with instructions.
- Alternatively: if a `--all-tenants` flag is explicitly passed, the task processes tenants in sequence (not parallel), wrapping each in a separate transaction, with per-tenant telemetry.
- The task's Repo queries MUST go through `Mailglass.Tenancy.scope/2` even though they're in a Mix task context. The task accepts the repo module and tenant_id as explicit arguments, never reads tenant context from the process dictionary.
- Integration test: run `resync` against a fixture DB with 2 tenants, assert that tenant A's suppressions have no rows where `tenant_id = tenant_b_id`.

**Warning signs:**
- `mix mailglass.suppressions.resync` has no `--tenant-id` flag.
- The task queries `mailglass_events` without a `WHERE tenant_id = ?` clause.
- The `NoUnscopedTenantQueryInLib` Credo check doesn't cover Mix task modules.

---

### STREAM-01: Adopter Sets `:transactional` Stream on a Marketing-Adjacent Email

**ID:** STREAM-01
**Severity:** HIGH
**Phase:** Phase 12 (Stream Policy Enforcement)

**What goes wrong:**
An adopter sends a "you haven't logged in for 30 days" re-engagement email. They classify it as `stream: :transactional` because it's triggered by user behavior (not a campaign blast). CAN-SPAM and GDPR define "commercial email" by content, not trigger mechanism. A re-engagement email promoting the product is commercial. `:transactional` streams skip List-Unsubscribe header injection and are excluded from suppression checks for `:unsubscribed` reason. The adopter is now sending commercial email without unsubscribe headers to users who have previously unsubscribed — a CAN-SPAM violation.

**Why it happens:**
The `:transactional` / `:operational` / `:bulk` distinction maps poorly to the legal definitions of "transactional," "commercial," and "marketing." Adopters use the mailglass stream names as their mental model for legal compliance, rather than as a technical routing distinction.

**How to avoid:**
- `stream: :transactional` documentation MUST include a callout box: "`:transactional` means the email is individually triggered in response to a user-initiated action (account creation, password reset, purchase confirmation). It does NOT exempt you from CAN-SPAM or GDPR if the email promotes your product. When in doubt, use `:operational` and include an unsubscribe option."
- The `mix mailglass.gen.unsubscribe` generator defaults to injecting headers on `:operational` AND `:bulk` — never `:transactional`.
- A runtime warning (not error) is emitted via `Logger.warning/2` when `stream: :transactional` is set on a mailable whose module name contains `re_engagement`, `win_back`, `reactivate`, `promo`, or `marketing` (heuristic; documented as a hint, not enforcement).

**Warning signs:**
- A mailable named `ReEngagementMailer` has `stream: :transactional`.
- The stream policy docs have no definition of what "transactional" means legally.
- No Logger warning is emitted for the heuristic pattern match.

---

### STREAM-02: Compile-Time Stream Check Misses Runtime-Set Stream — Policy Bypass

**ID:** STREAM-02
**Severity:** HIGH
**Phase:** Phase 12 (Stream Policy Enforcement)

**What goes wrong:**
The compile-time stream check (Credo) enforces `stream: :bulk` on mailables that use `inject_unsubscribe_headers`. But an adopter overrides the stream at call time: `Mailglass.deliver(MyMailer.newsletter(user), stream: :transactional)`. The override bypasses the compile-time check because Credo can't see runtime values. The newsletter is sent as `:transactional` — no List-Unsubscribe headers, no suppression check for unsubscribed users.

**Why it happens:**
Two enforcement layers (compile-time Credo + runtime `Stream.policy_check/1`) must be consistent. The compile-time check catches module-level declarations. The runtime check must catch call-site overrides. If the runtime check is absent or incomplete, the compile-time check is a false sense of security.

**How to avoid:**
- `Mailglass.Outbound` MUST evaluate `Mailglass.Stream.policy_check/2` at runtime for every deliver call, including when stream is overridden at the call site. The check validates: if `stream` is changed to `:transactional`, verify the message has no tracking opts and no unsubscribe headers set (if it did, that means they were injected at module level for a `:bulk` mailable and the runtime override is inconsistent).
- Runtime policy check returns `{:error, %StreamPolicyError{}}` with a message that names the specific violation: "Cannot override stream to :transactional on a message that has List-Unsubscribe headers. Remove the headers or keep stream as :bulk."
- Custom Credo check `NoRuntimeStreamOverride` warns on any `deliver(msg, stream: :transactional)` call-site pattern where the mailable module is identifiable at AST level as having a `:bulk` declaration.

**Warning signs:**
- `Mailglass.Outbound.send/2` accepts a `:stream` override option with no runtime validation.
- No test exercises the case where `deliver` is called with `stream: :transactional` on a `:bulk` mailable.
- The runtime `policy_check/2` function only checks the module-level stream, not the overridden value.

---

### STREAM-03: `%StreamPolicyError{}` Message Doesn't Say Why

**ID:** STREAM-03
**Severity:** MEDIUM
**Phase:** Phase 12 (Stream Policy Enforcement)

**What goes wrong:**
`Mailglass.deliver(newsletter, stream: :transactional)` returns `{:error, %StreamPolicyError{message: "Stream policy violation"}}`. The adopter has no idea whether the problem is the stream override, the List-Unsubscribe header presence, the tracking opt, or the suppression check. They spend an hour reading source code. Error-driven debugging loop ensues.

**Why it happens:**
Stream policy violations are caught in a single `policy_check/2` function that returns a generic error. The specific reason for failure (which policy, which field, which stream) is not threaded through the error struct.

**How to avoid:**
- `%Mailglass.Error{type: :stream_policy}` MUST include a `:detail` field (a map) with at least: `%{rule: atom, stream: atom, field: atom | nil, suggestion: String.t()}`. Example: `%{rule: :no_unsub_headers_on_transactional, stream: :transactional, field: :list_unsubscribe, suggestion: "Change stream to :bulk or remove unsubscribe headers"}`.
- The error's `Exception.message/1` implementation must format this into a readable sentence: "Stream policy violation: Cannot set List-Unsubscribe on a :transactional message. Suggestion: Change stream to :bulk or remove the unsubscribe headers."
- Every stream policy rule (there are ~5 in v0.2) has its own named atom in the `:rule` field, documented in `api_stability.md`.

**Warning signs:**
- `%StreamPolicyError{}` has only a `:message` string field, no structured `:detail`.
- All stream policy violations produce the same error atom (no rule differentiation).
- The error message contains "violation" without a specific explanation.

---

### REL-01: Tag-Push Trigger Fires on Workflow Rerun — Double-Publish to Hex

**ID:** REL-01
**Severity:** CRITICAL
**Phase:** Phase 8 (Release-Engineering Hardening)

**What goes wrong:**
`publish-hex.yml` is triggered on `push` with a `tags: ['v*']` filter. GitHub Actions "Re-run all jobs" on an existing tag push re-triggers the workflow. A transient CI failure during the v0.2.0 publish run causes someone to rerun the workflow. `mix hex.publish` runs a second time for the same version. Hex.pm rejects the duplicate (returns 422), but the workflow is now in an ambiguous state — the PR shows failure even though the package is published. Future maintainers don't know if the package is corrupted. Worse: if the first run published partially (some packages but not all siblings), the rerun may publish the remaining siblings inconsistently.

**Why it happens:**
The v0.1.1 ship surfaced this bug (tracked as TODO `2026-04-26-publish-hex-workflow-run-gate-cant-detect-tag-creation.md`). The `on: push: tags` trigger fires on both initial push AND workflow rerun.

**How to avoid:**
- Switch `publish-hex.yml` trigger from `on: push: tags: ['v*']` to `on: release: types: [published]`. GitHub Release creation is idempotent (cannot create the same release twice), so workflow reruns don't re-trigger the publish.
- Add a pre-publish step: `mix hex.info mailglass $VERSION` — if it returns 0 (version already published), exit 0 immediately with a log message "Version already published, skipping." This is the idempotency guard for any remaining edge cases.
- Integration test for the workflow: use `act` (or document manual test procedure) to verify that rerrunning the release workflow on an already-published version exits 0 without publishing again.

**Warning signs:**
- `publish-hex.yml` uses `on: push: tags:` trigger (not `on: release:`).
- No `mix hex.info` pre-check before `mix hex.publish` in the workflow.
- The workflow has no early-exit for "already published."

---

### REL-02: Dialyzer `--halt-exit-status` Blocks v0.2 Release With ~230 Residual Type Findings

**ID:** REL-02
**Severity:** HIGH
**Phase:** Phase 8 (Release-Engineering Hardening)

**What goes wrong:**
Enabling `Dialyzer --halt-exit-status` (currently advisory) reveals ~230 type warnings carried over from v0.1. Treating all 230 as blocking would stall the v0.2 release for weeks. Ignoring them entirely defeats the purpose of `--halt-exit-status`. The team needs a triage strategy that doesn't block the release but also doesn't silently paper over real bugs.

**Why it happens:**
Dialyzer warns prolifically on Elixir 1.18's new type inference for things that are not real bugs (e.g., `success_typing` warnings on functions that match structs via `__struct__` comparison, documented in D-06's v0.1 outcome). The PLT is also not stable across OTP 27 minor versions.

**How to avoid:**
- Explicit triage budget: Phase 8 allocates time for a full Dialyzer pass. Each warning is triaged to one of: (a) real bug → fix before release, (b) known false positive → add to `.dialyzer_ignore.exs`, (c) structural limitation of Dialyzer on Elixir 1.18 → document in `MAINTAINING.md` with the specific pattern and add to ignore file.
- The ignore file MUST be annotated: each entry has a comment explaining why the ignore is justified. CI rejects entries without comments (a script checks the file format).
- The CI Dialyzer lane runs with `--halt-exit-status` and the ignore file. A passing CI means: either zero warnings, or all warnings are explicitly justified.
- Target: fewer than 15 entries in `.dialyzer_ignore.exs` after triage. If more than 15 are needed, flag for a Dialyzer-specific research phase.

**Warning signs:**
- `.dialyzer_ignore.exs` exists but has no comments on any entry.
- More than 15 entries in `.dialyzer_ignore.exs` after Phase 8.
- The Dialyzer CI lane still runs without `--halt-exit-status` (advisory only) after Phase 8 ships.

---

### CROSS-01: One-Multi Chain Grows to 5+ Steps — Transaction Time + Readability Concerns

**ID:** CROSS-01
**Severity:** MEDIUM
**Phase:** Phase 11 (Auto-Suppression) / Phase 12 (Stream Policy)

**What goes wrong:**
The webhook ingest Multi starts as: `event → delivery_update → suppression`. v0.2 adds: `stream_policy_update → feedback_id_refresh → rate_limit_reset`. The Multi now has 6 steps and holds a Postgres transaction open for the duration of all 6. Under load, long transactions increase lock contention, WAL amplification, and connection pool pressure. Additionally, when the Multi fails at step 4, the error returned is `{:error, :stream_policy_update, changeset, %{event: ..., delivery_update: ..., suppression: ...}}` — debugging the failure requires understanding the accumulated state.

**Why it happens:**
Ecto.Multi composes beautifully; it's easy to add steps. The transaction boundary being "whatever is in the Multi" creates invisible performance coupling between logically separate operations.

**How to avoid:**
- Enforce a maximum of 4 named steps per `Ecto.Multi` pipeline in the webhook ingest flow. Any operation that doesn't require transactional consistency with the event insert must be extracted to an async Oban job or a `Task.Supervisor` worker launched after the Multi commits.
- Document the 4-step limit in `CONTRIBUTING.md` as an architectural constraint, with the rationale (transaction time, WAL pressure, debugging complexity).
- Credo check `BoundedMultiSteps` (new in v0.2): flag any `Ecto.Multi` construction in a webhook handler module that chains more than 4 `Multi.*` calls.

**Warning signs:**
- Any webhook handler module has an `Ecto.Multi` chain with more than 4 `Multi.*` calls.
- A slow-query log shows transactions from `mailglass_events` inserts averaging >100ms.
- An error from a Multi step mentions accumulated state from 5+ prior steps.

---

### CROSS-02: Dep Conflict Matrix — Stale Oban Pro / Phoenix.PubSub / Postgrex on Adopter Upgrade

**ID:** CROSS-02
**Severity:** HIGH
**Phase:** Phase 8 (Release-Engineering Hardening) / Phase 13 (Release Ceremony)

**What goes wrong:**
An adopter upgrades from mailglass v0.1 to v0.2. mailglass v0.2 requires Ecto 3.13+ (for a new feature). The adopter is on Ecto 3.11 with Oban Pro 3.x (which pins Ecto `~> 3.11`). The dependency conflict is unresolvable without upgrading Oban Pro, which requires a separate Oban Pro license key renewal. The adopter is blocked: they can't use mailglass v0.2 until Oban Pro releases a compatible version. This is not mailglass's fault, but the migration guide must warn about it.

**Why it happens:**
mailglass is a framework dep (not a leaf dep). Anything it requires propagates transitively. Version floor bumps (Ecto, Phoenix, Postgrex) can create conflicts with other ecosystem deps that lag behind the bleeding edge.

**How to avoid:**
- The v0.2 migration guide MUST include a "Known dep conflicts" table with tested-against versions: Oban CE/Pro, Phoenix.PubSub, Postgrex, Ecto SQL, Phoenix LiveView. For each, note the minimum version compatible with mailglass v0.2.
- Phase 8 includes a CI lane that installs mailglass against the minimum declared dep versions (not just the latest). If the minimum floor is incompatible, the floor must be lowered or documented.
- `mix.exs` dependency version specs MUST use `~>` with a floor, not `>=`. Example: `{:ecto_sql, "~> 3.12"}` (not `"~> 3.0"` and not `"== 3.13.0"`). This ensures adopters can satisfy the spec without pinning to an exact version.

**Warning signs:**
- `mix.exs` has `{:ecto_sql, ">= 3.0.0"}` (too loose, version-drift risk) or `{:ecto_sql, "== 3.13.0"}` (too tight, upgrade-blocking).
- The migration guide has no "Known dep conflicts" section.
- The minimum-dep CI lane is absent from the workflow matrix.

---

## Phase-to-Pitfall Mapping

| Phase | Pitfalls Addressed |
|-------|--------------------|
| **Phase 8** — Release-Engineering Hardening | REL-01, REL-02, CROSS-02 |
| **Phase 9** — API Redesign + Freeze | API-01, API-02, API-03, API-04 |
| **Phase 10** — RFC 8058 Unsubscribe | UNSUB-01, UNSUB-02, UNSUB-03, UNSUB-04, UNSUB-05, UNSUB-06 |
| **Phase 11** — Auto-Suppression | SUPP-01, SUPP-02, SUPP-03, SUPP-04, SUPP-05, CROSS-01 |
| **Phase 12** — Stream Policy Enforcement | STREAM-01, STREAM-02, STREAM-03, CROSS-01 |
| **Phase 13** — Release Ceremony | CROSS-02 |

---

## Severity Summary

| ID | Name | Severity |
|----|------|----------|
| API-01 | Unintended freeze of internal helper | HIGH |
| API-02 | Codemod silently rewrites ambiguous import site | HIGH |
| API-03 | `update_swoosh/2` removed — escape hatch lost | HIGH |
| API-04 | Doctest contracts not updated after redesign | MEDIUM |
| UNSUB-01 | List-Unsubscribe URL exceeds 998-octet limit | CRITICAL |
| UNSUB-02 | `List-Unsubscribe-Post` omitted on `:bulk` | CRITICAL |
| UNSUB-03 | Token signed with rotated-out salt breaks in-flight links | HIGH |
| UNSUB-04 | One-click POST slow response → provider retries → duplicate events | HIGH |
| UNSUB-05 | `List-Unsubscribe` omitted from DKIM `h=` | HIGH |
| UNSUB-06 | Unsubscribe route collides with adopter route | MEDIUM |
| SUPP-01 | Auto-suppression ON CONFLICT before event — replay phantom rows | CRITICAL |
| SUPP-02 | Soft-bounce escalation synchronous — DB load amplification | HIGH |
| SUPP-03 | Soft-bounce window semantics ambiguous (fixed vs sliding) | HIGH |
| SUPP-04 | Auto-suppression on `:complained` misread as reversible | CRITICAL |
| SUPP-05 | Resync task projects all tenants without scope | CRITICAL |
| STREAM-01 | Adopter uses `:transactional` on commercial email | HIGH |
| STREAM-02 | Compile-time stream check misses runtime override | HIGH |
| STREAM-03 | `%StreamPolicyError{}` message doesn't say why | MEDIUM |
| REL-01 | Tag-push trigger double-publishes to Hex | CRITICAL |
| REL-02 | Dialyzer 230 residual findings block release | HIGH |
| CROSS-01 | Multi chain grows past 5 steps | MEDIUM |
| CROSS-02 | Dep conflict matrix on adopter upgrade | HIGH |

**Totals:** 6 CRITICAL, 12 HIGH, 4 MEDIUM, 0 LOW. All 22 pitfalls are new to v0.2 (no v0.1 duplicates).

---

*v0.2 pitfalls research for: mailglass "Production-Credible Core"*
*Researched: 2026-04-26*
