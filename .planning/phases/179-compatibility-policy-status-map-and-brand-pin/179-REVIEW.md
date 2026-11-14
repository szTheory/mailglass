---
phase: 179-compatibility-policy-status-map-and-brand-pin
reviewed: 2026-11-14T00:40:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/status_map.ex
  - mailglass_admin/lib/mailglass_admin/copy.ex
  - mailglass_admin/lib/mailglass_admin/components.ex
  - scripts/brand_pin.exs
  - scripts/brand_trademark_gate.exs
  - mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs
  - mailglass_admin/test/mailglass_admin/copy_contract_test.exs
  - mailglass_admin/test/mailglass_admin/status_map_test.exs
  - test/mailglass/outbound/suppressed_not_persisted_test.exs
  - test/scripts/brand_pin_test.exs
  - test/scripts/brand_trademark_gate_test.exs
  - brandbook/brand.pin.json
  - docs/brand-v2-compatibility.md
  - docs/api_stability.md
findings:
  critical: 1
  warning: 9
  info: 5
  total: 15
  necessity: 0
status: issues_found
---

# Phase 179: Code Review Report

**Reviewed:** 2026-11-14T00:40:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the status map, the Copy table, the brand pin script and its committed pin, the
trademark gate and its record, the compatibility policy with its verifying test, and the
supporting tests. The `components.ex` change is a clean pass-through to `Copy` (the fallback
behavior is identical to the removed clause families).

Verification performed: the three admin tests (82 tests), the core script tests plus the
suppression persistence test (87 tests), `docs_contract_test`, `stability_contract_test` and
`compatibility_contract_test` all pass. `mix format --check-formatted` and `mix credo --strict`
(including the custom checks) are clean on the changed files. The passing tests are not evidence
of correctness here: most findings below are properties the tests do not exercise, and several
were reproduced by hand.

The one blocker is that both new scripts silently succeed with no output when run under
`MIX_ENV=test`, which turns the "fail-closed" trademark gate into a fail-open exit 0 in exactly
the environment the CI jobs already export. The warnings are gaps in the gate's invariants, a
policy that contradicts the stability inventory it was linked from, a compat-table proof that
can go green on documentation text, and a few contract-test claims that the same file
contradicts.

