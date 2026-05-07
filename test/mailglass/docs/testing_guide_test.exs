defmodule Mailglass.Docs.TestingGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/testing.md"
  @test_assertions "lib/mailglass/test_assertions.ex"
  @mailer_case "test/support/mailer_case.ex"
  @oban_helpers "test/support/oban_helpers.ex"

  test "canonical testing guide keeps the required section order and contract headings" do
    guide = File.read!(@guide)

    sections = [
      "## deliver/2 baseline",
      "## deliver_later/2 baseline",
      "## Optional Oban lanes",
      "## Cross-process and browser ownership",
      "## PubSub and webhook assertions",
      "## Footguns and strict-CI posture"
    ]

    Enum.each(sections, fn section ->
      assert guide =~ section
    end)

    positions =
      Enum.map(sections, fn section ->
        {section, :binary.match(guide, section)}
      end)

    assert Enum.all?(positions, fn {_section, match} -> match != :nomatch end)

    assert positions == Enum.sort_by(positions, fn {_section, {index, _len}} -> index end)
  end

  test "canonical testing guide documents the shipped helper semantics and narrow exceptions" do
    guide = File.read!(@guide)

    assert guide =~ "canonical testing guide"
    assert guide =~ "Mailglass.Adapters.Fake"
    assert guide =~ "Mailglass.TestAssertions"
    assert guide =~ "Mailglass.MailerCase"
    assert guide =~ "last_mail/0"
    assert guide =~ "reads Fake-backed delivery storage"
    assert guide =~ "does not consume the process mailbox"
    assert guide =~ "wait_for_mail/1"
    assert guide =~ "waits up to a timeout"
    assert guide =~ "fails if nothing arrives before the timeout"
    assert guide =~ "Fake.allow/2"
    assert guide =~ "shared/global"
    assert guide =~ "setup :set_mailglass_global"
    assert guide =~ "async: false"
    assert guide =~ "oban_jobs"
    assert guide =~ "`:inline`"
    assert guide =~ "`:manual`"
    assert guide =~ "PubSub-backed assertions"
    assert guide =~ "do not inspect the Fake mailbox or Fake delivery storage"
  end

  test "public helper docs match the canonical testing guide" do
    test_assertions = File.read!(@test_assertions)
    mailer_case = File.read!(@mailer_case)
    oban_helpers = File.read!(@oban_helpers)

    assert test_assertions =~ "`last_mail/0` reads Fake-backed delivery storage"

    assert test_assertions =~
             "`wait_for_mail/1`, `assert_no_mail_sent/0`, and `assert_mail_sent/0,1`"

    assert test_assertions =~ "reads Fake-backed delivery storage"
    assert test_assertions =~ "without consuming the"
    assert test_assertions =~ "process mailbox"
    assert test_assertions =~ "wait_for_mail timed out after"
    assert test_assertions =~ "Use when asserting webhook-received events"

    assert mailer_case =~
             "Application.put_env(:mailglass, :async_adapter_impl, Mailglass.Outbound.AsyncAdapter.Inline)"

    assert mailer_case =~
             "Use `Mailglass.Adapters.Fake.allow/2` first for targeted cross-process access."

    assert mailer_case =~ "Shared/global fallback via `setup :set_mailglass_global`"
    assert mailer_case =~ "non-async"
    assert mailer_case =~ "Both documented Oban lanes require `async: false`"
    assert mailer_case =~ "`oban_jobs` table"

    assert oban_helpers =~ "`@tag oban: :manual`"
    assert oban_helpers =~ "`@tag oban: :inline` tests"
    assert oban_helpers =~ "Both lanes require `async: false`."
    assert oban_helpers =~ "`oban_jobs` table must exist"
  end
end
