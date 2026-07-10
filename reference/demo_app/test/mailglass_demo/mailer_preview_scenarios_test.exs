defmodule MailglassDemo.MailerPreviewScenariosTest do
  use ExUnit.Case, async: true

  alias MailglassDemoWeb.Mailers.AccountMailer
  alias MailglassDemoWeb.Mailers.BillingMailer
  alias MailglassDemoWeb.Mailers.OperationsMailer

  describe "account preview scenarios" do
    test "preview_props keeps deterministic order and values" do
      props = AccountMailer.preview_props()

      assert Keyword.keys(props) == [:invite_admin, :magic_link]

      assert props[:magic_link].requested_by == "Chrome on macOS"
      assert props[:magic_link].requested_at == "2026-06-01 14:48 UTC"
    end

    test "invite_admin builds expected public message fields" do
      message = AccountMailer.invite_admin(AccountMailer.preview_props()[:invite_admin])

      assert message.mailable_function == :invite_admin
      assert message.swoosh_email.from == {"AtlasDesk", "notify@atlasdesk.example"}
      assert message.swoosh_email.subject == "Sam Rivera invited you to AtlasDesk"
      assert_real_atlasdesk_email(message)
      assert message.swoosh_email.html_body =~ "Workspace invite"
      assert message.swoosh_email.text_body =~ "Sam Rivera"
    end

    test "magic_link builds expected public message fields" do
      message = AccountMailer.magic_link(AccountMailer.preview_props()[:magic_link])

      assert message.mailable_function == :magic_link
      assert message.swoosh_email.from == {"AtlasDesk", "security@atlasdesk.example"}
      assert message.swoosh_email.subject == "Your AtlasDesk sign-in link"
      assert_real_atlasdesk_email(message)
      assert message.swoosh_email.html_body =~ "Chrome on macOS"
      assert message.swoosh_email.html_body =~ "2026-06-01 14:48 UTC"
      assert message.swoosh_email.text_body =~ "Chrome on macOS"
      assert message.swoosh_email.text_body =~ "2026-06-01 14:48 UTC"
    end
  end

  describe "billing preview scenarios" do
    test "preview_props keeps deterministic order and values" do
      props = BillingMailer.preview_props()

      assert Keyword.keys(props) == [:receipt_paid, :payment_failed]

      assert props[:receipt_paid].billing_period == "May 2026"
      assert props[:receipt_paid].plan == "Scale"
      assert props[:payment_failed].amount_due == "$248.00"
      assert props[:payment_failed].card_last4 == "4242"
      assert props[:payment_failed].retry_at == "2026-06-02 09:00 ET"
    end

    test "receipt_paid builds expected public message fields" do
      message = BillingMailer.receipt_paid(BillingMailer.preview_props()[:receipt_paid])

      assert message.mailable_function == :receipt_paid
      assert message.swoosh_email.from == {"AtlasDesk Billing", "billing@atlasdesk.example"}
      assert message.swoosh_email.subject == "Receipt INV-2026-0601 for AtlasDesk"
      assert_real_atlasdesk_email(message)
      assert message.swoosh_email.html_body =~ "May 2026"
      assert message.swoosh_email.html_body =~ "Scale"
      assert message.swoosh_email.text_body =~ "May 2026"
      assert message.swoosh_email.text_body =~ "Scale"
    end

    test "payment_failed builds expected public message fields" do
      message = BillingMailer.payment_failed(BillingMailer.preview_props()[:payment_failed])

      assert message.mailable_function == :payment_failed
      assert message.swoosh_email.from == {"AtlasDesk Billing", "billing@atlasdesk.example"}
      assert message.swoosh_email.subject == "Payment action needed for AtlasDesk"
      assert_real_atlasdesk_email(message)
      assert message.swoosh_email.html_body =~ "$248.00"
      assert message.swoosh_email.html_body =~ "4242"
      assert message.swoosh_email.text_body =~ "$248.00"
      assert message.swoosh_email.text_body =~ "4242"
    end
  end

  describe "operations preview scenarios" do
    test "preview_props keeps deterministic order and values" do
      props = OperationsMailer.preview_props()

      assert Keyword.keys(props) == [:usage_alert, :incident_update]

      assert props[:usage_alert].projected_overage == "$38.00"
      assert props[:incident_update].impacted_feature == "Inbound routing trace"
      assert props[:incident_update].next_update == "15 minutes"
    end

    test "usage_alert builds expected public message fields" do
      message = OperationsMailer.usage_alert(OperationsMailer.preview_props()[:usage_alert])

      assert message.mailable_function == :usage_alert
      assert message.swoosh_email.from == {"AtlasDesk", "ops@atlasdesk.example"}
      assert message.swoosh_email.subject == "AtlasDesk email usage reached 85%"
      assert_real_atlasdesk_email(message)
      assert message.swoosh_email.html_body =~ "Usage threshold reached"
      assert message.swoosh_email.html_body =~ "$38.00"
      refute message.swoosh_email.html_body =~ "Usage threshold reachedAtlasDesk"
      assert message.swoosh_email.text_body =~ "$38.00"
      assert message.swoosh_email.text_body =~ "AtlasDesk used 85%"
    end

    test "incident_update builds expected public message fields" do
      message = OperationsMailer.incident_update(OperationsMailer.preview_props()[:incident_update])

      assert message.mailable_function == :incident_update
      assert message.swoosh_email.from == {"AtlasDesk Status", "status@atlasdesk.example"}
      assert message.swoosh_email.subject == "INC-4421 is monitoring"
      assert_real_atlasdesk_email(message)
      assert message.swoosh_email.html_body =~ "Inbound routing trace"
      assert message.swoosh_email.html_body =~ "15 minutes"
      assert message.swoosh_email.text_body =~ "Inbound routing trace"
      assert message.swoosh_email.text_body =~ "15 minutes"
    end
  end

  defp assert_real_atlasdesk_email(message) do
    html = message.swoosh_email.html_body

    assert html =~ ~s(data-brand="AtlasDesk")
    refute html =~ "data-demo-brand"
    refute html =~ "Mailglass"
    refute html =~ "demo"
    refute html =~ "fictional"
    refute html =~ "seeded"
    refute html =~ "replay evidence"
  end
end
