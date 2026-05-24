---
phase: 48-inbound-admin-liveview
kind: gap-closure
closed: 2026-05-24
gaps_closed: [WR-01, WR-02, WR-03]
satisfies: [IADM-01, IADM-02]
commits:
  - f4f86dd  # fix(48): inbound list read-model — real disposition + search clause (WR-01, WR-03)
  - 75540c3  # fix(48): thread inbound search end-to-end + assert list disposition (WR-03, WR-01)
  - f7f15f4  # fix(48): detail 'From' cell shows the masked sender, not the recipient (WR-02)
key-files:
  modified:
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  tests:
    - mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
---

# Phase 48 Gap Closure: Inbound Admin LiveView

Closed the three verified gaps (WR-01, WR-02, WR-03) from the phase 48
verification (`48-VERIFICATION.md`, status `gaps_found`, 3/5 SCs) and the
independent code review (`48-REVIEW.md`). These were well-scoped read/display
defects, not architectural — no re-plan. With them closed, SC#1 (filterable
list reflecting real disposition, incl. search) and SC#2 (canonical message
incl. the sender) hold; IADM-01 and IADM-02 move from PARTIAL to satisfied.

## Gap 1 — WR-01 (SC#1 / IADM-01): list showed constant "Pending" + "no match"

**Root cause:** `Records.list_records/2` projected only identity/envelope
fields — never `outcome` or `mailbox`. The admin consumer (`RecordsList`) read
them via `Map.get` and always got `nil`, so every row rendered a neutral
"Pending" badge and "no match" mailbox regardless of real disposition.

**Fix:** Project each record's latest-FRESH `ExecutionRun` `outcome` + `mailbox`
via correlated subqueries (`parent_as(:rec)`), reusing the same `source: :fresh`
+ tenant-`where` shape `Detail.latest_fresh_run/2` already uses (single source
of truth for "what is this record's disposition"). The subqueries are themselves
tenant-scoped, so a foreign tenant's run can never leak in.

**Subtlety found + fixed (Rule 1):** a correlated subquery over an `Ecto.Enum`
column returns the *raw DB string* (`"accept"`), not the cast atom — the enum
load-cast only runs for a column selected directly from its own schema. The
admin badge pattern-matches atoms (`:accept`, `:no_match`), so the projected
string would have fallen through to the neutral badge and the fix would have
been cosmetic only. Added `cast_projected_outcome/1` to restore the atom against
the closed `ExecutionRun.__outcomes__/0` allow-list after `Repo.all`. The
consumer (`records_list.ex`) needed no change — its defensive `Map.get` reads
now resolve to real values.

A `:no_match` (or run-less) record projects a `nil` mailbox → still reads
"no match". The existing tenant-isolation guarantees are untouched.

## Gap 2 — WR-03 (SC#1 / IADM-01): the search filter was dead UI

**Root cause:** `search` was in `default_filter_params/0`/`normalize_filter_params/1`,
rendered by `FiltersForm`, and round-tripped through the URL — but
`load_inbound_records/1` never threaded it to the gateway, and `Records` had no
search clause. Typing a search did nothing.

