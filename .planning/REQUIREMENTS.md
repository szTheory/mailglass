# Requirements: mailglass - v2.1 Postgres + Admin URL Hardening

> **Milestone v2.1 (maintenance).** Close two bounded post-v2.0 hardening gaps:
> schema-prefix correctness must not depend on a patched DB `search_path`, and
> admin stylesheet URLs must survive hard refreshes and deep links from every
> mounted admin surface.
>
> Defined 2026-07-07 from in-thread repository research, focused subagent reads,
> and official Ecto/Phoenix behavior checks. This milestone is intentionally not
> a product-expansion, redesign, or release-cut milestone.

---

## Milestone v2.1 Requirements

### SCHEMA - No-search-path schema-prefix hardening

- [x] **SCHEMA-01**: A focused runtime proof shows `Mailglass.Webhook.Replay` updates projections in the
  configured schema when the DB connection `search_path` does not include that schema.

- [x] **SCHEMA-02**: A focused runtime proof shows unsubscribe replay/idempotency conflict lookups read from
  the configured schema when the DB connection `search_path` does not include that schema.

- [x] **SCHEMA-03**: Raw repo calls and transaction callbacks that touch mailglass tables use an explicit
  `prefix:`, the mailglass repo facade, or an allowlisted schema-agnostic query; recurrence is blocked by a
  static regression guard.

- [x] **SCHEMA-04**: Inbound extension points that accept a repo option either route through the inbound
  facade by default or document and prove the explicit-prefix contract when a raw repo is supplied.

### AAU - Admin asset URL robustness

- [x] **AAU-01**: First HTML for preview, preview scenario, preview error, gallery, operator, inbound, and
  query deep-link routes emits a stylesheet `href` rooted at the current admin mount path, never a bare
  relative path.

- [x] **AAU-02**: Hard refreshes and direct deep links for those routes load CSS and font assets with 200
  responses and expected content types; nested routes do not request assets relative to their own path.

- [x] **AAU-03**: The same asset proof passes for an arbitrary alternate mount path without adding public
  router macro options.

- [x] **AAU-04**: A browser gate fails on CSS/font 404s and asserts token-backed computed styling after
  direct `page.goto` loads, proving the page is styled rather than merely rendering HTML.

### GATE - Verification lanes

- [x] **GATE-01**: A focused schema-prefix verification lane, exposed as `mix verify.schema_prefix` or an
  equivalent existing alias, runs the hostile no-search-path DB proof and the static prefix guard.

- [x] **GATE-02**: The existing dual-schema advisory matrix remains a broad canary, while docs and comments
  clearly identify the focused no-search-path lane as the fail-closed proof for this milestone.

- [x] **GATE-03**: Admin URL robustness has both fast LiveView/Conn-level assertions for generated hrefs and
  a serialized browser proof for network/computed-style behavior.

### DOC - Documentation and planning reconciliation

- [ ] **DOC-01**: `mailglass_admin/docs/design-system.md`, `guides/run-the-demo.md`, and the admin
  relative-asset backlog item no longer claim hard-refresh/deep-link styling remains unresolved after the
  proof passes.

- [ ] **DOC-02**: Active planning artifacts keep broader UI verification discipline and ecosystem
  integrations explicitly deferred so v2.1 stays a narrow hardening milestone.

---

## Out of Scope (explicit exclusions - v2.1)

- New providers, transports, routes, public product capabilities, or release ceremony.
- Admin redesign, brand refresh, token changes, component changes, layout changes, or motion work.
- Public router macro API changes unless a phase proves the existing mount-aware path cannot satisfy the
  asset requirements.

- CDN/host asset pipeline changes, duplicate asset routes, `<base>` tags, or redirects as the primary
  asset fix.

- Screenshot/pixel-diff visual gating. Browser proof is network + computed-style based.
- Whole-suite no-search-path fixture migration as a first step. v2.1 creates the focused hostile lane and
  recurrence guard; broader fixture cleanup remains future work unless needed for honesty.

- SEED-003 ecosystem integrations, Cloudflare routing, synthetic inbound dev UI, `gen_smtp`, or additional
  provider work.

## Future Requirements (deferred, not this milestone)

- Broader UI verification discipline after v2.1, including any full admin visual/a11y sweep the maintainer
  chooses to run.

- A whole-suite no-search-path fixture cleanup if the focused lane exposes broader systemic drift.
- Ecosystem integrations only with real adopter pull.

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| SCHEMA-01 | Phase 138 | Complete |
| SCHEMA-02 | Phase 138 | Complete |
| SCHEMA-03 | Phase 138 | Complete |
| SCHEMA-04 | Phase 138 | Complete |
| GATE-01 | Phase 138 | Complete |
| GATE-02 | Phase 138 | Complete |
| AAU-01 | Phase 139 | Complete |
| AAU-02 | Phase 139 | Complete |
| AAU-03 | Phase 139 | Complete |
| AAU-04 | Phase 139 | Complete |
| GATE-03 | Phase 139 | Complete |
| DOC-01 | Phase 140 | Pending |
| DOC-02 | Phase 140 | Pending |

---

*Last updated: 2026-07-07 - v2.1 requirements defined.*
