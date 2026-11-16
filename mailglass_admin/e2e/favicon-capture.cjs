#!/usr/bin/env node

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { chromium, firefox, webkit } = require("playwright");

const REPO_ROOT = path.resolve(__dirname, "../..");
const CATALOG_ROOT = path.join(
  REPO_ROOT,
  ".planning/research/brand-v2-adoption/favicon-catalog",
);
const SOURCE_REL = "brandbook/v2/favicon.svg";
const SERVED_REL = "mailglass_admin/priv/static/favicon.svg";
const SCRIPT_REL = "mailglass_admin/e2e/favicon-capture.cjs";
const PNG_CAP = 120;
const BYTE_CAP = 5_000_000;
const ENGINE_TIMEOUT_MS = 90_000;
const SIZES = [16, 24, 32];
const DPRS = [1, 2];
const SCHEMES = ["light", "dark"];
const BACKGROUNDS = {
  light: [
    { id: "white", color: "#ffffff" },
    { id: "offwhite", color: "#f9f9fb" },
    { id: "tab-grey", color: "#dee1e6" },
  ],
  dark: [
    { id: "chrome", color: "#35363a" },
    { id: "black", color: "#202124" },
    { id: "purple", color: "#2b2a33" },
  ],
};

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function confined(relative, root) {
  const resolved = path.resolve(root, relative);
  const rel = path.relative(root, resolved);
  if (!rel || rel === ".." || rel.startsWith(`..${path.sep}`) || path.isAbsolute(rel)) {
    throw new Error(`output path escapes catalog root: ${relative}`);
  }
  return resolved;
}

function timestamp() {
  return new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
}

function parsePngHeader(bytes) {
  if (bytes.length < 24 || !bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    throw new Error("Playwright produced a file without a PNG header");
  }
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}

function rgb(hex) {
  const value = hex.replace("#", "");
  return [0, 2, 4].map(offset => Number.parseInt(value.slice(offset, offset + 2), 16));
}

function luminance(color) {
  const channels = color.map(value => {
    const channel = value / 255;
    return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
  });
  return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
}

