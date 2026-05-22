# Deferred Items — Phase 45

Out-of-scope discoveries logged during execution. Not fixed in the originating
plan; tracked here for a future cleanup pass.

## 45-01

### Pre-existing `mix format` drift in inbound under Elixir 1.19 / OTP 28 (local toolchain)

- **Found during:** 45-01 Task 3 (format check after the trailing-whitespace fix).
- **What:** `cd mailglass_inbound && mix format --check-formatted` reports several
  inbound `lib/` files as unformatted (e.g.
  `ingress/providers/postmark.ex`, `execution.ex`, `ingress/persist.ex` at
  long-line wrap sites — NOT at any line edited by 45-01).
- **Root cause:** Local dev toolchain is Elixir 1.19.5 / OTP 28, which wraps a
  few long lines differently than Elixir 1.18 / OTP 27. CI's format_check job
  pins Elixir 1.18 / OTP 27 (`.github/workflows/ci.yml`), where these files are
  correctly formatted. Verified the base commit `aaa7758` version of
  `persist.ex` also fails the local format check with zero 45-01 edits, so this
  is pre-existing version drift, not introduced by 45-01.
- **Disposition:** Out of scope for 45-01 (lint/infra plan; the files are
  untouched by it). Do NOT reformat under the 1.19 toolchain — that would churn
  many inbound files and could diverge from the 1.18-formatted CI baseline.
  Revisit if/when the project bumps its supported Elixir/OTP floor to 1.19/28.

## 45-03

### Pre-existing inbound `--no-optional-deps` warning: `Mailglass.Oban.TenancyMiddleware` undefined

- **Found during:** 45-03 Task 3 (running `cd mailglass_inbound && mix compile
  --no-optional-deps --warnings-as-errors`).
- **What:** The inbound standalone no-optional-deps compile warns
  `Mailglass.Oban.TenancyMiddleware.wrap_perform/2 is undefined`, referenced
  from `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex:37` (guarded
  by `Code.ensure_loaded?/1` at runtime). With `--no-optional-deps`, Oban is
  stripped from the core `mailglass` dependency, so the core
  `Mailglass.Oban.TenancyMiddleware` module (which lives under the core Oban
  gateway) is not compiled and the cross-package reference is undefined at
  compile time.
- **Verified pre-existing:** Temporarily removed both 45-03 files
  (`lib/mailglass_inbound/mime.ex`, `lib/mailglass_inbound/mime_error.ex`) and
  re-ran the same compile — the identical warning still fires and the build
  still exits 1. The warning is therefore NOT introduced by 45-03; it is a
  pre-existing cross-package reference in an untouched file (`worker.ex`).
- **Disposition:** Out of scope for 45-03 (the MIME parser does not touch the
  Oban worker seam). The 45-03 code itself adds zero new warnings: the core
  `mix compile --no-optional-deps --warnings-as-errors` (which Task 1's gateway
  change affects) exits 0, and removing the 45-03 files does not clear this
  inbound warning. Likely a local Elixir 1.19/OTP 28 toolchain artifact in the
  worktree; CI pins 1.18/OTP 27 with the proper dependency graph. A targeted
  fix (e.g. adding `Mailglass.Oban.TenancyMiddleware` to the inbound
  `elixirc_options` `no_warn_undefined` list) belongs to an inbound Oban-seam
  plan, not the MIME producer plan.
