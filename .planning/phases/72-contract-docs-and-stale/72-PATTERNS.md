# Phase 72: Contract Docs and Stale-Claim Guards - Pattern Map

**Mapped:** 2026-06-02
**Files analyzed:** 11 (8 modified docs/tests/task + 1 package metadata + 1 publish summary regenerated + 1 test file)
**Analogs found:** 11 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/jobs.md` | documentation | transform | `guides/compatibility-and-deprecations.md` | role-match |
| `guides/compatibility-and-deprecations.md` | documentation | transform | `mailglass_inbound/docs/api_stability.md` | role-match |
| `MAINTAINING.md` | documentation | transform | `guides/jobs.md` | role-match |
| `lib/mix/tasks/mailglass.docs.check.ex` | mix task (token rules) | request-response | self (existing `@tier1_surface_rules`) | exact |
| `test/mailglass/docs_contract_test.exs` | test | request-response | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | exact |
| `test/mailglass/stability_contract_test.exs` | test | request-response | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | role-match |
| `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | test | request-response | `test/mailglass/docs_contract_test.exs` | exact |
| `mailglass_inbound/mix.exs` | config/package metadata | transform | `mix.exs` (root) | role-match |
| `.planning/publish/mailglass_inbound-publish-summary.json` | publish artifact | transform | regenerated via `mix mailglass.publish.check` | N/A — do not hand-edit |
| `mailglass_inbound/README.md` | documentation | transform | `README.md` (root) | role-match |
| `mailglass_inbound/docs/api_stability.md` | documentation | transform | `docs/api_stability.md` (root) | exact |

---

## Pattern Assignments

### `lib/mix/tasks/mailglass.docs.check.ex` (mix task, token rules)

**Analog:** self — `lib/mix/tasks/mailglass.docs.check.ex`

This is the primary proof seam. The task checks `required:` and `forbidden:` token lists per file path. The pattern is: entries in `@tier1_surface_rules` for the target file path, modified in-place.

**Current stale required token for `"README.md"` — lines 71-86:**
```elixir
@tier1_surface_rules %{
  "README.md" => %{
    required: [
      "docs/api_stability.md",
      "guides/compatibility-and-deprecations.md",
      "guides/upgrading-to-v1_0.md",
      "mix mailglass.install",
      "mailglass_inbound` is outside the `v1.x` stability promise"   # <-- STALE: must be removed
    ],
    forbidden: [
      "~> 0.1",
      "~> 0.2",
      "verify.phase_07",
      "v0.1 in development",
      "v0.3 public surface"
    ]
  },
```

**Action — replace the stale `required:` entry with tokens already present in the corrected README:**
```elixir
"README.md" => %{
  required: [
    "docs/api_stability.md",
    "guides/compatibility-and-deprecations.md",
    "guides/upgrading-to-v1_0.md",
    "mix mailglass.install",
    "**`mailglass_inbound`** (inbound routing; stable 1.0)",
    "`mailglass_inbound` has its own stable `1.0` contract inventory"
  ],
  forbidden: [
    "~> 0.1",
    "~> 0.2",
    "verify.phase_07",
    "v0.1 in development",
    "v0.3 public surface",
    "mailglass_inbound` is outside the `v1.x` stability promise"   # <-- move here as forbidden
  ]
},
```

**Note on the two new `required:` tokens:** `docs_contract_test.exs` lines 43-44 already assert these exact strings are in README.md (Phase 71 put them there). Moving the stale phrase from `required:` to `forbidden:` makes `mix mailglass.docs.check` green on the corrected README and red on any future regression.

**Action — add `forbidden:` entry for compatibility guide — lines 251-264:**
```elixir
"guides/compatibility-and-deprecations.md" => %{
  required: [
    "stable lane",
    "compatibility lane",
    "warnings-as-errors",
    "mailglass_inbound",
    "mailglass_inbound/docs/api_stability.md",
    "Reachability is not a compatibility promise.",
    "## Inbound deprecation-DX inventory",
    "Support-until horizon",
    "Proof artifact",
    "independent `1.0` contract"   # <-- add: assert corrected support matrix posture
  ],
  forbidden: [
    "Phase 37",
    "v0.1 in development",
    "excluded from the `1.x` compatibility promise"   # <-- add: pin the stale phrase as forbidden
  ]
},
```

**How the tier1 engine works — lines 493-513 (copy this pattern, do not re-implement):**
```elixir
defp tier1_surface_issues(paths) do
  selected_paths = MapSet.new(paths)

  @tier1_surface_rules
  |> Enum.filter(fn {path, _rules} -> MapSet.member?(selected_paths, path) end)
  |> Enum.flat_map(fn {path, rules} ->
    content = File.read!(path)

    required_issues =
      Enum.flat_map(rules.required, fn token ->
        if String.contains?(content, token), do: [], else: [{:missing, path, token}]
      end)

    forbidden_issues =
      Enum.flat_map(rules.forbidden, fn token ->
        if String.contains?(content, token), do: [{:stale, path, token}], else: []
      end)

    required_issues ++ forbidden_issues
  end)
