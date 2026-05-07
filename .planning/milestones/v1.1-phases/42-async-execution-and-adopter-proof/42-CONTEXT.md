# Phase 42: Async Execution And Adopter Proof - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the first `mailglass_inbound` slice operationally credible without
expanding the product boundary: add Oban-backed async execution, define the
supported bounded non-Oban fallback, and publish one canonical install,
testing, replay, and operator-trust lane for adopters.

This phase does not add a public replay API, a Conductor-style UI, a hardened
operator LiveView surface, broader provider parity, or a bespoke durable queue
that competes with Oban.

</domain>

<decisions>
## Implementation Decisions

### Async execution contract
- **D-42-01:** Oban is the canonical durable async execution path for
  `mailglass_inbound`.
- **D-42-02:** The non-Oban fallback should remain post-persistence background
  execution via `Task.Supervisor`, not inline request-path execution.
- **D-42-03:** The fallback must be documented as best-effort only:
  - no durable enqueue
  - no automatic retries/backoff
  - work may be lost on node crash or shutdown
  - replay/operator action is the recovery path
- **D-42-04:** Do not silently change adopter semantics based on runtime mode.
  The contract should stay “persist truth first, then execute asynchronously”
  in both modes, with durability differing only in the documented execution
  mechanism.
- **D-42-05:** Inline request-path execution when Oban is absent is rejected
  because it couples mailbox cost to webhook latency, increases provider retry
  confusion, and violates least surprise once Oban mode is async.
- **D-42-06:** A bespoke durable non-Oban queue is out of scope for this
  phase. Rebuilding a subset of Oban would create a new subsystem, not a
  bounded fallback.
- **D-42-07:** The internal execution seam should preserve one mailbox
  contract and one execution-lineage truth model across:
  - fresh Oban-backed execution
  - fresh Task.Supervisor fallback execution
  - internal replay execution
- **D-42-08:** Failure handling should follow the existing boundary:
  mailbox outcomes are semantic results; raises/exits/throws/invalid return
  shapes are execution failures recorded in append-only lineage.

### Adopter setup and install story
- **D-42-09:** Phase 42 should be docs-first for `mailglass_inbound` adoption,
  not installer-first.
- **D-42-10:** Do not extend `mix mailglass.install` for inbound in this phase.
  Current inbound setup still depends on adopter-owned choices that the library
  cannot honestly infer:
  - route path and tenant segment shape
  - provider mount mix
  - endpoint/parser placement
  - Oban-vs-fallback runtime posture
  - host-app testing conventions
- **D-42-11:** The canonical adopter lane should be one explicit manual setup
  path covering:
  - dependency/install steps
  - repo and migration requirements
  - router mounting for Postmark and SendGrid
  - `Plug.Parsers` / body-reader wiring
  - Oban-backed runtime wiring
  - non-Oban fallback semantics
  - testing and replay verification expectations
- **D-42-12:** Minimal doc touch-up is insufficient. Phase 42 must ship a
  coherent onboarding and support story, not scattered provider notes.

### Operator trust and replay posture
- **D-42-13:** Phase 42 should prove inbound replay and execution trust through
  docs and verification, not by productizing a new operator surface.
- **D-42-14:** Keep replay internal in this phase. Do not publish a stable
  public replay API yet.
- **D-42-15:** Do not start an inbound operator UI or Conductor-style surface
  in this phase. That work requires separate decisions around auth, audit,
  exact-target selection, ambiguity handling, and stable operator semantics.
- **D-42-16:** The operator-trust docs must be explicit about what replay is
  and is not:
  - replay reruns mailbox processing against stored canonical plus evidence
    truth
  - replay is not a fresh provider receive
  - replay does not silently reroute to a different mailbox
  - replay may fail when prior fresh execution lineage is missing or only
    `:no_match` history exists
- **D-42-17:** The user-facing trust story should emphasize honest recoverability
  over speculative breadth:
  - what durable truth exists
  - what execution guarantees differ with and without Oban
  - how adopters test the supported paths
  - how operators diagnose duplicate, failed, and replayed runs

### Recommendation-first downstream posture
- **D-42-18:** Downstream research, planning, and execution for Mailglass
  should continue the recommendation-first posture already established in prior
  phases and in `.planning/METHODOLOGY.md`.
- **D-42-19:** Default to one coherent recommendation set when repo patterns,
  ecosystem precedent, and milestone scope already point to an obvious answer.
  Escalate only if a choice is likely to materially change:
  - the stable public contract
  - tenant or security boundaries
  - replay/audit truth semantics
  - irreversible maintainer/support burden
  - a user-visible workflow default the project owner is especially likely to
    care about directly
- **D-42-20:** For this phase specifically, the default recommendation set is:
  - Oban-backed async as the durable path
  - `Task.Supervisor` fallback as the bounded non-Oban path
  - docs-first adoption instead of installer expansion
  - docs-plus-verification trust proof instead of public replay/API/UI growth

### the agent's Discretion
- Exact internal module names for inbound workers, fallback dispatch helpers,
  and shared execution orchestration.
- Exact Oban worker/job argument shape, queue naming, and retry tuning, as long
  as no `%Oban.Job{}` details leak into the stable public contract.
- Exact boot/runtime warning copy for non-Oban installs, as long as it is
  explicit about best-effort semantics.
- Exact doc split across README, guides, API stability inventory, and test
  guides, as long as adopters get one coherent canonical lane.

</decisions>

