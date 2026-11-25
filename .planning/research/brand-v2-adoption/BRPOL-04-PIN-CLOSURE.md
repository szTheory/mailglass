# BRPOL-04 Pin Closure

## Canonical pin

The current canonical archive is the owner-approved brand v2.0.1 zip from commit `677b9d300e0da01abb199076b301bae36447d2da`, SHA-256 `3bd4369e0668f89c48bc0755ec3e06be2f1aacf07446dc568b2a248d4c9d0a56`. Its immutable URL is `https://raw.githubusercontent.com/szTheory/mailglass-brand/677b9d300e0da01abb199076b301bae36447d2da/mailglass-brand.zip`. The favicon source and Admin-served bytes both have SHA-256 `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5`.

The approved correction and its boundary are recorded in [BRPOL-04-PIN-DECISION.md](BRPOL-04-PIN-DECISION.md). It supersedes only the archive identity in the historical D-16 record; the immutable source commit and commit-derived URL rule remain intact. This evidence does not assert trademark clearance or resolve Phase 183's browser-producer provenance.

## Source consistency

**Observed:** 2026-11-17 23:10:31 UTC at checkout revision `493d01e3e767c2067115132776c905559016f5a5`.

**Worktree:** `git status --short` returned 73 entries before this evidence file was created. SHA-256 of that exact status output was `86f82699898109cdc16ddc96209c55fa8b5156bc23af6931be5d35cc72e4db2c`. The checkout already contained unrelated uncommitted work. No files under the pin, brand assets, test oracle or accepted favicon catalog were edited for this check.

The automated cross-source comparison passed. It checked the live BRPOL-04 row and Phase 179 criterion 4 against the approved correction, `brandbook/brand.pin.json`, the independent `@expected_zip_sha256` test literal, and the source/Admin-served favicon bytes. Command: the Python assertions in Task 1 of [179-05-PLAN.md](../../phases/179-compatibility-policy-status-map-and-brand-pin/179-05-PLAN.md), run from the repository root. Result: `PASS: approved decision, live BRPOL-04, Phase 179 SC4, manifest, independent test literal and source/served favicon agree`.

### Input fingerprints

SHA-256 values below identify the exact files read by this reconciliation at the observation time above. The closure file's own digest is excluded to avoid a self-reference.

| Input | Bytes | SHA-256 |
|---|---:|---|
| `.planning/REQUIREMENTS.md` | 8,178 | `f91eae4ae6076dba308ede614644b56d3b983c57216d29ccd654c4aca445d1da` |
| `.planning/ROADMAP.md` | 24,687 | `8625814d58cd6405c6d36188521d08fa80a96ea311bbfd883336e36757d74aa1` |
| `.planning/research/brand-v2-adoption/BRPOL-04-PIN-DECISION.md` | 2,410 | `31e8989f2bae82c5d065b881e98aa0129298d5bf7d05a352fbb99981d6d1e82d` |
| `brandbook/brand.pin.json` | 7,416 | `5d853e8ba0788528879241fe4f27e6df0e5f4f181270d2f8fcf480aeab088950` |
| `brandbook/v2/brand.json` | 49,765 | `db98e7a10c7f7873dee61139048cb788b0f7cea9ddd66e28a04a3661b0629b30` |
| `brandbook/v2/favicon.svg` | 783 | `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5` |
| `mailglass_admin/priv/static/favicon.svg` | 783 | `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5` |
| `test/scripts/brand_pin_test.exs` | 43,650 | `7d8e5aaae64989e2416e9acc4611a61edeb2abff57d72cb2078aff3711ec5201` |
| Accepted catalog `manifest.json` | 42,100 | `ef614ecee58a440887d1bfbede7f777d31f97ab37b61acf82c4e7d0d6c204e11` |

The pin records version `2.0.1`, the approved source commit and archive hash above. Its archive URL is commit-derived. The pin, test oracle, source/served assets, accepted catalog and historical Phase 179 plans/summaries are protected by the before/after inventory recorded for this task in the execution summary.

## Focused offline contract

Task 2 ran the existing test without source or test edits. The exact command was `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/scripts/brand_pin_test.exs --warnings-as-errors --seed 0`, launched in the background from the repository root.

- Attempt 1's ExUnit output showed `76 tests, 0 failures`, but a zsh read-only `status` variable in the wrapper prevented it from recording the process exit code. The shell issue was diagnosed; it was not a test failure.
- Attempt 2 used a corrected Bash wrapper and recorded exit code `0`, `76 tests, 0 failures`, elapsed time 4 seconds, start `2026-11-17T23:13:14Z`, finish `2026-11-17T23:13:18Z`. Log: `/private/tmp/phase179-brand-pin-test-final.log`; metadata: `/private/tmp/phase179-brand-pin-test-final.meta`.
- The output also contained the pre-existing warning that `opentelemetry_exporter` is not available. It did not affect the focused test result.
- SHA-256 of the exact Attempt 2 log is `7ccb73033bd968ec0e8e925865390dd76dc4434d6fe0ca92dfe41e483b5d8e46`.

Exact Attempt 2 stdout/stderr:

```text
18:13:15.088 [warning] OTLP exporter module `opentelemetry_exporter` not found. Verify you have included the `opentelemetry_exporter` dependency.
Running ExUnit with seed: 0, max_cases: 36
Excluding tags: [:phase_164_installed_production_boundary, :phase_165_installed_production_boundary, :phase_165_controlled_host]

............................................................................
Finished in 3.0 seconds (3.0s async, 0.00s sync)
76 tests, 0 failures

== Mailglass.TestSupport.SuiteFloor (schema "public") ==
  total: 76, excluded: 0, skipped: 0, executed: 76, failures: 0
  signature tally: already_shared=0, formatter_violations=0
  scope: scoped run (MAILGLASS_SUITE_FLOOR unset) — the executed floor, growth nudge and skipped ceiling describe a COMPLETE suite and were not evaluated. The exclusion allowlist and the :already_shared / formatter assertions above did run, and nothing halts this run.
  0 violation(s).
```

The exact post-test inventory compared 39 protected path entries against the pre-task baseline. All matched: the pin file SHA-256 is `5d853e8ba0788528879241fe4f27e6df0e5f4f181270d2f8fcf480aeab088950`; the test oracle SHA-256 is `7d8e5aaae64989e2416e9acc4611a61edeb2abff57d72cb2078aff3711ec5201`; and all 109 files in the accepted favicon catalog are unchanged, with aggregate tree SHA-256 `32b3741505a4599b26ecd7ad7cfb6894c0ad9bcd59567b080fe6b8c5efd83e1f`. The pinned source and served assets, other shipped brand assets and historical Phase 179 plans/summaries/context/research also match byte-for-byte. No capture or browser alias ran.

## Limits and handoff

This closes only the stale BRPOL-04 acceptance-identity mismatch, subject to fresh Phase 179 re-verification. It does not authenticate the Phase 183 browser producer, clear the trademark caution, or alter the approved pin. The accepted favicon catalog and its PNGs remain unchanged; do not recapture, rewrite a manifest, loosen producer validation or rerun the blocked alias. Immediately after Task 2 and before the first evidence commit, `git status --short` had 74 entries and SHA-256 `1fcf575f249e3dffb3f6232f6716abe12319c285f021deb4f2807615c5a9d3d8`; the sole task-created path was this evidence file. After adding the exact test output and completing the final inventory, status still had 74 entries and SHA-256 `d04f6ad526fae6103aa2b58e4e385eb535226f8e877315bcddecce6c8188c689`; this evidence file was the only task-owned working-tree change. The other 73 pre-existing entries were preserved.
