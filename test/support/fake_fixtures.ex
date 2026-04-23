defmodule Mailglass.FakeFixtures do
  @moduledoc """
  Shared Mailable + Message + Delivery fixtures for Phase 3 tests.

  These modules are defined at compile time so macro + behaviour-dispatch
  tests (Plan 04 mailable_test.exs; Plan 05 outbound_test.exs) can reference
  them without per-test module redefinition.
  """

  # Stub mailable with transactional stream (tracking off by default).
  # Used by: Plan 02 Fake tests, Plan 05 Outbound tests, Plan 06 TestAssertions tests.
  defmodule TestMailer do
    # `use Mailglass.Mailable` lands in Plan 04; until then this is a bare module.
    # Plan 04's task renames this to `use Mailglass.Mailable, stream: :transactional`.
    def welcome(email) when is_binary(email) do
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "test@example.com"})
      |> Swoosh.Email.to(email)
      |> Swoosh.Email.subject("Welcome")
      |> Swoosh.Email.text_body("Welcome!")
      |> then(
        &Mailglass.Message.new(&1,
          mailable: __MODULE__,
          mailable_function: :welcome,
          stream: :transactional
        )
      )
    end

    def password_reset(email) when is_binary(email) do
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Test", "test@example.com"})
      |> Swoosh.Email.to(email)
      |> Swoosh.Email.subject("Reset your password")
      |> Swoosh.Email.text_body("Click here")
      |> then(
        &Mailglass.Message.new(&1,
          mailable: __MODULE__,
          mailable_function: :password_reset,
          stream: :transactional
        )
      )
    end
  end
end
