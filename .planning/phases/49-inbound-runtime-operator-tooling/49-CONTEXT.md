# Phase 49: Inbound Runtime Operator Tooling - Context

**Gathered:** 2026-05-25 (assumptions mode + per-area advisor research)
**Status:** Ready for planning

<domain>
## Phase Boundary

An operator running mailglass in production gets the **same operational toolbox for
inbound** that they already have for outbound. Six deliverables, no more (IOPS-01..05,
MIME-03):

1. **`mix mailglass.inbound.doctor`** — DNS-free pre-deploy config validation (routes
   compile + don't conflict, mailboxes exist + implement the behaviour, provider signing
   keys configured, MIME backend available), exit-coded + JSON for CI. Mirrors `mix mail.doctor`.
2. **`mix mailglass.inbound.replay`** — CLI over `MailglassInbound.Internal.Replay.replay/2`
   with `--record-id`/`--since`/`--tenant` selectors and destructive-action confirmation unless `--yes`.
3. **`mix mailglass.inbound.prune`** — retention enforcement (records 90d / evidence 30d /
   execution_runs 90d / replay_runs 30d, configurable, batched), Oban-cron-when-available
   with mix-task fallback. Mirrors `Mailglass.Webhook.Pruner`.
4. **Ingress rate limiter** — post-verify, three buckets (tenant / sender_domain / recipient),
   HTTP 429 + `Retry-After`, telemetry on trip, no `:transactional` bypass, no auto-suppression.
5. **Suppression flag-only** — suppressed-sender messages persist normally with a flag, surface
   in IADM-02 and reach mailbox callbacks; no auto-bounce.

**Out of scope (later phases):** operator/provider/routing-debug *docs* (Phase 50);
the v1.2 release ceremony (Phase 50.5); SMTP listener / Cloudflare ingress (future milestone);
cluster-global (cross-node) rate limiting (future, needs a shared backend).

**Architectural anchor:** every new surface lives **inside `mailglass_inbound`**. Core never
depends on inbound (`{:mailglass, path: ".."}` is one-directional, enforced by `boundary` + Credo).
Inbound reuses core only by calling its public modules.
</domain>

<decisions>
## Implementation Decisions

> All decisions below are **locked defaults** synthesized from five parallel advisor-research
> agents (config, CLI/doctor, rate limiting, suppression/struct contract, prune/retention),
> each pressure-tested against Elixir/Plug/Ecto/Phoenix idioms, cross-ecosystem lessons, the
> `prompts/` research, DX/least-surprise, and mailglass's locked DNA. Where a decision overrides
> literal REQ wording, it is flagged as a documented deviation with rationale.

### A · Package architecture & config surface

- **D-49-01:** All Phase-49 surfaces (the three mix tasks, the rate limiter, the prune logic,
  the config accessor) live **inside `mailglass_inbound`**. Tasks/limiter/prune reach core only
  by calling its public modules (`Mailglass.SuppressionStore`, `Mailglass.RateLimitError`,
  `Mailglass.OptionalDeps.GenSmtp`). Core gains **no** dependency on inbound (boundary law).
