# Phase 167: Truthful Documentation and the Standing Control - Pattern Map

**Mapped:** 2026-09-18
**Files analyzed:** 12 (6 code/config artifacts scoped by the caller; 6 prose-only files noted but not pattern-mapped)
**Analogs found:** 6 / 6 in-scope code/config artifacts

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/mailglass/docs_contract_test.exs` (3 new `describe` blocks: CLAUDE.md, CONTRIBUTING.md, MAINTAINING.md) | test | transform (source-text assertion) | same file's own `describe "README.md contract"` (lines 14-69) and stale-pin guard (lines 550-558) | exact — self-analog |
| `test/mailglass/docs_contract_test.exs` (DOCS-04: migration-from-swoosh dynamic pin) | test | transform | same file's `dependency_constraint!`/`package_major_minor!`/`current_compatibility_section!` helpers (lines 1049-1074) | exact — self-analog |
| NEW script/task pinning DOCS-01 (STATE.md PR/issue refs vs live `gh` state) | utility / mix task | event-driven (scheduled audit, advisory) | `dev/mix/tasks/mailglass.repo.hygiene.ex` (552 lines) + `.github/workflows/repo-hygiene.yml` + `scripts/scheduled_control_evidence.sh` | role-match — closest real precedent in the repo, not exact (new domain: STATE.md prose vs `gh`, not git/CI state) |
| `test/mailglass/config_test.exs` (`css_inliner: :none` acceptance → `assert_raise`) | test | CRUD (validation) | same file's adjacent `:invalid_backend` case (lines 30-34) | exact — before/after pair in the same file |
| `lib/mailglass/config.ex` (narrow `css_inliner` type) | config / schema | CRUD (validation) | same file's own NimbleOptions schema idiom (surrounding `renderer:` subtree, lines 79-95) | exact — self-analog |
| `.github/dependabot.yml` (add `groups:` + `open-pull-requests-limit` to 3 `mix` entries) | config | batch (scheduled, GitHub-native) | itself (current file, verbatim below) — no in-repo Dependabot grouping precedent exists | no analog — pure GitHub-native YAML addition |
| `.github/workflows/release-please.yml` (extend sed resync loop to `guides/migration-from-swoosh.md`) | CI/infra config | batch (release-time text sync) | same file's existing sed resync step (lines 400-499) | exact — self-analog, extend the loop |

## Pattern Assignments

### `test/mailglass/docs_contract_test.exs` — three new `describe` blocks (DOCS-02, DOCS-03)

**Analog:** the file's own `describe "README.md contract"` block and helper functions. Read in full this session (1093 lines); no re-read needed.

**Module header / import idiom** (lines 1-12):
```elixir
defmodule Mailglass.DocsContractTest do
  use ExUnit.Case, async: true

  # Completing milestone v2.7 moves the Phase 164 directory into
  # `.planning/milestones/v2.7-phases/`. These documents are byte-identical either
  # side of that move, so the guide contract follows it instead of going red when the
  # milestone it documents is archived.
  @phase_164_dir Mailglass.TestSupport.PhaseArtifacts.relative!(
                   File.cwd!(),
                   ".planning/phases/164-repository-truth-reconciliation-and-closeout"
                 )
  import Mailglass.DocsHelpers

  describe "README.md contract" do
    test "..." do
      ...
```
- Path-to-repo-root resolution: **none needed** — tests call `File.read!("CLAUDE.md")` etc. with paths relative to the repo root directly (ExUnit runs `mix test` from repo root; no `Path.expand`/`__DIR__` gymnastics anywhere in this file). New `describe` blocks should do the same: `File.read!("CLAUDE.md")`, `File.read!("CONTRIBUTING.md")`, `File.read!("MAINTAINING.md")`.
- `import Mailglass.DocsHelpers` (from `test/support/docs_helpers.ex`) brings in `extract_code_blocks/1` and `extract_block_after_heading/2` — not needed for the new blocks (they do plain source-text `assert`/`refute`), but the import is already active file-wide.

**`assert`/`refute` source-text drift-guard shape** (lines 550-558, the exact idiom to copy for CLAUDE.md/CONTRIBUTING.md/MAINTAINING.md one-liner corrections):
```elixir
      # Stale pins are fixed and the current 2.x pin is present (positive assertion so
      # deleting the dep block or pinning to some other wrong version cannot pass).
      refute migration =~ "~> 0.3", "migration-from-swoosh.md still contains stale ~> 0.3 pin"

      refute migration =~ ~r/~>\s*1\.6/,
             "migration-from-swoosh.md still contains stale ~> 1.6 pin"

      assert migration =~ ~r/~>\s*2\.5/,
             "migration-from-swoosh.md must pin the current ~> 2.5 series"
