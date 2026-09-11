Code.require_file("../../scripts/validate_repository_truth.exs", __DIR__)

defmodule Mailglass.Scripts.Phase164RepositoryTruthTest do
  use ExUnit.Case, async: true

  alias Mailglass.RepositoryTruthLedger, as: Ledger

  @repo_root Path.expand("../..", __DIR__)
  @phase_dir ".planning/phases/164-repository-truth-reconciliation-and-closeout"
  @ledger Path.join(@repo_root, Path.join(@phase_dir, "164-TRUTH-DISPOSITION.tsv"))
  @headers [
    "stable_id",
    "subject",
    "kind",
    "producer",
    "state",
    "authority",
    "reproducibility",
    "currentness",
    "durable_consumer",
    "evidence",
    "disposition",
    "rationale"
  ]
  @ignore_files [
    ".gitignore",
    "mailglass_admin/.gitignore",
    "mailglass_inbound/.gitignore",
    "reference/demo_app/.gitignore",
    "reference/host_app/.gitignore",
    "test/example/.gitignore"
  ]
  @locked_digest "331810b4b1724452f0e2707c800230e52fabea01c3773d362b3a1240040ece7e"

  test "parses and validates the authoritative twelve-column ledger" do
    contents = File.read!(@ledger)

    assert {:ok, %{headers: @headers, rows: rows}} = Ledger.parse(contents)
    assert rows != []
    assert :ok = Ledger.validate(contents, @repo_root)

    assert {:ok, subjects} = Ledger.audit_subjects(@repo_root)
    assert MapSet.member?(subjects, "scripts/validate_repository_truth.exs")
    assert MapSet.member?(subjects, Path.join(@phase_dir, "164-VERIFICATION.md"))
  end

  test "D-08 retains its locked stale removal identity" do
    assert {:ok, %{rows: rows}} = Ledger.parse(File.read!(@ledger))
    assert [row] = Enum.filter(rows, &(&1["subject"] == "scheduled-control-sweep.json"))
    assert row["stable_id"] == "D-08"
    assert row["disposition"] == "remove"
    assert row["evidence"] =~ @locked_digest
  end

  test "rejects malformed schema, exact-currentness forgeries, and stale retained rows" do
    valid = valid_row()

    assert {:error, {:invalid_header, _}} = Ledger.parse("wrong\theader\n" <> valid)

    assert {:error, {:invalid_currentness, "current-forged"}} =
             Ledger.parse(
               header_line() <> "\n" <> String.replace(valid, "\tstale\t", "\tcurrent-forged\t")
             )

    assert {:error, {:invalid_currentness, "stale-looking"}} =
             Ledger.parse(
               header_line() <> "\n" <> String.replace(valid, "\tstale\t", "\tstale-looking\t")
             )

    assert {:error, {:stale_without_outcome, "scheduled-control-sweep.json"}} =
             Ledger.parse(
               header_line() <> "\n" <> String.replace(valid, "\tremove\t", "\tretain\t")
             )

    assert {:error, {:invalid_kind_relationship, "scheduled-control-sweep.json"}} =
             Ledger.parse(
               header_line() <> "\n" <> String.replace(valid, "\tremove\t", "\tarchive\t")
             )
  end

  test "rejects empty, incomplete, and duplicate-subject ledgers" do
    valid = valid_row()

    assert {:error, :empty_ledger} = Ledger.parse("")
    assert {:error, :empty_ledger} = Ledger.parse(header_line() <> "\n")

    assert {:error, {:blank_required_field, "kind"}} =
             Ledger.parse(header_line() <> "\n" <> String.replace(valid, "generated-output", ""))

    assert {:error, {:duplicate_subject, "scheduled-control-sweep.json"}} =
             Ledger.parse(header_line() <> "\n" <> valid <> "\n" <> valid)
  end

  test "validates independently of row ordering and fails missing audited subject classes" do
    contents = File.read!(@ledger)
    [header | rows] = String.split(String.trim_trailing(contents), "\n", trim: true)

    assert :ok = Ledger.validate(Enum.join([header | Enum.reverse(rows)], "\n") <> "\n", @repo_root)

    for subject <- [
          "scripts/validate_repository_truth.exs",
          Path.join(@phase_dir, "164-VERIFICATION.md"),
          "ignore:.gitignore:/tmp/",
          ".planning/release-target.json"
        ] do
      assert {:error, {:missing_audited_subjects, missing}} =
               contents |> remove_subject(subject) |> Ledger.validate(@repo_root)

      assert subject in missing
    end
  end

  test "rejects fabricated semantic authority fields and extra subjects" do
    contents = File.read!(@ledger)

    mutations = [
      mutate_first_row(contents, "stable_id", "FORGED"),
      mutate_first_row(contents, "kind", "forged-kind"),
      mutate_first_row(contents, "producer", "forged-producer"),
      mutate_first_row(contents, "state", "forged-state"),
      mutate_first_row(contents, "authority", "forged-authority"),
      mutate_first_row(contents, "reproducibility", "forged-reproducibility"),
      mutate_first_row(contents, "durable_consumer", "forged-consumer"),
      mutate_first_row(contents, "evidence", "fabricated-evidence")
    ]

    for mutation <- mutations do
      assert {:error, _reason} = Ledger.validate(mutation, @repo_root)
    end

    [header | rows] = String.split(contents, "\n", trim: true)
    tracked = Enum.find(rows, &String.starts_with?(&1, "M-01\t"))

    fabricated =
      tracked
      |> String.replace_prefix("M-01\t", "M-99\t")
      |> String.replace("\t#{Enum.at(String.split(tracked, "\t"), 1)}\t", "\tfabricated-subject\t")

    assert {:error, {:invalid_canonical_relationship, "fabricated-subject"}} =
             Ledger.validate(contents <> fabricated <> "\n", @repo_root)

    assert header == header_line()
  end

  test "rejects cross-row borrowing of canonical authority relationships" do
    contents = File.read!(@ledger)

    transplanted =
      swap_row_semantics(
        contents,
        "README.md",
        ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md"
      )

    assert {:error,
            {:invalid_canonical_relationship,
             ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md"}} =
             Ledger.validate(transplanted, @repo_root)
  end

  test "rejects a whitelisted producer transplanted onto an ignore subject" do
    contents = File.read!(@ledger)
    subject = "ignore:.gitignore:/_build/"

    transplanted = mutate_subject_row(contents, subject, "producer", "GSD phase lifecycle")

    assert {:error, {:invalid_canonical_relationship, ^subject}} =
             Ledger.validate(transplanted, @repo_root)
  end

  test "rejects stable IDs swapped between ignore subjects" do
    contents = File.read!(@ledger)
    first_subject = "ignore:.gitignore:/_build/"
    second_subject = "ignore:.gitignore:/cover/"

    swapped = swap_subject_column(contents, first_subject, second_subject, "stable_id")

    assert {:error, {:invalid_canonical_relationship, subject}} =
             Ledger.validate(swapped, @repo_root)

    assert subject in [first_subject, second_subject]
  end

  test "fails closed for an otherwise valid non-ignore subject absent from the canonical map" do
    contents = File.read!(@ledger)
    canonical_subject = "README.md"
    unmapped_subject = "future-audited-proof.md"

    [header | rows] = String.split(String.trim_trailing(contents), "\n", trim: true)
    row = Enum.find(rows, &String.contains?(&1, "\t#{canonical_subject}\t"))
    unmapped = String.replace(row, "\t#{canonical_subject}\t", "\t#{unmapped_subject}\t")

    assert {:error, {:invalid_canonical_relationship, ^unmapped_subject}} =
             Ledger.parse(Enum.join([header, unmapped], "\n") <> "\n")
  end

  test "git runtime rules do not conceal the retired finalize-phase extension paths" do
    assert ignored?(".gsd/gsd.db")
    assert ignored?(".gsd/exec/probe")
    assert ignored?(".gsd/extensions/other/index.ts")
    refute ignored?(".gsd/extensions/finalize-phase/index.ts")
    refute ignored?(".gsd/extensions/finalize-phase/extension-manifest.json")
  end

  test "git ignores the canonical GSD lifecycle lock while planning proof stays visible" do
    assert ignored?(".planning/milestone.lock")
    refute ignored?(".planning/milestone-lock-proof.json")
    refute ignored?(".planning/release-target.json")
  end

  test "retired extension rows preserve removal provenance and name the retained replacement" do
    assert {:ok, %{rows: rows}} = Ledger.parse(File.read!(@ledger))

    for subject <- [
          ".gsd/extensions/finalize-phase/extension-manifest.json",
          ".gsd/extensions/finalize-phase/index.ts"
        ] do
      assert [row] = Enum.filter(rows, &(&1["subject"] == subject))
      assert row["state"] == "untracked"
      assert row["currentness"] == "historical"
      assert row["disposition"] == "remove"
      assert row["evidence"] =~ "164-22-PLAN.md"
      assert row["rationale"] =~ "scripts/mailglass_finalize_phase_loader.mjs"
    end

    assert [replacement] =
             Enum.filter(rows, &(&1["subject"] == "scripts/mailglass_finalize_phase_loader.mjs"))

    assert replacement["state"] == "tracked"
    assert replacement["currentness"] == "current"
    assert replacement["disposition"] == "retain"
  end

  test "retained finalization artifacts have exactly one tracked current disposition" do
    assert {:ok, %{rows: rows}} = Ledger.parse(File.read!(@ledger))

    for subject <- [
          ".gitignore",
          "scripts/finalize_phase_164.sh",
          Path.join(@phase_dir, "164-FINALIZE.sh"),
          Path.join(@phase_dir, "164-FINALIZATION.md"),
          "scripts/ci_monitor.cjs",
          "scripts/scheduled_control_evidence.sh",
          "test/scripts/scheduled_control_evidence_test.exs"
        ] do
      assert [row] = Enum.filter(rows, &(&1["subject"] == subject))
      assert row["state"] == "tracked"
      assert row["currentness"] == "current"
      assert row["disposition"] == "retain"
    end
  end

  describe "phase 164 gap closure" do
    @describetag :phase_164_gap_closure

    test "rejects every forged currentness spelling by exact enum membership" do
      valid = valid_row()

      for forged <- [
            "current-forged",
            "current_extra",
            "historical-forged",
            "stale-looking",
            " current",
            "current ",
            "CURRENT"
          ] do
        contents =
          header_line() <> "\n" <> String.replace(valid, "\tstale\t", "\t#{forged}\t")

        assert {:error, {:invalid_currentness, ^forged}} = Ledger.parse(contents)
      end
    end

    test "rejects stale retain while accepting the locked canonical stale removal" do
      valid = valid_row()

      assert {:ok, %{rows: [%{"currentness" => "stale", "disposition" => "remove"}]}} =
               Ledger.parse(header_line() <> "\n" <> valid)

      assert {:error, {:stale_without_outcome, "scheduled-control-sweep.json"}} =
               Ledger.parse(
                 header_line() <> "\n" <> String.replace(valid, "\tremove\t", "\tretain\t")
               )
    end

    test "rejects vacuous and incomplete inventories across every audited subject class" do
      contents = File.read!(@ledger)

      assert {:error, :empty_ledger} = Ledger.parse("")
      assert {:error, :empty_ledger} = Ledger.parse(header_line() <> "\n")

      assert {:error, {:missing_audited_subjects, missing}} =
               Ledger.validate(header_line() <> "\n" <> valid_row() <> "\n", @repo_root)

      assert missing != []

      for subject <- [
            "ignore:.gitignore:/tmp/",
            "ignore:mailglass_admin/.gitignore:/tmp/",
            "ignore:mailglass_inbound/.gitignore:/deps/",
            "ignore:reference/demo_app/.gitignore:/tmp/",
            "ignore:reference/host_app/.gitignore:/deps/",
            "ignore:test/example/.gitignore:!README.md",
            ".planning/publish/mailglass-files.expected",
            ".planning/release-target.json",
            "scripts/validate_repository_truth.exs",
            Path.join(@phase_dir, "164-VERIFICATION.md")
          ] do
        assert {:error, {:missing_audited_subjects, missing}} =
                 contents |> remove_subject(subject) |> Ledger.validate(@repo_root)

        assert subject in missing
      end
    end

    test "duplicate identity errors and validation results are independent of row order" do
      contents = File.read!(@ledger)
      [header | rows] = String.split(String.trim_trailing(contents), "\n", trim: true)
      subject = "README.md"
      duplicate = Enum.find(rows, &String.contains?(&1, "\t#{subject}\t"))
      insertion_index = Enum.find_index(rows, &(&1 == duplicate))

      adjacent = List.insert_at(rows, insertion_index, duplicate)
      separated = rows ++ [duplicate]

      for duplicate_rows <- [adjacent, separated] do
        assert {:error, {:duplicate_subject, ^subject}} =
                 Ledger.parse(Enum.join([header | duplicate_rows], "\n") <> "\n")
      end

      rotated = Enum.drop(rows, 17) ++ Enum.take(rows, 17)

      for reordered <- [Enum.reverse(rows), rotated] do
        assert :ok = Ledger.validate(Enum.join([header | reordered], "\n") <> "\n", @repo_root)
      end

      forged = mutate_subject_row(contents, subject, "currentness", "current-forged")
      [forged_header | forged_rows] = String.split(String.trim_trailing(forged), "\n", trim: true)

      for reordered <- [forged_rows, Enum.reverse(forged_rows)] do
        assert {:error, {:invalid_currentness, "current-forged"}} =
                 Ledger.parse(Enum.join([forged_header | reordered], "\n") <> "\n")
      end
    end
  end

  describe "phase 164 trust anchors" do
    @describetag :phase_164_trust_anchor

    test "tracked ledger claims require exact Git index membership" do
      repo = clone_repository!()
      ledger = File.read!(Path.join(repo, Path.join(@phase_dir, "164-TRUTH-DISPOSITION.tsv")))

      assert :ok = Ledger.validate(ledger, repo)
      assert {_output, 0} = System.cmd("git", ["rm", "--cached", "--", "README.md"], cd: repo)
      assert File.regular?(Path.join(repo, "README.md"))

      assert {:error, {:tracked_subject_untracked, "README.md"}} = Ledger.validate(ledger, repo)
    end

    test "literal metacharacter and prefix-adjacent paths cannot satisfy another subject" do
      repo = clone_repository!()
      literal = "proof[1]*?.txt"
      adjacent = literal <> ".backup"
      File.write!(Path.join(repo, literal), "literal\n")
      File.write!(Path.join(repo, adjacent), "adjacent\n")
      assert {_output, 0} = System.cmd("git", ["add", "--", literal, adjacent], cd: repo)

      assert :ok = Ledger.tracked_subject_in_index(repo, literal)
      assert :ok = Ledger.tracked_subject_in_index(repo, adjacent)
      assert {_output, 0} = System.cmd("git", ["rm", "--cached", "--", literal], cd: repo)
      assert File.regular?(Path.join(repo, literal))

      assert {:error, {:tracked_subject_untracked, ^literal}} =
               Ledger.tracked_subject_in_index(repo, literal)

      assert :ok = Ledger.tracked_subject_in_index(repo, adjacent)
    end

    test "standalone CLI fails closed while requiring the module stays side-effect free" do
      script = Path.join(@repo_root, "scripts/validate_repository_truth.exs")
      elixir = System.find_executable("elixir")

      for args <- [[], ["--unknown"], ["--repo", @repo_root], ["--ledger", @ledger]] do
        {output, status} = System.cmd(elixir, [script | args], stderr_to_stdout: true)
        assert status != 0
        assert output =~ "repository truth ledger:"
        assert byte_size(output) < 1_024
      end

      {output, 0} =
        System.cmd(elixir, [script, "--repo", @repo_root, "--ledger", @ledger],
          stderr_to_stdout: true
        )

      assert output =~ "repository truth ledger: valid"

      require_expression =
        "Code.require_file(#{inspect(script)}); IO.puts(\"repository truth module: loaded\")"

      {output, 0} =
        System.cmd(elixir, ["-e", require_expression, "--", "--unknown"], stderr_to_stdout: true)

      assert output == "repository truth module: loaded\n"
    end
  end

  describe "phase 164 incomplete authority root" do
    @describetag :phase_164_incomplete_authority_root

    test "existing empty authority root returns one bounded deterministic CLI diagnostic" do
      authority_root =
        Path.join(
          System.tmp_dir!(),
          "mailglass-phase-164-empty-authority-#{System.unique_integer([:positive])}"
        )

      File.mkdir!(authority_root)
      on_exit(fn -> File.rm_rf!(authority_root) end)

      script = Path.join(@repo_root, "scripts/validate_repository_truth.exs")
      elixir = System.find_executable("elixir")

      expected =
        "repository truth ledger: {:missing_authority_subject, \".gitignore\"}\n" <>
          "usage: validate_repository_truth.exs --repo PATH [--authority-root PATH] --ledger PATH\n"

      results =
        for _run <- 1..2 do
          result =
            System.cmd(
              elixir,
              [
                script,
                "--repo",
                @repo_root,
                "--authority-root",
                authority_root,
                "--ledger",
                @ledger
              ],
              stderr_to_stdout: true
            )

          assert File.ls!(authority_root) == []
          result
        end

      assert Enum.map(results, &elem(&1, 1)) == [1, 1]
      assert Enum.map(results, &elem(&1, 0)) == [expected, expected]

      refute expected =~ "File.Error"
      refute expected =~ "** ("
      refute expected =~ "scripts/validate_repository_truth.exs:"
      refute expected =~ "    ("
    end

    test "authority subjects stop at the first missing file in declared order" do
      authority_root = authority_root!()

      for {ignore_file, index} <- Enum.with_index(@ignore_files) do
        assert ignore_subjects_result(authority_root) ==
                 {:error, {:missing_authority_subject, ignore_file}}

        write_authority_subject!(authority_root, ignore_file, "/fixture-#{index}/\n")
      end

      assert Ledger.ignore_subjects(authority_root) ==
               {:ok,
                Enum.with_index(@ignore_files, fn ignore_file, index ->
                  "ignore:#{ignore_file}:/fixture-#{index}/"
                end)}
    end

    test "wrong-type and unreadable authority subjects return bounded tagged reasons" do
      next_subject = Enum.at(@ignore_files, 1)

      directory_root = authority_root!()
      write_authority_subject!(directory_root, ".gitignore", "/root/\n")
      File.mkdir_p!(Path.join(directory_root, next_subject))

      symlink_root = authority_root!()
      write_authority_subject!(symlink_root, ".gitignore", "/root/\n")
      symlink_path = Path.join(symlink_root, next_subject)
      File.mkdir_p!(Path.dirname(symlink_path))
      File.ln_s!(Path.join(@repo_root, next_subject), symlink_path)

      unreadable_root = authority_root!()
      write_authority_subject!(unreadable_root, ".gitignore", "/root/\n")
      unreadable_path = Path.join(unreadable_root, next_subject)
      write_authority_subject!(unreadable_root, next_subject, "/private/\n")
      File.chmod!(unreadable_path, 0o000)

      malformed_root = authority_root!()
      write_authority_subject!(malformed_root, ".gitignore", "/root/\n")
      File.write!(Path.join(malformed_root, "mailglass_admin"), "not a directory\n")

      api_results =
        for root <- [directory_root, symlink_root, unreadable_root, malformed_root] do
          ignore_subjects_result(root)
        end

      script = Path.join(@repo_root, "scripts/validate_repository_truth.exs")
      elixir = System.find_executable("elixir")

      cli_result =
        System.cmd(
          elixir,
          [
            script,
            "--repo",
            @repo_root,
            "--authority-root",
            directory_root,
            "--ledger",
            @ledger
          ],
          stderr_to_stdout: true
        )

      expected_cli =
        "repository truth ledger: {:missing_authority_subject, #{inspect(next_subject)}}\n" <>
          "usage: validate_repository_truth.exs --repo PATH [--authority-root PATH] --ledger PATH\n"

      assert cli_result == {expected_cli, 1}

      assert api_results == [
               {:error, {:missing_authority_subject, next_subject}},
               {:error, {:missing_authority_subject, next_subject}},
               {:error, {:unreadable_authority_subject, next_subject, :eacces}},
               {:error, {:missing_authority_subject, next_subject}}
             ]
    end
  end

  describe "phase 164 stage-0 index identity" do
    @describetag :phase_164_stage0_index

    test "rejects a genuine unmerged subject through the helper and full validator" do
      repo = clone_repository!()
      subject = "README.md"
      ledger = File.read!(Path.join(repo, Path.join(@phase_dir, "164-TRUTH-DISPOSITION.tsv")))

      install_unmerged_index_entry!(repo, subject)

      {staged, 0} =
        System.cmd(
          "git",
          ["--literal-pathspecs", "ls-files", "--stage", "--", subject],
          cd: repo
        )

      assert length(String.split(staged, "\n", trim: true)) == 3
      refute staged =~ " 0\t"

      assert {:error, {:tracked_subject_identity_mismatch, ^subject, _records}} =
               Ledger.tracked_subject_in_index(repo, subject)

      assert {:error, {:tracked_subject_identity_mismatch, ^subject, _records}} =
               Ledger.validate(ledger, repo)
    end

    test "accepts one ordinary committed stage-0 record with byte-exact identity" do
      repo = clone_repository!()
      subject = "stage-zero\nproof.txt"
      File.write!(Path.join(repo, subject), "proof\n")
      assert {_output, 0} = System.cmd("git", ["add", "--", subject], cd: repo)

      assert :ok = Ledger.tracked_subject_in_index(repo, subject)
    end

    test "literal metacharacters, adjacent names, newlines, and record order preserve identity" do
      repo = clone_repository!()
      literal = "stage[0]*?.txt"
      adjacent = literal <> ".backup"
      newline = "stage-zero\nrecord.txt"

      for subject <- [literal, adjacent, newline] do
        File.write!(Path.join(repo, subject), subject)
      end

      assert {_output, 0} = System.cmd("git", ["add", "--", literal, adjacent, newline], cd: repo)
      assert :ok = Ledger.tracked_subject_in_index(repo, literal)
      assert :ok = Ledger.tracked_subject_in_index(repo, adjacent)
      assert :ok = Ledger.tracked_subject_in_index(repo, newline)

      assert {:error, {:tracked_subject_identity_mismatch, ^literal, _records}} =
               Ledger.validate_staged_index_output(
                 stage_record(adjacent) <> stage_record(literal),
                 literal
               )

      assert {:error, {:tracked_subject_identity_mismatch, ^literal, _records}} =
               Ledger.validate_staged_index_output(
                 stage_record(literal) <> stage_record(adjacent),
                 literal
               )
    end

    test "missing, duplicate, nonzero, malformed, and different records fail closed" do
      subject = "proof.txt"

      assert {:error, {:tracked_subject_malformed_output, ^subject}} =
               Ledger.validate_staged_index_output("", subject)

      for output <- [
            stage_record(subject) <> stage_record(subject),
            stage_record(subject, 1),
            stage_record(subject, 2),
            stage_record(subject, 3),
            stage_record("other.txt")
          ] do
        assert {:error, {:tracked_subject_identity_mismatch, ^subject, _records}} =
                 Ledger.validate_staged_index_output(output, subject)
      end

      for output <- [
            "not-a-mode #{String.duplicate("a", 40)} 0\t#{subject}\0",
            "100644 not-an-object 0\t#{subject}\0",
            "100644 #{String.duplicate("a", 40)} x\t#{subject}\0",
            "100644 #{String.duplicate("a", 40)} 0 #{subject}\0",
            "100644 #{String.duplicate("a", 40)} 0\t#{subject}"
          ] do
        assert {:error, {:tracked_subject_malformed_output, ^subject}} =
                 Ledger.validate_staged_index_output(output, subject)
      end
    end
  end

  defp remove_subject(contents, subject) do
    contents
    |> String.split("\n", trim: true)
    |> Enum.reject(fn line -> String.split(line, "\t", parts: 3) |> Enum.at(1) == subject end)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp header_line, do: Enum.join(@headers, "\t")

  defp ignored?(path) do
    {_output, status} =
      System.cmd("git", ["check-ignore", "-q", path], cd: @repo_root, stderr_to_stdout: true)

    status == 0
  end

  defp authority_root! do
    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-phase-164-authority-#{System.unique_integer([:positive])}"
      )

    File.mkdir!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end

  defp write_authority_subject!(authority_root, relative_path, contents) do
    path = Path.join(authority_root, relative_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end

  defp ignore_subjects_result(authority_root) do
    Ledger.ignore_subjects(authority_root)
  rescue
    error in File.Error -> {:raised, error.reason}
  end

  defp clone_repository! do
    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-phase-164-truth-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(root) end)

    assert {_output, 0} =
             System.cmd("git", ["clone", "--quiet", "--shared", @repo_root, root],
               stderr_to_stdout: true
             )

    fixture_ledger = Path.join(root, Path.join(@phase_dir, "164-TRUTH-DISPOSITION.tsv"))
    File.cp!(@ledger, fixture_ledger)

    assert {_output, 0} =
             System.cmd(
               "git",
               ["add", "--", Path.join(@phase_dir, "164-TRUTH-DISPOSITION.tsv")],
               cd: root
             )

    root
  end

  defp install_unmerged_index_entry!(repo, subject) do
    assert {_output, 0} =
             System.cmd("git", ["config", "user.email", "phase164@example.test"], cd: repo)

    assert {_output, 0} = System.cmd("git", ["config", "user.name", "Phase 164 Fixture"], cd: repo)
    base = git_output!(repo, ["rev-parse", "HEAD"])

    assert {_output, 0} = System.cmd("git", ["switch", "-c", "stage-ours"], cd: repo)
    File.write!(Path.join(repo, subject), "ours\n")
    assert {_output, 0} = System.cmd("git", ["add", "--", subject], cd: repo)
    assert {_output, 0} = System.cmd("git", ["commit", "-m", "ours"], cd: repo)

    assert {_output, 0} = System.cmd("git", ["switch", "-c", "stage-theirs", base], cd: repo)
    File.write!(Path.join(repo, subject), "theirs\n")
    assert {_output, 0} = System.cmd("git", ["add", "--", subject], cd: repo)
    assert {_output, 0} = System.cmd("git", ["commit", "-m", "theirs"], cd: repo)

    assert {_output, 0} = System.cmd("git", ["switch", "stage-ours"], cd: repo)
    assert {_output, 1} = System.cmd("git", ["merge", "--no-edit", "stage-theirs"], cd: repo)
  end

  defp git_output!(repo, args) do
    {output, 0} = System.cmd("git", args, cd: repo)
    String.trim(output)
  end

  defp stage_record(subject, stage \\ 0) do
    "100644 #{String.duplicate("a", 40)} #{stage}\t#{subject}\0"
  end

  defp valid_row do
    Enum.join(
      [
        "D-08",
        "scheduled-control-sweep.json",
        "generated-output",
        "scripts/scheduled_control_evidence.sh sweep (content shape only; no root-path producer)",
        "untracked",
        "D-08",
        "regenerable from the scheduled-control evidence workflow",
        "stale",
        "none",
        "D-08; sha256:#{@locked_digest}; Phase 162 scheduled-control proof",
        "remove",
        "stale generated root sweep"
      ],
      "\t"
    )
  end

  defp mutate_first_row(contents, column, value) do
    [header, first | rest] = String.split(String.trim_trailing(contents), "\n", trim: true)
    index = Enum.find_index(@headers, &(&1 == column))
    fields = String.split(first, "\t", trim: false)
    mutated = fields |> List.replace_at(index, value) |> Enum.join("\t")
    Enum.join([header, mutated | rest], "\n") <> "\n"
  end

  defp swap_row_semantics(contents, first_subject, second_subject) do
    semantic_indexes =
      @headers
      |> Enum.with_index()
      |> Enum.reject(fn {column, _index} -> column in ["subject", "rationale"] end)
      |> Enum.map(&elem(&1, 1))

    lines = String.split(String.trim_trailing(contents), "\n", trim: true)
    first_index = Enum.find_index(lines, &String.contains?(&1, "\t#{first_subject}\t"))
    second_index = Enum.find_index(lines, &String.contains?(&1, "\t#{second_subject}\t"))
    first = String.split(Enum.at(lines, first_index), "\t", trim: false)
    second = String.split(Enum.at(lines, second_index), "\t", trim: false)

    swap = fn target, donor ->
      Enum.reduce(semantic_indexes, target, fn index, fields ->
        List.replace_at(fields, index, Enum.at(donor, index))
      end)
      |> Enum.join("\t")
    end

    lines
    |> List.replace_at(first_index, swap.(first, second))
    |> List.replace_at(second_index, swap.(second, first))
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp mutate_subject_row(contents, subject, column, value) do
    lines = String.split(String.trim_trailing(contents), "\n", trim: true)
    row_index = Enum.find_index(lines, &String.contains?(&1, "\t#{subject}\t"))
    column_index = Enum.find_index(@headers, &(&1 == column))

    mutated =
      lines
      |> Enum.at(row_index)
      |> String.split("\t", trim: false)
      |> List.replace_at(column_index, value)
      |> Enum.join("\t")

    lines
    |> List.replace_at(row_index, mutated)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp swap_subject_column(contents, first_subject, second_subject, column) do
    lines = String.split(String.trim_trailing(contents), "\n", trim: true)
    first_index = Enum.find_index(lines, &String.contains?(&1, "\t#{first_subject}\t"))
    second_index = Enum.find_index(lines, &String.contains?(&1, "\t#{second_subject}\t"))
    column_index = Enum.find_index(@headers, &(&1 == column))
    first = String.split(Enum.at(lines, first_index), "\t", trim: false)
    second = String.split(Enum.at(lines, second_index), "\t", trim: false)

    lines
    |> List.replace_at(
      first_index,
      first |> List.replace_at(column_index, Enum.at(second, column_index)) |> Enum.join("\t")
    )
    |> List.replace_at(
      second_index,
      second |> List.replace_at(column_index, Enum.at(first, column_index)) |> Enum.join("\t")
    )
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end
end
