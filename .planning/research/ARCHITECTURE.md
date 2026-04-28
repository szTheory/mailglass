# Architecture Research — mailglass v0.2

**Domain:** Phoenix-native transactional email framework (subsequent milestone)
**Researched:** 2026-04-26
**Milestone:** v0.2 "Production-Credible Core"
**Confidence:** HIGH — all analysis grounded in exact line references to shipped v0.1 source

---

## 0. Executive Summary

v0.2 adds five feature surfaces on top of a fully shipped v0.1 codebase (~33k LOC, 319 commits, all 84 REQ-IDs satisfied). Every v0.2 change integrates into existing module boundaries without rewriting them. The changes are: (1) a **Mailable API redesign** that hides Swoosh from adopter call sites; (2) a **Stream policy implementation** that replaces the v0.1 no-op seam; (3) **RFC 8058 List-Unsubscribe** added as a first-class compliance layer in core; (4) **auto-suppression** wired directly into the existing webhook ingest Multi; and (5) a **codemod generator** for the one-cycle deprecation path. Build order confirmed and validated below.

---

## 1. Mailable API Redesign — Integration Points

### 1.1 Where `import Swoosh.Email` lives

In `lib/mailglass/mailable.ex`, **line 129**:

```elixir
quote bind_quoted: [opts: opts] do
  @behaviour Mailglass.Mailable
  @before_compile Mailglass.Mailable
  @mailglass_opts opts
  @compile {:no_warn_undefined, Mailglass.Outbound}
  import Swoosh.Email, except: [new: 0]   # ← LINE 129 — target for removal
  import Mailglass.Components
```

This is the only injection site. `import Swoosh.Email` is what causes adopter mailable modules to see Swoosh builder functions (`from/2`, `to/2`, `subject/2`, etc.) unqualified. The v0.1 usage pattern in `test/support/fake_fixtures.ex` and the `mailable_test.exs` shows the current expected call form:

```elixir
new()
|> Mailglass.Message.update_swoosh(fn e ->
     e
     |> Swoosh.Email.from({"Test", "test@example.com"})
     |> Swoosh.Email.to(email)
     |> Swoosh.Email.subject("Welcome")
     |> Swoosh.Email.html_body("<p>Welcome!</p>")
     |> Swoosh.Email.text_body("Welcome!")
   end)
|> Mailglass.Message.put_function(:welcome)
```

Adopters today call `Swoosh.Email.*` INSIDE the `update_swoosh` callback. The `import Swoosh.Email` at line 129 means they can also call unqualified `from/2`, `to/2`, etc. directly in the mailable body — this is the "leakage" the v0.1.2 TODO identifies.

### 1.2 Minimum-invasive BC strategy for `import Swoosh.Email` removal

**Approach:** Keep `import Swoosh.Email` in the macro injection but emit a `@deprecated` module attribute that triggers `:elixir_warnings` on first use. This is not directly supported by Elixir's deprecation mechanism (which targets functions, not imports). The correct approach is:

1. **Remove `import Swoosh.Email, except: [new: 0]` from line 129** of the `__using__/1` quote block.
2. **Add `@compile {:no_warn_undefined, Swoosh.Email}` to the injected quote** so modules that still call unqualified Swoosh functions get a compiler error (undefined function) rather than a silent wrong-call.
3. **Add native field setters to `Mailglass.Message`** — `to/2`, `from/2`, `subject/2`, `html_body/2`, `text_body/2`, `header/3`, `attach/2`, `put_tag/2`, `put_metadata/3` (the last exists already at line 200). These delegate to `%{msg | swoosh_email: Swoosh.Email.xxx(...)}` internally so the inner struct is still the source of truth.
4. **`update_swoosh/2` stays** — it is already documented in `api_stability.md §Message Extensions` as the escape hatch. Retain it, do NOT deprecate it, but demote it from the tutorial path to the "advanced / compatibility" path.
5. **One-cycle BC:** Add a compile-time module attribute `@mailglass_deprecated_swoosh_import true` with a `Logger.warning` emitted at the first `new()` call if a mailable tries to call an undefined Swoosh function. More pragmatically: ship the codemod task (Phase 13 candidate, or end of Phase 9) that rewrites adopter call sites before the import is dropped.

The `import Swoosh.Email` line is the single diff for this change. The `mailable_test.exs` test at line 100 already has a commented note about this import being injected — removing it there validates the unit test surface.

### 1.3 Native field setter design

New functions in `lib/mailglass/message.ex` (each is a NEW addition, none modified):

