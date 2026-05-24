# Phase 48: Inbound Admin LiveView - Context

**Gathered:** 2026-05-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Give operators the **same observability for inbound that they already have for
outbound**: a tenant-scoped master/detail at `/admin/inbound` in `mailglass_admin`.
Six deliverables, no more:

1. **`MailglassAdmin.InboundLive`** — a structural clone of `OperatorLive` with a
   list/detail split, URL-param filters (provider, mailbox outcome, time window,
   search), and the tenant-required-or-empty gate (never a cross-tenant leak).
2. **Detail view** — canonical `%InboundMessage{}` summary, raw provider source from
   `InboundEvidence` (PII-redacted by default, `:reveal_raw` capability gate), matched
   mailbox + execution outcome, and a timeline of `ExecutionRun` rows (fresh + replay).
3. **Replay modal** — confirmation-gated, tenant-bound, capability-gated; appends a
   `source: :replay` row (append-only; no UPDATE).
4. **Routing-trace card** (the one novel surface) — for `:no_match` rows, a per-clause
   matcher diff answering "why didn't this match `SupportMailbox`?".
5. **Live updates** — `InboundLive` subscribes to the per-tenant inbound topic.
6. **Nav + auth** — reachable from admin nav, gated by the existing `MailglassAdmin.Auth`
   plug. No new auth surface.

In scope: IADM-01..07, plus surfacing IOPS-05 `suppression_flagged` in the detail header.

Out of scope (later phases): the inbound suppression-flag *write* path itself (IOPS-05
persistence = Phase 49), CLI operator tooling (Phase 49), the routing-debug *guide*
(Phase 50). This phase is a **pure consumer** of inbound data + a thin reflection/replay
seam — it ships no new ingress or persistence behavior.

The entire visual/interaction language is locked and approved in
`48-UI-SPEC.md` (6/6 dimensions PASS) — these decisions are the implementation/
architecture choices that the contract intentionally left to the planner.
</domain>

<decisions>
## Implementation Decisions

### Cross-package dependency strategy (the load-bearing decision)
- **D-48-01:** `mailglass_admin` reaches `mailglass_inbound` through an **OPTIONAL,
  runtime-gated dependency — never a compile-time edge.** Add
  `{:mailglass_inbound, "~> 0.2", optional: true}` as a plain floating entry in
  `mailglass_admin/mix.exs` `deps/0`. For local dev, add a `mailglass_inbound_dep/0`
  helper mirroring `mailglass_dep/0` but **floating, never `==`**
  (path dep in dev/test, `"~> 0.2"` when published). The dep is **kept out of the
  release-please `PINS` array** in `.github/workflows/release-please.yml`.
  - Rationale: `mailglass` + `mailglass_admin` are linked at the 1.x line by the
    linked-versions plugin; `mailglass_inbound` is deliberately *excluded* from that
    group and tracks its own 0.x line (`release-please-config.json`,
    `.release-please-manifest.json`). The publish-time sed pin
    (`release-please.yml:145-164`) is anchored on the literal atom `mailglass` and the
    `{:dep, "== X.Y.Z"}` shape, so a `{:mailglass_inbound, "~> 0.2"}` entry is
    structurally invisible to it (confirmed High-confidence by research). A `==` linked
    pin would write an unsatisfiable `== 1.2.0` into a package on the 0.2.x line and
    break the sibling-group Hex publish at Phase 50.5. A non-optional dep would force
    every dev-preview-only admin adopter to pull inbound + its `ex_aws`/`gen_smtp`
    deps and configure a repo.
