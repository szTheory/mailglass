# Phase 25: deliverability-doctor - Context

**Gathered:** 2026-05-01 (assumptions mode, research-backed)
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `mix mail.doctor` as a DNS-focused deliverability diagnostic for one sending domain at a time. Phase 25 covers SPF, DKIM, DMARC, MX, and BIMI findings with honest classification and operator-facing remediation.

This phase is not an inbox-placement grader, not a provider API integration, not a reputation monitor, and not a general admin UI feature. It should tell the truth about what DNS can confirm, what it cannot confirm, and what the operator should fix next.

</domain>

<decisions>
## Implementation Decisions

### Scope posture
- **D-25-01:** Phase 25 stays DNS-only. Do not add provider API checks, inbox-placement scoring, complaint/reputation heuristics, or generalized “deliverability grade” output.
- **D-25-02:** The task should ship standards-aware structural checks plus tightly bounded policy advisories. It should report DNS truth and operational implications, not pretend to prove full delivery outcomes.
- **D-25-03:** `mix mail.doctor` should remain usable without requiring admin UI, Oban, or database-backed operator workflows. Do not make Phase 25 depend on `Repo`, `mailglass_events`, or other persistence surfaces just to run diagnostics.

### CLI contract
- **D-25-04:** The only canonical target contract is `mix mail.doctor --domain example.com`. Do not accept ambient domain inference from endpoint/config/tenant state, and do not make positional-argument parsing the primary interface.
- **D-25-05:** Phase 25 should operate on exactly one domain per invocation. Do not add multi-domain batch mode in v0.4.
- **D-25-06:** DKIM selector validation requires explicit selector knowledge. If selectors are not provided, the task must report an honest `cannot_verify` finding rather than guessing likely selectors or claiming DKIM absence.
- **D-25-07:** If selector-specific validation is exposed in the CLI, prefer explicit repeatable input such as `--dkim-selector` over provider guesswork or hidden defaults.

### Findings model and output UX
- **D-25-08:** Findings are classified only as `pass`, `warn`, `fail`, or `cannot_verify`, matching the locked requirement surface.
- **D-25-09:** Default output is human-first and grouped by protocol area: `SPF`, `DKIM`, `DMARC`, `MX`, and `BIMI`, with a short top summary and per-finding remediation.
- **D-25-10:** Each finding should carry the same conceptual fields even when rendered for humans:
  - title
  - why it matters
  - observed
  - remediation
- **D-25-11:** Add `--verbose` to expose supporting evidence inline without making the default output noisy.
- **D-25-12:** Add `--format json` from the first release so the same result model can power future CI/editor/admin surfaces without text scraping. Keep the JSON shape versionable from day one.
- **D-25-13:** `cannot_verify` is a first-class honest outcome, not an edge case. Unknown DKIM selectors, DNS timeouts, transient resolver failures, and other low-certainty states must not be flattened into `fail`.

### Protocol-specific check posture
- **D-25-14:** SPF should check for record presence, record uniqueness, parse validity, terminal policy shape, DNS-lookup pressure, void-lookup pressure where feasible, and clearly flag invalid or dangerously weak structure without treating every non-`-all` policy as “broken.”
- **D-25-15:** DKIM should validate only selectors that are explicitly known. For known selectors, validate record existence, parseability, CNAME/TXT resolution, revoked keys, and key-length advisories. Do not claim “DKIM passes” from DNS alone.
- **D-25-16:** DMARC should validate `_dmarc` record presence, uniqueness, parse validity, policy posture (`monitoring`, `partial enforcement`, `enforcement`), and alignment-related advisory fields such as `adkim`, `aspf`, `rua`, and `sp`. Valid `p=none` is a `warn`, not an automatic `fail`.
- **D-25-17:** MX checks should stay honest about ambiguity. If MX is absent, the task should explain both plausible interpretations:
  - the domain should receive mail and is misconfigured
  - the domain is intentionally send-only and should publish Null MX
  Phase 25 should not force the operator through extra scope-setting flags just to understand this distinction.
- **D-25-18:** BIMI should be treated as readiness/trust signaling, not core sender-health scoring. Missing BIMI is not equivalent to broken deliverability. DMARC enforcement prerequisites and certificate/display caveats must be explained clearly.

### Architecture and dependency posture
- **D-25-19:** Implement Phase 25 as a reusable internal runtime module plus a thin Mix task wrapper. Do not place core diagnostic logic inside `Mix.Tasks.*`.
- **D-25-20:** DNS resolution should sit behind a tiny Mailglass-owned resolver seam backed by native OTP DNS facilities. Do not add a new runtime dependency unless native OTP proves insufficient in a way that materially changes correctness or maintainer burden.
- **D-25-21:** The core result shape should be runtime-safe, UI-safe, and test-friendly: checks, findings, observed facts, and resolver errors should live in plain data structures that the Mix task merely formats.
- **D-25-22:** Do not broaden Mailglass’s public library API just because the diagnostic engine is internally reusable. Phase 25 should preserve a small honest external surface while still structuring internals for future reuse.

### Decision posture for downstream agents
- **D-25-23:** For this project, downstream planning and execution should research alternatives deeply, choose one coherent default, and avoid escalating routine decisions back to the user.
- **D-25-24:** Escalate only when a choice would materially change:
  - the public CLI or config contract
  - claims of deliverability certainty or trust semantics
  - long-term maintainer burden through new dependencies or support surface
  - future operator/admin UX in a way likely to surprise adopters

