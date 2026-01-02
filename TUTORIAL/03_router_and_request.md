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
