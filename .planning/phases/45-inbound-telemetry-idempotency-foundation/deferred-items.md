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
