---
phase: 143
plan: gap-closure-search-path-guard
subsystem: test-harness
tags: [harness-01, d-31, class-a, search-path, credo, pool-poisoning, prevention-layer]
status: complete
requires:
  - "Mailglass.TestSupport.SandboxOwnership — checkout!/1, with_schema!/2, scratch_schema!/2 (plans 143-01/04/07 + the Class A gap closure)"
  - "Mailglass.Credo.NoRawSandboxOwnership — the check this one is modelled on (plan 143-08)"
provides:
  - "Mailglass.Credo.NoRawSearchPathMutation — build-failing static ban on raw search_path mutations under test/, registered in .credo.exs"
  - "SandboxOwnership.with_search_path!/3 + SearchPathError — the sanctioned, same-connection, VERIFIED search_path override seam"
affects:
  - "credo_checks/, .credo.exs, test/support/sandbox_ownership.ex, and the one remaining raw call site"
key-files:
  created:
    - credo_checks/no_raw_search_path_mutation.ex
    - test/mailglass/credo/no_raw_search_path_mutation_test.exs
  modified:
    - .credo.exs
    - test/support/sandbox_ownership.ex
    - test/mailglass/test_support/sandbox_ownership_test.exs
    - test/mailglass/schema_prefix_hardening_test.exs
metrics:
  axes-verified: 2
  mutation-checks: 5
  new-tests: 25
  allowlist-entries: 3
---

# Phase 143 Gap Closure: the `search_path` prevention layer

Closes the item `143-gap-closure-class-a-schema-collision-SUMMARY.md` §8 recorded as explicitly
NOT closed:

> No suite-wide instrument observes pooled-connection `search_path`. A Credo check forbidding
> unscoped `SET search_path` under `test/` — mirroring `NoRawSandboxOwnership` — would be the
> fail-closed layer; not built.

It is built. `Mailglass.Credo.NoRawSearchPathMutation` fails the build on any raw `search_path`
mutation under `test/` and `mailglass_inbound/test/`, and the one legitimate call site now routes
through a new sanctioned seam, `SandboxOwnership.with_search_path!/3`.

The phase thesis is two-layer guards. The `search_path` defect had detection only — a
same-connection verified restore hand-rolled in one file — and detection alone is exactly what let
the class recur. This is the prevention half.

---

## 1. What the check bans, and why each form

Every form below is banned in **SQL-statement position** under the linted test trees.

| Form | Why it is banned |
|---|---|
| `SET search_path ...` | Session-scoped. Persists on the physical Postgres connection for its whole lifetime. Under Sandbox `:auto` every query checks a connection out of the 10-slot pool and hands it straight back, so the connection returns **poisoned** — and some later, wholly unrelated test draws it and raises `42P01 (undefined_table)` on an unqualified relation name. Seven innocent victim modules; two full misdiagnosis cycles. This is the confirmed D-31 Class A root cause. |
| `SET SESSION search_path ...` | An explicit spelling of exactly the same session write. |
| `SET LOCAL search_path ...` | Transaction-scoped, so it *cannot* poison the pool — and that is precisely why it reads as the safe escape hatch. It is not. `SET LOCAL` persists to the end of the transaction, and `Ecto.Migrator` inserts its `schema_migrations` version row **inside that same transaction, after the migration body**, so a `LOCAL` pin inside a migration redirects Ecto's own bookkeeping INSERT to a path holding no `schema_migrations` table. Observed live pre-fix: `MAILGLASS_SCHEMA=mailglass mix test test/mailglass/shipped_migration_divergence_test.exs` → 4 tests, 4 failures, all `42P01 … relation "schema_migrations" does not exist`. "Safer than the worst form" is not the same as safe. |
| `RESET search_path` | Cannot poison — it restores the startup-packet value. But issued from `:auto` mode it is its **own** pool checkout landing on an arbitrary connection, so it heals nothing observable while reading as a fix. A guard that reads as a guarantee without being one is the exact credibility failure this milestone repairs. |
| `SELECT set_config('search_path', ...)` | The function-call spelling of a session-level `SET`. Anchored to the `SELECT`/`PERFORM` that invokes it, so a bare mention of the function name in prose or a keyword list stays out of scope. |

