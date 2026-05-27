defmodule Mailglass.ReferenceHost.BootContractTest do
  use ExUnit.Case, async: true

  @readme_path Path.expand("../../reference/host_app/README.md", __DIR__)

  test "reference host README preserves the bootstrap contract" do
    readme = File.read!(@readme_path)

    required_tokens = [
      "Maintained trust-proof host artifact (not a fixture seed)",
      "test/example remains fixture-only",
      "mix deps.get",
      "mix ecto.create",
      "mix ecto.migrate",
      "mix compile --warnings-as-errors",
      "mix phx.server",
      "published package constraints"
    ]

    forbidden_tokens = [
      "path: \"../\"",
      "test/example baseline",
      "provider matrix"
    ]

    Enum.each(required_tokens, fn token ->
      assert String.contains?(readme, token),
             "README contract drift: expected required token #{inspect(token)}"
    end)

    Enum.each(forbidden_tokens, fn token ->
      refute String.contains?(readme, token),
             "README contract drift: found forbidden token #{inspect(token)}"
    end)
  end
end