```elixir
@spec to(t(), {String.t(), String.t()} | [tuple()] | String.t()) :: t()
def to(%__MODULE__{} = msg, recipient) do
  %{msg | swoosh_email: Swoosh.Email.to(msg.swoosh_email, recipient)}
end

@spec from(t(), {String.t(), String.t()} | String.t()) :: t()
def from(%__MODULE__{} = msg, sender) do
  %{msg | swoosh_email: Swoosh.Email.from(msg.swoosh_email, sender)}
end

@spec subject(t(), String.t()) :: t()
def subject(%__MODULE__{} = msg, text) do
  %{msg | swoosh_email: Swoosh.Email.subject(msg.swoosh_email, text)}
end

@spec html_body(t(), String.t()) :: t()
def html_body(%__MODULE__{} = msg, html) do
  %{msg | swoosh_email: Swoosh.Email.html_body(msg.swoosh_email, html)}
end

@spec text_body(t(), String.t()) :: t()
def text_body(%__MODULE__{} = msg, text) do
  %{msg | swoosh_email: Swoosh.Email.text_body(msg.swoosh_email, text)}
end

@spec header(t(), String.t(), String.t()) :: t()
def header(%__MODULE__{} = msg, name, value) do
  %{msg | swoosh_email: Swoosh.Email.header(msg.swoosh_email, name, value)}
end

@spec attach(t(), Swoosh.Attachment.t()) :: t()
def attach(%__MODULE__{} = msg, attachment) do
  %{msg | swoosh_email: Swoosh.Email.attachment(msg.swoosh_email, attachment)}
end

@spec put_tag(t(), String.t()) :: t()
def put_tag(%__MODULE__{} = msg, tag) when is_binary(tag) do
  %{msg | tags: [tag | msg.tags]}
end
```

These allow the v0.2 call pattern:

```elixir
def welcome(user) do
  new()
  |> Message.from({"MyApp", "hello@example.com"})
  |> Message.to(user.email)
  |> Message.subject("Welcome, #{user.name}!")
  |> Message.html_body(render_template(:welcome, user))
  |> Message.put_function(:welcome)
end
```

`update_swoosh/2` (line 163–166 of `message.ex`) is unchanged and is the documented escape hatch when adopters need Swoosh APIs not covered by the field setters (e.g., `Swoosh.Email.cc/2`, `Swoosh.Email.reply_to/2`).

### 1.4 `api_stability.md` — freeze policy syntax for v0.2

`docs/api_stability.md` currently enumerates the v0.1 public surface. For v0.2, the file needs a new section:

```markdown
## §v0.2 Public Surface Freeze

### `Mailglass.Message` — field setters (v0.2, API-01..03)

All functions below are **frozen at v0.2** — their names and signatures will
not change without a major version bump and deprecation cycle:

- `to/2`, `from/2`, `subject/2`, `html_body/2`, `text_body/2`,
  `header/3`, `attach/2`, `put_tag/2` — NEW in v0.2
- `put_function/2`, `put_metadata/3`, `new/2`, `new_from_use/2`,
  `update_swoosh/2` — carried from v0.1 (escape hatch, not default)

### `Mailglass.Mailable` — `use` opts (v0.2, API-04)

`:stream`, `:tracking`, `:from_default`, `:reply_to_default` remain stable.
`:stream` default remains `:transactional`.

`import Swoosh.Email` is **removed** from the injected quote block in v0.2.
One-cycle BC: adopters on `~> 0.1` see compiler errors on first unqualified
Swoosh call; `mix mailglass.upgrade.v0_2` rewrites call sites automatically.

### Freeze enforcement

`@doc since:` annotations mark the version each function was introduced.
`api_stability.md` is the machine-readable contract; `test/mailglass/api_stability_test.exs`
asserts the public surface set matches this document.
```

The freeze policy syntax: functions listed here with `Since: 0.2.0` cannot have their signatures changed without a major version bump. Adopter-visible atoms (error type sets, event type sets) continue to use the `__types__/0` convention already in place.

---

## 2. Stream Policy Integration

### 2.1 Where the no-op seam lives

`lib/mailglass/stream.ex` — the entire file is the seam. It is 47 lines, exported from `Mailglass` boundary. The call sites are:

- `lib/mailglass/outbound.ex` line 291 (`do_send`): `Stream.policy_check(msg)`
- `lib/mailglass/outbound.ex` line 355 (`do_deliver_later`): `Stream.policy_check(msg)`
- `lib/mailglass/outbound.ex` line 509 (`preflight_single` for batch): `Stream.policy_check(msg)`

All three are in the `with` chain at the same position (stage 4 of the preflight pipeline, after `RateLimiter.check`).

