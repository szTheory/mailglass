defmodule Mailglass.OptionalDeps.GenSmtpTest do
  use ExUnit.Case, async: true

  alias Mailglass.OptionalDeps.GenSmtp

  # gen_smtp (and therefore :mimemail) is a core optional dep resolved in the
  # test env, so available?/0 is true here and decode/2 exercises the real
  # parser. The never-raise contract (T-45-10) is the load-bearing assertion:
  # :mimemail.decode/2 escapes via erlang:error (rescue), throw (catch :throw),
  # and :exit (catch :exit). Each must surface as a tagged {:error, _} tuple.

  @valid_text_plain "From: a@example.com\r\n" <>
                      "To: b@example.com\r\n" <>
                      "Subject: Hi\r\n" <>
                      "Content-Type: text/plain; charset=utf-8\r\n\r\n" <>
                      "Hello world\r\n"

  describe "available?/0" do
    test "returns true when gen_smtp is resolved (core test env)" do
      assert GenSmtp.available?()
    end
  end

  describe "decode/2 — success" do
    test "returns {:ok, tuple} for a canonical RFC 5322 body" do
      assert {:ok, tuple} = GenSmtp.decode(@valid_text_plain)
      # 5-tuple {Type, SubType, Headers, Parameters, Body}
      assert is_tuple(tuple)
      assert tuple_size(tuple) == 5
      assert {"text", "plain", headers, %{} = _params, body} = tuple
      assert is_list(headers)
      assert body == "Hello world\r\n"
    end
  end

  describe "decode/2 — never raises (T-45-10)" do
    test "erlang:error path returns {:error, {:error, _}} (no_boundary)" do
      # multipart Content-Type with no boundary= parameter -> erlang:error(no_boundary)
      raw =
        "From: a@example.com\r\n" <>
          "MIME-Version: 1.0\r\n" <>
          "Content-Type: multipart/mixed\r\n\r\n--X--\r\n"

      assert {:error, {:error, _}} = GenSmtp.decode(raw)
    end

    test "erlang:error path returns {:error, {:error, _}} (missing_last_boundary on truncated multipart)" do
      raw =
        "From: a@example.com\r\n" <>
          "MIME-Version: 1.0\r\n" <>
          "Content-Type: multipart/mixed; boundary=\"BOUND\"\r\n\r\n" <>
          "--BOUND\r\nContent-Type: text/plain\r\n\r\nbody\r\n"

      assert {:error, {:error, _}} = GenSmtp.decode(raw)
    end

    test "throw path returns {:error, {:throw, _}} (bad_content_type)" do
      raw = "From: a@example.com\r\nContent-Type: not-a-valid-type\r\n\r\nbody\r\n"
      assert {:error, {:throw, :bad_content_type}} = GenSmtp.decode(raw)
    end

    test "throw path returns {:error, {:throw, _}} (badchar quoted-printable)" do
      raw =
        "From: a@example.com\r\n" <>
          "Content-Type: text/plain\r\n" <>
          "Content-Transfer-Encoding: quoted-printable\r\n\r\nfoo=X\r\n"

      assert {:error, {:throw, :badchar}} = GenSmtp.decode(raw)
    end
  end

  describe "decode/2 — opts" do
    test "merges caller opts after the mandatory iconv-avoidance defaults" do
      # encoding: none is mandatory (gen_smtp does not bundle iconv). Passing an
      # explicit opt must not strip the defaults; a valid body still decodes.
      assert {:ok, _} = GenSmtp.decode(@valid_text_plain, allow_missing_version: true)
    end

    test "raises a FunctionClauseError guard violation for non-binary input is impossible — guard rejects at the boundary" do
      assert_raise FunctionClauseError, fn -> GenSmtp.decode(:not_a_binary) end
    end
  end
end