```
Apply the same `refute <var> =~ "<stale string>", "<file> still contains <defect>"` + `assert <var> =~ "<corrected string or regex>", "<file> must state <correction>"` pairing for each Defect Ledger row. Example shape for the new `describe "CLAUDE.md contract"` block (per RESEARCH.md's own recommendation, lines 169-171):
```elixir
  describe "CLAUDE.md contract" do
    test "sibling pin guidance matches the current ~> convention, not the stale == pin" do
      claude = File.read!("CLAUDE.md")
      refute claude =~ ~s({:mailglass, "== <version>"}),
             "CLAUDE.md still describes the stale exact-pin re-pin dance"
      assert claude =~ "~>",
             "CLAUDE.md must describe the current ~> pin convention"
    end

    test "auto-merge claim matches the real disarmed + protected-dispatch mechanism" do
      claude = File.read!("CLAUDE.md")
      refute claude =~ "auto-merges on green",
             "CLAUDE.md still claims plain auto-merge, contradicting the disarmed step"
    end
  end
```
(Exact wording of asserted strings should track whatever prose the executor lands, per RESEARCH.md's Defect Ledger — the pattern shown here is the *shape*, not the literal text to paste.)

**Scoped `refute` to avoid a false positive on a legitimate unrelated occurrence** (RESEARCH.md DOCS-03 note, applies to CONTRIBUTING.md's `fix(inbound):` example at line 161): do not blanket-`refute contributing =~ "fix(inbound):"` — scope to the specific stale sentence, e.g. `refute contributing =~ "requires a deliberate fix(inbound):"`. This is the same "scope the assertion narrowly, don't blanket-match a common substring" discipline already visible in how `dependency_constraint!` regexes anchor on `\{:#{dependency},` rather than a bare version string.

**Dynamic (non-hardcoded) pin idiom — reuse verbatim for DOCS-04 and the MAINTAINING.md "fourteen exclude-paths" count** (lines 1049-1074, `package_major_minor!`/`current_compatibility_section!`/`dependency_constraint!` helpers, already defined at the bottom of this same file):
```elixir
  defp package_major_minor!(mixfile_path) do
    mixfile = File.read!(mixfile_path)

    [_, version] =
      Regex.run(~r/@version\s+"(\d+\.\d+\.\d+)"/, mixfile) ||
        flunk("#{mixfile_path} is missing an @version X.Y.Z manifest value")

    version
    |> String.split(".")
    |> Enum.take(2)
    |> Enum.join(".")
  end

  defp current_compatibility_section!(readme, path) do
    case Regex.run(~r/^## Current package compatibility\n\n([\s\S]*?)(?=^## |\z)/m, readme) do
      [_, section] -> section
      _ -> flunk("#{path} is missing its current package compatibility section")
    end
  end

  defp dependency_constraint!(section, dependency, path) do
    case Regex.run(~r/\{:#{dependency},\s*"~>\s*(\d+\.\d+)/, section) do
      [_, major_minor] -> major_minor
      _ -> flunk("#{path} is missing a current {:#{dependency}, \"~> X.Y\"} constraint")
    end
  end
```
For DOCS-04, replace the hardcoded lines 557-558 (`assert migration =~ ~r/~>\s*2\.5/, "..."`) with a call to `package_major_minor!("mix.exs")` compared against a dependency-constraint extraction from the migration guide's dep block — the same pattern as the README test at lines 16-26 (already excerpted above in "File Classification").

For MAINTAINING.md's "twelve/fourteen `exclude-paths`" claim, RESEARCH.md's own recommendation (lines 181-186) is to read `release-please-config.json`'s `.["."]["exclude-paths"]` array length at test time (via `Jason.decode!(File.read!("release-please-config.json"))` — no existing helper for this; it's a 2-3 line inline addition, not a new helper function) and assert the prose number matches it dynamically, rather than hardcoding "fourteen" as a second literal.

