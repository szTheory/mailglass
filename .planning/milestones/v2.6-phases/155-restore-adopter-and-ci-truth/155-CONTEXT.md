# Phase 155: Restore Adopter and CI Truth - Context

**Gathered:** 2026-08-16
**Status:** Ready for planning
**Mode:** Auto-generated from the approved v2.6 audit plan

<domain>
## Phase Boundary

Make the adopter-facing core/inbound migration generators truthful for fresh installs, upgrades,
rollbacks, multi-repo hosts, and the known legacy toy output. In the same phase, make the protected
aggregate CI gate fail closed when change detection or required code lanes do not actually run.

</domain>

<decisions>
## Implementation Decisions

### Migration generation
- Initial generators emit the documented `Migration.up/0` and `down/0` wrappers.
- Additive flags are `--repo`, `--upgrade`, `--from`, and `--repair-legacy`.
- Repo inference is allowed only for exactly one configured `:ecto_repos` entry.
- Upgrade wrappers are new timestamped files and bake the previous schema version into rollback.
- Already-applied migrations are immutable.

### Legacy and metadata safety
- Repair only the exact known toy shape; ambiguous or populated data fails with actionable guidance.
- Version zero means the anchor is genuinely absent. Query errors, missing/malformed comments, and
  impossible ranges fail closed.

### CI truth
- Preserve the public protected check name `CI Green`.
- Add change detection to its dependency graph and require exact success for every required code lane
  when `code=true`; only successful docs-only classification may permit skips.
- Add regression meta-tests for failed change detection, skipped code lanes, and docs-only behavior.

### the agent's Discretion
- Internal module factoring, helper names, and test fixture structure may follow existing conventions.
- Prefer the smallest additive surface that gives deterministic generated-host proof.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Migration` and `MailglassInbound.Migration` already provide versioned dispatch façades.
- Existing migration/version tests, generated-host smoke, CI lane parser, and CI gate meta-tests provide
  foundations but currently hand-write or bless the wrong behavior.

### Established Patterns
- Shipped migrations are immutable and schema-prefix aware.
- Gating identity is centralized through `Mailglass.CILanes` and protected `CI Green`.
- Installer commands fail closed with actionable `Mix.raise/1` messages.

### Integration Points
- Core and inbound migration Mix tasks, installer plan, Postgres migration runners, golden/generated-host
  fixtures, `ci.yml`, and CI lane contract tests.

</code_context>

<specifics>
## Specific Ideas

The first acceptance proof must use a real Ecto host and actually migrate and persist a delivery; a
`--no-ecto` compile/boot smoke is not sufficient.

</specifics>

<deferred>
## Deferred Ideas

Runtime delivery, inbound/data hardening, architecture refactors, broader quality-gate expansion, and
release certification belong to Phases 156-160 respectively.

</deferred>
