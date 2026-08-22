# mailglass

> *Mail you can see through.*

## What This Is

**mailglass** is a batteries-included transactional email framework for Phoenix — the layer that sits on top of [Swoosh](https://hex.pm/packages/swoosh) and ships everything Swoosh deliberately doesn't: HEEx-native components, a LiveView preview/admin dashboard, normalized webhook events, signed unsubscribe tokens with RFC 8058 List-Unsubscribe headers, message-stream separation, suppression lists, an append-only event ledger, multi-tenant routing, and `mix mail.doctor` deliverability checks. It's for senior Phoenix teams shipping production transactional email (welcome flows, password resets, magic links, receipts, notifications) who today rebuild 40% of ActionMailer + Anymail + ActionMailbox by hand on every project.

It is shipped as three sibling Hex packages: `mailglass` (core), `mailglass_admin` (mountable LiveView dashboard), and `mailglass_inbound` (Action Mailbox equivalent — post-`v1.0`).

## Current State

**v2.7 Repository Stewardship & Operational Hygiene opened 2026-08-21.** This is a bounded maintenance
milestone: restore quiet, trustworthy repository operations; disposition release and workspace residue;
and make documentation and tracked artifacts tell the truth. It does not expand the product, redesign
architecture, overhaul CI for speed, or force a Hex release without an adopter-facing correction.

**v2.6 Engineering Quality Ratchet shipped and passed its milestone audit 2026-08-21.** The milestone restored
generated-host migration truth, bounded execution and data/security correctness, tightened architecture,
and made merge and release signals fail closed. The canonical `mix ci` path passed 1,914 tests, 23
properties, and all 20 generated-host stages after its final deterministic-parity repair. The
admin/operator UI remained explicitly untouched. No next feature milestone is currently committed.

**Phase 155 completed and verified 2026-08-16.** Core and inbound now generate real fresh and
rollback-aware upgrade wrappers for an explicit host Repo, distinguish absent migration anchors from
catalog failures, and provide a byte-exact fail-closed legacy-toy repair. Two fresh generated Phoenix/Ecto
hosts proved both shared-schema rollback orders, and protected `CI Green` now fails if change detection or
required code proof is skipped. Verification passed 5/5 after closing the shared-schema rollback gap and a
deep review's three destructive/fail-open findings.

**Phase 156 completed and verified 2026-08-17.** Core and inbound rate limiting now has exact bounded
admission and restart-safe lifecycle behavior; durable batches commit delivery projections, events,
private payloads, and Oban jobs atomically; local fallback execution is bounded and reports saturation;
and retry, error privacy, telemetry, and persisted closed-set decoding are explicit. The full root CI gate,
a cold generated Phoenix/Ecto/Postgres adopter installation, and both generated-host migration orders are
green. Independent verification passed 5/5 and deep review closed with no findings.

**Phase 160 completed and verified 2026-08-20.** A production-shaped generated host and protected
publication certified the additive package family. `mailglass` 2.5.0, `mailglass_admin` 2.5.0, and
`mailglass_inbound` 2.2.0 are public on Hex from one immutable tag, and an exact-Hex adopter host passed
the generated-host and trust-runner journeys. Verification passed 4/4; the code review was clean, all 18
planned threats were closed, and all 13 phase tasks have automated or immutable evidence.

**v2.5 B2C Alpha Adoption Certification completed 2026-08-04.** The published `mailglass` 2.4.1,
`mailglass_admin` 2.4.1, and `mailglass_inbound` 2.1.2 package family passed its then-current package-shaped
proof. The v2.6 audit supersedes the claim that no library defect remains: the migration generator and
upgrade path were not exercised by a real Ecto host, and several deterministic quality lanes were not
merge-gating.

**v2.4 Outbound First-Adopter Correctness shipped 2026-08-04.** Mailglass now proves the documented
single-recipient sync/async journey from a generated production-shaped Phoenix/Postgres host. Durable
delivery persists a complete private envelope atomically with its canonical Oban job, classifies provider
outcomes honestly, bounds payload retention, and converges RFC 8058 one-click suppression before later
matching sends.

`mailglass` 2.4.1, `mailglass_admin` 2.4.1, and `mailglass_inbound` 2.1.2 are live on Hex. The immutable
`mailglass-v2.4.1` candidate passed protected publication, an exact-Hex generated-host journey, the
published reference-host trust journey, HexDocs checks, and unretracted-package verification. The v2.4
audit passed 35/35 requirements, 12/12 cross-phase seams, and 6/6 end-to-end flows.

Package boundaries are locked. Chimeway owns notification policy and preferences; Sigra owns auth token
semantics; Accrue owns billing and dunning; Cairnloop owns support state; Parapet owns dashboards and
paging; Crosswake owns mobile route activation. No `crosswake_mailglass` package is planned.

## Current Milestone: v2.7 Repository Stewardship & Operational Hygiene

**Goal:** Leave Mailglass in a clean, quiet, trustworthy maintenance posture after v2.6 without product
expansion or speculative refactoring.

**Target features:**
- Establish one canonical `main` workspace and safely disposition temporary worktrees, stashes, divergent
  branches, and release leftovers after auditing each for unique work.
- Recover scheduled release-please, repository-hygiene, and post-publish automation while preserving the
  already-green protected main CI path.
- Triage the blocked release PR and related stale branches/checks to explicit, evidence-backed outcomes.
- Repair the observed database property-test timeout and browser-gallery timeout only where they affect the
  release path; do not broaden this into a CI-performance or test-architecture redesign.
- Reconcile versions, release state, maintenance guidance, tracked/generated artifacts, ignore rules, and
  repository organization; remove only demonstrable junk or stale claims.
- Close with a clean working state, accurate docs, no unexplained red automation, and an explicit disposition
  for every audited item.

## Active Requirements: v2.7

The 16 committed v2.7 requirements in `.planning/REQUIREMENTS.md` cover workspace integrity, automation and
release truth, deterministic release-path gates, and repository truth/closeout. The milestone is constrained
to recoverability-first, low-controversy maintenance. Product/API/schema/UI expansion, dependency churn,
speculative architecture, cosmetic busywork, a CI-efficiency overhaul, and a release performed only for
ceremony are out of scope.

## Completed Milestone: v2.6 Engineering Quality Ratchet

**Goal:** Raise the internal engineering bar substantially while proving the generated first-adopter path,
runtime correctness, data safety, architecture boundaries, and merge/release signals are honest.

**Delivered features:**
- Correct initial, upgrade, rollback, multi-repo, and legacy-remediation migration generation.
- Bounded and honest delivery/inbound execution, retry classification, data access, and resource use.
- Zero compile cycles, explicit runtime/boundary ownership, deterministic tests, and fail-closed CI.
- Generated-host certification and additive-only package release without admin/operator UI changes.

## Validated Requirements: v2.6

All 50 v2.6 requirements in `.planning/milestones/v2.6-REQUIREMENTS.md` are validated across Phases 155-160:
adopter/CI truth; delivery correctness; inbound/data hardening; architecture simplification; engineering
gates; and certification/release. Phase 160 validated REL-01 through REL-04 and completed the protected
three-package release.

Default posture remains convergence and adopter-pull: do not absorb notification policy,
authentication, billing, support, mobile activation, or SRE ownership into Mailglass. The external
Sigra, Chimeway, Parapet, Accrue, and host recovery gates remain production-adoption work owned by
those systems, not unfinished Mailglass requirements. Admin visual polish, native HEEx assigns,
provider breadth, ecosystem integrations, and sent-snapshot viewing are explicitly deferred.

<details>
<summary>Archived v2.2 milestone context</summary>

## Archived: v2.2 CI Signal Integrity & Supply-Chain Hygiene (SHIPPED 2026-07-31)

**Opened 2026-07-28.** Maintenance and trust-restoration only — explicitly not product expansion, not a
redesign, not a release-cut milestone, and not a CI topology rewrite. The lane structure is sound; the
signals were not.

**Goal:** Make every green check mean what it says, and close the supply-chain gap that let four HIGH-severity
advisories sit unpatched.

**Why now.** On 2026-07-28 a single character-class typo in branch protection was found to have silently
held the repository for 24 days: live protection required the status context `guard-release-trigger` (the
job **id**) while the workflow reports `Guard Release Trigger` (the job **display name**). GitHub matches
on the reported name, so the required context was never reported by anything and every PR sat permanently
`BLOCKED`. Consequences, none visible from the repo's own green checks: 22 PRs blocked including a release
PR with auto-merge enabled since 2026-07-04; four HIGH CVEs unpatched because the dependabot PRs carrying
the fixes could not merge; and `branch-protection-drift.yml` reporting SUCCESS the entire time, because it
guards its own comparison behind `if: pat_present == 'true'` and so skips the check while still posting
green. The unifying defect is that several signals were not telling the truth, and the check built to catch
exactly this was itself blind.

**Already delivered 2026-07-28 — released as 2.1.3 / 2.1.3 / 2.1.1. Do NOT re-plan:**
- Branch protection corrected to `{CI Green, Guard Release Trigger}` via the repo's own
  `scripts/setup_branch_protection.sh`; zero drift against `--print-expected-json`.
- Nine advisories patched, four HIGH: phoenix, hpax, plug, postgrex, swoosh (PR #134) and cowboy, cowlib
  (PR #139). `hpax` was transitive — **dependabot never files those**, which is why it accumulated.
- All 7 admin design-system conformance gates green (PR #136), including two heroicons (`hero-check`,
  `hero-information-circle`) rendering invisible with nothing catching it.
- Dialyzer clean — `Operator.Deliveries.list_providers/2` (PR #136).
- Stale `mailglass_admin` publish allowlist fixed (PR #134) — the actual cause of the 2.1.0 publish failure.
- Citext probe made honest (PR #137) — it rescued every `Postgrex.Error`, retried, and reported "citext
  probe exhausted" for unrelated faults; now only the poisoned-OID surface retries.
- `migration_test.exs` baseline restoration fixed (PR #137) — restoration was gated on a recorded migration
  version, so a dropped-but-still-recorded schema skipped restore entirely.

**Target features (remaining scope, phases 141-144):**
- **Supply-chain remediation (VULN)** — disposition the dependabot backlog left with auto-merge enabled;
  promote the audit lane from advisory to gating so a new HIGH blocks merge instead of accumulating —
  **wiring allowlist logic into the CI-side lane first**, since `ci.yml`'s `hex_audit` runs bare
  `mix hex.audit` with no allowlist and would red-block every PR on the already-accepted cowlib advisories;
  a documented triage cadence that covers **transitive** dependencies (Dependabot cannot auto-PR a Hex
  transitive fix that needs a parent bump — this is documented behavior, not a bug, and `mix_audit` already
  detects them).
- **Test-harness truth (HARNESS)** — fix the Ecto Sandbox ownership leak (194 of 242 core-suite failures are
  `{:badmatch, :already_shared}` from `Sandbox.start_owner!/2`); Core Full Suite green across all four
  matrix legs; confirm recovered tests genuinely execute and assert rather than being skipped or tagged away
  to manufacture green; decide whether Core Full Suite should become release-gating. Full evidence,
  call-site map, and ruled-out list in `SEED-007`.
- **Design-system conformance (CONFORM)** — **verify**, don't rebuild, the icon-existence gate: research
  found `ICON-EXISTS-GATE` already ships at `check-conformance.sh:148-179` from PR #136, so the remaining
  work is confirming it covers the dynamic call sites (`name={@icon}`, `name={stat_severity_icon(...)}`) a
  literal grep cannot see. Rename the lane called "Credo Strict" that actually dies in
  `mailglass_admin/scripts/check-conformance.sh` — the misleading name is why nobody looked at it for weeks.
  **The rename is coupled to TRUTH-07/09 and must land with them**: `gate-ci-green` matches lanes by name.
- **Lane truth & drift-proofing (TRUTH)** — a skipped drift check must report neutral or failure, never
  green (this shape appears **twice**: `branch-protection-drift.yml`'s `reassert-protection` and `ci.yml`'s
  "Branch Protection Advisory"); verify live protection against `--print-expected-json` on a schedule with a
  regression guard; fix or formally accept the release-trigger anti-recursion gap (bot-auto-merged release
  PRs do not fire release-please's `push` trigger, so tagging waits on an hourly cron — this cost ~30
  minutes three separate times on 2026-07-28); every advisory lane gets a recorded disposition;
  `repo-hygiene` must distinguish "genuinely blocked" from "cannot check"; reconcile the **three**
  definitions of "advisory" (`ci_lanes.ex` lists ten, `gate-ci-green` hardcodes two plus a regex, and
  `MAINTAINING.md:152-191` lists eleven — that file **does** exist and is cited accurately; it is stale,
  not phantom); classify the **hidden third gating tier** of 9+ `ci.yml` jobs that are neither merge-gating
  nor advisory-recognized and so silently block Hex publish while never blocking a PR merge — the verified
  mechanism behind the 2.1.1 gate failure; fix the self-racing publish fan-out that makes a successful
  release report failure (`concurrency.group` is ref-scoped while linked releases fire on two tags).

**Scope locks:**
- **Maintenance only.** No product features, no new adopter-facing surface, no redesign, no release cut.
- **No CI topology rewrite.** Lane structure stays; only the honesty of its signals changes.
- **Do not re-plan delivered work.** The 2026-07-28 remediation above is shipped history.
- **Phases continue at 141.** v2.1's 138-140 phase history is archived.
- **SEED-006 (CI/CD efficiency audit) stays sequenced after this milestone.** Optimizing a pipeline whose
  greens are not trustworthy just makes it lie faster.

Scope source: `.planning/research/v2.2/MILESTONE-SCOPE.md`.

</details>

---

## Archived: v2.1 Postgres + Admin URL Hardening (SHIPPED 2026-07-08)

**Opened 2026-07-07, shipped 2026-07-08.** Tight post-v2.0 hardening milestone. v2.0 shipped the dedicated
`mailglass` Postgres schema on 2026-07-04, and its closeout left two bounded correctness gaps worth
closing before a broader UI verification or ecosystem pass: schema-prefix tests/runtime paths could hide
missing `prefix:` bugs when test helpers set `search_path`, and admin stylesheet URLs needed hard-refresh
and deep-link proof across preview/gallery/error paths and alternate mount roots.

**Shipped:** Schema-isolated runtime paths and admin first-load asset URLs now fail closed through focused
gates, without adding product capability or redesigning the admin UI.

Research base (decision-ready, 2026-07-07):
in-thread repository research with focused subagent reads, plus official Ecto prefix guidance and Phoenix
LiveView/router asset behavior. Active brand source remains `brandbook/brand-book.md`; prompt-era brand
research is provenance only.

**Delivered features (dependency-ordered, smallest safe surface first):**
- **Schema-prefix no-search-path hardening (Phase 138)** - fix concrete missing-prefix risks found after
  v2.0 (`Webhook.Replay` projection update, unsubscribe replay/idempotency conflict lookup, and inbound
  raw-repo extension footguns if reachable), then prove them with a hostile runtime lane where the DB
  `search_path` does not include the configured `mailglass` schema.
- **Admin asset first-load/deep-link proof (Phase 139)** - preserve the existing root-relative computed
  mount URL approach in `MountPathHook`/`MountPath`/layout `css_url`, then harden and prove it across
  preview, gallery, scenario, error, operator, inbound, query deep-link, and arbitrary alternate mount
  paths.
- **Verification, docs, and backlog reconciliation (Phase 140)** - wired focused gates, kept the broad
  dual-schema advisory matrix as a canary, updated stale docs/backlog that still described the admin
  deep-link asset issue as unresolved, and close the milestone.

**Locked decisions (research, 2026-07-07):** (1) Explicit Ecto `prefix:` remains the correctness
mechanism; `search_path` is allowed only as host/test convenience and must not be required for runtime
correctness. (2) Use surgical fixes plus hostile tests and a static guard; do not start with a whole-suite
test-fixture rewrite. (3) Keep root-relative computed admin asset URLs; do not introduce `<base>`,
duplicate asset routes, redirects, a CDN/host asset pipeline, or public router macro options unless a
phase proves there is no narrower fix. (4) Browser proof checks network failures and computed styles, not
pixel diffs. (5) Broader UI verification discipline and SEED-003 ecosystem integrations are explicitly
deferred.

**Scope locks:**
- **Maintenance/hardening only.** No new providers, transports, routes, product features, or release cut.
- **No admin redesign.** No token, component, motion, layout, or brand refresh work beyond preserving
  existing computed styling proof.
- **No public router macro API change** unless implementation proves the existing mount-aware path cannot
  satisfy the requirement; if so, document the tradeoff before expanding scope.
- **No full no-search-path suite migration.** The milestone creates a focused fail-closed lane and guard;
  broader fixture cleanup stays future work unless it becomes necessary to make the focused proof honest.
- **Phases continue at 138.** v2.0's 132-137 phase history is archived; v2.1 is three phases: 138-140.
- **Research: DONE.** Per-phase planning can inspect unfamiliar code edges, but milestone-level decisions
  are settled.

---

## Archived: v2.0 Postgres Schema Isolation (SHIPPED 2026-07-04)

**Opened 2026-07-02, shipped 2026-07-04.** First breaking major: default all mailglass domain tables
into a dedicated `mailglass` Postgres SCHEMA instead of host `public`, with `config :mailglass, :schema,
"public"` as the explicit opt-out and `mix mailglass.upgrade.v2_schema` as the Route B move path.
mailglass, mailglass_admin, and mailglass_inbound 2.0.0 are live on Hex; the audit passed and reference
baselines were advanced to `~> 2.0`.

**Closeout follow-up feeding v2.1:** v2.0's release debug campaign found a real missing-`prefix:` bug that
the test harness had masked by setting `search_path`. The tracked bucket-(b) follow-up was a broad
test-fixture `search_path` sweep; v2.1 narrows that into a safer first step: targeted runtime proof under
hostile `search_path`, surgical code fixes, and a guard against recurrence.

---

## Archived: v1.15 Release-Pipeline Efficiency & Contributor DX (SHIPPED 2026-07-02)

**Opened 2026-07-01, shipped 2026-07-02.** First of two designed-and-research-locked hygiene milestones (this one, then
v2.0 Postgres Schema Isolation). Opened because the 1.10.2 patch release took **three tag-move
recovery cycles** — the recurring symptom of a release pipeline whose exact-pin sibling coupling
forces a transient-red-to-main dance on every core bump, plus a local↔CI parity gap where the
documented contributor command (`mix verify.phase_07`, deprecated) exercises a fraction of what merge
requires. This is **infrastructure/DX hardening + one deliberate breaking-the-dance improvement** —
NOT product-capability growth (D-23 convergence holds; the library is feature-complete at ~93–95%).

**Goal:** Kill the exact-pin release dance and close the local↔CI parity gap — make releases genuinely
hands-free and make **one command reproduce the mergeable surface** — with zero product-behavior
change, then cut a real linked Hex release that dogfoods the hardened pipeline end-to-end.

Research base (decision-ready, adversarially verified 2026-07-01):
`.planning/research/milestone-cicd/` — `CICD-RELEASE-HARDENING.md`, `DX-MIX-CI.md`, and
`SYNTHESIS.md` (the locked decisions + the ~19 adversarial refinements that correct the raw dossiers).

**Target features (dependency-ordered, biggest-leverage first):**
- **Sibling-pin loosening (keystone, atomic)** — replace `{:mailglass, "== X.Y.Z"}` with `~>`
  (inbound `~> 1.10 and >= 1.10.2`, admin `~> 1.10`) + relaxed `stability_contract_test` +
  `publish.check` verify + deleted release-please `==` sed rewrites, as one indivisible change.
  Deletes the transient-red-to-main dance and the paired-inbound-per-patch drag.
- **CI Green fan-in gate** — one aggregate required context (release-SHA-safe `skipped` handling)
  replacing the 5 leaf contexts that cause green-but-BLOCKED / admin-merge; set-equality meta-test.
- **Inbound determinism** — root-cause fix for the shared-mode/async sandbox flake (retire `--seed 0`).
- **`mix ci` parity completion** — finish PR #104 so `mix ci` == the mergeable surface (adds Installer
  Host Smoke + trust lane); tiered `ci.fast`/`ci`/`ci.browser`; parity-drift manifest test;
  Postgres/network preflight guard; `verify.*` designated internal.
- **Cache-key + PLT correctness** — toolchain-scoped key from a single `.tool-versions` source;
  Bandit-style PLT self-healing eviction.
- **Supply chain + workflow hygiene** — `mix_audit` (advisory-on-PR / block-at-release); dependabot
  sibling-dir coverage; cowlib OSV-staleness forcing function; `actionlint`; latest-Elixir advisory row.
- **Release cut + closeout** — cut the real linked v1.15 (core+admin linked; inbound **minor** for the
  dependency-policy change), consumer + post-publish smoke, milestone audit + archive.

**Locked decisions (maintainer, 2026-07-01):** (1) **Cut a real Hex release** — the `~>` pins and
`mix ci` aliases only benefit adopters once published, and a real ceremony is the best end-to-end test
of the new pipeline. (2) Inbound pin floors at `>= 1.10.2` (the V05 migration fix), not bare `~> 1.10`
(which would admit the broken `1.10.0/1.10.1`). (3) `mix_audit` and OSV-staleness are advisory on PR,
blocking only at the publish gate (a v1.14-style advisory wave must never red every open PR). (4) The
pin change ships with a CHANGELOG line + documented **Hex retirement** as the new rollback lever
(replacing the `==` wall).

**Scope locks:**
- **Infrastructure + DX only.** No product code, no new provider/transport/route, no schema change
  (Postgres schema isolation is the *next* milestone → v2.0). D-23 convergence holds.
- **Zero product-behavior change** — every change is CI/release-machinery, test-determinism, or
  contributor tooling. The one adopter-visible change is the loosened published dependency constraint.
- **Zero-Node stays adopter-facing** — Node lives only in the opt-in `mix ci.browser`; the required +
  hygiene tiers need none (per the "zero-Node is adopter-facing, not a dev-tooling ban" rule).
- **Atomic-change discipline** — the pin loosening (pin + contract test + publish.check + sed
  deletion) lands as one indivisible change; Dialyzer is not promoted to required until the PLT
  self-healing fix lands. Sequencing is dependency-ordered, not convenience-ordered.
- **Dogfood the method** — each phase pushes a `phase/NN` branch and requires green CI, so the release
  ceremony is a confirmation, not a discovery (adopts the v1.14-post-mortem backlog fix).
- **Research: DONE** — decision-ready dossiers + adversarial synthesis already persisted; phases plan
  directly. Phases continue from 124 → 125+.

## Historical State Ledger

**v2.2 IMPLEMENTATION COMPLETE - CI Signal Integrity & Supply-Chain Hygiene (phases 141-144).** All four
phases are complete and verifier-passed. CI lane classification and supply-chain gating are reconciled;
the Core Full Suite is non-vacuous and release-gating; branch-protection, repo-hygiene, icon, publish,
and release-recovery signals now fail closed with hermetic automated evidence. Phase 144 passed 12/12
must-haves, is Nyquist-compliant, and closed all 13 planned threats with no human UAT. Next: milestone
audit and archive; v2.2 is not labeled shipped until that lifecycle gate completes.

**v2.1 SHIPPED 2026-07-08 - Postgres + Admin URL Hardening.** All 3 phases (138-140) complete, audit
`status: passed` (13/13 requirements). Focused no-search-path schema-prefix hardening has hostile
runtime proof, raw-repo/static guard coverage, and a green `mix verify.schema_prefix` lane. Admin asset
proof passed for first HTML, hard refresh, direct deep links, alternate mounts, CSS/font network
responses, and token-backed computed styling. Docs/backlog truth was reconciled, and active artifacts
preserve deferred scope. See `milestones/v2.1-MILESTONE-AUDIT.md`.

**Superseded by v2.2** (opened 2026-07-28, see above). Broader UI verification discipline, SEED-003
ecosystem integrations, whole-suite no-search-path fixture cleanup, release ceremony, and trigger-based
cowlib advisory allowlist cleanup remain deferred outside v2.1 — the cowlib allowlist cleanup is now
tracked against Phase 142.

**v2.0 SHIPPED 2026-07-04 - mailglass 2.0.0 / mailglass_admin 2.0.0 / mailglass_inbound 2.0.0 live on
Hex.** All 6 phases (132-137) complete, audit `status: passed`. Dedicated `mailglass` Postgres schema is
now the default, with `public` opt-out and v2 schema-upgrade tooling shipped. See
`milestones/v2.0-MILESTONE-AUDIT.md`.

**v1.15 SHIPPED 2026-07-02 - mailglass 1.11.0 / mailglass_admin 1.11.0 / mailglass_inbound 1.6.0 live on
Hex.** All 7 phases (125-131) complete, audit `status: passed` (26/26 reqs). The keystone LD-2 decoupling
shipped: inbound 1.6.0 carries `{:mailglass, "~> 1.10 and >= 1.10.2"}` on Hex - NOT `== 1.11.0`. The floor
stays `>= 1.10.2` (not bumped to 1.11.0) so the decouple is real. See
`milestones/v1.15-MILESTONE-AUDIT.md`. _Historical phase detail below._

**v1.14 SHIPPED 2026-06-30 — mailglass 1.10.1 / mailglass_admin 1.10.1 / mailglass_inbound 1.5.3.**
All 7 phases (118–124) complete, audit `status: passed` (15/15 reqs). Shipped via a linked-version
cut that recovered as a patch (the 1.10.0 cut never published — blocked by a coordinated EEF
dep-security advisory wave; see `milestones/v1.14-MILESTONE-AUDIT.md` +
`threads/v1.14-release-paused-dep-security-wave.md`). _Historical phase detail below._

**v1.14 (Phase 122 mid-milestone snapshot) — Preview surface redesign complete 2026-06-28, verifier
`passed` (PREV-01, 12/12 must-haves).** Preview's admin chrome now uses the canonical
tri-state `Components.theme_picker` (frame-aware `set_theme` routing preserves the
independent email-backdrop axis — the load-bearing D-05 invariant); the email-backdrop
toggle is a11y-hardened (aria-pressed + visible label + aria-live), onboarding/render-error
copy is re-voiced to brandbook, and the dead `dark_chrome` attr was removed. The `preview`
persona re-shoot was deferred to Phase 123 under the locked D-17 fallback (demo boot needs a
baseline-drifting `mix deps.get`). Next: Phase 123 (cross-surface coherence + ratchet
re-arm), then Phase 124 (release cut + closeout).

**v1.13 (prior milestone — SHIPPED 2026-06-21, live 1.8.0/1.8.0/1.5.0, archived; Phases
109, 110, 114, 115, 116 complete; 111, 112,
113 still open; 117 = release cut).** The admin stress-test milestone has its
foundation, primitives, component-groups, pages/flows, and the fixtures + idempotent
ratchet-arm landed. Phase 109 merged the PR #86 baseline and established system-theme
plumbing + semantic z-index/focus/motion gates; Phase 110 promoted the shared admin
atoms into public primitives (`nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`,
`stat_card`). **Phase 116 (Fixtures + Idempotent Ratchet-Arm) completed 2026-06-20,
verifier `passed`, RATCHET-01..05 at 5/5:** a single declarative `MailglassDemo.Personas`
spec (northstar / fjordline-aps / helios-void stress cohort, materialized into both the
demo seed and admin test fixtures via a shared `reference/persona_spec/` dir to dodge a
circular path-dep); a frozen 9-cell WCAG 2.2 AA axe-violation JSON baseline + fail-closed
comparator; four binary interaction-pillar gates (panel-above-scrim, scroll-chaining,
focus-restore, CLS≤4px) plus a component×state×{light,dark,system}×{320..wide} gallery
matrix overflow gate; an executable fail-closed Bucket-A manifest closing all 24 usability
defects; and a full-matrix run against rich `reference/demo_app` data that promoted the
54-cell aesthetic + 9-cell axe baselines current→prior with all three comparators green.
Code review was clean of blockers (0 Critical / 4 Warning / 4 Info — gate-honesty notes,
none falsifying a must-have). Remaining v1.13 work: Phases 111 (Forms), 112 (App-Shell /
Tenant Seam — planning WIP), 113 (Data-Display), then 117 (release cut + closeout).

**v1.11 SHIPPED 2026-06-16 (audit `status: passed` — 34/34 requirements, 10/10
phases, 16/16 integration paths, 7/7 E2E flows).** All ten phases (94-103) closed:
the admin `app.css` now consumes the canonical `brandbook/tokens.css` `--mg-*` tokens
as single source of truth behind a fail-closed token-parity gate; an idempotent
quality ratchet (committed per-`component × pillar × theme` baseline + carried-forward
`GAP-NN` register) is armed (36/36 cells meet-or-beat, 15 improved, zero regressions);
five LOCKED-DECISION research dossiers fed a fractal component → group → page uplift of
all three surfaces (Operator, Inbound, Preview) in light + dark at 390/768/1440, plus a
dev-only component gallery LiveView, global microcopy + motion passes, and all 6 CI
gates green. **Release prepare-only — no Hex release cut**; one PENDING ceremony action
(inbound exact-pin re-pin, D-13) is documented and deliberately deferred. v1.11 is
archived in `.planning/milestones/v1.11-ROADMAP.md`, `v1.11-REQUIREMENTS.md`, and
`v1.11-MILESTONE-AUDIT.md`. Next: `/gsd-new-milestone`.

**v1.10 progress:** All three phases (91, 92, 93) are complete — v1.10's active
scope is finished (999.1/999.2 remain backlog, promoted separately). The fable
brand is canonical under `brandbook/`, the root README now starts with the
canonical README header SVG, `brandbook/examples/og-card.png` is committed at
2400×1260 for manual GitHub social-preview upload, and the admin placeholder
wordmark has been replaced by a sealed-flap `currentColor` lockup. Phase 93 wired
ex_doc `logo:`/`favicon:` into all three packages' `docs/0` (pointing at the
canonical `brandbook/` assets, inert on hexdocs.pm until each package's next
natural release) and hardened the release pipeline: `exclude-paths` on the root
`.` package plus a new required `guard-release-trigger.yml` PR lint (with an
offline 6-case fixture) so a brand/planning-only commit can never again cut a
release. The 1.6.x aftermath is reconciled — in-repo manifest/`@version`/pins
advanced to the released truth **1.6.2 / 1.6.2 / 1.3.1**, remote 1.6.x tags
fetched and kept. No Hex release was cut by this milestone's commits. One
documented manual follow-up: register `guard-release-trigger` as a required
branch-protection check once a PR has exercised it.

**`v1.8 Brand System and Repo-Ready Brandbook` is closed superseded as of 2026-06-11.** Phases 80-82 completed through GSD (brand audit/gap register, source brandbook + tokens, logo option evidence); the logo selection checkpoint and phases 83-84 were resolved out-of-band in a separate working session that selected `concept-07r-no-idot-02-tighter-gap` and finished the brandbook around it (frozen at commit `09a84dd4`). Milestone audit verdict `gaps_found` — accepted at close because v1.9 supersedes the remaining work.

- Known accepted gaps: EXAMPLE/VOICE/REPO requirements never verified through GSD; `brandbook/` logo wordmark is live `<text>` in macOS-only Avenir Next; `tokens.json` retains stale planning language; dark tokens exist but are undemonstrated.
- v1.8 is archived in `.planning/milestones/v1.8-ROADMAP.md`, `v1.8-REQUIREMENTS.md`, `v1.8-MILESTONE-AUDIT.md`, and `v1.8-phases/`.

**`v1.7 Admin UI — IA & Design-System Polish v2` is complete and archived as of 2026-06-05. Phases 74-79 took `mailglass_admin` to "v2 polish" by applying the shipped design system more completely — a frozen UI-SPEC + scored gap register evidence gate, shell-level orientation parity across all 3 surfaces, an in-library Operator Overview landing, one unified `status_badge` atom replacing five divergent copies, full token migration, motion discipline, fully-expressive seed data, and a self-verified closeout (structural e2e + conformance/bundle grep gates, no human UAT). Milestone audit `status: passed` (19/19 requirements, 7/7 seams, 3/3 flows). No new dependencies, no brand-book amendment, stable seams untouched.**

- Phase 74 produced the evidence gate (gap register, frozen UI-SPEC with canonical status-badge taxonomy, before-baseline screenshots, assertion inventory) with zero code changed.
- Phase 75 generalized `Shell.orientation_strip/1` to Deliveries/Inbound/Preview and added the `:overview` Operator Overview landing via `OperatorLive.handle_params/3` — no router-macro change.
- Phase 76 collapsed five `badge_class/1` copies into `Components.status_badge/1`, migrated every admin HEEx file onto the v1 token scale, restructured support cards into a Tier1/Tier2 triage hierarchy, and committed the rebuilt bundle behind a self-contained `heroicons-inline.js` plugin.
- Phase 77 fixed the `motion-reveal` re-fire with record-keyed ids and enforced reduced-motion / transform-opacity-only / ≤300ms via a motion conformance gate.
- Phase 78 made every screen state reachable by a seeded URL with same-commit e2e count-assertion updates and untouched baseline pins.
- Phase 79 re-ran the full audit matrix vs the Phase 74 baseline, extended Playwright to 10 green tests, closed all sev-4/5 gap rows, and staged the linked-version release ceremony prepare-only (inbound exact-pin `== 1.4.5` → `== 1.5.0`; the publish pipeline owns the actual Hex cut — admin-minor bump mechanically drags matched core/inbound versions per D-01).
- v1.7 is archived in `.planning/milestones/v1.7-ROADMAP.md`, `.planning/milestones/v1.7-REQUIREMENTS.md`, and `.planning/milestones/v1.7-MILESTONE-AUDIT.md`.

**`v1.5 Demo Evidence and Click-Around Confidence` is complete as of 2026-06-02. Phases 67-70 shipped a separate realistic demo app, deterministic B2B SaaS Ops data, short click-around docs, and browser-driven evidence across preview, outbound operator, and inbound operator journeys.**

- Phase 67 established `reference/demo_app` as the rich demo surface separate from the narrow `reference/host_app`, with local-path and published-Hex dependency modes, health-gated Compose startup, cache-aware browser setup, deterministic reset proof, and `verify.phase67`.
- Phase 68 expanded deterministic Northstar fixture data with six outbound and four inbound stories, suppression/webhook/replay lineage, realistic preview mailers, and repo-root demo data tests.
- Phase 69 made the dashboard a guided hub into the real mounted preview/outbound/inbound surfaces, made `reference/demo_app/README.md` the canonical quickstart and click-path guide, and replaced human UAT with automated browser/docs evidence.
- Phase 70 reconciled the browser evidence gate to the Phase 69 automation lane: `mix verify.phase69` drives Playwright through the demo dashboard and writes `demo_browser_evidence.v1` checkpoint evidence.
- v1.5 is archived in `.planning/milestones/v1.5-ROADMAP.md`, `.planning/milestones/v1.5-REQUIREMENTS.md`, and `.planning/milestones/v1.5-MILESTONE-AUDIT.md`.

**`v1.4 Inbound Stability Lock` shipped on 2026-06-01. Phase 66 recorded the release-position decision: promote `mailglass_inbound` to the `1.0.0` candidate, with release ceremony / maintenance posture next.**

- Phase 63 reconciled `mailglass_inbound/docs/api_stability.md` into the canonical stable/testing/internal/deferred inbound inventory.
- Provider support is now documented through `MailglassInbound.Ingress.Plug` semantics, while provider modules, replay internals, route structs, workers, queues, and UI details stay internal.
- Deferred inbound capabilities are explicitly named: public replay API, provider extension API, matcher expansion, lifecycle callbacks, fan-out, synthetic UI, `gen_smtp`, and ecosystem integrations.
- Package-local docs-contract assertions now pin those section boundaries and over-claim guards.
- Phase 64 made the inbound contract executable: compiled-doc metadata is verified package-locally, closed error/type sets are locked to docs, release-line/over-claim checks fail closed, and root `mix verify.stability_contract` delegates to the inbound support-contract lane.
- Phase 65 locked the adopter-facing DX story: the inbound README is the canonical adoption lane, install/compatibility/operator/testing/admin trust docs agree on stable versus internal boundaries, and docs-contract plus Tier 1 checks now fail closed on drift.
- Phase 66 promoted the source-of-truth candidate to `mailglass_inbound` `1.0.0`, aligned release notes / README pins / publish proof, and kept broad feature-growth gated until explicit adopter pull or contract gaps justify new scope.

**`v1.3 Adopter Trust Proof` shipped on 2026-05-31.**

- Milestone archive complete: 7 phases (`52`, `57-62`), 18 plans, 16/16 requirements satisfied, final audit `status: passed`
- **Current package versions on Hex: `mailglass` 1.4.5 / `mailglass_admin` 1.4.5 / `mailglass_inbound` 1.1.5** (as of 2026-06-03). The 1.4.x line shipped as quiet maintenance **outside** GSD milestone planning: 1.4.2 unstuck a stranded linked release (admin pinned `mailglass == 1.3.0`); 1.4.3–1.4.5 fixed a stack of latent `mix mailglass.install` bugs the long-red consumer-install smoke had masked (swoosh-1.26 boot crash, OPS-01 finch-in-lock, installer codegen). Inbound was force-bumped to 1.1.5 to track each core release. Earlier line for reference: v1.3 shipped `mailglass`/`mailglass_admin` 1.3.0 (2026-05-29) and v1.6 shipped `mailglass_inbound` 1.0.0 inbound-only (2026-06-02).
- The maintained `reference/host_app` now proves a narrow, public-seam-only adopter path with an explicit scope contract and non-goals.
- One canonical deterministic trust runner now covers install -> preview -> send -> signed webhook ingest -> operator troubleshooting, with stable `trust_runner.v1` checkpoint evidence.
- Required repo-head and clean-baseline trust lanes enforce checkpoint evidence, Hex-first dependency resolution, and branch-protection/release-gate expectations.
- Post-publish smoke now runs a published-version trust journey and guards the current release line against stale-lock and hackney dependency regressions.
- Reference-host and trust-entry docs now route guarantee truth to canonical `api_stability.md` inventories and `mix verify.stability_contract`, with deterministic docs-check enforcement against contract-boundary drift.
- Backlog phase 999.1 completed on 2026-05-27: planning-artifact comment cleanup now covers scoped core/admin/inbound source paths, with Credo drift prevention (`Mailglass.Credo.NoPlanningArtifactComments`) and guard tests added
- Backlog phase 999.2 completed on 2026-05-27: deterministic preview URL/capture matrix foundations, mix screenshot capture workflow, advisory CI artifact lane, and docs claim-boundary contract checks are now in place
- `mailglass_inbound` now has production-credible telemetry, Mailgun + SES ingress, test helpers + generators, admin observability, operator tooling, and six first-party inbound guides
- Phase 51 retired the remaining v1.0 carry-forward debt inside the same milestone: Phase 35 Nyquist bookkeeping, branch-protection repo truth, bare `mix test` citext race, boundary warnings, and WR-01..WR-06 dispositions
- `v1.1` remains the previous shipped slice: `mailglass` 1.0.0 / `mailglass_admin` 1.0.0 / `mailglass_inbound` 0.1.0 published on 2026-05-07 via Phase 44.5

v1.0 milestone closed 2026-05-06. 4 phases (35-38), 12 plans, Stability Lock complete.
v0.6 milestone closed 2026-05-05. 3 phases (32-34), 9 plans, Production Maturity complete.
v0.5 milestone closed 2026-05-03. 4 phases (28-31), 7 plans, Adoption Hardening complete.

**Codebase characteristics:**
- Three sibling Hex packages (`mailglass`, `mailglass_admin`, `mailglass_inbound`) — `mailglass_inbound` opened in v1.1
- Phoenix 1.8+ / Elixir 1.18+ / OTP 27+ / Postgres only
- Append-only `mailglass_events` ledger with SQLSTATE 45A01 immutability trigger
- Multi-tenant first-class — `tenant_id` on every record
- 17 custom Credo checks operationalizing domain rules at lint time (every check registered in `.credo.exs` and meta-test-enforced against the inert-guard blind spot as of Phase 45)
- Boundary-enforced module hierarchy
- Optional-deps (Oban, OpenTelemetry, MJML, gen_smtp, sigra) gated through `Mailglass.OptionalDeps.*` modules
- HEEx + MSO VML fallbacks; zero Node toolchain anywhere
- Preview LiveView shipped at v0.1; production admin workflows, replay history, and tenant-safe operator actions shipped by v0.5
- Inbound package: canonical `%InboundMessage{}` value object, thin router DSL, mailbox behaviour with locked outcomes, Postmark + SendGrid first-party ingress, tenant-safe replayable storage of normalized + raw provider source, Oban-backed async execution with bounded `Task.Supervisor` fallback (v1.1)

**Open issues / debt**:
- Release-workflow fanout still relies on the documented `workflow_dispatch` fallback because GitHub `GITHUB_TOKEN` anti-recursion blocks downstream publish workflows from release-created releases.
- Admin publish still needs an explicit Hex-index wait on inbound when sibling packages release in parallel.
- `SEED-003-ecosystem-integrations` is intentionally deferred and remains dormant for later milestone selection.
- **`v1.6 Inbound 1.0 Release and Truth Lock` SHIPPED 2026-06-02: `mailglass_inbound` 1.0.0 is live on Hex (inserted 17:42:31Z, HexDocs up, release-triggered smoke green).** Cut via the canonical `release: published` path at `50bc4b82`; publish-core/publish-admin idempotency-skipped so no core/admin release was forced. Two release-readiness fixes were made at publish time: dropped 7 untracked draft files from the inbound publish allowlist (the package had been building from a dirty working tree, incl. a duplicate `suppression_flagged` migration), and greened `main` (mix format + a stale compatibility-contract assertion — `main` had been silently red since 2026-05-29 because phases 66–73 landed via `paths-ignore`d commits that never ran `ci.yml`). Posture now: quiet maintenance / adopter-pull, no feature-growth milestone queued.
- A few latent hardening notes remain in per-phase review artifacts, but none block the shipped `v1.2` surface.

## Latest Completed Milestone

<details>
<summary>v1.7 Admin UI — IA & Design-System Polish v2 — milestone closed 2026-06-05</summary>

**Goal:** Take `mailglass_admin` to "v2 polish" — a consistent, brand-distinct, intuitive, joy-to-use design system where each reused component pays dividends, information architecture that orients every persona on landing, and seed data that fully expresses every screen state — all by applying the existing shipped design system more completely (no new dependencies, no brand-book amendment).

- **Orientation parity + Operator Overview (Fork A)** — generalized `orientation_strip` into shell-level `Shell.orientation_strip/1` on Deliveries/Inbound/Preview; added an in-library task-oriented Operator Overview landing (`:overview` action in `OperatorLive.handle_params/3`, zero router-macro change) surfacing orphan-backlog / recent-failure / suppression-count health. ✓
- **Design-system hardening** — one unified `Components.status_badge/1` atom replaced five divergent `badge_class/1` copies (GAP-01..06); every admin HEEx file migrated onto the v1 token scale; the flat 2×2 support-card grid became a Tier1/Tier2 triage hierarchy; rebuilt bundle committed behind a self-contained `heroicons-inline.js` plugin. ✓
- **Motion & expressiveness within the brand book (Fork B)** — `motion-reveal` re-fire fixed with record-keyed ids (GAP-19); reduced-motion / transform-opacity-only / ≤300ms enforced by a motion conformance gate; seed data made every screen state reachable by a seeded URL. ✓
- **Self-verification + visual-regression hardening** — full audit-matrix re-run vs the Phase 74 baseline, Playwright extended to 10 green structural tests, conformance + bundle-clean grep gates, all sev-4/5 gap rows closed; no human UAT. ✓
- **Audit:** `status: passed` — 19/19 requirements, 7/7 cross-phase seams, 3/3 E2E flows.

**Release posture:** prepare-only — the inbound exact-pin was bumped `== 1.4.5` → `== 1.5.0` and the linked-version pipeline owns the Hex publish (admin-minor bump mechanically drags matched core/inbound versions; CHANGELOG entries administrative per D-01).

**Accepted residual debt:**

- Phase 76 human-UAT/verification artifacts left in `partial`/`human_needed` state — resolved downstream by Phases 77 + 79 and confirmed by the milestone audit; recorded as deferred in STATE.md.
- Two draft Nyquist VALIDATION records (Phases 75, 78) — coverage-bookkeeping only; both phases fully verified with green e2e.
- Pre-existing `operator_live.ex` / `suppression_card.ex` nil-guard tech debt (CR-01/02/03, predate v1.7) — candidates for a future maintenance pass.
- Leftover phase directories (71-79, 999.x) still in `.planning/phases/`; run `/gsd-cleanup` to archive execution history retroactively.

</details>

<details>
<summary>v1.6 Inbound 1.0 Release and Truth Lock — milestone closed 2026-06-02</summary>

**Goal:** Publish and prove the selected `mailglass_inbound` `1.0.0` release line, reconcile public docs with that contract truth, and leave Mailglass in a quiet maintenance / adopter-pull posture without adding new product surface.

- **Inbound-only release proof** — `mailglass_inbound` `1.0.0` shipped live on Hex 2026-06-02 (inserted 17:42:31Z, HexDocs up, release-triggered smoke green) via the canonical `release: published` path at `50bc4b82`; publish-core/publish-admin idempotency-skipped so no core/admin release was forced. ✓
- **Own 1.0 contract wording** — inbound described as its own stable `1.0` package contract routed through `mailglass_inbound/docs/api_stability.md`, with core/admin kept on the matched `1.x` sibling line. ✓
- **Release-runbook + published-artifact truth** — stale inbound `1.0` install/fallback/smoke/Hex/HexDocs claims reconciled; release evidence captured. ✓

**Note on subsequent maintenance line:** after v1.6 closed, the `1.4.x` quiet-maintenance line (1.4.2 unstuck a stranded linked release; 1.4.3–1.4.5 fixed `mix mailglass.install` bugs) shipped **outside** GSD milestone planning, bringing live versions to `mailglass` 1.4.5 / `mailglass_admin` 1.4.5 / `mailglass_inbound` 1.1.5 by 2026-06-03.

**Accepted residual debt:**

- Quiet-maintenance posture held; no feature-growth milestone was queued until this v1.7 adopter-visible-quality investment.

</details>

<details>
<summary>v1.5 Demo Evidence and Click-Around Confidence — milestone closed 2026-06-02</summary>

**Goal:** Prove Mailglass is done enough for pre-adopter confidence by shipping a realistic B2B SaaS Ops demo app with rich deterministic data, one-command Docker DX, and browser-driven adoption evidence across preview, outbound operator, and inbound operator journeys.

- **Separate demo app** — `reference/demo_app` stays distinct from `reference/host_app`, supports local-path and published-Hex dependency modes, and starts through health-gated Compose. ✓
- **Realistic fixture corpus** — deterministic Northstar outbound, inbound, suppression, webhook, replay, and preview-mailer scenarios reset from one command. ✓
- **Guided click-around** — dashboard and docs route maintainers into real preview, outbound operator, and inbound operator surfaces with explicit destructive reset wording. ✓
- **Browser evidence** — Playwright drives the dashboard/preview/outbound/inbound paths and writes bounded `demo_browser_evidence.v1` checkpoint evidence. ✓

**Accepted residual debt:**

- Phase directories remain in `.planning/phases/` for now; use `$gsd-cleanup` later if you want to move execution history under the milestone archive.
- The next milestone still needs fresh requirements; `REQUIREMENTS.md` is removed during closeout by design.

</details>

<details>
<summary>v1.4 Inbound Stability Lock — milestone closed 2026-06-01</summary>

**Goal:** Lock `mailglass_inbound` into a stable adopter contract by defining its public API, compatibility policy, docs guarantees, and executable stability checks without expanding feature scope.

- **Stable inventory** — reconciled `mailglass_inbound/docs/api_stability.md` around stable runtime, testing, operator, telemetry, error, internal, and deferred seams. ✓
- **Executable proof** — root `mix verify.stability_contract` now delegates to the package-owned inbound support-contract lane with compiled-doc and docs-contract proof. ✓
- **Adopter DX lock** — README, install, compatibility, operator, testing, and admin trust docs now agree on stable semantics and internal boundaries. ✓
- **Release position** — Phase 66 selected the `mailglass_inbound` `1.0.0` candidate and refreshed source/manifest/docs/publish-proof truth. ✓

**Accepted residual debt:**

- The live Hex release ceremony for `mailglass_inbound` `1.0.0` remains the next release-governance step.
- Broad feature-growth remains blocked unless concrete adopter pull or contract gaps justify new scope.

</details>

<details>
<summary>v1.3 Adopter Trust Proof — milestone closed 2026-05-31</summary>

**Goal:** Prove real-world adoption confidence with one maintained Phoenix reference host app and deterministic trust evidence across local, CI, and published-version release checks.

- **Reference host baseline** — shipped a maintained Phoenix host app with clean-checkout setup, public-seam-only integration, and a fail-closed scope contract. ✓
- **Deterministic trust journey** — shipped `mix verify.reference_host.journey` and stable `trust_runner.v1` checkpoint evidence for install, preview, send, webhook ingest, and operator troubleshooting. ✓
- **CI/release trust evidence** — required repo-head and clean-baseline lanes now publish checkpoint artifacts and guard Hex-first dependency resolution. ✓
- **Published-version proof** — post-publish smoke now runs the current-release trust journey and blocks stale release-line claims. ✓
- **Contract-boundary docs** — reference docs are usage proof only; public guarantee truth routes to canonical stability inventories and executable contract checks. ✓

**Accepted residual debt:**

- Advisory review notes remain for docs checker path-scoping consistency, async mutation flake risk, and broad assertion granularity.
- `mailglass_inbound` still needs a dedicated stability-lock milestone before it carries the same compatibility posture as the core/admin `1.x` surface.

</details>

<details>
<summary>v1.2 Inbound Production Confidence — milestone closed 2026-05-26</summary>

**Goal:** Finish opening `mailglass_inbound` so adopters can install, observe, test, and operate inbound mail with the same confidence already available on outbound.

- **Telemetry + replay proof** — shipped PII-safe inbound spans, PubSub hooks, never-raise MIME parsing, and a 1000-replay convergence proof. ✓
- **Major-provider ingress** — shipped Mailgun and SES inbound verification, normalization, replay-safe persistence, and bounded S3 fetch handling. ✓
- **Adopter DX** — shipped `MailboxCase`, `TestAssertions`, `Test.Ingress`, code-built fixtures, and three Igniter generators. ✓
- **Operator/admin depth** — shipped `InboundLive`, routing-trace and evidence views, replay controls, `mailglass.inbound.{doctor,replay,prune}`, rate limiting, and suppression-flag-only behavior. ✓
- **Closeout discipline** — published `mailglass` 1.2.0 / `mailglass_admin` 1.2.0 / `mailglass_inbound` 0.2.0, then resolved the remaining v1.0 carry-forward debt in Phase 51 before archiving. ✓

**Accepted residual debt:**

- Release-workflow fallback remains manual-by-design until a future maintainer chooses PAT-based or alternate fanout automation.
- `SEED-003-ecosystem-integrations` is acknowledged and dormant, not promoted into the next milestone automatically.

</details>

<details>
<summary>v1.1 Inbound Core Slice — milestone closed 2026-05-06 (audit re-passed 2026-05-07)</summary>

**Goal:** Open `mailglass_inbound` as the first deliberate post-`v1.0` expansion, proving Mailglass can receive, persist, route, and process inbound transactional email without weakening the locked outbound/admin core.

- **Inbound package foundation** — canonical `%InboundMessage{}`, thin router DSL, mailbox behaviour with locked outcomes, package-local persistence boundary, optional-Oban execution seam. ✓
- **First-party provider ingress** — Postmark verify-first ingress with sealed normalization; SendGrid second-provider proof with shared canonical shape and provider-specific dedup. ✓
- **Replayable persistence** — normalized canonical inbound rows alongside raw provider source evidence; replay over stored truth that never pretends a stored message is a fresh provider event. ✓
- **Async execution + adopter proof** — Oban-backed inbound worker, bounded `Task.Supervisor` fallback with explicit warn-on-enter, canonical install / testing / operator docs, repo-root release-proof coverage for the new sibling package. ✓
- **Audit-gap closure** — Phase 43 recovered Phases 39-41 verification artifacts and added Phase 41 validation; Phase 44 recovered Phase 42 verification and reconciled REQUIREMENTS.md / STATE.md / ROADMAP.md so the v1.1 audit re-ran with `status: passed`. No source code under `mailglass/` or `mailglass_inbound/` was modified during the gap closure. ✓

**Accepted closeout debt:**

- No new debt introduced in v1.1. Carry-forward only: v1.0 partial Nyquist bookkeeping for Phase 35, non-blocking boundary warnings in support-contract lanes, manual GitHub branch-protection verification, bare `mix test` citext-OID-cache race.

</details>

<details>
<summary>v1.0 Stability Lock — milestone closed 2026-05-06</summary>

**Goal:** Declare the transactional/admin core stable for long-lived production adoption without expanding the product boundary.

- **Stable surface lock** — core and admin contract inventories are now canonical, narrow, and backed by compiled-doc and docs-surface proof. ✓
- **Compatibility promise** — `1.x` deprecation/support policy and the canonical `0.x -> 1.0` upgrade path are now explicit and mechanically verified. ✓
- **Trust and release proof** — semantic stability verification, canonical testing/admin trust docs, and committed release rehearsal artifacts are now shipped. ✓

**Accepted closeout debt:**

- Phase 35 Nyquist bookkeeping still reports `wave_0_complete: false` even though verification now passes.
- Non-blocking boundary warnings remain in the stability verification lane.
- Manual GitHub branch-protection verification remains external to the repo.

</details>

## Next Milestone Queue (after v1.5)

- **Recommended next step after Demo Evidence:** define a fresh milestone with `$gsd-new-milestone`, biased toward release ceremony for the selected `mailglass_inbound` `1.0.0` candidate, maintenance, release hygiene, docs truth, or narrow adopter-pull work.
- **Convergence posture:** Mailglass is no longer in broad feature-growth mode. Core `mailglass`, `mailglass_admin`, and the inbound source candidate are effectively product-complete for the original transactional-email framework thesis unless concrete adopter pull or a contract gap says otherwise.
- **Done-enough target:** After inbound stability lock, default future posture should be maintenance, release hygiene, docs accuracy, and narrow adopter-pull work. Do not keep asking whether the project is "done" at every milestone boundary; assume the library is approaching done unless a concrete adopter need or contract gap says otherwise.
- Follow-on ordering:
  1) cut the selected `mailglass_inbound` `1.0.0` release line,
  2) enter quiet maintenance / "silence on the wire" mode by default,
  3) consider synthetic inbound dev tooling only if it has clear adopter pull and strict dev-only tenant/provenance safety,
  4) consider Cloudflare forwarding recipe docs or narrow ecosystem integration slices only as pull-driven strategic work,
  5) re-evaluate `gen_smtp` listener only with strong adopter pull and a separate threat/ops model.
