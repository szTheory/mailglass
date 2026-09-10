import {
  chmodSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  realpathSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { relative, resolve, sep } from "node:path";

import type { ExtensionAPI } from "@gsd/pi-coding-agent";

const MAX_OUTPUT_BYTES = 16_000;
const PHASE_PATTERN = /^[1-9]\d*$/;
const SUPPORTED_PHASE = "164";
const PRE_VERIFICATION = "--pre-verification";
type Dependency = { path: string; executable: boolean };

const STATIC_DEPENDENCIES: Dependency[] = [
  { path: "scripts/finalize_phase_164.sh", executable: true },
  { path: "scripts/closeout_repository_truth.sh", executable: true },
  { path: "scripts/verify_workspace_evidence.sh", executable: true },
  { path: "scripts/validate_repository_truth.exs", executable: true },
  { path: "scripts/ci_monitor.cjs", executable: true },
  { path: "scripts/scheduled_control_evidence.sh", executable: true },
  { path: ".github/scheduled-controls.json", executable: false },
  {
    path: ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md",
    executable: false,
  },
  {
    path: ".planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv",
    executable: false,
  },
  { path: ".planning/ROADMAP.md", executable: false },
  { path: ".planning/REQUIREMENTS.md", executable: false },
  { path: ".gitignore", executable: false },
  { path: "mailglass_admin/.gitignore", executable: false },
  { path: "mailglass_inbound/.gitignore", executable: false },
  { path: "reference/demo_app/.gitignore", executable: false },
  { path: "reference/host_app/.gitignore", executable: false },
  { path: "test/example/.gitignore", executable: false },
  { path: ".planning/release-target.json", executable: false },
  {
    path: ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md",
    executable: false,
  },
  {
    path: ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-UAT.md",
    executable: false,
  },
  {
    path: ".planning/phases/162-protected-release-and-scheduled-control-recovery/162-VERIFICATION.md",
    executable: false,
  },
  {
    path: ".planning/phases/163-deterministic-release-path-timeout-repairs/163-PROOF.md",
    executable: false,
  },
  {
    path: ".planning/phases/163-deterministic-release-path-timeout-repairs/163-VERIFICATION.md",
    executable: false,
  },
];

function phaseDependencies(phaseRelative: string): Dependency[] {
  return [
    { path: `${phaseRelative}/164-TRUTH-DISPOSITION.tsv`, executable: false },
    { path: `${phaseRelative}/164-VERIFICATION.md`, executable: false },
    { path: `${phaseRelative}/164-VALIDATION.md`, executable: false },
    { path: `${phaseRelative}/164-FINALIZATION.md`, executable: false },
  ];
}

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
  const lexicalPath = resolve(repoRoot, repositoryPath);
  let lexicalStat;
  try {
    lexicalStat = lstatSync(lexicalPath);
  } catch {
    commandError(ctx, `finalize-phase: ${label} is missing from the worktree`);
  }

  if (!inside(repoRoot, lexicalPath) || !lexicalStat.isFile() || lexicalStat.isSymbolicLink()) {
    commandError(ctx, `finalize-phase: ${label} is not a regular repository file`);
  }

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

async function numberedPhaseDependencies(
  pi: ExtensionAPI,
  repoRoot: string,
  phaseDirectory: string,
  ctx: { ui: { notify(message: string, level: "error"): void } },
): Promise<Dependency[]> {
  const phaseRelative = relative(repoRoot, phaseDirectory);
  const result = await pi.exec(
    "git",
    ["ls-tree", "-r", "--name-only", "-z", "HEAD", "--", phaseRelative],
    { cwd: repoRoot },
  );

  if (result.code !== 0 || !result.stdout.endsWith("\0")) {
    commandError(ctx, "finalize-phase: could not enumerate authenticated Phase 164 artifacts");
  }

  const pattern = new RegExp(`^${phaseRelative.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}/164-\\d{2}-(?:PLAN|SUMMARY)\\.md$`);
  const paths = result.stdout.split("\0").filter((path) => pattern.test(path));

  if (paths.length === 0 || new Set(paths).size !== paths.length) {
    commandError(ctx, "finalize-phase: authenticated Phase 164 artifact set is empty or duplicated");
  }

  return paths.map((path) => ({ path, executable: false }));
}

async function trackedTreeDependencies(
  pi: ExtensionAPI,
  repoRoot: string,
  treePath: string,
  ctx: { ui: { notify(message: string, level: "error"): void } },
): Promise<Dependency[]> {
  const result = await pi.exec(
    "git",
    ["ls-tree", "-r", "--name-only", "-z", "HEAD", "--", treePath],
    { cwd: repoRoot },
  );
  if (result.code !== 0 || !result.stdout.endsWith("\0")) {
    commandError(ctx, `finalize-phase: could not enumerate authenticated ${treePath}`);
  }
  const paths = result.stdout.split("\0").filter(Boolean);
  if (paths.length === 0 || new Set(paths).size !== paths.length) {
    commandError(ctx, `finalize-phase: authenticated ${treePath} is empty or duplicated`);
  }
  return paths.map((path) => ({ path, executable: false }));
}

function materializeDependency(root: string, dependency: Dependency, contents: string): void {
  const destination = resolve(root, dependency.path);
  if (!inside(root, destination)) throw new Error("finalize-phase: dependency path escaped authority root");
  mkdirSync(resolve(destination, ".."), { recursive: true, mode: 0o700 });
  writeFileSync(destination, contents, {
    encoding: "utf8",
    flag: "wx",
    mode: dependency.executable ? 0o500 : 0o400,
  });
  chmodSync(destination, dependency.executable ? 0o500 : 0o400);
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
      const phaseRelative = relative(repoRoot, phaseDirectory);
      await authenticateHeadFile(
        pi,
        repoRoot,
        finalizerRelative,
        `phase shim for ${phase}`,
        ctx,
      );
      const numberedDependencies = await numberedPhaseDependencies(pi, repoRoot, phaseDirectory, ctx);
      const publishDependencies = await trackedTreeDependencies(
        pi,
        repoRoot,
        ".planning/publish",
        ctx,
      );
      const dependencies = [
        ...STATIC_DEPENDENCIES,
        ...phaseDependencies(phaseRelative),
        ...numberedDependencies,
        ...publishDependencies,
      ];
      if (new Set(dependencies.map((dependency) => dependency.path)).size !== dependencies.length) {
        commandError(ctx, "finalize-phase: dependency manifest contains duplicate paths");
      }

      const authenticated = new Map<string, string>();
      for (const dependency of dependencies) {
        authenticated.set(
          dependency.path,
          await authenticateHeadFile(pi, repoRoot, dependency.path, dependency.path, ctx),
        );
      }

      const finalizer = realpathSync(finalizerCandidate);
      const downstream = realpathSync(downstreamCandidate);
      if (!inside(repoRoot, finalizer) || !inside(repoRoot, downstream)) {
        commandError(ctx, `finalize-phase: finalizer chain for phase ${phase} is not repository-contained`);
      }

      const privateDirectory = mkdtempSync(resolve(tmpdir(), `mailglass-finalize-${phase}-`));
      const privateFinalizer = resolve(privateDirectory, downstreamRelative);

      try {
        chmodSync(privateDirectory, 0o700);
        for (const dependency of dependencies) {
          materializeDependency(privateDirectory, dependency, authenticated.get(dependency.path)!);
        }

        const result = await pi.exec("bash", [privateFinalizer, repoRoot, privateDirectory, ...modeArgs], {
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
