#!/usr/bin/env python3
"""Record the Phone Stand tutorial: real touch interactions performed by
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

# ---- the stand (mm, side profile in the front plane; x right, y up; extruded 70 along z)

W_MM, H_MM, DEPTH = 90.0, 60.0, 70.0
OUTLINE = [(12, 60), (46, 10), (78, 10), (78, 22), (90, 22), (90, 0)]   # from the top of the back to the base's right end
FILLET_X = [90, 0, 12]            # long edges to round, seen from the top
SLOT = (58, 74, 27, 43)           # x0, x1, z0, z1 of the cable slot on the floor

def selected_line():
    """Bounding box (device points) of the orange selected line."""
    im = screenshot(tag="selected")
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    orange = (r > 200) & (g > 110) & (g < 215) & (b < 110)
    return bbox(orange, 300)

def base_extent(im, x_left, y_guess):
    """The base line's row and right end (device points): in a band of rows
    around y_guess, the row with the MOST sketch-blue pixels is the line;
    its run from x_left ends where the columns stop being contiguous."""
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    line = (b > r + 40) & (b > g + 15) & (r < 200)
    best = None
    for y in range(int(y_guess) - 6, int(y_guess) + 16):
        row = line[2 * y: 2 * y + 2].any(axis=0)
        xs = np.nonzero(row)[0] / 2
        xs = xs[xs > x_left + 6]                                # skip the endpoint marker
        if len(xs) < 200: continue
        gaps = np.nonzero(np.diff(xs) > 2.5)[0]
        run_end = xs[gaps[0]] if len(gaps) else xs[-1]
        if best is None or len(xs) > best[2]:
            best = (y, run_end, len(xs))
    return best and (best[0], best[1])

def blue_body(tag):
    im = screenshot(tag=tag)
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    return blob((b > r + 60) & (b > g + 20))

def blue_bbox(tag):
    im = screenshot(tag=tag)
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mask = (b > r + 60) & (b > g + 20)
    mask[:2 * 200, :] = False; mask[2 * 990:, :] = False      # top bars / bottom pills
    mask[:, :2 * 110] = False; mask[:, 2 * 1170:] = False     # palette / constraints panel
    found = blob(mask)
    if not found: return None
    # bbox of the solid region only: mask rows/cols near the blob
    cx, cy, area = found
    ys, xs = np.nonzero(mask)
    keep = (np.abs(xs / 2 - cx) < 700) & (np.abs(ys / 2 - cy) < 520)
    xs, ys = xs[keep], ys[keep]
    hx = np.bincount(xs, minlength=mask.shape[1]); hy = np.bincount(ys, minlength=mask.shape[0])
    kx = np.nonzero(hx >= 0.3 * hx.max())[0]; ky = np.nonzero(hy >= 0.3 * hy.max())[0]
    return (kx.min() / 2, ky.min() / 2, kx.max() / 2, ky.max() / 2)

def take(out):
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
        found = blob((b > r + 35) & (b > g + 15) & (b > 150))
        if not found: sys.exit("front-plane tile not found")
        control.act(f"tap:{norm(found[0], found[1])}")
        if control.act("wait_text:Sketching on plane") != "done":
            sys.exit("the sketch did not start on the front plane")
        time.sleep(1.0); tl.hold(0.2)

        # -- base: a horizontal line, dimensioned to 90
        tl.begin("base"); time.sleep(1.5)
        control.act("chain:0.22,0.62;0.78,0.62", timeout=30); time.sleep(1.0)
        control.act("palette_label:Sketch/Line"); time.sleep(1.0)
        if control.act("dimension:90", timeout=40) != "done":
            control.act("tap:0.50,0.62"); time.sleep(1.2); control.act("dimension:90", timeout=40)
        time.sleep(1.5)
        control.act("button:Fit View"); time.sleep(1.5)
        sb = selected_line()
        if not sb: sys.exit("base line not found after Fit View")
        x_left, y_base, x_right = sb[0], (sb[1] + sb[3]) / 2, sb[2]
        s1 = (x_right - x_left) / W_MM
        log(f"base {x_left:.0f}..{x_right:.0f} at y {y_base:.0f}: {s1:.2f} pt/mm")
        tl.hold(0.3)

        # -- back: a vertical line from the base's left end, dimensioned to 60
        tl.begin("back"); time.sleep(1.5)
        control.act("palette_label:Sketch/Line"); time.sleep(0.8)
        up = min(38.0 * s1, y_base - 130)                   # stay below the toolbar
        control.act(f"chain:{norm(x_left, y_base)};{norm(x_left, y_base - up)}", timeout=30); time.sleep(1.0)
        control.act("palette_label:Sketch/Line"); time.sleep(1.0)
        control.act("button:ConstraintRail-vertical"); time.sleep(1.2)   # lock it upright (deselects)
        control.act(f"tap:{norm(x_left, y_base - up / 2)}"); time.sleep(1.2)
        if control.act("dimension:60", timeout=40) != "done":
            control.act(f"tap:{norm(x_left, y_base - up / 2)}"); time.sleep(1.2); control.act("dimension:60", timeout=40)
        time.sleep(1.5)
        control.act("button:Fit View"); time.sleep(1.5)
        vb = selected_line()
        if not vb: sys.exit("back line not found after Fit View")
        if vb[2] - vb[0] > 8: sys.exit(f"back line is not vertical: {vb}")
        x_left = (vb[0] + vb[2]) / 2
        ext = base_extent(screenshot(tag="fitted"), x_left, vb[3])
        if not ext: sys.exit("base line not found after the second Fit View")
        y_bot, x_right = ext
        s = (x_right - x_left) / W_MM
        log(f"back x {x_left:.0f}, base row {y_bot:.0f} to x {x_right:.0f}: {s:.2f} pt/mm")
        X = lambda x: x_left + x * s
        Y = lambda y: y_bot - y * s
        tl.hold(0.3)

        # -- the rest of the profile
        tl.begin("profile"); time.sleep(1.5)
        control.act("palette_label:Sketch/Line"); time.sleep(0.8)
        pts = [(0, H_MM)] + OUTLINE
        control.act("chain:" + ";".join(norm(X(x), Y(y)) for x, y in pts), timeout=90)
        time.sleep(1.0)
        control.act("palette_label:Sketch/Line"); time.sleep(0.6)
        tl.hold(0.4)

        # -- extrude 70
        tl.begin("extrude"); time.sleep(1.0)
        control.act("button:Exit Sketching"); time.sleep(1.5)
        control.act(f"tap:{norm(X(45), Y(5))}")
        control.act("wait_text:Extrude"); time.sleep(1.5)
        control.act(f"field:Distance={DEPTH:.0f}"); time.sleep(1.5)
        cmd("view.isometric", 1.2); cmd("view.fit", 1.0)
        tl.hold(0.3)

        # -- material
        tl.begin("material"); time.sleep(1.5)
        im = screenshot(tag="extruded")
        body = (np.abs(im[..., 0] - im[..., 1]) < 12) & (im[..., 0] < 190) & (im[..., 0] > 60)
        found = blob(body)
        if found:
            control.act(f"double_tap:{norm(found[0], found[1])}"); time.sleep(1.0)
        control.act("palette:Sketch/MaterialButton"); time.sleep(1.5)
        control.act("button:MaterialPresetPlasticGloss"); time.sleep(1.5)
        control.act("button:MaterialApply"); time.sleep(1.2)
        control.act("tap:0.88,0.82"); time.sleep(0.6)
        tl.hold(0.3)

        # -- fillet the long edges, picked from the top
        tl.begin("fillet"); time.sleep(0.8)
        cmd("view.top", 1.2); cmd("view.fit", 1.2)
        tb = blue_bbox("top")
        if not tb: sys.exit("stand not found in top view")
        tx0, ty0, tx1, ty1 = tb
        # the profile's x runs along the wider screen axis; z along the other
        horizontal = (tx1 - tx0) >= (ty1 - ty0)
        log(f"top bbox {tb} horizontal={horizontal}")
        def TX(x):  # screen point of profile-x at mid depth
            if horizontal: return (tx0 + x / W_MM * (tx1 - tx0), (ty0 + ty1) / 2)
            return ((tx0 + tx1) / 2, ty0 + x / W_MM * (ty1 - ty0))
        control.act("palette:Modify/FilletButton"); time.sleep(1.2)
        # which end is x=0? try the lip (x=90) first; the response tells nothing, so
        # rely on geometry: the back (x=0) edge is the taller side — both ends are
        # silhouette edges from the top, so tapping both ends is symmetric anyway.
        for x in FILLET_X:
            px, py = TX(x)
            control.act(f"tap:{norm(px, py)}"); time.sleep(1.2)
        control.act("field:BlendValueField=3"); time.sleep(1.0)
        control.act("button:BlendApply"); time.sleep(1.5)
        control.act("tap:0.88,0.82"); time.sleep(0.5)
        cmd("view.isometric", 1.2); cmd("view.fit", 0.8)
        tl.hold(0.3)

        # -- cable slot: sketch on the floor face, cut through
        tl.begin("slot"); time.sleep(1.0)
        cmd("view.top", 1.2); cmd("view.fit", 1.2)
        tb = blue_bbox("top2")
        tx0, ty0, tx1, ty1 = tb
        horizontal = (tx1 - tx0) >= (ty1 - ty0)
        # x=0 (the back) vs x=90 (the lip): the back's top is 8 mm wide, the lip
        # 12 mm; both ends look alike from the top, so find the floor by colour:
        # the sloped rest and the floor are all blue — use the geometry instead.
        def TXZ(x, z):
            if horizontal: return (tx0 + x / W_MM * (tx1 - tx0), ty0 + z / DEPTH * (ty1 - ty0))
            return (tx0 + z / DEPTH * (tx1 - tx0), ty0 + x / W_MM * (ty1 - ty0))
        control.act("sketch_tool:Rectangle")
        control.act("wait_text:Choose a sketch plane"); time.sleep(1.0)
        fx, fy = TXZ(64, 35)
        control.act(f"tap:{norm(fx, fy)}")
        if control.act("wait_text:Sketching on plane") != "done":
            fx, fy = TXZ(W_MM - 64, 35)                   # the other end was the lip
            control.act(f"tap:{norm(fx, fy)}"); control.act("wait_text:Sketching on plane")
        time.sleep(2.0)
        tb = blue_bbox("floor")
        tx0, ty0, tx1, ty1 = tb
        horizontal = (tx1 - tx0) >= (ty1 - ty0)
        a = TXZ(SLOT[0], SLOT[2]); c = TXZ(SLOT[1], SLOT[3])
        control.act(f"drag:{norm(*a)};{norm(*c)}"); time.sleep(1.5)
        control.act("button:Exit Sketching"); time.sleep(1.5)
        m = TXZ((SLOT[0] + SLOT[1]) / 2, (SLOT[2] + SLOT[3]) / 2)
        control.act(f"tap:{norm(*m)}")
        control.act("wait_text:Extrude"); time.sleep(1.2)
        control.act("button:Subtract"); time.sleep(0.8)
        control.act("field:Distance=-15"); time.sleep(1.5)
        control.act("tap:0.88,0.82"); time.sleep(0.5)
        cmd("view.isometric", 1.2); cmd("view.fit", 0.8)
        tl.hold(0.3)

        # -- export menu
        tl.begin("export"); time.sleep(1.5)
        control.act("button:ExportMenu"); time.sleep(3.5)
        control.act("key:escape"); time.sleep(1.0)
        control.act("button:HistoryButton"); time.sleep(0.5)
        tl.hold(0.5)
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
