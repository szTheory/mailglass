# Phase 125: Sibling-pin loosening (keystone, atomic) - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning
**Source:** Synthesized from research-complete decisions of record (`.planning/research/milestone-cicd/SYNTHESIS.md`, LD-1..13). Milestone v1.15 is research-complete — discuss-phase and RESEARCH.md are intentionally skipped; SYNTHESIS.md is the canonical decision record.

<domain>
## Phase Boundary

Replace both sibling `{:mailglass, "== X.Y.Z"}` exact pins with pessimistic `~>` constraints, and relax
every gate that enforced exact equality — as ONE indivisible change. After this phase, a core **patch**
release no longer drags a paired sibling release (the exact-pin dance the 1.10.2 ceremony hit — see the
dated trap comment at `mailglass_inbound/mix.exs:114–136`). This is the milestone keystone: it unblocks
every future release.

**In scope:** the two sibling pins, the contract test that enforces `==`, the `publish.check`
constraint verification, the two `==` sed rewrites in `release-please.yml`, a CHANGELOG entry, and a
documented `mix hex.retire` rollback lever.

**Out of scope:** any product/provider/transport/route/schema change (D-23 convergence; schema
isolation is v2.0). No CI-gate reshaping (that is Phase 126). No `mix ci` work (Phase 128).

**Atomicity is load-bearing.** Splitting any part off reds main or miscuts the next release — e.g. the
sed anchor would then match zero `==` lines. All of §6(a)–(d) in the release-hardening dossier must be
verified BEFORE merge.
</domain>

<decisions>
## Implementation Decisions

### Sibling pin constraints (LD-2 — locked)
- **Inbound** (`mailglass_inbound/mix.exs:139`): `{:mailglass, "== 1.10.2"}` → `{:mailglass, "~> 1.10 and >= 1.10.2"}`.
  - Bare `~> 1.10` admits `1.10.0`/`1.10.1` — the *broken-deliveries-migration* core versions. Floor at the V05 fix (`>= 1.10.2`). Mirrors Ash's own `~> 3.5 and >= 3.5.13` precedent.
  - `~> 1.10` correctly REFUSES core `1.11.0` — desired: a new core **minor** is where internal contracts (`Mailglass.Outbound.*`, events table, Error hierarchy) may shift. Each minor floor-bump is a deliberate `fix(inbound):` asserting "verified against core 1.11." Do NOT speculatively widen inbound to `~> 1.10 or ~> 1.11`.
- **Admin** (`mailglass_admin/mix.exs:156`): `{:mailglass, "== 1.10.2"}` → `{:mailglass, "~> 1.10"}`.
  - Bare `~> 1.10` is safe because admin is in the linked-versions group `[mailglass, mailglass_admin]` (`release-please-config.json`) — the plugin release-time-locks admin's minor to core, so admin never resolves against a core it didn't ship with.
- **Reason about the two separately** — inbound is NOT in the linked group; its `~>` safety rests on a human choosing the floor, admin's rests on the plugin.
- Both remain behind the existing `MIX_PUBLISH` gate.

### Gate relaxation (LD-3 — locked, part of the atomic change)
- **`stability_contract_test`**: the `==`-exact assertion (`test/mailglass/stability_contract_test.exs:105` regex `~r/\{:mailglass, "== \d+\.\d+\.\d+"\}/`, and the assertion body around :154–159) must be replaced so it asserts the sibling pin *admits* core `@version` via `Version.match?` AND is pessimistic (`~>`), *rejecting* `==`. The relaxed test must pass on a bare main SHA where core `@version` is unchanged — the exact scenario that was RED before.
- **`publish.check`** (`lib/mix/tasks/mailglass.publish.check.ex`): `verify_deps` and `verify_linked_constraint` (the `== root_version` matches the dossier cites near :778/:827; `@accepted_advisories` near :60–63) must accept any `~>` that `Version.match?`-es core and reject `==`. `publish.check` must pass for all three packages.
- **`release-please.yml`**: DELETE the two `== X.Y.Z` sed rewrites (the `{:${dep}, "== ..."}` → `{:${dep}, "== ${CORE_VERSION}"}` rewrite at ~:184 that targets the sibling pins). Do NOT touch the `~>` README/installer sed rewrites (~:197, :214, :215, :230, :231) — those track minor versions and stay. After deletion, a simulated core patch release must touch zero sibling pin lines.

