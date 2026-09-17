#!/usr/bin/env python3
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
    p = os.path.join(SCR, f"probe-{tag}.png"); simctl("io", udid, "screenshot", p)
    im = Image.open(p).transpose(Image.ROTATE_90); im.thumbnail((1100, 1100)); im.save(p)
def st(): s = state(); print("mode", s.get("mode"), "sel", s.get("selectedSketchEntities"), "bodies", len(s.get("bodies", [])), flush=True)
t.touch("new_design"); wait_document(); time.sleep(2.5)
t.touch("sketch_tool:Rect"); time.sleep(1.5)
for attempt in range(3):
    t.tap_world(1.0, 0, 1.0); time.sleep(2.5)
    if state().get("mode") == "sketching": break
    print("plane pick missed, retry", flush=True)
t.touch("drag:0.38,0.40;0.62,0.62;0.3"); time.sleep(1.5)
shot("11-rect"); st()
sks = call("/v1/sketches"); print(json.dumps(sks)[:900], flush=True)
sk0 = sks["sketches"][0]; ents = sk0["entities"]; rect = [e for e in ents if e["kind"] == "rect"][0]
plane = sk0["plane"]
def world(u, v):
    o, xa, ya = plane["origin"], plane["xAxis"], plane["yAxis"]
    return tuple(o[i] + xa[i] * u + ya[i] * v for i in range(3))
mx = (rect["min"][0] + rect["max"][0]) / 2; my = (rect["min"][1] + rect["max"][1]) / 2
t.tap_world(*world(mx, rect["min"][1])); time.sleep(1.2)
shot("12-select"); st()
print("dimlabel", t.touch("exists:DimensionLabel"), flush=True)
print("dimension", t.touch("dimension:40"), flush=True); time.sleep(1.5)
shot("13-dim"); print(json.dumps(call("/v1/sketches")["sketches"][0]["entities"])[:400], flush=True)
cmd("view.fit", 1.5); shot("13b-fit")
print("circle tool", t.touch("palette_label:Sketch/Circle"), flush=True); time.sleep(1.0)
t.touch("drag:0.30,0.50;0.34,0.50;0.3"); time.sleep(1.5)
shot("14-circle"); print(json.dumps([e for e in call("/v1/sketches")["sketches"][0]["entities"] if e.get("kind") == "circle"])[:300], flush=True)
print("exit", t.touch("button:Exit Sketching"), flush=True); time.sleep(1.5); st()
sk_id = sk0["id"]
rect2 = [e for e in call("/v1/sketches")["sketches"][0]["entities"] if e["kind"] == "rect"][0]
seed = [(rect2["min"][0] + rect2["max"][0]) / 2 + 0.3, (rect2["min"][1] + rect2["max"][1]) / 2 + 0.3]
r = X("feature.extrude", {"sketchID": sk_id, "seedPoint": seed, "distance": 6}); body = r["producedBodyIDs"][0]
time.sleep(1.0); cmd("view.isometric", 1.0); cmd("view.fit", 1.5); shot("15-extrude"); st()
b = [x for x in bodies() if x["id"] == body][0]; print("body keys", list(b.keys()), flush=True)
bb = b.get("bounds"); print("bounds", bb, flush=True)
mn, mx_ = (bb["min"], bb["max"]) if isinstance(bb, dict) else (bb[0], bb[1])
center = [(mn[i] + mx_[i]) / 2 for i in range(3)]
t.double_tap_world(center[0], mx_[1], center[2]); time.sleep(1.2); st(); shot("16-selected")
print("material", t.touch("palette:Modify/Material"), flush=True); time.sleep(1.2); shot("17-material")
print("apply exists", t.touch("exists:MaterialApply"), flush=True)
print("preset", t.touch("button:MaterialPresetBrass"), flush=True); time.sleep(0.8)
print("apply", t.touch("button:MaterialApply"), flush=True); time.sleep(1.2); shot("18-applied")
print(json.dumps(bodies()[0].get("material"))[:200], flush=True)
control.finish()
try: test.wait(timeout=60)
except subprocess.TimeoutExpired: test.kill()
