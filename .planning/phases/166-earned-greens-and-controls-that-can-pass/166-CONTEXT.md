# Phase 166: Earned Greens and Controls That Can Pass - Context

**Gathered:** 2026-09-17 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Every CI signal either means what it says or can reach its own pass state — without any gate being
relaxed. Ten requirements: GREEN-01..05 (signals that report success without earning it) and
CTRL-01..05 (fail-closed controls structurally unable to reach their own success state).

**The standing prohibition binds every plan in this phase.** No requirement may be satisfied by
weakening a gate, relaxing a fail-closed control, deleting an expiry, lowering a test's rigor, or
narrowing a generator. Every diff must be auditable as *"made a control able to reach its own pass
state."* Three temptations are pre-refused by name: `cron-guard` `continue-on-error` / dropping a
cron; deleting `recheck_by` / `unused_entries`; lowering `max_runs` on the inbound property test.

**Out of scope:** documentation corrections (Phase 167), product behavior changes, CI efficiency
(SEED-006 stays deferred — GREEN-01 makes CI slower and that is accepted), reducing cron frequency
for CTRL-03 (the rate limit is a *secondary* limit, so frequency is not the lever).

**Ordering:** GREEN-01 first (largest blast radius, earliest discovery). CTRL-04 no later than
mid-phase (calendar deadline: the advisories expire 2026-10-26 and red a required lane 2026-10-27
with zero commits).
</domain>

<decisions>
## Implementation Decisions

### Admin lane truth (GREEN-01, GREEN-02)

- **D-01:** GREEN-01 is satisfied by **redefining `verify.support_contract.admin` itself** to a
  directory-scoped `["test --warnings-as-errors"]` run. It is **not** satisfied by pointing the lane
  at `verify.preview`. `mailglass_admin/mix.exs:202-207` (`verify.preview`) additionally runs
  `mailglass_admin.assets.build` + `cmd git diff --exit-code priv/static/` — an asset rebuild that is
  a known landmine (a fresh daisyUI build breaks `token_parity_test`). Adding a Tailwind rebuild to a
  **required** lane would red it on bundle drift unrelated to the 325 newly-run tests.
- **D-02:** Redefining the existing alias auto-fixes `mix ci` with **zero extra edits**: `mix.exs:435`
  (`ci.full`) and `mix.exs:328` (`verify.stability_contract`) already call it by name, and
  `test/scripts/ci_parity_drift_test.exs:184` matches on the **alias name**, not its body — so parity
  stays green. `.github/workflows/ci.yml:916-917` needs no change at all.
- **D-03:** Exclusions need no work. `mailglass_admin/test/test_helper.exs:1` is
  `ExUnit.start(exclude: [:skip])`; the only `@tag :skip` is `voice_test.exs:112`; no admin test needs
  Node (`axe_baseline_test.exs:26-30` reads the committed `docs/axe-baseline.json`).
- **D-04:** `--warnings-as-errors` **stays on the widened alias.** Dropping it would be a prohibited
  gate relaxation. Because `mix.exs:208` applies the flag only to the 9 allow-listed files, the other
  32 files' compile warnings have never been fatal anywhere — so the plan must **budget a
  warning-cleanup task over admin test files** before the lane can be green. Expect the first CI run
  of the widened lane to fail on warnings rather than test outcomes.
- **D-05:** GREEN-02 requires **first adding ExCoveralls to `mailglass_admin`** — it has neither the
  dep nor a `test_coverage:` key (cf. `mailglass_inbound/mix.exs:22,129`). This touches
  `mailglass_admin/mix.exs` + `mailglass_admin/mix.lock` as a clean intentional new-dep entry.
