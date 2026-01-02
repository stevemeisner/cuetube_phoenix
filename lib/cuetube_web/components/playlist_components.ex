defmodule CuetubeWeb.PlaylistComponents do
  use Phoenix.Component
  use CuetubeWeb, :verified_routes

  @doc """
  Renders a standardized playlist card.
  """
  attr :playlist, :any, required: true
  slot :actions

  def playlist_card(assigns) do
    ~H"""
    <div class="playlist-card group">
      <.link navigate={~p"/p/#{playlist_slug(@playlist)}"} class="playlist-card-link">
        <div class="playlist-card-thumbnail">
          <.playlist_collage playlist={@playlist} />
          <div class="playlist-card-overlay">
            <div class="playlist-card-count">
              <CuetubeWeb.CoreComponents.icon name="hero-play-circle" class="w-5 h-5" />
              <span>{playlist_count(@playlist)} videos</span>
            </div>
          </div>
        </div>

        <div class="playlist-card-content">
          <h3 class="playlist-card-title group-hover:text-primary transition-colors">
            {playlist_title(@playlist)}
          </h3>
          <p class="playlist-card-desc">
            {playlist_desc(@playlist)}
          </p>

          <div class="playlist-card-footer">
            <div class="playlist-card-curator">
              <%= if handle = curator_handle(@playlist) do %>
                <img src={~p"/avatar/#{handle}"} class="curator-avatar-sm" loading="lazy" />
              <% else %>
                <div class="curator-avatar-sm bg-gray-200"></div>
              <% end %>
              <span class="curator-name">by {curator_name(@playlist)}</span>
            </div>
            <span class="playlist-card-date">{playlist_date(@playlist)}</span>
          </div>
        </div>
      </.link>

      <%= if render_slot(@actions) != "" do %>
        <div class="playlist-card-actions">
          {render_slot(@actions)}
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a collage of thumbnails for a playlist.
  """
  attr :playlist, :any, required: true

  def playlist_collage(assigns) do
    thumbnails = get_collage_thumbnails(assigns.playlist)
    assigns = assign(assigns, :thumbnails, thumbnails)

    ~H"""
    <div class="playlist-collage">
      <%= case @thumbnails do %>
        <% [t1, t2, t3, t4] -> %>
          <div class="collage-grid collage-4">
            <img src={t1} class="collage-img" />
            <img src={t2} class="collage-img" />
            <img src={t3} class="collage-img" />
            <img src={t4} class="collage-img" />
          </div>
        <% [t1, t2] -> %>
          <div class="collage-grid collage-2">
            <img src={t1} class="collage-img" />
            <img src={t2} class="collage-img" />
          </div>
        <% [t1] -> %>
          <div class="collage-single">
            <img src={t1} class="collage-img" />
          </div>
        <% _ -> %>
          <div class="collage-placeholder">
            <CuetubeWeb.CoreComponents.icon name="hero-play" class="w-12 h-12 text-gray-400" />
          </div>
      <% end %>
    </div>
    """
  end

  # Helpers to handle different data shapes (Playlist struct vs Search Map)
  defp playlist_slug(%{playlist_slug: slug}), do: slug
  defp playlist_slug(%{slug: slug}), do: slug

  defp playlist_title(%{playlist_title: title}), do: title
  defp playlist_title(%{title: title}), do: title

  defp playlist_desc(%{playlist_description: desc}), do: desc || "No description provided."
  defp playlist_desc(%{description: desc}), do: desc || "No description provided."

  defp playlist_count(%{video_count: count}), do: count
  defp playlist_count(%{playlist_items: items}) when is_list(items), do: length(items)
  defp playlist_count(_), do: "?"

  defp curator_name(%{curator_display_name: name}), do: name || "anonymous"
  defp curator_name(%{user: %{display_name: name}}), do: name || "anonymous"
  defp curator_name(_), do: "anonymous"

  defp curator_handle(%{curator_handle: handle}), do: handle
  defp curator_handle(%{user: %{handle: handle}}), do: handle
  defp curator_handle(_), do: nil

  defp playlist_date(%{playlist_inserted_at: date}), do: format_date(date)
  defp playlist_date(%{created_at: date}), do: format_date(date)
  defp playlist_date(_), do: ""

  defp format_date(nil), do: ""
  defp format_date(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp get_collage_thumbnails(%{playlist_items: items}) when is_list(items) do
    items
    |> Enum.map(fn item ->
      cond do
        Map.get(item, :youtube_video_id) ->
          ~p"/thumbnails/#{item.youtube_video_id}"

        url = Map.get(item, :thumbnail_url) ->
          case extract_video_id(url) do
            nil -> url
            id -> ~p"/thumbnails/#{id}"
          end

        true ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.take(4)
    |> pad_thumbnails()
  end

  defp get_collage_thumbnails(%{thumbnail_url: url}) when not is_nil(url) do
    case extract_video_id(url) do
      nil -> [url]
      id -> [~p"/thumbnails/#{id}"]
    end
  end

  defp get_collage_thumbnails(_), do: []

  defp extract_video_id(url) do
    case Regex.run(~r/\/vi\/([^\/]+)\//, url) do
      [_, id] -> id
      _ -> nil
    end
  end

  defp pad_thumbnails(list) when length(list) == 3, do: list ++ [Enum.at(list, 0)]
  defp pad_thumbnails(list), do: list
end
