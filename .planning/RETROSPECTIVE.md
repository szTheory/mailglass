# Retrospective: mailglass

> Living retrospective. New milestones are appended at the top. Cross-milestone trends section grows over time.

---

## Milestone: v1.3 — Adopter Trust Proof

**Shipped:** 2026-05-31
**Phases:** 7 | **Plans:** 18
**Coverage:** 16/16 v1.3 requirements

### What Was Built

- Maintained Phoenix reference host app with clean-checkout setup, public-seam-only integration, and explicit proof-scope contract.
- Deterministic `mix verify.reference_host.journey` runner with stable `trust_runner.v1` checkpoint evidence.
- Required repo-head and clean-baseline trust lanes, plus post-publish published-version trust proof for the current Hex release line.
- Reference-host and trust-entry documentation that routes guarantee semantics to canonical stability inventories and executable contract checks.

### What Worked

- The narrow proof-scope lock prevented reference-host work from expanding into a second product.
- Shared checkpoint semantics let local, CI, and release proof paths converge on one evidence contract.
- The Phase 62 gap closure was small and targeted because the previous phases had already isolated release-line truth from the rest of the workflow.

### What Was Inefficient

- Phase numbering had drifted from the original 53-56 roadmap snapshot, leaving STATE.md stale until closeout.
- Clean-baseline/published-version proof initially validated an older release line, which required an inserted closure phase before archive.

### Patterns Established

- Treat reference apps as usage proof artifacts, not public API contract sources.
- Version-specific Hex guards should be non-evaluating and fail closed on stale lock entries.
- Trust claims need both repo-head and published-version evidence before milestone close.

### Key Lessons

1. Release-line truth belongs in an executable guard, not prose or lockfile inspection by convention.
2. Documentation boundary enforcement is valuable when a reference app could otherwise imply accidental API guarantees.
3. Branch-protection trust lanes need live verification in the audit, not just workflow-file inspection.

---

## Milestone: v0.1 — Validation Release

**Shipped:** 2026-04-26 (v0.1.0 + v0.1.1 on Hex.pm)
**Phases:** 8 (7 planned + 1 inserted) | **Plans:** 61
**Timeline:** 2026-04-21 → 2026-04-26 (6 calendar days)
**Codebase:** ~33k LOC Elixir, 319 commits
**Coverage:** 84/84 v1 REQ-IDs

### What Was Built

- **Phase 1 — Foundation**: Zero-dep modules + pure-function HEEx renderer pipeline with MSO Outlook VML fallbacks; structured `Mailglass.Error` hierarchy; OptionalDeps gateway pattern; `Mailglass.Config` (NimbleOptions + `:persistent_term`); 4-level telemetry convention with PII whitelist.
- **Phase 2 — Persistence + Tenancy**: Append-only `mailglass_events` ledger with SQLSTATE 45A01 immutability trigger; multi-tenancy first-class on every schema; idempotency via partial UNIQUE; `Outbound.Projector` single-writer for Delivery projection columns; `SuppressionStore` behaviour + Ecto impl.
- **Phase 3 — Transport + Send Pipeline**: Fake adapter built first as merge-blocking release gate; full hot path (Mailable → preflight → render → Multi(Delivery + Event) → Adapter → Multi(Delivery update + Event)); Phoenix.Token-signed click rewriting; ETS rate limiter; tracking off by default with `NoTrackingOnAuthStream` lint enforcement.
- **Phase 4 — Webhook Ingest**: Postmark + SendGrid HMAC-verified, parsed to Anymail event taxonomy verbatim, written through one Ecto.Multi with replay-safe idempotency; orphan reconciliation worker; 1000-replay StreamData convergence property.
- **Phase 5 — Dev Preview LiveView**: `mailglass_admin` sibling package with mailable sidebar, `preview_props/0` auto-discovery, device + dark toggles, HTML/Text/Raw/Headers tabs; daisyUI 5 + Tailwind v4 with no Node toolchain required of adopters.
- **Phase 6 — Custom Credo + Boundary**: 12 domain-rule lint checks operationalizing engineering DNA at lint time; `boundary` enforcement of module hierarchy.
- **Phase 7 — Installer + CI/CD + Docs**: `mix mailglass.install` with idempotent `.mailglass_conflict_*` sidecars; golden-diff CI; full GHA pipeline (format, compile w/ warnings-as-errors, no-optional-deps lane, ExUnit, Credo strict, Dialyzer, docs); Release Please linked-versions; protected-ref Hex publish; ExDoc with 9 guides.
- **Phase 07.1 — Publish to Hex.pm (INSERTED)**: Closed installer blockers G-1..G-5 surfaced by milestone audit; v0.1.0 + v0.1.1 shipped to Hex.

