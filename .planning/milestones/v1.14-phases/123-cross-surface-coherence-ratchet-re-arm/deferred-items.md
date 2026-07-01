# Deferred Items — Phase 123

Out-of-scope discoveries logged during execution (not fixed — SCOPE BOUNDARY).

## From 123-02 (storybook + gallery finalization)

- **Pre-existing compile warning** — `mailglass_admin/lib/mailglass_admin/operator_live.ex:505`:
  `attribute "selected_delivery" in component MailglassAdmin.Operator.DeliveriesList.deliveries_list/1
  must be a :map, got: nil` (`selected_delivery={nil}`). Surfaced while compiling `reference/demo_app`
  for the storybook verification; this plan touched no admin lib code. Pre-existing and unrelated to
  COH-01. Not fixed. `mix compile --warnings-as-errors` still returned exit 0 (warning came from the
  admin-lib dependency compile, did not abort). Candidate cleanup for a future admin-lib pass.
