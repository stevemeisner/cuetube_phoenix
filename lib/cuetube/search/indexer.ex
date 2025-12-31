defmodule Cuetube.Search.Indexer do
  @moduledoc """
  Handles rebuilding the full-text search index for playlists.
  """
  alias Cuetube.Repo

  @weights %{
    playlist_title: "A",
    tags: "A",
    video_titles: "B",
    curator: "C",
    notes: "C",
    playlist_description: "D"
  }

  @doc """
  Rebuilds the search document for a specific playlist.
  """
  def rebuild_for_playlist(playlist_id) do
    # Using raw SQL fragment for the complex weighted tsvector generation
    # mirroring the highly optimized SQL from the original project.

    query = """
    INSERT INTO playlist_search (playlist_id, search_vector, updated_at)
    SELECT
      p.id as playlist_id,
      (
        setweight(to_tsvector('simple', coalesce(p.title, '')), '#{@weights.playlist_title}') ||
        setweight(to_tsvector('simple', coalesce(
          (SELECT string_agg(distinct t.tag, ' ')
           FROM playlist_items pi
           CROSS JOIN LATERAL jsonb_array_elements_text(coalesce(pi.tags, '[]'::jsonb)) as t(tag)
           WHERE pi.playlist_id = p.id),
        '')), '#{@weights.tags}') ||
        setweight(to_tsvector('simple', coalesce(
          (SELECT string_agg(coalesce(pi.title, ''), ' ')
           FROM playlist_items pi
           WHERE pi.playlist_id = p.id),
        '')), '#{@weights.video_titles}') ||
        setweight(to_tsvector('simple', coalesce(u.display_name, '') || ' ' || coalesce(u.handle, '')), '#{@weights.curator}') ||
        setweight(to_tsvector('simple', coalesce(
          (SELECT string_agg(coalesce(pi.notes, ''), ' ')
           FROM playlist_items pi
           WHERE pi.playlist_id = p.id),
        '')), '#{@weights.notes}') ||
        setweight(to_tsvector('simple', coalesce(p.description, '')), '#{@weights.playlist_description}')
      ) as search_vector,
      now() as updated_at
    FROM playlists p
    LEFT JOIN users u ON u.id = p.user_id
    WHERE p.id = $1
    ON CONFLICT (playlist_id)
    DO UPDATE SET
      search_vector = EXCLUDED.search_vector,
      updated_at = EXCLUDED.updated_at
    """

    Ecto.Adapters.SQL.query!(Repo, query, [playlist_id])
    :ok
  end
end
