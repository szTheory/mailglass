# Phase 106: Day-2 Guides — Go-Live Checklist + Error/Troubleshooting Map - Context

**Gathered:** 2026-06-17 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Give adopters the day-2 runbooks they expect, as **docs-only** additions gated by
`test/mailglass/docs_contract_test.exs`:

1. **OPS-01** — new `guides/production-go-live-checklist.md`: a pre-production verification
   surface covering `mix mail.doctor` (DKIM/SPF/DMARC) + the Phase-104 `mix mailglass.doctor`
   webhook-wiring check, webhook secret provisioning/rotation, Oban queue sizing, per-tenant
   adapter routing, suppression strategy, telemetry/alerting wiring.
2. **OPS-02** — new `guides/errors-and-troubleshooting.md`: a unified map of every
   `Mailglass.Error` struct (the ten error modules) → cause → fix → remediation, routing
   canonical type/retryable truth to `docs/api_stability.md`.

Both guides registered in `mix.exs` `extras:` AND `groups_for_extras: [Guides: …]`, and gated by
new docs-contract assertions.

**Confined to:** docs/markdown (the two new `guides/*.md` files + cross-links from existing
guides), the docs registration in `mix.exs`, and the docs-contract test + helpers
(`test/mailglass/docs_contract_test.exs`, `test/support/docs_helpers.ex`). NO product code,
runtime-contract, schema, public-error-set, or installer/admin code changes. Friction-removal,
not feature growth (D-23 convergence holds). 105 → 106 serialize because both touch the `mix.exs`
docs lists + the docs-contract test.
</domain>

<decisions>
## Implementation Decisions

### OPS-02 — errors-and-troubleshooting.md: struct-organized, truth routed to api_stability.md
- **D-01:** `guides/errors-and-troubleshooting.md` is a single flat guide with **one `##`
  section per error struct** — ten sections: `SendError`, `TemplateError`, `SignatureError`,
  `SuppressedError`, `RateLimitError`, `ConfigError`, `EventLedgerImmutableError`,
  `TenancyError`, `StreamPolicyError`, `PublishError`. Each section gives type-atom → cause →
  fix → remediation. Use `##` (exactly two-hash) headings because `extract_block_after_heading/2`
  (`test/support/docs_helpers.ex:17-19`) matches `##` only; `###` would make any heading-anchored
  contract assertion silently return nil (false pass).
- **D-02:** The errors are **ten separate `defexception` modules**, each with its own closed
  `@types` set and `__types__/0` (`lib/mailglass/error.ex:5-8` confirms "no parent struct";
  `@error_modules` at `error.ex:65-76` enumerates all ten). The guide presents this accurately —
  it does NOT imply one parent struct with a single closed atom set.
- **D-03:** Route canonical type/retryable truth to `docs/api_stability.md` — do NOT restate the
  closed `:type` atom sets as authority in the guide. `api_stability.md:208-420` already holds the
  per-struct atom sets + `Retryable:` lines; duplicating them drifts the moment an atom is added
  (Honest-Surface lens). The guide's per-section "remediation" links/points to api_stability.md
  for the contract truth.
- **D-04:** The guide MUST cover `StreamPolicyError` and `PublishError` sourced from their module
  moduledocs directly (`lib/mailglass/errors/stream_policy_error.ex:12` `@types
  [:stream_policy_violated]`; PublishError), because `api_stability.md` documents PublishError
  (`:408-420`) but has **NO StreamPolicyError section at all**, and its `Mailglass.Error` summary
  still says "union of the six error structs" (`:214`). Trusting api_stability.md as complete
  would drop StreamPolicyError and fail the OPS-02 "every struct" coverage assertion.

### OPS-01 — production-go-live-checklist.md: thin orchestrating checklist, two distinct doctors
- **D-05:** `guides/production-go-live-checklist.md` is a **thin orchestrating checklist that
  cross-links the existing topic guides** rather than re-explaining them — one `##` section per
  topic. House pattern is cross-link-not-duplicate (`guides/webhook-troubleshooting.md:1-9` is an
  explicit shim). Sub-topic detail stays in: `multi-tenancy.md` (per-tenant routing),
  `telemetry.md` (telemetry/alerting), `dkim-setup.md` (DKIM detail), `rate-limiting.md`,
  `unsubscribe.md`, and the suppression APIs.
- **D-06:** Surface `mix mail.doctor` and `mix mailglass.doctor` as **two distinct commands** with
  distinct purposes — do NOT conflate them. `mix mail.doctor --domain` runs DNS DKIM/SPF/DMARC
  checks and requires `app.start` (`lib/mix/tasks/mail.doctor.ex:8-19,35`); `mix mailglass.doctor`
  is the Phase-104 OFFLINE static endpoint webhook-wiring scan with a three-state exit code
  (`lib/mix/tasks/mailglass.doctor.ex:6-31,98-104`; `lib/mailglass/installer/doctor.ex`). Both
  literal command strings must appear (the requirement names both; the contract assertion will
  likely require both literals present).