### What Worked

- **Research-driven phase planning** for Phases 2, 4, 5 (the three flagged for `/gsd-research-phase`). The research output materially shaped plan structure — particularly Phase 2's `metadata jsonb` projection columns shape and Phase 4's SendGrid ECDSA on OTP 27 `:crypto` recipe.
- **Wave-based parallelization** within phases. Phase 3's 12-plan structure (5 original waves + 5 gap-closure plans) absorbed mid-wave credit exhaustion via cherry-pick recovery without losing the sequential commit history.
- **Fake adapter built FIRST as merge gate** (D-13). Every PR validated against Fake; real-provider sandbox tests stayed advisory-only on daily cron + `workflow_dispatch`. Discipline held all the way through to v0.1.1 ship.
- **Engineering DNA carried over from prior libs** (accrue/lattice_stripe/sigra/scrypath). Patterns that were 4-of-4 convergent (telemetry shape, error hierarchy, sibling packages, append-only ledger, OptionalDeps gateway) planned directly from synthesis without research delay.
- **Custom Credo checks built LAST (Phase 6) against real code** rather than first. Avoided the known time-sink of fighting an immature lint surface against immature library code.
- **Append-only ledger + idempotency partial UNIQUE** combo — the 1000-replay StreamData property test passed clean once the `inserted_at: nil` sentinel pattern was settled (UUIDv7 schemas client-autogenerate `id` before INSERT).
- **Boundary library** caught two cross-layer regressions during Phase 4 that would have shipped silently otherwise.

### What Was Inefficient

- **The v0.1.1 ship cycle surfaced 5 latent release-engineering bugs** that the v0.1.0 ship didn't catch:
  1. release-please's `extra-files` generic updater silently no-ops on a `mix.exs` already managed by the `elixir` release-type — discovered after two failed annotation attempts; fixed via workflow `sed` step.
  2. `publish-hex.yml`'s `workflow_run` gate `head_branch` startsWith check is dead code (head_branch is always `main`); manual `workflow_dispatch` was used for both v0.1.0 and v0.1.1.
  3. `post-publish-smoke.yml` has the same `head_branch` bug — VERSION resolved to literal `"main"`, so smoke timed out.
  4. Installer golden snapshots embed package version literals and were not regenerated as part of release-please's PR — recovery required force-moving v0.1.1 tags.
  5. `CLAUDE.md` leaks into HexDocs at https://hexdocs.pm/mailglass/claude.html (`mix.exs:262` extras).
- **Phase 5 + Phase 7 shipped without VERIFICATION.md** initially. Audit caught it; Phase 07.1 backfilled. Procedural gap, not substantive — but the audit's "missing VERIFICATION.md = blocker" rule is correct.
- **Wave 1 of Phase 3 spawned 5 parallel agents but credits ran out mid-wave**. Recovery was clean (cherry-pick from worktrees, restart 2 plans whose worktree work was incomplete) but cost a session.
- **Phase 7 admin_smoke_gate CI job matched zero tests for two ship cycles** (v0.1.0 + part of v0.1.1) before being noticed. Caught by audit; closed in 07.1-06 by adding `@tag :admin_smoke` tests.
- **Bare `mix test` citext-OID-cache race** when migration_test.exs runs concurrently with async tests. Worked around with `disconnect_on_error_codes` + per-test probe; full architectural fix deferred (Phase 6 deferred-items.md).

