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
    # 1. Update playlist search vector
    update_playlist_vector = """
    UPDATE playlists p
    SET search_vector = (
      SELECT
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
        )
      FROM users u
      WHERE u.id = p.user_id
    )
    WHERE p.id = $1
    """

    # 2. Update item search vectors
    update_items_vector = """
    UPDATE playlist_items
    SET search_vector = to_tsvector('simple',
      coalesce(title, '') || ' ' ||
      coalesce(notes, '') || ' ' ||
      coalesce(tags::text, '')
    )
    WHERE playlist_id = $1
    """

    Repo.transaction(fn ->
      Ecto.Adapters.SQL.query!(Repo, update_playlist_vector, [playlist_id])
      Ecto.Adapters.SQL.query!(Repo, update_items_vector, [playlist_id])
    end)

    :ok
  end
end
