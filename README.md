# nquery

SQL charts, dashboards, and data visualization for Rails — mountable engine gem.

## What this is

- **`lib/` + `app/`** — the gem (mount in any Rails app)
- **`server/`** — thin demo app to run the UI locally (SQLite, no external database)
- **Docker + Makefile** — local dev only (MVP)

## Quick start (no Ruby required)

```bash
cp .env.example .env
make up
```

`make up` builds the image, runs migrations, seeds demo data, and starts the server — no separate seed step needed.

Open http://localhost:3000 — login: `admin@nquery.dev` / `password123`

## Dev commands

| Command | Description |
|---------|-------------|
| `make up` | Build, migrate, seed, and start server |
| `make setup` | Migrate and seed only (without starting server) |
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

## Contributing

Bug reports and pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow we follow (issue discussion, focused PRs, tests, and development setup).

## License

MIT
