defmodule MailglassAdmin.OperatorTrustDocTest do
  use ExUnit.Case, async: true

  @doc_path Path.expand("../../docs/operator-trust.md", __DIR__)

  test "canonical admin trust doc names the stable operator seams" do
    doc = File.read!(@doc_path)

    assert doc =~ "## Stable seams"
    assert doc =~ "MailglassAdmin.Router"
    assert doc =~ "MailglassAdmin.Auth.authorize/2"
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
    assert doc =~ "## Intentionally internal"
    assert doc =~ "LiveView modules"
    assert doc =~ "DOM/CSS shape"
  end
end
