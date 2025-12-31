defmodule CuetubeWeb.PlaylistNewLive do
  use CuetubeWeb, :live_view
  alias Cuetube.Library
  alias Cuetube.Utils.PlaylistInput

  @impl true
  def mount(params, _session, socket) do
    url = params["url"] || ""

    socket =
      assign(socket,
        url: url,
        error: nil,
        hint: nil,
        loading: false,
        page_title: "Import Playlist"
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    url = params["url"] || ""

    if url != "" do
      process_import(url, socket)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <main class="new-playlist-view container">
        <header class="new-header">
          <div>
            <h1 class="new-title">Import a Playlist</h1>
            <p class="new-subtitle">
              Paste a YouTube playlist URL and we’ll import the videos so you can
              add context.
            </p>
          </div>
          <div class="user-info">
            <span>{@current_user.email}</span>
            <.link navigate={~p"/dashboard"} class="btn btn-outline btn-sm">
              Back to Dashboard
            </.link>
          </div>
        </header>

        <section class="new-card">
          <%= if @error do %>
            <div class="error-box" role="alert">
              <div class="error-title">{@error.message}</div>
              <%= if @error.hint do %>
                <div class="error-hint">{@error.hint}</div>
              <% end %>
            </div>
          <% end %>

          <.form for={%{}} id="playlist-import-form" phx-submit="import" class="new-form">
            <label for="playlist-url" class="label">
              YouTube playlist URL or ID
            </label>
            <div class="form-row">
              <input
                id="playlist-url"
                type="text"
                name="url"
                value={@url}
                placeholder="https://www.youtube.com/playlist?list=..."
                required
                ph-change="validate"
                ph-debounce="300"
                autocomplete="off"
              />
              <button type="submit" class="btn btn-primary" disabled={@loading}>
                <%= if @loading do %>
                  Importing...
                <% else %>
                  Import
                <% end %>
              </button>
            </div>
            <%= if @hint do %>
              <div class="helper-text" role="status">
                {@hint}
              </div>
            <% end %>
          </.form>
        </section>
      </main>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"url" => url}, socket) do
    normalized = PlaylistInput.normalize_playlist_input(url)
    hint = PlaylistInput.get_playlist_input_hint(normalized)
    {:noreply, assign(socket, url: url, hint: hint)}
  end

  @impl true
  def handle_event("import", %{"url" => url}, socket) do
    process_import(url, assign(socket, loading: true, error: nil))
  end

  defp process_import(url, socket) do
    normalized = PlaylistInput.normalize_playlist_input(url)
    playlist_id = PlaylistInput.extract_playlist_id(normalized)

    if playlist_id do
      case Library.import_playlist_from_youtube(socket.assigns.current_user.id, playlist_id) do
        {:ok, playlist} ->
          {:noreply,
           socket
           |> put_flash(:info, "Playlist imported successfully!")
           |> push_navigate(to: ~p"/playlists/#{playlist.id}/edit")}

        {:error, :not_found} ->
          {:noreply,
           assign(socket,
             loading: false,
             error: %{
               message: "We couldn't access that playlist on YouTube.",
               hint:
                 "If the link is correct, the playlist may be private/deleted, or restricted. Try setting it to Public/Unlisted and retry."
             }
           )}

        {:error, reason} ->
          {:noreply,
           assign(socket,
             loading: false,
             error: %{
               message: "YouTube API error",
               hint: inspect(reason)
             }
           )}
      end
    else
      {:noreply,
       assign(socket,
         error: %{
           message: "Invalid playlist URL or ID",
           hint:
             "Tip: paste a full YouTube playlist URL like https://www.youtube.com/playlist?list=... or just the playlist id."
         }
       )}
    end
  end
end
