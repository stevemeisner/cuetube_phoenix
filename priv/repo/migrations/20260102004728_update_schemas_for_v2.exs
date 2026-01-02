defmodule Cuetube.Repo.Migrations.UpdateSchemasForV2 do
  use Ecto.Migration

  def up do
    # 1. Add columns to playlists
    alter table(:playlists) do
      add_if_not_exists :thumbnail_url, :string
      add_if_not_exists :video_count, :integer
      add_if_not_exists :search_vector, :tsvector
    end

    # 2. Add columns to playlist_items
    alter table(:playlist_items) do
      add_if_not_exists :thumbnail_url, :string
      add_if_not_exists :search_vector, :tsvector
    end

    # 3. Create GIN indexes (if they don't exist)
    # Ecto doesn't have create_index_if_not_exists but we can use execute
    execute "CREATE INDEX IF NOT EXISTS playlists_search_vector_idx ON playlists USING gin (search_vector)"

    execute "CREATE INDEX IF NOT EXISTS playlist_items_search_vector_idx ON playlist_items USING gin (search_vector)"

    # 4. Drop the old expression index on playlist_items if it exists
    execute "DROP INDEX IF EXISTS playlist_items_search_vector_gin"

    # 5. Migrate data from playlist_search to playlists.search_vector
    # We check if playlist_search exists before migrating
    execute """
    DO $$
    BEGIN
      IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'playlist_search') THEN
        UPDATE playlists p
        SET search_vector = ps.search_vector
        FROM playlist_search ps
        WHERE ps.playlist_id = p.id;
      END IF;
    END $$;
    """

    # 6. Drop the old search table
    execute "DROP TABLE IF EXISTS playlist_search"
  end

  def down do
    # Down migration is harder with if_not_exists but we can try
    # For now let's just make it simple
    alter table(:playlists) do
      remove :thumbnail_url
      remove :search_vector
    end

    alter table(:playlist_items) do
      remove :thumbnail_url
      remove :search_vector
    end
  end
end
