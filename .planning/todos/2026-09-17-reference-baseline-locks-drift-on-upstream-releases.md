---
created: 2026-09-17T16:52:00.000Z
title: Frozen reference baselines go red on someone else's release schedule
area: ci-cd
files:
  - reference/demo_app/mix.lock
  - reference/host_app/mix.lock
  - .github/workflows/ci.yml (Install demo deps step, `mix deps.get --check-locked`)
  - scripts/check_clean_baseline_hex_only.sh
priority: backlog
---

## Problem

`reference/demo_app` and `reference/host_app` are frozen deterministic
baselines that resolve from Hex with `~>` requirements. Nothing pins
their transitive deps exactly, so `mix deps.get --check-locked` starts
failing whenever an upstream package publishes a new version — with no
commit in this repo at all.

Two occurrences so far:

- `phoenix` 1.8.13 stopped resolving; two required jobs went red.
- `boundary` 0.11.0 shipped **between two CI runs of the same PR**
  (#276), taking Support Contract Core and Core Deterministic Suite
  down. Fixed by a one-line lock refresh, `f2ceb4af`.

Each time the fix is a one-line lock bump, so it looks cheap. The real
cost is that an unrelated PR goes red at an arbitrary moment for a
reason that has nothing to do with it, and whoever is mid-ceremony has
to diagnose it from scratch. During the 2.6.0 release close-out this
cost a full CI cycle.

## Fix — pick one

- **Pin exactly.** Give the baselines `==` requirements so they are
  genuinely frozen and only move when someone means to move them. Most
  faithful to what "frozen deterministic baseline" already claims, and
  it makes the drift visible as a deliberate commit rather than a
  surprise red.
- **Scheduled refresh.** A cron job that runs `mix deps.get` in both
  baselines and opens a `chore(deps):` PR when the lock moves. Keeps
  the baselines current but moves the red off the critical path.
- **Tolerate drift in the gate.** Drop `--check-locked` for the
  reference lane. Rejected on sight: that gate is what makes the
  baseline deterministic, and weakening a control to stop it reporting
  is how the determinism claim quietly becomes false.

Note the coupling before changing pins: the *mailglass* pins in these
baselines are a coordinated five-file change (2 mix.exs + 2 mix.lock +
`check_clean_baseline_hex_only.sh` + `ci_trust_lane_contract_test.exs`).
Third-party deps like `boundary` are not coupled that way.
