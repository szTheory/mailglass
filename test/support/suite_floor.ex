defmodule Mailglass.TestSupport.SuiteFloor do
  @moduledoc """
  The anti-vacuity policy layer for `mix test` (HARNESS-03, D-13..D-17).

  Answers three questions a green `mix test` run does not answer on its own:
  how many tests actually ran, which categories were allowed not to run, and
  did the sandbox-ownership regression signature (`:already_shared`, HARNESS-01)
  reappear. "Implied by `failures == 0`" is true today and worthless tomorrow —
  the moment the lane goes red for three unrelated reasons plus forty leaked
  owners, it reads as "43 failures" and the regression identity is lost. That
  is precisely the SEED-007 pain this module exists to prevent.

  A deliberate sibling of `Mailglass.CILanes` in spirit: hardcoded constants,
  each with a rationale comment saying what question it answers and what it
  is not, one-line `@doc`/`@spec` accessors, and a drift/negative-control
  meta-test (`test/scripts/suite_floor_contract_test.exs`) that exercises the
  same pure function this module's real `after_suite` path calls. There is no
  new idiom here for a future maintainer to learn.

  ## Why counts come from `ExUnit.after_suite/1`, never the CLI summary line (D-13)

  `after_suite/1`'s callback receives `%{total:, failures:, excluded:,
  skipped:}` — a typespec verified identical on Elixir 1.18.4 and 1.19.5. The
  CLI summary line is not merely brittle, it is *wrong*, on this repo's own
  toolchain matrix:

  ```
  Elixir 1.18.4:   23 properties, 1450 tests, 29 failures, 13 excluded, 7 skipped
  Elixir 1.19.5:   23 properties, 1437 tests, 213 failures, 7 skipped (13 excluded)
  ```

  Two independent breaking differences between the two legs of the very
  matrix HARNESS-02 requires green:

    1. **Field order changed.** `excluded` moved after `skipped` and into
       parentheses.
    2. **The meaning of `N tests` changed.** On 1.18 it is `total`; on 1.19 it
       is `total - excluded` (`1450 - 13 = 1437` public, `1450 - 14 = 1436`
       mailglass — exact on both schema axes).

  A shell parser pinned to 1.18's shape silently under-reports on 1.19 by the
  exclusion count; one pinned to 1.19's shape fails to parse 1.18 at all. The
  four ExUnit-native counts below are read with `Map.fetch!/2`, never
  `Map.get/3` with a default, so a shape difference on either leg fails
  loudly instead of silently reporting a wrong number.

  ## Why a machine-rewritten baseline is rejected (D-15)

  No threshold here is measured and written back by CI (no `.last_run.json`,
  no committed count file). A threshold a machine rewrites is an artifact, not
  a decision — it ratchets on flakes (a baseline written from a lucky run
  becomes the new floor) and is unmanageable under a parallel matrix (which
  leg's number wins?). Every constant below is a literal in this file,
  changed only by a human editing this file and re-reading the comment above
  it.

  ## Where the pinned floors and ceiling come from (D-27) — read before touching them

  Every threshold below was measured from **GitHub Actions run
  `30568802513`** (workflow `Advisory Matrix`, branch
  `gsd/phase-143-test-harness-truth`, head SHA `369577b0`, 2026-07-30), whose
  two Core Full Suite legs both concluded `success` (that pre-rename run reported
  them as `Core Full Suite Advisory (...)`; the job is now `core_full_suite` and the
  lane is `Core Full Suite (...)` — Phase 143 / D-21):

  | Job | Leg | Seed | `after_suite` counts | executed |
  |---|---|---|---|---|
  | `90959947929` | Elixir 1.18.4 / OTP 27.3.4.15 / schema `public` | 478127 | `total: 1596, excluded: 13, skipped: 7, failures: 0` | **1576** |
  | `90959948064` | Elixir 1.18.4 / OTP 27.3.4.15 / schema `mailglass` | 43820 | `total: 1596, excluded: 14, skipped: 7, failures: 0` | **1575** |

  D-27 forbids pinning these locally, and the reason is not stylistic: this
  repo's local toolchain is Elixir 1.19.5 / OTP 28 while every gating and
  required lane runs Elixir 1.18.4 / OTP 27, so a locally measured number
  would pin the WRONG leg of the very matrix the floor guards. The pre-fix
  ledger numbers (`143-RESEARCH.md`'s "Measured baselines": 1430 executed on
  `public`, 1429 on `mailglass`) came from a RED, pre-fix run and are sanity
  bounds only — a red-run count is not a target, and neither is a local one.

  **Research assumption A1 is CONFIRMED on the gating toolchain.** A1 held
  that `ExUnit.after_suite/1`'s callback map carries all four of `:total`,
  `:failures`, `:excluded` and `:skipped` on Elixir 1.18.4; it had only ever
  been verified on 1.19.5 locally. Both jobs above printed all four counts
  through the `Map.fetch!/2` reads in `check/1` — a missing key would have
  raised `KeyError` there rather than printing — so the 1.18.4 shape is now
  observed, not assumed. The `Map.fetch!/2` calls stay `fetch!` (never
  `Map.get/3` with a default) so a future shape change fails loudly.

  **The 1.19/OTP 28 legs have no green evidence and nothing here is pinned
  from them.** `core_full_suite_next_toolchain_advisory` carries
  `if: github.event_name != 'pull_request'`, and every Advisory Matrix run on
  this branch has been a `pull_request` event, so those two legs have been
  `skipped` on all of them. The floors are therefore keyed on schema alone
  rather than on `{schema, elixir_minor}` (D-16's re-keying instruction
  applies only to an *observed* divergence, and none has been observed). This
  is safe in the direction that matters: the comparison is `>=`, so a 1.19 leg
  executing at least as many tests passes, and one executing fewer reds an
  ADVISORY lane visibly rather than passing silently — which is the correct
  direction for a leg nobody has measured.

  ## Two scopes, one declaration; enforcement is opt-in (D-15, D-18)

  `install/0` registers `check/1` as an `ExUnit.after_suite/1` callback. Every
  run — a full lane, a focused `mix test path/to/one_test.exs`, a
  `mix verify.*` alias — prints its four counts and its signature tally
  unconditionally. The checks split into two scopes:

    * **Every-run checks.** The exclusion-tag allowlist, the `:already_shared`
      assertion, and the formatter's own hygiene count. These are meaningful
      on any invocation and are always computed.
    * **Full-suite-scoped checks.** The executed floor, the growth nudge, and
      the skipped ceiling. These are claims about a COMPLETE suite run. On a
      run that is deliberately scoped to four tests they are not merely
      uninformative, they are false: "only 4 test(s) executed, below the
      pinned floor of 1576" describes a developer running one file, not a
      regression.

  A run declares itself a complete suite by setting
  `MAILGLASS_SUITE_FLOOR=1`, which the two `advisory-matrix.yml` full-suite
  steps do (HARNESS-03) and which `test/scripts/lane_classification_drift_test.exs`
  asserts they still do. That one declaration carries both roles: it selects
  the full-suite contract AND turns a `kind: :violation` into a non-zero exit
  (`System.halt/1`). Collapsing the two roles into one variable is deliberate
  — they have exactly the same subject ("is this the complete suite the
  thresholds describe?"), and a second variable would be a second thing to
  forget.

  When the scoped checks are NOT evaluated, `print_report/3` says so on its
  own line, naming the variable. That is the difference between "not
  applicable to this run, and here is why" and silence: a reader who expected
  a full-suite lane to enforce can see at a glance that it did not declare
  itself one. The env var is read at runtime via `System.get_env/1` — never
  at compile time through any `Application` config-macro variant (CLAUDE.md's
  "don't use compile-time config reads outside `Mailglass.Config`" rule).

  **This scoping removes no enforcement.** Enforcement was already gated on
  the same variable, so no run that previously failed can now pass; only the
  false `[VIOLATION]` lines printed by runs that were never going to enforce
  are removed. A VIOLATION line that fires on nearly every developer
  invocation teaches people to ignore VIOLATION lines, which costs more than
  the line is worth.

  ## The accepted gap (D-18b) — read this before treating a green floor as more than it is

  None of this proves the tests *assert usefully*. A test rewritten to
  `assert true` still counts as `executed`. The floor answers "did the count
  drop," not "do the assertions mean anything." Do not read a passing
  `SuiteFloor` check as a stronger claim than that.

  ## The exclusion-tag allowlist, both directions (D-14) — the load-bearing invariant

  Not the count floor — the pinned exclusion-tag allowlist, checked by set
  equality in BOTH directions against `ExUnit.configuration()[:exclude]` (the
  effective MERGED set: CLI `--exclude` plus `test_helper.exs`'s conditional
  `ExUnit.configure(exclude: [:public_only])`). A new `@tag :foo` +
  `--exclude foo` fails on the tag NAME before any arithmetic matters; a dead
  allowlist entry fails too.

  The "missing" (dead-entry) direction is deliberately narrower than the
  "unknown" direction — `expected_exclusion_tags/1` asserts only
  `:public_only` (never `:requires_workspace`), because the two tokens are
  applied by fundamentally different mechanisms. `:public_only` is applied by
  `test_helper.exs` ITSELF, deterministically, from `Mailglass.Config.schema()`
  alone (`if schema != "public", do: ExUnit.configure(exclude: [:public_only])`)
  — present on every single non-`"public"` invocation of `mix test` in this
  repo, no CLI flag required, so its absence is always a genuine regression.
  `:requires_workspace`, by contrast, is applied ONLY by an external CLI flag
  (`advisory-matrix.yml`'s `--exclude requires_workspace`), present on the two
  full-suite steps and legitimately absent on every narrower lane
  (`verify.ci_lane_contract`, `verify.support_contract.core`, a developer's
  focused `mix test path/to/one_test.exs`, …) — asserting it as "missing"
  there would be a permanent false positive on nearly every `mix test`
  invocation in the repo, not a real regression. Confirmed live: an early
  draft of this check asserted both directions against the full two-tag
  union and immediately false-positived on `mix test test/mailglass/test_support/`
  (a narrow, real lane). The "unknown" direction still protects
  `:requires_workspace` fully — any run that DOES pass an unpinned tag
  (including a widened `--exclude requires_workspace,foo`) is caught there,
  regardless of lane.

  ### `:test` is `--only`'s mechanism, not an exclusion decision

  `mix test --only foo` is implemented by ExUnit as the PAIR
  `exclude: [:test], include: [foo]` — exclude everything, then re-include the
  named tag. The `:test` token is therefore a mechanical consequence of
  scoping a run, not a category anyone decided to stop covering, and this
  repo reaches it constantly: `mix verify.schema_prefix`, the three
  `--only phase_0N_uat` aliases in `mix.exs`, and any `mix test file.exs:12`
  a developer types. Observed live on BOTH legs of green run `30568802513`:

  ```
  Excluding tags: [:test]
  Including tags: [:schema_prefix]
  [VIOLATION] exclusion_allowlist_unknown_tag: Suite excluded :test, ...
  ```

  `:test` is consequently **discounted from the unknown-tag set when, and
  only when, the run carries a non-empty include set** — the exact signature
  of the `--only` pairing. It is deliberately NOT added to
  `@known_exclusion_tags`: that attribute names the two sources that
  legitimately withhold coverage, and `:test` is not one of them. A bare
  `--exclude test` with no include set still violates, which is right — it
  excludes the entire suite, nobody means it, and the executed floor catches
  the same run a second time when it collapses to zero.

  This is the same correction, and the same reasoning, as the
  `:requires_workspace` narrowing recorded above: distinguish an operator's
  deliberate scoping of a run from a silent loss of coverage. A guard that
  cries wolf on nearly every invocation is not a stricter guard; it is a
  guard people learn to skim past.

  ## The signature tally, and why it crosses a process boundary (D-17, D-09)

  `already_shared` (raw badmatch AND the composed `SandboxOwnership.LeakError`
  combined) and `formatter_violations` (the formatter's own module-boundary
  hygiene-violation count) are read from
  `Mailglass.TestSupport.SuiteTruthFormatter.current_state/0`. `check/1` runs
  in a different process (the `mix test` runner, via `ExUnit.after_suite/1`)
  than the formatter GenServer — and, confirmed by decompiling
  `ExUnit.Runner`, `ExUnit.EventManager.stop/1` already terminated that
  GenServer by the time `after_suite` callbacks run, so a live `:sys.get_state/1`
  read is not merely undesirable here, it is impossible. `current_state/0`
  instead reads the final snapshot the formatter persists to `:persistent_term`
  at `:suite_finished` (its last guaranteed-alive event) — a single source of
  truth (the formatter is still the only place classification/tallying
  happens), not a second/duplicate store this module maintains
  independently. See `SuiteTruthFormatter`'s own moduledoc ("Cross-process
  read path") for the full account, including why the naive name-registered
  `:sys.get_state/1` approach (mirroring `SandboxOwnership.probe/1`) was
  tried first and empirically found not to work. When no snapshot exists
  yet, that is reported as an unverifiable violation, never silently treated
  as zero — a check that cannot observe its subject must not report green.
  """

  alias Mailglass.TestSupport.SuiteTruthFormatter

  # ──────────────────────────────────────────────────────────────
  # Constants
  # ──────────────────────────────────────────────────────────────

  # The complete set of tokens either `advisory-matrix.yml`'s
  # `--exclude requires_workspace` or `test_helper.exs`'s conditional
  # `ExUnit.configure(exclude: [:public_only])` can produce. Answers "is this
  # tag one of the two legitimate sources," not "does THIS schema expect it"
  # — see `expected_exclusion_tags/1` for the schema-aware half.
  @known_exclusion_tags MapSet.new([:requires_workspace, :public_only])

  # Answers: "did this complete suite run at least as many tests as the last
  # green gating run did?" It does NOT answer whether those tests assert
  # anything (D-18b).
  #
  # MEASURED, not estimated, from GitHub Actions run 30568802513 on
  # 2026-07-30 — the two Core Full Suite legs, both `success`, both
  # Elixir 1.18.4 / OTP 27 (the gating toolchain):
  #
  #   job 90959947929, schema public,    seed 478127: 1596 - 13 - 7 = 1576
  #   job 90959948064, schema mailglass, seed 43820:  1596 - 14 - 7 = 1575
  #
  # The one-test difference is the whole reason D-16 requires PER-SCHEMA
  # floors: `test_helper.exs` excludes `:public_only` on any non-`"public"`
  # schema, so the mailglass leg legitimately excludes one more test. A single
  # global floor would have to equal 1575 and would blind the public leg to
  # losing a test.
  #
  # NO SAFETY MARGIN. The measured minimum is pinned exactly. A margin is slop
  # that silently absorbs the first regression — which is the entire failure
  # mode this constant exists to catch.
  #
  # A future legitimate change (a removed test, a new exclusion) must update
  # this count DELIBERATELY, from a fresh green CI run, not delete the guard
  # and not shave the number down to whatever today's red run produced. If the
  # executed count drops, tests are gone: that is the signal, not the noise.
  @executed_floors %{
    "public" => 1576,
    "mailglass" => 1575
  }

  # Answers: "did this complete suite run start skipping something new?"
  #
  # MEASURED at 7 on BOTH legs of run 30568802513 (2026-07-30), identical
  # across the two schema axes.
  #
  # A grep of `test/` finds MORE skip declarations than this — 5 × `@tag :skip`
  # plus 3 × `@moduletag :skip` — because some of them sit inside modules that
  # the lane's `--exclude requires_workspace` removes wholesale, so ExUnit
  # never reaches them to count them as skipped. Do NOT "fix" this constant to
  # match the grep: the measured number is what the gating lane actually
  # reports, and the grep number would silently raise the ceiling by one for
  # every skip that is currently unreachable.
  #
  # `skipped == 0` is explicitly REJECTED as a target (D-16) — it is false
  # today, and a target that is false on the day it is written gets disabled
  # rather than met. A NEW skip must be pinned here deliberately, not absorbed.
  @skipped_ceiling 7

  # NOT a placeholder — a fixed design constant (D-16), independent of
  # whichever floor ends up pinned. Crossing `floor + 40` is a nudge into
  # `$GITHUB_STEP_SUMMARY`, never a build failure: a hard ceiling on suite
  # growth would fail on every single test added to the repo.
  @nudge_margin 40

  # The complete, closed vocabulary of violation/warning `:name` atoms
  # `violations/3` can produce. Exists so the contract test's anti-vacuity
  # guard can assert this set is non-empty without hardcoding a second copy
  # that could silently drift from the pipeline below.
  @violation_classes [
    :exclusion_allowlist_unknown_tag,
    :exclusion_allowlist_dead_entry,
    :executed_floor,
    :executed_nudge,
    :skipped_ceiling,
    :already_shared,
    :formatter_violations
  ]

  @typedoc """
  The closed vocabulary of `:name` atoms `violations/3` can produce — the
  type-level twin of `@violation_classes`, kept adjacent to it so the two
  cannot drift silently (a new atom added to one and not the other fails
  `mix dialyzer`, because `violation_classes/0`'s success typing is the
  attribute's own contents).

  Closed rather than `atom()` on purpose: CLAUDE.md's "errors as a public API
  contract" DNA — consumers pattern-match these names, and a `name: atom()`
  contract would let a typo'd class silently type-check at every call site.
  """
  @type violation_class ::
          :exclusion_allowlist_unknown_tag
          | :exclusion_allowlist_dead_entry
          | :executed_floor
          | :executed_nudge
          | :skipped_ceiling
          | :already_shared
          | :formatter_violations

  @type violation :: %{
          kind: :violation | :warning,
          name: violation_class(),
          message: String.t()
        }

  @typedoc """
  What kind of run produced the report, as distinct from what the report
  says. Both fields describe the operator's DELIBERATE scoping of the run, so
  that scoping is never mistaken for a silent loss of coverage:

    * `:full_suite?` — did the run declare itself a complete suite by setting
      `MAILGLASS_SUITE_FLOOR=1`? Gates the executed floor, the growth nudge,
      and the skipped ceiling, all of which are claims about a complete suite.
    * `:inclusion` — the effective `ExUnit.configuration()[:include]` set. A
      non-empty value is the signature of `mix test --only <tag>`, which
      ExUnit implements as `exclude: [:test], include: [<tag>]`; see the
      moduledoc for why `:test` is discounted only in that pairing.
  """
  @type run_scope :: %{full_suite?: boolean(), inclusion: MapSet.t()}

  # The scope a synthetic report means when it does not say otherwise: a
  # complete suite, with no `--only` narrowing. Every scope-dependent check is
  # therefore ON by default, so a contract-test call site that forgets to pass
  # a scope gets the STRICT reading, never the permissive one.
  @default_run_scope %{full_suite?: true, inclusion: MapSet.new()}

  # ──────────────────────────────────────────────────────────────
  # Public API
  # ──────────────────────────────────────────────────────────────

  @doc """
  Registers `check/1` as an `ExUnit.after_suite/1` callback. Call once, from
  `test_helper.exs`.
  """
  @spec install() :: :ok
  def install do
    ExUnit.after_suite(&__MODULE__.check/1)
    :ok
  end

  @doc """
  `ExUnit.after_suite/1` callback (D-13). Reads the four ExUnit-native counts
  from `results` with `Map.fetch!/2` (never a summary-line parse), the
  effective merged exclusion set from `ExUnit.configuration()`, the current
  schema from `Mailglass.Config.schema()`, and the signature tally from
  `SuiteTruthFormatter.current_state/0` (D-17, D-09). Also reads the effective
  include set and the `MAILGLASS_SUITE_FLOOR` declaration into a
  `t:run_scope/0`, so a deliberately scoped run is not reported as lost
  coverage. Always prints the counts, the signature tally, which scope the run
  declared, and any computed violations. Enforces (non-zero exit via
  `System.halt/1`) only when `MAILGLASS_SUITE_FLOOR` is `"1"` AND at least one
  `kind: :violation` entry was produced — warnings never enforce.
  """
  @spec check(map()) :: :ok
  def check(results) when is_map(results) do
    config = ExUnit.configuration()
    effective_exclusion = config |> Keyword.get(:exclude, []) |> MapSet.new()
    schema = Mailglass.Config.schema()

    run_scope = %{
      full_suite?: full_suite?(),
      inclusion: config |> Keyword.get(:include, []) |> MapSet.new()
    }

    total = Map.fetch!(results, :total)
    excluded = Map.fetch!(results, :excluded)
    skipped = Map.fetch!(results, :skipped)
    failures = Map.fetch!(results, :failures)

    {already_shared, formatter_violations} = read_formatter_tally()

    augmented = %{
      total: total,
      excluded: excluded,
      skipped: skipped,
      failures: failures,
      already_shared: already_shared,
      formatter_violations: formatter_violations
    }

    found = violations(augmented, effective_exclusion, schema, run_scope)

    print_report(schema, augmented, found, run_scope)

    if run_scope.full_suite? and Enum.any?(found, &(&1.kind == :violation)) do
      System.halt(1)
    end

    :ok
  end

  @doc """
  PURE. Takes the augmented results map (the four `ExUnit.after_suite/1`
  counts plus `:already_shared` and `:formatter_violations`, D-17), the
  effective merged exclusion set, the current schema, and optionally the
  `t:run_scope/0` describing how the run was scoped. Returns a list of
  violation maps (`%{kind:, name:, message:}`) — `kind: :warning` entries
  (the nudge) are advisory and MUST NOT be treated as a build failure by any
  caller.

  The scope argument defaults to "a complete suite with no `--only`
  narrowing", so every scope-dependent check is ON unless a caller explicitly
  says the run was narrowed. The default is the strict reading on purpose: a
  call site that forgets the argument over-reports rather than under-reports.

  Driven directly by `test/scripts/suite_floor_contract_test.exs`'s synthetic
  reports — the negative controls there exercise this SAME function, never a
  re-implementation, so a future edit that weakens this pipeline breaks its
  own negative controls too.
  """
  @spec violations(map(), MapSet.t(atom()), String.t(), run_scope()) :: [violation()]
  def violations(results, effective_exclusion, schema, run_scope \\ @default_run_scope)
      when is_map(results) and is_binary(schema) and is_map(run_scope) do
    total = Map.fetch!(results, :total)
    excluded = Map.fetch!(results, :excluded)
    skipped = Map.fetch!(results, :skipped)
    _failures = Map.fetch!(results, :failures)
    already_shared = Map.fetch!(results, :already_shared)
    formatter_violations = Map.fetch!(results, :formatter_violations)

    executed = total - excluded - skipped
    full_suite? = Map.fetch!(run_scope, :full_suite?)
    inclusion = Map.fetch!(run_scope, :inclusion)

    []
    |> allowlist_violations(effective_exclusion, schema, inclusion)
    |> full_suite_violations(executed, skipped, schema, full_suite?)
    |> already_shared_violation(already_shared)
    |> formatter_violation(formatter_violations)
  end

  @doc """
  The full set of exclusion tags either legitimate source
  (`advisory-matrix.yml`'s `--exclude requires_workspace`,
  `test_helper.exs`'s conditional `:public_only`) can produce. Used for the
  "unknown tag" direction of the both-directions check — a schema chooses a
  SUBSET of this set, never a tag outside it (see `expected_exclusion_tags/1`
  for the schema-aware subset).
  """
  @spec known_exclusion_tags() :: [atom()]
  def known_exclusion_tags, do: MapSet.to_list(@known_exclusion_tags)

  @doc """
  The exclusion tags THIS schema's run is expected to carry deterministically
  — the "missing" direction of the both-directions check (D-14, D-16).
  Deliberately narrower than `known_exclusion_tags/0`: only `:public_only`
  (applied by `test_helper.exs` itself, from the schema alone) is asserted
  here. `:requires_workspace` (applied only by an external CLI flag, present
  only on the two full-suite lanes) is protected solely by the "unknown"
  direction — see the moduledoc for why asserting it here would false-positive
  on every narrower lane.
  """
  @spec expected_exclusion_tags(String.t()) :: MapSet.t(atom())
  def expected_exclusion_tags("public"), do: MapSet.new([])
  def expected_exclusion_tags(_schema), do: MapSet.new([:public_only])

  @doc """
  The pinned minimum `executed` count for `schema`, measured from green run
  `30568802513` (see the moduledoc). Evaluated only on a run that declared
  itself a complete suite.

  Returns `0` for a schema with no pinned floor, which is a convenience for
  callers that only ever ask about a pinned axis — NOT a floor. `executed >= 0`
  always holds, so an unpinned schema reaching the real pipeline would pass
  vacuously; `floor_violation/4` therefore checks `pinned_schemas/0` for
  membership FIRST and reports an unpinned schema as a violation rather than
  trusting this default. Ask `pinned_schemas/0`, never this function, when the
  question is "is this axis covered at all?".
  """
  @spec executed_floor(String.t()) :: non_neg_integer()
  def executed_floor(schema), do: Map.get(@executed_floors, schema, 0)

  @doc """
  The schema axes that have a floor pinned from a green CI run. A run on any
  other schema is reported as an unpinned axis, never silently floored at zero
  — a check that cannot observe its subject must not report green, and a
  schema nobody has measured is exactly that.
  """
  @spec pinned_schemas() :: [String.t()]
  def pinned_schemas, do: Map.keys(@executed_floors)

  # ── Why the next two accessors carry no `@spec` (deliberate, not an omission)
  #
  # Both return a bare module attribute, so dialyzer's success typing for each
  # is the LITERAL currently pinned there (`1_000_000_000`, `40`). Under this
  # repo's `:underspecs` flag (mix.exs `defp dialyzer/0`) the honest contract
  # `non_neg_integer()` is reported as `contract_supertype`, and
  # `.dialyzer_ignore.exs` is at its hard 15-entry cap (D-08-07), so the
  # warning cannot be filtered. That leaves exactly two options, and the
  # literal spec is the worse one:
  #
  #   * `@spec skipped_ceiling() :: 7` would be a spec that LIES on the next
  #     edit. `@skipped_ceiling` is re-pinned from a green 1.18/OTP 27 CI run
  #     whenever the suite's reachable skip set changes, and `@nudge_margin`
  #     is a tunable design constant. A spec pinned to today's literal turns
  #     every future re-pin into a mechanical "edit the spec to match the
  #     value" step — which teaches spec-rot as routine and makes the type
  #     signature a second copy of the constant rather than a contract about it.
  #   * No `@spec` states nothing false. Dialyzer still infers and checks the
  #     exact value at every call site, so no checking is lost — only a
  #     redundant restatement of it. The real contract ("a non-negative
  #     integer; callers must NOT depend on the value") lives in the `@doc`
  #     and in `test/scripts/suite_floor_contract_test.exs`, which reads both
  #     accessors live and computes its fixtures from them rather than
  #     hardcoding either number.
  #
  # Do NOT "fix" this by routing the constant through a `Map.get/3` or similar
  # indirection to blind dialyzer (the shape `executed_floor/1` happens to
  # have for its own reasons). Widening a contract to defeat an analyzer is
  # the same class of move as a check that reports green without observing its
  # subject — the exact failure this phase exists to eliminate.

  @doc """
  The pinned maximum `skipped` count, across all legs — measured from green
  run `30568802513` (see the moduledoc). Returns a non-negative integer;
  callers must not depend on the specific value. Evaluated only on a run that
  declared itself a complete suite.
  """
  def skipped_ceiling, do: @skipped_ceiling

  @doc """
  The warn-only nudge margin (D-16): `executed > executed_floor(schema) +
  nudge_margin()` prints a `$GITHUB_STEP_SUMMARY`-bound warning, never a
  build failure. Returns a non-negative integer; callers must not depend on
  the specific value.
  """
  def nudge_margin, do: @nudge_margin

  @doc """
  The complete, closed vocabulary of `:name` atoms `violations/3` can
  produce. See the module attribute of the same name for the rationale.
  """
  @spec violation_classes() :: [violation_class(), ...]
  def violation_classes, do: @violation_classes

  # ──────────────────────────────────────────────────────────────
  # Internal — the pure pipeline
  # ──────────────────────────────────────────────────────────────

  defp allowlist_violations(acc, effective_exclusion, schema, inclusion) do
    unknown =
      effective_exclusion
      |> MapSet.difference(@known_exclusion_tags)
      |> discount_only_mode_marker(inclusion)

    missing = MapSet.difference(expected_exclusion_tags(schema), effective_exclusion)

    acc =
      Enum.reduce(unknown, acc, fn tag, acc ->
        [
          violation(
            :violation,
            :exclusion_allowlist_unknown_tag,
            "Suite excluded #{inspect(tag)}, which is not one of SuiteFloor's known " <>
              "exclusion-tag sources (#{inspect(known_exclusion_tags())}). A new @tag/--exclude " <>
              "pair must be added to SuiteFloor's allowlist deliberately (D-14), or removed if " <>
              "it should not be excluded at all."
          )
          | acc
        ]
      end)

    Enum.reduce(missing, acc, fn tag, acc ->
      [
        violation(
          :violation,
          :exclusion_allowlist_dead_entry,
          "SuiteFloor expects schema #{inspect(schema)} to exclude #{inspect(tag)}, but this " <>
            "run's effective --exclude set does not contain it. Either the tag is dead (remove " <>
            "it from SuiteFloor's allowlist) or this run's exclusion configuration regressed (D-14)."
        )
        | acc
      ]
    end)
  end

  # `mix test --only foo` is ExUnit's `exclude: [:test], include: [foo]` pair,
  # so `:test` in the exclusion set alongside a non-empty include set is the
  # mechanism of scoping a run, not a category anyone stopped covering. A bare
  # `--exclude test` with no include set is NOT discounted — see the moduledoc.
  defp discount_only_mode_marker(unknown, inclusion) do
    if MapSet.member?(unknown, :test) and MapSet.size(inclusion) > 0 do
      MapSet.delete(unknown, :test)
    else
      unknown
    end
  end

  # The executed floor, the growth nudge and the skipped ceiling are all claims
  # about a COMPLETE suite run. On a deliberately scoped run they are not
  # merely uninformative, they are false — so they are not computed at all,
  # and `print_report/4` states that they were not, naming the variable that
  # would have turned them on. Silence would be the wrong answer here; so
  # would a violation.
  defp full_suite_violations(acc, _executed, _skipped, _schema, false), do: acc

  defp full_suite_violations(acc, executed, skipped, schema, true) do
    acc
    |> floor_violation(executed, schema)
    |> nudge_warning(executed, schema)
    |> ceiling_violation(skipped)
  end

  # An unpinned schema axis is checked BEFORE the arithmetic. `executed_floor/1`
  # answers 0 for an unknown schema and `executed >= 0` always holds, so a new
  # D-06 schema axis added without pinning its floor would pass vacuously —
  # a check silently reporting green on a subject it has never measured.
  defp floor_violation(acc, executed, schema) when is_map_key(@executed_floors, schema) do
    floor = executed_floor(schema)

    if executed >= floor do
      acc
    else
      [
        violation(
          :violation,
          :executed_floor,
          "Only #{executed} test(s) executed on schema #{inspect(schema)}, below the pinned " <>
            "floor of #{floor}. Tests were silently lost or newly excluded — see SuiteFloor's " <>
            "moduledoc for how this floor is measured and pinned."
        )
        | acc
      ]
    end
  end

  defp floor_violation(acc, executed, schema) do
    [
      violation(
        :violation,
        :executed_floor,
        "No executed floor is pinned for schema #{inspect(schema)} (pinned axes: " <>
          "#{inspect(pinned_schemas())}), so this run's #{executed} executed test(s) were " <>
          "compared against nothing. A new schema axis must pin its own floor from a green " <>
          "CI run (D-16/D-27) — an unmeasured axis must not pass vacuously."
      )
      | acc
    ]
  end

  defp nudge_warning(acc, executed, schema) when is_map_key(@executed_floors, schema) do
    floor = executed_floor(schema)

    if executed > floor + @nudge_margin do
      [
        violation(
          :warning,
          :executed_nudge,
          "Executed #{executed} test(s) on schema #{inspect(schema)}, #{executed - floor} above " <>
            "the pinned floor of #{floor} — more than the #{@nudge_margin}-test nudge margin. " <>
            "Advisory only (a growing suite is expected and welcome); consider re-pinning the " <>
            "floor deliberately if this reflects a genuine new baseline."
        )
        | acc
      ]
    else
      acc
    end
  end

  # An unpinned schema has no floor to nudge against; `floor_violation/3`
  # already reported it as a violation, which is the stronger signal.
  defp nudge_warning(acc, _executed, _schema), do: acc

  defp ceiling_violation(acc, skipped) do
    if skipped <= @skipped_ceiling do
      acc
    else
      [
        violation(
          :violation,
          :skipped_ceiling,
          "#{skipped} test(s) were skipped, above the pinned ceiling of #{@skipped_ceiling}. " <>
            "`skipped == 0` is rejected as a target (D-16) — a NEW skip must be pinned " <>
            "deliberately, not silently absorbed."
        )
        | acc
      ]
    end
  end

  # D-17. Combined raw badmatch + composed LeakError count — see
  # `SuiteTruthFormatter.signature/1`'s @doc for why both are counted as one.
  defp already_shared_violation(acc, :cannot_verify) do
    [
      violation(
        :violation,
        :already_shared,
        "SuiteTruthFormatter's signature tally could not be read — the formatter process was " <>
          "not found. A check that cannot observe its subject must not report green; this is " <>
          "reported as unverifiable rather than as zero."
      )
      | acc
    ]
  end

  defp already_shared_violation(acc, 0), do: acc

  defp already_shared_violation(acc, count) when is_integer(count) and count > 0 do
    [
      violation(
        :violation,
        :already_shared,
        "Sandbox ownership leaked #{count} time(s) this run (:already_shared, raw badmatch and " <>
          "the composed SandboxOwnership.LeakError combined) — exactly zero is required (D-17)."
      )
      | acc
    ]
  end

  defp formatter_violation(acc, :cannot_verify) do
    [
      violation(
        :violation,
        :formatter_violations,
        "SuiteTruthFormatter's own hygiene-violation count could not be read — the formatter " <>
          "process was not found. Reported as unverifiable rather than as zero."
      )
      | acc
    ]
  end

  defp formatter_violation(acc, 0), do: acc

  defp formatter_violation(acc, count) when is_integer(count) and count > 0 do
    [
      violation(
        :violation,
        :formatter_violations,
        "SuiteTruthFormatter recorded #{count} module-boundary hygiene violation(s) this run " <>
          "(pool_mode_leaked / config_schema_drift / baseline_missing / cannot_verify) — see the " <>
          "trace output (MAILGLASS_SANDBOX_TRACE=1) for which module and class."
      )
      | acc
    ]
  end

  defp violation(kind, name, message), do: %{kind: kind, name: name, message: message}

  # The lane's declaration that this run IS the complete suite the pinned
  # thresholds describe. Set by the two `advisory-matrix.yml` full-suite steps
  # (HARNESS-03) and asserted still present by
  # `test/scripts/lane_classification_drift_test.exs`. Carries both roles —
  # evaluate the full-suite-scoped checks, and halt on a violation — because
  # both answer the same question; see the moduledoc.
  defp full_suite?, do: System.get_env("MAILGLASS_SUITE_FLOOR") == "1"

  # ──────────────────────────────────────────────────────────────
  # Internal — reading the formatter's state across the process boundary
  # ──────────────────────────────────────────────────────────────

  defp read_formatter_tally do
    case SuiteTruthFormatter.current_state() do
      %{signature_tally: tally, violations: hygiene_violations} ->
        already_shared = Map.get(tally, :already_shared, 0)
        {already_shared, length(hygiene_violations)}

      :unavailable ->
        {:cannot_verify, :cannot_verify}
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Internal — reporting (always runs; never gated on full_suite?/0)
  # ──────────────────────────────────────────────────────────────

  defp print_report(schema, augmented, found, run_scope) do
    executed = augmented.total - augmented.excluded - augmented.skipped

    IO.puts([
      "\n== Mailglass.TestSupport.SuiteFloor (schema ",
      inspect(schema),
      ") ==\n",
      "  total: ",
      Integer.to_string(augmented.total),
      ", excluded: ",
      Integer.to_string(augmented.excluded),
      ", skipped: ",
      Integer.to_string(augmented.skipped),
      ", executed: ",
      Integer.to_string(executed),
      ", failures: ",
      Integer.to_string(augmented.failures)
    ])

    IO.puts(
      "  signature tally: already_shared=#{inspect(augmented.already_shared)}, " <>
        "formatter_violations=#{inspect(augmented.formatter_violations)}"
    )

    IO.puts("  scope: " <> scope_line(schema, run_scope))

    case found do
      [] ->
        IO.puts("  0 violation(s).")

      entries ->
        Enum.each(entries, fn %{kind: kind, name: name, message: message} ->
          prefix = if kind == :violation, do: "[VIOLATION]", else: "[WARNING]"
          IO.puts("  #{prefix} #{name}: #{message}")
        end)
    end
  end

  # States which contract this run was held to, in both directions. A reader
  # who expected a full-suite lane to enforce can see at a glance that it did
  # not declare itself one — which is the whole point of printing the line
  # rather than quietly skipping three checks.
  defp scope_line(schema, %{full_suite?: true}) do
    "FULL SUITE (MAILGLASS_SUITE_FLOOR=1) — executed floor #{executed_floor(schema)}, " <>
      "skipped ceiling #{@skipped_ceiling} enforced; a violation halts this run."
  end

  defp scope_line(_schema, %{full_suite?: false}) do
    "scoped run (MAILGLASS_SUITE_FLOOR unset) — the executed floor, growth nudge and " <>
      "skipped ceiling describe a COMPLETE suite and were not evaluated. The exclusion " <>
      "allowlist and the :already_shared / formatter assertions above did run, and nothing " <>
      "halts this run."
  end
end