- Guardrail remains: do not auto-promote `SEED-003-ecosystem-integrations` or transport-expansion tails as default next work.

## Core Value

**Email you can see, audit, and trust before it ships.** Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure — without leaving Phoenix or bolting on Node.

If everything else fails, the preview dashboard, normalized event ledger, and one-line `Mailglass.deliver/2 → deliver_later/2` ergonomics must work flawlessly.

## Validated Requirements (through v2.6 — SHIPPED)

All 84 v1 REQ-IDs, 38 v0.2 REQ-IDs, 10 v1.1 REQ-IDs, 13 v1.4 REQ-IDs, 19 v1.7 REQ-IDs, 10 v1.10 REQ-IDs, and 34 v1.11 REQ-IDs satisfied. The v1.9 brand book shipped its 22 REQ-IDs (archived in `milestones/v1.9-REQUIREMENTS.md`); v1.8 validated 2 brand-audit requirements before closing superseded.

**v2.6 Engineering Quality Ratchet:**
- ✓ ADOPT-01..06 / EXEC-01..08 — real Repo-explicit migration generation, fail-closed upgrade/repair truth, atomic bounded delivery, private errors, truthful telemetry, and finite persisted decoders.
- ✓ INB-01..07 / DATA-01..08 — bounded pre-verification work, durable terminal evidence, safe MIME transition, indexed/bulk database work, bounded retention, and expand/contract migration policy.
- ✓ ARCH-01..06 / QUAL-01..11 — cycle-free ownership behind stable façades plus deterministic, fail-closed local and protected merge proof.
- ✓ REL-01..04 — production-shaped generated-host certification and protected exact-Hex adoption for `mailglass` 2.5.0, `mailglass_admin` 2.5.0, and `mailglass_inbound` 2.2.0.

