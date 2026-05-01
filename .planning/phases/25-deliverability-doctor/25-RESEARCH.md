# Phase 25: deliverability-doctor - Research

**Researched:** 2026-05-01
**Domain:** DNS deliverability diagnostics for an Elixir Mix task
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)
[VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

### Locked Decisions
- **D-25-01:** Phase 25 stays DNS-only. Do not add provider API checks, inbox-placement scoring, complaint/reputation heuristics, or generalized “deliverability grade” output.
- **D-25-02:** The task should ship standards-aware structural checks plus tightly bounded policy advisories. It should report DNS truth and operational implications, not pretend to prove full delivery outcomes.
- **D-25-03:** `mix mail.doctor` should remain usable without requiring admin UI, Oban, or database-backed operator workflows. Do not make Phase 25 depend on `Repo`, `mailglass_events`, or other persistence surfaces just to run diagnostics.

- **D-25-04:** The only canonical target contract is `mix mail.doctor --domain example.com`. Do not accept ambient domain inference from endpoint/config/tenant state, and do not make positional-argument parsing the primary interface.
- **D-25-05:** Phase 25 should operate on exactly one domain per invocation. Do not add multi-domain batch mode in v0.4.
- **D-25-06:** DKIM selector validation requires explicit selector knowledge. If selectors are not provided, the task must report an honest `cannot_verify` finding rather than guessing likely selectors or claiming DKIM absence.
- **D-25-07:** If selector-specific validation is exposed in the CLI, prefer explicit repeatable input such as `--dkim-selector` over provider guesswork or hidden defaults.

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

- **D-25-14:** SPF should check for record presence, record uniqueness, parse validity, terminal policy shape, DNS-lookup pressure, void-lookup pressure where feasible, and clearly flag invalid or dangerously weak structure without treating every non-`-all` policy as “broken.”
- **D-25-15:** DKIM should validate only selectors that are explicitly known. For known selectors, validate record existence, parseability, CNAME/TXT resolution, revoked keys, and key-length advisories. Do not claim “DKIM passes” from DNS alone.
- **D-25-16:** DMARC should validate `_dmarc` record presence, uniqueness, parse validity, policy posture (`monitoring`, `partial enforcement`, `enforcement`), and alignment-related advisory fields such as `adkim`, `aspf`, `rua`, and `sp`. Valid `p=none` is a `warn`, not an automatic `fail`.
- **D-25-17:** MX checks should stay honest about ambiguity. If MX is absent, the task should explain both plausible interpretations:
  - the domain should receive mail and is misconfigured
  - the domain is intentionally send-only and should publish Null MX
  Phase 25 should not force the operator through extra scope-setting flags just to understand this distinction.
- **D-25-18:** BIMI should be treated as readiness/trust signaling, not core sender-health scoring. Missing BIMI is not equivalent to broken deliverability. DMARC enforcement prerequisites and certificate/display caveats must be explained clearly.

- **D-25-19:** Implement Phase 25 as a reusable internal runtime module plus a thin Mix task wrapper. Do not place core diagnostic logic inside `Mix.Tasks.*`.
- **D-25-20:** DNS resolution should sit behind a tiny Mailglass-owned resolver seam backed by native OTP DNS facilities. Do not add a new runtime dependency unless native OTP proves insufficient in a way that materially changes correctness or maintainer burden.
- **D-25-21:** The core result shape should be runtime-safe, UI-safe, and test-friendly: checks, findings, observed facts, and resolver errors should live in plain data structures that the Mix task merely formats.
- **D-25-22:** Do not broaden Mailglass’s public library API just because the diagnostic engine is internally reusable. Phase 25 should preserve a small honest external surface while still structuring internals for future reuse.

- **D-25-23:** For this project, downstream planning and execution should research alternatives deeply, choose one coherent default, and avoid escalating routine decisions back to the user.
- **D-25-24:** Escalate only when a choice would materially change:
  - the public CLI or config contract
  - claims of deliverability certainty or trust semantics
  - long-term maintainer burden through new dependencies or support surface
  - future operator/admin UX in a way likely to surprise adopters

### Claude's Discretion
- Exact internal module names under a `Mailglass.Deliverability.*` namespace, as long as Mix remains a thin wrapper over runtime code.
- Exact JSON schema keys and verbose-output formatting, as long as the human and machine surfaces describe the same underlying result model.
- Exact thresholds for SPF “near limit” warning posture and DKIM key-length advisory wording, as long as they remain standards-aware and clearly labeled as advisories rather than guarantees.

### Deferred Ideas (OUT OF SCOPE)
- Deliverability scoring, inbox-placement prediction, or generalized “health grade” output.
- Provider API integrations, reputation feeds, complaint-rate analysis, or DMARC aggregate-report ingestion.
- Multi-domain batch mode or tenant-wide doctor sweeps.
- Automatic DKIM selector guessing based on provider folklore.
- Admin UI rendering of doctor results; Phase 25 should prepare for reuse but not build the UI surface itself.
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Mix tasks in this repo use explicit `OptionParser.parse/2` validation, reject unknown flags, and reject positional arguments when the task contract is intended to be strict. [VERIFIED: lib/mix/tasks/mailglass.install.ex] [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex] [VERIFIED: lib/mix/tasks/mailglass.docs.check.ex]
- Mailglass prefers thin framework-facing entrypoints over embedding core behavior in `Mix.Tasks.*`; core logic belongs in reusable runtime modules. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
- Optional or speculative dependencies are conservative by default; native OTP or existing deps should be preferred over adding a new runtime package. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs] [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
- Public task surfaces must stay explicit, bounded, and honest about uncertainty. [VERIFIED: CLAUDE.md] [VERIFIED: guides/dkim-setup.md] [VERIFIED: guides/unsubscribe.md]
- The project already promises `mix mail.doctor` publicly, so this phase must ship a trustworthy diagnostic rather than a placeholder. [VERIFIED: README.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/ROADMAP.md]
- The phase must not require `Repo`, admin UI, Oban, or event persistence to execute. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCTOR-01 | User can run `mix mail.doctor` against a domain and receive SPF, DKIM, DMARC, MX, and BIMI findings. [VERIFIED: .planning/REQUIREMENTS.md] | Use one-domain strict CLI parsing, a resolver seam over OTP DNS, and per-protocol analyzers that emit a shared finding shape. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://hexdocs.pm/elixir/OptionParser.html] [CITED: https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html] |
| DOCTOR-02 | `mix mail.doctor` classifies findings as pass, warn, fail, or cannot-verify. [VERIFIED: .planning/REQUIREMENTS.md] | Model `cannot_verify` as a first-class outcome for selector absence, timeout, transient DNS failure, and other partial-evidence states. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| DOCTOR-03 | `mix mail.doctor` explains remediation in operator-facing language without overstating certainty. [VERIFIED: .planning/REQUIREMENTS.md] | Every finding should carry `title`, `why_it_matters`, `observed`, and `remediation`, and human output should group by protocol with concise evidence plus optional verbose details. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [VERIFIED: guides/dkim-setup.md] [VERIFIED: guides/unsubscribe.md] |
</phase_requirements>

## Summary

Phase 25 should be implemented as a strict, DNS-only diagnostic engine under `Mailglass.Deliverability.*` with a thin `mix mail.doctor` wrapper. That matches the repo’s established Mix-task style, the locked phase decisions, and the public roadmap promise. [VERIFIED: lib/mix/tasks/mailglass.install.ex] [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex] [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]

The hard part is not querying DNS. The hard part is avoiding false confidence. SPF has a standards-defined 10-term DNS lookup limit and a recommended void-lookup cap; DMARC record discovery fails closed when multiple records exist; DKIM cannot be honestly declared “present” without an explicit selector; Null MX changes the meaning of “no inbound mail”; and BIMI readiness depends on DMARC enforcement plus provider-specific display rules that the BIMI Group itself describes as evolving. [CITED: https://www.rfc-editor.org/rfc/rfc7208] [CITED: https://www.rfc-editor.org/rfc/rfc7489] [CITED: https://www.rfc-editor.org/rfc/rfc6376] [CITED: https://www.rfc-editor.org/rfc/rfc7505] [CITED: https://bimigroup.org/implementation-guide/]

OTP’s built-in DNS client is sufficient for Phase 25 if it is wrapped behind a resolver behaviour that normalizes TXT/MX/CNAME facts, timeouts, NXDOMAIN, and malformed answers into plain data. Local probing confirmed `:inet_res.lookup/3` can already retrieve MX and TXT records in the current environment, and the official docs expose `lookup/3`, `lookup/4`, and `lookup/5`, so a small resolver seam is the right default without adding a runtime dependency. [VERIFIED: local elixir probe] [CITED: https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html]

**Primary recommendation:** Build a reusable `Mailglass.Deliverability` runtime with protocol-specific analyzers over a shared fact model, strict `--domain` plus repeatable `--dkim-selector`, versioned JSON output, and property tests for SPF recursion/limits and uncertainty classification. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [VERIFIED: mix.exs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CLI argv parsing and contract enforcement | Mix task wrapper | — | Existing Mailglass tasks already own explicit `OptionParser` parsing and user-facing CLI errors. [VERIFIED: lib/mix/tasks/mailglass.install.ex] [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex] |
| DNS resolution and normalization | Runtime resolver seam | External DNS | Resolver behavior should isolate OTP DNS specifics from protocol logic and formatting. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html] |
| SPF/DKIM/DMARC/MX/BIMI analysis | Runtime protocol analyzers | Resolver seam | Standards logic belongs in reusable modules, not in Mix formatting code. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| Human output and JSON output | Formatter layer | Mix task wrapper | One result model should render to both human text and `--format json` without text scraping. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| Trust boundary and uncertainty classification | Result model | Protocol analyzers | `cannot_verify` is a semantic output choice, not a transport accident. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir `OptionParser` | 1.19.5 | Strict CLI parsing for `--domain`, `--dkim-selector`, `--verbose`, and `--format`. [CITED: https://hexdocs.pm/elixir/OptionParser.html] | It matches existing task style and supports repeatable switches via `:keep` without extra deps. [VERIFIED: lib/mix/tasks/mailglass.install.ex] [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| OTP `:inet_res` | OTP builtin; verified locally on OTP 28 | DNS lookups for TXT, MX, and raw resolver interaction behind a Mailglass seam. [VERIFIED: local elixir probe] [CITED: https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html] | It satisfies the locked “native OTP first” dependency posture. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| OTP `:public_key` | OTP builtin; enabled in app extras | DKIM public-key decoding and key-length advisory work without hand-rolled ASN.1 parsing. [VERIFIED: mix.exs] | It is already an application dependency and fits the repo’s no-new-runtime-dep preference. [VERIFIED: mix.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Jason` | `~> 1.4` in repo | Serialize the shared result model for `--format json`. [VERIFIED: mix.exs] | Use for the first-release machine contract; add a top-level schema version key. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| `ExUnit` | bundled with Elixir 1.19.5 | Unit tests and Mix-task output contract tests. [VERIFIED: local environment] [VERIFIED: test/test_helper.exs] | Use for parser, formatter, and analyzer examples and regressions. [VERIFIED: test/mix/tasks/mailglass.gen.unsubscribe_test.exs] |
| `stream_data` | `~> 1.3` in repo | Property tests for SPF recursion limits, duplicate-record handling, and uncertainty outcomes. [VERIFIED: mix.exs] | Use anywhere the input space is combinatorial and a few example fixtures would miss edge cases. [VERIFIED: test/mailglass/properties/unsubscribe_property_test.exs] [VERIFIED: test/mailglass/properties/webhook_signature_failure_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| OTP resolver seam | Shelling out to `dig` or another external resolver tool | Reject for v0.4 because it adds an environmental dependency, text-parsing fragility, and worse portability. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| Shared plain-data result model | Text-only output assembled inside the Mix task | Reject because `--format json` is locked and future CI/admin reuse should not scrape terminal output. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| Explicit DKIM selectors | Selector guessing based on provider folklore | Reject because it violates the phase’s trust posture and would create false `pass` or false `fail` results. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |

**Installation:**
```bash
# No new runtime dependency is recommended for Phase 25.
mix deps.get
```

**Version verification:** This phase uses existing repo and OTP/Elixir capabilities, so there is no new package version to verify from npm or Hex. `OptionParser` was verified from Elixir 1.19.5 docs, `:inet_res` was verified from official Erlang docs plus a local OTP 28 probe, and `Jason` / `stream_data` were verified from `mix.exs`. [CITED: https://hexdocs.pm/elixir/OptionParser.html] [CITED: https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html] [VERIFIED: local elixir probe] [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
mix mail.doctor --domain example.com --dkim-selector s1 --format json
                |
                v
      Mix.Tasks.Mail.Doctor
      - strict argv validation
      - one-domain contract
      - selects formatter
                |
                v
      Mailglass.Deliverability.run/1
                |
                +----------------------+
                |                      |
                v                      v
      Resolver behaviour         Input normalizer
      - TXT / MX / CNAME         - domain canonicalization
      - timeout / NXDOMAIN       - selector list
      - response normalization    - output mode
                |
                v
       Observed facts map
                |
    +-----------+-----------+-----------+-----------+-----------+
    |           |           |           |           |           |
    v           v           v           v           v
  SPF       DKIM        DMARC         MX         BIMI
 analyzer   analyzer    analyzer      analyzer   analyzer
    |           |           |           |           |
    +-----------+-----------+-----------+-----------+
                |
                v
         Shared result model
         - summary
         - checks
         - findings
         - resolver errors
         - schema_version
                |
         +------+------+
         |             |
         v             v
   Human formatter   JSON formatter
```

### Recommended Project Structure
```text
lib/
├── mix/tasks/
│   └── mail.doctor.ex                 # thin CLI wrapper
└── mailglass/deliverability/
    ├── resolver.ex                    # behaviour + OTP adapter
    ├── result.ex                      # shared plain-data helpers
    ├── spf.ex                         # SPF analyzer
    ├── dkim.ex                        # DKIM analyzer
    ├── dmarc.ex                       # DMARC analyzer
    ├── mx.ex                          # MX / Null MX analyzer
    ├── bimi.ex                        # BIMI analyzer
    └── formatter.ex                   # human + JSON rendering

test/
├── mix/tasks/mail_doctor_task_test.exs
├── mailglass/deliverability/*_test.exs
└── mailglass/properties/deliverability_*_property_test.exs
```

### Pattern 1: Resolver Seam Over OTP DNS
**What:** Hide `:inet_res` behind a tiny behaviour that returns normalized facts like `{:ok, %{txt: [...], mx: [...]}}` or `{:error, %{reason: :timeout}}`. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html]

**When to use:** Always. Protocol analyzers should not know whether TXT answers arrived as nested charlists, concatenated strings, or resolver-specific tuples. [VERIFIED: local elixir probe] [CITED: https://www.rfc-editor.org/rfc/rfc6376] [CITED: https://www.rfc-editor.org/rfc/rfc7208]

**Example:**
```elixir
# Source: OptionParser docs + OTP inet_res docs
{opts, rest, invalid} =
  OptionParser.parse(argv,
    strict: [domain: :string, dkim_selector: :keep, verbose: :boolean, format: :string]
  )

resolver.lookup(String.to_charlist(domain), :in, :txt)
```

### Pattern 2: Protocol Analyzers Emit Findings, Not Exit Codes
**What:** Each analyzer should emit findings with `status`, `title`, `why_it_matters`, `observed`, `remediation`, and optional `evidence`, then let the top-level formatter summarize them. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

**When to use:** For every protocol, including “good enough but not ideal” states like `p=none`, SPF near lookup limits, missing BIMI, or DKIM selector absence. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://www.rfc-editor.org/rfc/rfc7489] [CITED: https://www.rfc-editor.org/rfc/rfc7208]

**Example:**
```elixir
# Source: Mailglass task/output conventions
%{
  area: :dmarc,
  status: :warn,
  title: "DMARC policy is monitoring-only",
  why_it_matters: "BIMI and stronger spoofing resistance typically require enforcement.",
  observed: "Found _dmarc.example.com TXT with p=none.",
  remediation: "Move to quarantine or reject after validating legitimate traffic."
}
```

### Pattern 3: Separate Facts From Interpretation
**What:** Persist raw observed DNS facts separately from derived findings inside the in-memory result so JSON consumers can re-render or diff without reparsing prose. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

**When to use:** Especially for SPF recursion traces, TXT record multiplicity, DMARC tags, and resolver failures where operators may want `--verbose` evidence. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

### Anti-Patterns to Avoid
- **Binary pass/fail doctor:** Reject because the requirements and phase context explicitly require `cannot_verify`, and DNS truth is often incomplete. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
- **Mix-task-only implementation:** Reject because it blocks formatter reuse and makes protocol logic harder to test. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
- **Selector guessing:** Reject because RFC DKIM verification depends on explicit selector context, not provider folklore. [CITED: https://www.rfc-editor.org/rfc/rfc6376] [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
- **BIMI as a hard deliverability gate:** Reject because the phase scope and BIMI guidance treat it as readiness/trust signaling with provider-specific display behavior. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://bimigroup.org/implementation-guide/]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CLI flag parsing | Custom argv splitting and switch coercion | `OptionParser` strict parsing | Existing tasks already rely on it, and it supports repeatable flags cleanly. [VERIFIED: lib/mix/tasks/mailglass.install.ex] [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| DNS execution | Shell-outs to `dig` plus text scraping | OTP `:inet_res` behind a behaviour | Native OTP is already present and avoids environment drift. [VERIFIED: local elixir probe] [CITED: https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html] |
| DKIM key decoding | Manual ASN.1 or RSA modulus parsing | OTP `:public_key` | Cryptographic structure parsing is not where this phase should invent code. [VERIFIED: mix.exs] |
| Machine output | Ad hoc string parsing of terminal output | Versioned JSON via `Jason` | Future CI/admin/editor reuse should consume data, not scrape prose. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| Trust semantics | A “deliverability score” or grade | Per-finding statuses with honest uncertainty | DNS cannot prove inbox placement or reputation outcomes. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |

**Key insight:** The expensive bugs in this phase are semantic, not syntactic. Hand-rolled scoring or inferred certainty will damage operator trust faster than a missing convenience feature. [VERIFIED: guides/dkim-setup.md] [VERIFIED: guides/unsubscribe.md] [VERIFIED: .planning/milestones/v0.1-research/PITFALLS.md]

## Common Pitfalls

### Pitfall 1: SPF “Pass” Without Recursive Lookup Accounting
**What goes wrong:** The tool reads only the literal SPF TXT string and misses recursive `include`, `a`, `mx`, `exists`, `ptr`, or `redirect` lookup pressure. [CITED: https://www.rfc-editor.org/rfc/rfc7208] [VERIFIED: .planning/milestones/v0.1-research/PITFALLS.md]
**Why it happens:** RFC 7208’s 10-term limit and recommended two-void-lookup cap are easy to miss if the implementation stops at syntax. [CITED: https://www.rfc-editor.org/rfc/rfc7208]
**How to avoid:** Track recursion depth, unique visited nodes, term count, and void lookups in the analyzer and expose that evidence in `--verbose`. [CITED: https://www.rfc-editor.org/rfc/rfc7208] [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
**Warning signs:** Domains with many includes show `pass` locally but real receivers still permerror or soft-fail. [VERIFIED: .planning/milestones/v0.1-research/PITFALLS.md]

### Pitfall 2: Claiming DKIM Status Without Selector Knowledge
**What goes wrong:** The doctor reports “DKIM missing” or “DKIM passes” based only on the organizational domain. [CITED: https://www.rfc-editor.org/rfc/rfc6376]
**Why it happens:** DKIM keys live under `selector._domainkey.domain`, and the selector comes from message context, not from a universal DNS location. [CITED: https://www.rfc-editor.org/rfc/rfc6376]
**How to avoid:** Require explicit selectors for DNS validation and otherwise return `cannot_verify` with operator guidance. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
**Warning signs:** Tool behavior changes based on guessed provider names, or it never surfaces selector absence as uncertainty. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

### Pitfall 3: Treating Missing MX As Unconditional Failure
**What goes wrong:** Send-only domains are flagged as broken even when Null MX would be the intentional configuration. [CITED: https://www.rfc-editor.org/rfc/rfc7505]
**Why it happens:** “No MX” and “does not accept mail” are related but not identical states. Null MX has a specific DNS form. [CITED: https://www.rfc-editor.org/rfc/rfc7505]
**How to avoid:** Distinguish `no_mx`, `null_mx`, and `mx_present`, then explain the two plausible operator interpretations when MX is absent. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://www.rfc-editor.org/rfc/rfc7505]
**Warning signs:** The tool produces a hard fail on every outbound-only domain. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

### Pitfall 4: Overclaiming BIMI
**What goes wrong:** Missing BIMI is treated as broken deliverability, or BIMI record presence is treated as guaranteed inbox logo display. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://bimigroup.org/implementation-guide/]
**Why it happens:** BIMI mixes DNS structure, DMARC enforcement, logo hosting, optional evidence documents, and mailbox-provider display criteria. [CITED: https://bimigroup.org/implementation-guide/] [CITED: https://bimigroup.org/how-and-why-to-implement-bimi-selectors/]
**How to avoid:** Limit Phase 25 to readiness findings: DMARC enforcement prerequisite, record presence/shape, `l=` and `a=` posture, and provider-caveat remediation. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://bimigroup.org/implementation-guide/]
**Warning signs:** The task says “BIMI pass” without any caveat about provider-specific rendering or evolving program rules. [CITED: https://bimigroup.org/implementation-guide/]

## Code Examples

Verified patterns from official sources:

### Strict CLI Parsing With Repeatable Selectors
```elixir
# Source: https://hexdocs.pm/elixir/OptionParser.html
{opts, rest, invalid} =
  OptionParser.parse(argv,
    strict: [
      domain: :string,
      dkim_selector: :keep,
      verbose: :boolean,
      format: :string
    ]
  )
```

### Native DNS Lookup
```elixir
# Source: https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html
:inet_res.lookup(String.to_charlist("_dmarc.example.com"), :in, :txt)
:inet_res.lookup(String.to_charlist("example.com"), :in, :mx)
```

### Existing Mailglass Task Contract Style
```elixir
# Source: lib/mix/tasks/mailglass.install.ex
{opts, rest, invalid} = OptionParser.parse(argv, strict: [dry_run: :boolean])

if rest != [] do
  Mix.raise("Installation blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Text-only doctor output | Shared finding/result model rendered as human text and JSON | Locked for this phase in 2026-05 context | Enables CI/admin/editor reuse without scraping. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| Binary `pass`/`fail` diagnostics | `pass` / `warn` / `fail` / `cannot_verify` | Locked for this phase in 2026-05 context | Avoids lying when DNS evidence is incomplete or transient. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| DKIM guessed from provider defaults | DKIM validated only for explicit selectors | Locked for this phase in 2026-05 context | Removes false confidence and aligns with selector-based DNS semantics. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://www.rfc-editor.org/rfc/rfc6376] |
| RSA-SHA1 tolerated in DKIM advice | RSA-SHA256 required; weak RSA keys should warn/fail per standards | RFC 8301, January 2018 | Key-length and algorithm advisories must reflect current DKIM crypto guidance. [CITED: https://www.rfc-editor.org/rfc/rfc8301.html] |

**Deprecated/outdated:**
- Assuming any valid-looking DKIM TXT record means “DKIM is working” is outdated for this phase because DNS alone cannot prove active signing without selector context and message evidence. [CITED: https://www.rfc-editor.org/rfc/rfc6376] [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
- Treating missing BIMI as a sender-health failure is outdated for this phase because BIMI is a readiness/trust signal, not a core deliverability proof. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] [CITED: https://bimigroup.org/implementation-guide/]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All material claims in this document were verified locally or cited from primary sources. | — | — |

## Open Questions

1. **How much raw DNS evidence belongs in default output versus `--verbose`?**
   What we know: The phase locks `--verbose` and requires human-first default output. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
   What's unclear: Exact truncation rules for long SPF expansion traces and multi-record evidence are not yet decided. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
   Recommendation: Keep default output to one concise observation per finding and move recursion trees, raw TXT lists, and resolver diagnostics into `evidence` plus `--verbose`. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

2. **Should DKIM selector input support both repeated flags and comma lists?**
   What we know: The locked preference is explicit repeatable `--dkim-selector`. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]
   What's unclear: Whether adding comma-list parsing would help or only complicate strict CLI validation. [ASSUMED]
   Recommendation: Plan repeated `--dkim-selector` only for v0.4 and defer alternate syntaxes unless user demand appears. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix task and test execution | ✓ | 1.19.5 | — |
| Erlang/OTP | `:inet_res`, `:public_key`, runtime execution | ✓ | 28 (verified locally) | — |
| DNS egress via OTP resolver | Live domain lookups | ✓ | local `:inet_res.lookup/3` probe succeeded | Stub resolver in tests |
| `mix` | Task entrypoint and test commands | ✓ | bundled with Elixir 1.19.5 | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local environment]

**Missing dependencies with fallback:**
- None for planning. Live-network DNS is required in production use, but tests can and should run against a stubbed resolver. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + StreamData (`stream_data ~> 1.3`) [VERIFIED: mix.exs] |
| Config file | `test/test_helper.exs` bootstraps the suite; no standalone `ex_unit.exs` config file. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/mix/tasks/mail_doctor_task_test.exs test/mailglass/deliverability --warnings-as-errors` [ASSUMED] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCTOR-01 | `mix mail.doctor --domain example.com` emits grouped SPF/DKIM/DMARC/MX/BIMI findings. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/mix/tasks/mail_doctor_task_test.exs --warnings-as-errors` [ASSUMED] | ❌ Wave 0 |
| DOCTOR-02 | Findings classify only as `pass`, `warn`, `fail`, or `cannot_verify`. [VERIFIED: .planning/REQUIREMENTS.md] | unit + property | `mix test test/mailglass/deliverability/result_test.exs test/mailglass/properties/deliverability_status_property_test.exs --warnings-as-errors` [ASSUMED] | ❌ Wave 0 |
| DOCTOR-03 | Operator-facing remediation stays honest and avoids overstated certainty. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/mailglass/deliverability/formatter_test.exs --warnings-as-errors` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/mix/tasks/mail_doctor_task_test.exs test/mailglass/deliverability --warnings-as-errors` [ASSUMED]
- **Per wave merge:** `mix test --warnings-as-errors` [VERIFIED: mix.exs]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json]

### Wave 0 Gaps
- [ ] `test/mix/tasks/mail_doctor_task_test.exs` — strict CLI parsing, unknown-flag rejection, positional-arg rejection, grouped human output, JSON output.
- [ ] `test/mailglass/deliverability/spf_test.exs` — record presence, duplicate SPF, recursion counting, terminal policy classification.
- [ ] `test/mailglass/deliverability/dkim_test.exs` — selector-required `cannot_verify`, TXT/CNAME handling, revoked key, key-length advisory.
- [ ] `test/mailglass/deliverability/dmarc_test.exs` — `_dmarc` discovery, duplicate record handling, `p`/`sp`/`pct`/`rua`/alignment classification.
- [ ] `test/mailglass/deliverability/mx_test.exs` — MX present, Null MX, absent MX ambiguity wording.
- [ ] `test/mailglass/deliverability/bimi_test.exs` — `default._bimi` lookup, readiness-only wording, DMARC prerequisite warnings.
- [ ] `test/mailglass/deliverability/formatter_test.exs` — human output contract and JSON schema version.
- [ ] `test/mailglass/properties/deliverability_spf_property_test.exs` — SPF recursion, lookup-limit, and void-lookup properties.
- [ ] `test/support/deliverability_resolver_stub.ex` — deterministic resolver fixtures independent of live DNS.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | DNS-only diagnostic; no user auth surface in this phase. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| V3 Session Management | no | No session surface. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| V4 Access Control | no | Local Mix task only; no new authorization boundary. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| V5 Input Validation | yes | Strict `OptionParser` contract, domain normalization, selector validation, bounded TXT/tag parsing. [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| V6 Cryptography | yes | Use OTP `:public_key` for DKIM key inspection; do not hand-roll cryptographic parsing. [VERIFIED: mix.exs] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| DNS timeout or transient resolver failure flattened into hard `fail` | Denial of Service | Normalize to `cannot_verify` when the evidence is transient or incomplete. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| Malformed or oversized TXT/tag data causing crashes | Tampering | Parse into bounded intermediate structures, reject unknown critical forms, and keep analyzers pure. [CITED: https://www.rfc-editor.org/rfc/rfc7208] [CITED: https://www.rfc-editor.org/rfc/rfc7489] [CITED: https://www.rfc-editor.org/rfc/rfc6376] |
| Resolver trust boundary overstated as protocol certainty | Spoofing | Describe DNS observations as resolver-visible facts, not proof of mailbox-provider behavior or inbox placement. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |
| JSON contract drift breaking future reuse | Tampering | Add explicit `schema_version` and test JSON keys directly. [VERIFIED: .planning/phases/25-deliverability-doctor/25-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/25-deliverability-doctor/25-CONTEXT.md` - locked decisions, output contract, scope boundaries.
- `.planning/REQUIREMENTS.md` - `DOCTOR-01` through `DOCTOR-03`.
- `.planning/ROADMAP.md` - Phase 25 goal and dependency chain.
- `README.md` - current public promise that `mix mail.doctor` exists.
- `guides/dkim-setup.md` - existing operator-facing honesty standard for DKIM guidance.
- `guides/unsubscribe.md` - existing operator-facing remediation tone.
- `lib/mix/tasks/mailglass.install.ex` - strict CLI validation pattern.
- `lib/mix/tasks/mailglass.publish.check.ex` - multi-step task output pattern.
- `lib/mix/tasks/mailglass.docs.check.ex` - bounded task scope and fail-fast voice.
- `mix.exs` - existing dependencies and test infrastructure.
- `test/mix/tasks/mailglass.gen.unsubscribe_test.exs` - Mix-task output contract testing pattern.
- `https://hexdocs.pm/elixir/OptionParser.html` - strict parsing and repeatable switch support.
- `https://www.erlang.org/documentation/doc-14/lib/kernel-9.0/doc/html/inet_res.html` - official OTP DNS resolver API.
- `https://www.rfc-editor.org/rfc/rfc7208` - SPF publication and lookup-limit semantics.
- `https://www.rfc-editor.org/rfc/rfc6376` - DKIM selector, TXT uniqueness, revoked key, TEMPFAIL semantics.
- `https://www.rfc-editor.org/rfc/rfc7489` - DMARC `_dmarc` discovery, duplicate-record behavior, tag semantics.
- `https://www.rfc-editor.org/rfc/rfc7505` - Null MX semantics.
- `https://www.rfc-editor.org/rfc/rfc8301.html` - DKIM algorithm and key-size updates.

### Secondary (MEDIUM confidence)
- `https://bimigroup.org/implementation-guide/` - BIMI readiness prerequisites and record format caveats.
- `https://bimigroup.org/how-and-why-to-implement-bimi-selectors/` - BIMI default selector behavior and provider-caveat context.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The recommended stack is mostly existing repo and official OTP/Elixir capabilities, verified locally and from primary docs.
- Architecture: HIGH - The thin-task plus runtime-core pattern is strongly supported by repo conventions and locked context.
- Pitfalls: MEDIUM - SPF/DKIM/DMARC pitfalls are standards-backed, but BIMI remains partially program-driven and explicitly evolving in its own official guidance.

**Research date:** 2026-05-01
**Valid until:** 2026-05-31