end
```

---

### `test/mailglass/docs_contract_test.exs` (test, string assertion pattern)

**Analog:** `test/mailglass/docs_contract_test.exs` — self, lines 356-363

**Current stale test — lines 356-363:**
```elixir
test "freshness stamp and inbound stability boundary are present" do
  jobs = File.read!("guides/jobs.md")

  assert jobs =~ "Current as of 2026-05-23"
  assert jobs =~ "mailglass` and `mailglass_admin`"
  assert jobs =~ "outside the"
  assert jobs =~ "`v1.x` stability promise"
end
```

**Replacement pattern (flip stale asserts to refutes, add stable-1.0 asserts):**
```elixir
test "freshness stamp and inbound stability boundary are present" do
  jobs = File.read!("guides/jobs.md")

  assert jobs =~ "Current as of 2026-06-02"
  assert jobs =~ "mailglass` and `mailglass_admin`"
  assert jobs =~ "independent stable `1.0` contract"
  assert jobs =~ "mailglass_inbound/docs/api_stability.md"
  refute jobs =~ "outside the `v1.x` stability promise"
end
```

**Structural convention — how other assert/refute blocks in this file are written (lines 36-51):**
```elixir
assert readme =~ "docs/api_stability.md"
assert readme =~ "guides/compatibility-and-deprecations.md"
assert readme =~ "**`mailglass_inbound`** (inbound routing; stable 1.0)"
assert readme =~ "`mailglass_inbound` has its own stable `1.0` contract inventory"
refute readme =~ "v0.1 in development"
refute readme =~ "`mailglass_inbound` is outside the `v1.x` stability promise"
```

**File-read convention:** `File.read!("path/relative/to/project/root")` — no `Path.expand`. All root-test paths are relative to the project root (no `__DIR__` prefixes). Inbound test files use `Path.expand("../../...", __DIR__)` — that distinction is structural, not cosmetic.

**Partial coverage gap — MAINTAINING.md step 5:** The existing `"MAINTAINING.md pins the required versus advisory verification contract"` test (lines 171-202) covers many MAINTAINING tokens but does not assert the corrected JTBD step 5 wording. After editing `MAINTAINING.md`, add an assertion inside this existing test:

```elixir
# Add to existing test at line ~196, alongside the other assert maintaining lines:
refute maintaining =~ "while it remains outside the `v1.x`"
assert maintaining =~ "independent `1.0` contract"
```

---

### `test/mailglass/stability_contract_test.exs` (test, JSON parsing + string assert)

**Analog:** `test/mailglass/stability_contract_test.exs` — self, lines 116-146

**Current exact-version test block — lines 116-146:**
```elixir
test "inbound 1.0 release preflight truth is exact across source and publish evidence" do
  manifest = json!(".release-please-manifest.json")
  summary = json!(".planning/publish/mailglass_inbound-publish-summary.json")
  inbound_mix = File.read!("mailglass_inbound/mix.exs")
  # ...
  assert summary["source_ref"] == "v#{expected_version}"
  # source_ref_pattern is NOT currently asserted ← gap to fill