**v2.4 Outbound First-Adopter Correctness:**
- ✓ FIRST-01..07 — default-tenant first-send, exact recipient cardinality, body semantics, renderer parity, and zero-effect preflight failures.
- ✓ ENVL-01..08 — complete private envelope, immutable routing/rendering, atomic canonical Oban enqueue, and fail-closed durability.
- ✓ DISP-01..04 / PRIV-01..04 — structural provider outcomes, honest retry/reconciliation, payload scrubbing, bounded retention, and no public-content reconstruction.
- ✓ UNSUB-07..11 — atomic replay-safe one-click event/suppression convergence with immediate tenant/stream-safe enforcement.
- ✓ ADOPT-01..06 / REL-17 — production-shaped public-API host proof, callable preflight, authenticated operator mount, executable docs, protected changed-package publication, and exact-Hex post-publish proof.

**v2.3 B2C First-Adopter Readiness:**
- ✓ B2C-01..07 — stream mapping, suppression scope, RFC 8058 ownership, single-tenant identities, cold-domain pacing, privacy-first tracking, sibling ownership, external launch gates, and no `crosswake_mailglass`.
- ✓ OBS-01..02 — one stable post-commit provider-feedback telemetry event with `%{count: 1}`, PII-free metadata, and replay convergence.
- ✓ ADMIN-01..02 / PROOF-01 — tenant-scoped LiveView subscription switching and live visible-state refresh with foreign-tenant rejection and URL-state preservation.
- ✓ PROOF-02..03 / REL-01 — suppression/docs package proof and the public 2.4.0/2.4.0/2.1.1 clean-consumer release journey.

