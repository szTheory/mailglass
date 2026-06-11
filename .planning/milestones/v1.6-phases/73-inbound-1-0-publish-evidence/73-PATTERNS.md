# Phase 73: Inbound 1.0 Publish Evidence - Pattern Map

**Mapped:** 2026-06-02
**Files analyzed:** 4 (1 new record, 1 optional new checklist, 1 modified runbook, 1 optional test extension)
**Analogs found:** 4 / 4

This is a documentation + release-evidence phase under a PREPARE-AND-STAGE posture (D-01). No source/runtime code is created. The "files" are planning artifacts, one maintainer runbook, and at most one light test extension. Every pattern below is repo-native; no pattern asserts live external Hex/HexDocs state (D-08, anti-pattern in RESEARCH lines 283-287).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `73-xx-RELEASE-RECORD.md` (NEW) | release-evidence record (planning doc) | transform (capture → record) | `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md` | exact (clone shape, drop approver fields) |
| `73-xx-RELEASE-CHECKLIST.md` (OPTIONAL NEW) | release-gate checklist (planning doc) | transform (gate enumeration) | `.../38-03-RELEASE-CHECKLIST.md` | exact (clone shape, drop GitHub-Environment gate) |
| `MAINTAINING.md` (MODIFIED) | maintainer runbook (docs) | request-response (operator reads → acts) | itself (in-place edit of lines 250-298) | self / in-place |
| docs/release-contract test (OPTIONAL extension) | test (field-presence guard) | request-response (read file → assert) | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` line 404-417 + `test/mailglass/stability_contract_test.exs` line 116-179 | exact (string-presence idiom) |

## Pattern Assignments

### `73-xx-RELEASE-RECORD.md` (release-evidence record, transform)

**Analog:** `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md` (read in full, 30 lines)

**Top-block field set to clone** (analog lines 3-12) — flat `Key: value` lines, NOT a table:
```
Release type: <prepare-and-stage>
Tag: mailglass_inbound-v1.0.0 (staged, not cut)
Publish workflow run URL: <dry-run run URL | not run>
Post-publish smoke run URL: not run
Proof bundle path: <e.g. mailglass.publish.check summary path>
Install/upgrade rehearsal path: <pending | path>
Hex index confirmation: not run
HexDocs URLs: pending
Fallback path used: not run
60-minute outcome: not run; no live publish window started
```

**Pending-marker convention to mirror** (analog lines 9, 11-12, 29) — the literal strings `not run` / `pending`, with an honest clause appended where useful:
```
Hex index confirmation: not run; rehearsal stayed repo-local
60-minute outcome: not run; no live publish window started
```
Note from analog line 29 (clone the spirit): "Live publish, Hex index, HexDocs verification, and the 60-minute revert window remain explicit `not run` items until a real cut happens." For Phase 73 this becomes the inbound-scoped equivalent.

**Trailing sections to clone** (analog lines 20-29): `## Proof links` (bullet list of companion artifact paths) and `## Notes` (one honest paragraph stating the prepare posture).

**DROP from the analog (D-04 / RESEARCH lines 204-209):** the entire `## Manual approvals and external checks` block (analog lines 14-18) — specifically `GitHub Environment approver` and `Approval timestamp`. Publish is hands-free; the `hex-publish` environment has no required reviewers (CLAUDE.md "Commit & Branch Conventions"). `Branch-protection verification result` is optional for an inbound-only slice; if dropped, note why.

**Scope difference from analog:** the Phase 38 record covers the linked core+admin pair at one tag; the inbound record covers the single package `mailglass_inbound` at `mailglass_inbound-v1.0.0`. Do NOT edit the Phase 38 forms in place (D-03 / RESEARCH line 213) — they are the linked core/admin v1.0 record.

---

### `73-xx-RELEASE-CHECKLIST.md` (release-gate checklist, transform — OPTIONAL)

**Analog:** `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md` (read in full, 51 lines)

**Two-bucket structure to clone** (analog lines 3, 23) — the load-bearing separation:
```
## Repo-proved before publish      ← deterministic, runs this phase
## Manual/external proof           ← post-publish, marked pending
```

**Repo-proved bucket pattern** (analog lines 5-21) — numbered gates, each with indented `Proof fields:`. For inbound, swap the required buckets to the inbound-native lanes (from RESEARCH Standard Stack lines 117-123):
- `mix mailglass.publish.check --package mailglass_inbound` (exit 0; writes the committed summary)
- `mix verify.stability_contract` (root semantic proof)
- `mailglass_inbound-publish-summary.json` reviewed

