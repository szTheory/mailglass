# Phase 143: Test-Harness Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-29
**Phase:** 143-test-harness-truth
**Areas discussed:** Evidence bar for the mechanism, Fix shape + recurrence guard, Anti-vacuity proof
design, Publish-gating scope + lane naming (all four selected)

**Mode note:** The user selected all four gray areas and asked for research subagents to produce a single
coherent, one-shot recommendation set — explicitly *"so I don't have to think"* — covering pros/cons/
tradeoffs, Elixir/Plug/Ecto/Phoenix idiom, lessons from comparable successful libraries (including
cross-language), DX/ergonomics, brand-voice microcopy, and multi-lens expert review. Four
`gsd-advisor-researcher` agents ran in parallel, one per area. No per-question selection took place, so
the tables below record the *researched* alternatives and which one was locked, rather than user picks.

---

## Area A — Evidence bar for confirming the mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Ownership ledger in `test/support/` + Credo enforcement | Public-API instrumentation; attributes a leak to `module/test/file:line` in one run; survives as permanent hygiene | ✓ |
| `:erlang.trace` / `:dbg` on Sandbox + Ownership.Manager | Zero code change, catches unknown call sites incl. deps | Fallback only |
| ExUnit `:telemetry` handler | Idiomatic-sounding | Rejected — **not viable**; no ownership telemetry is emitted (verified against `deps/`) |
| Custom `ExUnit.Formatter` alone | Precise ordering/timestamps, no test changes | Rejected as primary — `%ExUnit.Test{}` carries no pid, so it cannot link a test to an owner |
| Seed / ordering bisection (RSpec `--bisect` analogue) | Cheap to describe, celebrated precedent | Rejected — **actively misleading here**; `:auto` files *heal* the leak, so leaker and victim aren't adjacent |
| `dev/mix/tasks/mailglass.sandbox_trace` | Matches the `repo.hygiene` maintainer-task precedent | Rejected — instrumentation must run inside `mix test`; use `MAILGLASS_SANDBOX_TRACE=1` |
| Written account only (class a) | Cheapest | Rejected — fails the repo's mechanical-proof culture and SEED-007 DoD #3 |
| Written account + deterministic **full-suite** repro (class c strict) | Strongest possible bar | Rejected — not achievable; would set the phase up to fail or fake it |

**Locked:** artifact class **b+** — written account + committed ledger dump from an instrumented
pre-fix full-suite run + a deterministic *mechanism-level* regression test (CONTEXT D-04).

**Notes:** The researcher ran the confirming experiment rather than only proposing one, against the real
`Mailglass.TestRepo`. Six-step proof reproduced `{:badmatch, :already_shared}` at `sandbox.ex:458`
exactly, and established that `mode(:auto)` *heals* a leaked owner and that `shared: false` is immune.
Independently re-verified in the main session: `manager.ex:148-159` (the `Process.alive?(current)` guard),
`sandbox.ex:448-465` (the unlinked `Agent.start` and the `:ok =` badmatch), the two leak windows in
`webhook_idempotency_convergence_test.exs:51-69`, and `data_case.ex:35-36`'s correct idiom.

**Consequence:** ROADMAP criterion 1's stated leading hypothesis is half backwards, and HARNESS-01's
prime named suspect (`Mailglass.DataCase`) is exonerated. CONTEXT D-31 records the required amendments.

---

## Area B — Fix shape + recurrence guard

**Fix shape:**

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Fix only the leaking site(s) | Smallest diff, fastest to green | Rejected — leaves the pattern re-typable; fails SEED-007 DoD #3 |
| (b) Centralize behind one sanctioned helper | Makes the acquire/release pairing structurally impossible to get wrong | ✓ |
| (c) Eliminate `:auto` via `unboxed_run/2` | Process-local; removes the bug class | Partially — adopted as the forward idiom, migration of existing files deferred |
| (d) Blanket `async: false` | — | **Prohibited** by SEED-007 |