**By category (v1.13 in progress — Phase 110 validated 2026-06-18):**
- ✓ PRIM-01..07 — public primitive API (`nav_link`, `nav_pill`, `tenant_chip`,
  `theme_picker`, `stat_card`), real shell/overview/gallery consumers, native
  system/light/dark picker semantics, canonical stat cards, 44x44 compiled target
  proof, icon-exists guard, and no-copy-drift/stat-card gates — validated in Phase 110.

**By category (v1.11 — mailglass_admin Design-System Uplift, SHIPPED 2026-06-16):**
- ✓ TOKEN-01..05 — admin `app.css` consumes canonical `brandbook/tokens.css` `--mg-*` tokens (no duplicate hex), corrected surface/border roles, dark-mode AA fixes, fail-closed token-parity gate, bit-clean rebuilt bundle — validated in Phase 94
- ✓ RATCHET-01..05 — committed meet-or-beat score baseline, carried-forward `GAP-NN` register with sev≥3 citation gate, tightened conformance/motion grep gates, Playwright structural assertions, LLM-scored 18-cell PNG matrix (PNGs gitignored) — validated in Phases 94-95 (RATCHET-03 in 94)
- ✓ RESEARCH-01..05 — five adversarially-synthesized LOCKED-DECISION dossiers (motion/IA/component-states/dark-mode/microcopy) — validated in Phase 96
- ✓ COMP-01..03, GALLERY-01..02 — all shared components on-brand in light+dark across the locked state matrix; deterministic on-token status_badge/badge mappings; dev-only `/dev/mail/gallery` with stable `data-testid` cells — validated in Phase 97
- ✓ GROUP-01/02/03, PAGE-01/02/03, RESP-01, FLOW-01/02, A11Y-01/02 — three-surface group/IA/responsive/flow/a11y uplift (Operator anchor Phase 98; Inbound overview tier + RoutingTrace/EvidenceCard rework Phase 99; Preview dark chrome Phase 100) — validated in Phases 98-100
- ✓ COPY-01 — global "thoughtful maintainer" microcopy pass, "Oops" banned across all 3 surfaces, data-driven voice_test — validated in Phase 101
- ✓ MOTION-01..02 — token-named easing, enter/exit asymmetry, skeletons, View-Transitions PE; `prefers-reduced-motion` collapses all motion; motion gate green — validated in Phase 102
- (Phase 103 closeout verified all 34 REQ-IDs: ratchet armed, zero open GAP rows, 6 CI gates green, release staged prepare-only)

