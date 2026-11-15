# Phase 182 deferred items

Out-of-scope discoveries logged by plan executors. Nothing here was fixed by the plan that found it.

## 182-01

### Phase164RepositoryTruthTest fails in a checkout that has a local `.gsd/.gitignore`

- **Test:** `test/scripts/phase_164_repository_truth_test.exs`, "git runtime rules do not conceal the retired finalize-phase extension paths" (`refute ignored?(".gsd/extensions/finalize-phase/index.ts")`).
- **Seen in:** `mix test test/mailglass/operator test/scripts test/mailglass/docs_contract_test.exs --seed 0` (752 tests, 1 failure) on the executor's working tree at 2026-11-15.
- **Cause:** an untracked local file `.gsd/.gitignore` (contents `*`, mtime 2026-10-07) makes `git check-ignore` report the finalize-phase path as ignored. `git check-ignore -v` names `.gsd/.gitignore:1:*`.
- **Not caused by 182-01:** in a fresh `git clone --local` of this repository checked out at the plan's last commit (`92e18c3c`), all five assertions of that test hold (`.gsd/gsd.db`, `.gsd/exec/probe` and `.gsd/extensions/other/index.ts` are ignored; `.gsd/extensions/finalize-phase/index.ts` is not). Plan 182-01 changed no `.gitignore` and no file under `.gsd/`.
- **Disposition:** environment-specific to this working tree. The owner can remove or narrow the local `.gsd/.gitignore` if the test should pass here; it was not touched.
