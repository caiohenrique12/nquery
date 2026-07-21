.PHONY: up restart setup test console shell

up: ## Start app + db
	docker compose up

restart: ## Restart app + db
	docker compose restart

setup: ## Build, migrate, seed
	docker compose run --rm nquery bin/setup

test: ## Run RSpec
	docker compose run --rm nquery bash -lc "cd /app && bundle exec rspec"

console: ## Rails console
	docker compose run --rm nquery bash -lc "cd server && bundle exec rails console"

shell: ## Bash inside container
	docker compose run --rm nquery bash
