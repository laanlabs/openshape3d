#!/usr/bin/env python3
"""Record the Glass Bottle tutorial: real touch interactions performed by
BottleTakeUITests on the landscape iPad simulator, paced by this host.

Writes <out>/raw.mp4 and <out>/timeline.json for compose.py.
"""
import json, os, re, signal, subprocess, sys, threading, time, urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = "/Users/thelodgestudio/projects/openshape3d"
os.environ.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")
UDID = "AC2FD923-1661-435F-BF47-3E9DF30D1A16"
BUNDLE = "com.laan.labs.openshape3d"
CONTROL_PORT = 8897
BRIDGE_PORT = "8921"
BASE = f"http://127.0.0.1:{BRIDGE_PORT}"
W, H = 1376, 1032                       # landscape device points
DUR = json.load(open(f"{HERE}/tts/durations.json"))

def log(m): print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)

def simctl(*a, check=True):
    return subprocess.run(["xcrun", "simctl", *a], check=check, capture_output=True, text=True)

def screenshot(path=None, tag="shot"):
    path = path or f"{HERE}/shots/{tag}.png"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    simctl("io", UDID, "screenshot", path)
    im = Image.open(path).transpose(Image.ROTATE_90)   # landscapeLeft framebuffer
    im.save(path)
    return np.asarray(im.convert("RGB"), dtype=np.int16)

def bbox(mask, min_px=200, frac=0.2):
    """Bounding box of the DENSE part of a pixel mask, in device points
    (x0, y0, x1, y1), or None. Thin strays (axis lines, grid) are dropped by
    keeping only the rows/columns holding at least `frac` of the peak count."""
    ys, xs = np.nonzero(mask)
    if len(xs) < min_px:
        return None
    hx = np.bincount(xs, minlength=mask.shape[1]); hy = np.bincount(ys, minlength=mask.shape[0])
    kx = np.nonzero(hx >= frac * hx.max())[0]; ky = np.nonzero(hy >= frac * hy.max())[0]
    return (kx.min() / 2, ky.min() / 2, kx.max() / 2, ky.max() / 2)

def blob(mask, block=16, min_frac=0.6):
    """Centre (device points) and area of the LARGEST solid region of a mask:
    the mask is pooled into `block`-px cells, cells at least `min_frac` full
    are grouped into 4-connected regions, the biggest region wins. Thin lines
    never qualify; small solid things (the view cube) lose to the tile."""
    h, w = mask.shape
    cells = mask[:h // block * block, :w // block * block].reshape(h // block, block, w // block, block).mean(axis=(1, 3))
    solid = cells >= min_frac
    seen = np.zeros_like(solid); best = None
    for sy, sx in zip(*np.nonzero(solid)):
        if seen[sy, sx]: continue
        stack, members = [(sy, sx)], []
        while stack:
            cy, cx = stack.pop()
            if seen[cy, cx] or not solid[cy, cx]: continue
            seen[cy, cx] = True; members.append((cy, cx))
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < solid.shape[0] and 0 <= nx < solid.shape[1]: stack.append((ny, nx))
        if best is None or len(members) > len(best): best = members
    if not best: return None
    ys = np.array([m[0] for m in best]); xs = np.array([m[1] for m in best])
    return ((xs.mean() + 0.5) * block / 2, (ys.mean() + 0.5) * block / 2, len(best) * block * block / 4)

def norm(x, y):
    return f"{x / W:.4f},{y / H:.4f}"

# ---- control loop -------------------------------------------------------------

class Control:
    def __init__(self, port):
        self.pending, self.events, self.lock = "", [], threading.Lock()
        outer = self
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *a): pass
            def do_GET(self):
                with outer.lock:
                    body = outer.pending if self.path == "/next" else ""
                self.send_response(200); self.send_header("Content-Length", str(len(body))); self.end_headers()
                self.wfile.write(body.encode())
            def do_POST(self):
                n = int(self.headers.get("Content-Length", 0)); msg = self.rfile.read(n).decode()
                with outer.lock:
                    outer.events.append(msg)
                    if msg.startswith("done"): outer.pending = ""
                self.send_response(200); self.send_header("Content-Length", "0"); self.end_headers()
        self.server = HTTPServer(("127.0.0.1", port), Handler)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def wait_event(self, prefix, timeout):
        end = time.time() + timeout
        while time.time() < end:
            with self.lock:
                for e in self.events:
                    if e.startswith(prefix):
                        self.events.remove(e); return e
            time.sleep(0.05)
        sys.exit(f"timed out waiting for {prefix!r}")

    def act(self, action, timeout=30):
        log(f"ui: {action}")
        with self.lock: self.pending = action
        r = self.wait_event("done", timeout)
        if r != "done": log(f"   -> {r}")
        return r

