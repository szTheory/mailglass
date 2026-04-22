# Mailglass Engineering DNA — Inherited from Prior Elixir/Phoenix Libs

> **Purpose:** Companion context for a fresh LLM seeding a new GSD project for `mailglass` (Phoenix-native, Swoosh-based email framework / suite — preview dashboards, inbound routing, marketing-email primitives, deliverability/compliance, admin UIs).
>
> **Source corpus:** Battle-tested patterns extracted from Jon's 4 prior Elixir/Phoenix OSS libs:
> - `accrue` — Stripe-native billing toolkit (`accrue` + `accrue_admin`, monorepo, v1.0+ shipped, 42 phases)
> - `lattice_stripe` — Production Stripe SDK (single package, v1.1 live on Hex, 37 phases, consumed by `accrue`)
> - `sigra` — Phoenix auth library w/ mountable admin LiveViews (single package + `test/example/` host, v0.2)
> - `scrypath` — Ecto-native search indexing (single package + optional `scrypath_ops/` companion, v0.3.4 live on Hex, 13 milestones, ~56 phases)
>
> **How to read this doc:** §2 is convergent DNA (4-of-4 = port verbatim). §3 is the divergent menu (pick per use case). §4 translates everything to email-domain primitives. §5 is the concrete starter skeleton. §6 is the gotcha list. §7 is the GSD seed plan. §8 is the source map for deeper digs.

---

## 1. Provenance & confidence calibration

| Source project | Maturity | Strongest contribution to mailglass |
|---|---|---|
| `accrue` | v1.0+ shipped, 42 phases, monorepo | Sibling-package shape (`mailglass` + `mailglass_admin`), Fake processor pattern, append-only event ledger, polymorphic ownership, RELEASING.md runbook |
| `lattice_stripe` | v1.1 live on Hex | Cleanest error-model + pluggable-behaviour design, downstream-aware planning, `api_stability.md` contract |
| `sigra` | v0.2, mature Phoenix integration | **Mountable LiveView admin/preview UIs** (the single closest precedent for mailglass dashboards), generated host code via `mix sigra.install`, golden-diff installer tests, `test/example/` Phoenix subproject |
| `scrypath` | v0.3.4 live on Hex, 13 shipped milestones | **Richest planning discipline**, doc-contract tests, post-publish verification gates, `scrypath_ops/` separate-app pattern, evidence-led backlog triage |

