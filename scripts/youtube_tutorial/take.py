#!/usr/bin/env python3
"""Record the YouTube tutorial take on the landscape iPad simulator.

Writes <out>/raw.mp4 (the simulator framebuffer, portrait-framed with the
landscape content rotated; compose.py turns it upright) and
<out>/timeline.json with the start/end of every narration segment.
"""
import argparse, json, os, signal, subprocess, sys, time, urllib.request
import numpy as np
from PIL import Image

S = os.path.dirname(os.path.abspath(__file__))
os.environ.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")
UDID = "AC2FD923-1661-435F-BF47-3E9DF30D1A16"
WINDOW = "os3d-parity-sept7"
BUNDLE = "com.laan.labs.openshape3d"
PORT = "8921"
BASE = f"http://127.0.0.1:{PORT}"
POINTS = (1376, 1032)            # landscape device points
DUR = json.load(open(f"{S}/tts/durations.json"))

def log(m): print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)

def simctl(*a, env=None, check=True):
    return subprocess.run(["xcrun", "simctl", *a], check=check, env=env, capture_output=True, text=True)

def screenshot(path):
    simctl("io", UDID, "screenshot", path)
    im = Image.open(path).transpose(Image.ROTATE_270)   # framebuffer is portrait-framed
    im.save(path)
    return path

class Sim:
    def __init__(self, calibrate=True):
        self.scale, self.origin = None, None
        if calibrate:
            self.calibrate()

    def calibrate(self):
        shot = screenshot(f"{S}/calib-device.png")
        win_path = f"{S}/calib-window.png"
        subprocess.run(["peekaboo", "see", "--app", "Simulator", "--window-title", WINDOW, "--path", win_path],
                       check=True, capture_output=True)
        win = np.asarray(Image.open(win_path).convert("L"), dtype=np.float32)
        dev = Image.open(shot).convert("L")
        pw, ph = POINTS
        best = None
        for s in np.arange(0.50, 0.70, 0.002):
            w, h = int(round(pw * s)), int(round(ph * s))
            if h > win.shape[0] or w > win.shape[1]:
                continue
            d = np.asarray(dev.resize((w, h), Image.BILINEAR), dtype=np.float32)
            y0, y1, x0, x1 = int(h * 0.15), int(h * 0.85), int(w * 0.1), int(w * 0.9)
            t = d[y0:y1, x0:x1]
            for oy in range(60, win.shape[0] - h + 1, 2):
                for ox in range(0, win.shape[1] - w + 1, 2):
                    e = np.mean(np.abs(win[oy + y0:oy + y1, ox + x0:ox + x1] - t))
                    if best is None or e < best[0]:
                        best = (e, float(s), ox, oy)
        err, self.scale, ox, oy = best
        self.origin = (ox, oy)
        log(f"screen at window ({ox},{oy}), scale {self.scale:.4f}, fit error {err:.1f}")
        if err > 12:
            sys.exit("calibration did not converge")

    def tap(self, px, py, label=""):
        wx, wy = self.origin[0] + px * self.scale, self.origin[1] + py * self.scale
        log(f"tap {label} ({px},{py}) -> window ({wx:.0f},{wy:.0f})")
        subprocess.run(["peekaboo", "click", "--app", "Simulator", "--window-title", WINDOW,
                        "--coords", f"{wx:.0f},{wy:.0f}", "--foreground", "--input-strategy", "synthOnly"],
                       check=True, capture_output=True)

    def launch(self, **env):
        simctl("terminate", UDID, BUNDLE, check=False)
        full = dict(os.environ, SIMCTL_CHILD_OS3D_AGENT="1", SIMCTL_CHILD_OS3D_AGENT_PORT=PORT)
        full.update({"SIMCTL_CHILD_" + k: v for k, v in env.items()})
        simctl("launch", UDID, BUNDLE, env=full)
        for _ in range(30):
            try:
                if call("/v1/health").get("ok"):
                    return
            except Exception:
                pass
            time.sleep(0.5)
        sys.exit("bridge never came up")

    def start_recording(self, path):
        if os.path.exists(path):
            os.remove(path)
        self.rec = subprocess.Popen(["xcrun", "simctl", "io", UDID, "recordVideo", "--codec=h264", "--force", path],
                                    stderr=subprocess.PIPE, text=True)
        while True:
            line = self.rec.stderr.readline()
            if "Recording started" in line:
                log("recording"); return
            if self.rec.poll() is not None:
                sys.exit("recordVideo exited before starting")

    def stop_recording(self):
        self.rec.send_signal(signal.SIGINT)
        self.rec.wait(timeout=120)
        log("recording stopped")

