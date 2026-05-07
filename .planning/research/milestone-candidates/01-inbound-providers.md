# Milestone Candidate: Inbound Provider Matrix Expansion

**Status:** Research draft for v1.2 scoping
**Author:** research agent (one of five)
**Date:** 2026-05-06

## Summary verdict

**Ship Mailgun + SES (SNS) inbound. Defer Cloudflare Email Routing to a future milestone, and treat `gen_smtp` SMTP listener as its own milestone — it is a different transport class entirely.**

This is the conservative-plus shape. Rationale:

1. Mailgun and SES are the **only two providers** in Anymail's "Tier 1 inbound" list besides Postmark and SendGrid (which v1.1 already shipped). Together they cover ~80% of Phoenix/Rails apps that ingest inbound mail in 2026.
2. The outbound webhook side **already ships verifiers for Mailgun (HMAC-SHA256 + replay cache) and SES (full SNS X.509 + CertCache + TrustPolicy)** at `/Users/jon/projects/mailglass/lib/mailglass/webhook/providers/mailgun.ex` and `/Users/jon/projects/mailglass/lib/mailglass/webhook/providers/ses.ex`. The crypto, replay defense, cert pinning, and SubscriptionConfirmation flow are solved problems in this repo. The inbound milestone is mostly **MIME parsing + lifting verifier patterns**, not new cryptography.
3. Cloudflare Email Routing's "webhook" output is **not a Cloudflare-defined contract** — it's whatever Worker code the user writes to POST. There is no signature scheme, no SDK, no first-party shape to normalize. Supporting it well means recommending users forward to a Postmark/SendGrid endpoint, not building a "Cloudflare provider."
4. `gen_smtp` is a **persistent listener (`:ranch` + TLS + STARTTLS), not a Plug**. It needs its own supervision tree, its own port, its own deployment story (port 25 firewall rules, reverse PTR, MX records). That's not a provider — it's a third ingress transport alongside webhook + replay. Conflating them in one milestone produces a muddy scope.

## Per-provider table

| Provider | Adoption signal | Implementation cost | Top footguns | Recommendation |
|---|---|---|---|---|
| **Mailgun** | Anymail Tier 1; Action Mailbox first-class ingress; HMAC scheme is the canonical one Anymail/ActionMailbox docs reference. Docs link in `prompts/Phoenix needs an email framework not another mailer.md`. | **Low.** Verifier already shipped at `lib/mailglass/webhook/providers/mailgun.ex:1-100` (HMAC-SHA256 over `timestamp+token`, 5-min tolerance, replay cache). MIME parse via raw multipart payload. | Deprecated v0 webhook signature scheme (different fields); 5-minute replay window must be enforced; multipart form payload includes attachments inline as form parts (not base64). | **Ship.** Lift verifier near-verbatim into `MailglassInbound.Ingress.Providers.Mailgun`. |
| **SES (via SNS)** | Anymail Tier 1; cheapest at scale; `prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` notes "no canonical Elixir SES bounce/complaint library — teams roll their own" — mailglass would fill this gap on inbound side too. | **Medium.** Full SNS verifier shipped at `lib/mailglass/webhook/providers/ses.ex:1-100` (X.509, CertCache ETS, TrustPolicy, SubscriptionConfirmation auto-confirm). MIME body fetch from S3 is the new piece — needs `:ex_aws_s3` as optional dep or documented adopter-supplied fetcher. | SES inbound puts MIME in S3, sends pointer in SNS. **S3 fetch can race SNS delivery** — must retry with exponential backoff. SubscriptionConfirmation hijacking (CVE class) — already mitigated by TrustPolicy URL allowlist. SNS message-type dispatch must happen post-verification. | **Ship.** Lift SNS verifier verbatim. Inbound-specific work is the S3 fetcher abstraction (behaviour + default `:ex_aws_s3` adapter + `Fake` for tests). |
| **Cloudflare Email Routing** | Workers-based, no first-party webhook contract. Stack Overflow / GitHub: production users universally **forward via Worker `fetch()` to a Postmark/SendGrid/Mailgun receiving endpoint**, not to a Cloudflare-defined endpoint. | **High and ill-defined.** No signature scheme to verify; no canonical payload shape. Best we can offer is a documented recipe ("here's the Worker snippet that POSTs to your Mailglass `/inbound/postmark` endpoint with shared-secret Basic Auth"). | Anyone shipping CF Email Routing with a real webhook ends up with a homegrown HMAC layer. Supporting it as a "provider" in mailglass would mean inventing a contract Cloudflare hasn't. | **Defer.** Document a recipe in `mailglass_inbound/docs/` for the Workers `fetch()` → existing Postmark-shaped endpoint pattern. Re-evaluate when/if Cloudflare ships first-party signed inbound webhooks. |
| **gen_smtp listener** | Niche but real (Discourse, on-prem ops, customers without DNS access to a SaaS provider). ActionMailbox `relay` ingress is the comparable feature. | **Very high.** New transport class entirely — `:ranch` listener, STARTTLS, SPF/DKIM check (or explicit "trust upstream MTA" config), spam-handling story (greylisting? Rspamd handoff?), supervision tree, port 25 deployment docs. Not a Plug. | Running an SMTP daemon means owning the entire spam/abuse surface. ActionMailbox's `relay` ingress sidesteps this by requiring an upstream MTA (Postfix) to do SMTP; mailglass should follow suit — accept on a localhost-bound port from a trusted MTA only, never expose port 25 directly. | **Defer to its own milestone (v1.3 or later).** Different shape, different deployment risk, different operator audience. |
| **Mailtrap** | Dev/staging, low real production usage. Supports Postmark-shaped webhooks for inbound when configured. | Trivial — works with Postmark adapter today. | None. | **Document** as "use the Postmark provider with Mailtrap's Postmark-compatible inbound webhook config." No code. |