The current signature at line 35:

```elixir
@spec policy_check(Message.t()) :: :ok
def policy_check(%Message{} = msg) do
```

The v0.2 signature remains `@spec policy_check(Message.t()) :: :ok | {:error, Mailglass.Error.t()}` — returning `{:error, _}` only when a real policy violation is detected. The three call sites use `with :ok <- Stream.policy_check(msg)` — that pattern naturally handles both the no-op `:ok` and any future `{:error, _}` short-circuit without caller changes.

### 2.2 Stream as compile-time attribute vs runtime Message field

**Decision: BOTH, with a clear ownership split.**

- **Compile-time (on the Mailable):** `:stream` is already a `use Mailglass.Mailable` option. It is stamped onto `%Message{}` in `Message.new_from_use/2` (line 134 of `message.ex`) at message construction time. The NoTrackingOnAuthStream Credo check (Phase 6 LINT-02) reads it via AST. This is the primary enforcement layer.
- **Runtime (on the Message struct):** `%Message{stream: :transactional | :operational | :bulk}` already exists at line 51–61 of `message.ex`. Stream policy violations detected at runtime use this field. The `policy_check/1` function already receives the full `%Message{}` and can read `msg.stream`.

**Violation split:**
- Compile-time violations (LINT): `NoTrackingOnAuthStream` already covers tracking on auth-named functions. Add `StreamPolicyConsistent` for static cases: a Mailable that declares `stream: :bulk` but does NOT opt into List-Unsubscribe at compile time is a lint warning (not an error — this check is advisory since the runtime will auto-inject).
- Runtime violations: `policy_check/1` raises or returns `{:error, %ConfigError{type: :stream_policy_violated}}` for dynamic cases — e.g., a `stream: :transactional` message arriving with tracking-enabled links after rewrite (belt-and-suspenders behind the compile check).

The `stream` field on `%Message{}` is NOT promoted to a separate schema in v0.2 — it stays as a field on `Mailglass.Outbound.Delivery` (already persisted as `TEXT NOT NULL` per the v0.1 DDL) and on `%Message{}`.

### 2.3 Extending `NoTrackingOnAuthStream` to `StreamPolicyConsistent`

The `NoTrackingOnAuthStream` check (`credo_checks/no_tracking_on_auth_stream.ex`) already does the hard work: module traversal, `use Mailglass.Mailable` detection via `module_uses_mailable?/2`, compile-time opts extraction. The pattern for `StreamPolicyConsistent` is identical structure but different predicate:

**Existing check structure (NoTrackingOnAuthStream):**
1. Walk AST with `Macro.traverse/4`
2. Detect modules using `Mailglass.Mailable`
3. For each `def` inside such a module, check function name + opts
4. Emit issue if predicate matches

**New `StreamPolicyConsistent` check** — same structure, different predicates:
- Flag mailable modules that declare `stream: :bulk` but whose `use` opts do NOT include `list_unsubscribe: true` (when that opt exists in v0.2) — advisory warning only
- Flag mailable modules that declare `stream: :transactional` AND have any `tracking: [opens: true]` or `tracking: [clicks: true]` — this overlaps `NoTrackingOnAuthStream` but catches non-auth-named functions too (the existing check only matches auth heuristic names)

The two checks are related but separable. `NoTrackingOnAuthStream` targets auth-named function heuristics; `StreamPolicyConsistent` targets stream-level rules regardless of function name. They can coexist as separate check files in `credo_checks/`.

New file: `credo_checks/stream_policy_consistent.ex`

---

## 3. RFC 8058 List-Unsubscribe — Controller Location Decision

### 3.1 Architecture analysis

The unsubscribe controller needs to:
1. Receive a GET (for one-click preview link) or POST (for RFC 8058 `List-Unsubscribe-Post: List-Unsubscribe=One-Click`)
2. Verify the signed token (via `Phoenix.Token`)
3. Insert a suppression row for the unsubscribing address
4. Return 200 (RFC requires it regardless of display)

The question frames this as core vs admin. The real split is:

| Concern | Core | Admin |
|---------|------|-------|
| Token signing/verification | Core (already needed for headers) | — |
| Suppression insertion | Core | — |
| HTTP request handling (Controller) | No Phoenix.Controller surface today | Has LiveView/Controller surface |
| Adopter availability | Must always be available (CAN-SPAM) | Optional package |

**Verdict: The unsubscribe controller lives in `mailglass` core, in a new module `Mailglass.Compliance.UnsubscribeController`.**

