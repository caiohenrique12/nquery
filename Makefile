.PHONY: up down restart setup test tests ci coverage console bash shell

up: ## Migrate, seed, and start app
	docker compose up

down: ## Stop all services and remove orphans
	docker compose down --remove-orphans

restart: down up ## Stop and restart all services

setup: ## Migrate and seed without starting server (requires running nquery service)
	docker compose exec nquery bin/setup

tests: ## Run RSpec (requires running nquery service)
	docker compose exec nquery bash -lc "cd /app && bundle exec rspec"

ci: ## Full CI suite (same as GitHub Actions; requires running nquery service)
	docker compose exec nquery bash -lc "cd /app && bin/ci"

coverage: ## Run RSpec with SimpleCov report (requires running nquery service)
	docker compose exec nquery bash -lc "cd /app && bundle exec rspec"

console: ## Rails console (requires running nquery service)
	docker compose exec nquery bash -lc "cd server && bundle exec rails console"

bash: ## Bash inside nquery container
	docker compose exec nquery bash

shell: bash ## Alias for bash
