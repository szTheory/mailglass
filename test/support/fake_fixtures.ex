defmodule Mailglass.FakeFixtures do
  @moduledoc """
  Shared Mailable + Message + Delivery fixtures for Phase 3 tests.

  These modules are defined at compile time so macro + behaviour-dispatch
  tests (Plan 04 mailable_test.exs; Plan 05 outbound_test.exs) can reference
  them without per-test module redefinition.
  """

  # Mailable with transactional stream (tracking off by default).
  # Used by: Plan 02 Fake tests, Plan 04 mailable tests, Plan 05 Outbound tests,
  # Plan 06 TestAssertions tests.
  defmodule TestMailer do
    use Mailglass.Mailable, stream: :transactional

    def welcome(email) when is_binary(email) do
      new()
      |> Mailglass.Message.update_swoosh(fn e ->
           e
           |> Swoosh.Email.from({"Test", "test@example.com"})
           |> Swoosh.Email.to(email)
           |> Swoosh.Email.subject("Welcome")
           |> Swoosh.Email.text_body("Welcome!")
         end)
      |> Mailglass.Message.put_function(:welcome)
    end

    def password_reset(email) when is_binary(email) do
      new()
      |> Mailglass.Message.update_swoosh(fn e ->
           e
           |> Swoosh.Email.from({"Test", "test@example.com"})
           |> Swoosh.Email.to(email)
           |> Swoosh.Email.subject("Reset your password")
           |> Swoosh.Email.text_body("Click here")
         end)
      |> Mailglass.Message.put_function(:password_reset)
    end
  end

  # Mailable with tracking opts — used by Plan 04 Task 2 auth-stream guard tests.
  # stream: :operational with both opens + clicks enabled.
  defmodule TrackingMailer do
    use Mailglass.Mailable, stream: :operational, tracking: [opens: true, clicks: true]

    def campaign(email) when is_binary(email) do
      new()
      |> Mailglass.Message.update_swoosh(fn e ->
           e
           |> Swoosh.Email.from({"Test", "test@example.com"})
           |> Swoosh.Email.to(email)
           |> Swoosh.Email.subject("Campaign")
           |> Swoosh.Email.text_body("Campaign body")
         end)
      |> Mailglass.Message.put_function(:campaign)
    end
  end
end
