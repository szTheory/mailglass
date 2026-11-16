#!/usr/bin/env node
"use strict";

// capture-before-catalog.cjs: the driver for the Phase 180 "before" catalog (BRPIPE-03).
//
// Order (D-17, D-19, D-20): refuse a dirty tree -> pick run_id and catalog_id -> restart the
// demo so it serves the current commit -> reset through the guarded helper -> seed the four
// missing delivery cases -> run the capture spec into the git-ignored staging directory ->
// validate -> re-check the tree -> write manifest.json -> promote atomically.
//
//   node reference/demo_app/assets/catalog/capture-before-catalog.cjs [--only <ids|smoke>] [--no-promote]
//   node reference/demo_app/assets/catalog/capture-before-catalog.cjs --mode after [--catalog-root <dir>] [--no-promote]
//
// `--mode after` (Phase 182, BRADM-07) runs the same order for the after catalog: both seeds (the
// Phase 180 CatalogSeed, then the password-reset JourneySeed), the spec `catalog/phase182-journey.spec.js`
// and a catalog id `after-<sha7>-<UTCstamp>`. The default mode is `before` and behaves exactly as it did
// in Phase 180: it passes `catalog/before-catalog.spec.js` and the CatalogSeed expression only.
//
// Environment: DEMO_BASE_URL (default http://127.0.0.1:${MAILGLASS_DEMO_HTTP_PORT:-4015}/),
// DEMO_EVIDENCE_RESET_TOKEN (default: the compose dev default). Neither value is ever written
// into the catalog. The catalog is evidence for a reviewer, never a pixel-diff baseline.

const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync, spawnSync } = require("node:child_process");

// One id per tier A-E plus a CatalogSeed case. `--only smoke` and the spec's
// `CATALOG_ONLY=smoke` both resolve through this export.
const CATALOG_SMOKE_IDS = [
  "overview__fjordline-aps__default__375__dark", // tier A
  "delivery-quick-view__fjordline-aps__open__1440__light", // tier A overlay
  "deliveries__northstar__default__1440__light", // tier B
  "delivery-detail__send-failed__default__375__dark", // tier C, a CatalogSeed case
  "gallery__any__default__1440__light", // tier D
  "inbound-quick-view__northstar__first-message__1440__light" // tier E
];

// The fourteen after-catalog scenario ids (Phase 182 D-21, checker W2). The `reset-*` ids render the
// JourneySeed password-reset rows; the last two reuse Phase 180 capture ids, so they pair with the
// identically named before shots. Pairing is by exact id only (a password-reset shot is never judged
// against a before shot of another mailable).
const AFTER_SCENARIO_IDS = [
  "deliveries__northstar__reset-search__375__light",
  "deliveries__northstar__reset-search__375__dark",
  "deliveries__northstar__reset-search__1440__light",
  "delivery-detail__reset-typo-bounce__default__375__light",
  "delivery-detail__reset-typo-bounce__default__375__dark",
  "delivery-detail__reset-typo-bounce__default__1440__light",
  "delivery-detail__reset-nil-reason-bounce__default__375__light",
  "delivery-detail__reset-deferred__default__375__light",
  "delivery-detail__reset-suppressed__default__375__light",
  "delivery-detail__reset-sent-no-report__default__375__light",
  "delivery-detail__reset-bounce-then-open__default__375__light",
  "deliveries__northstar__empty-search__375__light",
  "deliveries__northstar__default__1440__light",
  "delivery-detail__typo-bounce__default__375__light"
];

// Two injected-defect shots for the reviewer calibration. Each removes one thing from a real
// page with `page.evaluate` before the shot, so a reviewer that cannot reject them cannot be trusted.
const AFTER_CALIBRATION_CAPTURE_IDS = [
  "calib-defect-no-zone__reset-typo-bounce__default__375__light",
  "calib-defect-no-status-word__reset-typo-bounce__default__375__light"
];

const CAP_IMAGES = 80;
const CAP_BYTES = 15_000_000;
const BUNDLE_PATH = "mailglass_admin/priv/static/app.css";
const ROOT_LAYOUT_PATH = "mailglass_admin/lib/mailglass_admin/layouts/root.html.heex";
const COMPOSE = ["compose", "-f", "compose.demo.yml"];