**Manual/external bucket pattern** (analog lines 24-48) — keep `Fallback dispatch`, `Live package and docs verification` (Hex/HexDocs URLs), and the `60-minute smoke and release decision window`, all marked `pending` / `not run`.

**DROP from the analog (D-04 / RESEARCH lines 204-205):** the `GitHub Environment approval for hex-publish` gate (analog lines 25-29) including `GitHub Environment approver` / `Approval timestamp` proof fields.

**Closing pointer pattern** (analog line 50): "Use `73-xx-RELEASE-RECORD.md` to store the filled values above."

---

### `MAINTAINING.md` (maintainer runbook, request-response — MODIFIED in place)

**Analog:** the file itself; this is a targeted in-place edit, not a new file from a template.

**Fix 1 — D-10 stale path** (current lines 255-257):
```
Use the Phase 38 release-day proof forms while running these steps:
- `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md`
- `.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md`
```
The cited `.planning/phases/38-...` directory does NOT exist; it was archived to `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/` (RESEARCH lines 273-275, verified). Repoint both bullets to the archived path. Per RESEARCH line 277, the new inbound record may ALSO be cited here as the inbound-specific companion to the (still-archived) core/admin Phase 38 forms.

**Fix 2 — inbound-only publish/fallback wording refinement** (existing fallback line 298, already present):
```
For an inbound-only `1.0.0` recovery, dispatch `package=mailglass_inbound` from `mailglass_inbound-v1.0.0`.
```
This already documents the inbound-only recovery dispatch (RESEARCH lines 185-187) — REL-02 is a *refinement* of this wording, not an invention. Preserve the existing "Do not dispatch from `main`" constraint (line 298) and the package-order/idempotency notes (lines 296-297) verbatim; do NOT loosen the gating language (RESEARCH security note, line 450).

**Constraint:** the existing inbound docs-contract test asserts only `maintaining =~ "mailglass_inbound"` and `maintaining =~ "mix verify.stability_contract"` (test line 415-416). That assertion does NOT catch the broken path (RESEARCH lines 279-281), so the D-10 fix needs manual `grep -n "phases/38" MAINTAINING.md` verification (must return nothing) OR a new negative-assertion extension (see below).

---

### docs/release-contract test extension (test, request-response — OPTIONAL per D-08)

**Analog A (string-presence idiom):** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` line 404-417 ("repo-root verification keeps inbound docs and release proof in the canonical lane").

**File-read + assert idiom to mirror** (analog lines 405-416):
```elixir
test "..." do
  maintaining = File.read!(Path.expand("../../../MAINTAINING.md", __DIR__))

  assert maintaining =~ "mailglass_inbound"
  assert maintaining =~ "mix verify.stability_contract"
end
```
Path convention: tests in `mailglass_inbound/test/mailglass_inbound/` reach repo-root files via `Path.expand("../../../<file>", __DIR__)` (analog lines 405-407). The release record lives at `.planning/phases/73-inbound-1-0-publish-evidence/73-xx-RELEASE-RECORD.md` — reach it the same way.

**Field-presence extension shape** (string-presence ONLY, no live HTTP — D-08 / RESEARCH lines 286-287, 332-339):
```elixir
test "inbound release record exists and carries the REL-03 field headers" do
  record = File.read!(Path.expand(
    "../../../.planning/phases/73-inbound-1-0-publish-evidence/73-xx-RELEASE-RECORD.md", __DIR__))

  for header <- ["Tag", "Publish workflow run URL", "Fallback",
                 "Hex index", "HexDocs", "smoke", "60-minute"] do
    assert record =~ header
  end