- **D-06:** The committed admin floor is **the measured value from a green 1.18.4/27 run of the
  *widened* 510-test suite, with no safety margin**, mirroring `config/coverage_baselines/core.json`
  shape exactly (including `report_sha256`). The floor is *not* a percentage in config — it is a
  measured triple ratcheted by `scripts/check_coverage_floor.sh`: `covered_lines` **and**
  `relevant_lines` **and** `percentage` must each be ≥ baseline, behind a hard exact-toolchain
  assertion (`check_coverage_floor.sh:11-15` requires 1.18.4/27). A hand-picked percentage would
  either pass vacuously or red immediately, and would lose the `relevant_lines` half of the ratchet.

### Suite floor and its drift guard (GREEN-03)

- **D-07:** **The roadmap's "bump `@suite_floor_env_occurrences` 2 → 3" instruction is wrong as
  written and must not be followed literally.** That constant counts occurrences in
  `advisory-matrix.yml` **only**: `count_suite_floor_env_entries/1` defaults to
  `File.read!(@advisory_matrix_path)` (`lane_classification_drift_test.exs:43`), and all three tests
  in the `describe` at `:592-641` read that file (`:1280-1286`). Adding `MAILGLASS_SUITE_FLOOR: "1"`
  to `ci.yml` therefore breaks nothing — and a bare 2→3 bump would make the drift test **red**, not
  green.
- **D-08:** The real content of GREEN-03's second half is **deliberately extending the guard to
  `ci.yml`**: a separate `@ci_yml_suite_floor_occurrences` constant plus its own anti-vacuity and
  negative-control tests, mirroring the existing `advisory-matrix.yml` trio. Shipping the env line
  without extending the guard leaves it unprotected — reproducing exactly the silent-disable failure
  mode the guard exists to prevent.
- **D-09:** Enabling the floor is expected to pass on today's numbers with **no constant re-pinning**:
  floors are 1576/1575 (`test/support/suite_floor.ex:286-289`) against ~2145 executed, and
  `@skipped_ceiling 7` (`:307`) matches the measured 7 skipped. The growth nudge is a `:warning`,
  never a failure (`suite_floor.ex:693-711`). The lane runs schema `public` with no CLI `--exclude`
  (`ci.yml:446-452`), so the effective exclusion set is exactly `test_helper.exs`'s base list, all
  members of `@known_exclusion_tags` (`suite_floor.ex:245-259`).
- **D-10:** **Residual risk to demonstrate locally before pushing:** unlike the advisory legs, this
  lane does *not* exclude `:requires_workspace`, so `already_shared` / `formatter_violations` tallies
  are measured over a population the floor has never been enforced against. Run an unfiltered
  `MAILGLASS_SUITE_FLOOR=1 mix test --warnings-as-errors` locally first. If it reds on a
  sandbox-ownership signature, re-pinning or excluding are both prohibited diffs — fix the cause.

### Demo Hex pins and the trust-lane cache (GREEN-04, GREEN-05)

- **D-11:** GREEN-04 is a **new, isolated build step** (separate `MIX_BUILD_PATH`/`deps`, or its own
  job) running `MAILGLASS_DEMO_DEPS=hex mix deps.get --check-locked && mix compile` in
  `reference/demo_app`. It is **never a flip of the existing demo steps** at `ci.yml:276-281` and
  `ci.yml:424-437`, which are path-dep builds deliberately proving the working tree and feeding core
  coverage + the deterministic suite. Flipping one would make a required lane compile published 2.0.0
  instead of the branch under test — a silent *loss* of the exact signal this milestone is about.
- **D-12:** No lock edit is needed. `reference/demo_app/mix.exs:60-76` swaps path deps for
  `{:mailglass, "~> 2.0"}` when `MAILGLASS_DEMO_DEPS == "hex"`, and `reference/demo_app/mix.lock:21-23`
  already carries hex entries for all three packages at 2.0.0, so `--check-locked` succeeds today.
