defmodule Mailglass.SupplyChain.AcceptedAdvisories do
  # No `use Boundary` declaration: this module's name starts with `Mailglass.`,
  # so it is automatically part of the root `Mailglass` boundary by naming
  # convention (no nested `Mailglass.SupplyChain` boundary exists). The
  # `Boundary` library's `classify_to:` option is reserved for Mix tasks and
  # protocol implementations ONLY (their names live outside the `Mailglass.*`
  # namespace) — applying it here raises "only mix task and protocol
  # implementation can be reclassified" under `mix compile --warnings-as-errors`.
  @moduledoc """
  The single source of truth for advisories `mailglass` deliberately allows
  past `mix hex.audit` / `mix deps.audit` gates because no upstream fix exists
  yet. The allowlist is currently empty: every advisory finding blocks. Both `mix mailglass.publish.check` (publish gate) and
  `mix mailglass.audit` (CI gate, `dev/mix/tasks/mailglass.audit.ex`) read this
  module exclusively — there is no second copy of the allowlist anywhere in
  the repo.

  Each entry carries `:id` (the primary EEF-CVE id reported by `hex.audit`),
  `:aliases` (any GHSA ids the same advisory is known by in the
  mirego/elixir-security-advisories DB that `mix deps.audit` reads),
  `:package`, `:severity`, `:reason`, `:accepted_on`, and `:recheck_by`.
  Matching against a finding is exact `:id`-or-`:aliases`-member equality
  against ONE entry — never fuzzy, prefix, or cross-package.

  When the allowlist has entries, each carries the fields above. The query
  functions take an optional trailing `entries` argument (defaulting to the
  real allowlist) so tests can exercise matching, alias, expiry and unused
  logic against a fixture without a real entry existing.

  ## Expiry and staleness

  `expired_entries/2` flags any entry whose `:recheck_by` date has passed
  (strictly after — an entry due today does not yet block). `unused_entries/2`
  flags any entry that matched no current `hex.audit` finding across all three
  scanned Mix projects, so a suppression that is no longer needed cannot
  silently age forever. Both checks are local and deterministic — they never
  depend on OSV's unreliable `fixed`-event data.

  ## Known limitation

  `unused_entries/2`'s "used" signal comes only from `matched_hex_audit_ids/2`,
  which is populated only by `--kind hex` runs of `mix mailglass.audit`. A
  future allowlist entry that is detectable ONLY by `mix deps.audit` (e.g. a
  GHSA-only id absent from the EEF-CVE database) would therefore be
  perpetually reported "unused" by every `--kind hex` run, pressuring a
  maintainer to delete a legitimately-needed suppression. This fails loud, not
  silent, so it does not reintroduce VULN-06's silent-aging defect for the
  entries shipped so far (all were EEF-CVE-keyed and hex.audit-native). It is
  nonetheless a real constraint on who may add future entries: if such an
  entry is ever needed, widen the "used" signal to also aggregate `--kind
  deps` matches — that widening is deliberately not built speculatively here.
  """

  @type entry :: %{
          id: String.t(),
          aliases: [String.t()],
          package: String.t(),
          severity: String.t(),
          reason: String.t(),
          accepted_on: Date.t(),
          recheck_by: Date.t()
        }

  # The allowlist is intentionally EMPTY. It may only grow with a sourced,
  # falsifiable reason (see each entry's :reason for the shape: upstream
  # evidence plus a named re-check). History:
  #
  #   * EEF-CVE-2026-43969 (cowlib) was retired when cowlib 2.21.0 shipped its
  #     fix (OSV fixed: 2.21.0) and `unused_entries/1` flagged it.
  #   * EEF-CVE-2026-43966 (cowlib, GHSA-w4f7-4cxr-rv3c) was retired
  #     2026-11-13: the lock refresh to cowlib 2.22.0 means `mix hex.audit` no
  #     longer reports it in the root, mailglass_admin or mailglass_inbound
  #     projects, so `unused_entries/1` flagged the entry as matching no
  #     current finding. Upstream had declined the fix on principle
  #     (ninenines/cowlib#167, 2026-08-06); that stance no longer matters to
  #     the gate because the finding is gone.
  @entries []

  @doc "Returns the full accepted-advisory allowlist."
  @spec entries() :: [entry()]
  def entries, do: @entries

  # Parse `mix hex.audit` output and return the list of findings that are NOT
  # in the allowlist. Retired packages are NEVER accepted (a retired package
  # must be replaced), so their presence always yields a non-empty result.
  # Advisory finding lines look like: `  <pkg> <version> - <ADVISORY_ID> (<SEV>)`.
  # Public (with @doc false) only so the security-critical allowlist behaviour
  # is unit-testable; not part of this module's user-facing contract.
  @doc false
  def unaccepted_audit_findings(output, entries \\ @entries) do
    lines = String.split(output, "\n")

    retired =
      if Enum.any?(lines, &(&1 =~ ~r/retired/i)) and
           not Enum.any?(lines, &(&1 =~ ~r/No retired packages found/i)) do
        ["retired package(s) present"]
      else
        []
      end

    advisories =
      lines
      |> Enum.flat_map(fn line ->
        case Regex.run(~r/^\s+(\S+)\s+\S+\s+-\s+(\S+)\s+\(/, line) do
          [_, pkg, id] -> [{pkg, id}]
          _ -> []
        end
      end)
      |> Enum.reject(fn {_pkg, id} -> matches_any_entry?(id, entries) end)
      |> Enum.map(fn {pkg, id} -> "#{pkg} #{id}" end)

    retired ++ advisories
  end

  # Parse `mix deps.audit` human-formatter output and return the list of
  # findings NOT in the allowlist. mix_audit emits a multi-line block per
  # vulnerability; the advisory id is the trailing GHSA-* segment of the
  # `URL:` line, paired with the `Name:` line for the package. Matching is
  # alias-aware: a GHSA id registered as an entry's `:aliases` member is
  # suppressed exactly like the entry's primary `:id` would be.
  # Public (with @doc false) only so this security-critical parser is
  # unit-testable.
  @doc false
  def unaccepted_deps_audit_findings(output, entries \\ @entries) do
    output
    |> deps_audit_findings()
    |> Enum.reject(fn {_pkg, id} -> matches_any_entry?(id, entries) end)
    |> Enum.map(fn {pkg, id} -> "#{pkg} #{id}" end)
  end

  @doc false
  @spec matched_deps_audit_ids(String.t(), [entry()]) :: MapSet.t(String.t())
  def matched_deps_audit_ids(output, entries \\ @entries) do
    output
    |> deps_audit_findings()
    |> Enum.flat_map(fn {_pkg, id} ->
      case matching_entry(id, entries) do
        nil -> []
        entry -> [entry.id]
      end
    end)
    |> MapSet.new()
  end

  # Same line-scanning shape as unaccepted_audit_findings/2's advisory
  # extraction, but KEEPS only the ids matching an entry (instead of
  # rejecting them), mapping each surviving hit to its entry's canonical
  # `:id` — so a hit via alias still contributes the entry's `:id`, not the
  # raw finding id, to the returned set. This is the sole "used" signal for
  # unused_entries/2 (see moduledoc "Known limitation").
  @doc false
  @spec matched_hex_audit_ids(String.t(), [entry()]) :: MapSet.t(String.t())
  def matched_hex_audit_ids(output, entries \\ @entries) do
    output
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^\s+(\S+)\s+\S+\s+-\s+(\S+)\s+\(/, line) do
        [_, _pkg, id] -> [id]
        _ -> []
      end
    end)
    |> Enum.flat_map(fn id ->
      case matching_entry(id, entries) do
        nil -> []
        entry -> [entry.id]
      end
    end)
    |> MapSet.new()
  end

  @doc """
  Entries whose `:recheck_by` date has strictly passed as of `today`
  (`Date.compare(today, recheck_by) == :gt`) — an entry due today does not
  yet block; it blocks starting the day after.
  """
  @spec expired_entries(Date.t(), [entry()]) :: [entry()]
  def expired_entries(today \\ Date.utc_today(), entries \\ @entries) do
    Enum.filter(entries, fn entry -> Date.compare(today, entry.recheck_by) == :gt end)
  end

  @doc """
  Entries whose `:id` is absent from `matched_ids` — the aggregate of
  `matched_hex_audit_ids/1` across every directory scanned by a single
  `--kind hex` run of `mix mailglass.audit`. An entry counts as "used" if it
  matched a finding in ANY scanned directory.
  """
  @spec unused_entries(MapSet.t(String.t()), [entry()]) :: [entry()]
  def unused_entries(matched_ids, entries \\ @entries) do
    Enum.reject(entries, &MapSet.member?(matched_ids, &1.id))
  end

  defp matches_any_entry?(id, entries), do: matching_entry(id, entries) != nil

  defp deps_audit_findings(output) do
    {findings, _pkg} =
      output
      |> String.split("\n")
      |> Enum.reduce({[], nil}, fn line, {acc, current_pkg} ->
        cond do
          match = Regex.run(~r/^\s*Name:\s+(\S+)/, line) ->
            [_, pkg] = match
            {acc, pkg}

          match = Regex.run(~r/^\s*URL:.*\/(GHSA-\S+)/, line) ->
            [_, id] = match
            {[{current_pkg, id} | acc], current_pkg}

          true ->
            {acc, current_pkg}
        end
      end)

    Enum.reverse(findings)
  end

  defp matching_entry(id, entries) do
    Enum.find(entries, fn entry -> entry.id == id or id in entry.aliases end)
  end
end
