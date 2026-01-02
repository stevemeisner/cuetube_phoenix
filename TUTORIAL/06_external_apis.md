# Part 6: The Phone Call (External APIs)

You mentioned fetching data (YouTube). Let's see how that works in `lib/cuetube/youtube/client.ex`.

## The Tool: `Req`

We use a library called `Req`. It's the standard HTTP client now. It's high-level and easy to use.

```elixir
def get_playlist_details(playlist_id) do
  req()
  |> Req.get(url: "/playlists", params: [id: playlist_id, part: "snippet"])
  |> handle_response(...)
end
```

## Pattern Matching API Responses

One of the coolest things in Elixir is handling JSON responses.

```elixir
defp handle_response(result) do
  case result do
    # 1. Success! Pattern match the 200 OK and the body
    {:ok, %{status: 200, body: body}} ->
      {:ok, parse_body(body)}

    # 2. API Error (404, 500)
    {:ok, %{status: status}} ->
      {:error, "YouTube said no: #{status}"}

    # 3. Network Error (DNS failed, timeout)
    {:error, reason} ->
      {:error, "Internet broken: #{inspect(reason)}"}
  end
end
```

This forces you to handle every scenario. You can't accidentally ignore a 404.

## Keeping Secrets

Notice `Application.get_env(:cuetube, :youtube_api_key)`.
We **never** hardcode API keys. They live in `config/runtime.exs`, which reads them from environment variables (`System.get_env("YOUTUBE_API_KEY")`).

## Async & Tasks (Advanced)

If fetching a playlist takes 5 seconds, you don't want to freeze the user's browser.
In LiveView, you can do this:

1.  **Mount:** Render the page with a "Loading..." spinner.
2.  **Async:** Kick off a background task to fetch from YouTube.
3.  **Receive:** When the task finishes, it sends a message to the LiveView.
4.  **Update:** The LiveView updates the state with the data and the spinner disappears.

This is powered by the BEAM's lightweight processes. You can spawn thousands of these tasks without sweating.

## Bonus: Proxying Images (`ThumbnailController`)

Sometimes you need to serve external assets (like YouTube thumbnails) but you want to control caching or avoid mixed-content warnings.
You recently added `lib/cuetube_web/controllers/thumbnail_controller.ex`.

```elixir
def show(conn, %{"video_id" => video_id}) do
  url = "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg"

  case Req.get(url) do
    {:ok, %{status: 200, body: body, headers: headers}} ->
      content_type = Map.get(headers, "content-type") |> List.first()

      conn
      |> put_resp_content_type(content_type)
      |> put_resp_header("cache-control", "public, max-age=604800")
      |> send_resp(200, body)

    _ -> send_resp(conn, 404, "Not Found")
  end
end
```

### Why use a Controller here?

LiveView is great for HTML, but Controllers are still king for **binary data** (images, downloads, APIs).
By proxying through `Req`, we:

1.  **Hide the source:** The user sees `/thumbnails/xyz`, not `google.com`.
2.  **Cache it:** We set `cache-control` to 1 week.
3.  **Prevent Tracking:** Users don't ping YouTube's servers just by loading your dashboard.
