# Phase 105: Onboarding Docs — Quickstart Fix + Learning Arc - Context

**Gathered:** 2026-06-17 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the first hour frictionless via docs-only changes, all gated by
`test/mailglass/docs_contract_test.exs`:

1. **DOCS-01** — fix the broken README quickstart so it is config-first and a copy-paste
   cannot `ConfigError`.
2. **DOCS-02** — end `guides/getting-started.md` on a "Next steps" first-week arc instead of
   on installer troubleshooting (and fold in Phase 104's `--force`/fail-closed/doctor prose).
3. **DOCS-03** — add a discoverable learning-path/index over the existing guides.
4. **DOCS-04** — reopen `guides/migration-from-swoosh.md` with the "Swoosh = transport;
   mailglass = the framework layer" value pitch before the incremental-adoption mechanics.

**Confined to:** docs/markdown (`README.md`, `guides/*.md`), the docs registration in
`mix.exs` (`extras:` + `groups_for_extras: [Guides: …]`), and the docs-contract test +
helpers (`test/mailglass/docs_contract_test.exs`, `test/support/docs_helpers.ex`). NO product
code, runtime-contract, schema, public-error-set, or installer/admin code changes (those are
Phases 104/107). This is friction-removal, not feature growth (D-23 convergence holds).
</domain>

<decisions>
## Implementation Decisions

### DOCS-01 — README Quickstart Goes Config-First
- **D-01:** Insert a config-first block into the README "Quickstart" section
  (`README.md:86-122`) BEFORE the `Mailglass.deliver()` example, so a literal copy-paste of the
  Quickstart cannot raise `ConfigError`. Today the Quickstart jumps from `mix mailglass.install`
  straight to a mailable + `Mailglass.deliver()` with no `config :mailglass, repo:/adapter:`
  block in between.
- **D-02:** Reuse the WORKING config snippet from `guides/getting-started.md:24-32` verbatim
  (`config :mailglass, repo:, adapter: {Mailglass.Adapters.Swoosh, ...}`). Do not invent a new
  config shape — keep the two surfaces identical so they can't drift.
- **D-03:** Frame the config block honestly (Honest-Surface lens): the installer already writes
  a `config/runtime.exs` block (`README.md:79-84` says so), so present the Quickstart config as
  "the installer wrote this — confirm your repo + adapter," not as a separate manual step the
  installer didn't do.
- **D-04:** Add a NEW `docs_contract_test.exs` assertion that the README contains a
  `config :mailglass` block with `repo:` and `adapter:` — mirror the existing getting-started
  "Config examples are valid" test (`docs_contract_test.exs:108-114`). This is what DOCS-01's
  "validated by `docs_contract_test.exs`" requires; the current README tests only check the
  mailable block parses, not that config is present.

### DOCS-02 — getting-started Ends on a "Next steps" Arc
- **D-05:** `guides/getting-started.md` currently ENDS on "## Troubleshooting the Installer"
  (lines 89-104). Reorder so the guide ENDS on a new `## Next steps` section. Keep the
  troubleshooting content but place it before Next steps (requirement: "instead of ending on
  installer troubleshooting").
- **D-06:** The "Next steps" section sequences the natural first-week path per DOCS-02:
  jobs → authoring-mailables → preview → webhooks → testing → operate, each linking the existing
  guide. Point the arc at the canonical `guides/learning-path.md` (D-08) so the ordering lives
  in one place.
- **D-07:** Update the existing "Webhooks return 401 after installation" troubleshooting entry
  to reflect Phase 104's NEW fail-closed behavior: `mix mailglass.install` now fails closed on an
  unmanaged `Plug.Parsers` conflict, with a `--force` escape hatch and a `mix mailglass.doctor`
  webhook-wiring check. Phase 104 explicitly handed this guide-prose half to Phase 105 (see
  104-CONTEXT.md D-06 and Deferred Ideas). Keep error vocabulary canonical
  (`docs/api_stability.md`); do not over-claim.

### DOCS-03 — New Canonical `guides/learning-path.md`, Registered in Both Docs Lists
- **D-08:** Create a standalone `guides/learning-path.md` as the ordered first-week arc — the
  single source of truth for the learning sequence that HexDocs surfaces. (Requirement allows
  "a new guides/learning-path.md AND/OR a restructured README index"; standalone guide chosen so
  HexDocs gets a real index page and so the v1.12 "new guides registered in BOTH" guardrail
  applies cleanly.)
- **D-09:** Register `guides/learning-path.md` in BOTH `mix.exs` `extras:` (the list at
  ~383-400) AND `groups_for_extras: [Guides: …]` (~413-427) — mandatory per the v1.12 docs
  guardrail. Place it early in the Guides group (it is the index/entry arc). Keep
  `main: "getting-started"` unchanged.
- **D-10:** Link `guides/learning-path.md` from the README "## Documentation" index
  (`README.md:249-271`) and from getting-started's Next steps (D-06). Keep the README index a
  flat link list pointing at the canonical arc — do NOT duplicate the ordered sequence in the
  README (Honest-Surface: avoid two copies of the arc that can drift).

### DOCS-04 — migration-from-swoosh Opens With the Value Pitch
- **D-11:** Add a new opening "why" section at the TOP of `guides/migration-from-swoosh.md`
  (before the current line-3 "This guide is now a subordinate raw-Swoosh migration reference"
  deferral). The pitch: "Swoosh handles transport; mailglass adds the framework layer you'd
  otherwise rebuild — preview, webhooks, audit ledger, suppressions, multi-tenancy." Keep the
  subordinate-reference framing and the canonical-lane pointers
  (`upgrading-to-v1_0.md`, `compatibility-and-deprecations.md`) AFTER the pitch — do not delete
  them, do not contradict them.
- **D-12:** Add a NEW `docs_contract_test.exs` assertion that the value-prop opener keywords are
  present in `migration-from-swoosh.md` AND appear before the incremental-adoption mechanics
  (e.g. before the "subordinate" framing or the first `## 1)` heading).
- **D-13:** Fix the stale dep pins in the same guide: `migration-from-swoosh.md:26-27` still
  pin `{:mailglass, "~> 0.3"}` / `{:mailglass_admin, "~> 0.3"}`. Bump to the current `~> 1.x`
  major.minor line. This is correcting the file the phase is already editing as an onboarding
  surface (not new scope); the dynamic README-pin test does not cover this guide today.

### Claude's Discretion (planner decides)
- Exact wording of the new docs-contract assertions, and whether learning-path discoverability
  is asserted via file existence, a `mix.exs`-registration check, or a README-link check.
- Whether DOCS-04's "appears before mechanics" assertion uses a heading-position regex or a
  byte-offset comparison.
- Exact "Next steps" prose and link order, as long as it covers the DOCS-02 sequence.
- The exact heading text for the new sections — BUT new fenced code blocks that must be
  contract-extracted have to sit under a `##` (exactly two-hash) heading, because
  `extract_block_after_heading/2` (`docs_helpers.ex`) matches `##` only.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `README.md` — Quickstart (86-122, the broken config-less block), Installation (57-84, notes
  the installer generates `config/runtime.exs`), Documentation index (249-271)
- `guides/getting-started.md` — working config snippet (22-32, the source for DOCS-01), §4 send
  example (57-78), installer troubleshooting (89-104, must reorder + update for 104 behavior)
- `guides/migration-from-swoosh.md` — current subordinate-deferral opener (1-11), stale `~> 0.3`
  pins (26-27), canonical-lane pointers (84-87)
- `guides/jobs.md` — the JTBD ramp-up guide the DOCS-02 "Next steps" arc sequences toward;
  stamped "Current as of 2026-06-02" and contract-tested (do not break its markers)
- `test/mailglass/docs_contract_test.exs` — THE gate. Existing README/getting-started/config
  assertions (5-114) are the patterns to mirror for the new DOCS-01/02/04 assertions. Add new
  tests here.
- `test/support/docs_helpers.ex` — `extract_code_blocks/1` (any elixir/bash/sql fence) and
  `extract_block_after_heading/2` (matches `##` headings ONLY) — the extraction contract that
  constrains how new sections must be structured to be testable.
- `mix.exs` — `extras:` (383-400) and `groups_for_extras: [Guides: …]` (407-427); learning-path
  must be registered in BOTH. `main: "getting-started"` (357).
- `.planning/REQUIREMENTS.md` — DOCS-01..04 acceptance criteria (49-58) and v1.12 docs guardrails
- `.planning/phases/104-installer-fail-closed-webhook-wiring-doctor/104-CONTEXT.md` — the
  fail-closed / `--force` / `mix mailglass.doctor` behavior the DOCS-02 troubleshooting prose
  must describe accurately (D-06 there hands the guide half to this phase)
- `guides/compatibility-and-deprecations.md`, `guides/upgrading-to-v1_0.md` — canonical
  compatibility/upgrade lanes the migration guide defers to; the DOCS-04 opener must not
  contradict them
- `docs/api_stability.md` — canonical telemetry/error vocabulary for the troubleshooting prose
- `.planning/METHODOLOGY.md` — active lenses: Decisive-By-Default, Honest Surface Area,
  Recommendation-First Synthesis
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The working config block in `guides/getting-started.md:24-32` is the verbatim source for the
  README config-first fix (D-02) — already contract-validated, so reuse prevents drift.
- The docs-contract test already has the exact assertion patterns to mirror: README
  `File.read! =~ "..."` string checks (14-52), `extract_code_blocks/1` + `Code.string_to_quoted`
  parse checks (54-61), and `extract_block_after_heading/2` config check (108-114).
- `mix.exs` `extras:` + `groups_for_extras: [Guides: …]` is an established, ordered list — adding
  one entry to each is a mechanical, well-precedented change (every prior guide did it).

### Established Patterns
- Every new/edited guide is gated by `docs_contract_test.exs`; new guarantees land as new
  assertions in that file. Code blocks are extracted with `Regex.scan` over ```` ```elixir|bash|sql ````
  fences, and heading-scoped blocks require `##` (two-hash) headings.
- New guides are registered in BOTH `mix.exs` lists (v1.12 docs guardrail; the contract enforces
  it via the docs.check task elsewhere). Canonical telemetry/error vocabulary from
  `docs/api_stability.md`. No over-claims (Honest-Surface lens).
- Docs-only commits are release-safe under release-please defaults (`docs:` type).

### Integration Points
- README Quickstart config block → reuses getting-started config → new contract assertion.
- getting-started "Next steps" → links existing guides + canonical `learning-path.md`; updated
  troubleshooting entry → describes Phase 104's installed `--force`/doctor behavior.
- `guides/learning-path.md` → `mix.exs` extras + groups_for_extras (Guides) → README index +
  getting-started Next steps point to it.
- migration-from-swoosh new opener → new contract assertion for value-prop keyword presence +
  ordering; stale-pin fix.
</code_context>

<specifics>
## Specific Ideas

- The README Quickstart fix must be config-FIRST: the config block precedes the mailable +
  `Mailglass.deliver()` example, because `Mailglass.deliver()` without `config :mailglass` is
  exactly the `ConfigError` DOCS-01 targets.
- learning-path.md is the single source of truth for the first-week ordering; README index and
  getting-started Next steps LINK to it rather than re-listing the sequence (no dual maintenance).
- The DOCS-04 opener restates the value pitch but must not delete or weaken the existing
  subordinate-reference framing / canonical-lane pointers that the compatibility tests depend on
  (`docs_contract_test.exs:227-248` references upgrading/compat guides).
- Heading discipline: any new code block that a new contract assertion locates by heading must
  use a `##` heading, or `extract_block_after_heading/2` returns nil.
</specifics>

<deferred>
## Deferred Ideas

- Day-2 runbooks (`production-go-live-checklist.md`, unified `errors-and-troubleshooting.md`) —
  Phase 106 (OPS-01/02). 105 and 106 serialize because both touch `mix.exs` docs lists +
  `docs_contract_test.exs`.
- Inbound replay-modal a11y parity — Phase 107 (A11Y-01), independent admin-UI work.
- The actual Hex release + D-13 inbound exact-pin re-pin — Phase 108 (REL-01/02).
- Broader guide-content rewrites beyond the four DOCS items (e.g. restructuring webhooks.md or
  testing.md) — out of scope; this phase is the quickstart + arc + swoosh-why slice only.

### Reviewed Todos (not folded)
None — `todo.match-phase` returned 0 matches for Phase 105.
</deferred>
