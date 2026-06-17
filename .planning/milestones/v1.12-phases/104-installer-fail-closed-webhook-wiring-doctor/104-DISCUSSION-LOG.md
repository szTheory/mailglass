# Phase 104: Installer Fail-Closed + Webhook-Wiring Doctor - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-16
**Phase:** 104-installer-fail-closed-webhook-wiring-doctor
**Mode:** assumptions
**Areas analyzed:** Fail-Closed Mechanism, --force Semantics, Doctor Task Shape + Detection, Test Fixture Mechanics

## Assumptions Presented

### Fail-Closed Mechanism (INSTALL-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `validate_preflight/1` returns `{:error, {:unmanaged_parser_conflict, path}}`, threaded as first step of `Apply.run/2`'s `with`; task adds only a `format_error/1` clause; `--force` checked inside preflight | Confident | apply.ex:27,32-36,47-76,64-65; mailglass.install.ex:61-63,147 |

### --force Semantics (INSTALL-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `--force` only skips the new raise; managed block already inserts ABOVE the unmanaged parser (anchor `use Phoenix.Endpoint`, top of file, Plug source order); no plan/templates change | Confident | plan.ex:156-170; apply.ex:211-282,342-371; templates.ex:86-95 |

### Doctor Task Shape + Detection (INSTALL-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New dedicated `mix mailglass.doctor` (not a mail.doctor lane), internal runner, static source scan of endpoint.ex, three-state exit codes (0/1/2) | Likely | mail.doctor.ex:70-72 (--domain required); mailglass.inbound.doctor.ex:96-105 + internal/doctor.ex (precedent); templates.ex:73; apply.ex:55-65 |

### Test Fixture Mechanics (INSTALL-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Seed conflict by overwriting fixture endpoint.ex (bare `plug Plug.Parsers`, no body_reader, outside markers) after `new_fixture_root!/1`; assert `{:error, {:unmanaged_parser_conflict,_}}` tuple; --force test asserts ordering; doctor test under `File.cd!` | Confident | installer_fixture_helpers.ex:211,263-269,41-43,31; install_idempotency_test.exs |

## Corrections Made

No corrections — all assumptions confirmed. The one user-facing fork (doctor shape) was put to
the user and confirmed in favor of a NEW dedicated `mix mailglass.doctor` over extending
`mix mail.doctor` (which would have required relaxing its `--domain`-required DNS contract).

## External Research

None performed — self-contained installer/mix-task phase; all wiring facts established from the
read source files.
