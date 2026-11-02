---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "02"
subsystem: ui
tags: [phoenix-liveview, heex, inbound, addresses, xss, admin]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 01 Deliveries filter commits (independent; no code dependency)"
provides:
  - MailglassAdmin.Inbound.AddressList pure normalization (entries/1, split/2)
  - Inbound full detail contact dl - From, Reply-To, To, Cc, Delivered to - unmasked, with truthful missing, multiple, Unicode and spoof presentation
  - Components.message_identity recipient label derived from context ("Delivered to" for :inbound)
  - InboundFixtures.insert_record!/2 from:, to:, cc:, reply_to: options
affects: [176-05, 176-07, 176-10]

plan_head_before: 5399f4713cfbc71179534850df5ebb9837ca789f
plan_head_after: c485bb311b51529f521bac1f89d6eb2677b4069d

actuals:
  tokens: 9500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Stored contact maps are read through one dual-key (atom and JSONB string) reader and normalized to display entries before any markup is built"
    - "Detail header reads every record field with Map.get/2 so plain-map records missing keys render missing copy"
    - "Shared component derives wording from its existing context attr instead of gaining a new public attr"

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/inbound/address_list.ex
    - mailglass_admin/test/mailglass_admin/inbound/address_list_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/support/inbound_fixtures.ex

key-decisions:
  - "Unparseable means anything that is not exactly one @ with a non-empty local part and domain; the original string is kept and shown escaped (nil for a map with no address key, so only the label renders)"
  - "Dedupe key is {local part exact, domain downcased}; unparseable entries collapse only on their exact original; first occurrence wins"
  - "Spoof detection extracts the first address-like token from the display name and compares it by the same key; a name that merely repeats the address is dropped, a name with a bare @ and no token is not flagged"
  - "Delivered to renders the hint paragraph even when the envelope recipient is missing, so the label is always explained"
  - "Record ID row is hidden (not given missing copy) when a plain-map record has no id, matching the Provider message ID row"

patterns-established:
  - "Inbound contact cells carry data-testid inbound-contact-{from|reply-to|to|cc|delivered-to}; the spoof cue carries inbound-address-spoof-cue"

requirements-completed: ["INUX-05"]

coverage:
  - id: D1
    description: "Inbound full detail renders From, Reply-To, To, Cc, Delivered to unmasked, with Delivered to bound to envelope_recipient and To bound to the header list"
    requirement: INUX-05
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound detail shows From, To and Delivered to"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#Phase 176 contact display Delivered to is bound to envelope_recipient and To to the header list, never swapped"
        status: pass
    human_judgment: false
  - id: D2
    description: "Address matrix - multiple, overflow past 5, duplicate collapse, missing, unparseable, spoof cue, Unicode and long values, escaped markup"
    requirement: INUX-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/address_list_test.exs"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#Phase 176 contact display"
        status: pass
    human_judgment: false
  - id: D3
    description: "message_identity labels the recipient Delivered to for :inbound (detail header and Quick view) and keeps To for :delivery"
    requirement: INUX-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/components_test.exs#Phase 176 message_identity recipient label"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound Quick view labels the envelope recipient 'Delivered to'"
        status: pass
    human_judgment: false
  - id: D4
    description: "Routing-trace matcher and subject masking unchanged; mask_recipient/1 and mask_value/1 stay public"
    requirement: INUX-05
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#recipient is readable in list and detail while routing evidence stays masked (unmodified)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-10-28
status: complete
---

# Phase 176 Plan 02: Inbound contact display Summary

**Inbound full detail now shows unmasked From, Reply-To, To, Cc and a separate "Delivered to" envelope recipient, with a pure AddressList normalizer handling duplicates, 5-item overflow, spoofed display names, Unicode and escaped markup.**

## Performance

- **Duration:** about 10 min
- **Started:** 2026-10-28T14:19Z (approximate; not recorded at start)
- **Completed:** 2026-10-28T14:29Z
- **Tasks:** 3
- **Files modified:** 8 (2 created, 6 modified)

## Accomplishments

- `MailglassAdmin.Inbound.AddressList` (`entries/1`, `split/2`) reads atom, JSONB string-key and bare-string entries; classifies unparseable entries; collapses duplicates (domain case-insensitive, local part exact); drops redundant names; flags display names that embed a different address.
- `Inbound.DetailHeader` replaces the masked single From cell with a contact `<dl>` (From, Reply-To if present, To, Cc if present, Delivered to + RCPT TO hint), a private `address_list/1` component (`<ul role="list">`, native `<details>` "Show N more" past 5, `copy_value` per address, field-specific missing copy), and `Map.get/2` reads for every record field (no `@record.<field>` left).
- `Components.message_identity/1` derives the label from `context`: `:inbound` -> "Delivered to" / "Not recorded by provider", otherwise "To" / "Recipient not recorded". Inbound Quick view projection is not widened.
- `InboundFixtures.insert_record!/2` accepts `from:`, `to:`, `cc:`, `reply_to:` (defaults `[]`, existing callers unchanged).

## Task Commits

