defmodule Mailglass.DocsContractTest do
  use ExUnit.Case, async: true
  import Mailglass.DocsHelpers

  describe "README.md contract" do
    test "Installation snippet uses real tasks" do
      blocks = extract_code_blocks("README.md")
      # Find the block that contains mailglass.install
      install_block = Enum.find(blocks, &(&1 =~ "mix mailglass.install"))
      assert install_block
      assert install_block =~ "mix ecto.migrate"
      # We assert that at least one of the install/quickstart blocks contains the verify task
      assert Enum.any?(blocks, &(&1 =~ "mix verify.phase_07"))
    end

    test "Quickstart snippet compiles" do
      # Find the mailable definition
      blocks = extract_code_blocks("README.md")
      mailable_code = Enum.find(blocks, &(&1 =~ "defmodule MyApp.UserMailer"))

      assert mailable_code
      # Replace MyApp with a test name to avoid conflicts if needed,
      # but here we just want to ensure it's valid Elixir.
      assert {:ok, _quoted} = Code.string_to_quoted(mailable_code)
    end
  end

  describe "Task existence" do
    test "referenced tasks are available" do
      assert Mix.Task.get("mailglass.install")
      assert Mix.Task.get("mailglass.reconcile")
      assert Mix.Task.get("mailglass.webhooks.prune")

      # verify.phase_07 is an alias, check the project config
      aliases = Mix.Project.config()[:aliases]
      assert Keyword.has_key?(aliases, :"verify.phase_07")
    end
  end

  describe "Guide contracts" do
    test "Getting Started compiles" do
      code = extract_block_after_heading("guides/getting-started.md", "4) Send your first message")
      assert code
      assert {:ok, _quoted} = Code.string_to_quoted(code)
    end

    test "Config examples are valid" do
      # Extract config from Getting Started
      code = extract_block_after_heading("guides/getting-started.md", "2) Configure mailglass")
      assert code
      # We can't easily run Mailglass.Config.new!/1 on a raw snippet without eval,
      # but we can check if it parses and has the expected keys.
      assert code =~ "config :mailglass"
      assert code =~ "repo:"
      assert code =~ "adapter:"
    end
  end
end
