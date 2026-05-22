defmodule MailglassInbound.MIMETest do
  use ExUnit.Case, async: true

  alias MailglassInbound.{MIME, MIMEError}

  # gen_smtp (and :mimemail) is an inbound optional dep resolved in the test env,
  # so parse/1 exercises the real :mimemail parser via the GenSmtp gateway seam.
  # The load-bearing contract is MIME-04: parse/1 NEVER raises across all three
  # :mimemail escape mechanisms (erlang:error, throw, :exit).

  @text_plain "From: a@example.com\r\n" <>
                "To: b@example.com\r\n" <>
                "Subject: Hi\r\n" <>
                "Content-Type: text/plain; charset=utf-8\r\n\r\n" <>
                "Hello world\r\n"

  @multipart_attachment "From: a@example.com\r\n" <>
                          "To: b@example.com\r\n" <>
                          "Subject: MP\r\n" <>
                          "MIME-Version: 1.0\r\n" <>
                          "Content-Type: multipart/mixed; boundary=\"BOUND\"\r\n\r\n" <>
                          "--BOUND\r\n" <>
                          "Content-Type: text/plain; charset=utf-8\r\n\r\n" <>
                          "body text\r\n" <>
                          "--BOUND\r\n" <>
                          "Content-Type: application/pdf; name=\"a.pdf\"\r\n" <>
                          "Content-Disposition: attachment; filename=\"a.pdf\"\r\n" <>
                          "Content-Transfer-Encoding: base64\r\n\r\n" <>
                          "QUJD\r\n" <>
                          "--BOUND--\r\n"

  describe "parse/1 — MIME-01 canonical parse" do
    test "text/plain returns the stable internal representation" do
      assert {:ok, repr} = MIME.parse(@text_plain)
      assert %{headers: headers, parts: parts, attachments: [], inline: []} = repr
      assert is_list(headers)
      # the leaf body is carried in :parts
      assert [%{type: "text", subtype: "plain", body: "Hello world\r\n"}] = parts
    end

    test "multipart/mixed recurses and classifies the attachment with its filename" do
      assert {:ok, repr} = MIME.parse(@multipart_attachment)
      assert %{attachments: [attachment]} = repr
      assert attachment.type == "application"
      assert attachment.subtype == "pdf"
      assert attachment.filename == "a.pdf"
      # the text/plain leaf is a non-attachment part
      assert Enum.any?(repr.parts, fn p -> p.type == "text" and p.subtype == "plain" end)
    end

    test "inline part (Content-Disposition: inline) is classified into :inline" do
      raw =
        "From: a@example.com\r\n" <>
          "MIME-Version: 1.0\r\n" <>
          "Content-Type: multipart/related; boundary=\"B\"\r\n\r\n" <>
          "--B\r\nContent-Type: text/plain\r\n\r\nbody\r\n" <>
          "--B\r\n" <>
          "Content-Type: image/png; name=\"img.png\"\r\n" <>
          "Content-Disposition: inline; filename=\"img.png\"\r\n" <>
          "Content-Transfer-Encoding: base64\r\n\r\nQUJD\r\n" <>
          "--B--\r\n"

      assert {:ok, repr} = MIME.parse(raw)
      assert [inline] = repr.inline
      assert inline.type == "image"
      assert inline.subtype == "png"
      assert inline.filename == "img.png"
    end
  end

  describe "parse/1 — MIME-04 never raises (three escape mechanisms)" do
    test "erlang:error path (missing_last_boundary on truncated multipart) returns a structured error" do
      raw =
        "From: a@example.com\r\n" <>
          "MIME-Version: 1.0\r\n" <>
          "Content-Type: multipart/mixed; boundary=\"BOUND\"\r\n\r\n" <>
          "--BOUND\r\nContent-Type: text/plain\r\n\r\nbody\r\n"

      assert {:error, %MIMEError{type: :inbound_mime_invalid} = e} = MIME.parse(raw)
      assert e.context[:byte_size] == byte_size(raw)
    end

    test "throw path (bad_content_type) returns a structured error" do
      raw = "From: a@example.com\r\nContent-Type: not-a-valid-type\r\n\r\nbody\r\n"
      assert {:error, %MIMEError{type: :inbound_mime_invalid}} = MIME.parse(raw)
    end

    test "throw path (badchar quoted-printable) returns a structured error" do
      raw =
        "From: a@example.com\r\n" <>
          "Content-Type: text/plain\r\n" <>
          "Content-Transfer-Encoding: quoted-printable\r\n\r\nfoo=X\r\n"

      assert {:error, %MIMEError{type: :inbound_mime_invalid}} = MIME.parse(raw)
    end

    test "no_boundary (multipart without a boundary= param) returns a structured error" do
      raw =
        "From: a@example.com\r\nMIME-Version: 1.0\r\n" <>
          "Content-Type: multipart/mixed\r\n\r\n--X--\r\n"

      assert {:error, %MIMEError{type: :inbound_mime_invalid}} = MIME.parse(raw)
    end
  end

  describe "parse/2 — MIME-02 degraded fallback" do
    test "returns :gen_smtp_unavailable when the gateway is absent" do
      assert {:error, %MIMEError{type: :gen_smtp_unavailable} = e} =
               MIME.parse(@text_plain, gen_smtp_available?: false)

      assert e.cause == nil
      assert is_binary(e.message)
    end
  end

  describe "parse/2 — boundary-bomb / deep-nesting guard (T-45-12, V5)" do
    test "deeply nested multipart beyond max_depth returns a structured error, not a crash" do
      nested = deeply_nested_multipart(50)
      raw = "From: a@example.com\r\nMIME-Version: 1.0\r\n" <> nested

      assert {:error, %MIMEError{type: :inbound_mime_invalid}} =
               MIME.parse(raw, max_depth: 5)
    end

    test "nesting within max_depth still parses" do
      nested = deeply_nested_multipart(2)
      raw = "From: a@example.com\r\nMIME-Version: 1.0\r\n" <> nested
      assert {:ok, %{}} = MIME.parse(raw, max_depth: 100)
    end
  end

  defp deeply_nested_multipart(levels) do
    inner = "Content-Type: text/plain\r\n\r\nleaf\r\n"

    Enum.reduce(1..levels, inner, fn level, acc ->
      b = "B#{level}"

      "Content-Type: multipart/mixed; boundary=\"#{b}\"\r\nMIME-Version: 1.0\r\n\r\n" <>
        "--#{b}\r\n#{acc}\r\n--#{b}--\r\n"
    end)
  end
end
