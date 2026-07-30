# mailglass — Docker launchers
#
# Two stacks, fully isolated from each other:
#   `make demo`      — the click-around dashboard. Walkthrough: guides/run-the-demo.md
#   `make toolchain` — the suite on the GATING Elixir 1.18.4 / OTP 27 toolchain.
#                      Walkthrough: CONTRIBUTING.md "Verifying on the gating toolchain"
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

# --- Gating-toolchain harness (Elixir 1.18.4 / OTP 27) ---------------------
#
# Every gating CI lane runs 1.18.4/OTP 27; maintainer machines are routinely on
# a newer line. `make toolchain` runs any command on the gating toolchain, on a
# 2-vCPU container that matches the GitHub-hosted runner, so timing-sensitive
# bounds measured locally predict the CI clock. See CONTRIBUTING.md.
#
# The demo stack owns COMPOSE_PROJECT_NAME above, so the toolchain targets set
# their own per-invocation — never share a namespace with the demo.
MAILGLASS_TOOLCHAIN_CPUS    ?= 2
MAILGLASS_TOOLCHAIN_MEM     ?= 4g
MAILGLASS_TOOLCHAIN_DB_PORT ?= 5416
MAILGLASS_SCHEMA            ?= public

# The command `make toolchain` runs inside the container. Default mirrors the
# "Run advisory full suite" step of .github/workflows/advisory-matrix.yml.
CMD ?= mix test --warnings-as-errors --exclude requires_workspace

# Deliberately NOT `export`ed at file scope: these are set on the compose
# invocation itself, so `make ci` / `make demo` / any future target keeps the
# environment it had before this harness existed. In particular MAILGLASS_SCHEMA
# stays unset for every non-toolchain target, which is what config/runtime.exs
# treats as "use the config/test.exs pin".
TOOLCHAIN := COMPOSE_PROJECT_NAME=mailglass-toolchain \
	MAILGLASS_TOOLCHAIN_CPUS=$(MAILGLASS_TOOLCHAIN_CPUS) \
	MAILGLASS_TOOLCHAIN_MEM=$(MAILGLASS_TOOLCHAIN_MEM) \
	MAILGLASS_TOOLCHAIN_DB_PORT=$(MAILGLASS_TOOLCHAIN_DB_PORT) \
	MAILGLASS_SCHEMA=$(MAILGLASS_SCHEMA) \
	docker compose -f compose.toolchain.yml

# Every toolchain command is prefixed with this bootstrap:
#   1. prove the container really is the toolchain `.tool-versions` pins —
#      otherwise a green run here is evidence about nothing;
#   2. fetch deps into the container-private volume;
#   3. drop + recreate the test DB. Not optional — a suite that passes against
#      a stale schema has not proven anything
#      (see .planning/phases/143-test-harness-truth).
TOOLCHAIN_BOOTSTRAP := sh scripts/assert_gating_toolchain.sh \
	&& mix deps.get \
	&& until pg_isready -h "$$POSTGRES_HOST" -U postgres -d postgres >/dev/null 2>&1; do sleep 1; done \
	&& mix ecto.drop -r Mailglass.TestRepo --quiet \
	&& mix ecto.create -r Mailglass.TestRepo --quiet

.DEFAULT_GOAL := help
.PHONY: help demo demo-down demo-clean demo-reset demo-e2e demo-logs ci ci-fast ci-browser \
        toolchain toolchain-shell toolchain-version toolchain-down toolchain-clean

help: ## List the available commands
	@printf '\nmailglass — demo dashboard and gating-toolchain runner, one command each.\n\n'
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@printf '\nOverride ports to run several demos at once:\n'
	@printf '  make demo MAILGLASS_DEMO_HTTP_PORT=4025 MAILGLASS_DEMO_DB_PORT=5425\n'
	@printf '\nRun one file on the gating toolchain (Elixir 1.18.4 / OTP 27):\n'
	@printf "  make toolchain MAILGLASS_SCHEMA=mailglass CMD='mix test path/to_test.exs --seed 1'\n\n"

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

toolchain: ## Run the suite on the gating toolchain (override CMD=... / MAILGLASS_SCHEMA=...)
	@printf '→ Elixir 1.18.4 / OTP 27, %s vCPU, schema %s\n' "$(MAILGLASS_TOOLCHAIN_CPUS)" "$(MAILGLASS_SCHEMA)"
	@$(TOOLCHAIN) run --rm --build toolchain sh -lc '$(TOOLCHAIN_BOOTSTRAP) && $(CMD)'

toolchain-shell: ## Interactive shell on the gating toolchain (deps + fresh test DB ready)
	@$(TOOLCHAIN) run --rm --build toolchain sh -lc '$(TOOLCHAIN_BOOTSTRAP) && exec bash'

toolchain-version: ## Print the toolchain the container actually runs (proves the pin)
	@$(TOOLCHAIN) run --rm --build --no-deps toolchain sh -lc 'elixir --version'

toolchain-down: ## Stop the toolchain Postgres (keeps deps/build volumes)
	@$(TOOLCHAIN) down --remove-orphans

toolchain-clean: ## Stop and drop all toolchain volumes (reset after a version bump)
	@$(TOOLCHAIN) down -v --remove-orphans