**Confidence rules:**
- **4-of-4 convergence** → adopt without debate. (e.g., Conventional Commits + Release Please.)
- **3-of-4** → adopt unless mailglass has a specific reason not to.
- **2-of-4 with diverging reasoning** → menu choice; §3 explains the trade-off.
- **1-of-4** → only port if the precedent is the closest match (e.g., sigra's mountable LiveViews).

---

## 2. Convergent DNA — port verbatim

These patterns appear in **all 4** prior libs. They are not opinions — they are the validated default.

### 2.1 Repo, package, and version metadata

- **Single source of truth for version**: `@version` constant at top of `mix.exs`, referenced in `docs: [source_ref: "v#{@version}"]` and `release-please-manifest.json`. Never hand-edit version in two places.
- **Hex package whitelist files explicitly** in `mix.exs`: `files: ~w(lib priv guides .formatter.exs mix.exs README* LICENSE* CHANGELOG*)`. Never auto-include the whole repo (especially never include `test/example/` or `*_ops/` companion apps).
- **Hex package metadata table**: `name`, `description`, `licenses: ["MIT"]`, `links: %{"GitHub" => @source_url, "HexDocs" => ..., "Changelog" => ...}`. The Changelog link is the most-used by adopters in practice.
- **`.formatter.exs`** is intentionally minimal: an `inputs:` glob plus the deps (e.g., `:phoenix`, `:ecto`) whose macros need formatting. No custom rules.
- **Project root files** (always present): `README.md`, `CHANGELOG.md`, `LICENSE` (MIT), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`. accrue/sigra additionally ship `MAINTAINING.md` (release runbook, secret setup, branch protection settings) — adopt this for mailglass.
- **Module namespacing**: root module (`Mailglass`) is the public surface (reflection + orchestration + error types). Internal modules use `@moduledoc false` to lock the public API.

### 2.2 CI/CD shape

Every project converges on this lane structure:

| Lane | Purpose | Blocks merge? |
|---|---|---|
| **Lint** | format check, `mix compile --warnings-as-errors`, `mix credo --strict`, `mix docs --warnings-as-errors`, `mix hex.audit` | yes |
| **Test matrix** | `mix test --warnings-as-errors` across multiple Elixir/OTP cells | yes |
| **Integration / golden** | Real-service or generated-host-app proof (stripe-mock, MailHog, fresh `mix mailglass.install` output) | yes for paths that touch it |
| **Release-please** | Auto-bump version + CHANGELOG on `main` | n/a (opens a PR) |
| **Publish-Hex** | Triggers on tag from release-please merge | n/a (release-time only) |
| **Post-publish verify** | Polls Hex for tarball visibility, compiles a throwaway consumer app, checks HexDocs reachability | not for that PR — runs daily + on `workflow_dispatch` |

Specifics that all 4 share:
- **Concurrency group** with `cancel-in-progress: true` to kill stale CI runs on force-push.
- **Path filters** to skip CI on `.md` / `.planning/` / `guides/` only changes when nothing in `lib/` changed.
- **Caching layers** keyed by `mix.lock` hash: `deps/`, `_build/`, dialyzer PLT (split restore→build-if-miss→save), Hex registry.
- **Postgres service container** in any job needing Ecto, with healthcheck `--health-interval=10s --health-timeout=5s`. Credentials via env vars, never hardcoded `localhost:5432/postgres`.
- **Secrets** (`HEX_API_KEY`, `RELEASE_PLEASE_TOKEN`) only as GHA secrets. Never echoed, never in logs, never in the workflow file.
- **Least privilege**: `permissions: contents: read` at workflow top; jobs that need `id-token: write` or `pull-requests: write` opt in explicitly.

### 2.3 Release & versioning

**Conventional Commits + Release Please is the universal default.** Specifics:
- Commit format: `type(scope): subject`. Types: `feat | fix | docs | test | refactor | chore | perf | style`. Scope is usually a phase tag (`feat(send-04-02): ...`) or a component (`fix(admin): ...`).
- `feat:` → minor bump. `fix:` → patch bump. Breaking change footer (`BREAKING CHANGE:`) → major. (None of the 4 projects have shipped a breaking-change footer — they all design for forward-compat instead.)
- `release-please-manifest.json` is single source of truth for last-published version.
- `release-please-config.json` controls per-package CHANGELOG paths and bump rules. For multi-package monorepos (accrue), set `separate-pull-requests: false` + linked-versions plugin so packages bump together.
- **Manual publish fallback**: a `publish-hex.yml` workflow with `workflow_dispatch` that does a dry-run validation + version verification before publishing — for the day Release Please breaks.
- **Pre-1.0 versioning is strict**: new public modules/functions = minor bump (NOT patch). Patches are doc/internal only.
- **CHANGELOG format**: Keep-a-Changelog style. Release Please owns released sections; contributors write Unreleased entries by hand only when the auto-generation needs help.

### 2.4 Error model (the single most important convergent pattern)

All 4 libs use the same shape:

```elixir
defmodule Mailglass.Error do
  defexception [:type, :code, :message, :status, :request_id, :raw_body, :metadata]
end
```

Plus typed sub-error modules for the most common failure modes (so callers can pattern-match by struct, not by message string):

```elixir
defmodule Mailglass.SendError do ... end       # delivery failed
defmodule Mailglass.TemplateError do ... end   # template not found / variable missing
defmodule Mailglass.SignatureError do ... end  # webhook signature mismatch
defmodule Mailglass.SuppressedError do ... end # tried to send to a suppressed address
defmodule Mailglass.RateLimitError do ... end  # provider 429
defmodule Mailglass.ConfigError do ... end     # boot-time misconfig
```

Discipline rules (lattice_stripe + accrue + sigra all enforce these):
1. **Public API returns `{:ok, struct} | {:error, %Mailglass.Error{}}`**. Bang variants (`send!/2`) raise the same struct.
2. **`type:` field is a closed atom set** documented in `api_stability.md`. Pattern-match on `:type`, never on `:message` (message is human copy and may change in patch releases).
3. **`raw_body` is the escape hatch** — full provider payload preserved, callers can dig in for fields the lib hasn't normalized yet.
4. **One mapper module** translates provider-specific errors (Swoosh adapter errors, webhook signature mismatches, ESP HTTP responses) into `Mailglass.Error.t()`. Adopters see `Mailglass.Error`, never raw `%Swoosh.DeliveryError{}`.
5. **Enumeration-safe `safe_message/1`** for any error that could leak existence of subscribers/campaigns to unauthenticated callers (sigra's pattern — directly applicable to mailglass public preview links and unsubscribe endpoints).
6. **Custom `message/1` impl** formats: `(type) [status] [code] message (request: id)` for log-friendly output.

### 2.5 Telemetry — span pattern with structured names

All 4 libs use **`:telemetry.span/3` wrapped in a project module**:

```elixir
defmodule Mailglass.Telemetry do
  def span(event, meta, fun), do: :telemetry.span([:mailglass | event], meta, fun)
end
```

Naming convention is **strictly `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]`** (4 levels before suffix). Examples for mailglass:

- `[:mailglass, :outbound, :send, :start | :stop | :exception]`
- `[:mailglass, :outbound, :batch, :start | :stop]`
- `[:mailglass, :inbound, :receive, :start | :stop]`
- `[:mailglass, :inbound, :route, :match | :no_match]`
- `[:mailglass, :webhook, :signature, :verify, :ok | :fail]`
- `[:mailglass, :preview, :render, :start | :stop | :exception]`
- `[:mailglass, :template, :compile, :start | :stop | :exception]`
- `[:mailglass, :ops, :bounce, :received]`
- `[:mailglass, :ops, :complaint, :received]`
- `[:mailglass, :ops, :unsubscribe, :received]`
- `[:mailglass, :ops, :dlq, :exhausted]`

Universal rules:
- **Never raise from telemetry** — observability faults must not break business logic.
- **Stop metadata never includes raw recipient lists, raw bodies, or PII**. Counts, statuses, latencies, opaque IDs only.
- **Conditional OpenTelemetry bridge**: `Code.ensure_loaded?(:opentelemetry)` gate, `@compile {:no_warn_undefined, :opentelemetry}` to avoid warnings when the optional dep is absent.
- **Actor/scope auto-captured** from process dict (sigra/accrue pattern) — adopters get attribution "for free" once they set the actor at request boundary.
- **Ops-class events are tagged separately** (`[:mailglass, :ops, ...]`) so operators can wire alerts without subscribing to the firehose.

### 2.6 Testing

Convergent stack (all 4 use this):
- **ExUnit + Mox** for behaviour mocking. Define mocks in `test_helper.exs` for every public behaviour the lib exposes.
- **`test/support/`** auto-loaded; contains shared `Case` templates, fixture modules, and assertion helpers.
- **Fixture modules return plain maps** (no factory framework — `ExMachina` is intentionally not used). Composition at call site via `Map.merge/2`.
- **Tests tagged `:integration`** are excluded by default (`ExUnit.start(exclude: [:integration])`); run via `mix test --include integration` in a dedicated CI job with the real service container.
- **Doctests are second-class** — used sparingly for tiny pure functions, not as a primary test strategy.
- **Property tests are absent** unless the domain is genuinely algorithmic (none of the 4 libs use `stream_data` in release-blocking gates).
- **Per-domain `Case` templates**: e.g., `Mailglass.MailerCase` (sandbox + Fake adapter + actor seeded), `Mailglass.WebhookCase` (raw-body Plug stub + signature fixtures).

### 2.7 Documentation contracts

This is the highest-leverage convergent pattern (every project has it; every project credits it for catching silent doc rot):

```elixir
# test/mailglass/docs_contract_test.exs
defmodule Mailglass.DocsContractTest do
  use ExUnit.Case, async: true

  test "README Quick Start snippet matches the actual public function" do
    snippet = File.read!("README.md") |> extract_codeblock("elixir-quickstart")
    assert snippet =~ "Mailglass.send(%{to: \"alice@example.com\", ..."
    # also: compile the snippet to ensure it parses
    Code.string_to_quoted!(snippet)
  end

  test "guides/golden-path.md config example matches Mailglass.Config schema" do
    ...
  end
