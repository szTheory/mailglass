defmodule Mailglass.Scripts.WorkspaceEvidenceContractTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/verify_workspace_evidence.sh")
  @phase_dir Path.join(
               @repo_root,
               ".planning/phases/161-canonical-workspace-and-evidence-preservation"
             )
  @phase_inventory Path.join(@phase_dir, "161-WORKSPACE-INVENTORY.md")
  @phase_tsv Path.join(@phase_dir, "161-PRESERVATION-RECONCILIATION.tsv")

  test "Phase 161 evidence satisfies the reusable static contract" do
    assert {output, 0} = run(["static", @phase_inventory, @phase_tsv])
    assert output =~ "workspace evidence static contract: PASS"
  end

  test "a complete disposable repository satisfies the live contract" do
    fixture = fixture!()

    assert {output, 0} =
             run(["live", fixture.repo, fixture.inventory, fixture.tsv])

    assert output =~ "workspace evidence live contract: PASS"
    assert output =~ "15/15 automated UAT checks passed"
  end

  test "missing zero sentinels and stale evidence fail closed" do
    fixture = fixture!()

    without_stash_sentinel =
      mutate_copy!(fixture.inventory, fn source ->
        source
        |> String.split("\n")
        |> Enum.reject(&String.starts_with?(&1, "| NONE-STASH "))
        |> Enum.join("\n")
      end)

    assert_failed(without_stash_sentinel, fixture.tsv, "stash category")

    stale =
      mutate_copy!(fixture.inventory, &String.replace(&1, "EVID-WT-ROOT", "stale", global: false))

    assert_failed(stale, fixture.tsv, "stale or unreadable evidence")
  end

  test "identity collapse and unsafe removal fail closed" do
    fixture = fixture!()

    duplicate =
      mutate_copy!(fixture.inventory, fn source ->
        duplicate =
          source
          |> String.split("\n")
          |> Enum.find(&String.starts_with?(&1, "| REF-0001 "))
          |> String.replace("REF-0001", "REF-0002", global: false)

        String.replace(
          source,
          "\n## Final Reconciliation",
          "\n#{duplicate}\n\n## Final Reconciliation"
        )
      end)

    assert_failed(duplicate, fixture.tsv, "duplicate category/identity")

    unsafe_inventory =
      mutate_copy!(fixture.inventory, fn source ->
        String.replace(source, "| REF-0001 | archive ref |", "| REF-0001 | archive ref |")
        |> String.replace(
          "| archive | named recovery ref |",
          "| remove | age and detached state only |",
          global: false
        )
      end)

    unsafe_tsv =
      mutate_copy!(fixture.tsv, &String.replace(&1, "REF-0001\tarchive", "REF-0001\tremove"))

    assert_failed(unsafe_inventory, unsafe_tsv, "safe removal proof")
  end

  test "a clean tree cannot be labeled release-clean while it is ahead" do
    fixture = fixture!()

    dishonest =
      mutate_copy!(fixture.inventory, fn source ->
        String.replace(source, "non-release-clean", "release-clean", global: false)
      end)

    assert_failed(dishonest, fixture.tsv, "non-release-clean")
  end

  test "live ref drift and a mid-assessment mutation both abort" do
    fixture = fixture!()
    git!(fixture.repo, ["branch", "-f", "archive/source", "main"])

    assert {output, status} = run(["live", fixture.repo, fixture.inventory, fixture.tsv])
    assert status != 0
    assert output =~ "archive/source"

    fixture = fixture!()
    sync_dir = tmp_dir!("mailglass-workspace-evidence-sync")

    task =
      Task.async(fn ->
        run(["live", fixture.repo, fixture.inventory, fixture.tsv], [
          {"WORKSPACE_EVIDENCE_TEST_SYNC_DIR", sync_dir}
        ])
      end)

    wait_for!(Path.join(sync_dir, "ready"))
    git!(fixture.repo, ["branch", "mutation-during-assessment", "main"])
    File.write!(Path.join(sync_dir, "continue"), "continue\n")

    assert {output, status} = Task.await(task, 15_000)
    assert status != 0
    assert output =~ "monitored assessment inputs changed"
  end

  test "the Phase 161 recapture commit is append-only and preserves the historical capture" do
    path =
      ".planning/phases/161-canonical-workspace-and-evidence-preservation/" <>
        "161-WORKSPACE-INVENTORY.md"

    assert {_, 0} = git(@repo_root, ["cat-file", "-e", "e2be2c94^{commit}"])
    assert {_, 0} = git(@repo_root, ["cat-file", "-e", "4402d789^{commit}"])

    assert {diff, 0} = git(@repo_root, ["diff", "--unified=0", "4402d789^", "4402d789", "--", path])

    removed_lines =
      diff
      |> String.split("\n")
      |> Enum.filter(&(String.starts_with?(&1, "-") and not String.starts_with?(&1, "---")))

    assert removed_lines == []

    assert {historical, 0} = git(@repo_root, ["show", "4402d789:#{path}"])
    assert historical =~ "Final capture HEAD:** `e2be2c941300fb0de3194bef6d62e087e96b5722`"
    assert historical =~ "behind 0 / ahead 29"
    assert historical =~ "Canonical Main Recapture — 2026-08-22T16:25:33Z"
  end

  defp fixture! do
    root = tmp_dir!("mailglass-workspace-evidence")
    repo = Path.join(root, "repo")
    remote = Path.join(root, "origin.git")
    File.mkdir_p!(repo)
    File.mkdir_p!(remote)

    git!(repo, ["init", "-b", "main"])
    git!(repo, ["config", "user.email", "test@example.test"])
    git!(repo, ["config", "user.name", "Mailglass Test"])
    File.write!(Path.join(repo, "tracked.txt"), "base\n")
    git!(repo, ["add", "tracked.txt"])
    git!(repo, ["commit", "-m", "base"])
    base = git_output!(repo, ["rev-parse", "HEAD"])

    git!(remote, ["init", "--bare"])
    git!(repo, ["remote", "add", "origin", remote])
    git!(repo, ["push", "-u", "origin", "main"])

    File.write!(Path.join(repo, "tracked.txt"), "ahead\n")
    git!(repo, ["commit", "-am", "ahead"])
    head = git_output!(repo, ["rev-parse", "HEAD"])
    git!(repo, ["branch", "archive/source", base])
    git!(repo, ["branch", "preserve/fixture-ref", base])
    git!(repo, ["branch", "preserve/fixture-range", base])

    inventory = Path.join(root, "INVENTORY.md")
    tsv = Path.join(root, "RECONCILIATION.tsv")

    File.write!(inventory, inventory(repo, head, base))
    File.write!(tsv, reconciliation(base))
    on_exit(fn -> File.rm_rf!(root) end)

    %{repo: repo, inventory: inventory, tsv: tsv}
  end

  defp inventory(repo, head, base) do
    """
    # Workspace Evidence Fixture

    ## Pre-Mutation Snapshot

    | ID | category | identity/path | observed state | content/unique-work evidence | reachability evidence | evidence ref | disposition | preservation/handoff | permitted next action | outcome |
    | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
    | CANONICAL | canonical workspace | `#{repo}` | `main`, upstream `origin/main`; clean; `behind 0 / ahead 1`; **non-release-clean** | tracked fixture commit | `git rev-parse HEAD` = `#{head}` | CM-01 | retain | canonical fixture | append evidence only | captured |
    | WT-01 | linked worktree | `#{repo}` | canonical `main`; clean | clean fixture worktree | `git rev-parse HEAD` = `#{head}` | EVID-WT-ROOT | retain | canonical fixture | append evidence only | captured |
    | NONE-STASH | stash | `NONE` | explicit zero sentinel | no stash returned by the enumerator | fresh empty stash enumeration | EVID-ZERO-STASH | retain | no preservation required | recapture if non-empty | captured |
    | REF-0001 | archive ref | `archive/source` | `#{base}` | source identity retained independently | source commit remains reachable | EVID-REF-GRAPH | archive | named recovery ref | retain | captured |
    | RANGE-0001 | archive range | `main...archive/source` | fixed range | range identity retained independently | both endpoints resolve | EVID-RANGE-GRAPH | archive | named recovery ref | retain | captured |
    | NONE-RELEASE | release proof | `NONE` | explicit zero sentinel | no release artifacts selected | fresh empty release enumeration | EVID-ZERO-RELEASE | retain | no preservation required | recapture if non-empty | captured |
    | NONE-OBJECT | unreachable commit | `NONE` | explicit zero sentinel | no unreachable commits selected | fresh empty fsck enumeration | EVID-ZERO-OBJECT | retain | no preservation required | recapture if non-empty | captured |

    ## Final Reconciliation

    The cleanup queue contains **zero** `remove` rows. No force removal, deletion, reset,
    force-push, prune, garbage collection, stash consumption, ref overwrite, or canonical
    history rewrite occurred. Pre-mutation evidence remains immutable and final state is
    appended separately. A clean tree remains **non-release-clean** while divergence exists.
    """
  end

  defp reconciliation(base) do
    """
    source_row\tdisposition\tevidence_ref\tpreservation_requirement\tmechanism\texpected_oid\ttarget\tobserved_oid\thandoff_location\tblocking_condition\tpermitted_next_action\tstatus
    REF-0001\tarchive\tEVID-REF-GRAPH\trequired\tref\t#{base}\trefs/heads/preserve/fixture-ref\t#{base}\t-\t-\tretain fixture ref\tverified
    RANGE-0001\tarchive\tEVID-RANGE-GRAPH\trequired\tref\t#{base}\trefs/heads/preserve/fixture-range\t#{base}\t-\t-\tretain fixture ref\tverified
    """
  end

  defp assert_failed(inventory, tsv, message) do
    assert {output, status} = run(["static", inventory, tsv])
    assert status != 0
    assert output =~ message
  end

  defp mutate_copy!(path, fun) do
    copy =
      Path.join(
        Path.dirname(path),
        "mutated-#{System.unique_integer([:positive])}-#{Path.basename(path)}"
      )

    File.write!(copy, path |> File.read!() |> fun.())
    copy
  end

  defp run(args, env \\ []) do
    System.cmd("bash", [@script | args],
      cd: @repo_root,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp git!(repo, args) do
    case git(repo, args) do
      {_output, 0} -> :ok
      {output, status} -> flunk("git #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end

  defp git_output!(repo, args) do
    assert {output, 0} = git(repo, args)
    String.trim(output)
  end

  defp git(repo, args), do: System.cmd("git", ["-C", repo | args], stderr_to_stdout: true)

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.mkdir_p!(path)
    path
  end

  defp wait_for!(path, attempts \\ 100)
  defp wait_for!(path, 0), do: flunk("timed out waiting for #{path}")

  defp wait_for!(path, attempts) do
    if File.exists?(path) do
      :ok
    else
      Process.sleep(25)
      wait_for!(path, attempts - 1)
    end
  end
end