- **D-13:** **GREEN-05's premise (FINDINGS FG-4) is refuted — and refuted *by construction*, with
  implementation evidence rather than a "probably fine" verdict.** `actions/cache` SHA-256-hashes the
  declared `path` list into the cache **version** (`packages/cache/src/internal/cacheUtils.ts`,
  `getCacheVersion`), and the server filters candidates by version, so `restore-keys` prefix matching
  cannot rescue a mismatch. Restore calls `extractTar` with **no path argument** — extraction is
  all-or-nothing into `$GITHUB_WORKSPACE`, so partial/selective materialization does not exist as a
  mechanism. `ci.yml` has 19 cache steps sharing one key *string* across **five distinct path lists**
  (`deps` at :132/:161/:337/:595/:674; +inbound+demo at :264-267; +host_app+demo at :406-410;
  +inbound at :498-500/:563-565; the separate `plt-` key at :681) — these are **four independent cache
  entries under one key name**, not one shared cache. Cross-lane contamination cannot happen.
- **D-14:** Two further facts close the requirement: neither trust lane caches
  `reference/host_app/deps` at all (both declare `path: deps` only — `ci.yml:1206`, `ci.yml:1291`;
  the jobs that save it are `support_contract_core` :261-270 and `core_deterministic_suite` :403-413),
  and the trust lanes' `mix deps.get` is unlocked only in the `--check-locked` sense — it still honors
  `reference/host_app/mix.lock:20-22`, which pins 2.0.0. So "resolving live 2.6.0" was never
  established either.
- **D-15:** The committed note must **demonstrate**, not assert. Three parts: (1) a key-space table of
  which jobs save which paths under the shared key; (2) a CI run step listing
  `reference/host_app/deps` **before** `deps.get` in each trust lane, proving what restore actually
  materialized; (3) a lock-authority proof (`mix deps.tree` / lock diff) that resolution is 2.0.0.
  Disambiguating the two trust lanes' cache keys with a lane-specific segment is a one-line,
  zero-relaxation belt-and-braces addition to land alongside the note.
- **D-16:** **Plan-visible caveat:** changing any existing `path:` list creates a brand-new cache
  entry and cold-starts that job's cache. That is a one-run CI slowdown, not a regression — state it
  in the PR so a first-run `Cache not found for input keys: mix-…` miss is not misread.

### CTRL-01 — post-publish-smoke can pass between releases

- **D-17:** CTRL-01 is **four coordinated edits**, not just a new policy verb:
  1. a `baseline-versions` resolution verb handling `status == "inactive"`;
  2. a new `workflow_dispatch` **mode input** — the schedule path is unreachable today, hard-branched
     on `EVENT_NAME` (`post-publish-smoke.yml:263-265` chooses `completed-versions` only for
     `schedule`), with all four dispatch inputs `required: true` (`:15-30`) behind a fail-closed
     40-hex guard (`:73-78`). **Keep the guard; condition it on mode.**
  3. a `cron-guard` predicate that accepts baseline evidence: emit a **distinct `baseline=true`** and
     widen the schedule branch at `:285-288` to `COMPLETED || BASELINE`, keeping the SemVer-triple and
     40-hex-ref assertions. **Never reuse `completed=true` for an inactive ledger** — that is making a
     fail-closed control lie, the prohibited diff by name.
  4. a baseline-mode target check that does **not** demand `publishable_content.digest`:
     `scripts/check_post_publish_target.sh:86-98` requires a 64-hex digest, which
     `close_out_successor/3` sets to **`null`** (`release_policy.exs:620-624`).
- **D-18:** The baseline proof verifies the three tags resolve to
  `required_evidence_identifiers.historical_tag_sha` plus `hex_release_checksums` /
  `hex_release_endpoints` (all present and correct for 2.6.0/2.6.0/2.3.0 in
  `.planning/release-target.json`), running the **same** exact Hex checksum/endpoint proof against the
  published baseline. Dispatch semantics for a live release are unchanged.

### CTRL-02 / CTRL-03 — release-please rate limit

