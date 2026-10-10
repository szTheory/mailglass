"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

function assertSafeParent(parent, trustedRoot) {
  const absolute = path.resolve(parent);
  const root = path.resolve(trustedRoot);
  const rootStat = fs.lstatSync(root);
  if (rootStat.isSymbolicLink() || !rootStat.isDirectory()) {
    throw new Error(`JSON evidence root is not a real directory: ${root}`);
  }
  if (absolute !== root && !absolute.startsWith(`${root}${path.sep}`)) {
    throw new Error(`JSON evidence parent escapes its trusted root: ${absolute}`);
  }
  let current = root;
  for (const part of (absolute === root ? "" : absolute.slice(root.length + 1)).split(path.sep).filter(Boolean)) {
    current = path.join(current, part);
    const stat = fs.lstatSync(current);
    if (stat.isSymbolicLink() || !stat.isDirectory()) {
      throw new Error(`JSON evidence parent is not a real directory: ${current}`);
    }
  }
  return absolute;
}

function writeJson(outputPath, value, trustedRoot = process.cwd()) {
  const destination = path.resolve(outputPath);
  const parent = assertSafeParent(path.dirname(destination), trustedRoot);
  let existing;
  try {
    existing = fs.lstatSync(destination);
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  if (existing && (existing.isSymbolicLink() || !existing.isFile())) {
    throw new Error(`JSON evidence destination is not a regular file: ${destination}`);
  }

  const temporary = path.join(parent, `.${path.basename(destination)}.${process.pid}.${crypto.randomBytes(8).toString("hex")}.tmp`);
  let fd;
  try {
    fd = fs.openSync(temporary, "wx", 0o600);
    fs.writeFileSync(fd, `${JSON.stringify(value, null, 2)}\n`, "utf8");
    fs.fsyncSync(fd);
    fs.closeSync(fd);
    fd = undefined;

    // Recheck the parent immediately before rename. Rename replaces a planted
    // destination symlink itself, so it cannot follow that link to its target.
    if (assertSafeParent(parent, trustedRoot) !== parent) throw new Error("JSON evidence parent changed during write");
    fs.renameSync(temporary, destination);
  } catch (error) {
    if (fd !== undefined) fs.closeSync(fd);
    try { fs.unlinkSync(temporary); } catch (cleanupError) {
      if (cleanupError.code !== "ENOENT") throw cleanupError;
    }
    throw error;
  }
}

module.exports = { writeJson };
