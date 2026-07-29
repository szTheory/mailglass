---
artifact: tooling-defects
stable_ids: true
created: 2026-07-28
---

# TOOLING-DEFECTS — Recognized GSD Tooling Defects

> This register is deliberately **milestone-independent** — it lives at the `.planning/` root, not
> under a `milestones/<version>-phases/` directory. Both existing registers in this repo
> (`.planning/RATCHET-GAP-REGISTER.md`, `.planning/research/v1.14/DEFECT-REGISTER.md`) are milestone-
> scoped by design and get archived away with their milestone. A defect record whose only job is to be
> recognized by a future run of the same command must survive a milestone boundary, so this file
> deliberately breaks that pattern.

## How to read this register

- Stable `TOOL-NN` IDs, never renumbered once assigned.
- Each entry carries **Symptom**, **Occurrences**, **Evidence**, **Mitigations**, and **Status**.
- The Symptom line is the load-bearing content: someone re-running the command must recognize the
  failure from what they see on screen, not from a git-archaeology exercise.

---

## TOOL-01 — `gsd-tools query phases.clear` deletes phase directories without writing the archive

**Symptom:** `cleared: N` is reported and the command exits looking successful, but no
`milestones/<version>-phases/` directory is written. The phase directories are gone; there is no
archive to show for it.

**Occurrences (two, both in this repo):**

1. **v2.0 phases 132-137.** `b5fed519` ("docs: start milestone v2.1") deleted 48 files under
   `.planning/phases/132-*` … `137-*`. `a629fb82` restored all 48 under
   `.planning/milestones/v2.0-phases/`. Per-file `git hash-object` comparison against `b5fed519^`:
   `ok=48 missing=0 differ=0`.
2. **v2.1 phases 138-140**, during v2.2's own opening on 2026-07-28. `70099869` moved 39 files;
   `git show --name-status -M 70099869` reports all 39 as `R100`. The delete and the by-hand repair
   landed in the same commit.

**Evidence** — the only place this defect was recorded before this file existed, quoted verbatim from
`70099869`'s commit body:

> `gsd-tools query phases.clear --archive-version v2.1` reported `cleared: 3` but deleted the three
> phase directories without writing the archive.

**Mitigations, ranked:**

- **PRIMARY (post-condition check).** After any `phases.clear`, list `.planning/milestones/<outgoing>-
  phases/` and compare its file count against `git show --stat HEAD` **before committing**. A count
  mismatch, or a missing directory, is the defect showing up in front of you — catch it there, not
  three commits later.
- **necessary but insufficient — does NOT prevent this.** Passing `--archive-version <outgoing>`
  explicitly. It was passed on the 2026-07-28 occurrence (`gsd-tools query phases.clear
  --archive-version v2.1`) and the archive was still not written. Record it anyway: `new-milestone`
  runs `state.milestone-switch` **before** `phases.clear`, so a live `STATE.md` read at that point would
  file the archive under the *incoming* milestone rather than the outgoing one — the flag is still
  required for correct filing, it is simply not a fix for this defect. It is recorded here as
  necessary but insufficient, not as the fix.

**Status / tool version observed:** `gsd-sdk v1.42.3` (`~/.claude/gsd-core/bin/lib/milestone.cjs`),
which archives rather than hard-deletes (`#1871`), refuses to run against uncommitted phase work
(`#1447`), and accepts `--archive-version` (`#2288`).

**Live recurrence risk:** v2.2's own milestone close invokes the same command against phases 141-144.
Run the post-condition check above before that close is committed.

---

## TOOL-02 — `CI Green` is structurally blind to test regressions: none of its seven `needs` runs the root `mix test`

**Symptom:** Dispatching `gate-self-test.yml` at its defaults (`check_name="CI Green"`,
`required_only=true`) injects `test/gate_self_test/intentional_failure_test.exs` — a test that always
fails — into a synthetic PR, and `CI Green` still reports `SUCCESS`. **Precise framing, corrected from
the probe's own log line:** this is NOT "the gate does not enforce halt-on-failure" (what the probe's
`ERROR:` text says). The gate's enforcement logic (`ci.yml:1154-1171`) is doing exactly what it is
written to do — fail if any of its seven `needs` reports `failure`/`cancelled`. The defect is that
**none of those seven jobs is capable of observing a test regression at all**, so the gate isn't failing
to enforce a rule against the failing test — it never had a rule that mentions the failing test in the
first place.

**Occurrences (one, discovered and empirically confirmed live during Phase 143 plan 02):**

