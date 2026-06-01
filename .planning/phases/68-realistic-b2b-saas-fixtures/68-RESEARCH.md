# Phase 68: Realistic B2B SaaS Fixtures - Research

**Researched:** 2026-06-01
**Domain:** Deterministic B2B SaaS demo data fixtures for Phoenix/Ecto + Mailglass schemas
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Fixture Scope
- **D-01:** Expand the existing `MailglassDemo.DemoData` seed/reset path rather
  than replacing it with a separate fixture framework. The phase should deepen
  the deterministic corpus already used by `mix demo.reset`.
- **D-02:** Keep the destructive fast reset command as the canonical maintainer
  reset path for this phase: `mix demo.reset`, backed by `priv/repo/seeds.exs`.
  Reset must truncate the demo Mailglass tables, restart identities, and reseed
  fixed data without rebuilding the schema.
- **D-03:** Keep fixture implementation under the demo app namespace. Demo-only
  data helpers belong under `MailglassDemo*`, not under `lib/mailglass*`,
  `mailglass_admin`, or `mailglass_inbound`.

### Scenario Corpus
- **D-04:** Deepen the existing Northstar Ops story instead of broadening into a
  provider matrix. The demo should feel like one coherent B2B SaaS operations
  workspace with believable invite/auth, billing, usage, support, bounce,
  suppression, webhook replay, inbound replay, and no-match stories.
- **D-05:** Seed outbound data with realistic delivery state variety: successful
  invite/auth and receipt cases, operational alert/bounce or failure cases,
  suppression-linked cases, and replayable webhook evidence that operator
  surfaces can inspect later.
- **D-06:** Seed inbound data with realistic stored truth: support replies,
  provider evidence, routing outcomes, fresh execution, replay execution, and at
  least one intentional no-match case. Include enough metadata for operator
  surfaces to explain why each record exists.
- **D-07:** Do not treat Phase 68 as provider breadth work. Representative
  provider labels are fine when they make scenarios concrete, but broad
  provider-matrix coverage remains deferred by v1.5 requirements.

### Mailables
- **D-08:** Keep demo mailables under `MailglassDemoWeb.Mailers.*` and use only
  public `Mailglass.Mailable` / `Mailglass.Message` APIs.
- **D-09:** Preserve and enrich the current preview scenario families:
  account invite/auth, billing receipt/payment, and operations usage/incident
  mail. Preview props should be deterministic and realistic enough for Phase 70
  browser evidence to assert rendered scenario identity without relying on
  private DOM shape.
- **D-10:** Mailer examples should read like B2B SaaS operational email, not
  marketing campaigns. Keep copy calm, concrete, and tied to the operator
  evidence story.

### Inbound And Replay Semantics
- **D-11:** Seed inbound truth directly through the package-owned inbound record,
  evidence, and execution-run insertion helpers already used by the demo app.
  Preserve stored-truth semantics: replay rows describe processing stored
  evidence, not a fresh provider receive.
- **D-12:** Preserve explicit fresh versus replay execution lineage. Inbound
  records that are replayed should have both original `:fresh` and subsequent
  `:replay` execution rows where appropriate.
- **D-13:** Keep no-match and rejection/bounce-style examples within existing
  inbound routing/mailbox semantics. Do not add new public router or mailbox
  API just to support fixtures.

### Verification
- **D-14:** Add focused deterministic seed/reset tests for Phase 68: row counts,
  stable provider/message IDs, stable event/outcome sets, suppression linkage,
  inbound evidence/run coverage, and mailer preview scenario coverage.
- **D-15:** Verification should prove the fixture corpus is deterministic and
  complete for DATA-01..DATA-04. Browser journey proof, screenshots, and
  checkpoint artifacts remain Phase 70 work.
- **D-16:** Keep assertions at the demo data contract level. Do not assert
  MailglassAdmin DOM shape, LiveView internals, or private package module
  details as stable public API.

### the agent's Discretion
- Exact scenario names, counts, provider labels, timestamps, and metadata keys,
  as long as they are deterministic, realistic, and cover DATA-01..DATA-04.
- Whether to keep all fixture helpers in `DemoData` or split small private
  helper modules under `MailglassDemo`, provided the public reset surface stays
  simple.
- Exact test module organization, provided tests make fixture completeness and
  reset determinism clear.

### Deferred Ideas (OUT OF SCOPE)
- Provider-matrix demo breadth beyond representative seeded stories remains
  deferred by FUTR-02.
- Published-Hex-only demo gate after the live `mailglass_inbound` `1.0.0`
  release remains FUTR-01.
