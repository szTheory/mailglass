defmodule MailglassInbound.ConfigTest do
  # async: false — these tests mutate the :mailglass_inbound application env
  # (retention / rate_limit) which is process-global. Snapshot + restore around
  # each test so the suite stays deterministic and order-independent.
  use ExUnit.Case, async: false

  alias MailglassInbound.Config

  setup do
    prior_retention = Application.get_env(:mailglass_inbound, :retention)
    prior_rate_limit = Application.get_env(:mailglass_inbound, :rate_limit)

    on_exit(fn ->
      restore(:retention, prior_retention)
      restore(:rate_limit, prior_rate_limit)
    end)

    :ok
  end

  defp restore(key, nil), do: Application.delete_env(:mailglass_inbound, key)
  defp restore(key, value), do: Application.put_env(:mailglass_inbound, key, value)

  describe "validate_at_boot!/0" do
    test "returns :ok with the locked default shape (no app env set)" do
      Application.delete_env(:mailglass_inbound, :retention)
      Application.delete_env(:mailglass_inbound, :rate_limit)

      assert :ok = Config.validate_at_boot!()
    end

    test "returns :ok when a valid retention + rate_limit override is configured" do
      Application.put_env(:mailglass_inbound, :retention,
        records_days: 30,
        evidence_days: 7,
        execution_runs_days: 30,
        replay_runs_days: 7
      )

      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 100, per_minute: 60],
        sender_domain: [capacity: 20, per_minute: 60],
        recipient: [capacity: 50, per_minute: 60]
      )

      assert :ok = Config.validate_at_boot!()
    end

    test "accepts :infinity on a retention class (disables that window)" do
      Application.put_env(:mailglass_inbound, :retention,
        records_days: :infinity,
        evidence_days: 30
      )

      assert :ok = Config.validate_at_boot!()
    end

    test "raises on a negative retention value" do
      Application.put_env(:mailglass_inbound, :retention, records_days: -1)

      assert_raise NimbleOptions.ValidationError, fn -> Config.validate_at_boot!() end
    end

    test "raises on a non-integer, non-:infinity retention value" do
      Application.put_env(:mailglass_inbound, :retention, evidence_days: :forever)

      assert_raise NimbleOptions.ValidationError, fn -> Config.validate_at_boot!() end
    end

    test "raises on a negative rate_limit capacity" do
      Application.put_env(:mailglass_inbound, :rate_limit, tenant: [capacity: -5, per_minute: 60])

      assert_raise NimbleOptions.ValidationError, fn -> Config.validate_at_boot!() end
    end
  end

  describe "retention/0" do
    test "returns the locked default windows when unset" do
      Application.delete_env(:mailglass_inbound, :retention)

      retention = Config.retention()

      # CR-02: evidence default is 90 (>= the 90d execution_runs window it is
      # referenced by), not the former 30, so the child-first prune never trips an
      # on_delete: :nothing FK on a fresh run aged 30-90 days.
      assert retention[:records_days] == 90
      assert retention[:evidence_days] == 90
      assert retention[:execution_runs_days] == 90
      assert retention[:replay_runs_days] == 30
    end

    test "merges configured overrides over the defaults" do
      Application.put_env(:mailglass_inbound, :retention, replay_runs_days: 7)

      retention = Config.retention()

      assert retention[:replay_runs_days] == 7
      # Unset classes still carry their defaults.
      assert retention[:records_days] == 90
      assert retention[:evidence_days] == 90
    end

    test "CR-02: clamps evidence_days up to the longest referencing run window" do
      # An operator who sets evidence shorter than a run window that references it
      # would otherwise crash prune on an FK violation. Config clamps it up.
      Application.put_env(:mailglass_inbound, :retention,
        evidence_days: 10,
        execution_runs_days: 90,
        replay_runs_days: 30
      )

      retention = Config.retention()

      assert retention[:evidence_days] == 90, "evidence clamped to max(execution_runs, replay_runs)"
      assert retention[:records_days] >= retention[:evidence_days], "records clamped >= evidence"
    end

    test "CR-02: clamps records_days up to evidence_days" do
      Application.put_env(:mailglass_inbound, :retention,
        records_days: 30,
        evidence_days: 120
      )

      retention = Config.retention()

      assert retention[:records_days] == 120, "records clamped up to evidence_days"
      assert retention[:evidence_days] == 120
    end

    test "CR-02: :infinity on a child forces its parents to :infinity" do
      Application.put_env(:mailglass_inbound, :retention, execution_runs_days: :infinity)

      retention = Config.retention()

      # :infinity execution_runs means evidence (and records) must never be pruned
      # while a run that references them could survive.
      assert retention[:evidence_days] == :infinity
      assert retention[:records_days] == :infinity
    end
  end

  describe "rate_limit/0" do
    test "returns the locked default buckets when unset" do
      Application.delete_env(:mailglass_inbound, :rate_limit)

      rate_limit = Config.rate_limit()

      # WR-01: per_minute == capacity so the advertised "N/min" is the sustained
      # refill rate, matching the core Mailglass.RateLimiter convention.
      assert rate_limit[:tenant][:capacity] == 1000
      assert rate_limit[:tenant][:per_minute] == 1000
      assert rate_limit[:recipient][:capacity] == 500
      assert rate_limit[:recipient][:per_minute] == 500
      assert rate_limit[:sender_domain][:capacity] == 200
      assert rate_limit[:sender_domain][:per_minute] == 200
    end

    test "merges configured bucket overrides over the defaults" do
      Application.put_env(:mailglass_inbound, :rate_limit, tenant: [capacity: 5, per_minute: 60])

      rate_limit = Config.rate_limit()

      assert rate_limit[:tenant][:capacity] == 5
      # Unset buckets still carry their defaults.
      assert rate_limit[:recipient][:capacity] == 500
      assert rate_limit[:sender_domain][:capacity] == 200
    end
  end
end