// Per-mode constants. `before` is the Phase 180 behaviour, byte for byte.
const MODES = {
  before: {
    schema: "mailglass.before_catalog.v1",
    catalogDirRel: ".planning/research/brand-v2-adoption/before-catalog",
    idPrefix: "before",
    spec: "catalog/before-catalog.spec.js",
    seedExpr: "MailglassDemo.CatalogSeed.seed!()",
    sentinels: { catalog: "CATALOG_CASES_JSON=" },
    seedLabel: "CatalogSeed.seed!()"
  },
  after: {
    schema: "mailglass.after_catalog.v1",
    catalogDirRel: ".planning/research/brand-v2-adoption/after-catalog",
    idPrefix: "after",
    spec: "catalog/phase182-journey.spec.js",
    seedExpr: "MailglassDemo.CatalogSeed.seed!(); MailglassDemo.JourneySeed.seed!()",
    sentinels: { catalog: "CATALOG_CASES_JSON=", journey: "JOURNEY_CASES_JSON=" },
    seedLabel: "CatalogSeed.seed!(); JourneySeed.seed!()"
  }
};
const SLUG_FILE = /^[a-z0-9_.-]+\.png$/;
const EMAIL = /[\p{L}\p{N}._%+-]+@([\p{L}\p{N}-]+(?:\.[\p{L}\p{N}-]+)+)/gu;
const RESERVED_SUFFIXES = [".example.com", ".example", ".local", ".test", ".invalid", ".localhost"];
const RESERVED_DOMAINS = new Set(["example.com", "example.net", "example.org"]);
const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

class Refusal extends Error {}

function refuse(message) {
  throw new Refusal(message);
}

function git(repoRoot, args, options = {}) {
  return execFileSync("git", args, { cwd: repoRoot, encoding: "utf8", ...options }).trim();
}

function repoRootFrom(start) {
  return execFileSync("git", ["rev-parse", "--show-toplevel"], { cwd: start, encoding: "utf8" }).trim();
}

const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");

// The same computation `git hash-object` performs; the manifest test recomputes it in Elixir.
function gitBlobSha(bytes) {
  return crypto
    .createHash("sha1")
    .update(Buffer.concat([Buffer.from(`blob ${bytes.byteLength}\0`), bytes]))
    .digest("hex");
}

function utcStamp(date) {
  return date.toISOString().replace(/[-:]/g, "").replace(/\.\d+Z$/, "Z");
}

function parseArgs(argv) {
  const options = { only: null, promote: true, mode: "before", catalogRoot: null };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--no-promote") options.promote = false;
    else if (argument === "--only") {
      options.only = argv[index + 1];
      index += 1;
      if (!options.only) refuse("--only needs a comma-separated list of capture ids, or `smoke`");
    } else if (argument === "--mode") {
      options.mode = argv[index + 1];
      index += 1;
      if (!Object.hasOwn(MODES, options.mode)) refuse("--mode needs `before` or `after`");
    } else if (argument === "--catalog-root") {
      options.catalogRoot = argv[index + 1];
      index += 1;
      if (!options.catalogRoot) refuse("--catalog-root needs a directory");
    } else refuse(`Unknown option: ${argument}`);
  }
  if (options.catalogRoot && options.mode !== "after") {
    refuse("--catalog-root is only valid with --mode after (the before catalog always lives at its planning path)");
  }
  return options;
}

// ---------------------------------------------------------------------------------------
// Step (a): clean tree and source identity
// ---------------------------------------------------------------------------------------

// The single path a clean tree may differ in. `.planning/config.json` holds the GSD workflow and model
// settings; the demo and the admin bundle never read it, so it cannot change what is served or captured.
// No other path is exempt. The shell form of the exclusion:
//   git status --porcelain --untracked-files=all -- . ':!.planning/config.json'
const CLEAN_TREE_EXEMPT_PATH = ".planning/config.json";

// Pure: the lines of `git status --porcelain` output that block a capture. The pathspec exclusion in
// `assertCleanTree` already hides the exempt path from git; this filter states the same rule on the
// text so it is checkable without git (a rename `a -> b` blocks unless both sides are exempt).
function dirtyPathsBlocking(porcelainText) {
  return `${porcelainText}`
    .split("\n")
    .map((line) => line.replace(/\r$/, ""))
    .filter((line) => line.trim() !== "")
    .filter((line) => {
      const paths = line.slice(3).split(" -> ").map((entry) => entry.trim().replace(/^"|"$/g, ""));
      return !paths.every((entry) => entry === CLEAN_TREE_EXEMPT_PATH);
    });
}

