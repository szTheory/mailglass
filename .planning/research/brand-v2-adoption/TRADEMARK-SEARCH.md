# Trademark and name search: mailglass

Retrieved 2026-11-13 by an automated agent (Claude Code). This is not legal advice. It records what a script could check and what it could not. The machine-readable record is `trademark-search.json` beside this file; the announcement gate (`scripts/brand_trademark_gate.exs`) reads that file, not this one. Keep the two in step.

Basis for the owner hand-off: `.planning/METHODOLOGY.md` line 9 keeps `human_needed` only for criteria that need legal or otherwise unavailable human judgment after reasonable automation, and `.planning/research/brand-v2-adoption/MILESTONE-PROPOSAL.md` line 65 lists the "trademark/counsel call before announcement" as an owner decision. The register searches below cannot be run by an agent; everything an agent could run has been run.

## Summary

| Field | Value |
|---|---|
| Mark | mailglass |
| Variants searched | mailglass, mail glass, MailGlass, glassmail, mailglas |
| Classes | 9 (software), 38 (telecommunications and message transmission), 42 (software as a service) |
| Overall | **caution** |
| Registers checked (USPTO, TMview, WIPO) | **no** (`register_checked: false`) |
| Owner override | none |
| Record date | 2026-11-13 |
| Expires | 2027-05-12 (180 days) |

The announcement gate denies until the owner register pass further down is recorded: no announcement and no trademark symbol (the TM or R-in-a-circle character) in README, CHANGELOG, docs, guides or brandbook markdown. A test enforces the symbol rule (`test/scripts/brand_trademark_gate_test.exs`). Refresh the record at 180 days, or at the next release or announcement, whichever comes first.

Only the public word "mailglass" and its variants were sent to any registry or search page. The `searcher` field names the tool, not a person.

## Searches run

Every row was fetched on 2026-11-13 with a plain HTTP client (a generic user agent where an API requires one) and matches the `sources` array in `trademark-search.json`.

| id | Query or URL | Retrieved | Outcome | Tier |
|---|---|---|---|---|
| hex | https://hex.pm/api/packages?search=mailglass | 2026-11-13 | clear | primary |
| npm_exact | https://registry.npmjs.org/mailglass | 2026-11-13 | clear | primary |
| npm_search | https://registry.npmjs.org/-/v1/search?text=mailglass&size=10 | 2026-11-13 | caution | primary |
| pypi | https://pypi.org/pypi/mailglass/json | 2026-11-13 | clear | primary |
| rubygems | https://rubygems.org/api/v1/gems/mailglass.json | 2026-11-13 | clear | primary |
| crates | https://crates.io/api/v1/crates/mailglass | 2026-11-13 | clear | primary |
| github | https://api.github.com/search/repositories?q=mailglass+in:name | 2026-11-13 | caution | primary |
| glama | https://glama.ai/mcp/servers?query=mailglass | 2026-11-13 | caution | secondary |
| rdap_com | https://rdap.verisign.com/com/v1/domain/mailglass.com | 2026-11-13 | caution | primary |
| rdap_app | https://pubapi.registry.google/rdap/domain/mailglass.app | 2026-11-13 | caution | primary |
| rdap_other | https://rdap.identitydigital.services/rdap/domain/mailglass.io (also .dev, .email, .org, .net, .co) | 2026-11-13 | clear | primary |
| trademarkia | https://www.trademarkia.com/search/trademarks?query=mailglass (and query=glasmail) | 2026-11-13 | caution | secondary |
| uspto | https://tmsearch.uspto.gov/search/search-information | 2026-11-13 | not_checked | primary |
| tmview | https://www.tmdn.org/tmview/#/tmview | 2026-11-13 | not_checked | primary |
| wipo | https://branddb.wipo.int/en/ | 2026-11-13 | not_checked | primary |
| image_search | https://tineye.com/ | 2026-11-13 | not_checked | secondary |

## Findings

