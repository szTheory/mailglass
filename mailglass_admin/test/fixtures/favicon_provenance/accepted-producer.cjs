#!/usr/bin/env node

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const zlib = require("node:zlib");
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

function paethPredictor(left, up, upperLeft) {
  const estimate = left + up - upperLeft;
  const leftDistance = Math.abs(estimate - left);
  const upDistance = Math.abs(estimate - up);
  const upperLeftDistance = Math.abs(estimate - upperLeft);
  if (leftDistance <= upDistance && leftDistance <= upperLeftDistance) return left;
  if (upDistance <= upperLeftDistance) return up;
  return upperLeft;
}

// Decode only bounded, 8-bit, non-interlaced screenshot PNGs used by the theme probe. The
// independent ExUnit validator still checks chunk CRCs and all catalog metrics.
function decodePngPixels(bytes) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (!bytes.subarray(0, 8).equals(signature)) throw new Error("PNG signature is invalid");

  let offset = 8;
  let width;
  let height;
  let bitDepth;
  let colorType;
  let interlace;
  const idat = [];
  let ended = false;

  while (offset + 12 <= bytes.length) {
    const length = bytes.readUInt32BE(offset);
    const type = bytes.toString("ascii", offset + 4, offset + 8);
    const dataStart = offset + 8;
    const dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) throw new Error("PNG chunk is truncated");
    const data = bytes.subarray(dataStart, dataEnd);
    offset = dataEnd + 4;

    if (type === "IHDR") {
      if (length !== 13) throw new Error("PNG IHDR is malformed");
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      bitDepth = data[8];
      colorType = data[9];
      interlace = data[12];
    } else if (type === "IDAT") {
      idat.push(data);
    } else if (type === "IEND") {
      ended = true;
      break;
    }
  }

  const channels = colorType === 2 ? 3 : colorType === 6 ? 4 : 0;
  if (!ended || !width || !height || width > 64 || height > 64 || bitDepth !== 8 || !channels || interlace !== 0) {
    throw new Error("PNG format is unsupported for the theme probe");
  }

  const stride = width * channels;
  const expectedBytes = (stride + 1) * height;
  const filtered = zlib.inflateSync(Buffer.concat(idat), { maxOutputLength: expectedBytes });
  if (filtered.length !== expectedBytes) throw new Error("PNG decompressed size does not match IHDR");

  const decoded = Buffer.alloc(stride * height);
  let sourceOffset = 0;
  for (let y = 0; y < height; y += 1) {
    const filter = filtered[sourceOffset];
    const rowOffset = y * stride;
    sourceOffset += 1;
    if (filter > 4) throw new Error(`PNG row filter ${filter} is unsupported`);

    for (let x = 0; x < stride; x += 1) {
      const left = x >= channels ? decoded[rowOffset + x - channels] : 0;
      const up = y > 0 ? decoded[rowOffset - stride + x] : 0;
      const upperLeft = x >= channels && y > 0 ? decoded[rowOffset - stride + x - channels] : 0;
      let predictor = 0;
      if (filter === 1) predictor = left;
      else if (filter === 2) predictor = up;
      else if (filter === 3) predictor = Math.floor((left + up) / 2);
      else if (filter === 4) predictor = paethPredictor(left, up, upperLeft);
      decoded[rowOffset + x] = (filtered[sourceOffset + x] + predictor) & 255;
    }
    sourceOffset += stride;
  }

  const pixels = Buffer.alloc(width * height * 4);
  for (let index = 0; index < width * height; index += 1) {
    const inputOffset = index * channels;
    const outputOffset = index * 4;
    pixels[outputOffset] = decoded[inputOffset];
    pixels[outputOffset + 1] = decoded[inputOffset + 1];
    pixels[outputOffset + 2] = decoded[inputOffset + 2];
    pixels[outputOffset + 3] = channels === 4 ? decoded[inputOffset + 3] : 255;
  }

  return { width, height, pixels };
}

