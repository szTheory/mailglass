const { readFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const test = require("node:test");
const assert = require("node:assert/strict");

const repoRoot = resolve(__dirname, "../../../../");
const readme = readFileSync(join(repoRoot, "reference/demo_app/README.md"), "utf8");
const runbook = readFileSync(
  join(repoRoot, ".planning/phases/173-consistency-and-delivery-evidence/173-DELIVERY.md"),
  "utf8"
);

test("README exposes the committed candidate review entry point", () => {
  assert.match(readme, /bash scripts\/check_phase173_candidate\.sh/);
  assert.match(readme, /\/dev\/mail/);
  assert.match(readme, /173-DELIVERY\.md/);
});

test("delivery runbook tells the owner how to open and identify the candidate", () => {
  assert.match(runbook, /bash scripts\/check_phase173_candidate\.sh/);
  assert.match(runbook, /http:\/\/127\.0\.0\.1:<recorded-port>\/dev\/mail/);
  assert.match(runbook, /detached worktree/i);
  assert.match(runbook, /exact candidate SHA/i);
  assert.match(runbook, /clean checkout/i);
  assert.match(runbook, /origin-dirty-paths\.json/);
  assert.match(runbook, /excluded owner paths/i);
});

test("runbook documents served asset identity and bounded browser claims", () => {
  assert.match(runbook, /source CSS/i);
  assert.match(runbook, /built CSS/i);
  assert.match(runbook, /served CSS/i);
  assert.match(runbook, /synthetic/i);
  assert.match(runbook, /Gmail/i);
  assert.match(runbook, /Outlook/i);
  assert.match(runbook, /Apple Mail/i);
  for (const route of ["/dev/mail", "/dev/mail/gallery", "/dev/storybook"]) {
    assert.ok(runbook.includes(route), `missing review route ${route}`);
  }
});

test("runbook separates required CI from advisory jobs and retains scoped resources", () => {
  assert.match(runbook, /CI Green/);
  assert.match(runbook, /advisory/i);
  assert.match(runbook, /review project/i);
  assert.match(runbook, /candidate worktree/i);
  assert.match(runbook, /docker compose -p \"\$REVIEW_PROJECT\" -f \"\$WORKTREE\/compose\.demo\.yml\" down/);
  assert.match(runbook, /git worktree remove \"\$WORKTREE\"/);
  assert.match(runbook, /14-day/i);
  assert.match(runbook, /no merge|no publication/i);
});