- **D-48-02:** **Do NOT add `MailglassInbound` to the Boundary `deps:` list.** Keep
  `mailglass_admin.ex`'s `use Boundary, deps: [Mailglass], exports: [Router]`
  **unchanged.** Gate *all* inbound access at runtime through a new
  `MailglassAdmin.OptionalDeps.MailglassInbound` gateway: `Code.ensure_loaded?/1`
  guard + `apply/3` call sites + `@compile {:no_warn_undefined, [...]}`. Mirror the
  two in-repo precedents exactly: core's Oban gating (`lib/mailglass.ex:55-60`) and
  admin's `MailglassAdmin.OptionalDeps.PhoenixLiveReload`
  (`mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex`).
  - Rationale: research (High confidence) traced Boundary 0.10.4 source — listing an
    *absent* app in `deps:` returns `nil` from `Boundary.get/2` and emits an
    `unknown_dep` error (`deps/boundary/lib/boundary/checker.ex:24-61`), which breaks
    the mandatory `mix compile --no-optional-deps --warnings-as-errors` lane (inbound
    stripped). Boundary has no per-dep "may be absent" option; `check: [out: ...]` is
    too broad and can't coexist with sub-boundaries. NOT listing the dep means calls
    are unrestricted by default — no edge to resolve, nothing to break.
- **D-48-03:** The **entire inbound admin surface is gated behind
  `MailglassAdmin.OptionalDeps.MailglassInbound.available?/0`**: the `InboundLive`
  module body, the `/admin/inbound` live route, and the nav link all no-op / are
  omitted when `mailglass_inbound` is absent. `available?/0` checks
  `Code.ensure_loaded?(MailglassInbound)` (or a concrete inbound module such as
  `MailglassInbound.InboundRecords.InboundRecord`).

### Inbound read-model location + tenancy
- **D-48-04:** Inbound DATA access lives **in `mailglass_inbound` as `@moduledoc false`
  internal modules** (e.g. `MailglassInbound.Internal.Operator.*`, matching the
  existing `MailglassInbound.Internal.Replay` posture), **NOT** by querying inbound
  Ecto schemas directly from admin. Queries run through `MailglassInbound.Repo` (host-
  repo facade: `all/2`, `one/3`, `get/3`), apply `Mailglass.Tenancy.scope/2`, and are
  **tenant-required-or-empty** (blank/missing tenant returns `[]`, never a cross-tenant
  leak — mirrors `OperatorLive.load_deliveries/1`).
  - Rationale: mirrors the locked outbound precedent — `OperatorLive` reads via
    `Mailglass.Operator.{Deliveries,Timeline,ReplayHistory,…}`, never raw schemas
    (`lib/mailglass/operator/deliveries.ex:18-50` is the canonical tenant-required +
    `Tenancy.scope/2` + `select` projection shape). Inbound has *zero* `Tenancy.scope`
    usage today (grep-confirmed). Using `Internal.*` keeps inbound's narrow documented
    0.x public API (6 stable modules) uncommitted to a new operator surface while still
    placing tenancy logic in the owning package.
  - Considered + rejected: (A) admin owns the queries — breaks the "data access in the
    owning package" precedent and forces tenancy into admin; (B) a *public*
    `MailglassInbound.Operator.*` surface — expands the 0.x stable contract prematurely.
- **D-48-05:** Admin enforces the **tenant gate before any record-mutating internal
  call.** `MailglassInbound.Internal.Replay.replay/2` loads by `id` only and does NOT
  tenant-scope (`internal/replay.ex:30-38`), so `InboundLive` MUST verify the record
  belongs to the active tenant scope *before* invoking replay — otherwise an operator
  scoped to tenant A could replay tenant B's record by guessing a UUID.

