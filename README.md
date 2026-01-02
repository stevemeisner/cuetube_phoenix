# Cuetube (PESAL Stack)

Cuetube is a "Playlist Curator" and "Deep Search" tool for YouTube, ported from Remix/React to Phoenix LiveView.

## Tech Stack (PESAL)

- **P**hoenix 1.7+ (LiveView)
- **E**cto (Postgres / Neon)
- **S**ASS (Modular SCSS)
- **A**lpine.js / **L**iveJS (Native Phoenix)

## Key Features

- **Deep Search**: Full-text search using Postgres `tsvector` and weighted rankings.
- **Real-time Suggestions**: Trigram-based fuzzy matching for Playlists, Videos, Curators, and Tags.
- **YouTube Sync**: Lightweight synchronization of YouTube playlists using `Req` and `Ecto.Multi`.
- **Google OAuth**: Integrated authentication via `Ueberauth`.

## Local Development

### Prerequisites

- Elixir 1.19+ / Erlang 28+
- PostgreSQL (or Neon connection string)
- YouTube Data API v3 Key

### Setup

1. Install dependencies:

   ```bash
   mix deps.get
   ```

2. Configure environment variables in `.env` (or your shell):

   ```bash
   export DATABASE_URL="postgres://..."
   export GOOGLE_CLIENT_ID="..."
   export GOOGLE_CLIENT_SECRET="..."
   export YOUTUBE_API_KEY="..."
   ```

3. Setup the database:

   ```bash
   mix ecto.setup
   ```

4. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing

Run the test suite with:

```bash
mix test
```

## Deployment

This project is configured for deployment on **Render** using Docker.

1. Connect your repository to Render.
2. Select "Web Service".
3. Render will automatically use the `render.yaml` and `Dockerfile`.
4. Ensure all environment variables are set in the Render dashboard.

## Full-Text Search Implementation

The search engine leverages Postgres-specific features:

- `websearch_to_tsquery`: For smart user query parsing.
- `ts_rank_cd`: For cover density ranking.
- `pg_trgm`: For fast trigram similarity matching in suggestions.
- `unaccent`: For accent-insensitive searching.

## The Phoenix Field Guide (Tutorial)

New to Elixir/Phoenix? We've written a comprehensive 6-part guide analyzing this exact codebase to help React/Node developers make the switch.

- **[Read the Guide Locally (Markdown)](docs/README.md)**
- **[View the Live Guide (HTML)](https://docs.elixir.cuetube.apps)**
- _[Source Code for Guide](docs/index.html)_
