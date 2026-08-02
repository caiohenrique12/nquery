# nquery

SQL charts, dashboards, and data visualization for Rails — a mountable engine gem.

nquery lets a host Rails app expose a self-contained analytics UI. It:

* Ships as a Rails engine you mount at a path (for example `/nquery`)
* Provides query builders, charts, dashboards, collections, groups, and permissions
* Provisions groups and data sources via `rails nquery:setup`
* Creates the first administrator through a one-time onboarding wizard (no public signup)

## Table of contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [What `nquery:setup` does](#what-nquerysetup-does)
  - [After onboarding](#after-onboarding)
- [Configuration](#configuration)
- [Authentication](#authentication)
- [First admin onboarding](#first-admin-onboarding)
- [Mail and SMTP](#mail-and-smtp)
- [Data sources](#data-sources)
- [Active Storage](#active-storage)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Requirements

* Ruby `>= 3.2`
* Rails `>= 7.1`, `< 9`
* Active Storage (for organization logo / cover uploads)

## Installation

Install the gem and add it to your application's Gemfile by executing:

```bash
bundle add nquery
```

If Bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install nquery
```

Or add it manually:

```ruby
# Gemfile
gem "nquery"
```

```bash
bundle install
```

Then run the install generator and complete setup:

```bash
rails generate nquery:install
rails active_storage:install   # required for organization logo/cover
rails db:migrate               # engine migrations load from the gem
rails nquery:setup
```

Mount the engine in `config/routes.rb`:

```ruby
mount Nquery::Engine, at: "/nquery"
```

Edit `config/initializers/nquery.rb` to set `mailer_sender` and `smtp` (required for confirmation email). Visit `/nquery` and complete the [first admin onboarding](#first-admin-onboarding) wizard.

| Task | When to use | Creates users? | Creates demo charts? |
|------|-------------|----------------|----------------------|
| `rails nquery:setup` | Host / production install | No | No |
| `rails nquery:seed` | Local demo only (`make up`) | Yes | Yes |

Prefer `nquery:setup` in host apps. `nquery:seed` calls setup first, then adds sample content for the Docker demo.

## Usage

### What `nquery:setup` does

`Nquery::Setup.run!` (invoked by `rails nquery:setup`) is idempotent and safe to re-run. It:

1. Ensures system groups `administrators` and `all_users`
2. Syncs `config.data_sources` into `Nquery::DataSource` rows (via `Nquery::DataSources::Syncer`)
3. Ensures the root collection (`Our analytics`)
4. Seeds default collection, data, and application permissions for those groups

It intentionally does **not** create an organization, users, or demo charts. Those belong to onboarding (first admin) or `nquery:seed` (demo only).

### After onboarding

1. Sign in at `/nquery/login` (or your mount path + `/login`)
2. Browse **Collections**, build queries/charts, assemble dashboards
3. Manage **Users**, **Groups**, **Permissions**, and **Data sources** as an admin

Default permissions from setup give administrators full application features and query access on the default data source; `all_users` gets view-oriented defaults on the root collection.

## Configuration

`rails generate nquery:install` copies `config/initializers/nquery.rb`. Example:

```ruby
Nquery.configure do |config|
  config.mailer_sender = "noreply@example.com"
  config.smtp = {
    address: "smtp.example.com",
    port: 587,
    domain: "example.com",
    user_name: "smtp-user",
    password: "smtp-password",
    authentication: :plain,
    enable_starttls_auto: true
  }

  config.data_sources = {
    main: { adapter: :rails, name: "Application database" }
  }
  config.default_data_source = :main
end
```

| Option | Default | Description |
|--------|---------|-------------|
| `mailer_sender` | `nil` | From address for Devise / app mail |
| `smtp` | `{}` | Passed to `ActionMailer::Base.smtp_settings` when present |
| `data_sources` | `{ main: { adapter: :rails, name: "Application database" } }` | Identity-only map of configured sources |
| `default_data_source` | `:main` | Key of the default source used by setup permissions |
| `query_timeout` | `15` | Query timeout (seconds) |
| `query_row_limit` | `10_000` | Max rows returned by a query |
| `embed_secret` | `nil` | Override for embed token signing (falls back to `secret_key_base`) |

**Not supported in config:** storing database credentials for data sources, SSO/hybrid auth hooks, or public self-registration.

## Authentication

Authentication is handled by [Devise](https://github.com/heartcombo/devise) end-to-end:

* **Sessions** — `Devise::SessionsController` (sign in / sign out via Warden)
* **Passwords** — Devise `:database_authenticatable` + `:validatable` on `Nquery::User`
* **Confirmation** — Devise `:confirmable` (first admin sets a password from the confirmation link; tokens expire after 3 days)

There is **no** public signup route (`:registerable` is not enabled). Password reset (`:recoverable`) and remember-me (`:rememberable`) are not enabled. The first admin is created through [onboarding](#first-admin-onboarding); additional users are invited by an administrator under **Admin → Users** (confirmation email; invitee sets their password via the confirmation link).

Login and logout use Devise routes (`/login`, `/logout`) backed by Warden. Authentication is Devise-only; custom session cookie auth and SSO/hybrid hooks are not supported.

## First admin onboarding

After install + `nquery:setup`, the first person to open the engine creates the organization and the first administrator. There is no seed admin in a production-style install.

### When the wizard runs

Onboarding is required until:

* An `Nquery::Organization` exists
* Onboarding is complete (a confirmed admin exists in `administrators`, or onboarding has been latched via `onboarding_completed_at`)

Until then, visiting the engine redirects into the wizard instead of the normal login page. `nquery:setup` alone never completes onboarding — it only prepares groups and data sources.

### Wizard steps

Paths assume `mount Nquery::Engine, at: "/nquery"`. Drop the `/nquery` prefix when mounted at `/`.

| Step | Path | What the user does | Result |
|------|------|--------------------|--------|
| 1. Company | `GET /nquery/onboarding/company/new` | Name, optional website, logo, cover | Creates `Organization`; advances to admin step |
| 2. Admin | `GET /nquery/onboarding/admin/new` | First name, last name, email | Provisions admin into `administrators` + `all_users`; sends Devise confirmation email |
| 3. Congrats | `GET /nquery/onboarding/congrats` | Read instructions | Explains that a confirmation email was sent |
| 4. Confirm | `GET /nquery/onboarding/confirm?confirmation_token=…` | Choose password | Confirms the user, signs them in, locks the wizard |

### Flow

```text
Visit /nquery
  → Company form
  → Admin form (email + name)
  → Congrats (“check your email”)
  → Open confirmation link
  → Set password
  → Signed in as admin; wizard locked
```

Mail must work for step 2 → 4. If SMTP is misconfigured, the admin user is still created and the wizard continues to congrats with a warning flash — fix mail settings and resend or use the confirmation token before continuing. The Docker demo writes mail to `server/tmp/mail` (`:file` delivery) instead of SMTP.

### After the first admin

* Revisiting onboarding routes redirects away (wizard locked)
* `/signup` is not routed; the login page has no “Create an account” link
* New users: **Admin → Users**

### Checklist before first visit (host app)

1. `rails nquery:setup` succeeded
2. Engine mounted
3. `mailer_sender` + `smtp` configured
4. Action Mailer default URL options set in the host app (so confirmation links resolve)
5. Active Storage installed if you want logo/cover uploads during company setup

## Mail and SMTP

Confirmation mail uses `Nquery::DeviseMailer` and `Nquery.configuration.mailer_sender`.

Also configure the host app’s Action Mailer URL options so links in email are absolute:

```ruby
# config/environments/production.rb (example)
config.action_mailer.default_url_options = { host: "analytics.example.com", protocol: "https" }
```

In development, Letter Opener or `:test` / `:file` delivery works as long as confirmation URLs use a reachable host.

## Data sources

`config.data_sources` describes **identity** for sources that setup syncs into the database:

```ruby
config.data_sources = {
  main: { adapter: :rails, name: "Application database" }
}
config.default_data_source = :main
```

* Keys become the unique `key` on `nquery_data_sources` (e.g. `"main"`)
* For `adapter: :rails`, connection config is empty — nquery uses the host app’s Active Record connection
* Do **not** put database credentials in `Nquery.configure`; external adapters are managed in the admin UI after install
* `Nquery::DataSources::Syncer` ignores credential-like keys if they appear in the hash

After setup, review sources under **Admin → Data sources**.

## Active Storage

Required for organization `logo` and `cover_image` during company onboarding (and later branding):

```bash
rails active_storage:install
rails db:migrate
```

Configure `config.active_storage.service` in each environment (e.g. `:local` in development).

## Development

This repository includes a thin demo Rails app under `server/` (SQLite) for local UI work. Host apps install nquery migrations into their own database; the demo app is for contributors and exploration.

After checking out the repo:

```bash
cp .env.example .env
make up
```

`make up` builds the Docker image, runs migrations, seeds demo data (`nquery:seed`), and starts the server at http://localhost:3000.

| Email | Password |
|-------|----------|
| `admin@nquery.dev` | `password123` |

The demo seeds an organization + confirmed admin so you skip the first-run wizard and can sign in with Devise immediately.

| Command | Description |
|---------|-------------|
| `make up` | Build, migrate, seed, and start the demo server |
| `make setup` | Migrate and seed only (requires a running `nquery` service) |
| `make tests` | Run RSpec via `docker compose exec` (requires running `nquery`) |
| `make console` | Rails console for the demo app |
| `make bash` | Shell inside the `nquery` container |

| Path | Purpose |
|------|---------|
| `lib/` + `app/` | Mountable engine gem |
| `spec/` | RSpec suite for the gem |
| `server/` | Thin demo Rails app |
| Docker + Makefile | Local development (recommended) |

To install this gem onto your local machine from the checkout, use your usual Bundler path / gem build workflow against `nquery.gemspec`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/caiohenrique12/nquery.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow (issue discussion, focused PRs, tests, and development setup). AI / agent contributors should follow [AGENTS.md](AGENTS.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
