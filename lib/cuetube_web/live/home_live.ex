defmodule CuetubeWeb.HomeLive do
  use CuetubeWeb, :live_view
  import CuetubeWeb.PlaylistComponents
  alias Cuetube.Search
  alias Cuetube.Library

  @impl true
  def mount(_params, _session, socket) do
    latest_playlists = Library.list_latest_playlists(6)

    {:ok,
     assign(socket,
       query: "",
       suggestions: [],
       results: [],
       latest_playlists: latest_playlists,
       loading: false,
       page_title: "Curate & Contextualize"
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    query = params["q"] || ""

    if query != "" do
      results = Search.search_playlists(query, 6)
      {:noreply, assign(socket, query: query, results: results, suggestions: [])}
    else
      {:noreply, assign(socket, query: "", results: [], suggestions: [])}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="home-view">
        <section class="hero-section">
          <div class="container hero-content">
            <h1 class="hero-title">Curate & Contextualize</h1>
            <p class="hero-subtitle">
              Transform YouTube playlists into guided learning experiences. Add
              notes, tags, and context to create deeper understanding.
            </p>

            <div class="search-box-wrapper">
              <form phx-change="suggest" phx-submit="search" class="search-form">
                <.icon name="hero-magnifying-glass" class="search-icon" />
                <input
                  type="text"
                  name="query"
                  value={@query}
                  placeholder="Search by title, #tag, or curator..."
                  autocomplete="off"
                  phx-debounce="300"
                  phx-focus="suggest"
                  class="hero-search-input"
                />
              </form>

              <%= if @suggestions != [] do %>
                <div class="hero-suggestions">
                  <ul class="suggestions-list">
                    <%= for suggestion <- @suggestions do %>
                      <li class="suggestion-item">
                        <.link navigate={suggestion_link(suggestion)} class="suggestion-link">
                          <div class="suggestion-icon-wrapper">
                            <.icon name={suggestion_icon(suggestion.type)} class="suggestion-icon" />
                          </div>
                          <div class="suggestion-info">
                            <div class="suggestion-header">
                              <span class="suggestion-text">{suggestion_label(suggestion)}</span>
                              <span class="suggestion-type-label">{suggestion.type}</span>
                            </div>
                            <%= if suggestion.type == :playlist do %>
                              <span class="suggestion-meta">
                                by {suggestion.curator_display_name || "anonymous"}
                                <%= if suggestion.video_count do %>
                                  • {suggestion.video_count} videos
                                <% end %>
                              </span>
                            <% end %>
                          </div>
                        </.link>
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
            </div>

            <div class="cta-container">
              <%= if !@current_user do %>
                <.link href={~p"/auth/google"} class="btn btn-primary btn-lg">
                  Login with Google
                </.link>
              <% end %>
            </div>
          </div>
        </section>

        <section :if={@query != ""} class="search-results-preview-section container">
          <div class="search-status" role="status" aria-live="polite">
            <%= if @results != [] do %>
              {length(@results)} results for "{@query}".
            <% else %>
              No results for "{@query}".
            <% end %>
          </div>

          <header class="section-header">
            <h2 class="section-title">Top results</h2>
          </header>

          <div :if={@results != []} class="grid">
            <%= for result <- @results do %>
              <.playlist_card playlist={result} />
            <% end %>
          </div>
        </section>

        <section class="featured-section container">
          <header class="section-header">
            <h2 class="section-title">Fresh from the Community</h2>
          </header>

          <div class="grid">
            <%= for playlist <- @latest_playlists do %>
              <.playlist_card playlist={playlist} />
            <% end %>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  # Event handlers (similar to SearchLive)
  @impl true
  def handle_event("suggest", %{"query" => query}, socket) do
    IO.inspect(query, label: "SUGGEST EVENT")
    suggestions = if String.length(query) >= 2, do: Search.get_suggestions(query), else: []
    IO.inspect(length(suggestions), label: "SUGGESTIONS FOUND")

    # Update results as well for the real-time preview grid
    results = if String.length(query) >= 3, do: Search.search_playlists(query, 6), else: []

    {:noreply,
     socket
     |> assign(query: query, suggestions: suggestions, results: results)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?q=#{query}")}
  end

  defp suggestion_label(%{type: :playlist, title: title}), do: title
  defp suggestion_label(%{type: :video, title: title}), do: title

  defp suggestion_label(%{type: :curator, display_name: name, handle: handle}),
    do: name || "@#{handle}"

  defp suggestion_label(%{type: :tag, tag: tag}), do: "##{tag}"

  defp suggestion_icon(:playlist), do: "hero-list-bullet"
  defp suggestion_icon(:video), do: "hero-play-circle"
  defp suggestion_icon(:curator), do: "hero-user"
  defp suggestion_icon(:tag), do: "hero-tag"
  defp suggestion_icon(_), do: "hero-question-mark-circle"

  defp suggestion_link(%{type: :playlist, slug: slug}), do: ~p"/p/#{slug}"

  defp suggestion_link(%{type: :video, playlist_slug: slug, video_id: id}),
    do: ~p"/p/#{slug}?v=#{id}"

  defp suggestion_link(%{type: :curator, handle: handle}), do: ~p"/?q=@#{handle}"
  defp suggestion_link(%{type: :tag, tag: tag}), do: ~p"/?q=%23#{tag}"
end
