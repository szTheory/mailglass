defmodule MailglassInbound.ArchitecturePortTest do
  use ExUnit.Case, async: true

  @production_glob "lib/mailglass_inbound/**/*.ex"

  test "inbound production Mailglass edges are declared capabilities or pure primitives" do
    sources =
      @production_glob
      |> Path.wildcard()
      |> Enum.map(fn path -> {path, File.read!(path)} end)

    assert prohibited_edges(sources) == []

    assert prohibited_edges([
             {"fixture.ex", "defmodule Fixture do\n  Mailglass.Config.schema()\nend"}
           ]) == ["fixture.ex"]
  end

  test "the declared Core port owns every runtime sibling capability" do
    core_port = File.read!("lib/mailglass_inbound/ports/core.ex")
    plug = File.read!("lib/mailglass_inbound/ingress/plug.ex")

    assert core_port =~ "to: Mailglass.Ports.PubSub"
    assert plug =~ "Ports.Core.safe_broadcast"
    refute plug =~ "Outbound.Projector.safe_broadcast"
    refute plug =~ "defp safe_broadcast"
  end

  test "optional integrations and job tenancy stay behind inbound-owned seams" do
    worker = File.read!("lib/mailglass_inbound/execution/worker.ex")
    mime = File.read!("lib/mailglass_inbound/mime.ex")
    doctor = File.read!("lib/mailglass_inbound/internal/doctor.ex")
    persist = File.read!("lib/mailglass_inbound/ingress/persist.ex")
    mixfile = File.read!("mix.exs")

    assert worker =~ "Ports.Core.with_job_tenant"
    assert mime =~ "MailglassInbound.OptionalDeps.GenSmtp"
    assert doctor =~ "MailglassInbound.OptionalDeps.GenSmtp"
    assert persist =~ "Ports.Core.suppressed_sender?"
    refute worker =~ "Mailglass.Oban.TenancyMiddleware"
    refute mime =~ "alias Mailglass.OptionalDeps.GenSmtp"
    refute doctor =~ "Mailglass.OptionalDeps.GenSmtp.available?()"
    refute persist =~ "Application.get_env(:mailglass, :suppression_store"
    refute mixfile =~ "Mailglass.Oban.TenancyMiddleware"
  end

  defp prohibited_edges(sources) do
    for {path, source} <- sources,
        source = code_only(source),
        source =~
          ~r/\bMailglass\.(?:Config|Repo|Outbound|OptionalDeps|SuppressionStore|Oban\.TenancyMiddleware)\s*\./ or
          source =~ "Application.get_env(:mailglass,",
        do: path
  end

  defp code_only(source) do
    source
    |> String.replace(~r/""".*?"""/s, "")
    |> String.split("\n")
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end
end
