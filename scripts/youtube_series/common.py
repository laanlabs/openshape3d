#!/usr/bin/env python3
"""Shared machinery for the YouTube tutorial series (sketching, shapes, materials).

A take = the app recorded on the landscape `os3d-video` iPad simulator while
this host script (1) remote-controls `TutorialTakeUITests` for the real
touches, (2) drives modelling and the camera over the DEBUG bridge, and
(3) paces every chapter to its narration clip. compose() then lays the take
out at 1920×1080 beside a chapter panel with the narration (edge-tts neural
voice) and a music bed, and writes the YouTube metadata (title, description
with chapter timestamps, tags).
"""
import asyncio, hashlib, json, os, re, signal, subprocess, sys, threading, time, urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

S = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(S))
os.environ.setdefault("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer")
DEVICE = os.environ.get("OS3D_VIDEO_SIM", "os3d-video")
BUNDLE = "com.laan.labs.openshape3d"
BRIDGE_PORT = os.environ.get("OS3D_TUTORIAL_BRIDGE_PORT", "8931")
CONTROL_PORT = int(os.environ.get("OS3D_TUTORIAL_CONTROL_PORT", "8930"))
BASE = f"http://127.0.0.1:{BRIDGE_PORT}"
DD = os.environ.get("OS3D_VIDEO_DD", os.path.join(S, "dd"))
OUT_DIR = os.path.join(ROOT, "marketing", "youtube")
POINTS = (1376, 1032)                 # landscape device points = touch space
VOICE = os.environ.get("OS3D_VOICE", "en-US-AndrewMultilingualNeural")
RATE = os.environ.get("OS3D_VOICE_RATE", "-3%")
ICON = os.path.join(ROOT, "openshape3d/Assets.xcassets/AppIcon.appiconset/icon-ios-1024x1024.png")
LOOPS = "/Library/Audio/Apple Loops/Apple/07 Chillwave"


def log(m):
    print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)


def simctl(*a, env=None, check=True):
    return subprocess.run(["xcrun", "simctl", *a], check=check, env=env, capture_output=True, text=True)


def udid_for(name=DEVICE):
    out = simctl("list", "devices", "available").stdout
    for line in out.splitlines():
        if name + " (" in line:
            m = re.search(r"[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}", line)
            if m:
                return m.group(0)
    sys.exit(f"no simulator named {name}; create it with `xcrun simctl create {name} \"iPad Pro 13-inch (M5)\" <runtime>`")


# ---- bridge ---------------------------------------------------------------------

def call(path, payload=None, timeout=120):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.load(e)


def wait_document(seconds=40):
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
        sys.exit(f"{op} failed: {json.dumps(r)[:600]}")
    return r


def cmd(id, wait=0.0):
    r = call("/v1/command", {"id": id})
    if not r.get("ran"):
        log(f"command {id}: {str(r)[:200]}")
    if wait:
        time.sleep(wait)


def state():
    return call("/v1/state")


def bodies():
    return state().get("bodies", [])


def edges(body):
    return call(f"/v1/edges?body={body}")["edges"]


def faces(body):
    return call(f"/v1/faces?body={body}")["faces"]


def normalized(world):
    """World mm → normalised window coordinates for the test's tap/drag."""
    pts = ";".join(",".join(str(c) for c in p) for p in world)
    r = call(f"/v1/project?points={pts}")
    out = []
    for p in r["points"]:
        if p is None:
            sys.exit(f"point behind the camera: {world}")
        out.append((p["x"] / POINTS[0], p["y"] / POINTS[1]))
    return out


def nstr(xy):
    return f"{xy[0]:.4f},{xy[1]:.4f}"


# ---- remote-controlled test -------------------------------------------------------