end
```

**Pending-marker assertion** (mirror the Honest Surface Area rule, D-05): assert the post-publish fields read as pending, e.g. `assert record =~ "not run"` / `assert record =~ "pending"` for the Hex/HexDocs/smoke/60-minute lines.

**Optional D-10 regression guard** (RESEARCH lines 425-426) — negative assertion in the `refute` idiom already used throughout the analog (e.g. test lines 144-145, 524-526):
```elixir
refute maintaining =~ ".planning/phases/38-"
```

**Analog B (derive-don't-hardcode, if extending the root test instead):** `test/mailglass/stability_contract_test.exs` line 116-179 ("inbound release preflight truth is internally consistent"). Mirror its helpers: `json!/1` (line 26) for reading committed JSON, `read_at_version!/1` (line 184-189) for deriving versions from `mix.exs`, and the WR-03/WR-04 principle (lines 117-127) of asserting internal consistency rather than hardcoding `1.0.0`/`1.3.0` literals. If the field-presence test needs to reference the inbound version, derive it from `manifest["mailglass_inbound"]` (line 140), never a literal.

**CRITICAL (D-08 / Pitfall 4, RESEARCH lines 283-287):** the extension asserts ONLY that the record file EXISTS and contains the required field headers (string presence). It must NEVER assert external HTTP / Hex / HexDocs state (e.g. that `https://hex.pm/packages/mailglass_inbound/1.0.0` resolves) — that fails deterministically under the prepare posture and would block milestone closeout.

## Shared Patterns

### Honest Surface Area (pending reads as pending)
**Source:** `.../38-03-RELEASE-RECORD.md` lines 9-12, 29 (the `not run; <why>` convention)
**Apply to:** the release record, the checklist's manual/external bucket, and any test pending-marker assertion.
Post-publish-only fields (Hex index URL, HexDocs URL, install/smoke proof, 60-minute outcome) must carry explicit `pending` / `not run` markers and never read as captured (D-05). The analog's trailing Note (line 29) is the template for the honest closing paragraph.

### Repo-native deterministic lanes over new mechanics
**Source:** RESEARCH "Don't Hand-Roll" (lines 225-234) + Standard Stack (lines 117-123)
**Apply to:** the checklist's repo-proved bucket and any test extension.
Lean on `mix mailglass.publish.check --package mailglass_inbound`, `mix verify.stability_contract`, and `publish-hex.yml` `dry_run=true` — never invent new release validation scripts. The `stability_contract_test.exs` inbound-consistency test (line 116-179) already owns source/publish internal-consistency proof; do not duplicate it.

### Package-local vs. aggregate test ownership
**Source:** CONTEXT "Established Patterns" (lines 199-200)
**Apply to:** the D-08 test extension placement decision.
Package-local truth (the inbound record's field presence, inbound docs) belongs in `mailglass_inbound/test/.../docs_contract_test.exs`; aggregate wiring / release-automation topology belongs in `test/mailglass/stability_contract_test.exs`. The inbound RELEASE-RECORD is package-local evidence → prefer the inbound docs-contract test as the extension home.

### Drop the obsolete hands-free-publish approver fields
**Source:** RESEARCH State of the Art (line 346) + Security note (line 452); CLAUDE.md "Commit & Branch Conventions"
**Apply to:** both the record and the checklist.
Publish is hands-free with no required reviewers. Drop `GitHub Environment approver`, `Approval timestamp`, and the `GitHub Environment approval for hex-publish` gate. Do NOT reintroduce any approval claim that does not exist.

## No Analog Found

None. Every file in this phase has a strong existing analog (the Phase 38 forms for the record/checklist, MAINTAINING.md itself for the runbook edit, and the two contract test files for the optional extension).

## Anti-Patterns (do NOT copy these from anywhere)

- A test asserting live Hex/HexDocs HTTP state (D-08 / Pitfall 4) — fails deterministically under prepare posture.
- Editing the archived Phase 38 forms in place (D-03) — they are the linked core/admin v1.0 record.
- Recording any pending field as captured (D-05, Honest Surface Area).
- Cutting `mailglass_inbound-v1.0.0` as a real tag (D-01/D-02 / Pitfall 2) — it arms the hands-free publish fan-out.
- Flipping reference-app pins to `~> 1.0` (D-09) — `reference/host_app/mix.exs` (`~> 0.3`) and `reference/demo_app/mix.exs` (`~> 0.3.0`) stay below `~> 1.0`.
- Hardcoding `1.0.0` / `1.3.0` literals in any test extension — derive from the manifest / core `@version` (stability_contract_test pattern, lines 117-127).

## Metadata

**Analog search scope:** `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/`, `MAINTAINING.md` (220-339), `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`, `test/mailglass/stability_contract_test.exs`.
**Files scanned:** 5 (2 Phase 38 forms, MAINTAINING.md runbook section, 2 contract test files).
**Pattern extraction date:** 2026-06-02
