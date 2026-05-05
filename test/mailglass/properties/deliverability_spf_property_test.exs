defmodule Mailglass.Properties.DeliverabilitySPFPropertyTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Mailglass.Deliverability
  alias Mailglass.Deliverability.SPF
  alias Mailglass.TestSupport.DeliverabilityResolverStub

  @moduletag :property

  setup do
    DeliverabilityResolverStub.reset()
    :ok
  end

  property "recursive SPF lookup trees never report pass once lookup pressure reaches ten" do
    check all(
            lookup_count <- integer(10..14),
            terminal_redirect? <- boolean(),
            max_runs: 30
          ) do
      domain = "example.com"
      fixtures = spf_tree_fixtures(domain, lookup_count, terminal_redirect?)

      DeliverabilityResolverStub.put_fixtures(%{txt: fixtures})

      assert {:ok, runtime_result} =
               Deliverability.run(
                 domain: domain,
                 resolver: DeliverabilityResolverStub
               )

      analysis = SPF.analyze(runtime_result.facts.spf, resolver: DeliverabilityResolverStub)

      assert analysis.facts.lookup_count >= 10
      refute Enum.any?(analysis.findings, &(&1.status == :pass))

      assert Enum.any?(
               analysis.findings,
               &(&1.status == :fail and &1.check == :lookup_limit_exceeded)
             )
    end
  end

  defp spf_tree_fixtures(domain, lookup_count, terminal_redirect?) do
    included =
      for index <- 1..lookup_count, into: %{} do
        current = "hop#{index}.example.test"

        record =
          cond do
            index == lookup_count ->
              "v=spf1 -all"

            terminal_redirect? and index == lookup_count - 1 ->
              "v=spf1 redirect=hop#{index + 1}.example.test"

            true ->
              "v=spf1 include:hop#{index + 1}.example.test -all"
          end

        {current, {:ok, [record]}}
      end

    Map.put(
      included,
      domain,
      {:ok, ["v=spf1 include:hop1.example.test -all"]}
    )
  end
end