function assertCleanTree(repoRoot, when) {
  // Raw output, not `git()`: trimming would eat the leading status column of the first line.
  const status = execFileSync(
    "git",
    ["status", "--porcelain", "--untracked-files=all", "--", ".", `:!${CLEAN_TREE_EXEMPT_PATH}`],
    { cwd: repoRoot, encoding: "utf8" }
  );
  const dirty = dirtyPathsBlocking(status);
  if (dirty.length > 0) {
    refuse(
      `${when}: the working tree is dirty, so the recorded commit would not describe what was captured.\n` +
        `${dirty.slice(0, 12).join("\n")}\nCommit or discard these changes, then run again.`
    );
  }
}

function contentIdentity(repoRoot, relativePath) {
  const bytes = fs.readFileSync(path.join(repoRoot, relativePath));
  const gitBlob = git(repoRoot, ["rev-parse", `HEAD:${relativePath}`]);
  const computed = gitBlobSha(bytes);
  if (computed !== gitBlob) {
    refuse(
      `${relativePath}: the working-tree bytes (blob ${computed}) differ from HEAD (blob ${gitBlob}). ` +
        "The manifest test would disagree with git, so nothing is captured."
    );
  }
  return { sha256: sha256(bytes), git_blob_sha: gitBlob };
}

function readSourceIdentity(repoRoot) {
  assertCleanTree(repoRoot, "Refusing to run");
  const gitSha = git(repoRoot, ["rev-parse", "HEAD"]);
  const bundle = contentIdentity(repoRoot, BUNDLE_PATH);
  const layout = contentIdentity(repoRoot, ROOT_LAYOUT_PATH);
  return {
    git_sha: gitSha,
    dirty: false,
    branch: git(repoRoot, ["rev-parse", "--abbrev-ref", "HEAD"]),
    tree_sha: git(repoRoot, ["rev-parse", "HEAD^{tree}"]),
    committed_at: new Date(git(repoRoot, ["show", "-s", "--format=%cI", "HEAD"])).toISOString(),
    bundle: { path: BUNDLE_PATH, ...bundle },
    root_layout: { path: ROOT_LAYOUT_PATH, git_blob_sha: layout.git_blob_sha }
  };
}

// ---------------------------------------------------------------------------------------
// Docker steps
// ---------------------------------------------------------------------------------------

function docker(repoRoot, args, options = {}) {
  return spawnSync("docker", args, {
    cwd: repoRoot,
    encoding: "utf8",
    maxBuffer: 256 * 1024 * 1024,
    ...options
  });
}

function restartDemo(repoRoot, runId, commitTime, scriptStartedAt) {
  console.log(`Restarting the demo so it serves the current commit (run ${runId})...`);
  const env = { ...process.env, DEMO_EVIDENCE_PROJECT_ID: runId };
  const up = docker(repoRoot, [...COMPOSE, "up", "-d", "--force-recreate", "--wait", "demo"], {
    env,
    stdio: ["ignore", "inherit", "inherit"],
    timeout: 12 * 60 * 1000
  });
  if (up.status !== 0) {
    refuse(`docker compose up failed (exit ${up.status}). The demo must be healthy before a capture.`);
  }
  const id = docker(repoRoot, [...COMPOSE, "ps", "-q", "demo"], { env }).stdout.trim();
  if (id === "") refuse("docker compose ps found no demo container after the restart");
  const inspected = docker(repoRoot, ["inspect", "--format", "{{.State.Pid}} {{.State.StartedAt}}", id]).stdout.trim();
  const separator = inspected.indexOf(" ");
  const pid = Number(inspected.slice(0, separator));
  const startedAt = inspected.slice(separator + 1);
  const started = new Date(startedAt);
  if (Number.isNaN(started.getTime()) || started.getTime() <= new Date(commitTime).getTime()) {
    refuse(
      `The demo container started at ${startedAt}, which is not later than the source commit (${commitTime}). ` +
        "A stale server would serve old bytes, so nothing is captured."
    );
  }
  // D-21: the server must have been started by THIS run, after the script began, or it could be a
  // container left over from an earlier run that happens to be newer than the commit.
  if (started.getTime() <= new Date(scriptStartedAt).getTime()) {
    refuse(
      `The demo container started at ${startedAt}, which is not later than this script's start (${scriptStartedAt}). ` +
        "The served bytes would not be proven to come from this run, so nothing is captured."
    );
  }
  if (!Number.isInteger(pid) || pid <= 0) refuse(`docker inspect returned no container PID (${inspected})`);
  return { startedAt: started.toISOString(), pid };
}