1. **2026-07-29, probe run [`30482341388`](https://github.com/szTheory/mailglass/actions/runs/30482341388)**
   (`gate-self-test.yml`, dispatched at defaults against `main`) → `result=leaked`, recorded
   `2026-07-29T19:06:28Z`. **CI run
   [`30482357828`](https://github.com/szTheory/mailglass/actions/runs/30482357828)** is the synthetic-
   failure PR's `ci.yml` run underlying that result: `CI Green` → `success` despite the injected
   failing test. Full evidence, including the exact `needs` list and job conclusions, is recorded in
   `.planning/phases/143-test-harness-truth/143-PROBE-EVIDENCE.md`.

**Evidence — verified by direct read AND by this live run, not inference alone:**

- `CI Green` (`.github/workflows/ci.yml:1141-1171`) is `if: always()` with exactly seven `needs`:
  `compile_no_optional_deps`, `installer_host_smoke`, `support_contract_core`,
  `support_contract_admin`, `trust_lane_repo_head`, `hex_audit`, `deps_audit_advisory`. Its script
  (`:1154-1171`) fails only when one of those seven `needs.*.result` is `failure` or `cancelled`.
- `.github/workflows/ci.yml:355` and `:362` are the **only two** `mix test` invocations in the entire
  workflow, and **both** carry `working-directory: mailglass_inbound` (`ci.yml:345`) — neither is
  among the seven `needs`, and neither touches the root project's `test/` directory where the probe's
  injected file lives.
- Every root-project CI lane instead runs an **explicit file list** or a **directory glob**, never a
  bare `mix test` over `test/`: `verify.support_contract.core` (`mix.exs:296`) lists specific files;
  `verify.ci_lane_contract` (`mix.exs:294`) globs `test test/scripts/`; `verify.mix_tasks`
  (`mix.exs:287`) globs `test test/mix/tasks/`. None of these paths includes `test/gate_self_test/`,
  and none is required to feed `ci_green.needs` for the ones that are.
- `mix ci` (`mix.exs:388-394`) **does** run the root `mix test` — but `mix ci` is a local developer
  alias, not a `ci.yml` lane. It never executes in CI, so it cannot make `CI Green` non-blind.
- **Live confirmation, run `30482357828`:** every one of the seven `needs` jobs reported `success` on
  the synthetic-failure PR — none of them runs the root suite, so none of them could have observed the
  injected failure. `CI Green` correctly aggregated seven honest successes into one honest success; the
  dishonesty is upstream, in what the seven lanes were chosen to cover.

**A second, independent gap surfaced by the same run — record separately, do not conflate:** in the
same run `30482357828`, the job `Demo Browser Evidence (Docker Compose / Chromium)` reported
**`failure`**, and `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)` had not finished
(`in_progress`) when `CI Green` concluded — yet `CI Green` still reported `success`, because **neither
job is in its `needs` list**. This shows the required context is blind to at least one lane that
actually went red on this very PR, independent of anything Phase 143 injected. Scoped to Phase 144
(TRUTH-02/CONFORM-02 territory), not fixed here.

**Mitigations, ranked:**

- **PRIMARY (out of scope for Phase 143 — routed to Phase 144).** Add a `ci.yml` lane that runs the
  root `mix test` over `test/` and add it to `ci_green.needs` (or otherwise make an existing required
  lane reach `test/gate_self_test/` and feed the aggregate). This is a CI topology change — widening
  `ci.yml`'s test coverage and/or its `needs` list — which Phase 143 is explicitly forbidden from
  making (`.planning/phases/143-test-harness-truth/143-CONTEXT.md` D-18a: "Record this finding and
  verify it live; do NOT fix `ci.yml` coverage here — that is a topology change this phase is
  forbidden."). Phase 144 should also separately consider whether `Demo Browser Evidence` and
  `Operator Browser Gate` belong in `ci_green.needs` (the second gap above).
- **Available today, non-vacuous, but requires the lane to exist and be green first.** Phase 143 plan
  02 (this plan) widened `gate-self-test.yml` with `required_only=false` and `deadline_minutes`, so
  once Phase 143's `Core Full Suite` lane is renamed and reachable (HARNESS-03/HARNESS-04), the probe
  can be dispatched against it directly — `Core Full Suite` runs the root `mix test` and so is a
  genuine target. That dispatch is plan `143-12`'s job, not this one. (Incidental corroboration: the
  same synthetic-failure PR's `advisory-matrix.yml` push-triggered run,
  [`30482357115`](https://github.com/szTheory/mailglass/actions/runs/30482357115), independently shows
  both 1.18/OTP 27 `Core Full Suite Advisory` legs going `failure` on the same injected test — see
  `143-PROBE-EVIDENCE.md`'s "Bonus incidental observation" section. This is suggestive, not the
  required `required_only=false` probe evidence, and must not be cited as satisfying it.)

**Status:** open, routed to Phase 144.

**Live recurrence risk:** any future addition of a new required root-project `ci.yml` lane must be
checked against whether it (a) now reaches `test/gate_self_test/` and (b) is added to `ci_green.needs`
— both conditions are required, since a lane that runs the suite but isn't in `needs` would leave this
defect exactly as open as it is today. If both land, this defect is auto-resolved and this entry should
be marked closed with the resolving commit cited.
