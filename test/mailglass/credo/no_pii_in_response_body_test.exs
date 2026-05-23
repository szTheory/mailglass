defmodule Mailglass.Credo.NoPiiInResponseBodyTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoPiiInResponseBody

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  # In-scope filename so the path-gated check fires. (The filename trap: an
  # out-of-scope name makes the check inert and the test would pass for the
  # wrong reason — see the path-gating case below.)
  @in_scope "mailglass_inbound/lib/mailglass_inbound/ingress/fixture.ex"

  test "flags inspect(reason) in a send_json body (the original leak shape)" do
    source = """
    defmodule MailglassInbound.Ingress.Leak do
      def run(conn, reason) do
        send_json(conn, 500, %{status: "error", reason: inspect(reason)})
      end
    end
    """

    issues = run_check(source, @in_scope)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "static closed code")
  end

  test "flags inspect(changeset) in a send_resp body" do
    source = """
    defmodule MailglassInbound.Ingress.Leak2 do
      def run(conn, changeset) do
        send_resp(conn, 500, inspect(changeset))
      end
    end
    """

    issues = run_check(source, @in_scope)

    assert length(issues) == 1
  end

  test "flags an %Ecto.Changeset{} literal in a response body" do
    source = """
    defmodule MailglassInbound.Ingress.Leak3 do
      def run(conn) do
        send_resp(conn, 500, %Ecto.Changeset{})
      end
    end
    """

    assert length(run_check(source, @in_scope)) == 1
  end

  test "flags a differently-named error variable as a response-body field (WR-02, err)" do
    # The error term is bound to `err`, NOT `reason`/`changeset`. Today the
    # original check's fragment list missed this; the mandated bare-variable
    # body-arg rule (plus the optional `"error"` fragment that substring-matches
    # `err`) closes it.
    source = """
    defmodule MailglassInbound.Ingress.LeakErr do
      def run(conn, err) do
        send_json(conn, 500, %{status: "error", detail: err})
      end
    end
    """

    issues = run_check(source, @in_scope)

    assert length(issues) == 1
  end

  test "flags the two-step payload construction shape (WR-03)" do
    # The `inspect` lives in a prior `=` assignment, not inside the sink call.
    # The bare `payload` body variable passed to `send_json` is what the
    # mandated bare-variable body-arg rule catches — fragment-name broadening
    # alone cannot reach this intra-function two-step shape.
    source = """
    defmodule MailglassInbound.Ingress.LeakTwoStep do
      def run(conn, changeset) do
        payload = %{status: "error", detail: inspect(changeset)}
        send_json(conn, 500, payload)
      end
    end
    """

    issues = run_check(source, @in_scope)

    assert length(issues) == 1
  end

  test "does NOT flag the fixed static body (closed code)" do
    source = """
    defmodule MailglassInbound.Ingress.Safe do
      def run(conn) do
        send_json(conn, 500, %{status: "error", reason: "persist_failed"})
      end
    end
    """

    assert run_check(source, @in_scope) == []
  end

  test "does NOT flag the JSON helper's generic send_resp(status, body)" do
    source = """
    defmodule MailglassInbound.Ingress.SafeHelper do
      def send_json(conn, status, payload) do
        body = Jason.encode!(payload)
        send_resp(conn, status, body)
      end
    end
    """

    assert run_check(source, @in_scope) == []
  end

  test "ignores files outside the webhook/ingress path scope (path-gating)" do
    source = """
    defmodule Mailglass.Outbound.Foo do
      def run(conn, reason) do
        send_resp(conn, 500, inspect(reason))
      end
    end
    """

    assert run_check(source, "lib/mailglass/outbound/foo.ex") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoPiiInResponseBody.run([])
  end
end
