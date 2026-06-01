defmodule MailglassDemoWeb.Mailers.AccountMailer do
  use Mailglass.Mailable, stream: :transactional

  alias Mailglass.Message

  def preview_props do
    [
      invite_admin: %{
        recipient: "mira.chen@northstar-ops.example",
        inviter: "Sam Rivera",
        workspace: "Northstar Ops",
        role: "Admin"
      },
      magic_link: %{
        recipient: "mira.chen@northstar-ops.example",
        workspace: "Northstar Ops",
        expires_in: "15 minutes"
      }
    ]
  end

  def invite_admin(assigns) do
    new()
    |> Message.from({"Northstar Ops", "notify@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("#{assigns.inviter} invited you to #{assigns.workspace}")
    |> Message.html_body("""
    <h1>Join #{assigns.workspace}</h1>
    <p>#{assigns.inviter} invited you as #{assigns.role}.</p>
    <p>Accept the invite to review delivery health, billing notices, and support replies.</p>
    """)
    |> Message.text_body(
      "#{assigns.inviter} invited you to #{assigns.workspace} as #{assigns.role}."
    )
    |> Message.put_function(:invite_admin)
  end

  def magic_link(assigns) do
    new()
    |> Message.from({"Northstar Ops", "security@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Your #{assigns.workspace} sign-in link")
    |> Message.html_body("""
    <h1>Sign in to #{assigns.workspace}</h1>
    <p>This link expires in #{assigns.expires_in}. If you did not request it, ignore this email.</p>
    """)
    |> Message.text_body(
      "Sign in to #{assigns.workspace}. This link expires in #{assigns.expires_in}."
    )
    |> Message.put_function(:magic_link)
  end
end
