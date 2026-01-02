defmodule Cuetube.Library.Sync do
  @moduledoc """
  Service for synchronizing playlists with YouTube.
  """
  alias Cuetube.Repo
  alias Cuetube.Library.Playlist
  alias Cuetube.Library.PlaylistItem
  alias Ecto.Multi
  import Ecto.Query

  @doc """
  Synchronizes a playlist and its items from YouTube.
  """
  def sync_playlist(%Playlist{} = playlist) do
    with {:ok, details} <- Cuetube.YouTube.get_playlist_details(playlist.youtube_playlist_id),
         {:ok, items} <- Cuetube.YouTube.get_playlist_items(playlist.youtube_playlist_id) do
      Multi.new()
      |> Multi.update(
        :playlist,
        Playlist.changeset(playlist, %{
          title: details.title,
          description: details.description,
          thumbnail_url: details.thumbnail,
          video_count: details.video_count,
          last_synced_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
      )
      |> upsert_items(playlist, items)
      |> Repo.transaction()
      |> case do
        {:ok, %{playlist: updated_playlist}} ->
          Cuetube.Search.Indexer.rebuild_for_playlist(updated_playlist.id)
          {:ok, updated_playlist}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    end
  end

  defp upsert_items(multi, playlist, items) do
    # In a real app with 1000s of items, we'd use Repo.insert_all
    # For this scale, we can iterate or build a custom Multi step
    Multi.run(multi, :items, fn repo, _changes ->
      existing_items =
        repo.all(Ecto.assoc(playlist, :playlist_items))
        |> Map.new(fn item -> {item.youtube_video_id, item} end)

      # Handle deletions: delete items that exist locally but not in YouTube
      new_item_ids = MapSet.new(items, & &1.id)

      deleted_ids =
        existing_items
        |> Map.keys()
        |> MapSet.new()
        |> MapSet.difference(new_item_ids)

      repo.delete_all(
        from(pi in PlaylistItem,
          where:
            pi.youtube_video_id in ^MapSet.to_list(deleted_ids) and pi.playlist_id == ^playlist.id
        )
      )

      results =
        Enum.map(items, fn item_data ->
          params =
            item_data
            |> Map.put(:youtube_video_id, item_data.id)
            |> Map.put(:thumbnail_url, item_data.thumbnail)

          case Map.get(existing_items, item_data.id) do
            nil ->
              %PlaylistItem{playlist_id: playlist.id}
              |> PlaylistItem.changeset(params)
              |> repo.insert()

            existing ->
              existing
              |> PlaylistItem.changeset(params)
              |> repo.update()
          end
        end)

      case Enum.find(results, fn {status, _} -> status == :error end) do
        nil -> {:ok, :synced}
        {:error, changeset} -> {:error, changeset}
      end
    end)
  end
end