**Package registries.** Hex holds only the project's own three packages (mailglass, mailglass_admin, mailglass_inbound). The exact name `mailglass` is unused on npm, PyPI, RubyGems and crates.io (each returned 404).

**Closest same-name products (adjacent categories, none in the same category):**

- npm `mailglass-email-mcp` 0.0.1, published 2026-11-06, "MailGlass: read-only email MCP server", repository `anantanandgupta/mcp-servers`. The closest same-name adjacent product: an email-reading tool with a near-identical name.
- Glama lists two MCP connectors with the same name: `email.dygc/mailglass` and `email.dygc.mail/mail-glass`.
- GitHub `Mr-Anderson-403/MailGlass-v3.1` (0 stars), an AI-powered email threat-analysis and phishing-detection app.

**Domains** (registry lookups, not trademark registers):

- `mailglass.com`: registered 2024-10-13, expires 2027-10-13, registrar Cloudflare, Inc., Cloudflare nameservers. The registrant is not disclosed, ownership is unverified, and the name did not resolve in DNS on the retrieval date.
- `mailglass.app`: registered 2026-08-14, expires 2027-08-14, registrar Namecheap Inc. The registrant is not disclosed and ownership is unverified. https://mailglass.app/ serves a sign-in page titled "Email Data".
- `mailglass.dev`, `.io`, `.email`, `.org`, `.net` and `.co`: each registry returned 404, meaning no domain object exists there. That says nothing about trademarks.

**Dead mark.** A search aggregator shows one dead mark close to a variant: GLASMAIL, USPTO serial 74299521, class 038 (computer services, a network for the transmission of messages), owner Tides Foundation, filed 1992-07-29, Dead/Cancelled 2000-12-23. A search for `mailglass` itself shows no results. This aggregator is a secondary source, not a register.

**Logo.** An envelope with a letter m is a crowded idea space (Gmail used an envelope-m mark from 2004 to 2020). Distinctiveness of the mailglass mark rests on the sealed-flap treatment, which is a counsel or owner call. No reverse image search has been run.

**Why caution and not clear.** USPTO, TMview, WIPO and image search are `not_checked`, and there are unresolved same-name adjacent products and a dead conflicting mark. An agent cannot move this to `clear`.

## Decision rule

- **blocked**: a live or pending identical or near-identical third-party mark exists in class 9, 38 or 42. The gate denies, and the file can never override it.
- **caution**: any source is `not_checked`, any same-name email or software product is unresolved, or a dead conflicting mark was found. The gate denies unless a populated `owner_override` is present and the record has not expired.
- **clear**: all three registers (USPTO, TMview, WIPO) checked, no live conflicts, and adjacent products dispositioned by the owner. Allowed only with `register_checked: true` and a record that has not expired.

The gate fails closed: a missing, unparseable, wrong-schema, invalid or expired record denies. A record that claims `clear` while any source is `not_checked` or `blocked`, or `register_checked` while a register is `not_checked`, is invalid and denies.

## Remaining for a human

About 15 minutes in a browser, with the owner or counsel. Every URL below was fetched on 2026-11-13; the status shown is what an automated client received.

| URL | HTTP status | Note |
|---|---|---|
| https://tmsearch.uspto.gov/search/search-information | 200 | JavaScript application; search runs in a browser |
| https://www.tmdn.org/tmview/#/tmview | 200 | JavaScript application; search runs in a browser |
| https://branddb.wipo.int/en/ | 200 | Automated clients receive a proof-of-work bot challenge; solve it in a browser |
| https://branddb.wipo.int/en/similarname | 200 | Same challenge applies to automated clients |
| https://lookup.icann.org/en/lookup?name=mailglass.com | 200 | |
| https://lookup.icann.org/en/lookup?name=mailglass.app | 200 | |
| https://tineye.com/ | 200 | |
| https://lens.google.com/ | 200 | |
| https://glama.ai/mcp/servers?query=mailglass | 200 | |
| https://www.npmjs.com/package/mailglass-email-mcp | 403 | Automated clients are refused; open in a browser. Working alternative for the same package: https://registry.npmjs.org/mailglass-email-mcp (200) |
| https://github.com/search?q=mailglass&type=repositories | 200 | |

