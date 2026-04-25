defmodule Mailglass.TestAssertions do
  @moduledoc """
  Test assertions extending Swoosh.TestAssertions (TEST-01, D-05).

  Lives in `lib/` (not `test/support/`) because it's exported for
  adopter consumption. Adopters `import Mailglass.TestAssertions` in
  their test helpers or use `Mailglass.MailerCase` which imports it.

  ## Matcher styles

      # 1. Presence (bare call)
      assert_mail_sent()

      # 2. Keyword match (Swoosh familiarity)
      assert_mail_sent(subject: "Welcome", to: "user@example.com")

      # 3. Struct pattern (macro — no explicit quoting)
      assert_mail_sent(%{mailable: MyApp.UserMailer})

      # 4. Predicate fn
      assert_mail_sent(fn msg -> msg.stream == :transactional end)

  ## Supported keyword matcher keys

  `:subject`, `:to`, `:mailable`, `:stream`, `:tenant` — extensible in
  future versions. Any other key raises `ExUnit.AssertionError`.

  ## Process-local + PubSub-backed assertions

  - `last_mail/0`, `wait_for_mail/1`, `assert_no_mail_sent/0` — read
    the current process's mailbox (`Mailglass.Adapters.Fake.Storage` sends
    `{:mail, %Message{}}` to the owner via `send/2` on every delivery).
  - `assert_mail_delivered/2`, `assert_mail_bounced/2` — consume
    PubSub broadcasts from
    `Mailglass.Outbound.Projector.broadcast_delivery_updated/3`.
    Use when asserting webhook-received events (Phase 4) or
    Fake-triggered events (`Mailglass.Adapters.Fake.trigger_event/3`).

  ## Async-safe

  Process mailbox + ETS-per-owner (Fake) + PubSub subscription (all
  cleaned up on process exit) means `async: true` tests see only their
  own mail. Use `Mailglass.MailerCase` for the canonical setup.

  ## PII policy (T-3-06-01)

  Failure messages embed caller-supplied values (e.g. `subject` or `to`
  address) because adopter test failures need that context. These values
  appear only in the adopter's own test output — not in telemetry,
  log streams, or cross-tenant surfaces.
  """

  import ExUnit.Assertions

  alias Mailglass.{Adapters, Message, Outbound}

  # ===== assert_mail_sent — 4 matcher styles via macro =====

  @doc """
  Asserts that at least one mail was sent in the current test process.

  Four matcher styles supported; see module doc.

  ## Style 1: presence (bare call)

      assert_mail_sent()

  ## Style 2: keyword list

      assert_mail_sent(subject: "Welcome", to: "user@example.com")
      assert_mail_sent(mailable: MyApp.UserMailer, stream: :transactional)

  Supported keys: `:subject`, `:to`, `:mailable`, `:stream`, `:tenant`

  ## Style 3: struct pattern (no quoting needed)

      assert_mail_sent(%{mailable: MyApp.UserMailer})

  ## Style 4: predicate function

      assert_mail_sent(fn msg -> msg.stream == :transactional end)
  """
  @doc since: "0.1.0"
  defmacro assert_mail_sent do
    quote do
      assert_received {:mail, _msg}
    end
  end

  @doc since: "0.1.0"
  defmacro assert_mail_sent({:%{}, _, _} = pattern) do
    # Style 3: struct pattern — caller passes `%{mailable: X}` without quoting.
    quote do
      assert_received {:mail, unquote(pattern)}
    end
  end

  @doc since: "0.1.0"
  defmacro assert_mail_sent({:fn, _, _} = fun_ast) do
    # Style 4: predicate — `fn msg -> ... end`.
    quote do
      assert_received {:mail, msg}
      fun = unquote(fun_ast)

      assert fun.(msg),
             "assert_mail_sent predicate returned false for message #{inspect(msg)}"
    end
  end

  @doc since: "0.1.0"
  defmacro assert_mail_sent(params) do
    # Style 2: keyword list. Matcher dispatched at runtime by __match_keyword__/2.
    quote do
      assert_received {:mail, msg}
      Mailglass.TestAssertions.__match_keyword__(msg, unquote(params))
    end
  end

  @doc false
  def __match_keyword__(%Message{} = msg, params) when is_list(params) do
    Enum.each(params, fn
      {:subject, v} ->
        assert msg.swoosh_email.subject == v,
               "subject mismatch: expected #{inspect(v)}, got #{inspect(msg.swoosh_email.subject)}"

      {:to, v} when is_binary(v) ->
        assert Enum.any?(msg.swoosh_email.to, fn
                 {_, addr} -> addr == v
                 addr when is_binary(addr) -> addr == v
               end),
               "to mismatch: #{inspect(v)} not in #{inspect(msg.swoosh_email.to)}"

      {:mailable, v} ->
        assert msg.mailable == v,
               "mailable mismatch: expected #{inspect(v)}, got #{inspect(msg.mailable)}"

      {:stream, v} ->
        assert msg.stream == v,
               "stream mismatch: expected #{inspect(v)}, got #{inspect(msg.stream)}"

      {:tenant, v} ->
        assert msg.tenant_id == v,
               "tenant_id mismatch: expected #{inspect(v)}, got #{inspect(msg.tenant_id)}"

      {key, _} ->
        flunk(
          "Unsupported matcher key: #{inspect(key)}. " <>
            "Supported: :subject, :to, :mailable, :stream, :tenant"
        )
    end)
  end

  # ===== last_mail / wait_for_mail / assert_no_mail_sent =====

  @doc """
  Returns the most recent `%Mailglass.Message{}` sent from the current
  owner's Fake ETS bucket; or `nil` if none.

  Reads directly from the Fake ETS table — no process mailbox consumed.
  The returned message is still present in the mailbox for subsequent
  `assert_mail_sent/0,1` calls.
  """
  @doc since: "0.1.0"
  @spec last_mail() :: Message.t() | nil
  def last_mail do
    case Adapters.Fake.last_delivery() do
      nil -> nil
      %{message: %Message{} = msg} -> msg
    end
  end

  @doc """
  Blocks until a mail arrives or `timeout` elapses. Returns the message.
  Flunks on timeout with a descriptive failure message.

  Unlike `assert_mail_sent/0` (which uses `assert_received` and checks
  the mailbox synchronously), `wait_for_mail/1` blocks the test for up
  to `timeout` milliseconds — useful when the delivery may arrive
  slightly after the assertion site.
  """
  @doc since: "0.1.0"
  @spec wait_for_mail(timeout()) :: Message.t()
  def wait_for_mail(timeout \\ 100) do
    receive do
      {:mail, %Message{} = msg} -> msg
    after
      timeout -> flunk("wait_for_mail timed out after #{timeout}ms — no {:mail, _} received")
    end
  end

  @doc """
  Asserts that no mail was sent in the current test process.

  Reads the current process mailbox. Flunks if any `{:mail, _}` message
  is present.
  """
  @doc since: "0.1.0"
  defmacro assert_no_mail_sent do
    quote do
      refute_received {:mail, _}
    end
  end

  # ===== PubSub-backed: assert_mail_delivered / assert_mail_bounced =====

  @doc """
  Blocks until a `{:delivery_updated, _, :delivered, _}` broadcast
  arrives for the given delivery id (or `%Delivery{}`). Flunks on timeout.

  The current test process MUST be subscribed to either
  `Mailglass.PubSub.Topics.events(tenant_id)` or
  `Mailglass.PubSub.Topics.events(tenant_id, delivery_id)` before
  this assertion runs. `Mailglass.MailerCase` handles the tenant-wide
  subscription in setup.

  ## Accepts

  - `delivery_id :: binary()` — the UUID string
  - `delivery :: %Mailglass.Outbound.Delivery{}` — the struct (`.id` extracted)
  """
  @doc since: "0.1.0"
  @spec assert_mail_delivered(Outbound.Delivery.t() | binary(), timeout()) :: :ok
  def assert_mail_delivered(delivery_or_id, timeout \\ 100) do
    delivery_id = to_delivery_id(delivery_or_id)

    assert_receive {:delivery_updated, ^delivery_id, :delivered, _meta},
                   timeout,
                   "assert_mail_delivered timed out for delivery_id=#{delivery_id}"

    :ok
  end

  @doc """
  Blocks until a `{:delivery_updated, _, :bounced, _}` broadcast arrives.
  See `assert_mail_delivered/2` for usage notes.
  """
  @doc since: "0.1.0"
  @spec assert_mail_bounced(Outbound.Delivery.t() | binary(), timeout()) :: :ok
  def assert_mail_bounced(delivery_or_id, timeout \\ 100) do
    delivery_id = to_delivery_id(delivery_or_id)

    assert_receive {:delivery_updated, ^delivery_id, :bounced, _meta},
                   timeout,
                   "assert_mail_bounced timed out for delivery_id=#{delivery_id}"

    :ok
  end

  defp to_delivery_id(%Outbound.Delivery{id: id}), do: id
  defp to_delivery_id(id) when is_binary(id), do: id
end