Rationale:
- Adopters who use `mailglass` without `mailglass_admin` (most adopters in headless API contexts, or apps with custom admin UIs) MUST be able to honor RFC 8058 unsubscribes. RFC 8058 is a deliverability requirement, not an admin UI feature.
- v0.5 prod admin will have suppression management UI — but that is a DISPLAY surface. The HANDLING surface (receiving the POST, verifying the token, writing the suppression) must be available before v0.5.
- Phoenix.Controller IS already a hard dependency of mailglass (Phoenix is in `mix.exs` deps). Adding a controller to core does not add any new dependency.
- The `MailglassAdmin.Router` macro pattern (v0.1) can be used as a reference, but the unsubscribe routes belong in `Mailglass.Webhook.Router` (which already mounts into adopter routers) or in a new `Mailglass.Router` macro.

**Recommended location:** `Mailglass.Compliance.UnsubscribeController` (new module) mounted via the existing `Mailglass.Webhook.Router` macro OR a new `Mailglass.Router` macro. Routes:

```
GET  /mailglass/unsubscribe/:token   # Human-facing confirmation page
POST /mailglass/unsubscribe/:token   # RFC 8058 one-click machine POST
```

The GET endpoint renders a minimal confirmation page (HTML, no JS, brand-neutral) or redirects to a success URL provided in the token's `redirect_on_success` field. The POST endpoint inserts the suppression row and returns `200 OK` with an empty body per RFC 8058 §3.

### 3.2 `mix mailglass.gen.unsubscribe` — interaction with Router macro pattern

The v0.1 `MailglassAdmin.Router` macro in `mailglass_admin/lib/mailglass_admin/router.ex` provides the template. The generator produces:

1. A config snippet to add to `config/config.exs` (token signing secret, redirect URL)
2. A router mount instruction for the adopter's `router.ex`

The generator does NOT copy code into the adopter's app (unlike `mix mailglass.install` which generates migrations). It prints instructions. The mount is:

```elixir
# In adopter's router.ex:
use Mailglass.Router

mailglass_routes()
```

Where `mailglass_routes/0` expands to:

```elixir
scope "/mailglass", Mailglass do
  pipe_through :browser  # or [:api] depending on config
  get  "/unsubscribe/:token", Compliance.UnsubscribeController, :show
  post "/unsubscribe/:token", Compliance.UnsubscribeController, :create
end
```

This follows the same macro expansion pattern as `MailglassAdmin.Router` without creating a separate package. The `Mailglass.Router` macro is a NEW module added to the core package in Phase 11.

---

## 4. Auto-Suppression in the Existing One-Multi

### 4.1 Where AutoSuppress slots in `ingest_multi/3`

The current `build_multi/4` in `lib/mailglass/webhook/ingest.ex` (lines 178–227) assembles steps in this order:

```
1. Multi.run :duplicate_check
2. Multi.insert :webhook_event (on_conflict: :nothing)
3. Events.append_multi :event_0..:event_N  (one per normalized event)
4. Multi.run {:projector_categorize, idx} + {:projector_apply, idx}  (per event)
5. Multi.update_all :flip_status
```

AutoSuppress must slot at **step 4.5** — after `{:projector_apply, idx}` confirms an event is `:bounced`/`:complained`/`:unsubscribed` AND has a matched delivery (not orphan), but before `:flip_status`. The Auto-Suppress step reads the `{:projector_apply, idx}` change map entry:

```elixir
# Step 4.5: after each projector_apply, conditionally insert suppression
|> Multi.run({:auto_suppress, idx}, fn repo, changes ->
  case Map.get(changes, {:projector_apply, idx}) do
    {delivery, %Event{type: type}} when type in [:bounced, :complained, :unsubscribed] ->
      Suppression.AutoSuppress.maybe_suppress(repo, delivery, type)
    _ ->
      {:ok, :skipped}
  end
end)
```

This inserts the suppression row with `on_conflict: :nothing` so webhook replays are idempotent.

The `Suppression.AutoSuppress` module is a **NEW module** (`lib/mailglass/suppression/auto_suppress.ex`). It takes the repo handle from `Multi.run`, the `%Delivery{}`, and the event type. It must NOT call `Mailglass.Repo.multi/1` (no nested Multi — this is the exact anti-pattern that caused the v0.1 projector flat-Multi refactor per the `update_projections_for_each/2` docstring). It calls `repo.insert` directly on `Suppression.Entry` with `on_conflict: :nothing`.

