defmodule Cuetube.Library.Sync do
  @moduledoc """
  Service for synchronizing playlists with YouTube.
  """
  alias Cuetube.Repo
  alias Cuetube.Library.Playlist
  alias Cuetube.Library.PlaylistItem
  alias Ecto.Multi

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

      results =
        Enum.map(items, fn item_data ->
          case Map.get(existing_items, item_data.id) do
            nil ->
              %PlaylistItem{playlist_id: playlist.id}
              |> PlaylistItem.changeset(Map.put(item_data, :youtube_video_id, item_data.id))
              |> repo.insert()

            existing ->
              existing
              |> PlaylistItem.changeset(item_data)
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