async function resetDemo(assetsDir, env) {
  const { request } = require(require.resolve("@playwright/test", { paths: [assetsDir] }));
  const { resetDisposableEvidence } = require(path.join(assetsDir, "scripts/check-persona-reset-target.cjs"));
  const context = await request.newContext();
  try {
    await resetDisposableEvidence(context, env);
  } finally {
    await context.dispose();
  }
}

function runSeed(repoRoot, args, sentinels) {
  const result = docker(repoRoot, args, { timeout: 5 * 60 * 1000 });
  const lines = `${result.stdout || ""}`.split("\n").map((entry) => entry.trim());
  const found = {};
  for (const [name, sentinel] of Object.entries(sentinels)) {
    const line = lines.find((entry) => entry.startsWith(sentinel));
    if (line) found[name] = line.slice(sentinel.length);
  }
  const ok = result.status === 0 && Object.keys(sentinels).every((name) => Object.hasOwn(found, name));
  return { ok, found, result };
}

async function seedCatalog(repoRoot, assetsDir, resetEnv, modeConfig) {
  const { seedExpr, sentinels, seedLabel } = modeConfig;
  const primary = ["compose", "-f", "compose.demo.yml", "exec", "-T", "demo", "mix", "run", "-e", seedExpr];
  const first = runSeed(repoRoot, primary, sentinels);
  if (first.ok) {
    console.log("seed branch: primary (docker compose exec demo mix run)");
    return { found: first.found, seed_command: `docker compose exec -T demo mix run -e ${seedLabel}` };
  }
  console.log(
    `The primary seed command failed (exit ${first.result.status}); resetting, then taking the in-harness fallback.`
  );
  console.log(`${first.result.stderr || ""}`.split("\n").slice(-8).join("\n"));
  // A partly applied primary seed would collide with the fixed catalog idempotency keys.
  await resetDemo(assetsDir, resetEnv);
  const fallback = ["compose", "-f", "compose.demo.yml", "run", "--rm", "--no-deps", "-T", "demo", "mix", "run", "-e", seedExpr];
  const second = runSeed(repoRoot, fallback, sentinels);
  if (!second.ok) {
    refuse(
      `The catalog seed failed on both branches (exit ${second.result.status}).\n` +
        `${`${second.result.stderr || ""}`.split("\n").slice(-12).join("\n")}`
    );
  }
  console.log("seed branch: in-harness fallback (docker compose run --rm --no-deps)");
  return { found: second.found, seed_command: `docker compose run --rm --no-deps -T demo mix run -e ${seedLabel}` };
}

// ---------------------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------------------

