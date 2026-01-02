defmodule CuetubeWeb.PlaylistLive do
  use CuetubeWeb, :live_view
  alias Cuetube.Library

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    playlist = Library.get_playlist_by_slug!(slug)
    items = Library.list_playlist_items(playlist.id)

    {:ok,
     assign(socket,
       playlist: playlist,
       items: items,
       active_video_id: nil,
       page_title: playlist.title
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    first_video_id =
      case List.first(socket.assigns.items) do
        nil -> nil
        item -> item.youtube_video_id
      end

    active_video_id = params["v"] || first_video_id
    {:noreply, assign(socket, active_video_id: active_video_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="playlist-view container">
        <header class="section-header playlist-header">
          <div class="header-main">
            <div class="header-top">
              <div class="curator-info">
                <%= if @playlist.user.handle do %>
                  <img src={~p"/avatar/#{@playlist.user.handle}"} class="curator-avatar" />
                <% end %>
                <span>Curated by <strong>{@playlist.user.display_name}</strong></span>
              </div>
              <div class="header-actions">
                <%= if @current_user && @current_user.id == @playlist.user_id do %>
                  <.link
                    navigate={~p"/playlists/#{@playlist.id}/edit"}
                    class="btn btn-sm btn-outline"
                  >
                    <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit Playlist Curation
                  </.link>
                <% end %>
              </div>
            </div>
            <h1 class="section-title playlist-title">{@playlist.title}</h1>
            <%= if @playlist.description do %>
              <p class="playlist-description">{@playlist.description}</p>
            <% end %>
          </div>
        </header>

        <div class="playlist-layout">
          <div class="main-content">
            <div class="player-wrapper">
              <%= if @active_video_id do %>
                <iframe
                  width="100%"
                  height="100%"
                  src={"https://www.youtube.com/embed/#{@active_video_id}?rel=0&autoplay=1"}
                  title="YouTube video player"
                  frameborder="0"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowfullscreen
                >
                </iframe>
              <% end %>
            </div>

            <%= if active_item = Enum.find(@items, &(&1.youtube_video_id == @active_video_id)) do %>
              <div class="context-card">
                <h2 class="current-video-title">{active_item.title}</h2>

                <%= if active_item.notes do %>
                  <div class="notes-section">
                    <span class="notes-label">Curator's Notes</span>
                    <div class="notes-content">{active_item.notes}</div>
                  </div>
                <% else %>
                  <p class="no-notes">No notes added for this video.</p>
                <% end %>

                <%= if active_item.tags && active_item.tags != [] do %>
                  <div class="tags-list">
                    <%= for tag <- active_item.tags do %>
                      <span class="tag">#{tag}</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <aside class="playlist-sidebar">
            <div class="sidebar-header">
              <span>Up Next</span>
              <span>{length(@items)} videos</span>
            </div>
            <div class="video-list">
              <%= for {item, idx} <- Enum.with_index(@items) do %>
                <.link
                  patch={~p"/p/#{@playlist.slug}?v=#{item.youtube_video_id}"}
                  class={["video-item", item.youtube_video_id == @active_video_id && "active"]}
                >
                  <span class="item-index">{idx + 1}.</span>
                  <div class="item-thumbnail">
                    <img
                      src={~p"/thumbnails/#{item.youtube_video_id}"}
                      loading="lazy"
                    />
                  </div>
                  <div class="item-info">
                    <div class="item-title">{item.title}</div>
                    <%= if item.notes do %>
                      <div class="has-notes-badge">Has notes</div>
                    <% end %>
                  </div>
                </.link>
              <% end %>
            </div>
          </aside>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
