const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const { captureAndSaveTile } = require("./favicon-capture.cjs");

test("favicon capture decodes the image before screenshot and PNG save", { timeout: 2_000 }, async t => {
  const output = path.join(os.tmpdir(), `mailglass-favicon-order-${process.pid}-${Date.now()}.png`);
  t.after(() => fs.rmSync(output, { force: true }));

  const events = [];
  let releaseDecode;
  let announceDecodeStarted;
  const decodeGate = new Promise(resolve => {
    releaseDecode = resolve;
  });
  const decodeStarted = new Promise(resolve => {
    announceDecodeStarted = resolve;
  });

  const page = {
    __faviconDataUrls: { light: "data:image/svg+xml;base64,PHN2Zz48L3N2Zz4=" },
    async setContent() {
      events.push("content");
    },
    async evaluate() {
      assert.ok(events.includes("decode:done"), "animation-frame wait started before image decode completed");
      events.push("frames");
    },
    locator(selector) {
      if (selector === "img") {
        return {
          async evaluate(callback) {
            await callback({
              async decode() {
                events.push("decode:start");
                announceDecodeStarted();
                await decodeGate;
                events.push("decode:done");
              },
              naturalWidth: 32,
              naturalHeight: 32,
            });
          },
        };
      }

      assert.equal(selector, ".tile");
      return {
        async screenshot() {
          assert.ok(events.includes("decode:done"), "screenshot started before image decode completed");
          assert.ok(events.includes("frames"), "screenshot started before frame settling completed");
          events.push("screenshot");
          return Buffer.from("synthetic png bytes");
        },
      };
    },
  };

  const capture = captureAndSaveTile(page, output, 32, "#ffffff", "light", png => {
    assert.ok(events.includes("screenshot"), "PNG validation ran before the screenshot completed");
    assert.equal(fs.existsSync(output), false, "PNG was saved before its dimensions and byte limit were validated");
    assert.deepEqual(png, Buffer.from("synthetic png bytes"));
    events.push("validate");
  });
  const firstEvent = await Promise.race([
    decodeStarted.then(() => "decode-started"),
    capture.then(() => "capture-finished"),
  ]);
  assert.equal(firstEvent, "decode-started", "capture finished before image decoding began");
  assert.equal(fs.existsSync(output), false, "PNG was saved while image decode was still pending");
  assert.equal(events.includes("screenshot"), false, "screenshot began while image decode was still pending");

  releaseDecode();
  const png = await capture;

  assert.deepEqual(events, ["content", "decode:start", "decode:done", "frames", "screenshot", "validate"]);
  assert.deepEqual(fs.readFileSync(output), png);
});
