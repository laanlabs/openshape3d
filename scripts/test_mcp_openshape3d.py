#!/usr/bin/env python3
"""Tests for scripts/mcp_openshape3d.py — the AI-facing tool surface.

    python3 scripts/test_mcp_openshape3d.py            # offline: fake bridge
    python3 scripts/test_mcp_openshape3d.py --live     # + a real app on OS3D_AGENT_PORT

Offline, the server is run as a real subprocess speaking JSON-RPC over stdio
against a stub HTTP bridge, so what is tested is what an MCP client sees:
the handshake, the tool list, argument validation, how bridge errors and
failed features surface (`isError`), port discovery past a stranger on the
first port, the export file, and the call log.

`--live` then models the tutorial flowerpot through the same tools on a
running app and holds the result to the analytic volume (Pappus) and a
watertight, upright STL. It needs an EMPTY open design (launch with
OS3D_FRESH=1).
"""
import collections, json, math, os, shlex, struct, subprocess, sys, tempfile, threading, unittest
from http.server import BaseHTTPRequestHandler, HTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER = os.path.join(HERE, "mcp_openshape3d.py")
LIVE = "--live" in sys.argv


class Client:
    """A minimal MCP client: newline-delimited JSON-RPC over the server's stdio."""

    def __init__(self, env, command=None):
        self.p = subprocess.Popen(command or [sys.executable, SERVER], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  env=dict(os.environ, **env), text=True)
        self.n = 0

    def rpc(self, method, params=None):
        self.n += 1
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": self.n, "method": method, "params": params or {}}) + "\n")
        self.p.stdin.flush()
        reply = json.loads(self.p.stdout.readline())
        assert reply["id"] == self.n
        return reply

    def tool(self, name, arguments=None):
        result = self.rpc("tools/call", {"name": name, "arguments": arguments or {}})["result"]
        text = "".join(c.get("text", "") for c in result["content"])
        try:
            return result, json.loads(text)
        except ValueError:
            return result, text

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=5)
        self.p.stdout.close()


def stl_report(path, tol=1e-4):
    with open(path, "rb") as handle:
        data = handle.read()
    n = struct.unpack("<I", data[80:84])[0]
    assert len(data) == 84 + 50 * n, "not a binary STL"
    edges, lo, hi, volume = collections.Counter(), [1e18] * 3, [-1e18] * 3, 0.0
    for i in range(n):
        f = struct.unpack("<12f", data[84 + 50 * i: 132 + 50 * i])
        a, b, c = f[3:6], f[6:9], f[9:12]
        for p in (a, b, c):
            for k in range(3):
                lo[k], hi[k] = min(lo[k], p[k]), max(hi[k], p[k])
        volume += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
                   + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
        keys = [tuple(round(x / tol) for x in p) for p in (a, b, c)]
        for j in range(3):
            e = (keys[j], keys[(j + 1) % 3])
            edges[(min(e), max(e))] += 1
    return {"triangles": n, "min": lo, "max": hi, "volume": volume,
            "watertight": all(count == 2 for count in edges.values())}


# ---- offline: a stub bridge ------------------------------------------------------

class Stub(BaseHTTPRequestHandler):
    app = "openshape3d"
    seen = []

    def log_message(self, *a): pass

    def send(self, status, body, content_type="application/json"):
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        Stub.seen.append(("GET", self.path))
        if self.path == "/v1/health":
            return self.send(200, {"ok": True, "app": self.server.app_name, "hasDocument": True})
        if self.path.startswith("/v1/export"):
            if "format=gcode" in self.path:
                return self.send(400, {"ok": False, "error": "unknown_format", "message": "stl, obj, 3mf, step"})
            return self.send(200, b"\0" * 80 + struct.pack("<I", 2) + b"\0" * 100, "model/stl")
        if self.path.startswith("/v1/faces"):
            return self.send(200, {"ok": True, "faces": [{"index": 1, "kind": "planar"}]})
        if self.path.startswith("/v1/edges?body=missing"):
            return self.send(404, {"ok": False, "error": "unknown_body", "message": "no such body"})
        return self.send(200, {"ok": True, "path": self.path})

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        Stub.seen.append(("POST", self.path, body))
        if body.get("op") == "feature.bogus":
            return self.send(400, {"ok": False, "error": "unknown_op", "message": "No op feature.bogus"})
        if body.get("op") == "feature.fillet":
            return self.send(200, {"ok": True, "failed": True, "message": "radius too large"})
        return self.send(200, {"ok": True, "echo": body, "producedBodyIDs": ["B1"]})


def serve(app_name):
    server = HTTPServer(("127.0.0.1", 0), Stub)
    server.app_name = app_name
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


class OfflineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.stranger, cls.bridge = serve("something-else"), serve("openshape3d")
        cls.log = tempfile.NamedTemporaryFile(suffix=".jsonl", delete=False).name
        # The stranger's port comes first: discovery has to walk past it.
        cls.c = Client({"OS3D_AGENT_PORT": "{},{}".format(cls.stranger.server_port, cls.bridge.server_port),
                        "OS3D_MCP_LOG": cls.log})

    @classmethod
    def tearDownClass(cls):
        cls.c.close()
        for server in (cls.stranger, cls.bridge):
            server.shutdown(); server.server_close()
        os.remove(cls.log)

    def test_handshake_carries_the_modelling_guide(self):
        result = self.c.rpc("initialize", {"protocolVersion": "2025-06-18"})["result"]
        self.assertEqual(result["serverInfo"]["name"], "openshape3d")
        self.assertIn("Y is up", result["instructions"])
        self.assertNotIn("name: model-openshape3d", result["instructions"], "frontmatter must be stripped")

    def test_lists_the_modelling_tools(self):
        tools = self.c.rpc("tools/list")["result"]["tools"]
        names = {t["name"] for t in tools}
        # Claude Desktop approves tools BY NAME on first use (2.110 only groups
        # annotated read-only tools in Settings): one listed tool, one prompt.
        self.assertEqual(names, {"os3d"})

    def test_the_one_tool_routes_reads_and_changes(self):
        result, body = self.c.tool("os3d", {"op": "health"})
        self.assertEqual(body["app"], "openshape3d")
        result, body = self.c.tool("os3d", {"op": "faces", "args": {"body": "ABC"}})
        self.assertEqual(body["faces"][0]["index"], 1)
        result, text = self.c.tool("os3d", {"op": "guide"})
        self.assertIn("Y is up", text)
        result, body = self.c.tool("os3d", {"op": "feature.extrude", "args": {"distance": 5}})
        self.assertEqual(body["echo"], {"op": "feature.extrude", "args": {"distance": 5}})
        result, text = self.c.tool("os3d", {})
        self.assertTrue(result["isError"])

    def test_views_undo_and_export_ride_on_exec(self):
        result, body = self.c.tool("os3d", {"op": "command.run", "args": {"id": "view.fit"}})
        self.assertFalse(result.get("isError"), body)
        self.assertIn(("POST", "/v1/command", {"id": "view.fit"}), Stub.seen)
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "pot.stl")
            result, body = self.c.tool("os3d_exec", {"op": "document.export",
                                                     "args": {"format": "stl", "up": "z", "body": ["B1"], "path": path}})
            self.assertFalse(result.get("isError"), body)
            self.assertEqual(body["triangles"], 2)
        result, text = self.c.tool("os3d_exec", {"op": "command.run", "args": {}})
        self.assertTrue(result["isError"])
        self.assertIn("id", text)

    def test_every_tool_has_an_object_schema_and_a_description(self):
        for tool in self.c.rpc("tools/list")["result"]["tools"]:
            self.assertEqual(tool["inputSchema"]["type"], "object", tool["name"])
            self.assertGreater(len(tool["description"]), 40, tool["name"])

    def test_health_skips_a_stranger_on_the_first_port(self):
        result, body = self.c.tool("os3d_health")
        self.assertFalse(result.get("isError"))
        self.assertEqual(body["app"], "openshape3d")

    def test_exec_posts_op_and_args(self):
        result, body = self.c.tool("os3d_exec", {"op": "feature.extrude", "args": {"distance": 5}})
        self.assertFalse(result.get("isError"))
        self.assertEqual(body["echo"], {"op": "feature.extrude", "args": {"distance": 5}})

    def test_exec_without_op_is_refused_before_the_bridge(self):
        result, text = self.c.tool("os3d_exec", {"args": {}})
        self.assertTrue(result["isError"])
        self.assertIn("op", text)

    def test_bridge_refusal_reaches_the_model_intact(self):
        result, body = self.c.tool("os3d_exec", {"op": "feature.bogus"})
        self.assertTrue(result["isError"])
        self.assertEqual(body["error"], "unknown_op")

    def test_a_feature_that_did_not_build_is_an_error(self):
        result, body = self.c.tool("os3d_exec", {"op": "feature.fillet", "args": {}})
        self.assertTrue(result["isError"], "HTTP 200 with failed:true must not read as success")
        self.assertEqual(body["message"], "radius too large")

    def test_faces_needs_a_body_and_passes_it_on(self):
        result, _ = self.c.tool("os3d_faces")
        self.assertTrue(result["isError"])
        result, body = self.c.tool("os3d_faces", {"body": "ABC"})
        self.assertEqual(body["faces"][0]["index"], 1)
        self.assertIn(("GET", "/v1/faces?body=ABC"), Stub.seen)

    def test_edges_404_is_an_error_with_its_code(self):
        result, body = self.c.tool("os3d_edges", {"body": "missing"})
        self.assertTrue(result["isError"])
        self.assertEqual(body["error"], "unknown_body")

    def test_export_writes_the_file_and_reports_triangles(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "out", "pot.stl")
            result, body = self.c.tool("os3d_export", {"format": "stl", "up": "z", "body": ["B1", "B2"], "path": path})
            self.assertFalse(result.get("isError"))
            self.assertEqual((os.path.realpath(body["path"]), body["triangles"], body["up"]), (os.path.realpath(path), 2, "z"))
            self.assertEqual(os.path.getsize(path), 184)
        self.assertIn(("GET", "/v1/export?format=stl&up=z&body=B1%2CB2"), Stub.seen)

    def test_export_refusal_writes_no_file(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "x.gcode")
            result, body = self.c.tool("os3d_export", {"format": "gcode", "path": path})
            self.assertTrue(result["isError"])
            self.assertEqual(body["error"], "unknown_format")
            self.assertFalse(os.path.exists(path))

    def test_unknown_tool_and_unknown_method(self):
        result, _ = self.c.tool("os3d_nope")
        self.assertTrue(result["isError"])
        self.assertEqual(self.c.rpc("resources/list")["error"]["code"], -32601)

    def test_zz_calls_are_logged(self):
        self.c.tool("os3d_state")
        with open(self.log) as handle:
            entries = [json.loads(line) for line in handle]
        self.assertEqual(entries[-1]["name"], "os3d_state")
        self.assertIn("seconds", entries[-1])