### Routing-trace reflection (IADM-04 — the novel surface)
- **D-48-06:** Add an **`@moduledoc false` per-clause reflection function to
  `mailglass_inbound`** (e.g. `MailglassInbound.Router.Matcher.explain/2`, or a small
  `Router.Trace` module) returning a structured per-clause verdict list, e.g.
  `[{:recipient, expected, actual, pass?}, {:subject, expected, actual, pass?},
  {:header, name, expected, actual, pass?}]`. It **reuses the same predicates** that
  `matches_route?/2` uses (single source of truth) so the rendered verdict always
  matches real routing behavior.
  - Rationale: today only the boolean `matches_route?/2` is public
    (`router/matcher.ex:31`); the per-dimension predicates `matches_matcher?/2`
    (lines 45-48) and `matches_headers?/2` (line 37) are `defp` and uncallable from
    admin. The Route struct is finite — exactly 4 fields (`mailbox`, `recipient`,
    `subject`, `headers`; `router/route.ex:7-14`) and 3 matcher kinds (`nil`=wildcard,
    exact `String.t()`, `Regex.t()`) — so a thin `explain/2` over the same predicates
    is low-risk. ROADMAP "Hardest sub-tasks" + UI-SPEC both mandate reusing matcher
    internals; the internals needed are private, so they must be exposed via reflection.
  - Considered + rejected: re-implementing matcher semantics in the admin view (silent
    divergence risk — the exact bug the UI-SPEC forbids).
- **D-48-07:** The admin discovers the adopter's routes via an **explicit
  `:inbound_router` (or `:inbound_routes`) option on the admin's
  `mailglass_operator_routes/2` macro, threaded into the LiveView session/assigns
  alongside `:auth`.** No new global `Application` config singleton.
  - Rationale: routes are supplied **per-request** to the ingress plug via opts
    (`plug.ex` `:router`/`:routes`; resolved in `persist.ex:281-287` via
    `opts[:router].__mailglass_inbound_routes__()`); there is no
    `Application.get_env(:mailglass_inbound, :router|:routes)` anywhere (grep-confirmed),
    so the LiveView has no ambient way to know the router at render time. Threading an
    explicit option mirrors how `:auth` is already threaded and avoids a global
    singleton (CLAUDE.md discourages `name: __MODULE__`-style singletons).
  - **Adopter-visible:** this is the one new adopter-facing config the phase introduces
    — without it the routing-trace card renders an empty route list. Document it in the
    Phase 50 install/routing-debug guide.
  - Considered + rejected: `config :mailglass_inbound, :router` global config — expands
    inbound's config contract and overlaps the existing per-request opt resolution.

### Replay + capability gates
- **D-48-08:** Replay runs through `MailglassInbound.Internal.Replay.replay(record_id,
  opts)` (`internal/replay.ex:13-28`), which calls `Execution.execute(payload,
  source: :replay)` and appends a new `ExecutionRun` (append-only — never UPDATE). Its
  structured error reasons map directly to the UI-SPEC's composed copy
  (`:not_found`; `{:replay_mailbox_missing, ...}` → "Replay blocked: mailbox module not
  found.").
- **D-48-09:** New capability atoms `:replay_inbound` and `:reveal_raw` ride the
  **existing `MailglassAdmin.Auth.authorize/3` adapter seam** — the action type is
  `:operator_access | :destructive_action | atom()` (`auth.ex:33`), so arbitrary atoms
  are accepted with **NO new auth module, plug, or behaviour callback.**
- **D-48-10:** Add a **thin inbound sibling `MailglassAdmin.Inbound.DestructiveAction`**
  (inbound-shaped context, e.g. `%{actor:, inbound_record:}`, action `:replay_inbound`)
  rather than reusing the outbound `operator/destructive_action.ex` verbatim.
  - Rationale: the outbound module hard-codes `:delivery`/`:replay_target` context keys
    (`destructive_action.ex:18-22`); adopter `Auth` implementations may pattern-match
    `%Mailglass.Outbound.Delivery{}`. Passing an inbound record under `:delivery` would
    either leak the wrong struct or break adopter auth. A sibling keeps the shipped
    outbound helper untouched and matches the UI-SPEC "sibling, not refactor" rule.

### PubSub consumer + nav mounting + component clones
- **D-48-11:** Phase 45's inbound broadcast already landed (verified:
  `mailglass_inbound/.../ingress/plug.ex` broadcasts `{:inbound_record_inserted,
  record_id, %{provider:, record_type:}}` post-commit on the **shared `Mailglass.PubSub`
  server** via `MailglassInbound.PubSub.Topics.inbound_record_inserted/1` →
  `"mailglass:inbound:" <> tenant_id`). Phase 48 adds **only the consumer side**: a new
  `inbound_record_inserted/1` builder in `MailglassAdmin.PubSub.Topics` producing the
  **identical string**, and `InboundLive` subscribes on mount. Both builders satisfy
  LINT-06 PrefixedPubSubTopics. New records **prepend to the list without stealing the
  current selection or resetting filters.**