def start_test(log_path):
    env = dict(os.environ, TEST_RUNNER_OS3D_BOTTLE_TAKE="1",
               TEST_RUNNER_OS3D_BOTTLE_CONTROL_PORT=str(CONTROL_PORT),
               TEST_RUNNER_OS3D_BOTTLE_BRIDGE_PORT=BRIDGE_PORT)
    cmd = ["xcodebuild", "test-without-building", "-project", f"{ROOT}/openshape3d.xcodeproj",
           "-scheme", "openshape3d", "-destination", f"platform=iOS Simulator,id={UDID}",
           "-parallel-testing-enabled", "NO",
           "-only-testing:openshape3dUITests/BottleTakeUITests"]
    log(f"starting the take test (log: {log_path})")
    return subprocess.Popen(cmd, env=env, stdout=open(log_path, "w"), stderr=subprocess.STDOUT)

# ---- bridge -------------------------------------------------------------------

def call(path, payload=None, timeout=60):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r: return json.load(r)
    except urllib.error.HTTPError as e: return json.load(e)

def cmd(id, wait=0.0):
    r = call("/v1/command", {"id": id})
    if not r.get("ran"): log(f"command {id}: {r}")
    if wait: time.sleep(wait)

def state(): return call("/v1/state")

# ---- recording + timeline -----------------------------------------------------

class Recorder:
    def start(self, path):
        if os.path.exists(path): os.remove(path)
        self.p = subprocess.Popen(["xcrun", "simctl", "io", UDID, "recordVideo", "--codec=h264", "--force", path],
                                  stderr=subprocess.PIPE, text=True)
        while True:
            line = self.p.stderr.readline()
            if "Recording started" in line: log("recording"); return
            if self.p.poll() is not None: sys.exit("recordVideo exited before starting")
    def stop(self):
        self.p.send_signal(signal.SIGINT); self.p.wait(timeout=120); log("recording stopped")

class Timeline:
    def __init__(self): self.t0 = time.time(); self.segs = []; self.cur = None
    def now(self): return time.time() - self.t0
    def begin(self, id):
        self.end(); self.cur = {"id": id, "start": self.now()}; log(f"== {id} @ {self.cur['start']:.1f}s")
    def end(self):
        if self.cur: self.cur["end"] = self.now(); self.segs.append(self.cur); self.cur = None
    def hold(self, extra=0.6):
        need = self.cur["start"] + DUR[self.cur["id"]] + 0.35 + extra
        while self.now() < need: time.sleep(0.1)
    def dump(self, path):
        self.end(); json.dump({"segments": self.segs, "total": self.now()}, open(path, "w"), indent=1)

# ---- the profile (normalised window coordinates, head-on front view) ------------

AXIS_X = 0.44
# (r, h) mm from the lip down to the base — the Tufts bottle trace, simplified.
OUTLINE = [(13.5, 230), (14, 205), (15, 188), (21, 168), (28, 150), (31.5, 125), (32, 95), (30, 55), (32, 22), (28, 0)]
PROFILE = [(AXIS_X, 0.85), (0.50, 0.85), (0.515, 0.78), (0.51, 0.62), (0.515, 0.52), (0.505, 0.44),
           (0.475, 0.35), (0.465, 0.27), (0.465, 0.17), (0.475, 0.15), (AXIS_X, 0.15), (AXIS_X, 0.85)]