<specifics>
## Specific Ideas

- The right mental model is: “Swoosh-style lightweight async fallback, Oban for
  durable async, Action Mailbox-style durable truth first.”
- The fallback should feel like outbound `mailglass`: useful and honest, not a
  fake queue.
- The best adopter experience is one obvious manual path with sharp-edge docs,
  not scaffolding that guesses wrong and becomes support debt.
- The best operator-trust move now is to explain replay and execution truth
  precisely, then prove it with tests, rather than freezing a public replay/UI
  contract too early.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked posture
- `.planning/ROADMAP.md` — Phase 42 goal, plan split, and deferred boundary.
- `.planning/PROJECT.md` — `v1.1` narrow-slice posture, optional-Oban
  philosophy, and package-honesty constraint.
- `.planning/REQUIREMENTS.md` — `EXEC-01`, `EXEC-02`, and `ADOPT-01`.
- `.planning/STATE.md` — current milestone position after Phase 41.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, and
  recommendation-first posture.
- `.planning/phases/39-inbound-package-foundation/39-CONTEXT.md` — locked
  mailbox contract, replay boundary, and optional-Oban seam intent.
- `.planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md`
  — locked ingress/storage/replay truth posture.
- `.planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-CONTEXT.md` —
  locked execution-lineage, replay-honesty, and deferred async/UI boundary.

### Existing local code and docs
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` — current
  persist-then-execute ingress orchestration.
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` — durable
  canonical/evidence truth boundary and duplicate handling.
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` — current execution
  classification and append-only run recording.
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` — current
  replay semantics and sharp edges that remain internal.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` — normalized
  execution/replay lineage API.
- `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` — package-local
  optional Oban gateway.
- `mailglass_inbound/README.md` — current package posture and deferred items.
- `mailglass_inbound/docs/api_stability.md` — stable/internal/deferred surface
  inventory that must stay honest in Phase 42.
- `mailglass_inbound/docs/postmark_ingress.md` — current Postmark setup story.
- `mailglass_inbound/docs/sendgrid_ingress.md` — current SendGrid setup and
  replay posture.
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` — config
  and ordering footguns, especially body-reader wiring.
- `mailglass_inbound/test/mailglass_inbound/replay_test.exs` — replay behavior
  and failure cases that docs must explain.
- `lib/mailglass/outbound.ex` — existing Oban-vs-TaskSupervisor precedent.
- `lib/mailglass/optional_deps/oban.ex` — current optional-dependency gateway
  pattern.
- `lib/mailglass/application.ex` — current boot-warning posture for
  Oban-absent installs.
- `mailglass_admin/docs/operator-trust.md` — precedent for honest operator
  semantics and replay wording.
- `lib/mailglass/webhook/replay.ex` — precedent for how much machinery a
  stable operator-facing replay surface actually needs.
- `.github/workflows/release-please.yml` — current linked-version and sibling
  package release automation posture.

### Official ecosystem references
- `https://hexdocs.pm/oban/Oban.Worker.html` — worker contract, retries, and
  failure semantics for the durable async path.
- `https://hexdocs.pm/oban/error_handling.html` — retry and failure recording
  posture.
- `https://hexdocs.pm/elixir/Task.Supervisor.html` — supervised task semantics
  for the bounded non-durable fallback.
- `https://hexdocs.pm/swoosh/Swoosh.html` — lightweight async guidance and the
  warning that durable async should use a real job system.
- `https://hexdocs.pm/plug/Plug.Parsers.html` — `:body_reader` behavior and
  multipart caveats.
- `https://guides.rubyonrails.org/action_mailbox_basics.html` — durable
  inbound record, async routing, statuses, setup flow, and conductor lessons.
- `https://anymail.dev/en/stable/inbound/` — retry/duplicate cautions and
  advice to queue slow inbound processing instead of doing too much inline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MailglassInbound.Execution` already normalizes mailbox outcomes and
  execution failures into append-only run truth.
- `MailglassInbound.Internal.Replay` already proves the package can rerun
  mailbox logic against stored truth without re-ingesting provider payloads.
- `MailglassInbound.OptionalDeps.Oban` already provides the right package-local
  gateway seam for optional Oban support.
- Core `mailglass` already ships the precedent for “Oban when available,
  `Task.Supervisor` when absent” plus warning posture.

### Established Patterns
- Persist durable truth before side effects.
- Keep public contracts narrower than implementation reachability.
- Treat replay as a linked rerun over stored truth, not as fake fresh receive.
- Use optional-dependency gateways instead of scattering direct `Oban`
  references across the codebase.
- Prefer honest docs and supportable defaults over broader but speculative DX.

### Integration Points
- Phase 42 async work should plug into the existing ingress persistence result,
  not redesign the ingress contract.
- Oban-backed fresh execution and Task.Supervisor fallback should share the
  same mailbox contract and execution-lineage persistence path.
- Adoption docs should connect provider guides, execution mode semantics,
  replay truth, and release-proof verification into one canonical lane.

</code_context>

<deferred>
## Deferred Ideas

- Public replay API for inbound.
- Inbound operator UI or Conductor-style replay/dev surface.
- Extending `mix mailglass.install` to scaffold inbound setup.
- A bespoke durable non-Oban queue/recovery subsystem.
- Broader provider parity beyond Postmark and SendGrid.

</deferred>

---

*Phase: 42-async-execution-and-adopter-proof*
*Context gathered: 2026-05-06*
