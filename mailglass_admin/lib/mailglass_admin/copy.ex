defmodule MailglassAdmin.Copy do
  @moduledoc false

  # The single owner of status words. Every status badge reads its label, icon and
  # badge class from @statuses, so the words an operator sees are changed in one
  # place and nowhere else.
  #
  # @statuses holds the 25 atoms the status badge accepts. The strict functions
  # (status_label/1, status_icon/1, status_class/1) have no fallback clause: nil, an
  # unmapped atom and :subscribed (a real Event type that has no badge) raise
  # FunctionClauseError. The *_or_unknown/1 variants carry the one sanctioned UI
  # fallback, used by the badge component for a missing status.
  #
  # vocabulary/0 and class_labels/0 record words that are agreed but not yet on
  # screen. They carry wired: false until the screens switch over, and a contract
  # test binds each entry once it is marked wired: true.

  alias MailglassAdmin.StatusMap

  @statuses %{
    dispatched: %{label: "Dispatched", icon: "hero-paper-airplane", class: "badge-primary"},
    queued: %{label: "Queued", icon: "hero-arrow-path", class: "badge-primary"},
    sent: %{label: "Sent", icon: "hero-paper-airplane", class: "badge-primary"},
    delivered: %{label: "Delivered", icon: "hero-check-circle", class: "badge-success"},
    deferred: %{label: "Deferred", icon: "hero-exclamation-triangle", class: "badge-warning"},
    bounced: %{label: "Bounced", icon: "hero-x-circle", class: "badge-error"},
    failed: %{label: "Failed", icon: "hero-x-circle", class: "badge-error"},
    rejected: %{label: "Rejected", icon: "hero-x-circle", class: "badge-error"},
    complained: %{label: "Complained", icon: "hero-exclamation-circle", class: "badge-error"},
    unsubscribed: %{label: "Unsubscribed", icon: "hero-bell-slash", class: "badge-warning"},
    opened: %{label: "Opened", icon: "hero-envelope-open", class: "badge-success"},
    clicked: %{label: "Clicked", icon: "hero-hand-thumb-up", class: "badge-success"},
    autoresponded: %{
      label: "Auto-replied",
      icon: "hero-arrow-uturn-left",
      class: "badge-outline"
    },
    unknown: %{label: "Unknown", icon: "hero-question-mark-circle", class: "badge-outline"},
    accepted: %{label: "Accepted", icon: "hero-check-circle", class: "badge-success"},
    no_match: %{label: "Unrouted", icon: "hero-exclamation-triangle", class: "badge-warning"},
    ignore: %{label: "Ignored", icon: "hero-minus-circle", class: "badge-outline"},
    no_change: %{label: "No change", icon: "hero-minus-circle", class: "badge-outline"},
    missing_history: %{
      label: "No history",
      icon: "hero-question-mark-circle",
      class: "badge-outline"
    },
    failed_ingest: %{
      label: "Ingest failed",
      icon: "hero-exclamation-circle",
      class: "badge-error"
    },
    webhook_replay_requested: %{
      label: "Replay requested",
      icon: "hero-arrow-path",
      class: "badge-outline"
    },
    webhook_replay_succeeded: %{
      label: "Replay succeeded",
      icon: "hero-check-circle",
      class: "badge-success"
    },
    webhook_replay_failed: %{
      label: "Replay failed",
      icon: "hero-x-circle",
      class: "badge-error"
    },
    reconciled: %{
      label: "Reconciled",
      icon: "hero-exclamation-triangle",
      class: "badge-warning"
    },
    suppressed: %{label: "Suppressed", icon: "hero-minus-circle", class: "badge-warning"}
  }

  @unknown %{label: "Unknown", icon: "hero-question-mark-circle", class: "badge-outline"}

  # Words the screens will move to. Data only: nothing renders these yet, and a
  # wired: false entry is not bound by any screen test.
  @vocabulary [
    %{
      key: :admin,
      public_name: "Operator",
      on_screen: "Admin",
      gloss: "screen text and docs prose only; the public name stays",
      wired: false
    },
    %{
      key: :account,
      public_name: "Tenant",
      on_screen: "Account",
      gloss: "screen text and docs prose only; the public name stays",
      wired: true
    },
    %{
      key: :activity,
      public_name: "Deliveries",
      on_screen: "Activity",
      gloss: "screen text and docs prose only; the public name stays",
      wired: false
    },
    %{
      key: :unmatched_reports,
      public_name: "orphan / unmatched",
      on_screen: "provider reports match no email",
      gloss: "screen text and docs prose only; the public name stays",
      wired: false
    }
  ]

  # The five plain status words, one per delivery class that has a word.
  @class_labels [
    %{class: :sent, label: "Sent", wired: false},
    %{class: :delivered, label: "Delivered", wired: false},
    %{class: :delayed, label: "Delayed", wired: false},
    %{class: :failed, label: "Failed", wired: false},
    %{class: :not_sent, label: "Not sent", wired: false}
  ]

  expected_keys = StatusMap.atoms() -- [:subscribed]
  actual_keys = Enum.sort(Map.keys(@statuses))

  if actual_keys != expected_keys do
    raise ArgumentError,
          "MailglassAdmin.Copy status keys must equal MailglassAdmin.StatusMap.atoms() " <>
            "minus :subscribed. Missing from Copy: #{inspect(expected_keys -- actual_keys)}. " <>
            "Not in StatusMap: #{inspect(actual_keys -- expected_keys)}."
  end

  expected_classes = StatusMap.classes() -- [:not_a_delivery_status]
  actual_classes = @class_labels |> Enum.map(& &1.class) |> Enum.sort()

  if actual_classes != Enum.sort(expected_classes) do
    raise ArgumentError,
          "MailglassAdmin.Copy class labels must cover exactly #{inspect(expected_classes)}, " <>
            "got #{inspect(actual_classes)}."
  end

  @spec statuses() :: %{atom() => %{label: String.t(), icon: String.t(), class: String.t()}}
  def statuses, do: @statuses

  @spec unknown() :: %{label: String.t(), icon: String.t(), class: String.t()}
  def unknown, do: @unknown

  @spec status_label(atom()) :: String.t()
  @spec status_icon(atom()) :: String.t()
  @spec status_class(atom()) :: String.t()
  for {atom, %{label: label, icon: icon, class: class}} <- @statuses do
    def status_label(unquote(atom)), do: unquote(label)
    def status_icon(unquote(atom)), do: unquote(icon)
    def status_class(unquote(atom)), do: unquote(class)
  end

  @spec status_label_or_unknown(term()) :: String.t()
  def status_label_or_unknown(status), do: field_or_unknown(status, :label)

  @spec status_icon_or_unknown(term()) :: String.t()
  def status_icon_or_unknown(status), do: field_or_unknown(status, :icon)

  @spec status_class_or_unknown(term()) :: String.t()
  def status_class_or_unknown(status), do: field_or_unknown(status, :class)

  @spec vocabulary() :: [map()]
  def vocabulary, do: @vocabulary

  @spec class_labels() :: [map()]
  def class_labels, do: @class_labels

  defp field_or_unknown(status, field) do
    case Map.fetch(@statuses, status) do
      {:ok, entry} -> Map.fetch!(entry, field)
      :error -> Map.fetch!(@unknown, field)
    end
  end
end
