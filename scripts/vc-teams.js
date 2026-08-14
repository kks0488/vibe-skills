#!/usr/bin/env node
import fs from "fs/promises";
import os from "os";
import path from "path";
import crypto from "crypto";

const COLOR_PALETTE = [
  "red",
  "blue",
  "green",
  "yellow",
  "purple",
  "orange",
  "pink",
  "cyan",
];

const MESSAGE_TYPES = new Set([
  "message",
  "broadcast",
  "shutdown_request",
  "shutdown_response",
  "shutdown_approved",
  "shutdown_rejected",
  "plan_approval_request",
  "plan_approval_response",
  "permission_request",
  "permission_response",
  "idle_notification",
]);

const REQUEST_TYPES = new Set(["shutdown_request", "plan_approval_request"]);
const RESPONSE_TYPES = new Set(["shutdown_response", "plan_approval_response", "shutdown_approved", "shutdown_rejected"]);

const VC_HOME = process.env.VC_HOME || path.join(os.homedir(), ".vc");
const TEAMS_DIR = process.env.VC_TEAMS_DIR || path.join(VC_HOME, "teams");
const LOCK_TTL_MS = Number(process.env.VC_TEAMS_LOCK_TTL_MS || 5 * 60 * 1000);
const DEDUPE_WINDOW_MS = Number(process.env.VC_TEAMS_DEDUPE_WINDOW_MS || 30 * 1000);

function usage() {
  console.log(`vc teams commands:
  vc teams create --name <team> [--description <text>] [--agent-type <type>] [--lead-name <name>] [--model <model>] [--plan-mode-required <bool>]
  vc teams delete --name <team> [--force]
  vc teams add-member --team <team> --name <agent> [--agent-type <type>] [--model <model>] [--backend <codex|tmux-assist>] [--plan-mode-required <bool>]
  vc teams remove-member --team <team> --name <agent>
  vc teams send --team <team> --type <${Array.from(MESSAGE_TYPES).join("|")}> [--from <agent>] [--recipient <agent>] [--content <text>] [--summary <text>] [--request-id <id>] [--approve <bool>]
  vc teams status --team <team> [--json]
  vc teams watch --team <team> [--agent <name>] [--interval-ms <n>] [--once] [--max-iterations <n>] [--json]
  vc teams await --team <team> --agent <name> --request-id <id> [--timeout-ms <n>] [--poll-ms <n>] [--mark-read <bool>] [--json]
  vc teams read --team <team> --agent <name> [--unread] [--json]
  vc teams mark-read --team <team> --agent <name> --id <message-id>
  vc teams prune --team <team> [--days <n>] [--message-days <n>] [--task-days <n>]

compat aliases:
  vc teams teamcreate --team_name <team> [--description <text>] [--agent_type <type>]
  vc teams teamdelete --team_name <team>
  vc teams sendmessage --team_name <team> --type <...> [protocol fields]
`);
}

function parseOptions(argv) {
  const options = { _: [] };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) {
      options._.push(token);
      continue;
    }

    const eq = token.indexOf("=");
    if (eq > -1) {
      const key = token.slice(2, eq);
      options[key] = token.slice(eq + 1);
      continue;
    }

    const key = token.slice(2);
    const next = argv[i + 1];
    if (next && !next.startsWith("--")) {
      options[key] = next;
      i += 1;
    } else {
      options[key] = true;
    }
  }
  return options;
}

function pickOption(opts, keys) {
  for (const key of keys) {
    const value = opts[key];
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return value;
    }
  }
  return undefined;
}

function requiredOption(opts, keys, errorLabel) {
  const value = pickOption(opts, keys);
  if (value === undefined) throw new Error(`Missing required arg: ${errorLabel}`);
  return value;
}

function sanitizeName(value) {
  const normalized = String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  if (
    !normalized ||
    normalized === "." ||
    normalized === ".." ||
    normalized.length > 64 ||
    !/^[a-z0-9][a-z0-9._-]*$/.test(normalized)
  ) {
    throw new Error(`Invalid name: "${value}"`);
  }
  return normalized;
}

function makeAgentId(agentName, teamName) {
  return `${sanitizeName(agentName)}@${sanitizeName(teamName)}`;
}

