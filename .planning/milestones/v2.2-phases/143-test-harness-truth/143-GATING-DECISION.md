---
artifact: gating-decision
phase: 143-test-harness-truth
plan: 14
created: 2026-07-31
verdict: gate-floor-legs
rehearsal: run-rehearsal-pair
---

# 143-GATING-DECISION — the release gate, exercised

## 1. Verdict

The decision is **`gate-floor-legs`**: Core Full Suite is release-gating, limited to exact runtime-name
equality with these two Elixir 1.18 / OTP 27 floor legs:

```
Core Full Suite (Elixir 1.18 / OTP 27 / schema public)
Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)
```

The Elixir 1.19 / OTP 28 next-toolchain legs, `Provider Compatibility Advisory`, and both `Inbound Full
Suite Advisory` legs remain advisory. The authorised live-rehearsal option was **`run-rehearsal-pair`**.
A red floor leg has now been observed blocking the real Hex workflow, not merely a merge.

Before dispatch, all three safety preconditions were confirmed: `mailglass 2.3.0`, `mailglass_admin 2.3.0`,
and `mailglass_inbound 2.1.1` were live on Hex; no Release Please PR was open or mid-merge; and gate commit
`34008138` was an ancestor of `main` at `2ac5b278`. The tag was cut after that gate commit. The rehearsal
used `dry_run=true`; no package version changed and no Hex release occurred. This checkpoint matters because
a Hex release cannot be unpublished after sixty minutes.

## 2. Rationale

**Against gating:** comparable Elixir libraries generally publish on tag push without this test gate, and a
wedged gate in a hands-free, auto-merging pipeline is an unattended stall discovered only when a release does
not appear.

**For gating:** the existing required lanes are narrow contract and file-list checks. Before this change, a
total core regression could reach Hex without a red light; the 2.2.2 release demonstrated that the pipeline
could publish while the release SHA's overall CI run was red in an advisory browser job.

The asymmetry decides it. A blocked release costs the maintainer about thirty minutes and one dispatch. A
published broken core costs every adopter and, after sixty minutes, cannot be unpublished from Hex. The
override preserves release availability without pretending the gate is infallible.

## 3. Why only the floor pair

The repo's own CI research says to keep required matrices small and lists one gigantic required matrix as an
anti-pattern. The gated legs are exactly the declared `~> 1.18` floor in `mix.exs`, preserving the
floor-coincidence invariant. Gating is deliberately not widened merely because another lane happens to be
green; a new gating leg needs the same observation and negative-control evidence.

## 4. Why inbound remains advisory

The inbound suite pins seed `0` to avoid a known property-test pool flake. A lane whose green depends on a
hardcoded seed selected to dodge known nondeterminism is not trustworthy enough to veto a publish. Revisit
this only after the pool-mode leak is fixed and inbound is repeatedly green across unpinned, varied seeds.

`mailglass_inbound` depends on core with `{:mailglass, "~> 2.0"}`. It is a range, not an exact `==` pin, so
the dependency does not force paired core/inbound releases and is not a reason to widen this gate.

## 5. Evidence

