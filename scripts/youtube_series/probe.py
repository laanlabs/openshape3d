#!/usr/bin/env python3
"""Probe the touch flows on the video simulator; screenshots + state per step."""
import json, os, subprocess, sys, time
from common import *
from PIL import Image

SCR = sys.argv[1]
udid = udid_for()
simctl("terminate", udid, BUNDLE, check=False)
control = Control()
test = start_test(udid, os.path.join(SCR, "probe-xcodebuild.log"))
control.wait_event("ready", 900)
t = Take(control, None)

def shot(tag):
    p = os.path.join(SCR, f"probe-{tag}.png")
    simctl("io", udid, "screenshot", p)
    im = Image.open(p)
    print("shot", tag, im.size, flush=True)
    return p

def sk():
    r = call("/v1/sketches")
    for s in r.get("sketches", []):
        print("  sketch", s.get("name"), "normal", s.get("plane", {}).get("normal"), "entities", len(s.get("entities", [])), flush=True)
        for e in s.get("entities", [])[:6]:
            print("    ", json.dumps(e)[:160], flush=True)

steps = sys.argv[2:] or ["all"]
t.touch("new_design"); wait_document(); time.sleep(1.5)
shot("01-new")
print("mode", state().get("mode"), flush=True)
t.touch("sketch_tool:Rect"); time.sleep(1.5)
shot("02-rect-tool")
print("mode", state().get("mode"), flush=True)
# ground plane tile: try the projection of a point just off the origin on the ground
t.tap_world(1.0, 0, 1.0); time.sleep(2.5)
shot("03-plane")
print("mode", state().get("mode"), flush=True); sk()
t.drag_world((-20, 0, -12), (20, 0, 12)); time.sleep(1.5)
shot("04-rect")
print("mode", state().get("mode"), "sel", state().get("selectedSketchEntities"), flush=True); sk()
t.tap_world(0, 0, -12); time.sleep(1.2)
shot("05-select-edge")
print("mode", state().get("mode"), "sel", state().get("selectedSketchEntities"), flush=True)
print("dimlabel", t.touch("exists:DimensionLabel"), flush=True)
print("dimension", t.touch("dimension:40"), flush=True); time.sleep(1.5)
shot("06-dimension"); sk()
print("circle tool", t.touch("palette_label:Sketch/Circle"), flush=True); time.sleep(1.0)
t.drag_world((-12, 0, 0), (-9, 0, 0)); time.sleep(1.5)
shot("07-circle"); sk()
print("exit", t.touch("button:Exit Sketching"), flush=True); time.sleep(1.5)
shot("08-exit")
print("mode", state().get("mode"), flush=True)
control.finish()
try: test.wait(timeout=60)
except subprocess.TimeoutExpired: test.kill()
