defmodule Mailglass.ReferenceHost.PublicSeamsContractTest do
  use ExUnit.Case, async: true

  @host_files [
    Path.expand("../../reference/host_app/lib/mailglass_reference_host_web/router.ex", __DIR__),
    Path.expand("../../reference/host_app/config/runtime.exs", __DIR__),
    Path.expand("../../reference/host_app/README.md", __DIR__)
  ]

  test "reference host wiring stays on stable public seams only (HOST-02)" do
    files_with_content = Enum.map(@host_files, &{&1, File.read!(&1)})

    required_tokens = [
      "Mailglass.deliver/2",
      "Mailglass.deliver!/2",
      "Mailglass.deliver_later/2",
      "mailglass_admin_routes/2",
      "mailglass_operator_routes/2",
      "MailglassInbound.Ingress.Plug",
      "Public seam boundary: this host does not call Mailglass internal modules or provider internals."
    ]

    forbidden_tokens = [
      "Mailglass.Repo",
      "Mailglass.Outbound.Projector",
      "Mailglass.OptionalDeps",
      "MailglassAdmin.Operator.Mount",
      "MailglassInbound.Ingress.Providers",
      "defmodule MailglassInbound.Ingress.Providers",
      "copied provider internals"
    ]

    Enum.each(required_tokens, fn token ->
      assert token_present?(files_with_content, token),
             "HOST-02 contract drift: required public seam token missing: #{inspect(token)}"
    end)

    Enum.each(forbidden_tokens, fn token ->
      refute token_present?(files_with_content, token),
             "HOST-02 contract drift: forbidden internal/provider token present: #{inspect(token)}"
    end)
  end

  test "Config keeps its documented public accessor inventory while Runtime remains internal" do
    assert Code.ensure_loaded?(Mailglass.Config)

    for {name, arity} <- [
          {:new!, 0},
          {:new!, 1},
          {:validate_at_boot!, 0},
          {:get_theme, 0},
          {:schema, 0},
          {:default_adapter, 0},
          {:adapters, 0},
          {:resolve_adapter_ref, 1},
          {:compliance, 0},
          {:compliance_endpoint, 0},
          {:compliance_host, 0},
          {:compliance_scheme, 0},
          {:compliance_mount_path, 0},
          {:compliance_previous_secrets, 0},
          {:compliance_redirect, 0},
          {:compliance_max_age, 0},
          {:compliance_lifecycle, 0},
          {:webhook_ingest_mode, 0}
        ] do
      assert function_exported?(Mailglass.Config, name, arity),
             "stable Config accessor missing: #{name}/#{arity}"
    end

    for internal <- [
          Mailglass.Runtime,
          Mailglass.Runtime.Schema,
          Mailglass.Outbound.Preflight,
          Mailglass.Outbound.Routes,
          Mailglass.Outbound.Persistence,
          Mailglass.Outbound.Dispatch
        ] do
      assert {:docs_v1, _, :elixir, _, :hidden, _, _} = Code.fetch_docs(internal)
    end

    refute function_exported?(Mailglass, :runtime, 0)
    refute function_exported?(Mailglass, :runtime_config, 0)
  end

  defp token_present?(files_with_content, token) do
    Enum.any?(files_with_content, fn {_path, content} -> String.contains?(content, token) end)
  end
end