**By category (v1.10 — Brand Adoption, SHIPPED 2026-06-13):**
- ✓ FOLD-01..03 — fable book adopted as canonical `brandbook/` via `git mv` (codex removed, history at `09a84dd4`), CLAUDE.md + `design-system.md` pointers reconciled to `brandbook/brand-book.md`, v1.9 gate re-passed on the new path — validated in Phase 91
- ✓ SURF-01..03 — root README brand header, committed 2400×1260 og-card.png with documented social-preview upload, theme-safe sealed-flap admin wordmark with bundle-clean proof — validated in Phase 92
- ✓ HEXD-01..02 — ex_doc `logo:`/`favicon:` wired into all three packages pointing at canonical `brandbook/` assets (SVG width/height added for ex_doc 0.40.x), local `mix docs` renders verified — validated in Phase 93
- ✓ RELH-01..02 — release-please hardened (`exclude-paths` + required `guard-release-trigger` PR lint with offline fixture) so brand/planning-only commits can't cut a release; 1.6.x aftermath reconciled to released truth 1.6.2/1.6.2/1.3.1 — validated in Phase 93

**By category (v1.8 closed superseded — Brand System and Repo-Ready Brandbook):**
- ✓ BRAND-01..02 — critical KEEP/TIGHTEN/REWORK/ADD/REMOVE brand audit and required-surface stress matrix validated in Phase 80.