def take(out, dry=False):
    simctl("terminate", UDID, BUNDLE, check=False)
    control = Control(CONTROL_PORT)
    test = start_test(f"{out}/xcodebuild.log")
    control.wait_event("ready", 900)
    time.sleep(2.5)
    rec = Recorder(); rec.start(f"{out}/raw.mp4")
    tl = Timeline()
    try:
        tl.begin("intro"); time.sleep(1.0); tl.hold(0.2)
        tl.begin("new_design"); time.sleep(0.8)
        control.act("new_design"); tl.hold(0.3)

        tl.begin("plane"); time.sleep(1.5)
        control.act("sketch_tool:Line")
        control.act("wait_text:Choose a sketch plane"); time.sleep(1.2)
        im = screenshot(tag="plane-picker")
        r, g, b = im[..., 0], im[..., 1], im[..., 2]
        blue = (b > r + 35) & (b > g + 15) & (b > 150)
        found = blob(blue)
        if not found: sys.exit("front-plane tile not found")
        cx, cy, area = found
        log(f"front tile at {cx:.0f},{cy:.0f} (area {area:.0f} pt2)")
        control.act(f"tap:{norm(cx, cy)}")
        if control.act("wait_text:Sketching on plane") != "done":
            screenshot(tag="plane-miss"); sys.exit("the sketch did not start on the front plane")
        time.sleep(1.5)
        time.sleep(1.0)
        tl.hold(0.2)

        tl.begin("axis"); time.sleep(1.5)
        control.act(f"chain:{AXIS_X:.4f},0.85;{AXIS_X:.4f},0.15", timeout=30)
        time.sleep(1.0)
        control.act("palette_label:Sketch/Line")          # finish the chain (tool off)
        time.sleep(1.0)
        if control.act("dimension:230", timeout=40) != "done":
            control.act(f"tap:{AXIS_X:.4f},0.50"); time.sleep(1.2)
            control.act("dimension:230", timeout=40)
        time.sleep(1.5)
        control.act("button:Fit View"); time.sleep(1.5)
        im = screenshot(tag="axis")
        r, g, b = im[..., 0], im[..., 1], im[..., 2]
        orange = (r > 200) & (g > 110) & (g < 215) & (b < 110)
        ab = bbox(orange, 300)
        if not ab: sys.exit("selected centreline not found after Fit View")
        ax, y_top, y_bot = (ab[0] + ab[2]) / 2, ab[1], ab[3]
        scale = (y_bot - y_top) / 230.0                     # pt per mm
        log(f"centreline x {ax:.0f}, y {y_top:.0f}..{y_bot:.0f}, {scale:.3f} pt/mm")
        tl.hold(0.3)

        tl.begin("profile"); time.sleep(1.5)
        control.act("palette_label:Sketch/Line")          # arm Line again
        time.sleep(0.8)
        pts = [(0, 230)] + OUTLINE + [(0, 0)]
        chain = ";".join(norm(ax + rr * scale, y_bot - hh * scale) for rr, hh in pts)
        control.act("chain:" + chain, timeout=90)
        time.sleep(1.0)
        control.act("palette_label:Sketch/Line")          # tool off
        time.sleep(0.6)
        tl.hold(0.4)

        tl.begin("revolve"); time.sleep(1.0)
        control.act("button:Exit Sketching"); time.sleep(1.5)
        im = screenshot(tag="profile")
        r, g, b = im[..., 0], im[..., 1], im[..., 2]
        fill = (b > r + 20) & (b > g + 8) & (b > 170) & (r < 235)
        fb = bbox(fill, 3000)
        if not fb: sys.exit("profile fill not found")
        x0, y0, x1, y1 = fb
        log(f"profile fill bbox {fb}")
        control.act(f"tap:{norm(x0 + 0.45 * (x1 - x0), (y0 + y1) / 2)}")
        control.act("wait_text:Extrude"); time.sleep(1.5)
        control.act("button:Revolve"); time.sleep(0.8)
        control.act("wait_text:Tap a sketch line to set the revolve axis"); time.sleep(0.8)
        control.act(f"tap:{norm(x0 - 1, (y0 + y1) / 2 + 40)}")   # on the centreline, clear of the fill's centre
        if control.act("wait_text:Angle") != "done":
            control.act(f"tap:{norm(x0 - 3, (y0 + y1) / 2 - 60)}"); control.act("wait_text:Angle"); time.sleep(2.0)
        control.act("button:Revolve"); time.sleep(1.0)
        cmd("view.isometric", 1.2); cmd("view.fit", 1.0)
        tl.hold(0.3)

        tl.begin("material"); time.sleep(1.5)
        im = screenshot(tag="revolved")
        body = (np.abs(im[..., 0] - im[..., 1]) < 12) & (im[..., 0] < 190) & (im[..., 0] > 60)
        mb = bbox(body, 3000)
        if mb:
            control.act(f"double_tap:{norm((mb[0] + mb[2]) / 2, (mb[1] + mb[3]) / 2)}")
            time.sleep(1.0)
        control.act("palette:Sketch/MaterialButton"); time.sleep(1.5)
        control.act("button:MaterialPresetPlasticGloss"); time.sleep(1.5)
        control.act("button:MaterialApply"); time.sleep(1.2)
        control.act("tap:0.88,0.82"); time.sleep(0.6)      # deselect: drop the gizmo
        tl.hold(0.3)

        tl.begin("shell"); time.sleep(0.8)
        cmd("view.top", 1.2); cmd("view.fit", 1.2)
        im = screenshot(tag="top")
        r, g, b = im[..., 0], im[..., 1], im[..., 2]
        blue = (b > r + 60) & (b > g + 20)
        found = blob(blue)
        if not found: sys.exit("bottle not found in top view")
        tcx, tcy, area = found
        R = float(np.sqrt(area / np.pi))
        log(f"top view centre {tcx:.0f},{tcy:.0f} R {R:.0f}")
        control.act("palette:Modify/ShellButton"); time.sleep(1.2)
        control.act(f"tap:{norm(tcx, tcy)}"); time.sleep(1.5)
        control.act("field:ShellThicknessField=2"); time.sleep(1.0)
        control.act("button:ShellApply"); time.sleep(1.5)
        control.act("tap:0.88,0.82"); time.sleep(0.5)      # deselect
        cmd("view.isometric", 1.2); cmd("view.fit", 0.8)
        tl.hold(0.3)

        tl.begin("fillet"); time.sleep(0.8)
        cmd("view.top", 1.2); cmd("view.fit", 1.0)
        # outer lip radius from the kernel vs the widest radius from the picture
        st = state(); bid = st["bodies"][0]["id"]
        edges = call(f"/v1/edges?body={bid}")["edges"]
        top_y = max(e["midpoint"][1] for e in edges if e.get("midpoint"))
        rims = sorted([e for e in edges if e.get("midpoint") and abs(e["midpoint"][1] - top_y) < 0.5],
                      key=lambda e: -e["lengthMM"])
        r_lip = rims[0]["lengthMM"] / (2 * np.pi)
        r_max = max(np.hypot(e["midpoint"][0], e["midpoint"][2]) for e in edges if e.get("midpoint"))
        rx = tcx + R * 0.97 * r_lip / r_max
        log(f"lip r {r_lip:.1f} / max r {r_max:.1f} -> tap x {rx:.0f}")
        control.act("palette:Modify/FilletButton"); time.sleep(1.2)
        control.act(f"tap:{norm(rx, tcy)}"); time.sleep(1.5)
        control.act("field:BlendValueField=1"); time.sleep(1.0)
        control.act("button:BlendApply"); time.sleep(1.5)
        control.act("tap:0.88,0.82"); time.sleep(0.5)      # deselect
        cmd("view.isometric", 1.2); cmd("view.fit", 0.8)
        tl.hold(0.3)

        tl.begin("history"); time.sleep(0.6)
        control.act("button:HistoryButton"); tl.hold(0.8)
        control.act("button:HistoryButton"); time.sleep(0.5)

        tl.begin("outro"); time.sleep(0.5)
        cmd("view.front", 2.5); cmd("view.isometric", 1.5); cmd("view.fit", 0.3)
        tl.hold(1.0)
    finally:
        tl.dump(f"{out}/timeline.json")
        rec.stop()
        with control.lock: control.pending = "finish"
        try: test.wait(timeout=60)
        except subprocess.TimeoutExpired: test.kill()
        control.server.shutdown()
        log(f"take length {tl.now():.1f}s")

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else f"{HERE}/take"
    os.makedirs(out, exist_ok=True)
    take(out)
