# Phase 42: Async Execution And Adopter Proof - Research

**Researched:** 2026-05-06 [VERIFIED: local system date]  
**Domain:** `mailglass_inbound` async execution, bounded fallback semantics, adopter/operator docs, and sibling-package release proof [VERIFIED: .planning/ROADMAP.md, .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: repo code, local environment probes, official docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from `42-CONTEXT.md`. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md]

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- Public replay API for inbound.
- Inbound operator UI or Conductor-style replay/dev surface.
- Extending `mix mailglass.install` to scaffold inbound setup.
- A bespoke durable non-Oban queue/recovery subsystem.
- Broader provider parity beyond Postmark and SendGrid.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXEC-01 | Adopter can execute inbound routing asynchronously through Oban when Oban is installed and configured. [VERIFIED: .planning/REQUIREMENTS.md] | Use an internal Oban worker that accepts JSON-safe identifiers only, restores tenant scope, reloads canonical/evidence truth by id, runs the shared execution classifier, and returns Oban-native success/error tuples without exposing `%Oban.Job{}` in any stable package API. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/execution.ex, mailglass_inbound/lib/mailglass_inbound/internal/replay.ex, mailglass_inbound/lib/mailglass_inbound/optional_deps.ex, lib/mailglass/outbound/worker.ex][CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| EXEC-02 | Adopter can execute the same logical mailbox contract through a supported bounded fallback when Oban is absent. [VERIFIED: .planning/REQUIREMENTS.md] | Keep the fallback post-persistence and asynchronous via `Task.Supervisor.start_child/3`; document and test it as best-effort only, with no retries or durable queue, and use replay as the recovery path after node loss or shutdown. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md, lib/mailglass/outbound.ex, lib/mailglass/application.ex][CITED: https://hexdocs.pm/elixir/Task.Supervisor.html][CITED: https://hexdocs.pm/swoosh/Swoosh.html] |
| ADOPT-01 | Adopter can install, configure, test, and support the core inbound slice through honest first-party docs and verification lanes. [VERIFIED: .planning/REQUIREMENTS.md] | Publish one canonical setup lane that covers repo config, migrations, ingress mounts, Plug parser/body-reader wiring, Postmark and SendGrid provider specifics, durable-vs-best-effort execution semantics, replay truth, and root CI/release proof for `mailglass_inbound`. [VERIFIED: mailglass_inbound/README.md, mailglass_inbound/docs/api_stability.md, mailglass_inbound/docs/postmark_ingress.md, mailglass_inbound/docs/sendgrid_ingress.md, .github/workflows/release-please.yml, .github/workflows/publish-hex.yml][CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email][CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep optional dependencies behind gateway modules and preserve `mix compile --no-optional-deps --warnings-as-errors` as a hard constraint. [VERIFIED: CLAUDE.md, mailglass_inbound/lib/mailglass_inbound/optional_deps.ex, mailglass_inbound/mix.exs]  
- Do not expose `%Oban.Job{}` or other implementation details as part of the public contract; Mailglass treats errors and public return shapes as contract, not internals. [VERIFIED: CLAUDE.md, lib/mailglass/outbound.ex, mailglass_inbound/docs/api_stability.md]  
- Preserve multi-tenant truth boundaries and keep `tenant_id` explicit on execution and persistence objects. [VERIFIED: CLAUDE.md, mailglass_inbound/lib/mailglass_inbound/execution.ex, mailglass_inbound/lib/mailglass_inbound/internal/replay.ex]  
- Prefer honest docs over speculative breadth; Phase 42 must not claim installer automation, public replay APIs, or operator UI that do not exist. [VERIFIED: CLAUDE.md, .planning/METHODOLOGY.md, .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md]  
- Maintain linked-version sibling-package release discipline; Phase 42 research must not recommend a release path that contradicts the project’s sibling-package posture. [VERIFIED: CLAUDE.md, .planning/PROJECT.md, .github/workflows/release-please.yml]  

## Summary

Phase 42 should be planned as three tightly coupled deliverables: one internal async execution seam that can enqueue durable work through Oban, one explicit best-effort fallback seam through `Task.Supervisor`, and one adopter/operator proof lane that explains the exact difference between those modes without changing the public mailbox contract or pretending replay is a fresh receive. [VERIFIED: .planning/ROADMAP.md, .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md, mailglass_inbound/lib/mailglass_inbound/execution.ex, mailglass_inbound/lib/mailglass_inbound/internal/replay.ex]

The repo already contains the key building blocks: fresh ingress persists before execution, execution outcomes and failures normalize into append-only lineage, replay reruns mailbox logic over stored truth, and outbound Mailglass already proves the house pattern for “Oban when available, `Task.Supervisor` when absent, never return `%Oban.Job{}` publicly.” [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex, mailglass_inbound/lib/mailglass_inbound/execution.ex, mailglass_inbound/lib/mailglass_inbound/internal/replay.ex, lib/mailglass/outbound.ex, lib/mailglass/application.ex]

The decisive recommendation is to split Phase 42 around one shared internal runner contract: ingress persists canonical and evidence rows, then dispatches either an Oban job or a supervised task that later reloads those rows and calls the same execution classifier. Oban owns durable retries and backoff; the fallback owns only immediate background handoff and logging. Docs and tests must make that difference explicit, and release/CI automation must be expanded because `mailglass_inbound` is not yet included in root release-please or publish workflows. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex, mailglass_inbound/lib/mailglass_inbound/optional_deps.ex, mailglass_inbound/mix.exs, .github/workflows/release-please.yml, .github/workflows/publish-hex.yml][CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/elixir/Task.Supervisor.html]

**Primary recommendation:** plan Phase 42 as `persist truth -> dispatch via Oban or Task.Supervisor -> reload stored truth -> run shared mailbox classifier -> append execution lineage`, then ship one canonical manual setup/trust lane and extend root verification/release automation to include `mailglass_inbound`. [VERIFIED: .planning/ROADMAP.md, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex, mailglass_inbound/lib/mailglass_inbound/execution.ex, .github/workflows/release-please.yml, .github/workflows/ci.yml]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Inbound HTTP entrypoint and parser/body-reader wiring | Frontend Server (SSR) | API / Backend | The adopter’s Phoenix endpoint/router owns route mounting and `Plug.Parsers` configuration, including the Postmark `:body_reader` seam and SendGrid multipart parser path. [VERIFIED: mailglass_inbound/docs/postmark_ingress.md, mailglass_inbound/docs/sendgrid_ingress.md, mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| Request verification and tenant resolution | API / Backend | Frontend Server (SSR) | Verification and tenancy are backend concerns, but they depend on the request data captured at the mounted Plug seam. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex] |
| Canonical/evidence persistence | Database / Storage | API / Backend | The durable truth boundary is package-local Postgres storage mediated through the host Repo facade. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records.ex, mailglass_inbound/lib/mailglass_inbound/repo.ex] |
| Async dispatch decision | API / Backend | Database / Storage | The backend chooses Oban or `Task.Supervisor` only after durable persistence has succeeded. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md, lib/mailglass/outbound.ex] |
| Durable job execution | API / Backend | Database / Storage | Oban workers consume DB-backed jobs, reload persisted truth, and retry based on worker result semantics. [VERIFIED: lib/mailglass/outbound/worker.ex][CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Best-effort fallback execution | API / Backend | — | `Task.Supervisor` only supervises a side-effecting task process; it does not provide durable storage or automatic retry. [VERIFIED: lib/mailglass/outbound.ex, lib/mailglass/application.ex][CITED: https://hexdocs.pm/elixir/Task.Supervisor.html][CITED: https://hexdocs.pm/swoosh/Swoosh.html] |
| Replay and operator trust explanation | API / Backend | Database / Storage | Replay semantics derive from stored canonical/evidence truth and stored execution lineage, not from provider receive paths. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/internal/replay.ex, mailglass_admin/docs/operator-trust.md] |
| Release and verification proof | Frontend Server (SSR) | API / Backend | CI/workflow automation and docs-contract proof live in repo automation and package docs, not in request-path runtime code. [VERIFIED: .github/workflows/ci.yml, .github/workflows/release-please.yml, .github/workflows/publish-hex.yml, mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `oban` | declared `~> 2.21`, locked `2.21.1`, latest `2.22.1` released `2026-04-30` [VERIFIED: mailglass_inbound/mix.exs, mix.lock, `mix hex.info oban`] | Canonical durable async execution path | Oban gives DB-backed enqueue, retries, worker result semantics, job lifecycle states, and backoff without forcing `%Oban.Job{}` into the public API. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md, lib/mailglass/outbound/worker.ex][CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| `Task.Supervisor` | Elixir `1.19.5` stdlib [VERIFIED: local env probe] | Supported bounded non-Oban fallback | `Task.Supervisor.start_child/3` is the standard fire-and-forget side-effect path when durability is not required, and its limits are explicit in the docs. [VERIFIED: lib/mailglass/outbound.ex, lib/mailglass/application.ex][CITED: https://hexdocs.pm/elixir/Task.Supervisor.html][CITED: https://hexdocs.pm/swoosh/Swoosh.html] |
| `plug` | declared `~> 1.18`, locked `1.19.1`, latest `1.19.1` released `2025-12-09` [VERIFIED: mix.exs, mix.lock, `mix hex.info plug`] | Ingress parser/body-reader contract | Phase 42 docs must explain the provider-specific parser split accurately: `:body_reader` works for Postmark JSON, but Plug documents that it is not used by `Plug.Parsers.MULTIPART`. [VERIFIED: mailglass_inbound/docs/postmark_ingress.md, mailglass_inbound/docs/sendgrid_ingress.md][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| `ecto_sql` | declared `~> 3.13`, locked `3.13.5` [VERIFIED: mix.exs, mailglass_inbound/mix.exs, mix.lock] | Persisted truth and lineage writes | Phase 42 must continue the current “persist first, then execute” write boundary and append-only execution recording. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records.ex] |
| `swoosh` precedent | declared `~> 1.25`, locked `1.25.0`, latest `1.25.1` released `2026-04-29` [VERIFIED: mix.exs, mix.lock, `mix hex.info swoosh`] | House precedent for honest lightweight fallback docs | Swoosh’s docs explicitly position `Task.Supervisor` as a simple async path and recommend a queue/job system for safer durable async, which matches the locked Phase 42 posture. [CITED: https://hexdocs.pm/swoosh/Swoosh.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `MailglassInbound.OptionalDeps.Oban` | repo-local [VERIFIED: mailglass_inbound/lib/mailglass_inbound/optional_deps.ex] | Optional-dependency gateway | Extend this module with enqueue helpers or runner classification rather than scattering direct `Oban` references across the package. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/optional_deps.ex, CLAUDE.md] |
| `Mailglass.Oban.TenancyMiddleware` pattern | repo-local [VERIFIED: lib/mailglass/optional_deps/oban.ex, lib/mailglass/outbound/worker.ex] | Tenant restoration across job boundaries | Reuse the outbound tenancy-serialization pattern for inbound worker args so background execution preserves `tenant_id` safely. [VERIFIED: lib/mailglass/optional_deps/oban.ex, lib/mailglass/outbound/worker.ex] |
| `mailglass_inbound` docs-contract tests | repo-local [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] | Adoption-proof regression gate | Use to lock the docs story for durable path, fallback semantics, replay truth, and deferred boundaries. [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] |
| Release Please linked versions | repo-local workflow [VERIFIED: .github/workflows/release-please.yml, release-please-config.json] | Sibling-package release proof | Extend the current root/admin-only release automation to include `mailglass_inbound`, or the package remains outside the repo’s canonical release lane. [VERIFIED: release-please-config.json, .release-please-manifest.json, .github/workflows/release-please.yml] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Internal Oban worker with JSON-safe ids only [VERIFIED: lib/mailglass/outbound/worker.ex] | Return `%Oban.Job{}` or expose worker args to adopters | That leaks transport mechanics into the stable contract and contradicts the project’s public-return-shape discipline. [VERIFIED: lib/mailglass/outbound.ex, mailglass_inbound/docs/api_stability.md] |
| `Task.Supervisor` fallback after persistence [VERIFIED: 42-CONTEXT.md] | Inline `Mailbox.process/1` in the request path | Inline execution changes provider latency semantics, conflates mailbox failure with webhook retry, and was explicitly rejected in locked decisions. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md] |
| Oban as the only durable queue [VERIFIED: 42-CONTEXT.md] | A bespoke durable fallback queue | That would create a new subsystem and reimplement queue semantics the project already decided to delegate to Oban. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md] |
| Manual docs-first setup lane [VERIFIED: 42-CONTEXT.md] | Extend `mix mailglass.install` now | The installer cannot honestly infer mount mix, parser placement, provider mix, or runtime posture yet, and Phase 42 explicitly rejects installer-first work. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-CONTEXT.md] |
| Extend root release/CI automation to cover `mailglass_inbound` [VERIFIED: .planning/ROADMAP.md] | Rely on package-local tests only | The sibling package would still be missing canonical root proof and publish automation, which makes adopter docs and release posture incomplete. [VERIFIED: .github/workflows/ci.yml, .github/workflows/release-please.yml, .github/workflows/publish-hex.yml] |

**Installation:**
```elixir
# host app mix.exs during current repo/dev integration
{:mailglass_inbound, path: "../mailglass_inbound"}
{:oban, "~> 2.21"} # optional; required only for durable async execution
```
[VERIFIED: mailglass_inbound/mix.exs]

**Version verification:** Keep Phase 42 on the repo’s existing dependency floor; plan code/docs changes, not dependency upgrades. `mailglass_inbound` already declares optional `oban "~> 2.21"`, the lockfile is on `2.21.1`, and current Hex shows `2.22.1` as the latest release dated `2026-04-30`. [VERIFIED: mailglass_inbound/mix.exs, mix.lock, `mix hex.info oban`]

## Architecture Patterns

### System Architecture Diagram

```text
Postmark JSON or SendGrid multipart inbound request
        |
        v
Phoenix route -> MailglassInbound.Ingress.Plug
        |
        v
verify request -> resolve tenant -> normalize -> persist canonical + evidence
        |
        +--> duplicate -> 200 acknowledged, no second execution
        |
        v
dispatch decision
        |
        +--> Oban available/configured
        |       |
        |       v
        |   insert inbound execution job
        |       |
        |       v
        |   worker reloads record + evidence -> shared execution runner
        |
        \--> Oban absent
                |
                v
            Task.Supervisor.start_child/3
                |
                v
            fallback task reloads record + evidence -> shared execution runner

shared execution runner
        |
        v
route/mailbox outcome classification
        |
        v
append execution lineage
  - source: fresh
  - mailbox
  - outcome / failure
  - replay stays separate and reuses same classifier
```
[VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex, mailglass_inbound/lib/mailglass_inbound/execution.ex, mailglass_inbound/lib/mailglass_inbound/internal/replay.ex, lib/mailglass/outbound.ex]

### Recommended Project Structure

```text
mailglass_inbound/
├── lib/mailglass_inbound/application.ex          # warning posture + Task.Supervisor child if package-local
├── lib/mailglass_inbound/async.ex                # dispatch orchestration (Oban vs fallback)
├── lib/mailglass_inbound/execution.ex            # shared mailbox classification + lineage persistence
├── lib/mailglass_inbound/execution/worker.ex     # conditional Oban worker
├── lib/mailglass_inbound/ingress/plug.ex         # persist then dispatch
├── lib/mailglass_inbound/internal/replay.ex      # internal replay over stored truth
├── docs/inbound_setup.md                         # canonical adopter lane
├── docs/operator_trust.md                        # replay/fallback/operator semantics
└── test/mailglass_inbound/                       # execution + docs-contract proof
```
[VERIFIED: existing module layout in `mailglass_inbound/lib`, `mailglass_inbound/test`; recommended additions are constrained by 42-CONTEXT discretion]

### Pattern 1: Persist Then Dispatch Through One Internal Async Facade
**What:** Keep ingress responsible for verified receive truth, then call a single internal async facade that chooses Oban or `Task.Supervisor` without changing the public response shape. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex, lib/mailglass/outbound.ex]  
**When to use:** Every fresh inserted inbound receive. [VERIFIED: 42-CONTEXT.md]  
**Example:**
```elixir
# Source pattern: mailglass_inbound ingress + mailglass outbound async split
case persistence.persist(handoff, opts) do
  {:ok, %{status: :inserted} = result} ->
    :ok = MailglassInbound.Async.dispatch(result)
    send_json(conn, 200, %{status: "inserted", route: route_status(result.route)})

  {:ok, %{status: :duplicate} = result} ->
    send_json(conn, 200, %{status: "duplicate", route: route_status(result.route)})
end
```
[VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex, lib/mailglass/outbound.ex]