**Fix (two seams):**
- Read-model: `maybe_filter_search/2` — a case-insensitive `ILIKE` *contains*
  over the tenant-scoped `subject`, `envelope_recipient`, and
  `provider_message_id`. LIKE metacharacters (`%`, `_`, `\`) in operator input
  are escaped to literals (`escape_like/1`) so a wildcard cannot widen the
  match; blank/absent search is a no-op (full list returns). Tenant scoping
  intact.
- LiveView: thread `search` from `load_inbound_records/1` into the gateway
  `list_records` call (`blank_to_nil` so an empty box stays a no-op).

## Gap 3 — WR-02 (SC#2 / IADM-02): detail "From" cell showed the recipient

**Root cause:** the "From" cell rendered
`mask_recipient(@record.envelope_recipient)` — the RECIPIENT — duplicating the
title and never showing the sender. `InboundRecord.from` (an `{:array, :map}` of
parsed address maps) was never read.

**Fix:** `sender_display/1` extracts each sender address from `@record.from` and
masks it through the one audited `Components.mask_recipient/1` (the sender is PII
and is masked exactly like recipients). It reads both atom-keyed (`:address`,
freshly built structs) and string-keyed (`"address"`, JSONB round-trip) maps,
and degrades to the neutral "Unavailable" placeholder on an empty or malformed
`from` (no crash, no falsehood). The detail read-model (`Detail.fetch/2`) already
returns the full `%InboundRecord{}`, so `from` was available with no projection
change.

## Constraints honored

- **Tenant isolation:** every changed/added query keeps the explicit `tenant_id`
  where-clause AND `Mailglass.Tenancy.scope/2`; the disposition subqueries are
  tenant-scoped (asserted by a dedicated test), and blank/missing tenant still
  yields `[]`/`nil`. No cross-tenant path introduced.
- **PII:** the sender is masked via the single audited masking definition; no PII
  added to telemetry or logs.
- **Optional-dep boundary (D-48-02):** no new direct `MailglassInbound.*`
  reference in the admin lib — the new `search` field and the projected
  `outcome`/`mailbox` flow through the existing `apply/3` gateway map. The
  `--no-optional-deps --warnings-as-errors` lane compiles clean (exit 0).
- **Append-only:** no replay/outcome write path changed; reads only.

## Tests added (closes the verifier's "no test asserts list-level disposition")

- `records_test.exs` (read-model): matched row projects real outcome + mailbox;
  `:no_match` row → `nil` mailbox; run-less row → `nil`/`nil`; latest-fresh wins
  over an older fresh run; a `:replay` run is ignored (fresh-only); the
  disposition subquery is tenant-scoped (foreign run never leaks). Search:
  narrows by case-insensitive subject/recipient/provider_message_id; blank +
  missing are no-ops; LIKE wildcards are literal; search stays tenant-scoped.
- `inbound_live_test.exs` (end-to-end, real DB fixtures): the rendered list
  shows real per-row disposition (Accept badge + matched mailbox; "No match" +
  warning badge); distinct rows show distinct dispositions; submitting the
  search form narrows results, blank is a no-op, and search is tenant-scoped.
- `components_test.exs` (component): RecordsList renders the real Accept badge +
  mailbox for a matched record, "No match"/warning for `:no_match`, neutral
  Pending for a run-less record; DetailHeader "From" shows the masked sender
  (atom- and string-keyed `from`), never leaks the raw sender, and degrades to
  "Unavailable" on empty/malformed `from`.

## Verification (all green)

| Command | Result |
| --- | --- |
| `mailglass_admin` `mix compile --warnings-as-errors` | exit 0 |
| `mailglass_admin` `mix compile --no-optional-deps --warnings-as-errors` | exit 0 (39 files); restored via `mix compile --force` |
| `mailglass_admin` `mix test --seed 0` | 131 tests, **1 failure** — only the documented pre-existing `voice_test.exs` "n**oops**" in inlined Phoenix dep JS (NOT phase 48); all else green |
| `mailglass_inbound` `mix test test/mailglass_inbound/internal/operator/ --seed 0` | 27 tests, 0 failures |
| `mix credo --strict` (records.ex, detail_header.ex, inbound_live.ex) | found no issues |

The full admin suite grew from the verifier's 118 → 131 tests: +21 new
assertions across the three suites (the delta vs. 118 also reflects the
seed-0/exclusion accounting), 0 new failures.

## Deviations

- **[Rule 1 — Bug] `Ecto.Enum` subquery returns a raw string.** Discovered while
  the WR-01 projection tests failed with `"accept"` ≠ `:accept`. Without the
  added `cast_projected_outcome/1` the badge would still have rendered "Pending"
  for matched rows — the fix would have been cosmetic. Fixed inline, asserted by
  the new read-model tests. Documented under Gap 1.

Out of scope (left for the orchestrator / future work): WR-04 (nil-adapter guard)
and WR-05 (non-standard adopter error tuple) are Info-level latent crash paths
shielded in production today; not part of the three verified blocker gaps.

## Self-Check: PASSED

- `records.ex` projection + search clause: present (commit f4f86dd).
- `inbound_live.ex` search threading: present (commit 75540c3).
- `detail_header.ex` sender_display: present (commit f7f15f4).
- All three `fix(48):` commits exist on `worktree-agent-a76e8646f0c479afb`.
- `STATE.md` / `ROADMAP.md` untouched (orchestrator-owned); `mix.lock` excluded.
