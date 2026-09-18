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
SERVER_INFO = {"name": "openshape3d", "version": "1.1.0"}


# --------------------------------------------------------------------------
# HTTP to the app
# --------------------------------------------------------------------------

def call_app(method, path, payload=None, timeout=TIMEOUT):
    """Return (status, body_bytes, content_type). Never raises for HTTP errors —
    the bridge's 4xx bodies carry the actionable message, so they must reach the
    model intact rather than being flattened into a transport failure."""
    global _base
    url = base_url() + path
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(url, data=data, method=method)
    if data is not None:
        request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status, response.read(), response.headers.get("Content-Type", "")
    except urllib.error.HTTPError as error:
        return error.code, error.read(), error.headers.get("Content-Type", "")
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

TOOLS = [
    {
        "name": "os3d_health",
        "description": (
            "Check whether openshape3d is running and reachable. Returns the platform "
            "(simulator/maccatalyst/device), the bound port, and whether a document is "
            "open. Call this first — everything else fails without it."
        ),
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "os3d_list_commands",
        "description": (
            "List every command that can actually be run. Call before os3d_run_command "
            "rather than guessing an id — the app's full catalog is wider than this, and "
            "the extra entries have no entry point yet."
        ),
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "os3d_state",
        "description": (
            "Read the editor: current mode, selection, every body with its volume in mm3 "
            "and whether it is still analytic (brep), undo/redo availability, and the "
            "measurement rows shown in the app's info bar. Verify geometry with this, not "
            "with a screenshot — an image cannot show that a boolean produced a 0 mm3 body."
        ),
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "os3d_run_command",
        "description": (
            "Run a named command, e.g. 'view.isometric', 'edit.undo', 'model.extrude'. "
            "Note that tool commands ARM a tool (they put the editor in that mode); they do "
            "not parameterize or commit it. A result of ran=false means the command is real "
            "but does not apply in the current mode — read the message rather than retrying."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {"id": {"type": "string", "description": "Command id from os3d_list_commands."}},
            "required": ["id"],
        },
    },
    {
        "name": "os3d_screenshot",
        "description": (
            "Capture the 3D viewport as a PNG, rendered by the app itself. After any view.* "
            "command, wait about a second before calling this: standard views animate, and an "
            "immediate capture catches the camera mid-flight."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "width": {"type": "integer", "description": "Pixels, 64-4096. Default 1024."},
                "height": {"type": "integer", "description": "Pixels, 64-4096. Default 1024."},
            },
        },
    },
    {
        "name": "os3d_guide",
        "description": (
            "The modelling guide: coordinate conventions (millimetres, Y is up), every "
            "os3d_exec op with its arguments, worked recipes, and the verify-then-export "
            "loop. Read it once before the first os3d_exec of a session."
        ),
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "os3d_exec",
        "description": (
            "Build or change geometry: one parameterized operation per call, recorded as an "
            "undoable feature exactly as if it had been modelled by hand. op is e.g. "
            "'sketch.create', 'sketch.addEntities', 'feature.extrude', 'feature.revolve', "
            "'feature.shell', 'feature.fillet', 'feature.boolean', 'body.setMaterial'; args "
            "is that op's argument object (os3d_guide lists them all). Units are millimetres "
            "and degrees. The reply carries the new state plus producedBodyIDs / "
            "changedBodyIDs / removedBodyIDs; 'failed': true means the feature was recorded "
            "but did not build — read 'message', run edit.undo, and correct the arguments."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "op": {"type": "string", "description": "Operation name, e.g. feature.extrude."},
                "args": {"type": "object", "description": "The operation's arguments."},
            },
            "required": ["op"],
        },
    },
    {
        "name": "os3d_faces",
        "description": (
            "List a body's faces straight from the kernel: 1-based index, kind (planar / "
            "cylindrical + radius / other), area, centroid, normal. These indices are what "
            "feature.shell 'openFaces', feature.pushPull 'face' and the other face ops take. "
            "Re-list after every feature: indices are per-shape, not stable across edits."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {"body": {"type": "string", "description": "Body id from os3d_state."}},
            "required": ["body"],
        },
    },
    {
        "name": "os3d_edges",
        "description": (
            "List a body's edges: 1-based index, the two adjacent faces, midpoint, length, "
            "convexity. These indices are what feature.fillet / feature.chamfer 'edges' take. "
            "Re-list after every feature."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {"body": {"type": "string", "description": "Body id from os3d_state."}},
            "required": ["body"],
        },
    },
    {
        "name": "os3d_sketches",
        "description": "List every sketch with its plane and its entities in sketch (u, v) millimetres.",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "os3d_check",
        "description": (
            "Geometry health report (valid solid? open shells? self-intersections with "
            "bop=true). Run it before exporting anything that will be manufactured."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "body": {"type": "string", "description": "Body id; omit to check every body."},
                "bop": {"type": "boolean", "description": "Add the slow self-intersection pass."},
            },
        },
    },
    {
        "name": "os3d_export",
        "description": (
            "Write the design to a file for printing or another CAD tool and return its path. "
            "format: stl (default), 3mf, obj (meshes) or step (exact B-rep). The app's world is "
            "Y-up; pass up='z' for a 3D-printing slicer so the part stands on the bed. body "
            "limits the file to the listed body ids (one printable part per file)."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "format": {"type": "string", "enum": ["stl", "3mf", "obj", "step"]},
                "up": {"type": "string", "enum": ["y", "z"], "description": "Up axis of the file. Default y; z for slicers."},
                "body": {"type": "array", "items": {"type": "string"}, "description": "Body ids; omit for the whole design."},
                "path": {"type": "string", "description": "Where to write. Default ~/Downloads/openshape3d-<time>.<format>."},
            },
        },
    },
]


def run_tool(name, arguments):
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
        status, body, content_type = call_app(
            "GET", "/v1/screenshot?w={}&h={}".format(width, height))
        if status >= 400 or "image/png" not in content_type:
            return error_result(body.decode("utf-8", "replace"))
        return {"content": [{
            "type": "image",
            "data": base64.b64encode(body).decode("ascii"),
            "mimeType": "image/png",
        }]}

    if name == "os3d_guide":
        return text_result(guide_text())

    if name == "os3d_exec":
        arguments = arguments or {}
        if not arguments.get("op"):
            return error_result("os3d_exec needs an 'op'. os3d_guide lists the operations.")
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
    status, data, content_type = call_app("GET", "/v1/export?" + "&".join(query), timeout=EXEC_TIMEOUT)
    if status >= 400 or "json" in content_type:
        return error_result(data.decode("utf-8", "replace"))
    path = arguments.get("path") or os.path.join(
        "~", "Downloads", "openshape3d-{}.{}".format(time.strftime("%Y%m%d-%H%M%S"), fmt))
    path = os.path.abspath(os.path.expanduser(path))
    if os.path.isdir(path):
        return error_result("'{}' is a folder — give a file path.".format(path))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(data)
    report = {"ok": True, "path": path, "bytes": len(data), "format": fmt,
              "up": arguments.get("up") or "y", "units": "mm"}
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
