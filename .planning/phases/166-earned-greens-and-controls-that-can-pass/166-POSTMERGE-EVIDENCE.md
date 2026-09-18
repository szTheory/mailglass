# Phase 166 — post-merge evidence harvest

Harvested 2026-09-18 from the first CI run on protected `main` after the v2.8 merge.

- Merge commit: `dcbda58f62a3c324d97f1e44998f40721cb55d40` (PR #281, squash)
- `CI` run: **35361151376** — conclusion `success`
- `Advisory Matrix` run: 35361151275 — conclusion `success`

This file is a raw evidence capture for `/gsd-verify-work 166`. It records what was
*observed*, including one item that is only partially satisfiable today. It does not
mark any requirement complete.

---

## CTRL-01 — SATISFIED

Live `workflow_dispatch` of `post-publish-smoke.yml` with `mode=baseline`, run **35364627465**,
all 9 jobs green. Artifact `post-publish-resolution-35364627465` downloaded and inspected
(not inferred from the job's green status):

```json
{
  "status": "pass",
  "reason": "exact_target_verified",
  "event_name": "workflow_dispatch",
  "run_id": "35364627465",
  "lifecycle": "inactive",
  "ledger_status": "inactive",
  "publication_status": "published",
  "target_ref": "6a0447a900e26b2b07332ac50682767801ddcda7",
  "core": "2.6.0",
  "admin": "2.6.0",
  "inbound": "2.3.0",
  "evidence_schema": "mailglass.scheduled-control/v1",
  "control": "post-publish-smoke",
  "workflow_sha": "dcbda58f62a3c324d97f1e44998f40721cb55d40",
  "head_sha": "dcbda58f62a3c324d97f1e44998f40721cb55d40"
}
```

Every acceptance field matches: exit 0, artifact present, `status: pass`,
`reason: exact_target_verified`, versions `2.6.0/2.6.0/2.3.0`, `target_ref 6a0447a9…`.
`lifecycle: inactive` is the load-bearing part — it proves the control resolved from the
ledger's `baselines` + `historical_tag_sha`, i.e. **it can pass between releases**.
Milestone exit criterion 3.

Dispatch form (GitHub requires all four version inputs non-empty even though baseline mode
does not consult them; omitting them fails `HTTP 422: Required input 'core_version' not provided`):

```
gh workflow run post-publish-smoke.yml --ref main -f mode=baseline \
  -f core_version=2.6.0 -f admin_version=2.6.0 -f inbound_version=2.3.0 \
  -f target_ref=6a0447a900e26b2b07332ac50682767801ddcda7
```

---

## GREEN-04 — SATISFIED

The CI runner itself resolved the demo app's deps from **Hex**, not path deps. Observed in
`Support Contract Core (Elixir 1.18 / OTP 27)`, run 35361151376:

```
15:16:11  rm -rf /tmp/mailglass_demo_hex_proof
15:16:11  rsync -a --exclude 'demo_app/deps' --exclude 'demo_app/_build' \
            --exclude 'host_app' reference/ /tmp/mailglass_demo_hex_proof/
15:16:11  MAILGLASS_DEMO_DEPS: hex
15:16:13  Resolving Hex dependencies...
15:16:13    mailglass 2.6.0
15:16:13    mailglass_admin 2.6.0
15:16:13    mailglass_inbound 2.3.0
15:16:13  * Getting mailglass (Hex package)
15:16:13  * Getting mailglass_admin (Hex package)
15:16:13  * Getting mailglass_inbound (Hex package)
```

`* Getting … (Hex package)` is the decisive line — a path dep never emits it. The resolved
versions match the published 2.6.0/2.6.0/2.3.0 line, and the rsync scratch copy excluded
`demo_app/deps` and `demo_app/_build`, so nothing could have been served from a pre-existing
local build.

---

## GREEN-05 Part 2 — PARTIAL. Do not mark complete from this run alone.

**Observed (full, untruncated cache keys):**

```
mix-trust-clean-baseline-Linux-1ae76eec8d8b2500891e59c4bfa89c78cda3b62f03b79783e75316109bfb8dbd-test-f6571b555d46a2d1910b12cfbe0427ff6ffd5b3923ba2b3a3327c76f46fed402
mix-trust-repo-head-Linux-1ae76eec8d8b2500891e59c4bfa89c78cda3b62f03b79783e75316109bfb8dbd-test-f6571b555d46a2d1910b12cfbe0427ff6ffd5b3923ba2b3a3327c76f46fed402
```

The two keys are **byte-identical after the lane prefix**. The entire distinguishing power
comes from `mix-trust-clean-baseline-` vs `mix-trust-repo-head-`. Because `restore-keys` is
prefixed the same way, a lookup in one lane cannot fall back onto the other lane's entry —
key-space isolation holds, confirming Part 1's written claim.

Restore/save lines, run 35361151376:

```
Trust Lane Repo Head       15:14:49  key: mix-trust-repo-head-Linux-…-test-f6571b55…
Trust Lane Repo Head       15:14:49  restore-keys: mix-trust-repo-head-Linux-…
Trust Lane Repo Head       15:14:50  Cache not found for input keys: mix-trust-repo-head-Linux-…
Trust Lane Repo Head       15:18:01  Cache saved with key: mix-trust-repo-head-Linux-…

Trust Lane Clean Baseline  15:14:48  key: mix-trust-clean-baseline-Linux-…-test-f6571b55…
Trust Lane Clean Baseline  15:14:48  restore-keys: mix-trust-clean-baseline-Linux-…
Trust Lane Clean Baseline  15:14:48  Cache not found for input keys: mix-trust-clean-baseline-Linux-…
Trust Lane Clean Baseline  15:17:48  Cache saved with key: mix-trust-clean-baseline-Linux-…
```

**Why this is only partial.** `grep -cE "Cache restored from key: mix-trust" → 0`. Both lanes
were a cold **miss → save**. Part 2 asks for observed **restore** log lines, and a restore-hit
cannot occur until a *second* CI run on `main` with an unchanged `mix.lock` reuses these keys.
Only one CI run exists on `main` (`dcbda58f`, 2026-09-18T15:14:01Z).

Note this was **not** a globally cold run — the same run logged **21** `Cache restored from key`
hits in other lanes (`Compile No Optional Deps`, `Compile Warnings as Errors`,
`Core Deterministic Suite`, `Credo Strict`, `Deps Audit`, `Dialyzer` (both `mix-` and `plt-`),
`Docs Warnings as Errors`, `Format Check`, `Hex Audit`, `Inbound Compile No Optional Deps`,
`Inbound Dialyzer`, …), all off the shared `mix-Linux-1ae76eec…` key space or their own
lane-specific ones. The trust lanes alone missed. That is corroborating evidence for isolation:
the two trust key spaces were not reachable from the general `mix-Linux-…` cache that a dozen
other jobs restored from in the same run. It is still not a restore-hit observation, which is
what Part 2 asks for.

A miss-then-save pair demonstrates the key-space is distinct; it does **not** demonstrate that a
warm restore stays inside its own lane. Recording the difference rather than writing the weaker
observation up as though it were the stronger one — that distinction is the whole point of this
milestone.

**To finish Part 2:** trigger one more CI run on `main` with `mix.lock` unchanged, then capture
the `Cache restored from key: mix-trust-…` lines from both trust lanes and confirm each names its
own prefix.

---

## Not harvestable here

**CTRL-02 / CTRL-03** remain blocked on release proposal **PR #280**, which is open and targets
`2.6.0/2.6.0/2.3.0` — versions already tagged and live. Preflight short-circuits on
`All expected release tags already exist`, skipping the release-please action *and* the
discovery/capture steps, so the proposal-only control falls through to its default
`cannot-check` / `github_evidence_unavailable` and fails every push to `main`.

Reproduced on a rerun of run 35361151297 with `gh api rate_limit` at 5000/5000 — this is **not**
the secondary rate limit that caused earlier release-please reds.

CTRL-02's acceptance ("merge of a `chore: release main` PR produces a green push run") cannot be
observed until #280 is closed or retargeted and a fresh proposal is merged. That is a release-
ceremony decision, deliberately left to a human.
