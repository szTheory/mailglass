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
  # vocabulary/0 and class_labels/0 record words that are agreed. An entry carries
  # wired: true once a screen shows it, and a contract test binds each wired entry.
  # The five class labels are wired: the row-level class badge and the verdict read
  # them through delivery_class_word/1 and delivery_verdict/2.
  #
  # delivery_verdict/2 is the one place a delivery verdict is computed. The list row
  # badge, the Quick view line and the Full detail verdict all read it, so the three
  # cannot disagree for the same row. It is pure: no process state, no clock, no I/O.

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

  # Words the screens move to. A wired: false entry is not bound by any screen test.
  @vocabulary [
    %{
      key: :admin,
      public_name: "Operator",
      on_screen: "Admin",
      gloss: "screen text and docs prose only; the public name stays",
      wired: true
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
      wired: true
    },
    %{
      key: :unmatched_reports,
      public_name: "orphan / unmatched",
      on_screen: "provider reports match no email",
      gloss: "screen text and docs prose only; the public name stays",
      wired: true
    }
  ]

  # The five plain status words, one per delivery class that has a word.
  @class_labels [
    %{class: :sent, label: "Sent", wired: true},
    %{class: :delivered, label: "Delivered", wired: true},
    %{class: :delayed, label: "Delayed", wired: true},
    %{class: :failed, label: "Failed", wired: true},
    %{class: :not_sent, label: "Not sent", wired: true}
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

  # -- delivery verdict ----------------------------------------------------------

  @undetermined_sentence "Status cannot be fully determined with this mailglass version."
  @fallback_reason "No reason was recorded for this email."

  @providers %{
    "postmark" => "Postmark",
    "sendgrid" => "SendGrid",
    "mailgun" => "Mailgun",
    "resend" => "Resend",
    "ses" => "Amazon SES"
  }

  @type verdict :: %{
          class: :sent | :delivered | :delayed | :failed | :not_sent | :undetermined,
          word: String.t() | nil,
          sentence: [String.t() | {:time, DateTime.t()}],
          rule: String.t() | nil,
          next_step: String.t() | nil,
          next_link: %{label: String.t(), href: String.t()} | nil,
          cause: String.t() | nil,
          notes: [String.t()]
        }

  # Evidence the verdict may read beyond the list row. :not_loaded means the caller
  # has no events or suppression state (the Quick view), :read_failed means the read
  # failed. Neither may produce a cause or the no-reason fallback. For suppression,
  # :no_entry means the read succeeded and no entry matches now (it expired or was
  # removed): that is the absence of an entry, not an entry that recorded no reason, so
  # it gets its own note and never the no-reason fallback.
  @default_evidence %{events: :not_loaded, suppression: :not_loaded}

  @doc """
  The sentence a screen shows when the row cannot be classified, for an operator row
  from a core that predates the lifecycle fields.
  """
  @spec undetermined_sentence() :: String.t()
  def undetermined_sentence, do: @undetermined_sentence

  @doc "The fixed sentence for a failure or suppression that recorded no reason."
  @spec fallback_reason() :: String.t()
  def fallback_reason, do: @fallback_reason

  @doc """
  The display name of a provider recorded on a delivery. Known adapters get their
  proper name, anything else is shown as recorded, and a missing provider is nil.
  """
  @spec provider_name(String.t() | nil) :: String.t() | nil
  def provider_name(nil), do: nil

  def provider_name(provider) when is_binary(provider) do
    case String.trim(provider) do
      "" -> nil
      trimmed -> Map.get(@providers, String.downcase(trimmed), trimmed)
    end
  end

  # Cause text is structural: one sentence per recorded reason, generated from the core
  # enums, and no clause for nil. Rendering a cause for a missing reason raises, so a
  # screen cannot invent one; a caller that may have no reason asks cause_or_fallback/1.
  # A sentence names what the provider or the suppression list recorded, never when or
  # whether a send is tried again: the product does not know retry timing.
  @reject_reason_sentences %{
    invalid: "The provider reported: invalid address.",
    bounced: "The provider reported: bounced.",
    timed_out: "The provider reported: timed out.",
    blocked: "The provider reported: blocked by the receiving server.",
    spam: "The provider reported: marked as spam.",
    unsubscribed: "The provider reported: the recipient unsubscribed.",
    other: "The provider reported a reason outside the standard categories."
  }

  @suppression_reason_sentences %{
    hard_bounce: "Reason: hard bounce.",
    complaint: "Reason: spam complaint.",
    unsubscribe: "Reason: unsubscribed.",
    manual: "Reason: added by hand.",
    policy: "Reason: policy.",
    invalid_recipient: "Reason: invalid recipient."
  }

  # A reject reason added to the core enum breaks the build here, not a screen. The
  # suppression reasons live in Mailglass.Suppression.Entry, which the core boundary does
  # not export to this package, so their parity with the core enum is held by
  # phase182_cause_contract_test in the required admin lane instead.
  reject_reasons = Mailglass.Events.Event.__reject_reasons__()

  if Enum.sort(Map.keys(@reject_reason_sentences)) != Enum.sort(reject_reasons) do
    raise ArgumentError,
          "MailglassAdmin.Copy reject reason sentences must cover exactly the core enum " <>
            "#{inspect(Enum.sort(reject_reasons))}, got " <>
            "#{inspect(Enum.sort(Map.keys(@reject_reason_sentences)))}. " <>
            "A new reason needs its own sentence before the screens can show it."
  end

  @send_failure_cause "Sending failed before a successful handoff to the provider."
  @unrecognized_reason "The recorded reason is not one this version recognises."
  @events_unreadable "The event history could not be read, so no reason is shown."
  @suppression_unreadable "The suppression record could not be read, so no reason is shown."
  @no_suppression_entry "No current suppression entry matches this address."

  @doc """
  The sentence for one recorded reason: `{:reject_reason, r}` for a provider reason or
  `{:suppression_reason, r}` for a suppression reason. There is no clause for nil or an
  unlisted value, so asking for a cause that was not recorded raises FunctionClauseError.
  """
  @spec cause_sentence({:reject_reason, atom()} | {:suppression_reason, atom()}) :: String.t()
  for {reason, sentence} <- @reject_reason_sentences do
    def cause_sentence({:reject_reason, unquote(reason)}), do: unquote(sentence)
  end

  for {reason, sentence} <- @suppression_reason_sentences do
    def cause_sentence({:suppression_reason, unquote(reason)}), do: unquote(sentence)
  end

  @doc """
  The cause for a reason that may be missing: the reason's own sentence when there is
  one, and the fixed no-reason sentence when the reason is nil.
  """
  @spec cause_or_fallback(nil | {atom(), atom() | nil}) :: String.t()
  def cause_or_fallback(nil), do: @fallback_reason
  def cause_or_fallback({_kind, nil}), do: @fallback_reason
  def cause_or_fallback({kind, reason}), do: cause_sentence({kind, reason})

  for %{class: class, label: label} <- @class_labels do
    defp class_label(unquote(class)), do: unquote(label)
  end

  @doc """
  The class word for one operator delivery row: Sent, Delivered, Delayed, Failed or
  Not sent. A row that was accepted into the pipeline and not handed to the provider
  yet reads Queued, so the word never implies a handoff that did not happen.
  """
  @spec delivery_class_word(map()) :: String.t()
  def delivery_class_word(row) when is_map(row) do
    class = StatusMap.delivery_class(row)

    if class == :sent and queued?(row),
      do: status_label(:queued),
      else: class_label(class)
  end

  @doc """
  The verdict for one operator delivery row, as data. Pure: equal input gives an equal
  map. A row without the `:bounced_at` key comes from a core that predates the
  lifecycle fields, so it gets no verdict and the sentence says why.
  """
  @spec delivery_verdict(map(), map()) :: verdict()
  def delivery_verdict(row, evidence \\ %{}) when is_map(row) and is_map(evidence) do
    if Map.has_key?(row, :bounced_at) do
      evidence = Map.merge(@default_evidence, evidence)
      verdict(StatusMap.delivery_class(row), row, evidence)
    else
      %{
        class: :undetermined,
        word: nil,
        sentence: [@undetermined_sentence],
        rule: nil,
        next_step: nil,
        next_link: nil,
        cause: nil,
        notes: []
      }
    end
  end

  defp verdict(:sent, row, evidence) do
    provider = provider_name(Map.get(row, :provider))
    complained? = present?(row, :complained_at)

    base(:sent, row, evidence, %{
      sentence: sent_sentence(row, provider),
      rule: sent_rule(row, complained?),
      next_step: sent_next_step(row, provider)
    })
    |> add_note(complained?, "A complaint was recorded for this email.")
    |> engagement_note(row, evidence)
  end

  defp verdict(:delivered, row, evidence) do
    sentence =
      case Map.get(row, :delivered_at) do
        %DateTime{} = at ->
          ["Delivered at ", {:time, at}, ": the receiving server accepted this email."]

        _ ->
          ["Delivered: the receiving server accepted this email."]
      end

    base(:delivered, row, evidence, %{
      sentence: sentence,
      rule: "Delivered is not the same as read. It may not be in the inbox.",
      next_step:
        "Ask the customer to check spam and promotions, and to search for the sender address."
    })
    |> engagement_note(row, evidence)
  end

  defp verdict(:delayed, row, evidence) do
    provider = provider_name(Map.get(row, :provider))

    base(:delayed, row, evidence, %{
      sentence: [
        "Delayed: the receiving server asked to try again later. No final result is recorded yet."
      ],
      rule: nil,
      next_step:
        "Nothing to do yet. Check this page again later, or see the retry schedule in " <>
          provider_logs(provider) <> "."
    })
    |> engagement_note(row, evidence)
  end

  defp verdict(:failed, row, evidence) do
    {cause, notes} = failure_cause(row, evidence.events)

    base(:failed, row, evidence, %{
      sentence: ["Failed: the email did not get through."],
      rule: nil,
      next_step:
        "Check the address for a typo. See whether it is on the suppression list. " <>
          "Correct it in your app, then trigger the email again.",
      cause: cause,
      notes: notes
    })
    |> engagement_note(row, evidence)
  end

  # The read succeeded and no entry matches now, so the address is not on the list at
  # this moment. The recorded suppression is still the fact; saying the address "is on"
  # the list, or telling the reader to remove it, would contradict the suppression card.
  defp verdict(:not_sent, row, %{suppression: :no_entry} = evidence) do
    base(:not_sent, row, evidence, %{
      sentence: [
        "Not sent: nothing was sent. This address was on your suppression list when this was recorded."
      ],
      rule: nil,
      next_step: "Trigger the email from your app again if it should be sent.",
      notes: [@no_suppression_entry]
    })
    |> engagement_note(row, evidence)
  end

  defp verdict(:not_sent, row, evidence) do
    {cause, notes} = suppression_cause(evidence.suppression)

    base(:not_sent, row, evidence, %{
      sentence: ["Not sent: nothing was sent. This address is on your suppression list."],
      rule: nil,
      next_step:
        "Remove this address from the suppression list if it should receive email, " <>
          "then trigger the email from your app again.",
      next_link: %{label: "Go to the suppression card", href: "#delivery-suppression"},
      cause: cause,
      notes: notes
    })
    |> engagement_note(row, evidence)
  end

  # The cause of a Failed row. Only a loaded timeline can answer: the latest failure
  # event in evidence order carries the provider's reason (or none). No loaded timeline
  # (the Quick view) and an unreadable one both give no cause and no fallback, because
  # "no reason was recorded" would be false when the history was simply not read.
  @failure_event_types [:bounced, :rejected, :failed]

  defp failure_cause(_row, :not_loaded), do: {nil, []}
  defp failure_cause(_row, :read_failed), do: {nil, [@events_unreadable]}

  defp failure_cause(row, events) when is_list(events) do
    case events |> Enum.filter(&(Map.get(&1, :type) in @failure_event_types)) |> List.last() do
      nil -> {send_failure_or_fallback(row), []}
      event -> {event_cause(row, event), []}
    end
  end

  # A :failed event with no reason is a send-time failure only when the row says so.
  # Provider mappers also emit {:failed, nil} for an email the provider accepted and then
  # failed (Mailgun "failed" without a severity, SES "Rendering Failure"); that row is
  # :sent, and claiming the handoff failed would be false.
  defp event_cause(row, event) do
    case {Map.get(event, :type), Map.get(event, :reject_reason)} do
      {:failed, nil} -> send_failure_or_fallback(row)
      {_type, reason} -> reason_cause(:reject_reason, @reject_reason_sentences, reason)
    end
  end

  # A send-time failure (status :failed) never reached the provider, so the handoff
  # sentence is true; any other failure with no event to read has no recorded reason.
  defp send_failure_or_fallback(row) do
    if Map.get(row, :status) == :failed, do: @send_failure_cause, else: @fallback_reason
  end

  defp suppression_cause(:not_loaded), do: {nil, []}
  defp suppression_cause(:read_failed), do: {nil, [@suppression_unreadable]}

  defp suppression_cause(%{} = suppression) do
    {reason_cause(
       :suppression_reason,
       @suppression_reason_sentences,
       Map.get(suppression, :reason)
     ), []}
  end

  # nil is the fixed fallback, a listed reason is its own sentence, and a value this
  # version does not list (a newer core) says so rather than guessing.
  defp reason_cause(_kind, _sentences, nil), do: @fallback_reason

  defp reason_cause(kind, sentences, reason) do
    if Map.has_key?(sentences, reason),
      do: cause_sentence({kind, reason}),
      else: @unrecognized_reason
  end

  defp base(class, row, _evidence, fields) do
    Map.merge(
      %{
        class: class,
        word: delivery_class_word(row),
        sentence: [],
        rule: nil,
        next_step: nil,
        next_link: nil,
        cause: nil,
        notes: []
      },
      fields
    )
  end

  defp sent_sentence(row, provider) do
    if queued?(row) do
      ["Not handed to the provider yet."]
    else
      lead = if provider, do: "Sent with #{provider}.", else: "Sent to the provider."
      [lead <> " mailglass has recorded no delivery report for this email."]
    end
  end

  defp sent_rule(row, complained?) do
    cond do
      queued?(row) -> "Queued is not sent, and sent is not delivered."
      complained? -> "Sent is not delivered: your app handed the email to the provider."
      true -> sent_rule_default()
    end
  end

  defp sent_rule_default do
    "Sent is not delivered: your app handed the email to the provider, " <>
      "and the receiving server has not reported accepting it."
  end

  defp sent_next_step(row, provider) do
    if queued?(row) do
      "Nothing to do yet. Check this page again later."
    else
      "Check this address on the suppression list below. Then look up the email in " <>
        provider_logs(provider) <>
        ", and ask the customer to check spam. " <>
        "Delivery reports reach mailglass only if the provider’s webhook is set up."
    end
  end

  defp provider_logs(nil), do: "the provider’s logs"
  defp provider_logs(provider), do: provider <> "’s logs"

  defp add_note(verdict, true, note), do: %{verdict | notes: verdict.notes ++ [note]}
  defp add_note(verdict, false, _note), do: verdict

  defp engagement_note(verdict, row, evidence) do
    add_note(
      verdict,
      engagement?(row, evidence),
      "Open and click reports are not delivery reports."
    )
  end

  defp engagement?(row, %{events: events}) do
    Map.get(row, :last_event_type) in [:opened, :clicked] or
      (is_list(events) and Enum.any?(events, &(Map.get(&1, :type) in [:opened, :clicked])))
  end

  defp queued?(row) do
    Map.get(row, :status) == :queued and Map.get(row, :last_event_type) in [nil, :queued]
  end

  defp present?(row, key), do: Map.get(row, key) != nil

  defp field_or_unknown(status, field) do
    case Map.fetch(@statuses, status) do
      {:ok, entry} -> Map.fetch!(entry, field)
      :error -> Map.fetch!(@unknown, field)
    end
  end
end
