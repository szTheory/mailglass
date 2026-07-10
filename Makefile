# mailglass — demo launcher
#
# One command to see mailglass working: `make demo`.
# Full walkthrough: guides/run-the-demo.md
#
# Host ports are configurable so this demo never collides with sibling library
# demos (or anything else on your machine). Override per run, e.g.:
#   make demo MAILGLASS_DEMO_HTTP_PORT=4025 MAILGLASS_DEMO_DB_PORT=5425

MAILGLASS_DEMO_HTTP_PORT ?= 4015
MAILGLASS_DEMO_DB_PORT   ?= 5415
export MAILGLASS_DEMO_HTTP_PORT
export MAILGLASS_DEMO_DB_PORT

# Compose project name = the isolation namespace (containers/networks/volumes).
# Override it together with the ports to run a SECOND, fully independent copy of
# *this* demo at once:
#   make demo COMPOSE_PROJECT_NAME=mailglass-demo-b \
#             MAILGLASS_DEMO_HTTP_PORT=4025 MAILGLASS_DEMO_DB_PORT=5425
COMPOSE_PROJECT_NAME ?= mailglass-demo
export COMPOSE_PROJECT_NAME

COMPOSE := docker compose -f compose.demo.yml
HTTP    := http://localhost:$(MAILGLASS_DEMO_HTTP_PORT)

.DEFAULT_GOAL := help
.PHONY: help demo demo-down demo-clean demo-reset demo-e2e demo-logs ci ci-fast ci-browser

help: ## List the demo commands
	@printf '\nmailglass demo — run the click-around dashboard in one command.\n\n'
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@printf '\nOverride ports to run several demos at once:\n'
	@printf '  make demo MAILGLASS_DEMO_HTTP_PORT=4025 MAILGLASS_DEMO_DB_PORT=5425\n\n'

demo: ## Build, start, and print the demo URLs
	@printf '→ building + starting the demo (first run downloads deps, ~2 min)…\n'
	@$(COMPOSE) up -d --build --wait demo \
		|| { printf '\n✗ demo did not come up healthy. Inspect logs with: make demo-logs\n\n'; exit 1; }
	@printf '\n  mailglass demo is up:\n\n'
	@printf '    Dashboard   %s\n' "$(HTTP)"
	@printf '    Preview     %s/dev/mail\n' "$(HTTP)"
	@printf '    Outbound    %s/demo/login?return_to=/ops/mail?tenant_id=northstar\n' "$(HTTP)"
	@printf '    Inbound     %s/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar\n' "$(HTTP)"
	@printf '\n    Postgres    localhost:%s  (postgres/postgres, db: mailglass_demo_dev)\n' "$(MAILGLASS_DEMO_DB_PORT)"
	@printf '\n  Stop: make demo-down · Reset data: make demo-reset · Browser evidence: make demo-e2e\n\n'

demo-down: ## Stop the demo (keeps cached deps/build volumes for a fast restart)
	@$(COMPOSE) down --remove-orphans

demo-clean: ## Stop and remove all volumes (the reset after an Elixir/base-image bump)
	@$(COMPOSE) down -v --remove-orphans

demo-reset: ## Reseed the deterministic AtlasDesk demo data
	@$(COMPOSE) exec demo mix demo.reset

demo-e2e: ## Run the Playwright browser-evidence suite against the demo
	@$(COMPOSE) run --rm demo_e2e

demo-logs: ## Follow the demo app logs
	@$(COMPOSE) logs -f demo

ci: ## Run the full local↔CI parity suite (needs Postgres + network)
	@MAILGLASS_PATH="$$(pwd)" mix ci

ci-fast: ## Fast static checks only (format + credo + compile). Pre-commit loop.
	@mix ci.fast

ci-browser: ## Opt-in admin browser gate (Node + Playwright)
	@mix ci.browser
