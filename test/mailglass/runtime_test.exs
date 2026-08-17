defmodule Mailglass.RuntimeTest do
  use ExUnit.Case, async: false

  alias Mailglass.ConfigError
  alias Mailglass.Runtime

  setup do
    prior = Application.get_all_env(:mailglass)

    on_exit(fn ->
      Runtime.reset_for_test!()

      Application.get_all_env(:mailglass)
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(:mailglass, &1))

      Enum.each(prior, fn {key, value} -> Application.put_env(:mailglass, key, value) end)
    end)

    :ok
  end

  test "bootstraps the default schema into an opaque runtime value" do
    Application.delete_env(:mailglass, :schema)
    Runtime.reset_for_test!()

    assert %Runtime{} = Runtime.current()
    assert Runtime.schema() == "mailglass"
    assert :persistent_term.get({Mailglass.Config, :schema}) == "mailglass"
  end

  test "reloads an explicit schema override after an explicit reset" do
    Application.put_env(:mailglass, :schema, "analytics")
    Runtime.reset_for_test!()

    assert Runtime.schema() == "analytics"
    assert Mailglass.Config.schema() == "analytics"
  end

  test "rejects an invalid schema instead of serving a stale runtime value" do
    Application.put_env(:mailglass, :schema, "has-dash")
    Runtime.reset_for_test!()

    assert_raise ConfigError, fn ->
      Runtime.current()
    end
  end

  test "validates and caches the complete normalized configuration once" do
    Application.put_env(:mailglass, :adapter, Mailglass.Adapters.Fake)
    Application.put_env(:mailglass, :tracking, host: "track.example.test", salts: ["salt"])
    Application.put_env(:mailglass, :compliance, scheme: "http")
    Runtime.reset_for_test!()

    runtime = Runtime.bootstrap!()

    assert Runtime.fetch!(runtime, :adapter) == {Mailglass.Adapters.Fake, []}
    assert Runtime.fetch!(:tracking)[:host] == "track.example.test"
    assert Runtime.fetch!(:compliance)[:scheme] == "http"

    refute Map.has_key?(runtime, :source)
    refute inspect(runtime) =~ "track.example.test"

    Application.put_env(:mailglass, :tracking, host: "changed.example.test")
    assert Runtime.fetch!(:tracking)[:host] == "track.example.test"

    Runtime.reset_for_test!()
    assert Runtime.fetch!(:tracking)[:host] == "changed.example.test"
  end

  test "Config accessors refresh a changed test environment without exposing the raw source" do
    Application.put_env(:mailglass, :tracking, host: "first-secret.example.test")
    Runtime.reset_for_test!()

    assert Mailglass.Config.tracking()[:host] == "first-secret.example.test"
    assert inspect(Runtime.current()) =~ "source_fingerprint"
    refute inspect(Runtime.current()) =~ "first-secret.example.test"

    Application.put_env(:mailglass, :tracking, host: "second-secret.example.test")

    assert Mailglass.Config.tracking()[:host] == "second-secret.example.test"
  end

  test "invalid full configuration never replaces the last valid runtime or legacy caches" do
    Application.put_env(:mailglass, :schema, "stable")
    Runtime.reset_for_test!()
    assert Runtime.schema() == "stable"

    Application.put_env(:mailglass, :schema, "invalid-schema")

    assert_raise ConfigError, fn -> Runtime.bootstrap!() end
    assert Runtime.schema() == "stable"
    assert :persistent_term.get({Mailglass.Config, :schema}) == "stable"
  end

  test "Config validation and runtime validation preserve the public normalized shape" do
    opts = [adapter: Mailglass.Adapters.Fake, adapters: [primary: Mailglass.Adapters.Fake]]

    assert Mailglass.Config.new!(opts) == Runtime.validate!(opts)

    assert Keyword.fetch!(Runtime.validate!(opts), :adapters) == [
             primary: {Mailglass.Adapters.Fake, []}
           ]
  end

  test "Config accessors delegate every validated slice to the cached runtime" do
    Application.put_env(:mailglass, :tenancy, Mailglass.Tenancy.SingleTenant)

    Application.put_env(:mailglass, :rate_limit,
      tenant_recipient: [default: [capacity: 7, per_minute: 3]]
    )

    Application.put_env(:mailglass, :webhook_retention, succeeded_days: 5)
    Runtime.reset_for_test!()

    assert Mailglass.Config.tenancy() == Mailglass.Tenancy.SingleTenant
    assert Mailglass.Config.rate_limit()[:tenant_recipient][:default][:capacity] == 7
    assert Mailglass.Config.webhook_retention()[:succeeded_days] == 5
    assert Mailglass.Config.async_adapter() in [:oban, :task_supervisor]
  end
end