- Click-around dashboard/navigation/docs are Phase 69.
- Playwright browser evidence, screenshots, and checkpoints are Phase 70.

No reviewed todos were folded or deferred; `todo.match-phase 68` returned no
matches.
</user_constraints>

## Summary

Phase 68 should extend the existing deterministic fixture seam (`MailglassDemo.DemoData.reset!/0` + `mix demo.reset`) rather than introducing new infrastructure, and keep all changes inside `reference/demo_app` namespaces. [VERIFIED: codebase grep]

The fastest safe path is to grow scenario richness by adding deterministic rows that still obey existing closed enums and insertion contracts for outbound deliveries/events/webhooks/suppressions and inbound records/evidence/execution runs. [VERIFIED: codebase grep]

Primary recommendation: implement fixture expansion as scenario-oriented helper functions in `MailglassDemo.DemoData`, then strengthen `demo_data_reset_test.exs` to assert named scenario contracts and fresh/replay lineage determinism. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Deterministic reset command | API / Backend | Database / Storage | `mix demo.reset` executes server-side seed script and truncation/reseed logic. [VERIFIED: codebase grep] |
| Outbound fixture corpus | Database / Storage | API / Backend | Fixture rows persist in Mailglass tables and are produced via Ecto changesets/helpers. [VERIFIED: codebase grep] |
| Inbound evidence + replay lineage corpus | Database / Storage | API / Backend | Inbound record/evidence/execution rows are stored truth and replay lineage state. [VERIFIED: codebase grep] |
| Preview mailable realism | API / Backend | Browser / Client | Mailers/preview props are generated server-side and rendered in preview UI later. [VERIFIED: codebase grep] |
| Determinism verification tests | API / Backend | Database / Storage | ExUnit validates repeatable seeded state and identity restart. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Demo fixture logic and tests | Existing demo app/runtime uses Elixir + Mix. [VERIFIED: codebase grep] |
| Phoenix | `~> 1.8` | Demo app web shell and preview routes | Already pinned in demo app dependencies. [VERIFIED: codebase grep] |
| Ecto SQL | `~> 3.13` | Seed inserts, truncation, and test queries | Existing `DemoData` and tests rely on Ecto/Repo semantics. [VERIFIED: codebase grep] |
| Mailglass | `~> 1.3` (hex mode) / local path | Public mailable/message and outbound schemas | Locked by phase decisions to public seams. [VERIFIED: codebase grep] |
| MailglassInbound | `~> 0.3.0` (hex mode) / local path | Inbound record/evidence/execution helpers | Existing seed path already uses `InboundRecords.insert_*`. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| PostgreSQL | 14.17 (local env) | Deterministic relational fixture storage | Required for local reset/test execution. [VERIFIED: codebase grep] |
| Node.js | 22.14.0 | Demo asset/e2e lane support | Needed for broader demo workflows, not core Phase 68 fixture logic. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend `MailglassDemo.DemoData` | New fixture framework/library | Contradicts locked D-01 and adds unnecessary moving parts. [VERIFIED: codebase grep] |
| `mix demo.reset` reseed path | Full `ecto.reset` (drop + migrate) | Slower, breaks locked “truncate + reseed only” path. [VERIFIED: codebase grep] |

**Installation:** No new external packages are required for this phase scope. [VERIFIED: codebase grep]

## Package Legitimacy Audit

Not required for Phase 68 as scoped: no new third-party package installation is recommended. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
mix demo.reset
   |
   v
priv/repo/seeds.exs
   |
   v
MailglassDemo.DemoData.reset!/0
   |------------------------------|
   v                              v
truncate!()                 seed_outbound!() + seed_inbound!()
   |                              |
   v                              v
mailglass_* tables         Delivery/Event/Webhook/Suppression + InboundRecords helpers
   |                              |
   |------------------------------|
                  v
        deterministic corpus for preview/operator surfaces
                  |
                  v
      ExUnit deterministic contract tests
