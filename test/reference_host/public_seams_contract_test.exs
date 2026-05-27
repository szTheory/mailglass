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

  defp token_present?(files_with_content, token) do
    Enum.any?(files_with_content, fn {_path, content} -> String.contains?(content, token) end)
  end
end