end
```

Coverage to lock for mailglass on day 1:
- README "Quick Start" code block compiles + matches real public functions
- `guides/golden-path.md` setup steps reference real mix tasks
- `guides/sending.md` adapter config snippets validate against `Mailglass.Config` NimbleOptions schema
- `CONTRIBUTING.md` CI table references actual workflow job names from `.github/workflows/ci.yml`
- `mailglass_admin/docs/ops-ia.md` nav matches real LiveView routes (sigra/scrypath both lock this)
- Phase-verification scripts (e.g., `verify_send_pipeline_readme_contract.sh`) grep for needle strings in guides

### 2.8 Custom Credo checks for domain rules

All 4 libs ship project-local Credo checks under `lib/<project>/credo/*.ex` and load them via `.credo.exs` `requires:`. They enforce **rules that prose docs can't**. Mailglass should ship at least:

- `Mailglass.Credo.NoRawSwooshSendInLib` — every send must go through `Mailglass.Outbound.send/2` (so telemetry, suppression checks, audit ledger writes all happen)
- `Mailglass.Credo.NoUnscopedTenantQueryInLib` — Repo queries on tenanted tables must pass through `Mailglass.Tenancy.scope/2`
- `Mailglass.Credo.RequiredListUnsubscribeHeaders` — flag any `Swoosh.Email` builder that doesn't go through `Mailglass.Compliance.add_unsubscribe_headers/1`
- `Mailglass.Credo.NoPiiInTelemetryMeta` — flag literal `:to`, `:from`, `:body` keys in telemetry `meta` maps

These ride on top of `mix credo --strict` in the lint lane.

### 2.9 GSD planning structure

All 4 projects use the same `.planning/` shape. Mailglass should bootstrap with this exact tree:

```
.planning/
├── PROJECT.md                # charter, value, locked decisions, out-of-scope
├── ROADMAP.md                # milestone table + active phase progress
├── REQUIREMENTS.md           # active milestone REQ-IDs (one row per requirement)
├── STATE.md                  # current focus, deferred items, audit-open ack
├── RETROSPECTIVE.md          # appended per shipped milestone
├── milestone-candidates.md   # backlog tiered A/B/C/D, evidence-led
├── milestones/               # archived REQ/ROADMAP/AUDIT per shipped version
├── phases/NN-slug/           # per-phase: PLAN.md, VERIFICATION.md, SUMMARY.md
├── research/                 # spikes, gap audits, design docs
├── intel/                    # codebase intel files
└── quick/                    # one-off micro-spikes
```

Convergent rules (every project enforces these and learned them the hard way):
1. **Phase counter is continuous** across milestones — never resets. (scrypath shipped 13 milestones in one continuous counter to phase 56.)
2. **Each phase owns a `VERIFICATION.md`** that becomes a merge gate. Lists exact test commands. No "done" without a verified command.
3. **Each phase has a `SUMMARY.md` written at close** — closure is what updates `REQUIREMENTS.md` traceability rows. (scrypath v1.11 retro: "REQUIREMENTS.md is a living contract; update traceability in same session as phase ship.")
4. **Decimal phases for gap-closure** (e.g., `11.1`) without renumbering downstream phases.
5. **One `verify.phase<NN>` mix task per focused concern** — never a kitchen-sink verify task that blurs what broke. (scrypath: `verify.phase11`, `verify.phase43`, `verify.opsui`. accrue: `release-gate`, `phase18-tax-gate`, `admin-drift-docs`, `host-integration`.)
6. **Locked decisions table in PROJECT.md** with `D-NN` IDs. Cite them in `@moduledoc` and PLAN.md so the rationale is grep-able 6 months later.
7. **Backlog triage is evidence-led**: A=highest-leverage now, B=next default pull only when tied to real adopter pain (issues, dogfood), C=defer until failure proven, D=maintainer hygiene that's not product. Scrypath's exact words: *"avoid busywork and maintainer-only work masquerading as product."*

### 2.10 Git hygiene

- Linear history on `main` (squash + rebase culture). Merge commits rare.
- Commits scoped by phase: `feat(send-04-02):`, `test(subs-02-03):`, `docs(phase-12):`.
- Heavy use of body for "why" + phase reference. CHANGELOG is auto-derived; commit body is where rationale lives.
- `Co-Authored-By: Claude ... <noreply@anthropic.com>` footer on AI-pair commits.
- **No `--no-verify`, no force-push to `main`, no amending published commits.**

---

## 3. Divergent patterns — pick per use case

These are patterns where the 4 projects chose differently. For each, the recommended mailglass choice is explicit, with the dissenting reasoning noted.

### 3.1 Single package vs sibling packages

| Project | Choice |
|---|---|
| accrue | **Sibling packages**: `accrue` (core) + `accrue_admin` (LiveView), shared CI, linked release |
| lattice_stripe | Single package (no UI) |
| sigra | Single package, generated host code via `mix sigra.install`, `test/example/` Phoenix subproject |
| scrypath | Single package + optional in-repo `scrypath_ops/` Phoenix app **NOT published to Hex** |

**Mailglass recommendation: hybrid of sigra + scrypath.**
- `mailglass` (Hex package) — core lib (Outbound, Inbound, Templates, Subscribers, Suppression, Compliance, Webhook plugs).
- `mailglass_admin` (Hex package) — mountable LiveView dashboards (preview, sent-mail browser, inbound conductor, suppression manager). Sibling release like accrue/accrue_admin.
- `mailglass/test/example/` — full Phoenix host app for installer golden tests + Playwright admin smoke (sigra pattern).
- **No third "ops" Phoenix app** — scrypath_ops was a separate-app pattern because their UI was a maintenance console, not an embeddable component. Mailglass admin is meant to be *mounted in adopters' Phoenix apps*, so it ships as a LiveView library (sigra pattern), not a standalone ops app.

### 3.2 Generators / installers

| Project | Choice |
|---|---|
| accrue | `mix accrue.install` generates host-owned context, migrations, router mounts, webhook stub, Oban wiring; reruns don't clobber edits (conflict sidecars) |
| lattice_stripe | None (API SDK) |
| sigra | `mix sigra.install` with golden-diff CI tests; flag matrix (`--no-passkeys`, `--no-organizations`) for conditional code paths |
| scrypath | None initially; relies on adopter-owned context |

**Mailglass recommendation: sigra/accrue model.**
- `mix mailglass.install` generates: host-owned `MyApp.Mail` context, migrations for subscribers/lists/campaigns/suppression/event ledger, router mount for webhook plug, admin route mount, Oban worker stubs, default templates.
- Flag matrix: `--no-admin`, `--no-marketing` (skip lists/campaigns), `--no-inbound`.
- **Golden-diff CI**: install on fresh Phoenix app, snapshot the output tree under `test/fixtures/install/`, fail PR if drift uncommitted (sigra pattern).
- **Idempotency**: rerunning `mix mailglass.install` on an existing host writes conflict sidecars (`.mailglass_conflict_*`) instead of clobbering.

### 3.3 Authentication / scope integration

| Project | Choice |
|---|---|
| accrue | Adapter behaviour (`Accrue.Auth`); auto-detects sigra and wires adapter if present |
| lattice_stripe | N/A |
| sigra | IS the auth lib — owns `%Scope{}` |
| scrypath | None (single-tenant search) |

**Mailglass recommendation: accrue model.**
- `Mailglass.Auth` adapter behaviour (callbacks: `current_actor/1`, `actor_can?/3`, `tenant_for/1`).
- Built-in adapters: `Mailglass.Auth.Sigra` (auto-wired if sigra is loaded), `Mailglass.Auth.PhxGenAuth`, `Mailglass.Auth.Anonymous` (dev only).
- Step-up verification (sigra pattern) on destructive admin actions: bulk unsuppress, replay webhook, force-resend campaign.

### 3.4 Optional dependencies

| Project | Choice |
|---|---|
| accrue, sigra | `optional: true` in `mix.exs` + `Code.ensure_loaded?/1` + `@compile {:no_warn_undefined, ...}` guard |
| lattice_stripe | Pluggable behaviours (Transport, Json, RetryStrategy) — adopter brings their own impl |
| scrypath | Same as accrue/sigra |

**Mailglass recommendation: combine both.**
- Optional deps with guards: `:opentelemetry`, `:sigra`, `:oban` (for `deliver_later`), `:premailex` (CSS inliner), `:floki` (HTML→text auto-derivation), `:mrml` (MJML compilation).
- Pluggable behaviours: `Mailglass.Adapter` (Swoosh wrapper), `Mailglass.TemplateEngine` (HEEx default, MJML opt-in), `Mailglass.PreviewStore` (in-memory default, S3/Redis adapters), `Mailglass.SuppressionStore` (Ecto default, custom adapters).

### 3.5 Test fake vs Mox

| Project | Choice |
|---|---|
| accrue | **Stateful in-memory `Accrue.Processor.Fake`** — time-advanceable, event-triggerable, JSON-compatible state machine. **The required merge-blocking test target.** |
| lattice_stripe | Mox + stripe-mock Docker integration job |
| sigra | Mox for optional deps + stub adapters in test |
| scrypath | Stub adapters (e.g., Meilisearch in-memory) for fast CI |

**Mailglass recommendation: accrue's Fake-first approach is the strongest play here.**
- Build `Mailglass.Adapter.Fake` — an in-memory adapter that records sent emails, lets tests trigger bounces/complaints/opens/clicks, simulates inbound webhooks, advances time. Stateful, deterministic, credential-free.
- Make Fake the **required release-gate target**. Real provider tests (Postmark sandbox, SendGrid test mode, MailHog SMTP) are **advisory** — daily cron + `workflow_dispatch`, never block PRs.
- This matches accrue's lesson: *"Keep provider-backed checks advisory while Fake-backed host proof remains deterministic release blocker."*

### 3.6 Append-only event ledger

| Project | Choice |
|---|---|
| accrue | **Yes** — `accrue_events` table, Postgres BEFORE-UPDATE-OR-DELETE trigger raises SQLSTATE 45A01, `UNIQUE(idempotency_key)` partial index, every state mutation is an `Ecto.Multi` that includes the event row |
| others | No |

**Mailglass recommendation: adopt verbatim.** This is one of accrue's strongest single contributions and maps perfectly onto email's audit needs.

```sql
CREATE TABLE mailglass_events (
  id BINARY(16) PRIMARY KEY,
  type VARCHAR NOT NULL,         -- "send.queued", "send.sent", "send.delivered", "send.bounced",
                                 -- "send.complained", "send.opened", "send.clicked",
                                 -- "inbound.received", "inbound.routed", "subscriber.subscribed",
                                 -- "subscriber.unsubscribed", "suppression.added", "campaign.started"
  subject_type VARCHAR,           -- "Subscriber" | "Campaign" | "Send" | "Inbound"
  subject_id BINARY(16),
  actor_type VARCHAR,
  actor_id VARCHAR,
  payload JSONB NOT NULL,
  idempotency_key VARCHAR,
  occurred_at TIMESTAMPTZ NOT NULL,
  inserted_at TIMESTAMPTZ NOT NULL
);
CREATE UNIQUE INDEX ON mailglass_events (idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE TRIGGER mailglass_events_immutable BEFORE UPDATE OR DELETE ON mailglass_events
  FOR EACH ROW EXECUTE FUNCTION mailglass_raise_immutability();
```

This single table is the source of truth for the admin "sent mail browser" timeline view, the webhook replay system, the bounce/complaint feed, the campaign analytics rollups, and compliance audit trails. **Every mutation goes through `Ecto.Multi` that writes the data row + the event row in the same transaction.** Idempotency keys (provider message IDs, webhook event IDs) make replays no-ops.

### 3.7 Polymorphic ownership

| Project | Choice |
|---|---|
| accrue | `owner_type VARCHAR + owner_id VARCHAR` — lossless across UUID/ULID/bigint host PKs, no FK to host schemas |
| sigra | Owns its own users; `%Scope{}` carries org context |
| scrypath, lattice_stripe | Single-tenant |

**Mailglass recommendation: adopt accrue's polymorphic ownership for `Subscriber`, `List`, `Campaign`, `Domain`.** Rationale: mailglass adopters will bring their own `User` / `Organization` / `Team` schemas. A polymorphic `(owner_type, owner_id)` pair with no FK avoids forcing a particular host schema shape.

```elixir
schema "mailglass_lists" do
  field :name, :string
  field :owner_type, :string  # "User" | "Organization" | "Team"
  field :owner_id, :string    # holds UUID/ULID/bigint as string
  ...
end
create unique_index(:mailglass_lists, [:owner_type, :owner_id, :name])
```

### 3.8 Ecto identifiers & timestamps

Convergent: `binary_id` UUID PKs, `timestamps(type: :utc_datetime_usec)` (microsecond precision for event ordering), no soft-delete via `deleted_at` on transactional tables (use status enums instead — accrue's lesson). Soft-delete only for adopter-facing aggregates like `List` and `Campaign` where audit history matters (sigra's pattern).

### 3.9 Dialyzer

| Project | Choice |
|---|---|
| accrue, sigra, scrypath | Yes, with split PLT cache strategy in CI |
| lattice_stripe | **No** (typespecs are doc-only) |

**Mailglass recommendation: yes, follow the 3-of-4 majority.** Dialyzer + split PLT cache. The PLT churn cost is real but manageable (accrue's pattern: cache restore → build only on miss → save).

### 3.10 ExDoc landing page

| Project | Choice |
|---|---|
| accrue | `main: "readme"` |
| lattice_stripe | `main: "getting-started"` |
| sigra | `main: "getting-started"` |
| scrypath | `main: "readme"` |

**Mailglass recommendation: `main: "getting-started"`** — guides better than READMEs at framing first-hour for a multi-feature framework. README stays for the GitHub front page; HexDocs lands on a guide.

---

## 4. Mailglass-specific translation

### 4.1 Public API surface (suggested shape)

```elixir
# Outbound — transactional & marketing send paths
Mailglass.send(email_or_attrs, opts \\ [])      # sync, returns {:ok, %Send{}} | {:error, %Error{}}
Mailglass.send!(email_or_attrs, opts \\ [])     # raises
Mailglass.deliver_later(email_or_attrs, opts)   # Oban-backed; requires :oban optional dep
Mailglass.batch_send(emails, opts)              # provider batch endpoint

# Templates
Mailglass.Template.render(key, assigns, opts)
Mailglass.Template.preview(key, assigns, opts)  # returns {html, text, subject}
Mailglass.Template.list()
Mailglass.Template.preview_props(key)           # React-Email-style PreviewProps callback

# Subscribers / Lists / Campaigns (marketing)
Mailglass.Subscribers.subscribe(list_or_id, attrs)
Mailglass.Subscribers.unsubscribe(subscriber, reason)
Mailglass.Subscribers.import(list, csv_or_stream)
Mailglass.Lists.create(owner, attrs)
Mailglass.Campaigns.draft(list, template_key, opts)
Mailglass.Campaigns.schedule(campaign, send_at)
Mailglass.Campaigns.send_now(campaign)
Mailglass.Campaigns.pause(campaign)

# Suppression / Compliance
Mailglass.Suppression.add(email, reason, opts)
Mailglass.Suppression.suppressed?(email)
Mailglass.Suppression.list(filters)
Mailglass.Compliance.add_unsubscribe_headers(email, opts)

# Webhooks (inbound provider events)
Mailglass.Webhook.process(provider, raw_body, signature_header)
# Provider-normalized event taxonomy (Anymail's, ported verbatim):
#   :queued | :sent | :rejected | :failed | :bounced | :deferred
#   | :delivered | :autoresponded | :opened | :clicked | :complained
#   | :unsubscribed | :subscribed | :unknown

# Inbound (ActionMailbox-style)
Mailglass.Inbound.route(raw_email, opts)
# Adopter declares Mailbox modules; Mailglass.Inbound.Router DSL matches and dispatches

# Reflection
Mailglass.config()                              # resolved config snapshot
Mailglass.adapters()                            # registered adapters
```

### 4.2 Behaviours (extension seams)

```elixir
@behaviour Mailglass.Adapter            # wraps a Swoosh.Adapter; adds telemetry, suppression check, event log
@behaviour Mailglass.TemplateEngine     # HEEx (default), MJML (via mrml NIF), Liquid (opt-in)
@behaviour Mailglass.PreviewStore       # in-memory (dev), S3, Redis
@behaviour Mailglass.SuppressionStore   # Ecto default; custom for Redis bloom filters etc.
@behaviour Mailglass.Webhook.Handler    # inbound provider event dispatch
@behaviour Mailglass.Inbound.Mailbox    # ActionMailbox-style routing target
@behaviour Mailglass.Auth               # current_actor, actor_can?, tenant_for
```

### 4.3 Schemas (first-pass, multi-tenant-safe)

```
mailglass_subscribers   (id, owner_type, owner_id, email, confirmed_at, unsubscribed_at, metadata, ts)
mailglass_lists         (id, owner_type, owner_id, name, archived_at, metadata, ts)
mailglass_list_members  (list_id, subscriber_id, joined_at, source) — with composite unique index
mailglass_campaigns     (id, owner_type, owner_id, list_id, template_key, subject, status, scheduled_at, sent_at, ts, lock_version)
mailglass_sends         (id, campaign_id, subscriber_id, message_id, provider, status, last_event_at, ts)
mailglass_suppressions  (id, owner_type, owner_id, email, reason, source, expires_at, ts)
mailglass_inbound       (id, owner_type, owner_id, mailbox, raw_mime, parsed, status, ts)
mailglass_domains       (id, owner_type, owner_id, hostname, dkim_public_key, verified_at, dns_status, ts)
mailglass_events        (append-only ledger; see §3.6)
```

Indices to lock in v0.1: `unique(owner_type, owner_id, email)` on subscribers, composite `(list_id, email)` for membership lookups, `(campaign_id, last_event_at DESC)` for admin timeline pagination, partial `unique(idempotency_key) where idempotency_key is not null` on events.

### 4.4 Mountable LiveView admin (sigra-flavored)

```
mailglass_admin/
  lib/mailglass_admin/
    router.ex               # mailglass_admin/2 macro → live_session + routes
    live/
      dashboard_live.ex     # send volume, queue depth, error rate
      sent_index_live.ex    # sent-mail browser w/ webhook timeline (Flop pagination)
      sent_show_live.ex     # individual send detail + replay button
      preview_index_live.ex # template gallery (React-Email-style)
      preview_show_live.ex  # render + device/dark-mode toggle, "send to me" button
      campaigns_index_live.ex
      campaigns_show_live.ex
      subscribers_index_live.ex
      suppression_index_live.ex
      inbound_conductor_live.ex  # ActionMailbox Conductor analog — synthesize inbound emails for dev
      webhook_log_live.ex
    components/
      copy.ex                    # SSOT for operator copy strings (accrue pattern)
      nav.ex
  priv/static/                   # committed esbuild/Tailwind output, CI verifies with git diff --exit-code
  test/example/                  # Playwright admin smoke target
```

Mounted in adopter's router:

```elixir
# lib/my_app_web/router.ex
import MailglassAdmin.Router

pipeline :require_admin, do: plug ...

scope "/mail-admin" do
  pipe_through [:browser, :require_admin]
  mailglass_admin "/", scope: MyApp.MailScope
end
```

### 4.5 Webhook plug (accrue/lattice_stripe pattern)

```elixir
defmodule MyAppWeb.Router do
  import Mailglass.Router

  scope "/webhooks", MyAppWeb do
    pipe_through :webhook_pipeline  # Plug.Parsers w/ {Mailglass.Webhook.CachingBodyReader, :read_body, []}
    mailglass_webhook "/postmark", provider: :postmark, secret: {MyApp.Secrets, :postmark_webhook, []}
    mailglass_webhook "/sendgrid", provider: :sendgrid
    mailglass_webhook "/mailgun",  provider: :mailgun
    mailglass_webhook "/ses",      provider: :ses
  end
end
```

Behind the scenes:
- `CachingBodyReader` preserves raw body bytes for HMAC verification before `Plug.Parsers` consumes the stream.
- `Mailglass.Webhook.Plug` verifies signature, parses, normalizes to the Anymail event taxonomy, dispatches to registered handlers.
- Failed signatures raise `Mailglass.SignatureError` — non-recoverable at call site (accrue's D-08 lesson).
- Each event is recorded in `mailglass_events` with provider's event ID as idempotency key — replays are safe no-ops.

### 4.6 Telemetry events (concrete catalog)

| Event | When | Key meta |
|---|---|---|
| `[:mailglass, :outbound, :send, :start]` | Before adapter `deliver/2` | `template_key`, `provider`, `tenant_id`, `recipient_count` |
| `[:mailglass, :outbound, :send, :stop]` | After delivery | `status`, `message_id`, `provider`, `latency_ms` |
| `[:mailglass, :outbound, :send, :exception]` | Adapter raised | `kind`, `reason`, `provider` |
| `[:mailglass, :outbound, :batch, :stop]` | Batch send done | `count`, `accepted`, `rejected` |
| `[:mailglass, :inbound, :receive, :stop]` | Inbound parsed | `provider`, `mailbox`, `bytes` |
| `[:mailglass, :inbound, :route, :no_match]` | No mailbox matched | `mailbox`, `from_domain` |
| `[:mailglass, :webhook, :signature, :verify, :fail]` | HMAC mismatch | `provider`, `header_present?` |
| `[:mailglass, :preview, :render, :exception]` | Template render crashed | `template_key`, `engine` |
| `[:mailglass, :ops, :bounce, :received]` | Hard bounce | `subscriber_id`, `bounce_type`, `provider` |
| `[:mailglass, :ops, :complaint, :received]` | FBL complaint | `subscriber_id`, `provider` |
| `[:mailglass, :ops, :unsubscribe, :received]` | One-click unsubscribe (RFC 8058) | `subscriber_id`, `list_id`, `source` |
| `[:mailglass, :ops, :dlq, :exhausted]` | Job retry budget hit | `job_args_digest`, `attempt` |

Operators wire just `[:mailglass, :ops, *]` for alerts. Dashboards wire the full tree.

### 4.7 Compliance & deliverability hooks (the bits Phoenix has nothing for)

These are the differentiated value props per the existing `Phoenix needs an email framework not another mailer.md` doc. Bake them in from v0.1:

- **`Mailglass.Compliance.add_unsubscribe_headers/1`** — RFC 8058 `List-Unsubscribe` + `List-Unsubscribe-Post: List-Unsubscribe=One-Click`. Auto-added by `Mailglass.send/2` for marketing sends; opt-out for transactional.
- **`Mailglass.Compliance.dkim_sign/2`** — wraps `mailibex` DKIM signing (currently the only Elixir DKIM lib, GitHub-only). Vendor it or upstream-fork.
- **`Mailglass.Compliance.dns_doctor/1`** — checks SPF/DKIM/DMARC for a sending domain. Surfaces in admin UI. (No Elixir lib does this today.)
- **`Mailglass.Suppression.check_before_send/1`** — auto-injected pipeline step; refuses to send to suppressed addresses. Returns `{:error, %SuppressedError{}}`.
- **Bounce/complaint normalization** — map every provider's webhook into a single `Mailglass.Webhook.Event` struct (Anymail taxonomy). One handler, all providers.

---

## 5. Project skeleton — the v0.1 starter shape

```
mailglass/                                # repo root (also Hex package root for `mailglass`)
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── MAINTAINING.md
├── LICENSE
├── SECURITY.md
├── CODE_OF_CONDUCT.md
├── mix.exs                               # @version, package whitelist, ExDoc config
├── .formatter.exs
├── .credo.exs                            # strict + requires: custom checks under lib/mailglass/credo/
├── .release-please-manifest.json
├── release-please-config.json
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                        # lint + matrix test + golden install + admin smoke
│   │   ├── release-please.yml
│   │   ├── publish-hex.yml               # workflow_dispatch fallback
│   │   └── verify-published-release.yml  # daily + manual
│   └── dependabot.yml
├── lib/
│   ├── mailglass.ex                      # public surface (reflection + facade)
│   ├── mailglass/
│   │   ├── application.ex
│   │   ├── config.ex                     # NimbleOptions schema + resolve!/1
│   │   ├── error.ex
│   │   ├── send_error.ex
│   │   ├── template_error.ex
│   │   ├── signature_error.ex
│   │   ├── suppressed_error.ex
│   │   ├── rate_limit_error.ex
│   │   ├── config_error.ex
│   │   ├── telemetry.ex                  # span/3, common_metadata/3, stop_metadata/2
│   │   ├── repo.ex                       # transact/1
│   │   ├── outbound/
│   │   ├── inbound/
│   │   ├── template/
│   │   ├── subscribers/
│   │   ├── lists/
│   │   ├── campaigns/
│   │   ├── suppression/
│   │   ├── compliance/
│   │   ├── webhook/                      # Plug, CachingBodyReader, Handler behaviour, Provider mappers
│   │   ├── adapter/                      # behaviour + Fake + SwooshBridge
│   │   ├── tenancy/                      # scope/2 + prepare_query/3 callback
│   │   ├── auth/                         # adapter behaviour + Sigra/PhxGenAuth/Anonymous
│   │   ├── events/                       # ledger writes via Ecto.Multi
│   │   ├── credo/                        # custom Credo checks
│   │   └── router.ex                     # mailglass_webhook/2 macro
│   └── mix/tasks/
│       ├── mailglass.install.ex
│       ├── verify.phase11.ex             # release-gate alias
│       ├── verify.release_publish.ex
│       └── verify.release_parity.ex
├── priv/
│   ├── repo/migrations/                  # template migrations included in Hex package
│   └── templates/mailglass.install/      # .eex templates rendered by installer
├── test/
│   ├── test_helper.exs                   # ExUnit.start(exclude: [:integration]); Mox.defmock(...)
│   ├── support/
│   │   ├── mailer_case.ex
│   │   ├── webhook_case.ex
│   │   ├── fixtures/
│   │   │   ├── email.ex
│   │   │   ├── subscriber.ex
│   │   │   └── webhook_payloads/
│   │   │       ├── postmark.ex
│   │   │       ├── sendgrid.ex
│   │   │       └── mailgun.ex
│   │   └── assertions/
│   │       ├── mailer_assertions.ex      # assert_email_sent/1
│   │       └── webhook_assertions.ex
│   ├── mailglass/
│   │   ├── docs_contract_test.exs        # locks README + guides to code
│   │   ├── outbound_test.exs
│   │   ├── webhook_test.exs
│   │   └── ...
│   ├── example/                          # full Phoenix host app for installer goldens + Playwright
│   │   ├── mix.exs
│   │   └── ...
│   └── fixtures/install/                 # snapshotted installer output trees
├── guides/
│   ├── getting-started.md
│   ├── golden-path.md                    # the 5-minute first-email walkthrough
│   ├── installation.md
│   ├── sending-transactional.md
│   ├── sending-marketing.md
│   ├── templating-with-heex.md
│   ├── templating-with-mjml.md
│   ├── preview-dashboard.md
│   ├── webhooks-postmark.md
│   ├── webhooks-sendgrid.md
│   ├── webhooks-mailgun.md
│   ├── webhooks-ses.md
│   ├── inbound-routing.md                # ActionMailbox-style
│   ├── deliverability-and-compliance.md  # SPF/DKIM/DMARC, List-Unsubscribe, suppression
│   ├── multi-tenancy.md
│   ├── auth-adapters.md
│   ├── testing.md
│   ├── telemetry.md
│   ├── monitoring-and-alerts.md
│   ├── admin-dashboard.md
│   ├── common-mistakes.md
│   ├── extension-points.md               # adapter behaviours
│   └── api_stability.md                  # public surface contract
├── docs/
│   └── (maintainer-only docs not shipped to Hex)
└── .planning/
    ├── PROJECT.md
    ├── ROADMAP.md
    ├── REQUIREMENTS.md
    ├── STATE.md
    ├── RETROSPECTIVE.md
    ├── milestone-candidates.md
    ├── milestones/
    ├── phases/
    ├── research/
    ├── intel/
    └── quick/
```

Plus the sibling package:

```
mailglass_admin/                          # second Hex package, sibling release
├── mix.exs                               # {:mailglass, "~> 0.1"} (Hex) or path-local in dev
├── lib/mailglass_admin/                  # router + LiveView modules + components
├── priv/static/                          # committed bundle, CI verifies via `git diff --exit-code`
├── assets/                               # esbuild + Tailwind sources
├── test/
└── docs/
    └── ops-ia.md                         # locked by docs_contract_test
```

---

## 6. Anti-patterns / gotchas (lessons explicitly learned)

Each item here was paid for in someone's commit history. Don't repay them.

1. **Don't ship `Application.compile_env!` for runtime settings.** Use `Application.get_env/2` + a `Mailglass.Config.resolve!/1` validated at boot via NimbleOptions. (accrue's pattern; saved them from a class of release-build configuration bugs.)

2. **Don't mutate or delete `mailglass_events` rows.** The Postgres trigger raises SQLSTATE 45A01. The lib catches and re-raises as `Mailglass.EventLedgerImmutableError`. This is a feature, not a bug. (accrue D-13.)

3. **Don't return errors from telemetry handlers, don't raise.** Telemetry is observability; raising breaks business logic for an obs failure. Log separately. (Convergent across all 4 libs.)

4. **Don't include raw recipient lists, raw bodies, or raw provider responses in telemetry meta.** Counts, statuses, IDs, latencies only. PII scrubbing is the *caller's* responsibility for the `:processor_error` field (accrue T-OBS-01).

5. **Don't pattern-match webhook signature failures and recover.** `Mailglass.SignatureError` raises at call site — there is no safe recovery from a forged webhook. (accrue D-08.)

6. **Don't let `mailglass_admin/priv/static/` drift from the committed bundle.** CI runs `git diff --exit-code` on `priv/static/` after rebuilding. If the diff is non-empty, the PR fails. (accrue admin-drift-docs lane.)

7. **Don't skip the milestone-archival step.** scrypath retro v1.5–v1.13: REQUIREMENTS.md ↔ ROADMAP.md drift becomes nightmarish if you defer to "next session." Update traceability rows in the same session as phase ship.

8. **Don't `mix.exs` auto-include the whole repo.** Always whitelist `files:` explicitly. Otherwise `test/example/` (~200MB after a build) ends up in the Hex tarball. (Universal lesson.)

9. **Don't write a kitchen-sink verify task.** `verify.everything` masks what broke. One `verify.phase<NN>` per focused concern. (scrypath v1.7 retro.)

10. **Don't ship Dialyzer warnings as warnings.** `mix dialyzer --halt-exit-status` in CI. `.dialyzer_ignore.exs` for known spurious warnings only — never to silence real signal. (accrue, sigra.)

11. **Don't rely on stripe-mock-style external services as the merge gate.** Use a Fake (in-process, deterministic) for the gate; provider sandboxes are advisory. (accrue release-gate vs live-stripe lanes.)

12. **Don't put secrets in workflow files.** Always GHA secrets. `RELEASE_PLEASE_TOKEN` (PAT fallback if org forbids "Actions create PRs"), `HEX_API_KEY`. Document setup in MAINTAINING.md. (sigra MAINTAINING.md.)

13. **Don't rebuild the dialyzer PLT every CI run.** Split cache into restore → build-on-miss → save. (accrue's pattern; cuts CI time substantially.)

14. **Don't forget `test_load_filters: [~r"^test/(?!example/|fixtures/)"]`** in `mix.exs` — otherwise root `mix test` tries to load the example Phoenix subproject. (sigra.)

15. **Don't skip the `verify.release_publish` poll-until-visible gate.** Hex tarball acceptance ≠ HexDocs reachability ≠ third-party package compiles against it. All 3 need to be checked separately, post-publish. (scrypath.)

16. **Don't mix planning-state updates into code commits.** `docs(state): ...` and `chore(planning): ...` are distinct commit types. CI path filters skip them, history stays scannable. (accrue, scrypath.)

17. **Don't introduce backwards-compat shims for removed code.** Delete cleanly; let semver carry the signal. Pre-1.0: minor bump on removal. Post-1.0: deprecation cycle (`@deprecated` in current major, removal in next major). (lattice_stripe `api_stability.md`.)

---

## 7. The opinionated GSD seed plan

Suggested initial milestone & phase structure (continuous phase counter, never resets):

| Milestone | Phases | Theme | Requirement code prefix |
|---|---|---|---|
| **v0.1 — Core outbound** | 1–6 | `Mailglass.send/2`, Fake adapter, Swoosh bridge, telemetry, error model, event ledger, NimbleOptions config | `SEND-NN` |
| **v0.2 — Templates & preview** | 7–11 | HEEx-based components w/ MSO fallbacks, preview_props callback, `Mailglass.Template.preview/3`, dev mailbox auto-refresh fix | `TPL-NN` |
| **v0.3 — Admin LiveView (`mailglass_admin`)** | 12–17 | Sibling package, mountable router, sent-mail browser, preview gallery, suppression manager, Playwright smoke | `ADMIN-NN` |
| **v0.4 — Subscribers & lists** | 18–22 | Schemas, polymorphic owner, CSV import, segmentation primitives | `SUBS-NN` |
| **v0.5 — Webhooks** | 23–28 | Plug, CachingBodyReader, signature verification per provider, Anymail-taxonomy normalization, replay system | `WH-NN` |
| **v0.6 — Compliance & deliverability** | 29–33 | List-Unsubscribe (RFC 8058), DKIM signing, DNS doctor, suppression auto-check pipeline | `COMPLY-NN` |
| **v0.7 — Inbound routing** | 34–39 | Ingress adapters, raw MIME parser, Mailbox routing DSL, Conductor-style dev synth UI | `INBND-NN` |
| **v0.8 — Marketing campaigns** | 40–45 | Draft → schedule → send_now → pause, Oban-backed worker chain, per-recipient send rows, analytics rollups | `CAMP-NN` |
| **v0.9 — Multi-tenancy hardening** | 46–49 | `Mailglass.Tenancy.scope/2`, prepare_query enforcement, Credo check, audit | `TENANT-NN` |
| **v1.0 — Stability commit** | 50–54 | `api_stability.md` lock, deprecation policy, full guide audit, release-runbook dry-run | `STAB-NN` |

Per-phase shape (every phase, no exceptions):
- `.planning/phases/NN-slug/PLAN.md` (created at open via `/gsd-plan-phase`)
- `.planning/phases/NN-slug/VERIFICATION.md` (the merge gate; lists exact `mix verify.phase<NN>` command)
- `.planning/phases/NN-slug/SUMMARY.md` (written at close; updates REQUIREMENTS.md traceability rows in the same session)
- A new `lib/mix/tasks/verify.phase<NN>.ex` mix task targeting just that phase's tests
- Commit scope: `feat(send-04-02): ...` (phase-tagged)

Backlog discipline (scrypath model):
- `milestone-candidates.md` ranks themes A/B/C/D
- A = ship now (in current milestone)
- B = next default pull only when tied to real adopter pain (issue, dogfood)
- C = defer until failure proven
- D = maintainer hygiene that's not product

---

## 8. Source map — where to look in each prior repo

When implementing a specific pattern, here's where the highest-fidelity reference code lives:

| Pattern | Best reference |
|---|---|
| Sibling-package mix.exs / Release Please linked versions | `~/projects/accrue/{accrue,accrue_admin}/mix.exs`, `~/projects/accrue/release-please-config.json` |
| Fake processor / in-memory test backend | `~/projects/accrue/accrue/lib/accrue/processor/fake.ex` |
| Append-only event ledger + Postgres immutability trigger | `~/projects/accrue/accrue/priv/repo/migrations/*events*.exs`, `~/projects/accrue/accrue/lib/accrue/events/` |
| Polymorphic ownership schema | `~/projects/accrue/accrue/lib/accrue/billing/customer.ex` |
| Webhook plug with CachingBodyReader | `~/projects/lattice_stripe/lib/lattice_stripe/webhook/plug.ex`, `~/projects/lattice_stripe/lib/lattice_stripe/webhook/cache_body_reader.ex` |
| Pluggable behaviours (Transport / Json / RetryStrategy) | `~/projects/lattice_stripe/lib/lattice_stripe/transport.ex`, `.../json.ex`, `.../retry_strategy.ex` |
| Error model + custom message/2 + closed-atom :type | `~/projects/lattice_stripe/lib/lattice_stripe/error.ex` |
| api_stability.md contract | `~/projects/lattice_stripe/guides/api_stability.md` |
| Mountable LiveView admin (router macro + live_session) | `~/projects/sigra/lib/sigra/admin/`, `~/projects/sigra/priv/templates/sigra.install/router.ex.eex` |
| Generated host code via installer (mix sigra.install) | `~/projects/sigra/lib/sigra/install/`, `~/projects/sigra/priv/templates/sigra.install/` |
| Golden-diff installer test | `~/projects/sigra/test/sigra/install/golden_diff_test.exs`, `~/projects/sigra/test/fixtures/` |
| `test/example/` Phoenix subproject + Playwright | `~/projects/sigra/test/example/` |
| Custom Credo checks loaded via `requires:` | `~/projects/sigra/lib/sigra/credo/`, `~/projects/sigra/.credo.exs` |
| Audit emit-only-on-Multi-commit pattern | `~/projects/sigra/lib/sigra/audit/`, search for `emit_telemetry_from_changes` |
| Doc-contract tests (lock README/guide snippets to code) | `~/projects/scrypath/test/scrypath/docs_contract_test.exs` |
| Per-phase verify mix tasks | `~/projects/scrypath/lib/mix/tasks/verify.phase*.ex` |
| Post-publish verification (`verify.release_publish` / `verify.release_parity`) | `~/projects/scrypath/lib/mix/tasks/verify.release_*.ex` |
| Standalone in-repo Phoenix companion app pattern | `~/projects/scrypath/scrypath_ops/` |
| `.planning/` discipline at scale (13 milestones, retros, candidates) | `~/projects/scrypath/.planning/{PROJECT,ROADMAP,RETROSPECTIVE,milestone-candidates}.md` |
| RELEASING.md / MAINTAINING.md runbook | `~/projects/accrue/RELEASING.md`, `~/projects/sigra/MAINTAINING.md` |
| Telemetry span wrapper + common_metadata/stop_metadata | `~/projects/scrypath/lib/scrypath/telemetry.ex`, `~/projects/lattice_stripe/lib/lattice_stripe/telemetry.ex` |

---

## 9. TL;DR — the 10 must-port wins, ranked

If mailglass adopts only 10 things from this doc, these 10 are the highest-leverage:

1. **Fake adapter as the required release-gate target.** Real providers are advisory.
2. **Append-only `mailglass_events` ledger with Postgres immutability trigger + idempotency-key UNIQUE index.** Every mutation in `Ecto.Multi`. Foundation for admin timeline, replay, analytics, audit.
3. **Conventional Commits + Release Please + post-publish verification.** Zero-touch releases from day 1.
4. **Sibling packages (`mailglass` + `mailglass_admin`) with linked versions.** Admin ships as a Hex-published mountable LiveView library, not a standalone ops app.
5. **Anymail-taxonomy webhook normalization** (queued / sent / delivered / bounced / complained / opened / clicked / unsubscribed / ...) dispatched to a single behaviour. One handler, all providers.
6. **Pluggable behaviours: `Adapter`, `TemplateEngine`, `PreviewStore`, `SuppressionStore`, `Webhook.Handler`, `Inbound.Mailbox`, `Auth`.** Adopters bring their own; we ship sensible defaults.
7. **Doc-contract tests from day 1.** Lock README/golden-path/guide snippets to actual code. CI fails on drift.
8. **Per-phase `verify.phase<NN>` mix tasks.** One task per focused concern. Never a kitchen-sink verifier.
9. **Custom Credo checks for domain rules** (`NoRawSwooshSendInLib`, `NoUnscopedTenantQueryInLib`, `RequiredListUnsubscribeHeaders`, `NoPiiInTelemetryMeta`).
10. **`.planning/` discipline with continuous phase counter, REQUIREMENTS.md traceability updated at phase close, evidence-led `milestone-candidates.md` triage.** Never reset phase numbers; never defer traceability updates.

These are not opinions. They are 4 different OSS Elixir libs, shipped to Hex, converging on the same answers. The DNA is the convergence.
