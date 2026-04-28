defmodule Mailglass.DocsContractTest do
  use ExUnit.Case, async: true
  import Mailglass.DocsHelpers

  describe "README.md contract" do
    test "installation snippet targets the v0.2 surface" do
      blocks = extract_code_blocks("README.md")
      install_block = Enum.find(blocks, &(&1 =~ "mix mailglass.install"))

      assert install_block
      assert install_block =~ "mix ecto.migrate"
      refute Enum.any?(blocks, &String.contains?(&1, "mix verify.phase_07"))

      readme = File.read!("README.md")
      assert readme =~ "{:mailglass, \"~> 0.2\"}"
      refute readme =~ "v0.1 in development"
    end

    test "Quickstart snippet compiles" do
      blocks = extract_code_blocks("README.md")
      mailable_code = Enum.find(blocks, &(&1 =~ "defmodule MyApp.UserMailer"))

      assert mailable_code
      assert mailable_code =~ "|> to(user.email)"
      assert {:ok, _quoted} = Code.string_to_quoted(mailable_code)
    end
  end

  describe "Task existence" do
    test "referenced tasks are available" do
      assert Mix.Task.get("mailglass.install")
      assert Mix.Task.get("mailglass.suppressions.resync")
      assert Mix.Task.get("mailglass.webhooks.prune")
      assert Mix.Task.get("mailglass.docs.check")
    end
  end

  describe "Guide contracts" do
    test "Getting Started compiles" do
      code = extract_block_after_heading("guides/getting-started.md", "4) Send your first message")
      assert code
      assert code =~ "|> to(user.email)"
      refute code =~ "Swoosh.Email.to"
      assert {:ok, _quoted} = Code.string_to_quoted(code)
    end

    test "Config examples are valid" do
      code = extract_block_after_heading("guides/getting-started.md", "2) Configure mailglass")
      assert code
      assert code =~ "config :mailglass"
      assert code =~ "repo:"
      assert code =~ "adapter:"
    end
  end
end
