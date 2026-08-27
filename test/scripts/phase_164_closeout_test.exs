defmodule Mailglass.Scripts.Phase164CloseoutTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/closeout_repository_truth.sh")
  @ledger Path.join(
            @repo_root,
            ".planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv"
          )

  test "rejects a sibling checkout and a foreign symlink before component collection" do
    root = temporary_root!()
    sibling = @repo_root <> "-disposable"
    File.mkdir_p!(sibling)

    on_exit(fn ->
      File.rm_rf!(root)
      File.rm_rf!(sibling)
    end)

    link = Path.join(root, "mailglass")
    File.ln_s!(sibling, link)

    for repo <- [sibling, link] do
      marker = Path.join(root, "mix-called-#{System.unique_integer([:positive])}")
      output = Path.join(root, "outside/report.json")

      {_, status} = run(repo, @ledger, output, marker)
      assert status != 0
      refute File.exists?(marker)
      refute File.exists?(output)
    end
  end

  test "rejects copied and arbitrary ledgers before component collection" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    copied = Path.join(root, "complete-copy.tsv")
    arbitrary = Path.join(root, "one-row.tsv")
    File.cp!(@ledger, copied)

    File.write!(
      arbitrary,
      header() <>
        "\nD-01\tproof\tproof\tproducer\ttracked\tauthority\treproducible\tcurrent\tconsumer\tevidence\tretain\trationale\n"
    )

    for ledger <- [copied, arbitrary] do
      marker = Path.join(root, "mix-called-#{System.unique_integer([:positive])}")
      output = Path.join(root, "outside/report.json")

      {_, status} = run(@repo_root, ledger, output, marker)
      assert status != 0
      refute File.exists?(marker)
      refute File.exists?(output)
    end
  end

  test "the shared validator rejects malformed currentness, stale retain, missing subjects, and header-only ledgers" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    contents = File.read!(@ledger)

    mutations = [
      String.replace(contents, "\tcurrent\t", "\tcurrent-forged\t", global: false),
      String.replace(contents, "\tcurrent\t", "\tstale\t", global: false),
      header() <> "\n",
      contents |> String.split("\n") |> List.delete_at(2) |> Enum.join("\n")
    ]

    for {contents, index} <- Enum.with_index(mutations) do
      ledger = Path.join(root, "invalid-#{index}.tsv")
      File.write!(ledger, contents)

      {_, status} =
        System.cmd(
          "elixir",
          ["scripts/validate_repository_truth.exs", "--repo", @repo_root, "--ledger", ledger],
          cd: @repo_root,
          stderr_to_stdout: true
        )

      assert status != 0
    end
  end

  test "rejects non-ignored and lexical-prefix output paths before write" do
    root = temporary_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    filename = "closeout-report-#{System.unique_integer([:positive])}.json"
    tracked = Path.join(@repo_root, filename)
    prefix_escape = Path.join(@repo_root <> "-other", filename)

    for output <- [tracked, prefix_escape] do
      marker = Path.join(root, "mix-called-#{System.unique_integer([:positive])}")
      {_, status} = run(@repo_root, @ledger, output, marker)
      assert status != 0
      refute File.exists?(marker)
      refute File.exists?(output)
    end
  end

  test "uses the canonical ledger validator and samples porcelain after report writes" do
    source = File.read!(@script)
    assert source =~ "canonical_repo=/Users/jon/projects/mailglass"
    assert source =~ "validate_repository_truth.exs"
    assert source =~ "--ledger \"$canonical_ledger\""
    assert source =~ "git -C \"$repo\" check-ignore"
    assert source =~ "status --porcelain=v1 --untracked-files=all"

    assert source =~ "write_report\nfinal_porcelain=$(stable_porcelain)"
  end

  defp run(repo, ledger, output, marker) do
    root = Path.dirname(marker)
    bin = Path.join(root, "bin-#{System.unique_integer([:positive])}")
    File.mkdir_p!(bin)
    mix = Path.join(bin, "mix")
    File.write!(mix, "#!/usr/bin/env bash\nprintf invoked > #{inspect(marker)}\nexit 99\n")
    File.chmod!(mix, 0o755)

    System.cmd(
      "bash",
      [@script, "--repo", repo, "--ledger", ledger, "--ci-run-id", "123", "--output", output],
      env: [{"PATH", "#{bin}:#{System.fetch_env!("PATH")}"}],
      stderr_to_stdout: true
    )
  end

  defp header do
    "stable_id\tsubject\tkind\tproducer\tstate\tauthority\treproducibility\tcurrentness\tdurable_consumer\tevidence\tdisposition\trationale"
  end

  defp temporary_root do
    Path.join(System.tmp_dir!(), "mailglass-closeout-#{System.unique_integer([:positive])}")
  end

  defp temporary_root! do
    root = temporary_root()
    File.mkdir_p!(root)
    root
  end
end
