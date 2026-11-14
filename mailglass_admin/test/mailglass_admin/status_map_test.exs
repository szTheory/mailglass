defmodule MailglassAdmin.StatusMapTest do
  @moduledoc """
  Binds `MailglassAdmin.StatusMap`, the single table from status and event atom to
  delivery class.

  The atom universe is read from source (the Event types, the Delivery status enum,
  the Delivery event types, the `status_badge` attr values and the normalized
  inbound outcomes), never from a hand-copied list, and compared with the table in
  both directions. A new atom anywhere fails here until it is classified; a stale
  table key fails here until it is removed.

  There are 26 atoms: the 25 badge atoms plus `:subscribed`, a real Event type with
  no badge. The count is intentionally 26.

  "Not sent" is a pre-send block only. The core test
  `test/mailglass/outbound/suppressed_not_persisted_test.exs` proves a suppressed
  send persists no Delivery and no Event, and no library code writes
  `Delivery.status :suppressed`. A send-time failure reads Failed.

  The "detectors have teeth" block proves each detector goes red on a known-bad
  input, so a pass is not vacuous.
  """

  use ExUnit.Case, async: true

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.{Components, Copy, StatusMap}
  alias MailglassInbound.InboundRecords.ExecutionRun

  # Hand-written, independent of StatusMap: the expected class of every atom.
  @golden %{
    sent: [:dispatched, :sent, :queued],
    delivered: [:delivered],
    delayed: [:deferred],
    failed: [:failed, :bounced, :rejected],
    not_sent: [:suppressed],
    not_a_delivery_status: [
      :complained,
      :unsubscribed,
      :opened,
      :clicked,
      :autoresponded,
      :unknown,
      :subscribed,
      :accepted,
      :no_match,
      :ignore,
      :no_change,
      :missing_history,
      :failed_ingest,
      :reconciled,
      :webhook_replay_requested,
      :webhook_replay_succeeded,
      :webhook_replay_failed
    ]
  }

  @golden_counts %{
    sent: 3,
    delivered: 1,
    delayed: 1,
    failed: 3,
    not_sent: 1,
    not_a_delivery_status: 17
  }

  # -- universe, from source ----------------------------------------------------

  defp badge_values do
    Components.__components__().status_badge.attrs
    |> Enum.find(&(&1.name == :status))
    |> then(& &1.opts[:values])
  end

  defp inbound_outcomes do
    [nil | ExecutionRun.__outcomes__()]
    |> Enum.map(&Components.normalize_inbound_outcome/1)
  end

  defp universe do
    (Event.__types__() ++
       Ecto.Enum.values(Delivery, :status) ++
       Delivery.__event_types__() ++
       badge_values() ++
       inbound_outcomes())
    |> Enum.uniq()
    |> Enum.sort()
  end

  # `{missing, stale}`: universe atoms with no table key, and table keys that are not
  # in the universe.
  defp universe_diff(universe, keys), do: {universe -- keys, keys -- universe}

  # Calls go through apply/3 so the compiler's type checker does not see a literal
  # that the function has no clause for; the runtime behavior is what is under test.
  defp classify!(value), do: apply(StatusMap, :classify, [value])

  describe "detectors have teeth" do
    test "universe_diff reports an atom that exists in source but is not in the table" do
      assert {[:synthetic_unmapped], []} ==
               universe_diff([:synthetic_unmapped | universe()], StatusMap.atoms())
    end

    test "universe_diff reports a table key that no longer exists in source" do
      assert {[], [:synthetic_stale]} ==
               universe_diff(universe(), [:synthetic_stale | StatusMap.atoms()])
    end

    test "classify/1 raises for an unmapped atom and for nil" do
      assert_raise FunctionClauseError, fn -> classify!(:synthetic_unmapped) end
      assert_raise FunctionClauseError, fn -> classify!(nil) end
    end
  end

  describe "atom universe" do
    test "the table covers exactly the atoms that exist in source" do
      {missing, stale} = universe_diff(universe(), StatusMap.atoms())

      assert {missing, stale} == {[], []},
             "StatusMap does not match the atoms in source. Missing from the table: " <>
               "#{inspect(missing)}. Stale table keys: #{inspect(stale)}. Edit " <>
               "MailglassAdmin.StatusMap and MailglassAdmin.Copy to classify the new atom " <>
               "or remove the stale one."
    end

    test "there are exactly 26 atoms: the 25 badge atoms plus :subscribed" do
      assert length(universe()) == 26
      assert length(StatusMap.atoms()) == 26
      assert universe() -- Enum.sort(badge_values()) == [:subscribed]
      assert Enum.sort(badge_values()) -- universe() == []
    end

    test "Copy covers the 25 badge atoms and not :subscribed" do
      assert Enum.sort(Map.keys(Copy.statuses())) == Enum.sort(badge_values())
      refute Map.has_key?(Copy.statuses(), :subscribed)
    end
  end

  describe "class table" do
    test "every atom maps to the class written in the golden table" do
      for {class, atoms} <- @golden, atom <- atoms do
        assert StatusMap.classify(atom) == class,
               "#{inspect(atom)} must classify as #{inspect(class)}"
      end
    end

    test "the golden table covers every atom exactly once and the counts hold" do
      golden_atoms = @golden |> Map.values() |> List.flatten() |> Enum.sort()

      assert golden_atoms == StatusMap.atoms()
      assert golden_atoms == Enum.uniq(golden_atoms)
      assert Map.new(@golden, fn {class, atoms} -> {class, length(atoms)} end) == @golden_counts

      table_counts =
        StatusMap.table() |> Map.values() |> Enum.frequencies()

      assert table_counts == @golden_counts
    end

    test "classes/0 is the closed set of six" do
      assert StatusMap.classes() ==
               [:sent, :delivered, :delayed, :failed, :not_sent, :not_a_delivery_status]
    end

    test "classify_or_unknown/1 returns the class, or :unclassified for nil and unmapped atoms" do
      assert StatusMap.classify_or_unknown(:delivered) == :delivered
      assert StatusMap.classify_or_unknown(nil) == :unclassified
      assert StatusMap.classify_or_unknown(:synthetic_unmapped) == :unclassified
      refute :unclassified in StatusMap.classes()
    end

    test "a bare send-time :failed status is Failed, never Not sent" do
      assert StatusMap.classify(:failed) == :failed
      refute StatusMap.classify(:failed) == :not_sent
    end
  end

  describe "inbound outcomes share atom names with outbound events" do
    test "every normalized inbound outcome classifies without raising" do
      for outcome <- inbound_outcomes() do
        assert StatusMap.classify(outcome) in StatusMap.classes(),
               "inbound outcome #{inspect(outcome)} has no class"
      end
    end

    test "classify/1 is context-free: :rejected, :bounced and :failed return the outbound class" do
      # Inbound badges must not adopt delivery words even though the class is the same.
      for atom <- [:rejected, :bounced, :failed] do
        assert StatusMap.classify(atom) == :failed
      end
    end
  end
end
