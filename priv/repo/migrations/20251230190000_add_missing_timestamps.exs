defmodule Cuetube.Repo.Migrations.AddMissingTimestamps do
  use Ecto.Migration

  def change do
    alter table(:playlists) do
      add_if_not_exists :created_at, :utc_datetime, default: fragment("now()")
    end

    alter table(:users) do
      add_if_not_exists :created_at, :utc_datetime, default: fragment("now()")
    end
  end
end
