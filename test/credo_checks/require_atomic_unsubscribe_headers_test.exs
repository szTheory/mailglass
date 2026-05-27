defmodule Mailglass.Credo.LegacyRequireAtomicUnsubscribeHeadersTest do
  use Credo.Test.Case

  alias Mailglass.Credo.RequireAtomicUnsubscribeHeaders

  setup_all do
    Application.ensure_all_started(:credo)
    :ok
  end

  test "reports direct unsubscribe header writes outside the compliance injector" do
    """
    defmodule MyApp.Mailer do
      def add_header(email, url) do
        Swoosh.Email.header(email, "List-Unsubscribe", "<\#{url}>")
      end
    end
    """
    |> to_source_file()
    |> run_check(RequireAtomicUnsubscribeHeaders)
    |> assert_issue()
  end

  test "reports helper-style one-click header writes outside the compliance injector" do
    """
    defmodule MyApp.Mailer do
      def add_header(email) do
        put_header_if_absent(email, "List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
      end
    end
    """
    |> to_source_file()
    |> run_check(RequireAtomicUnsubscribeHeaders)
    |> assert_issue()
  end

  test "accepts the dedicated compliance injection path" do
    """
    defmodule Mailglass.Compliance do
      def inject_unsubscribe_headers(message, url) do
        email =
          message.swoosh_email
          |> put_header_if_absent("List-Unsubscribe", "<\#{url}>")
          |> put_header_if_absent("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")

        %{message | swoosh_email: email}
      end
    end
    """
    |> to_source_file()
    |> run_check(RequireAtomicUnsubscribeHeaders)
    |> refute_issues()
  end

  test "does not flag tests that only assert on unsubscribe headers" do
    """
    defmodule MyApp.MailerTest do
      use ExUnit.Case

      test "asserts on the injected headers" do
        email = %{headers: %{"List-Unsubscribe" => "<https://example.test>"}}
        assert email.headers["List-Unsubscribe"] == "<https://example.test>"
      end
    end
    """
    |> to_source_file()
    |> run_check(RequireAtomicUnsubscribeHeaders)
    |> refute_issues()
  end
end