- **D-07:** Checklist topic coverage (one `##` section each): `mix mail.doctor` deliverability,
  `mix mailglass.doctor` webhook-wiring (INSTALL-03), webhook secret provisioning/rotation, Oban
  queue sizing, per-tenant adapter routing, suppression strategy, telemetry/alerting wiring.

### OPS-02 — relationship to existing incident/webhook guides: cross-link, do not absorb
- **D-08:** `errors-and-troubleshooting.md` is a **NEW guide that cross-links — does not absorb or
  duplicate** — the existing `guides/operator-incident-support.md` (symptom-first incident
  runbook: symptom→telemetry→repair) and `guides/webhook-troubleshooting.md` (shim). The new guide
  is organized **by error struct**; the incident guide stays organized **by customer symptom** —
  two complementary axes. Absorbing them would break the Phase-33/Phase-61 contract assertions
  that pin specific strings in those files (`docs_contract_test.exs:231-263, :359-375`). Neither
  existing file is in `mix.exs` extras; OPS-02 requires the NEW guide to be registered there
  (so "register the existing file instead" does not satisfy the requirement).

### Docs-contract assertions + mix.exs registration
- **D-09:** Add new `describe`-block tests to `test/mailglass/docs_contract_test.exs` mirroring
  existing patterns: (1) **OPS-02 error-coverage** — all ten error module names appear literally in
  `errors-and-troubleshooting.md` (drive the list from `Mailglass.Error.@error_modules` /
  `__info__` so the assertion is self-maintaining), plus an `api_stability.md` route-link
  assertion; (2) **OPS-01 section-presence** — checklist contains the key literals (`mix
  mail.doctor`, `mix mailglass.doctor`, rotation / Oban / suppression / telemetry section
  markers). Section-presence-by-literal is the dominant existing pattern
  (`docs_contract_test.exs:240-263, :328-341`).
- **D-10:** Add a **registration test** mirroring the `learning-path` check
  (`docs_contract_test.exs:158-168`): `Regex.scan(~r/"guides\/X\.md"/, mix_exs)` asserting `>= 2`
  occurrences (one in `extras:`, one in the `Guides:` group) + `File.exists?` — applied to both
  new guides. Append both guides to `extras:` (mix.exs ~383-407) AND to the `Guides:` group in
  `groups_for_extras:` (mix.exs ~408-431, group named `Guides:` at ~:414). Keep
  `main: "getting-started"` (mix.exs:357) unchanged.

### Claude's Discretion (planner decides)
- Exact ordering of the two new guides within `extras:` / the `Guides:` group.
- Exact heading text and prose voice per section (match house style in `getting-started.md` /
  `telemetry.md`), as long as fenced code blocks a contract assertion locates by heading sit
  under `##` headings.
- Whether the error-coverage assertion matches module short names (e.g. `SendError`) or their
  `__types__` discriminators — short names recommended for readability.
- Exact literal markers chosen for the OPS-01 section-presence assertion.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — OPS-01 / OPS-02 acceptance criteria (~63-72) + v1.12 docs
  guardrails (every code block parses; canonical vocabulary; no over-claims; new guides in BOTH
  `extras:` and `groups_for_extras:`).
- `.planning/ROADMAP.md` — Phase 106 block (~71-83): goal, depends-on-105, success criteria.
- `lib/mailglass/error.ex` — the ten error modules registry: `@error_modules` (65-76), `@type t`
  (47-57), "no parent struct" note (5-8). **Source of the 10-name coverage list.**
- `lib/mailglass/errors/*.ex` — the ten `defexception` modules with closed `@types` /
  `__types__/0`: `send_error.ex`, `template_error.ex`, `signature_error.ex`,
  `suppressed_error.ex`, `rate_limit_error.ex`, `config_error.ex`,
  `event_ledger_immutable_error.ex`, `tenancy_error.ex`, `stream_policy_error.ex` (`:12`
  `@types [:stream_policy_violated]`), `publish_error.ex`. Primary source for cause/fix prose,
  especially StreamPolicyError (absent from api_stability.md).
- `docs/api_stability.md` — canonical per-struct atom sets + `Retryable:` lines (208-420);
  PublishError (408-420). **Route truth here, do not duplicate.** NOTE the stale summary counts
  (see Deferred Ideas).
- `lib/mix/tasks/mail.doctor.ex` (8-19,35) — deliverability DKIM/SPF/DMARC doctor (`--domain`,
  needs `app.start`).
- `lib/mix/tasks/mailglass.doctor.ex` (6-31,98-104) + `lib/mailglass/installer/doctor.ex` —
  Phase-104 offline webhook-wiring doctor with three-state exit code.
- `test/mailglass/docs_contract_test.exs` — THE gate. Patterns to mirror: `learning-path`
  registration test (158-168), section-presence-by-literal (240-263, 328-341), trust-doc route
  assertion (359-375). Add new OPS-01/02 assertions here.
