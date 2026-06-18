---
quick_id: 260618-1qj
description: De-hardcode trust-lane baseline so dep/version bumps are zero-touch
status: complete
date: 2026-06-18
---

# Quick Task 260618-1qj — Summary

Removed the "coordinated 5-file hand-edit" friction behind thread
`release-pipeline-maintenance.md` item 2 (the last open item). Commit `7cbef50b`;
CI green on main — **both Trust Lane jobs (Repo Head + Clean Baseline) success**.

## Root cause of the fiddliness

Two places hardcoded exact sibling versions, forcing a manual sync on every release:
- `scripts/check_clean_baseline_hex_only.sh` — `required = [{"mailglass", :hex, "1.4.5"}, ...]`
- `test/mailglass/publish/ci_trust_lane_contract_test.exs` — `1.4.5`/`1.1.5` literals in fixtures/regexes

(Plus the baseline was silently frozen at **1.4.5** — three minors behind the published 1.7.0 — so
the trust lane was exercising stale code.)

## Change (commit `7cbef50b`, 6 files)

- **Guard made version-agnostic:** assert each sibling resolves via `:hex` with a well-formed
  (non-empty) version string; dropped the version literal. The committed `mix.lock` stays the
  reproducible pin; the guard enforces the property that matters — "real Hex consumer, not a
  `path:`/`git:` dep."
- **Contract test version-agnostic:** version-agnostic regexes; repurposed the old "rejects stale
  version" test into "rejects a non-Hex (path/git) source." Kept malformed/security/non-tuple tests.
- **Widened pins** `reference/{host_app,demo_app}/mix.exs` `~> 1.4`/`~> 1.1` → `~> 1.0` (floor is
  cosmetic; the lock pins the real version).
- **Refreshed both locks** 1.4.5/1.4.5/1.1.5 → **1.7.0/1.7.0/1.4.0** (current published). Surgical
  diffs (host 9 lines, demo 10 — siblings + the transitive bumps 1.7.0 pulls). The previous
  swoosh-lock-drift footgun is now moot (swoosh→1.26.1 is intentional, matches root).

## Validation

- Guard against refreshed host_app lock → exit 0, "Hex-first OK" ×3 (now 1.7.0).
- Contract test → 5/5 green (against both the old 1.4.5 and refreshed 1.7.0 locks).
- `host_app` compiles clean against mailglass 1.7.0 / admin 1.7.0 / inbound 1.4.0.
- CI on main (`7cbef50b`): **Trust Lane Repo Head + Trust Lane Clean Baseline both success.**

## Result — zero-touch going forward

Future releases need NO baseline babysitting. To refresh the baseline to a newer published version:
```
cd reference/host_app && mix deps.update mailglass mailglass_admin mailglass_inbound
cd reference/demo_app && MAILGLASS_DEMO_DEPS=hex mix deps.update mailglass mailglass_admin mailglass_inbound
```
No script/test/pin edits. **This was the "5-file change" done one final time — and the change makes
all future ones unnecessary.** Closes thread item 2; thread `release-pipeline-maintenance.md` now
fully resolved.

## Considered + rejected
- Wiring the lock refresh into the release pipeline — optional future automation; it's a single
  command today, not worth the moving parts now.