function pixelAt(raster, x, y) {
  const offset = (y * raster.width + x) * 4;
  return [...raster.pixels.subarray(offset, offset + 3)];
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

async function screenshotTile(page, size, background, scheme) {
  await page.setContent(
    `<!doctype html><meta name="color-scheme" content="light dark"><style>` +
      `html,body{margin:0;width:100%;height:100%;overflow:hidden}` +
      `.tile{width:${size}px;height:${size}px;display:grid;place-items:center;background:${background};color-scheme:${scheme}}` +
      `img{display:block;width:${size}px;height:${size}px;color-scheme:${scheme}}</style>` +
      `<div class="tile"><img alt="mailglass favicon" width="${size}" height="${size}" src="${page.__faviconDataUrls[scheme]}"></div>`,
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

async function themeProbe(engine, faviconDataUrls) {
  const captures = [];
  for (const scheme of SCHEMES) {
    const context = await engine.newContext({
      colorScheme: scheme,
      deviceScaleFactor: 1,
      viewport: { width: 32, height: 32 },
    });
    const page = await context.newPage();
    await page.emulateMedia({ colorScheme: scheme });
    const emulatedScheme = await page.evaluate(() =>
      window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light",
    );
    if (emulatedScheme !== scheme) {
      throw new Error(`expected page media ${scheme}, got ${emulatedScheme}`);
    }
    page.__faviconDataUrls = faviconDataUrls;
    const png = await screenshotTile(page, 32, "#ffffff", scheme);
    const raster = decodePngPixels(png);
    const expected = scheme === "dark"
      ? { glass: [70, 182, 232], pane: [168, 228, 247] }
      : { glass: [24, 149, 194], pane: [10, 100, 136] };
    // These samples land inside the flat glass stem and pane at 32 CSS pixels.
    const observed = { glass: pixelAt(raster, 3, 18), pane: pixelAt(raster, 16, 20) };
    if (JSON.stringify(observed) !== JSON.stringify(expected)) {
      throw new Error(`${scheme} theme probe used unexpected SVG colors ${JSON.stringify(observed)}`);
    }
    captures.push({ png, pixels: raster.pixels });
    await context.close();
  }
  if (captures[0].pixels.equals(captures[1].pixels)) {
    throw new Error("light/dark theme probe produced identical favicon pixels");
  }
  return {
    lightSha256: sha256(captures[0].png),
    darkSha256: sha256(captures[1].png),
    different: true,
  };
}

async function captureEngine(name, engineType, dataUrls, catalogDir, records, byteCount) {
  let browser;
  let currentEngine = null;
  const work = (async () => {
    browser = await engineType.launch({ headless: true, timeout: ENGINE_TIMEOUT_MS });
    currentEngine = { name, version: browser.version() };
    currentEngine.themeProbe = await themeProbe(browser, dataUrls);

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
        page.__faviconDataUrls = dataUrls;

        for (const size of SIZES) {
          for (const background of BACKGROUNDS[scheme]) {
            if (records.length >= PNG_CAP) throw new Error(`PNG cap ${PNG_CAP} would be exceeded`);
            const file = `${name}__${scheme}__${size}__${dpr}x__${background.id}.png`;
            const output = confined(file, catalogDir);
            const png = await screenshotTile(page, size, background.color, scheme);
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

  if (mode === "--check") {
    console.log(`favicon source pin passed (${sourceSha}); independent pixel checks run through ExUnit`);
    return;
  }

  fs.mkdirSync(CATALOG_ROOT, { recursive: true });
  const catalogId = `favicon-${sourceSha.slice(0, 7)}-${timestamp()}`;
  const catalogDir = confined(catalogId, CATALOG_ROOT);
  fs.mkdirSync(catalogDir, { recursive: false });
  const base64 = source.toString("base64");
  // Keep the SVG bytes identical while giving WebKit's SVG image cache a scheme-distinct key.
  const faviconDataUrls = {
    light: `data:image/svg+xml;base64,${base64}`,
    dark: `data:image/svg+xml;charset=utf-8;base64,${base64}`,
  };
  const records = [];
  const byteCount = { value: 0 };
  const engines = [];

  for (const [name, engineType] of Object.entries({ chromium, firefox, webkit })) {
    const result = await captureEngine(name, engineType, faviconDataUrls, catalogDir, records, byteCount);
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

if (require.main === module) {
  main().catch(error => {
    console.error(error?.stack || String(error));
    process.exitCode = 1;
  });
}

module.exports = { decodePngPixels };
