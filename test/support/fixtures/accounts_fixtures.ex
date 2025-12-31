defmodule Cuetube.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cuetube.Accounts` context.
  """

  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "some email#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique user google_id.
  """
  def unique_user_google_id, do: "some google_id#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique user handle.
  """
  def unique_user_handle, do: "some handle#{System.unique_integer([:positive])}"

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        avatar_url: "some avatar_url",
        display_name: "some display_name",
        email: unique_user_email(),
        google_id: unique_user_google_id(),
        handle: unique_user_handle()
      })
      |> Cuetube.Accounts.create_user()

    user
  end
end