**Boundary implication:** `Suppression.AutoSuppress` is called FROM `Webhook.Ingest`. The dependency direction is `Webhook.Ingest → Suppression.AutoSuppress`, NOT the reverse. `Suppression.AutoSuppress` may depend on `Suppression` (for changeset building) and `Mailglass.Events.Event` (for pattern matching). It must NOT depend on `Webhook.Ingest` — that would create a cycle.

`Mailglass.SuppressionStore` (the behaviour) is NOT involved here. Auto-suppression writes directly to the Ecto-backed default store because webhook ingest already owns the database transaction. The `SuppressionStore.add/3` public API is for out-of-band suppression management; inside the Multi we go direct to avoid double-transactions.

### 4.2 AutoSuppress step as Multi.run vs downstream Oban job

**Decision: Multi.run inside the existing transaction.** Not a downstream Oban job.

Rationale:
- The bounce/complaint event and the resulting suppression MUST be atomic. If the suppression insert lands in a separate job and that job fails, the next send to the bounced address would succeed (race window between event record and suppression record). This is exactly the class of eventual-consistency bug that the v0.1 append-only Multi pattern was designed to eliminate.
- `on_conflict: :nothing` on the suppression insert means replay is safe.
- The transaction already holds the delivery row lock (from `{:projector_apply, idx}`), so the suppression insert is a pure append with no additional lock acquisition.
- Oban job for auto-suppression would be appropriate ONLY if the suppression required external API calls (e.g., syncing to a third-party list service) — that is out of scope.

### 4.3 Soft-bounce escalation

The v0.1 suppressions table already has a `reason` column (`hard_bounce | complaint | unsubscribe | manual | policy | invalid_recipient`). Soft-bounce escalation (5 bounces in 7 days → permanent suppression) requires:

1. At auto-suppress time for a `:bounced` event: check if the event's `reject_reason` indicates soft bounce (`:deferred` events are soft; `:bounced` with `reject_reason: :bounced` is hard; `reject_reason: :invalid` is permanent invalid recipient).
2. For soft bounces: insert with `reason: :soft_bounce, expires_at: utc_now + 7 days` (temporary suppression).
3. A scheduled job checks the escalation: `SELECT address, tenant_id, COUNT(*) FROM mailglass_suppressions WHERE reason = 'soft_bounce' AND inserted_at >= now() - interval '7 days' GROUP BY address, tenant_id HAVING COUNT(*) >= 5`.

**Decision: Postgres query at suppression time + Oban scheduled job for escalation check.**

The inline Multi.run approach handles the per-event insert (step 4.5 above). The soft-bounce threshold query runs as an Oban cron job (daily, or configurable). When the threshold is crossed, the cron job inserts a new suppression row with `reason: :hard_bounce, expires_at: nil` — it does NOT update the existing soft-bounce rows (append-only invariant; updating suppression rows does not violate the event ledger trigger, but the Suppression context should treat its own table as append-oriented by convention). The soft-bounce rows are left to expire via their `expires_at`.

New module: `Mailglass.Suppression.Escalation` — the Oban worker for the threshold check. This is the `SUPP-04` soft-bounce escalation requirement.

`mix mailglass.suppressions.resync` — a new mix task that re-runs the escalation check on-demand (useful after importing historical bounce data).

---

## 5. Build Order for v0.2 Phases — Validation

### 5.1 Proposed order

```
Phase 8:  Release-Engineering Hardening
Phase 9:  Mailable API Redesign
Phase 10: Stream Policy Implementation
Phase 11: RFC 8058 List-Unsubscribe
Phase 12: Auto-Suppression
Phase 13: Release Ceremony
```

### 5.2 Dependency analysis

**Phase 8 must be first.** The v0.2 framing in `PROJECT.md` explicitly identifies this: "Tests gate currently `continue-on-error: true`", "Credo `strict: true` currently disabled", "Dialyzer `--halt-exit-status` advisory". These three are the quality gate that makes Phase 9 API changes auditable. You cannot confidently freeze a public API if Credo is not running strict and Dialyzer is not enforcing types. Phase 8 also closes the 9 v0.1.2 TODOs that are cosmetic debt — better to have a clean codebase before adding new features.

**Phase 9 (Mailable API) must precede Phase 10 (Stream) for one reason:** the `StreamPolicyConsistent` Credo check added in Phase 10 inspects the `use Mailglass.Mailable` compile-time opts. Phase 9 changes the macro injection (removes `import Swoosh.Email`). If Phase 10 runs first, it adds a Credo check that references the old macro shape, then Phase 9 changes the macro shape, forcing Phase 10's check to be rewritten. Doing 9 before 10 avoids this revision cycle.

