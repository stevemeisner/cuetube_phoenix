defmodule Cuetube.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :google_id, :string
    field :display_name, :string
    field :handle, :string
    field :avatar_url, :string
    has_many :playlists, Cuetube.Library.Playlist

    timestamps(inserted_at: :created_at, updated_at: false, type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :google_id, :display_name, :handle, :avatar_url])
    |> validate_required([:email, :google_id, :display_name, :handle, :avatar_url])
    |> unique_constraint(:handle)
    |> unique_constraint(:google_id)
    |> unique_constraint(:email)
  end
end
