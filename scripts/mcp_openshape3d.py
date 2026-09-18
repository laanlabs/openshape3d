#!/usr/bin/env python3
"""MCP server exposing the openshape3d DEBUG agent bridge to any MCP client —
Claude Desktop, Claude Code, ChatGPT/Codex (docs/AI_MODELING_SETUP.md).

`AgentServer.swift` named this file from the day it was written; this is it.

WHY THIS EXISTS AT ALL: Claude Code needs nothing here — it has a shell, so
`curl` is a complete client and `.claude/skills/drive-openshape3d/` is the whole
integration. Claude Desktop has no shell, so it needs a real MCP server. That is
the only difference between the two clients.

WHY IT IS STDLIB-ONLY: it runs inside Claude Desktop's launch environment, not
yours — no venv, no PATH you control, no chance to `pip install` when something
is missing. A dependency here is a support burden paid in "it just says failed"
reports. Hand-rolling JSON-RPC over stdio costs ~120 lines and removes that
whole class of problem. Targets Python 3.9 (the system interpreter on macOS):
no `match`, no PEP-604 unions.

This server holds NO logic of its own. Every tool is a thin call to the same
HTTP endpoints the skill documents, so the two clients cannot drift apart.
The modelling know-how (op reference, coordinate conventions, the verify
loop) lives in ONE place — `.claude/skills/model-openshape3d/SKILL.md` — and
is served from there: as the MCP `instructions` and by the `os3d_guide` tool,
for clients that have no skill mechanism of their own.

Register it in ~/Library/Application Support/Claude/claude_desktop_config.json:

    {"mcpServers": {"openshape3d": {
        "command": "python3",
        "args": ["/absolute/path/to/scripts/mcp_openshape3d.py"]}}}

Then launch the app with OS3D_AGENT=1 — see docs/AGENT_CONTROL.md.

OS3D_AGENT_PORT may list several ports ("8787,8899"): the first one where
openshape3d itself answers /v1/health wins. 8787 is a popular port, and a
stranger answering there otherwise looks exactly like a broken bridge.
"""

import base64
import json
import os
import struct
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HOST = os.environ.get("OS3D_AGENT_HOST", "127.0.0.1")
PORTS = [p.strip() for p in os.environ.get("OS3D_AGENT_PORT", "8787,8899").split(",") if p.strip()]
TIMEOUT = 30
EXEC_TIMEOUT = 300          # a boolean or a shell on a dense body can take minutes
SCREENSHOT_BUDGET = 700_000  # bytes of image; ×4/3 as base64 stays under the 1 MB tool-result cap
HERE = os.path.dirname(os.path.abspath(__file__))
GUIDE_PATH = os.path.join(os.path.dirname(HERE), ".claude", "skills", "model-openshape3d", "SKILL.md")
# One JSON line per tool call (name, arguments, status, seconds) — how a
# session is audited, and how the tutorial videos replay a real one.
CALL_LOG = os.environ.get("OS3D_MCP_LOG")

_base = None


def base_url():
    """The first configured port where openshape3d itself answers."""
    global _base
    if _base:
        return _base
    seen = []
    for port in PORTS:
        url = "http://{}:{}".format(HOST, port)
        try:
            with urllib.request.urlopen(url + "/v1/health", timeout=2) as response:
                if json.loads(response.read().decode("utf-8")).get("app") == "openshape3d":
                    _base = url
                    return url
                seen.append("{} (something else answers there)".format(port))
        except Exception:  # noqa: BLE001 — refused, timed out, or not JSON
            seen.append("{} (no answer)".format(port))
    raise RuntimeError(
        "Cannot reach openshape3d on port {}. The app has to be running a DEBUG build "
        "launched with OS3D_AGENT=1 (and OS3D_AGENT_PORT when 8787 is taken). "
        "See docs/AI_MODELING_SETUP.md.".format(", ".join(seen)))