**Phase 10 (Stream) must precede Phase 11 (List-Unsubscribe).** RFC 8058 `List-Unsubscribe` headers are stream-conditional: they are auto-injected for `:bulk` and opt-in for `:operational`, and must NOT appear on `:transactional`. `Mailglass.Compliance.add_rfc_required_headers/1` (modified in Phase 11) reads `msg.stream` to decide whether to inject. The stream policy enforcement from Phase 10 is the upstream that ensures `msg.stream` is valid and accurate before Phase 11 reads it. If Phase 11 ran before Phase 10, the compliance logic would be reading from the no-op seam's stream value — which is already correct in v0.1, but Phase 10's policy enforcement adds the guarantee that a message with `stream: :bulk` that somehow bypassed the Mailable declaration is caught.

**Phase 12 (Auto-Suppression) must follow Phase 11 (List-Unsubscribe).** The `:unsubscribed` event type (Anymail taxonomy) already exists in v0.1. However, the end-to-end flow — RFC 8058 POST received → token verified → suppression inserted — is complete only after Phase 11 adds the unsubscribe controller. Phase 12's AutoSuppress integration handles the `:unsubscribed` event that arrives via webhook (provider reports back that the user clicked "unsubscribe" in their email client). The controller in Phase 11 handles the user directly clicking the unsubscribe link in the email. Both paths insert suppression rows, but they are distinct flows. Phase 11 must land first so that the `:unsubscribed` event type's full lifecycle (header injected → user clicks → provider fires webhook → AutoSuppress runs) can be tested end-to-end in Phase 12.

**Phase 13 (Release Ceremony) depends on all of 8–12.** No inversion is safer.

### 5.3 Alternative ordering considered and rejected

**"Could Phase 12 (Auto-Suppression) precede Phase 11 (List-Unsubscribe)?"** — Technically possible for the `:bounced` and `:complained` event types. The `:unsubscribed` event type auto-suppression does not strictly require the unsub controller to exist — providers already fire `:unsubscribed` webhooks when users hit "report spam" or use built-in unsubscribe in Gmail. However, the "batteries-included" promise means the auto-suppression story is not complete until the full loop (header → click → webhook → suppression) is testable. Keep Phase 12 after Phase 11.

**"Could Phase 9 and Phase 10 be merged?"** — Not recommended. The Mailable API change (Phase 9) affects every adopter's mailable module (the codemod task is scoped here). The Stream policy implementation (Phase 10) affects internal pipeline logic and adds a new Credo check. These are independent concern axes. Merging them creates a larger change set that is harder to revert if Dialyzer finds type issues in one of them.

**Validated build order:**

```
Phase 8 → Phase 9 → Phase 10 → Phase 11 → Phase 12 → Phase 13
```

This order is confirmed. No inversions are safer.

---

## 6. Boundary Contract Changes for v0.2

### 6.1 Current v0.1 boundary contract test

`test/mailglass/boundary_test.exs` asserts:
- `boundary_deps(Mailglass.Renderer) == [Mailglass]`
- `boundary_deps(Mailglass.Outbound) == [Mailglass]`
- `boundary_deps(Mailglass.Events) == [Mailglass]`
- `boundary_deps(Mailglass.Webhook)` includes `Mailglass.Events` and excludes `Mailglass.Outbound`

### 6.2 What changes in v0.2

**Phase 9 (Mailable API):** `Mailglass.Message` gains new functions. The `Mailglass` root boundary export list in `lib/mailglass.ex` (line 41–90) does NOT need to change — `Message` is already exported at line 44. The `Mailglass.Renderer` sub-boundary does not change (Renderer depends on Message, not the reverse).

**Phase 10 (Stream):** `Mailglass.Stream` module is MODIFIED in place (no-op seam → real implementation). The module is already exported from the root boundary at line 53. No boundary changes needed.

**Phase 11 (List-Unsubscribe):**
- NEW: `Mailglass.Compliance.Unsubscribe` (token signer) — add to root boundary exports
- NEW: `Mailglass.Compliance.UnsubscribeController` (Phoenix.Controller) — add to root boundary exports
- NEW: `Mailglass.Router` macro — add to root boundary exports
- MODIFIED: `Mailglass.Compliance.add_rfc_required_headers/1` — function signature unchanged, behavior extended for `:bulk` stream

The `UnsubscribeController` depends on `Mailglass.Suppression` (to insert a suppression row) and `Mailglass.Compliance.Unsubscribe` (to verify the token). These are both already in the root boundary. The boundary test should add:

```elixir
test "unsubscribe controller depends on suppression but not outbound" do
  deps = boundary_deps(Mailglass.Compliance.UnsubscribeController)
  assert Mailglass.Suppression in deps  # or inferred from root
  refute Mailglass.Outbound in deps
end
```

