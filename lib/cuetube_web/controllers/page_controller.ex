defmodule CuetubeWeb.PageController do
  use CuetubeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
