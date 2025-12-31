defmodule Cuetube.Utils.PlaylistInput do
  @moduledoc """
  Utilities for parsing and normalizing YouTube playlist input.
  """

  @doc """
  Extracts the playlist ID from a URL or string.
  """
  def extract_playlist_id(input) do
    input = String.trim(input)

    cond do
      # Full URL with list param
      String.contains?(input, "list=") ->
        case Regex.run(~r/list=([a-zA-Z0-9_-]+)/, input) do
          [_, id] -> id
          _ -> nil
        end

      # Just the ID (usually 34 chars starting with PL)
      Regex.match?(~r/^[a-zA-Z0-9_-]{12,64}$/, input) ->
        input

      true ->
        nil
    end
  end

  @doc """
  Normalizes input by trimming and removing unwanted whitespace.
  """
  def normalize_playlist_input(input) do
    input
    |> String.trim()
    |> String.replace(~r/\s+/, "")
  end

  @doc """
  Provides a hint message based on the input.
  """
  def get_playlist_input_hint(input) do
    id = extract_playlist_id(input)

    if id do
      "Valid playlist ID detected: #{id}"
    else
      nil
    end
  end
end