1. **Task 1: Inbound full detail shows unmasked From, header To and Delivered to end-to-end (tracer)** - `f48ae4fd` (feat)
2. **Task 2: Address matrix - multiple, overflow, duplicates, missing, unparseable, spoof, Unicode, XSS** - `15bcac65` (feat; tests written first and seen RED for dedupe, name-drop, spoof, then green)
3. **Task 3: Context-aware recipient label in message_identity** - `c485bb31` (feat)

**Plan metadata:** committed separately (docs: complete plan).

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/inbound/address_list.ex` - pure address normalization
- `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` - contact dl and address list components; sender masking removed
- `mailglass_admin/lib/mailglass_admin/components.ex` - context-derived recipient label
- `mailglass_admin/test/mailglass_admin/inbound/address_list_test.exs` - 14 table tests
- `mailglass_admin/test/mailglass_admin/inbound/components_test.exs` - flipped From tests, plain-map case, "Phase 176 contact display" describe
- `mailglass_admin/test/mailglass_admin/components_test.exs` - "Phase 176 message_identity recipient label"
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - full-detail and Quick view Phase 176 tests
- `mailglass_admin/test/support/inbound_fixtures.ex` - contact-list options

## Decisions Made

See `key-decisions` above. The `priv/static/app.css` rebuild produced no diff (all utilities used were already in the bundle), so no bundle commit was needed; TokenParityTest and AssetsTest pass and `git diff --exit-code priv/static/` is clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] False-green mailbox test matched the From placeholder**
- **Found during:** Task 1
- **Issue:** "shows an unavailable mailbox for a failed execution without one" asserted `html =~ "Unavailable"`, which was only satisfied by the old From cell placeholder on a record with no `from`; the mailbox cell actually renders "Not recorded".
- **Fix:** Asserted the real mailbox copy ("Not recorded" and "Processing failed, but no mailbox name was saved for this attempt.") with a comment explaining the change.
- **Files modified:** `mailglass_admin/test/mailglass_admin/inbound/components_test.exs`
- **Verification:** inbound components test file 0 failures.
- **Committed in:** f48ae4fd

**2. [Process] `mix format` with no arguments reformatted 11 unrelated files**
- **Found during:** Task 2
- **Issue:** A bare `mix format` rewrote files outside this plan (this toolchain formats the tree differently from the committed baseline). They were unstaged and never committed.
- **Fix:** Restored each file with `git checkout -- <path>` (they were modified only by my format run); afterwards formatted only plan files by path.
- **Verification:** `git status` showed only plan files plus the pre-existing user WIP.

---

**Total deviations:** 1 auto-fixed (Rule 1) and 1 process slip, no scope change.
**Impact on plan:** None on shipped code.

### Trace-contract re-scopes

None needed. The existing trace-masked contracts (`inbound_live_test.exs` routing-trace card and `recipient is readable ... routing evidence stays masked`) and `inbound/components_test.exs` trace tests passed unmodified, so no refute was re-scoped.

## Issues Encountered

- The first Task 3 test run failed because HEEx formatting puts a newline between the label and value span; the test helper now collapses whitespace before comparing.

## Verification

- `mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --seed 0` -> 117 tests, 0 failures (after Task 1)
- `... inbound_live_test.exs --only phase176 --trace` -> 85 tests, 0 failures (1 included, Phase 176 test present in trace)
- `... address_list_test.exs components_test.exs --only phase176 --trace` -> 57 tests, 0 failures, "Phase 176 contact display" cases present
- `... components_test.exs inbound_live_test.exs token_parity_test.exs assets_test.exs --seed 0` -> 217 tests, 0 failures; `git diff --exit-code -- mailglass_admin/priv/static/` clean
- Full `mailglass_admin` suite `mix test --seed 0` -> 757 tests, 0 failures, 1 excluded (the large crash-report output is from intentional failing-repo tests)
- `bash mailglass_admin/scripts/check-conformance.sh` -> "OK: design-system conformance clean."
- Acceptance greps: fixtures `Keyword.get(opts, :{from,to,cc,reply_to}` each 1; non-comment `mask_recipient` in detail_header.ex 0; `def mask_recipient` in components.ex 2; "Delivered to" in detail_header.ex 2 and components.ex 1; `@record.` in detail_header.ex 0; `raw(` in detail_header.ex 0
- `mix format --check-formatted` on every file this plan touched passes; `mix credo --strict` on `inbound/*.ex` and `components.ex` reports no findings in files this plan touched (the remaining findings are in other files, pre-existing)

## Known Stubs

None.

## Threat Flags

None. The only new surface is escaped rendering of stored sender input (T-176-05 mitigated and tested), already in the plan's threat model.

## Next Phase Readiness

- 176-05 and 176-07 can call `InboundFixtures.insert_record!/2` with contact lists as-is.
- INUX-05 is declared by this plan only, so it can be marked complete.

## Self-Check: PASSED

- Created files exist (`address_list.ex`, `address_list_test.exs`).
- Commits `f48ae4fd`, `15bcac65`, `c485bb31` are ancestors of HEAD.

---
*Phase: 176-direct-filters-and-useful-inbound-evidence*
*Completed: 2026-10-28*