def call(path, payload=None, timeout=120):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.load(e)

def wait_document(seconds=30):
    for _ in range(seconds * 4):
        try:
            if call("/v1/health").get("hasDocument"):
                return
        except Exception:
            pass
        time.sleep(0.25)
    sys.exit("no document opened on the bridge")

def X(op, args):
    r = call("/v1/exec", {"op": op, "args": args}, timeout=300)
    if not r.get("ok") or r.get("evalErrors"):
        sys.exit(f"{op} failed: {json.dumps(r)[:500]}")
    return r

def cmd(id, wait=0.0):
    r = call("/v1/command", {"id": id})
    if not r.get("ran"):
        log(f"command {id}: {r}")
    if wait:
        time.sleep(wait)

# ---- timeline ----------------------------------------------------------------

class Timeline:
    def __init__(self):
        self.t0 = time.time(); self.segs = []; self.cur = None
    def now(self): return time.time() - self.t0
    def begin(self, id):
        self.end()
        self.cur = {"id": id, "start": self.now()}
        log(f"== {id} @ {self.cur['start']:.1f}s")
    def end(self):
        if self.cur:
            self.cur["end"] = self.now(); self.segs.append(self.cur); self.cur = None
    def hold(self, extra=0.6):
        """Wait until the current segment's narration has finished (+extra)."""
        need = self.cur["start"] + DUR[self.cur["id"]] + 0.35 + extra
        while self.now() < need:
            time.sleep(0.1)
    def dump(self, path):
        self.end()
        json.dump({"segments": self.segs, "total": self.now()}, open(path, "w"), indent=1)

# ---- the take ---------------------------------------------------------------

TAPS = json.load(open(f"{S}/taps.json")) if os.path.exists(f"{S}/taps.json") else {}