PROTOCOL_VERSION = "2025-06-18"
SERVER_INFO = {"name": "openshape3d", "version": "1.2.0"}


# --------------------------------------------------------------------------
# HTTP to the app
# --------------------------------------------------------------------------

def call_app(method, path, payload=None, timeout=TIMEOUT):
    """Return (status, body_bytes, content_type). Never raises for HTTP errors —
    the bridge's 4xx bodies carry the actionable message, so they must reach the
    model intact rather than being flattened into a transport failure."""
    status, body, headers = call_app_headers(method, path, payload, timeout)
    return status, body, headers.get("Content-Type", "")


def call_app_headers(method, path, payload=None, timeout=TIMEOUT):
    """As call_app, with every response header: an export's overall size
    travels as `X-OS3D-Size-MM`, the one fact the bytes cannot state."""
    global _base
    url = base_url() + path
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(url, data=data, method=method)
    if data is not None:
        request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status, response.read(), response.headers
    except urllib.error.HTTPError as error:
        return error.code, error.read(), error.headers
    except urllib.error.URLError as error:
        _base = None            # the app may come back on another port
        raise RuntimeError(
            "Lost openshape3d at {}: {}. Relaunch the DEBUG build with OS3D_AGENT=1. "
            "See docs/AI_MODELING_SETUP.md.".format(url, error.reason)
        )