## Concrete Elixir patterns to adopt

### 1. Mailgun verifier — lift from outbound webhook side

Current outbound impl at `lib/mailglass/webhook/providers/mailgun.ex:18-45` is exactly the right shape. Inbound differs only in what `normalize/2` produces (`%InboundMessage{}` instead of `[%Event{}]`). The replay cache at `lib/mailglass/webhook/providers/mailgun_replay_cache.ex:1-45` (ETS-backed, 8h TTL by default) carries over unchanged — Mailgun reuses the same `signature.token` for inbound and event webhooks.

Use the **same** `MailgunReplayCache` GenServer; do not stand up a second one.

### 2. SES SNS verifier — lift verbatim from outbound

`lib/mailglass/webhook/providers/ses.ex:55-100` and the helper modules `ses/cert_cache.ex`, `ses/trust_policy.ex`, `ses/cert_cache/{supervisor,table_owner}.ex` are reusable as-is. The inbound MailglassInbound module should `alias Mailglass.Webhook.Providers.SES.{CertCache, TrustPolicy}` rather than fork them. Cross-package alias is fine — `mailglass_inbound` already depends on `mailglass`.

The new code is a **`MailglassInbound.Ingress.Providers.SES.S3Fetcher` behaviour** with `:ex_aws_s3` optional gateway through `Mailglass.OptionalDeps.ExAwsS3` (new gateway module, mirror of existing `Mailglass.OptionalDeps.GenSmtp` at `lib/mailglass/optional_deps/gen_smtp.ex:1-22`). Default fetcher fetches with retry; `Fake` fetcher returns a fixture MIME blob for tests.

### 3. MIME parsing — use `:gen_smtp`'s `:mimemail`

`gen_smtp` is **already declared as an optional dep** (`prompts/.../STACK.md`, `lib/mailglass/optional_deps/gen_smtp.ex`). The Erlang `:mimemail.decode/1` function is battle-tested (Discourse uses it; gen_smtp has been on Hex since 2010). The `Sendgrid` provider at `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex:125-205` currently hand-rolls multipart parsing — that hand-roll is the correct first-pass shape (no new dep) but **is a known sharp edge for nested multiparts and quoted-printable bodies**.

**Recommendation:** introduce `MailglassInbound.MIME` module with two backends:
- Default: hand-rolled (current Sendgrid path) — handles 90% of real inbound
- Optional `:gen_smtp` backend: `:mimemail.decode/1` — handles nested multiparts, QP, base64, RFC 2047 encoded headers properly

Gate via `Mailglass.OptionalDeps.GenSmtp.available?/0`. Mailgun + SES inbound **require** `:gen_smtp` because raw MIME from S3 / multipart-form will hit nested-multipart real-world cases the hand-roller drops.

### 4. Provider behaviour evolution

The current callback signature in `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex:14-23` already supports a `Request` struct via the SendGrid path (see `providers/sendgrid.ex:11-22`). Standardize **all** providers on `verify!(%Request{}, config)` and `normalize(%Request{})` — drop the old `(raw_body, headers)` arity once Mailgun + SES land. SendGrid is already mid-migration; this is the moment to finish it.

## Idiomatic vs anti-idiomatic choices

