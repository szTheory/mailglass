defmodule MailglassAdmin.TestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :mailglass,
    adapter: Ecto.Adapters.Postgres
end
