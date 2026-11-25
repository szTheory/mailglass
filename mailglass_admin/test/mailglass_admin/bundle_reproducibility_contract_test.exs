defmodule MailglassAdmin.BundleReproducibilityContractTest do
  @moduledoc """
  Machine-checked form of BRPIPE-01: the committed admin bundle
  `priv/static/app.css` is byte-for-byte what the committed generator produces.

  `MailglassAdmin.AssetsCheck.check/1` is the single compare function. It backs
  two entry points so neither can be removed alone: the Mix task
  `mix mailglass_admin.assets.build --check` (the first step of the
  `verify.support_contract.admin` alias) and this file, which `mix test` runs
  in the same required lane (`support_contract_admin` in `ci.yml`, the whole
  test directory).

  The "detectors have teeth" blocks make a pass non-vacuous. Each one breaks a
  hermetic temp copy (a flipped byte, a truncated or deleted bundle, an appended
  CSS rule, a planted utility token, a removed scan exclusion) and requires the
  check to go red and name the fix command. The wiring block proves the check
  sits in a lane that actually runs, with a negative control for every
  assertion. The fail-closed block proves a Tailwind download or build failure
  can never become a pass.

  Nothing here writes inside `priv/static/` or mutates global Application env:
  the compare is called in-process with injected options, and every mutation
  happens in a temp directory this file creates and removes.
  """

  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias MailglassAdmin.AssetsCheck

  @admin_root Path.expand("../..", __DIR__)
  @repo_root Path.expand("../../..", __DIR__)
  @committed Path.join(@admin_root, "priv/static/app.css")
  @ci_yml Path.join(@repo_root, ".github/workflows/ci.yml")

  @check_step "mailglass_admin.assets.build --check"
  @fix_command "mix mailglass_admin.assets.build"
  @prose_directive ~r/^@source not inline\("prose"\);.*\n/m

  # Every Tailwind-driven case needs the pinned binary. Install it once, before
  # any async case starts, so concurrent cases never race a download. An
  # install failure fails every case here: the gate is closed, never skipped.
  setup_all do
    unless File.exists?(Tailwind.bin_path()), do: Tailwind.install()
    :ok
  end

  describe "committed bundle matches a fresh build" do
    test "positive check: the committed bundle is what the generator produces" do
      assert :ok = AssetsCheck.check()
    end

    test "the check never writes inside priv/static" do
      assert :ok = AssetsCheck.check()

      # A trailing second --output flag would be comma-joined into one path and
      # leave an entry like `app.css,/tmp/...` next to the bundle (F1).
      assert Path.wildcard(Path.join(@admin_root, "priv/static/app.css?*")) == []
    end

    test "task entry point: --check prints a confirmation against the committed bundle" do
      output =
        capture_io(fn ->
          Mix.Tasks.MailglassAdmin.Assets.Build.run(["--check"])
        end)

      assert output =~ "matches a fresh build"
    end
  end

  describe "detectors have teeth: committed-file mutations (hermetic copies)" do
    test "one flipped byte is drift at that offset and names the fix command" do
      bundle = File.read!(@committed)
      offset = 1000
      <<head::binary-size(offset), byte, tail::binary>> = bundle
      flipped = <<head::binary, Bitwise.bxor(byte, 0xFF), tail::binary>>
      refute flipped == bundle

      with_tmp_dir(fn dir ->
        path = Path.join(dir, "app.css")
        File.write!(path, flipped)

        size = byte_size(bundle)
        assert {:error, {:drift, ^size, ^size, ^offset}} = AssetsCheck.check(committed: path)

        {:error, reason} = AssetsCheck.check(committed: path)
        assert AssetsCheck.format_error(reason) =~ @fix_command
      end)
    end

    test "a flipped final byte is drift at the last offset" do
      bundle = File.read!(@committed)
      size = byte_size(bundle)
      last = size - 1
      <<head::binary-size(last), byte>> = bundle
      flipped = <<head::binary, Bitwise.bxor(byte, 0xFF)>>
      refute flipped == bundle

      with_tmp_dir(fn dir ->
        path = Path.join(dir, "app.css")
        File.write!(path, flipped)

        assert {:error, {:drift, ^size, ^size, ^last}} = AssetsCheck.check(committed: path)
      end)
    end

    test "one extra trailing byte is drift at the original length" do
      bundle = File.read!(@committed)
      size = byte_size(bundle)

      with_tmp_dir(fn dir ->
        path = Path.join(dir, "app.css")
        File.write!(path, bundle <> "\n")

        longer = size + 1
        assert {:error, {:drift, ^size, ^longer, ^size}} = AssetsCheck.check(committed: path)
      end)
    end

    test "a truncated bundle is drift at the truncation length" do
      bundle = File.read!(@committed)
      truncated = binary_part(bundle, 0, 5000)

      with_tmp_dir(fn dir ->
        path = Path.join(dir, "app.css")
        File.write!(path, truncated)

        size = byte_size(bundle)
        assert {:error, {:drift, ^size, 5000, 5000}} = AssetsCheck.check(committed: path)

        {:error, reason} = AssetsCheck.check(committed: path)
        assert AssetsCheck.format_error(reason) =~ @fix_command
      end)
    end

    test "a deleted bundle is reported unreadable and names the fix command" do
      with_tmp_dir(fn dir ->
        missing = Path.join(dir, "app.css")

        assert {:error, {:committed_unreadable, :enoent}} =
                 AssetsCheck.check(committed: missing)

        message = AssetsCheck.format_error({:committed_unreadable, :enoent})
        assert message =~ @fix_command
        assert message =~ "priv/static/app.css"
        assert message =~ "enoent"
      end)
    end

    test "drift text carries both sizes, the first differing offset and the fix" do
      message = AssetsCheck.format_error({:drift, 139_137, 136_877, 74_051})

      assert message =~ "Admin bundle drift"
      assert message =~ "139137"
      assert message =~ "136877"
      assert message =~ "74051"
      assert message =~ "#{@fix_command} and commit priv/static/app.css"
      refute message =~ ~r/oops/i
    end
  end

  describe "detectors have teeth: source-side mutations (hermetic copy of the inputs)" do
    test "an unmodified copy at a different absolute path still matches" do
      with_input_tree(fn admin_dir ->
        refute admin_dir =~ @admin_root
        assert :ok = AssetsCheck.check(cd: admin_dir, committed: @committed)
      end)
    end

    test "an appended CSS rule in assets/css/app.css reports drift" do
      committed_size = byte_size(File.read!(@committed))

      with_input_tree(fn admin_dir ->
        css = Path.join(admin_dir, "assets/css/app.css")
        File.write!(css, File.read!(css) <> "\n.mg-bundle-probe{color:red}\n")

        assert {:error, {:drift, fresh, ^committed_size, _offset}} =
                 AssetsCheck.check(cd: admin_dir, committed: @committed)

        assert fresh > committed_size
      end)
    end

    test "the utility token tracking-widest planted in a lib/ string reports drift" do
      committed_size = byte_size(File.read!(@committed))

      with_input_tree(fn admin_dir ->
        # Tailwind scans lib/ as plain text, so a utility-looking word inside any
        # string or comment emits that class. `tracking-widest` is absent from
        # the committed bundle; a word already present (`underline`) would not
        # prove anything.
        probe = Path.join(admin_dir, "lib/zz_bundle_probe.ex")
        File.write!(probe, ~s|defmodule ZzBundleProbe do\n  @probe "tracking-widest"\nend\n|)

        assert {:error, {:drift, fresh, ^committed_size, _offset}} =
                 AssetsCheck.check(cd: admin_dir, committed: @committed)

        assert fresh > committed_size
      end)
    end

    test "removing the @source not inline(\"prose\") exclusion reports drift" do
      committed_size = byte_size(File.read!(@committed))

      with_input_tree(fn admin_dir ->
        css = Path.join(admin_dir, "assets/css/app.css")
        original = File.read!(css)
        mutated = Regex.replace(@prose_directive, original, "")
        refute mutated == original, "the prose exclusion line must exist in assets/css/app.css"
        File.write!(css, mutated)

        # Phase 179 copy text holds the bare word "prose"; without the exclusion
        # the scanner emits daisyUI .prose rules (measured at HEAD before the
        # fix: 139137 fresh bytes against 136877 committed, first difference at
        # byte 74051). Assert the shape, not those sizes, so a later legitimate
        # token or copy change does not turn this into churn.
        assert {:error, {:drift, fresh, ^committed_size, offset}} =
                 AssetsCheck.check(cd: admin_dir, committed: @committed)

        assert fresh > committed_size
        assert offset < committed_size
      end)
    end

    test "run_check! raises a Mix.Error naming the fix command on a drifted tree" do
      with_input_tree(fn admin_dir ->
        css = Path.join(admin_dir, "assets/css/app.css")
        File.write!(css, File.read!(css) <> "\n.mg-bundle-probe{color:red}\n")

        error =
          assert_raise Mix.Error, fn ->
            AssetsCheck.run_check!(cd: admin_dir, committed: @committed)
          end

        assert Exception.message(error) =~ ~r/mix mailglass_admin\.assets\.build/
        assert Exception.message(error) =~ "Admin bundle drift"
      end)
    end
  end

  describe "task option handling" do
    test "an unknown flag is rejected loudly" do
      assert_raise Mix.Error, ~r/unknown option/, fn ->
        Mix.Tasks.MailglassAdmin.Assets.Build.run(["--wat"])
      end
    end

    test "positional arguments are rejected loudly" do
      assert_raise Mix.Error, ~r/unexpected positional arguments/, fn ->
        Mix.Tasks.MailglassAdmin.Assets.Build.run(["app.css"])
      end
    end
  end

  describe "wiring: the check sits in a lane that actually runs" do
    test "alias first step is the --check step" do
      assert alias_leads_with_check?(support_contract_alias())
    end

    test "alias carries no test-file allow-list" do
      refute alias_has_file_allow_list?(support_contract_alias())
    end

    test "verify.preview ends in the --check step, not a git diff nobody runs" do
      steps = Mix.Project.config()[:aliases][:"verify.preview"]

      assert List.last(steps) == @check_step
      refute Enum.any?(steps, &(&1 =~ "git diff"))
    end

    test "ci.yml job support_contract_admin runs the alias" do
      assert ci_runs_admin_alias?(File.read!(@ci_yml))
    end

    test "ci_green needs the support_contract_admin job" do
      assert ci_green_needs_admin_lane?(File.read!(@ci_yml))
    end

    test "negative controls: each wiring detector goes red when its line is removed" do
      steps = support_contract_alias()
      ci = File.read!(@ci_yml)

      # Alias: dropping the step, reordering it, or adding a file list is caught.
      [_check | without_check] = steps
      refute alias_leads_with_check?(without_check)
      refute alias_leads_with_check?(without_check ++ [@check_step])
      assert alias_has_file_allow_list?(steps ++ ["test test/mailglass_admin/some_test.exs"])

      # ci.yml: the job no longer runs the alias.
      without_alias_run =
        String.replace(ci, "mix verify.support_contract.admin", "mix test --warnings-as-errors")

      refute ci_runs_admin_alias?(without_alias_run)

      # ci.yml: ci_green no longer waits for the job.
      without_need = String.replace(ci, "      - support_contract_admin\n", "")
      refute ci_green_needs_admin_lane?(without_need)

      # A missing job block never satisfies either detector.
      refute ci_runs_admin_alias?("jobs:\n")
      refute ci_green_needs_admin_lane?("jobs:\n")
    end
  end

  describe "fail closed: a Tailwind failure is never a pass" do
    test "an installer that raises propagates the raise" do
      with_tmp_dir(fn dir ->
        missing_bin = Path.join(dir, "tailwind-not-installed")

        assert_raise RuntimeError, "download failed", fn ->
          AssetsCheck.check(
            bin_path: missing_bin,
            installer: fn -> raise "download failed" end
          )
        end
      end)
    end

    test "an installer that leaves no binary behind still raises, never returns :ok" do
      with_tmp_dir(fn dir ->
        missing_bin = Path.join(dir, "tailwind-not-installed")

        assert_raise ErlangError, fn ->
          AssetsCheck.check(bin_path: missing_bin, installer: fn -> :ok end)
        end
      end)
    end

    test "a Tailwind build that exits non-zero is reported with its status and output" do
      with_tmp_dir(fn dir ->
        failing_bin = write_script(dir, "tailwind-fails", "echo boom\nexit 3\n")

        assert {:error, {:tailwind_failed, 3, "boom"}} =
                 AssetsCheck.check(bin_path: failing_bin)

        message = AssetsCheck.format_error({:tailwind_failed, 3, "boom"})
        assert message =~ "status 3"
        assert message =~ "boom"
      end)
    end

    test "a Tailwind build that exits 0 without writing output raises, never returns :ok" do
      with_tmp_dir(fn dir ->
        silent_bin = write_script(dir, "tailwind-silent", "exit 0\n")

        assert_raise File.Error, fn -> AssetsCheck.check(bin_path: silent_bin) end
      end)
    end
  end

  # -- helpers ---------------------------------------------------------------

  defp support_contract_alias do
    Mix.Project.config()[:aliases][:"verify.support_contract.admin"]
  end

  defp alias_leads_with_check?(steps), do: is_list(steps) and List.first(steps) == @check_step

  defp alias_has_file_allow_list?(steps) do
    Enum.any?(steps, fn step -> is_binary(step) and step =~ ~r{test/} end)
  end

  defp ci_runs_admin_alias?(ci_source) do
    extract_job_block(ci_source, "support_contract_admin") =~ "mix verify.support_contract.admin"
  end

  defp ci_green_needs_admin_lane?(ci_source) do
    "support_contract_admin" in job_needs(ci_source, "ci_green")
  end

  # Same shape as test/scripts/required_checks_test.exs (per-file duplication is
  # the repo convention for ci.yml readers).
  defp extract_job_block(source, job_key) do
    marker = "  #{job_key}:\n"

    case String.split(source, marker, parts: 2) do
      [_, rest] -> marker <> (rest |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2) |> hd())
      _ -> ""
    end
  end

  defp job_needs(source, job_key) do
    case source |> extract_job_block(job_key) |> String.split("    needs:\n", parts: 2) do
      [_, rest] ->
        rest
        |> String.split("\n")
        |> Enum.take_while(&String.starts_with?(&1, "      - "))
        |> Enum.map(&String.trim_leading(&1, "      - "))

      _ ->
        []
    end
  end

  # Builds a throwaway directory under the system temp dir, runs `fun` with it,
  # and removes the directory this test created.
  defp with_tmp_dir(fun) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "mg-bundle-contract-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)

    try do
      fun.(dir)
    after
      File.rm_rf!(dir)
    end
  end

  # Copies the real build inputs into a temp tree that keeps the relative layout
  # `app.css` depends on (`../../../brandbook/tokens.css` from assets/css), so
  # the build runs at a different absolute path. Yields the temp
  # `mailglass_admin/` directory. brandbook/tokens.css has no @import lines.
  defp with_input_tree(fun) do
    with_tmp_dir(fn root ->
      admin_dir = Path.join(root, "mailglass_admin")
      brandbook_dir = Path.join(root, "brandbook")

      File.mkdir_p!(admin_dir)
      File.mkdir_p!(brandbook_dir)
      File.cp_r!(Path.join(@admin_root, "assets"), Path.join(admin_dir, "assets"))
      File.cp_r!(Path.join(@admin_root, "lib"), Path.join(admin_dir, "lib"))

      File.cp!(
        Path.join(@repo_root, "brandbook/tokens.css"),
        Path.join(brandbook_dir, "tokens.css")
      )

      fun.(admin_dir)
    end)
  end

  defp write_script(dir, name, body) do
    path = Path.join(dir, name)
    File.write!(path, "#!/bin/sh\n" <> body)
    File.chmod!(path, 0o755)
    path
  end
end
