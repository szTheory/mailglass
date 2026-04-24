defmodule Mailglass.BoundaryTest do
  use ExUnit.Case, async: true

  @moduledoc false

  test "renderer boundary remains root-only (no outbound/repo dependency edge)" do
    assert boundary_deps(Mailglass.Renderer) == [Mailglass]
  end

  test "outbound boundary remains root-only" do
    assert boundary_deps(Mailglass.Outbound) == [Mailglass]
  end

  test "events boundary has no outbound dependency edge" do
    assert boundary_deps(Mailglass.Events) == [Mailglass]
  end

  test "webhook depends on events but not outbound boundary" do
    deps = boundary_deps(Mailglass.Webhook)

    assert Mailglass.Events in deps
    refute Mailglass.Outbound in deps
  end

  test "root exports include the sub-boundary entrypoints" do
    exports = boundary_exports(Mailglass)

    assert Outbound in exports
    assert Events in exports
    assert Webhook in exports
  end

  test "non-fake adapters stay leaf modules for outbound calls" do
    adapters_dir = Path.expand("../../lib/mailglass/adapters", __DIR__)

    adapters_dir
    |> Path.join("*.ex")
    |> Path.wildcard()
    |> Enum.reject(&String.ends_with?(&1, "fake.ex"))
    |> Enum.each(fn path ->
      contents = File.read!(path)
      refute contents =~ "Mailglass.Outbound", "unexpected outbound reference in #{path}"
    end)
  end

  defp boundary_deps(module) do
    module
    |> boundary_opts()
    |> Keyword.get(:deps, [])
  end

  defp boundary_exports(module) do
    module
    |> boundary_opts()
    |> Keyword.get(:exports, [])
  end

  defp boundary_opts(module) do
    attrs = module.__info__(:attributes)
    [{Boundary, [meta]}] = Keyword.take(attrs, [Boundary])
    Keyword.new(meta.opts)
  end
end
