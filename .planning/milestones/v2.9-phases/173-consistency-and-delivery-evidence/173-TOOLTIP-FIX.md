---
phase: 173
status: locally_verified
candidate_sha: 8a40b853df0fe784f2c98930ea3b7f0697bc9049
previous_candidate_sha: cea2f46a37b15d33592e06bcc8c4baf43c4db5ea
branch: gsd/phase-173-delivery-8b4ce3e9
updated_at: 2026-10-10T17:19:56Z
---

# Health tooltip overlap fix

> Follow-up: `173-DELIVERY-CHECKS.md` records final candidate 9b6e60e4, with all local delivery predicates and all 26 exact-SHA CI jobs passed. The existing 55483 preview now mounts that final SHA (the follow-up changes only test timing); the fresh exact-SHA review is at http://127.0.0.1:59905/dev/mail. The scoped results below remain historical evidence for the tooltip commit. Authenticated owner acceptance is still unverified.

The user reported tooltips painting under neighboring health cards on the retained Northstar preview. The hover translation creates a stacking context on the outer drill-through link, trapping the existing tooltip layer. The fix raises the active linked stat card to the existing dropdown tier on hover or focus-within. The generated Admin CSS was rebuilt; no Elixir behavior changed. Commit `8a40b853df0fe784f2c98930ea3b7f0697bc9049` was pushed normally to the same authorized delivery branch.

Fresh verification: four Playwright regressions passed (10.9s), covering all five health cards with hover and real keyboard focus at 1440px and 390px. The checks sample the tooltip's actual painted layer with hit testing, restoring its normal pointer-events afterward. Design and motion conformance gates, JavaScript syntax and scoped diff checks passed. The original live reproduction changed from `tooltipInFront: false` (suppression card on top) to `true`, with parent layer 20. Screenshot: `/private/tmp/mailglass-tooltip-after.png`. Test log: `/private/tmp/mailglass-health-tooltips-check.log`.

The same review URL remains http://127.0.0.1:55483/ops/mail?tenant_id=northstar. Its Compose demo service now mounts clean repair candidate `/private/tmp/mailglass-phase173-ci-repair-lw4_w1ad/candidate`, using override `/private/tmp/mailglass-tooltip-preview-override.json`. Project remains `mailglass-phase173-review-cea2f46a-20261010165422-30235-22143`; HTTP/DB ports remain 55483/55484. Existing database, project environment and named volumes were preserved. The original gate candidate `/private/tmp/mailglass-phase173.bvJb17QO/candidate` and its exact-SHA delivery record remain unchanged as historical evidence. The project name contains its original SHA and no longer identifies the running source. The override contains the retained reset environment; keep it local.

Built and served CSS SHA256 both equal `36e08ac7344c60d66165d225008c1421457d2db5aee8770f6678de65fb75679e`. Live container is healthy. No screenshot baselines were regenerated. Original owner edits and the protected original files remain untouched.

At this fix's initial verification, CI run 38069265370 and the full local delivery gate applied to prior SHA cea2f46a only. The scoped tooltip checks passed for 8a40b853; its full delivery and CI refresh followed separately, as recorded in `173-DELIVERY-CHECKS.md`. Do not transfer prior exact-SHA evidence or mark Phase 173 complete from this bug-fix verification.

For future preview recreation, include both the original compose file and `/private/tmp/mailglass-tooltip-preview-override.json`, set HTTP/DB ports to 55483/55484, and retain the same project name. Do not remove either source worktree while this preview is running.