function parseBoolean(value, fallback = false) {
  if (value === undefined || value === null || value === "") return fallback;
  if (typeof value === "boolean") return value;
  const s = String(value).trim().toLowerCase();
  if (["1", "true", "yes", "y", "on"].includes(s)) return true;
  if (["0", "false", "no", "n", "off"].includes(s)) return false;
  throw new Error(`Invalid boolean: ${value}`);
}

function parsePositiveInt(value, label) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 1 || !Number.isInteger(parsed)) {
    throw new Error(`${label} must be a positive integer`);
  }
  return parsed;
}

function colorForAgent(agentId) {
  let hash = 0;
  for (let i = 0; i < agentId.length; i += 1) {
    hash = (hash * 31 + agentId.charCodeAt(i)) >>> 0;
  }
  return COLOR_PALETTE[hash % COLOR_PALETTE.length];
}

function teamDirForName(teamName) {
  return path.join(TEAMS_DIR, sanitizeName(teamName));
}

function inboxPath(teamName, agentName) {
  return path.join(teamDirForName(teamName), "inboxes", `${sanitizeName(agentName)}.json`);
}

function teamConfigPath(teamName) {
  return path.join(teamDirForName(teamName), "config.json");
}

function requestsPath(teamName) {
  return path.join(teamDirForName(teamName), "requests.json");
}

function eventsPath(teamName) {
  return path.join(teamDirForName(teamName), "events.jsonl");
}