**By category (v1.7 — Admin UI IA & Design-System Polish v2):**
- ✓ AUDIT-01..03 — scored gap register, frozen UI-SPEC with canonical status-badge taxonomy, and before-baseline screenshot + assertion-ripple inventory validated in Phase 74 (evidence-only gate, zero code)
- ✓ IA-01..04 — shell-level orientation-strip parity on all 3 surfaces, in-library Operator Overview landing (`handle_params/3`, no router change), deliberate IA vocabulary, and explicit deep-link-fix decision validated in Phase 75
- ✓ DS-01..04 — unified `status_badge` atom replacing five `badge_class/1` copies, token migration off the raw scale, support-card Tier1/Tier2 hierarchy, and committed bundle validated in Phase 76
- ✓ MOTION-01..02 — six-motion vocabulary applied per UI-SPEC (mount-not-patch, record-keyed ids) and reduced-motion / ≤300ms / transform-opacity discipline validated in Phase 77
- ✓ SEED-01..02 — seed data making every screen state reachable by URL with same-commit demo/e2e assertion ripple and unchanged baseline pins validated in Phase 78
- ✓ VERIF-01..04 — full audit-matrix re-run vs baseline, extended structural e2e, conformance + bundle gates, and deep-link resolution/deferral validated in Phase 79

**By category (v1.4 — Inbound Stability Lock):**
- ✓ LOCK-01..03 — Canonical stable/testing/operator inventory, stable-vs-internal distinction, and explicit deferred inbound capability list validated in Phase 63
- ✓ PROOF-01..03 — Inbound compiled-doc proof, closed atom/type set docs locks, and over-claim/stale-release docs guards validated in Phase 64
- ✓ DX-01..04 — Canonical adoption path, operator semantics, testing semantics, and admin/operator trust boundaries validated in Phase 65
- ✓ REL-01..03 — Explicit `mailglass_inbound` `1.0.0` candidate decision, operational release notes, and feature-growth gate validated in Phase 66

**By category (v1.3 Phase 52 — trust baseline):**
- ✓ HOST-01..03 — Maintained reference host baseline, public-seam-only integration boundary, and fail-closed scope lock artifact/test contracts validated in Phase 52
- ✓ JOUR-01..02 — Canonical deterministic trust-runner command plus deterministic fixture/checkpoint schema and validator contract validated in Phase 57
- ✓ EVID-02, EVID-03 — Clean-baseline trust lane and published-version trust evidence gates validated in Phases 59-60, with current-release Hex proof closed in Phase 62
- ✓ OPS-01..02 — Release-gate drift prevention and smoke reliability guardrails validated in Phase 60
- ✓ DOCB-01..03 — Reference-host usage-proof boundary, canonical stability routing, and deterministic docs-contract enforcement validated in Phase 61

**By category (v1.1 — Inbound Core Slice):**
- ✓ MODEL-01 — Canonical `%MailglassInbound.InboundMessage{}` value object with stable fields for routing, tenancy, and provider provenance — v1.1
- ✓ ROUTE-01 — Inbound router DSL matching on recipient, subject, and headers, backed by compiled ordered route data and pure matcher engine — v1.1
- ✓ MAILBOX-01 — Mailbox behaviour with locked `:accept` / `:reject` / `:ignore` / `{:bounce, reason}` outcomes — v1.1
- ✓ INGRESS-01..02 — First-party Postmark + SendGrid ingress plugs with verify-first signature checks and sealed normalization into the canonical inbound model — v1.1
- ✓ STORE-01..02 — Tenant-safe persistence of normalized canonical data plus raw provider source evidence; replay over stored truth without re-receive ambiguity — v1.1
- ✓ EXEC-01..02 — Oban-backed async mailbox execution with bounded `Task.Supervisor` fallback and explicit warn-on-enter for the degraded path — v1.1
- ✓ ADOPT-01 — Canonical install / testing / operator-trust docs and repo-root release-proof coverage for the inbound sibling package — v1.1

**By category (v0.2 - Production-Credible Core):**
- ✓ API-01..07 — Mailable API redesign + native Message field setters + `api_stability.md` v2 + codemod task + deprecation warnings + migration guide
- ✓ STREAM-01..04 — Message-stream separation (`:transactional`/`:operational`/`:bulk`) + runtime + compile-time enforcement + stream-aware Feedback-ID
- ✓ UNSUB-01..06 — RFC 8058 List-Unsubscribe headers + signed-token controller + rotation + generator + property tests
- ✓ SUPP-01..05 — Auto-suppression on bounce/complaint/unsubscribe + soft-bounce escalation + resync mix task + default-deny pre-send check
- ✓ REL-01..16 — Release-engineering hardening: 9 v0.1.2 polish TODOs + Tests gate halt-on-failure + Credo strict + Dialyzer halt-exit-status + release ceremony (CHANGELOG, migration guide, Hex publish)

**By category (v0.1):**
- ✓ CORE-01..07 — Error hierarchy, Config, Telemetry whitelist, Repo.transact/1, IdempotencyKey, OptionalDeps gateway, boundary
- ✓ AUTHOR-01..05 — Mailable behaviour, HEEx components with MSO fallbacks, render pipeline <50ms, Gettext i18n, MJML opt-in
- ✓ PERSIST-01..06 — 3 tables (deliveries/events/suppressions), append-only trigger, idempotency partial UNIQUE, append/1 + append_multi/3, migration generator
- ✓ TENANT-01..03 — tenant_id on every schema, Tenancy behaviour + SingleTenant default, NoUnscopedTenantQueryInLib Credo enforcement
- ✓ TRANS-01..04 — Adapter behaviour, Fake (merge gate), Swoosh wrapper, Outbound facade
- ✓ SEND-01..05 — Preflight pipeline, ETS RateLimiter, Outbound.Worker, Suppression check_before_send, PubSub.Topics
- ✓ TRACK-01..03 — Off by default, NoTrackingOnAuthStream lint, signed Phoenix.Token rewriting
- ✓ HOOK-01..07 — CachingBodyReader, Postmark + SendGrid HMAC, Anymail taxonomy verbatim, one-Multi ingest, 1000-replay convergence
- ✓ COMP-01..02 — RFC headers, Feedback-ID
- ✓ PREV-01..06 — mailglass_admin sibling package, Router macro, PreviewLive with sidebar/tabs/device toggle, LiveReload, brand-conformant components, committed bundle
- ✓ TEST-01..05 — TestAssertions (4 matcher styles), per-domain Case templates, StreamData properties, real-provider sandbox advisory cron, Clock injection
- ✓ LINT-01..12 — 12 custom Credo checks operationalizing domain rules at lint time
- ✓ INST-01..04 — `mix mailglass.install` with idempotent sidecars, golden-diff CI, verify.phase aliases
- ✓ CI-01..07 — GHA workflows, single-cell required matrix, Conventional Commits, Release Please linked-versions, tarball whitelisted, Actions SHA-pinned, HEX_API_KEY in protected Environment
- ✓ DOCS-01..05 — ExDoc with 9 guides, migration-from-swoosh, doc-contract tests, governance files
- ✓ BRAND-01..03 — Brand-conformant UI + voice + docs

## Most Recent Milestone: v1.13 Admin Design-System Stress Test & UX Uplift v3 (SHIPPED 2026-06-21)

**Current released state: `mailglass` 1.8.0 / `mailglass_admin` 1.8.0 / `mailglass_inbound` 1.5.0**
(live on Hex 2026-06-21). **Opened 2026-06-18; shipped 2026-06-21** — audit `status: passed`
(41/41 requirements, 9 phases 109–117); linked-version MINOR (admin design-system bump drags
matched core + inbound), `mailglass_inbound` re-pinned `{:mailglass, "== 1.8.0"}` (D-13 / REL-02).
Third lived-experience admin design-system pass (light/dark/system, WCAG 2.2 AA, multi-tenant
stress fixtures, axe-JSON + score-baseline ratchet) — no product-capability growth (D-23/D-28/D-29).
Detail archived in `.planning/milestones/v1.13-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.
Release-engineering note: the 227-commit body had never run CI while origin was frozen, so the cut
surfaced 3 latent regressions (a `mix format` comment, 2 Dialyzer Ecto map-projection specs, 16
stale Phase-113 responsive browser specs) plus a publish-time `premailex` lock-incompat fixed by
`mix deps.unlock --all` before the sibling `deps.get` in `publish-hex.yml` (`ceee3835`).

## Preceding Milestone: v1.12 Adopter Onboarding & Day-2 Confidence (SHIPPED 2026-06-17)

**Opened 2026-06-16; shipped 2026-06-17** — audit `status: passed` (13/13 requirements, 5/5 phases);
**cut the first real linked-version Hex release since 1.6.2** → live at 1.7.0 / 1.7.0 / 1.4.0,
mailglass_inbound re-pinned `{:mailglass, "== 1.7.0"}` (D-13 / REL-02). Detail archived in
`.planning/milestones/v1.12-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.

**Opened 2026-06-16.** Phases 104–108, 13 requirements (`.planning/REQUIREMENTS.md`); roadmap in
`.planning/ROADMAP.md`. Selected from the 2026-06-16 next-step assessment: mailglass is
feature-complete for its scope (~88–90% done; the risk is overbuilding, not underbuilding), and the
one remaining adopter wedge is onboarding / day-2 DX. This milestone removes adoption friction and
**publishes** — it is friction-removal + release, not feature growth (D-23 convergence posture holds).

**Goal:** A Phoenix dev goes from `mix mailglass.install` to a correctly-wired, production-ready
integration without a silent webhook failure, a broken copy-paste example, or a missing day-2
runbook — and the accumulated v1.7–v1.12 polish finally ships to Hex.

**Target features:**
- **Installer fails closed** on the webhook-`Plug.Parsers` conflict (today a silent prod 401), with
  a `--force` escape hatch + a verifiable post-install webhook-wiring doctor check (Phase 104).
- **Onboarding fixes**: working README quickstart, a "next steps"/learning-path arc, a sharpened
  migration-from-swoosh "why" (Phase 105).
- **Day-2 runbooks**: production go-live checklist + a unified error/troubleshooting map (Phase 106).
- **Inbound replay-modal a11y parity** (focus-trap + Escape; folded-in v1.11 WR-03) (Phase 107).
- **Cut the real Hex release** for the staged v1.7–v1.12 work + D-13 inbound exact-pin re-pin
  (Phase 108). **Release posture: actually cut** (the deliberate change from v1.7/v1.11 prepare-only).

**Decided this session:** (D-28) v1.12 actually cuts the Hex release rather than staging
prepare-only — the staged polish must reach adopters. (D-29) the inbound replay-modal a11y fix
(ex-v1.11 WR-03) is folded into v1.12 as a quality-parity item.

**Diminishing-returns — explicitly NOT in scope (do NOT build without concrete adopter pull):**
- Core mailglass **email-template HEEx component** design-system uplift — components are real and
  VML/MSO-complete; recipient-facing polish, not an adopter wedge.
- `SEED-003` ecosystem integrations — no adopter signal; needs a narrow spike + real pull first.
- Synthetic inbound dev UI, Cloudflare Email Routing, `gen_smtp` listener, more providers — all
  flat-tail (see `.planning/threads/transport-expansion-watchlist.md`).

> Note: `.planning/research/JTBD-COVERAGE.md` (the internal frontier map) is 5 milestones stale; its
> *curve/conclusion* holds (wait for pull) but its status tables don't. Refresh it before any
> *feature-discovery* pass — not needed for this onboarding/release milestone.

## Out of Scope

Explicit boundaries with permanent reasoning to prevent re-litigation.