### Pattern 2: Oban Worker Reloads Stored Truth And Returns Native Job Results
**What:** Oban worker args should contain identifiers and tenant context only; the worker reloads the inbound record/evidence and returns `:ok` or `{:error, reason}` based on shared execution outcomes. [VERIFIED: lib/mailglass/outbound/worker.ex, mailglass_inbound/lib/mailglass_inbound/execution.ex]  
**When to use:** Durable async lane. [VERIFIED: 42-CONTEXT.md]  
**Example:**
```elixir
# Source: repo pattern from lib/mailglass/outbound/worker.ex
use Oban.Worker,
  queue: :mailglass_inbound,
  max_attempts: 10,
  unique: [period: 3600, fields: [:args], keys: [:inbound_record_id]]

@impl Oban.Worker
def perform(%Oban.Job{args: %{"inbound_record_id" => id}} = job) do
  Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
    case MailglassInbound.Async.perform_by_id(id) do
      {:ok, %{outcome: outcome}} when outcome in [:accept, :ignore, :reject, :bounce, :no_match] -> :ok
      {:ok, %{outcome: :failed, failure: failure}} -> {:error, failure}
      {:error, reason} -> {:error, reason}
    end
  end)
end
```
[VERIFIED: lib/mailglass/outbound/worker.ex][CITED: https://hexdocs.pm/oban/Oban.Worker.html]

### Pattern 3: Fallback Task Reloads Stored Truth, Logs Failures, And Stops
**What:** Best-effort fallback should spawn a supervised task after commit, reload stored truth, and log failures without inventing retries or alternate persistence. [VERIFIED: lib/mailglass/outbound.ex, lib/mailglass/application.ex]  
**When to use:** Oban absent or explicitly disabled. [VERIFIED: 42-CONTEXT.md, lib/mailglass/application.ex]  
**Example:**
```elixir
# Source pattern: repo outbound fallback + Task.Supervisor docs
Task.Supervisor.start_child(MailglassInbound.TaskSupervisor, fn ->
  Mailglass.Tenancy.with_tenant(tenant_id, fn ->
    case MailglassInbound.Async.perform_by_id(inbound_record_id) do
      {:ok, _result} -> :ok
      {:error, reason} -> Logger.warning("[mailglass_inbound] fallback execution failed: #{inspect(reason)}")
    end
  end)
end)
```
[VERIFIED: lib/mailglass/outbound.ex][CITED: https://hexdocs.pm/elixir/Task.Supervisor.html][CITED: https://hexdocs.pm/swoosh/Swoosh.html]

### Anti-Patterns to Avoid

- **Expose `%Oban.Job{}` or queue names in docs/API examples:** the stable contract is mailbox semantics plus ingress results, not job transport types. [VERIFIED: lib/mailglass/outbound.ex, mailglass_inbound/docs/api_stability.md]  
- **Execute mailboxes inline when Oban is absent:** this violates locked Phase 42 semantics and changes provider latency/failure behavior. [VERIFIED: 42-CONTEXT.md]  
- **Serialize full `%InboundMessage{}` or evidence blobs into Oban args:** the outbound worker docs already reject rich struct serialization; inbound should follow the same JSON-safe identifier rule. [VERIFIED: lib/mailglass/outbound/worker.ex]  
- **Pretend fallback tasks retry or survive node crashes:** `Task.Supervisor` does not provide durable queue semantics; docs must say so plainly. [CITED: https://hexdocs.pm/elixir/Task.Supervisor.html][CITED: https://hexdocs.pm/swoosh/Swoosh.html]  
- **Claim Hex/release readiness before automation exists:** current release-please and publish workflows exclude `mailglass_inbound`. [VERIFIED: release-please-config.json, .release-please-manifest.json, .github/workflows/release-please.yml, .github/workflows/publish-hex.yml]  

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Durable retries and backoff | Custom retry tables, timers, or queue records | Oban worker + DB-backed jobs | Oban already models retries, discard/cancel states, backoff, timeouts, and lifecycle visibility. [CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Best-effort async fallback | A fake queue that pretends to be durable | `Task.Supervisor.start_child/3` plus explicit warnings | The fallback should be small and honest, not a second queue system. [VERIFIED: 42-CONTEXT.md][CITED: https://hexdocs.pm/elixir/Task.Supervisor.html] |
| Provider-specific operator UX in this phase | Conductor/replay UI or public replay API | Internal replay plus trust docs/tests | Phase 42 explicitly scopes trust proof to docs and verification, not UI/API growth. [VERIFIED: 42-CONTEXT.md, mailglass_inbound/lib/mailglass_inbound/internal/replay.ex] |
| Setup inference | `mix mailglass.install` guesses inbound routes/parser/runtime mode | One canonical manual setup guide | The unresolved installer choices are adopter-owned and currently not inferable honestly. [VERIFIED: 42-CONTEXT.md] |
| Release automation drift handling | Manual release checklist outside CI only | Extend release-please, root CI, and publish workflows | `mailglass_inbound` currently has package metadata but no canonical root release lane. [VERIFIED: mailglass_inbound/mix.exs, .github/workflows/release-please.yml, .github/workflows/publish-hex.yml] |

**Key insight:** Phase 42 is not about inventing new execution behavior; it is about routing the already-correct “persist truth first, classify mailbox outcomes later” model through two transport modes and then documenting the operational difference honestly. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex, mailglass_inbound/lib/mailglass_inbound/execution.ex, 42-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Public Contract Leakage From The Oban Worker
**What goes wrong:** Adopter-facing docs or APIs start talking about `%Oban.Job{}`, worker modules, or queue names as if they were stable contract. [VERIFIED: mailglass_inbound/docs/api_stability.md, lib/mailglass/outbound.ex]  
**Why it happens:** Oban is visible in implementation code and easy to surface in examples accidentally. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/optional_deps.ex, lib/mailglass/outbound/worker.ex]  
**How to avoid:** Keep the stable promise at the ingress/mailbox/outcome level and mark workers, queue names, and gateway helpers as internal. [VERIFIED: 42-CONTEXT.md, mailglass_inbound/docs/api_stability.md]  
**Warning signs:** README or guide examples instruct users to pattern-match on jobs or call worker modules directly. [VERIFIED: mailglass_inbound/README.md, mailglass_inbound/docs/api_stability.md]  

### Pitfall 2: Fallback Semantics Drift Into Inline Request Execution
**What goes wrong:** Non-Oban mode starts running mailbox logic before the webhook response returns, changing latency and retry behavior. [VERIFIED: 42-CONTEXT.md]  
**Why it happens:** It can look simpler than starting a task after persistence. [VERIFIED: 42-CONTEXT.md]  
**How to avoid:** Keep the sequence identical in both modes up to persistence, then dispatch async via Oban or `Task.Supervisor`. [VERIFIED: 42-CONTEXT.md, lib/mailglass/outbound.ex]  
**Warning signs:** Plug tests start asserting mailbox side effects synchronously on the request process. [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs]  

### Pitfall 3: Assuming `Task.Supervisor` Gives Durability Or Retry
**What goes wrong:** Docs over-promise fallback recoverability, or operators treat task loss as a bug rather than expected best-effort behavior. [VERIFIED: lib/mailglass/application.ex]  
**Why it happens:** The task is supervised, so it is easy to blur supervision with queue durability. [CITED: https://hexdocs.pm/elixir/Task.Supervisor.html]  
**How to avoid:** State explicitly that fallback work can be lost on crash/shutdown, does not retry, and is recoverable only through replay/operator action. [VERIFIED: 42-CONTEXT.md][CITED: https://hexdocs.pm/swoosh/Swoosh.html]  
**Warning signs:** Guide language says “queued” or “will retry” for fallback mode without qualifying that Oban is absent. [VERIFIED: current docs need Phase 42 expansion; 42-CONTEXT.md]  

### Pitfall 4: Provider Setup Docs Omit The Parser/Raw-MIME Sharp Edges
**What goes wrong:** Adopters mount the route but miss the Postmark `body_reader` requirement or the SendGrid raw MIME checkbox and conclude the package is broken. [VERIFIED: mailglass_inbound/docs/postmark_ingress.md, mailglass_inbound/docs/sendgrid_ingress.md, mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs]  
**Why it happens:** Postmark and SendGrid need different parser expectations, and Plug documents that multipart parsing bypasses `:body_reader`. [CITED: https://hexdocs.pm/plug/Plug.Parsers.html][CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook]  
**How to avoid:** Publish one setup guide that shows both mounts and both parser caveats together. [VERIFIED: 42-CONTEXT.md]  
**Warning signs:** Support docs mention only provider-specific pages and never reconcile their parser/runtime differences in one canonical lane. [VERIFIED: mailglass_inbound/README.md, mailglass_inbound/mix.exs]  

### Pitfall 5: Replay Trust Docs Drift From Actual Failure Modes
**What goes wrong:** Operator docs imply replay always works or silently re-routes, even though current code fails when fresh matched history is missing or only `:no_match` exists. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/internal/replay.ex, mailglass_inbound/test/mailglass_inbound/replay_test.exs]  
**Why it happens:** Replay looks simple conceptually, but the current code deliberately depends on prior execution lineage. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/internal/replay.ex]  
**How to avoid:** Mirror the current failure cases in operator-trust docs and docs-contract tests. [VERIFIED: mailglass_admin/docs/operator-trust.md, mailglass_inbound/test/mailglass_inbound/replay_test.exs]  
**Warning signs:** Docs claim replay “reprocesses any inbound message” without mentioning missing-lineage or `:no_match` cases. [VERIFIED: 42-CONTEXT.md, mailglass_inbound/lib/mailglass_inbound/internal/replay.ex]  

### Pitfall 6: Sibling Package Release Drift
**What goes wrong:** `mailglass_inbound` gains runtime/docs features but remains outside root CI, release-please, and publish automation, so the repo cannot prove adopter readiness end to end. [VERIFIED: .planning/ROADMAP.md, .github/workflows/ci.yml, .github/workflows/release-please.yml, .github/workflows/publish-hex.yml]  
**Why it happens:** The package metadata exists, but the root workflows still only cover `mailglass` and `mailglass_admin`. [VERIFIED: mailglass_inbound/mix.exs, release-please-config.json, .release-please-manifest.json]  
**How to avoid:** Treat 42-03 as mandatory automation work, not post-phase cleanup. [VERIFIED: .planning/ROADMAP.md]  
**Warning signs:** No CI job runs `cd mailglass_inbound && mix test`, `mailglass_inbound` is absent from release-please config, and the package has no changelog even though `mix.exs` packages `CHANGELOG*`. [VERIFIED: .github/workflows/ci.yml, release-please-config.json, mailglass_inbound/mix.exs, local file probe]  

## Code Examples

Verified patterns from official and repo-primary sources:

### Oban Worker Return Semantics For Durable Retries
```elixir
# Source: https://hexdocs.pm/oban/Oban.Worker.html
def perform(%Oban.Job{args: %{"id" => id}}) do
  case run_mailbox(id) do
    :ok -> :ok
    {:failed, reason} -> {:error, reason}
  end
end
```
[CITED: https://hexdocs.pm/oban/Oban.Worker.html]

### Fire-And-Forget Fallback With `Task.Supervisor`
```elixir
# Source: https://hexdocs.pm/elixir/Task.Supervisor.html
Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
  do_side_effecting_work()
end)
```
[CITED: https://hexdocs.pm/elixir/Task.Supervisor.html]

### Honest Lightweight Async Warning From The Swoosh Pattern
```elixir
# Source: https://hexdocs.pm/swoosh/Swoosh.html
Task.Supervisor.start_child(MyApp.AsyncEmailSupervisor, fn ->
  MyApp.Mailer.deliver(email)
end)
```
[CITED: https://hexdocs.pm/swoosh/Swoosh.html]

### Persist-Then-Execute Ingress Entry Shape
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
case persistence.persist(handoff, persistence_opts(opts)) do
  {:ok, result} ->
    maybe_execute(execution, result)
    send_json(conn, 200, %{status: Atom.to_string(result.status), route: route_status(result.route)})

  {:error, reason} ->
    send_json(conn, 500, %{status: "error", reason: inspect(reason)})
end
```
[VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline mailbox work during webhook handling | Persist receive truth first, then hand off asynchronously | Locked by Phase 42 decisions on `2026-05-06`. [VERIFIED: 42-CONTEXT.md] | Keeps provider acknowledgement semantics stable and decouples mailbox cost from request latency. [VERIFIED: 42-CONTEXT.md] |
| Fire-and-forget task as the only async story | Durable Oban jobs for the primary path, task fallback only when durability is unavailable | Current Oban and Swoosh docs still present this split in 2026. [CITED: https://hexdocs.pm/oban/Oban.Worker.html][CITED: https://hexdocs.pm/swoosh/Swoosh.html] | Lets Mailglass stay optional-Oban without lying about guarantees. [VERIFIED: CLAUDE.md, 42-CONTEXT.md] |
| Per-provider setup pages only | One canonical setup lane plus provider-specific supplements | Phase 42 target. [VERIFIED: 42-CONTEXT.md, current docs layout in mailglass_inbound/mix.exs] | Reduces adopter setup misses around parser, raw MIME, fallback, and replay semantics. [VERIFIED: mailglass_inbound/docs/postmark_ingress.md, mailglass_inbound/docs/sendgrid_ingress.md] |
| Root/admin-only sibling automation | Full sibling-package release proof including `mailglass_inbound` | Phase 42 plan 42-03 target. [VERIFIED: .planning/ROADMAP.md, current root workflows] | Makes the package’s docs and release posture match the repo’s linked-version promise. [VERIFIED: .planning/PROJECT.md, release-please-config.json] |

**Deprecated/outdated:**
- Treating the non-Oban fallback as “good enough queueing” is outdated for this repo; the official Swoosh guidance and locked Phase 42 decisions both treat it as lightweight best-effort only. [CITED: https://hexdocs.pm/swoosh/Swoosh.html][VERIFIED: 42-CONTEXT.md]  
- Shipping `mailglass_inbound` docs without root release/verification proof is outdated once Phase 42 claims adopter credibility. [VERIFIED: .planning/ROADMAP.md, .github/workflows/release-please.yml, .github/workflows/ci.yml]  

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A package-local `MailglassInbound.Application` plus `MailglassInbound.TaskSupervisor` is the chosen internal home for fallback warning posture and supervised tasks, rather than reusing `Mailglass.TaskSupervisor`. [RESOLVED] | Architecture Patterns / Resolved Questions | Low. The plans now wire this choice explicitly via `mailglass_inbound/mix.exs`, package-local runtime ownership, and dedicated async/worker proof files. |

## Resolved Questions

1. **Should fallback execution reuse `Mailglass.TaskSupervisor` or add a package-local supervisor?**
   - What we know: `mailglass_inbound` currently has no application module, while `mailglass` already starts `Mailglass.TaskSupervisor`; Phase 42 also wants package-owned warning posture. [VERIFIED: mailglass_inbound/mix.exs, lib/mailglass/application.ex]
   - Resolution: use a package-local `MailglassInbound.Application` and `MailglassInbound.TaskSupervisor` so the sibling package can own its fallback docs, logging, and tests cleanly without depending on a core internal singleton. [RESOLVED]
   - Planning impact: `42-01` must modify `mailglass_inbound/mix.exs`, add the package-local application/supervisor path, and prove the new runtime behavior with targeted async and worker tests. [VERIFIED: checker findings + updated plan]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | compile/test/docs verification | ✓ [VERIFIED: local env probe] | `1.19.5` [VERIFIED: local env probe] | — |
| Erlang/OTP | runtime/test | ✓ [VERIFIED: local env probe] | `28` [VERIFIED: local env probe] | — |
| Mix | compile/test/release commands | ✓ [VERIFIED: local env probe] | `1.19.5` [VERIFIED: local env probe] | — |
| PostgreSQL client/binaries | DB-backed verification and migrations | ✓ [VERIFIED: local env probe] | `14.17` [VERIFIED: local env probe] | — |
| Docker | CI-like local service rehearsal if needed | ✓ [VERIFIED: local env probe] | `29.4.1` [VERIFIED: local env probe] | — |
| Oban dependency in host app | durable async runtime | project-dependent [VERIFIED: mailglass_inbound/mix.exs] | locked in repo at `2.21.1` [VERIFIED: mix.lock] | supported fallback via `Task.Supervisor` with explicit best-effort semantics. [VERIFIED: 42-CONTEXT.md] |

**Missing dependencies with no fallback:**
- None for planning. [VERIFIED: local env probe]

**Missing dependencies with fallback:**
- Host-app Oban installation is optional; the supported fallback remains `Task.Supervisor` after persistence, with replay as the recovery path. [VERIFIED: 42-CONTEXT.md, mailglass_inbound/mix.exs]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix [VERIFIED: mailglass_inbound/test/test_helper.exs, mailglass_inbound/mix.exs] |
| Config file | `mailglass_inbound/mix.exs` + `mailglass_inbound/test/test_helper.exs` [VERIFIED: mailglass_inbound/mix.exs, mailglass_inbound/test/test_helper.exs] |
| Quick run command | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` [VERIFIED: existing test files] |
| Full suite command | `cd mailglass_inbound && mix test --warnings-as-errors` [VERIFIED: mailglass_inbound/mix.exs, test tree] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXEC-01 | Fresh inserted inbound messages enqueue durable work through Oban without exposing `%Oban.Job{}` in public returns/docs. [VERIFIED: REQUIREMENTS + context] | unit + integration | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs --warnings-as-errors` | ❌ Wave 0 |
| EXEC-01 | Oban worker maps shared execution results into `:ok` or `{:error, reason}` so retries follow Oban semantics. [VERIFIED: repo outbound precedent + official docs] | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/worker_test.exs --warnings-as-errors` | ❌ Wave 0 |
| EXEC-02 | Fallback dispatch happens only after persistence and returns `200` without inline mailbox execution. [VERIFIED: 42-CONTEXT.md, ingress tests] | unit + Plug integration | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/async_execution_test.exs --warnings-as-errors` | ◐ expand existing + new file |
| EXEC-02 | Fallback failure is logged/recorded honestly and does not imply retry or durability. [VERIFIED: outbound precedent + docs requirement] | unit + docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ❌ / ◐ |
| ADOPT-01 | Canonical setup docs cover Postmark + SendGrid mounts, parser wiring, Oban/fallback semantics, and replay trust. [VERIFIED: current docs gaps + context] | docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ expand existing |
| ADOPT-01 | Root verification/release proof includes `mailglass_inbound` CI and release automation coverage. [VERIFIED: ROADMAP + workflow gaps] | workflow/config contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` plus workflow diff review [VERIFIED: existing root support-contract posture] | ❌ Wave 0 root proof |

### Sampling Rate

- **Per task commit:** `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` [VERIFIED: existing test files]  
- **Per wave merge:** `cd mailglass_inbound && mix test --warnings-as-errors` [VERIFIED: mailglass_inbound test tree]  
- **Phase gate:** `cd mailglass_inbound && mix test --warnings-as-errors` plus root workflow/release file review proving `mailglass_inbound` enters CI + publish automation. [VERIFIED: current workflow gaps]  

### Wave 0 Gaps

- [ ] `mailglass_inbound/test/mailglass_inbound/async_execution_test.exs` — covers EXEC-01 and EXEC-02 dispatch branching, fallback ordering, and no-duplicate-execution proof. [VERIFIED: required by current gaps]  
- [ ] `mailglass_inbound/test/mailglass_inbound/worker_test.exs` — covers Oban worker arg shape, tenancy restoration, and retry-result mapping. [VERIFIED: required by current gaps]  
- [ ] Extend `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` — cover one canonical setup guide, fallback warning posture, replay trust wording, and deferred-boundary honesty. [VERIFIED: current file exists but does not cover Phase 42 additions]  
- [ ] Root proof addition — add CI/release contract coverage that fails if `mailglass_inbound` remains absent from root automation. [VERIFIED: current root workflows omit package]  

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: provider basic-auth ingress exists] | Provider verification before tenancy/persistence; Postmark and SendGrid setup docs must keep auth explicit. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex, docs][CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email][CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook] |
| V3 Session Management | no [VERIFIED: webhook ingress and internal replay are not session-based in this phase] | — |
| V4 Access Control | yes [VERIFIED: replay/operator trust docs matter] | Keep replay internal and document operator-facing semantics without opening a public replay API/UI. [VERIFIED: 42-CONTEXT.md, mailglass_admin/docs/operator-trust.md] |
| V5 Input Validation | yes [VERIFIED: inbound email is untrusted user input] | Provider verification, parser constraints, normalized struct boundary, and attachment/raw-evidence caution. [VERIFIED: ingress code/docs][CITED: https://anymail.dev/en/stable/inbound/] |
| V6 Cryptography | no direct new crypto in Phase 42 [VERIFIED: phase scope] | Reuse existing provider-auth mechanisms; do not hand-roll queue/retry tokens or cryptographic replay controls in this phase. [VERIFIED: 42-CONTEXT.md] |

### Known Threat Patterns for `mailglass_inbound`

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged inbound webhook | Spoofing | Verify provider auth before tenant resolution or writes; fail closed on bad credentials. [VERIFIED: ingress code][CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email] |
| Malicious attachment or body content | Tampering | Treat inbound email as user-supplied content; keep attachment bytes in evidence and do not imply they are safe/trusted. [CITED: https://anymail.dev/en/stable/inbound/] |
| Duplicate provider delivery triggers repeated mailbox work | Repudiation / Tampering | Persist truth first, detect duplicates before dispatch, and do not re-execute on duplicate fresh receive. [VERIFIED: ingress/persist tests and code] |
| Lost fallback work after node crash | Denial of Service | Document best-effort semantics, log warnings, and position replay as recovery path. [VERIFIED: 42-CONTEXT.md, outbound warning posture] |
| Replay misunderstood as new provider receive | Repudiation | Trust docs must state replay uses stored truth and may fail without prior matched fresh lineage. [VERIFIED: internal replay code/tests, operator-trust precedent] |

## Sources

### Primary (HIGH confidence)
- `/oban-bg/oban` via Context7 CLI — worker retry/result semantics and lifecycle guidance. [VERIFIED: `npx --yes ctx7@latest docs /oban-bg/oban ...`]  
- `/elixir-plug/plug` via Context7 CLI — `Plug.Parsers` and parser/body-reader behavior. [VERIFIED: `npx --yes ctx7@latest docs /elixir-plug/plug ...`]  
- `/swoosh/swoosh` via Context7 CLI — lightweight async fallback posture. [VERIFIED: `npx --yes ctx7@latest docs /swoosh/swoosh ...`]  
- https://hexdocs.pm/oban/Oban.Worker.html — durable worker contract, retries, timeouts, and native return semantics. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]  
- https://hexdocs.pm/oban/job_lifecycle.html — job state transitions and retry lifecycle. [CITED: https://hexdocs.pm/oban/job_lifecycle.html]  
- https://hexdocs.pm/elixir/Task.Supervisor.html — supervised task semantics, `start_child/3`, and restart behavior. [CITED: https://hexdocs.pm/elixir/Task.Supervisor.html]  
- https://hexdocs.pm/plug/Plug.Parsers.html — parser options and multipart/body-reader caveat. [CITED: https://hexdocs.pm/plug/Plug.Parsers.html]  
- https://hexdocs.pm/swoosh/Swoosh.html — async Task.Supervisor example and durable-queue warning. [CITED: https://hexdocs.pm/swoosh/Swoosh.html]  
- https://guides.rubyonrails.org/action_mailbox_basics.html — durable inbound record, async routing, and status/replay precedent. [CITED: https://guides.rubyonrails.org/action_mailbox_basics.html]  
- https://anymail.dev/en/stable/inbound/ — inbound normalization and user-supplied-content security cautions. [CITED: https://anymail.dev/en/stable/inbound/]  
- https://postmarkapp.com/developer/user-guide/inbound/parse-an-email — inbound webhook timing/retry behavior and setup semantics. [CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email]  
- https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook — inbound parse setup, raw full MIME option, and multipart payload format. [CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook]  

### Secondary (MEDIUM confidence)
- `mix hex.info oban` — current Hex release metadata for Oban. [VERIFIED: local command]  
- `mix hex.info plug` — current Hex release metadata for Plug. [VERIFIED: local command]  
- `mix hex.info swoosh` — current Hex release metadata for Swoosh. [VERIFIED: local command]  

### Tertiary (LOW confidence)
- None. [VERIFIED: this document]

## Metadata

**Confidence breakdown:**  
- Standard stack: HIGH - The repo already pins the relevant packages and the runtime claims are cross-checked with current official docs and Hex metadata. [VERIFIED: mix.exs, mix.lock, local commands][CITED: official docs above]  
- Architecture: HIGH - The phase is tightly constrained by locked context decisions and existing outbound/inbound execution patterns already present in the repo. [VERIFIED: 42-CONTEXT.md, lib/mailglass/outbound.ex, mailglass_inbound/lib/mailglass_inbound/*.ex]  
- Pitfalls: HIGH - The main risks come directly from current code gaps, current workflow omissions, and current official docs for Oban, Plug, Swoosh, Postmark, and SendGrid. [VERIFIED: repo code/workflows][CITED: official docs above]  

**Research date:** 2026-05-06 [VERIFIED: local system date]  
**Valid until:** 2026-06-05 for repo-shape claims; re-check official package/docs versions sooner if dependency upgrades or release automation changes land. [VERIFIED: current repo state][ASSUMED: 30-day stability window]
