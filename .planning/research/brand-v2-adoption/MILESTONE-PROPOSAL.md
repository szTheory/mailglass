# v2.11 "Brand v2.0 adoption" — milestone proposal

**Status:** proposal, not admitted. **Date:** 2026-11-13. **Inputs:** six read-only lenses (API/compat, tokens/build, admin UX/JTBD, gates/CI/release, roadmap candidates, brand risk/docs) plus sibling lessons from accrue, exifcleaner and sigra (memory: `project_brand_adoption_v2_lessons`). Roadmap: `.planning/ROLLING-ROADMAP.md`. Precedent: `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`.

Book: brand book v2.0, zip sha256 `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`.

## Goal and stop line

Goal: the repo's identity (words, colors, type, logo, docs assets, admin screens) matches brand v2.0, and every identity claim is true or tested.
Stop line: **no new data capture or backend features.** Anything the book wants that the product cannot truthfully show today (next-retry time, provider reason text, per-mailer rollups) is filed for a later "insight" milestone, not built. Cap: 5 phases, ≤ 20 plans, one open PR at a time. (v2.10 cost 76 plans; this is a deliberate contrast.)

## Corrections the research made to the brief

- The admin test lane is not a blind spot any more: `verify.support_contract.admin` runs the whole directory.
- But the claim "CI diffs the committed admin bundle" is **not enforced**: `verify.preview` does it, no workflow calls it, and the bundle was hand-assembled by a script that was never committed. Fix this first.
- `README.md` line 2 uses a relative image path that breaks on hex.pm. Use absolute `raw.githubusercontent.com` URLs pinned to a tag.
- v2 `tokens.json` has palette and status text colors only. The admin's 36-slot daisyUI mapping (solid, on-solid, sunken, input border…) has no v2 source; these values must be designed and contrast-verified here.
- Funnel Display ships only weight 600; ExDoc stays Lato (only code colors change); the book's ExDoc CSS has an OS dark media query that fights ExDoc's own switcher and must be removed.

## Phases

**P1 — Policy, inventory, pin (S, ~3 plans).**
Compatibility policy: gloss, don't rename. `Mailglass.Operator.*`, `mailglass_operator_routes`, `:operator_access`, `tenant_id`, `:orphan_backlog`, telemetry names and the `Delivery.status` enum stay. On-screen and docs words change. Add `MailglassAdmin.Copy` (status-label map + copy contract test, modeled on accrue's `copy_test.exs`), a pure unit-tested **status map** (25 atoms → Sent / Delivered / Delayed / Failed / Not sent / "not a delivery status"), and a brand pin (zip sha256 + tamper test; full book stays out of the repo, shipped assets are copied in). Run trademark/image/register searches and record the result (1–2 hours). Verify before promising: is "Not sent" ever a persisted `Delivery.status :suppressed` row, or only a pre-send block?

**P2 — Pipeline and catalog (M, ~4 plans).**
Make the admin bundle reproducible (generator + `--check` drift gate that CI actually runs; theme attribute owned by `<html>` only; fix the nested `data-theme` shadowing class). Catalog the current screens on realistic fixtures (Northstar, Fjordline, Helios + the delivery cases the UX lens listed) with unique-path before screenshots. Goal is seeing what breaks before any swap.

**P3 — Tokens, fonts, logo (M, ~4 plans).**
One coordinated change: v2 tokens + role map for the 36 slots, static contrast test (declared fg/bg pairs per theme, checked against the book's own ratios, no new dependency), seven woff2 files (~52 KB, no CDN) with OFL texts in `priv/static/fonts`, `@external_resource` + `@allowed_fonts`, weight 600 mapping, replace the `←` glyph, logo/favicon files, update `brand_test`/`token_parity_test`/`accessibility_test`. Regenerate the axe baseline once, last. Core email defaults (`config.ex`, `theme.ex`, button colors, VML goldens) stay **unchanged**: they are the host's emails and a public API.

**P4 — Admin words and layout, one job first (M, ~5 plans).**
Prove "a customer says the password reset never arrived" end to end through the real LiveView: search by email → Needs attention → timeline with a verdict and "sent is not delivered" → next step; light/dark/375px; every time shows its zone; status = pane mark + word. Then roll out: Activity label (screen text only), Admin for Operator in copy, Account for Tenant in copy, "N provider reports match no email", mailer plain name with accessible tooltip. Cause sentences only where `reject_reason` or the suppression reason exists; fixed honest fallback otherwise. **Never render** "next try at…", "will retry", or cause text with nil reason. Qualitative per-scenario design review by a separate agent with a rejection gate; evidence at unique paths; restart the server and record the served SHA.

**P5 — Docs, packaging, launch prep (S, ~3 plans).**
README header (`<picture>`, absolute URLs), ExDoc CSS and the "m" logo in all three `mix.exs`, verified by a real `mix docs` build per package, `design-system.md`, `.impeccable` config, CLAUDE.md/PRODUCT.md (owner sign-off), lowercase-name lint, Hex file allowlist + `mix mailglass.publish.check`, favicon check at 16/24/32 px in three browsers, social card/avatar manual-upload checklist. **Gate the announcement and any ™ claim on the P1 search result;** code rollout is not gated.

## Release and commit kinds

Admin `lib`/`priv/static` changes: `feat(admin):` (minor bump; a rebrand of a shipped UI is user-visible). Docs, README, brand files, `.planning`: `docs:`/`chore:`. Mixed phases may use `feat:` if one shippable file is in the diff (Guard Release Trigger classifies by kind). Every PR title conventional. One CHANGELOG line, no migration section.

## Decisions (recommended defaults; veto any)

| Decision | Recommendation | Why |
|---|---|---|
| "Activity" as screen name | Yes, label only; `deliveries_path` stays (add `activity_path` alias later if wanted) | Matches Postmark/SendGrid; zero API cost |
| "Admin" for Operator | Yes in copy and docs; modules stay | Public contract |
| Five plain statuses | Yes, via explicit map; provider/event names stay in code | Book + cold-reader evidence |
| opened/clicked | Keep, labeled optional and provider-reported (already opt-in, D-08) | No decision pending in code |
| Trademark | No ™ claim now; record search result; keep one-color/wordmark fallback | Irreversible claims wait |
| Email defaults | Unchanged | Host-owned, public API |
| CLAUDE.md/PRODUCT.md edits | Draft in P5; owner approves | Locked project docs |

## Adversarial pass

- *Scope creep into backend:* the book's drawings imply data we lack. Mitigated by the stop line and the "never render" list.
- *Green checks ≠ good design* (accrue): P4 has a separate agent review with a rejection gate.
- *Bundle reproducibility could swallow P2:* scope it first, time-box it, fall back to committing the assembly script as-is.
- *Book is unverified in places* (favicon at 16 px, ExDoc CSS, trademark): each has a verification task inside this milestone.
- *Brand churn vs. hex.pm:* hex.pm shows only the README; one surface to get right.
- *CI cost:* UI changes legitimately run all browser lanes (~115 runner-minutes/run); batch commits, run locally first, do path-aware lanes afterwards.
- *Half-renamed state:* `Operator.Tenants` and `Operator.Accounts` already coexist; the policy file lists every name that stays.

## Owner hand-off (only these)

Ship/no-ship on PR #317 (gate for H0); veto any default above; trademark/counsel call before announcement; physical devices for favicon sanity if wanted.
