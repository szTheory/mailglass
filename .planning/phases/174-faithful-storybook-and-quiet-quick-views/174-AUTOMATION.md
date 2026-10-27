# Phase 174 — Automated Acceptance Closure

Owner instruction, 2026-10-27: target zero human verification/UAT; automate observable acceptance and retain proof so it is not handed back again. This reaffirms D-52 in PROJECT.md, METHODOLOGY.md and STATE.md. It supersedes the three former owner checkpoints without claiming owner approval.

## Acceptance and evidence

| Former checkpoint | Executable proof | Result |
| --- | --- | --- |
| 14 current contrast incomplete findings and 36 focus sentinels | Admin selected Storybook sweep, rendered-color measurements of all 242 retained contrast targets, real Tab/Shift+Tab wrap in all 18 cases | Pass in cold and warm. Minimum measured ratio 5.26377889458762. Axe still records 50 incomplete findings separately; zero violations, unapproved or untriaged findings. |
| Missing transparency prohibition enforcement | `scripts/phase174-review-claims.test.cjs`, called summary boundary in the real evidence checker, GSD descriptor in 174-05-PLAN.md | Pass. GSD independently observed assertion failures against the known-bad subject and a clean pass against the real module. No unexecuted/advisory evidence becomes required CI proof or owner approval. |
| Narrow Storybook theme chrome | Both templates reserve a 96px control band; existing responsive cases assert non-overlap and bounds at 320/375/768/1280/1440px, both themes; agent inspected saved narrow captures | Pass: 20 responsive cases per condition; theme controls retain 44px targets. No owner aesthetic score is inferred. |

The no-overlap assertion first reproduced a genuine defect (picker bottom 85px, dialog top 61px). The narrow matrix then caught wrapping in the actual 270px iframe. Both were repaired before the passing sweep. Selected iframe readiness now waits for the connected host, fonts, settled entry animation and a stable visible frame, avoiding host occlusion and stale remount handles. The contrast helper fails closed on unsupported paint; daisyUI's `auto, 0%` noise layer is proven unpainted by its computed size.

## Fresh run and replay

Run: `mailglass-evidence-20261027131817-50319-18180`. Base revision: `bf4baa5fee1ca53be3038daa44cfd1f8b10e737e` with the edited working tree, bound by source digest `71f4452a8221b45bc6aa7dbf27744fe93e5df966ed378b831677c3a3fab703ef`. `phase174/execution.json#source` retains the exact path/byte/hash inputs. The digest was recomputed after the run and matched the current selected source. Historical hosted run 40498413906 belongs to the earlier implementation revision; no new hosted success is claimed.

Each condition expected/executed 98 Demo + 6 hook + 26 fidelity + 18 axe = **148/148** acceptance cases. Cold and warm both passed, including all supplemental checks. The archive contains byte-identical copies of the 14 checker inputs, a file hash manifest, the checked summary and the prohibition request/result. It remains replayable after temporary Docker evidence or hosted artifacts expire:

```sh
node scripts/check_phase174_evidence.cjs --evidence-dir .planning/phases/174-faithful-storybook-and-quiet-quick-views/artifacts/automated-uat --pilot
node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check prohibition-enforcement .planning/phases/174-faithful-storybook-and-quiet-quick-views/artifacts/automated-uat/prohibition-request.json --raw
node --test scripts/check_phase174_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs
```

Fresh full reproduction uses `bash scripts/run_demo_browser_evidence.sh --phase174 --pilot`. The wrapper owns its unique Compose project, resets, ports, cold/warm caches and cleanup. Existing unrelated demo services and workspace edits were preserved.

## Recurring placement and validation

The existing advisory Demo Browser Evidence job runs the selected browser assertions and the 31 fast Node contract checks. The local GSD regression gate also runs those contract checks. No dependency, extra CI lane or required-context change was introduced. The evidence checker now emits an explicit review summary: environment local/hosted, tier advisory, required_ci_proof false and owner_approval false.

Additional validation passed: six native fidelity browser tests (including the 20-case width matrix), 18 native selected axe cases, three ExUnit CI-wiring contracts, the wrapper seam test, actionlint, Bash syntax, Elixir story formatting and git diff whitespace checks. These supplement the complete isolated cold/warm run.

Local measured wall time: cold 276,262ms; warm 127,562ms; entire pilot 406,849ms including cleanup. Local runner minutes and added hosted cost are unmeasured. The previous hosted 14-second provisional added-wall overage remains a historical disclosed observation, not a newly measured cost or waived gate.

## Durable disposition

All three UAT rows close with source automated. No owner confirmation is required. Reopen only for a relevant implementation/acceptance change or fresh failing evidence; do not regenerate the former subjective queue or treat incomplete axe outcomes as passes. Real zoom, remaining catalogue/StatCard work and final STORY-07 reconciliation stay with the already-assigned Phase 178 scope. Current repair CI wiring has not been executed on a hosted runner. No merge, release, publication or deployment occurred.

Selected visual captures are byte-identical copies from the isolated Linux warm run. Their outer explorer breadcrumb clips the top of the theme legend in the iframe crop; labeled radio choices and dialog content remain readable. This bounded outer-chrome framing observation does not require owner UAT; final explorer/catalogue review remains in Phase 178. Native macOS diagnostic captures were discarded because their compositing artifacts did not represent the isolated acceptance run.
