defmodule MailglassInbound.ArchitecturePortTest do
  use ExUnit.Case, async: true

  @production_glob "lib/mailglass_inbound/**/*.ex"
  @allowed_core_references %{
    "lib/mailglass_inbound/config.ex" => MapSet.new(["Mailglass.Identifier"]),
    "lib/mailglass_inbound/execution.ex" =>
      MapSet.new(["Mailglass.SendError", "Mailglass.Tenancy"]),
    "lib/mailglass_inbound/fixtures.ex" =>
      MapSet.new(["Mailglass.Webhook.Providers.SES.CertCache"]),
    "lib/mailglass_inbound/ingress/persist.ex" => MapSet.new(["Mailglass.Identifier"]),
    "lib/mailglass_inbound/ingress/plug.ex" =>
      MapSet.new(["Mailglass", "Mailglass.RateLimitError"]),
    "lib/mailglass_inbound/ingress/providers/mailgun.ex" =>
      MapSet.new(["Mailglass", "Mailglass.Webhook.Providers.MailgunReplayCache"]),
    "lib/mailglass_inbound/ingress/providers/postmark.ex" => MapSet.new(["Mailglass"]),
    "lib/mailglass_inbound/ingress/providers/sendgrid.ex" => MapSet.new(["Mailglass"]),
    "lib/mailglass_inbound/ingress/providers/ses.ex" =>
      MapSet.new([
        "Mailglass.SignatureError",
        "Mailglass.Webhook.Providers.SES",
        "Mailglass.Webhook.Providers.SES.TrustPolicy"
      ]),
    "lib/mailglass_inbound/internal/operator/detail.ex" => MapSet.new(["Mailglass.Tenancy"]),
    "lib/mailglass_inbound/internal/operator/records.ex" => MapSet.new(["Mailglass.Tenancy"]),
    "lib/mailglass_inbound/internal/operator/summary.ex" => MapSet.new(["Mailglass.Tenancy"]),
    "lib/mailglass_inbound/internal/operator/timeline.ex" => MapSet.new(["Mailglass.Tenancy"]),
    "lib/mailglass_inbound/internal/replay.ex" => MapSet.new(["Mailglass.Tenancy"]),
    "lib/mailglass_inbound/mailbox_case.ex" =>
      MapSet.new([
        "Mailglass.PubSub",
        "Mailglass.Tenancy",
        "Mailglass.Webhook.Providers.SES.CertCache"
      ]),
    "lib/mailglass_inbound/migrations/postgres.ex" =>
      MapSet.new(["Mailglass.Identifier", "Mailglass.MigrationVersionError"]),
    "lib/mailglass_inbound/migrations/postgres/v01.ex" => MapSet.new(["Mailglass.Identifier"]),
    "lib/mailglass_inbound/migrations/postgres/v02.ex" =>
      MapSet.new(["Mailglass.Identifier", "Mailglass.Migrations.Postgres.SessionTimeouts"]),
    "lib/mailglass_inbound/ports/core.ex" =>
      MapSet.new(["Mailglass.Ports.PubSub", "Mailglass.Ports.Suppression", "Mailglass.Tenancy"]),
    "lib/mailglass_inbound/rate_limiter.ex" =>
      MapSet.new(["Mailglass.RateLimitError", "Mailglass.RateLimiter.AtomicBucket"]),
    "lib/mailglass_inbound/rate_limiter/table_owner.ex" =>
      MapSet.new(["Mailglass.RateLimiter.AtomicBucket"])
  }

  test "inbound production Mailglass edges are declared capabilities or pure primitives" do
    sources =
      @production_glob
      |> Path.wildcard()
      |> Enum.map(fn path -> {path, File.read!(path)} end)

    assert remote_reference_violations(sources) == []

    assert remote_reference_violations([
             {"fixture.ex", "defmodule Fixture do\n  Mailglass.Unapproved.Secret.fetch()\nend"}
           ]) == [{"fixture.ex", "Mailglass.Unapproved.Secret"}]

    assert remote_reference_violations([
             {"fixture.ex", "defmodule Fixture do\n  Application.get_env(:mailglass, :repo)\nend"}
           ]) == [{"fixture.ex", "Application.get_env(:mailglass)"}]
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

  defp remote_reference_violations(sources) do
    for {path, source} <- sources,
        reference <- remote_references(source),
        reference not in Map.get(@allowed_core_references, path, MapSet.new()),
        do: {path, reference}
  end

  defp remote_references(source) do
    {:ok, ast} = Code.string_to_quoted(source)

    {_ast, references} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:__aliases__, _, [:Mailglass | rest]} = node, refs ->
          reference = Enum.join(["Mailglass" | Enum.map(rest, &Atom.to_string/1)], ".")
          {node, MapSet.put(refs, reference)}

        {{:., _, [{:__aliases__, _, [:Application]}, function]}, _, [:mailglass | _]} = node, refs
        when function in [:get_env, :fetch_env, :fetch_env!, :get_all_env] ->
          {node, MapSet.put(refs, "Application.#{function}(:mailglass)")}

        node, refs ->
          {node, refs}
      end)

    Enum.sort(references)
  end
end
