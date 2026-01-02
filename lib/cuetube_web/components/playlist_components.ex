  defp get_collage_thumbnails(%{playlist_items: items}) when is_list(items) do
    items
    |> Enum.map(fn item ->
      cond do
        Map.get(item, :youtube_video_id) ->
          ~p"/thumbnails/#{item.youtube_video_id}"

        url = Map.get(item, :thumbnail_url) ->
          case extract_video_id(url) do
            nil -> url
            id -> ~p"/thumbnails/#{id}"
          end

        true ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.take(4)
    |> pad_thumbnails()
  end

  defp get_collage_thumbnails(%{thumbnail_url: url}) when not is_nil(url) do
    case extract_video_id(url) do
      nil -> [url]
      id -> [~p"/thumbnails/#{id}"]
    end
  end

  defp get_collage_thumbnails(_), do: []

  defp extract_video_id(url) do
    case Regex.run(~r/\/vi\/([^\/]+)\//, url) do
      [_, id] -> id
      _ -> nil
    end
  end

  defp pad_thumbnails(list) when length(list) == 3, do: list ++ [Enum.at(list, 0)]
  defp pad_thumbnails(list), do: list
end
