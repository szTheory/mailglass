defmodule MailglassInbound.Internal.DoctorTest do
  @moduledoc """
  Unit tests for `MailglassInbound.Internal.Doctor` — the DNS-free pre-deploy
  config check runner behind `mix mailglass.inbound.doctor` (IOPS-01, MIME-03).

  Pure unit: NO DB, NO DNS. The router module is passed via an opt so the doctor
  reflects a fixture router (its `__mailglass_inbound_routes__/0`) instead of app
  config. Covers:

    1. Locked finding shape `%{check, status, title, observed, remediation, evidence}`
       and the summary tally `%{pass, warn, fail}`.
    2. Route-conflict via `Router.Matcher.matches_route?/2` reuse:
       structural subsumption (broad-before-narrow) -> :fail,
       witness-probe shadow -> :fail, regex-vs-regex -> :warn; conflict findings
       name `router.ex:LINE` via `Route.:source` (D-49-08).
    3. Missing router -> a cannot-diagnose marker (drives exit 2).
    4. Mailbox without `process/1` -> :fail; mailbox with it -> :pass.
    5. MIME backend reports name + version via `OptionalDeps.GenSmtp` (:pass when
       available, else :warn) — MIME-03, no bare optional-dep ref.
    6. Signing-key PRESENCE only (never verifies a signature).
  """

  use ExUnit.Case, async: true

  alias MailglassInbound.Internal.Doctor

  # ---- Fixture mailboxes ----------------------------------------------------

  defmodule GoodMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule BadMailbox do
    # Intentionally does NOT implement process/1 — exercises the behaviour check.
    def not_process(_message), do: :accept
  end

  # ---- Fixture routers ------------------------------------------------------

  defmodule CleanRouter do
    use MailglassInbound.Router
    route(MailglassInbound.Internal.DoctorTest.GoodMailbox, recipient: "support@example.com")
    route(MailglassInbound.Internal.DoctorTest.GoodMailbox, recipient: "billing@example.com")
  end

  defmodule SubsumptionRouter do
    # Catch-all (recipient: nil) BEFORE a specific string — the classic footgun.
    use MailglassInbound.Router
    route(MailglassInbound.Internal.DoctorTest.GoodMailbox, recipient: nil)
    route(MailglassInbound.Internal.DoctorTest.GoodMailbox, recipient: "specific@example.com")
  end

  defmodule WitnessShadowRouter do
    # An earlier broader subject-regex shadows a later exact-string route.
    use MailglassInbound.Router
    route(MailglassInbound.Internal.DoctorTest.GoodMailbox, recipient: ~r/.*@example\.com/)
    route(MailglassInbound.Internal.DoctorTest.GoodMailbox, recipient: "support@example.com")
  end

  defmodule RegexVsRegexRouter do
    use MailglassInbound.Router
    route(MailglassInbound.Internal.DoctorTest.GoodMailbox, recipient: ~r/support@.*/)
    route(MailglassInbound.Internal.DoctorTest.GoodMailbox, recipient: ~r/.*@example\.com/)
  end

  defmodule EmptyRouter do
    use MailglassInbound.Router
  end

  defmodule BadMailboxRouter do
    use MailglassInbound.Router
    route(MailglassInbound.Internal.DoctorTest.BadMailbox, recipient: "support@example.com")
  end

  # ---- Finding shape + summary ----------------------------------------------

  describe "run/1 result shape" do
    test "returns %{summary: %{pass, warn, fail}, findings: [...]} with the locked finding shape" do
      result = Doctor.run(router: CleanRouter)

      assert %{summary: %{pass: pass, warn: warn, fail: fail}, findings: findings} = result
      assert is_integer(pass) and is_integer(warn) and is_integer(fail)
      assert is_list(findings) and findings != []

      for finding <- findings do
        assert %{check: check, status: status, title: title} = finding
        assert is_atom(check)
        assert status in [:pass, :warn, :fail]
        assert is_binary(title)
        assert Map.has_key?(finding, :observed)
        assert Map.has_key?(finding, :remediation)
        # D-49-05: NO :why_it_matters, NO :area on inbound findings.
        refute Map.has_key?(finding, :why_it_matters)
        refute Map.has_key?(finding, :area)
      end
    end

    test "a clean router has no fail findings and a cannot-diagnose count of 0" do
      result = Doctor.run(router: CleanRouter)
      assert result.summary.fail == 0
      refute Map.get(result.summary, :cannot_diagnose, 0) > 0
    end
  end

  # ---- Route-conflict detection ---------------------------------------------

  describe "run/1 route-conflict detection (REUSES Router.Matcher)" do
    test "structural subsumption (broad-before-narrow) is a :fail naming router.ex:LINE" do
      result = Doctor.run(router: SubsumptionRouter)

      conflict = find_conflict_fail(result)
      assert conflict, "expected a conflict :fail finding for broad-before-narrow"
      assert conflict.status == :fail
      assert conflict.observed =~ "doctor_test.exs:" or conflict.observed =~ ".ex:",
             "conflict finding must name the source file:line (Route.:source, D-49-08)"
    end

    test "witness-probe shadow (earlier broader matches a later exact route) is a :fail" do
      result = Doctor.run(router: WitnessShadowRouter)
      conflict = find_conflict_fail(result)
      assert conflict, "expected a conflict :fail for a witness-probe shadow"
      assert conflict.status == :fail
    end

    test "regex-vs-regex overlap is a :warn, never a :fail" do
      result = Doctor.run(router: RegexVsRegexRouter)
      conflict_findings = Enum.filter(result.findings, &(&1.check == :route_conflict))

      assert conflict_findings != []
      assert Enum.all?(conflict_findings, &(&1.status == :warn))
      refute Enum.any?(conflict_findings, &(&1.status == :fail))
    end

    test "a clean router produces no conflict :fail/:warn" do
      result = Doctor.run(router: CleanRouter)
      conflict_findings = Enum.filter(result.findings, &(&1.check == :route_conflict))
      refute Enum.any?(conflict_findings, &(&1.status in [:fail, :warn]))
    end
  end

  # ---- Cannot-diagnose / router checks --------------------------------------

  describe "run/1 router checks" do
    test "a missing router yields a cannot-diagnose marker (drives exit 2)" do
      result = Doctor.run(router: nil)
      assert result.summary[:cannot_diagnose] && result.summary.cannot_diagnose > 0
    end

    test "a router with zero routes is a :fail (>= 1 route required)" do
      result = Doctor.run(router: EmptyRouter)
      route_findings = Enum.filter(result.findings, &(&1.check == :routes_defined))
      assert Enum.any?(route_findings, &(&1.status == :fail))
    end
  end

  # ---- Mailbox behaviour check ----------------------------------------------

  describe "run/1 mailbox checks" do
    test "a mailbox implementing process/1 is a :pass" do
      result = Doctor.run(router: CleanRouter)
      mailbox_findings = Enum.filter(result.findings, &(&1.check == :mailbox))
      assert mailbox_findings != []
      assert Enum.all?(mailbox_findings, &(&1.status == :pass))
    end

    test "a mailbox without process/1 is a :fail" do
      result = Doctor.run(router: BadMailboxRouter)
      mailbox_findings = Enum.filter(result.findings, &(&1.check == :mailbox))
      assert Enum.any?(mailbox_findings, &(&1.status == :fail))
    end
  end

  # ---- MIME backend report (MIME-03) ----------------------------------------

  describe "run/1 MIME backend report (MIME-03)" do
    test "reports the backend name and is :pass when gen_smtp is available, else :warn" do
      result = Doctor.run(router: CleanRouter)
      mime = Enum.find(result.findings, &(&1.check == :mime_backend))

      assert mime, "expected a :mime_backend finding"
      assert mime.observed =~ "gen_smtp"

      if Mailglass.OptionalDeps.GenSmtp.available?() do
        assert mime.status == :pass
        # version is reported when available
        assert mime.observed =~ ~r/\d+\.\d+/
      else
        assert mime.status == :warn
      end
    end
  end

  # ---- Signing-key presence (never verifies) --------------------------------

  describe "run/1 signing-key check" do
    test "reports key PRESENCE only and the finding text says so (never verifies)" do
      result = Doctor.run(router: CleanRouter)
      signing = Enum.find(result.findings, &(&1.check == :signing_keys))

      assert signing, "expected a :signing_keys finding"
      # Honest-surface: the text must make clear it only checks presence.
      assert signing.observed =~ "present" or signing.remediation =~ "present" or
               signing.title =~ "present" or signing.observed =~ "configured"
    end
  end

  # ---- helpers --------------------------------------------------------------

  defp find_conflict_fail(result) do
    result.findings
    |> Enum.filter(&(&1.check == :route_conflict and &1.status == :fail))
    |> List.first()
  end
end
