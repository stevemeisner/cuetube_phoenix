defmodule Cuetube.Repo.Migrations.SetupSearchExtensions do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"
    execute "CREATE EXTENSION IF NOT EXISTS unaccent"
  end

  def down do
    execute "DROP EXTENSION IF NOT EXISTS pg_trgm"
    execute "DROP EXTENSION IF NOT EXISTS unaccent"
  end
end
