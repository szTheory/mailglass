defmodule MailglassAdmin.OperatorTrustDocTest do
  use ExUnit.Case, async: true

  @doc_path Path.expand("../../docs/operator-trust.md", __DIR__)

  test "canonical admin trust doc names the stable operator seams" do
    doc = File.read!(@doc_path)

    assert doc =~ "## Stable seams"
    assert doc =~ "MailglassAdmin.Router"
    assert doc =~ "MailglassAdmin.Auth"
    assert doc =~ "`authorize/2` callback"
    assert doc =~ "subject_id"
    assert doc =~ "tenant_id"
    assert doc =~ "auth_method"
    assert doc =~ "recent_auth_at"
    assert doc =~ ":operator_access"
    assert doc =~ ":destructive_action"
  end

  test "canonical admin trust doc describes replay outcomes and internal boundaries" do
    doc = File.read!(@doc_path)

    assert doc =~ "## Replay semantics"
    assert doc =~ "new work"
    assert doc =~ "no change"
    assert doc =~ "newly normalized Event rows"
    assert doc =~ "persisted evidence is labeled unavailable"
    [outbound, inbound] = String.split(doc, "### Inbound mailbox recovery", parts: 2)
    assert outbound =~ "synchronously through the local command"
    refute outbound =~ "Task.Supervisor"
    refute outbound =~ "no_prior_match"
    assert inbound =~ "Task.Supervisor"
    assert inbound =~ "no_prior_match"
    assert doc =~ "## Intentionally internal"
    assert doc =~ "LiveView modules"
    assert doc =~ "DOM/CSS shape"
  end
end
