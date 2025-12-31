defmodule CuetubeWeb.UserAuth do
  use CuetubeWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller

  alias Cuetube.Accounts

  def init(opts), do: opts

  def call(conn, :fetch_current_user) do
    fetch_current_user(conn, [])
  end

  def log_in_user(conn, user) do
    conn
    |> renew_session()
    |> put_session(:user_id, user.id)
    |> redirect(to: ~p"/dashboard")
  end

  def log_out_user(conn) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && Accounts.get_user!(user_id)
    assign(conn, :current_user, user)
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    if session["user_id"] do
      {:cont, mount_current_user(socket, session)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_id = session["user_id"] do
        Accounts.get_user!(user_id)
      end
    end)
  end

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
