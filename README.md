# nquery

Metabase-like BI analytics for Rails — mountable engine gem.

## What this is

- **`lib/` + `app/`** — the gem (mount in any Rails app)
- **`server/`** — thin demo app to run the UI locally without Ruby on your machine
- **Docker + Makefile** — local dev only (MVP)

## Quick start (no Ruby required)

```bash
cp .env.example .env
make setup
make up
```

Open http://localhost:3000 — login: `admin@nquery.dev` / `password123`

## Dev commands

| Command | Description |
|---------|-------------|
| `make up` | Start server + PostgreSQL |
| `make setup` | Build image, migrate, seed |
| `make test` | Run RSpec |
| `make console` | Rails console |

## Use as a gem (in a Rails app)

```ruby
# Gemfile
gem "nquery"

# config/routes.rb
mount Nquery::Engine, at: "/nquery"
```

```bash
rails generate nquery:install
rails db:migrate
```

## License

MIT
