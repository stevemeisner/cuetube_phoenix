defmodule Cuetube.Library.Playlist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playlists" do
    field :youtube_playlist_id, :string
    field :title, :string
    field :description, :string
    field :slug, :string
    field :thumbnail_url, :string
    field :video_count, :integer
    field :last_synced_at, :utc_datetime
    field :search_vector, :any, virtual: true

    belongs_to :user, Cuetube.Accounts.User
    has_many :playlist_items, Cuetube.Library.PlaylistItem

    timestamps(inserted_at: :created_at, updated_at: false, type: :utc_datetime)
  end

  @doc false
  def changeset(playlist, attrs) do
    playlist
    |> cast(attrs, [
      :youtube_playlist_id,
      :title,
      :description,
      :slug,
      :thumbnail_url,
      :video_count,
      :last_synced_at
    ])
    |> validate_required([
      :youtube_playlist_id,
      :title,
      :description,
      :slug,
      :last_synced_at
    ])
    |> unique_constraint(:slug)
  end
end
