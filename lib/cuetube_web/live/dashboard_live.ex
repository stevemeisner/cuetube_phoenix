defmodule CuetubeWeb.DashboardLive do
  use CuetubeWeb, :live_view
  alias Cuetube.Library

  @impl true
  def mount(_params, _session, socket) do
    # This route is protected by on_mount :ensure_authenticated in the router
    user_id = socket.assigns.current_user.id
    playlists = Library.list_user_playlists(user_id)

    {:ok,
      assign(socket,
        playlists: playlists,
        page_title: "My Dashboard"
      )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="dashboard-view container">
        <header class="section-header dashboard-header">
          <h1 class="section-title">My Playlists</h1>
          <div class="header-actions">
            <.link navigate={~p"/playlists/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Playlist
            </.link>
          </div>
        </header>

        <div class="dashboard-content">
          <%= if @playlists == [] do %>
            <div class="empty-dashboard">
              <div class="empty-icon-wrapper">
                <.icon name="hero-queue-list" class="empty-icon" />
              </div>
              <h2 class="empty-title">No playlists yet</h2>
              <p class="empty-text">
                Start by importing a YouTube playlist to add your own educational context and notes.
              </p>
              <.link navigate={~p"/playlists/new"} class="btn btn-outline btn-lg">
                Import Your First Playlist
              </.link>
            </div>
          <% else %>
            <div class="dashboard-grid">
              <%= for playlist <- @playlists do %>
                <div class="dashboard-card">
                  <div class="card-body">
                    <h3 class="card-title">{playlist.title}</h3>
                    <p class="card-desc">{playlist.description}</p>
                    <div class="card-meta">
                      <.icon name="hero-calendar" class="w-3 h-3 mr-1" />
                      <span>Synced {Calendar.strftime(playlist.last_synced_at, "%b %d, %Y")}</span>
                    </div>
                  </div>
                  <div class="card-actions">
                    <.link navigate={~p"/p/#{playlist.slug}"} class="btn btn-sm btn-outline">
                      View Public
                    </.link>
                    <.link navigate={~p"/playlists/#{playlist.id}/edit"} class="btn btn-sm btn-primary">
                      Edit Curation
                    </.link>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
