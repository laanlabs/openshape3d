#!/usr/bin/env python3
"""Record the App Store app previews (iPhone and iPad) from the live app.

    scripts/preview_video.py iphone|ipad [--out marketing/app-store/previews]

One take per device, ~27 s: the welcome screen, Add Sample Designs, the
Demos folder, the Motorcycle Wheel orbiting, then a mounting plate built
step by step in a new design (sketch, extrude, fillets, boss) with the
History panel opened at the end.

Two halves. The taps are performed by an XCUITest
(openshape3dUITests/PreviewTakeUITests) that this script remote-controls
over a small HTTP loop on the host, so they land by element identity
whatever the Simulator windows are doing on screen; the camera moves and
the modelling go over the app's DEBUG bridge (port 8899) while the test
waits. The raw take is `simctl io recordVideo` at the device's native size
(iPhone 17 Pro Max 1320 × 2868, iPad Pro 13-inch 2064 × 2752). ffmpeg then
makes the App Store file: portrait 886 × 1920 (every modern iPhone size,
6.1"–6.9") or 1200 × 1600 (every current iPad), 30 fps H.264 at ~10 Mbps
with a silent stereo 256 kbps AAC track, trimmed to 29.5 s — the spec is
15–30 s, 30 fps max, .mp4/.mov, stereo AAC. Both are portrait to match
the screenshots (App Store Connect wants one orientation per device size).

Needs Xcode (the test build is part of the run), `ffmpeg` on PATH, and no
other app instance holding port 8899.
"""


import argparse, json, os, re, signal, subprocess, sys, threading, time, urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTROL_PORT = int(os.environ.get("OS3D_PREVIEW_CONTROL_PORT", "8898"))
BUNDLE = "com.laan.labs.openshape3d"
PORT = os.environ.get("OS3D_PORT", "8899")
BASE = f"http://127.0.0.1:{PORT}"

DEVICES = {
    "iphone": dict(name="iPhone 17 Pro Max", points=(440, 956), size=(886, 1920)),
    "ipad":   dict(name="iPad Pro 13-inch (M5)", points=(1032, 1376), size=(1200, 1600)),
}


def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def simctl(*args, env=None, check=True):
    return subprocess.run(["xcrun", "simctl", *args], check=check, env=env,
                          capture_output=True, text=True)


def udid_for(name):
    out = simctl("list", "devices", "available").stdout
    for line in out.splitlines():
        if name + " (" in line:
            m = re.search(r"[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}", line)
            if m:
                return m.group(0)
    sys.exit(f"no simulator named {name}")


class Device:
    def __init__(self, key):
        self.key = key
        self.spec = DEVICES[key]
        self.name = self.spec["name"]
        self.udid = udid_for(self.name)

    def terminate_app(self):
        simctl("terminate", self.udid, BUNDLE, check=False)

    def start_recording(self, path):
        if os.path.exists(path):
            os.remove(path)
        self.rec = subprocess.Popen(
            ["xcrun", "simctl", "io", self.udid, "recordVideo", "--codec=h264", "--force", path],
            stderr=subprocess.PIPE, text=True)
        while True:
            line = self.rec.stderr.readline()
            if "Recording started" in line:
                log("recording")
                return
            if self.rec.poll() is not None:
                sys.exit("recordVideo exited before starting")

    def stop_recording(self):
        self.rec.send_signal(signal.SIGINT)
        self.rec.wait(timeout=60)
        log("recording stopped")


# ---- the tap side: a remote-controlled XCUITest ----------------------------

class Control:
    """Host end of the loop PreviewTakeUITests polls: one pending action at a
    time, acknowledged with an event."""

    def __init__(self, port):
        self.pending = ""
        self.events = []
        self.lock = threading.Lock()
        outer = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def do_GET(self):
                with outer.lock:
                    body = outer.pending if self.path == "/next" else ""
                self.send_response(200)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body.encode())

            def do_POST(self):
                n = int(self.headers.get("Content-Length", 0))
                msg = self.rfile.read(n).decode()
                with outer.lock:
                    outer.events.append(msg)
                    if msg == "done":
                        outer.pending = ""
                self.send_response(200)
                self.send_header("Content-Length", "0")
                self.end_headers()

        self.server = HTTPServer(("127.0.0.1", port), Handler)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def wait_event(self, name, timeout):
        end = time.time() + timeout
        while time.time() < end:
            with self.lock:
                if name in self.events:
                    self.events.remove(name)
                    return
            time.sleep(0.05)
        sys.exit(f"timed out waiting for the test to report {name!r}")

    def act(self, action, timeout=20):
        log(f"tap: {action}")
        with self.lock:
            self.pending = action
        self.wait_event("done", timeout)


def start_test(dev):
    env = dict(os.environ,
               TEST_RUNNER_OS3D_PREVIEW_TAKE="1",
               TEST_RUNNER_OS3D_PREVIEW_CONTROL_PORT=str(CONTROL_PORT),
               TEST_RUNNER_OS3D_PREVIEW_BRIDGE_PORT=PORT)
    log_path = os.path.join(ROOT, "marketing", "app-store", "previews", f"{dev.key}-xcodebuild.log")
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    cmd = ["xcodebuild", "test", "-project", os.path.join(ROOT, "openshape3d.xcodeproj"),
           "-scheme", "openshape3d", "-destination", f"platform=iOS Simulator,id={dev.udid}",
           "-parallel-testing-enabled", "NO",
           "-only-testing:openshape3dUITests/PreviewTakeUITests"]
    log(f"starting the take test (log: {log_path})")
    return subprocess.Popen(cmd, env=env, stdout=open(log_path, "w"), stderr=subprocess.STDOUT)


