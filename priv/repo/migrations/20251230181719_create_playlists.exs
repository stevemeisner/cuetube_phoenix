defmodule Cuetube.Repo.Migrations.CreatePlaylists do
  use Ecto.Migration

  def change do
    create table(:playlists) do
      add :youtube_playlist_id, :string
      add :title, :string
      add :description, :text
      add :slug, :string
      add :last_synced_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)

      add :created_at, :utc_datetime, default: fragment("now()")
    end

    create unique_index(:playlists, [:slug])
    create index(:playlists, [:user_id])
  end
end
