# 124-01 SUMMARY — Release cut + milestone closeout (v1.14)

status: complete
outcome: v1.14 SHIPPED to Hex as a recovered linked-version release.

## Hex versions confirmed live (`mix hex.info`, Released: 2026-06-30)

- **mailglass 1.10.1** — https://hexdocs.pm/mailglass/1.10.1
- **mailglass_admin 1.10.1** — https://hexdocs.pm/mailglass_admin/1.10.1
- **mailglass_inbound 1.5.3** — https://hexdocs.pm/mailglass_inbound/1.5.3

Inbound pin verification: `mix hex.info mailglass_inbound 1.5.3` → `mailglass == 1.10.1` (D-07 / PROJECT D-13). ✅

> NOTE: target versions shifted 1.10.0/1.10.0/1.5.2 → **1.10.1/1.10.1/1.5.3**. The 1.10.0 cut (tags at `f0c84ec0`) was merged + tagged but NEVER published — the publish gate blocked on a coordinated EEF dep-security advisory wave. Recovery shipped as a fresh patch; the 1.10.0 tags remain as harmless unpublished phantoms.

## Origin reconciliation

- Rebased the 126-commit v1.14 body onto the lone dependabot `#88` (`63c3f4c3`) commit, fast-forward pushed (NEVER `--force`), landed `fix(inbound): re-pin == 1.10.0` (later `== 1.10.1` for recovery). New HEADs all reached origin via fast-forward.
- Final release SHA: **`c3429288`** (`chore: release main (#99)`, admin-squash-merged). ci.yml green on it (Format, Support Contract Core/Admin, Hex Audit, Operator Browser Gate 160/0, Inbound Test; only advisory Demo Browser Evidence Docker-flake red).
- Self-approval of the RP PR is blocked → admin-squash-merge (the documented stall path); a human-pushed squash also satisfies gate-ci-green (no bot anti-recursion gap).

## fix(inbound): re-pin

- `fix(inbound): re-pin to mailglass == 1.10.1` (commit `caacffae`) reached origin/main BEFORE PR #99 merged → RP folded the paired inbound **1.5.3** (`== 1.10.1`) into the same linked PR. publish-admin `needs [publish-core, publish-inbound]` satisfied.

## Consumer smoke (REL-01)

- `VERSION=1.10.1 VERSION_INBOUND=1.5.3 DEP_MODE=hex INCLUDE_INBOUND=true scripts/consumer_install_smoke.sh` → **passed**: `mix deps.get` resolved mailglass 1.10.1 + mailglass_inbound 1.5.3 from Hex; app boots; **`GET /dev/mail/ → HTTP 200`**; "Endpoint smoke passed."

## post-publish-smoke

- Initial core run failed on "Wait for Hex.pm index" (fired on the release event before publish-core finished — a timing race, not #32 and not a regression). **Re-dispatched run `28421396832` GREEN**: Hex index, HexDocs build, Consumer install, Published-version trust journey, Verify-not-retracted all pass. No #32 hackney noise.

## Milestone audit (REL-02, D-12)

- True scope: **7 phases (118–124), 15 requirements** (NOT gsd-sdk raw counts; 999.x dirs excluded).
- All 15 REQ-IDs `status: passed`: METHOD-01/02, STORY-01/02, SHELL-01/02/03, DELIV-01, INB-01, PREV-01, COH-01/02, SEED-003, REL-01, REL-02.
- Archived: `milestones/v1.14-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`; updated MILESTONES/PROJECT/ROADMAP/RETROSPECTIVE/STATE; removed `REQUIREMENTS.md` (archived).

## Git tag v1.14 (REL-02)

- `git tag -l v1.14` → `v1.14`; `git ls-remote --tags origin v1.14` → `0a7c5fe2…/refs/tags/v1.14`. ✅ (Milestone marker, distinct from the RP Hex release tags.)

## Fix-forward steps taken (NOT in the original plan — surfaced by the first real CI run + the publish gate)

1. **plug CVE-2026-54892 → 1.19.3** (`fc17fdfd`).
2. **7 Operator Browser Gate regressions** (deferred phase verification never CI'd them): 2 real a11y bugs (preview backdrop `aria-pressed` `preview_live.ex`; inbound reveal ARIA disclosure `evidence_card.ex`), 3 stale specs realigned, 1 CI-only gallery overflow (re-redact button `px-sm`). Commits `c8b19960`, `8a10e584`, `8bfb7ac5`. Debug session: `debug/resolved/operator-browser-gate-v114.md`.
3. **EEF dep-security advisory wave** (cowlib/cowboy/postgrex/phoenix/mint/req/decimal): bumped all fixable deps across admin+inbound locks (`29a6155d`); accepted the 2 **unfixable** cowlib advisories (EEF-CVE-2026-43966/43969) via a narrow documented allowlist in `publish.check` `verify_audit` + regression test (`8e9fbaf9`).
4. Release recovery: RP cut a fresh patch 1.10.1/1.10.1/1.5.3 rather than force-moving the 1.10.0 tags.

Full narrative: `.planning/threads/v1.14-release-paused-dep-security-wave.md`.
