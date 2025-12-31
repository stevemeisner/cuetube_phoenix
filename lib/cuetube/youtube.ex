defmodule Cuetube.YouTube do
  @moduledoc """
  The YouTube context and behaviour for external API calls.
  """

  @callback get_playlist_details(String.t()) :: {:ok, map()} | {:error, any()}
  @callback get_playlist_items(String.t()) :: {:ok, [map()]} | {:error, any()}

  def client do
    Application.get_env(:cuetube, :youtube_client, Cuetube.YouTube.Client)
  end

  @doc """
  Fetches playlist details.
  """
  def get_playlist_details(playlist_id), do: client().get_playlist_details(playlist_id)

  @doc """
  Fetches all items in a playlist.
  """
  def get_playlist_items(playlist_id), do: client().get_playlist_items(playlist_id)
end
