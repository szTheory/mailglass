# Debian bookworm ships Node 18; Playwright 1.65+ needs Node 20 or later.
FROM node:22.23.3-bookworm-slim@sha256:3ed98443660ff48413b5af19ecefce3b9d50845a901a43420d47cc63a9fddbe9 AS node

FROM hexpm/elixir:1.18.4-erlang-27.3.4.13-debian-bookworm-20260623-slim@sha256:ca09419f742ec4040ccb4d9949324f73d3d2c364cacad56686d68d6327eb45f2

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git curl ca-certificates postgresql-client \
  && rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

RUN mix local.hex --force && mix local.rebar --force

COPY reference/demo_app/assets/package*.json /tmp/mailglass-demo-assets/
COPY reference/demo_app/assets/scripts/check-demo-browser-deps.cjs /tmp/mailglass-demo-assets/scripts/
RUN node /tmp/mailglass-demo-assets/scripts/check-demo-browser-deps.cjs --lock-only \
  && npm --prefix /tmp/mailglass-demo-assets ci --no-audit --no-fund \
  && npx --prefix /tmp/mailglass-demo-assets playwright install --with-deps chromium \
  && rm -rf /tmp/mailglass-demo-assets

WORKDIR /workspace/reference/demo_app

CMD ["sh", "-lc", "mix deps.get --check-locked && mix ecto.setup && mix phx.server"]
