const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '../..');

test('adopter-facing README prose uses lowercase mailglass at sentence starts', () => {
  const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
  const prose = readme
    .replace(/^```[\s\S]*?^```\s*$/gm, '')
    .replace(/`[^`]*`/g, '')
    .replace(/https?:\/\/\S+/g, '');

  assert.doesNotMatch(prose, /\b(?:Mailglass|MailGlass|MAILGLASS)\b/);
});
