import { chmodSync, lstatSync, mkdtempSync, realpathSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { relative, resolve, sep } from "node:path";

import type { ExtensionAPI } from "@gsd/pi-coding-agent";

const MAX_OUTPUT_BYTES = 16_000;
const PHASE_PATTERN = /^[1-9]\d*$/;
const SUPPORTED_PHASE = "164";
const PRE_VERIFICATION = "--pre-verification";

function inside(root: string, candidate: string): boolean {
  const pathFromRoot = relative(root, candidate);
  return pathFromRoot === "" || (!pathFromRoot.startsWith(`..${sep}`) && pathFromRoot !== "..");
}

function boundedTail(stdout: string, stderr: string): string {
  const output = [stdout.trim(), stderr.trim()].filter(Boolean).join("\n");
  return (output || "(no output)").slice(-MAX_OUTPUT_BYTES);
}

function commandError(
  ctx: { ui: { notify(message: string, level: "error"): void } },
  message: string,
): never {
  ctx.ui.notify(message, "error");
  process.exitCode = 1;
  if (process.argv.includes("--print")) {
    console.error(message);
  }
  throw new Error(message);
}

async function authenticateHeadFile(
  pi: ExtensionAPI,
  repoRoot: string,
  repositoryPath: string,
  label: string,
  ctx: { ui: { notify(message: string, level: "error"): void } },
): Promise<string> {
  const objectType = await pi.exec("git", ["cat-file", "-t", `HEAD:${repositoryPath}`], {
    cwd: repoRoot,
  });

  if (objectType.code !== 0 || objectType.stdout.trim() !== "blob") {
    commandError(ctx, `finalize-phase: ${label} is not a blob at HEAD`);
  }

  const tracked = await pi.exec(
    "git",
    ["--literal-pathspecs", "ls-files", "--error-unmatch", "--", repositoryPath],
    { cwd: repoRoot },
  );
  const returnedPaths = tracked.stdout.replace(/\r\n/g, "\n").replace(/\n$/, "").split("\n");

  if (tracked.code !== 0 || returnedPaths.length !== 1 || returnedPaths[0] !== repositoryPath) {
    commandError(ctx, `finalize-phase: ${label} is not the exact tracked path at HEAD`);
  }

  const stagedDifference = await pi.exec(
    "git",
    ["--literal-pathspecs", "diff", "--cached", "--quiet", "HEAD", "--", repositoryPath],
    { cwd: repoRoot },
  );
  const workingDifference = await pi.exec(
    "git",
    ["--literal-pathspecs", "diff", "--quiet", "--", repositoryPath],
    { cwd: repoRoot },
  );

  if (stagedDifference.code !== 0 || workingDifference.code !== 0) {
    commandError(ctx, `finalize-phase: ${label} differs from HEAD`);
  }

  const blob = await pi.exec("git", ["show", `HEAD:${repositoryPath}`], { cwd: repoRoot });

  if (blob.code !== 0) {
    commandError(ctx, `finalize-phase: could not read authenticated ${label} blob`);
  }

  return blob.stdout;
}

export default function finalizePhaseExtension(pi: ExtensionAPI): void {
  pi.registerCommand("finalize-phase", {
    description: "Finalize a phase after all tracked completion metadata reaches protected main",
    handler: async (args, ctx) => {
      const tokens = args.trim() === "" ? [] : args.trim().split(/\s+/);
      const validMode = tokens.length === 1 || (tokens.length === 2 && tokens[1] === PRE_VERIFICATION);

      if (!validMode || !PHASE_PATTERN.test(tokens[0] ?? "")) {
        const message =
          "finalize-phase: expected one positive integer phase and optional --pre-verification";
        commandError(ctx, message);
      }

      const phase = tokens[0];

      if (phase !== SUPPORTED_PHASE) {
        commandError(ctx, `finalize-phase: only phase ${SUPPORTED_PHASE} is supported`);
      }

      const modeArgs = tokens.length === 2 ? [PRE_VERIFICATION] : [];
      const rootResult = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd: ctx.cwd });

      if (rootResult.code !== 0 || rootResult.stdout.trim() === "") {
        const message = "finalize-phase: current directory is not inside a Git repository";
        commandError(ctx, message);
      }

      const repoRoot = realpathSync(rootResult.stdout.trim());
      const phasesRoot = realpathSync(resolve(repoRoot, ".planning/phases"));

      if (!inside(repoRoot, phasesRoot)) {
        const message = "finalize-phase: planning phases directory escapes the repository";
        commandError(ctx, message);
      }

      const phaseDirectories = readdirSync(phasesRoot, { withFileTypes: true })
        .filter((entry) => entry.isDirectory() && entry.name.startsWith(`${phase}-`))
        .map((entry) => resolve(phasesRoot, entry.name));

      if (phaseDirectories.length !== 1) {
        const message = `finalize-phase: expected exactly one phase directory for ${phase}`;
        commandError(ctx, message);
      }

      const phaseDirectory = realpathSync(phaseDirectories[0]);
      const finalizerCandidate = resolve(phaseDirectory, `${phase}-FINALIZE.sh`);
      const downstreamCandidate = resolve(repoRoot, "scripts/finalize_phase_164.sh");

      let finalizerStat;
      let downstreamStat;
      try {
        finalizerStat = lstatSync(finalizerCandidate);
        downstreamStat = lstatSync(downstreamCandidate);
      } catch {
        const message = `finalize-phase: finalizer chain is missing for phase ${phase}`;
        commandError(ctx, message);
      }

      if (
        !inside(repoRoot, phaseDirectory) ||
        !inside(repoRoot, finalizerCandidate) ||
        !inside(repoRoot, downstreamCandidate) ||
        !finalizerStat.isFile() ||
        finalizerStat.isSymbolicLink() ||
        !downstreamStat.isFile() ||
        downstreamStat.isSymbolicLink()
      ) {
        const message = `finalize-phase: finalizer chain for phase ${phase} is not repository-contained`;
        commandError(ctx, message);
      }

      const finalizerRelative = relative(repoRoot, finalizerCandidate);
      const downstreamRelative = relative(repoRoot, downstreamCandidate);
      await authenticateHeadFile(
        pi,
        repoRoot,
        finalizerRelative,
        `phase shim for ${phase}`,
        ctx,
      );
      const downstreamBlob = await authenticateHeadFile(
        pi,
        repoRoot,
        downstreamRelative,
        `downstream finalizer for ${phase}`,
        ctx,
      );

      const finalizer = realpathSync(finalizerCandidate);
      const downstream = realpathSync(downstreamCandidate);
      if (!inside(repoRoot, finalizer) || !inside(repoRoot, downstream)) {
        commandError(ctx, `finalize-phase: finalizer chain for phase ${phase} is not repository-contained`);
      }

      const privateDirectory = mkdtempSync(resolve(tmpdir(), `mailglass-finalize-${phase}-`));
      const privateFinalizer = resolve(privateDirectory, "finalize.sh");

      try {
        chmodSync(privateDirectory, 0o700);
        writeFileSync(privateFinalizer, downstreamBlob, { encoding: "utf8", flag: "wx", mode: 0o500 });
        chmodSync(privateFinalizer, 0o500);

        const result = await pi.exec("bash", [privateFinalizer, repoRoot, ...modeArgs], {
          cwd: repoRoot,
        });
        const output = boundedTail(result.stdout, result.stderr);

        if (result.code !== 0) {
          commandError(ctx, `finalize-phase: finalizer exited with status ${result.code}: ${output}`);
        }

        ctx.ui.notify(output, "success");
      } finally {
        rmSync(privateDirectory, { recursive: true, force: true });
      }
    },
  });
}
