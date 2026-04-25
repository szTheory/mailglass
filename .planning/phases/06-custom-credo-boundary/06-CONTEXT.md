# Phase 6: Custom Credo + Boundary — Context

**Gathered:** 2026-04-24
**Status:** Ready for planning (no research phase required — patterns are 4-of-4 convergent across prior libs)

<domain>
## Phase Boundary

**Ship twelve domain-rule custom Credo checks plus boundary enforcement, all merge-blocking in CI.** Phase 6 operationalizes the invariants that Phases 1–5 established by convention into compile-time enforcement. After Phase 6, a contributor cannot accidentally violate the domain rules that mailglass's reliability and security properties depend on.

The twelve checks (LINT-01..LINT-12) fall into five enforcement categories:

1. **Send-path integrity** — LINT-01 (NoRawSwooshSendInLib)
2. **Privacy / PII** — LINT-02 (NoPiiInTelemetryMeta), LINT-11 (NoFullResponseInLogs)
3. **Multi-tenancy** — LINT-03 (NoUnscopedTenantQueryInLib)
4. **Dependency hygiene** — LINT-04 (NoBareOptionalDepReference), LINT-08 (NoCompileEnvOutsideConfig), LINT-09 (NoOtherAppEnvReads)
5. **Structural discipline** — LINT-05 (NoOversizedUseInjection), LINT-06 (PrefixedPubSubTopics), LINT-07 (NoDefaultModuleNameSingleton), LINT-10 (TelemetryEventConvention), LINT-12 (NoDirectDateTimeNow)

Plus two cross-cutting requirements:
- **TRACK-02** — `NoTrackingOnAuthStream` (13th check, distinct from LINT-01..12)
- **TENANT-03** — Multi-tenant property test + boundary contract test

**Five checks already have conventions proven in Phases 1–4 code** (LINT-02, 04, 06, 10, 12 — marked [x] in REQUIREMENTS.md). These need Credo check implementations + tests, not design work.

**Seven checks need fresh implementation** (LINT-01, 03, 05, 07, 08, 09, 11) plus TRACK-02. These are AST-walking checks with varying complexity.

**Boundary enforcement** (CORE-07) already has `use Boundary` declarations in `lib/mailglass.ex` and `lib/mailglass/renderer.ex`. Phase 6 extends these to cover Outbound, Events, Webhook, and Admin boundaries with explicit `deps:` / `exports:` lists, and adds the CI `mix compile` lane that fails on boundary violations.

**Out of scope:**
- Runtime enforcement or middleware guards (checks are compile-time only)
- Custom Credo checks for `mailglass_admin` package (deferred to when admin has prod surface in v0.5)
- `credo:disable-for-next-line` governance policy (documented in guides, not enforced by tooling)
</domain>

<decisions>
## Implementation Decisions

### Check module location (D-P6-01)

All custom Credo checks live under `lib/mailglass/credo/` with module namespace `Mailglass.Credo.*`. This follows the Oban convention (`Oban.Credo.*`) over the alternative `lib/credo/` path. The checks ship as part of the `mailglass` Hex package — adopters who add `{:mailglass, "~> 0.1"}` get the checks automatically.

### .credo.exs registration (D-P6-02)

Each check is registered in `.credo.exs` under `extra_checks:` with explicit params (e.g., the PII key blocklist for LINT-02, the tenant table list for LINT-03). Checks default to `priority: :higher` so they appear before stock Credo warnings.

### AST walking strategy (D-P6-03)

All checks use `Credo.Check.run_on_all_source_files/2` or single-file `run/2` depending on whether they need cross-file context:
- **Single-file** (majority): LINT-01, 02, 04, 05, 06, 07, 08, 09, 10, 11, 12, TRACK-02
- **Cross-file** (needs module resolution): LINT-03 (must know which schemas are tenanted)

AST walking uses `Macro.postwalk/2` for depth-first pattern matching on quoted forms. No regex-based source scanning — all checks operate on compiled AST.

### Test structure (D-P6-04)

Each check has a dedicated test file at `test/mailglass/credo/` containing:
- At least one "should flag" case with a synthetic source string
- At least one "should NOT flag" case (valid code)
- Edge cases specific to that check

