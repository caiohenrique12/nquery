.PHONY: up down restart debug setup test console bash shell

up: ## Migrate, seed, and start app
	docker compose up

down: ## Stop all services and remove orphans
	docker compose down --remove-orphans

restart: down up ## Stop and restart all services

debug: ## Start app with Ruby debugger (attach on port 12345)
	docker compose -f docker-compose.yml -f docker-compose.debug.yml up --build

setup: ## Migrate and seed without starting server
	docker compose run --rm nquery bin/setup

tests: ## Run RSpec
	docker compose run --rm nquery bash -lc "cd /app && bundle exec rspec"

coverage: ## Run RSpec with SimpleCov report (output in coverage/)
	docker compose run --rm nquery bash -lc "cd /app && bundle exec rspec"

console: ## Rails console
	docker compose run --rm nquery bash -lc "cd server && bundle exec rails console"

bash: ## Bash inside nquery container
	docker compose exec nquery bash

shell: bash ## Alias for bash
