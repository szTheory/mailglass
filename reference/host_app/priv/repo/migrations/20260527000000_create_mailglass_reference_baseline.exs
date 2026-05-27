defmodule MailglassReferenceHost.Repo.Migrations.CreateMailglassReferenceBaseline do
  use Ecto.Migration

  def change do
    create table(:mailglass_reference_baseline) do
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end
  end
end
