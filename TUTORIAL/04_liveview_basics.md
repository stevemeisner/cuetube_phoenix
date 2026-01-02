# Part 4: The Heartbeat (LiveView Basics)

This is the main event. LiveView allows you to write interactive UI (like React) entirely in Elixir.

Let's dissect `lib/cuetube_web/live/dashboard_live.ex`.

## The Connection Lifecycle

A LiveView has a very specific lifecycle.

### 1. `mount(params, session, socket)`

This is the constructor. It runs **twice**:

1.  Once on the initial HTTP request (to render the HTML for SEO and speed).
2.  Once again when the WebSocket connects (to become interactive).

```elixir
def mount(_params, _session, socket) do
  user_id = socket.assigns.current_user.id
  playlists = Library.list_user_playlists(user_id)

  {:ok, assign(socket, playlists: playlists)}
end
```

- **`socket`**: This is your state (like `this.state` or `useState`).
- **`assign(socket, key: value)`**: This sets state. Here we fetch the user's playlists and store them in the socket.

### 2. `render(assigns)`

This is your JSX. It takes the state (`assigns`) and returns HTML.
In Phoenix 1.7+, this is often inside the `.ex` file using the `~H` (Heex) sigil.

```elixir
def render(assigns) do
  ~H"""
  <Layouts.app flash={@flash} current_user={@current_user}>
    <h1>My Playlists</h1>
    <%= for playlist <- @playlists do %>
      <.playlist_card playlist={playlist} />
    <% end %>
  </Layouts.app>
  """
end
```

- **`<%= ... %>`**: Executes Elixir code (loops, logic).
- **`@playlists`**: Accessing the state we set in `mount`.
- **`<.playlist_card>`**: A Function Component (like a React component).

## Interactivity (Events)

How do you handle a click?

### The Template

```html
<button phx-click="delete_playlist" phx-value-id="{playlist.id}">Delete</button>
```

- **`phx-click`**: The event name.
- **`phx-value-id`**: Passes data (`id`) to the event.

### The Handler

Back in the `.ex` file:

```elixir
def handle_event("delete_playlist", %{"id" => id}, socket) do
  Library.delete_playlist!(id)

  # Update the list!
  playlists = Library.list_user_playlists(socket.assigns.current_user.id)

  {:noreply, assign(socket, playlists: playlists)}
end
```

1.  User clicks.
2.  "delete_playlist" is sent over the WebSocket.
3.  `handle_event` runs on the server.
4.  We delete the item in the DB.
5.  We update the `socket` with the new list.
6.  **Magic:** LiveView calculates the _diff_ (only the deleted item is removed) and sends a tiny patch to the browser. The DOM updates.

## No API Needed

Notice what we didn't do?

- We didn't write a `DELETE /api/playlists/:id` endpoint.
- We didn't write a `fetch()` call in JS.
- We didn't handle loading states or JSON parsing.

We just changed the server state, and the UI updated.
