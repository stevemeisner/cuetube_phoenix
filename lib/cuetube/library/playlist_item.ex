defmodule Cuetube.Library.PlaylistItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playlist_items" do
    field :youtube_video_id, :string
    field :title, :string
    field :position, :integer
    field :notes, :string
    field :tags, {:array, :string}
    field :thumbnail_url, :string
    field :timestamp_start, :integer
    field :timestamp_end, :integer
    field :search_vector, :any, virtual: true

    belongs_to :playlist, Cuetube.Library.Playlist
  end

  @doc false
  def changeset(playlist_item, attrs) do
    playlist_item
    |> cast(attrs, [
      :youtube_video_id,
      :title,
      :position,
      :notes,
      :tags,
      :thumbnail_url,
      :timestamp_start,
      :timestamp_end
    ])
    |> validate_required([:youtube_video_id, :title, :position])
  end
end
