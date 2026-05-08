# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Mailglass.Upgrade.V0_2Test do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Igniter.Test

  @fixtures_root Path.expand("../../fixtures/upgrade", __DIR__)
  @migration_guide_url "https://hexdocs.pm/mailglass/guides/upgrading-to-v1_0.html"

  setup do
    [
      igniter: test_project()
    ]
  end

  defp assert_file_content(igniter, file_path, expected_content) do
    source = Rewrite.source!(igniter.rewrite, file_path)
    actual_content = Rewrite.Source.get(source, :content) |> String.trim()
    assert actual_content == expected_content |> String.trim()
  end

  defp fixture!(name) do
    @fixtures_root
    |> Path.join(name)
    |> File.read!()
  end

  test "does not rewrite string literals", %{igniter: igniter} do
    igniter =
      igniter
      |> Igniter.Project.Module.create_module(MyApp.Dummy, """
      def m() do
        "Swoosh.Email.to(msg, \\"a@b.com\\")"
      end
      """)
      |> Igniter.compose_task(Mix.Tasks.Mailglass.Upgrade.V0_2)
      |> apply_igniter!()

    assert_file_content(igniter, "lib/my_app/dummy.ex", """
    defmodule MyApp.Dummy do
      def m() do
        "Swoosh.Email.to(msg, \\"a@b.com\\")"
      end
    end
    """)
  end

  test "rewrites committed supported v0.1 fixture with zero manual edits", %{igniter: igniter} do
    igniter =
      igniter
      |> Igniter.create_new_file(
        "lib/fixture/supported_before.ex",
        fixture!("v0_2_supported_before.ex")
      )
      |> Igniter.compose_task(Mix.Tasks.Mailglass.Upgrade.V0_2)
      |> apply_igniter!()

    assert_file_content(
      igniter,
      "lib/fixture/supported_before.ex",
      fixture!("v0_2_supported_after.ex")
    )

    assert {:ok, _ast} =
             igniter.rewrite
             |> Rewrite.source!("lib/fixture/supported_before.ex")
             |> Rewrite.Source.get(:content)
             |> Code.string_to_quoted()
  end

  test "rewrites attachment/2 to attach/2", %{igniter: igniter} do
    igniter =
      igniter
      |> Igniter.Project.Module.create_module(MyApp.Dummy, """
      def m() do
        msg
        |> Swoosh.Email.attachment("path/to/file")
      end
      """)
      |> Igniter.compose_task(Mix.Tasks.Mailglass.Upgrade.V0_2)
      |> apply_igniter!()

    assert_file_content(igniter, "lib/my_app/dummy.ex", """
    defmodule MyApp.Dummy do
      def m() do
        msg
        |> attach("path/to/file")
      end
    end
    """)
  end

  test "keeps ambiguous Swoosh usage in place and warns with migration-guide URL", %{
    igniter: igniter
  } do
    warning_output =
      capture_io(:stderr, fn ->
        igniter =
          igniter
          |> Igniter.create_new_file(
            "lib/fixture/ambiguous_before.ex",
            fixture!("v0_2_ambiguous_before.ex")
          )
          |> Igniter.compose_task(Mix.Tasks.Mailglass.Upgrade.V0_2)
          |> apply_igniter!()

        assert_file_content(
          igniter,
          "lib/fixture/ambiguous_before.ex",
          fixture!("v0_2_ambiguous_after.ex")
        )
      end)

    assert warning_output =~ "Skipping unknown Swoosh.Email function: put_provider_option/2"
    assert warning_output =~ @migration_guide_url
    assert warning_output =~ "Mailglass.Message.update_swoosh/2"
  end
end
