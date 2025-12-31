defmodule CuetubeWeb.AvatarController do
  use CuetubeWeb, :controller
  alias Cuetube.Accounts

  def show(conn, %{"handle" => handle}) do
    user = Accounts.get_user_by_handle(handle)

    initials =
      if user do
        user.display_name
        |> String.split()
        |> Enum.map(&String.at(&1, 0))
        |> Enum.take(2)
        |> Enum.join()
        |> String.upcase()
      else
        handle |> String.at(0) |> String.upcase()
      end

    case user && user.avatar_url do
      nil ->
        render_placeholder(conn, initials)

      avatar_url ->
        if is_allowed_avatar_url(avatar_url) do
          proxy_avatar(conn, avatar_url, initials)
        else
          render_placeholder(conn, initials)
        end
    end
  end

  defp render_placeholder(conn, initials) do
    svg = """
    <svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
      <defs>
        <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="#e2e8f0"/>
          <stop offset="1" stop-color="#cbd5e1"/>
        </linearGradient>
      </defs>
      <rect width="96" height="96" rx="48" fill="url(#g)"/>
      <text x="48" y="54" text-anchor="middle" font-family="sans-serif" font-size="32" font-weight="700" fill="#334155">#{initials}</text>
    </svg>
    """

    conn
    |> put_resp_content_type("image/svg+xml")
    |> put_resp_header("cache-control", "public, max-age=300")
    |> send_resp(200, svg)
  end

  defp proxy_avatar(conn, url, initials) do
    case Req.get(url, headers: [{"user-agent", "Mozilla/5.0"}]) do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        content_type = Map.get(headers, "content-type") |> List.first() || "image/jpeg"

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("cache-control", "public, max-age=3600")
        |> send_resp(200, body)

      _ ->
        render_placeholder(conn, initials)
    end
  end

  defp is_allowed_avatar_url(url) do
    uri = URI.parse(url)
    uri.scheme == "https" &&
      (uri.host == "lh3.googleusercontent.com" || String.ends_with?(uri.host || "", ".googleusercontent.com"))
  end
end