### the agent's Discretion
- Exact internal module names under a `Mailglass.Deliverability.*` namespace, as long as Mix remains a thin wrapper over runtime code.
- Exact JSON schema keys and verbose-output formatting, as long as the human and machine surfaces describe the same underlying result model.
- Exact thresholds for SPF “near limit” warning posture and DKIM key-length advisory wording, as long as they remain standards-aware and clearly labeled as advisories rather than guarantees.

</decisions>

<specifics>
## Specific Ideas

- The right Mailglass posture here is:
  - “Here is what DNS truthfully says.”
  - “Here is what that usually means operationally.”
  - “Here is what to fix next.”
- Great DX for this phase means:
  - explicit target contract
  - no hidden inference
  - trustworthy `cannot_verify` outcomes
  - structured output that can grow into CI/admin reuse
  - no false promise that authentication correctness equals inbox placement
- The user preference for this repo is now stronger than “decisive by default” alone:
  - research across ecosystem precedents
  - synthesize one cohesive recommendation set
  - escalate only for truly high-impact contract or trust choices

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — Phase 25 goal, dependency chain, and scope anchor.
- `.planning/PROJECT.md` — v0.4 operator-confidence goal, maintainer budget, trust posture, and voice constraints.
- `.planning/REQUIREMENTS.md` — `DOCTOR-01`, `DOCTOR-02`, and `DOCTOR-03`.
- `.planning/STATE.md` — current milestone position and neighboring phase context.
- `.planning/METHODOLOGY.md` — decisive-by-default and recommendation-first workflow posture.

### Existing docs and product promises
- `README.md` — current public promise that `mix mail.doctor` exists as part of the Mailglass vision.
- `guides/dkim-setup.md` — current Mailglass-specific DKIM guidance and the project’s existing standard for honest operator-facing explanation.
- `guides/unsubscribe.md` — current deliverability-adjacent operator guidance tone and rollout posture.

### Implementation seams and local patterns
- `mix.exs` — dependency posture, optional-dependency discipline, and current Mix task conventions.
- `lib/mix/tasks/mailglass.install.ex` — strict explicit-flag task pattern and operator-facing task voice.
- `lib/mix/tasks/mailglass.publish.check.ex` — multi-step task formatting and fail-fast operator messaging style.
- `lib/mix/tasks/mailglass.docs.check.ex` — bounded task scope, strict parsing, and clear failure copy.
- `lib/mailglass/config.ex` — existing public config surface discipline and “small honest surface” precedent.
- `lib/mailglass/error.ex` — error taxonomy philosophy and stable public contract posture.
- `lib/mailglass/errors/config_error.ex` — exact user-facing copy style for bounded, actionable diagnostics.
- `lib/mailglass/events.ex` — evidence that Mailglass already envisions `mix mail.doctor` as a standalone operational concern, while Phase 25 intentionally avoids taking a persistence dependency.

### External standards and ecosystem priors
- `RFC 7208` — SPF record semantics and DNS lookup-limit constraints.
- `RFC 6376` — DKIM record and selector semantics.
- `RFC 7489` — DMARC record location, syntax, and alignment-policy semantics.
- `RFC 7505` — Null MX semantics for non-receiving domains.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing Mix tasks already establish the Mailglass house style for explicit input parsing, bounded scope, and exact user-facing error copy.
- `Mailglass.Config` already models the project’s “small honest surface” preference and should remain the standard to emulate rather than bypass.
- `Mailglass.Error` and sibling exception modules already show how Mailglass distinguishes hard failure from advisory guidance without fuzzy messaging.
- `Mailglass.Events` is a future integration seam for operator breadcrumbs, but Phase 25 should keep the diagnostic engine persistence-free.

### Established Patterns
- Mailglass prefers thin adapter surfaces over embedding core behavior in framework-facing entrypoints.
- Optional and speculative dependencies are treated conservatively; if native OTP and plain Elixir solve the problem, that is the preferred default.
- Public task surfaces are explicit, strict, and honest about what they can and cannot do.
- Operator trust matters more than looking clever: better an honest `cannot_verify` than a confident lie.

### Integration Points
- The diagnostic engine should live under a reusable `Mailglass.Deliverability.*` namespace so future admin/operator UI can reuse the same result model.
- The Mix task should only parse CLI input, call the runtime diagnostic module, and render human or JSON output.
- Any future admin/operator surface should consume the same finding/result shape rather than inventing a second presentation-specific schema.
- Future phases may wire explicit config-derived DKIM selectors or operator-supplied selectors into the same engine, but Phase 25 should not depend on that future surface to be useful and honest now.

</code_context>

<deferred>
## Deferred Ideas

- Deliverability scoring, inbox-placement prediction, or generalized “health grade” output.
- Provider API integrations, reputation feeds, complaint-rate analysis, or DMARC aggregate-report ingestion.
- Multi-domain batch mode or tenant-wide doctor sweeps.
- Automatic DKIM selector guessing based on provider folklore.
- Admin UI rendering of doctor results; Phase 25 should prepare for reuse but not build the UI surface itself.

</deferred>

---

*Phase: 25-deliverability-doctor*
*Context gathered: 2026-05-01*
