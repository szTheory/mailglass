# Rolling roadmap

**Last reviewed:** 2026-11-13 · **Posture:** quiet maintenance with one scoped UI milestone · **Next gate:** v2.10 reaches `main` (owner ship decision on PR #317), then v2.11 opens.

Authority order: live code → `PROJECT.md` → `ROADMAP.md` (phase ledger) → this file. This file orders *candidate* work; it admits nothing. A milestone is admitted only through `$gsd-new-milestone`.

Maintenance rule (owner instruction 2026-11-13): at every milestone close and before every "what next?" question, fan out research, update this file, and present a proposal. Review also on any adopter report, a Phoenix/LiveView/Swoosh major or advisory, and after 90 days of no change (add a staleness banner).

## NOW — v2.11 "Brand v2.0 adoption" (proposal; not yet admitted)

Gate satisfied: brand book v2.0 signed off 2026-11-13 (zip sha256 `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`). Scoping: `.planning/research/brand-v2-adoption/MILESTONE-PROPOSAL.md`.
Precedent to reuse: `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`.

| ID | Outcome | Size | Depends on | Demand | Reversible |
|---|---|---|---|---|---|
| H0 | Housekeeping: v2.10 on `main`, tree clean, Dependabot batch | S | owner ship call on #317 | owner | yes |
| B0 | API/compat inventory and word/status policy (gloss, don't rename) | S | H0 | owner | yes |
| B1 | Catalog of current screens on realistic fixtures | M | B0 | accrue/exifcleaner lesson | yes |
| B2 | Tokens, fonts, logo as one coordinated change + static contrast gate | M | B1 | owner | yes (git) |
| B3 | Admin layout slice, one end-to-end job first (zone-explicit times, verdict + next step, Needs attention, mailer names) | M | B2 | owner | yes |
| B4 | README, ExDoc CSS, Hex/social assets, CLAUDE.md/PRODUCT.md updates | S | B3 | owner | yes |

Stop line: every claim the repo makes about its identity is true or tested. Anything else found is filed, not fixed.

## NEXT (1–2 milestones)

1. **Delivery-absence signal (SEED-008)** — read-model over `dispatched_at`/`delivered_at`; queryable signal or telemetry, not a notifier. Only item with confirmed adopter pull. Independent of the brand, so it may go first if the book work slips.
2. **Fractal Storybook depth (SEED-009: whole-job scenarios, F7 demo mounts)** — after tokens settle; stop at diminishing returns; new profile only for a distinct supported risk. Bundle the CI path-aware lanes todo here.

## LATER (themes, not commitments)

JTBD-COVERAGE refresh (stale since June) plus GAP-05 preference-center escape-hatch docs · custom date ranges (SEED-261010-gad) · `scripts/release.sh` driver, folded into the next release ceremony · scheduled-send wrapper (GAP-04) · SEED-005 HEEx assigns only if an adopter asks or a renderer contract change is already planned.

## Admin hygiene slice (schedule inside NOW or NEXT)

Correctness items independent of the brand go first: `tenant_id` whitespace (blank-to-nil), `aria-selected` on delivery buttons, e2e specs overwriting frozen evidence. UI items (details-open reset, inbound load flash, iframe reload) wait until after the brand re-baseline to avoid double work.

## Not planned

Marketing email, multi-channel notifications, preference center, hosted console, AMP, MySQL/SQLite, open core (permanent; `PROJECT.md` Out of Scope). Default-on tracking (D-08). SEED-004 snapshot retention and SEED-003 ecosystem integrations until a named adopter pulls (recipes only). Transport watchlist (gen_smtp listener, Cloudflare inbound, synthetic inbound UI). New providers. A generic Storybook fixture engine. A paid CI judge. Any rebrand beyond the owner's book.
Reopen condition for each: a named adopter request or a security/ecosystem event.

## Below the diminishing-returns line (tempting, resist)

SEED-003 (motivated reasoning, no external pull) · SEED-004 (PII threat-model liability for a solo maintainer) · SEED-005 (the stable renderer contract is a feature) · full Storybook catalogue (v2.10 cost 76 plans and a runner overage) · broad CI audit (SEED-006; only the measured narrow todo is justified) · rewriting the release pipeline (#316 did most of it) · working the 43 acknowledged deferred records (cull them instead).

## Seed and todo index (status as of 2026-11-13)

| Item | Status |
|---|---|
| SEED-007 sandbox leak | done in v2.2 Phase 143; close |
| SEED-261010-hjp auto-apply filters | shipped in v2.10 Phase 176; close |
| SEED-006 CI efficiency | superseded by `todos/2026-11-02-ci-path-aware-test-lanes.md` |
| SEED-008, SEED-009 | live; see NEXT |
| SEED-003, 004, 005 | pull-gated; see Not planned / LATER |
| Dependabot #321–#324 | batch into one refresh PR (precedent #315); Swoosh latest 1.29.x; LiveView lock at or past 1.2.13 (advisories) |
| 2026-09 release close-out todos | re-triage at the next release ceremony; #316 may have fixed several |

## Seed graduation rule

A seed becomes a milestone when: a trigger has fired; there is named demand evidence; scope is bounded with stated non-goals; there is a stop line; a CI/runner budget is set; and the gating input exists. Demote to archive after two reviews with no pull. Keep at most one active milestone and one NEXT item with a written scope.
