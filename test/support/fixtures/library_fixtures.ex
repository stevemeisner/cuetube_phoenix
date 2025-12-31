defmodule Cuetube.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cuetube.Library` context.
  """

  @doc """
  Generate a unique playlist slug.
  """
  def unique_playlist_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a playlist.
  """
  def playlist_fixture(attrs \\ %{}) do
    {:ok, playlist} =
      attrs
      |> Enum.into(%{
        description: "some description",
        last_synced_at: ~U[2025-12-29 18:17:00Z],
        slug: unique_playlist_slug(),
        title: "some title",
        youtube_playlist_id: "some youtube_playlist_id"
      })
      |> Cuetube.Library.create_playlist()

    playlist
  end

  @doc """
  Generate a playlist_item.
  """
  def playlist_item_fixture(attrs \\ %{}) do
    {:ok, playlist_item} =
      attrs
      |> Enum.into(%{
        notes: "some notes",
        position: 42,
        tags: %{},
        title: "some title",
        youtube_video_id: "some youtube_video_id"
      })
      |> Cuetube.Library.create_playlist_item()

    playlist_item
  end
end