**"Statement position" is defined twice over, and both definitions are load-bearing:**

1. **Statement-initial within the literal** — the match must open a SQL statement: at the start of
   the string, or immediately after a `;`. This is what keeps
   `CREATE FUNCTION … SET search_path = ''` — a function *attribute* clause that hardens a function
   body against search-path injection, and a different construct entirely from a session write —
   out of scope with no allowlist entry. It is also what makes the multi-statement evasion
   (`CREATE SCHEMA scratch; SET search_path TO scratch`) a hit rather than a miss.
2. **Not an assertion match target** — a literal that is a direct argument of `=~` or
   `String.contains?/2` is *compared*, never executed, so it cannot poison anything. This
   positional carve-out (param `:match_target_functions`) is why
   `test/mailglass/upgrade_v2_schema_generation_test.exs`'s two
   `assert body =~ "SET search_path = ''"` assertions needed neither migration nor exemption.

The carve-out is positional rather than file-based **on purpose**: the alternative — splitting a
literal apart so the check cannot see it — teaches precisely the evasion the guard exists to
prevent, and that credibility loss is what `NoRawSandboxOwnership`'s own "deliberate non-copy"
comment already warns about.

## 2. What the check permits

- `SHOW search_path` — read-only.
- `search_path` in the Postgrex `:parameters` connection option (`test/test_helper.exs`). That is
  the connection's **startup** value, set once at pool-connect time on every connection — precisely
  the invariant the bans above exist to protect.
- `SET search_path = ''` as a `CREATE FUNCTION` attribute clause (never statement-initial inside
  the `CREATE`).
- The same literals as assertion match targets.
- Anything inside the three allowlisted modules below.

## 3. The allowlist — three entries, each justified

Each entry is safe because of **what the module is**, not because of what it happens to contain
today. The comment block in `.credo.exs` carries the same justifications inline.

| Entry | Why it is safe |
|---|---|
| `Mailglass.TestSupport.SandboxOwnership` | The sanctioned seam itself. It is the only place that may issue the raw statement, because it is the only place that pins ONE pooled connection for the whole block, restores the prior value on that same connection, and re-reads it to verify the restore landed. Exempting it is what makes every *other* exemption unnecessary — legitimate needs route through it instead of being allowlisted. |
| `Mailglass.TestSupport.SandboxOwnershipTest` | The seam's own mechanism test. It must drive real `SET`/`SHOW search_path` statements against the live pool to prove the restore-verification raise path actually fires; a mechanism test that cannot contain its own mechanism proves nothing. Same module, same rationale as `NoRawSandboxOwnership`'s second entry. |
| `Mailglass.Credo.NoRawSearchPathMutationTest` | The check's own fixture corpus. Its positive cases must spell the banned statements verbatim, **including** the multi-statement `…; SET search_path …` evasion the semicolon branch exists to catch — and there is no way to write that fixture without a statement-initial literal in the file's own source. Zero risk: the module is a pure `async: true` Credo unit test that opens no database connection at all. The alternative (splitting the literals) was rejected as strictly worse, per §1. |

No file-level exemptions, no `excluded:` paths, no weakened assertions anywhere.

## 4. Call sites migrated, not exempted

There was exactly **one** remaining raw call site, and it was migrated rather than allowlisted.

`test/mailglass/schema_prefix_hardening_test.exs`'s private `with_public_search_path!/1` — which
carried its own hand-rolled checkout / SET / restore / verify block plus a 30-line mechanism
comment — is now a two-line delegation to
`SandboxOwnership.with_search_path!("public", fun, repo: TestRepo, caller: __MODULE__)`. The
mechanism account moved with the code, into the seam's `@doc`, where every future caller reads it.

The same file's `RESET search_path` in `on_exit` was **deleted, not relocated**. It was documented
as "harmless belt-and-braces", but it was its own pool checkout on an arbitrary connection: it
could neither be relied on nor read as evidence that no connection was poisoned. Its removal was
confirmed non-load-bearing **empirically**, not by argument — both CI seeds are green on both axes
without it (§6).

