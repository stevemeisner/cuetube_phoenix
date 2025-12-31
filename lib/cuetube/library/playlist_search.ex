defmodule Cuetube.Library.PlaylistSearch do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:playlist_id, :id, autogenerate: false}
  schema "playlist_search" do
    belongs_to :playlist, Cuetube.Library.Playlist, define_field: false
    # Handled by raw SQL / fragments
    field :search_vector, :any, virtual: true

    timestamps(inserted_at: false, updated_at: :updated_at, type: :utc_datetime)
  end

  @doc false
  def changeset(playlist_search, attrs) do
    playlist_search
    |> cast(attrs, [:playlist_id, :updated_at])
    |> validate_required([:playlist_id])
  end
end