class Control:
    def __init__(self, port=CONTROL_PORT):
        self.pending, self.events, self.lock = "", [], threading.Lock()
        outer = self

        class H(BaseHTTPRequestHandler):
            def log_message(self, *a): pass

            def do_GET(self):
                with outer.lock:
                    body = outer.pending if self.path == "/next" else ""
                self.send_response(200); self.send_header("Content-Length", str(len(body))); self.end_headers()
                self.wfile.write(body.encode())

            def do_POST(self):
                n = int(self.headers.get("Content-Length", 0))
                msg = self.rfile.read(n).decode()
                with outer.lock:
                    outer.events.append(msg)
                    if msg.startswith("done"):
                        outer.pending = ""
                self.send_response(200); self.send_header("Content-Length", "0"); self.end_headers()

        self.server = HTTPServer(("127.0.0.1", port), H)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def wait_event(self, prefix, timeout):
        end = time.time() + timeout
        while time.time() < end:
            with self.lock:
                for e in self.events:
                    if e.startswith(prefix):
                        self.events.remove(e)
                        return e
            time.sleep(0.05)
        sys.exit(f"timed out waiting for the test to report {prefix!r}")

    def act(self, action, timeout=30):
        log(f"touch: {action}")
        with self.lock:
            self.pending = action
        r = self.wait_event("done", timeout)
        if r != "done":
            log(f"   -> {r}")
        return r

    def finish(self):
        with self.lock:
            self.pending = "finish"


def start_test(udid, log_path):
    env = dict(os.environ, TEST_RUNNER_OS3D_TUTORIAL_TAKE="1",
               TEST_RUNNER_OS3D_TUTORIAL_CONTROL_PORT=str(CONTROL_PORT),
               TEST_RUNNER_OS3D_TUTORIAL_BRIDGE_PORT=BRIDGE_PORT)
    cmdline = ["xcodebuild", "test", "-project", os.path.join(ROOT, "openshape3d.xcodeproj"),
               "-scheme", "openshape3d", "-destination", f"platform=iOS Simulator,id={udid}",
               "-derivedDataPath", DD, "-parallel-testing-enabled", "NO",
               "-only-testing:openshape3dUITests/TutorialTakeUITests"]
    return subprocess.Popen(cmdline, env=env, stdout=open(log_path, "w"), stderr=subprocess.STDOUT)


class Recorder:
    def __init__(self, udid):
        self.udid = udid

    def start(self, path):
        if os.path.exists(path):
            os.remove(path)
        self.rec = subprocess.Popen(["xcrun", "simctl", "io", self.udid, "recordVideo", "--codec=h264", "--force", path],
                                    stderr=subprocess.PIPE, text=True)
        while True:
            line = self.rec.stderr.readline()
            if "Recording started" in line:
                log("recording"); return
            if self.rec.poll() is not None:
                sys.exit("recordVideo exited before starting")

    def stop(self):
        self.rec.send_signal(signal.SIGINT)
        self.rec.wait(timeout=180)
        log("recording stopped")


# ---- narration ------------------------------------------------------------------

def tts_dir(name):
    d = os.path.join(S, "tts", name)
    os.makedirs(d, exist_ok=True)
    return d


def synthesize(name, script):
    """One clip per segment (edge-tts, cached by text+voice); returns {id: seconds}."""
    import edge_tts
    d = tts_dir(name)
    durations = {}
    from pronunciation import speakable
    for seg in script:
        spoken = speakable(seg["say"])            # respellings: see pronunciation.py
        key = hashlib.sha1((VOICE + RATE + spoken).encode()).hexdigest()[:10]
        path = os.path.join(d, f"{seg['id']}-{key}.mp3")
        if not os.path.exists(path):
            log(f"tts {seg['id']}")
            asyncio.run(edge_tts.Communicate(spoken, VOICE, rate=RATE).save(path))
        seg["_clip"] = path
        durations[seg["id"]] = float(subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
            capture_output=True, text=True).stdout.strip())
    return durations


# ---- timeline ---------------------------------------------------------------------

class Timeline:
    def __init__(self, durations):
        self.dur = durations; self.t0 = time.time(); self.segs = []; self.cur = None

    def now(self): return time.time() - self.t0

    def begin(self, id):
        self.end()
        self.cur = {"id": id, "start": self.now()}
        log(f"== {id} @ {self.cur['start']:.1f}s ({self.dur[id]:.1f}s of narration)")

    def end(self):
        if self.cur:
            self.cur["end"] = self.now(); self.segs.append(self.cur); self.cur = None

    def mark(self):
        """A sub-step inside the current segment: the panel's k-th `steps` entry shows from here."""
        self.cur.setdefault("marks", []).append(self.now())

    def hold(self, extra=0.6):
        """Wait until the current segment's narration has finished (+extra)."""
        need = self.cur["start"] + self.dur[self.cur["id"]] + 0.35 + extra
        while self.now() < need:
            time.sleep(0.1)

    def remaining(self):
        return max(0.0, self.cur["start"] + self.dur[self.cur["id"]] + 0.35 - self.now())

    def dump(self, path):
        self.end()
        json.dump({"segments": self.segs, "total": self.now()}, open(path, "w"), indent=1)


