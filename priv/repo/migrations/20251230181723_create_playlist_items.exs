defmodule Cuetube.Repo.Migrations.CreatePlaylistItems do
  use Ecto.Migration

  def change do
    create table(:playlist_items) do
      add :youtube_video_id, :string
      add :title, :string
      add :position, :integer
      add :notes, :text
      add :tags, :map
      add :timestamp_start, :integer
      add :timestamp_end, :integer
      add :playlist_id, references(:playlists, on_delete: :nothing)
    end

    create index(:playlist_items, [:playlist_id])
  end
end