Tests use `Credo.Test.Helpers.to_source_file/1` to create synthetic source files and assert on `Credo.Check.run/2` returning issues (or not).

### Boundary enforcement extension (D-P6-05)

Phase 6 adds `use Boundary` declarations to:
- `Mailglass.Outbound` — deps: `[Mailglass]`, cannot reach into `Mailglass.Events` directly
- `Mailglass.Events` — deps: `[Mailglass]`, cannot reach into `Mailglass.Outbound`
- `Mailglass.Webhook` — deps: `[Mailglass, Mailglass.Events]`, leaf (no reverse deps)

The root `Mailglass` boundary `exports:` list is updated to reflect the public surface consumed by each sub-boundary. CI lane `mix compile --warnings-as-errors` catches violations.

### CI integration (D-P6-06)

`.github/workflows/ci.yml` gains a dedicated `credo-custom` job that runs:
```
mix credo --strict --only Mailglass.Credo
```
This is the canonical merge-blocking command for Phase 6 custom checks. It is separate from the existing `credo --strict` baseline step to allow unambiguous pass/fail reporting for domain-rule enforcement. The job depends on `compile` completing first.

### Phase 6 success criteria mapping (from REQUIREMENTS.md)

1. PR adding raw `Swoosh.Mailer.deliver/1` → fails CI with LINT-01
2. PR adding `tracking: [opens: true]` to `password_reset/1` → fails CI with TRACK-02
3. PR adding PII keys to telemetry → fails CI with LINT-02
4. PR with unscoped tenant query lacking companion tenant-bypass audit telemetry emit/helper → fails CI with LINT-03
5. PR calling `Oban.insert/2` outside gateway → fails CI with LINT-04
6. PR broadcasting bare topic → fails CI with LINT-06
7. PR calling `DateTime.utc_now/0` outside Clock → fails CI with LINT-12
8. Multi-tenant property/integration test + boundary contract test pass
</decisions>

<dependencies>
## Dependencies

### Requires (from prior phases)
- Phase 1–5 complete (codebase to lint against exists)
- `{:credo, "~> 1.7"}` already in dev deps
- `{:boundary, "~> 0.10"}` already in deps + compilers list
- Existing `use Boundary` in `lib/mailglass.ex` and `lib/mailglass/renderer.ex`

### Produces (for Phase 7)
- All domain rules CI-enforced before installer/docs phase
- Boundary graph validates the module dependency DAG is clean
- CI workflow updated with custom Credo lane (Phase 7 extends CI further)

### No external research required
Per ROADMAP.md: "Other phases (1, 3, 6, 7) plan directly from synthesis — patterns are 4-of-4 convergent across prior libs." The Credo check authoring pattern is well-understood from Oban, Ash, and Surface prior art.
</dependencies>

<risks>
## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| AST shape changes between Elixir versions | Low | Medium | Pin minimum Elixir version in mix.exs; test against 1.17 + 1.18 in CI matrix |
| LINT-03 (tenant scope) false positives on intentional unscoped queries | Medium | Low | Support explicit `scope: :unscoped` only with companion tenant-bypass audit telemetry emit/helper; document escape hatch contract |
| LINT-05 (use injection size) counting depends on AST expansion timing | Medium | Medium | Count at `@before_compile` callback level, not post-expansion |
| Boundary violations discovered in existing Phase 1–5 code | Low | Medium | Fix violations before adding boundary declarations; treat as part of plan |
| Credo check performance on large adopter codebases | Low | Low | Single-file checks are O(n) per file; no cross-file graph walking except LINT-03 |
</risks>

<pitfalls>
## Relevant Pitfalls (from PITFALLS.md)

Phase 6 guards against 14 pitfalls: LIB-01, LIB-02, LIB-05, LIB-07, MAIL-01, DIST-04, PHX-01, PHX-05, PHX-06, OBS-01, OBS-04, OBS-05, TEST-06. Each pitfall maps to one or more LINT checks. See `.planning/research/PITFALLS.md` for full text.
</pitfalls>