# ---- the take runner --------------------------------------------------------------

class Take:
    """What a video's take() receives: control (touches), timeline, bridge helpers."""

    def __init__(self, control, timeline):
        self.c, self.tl = control, timeline

    def touch(self, action, timeout=30):
        return self.c.act(action, timeout)

    def tap_world(self, x, y, z=0):
        self.touch("tap:" + nstr(normalized([(x, y, z)])[0]))

    def double_tap_world(self, x, y, z=0):
        self.touch("double_tap:" + nstr(normalized([(x, y, z)])[0]))

    def drag_world(self, a, b, hold=0.3):
        p, q = normalized([a, b])
        self.touch(f"drag:{nstr(p)};{nstr(q)};{hold}")


def run_take(name, script, take_fn, out=None):
    out = out or os.path.join(S, "take-" + name)
    os.makedirs(out, exist_ok=True)
    durations = synthesize(name, script)
    udid = udid_for()
    simctl("terminate", udid, BUNDLE, check=False)
    control = Control()
    test = start_test(udid, os.path.join(out, "xcodebuild.log"))
    control.wait_event("ready", 900)
    time.sleep(3.0)
    rec = Recorder(udid)
    rec.start(os.path.join(out, "raw.mp4"))
    tl = Timeline(durations)
    try:
        take_fn(Take(control, tl))
        tl.dump(os.path.join(out, "timeline.json"))
    finally:
        # a failed take must not leave recordVideo or the test running: the
        # next take's recorder and test would fail to start on this device
        rec.stop()
        control.finish()
        try:
            test.wait(timeout=120)
        except subprocess.TimeoutExpired:
            test.kill()
        control.server.shutdown()
    log(f"take length {tl.now():.1f}s -> {out}")
    return out


# ---- compose ------------------------------------------------------------------------

W, H = 1920, 1080
VW = 1440
TITLE_S, OUTRO_S = 5.0, 8.0
BG, PANEL, FG, MUTED, ACCENT = (16, 19, 24), (22, 26, 33), (240, 242, 246), (150, 158, 172), (56, 142, 245)


def font(size, bold=False):
    from PIL import ImageFont
    return ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", size, index=1 if bold else 0)


def mono(size, bold=False):
    from PIL import ImageFont
    return ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", size, index=1 if bold else 0)


CODE_BG, CODE_FG, CODE_DIM, CODE_OK = (11, 13, 17), (214, 222, 235), (120, 130, 146), (126, 211, 140)


def code_block(d, x, y, w, lines, size=17):
    """A terminal-style box. A line starting with "# " is dimmed, "✓ " is green, "> " is accent."""
    lh = int(size * 1.45)
    h = lh * len(lines) + 28
    d.rounded_rectangle([x, y, x + w, y + h], radius=10, fill=CODE_BG + (255,), outline=(40, 46, 56, 255))
    ty = y + 14
    for line in lines:
        colour = CODE_DIM if line.startswith("# ") else CODE_OK if line.startswith("✓ ") else ACCENT if line.startswith("> ") else CODE_FG
        d.text((x + 16, ty), line, font=mono(size, line.startswith("> ")), fill=colour)
        ty += lh
    return y + h


def icon(size):
    from PIL import Image, ImageDraw
    im = Image.open(ICON).convert("RGBA").resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * 0.22), fill=255)
    im.putalpha(mask)
    return im


def wrap(draw, text, f, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=f) <= width:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur:
        lines.append(cur)
    return lines


