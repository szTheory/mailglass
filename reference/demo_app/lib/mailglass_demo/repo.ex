defmodule MailglassDemo.Repo do
  use Ecto.Repo,
    otp_app: :mailglass_demo,
    adapter: Ecto.Adapters.Postgres
end