async function sleep(ms) {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function ensureDir(dirPath) {
  await fs.mkdir(dirPath, { recursive: true });
}

async function readJson(filePath, fallbackValue) {
  try {
    const raw = await fs.readFile(filePath, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    if (error && error.code === "ENOENT") return fallbackValue;
    throw error;
  }
}

async function writeJsonAtomic(filePath, value) {
  await ensureDir(path.dirname(filePath));
  const tmp = `${filePath}.tmp-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const text = `${JSON.stringify(value, null, 2)}\n`;
  await fs.writeFile(tmp, text, "utf8");
  await fs.rename(tmp, filePath);
}

async function removeStaleLockIfNeeded(lockPath) {
  try {
    const stat = await fs.stat(lockPath);
    const age = Date.now() - stat.mtimeMs;
    if (age > LOCK_TTL_MS) {
      await fs.rm(lockPath, { force: true });
      return true;
    }
  } catch {
    // ignore
  }
  return false;
}

async function withLock(targetPath, fn) {
  const lockPath = `${targetPath}.lock`;
  let attempt = 0;
  let lockHandle = null;

  while (true) {
    try {
      lockHandle = await fs.open(lockPath, "wx");
      try {
        await lockHandle.writeFile(`${process.pid}:${new Date().toISOString()}\n`, "utf8");
      } catch {
        // best effort metadata
      }
      break;
    } catch (error) {
      if (error && error.code === "EEXIST") {
        const staleRemoved = await removeStaleLockIfNeeded(lockPath);
        if (staleRemoved) continue;
        if (attempt < 40) {
          const delay = Math.min(1000, Math.round(25 * Math.pow(1.35, attempt)));
          attempt += 1;
          await sleep(delay);
          continue;
        }
      }
      throw error;
    }
  }

  try {
    return await fn();
  } finally {
    if (lockHandle) {
      try {
        await lockHandle.close();
      } catch {
        // Best effort cleanup.
      }
    }
    try {
      await fs.unlink(lockPath);
    } catch {
      // Best effort cleanup.
    }
  }
}

async function ensureMailbox(teamName, agentName) {
  const file = inboxPath(teamName, agentName);
  await ensureDir(path.dirname(file));
  const existing = await readJson(file, null);
  if (existing === null) {
    await writeJsonAtomic(file, []);
  }
}

async function ensureRequestsFile(teamName) {
  const file = requestsPath(teamName);
  const existing = await readJson(file, null);
  if (existing === null) {
    await writeJsonAtomic(file, []);
  }
}

function isRecentDuplicate(message, incomingDedupeKey, nowMs, windowMs) {
  if (!message || message.dedupeKey !== incomingDedupeKey) return false;
  const ts = Date.parse(message.timestamp || "");
  if (Number.isNaN(ts)) return false;
  return nowMs - ts <= windowMs;
}

async function appendMailbox(teamName, recipient, message, dedupeWindowMs = DEDUPE_WINDOW_MS) {
  const file = inboxPath(teamName, recipient);
  await ensureMailbox(teamName, recipient);
  return withLock(file, async () => {
    const messages = await readJson(file, []);
    const nowMs = Date.now();

    if (message.dedupeKey) {
      const duplicate = messages.find((entry) => isRecentDuplicate(entry, message.dedupeKey, nowMs, dedupeWindowMs));
      if (duplicate) {
        return { id: duplicate.id, duplicate: true };
      }
    }

    messages.push(message);
    await writeJsonAtomic(file, messages);
    return { id: message.id, duplicate: false };
  });
}

async function appendEvent(teamName, eventType, payload = {}) {
  const eventFile = eventsPath(teamName);
  await ensureDir(path.dirname(eventFile));

  const line = `${JSON.stringify({
    ts: new Date().toISOString(),
    type: eventType,
    payload,
  })}\n`;

  await withLock(eventFile, async () => {
    await fs.appendFile(eventFile, line, "utf8");
  });
}

async function readTeamConfig(teamName) {
  const configPath = teamConfigPath(teamName);
  const config = await readJson(configPath, null);
  if (!config) {
    throw new Error(`Team not found: ${teamName}`);
  }
  return { config, configPath };
}

function normalizeMessageType(type, approve) {
  if (type === "shutdown_response") {
    return approve ? "shutdown_approved" : "shutdown_rejected";
  }
  return type;
}

function computeDedupeKey({ from, recipient, type, text, summary, requestId, approve }) {
  const bucket = Math.floor(Date.now() / DEDUPE_WINDOW_MS);
  const raw = [from, recipient || "", type, text || "", summary || "", requestId || "", String(approve ?? ""), bucket].join("|");
  return crypto.createHash("sha256").update(raw).digest("hex").slice(0, 24);
}

function buildMessageEnvelope({ type, from, recipient, content, summary, requestId, approve, noDedupe }) {
  const effectiveType = normalizeMessageType(type, approve);
  const envelope = {
    id: crypto.randomUUID(),
    type: effectiveType,
    rawType: type,
    from: sanitizeName(from),
    recipient: recipient ? sanitizeName(recipient) : undefined,
    text: content || "",
    summary: summary || "",
    timestamp: new Date().toISOString(),
    color: colorForAgent(`${sanitizeName(from)}@msg`),
    read: false,
    requestId,
    approve,
    dedupeKey: noDedupe ? undefined : computeDedupeKey({
      from: sanitizeName(from),
      recipient: recipient ? sanitizeName(recipient) : "",
      type: effectiveType,
      text: content || "",
      summary: summary || "",
      requestId,
      approve,
    }),
  };

  validateMessageEnvelope(envelope);
  return envelope;
}

function validateMessageEnvelope(message) {
  if (!message.id || typeof message.id !== "string") throw new Error("Invalid message: id");
  if (!message.type || !MESSAGE_TYPES.has(message.type)) throw new Error(`Invalid message type: ${message.type}`);
  if (!message.from || typeof message.from !== "string") throw new Error("Invalid message: from");
  if (!message.timestamp || Number.isNaN(Date.parse(message.timestamp))) throw new Error("Invalid message: timestamp");
  if (typeof message.read !== "boolean") throw new Error("Invalid message: read");

  if ((message.type === "shutdown_approved" || message.type === "shutdown_rejected") && typeof message.requestId !== "string") {
    throw new Error(`Message type ${message.type} requires requestId`);
  }

  if (message.rawType === "plan_approval_response") {
    if (typeof message.requestId !== "string") throw new Error("plan_approval_response requires requestId");
    if (typeof message.approve !== "boolean") throw new Error("plan_approval_response requires approve boolean");
  }
}

function ensureMemberExists(config, name) {
  const normalized = sanitizeName(name);
  const member = config.members.find((entry) => entry.name === normalized);
  if (!member) {
    throw new Error(`Member not found in team "${config.name}": ${name}`);
  }
  return member;
}

async function addPendingRequest(teamName, item) {
  const file = requestsPath(teamName);
  await ensureRequestsFile(teamName);
  await withLock(file, async () => {
    const requests = await readJson(file, []);
    requests.push(item);
    await writeJsonAtomic(file, requests);
  });
}

async function resolvePendingRequest(teamName, requestId, resolverName, approve, resolutionType) {
  const file = requestsPath(teamName);
  await ensureRequestsFile(teamName);

  return withLock(file, async () => {
    const requests = await readJson(file, []);
    const index = requests.findIndex((entry) => entry.requestId === requestId && entry.status === "pending");
    if (index < 0) {
      throw new Error(`No pending request for requestId=${requestId}`);
    }

    requests[index].status = approve ? "approved" : "rejected";
    requests[index].resolvedAt = new Date().toISOString();
    requests[index].resolvedBy = sanitizeName(resolverName);
    requests[index].resolutionType = resolutionType;
    await writeJsonAtomic(file, requests);
    return requests[index];
  });
}

async function getPendingRequests(teamName) {
  const file = requestsPath(teamName);
  const requests = await readJson(file, []);
  return requests.filter((entry) => entry.status === "pending");
}

async function commandCreate(opts) {
  const rawName = requiredOption(opts, ["name", "team", "team_name"], "--name");
  const teamName = sanitizeName(rawName);
  const teamDir = teamDirForName(teamName);
  const configPath = teamConfigPath(teamName);
  const exists = await readJson(configPath, null);
  if (exists) {
    throw new Error(`Team already exists: ${teamName}`);
  }

  const leadName = sanitizeName(pickOption(opts, ["lead-name", "lead_name"]) || "team-lead");
  const leadAgentId = makeAgentId(leadName, teamName);
  const model = pickOption(opts, ["model"]) || process.env.MODEL || "";
  const now = Date.now();

  const config = {
    schemaVersion: 1,
    name: teamName,
    description: pickOption(opts, ["description"]) || "",
    createdAt: now,
    leadAgentId,
    leadSessionId: process.env.PARENT_SESSION_ID || process.env.CLAUDE_PARENT_SESSION_ID || crypto.randomUUID(),
    members: [
      {
        agentId: leadAgentId,
        name: leadName,
        agentType: pickOption(opts, ["agent-type", "agent_type"]) || "lead",
        model,
        prompt: "",
        color: colorForAgent(leadAgentId),
        planModeRequired: parseBoolean(pickOption(opts, ["plan-mode-required", "plan_mode_required"]), false),
        joinedAt: now,
        tmuxPaneId: "",
        cwd: process.cwd(),
        subscriptions: [],
        backendType: "codex",
      },
    ],
    hiddenPaneIds: [],
    stats: {
      dedupedMessages: 0,
      staleLocksRecovered: 0,
    },
  };

  await ensureDir(path.join(teamDir, "inboxes"));
  await ensureDir(path.join(teamDir, "tasks"));
  await writeJsonAtomic(configPath, config);
  await ensureMailbox(teamName, leadName);
  await ensureRequestsFile(teamName);
  await appendEvent(teamName, "team_created", {
    teamName,
    leadName,
  });

  console.log(`Created team: ${teamName}`);
  console.log(`Team config: ${configPath}`);
  console.log(`Lead: ${leadName}`);
}

async function commandDelete(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["name", "team", "team_name"], "--name"));
  const force = parseBoolean(pickOption(opts, ["force"]), false);
  const { config } = await readTeamConfig(teamName);

  const activeTeammates = config.members.filter((member) => member.agentId !== config.leadAgentId);
  if (activeTeammates.length > 0 && !force) {
    const names = activeTeammates.map((member) => member.name).join(", ");
    throw new Error(
      `Refusing to delete team with active members: ${names}. Remove members first or pass --force true`
    );
  }

  await appendEvent(teamName, "team_deleted", { force, memberCount: config.members.length });
  await fs.rm(teamDirForName(teamName), { recursive: true, force: true });
  console.log(`Deleted team: ${teamName}`);
}

async function commandAddMember(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "team_name"], "--team"));
  const memberName = sanitizeName(requiredOption(opts, ["name", "agent", "agent_name"], "--name"));

  const { config, configPath } = await readTeamConfig(teamName);
  const exists = config.members.some((member) => member.name === memberName);
  if (exists) throw new Error(`Member already exists: ${memberName}`);

  const agentId = makeAgentId(memberName, teamName);
  const entry = {
    agentId,
    name: memberName,
    agentType: pickOption(opts, ["agent-type", "agent_type"]) || "teammate",
    model: pickOption(opts, ["model"]) || "",
    prompt: pickOption(opts, ["prompt"]) || "",
    color: pickOption(opts, ["color"]) || colorForAgent(agentId),
    planModeRequired: parseBoolean(pickOption(opts, ["plan-mode-required", "plan_mode_required"]), false),
    joinedAt: Date.now(),
    tmuxPaneId: "",
    cwd: process.cwd(),
    subscriptions: [],
    backendType: pickOption(opts, ["backend"]) || "codex",
  };

  await withLock(configPath, async () => {
    const latest = await readJson(configPath, null);
    if (!latest) throw new Error(`Team missing while updating: ${teamName}`);
    latest.members.push(entry);
    await writeJsonAtomic(configPath, latest);
  });

  await ensureMailbox(teamName, memberName);
  await appendEvent(teamName, "member_added", { member: memberName, agentType: entry.agentType });
  console.log(`Added member ${memberName} to ${teamName}`);
}

async function commandRemoveMember(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "team_name"], "--team"));
  const memberName = sanitizeName(requiredOption(opts, ["name", "agent", "agent_name"], "--name"));

  const { config, configPath } = await readTeamConfig(teamName);
  const target = ensureMemberExists(config, memberName);
  if (target.agentId === config.leadAgentId) {
    throw new Error("Cannot remove the team lead member");
  }

  await withLock(configPath, async () => {
    const latest = await readJson(configPath, null);
    if (!latest) throw new Error(`Team missing while updating: ${teamName}`);
    latest.members = latest.members.filter((member) => member.name !== memberName);
    await writeJsonAtomic(configPath, latest);
  });

  await fs.rm(inboxPath(teamName, memberName), { force: true });
  await appendEvent(teamName, "member_removed", { member: memberName });
  console.log(`Removed member ${memberName} from ${teamName}`);
}

function isResponseInputType(type) {
  return type === "shutdown_response" || type === "plan_approval_response" || type === "shutdown_approved" || type === "shutdown_rejected";
}

async function resolveRecipients(config, messageType, from, recipient) {
  const normalizedFrom = sanitizeName(from || "team-lead");

  if (messageType === "broadcast" || messageType === "idle_notification") {
    return config.members
      .map((member) => member.name)
      .filter((memberName) => memberName !== normalizedFrom);
  }

  if (!recipient) {
    throw new Error(`--recipient is required for type=${messageType}`);
  }
  ensureMemberExists(config, recipient);
  return [sanitizeName(recipient)];
}

async function commandSend(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "team_name"], "--team"));
  const type = String(requiredOption(opts, ["type"], "--type")).trim();
  if (!MESSAGE_TYPES.has(type)) {
    throw new Error(`Unsupported type=${type}. Allowed: ${Array.from(MESSAGE_TYPES).join(", ")}`);
  }

  const { config, configPath } = await readTeamConfig(teamName);
  const from = sanitizeName(pickOption(opts, ["from"]) || "team-lead");
  ensureMemberExists(config, from);

  const recipient = pickOption(opts, ["recipient", "to"]);
  const content = pickOption(opts, ["content", "text"]) || "";
  const summary = pickOption(opts, ["summary"]) || "";
  const noDedupe = parseBoolean(pickOption(opts, ["no-dedupe", "no_dedupe"]), false);
  let requestId = pickOption(opts, ["request-id", "request_id"]);
  let approve = pickOption(opts, ["approve"]);

  if ((type === "message" || type === "broadcast") && !content) {
    throw new Error("--content is required for type=message|broadcast");
  }

  if (REQUEST_TYPES.has(type)) {
    if (!requestId) requestId = crypto.randomUUID();
  }

  if (isResponseInputType(type)) {
    if (!requestId) throw new Error(`--request-id is required for type=${type}`);
  }

  if (type === "shutdown_response" || type === "plan_approval_response" || type === "shutdown_approved" || type === "shutdown_rejected") {
    if (type === "shutdown_approved") approve = true;
    if (type === "shutdown_rejected") approve = false;
    if (approve === undefined) {
      throw new Error(`--approve is required for type=${type}`);
    }
    approve = parseBoolean(approve);
  } else {
    approve = approve === undefined ? undefined : parseBoolean(approve);
  }

  const recipients = await resolveRecipients(config, type, from, recipient);

  if (REQUEST_TYPES.has(type)) {
    await addPendingRequest(teamName, {
      requestId,
      requestType: type,
      status: "pending",
      createdAt: new Date().toISOString(),
      from,
      to: recipients[0],
      summary,
    });
  }

  if (isResponseInputType(type)) {
    await resolvePendingRequest(teamName, requestId, from, Boolean(approve), type);
  }

  let delivered = 0;
  let deduped = 0;

  for (const target of recipients) {
    const envelope = buildMessageEnvelope({
      type,
      from,
      recipient: target,
      content,
      summary,
      requestId,
      approve,
      noDedupe,
    });

    const result = await appendMailbox(teamName, target, envelope);
    if (result.duplicate) {
      deduped += 1;
      continue;
    }
    delivered += 1;
  }

  if (deduped > 0) {
    await withLock(configPath, async () => {
      const latest = await readJson(configPath, null);
      if (!latest) return;
      if (!latest.stats) latest.stats = { dedupedMessages: 0, staleLocksRecovered: 0 };
      latest.stats.dedupedMessages = (latest.stats.dedupedMessages || 0) + deduped;
      await writeJsonAtomic(configPath, latest);
    });
  }

  await appendEvent(teamName, "message_sent", {
    type,
    from,
    recipients,
    delivered,
    deduped,
    requestId,
    approve,
  });

  const requestInfo = requestId ? ` requestId=${requestId}` : "";
  console.log(
    `Sent ${type} from ${from} to ${recipients.length} recipients (delivered=${delivered}, deduped=${deduped})${requestInfo}`
  );
}

async function listInboxStats(teamName, config) {
  const inboxes = [];
  for (const member of config.members) {
    const file = inboxPath(teamName, member.name);
    const messages = await readJson(file, []);
    inboxes.push({
      agent: member.name,
      total: messages.length,
      unread: messages.filter((message) => !message.read).length,
      lastTimestamp: messages.length > 0 ? messages[messages.length - 1].timestamp : null,
    });
  }
  return inboxes;
}

async function buildStatus(teamName, filterAgent) {
  const { config, configPath } = await readTeamConfig(teamName);
  const inboxes = await listInboxStats(teamName, config);
  const pendingRequests = await getPendingRequests(teamName);

  const filteredInboxes = filterAgent
    ? inboxes.filter((entry) => entry.agent === sanitizeName(filterAgent))
    : inboxes;

  return {
    team: config.name,
    description: config.description || "",
    createdAt: config.createdAt,
    leadAgentId: config.leadAgentId,
    members: config.members,
    configPath,
    requestsPath: requestsPath(teamName),
    eventsPath: eventsPath(teamName),
    inboxes: filteredInboxes,
    pendingRequests,
    stats: config.stats || { dedupedMessages: 0, staleLocksRecovered: 0 },
  };
}

function printStatus(payload) {
  console.log(`Team: ${payload.team}`);
  console.log(`Config: ${payload.configPath}`);
  console.log(`Members: ${payload.members.length}`);
  for (const member of payload.members) {
    console.log(`- ${member.name} (${member.agentType}, color=${member.color}, backend=${member.backendType})`);
  }
  console.log(`Pending Requests: ${payload.pendingRequests.length}`);
  for (const req of payload.pendingRequests) {
    console.log(`- ${req.requestId} type=${req.requestType} from=${req.from} to=${req.to} at=${req.createdAt}`);
  }
  console.log(`Stats: dedupedMessages=${payload.stats.dedupedMessages || 0}`);
  console.log("Inboxes:");
  for (const entry of payload.inboxes) {
    console.log(`- ${entry.agent}: unread=${entry.unread}, total=${entry.total}, last=${entry.lastTimestamp || "-"}`);
  }
}

async function commandStatus(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "name", "team_name"], "--team"));
  const payload = await buildStatus(teamName, pickOption(opts, ["agent"]));

  if (parseBoolean(pickOption(opts, ["json"]), false)) {
    console.log(JSON.stringify(payload, null, 2));
    return;
  }
  printStatus(payload);
}

async function commandWatch(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "team_name"], "--team"));
  const agentFilter = pickOption(opts, ["agent"]);
  const intervalMs = pickOption(opts, ["interval-ms", "interval_ms"])
    ? parsePositiveInt(pickOption(opts, ["interval-ms", "interval_ms"]), "--interval-ms")
    : 1000;
  const once = parseBoolean(pickOption(opts, ["once"]), false);
  const maxIterations = pickOption(opts, ["max-iterations", "max_iterations"])
    ? parsePositiveInt(pickOption(opts, ["max-iterations", "max_iterations"]), "--max-iterations")
    : 0;
  const asJson = parseBoolean(pickOption(opts, ["json"]), false);

  let previousKey = "";
  let iterations = 0;

  while (true) {
    const payload = await buildStatus(teamName, agentFilter);
    const watchView = {
      ts: new Date().toISOString(),
      team: payload.team,
      inboxes: payload.inboxes,
      pendingRequests: payload.pendingRequests,
      stats: payload.stats,
    };

    const key = JSON.stringify(watchView);
    if (key !== previousKey) {
      if (asJson) {
        console.log(JSON.stringify(watchView));
      } else {
        console.log(`--- watch @ ${watchView.ts} ---`);
        console.log(`team=${watchView.team} pending=${watchView.pendingRequests.length} deduped=${watchView.stats.dedupedMessages || 0}`);
        for (const entry of watchView.inboxes) {
          console.log(`inbox ${entry.agent}: unread=${entry.unread} total=${entry.total} last=${entry.lastTimestamp || "-"}`);
        }
      }
      previousKey = key;
    }

    iterations += 1;
    if (once) return;
    if (maxIterations > 0 && iterations >= maxIterations) return;
    await sleep(intervalMs);
  }
}

async function commandRead(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "team_name"], "--team"));
  const agentName = sanitizeName(requiredOption(opts, ["agent", "name", "agent_name"], "--agent"));

  const { config } = await readTeamConfig(teamName);
  ensureMemberExists(config, agentName);

  const messages = await readJson(inboxPath(teamName, agentName), []);
  const unreadOnly = parseBoolean(pickOption(opts, ["unread"]), false);
  const filtered = unreadOnly ? messages.filter((message) => !message.read) : messages;

  if (parseBoolean(pickOption(opts, ["json"]), false)) {
    console.log(JSON.stringify(filtered, null, 2));
    return;
  }

  if (filtered.length === 0) {
    console.log("No messages");
    return;
  }

  for (const message of filtered) {
    validateMessageEnvelope(message);
    const summary = message.summary ? ` summary="${message.summary}"` : "";
    console.log(`<teammate-message teammate_id="${message.from}" color="${message.color || "blue"}"${summary}>`);
    console.log(message.text || "");
    console.log(`</teammate-message> id=${message.id} type=${message.type} requestId=${message.requestId || "-"} read=${message.read}`);
  }
}

async function commandAwait(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "team_name"], "--team"));
  const agentName = sanitizeName(requiredOption(opts, ["agent", "agent_name"], "--agent"));
  const requestId = String(requiredOption(opts, ["request-id", "request_id"], "--request-id")).trim();
  const timeoutMs = pickOption(opts, ["timeout-ms", "timeout_ms"])
    ? parsePositiveInt(pickOption(opts, ["timeout-ms", "timeout_ms"]), "--timeout-ms")
    : 15000;
  const pollMs = pickOption(opts, ["poll-ms", "poll_ms"])
    ? parsePositiveInt(pickOption(opts, ["poll-ms", "poll_ms"]), "--poll-ms")
    : 300;
  const markRead = parseBoolean(pickOption(opts, ["mark-read", "mark_read"]), false);
  const asJson = parseBoolean(pickOption(opts, ["json"]), false);

  const { config } = await readTeamConfig(teamName);
  ensureMemberExists(config, agentName);

  const started = Date.now();
  const file = inboxPath(teamName, agentName);

  while (Date.now() - started <= timeoutMs) {
    const messages = await readJson(file, []);
    const index = messages.findIndex((message) => message.requestId === requestId);

    if (index >= 0) {
      const message = messages[index];
      if (markRead && !message.read) {
        await withLock(file, async () => {
          const latest = await readJson(file, []);
          const latestIndex = latest.findIndex((entry) => entry.id === message.id);
          if (latestIndex >= 0) {
            latest[latestIndex].read = true;
            latest[latestIndex].readAt = new Date().toISOString();
            await writeJsonAtomic(file, latest);
          }
        });
      }

      await appendEvent(teamName, "await_match", {
        agent: agentName,
        requestId,
        messageId: message.id,
        type: message.type,
      });

      if (asJson) {
        console.log(JSON.stringify(message, null, 2));
      } else {
        console.log(
          `Matched requestId=${requestId} for agent=${agentName} type=${message.type} id=${message.id}`
        );
      }
      return;
    }

    await sleep(pollMs);
  }

  await appendEvent(teamName, "await_timeout", {
    agent: agentName,
    requestId,
    timeoutMs,
  });
  throw new Error(
    `Timed out waiting for requestId=${requestId} on agent=${agentName} after ${timeoutMs}ms`
  );
}

async function commandMarkRead(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "team_name"], "--team"));
  const agentName = sanitizeName(requiredOption(opts, ["agent", "agent_name"], "--agent"));
  const messageId = requiredOption(opts, ["id", "message_id"], "--id");

  const file = inboxPath(teamName, agentName);
  await withLock(file, async () => {
    const messages = await readJson(file, []);
    const index = messages.findIndex((entry) => entry.id === messageId);
    if (index < 0) throw new Error(`Message not found: ${messageId}`);
    messages[index].read = true;
    messages[index].readAt = new Date().toISOString();
    await writeJsonAtomic(file, messages);
  });

  await appendEvent(teamName, "message_mark_read", { agent: agentName, id: messageId });
  console.log(`Marked message as read: ${messageId}`);
}

async function commandPrune(opts) {
  const teamName = sanitizeName(requiredOption(opts, ["team", "name", "team_name"], "--team"));

  const sharedDays = pickOption(opts, ["days"]);
  const messageDays = pickOption(opts, ["message-days", "message_days"]) || sharedDays || "7";
  const taskDays = pickOption(opts, ["task-days", "task_days"]) || sharedDays || "7";
  const messageCutoff = Date.now() - parsePositiveInt(messageDays, "--message-days") * 24 * 60 * 60 * 1000;
  const taskCutoff = Date.now() - parsePositiveInt(taskDays, "--task-days") * 24 * 60 * 60 * 1000;

  const { config } = await readTeamConfig(teamName);

  let removedMessages = 0;
  for (const member of config.members) {
    const file = inboxPath(teamName, member.name);
    await withLock(file, async () => {
      const messages = await readJson(file, []);
      const kept = messages.filter((message) => {
        if (!message.timestamp) return true;
        const ts = Date.parse(message.timestamp);
        if (Number.isNaN(ts)) return true;
        if (!message.read) return true;
        return ts >= messageCutoff;
      });
      removedMessages += messages.length - kept.length;
      await writeJsonAtomic(file, kept);
    });
  }

  let removedTasks = 0;
  const tasksDir = path.join(teamDirForName(teamName), "tasks");
  try {
    const entries = await fs.readdir(tasksDir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isFile()) continue;
      const taskPath = path.join(tasksDir, entry.name);
      const stat = await fs.stat(taskPath);
      if (stat.mtimeMs < taskCutoff) {
        await fs.rm(taskPath, { force: true });
        removedTasks += 1;
      }
    }
  } catch {
    // tasks dir may not exist.
  }

  await appendEvent(teamName, "team_pruned", {
    removedMessages,
    removedTasks,
    messageDays: parsePositiveInt(messageDays, "--message-days"),
    taskDays: parsePositiveInt(taskDays, "--task-days"),
  });

  console.log(`Pruned team ${teamName}: removed ${removedMessages} messages, ${removedTasks} task files`);
}

async function main() {
  const [command, ...rest] = process.argv.slice(2);
  if (!command || command === "help" || command === "--help" || command === "-h") {
    usage();
    process.exit(0);
  }

  const opts = parseOptions(rest);

  switch (command) {
    case "create":
    case "teamcreate":
      await commandCreate(opts);
      break;
    case "delete":
    case "teamdelete":
      await commandDelete(opts);
      break;
    case "add-member":
      await commandAddMember(opts);
      break;
    case "remove-member":
      await commandRemoveMember(opts);
      break;
    case "send":
    case "sendmessage":
      await commandSend(opts);
      break;
    case "status":
      await commandStatus(opts);
      break;
    case "watch":
      await commandWatch(opts);
      break;
    case "read":
      await commandRead(opts);
      break;
    case "await":
    case "await-response":
      await commandAwait(opts);
      break;
    case "mark-read":
      await commandMarkRead(opts);
      break;
    case "prune":
      await commandPrune(opts);
      break;
    default:
      throw new Error(`Unknown teams command: ${command}`);
  }
}

main().catch((error) => {
  console.error(`Error: ${error.message}`);
  process.exit(1);
});