- **Marketing email** (campaigns, contact lists, segmentation, drip automations, A/B testing, broadcast scheduling) — that's [Keila](https://www.keila.io) / [Listmonk](https://listmonk.app) territory. Mailglass is forever **transactional + operational** mail.
- **Single-pane multi-channel notifications** (push, SMS, in-app, Slack alongside email) — that's a [Noticed](https://github.com/excid3/noticed)-shaped library with a different abstraction. Mailglass stays focused on email so it can be excellent at email.
- **Built-in subscriber management / preference center** — depends on having marketing concerns; if/when individual adopters need it, they can build it on the suppression + consent primitives mailglass exposes.
- **AMP for Email** — declared dead post-Cloudflare's October 2025 sunset; <5% adoption.
- **MJML as a default rendering path** — HEEx + Phoenix.Component with MSO fallbacks IS the default. MJML stays as opt-in `Mailglass.TemplateEngine.MJML` via the `mjml` Hex package.
- **Standalone ops console / SaaS dashboard** — `mailglass_admin` mounts in adopters' Phoenix apps; we don't run hosted infrastructure.
- **Backwards compatibility with Bamboo APIs** — Bamboo in maintenance mode; Swoosh is Phoenix 1.7+ default. Migration guide is from raw Swoosh + `Phoenix.Swoosh`.
- **Pre-Phoenix-1.8 / pre-LiveView-1.0 / pre-Elixir-1.18 support** — bleeding-edge floor (Elixir 1.18+, OTP 27+, Phoenix 1.8+, LiveView 1.0+, Ecto 3.13+).
- **Custom SMTP server** — `gen_smtp` for inbound relay is the floor; mailglass is not building or maintaining an SMTP daemon.
- **MySQL/SQLite support** — Postgres only. Advisory locks, JSONB, partial unique indexes, triggers are load-bearing.
- **Open/click tracking on by default** — privacy-first stance; legal liability on auth-carrying messages.
- **Open core / paid Pro tier** — MIT pure OSS across all sibling packages forever. No `mailglass_pro`.
- **Hosted SaaS Pro tier** — same as standalone ops console; we mount, never host.
- **Conductor-style inbound dev UI in `v1.1`** — the first inbound milestone proves routing, storage, and execution before adding a synthetic/replay LiveView surface.
- **Mailgun / SES / `gen_smtp` relay ingress in `v1.1`** — the first inbound milestone proves the package on Postmark + SendGrid before broadening provider or transport scope.
- **Provider-matrix broadening in `v1.3`** — trust proof is a single representative journey, not a breadth expansion milestone.
- **`SEED-003-ecosystem-integrations` auto-promotion in `v1.3`** — remains deferred until trust proof and inbound stability lock are complete.
- **Transport-class expansion (`gen_smtp` listener) in `v1.3`** — requires a dedicated milestone with separate threat model and ops burden review.

## Context

**The gap mailglass fills.** Swoosh is the canonical Phoenix mailer (39k downloads/month, healthy maintenance, extensible). It is excellent at the `compose → adapter → deliver` primitive. But everything around it — responsive templates, preview dashboards, normalized webhook events, suppression enforcement, signed unsubscribe, inbound routing, admin tooling, deliverability tooling — is left to each project to rebuild. The 2024 Gmail/Yahoo bulk-sender rules, React Email's emergence, and Phoenix 1.7's removal of `Phoenix.View` made the timing acute.

**Position relative to the ecosystem.** Mailglass is **not** a Swoosh replacement; it composes on top. It is **not** Bamboo (maintenance mode). It is **not** Keila (newsletter application, AGPLv3, not embeddable). It IS the missing framework layer between Swoosh's transport and a senior Phoenix team's transactional email needs.

**Engineering DNA inherited from prior libraries** (accrue, lattice_stripe, sigra, scrypath):

- Pluggable behaviours over magic — narrow callbacks, minimal surface
- Errors as a public API contract — structured `Mailglass.Error.t()` with closed `:type` atom set, `:cause` excluded from `Jason.Encoder`, one mapper per provider
- Telemetry as first-class — `[:mailglass, :domain, :resource, :action, :start | :stop | :exception]` 4-level naming, never raise from handlers, never include PII
- Append-only event ledger with Postgres trigger immutability — every mutation flows through `Ecto.Multi` that includes a `mailglass_events` row; SQLSTATE 45A01 on UPDATE/DELETE
- Sibling packages with linked-version releases — Release Please with `separate-pull-requests: false` + linked-versions plugin
- Fake adapter as required release gate — real-provider sandbox tests advisory only (daily cron + `workflow_dispatch`)
- Custom Credo checks for domain rules — domain invariants enforced at lint time
- Continuous phase counter & evidence-led backlog triage — the `.planning/` discipline this very document is part of

**Brand voice.** mailglass is "clear, exact, confident (not cocky), warm (not cute), modern (not trendy), technical (not intimidating)." The voice is "a thoughtful maintainer." Errors are specific and composed ("Delivery blocked: recipient is on the suppression list" — never "Oops!"). Documentation prefers the direct word ("preview" over "experience the full rendering lifecycle"). Visual palette: **Ink** #0D1B2A, **Glass** #277B96, **Ice** #A6EAF2, **Mist** #EAF6FB, **Paper** #F8FBFD, **Slate** #5C6B7A. Typography: Inter (UI/body), Inter Tight (display), IBM Plex Mono (code). Mobile-first responsive. No glassmorphism, bevels, lens flares, or "literal broken glass" visuals.

**Target persona / JTBD.** Senior or technical-lead Phoenix developers shipping production transactional email for SaaS apps. Common JTBDs: "let me ship a welcome email I can preview before deploying," "let me trust my password-reset deliveries," "let me audit why a customer's receipt didn't arrive," "let me operationalize bounce/complaint handling without rolling my own webhook plumbing," "let me support multiple tenants with different sending domains."

**Prior research artifacts** (preserved in `prompts/`, source of truth for vocabulary + conventions):

- `Phoenix needs an email framework not another mailer.md` — the founding thesis
- `mailglass-brand-book.md` — visual identity, voice, palette
- `mailer-domain-language-deep-research.md` — canonical vocabulary (Mailable / Message / Delivery / Event / InboundMessage / Mailbox / Suppression)
- `mailglass-engineering-dna-from-prior-libs.md` — engineering patterns distilled
- Various Elixir/Ecto/Phoenix/LiveView/Plug/OSS-CI/CD best-practices research files

## Constraints

- **Tech stack**: Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+ / Postgres (Postgrex). Bleeding-edge floor.
- **Required deps**: `:ecto_sql`, `:postgrex`, `:phoenix`, `:swoosh`, `:nimble_options`, `:telemetry`, `:gettext`, `:premailex`, `:floki`. Hard required from v0.1.
- **Optional deps**: `:oban`, `:opentelemetry`, `:sigra`, `:mjml`, `:gen_smtp`. CI must pass `mix compile --no-optional-deps --warnings-as-errors`.
- **Persistence**: Postgres only. MySQL/SQLite explicitly not supported.
- **Phoenix coupling**: Phoenix is a hard dep; mailglass is unapologetically Phoenix-first.
- **License**: MIT across all sibling packages, forever.
- **Distribution**: Hex.pm only. Source on GitHub. No standalone npm packages, no compiled binaries, no Node toolchain anywhere.
- **Compliance**: RFC 8058, 2024 Gmail/Yahoo bulk-sender rules, US CAN-SPAM, GDPR-shaped consent + suppression audit trail.
- **Privacy**: open/click tracking off by default. Telemetry metadata never includes recipient addresses, message bodies, or response payloads.
- **Security**: webhook signature failures raise `Mailglass.SignatureError` at call site — no recovery from forged webhooks. Unsubscribe tokens are signed with rotation support.
- **Maintenance budget**: one-person maintainer realistic; v0.1 must be coastable for 6 months without releases. Provider/compliance churn is expected to consume 20–30% of maintenance time forever.

## Key Decisions

