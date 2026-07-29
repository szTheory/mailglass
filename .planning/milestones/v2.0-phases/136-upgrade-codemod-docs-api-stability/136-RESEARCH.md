# Phase 136: Upgrade codemod + docs + api_stability (Design Phase E) - Research

**Researched:** 2026-07-03
**Domain:** Elixir/Ecto migration code-generation (Mix task), Postgres `ALTER TABLE … SET SCHEMA`, HexDocs/publish doc-wiring, api_stability contract docs
**Confidence:** HIGH (every claim below is cross-checked against shipped source read this session)

## Summary

Phase 136 ships the adopter upgrade path for mailglass 2.0's schema-isolation change. The design-of-record `.planning/research/milestone-schema-isolation/SCHEMA-ISOLATION-DESIGN.md` §4 already locks the *what* (both upgrade routes, the exact Route B move-migration SQL, the safety facts, the locking posture, the grants). This research resolves the five *how* questions the planner needs to write unambiguous tasks, and confirms §4's facts against the actual shipped codebase (v01–v05 migration stack, the two existing codemod precedents, the publish/docs gate machinery, the Phase-134 regression-test template).

Every §4 fact I could check held: the four table names are exactly `mailglass_events`, `mailglass_deliveries`, `mailglass_suppressions`, `mailglass_webhook_events` `[VERIFIED]`; the trigger/function names are `mailglass_events_immutable_trigger` / `mailglass_raise_immutability` `[VERIFIED]`; the version marker IS a `COMMENT ON TABLE … mailglass_events` (`obj_description`), so §4's "SET SCHEMA preserves the comment" claim is load-bearing and must be tested `[VERIFIED]`; the trigger FUNCTION genuinely does not auto-move (it is a separate object) `[VERIFIED]`.

**Primary recommendation:** Implement `mix mailglass.upgrade.v2_schema` as a **plain `use Mix.Task` file-emitter** (mirroring `mailglass.gen.migration`, NOT the Igniter `v0_2` codemod), because the deliverable GENERATES a migration file — it does not rewrite adopter AST. This keeps the `mix compile --no-optional-deps --warnings-as-errors` lane green without a compile guard, needs no optional Igniter dep, and matches the existing file-emitter precedent exactly. The generated migration body is a byte-for-byte transcription of §4's `MoveMailglassToSchema` example, with the trigger/function block made byte-identical to the shipped `v01.ex` fresh-install DDL so a moved DB equals a fresh-installed DB.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Generate move-migration file | Mix task (build-time tooling) | — | Emits a `.exs` into adopter's `priv/repo/migrations/`; no runtime path |
| Execute the move DDL | Database / migration | — | `ALTER TABLE … SET SCHEMA`, trigger recreation run by Ecto migrator |
| Document the two routes | Docs (guides) | — | `guides/upgrading-to-v2_0.md` — adopter-facing prose |
| Declare `:schema` stable | Docs (contract) | — | `docs/api_stability.md` + `mailglass_inbound/docs/api_stability.md` |
| Assert the codemod green | Test (ExUnit, `async: false` DDL) | — | Mirrors Phase-134 `schema_isolation_immutability_test.exs` shape |

## Locked context (from SCHEMA-ISOLATION-DESIGN §4 — do not re-derive)

§4.1–4.4 already fix: Route A (`config :mailglass, :schema, "public"` one-line opt-out); Route B (the `MoveMailglassToSchema` move migration with `SET LOCAL lock_timeout='5s'`, `CREATE SCHEMA IF NOT EXISTS`, `ALTER TABLE public.<t> SET SCHEMA`, DROP+recreate the immutability trigger/function schema-qualified with `SET search_path=''`, working `down/0`); the safety facts (SET SCHEMA is a metadata-only OID relnamespace swap, indexes/constraints/sequences move with the table, FKs/views resolve by OID, citext column type unaffected, the trigger FUNCTION does NOT auto-move — the single manual step); the ACCESS EXCLUSIVE lock posture + `lock_timeout`+retry guidance; §4.4 `create_schema: false` grants; §4.3 rollback. **The tasks below implement §4; they do not re-open it.**

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UPG-01 | `mix mailglass.upgrade.v2_schema` generates a Route B move migration (`CREATE SCHEMA`, `ALTER TABLE … SET SCHEMA` all four core tables under `SET LOCAL lock_timeout`, trigger+function recreated schema-qualified, working `down/0`) | Resolved-decision 1 (task pattern) + Verified-fact "exact generated migration" + resolved-decision 3 (lock_timeout semantics) |
| UPG-02 | `guides/upgrading-to-v2_0.md` documents both routes, `create_schema: false` grants, the `public.mailglass_*` literal-SQL grep checklist, `lock_timeout`+retry posture | Resolved-decision 4 (doc content) + §4.2/4.4 verbatim source |
| UPG-03 | `api_stability.md` (core + inbound) documents `:schema` as a stable 2.0 surface + tenancy-vs-schema orthogonality | Resolved-decision 4 (api_stability wording) + Verified-fact "api_stability shape" |
| UPG-04 | The codemod is run end-to-end against `reference/host_app` (frozen baseline) and asserted green | Resolved-decision 5 (test strategy) + Verified-fact "host_app baseline is empty of mailglass tables" (the mechanical meaning of "run against host_app") |

