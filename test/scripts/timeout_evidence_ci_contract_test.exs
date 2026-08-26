defmodule Mailglass.Scripts.TimeoutEvidenceCIContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @ci_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @playwright_path Path.join(@repo_root, "mailglass_admin/playwright.config.cjs")
  @gallery_path Path.join(@repo_root, "mailglass_admin/e2e/gallery-matrix.spec.js")

  test "existing deterministic and browser lanes upload strict evidence only when their gate fails" do
    ci = File.read!(@ci_path)

    assert ci =~ "id: deterministic-core"
    assert ci =~ "MAILGLASS_TIMEOUT_EVIDENCE_PATH: tmp/timeout-evidence/database.ndjson"
    assert ci =~ "failure() && steps.deterministic-core.outcome == 'failure'"
    assert ci =~ "name: database-timeout-evidence-${{ github.run_id }}"

    assert ci =~
             ~r/name: database-timeout-evidence-.*?\n\s+if-no-files-found: error\n\s+retention-days: 90/s

    assert ci =~ "id: operator-browser"

    assert ci =~
             "MAILGLASS_BROWSER_SERVER_EVIDENCE_PATH: test-results/operator-browser-server.ndjson"

    assert ci =~ "failure() && steps.operator-browser.outcome == 'failure'"

    assert ci =~
             "name: operator-browser-timeout-evidence-${{ github.run_id }}-node-${{ matrix.node }}"

    assert ci =~
             ~r/name: operator-browser-timeout-evidence-.*?\n\s+if-no-files-found: error\n\s+retention-days: 90/s

    assert length(
             Regex.scan(~r/actions\/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a/, ci)
           ) >= 6

    assert ci =~ "name: Core Deterministic Suite (Elixir 1.18 / OTP 27)"
    assert ci =~ "name: Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)"
    assert ci =~ "timeout-minutes: 30"
  end

  test "browser evidence retains first-attempt failures without widening execution policy" do
    config = File.read!(@playwright_path)

    assert config =~ "timeout: 30_000"
    assert config =~ "retries: process.env.CI ? 1 : 0"
    assert config =~ "trace: process.env.CI ? \"retain-on-failure\" : \"on-first-retry\""
    assert config =~ "timeout: 300_000"
    assert config =~ "timeout-evidence-reporter.cjs"
    assert config =~ "operator-browser-evidence.json"
  end

  test "the reproduced gallery timeout is repaired only at the named matrix body" do
    gallery = File.read!(@gallery_path)

    assert gallery =~ "test.setTimeout(60_000)"
    assert gallery =~ "const MATRIX_WIDTHS = [320, 390, 768, 1440]"
    assert gallery =~ ~s(const MATRIX_THEMES = ["light", "dark", "system"])
    assert gallery =~ "expect(cells.length, \"gallery exposes specimen cells\").toBeGreaterThan(50)"
  end
end