Nothing else needed migrating. The other `SET LOCAL` pins were already removed in the previous gap
closure, and every remaining `search_path` occurrence under `test/` is a comment (invisible to an
AST-based check by construction), a `SHOW`, a `:parameters` keyword, an assertion match target, or
`schema_isolation_immutability_test.exs`'s deliberately fragment-assembled anti-self-match needle.

## 5. The seam: `with_search_path!/3` + `SearchPathError`

New public surface on `Mailglass.TestSupport.SandboxOwnership`:

```elixir
SandboxOwnership.with_search_path!("public", fn -> ... end, repo: TestRepo, caller: __MODULE__)
```

`Ecto.Repo.checkout/2` pins ONE connection for the whole block, so the override, the code under
test, and the restore all ride the same connection. `after` guarantees the restore even when the
block raises, and a post-restore **re-read** makes the restore verified rather than assumed — a
restore that cannot be observed to have worked must not be reported as success (D-31). A mismatch
raises `SearchPathError`, naming the offending module, the expected and actual values, and the
42P01 consequence that would otherwise have landed on an innocent module.

An injectable `:search_path_fun` (default: the real `SHOW search_path` read) is used **only** for
the verification read, mirroring `with_schema!/2`'s existing `:schema_fun` idiom, so the raise path
is testable with a synthetic mismatch rather than by genuinely poisoning the suite's pool.

## 6. Fail-closed: non-observation is a failure, never a green

Credo hands `run/2` an **empty AST** with `status: :invalid` when a file fails to parse. Traversing
an empty AST finds nothing and would report a confident green over a file whose contents were never
read — the exact "reported success without observing its subject" shape this milestone eliminates.
`run/2` therefore reports an explicit `unparsable-source` issue for any **in-scope** file it cannot
parse, and two tests pin that behaviour (in-scope unparsable → 1 issue; out-of-scope unparsable →
still out of scope).

**Documented observation boundary, stated rather than papered over:** the check reads string
literals in the AST, including interpolated ones. A statement assembled by `<>` concatenation of
separate literals (`"SET" <> " " <> "search" <> "_path"`) is outside its window. That is deliberate:
the repo's one existing use of that form is
`schema_isolation_immutability_test.exs`'s anti-self-match needle, and folding concatenations would
flag it. This is a scope boundary of the same class as `NoRawSandboxOwnership`'s documented
non-coverage of `apply/3` — not a "cannot verify" branch routed to silence.

## 7. Mutation checks (non-vacuity)

Each guard was shown to fail when its underlying defect is reintroduced, with everything else in
place. Every mutation was reverted from a byte-identical backup and the tree re-verified (§8).

| # | Defect reintroduced | Result |
|---|---|---|
| M1 | The original unscoped `TestRepo.query!("SET search_path TO public", [])` restored in `schema_prefix_hardening_test.exs` | `mix credo --strict` → **1 warning, exit 16**, `test/mailglass/schema_prefix_hardening_test.exs:301:26 #(Mailglass.SchemaPrefixHardeningTest.with_public_search_path!)`, trigger `SET search_path` |
| M2 | `execute("SET LOCAL search_path TO #{@prefix}, public")` re-typed into `shipped_migration_divergence_test.exs`'s wrapper migration | **1 warning**, `shipped_migration_divergence_test.exs:45 #(…ShippedWrapperMigration.up)` — the exact pin whose removal M5 of the prior gap closure justified |
| M3 | `TestRepo.query("RESET search_path")` restored in the same file's `on_exit` | **1 warning**, `schema_prefix_hardening_test.exs:154:27`, trigger `RESET search_path` |
| M4 | `TestRepo.query("SELECT set_config('search_path', 'public', false)")` added | **1 warning**, `schema_prefix_hardening_test.exs:155`, trigger `set_config('search_path', ...)` |
| M5 | The seam's own restore statement deleted from `with_search_path!/3`'s `after` block | **3 failures** in `sandbox_ownership_test.exs` — all three new seam tests, with the real message `expected "\"$user\", public", got "public"`, proving the verification observes genuine connection state rather than a tautology |

Clean-tree control: `mix credo --strict` → `3904 mods/funs, found no issues.`, exit 0.

M1 is the decisive check: it reintroduces *exactly* the statement that M4 of the previous gap
closure proved reproduces the CI victim set, and the build now fails on it statically — before a
single test runs, at the file that would cause it.

