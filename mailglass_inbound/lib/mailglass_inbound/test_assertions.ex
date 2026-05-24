defmodule MailglassInbound.TestAssertions do
  @moduledoc """
  Inbound test assertions (ITEST-01..04) — the inbound mirror of
  `Mailglass.TestAssertions`.

  Adopters `import MailglassInbound.TestAssertions` (or `use` the
  `MailglassInbound.MailboxCase` that imports it) and assert over the capture
  tuple emitted by `MailglassInbound.Test.Ingress`:

      send(self(), {:inbound, message, outcome, route})

  These assertions read that tuple with `assert_received`/`refute_received`, so
  every assertion is **process-local** — `async: true` tests see only their own
  captures.

  ## Matcher styles (`assert_inbound_received`)

      # 1. Presence (bare call)
      assert_inbound_received()

      # 2. Keyword match
      assert_inbound_received(subject: "Re: ticket #42", from: "alice@example.com")

      # 3. Struct pattern (macro — no explicit quoting)
      assert_inbound_received(%{subject: "Re: ticket #42"})

      # 4. Predicate fn
      assert_inbound_received(fn msg -> String.contains?(msg.subject, "ticket") end)

  Supported keyword keys: `:subject`, `:from`, `:to`, `:tenant`, `:provider`,
  `:envelope_recipient`. `:from`/`:to` match against the address-shaped lists
  (`[%{address: ...}]`). Any other key flunks with a clear message.

  ## Outcome assertions (ITEST-02)

  `assert_inbound_accepted/0`, `_ignored/0`, `_rejected/0`, `_bounced/0` key off
  the persisted `ExecutionRun.outcome` enum carried by the captured
  `outcome` map (`%{outcome: :accept | :ignore | :reject | :bounce | …}`). The
  raw mailbox atoms `:accept | :ignore | {:reject, _} | {:bounce, _}` normalize
  to that enum in `Execution.execute/2`, so the assertion can never drift from
  what was written.

  ## Routing assertions (ITEST-03)

  `assert_inbound_routed_to/1` matches the captured route
  `%{status: :matched, mailbox: ^expected}`; `assert_inbound_no_match/0` matches
  `%{status: :no_match}`.

  ## Negative assertion (ITEST-04)

  `assert_no_inbound_received/0` refutes any captured `{:inbound, …}` tuple.

  ## These are ExUnit assertions, not domain errors

  Every failure is an `ExUnit.AssertionError` raised by `assert`/`flunk` — NOT a
  `%MailglassInbound.Error{}`. The errors-as-contract rule (CLAUDE.md) governs
  the library's runtime API surface; test assertions are a test-time tool, so
  they speak ExUnit. `ExUnit.Assertions` is imported from the bundled OTP
  `:ex_unit` app — no Hex dependency is added (D-47-02).

  ## PII posture

  Failure messages embed caller-supplied matcher values (e.g. a `:subject` or
  `:from` address) so a failing adopter test has the context it needs. Those
  values appear only in the adopter's own test output — never in telemetry, log
  streams, or cross-tenant surfaces (T-47-09). The assertions add no telemetry.
  """

  import ExUnit.Assertions

  alias MailglassInbound.InboundMessage

  # ===== assert_inbound_received — 4 matcher styles via macro =====

  @doc """
  Asserts that at least one inbound message was captured in the current test
  process. See the moduledoc for the four matcher styles.

  ## Style 1: presence (bare call)

      assert_inbound_received()
  """
  @doc since: "0.1.0"
  defmacro assert_inbound_received do
    quote do
      assert_received {:inbound, _msg, _outcome, _route},
                      "No inbound message received in this test process. " <>
                        "Drive one with MailglassInbound.Test.Ingress first."
    end
  end

  @doc """
  Asserts that an inbound message matching the given matcher was captured.

  ## Style 2: keyword list

      assert_inbound_received(subject: "Welcome", from: "alice@example.com")

  ## Style 3: struct pattern (no quoting needed)

      assert_inbound_received(%{subject: "Welcome"})

  ## Style 4: predicate function

      assert_inbound_received(fn msg -> msg.tenant_id == "acme" end)
  """
  @doc since: "0.1.0"
  defmacro assert_inbound_received({:%{}, _, _} = pattern) do
    # Style 3: struct/map pattern — caller passes `%{subject: X}` without quoting.
    quote do
      assert_received {:inbound, unquote(pattern), _outcome, _route},
                      "No inbound message matching the given pattern was received."
    end
  end

  @doc since: "0.1.0"
  defmacro assert_inbound_received({:fn, _, _} = fun_ast) do
    # Style 4: predicate — `fn msg -> ... end`.
    quote do
      assert_received {:inbound, msg, _outcome, _route},
                      "No inbound message received to apply the predicate to."

      fun = unquote(fun_ast)

      assert fun.(msg),
             "assert_inbound_received predicate returned false for message #{inspect(msg)}"
    end
  end

  @doc since: "0.1.0"
  defmacro assert_inbound_received(params) do
    # Style 2: keyword list. Matched at runtime by __match_keyword__/2.
    quote do
      assert_received {:inbound, msg, _outcome, _route},
                      "No inbound message received to match the given keywords against."

      MailglassInbound.TestAssertions.__match_keyword__(msg, unquote(params))
    end
  end

  @doc false
  def __match_keyword__(%InboundMessage{} = msg, params) when is_list(params) do
    Enum.each(params, fn
      {:subject, v} ->
        assert msg.subject == v,
               "subject mismatch: expected #{inspect(v)}, got #{inspect(msg.subject)}"

      {:from, v} when is_binary(v) ->
        assert address_present?(msg.from, v),
               "from mismatch: #{inspect(v)} not in #{inspect(msg.from)}"

      {:to, v} when is_binary(v) ->
        assert address_present?(msg.to, v),
               "to mismatch: #{inspect(v)} not in #{inspect(msg.to)}"

      {:tenant, v} ->
        assert msg.tenant_id == v,
               "tenant_id mismatch: expected #{inspect(v)}, got #{inspect(msg.tenant_id)}"

      {:provider, v} ->
        assert msg.provider == v,
               "provider mismatch: expected #{inspect(v)}, got #{inspect(msg.provider)}"

      {:envelope_recipient, v} ->
        assert msg.envelope_recipient == v,
               "envelope_recipient mismatch: expected #{inspect(v)}, " <>
                 "got #{inspect(msg.envelope_recipient)}"

      {key, _} ->
        flunk(
          "Unsupported matcher key: #{inspect(key)}. " <>
            "Supported: :subject, :from, :to, :tenant, :provider, :envelope_recipient"
        )
    end)
  end

  defp address_present?(addresses, value) when is_list(addresses) do
    Enum.any?(addresses, fn
      %{address: addr} -> addr == value
      addr when is_binary(addr) -> addr == value
      _ -> false
    end)
  end

  defp address_present?(_addresses, _value), do: false

  # ===== Outcome assertions (ITEST-02) =====

  @doc """
  Asserts the most recent captured inbound was accepted (`outcome == :accept`).
  """
  @doc since: "0.1.0"
  defmacro assert_inbound_accepted do
    quote do: MailglassInbound.TestAssertions.__assert_outcome__(:accept)
  end

  @doc """
  Asserts the most recent captured inbound was ignored (`outcome == :ignore`).
  """
  @doc since: "0.1.0"
  defmacro assert_inbound_ignored do
    quote do: MailglassInbound.TestAssertions.__assert_outcome__(:ignore)
  end

  @doc """
  Asserts the most recent captured inbound was rejected (`outcome == :reject`).
  """
  @doc since: "0.1.0"
  defmacro assert_inbound_rejected do
    quote do: MailglassInbound.TestAssertions.__assert_outcome__(:reject)
  end

  @doc """
  Asserts the most recent captured inbound was bounced (`outcome == :bounce`).
  """
  @doc since: "0.1.0"
  defmacro assert_inbound_bounced do
    quote do: MailglassInbound.TestAssertions.__assert_outcome__(:bounce)
  end

  @doc false
  defmacro __assert_outcome__(expected) do
    quote bind_quoted: [expected: expected] do
      assert_received {:inbound, _msg, outcome, _route},
                      "No inbound message received; cannot assert outcome #{inspect(expected)}."

      actual = Map.get(outcome, :outcome)

      assert actual == expected,
             "outcome mismatch: expected #{inspect(expected)}, got #{inspect(actual)} " <>
               "(full outcome: #{inspect(outcome)})"
    end
  end

  # ===== Routing assertions (ITEST-03) =====

  @doc """
  Asserts the most recent captured inbound was routed to `expected_mailbox`
  (route `%{status: :matched, mailbox: ^expected_mailbox}`).
  """
  @doc since: "0.1.0"
  defmacro assert_inbound_routed_to(expected_mailbox) do
    quote do
      expected = unquote(expected_mailbox)

      assert_received {:inbound, _msg, _outcome, route},
                      "No inbound message received; cannot assert routing to #{inspect(expected)}."

      assert match?(%{status: :matched, mailbox: ^expected}, route),
             "route mismatch: expected a match on #{inspect(expected)}, got #{inspect(route)}"
    end
  end

  @doc """
  Asserts the most recent captured inbound did not match any route
  (route `%{status: :no_match}`).
  """
  @doc since: "0.1.0"
  defmacro assert_inbound_no_match do
    quote do
      assert_received {:inbound, _msg, _outcome, route},
                      "No inbound message received; cannot assert :no_match."

      assert match?(%{status: :no_match}, route),
             "expected route :no_match, got #{inspect(route)}"
    end
  end

  # ===== Negative assertion (ITEST-04) =====

  @doc """
  Asserts that NO inbound message was captured in the current test process.
  """
  @doc since: "0.1.0"
  defmacro assert_no_inbound_received do
    quote do
      refute_received {:inbound, _msg, _outcome, _route}
    end
  end
end
