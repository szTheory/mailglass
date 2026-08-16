defmodule MailglassInbound.Router.MatcherTest do
  @moduledoc """
  Covers `MailglassInbound.Router.Matcher.explain/2` — the IADM-04 routing-trace
  reflection seam consumed by the Phase 48 admin LiveView.

  The keystone is the V3 equivalence property (D-48-06): the AND across every
  per-clause verdict `explain/2` emits MUST equal the boolean `matches_route?/2`
  returns, for every route × message over the three matcher kinds (nil / exact /
  regex) × {present, absent, nil} actuals × header AND-semantics. That is what
  guarantees the trace card never lies about why a message did or did not match.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Router.Matcher
  alias MailglassInbound.Router.Route

  # The pass? boolean is the LAST element of every clause verdict tuple,
  # regardless of arity (4-tuple for recipient/subject, 5-tuple for headers).
  defp clause_pass?(tuple), do: elem(tuple, tuple_size(tuple) - 1)

  defp overall(route, message) do
    route
    |> Matcher.explain(message)
    |> Enum.all?(&clause_pass?/1)
  end

  describe "explain/2 example verdicts" do
    test "exact-recipient route: matching message passes the recipient clause" do
      route = %Route{mailbox: M, recipient: "support@example.com"}
      message = %InboundMessage{envelope_recipient: "support@example.com"}

      verdicts = Matcher.explain(route, message)

      assert {:recipient, "support@example.com", "support@example.com", true} in verdicts
      assert overall(route, message) == Matcher.matches_route?(route, message)
      assert overall(route, message)
    end

    test "exact-recipient route: non-matching message fails the recipient clause" do
      route = %Route{mailbox: M, recipient: "support@example.com"}
      message = %InboundMessage{envelope_recipient: "sales@example.com"}

      verdicts = Matcher.explain(route, message)

      assert {:recipient, "support@example.com", "sales@example.com", false} in verdicts
      refute overall(route, message)
      assert overall(route, message) == Matcher.matches_route?(route, message)
    end

    test "regex-recipient route: matching message passes" do
      regex = ~r/@example\.com$/
      route = %Route{mailbox: M, recipient: regex}
      message = %InboundMessage{envelope_recipient: "anyone@example.com"}

      verdicts = Matcher.explain(route, message)

      assert {:recipient, ^regex, "anyone@example.com", true} =
               Enum.find(verdicts, &match?({:recipient, _, _, _}, &1))

      assert overall(route, message) == Matcher.matches_route?(route, message)
    end

    test "wildcard (nil) route matches every actual including a nil actual" do
      route = %Route{mailbox: M, recipient: nil, subject: nil}
      message = %InboundMessage{envelope_recipient: nil, subject: nil}

      verdicts = Matcher.explain(route, message)

      assert {:recipient, nil, nil, true} in verdicts
      assert {:subject, nil, nil, true} in verdicts
      assert overall(route, message)
      assert overall(route, message) == Matcher.matches_route?(route, message)
    end

    test "nil actual against a concrete matcher fails (subject)" do
      route = %Route{mailbox: M, subject: "Receipt"}
      message = %InboundMessage{subject: nil}

      verdicts = Matcher.explain(route, message)

      assert {:subject, "Receipt", nil, false} in verdicts
      refute overall(route, message)
      assert overall(route, message) == Matcher.matches_route?(route, message)
    end

    test "header verdict actual is a LIST and a missing header yields [] + fail" do
      route = %Route{mailbox: M, headers: [{"x-priority", "high"}]}
      # No "x-priority" header present in the message at all.
      message = %InboundMessage{headers: %{"x-other" => ["value"]}}

      verdicts = Matcher.explain(route, message)
      header_verdict = Enum.find(verdicts, &match?({:header, "x-priority", _, _, _}, &1))

      assert {:header, "x-priority", "high", [], false} = header_verdict
      assert is_list(elem(header_verdict, 3))
      refute overall(route, message)
      assert overall(route, message) == Matcher.matches_route?(route, message)
    end

    test "header verdict passes when one of the actual list values matches" do
      route = %Route{mailbox: M, headers: [{"x-priority", "high"}]}
      message = %InboundMessage{headers: %{"x-priority" => ["low", "high"]}}

      verdicts = Matcher.explain(route, message)
      header_verdict = Enum.find(verdicts, &match?({:header, "x-priority", _, _, _}, &1))

      assert {:header, "x-priority", "high", ["low", "high"], true} = header_verdict
      assert overall(route, message) == Matcher.matches_route?(route, message)
    end

    test "multi-clause route: overall equals matches_route?/2 when one header fails" do
      route = %Route{
        mailbox: M,
        recipient: "support@example.com",
        subject: ~r/help/,
        headers: [{"x-priority", "high"}, {"x-tier", "gold"}]
      }

      message = %InboundMessage{
        envelope_recipient: "support@example.com",
        subject: "please help",
        headers: %{"x-priority" => ["high"], "x-tier" => ["silver"]}
      }

      assert overall(route, message) == Matcher.matches_route?(route, message)
      refute overall(route, message)
    end
  end

  describe "explain/2 V3 equivalence property" do
    # Three matcher kinds: nil (wildcard), exact string, regex.
    defp matcher_gen do
      one_of([
        constant(nil),
        member_of(["support@example.com", "sales@example.com", "Receipt", "help", "high", "low"]),
        member_of([~r/example\.com/, ~r/help/i, ~r/^Re:/, ~r/high/])
      ])
    end

    # Actuals: present strings, plus nil (absent).
    defp actual_gen do
      one_of([
        constant(nil),
        member_of([
          "support@example.com",
          "sales@example.com",
          "Receipt",
          "please help",
          "Re: ticket"
        ])
      ])
    end

    # A header map whose values are LISTS (the normalized shape). The name pool
    # is wider than the clause-name pool, so the message headers
    # overlap the clause names sometimes and miss them other times — exercising
    # both the present-header and the absent-header (`Map.get(.., [])`) paths.
    defp header_name_gen do
      one_of([
        member_of(["x-priority", "x-tier", "x-spam"]),
        string(:alphanumeric, min_length: 3, max_length: 8)
      ])
    end

    defp headers_gen do
      list_of(
        tuple({
          header_name_gen(),
          list_of(member_of(["high", "low", "gold", "silver"]), max_length: 3)
        }),
        max_length: 4
      )
      |> map(&Map.new/1)
    end

    defp header_clauses_gen do
      list_of(
        tuple({member_of(["x-priority", "x-tier", "x-spam"]), matcher_gen()}),
        max_length: 3
      )
    end

    property "AND of explain/2 clause verdicts equals matches_route?/2" do
      check all recipient <- matcher_gen(),
                subject <- matcher_gen(),
                header_clauses <- header_clauses_gen(),
                envelope_recipient <- actual_gen(),
                actual_subject <- actual_gen(),
                headers <- headers_gen(),
                max_runs: 500 do
        route = %Route{
          mailbox: M,
          recipient: recipient,
          subject: subject,
          headers: header_clauses
        }

        message = %InboundMessage{
          envelope_recipient: envelope_recipient,
          subject: actual_subject,
          headers: headers
        }

        verdicts = Matcher.explain(route, message)
        derived = Enum.all?(verdicts, &clause_pass?/1)

        assert derived == Matcher.matches_route?(route, message)
      end
    end

    property "every clause verdict's last element is a boolean" do
      check all recipient <- matcher_gen(),
                subject <- matcher_gen(),
                header_clauses <- header_clauses_gen(),
                envelope_recipient <- actual_gen(),
                actual_subject <- actual_gen(),
                headers <- headers_gen(),
                max_runs: 200 do
        route = %Route{
          mailbox: M,
          recipient: recipient,
          subject: subject,
          headers: header_clauses
        }

        message = %InboundMessage{
          envelope_recipient: envelope_recipient,
          subject: actual_subject,
          headers: headers
        }

        for verdict <- Matcher.explain(route, message) do
          assert is_boolean(clause_pass?(verdict))
        end
      end
    end
  end
end
