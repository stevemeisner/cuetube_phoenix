defmodule CuetubeWeb.ThumbnailController do
  use CuetubeWeb, :controller

  def show(conn, %{"video_id" => video_id}) do
    # Try high quality first, fall back to medium if needed?
    # YouTube usually has hqdefault.jpg available.
    url = "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg"

    case Req.get(url, headers: [{"user-agent", "Mozilla/5.0"}]) do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        content_type = Map.get(headers, "content-type") |> List.first() || "image/jpeg"

        # Cache for 1 week since video thumbnails rarely change
        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("cache-control", "public, max-age=604800")
        |> send_resp(200, body)

      _ ->
        # Fallback to a placeholder or 404
        send_resp(conn, 404, "Not Found")
    end
  end
end
