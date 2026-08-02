# Agent instructions

Follow the **[Ruby on Rails codebase guide for AI agents](https://github.com/rails/rails/blob/main/AGENTS.md)** for general Rails conventions where they apply. **This project uses RSpec** under `spec/` (not Rails core’s Minitest layout). Prefer Docker/`make` for Ruby CLI (see below).

## Development rules (mandatory)

When **planning** or **implementing** features:

1. Follow [`.cursor/rules/development-principles.mdc`](.cursor/rules/development-principles.mdc) (always-on).
2. Follow layer/topic rules in [`.cursor/rules/`](.cursor/rules/) — see [`rails-overview.mdc`](.cursor/rules/rails-overview.mdc) for the full index. Rules load automatically when editing matching files (`models`, `controllers`, `services`, `testing`, etc.).
3. Run Ruby/RSpec/bundle **inside Docker** when using the Makefile path (see below).

## Ruby / Rails CLI: Docker preferred (mandatory for agents)

**Mandatory for LLMs / automation:** do **not** run **`ruby`**, **`bundle`**, **`rails`**, **`rake`**, or **`rspec`** on the host when Docker is available. Use the **`nquery`** Compose service so the interpreter matches the image.

Prefer Makefile targets:

| Command | Description |
|---------|-------------|
| `make up` | Build/start demo app (migrate + seed via `bin/dev`) |
| `make setup` | Migrate and seed (requires running `nquery` service) |
| `make tests` | Run RSpec via `docker compose exec` (requires running `nquery` service) |
| `make console` | Rails console (demo `server/`; requires running `nquery` service) |
| `make bash` | Shell in a running `nquery` container |

Makefile targets use `docker compose exec nquery` so they run in the existing container (e.g. the one serving http://127.0.0.1:3000), not a new one-off service.

```bash
docker compose exec nquery bash -lc "cd /app && bundle exec rspec"
docker compose exec nquery bash -lc "cd server && bundle exec rails db:migrate"
make tests
```

### Reuse the running stack

1. **Before** starting Compose, check whether the app is already up (`docker compose ps`, or `curl` on http://127.0.0.1:3000).
2. If it is serving, **do not** start another `docker compose up` for the same work.
3. Start Compose (`make up`) when containers are stopped — `make tests` / `make console` / `make setup` require the `nquery` service to be running.

Git commands run on the **host** (outside the container).

## Git

- Work on a **feature branch**; open a PR. Do **not** push to `main` unless the user explicitly asks.
- Prefer commit messages that reference issues when applicable (e.g. `Fix #2: …`).

## Schema

- **Never hand-edit** `db/schema.rb` / `server/db/schema.rb`. Add a migration and run it so Rails regenerates the schema.
- Never edit a migration that has already been applied — create a new migration.

## Project layout

- `lib/` + `app/` — mountable engine gem
- `server/` — thin demo Rails app (SQLite)
- `spec/` — RSpec for the gem
- Host apps install nquery migrations into their own DB

## Rails-style conventions

- Prefer `# frozen_string_literal: true` on new Ruby files.
- Clear, intention-revealing names; match existing patterns in the file you edit.
- Co-locate specs with the layer changed (`spec/models`, `spec/requests`, `spec/lib`, …).
- When changing configurable behavior, test **default and explicit overrides**.
- For temporary class-level config in specs, prefer `Object#with` over manual save/restore.

## Devise (engine)

Authentication is **Devise-only** (`Nquery::User` + engine `devise_for`). Do **not** mutate global Devise settings (`parent_controller`, Warden `failure_app`, `navigational_formats`, mailer) from the engine — use per-mapping `devise_for` options (`router_name: :nquery`, `sign_out_via`, custom sessions controller) and `User#send_devise_notification`. Stock `Devise::FailureApp` with `router_name: :nquery` preserves the engine mount prefix on unauthenticated redirects.

## RSpec: Better Specs

Follow **[Better Specs](https://www.betterspecs.org/)**:

- Precise `describe` (`.method` / `#method`); `context` starting with *when* / *with* / *without*
- Short `it` descriptions; one behavior per example
- Request specs over controller specs
- Prefer `expect(...).to` over `should`

Run: `make tests`.

## Human contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution workflow (issues, PRs, checklist).