# ---- bridge ---------------------------------------------------------------

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


def cmd(id):
    call("/v1/command", {"id": id})


# ---- the take ---------------------------------------------------------------

def build_plate():
    """The mounting plate, one visible step at a time."""
    sk = X("sketch.create", {"name": "Plate"})["sketchID"]
    X("sketch.addEntities", {"sketchID": sk, "entities": [
        {"kind": "rect", "min": [-20, -12], "max": [20, 12]}]})
    # A new design's camera sits close to the origin; frame the sketch.
    cmd("view.fit"); time.sleep(0.8)
    X("sketch.addEntities", {"sketchID": sk, "entities": [
        {"kind": "circle", "center": [-12, 0], "radius": 3},
        {"kind": "circle", "center": [12, 0], "radius": 3}]})
    time.sleep(0.8)
    body = X("feature.extrude", {"sketchID": sk, "seedPoint": [0, 8], "distance": 6})["producedBodyIDs"][0]
    time.sleep(0.4); cmd("view.fit"); time.sleep(0.8)
    edges = call(f"/v1/edges?body={body}")["edges"]
    corners = [e["index"] for e in edges
               if e.get("midpoint") and abs(e["midpoint"][1] - 3) < 0.1 and abs(e["lengthMM"] - 6) < 0.1]
    X("feature.fillet", {"bodyID": body, "radius": 4, "edges": corners})
    time.sleep(0.9)
    edges = call(f"/v1/edges?body={body}")["edges"]
    top = [e["index"] for e in edges if e.get("midpoint") and abs(e["midpoint"][1] - 6) < 0.1]
    X("feature.fillet", {"bodyID": body, "radius": 1, "edges": top})
    time.sleep(0.9)
    boss = X("sketch.create", {"name": "Boss", "origin": [0, 6, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": boss, "entities": [
        {"kind": "circle", "center": [0, 0], "radius": 5}]})
    time.sleep(0.5)
    X("feature.extrude", {"sketchID": boss, "seedPoint": [0, 0], "distance": 4.5,
                          "boolean": "union", "booleanTargets": [body]})
    time.sleep(0.7)
    X("body.setMaterial", {"bodyIDs": [body], "color": [0.30, 0.56, 0.96], "roughness": 0.3})
    X("item.setHidden", {"allSketches": True})


def take(dev, raw):
    dev.terminate_app()
    control = Control(CONTROL_PORT)
    test = start_test(dev)
    control.wait_event("ready", 600)   # includes the test build
    time.sleep(2.0)                     # welcome sheet fully presented
    dev.start_recording(raw)
    t0 = time.time()
    time.sleep(1.6)                     # 1. welcome
    control.act("add_samples")
    time.sleep(1.5)                     # 2. Demos folder
    control.act("wheel_card")
    wait_document()
    time.sleep(0.6)                     # 3. the wheel
    cmd("view.front"); time.sleep(1.2)
    cmd("view.isometric"); time.sleep(1.4)
    control.act("back")
    time.sleep(0.6)
    control.act("new_design")
    wait_document()
    time.sleep(0.5)                     # 4. a blank design
    build_plate()                       # 5. ~8 s of modelling
    cmd("view.isometric"); time.sleep(0.3)
    cmd("view.fit"); time.sleep(0.9)
    control.act("history")              # 6. History panel
    time.sleep(3.0)
    log(f"take length {time.time() - t0:.1f} s")
    dev.stop_recording()
    with control.lock:
        control.pending = "finish"
    try:
        test.wait(timeout=120)
    except subprocess.TimeoutExpired:
        test.kill()
    control.server.shutdown()


def encode(raw, out, size, seconds=29.5):
    w, h = size
    vf = f"scale={w}:{h}:force_original_aspect_ratio=increase:flags=lanczos,crop={w}:{h},fps=30,format=yuv420p"
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", raw,
        "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000",
        "-t", str(seconds), "-vf", vf,
        "-c:v", "libx264", "-profile:v", "high", "-level", "4.1", "-preset", "slow",
        "-b:v", "10M", "-maxrate", "12M", "-bufsize", "20M",
        "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2",
        "-movflags", "+faststart", out], check=True)
    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0",
                            "-show_entries", "stream=width,height,r_frame_rate,codec_name:format=duration",
                            "-of", "default=nw=1", out], capture_output=True, text=True).stdout
    log(f"wrote {out}\n{probe.strip()}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("device", choices=list(DEVICES))
    ap.add_argument("--out", default=os.path.join(ROOT, "marketing", "app-store", "previews"))
    ap.add_argument("--encode-only", action="store_true", help="skip the take; re-encode the raw file")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    raw = os.path.join(a.out, f"{a.device}-raw.mp4")
    out = os.path.join(a.out, f"{a.device}-preview.mp4")
    if not a.encode_only:
        take(Device(a.device), raw)
    encode(raw, out, DEVICES[a.device]["size"])
