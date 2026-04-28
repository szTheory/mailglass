defmodule Mailglass.ComplianceTest do
  use ExUnit.Case, async: true

  alias Mailglass.Message

  defmodule OperationalOptInMailer do
    def __mailglass_unsubscribe__ do
      [enabled: true]
    end
  end

  defmodule NoOptInMailer do
  end

  setup do
    prior_tracking = Application.get_env(:mailglass, :tracking)
    prior_compliance = Application.get_env(:mailglass, :compliance)

    Application.put_env(:mailglass, :tracking, endpoint: "tracking-endpoint-secret-123")

    Application.put_env(:mailglass, :compliance,
      endpoint: "current-secret-key-base-123",
      host: "unsubscribe.example.com",
      scheme: "https",
      mount_path: "/mailglass/unsubscribe",
      previous_secrets: [],
      redirect: nil,
      max_age: 60
    )

    on_exit(fn ->
      Application.put_env(:mailglass, :tracking, prior_tracking)
      Application.put_env(:mailglass, :compliance, prior_compliance)
    end)

    :ok
  end

  describe "add_rfc_required_headers/1" do
    test "adds Date header when absent (COMP-01)" do
      email = %Swoosh.Email{headers: %{}}
      result = Mailglass.Compliance.add_rfc_required_headers(email)
      assert Map.has_key?(result.headers, "Date")

      # Sanity check the RFC 2822 shape: "Wed, 22 Apr 2026 12:00:00 +0000"
      assert Regex.match?(
               ~r/^[A-Z][a-z]{2}, \d{2} [A-Z][a-z]{2} \d{4} \d{2}:\d{2}:\d{2} \+0000$/,
               result.headers["Date"]
             )
    end

    test "adds Message-ID header when absent (COMP-01)" do
      email = %Swoosh.Email{headers: %{}}
      result = Mailglass.Compliance.add_rfc_required_headers(email)
      assert Map.has_key?(result.headers, "Message-ID")

      message_id = result.headers["Message-ID"]
      assert String.starts_with?(message_id, "<")
      assert String.ends_with?(message_id, "@mailglass>")
    end

    test "adds MIME-Version: 1.0 when absent (COMP-01)" do
      email = %Swoosh.Email{headers: %{}}
      result = Mailglass.Compliance.add_rfc_required_headers(email)
      assert result.headers["MIME-Version"] == "1.0"
    end

    test "does NOT overwrite existing Date header (COMP-01)" do
      email = %Swoosh.Email{headers: %{"Date" => "Thu, 01 Jan 2026 00:00:00 +0000"}}
      result = Mailglass.Compliance.add_rfc_required_headers(email)
      assert result.headers["Date"] == "Thu, 01 Jan 2026 00:00:00 +0000"
    end

    test "does NOT overwrite existing Message-ID header (COMP-01)" do
      email = %Swoosh.Email{headers: %{"Message-ID" => "<existing@example.com>"}}
      result = Mailglass.Compliance.add_rfc_required_headers(email)
      assert result.headers["Message-ID"] == "<existing@example.com>"
    end

    test "does NOT overwrite existing MIME-Version header (COMP-01)" do
      email = %Swoosh.Email{headers: %{"MIME-Version" => "2.0"}}
      result = Mailglass.Compliance.add_rfc_required_headers(email)
      assert result.headers["MIME-Version"] == "2.0"
    end

    test "adds default Mailglass-Mailable header when absent (COMP-02)" do
      email = %Swoosh.Email{headers: %{}}
      result = Mailglass.Compliance.add_rfc_required_headers(email)
      assert Map.has_key?(result.headers, "Mailglass-Mailable")
    end

    test "does NOT overwrite existing Mailglass-Mailable header (COMP-02)" do
      email = %Swoosh.Email{headers: %{"Mailglass-Mailable" => "MyApp.Foo.bar/1"}}
      result = Mailglass.Compliance.add_rfc_required_headers(email)
      assert result.headers["Mailglass-Mailable"] == "MyApp.Foo.bar/1"
    end
  end

  describe "add_mailable_header/4" do
    test "Mailglass-Mailable header has format 'Module.function/arity' (COMP-02)" do
      email = %Swoosh.Email{headers: %{}}

      result =
        Mailglass.Compliance.add_mailable_header(email, MyApp.UserMailer, :welcome, 1)

      assert result.headers["Mailglass-Mailable"] == "MyApp.UserMailer.welcome/1"
    end

    test "does NOT overwrite existing Mailglass-Mailable header" do
      email = %Swoosh.Email{headers: %{"Mailglass-Mailable" => "MyApp.Existing.keep/2"}}

      result =
        Mailglass.Compliance.add_mailable_header(email, MyApp.UserMailer, :welcome, 1)

      assert result.headers["Mailglass-Mailable"] == "MyApp.Existing.keep/2"
    end

    test "strips 'Elixir.' prefix from module name" do
      email = %Swoosh.Email{headers: %{}}

      result =
        Mailglass.Compliance.add_mailable_header(email, Mailglass.RendererTest, :welcome, 1)

      assert result.headers["Mailglass-Mailable"] == "Mailglass.RendererTest.welcome/1"
      refute String.starts_with?(result.headers["Mailglass-Mailable"], "Elixir.")
    end
  end

  describe "maybe_add_feedback_id/1" do
    setup do
      original_config = Application.get_env(:mailglass, :feedback_id)
      on_exit(fn -> Application.put_env(:mailglass, :feedback_id, original_config) end)
      :ok
    end

    test "does not inject header if feedback_id is nil" do
      Application.put_env(:mailglass, :feedback_id, nil)
      message = %Mailglass.Message{swoosh_email: %Swoosh.Email{}}
      result = Mailglass.Compliance.maybe_add_feedback_id(message)
      refute Map.has_key?(result.swoosh_email.headers, "Feedback-ID")
    end

    test "injects Feedback-ID with expected format when configured" do
      Application.put_env(:mailglass, :feedback_id, "my-sender")

      message = %Mailglass.Message{
        swoosh_email: %Swoosh.Email{},
        tenant_id: "acme",
        mailable: MyApp.WelcomeMailer,
        stream: :bulk
      }

      result = Mailglass.Compliance.maybe_add_feedback_id(message)
      assert result.swoosh_email.headers["Feedback-ID"] == "my-sender:MyApp.WelcomeMailer:acme:bulk"
    end

    test "interpolates defaults for missing tenant and mailable" do
      Application.put_env(:mailglass, :feedback_id, "my-sender")

      message = %Mailglass.Message{
        swoosh_email: %Swoosh.Email{},
        tenant_id: nil,
        mailable: nil,
        stream: :transactional
      }

      result = Mailglass.Compliance.maybe_add_feedback_id(message)
      assert result.swoosh_email.headers["Feedback-ID"] == "my-sender:unknown:default:transactional"
    end

    test "does NOT overwrite an explicitly set Feedback-ID header" do
      Application.put_env(:mailglass, :feedback_id, "my-sender")

      email = %Swoosh.Email{headers: %{"Feedback-ID" => "explicit:override:value"}}

      message = %Mailglass.Message{
        swoosh_email: email,
        tenant_id: "acme",
        mailable: MyApp.WelcomeMailer,
        stream: :bulk
      }

      result = Mailglass.Compliance.maybe_add_feedback_id(message)
      assert result.swoosh_email.headers["Feedback-ID"] == "explicit:override:value"
    end
  end

  describe "apply_outbound_headers/1" do
    test "adds unsubscribe headers for bulk messages" do
      message =
        %Swoosh.Email{}
        |> Message.build(stream: :bulk, tenant_id: "tenant-1")
        |> Mailglass.Compliance.apply_outbound_headers()

      assert message.swoosh_email.headers["List-Unsubscribe"] =~ "https://"
      assert message.swoosh_email.headers["List-Unsubscribe-Post"] == "List-Unsubscribe=One-Click"
    end

    test "does not add unsubscribe headers for transactional messages" do
      message =
        %Swoosh.Email{}
        |> Message.build(stream: :transactional, tenant_id: "tenant-1")
        |> Mailglass.Compliance.apply_outbound_headers()

      refute Map.has_key?(message.swoosh_email.headers, "List-Unsubscribe")
      refute Map.has_key?(message.swoosh_email.headers, "List-Unsubscribe-Post")
    end

    test "adds unsubscribe headers for operational messages only when the mailable opts in" do
      opted_in =
        %Swoosh.Email{}
        |> Message.build(
          stream: :operational,
          tenant_id: "tenant-1",
          mailable: OperationalOptInMailer
        )
        |> Mailglass.Compliance.apply_outbound_headers()

      opted_out =
        %Swoosh.Email{}
        |> Message.build(stream: :operational, tenant_id: "tenant-1", mailable: NoOptInMailer)
        |> Mailglass.Compliance.apply_outbound_headers()

      assert opted_in.swoosh_email.headers["List-Unsubscribe"] =~ "https://"
      assert opted_in.swoosh_email.headers["List-Unsubscribe-Post"] == "List-Unsubscribe=One-Click"
      refute Map.has_key?(opted_out.swoosh_email.headers, "List-Unsubscribe")
      refute Map.has_key?(opted_out.swoosh_email.headers, "List-Unsubscribe-Post")
    end
  end

  describe "inject_unsubscribe_headers/2" do
    test "preserves an intentionally pre-set unsubscribe header pair" do
      email = %Swoosh.Email{
        headers: %{
          "List-Unsubscribe" => "<https://example.test/unsub>",
          "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click"
        }
      }

      message = Message.build(email, stream: :bulk, tenant_id: "tenant-1")

      result =
        Mailglass.Compliance.inject_unsubscribe_headers(message, "https://mailglass.dev/unsub")

      assert result.swoosh_email.headers["List-Unsubscribe"] == "<https://example.test/unsub>"
      assert result.swoosh_email.headers["List-Unsubscribe-Post"] == "List-Unsubscribe=One-Click"
    end

    test "does not write a half-configured unsubscribe pair" do
      email = %Swoosh.Email{
        headers: %{
          "List-Unsubscribe" => "<https://example.test/unsub>"
        }
      }

      message = Message.build(email, stream: :bulk, tenant_id: "tenant-1")

      result =
        Mailglass.Compliance.inject_unsubscribe_headers(message, "https://mailglass.dev/unsub")

      assert result.swoosh_email.headers["List-Unsubscribe"] == "<https://example.test/unsub>"
      refute Map.has_key?(result.swoosh_email.headers, "List-Unsubscribe-Post")
    end
  end
end
