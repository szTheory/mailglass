# Phase 176 Deferred Items

## 176-04 (found 2026-10-28)

- `mailglass_admin/e2e/phase169-journey.spec.js:459` expects the replay review to contain "does not resend outbound mail or prove provider receipt". `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:35` has read "It does not resend mail or prove provider receipt." since Phase 175 (`a9670252`, `fix(175): align inbound replay presentation`). The Playwright case "Phase 169 rendered route matrix stays readable across widths and missing media" therefore fails on this copy alone. Plan 176-04 did not touch the replay modal. Fix: align the spec literal with the modal copy.
