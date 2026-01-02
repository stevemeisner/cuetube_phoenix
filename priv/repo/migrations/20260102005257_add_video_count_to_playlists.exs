defmodule Cuetube.Repo.Migrations.AddVideoCountToPlaylists do
  use Ecto.Migration

  def change do
    alter table(:playlists) do
      add_if_not_exists :video_count, :integer
    end
  end
end
