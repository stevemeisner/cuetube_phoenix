# From React to Phoenix: A Developer's Field Guide

## The "Cuetube" Architecture Series

**Author:** Cursor AI (Powered by gemini-3-pro-preview)
**For:** Steve Meisner
**Date:** January 1, 2026

---

<div style="page-break-after: always;"></div>

# Part 1: The Blueprint (Stack & Structure)

Welcome! You've just inherited a high-performance sports car (Elixir/Phoenix) after driving a reliable sedan (React/Node). It feels different, the steering is tighter, and the engine hums a weird tune. Don't worry, we're going to pop the hood.

## The 30,000 Foot View

You came from **React + Node + Neon + Drizzle**.
You are now in **Phoenix LiveView + Elixir + Postgres + Ecto**.

### The Big Shift

In your old stack, you had a "Frontend" (React) and a "Backend" (Node/Express). They lived apart and talked via JSON.
In **Phoenix LiveView**, the "Backend" _renders_ the "Frontend" and keeps a persistent connection open. It's like having the server sit right next to the browser, whispering updates into its ear.

**Why is this cool?**

- **No API Layer:** You don't need to build a REST/GraphQL API just to talk to your own frontend.
- **Speed:** Elixir runs on the BEAM (Erlang VM), designed for massive concurrency. It eats parallel tasks for breakfast.
- **Reliability:** "Let it crash." If a part of your app breaks, it restarts instantly without taking down the whole ship.

---

## The Kitchen (Project Structure)

Let's look at the file structure. Think of your app as a professional kitchen.

### 1. `mix.exs` (The Shopping List)

This is your `package.json`. It defines your app name, version, and most importantly, your **dependencies** (`deps`).

- **You'll see:** `{:phoenix, ...}`, `{:ecto, ...}`, `{:req, ...}`.
- **Command:** `mix deps.get` (like `npm install`).

### 2. `lib/` (The Recipes)

This is where _all_ your code lives. It's split into two main folders:

#### A. `lib/cuetube/` (The Business Logic)

This is the "Back of House". It's where your data, rules, and logic live. It knows _nothing_ about the web, HTML, or HTTP.

- **Examples:** `Accounts` (User users), `Library` (Playlists), `YouTube` (API client).
- **Key Concept:** **Contexts**. You'll see files like `accounts.ex`. This is the _public interface_ for a feature. You don't query the `User` table directly from a controller; you call `Accounts.get_user!(id)`.

#### B. `lib/cuetube_web/` (The Front of House)

This is the "Dining Room". It handles web requests, renders HTML, and deals with the user.

- **Examples:** `controllers`, `live` (LiveViews), `components` (UI widgets), `router.ex`.
- **Key Rule:** The Web layer calls the Business layer. The Business layer _never_ calls the Web layer.

### 3. `priv/repo/migrations` (The Blueprint Archive)

This is where your database structure is defined. Unlike Drizzle where you might define schemas and push, Ecto uses specific migration files to alter the DB step-by-step.

---

## The Language: Elixir in a Nutshell

Elixir looks like Ruby but acts like... functional magic.

1.  **Everything is Immutable:** You can't change a variable.

    ```elixir
    # React/JS
    let count = 1;
    count = 2; // Mutated!

    # Elixir
    count = 1
    new_count = count + 1 # count is still 1
    ```

2.  **The Pipe Operator `|>`:** This is the best thing ever. It passes the result of the previous function as the _first argument_ of the next function.

    ```elixir
    # Nested (Hard to read)
    serve(cook(chop(onion)))

    # Pipe (Chef's kiss)
    onion
    |> chop()
    |> cook()
    |> serve()
    ```

3.  **Pattern Matching:** The `=` sign isn't just assignment; it's a match.
    ```elixir
    {:ok, user} = Accounts.create_user(params)
    # If create_user returns {:error, ...}, this line CRASHES (or raises).
    # It forces you to handle success/failure explicitly.
    ```

---

## Your First Mission

