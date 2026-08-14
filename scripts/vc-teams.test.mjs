import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { execFile, spawn } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const repoRoot = process.cwd();
const scriptPath = path.join(repoRoot, "scripts", "vc-teams.js");

async function run(args, env) {
  const { stdout, stderr } = await execFileAsync("node", [scriptPath, ...args], {
    env,
    cwd: repoRoot,
  });
  return { stdout: stdout.trim(), stderr: stderr.trim() };
}

function spawnRun(args, env) {
  return spawn("node", [scriptPath, ...args], {
    env,
    cwd: repoRoot,
    stdio: ["ignore", "pipe", "pipe"],
  });
}

async function setupEnv() {
  const tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), "vc-teams-test-"));
  return {
    ...process.env,
    VC_TEAMS_DIR: path.join(tmpRoot, "teams"),
    VC_TEAMS_DEDUPE_WINDOW_MS: "60000",
  };
}

test("team lifecycle + request/response + dedupe", async () => {
  const env = await setupEnv();
  const team = "alpha-team";

  await run(["create", "--name", team], env);
  await run(["add-member", "--team", team, "--name", "researcher"], env);
  await run(["add-member", "--team", team, "--name", "implementer"], env);

  const req = await run([
    "send",
    "--team",
    team,
    "--type",
    "plan_approval_request",
    "--from",
    "team-lead",
    "--recipient",
    "researcher",
    "--content",
    "draft plan",
  ], env);
  assert.match(req.stdout, /requestId=/);
  const requestId = req.stdout.split("requestId=")[1]?.trim();
  assert.ok(requestId);

  const response = await run([
    "send",
    "--team",
    team,
    "--type",
    "plan_approval_response",
    "--from",
    "researcher",
    "--recipient",
    "team-lead",
    "--request-id",
    requestId,
    "--approve",
    "true",
    "--content",
    "approved",
  ], env);
  assert.match(response.stdout, /delivered=1/);

  await run([
    "send",
    "--team",
    team,
    "--type",
    "message",
    "--from",
    "team-lead",
    "--recipient",
    "implementer",
    "--content",
    "same message",
  ], env);
  const deduped = await run([
    "send",
    "--team",
    team,
    "--type",
    "message",
    "--from",
    "team-lead",
    "--recipient",
    "implementer",
    "--content",
    "same message",
  ], env);
  assert.match(deduped.stdout, /deduped=1/);

  const implementerInbox = await run([
    "read",
    "--team",
    team,
    "--agent",
    "implementer",
    "--json",
  ], env);
  const implementerMessages = JSON.parse(implementerInbox.stdout);
  assert.equal(implementerMessages.length, 1);

  const status = await run(["status", "--team", team, "--json"], env);
  const payload = JSON.parse(status.stdout);
  assert.equal(payload.pendingRequests.length, 0);

  await run(["remove-member", "--team", team, "--name", "researcher"], env);
  await run(["remove-member", "--team", team, "--name", "implementer"], env);
  await run(["delete", "--name", team], env);
});

test("watch emits snapshots and protocol guard rejects orphan response", async () => {
  const env = await setupEnv();
  const team = "watch-team";

  await run(["create", "--name", team], env);
  await run(["add-member", "--team", team, "--name", "reviewer"], env);

  const watch = spawnRun([
    "watch",
    "--team",
    team,
    "--json",
    "--interval-ms",
    "100",
    "--max-iterations",
    "3",
  ], env);

  let stdout = "";
  let stderr = "";
  watch.stdout.on("data", (chunk) => {
    stdout += chunk.toString();
  });
  watch.stderr.on("data", (chunk) => {
    stderr += chunk.toString();
  });

  await new Promise((resolve) => setTimeout(resolve, 120));
  await run([
    "send",
    "--team",
    team,
    "--type",
    "message",
    "--from",
    "team-lead",
    "--recipient",
    "reviewer",
    "--content",
    "hello watch",
  ], env);

  await new Promise((resolve, reject) => {
    watch.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`watch exited ${code}: ${stderr}`));
    });
  });

  assert.ok(stdout.trim().split("\n").length >= 2);

  await assert.rejects(
    run([
      "send",
      "--team",
      team,
      "--type",
      "shutdown_response",
      "--from",
      "reviewer",
      "--recipient",
      "team-lead",
      "--request-id",
      "missing-request-id",
      "--approve",
      "true",
      "--content",
      "ok",
    ], env),
    /No pending request/
  );

  await run(["remove-member", "--team", team, "--name", "reviewer"], env);
  await run(["delete", "--name", team], env);
});

test("await matches requestId and times out when missing", async () => {
  const env = await setupEnv();
  const team = "await-team";

  await run(["create", "--name", team], env);
  await run(["add-member", "--team", team, "--name", "worker"], env);

  const req = await run([
    "send",
    "--team",
    team,
    "--type",
    "shutdown_request",
    "--from",
    "team-lead",
    "--recipient",
    "worker",
    "--content",
    "stop",
  ], env);
  const requestId = req.stdout.split("requestId=")[1]?.trim();
  assert.ok(requestId);

  const awaitProc = spawnRun(
    [
      "await",
      "--team",
      team,
      "--agent",
      "team-lead",
      "--request-id",
      requestId,
      "--timeout-ms",
      "4000",
      "--json",
    ],
    env
  );

  let awaitOut = "";
  awaitProc.stdout.on("data", (chunk) => {
    awaitOut += chunk.toString();
  });

  await new Promise((resolve) => setTimeout(resolve, 200));
  await run([
    "send",
    "--team",
    team,
    "--type",
    "shutdown_response",
    "--from",
    "worker",
    "--recipient",
    "team-lead",
    "--request-id",
    requestId,
    "--approve",
    "true",
    "--content",
    "done",
  ], env);

  await new Promise((resolve, reject) => {
    awaitProc.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`await exited ${code}`));
    });
  });
  assert.match(awaitOut, /"requestId"/);

  await assert.rejects(
    run([
      "await",
      "--team",
      team,
      "--agent",
      "team-lead",
      "--request-id",
      "not-found",
      "--timeout-ms",
      "300",
    ], env),
    /Timed out waiting/
  );

  await run(["remove-member", "--team", team, "--name", "worker"], env);
  await run(["delete", "--name", team], env);
});

test("team names cannot escape the configured teams directory", async () => {
  const env = await setupEnv();

  await assert.rejects(
    run(["create", "--name", ".."], env),
    /Invalid name/
  );
  await assert.rejects(
    run(["delete", "--name", "..", "--force", "true"], env),
    /Invalid name/
  );
  await assert.rejects(
    run(["create", "--name", "a".repeat(65)], env),
    /Invalid name/
  );
});
