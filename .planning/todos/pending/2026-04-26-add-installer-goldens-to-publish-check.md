---
created: 2026-04-26T17:55:00.000Z
title: Add installer golden test to `mix mailglass.publish.check` so version bumps don't ambush post-merge CI
area: release-engineering
files:
  - lib/mix/tasks/mailglass.publish.check.ex
  - test/mailglass/install/install_golden_test.exs
  - .github/workflows/publish-hex.yml:64-77 (prepublish-summary calls publish.check)
priority: v0.1.2
---

## Problem

The v0.1.1 publish was blocked by a CI failure on the merge commit
(c5169d6) because the installer golden snapshot embedded the package
version string `installer_version = "0.1.0"` and the bump to v0.1.1
changed that literal in two places. Pure version-string drift, no
semantic regression — but the failure surfaced at the WORST moment:
**after PR #10 had already squash-merged and tags had been created**,
forcing a force-tag recovery operation.

The pre-publish gate (`mix mailglass.publish.check`, run by
`prepublish-summary` in publish-hex.yml) inspected the tarball
manifest, the deps, the version pin — but did NOT run the installer
golden test. So pre-publish saw nothing wrong; post-merge CI did.

## Fix

Add a dry-run of the installer golden test to `mix mailglass.publish.check`,
gated such that it only runs when `MIX_PUBLISH=true` (matching the
existing convention for publish-time-only checks).

Pseudocode:

```elixir
defp check_installer_goldens(ctx) do
  # Run the golden test in dry-run mode. We don't WRITE goldens here
  # (that's a maintainer action); we just verify the snapshot matches
  # what the installer currently emits. If it doesn't, fail with a
  # specific actionable error pointing at the regen command.
  {output, exit_code} =
    System.cmd("mix", ["test", "test/mailglass/install/install_golden_test.exs"],
      env: [{"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )

  if exit_code != 0 do
    {:error,
     %Mailglass.Error{
       type: :publish_blocked_golden_drift,
       message: """
       Delivery blocked: installer golden snapshot is out of sync with
       installer output. This usually happens after a version bump
       changes the literals embedded in the generated mix.exs / config.

       Run:
         MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors

       Then commit test/example/README.md and re-publish.

       Failure detail:
       #{output}
       """
     }}
  else
    :ok
  end
end
```

Wire into the existing `mix mailglass.publish.check` flow alongside the
other gates.

## Why this matters

- v0.1.1 cycle cost ~30 minutes of unplanned recovery (force-tag,
  re-dispatch). v0.1.2+ should not repeat this pattern.
- Every version bump touches the goldens. This is not an edge case —
  it's the steady-state behavior. A pre-publish check is the right
  place for a steady-state precondition.
- Running the golden test inside `publish.check` is cheap (~50ms per
  the test runtime observed locally) and the test is already
  deterministic (no flakes seen across the v0.1.0/v0.1.1 cycles).

## Acceptance criteria

- `mix mailglass.publish.check` fails fast with a clear error when
  installer goldens drift.
- The error message includes the exact regen command.
- The check runs as part of `prepublish-summary` in publish-hex.yml
  (no workflow change needed — the existing job calls publish.check).
- Optional: also wire into `mix verify.installer` (formerly
  `verify.phase_07`, see the rename TODO) so local-dev also catches
  this before push.

## Belt-and-suspenders

Consider also adding a CI lane that runs `MIX_INSTALLER_ACCEPT_GOLDEN=1`
in PR-only mode (NOT main) and fails if the diff is non-empty after
running. That makes the goldens drift visible during PR review rather
than after merge.