| ID | Decision | Rationale | Outcome |
|----|----------|-----------|---------|
| D-01 | Sibling packages from v0.1 (`mailglass`, `mailglass_admin`, `mailglass_inbound` v0.5+) | Per accrue/sigra DNA — admin is mounted in adopters' apps, not run standalone; linked-version releases via Release Please | ✓ Validated v0.1 — Release Please linked-versions works; `mailglass_admin/mix.exs` pins `{:mailglass, "== <ver>"}` |
| D-02 | MIT license across all packages | Aligns with Swoosh/Phoenix/Ecto; maximizes adoption | ✓ Held v0.1 |
| D-03 | Marketing email **permanently** out of scope | Different problem (lists/segments/campaigns), different compliance surface, different abstraction | ✓ Held v0.1 |
| D-04 | Single-pane multi-channel notifications **out** | That's a Noticed-shaped lib; mailglass stays email-only | ✓ Held v0.1 |
| D-05 | Inbound (Action Mailbox equivalent) **in scope** as `mailglass_inbound` sibling package | Inbound webhook plumbing shares HMAC + plug + event-normalization infrastructure with the existing mailglass delivery and webhook foundation | ✓ Validated v1.1 — `mailglass_inbound` opened with Postmark + SendGrid ingress, replayable persistence, Oban-optional execution |
| D-06 | Bleeding-edge version floor (Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+) | Newest features (streams, async, scopes, schema_redact, colocated hooks); smallest CI matrix | ✓ Validated v0.1 — Elixir 1.19 type checker forced struct-discrimination tests via `__struct__` comparison (worked, with documented workaround) |
| D-07 | Ecto + Phoenix **required**; Oban **optional** | mailglass is a Phoenix-first framework; `deliver_later/2` degrades to `Task.Supervisor` with a warning when Oban absent | ✓ Validated v0.1 — Outbound.Worker conditionally compiled; Task.Supervisor fallback path tested |
| D-08 | Open/click tracking **off by default** | Apple Mail Privacy Protection makes opens noisy; auth-carrying messages must NEVER have rewritten links | ✓ Validated v0.1 — NoTrackingOnAuthStream Credo check operationalizes |
| D-09 | Multi-tenancy **first-class from v0.1** | Phoenix 1.8 scopes default makes this the right time; harder to retrofit | ✓ Held v0.1 — `tenant_id` on every schema |
| D-10 | v0.1 normalizes **Postmark + SendGrid** webhooks; Mailgun/SES/Resend land in v0.5 | Most-used per Anymail data; smallest validation matrix | ✓ Held v0.1 |
| D-11 | Preview LiveView is **dev-only at v0.1**, prod admin lands at v0.5 | v0.1 surface stays scoped; admin UI needs event taxonomy maturity | ✓ Held v0.1 |
| D-12 | Full `mix mailglass.install` with golden-diff CI from v0.1 | "Batteries-included" brand promise demands one-command setup | ✓ Validated v0.1 — Phase 07.1 closed installer blockers G-1..G-5 (real `Apply.run` driving golden test) |
| D-13 | Test pyramid: doctests + ExUnit + StreamData property + Mox + **Fake adapter release gate** + real-provider sandbox advisory only | Per accrue DNA — real provider tests on daily cron + `workflow_dispatch`, never block PRs | ✓ Held v0.1 |
| D-14 | Anymail event taxonomy **verbatim** for normalized webhook events | Don't reinvent; multi-language standard; lowers cognitive cost for polyglot teams | ⚠ Held with one amendment — `:reconciled` is `@mailglass_internal_types` (audit-only), never emitted by provider mappers |
| D-15 | `mailglass_events` table is **append-only**, enforced by Postgres trigger raising SQLSTATE 45A01 | Per accrue DNA — single source of truth; immutability is structural, not policy | ✓ Validated v0.1 — `Mailglass.Repo` write path translates SQLSTATE at four sites |
| D-16 | Conventional Commits + Release Please + sibling-linked-version automation; Hex publish from protected ref only | Per OSS CI/CD best practices; squash-merge workflow keeps casual contributor UX low-friction | ✓ Validated v0.1 — release-please extra-files no-op surfaced; mitigated with workflow sed step |
| D-17 | Custom Credo checks enforce domain rules | Per engineering DNA — invariants caught at lint time, not just runtime | ✓ Validated v0.1 — 12 checks operational |
| D-18 | Renderer default is HEEx + `Phoenix.Component` with MSO VML fallbacks; MJML opt-in via `:mjml` Hex package (NOT `:mrml`) | Native composition, no Node, killer differentiator vs React Email + Mailing | ✓ Held v0.1 |
| D-19 | Brand voice & visual identity locked to `brandbook/brand-book.md` | Brand discipline prevents drift toward generic SaaS or growth-marketing aesthetic; prompt-era research remains preserved as provenance | Superseded by v1.10 canonical adoption |
| D-20 | Domain vocabulary locked to `prompts/mailer-domain-language-deep-research.md` | Borrowed from battle-tested libs; avoid "Email" or "Status" as ambiguous primitives | ✓ Held v0.1 |
| D-21 | Adapter call between Multi#1 and Multi#2 (never inside transaction) | Postgres pool starvation prevention | ✓ Held v0.1 — Phase 3 Outbound enforces |
| D-22 | The first `mailglass_inbound` milestone stays narrow: Postmark + SendGrid ingress, normalized plus raw replayable storage, and Oban-optional execution; Conductor/Mailgun/SES/SMTP are deferred | Protect the locked `v1.x` core and make the first sibling-package expansion supportable for a one-person maintainer | ✓ Validated v1.1 — narrow scope held; Conductor / Mailgun / SES / `gen_smtp` remained deliberately deferred |
| D-23 | Post-v1.3 project posture shifts from broad capability expansion to convergence, stability, and maintenance by default | Core/admin have crossed the original product-complete threshold; endless polish or provider breadth has diminishing returns unless tied to adopter pull | ✓ Validated v1.4 — inbound contract posture is locked, `mailglass_inbound` has a `1.0.0` candidate, and future work defaults to release ceremony / maintenance unless adopter pull or contract gaps justify scope |
| D-24 | v1.7 admin UI polish is a sanctioned **adopter-visible-quality** investment under the D-23 convergence rule (not feature growth); delivered **within** the brand book (Fork B) by *applying* the shipped design system more completely, with a real in-library Operator Overview landing + generalized orientation (Fork A) | First-run/forensic UX quality is the highest-leverage remaining adopter lever now that the product surface is complete; restraint (no brand amendment, no new deps, grep-enforceable conformance) keeps it convergence-aligned, not scope creep | ✓ Validated v1.7 — anti-churn gate held (every build task cited a sev≥3 gap-register row), stable seams untouched, no new deps, conformance grep-enforced; audit passed 19/19; linked-version admin bump confirmed mechanical |
| D-25 | v1.8 brand-system work is a repo-artifact milestone, not product expansion | Mailglass had strong prompt-era brand direction but lacked source-controlled, buildable collateral for maintainers, future agents, docs, landing pages, tokens, logos, and marketing copy | ✓ Held through v1.8→v1.9→v1.10 — all artifacts stayed under `brandbook/`; no public API/package code changes; brand strategy preserved as provenance |
| D-26 | v1.10 adopts the A/B-winning fable brand as the project's one canonical identity and hardens the release pipeline against accidental brand/planning-only releases | The v1.9 A/B winner needed to actually become the repo's identity (folder, README, social, HexDocs), and the 1.6.x accidental-release incident proved release-please could cut a release from non-code commits | ✓ Validated v1.10 — canonical `brandbook/` adopted (codex removed), README/og-card/admin/HexDocs surfaces propagated, `exclude-paths` + required `guard-release-trigger` lint added, 1.6.x aftermath reconciled to 1.6.2/1.6.2/1.3.1; audit passed 10/10; no Hex release cut |
| D-27 | v1.11 re-baselines `mailglass_admin` onto the canonical fable brand tokens and runs a fractal (component → group → page), idempotent, research-grounded design-system uplift of all three admin surfaces — an adopter-visible-quality investment under D-23, not feature growth | The admin UI was last polished (v1.7) against the *old codex-era* brand; v1.9→v1.10 brand work never touched the admin's `app.css`, leaving it drifted (borders drawn in the accent color, cards one brand-role off, dark muted text below AA, no consumption of `brandbook/tokens.css`). The "Storybook lens" is realized as a thin dev-only gallery (zero-Node forbids real Storybook); "only-forward" is enforced by a committed score baseline + carried-forward GAP register. Scope fenced to admin UI; release prepare-only | ✓ Validated v1.11 — all 3 admin surfaces re-baselined onto `brandbook/tokens.css`; idempotent ratchet armed (36/36 cells meet-or-beat, zero regressions); dev-only gallery shipped; audit passed 34/34 reqs across 10 phases; release prepare-only held (no Hex cut); fenced scope held (no functional core/inbound changes) |
| D-28 | Each adopter-quality milestone **actually cuts** the linked-version Hex release at close (not prepare-only), draining the staged-but-unshipped backlog to adopters | v1.7/v1.11 staged release ceremonies prepare-only, accumulating polish on `main` that adopters never saw; the convergence posture is only adopter-valuable once it ships | ✓ Validated v1.12 — first real linked-version release since 1.6.2 cut (1.7.0/1.7.0/1.4.0); carried into v1.13 (PR #86 fixes + the design-system uplift ship together) |
| D-29 | v1.13 is a third adopter-visible-quality admin pass under D-23, distinguished from v1.7/v1.11 by being **lived-experience / real-demo-driven** rather than in-the-lab: a fractal, research-per-decision (adversarially judged), WCAG-2.2-AA, light/dark/**system**, idempotent design-system stress-test that also fixes the multi-tenant demo so the picker earns its place — then ships (D-28) | v1.11's ratchet passed in the lab (LLM-scored PNGs, structural assertions) yet clicking the real demo still surfaced usability traps and "kind of ugly" rough edges; the remaining gap is lived-experience polish + a tangible multi-tenant story, not more capability. Restraint (admin+demo only, brand book is source of truth, no new deps without a decision brief, idempotent meet-or-beat ratchet extended from v1.11) keeps it convergence-aligned | — Pending (v1.13 in flight) |
| D-30 | Mailglass publishes the B2C email safety profile but host/Chimeway retain notification preferences and RFC 8058 category policy | Preference, consent, auth, and product policy belong with the host; Mailglass owns stream and suppression mechanics | ✓ Validated v2.3 — guide/package contracts passed without adding a preference-center API |
| D-31 | Provider feedback emits once from the existing post-commit projector chokepoint with a closed, PII-free metadata contract | Observability consumers need durable facts, not webhook-attempt noise or recipient/message data | ✓ Validated v2.3 — replay-safe event and metadata contract passed focused tests |
| D-32 | The admin reuses existing tenant PubSub topics and refreshes read models; it does not add a second event bus or mutate URL navigation state | Existing projection topics are the canonical live signal and keep the one-maintainer architecture supportable | ✓ Validated v2.3 — current-tenant refresh and foreign-tenant rejection passed 79 LiveView tests |
| D-33 | B2C release links core/admin 2.4.0 while inbound remains independently versioned at 2.1.1 | Inbound had no compatibility change and must not be republished merely because linked outbound/admin packages ship | ✓ Validated v2.3 — protected publication and clean public consumer smoke passed |
| D-34 | The supported outbound envelope has exactly one recipient across `to`/`cc`/`bcc`, and invalid tenancy, recipient, or body shapes fail before effects | The first-adopter contract must be explicit and safely enforceable before rendering, rate limiting, persistence, queueing, or provider I/O | ✓ Validated v2.4 — shared preflight and generated-host negative controls pass |
| D-35 | Durable Oban delivery stores a complete private, versioned envelope and commits its public projection, ledger event, payload, and ID-only job atomically | Retries must use immutable prepared truth without leaking content into public metadata or claiming queue success after a partial commit | ✓ Validated v2.4 — prefix-safe atomic enqueue, real job recovery, and payload privacy proofs pass |
| D-36 | Provider outcomes use conservative structural classes; successful dispatch atomically settles and scrubs private payload content | Error-string guessing and blind retries can duplicate accepted mail, while unbounded payload retention violates the privacy contract | ✓ Validated v2.4 — sync/async parity, retry/cancel/reconciliation, retention, and scrub proofs pass |
| D-37 | Built-in RFC 8058 POST atomically converges one canonical unsubscribe event and one stream-scoped suppression before best-effort host effects | Replay, concurrency, tenant isolation, and suppression enforcement must agree on one durable state transition | ✓ Validated v2.4 — concurrent replay and hostile-schema proofs pass |
| D-38 | Release only the resolver-selected changed package set through protected automation, then accept the release only after an exact-Hex production-shaped journey | A green repository build is not proof that immutable public artifacts install and work together | ✓ Validated v2.4 — 2.4.1/2.4.1/2.1.2 published from immutable candidate `587c9d1`; exact-Hex and trust journeys passed |
| D-39 | Migration generation is additive and Repo-explicit: initial wrappers call public façades, upgrades are new timestamped files with a baked rollback version, and anchor corruption/query failure never means version zero | Applied Ecto migrations do not rerun after package upgrades, inferred Repo modules fail in custom/multi-repo hosts, and fail-open metadata can replay destructive DDL | ✓ Validated Phase 155 — core/inbound generator and catalog matrices pass; exact legacy repair is runtime-revalidated under lock |
| D-40 | Core and inbound own only their relations inside a shared configured schema; down-to-zero drops the schema with RESTRICT only when it is empty | Either package may be rolled back first without deleting or blocking on sibling/host objects | ✓ Validated Phase 155 — two isolated generated Host.Repo journeys pass in both rollback orders |
| D-41 | `CI Green` preserves its public identity but directly depends on successful change detection and exact success from every required code lane | A skipped or failed detector/leaf must not be interpreted as docs-only green | ✓ Validated Phase 155 — exhaustive policy/meta-tests, actionlint, and protected-lane wiring pass |
| D-42 | Delivery and ingress resource limits are structural contracts: fixed-point atomic buckets, bounded task/certificate/cache/S3 work, and closed retry classifications fail safely under saturation | Correct happy-path behavior is insufficient when attacker-controlled cardinality, concurrency, or provider faults can exhaust a first adopter's host | ✓ Validated Phases 156-157 — isolated concurrency, saturation, cache, S3, and provider suites pass |
| D-43 | Future populated-table changes use additive expand/contract migrations with bounded session timeouts and concurrent indexes, while exact raw signed input and replay evidence remain durable | Adopters need safe upgrades and forensic truth without rewriting already-applied migration history or retaining unbounded processing state | ✓ Validated Phase 157 — both generated-host package orders, interrupted/resumed backfills, rollback, rerun, and immutable-history checks pass |
| D-44 | Stable v2 façades remain thin compatibility edges over validated Runtime state, cohesive package-local pipelines, and narrow sibling ports; executable AST/CI guards prevent ownership drift | Refactoring only raises quality when it removes policy duplication without forcing adopter migrations or creating ceremonial wrapper modules | ✓ Validated Phase 158 — independent review closed vacuous guards/trampolines and final core/inbound compatibility, no-optional, cycle, and scope suites pass |
| D-45 | One canonical local `mix ci` path and the protected `CI Green` aggregate must cover the same required deterministic evidence, with explicit ownership for every exception | Maintainers need a single reproducible merge signal whose green state cannot be manufactured by skipped, stale, or cross-test evidence | ✓ Validated Phase 159 and milestone re-audit — scoped telemetry regression, policy checks, and uninterrupted full CI passed |
| D-46 | Publication authority is bound to one authorized candidate digest and immutable tag, and success requires exact-Hex generated-host and trust-runner evidence | Repository green is not sufficient proof that the public three-package family is installable and behaviorally identical | ✓ Validated Phase 160 — 2.5.0 / 2.5.0 / 2.2.0 published and exact-Hex adoption passed from immutable tag SHA `0f0b0686` |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions with `D-NN` ID
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
5. Brand voice / domain vocabulary still aligned with `prompts/` source-of-truth files? Reconcile any drift.

**Release-cadence rule (added 2026-05-06 — see ROADMAP.md):** Each milestone closes with a release ceremony to Hex.pm before the next milestone implementation starts. Convention: a `Phase X.5` numbered between the last feature phase of milestone N and the first feature phase of milestone N+1 (e.g. Phase 44.5 between v1.1 and v1.2). The 4-milestone-deep gap that accumulated between `v0.3.2` and `1.0.0` (v0.5 + v0.6 + v1.0 + v1.1 all unreleased on Hex while milestone planning labels marched forward) is the failure mode this rule prevents. Milestone "shipped" status now requires both planning-archive completion AND Hex publish — not just one.

---
*Last updated: 2026-08-21 after opening v2.7 Repository Stewardship & Operational Hygiene.*
<!-- prior footer: 2026-07-31 after v2.2 milestone archive. Audit passed 20/20 requirements, 8/8 integration seams, and 6/6 end-to-end flows; next milestone not yet defined. -->
<!-- prior footer: 2026-07-28 — v2.2 opened (phases 141-144), 2026-07-28 remediation shipped as 2.1.3 / 2.1.3 / 2.1.1 and marked delivered. -->
<!-- prior footer: 2026-07-08 after v2.1 milestone archive. v2.1 Postgres + Admin URL Hardening shipped with audit `status: passed`; next milestone not opened. -->
<!-- prior footer: 2026-06-28 — v1.14 Phase 122 (Preview surface redesign) complete, verifier `passed` (PREV-01). v1.14 Operator IA & Lived-Experience Redesign in progress (the 4th admin-UI quality pass; top-down JTBD/IA-led + adversarial persona-critic method; adopts phoenix_storybook dev-only; ships to Hex). Previous milestone **v1.13 Admin Design-System Stress Test & UX Uplift (v3)** SHIPPED 2026-06-21 — live at **1.8.0 / 1.8.0 / 1.5.0**, audit `status: passed` (41/41, 9 phases), now fully archived (phase dirs in `milestones/v1.13-phases/`).* -->
