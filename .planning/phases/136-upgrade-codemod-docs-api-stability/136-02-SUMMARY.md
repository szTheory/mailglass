---
phase: 136-upgrade-codemod-docs-api-stability
plan: 02
subsystem: docs
status: complete
tags: [docs, api_stability, upgrade-guide, schema-isolation, publish-allowlist, hexdocs]
requires: []
provides:
  - "guides/upgrading-to-v2_0.md (adopter-facing v2.0 schema-isolation upgrade guide)"
  - "config :mailglass, :schema documented as a stable 2.0 surface (core api_stability)"
  - "config :mailglass_inbound, :schema documented as a stable 2.0 surface (inbound api_stability)"
  - "publish allowlist entry for the v2.0 guide (unblocks Phase 137 release)"
affects:
  - "Phase 137 (2.0 release) — the allowlist entry prevents the 1.10.2 tag-move dance"
  - "HexDocs rendering — guide appears under Guides"
tech-stack:
  added: []
  patterns:
    - "doc-token ExUnit test (pure File.read! substring assertions, async: true, no DB)"
    - "publish allowlist byte-compare enumeration (sorted, one line per shipped file)"
key-files:
  created:
    - "guides/upgrading-to-v2_0.md"
    - "test/mailglass/upgrade_v2_docs_test.exs"
  modified:
    - "docs/api_stability.md"
    - "mailglass_inbound/docs/api_stability.md"
    - "mix.exs"
    - ".planning/publish/mailglass-files.expected"
key-decisions:
  - "Placed the v2.0 guide in true sorted position (after upgrading-to-v1_0.md, before webhook-troubleshooting.md) per sort -c, not the plan's imprecise 'between v0_1 and v1_0' hint — sort -c is the authoritative publish gate."
  - "Inserted ## §Schema config (2.0) after ## §Repo.multi (Phase 3) in the core api_stability doc, mirroring the existing Since:-lined subsection shape."
  - "Inbound :schema documented as a new stable-inventory subsection (### Schema config (2.0)) before ## Inventory Notes — ADD-only, disturbing no existing tier-1 required token."
requirements-completed:
  - UPG-02
  - UPG-03
coverage:
  - deliverable: "guides/upgrading-to-v2_0.md documents Route A, Route B, create_schema:false grants, public.mailglass_ grep checklist, lock_timeout/55P03 posture (UPG-02)"
    verification:
      - kind: test
        ref: "test/mailglass/upgrade_v2_docs_test.exs#UPG-02 — guides/upgrading-to-v2_0.md content"
        status: pass
    human_judgment: false
  - deliverable: "config :mailglass[_inbound], :schema documented as a stable 2.0 surface (Since 2.0.0) with tenancy-vs-schema orthogonality (UPG-03)"
    verification:
      - kind: test
        ref: "test/mailglass/upgrade_v2_docs_test.exs#UPG-03 — :schema documented as a stable 2.0 surface"
        status: pass
      - kind: command
        ref: "mix mailglass.docs.check (confirms no inbound tier-1 required token disturbed)"
        status: pass
    human_judgment: false
  - deliverable: "v2.0 guide wired into mix.exs extras/groups_for_extras + present in publish allowlist (sorted) — UPG-02 release gate"
    verification:
      - kind: test
        ref: "test/mailglass/upgrade_v2_docs_test.exs#UPG-02 release gate — guide wired for publish + HexDocs"
        status: pass
      - kind: command
        ref: "LC_ALL=C sort -c .planning/publish/mailglass-files.expected"
        status: pass
    human_judgment: false
duration: 3 min
completed: 2026-07-03
---

# Phase 136 Plan 02: Upgrade docs + `:schema` api_stability contract Summary

Shipped the adopter-facing mailglass 2.0 schema-isolation upgrade guide (both routes, grants, grep checklist, locking posture), declared `config :mailglass[_inbound], :schema` a stable 2.0 surface with the tenancy-vs-schema orthogonality statement in both api_stability docs, and wired the guide into HexDocs + the publish allowlist so Phase 137's 2.0 release will not repeat the 1.10.2 tag-move dance.

## Metrics

- Duration: 3 min (2026-07-03T10:23:33Z → 2026-07-03T10:26:44Z)
- Tasks: 4/4
- Files: 6 (2 created, 4 modified)
- Commits: 4 (1 test, 3 docs)

## Accomplishments

- **`guides/upgrading-to-v2_0.md` (UPG-02)** — new adopter guide in mailglass voice covering: Route A (one-line `config :mailglass, :schema, "public"` opt-out); Route B (`mix mailglass.upgrade.v2_schema` move migration) with the safety facts, the `public.mailglass_*` literal-SQL grep checklist, the `SET LOCAL lock_timeout = '5s'` + `55P03` retry-off-peak locking posture, the `create_schema: false` grants block (`CREATE SCHEMA … AUTHORIZATION` / `GRANT USAGE` / `ALTER DEFAULT PRIVILEGES`), rollback, and verification. No internal `D-NN`/`LINT-NN` tokens in the prose (safe if later added to `docs.check` tier-1).
- **`docs/api_stability.md` `## §Schema config (2.0)` (UPG-03)** — documents `config :mailglass, :schema` (valid unquoted identifier validated at boot, default `"mailglass"`, `"public"` the explicit opt-out), `Since: 2.0.0`, and the tenancy-vs-schema orthogonality paragraph (`orthogonal to tenant_id`; `:schema` is not a per-tenant prefix).
- **`mailglass_inbound/docs/api_stability.md` `### Schema config (2.0)` (UPG-03)** — mirror subsection for `config :mailglass_inbound, :schema`, same contract shape + `Since: 2.0.0` + orthogonality. ADD-only; `mix mailglass.docs.check` confirms no existing tier-1 required token was disturbed.
- **HexDocs + publish allowlist wiring (UPG-02 release gate)** — `guides/upgrading-to-v2_0.md` added to `mix.exs` `extras:` and `groups_for_extras: Guides:`, and added to `.planning/publish/mailglass-files.expected` in sorted position (after `upgrading-to-v1_0.md`). This is the LOAD-BEARING mitigation for T-136-05: the publish allowlist byte-compares the tarball file list and hard-blocks any un-enumerated shipped file.
- **`test/mailglass/upgrade_v2_docs_test.exs`** — new `async: true` doc-token + allowlist-presence test (9 tests) locking every required section/token; written RED first (Wave 0), driven GREEN by Tasks 2–4.