### Documentation (LD-5 — locked)
- Ship a CHANGELOG entry: "mailglass_inbound now depends on `mailglass ~> 1.10 and >= 1.10.2` instead of an exact pin; you may upgrade core patch releases without waiting for a paired inbound release."
- Document `mix hex.retire mailglass X.Y.Z` as the rollback lever that replaces the `==` wall. Rationale to capture: `==`→`~>` is a published constraint change to every downstream adopter — it changes the resolver's degrees of freedom (an adopter who also directly depends on core no longer gets forced-consistent resolution; a bad core patch that previously could never silently reach an inbound adopter now auto-resolves in). `mix hex.retire` is the new lever for that failure mode.

### Claude's Discretion
- Exact wording/placement of the CHANGELOG entry and the `mix hex.retire` rollback doc (README vs CHANGELOG vs a release-ops doc — follow existing repo conventions).
- Precise refactor shape of the relaxed contract-test/`publish.check` helpers (a shared `Version.match?`-based predicate is fine), provided semantics match LD-2/LD-3.
- Which of the three `stability_contract_test.exs` files carry the sibling-pin assertions (core checks inbound_mix at :105; verify admin/inbound copies during planning) and how to keep them consistent.
- How to *simulate* a core patch release for the "touches zero sibling pin lines" proof (dry-run/sed-noop assertion vs a scripted check).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Decisions of record (authoritative — this file wins over raw dossiers)
- `.planning/research/milestone-cicd/SYNTHESIS.md` — LD-1..13; §0 ground-truth corrections; §1 LD-2/LD-3/LD-5 are Phase 125's binding decisions; §6 (in the dossier) is the pre-merge verification checklist referenced by LD-3.
- `.planning/research/milestone-cicd/CICD-RELEASE-HARDENING.md` — raw release-eng dossier (version/line-stale; SYNTHESIS overrides on conflict).

### Files this phase changes
- `mailglass_inbound/mix.exs:139` — inbound sibling pin (+ the dated trap comment at :114–136 to update/retire).
- `mailglass_admin/mix.exs:156` — admin sibling pin.
- `test/mailglass/stability_contract_test.exs:105,154–159` — core contract test enforcing `==` (relax to admit-`~>`-reject-`==`).
- `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` and `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` — sibling contract tests (verify + relax as needed).
- `lib/mix/tasks/mailglass.publish.check.ex` — `verify_deps` / `verify_linked_constraint` / `@accepted_advisories`.
- `.github/workflows/release-please.yml:~184` — the two `== X.Y.Z` sibling sed rewrites to DELETE (leave `~>` rewrites intact).
- `CHANGELOG` (per-package convention) — the constraint-change entry.

### Project conventions
- `./CLAUDE.md` — sibling linked-version release mechanics; inbound exact-pin history; D-13; "Things Not To Do."
- `.planning/REQUIREMENTS.md` — PIN-01..05 acceptance wording.
</canonical_refs>

<specifics>
## Specific Ideas

- The dated trap comment at `mailglass_inbound/mix.exs:114–136` narrates the exact transient-red window the `==` pin caused during the 1.10.2 ceremony — planning should update/remove it as part of this change so the file's narrative matches the new `~>` reality.
- The "scenario that was red before" (PIN-05 / success criterion 2): the inbound `== X` re-pin had to land direct-to-main as a transient-red SHA because `stability_contract_test` required pin == core@version while core only bumps inside the release PR. The relaxed test must be GREEN on a bare main SHA with unchanged core `@version` — that is the concrete before/after proof.
- Memory `project_1_10_2_patch_release.md` (release-recovery gotchas) and `project_milestone_1_2_designed.md` (this milestone's design) are relevant background.
</specifics>

<deferred>
## Deferred Ideas

- CI Green fan-in gate / branch-protection collapse — Phase 126.
- Inbound test determinism / `--seed 0` deletion — Phase 127.
- `mix ci` parity — Phase 128.
- Everything else in v1.15 phases 129–131.
- Speculative widening of inbound to `~> 1.10 or ~> 1.11` — explicitly rejected (LD-2).
</deferred>

---

*Phase: 125-sibling-pin-loosening-keystone-atomic*
*Context synthesized 2026-07-01 from SYNTHESIS.md decisions of record (research-complete milestone)*