- **D-48-12:** `/admin/inbound` mounts in the **existing operator `live_session`**
  (with `MailglassAdmin.Operator.Mount` + the `MailglassAdmin.Auth` gate), NOT the
  dev-preview session — additionally gated by `available?/0` (D-48-03). A nav link is
  added to the existing admin nav. **No new auth surface.**
  - If wrong: mounting in the dev-preview `live_session` would bypass `MailglassAdmin.Auth`
    and expose tenant inbound data without authorization — a trust-boundary violation.
- **D-48-13:** Operator UI components are **cloned as `MailglassAdmin.Inbound.*`
  siblings** (per UI-SPEC "sibling, not refactor"), not parameterized for both surfaces.
  **Promote `mask_recipient/1` to a public `MailglassAdmin.Components` helper** (one
  audited PII-masking definition) rather than duplicating the `defp` currently private
  to `operator/deliveries_list.ex:98-100`. `Components.flash/1` and `Components.icon/1`
  are directly reusable as-is.

### Claude's Discretion
- Exact module names/signatures of the inbound read-model (`MailglassInbound.Internal.Operator.*`
  vs extending `InboundRecords`), the reflection fn (`Matcher.explain/2` vs a `Trace`
  module), and the admin optional-dep gateway — provided D-48-01..06 hold.
- Exact `InboundLive` filter/URL-param plumbing, list pagination, and assign shapes —
  clone `OperatorLive` mechanics.
- Whether `mask_recipient/1` promotion also pulls any sibling masking helpers up to
  `Components`, provided one canonical definition results.
- Plan/wave breakdown (UI hint: yes; ~3 plans per ROADMAP estimate).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope + locked posture
- `.planning/ROADMAP.md` — Phase 48 goal, success criteria #1-5, hardest sub-tasks.
- `.planning/REQUIREMENTS.md` — IADM-01..07 wording + IOPS-05 (suppression flag surfaced in IADM-02).
- `.planning/phases/48-inbound-admin-liveview/48-UI-SPEC.md` — **approved** visual/interaction contract (clone-of-OperatorLive, routing-trace + evidence card specs, copy strings).
- `.planning/PROJECT.md` — telemetry-no-PII, append-only, optional-dep gateway, tenancy-first, brand voice.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, recommendation-first.
- `.planning/phases/45-inbound-telemetry-idempotency-foundation/45-CONTEXT.md` — TELE-07 topic/broadcast contract (D-45-06/07/08) this phase consumes.

### Cross-package dependency / boundary / release-eng (D-48-01/02/03)
- `mailglass_admin/mix.exs` — `deps/0`, `mailglass_dep/0` MIX_PUBLISH branch (~lines 100-135), `elixirc_options` no_warn_undefined (~lines 69-71); where the optional inbound dep + local helper go.
- `release-please-config.json`, `.release-please-manifest.json` — linked-versions group (inbound excluded; 0.x line).
- `.github/workflows/release-please.yml:119-179` — the `PINS` array + sed pin step (keep inbound out).
- `mailglass_admin/lib/mailglass_admin.ex:45-47` — Boundary decl (leave UNCHANGED).
- `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex` — the gateway pattern to clone for `OptionalDeps.MailglassInbound`.
- `lib/mailglass.ex:55-60` — core Oban `Code.ensure_loaded?` + conditional gating precedent.
- `lib/mailglass/optional_deps.ex`, `lib/mailglass/optional_deps/gen_smtp.ex` — canonical `available?/0` gateway shape.
- `mailglass_admin/lib/mailglass_admin/router.ex:87-94` — existing `@compile {:no_warn_undefined, ...}` precedent.

