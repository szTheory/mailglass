// Run 40904249445 failed only on hosted: local node_modules masked its MODULE_NOT_FOUND.
// This test-only preload constrains Module._resolveFilename to each CI job's npm install roots.
// MAILGLASS_REQUIRE_GUARD_ALLOWED is path-delimited; MAILGLASS_REQUIRE_GUARD_RECORD is optional.
const Module = require("node:module");
const path = require("node:path");
const fs = require("node:fs");

const recordPath = process.env.MAILGLASS_REQUIRE_GUARD_RECORD;
const allowedRoots = (process.env.MAILGLASS_REQUIRE_GUARD_ALLOWED || "")
  .split(path.delimiter)
  .filter(Boolean)
  .map(root => {
    try {
      return fs.realpathSync(root);
    } catch {
      return null;
    }
  })
  .filter(Boolean);

function record(line) {
  if (recordPath) fs.appendFileSync(recordPath, `${line}\n`);
}

if (process.argv[1]) record(`loaded\t${process.argv[1]}`);

const resolveFilename = Module._resolveFilename;
Module._resolveFilename = function (request, parent, isMain, options) {
  let resolved;
  try {
    resolved = resolveFilename.call(this, request, parent, isMain, options);
  } catch (error) {
    throw error;
  }

  if (Module.isBuiltin(request) || request.startsWith(".") || path.isAbsolute(request)) {
    return resolved;
  }

  const parts = resolved.split(path.sep);
  const nodeModulesIndex = parts.indexOf("node_modules");
  const packageRoot = nodeModulesIndex < 0
    ? null
    : path.join(path.sep, ...parts.slice(0, nodeModulesIndex));
  let canonicalRoot = null;
  try {
    if (packageRoot) canonicalRoot = fs.realpathSync(packageRoot);
  } catch {
    canonicalRoot = null;
  }

  if (canonicalRoot && allowedRoots.includes(canonicalRoot)) return resolved;

  record(`violation\t${request}\t${parent?.filename || "<unknown>"}`);
  const error = new Error(
    `Cannot find module '${request}' required by ${parent?.filename || "<unknown>"}: not installed by this CI job (ci-require-guard)`
  );
  error.code = "MODULE_NOT_FOUND";
  throw error;
};
