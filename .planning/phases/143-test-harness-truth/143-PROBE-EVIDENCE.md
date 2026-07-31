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

### RESULT: **the lane blocks.** Both gating legs went red on the injected regression.

Observed 2026-07-31 on post-merge `main` (PR #151 merged as `d6e50388`, so the D-21 rename is live).

| Leg | Conclusion | Job |
|---|---|---|
| `Core Full Suite (Elixir 1.18 / OTP 27 / schema public)` | **FAILURE** | https://github.com/szTheory/mailglass/actions/runs/30599206217/job/91058066866 |
| `Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)` | **FAILURE** | https://github.com/szTheory/mailglass/actions/runs/30599206217/job/91058066875 |

Probe PR: https://github.com/szTheory/mailglass/pull/156 (closed, branch deleted). Injected commit
carried `test/gate_self_test/intentional_failure_test.exs` **verbatim** as `gate-self-test.yml` writes
it, on a branch cut from the green `main` SHA.

This is the `result=blocked` outcome the expected-value paragraph above predicted, and it is the
evidence condition 4 asks for: the renamed lane demonstrably catches an injected regression, unlike
`CI Green`, whose structural blindness is recorded earlier in this file.

### Why it was NOT produced by a `gate-self-test.yml` dispatch

**`gate-self-test.yml` structurally cannot produce this evidence, and three dispatches proved it.**
GitHub does not trigger workflows for events raised with `GITHUB_TOKEN`, so the PR the workflow opens
itself receives **zero checks**. Run 30597469482 polled for 35 minutes and its own diagnostic printed
an empty observed-check list. This is the same anti-recursion rule already documented for
release-please bot-merged SHAs (CLAUDE.md).

The probe above was therefore opened with a real user token so CI would actually run. It is
equivalent in every other respect — same synthetic commit, same base, same lane names, same
`FAILURE`-vs-`SUCCESS` reading — but it is a **manual** procedure, not an automated one, and that
distinction must not be lost:

- **Reproducing it requires a human** (or an agent with a user token) to open the PR. It is not a
  push-button dispatch today.
- **Making `gate-self-test.yml` self-sufficient requires a stored PAT** so the PR it opens triggers
  workflows. That is an unresolved maintainer decision, not a code gap.

Three real defects in `gate-self-test.yml` were found by running it and are fixed separately (PR #155):
the poll loop could not survive the window before checks register (run 30595556100 produced no
`result=` at all); a hardcoded `timeout-minutes: 30` silently truncated a larger `deadline_minutes`
and cancelled run 30596060407 mid-poll; and an absent check was logged as `status=pending`, making an
unobserved lane read as an observed one.

**Reading for HARNESS-04 / D-28.** Condition 4's substantive bar — *a lane never observed catching an
injected regression must not be given veto power over a publish* — is now **met**: the lane was
observed catching one. The residual gap is that the observation is not yet reproducible without a
human in the loop, which is a decision for the gating checkpoint to weigh rather than a blocker on
the lane's demonstrated behaviour.

### STATUS AS OF PLAN 143-12: **NOT RUN — no dispatch was made, no run URL exists**

Plan `143-12` Task 1 could not be executed. Its process constraints state, verbatim, **"Do NOT push. Do
NOT trigger GitHub Actions runs (real CI minutes on a public repo)."** `gate-self-test.yml` cannot be
exercised without doing both: it pushes a synthetic-failure branch and opens a real pull request, which
triggers `ci.yml`, `advisory-matrix.yml` and `guard-release-trigger.yml`.

There is therefore **no `result` value, no run URL, and no observed lane conclusion for the renamed lane.**
Nothing in this section may be read as evidence that the probe passed, and the expected value stated above
remains an *expectation*, not an observation. This is the same class of omission recorded by plans `143-10`
(Task 3's post-change dispatch) and `143-11` (the post-rename push run) — recorded openly rather than
claimed.

**Condition 4 of the D-28 promotion checkpoint is consequently NOT MET.** See
`143-PROMOTION-CHECKPOINT.md`.

### The plan's own automated verification for this task is vacuous — recorded so it is not trusted

`143-12-PLAN.md` Task 1 verifies with:

```
grep -q 'result=blocked' .planning/phases/143-test-harness-truth/143-PROBE-EVIDENCE.md
```

That command **already exited 0 against this file before plan 143-12 began**, because the "Expected value,
stated up front" paragraph above legitimately contains the string ``**`result=blocked`**`` at line 150 as a
statement of what the probe *should* report. Verified:

```
$ grep -q 'result=blocked' .planning/phases/143-test-harness-truth/143-PROBE-EVIDENCE.md && echo PASSES
PASSES
$ grep -n 'result=blocked' .planning/phases/143-test-harness-truth/143-PROBE-EVIDENCE.md
150:required_only=false` against a synthetic-failure PR is expected to report **`result=blocked`** — i.e.
```

The check cannot distinguish "the probe ran and the lane blocked" from "the probe never ran and this file
merely predicts that it would." It is precisely the failure mode this phase exists to eliminate — a check
that reports success without observing its subject — appearing inside the phase's own plan. **Do not treat a
green Task 1 verification as evidence.** The evidence is a run URL plus a recorded `result` line from the
probe's own poll step, and neither exists yet.

A non-vacuous replacement would assert the run URL and the outcome together, e.g.
`grep -Eq '^\*\*Result output:\*\* `result=blocked`' ...` combined with a
`https://github.com/szTheory/mailglass/actions/runs/[0-9]+` match in the same section.

### The dispatch to run, verbatim, when CI minutes are authorised

```
gh workflow run gate-self-test.yml \
  --ref gsd/phase-143-test-harness-truth \
  -f check_name="Core Full Suite (" \
  -f required_only=false \
  -f deadline_minutes=40
```

Each input, and why it is what it is:

| Input | Value | Why |
|---|---|---|
| `--ref` | `gsd/phase-143-test-harness-truth` | **Not `main`.** The D-21 rename is unmerged. `main`'s `advisory-matrix.yml` still names the lane `Core Full Suite Advisory (`, which does **not** `startswith("Core Full Suite (")`, so a dispatch from `main` would poll for a name that cannot exist and report `never-appeared`. The branch also carries the `required_only` / `deadline_minutes` inputs themselves, which `main` does not have (see Run 1's dispatch note above). |
| `check_name` | `Core Full Suite (` | The renamed gating job's display name up to and including its opening parenthesis. The trailing `(` is load-bearing: without it the prefix would also match `Core Full Suite Next Toolchain Advisory (…)`, and `jq … | head -1` would poll whichever GitHub returned first. |
| `required_only` | `false` | Branch protection's required set is exactly `{CI Green, Guard Release Trigger}` — two entries, asserted by `test/scripts/required_checks_test.exs` ("REQUIRED_CHECKS contains exactly {CI Green, Guard Release Trigger} (GATE-01)"). An advisory-matrix lane never appears in a `gh pr checks --required` query, so leaving this `true` guarantees `never-appeared`. |
| `deadline_minutes` | `40` | The lane's own cold-cache full-suite leg ran **258.2 s** of `mix test` alone in run `30574508370`, and the job additionally does `deps.get`, `compile --warnings-as-errors`, a Postgres wait, the inbound `deps.get` / `ecto.create`, and `mix verify.schema_prefix`. The probe also waits for branch creation, PR opening and job scheduling. The 25-minute default is tight; 40 leaves headroom without risking the workflow's own `timeout-minutes: 30` — **note that job-level cap and raise it too if a longer deadline is wanted.** |

**Known blocker that will otherwise consume the whole deadline and report a misleading `timeout`:** Run 1
recorded that PRs opened by the probe are attributed to `github-actions[bot]`, and this repository holds
such runs in `action_required` until a maintainer approves them. Approve promptly with
`gh api -X POST repos/szTheory/mailglass/actions/runs/{id}/approve` for each pending run, or the probe will
poll a check that never starts. `gate-self-test.yml` still has no mechanism to detect or self-heal this
state.

**Expected outcome remains as stated above:** the renamed lane goes red on the injected failing test and the
probe reports a blocked result. Any other outcome — `leaked`, `timeout`, or `never-appeared` — is a finding
requiring investigation, not an inconclusive-but-fine pass.

### One caution specific to running this probe today

`main` is currently red on this very lane for reasons unrelated to any injected failure (see
`143-PROMOTION-CHECKPOINT.md`, condition 1). The probe injects a failing test and asserts the lane goes red,
so it would report a blocked result **even if the lane were red for a pre-existing reason** — the probe
cannot distinguish "red because of my injection" from "red anyway." To keep the result meaningful, dispatch
it from a ref whose lane is *green* without the injection. The phase branch at `6bacf2ff` is such a ref
(run `30574508370`, both gating legs green); `main` is not.
