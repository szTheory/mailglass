defmodule MailglassReferenceHost.Repo do
  use Ecto.Repo,
    otp_app: :mailglass_reference_host,
    adapter: Ecto.Adapters.Postgres
end