**Phase 12 (Auto-Suppression):**
- NEW: `Mailglass.Suppression.AutoSuppress` — dependency direction `Webhook.Ingest → Suppression.AutoSuppress`, NOT the reverse
- NEW: `Mailglass.Suppression.Escalation` (Oban worker, conditionally compiled when Oban present)

The critical boundary rule: `Mailglass.Suppression.AutoSuppress` MUST NOT depend on `Mailglass.Webhook.Ingest`. AutoSuppress is a pure suppression concern; it receives a `%Delivery{}` and an event type atom. It does not know it was called from webhook ingest — it could equally be called from other contexts in the future. The dependency graph:

```
Mailglass.Webhook.Ingest
  → Mailglass.Suppression.AutoSuppress
      → Mailglass.Suppression (changeset building)
      → Mailglass.Events.Event (pattern matching on event type)
      → Mailglass.Repo (direct repo.insert, not transact/1)
```

The boundary test update for Phase 12:

```elixir
test "auto_suppress has no webhook boundary dependency" do
  deps = boundary_deps(Mailglass.Suppression.AutoSuppress)
  refute Mailglass.Webhook in deps
end

test "webhook ingest may depend on suppression" do
  deps = boundary_deps(Mailglass.Webhook)
  assert Mailglass.Suppression in deps  # already true if Suppression is on Mailglass root
end
```

### 6.3 Root boundary export additions for v0.2

Additions to `lib/mailglass.ex` exports list:

```elixir
# Phase 11 additions
Compliance.Unsubscribe,
Compliance.UnsubscribeController,
Router,

# Phase 12 additions
Suppression.AutoSuppress,
Suppression.Escalation,   # conditionally when Oban loaded
```

The `@oban_exports` conditional pattern (line 37–39 of `mailglass.ex`) is the template for the `Suppression.Escalation` conditional export.

---

## 7. Data Flow Changes

### 7.1 v0.2 Send Pipeline (with Stream enforcement active)

```
Caller: msg |> MyApp.UserMailer.welcome(user) |> Mailglass.deliver()

Preflight (all in do_send/2 — lib/mailglass/outbound.ex):
  Stage 0: Tenancy.assert_stamped!/0
  Stage 1: Tracking.Guard.assert_safe!/1
  Stage 2: Suppression.check_before_send/1
  Stage 3: RateLimiter.check/3
  Stage 4: Stream.policy_check/1  ← NOW REAL (Phase 10: validates stream rules)
  Stage 5: Renderer.render/1
  Stage 5.5: Compliance.add_rfc_required_headers/1  ← EXTENDED (Phase 11: auto-injects
              List-Unsubscribe for :bulk, conditional for :operational)
  Stage 6: Tracking.rewrite_if_enabled/1

Multi#1: Delivery insert + Event(:queued) insert
Adapter call (outside transaction per D-21)
Multi#2: Delivery update + Event(:dispatched) insert
PubSub broadcast
```

### 7.2 v0.2 Webhook Ingest Multi (with AutoSuppress)

```
Webhook POST → Plug → Signature verify → Tenant resolve → ingest_multi/3

build_multi/4 steps (lib/mailglass/webhook/ingest.ex):
  1. Multi.run :duplicate_check
  2. Multi.insert :webhook_event
  3. For each event idx:
       Events.append_multi :"event_#{idx}"
  4. For each event idx:
       Multi.run {:projector_categorize, idx}
       Multi.run {:projector_apply, idx}
       Multi.run {:auto_suppress, idx}  ← NEW (Phase 12: after projector_apply)
  5. Multi.update_all :flip_status

Post-commit:
  PubSub.broadcast per event (matched events only — orphans skipped)
  Telemetry emit (per-event + duplicate signal)
```

### 7.3 New controller flow (Phase 11)

```
User GET  /mailglass/unsubscribe/:token
  → UnsubscribeController.show/2
  → Compliance.Unsubscribe.verify_token!(token)  → {:ok, %{address, tenant_id, stream}}
  → render confirmation HTML

User POST /mailglass/unsubscribe/:token (RFC 8058 one-click)
  → UnsubscribeController.create/2
  → Compliance.Unsubscribe.verify_token!(token)
  → Suppression.add(%{reason: :unsubscribe, source: "rfc8058", tenant_id, address})
  → 200 OK (empty body per RFC 8058 §3)
```

---

## 8. New Modules — Complete Inventory