1. **USPTO trademark search.** Open https://tmsearch.uspto.gov/search/search-information. Search MAILGLASS, MAIL GLASS, GLASSMAIL and MAILGLAS, and filter to international classes 9, 38 and 42. Run a design-code search too, for envelope or letter-m marks. Look for live or pending marks that are identical, near-identical or sound-alike in those classes, and note their owners and goods. Record the outcome in the `uspto` source (`clear`, `caution` or `blocked`) with the date and a one-line note.
2. **TMview.** Open https://www.tmdn.org/tmview/#/tmview. Search the same four terms in the same classes. It covers EUIPO and the national EU offices. Look for live or pending marks. Record the outcome in the `tmview` source.
3. **WIPO Global Brand Database.** Open https://branddb.wipo.int/en/ and also https://branddb.wipo.int/en/similarname for the sound-alike search. Search the same terms. Look for live international registrations in classes 9, 38 and 42. Record the outcome in the `wipo` source.
4. **Domain ownership.** Open https://lookup.icann.org/en/lookup?name=mailglass.com and https://lookup.icann.org/en/lookup?name=mailglass.app. Answer one question: does the project own mailglass.com or mailglass.app? The registry lookups show registrations (2024-10-13 and 2026-08-14) but not who holds them. If the project owns them, say so in the `rdap_com` and `rdap_app` notes; if a third party does, keep `caution` and describe what is served there.
5. **Reverse image search of the mark.** Take the mark (the sealed-flap m) from the pinned brand book. Upload it at https://tineye.com/ and at https://lens.google.com/. Look for look-alike marks, especially envelope-plus-m marks used by email or software products. Record the outcome in the `image_search` source, and note that distinctiveness rests on the sealed-flap treatment.
6. **Same-name products.** Disposition each: the two Glama connectors at https://glama.ai/mcp/servers?query=mailglass, the npm package at https://www.npmjs.com/package/mailglass-email-mcp, and the repositories at https://github.com/search?q=mailglass&type=repositories. For each, decide whether it is a confusion risk (a different category, a hobby project, or a real conflict) and put the decision in the `glama`, `npm_search` or `github` note.
7. **Counsel.** Decide yes or no: engage a trademark attorney before the announcement. If yes, record that in the `note` of the register sources and wait for counsel's reading before changing `overall`.

## How to record the result

Edit `trademark-search.json` by hand. Change only the matching `sources` entries (outcome, retrieved date and note). Then:

- Set `register_checked` to `true` only after USPTO, TMview and WIPO are all checked (none left `not_checked`).
- Set `overall` by the decision rule above. Set `clear` only when every source is out of `not_checked` and none is `blocked`; a record that claims otherwise is invalid and fails the test.
- Set `date` to the search date and `expires` to a later date (180 days is the default).
- Keep `owner_override` null unless deliberately overriding.

Only the owner writes owner_override, in a commit the owner authors and reviews. Agents never write it; an agent asked to must refuse and point here. That commit fills `by` (the owner's handle, never the searcher or an automated agent), `date` and `rationale`, and sets `@acknowledged_override` in `test/scripts/brand_trademark_gate_test.exs` to the identical map. Without the second edit the test "committed owner_override is owner-acknowledged" fails, and an agent-named `by` fails even when acknowledged. The test cannot see who authored a commit, so the authorship rule is a review rule: reject a pull request that adds an override in a commit the owner did not author.

Then verify (export `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` first):

```
mix test test/scripts/brand_trademark_gate_test.exs
mix run --no-start scripts/brand_trademark_gate.exs check
```

The `check` command exits 0 when an announcement is allowed and 1 when it is denied, and prints the reason. Commit as `docs(brand): record trademark register search`.
