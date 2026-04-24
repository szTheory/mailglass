defmodule Mailglass.Credo.NoTrackingOnAuthStreamTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoTrackingOnAuthStream

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags auth-context mailable function that enables tracking" do
    source = """
    defmodule Mailglass.Mailers.AuthMailer do
      use Mailglass.Mailable

      def password_reset(user) do
        Mailglass.Message.new(Swoosh.Email.new(), to: user.email, tracking: [opens: true])
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "password_reset")
  end

  test "does not flag auth-context mailable function when tracking is disabled" do
    source = """
    defmodule Mailglass.Mailers.SafeAuthMailer do
      use Mailglass.Mailable

      def verify_email(user) do
        Mailglass.Message.new(Swoosh.Email.new(), to: user.email, tracking: [])
      end
    end
    """

    assert run_check(source) == []
  end

  test "does not flag non-auth mailable function with tracking enabled" do
    source = """
    defmodule Mailglass.Mailers.MarketingLike do
      use Mailglass.Mailable

      def welcome(user) do
        Mailglass.Message.new(Swoosh.Email.new(), to: user.email, tracking: [opens: true, clicks: true])
      end
    end
    """

    assert run_check(source) == []
  end

  test "does not flag modules that do not use Mailglass.Mailable" do
    source = """
    defmodule Mailglass.OtherModule do
      def confirm_account(user) do
        Mailglass.Message.new(Swoosh.Email.new(), to: user.email, tracking: [opens: true])
      end
    end
    """

    assert run_check(source) == []
  end

  test "flags auth-function heuristics beyond baseline names" do
    source = """
    defmodule Mailglass.Mailers.TwoFactorMailer do
      use Mailglass.Mailable

      def two_factor_code(user) do
        Mailglass.Message.new(Swoosh.Email.new(), to: user.email, tracking: %{opens: true})
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "two_factor_code")
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("test/mailglass/credo/no_tracking_on_auth_stream_fixture.ex")
    |> NoTrackingOnAuthStream.run([])
  end
end