## Verification Results

| Gate | Command | Result |
|------|---------|--------|
| Docs test (full) | `mix test test/mailglass/upgrade_v2_docs_test.exs --seed 0` | PASS (9 tests, 0 failures) |
| Inbound tier-1 tokens intact | `mix mailglass.docs.check` | PASS (Tier 1 docs match the stability contract) |
| Allowlist sorted | `LC_ALL=C sort -c .planning/publish/mailglass-files.expected` | PASS |
| mix.exs compiles | `mix compile --warnings-as-errors` | PASS |
| Format (touched .ex/.exs) | `mix format --check-formatted test/mailglass/upgrade_v2_docs_test.exs mix.exs` | PASS |

Note (per repo memory): bare `mix test` was NOT used as the gate — it carries ~57 unrelated Oban failures plus known dep-JS-noise failures. Gated on this plan's own test file + the doc/allowlist verification the plan specifies.

## Commits

- `b3542e30` test(136-02): add failing docs-token + allowlist-presence test
- `54ed0ade` docs(136-02): author guides/upgrading-to-v2_0.md (UPG-02)
- `40db17cb` docs(136-02): document :schema as a stable 2.0 surface in both api_stability docs (UPG-03)
- `adc630ed` docs(136-02): wire upgrading-to-v2_0 guide into HexDocs + publish allowlist (UPG-02 release gate)

## Deviations from Plan

**1. [Rule 3 — Blocker/sorting] Allowlist insertion position corrected against `sort -c`**
- **Found during:** Task 4
- **Issue:** The plan (and 136-RESEARCH Decision 4 item 2) stated the new line "slots between `guides/upgrading-from-v0_1.md` and `guides/upgrading-to-v1_0.md` alphabetically." That is incorrect — `upgrading-to-v2_0.md` sorts *after* `upgrading-to-v1_0.md` (`v2` > `v1`), before `webhook-troubleshooting.md`. Following the hint literally would have failed the `sort -c` gate the same task requires.
- **Fix:** Placed the line in true sorted position (after `upgrading-to-v1_0.md`), verified with `LC_ALL=C sort -c` (PASS) before committing.
- **Files modified:** `.planning/publish/mailglass-files.expected`
- **Verification:** `LC_ALL=C sort -c .planning/publish/mailglass-files.expected` passes; docs test allowlist assertion passes.
- **Commit:** `adc630ed`

**Total deviations:** 1 auto-fixed (1 blocker/sorting). **Impact:** none on scope — the guide is correctly enumerated and the allowlist gate is satisfied; the plan's alphabetical hint was imprecise but the `sort -c` gate it also mandated caught it.

## Threat Mitigations Applied

- **T-136-05 (DoS — release hard-block):** mitigated. Guide added to the allowlist (sorted); the docs test asserts the exact line is present so the omission cannot regress silently.
- **T-136-06 (Info disclosure — under-specified grep):** mitigated. Guide includes the explicit `public.mailglass_` grep string + the "qualification cannot rescue literal SQL" caveat; docs test asserts the token.
- **T-136-07 (Tampering — inbound doc token removal):** mitigated. ADD-only edit; `mix mailglass.docs.check` re-run confirms no tier-1 required token disturbed.
- **T-136-08 (Repudiation — `:schema` conflated with per-tenant prefix):** mitigated. Both api_stability docs carry the explicit tenancy-vs-schema orthogonality statement; docs test asserts the `orthogonal to tenant_id` token.

## Known Stubs

None.

## Issues Encountered

None.

## Next Phase Readiness

Ready for orchestrator wave completion. Plan 136-01 (codemod) and 136-02 (docs) are both complete; Phase 136 is ready for `/gsd-verify-work 136` and, subsequently, Phase 137 (2.0 release) — the allowlist entry is in place, so the release will not hit the 1.10.2 allowlist landmine.

## Self-Check: PASSED

- `guides/upgrading-to-v2_0.md` — FOUND
- `test/mailglass/upgrade_v2_docs_test.exs` — FOUND
- `docs/api_stability.md` `## §Schema config (2.0)` — FOUND (grep count 1)
- `mailglass_inbound/docs/api_stability.md` `config :mailglass_inbound, :schema` — FOUND (grep count 1)
- Commits `b3542e30`, `54ed0ade`, `40db17cb`, `adc630ed` — all FOUND in git log
- Docs test 9/9 GREEN; `mix mailglass.docs.check` PASS; allowlist `sort -c` PASS
