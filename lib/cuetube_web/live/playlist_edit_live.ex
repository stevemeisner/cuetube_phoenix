defmodule CuetubeWeb.PlaylistEditLive do
  use CuetubeWeb, :live_view
  alias Cuetube.Library

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    playlist = Library.get_playlist!(id)

    # Ensure user owns this playlist
    if playlist.user_id != socket.assigns.current_user.id do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      items = Library.list_playlist_items(playlist.id)

      {:ok,
       assign(socket,
         playlist: playlist,
         items: items,
         view_mode: "grid",
         page_title: "Edit: #{playlist.title}",
         # We'll track forms by item id in a map
         item_forms: %{}
       )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="edit-playlist-view container">
        <header class="edit-header">
          <div class="breadcrumbs">
            <.link navigate={~p"/dashboard"} class="back-link">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="2.5"
                stroke="currentColor"
                class="w-4 h-4 mr-1"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18"
                />
              </svg>
              Back to Dashboard
            </.link>
          </div>

          <div class="title-row">
            <div class="header-left">
              <h1 class="edit-title">{@playlist.title}</h1>
              <p class={["edit-description", !@playlist.description && "empty-state"]}>
                {@playlist.description || "No description set on YouTube"}
              </p>
              <div class="edit-meta">
                Last Synced: {format_datetime(@playlist.last_synced_at)}
              </div>
            </div>

            <div class="edit-actions">
              <div class="view-toggle">
                <button
                  type="button"
                  class={["toggle-btn", @view_mode == "grid" && "active"]}
                  phx-click="set_view_mode"
                  phx-value-mode="grid"
                  title="Grid View"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="2"
                    stroke="currentColor"
                    class="w-5 h-5"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z"
                    />
                  </svg>
                </button>
                <button
                  type="button"
                  class={["toggle-btn", @view_mode == "list" && "active"]}
                  phx-click="set_view_mode"
                  phx-value-mode="list"
                  title="List View"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="2"
                    stroke="currentColor"
                    class="w-5 h-5"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
                    />
                  </svg>
                </button>
              </div>

              <.link
                navigate={~p"/p/#{@playlist.slug}"}
                target="_blank"
                class="btn btn-primary btn-sm"
              >
                View Public Page <span class="ml-1">↗</span>
              </.link>

              <button
                type="button"
                class="btn btn-outline btn-sm sync-btn"
                phx-click="sync_from_youtube"
              >
                <span class="sync-icon">↻</span> Sync from YouTube
              </button>
            </div>
          </div>
        </header>

        <div class={["editor-grid", @view_mode == "list" && "list-view"]}>
          <%= for item <- @items do %>
            <.video_editor
              item={item}
              view_mode={@view_mode}
              form={Map.get(@item_forms, item.id, to_form_for_item(item))}
            />
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp video_editor(assigns) do
    ~H"""
    <div class="editor-card">
      <div class="card-preview">
        <img
          src={"https://i.ytimg.com/vi/#{@item.youtube_video_id}/mqdefault.jpg"}
          alt={@item.title}
          class="thumbnail"
        />
        <div class="position">#{@item.position + 1}</div>
      </div>

      <div class="card-content">
        <h3 class="video-title">{@item.title}</h3>

        <.form
          for={@form}
          id={"edit-form-#{@item.id}"}
          class="edit-form"
          phx-change="validate_item"
          phx-submit="save_item"
        >
          <input type="hidden" name="item_id" value={@item.id} />

          <div class="form-row">
            <div class="form-group">
              <label>Curator's Notes</label>
              <textarea
                name="notes"
                placeholder="Add educational context, key takeaways, or timestamps..."
                rows={if(@view_mode == "list", do: 3, else: 4)}
              >{@item.notes}</textarea>
            </div>

            <div class="form-group">
              <label>Tags (comma separated)</label>
              <input
                type="text"
                name="tags"
                value={Enum.join(@item.tags || [], ", ")}
                placeholder="e.g. history, lecture, tutorial"
              />
            </div>
          </div>

          <div class="form-footer">
            <span class="status">
              <%= if @form.source.action do %>
                Saving...
              <% end %>
            </span>
            <button type="submit" class="btn btn-sm btn-primary btn-save">
              Save
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("set_view_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, view_mode: mode)}
  end

  @impl true
  def handle_event("validate_item", %{"item_id" => id} = params, socket) do
    # Just update the local form state for that item
    item = Enum.find(socket.assigns.items, &(&1.id == String.to_integer(id)))
    form = to_form_with_params(item, params)

    {:noreply, assign(socket, item_forms: Map.put(socket.assigns.item_forms, item.id, form))}
  end

  @impl true
  def handle_event("save_item", %{"item_id" => id, "notes" => notes, "tags" => tags_raw}, socket) do
    item_id = String.to_integer(id)
    item = Library.get_playlist_item!(item_id)

    tags =
      tags_raw
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case Library.update_playlist_item(item, %{notes: notes, tags: tags}) do
      {:ok, updated_item} ->
        # Update the item in the list and clear the form override
        items =
          Enum.map(socket.assigns.items, fn
            i when i.id == item_id -> updated_item
            i -> i
          end)

        {:noreply,
         socket
         |> assign(items: items)
         |> assign(item_forms: Map.delete(socket.assigns.item_forms, item_id))
         |> put_flash(:info, "Item updated")}

      {:error, changeset} ->
        form = Phoenix.Component.to_form(changeset)
        {:noreply, assign(socket, item_forms: Map.put(socket.assigns.item_forms, item_id, form))}
    end
  end

  @impl true
  def handle_event("sync_from_youtube", _params, socket) do
    # Placeholder for actual sync logic which would be in Cuetube.Library.Sync
    {:noreply, put_flash(socket, :info, "Syncing from YouTube... (Simulated)")}
  end

  defp to_form_for_item(item) do
    item
    |> Library.change_playlist_item()
    |> Phoenix.Component.to_form()
  end

  defp to_form_with_params(item, params) do
    item
    |> Library.change_playlist_item(params)
    |> Phoenix.Component.to_form()
  end

  defp format_datetime(nil), do: "Never"
  defp format_datetime(dt), do: Calendar.strftime(dt, "%b %d, %Y %I:%M %p")
end
