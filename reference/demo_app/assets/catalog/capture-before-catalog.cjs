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

const CAP_IMAGES = 80;
const CAP_BYTES = 15_000_000;
const SCHEMA = "mailglass.before_catalog.v1";
const BUNDLE_PATH = "mailglass_admin/priv/static/app.css";
const ROOT_LAYOUT_PATH = "mailglass_admin/lib/mailglass_admin/layouts/root.html.heex";
const CATALOG_DIR_REL = ".planning/research/brand-v2-adoption/before-catalog";
const COMPOSE = ["compose", "-f", "compose.demo.yml"];
const SEED_EXPR = "MailglassDemo.CatalogSeed.seed!()";
const SENTINEL = "CATALOG_CASES_JSON=";
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
  const options = { only: null, promote: true };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--no-promote") options.promote = false;
    else if (argument === "--only") {
      options.only = argv[index + 1];
      index += 1;
      if (!options.only) refuse("--only needs a comma-separated list of capture ids, or `smoke`");
    } else refuse(`Unknown option: ${argument}`);
  }
  return options;
}

// ---------------------------------------------------------------------------------------
// Step (a): clean tree and source identity
// ---------------------------------------------------------------------------------------

function assertCleanTree(repoRoot, when) {
  const dirty = git(repoRoot, ["status", "--porcelain", "--untracked-files=all"]);
  if (dirty !== "") {
    refuse(
      `${when}: the working tree is dirty, so the recorded commit would not describe what was captured.\n` +
        `${dirty.split("\n").slice(0, 12).join("\n")}\nCommit or discard these changes, then run again.`
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

function restartDemo(repoRoot, runId, commitTime) {
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
  const startedAt = docker(repoRoot, ["inspect", "--format", "{{.State.StartedAt}}", id]).stdout.trim();
  const started = new Date(startedAt);
  if (Number.isNaN(started.getTime()) || started.getTime() <= new Date(commitTime).getTime()) {
    refuse(
      `The demo container started at ${startedAt}, which is not later than the source commit (${commitTime}). ` +
        "A stale server would serve old bytes, so nothing is captured."
    );
  }
  return started.toISOString();
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

function runSeed(repoRoot, args) {
  const result = docker(repoRoot, args, { timeout: 5 * 60 * 1000 });
  const line = `${result.stdout || ""}`
    .split("\n")
    .map((entry) => entry.trim())
    .find((entry) => entry.startsWith(SENTINEL));
  return { ok: result.status === 0 && Boolean(line), line, result };
}

async function seedCatalog(repoRoot, assetsDir, resetEnv) {
  const primary = ["compose", "-f", "compose.demo.yml", "exec", "-T", "demo", "mix", "run", "-e", SEED_EXPR];
  const first = runSeed(repoRoot, primary);
  if (first.ok) {
    console.log("seed branch: primary (docker compose exec demo mix run)");
    return { line: first.line, seed_command: "docker compose exec -T demo mix run -e CatalogSeed.seed!()" };
  }
  console.log(
    `The primary seed command failed (exit ${first.result.status}); resetting, then taking the in-harness fallback.`
  );
  console.log(`${first.result.stderr || ""}`.split("\n").slice(-8).join("\n"));
  // A partly applied primary seed would collide with the fixed catalog idempotency keys.
  await resetDemo(assetsDir, resetEnv);
  const fallback = ["compose", "-f", "compose.demo.yml", "run", "--rm", "--no-deps", "-T", "demo", "mix", "run", "-e", SEED_EXPR];
  const second = runSeed(repoRoot, fallback);
  if (!second.ok) {
    refuse(
      `The catalog seed failed on both branches (exit ${second.result.status}).\n` +
        `${`${second.result.stderr || ""}`.split("\n").slice(-12).join("\n")}`
    );
  }
  console.log("seed branch: in-harness fallback (docker compose run --rm --no-deps)");
  return { line: second.line, seed_command: "docker compose run --rm --no-deps -T demo mix run -e CatalogSeed.seed!()" };
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

function validate({ staging, captures, source, casesText, resetToken, full }) {
  const total = printBudget(captures);
  if (full) {
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

function buildManifest({ repoRoot, assetsDir, catalogId, runId, source, serverStartedAt, captures, casesSha, caseData, checked }) {
  const { computeSourceIdentity } = require(path.join(repoRoot, "scripts/check_phase174_evidence.cjs"));
  const identity = computeSourceIdentity(repoRoot, source.git_sha);
  const spec = fs.readFileSync(path.join(assetsDir, "catalog/before-catalog.spec.js"));
  const driver = fs.readFileSync(__filename);
  // sha256(spec bytes, NUL, driver bytes): the two scripts that produced the capture.
  const scriptHash = sha256(Buffer.concat([spec, Buffer.from([0]), driver]));
  const fonts = [...new Set(captures.flatMap((capture) => capture._fonts))].sort();

  return {
    schema: SCHEMA,
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
      server_started_at: serverStartedAt
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
}

// ---------------------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------------------

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const repoRoot = repoRootFrom(__dirname);
  const assetsDir = path.join(repoRoot, "reference/demo_app/assets");
  const catalogRoot = path.join(repoRoot, CATALOG_DIR_REL);
  const baseUrl = process.env.DEMO_BASE_URL || `http://127.0.0.1:${process.env.MAILGLASS_DEMO_HTTP_PORT || "4015"}/`;
  const resetToken = process.env.DEMO_EVIDENCE_RESET_TOKEN || "mailglass-dev-demo";

  // (a) clean tree, source identity
  const source = readSourceIdentity(repoRoot);

  // (b) ids; refuse to reuse an existing catalog
  const now = new Date();
  const runId = `mailglass-evidence-${utcStamp(now).replace("T", "").replace("Z", "")}-${process.pid}-${Math.floor(Math.random() * 90000) + 10000}`;
  const catalogId = `before-${source.git_sha.slice(0, 7)}-${utcStamp(now)}`;
  const finalDir = path.join(catalogRoot, catalogId);
  const staging = path.join(catalogRoot, ".cache", catalogId);
  if (fs.existsSync(finalDir) || fs.existsSync(staging)) refuse(`Refusing to reuse existing catalog ${catalogId}`);
  assertNoSymlink(staging);
  fs.mkdirSync(staging, { recursive: true });
  console.log(`catalog ${catalogId} from ${source.git_sha} (staging ${staging})`);

  // (c) restart so the server serves this commit
  const serverStartedAt = restartDemo(repoRoot, runId, source.committed_at);

  // (d) reset through the guarded helper
  const resetEnv = {
    DEMO_BASE_URL: baseUrl,
    DEMO_EVIDENCE_RUN_ID: runId,
    DEMO_EVIDENCE_RESET_TOKEN: resetToken
  };
  await resetDemo(assetsDir, resetEnv);

  // (e) seed the four missing cases
  const seeded = await seedCatalog(repoRoot, assetsDir, resetEnv);
  const caseData = JSON.parse(seeded.line.slice(SENTINEL.length));
  const casesText = `${JSON.stringify(caseData, null, 2)}\n`;
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
  const playwright = spawnSync(
    path.join(assetsDir, "node_modules/.bin/playwright"),
    ["test", "--config=playwright.catalog.config.cjs"],
    { cwd: assetsDir, env, stdio: "inherit" }
  );
  if (playwright.status !== 0) refuse(`The capture spec failed (exit ${playwright.status}). Nothing is promoted.`);

  // (g) validate
  const captures = collectCaptures(staging);
  const checked = validate({ staging, captures, source, casesText, resetToken, full: !options.only });

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
    catalogId,
    runId,
    source,
    serverStartedAt,
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
    return;
  }
  assertCleanTree(repoRoot, "Refusing to promote");
  if (fs.existsSync(finalDir)) refuse(`Refusing to reuse existing catalog ${catalogId}`);
  fs.renameSync(staging, finalDir);
  console.log(`promoted ${catalogId} to ${finalDir} (${captures.length} captures, ${checked.total} bytes; seed ${seeded.seed_command})`);
}

module.exports = { CATALOG_SMOKE_IDS };

if (require.main === module) {
  main().catch((error) => {
    console.error(error instanceof Refusal ? error.message : error);
    process.exit(1);
  });
}
