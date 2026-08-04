# Compatibility and Deprecations

This guide is the canonical 2.x compatibility, upgrade, and deprecation policy
for Mailglass.

Use this guide when you need to answer any of these questions:

- Which Mailglass surfaces are the stable default path for 2.x
- Which older surfaces still work only as retained compatibility bridges
- What a patch, minor, or major release may change
- Which runtime, framework, database, and sibling-package combinations the
  repository currently proves

The stability inventories in [`docs/api_stability.md`](../docs/api_stability.md)
and
[`mailglass_admin/docs/api_stability.md`](../mailglass_admin/docs/api_stability.md)
answer a different question: which package surfaces are stable, internal, or
first-party-only. They are not the lifecycle policy by themselves.

For inbound, route compatibility claims through
[`mailglass_inbound/docs/api_stability.md`](../mailglass_inbound/docs/api_stability.md).
That inventory is the canonical stable/internal/deferred source for
`mailglass_inbound`.

## Contract shape

Mailglass keeps a two-lane public posture for the 2.x line:

- `stable lane`:
  [`Mailglass.deliver/2`](https://hexdocs.pm/mailglass/Mailglass.html#deliver/2),
  `deliver!/2`, `deliver_later/2`, `deliver_many/2`, `deliver_many!/2`,
  native `Mailglass.Message` setters such as `to/2`, `from/2`, `subject/2`,
  `html_body/2`, `text_body/2`, `attach/2`, and the escape hatch
  `Mailglass.Message.update_swoosh/2`
- `compatibility lane`: a deliberately small set of retained legacy bridges
  kept to make upgrades practical without promising that every historical path
  remains first-class forever

If you are starting fresh on 2.x, stay on the stable lane. The compatibility
lane exists to help existing adopters land on 2.x without rewriting
everything in one release.

## Stable lane defaults

The stable lane is the path maintainers intend adopters to build on throughout
the 2.x line.

- Delivery entrypoint: `Mailglass.deliver*`
- Message construction: native `Mailglass.Message` setters
- Advanced shaping when setters are not enough:
  `Mailglass.Message.update_swoosh/2`
- Support-contract verification: the repo-native checks under
  `scripts/verify_support_contract.sh`

The stable lane is the only lane that receives an affirmative compatibility
promise across 2.x minor releases.

### Current 2.x schema and payload contract

Fresh installs use the public migration wrapper and the current Mailglass schema;
do not depend on an old table-count claim or copy package migration internals.
Async delivery stores private payload content before enqueuing normal Oban work
on `:mailglass_outbound`, then scrubs successful content according to retention.
There is no public payload reader or legacy metadata reconstruction path. A
missing historical private payload settles as `legacy_payload_missing`, keeps
the public Delivery/Event audit facts, and never invokes an adapter.

## Compatibility lane

The compatibility lane is intentionally small. A retained path stays here only
when the repository still documents a replacement, warning behavior, and a
support horizon.

Examples of retained bridges during the `2.x` transition:

- `Mailglass.Message.new/2`
- `Mailglass.Outbound.send/2`
- delivering a raw `%Swoosh.Email{}`
- the `mix mailglass.upgrade.v0_2` codemod
- deprecated `verify.phase_*` aliases that forward to semantic verification
  aliases for one release cycle

Compatibility-lane support is not a promise that the older path remains the
preferred API. It means the bridge still exists so adopters can migrate on a
controlled schedule.

### Legacy durable payload cleanup

The former pre-v2.4 metadata dispatch bridge is retired under the
security/correctness exception: recognizable public metadata is provenance, not
private provider input. A queued Delivery without its private Payload settles
idempotently as `legacy_payload_missing`, preserves Delivery/Event history,
never calls an adapter, and cannot fabricate a private envelope. If it still
needs sending, an operator must re-author/re-enqueue it from an authoritative
private source.

The 14-day legacy cleanup window applies only to real content-bearing legacy
Payload rows and their tombstones; it is not a dispatch grace window. This
retirement does not create a public Payload API or break `Mailglass.Adapter`
callback compatibility, which remains the public delivery seam.

## Release guarantees

### Patch releases

Patch releases keep the documented `2.x` stable lane intact.

Allowed in a patch release:

- bug fixes
- docs corrections
- additional tests or verification
- stricter warnings or docs around deprecated bridges
- security or correctness fixes that preserve the documented semantics as much
  as possible

Not allowed in a normal patch release:

- removing stable-lane APIs
- silently broadening or shrinking the support matrix beyond repo proof
- treating a retained compatibility bridge as stable without updating this guide

### Minor releases

Minor releases may add new stable-lane APIs, new docs, new integrations, or
new optional-dependency lanes.

Minor releases may also narrow the compatibility lane only when all of these
are true:

- the affected path is already documented here as deprecated or compatibility
  only
- a replacement is already documented
- the support horizon documented here has been honored
- the change does not break the stable lane

### Major releases

Major releases may remove deprecated bridges, revise guarantees, or redesign
the support matrix. If a path is only promised through `v2.0`, assume that
removal can happen no earlier than the first `2.x` release.

## Security and correctness exception

Mailglass keeps a narrow exception for security and correctness incidents.

If a documented behavior must change to fix a security issue, prevent data
loss, restore signature correctness, or recover from a demonstrably unsafe
contract bug, maintainers may ship the smallest safe change before the next
major release. When that happens, the goal is:

- patch the unsafe behavior, not opportunistically redesign adjacent APIs
- document the exception in the changelog and maintainer docs
- provide the clearest available migration note or fallback path

This exception is intentionally narrow. It is not permission to bypass the
stable-lane contract for convenience.

## Warnings-as-errors guidance

Mailglass supports strict adopters that compile and test with
`--warnings-as-errors`.

- Paths with explicit `@deprecated` metadata should be treated as migration work
  you should schedule before tightening your `2.x` adoption baseline
- Silent legacy bridges may remain temporarily when this guide still documents
  them as compatibility-lane surfaces with a support horizon
- New code should prefer the stable lane even when a compatibility bridge still
  works

The repository itself proves this posture through docs and support-contract
checks, including `mix docs --warnings-as-errors`,
`mix verify.support_contract.core`, `mix verify.support_contract.admin`, and
`mix compile --no-optional-deps --warnings-as-errors`.

## Support matrix

This table is intentionally narrow. A row belongs here only if the repository
proves it today through `mix.exs`, `mailglass_admin/mix.exs`,
`scripts/verify_support_contract.sh`, or `.github/workflows/ci.yml`.

| Surface | Supported `2.x` posture | Proof artifact |
| --- | --- | --- |
| Elixir | `~> 1.18` | `mix.exs`, `mailglass_admin/mix.exs`, `.github/workflows/ci.yml` |
| OTP | `27+` | `.github/workflows/ci.yml` |
| Phoenix | `~> 1.8` | `mix.exs`, `mailglass_admin/mix.exs` |
| Phoenix LiveView | `~> 1.1` | `mix.exs`, `mailglass_admin/mix.exs` |
| Ecto / Ecto SQL | `~> 3.13` | `mix.exs` |
| PostgreSQL | 14+ for the documented contract; CI proves Postgres 16 and the repo requires trigger support | `README.md`, `mix.exs`, `.github/workflows/ci.yml` |
| `mailglass_admin` | matched release line with the core package | `mailglass_admin/mix.exs` |
| `mailglass_inbound` | independent `1.0` contract; see `mailglass_inbound/docs/api_stability.md` | `mailglass_inbound/docs/api_stability.md` |

### Optional dependency lanes

Optional dependencies are supported integration lanes when present, not part of
the minimum runtime floor.

- `oban`
- `opentelemetry`
- `mjml`
- `gen_smtp`
- `sigra`

Those integrations are documented and compiled as optional dependencies in
`mix.exs`. They are supported when present in a compatible adopter app, but the
repo does not claim that every project must install them to remain inside the
core `2.x` contract.

## Sibling-package policy

`mailglass` and `mailglass_admin` ship as matched siblings. For the `2.x`
contract, use matched release lines unless a future guide explicitly documents a
different compatibility window.

`mailglass_admin/mix.exs` proves the current expectation:

- local development uses the repo path dependency
- published builds pin the exact sibling version

That is the current truth the repo can defend. Do not infer a broader
cross-version compatibility story from shared source control alone.

## mailglass_inbound compatibility

`mailglass_inbound` has an explicit semantics-first contract inventory in
[`mailglass_inbound/docs/api_stability.md`](../mailglass_inbound/docs/api_stability.md).
Use that file for stable surface truth before making compatibility claims.

Stable inventoried inbound surfaces require one of:

- a deprecation bridge with clear replacement and support horizon, or
- a major-version change before semantic breakage.

Internal and deferred inbound surfaces may change without deprecation, even
when the module is reachable, documented for troubleshooting, or referenced by
tests. Reachability is not a compatibility promise.

### Inbound deprecation-DX inventory

| Surface | Bridge or replacement | Warning or migration channel | `--warnings-as-errors` impact | Support-until horizon | Proof artifact |
| --- | --- | --- | --- | --- | --- |
| `MailglassInbound.Ingress.CachingBodyReader` + required endpoint `body_reader` wiring | Keep stable path and preserve `MailglassInbound.Ingress.CachingBodyReader` semantics | Release notes + docs updates in README/install/operator guides | Missing or changed wiring can fail strict docs/support lanes; no silent compatibility fallback is promised | Through `mailglass_inbound` `1.x`; semantic break requires a deprecation bridge or a `mailglass_inbound` major-version change | `mailglass_inbound/docs/api_stability.md`, `mailglass_inbound/README.md`, `mailglass_inbound/docs/inbound-install.md`, `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| `MailglassInbound.Router` + `MailglassInbound.Mailbox` contract (`process/1` outcomes) | Keep stable callback and documented matcher/outcome semantics; any narrowing requires a deprecation bridge or major change | Release notes + contract docs; docs-contract drift checks | Strict adopters fail on drift in docs-contract/support-contract lanes | Through `mailglass_inbound` `1.x`; semantic break requires a deprecation bridge or a `mailglass_inbound` major-version change | `mailglass_inbound/docs/api_stability.md`, `mix verify.stability_contract` |
| `mix mailglass.inbound.doctor`, `mix mailglass.inbound.replay`, `mix mailglass.inbound.prune` command semantics | Preserve documented flags, tenant guards, confirmations, and exit semantics; internal modules remain non-contract | Operator guide updates + release notes | Strict adopters can fail docs lanes if command-semantics contract wording drifts | Through `mailglass_inbound` `1.x`; semantic break requires a deprecation bridge or a `mailglass_inbound` major-version change | `mailglass_inbound/docs/inbound-operator.md`, `mailglass_inbound/docs/api_stability.md`, `mix mailglass.docs.check` |

## What this guide does not promise

This guide does not promise:

- `mailglass_inbound`'s contract within the `mailglass` / `mailglass_admin` `2.x` line covered here; `mailglass_inbound` has its own independent contract documented in `mailglass_inbound/docs/api_stability.md`
- broader Elixir, OTP, Phoenix, LiveView, Ecto, or Postgres ranges than the
  repository currently proves
- that every exported or reachable function is stable
- that deprecated bridges are equally preferred as the stable lane

## How to use this guide

- Starting a new integration: stay on `Mailglass.deliver*` and native
  `Mailglass.Message` setters
- Upgrading from `0.x`: use the canonical
  [`guides/upgrading-to-v1_0.md`](upgrading-to-v1_0.md) path and treat older
  migration guides as subordinate references
- Checking public surface promises: pair this guide with
  [`docs/api_stability.md`](../docs/api_stability.md) and
  [`mailglass_admin/docs/api_stability.md`](../mailglass_admin/docs/api_stability.md)
- Verifying repo truth: run `scripts/verify_support_contract.sh`

If a compatibility claim is not documented here or in the package stability
inventories, do not assume it is part of the `2.x` promise.
