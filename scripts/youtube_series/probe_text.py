"""Which way does a sketch on a picked face point? Plate A: ground sketch
extruded +3. Plate B: sketch at y=3 extruded -3. Pick each top face with the
Text tool armed and read the new sketch's plane axes."""
import json, time
from common import *
udid = udid_for()
simctl("terminate", udid, BUNDLE, check=False)
c = Control()
test = start_test(udid, os.path.join(S, "probe_text.xcodebuild.log"))
c.wait_event("ready", 900); time.sleep(2)
t = Take(c, None)
try:
    t.touch("new_design"); wait_document(); time.sleep(1.5)
    s = X("sketch.create", {"name": "A", "origin": [0, 0, 0], "xAxis": [1, 0, 0], "yAxis": [0, 0, -1]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s, "entities": [{"kind": "rect", "min": [-30, -10], "max": [30, 10]}]})
    X("feature.extrude", {"sketchID": s, "seedPoint": [0, 0], "distance": 3})
    s = X("sketch.create", {"name": "B", "origin": [0, 3, 40], "xAxis": [1, 0, 0], "yAxis": [0, 0, -1]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s, "entities": [{"kind": "rect", "min": [-30, -10], "max": [30, 10]}]})
    X("feature.extrude", {"sketchID": s, "seedPoint": [0, 0], "distance": -3})
    X("item.setHidden", {"allSketches": True})
    for label, pt in (("A", (4, 3, -7)), ("B", (4, 3, 33))):
        cmd("view.top", 0.8); cmd("view.fit", 1.2)
        before = {k["id"] for k in call("/v1/sketches")["sketches"]}
        t.touch("sketch_tool:Text"); time.sleep(1.5)
        t.tap_world(*pt); time.sleep(2.0)
        new = [k for k in call("/v1/sketches")["sketches"] if k["id"] not in before]
        print(label, json.dumps([k["plane"] for k in new]), "mode", state().get("mode"), flush=True)
        t.touch("button:Exit Sketching"); time.sleep(1.0)
finally:
    c.finish()
    try: test.wait(timeout=60)
    except Exception: test.kill()
    c.server.shutdown()
