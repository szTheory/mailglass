# Components

`Mailglass.Components` gives you HEEx-native email building blocks with Outlook fallbacks and no Node toolchain.

## Prerequisites

- Phoenix.Component available in your app
- A mailable module using `Mailglass.Mailable`

## Build a template component

```elixir
defmodule MyApp.MailTemplates do
  use Phoenix.Component
  import Mailglass.Components

  def welcome(assigns) do
    ~H"""
    <.container>
      <.section>
        <.heading level={1}>Welcome</.heading>
        <.text>Hello <%= @name %>, your account is ready.</.text>
        <.button href="https://example.com/login">Sign in</.button>
      </.section>
    </.container>
    """
  end
end
```

## Render from a mailable

```elixir
defmodule MyApp.UserMailer do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    new()
    |> Mailglass.Message.update_swoosh(fn email ->
      email
      |> Swoosh.Email.to(user.email)
      |> Swoosh.Email.subject("Welcome")
      |> Swoosh.Email.html_body(Phoenix.Component.render_to_string(&MyApp.MailTemplates.welcome/1, name: user.name))
    end)
    |> Mailglass.Message.put_function(:welcome)
  end
end
```

## End-to-End Example

```elixir
message = MyApp.UserMailer.welcome(%{email: "carol@example.com", name: "Carol"})
{:ok, rendered} = Mailglass.Renderer.render(message)
is_binary(rendered.swoosh_email.html_body)
```
