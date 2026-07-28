---
id: SEED-007
status: dormant
planted: 2026-07-28
planted_during: v2.2 (CI Signal Integrity) scoping; blocking the 2.1.x Hex publish
trigger_when: immediately — this is the single remaining blocker on Core Full Suite, and Core Full Suite is release-blocking in gate-ci-green
scope: medium
---

# SEED-007: Ecto Sandbox Ownership Leak in the Core Suite

## The One-Line Version

**194 of 242 core-suite failures are `{:badmatch, :already_shared}` from
`Ecto.Adapters.SQL.Sandbox.start_owner!/2` — a sandbox-mode leak, not a citext
race and not schema teardown.** It is the last thing standing between `main` and
a publishable Hex release.

## Why This Is Urgent, Not Dormant

`gate-ci-green` in `publish-hex.yml` hardcodes its own advisory list:

```js
const ADVISORY_LANES = ['Operator Browser Gate', 'Demo Browser Evidence'];
```

`Core Full Suite Advisory` is **not** in it, so a Core Full Suite failure
**blocks every Hex publish** — despite `test/support/ci_lanes.ex` classifying it
as advisory. The lane is intermittent (it passed on the `mailglass-v2.1.0`
tagged SHA, failed on the PR #136 and #139 runs), so releases currently succeed
or fail on a coin flip.

## Evidence (2026-07-28)

Measured locally with a restored baseline DB and a fixed seed, so the runs are
comparable:

| Failure signature | Count |
|---|---|
| `{:badmatch, :already_shared}` in `Sandbox.start_owner!/2` | **194** |
| `42P01 undefined_table` | 31 |
| worktree-env fixture artifacts (Rewrite / Mix) | 14 |
| `citext probe exhausted` | **0** |

Controlled before/after on the citext-probe change (same seed, same DB state):
**233 failures before, 242 after** — statistically flat. The probe fix did not
cause this and did not mask it; it *revealed* it. Before that change every one
of these was reported as "citext probe exhausted", which is why the lane looked
like a flaky database race for so long.

## Where To Start Reading

`:already_shared` is raised when `start_owner!` is called while the sandbox is
already in `{:shared, pid}` mode owned by another process.

Shared mode is taken in:

- `test/support/mailer_case.ex:93` — `start_owner!(TestRepo, shared: not async?)`,
  so **every `async: false` test using MailerCase takes shared mode**
- `test/support/mailer_case.ex:158` and `:248` — explicit `{:shared, self()}` for
  Oban / Task.Supervisor dispatch
- `test/mailglass/outbound/deliver_many_test.exs:17`
- `test/mailglass/outbound/deliver_later_test.exs:37`

Sandbox mode is switched to `:auto` (disabling ownership entirely) and reverted
in `on_exit` by nine files:

- `migration_test.exs`, `upgrade_v2_schema_migration_test.exs`,
  `schema_prefix_hardening_test.exs`, `schema_isolation_integration_test.exs`,
  `schema_isolation_immutability_test.exs`, `shipped_migration_divergence_test.exs`
- `properties/webhook_suppression_convergence_test.exs`,
  `properties/idempotency_convergence_test.exs`,
  `properties/unsubscribe_post_idempotency_property_test.exs`

The likely shape: a test takes shared mode (or `:auto`) and its owner is not
stopped / mode not reverted before the next owner-taking test runs — whether
because `on_exit` ordering differs from expectation, or because a crash skips
cleanup. Confirm the mechanism before changing anything; do not "fix" it by
making tests `async: false`, which would hide it and slow the suite.

## What Has Already Been Ruled Out

Do not re-investigate these — each was tested empirically on 2026-07-28:

- **Not the citext OID race.** Zero exhaustion failures remain after the probe fix.
- **Not `migration_test.exs` teardown.** Its conditional-restoration defect was
  real and is fixed; the file now restores the baseline correctly.
- **Not the other schema teardown tests.** Running all six together leaves the
  baseline intact. `upgrade_v2_schema_migration_test` restores correctly and its
  own comments document the failure mode.
- **Not `demo_data_test.exs`** (shells out to the demo app) — leaves the baseline intact.
- **Not `shipped_migration_divergence_test.exs`** — leaves the baseline intact.
- **No single file** reproduces it in isolation; it requires the full suite, which
  points at cross-file global-state interaction rather than one bad actor.

## Definition of Done

1. The mechanism is explained, not just suppressed — a written account of which
   test leaves shared/auto mode set and why cleanup does not run.
2. Core Full Suite passes across all four matrix legs (1.18/OTP27 and 1.19/OTP28
   × `public` and `mailglass` schema axes), repeatedly, across seeds.
3. Ownership hygiene is enforced so it cannot silently recur — e.g. an assertion
   that the sandbox is back in `:manual` at the end of each mode-switching file.
4. A decision is recorded on whether `Core Full Suite` belongs in
   `gate-ci-green`'s `ADVISORY_LANES`, since today it silently gates every release
   while being documented as advisory.

## Related

- Fixed en route: the citext probe now re-raises permanent faults instead of
  masking them as "citext probe exhausted" — that change is what made this
  diagnosable at all.
- Feeds **v2.2 CI Signal Integrity** phase 142 (HARNESS).
- The gate-vs-`CILanes` advisory-list divergence is phase 144 (TRUTH) work; note
  the split's cited authority, `MAINTAINING.md`, has never existed in this repo.