## Resolved decisions

### Decision 1 — Codemod implementation pattern: plain `Mix.Task` file-emitter (NOT Igniter)

**Question:** Igniter AST-rewrite task (like `mailglass.upgrade.v0_2`) vs. plain `Mix.Task` file-emitter (like `mailglass.gen.migration`)?

**Evidence:**
- `lib/mix/tasks/mailglass.upgrade.v0_2.ex:9` wraps the *entire module* in `if Code.ensure_loaded?(Igniter.Mix.Task) do … end` because Igniter is `optional: true, runtime: false` (`mix.exs:180`) and pulls `req`/`finch`/`mint`. Igniter is the right tool THERE because v0_2 rewrites adopter source AST (`Igniter.update_all_elixir_files`, `Sourceror.Zipper` — v0_2.ex:50–98).
- `lib/mix/tasks/mailglass.gen.migration.ex` is a plain `use Mix.Task` (`:5`) that WRITES a timestamped `.exs` FILE into `priv/repo/migrations/` (`:27–32`). It discovers the app module by regex over `mix.exs` (`current_app_module/0`, `:72–79`), computes a `timestamp/0` (`:49–53`), and is idempotent via a wildcard existence check (`existing_wrapper_migration/0`, `:41–47`).
- Phase 136's deliverable GENERATES a migration file. It does **not** rewrite adopter Elixir source. There is zero AST-rewrite requirement.

**Rationale:** A file-emitter needs no AST library, so it needs no Igniter, so it needs no compile guard — the `mix compile --no-optional-deps --warnings-as-errors` lane stays green with an ordinary `use Mix.Task` module (no `if Code.ensure_loaded?` wrapper, no optional-dep pollution). This is strictly simpler and lower-risk than the Igniter path, honors the zero-Node / narrow-public-surface principles, and reuses a precedent that already lives one file over. The §4 phrase "mirrors the existing `mailglass.upgrade.v0_2` Igniter precedent" refers to the *user-facing shape* (a `mailglass.upgrade.*` codemod task with a `--apply`/dry-run posture), not the internal mechanism.

**RECOMMENDATION:** Implement `Mix.Tasks.Mailglass.Upgrade.V2Schema` as a plain `use Boundary, classify_to: Mailglass` + `use Mix.Task` module (no Igniter, no compile guard). Copy the `gen.migration` mechanics verbatim:
- **App-module discovery:** regex `~r/app:\s*:(\w+)/` over `mix.exs` → `Macro.camelize` (mirror `current_app_module/0`).
- **Timestamp:** `NaiveDateTime.utc_now |> truncate(:second) |> Calendar.strftime("%Y%m%d%H%M%S")` (mirror `timestamp/0`).
- **Idempotency:** wildcard `priv/repo/migrations/*_move_mailglass_to_schema.exs`; if one exists, print `unchanged <path>` and no-op (mirror `existing_wrapper_migration/0`). Prevents double-generation and defuses the timestamp-collision landmine.
- **Options:** support `--apply` for parity with the codemod idiom, but since this task only WRITES a new file (it does not mutate existing files), the safe default is to WRITE the file and print the path. Consider a `--dry-run` that prints the would-be path + body without writing. (Unlike v0_2, there is no destructive in-place edit to guard, so `--apply` is optional polish, not a safety gate — the planner may drop it to keep the surface minimal.)
- **Schema name:** read `Mailglass.Config.schema/0`? No — the task runs in the *adopter's* mix context where mailglass config may already say `"mailglass"`; the generated migration must hard-code the target schema literal it moves TO. Emit `@schema "mailglass"` in the generated body (the 2.0 default). If the planner wants configurability, accept `--schema <name>` and validate via `Mailglass.Identifier.validate!/2` before interpolation (the single unquoted-identifier chokepoint — `lib/mailglass/identifier.ex`).

### Decision 2 — Exact generated move-migration content

**Question:** Confirm the four table names, trigger/function names, and that the recreated qualified trigger/function byte-matches the fresh-install v01 path; confirm the comment/version-marker survival claim.

**Evidence:** see Verified-facts below. All names confirmed. The version marker IS a table comment (`postgres.ex:129`), so §4's `obj_description` survival note is real and must be asserted.