def take(sim, out):
    sim.launch(OS3D_WELCOME="1", OS3D_RESET_STORE="1")
    time.sleep(4.0)
    sim.start_recording(f"{out}/raw.mp4")
    tl = Timeline()
    tl.begin("intro"); time.sleep(1.0); tl.hold()
    tl.begin("what_is_cad"); tl.hold()
    tl.begin("workflow"); tl.hold(0.3)
    tl.begin("samples")
    time.sleep(1.5)
    sim.tap(*TAPS["add_samples"], label="Add Sample Designs")
    time.sleep(3.0)
    sim.tap(*TAPS["wheel_card"], label="Motorcycle Wheel")
    wait_document(); tl.hold(0.2)
    tl.begin("wheel")
    time.sleep(2.5)
    cmd("view.front", 2.6); cmd("view.right", 2.6); cmd("view.isometric", 1.2); cmd("view.fit", 0.5)
    tl.hold(0.4)
    tl.begin("history")
    time.sleep(0.6)
    sim.tap(*TAPS["history"], label="History")
    tl.hold(1.0)
    sim.tap(*TAPS["history"], label="History (close)")
    time.sleep(0.6)
    tl.begin("new_design")
    time.sleep(0.4)
    sim.tap(*TAPS["back"], label="Designs")
    time.sleep(1.6)
    sim.tap(*TAPS["new_design"], label="New Design")
    wait_document(); tl.hold(0.4)
    # -- modelling
    tl.begin("sketch_rect")
    time.sleep(3.0)
    sk = X("sketch.create", {"name": "Plate"})["sketchID"]
    X("sketch.addEntities", {"sketchID": sk, "entities": [{"kind": "rect", "min": [-20, -12], "max": [20, 12]}]})
    time.sleep(0.5); cmd("view.fit", 0.4)
    tl.hold(0.4)
    tl.begin("sketch_holes")
    time.sleep(2.5)
    X("sketch.addEntities", {"sketchID": sk, "entities": [
        {"kind": "circle", "center": [-12, 0], "radius": 3}]})
    time.sleep(1.2)
    X("sketch.addEntities", {"sketchID": sk, "entities": [
        {"kind": "circle", "center": [12, 0], "radius": 3}]})
    tl.hold(0.4)
    tl.begin("extrude")
    time.sleep(3.0)
    body = X("feature.extrude", {"sketchID": sk, "seedPoint": [0, 8], "distance": 6})["producedBodyIDs"][0]
    time.sleep(1.5); cmd("view.isometric", 0.8); cmd("view.fit", 0.4)
    tl.hold(0.4)
    tl.begin("fillet_corners")
    time.sleep(2.5)
    edges = call(f"/v1/edges?body={body}")["edges"]
    corners = [e["index"] for e in edges
               if e.get("midpoint") and abs(e["midpoint"][1] - 3) < 0.1 and abs(e["lengthMM"] - 6) < 0.1]
    X("feature.fillet", {"bodyID": body, "radius": 4, "edges": corners})
    tl.hold(0.4)
    tl.begin("fillet_top")
    time.sleep(1.2)
    edges = call(f"/v1/edges?body={body}")["edges"]
    top = [e["index"] for e in edges if e.get("midpoint") and abs(e["midpoint"][1] - 6) < 0.1]
    X("feature.fillet", {"bodyID": body, "radius": 1, "edges": top})
    tl.hold(0.8)
    tl.begin("boss")
    time.sleep(1.8)
    boss = X("sketch.create", {"name": "Boss", "origin": [0, 6, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": boss, "entities": [{"kind": "circle", "center": [0, 0], "radius": 5}]})
    time.sleep(2.5)
    X("feature.extrude", {"sketchID": boss, "seedPoint": [0, 0], "distance": 4.5,
                          "boolean": "union", "booleanTargets": [body]})
    tl.hold(0.4)
    tl.begin("material")
    time.sleep(1.0)
    X("body.setMaterial", {"bodyIDs": [body], "color": [0.30, 0.56, 0.96], "roughness": 0.3})
    X("item.setHidden", {"allSketches": True})
    time.sleep(2.2)
    cmd("view.front", 1.8); cmd("view.top", 1.8); cmd("view.isometric", 1.0); cmd("view.fit", 0.3)
    tl.hold(0.3)
    tl.begin("undo")
    time.sleep(0.8)
    for _ in range(4):
        cmd("edit.undo", 0.45)
    time.sleep(0.6)
    for _ in range(4):
        cmd("edit.redo", 0.45)
    tl.hold(0.3)
    tl.begin("outro")
    time.sleep(1.0)
    cmd("view.right", 2.0); cmd("view.isometric", 1.5); cmd("view.fit", 0.3)
    tl.hold(1.2)
    tl.dump(f"{out}/timeline.json")
    sim.stop_recording()
    log(f"take length {tl.now():.1f}s")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=f"{S}/take")
    ap.add_argument("--tap", help="aid: tap X,Y device points, then screenshot")
    ap.add_argument("--shot", help="aid: screenshot path")
    ap.add_argument("--cmd", help="aid: run a bridge command id")
    a = ap.parse_args()
    if a.tap or a.shot or a.cmd:
        sim = Sim(calibrate=bool(a.tap))
        if a.cmd:
            print(call("/v1/command", {"id": a.cmd})); time.sleep(1.2)
        if a.tap:
            sim.tap(*map(float, a.tap.split(",")), label="measure"); time.sleep(2.0)
        if a.shot:
            screenshot(a.shot)
        sys.exit(0)
    os.makedirs(a.out, exist_ok=True)
    take(Sim(), a.out)