### Patterns Established

- **Decimal-phase insertion** for urgent post-roadmap work (Phase 07.1 to fix installer blockers + ship to Hex). Clean semantics: integer phases = planned, decimal = inserted.
- **Audit-fix-reaudit loop** before milestone close. v0.1 milestone audit at 2026-04-25 returned `gaps_found` (G-1..G-5); Phase 07.1 closed gaps; refreshed audit at close returned `passed`.
- **Repo write path SQLSTATE translation at exactly four sites** (`insert/2`, `update/2`, `delete/2`, `transact/1`). Single `translate_postgrex_error/2` defp is the one translation point. Pattern documented for future append-only schemas.
- **`Mailglass.Tenancy` public API as the only stamping path**. Raw `Process.put(:mailglass_tenant_id, …)` retired in Plan 02-04; `LINT-03 NoUnscopedTenantQueryInLib` enforces.
- **`:telemetry.span/3` directly when per-request enrichment needed; `Mailglass.Telemetry.execute/3` wrapper for closed-metadata calls**. The wrapper closes metadata at call time and cannot express enrichment — using it would regress Plan 04-04's deviation fix. Pattern documented in Plan 04-08.
- **Multi.run-then-Multi.run flat composition** for webhook ingest, NOT nested `Repo.multi` inside `Multi.run`. Nested form broke transaction scoping; flat form keeps everything in one transaction with correct rollback (Plan 04-06 revision W4).
- **Closed-atom-set reflectors on schemas** (e.g. `Event.types/0` returns the Anymail taxonomy + `:reconciled` internal). Pattern matches by struct + `__struct__` module comparison instead of literal `match?(%Mod{}, err)` to satisfy Elixir 1.19 type narrowing.

### Key Lessons

1. **Release Please's `extra-files` generic updater is fragile around release-type-managed files.** Document this for v0.1.2 fix; consolidate with the publish-hex.yml + post-publish-smoke.yml head_branch fix into a single tag-push trigger workflow.
2. **Audit-driven milestone close is non-negotiable.** The v0.1 audit caught installer blockers G-1..G-5 that would have shipped behind a green CI gate (the golden test fixture drove a simulated path, not real `Apply.run`). Re-running the audit BEFORE close, after fixes, is the loop that should be standardized.
3. **Procedural gaps (missing VERIFICATION.md) are real blockers in `/gsd-audit-milestone` even when the substantive verification is observable.** Don't skip the bookkeeping; it's the audit's only entry point for retroactive verification.
4. **Bleeding-edge floor (D-06) costs more than expected at the type-checker boundary.** Elixir 1.19 type narrowing forced `__struct__` comparison instead of literal struct pattern matching for error-type discrimination tests. Document the workaround once; expect more friction at every minor version.
5. **CLAUDE.md being shipped to HexDocs is a documentation hygiene smell.** Easy to fix; the embarrassment is a reminder that mix.exs `extras` deserves careful curation.
6. **Plan a "release engineering" mini-phase ahead of the FIRST Hex publish.** v0.1.0 + v0.1.1 both required manual `workflow_dispatch` because the auto-publish gate was dead code. Catching this before v0.1.0 would have saved an hour of recovery.

### Cost Observations

- **Cycle length**: 6 calendar days for 8 phases / 61 plans / ~33k LOC. High velocity sustained by GSD discipline.
- **Recovery overhead**: ~1 session lost to Wave 1 mid-wave credit exhaustion (Phase 3); ~30 min on each of 5 release-engineering bug recoveries during v0.1.1 ship.
- **Audit overhead**: 1 audit cycle (gaps_found → fix → passed). Worth it — caught installer blockers that would have shipped.
- **Phase research overhead**: Phases 2, 4, 5 research passes added value proportional to flag accuracy. Phases 1, 3, 6, 7 planned directly from synthesis without delay.

---

## Cross-Milestone Trends

*To be populated as future milestones complete.*
