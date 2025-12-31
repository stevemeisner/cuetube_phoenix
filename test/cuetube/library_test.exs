defmodule Cuetube.LibraryTest do
  use Cuetube.DataCase

  alias Cuetube.Library

  describe "playlists" do
    alias Cuetube.Library.Playlist

    import Cuetube.LibraryFixtures

    @invalid_attrs %{
      description: nil,
      title: nil,
      youtube_playlist_id: nil,
      slug: nil,
      last_synced_at: nil
    }

    test "list_playlists/0 returns all playlists" do
      playlist = playlist_fixture()
      assert Library.list_playlists() == [playlist]
    end

    test "get_playlist!/1 returns the playlist with given id" do
      playlist = playlist_fixture()
      assert Library.get_playlist!(playlist.id) == playlist
    end

    test "create_playlist/1 with valid data creates a playlist" do
      valid_attrs = %{
        description: "some description",
        title: "some title",
        youtube_playlist_id: "some youtube_playlist_id",
        slug: "some slug",
        last_synced_at: ~U[2025-12-29 18:17:00Z]
      }

      assert {:ok, %Playlist{} = playlist} = Library.create_playlist(valid_attrs)
      assert playlist.description == "some description"
      assert playlist.title == "some title"
      assert playlist.youtube_playlist_id == "some youtube_playlist_id"
      assert playlist.slug == "some slug"
      assert playlist.last_synced_at == ~U[2025-12-29 18:17:00Z]
    end

    test "create_playlist/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_playlist(@invalid_attrs)
    end

    test "update_playlist/2 with valid data updates the playlist" do
      playlist = playlist_fixture()

      update_attrs = %{
        description: "some updated description",
        title: "some updated title",
        youtube_playlist_id: "some updated youtube_playlist_id",
        slug: "some updated slug",
        last_synced_at: ~U[2025-12-30 18:17:00Z]
      }

      assert {:ok, %Playlist{} = playlist} = Library.update_playlist(playlist, update_attrs)
      assert playlist.description == "some updated description"
      assert playlist.title == "some updated title"
      assert playlist.youtube_playlist_id == "some updated youtube_playlist_id"
      assert playlist.slug == "some updated slug"
      assert playlist.last_synced_at == ~U[2025-12-30 18:17:00Z]
    end

    test "update_playlist/2 with invalid data returns error changeset" do
      playlist = playlist_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_playlist(playlist, @invalid_attrs)
      assert playlist == Library.get_playlist!(playlist.id)
    end

    test "delete_playlist/1 deletes the playlist" do
      playlist = playlist_fixture()
      assert {:ok, %Playlist{}} = Library.delete_playlist(playlist)
      assert_raise Ecto.NoResultsError, fn -> Library.get_playlist!(playlist.id) end
    end

    test "change_playlist/1 returns a playlist changeset" do
      playlist = playlist_fixture()
      assert %Ecto.Changeset{} = Library.change_playlist(playlist)
    end
  end

  describe "playlist_items" do
    alias Cuetube.Library.PlaylistItem

    import Cuetube.LibraryFixtures

    @invalid_attrs %{position: nil, title: nil, youtube_video_id: nil, notes: nil, tags: nil}

    test "list_playlist_items/0 returns all playlist_items" do
      playlist_item = playlist_item_fixture()
      assert Library.list_playlist_items() == [playlist_item]
    end

    test "get_playlist_item!/1 returns the playlist_item with given id" do
      playlist_item = playlist_item_fixture()
      assert Library.get_playlist_item!(playlist_item.id) == playlist_item
    end

    test "create_playlist_item/1 with valid data creates a playlist_item" do
      valid_attrs = %{
        position: 42,
        title: "some title",
        youtube_video_id: "some youtube_video_id",
        notes: "some notes",
        tags: %{}
      }

      assert {:ok, %PlaylistItem{} = playlist_item} = Library.create_playlist_item(valid_attrs)
      assert playlist_item.position == 42
      assert playlist_item.title == "some title"
      assert playlist_item.youtube_video_id == "some youtube_video_id"
      assert playlist_item.notes == "some notes"
      assert playlist_item.tags == %{}
    end

    test "create_playlist_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_playlist_item(@invalid_attrs)
    end

    test "update_playlist_item/2 with valid data updates the playlist_item" do
      playlist_item = playlist_item_fixture()

      update_attrs = %{
        position: 43,
        title: "some updated title",
        youtube_video_id: "some updated youtube_video_id",
        notes: "some updated notes",
        tags: %{}
      }

      assert {:ok, %PlaylistItem{} = playlist_item} =
               Library.update_playlist_item(playlist_item, update_attrs)

      assert playlist_item.position == 43
      assert playlist_item.title == "some updated title"
      assert playlist_item.youtube_video_id == "some updated youtube_video_id"
      assert playlist_item.notes == "some updated notes"
      assert playlist_item.tags == %{}
    end

    test "update_playlist_item/2 with invalid data returns error changeset" do
      playlist_item = playlist_item_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Library.update_playlist_item(playlist_item, @invalid_attrs)

      assert playlist_item == Library.get_playlist_item!(playlist_item.id)
    end

    test "delete_playlist_item/1 deletes the playlist_item" do
      playlist_item = playlist_item_fixture()
      assert {:ok, %PlaylistItem{}} = Library.delete_playlist_item(playlist_item)
      assert_raise Ecto.NoResultsError, fn -> Library.get_playlist_item!(playlist_item.id) end
    end

    test "change_playlist_item/1 returns a playlist_item changeset" do
      playlist_item = playlist_item_fixture()
      assert %Ecto.Changeset{} = Library.change_playlist_item(playlist_item)
    end
  end
end