// A lexical prefix alone permits a directory inside the root to redirect writes elsewhere, so
// walk every path segment (the evidence-output-path.cjs idiom).
function assertNoSymlink(target) {
  let current = path.parse(target).root;
  for (const part of target.slice(current.length).split(path.sep).filter(Boolean)) {
    current = path.join(current, part);
    try {
      if (fs.lstatSync(current).isSymbolicLink()) refuse(`The catalog path contains a symlink: ${current}`);
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
}

function pngDimensions(file, bytes) {
  if (bytes.byteLength < 24 || !bytes.subarray(0, 8).equals(PNG_SIGNATURE)) {
    refuse(`${file} is not a PNG (bad signature)`);
  }
  return { w: bytes.readUInt32BE(16), h: bytes.readUInt32BE(20) };
}

function unreservedEmails(text) {
  const found = new Set();
  for (const match of text.matchAll(EMAIL)) {
    const domain = match[1].toLowerCase();
    const reserved = RESERVED_DOMAINS.has(domain) || RESERVED_SUFFIXES.some((suffix) => domain.endsWith(suffix));
    if (!reserved) found.add(match[0]);
  }
  return [...found];
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function collectCaptures(staging) {
  const recordDir = path.join(staging, "records");
  if (!fs.existsSync(recordDir)) refuse("The capture spec wrote no records");
  const records = fs
    .readdirSync(recordDir)
    .filter((name) => name.endsWith(".json"))
    .sort()
    .map((name) => readJson(path.join(recordDir, name)));
  if (records.length === 0) refuse("The capture spec wrote no records");

  const captures = [];
  for (const record of records) {
    const file = `${record.id}.png`;
    if (!SLUG_FILE.test(file)) refuse(`${file} is not a slug file name (${SLUG_FILE})`);
    const pngFile = path.join(staging, file);
    assertNoSymlink(pngFile);
    if (!fs.lstatSync(pngFile).isFile()) refuse(`${file} is not a regular file`);
    const bytes = fs.readFileSync(pngFile);
    const { w, h } = pngDimensions(file, bytes);

    const ariaFile = `aria/${record.id}.yml`;
    const ariaPath = path.join(staging, ariaFile);
    assertNoSymlink(ariaPath);
    const ariaBytes = fs.readFileSync(ariaPath);

    captures.push({
      id: record.id,
      file,
      sha256: sha256(bytes),
      bytes: bytes.byteLength,
      w,
      h,
      screen: record.screen,
      route: record.route,
      fixture: record.fixture,
      state: record.state,
      case: record.case,
      viewport: record.viewport,
      theme: record.theme,
      root_theme_attr: record.root_theme_attr,
      tier: record.tier,
      aria_file: ariaFile,
      aria_sha256: sha256(ariaBytes),
      stop_line_hits: record.stop_line_hits,
      // working fields, removed before the manifest is written
      _nested: record.nested_theme_attr_count,
      _relative: record.relative_time_hits,
      _fonts: record.fonts_loaded,
      _aria: ariaBytes.toString("utf8")
    });
  }
  return captures;
}

function printBudget(captures) {
  const byTier = new Map();
  for (const capture of captures) {
    const entry = byTier.get(capture.tier) || { count: 0, bytes: 0 };
    entry.count += 1;
    entry.bytes += capture.bytes;
    byTier.set(capture.tier, entry);
  }
  console.log("\nBudget by tier (decimal MB):");
  for (const tier of [...byTier.keys()].sort()) {
    const entry = byTier.get(tier);
    console.log(`  tier ${tier}: ${String(entry.count).padStart(2)} shots  ${(entry.bytes / 1e6).toFixed(3)} MB`);
  }
  const total = captures.reduce((sum, capture) => sum + capture.bytes, 0);
  console.log(`  total: ${captures.length} shots  ${total} bytes (${(total / 1e6).toFixed(3)} MB)`);
  console.log(`  caps : ${CAP_IMAGES} images, ${CAP_BYTES} bytes\n`);
  return total;
}

function validate({ staging, captures, source, casesText, resetToken, full, mode = "before" }) {
  const total = printBudget(captures);
  if (full && mode === "after") {
    // The after catalog is a fixed list of ids, not tiers: every scenario and calibration shot must exist.
    const have = new Set(captures.map((capture) => capture.id));
    const missing = [...AFTER_SCENARIO_IDS, ...AFTER_CALIBRATION_CAPTURE_IDS].filter((id) => !have.has(id));
    const extra = [...have].filter((id) => !AFTER_SCENARIO_IDS.includes(id) && !AFTER_CALIBRATION_CAPTURE_IDS.includes(id));
    if (missing.length > 0) refuse(`The full after capture run produced no shot for: ${missing.join(", ")}.`);
    if (extra.length > 0) refuse(`The after capture run produced unexpected shots: ${extra.join(", ")}.`);
  } else if (full) {
    const tiers = new Set(captures.map((capture) => capture.tier));
    const missing = ["A", "B", "C", "D", "E"].filter((tier) => !tiers.has(tier));
    if (missing.length > 0) refuse(`The full capture run produced no shots for tier ${missing.join(", ")}.`);
  }
  if (captures.length > CAP_IMAGES) {
    refuse(`Budget exceeded: ${captures.length} images against the cap of ${CAP_IMAGES}. Apply the cut order and run again.`);
  }
  if (total > CAP_BYTES) {
    refuse(`Budget exceeded: ${total} PNG bytes against the cap of ${CAP_BYTES}. Apply the cut order and run again.`);
  }

  const determinism = readJson(path.join(staging, "determinism.json"));
  if (determinism.identical !== true) {
    refuse(`The double capture of ${determinism.self_test_id} differs (${determinism.sha256.join(" vs ")}).`);
  }

  const served = readJson(path.join(staging, "served.json"));
  for (const asset of served.assets) {
    if (!asset.matches_disk || !asset.matches_git_blob) {
      refuse(`Stale server: ${asset.url_path} does not match the working tree and the git blob at ${served.revision}.`);
    }
  }
  const css = served.assets.find((asset) => /\/css-[0-9a-f]{32}$/.test(asset.url_path));
  if (!css) refuse("The spec recorded no served css asset");
  if (css.sha256 !== source.bundle.sha256 || css.git_blob_sha !== source.bundle.git_blob_sha) {
    refuse(
      "The served css asset does not equal the recorded source bundle " +
        `(served sha256 ${css.sha256}, source ${source.bundle.sha256}).`
    );
  }
  if (served.revision !== source.git_sha) {
    refuse(`The spec resolved revision ${served.revision}, not the recorded ${source.git_sha}.`);
  }

  const nested = captures.reduce((sum, capture) => sum + capture._nested, 0);
  if (nested !== 0) refuse(`nested_theme_attr_count is ${nested}; every capture must have <html> as the only theme owner.`);
  for (const capture of captures) {
    if (capture.root_theme_attr !== `mailglass-${capture.theme}`) {
      refuse(`${capture.id}: <html data-theme> is ${capture.root_theme_attr}, expected mailglass-${capture.theme}.`);
    }
    if (capture._relative.length > 0) {
      refuse(`${capture.id}: the page shows relative time (${capture._relative.join(" | ")}), which is not reproducible.`);
    }
    const leaked = unreservedEmails(capture._aria);
    if (leaked.length > 0) refuse(`${capture.id}: aria text names a non-reserved email address: ${leaked.join(", ")}`);
    if (resetToken && capture._aria.includes(resetToken)) refuse(`${capture.id}: aria text contains the demo reset token.`);
  }
  if (resetToken && casesText.includes(resetToken)) refuse("cases.json contains the demo reset token.");
  const casesLeak = unreservedEmails(casesText);
  if (casesLeak.length > 0) refuse(`cases.json names a non-reserved email address: ${casesLeak.join(", ")}`);

  return { determinism, served, nested, total };
}

// ---------------------------------------------------------------------------------------
// Manifest
// ---------------------------------------------------------------------------------------

function toolVersions(assetsDir, scriptHash) {
  const playwright = readJson(require.resolve("@playwright/test/package.json", { paths: [assetsDir] }));
  const browsersJson = readJson(path.join(path.dirname(require.resolve("playwright-core/package.json", { paths: [assetsDir] })), "browsers.json"));
  const chromium = browsersJson.browsers.find((browser) => browser.name === "chromium");
  return {
    playwright: playwright.version,
    chromium: chromium ? chromium.browserVersion : "unknown",
    node: process.version,
    os: `${os.platform()} ${os.release()} ${os.arch()}`,
    script_sha256: scriptHash
  };
}

function buildManifest({
  repoRoot,
  assetsDir,
  modeConfig,
  catalogId,
  runId,
  source,
  server,
  scriptStartedAt,
  captures,
  casesSha,
  caseData,
  checked
}) {
  const { computeSourceIdentity } = require(path.join(repoRoot, "scripts/check_phase174_evidence.cjs"));
  const identity = computeSourceIdentity(repoRoot, source.git_sha);
  const spec = fs.readFileSync(path.join(assetsDir, modeConfig.spec));
  const driver = fs.readFileSync(__filename);
  // sha256(spec bytes, NUL, driver bytes): the two scripts that produced the capture.
  const scriptHash = sha256(Buffer.concat([spec, Buffer.from([0]), driver]));
  const fonts = [...new Set(captures.flatMap((capture) => capture._fonts))].sort();

  const manifest = {
    schema: modeConfig.schema,
    catalog_id: catalogId,
    run_id: runId,
    source_revision: identity.source_revision,
    source_digest: identity.source_digest,
    source: { ...source, recheck: { clean: true, head_unchanged: true } },
    served: {
      assets: checked.served.assets.map((asset) => ({
        url_path: asset.url_path,
        sha256: asset.sha256,
        matches_disk: asset.matches_disk,
        matches_git_blob: asset.matches_git_blob,
        git_blob_sha: asset.git_blob_sha
      })),
      server_started_at: server.startedAt
    },
    cases: { file: "cases.json", sha256: casesSha },
    tools: toolVersions(assetsDir, scriptHash),
    determinism: {
      tz: "UTC",
      locale: "en-US",
      fixed_time: null,
      seed_anchor_utc: caseData.seed_anchor_utc,
      reduced_motion: "reduce",
      animations: "disabled",
      dsf: 1,
      fonts_loaded: fonts,
      double_capture_identical: checked.determinism.identical === true
    },
    budget: {
      image_count: captures.length,
      total_bytes: checked.total,
      cap_images: CAP_IMAGES,
      cap_bytes: CAP_BYTES
    },
    nested_theme_attr_count: checked.nested,
    captures: captures.map((capture) => {
      const entry = { ...capture };
      for (const key of Object.keys(entry)) if (key.startsWith("_")) delete entry[key];
      return entry;
    })
  };
  if (modeConfig.idPrefix === "after") {
    // D-21 served SHA: this run restarted the server (PID and start time recorded) after the script began.
    manifest.script_started_at = scriptStartedAt;
    manifest.server = { container_pid: server.pid, started_at: server.startedAt };
  }
  return manifest;
}

// ---------------------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------------------

async function main() {
  // D-21: recorded first, so a server that started before it cannot be mistaken for this run's server.
  const scriptStartedAt = new Date().toISOString();
  const options = parseArgs(process.argv.slice(2));
  const modeConfig = MODES[options.mode];
  const repoRoot = repoRootFrom(__dirname);
  const assetsDir = path.join(repoRoot, "reference/demo_app/assets");
  const catalogRoot = options.catalogRoot ? path.resolve(options.catalogRoot) : path.join(repoRoot, modeConfig.catalogDirRel);
  const baseUrl = process.env.DEMO_BASE_URL || `http://127.0.0.1:${process.env.MAILGLASS_DEMO_HTTP_PORT || "4015"}/`;
  const resetToken = process.env.DEMO_EVIDENCE_RESET_TOKEN || "mailglass-dev-demo";

  // (a) clean tree, source identity
  const source = readSourceIdentity(repoRoot);

  // (b) ids; refuse to reuse an existing catalog
  const now = new Date();
  const runId = `mailglass-evidence-${utcStamp(now).replace("T", "").replace("Z", "")}-${process.pid}-${Math.floor(Math.random() * 90000) + 10000}`;
  const catalogId = `${modeConfig.idPrefix}-${source.git_sha.slice(0, 7)}-${utcStamp(now)}`;
  const finalDir = path.join(catalogRoot, catalogId);
  const staging = path.join(catalogRoot, ".cache", catalogId);
  if (fs.existsSync(finalDir) || fs.existsSync(staging)) refuse(`Refusing to reuse existing catalog ${catalogId}`);
  assertNoSymlink(staging);
  fs.mkdirSync(staging, { recursive: true });
  console.log(`catalog ${catalogId} from ${source.git_sha} (staging ${staging})`);

  // (c) restart so the server serves this commit
  const server = restartDemo(repoRoot, runId, source.committed_at, scriptStartedAt);

  // (d) reset through the guarded helper
  const resetEnv = {
    DEMO_BASE_URL: baseUrl,
    DEMO_EVIDENCE_RUN_ID: runId,
    DEMO_EVIDENCE_RESET_TOKEN: resetToken
  };
  await resetDemo(assetsDir, resetEnv);

  // (e) seed the four missing cases
  const seeded = await seedCatalog(repoRoot, assetsDir, resetEnv, modeConfig);
  const caseData = JSON.parse(seeded.found.catalog);
  // Before mode: cases.json is the CatalogSeed payload, as in Phase 180. After mode: both payloads.
  const casesDocument = options.mode === "after" ? { catalog: caseData, journey: JSON.parse(seeded.found.journey) } : caseData;
  const casesText = `${JSON.stringify(casesDocument, null, 2)}\n`;
  fs.writeFileSync(path.join(staging, "cases.json"), casesText);

  // (f) capture
  const env = {
    ...process.env,
    DEMO_BASE_URL: baseUrl,
    CATALOG_STAGING_DIR: staging,
    CATALOG_CASES_FILE: path.join(staging, "cases.json"),
    DEMO_CANDIDATE_REVISION: source.git_sha
  };
  if (options.only) env.CATALOG_ONLY = options.only;
  else delete env.CATALOG_ONLY;
  const playwrightBin = path.join(assetsDir, "node_modules/.bin/playwright");
  // The spec file is passed positionally: `testDir` is `./catalog`, which holds both specs, and each
  // mode must run only its own (before mode runs before-catalog.spec.js, after mode the journey spec).
  const captureArgs = ["test", "--config=playwright.catalog.config.cjs", modeConfig.spec];
  if (options.mode === "after") captureArgs.push("--grep-invert", "@advisory");
  const playwright = spawnSync(playwrightBin, captureArgs, { cwd: assetsDir, env, stdio: "inherit" });
  if (playwright.status !== 0) refuse(`The capture spec failed (exit ${playwright.status}). Nothing is promoted.`);

  // (f2) after mode: the advisory browser journey (D-20). Reported, never required proof, never a
  // reason to withhold the evidence, so its exit status is printed rather than refused on.
  let advisory = null;
  if (options.mode === "after") {
    console.log("\nRunning the advisory browser journey (375 and 1440, light and dark, three time zones)...");
    const adv = spawnSync(
      playwrightBin,
      ["test", "--config=playwright.catalog.config.cjs", modeConfig.spec, "--grep", "@advisory"],
      { cwd: assetsDir, env, stdio: "inherit" }
    );
    advisory = { status: adv.status === 0 ? "pass" : "fail", exit: adv.status };
    console.log(`ADVISORY journey: ${advisory.status} (exit ${adv.status}); advisory results are never the required proof.`);
  }

  // (g) validate
  const captures = collectCaptures(staging);
  const checked = validate({ staging, captures, source, casesText, resetToken, full: !options.only, mode: options.mode });

  // (h) the tree and HEAD must not have moved; then the manifest
  try {
    assertCleanTree(repoRoot, "Refusing to promote");
  } catch (error) {
    refuse("Refusing to promote: the tree changed during the capture run.\n" + error.message);
  }
  if (git(repoRoot, ["rev-parse", "HEAD"]) !== source.git_sha) {
    refuse("Refusing to promote: the tree changed during the capture run (HEAD moved).");
  }
  const manifest = buildManifest({
    repoRoot,
    assetsDir,
    modeConfig,
    catalogId,
    runId,
    source,
    server,
    scriptStartedAt,
    captures,
    casesSha: sha256(Buffer.from(casesText)),
    caseData,
    checked
  });
  const manifestText = `${JSON.stringify(manifest, null, 2)}\n`;
  if (resetToken && manifestText.includes(resetToken)) refuse("manifest.json contains the demo reset token.");
  const manifestLeak = unreservedEmails(manifestText);
  if (manifestLeak.length > 0) refuse(`manifest.json names a non-reserved email address: ${manifestLeak.join(", ")}`);
  fs.writeFileSync(path.join(staging, "manifest.json"), manifestText);

  // The promoted directory holds only listed files.
  fs.rmSync(path.join(staging, "records"), { recursive: true, force: true });
  fs.rmSync(path.join(staging, "determinism.json"), { force: true });
  fs.rmSync(path.join(staging, "served.json"), { force: true });

  // (i) stop at staging, or promote with nothing between the recheck and the rename
  if (!options.promote) {
    console.log(`staged ${catalogId} at ${staging} (${captures.length} captures, ${checked.total} bytes; seed ${seeded.seed_command})`);
    if (advisory) console.log(`advisory journey: ${advisory.status}`);
    return;
  }
  assertCleanTree(repoRoot, "Refusing to promote");
  if (fs.existsSync(finalDir)) refuse(`Refusing to reuse existing catalog ${catalogId}`);
  fs.renameSync(staging, finalDir);
  console.log(`promoted ${catalogId} to ${finalDir} (${captures.length} captures, ${checked.total} bytes; seed ${seeded.seed_command})`);
  if (advisory) console.log(`advisory journey: ${advisory.status}`);
}

module.exports = {
  CATALOG_SMOKE_IDS,
  AFTER_SCENARIO_IDS,
  AFTER_CALIBRATION_CAPTURE_IDS,
  CLEAN_TREE_EXEMPT_PATH,
  dirtyPathsBlocking,
  assertCleanTree
};

if (require.main === module) {
  main().catch((error) => {
    console.error(error instanceof Refusal ? error.message : error);
    process.exit(1);
  });
}
