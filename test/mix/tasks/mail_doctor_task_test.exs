defmodule Mix.Tasks.Mail.DoctorTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mailglass.TestSupport.DeliverabilityResolverStub

  setup do
    prior_resolver = Application.get_env(:mailglass, :deliverability_resolver)

    Application.put_env(:mailglass, :deliverability_resolver, DeliverabilityResolverStub)
    DeliverabilityResolverStub.reset()

    on_exit(fn ->
      DeliverabilityResolverStub.reset()

      if is_nil(prior_resolver) do
        Application.delete_env(:mailglass, :deliverability_resolver)
      else
        Application.put_env(:mailglass, :deliverability_resolver, prior_resolver)
      end
    end)

    :ok
  end

  describe "mix mail.doctor" do
    test "prints grouped human output for all protocol areas" do
      put_success_fixtures()

      output = run_task!(["--domain", "example.com", "--dkim-selector", "selector1"])

      assert output =~ "example.com:"
      assert output =~ "\n\nSPF\n"
      assert output =~ "\n\nDKIM\n"
      assert output =~ "\n\nDMARC\n"
      assert output =~ "\n\nMX\n"
      assert output =~ "\n\nBIMI\n"
      assert output =~ "[pass] SPF record structure looks healthy"
      assert output =~ "[pass] Selector selector1 published DKIM material"
      assert output =~ "[warn] DMARC policy is monitoring-only"
      assert output =~ "[pass] Null MX marks the domain as send-only"
      assert output =~ "[warn] BIMI needs DMARC enforcement first"
    end

    test "prints json output with the stable schema version" do
      put_success_fixtures()

      output =
        run_task!([
          "--domain",
          "example.com",
          "--dkim-selector",
          "selector1",
          "--format",
          "json"
        ])

      assert output =~ "\"schema_version\":1"
      assert output =~ "\"findings\""
      assert output =~ "\"summary\""
    end

    test "prints evidence only in verbose mode" do
      put_success_fixtures()

      default_output = run_task!(["--domain", "example.com", "--dkim-selector", "selector1"])
      verbose_output = run_task!(["--domain", "example.com", "--dkim-selector", "selector1", "--verbose"])

      refute default_output =~ "Evidence:"
      assert verbose_output =~ "Evidence:"
    end

    test "reports cannot_verify when dkim selectors are omitted" do
      put_success_fixtures()

      output = run_task!(["--domain", "example.com"])

      assert output =~ "cannot_verify"
      assert output =~ "DKIM selectors were not provided"
      assert output =~ "Re-run the doctor with one or more explicit DKIM selectors"
    end

    test "rejects missing and blank domains loudly" do
      assert_raise Mix.Error, ~r/--domain is required/, fn ->
        run_task!([])
      end

      assert_raise Mix.Error, ~r/--domain is required/, fn ->
        run_task!(["--domain", "   "])
      end
    end

    test "rejects unknown flags loudly" do
      assert_raise Mix.Error, ~r/unknown option/, fn ->
        run_task!(["--domain", "example.com", "--wat"])
      end
    end

    test "rejects positional arguments loudly" do
      assert_raise Mix.Error, ~r/positional arguments/, fn ->
        run_task!(["--domain", "example.com", "extra"])
      end
    end

    test "rejects invalid format values loudly" do
      assert_raise Mix.Error, ~r/invalid format/, fn ->
        run_task!(["--domain", "example.com", "--format", "yaml"])
      end
    end
  end

  defp run_task!(argv) do
    Mix.Task.reenable("mail.doctor")
    Mix.Task.reenable("app.start")

    capture_io(fn ->
      Mix.Tasks.Mail.Doctor.run(argv)
    end)
  end

  defp put_success_fixtures do
    DeliverabilityResolverStub.put_fixtures(%{
      txt: %{
        "example.com" => {:ok, ["v=spf1 -all"]},
        "_dmarc.example.com" => {:ok, ["v=DMARC1; p=none"]},
        "selector1._domainkey.example.com" => {:ok, ["v=DKIM1; k=rsa; p=YWJj"]},
        "default._bimi.example.com" => {:ok, ["v=BIMI1; l=https://cdn.example.com/logo.svg"]}
      },
      mx: %{"example.com" => {:ok, [%{exchange: ".", preference: 0}]}},
      cname: %{"selector1._domainkey.example.com" => {:ok, "selector1.provider.example"}}
    })
  end
end