end
```

**Add `source_ref_pattern` assertion to this block after the publish summary is regenerated:**
```elixir
assert summary["source_ref_pattern"] == "mailglass_inbound-v%{version}"
```

**JSON parsing helper pattern — lines 26 (reuse, do not add a second helper):**
```elixir
defp json!(path), do: path |> File.read!() |> Jason.decode!()
```

**Regex-pattern assertion convention (ceremony-agnostic) — lines 94, 105:**
```elixir
assert manifest =~ ~r/"mailglass_inbound": "\d+\.\d+\.\d+"/
assert inbound_mix =~ ~r/\{:mailglass, "== \d+\.\d+\.\d+"\}/
```
Use exact-value assertions only for known-stable release facts (like `expected_version = "1.0.0"`). Use `~r/...` patterns for values that change each ceremony.

---

### `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (test, string assertion)

**Analog:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` — self

**Path convention — lines 4-14 (all paths via `Path.expand` relative to `__DIR__`):**
```elixir
@readme_path Path.expand("../../README.md", __DIR__)
@stability_path Path.expand("../../docs/api_stability.md", __DIR__)
@compatibility_path Path.expand("../../../guides/compatibility-and-deprecations.md", __DIR__)
```

**Existing `"adoption path and compatibility routing stay canonical"` test — lines 475-524:** This test already asserts `compatibility =~ "mailglass_inbound/docs/api_stability.md"` and other tokens. After editing `guides/compatibility-and-deprecations.md`, verify this test still passes without changes. The tokens it pins must survive the compatibility guide edit:

```elixir
# These must remain present after Phase 72 compatibility guide edits:
assert compatibility =~ "mailglass_inbound/docs/api_stability.md"
assert compatibility =~ "stable/internal/deferred source"
assert compatibility =~ "Reachability is not a compatibility promise."
assert compatibility =~ "## mailglass_inbound compatibility"
assert compatibility =~ "## Inbound deprecation-DX inventory"
assert compatibility =~ "| Surface | Bridge or replacement | Warning or migration channel | `--warnings-as-errors` impact | Support-until horizon | Proof artifact |"
```

**Coverage gap — DX inventory support-until horizon wording:** The existing test checks routing tokens but does not assert the corrected "Through `mailglass_inbound` `1.x`" horizon wording. If the planner wants a guard here, add inside `"adoption path and compatibility routing stay canonical"`:

```elixir
refute compatibility =~ "Through `mailglass_inbound` `0.x`"
assert compatibility =~ "Through `mailglass_inbound` `1.x`"
```

**`refute_over_claims!/1` guard (lines 581-604) — already running on compatibility text:** The `"stable/adoption prose forbids over-claims"` test passes `readme_active` through `refute_over_claims!/1`, which includes this regex:

```elixir
refute Regex.match?(
  ~r/mailglass_inbound.*1\.x.*(stability|stable|compatibility)/i,
  claim_scope
)
```
The replacement wording "independent `1.0` contract" avoids the `1.x` + stability combo that this guard flags, so it will pass without changes. Do not use "part of the `1.x` stability" in replacement wording.

---

### `mailglass_inbound/mix.exs` (config, package metadata)

**Analog:** `mailglass_inbound/mix.exs` — self, lines 118-130

**Current stale `source_ref_pattern` — lines 118-130:**
```elixir
defp package do
  [
    name: "mailglass_inbound",
    licenses: ["MIT"],
    description: @description,
    source_ref_pattern: "mailglass-sibling-group-v%{version}",   # <-- STALE
    links: %{
      "GitHub" => @source_url,
      "HexDocs" => "https://hexdocs.pm/mailglass_inbound"
    },
    files: ~w(lib docs priv .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
  ]
end
```

**Corrected value:**
```elixir
source_ref_pattern: "mailglass_inbound-v%{version}",
```

**`source_ref` in `docs/0` (line 136) is already correct and must not change:**
```elixir
source_ref: "v" <> @version,   # stays as-is: "v1.0.0"
```

**After editing `mix.exs`:** Run `mix mailglass.publish.check --package mailglass_inbound` to regenerate `.planning/publish/mailglass_inbound-publish-summary.json`. Do not hand-edit the JSON — the task writes canonical output including checksums.

---

### `guides/jobs.md` (documentation)

**Analog:** `guides/compatibility-and-deprecations.md` (same repo, same correction style)

**Stale header — lines 3-6 (exact current text):**
```markdown
> **Current as of 2026-05-23.** This guide covers the shipped, `v1.x`-stable
> jobs in `mailglass` and `mailglass_admin`. Inbound mail
> (`mailglass_inbound`) is summarized near the end, but it remains **outside the
> `v1.x` stability promise** for now.
```

**Replacement direction (D-01, D-03, D-16):** Update date to `2026-06-02`. Replace inbound stability note. Keep one-sentence summary style. Example:
```markdown
> **Current as of 2026-06-02.** This guide covers the shipped, `v1.x`-stable
> jobs in `mailglass` and `mailglass_admin`. `mailglass_inbound` is summarized
> near the end; it has its own independent stable `1.0` contract documented in
> `mailglass_inbound/docs/api_stability.md`.
```

**Stale footer paragraph — lines 416-419 (exact current text):**
```markdown
Today it ships verified ingress for Postmark and SendGrid, and the repo's v1.2
work is expanding that surface with more provider, operator, testing, and docs
maturity. It is real, useful, and shipping, but it is still **outside the
`v1.x` stability promise**. Treat it as production-capable and still hardening.
```

**Replacement direction (D-01, D-16 — two sentences max):** Keep spirit (brief what-it-does + routing), correct stability claim. Example:
```markdown
`mailglass_inbound` `1.0.0` ships its own independent stable `1.0` contract —
verified ingress, replayable storage, async execution, and operator tooling —
documented in [`mailglass_inbound/docs/api_stability.md`](../mailglass_inbound/docs/api_stability.md).
```

**Voice pattern (from CLAUDE.md):** Calm, exact, maintainer-like. "Small honest surfaces beat broad claims." No superlatives.

---

### `guides/compatibility-and-deprecations.md` (documentation)

**Analog:** `guides/compatibility-and-deprecations.md` — self, existing support matrix rows for comparison

**Stale support matrix row — line 166:**
```markdown
| `mailglass_inbound` | excluded from the `1.x` compatibility promise in this milestone | `README.md`, `docs/api_stability.md` |
```

**Replacement (D-02, D-03, RESEARCH.md Example 1):**
```markdown
| `mailglass_inbound` | independent `1.0` contract; see `mailglass_inbound/docs/api_stability.md` | `mailglass_inbound/docs/api_stability.md` |
```

**Stale support-until horizons — lines 217-219 (three table rows, same cell text each):**
```markdown
Through `mailglass_inbound` `0.x`; semantic break requires a major release position decision
```

**Replacement (D-02, RESEARCH.md Example 2 — parallels the core/admin major-release language):**
```markdown
Through `mailglass_inbound` `1.x`; semantic break requires a deprecation bridge or a `mailglass_inbound` major-version change
```

**"What this guide does not promise" section — line 225:** Currently says:
```markdown
- support for `mailglass_inbound` within the `1.x` contract covered here
```
This reads as "inbound is not stable" even though it is technically accurate (this guide covers core/admin). Per the open question in RESEARCH.md, rephrase to clarify:
```markdown
- `mailglass_inbound`'s contract within the `mailglass` / `mailglass_admin` `1.x` line covered here; `mailglass_inbound` has its own independent contract documented in `mailglass_inbound/docs/api_stability.md`
```

**Tokens that must survive the edit (inbound docs_contract_test.exs pins these):**
- `"mailglass_inbound/docs/api_stability.md"`
- `"stable/internal/deferred source"`
- `"Reachability is not a compatibility promise."`
- `"## mailglass_inbound compatibility"`
- `"## Inbound deprecation-DX inventory"`
- The full DX inventory header row string

---

### `MAINTAINING.md` (documentation)

**Analog:** `MAINTAINING.md` — self, lines 110-123

**Stale step 5 text — lines 117-118:**
```markdown
   - keep inbound summarized separately while it remains outside the `v1.x`
     promise
```

**Replacement (D-01, D-03):**
```markdown
   - keep inbound summarized separately, noting its own independent `1.0`
     contract and routing readers to `mailglass_inbound/docs/api_stability.md`
```

**Tokens that docs_contract_test.exs `"MAINTAINING.md pins"` test (lines 171-202) asserts must survive the edit:**
- `"JTBD Docs Refresh Protocol"`
- `"guides/jobs.md"`
- `"Always refresh the internal map first"`
- `"guides/compatibility-and-deprecations.md"`

---

### `.planning/publish/mailglass_inbound-publish-summary.json` (publish artifact)

**Not hand-edited.** Regenerate with:
```sh
mix mailglass.publish.check --package mailglass_inbound
```

After regeneration the JSON will have the corrected `source_ref_pattern`. The `stability_contract_test.exs` exact-version test will then pass with the new `source_ref_pattern` assertion added.

---

## Shared Patterns

### String Assertion Convention (ExUnit)
**Source:** `test/mailglass/docs_contract_test.exs` and `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
**Apply to:** All test file changes

The established idiom in this repo:
```elixir
# Assert presence of correct token
assert doc =~ "exact token string"

# Assert absence of stale token  
refute doc =~ "stale phrase"

# Regex for ceremony-agnostic patterns
assert doc =~ ~r/pattern with \d+ capture/
```
Never assert by message string (per CLAUDE.md "Don't pattern-match errors by message string"). Match structures and tokens.

### Mix Task Token Rule Convention
**Source:** `lib/mix/tasks/mailglass.docs.check.ex` lines 70-426
**Apply to:** `@tier1_surface_rules` changes only

Pattern: add entries to `required:` list for tokens that must be present in the corrected doc, and to `forbidden:` list for stale phrases that must be absent. Both lists are plain string tokens checked via `String.contains?/2`. No regex in tier1 rules — use `preview_boundary_issues/1` or `trust_boundary_issues/1` patterns for regex-based checks.

### Docs Voice
**Source:** `CLAUDE.md` "Brand & Voice" section + `prompts/mailglass-brand-book.md`
**Apply to:** All Markdown file edits

- Specific, calm, exact: "has its own independent stable `1.0` contract" not "is now stable!"
- Route to canonical source rather than restating inventory: "see `mailglass_inbound/docs/api_stability.md`"
- Small honest surfaces beat broad claims (D-16)
- Do not use `1.x` to describe inbound's contract — use `1.0` or `1.0+`

### Avoid `refute_over_claims!` Trigger
**Source:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` lines 581-604
**Apply to:** All replacement wording

The `refute_over_claims!/1` helper rejects:
```elixir
~r/mailglass_inbound.*1\.x.*(stability|stable|compatibility)/i
```
Replacement wording using `1.0` instead of `1.x` for inbound's own contract avoids this guard. Using `1.x` for the core/admin group (which is correct) is fine because the guard fires only when `mailglass_inbound` and `1.x` and `stability/stable/compatibility` appear together in one paragraph. The claim_scope carve-out already handles "the `1.x` stability promise applies to `mailglass` + `mailglass_admin` only".

---

## No Analog Found

No files in this phase lack an analog. All changes are in-place edits of existing files using established patterns.

---

## Metadata

**Analog search scope:** Root test/, lib/mix/tasks/, guides/, mailglass_inbound/test/, mailglass_inbound/mix.exs, mailglass_inbound/docs/
**Files scanned:** 11 primary files read in full
**Pattern extraction date:** 2026-06-02
