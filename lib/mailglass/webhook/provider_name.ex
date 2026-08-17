defmodule Mailglass.Webhook.ProviderName do
  @moduledoc false

  @type provider :: :postmark | :sendgrid | :mailgun | :ses | :resend

  @spec decode(term()) :: {:ok, provider()} | :error
  def decode("postmark"), do: {:ok, :postmark}
  def decode("sendgrid"), do: {:ok, :sendgrid}
  def decode("mailgun"), do: {:ok, :mailgun}
  def decode("ses"), do: {:ok, :ses}
  def decode("resend"), do: {:ok, :resend}
  def decode(_provider), do: :error

  @spec encode(provider()) :: {:ok, String.t()} | :error
  def encode(:postmark), do: {:ok, "postmark"}
  def encode(:sendgrid), do: {:ok, "sendgrid"}
  def encode(:mailgun), do: {:ok, "mailgun"}
  def encode(:ses), do: {:ok, "ses"}
  def encode(:resend), do: {:ok, "resend"}
  def encode(_provider), do: :error
end
