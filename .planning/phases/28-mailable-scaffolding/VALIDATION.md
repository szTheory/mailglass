# Phase 28: Mailable Scaffolding

## Goal-Backward Validation

**Phase Goal:** Developers can scaffold mailables instantly without looking up boilerplate.

### 1. Observable Truths
What must be true for the goal to be achieved?
- The user can run a mix task (`mix mailglass.gen.mailable`) to generate a new mailable.
- The generated code contains standard boilerplate, compiles correctly, and functions as expected.
- Naming collisions between the builder function and the template are avoided automatically.

### 2. Required Artifacts
What must exist for these truths to hold?
- `lib/mix/tasks/mailglass.gen.mailable.ex`: The mix task logic using Igniter.
- `test/mix/tasks/mailglass.gen.mailable_test.exs`: The tests for the generator.

### 3. Required Wiring & Key Links
- The `mailglass.gen.mailable` mix task must rely on `Igniter.Mix.Task` to integrate into the user's project and create files.
- The generator must produce modules that `use Mailglass.Mailable` and `embed_templates`.

### 4. Verification Steps
- Run `mix test test/mix/tasks/mailglass.gen.mailable_test.exs`. All tests must pass, confirming the task logic.
- Execute `mix igniter.run mailglass.gen.mailable TestEmail` in a dummy setup (or within the test suite) to verify the output compiles cleanly and is located at `lib/my_app/mail/test_email.ex`.