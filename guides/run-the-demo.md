# Run the demo

> See mailglass working — the preview, the outbound operator dashboard, and the
> inbound operator dashboard — against realistic seeded data, in one command. No
> Phoenix app of your own required. This is the fastest way to evaluate mailglass
> before you install it, and the way maintainers iterate on the admin UI.

## The short version

You need Docker. From the repo root:

```bash
make demo
```

The first run builds the image and downloads dependencies (about two minutes).
After that it's seconds. When the demo is healthy, it prints the URLs to open:

```
  mailglass demo is up:

    Dashboard   http://localhost:4015
    Preview     http://localhost:4015/dev/mail
    Outbound    http://localhost:4015/demo/login?return_to=/ops/mail?tenant_id=northstar
    Inbound     http://localhost:4015/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar

    Postgres    localhost:5415  (postgres/postgres, db: mailglass_demo_dev)

  Stop: make demo-down · Reset data: make demo-reset · Browser evidence: make demo-e2e
```

Open the Dashboard URL and click around. When you're done, `make demo-down`.

---

## What you're looking at

The demo plays the role of **Northstar Ops** — a B2B SaaS operations team using
mailglass in production. The data is seeded and deterministic, so every screen
has something real to inspect.

| Open | To see |
|---|---|
| **Dashboard** | The operator overview — deliveries, suppressions, and inbound records at a glance. |
| **Preview** (`/dev/mail`) | Rendered mailables with device-width and dark-mode toggles, and HTML / Text / Raw / Headers tabs. This is the dev preview adopters mount in their own app. |
| **Outbound** (`/ops/mail`) | The production operator dashboard: deliveries, their event timelines, bounces, and manual suppressions. |
| **Inbound** (`/ops/mail/inbound`) | Received mail, its routing trace, the matched mailbox, and stored-truth replay. |

The outbound and inbound links route through `/demo/login` first because those
are the *production* operator surfaces, which sit behind auth. The demo logs you
in automatically.

---

## Running several demos at once

This is the reason the demo uses configurable ports.

**Different libraries side by side.** If you're working on more than one Elixir
library — each with its own Dockerized admin UI — they'd otherwise fight over the
same host ports. Each library is its own repo with its own Compose project, so
they're already isolated; you just give each one its own port band. mailglass owns
**4015** (HTTP) and **5415** (Postgres); point your other libraries at 4025/5425,
4035/5435, and so on. Nothing to do here beyond not reusing 4015/5415 elsewhere.

**Two copies of *this* demo at once** (e.g. comparing branches). Override the
project name and the ports together, so the second copy gets its own containers,
volumes, and ports:

```bash
make demo COMPOSE_PROJECT_NAME=mailglass-demo-b \
          MAILGLASS_DEMO_HTTP_PORT=4025 MAILGLASS_DEMO_DB_PORT=5425
```

The printed URLs follow whatever ports you choose. The ports are also bound to
`127.0.0.1`, so the demo and its Postgres are reachable from your machine only —
never the wider network.

To make a port override the default for your checkout, copy `.env.example` to
`.env` and edit it; Docker Compose reads `.env` automatically. You never *need*
to — `make demo` works with no `.env` at all.

---

## Everyday commands

```bash
make            # list every demo command (same as: make help)
make demo       # build, start, and print the URLs
make demo-down  # stop the demo (keeps cached deps for a fast restart)
make demo-reset # reseed the deterministic northstar data
make demo-e2e   # run the Playwright browser-evidence suite
make demo-logs  # follow the app logs
make demo-clean # stop and remove all volumes (full reset)
```

> **`make demo-reset` is destructive.** It truncates the seeded demo tables
> before reseeding preview, delivery, suppression, inbound record, evidence,
> routing trace, and replay data for tenant `northstar`. That's exactly what you
> want to return the demo to a known baseline — just know it clears your clicks.

---

## Why it's fast to iterate

The container mounts your working tree live and keeps dependencies and compiled
build artifacts in named volumes. So when you edit a HEEx template or admin CSS,
the change hot-reloads in place — mailglass does **not** re-download or recompile
its dependencies for a style change. Only the first boot pays the dependency
cost.

The one time to reach for `make demo-clean` is after bumping the Elixir or base
image version: the persisted build volumes are tied to the old toolchain, and a
clean wipe rebuilds them against the new one.

---

## Troubleshooting

**`Error: port is already allocated`** — another process (often a second demo)
holds 4015 or 5415. Pick a different band: `make demo MAILGLASS_DEMO_HTTP_PORT=4025
MAILGLASS_DEMO_DB_PORT=5425`.

**Health never goes green** — `make demo-logs` shows what the app is doing. The
first build legitimately takes a couple of minutes while dependencies download;
after that, a stall usually means Postgres didn't come up — `make demo-clean`
then `make demo` for a fresh start.

**Styles look unstyled after a hard refresh on a deep link** — a known
limitation (admin asset URLs resolve relative to the mount root). Navigate from
the dashboard rather than reloading a deep URL. Tracked as GAP-22.

**`/dev/storybook` returns a 500 (`PhoenixStorybook.Router is not available`)**
— the dev-only component storybook is a live route added with the
`phoenix_storybook` dep. A demo container that was already running from *before*
that dep landed cannot hot-reload the `live_storybook` macro, so the route raises
an `UndefinedFunctionError` until the container is freshly booted. Run `make demo`
(or `docker restart`) once to pick it up. The operator surfaces under `/dev/mail`
hot-reload fine — only the storybook live-route needs the clean boot.

---

The demo lives in `reference/demo_app`. Its DOM, routes, and copy are
illustrative, not stable public API — for the API contract, see
[`docs/api_stability.md`](../docs/api_stability.md). For what mailglass does and
why, start with [`guides/jobs.md`](jobs.md).
