# Phase 167: Truthful Documentation and the Standing Control - Research

**Researched:** 2026-09-17/18
**Domain:** Documentation truth-maintenance (self-referential drift-guards) + Dependabot config
**Confidence:** HIGH (every claim below was read at HEAD this session; no claim in this file is carried from the milestone's original research without re-verification)

## Summary

Phase 167 is a verification-and-pinning task, not a design task. All six DOCS-0X requirement
prompts were checked against the live tree (2026-09-18). Most cited line numbers are still exact.
Two defects are **already better than the requirement text assumes** and must not be "fixed" as
originally described (`guides/upgrading-to-v2_0.md` already exists; `docs_contract_test.exs`
already passes green today). Two defects are exactly as described. One (DOCS-04) is a currently
**passing but fragile** lockstep — not a red test, a landmine. One (STAND-01) needs the full
`groups:` YAML written from scratch — nothing exists yet in `dependabot.yml` beyond bare weekly
schedules.

**Primary recommendation:** Treat this phase as one PR with two review passes — (1) a
docs-and-config-only pass covering DOCS-01/02/03/06/STAND-01 (pure text/YAML, zero product-code
risk), and (2) a narrowly-scoped code pass covering DOCS-04 (test regex → dynamic assertion) and
DOCS-05 (the single permitted `lib/` change: reject `css_inliner: :none` at validation, plus two
moduledoc corrections). Pin every correction with the idiom the repo already uses for that class of
claim — dynamic `dependency_constraint!`-style assertions for versions, `refute ... =~` /
`assert ... =~` source-text pins for prose claims, and a NimbleOptions type change + inverted unit
test for the config-key correction. Do not invent a new pinning mechanism; extend the two that
already exist (`test/mailglass/docs_contract_test.exs`, and the `mailable_test.exs` AST-reading
idiom).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| STATE.md truth correction | Docs/planning tier | — | Prose-only; `.planning/` is GSD-owned, corrected via a `docs(state):` commit per CLAUDE.md's own carve-out |
| CLAUDE.md / CONTRIBUTING.md / MAINTAINING.md truth correction | Docs tier | CI (drift-guard tests) | Prose read by humans and by Claude Code itself; pinned by `test/mailglass/docs_contract_test.exs`-style source-text assertions |
| guides/*.md version claims | Docs tier | Release automation (release-please.yml sed step) | Currently proofread-only; DOCS-04 moves this to the generated tier (sed sync + dynamic test) |
| `css_inliner: :none` config key | Library/Core (`lib/mailglass/config.ex`) | Test tier | The only in-scope `lib/` change; a NimbleOptions schema edit, not a renderer behavior change |
| `docs/api_stability.md` injected-forms list | Docs tier | Test tier (mirror `mailable_test.exs`) | Public API contract doc; must match the macro's actual AST, already has a sibling structural test to imitate |
| `.github/dependabot.yml` | CI/infra config tier | — | Pure YAML; GitHub-native grouping, no code |

## Standing Control Architecture — STAND-01 Data Flow

```
 dependabot.yml (per directory: /, /mailglass_admin, /mailglass_inbound)
        │
        ▼
 GitHub Dependabot scanner (weekly cron, GitHub-hosted — not this repo's CI)
        │
        ├─ major bump found ──────────────► individual PR (ungrouped, always reviewable alone)
        │
        └─ minor/patch bump(s) found ─────► single grouped PR per directory
                                                    │
                                                    ▼
                                          ci.yml "Detect Non-Doc Changes"
                                          (mix.lock changes are NON-doc →
                                           code=true → full matrix runs)
                                                    │
                                                    ▼
                                          required lanes (Core Full Suite,
                                          Core Deterministic Suite, etc.)
                                                    │
                                          ┌─────────┴─────────┐
                                          ▼                   ▼
                                       green                 red
                                  (mergeable, no            (drop the culprit
                                   hand edits)                via per-group
                                                               `ignore:`, re-run —
                                                               do NOT ungroup)
```

## Defect Ledger

Every row was verified by reading the file at HEAD (commit range around `73d7637d`, 2026-09-18).
"Still broken?" answers the literal question "does the defect exist right now," independent of
whether the requirement text's line numbers were exact.

| Req | File | Current line(s) | Current exact text | Corrected text (recommended) | Still broken at HEAD? |
|---|---|---|---|---|---|
| DOCS-01 | `.planning/STATE.md` | 33-36 (note), 103-107, 116, 128, 250, 369-370, 391-402 | See full quotes below | Truthed-up prose reflecting 0 open issues, 1 open PR (**#280**, `chore: release main`, currently red), #222 and #129 both closed, InboundLiveTest fixed | **Yes** — but the underlying facts have moved again since REQUIREMENTS.md was authored (see Landmines) |
| DOCS-02 | `CLAUDE.md` | 13 | `` — **`mailglass_inbound`** — Action Mailbox equivalent (opened v1.1; now on its own stable `1.0` contract — see `mailglass_inbound/docs/api_stability.md`) `` | Verified accurate — `mailglass_inbound/docs/api_stability.md` line 6 self-describes "## Current v2.6 Additive Contract" and the package's own contract doc, so "stable `1.0` contract" undersells but does not falsify; see note below | **Partially** — not requirement-blocking on its own, see notes |
| DOCS-02 | `CLAUDE.md` | 56 | `` - **Sibling packages with linked-version releases.** Release Please with `separate-pull-requests: false` + linked-versions plugin. `mailglass_admin/mix.exs` declares `{:mailglass, "== <version>"}`. `` | Replace `{:mailglass, "== <version>"}` with `{:mailglass, "~> <core-major.minor>"}`, matching line 24's own statement that exact pins are stale since Phase 125 | **Yes** — directly self-contradicts line 24 of the same file |
| DOCS-02 | `CLAUDE.md` | 119 | `` A Release Please PR auto-merges on green (see `release-please.yml` "Arm auto-merge") `` | The step itself now says: `"Disarmed ordinary auto-merge; a later protected exact candidate-digest dispatch is required."` (`.github/workflows/release-please.yml:904`, inside the `Arm auto-merge on the release PR` step, line 898). Reword to state auto-merge is disarmed and a protected dispatch step is required. | **Yes** |
| DOCS-03 | `CONTRIBUTING.md` | 186-190 | `` As of v1.15 Phase 125 the sibling packages use hand-maintained pessimistic `~>` constraints (`mailglass_inbound` uses `~> 1.10 and >= 1.10.2`, `mailglass_admin` uses `~> 1.10`). A core **patch** release requires no sibling change at all. A core **minor** (e.g. 1.11.0) requires a deliberate `fix(inbound):` commit in `mailglass_inbound/mix.exs` updating the floor `` | Current sibling constraints are bare `{:mailglass, "~> 2.0"}` (both `mailglass_admin/mix.exs:151` and `mailglass_inbound/mix.exs:149` — verified `[VERIFIED: mailglass_admin/mix.exs:151, mailglass_inbound/mix.exs:149]`), no explicit `>= floor`. A core minor bump (e.g. 2.1.0, 2.7.0) is satisfied by `~> 2.0` with **no** sibling `mix.exs` edit required — only a core **major** would. Rewrite to describe the current bare-`~>` reality and retire the `fix(inbound):` floor-bump instruction. | **Yes** |
| DOCS-03 | `MAINTAINING.md` | 137 | `` every non-excluded path, and the twelve `exclude-paths` entries (`#263`) narrow `` | `release-please-config.json:9` core `exclude-paths` array has **14** entries: `.github, .gitignore, .gsd, .planning, brandbook, ci, dev, mailglass_admin, mailglass_inbound, prompts, reference, scripts, test, test_js` `[VERIFIED: release-please-config.json:9]` | **Yes** — "twelve" should be "fourteen" |
| DOCS-03 | `MAINTAINING.md` | 631, 662 | `` 3. **Monitor the hands-free publish fan-out.** `` / `` It is **dispatch-only and inert on the `release` event** — the hands-free path can never self-skip its own gate. `` | `.github/workflows/publish-hex.yml` has **three** separate `environment: hex-publish` job blocks (lines 979, 1057, 1164 `[VERIFIED: .github/workflows/publish-hex.yml:979,1057,1164]`), and CLAUDE.md:119 itself already documents "three approvals on a linked core+admin+inbound release." "Hands-free" is the wrong word for a stage with 3 manual `required_reviewers` stops; reword to "the publish fan-out still requires one manual approval per package (3 stops for a linked release) — 'hands-free' describes everything up to that gate, not past it." | **Yes** — internally contradicts CLAUDE.md:119 which is more accurate |
| DOCS-03 | `MAINTAINING.md` | none (missing) | (no close-out section exists — `grep -n "release_policy_close_out\|close-out"` returns exactly one unrelated historical mention at line 179) | New `## Release Close-Out` section (see notes below) | **Yes** — section does not exist |
| DOCS-04 | `guides/migration-from-swoosh.md` | 31-32 | `` {:mailglass, "~> 2.5"}, {:mailglass_admin, "~> 2.5"} `` | Convert to a dynamic assertion pattern (see DOCS-04 notes) — the literal text does not need to change today (2.6.0 satisfies `~> 2.5`), only the *mechanism* that keeps it true does | **No** (not currently false — `~> 2.5` still matches published 2.6.0) — but it is a **landmine**, not a green light to skip |
| DOCS-04 | `test/mailglass/docs_contract_test.exs` | 557-558 | `` assert migration =~ ~r/~>\s*2\.5/, "migration-from-swoosh.md must pin the current ~> 2.5 series" `` | Replace the hardcoded `~r/~>\s*2\.5/` with a dynamic comparison against `package_major_minor!("mix.exs")`, mirroring the README contract test at lines 16-26 of the same file | **No** (currently green — `mix test test/mailglass/docs_contract_test.exs` passes: 49 tests, 0 failures, 1 skipped, verified this session) |
| DOCS-04 | `guides/compatibility-and-deprecations.md` | 209-210 | `- local development uses the repo path dependency` / `- published builds pin the exact sibling version` | `mailglass_admin/mix.exs:151` and `mailglass_inbound/mix.exs:149` both use `{:mailglass, "~> 2.0"}` — NOT an exact pin. Rewrite to "published builds pin the sibling's current major.minor with `~>`" | **Yes** |
| DOCS-05 (i) | `lib/mailglass/config.ex` | 84-88 | ```elixir\ncss_inliner: [\n  type: {:in, [:premailex, :none]},\n  default: :premailex,\n  doc: "CSS inlining backend. Default: `:premailex`."\n]\n``` | Recommend: narrow `type:` to `{:in, [:premailex]}` (reject `:none` at validation) — see disposition rationale below | **Yes** — `:none` validates but has zero effect |
| DOCS-05 (i) | `lib/mailglass/renderer.ex` | 238-239 | `` defp inline_css(html) when is_binary(html) do\n    inlined = Premailex.to_inline_css(html) `` | No behavior change needed once `:none` is rejected at validation — `inline_css/1` is correctly always-Premailex once `:none` cannot reach it | **N/A once (i) resolved by rejection** |
| DOCS-05 (ii) | `lib/mailglass/outbound.ex` | 47-50 | `` **Adapter-call-in-transaction is a hard no** — Postgres connection-pool starvation under provider latency. Orphan `:queued` Delivery rows between Multi#1 and adapter call are reconcilable via `Mailglass.Events.Reconciler` with age >= 5min. `` | `Mailglass.Events.Reconciler.find_orphans/1` (`lib/mailglass/events/reconciler.ex:58-73`) queries **orphan webhook `Event` rows** (`needs_reconciliation == true and is_nil(delivery_id)`), a different orphan class from a stuck `:queued` `Delivery` row with no matching event at all. There is **no** reconciliation mechanism in the codebase for a `Delivery` stuck at `:queued` with no webhook event (verified: no hits for "stale queued"/"orphan sweep" on Delivery in `lib/`). Correct the moduledoc to state this class is **not currently reconciled** (operational risk note), not that it is | **Yes** — factually wrong mechanism named |
| DOCS-05 (iii) | `docs/api_stability.md` | 1114-1122 | ``` 1. `@behaviour Mailglass.Mailable`\n2. `@before_compile Mailglass.Mailable`\n3. `@mailglass_opts opts`\n4. `@compile {:no_warn_undefined, Mailglass.Outbound}` (forward-ref guard until Plan 05)\n5. `import Swoosh.Email, except: [new: 0]`\n6. `import Mailglass.Components`\n7. `def __mailglass_opts__/0`\n8. `def new/0`\n9. `def render/3`\n10. `def deliver/2`\n11. `def deliver_later/2`\n12. `defoverridable new: 0, render: 3, deliver: 2, deliver_later: 2` ``` | Items 5, 8, 12 are wrong. Actual (`lib/mailglass/mailable.ex:124-157`, `[VERIFIED]`, quoted verbatim below): item 5 is `import Mailglass.Message, only: [to: 2, from: 2, subject: 2, html_body: 2, text_body: 2, header: 3, attach: 2, put_tag: 2]`; item 8 is `def new(assigns \\ [])` (defines both `new/0` and `new/1`); item 12 is `defoverridable new: 0, new: 1, render: 3, deliver: 2, deliver_later: 2` | **Yes** — item 5 names a module (`Swoosh.Email`) that is never imported by `__using__/1` |
| DOCS-06 | `README.md` | 275-289 (the "Where to Look next" learning-path list) | Links `guides/upgrading-to-v1_0.md` and `guides/upgrading-from-v0_1.md`, does **not** link `guides/upgrading-to-v2_0.md` | Add a bullet linking `guides/upgrading-to-v2_0.md` | **Yes, but narrower than described** — the guide **already exists on disk** (`guides/upgrading-to-v2_0.md`, confirmed present via `ls guides/`). This is a missing-link defect, not a missing-file defect. Do not create a new guide. |
| DOCS-06 | `CHANGELOG.md` | 169-173 | ``` ## [2.0.0](...) (2026-07-04)\n\n### ⚠ BREAKING CHANGES\n\n* **release:** marker is banked in 132-136, so release-please would otherwise cut 1.12.0/1.12.0. This root mix.exs touch attributes the footer below to the linked group (core exclude-paths keep admin/inbound out of `.`). ``` | Append or replace with a line naming the real breaking change: the Postgres schema-isolation move (v2.0 = Phases 132-137, `metadata jsonb`/non-public-schema migration; see `.planning/milestones/` v2.0 records and STATE.md's `[Phase ?]` schema-isolation bullets for the authoritative wording) | **Yes** — the only BREAKING CHANGES bullet is a release-tooling footnote, not adopter-facing |

### DOCS-01 — STATE.md verbatim source quotes (for the corrections above)

Read this session, `[VERIFIED: .planning/STATE.md]`:

- L33-36 (already a maintainer note, itself in need of updating): `> since gone stale — notably ## Operator Next Steps, which still describes two InboundLiveTest reds as undiagnosed (fixed in f733fc22/d65a1aa8), PR #222 as open (closed), and 14 open PRs (now zero).`
- L103-107: `` `repo-hygiene` → `blocked` / "14 open PR(s) require disposition before release"; `post-publish-smoke` → `blocked` / `scheduled_target_not_published` (PR #222 is an authorized-but-unpublished target); `release-please` → `blocked` / `proposal_identity_mismatch` (the same open #222 proposal). ``
- L128: `Repository hygiene remains policy-blocked by 14 open PRs as accepted operational debt.`
- L391-393: `v2.7 needs nothing further. The accepted-debt PR count is now 1, not 14, but 165-FINALIZATION.md §6–7 stays closed out: the remaining PR (#222) still fails repo-hygiene, and both post-publish-smoke and release-please block specifically on it.`
- L396-397: `Decide #222 chore: release main — it would cut mailglass 2.6.0 / mailglass_inbound 2.3.0 to Hex. Currently red (Core Full Suite + CI Green) and BEHIND.`
- L401-403: `Two pre-existing reds on main in MailglassAdmin.InboundLiveTest (replay flash copy, inbound_live_test.exs:913 and :1411) are undiagnosed. Likely coupled to the unmerged PR #129 replay-copy redesign.`

**Ground truth verified live this session** (`gh pr list --state open`, `gh issue list --state open`, 2026-09-18):
- `gh issue list --state open` → **0 open issues**.
- `gh pr list --state open` → **1 open PR: #280, "chore: release main"**, branch `release-please--branches--main`, opened 2026-09-17T20:30:43Z. This is a **different** PR than #222 (#222 is CLOSED, confirmed via `gh pr view 222` → `{"state":"CLOSED"}`). #280 is currently **RED**: `Core Full Suite (schema public)` FAILURE, `Core Full Suite (schema mailglass)` FAILURE, `Mix Task Tests` FAILURE, `Core Deterministic Suite` FAILURE, `CI Green` FAILURE (checked via `gh pr view 280 --json statusCheckRollup`).
- `gh pr view 129` → `{"state":"CLOSED"}`.
- `f733fc22` (`test(admin): seed durable replay route binding in InboundFixtures (#262)`, 2026-09-16) and `d65a1aa8` (`fix(admin): name the real cause when a pre-2.2.0 inbound message cannot be replayed (#268)`, 2026-09-16) are both real, merged commits on `main` — the InboundLiveTest reds are fixed.

**This means the requirement's own "14 open PRs / #222 open" framing is already one generation stale relative to HEAD** — the *real* current defect in STATE.md is references to the old #222/14-count debt, and the *real* current fact is a *new*, different, currently-red PR #280. See Landmines section — do not hardcode "#280 is red" as a permanent fact in STATE.md's correction; by the time this phase executes, #280 may be green, merged, or replaced by a new release-please proposal.

## Per-Requirement Implementation Notes

### DOCS-01 — STATE.md

STATE.md is GSD machine-managed (`docs(state):` commit type, "never edit by hand" per CLAUDE.md's
own Commit & Branch Conventions section). Two things follow:

1. **The one-time prose correction is legitimate and expected** — CLAUDE.md's "never edit by hand"
   guidance exists to stop ad-hoc edits that fight the GSD state machine during ordinary phase work,
   not to forbid a requirement whose entire purpose is correcting STATE.md prose. Do the edit, commit
   it with `docs(state): correct stale PR/issue references and fixed-test claims` (or let the
   phase's own executor produce this commit naturally — GSD phase execution already writes
   `docs(state):`-typed commits for STATE.md updates).
2. **No existing test/script asserts STATE.md prose against live `gh` state.** Searched
   `test/**/*state*`, `scripts/*state*`, workflow files — zero hits that validate STATE.md content
   against GitHub. A rigid content-match test is a poor fit anyway: STATE.md's "Accumulated Context"
   grows every phase (GSD appends new `[Phase N]:` bullets on every run), so a snapshot-style test
   would go red on the next unrelated phase's own routine update.

**Recommendation:** Pin this with a **generated, advisory-lane check**, not a blocking unit test —
mirroring `repo-hygiene`'s own pattern (a script that queries live GitHub state and reports
pass/fail, run on a schedule, non-blocking on ordinary PRs). Concretely: a small script
(`scripts/check_state_md_pr_refs.sh` or a `mix mailglass.state.audit` task) that:
- Extracts every `#NNN` reference from `.planning/STATE.md`.
- For each, calls `gh pr view NNN --json state` (or `gh issue view`).
- Fails (or warns) if a referenced number is described as "open" in STATE.md prose but is actually
  closed, or vice versa.
This is exactly the "generated, not merely proofread" mechanism the milestone stop line demands,
without fighting GSD's ownership of STATE.md's structural/frontmatter fields, and without producing
a test that is guaranteed to go red on the next routine phase.

### DOCS-02 — CLAUDE.md

Three corrections, all isolated one-liners in a single file:
- Line 56 (`{:mailglass, "== <version>"}` → `{:mailglass, "~> <major.minor>"}`) — this is the one
  genuinely **internally contradictory** claim (contradicts CLAUDE.md:24 in the same document,
  confirmed: line 24 reads `Sibling pins are **no longer exact**. Since v1.15 Phase 125 the packages
  carry ~> and the Release Please linked-versions plugin locks the minor at release time... Any doc
  describing a {:mailglass, "== <core>"} re-pin dance is stale.` — line 56 is that exact stale
  pattern, inside the same file that disclaims it).
- Line 119 (auto-merge claim) — reword using the real step text quoted verbatim at
  `.github/workflows/release-please.yml:904`: `"Disarmed ordinary auto-merge; a later protected exact
  candidate-digest dispatch is required."` Do not merely delete the auto-merge sentence — explain
  the real mechanism (a human dispatches a protected exact-digest step) so a maintainer isn't left
  wondering what replaces auto-merge.
- Line 15 (inbound "stable `1.0` contract") — **this one is defensible, not clearly false.**
  `mailglass_inbound/docs/api_stability.md` is genuinely the canonical contract inventory and does
  describe a stable, versioned contract (currently "v2.6 Additive Contract" heading, meaning stable
  as of the v2.6 line, with "Active v2 deprecations: none"). "Stable `1.0` contract" is shorthand for
  "semver-stable / contract-frozen since inbound's 1.0," which is accurate in spirit — inbound has
  never had a breaking removal. Recommend leaving this line as-is, or softening "stable `1.0`
  contract" to "stable contract (semver-honored since 1.0)" for precision, but do **not** spend a
  pinning test on this one — it is not a falsifiable claim in the same way the other two are.

**Pinning:** three `refute CLAUDE.md =~ "== <version>"` / positive `assert CLAUDE.md =~ "~>"` -style
assertions in a new `describe "CLAUDE.md contract"` block inside `docs_contract_test.exs`, following
the exact idiom already used for `migration-from-swoosh.md` (lines 552-558).

### DOCS-03 — CONTRIBUTING.md / MAINTAINING.md

- CONTRIBUTING.md fix: rewrite the `fix(inbound):` floor-bump paragraph to describe the actual
  current mechanism (bare `~> 2.0`, no explicit floor, no mandatory sibling commit on a core minor).
  Pin with a `refute contributing =~ "fix(inbound):"` guard scoped to that paragraph (there is one
  legitimate, unrelated `fix(inbound):` example commit message earlier in the file at line 161 — a
  blanket `refute` would false-positive; scope the assertion to the specific sentence, e.g. `refute
  contributing =~ "requires a deliberate `fix(inbound):` commit"`).
- MAINTAINING.md "twelve" → "fourteen": `refute maintaining =~ "twelve `exclude-paths`"` /
  `assert maintaining =~ "fourteen `exclude-paths`"`. **Better pin:** don't hardcode "fourteen" as a
  literal either — read `release-please-config.json`'s `.["."]["exclude-paths"]` length at test time
  and assert the prose number matches it, the same self-sustaining pattern recommended for DOCS-04.
  This is the single highest-value generated pin in the whole phase, since the exclude-paths count
  is exactly the kind of number that silently drifts on every future `#26x`-style widening PR.
- MAINTAINING.md "hands-free" reword: pin with `refute maintaining =~ "hands-free publish fan-out"`
  (the exact defective phrase) combined with a positive assertion that the corrected text mentions
  "three" and "`required_reviewers`" or "approval."
- **New MAINTAINING.md close-out section — required content** (verified this session by reading the
  actual scripts, not inferred):
  - The ledger state machine: `inactive → captured → authorized → published → completed → inactive`
    (already documented at CLAUDE.md:21, reuse that wording for consistency).
  - `scripts/release_policy.exs` has a `close-out` CLI verb: `[VERIFIED: scripts/release_policy.exs:444]`
    `def cli(["close-out", target_path, tag_sha, checksums_path]) do`.
  - `scripts/release_policy_close_out.sh` is the operator-facing wrapper.
    `[VERIFIED: scripts/release_policy_close_out.sh:1-45]` — usage:
    `release_policy_close_out.sh [--target PATH] [--repo PATH] [--write]`. It requires
    `.planning/release-target.json`'s `status` to be one of `authorized | published | completed`
    (line 37-40 of the script: `case "$status" in authorized | published | completed) ;; *) fail ...
    esac`), and re-verifies live Hex checksums before writing.
  - `scripts/check_published_baseline_of_record.sh` is invoked from inside the close-out script at
    `[VERIFIED: scripts/release_policy_close_out.sh:110]` — this is the guard that fails the ledger
    write loudly if the four published-baseline records disagree, added per PR #279 (per STATE.md
    memory — do not re-verify #279 itself, but do verify the wiring line, which was done here).
  - Acceptance bar per the requirement: "a reader who has never seen the ledger can complete
    close-out from MAINTAINING.md alone" — write it as a numbered runbook: (1) confirm
    `.planning/release-target.json` status is `published`/`completed`, (2) run
    `scripts/release_policy_close_out.sh --write`, (3) confirm ledger status returned to `inactive`
    and `baselines` advanced, (4) commit the ledger change as its own reviewed PR (per CLAUDE.md's
    "ledger edits are their own reviewed PR" rule — do not fold a ledger close-out into this phase's
    docs PR).

### DOCS-04 — the landmine, decisive disposition

**Current state is NOT red.** `mix test test/mailglass/docs_contract_test.exs` passes today (49
tests, 0 failures, 1 skipped — verified this session with the correct toolchain env:
`ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`). The guide's `~> 2.5` and the
test's `~r/~>\s*2\.5/` currently agree, and both are still technically true against the live
published core version 2.6.0 (`~> 2.5` in Hex/Elixir version-requirement syntax means `>= 2.5.0 and
< 3.0.0` for a two-segment requirement, so 2.6.0 satisfies it). **Do not treat this as a live red to
fix** — treat it as the structural landmine the requirement names it: the moment core crosses into
3.0 (or any maintainer decides to bump the guide's floor sooner), the hardcoded literal in both
files must move together, in the same commit, or the milestone's own DOCS-04 acceptance ("no guide
asserts a version the tree disproves") becomes false again on the very next release.

**Two dispositions, decisive recommendation:**

(a) *Move both literals together forever.* Cheap today, but reproduces exactly the Phase 125
pin-drift failure mode the requirement explicitly warns about — a human has to remember, on every
future core-minor decision to bump guide floors, to touch two files in lockstep. This is a
proofread-and-hope mechanism, which the milestone stop line explicitly disqualifies ("each
correction must be pinned by a test or generated, not merely proofread").

(b) *Bring the guide under generated sync.* **Recommended.** Important correction to the original
requirement's framing: **this repo has no release-please `extra-files` / `x-release-please-version`
marker mechanism at all** — `release-please-config.json` was read in full this session and contains
no `extra-files` key. The actual "README-sync" the requirement is pointing at is a **custom sed
step already living inside `.github/workflows/release-please.yml` (lines 400-490)**, which today
resyncs `{:mailglass, "~> X.Y"}` / `{:mailglass_admin, "~> X.Y"}` pins in `README.md`,
`mailglass_admin/README.md`, `mailglass_inbound/README.md`, and
`mailglass_inbound/docs/inbound-install.md` on every release-please proposal, using generic regex
`s/\{:mailglass, "~> [0-9]+\.[0-9]+"/{:mailglass, "~> ${CORE_MM}"/`. This regex is generic enough
that adding `guides/migration-from-swoosh.md` to the `for readme in ...` loop at line 439 and the
`SYNC_PATHS` array is a **~3-line addition to an existing, already-tested job**, not new
infrastructure.

The harder half of (b): the *test* side must also stop being a hardcoded literal, mirroring the
existing README contract test (`docs_contract_test.exs:14-26`), which reads `core_version =
package_major_minor!("mix.exs")` and asserts the doc's pin equals it **dynamically** — never a
literal version string. Replace lines 557-558's `assert migration =~ ~r/~>\s*2\.5/` with the same
`dependency_constraint!`/`package_major_minor!` helper pattern already defined at the bottom of the
same test file (`defp current_compatibility_section!` at line 1062, `defp dependency_constraint!` at
line 1069) — reuse those helpers on the guide's dep block instead of inventing new ones.

**Net effect:** after (b), the guide's pin is generated at release time (never manually edited
again) and the test asserts it dynamically (never goes stale on a future core bump). This is a
strictly better outcome than (a) for the same or less code, and it is exactly the "generated, not
merely proofread" instruction applied literally. **Decisive recommendation: (b).**

`guides/compatibility-and-deprecations.md:209-210`'s "published builds pin the exact sibling
version" is a separate, simpler correction — no lockstep risk, just a wrong adjective (`exact` →
`current major.minor via ~>`), pinned the same `refute .. =~ "exact sibling version"` way as the
other prose corrections.

### DOCS-05 — decisive dispositions

**(i) `css_inliner: :none` — RECOMMENDATION: REJECT, not honor.**

Evidence gathered this session:
- `config.ex:84-88` accepts `:none` via `type: {:in, [:premailex, :none]}`, default `:premailex`.
- `renderer.ex:238-239`'s `inline_css/1` unconditionally calls `Premailex.to_inline_css(html)` —
  never reads the `:renderer` config subtree at all. `render/2` (line 63-83) never threads config
  into `inline_css/1`.
- `test/mailglass/config_test.exs:17-21` already asserts `:none` is *accepted and stored* — but
  no test anywhere asserts it changes rendering behavior (grepped `test/` for `css_inliner` —
  only the one config-validation test exists).
- Grepped every doc, guide, and README for `css_inliner` — **zero hits outside `lib/mailglass/config.ex`
  and `test/mailglass/config_test.exs`.** No adopter-facing guide, README, or CHANGELOG entry has
  ever promised `:none` skips Premailex. This is not a documented public contract being broken by a
  fix; it is dead validation surface nobody depends on.

Rationale for REJECT over HONOR:
1. **Scope discipline.** The milestone explicitly frames this as "the single permitted `lib/`
   change" and explicitly pre-authorizes the reject disposition in its own text ("it may legitimately
   be resolved by rejecting the `css_inliner` key at validation rather than implementing it" —
   ROADMAP.md:233-234, REQUIREMENTS.md Out of Scope table). Honoring the key requires a genuine
   behavior change to `renderer.ex` (threading config through `render/2` → `inline_css/1`), which is
   a materially larger, riskier diff for a 5-day, docs-focused, CI-heavy timebox already carrying
   17 requirements.
2. **No regression risk.** Nothing currently relies on `:none` skipping inlining (zero adopter-facing
   documentation), so rejecting it cannot break any documented adopter workflow.
3. **Matches the project's error-contract convention.** `%Mailglass.Error{}` uses a closed `:type`
   atom set and NimbleOptions raises `ValidationError` for unsupported values elsewhere in the same
   schema (`config_test.exs:30-34` already tests this exact pattern for `:invalid_backend`) — REJECT
   is the idiomatic mailglass way to close an inert option, not a workaround.

**Implementation:** narrow `config.ex:85` from `type: {:in, [:premailex, :none]}` to
`type: {:in, [:premailex]}`. **Pin:** invert `config_test.exs:17-21` — instead of asserting `:none`
is accepted, assert `Mailglass.Config.new!(renderer: [css_inliner: :none])` raises
`NimbleOptions.ValidationError`, mirroring the adjacent `:invalid_backend` test at lines 30-34.

**(ii) outbound.ex moduledoc** — correct per Defect Ledger row above. No code change; this is a pure
documentation-accuracy fix (the moduledoc describes behavior that was never built, not behavior that
regressed). Recommend the corrected text explicitly flag the gap as an operational fact rather than
silently deleting the sentence: e.g. "Orphan `:queued` Delivery rows between Multi#1 and the adapter
call are **not currently auto-reconciled**; `Mailglass.Events.Reconciler` only resolves orphan
webhook *events*, a distinct failure class. A stuck `:queued` row today requires manual operator
intervention." — this keeps the "no PII / errors as public contract" spirit by being precise about
what does and does not happen, rather than just removing the false claim and leaving a documentation
gap.

**(iii) api_stability.md:1119** — correct per Defect Ledger row above, verbatim quotes already
extracted from `mailable.ex:124-157` `[VERIFIED]`. **Pin:** extend the AST-reading idiom already
proven in `test/mailglass/mailable_test.exs:74-118` (which parses `lib/mailglass/mailable.ex` via
`Code.string_to_quoted` and asserts function existence) — add a companion assertion (either in that
same test file or a new block in `docs_contract_test.exs`) that reads `docs/api_stability.md` and
`refute`s the stale string `import Swoosh.Email, except: [new: 0]` while `assert`ing the correct
`import Mailglass.Message, only: [to: 2` substring is present. This is a source-text pin, not a
full re-derivation — full dynamic AST-to-prose generation is out of scope for a docs-correctness
phase.

### DOCS-06 — README.md / CHANGELOG.md

`guides/upgrading-to-v2_0.md` **already exists** — this is purely a missing-link defect in the
"Where to Look next" list (`README.md:275-289`). Add one bullet in the same style as the surrounding
entries, placed logically near `upgrading-to-v1_0.md` (chronological/version order). **Pin:** extend
`docs_contract_test.exs`'s existing `"guides/learning-path.md does not exist on disk"`-style pattern
(visible at line 515 of the file read this session) — add an assertion that every `guides/*.md` file
on disk that matches an `upgrading-*` naming convention is linked somewhere in README.md, so a
*future* upgrade guide can't silently go unlinked either (this generalizes past just fixing today's
gap, which is the point of "generated, not merely proofread").

CHANGELOG.md's 2.0.0 BREAKING CHANGES block: this is git-history / already-published changelog text.
**Do not rewrite history** — CHANGELOG.md is generated by release-please from commit messages and
is also explicitly called out in REQUIREMENTS.md's Out of Scope table ("Rewriting historical `==` /
'hands-free' claims would falsify history" — same principle applies here). Recommend **appending** a
clarifying line immediately after the existing bullet (not replacing it), e.g.: "**Note (added
2026-09, Phase 167):** the substantive breaking change in this release was the PostgreSQL
schema-isolation move (Phases 132-137, `mailglass_events`/`mailglass_deliveries` etc. relocated out
of the `public` schema; see `.planings/milestones/` v2.0 records) — the bullet above only documents
release-tooling bookkeeping, not the adopter-facing migration." Pin with a source-text `assert` that
the schema-isolation note is present near the 2.0.0 heading; do not `refute` or delete the original
release-please-generated text.

## Pinning Strategy — mechanism per defect class

| Defect class | Existing mechanism to reuse | Concrete file/idiom | New mechanism needed? |
|---|---|---|---|
| Version claim in a guide/README that must track a package's current version | `dependency_constraint!` / `package_major_minor!` / `current_compatibility_section!` helpers, `docs_contract_test.exs:16-55` | Add `guides/migration-from-swoosh.md` as a 4th document alongside README.md/admin README/inbound README in the same describe block | No — reuse verbatim |
| One-off wrong prose/number claim (e.g. "twelve", "hands-free", "== <version>") | `assert`/`refute ... =~` source-text idiom, `docs_contract_test.exs:552-558` (already used for stale-pin guards) | New `describe` blocks per target file (`CLAUDE.md contract`, `CONTRIBUTING.md contract`, `MAINTAINING.md contract`) inside `docs_contract_test.exs` | No — reuse verbatim; consider making the "fourteen" claim a generated comparison against `release-please-config.json`'s actual array length (see DOCS-03 notes) rather than a second hardcoded literal |
| Inert/wrong config key | NimbleOptions schema + inverted unit test, `config_test.exs:17-34` | Narrow `type:`, flip lines 17-21 from accept-assertion to `assert_raise` | No — reuse verbatim (mirrors the adjacent `:invalid_backend` test) |
| Wrong `__using__/1` injected-forms description | AST-reading idiom, `mailable_test.exs:74-118` (`Code.string_to_quoted` + structural assertion) | Add a companion `refute .. =~ "import Swoosh.Email, except"` / `assert .. =~ "import Mailglass.Message, only"` in `docs_contract_test.exs` reading `docs/api_stability.md` | No — reuse the pattern, new assertion |
| STATE.md prose vs. live GitHub state | **None exists today** | New: a small script/mix task calling `gh pr view`/`gh issue view` per `#NNN` reference found in STATE.md, run as an advisory/scheduled lane (mirrors `repo-hygiene`'s own non-blocking pattern) | **Yes — new, narrowly scoped, advisory not blocking** |
| Missing README link for an existing guide | `docs_contract_test.exs`'s existing "guide exists on disk" pattern (line ~515) | Generalize: assert every `guides/upgrading-*.md` on disk is referenced somewhere in `README.md` | No — extend existing idiom |
| Dependabot grouping/limits | N/A (pure GitHub-native config, no repo-side test possible — GitHub's Dependabot scanner is not invokable from this repo's CI) | None — acceptance is behavioral over a week ("a week's bumps arrive as ≤1 PR per lock directory"), verified by observation, not a unit test | No mechanism possible; document this explicitly as an observation-only acceptance criterion, same shape as Phase 166's CTRL-0x "post-merge evidence pending" items |

## STAND-01 — exact YAML

Current `.github/dependabot.yml` in full (verified this session, byte-for-byte):

```yaml
version: 2
updates:
  - package-ecosystem: "mix"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "mix"
    directory: "/mailglass_admin"
    schedule:
      interval: "weekly"
  - package-ecosystem: "mix"
    directory: "/mailglass_inbound"
    schedule:
      interval: "weekly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "docker"
    directory: "/dev/toolchain"
    schedule:
      interval: "weekly"
  - package-ecosystem: "docker"
    directory: "/reference/demo_app"
    schedule:
      interval: "weekly"
```

**Confirmed: no `groups:`, no `open-pull-requests-limit`, weekly schedule already present on all 6
entries.** Only the three `mix` entries are in scope for STAND-01 (the requirement text says "Each
`mix` entry" — github-actions and docker entries are out of scope; do not touch them).

**`groups:` syntax** `[CITED: docs.github.com/en/code-security/dependabot]` (confirmed via
WebSearch against current GitHub Docs; exact syntax cross-checked against the "Optimizing the
creation of pull requests for Dependabot version updates" doc):

```yaml
groups:
  <group-name>:
    patterns:
      - "*"
    update-types:
      - "minor"
      - "patch"
    # exclude-patterns: ["<dep-name>"]   # per-dep drop without ungrouping a red group
```

- `patterns: ["*"]` groups every dependency in that directory into one PR.
- `update-types: ["minor", "patch"]` is what keeps majors **out** of the group — Dependabot only
  places updates matching the listed `update-types` into the group; a major-version bump that
  doesn't match `minor`/`patch` is raised as its own individual, ungrouped PR automatically. No
  separate "major" exclusion syntax is needed — omitting `"major"` from `update-types` is sufficient
  and is the documented mechanism.
- `exclude-patterns` can drop a single dependency out of a group by name/pattern — this is the
  mechanism the requirement's own "Counter-argument accepted" clause names for de-fanging a red
  group without ungrouping everything ("if a group reds, drop the culprit with `ignore` and re-run").
  Note the requirement text says `ignore`, but the group-scoped escape hatch is actually
  `exclude-patterns` inside the `groups:` block; top-level `ignore:` (outside `groups:`) is a
  separate, coarser mechanism that stops Dependabot from proposing updates for a dependency at all
  (any version). For "drop the culprit from this week's grouped PR, try again next week,"
  `exclude-patterns` is the correct, narrower tool; reserve `ignore:` for a dependency that should
  never auto-update (e.g. permanently pinned by policy).
- `open-pull-requests-limit: 3` is a per-`updates`-entry cap on concurrently open PRs from that
  directory, independent of `groups:` — set it once per entry.

**Recommended exact addition to each of the three `mix` entries:**

```yaml
  - package-ecosystem: "mix"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 3
    groups:
      mix-minor-patch:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"
  - package-ecosystem: "mix"
    directory: "/mailglass_admin"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 3
    groups:
      mix-minor-patch:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"
  - package-ecosystem: "mix"
    directory: "/mailglass_inbound"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 3
    groups:
      mix-minor-patch:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"
```

Leave the `github-actions` and `docker` entries untouched (out of scope per "Each `mix` entry").

**Fourth lock directory question — confirmed:** `reference/host_app/mix.exs` +
`reference/host_app/mix.lock` and `reference/demo_app/mix.exs` + `reference/demo_app/mix.lock` both
exist `[VERIFIED: ls output this session]`. Neither has a `mix`-ecosystem dependabot entry today
(only `reference/demo_app` has a `docker`-ecosystem entry, for its Dockerfile, not its mix deps).
**Do not add `mix` entries for either `reference/` directory.** Per project memory
(`project_demo_app_phoenix_advisory.md`, `project_reference_baseline_coupling.md`): these are
deliberately FROZEN deterministic baselines; bumping their pins is a coordinated 5-file change, and
letting Dependabot auto-propose bumps here would directly contradict that frozen-baseline design.
This absence is correct and should be left alone, not treated as a gap.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18.4-otp-27, per `.tool-versions`) |
| Config file | `mix.exs` (root), `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs` — no separate ExUnit config file |
| Quick run command | `export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 && mix test test/mailglass/docs_contract_test.exs test/mailglass/config_test.exs test/mailglass/mailable_test.exs` |
| Full suite command | `mix verify.support_contract.core` (root alias, `mix.exs:323-329`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-01 | STATE.md contains no claim contradicted by live GH state | generated script, advisory | new script (see Pinning Strategy) | ❌ new |
| DOCS-02 | CLAUDE.md release-pipeline claims match reality | unit (source-text) | `mix test test/mailglass/docs_contract_test.exs --only claude_md` (or a plain full run) | ❌ new describe block, existing test file |
| DOCS-03 | CONTRIBUTING.md / MAINTAINING.md corrected, close-out section present | unit (source-text) | same file, new describe blocks | ❌ new describe blocks |
| DOCS-04 | guide version claim dynamic, no drift | unit (dynamic assertion) | `mix test test/mailglass/docs_contract_test.exs` (extend existing README-contract test) | ✅ existing test extended |
| DOCS-05 | `css_inliner` rejected at validation; moduledocs corrected | unit | `mix test test/mailglass/config_test.exs test/mailglass/docs_contract_test.exs` | ✅ existing tests extended |
| DOCS-06 | upgrade guide linked, CHANGELOG note present | unit (source-text) | `mix test test/mailglass/docs_contract_test.exs` | ✅ existing test extended |
| STAND-01 | dependabot grouped, weekly, limit 3 | none automatable in-repo | manual YAML review + week-later observation | N/A — GitHub-native |

### Sampling Rate
- **Per task commit:** targeted `mix test test/mailglass/docs_contract_test.exs test/mailglass/config_test.exs test/mailglass/mailable_test.exs`
- **Per wave merge:** `mix verify.support_contract.core` (full core suite — this is the required
  `support_contract_core` CI lane already, confirmed at `ci.yml:224-225`)
- **Phase gate:** full suite green before `/gsd-verify-work`; additionally confirm `git diff` for
  the corrected files no longer matches any of the stale strings listed in the Defect Ledger
  (`grep` sweep as a final sanity check, matching exit criterion 6's own phrasing: "`grep` for the
  corrected doc claims returns nothing")

### Wave 0 Gaps
- [ ] New `describe "CLAUDE.md contract"` / `describe "CONTRIBUTING.md contract"` / `describe
  "MAINTAINING.md contract"` blocks in `test/mailglass/docs_contract_test.exs` — none exist yet for
  these three files (only README.md and the guides currently have contract tests).
- [ ] New script/task for DOCS-01's live-GitHub-state pin (`scripts/check_state_md_pr_refs.sh` or
  equivalent) — genuinely new infrastructure, the one item in this phase without a direct existing
  pattern to extend.
- [ ] Inverted `config_test.exs` case for `css_inliner: :none` (raise, not accept) — one-line flip
  of existing lines 17-21, not a net-new file.

*(Everything else reuses existing test files/idioms — this is a low-Wave-0-gap phase.)*

## Landmines and Lockstep Constraints

1. **DOCS-04 is a two-file lockstep** (`guides/migration-from-swoosh.md:31-32` +
   `docs_contract_test.exs:557-558`) — if disposition (b) is chosen (recommended), the *sync
   mechanism* (release-please.yml sed step) and the *test* (dynamic assertion) must both land in
   this phase's PR, or the phase leaves the guide un-generated while the test now expects dynamic
   behavior that doesn't exist yet. Land both in the same commit.

2. **DOCS-01's factual basis has already shifted once since REQUIREMENTS.md was authored on
   2026-09-17**, and it may shift again before this phase executes: PR #222 (named in the
   requirement) is closed and gone; a **new** PR #280 (`chore: release main`) opened 2026-09-17 and
   is currently **red**. Any STATE.md correction written during planning must either (a) be phrased
   to describe the *category* of fact ("N open PRs, see `gh pr list` for current state") rather than
   hardcoding a PR number and status that will go stale again within days, or (b) be re-verified via
   `gh pr list`/`gh issue list` immediately before the correcting commit lands, not sourced from this
   research document's snapshot. **Do not copy the "#280 is red" fact from this document into
   STATE.md verbatim without re-checking it at execution time.**

3. **DOCS-02's line-24-vs-line-56 contradiction must be resolved by making line 56 agree with line
   24, not the reverse** — line 24 is the more recently written, more detailed, and independently
   corroborated (matches `mailglass_admin/mix.exs:151` and `mailglass_inbound/mix.exs:149`'s actual
   `~>` pins) statement.

4. **DOCS-05(i)'s disposition (reject `:none`) is a genuine, if narrow, `lib/` behavior change** —
   any code calling `Mailglass.Config.new!(renderer: [css_inliner: :none])` today (none found in
   `lib/`, `test/`, or `reference/` this session) would start raising. Confirmed via grep this is
   currently dead surface, but re-grep immediately before landing the change in case something new
   appeared during Phase 166's execution window.

5. **`mailable_test.exs`'s own inline comment (lines 95-108) is already correct** — do not treat it
   as a second defect to fix; it independently corroborates the correction needed in
   `docs/api_stability.md`. This is useful confirmation, not additional work.

6. **CI path-filter gate does not skip doc-only changes for these files.** `.github/workflows/ci.yml`'s
   `changes` job (`Detect Non-Doc Changes`, lines 22-68) only classifies a push/PR as doc-only (and
   thus skips the full matrix) when **every** changed file is under `.planning/` or `prompts/`. None
   of CLAUDE.md, CONTRIBUTING.md, MAINTAINING.md, README.md, CHANGELOG.md, `guides/*.md`,
   `docs/api_stability.md`, `.github/dependabot.yml`, or any `lib/`/`test/` file fall under those two
   prefixes — so a PR touching any of them (which is all of DOCS-02 through DOCS-06 and STAND-01)
   will correctly trigger the full required-lane matrix, including `support_contract_core` (which
   runs `docs_contract_test.exs`). **The one exception is a STATE.md-only commit** (`.planning/`
   prefix) — if DOCS-01 is somehow isolated into its own commit/PR with nothing else changed, CI
   will classify it `code=false` and skip validation. This is low-risk (STATE.md has no test pin to
   skip anyway, per DOCS-01 notes), but confirms DOCS-01 should land bundled with at least one
   non-`.planning/` file change if a maintainer wants any CI signal on that commit at all.

## Already-Fixed / Dead Work — do not re-do

1. **`guides/upgrading-to-v2_0.md` already exists on disk.** The requirement's phrasing ("does
   `guides/upgrading-to-v2_0.md` exist? what is it actually named?") reads as an open question; it
   is answered: yes, exact name, no rename needed. The only defect is the missing README link.
2. **`test/mailglass/docs_contract_test.exs` passes green today** (49 tests, 0 failures, 1 skipped).
   DOCS-04 is not a currently-failing test to fix; it is a fragile-but-passing lockstep to make
   durable. Do not spend time "debugging a red test" that isn't red.
3. **`mailable_test.exs`'s own AST-injection comment is already accurate** — no fix needed there,
   only in `docs/api_stability.md`.
4. **CONTRIBUTING.md's `fix(inbound):` example commit message at line 161 is a legitimate,
   unrelated example** (demonstrating a *different*, still-valid historical scenario: "select CI by
   checkout SHA") — do not blanket-`refute` the string `fix(inbound):` across the whole file, only
   the specific stale-floor-bump sentence at lines 188-190.
5. **`reference/host_app` and `reference/demo_app` correctly have no `mix`-ecosystem Dependabot
   entries** — this is intentional (frozen baselines), not a gap to fill under STAND-01.
6. **PR #222 is closed** — any lingering plan-time assumption that it's still open (carried from
   earlier `.planning/` bullets or the requirement text itself) is stale; the currently-open PR
   relevant to release mechanics is #280, and its identity/status should be re-checked at execution
   time per Landmine #2.

## Sources

### Primary (HIGH confidence — read at HEAD this session)
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` — requirement text, phase shape, landmine notes
- `.planning/phases/166-*/166-VERIFICATION.md` — Phase 166 status, six items with post-merge evidence pending
- `CLAUDE.md`, `CONTRIBUTING.md`, `MAINTAINING.md`, `README.md`, `CHANGELOG.md` — full grep + targeted reads
- `guides/migration-from-swoosh.md`, `guides/compatibility-and-deprecations.md`, `guides/` directory listing
- `test/mailglass/docs_contract_test.exs` (full read of relevant sections + helper functions), `test/mailglass/config_test.exs`, `test/mailglass/mailable_test.exs`
- `lib/mailglass/config.ex`, `lib/mailglass/renderer.ex`, `lib/mailglass/outbound.ex`, `lib/mailglass/mailable.ex`, `lib/mailglass/events/reconciler.ex`
- `docs/api_stability.md`, `mailglass_inbound/docs/api_stability.md`
- `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs`, `release-please-config.json`, `.release-please-manifest.json`, `.planning/release-target.json`
- `.github/workflows/ci.yml`, `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `.github/dependabot.yml`
- `scripts/release_policy.exs`, `scripts/release_policy_close_out.sh`
- `gh pr list --state open`, `gh issue list --state open`, `gh pr view 222/129/280`
- Direct execution: `mix test test/mailglass/docs_contract_test.exs` (49 tests, 0 failures, 1 skipped)

### Secondary (MEDIUM confidence)
- [Optimizing the creation of pull requests for Dependabot version updates](https://docs.github.com/en/code-security/tutorials/secure-your-dependencies/optimizing-pr-creation-version-updates) — `groups:`/`update-types:`/`exclude-patterns` syntax, cross-checked via WebSearch summary against multiple independent sources agreeing on the same shape

### Tertiary (LOW confidence)
- None used as load-bearing for any recommendation in this document.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact wording of the recommended `MAINTAINING.md` close-out runbook steps (the 4-step numbered list) is this researcher's synthesis, not a verbatim quote from any existing doc | DOCS-03 notes | Low — the underlying facts (script names, CLI verb, ledger states) are all `[VERIFIED]`; only the runbook's prose phrasing is a recommendation, easily adjusted by the planner/executor |
| A2 | CHANGELOG.md's exact corrected wording for the v2.0 schema-isolation note is drafted, not sourced from an existing canonical one-line summary | DOCS-06 notes | Low — planner should pull exact phrasing from `.planning/milestones/` v2.0 archive documents rather than this draft verbatim, since those are the authoritative source for what shipped in v2.0 |
| A3 | DOCS-02 line 15 (inbound "stable 1.0 contract") is judged defensible/not-falsified based on this researcher's reading of `mailglass_inbound/docs/api_stability.md`'s framing — a reasonable maintainer could still choose to soften the wording | DOCS-02 notes | Low — worst case, the phase spends a small unnecessary edit on an already-acceptable sentence; does not block acceptance criteria |

**If this table is empty:** N/A — three low-risk assumptions logged above, all clearly bounded.

## Open Questions

1. **Should DOCS-01's correction hardcode "#280, currently red" or stay generic?**
   - What we know: #280 is the real current open PR as of this research session (2026-09-18).
   - What's unclear: whether it will still be open/red by the time Phase 167 executes (it's a
     release-please auto-generated proposal; it may merge, close, or be superseded).
   - Recommendation: phrase STATE.md's correction to point at "the current release-please proposal
     PR (see `gh pr list`)" rather than a hardcoded number/status where the text is about *ongoing*
     state, and only hardcode facts that are permanently true regardless of execution date (e.g.,
     "#222 and #129 are both closed" — closed is permanent; "#280 is open" is not).

2. **Does the maintainer want the DOCS-01 live-GitHub-state check (new script) built in this phase,
   or is documenting the *approach* in MAINTAINING.md/STATE.md sufficient to satisfy "pinned by a
   test or generated"?**
   - What we know: no such mechanism exists today; building it is straightforward (mirrors
     `repo-hygiene`'s existing `gh` CLI + JSON-artifact pattern) but is net-new infrastructure in an
     otherwise infrastructure-light phase.
   - What's unclear: whether the 5-day timebox has room for a new scheduled workflow (vs. a one-time
     hand correction with a documented recheck procedure).
   - Recommendation: build a minimal script (not a full GitHub Actions workflow) — a `mix` task or
     shell script invokable both by a human and, later, by a scheduled lane if the maintainer wants
     one. This satisfies "generated, not merely proofread" without requiring new CI wiring in this
     phase.
