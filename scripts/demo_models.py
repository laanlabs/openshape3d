#!/usr/bin/env python3
"""Bake the bundled sample designs (openshape3d/Demos/*.os3d) from a live app.

Each sample is built in its own fresh design over the agent bridge — the same
scene recipes the App Store screenshots use (scripts/marketing_scenes.py) plus
the cycloidal cam — then pulled back as a `.os3d` archive with
`GET /v1/archive` and a 512 px viewport PNG for the welcome screen. The app
keeps the feature history, so a sample opens fully editable.

    scripts/demo_models.py [--udid UDID] [--app PATH] [wheel|plate|bottle|cam …]

Needs a DEBUG build installed on the simulator (`xcodebuild build …` then
`simctl install`); the script launches it once per sample with OS3D_FRESH and
OS3D_AGENT on port 8899, and terminates it afterwards. Re-run after a change
to the archive format, and check the volumes it prints against the recipes'
own expectations (rebuild_*.py) before committing the new files.
"""

import argparse, os, subprocess, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "openshape3d", "Demos")
BUNDLE = "com.laan.labs.openshape3d"
PORT = os.environ.setdefault("OS3D_PORT", "8899")
BASE = f"http://127.0.0.1:{PORT}"

sys.path.insert(0, HERE)
import marketing_scenes as scenes  # noqa: E402  (reads OS3D_PORT at import)

# id (file name) -> (design name, scene)
SAMPLES = {
    "wheel":  ("Motorcycle Wheel", "wheel"),
    "plate":  ("Mounting Plate",   "plate"),
    "bottle": ("Glass Bottle",     "bottle"),
    "cam":    ("Plate Cam",        "cam"),
}
FILE_IDS = {"wheel": "motorcycle-wheel", "plate": "mounting-plate",
            "bottle": "glass-bottle", "cam": "plate-cam"}


def cam():
    scenes.rebuild("rebuild_cycloidal_cam.py")
    scenes.paint([b["id"] for b in scenes.bodies()],
                 color=[0.86, 0.60, 0.22], metallic=0.6, roughness=0.35)
    scenes.finish()


def simctl(*args, env=None):
    return subprocess.run(["xcrun", "simctl", *args], check=True, env=env,
                          capture_output=True, text=True)


def find_udid():
    out = simctl("list", "devices", "available").stdout
    for name in ("iPad Pro 13-inch (M5)", "iPad Pro 11-inch (M5)"):
        for line in out.splitlines():
            if name + " (" in line:
                return line.split("(")[1].split(")")[0]
    sys.exit("no iPad simulator available")


def wait_health(seconds=40):
    for _ in range(seconds * 2):
        try:
            if urllib.request.urlopen(BASE + "/v1/health", timeout=1).status == 200:
                return
        except Exception:
            time.sleep(0.5)
    sys.exit("the app never answered on the bridge")


def fetch(path):
    return urllib.request.urlopen(BASE + path, timeout=300).read()


def bake(key, udid):
    name, scene = SAMPLES[key]
    env = dict(os.environ, SIMCTL_CHILD_OS3D_AGENT="1", SIMCTL_CHILD_OS3D_AGENT_PORT=PORT,
               SIMCTL_CHILD_OS3D_FRESH="1", SIMCTL_CHILD_OS3D_FRESH_NAME=name)
    subprocess.run(["xcrun", "simctl", "terminate", udid, BUNDLE], capture_output=True)
    simctl("launch", udid, BUNDLE, env=env)
    wait_health()
    print(f"== {name}")
    (cam if scene == "cam" else getattr(scenes, scene))()
    time.sleep(1.5)  # let the fit animation settle before the thumbnail
    fid = FILE_IDS[key]
    os.makedirs(OUT, exist_ok=True)
    archive = fetch("/v1/archive")
    with open(os.path.join(OUT, fid + ".os3d"), "wb") as f:
        f.write(archive)
    with open(os.path.join(OUT, fid + "-thumb.png"), "wb") as f:
        f.write(fetch("/v1/screenshot?w=512&h=512"))
    print(f"   wrote {fid}.os3d ({len(archive) / 1024:.0f} KB) + thumbnail")
    subprocess.run(["xcrun", "simctl", "terminate", udid, BUNDLE], capture_output=True)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--udid")
    ap.add_argument("samples", nargs="*", default=list(SAMPLES))
    a = ap.parse_args()
    udid = a.udid or find_udid()
    for key in a.samples:
        if key not in SAMPLES:
            sys.exit(f"unknown sample {key}; choose from {', '.join(SAMPLES)}")
        bake(key, udid)
