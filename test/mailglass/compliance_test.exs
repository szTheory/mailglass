defmodule Mailglass.ComplianceTest do
  use ExUnit.Case, async: true

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
end