def panel_png(i, n, seg, series, path):
    from PIL import Image, ImageDraw
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x0, pad = VW, 36
    d.rectangle([x0, 0, W, H], fill=PANEL + (255,))
    d.rectangle([x0, 0, x0 + 2, H], fill=(40, 46, 56, 255))
    im.alpha_composite(icon(44), (x0 + pad, 40))
    d.text((x0 + pad + 58, 46), "OpenShape 3D", font=font(26, True), fill=FG)
    d.text((x0 + pad + 58, 76), series, font=font(18), fill=MUTED)
    y = 170
    d.rectangle([x0 + pad, y, x0 + pad + 46, y + 5], fill=ACCENT + (255,))
    y += 26
    for line in wrap(d, seg["title"], font(42, True), W - x0 - 2 * pad):
        d.text((x0 + pad, y), line, font=font(42, True), fill=FG); y += 50
    y += 6
    for line in wrap(d, seg["sub"], font(26), W - x0 - 2 * pad):
        d.text((x0 + pad, y), line, font=font(26), fill=MUTED); y += 33
    y += 34
    for item in seg["lines"]:
        d.ellipse([x0 + pad, y + 11, x0 + pad + 9, y + 20], fill=ACCENT + (255,))
        for line in wrap(d, item, font(25), W - x0 - 2 * pad - 26):
            d.text((x0 + pad + 26, y), line, font=font(25), fill=FG); y += 32
        y += 12
    if seg.get("code"):
        code_block(d, x0 + pad - 16, y + 10, W - x0 - 2 * pad + 32, seg["code"], size=17)
    d.text((x0 + pad, H - 90), f"{i + 1} / {n}", font=font(20), fill=MUTED)
    bw = W - x0 - 2 * pad
    d.rectangle([x0 + pad, H - 56, x0 + pad + bw, H - 52], fill=(45, 51, 62, 255))
    d.rectangle([x0 + pad, H - 56, x0 + pad + int(bw * (i + 1) / n), H - 52], fill=ACCENT + (255,))
    im.save(path)


def hero_card(title, sub, foot, hero, path):
    """Title card with the finished model: text on the left, the render on the right."""
    from PIL import Image, ImageDraw
    im = Image.new("RGB", (W, H), BG)
    shot = Image.open(hero).convert("RGB")
    s = H / shot.height
    shot = shot.resize((int(shot.width * s), H), Image.LANCZOS)
    x0 = W - shot.width + int(shot.width * 0.1)
    im.paste(shot, (x0, 0))
    # fade the render into the background towards the text column
    fade = Image.new("L", (W, H), 0)
    fd = ImageDraw.Draw(fade)
    for x in range(W):
        fd.line([(x, 0), (x, H)], fill=max(0, min(255, int(255 * (1.0 - (x - x0) / 420)))))
    im = Image.composite(Image.new("RGB", (W, H), BG), im, fade)
    d = ImageDraw.Draw(im)
    ic = icon(120)
    im.paste(ic, (110, 250), ic)
    y = 410
    f = font(84, True)
    for line in wrap(d, title, f, 800):
        d.text((110, y), line, font=f, fill=FG); y += 96
    y += 10
    f = font(40)
    for line in wrap(d, sub, f, 800):
        d.text((110, y), line, font=f, fill=MUTED); y += 52
    y += 30
    for line in foot:
        d.text((110, y), line, font=font(30), fill=ACCENT); y += 42
    im.save(path)


