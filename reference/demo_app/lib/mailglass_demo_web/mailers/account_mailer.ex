defmodule MailglassDemoWeb.Mailers.AccountMailer do
  use Mailglass.Mailable, stream: :transactional

  alias Mailglass.Message
  alias MailglassDemoWeb.Mailers.AtlasDeskEmail

  def preview_props do
    [
      invite_admin: %{
        recipient: AtlasDeskEmail.address("mira.chen"),
        inviter: "Sam Rivera",
        workspace: AtlasDeskEmail.brand(),
        role: "Admin"
      },
      magic_link: %{
        recipient: AtlasDeskEmail.address("mira.chen"),
        workspace: AtlasDeskEmail.brand(),
        expires_in: "15 minutes",
        requested_by: "Chrome on macOS",
        requested_at: "2026-06-01 14:48 UTC"
      }
    ]
  end

  def invite_admin(assigns) do
    new()
    |> Message.from({AtlasDeskEmail.brand(), "notify@atlasdesk.example"})
    |> Message.to(assigns.recipient)
    |> Message.subject("#{assigns.inviter} invited you to #{assigns.workspace}")
    |> Message.html_body(
      AtlasDeskEmail.html(%{
        eyebrow: "Workspace invite",
        preheader: "#{assigns.inviter} invited you to #{assigns.workspace}.",
        title: "Join #{assigns.workspace}",
        paragraphs: [
          "#{assigns.inviter} invited you as #{assigns.role}.",
          "Accept the invite to review team conversations, customer replies, billing notices, and delivery health from one workspace."
        ],
        metrics: [{"Role", assigns.role}, {"Invited by", assigns.inviter}],
        cta: {"Accept invite", "https://app.atlasdesk.example/invitations/team-invite"}
      })
    )
    |> Message.text_body(
      "#{assigns.inviter} invited you to #{assigns.workspace} as #{assigns.role}."
    )
    |> Message.put_function(:invite_admin)
  end

  def magic_link(assigns) do
    new()
    |> Message.from({AtlasDeskEmail.brand(), "security@atlasdesk.example"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Your #{assigns.workspace} sign-in link")
    |> Message.html_body(
      AtlasDeskEmail.html(%{
        eyebrow: "Secure sign-in",
        preheader: "Use this one-time link to sign in to #{assigns.workspace}.",
        title: "Sign in to #{assigns.workspace}",
        paragraphs: [
          "This link expires in #{assigns.expires_in}. If you did not request it, you can ignore this email.",
          "We include the request context so your team can recognize legitimate sign-ins."
        ],
        metrics: [
          {"Requested from", assigns.requested_by},
          {"Requested at", assigns.requested_at}
        ],
        cta: {"Sign in", "https://app.atlasdesk.example/login/magic"},
        note: "AtlasDesk will never ask for your password in email."
      })
    )
    |> Message.text_body(
      "Sign in to #{assigns.workspace}. This link expires in #{assigns.expires_in}. Request context: #{assigns.requested_by} at #{assigns.requested_at}."
    )
    |> Message.put_function(:magic_link)
  end
end
