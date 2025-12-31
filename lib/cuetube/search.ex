defmodule Cuetube.Search do
  @moduledoc """
  The Search context for full-text and fuzzy search.
  """
  alias Cuetube.Repo
  import Ecto.Query

  @doc """
  Performs a ranked full-text search across playlists.
  """
  def search_playlists(raw_query, limit \\ 20) do
    %{text: text, hashtags: hashtags, handle: handle} = parse_query(raw_query)
    search_text = Enum.join([text | hashtags], " ") |> String.trim()

    if search_text == "" and is_nil(handle) do
      []
    else
      prefix_q = build_prefix_ts_query(search_text)

      matches =
        cond do
          search_text != "" and prefix_q ->
            dynamic(
              [ps],
              fragment(
                "? @@ websearch_to_tsquery('simple', ?) OR ? @@ to_tsquery('simple', ?)",
                ps.search_vector,
                ^search_text,
                ps.search_vector,
                ^prefix_q
              )
            )

          search_text != "" ->
            dynamic(
              [ps],
              fragment("? @@ websearch_to_tsquery('simple', ?)", ps.search_vector, ^search_text)
            )

          true ->
            dynamic(true)
        end

      rank =
        cond do
          search_text != "" and prefix_q ->
            dynamic(
              [ps],
              fragment(
                "greatest(ts_rank_cd(?, websearch_to_tsquery('simple', ?)), ts_rank_cd(?, to_tsquery('simple', ?)) * 0.9)",
                ps.search_vector,
                ^search_text,
                ps.search_vector,
                ^prefix_q
              )
            )

          search_text != "" ->
            dynamic(
              [ps],
              fragment(
                "ts_rank_cd(?, websearch_to_tsquery('simple', ?))",
                ps.search_vector,
                ^search_text
              )
            )

          true ->
            dynamic(1.0)
        end

      order_by = [desc: rank, desc: dynamic([ps, p], p.created_at)]

      query =
        from(ps in Cuetube.Library.PlaylistSearch,
          join: p in assoc(ps, :playlist),
          left_join: u in assoc(p, :user),
          where: ^matches,
          order_by: ^order_by,
          limit: ^limit,
          select: %{
            playlist_id: p.id,
            playlist_slug: p.slug,
            playlist_title: p.title,
            playlist_description: p.description,
            playlist_inserted_at: p.created_at,
            curator_handle: u.handle,
            curator_display_name: u.display_name,
            curator_avatar_url: u.avatar_url
          }
        )

      query =
        if handle do
          where(query, [ps, p, u], ilike(u.handle, ^handle))
        else
          query
        end

      Repo.all(query)
    end
  end

  @doc """
  Gets autocomplete suggestions across Playlists, Videos, Curators, and Tags.
  """
  def get_suggestions(raw_query) do
    %{text: text} = parse_query(raw_query)
    tag_prefix = get_hashtag_prefix(raw_query)

    # In a real app, we'd use Task.async_stream or similar for parallel queries
    # For now, we'll implement the logic for each type of suggestion.

    # 1. Playlist suggestions (FTS + Trigram)
    playlists = get_playlist_suggestions(text)

    # 2. Video suggestions (FTS on items)
    videos = get_video_suggestions(text)

    # 3. Curator suggestions (ILIKE)
    curators = get_curator_suggestions(text)

    # 4. Tag suggestions (JSONB extraction)
    tags = get_tag_suggestions(tag_prefix)

    (playlists ++ videos ++ curators ++ tags)
    |> Enum.uniq_by(fn
      %{type: :playlist, slug: slug} -> {:playlist, slug}
      %{type: :video, video_id: id} -> {:video, id}
      %{type: :curator, handle: handle} -> {:curator, handle}
      %{type: :tag, tag: tag} -> {:tag, tag}
      _other -> nil
    end)
    |> Enum.take(12)
  end

  defp get_playlist_suggestions(""), do: []

  defp get_playlist_suggestions(text) do
    prefix_q = build_prefix_ts_query(text)

    fts_results =
      if prefix_q do
        from(ps in Cuetube.Library.PlaylistSearch,
          join: p in assoc(ps, :playlist),
          left_join: u in assoc(p, :user),
          where:
            fragment(
              "? @@ websearch_to_tsquery('simple', ?) OR ? @@ to_tsquery('simple', ?)",
              ps.search_vector,
              ^text,
              ps.search_vector,
              ^prefix_q
            ),
          limit: 6,
          select: %{
            type: :playlist,
            slug: p.slug,
            title: p.title,
            curator_display_name: u.display_name
          }
        )
        |> Repo.all()
      else
        from(ps in Cuetube.Library.PlaylistSearch,
          join: p in assoc(ps, :playlist),
          left_join: u2 in assoc(p, :user),
          where: fragment("? @@ websearch_to_tsquery('simple', ?)", ps.search_vector, ^text),
          limit: 6,
          select: %{
            type: :playlist,
            slug: p.slug,
            title: p.title,
            curator_display_name: u2.display_name
          }
        )
        |> Repo.all()
      end

    trgm_results =
      if String.length(text) >= 3 do
        from(p in Cuetube.Library.Playlist,
          left_join: u in assoc(p, :user),
          where: fragment("? % ?::text", p.title, ^text),
          order_by: fragment("similarity(?, ?::text) DESC", p.title, ^text),
          limit: 6,
          select: %{
            type: :playlist,
            slug: p.slug,
            title: p.title,
            curator_display_name: u.display_name
          }
        )
        |> Repo.all()
      else
        []
      end

    fts_results ++ trgm_results
  end

  defp get_video_suggestions(""), do: []

  defp get_video_suggestions(text) do
    prefix_q = build_prefix_ts_query(text)

    if prefix_q do
      from(pi in Cuetube.Library.PlaylistItem,
        join: p in assoc(pi, :playlist),
        where:
          fragment(
            "(to_tsvector('simple', coalesce(?, '') || ' ' || coalesce(?, '') || ' ' || coalesce(?::text, '')) @@ websearch_to_tsquery('simple', ?))
                          OR (to_tsvector('simple', coalesce(?, '') || ' ' || coalesce(?, '') || ' ' || coalesce(?::text, '')) @@ to_tsquery('simple', ?))",
            pi.title,
            pi.notes,
            pi.tags,
            ^text,
            pi.title,
            pi.notes,
            pi.tags,
            ^prefix_q
          ),
        limit: 6,
        select: %{
          type: :video,
          playlist_slug: p.slug,
          video_id: pi.youtube_video_id,
          title: pi.title
        }
      )
      |> Repo.all()
    else
      from(pi in Cuetube.Library.PlaylistItem,
        join: p in assoc(pi, :playlist),
        where:
          fragment(
            "to_tsvector('simple', coalesce(?, '') || ' ' || coalesce(?, '') || ' ' || coalesce(?::text, '')) @@ websearch_to_tsquery('simple', ?)",
            pi.title,
            pi.notes,
            pi.tags,
            ^text
          ),
        limit: 6,
        select: %{
          type: :video,
          playlist_slug: p.slug,
          video_id: pi.youtube_video_id,
          title: pi.title
        }
      )
      |> Repo.all()
    end
  end

  defp get_curator_suggestions(""), do: []

  defp get_curator_suggestions(text) do
    like_pattern = "%#{escape_like(text)}%"

    from(u in Cuetube.Accounts.User,
      where: ilike(u.handle, ^like_pattern) or ilike(u.display_name, ^like_pattern),
      limit: 5,
      select: %{
        type: :curator,
        handle: u.handle,
        display_name: u.display_name
      }
    )
    |> Repo.all()
  end

  defp get_tag_suggestions(nil), do: []

  defp get_tag_suggestions(prefix) do
    like_pattern = "#{escape_like(prefix)}%"

    query = """
    SELECT DISTINCT t.tag
    FROM playlist_items pi
    CROSS JOIN LATERAL jsonb_array_elements_text(coalesce(pi.tags, '[]'::jsonb)) as t(tag)
    WHERE t.tag ILIKE $1
    ORDER BY t.tag ASC
    LIMIT 8
    """

    case Repo.query(query, [like_pattern]) do
      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [tag] -> %{type: :tag, tag: tag} end)

      _ ->
        []
    end
  end

  def parse_query(raw) do
    normalized = normalize_query(raw)

    if normalized == "" do
      %{text: "", hashtags: [], handle: nil}
    else
      hashtags =
        Regex.scan(~r/(?:^|\s)#([a-zA-Z0-9_]{1,64})/, normalized)
        |> Enum.map(fn [_, tag] -> String.downcase(tag) end)
        |> Enum.uniq()

      handle =
        case Regex.run(~r/(?:^|\s)@([a-zA-Z0-9_]{1,64})/, normalized) do
          [_, h] -> String.downcase(h)
          _ -> nil
        end

      text =
        normalized
        |> String.replace(~r/(?:^|\s)#([a-zA-Z0-9_]{1,64})/, "")
        |> String.replace(~r/(?:^|\s)@([a-zA-Z0-9_]{1,64})/, "")
        |> normalize_query()

      %{text: text, hashtags: hashtags, handle: handle}
    end
  end

  def get_hashtag_prefix(raw) do
    if String.ends_with?(raw, " ") do
      nil
    else
      normalized = normalize_query(raw)

      case Regex.run(~r/(?:^|\s)#([a-zA-Z0-9_]{1,64})$/, normalized) do
        [_, tag] -> String.downcase(tag)
        _ -> nil
      end
    end
  end

  def build_prefix_ts_query(raw) do
    normalized = normalize_query(raw) |> String.downcase()

    if normalized == "" do
      nil
    else
      tokens =
        normalized
        |> String.split(" ")
        |> Enum.map(fn t -> String.replace(t, ~r/[^a-z0-9_]+/, "") end)
        |> Enum.reject(&(&1 == ""))

      if tokens == [] do
        nil
      else
        Enum.map(tokens, &"#{&1}:*") |> Enum.join(" & ")
      end
    end
  end

  def normalize_query(nil), do: ""

  def normalize_query(raw) do
    raw
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  defp escape_like(q) do
    q
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end
end
