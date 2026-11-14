# Phase 179 research (2026-11-13)

Condensed output of three parallel agents behind `179-CONTEXT.md`. Persisted so it is not regenerated. Claims marked (memory) were not fetched.

## Trademark / name search (retrieved 2026-11-13; not legal advice)
- Reached by plain fetch: Hex API, npm registry, GitHub search, crates.io, PyPI JSON (`/pypi/mailglass/json` 404), RubyGems (404), Glama pages, DNS (sandbox only).
- Secondary only: Trademarkia ("mailglass" 0 results; "mail glass" 11,537 fuzzy hits, page 1 unrelated; GLASMAIL serial 74299521 class 38 cancelled 2000-12-23).
- NOT reachable, so `not_checked`: USPTO tmsearch (JS app), WIPO Global Brand Database, EUIPO TMview, Justia (403), WHOIS/RDAP (403), image/logo search, UK IPO/CIPO/state registers.
- Findings: Hex only our three packages; PyPI/RubyGems/crates.io exact name free; npm `mailglass` free but `mailglass-email-mcp` (proprietary read-only email MCP server, published 2026-11-06, anantanandgupta/mcp-servers) is the closest same-name adjacent product; Glama `email.dygc/mailglass` ("Disposable email for AI agents") and `email.dygc.mail/mail-glass`; GitHub `Mr-Anderson-403/MailGlass-v3.1` (AI phishing-analysis Flask app, 0 stars); `mailglass.app` resolves to a login page "Email Data"; `mailglass.com` Cloudflare NS, no A record; `.io/.dev/.email/.net/.org/.co` show no nameservers.
- Lessons: Clawdbot -> Moltbot -> OpenClaw (2026, searched exact string only, missed phonetic neighbour); Hudson -> Jenkins (2011); MIT does not license the name; cheapest rename is before users depend on it; ™ needs no registration and does not clear anyone's earlier rights (law-firm sources, not USPTO text).
- Gate rule and record format: see D-20..D-23 in `179-CONTEXT.md`.
- Human remainder (~15 min): USPTO, TMview, WIPO searches for MAILGLASS, MAIL GLASS and sound-alikes (GLASSMAIL, MAILGLAS) in classes 9/38/42 plus design-code search; WHOIS on `mailglass.app`/`.com`; decide on the two same-name MCP products; whether to engage counsel.

## Compatibility policy, status map, brand pin (prior art)
- Elixir removes deprecated features only in majors (hexdocs.pm/elixir/compatibility-and-deprecations.html); Stripe keeps API object names stable while dashboard labels are friendlier (memory).
- Postmark: Delivered = recipient server accepted; API "Transient" vs UI "Delayed" (postmarkapp.com/support/article/1267). SendGrid: Dropped = no attempt, Deferred carries SMTP response (docs.sendgrid.com/ui/analytics-and-reporting/email-activity/). Resend: `suppressed` = never attempted, `delivery_delayed` retries ~14 h then bounces (resend.com/docs/dashboard/emails/manage-emails). Late events overwriting `delivered`: milo-os/resend-provider issue #38.
- Pin precedent: exifcleaner `brand.pin.json` + `scripts/lib/brand.mjs`; Cargo.lock checksums, npm integrity, Go sumdb (memory). The pinned zip downloads from `raw.githubusercontent.com/szTheory/mailglass-brand/240bdd214746b956162b8d4f2f82d4b178106eff/mailglass-brand.zip` and hashes to `ed96bb25...f87b` (1,943,435 bytes), verified by the research agent.
- Footguns: the book's `brand.json` TTF hashes will not match shipped woff2 subsets; `config/test_exceptions.exs` is line-keyed; `verify.support_contract.core` is a file allow-list; policy tests must not collide with `operator_trust_doc_test` and the docs contract tests.