### Outbound admin to clone (UI-SPEC siblings)
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — master/detail shell, URL-param state, `load_deliveries/1:338` tenant-required-or-empty contract.
- `mailglass_admin/lib/mailglass_admin/operator/{deliveries_list,detail_header,timeline,replay_modal,filters_form,destructive_action,mount}.ex` — components to clone; `mask_recipient/1` at `deliveries_list.ex:98-100`.
- `mailglass_admin/lib/mailglass_admin/auth.ex:33` — `authorize/3` action type accepts `atom()` (capability gates).
- `mailglass_admin/lib/mailglass_admin/components.ex` — `flash/1`, `icon/1` (reusable); `mask_recipient/1` promotion target.
- `mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex` — admin consumer topic module (add `inbound_record_inserted/1`).
- `mailglass_admin/lib/mailglass_admin/router.ex` — `mailglass_operator_routes/2` macro (add `:inbound_router` option + `/inbound` live route).

### Outbound read-model precedent (D-48-04)
- `lib/mailglass/operator/deliveries.ex:18-50` — tenant-required + `Tenancy.scope/2` + projection shape to mirror for the inbound read-model.
- `lib/mailglass/operator/timeline.ex` — timeline read-model precedent.
- `lib/mailglass/tenancy.ex` — `scope/2` behaviour applied to every inbound query.