- **D-19:** CTRL-02's fix is **deleting the early `exit 0`** at `release-please.yml:90-94`, which
  resurrects an already-written but currently unreachable proposal-mode path — the
  `elif ! expected_tags_text=$(scripts/release_policy_expected_tags.sh "$manifest")` branch at `:101`
  is dead code today because the `if [ -z "${CANDIDATE_DIGEST:-}" ]` block returns first. Downstream
  at `:145-167`, the `Merge pull request #N` parse + `autorelease: tagged` label check **is** the
  already-tagged-SHA skip CTRL-02 asks to restore, and its `should_run=false` correctly gates the
  action step's `if:` at `:298`. Do **not** write new preflight logic — doing so risks reintroducing
  the partial-release / missing-tag hard-fails at `:127-132` on an ordinary push, turning a rate-limit
  red into a structural one.
- **D-20:** CTRL-03's retry lives in exactly two places: a bash retry loop around the `gh api` calls
  that already classify to `cannot-check` (`release-please.yml:119` — already uses `--include`, so
  headers are available — and `:179`), and `continue-on-error: true` + **one guarded re-run with
  backoff** on the `googleapis/release-please-action` step (`:292-306`, `:299`). That action step is
  the only non-`continue-on-error` GitHub-API step in the proposal path — every other one already
  classifies (`:457-460`, `:497-510`, `:677-687`) — which is why a 403 there crashes the job instead
  of producing evidence.
- **D-21:** **The gate at `release-please.yml:736-739` is left byte-for-byte alone.**
  `[ "$RESULT_STATUS" = pass ] || { pending && no_open_proposal; }` is what makes `cannot-check` never
  report as `pass`; widening it to tolerate `cannot-check` is the prohibited cosmetic green.
- **D-22:** Concrete retry policy, per GitHub's own normative text (docs prescribe a **60-second
  floor** and no maximum count):
  - **Classify on `403` OR `429`** *and* body matching `/secondary rate/i`. A loop matching only 403
    is incomplete. Do not classify on headers.
  - Sleep = `retry-after` if present and non-blank → else `x-ratelimit-reset - now + 1` **only if**
    `x-ratelimit-remaining == 0` → else **60s**. Escalate ×2 per consecutive secondary failure,
    flooring every wait at 60s.
  - **3 attempts (60 / 120 / 240s, ≈7 min worst case)**, then hard-fail. The retry *count* is
    project policy, not a documented GitHub value — label it as such in the PR.
  - **Never `continue-on-error` a blind retry** — GitHub documents banning risk for continuing to
    request while limited. The `continue-on-error` in D-20 exists solely to route the failure into
    classification, followed by a bounded guarded re-run.
- **D-23:** **Do not model the loop on octokit defaults or `actions/github-script`'s `retries`
  input.** `@octokit/plugin-retry` puts 403 in `doNotRetry` and uses quadratic 1s/4s/9s delays (all
  three retries finish in 14s, under the floor); `actions/github-script` bundles retry but **not**
  throttling, defaults `retries: "0"`, and exempts 403. `googleapis/release-please-action` inherits
  that posture — which is why a guarded outer re-run is the only available lever.