**Idiomatic:**
- Verify-first plug pipeline (already the v1.1 shape) — `verify! → resolve_tenant → normalize → persist → maybe_execute`
- Raise `Mailglass.SignatureError` on any verification failure, never recover (CLAUDE.md "Things Not To Do" #5)
- Optional-dep gateway pattern for `:ex_aws_s3` and `:gen_smtp` (CLAUDE.md "Engineering DNA")
- One MIME module shared across providers; not three copies of multipart parsing
- Reuse `MailgunReplayCache` and `SES.CertCache` from the outbound side — single ETS table per concern

**Anti-idiomatic (a senior reviewer will flag these):**
- Inventing a new "Cloudflare" provider when Cloudflare ships no contract → invent a recipe instead
- Putting `gen_smtp` listener in this milestone → conflates webhook ingress (request/response) with persistent socket listener (long-running supervised port). Different lifecycle, different supervision, different ops surface.
- Hand-rolling RFC 2047 header decoding when `:mimemail` already does it
- Pulling `:ex_aws` (the umbrella) instead of `:ex_aws_s3` only — bloats the dep tree
- Forking SES verifier into `mailglass_inbound` instead of aliasing across the package boundary
- Adding an `auto-confirm SubscriptionConfirmation` toggle that defaults to `true` without TrustPolicy URL allowlist — outbound side already gets this right, inbound must match

## What I'd cut from scope

If the milestone gets tight: **cut the SES S3 fetcher abstraction and ship SES SNS verification only with a stubbed `S3Fetcher.Adopter` behaviour adopters implement themselves.** The MIME-from-S3 fetch is the operationally riskiest piece (race conditions, IAM, retry policy) and adopters running SES inbound at scale already have AWS SDK opinions. Shipping the verifier + behaviour + Fake is enough to unblock them; the production fetcher can land in a v1.2.1 patch.

The other tempting cut — Mailgun replay cache — should **not** be cut. Mailgun's webhook security guide explicitly warns about replay attacks; shipping without replay defense is shipping a known CVE.

Also non-negotiable: `Mailglass.SignatureError` raises on verification failure with no recovery (CLAUDE.md #5). Don't add a `:relaxed` mode "for development."

## References

1. **Mailgun webhook security** — https://documentation.mailgun.com/docs/mailgun/user-manual/webhooks/securing-webhooks (HMAC-SHA256 over `timestamp+token`, replay window guidance)
2. **AWS SNS message signing** — https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html (canonical string format, X.509 cert URL allowlist requirement, SignatureVersion 1 vs 2)
3. **AWS SES inbound to S3+SNS** — https://docs.aws.amazon.com/ses/latest/dg/receiving-email-action-s3.html (S3 object key format, SNS notification race window, IAM policy)
4. **ActionMailbox source — Mailgun + SES + Relay ingresses** — https://github.com/rails/rails/tree/main/actionmailbox/app/controllers/action_mailbox/ingresses (canonical Rails patterns to mine; relay ingress shows the "trusted upstream MTA on localhost" model for `gen_smtp`-equivalent)
5. **Anymail inbound webhook docs** — https://anymail.dev/en/stable/inbound/ (normalization across Mailgun/SES/Postmark/SendGrid; what fields they treat as canonical vs provider-specific)
6. **Cloudflare Email Workers** — https://developers.cloudflare.com/email-routing/email-workers/ (confirms there is no Cloudflare-defined webhook contract; it's user-written `fetch()` to user-defined endpoint)

## File references for the orchestrator

- Existing inbound provider behaviour: `/Users/jon/projects/mailglass/mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex`
- Existing inbound plug: `/Users/jon/projects/mailglass/mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` (lines 17-27 hard-code `[:postmark, :sendgrid]` — must extend)
- Existing inbound providers (the pattern): `/Users/jon/projects/mailglass/mailglass_inbound/lib/mailglass_inbound/ingress/providers/{postmark,sendgrid}.ex`
- **Existing OUTBOUND verifier to lift (Mailgun):** `/Users/jon/projects/mailglass/lib/mailglass/webhook/providers/mailgun.ex` (232 LOC, complete)
- **Existing OUTBOUND verifier to lift (SES SNS + helpers):** `/Users/jon/projects/mailglass/lib/mailglass/webhook/providers/ses.ex` (653 LOC, complete) + `ses/cert_cache.ex`, `ses/trust_policy.ex`, `ses/cert_cache/{supervisor,table_owner}.ex`
- Existing optional-dep gateway pattern: `/Users/jon/projects/mailglass/lib/mailglass/optional_deps/gen_smtp.ex` (mirror this for `:ex_aws_s3`)
- D-22 ("Conductor / Mailgun / SES / gen_smtp deferred") in `/Users/jon/projects/mailglass/.planning/PROJECT.md:221` — this milestone explicitly closes the Mailgun + SES half of D-22.