Open `lib/cuetube_web/router.ex`. This is the Maître D'. It greets every request and decides where it sits. We'll explore that next.

<div style="page-break-after: always;"></div>

# Part 2: The Vault (Data & Ecto)

In your old stack, you used **Drizzle**. Here, we use **Ecto**.
Ecto is not just an ORM; it's a data mapping and validation toolkit. It separates "Data Representation" (Schemas) from "Database Interaction" (Repo).

## The Schema: `lib/cuetube/accounts/user.ex`

Open this file. This defines what a "User" looks like in Elixir struct form.

```elixir
defmodule Cuetube.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :handle, :string
    # ... other fields
    has_many :playlists, Cuetube.Library.Playlist

    timestamps()
  end
```

### What's happening?

1.  **`schema "users"`**: Maps this module to the `users` table in Postgres.
2.  **`field`**: Defines the properties. Note that `:string` covers `varchar`, `text`, etc.
3.  **`has_many`**: Defines the relationship. A user has many playlists.

## The Bouncer: Changesets

Below the schema, you'll usually see a `changeset` function. This is unique to Ecto.
In many frameworks, you validate data in the controller or a separate validator. In Ecto, **validation happens on the data structure itself**.

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :handle, ...])
  |> validate_required([:email])
  |> unique_constraint(:email)
end
```

- **`cast`**: "I accept these fields from the outside world (forms/API) and map them to the struct." safely.
- **`validate_...`**: Runs logic checks (length, format).
- **`unique_constraint`**: Checks the _database_ index to ensure uniqueness (no race conditions!).

## The Repo & The Context

Ecto splits the definition (`User`) from the action (`Repo`).
To save a user, you don't do `user.save()`. You do `Repo.insert(user)`.

However, in a Phoenix app, we wrap these raw Repo calls in a **Context**.
Look at `lib/cuetube/accounts.ex`.

```elixir
defmodule Cuetube.Accounts do
  alias Cuetube.Repo
  alias Cuetube.Accounts.User

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
```

### Why Contexts?

It creates a **Public API** for your domain.

- Your web controllers don't need to know _how_ to build a user changeset or which Repo functions to call.
- They just call `Accounts.create_user(params)`.
- If you swap Postgres for something else later, or add complex logic (like sending a welcome email on creation), you change it _here_, not in every controller.

## Summary

- **Schema (`User`)**: Defines the shape of data.
- **Changeset**: Validates and prepares data for the DB.
- **Repo**: Talks to the database.
- **Context (`Accounts`)**: The friendly manager that coordinates everything.

<div style="page-break-after: always;"></div>

# Part 3: The Traffic Controller (Router & Request)

The file `lib/cuetube_web/router.ex` is the central nervous system of your web layer.

## The Pipeline (The Assembly Line)

Web requests are just data. Phoenix treats a request (called `conn` for connection) as a struct that gets passed through a series of functions. Each function modifies it slightly. This is called a **Pipeline**.

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :put_root_layout, html: {CuetubeWeb.Layouts, :root}
  plug CuetubeWeb.UserAuth, :fetch_current_user
end
```

1.  **`plug :accepts`**: "I only speak HTML here."
2.  **`plug :fetch_session`**: "Go get the cookie jar."
3.  **`plug :fetch_current_user`**: This is custom! It looks at the session, finds the `user_token`, looks up the user in the DB, and assigns it to `conn.assigns.current_user`. Now _every_ page knowns who is logged in.

## Scopes (The VIP Sections)

Scopes group routes together and apply pipelines to them.

```elixir
scope "/", CuetubeWeb do
  pipe_through :browser

  live_session :public, on_mount: [{CuetubeWeb.UserAuth, :mount_current_user}] do
    live "/", HomeLive
  end

  live_session :authenticated, on_mount: [{CuetubeWeb.UserAuth, :ensure_authenticated}] do
    live "/dashboard", DashboardLive
  end
end
```

### What is `live_session`?

