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

  ## PLACEHOLDER floors and ceiling (D-27) — read before touching these constants

  The per-schema executed floors and the skipped ceiling below are
  deliberately unpinned placeholders, not measurements. This repo's local
  toolchain is Elixir 1.19.5 / OTP 28; every gating and required lane runs
  Elixir 1.18.4 / OTP 27. A number measured by running the suite locally
  would be pinning the WRONG leg of the matrix the floor is supposed to
  guard — D-27 forbids it explicitly. Plan `143-10` pins the real values from
  green CI runs on the 1.18/OTP 27 leg. The pre-fix ledger numbers
  (`143-RESEARCH.md`'s "Measured baselines": 1430 executed on `public`, 1429
  on `mailglass`, both from a RED, pre-fix run) are sanity bounds for that
  later measurement, and MUST NOT be copied into these constants as if they
  were the real floor — a pre-fix, red-run count is not a target.

  ## Enforcement is opt-in; reporting is not (D-15, D-18)

  `install/0` registers `check/1` as an `ExUnit.after_suite/1` callback.
  Every run — a full lane, a focused `mix test path/to/one_test.exs`, a
  `mix verify.*` alias — prints its counts and any computed violations,
  unconditionally. Only when `System.get_env("MAILGLASS_SUITE_FLOOR") ==
  "1"` does a violation turn into a non-zero exit (`System.halt/1`). Read at
  runtime via `System.get_env/1` — never at compile time via any
  `Application` config-macro variant (CLAUDE.md's "Don't use compile-time
  config reads outside `Mailglass.Config`" rule). This is what lets a
  focused local run or a `mix verify.*`
  alias never misfire while the numbers stay fully visible — and it is why
  the placeholder values above are safe to leave in place before `143-10`
  pins them: nothing enforces against them until the two
  `advisory-matrix.yml` full-suite steps set the env var.

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

  ## The signature tally (D-17) — landed in plan `143-09` Task 2

  `already_shared` (raw badmatch AND the composed `SandboxOwnership.LeakError`
  combined) and the formatter's own hygiene-violation count join the pipeline
  once `Mailglass.TestSupport.SuiteTruthFormatter`'s classifier and
  cross-process read path exist (this same plan's Task 2). See that module's
  moduledoc for the other half of that read path.
  """

  # ──────────────────────────────────────────────────────────────
  # Constants
  # ──────────────────────────────────────────────────────────────

  # The complete set of tokens either `advisory-matrix.yml`'s
  # `--exclude requires_workspace` or `test_helper.exs`'s conditional
  # `ExUnit.configure(exclude: [:public_only])` can produce. Answers "is this
  # tag one of the two legitimate sources," not "does THIS schema expect it"
  # — see `expected_exclusion_tags/1` for the schema-aware half.
  @known_exclusion_tags MapSet.new([:requires_workspace, :public_only])

  # PLACEHOLDER (D-27). 0 for both schemas is deliberately non-representative
  # — `executed >= 0` always holds, so this constant never meaningfully
  # enforces anything until plan 143-10 replaces it with a number measured
  # from a green 1.18/OTP 27 CI run. Do NOT put the pre-fix ledger numbers
  # (1430 public / 1429 mailglass — both from a RED run) here; see the
  # moduledoc.
  @executed_floors %{
    "public" => 0,
    "mailglass" => 0
  }

  # PLACEHOLDER (D-27/D-16). A large, obviously-fake sentinel — `skipped <=
  # 1_000_000_000` always holds, so this never meaningfully enforces before
  # plan 143-10 measures the real ceiling. `skipped == 0` is explicitly
  # REJECTED as a target: it is false today (the suite genuinely skips tests)
  # — see 143-RESEARCH.md for why the measured value (not a static grep of
  # `@tag :skip`) is what gets pinned.
  @skipped_ceiling 1_000_000_000

  # NOT a placeholder — a fixed design constant (D-16), independent of
  # whichever floor ends up pinned. Crossing `floor + 40` is a nudge into
  # `$GITHUB_STEP_SUMMARY`, never a build failure: a hard ceiling on suite
  # growth would fail on every single test added to the repo.
  @nudge_margin 40

  # The complete, closed vocabulary of violation/warning `:name` atoms
  # `violations/3` can produce. Exists so the contract test's anti-vacuity
  # guard can assert this set is non-empty without hardcoding a second copy
  # that could silently drift from the pipeline below. Task 2 (this same
  # plan) appends `:already_shared` and `:formatter_violations`.
  @violation_classes [
    :exclusion_allowlist_unknown_tag,
    :exclusion_allowlist_dead_entry,
    :executed_floor,
    :executed_nudge,
    :skipped_ceiling
  ]

  @type violation :: %{kind: :violation | :warning, name: atom(), message: String.t()}

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
  effective merged exclusion set from `ExUnit.configuration()`, and the
  current schema from `Mailglass.Config.schema()`. Always prints the counts
  and any computed violations. Enforces (non-zero exit via `System.halt/1`)
  only when `MAILGLASS_SUITE_FLOOR` is `"1"` AND at least one `kind:
  :violation` entry was produced — warnings never enforce.
  """
  @spec check(map()) :: :ok
  def check(results) when is_map(results) do
    effective_exclusion = ExUnit.configuration() |> Keyword.get(:exclude, []) |> MapSet.new()
    schema = Mailglass.Config.schema()

    total = Map.fetch!(results, :total)
    excluded = Map.fetch!(results, :excluded)
    skipped = Map.fetch!(results, :skipped)
    failures = Map.fetch!(results, :failures)

    augmented = %{
      total: total,
      excluded: excluded,
      skipped: skipped,
      failures: failures
    }

    found = violations(augmented, effective_exclusion, schema)

    print_report(schema, augmented, found)

    if enforce?() and Enum.any?(found, &(&1.kind == :violation)) do
      System.halt(1)
    end

    :ok
  end

  @doc """
  PURE. Takes the augmented results map (the four `ExUnit.after_suite/1`
  counts), the effective merged exclusion set, and the current schema.
  Returns a list of violation maps (`%{kind:, name:, message:}`) — `kind:
  :warning` entries (the nudge) are advisory and MUST NOT be treated as a
  build failure by any caller.

  Driven directly by `test/scripts/suite_floor_contract_test.exs`'s synthetic
  reports — the negative controls there exercise this SAME function, never a
  re-implementation, so a future edit that weakens this pipeline breaks its
  own negative controls too.
  """
  @spec violations(map(), MapSet.t(atom()), String.t()) :: [violation()]
  def violations(results, effective_exclusion, schema)
      when is_map(results) and is_binary(schema) do
    total = Map.fetch!(results, :total)
    excluded = Map.fetch!(results, :excluded)
    skipped = Map.fetch!(results, :skipped)
    _failures = Map.fetch!(results, :failures)

    executed = total - excluded - skipped

    []
    |> allowlist_violations(effective_exclusion, schema)
    |> floor_violation(executed, schema)
    |> nudge_warning(executed, schema)
    |> ceiling_violation(skipped)
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
  The pinned minimum `executed` count for `schema`. PLACEHOLDER (D-27) — see
  the moduledoc; plan `143-10` replaces this with a number measured from a
  green CI run on the required 1.18/OTP 27 leg.
  """
  @spec executed_floor(String.t()) :: non_neg_integer()
  def executed_floor(schema), do: Map.get(@executed_floors, schema, 0)

  @doc """
  The pinned maximum `skipped` count, across all legs. PLACEHOLDER (D-27) —
  see the moduledoc.
  """
  @spec skipped_ceiling() :: non_neg_integer()
  def skipped_ceiling, do: @skipped_ceiling

  @doc """
  The warn-only nudge margin (D-16): `executed > executed_floor(schema) +
  nudge_margin()` prints a `$GITHUB_STEP_SUMMARY`-bound warning, never a
  build failure.
  """
  @spec nudge_margin() :: non_neg_integer()
  def nudge_margin, do: @nudge_margin

  @doc """
  The complete, closed vocabulary of `:name` atoms `violations/3` can
  produce. See the module attribute of the same name for the rationale.
  """
  @spec violation_classes() :: [atom()]
  def violation_classes, do: @violation_classes

  # ──────────────────────────────────────────────────────────────
  # Internal — the pure pipeline
  # ──────────────────────────────────────────────────────────────

  defp allowlist_violations(acc, effective_exclusion, schema) do
    unknown = MapSet.difference(effective_exclusion, @known_exclusion_tags)
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

  defp floor_violation(acc, executed, schema) do
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

  defp nudge_warning(acc, executed, schema) do
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

  defp violation(kind, name, message), do: %{kind: kind, name: name, message: message}

  defp enforce?, do: System.get_env("MAILGLASS_SUITE_FLOOR") == "1"

  # ──────────────────────────────────────────────────────────────
  # Internal — reporting (always runs; never gated on enforce?/0)
  # ──────────────────────────────────────────────────────────────

  defp print_report(schema, augmented, found) do
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
end