**Companion AST-cross-check idiom for DOCS-05(iii)** (`docs/api_stability.md`'s injected-forms list) — mirror `test/mailglass/mailable_test.exs:74-118`'s `Code.string_to_quoted` structural-assertion pattern (excerpted below under Shared Patterns) via a lighter-weight source-text pin inside `docs_contract_test.exs`:
```elixir
  describe "docs/api_stability.md contract" do
    test "injected __using__ forms list matches mailable.ex's actual imports" do
      api_stability = File.read!("docs/api_stability.md")
      refute api_stability =~ "import Swoosh.Email, except: [new: 0]",
             "api_stability.md still describes the wrong __using__ import"
      assert api_stability =~ "import Mailglass.Message, only: [to: 2",
             "api_stability.md must describe the actual Mailglass.Message import"
    end
  end
```

**Existing "guide exists on disk" pattern to generalize for DOCS-06** (line ~514, `learning-path is registered in both mix.exs docs lists` test):
```elixir
      assert File.exists?("guides/learning-path.md"),
             "guides/learning-path.md does not exist on disk"
```
Generalize per RESEARCH.md: assert every `guides/upgrading-*.md` file on disk is referenced somewhere in `README.md` (e.g. `Path.wildcard("guides/upgrading-*.md")` + `Enum.each(&assert readme_text =~ Path.basename(&1), ...)`).

---

### NEW script pinning DOCS-01 — analog survey (the one artifact with no direct precedent)

**Closest real analog:** `dev/mix/tasks/mailglass.repo.hygiene.ex` (552 lines, `dev/` per CLAUDE.md's "dev/ for internal tooling" carve-out) + its invoking workflow `.github/workflows/repo-hygiene.yml` + `scripts/scheduled_control_evidence.sh` (evidence-binding wrapper) + companion test `test/mix/tasks/mailglass.repo.hygiene_test.exs`.

**Why this is the analog, not a `scripts/*.sh` script:** every `scripts/*.sh` file in the repo (`assert_gating_toolchain.sh`, `check_post_publish_target.sh`, `verify-branch-protection.sh`, etc.) is either a release-ceremony gate or a pure bash/jq utility invoked from a workflow step directly. The **one** existing mechanism that does "query live GitHub state via `gh`, classify pass/blocked/cannot-check, emit `--format json`, run on a schedule, advisory not gating" is `mailglass.repo.hygiene` — a **Mix task**, not a shell script. This is the correct shape to imitate for a new "does STATE.md's prose match live `gh pr`/`gh issue` state" check.

**CLI arg-parsing + mode dispatch idiom** (lines 22-55):
```elixir
  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [check: :boolean, apply: :boolean, format: :string],
        aliases: [c: :check]
      )

    validate_cli!(opts, rest, invalid)

    mode = if opts[:apply], do: :apply, else: :check
    format = opts[:format] || "text"
    repo = File.cwd!()

    result =
      if mode == :apply do
        apply_safe_actions(repo)
        audit(repo)
      else
        audit(repo)
      end

    emit(result, format)

    case result.status do
      :pass -> :ok
      # A non-verdict must be observably different from a confirmed alarm in
      # the workflow log and to any consumer -- and it must never be 0 (that
      # would convert an unobservable control into a permanent green, the
      # same failure class the release-please gate refuses). D-34.
      :cannot_check -> exit({:shutdown, 2})
      _blocked -> exit({:shutdown, 1})
    end
  end
```
**Exit-code convention:** `0` = pass, `2` = cannot-check (distinct exit code, never conflated with 0 — D-34 "a non-verdict must never be indistinguishable from a confirmed pass"), `1` = blocked/any other non-pass status.

**Per-check result shape + aggregation idiom** (lines 57-73, 482-508):
```elixir
  def audit(repo) do
    checks = [
      git_state(repo),
      ci_state(repo),
      branch_protection(repo),
      pull_requests(repo),
      stale_branches(repo),
      release_workflows(repo)
    ]

    %{
      status: status(checks),
      reason: reason(checks),
      generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      repo: repo,
      checks: checks
    }
  end

  defp status(checks) do
    cond do
      Enum.any?(checks, &(&1.status == :cannot_check)) -> :cannot_check
      Enum.any?(checks, &(&1.status == :blocked)) -> :blocked
      true -> :pass
    end
  end

  defp check(name, status, message, details) do
    %{name: name, status: status, message: message, details: details}
  end

  defp cannot_check(name, message, details) do
    check(name, :cannot_check, message, details)
  end
```
A new DOCS-01 check would follow the identical `%{name:, status:, message:, details:}` shape, one check per `#NNN` reference found in STATE.md (or one aggregate check), folded into the same three-way `status/1` aggregation.

**`gh` CLI invocation + JSON decode + graceful degradation idiom** (lines 165-227, `ci_state/1` — directly reusable shape for "call `gh pr view NNN --json state`"):
```elixir
  defp ci_state(repo) do
    sha = git_output(repo, ["rev-parse", "HEAD"]) |> String.trim()

    cond do
      System.find_executable("gh") == nil ->
        cannot_check(:ci_state, "GitHub CLI is not installed; CI state was not checked.", %{
          sha: sha
        })

      true ->
        args = ["run", "list", "--workflow", "ci.yml", "--commit", sha, "--limit", "1",
                "--json", "headSha,conclusion,status,url"]

        case cmd(repo, "gh", args) do
          {json, 0} ->
            case Jason.decode(json) do
              {:ok, runs} when is_list(runs) ->
                # ... classify pass/blocked from decoded JSON
              {:ok, _response} ->
                cannot_check(:ci_state, "... unexpected GitHub CI response ...", %{sha: sha})
              {:error, _reason} ->
                cannot_check(:ci_state, "... malformed GitHub CI response ...", %{sha: sha})
            end

          {output, _} ->
            cannot_check(:ci_state, "GitHub CI state was not checked.", %{error: String.trim(output)})
        end
    end
  end

  defp cmd(repo, executable, args) do
    System.cmd(executable, args, cd: repo, stderr_to_stdout: true)
  end
```
For DOCS-01: replace `gh run list --workflow ci.yml` with `gh pr view NNN --json state` / `gh issue view NNN --json state` per extracted `#NNN` reference from `.planning/STATE.md`, same three-way degrade (gh missing → cannot-check; malformed JSON → cannot-check; decoded and mismatched vs. STATE.md's prose claim → blocked; matches → pass).

**Output emission (`--format json` / `--format text`) idiom** (lines 510-532):
```elixir
  defp emit(result, "json") do
    result
    |> encode_statuses()
    |> Jason.encode!(pretty: true)
    |> Mix.shell().info()
  end

  defp emit(result, "text") do
    Mix.shell().info("Repo hygiene: #{external_status(result.status)}")

    Enum.each(result.checks, fn check ->
      Mix.shell().info("#{external_status(check.status)} #{check.name}: #{check.message}")
    end)
  end

  defp external_status(:cannot_check), do: "cannot-check"
  defp external_status(status), do: to_string(status)
```

**Invoking workflow shape** (`.github/workflows/repo-hygiene.yml`, full file, 64 lines):
```yaml
name: repo-hygiene

on:
  schedule:
    - cron: "30 12 * * *"
  workflow_dispatch:

permissions:
  contents: read
  pull-requests: read
  actions: read

concurrency:
  group: repo-hygiene-${{ github.ref }}
  cancel-in-progress: false

jobs:
  hygiene:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1  # v7.0.1
        with:
          fetch-depth: 0
      - name: Set up OTP + Elixir
        uses: erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124  # v1.24.1
        with:
          version-file: .tool-versions
          version-type: strict
      - name: Cache deps
        uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9  # v6.1.0
        with:
          path: deps
          key: mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV || 'dev' }}-${{ hashFiles('**/mix.lock') }}
      - name: Install deps
        run: mix deps.get
      - name: Compile repo hygiene task
        run: mix compile
      - name: Run repo hygiene audit
        id: hygiene
        env:
          GH_TOKEN: ${{ secrets.BRANCH_PROTECTION_PAT || secrets.GITHUB_TOKEN }}
        run: |
          set -o pipefail
          mix mailglass.repo.hygiene --check --format json | tee "$RUNNER_TEMP/repo-hygiene.json"
      - name: Bind and summarize scheduled-control evidence
        if: always()
        env:
          GITHUB_WORKFLOW_SHA: ${{ github.workflow_sha }}
        run: |
          set -o pipefail
          bash scripts/scheduled_control_evidence.sh bind \
            --control repo-hygiene \
            --artifact "$RUNNER_TEMP/repo-hygiene.json" \
            | tee -a "$GITHUB_STEP_SUMMARY"
      - name: Upload hygiene artifact
        if: always()
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a  # v7.0.1
        with:
          name: repo-hygiene
          path: ${{ runner.temp }}/repo-hygiene.json
          if-no-files-found: error
```
This is triggered on `schedule` + `workflow_dispatch` (never on push/PR — advisory, never blocks a merge), same `concurrency`/`cancel-in-progress: false` shape, pipes `--format json` output to a temp file, then binds it via `scripts/scheduled_control_evidence.sh bind --control <id> --artifact <path>` (an existing generic evidence-binding wrapper already wired to `.github/scheduled-controls.json` — check whether a new `state-md-audit` control ID needs registering there, or whether reusing/extending `repo-hygiene`'s own control ID is simpler, since RESEARCH.md's Open Question 2 leaves "new script vs. extend existing" undecided).

**Companion test file exists for the analog** — `test/mix/tasks/mailglass.repo.hygiene_test.exs` is the pattern to imitate for a new task's test file (not read in full this session; same directory `test/mix/tasks/`, same naming convention `mailglass.<task_name>_test.exs`).

**Open question carried to planner:** RESEARCH.md's Open Question 2 is unresolved — whether DOCS-01 needs a full new Mix task + workflow (mirroring `mailglass.repo.hygiene` exactly), or a smaller one-off script invoked ad hoc. Either way, the code shape above (CLI opts → `%{name:, status:, message:, details:}` checks → `gh` calls with graceful degrade → `--format json`/`text` emission → exit-code convention) is the pattern to copy.

---

### `test/mailglass/config_test.exs` — `css_inliner: :none` inversion (DOCS-05(i))

**Before (current acceptance case, lines 17-21):**
```elixir
    test "accepts valid opts unchanged and fills defaults" do
      config = Mailglass.Config.new!(renderer: [css_inliner: :none, plaintext: false])
      renderer = Keyword.fetch!(config, :renderer)
      assert Keyword.fetch!(renderer, :css_inliner) == :none
      assert Keyword.fetch!(renderer, :plaintext) == false
    end
```

**After-pattern (adjacent `:invalid_backend` `assert_raise` case, lines 30-34 — copy this shape):**
```elixir
    test "invalid type raises NimbleOptions.ValidationError" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(renderer: [css_inliner: :invalid_backend])
      end
    end
```
Per RESEARCH.md's decisive disposition (REJECT, not honor): invert the "accepts valid opts" test so it no longer includes `css_inliner: :none` in its valid-opts payload (adjust the still-valid `plaintext: false` assertion to stand alone, or fold into the surrounding `describe "new!/1"` block), and add a new test asserting `:none` now raises, e.g.:
```elixir
    test "rejects css_inliner: :none (dead validation surface, closed per DOCS-05)" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(renderer: [css_inliner: :none])
      end
    end
```

---

### `lib/mailglass/config.ex` — narrow `css_inliner` type (DOCS-05(i))

**Current schema idiom, `renderer:` subtree** (lines 79-95, `Mailglass.Runtime.Schema` module — note: the module docstring above frontloads with "Schema is declared BEFORE @moduledoc so NimbleOptions.docs(@schema) can interpolate into the module documentation," a convention worth preserving when editing):
```elixir
    renderer: [
      type: :keyword_list,
      default: [],
      doc: "Renderer options.",
      keys: [
        css_inliner: [
          type: {:in, [:premailex, :none]},
          default: :premailex,
          doc: "CSS inlining backend. Default: `:premailex`."
        ],
        plaintext: [
          type: :boolean,
          default: true,
          doc: "Auto-generate a plaintext body alongside the HTML body. Default: `true`."
        ]
      ]
    ],
```
**Change:** narrow `type: {:in, [:premailex, :none]}` → `type: {:in, [:premailex]}` (line 85 only). No other lines in this subtree change. This is a `NimbleOptions` schema, and validation failures raise `NimbleOptions.ValidationError` automatically (not a custom `%Mailglass.Error{}`) — confirmed by every `assert_raise NimbleOptions.ValidationError` test in `config_test.exs`; `Mailglass.Config` does not wrap NimbleOptions errors into the closed `%Mailglass.Error{}` `:type` atom set anywhere in this schema (that contract applies to runtime/library errors elsewhere, not config-boot validation).

---

### `.github/dependabot.yml` — current file verbatim (STAND-01)

```yaml
version: 2
updates:
  - package-ecosystem: "mix"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "mix"
    directory: "/mailglass_admin"
    schedule:
      interval: "weekly"
  - package-ecosystem: "mix"
    directory: "/mailglass_inbound"
    schedule:
      interval: "weekly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "docker"
    directory: "/dev/toolchain"
    schedule:
      interval: "weekly"
  - package-ecosystem: "docker"
    directory: "/reference/demo_app"
    schedule:
      interval: "weekly"
```
**Entries in `mix` ecosystem (the only ones in scope for STAND-01):** the three `package-ecosystem: "mix"` blocks — `directory: "/"`, `directory: "/mailglass_admin"`, `directory: "/mailglass_inbound"`. The `github-actions` and two `docker` entries are out of scope — do not touch them. No `groups:` or `open-pull-requests-limit` key exists anywhere in the file today; this is a pure addition, not a rewrite. See RESEARCH.md's "Recommended exact addition to each of the three `mix` entries" block for the exact `groups:`/`update-types:`/`open-pull-requests-limit` YAML to add (reproduced in RESEARCH.md lines 428-467; not re-excerpted here since RESEARCH.md is the authoritative source and this is pure net-new YAML with no in-repo precedent to imitate).

---

### `.github/workflows/release-please.yml` — sed resync step extension (DOCS-04 disposition (b))

**Existing step verbatim** (lines 400-499, the full sed-resync block; extend by adding `guides/migration-from-swoosh.md` to the loop and to `SYNC_PATHS`):
```bash
          git fetch origin "$BRANCH":"$BRANCH"
          git checkout "$BRANCH"

          # Read the linked core/admin manifest version. Read .["."] directly;
          # do NOT use a fallback chain (which could return inbound's independent
          # version instead).
          CORE_VERSION=$(jq -r '.["."]' .release-please-manifest.json)
          if [ -z "$CORE_VERSION" ] || [ "$CORE_VERSION" = "null" ]; then
            echo "ERROR: could not read core version (.[\".\"]) from .release-please-manifest.json" >&2
            exit 1
          fi

          # ... (inbound version handling, unchanged) ...

          CORE_MM=$(echo "$CORE_VERSION" | cut -d. -f1,2)
          INBOUND_MM=$(echo "$INBOUND_VERSION" | cut -d. -f1,2)
          echo "Target core/admin README pins: ~> $CORE_MM"
          for readme in README.md mailglass_admin/README.md; do
            sed -i -E "s/\{:mailglass, \"~> [0-9]+\.[0-9]+\"/{:mailglass, \"~> ${CORE_MM}\"/" "$readme"
            sed -i -E "s/\{:mailglass_admin, \"~> [0-9]+\.[0-9]+\"/{:mailglass_admin, \"~> ${CORE_MM}\"/" "$readme"
          done

          # Inbound stays on its independent version line, but its install docs
          # and committed compatibility evidence must describe the new core.
          sed -i -E "s/\{:mailglass, \"~> [0-9]+\.[0-9]+\"/{:mailglass, \"~> ${CORE_MM}\"/" mailglass_inbound/README.md
          sed -i -E "s/\{:mailglass_admin, \"~> [0-9]+\.[0-9]+\"/{:mailglass_admin, \"~> ${CORE_MM}\"/" mailglass_inbound/README.md

          INSTALL=mailglass_inbound/docs/inbound-install.md
          if [ -f "$INSTALL" ]; then
            sed -i -E "s/(\{:mailglass,[[:space:]]+\"~> )[0-9]+\.[0-9]+(\")/\1${CORE_MM}\2/" "$INSTALL"
          fi
          # ... (publish-summary jq sync, inbound README bump, unchanged) ...

          SYNC_PATHS=(
            README.md
            mailglass_admin/README.md
            mailglass_inbound/README.md
            mailglass_inbound/docs/inbound-install.md
            .planning/publish/mailglass_inbound-publish-summary.json
          )
          COMMIT_MESSAGE="chore(release-please): sync linked package pins to core $CORE_VERSION"
          if [ "$INBOUND_CHANGED" = true ]; then
            COMMIT_MESSAGE="chore(release-please): sync inbound README \`~>\` pin + publish-summary to core $CORE_VERSION"
          fi
          if git diff --quiet -- "${SYNC_PATHS[@]}"; then
            echo "Pins + README already synced — nothing to commit."
            exit 0
          fi

          echo "Pins/README updated; diff follows:"
          git --no-pager diff -- "${SYNC_PATHS[@]}"

          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add "${SYNC_PATHS[@]}"
```
**Extension shape:** add one `sed -i -E "s/\{:mailglass, \"~> [0-9]+\.[0-9]+\"/{:mailglass, \"~> ${CORE_MM}\"/" guides/migration-from-swoosh.md` line alongside the existing `README.md`/`mailglass_admin/README.md` loop (or add `guides/migration-from-swoosh.md` as a third entry to the `for readme in ...` loop at line 441, since its dep-pin shape — `{:mailglass, "~> X.Y"}, {:mailglass_admin, "~> X.Y"}` — matches exactly what that loop already resyncs), and add `guides/migration-from-swoosh.md` to the `SYNC_PATHS` array (line 478-484) so `git diff`/`git add` pick it up. This is a ~3-line addition to existing, already-tested job logic — not new infrastructure. Comment style to preserve: this file annotates *why* each sync exists with a reference to the test file that would otherwise go red (see the comment at lines 434-437 referencing `docs_contract_test.exs`) — add a matching one-line comment noting DOCS-04 / the dynamic test extension.

---

## Shared Patterns

### Source-text drift-guard idiom (applies to DOCS-02, DOCS-03, DOCS-05(ii), DOCS-05(iii), DOCS-06)
**Source:** `test/mailglass/docs_contract_test.exs` (whole-file idiom, concrete instance at lines 550-558)
**Apply to:** every new `describe` block for CLAUDE.md, CONTRIBUTING.md, MAINTAINING.md, `docs/api_stability.md`, and the CHANGELOG.md note.
```elixir
refute <source_var> =~ "<stale/defective phrase>", "<file> still contains <defect description>"
assert <source_var> =~ "<corrected phrase or regex>", "<file> must state <correction description>"
```

### Dynamic (never-hardcoded) version/count pin idiom (applies to DOCS-04, and recommended for the MAINTAINING.md "fourteen exclude-paths" count)
**Source:** `test/mailglass/docs_contract_test.exs:1049-1074` (`package_major_minor!`, `current_compatibility_section!`, `dependency_constraint!`)
**Apply to:** any assertion where a literal number/version could silently drift on a future release — read the ground-truth value from its source file (`mix.exs`'s `@version`, `release-please-config.json`'s `exclude-paths` array length) at test time rather than asserting a hardcoded literal.

### `%{name:, status:, message:, details:}` check-and-aggregate idiom (applies to DOCS-01's new script)
**Source:** `dev/mix/tasks/mailglass.repo.hygiene.ex:57-73, 482-508`
**Apply to:** the new STATE.md-vs-live-GitHub-state check — one check struct per validated claim, aggregated via `:pass`/`:blocked`/`:cannot_check` three-way status with `:cannot_check` never conflated with `:pass` (exit code 2 vs. 0, per D-34's "a non-verdict must be observably different from a confirmed alarm").

### `assert_raise NimbleOptions.ValidationError` idiom for closing a dead/inert config surface (applies to DOCS-05(i))
**Source:** `test/mailglass/config_test.exs:24-34` (both the generic-invalid-key case and the `:invalid_backend` case)
**Apply to:** the inverted `css_inliner: :none` test — this is the established, idiomatic way this codebase closes an unsupported config value; no new error-handling mechanism needed.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.github/dependabot.yml` `groups:`/`open-pull-requests-limit` addition | config | batch | Pure GitHub-native YAML feature with zero prior use anywhere in this repo's Dependabot config; RESEARCH.md's own "STAND-01 — exact YAML" section (lines 358-467) is the authoritative source for the syntax to add, cross-checked against GitHub's own docs (cited in RESEARCH.md Sources) rather than an in-repo analog. |
| New DOCS-01 script/task (fully net-new domain: STATE.md prose vs. live `gh pr`/`gh issue` state) | utility / mix task | event-driven | No exact-role analog exists; `mailglass.repo.hygiene` (mapped above as role-match) is the closest shape but audits *git/CI/branch* state, not *documentation prose* against `gh`. Planner should treat the repo-hygiene excerpts above as the mechanical shape to imitate, with the actual data source (STATE.md `#NNN` extraction + `gh pr view`/`gh issue view` per reference) being the genuinely new piece. |

## Prose-Only Files (not pattern-mapped, per phase-runner scoping)

One-line notes only, per the caller's explicit "do not spend effort" instruction — target text is already quoted verbatim in `167-RESEARCH.md`'s Defect Ledger:

- `CLAUDE.md` — 3 corrections (lines 15, 56, 119); pinned by the new `docs_contract_test.exs` describe block above.
- `CONTRIBUTING.md` — 1 correction (lines 186-190, `fix(inbound):` floor-bump paragraph); pinned by a scoped `refute`.
- `MAINTAINING.md` — 3 corrections (line 137 "twelve"→dynamic count, lines 631/662 "hands-free" reword, new `## Release Close-Out` section); pinned by new describe block + dynamic-count assertion.
- `README.md` — 1 addition (missing link to `guides/upgrading-to-v2_0.md`, which already exists on disk); pinned by generalizing the existing "guide exists on disk" pattern.
- `CHANGELOG.md` — 1 appended clarifying note near the 2.0.0 BREAKING CHANGES bullet; do not rewrite history, only append; pinned by a positive `assert` that the note text is present (no `refute`/deletion of release-please-generated text).
- `.planning/STATE.md` — DOCS-01's prose correction itself (GSD machine-managed; commit as `docs(state):`); the *pin* is the new script/task above, not a unit test on STATE.md's literal text (a snapshot test would go red on every routine GSD phase-completion append).
- `guides/migration-from-swoosh.md` (DOCS-04) and `guides/compatibility-and-deprecations.md` (lines 209-210) — prose bodies whose corrected text RESEARCH.md already quotes; the pattern-mapping value for these two is entirely in the *test*/*sed-step* mechanisms above, not the prose itself.

## Metadata

**Analog search scope:** `test/mailglass/`, `test/support/`, `test/mix/tasks/`, `dev/mix/tasks/`, `lib/mailglass/config.ex`, `.github/workflows/`, `.github/dependabot.yml`, `scripts/`
**Files scanned:** `test/mailglass/docs_contract_test.exs` (full, 1093 lines), `test/mailglass/config_test.exs` (full, 213 lines), `lib/mailglass/config.ex` (lines 1-100), `dev/mix/tasks/mailglass.repo.hygiene.ex` (full, 552 lines), `.github/workflows/repo-hygiene.yml` (full, 64 lines), `.github/workflows/release-please.yml` (lines 400-499), `.github/dependabot.yml` (full, 27 lines), `test/support/docs_helpers.ex` (full, 27 lines), `test/mailglass/mailable_test.exs` (lines 70-119), `scripts/` directory listing (46 files) + `scripts/check_post_publish_target.sh` (full) + `scripts/scheduled_control_evidence.sh` (lines 1-80)
**Pattern extraction date:** 2026-09-18

