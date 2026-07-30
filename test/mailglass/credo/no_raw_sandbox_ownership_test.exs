defmodule Mailglass.Credo.NoRawSandboxOwnershipTest do
  use ExUnit.Case, async: true

  # HARNESS-01: the prevention half of the two-layer recurrence guard (see
  # `Mailglass.TestSupport.SuiteTruthFormatter` for the detection half).
  #
  # This scaffold is deliberately empty pending Task 2, which fills it with
  # the check's fixture corpus (fully-qualified / aliased / `as:`-renamed
  # forbidden-call cases, the two allowlisted modules, the path filter, the
  # deliberate non-copy of the analog's bare-tail over-match, and the
  # `Sandbox.allow/3` non-forbidden case).
  #
  # Task 1's own job was answering RESEARCH.md Open Question 5 — whether
  # `mix credo --strict` actually reaches `test/**/*.exs` and `test/support/*.ex`
  # before this check is built on top of that assumption. It does: confirmed
  # with a deliberately-violating scratch file under each path shape (run
  # through the existing, unscoped `Mailglass.Credo.NoPiiInTelemetryMeta`
  # check, which carries no `included_path_prefixes` filter), both flagged by
  # exact file path, both removed afterward. See the "Task 1" section of
  # `.planning/phases/143-test-harness-truth/143-08-SUMMARY.md` for the exact
  # scratch content and reported output.
end