## 8. Acceptance

Every run from a freshly reset DB
(`MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet`),
with `--warnings-as-errors`, read from **raw `mix test` output only** — never the SuiteFloor ledger
or the formatter.

| Axis | Seed | Result | Exit |
|---|---|---|---|
| `MAILGLASS_SCHEMA=mailglass` | 374117 (CI) | 23 properties, **1546 tests, 0 failures**, 7 skipped (14 excluded) | 0 |
| public (default) | 783091 (CI) | 23 properties, **1547 tests, 0 failures**, 7 skipped (13 excluded) | 0 |

`signature tally: already_shared=0, formatter_violations=0` on both.

**Test-count delta, reconciled exactly:** mailglass axis 1521 → 1546, public axis 1522 → 1547.
Both +25 = 22 new tests in `no_raw_search_path_mutation_test.exs` + 3 new seam tests in
`sandbox_ownership_test.exs`. No pre-existing test was removed, skipped, excluded, or weakened.

`mix format --check-formatted` → clean. `mix credo --strict` → `3904 mods/funs, found no issues.`

The two standing meta-guards both pass against the new check with no exclusion added:
`checks_have_tests_test.exs` (every `credo_checks/*.ex` has a matching regression test **and** a
`.credo.exs` registration) and `credo_config_sentinel_test.exs`.

## 9. Deviations from the directed scope

1. **`SET LOCAL` is banned, not permitted.** The directed task left the decision open. Permitting it
   would have re-legitimised the exact pin the previous gap closure removed for breaking Ecto's
   `schema_migrations` bookkeeping (M5 there, M2 here). The rationale is encoded in the check's
   `explanations`, in the issue message, and in the seam's `@doc`, so a future reader hitting the
   ban learns *why* the transaction-scoped form is not the escape hatch it looks like.
2. **`RESET` and `set_config` are banned too**, beyond the directed "unscoped `SET`". `RESET` because
   it reads as a heal while healing nothing observable; `set_config` because it is the same session
   write wearing a function call, and a ban that a one-line rewrite walks around is not a ban.
3. **Scope widened to `mailglass_inbound/test/`.** The inbound sibling runs its own pool with the
   identical hazard, `.credo.exs` already lints that tree, and it required no migrations there
   (verified: no raw call sites exist in inbound test code).
4. **A third allowlist entry** (the check's own test) beyond the two the directed model check has,
   justified in §3 and in `.credo.exs`. The alternative was literal-splitting, rejected as worse.
5. **Three seam tests added to `sandbox_ownership_test.exs`**, not directed. A seam introduced to
   replace a hand-rolled guarantee that nothing tested would otherwise inherit the same problem;
   M5 shows they are non-vacuous.

## 10. Not closed

- **Still no *runtime*, suite-wide instrument observing pooled-connection `search_path`.** This
  closes the gap with a **static** fail-closed layer, which is what §8 of the prior SUMMARY asked
  for and is strictly stronger for the re-typing case (it fails before any test runs, at the
  offending file). It is strictly weaker for a mutation arriving through a path the AST cannot see —
  `<>`-concatenated literals (§6), `apply/3`, or a SQL string read from a fixture file. A
  `SuiteTruthFormatter`-side `SHOW search_path` probe at each `async: false` module boundary would
  cover those; not built here.
- **The formatter's `:module_finished`-only boundary blind spot is unchanged** (143-MECHANISM.md §7).
  Nothing here narrows it.
- **`upgrade_v2_schema_migration_test.exs`'s test names still say "mailglass.\*"** where they now
  mean the scratch schema — carried forward unchanged from the prior SUMMARY §8, deliberately, since
  those names are referenced by ref in earlier 143 traceability entries.

## Self-Check: PASSED

- `credo_checks/no_raw_search_path_mutation.ex` — FOUND
- `test/mailglass/credo/no_raw_search_path_mutation_test.exs` — FOUND
- `.credo.exs`, `test/support/sandbox_ownership.ex`,
  `test/mailglass/test_support/sandbox_ownership_test.exs`,
  `test/mailglass/schema_prefix_hardening_test.exs` — all modified and present
- Working tree clean of every mutation; `mix credo --strict` and
  `mix format --check-formatted` both clean on the committed state