### Inbound internals to consume / extend
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` — `matches_route?/2` (public, l.31) + `defp matches_matcher?/2` (l.45-48), `defp matches_headers?/2` (l.37); add `explain/2` reflection here (D-48-06).
- `mailglass_inbound/lib/mailglass_inbound/router/route.ex:7-14` — 4-field Route struct (the diff data model).
- `mailglass_inbound/lib/mailglass_inbound/router.ex:64-72` — `__mailglass_inbound_routes__/0` reflection entry point.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` — per-request `:router`/`:routes` opt resolution; post-commit broadcast site (verify D-48-11).
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:281-287` — route resolution from opts.
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex:13-38` — `replay/2` (no tenant scope — admin gates first, D-48-05/08).
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` — `execute/2` + `source: :replay`.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/{inbound_record,inbound_evidence,execution_run,replay_run}.ex` — schemas to read; `ExecutionRun.__outcomes__/0` for the filter select; `raw_payload`/`raw_mime` `redact: true` (inbound_evidence.ex).
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` — package-local persistence boundary (read-model lives near here or under `Internal.Operator.*`).
- `mailglass_inbound/lib/mailglass_inbound/repo.ex` — host-repo facade (`all/2`, `one/3`, `get/3`).
- `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex:33-34` — `inbound_record_inserted/1` (the string the admin builder must match).

### Conventions to satisfy
- `credo_checks/prefixed_pub_sub_topics.ex` (LINT-06) — both topic builders must pass.
- `.credo.exs` — how checks are path-scoped across packages (relevant if a tenant-scope Credo check is added per ROADMAP hardest sub-task — optional this phase).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `OperatorLive` + its `operator/*` components are a complete structural template for
  the inbound master/detail (clone as `MailglassAdmin.Inbound.*` siblings).
- `Mailglass.Operator.{Deliveries,Timeline,…}` is the exact tenant-scoped read-model
  shape to mirror for the inbound read-model (tenant-required + `Tenancy.scope/2` + projection).
- `MailglassAdmin.OptionalDeps.PhoenixLiveReload` + core's Oban gating are the
  copy-paste precedents for the new `OptionalDeps.MailglassInbound` gateway.
- `MailglassAdmin.Auth.authorize/3` already accepts arbitrary `atom()` actions — the
  capability gates need zero new auth surface.
- Phase 45 already ships the inbound-side broadcast + topic builder on the shared
  `Mailglass.PubSub` server — the admin only adds the consumer-side builder + subscribe.
- `MailglassInbound.Internal.Replay.replay/2` + `Execution.execute(source: :replay)`
  already implement append-only replay — admin wraps it with a tenant gate + modal.
- `Router.Matcher` predicates already encode the canonical matcher semantics — expose
  them via `explain/2` rather than re-implementing.

### Established Patterns
- Optional deps gated through a single `*.OptionalDeps.*` module: `Code.ensure_loaded?`
  + `available?/0` + `apply/3` call sites + `@compile {:no_warn_undefined, ...}`. Bare
  references to absent deps break `mix compile --no-optional-deps --warnings-as-errors`.
- Boundary edges are explicit `deps:`; an absent cross-package app must NOT be listed
  (emits `unknown_dep`) — route through runtime `apply/3` instead.
- Admin is a pure consumer of core/inbound; data access + tenancy live in the owning package.
- PubSub: typed `mailglass:`-prefixed per-tenant topic builders only (LINT-06).
- Append-only inbound tables — replay APPENDS rows, never UPDATEs.
- Tenant-required-or-empty: every operator query through `Tenancy.scope/2`; blank tenant → `[]`.
- PII discipline: mask recipient/sender by default; raw payload redacted until `:reveal_raw`.

### Integration Points
- `mailglass_admin/mix.exs` `deps/0` → `{:mailglass_inbound, "~> 0.2", optional: true}` (floating).
- New `MailglassAdmin.OptionalDeps.MailglassInbound` → `MailglassInbound` (runtime gate).
- `InboundLive` → inbound read-model (`MailglassInbound.Internal.Operator.*`) via `apply/3`.
- `InboundLive` routing-trace → `MailglassInbound.Router.Matcher.explain/2` (new) + the
  adopter router threaded via the `:inbound_router` macro option.
- `InboundLive` replay → `MailglassInbound.Internal.Replay.replay/2` (admin tenant-gates first).
- `InboundLive` subscribe → `Mailglass.PubSub` @ `MailglassAdmin.PubSub.Topics.inbound_record_inserted/1`.
- `/admin/inbound` live route → existing operator `live_session` (Auth gate) via the `router.ex` macro.

</code_context>

<specifics>
## Specific Ideas

- Mental model: this phase is the **observability sibling of `OperatorLive`** for
  inbound — clone the shell, reuse the read-model discipline, and add exactly one novel
  surface (the routing-trace card). The hard part is plumbing, not UI.
- The single highest-leverage decision is D-48-01/02: the dependency is **optional and
  runtime-gated**, with the Boundary `deps:` list left untouched. Research confirmed
  (High) that the obvious-looking move (add inbound to Boundary `deps:` / use a `==`
  pin) breaks both the no-optional-deps CI lane and the Phase 50.5 Hex publish.
- Two adopter-visible surfaces this phase introduces: the optional install line
  (`{:mailglass_inbound, "~> 0.2", optional: true}`) and the `:inbound_router` mount
  option (required for the routing-trace card to populate). Both belong in the Phase 50
  install + routing-debug guides.
- Tenant-boundary correctness is a structural invariant in two places: the read-model
  (tenant-required-or-empty) and the replay path (admin tenant-gates the record before
  calling the un-scoped `Internal.Replay.replay/2`).

</specifics>

<deferred>
## Deferred Ideas

- A Credo check asserting no `MailglassAdmin.Inbound*` module queries inbound tables
  without `Mailglass.Tenancy.scope/2` (ROADMAP hardest sub-task) — valuable regression
  guard, but optional for this phase; can land here or in Phase 51 closeout. Noted, not
  scoped.
- Promoting the inbound read-model from `Internal.*` to a documented public
  `MailglassInbound.Operator.*` API — only when inbound approaches its 1.0 line
  (Conductor + relay providers), not during 0.x.
- A global `config :mailglass_inbound, :router` registration (also usable to simplify
  the ingress plug's per-request opt) — larger inbound-config decision, deferred.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 48 scope.

</deferred>

---

*Phase: 48-inbound-admin-liveview*
*Context gathered: 2026-05-24 (assumptions mode)*