| Module | Status | Phase | Notes |
|--------|--------|-------|-------|
| `Mailglass.Compliance.Unsubscribe` | NEW | 11 | Token sign/verify for List-Unsubscribe links |
| `Mailglass.Compliance.UnsubscribeController` | NEW | 11 | Phoenix.Controller handling GET + POST |
| `Mailglass.Router` | NEW | 11 | Macro that mounts unsubscribe routes in adopter router |
| `Mailglass.Suppression.AutoSuppress` | NEW | 12 | Multi.run step — pure Repo insert, no behaviours |
| `Mailglass.Suppression.Escalation` | NEW | 12 | Oban worker for soft-bounce threshold check |
| `lib/mix/tasks/mailglass.upgrade.v0_2.ex` | NEW | 9 | Codemod task rewriting `update_swoosh` patterns |
| `lib/mix/tasks/mailglass.suppressions.resync.ex` | NEW | 12 | On-demand escalation resync |
| `credo_checks/stream_policy_consistent.ex` | NEW | 10 | Compile-time stream rule enforcement |

| Module | Status | Phase | Change |
|--------|--------|-------|--------|
| `Mailglass.Mailable` (`__using__/1`) | MODIFIED | 9 | Remove `import Swoosh.Email` at line 129 |
| `Mailglass.Message` | MODIFIED | 9 | Add 8 new field setter functions |
| `Mailglass.Stream` | MODIFIED | 10 | Replace no-op body with real policy enforcement |
| `Mailglass.Compliance` | MODIFIED | 11 | Extend `add_rfc_required_headers/1` for `:bulk`/`:operational` |
| `Mailglass.Webhook.Ingest` | MODIFIED | 12 | Add `{:auto_suppress, idx}` Multi.run step in `build_multi/4` |
| `docs/api_stability.md` | MODIFIED | 9 | Add §v0.2 Public Surface Freeze section |
| `lib/mailglass.ex` (root boundary) | MODIFIED | 11+12 | Add new module exports to boundary list |
| `test/mailglass/boundary_test.exs` | MODIFIED | 11+12 | Add boundary assertions for new modules |

---

## 9. Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Mailable macro injection site | HIGH | Exact line 129 of `mailable.ex` verified in source |
| `update_swoosh` as documented escape hatch | HIGH | Already in `api_stability.md §Message Extensions` |
| Stream policy seam location | HIGH | `stream.ex` line 35; call sites at outbound.ex lines 291, 355, 509 |
| List-Unsubscribe in core (not admin) | HIGH | Phoenix.Controller already a hard dep; adopter availability requires core |
| AutoSuppress as Multi.run (not Oban job) | HIGH | Atomicity requirement; replay-safe via on_conflict: :nothing |
| Soft-bounce escalation as Oban cron | MEDIUM | Correct approach; Oban optional dep adds conditional compilation need |
| Build order Phase 8→9→10→11→12→13 | HIGH | Dependency chain validated above; no valid inversions found |
| Boundary changes | HIGH | Grounded in existing boundary_test.exs assertions and Boundary macro patterns |

---

## 10. Open Questions for Phase-Specific Research

1. **Phase 9 — `mix mailglass.upgrade.v0_2` codemod scope:** Does the codemod need to handle `import Swoosh.Email` in ADOPTER test files (e.g., `test/support/`), or only in production mailable modules? Confirm scope before writing the task.

2. **Phase 10 — Stream policy violations for adopters who pass `stream: :bulk` but don't configure unsubscribe:** Is this a compile error, runtime error, or lint warning? Recommendation is lint warning (advisory) at Phase 10 since the unsubscribe controller doesn't exist until Phase 11. Confirm at planning time.

3. **Phase 11 — Token rotation strategy:** `Phoenix.Token` supports `max_age` and `key_iterations`. The `Mailglass.Compliance.Unsubscribe` module needs a key rotation story. Does it reuse the adopter's `Phoenix.Endpoint` signing key, or does it require a separate `config :mailglass, :unsubscribe_signing_key` value? Confirm at planning time.

4. **Phase 12 — Soft-bounce `reject_reason` mapping:** The Anymail taxonomy has `reject_reason: :bounced` for hard bounces and does not have a specific soft-bounce `reject_reason` — soft bounces may arrive as `:deferred` events rather than `:bounced`. Confirm provider-specific mapping in Phase 12 research before implementing escalation logic.

5. **Phase 12 — `mix mailglass.suppressions.resync` scope:** Does this task rescan ALL historical events (potentially expensive) or only events from the last N days? The Postgres LATERAL query approach is correct but the time window needs configuration.

---

*End of architecture research. All integration points grounded in exact line references to shipped v0.1 source.*