function contrastRatio(first, second) {
  const a = luminance(rgb(first));
  const b = luminance(rgb(second));
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

async function screenshotTile(page, size, background) {
  await page.setContent(
    `<!doctype html><meta name="color-scheme" content="light dark"><style>` +
      `html,body{margin:0;width:100%;height:100%;overflow:hidden}` +
      `.tile{width:${size}px;height:${size}px;display:grid;place-items:center;background:${background}}` +
      `img{display:block;width:${size}px;height:${size}px}</style>` +
      `<div class="tile"><img alt="mailglass favicon" width="${size}" height="${size}" src="${page.__faviconDataUrl}"></div>`,
    { waitUntil: "load", timeout: 15_000 },
  );
  await page.locator("img").evaluate(async img => {
    if (typeof img.decode === "function") await img.decode();
    else if (!img.complete || img.naturalWidth === 0) {
      await new Promise((resolve, reject) => {
        img.addEventListener("load", resolve, { once: true });
        img.addEventListener("error", reject, { once: true });
      });
    }
    if (img.naturalWidth <= 0 || img.naturalHeight <= 0 || img.naturalWidth !== img.naturalHeight) {
      throw new Error(`decoded SVG has invalid natural dimensions ${img.naturalWidth}x${img.naturalHeight}`);
    }
  });
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  return page.locator(".tile").screenshot({ animations: "disabled", scale: "device", timeout: 15_000 });
}

async function themeProbe(engine, faviconDataUrl) {
  const captures = [];
  for (const scheme of SCHEMES) {
    const context = await engine.newContext({
      colorScheme: scheme,
      deviceScaleFactor: 1,
      viewport: { width: 32, height: 32 },
    });
    const page = await context.newPage();
    await page.emulateMedia({ colorScheme: scheme });
    page.__faviconDataUrl = faviconDataUrl;
    captures.push(await screenshotTile(page, 32, "#ffffff"));
    await context.close();
  }
  if (captures[0].equals(captures[1])) {
    throw new Error("light/dark theme probe produced identical favicon raster bytes");
  }
  return {
    lightSha256: sha256(captures[0]),
    darkSha256: sha256(captures[1]),
    different: true,
  };
}

async function captureEngine(name, engineType, dataUrl, catalogDir, records, byteCount) {
  let browser;
  let currentEngine = null;
  const work = (async () => {
    browser = await engineType.launch({ headless: true, timeout: ENGINE_TIMEOUT_MS });
    currentEngine = { name, version: browser.version() };
    currentEngine.themeProbe = await themeProbe(browser, dataUrl);

    for (const scheme of SCHEMES) {
      for (const dpr of DPRS) {
        const context = await browser.newContext({
          colorScheme: scheme,
          deviceScaleFactor: dpr,
          viewport: { width: 40, height: 40 },
        });
        const page = await context.newPage();
        await page.emulateMedia({ colorScheme: scheme });
        page.setDefaultTimeout(15_000);
        page.__faviconDataUrl = dataUrl;

        for (const size of SIZES) {
          for (const background of BACKGROUNDS[scheme]) {
            if (records.length >= PNG_CAP) throw new Error(`PNG cap ${PNG_CAP} would be exceeded`);
            const file = `${name}__${scheme}__${size}__${dpr}x__${background.id}.png`;
            const output = confined(file, catalogDir);
            const png = await screenshotTile(page, size, background.color);
            const { width, height } = parsePngHeader(png);
            if (width !== size * dpr || height !== size * dpr) {
              throw new Error(`${file}: expected ${size * dpr}x${size * dpr}, got ${width}x${height}`);
            }
            byteCount.value += png.length;
            if (byteCount.value > BYTE_CAP) throw new Error(`capture exceeds ${BYTE_CAP} byte cap`);
            fs.writeFileSync(output, png, { flag: "wx" });
            records.push({
              file,
              engine: name,
              engineVersion: currentEngine.version,
              scheme,
              size,
              dpr,
              background: background.color,
              width,
              height,
              bytes: png.length,
              sha256: sha256(png),
            });
          }
        }
        await context.close();
      }
    }
    await browser.close();
    browser = null;
    return currentEngine;
  })();

  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(`${name} exceeded the ${ENGINE_TIMEOUT_MS} ms engine timeout`)), ENGINE_TIMEOUT_MS);
  });
  try {
    return await Promise.race([work, timeout]);
  } catch (error) {
    if (browser) await browser.close().catch(() => {});
    work.catch(() => {});
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

async function main() {
  const startedAt = new Date().toISOString();
  const mode = process.argv[2];
  if (!["--capture", "--check"].includes(mode) || process.argv.length !== 3) {
    throw new Error("usage: node mailglass_admin/e2e/favicon-capture.cjs --capture|--check");
  }

  const sourcePath = path.join(REPO_ROOT, SOURCE_REL);
  const servedPath = path.join(REPO_ROOT, SERVED_REL);
  const pin = JSON.parse(fs.readFileSync(path.join(REPO_ROOT, "brandbook/brand.pin.json"), "utf8"));
  const source = fs.readFileSync(sourcePath);
  const sourceSha = sha256(source);
  const servedSha = sha256(fs.readFileSync(servedPath));
  const sourceEntry = pin.shipped.find(entry => entry.to === SOURCE_REL);
  if (!sourceEntry || sourceEntry.sha256 !== sourceSha || sourceEntry.bytes !== source.length) {
    throw new Error("favicon source does not match the brand pin");
  }
  if (servedSha !== sourceSha) throw new Error("served favicon does not match the pinned source");

  fs.mkdirSync(CATALOG_ROOT, { recursive: true });
  const catalogId = `favicon-${sourceSha.slice(0, 7)}-${timestamp()}`;
  const catalogDir = confined(catalogId, CATALOG_ROOT);
  fs.mkdirSync(catalogDir, { recursive: false });
  const faviconDataUrl = `data:image/svg+xml;base64,${source.toString("base64")}`;
  const records = [];
  const byteCount = { value: 0 };
  const engines = [];

  for (const [name, engineType] of Object.entries({ chromium, firefox, webkit })) {
    const result = await captureEngine(name, engineType, faviconDataUrl, catalogDir, records, byteCount);
    engines.push(result);
    if (sha256(fs.readFileSync(sourcePath)) !== sourceSha) {
      throw new Error("favicon source changed while the browser capture was running");
    }
  }

  if (records.length !== 108) throw new Error(`expected 108 capture cells, got ${records.length}`);
  const safariRiskSimulation = BACKGROUNDS.dark.map(({ color }) => ({
    background: color,
    glassContrast: Number(contrastRatio("#1895C2", color).toFixed(3)),
    overlapContrast: Number(contrastRatio("#0A6488", color).toFixed(3)),
  }));
  const manifest = {
    schema: "mailglass.favicon_catalog.v1",
    catalogId,
    startedAt,
    capturedAt: new Date().toISOString(),
    sourceRevision: pin.commit,
    source: { path: SOURCE_REL, sha256: sourceSha, bytes: source.length },
    served: { path: SERVED_REL, sha256: servedSha },
    producer: { path: SCRIPT_REL, sha256: sha256(fs.readFileSync(path.join(REPO_ROOT, SCRIPT_REL))) },
    engines,
    matrix: {
      schemes: SCHEMES,
      sizes: SIZES,
      dprs: DPRS,
      backgrounds: BACKGROUNDS,
      cells: records.length,
    },
    metrics: {
      inkContrastRatio: 1.15,
      minimumGlyphWidthFraction: 0.8,
      minimumGlyphHeightFraction: 0.5,
      stemSampleHeightFraction: 0.75,
      minimumGapPhysicalPixelsPerDpr: 1,
      minimumLightGlassContrast: 3.0,
      minimumGreyGlassContrast: 2.5,
      minimumDarkGlassContrast: 4.5,
      minimumPaneContrastAt24And32: 1.3,
      crossEngineInkMaskIoU: 0.9,
    },
    diagnostics: {
      safariLightArtworkOnDarkSurfaces: safariRiskSimulation,
      safariTabChromeObserved: false,
      note: "The light artwork-on-dark raster is a Safari-risk simulation; Playwright captures the SVG as an image and does not observe real Safari tab chrome.",
    },
    limits: { pngFiles: PNG_CAP, totalPngBytes: BYTE_CAP, engineTimeoutMs: ENGINE_TIMEOUT_MS },
    captures: records,
  };

  const manifestPath = confined("manifest.json", catalogDir);
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { flag: "wx" });
  console.log(`${mode === "--check" ? "checked" : "captured"} ${records.length} cells in ${path.relative(REPO_ROOT, catalogDir)}`);
  console.log(`source sha256 ${sourceSha}; ${byteCount.value} PNG bytes`);
}

main().catch(error => {
  console.error(error?.stack || String(error));
  process.exitCode = 1;
});