**Recurrence guard:**

| Option | Description | Selected |
|--------|-------------|----------|
| Per-file `on_exit` postcondition | What DoD #3 literally suggests | Folded into the helper — rejected standalone because it is opt-in |
| ExUnit formatter at `:module_finished` + `after_suite` failure | Zero opt-in; names the offender immediately; heals so the rest of the run yields signal | ✓ (detection) |
| `after_suite` alone | Simplest | Only as the failure channel — fires too late to name anyone |
| Custom Credo check | Repo's native idiom (20 existing checks) | ✓ (prevention) |
| Compile-time / architectural boundary | Strongest in principle | Rejected — Elixir has no import restriction; the Credo check *is* the idiomatic boundary |

**Locked:** (b) + both guard layers (CONTEXT D-06, D-08).

**Notes:** Surfaced a second defect (S2) independent of the leak: four raw
`Sandbox.mode(repo, {:shared, self()})` calls whose `:already_shared` return is discarded, with a comment
at `mailer_case.ex:153-157` claiming a guarantee the code does not provide — a check that cannot do its
job reporting green, *inside the harness of the milestone that exists to kill that*. Main-session
verification **corrected the researcher's read**: these are redundant no-ops, not broken guarantees —
`start_owner!(shared: true)` already put the pool in shared mode, so deletion is behavior-preserving and
no `set_mailglass_global` semantics change (CONTEXT D-07).

---

## Area C — Anti-vacuity proof design

| Option | Description | Selected |
|--------|-------------|----------|
| `ExUnit.after_suite/1` for counts | Programmatic; typespec verified identical on 1.18.4 and 1.19.5 | ✓ |
| Parse the `mix test` summary line | No Elixir code | Rejected on **correctness** — `N tests` is `total - excluded`, not executed |
| Formatter computing all counts | Full control | Rejected for counts; adopted **narrowly** for failure signatures |
| Hardcoded constants in a committed module | Matches `Mailglass.CILanes` | ✓ |
| Committed baseline JSON | Language-agnostic | Rejected — invites CI to rewrite it (SimpleCov `.last_run.json` failure mode) |
| One global floor | One number | Rejected — legs legitimately differ (`:public_only`) |
| Per-schema floors, `>=`, manual raise | Correct per leg; never fires on added tests | ✓ |
| **Pinned exclusion-tag allowlist** | Fails on the tag name before arithmetic matters | ✓ — **the load-bearing invariant** |
| `skipped == 0` | Strict | Rejected — **false today**; 8 `@tag :skip` exist. Measured ceiling instead |
| Extend `gate-self-test.yml` | Reuses the precedent HARNESS-03 names | ✓ |
| New probe job in `advisory-matrix.yml` / scheduled probe | Co-located / continuous | Rejected — SEED-006 wall-clock; opens real PRs on a cadence |
| Deterministic unit test on `violations/1` | Free, exercises the real function | ✓ (the count-floor negative case) |
| Mutation testing, coverage gates, external reporting | Stronger claims | Rejected as over-engineering, with reasons recorded so they aren't re-litigated |

**Locked:** CONTEXT D-13 through D-18b.

**Notes:** Surfaced that **no `ci.yml` lane runs the root `mix test`** — main-session verified (both
invocations are `working-directory: mailglass_inbound`; all root lanes use explicit file lists or the
`test/scripts/` glob). So the existing `gate-self-test.yml` is vacuous against `CI Green`, and Core Full
Suite is the first lane whose run command actually reaches the injection point. Recorded as a finding and
routed to Phase 144; fixing `ci.yml` coverage is a topology change this phase is forbidden.

---

## Area D — Publish-gating scope + lane naming

