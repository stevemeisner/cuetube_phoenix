defmodule Cuetube.Repo do
  use Ecto.Repo,
    otp_app: :cuetube,
    adapter: Ecto.Adapters.Postgres
end
