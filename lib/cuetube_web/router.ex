defmodule CuetubeWeb.Router do
  use CuetubeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CuetubeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CuetubeWeb.UserAuth, :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/auth", CuetubeWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  scope "/", CuetubeWeb do
    pipe_through :browser

    get "/avatar/:handle", AvatarController, :show
    get "/thumbnails/:video_id", ThumbnailController, :show

    live_session :public, on_mount: [{CuetubeWeb.UserAuth, :mount_current_user}] do
      live "/", HomeLive
      live "/p/:slug", PlaylistLive
      live "/privacy", LegalLive, :privacy
      live "/terms", LegalLive, :terms
    end

    live_session :authenticated, on_mount: [{CuetubeWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", DashboardLive
      live "/playlists/new", PlaylistNewLive
      live "/playlists/:id/edit", PlaylistEditLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", CuetubeWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:cuetube, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CuetubeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
