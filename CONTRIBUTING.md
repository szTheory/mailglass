# Contributing to Mailglass

We welcome contributions! Mailglass is developed using a phase-based roadmap found in [`.planning/PROJECT.md`](.planning/PROJECT.md).

## Local Setup

1. Clone the repo.
2. Install dependencies: `mix deps.get`.
3. Setup the test database: `mix ecto.setup` (or `mix ecto.create -r Mailglass.TestRepo`).
4. Run tests: `mix test`.

## Development Workflow

1. Create a branch.
2. Implement your changes and add tests.
3. Run the full verification suite: `mix verify.phase_07`.
4. Submit a PR.

## Commit Guidelines

Use Conventional Commits:
- `feat: ...` for new features
- `fix: ...` for bug fixes
- `docs: ...` for documentation changes
- `chore: ...` for maintenance

## PR Expectations

- All CI checks must pass.
- New features must include documentation and tests.
- Maintain atomic commits.