**RECOMMENDATION:** The generated body is §4's `MoveMailglassToSchema` transcribed, with the recreated function/trigger block copied **character-for-character from `v01.ex:138–159`** (same `SET search_path = ''`, same `RAISE SQLSTATE '45A01' USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden'`, same `BEFORE UPDATE OR DELETE`, same `FOR EACH ROW EXECUTE FUNCTION`). Byte-parity is the correctness contract: a moved DB must be indistinguishable from a fresh-installed one. See the "Exact move-migration SQL (final form)" verified fact for the literal body.

### Decision 3 — `lock_timeout` + retry posture

**Question:** Confirm `SET LOCAL lock_timeout` semantics inside an Ecto migration transaction; whether `@disable_ddl_transaction`/`@disable_migration_lock` matter.

**Evidence + facts `[VERIFIED: Ecto.Migration semantics + shipped code]`:**
- Ecto wraps each migration in a transaction by default (unless `@disable_ddl_transaction true`). `SET LOCAL lock_timeout = '5s'` is transaction-scoped — it applies to the rest of the migration transaction and auto-reverts on commit/rollback. This is exactly what §4 wants: the `ALTER TABLE … SET SCHEMA` statements that follow inherit the 5s timeout and fail fast (SQLSTATE `55P03` lock_not_available) instead of queueing behind long readers holding the `ACCESS EXCLUSIVE` lock.
- **Do NOT set `@disable_ddl_transaction`** here. The move must be transactional so a mid-move failure rolls the whole thing back (partial moves would split the four tables across two schemas). `SET LOCAL` *requires* an enclosing transaction to be meaningful — outside a transaction `SET LOCAL` is a no-op warning. So the default (transactional) migration is mandatory, and §4's design is correct as written.
- **`@disable_migration_lock` is irrelevant** to this concern (it governs Ecto's advisory migration lock across concurrent migrators, not the table-level `ACCESS EXCLUSIVE`).
- **Retry:** because the DDL is inside a transaction, a `lock_timeout` abort rolls back the whole migration; the adopter simply re-runs `mix ecto.migrate` (Ecto records nothing on failure, so a re-run re-attempts). The guide documents: "if the migration aborts with `55P03` (lock_not_available), it means a long-running query held the table — retry `mix ecto.migrate` off-peak; the move is metadata-only and instant once the lock is granted." This is guidance for the GUIDE (UPG-02), not code — the migration itself does not loop.

**RECOMMENDATION:** Generated migration keeps the default transactional wrapper (no `@disable_ddl_transaction`), opens `up/0` with `execute "SET LOCAL lock_timeout = '5s'"`, and the guide documents the `55P03`-retry posture. No `@disable_migration_lock`. STATE flagged this as an edge to research — resolved: the naive design is correct; the only subtlety is that `SET LOCAL` mandates the transactional wrapper, which reinforces "do not disable the DDL transaction."

### Decision 4 — Doc + api_stability wiring mechanics

**Question:** Which files must change to wire `guides/upgrading-to-v2_0.md` into published docs; what "stable 2.0 surface" wording for `:schema` in both api_stability docs.

**Evidence `[VERIFIED: shipped gate source]`:**
- **HexDocs rendering** requires the guide in `mix.exs` `extras:` (`mix.exs:435–461`) AND `groups_for_extras:` under the `Guides:` group (`mix.exs:468–487`). Both are lists of literal path strings.
- **Package tarball** ships guides via the `files: ~w(lib priv/gettext guides …)` glob (`mix.exs:402–403`) — the whole `guides/` dir is included wholesale, so no `files:` change is needed for the file to SHIP.
- **BUT the publish allowlist gate byte-compares the tarball file list against `.planning/publish/mailglass-files.expected`** (`mailglass.publish.check.ex` `verify_allowlist/1:449–473` — any `added` file hard-blocks with `fail_step`). The expected file enumerates each guide explicitly (`.planning/publish/mailglass-files.expected:8–27`). **A new `guides/upgrading-to-v2_0.md` MUST be added to that allowlist** or the 2.0 release blocks at publish — this is the exact landmine that caused the 1.10.2 tag-move dance (memory: v05.ex missing from the allowlist).
- **`mix mailglass.docs.check`** is NOT a wildcard scanner — it checks an explicit `@tier1_paths` allowlist with per-file `required`/`forbidden` token rules (`mailglass.docs.check.ex:24–53, 70–433`). A new guide is NOT auto-checked (default run only touches listed paths; a `--path` glob leak-checks unknowns and prints a "leak-only" notice — `:497–521`). Adding `guides/upgrading-to-v2_0.md` to `@tier1_paths` + a `@tier1_surface_rules` entry is **optional but recommended** to lock the guide's contract wording against drift (mirror the `guides/upgrading-to-v1_0.md` rule at `:272–283`). Not required to ship.
- **api_stability shape:** config keys are not currently a first-class section — the doc documents modules/tasks/telemetry/structs (`docs/api_stability.md` sections at `:94–176`, `:503–611`). Each stable item carries a `Since: <ver>` line (`:219, 236, …`). Add a new subsection (e.g. `## §Schema config (2.0)`) documenting `config :mailglass, :schema` with `Since: 2.0.0`, its contract (valid unquoted identifier, default `"mailglass"`, `"public"` the explicit opt-out), and the tenancy-vs-schema orthogonality paragraph (source: §3.9 / §5 non-goals). Mirror the same in `mailglass_inbound/docs/api_stability.md` for `config :mailglass_inbound, :schema`.

