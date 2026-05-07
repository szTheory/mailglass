# v1.2 Strategic Alternatives — Adversarial Review

**Brief:** Argue strongly against the orchestrator's hypothesis that v1.2 should complete `mailglass_inbound` (Mailgun + SES + admin observability + test helpers + operator runtime).

**Verdict: The hypothesis substantially stands. Inbound completion is the right v1.2.** Of six alternatives investigated, only one — **Stability/Polish v1.2** — is a defensible challenger, and it loses on adopter pull. The honest amendment is that v1.2 should *bundle* the carry-forward debt closeout into the inbound completion milestone rather than defer it again, but it should not replace it.

## Alternatives Evaluated

| Direction | Adopter pull | Effort | Verdict |
|---|---|---|---|
| 1. Stability/Polish v1.2 (close all carry-forward debt) | Low–med (mostly maintainer pain) | Small (~1 phase) | Fold into v1.2, do not replace |
| 2. Outbound deepening (scheduled sends, batch, circuit-breaker, BIMI, GDPR DSR) | Med, but no single load-bearer | Med–large per item | Reject. Core was Stability-Locked at v1.0 — reopening is contradiction |
| 3. New sibling: `mailglass_relay` (gen_smtp listener) | Low for v1.2 — Postmark/SendGrid covers >70% of adopters | Large (new transport class, DKIM/SPF, anti-abuse) | Reject for v1.2; revisit v1.3+ |
| 3b. New sibling: `mailglass_test` extraction | Low (current `Mailglass.TestAssertions` already vendorable in test deps) | Small but speculative | Reject — premature extraction without adopter complaints |
| 4. Multi-tenant deepening (per-tenant domains, rate pools, audit isolation) | Med-high for SaaS adopters, but no signal yet | Large; bleeds into outbound and admin | Reject for v1.2; capture as v1.3 candidate pending adopter signal |
| 5. Marketing-adjacent ops (digest scheduling, TZ-aware send, double-opt-in) | Low — D-03 wall is load-bearing brand discipline | Med | Reject. Even "transactional consent" pulls toward Noticed-shaped surface (D-04) |
| 6. Adopter discovery / smaller v1.2 + outreach | Genuinely unknown — no public adoption data in repo | Tiny build, large calendar | Run *in parallel* with v1.2, not instead of |

## The Strongest Counter-Argument, Made Carefully

The most coherent challenger is **Alternative 1 + 6**: ship a deliberately small "Stability + Listening" v1.2. The argument runs:

1. v1.0 was named **Stability Lock**. Closing it with five accepted-debt items (Phase 35 Nyquist bookkeeping, boundary warnings, manual branch protection, citext race, WR-01..06) is a contradiction in terms. v1.1 then layered a *new* package on that unstable foundation. Compounding surface on unpaid debt is precisely the failure mode every retrospective in `RETROSPECTIVE.md` warns against ("audit-fix-reaudit before close is non-negotiable").
2. The repo has **zero observable adopters** in `STATE.md`, `RETROSPECTIVE.md`, or any open-issue tracking. v0.1 shipped to Hex.pm 11 days ago (2026-04-26). v1.0 shipped 10 days ago. v1.1 shipped 0–1 days ago — and the live `v1.0` Hex publish is *still pending closeout*. The "production confidence" framing of inbound completion presumes a user base whose feedback we do not have.
3. Per CLAUDE.md, the maintenance budget is "one-person maintainer realistic; v0.1 must be coastable for 6 months without releases." Three milestones (v1.0, v1.1, v1.2) inside two weeks of the first Hex publish is a velocity that *creates* maintenance burden faster than adopters can surface real-world signal to direct it. Mailgun + SES + observability + test helpers + operator tools is the v0.4–v0.6 arc compressed into one milestone, applied to a package nobody has yet deployed in anger.
4. D-22 explicitly justified v1.1's narrow Postmark+SendGrid scope as "supportable for a one-person maintainer." Nothing about that constraint changed in 24 hours. Doubling provider surface and adding admin/observability/test/operator surface in v1.2 walks back D-22 without new evidence.

## What Would Have to Be True for the Alternative to Win

For Stability+Listening v1.2 to beat inbound completion, **at least two** of these must hold:

- **A1.** Real adopter signal exists or can be gathered cheaply showing Postmark/SendGrid coverage is insufficient before v1.2 ships. (Evidence: GitHub issues, ElixirForum threads, download trajectory, direct DM traffic.)
- **A2.** The carry-forward debt is *blocking* adopters today — citext race causes flaky CI in adopter projects; manual branch protection is causing accidental main-push regressions; boundary warnings mask real boundary violations.
- **A3.** A second post-v1.0 expansion (relay, multi-tenant deepening, outbound completion) has a stronger vision-fit than inbound completion.

**Reality check on each:**
- A1: No adopter signal exists in the planning artifacts at all. This is precisely Alternative 6's premise — and it's a reason to *gather signal*, not to *delay inbound*. A 1-week outreach effort is compatible with a 4–6-week v1.2 inbound milestone running in parallel.
- A2: The debt is genuinely small-bore (test-environment race, two boundary warnings, one manual ops step, one bookkeeping field). None of it is adopter-facing in any documented case. Folding it into v1.2 as a single closeout phase costs maybe 1 plan.
- A3: Reviewed all candidates above. None has the vision coherence of inbound completion, which is the *only* expansion already endorsed by D-05, blueprinted by D-22, and partially shipped. Mailgun+SES are the same provider class already proven (D-10 outbound parity). Admin observability for inbound is the same Conductor-shaped UI already deferred from v1.1 by name. Test helpers/operator tools are the same v0.4→v0.6 maturation path outbound already completed.

None of the three conditions hold cleanly. A2 is the closest, and it's addressed by **bundling**, not **replacing**.

## Honest Recommendation

**Ship inbound completion as v1.2** — Mailgun + SES ingress, Conductor-style replay/inspect LiveView surface, `MailglassInbound.TestAssertions` + Case template, operator `mix mailglass.inbound.*` tasks, public replay API.

**Bundle into v1.2 as Phase 0:** the five carry-forward debt items. They are tiny, they are real, and a milestone called "Inbound Production Confidence" cannot honestly ship while a milestone called "Stability Lock" still has open debt.

**Run in parallel (not as a milestone):** lightweight adopter outreach — pin a GitHub Discussion, post one ElixirForum thread announcing v1.0+v1.1, watch for issues. If signal arrives mid-v1.2 contradicting the plan, re-scope. Otherwise the orchestrator's hypothesis is correct.

The hypothesis is right. The honest amendment is one phase of debt closeout, not a different milestone.

## References

1. Anymail event-taxonomy + provider parity reasoning (D-14 source) — https://anymail.dev/en/stable/esps/
2. Rails ActionMailbox Conductor dev UI — the "DX superpower" called out in `prompts/Phoenix needs an email framework not another mailer.md` §3 — https://guides.rubyonrails.org/action_mailbox_basics.html#conductor
3. Oban Web (the admin-observability shape inbound replay UI should mirror) — https://hexdocs.pm/oban/Oban.Web.html
4. SES inbound (Lambda/SNS) and Mailgun inbound webhook contracts (the v1.2 ingress surface) — https://docs.aws.amazon.com/ses/latest/dg/receiving-email.html and https://documentation.mailgun.com/docs/mailgun/user-manual/receive-forward-store/
5. `gen_smtp` server behaviour (the deferred `mailglass_relay` candidate this report rejects for v1.2) — https://hexdocs.pm/gen_smtp/gen_smtp_server.html
