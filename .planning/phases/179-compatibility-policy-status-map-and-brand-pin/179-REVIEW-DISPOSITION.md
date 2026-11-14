---
phase: 179-compatibility-policy-status-map-and-brand-pin
review: 179-REVIEW.md
updated: 2026-11-14
---

# Phase 179 — Code Review Disposition

Advisory ledger. One row per finding; `open` means seen and not yet acted on.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| CR-01 | critical | fixed | CLI entrypoints in `scripts/brand_pin.exs` and `scripts/brand_trademark_gate.exs` no longer gate on `Mix.env()`; tests opt into library mode via `Application.put_env(:mailglass, :script_library_mode, true)`. Subprocess regression tests run each CLI under `MIX_ENV=test`; the trademark one was mutation-proven red against the old guard. `scripts/reconcile_release_versions.exs:777` has the same latent guard (outside phase scope, open). |
| WR-01 | warning | open | Gate allows `overall: "clear"` with a required register at `caution`. Harden before Phase 183 depends on the gate; moot while the record is `caution`. |
| WR-02 | warning | open | No `date <= today` check, no `expires` bound; `--today`/`--path` can bypass expiry. Same hand-off as WR-01. |
| WR-03 | warning | open | Policy lists names `api_stability.md` calls internal. Needs a scope decision on the "stays" table. |
| WR-04 | warning | open | `grep`-kind rows match moduledoc text in `router.ex`. |
| WR-05 | warning | open | `copy_contract_test` Part B "without a test edit" promise contradicts its own `wired == false` assertion. |
| WR-06 | warning | open | Part B keyed on atom alone; would collide with inbound `:rejected`/`:bounced`. Phase 182 hand-off. |
| WR-07 | warning | open | `delivery_class/1` returns `:failed` for suppressed + terminal. |
| WR-08 | warning | open | Operator projections lack fields `delivery_class/1` needs; already recorded as a Phase 182 limitation in 179-01-SUMMARY. |
| WR-09 | warning | open | `brand_pin_test.exs` `update` CLI case runs against the real tree despite header. |
| IN-01 | info | open | Duplicated `insert_suppression!/2` helper. |
| IN-02 | info | open | Raw U+00A0 literal in `brand_v2_compat_policy_test.exs`. |
| IN-03 | info | open | Trademark-symbol scan covers markdown only. |
| IN-04 | info | open | `Copy` comment/binding looseness. |
| IN-05 | info | open | Minor `brand_pin.exs` gaps. |