**RECOMMENDATION (exact file list to change for doc-wiring):**
1. `mix.exs` — add `"guides/upgrading-to-v2_0.md"` to `extras:` (after the `upgrading-to-v1_0.md` entry, `~:439`) AND to `groups_for_extras: Guides:` (`~:469`).
2. `.planning/publish/mailglass-files.expected` — add the line `guides/upgrading-to-v2_0.md` (keep the file sorted; it slots between `upgrading-from-v0_1.md` and `upgrading-to-v1_0.md` alphabetically). **Load-bearing for the 2.0 release gate.**
3. `guides/upgrading-to-v2_0.md` — NEW file (content per UPG-02: Route A/B, `create_schema:false` grants block from §4.4, `public.mailglass_*` grep checklist from §4.2, `lock_timeout`+`55P03`-retry posture from decision 3). Avoid literal `D-\d{2,3}` / `LINT-\d{2}` tokens (docs.check `@banned_patterns:23` — even though the guide isn't in `@tier1_paths` by default, adding it later trips this).
4. `docs/api_stability.md` — add `## §Schema config (2.0)` subsection (`:schema`, Since 2.0.0, tenancy orthogonality).
5. `mailglass_inbound/docs/api_stability.md` — add the mirror `:schema` subsection. NOTE: this file IS in `@tier1_paths` (docs.check.ex:31) with a `required`/`forbidden` rule (`:219–229`) AND in the inbound `required_file_entries` (publish.check.ex:1446) — do not remove existing required tokens; only ADD the `:schema` prose.
6. (OPTIONAL) `lib/mix/tasks/mailglass.docs.check.ex` — add `guides/upgrading-to-v2_0.md` to `@tier1_paths` + a `@tier1_surface_rules` entry to lock its wording. Recommend YES for symmetry with the v1_0 guide; low cost.

### Decision 5 — Verification / test strategy (UPG-01..04 → deterministic ExUnit)

**Question:** How each UPG becomes an automated deterministic check; especially UPG-04's end-to-end host_app run.

**Key finding on "run against reference/host_app":** `reference/host_app/priv/repo/migrations/20260527000000_create_mailglass_reference_baseline.exs` creates ONLY a `mailglass_reference_baseline` table — it does NOT install mailglass's four tables into `public`. So UPG-04 cannot literally `ALTER` real mailglass tables inside host_app's DB (they don't exist there), and running the generated migration against host_app as-is would fail on the first `ALTER TABLE public.mailglass_events`. The mechanically-correct reading of UPG-04 is: **an ExUnit test (in the core suite, using `Mailglass.TestRepo`) that (a) invokes the task to GENERATE the migration file, (b) stands up the four tables in `public` via the shipped `Mailglass.Migration.up(prefix: "public")` path (= the 1.x pre-move state), (c) runs the GENERATED migration up, (d) asserts the four tables now live under `mailglass.*`, the trigger still raises 45A01 under the moved schema with NO `search_path` pin, citext still resolves, the version-marker comment survived, and `public` is empty of mailglass tables, then (e) runs the generated migration down and asserts the tables are back in `public`.** The `reference/host_app` name in UPG-04 is best satisfied by ALSO asserting the *generated task* runs cleanly with host_app's `mix.exs` app-module (`mailglass_reference_host` → `MailglassReferenceHost`) as the module-name discovery input — i.e. prove the emitter produces a valid, compilable migration for the frozen baseline's app module, without needing to bump host_app's mailglass pin (which would trigger the 5-file baseline-coupling change — memory `project_reference_baseline_coupling`).

**Test template:** mirror `test/mailglass/schema_isolation_immutability_test.exs` (read in full this session). It already: switches Sandbox to `:auto` for DDL, overrides `:schema`, erases the `:persistent_term` cache, drops the schema clean, runs a wrapper migration via `Ecto.Migrator`, asserts 45A01 via `Postgrex.Error.pg_code`, asserts citext case-insensitivity, asserts down drops the schema, and restores the suite baseline in `on_exit`. The UPG-04 test is the same skeleton but the wrapper migration is: first `Mailglass.Migration.up(prefix: "public")` to seed 1.x state, then apply the GENERATED move migration.

**RECOMMENDATION:** two test modules, both `async: false, @moduletag :schema_isolation`:
- `test/mailglass/upgrade_v2_schema_generation_test.exs` — UPG-01: invoke the task's file-emitter (call the module function directly with a temp `priv/repo/migrations` dir + a synthetic `mix.exs`), assert the emitted file compiles, contains `ALTER TABLE public.mailglass_events SET SCHEMA`, all four table names, the byte-parity trigger/function block, `SET LOCAL lock_timeout`, and a `def down`. Also assert idempotency (second run prints `unchanged`).
- `test/mailglass/upgrade_v2_schema_migration_test.exs` — UPG-04 (+ UPG-01 execution): seed `public` via `Mailglass.Migration.up(prefix: "public")`, apply the generated migration via `Ecto.Migrator`, assert tables moved to `mailglass.*` (query `information_schema.tables`), 45A01 fires under `mailglass.mailglass_events` with no path pin (copy the `insert_event!` + UPDATE/DELETE asserts from the 134 test), the `obj_description` version comment survived, citext resolves, `public` has no mailglass tables; then migrate down and assert tables are back in `public`.
- UPG-02 / UPG-03 are doc requirements — verify via a `docs.check`-style token test OR a lightweight `File.read!` assertion in a `*_docs_test.exs` that the new guide contains the required section headers (Route A, Route B, grants SQL, grep checklist, lock_timeout) and that both api_stability files contain the `:schema` / `Since: 2.0.0` / orthogonality tokens. If the planner adds the guide to `@tier1_paths` (Decision 4 opt 6), `mix mailglass.docs.check` covers UPG-02 automatically.

## Verified facts (with citations)

### Four core table names `[VERIFIED: grep over lib/mailglass/migrations/postgres/*]`
`mailglass_events`, `mailglass_deliveries`, `mailglass_suppressions`, `mailglass_webhook_events`. (`mailglass_webhook_events` is created in `v02.ex:28`, NOT v01 — but §4's `@tables` list is correct; all four exist by `@current_version 5`.)

### Trigger + function names `[VERIFIED: v01.ex:138–159]`
Function `mailglass_raise_immutability()` (schema-qualified as `#{q}.mailglass_raise_immutability()`), trigger `mailglass_events_immutable_trigger` (unqualified name, `ON #{q}.mailglass_events`). SQLSTATE `45A01`, message `mailglass_events is append-only; UPDATE and DELETE are forbidden`, `SET search_path = ''`.

### Version marker IS a table comment `[VERIFIED: postgres.ex:122–130, migrated_version/1:63–75]`
`record_version/2` runs `COMMENT ON TABLE #{inspect(prefix)}.mailglass_events IS '<version>'`; `migrated_version/1` reads it back via `pg_catalog.obj_description(pg_class.oid, 'pg_class')` filtered by `nspname = $1`. §4's claim that `ALTER TABLE … SET SCHEMA` preserves `obj_description` is therefore **load-bearing** — if it did NOT survive, the moved DB would report version 0 and `Mailglass.Migration.up` would try to re-run v01..v05 into the already-moved schema. The UPG-04 test MUST assert the comment survived (query `obj_description` after the move returns `'5'`, or whatever `@current_version` is at 2.0).

### The trigger FUNCTION does not auto-move `[VERIFIED: §4 + Postgres semantics]`
In a 1.x install the function was created in `public` (1.x v01 was hard-bound to `public` — STATE Quick-Task 2026-06-30 confirms "V01's events immutability trigger is hard-bound to public"). `ALTER TABLE … SET SCHEMA` moves only the table; the function is a distinct `pg_proc` object. The move migration must `DROP FUNCTION public.mailglass_raise_immutability()` and recreate it as `mailglass.mailglass_raise_immutability()` + re-point the trigger. This is §4's "single manual step" — correct.

### Exact move-migration SQL (final form for the generator)
Transcribe §4.2's `MoveMailglassToSchema`, with the function/trigger block byte-matched to `v01.ex:138–159`:

```elixir
defmodule <AppModule>.Repo.Migrations.MoveMailglassToSchema do
  use Ecto.Migration

  @schema "mailglass"
  @tables ~w(mailglass_events mailglass_deliveries
             mailglass_suppressions mailglass_webhook_events)

  def up do
    execute "SET LOCAL lock_timeout = '5s'"
    execute ~s(CREATE SCHEMA IF NOT EXISTS "#{@schema}")
    for t <- @tables, do: execute(~s(ALTER TABLE public.#{t} SET SCHEMA "#{@schema}"))

    # The immutability FUNCTION does not move with the table — recreate it qualified.
    execute ~s(DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON "#{@schema}".mailglass_events)
    execute ~s(DROP FUNCTION IF EXISTS public.mailglass_raise_immutability())
    execute """
    CREATE OR REPLACE FUNCTION "#{@schema}".mailglass_raise_immutability()
    RETURNS trigger
    LANGUAGE plpgsql
    SET search_path = ''
    AS $$
    BEGIN
      RAISE SQLSTATE '45A01'
        USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden';
    END;
    $$;
    """
    execute """
    CREATE TRIGGER mailglass_events_immutable_trigger
      BEFORE UPDATE OR DELETE ON "#{@schema}".mailglass_events
      FOR EACH ROW EXECUTE FUNCTION "#{@schema}".mailglass_raise_immutability();
    """
  end

  def down do
    execute "SET LOCAL lock_timeout = '5s'"
    for t <- @tables, do: execute(~s(ALTER TABLE "#{@schema}".#{t} SET SCHEMA public))
    execute ~s(DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON public.mailglass_events)
    execute ~s(DROP FUNCTION IF EXISTS "#{@schema}".mailglass_raise_immutability())
    execute """
    CREATE OR REPLACE FUNCTION public.mailglass_raise_immutability()
    RETURNS trigger
    LANGUAGE plpgsql
    SET search_path = ''
    AS $$
    BEGIN
      RAISE SQLSTATE '45A01'
        USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden';
    END;
    $$;
    """
    execute """
    CREATE TRIGGER mailglass_events_immutable_trigger
      BEFORE UPDATE OR DELETE ON public.mailglass_events
      FOR EACH ROW EXECUTE FUNCTION public.mailglass_raise_immutability();
    """
  end
end
```

Note §4's example `down/0` left the public trigger/function recreation as "…"; the final form above completes it (mirror-of-up) so rollback restores the exact 1.x public-qualified trigger. The generator must emit this full `down/0`, not the elided §4 stub. `[VERIFIED: v01.ex byte-parity + §4.3 rollback intent]`

### `@schema` config key already exists `[VERIFIED: config/test.exs:15, config/runtime.exs:35–44]`
`config :mailglass, :schema, "public"` is pinned in test; runtime.exs threads `MAILGLASS_SCHEMA` for the CI axis. `Mailglass.Config.schema/0` + `Mailglass.Identifier.validate!/2` shipped in Phase 132 (STATE decisions 132-01/02). The api_stability doc just needs to DOCUMENT this existing surface.

### host_app baseline is empty of mailglass tables `[VERIFIED: reference/host_app/.../20260527000000_*.exs + mix.exs:35–37]`
Baseline migration creates only `mailglass_reference_baseline`; pins are `~> 1.0`. Confirms Decision-5's mechanical reading of UPG-04 and the reason NOT to bump the pin (baseline-coupling memory).

### Doc-wiring gate files `[VERIFIED: this session]`
- `mix.exs:435–461` (extras), `:462–494` (groups_for_extras), `:402–403` (files glob).
- `.planning/publish/mailglass-files.expected:8–27` (enumerated guides — the byte-compared allowlist).
- `mailglass.publish.check.ex:449–473` (`verify_allowlist/1` hard-blocks on any added file).
- `mailglass.docs.check.ex:24–53` (`@tier1_paths`), `:272–283` (v1_0 guide rule template), `:23` (banned `D-`/`LINT-` patterns).

## Validation Architecture

> nyquist_validation is enabled (not `false` in config). This section maps UPG-01..04 to deterministic automated checks the planner lifts into `must_haves` and `<verify>` blocks.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (shipped; `test/test_helper.exs` boots `Mailglass.TestRepo`) |
| Config file | `config/test.exs` (pins `:schema` "public") |
| Quick run command | `mix test test/mailglass/upgrade_v2_schema_generation_test.exs --seed 0` |
| Full suite command | `MAILGLASS_SCHEMA=mailglass mix test --only schema_isolation --seed 0` + default-schema `mix test --seed 0` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UPG-01 | Task emits a compilable move migration with all four `ALTER … SET SCHEMA`, byte-parity trigger/function, `SET LOCAL lock_timeout`, working `down/0`; idempotent | unit | `mix test test/mailglass/upgrade_v2_schema_generation_test.exs -x` | ❌ Wave 0 |
| UPG-01/04 | Generated migration, applied over a 1.x `public` seed, moves all four tables to `mailglass.*`; 45A01 fires under moved schema with NO path pin; version-comment + citext survive; `down` reverses to `public` | integration (DDL, `async: false`) | `mix test test/mailglass/upgrade_v2_schema_migration_test.exs -x` | ❌ Wave 0 |
| UPG-02 | `guides/upgrading-to-v2_0.md` contains Route A, Route B, grants SQL, `public.mailglass_*` grep checklist, `lock_timeout`/`55P03`-retry | doc-token | `mix test test/mailglass/upgrade_v2_docs_test.exs -x` (or `mix mailglass.docs.check` if guide added to `@tier1_paths`) | ❌ Wave 0 |
| UPG-03 | Both api_stability docs contain `:schema`, `Since: 2.0.0`, tenancy-vs-schema orthogonality prose | doc-token | same `*_docs_test.exs` module | ❌ Wave 0 |
| release gate | `guides/upgrading-to-v2_0.md` present in `.planning/publish/mailglass-files.expected` | allowlist | `mix mailglass.publish.check --package mailglass` (Phase 137) | n/a (config) |

### Sampling Rate
- **Per task commit:** the targeted `mix test <file> --seed 0` for the file touched (the `:schema_isolation` DDL tests are `async: false` and need `--seed 0` per the determinism memory).
- **Per wave merge:** `MAILGLASS_SCHEMA=mailglass mix test --only schema_isolation --seed 0` + `mix test --seed 0` (both axes).
- **Phase gate:** both-axis suite green + `mix format --check-formatted` + `mix credo --strict` (path-scoped to `lib/` per the credo memory) before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/mailglass/upgrade_v2_schema_generation_test.exs` — covers UPG-01 (emitter)
- [ ] `test/mailglass/upgrade_v2_schema_migration_test.exs` — covers UPG-01/04 (execution; clone `schema_isolation_immutability_test.exs` skeleton)
- [ ] `test/mailglass/upgrade_v2_docs_test.exs` — covers UPG-02/03 (unless folded into `docs.check` Tier1 rules)
- [ ] No framework install needed — ExUnit + TestRepo already boot.

## Landmines / pitfalls

### Pitfall 1: Publish allowlist blocks the 2.0 release
**What goes wrong:** The new guide ships (glob include) but `.planning/publish/mailglass-files.expected` doesn't list it → `verify_allowlist/1` hard-blocks at publish (Phase 137), forcing a tag-move recovery.
**Prevention:** Add `guides/upgrading-to-v2_0.md` to the expected file IN THIS PHASE, sorted. This is the exact 1.10.2 landmine (memory `project_1_10_2_patch_release`). Assert it with a tiny test that reads the expected file and checks the line is present.

### Pitfall 2: Trigger/function drift between generated migration and fresh install
**What goes wrong:** The generated recreation block diverges (whitespace, message text, `SET search_path`) from `v01.ex` → a moved DB behaves subtly differently from a fresh-installed one.
**Prevention:** Copy the block character-for-character from `v01.ex:138–159`. Add a test that greps the emitted body for the exact `RAISE SQLSTATE '45A01'` message and `SET search_path = ''`.

### Pitfall 3: `reference/host_app` pin bump (baseline coupling)
**What goes wrong:** Reading UPG-04 as "make host_app actually run the migration" tempts bumping host_app's `~> 1.0` mailglass pin, which is a coordinated 5-file change (2 mix.exs + 2 mix.lock + `check_clean_baseline_hex_only.sh` + `ci_trust_lane_contract_test.exs`) and drags the whole baseline (memory `project_reference_baseline_coupling`). That is Phase 137's job, not 136.
**Prevention:** UPG-04 is satisfied by the core-suite integration test (seed public → move → assert), plus proving the emitter produces a valid migration for host_app's app module. Do NOT touch host_app pins/locks in Phase 136.

### Pitfall 4: Optional-dep lane pollution (Igniter)
**What goes wrong:** Reaching for Igniter forces a compile guard and risks the `--no-optional-deps --warnings-as-errors` lane. See memory `project_execute_phase_no_optional_deps_pollution`.
**Prevention:** Use plain `Mix.Task` (Decision 1) — no Igniter, no guard.

### Pitfall 5: Timestamp collision / double-generation
**What goes wrong:** Re-running the task emits a second migration with a colliding-or-nearby timestamp, or two move migrations.
**Prevention:** Idempotent wildcard check (`*_move_mailglass_to_schema.exs`) → print `unchanged` and no-op on re-run (mirror `gen.migration`).

### Pitfall 6: citext qualified into `mailglass` by accident
**What goes wrong:** The move migration must NOT touch citext — the extension stays in `public`, only the *tables* move. Qualifying/moving citext breaks case-insensitive resolution (design §1 nuance).
**Prevention:** The generated migration has no `citext` statement at all. The UPG-04 test asserts a mixed-case suppression address still matches lowercase after the move (copy from 134 test:178–199).

### Pitfall 7: `SET LOCAL` outside a transaction is a no-op
**What goes wrong:** If a future edit adds `@disable_ddl_transaction true`, `SET LOCAL lock_timeout` silently stops applying and the DDL can stall behind long readers indefinitely.
**Prevention:** Do NOT disable the DDL transaction (Decision 3). Optionally assert the emitted body contains no `@disable_ddl_transaction`.

### Pitfall 8: docs.check banned tokens in the new guide
**What goes wrong:** If the guide is later added to `@tier1_paths`, any `D-23`/`LINT-04`-style token trips `@banned_patterns`.
**Prevention:** Keep internal IDs out of the adopter guide prose (they don't belong there anyway).

## Open assumptions

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@current_version` remains 5 at the 2.0 cut, so the version-comment after a move must read `'5'` | UPG-04 test | LOW — the test should read `Mailglass.Migrations.Postgres.current_version/0` dynamically rather than hard-code `'5'`, making it version-agnostic. Recommend the planner encode the dynamic read. |
| A2 | `ALTER TABLE … SET SCHEMA` preserves `obj_description` (the table comment) | Verified-fact "version marker" | MEDIUM — this is a documented Postgres behavior (comments are stored in `pg_description` keyed by object OID, which is stable across a namespace move) but I did not execute it live this session. The UPG-04 test asserting the comment survives is the empirical proof; if it FAILS, the generated `up/0` must add an explicit `COMMENT ON TABLE "mailglass".mailglass_events IS '<version>'` after the move. Flag for the planner to include a comment-survival assertion whose failure branch adds the explicit re-COMMENT. |
| A3 | `--apply` flag is desirable for idiom-parity | Decision 1 | LOW — reversible; the task only writes a new file, so the flag is cosmetic. Planner may include or drop. |
| A4 | UPG-04 "against reference/host_app" is satisfiable without a host_app pin bump | Decision 5 / Pitfall 3 | LOW-MEDIUM — if a reviewer insists on a literal host_app end-to-end run (not a core-suite proxy), Phase 137's baseline update would need to precede it; but the milestone build-order puts the baseline bump in 137, and the dossier §5 Phase E scope says "run the codemod against reference/host_app … assert green" which the emitter-for-host_app-app-module + core-suite-migration test satisfies without moving the pin. Escalate only if the planner reads UPG-04 more strictly. |

## Sources

### Primary (HIGH confidence — read in full this session)
- `.planning/research/milestone-schema-isolation/SCHEMA-ISOLATION-DESIGN.md` §4 (locked upgrade design)
- `lib/mix/tasks/mailglass.upgrade.v0_2.ex` (Igniter codemod precedent)
- `lib/mix/tasks/mailglass.gen.migration.ex` (file-emitter precedent — the recommended pattern)
- `lib/mailglass/migrations/postgres/v01.ex` (trigger/function/CHECK byte source), `postgres.ex` (dispatcher + version-comment marker), `v05.ex`
- `lib/mailglass/identifier.ex` (unquoted-identifier chokepoint)
- `lib/mix/tasks/mailglass.publish.check.ex` (`verify_allowlist/1` — the release gate) + `.planning/publish/mailglass-files.expected`
- `lib/mix/tasks/mailglass.docs.check.ex` (`@tier1_paths` + surface rules)
- `mix.exs:397–494` (package files, docs extras/groups)
- `test/mailglass/schema_isolation_immutability_test.exs` (the UPG-04 test template — 45A01/citext/down/no-path-pin)
- `reference/host_app/mix.exs` + baseline migration (empty-of-mailglass-tables proof)
- `config/test.exs`, `config/runtime.exs` (`:schema` pin + CI axis)
- `.planning/STATE.md` (v2.0 intent, Phase 132–135 shipped decisions)

### Secondary (MEDIUM confidence)
- Ecto.Migration transactional-wrapper + `SET LOCAL` semantics (training knowledge, cross-checked against §4 design intent — A2 flagged for live confirmation via the UPG-04 test)

## Metadata

**Confidence breakdown:**
- Task pattern (Decision 1): HIGH — two concrete in-repo precedents; deliverable is a file emitter
- Generated SQL (Decision 2 + verified facts): HIGH — byte-sourced from shipped v01.ex + §4
- lock_timeout posture (Decision 3): HIGH — Ecto transactional-wrapper semantics + §4
- Doc-wiring (Decision 4): HIGH — every gate file read this session; allowlist landmine confirmed
- Test strategy (Decision 5): HIGH — clones an existing shipped test; host_app mechanical reading resolved
- Comment-survival (A2): MEDIUM — documented PG behavior, empirically confirmed by the UPG-04 test at execution

**Research date:** 2026-07-03
**Valid until:** 2026-08-02 (stable — migration/DDL surface and gate machinery are slow-moving; re-check only if `@current_version` bumps or the publish allowlist mechanism changes)
