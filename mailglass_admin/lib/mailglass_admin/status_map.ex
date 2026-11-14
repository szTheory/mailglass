defmodule MailglassAdmin.StatusMap do
  @moduledoc false

  # The single table that says what each status or event atom means to an operator.
  # Display words, icons and badge classes live in MailglassAdmin.Copy, which must
  # cover exactly the atoms below (minus :subscribed, see next paragraph).
  #
  # There are 26 atoms: the 25 atoms the status badge accepts, plus :subscribed.
  # :subscribed is a real Event type with no badge, so the count is intentionally
  # 26 and not 25. Do not trim it back to 25.
  #
  # Classes describe outbound delivery meaning:
  #
  #   * :sent                  handed off, or about to be, with no delivery report yet
  #   * :delivered             the receiving server accepted the message
  #   * :delayed               the provider reported a deferral
  #   * :failed                the provider, or the send itself, reported failure
  #   * :not_sent              blocked before any send attempt
  #   * :not_a_delivery_status engagement, mailbox outcomes, replay and ledger markers
  #
  # queued: accepted into the send pipeline, before handoff to the provider.
  # Queued reads Sent only as that pre-handoff state; it never reads Delivered and
  # never implies the handoff succeeded.
  #
  # Inbound outcome atoms :rejected, :bounced and :failed share names with outbound
  # atoms, but they are mailbox outcomes. classify/1 is context-free and returns the
  # outbound class for them, so inbound badges must not adopt delivery words.
  #
  # Not sent is a pre-send block only. Suppression is checked in
  # Mailglass.Outbound.Preflight via Mailglass.Suppression before any insert, so a
  # suppressed send leaves no Delivery row and no Event. deliver_many/2 builds an
  # in-memory :failed Delivery via Mailglass.Outbound.Persistence.build_failed_delivery/2
  # that is never inserted. No library code writes Delivery.status :suppressed, so the
  # :suppressed member is reserved and dormant, and a send-time :failed reads Failed.
  #
  # classify/1 has no catch-all clause on purpose: an atom that is not in the table
  # must raise rather than be quietly labelled. classify_or_unknown/1 is the only
  # function that tolerates an unmapped value, and it exists for UI fallbacks.

  @classes [:sent, :delivered, :delayed, :failed, :not_sent, :not_a_delivery_status]

  @table %{
    # Sent
    dispatched: :sent,
    sent: :sent,
    queued: :sent,
    # Delivered
    delivered: :delivered,
    # Delayed
    deferred: :delayed,
    # Failed
    failed: :failed,
    bounced: :failed,
    rejected: :failed,
    # Not sent
    suppressed: :not_sent,
    # Not a delivery status
    complained: :not_a_delivery_status,
    unsubscribed: :not_a_delivery_status,
    opened: :not_a_delivery_status,
    clicked: :not_a_delivery_status,
    autoresponded: :not_a_delivery_status,
    unknown: :not_a_delivery_status,
    subscribed: :not_a_delivery_status,
    accepted: :not_a_delivery_status,
    no_match: :not_a_delivery_status,
    ignore: :not_a_delivery_status,
    no_change: :not_a_delivery_status,
    missing_history: :not_a_delivery_status,
    failed_ingest: :not_a_delivery_status,
    reconciled: :not_a_delivery_status,
    webhook_replay_requested: :not_a_delivery_status,
    webhook_replay_succeeded: :not_a_delivery_status,
    webhook_replay_failed: :not_a_delivery_status
  }

  Enum.each(@table, fn {atom, class} ->
    if class not in @classes do
      raise ArgumentError,
            "MailglassAdmin.StatusMap maps #{inspect(atom)} to #{inspect(class)}, " <>
              "which is not one of #{inspect(@classes)}"
    end
  end)

  @type class ::
          :sent | :delivered | :delayed | :failed | :not_sent | :not_a_delivery_status

  @spec classes() :: [class()]
  def classes, do: @classes

  @spec atoms() :: [atom()]
  def atoms, do: @table |> Map.keys() |> Enum.sort()

  @spec table() :: %{atom() => class()}
  def table, do: @table

  @spec classify(atom()) :: class()
  for {atom, class} <- @table do
    def classify(unquote(atom)), do: unquote(class)
  end

  @spec classify_or_unknown(term()) :: class() | :unclassified
  def classify_or_unknown(value) do
    case Map.fetch(@table, value) do
      {:ok, class} -> class
      :error -> :unclassified
    end
  end
end
