# Contributing to nquery

Thank you for considering a contribution. nquery follows the same contribution model used across the Ruby on Rails ecosystem: discuss significant changes first, keep pull requests focused, and include tests.

For general Rails conventions (commit messages, pull request etiquette, and coding style), see the official guide: [Contributing to Ruby on Rails](https://edgeguides.rubyonrails.org/contributing_to_ruby_on_rails.html).

## Did you find a bug?

- **Search existing issues** on GitHub before opening a new one.
- If the bug is a **security vulnerability**, do not open a public issue. Email the maintainers privately instead.
- When reporting a bug, include:
  - A clear title and description
  - Steps to reproduce
  - Expected vs. actual behavior
  - Your environment (Ruby, Rails, database adapter, OS)
  - A failing spec or minimal reproduction, when possible

## Did you write a patch that fixes a bug?

1. Fork the repository and create a branch from `main`.
2. Add or update specs that demonstrate the bug and your fix.
3. Run the test suite (see [Development setup](#development-setup) below).
4. Open a pull request with a clear description of the problem and solution.
5. Reference the related issue in the PR description when one exists.

## Do you intend to add a new feature or change existing behavior?

- **Open an issue first** to describe the problem you are solving and your proposed approach.
- Wait for maintainer feedback before investing in a large change.
- Keep pull requests small and focused on a single concern.

Cosmetic-only changes (formatting, renaming without behavior change) are unlikely to be accepted unless they are part of a substantive fix or agreed-upon cleanup.

## Development setup

You can develop with Docker (recommended) or with Ruby installed locally.

### Docker (recommended)

```bash
cp .env.example .env
make setup
make up
```

Useful commands:

| Command | Description |
|---------|-------------|
| `make up` | Start server + PostgreSQL |
| `make setup` | Build image, migrate, seed |
| `make test` | Run RSpec |
| `make console` | Rails console |
| `make shell` | Bash inside the container |

The demo app runs at http://localhost:3000 (`admin@nquery.dev` / `password123`).

### Local Ruby

Requirements: Ruby >= 3.2, PostgreSQL.

```bash
bundle install
bin/setup
cd server && bundle exec rails server
```

Run tests from the repository root:

```bash
bundle exec rspec
```

## Pull request checklist

Before requesting review, please confirm:

- [ ] Specs pass (`make test` or `bundle exec rspec`)
- [ ] New behavior is covered by specs where appropriate
- [ ] The change is limited to the stated goal (no unrelated refactors)
- [ ] Commit messages are clear and use the imperative mood (e.g. "Fix query timeout for large datasets")
- [ ] The PR description explains **what** changed and **why**

## Project structure

- `lib/` and `app/` — the mountable engine gem
- `server/` — thin demo Rails app for local development
- `spec/` — RSpec tests for the gem

When changing engine code, verify behavior through the demo app when UI or routing is affected.

## Code style

- Match existing patterns in the file you are editing.
- Use `# frozen_string_literal: true` at the top of new Ruby files.
- Prefer small, readable methods over clever abstractions.
- Follow Rails naming and directory conventions for engine code.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