- **D-49-02:** Add a small validated **`MailglassInbound.Config`** accessor (NimbleOptions schema
  + boot validation + helpful errors, mirroring core `Mailglass.Config`'s *style*) reading the
  **`:mailglass_inbound` app env**. Do **not** add inbound keys to core `Mailglass.Config`
  (it reads `Application.get_all_env(:mailglass)` only — adding inbound keys would invert the
  package dependency and make core validate config for a package it can't see). The ROADMAP's
  "configurable via `Mailglass.Config`" reads as "in the Config *style*, inbound-local."
  Cross-ecosystem precedent: **Rails ActionMailbox** namespaces `config.action_mailbox.*`
  (incl. `incinerate_after` retention) to the inbound component, not ActionMailer.
- **D-49-03:** Config key shape (sits beside the existing `:postmark`/`:sendgrid`/`:mailgun`/`:ses`
  blocks):
  ```elixir
  config :mailglass_inbound,
    retention: [records_days: 90, evidence_days: 30, execution_runs_days: 90, replay_runs_days: 30],
    rate_limit: [
      tenant:        [capacity: 1000, per_minute: 60],
      sender_domain: [capacity: 200,  per_minute: 60],
      recipient:     [capacity: 500,  per_minute: 60]
    ]
  ```
  `:infinity` on any retention class disables that window. Honest-surface: ship **only** the knobs
  the runtime actually reads — no speculative per-tenant override maps until a code path consumes them.

### B · Mix tasks (doctor / replay / prune)

- **D-49-04:** Three thin `Mix.Tasks.Mailglass.Inbound.{Doctor,Replay,Prune}` shells in
  `mailglass_inbound/lib/mix/tasks/` (OptionParser `strict:` + a `validate_cli!/3` rejecting
  `rest`/`invalid` per `mail.doctor.ex:54-81` + `Mix.Task.run("app.start")`) delegating to
  package-local **`MailglassInbound.Internal.{Doctor,Prune}`** + the existing `Internal.Replay`.
  A shared **`MailglassInbound.Operator.Formatter`** (cloned from `Mailglass.Deliverability.Formatter`,
  `render_human/2` + `render_json/1`) owns output. Each task `use Boundary, classify_to:` the inbound
  package. Logic lives in the internal modules (unit-testable + reusable by the admin LiveView), never
  inline in the task. Reject the umbrella-subcommand shape (`mix mailglass.inbound doctor`) — Mix's
  model is one dotted task per name.
- **D-49-05:** Doctor **three-state exit code** (Credo's model — distinguishing "problems found"
  from "couldn't check" is the #1 doctor footgun): `0` all pass (or pass+warn without `--strict`);
  `1` at least one `fail` (or any `warn` under `--strict`) — the CI-gate signal; `2` cannot-diagnose
  (no router configured / app failed to boot). Flags: `--format human|json` (validate against the
  allowlist as `mail.doctor.ex:74-78`), `--strict`, `--verbose`. Finding shape:
  `%{check: atom, status: :pass|:warn|:fail, title, observed, remediation, evidence: map}`.
  JSON = one object `%{summary: %{pass, warn, fail}, findings: [...]}` (machine-parseable).
- **D-49-06:** Doctor checks, all **DNS-free / offline** (the trait that makes doctors loved):
  router configured + compiles; ≥1 route defined; each route's mailbox `Code.ensure_compiled!/1`
  + `function_exported?(mod, :process, 1)`; provider signing keys present (read the same
  `:mailglass_inbound` config the plug reads — **never verify a signature**); MIME backend via
  `Mailglass.OptionalDeps.GenSmtp.available?/0`, reporting backend = `gen_smtp` (`:mimemail`) and
  version via `Application.spec(:gen_smtp, :vsn)` — neither trips `NoBareOptionalDepReference`
  (MIME-03); and route-conflict detection (D-49-07).
- **D-49-07:** Route-conflict detection **reuses `MailglassInbound.Router.Matcher.matches_route?/2`**
  (the single source of truth for match semantics — never re-implement equality/regex/wildcard rules,
  or the doctor drifts from runtime and emits false positives). Strategy: (a) **structural subsumption**
  — an earlier wildcard/catch-all/broader route preceding a narrower one = `fail` (the classic
  "catch-all before specific" footgun); (b) **witness-probe** — synthesize an `InboundMessage` from a
  later route's exact-string matchers and run the earlier route's matcher; if it matches, the later
  route is shadowed. **Regex-vs-regex** overlap is undecidable → `warn` ("possible overlap, verify
  manually"), never `fail`.
- **D-49-08:** Add a compile-time **`:source` (file + line) field to `MailglassInbound.Router.Route`**,
  captured via `__CALLER__` in the `route/2` macro, so conflict reports name `router.ex:12`, not bare
  module names. Additive, internal reflection metadata; locked as default — it is what turns conflict
  output from "vague and hated" into "actionable and loved."
- **D-49-09:** Replay CLI: `Internal.Replay.replay/2` **stays single-record** (do not widen it). The
  task resolves `--record-id` / `--since <iso8601>` / `--tenant <id>` (AND-combinable) into a record-id
  list via a small selection query, then iterates `replay/2` per record. `--dry-run` (count + scope,
  no change), interactive `[y/N]` defaulting **No** via `Mix.shell().yes?/1`, `--yes`/`-y` to skip the
  prompt (never *remove* it). Zero matches → exit `0` with "nothing to replay." Replay is
  non-destructive (appends `ExecutionRun` rows, `source: :replay`, append-only) → the `[y/N]` tier
  suffices.
- **D-49-10:** Prune CLI **deletes rows** → stronger confirmation tier: `--dry-run` + a typed
  confirmation above a row-count threshold + `--yes` for cron/CI.

### C · Ingress rate limiter

- **D-49-11:** Ship an **inbound-local `MailglassInbound.RateLimiter`** with its **own** supervised
  `:mailglass_inbound_rate_limit` ETS table via a new `MailglassInbound.RateLimiter.TableOwner`
  child added to `MailglassInbound.Application` (alongside `Task.Supervisor`). Do **not** reuse
  `Mailglass.RateLimiter` — it is `%Mailglass.Message{}`-bound, reads `:mailglass` app env, has a
  `:transactional` bypass baked in, and its ETS table is owned by a supervisor started only in
  core's `Application` (absent in an inbound-only runtime). **No new dependency** (no Hammer/PlugAttack):
  a library shouldn't force a rate-limit dep, and core already ships the primitive to copy. Reuse
  only core's `Mailglass.RateLimitError` *struct*.
- **D-49-12:** Algorithm = **leaky-bucket continuous-refill** (same as core D-23), one ETS row per key
  via `:ets.update_counter/4`. Copy core `TableOwner`'s OTP-27 ETS opts verbatim (`:set, :public,
  :named_table, read_concurrency: true, write_concurrency: :auto, decentralized_counters: true`) +
  D-22 crash semantics (table dies with owner; rate state is not load-bearing across crashes).
  Use `System.monotonic_time(:millisecond)` for refill math. Rejected fixed-window (burst-at-boundary)
  and sliding-log (unbounded memory).
- **D-49-13:** Three buckets evaluated **fail-fast** via `with`: tenant (1000/min) → recipient (500/min)
  → sender_domain (200/min). The bucket that trips first returns **its own** `Retry-After` — do not
  compute a max across buckets (you only enforced one; honest-surface; matches Rack::Attack + nginx
  `limit_req`). **No `:transactional` bypass** (inbound has no stream semantics). **No auto-suppression**
  on rate-trip.
- **D-49-14:** Placement: inside `MailglassInbound.Ingress.Plug.do_call/2`, **post-verify** (forged
  payloads never consume budget — else it's an unauthenticated-DoS amplifier) and **after `resolve_tenant!`**
  (need `tenant_id`), **before persist**. On trip, return the existing `{resp, meta}` tuple — **never raise**:
  HTTP **429** + `Retry-After` header in seconds (`put_resp_header/3`), body `%{status: "rate_limited",
  bucket: "<type>"}`. Build `Mailglass.RateLimitError` internally for classification (`:per_tenant` /
  `:per_domain` cover the buckets); do not let it escape as a raise. (SES does a bounded S3 fetch inside
  verify — that's signature-gated, so the limiter still correctly sits post-verify.)
- **D-49-15:** Headers = **`Retry-After` only**. No `X-RateLimit-*` / `RateLimit-*` (honest-surface:
  the consumer is a provider webhook poster that honors `Retry-After` and ignores quota-advertisement
  headers; the IETF RateLimit-headers draft is not yet an RFC). Revisit only if a real client consumes them.
- **D-49-16:** **PII discipline.** Sender bucket keyed on **domain** (never the full sender address).
  Recipient bucket **may** key on the full recipient address — it's the routing identity, already
  persisted in clear, lives only in node-local ETS, and is never logged/serialized/emitted; no hashing
  required. Add a code comment citing this so a future lint pass doesn't false-positive. Telemetry and
  the 429 body carry the bucket **type** (`:tenant | :recipient | :sender_domain`), **never** the value.
- **D-49-17:** Telemetry: emit the **dedicated `[:mailglass_inbound, :rate_limit, :stop]`** span
  (mandated by IOPS-04 + success criterion 4) from the single `MailglassInbound.Telemetry` module
  (preserve its single-span-surface invariant). Extend the D-45-03 PII whitelist with `bucket`, `limit`,
  `retry_after` and update the `NoPiiInTelemetry` allowlist accordingly. Metadata
  `%{provider, tenant_id, bucket, limit, retry_after}` — never recipient/sender/email/to/from.
- **D-49-18:** Document that inbound rate limits are **per-node** (ETS is node-local — an N-node cluster
  enforces N× the limit). Acceptable for the single-node-default library posture; cluster-global
  enforcement (Redis/Mnesia backend) is out of scope until a shared-backend option ships.

### D · Suppression flag-only + the `InboundMessage` signals contract

- **D-49-19:** Compute the flag in **`MailglassInbound.Ingress.Persist.persist/2` before `insert_record/4`**
  (where `tenant_id`, the normalized `%InboundMessage{}`, and the transaction already live), threading it
  into the record attrs. Call core **`Mailglass.SuppressionStore.check/2`** via the configured store
  (`Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)`) — **not** the
  outbound `Mailglass.Suppression.check_before_send/1` facade (it reads swoosh `:to` + emits *outbound*
  telemetry — wrong direction). Key = `%{tenant_id: tenant_id, address: downcased :address of
  List.first(message.from)}`, **no `:stream`** (outbound concept). Result map: `{:suppressed, _}` → `true`;
  `:not_suppressed` → `false`; `{:error, _}` and empty/missing `from` → **`false` (degrade OPEN** — this is
  diagnostic signal, not a gate; a store hiccup must never block legitimate inbound mail). Tenant scoping is
  internal to `Ecto.check/2` (`Mailglass.Tenancy.scope`).
- **D-49-20:** Persist a **`suppression_flagged :boolean, null: false, default: false`** column on
  `mailglass_inbound_records` (a new generated migration adopters run; `NOT NULL DEFAULT false` backfills
  existing rows). Add the field to the `InboundRecord` schema + `@cast` (settable-at-insert, **not** `@required`).
  The **column is the source of truth**; the admin list (IADM-02) read-model selects it directly. (Inbound
  tables are append-only by convention but carry no DB UPDATE/DELETE trigger — the flag is set once at INSERT.)
- **D-49-21:** **Surface-signal shape — documented deviation from IOPS-05 literal wording.** Add a single
  field **`:signals`** to `%MailglassInbound.InboundMessage{}`, typed as a framework-owned, read-only
  **nested struct `%MailglassInbound.InboundMessage.Signals{}`** (the `Ecto.Schema.Metadata` / `__meta__`
  archetype: framework writes, adopter reads, dialyzer-checkable, pattern-matchable). Fields are enumerated,
  defaulted, and non-nil; today exactly `suppression_flagged: false`. `:signals` defaults to `%Signals{}`.
  **Do NOT use a free `:metadata` map and do NOT name it `:metadata`** — mailglass already uses `:metadata`
  for **adopter-owned** application data on outbound `Mailglass.Message` (+ `put_metadata/3`), and the
  domain-language doc defines Metadata = application-defined data; reusing that name for *framework-derived*
  facts would invert its meaning across the framework. `Execution.message_from_record/1` populates
  `signals: %Signals{suppression_flagged: record.suppression_flagged}` from the column.
  **IOPS-05 says `%InboundMessage{}.metadata.suppression_flagged`; we ship `.signals.suppression_flagged`
  as a deliberate, documented improvement** (same precedent as the Phase-46 SESI-04 erratum). Future derived
  signals (spf_pass, dkim_pass, dmarc_pass, spam_score, auto_response) each become a new typed `Signals`
  field — each its own `@since` + CHANGELOG + minor bump.
- **D-49-22:** Read API: **safe dot-access `msg.signals.suppression_flagged`** (every field defaulted →
  never `nil`/`KeyError`, on every version, including pre-migration records that project through the
  struct default), pattern-matching in the head encouraged
  (`def process(%InboundMessage{signals: %Signals{suppression_flagged: true}})`), plus **one** convenience
  predicate **`MailglassInbound.InboundMessage.suppression_flagged?/1`**. Do **not** mint a predicate per
  future signal (the typed struct already makes dot-access safe — avoid helper sprawl). `@since "1.2.0"` +
  CHANGELOG "Added" entry under `mailglass_inbound` + linked minor bump; purely additive and
  backward-compatible (existing `process/1` clauses keep matching).
- **D-49-23:** **No auto-bounce, no auto-suppression** (IOPS-04/05). Validated against the backscatter
  consensus (auto-bouncing webhook-*accepted* mail generates collateral spam to forged senders and risks
  blocklisting your domain), Rails ActionMailbox, and the repo's domain-language doc (a suppression is a
  future-eligibility *signal*, never an automatic past action). The mailbox's existing
  `:accept | :ignore | {:reject, reason} | {:bounce, reason}` contract already gives adopters every lever —
  they read `signals.suppression_flagged` and decide. Emit `[:mailglass_inbound, :ingress, :suppression_flag,
  :stop]` with `%{flagged, tenant_id, provider}` only — never the address.
- **D-49-24:** Reserve the **name `:assigns`** on `%InboundMessage{}` for a future *adopter-writable* field;
  do **not** add it now (no consumer — `process/1` is single-shot; honest-surface). This keeps the
  metadata/signals/assigns ownership split clean if a multi-stage inbound transform pipeline ever lands.

### E · Prune / retention

- **D-49-25:** Shared-table model **confirmed**: `ExecutionRun` and `ReplayRun` both map
  `mailglass_inbound_replay_runs`, discriminated by the `source` `Ecto.Enum` column (`:fresh | :replay`,
  added by `..._generalize_replay_runs_to_execution_lineage.exs`). Read/filter `source` via **`ExecutionRun`**
  (or a schemaless query) — `ReplayRun` is the legacy narrow projection and does **not** map `source`.
  Four logical windows → **three physical tables**: records 90d; evidence 30d; `source=:fresh` 90d
  ("execution_runs"); `source=:replay` 30d.
- **D-49-26:** Keep FKs **`on_delete: :nothing`**; do explicit **child-first** ordered app-level batched
  deletes: `replay_runs (both source filters) → evidence → records`. Do **not** switch to `ON DELETE CASCADE`
  — it cannot express independent windows (evidence 30d ≠ records 90d) and silently un-batches a 1000-row
  parent delete into an unbounded child cascade. A mis-ordered delete fails loudly on the FK (safety net).
- **D-49-27:** Batched-delete idiom: `DELETE ... WHERE id IN (SELECT id FROM <t> WHERE <window>
  LIMIT 1000 FOR UPDATE SKIP LOCKED)`, looped until affected `< 1000`. Wrap the whole sweep in
  `pg_try_advisory_lock(<stable key>)` (non-blocking single-run guard — bail `{:ok, :locked_out}` if not
  acquired; prevents a cron tick racing an ops `mix` run). Batch size **1000** (IOPS-03). Do **not** run
  `VACUUM`/`ANALYZE` from the prune (autovacuum handles dead tuples; `VACUUM` can't run in a txn).
- **D-49-28:** `MailglassInbound.Internal.Prune.prune/0` holds the pure batched logic (Oban-independent).
  Ship a thin Oban worker behind a top-of-file `if Code.ensure_loaded?(Oban.Worker)` guard whose `perform/1`
  calls `prune/0` (+ an `available?/0 → false` stub in the `else`), gated through
  `MailglassInbound.OptionalDeps.Oban` (single file `optional_deps.ex`). **Document** the `0 3 * * *` cron
  line in the inbound operator guide (Phase 50); **never auto-register** it (mirror `Webhook.Pruner` + the
  consolidated boot-warning pattern in `application.ex`). The `mix mailglass.inbound.prune` task runs `prune/0`
  **synchronously whether or not Oban is present** — a deliberate, honest improvement over
  `mailglass.webhooks.prune`'s exit-1-when-Oban-absent (only *scheduling* needs Oban; the batched sweep is
  the workhorse). Mirror the webhook pruner's **structure** (gating, `:infinity` disable, telemetry shape)
  but **upgrade** its unbounded `delete_all` to the batched idiom (IOPS-03 requires LIMIT 1000; the webhook
  pruner does not batch).
- **D-49-29:** Telemetry `[:mailglass_inbound, :prune, :stop]` with per-table counts
  `%{records_deleted, evidence_deleted, fresh_runs_deleted, replay_runs_deleted, status}` — counts only, no PII.
- **D-49-30:** Retention defaults records 90d / evidence 30d / fresh_runs 90d / replay_runs 30d; `:infinity`
  on a class disables that window (mirror `Webhook.Pruner.prune_status(_, :infinity) → {:ok, 0}`). The
  evidence 30d default matches Rails ActionMailbox `incinerate_after`. Document the override + a **GDPR note**
  (raw evidence `raw_payload`/`raw_mime` are the sensitive surface; targeted identity-based erasure ≠ retention
  prune), mirroring core's webhook-pruner GDPR note.

### Claude's Discretion
- Exact internal function names/signatures of `MailglassInbound.{Config, RateLimiter, RateLimiter.TableOwner,
  Internal.Doctor, Internal.Prune, Operator.Formatter}`.
- Exact NimbleOptions schema field names within the locked config key shape (D-49-03).
- Exact replay batch-selection query module/shape (D-49-09).
- Exact `pg_try_advisory_lock` key constant + the prune typed-confirmation row threshold (D-49-10/27).
- Exact witness-probe construction for route-conflict detection, within the matcher-reuse + warn-on-regex
  constraint (D-49-07).
- Exact `Signals` struct field ordering and the precise wording of its closed-contract moduledoc note (D-49-21).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked posture
- `.planning/ROADMAP.md` — Phase 49 goal, success criteria 1-5, hardest sub-tasks (lines 192-213).
- `.planning/REQUIREMENTS.md` — IOPS-01..05 + MIME-03 exact wording (lines 89-93, 34). Note IOPS-05's
  `.metadata.suppression_flagged` is superseded by `.signals.suppression_flagged` per D-49-21.
- `.planning/PROJECT.md` — boundary law, optional-dep gateway, no-PII telemetry, append-only, fake-adapter-first,
  one-maintainer honesty.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, recommendation-first.
- `.planning/STATE.md` — current v1.2 milestone position.

### Inherited v1.2 decisions
- `.planning/phases/45-inbound-telemetry-idempotency-foundation/45-CONTEXT.md` — telemetry single-surface
  module + D-45-03 PII whitelist (extended by D-49-17), MIME parser + `GenSmtp` gateway, PubSub topic shape.
- `.planning/phases/46-mailgun-ses-inbound-ingress/46-CONTEXT.md` — provider signing config seam, the
  SESI-04 erratum precedent (the model for D-49-21's documented deviation), inbound-local error/gateway discipline.
- `.planning/phases/48-inbound-admin-liveview/48-CONTEXT.md` — IADM-02 admin list read-model that consumes
  the `suppression_flagged` column.

### Code anchors — outbound lift sources (mailglass core)
- `lib/mix/tasks/mail.doctor.ex` + `lib/mailglass/deliverability/formatter.ex` — doctor CLI shell, `validate_cli!`,
  `--format` allowlist, `render_human/2` + `render_json/1` (clone for `Operator.Formatter`).
- `lib/mailglass/webhook/pruner.ex` + `lib/mix/tasks/mailglass.webhooks.prune.ex` — prune skeleton to mirror
  (gating, `:infinity` disable, telemetry, `available?/0`, `exit({:shutdown, 1})`); note: webhook does NOT batch
  (`pruner.ex:97`) and exits-1 when Oban absent (`:54`) — D-49-27/28 upgrade both.
- `lib/mailglass/rate_limiter.ex` + `lib/mailglass/rate_limiter/{supervisor,table_owner}.ex` +
  `lib/mailglass/errors/rate_limit_error.ex` — leaky-bucket algorithm, multi-bucket `with` chain, OTP-27 ETS opts,
  D-22 crash semantics, the PII rule comment (`rate_limiter.ex:43`), and the `:transactional` bypass to drop.
- `lib/mailglass/suppression_store.ex` + `lib/mailglass/suppression_store/ecto.ex` — `check/2` seam + internal
  `Tenancy.scope`, nil-stream clause, downcasing. (`lib/mailglass/suppression.ex` is the outbound facade — do NOT reuse.)
- `lib/mailglass/message.ex` — outbound `:metadata` (adopter-owned) + `put_metadata/3`: the reason inbound must
  NOT claim `:metadata` for framework data (D-49-21).
- `lib/mailglass/config.ex` — the validated-accessor style to mirror inbound-local (it is `:mailglass`-scoped only).
- `lib/mailglass/optional_deps/gen_smtp.ex` — `available?/0`; report version via `Application.spec(:gen_smtp, :vsn)` (MIME-03).
- `lib/mailglass/application.ex` — consolidated Oban-absent boot-warning pattern (mirror for the prune worker).

### Code anchors — inbound targets (mailglass_inbound)
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` — `do_call/2` insertion point for rate-limit
  (post-verify, after `resolve_tenant!`, before persist) + the `{resp, meta}` non-raising response idiom + spans.
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` — `insert_record/4` attrs; where the suppression
  flag is computed + written (D-49-19/20).
- `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` — the public struct to extend with `:signals` (D-49-21).
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` — `message_from_record/1` (projects the column → `Signals`).
- `mailglass_inbound/lib/mailglass_inbound/mailbox.ex` — the `:accept|:ignore|{:reject,_}|{:bounce,_}` outcome contract.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/{inbound_record,execution_run,replay_run,inbound_evidence}.ex`
  — schemas; note `execution_run` + `replay_run` share table `mailglass_inbound_replay_runs` via `source` (D-49-25).
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` — single-record `replay/2` the CLI iterates (D-49-09).
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` — IADM-02 list `select/3` (add `suppression_flagged`).
- `mailglass_inbound/lib/mailglass_inbound/router.ex` + `router/matcher.ex` + `router/route.ex` —
  `__mailglass_inbound_routes__/0` reflection + `matches_route?/2`/`explain/2` reuse + `route/2` macro
  (`__CALLER__` for the `:source` field, D-49-08).
- `mailglass_inbound/lib/mailglass_inbound/telemetry.ex` — single-span surface + D-45-03 whitelist (extend per D-49-17).
- `mailglass_inbound/lib/mailglass_inbound/application.ex` — add `RateLimiter.TableOwner` child; do NOT auto-register the prune worker.
- `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` — `MailglassInbound.OptionalDeps.Oban` gateway (single file).
- `mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs` +
  `..._20260506210000_generalize_replay_runs_to_execution_lineage.exs` — FK `on_delete: :nothing` → child-first
  cascade order; the `source` column origin; no DELETE/UPDATE trigger on inbound tables.

### Strongest external precedents (verified 2026-05-25)
- Ecto.Schema.Metadata (`__meta__`) — https://hexdocs.pm/ecto/Ecto.Schema.Metadata.html — the framework-owned
  typed-nested-struct archetype `:signals` imitates (D-49-21).
- Broadway.Message (`:data` vs `:metadata`) — https://hexdocs.pm/broadway/Broadway.Message.html.
- Plug.Conn (`:assigns` vs `:private`) — https://hexdocs.pm/plug/Plug.Conn.html ; Swoosh.Email (`:private`/`:assigns`)
  — https://hexdocs.pm/swoosh/Swoosh.Email.html.
- Rails ActionMailbox (`config.action_mailbox.incinerate_after`, 30d default; backscatter avoidance) —
  https://guides.rubyonrails.org/action_mailbox_basics.html.
- Backscatter — https://en.wikipedia.org/wiki/Backscatter_(email) (the no-auto-bounce rationale, D-49-23).
- Credo exit statuses (three-tier) — https://hexdocs.pm/credo/exit_statuses.html ; clig.dev (exit codes,
  `--json`, dry-run/`--yes`/typed-confirm tiers) — https://clig.dev/.
- Hammer 7.x / PlugAttack (the deps deliberately NOT taken, D-49-11) — https://hexdocs.pm/hammer/readme.html.
- Postgres time-based retention (batched `DELETE ... FOR UPDATE SKIP LOCKED`, advisory locks) —
  https://blog.sequinstream.com/time-based-retention-strategies-in-postgres/ ; Oban.Plugins.Pruner —
  https://hexdocs.pm/oban/Oban.Plugins.Pruner.html.
- IETF RateLimit header fields draft (not yet an RFC — why `Retry-After` only, D-49-15) —
  https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/.

### `prompts/` research mined
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` (ETS rate-limit counters, OTP-27 ETS knobs, plug pipeline).
- `prompts/ecto-best-practices-deep-research.md` (batched retention deletes).
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` + `prompts/elixir-best-practices-deep-research.md` (library config namespacing, public-struct conventions, mix-task design).
- `prompts/mailer-domain-language-deep-research.md` ("Metadata = application-defined data"; accept/reject/bounce/ignore; suppression = future eligibility).
- `prompts/mailglass-brand-book.md` (CLI/error voice) + `prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` (Hammer/PlugAttack landscape, BEAM-primitives-over-Redis).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mail.doctor` + `Deliverability.Formatter` = the exact task-shell + service + human/JSON-formatter pattern to clone.
- `Webhook.Pruner` + `mailglass.webhooks.prune` = the prune skeleton (gating, `:infinity`, telemetry) — mirror
  structure, upgrade the delete to batched + run-without-Oban.
- `Mailglass.RateLimiter` + `RateLimiter.TableOwner` = the leaky-bucket + OTP-27 ETS + crash-semantics template to copy
  inbound-locally (NOT reuse).
- `Mailglass.SuppressionStore.check/2` = the tenant-scoped suppression lookup (call from inbound; core gains no dep).
- `Mailglass.OptionalDeps.GenSmtp.available?/0` + `Application.spec(:gen_smtp, :vsn)` = MIME-03 reporting without a bare ref.
- `Router.Matcher.matches_route?/2` = the single source of truth for route-conflict detection (reuse, never re-implement).
- `MailglassInbound.OptionalDeps.Oban` = the gateway for the conditionally-compiled prune worker.
- `Execution.message_from_record/1` = the single projection point where the persisted `suppression_flagged` column
  becomes `%InboundMessage{}.signals`.

### Established Patterns
- Boundary law: `mailglass_inbound` → `mailglass` only; new tooling lives in inbound; tasks are CLI shells over `Internal.*`.
- Closed-type structs + pattern-match-not-string-match (errors-as-contract) → the typed `Signals` nested struct fits the DNA.
- Optional deps via a single `OptionalDeps.*` module + `available?/0` + degraded fallback; bare refs banned.
- Telemetry on `[:mailglass_inbound, domain, resource, action, *]`, metadata whitelisted, never PII; single-span-surface module.
- Append-only inbound tables (no UPDATE/DELETE trigger, but retention DELETEs allowed); multi-tenant `tenant_id` everywhere.
- `:metadata` means **adopter-owned** across the whole framework (outbound + domain doc) — inbound framework facts go on `:signals`.

### Integration Points
- `Ingress.Plug.do_call/2` ← rate-limit check (post-verify/post-tenant/pre-persist) returning a 429 tuple.
- `Ingress.Persist.persist/2` ← suppression-flag computation (core `SuppressionStore.check/2`) → record column.
- `Execution.message_from_record/1` → `%InboundMessage{signals: %Signals{...}}` → adopter `process/1`.
- `internal/operator/records.ex` (IADM-02) ← `suppression_flagged` column.
- `MailglassInbound.Application` ← new `RateLimiter.TableOwner` child; prune Oban worker stays unregistered.
- `MailglassInbound.Telemetry` ← new `rate_limit` + `suppression_flag` + `prune` spans (whitelist extended).
- `MailglassInbound.Config` → `:mailglass_inbound` app env → consumed by `RateLimiter` + `Internal.Prune`.
</code_context>

<specifics>
## Specific Ideas

- **Mental model:** Phase 49 is the inbound *sibling* of the shipped outbound operator toolbox (`mail.doctor`,
  `Webhook.Pruner`, `RateLimiter`, suppression). Mirror the proven patterns; adapt only where inbound genuinely
  differs (no streams → no `:transactional` bypass; no Swoosh email → own limiter; webhook-accepted mail → flag-not-bounce).
- **The one decision researched rather than assumed:** the `%InboundMessage{}` surface for `suppression_flagged`.
  Deep research overturned the initial "free `:metadata` map" lean → a typed framework-owned `:signals` nested struct,
  because mailglass already reserves `:metadata` for adopter data. This is a permanent public contract; `.signals.*`
  ships instead of IOPS-05's literal `.metadata.*` as a documented improvement (SESI-04-erratum precedent).
- **Two literal-REQ deviations, both documented:** (1) "configurable via `Mailglass.Config`" → inbound-local
  `MailglassInbound.Config` reading `:mailglass_inbound` (D-49-02, boundary law); (2) `.metadata.suppression_flagged`
  → `.signals.suppression_flagged` (D-49-21).
- **Honest-surface throughline:** ship only config knobs the runtime reads (no speculative per-tenant overrides),
  `Retry-After` only (no quota-advertisement headers), no inbound `:assigns` until a consumer exists, no per-signal
  predicate sprawl.
- **DoS posture:** the rate limiter is post-verify by design — forged payloads must never consume a tenant's budget.
- **Honest improvements over the outbound mirror:** the inbound prune batches (webhook doesn't) and runs without Oban
  (webhook exits 1); the doctor is offline/DNS-free (core's `mail.doctor` is DNS-bound) — lean into the speed.
</specifics>

<deferred>
## Deferred Ideas

- Operator / Mailgun+SES setup / routing-debug **docs** for this tooling → Phase 50 (IDOC-*).
- **Cluster-global (cross-node) rate limiting** (Redis/Mnesia backend) — node-local ETS is the v1.2 posture; revisit on scale evidence.
- Taking **Hammer / PlugAttack** as a rate-limit dep — explicitly not now (own ETS suffices; a library shouldn't force the dep).
- Inbound **`:assigns`** (adopter-writable) field — reserved name, added only if a multi-stage inbound transform pipeline lands.
- Per-signal predicate helpers beyond `suppression_flagged?/1` — add only for signals with proven high-frequency branching.
- Switching inbound FKs to **`ON DELETE CASCADE`** — rejected (can't express independent windows, un-batches); revisit never unless windows unify.
- Future `Signals` fields (spf_pass / dkim_pass / dmarc_pass / spam_score / auto_response) — additive, each its own phase/`@since`.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 49 scope.
</deferred>

---

*Phase: 49-inbound-runtime-operator-tooling*
*Context gathered: 2026-05-25 (assumptions mode + 6 advisor-research agents)*