```

### Recommended Project Structure
```text
reference/demo_app/
├── lib/mailglass_demo/demo_data.ex        # deterministic reset + scenario seeders
├── lib/mailglass_demo_web/mailers/        # preview scenario families
├── priv/repo/seeds.exs                    # reset entrypoint
└── test/mailglass_demo/                   # deterministic fixture contract tests
```

### Pattern 1: Scenario-First Seed Builders
**What:** Build one helper per business scenario, then compose in `seed_outbound!`/`seed_inbound!`. [VERIFIED: codebase grep]
**When to use:** Adding DATA-02/DATA-03 realism while preserving determinism. [VERIFIED: codebase grep]

### Pattern 2: Stored-Truth Replay Lineage
**What:** Insert inbound record/evidence once, then add `:fresh` and `:replay` execution rows referencing same stored evidence. [VERIFIED: codebase grep]
**When to use:** Any replayable inbound example. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- **Provider-matrix explosion:** Broadening providers violates D-07 and FUTR-02 scope. [VERIFIED: codebase grep]
- **Private seam coupling:** Seeding via private internals instead of public helper APIs violates D-08/D-11. [VERIFIED: codebase grep]
- **DOM-shape assertions in fixture tests:** Violates D-16; keep tests at data-contract level. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Inbound persistence | Custom SQL inserters for inbound rows | `MailglassInbound.InboundRecords.insert_*` helpers | Keeps canonical validation semantics for execution outcomes and replay shape. [VERIFIED: codebase grep] |
| Email construction | Raw map builders for mail payloads | `Mailglass.Mailable` + `Mailglass.Message` | Keeps preview scenarios on public contract seam. [VERIFIED: codebase grep] |
| Reset orchestration | New reset command framework | Existing `mix demo.reset` via `seeds.exs` | Already integrated in demo workflows and phase lock decisions. [VERIFIED: codebase grep] |

**Key insight:** This phase is corpus depth, not infrastructure invention. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Breaking Determinism With Non-Fixed Time/IDs
**What goes wrong:** Data changes between runs and tests become flaky. [VERIFIED: codebase grep]
**Why it happens:** Using `DateTime.utc_now/0` or random IDs in fixture generation paths. [VERIFIED: codebase grep]
**How to avoid:** Keep fixed `@now`, fixed scenario IDs/provider IDs, and stable ordering assertions. [VERIFIED: codebase grep]
**Warning signs:** Snapshot mismatch after back-to-back `DemoData.reset!()` calls. [VERIFIED: codebase grep]

### Pitfall 2: Seeding Invalid Enum States
**What goes wrong:** Changesets reject inserts or rows become semantically invalid. [VERIFIED: codebase grep]
**Why it happens:** Fixture values drift from closed enum sets (`Delivery`, `Event`, `ExecutionRun`, `Suppression`). [VERIFIED: codebase grep]
**How to avoid:** Only use schema-declared enums and existing valid outcome shapes. [VERIFIED: codebase grep]
**Warning signs:** Changeset errors on `outcome`, `status`, `reason`, or `type`. [VERIFIED: codebase grep]

### Pitfall 3: Mis-modeling Replay As Fresh Ingress
**What goes wrong:** Operator evidence becomes misleading. [VERIFIED: codebase grep]
**Why it happens:** Creating a second inbound record instead of replay execution row on stored evidence. [VERIFIED: codebase grep]
**How to avoid:** One canonical record/evidence pair, multiple execution rows with `source` lineage. [VERIFIED: codebase grep]
**Warning signs:** Duplicate provider_message_ids representing the same story. [VERIFIED: codebase grep]

## Code Examples

### Deterministic Reset Contract Test Shape
```elixir
DemoData.reset!()
baseline = snapshot()
insert_noise()
DemoData.reset!()
rerun = snapshot()
assert Map.take(rerun, deterministic_keys()) == Map.take(baseline, deterministic_keys())
```
Source: `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Minimal demo seeds only | Scenario-rich deterministic fixture corpus | Phase 68 scope (2026-06-01) | Better operator confidence for DATA-01..04 and later browser evidence. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Treating fixture tests as count-only checks is insufficient for this phase; scenario identity assertions are now required. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None | — | — |

All substantive claims above are verified against this repository context.

## Open Questions (RESOLVED)

1. **Exact scenario corpus size**
   - RESOLVED: Lock the corpus to ten named business scenarios: six outbound stories (`invite_admin`, `magic_link`, `receipt_paid`, `payment_failed`, `usage_alert`, `incident_update`) and four inbound stories (`support_reply`, `refund_request`, `spam_reject`, `inbound_no_match`). [RESOLVED]
   - RESOLVED: Derive fixed coverage counts from that scenario list: six deliveries, two webhook evidence rows, one suppression row, four inbound records, four inbound evidence rows, and six inbound execution rows with explicit `:fresh`/`:replay` lineage where applicable. [RESOLVED]
   - RESOLVED: Keep the naming taxonomy scenario-first and operator-readable, with exact provider/message IDs pinned in Plan `68-01` so downstream tests can assert scenario identity instead of counts alone. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Fixture/test implementation | ✓ | 1.19.5 | — |
| Mix | Reset/test commands | ✓ | OTP 28 runtime reported | — |
| PostgreSQL CLI | Local DB operations | ✓ | 14.17 | Use dockerized DB if local service absent |
| Docker | Compose demo workflows | ✓ | 29.5.2 | Direct local `mix` workflow |
| Node.js/npm | Demo asset/e2e lane | ✓ | 22.14.0 / 11.1.0 | Skip e2e in this phase |

