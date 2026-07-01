# v1.15 CI/CD Milestone — Synthesis & Locked Decisions

> **What this is.** The decision-of-record for the v1.15 Release-Pipeline Efficiency & Contributor
> DX milestone. It sits ON TOP of the two decision-ready dossiers (`CICD-RELEASE-HARDENING.md`,
> `DX-MIX-CI.md`) and records the **corrections + refinements** produced by a 3-agent adversarial
> verification pass (release-eng/SRE, DX/contributor, live-repo fact-check) run 2026-07-01. Where
> this file disagrees with the raw dossiers, **this file wins** — the dossiers were written at
> `1.10.1/1.5.3` and have version/line drift plus a few under-weighted decisions.
>
> **Author:** milestone-open synthesis, 2026-07-01. **Live versions:** `mailglass` 1.10.2 /
> `mailglass_admin` 1.10.2 / `mailglass_inbound` 1.5.4.

---

## 0. Ground-truth corrections (dossiers are stale here)

- **Versions/pins:** live is `1.10.2 / 1.10.2 / 1.5.4`; both `mailglass_admin/mix.exs:156` and
  `mailglass_inbound/mix.exs:139` carry `{:mailglass, "== 1.10.2"}`. Re-anchor all §6 "before"
  examples to `1.10.2 → 1.10.3`. The "1.10.2/1.5.4 ceremony just ran" prediction is now history —
  the dated trap comment at `mailglass_inbound/mix.exs:114–136` narrates the exact transient-red
  window it caused.
- **Line refs that moved (still valid, just re-cite):** `stability_contract_test.exs:154–159` (+ the
  regex at :105) for the exact-`==` assertion; `publish.check.ex:60–63` for `@accepted_advisories`;
  `publish.check.ex:778,827` for the `== root_version` matches (`verify_deps/1` at :736,
  `verify_linked_constraint/1` at :805).
- **linked-versions group is `[mailglass, mailglass_admin]` only** (`release-please-config.json`) —
  **`mailglass_inbound` is NOT linked**. Admin's `~>` safety rests on the plugin (its minor is
  release-time-locked to core); inbound's `~>` safety rests on a human choosing the floor. Reason
  about them separately — do not fold into one bullet as the dossier does.
- **PR #104 is OPEN** (`chore/mix-ci-local-parity`, 2 files) and implements only the DX slice:
  root `ci`/`ci.fast`/`ci.setup`/`ci.browser` aliases + `preferred_envs` + the CONTRIBUTING fix.
  Its shipped `mix ci` is **missing Installer Host Smoke + trust-lane** → it is *not yet the
  mergeable surface* (re-creates the parity-lie the milestone exists to kill). It also deliberately
  dropped `deps.unlock --check-unused` (orphaned transitive entries: `castore`, `unicode_util_compat`).
  Everything in `CICD-RELEASE-HARDENING.md` is still un-started; its premises hold.

---

## 1. Locked decisions (maintainer-approved 2026-07-01)

**LD-1 — Cut a real Hex release at close.** The `~>` pins and `mix ci` aliases only benefit adopters
once published; a real ceremony is the best end-to-end test of the hardened pipeline. Core+admin
linked; inbound ships a **minor** bump (the dependency-policy change is feat-level, not a patch).