| Run | Ref / event | Evidence |
|---|---|---|
| [`30595090072`](https://github.com/szTheory/mailglass/actions/runs/30595090072) | `d6e50388`, push | All four matrix legs green; floor seeds public `716451`, mailglass `921264`. |
| [`30635221221`](https://github.com/szTheory/mailglass/actions/runs/30635221221) | `981b9343`, push | Second distinct green `main` SHA; floor seeds public `860362`, mailglass `50081`. |
| [`30638980059`](https://github.com/szTheory/mailglass/actions/runs/30638980059) | `7649f96f`, push | Third distinct green `main` SHA; floor seeds public `766167`, mailglass `749958`. |
| [`30607136165`](https://github.com/szTheory/mailglass/actions/runs/30607136165) | `d6e50388`, schedule | Cold-cache unattended cron run green on all four legs. |
| [`30595564984`](https://github.com/szTheory/mailglass/actions/runs/30595564984) | throwaway tag, dispatch | A tag-shaped ref expanded both exact gating names and passed; tag deleted. |
| [`30599206217`](https://github.com/szTheory/mailglass/actions/runs/30599206217) | synthetic-failure branch | Both floor legs caught the deliberate regression ([public job `91058066866`](https://github.com/szTheory/mailglass/actions/runs/30599206217/job/91058066866), [mailglass job `91058066875`](https://github.com/szTheory/mailglass/actions/runs/30599206217/job/91058066875)). |
| [`30645266725`](https://github.com/szTheory/mailglass/actions/runs/30645266725) | real `mailglass_admin-v2.3.0` release | Positive path: [`gate-ci-green`](https://github.com/szTheory/mailglass/actions/runs/30645266725/job/91207000226) passed, after self-healing both absent workflow runs by dispatch. |
| [`30645265238`](https://github.com/szTheory/mailglass/actions/runs/30645265238) | real `mailglass-v2.3.0` release | The sibling [`gate-ci-green`](https://github.com/szTheory/mailglass/actions/runs/30645265238/job/91208030288) also passed. Its later core-publish failure was the known duplicate-publish race, not a gate failure; 2.3.0 is on Hex. |
| [`30645896855`](https://github.com/szTheory/mailglass/actions/runs/30645896855) | `d0054bdc`, self-healed dispatch | The positive release gate's dispatched Advisory Matrix run passed both floor legs. The sibling gate reused it. |
| [`30653681147`](https://github.com/szTheory/mailglass/actions/runs/30653681147) | `97e02b95`, dispatch | Negative precondition: every required `ci.yml` lane passed; only pre-existing `Demo Browser Evidence` was red. |
| [`30653683660`](https://github.com/szTheory/mailglass/actions/runs/30653683660) | `97e02b95`, dispatch | Both real floor legs failed on the injected assertion. Raw output reported `1629 tests, 1 failure` in each schema (seeds varied); this isolates the negative control to Core Full Suite. |
| [`30654293410`](https://github.com/szTheory/mailglass/actions/runs/30654293410) | negative tag, dry-run dispatch | [`prepublish-summary`](https://github.com/szTheory/mailglass/actions/runs/30654293410/job/91234781278) passed; [`gate-ci-green`](https://github.com/szTheory/mailglass/actions/runs/30654293410/job/91236237938) failed; [`publish-core`](https://github.com/szTheory/mailglass/actions/runs/30654293410/job/91236268528) was `completed/skipped` with zero steps, so it did not start. Admin and inbound publish jobs were likewise skipped with zero steps. |

The negative rehearsal used branch
`gate-rehearsal/143-14-negative-20260731T180337Z-2ac5b278`, annotated tag
`gate-rehearsal-143-14-negative-20260731T180337Z-2ac5b278`, and synthetic commit
`97e02b95739f5aef3f62284806ce037fa9b16cb7`. Its only diff was
`test/gate_self_test/intentional_failure_test.exs`, containing:

```elixir
assert false, "intentional failure for gate-self-test"
```

The dispatch command was:

```sh
gh workflow run publish-hex.yml \
  --ref gate-rehearsal-143-14-negative-20260731T180337Z-2ac5b278 \
  -f tag=gate-rehearsal-143-14-negative-20260731T180337Z-2ac5b278 \
  -f package=mailglass -f dry_run=true \
  -f skip_core_full_suite_gate=false \
  -f core_full_suite_gate_skip_reason=n/a
```

The gate's verbatim blocking result was:

```text
Delivery blocked: Core Full Suite gating lane(s) did not pass on SHA 97e02b95739f5aef3f62284806ce037fa9b16cb7:
  - Core Full Suite (Elixir 1.18 / OTP 27 / schema public) (failure)
  - Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass) (failure)
Run: https://github.com/szTheory/mailglass/actions/runs/30653683660
```

After evidence capture, the remote and local branch and tag were deleted. `ls-remote` and local ref scans
show no `gate-rehearsal` ref, and the synthetic test title is reachable from no remaining ref. Registry
versions remain `mailglass 2.3.0`, `mailglass_admin 2.3.0`, and `mailglass_inbound 2.1.1`.

## 6. Accepted gaps

1. **Publish fan-out race.** Linked releases can dispatch two gate runs and race to publish core. The
   settle/recheck reduces duplicate matrix work, but the real 2.3.0 release still showed the duplicate
   publish race. Registry state, not overall run conclusion, remains authoritative.
2. **Floating floor toolchain.** The gate resolves Elixir 1.18 loosely while artifact validation is stricter.
   A new patch-level deprecation warning can block a release with no repo change. That remains deliberate:
   adopters compile on their installed patch, and warning regressions are visible defects; the override is
   the pressure valve.
3. **Cold-cache wall-clock and external dependencies.** Every release may wait on a dispatched matrix run.
   The gated job also depends on Hex/network access, Postgres, inbound dependency installation, and schema
   verification, so infrastructure faults can block a clean tree.
4. **Publish-only sandbox hygiene.** Core Full Suite is not merge-gating. A raw sandbox ownership call can
   merge and only become blocking at publish time; the custom Credo check lowers but does not erase this gap.
5. **A count floor is not semantic coverage.** It proves tests executed, not that their assertions are
   useful; a tautology still counts.
6. **SuiteTruthFormatter's module-boundary probes are currently non-observing.** They read
   `%ExUnit.TestModule{}.tags[:async]`, which is always empty. The unshipped correction surfaces 103
   violations, including two real pool-mode leaks, and needs its own phase. This record therefore uses raw
   `mix test` output—not a green formatter ledger—as evidence.
7. **Inbound still hides nondeterminism with seed `0`.** It remains advisory until the known pool flake is
   fixed and unpinned multi-seed runs establish trust.

## 7. Override discipline

`skip_core_full_suite_gate` is workflow-dispatch-only and inert for an automated release event. It requires
the free-text `core_full_suite_gate_skip_reason`, renders that untrusted text as a code block in the run
summary, and emits a warning naming the bypass as an exception. This is the release-availability half of the
gating trade. It exists for a diagnosed false block or infrastructure outage; it must not become the habit.
