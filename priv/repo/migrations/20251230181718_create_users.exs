defmodule Cuetube.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :google_id, :string
      add :display_name, :string
      add :handle, :string
      add :avatar_url, :string

      add :created_at, :utc_datetime, default: fragment("now()")
    end

    create unique_index(:users, [:handle])
    create unique_index(:users, [:google_id])
    create unique_index(:users, [:email])
  end
end
