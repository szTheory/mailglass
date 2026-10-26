---
phase: 173-consistency-and-delivery-evidence
status: locally_verified
candidate_sha: a17f0ee565dd9b63388313b481381bc6f3779d14
remote_delivery_sha: 9b6e60e4c8724b8168f72e49d9368aa7a0adc84a
owner_acceptance: unverified
updated: 2026-10-10T19:06:54Z
---

# Inbound page refinement

The owner requested a quieter inbound collection page: less vertical filter copy, filters before their summary, clear scope, and uniform outcome counts that do not look like toggles. Initial cleanup implemented as local commit `61dc374d`, followed by Impeccable polish in `bb98438f` and removal of redundant summary context in `a17f0ee5`, in the existing sparse candidate worktree `/private/tmp/mailglass-phase173-ci-repair-lw4_w1ad/candidate`.

The review URL is http://127.0.0.1:55483/ops/mail/inbound?tenant_id=northstar. Its existing container mounts this candidate. The prior exact-SHA delivery preview at http://127.0.0.1:59905/dev/mail remains the separately retained `9b6e60e4` candidate.

## Result

- Compact labelled filters precede the summary and collection. Desktop controls and actions share one row; mobile controls use the existing disclosure.
- Removed the repeated introductory paragraphs. Shared field help is optional and available through hover, keyboard focus, or tap. Escape dismisses help without moving focus, click-away clears pinned help, and descriptions remain connected to their controls for assistive technology. Errors and unavailable-data recovery remain visible.
- The summary uses the existing shared stat primitive with a compact variant. All seven outcomes, including no change and zero counts, have consistent presentation without separate badge-like controls.
- The filters provide context without repeating their values above the counts. Summary semantics are preserved: counts follow applied provider, time, and search filters across all matching messages and pages, while mailbox outcome only narrows the collection. An applied outcome adds a short conditional note explaining that difference.
- Changed the collection heading to “Received messages.” Preserved account scope, URL-backed filters, pagination, authorization, detail, and replay behavior.
- Fixed a demonstrated responsive defect: closing the mobile filter panel no longer leaves an inline display override that hides desktop controls after widening the viewport.

## Additional Impeccable polish

The owner approved the first cleanup and requested another focused Impeccable refinement. Preserved the accepted filter ordering, summary presentation, applied-filter semantics, and shared design tokens.

- Combined “Received messages” and the result count in one header row. The component accepts an optional heading, so its other empty-state callers keep their existing content.
- Replaced uppercase table and mobile metadata labels with the existing sentence-case typography.
- Kept the full canonical UTC timestamp visible and placed the labelled local-time supplement on its own line. Both now wrap within the received cell.
- Rebalanced recipient/outcome column widths and retained readable mailbox widths at intermediate sizes. The existing table scroll region owns overflow when the full table cannot fit; the normal 1512px review viewport has no table overflow.
- Extended the browser regression to 1024px and asserted that received cells contain their UTC/local content and the mailbox column remains readable.

## Redundant scope-line removal

The owner identified “All outcomes · Last 7 days · Any provider” as a repetition of the filter controls. Removed that line and its separate help button, the unused scope formatting helper, and summary-only tooltip CSS. The summary now starts directly with its counts. Only an applied outcome adds “Counts include all outcomes; list shows Accepted.” (or the selected outcome label).

Updated the existing filter regression to check real count changes after applying a search and recovery after clearing it. No summary-data behavior changed.

## Verification

Final checks ran after the last implementation change:

- Admin package: **621 tests, 0 failures, 1 existing excluded** (`/private/tmp/mailglass-inbound-scope-cleanup-exunit.log`).
- Focused browser checks: **9 passed** (`/private/tmp/mailglass-inbound-scope-cleanup-browser.log`). This includes four existing health-tooltip regressions and five inbound checks at 1440/1024/390/320px, tooltip paint order/bounds, keyboard/tap/Escape, responsive reopening, applied-filter scope, and clear-filter account preservation.
- Axe found **zero violations** within the changed filter and summary regions at all four viewport sizes. This is scoped coverage, not a fresh whole-app accessibility certification.
- Production CSS build, targeted formatting check, JavaScript syntax, design-system conformance, motion conformance, and scoped diff checks passed.
- Live Northstar page confirmed the new labels and desktop controls; the collection starts at approximately **363px** in the normal desktop viewport.
- Built and served CSS are identical; SHA-256 `9f041e7ecb870494a53a624be3d1838a992f1d432404c06f8d5c73d0f43235ed`.
- Optional browser-fixture screenshots: `/private/tmp/mailglass-inbound-without-scope-1440.png`, `-1024.png`, `-390.png`, and `-320.png`; each validated at its expected width and 900px height.
- Impeccable mechanical detector ran once. Its findings were pre-existing shared navigation accent borders and the established Inter font, outside this refinement. No brand-wide drift repair or skill update was performed.

The retained demo's startup refreshed its Decimal lock entry. That runtime-generated change was restored only in the sparse candidate; all four lockfiles match HEAD and the candidate has no tracked or untracked changes. Original source files and owner edits remain untouched; only the generated planning record and checkpoint were refreshed in that worktree.

## Delivery state

This UI follow-up is committed **locally only**. It has not been pushed or given a fresh remote CI/full Phase 173 gate run. The all-26-job CI result and retained delivery record for `9b6e60e4` remain valid for that historical exact SHA, not for `61dc374d`, `bb98438f`, or `a17f0ee5`. Owner acceptance and formal Phase 173 completion remain unverified. Do not overwrite the old delivery record or treat this local UI review as final delivery acceptance.

Next delivery work, if requested, should use the existing path-safe sparse candidate route to publish and obtain exact-SHA evidence for the chosen final candidate. Preserve both original protected demo paths, earlier retained previews, and the no-merge/no-release fence.

The owner selected updating Impeccable next session; do not update skill files during this session.
