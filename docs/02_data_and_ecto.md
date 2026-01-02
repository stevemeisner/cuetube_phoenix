# Part 2: The Vault (Data & Ecto)

In your old stack, you used **Drizzle**. Here, we use **Ecto**.
Ecto is not just an ORM; it's a data mapping and validation toolkit. It separates "Data Representation" (Schemas) from "Database Interaction" (Repo).

## The Schema: `lib/cuetube/accounts/user.ex`

Open this file. This defines what a "User" looks like in Elixir struct form.

```elixir
defmodule Cuetube.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :handle, :string
    # ... other fields
    has_many :playlists, Cuetube.Library.Playlist

    timestamps()
  end
```

### What's happening?

1.  **`schema "users"`**: Maps this module to the `users` table in Postgres.
2.  **`field`**: Defines the properties. Note that `:string` covers `varchar`, `text`, etc.
3.  **`has_many`**: Defines the relationship. A user has many playlists.

## The Bouncer: Changesets

Below the schema, you'll usually see a `changeset` function. This is unique to Ecto.
In many frameworks, you validate data in the controller or a separate validator. In Ecto, **validation happens on the data structure itself**.

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :handle, ...])
  |> validate_required([:email])
  |> unique_constraint(:email)
end
```

- **`cast`**: "I accept these fields from the outside world (forms/API) and map them to the struct." safely.
- **`validate_...`**: Runs logic checks (length, format).
- **`unique_constraint`**: Checks the _database_ index to ensure uniqueness (no race conditions!).

## The Repo & The Context

Ecto splits the definition (`User`) from the action (`Repo`).
To save a user, you don't do `user.save()`. You do `Repo.insert(user)`.

However, in a Phoenix app, we wrap these raw Repo calls in a **Context**.
Look at `lib/cuetube/accounts.ex`.

```elixir
defmodule Cuetube.Accounts do
  alias Cuetube.Repo
  alias Cuetube.Accounts.User

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
```

### Why Contexts?

It creates a **Public API** for your domain.

- Your web controllers don't need to know _how_ to build a user changeset or which Repo functions to call.
- They just call `Accounts.create_user(params)`.
- If you swap Postgres for something else later, or add complex logic (like sending a welcome email on creation), you change it _here_, not in every controller.

## Summary

- **Schema (`User`)**: Defines the shape of data.
- **Changeset**: Validates and prepares data for the DB.
- **Repo**: Talks to the database.
- **Context (`Accounts`)**: The friendly manager that coordinates everything.
