import { realpathSync, readdirSync, statSync } from "node:fs";
import { relative, resolve, sep } from "node:path";

import type { ExtensionAPI } from "@gsd/pi-coding-agent";

const MAX_OUTPUT_BYTES = 16_000;
const PHASE_PATTERN = /^[1-9]\d*$/;
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
    process.exit(1);
  }
  throw new Error(message);
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

      let finalizer: string;
      try {
        finalizer = realpathSync(finalizerCandidate);
      } catch {
        const message = `finalize-phase: tracked finalizer is missing for phase ${phase}`;
        commandError(ctx, message);
      }

      if (!inside(repoRoot, phaseDirectory) || !inside(repoRoot, finalizer) || !statSync(finalizer).isFile()) {
        const message = `finalize-phase: finalizer for phase ${phase} is not a repository file`;
        commandError(ctx, message);
      }

      const finalizerRelative = relative(repoRoot, finalizer);
      // Equivalent to: git ls-files --error-unmatch -- <finalizer>
      const tracked = await pi.exec(
        "git",
        ["ls-files", "--error-unmatch", "--", finalizerRelative],
        { cwd: repoRoot },
      );

      if (tracked.code !== 0) {
        const message = `finalize-phase: finalizer for phase ${phase} is not tracked at HEAD`;
        commandError(ctx, message);
      }

      const result = await pi.exec("bash", [finalizer, repoRoot, ...modeArgs], { cwd: repoRoot });
      const output = boundedTail(result.stdout, result.stderr);

      if (result.code !== 0) {
        commandError(ctx, `finalize-phase: finalizer exited with status ${result.code}: ${output}`);
      }

      ctx.ui.notify(output, "success");
    },
  });
}