| Option | Description | Selected |
|--------|-------------|----------|
| Do not gate at all | Matches the ecosystem norm (Bandit/Phoenix/Ecto/Oban/Req/Broadway gate publish weakly or not at all) | Rejected on cost asymmetry — but preserved as a clean fallback |
| Gate all four legs | Maximal safety | Rejected — 1.19/OTP28 is the forward-compat canary; violates LD-13's intent |
| **Gate the two 1.18/OTP27 legs only** | The declared `~> 1.18` floor | ✓ |
| Gate only the `public` schema legs | Cheaper | Rejected — the `mailglass` schema axis is a shipped v2.0 contract |
| Gate `Inbound Full Suite Advisory` too | Green today | Rejected — its green depends on a `--seed 0` flake pin |
| Keep "Advisory" in the gating lane's name | No rename churn | Rejected — Phase 141/142 signal-honesty precedent, and the rename is mechanically load-bearing |

**Locked:** CONTEXT D-19 through D-26.

**Notes:** The researcher made live GitHub API checks and returned three empirical corrections, all
re-verified in the main session:
1. **Runtime names carry no matrix suffix** (interpolated `name:` templates), so exact-equality matching
   works — the naming collision is in the *declared*-name space, which is what makes registry
   set-equality vacuous.
2. **The 1.19/OTP28 legs fail in the suite, not at toolchain setup** — the in-file "setup-beam may not
   resolve 1.19/28" hazard is hypothetical today.
3. **`advisory-matrix.yml` has ZERO runs on bot-merged release SHAs** (confirmed: `25c74ca0` → 1 `ci.yml`
   run, 0 advisory-matrix runs), so self-heal dispatch is the default path, not an edge case.

Main-session verification added a **fourth** name form the research missed: on `pull_request` runs the
1.19 job collapses to a single `skipped` entry carrying the **literal uninterpolated template**
`Core Full Suite Advisory (Elixir ${{ matrix.elixir }} / ...)` — byte-identical to the 1.18 job's declared
name. This sharpens the rename rationale and means any drift test must handle three name forms. It is not
a gate-correctness problem, since publish reads a tag/push run.

Also observed live: the last release fired **two** simultaneous `publish-hex` runs (the Phase 144 /
TRUTH-08 fan-out race), which the gate design must tolerate (CONTEXT D-30).

---

## Claude's Discretion

The user delegated every decision, asking for one coherent recommendation set rather than per-question
selection. All decisions in CONTEXT.md are Claude's calls under the CLAUDE.md decision policy
(research → synthesize → decide → escalate rarely).

The one genuinely strategic fork — **whether to gate a publish at all** (D-19) — was researched from both
sides and decided rather than escalated, on the grounds that it is reversible config rather than a
contract break: a blocked release costs 30 minutes and a dispatch; a published broken core cannot be
unpublished after 60 minutes on Hex. If the maintainer disagrees, D-19 and Wave 4 drop wholesale without
disturbing Waves 1-3, and HARNESS-04 becomes a recorded "not gating, and here is why" — which ROADMAP
criterion 4 explicitly permits ("**whether** Core Full Suite is now release-gating").

Left to the planner: task decomposition, per-file `on_exit`-ordering verification order for the nine
`:auto` files, and final wording of the composed failure messages (drafts exist in the research).

## Deferred Ideas

- Migrating the three property files from `:auto` to `Sandbox.unboxed_run/2` (the six migration/schema
  files cannot migrate — `Ecto.Migrator.with_repo/2` spawns a process `unboxed_run` cannot cover).
- Fixing `gate-self-test.yml`'s vacuity against `CI Green` → Phase 144 / `.planning/TOOLING-DEFECTS.md`.
- Promoting the sandbox-hygiene Credo lane to merge-gating (currently publish-gating only).
- Gating `Inbound Full Suite Advisory` once its `--seed 0` flake pin is removed (SEED-006 / LD-8).
- The publish fan-out race (TRUTH-08, Phase 144) — designed around here, not fixed.
- SEED-006 CI/CD efficiency work — deliberately sequenced after v2.2.
- Mutation testing / coverage gates / external count reporting — declined with reasoning recorded.
