# Phase 178 delivery status

## Cycle 09 owner review — attempt 3

Candidate `5ad5329a6d0f17da0edce3af6b4a987bc3219023` passed the exact-SHA launcher, required CI check, and all 17 preview-page checks. The owner accepted the review on 2026-11-02 (`yeah this is fine i accept it`). The candidate preview, project-specific image tag, detached worktree, run parent, and disposable clone were then removed. The earlier attempt-1 checkout failure and attempt-2 Buildx metadata failure remain preserved as historical records. The page URLs below document the review and are no longer live.

The preview used loopback-only ports and only the `demo` and `demo_db` services. Its generated fixture data was synthetic. The session links signed in the synthetic demo operator and redirected straight to the requested Operator page; there was no sign-in screen.

## Short history

Cycle 07 stopped after its required Support Contract Admin failure across seven attempt-1 workflows; it had no dispatch, cost disposition, or preview. Plan 33 fixed the local projection-time regression, and Cycle 09 includes its time-window fix plus the locally verified architecture allowlist correction. The earlier `2bdf1816` candidate was superseded after Plan 13 fixed its Demo job defect. Attempts 1 and 2 for the current candidate are preserved as stopped records; this handoff uses only successful attempt 3.

### Review pages

1. URL: http://127.0.0.1:65275/dev/mail/MailglassDemoWeb.Mailers.AccountMailer/invite_admin?width=768 | marker: preview-assigns-form | action: Review the Invite Admin preview: Restore defaults stays aligned, validation is clear, and read-only guidance is visible.
2. URL: http://127.0.0.1:65275/dev/mail | marker: preview-mailables-picker | action: Check the selector keeps the human scenario, Mailable name, and exact module/scenario identity easy to distinguish.
3. URL: http://127.0.0.1:65275/dev/storybook/preview_authoring | marker: preview-authoring-story | action: Inspect the retained production composition and Preview authoring theme controls.
4. URL: http://127.0.0.1:65275/dev/storybook/preview_chrome | marker: preview-chrome-story | action: Inspect the shared preview chrome, theme behavior, and layout framing.
5. URL: http://127.0.0.1:65275/dev/storybook/primitives/stat_card?tab=playground&variation_id=neutral_light | marker: mailglass-light | action: Inspect the light StatCard example, especially label/value font roles and contrast.
6. URL: http://127.0.0.1:65275/dev/storybook/primitives/stat_card?tab=playground&variation_id=neutral_dark | marker: mailglass-dark | action: Inspect the dark StatCard example and confirm the same type hierarchy remains readable.
7. URL: http://127.0.0.1:65275/dev/storybook/delivery_investigation | marker: delivery-investigation-story | action: Review the delivery investigation story and its evidence/suppression presentation.
8. URL: http://127.0.0.1:65275/dev/storybook/inbound_evidence | marker: inbound-evidence-story | action: Review the inbound contacts and raw-source evidence story.
9. URL: http://127.0.0.1:65275/dev/storybook/health_overview | marker: health-overview-story | action: Review the health overview status, issue summary, and time-window copy.
10. URL: http://127.0.0.1:65275/dev/storybook/account_scope | marker: account-scope-story | action: Review the account-scope navigation and selected-account context.
11. URL: http://127.0.0.1:65275/dev/storybook/quick_views/delivery | marker: quick-view-review-theme | action: Review the delivery quick-view composition and its navigation/focus affordances; do not submit an action.
12. URL: http://127.0.0.1:65275/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar | marker: operator-health-layout | action: Check the authenticated Northstar Operator Health page and its linked issue drill-downs.
13. URL: http://127.0.0.1:65275/demo/login?return_to=%2Fops%2Fmail%3Fview%3Ddeliveries%26tenant_id%3Dnorthstar%26delivery_id%3D01a19e50-e1be-7ada-9314-99355a8eac24 | marker: operator-quick-view | action: Open the seeded delivery quick view and review recipient, outcome, account, and next/previous navigation.
14. URL: http://127.0.0.1:65275/demo/login?return_to=%2Fops%2Fmail%3Fevent%3Dbounced%26tenant_id%3Dnorthstar%26view%3Ddeliveries%26window_hours%3D168 | marker: operator-filters | action: Review the bounced-event filter state, applied-filter summary, and clear path.
15. URL: http://127.0.0.1:65275/demo/login?return_to=%2Fops%2Fmail%3Fview%3Ddeliveries%26tenant_id%3Dnorthstar%26delivery_id%3D01a19e50-e1be-7ada-9314-99355a8eac24%26full%3D1 | marker: operator-detail-column | action: Review the seeded delivery’s full detail and its evidence/timeline; do not submit a mutation.
16. URL: http://127.0.0.1:65275/demo/login?return_to=%2Fops%2Fmail%3Fview%3Ddeliveries%26tenant_id%3Dnorthstar%26delivery_id%3D01a19e50-e1bb-7d31-b5cf-c1ec3b9b5d91%26full%3D1 | marker: operator-replay-open | action: Review replay eligibility and the retry-review affordance only; do not execute a replay.
17. URL: http://127.0.0.1:65275/demo/login?return_to=%2Fops%2Fmail%2Finbound%3Ftenant_id%3Dnorthstar | marker: inbound-overview | action: Review the authenticated Inbound overview, filters, record list, and outcome labels.