class UnreachableTests(unittest.TestCase):
    def test_no_app_is_a_readable_tool_error_not_a_crash(self):
        c = Client({"OS3D_AGENT_PORT": "1"})
        try:
            result, text = c.tool("os3d_state")
            self.assertTrue(result["isError"])
            self.assertIn("OS3D_AGENT=1", text)
            self.assertEqual(c.rpc("ping")["result"], {})
        finally:
            c.close()


# ---- live: the tutorial flowerpot -------------------------------------------------

POT = [(6, 0), (40, 0), (55, 100), (52, 100), (37.6, 4), (6, 4)]   # (radius, height) mm


def pappus(points):
    area = cx = 0.0
    for (x0, y0), (x1, y1) in zip(points, points[1:] + points[:1]):
        cross = x0 * y1 - x1 * y0
        area += cross
        cx += (x0 + x1) * cross
    area /= 2
    return 2 * math.pi * (cx / (6 * area)) * abs(area)


@unittest.skipUnless(LIVE, "needs a running app: pass --live")
class LiveFlowerpot(unittest.TestCase):
    def test_flowerpot_through_the_tools(self):
        # OS3D_TEST_SERVER_CMD swaps in another stdio server for the same test —
        # e.g. the Claude Desktop extension's relay to the app's own /mcp:
        #   OS3D_TEST_SERVER_CMD="node integrations/claude-desktop/server/index.js" OS3D_PAIRING_CODE=… … --live
        c = Client({}, shlex.split(os.environ["OS3D_TEST_SERVER_CMD"]) if os.environ.get("OS3D_TEST_SERVER_CMD") else None)
        try:
            _, health = c.tool("os3d_health")
            self.assertTrue(health.get("hasDocument"), health)
            _, state = c.tool("os3d_state")
            self.assertEqual(state["bodies"], [], "run --live against an empty design (OS3D_FRESH=1)")

            _, sketch = c.tool("os3d_exec", {"op": "sketch.create", "args": {
                "name": "Pot profile", "origin": [0, 0, 0], "xAxis": [1, 0, 0], "yAxis": [0, 1, 0]}})
            lines = [{"kind": "line", "a": list(a), "b": list(b)} for a, b in zip(POT, POT[1:] + POT[:1])]
            c.tool("os3d_exec", {"op": "sketch.addEntities", "args": {"sketchID": sketch["sketchID"], "entities": lines}})
            result, pot = c.tool("os3d_exec", {"op": "feature.revolve", "args": {
                "sketchID": sketch["sketchID"], "seedPoint": [20, 2], "axisPoint": [0, 0], "axisDirection": [0, 1]}})
            self.assertFalse(result.get("isError"), pot)
            body = pot["producedBodyIDs"][0]
            volume = next(b for b in pot["bodies"] if b["id"] == body)["volumeMM3"]
            self.assertAlmostEqual(volume, pappus(POT), delta=1e-3)

            result, failed = c.tool("os3d_exec", {"op": "feature.fillet", "args": {"bodyID": body, "radius": 500, "edges": [1]}})
            self.assertTrue(result["isError"], "an impossible fillet must surface as an error")
            c.tool("os3d_exec", {"op": "command.run", "args": {"id": "edit.undo"}})

            _, check = c.tool("os3d_check", {"body": body})
            self.assertEqual(check["invalid"], 0, check)
            with tempfile.TemporaryDirectory() as d:
                _, export = c.tool("os3d_exec", {"op": "document.export", "args": {
                    "format": "stl", "up": "z", "body": [body], "path": os.path.join(d, "pot.stl")}})
                report = stl_report(export["path"])
            self.assertTrue(report["watertight"], report)
            self.assertAlmostEqual(report["min"][2], 0, places=3)       # stands on the bed
            self.assertAlmostEqual(report["max"][2], 100, places=3)     # Z is up
            self.assertAlmostEqual(report["volume"], volume, delta=volume * 0.005)
        finally:
            c.close()


if __name__ == "__main__":
    unittest.main(argv=[a for a in sys.argv if a != "--live"], verbosity=2)
