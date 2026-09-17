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
t.touch("new_design"); wait_document(); time.sleep(2.5)
t.touch("sketch_tool:Rect"); time.sleep(1.5)
r = call("/v1/project?points=0,0,0;1,0,1;5,0,0;0,0,5;0,5,0")
print("proj", r, flush=True)
p = os.path.join(SCR, "probe-21-pick.png"); simctl("io", udid, "screenshot", p)
im = Image.open(p); print("raw", im.size, flush=True)
im = im.transpose(Image.ROTATE_90); im.thumbnail((1376, 1376)); im.save(p)
control.finish()
try: test.wait(timeout=60)
except subprocess.TimeoutExpired: test.kill()