- `test/support/docs_helpers.ex` — `extract_code_blocks/1` (elixir|bash|sql fences) and
  `extract_block_after_heading/2` (matches `##` ONLY, :17-19) — the extraction contract that
  constrains heading structure.
- `mix.exs` — `extras:` (~383-407), `groups_for_extras: [Guides: …]` (~408-431, group at ~:414),
  `main: "getting-started"` (357). Both new guides registered in BOTH lists.
- Existing topic guides the checklist cross-links: `guides/multi-tenancy.md`, `guides/telemetry.md`,
  `guides/dkim-setup.md`, `guides/rate-limiting.md`, `guides/unsubscribe.md`,
  `guides/webhooks.md`.
- Existing incident guides the error guide cross-links (do NOT absorb):
  `guides/operator-incident-support.md` (canonical symptom-first runbook, :1-3),
  `guides/webhook-troubleshooting.md` (shim, :1-9). Both pinned by contract assertions.
- `.planning/phases/105-.../105-CONTEXT.md` — prior-phase locks: registration-in-both-lists rule,
  `##`-heading discipline, docs-contract gate patterns.
- `.planning/METHODOLOGY.md` — active lenses: Decisive-By-Default, Honest Surface Area,
  Recommendation-First Synthesis.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Error.@error_modules` (`lib/mailglass/error.ex:65-76`) is the authoritative ten-name
  list — drive the OPS-02 coverage assertion from it so the test self-maintains if a module is
  ever added/removed.
- The `learning-path` registration test (`docs_contract_test.exs:158-168`) and the
  section-presence-by-literal tests (240-263, 328-341) are exact templates for the two new
  OPS-01/02 assertion shapes.
- Existing topic guides already cover every checklist sub-topic — the checklist orchestrates and
  links them rather than re-explaining (matches the `webhook-troubleshooting.md` shim pattern).

### Established Patterns
- Every new/edited guide is gated by `docs_contract_test.exs`; new guarantees land as new
  assertions there. Heading-scoped code blocks require `##` (two-hash) headings.
- New guides registered in BOTH `mix.exs` lists (v1.12 docs guardrail; the `>= 2`-occurrences
  test enforces it). Canonical telemetry/error vocabulary from `docs/api_stability.md`. No
  over-claims (Honest-Surface lens).
- Cross-link-not-duplicate: canonical guide owns the content; shims/checklists point at it.
- Docs-only commits are release-safe under release-please defaults (`docs:` type).

### Integration Points
- `errors-and-troubleshooting.md` → per-struct sections route to `docs/api_stability.md` for
  contract truth → new error-coverage + route-link assertions; cross-links (not absorbs)
  `operator-incident-support.md` + `webhook-troubleshooting.md`.
- `production-go-live-checklist.md` → cross-links `multi-tenancy.md` / `telemetry.md` /
  `dkim-setup.md` / `rate-limiting.md` / `unsubscribe.md`; surfaces both doctor commands → new
  section-presence assertion.
- Both new guides → `mix.exs` `extras:` + `groups_for_extras: [Guides:]` → registration test.
</code_context>

<specifics>
## Specific Ideas

- Two doctors, two names, two purposes — never conflate: `mix mail.doctor` (DNS/deliverability,
  needs app.start) vs `mix mailglass.doctor` (offline webhook-wiring, three-state exit).
- The error guide is organized by error STRUCT; the existing incident guide is organized by
  customer SYMPTOM — complementary axes, cross-linked, never merged.
- Drive the 10-name coverage assertion from `@error_modules`, not a hardcoded list.
- StreamPolicyError is the trap: present in the modules but missing from api_stability.md — source
  its prose from the module moduledoc, and do not skip it.
</specifics>

<deferred>
## Deferred Ideas

- **Stale error counts in `docs/api_stability.md`** — the `Mailglass.Error` summary says "union of
  the six error structs" (`:214`), the module union (`:56-60`) lists nine names and omits
  StreamPolicyError, and `error.ex:5` moduledoc says "eight" while `@error_modules` enumerates ten.
  Fixing these counts + adding a StreamPolicyError section to api_stability.md is **adjacent but
  technically out of Phase-106 (docs-only-guides) scope**. Flagged for the planner: either fold a
  minimal api_stability.md count/StreamPolicyError correction into this phase if low-risk, or note
  it as a follow-up. Phase 106 itself must still cover StreamPolicyError in the new guide
  regardless (D-04).
- Inbound replay-modal a11y parity — Phase 107 (A11Y-01).
- The actual Hex release + D-13 inbound exact-pin re-pin — Phase 108 (REL-01/02).
- Broader rewrites of existing guides (operator-incident-support.md, webhooks.md, etc.) beyond
  cross-linking — out of scope; this phase is the two new day-2 guides only.

### Reviewed Todos (not folded)
None — `todo.match-phase` returned 0 matches for Phase 106.
</deferred>