**LD-2 — Inbound pin = `{:mailglass, "~> 1.10 and >= 1.10.2"}`; admin = `{:mailglass, "~> 1.10"}`.**
Bare `~> 1.10` admits `1.10.0/1.10.1` — the *broken-deliveries-migration* core versions. Floor
inbound at the V05 fix (mirrors Ash's own `~> 3.5 and >= 3.5.13` precedent the dossier cites but
didn't pick). Admin bare `~> 1.10` is safe because the linked plugin never resolves admin against a
core it didn't ship with. `~> 1.10` correctly REFUSES core `1.11.0` for inbound — desired, because a
new core **minor** is exactly where internal contracts (`Mailglass.Outbound.*`, events table, Error
hierarchy) may shift; each minor floor-bump is a deliberate `fix(inbound):` asserting "verified
against core 1.11." Do NOT speculatively widen inbound to `~> 1.10 or ~> 1.11`.

**LD-3 — The pin change is ATOMIC, not "independent/first".** One indivisible change = `~>` pins
(×2) + relaxed `stability_contract_test` (:105, :154–159) + `publish.check` `verify_deps` /
`verify_linked_constraint` (accept any `~>` that `Version.match?`-es core; reject `==`) + **delete
the two `== X.Y.Z` sed rewrites from `release-please.yml`**. Splitting any part off reds main or
miscuts the next release (the sed anchor would match zero `==` lines). Verify §6(a)–(d) BEFORE merge.

**LD-4 — `mix_audit` + OSV-staleness are advisory-on-PR, blocking-only-at-release.** Required-blocking
on every PR would, under a v1.14-style advisory wave (unfixable transitive CVE, no patch), red every
open PR across all three packages until a maintainer allowlists — a self-inflicted outage for a
quiet-maintenance lib. Add `mix deps.audit` **advisory (non-blocking) on PR**; block only in the
publish gate (`publish.check`, which already owns the allowlist lifecycle). The cowlib OSV-staleness
check is a **loud CI warning on every run** (so it's noticed before the ceremony) + a **hard block at
publish**; **fail-OPEN on OSV API outage** (a third-party blip must never block a security *patch*).

**LD-5 — Pin change ships with a CHANGELOG line + documented Hex-retirement rollback.** `==`→`~>` is a
published constraint change to every downstream adopter; it changes the resolver's degrees of freedom
(an adopter who also directly depends on core no longer gets forced-consistent resolution). With
`==`, a bad core patch could never silently reach an inbound adopter; with `~>` it auto-resolves in.
The new rollback lever is **`mix hex.retire mailglass X.Y.Z`** — document it as the replacement for
the `==` wall. CHANGELOG: "mailglass_inbound now depends on `mailglass ~> 1.10 and >= 1.10.2` instead
of an exact pin; you may upgrade core patch releases without waiting for a paired inbound release."

**LD-6 — `CI Green` fan-in gate, but `skipped ≠ success` on the release/publish path.** The aggregate
job's "skipped is OK" rule (so docs-only path-filtered PRs don't false-fail) is a genuine hole on the
**release SHA** — release commits touch many paths, `docs(state):` skips CI entirely, and a required
lane that path-skips would be blessed green. For the publish path, a required lane must be `success`,
not merely not-`failure` (the `gate-ci-green` publish gate re-asserts the lane actually executed).
The coverage meta-test asserts **set-equality** between `setup_branch_protection.sh` `REQUIRED_CHECKS`,
`ci-green.needs`, and the actual job set — **not** superset — plus that no lane is permanently
`if:`-disabled (an always-skipped lane "passes" vacuously). Also verify `guard-release-trigger`
(the 2nd required context) always reports, or it re-introduces green-but-BLOCKED.

**LD-7 — Do NOT promote Dialyzer (or format/credo/compile-warnings) to required until the PLT
self-healing eviction lands.** Folding Dialyzer into `ci-green.needs` before the cache/PLT fix
(dossier §1) means PLT-staleness flakes block merges. Sequence: cache+PLT correctness FIRST, then
promote. Note the §7 "PR required" list silently promotes several advisory lanes to blocking — do it
deliberately and only after the flake-source is fixed.

**LD-8 — `--seed 0` is DELETED, not carried.** The two dossiers contradict: §3 removes it (root-cause
fix); `DX-MIX-CI.md:173,251` keeps it in the `mix ci` alias. **§3 wins** — seed-pinning masks, never
fixes. The inbound determinism fix (Option B: default `async: false` in `MailboxCase`, drop
`shared:`, plain ownership checkout) must land **before/atomic-with** the `mix ci` inbound step, and
the alias then uses plain `mix test --exclude property` (no seed). Keep the Oban
`|| mix test --failed` retry idiom only as a **time-boxed transition net with a removal date** — a
permanent retry re-introduces flake-masking on a suite you just made deterministic-by-construction.
Accept that full-serial trades away concurrency-regression signal; revisit Option A (`Sandbox.allow/3`)
only if inbound grows concurrent paths.

**LD-9 — Cache toolchain string derives from ONE source, not 15 hardcoded literals.** Hardcoding
`otp27-ex1.18` across ~15 cache blocks is the same latent-staleness class as the `gate-self-test`
stale default and the sed anchors. Derive it: either hash `.tool-versions` into the key (Livebook
pattern; auto-busts on bump, one-file edit propagates to `setup-beam` too) or a single top-of-workflow
`env:` block (`ELIXIR_V`/`OTP_V`) if human-readable cache logs matter. Removes the need for the
proposed `ci_cache_key_test.exs` grep-police.

**LD-10 — `mix ci` must equal the mergeable surface before the CONTRIBUTING claim lands.** Add
Installer Host Smoke + trust-lane to the alias; only then land the CONTRIBUTING "mirrors every
required merge gate" copy. The parity-drift backstop is **manifest-membership**, not YAML-superset:
one `ci_lanes` source of truth (shared with LD-6's coverage meta-test) mapping `{lane_name,
mix_command_with_flags}`; assert the alias covers every entry (lane identity + flag-set), and that
each required `ci.yml` job cites a manifest lane. A substring superset check passes vacuously on flag
drift (`--exclude flaky` vs `--include slow`) and breaks on YAML reformat → gets `@tag :skip`'d.

**LD-11 — Add `actionlint` (+ dependency-review) on workflow PRs.** The project's own research
(`prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`) names these "highest-leverage," and
this milestone churns workflows heavily (new aggregate job, sed reduction, ~15 cache rewrites) with
zero YAML linting. `actionlint` + the coverage meta-test are the belt-and-suspenders against the
plan's central footgun (a lane silently missing from `needs`; sed anchor drift).

**LD-12 — least-surprise DX guards.** `mix ci`/`ci.setup` preflight-probes Postgres (and the
installer step probes `phx.new` network) and prints a **brand-voice, actionable** message on absence
("Delivery blocked: PostgreSQL is not reachable on localhost:5432. Start it, or set POSTGRES_HOST.
See CONTRIBUTING.md 'Local Setup'.") — never a raw `DBConnection.ConnectionError`. Designate `verify.*`
as **internal composition targets** and `ci.*` as the **public contributor verb**; finish deleting the
deprecated `verify.phase_NN` pass-throughs (else CONTRIBUTING's old `verify.phase_07` pointer 404s).

**LD-13 — matrix floor-coincidence invariant.** Declining a min-supported floor row is correct TODAY
(required pin == declared floor == 1.18; REL-06 precedent). Add a written invariant: **whenever the
required pin advances past 1.18, either add a 1.18 floor row to the required lane or raise the
declared `elixir:` floor** — never let the tested version outrun the declared `~> 1.18`.

---

## 2. Corrected adoption sequence (supersedes dossier §7)

1. **Sibling-pin loosening (atomic — LD-2/3/5).** Pin + contract test + publish.check + sed deletion +
   CHANGELOG + retirement doc. One change. Unblocks every future release. → **Phase 125**
2. **CI Green fan-in gate + branch-protection collapse (LD-6) + `gate-self-test` default fix.** → **Phase 126**
3. **Inbound determinism (LD-8) — delete `--seed 0`.** Precondition for the `mix ci` inbound step. → **Phase 127**
4. **`mix ci` parity completion (LD-10/12) — folds in PR #104.** → **Phase 128**
5. **Cache-key + PLT correctness (LD-9).** Precondition for Dialyzer-as-required + the advisory row. → **Phase 129**
6. **Supply chain + workflow hygiene (LD-4/11) + latest-Elixir advisory row (LD-13).** → **Phase 130**
7. **Release cut + closeout (LD-1).** Real linked release; consumer + post-publish smoke; audit + archive. → **Phase 131**

**Cross-cutting method:** dogfood the v1.14-post-mortem backlog fix — every phase pushes a `phase/NN`
branch and requires green CI, so the release ceremony is a confirmation, not a discovery.

---

## 3. Provenance

- Raw dossiers: `CICD-RELEASE-HARDENING.md` (release-eng research, 2026-06-30), `DX-MIX-CI.md`
  (DX research, 2026-07-01) — both decision-ready, both version/line-stale, both individually correct
  but mutually inconsistent on `--seed 0` (resolved by LD-8).
- Adversarial pass (2026-07-01): 3 parallel agents — live-repo fact-check (drift + PR #104 state),
  release-eng/SRE adversarial review (DP1–DP5 + missed items), DX/contributor review (DX1–DX6 +
  missed items). Cross-checked against `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
  and `prompts/mailglass-engineering-dna-from-prior-libs.md`. All 19 refinements folded into LD-1..13.
