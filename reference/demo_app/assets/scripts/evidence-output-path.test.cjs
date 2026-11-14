const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const { resolveEvidenceOutputPath } = require('./evidence-output-path.cjs');
const { stageRetainedEvidence } = require('./check-demo-browser-evidence.cjs');
const ROOT = path.resolve(__dirname, '../../tmp/demo_browser_evidence');

function owned(t) {
  fs.mkdirSync(ROOT, { recursive: true });
  const dir = fs.mkdtempSync(path.join(ROOT, '.path-guard-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  return dir;
}

test('evidence paths reject symlinked parent directories without touching outside data', t => {
  const dir = owned(t);
  const outside = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'mailglass-outside-')));
  t.after(() => fs.rmSync(outside, { recursive: true, force: true }));
  fs.mkdirSync(path.join(outside, 'retained'));
  const marker = path.join(outside, 'retained', 'keep.txt');
  fs.writeFileSync(marker, 'keep');
  fs.symlinkSync(outside, path.join(dir, 'redirect'), 'dir');
  assert.throws(() => resolveEvidenceOutputPath(path.join(dir, 'redirect', 'child')), /symlink/i);
  assert.throws(() => stageRetainedEvidence(path.join(dir, 'redirect'), { captures: [] }), /symlink/i);
  assert.equal(fs.readFileSync(marker, 'utf8'), 'keep');
});

test('retained staging rejects symlinked destination and preserves prior retained evidence', t => {
  const dir = owned(t);
  const outside = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'mailglass-retained-')));
  t.after(() => fs.rmSync(outside, { recursive: true, force: true }));
  fs.writeFileSync(path.join(outside, 'keep.txt'), 'keep');
  fs.symlinkSync(outside, path.join(dir, 'retained'), 'dir');
  assert.throws(() => stageRetainedEvidence(dir, { captures: [] }), /symlink/i);
  assert.equal(fs.readFileSync(path.join(outside, 'keep.txt'), 'utf8'), 'keep');
  fs.unlinkSync(path.join(dir, 'retained'));
  fs.mkdirSync(path.join(dir, 'retained'));
  fs.writeFileSync(path.join(dir, 'retained', 'old.txt'), 'old');
  stageRetainedEvidence(dir, { captures: [] });
  const prior = fs.readdirSync(dir).find(name => name.startsWith('.retained-prior-'));
  assert.ok(prior, 'previous evidence is archived, never recursively deleted');
  assert.equal(fs.readFileSync(path.join(dir, prior, 'old.txt'), 'utf8'), 'old');
  assert.ok(fs.existsSync(path.join(dir, 'retained', 'checkpoint.json')));
});
