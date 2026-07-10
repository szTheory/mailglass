defmodule MailglassDemo.DocsContractTest do
  use ExUnit.Case, async: true

  defp readme!, do: File.read!(Path.expand("../../README.md", __DIR__))

  test "pins phase 69 quickstart and click-path contract" do
    readme = readme!()

    assert readme =~ "## Quickstart"
    assert readme =~ "## Persona and JTBD"
    assert readme =~ "## Seeded data"
    assert readme =~ "## What to click"
    assert readme =~ "## Dependency Mode"
    assert readme =~ "AtlasDesk is the fictional support/workspace SaaS for this demo."
    assert readme =~ "The deterministic tenant id remains `northstar`"

    assert readme =~
             "DEMO_EVIDENCE_RESET_TOKEN=$(openssl rand -hex 24) docker compose -f compose.demo.yml up demo"

    assert readme =~
             "DEMO_EVIDENCE_RESET_TOKEN=<same-token> docker compose -f compose.demo.yml exec demo mix demo.reset"

    assert readme =~
             "DEMO_EVIDENCE_RESET_TOKEN=<same-token> docker compose -f compose.demo.yml run --rm demo_e2e"

    assert readme =~ "http://localhost:4015"
    assert readme =~ "http://localhost:4015/dev/mail"

    assert readme =~
             "http://localhost:4015/demo/login?return_to=/ops/mail?tenant_id=northstar"

    assert readme =~
             "http://localhost:4015/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar"
  end

  test "pins seeded stories, boundary language, and future artifact label" do
    readme = readme!()

    for token <- [
          "invite admin",
          "magic link",
          "receipt paid",
          "payment failed",
          "usage alert",
          "incident update",
          "receipt delivery",
          "payment failure bounce",
          "usage alert bounce",
          "manual suppression",
          "support reply",
          "refund request",
          "spam reject",
          "no-match route",
          "stored-truth replay",
          "Future artifact label: `demo_browser_evidence.v1`.",
          "Destructive note: this reset truncates seeded demo tables before reseeding preview, delivery, suppression, inbound record, evidence, routing trace, and replay data for tenant `northstar`.",
          "This demo app is richer click-around evidence for maintainer and adopter validation. It does not define stable Mailglass API guarantees, and demo DOM, selectors, routes, and copy are not stable public API."
        ] do
      assert readme =~ token
    end
  end
end