Necessity (#4100): `necessity-review.md` was read. Nothing met the evidence rule for an
impossible-state or phantom-requirement finding. `StatusMap.delivery_class/1`,
`classify_or_unknown/1` and `Copy.vocabulary/0` have no production caller yet, but the repo
documents the planned wiring, so that is not provable as unnecessary.

## Critical Issues

### CR-01: Both scripts exit 0 with no output under `MIX_ENV=test` (fail-open gate, vacuous pin verify)

**File:** `scripts/brand_trademark_gate.exs:438-442`, `scripts/brand_pin.exs:838-842`
**Issue:** The run-guard is `if Mix.env() != :test do ... end`. When a script is invoked as its
own docs instruct (`mix run --no-start scripts/brand_trademark_gate.exs check`) with
`MIX_ENV=test`, the guard is false, nothing runs, nothing prints, and the process exits 0.
Reproduced:

```
$ MIX_ENV=test mix run --no-start scripts/brand_trademark_gate.exs check ; echo $?
0                                  # no output
$ mix run --no-start scripts/brand_trademark_gate.exs check ; echo $?
deny (not_clear): overall=caution ... ; 1
```

The gate's contract is "Exit 0 means an announcement is allowed" and "defaults to no", so a
silent 0 is the opposite of fail-closed. `brand_pin.exs verify` (documented as the merge-blocking
check) is vacuous the same way. This is reachable, not theoretical: `.github/workflows/ci.yml`
exports `MIX_ENV: test` at job level (lines 250, 336, 412) and the announcement phase is
expected to call the gate from CI. The guard is inherited from
`scripts/reconcile_release_versions.exs:777`, which has the same latent defect.
**Fix:** Make "run" the default and make library mode an explicit opt-in set by the tests, instead
of keying on the environment name:

```elixir
# bottom of both scripts
unless Application.get_env(:mailglass, :script_library_mode, false) do
  {status, output} = Mailglass.BrandTrademarkGate.cli(System.argv())
  IO.puts(output)
  if status != 0, do: System.halt(status)
end
```

```elixir
# test setup_all, before Code.require_file/1
Application.put_env(:mailglass, :script_library_mode, true)
Code.require_file(@script)
```

Add a test that shells out with `MIX_ENV=test` and asserts a non-empty, non-zero result for the
committed (denying) record.

## Warnings

### WR-01: Gate allows `overall: "clear"` while a required register is `caution`

**File:** `scripts/brand_trademark_gate.exs:286-290`
**Issue:** `clear_issue` rejects `clear` only for `not_checked` or `blocked` sources. A register
(USPTO, TMview, WIPO) recording `caution` (a possible live conflict) with `overall: "clear"` and
`register_checked: true` validates and returns `{:allow, :clear}`. Reproduced with the committed
record, `uspto` set to `caution`, the other `not_checked` sources set to `clear`: decision is
`{:allow, :clear}`. `TRADEMARK-SEARCH.md` line 73 defines `clear` as "all three registers
checked, no live conflicts". `test/scripts/brand_trademark_gate_test.exs` `clear_record/0` only
sets the registers to `clear`, so the test never exercises this.
**Fix:** Require the three registers to read `clear` for `overall: "clear"`:

```elixir
register_unresolved_issue =
  if record["overall"] == "clear" and Enum.any?(required_outcomes, &(&1 != "clear")),
    do: [:clear_with_unresolved_register],
    else: []
```

Add a test planting `uspto: "caution"` under `overall: "clear"` and asserting `:invalid_record`.

### WR-02: Gate trusts record-supplied dates (future `date`, unbounded `expires`) and the CLI can override "today"

**File:** `scripts/brand_trademark_gate.exs:156-172, 335-344, 367-401`
**Issue:** `judge/2` only compares `today` with `expires`. It never checks `date <= today`, and
`validate/1` only requires `expires > date`, with no maximum window. Reproduced: a record dated
`2030-01-01` with `expires: 2099-12-31` evaluated on `2026-11-20` returns `{:allow, :clear}`. The
documented 180-day refresh is therefore enforced by nobody, and one hand-edit of `expires` keeps a
stale search valid forever. Separately, `check --today YYYY-MM-DD --path FILE` on the production
command lets any caller evaluate an expired record as of an earlier day or against another file
and still get exit 0.
**Fix:** Deny when `today` is before `date`, and cap the window in validation:

```elixir
@max_validity_days 180
# in expiry_order_issue/2 when both parse:
cond do
  Date.compare(expires, date) != :gt -> [:expires_not_after_date]
  Date.diff(expires, date) > @max_validity_days -> [:expiry_window_too_long]
  true -> []
end
# in judge/2, before the expiry clause:
Date.compare(today, date) == :lt -> {:deny, :not_yet_valid}
```

Gate `--today` and `--path` behind the test-only path (or document them as non-authoritative and
keep the CI/announcement call on `announcement_allowed?/1`).

### WR-03: The compatibility policy lists names that `api_stability.md` calls internal or sibling-only, and the reverse check forces more in

**File:** `docs/brand-v2-compatibility.md:26-51`, `docs/api_stability.md:130-136, 262`, `mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs:358-369, 534-545`
**Issue:** The policy declares its rows "public names that must not move" and says removal needs
the deprecation process and a major version. Its rows include `Mailglass.Operator.SupportSummary`,
`Mailglass.Operator.Tenants`, `Mailglass.Operator.SupportSummary.read_orphan_backlog/1` and the
`"tenant_id"` literal in `mailglass_admin/lib/mailglass_admin/operator/mount.ex`.
`docs/api_stability.md` (the file this phase edited to point at the policy) states that
`SupportSummary.read_orphan_backlog/1` is "sibling-package-only ... not general adopter promises"
(lines 130-136) and that `MailglassAdmin.Operator.Mount` "remains internal" (line 262). The stable
operator read models it lists are only `Deliveries`, `ReplayHistory`, `ReplayTargets`, `Timeline`
and `Suppressions`. Worse, "every `Mailglass.Operator.*` module has a module row" means any future
internal Operator module is forced into a major-version commitment. An adopter reading both
documents gets two contradictory answers about what is protected.
**Fix:** Split the table into a "stable" tier (matches `api_stability.md`) and a "first-party
coupling" tier whose removal needs a coordinated sibling release but not a major version, or drop
the sibling-only and internal names. Restrict the reverse check to the documented stable modules.
Reconcile the wording in `api_stability.md` in the same change.

### WR-04: `grep`-kind compat rows pass on documentation text, so removing the code leaves them green

**File:** `mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs:251-258, 319-322`; `docs/brand-v2-compatibility.md:43-51`
**Issue:** A `grep` row is satisfied by `String.contains?` anywhere in the proof file, comments and
`@doc` text included, and atom names also match any `<name>:` substring. In
`mailglass_admin/lib/mailglass_admin/router.ex`, `deliveries_path` appears in the moduledoc
(line 49), `live_session_name` at lines 45 and 61, and `account_labels` at line 66. Deleting the
NimbleOptions keys (lines 121, 144/202, 228) while leaving the docs would keep three of the five
router rows green. This contradicts the stated purpose ("proves each one still exists in the code")
and the file's own `teeth` section, which only plants a wrong *file*, never a doc-only mention.
**Fix:** Strip comments and doc heredocs before matching, and prefer a structural pattern for
option names. The stripping helper already exists in `copy_contract_test.exs`:

```elixir
defp code_only(source) do
  ~r/@(?:module)?doc\s+(?:~[sS])?"""\n.*?"""/s
  |> Regex.replace(source, "")
  |> String.split("\n")
  |> Enum.reject(&Regex.match?(~r/^\s*#/, &1))
  |> Enum.join("\n")
end
```

Add a planted-row test where the name occurs only in a `@doc` heredoc and assert it fails.

### WR-05: `copy_contract_test` promises Part B binds "without a test edit" but asserts the opposite

**File:** `mailglass_admin/test/mailglass_admin/copy_contract_test.exs:55-60, 702`; `mailglass_admin/lib/mailglass_admin/copy.ex:14-16`
**Issue:** The moduledoc says every class label is `wired: false` today and Part B "starts binding
without a test edit when a class label is switched on". The test `entries that are not wired yet
are present as data` contains `assert Enum.all?(Copy.class_labels(), &(&1.wired == false))`. The
first time anyone flips one class label to `wired: true` (the documented switch-on action), that
assertion fails and a test edit is required. The documented workflow is broken by the contract
that documents it.
**Fix:** Drop the `all? wired == false` assertion (keep the `is_boolean(entry.wired)` check) or
correct the moduledoc and `Copy` comment to say a test edit is part of switching a label on.

### WR-06: Part B is keyed on the atom alone and would enforce the relabeling the policy forbids

**File:** `mailglass_admin/test/mailglass_admin/copy_contract_test.exs:456-463, 620-622`; `docs/brand-v2-compatibility.md:112-117`; `mailglass_admin/lib/mailglass_admin/status_map.ex:25-27`
**Issue:** The policy ("Same atom, two meanings") and the `StatusMap` comment say inbound outcome
badges for `:rejected`, `:bounced` and `:failed` must not adopt the delivery words, and that "a
rename keyed on the atom alone would relabel them by accident". `wired_class_violations/1`
iterates every atom with `StatusMap.classify(atom) == class` and requires
`badge_text(atom) == label`, where `badge_text/1` renders `status_badge/1` with no context. Once
the `:failed` class label is wired, the test demands that the `:rejected` and `:bounced` badges
read the outbound word everywhere, including the inbound surface that shares those atoms and
`Copy.statuses/0` (one label per atom, no context key). The executable contract encodes the
accident the prose warns about.
**Fix:** Before any class label is switched on, give `Copy` a context dimension (key by
`{context, atom}`, or a separate inbound table) and scope Part B to the delivery context. Add a
planted test showing an inbound `:rejected` badge is left alone when `:failed` is wired.

### WR-07: `delivery_class/1` classifies a suppressed row as Failed when it also carries the terminal latch

**File:** `mailglass_admin/lib/mailglass_admin/status_map.ex:129-155`
**Issue:** `durable_failure?/2` excludes suppression only via `present?(row, :suppressed_at)`,
while the very next `cond` clause also treats `status == :suppressed` and
`last == :suppressed` as suppression. Reproduced:

```
%{status: :suppressed, last_event_type: nil, terminal: true}                 -> :failed
%{status: :sent, last_event_type: :suppressed, terminal: true}               -> :failed
```

The comment documents precedence "a failure report or a durable failure field, then a
suppression" and says a terminal latch needs "no delivery, complaint or suppression behind it".
The policy promises dormant `:suppressed` rows "still read Not sent if they ever appear". The
projector always sets `suppressed_at`, so persisted rows are safe, but the fixtures the policy
refers to (and any row built without that column) are misclassified, and the `grid/0` tests never
set `terminal`, so nothing catches it.
**Fix:** Compute suppression once and use it in both places:

```elixir
suppressed? = status == :suppressed or last == :suppressed or present?(row, :suppressed_at)
# durable_failure?(row, confirmed?, suppressed?) uses `not suppressed?`
# and the not_sent clause becomes `suppressed? -> :not_sent`
```

Add terminal-latch rows to the grid or the precedence table.

### WR-08: `delivery_class/1` cannot see a bounce on the only row shape production produces, and a test pins that

**File:** `mailglass_admin/lib/mailglass_admin/status_map.ex:43-48`, `mailglass_admin/test/mailglass_admin/status_map_test.exs:326-335`, `lib/mailglass/operator/deliveries.ex:122-137`
**Issue:** The function exists so that "a late :opened or :clicked would not hide a delivery or a
bounce". Both operator projections (`delivery_projection/1` and the `outcome_groups` select) carry
only `status`, `last_event_type` and `delivery_confirmed`; no `bounced_at`, `terminal`,
`complained_at` or `suppressed_at`. On that shape a bounce followed by an open reads `:sent`, which
is the exact failure the function was written to prevent. The test
`operator row limitation: a bounce overwritten by a later open reads sent` asserts the wrong
answer as expected ("not a bug to fix here"), and nothing tracks the dependency. The first screen
to switch to `delivery_class/1` will label bounced mail "Sent".
**Fix:** Add the durable columns (or a precomputed `failure_reported` boolean) to both operator
projections before any screen consumes `delivery_class/1`, and change the pinned test to assert
the corrected result on the richer shape. If that is deliberately out of scope, file a tracked
todo and have `delivery_class/1` fail loudly (or return a distinct value) on the three-field
shape instead of returning a confident `:sent`.

### WR-09: A CLI test runs `update` against the real repository tree, contradicting the file's hermeticity claim

**File:** `test/scripts/brand_pin_test.exs:4-6, 689-695`; `scripts/brand_pin.exs:716, 767-781`
**Issue:** The header says "every mutation writes only under its own ExUnit tmp_dir ... never the
repository tree". `update against the real pin refuses a zip with the wrong hash before any write`
calls `pin(:cli, [["update", ...], getter])`. `cli/2` takes no target, so `update/3` falls back to
`@repo_root` and the test depends on the hash refusal being correct to avoid rewriting
`brandbook/brand.pin.json` and `brandbook/v2/*` with synthetic data. If that refusal ever
regresses (the exact thing under test), the test itself corrupts the committed pin and assets.
**Fix:** Give `cli/3` a `target_dir` option and pass a `tmp_dir`, or drop the real-tree CLI update
case, since the `update/3` tests already cover the refusal against a temp tree:

```elixir
def cli(args, getter \\ &http_get/1, opts \\ [])
# ... update(pin_map, Keyword.merge(opts_from_args, Keyword.take(opts, [:target_dir])), getter)
```

## Info

### IN-01: Retry helper rescues every `Postgrex.Error`, is copied verbatim, and misnames its attempt count

**File:** `test/mailglass/outbound/suppressed_not_persisted_test.exs:122-151`
**Issue:** This is the same `insert_suppression!/2` as `test/mailglass/outbound/deliver_many_test.exs:499-516`
(now two copies). It retries on any `Postgrex.Error`, while `test/support/citext_probe.ex`
documents that only the poisoned-OID surface should be retried and every other error re-raised so
real faults are not hidden. `attempts_left = 4` makes five insert attempts (four via recursion plus
the unconditional final one). The name ends in `!` but returns `{:ok, _} | {:error, changeset}`.
**Fix:** Move one helper into `test/support`, drop the blanket rescue (the `setup` and `DataCase`
already run `CitextProbe`), and call `Mailglass.SuppressionStore.Ecto.record/2` or
`Entry.changeset |> TestRepo.insert!()`.

### IN-02: Invisible U+00A0 literal in test source

**File:** `mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs:660`
**Issue:** `nbsp = " "` is a raw non-breaking space (bytes `c2 a0`). Editors, formatters and
copy-paste can silently normalize it to an ASCII space, at which point the "no Unicode trimming"
test would assert against a plain space and fail confusingly.
**Fix:** `nbsp = " "`.

### IN-03: Trademark-symbol scan covers markdown only, not the other published prose surfaces

**File:** `test/scripts/brand_trademark_gate_test.exs:30-45`
**Issue:** While the gate denies, the test forbids U+2122 and U+00AE only in README, CHANGELOG, docs,
guides and brandbook markdown. `@moduledoc` text in `lib/**` (published to HexDocs),
`brandbook/index.html`, `mix.exs` descriptions and admin UI strings are not scanned, so a symbol
can still ship while the record says no announcement.
**Fix:** Extend the scan to `lib/**/*.ex`, `mailglass_admin/lib/**/*.ex`,
`mailglass_inbound/lib/**/*.ex`, `**/*.html` under `brandbook/`, and the `description:` in each
`mix.exs`, or state the narrower scope in the test name and `TRADEMARK-SEARCH.md`.

### IN-04: `Copy` comment says nothing renders the vocabulary, but one entry is `wired: true`; the binding is a substring check

**File:** `mailglass_admin/lib/mailglass_admin/copy.ex:78-79, 88-94`; `mailglass_admin/test/mailglass_admin/copy_contract_test.exs:679-689`
**Issue:** "Data only: nothing renders these yet" sits above a list whose `:account` entry is
`wired: true`. The test that "binds" a wired entry passes if any string literal anywhere under
`mailglass_admin/lib` contains the substring `Account` (about 20 hardcoded literals do), and no
production code reads `Copy.vocabulary/0`. The flag therefore means "someone typed the word
somewhere", not "screens read it from `Copy`". The vocabulary also duplicates the policy's gloss
table with no test tying the two together.
**Fix:** Reword the comment, define `wired` precisely in the moduledoc, and add a test that
`Copy.vocabulary/0` equals the parsed `gloss-table` from the policy file (the parser already
exists in the policy test).

### IN-05: Small robustness gaps in `brand_pin.exs`

**File:** `scripts/brand_pin.exs:23, 370-396, 558-568`
**Issue:** Three minor items. (1) `check_zip/2` decompresses the listed members even when the
top-level hash or size already mismatched; `download/4` (init and update) hashes first, but the
advisory `check` path reads a potentially unexpected archive before rejecting it. (2) `@repo_name`
accepts `.` and `..` path components (`../..` is a "valid" repo and yields a URL with `..`
segments). The repo comes from the committed pin, so this is hygiene rather than exposure. (3)
`book_meta/1` collapses a specific `{:book_date_unparseable, date}` into `:book_meta_unreadable`,
which makes a failed update harder to diagnose.
**Fix:** Skip member extraction when `top` is non-empty, reject repo segments equal to `.` or
`..`, and add the date reason to the `else` clause of `book_meta/1`.

---

_Reviewed: 2026-11-14T00:40:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