- **D-24:** **No pre-flight "is the limit clear" probe may be built.** GitHub states there is no way
  to check secondary-limit status, and the primary `x-ratelimit-*` buckets read full during a
  secondary 403 (the documented reason the codebase's own evidence shows all 15 buckets full).
  Unconditional timed waiting is the only correct mechanism.
- **D-25:** CTRL-02 makes CTRL-03 cheaper (fewer `gh api` calls per push), but **neither alone
  produces exit criterion 5**. They land in one PR.

### CTRL-04 — the Hex Audit calendar time bomb

- **D-26:** **The entries stay. Upstream has permanently declined the fix, and this is source-verified,
  not inferred.** Both OSV records list 2.20.0 as affected with a SEMVER range carrying an
  `introduced: 2.9.0` event and **no `fixed` event**, re-confirmed 2026-09-09 — *one day after* cowlib
  2.20.0 shipped to Hex (2026-09-08), so the enumeration is deliberate, not stale. Verified directly
  in cowlib 2.20.0 source: `cow_cookie:cookie/1` emits values verbatim and
  `cow_http_struct_hd:escape_string/2` escapes only `\` and `"`, passing CR/LF through.
- **D-27:** All six upstream fix PRs (ninenines/cowlib #154, #163, #164, #165, #166, #169) were
  **closed unmerged by the maintainer on principle**: *"Both CVEs are invalid because this type of
  validation is done at a different level… Neither Gun nor Cowboy are vulnerable"*
  (ninenines/cowlib#167, 2026-08-06; https://ninenines.eu/articles/security-strategy/). The EEF
  advisory pages themselves point remediation at the framework layer — Cowboy 2.16.0+
  `invalid_response_headers`, Gun 2.4.0+ `invalid_request_headers` — which mailglass inherits via
  plug_cowboy.
- **D-28:** **There is no upgrade escape, so any plan step shaped "bump cowlib to clear the audit" is
  struck.** Latest cowlib is 2.20.0; latest cowboy 2.19.0 requires `cowlib >= 2.20.0 and < 3.0.0`.
  The repo is already on the newest of both. The entries stay "used" solely via the `mailglass_admin`
  scan (`mailglass_admin/mix.lock` → cowlib 2.20.0; `dev/mix/tasks/mailglass.audit.ex` `@scan_dirs`
  is `["", "mailglass_admin", "mailglass_inbound"]`, and root + inbound locks carry no cowlib at all).
- **D-29:** **No new schema field is needed** — the existing free-text `:reason` carries the
  justification. Rewrite both entries' reason from *"no upstream fix as of cowlib 2.19.0"* (which
  implies a fix is pending, and is stale against the locked 2.20.0) to the **permanent-refusal
  framing**: the closed-PR list, the maintainer's position and the security-strategy URL, the
  2026-09-17 source verification against 2.20.0, the OSV re-confirmation date and absent `fixed`
  event, the no-upgrade-escape fact, and the Cowboy/Gun-layer mitigation. The entry-specific mirego
  notes remain accurate verbatim (`GHSA-g2wm-735q-3f56.yml` has empty `first_patched_versions` and
  ranges `>= 2.9.0, <= 2.16.1`; `GHSA-w4f7-4cxr-rv3c` 404s — absent from mirego, as stated).
- **D-30:** **New `recheck_by` is `~D[2027-03-17]` (6 months)** — USER DECISION. It halves the churn
  of re-litigating a settled refusal while keeping the expiry real and the control fail-closed. The
  reason must name the cheap falsifiable re-verification: *does a cowlib release > 2.20.0 validate
  input, or does OSV add a `fixed` event.*
- **D-31:** **lib/ exemption, stated explicitly** — USER DECISION. The milestone's "no product code
  changes" constraint collides with CTRL-04, which necessarily edits
  `lib/mailglass/supply_chain/accepted_advisories.ex:62-89` (both entries; `recheck_by` at `:73` and
  `:88`). This is a **data/justification edit only** — the `:reason` and `:recheck_by` fields of two
  entry maps. `expired_entries/1` (`:189-191`) and `unused_entries/1` (`:200-202`) are untouched and
  no behavior changes. **The plan and the PR description must name this exemption** so a reviewer
  does not read it as scope drift.
- **D-32:** **The acceptance clause "clock faked to 2026-12-01" has no in-process fake, and none may
  be added.** `dev/mix/tasks/mailglass.audit.ex:145` calls `AcceptedAdvisories.expired_entries()` with
  its `Date.utc_today()` default (`accepted_advisories.ex:188`) and does **not** route through
  `Mailglass.Clock`. Adding a `--today` / env override would ship a maintainer-settable expiry bypass
  — exactly the gate-weakening this milestone prohibits. Evidence is instead **(a)** a real
  `mix mailglass.audit --kind hex` run and **(b)** a rewritten date-boundary test at the new dates.
- **D-33:** **Two-file atomic lockstep (the Phase 125 pin-drift shape, third occurrence).**
  `test/mailglass/supply_chain/accepted_advisories_test.exs:155,159,172,177` hardcode `~D[2026-10-26]`,
  `~D[2026-10-27]`, `~D[2026-12-01]` and `~D[2026-07-28]`, and **`:168-174` currently asserts both
  entries ARE expired at 2026-12-01** — the direct negation of the acceptance criterion. The entry
  data and the test dates move in the same commit or the core suite reds deterministically.

### CTRL-05 — repo-hygiene

- **D-34:** Two edits in `dev/mix/tasks/mailglass.repo.hygiene.ex` plus its test. First: split the
  exit code so `:cannot_check` gets its **own distinct, still-non-zero** code — `:46-48` currently
  collapses *every* non-pass to `exit({:shutdown, 1})`, and `:427-433` aggregates `:cannot_check`
  above `:blocked`. **Separating it by making it exit 0 is prohibited** — that converts an
  unobservable control into a permanent green, the same failure class as CTRL-03's temptation.
- **D-35:** Second: replace the `if Enum.empty?(prs), do: :pass, else: :blocked` predicate at
  `:294-305` with "open **>14d** or failing a required check". This **requires widening the
  `gh pr list --json` field list** at `:280-292`, which currently fetches `updatedAt` and
  `mergeStateStatus` but **not** `createdAt` (needed for age) or `statusCheckRollup` (needed for
  failing-check). `test/mix/tasks/mailglass.repo.hygiene_test.exs` pins current behavior and moves in
  the same commit.
- **D-36:** `.github/workflows/repo-hygiene.yml` needs **no change** — it just runs the task with
  `set -o pipefail` (`:38-45`).

### PR slicing under the WIP-1 limit

- **D-37:** Five sequential PRs, each independently reviewable against *"made a control able to reach
  its own pass state"*:
  1. **PR-1 (day 1, largest blast radius): GREEN-01 + GREEN-02** — must be one PR, because widening
     the lane changes the population the coverage baseline is measured over; a baseline committed
     before the widening would be measured against the wrong 185-test cohort. Touches
     `mailglass_admin/mix.exs`, `mailglass_admin/mix.lock`, `config/coverage_baselines/admin.json`,
     `ci.yml` (one new floor step mirroring `:292-295`).
  2. **PR-2: GREEN-03** — atomic by construction: the `ci.yml` env line + the extended
     `lane_classification_drift_test.exs` guard in one commit.
  3. **PR-3 (mid-phase calendar deadline): CTRL-04** — atomic pair (entry data + test date rewrite).
     The upstream evidence is already gathered (D-26..D-29), so this is not blocked.
  4. **PR-4: CTRL-02 + CTRL-03** — cause and symptom. Exit criterion 5 ("three consecutive pushes
     green, `push` and `schedule` agreeing at the same SHA") is only observable after both, and each
     subsequent merge is itself one of the three observations — so PR-5 and the Phase 167 PRs supply
     the three-push evidence for free.
  5. **PR-5: GREEN-04 + GREEN-05 + CTRL-01 + CTRL-05** — four independent, small, low-coupling diffs.
     **If the timebox tightens, CTRL-01 is the one that must not be dropped** — it is milestone exit
     criterion 3, and the only one whose acceptance needs a `workflow_dispatch` on `main` after merge.
- **D-38:** Mandatory-atomic pairs, restated for the planner: **GREEN-01+GREEN-02**, **GREEN-03's two
  files**, **CTRL-04's two files**, **CTRL-02+CTRL-03**. Genuinely independent: GREEN-04, GREEN-05,
  CTRL-05.

### Claude's Discretion

- Exact admin warning-cleanup mechanics (D-04) — whatever the widened run surfaces, fixed in test
  files only, never by relaxing the flag.
- The precise shape of the `ci.yml` occurrence-guard constant and its negative control (D-08), so
  long as it mirrors the existing `advisory-matrix.yml` trio.
- Whether GREEN-04's isolated build is a separate job or a separate `MIX_BUILD_PATH` within an
  existing one (D-11), provided no existing path-dep demo build is flipped.
- The lane-specific cache-key segment's naming (D-15).
- The exact `workflow_dispatch` mode input name for CTRL-01 (D-17).

### Folded Todos

None — `todo.match-phase 166` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — v2.8 section: GREEN-01..05 and CTRL-01..05 acceptance text, the stop
  line, the standing prohibition, and the Out of Scope table (verbatim acceptance criteria).
- `.planning/ROADMAP.md` — Phase 166 Phase Details: success criteria and the in-phase
  dependencies-and-landmines list. **Note: its "bump `@suite_floor_env_occurrences` 2 → 3" instruction
  is superseded by D-07/D-08 below.**
- `.planning/research/v2.8/FINDINGS.md` — the orchestrator-verified evidence base behind every
  requirement. **Note: its FG-4 trust-lane cache premise is refuted by D-13/D-14.**
- `.planning/METHODOLOGY.md` — Decisive-By-Default Research Posture, Honest Surface Area,
  Recommendation-First Synthesis.
- `CLAUDE.md` — Engineering DNA and the Things Not To Do list. (Its release-mechanics claims are
  themselves Phase 167 DOCS-02 targets; do not treat them as authoritative here.)
- `MAINTAINING.md:431` — the documented, deliberately non-gating inbound property flake (out of scope).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `mailglass_admin/mix.exs:208` — `verify.support_contract.admin`, the 9-file allow-list to replace.
  `:202-207` — `verify.preview`, the uninvoked alias the roadmap names; **rejected per D-01** because
  it carries an asset rebuild.
- `scripts/check_coverage_floor.sh` — the existing measured-triple ratchet (`:11-15` toolchain
  assertion). `config/coverage_baselines/core.json` (`:8` `report_sha256`) is the shape to mirror.
  `mailglass_inbound/mix.exs:22,129` is the working ExCoveralls wiring to copy.
- `ci.yml:292-295` — the existing coverage-floor step to mirror for the admin lane.
- `test/support/suite_floor.ex` — floors at `:286-289`, `@skipped_ceiling` at `:307`,
  `@known_exclusion_tags` at `:245-259`, warning-not-failure growth nudge at `:693-711`, runtime env
  read at `:798`.
- `test/scripts/lane_classification_drift_test.exs` — `@advisory_matrix_path` default at `:43`, the
  three-test `describe` at `:592-641`, `count_suite_floor_env_entries/1` at `:1280-1286`. The trio to
  mirror for `ci.yml`.
- `reference/demo_app/mix.exs:60-76` — the `MAILGLASS_DEMO_DEPS == "hex"` dep swap;
  `reference/demo_app/mix.lock:21-23` already carries the 2.0.0 hex entries.
- `release-please.yml:101` — the dead `expected_tags_text` branch; `:145-167` — the already-written
  `autorelease: tagged` skip that CTRL-02 resurrects; `:119` `gh api --include` (headers available).
- `release_policy.exs` — `validate_completed_target` at `:332-345`, `close_out_successor/3` at
  `:620-624` (sets `publishable_content.digest` to `null`).
- `lib/mailglass/supply_chain/accepted_advisories.ex` — entries `:62-89`, `recheck_by` `:73`/`:88`,
  `expired_entries/1` `:189-191` (default `Date.utc_today()` at `:188`), `unused_entries/1` `:200-202`.
- `dev/mix/tasks/mailglass.repo.hygiene.ex` — `--json` fields `:280-292`, PR predicate `:294-305`,
  status aggregation `:427-433`, exit collapse `:46-48`.

### Established Patterns

- **Alias-name-matched parity.** `ci_parity_drift_test.exs:184` matches alias *names*, not bodies —
  so redefining an alias's body keeps `mix ci` ↔ CI parity green for free (D-02).
- **Measured-ratchet floors, not configured percentages.** Core and inbound both commit a measured
  triple + `report_sha256` behind an exact-toolchain assertion (D-06).
- **Classify-then-gate for GitHub evidence.** Every API step in the release-please proposal path
  except the action itself is `continue-on-error` + classify into an evidence artifact; the single
  gate at `:736-739` is where `cannot-check` is denied a pass (D-20, D-21).
- **Occurrence-count drift guards.** A constant pins how many times a load-bearing env var appears in
  a workflow, with an anti-vacuity test and a negative control (D-08).
- **Two-file doc/test lockstep.** Recurring shape (Phase 125 pin-drift; CTRL-04 is the third
  occurrence) — a literal value asserted verbatim by a test, where splitting the change produces a
  deterministic red (D-33).

### Integration Points

- `ci.yml:916-917` — the `Support Contract Admin` lane invocation (unchanged by D-01/D-02).
- `ci.yml:446-452` — `core_deterministic_suite`, where `MAILGLASS_SUITE_FLOOR: "1"` lands.
- `ci.yml:1206`/`:1291` (trust-lane cache `path:`), `:1226`/`:1307` (their `deps.get`) — GREEN-05.
- `ci.yml:276-281`, `:424-437` — existing path-dep demo builds; **do not flip** (D-11).
- `post-publish-smoke.yml:15-30` (dispatch inputs), `:73-78` (40-hex guard), `:263-265` (event
  branch), `:285-288` (cron-guard) — CTRL-01.
- `scripts/check_post_publish_target.sh:86-98` — the 64-hex digest requirement to bypass in baseline
  mode.
- `.planning/release-target.json` — currently `inactive`, carrying `baselines`,
  `required_evidence_identifiers.historical_tag_sha`, `hex_release_checksums`, `hex_release_endpoints`
  for 2.6.0/2.6.0/2.3.0.
- `.github/workflows/repo-hygiene.yml:38-45` — invocation only; no change needed (D-36).
</code_context>

<specifics>
## Specific Ideas

- **Two user decisions recorded this session:** the CTRL-04 lib/ exemption is taken as a
  **data-only exemption, explicitly stated in the plan and PR** (D-31), and the new `recheck_by` is
  **`~D[2027-03-17]`, 6 months** (D-30).
- **The `:reason` rewrite has a drafted form** available in this session's research output; the
  planner should reproduce its substance (closed-PR list, maintainer position + security-strategy URL,
  2026-09-17 source verification against 2.20.0, OSV re-confirmation with no `fixed` event, the
  no-upgrade-escape fact, framework-layer mitigation, and the named falsifiable re-check).
- GREEN-05's committed note is a **deliverable artifact**, not a comment — the requirement's "a
  'probably fine' verdict does not satisfy this" clause is the acceptance bar.
</specifics>

<deferred>
## Deferred Ideas

- **The one `:flaky` tag** (`tenancy_test.exs:154`) — fixable in one line (`Code.ensure_loaded!/1`),
  and its justification cites an archived path that no longer exists. Per REQUIREMENTS.md Out of
  Scope: **admit it only if the timebox has room after all ten requirements land.** Not a Phase 166
  commitment.
- **Cache-shape consolidation across `ci.yml`'s 19 cache steps / five path lists** (D-13). Surfaced
  by GREEN-05 research; it is a CI-efficiency change, and SEED-006 is already deferred. File, don't
  fix.
- **Reference-app lock lag** — `reference/host_app/mix.lock` carries cowlib 2.18.0 while demo_app and
  admin are at 2.20.0. Not scanned by `mailglass.audit` (`@scan_dirs` excludes reference apps), so it
  affects nothing in scope. File.
- **Shared `mailglass_test` database between core and admin** — already filed as a todo in
  REQUIREMENTS.md Out of Scope; GREEN-01's widened admin run touches the same suites, so re-confirm it
  stays serial under `mix ci` but do not de-fang it here.

### Reviewed Todos (not folded)

None — `todo.match-phase 166` returned 0 matches.
</deferred>
