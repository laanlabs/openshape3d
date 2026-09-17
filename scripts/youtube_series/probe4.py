import json, os, subprocess, sys, time
from common import *
from PIL import Image
SCR = sys.argv[1]
udid = udid_for(); simctl("terminate", udid, BUNDLE, check=False)
control = Control(); test = start_test(udid, os.path.join(SCR, "probe-xcodebuild.log")); control.wait_event("ready", 900)
t = Take(control, None)
def shot(tag):
    p = os.path.join(SCR, f"probe-{tag}.png"); simctl("io", udid, "screenshot", p)
    im = Image.open(p).transpose(Image.ROTATE_90); im.thumbnail((1000, 1000)); im.save(p)
def ents(): return call("/v1/sketches")["sketches"][0]["entities"]
t.touch("new_design"); wait_document(); time.sleep(2.5)
t.touch("sketch_tool:Rect"); time.sleep(1.5)
for attempt in range(3):
    t.tap_world(1.0, 0, 1.0); time.sleep(2.5)
    if state().get("mode") == "sketching": break
print("pinch", t.touch("pinch:0.2"), flush=True); time.sleep(1.5); shot("41-pinched")
print("proj of 20,0,0:", call("/v1/project?points=20,0,0;-20,0,0")["points"], flush=True)
t.touch("drag:0.35,0.38;0.65,0.62;0.3"); time.sleep(1.2)
print("rect", json.dumps(ents())[:200], "sel", state().get("selectedSketchEntities"), flush=True)
print("dimlabel", t.touch("exists:DimensionLabel"), flush=True)
shot("42-drawn")
print("dimension", t.touch("dimension:40"), flush=True); time.sleep(1.5)
print("rect after", json.dumps(ents())[:200], flush=True); shot("43-dim")
control.finish()
try: test.wait(timeout=60)
except subprocess.TimeoutExpired: test.kill()
