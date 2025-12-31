defmodule CuetubeWeb.AuthController do
  use CuetubeWeb, :controller
  plug Ueberauth

  alias Cuetube.Accounts

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => "google"}) do
    user_params = %{
      google_id: auth.uid,
      email: auth.info.email,
      display_name: auth.info.name,
      avatar_url: auth.info.image,
      handle: extract_handle(auth)
    }

    case Accounts.find_or_create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> CuetubeWeb.UserAuth.log_in_user(user)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to authenticate.")
        |> redirect(to: ~p"/")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: ~p"/")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> CuetubeWeb.UserAuth.log_out_user()
  end

  defp extract_handle(auth) do
    # Try to get a handle from info, or fallback to email prefix
    auth.info.nickname || auth.info.email |> String.split("@") |> List.first()
  end
end