def guide_text():
    """The modelling skill, minus its frontmatter."""
    try:
        with open(GUIDE_PATH, encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        return ("The modelling guide is missing ({}). Protocol reference: "
                "docs/AGENT_CONTROL.md.".format(GUIDE_PATH))
    if text.startswith("---"):
        text = text.split("---", 2)[2]
    return text.strip()


def text_result(body):
    return {"content": [{"type": "text", "text": body}]}


def error_result(message):
    return {"content": [{"type": "text", "text": message}], "isError": True}


# --------------------------------------------------------------------------
# Tools
# --------------------------------------------------------------------------

TOOLS_PATH = os.path.join(os.path.dirname(HERE), "openshape3d", "Agent", "MCPTools.json")


def load_tools():
    """The app's own catalog (`MCPTools.json`): ONE tool, `os3d`, whose `op`
    covers reads and changes alike, so Claude Desktop asks for permission once."""
    with open(TOOLS_PATH, encoding="utf-8") as handle:
        return json.load(handle)["tools"]


TOOLS = load_tools()


# `os3d` read ops → the (unlisted) per-endpoint handlers below. ONE listed tool,
# because Claude Desktop asks the person to approve each tool by name on first
# use (a read-only annotation only groups a tool in its Settings, it does not
# skip the prompt — checked on 2.110), so reads and changes share one approval.
READ_OPS = {"health": "os3d_health", "guide": "os3d_guide", "state": "os3d_state", "faces": "os3d_faces",
            "edges": "os3d_edges", "sketches": "os3d_sketches", "check": "os3d_check",
            "screenshot": "os3d_screenshot", "commands": "os3d_list_commands"}


def run_tool(name, arguments):
    if name == "os3d":
        op = (arguments or {}).get("op")
        if not op:
            return error_result("os3d needs an 'op' — health, state, faces, edges, check, screenshot, "
                                "or a change such as feature.extrude. The guide (op guide) lists them all.")
        if op in READ_OPS:
            return run_tool(READ_OPS[op], (arguments or {}).get("args") or {})
        return run_tool("os3d_exec", arguments)

    if name == "os3d_health":
        status, body, _ = call_app("GET", "/v1/health")
        return text_result(body.decode("utf-8"))

    if name == "os3d_list_commands":
        status, body, _ = call_app("GET", "/v1/commands")
        return text_result(body.decode("utf-8"))

    if name == "os3d_state":
        status, body, _ = call_app("GET", "/v1/state")
        return text_result(body.decode("utf-8"))

    if name == "os3d_run_command":
        command_id = (arguments or {}).get("id")
        if not command_id:
            return error_result("os3d_run_command needs an 'id'. Call os3d_list_commands for the list.")
        status, body, _ = call_app("POST", "/v1/command", {"id": command_id})
        text = body.decode("utf-8")
        # A 4xx here is a usable answer (unknown id / no entry point / no
        # document), so pass the body through and only flag it as an error.
        return error_result(text) if status >= 400 else text_result(text)

    if name == "os3d_screenshot":
        arguments = arguments or {}
        width = int(arguments.get("width", 1024))
        height = int(arguments.get("height", 1024))
        # JPEG under a byte budget: a 1024² PNG of a model is ~1.4 MB as
        # base64, and Claude Desktop drops tool results over 1 MB.
        status, body, content_type = call_app(
            "GET", "/v1/screenshot?w={}&h={}&format={}&maxBytes={}".format(
                width, height, arguments.get("format", "jpeg"), SCREENSHOT_BUDGET))
        if status >= 400 or not content_type.startswith("image/"):
            return error_result(body.decode("utf-8", "replace"))
        return {"content": [{
            "type": "image",
            "data": base64.b64encode(body).decode("ascii"),
            "mimeType": content_type.split(";")[0].strip(),
        }]}

    if name == "os3d_guide":
        return text_result(guide_text())

    if name == "os3d_exec":
        arguments = arguments or {}
        if not arguments.get("op"):
            return error_result("os3d_exec needs an 'op'. os3d_guide lists the operations.")
        # Views, undo and export are exec ops too, so the one listed tool
        # (`os3d`, which forwards here) covers them with a single approval.
        if arguments["op"] == "command.run":
            return run_tool("os3d_run_command", arguments.get("args") or {})
        if arguments["op"] == "document.export":
            return run_tool("os3d_export", arguments.get("args") or {})
        status, body, _ = call_app(
            "POST", "/v1/exec", {"op": arguments["op"], "args": arguments.get("args") or {}},
            timeout=EXEC_TIMEOUT)
        text = body.decode("utf-8")
        failed = status >= 400
        try:
            failed = failed or bool(json.loads(text).get("failed"))
        except ValueError:
            pass
        return error_result(text) if failed else text_result(text)

    if name in ("os3d_faces", "os3d_edges"):
        body_id = (arguments or {}).get("body")
        if not body_id:
            return error_result("{} needs 'body' — a body id from os3d_state.".format(name))
        status, body, _ = call_app("GET", "/v1/{}?body={}".format(
            name[len("os3d_"):], urllib.parse.quote(body_id)))
        text = body.decode("utf-8")
        return error_result(text) if status >= 400 else text_result(text)

    if name == "os3d_sketches":
        status, body, _ = call_app("GET", "/v1/sketches")
        text = body.decode("utf-8")
        return error_result(text) if status >= 400 else text_result(text)

    if name == "os3d_check":
        arguments = arguments or {}
        query = []
        if arguments.get("body"):
            query.append("body=" + urllib.parse.quote(arguments["body"]))
        if arguments.get("bop"):
            query.append("bop=1")
        status, body, _ = call_app("GET", "/v1/check" + ("?" + "&".join(query) if query else ""),
                                   timeout=EXEC_TIMEOUT)
        text = body.decode("utf-8")
        return error_result(text) if status >= 400 else text_result(text)

    if name == "os3d_export":
        return export(arguments or {})

    return error_result("Unknown tool: {}".format(name))


def export(arguments):
    fmt = str(arguments.get("format") or "stl").lower()
    query = ["format=" + urllib.parse.quote(fmt), "up=" + urllib.parse.quote(str(arguments.get("up") or "y"))]
    bodies = arguments.get("body") or []
    if isinstance(bodies, str):
        bodies = [bodies]
    if bodies:
        query.append("body=" + urllib.parse.quote(",".join(bodies)))
    status, data, headers = call_app_headers("GET", "/v1/export?" + "&".join(query), timeout=EXEC_TIMEOUT)
    content_type = headers.get("Content-Type", "")
    if status >= 400 or "json" in content_type:
        return error_result(data.decode("utf-8", "replace"))
    # `name` is what the in-app server takes (a file in Downloads); `path` is
    # the developer's override. Same catalog, so both must work here.
    name = os.path.basename(str(arguments.get("name") or "").strip())
    if name.lower().endswith("." + fmt):
        name = name[:-(len(fmt) + 1)]
    name = "".join(ch for ch in name if ch.isalnum() or ch in " -_().").strip() or \
        "openshape3d-{}".format(time.strftime("%Y%m%d-%H%M%S"))
    path = arguments.get("path") or os.path.join("~", "Downloads", "{}.{}".format(name, fmt))
    path = os.path.abspath(os.path.expanduser(path))
    if os.path.isdir(path):
        return error_result("'{}' is a folder — give a file path.".format(path))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(data)
    report = {"ok": True, "path": path, "fileName": os.path.basename(path), "bytes": len(data),
              "format": fmt, "up": arguments.get("up") or "y", "units": "mm"}
    if headers.get("X-OS3D-Size-MM"):
        report["sizeMM"] = headers["X-OS3D-Size-MM"]     # width x depth x height as written
    if headers.get("X-OS3D-Bodies"):
        report["bodies"] = int(headers["X-OS3D-Bodies"])
    if fmt == "stl" and len(data) >= 84:
        # Binary STL: 80-byte header, then a uint32 triangle count.
        report["triangles"] = struct.unpack("<I", data[80:84])[0]
    return text_result(json.dumps(report))


# --------------------------------------------------------------------------
# JSON-RPC over stdio
# --------------------------------------------------------------------------

def handle(message):
    """Return a response dict, or None for a notification."""
    method = message.get("method")
    message_id = message.get("id")

    # Notifications (no id) get no reply — answering one is a protocol error.
    if message_id is None:
        return None

    if method == "initialize":
        requested = (message.get("params") or {}).get("protocolVersion")
        return ok(message_id, {
            "protocolVersion": requested or PROTOCOL_VERSION,
            "capabilities": {"tools": {}},
            "serverInfo": SERVER_INFO,
            "instructions": guide_text(),
        })

    if method == "ping":
        return ok(message_id, {})

    if method == "tools/list":
        return ok(message_id, {"tools": TOOLS})

    if method == "tools/call":
        params = message.get("params") or {}
        started = time.time()
        try:
            result = run_tool(params.get("name"), params.get("arguments"))
            log_call(params, result, started)
            return ok(message_id, result)
        except RuntimeError as error:
            # The app being down is the single most common failure and is
            # recoverable by the user, so report it as tool output rather than
            # as a transport error the model cannot see the text of.
            return ok(message_id, error_result(str(error)))
        except Exception as error:  # noqa: BLE001 — never take the server down
            return ok(message_id, error_result("openshape3d MCP server error: {!r}".format(error)))

    return {"jsonrpc": "2.0", "id": message_id,
            "error": {"code": -32601, "message": "Method not found: {}".format(method)}}


def log_call(params, result, started):
    if not CALL_LOG:
        return
    texts = [c.get("text", "") for c in result.get("content", []) if c.get("type") == "text"]
    entry = {"t": started, "seconds": round(time.time() - started, 3),
             "name": params.get("name"), "arguments": params.get("arguments") or {},
             "isError": bool(result.get("isError")), "text": "".join(texts)[:20000]}
    try:
        with open(CALL_LOG, "a", encoding="utf-8") as handle:
            handle.write(json.dumps(entry) + "\n")
    except OSError:
        pass


def ok(message_id, result):
    return {"jsonrpc": "2.0", "id": message_id, "result": result}


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue
        response = handle(message)
        if response is not None:
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