**Missing dependencies with no fallback:**
- None. [VERIFIED: codebase grep]

**Missing dependencies with fallback:**
- None. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Phoenix/Ecto test stack) |
| Repo-root config file | `mix.exs` |
| Demo-app local config file | `reference/demo_app/mix.exs` |
| Canonical quick run command | `mix test test/mailglass/demo_data_test.exs` (repo root, after Plan `68-01` Task 2 creates the wrapper) |
| Bootstrap fallback command | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/demo_data_reset_test.exs --warnings-as-errors` (inside `reference/demo_app`, while implementing Plan `68-01` Task 1 before the root wrapper exists) |
| Demo-app targeted fallback | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/*.exs --warnings-as-errors` |
| Full suite command | `mix test` (repo root) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Deterministic one-command reset | unit/integration | `mix test test/mailglass/demo_data_test.exs` (repo root canonical quick gate once created; bootstrap with the demo-app fallback above during Plan `68-01` Task 1) | ❌ Wave 0 |
| DATA-02 | Realistic outbound/events/suppression/webhook fixtures | integration | `mix test test/mailglass/demo_data_test.exs` (repo root canonical quick gate once created; bootstrap with the demo-app fallback above during Plan `68-01` Task 1) | ❌ Wave 0 |
| DATA-03 | Realistic inbound/evidence/routing/replay/no-match fixtures | integration | `mix test test/mailglass/demo_data_test.exs` (repo root canonical quick gate once created; bootstrap with the demo-app fallback above during Plan `68-01` Task 1) | ❌ Wave 0 |
| DATA-04 | Realistic preview scenarios by family | unit | `mix test test/mailglass/demo_data_test.exs` (repo root canonical quick gate after Plan `68-02` adds preview tests; demo-app fallback remains `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/*.exs --warnings-as-errors`) | ❌ Wave 0 |

### Sampling Rate
- **Bootstrap during Plan `68-01` Task 1:** `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/demo_data_reset_test.exs --warnings-as-errors`
- **Per task commit after the root wrapper exists:** `mix test test/mailglass/demo_data_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- [ ] `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` — explicit DATA-04 scenario-family coverage
- [ ] Extend `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` with named scenario assertions beyond counts

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A for fixture-seeding scope |
| V3 Session Management | no | N/A for fixture-seeding scope |
| V4 Access Control | yes | Keep reset path as explicit destructive maintainer endpoint/tokenized workflow |
| V5 Input Validation | yes | Reuse schema changeset validation and closed enums |
| V6 Cryptography | no | No cryptographic feature work in this phase |

### Known Threat Patterns for Elixir/Phoenix fixture seeding

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsafe raw SQL scope creep in reset | Tampering | Keep truncate target list explicit and limited to demo tables |
| Fixture secrets/PII leakage in test logs | Information Disclosure | Use synthetic deterministic data only; avoid real user data |
| Replay lineage falsification | Repudiation | Preserve stored-truth record/evidence + explicit `:fresh`/`:replay` rows |

## Sources

### Primary (HIGH confidence)
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` - current reset/seed contracts and fixed tenant/time
- `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` - existing determinism assertions
- `reference/demo_app/mix.exs` - canonical `demo.reset` alias and dependency pins
- `reference/demo_app/priv/repo/seeds.exs` - reset entrypoint behavior
- `reference/demo_app/lib/mailglass_demo_web/mailers/*.ex` - preview scenario families
- `lib/mailglass/outbound/delivery.ex` - outbound enums/shape
- `lib/mailglass/events/event.ex` - event enums/shape
- `lib/mailglass/webhook/webhook_event.ex` - webhook status/shape
- `lib/mailglass/suppression/entry.ex` - suppression enum/coupling rules
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex` - inbound lineage enums/outcome constraints
- `.planning/phases/68-realistic-b2b-saas-fixtures/68-CONTEXT.md` - locked decisions and scope boundaries
- `.planning/REQUIREMENTS.md` - DATA-01..DATA-04 requirements mapping
- `.planning/ROADMAP.md` - phase sequencing and v1.5 objective
- `.planning/config.json` - nyquist validation enabled

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - directly pinned in repo and current environment checks
- Architecture: HIGH - phase boundaries and seams are explicitly locked in CONTEXT.md + code
- Pitfalls: HIGH - derived from deterministic reset/test patterns and schema constraints in code

**Research date:** 2026-06-01
**Valid until:** 2026-07-01