### PR and hosted checks

18. Draft PR: [#317](<https://github.com/szTheory/mailglass/pull/317>) — still open and draft, branch `gsd/v2.10-ui-repairs-storybook` at the approved candidate SHA. Review the proposed change only; this is not a merge instruction.

19. PR Title (pull_request_target): [run 41497959738](<https://github.com/szTheory/mailglass/actions/runs/41497959738>) — completed/success, exact head `5ad5329a6d0f17da0edce3af6b4a987bc3219023`.
20. Guard Release Trigger (pull_request): [run 41497963277](<https://github.com/szTheory/mailglass/actions/runs/41497963277>) — completed/success, exact head `5ad5329a6d0f17da0edce3af6b4a987bc3219023`; key jobs: [Guard Release Trigger](<https://github.com/szTheory/mailglass/actions/runs/41497963277/job/125457771594>) — success.
21. Advisory Matrix (pull_request): [run 41497963281](<https://github.com/szTheory/mailglass/actions/runs/41497963281>) — completed/success, exact head `5ad5329a6d0f17da0edce3af6b4a987bc3219023`.
22. CI (pull_request): [run 41497963359](<https://github.com/szTheory/mailglass/actions/runs/41497963359>) — completed/success, exact head `5ad5329a6d0f17da0edce3af6b4a987bc3219023`; key jobs: [Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22) (22)](<https://github.com/szTheory/mailglass/actions/runs/41497963359/job/125457857154>) — success, [Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22)](<https://github.com/szTheory/mailglass/actions/runs/41497963359/job/125457857365>) — success, [Demo Browser Evidence (Docker Compose / Chromium)](<https://github.com/szTheory/mailglass/actions/runs/41497963359/job/125457857735>) — success, [CI Green](<https://github.com/szTheory/mailglass/actions/runs/41497963359/job/125466296472>) — success; artifacts: trust-runner-clean-baseline-41497963359 (expires 2027-01-31T18:10:02Z), trust-runner-repo-head-41497963359 (expires 2027-01-31T18:10:02Z), preview-capture-advisory-41497963359 (expires 2026-11-16T18:14:45Z), demo-browser-evidence-41497963359-1 (expires 2026-11-16T18:25:45Z).
23. Actionlint (pull_request): [run 41497963451](<https://github.com/szTheory/mailglass/actions/runs/41497963451>) — completed/success, exact head `5ad5329a6d0f17da0edce3af6b4a987bc3219023`.
24. PR Title (pull_request_target): [run 41501371720](<https://github.com/szTheory/mailglass/actions/runs/41501371720>) — completed/success, exact head `5ad5329a6d0f17da0edce3af6b4a987bc3219023`.
25. Guard Release Trigger (pull_request): [run 41501370811](<https://github.com/szTheory/mailglass/actions/runs/41501370811>) — completed/success, exact head `5ad5329a6d0f17da0edce3af6b4a987bc3219023`; key jobs: [Guard Release Trigger](<https://github.com/szTheory/mailglass/actions/runs/41501370811/job/125469408905>) — success.
26. CI (workflow_dispatch): [run 41501525366](<https://github.com/szTheory/mailglass/actions/runs/41501525366>) — completed/success, exact head `5ad5329a6d0f17da0edce3af6b4a987bc3219023`; key jobs: [Demo Browser Evidence (Docker Compose / Chromium)](<https://github.com/szTheory/mailglass/actions/runs/41501525366/job/125470064745>) — success, [Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22)](<https://github.com/szTheory/mailglass/actions/runs/41501525366/job/125470064778>) — success, [Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22) (22)](<https://github.com/szTheory/mailglass/actions/runs/41501525366/job/125470065010>) — success, [CI Green](<https://github.com/szTheory/mailglass/actions/runs/41501525366/job/125478449475>) — success; artifacts: preview-capture-advisory-41501525366 (expires 2026-11-16T18:40:19Z), trust-runner-clean-baseline-41501525366 (expires 2027-01-31T18:32:23Z), demo-browser-evidence-41501525366-1 (expires 2026-11-16T18:44:12Z), trust-runner-repo-head-41501525366 (expires 2027-01-31T18:32:23Z).

27. Reference: `/Users/jon/projects/mailglass/.planning/phases/178-preview-authoring-and-milestone-review/178-DELIVERY.md` — read **Checks and evidence limits**, the Cycle 07–09 history, the decisions below, and the resource dispositions before deciding.

The Advisory Matrix run has one intentionally skipped next-toolchain advisory job; its other jobs passed. No hosted job was rerun during preview attempt 3.

## Checks and evidence limits

- The preview is candidate `5ad5329a6d0f17da0edce3af6b4a987bc3219023`. Its six launcher routes returned HTTP 200, the required exact-SHA CI read passed, and the built CSS bytes match the served CSS. All 17 review pages above returned HTTP 200 with their page markers through the synthetic session; redirects were checked to stay on the same loopback origin.
- All eight attempt-1 workflow runs completed successfully at this candidate SHA. CI Green and Guard Release Trigger succeeded in both the PR and `workflow_dispatch` runs. Demo Browser Evidence, Operator Browser Gate, and Preview Capture Advisory also succeeded for both. The CI run pages link to their job details; the recorded evidence artifacts remain available until their listed expiry.
- The eight hosted runs used a total of **267.60 runner-minutes**. The two full CI runs exceeded the existing 10-runner-minute per-run comparison budget by 8.43 minutes on the PR run and 6.50 minutes on the exact-SHA dispatch run. CI Green itself finished 288 seconds faster than baseline in the PR run and 273 seconds faster in the dispatch run. Runner-minutes are summed job elapsed time, not a dollar bill.
- The cold browser pilot used 7.37 runner-minutes and took 7m22 wall time, above its 5-minute wall target but under the 10-minute runner cap. The warm pilot used 3.71 runner-minutes and took 3m43. The cold and warm conditions were kept; dropping the cold case would hide setup cost. Demo Browser Evidence retained all 169 expected checks in each condition. Operator Browser Gate recorded 310 passes and one expected guarded skip.
- D-12 supports the measured overage for this one candidate-specific owner review only. No job, assertion, expected count, or gate was removed or weakened. The measured cost artifact is [`178-CYCLE-09-COST-DISPOSITION.json`](178-CYCLE-09-COST-DISPOSITION.json).
- Hosted browser evidence is Chromium-only and uses synthetic fixtures; it does not prove behavior against a live provider or real delivery data. The PR browser artifact is tied to GitHub’s merge checkout; the exact-source dispatch artifact binds directly to this candidate. The run count is one PR cycle plus one dispatch cycle, so the observed differences do not isolate causal per-PR cost.
- The evidence documents prepared after the candidate are local, ignored, and unpushed. The path-aware CI-lane follow-up remains recorded at `.planning/todos/2026-11-02-ci-path-aware-test-lanes.md`. No new CI run occurred during attempt 3.

## Planning decisions to review

- **D-13 clarification:** the one hosted approval included a single exact-SHA `workflow_dispatch` because a `pull_request` merge-ref run cannot prove the candidate SHA by itself. No hosted rerun was included in that approval.
- **D-14 amendment:** the Cycle 09 preview uses `scripts/check_phase178_candidate.sh`, a narrow sibling that reuses the 173 launcher mechanics. The original 173 script depends on 173-specific plans and baseline assets and cannot run for this candidate.
- **D-16:** positive `state_md_contract_test` assertions moved from tool-managed `STATE.md` to the v2.8 DOCS-01 requirements record, where the state updater will not overwrite them; the `STATE.md` prohibitions stayed in place.
- **178-13 fix:** Playwright is required lazily inside the accessibility check, and a required-lane guard catches missing package installs. This keeps pure helper tests usable without Playwright and changes no workflow or dependency.
- **178-14 failure disposition:** the hosted End-key failure was classified as nondeterministic. The saved traces showed focus remained in the dialog and the page scrolled, but omitted the dimensions and callback result needed to locate the false bottom predicate. Focus diagnostics were added; the targeted flow then passed 50 consecutive checks and the complete local flow file passed. The recorded readiness race was excluded from the repeat count. No assertion or lane was weakened.

## Scoped cleanup after review

| Resource | Current state | Disposition |
| --- | --- | --- |
| Candidate preview and detached worktree | Removed after the owner accepted the review | Exact attempt-3 teardown stopped only the candidate project, removed its volumes/network, and removed its detached worktree and run parent. |
| Candidate image | Project-specific tag removed after teardown; Docker reported 1.837 GB unique size (2.02 GB total image size) | Removed only after confirming the exact project label and no remaining container references. Shared base images and Buildx cache were preserved. |
| Previous owner demo | Zero matching running containers before and after this attempt | Unchanged; never use it for candidate cleanup. |
| PR and branch | PR #317 is open/draft at the candidate SHA | Keep open; no merge, release, publication, or deployment is authorized here. |
| Hosted artifacts | Current, not expired | Keep until each artifact’s recorded expiry. Browser and preview artifacts expire on 2026-11-16; trust-runner artifacts expire on 2027-01-31. |
| Local ignored evidence | Attempt records, logs, recovery record, and review checkpoint retained; disposable clone removed | Keep for the audit trail; these post-candidate files remain local and unpushed. |
| Buildx | Dedicated temporary config removed; shared `desktop-linux` builder/cache preserved | No global Docker configuration changed. |
| Unrelated services | Unchanged | Leave them untouched. |

This exact candidate-scoped teardown command was run from the disposable clone before that clone was removed:

```sh
bash "/private/tmp/mailglass-phase178-cycle09-attempt3.QDldah/repo/scripts/check_phase178_candidate.sh" --teardown "/Users/jon/projects/mailglass/reference/demo_app/tmp/phase178_candidate/recovery-cycle-09/preview-attempt-3.json"
```

## Owner decision

**Decision:** ship / accept the review only. **Owner reply:** “yeah this is fine i accept it” (**2026-11-02**, candidate `5ad5329a6d0f17da0edce3af6b4a987bc3219023`). This authorizes the review outcome and candidate-scoped cleanup only. It does not authorize merging, release, publication, deployment, or a GitHub write. PR #317 remains open and draft.

