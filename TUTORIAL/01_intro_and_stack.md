# Part 1: The Blueprint (Stack & Structure)

Welcome! You've just inherited a high-performance sports car (Elixir/Phoenix) after driving a reliable sedan (React/Node). It feels different, the steering is tighter, and the engine hums a weird tune. Don't worry, we're going to pop the hood.

## The 30,000 Foot View

You came from **React + Node + Neon + Drizzle**.
You are now in **Phoenix LiveView + Elixir + Postgres + Ecto**.

### The Big Shift

In your old stack, you had a "Frontend" (React) and a "Backend" (Node/Express). They lived apart and talked via JSON.
In **Phoenix LiveView**, the "Backend" _renders_ the "Frontend" and keeps a persistent connection open. It's like having the server sit right next to the browser, whispering updates into its ear.

**Why is this cool?**

- **No API Layer:** You don't need to build a REST/GraphQL API just to talk to your own frontend.
- **Speed:** Elixir runs on the BEAM (Erlang VM), designed for massive concurrency. It eats parallel tasks for breakfast.
- **Reliability:** "Let it crash." If a part of your app breaks, it restarts instantly without taking down the whole ship.

---

## The Kitchen (Project Structure)

Let's look at the file structure. Think of your app as a professional kitchen.

### 1. `mix.exs` (The Shopping List)

This is your `package.json`. It defines your app name, version, and most importantly, your **dependencies** (`deps`).

- **You'll see:** `{:phoenix, ...}`, `{:ecto, ...}`, `{:req, ...}`.
- **Command:** `mix deps.get` (like `npm install`).

### 2. `lib/` (The Recipes)

This is where _all_ your code lives. It's split into two main folders:

#### A. `lib/cuetube/` (The Business Logic)

This is the "Back of House". It's where your data, rules, and logic live. It knows _nothing_ about the web, HTML, or HTTP.

- **Examples:** `Accounts` (User users), `Library` (Playlists), `YouTube` (API client).
- **Key Concept:** **Contexts**. You'll see files like `accounts.ex`. This is the _public interface_ for a feature. You don't query the `User` table directly from a controller; you call `Accounts.get_user!(id)`.

#### B. `lib/cuetube_web/` (The Front of House)

This is the "Dining Room". It handles web requests, renders HTML, and deals with the user.

- **Examples:** `controllers`, `live` (LiveViews), `components` (UI widgets), `router.ex`.
- **Key Rule:** The Web layer calls the Business layer. The Business layer _never_ calls the Web layer.

### 3. `priv/repo/migrations` (The Blueprint Archive)

This is where your database structure is defined. Unlike Drizzle where you might define schemas and push, Ecto uses specific migration files to alter the DB step-by-step.

---

## The Language: Elixir in a Nutshell

Elixir looks like Ruby but acts like... functional magic.

1.  **Everything is Immutable:** You can't change a variable.

    ```elixir
    # React/JS
    let count = 1;
    count = 2; // Mutated!

    # Elixir
    count = 1
    new_count = count + 1 # count is still 1
    ```

2.  **The Pipe Operator `|>`:** This is the best thing ever. It passes the result of the previous function as the _first argument_ of the next function.

    ```elixir
    # Nested (Hard to read)
    serve(cook(chop(onion)))

    # Pipe (Chef's kiss)
    onion
    |> chop()
    |> cook()
    |> serve()
    ```

3.  **Pattern Matching:** The `=` sign isn't just assignment; it's a match.
    ```elixir
    {:ok, user} = Accounts.create_user(params)
    # If create_user returns {:error, ...}, this line CRASHES (or raises).
    # It forces you to handle success/failure explicitly.
    ```

---

## Your First Mission

Open `lib/cuetube_web/router.ex`. This is the Maître D'. It greets every request and decides where it sits. We'll explore that next.
