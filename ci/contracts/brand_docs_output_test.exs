output_root = System.get_env("MAILGLASS_DOCS_OUTPUT_ROOT")

unless output_root && output_root != "" && File.dir?(output_root) do
  Mix.raise("MAILGLASS_DOCS_OUTPUT_ROOT must name an existing generated docs output root")
end

Application.put_env(:mailglass, :script_library_mode, true)
Code.require_file("scripts/brand_docs_check.exs")
Code.require_file("scripts/brand_trademark_gate.exs")
ExUnit.start()

defmodule Mailglass.BrandDocsOutputContractTest do
  use ExUnit.Case, async: true

  @output_root System.get_env("MAILGLASS_DOCS_OUTPUT_ROOT") |> Path.expand()

  test "all three real package outputs contain pinned media and native ExDoc behavior" do
    for package <- ["core", "admin", "inbound"] do
      output = Path.join(@output_root, package)

      case Mailglass.BrandDocsCheck.verify_output(output, package) do
        {:ok, %{package: ^package}} ->
          :ok

        {:error, issues} ->
          flunk("#{package} generated docs failed: #{inspect(issues)}")
      end
    end
  end
end