This is crucial for LiveView.
When you navigate between pages in a `live_session`, the connection **stays open**. It's super fast.

- **:public**: Anyone can be here. We run `:mount_current_user` just to check _if_ they are logged in, but we don't kick them out if they aren't.
- **:authenticated**: The Bouncer. We run `:ensure_authenticated`. If they aren't logged in, this plug halts the request and redirects them to login.

## The "Verified Routes" (~p)

You might see this weird syntax: `~p"/dashboard"`.
This is a **sigil** (like regex `~r/.../`). It checks your routes at **compile time**.

- **Good:** `~p"/thumbnails/#{video_id}"` -> interpolates the ID and ensures the route exists.
- **Bad:** `~p"/thumnails/#{id}"` -> **COMPILER ERROR!** (Typo detected).

In React, you often have broken links that you only find when you click them. In Phoenix, if you change a route in `router.ex` but forget to update a link, the app won't even compile.

## The "Dead" View vs. LiveView

You'll see some routes use `get` (standard HTTP) and some use `live` (LiveView).

- **`get "/auth/:provider", AuthController, :request`**: This is a standard HTTP request. It hits the server, the server renders HTML (or redirects), and the connection closes. Used for OAuth because OAuth requires full page redirects.
- **`live "/dashboard", DashboardLive`**: This loads a page, then establishes a WebSocket. It stays alive.

## The Auth Flow (OAuth)

1.  User clicks "Login with Google".
2.  Router hits `AuthController.request` -> redirects to Google.
3.  Google redirects back to `AuthController.callback`.
4.  Controller grabs the user info, finds/creates the user in `Accounts`, puts the user ID in the session, and redirects to `/dashboard`.
5.  User hits `/dashboard`. The `live_session :authenticated` sees the ID in the session and lets them in.

<div style="page-break-after: always;"></div>

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

<div style="page-break-after: always;"></div>

# Part 5: The Face (UI & Components)

Your app uses **Tailwind CSS** and **HEEx** (HTML + EEx).

## HEEx (HTML + Elixir)

The `~H` syntax is strict. It forces you to write valid HTML.

- **Interpolation:** Use `{ @variable }` (Phoenix 1.8+) or `<%= @variable %>` to output data.
- **Attributes:** `<div class={@my_class}>` allows dynamic values.

## Core Components (`lib/cuetube_web/components/core_components.ex`)

This file is a goldmine. It contains reusable UI elements like `input`, `modal`, `table`, and `button`.
It's generated by Phoenix but you own it. You can change the Tailwind classes here to change the look of your _entire_ app.

### Anatomy of a Component

```elixir
attr :variant, :string, default: "primary" # Props definition
attr :class, :any, default: nil
slot :inner_block, required: true         # Children

def button(assigns) do
  ~H"""
  <button class={[
    "btn",
    @variant == "primary" && "btn-primary",
    @class
  ]}>
    {render_slot(@inner_block)}
  </button>
  """
end
```

- **`attr`**: Defines what props the component accepts. It's like TypeScript interfaces for your templates.
- **`slot`**: Where the children go. `<.button>Click Me</.button>` -> "Click Me" goes into `inner_block`.

### Usage

In your LiveViews, you use them with a dot prefix:

```html
<.button variant="secondary" phx-click="cancel">
  Cancel
</.button>
```

## DaisyUI

Your `assets/css/app.scss` imports DaisyUI (via the config). This gives you classes like `btn`, `card`, `input`.
You don't need to write 50 utility classes for a button. `class="btn btn-primary"` does the heavy lifting.

## Layouts

`lib/cuetube_web/components/layouts/root.html.heex` is the skeleton (`<html>`, `<head>`, `<body>`).
`lib/cuetube_web/components/layouts/app.html.heex` is the wrapper for your main content (Navigation bar, Flash messages).

When `DashboardLive` renders, it's injected _inside_ `app.html.heex`, which is inside `root.html.heex`.

<div style="page-break-after: always;"></div>

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
