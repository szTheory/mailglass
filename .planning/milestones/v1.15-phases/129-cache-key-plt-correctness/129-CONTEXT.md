# Phase 129: Cache-key + PLT correctness - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning
**Source:** Decision-of-record synthesis (v1.15 milestone is research-complete) + one maintainer decision (single-source mechanism)

<domain>
## Phase Boundary

Pure CI-infrastructure / DX phase. Two requirements:

- **CACHE-01** — Derive the deps/`_build` cache key OTP+Elixir dims from a **single source**
  (not per-block hardcoded literals), with a per-env prefix. Kill the scattered `1.18`/`27`
  toolchain literals across the workflow cache + setup-beam blocks.
- **CACHE-02** — Give the Dialyzer PLT cache **Bandit-style self-healing eviction** (a
  corrupted/stale PLT is evicted and rebuilt by the workflow). This is the precondition that
  must exist **before** Dialyzer can later be promoted toward the required set (LD-7).

**Decisions of record:** `.planning/research/milestone-cicd/SYNTHESIS.md` (LD-7, LD-9) and the
raw dossier `CICD-RELEASE-HARDENING.md` §1 / §P1-A.

**No product-behavior change.** D-23 convergence holds — infrastructure/DX only, no lib code,
no schema change. This is one `phase/129` branch that must go green in CI (the milestone's
"CI-the-body" dogfooding method).
</domain>

<decisions>
## Implementation Decisions (LOCKED)

### Single-source mechanism — RESOLVED (maintainer, 2026-07-01)
- **A new `.tool-versions` file at the repo root is the single source of truth for the
  canonical toolchain.** LD-9 blessed two mechanisms (`.tool-versions` hash vs per-workflow
  `env:` block); the maintainer chose `.tool-versions`.
- **`setup-beam` reads it via `version-file: .tool-versions`** so the toolchain setup and the
  cache key can never drift (one file drives both). Use the setup-beam `version-file` input
  (resolve the exact `version-type` — `strict` vs the current major.minor `loose` behavior —
  during planning so the resolved OTP/Elixir stays 27 / 1.18 as today; do not silently bump the
  toolchain in this phase).
- **Cache keys hash `.tool-versions` into the key** alongside the lock hash, e.g.
  `mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ hashFiles('**/mix.lock') }}` with
  a matching `restore-keys:` scoped to the same toolchain-hash prefix (never the broad `-mix-`
  restore-key that can pull a `_build`/PLT built under a different toolchain — that broad
  restore-key is the latent-staleness bug §P1-A calls out; scope or drop it).
- A single global file means **no cross-file consistency/grep-police test is needed** (LD-9
  explicitly removes the need for the proposed `ci_cache_key_test.exs`). A toolchain bump is one
  file edit that auto-busts every cache and re-pins `setup-beam` everywhere.
- Bonus: `.tool-versions` also pins local `asdf`/`mise` dev toolchains — the zero-Node
  *adopter-facing* guarantee is untouched (a dev-tooling file, not shipped).

### PLT self-healing (CACHE-02, LD-7) — Bandit pattern
- Keep the PLT cache a **separate** cache block (its own `plt-…` key, toolchain-hash + lock-hash
  scoped) from the deps/`_build` cache.
- Run Dialyzer as **two steps**: (1) `id: dialyzer`, `continue-on-error: true`, run
  `mix dialyzer`; (2) an **evict + rebuild** step gated on
  `if: steps.dialyzer.outcome == 'failure'` that does `rm -rf _build/*/*.plt && mix dialyzer --plt
  && mix dialyzer` so a stale/corrupt PLT self-heals instead of wedging the job. (Resolve the
  exact PLT path — `_build/dev/*.plt` today — during planning.)
- The **final job conclusion must still reflect the real Dialyzer result** after the retry
  (a genuine type error must red the job; only PLT-staleness self-heals). Do NOT leave Dialyzer
  permanently green-regardless.

### Sequencing guard (LD-7) — do NOT promote Dialyzer this phase
- Phase 129 delivers the PLT self-healing **mechanism only**. It must **not** promote Dialyzer
  (or format/credo/compile-warnings) into the required `CI Green` `needs` / branch-protection
  set. That promotion is deliberately deferred (it happens only *after* this eviction lands, and
  is a separate decision). Dialyzer stays advisory / non-required in this phase.
</decisions>

<scope_fence>
## Scope Fences (do NOT do these)

- **Do NOT collapse `advisory-matrix.yml`'s alternative-toolchain rows onto `.tool-versions`.**
  That workflow's *purpose* is to test toolchains that deliberately diverge from the pin, and
  Phase 130 will add a non-blocking latest-Elixir (1.19 / OTP 28) row there. The pinned
  `.tool-versions` describes the **canonical** toolchain only; advisory/alternative rows keep
  their own explicit versions. (Their cache keys should still be toolchain-scoped so alt-rows
  don't collide with the canonical cache — but scoped by *their* matrix values, not
  `.tool-versions`.)
