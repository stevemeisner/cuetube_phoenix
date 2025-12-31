defmodule Cuetube.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false
  alias Cuetube.Repo

  alias Cuetube.Library.{Playlist, PlaylistItem}

  @doc """
  Returns the list of playlists.

  ## Examples

      iex> list_playlists()
      [%Playlist{}, ...]

  """
  def list_playlists do
    Repo.all(Playlist)
  end

  @doc """
  Gets a single playlist.

  Raises `Ecto.NoResultsError` if the Playlist does not exist.

  ## Examples

      iex> get_playlist!(123)
      %Playlist{}

      iex> get_playlist!(456)
      ** (Ecto.NoResultsError)

  """
  def get_playlist!(id), do: Repo.get!(Playlist, id)

  @doc """
  Gets a playlist by slug with curator info.
  """
  def get_playlist_by_slug!(slug) do
    Playlist
    |> Repo.get_by!(slug: slug)
    |> Repo.preload(:user)
  end

  @doc """
  Lists all items for a playlist ordered by position.
  """
  def list_playlist_items(playlist_id) do
    PlaylistItem
    |> where(playlist_id: ^playlist_id)
    |> order_by(asc: :position)
    |> Repo.all()
  end

  @doc """
  Lists playlists for a specific user.
  """
  def list_user_playlists(user_id) do
    Playlist
    |> where(user_id: ^user_id)
    |> order_by(desc: :created_at)
    |> Repo.all()
  end

  @doc """
  Lists the latest N playlists with curator info.
  """
  def list_latest_playlists(limit \\ 6) do
    Playlist
    |> order_by([p], desc: p.created_at)
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Creates a playlist.

  ## Examples

      iex> create_playlist(%{field: value})
      {:ok, %Playlist{}}

      iex> create_playlist(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_playlist(attrs) do
    %Playlist{}
    |> Playlist.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a playlist.

  ## Examples

      iex> update_playlist(playlist, %{field: new_value})
      {:ok, %Playlist{}}

      iex> update_playlist(playlist, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_playlist(%Playlist{} = playlist, attrs) do
    playlist
    |> Playlist.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a playlist.

  ## Examples

      iex> delete_playlist(playlist)
      {:ok, %Playlist{}}

      iex> delete_playlist(playlist)
      {:error, %Ecto.Changeset{}}

  """
  def delete_playlist(%Playlist{} = playlist) do
    Repo.delete(playlist)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking playlist changes.

  ## Examples

      iex> change_playlist(playlist)
      %Ecto.Changeset{data: %Playlist{}}

  """
  def change_playlist(%Playlist{} = playlist, attrs \\ %{}) do
    Playlist.changeset(playlist, attrs)
  end

  alias Cuetube.YouTube
  alias Cuetube.Search.Indexer
  alias Ecto.Multi

  @doc """
  Imports a playlist from YouTube.
  """
  def import_playlist_from_youtube(user_id, youtube_id) do
    with {:ok, details} <- YouTube.get_playlist_details(youtube_id),
         {:ok, items} <- YouTube.get_playlist_items(youtube_id) do
      base_slug =
        (details.title || "playlist")
        |> String.downcase()
        |> String.replace(~r/[^a-z0-9]+/i, "-")
        |> String.trim("-")

      slug = "#{base_slug}-#{:rand.uniform(10000)}"

      Multi.new()
      |> Multi.insert(:playlist, %Playlist{
        user_id: user_id,
        youtube_playlist_id: youtube_id,
        title: details.title || "Untitled Playlist",
        description: details.description || "",
        slug: slug
      })
      |> Multi.run(:items, fn repo, %{playlist: playlist} ->
        results =
          Enum.map(items, fn item_data ->
            %PlaylistItem{playlist_id: playlist.id}
            |> PlaylistItem.changeset(%{
              youtube_video_id: item_data.id,
              title: item_data.title || "Untitled Video",
              position: item_data.position || 0
            })
            |> repo.insert()
          end)

        case Enum.find(results, fn {status, _} -> status == :error end) do
          nil -> {:ok, :inserted}
          {:error, changeset} -> {:error, changeset}
        end
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{playlist: playlist}} ->
          Indexer.rebuild_for_playlist(playlist.id)
          {:ok, playlist}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Returns the list of playlist_items.

  ## Examples

      iex> list_playlist_items()
      [%PlaylistItem{}, ...]

  """
  def list_playlist_items do
    Repo.all(PlaylistItem)
  end

  @doc """
  Gets a single playlist_item.

  Raises `Ecto.NoResultsError` if the Playlist item does not exist.

  ## Examples

      iex> get_playlist_item!(123)
      %PlaylistItem{}

      iex> get_playlist_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_playlist_item!(id), do: Repo.get!(PlaylistItem, id)

  @doc """
  Creates a playlist_item.

  ## Examples

      iex> create_playlist_item(%{field: value})
      {:ok, %PlaylistItem{}}

      iex> create_playlist_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_playlist_item(attrs) do
    %PlaylistItem{}
    |> PlaylistItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a playlist_item.

  ## Examples

      iex> update_playlist_item(playlist_item, %{field: new_value})
      {:ok, %PlaylistItem{}}

      iex> update_playlist_item(playlist_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_playlist_item(%PlaylistItem{} = playlist_item, attrs) do
    playlist_item
    |> PlaylistItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a playlist_item.

  ## Examples

      iex> delete_playlist_item(playlist_item)
      {:ok, %PlaylistItem{}}

      iex> delete_playlist_item(playlist_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_playlist_item(%PlaylistItem{} = playlist_item) do
    Repo.delete(playlist_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking playlist_item changes.

  ## Examples

      iex> change_playlist_item(playlist_item)
      %Ecto.Changeset{data: %PlaylistItem{}}

  """
  def change_playlist_item(%PlaylistItem{} = playlist_item, attrs \\ %{}) do
    PlaylistItem.changeset(playlist_item, attrs)
  end
end
