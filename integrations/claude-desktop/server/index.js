#!/usr/bin/env node
// OpenShape 3D for Claude Desktop — a relay, nothing more.
//
// Claude Desktop speaks MCP over stdio; the OpenShape 3D app speaks MCP over
// HTTP on this computer (Settings ▸ AI Assistant). This copies each JSON-RPC
// line from one to the other, adding the pairing code. No dependencies: Node's
// own http module, so there is nothing to install.
//
// It answers for the app in exactly three situations, all so that a person
// who has never seen a terminal gets a sentence instead of a dead extension:
// the handshake and the tool list when the app is not running (tools.json is
// the app's own catalog), and a tool call that cannot be delivered.
"use strict";
const http = require("http");
const path = require("path");
const fs = require("fs");
const readline = require("readline");

const HOST = "127.0.0.1";
const FIRST_PORT = parseInt(process.env.OS3D_AGENT_PORT || "8787", 10);
const PORTS = Array.from({ length: process.env.OS3D_AGENT_PORT ? 1 : 10 }, (_, i) => FIRST_PORT + i);
const CODE = (process.env.OS3D_PAIRING_CODE || "").trim();
const TOOLS = JSON.parse(fs.readFileSync(path.join(__dirname, "tools.json"), "utf8")).tools;

const NOT_RUNNING =
  "OpenShape 3D is not reachable. Ask the person to open OpenShape 3D on this Mac, go to Settings ▸ AI Assistant, " +
  "switch on “Let AI assistants build here”, and open or create a design. Then try again.";
const NOT_PAIRED =
  "OpenShape 3D refused the pairing code. Ask the person to copy the code from OpenShape 3D ▸ Settings ▸ AI Assistant " +
  "and paste it into this extension's settings in Claude (Settings ▸ Extensions ▸ OpenShape 3D).";

let port = null;

function request(method, port, urlPath, body) {
  return new Promise((resolve, reject) => {
    const data = body === undefined ? null : Buffer.from(JSON.stringify(body));
    const headers = { Accept: "application/json, text/event-stream" };
    if (CODE) headers.Authorization = "Bearer " + CODE;
    if (data) { headers["Content-Type"] = "application/json"; headers["Content-Length"] = data.length; }
    const req = http.request({ host: HOST, port, path: urlPath, method, headers, timeout: 330000 }, (res) => {
      const chunks = [];
      res.on("data", (c) => chunks.push(c));
      res.on("end", () => resolve({ status: res.statusCode, text: Buffer.concat(chunks).toString("utf8") }));
    });
    req.on("timeout", () => req.destroy(new Error("timeout")));
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

// The first port in the range where OpenShape 3D itself answers. 8787 is a
// popular number; a stranger there must not look like a broken app.
async function findApp() {
  if (port !== null) return port;
  for (const candidate of PORTS) {
    try {
      const reply = await request("GET", candidate, "/v1/health");
      if (JSON.parse(reply.text).app === "openshape3d") { port = candidate; return port; }
    } catch (_) { /* refused, not JSON, someone else */ }
  }
  return null;
}

function toolError(id, text) {
  return { jsonrpc: "2.0", id, result: { content: [{ type: "text", text }], isError: true } };
}

async function handle(message) {
  const isRequest = message.id !== undefined && message.id !== null;
  const found = await findApp();
  if (found !== null) {
    try {
      const reply = await request("POST", found, "/mcp", message);
      if (reply.status === 401) return isRequest ? answerOffline(message, NOT_PAIRED) : null;
      if (reply.status === 202 || !reply.text) return null;
      return JSON.parse(reply.text);
    } catch (_) {
      port = null;                       // the app quit, or moved ports
    }
  }
  return isRequest ? answerOffline(message, NOT_RUNNING) : null;
}

function answerOffline(message, why) {
  switch (message.method) {
    case "initialize":
      return { jsonrpc: "2.0", id: message.id, result: {
        protocolVersion: (message.params && message.params.protocolVersion) || "2025-06-18",
        capabilities: { tools: {} },
        serverInfo: { name: "openshape3d", title: "OpenShape 3D", version: "1.0.0" },
        instructions: "Call os3d_health first, then os3d_guide before modelling." } };
    case "ping":
      return { jsonrpc: "2.0", id: message.id, result: {} };
    case "tools/list":
      return { jsonrpc: "2.0", id: message.id, result: { tools: TOOLS } };
    case "tools/call":
      return toolError(message.id, why);
    default:
      return { jsonrpc: "2.0", id: message.id, error: { code: -32601, message: "Method not found: " + message.method } };
  }
}

// One message at a time, in order: the app answers one request per connection
// and a model's tool calls are sequential anyway.
let chain = Promise.resolve();
readline.createInterface({ input: process.stdin }).on("line", (line) => {
  line = line.trim();
  if (!line) return;
  let message;
  try { message = JSON.parse(line); } catch (_) { return; }
  chain = chain.then(() => handle(message)).then((reply) => {
    if (reply) process.stdout.write(JSON.stringify(reply) + "\n");
  }).catch((error) => {
    if (message.id !== undefined && message.id !== null) {
      process.stdout.write(JSON.stringify(toolError(message.id, "OpenShape 3D extension error: " + error.message)) + "\n");
    }
  });
}).on("close", () => chain.then(() => process.exit(0)));
