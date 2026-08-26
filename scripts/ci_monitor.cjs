#!/usr/bin/env node

const { spawnSync } = require("node:child_process");

const RUN_LIST_FIELDS =
  "databaseId,workflowName,headBranch,headSha,event,status,conclusion,url,createdAt";
const RUN_VIEW_FIELDS =
  "databaseId,workflowName,headBranch,headSha,event,status,conclusion,url,jobs";

const HELP = `Usage: node scripts/ci_monitor.cjs <command> [arguments]

Commands:
  runs [--branch <name>]       List the 20 most recent workflow runs as JSON.
  inspect <run-id>             Inspect one exact run and its jobs as JSON.
  watch <run-id>               Watch one exact run and fail on non-success.
  fail-fast <run-id>           Alias for watch.
  log-failed <run-id>          Print logs for failed steps in one exact run.
  pr-inspect <pr-number>       Inspect exact PR identity and check rollup as JSON.
  pr-create --base <branch> --head <branch> --title <text> --body-file <path>
                               Open a PR using a file-backed body.
  --help                       Show this help.
`;

function buildCommand(argv) {
  const [command, ...args] = argv;

  switch (command) {
    case "runs":
      return buildRuns(args);

    case "inspect":
      return ["run", "view", exactRunId(args), "--json", RUN_VIEW_FIELDS];

    case "watch":
    case "fail-fast":
      return [
        "run",
        "watch",
        exactRunId(args),
        "--exit-status",
        "--interval",
        "10"
      ];

    case "log-failed":
      return ["run", "view", exactRunId(args), "--log-failed"];

    case "pr-inspect":
      return [
        "pr",
        "view",
        exactPositiveInteger(args, "pr-number"),
        "--json",
        "number,state,isDraft,headRefName,headRefOid,baseRefName,url,statusCheckRollup"
      ];

    case "pr-create":
      return buildPrCreate(args);

    default:
      throw new Error(`unknown command: ${command || "<missing>"}`);
  }
}

function buildRuns(args) {
  const command = ["run", "list", "--limit", "20"];

  if (args.length === 0) return [...command, "--json", RUN_LIST_FIELDS];
  if (args.length !== 2 || args[0] !== "--branch") {
    throw new Error(`unknown argument for runs: ${args.join(" ")}`);
  }

  return [...command, "--branch", stableValue("branch", args[1]), "--json", RUN_LIST_FIELDS];
}

function exactRunId(args) {
  return exactPositiveInteger(args, "run-id");
}

function exactPositiveInteger(args, name) {
  if (args.length !== 1 || !/^[1-9][0-9]*$/.test(args[0])) {
    throw new Error(`${name} must be a positive integer`);
  }

  return args[0];
}

function buildPrCreate(args) {
  const expected = ["--base", "--head", "--title", "--body-file"];

  if (args.length !== expected.length * 2) {
    throw new Error(`pr-create requires ${expected.join(", ")}`);
  }

  const values = new Map();

  for (let index = 0; index < args.length; index += 2) {
    const flag = args[index];
    if (!expected.includes(flag) || values.has(flag)) {
      throw new Error(`unknown or duplicate pr-create argument: ${flag}`);
    }
    values.set(flag, stableValue(flag.slice(2), args[index + 1]));
  }

  for (const flag of expected) {
    if (!values.has(flag)) throw new Error(`pr-create requires ${flag}`);
  }

  return [
    "pr",
    "create",
    ...expected.flatMap(flag => [flag, values.get(flag)])
  ];
}

function stableValue(name, value) {
  if (typeof value !== "string" || value.length === 0 || /[\r\n\0]/.test(value)) {
    throw new Error(`${name} must be a non-empty single-line value`);
  }

  return value;
}

function main(argv) {
  if (argv.length === 0 || argv[0] === "--help" || argv[0] === "help") {
    process.stdout.write(HELP);
    return;
  }

  let command;
  try {
    command = buildCommand(argv);
  } catch (error) {
    process.stderr.write(`ci_monitor: ${error.message}\n\n${HELP}`);
    process.exitCode = 2;
    return;
  }

  process.stderr.write(`ci_monitor: gh ${command.map(arg => JSON.stringify(arg)).join(" ")}\n`);
  const result = spawnSync(process.env.CI_MONITOR_GH_BIN || "gh", command, {
    stdio: "inherit"
  });

  if (result.error) {
    process.stderr.write(`ci_monitor: ${result.error.message}\n`);
    process.exitCode = 1;
    return;
  }

  process.exitCode = result.status === null ? 1 : result.status;
}

if (require.main === module) main(process.argv.slice(2));

module.exports = { buildCommand };
