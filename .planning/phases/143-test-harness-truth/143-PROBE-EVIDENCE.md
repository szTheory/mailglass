---
artifact: probe-evidence
phase: 143-test-harness-truth
created: 2026-07-29
---

# 143-PROBE-EVIDENCE — `gate-self-test.yml` deliberate-failure probe runs

This ledger records every real dispatch of `.github/workflows/gate-self-test.yml` made during Phase
143, in the order they happened, with run URLs, recorded `result` outputs, and a reading of what each
run does and does not prove. See D-18 / D-18a in
`.planning/phases/143-test-harness-truth/143-CONTEXT.md` for the decision record this evidence backs.

---

## Run 1 — Defaults (`check_name="CI Green"`, `required_only=true`) — 2026-07-29

**Dispatch command (verbatim):**

```
gh workflow run gate-self-test.yml --ref main
```

(No inputs were passed; the workflow was dispatched before this plan's `required_only` /
`deadline_minutes` inputs existed on `main`, so it ran the pre-existing single-flag poll loop. This is
equivalent to the new workflow's default of `required_only=true`, `deadline_minutes=25` — the old loop
always passed `--required` and always used a 1500-second/25-minute deadline.)

**Run URL:** https://github.com/szTheory/mailglass/actions/runs/30482341388

**Result output:** `result=leaked` (recorded at `2026-07-29T19:06:28Z`, in the "Poll for CI Green check
completion" step log)

**Job conclusion:** `Gate Self-Test` → `failure` (the probe's own poll step exits 1 on `leaked`, which
is the intended fail-closed behaviour — the workflow succeeding would mean the gate is broken and going
unnoticed).

**Observed `CI Green` conclusion on the synthetic-failure PR (#150, CI run
[`30482357828`](https://github.com/szTheory/mailglass/actions/runs/30482357828)):** `success`.

### The mechanism, precisely — this is the empirical confirmation of D-18a

The probe's own log line reads `"ERROR: CI Green check returned SUCCESS on a synthetic-failure PR / The
gate is NOT enforcing halt-on-failure."` **That framing is imprecise and must not be repeated as the
finding.** `CI Green` (`.github/workflows/ci.yml:1141-1171`) is `if: always()` with exactly seven
`needs`:

```
compile_no_optional_deps, installer_host_smoke, support_contract_core, support_contract_admin,
trust_lane_repo_head, hex_audit, deps_audit_advisory
```

Its evaluation script (`ci.yml:1154-1171`) fails only when one of those seven `needs.*.result` is
`failure` or `cancelled`. **None of those seven jobs runs the root-project core test suite** — this is
the same fact D-18a already established by reading `ci.yml:355` and `:362` (both
`working-directory: mailglass_inbound`) and the explicit file-list / directory-glob root lanes in
`mix.exs:285-302`. So the correct statement is:

> The required branch-protection context (`CI Green`) aggregates a set of lanes that excludes every
> test-suite lane. It is not that the gate fails to enforce halt-on-failure — it is that the gate is
> structurally blind to test regressions, because nothing it watches is capable of observing one. A
> deliberately-injected failing test in `test/gate_self_test/` cannot turn `CI Green` red, no matter how
> long the probe waits, because `CI Green` never asks a question that test file could answer.

This was previously a verified-by-static-read hypothesis (D-18a); this run is the first live,
end-to-end confirmation — the probe was actually dispatched, the failing test was actually injected and
pushed, `CI Green` actually completed, and it actually reported `success`.

### A second, independent gap observed in the same run — record separately, do not merge with the above

In CI run `30482357828` (the same run whose `CI Green` job is discussed above), the job **`Demo Browser
Evidence (Docker Compose / Chromium)`** reported **`failure`**, and **`Operator Browser Gate (Elixir
1.18 / OTP 27 / Node 22)`** had not finished (`in_progress`) at the moment `CI Green` concluded. `CI
Green` still reported `success`, because **neither job appears in its `needs` list.** This is a
distinct finding from the test-suite blindness above: it shows the required context is blind to at
least one lane (`Demo Browser Evidence`) that genuinely went red on this very PR, independent of
anything this phase injected. This is scoped as CONFORM-02 / TRUTH-02-adjacent territory (Phase 144),
not something Phase 143 fixes — recorded here because it surfaced live, during this phase's own probe
run, and would otherwise be lost.

### What this run proves, and what it does not

**Proves:** the required gate (`CI Green`) is blind to test regressions — confirmed live, not just by
static read. The seven-lane `needs` list is the complete evidence for why.

**Does NOT prove:** that the advisory lane (`Core Full Suite Advisory`, which does run the test suite)
*would* catch the same regression if polled directly. That requires a `gate-self-test.yml` dispatch with
`required_only=false` pointed at `Core Full Suite (` — this phase's Task 1 built that capability; running
it against the (still advisory-named) lane is plan **143-12**'s job, not this one. No such dispatch was
made here, and none should be inferred from the section below.

**Cleanup confirmed:** `gh pr list --search 'head:gate-self-test/' --state open` returns `[]` and
`git ls-remote --heads origin 'gate-self-test/*'` returns nothing — the workflow's `if: always()`
cleanup step closed PR #150 and deleted its branch as designed. No manual cleanup was required.

### Deviation encountered and resolved during this run

PR #150's three triggered workflow runs (`CI`, `Advisory Matrix`, `Guard Release Trigger`) initially sat
in GitHub's `action_required` state with zero jobs queued — the repository requires manual approval for
workflow runs on a PR whose author GitHub attributes to `github-actions[bot]` (the PR was opened via
`gh pr create` using `secrets.GITHUB_TOKEN` inside the probe's own "Open draft PR" step). Left
unapproved, the probe's 25-minute poll would have expired against a `CI Green` check that never even
started, producing a misleading `result=timeout` that looks like a slow CI run rather than what it
actually is (an approval gate the probe cannot see or self-heal). This was resolved by approving the
three pending runs directly (`gh api -X POST repos/szTheory/mailglass/actions/runs/{id}/approve` for
runs `30482357117`, `30482357828`, `30482357115`) — a maintainer action available because of the
`workflow` OAuth scope already held, not a code or workflow change. **This is itself a latent gap in the
probe worth naming for a future phase:** `gate-self-test.yml` has no mechanism to detect or auto-approve
an `action_required` state, so an unattended dispatch (e.g. from a cron, if one were ever added — which
D-18/the phase context explicitly forbids) would silently stall for its full deadline and report
`timeout`, never revealing that the actual cause was an unapproved run. Not fixed here — out of this
plan's scope (workflow topology / GitHub repo settings), noted for whoever next touches
`gate-self-test.yml`'s failure modes.

---

## Bonus incidental observation — NOT the 143-12 probe run, recorded for completeness only

PR #150 also triggered `advisory-matrix.yml` on its own `push` trigger (run
[`30482357115`](https://github.com/szTheory/mailglass/actions/runs/30482357115)), independent of
anything `gate-self-test.yml` dispatched or polled. By the time the probe's poll loop gave up on `CI
Green` (`2026-07-29T19:06:28Z`), this run was still `in_progress`; it has since completed with:

- `Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema public)` → **`failure`**
- `Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema mailglass)` → **`failure`**
- `Core Full Suite Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})`
  → **`skipped`**, with the matrix expression left **unexpanded** in the reported name — the exact
  `pull_request`-event job-name-collapse artifact D-21 predicted from static analysis of prior runs.
  Recorded here as a second live confirmation of that mechanism; **fixing it is plan 143-11's job, not
  this one.**

This is suggestive — the two 1.18/OTP 27 legs (the ones D-19 would make gating) genuinely did go red on
the same injected failure — but it is **not** the evidence Task 2 or D-18's second probe calls for,
because it was not produced by dispatching `gate-self-test.yml` with `required_only=false` against this
lane. It is recorded only so a future reader does not rediscover it and mistake it for that evidence.
**Do not cite this section as satisfying 143-12's requirement.**

---

## Core Full Suite probe run — RESERVED for plan 143-12

**This section is intentionally left for plan 143-12 to fill in.** Do not backfill it from the
"Bonus incidental observation" above — that run was not a `gate-self-test.yml required_only=false`
dispatch and does not satisfy this section's evidence bar.

**Expected value, stated up front (per RESEARCH.md Pitfall 3 — a run URL with no stated expected
result before the run happens is itself a warning sign of a probe nobody is actually reading):** once
the Core Full Suite lane is renamed (D-21, plan 143-11) and green across its floor legs (Wave 2/3 of
this phase), a `gate-self-test.yml` dispatch with `-f check_name="Core Full Suite (" -f
required_only=false` against a synthetic-failure PR is expected to report **`result=blocked`** — i.e.
the renamed lane actually goes red on the injected failure and the probe observes it, in contrast to
`CI Green`'s structural blindness recorded above. If the recorded result is anything other than
`blocked` (`leaked`, `timeout`, or the new `never-appeared` outcome this plan's Task 1 added), that is
itself a finding requiring investigation before HARNESS-04's gating checkpoint (D-28) can proceed —
per this phase's own coordinating principle, a probe that cannot observe its subject must never be
read as a quiet pass.

*(Fill in below: dispatch command, run URL, `result` value, observed check conclusion, and reading.)*