- **Do NOT rename job `name:` display strings** (e.g. `Support Contract Core (Elixir 1.18 / OTP
  27)`). These are branch-protection / gate contract identifiers — `publish-hex.yml` references
  the exact literal names (`:205-208`), and GitHub's `env`/`hashFiles` contexts are unavailable
  in job-level `name:` anyway. The "(Elixir 1.18 / OTP 27)" substring in a job **display name**
  is a contract label, not a cache-correctness toolchain literal, and is out of scope for the
  "no per-block hardcoded literals remain" criterion. If a name string later drifts from the
  pin, that is a separate coordinated branch-protection change.
- **Do NOT promote Dialyzer to required** (see sequencing guard above).
- **Do NOT bump the actual OTP/Elixir versions.** The resolved toolchain stays 27 / 1.18 — this
  phase changes *where the version is declared*, not *which version runs*.
- No product code, no migration, no schema change (D-23 / v1.15 infra-only lock).
</scope_fence>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Decisions of record
- `.planning/research/milestone-cicd/SYNTHESIS.md` — LD-7 (PLT self-healing precedes Dialyzer
  promotion), LD-9 (cache toolchain string from one source).
- `.planning/research/milestone-cicd/CICD-RELEASE-HARDENING.md` §P1-A (`:137-188`) — the concrete
  cache-key + PLT-eviction YAML the dossier proposes (adapt the hardcoded `otp27-ex1.18` literal
  to the chosen `.tool-versions` hash).

### Files this phase changes
- `.github/workflows/ci.yml` — ~18 `actions/cache` + ~18 `setup-beam` blocks; the `dialyzer`
  job (`:466-524`) carries the PLT cache (`:510-516`) + Dialyzer run (`:523-524`).
- `.github/workflows/publish-hex.yml` — 4 cache / 4 setup-beam blocks (publish jobs want an
  exact key with **no** restore-keys per §P1-A — a partial restore under a stale toolchain is
  worse than a cold fetch).
- `.github/workflows/post-publish-smoke.yml`, `.github/workflows/repo-hygiene.yml`,
  `.github/workflows/provider-live.yml` — canonical-toolchain cache/setup-beam blocks.
- `.github/workflows/advisory-matrix.yml` — **exempt** alt-toolchain rows (see scope fence).
- `.tool-versions` — **new** file at repo root.

### Repo precedents to match
- Phase 128 shared-source + fail-loud drift-test pattern: `test/support/ci_lanes.ex`
  (`Mailglass.CILanes`), `test/scripts/ci_parity_drift_test.exs`,
  `test/scripts/required_checks_test.exs` — the house style for CI-config coherence tests, if a
  verification test is warranted (note: with a single `.tool-versions` file, a cross-file drift
  test is NOT needed — LD-9).
- SHA-pinned third-party Actions (CLAUDE.md commit conventions) — keep every `actions/*` /
  `erlef/setup-beam` pin unchanged; only edit `with:`/`key:` bodies.
</canonical_refs>

<specifics>
## Specific Ideas

- **Verification (self-verify, shift-left):** the two success criteria are CI-observable —
  (1) cache keys in the Actions logs carry OTP+Elixir dims from one source; (2) a corrupted PLT
  is evicted and rebuilt. Prove (1) by `phase/129` CI logs showing the new key shape; prove (2)
  by an intentional PLT-corruption run (or a documented, reproducible local proof) showing the
  eviction step recovers. Prefer an automatable/greppable assertion over a manual-only check
  where possible, but do not add the grep-police test LD-9 retired.
- Per-env prefix: keep the `mix-` / `plt-` prefixes distinct so deps-cache and PLT-cache never
  collide; include `${{ runner.os }}` and (for the deps cache) the MIX_ENV-or-`dev` prefix per
  §P1-A so test-env and dev-env `_build` don't cross-pollute.
- Success criterion #3 ("no per-block hardcoded toolchain literals remain") is scoped to
  **cache keys + setup-beam version inputs + strategy.matrix toolchain entries** on the
  canonical lanes — NOT job display-name strings (contract labels) and NOT advisory-matrix
  alt-rows (see scope fences).
</specifics>

<deferred>
## Deferred Ideas

- **Dialyzer promotion to required** — deferred to a later decision (must land *after* this
  eviction; LD-7). Not this phase.
- **Latest-Elixir 1.19 / OTP 28 advisory row** — Phase 130 (SUPPLY-05); it lands in
  advisory-matrix.yml and depends on the cache being toolchain-scoped first.
</deferred>

---

*Phase: 129-cache-key-plt-correctness*
*Context synthesized 2026-07-01 from v1.15 decisions-of-record + one maintainer fork resolution*
