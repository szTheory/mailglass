defmodule Mailglass.Upgrade.V0_2Test do
  use ExUnit.Case
  import Igniter.Test

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

  test "rewrites standard setters to native setters", %{igniter: igniter} do
    igniter =
      igniter
      |> Igniter.Project.Module.create_module(MyApp.Dummy, """
      def m() do
        msg
        |> Swoosh.Email.to("a@b.com")
        |> Swoosh.Email.from("c@d.com")
        |> Swoosh.Email.subject("hello")
        |> Swoosh.Email.text_body("world")
        |> Swoosh.Email.html_body("<h1>world</h1>")
        |> Swoosh.Email.header("x-custom", "value")
        |> Swoosh.Email.put_tag("tag1")
      end
      """)
      |> Igniter.compose_task(Mix.Tasks.Mailglass.Upgrade.V0_2)
      |> apply_igniter!()

    assert_file_content(igniter, "lib/my_app/dummy.ex", """
    defmodule MyApp.Dummy do
      def m() do
        msg
        |> to("a@b.com")
        |> from("c@d.com")
        |> subject("hello")
        |> text_body("world")
        |> html_body("<h1>world</h1>")
        |> header("x-custom", "value")
        |> put_tag("tag1")
      end
    end
    """)
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

  test "skips unknown Swoosh.Email functions", %{igniter: igniter} do
    igniter =
      igniter
      |> Igniter.Project.Module.create_module(MyApp.Dummy, """
      def m() do
        msg
        |> Swoosh.Email.put_provider_option(:k, "v")
      end
      """)
      |> Igniter.compose_task(Mix.Tasks.Mailglass.Upgrade.V0_2)
      |> apply_igniter!()

    assert_file_content(igniter, "lib/my_app/dummy.ex", """
    defmodule MyApp.Dummy do
      def m() do
        msg
        |> Swoosh.Email.put_provider_option(:k, "v")
      end
    end
    """)
  end
end
