defmodule Cuetube.Repo.Migrations.CreatePlaylistSearch do
  use Ecto.Migration

  def up do
    create table(:playlist_search, primary_key: false) do
      add :playlist_id, references(:playlists, on_delete: :delete_all), primary_key: true
      add :search_vector, :tsvector, null: false
      add :updated_at, :utc_datetime, null: false, default: fragment("now()")
    end

    create index(:playlist_search, [:search_vector],
             name: :playlist_search_vector_gin,
             using: :gin
           )

    # Trigram indexes for fast autocomplete on titles and handles
    execute "CREATE INDEX playlists_title_trgm_idx ON playlists USING gin (title gin_trgm_ops)"

    execute "CREATE INDEX users_display_name_trgm_idx ON users USING gin (display_name gin_trgm_ops)"

    execute "CREATE INDEX users_handle_trgm_idx ON users USING gin (handle gin_trgm_ops)"

    # Index for individual item searching (videos)
    execute """
    CREATE INDEX playlist_items_search_vector_gin ON playlist_items USING gin (
      to_tsvector('simple',
        coalesce(title, '') || ' ' ||
        coalesce(notes, '') || ' ' ||
        coalesce(tags::text, '')
      )
    )
    """
  end

  def down do
    execute "DROP INDEX playlist_items_search_vector_gin"
    execute "DROP INDEX users_handle_trgm_idx"
    execute "DROP INDEX users_display_name_trgm_idx"
    execute "DROP INDEX playlists_title_trgm_idx"
    drop table(:playlist_search)
  end
end