def card(title, sub, foot, path, big=True, hero=None):
    from PIL import Image, ImageDraw
    if hero:
        return hero_card(title, sub, foot, hero, path)
    glow = Image.new("RGB", (W, H), BG)
    gd = ImageDraw.Draw(glow)
    for r in range(600, 0, -20):
        a = int(18 * (1 - r / 600))
        gd.ellipse([W // 2 - r, H // 2 - r + 40, W // 2 + r, H // 2 + r + 40], fill=(16 + a, 19 + a * 2, 24 + a * 4))
    im, d = glow, ImageDraw.Draw(glow)
    ic = icon(200 if big else 140)
    y = 200 if big else 240
    im.paste(ic, ((W - ic.width) // 2, y), ic)
    y += ic.height + 40
    f = font(88 if big else 72, True)
    for line in wrap(d, title, f, W - 200):
        d.text(((W - d.textlength(line, font=f)) // 2, y), line, font=f, fill=FG); y += (100 if big else 90)
    f = font(44)
    d.text(((W - d.textlength(sub, font=f)) // 2, y), sub, font=f, fill=MUTED); y += 70
    f = font(28)
    for line in foot:
        d.text(((W - d.textlength(line, font=f)) // 2, y), line, font=f, fill=ACCENT); y += 40
    im.save(path)


def run(args):
    print(" ".join(a if " " not in a else repr(a) for a in args[:10]), "…", flush=True)
    subprocess.run(args, check=True)


def music_bed(path, seconds=900):
    """Three Chillwave "Dream State" Apple Loops (10.1 s, same key) layered and looped."""
    if os.path.exists(path):
        return path
    ins = []
    for stem in ("Dream State Guitar", "Dream State Bass", "Dream State Synth"):
        ins += ["-stream_loop", "-1", "-i", os.path.join(LOOPS, stem + ".caf")]
    run(["ffmpeg", "-y", "-loglevel", "error", *ins, "-filter_complex",
         "[0:a][1:a][2:a]amix=inputs=3:normalize=0,volume=0.5[a]", "-map", "[a]",
         "-t", str(seconds), "-ar", "48000", "-ac", "2", path])
    return path


def compose(name, script, take_dir, video, out_path, series):
    """take_dir/raw.mp4 + timeline.json → out_path (1920×1080, narrated)."""
    tl = json.load(open(os.path.join(take_dir, "timeline.json")))
    build = os.path.join(take_dir, "build")
    os.makedirs(build, exist_ok=True)
    starts = {s["id"]: s for s in tl["segments"]}
    total = tl["total"]
    n = len(script)
    overlays = []
    for i, seg in enumerate(script):
        p = os.path.join(build, f"panel-{i:02d}.png")
        panel_png(i, n, seg, series, p)
        t = starts[seg["id"]]
        marks = t.get("marks", []) if seg.get("steps") else []
        overlays.append((p, t["start"], marks[0] if marks else t["end"]))
        # one panel per marked sub-step (a tool call), each until the next mark
        for k, at in enumerate(marks):
            if k >= len(seg["steps"]):
                break
            p = os.path.join(build, f"panel-{i:02d}-{k:02d}.png")
            panel_png(i, n, dict(seg, code=seg["steps"][k]), series, p)
            overlays.append((p, at, marks[k + 1] if k + 1 < min(len(marks), len(seg["steps"])) else t["end"]))
        # a full-frame slide (VW×H PNG) hides the recording for this segment
        if seg.get("slide"):
            overlays.append((seg["slide"], t["start"], t["end"]))
    card(video["title_card"], video["title_sub"], [video.get("title_foot", "Free, open-source solid modeling for iPad")],
         os.path.join(build, "title.png"), hero=video.get("hero"))
    card("Thanks for watching", "github.com/laanlabs/openshape3d",
         ["Free · open source · no account", video.get("outro_foot", "Subscribe for the next tutorial")],
         os.path.join(build, "outro.png"), big=False)
    raw = os.path.join(take_dir, "raw.mp4")
    # Exactly one panel (plus at most one slide) shows at any moment, so the
    # overlays are flattened into ONE image track (concat demuxer, a still per
    # interval) — a filter per panel made ffmpeg crawl once a video had ~50.
    from PIL import Image
    cuts = sorted({0.0, total} | {min(max(t, 0.0), total) for _, a, b in overlays for t in (a, b)})
    with open(os.path.join(build, "overlay.txt"), "w") as f:
        last = None
        for k, (a, b) in enumerate(zip(cuts, cuts[1:])):
            if b - a < 1e-3:
                continue
            frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            for p, start, end in overlays:
                if start <= a + 1e-6 and end >= b - 1e-6:
                    layer = Image.open(p).convert("RGBA")
                    frame.alpha_composite(layer, (0, 0))
            last = os.path.join(build, f"overlay-{k:03d}.png")
            frame.save(last)
            f.write(f"file '{last}'\nduration {b - a:.3f}\n")
        f.write(f"file '{last}'\n")              # the demuxer needs the last file repeated
    fc = [f"[0:v]transpose=2,tpad=stop_mode=clone:stop_duration=30,fps=30,"
          f"scale={VW}:{H}:force_original_aspect_ratio=decrease:flags=lanczos,"
          f"pad={W}:{H}:0:(oh-ih)/2:color=0x{BG[0]:02x}{BG[1]:02x}{BG[2]:02x}[base]",
          "[1:v]fps=30,format=rgba[panels]",
          "[base][panels]overlay=0:0:eof_action=repeat[o]",
          f"[o]format=yuv420p,fade=t=in:st=0:d=0.6,fade=t=out:st={total - 0.8:.2f}:d=0.8[v]"]
    args = ["ffmpeg", "-y", "-loglevel", "error", "-i", raw,
            "-f", "concat", "-safe", "0", "-i", os.path.join(build, "overlay.txt"),
            "-filter_complex", ";".join(fc), "-map", "[v]", "-t", f"{total:.2f}",
            "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-r", "30", "-an", os.path.join(build, "main.mp4")]
    run(args)
    for card_name, dur in (("title", TITLE_S), ("outro", OUTRO_S)):
        run(["ffmpeg", "-y", "-loglevel", "error", "-loop", "1", "-i", os.path.join(build, card_name + ".png"),
             "-t", str(dur), "-vf", f"fps=30,format=yuv420p,fade=t=in:st=0:d=0.8,fade=t=out:st={dur - 0.8}:d=0.8",
             "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-r", "30", "-an", os.path.join(build, card_name + ".mp4")])
    with open(os.path.join(build, "concat.txt"), "w") as f:
        for part in ("title", "main", "outro"):
            f.write(f"file '{os.path.join(build, part + '.mp4')}'\n")
    run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", os.path.join(build, "concat.txt"),
         "-c", "copy", os.path.join(build, "video.mp4")])
    full = TITLE_S + total + OUTRO_S
    bed = music_bed(os.path.join(S, "music-bed.wav"))
    ins = ["ffmpeg", "-y", "-loglevel", "error", "-i", os.path.join(build, "video.mp4"), "-i", bed]
    af, mixes = [], []
    for k, seg in enumerate(script):
        ins += ["-i", seg["_clip"]]
        off = int((TITLE_S + starts[seg["id"]]["start"] + 0.35) * 1000)
        af.append(f"[{k + 2}:a]aformat=sample_rates=48000:channel_layouts=stereo,adelay={off}|{off}[n{k}]")
        mixes.append(f"[n{k}]")
    af.append(f"{''.join(mixes)}amix=inputs={len(mixes)}:normalize=0:dropout_transition=0,loudnorm=I=-16:TP=-1.5:LRA=11[voice]")
    quiet_to = TITLE_S + total
    af.append(f"[1:a]atrim=0:{full:.2f},volume='if(lt(t,{TITLE_S}),0.9,if(gt(t,{quiet_to:.2f}),0.9,0.28))':eval=frame,"
              f"afade=t=in:st=0:d=1.5,afade=t=out:st={full - 3:.2f}:d=3[music]")
    af.append("[voice][music]amix=inputs=2:normalize=0:duration=longest,alimiter=limit=0.95[a]")
    ins += ["-filter_complex", ";".join(af), "-map", "0:v", "-map", "[a]", "-t", f"{full:.2f}",
            "-c:v", "copy", "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-movflags", "+faststart", out_path]
    run(ins)
    log(f"wrote {out_path} ({full:.0f} s)")
    return full


def write_metadata(path, video, script, take_dir):
    tl = json.load(open(os.path.join(take_dir, "timeline.json")))
    starts = {s["id"]: s["start"] for s in tl["segments"]}
    chapters = ["0:00 Intro"]
    seen = {"Intro"}
    for seg in script:
        label = seg.get("chapter")
        if not label or label in seen:
            continue
        seen.add(label)
        t = int(TITLE_S + starts[seg["id"]])
        chapters.append(f"{t // 60}:{t % 60:02d} {label}")
    desc = video["description"].strip() + "\n\nChapters\n" + "\n".join(chapters) + "\n\n" + video["footer"].strip()
    with open(path, "w") as f:
        f.write(f"# {video['title']}\n\n")
        f.write(f"**Title ({len(video['title'])} chars):** {video['title']}\n\n")
        f.write("## Description\n\n```\n" + desc + "\n```\n\n")
        f.write("## Tags\n\n```\n" + ", ".join(video["tags"]) + "\n```\n\n")
        f.write("## Thumbnail text\n\n" + video["thumb"] + "\n")
    log(f"wrote {path}")
    return desc
