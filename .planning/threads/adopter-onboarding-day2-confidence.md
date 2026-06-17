# Thread: Adopter Onboarding & Day-2 Confidence

**Opened:** 2026-06-16
**Status:** ✅ CLOSED 2026-06-17 — exit signal met. **v1.12 SHIPPED** (Phases 104–108, audit
`status: passed`, 13/13 reqs): all done-enough criteria below delivered AND the first real
linked-version Hex release since 1.6.2 was cut (1.7.0 / 1.7.0 / 1.4.0 live). Every "newly surfaced
durable finding" and "open investigation" below was consumed by the milestone — see resolution notes.
**Priority:** ~~high~~ resolved
**Owner:** maintainer

## Resolution (2026-06-17)

- Silent webhook `Plug.Parsers` 401 → **fixed closed** (Phase 104): `validate_preflight/1` in
  `installer/apply.ex` returns `{:error, {:unmanaged_parser_conflict, _}}` (Mix.raise) without
  `--force`; `mix mailglass.doctor` added as the post-install verifiable check.
- README quickstart → **fixed** (Phase 105): config-first block; learning-path index + getting-started
  Next-steps arc; migration-from-swoosh value-prop opener.
- Go-live checklist + unified errors/troubleshooting guides → **shipped** (Phase 106).
- Inbound replay-modal a11y parity (ex-WR-03) → **shipped** (Phase 107).
- Staged release → **cut** (Phase 108); inbound re-pinned `{:mailglass, "== 1.7.0"}` (D-13).

Re-confirmed at the 2026-06-17 next-step assessment: no remaining onboarding/day-2 gap. Post-v1.12
posture is pure quiet maintenance (see `project-convergence-posture.md`).

## Question

mailglass is feature-complete for its scope (~92% on the code axis; all 10 `guides/jobs.md`
jobs map to shipped, tested code). The remaining adopter value is **not** more capability — it
is removing the friction and footguns between "evaluating" and "in production." What is the
thinnest milestone that converts the weak onboarding/day-2 axis without expanding scope?

## Why this is the wedge (from the 2026-06-16 next-step assessment)

A feature-complete framework that loses evaluators at a broken README example and loses
production adopters at a **silent webhook 401** is leaving its only remaining leverage on the
table. This is pure adopter-pull conversion work, coherent with the founding thesis ("email you
can see, audit, and trust"), zero feature scope creep, and respects the D-23 convergence posture.

## Done-enough criteria

- **Installer fails closed (or hard pre-flight + verifiable check)** on the webhook-`Plug.Parsers`
  conflict — silent prod 401 becomes impossible. *(Only code change in the milestone; DX hardening,
  not feature growth.)*
- README quickstart copy-pastes cleanly (config-first, or replaced with a link to getting-started).
- "First week" learning arc: a Next-Steps section at the end of `guides/getting-started.md` + a
  guide index/sequence so adopters don't wander across 19 guides.
- One **production go-live checklist** guide — surfaces `mix mail.doctor` (DKIM/SPF/DMARC), webhook
  secret provisioning/rotation, Oban queue sizing, per-tenant adapter routing.
- One **unified error/troubleshooting** guide — `SuppressedError`/`SignatureError`/`RenderError`/
  provider errors in one place (error → cause → fix).
- `guides/migration-from-swoosh.md` opens with the "Swoosh = transport; mailglass = the framework
  layer you'd otherwise rebuild (preview, webhooks, audit ledger, suppressions, multi-tenancy)" pitch.

## Newly surfaced durable findings (GRADUATION CANDIDATES)

These are cross-session adopter-DX findings from the 2026-06-16 assessment. They do not belong in
any existing phase's LEARNINGS (no phase owns them); they live here until the milestone consumes them:

1. **Silent webhook `Plug.Parsers` 401** — `mailglass/lib/mailglass/installer/apply.ex:64-74` warns
   in yellow then continues when a conflicting parser (no `:body_reader`) is present. The headline
   webhook feature breaks silently in prod with no hard failure. Highest-value single fix.
2. **README quickstart broken-as-written** — `README.md` shows
   `UserMailer.welcome(u) |> Mailglass.deliver()` with no prior `config :mailglass, repo:` → crashes
   on copy-paste; `guides/getting-started.md` has the real config-first path but they're disconnected.

## Open investigations this milestone inherits

- Webhook-parser fail-closed fix (above).
- **Inbound replay-modal a11y parity** — operator-style focus-trap + Escape handler; the named
  highest-priority deferred quality item from v1.11 (Phase 102 WR-03). Small, self-contained; could
  ride along or be its own follow-up.
- **Staged release is still prepare-only** — v1.7–v1.11 polish is not on Hex. Cut the linked-version
  release (admin-minor drags matched core+inbound) and perform the PENDING inbound exact-pin re-pin
  (D-13) when the Release Please PR merges. Best folded into this milestone's close so the onboarding
  docs + admin polish actually reach adopters.

## Out of scope (explicit — diminishing returns / pull-gated, do NOT bundle in)

- Core email-template HEEx component "design-system uplift" (components are real + VML-complete;
  recipient-facing polish, not an adopter wedge).
- `SEED-003` ecosystem integrations (no adopter signal; needs a narrow spike + real pull).
- Synthetic inbound dev UI, Cloudflare Email Routing, `gen_smtp` listener (flat-tail; see
  `transport-expansion-watchlist.md`).
- More providers (6 webhook / 4 inbound already shipped).

## Exit Signal

This thread closes when a milestone is opened with the done-enough criteria above mapped to phase
requirements, OR the maintainer explicitly defers onboarding work and stays in pure silence-on-the-wire.
