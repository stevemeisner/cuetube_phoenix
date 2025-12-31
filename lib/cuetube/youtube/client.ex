defmodule Cuetube.YouTube.Client do
  @moduledoc """
  Lightweight YouTube API client using Req.
  """
  @behaviour Cuetube.YouTube

  @base_url "https://www.googleapis.com/youtube/v3"

  @impl true
  def get_playlist_details(playlist_id) do
    req()
    |> Req.get(
      url: "/playlists",
      params: [
        part: "snippet",
        id: playlist_id
      ]
    )
    |> handle_response(fn body ->
      case body["items"] do
        [playlist | _] ->
          {:ok,
           %{
             id: playlist["id"],
             title: get_in(playlist, ["snippet", "title"]),
             description: get_in(playlist, ["snippet", "description"]),
             channel_title: get_in(playlist, ["snippet", "channelTitle"]),
             thumbnail: get_in(playlist, ["snippet", "thumbnails", "high", "url"])
           }}

        [] ->
          {:error, :not_found}
      end
    end)
  end

  @impl true
  def get_playlist_items(playlist_id) do
    # For MVP we just get the first 50 as in the original project
    req()
    |> Req.get(
      url: "/playlistItems",
      params: [
        part: "snippet,contentDetails",
        playlistId: playlist_id,
        maxResults: 50
      ]
    )
    |> handle_response(fn body ->
      items =
        body["items"]
        |> Enum.map(fn item ->
          %{
            id: get_in(item, ["snippet", "resourceId", "videoId"]),
            title: get_in(item, ["snippet", "title"]),
            description: get_in(item, ["snippet", "description"]),
            position: get_in(item, ["snippet", "position"]),
            thumbnail: get_in(item, ["snippet", "thumbnails", "medium", "url"])
          }
        end)
        |> Enum.reject(&is_nil(&1.id))

      {:ok, items}
    end)
  end

  defp req do
    api_key = Application.get_env(:cuetube, :youtube_api_key)
    base_url_header = Application.get_env(:cuetube, :base_url, "http://localhost:4000")

    Req.new(base_url: @base_url)
    |> Req.Request.put_header("referer", base_url_header)
    |> Req.merge(params: [key: api_key])
  end

  defp handle_response(result, success_fun) do
    case result do
      {:ok, %{status: 200, body: body}} ->
        success_fun.(body)

      {:ok, %{status: status, body: body}} ->
        {:error, "YouTube API error: #{status} - #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
