defmodule MailglassAdmin.DiscoveryTest do
  @moduledoc """
  RED-by-default coverage for PREV-03 discovery portion: `MailglassAdmin.Preview.Discovery.discover/1`
  auto-scanning loaded mailables and surfacing healthy / no-previews /
  raising mailables via the graceful-failure return shape from CONTEXT D-13.

  Plan 04 lands `MailglassAdmin.Preview.Discovery` per 05-PATTERNS.md
  §"discovery.ex" + 05-RESEARCH.md Pattern 3, turning these RED tests green.
  """

  use ExUnit.Case, async: true

  alias MailglassAdmin.Preview.Discovery
  alias MailglassAdmin.Fixtures.{HappyMailer, StubMailer, BrokenMailer}

  describe "discover/1 with explicit list" do
    test "explicit list returns scenarios for healthy mailable" do
      assert [{HappyMailer, scenarios}] = Discovery.discover([HappyMailer])

      assert Keyword.keys(scenarios) == [:welcome_default, :welcome_enterprise],
             "scenarios must preserve HappyMailer.preview_props/0 order"
    end

    test "stub mailable yields :no_previews sentinel" do
      assert [{StubMailer, :no_previews}] = Discovery.discover([StubMailer])
    end

    test "raising preview_props/0 yields {:error, formatted_stacktrace}" do
      assert [{BrokenMailer, {:error, msg}}] = Discovery.discover([BrokenMailer])
      assert msg =~ "boom",
             "formatted stacktrace must contain the raised message substring"
    end

    test "non-mailable module raises ArgumentError with actionable message" do
      assert_raise ArgumentError, ~r/use Mailglass\.Mailable/, fn ->
        Discovery.discover([Enum])
      end
    end
  end

  describe "discover/1 with :auto_scan" do
    test "auto_scan returns a list of {module, scenarios} tuples" do
      discovered = Discovery.discover(:auto_scan)
      assert is_list(discovered)

      # Every entry is a 2-tuple with a module atom head.
      Enum.each(discovered, fn entry ->
        assert is_tuple(entry) and tuple_size(entry) == 2
        assert is_atom(elem(entry, 0))
      end)
    end

    test "auto_scan includes fixture mailables when their OTP app is loaded" do
      discovered = Discovery.discover(:auto_scan)
      modules = Enum.map(discovered, &elem(&1, 0))

      assert HappyMailer in modules,
             "auto_scan must surface HappyMailer while :mailglass_admin is loaded"
    end
  end
end
