#!/usr/bin/env python3
"""Record, compose and write metadata for one tutorial.

    tutorial.py sketching|shapes|materials [--compose-only] [--take-only]
"""
import argparse, json, os, sys, time
from common import *
from scripts_text import VIDEOS


def plane_of(sketch):
    o, xa, ya = sketch["plane"]["origin"], sketch["plane"]["xAxis"], sketch["plane"]["yAxis"]
    return lambda u, v: tuple(o[i] + xa[i] * u + ya[i] * v for i in range(3))


def sketch0():
    return call("/v1/sketches")["sketches"][0]


def pick_ground_plane(t):
    for _ in range(3):
        t.tap_world(1.0, 0, 1.0); time.sleep(2.4)
        if state().get("mode") == "sketching":
            return True
        log("plane pick missed, retrying")
    return False


# ---- 1. sketching -----------------------------------------------------------------

def take_sketching(t):
    tl = t.tl
    tl.begin("intro"); time.sleep(1.2); tl.hold(0.2)
    tl.begin("planes")
    t.touch("new_design"); wait_document(); time.sleep(2.0)
    t.touch("sketch_tool:Rect"); time.sleep(2.0)
    pick_ground_plane(t)
    tl.hold(0.3)
    tl.begin("rectangle")
    time.sleep(1.5)
    t.touch("drag:0.33,0.36;0.66,0.62;0.4"); time.sleep(0.8)
    sk = sketch0(); W = plane_of(sk)
    rect = [e for e in sk["entities"] if e["kind"] == "rect"]
    tl.hold(0.3)
    tl.begin("dimension")
    time.sleep(2.0)
    r = t.touch("dimension:40"); time.sleep(1.2)
    if r == "done":
        t.touch("dimension:24@1"); time.sleep(1.0)
    cmd("view.fit", 1.6)
    tl.hold(0.3)
    tl.begin("circles")
    time.sleep(1.0)
    sk = sketch0(); W = plane_of(sk)
    rect = [e for e in sk["entities"] if e["kind"] == "rect"][0]
    cx = (rect["min"][0] + rect["max"][0]) / 2; cy = (rect["min"][1] + rect["max"][1]) / 2
    sx = (rect["max"][0] - rect["min"][0]) / 40.0           # scale in case the typed size did not land
    t.touch("palette_label:Sketch/Circle"); time.sleep(0.8)
    for dx in (-12, 12):
        c = (cx + dx * sx, cy)
        t.drag_world(W(*c), W(c[0] + 3 * sx, c[1]), hold=0.35); time.sleep(0.9)
    tl.hold(0.3)
    tl.begin("lines_arcs")
    time.sleep(1.0)
    ox = rect["max"][0] + 14 * sx
    import math
    X("sketch.addEntities", {"sketchID": sk["id"], "entities": [
        {"kind": "line", "a": [ox, cy - 10 * sx], "b": [ox + 12 * sx, cy - 10 * sx]},
        {"kind": "line", "a": [ox + 12 * sx, cy - 10 * sx], "b": [ox + 12 * sx, cy - 2 * sx]},
        {"kind": "line", "a": [ox + 12 * sx, cy - 2 * sx], "b": [ox, cy - 4 * sx]},
    ]}); time.sleep(1.2)
    X("sketch.addEntities", {"sketchID": sk["id"], "entities": [
        {"kind": "arc", "center": [ox + 6 * sx, cy + 4 * sx], "radius": 6 * sx, "startAngle": 0, "endAngle": math.pi}]}); time.sleep(1.2)
    X("sketch.addEntities", {"sketchID": sk["id"], "entities": [
        {"kind": "polygon", "center": [ox + 22 * sx, cy - 6 * sx], "radius": 5 * sx, "sides": 6}]}); time.sleep(1.0)
    X("sketch.addEntities", {"sketchID": sk["id"], "entities": [
        {"kind": "ellipse", "center": [ox + 22 * sx, cy + 6 * sx], "radiusX": 6 * sx, "radiusY": 3.5 * sx}]}); time.sleep(1.0)
    X("sketch.addEntities", {"sketchID": sk["id"], "entities": [
        {"kind": "spline", "points": [[ox + 30 * sx, cy - 10 * sx], [ox + 34 * sx, cy - 3 * sx], [ox + 31 * sx, cy + 4 * sx], [ox + 36 * sx, cy + 10 * sx]], "closed": False}]})
    time.sleep(0.5); cmd("view.fit", 1.4)
    tl.hold(0.3)
    tl.begin("constraints")
    time.sleep(1.0)
    # a slightly tilted line, selected by touch and made horizontal from the panel
    ty = cy - 16 * sx
    X("sketch.addEntities", {"sketchID": sk["id"], "entities": [
        {"kind": "line", "a": [cx - 14 * sx, ty], "b": [cx + 14 * sx, ty + 3 * sx]}]}); time.sleep(0.8)
    t.tap_world(*W(cx, ty + 1.5 * sx)); time.sleep(1.4)
    t.touch("button:Horizontal"); time.sleep(1.2)
    tl.hold(0.3)
    tl.begin("editing")
    time.sleep(1.0)
    t.tap_world(*W(ox + 22 * sx + 5 * sx, cy - 6 * sx)); time.sleep(1.0)     # the hexagon's right corner
    cmd("edit.delete", 1.2)
    cmd("edit.undo", 1.2)
    t.tap_world(*W(cx, cy - 20 * sx)); time.sleep(0.5)                        # empty spot: deselect
    tl.hold(0.3)
    tl.begin("profiles")
    time.sleep(0.5); cmd("view.fit", 1.0)
    tl.hold(0.3)
    tl.begin("extrude")
    t.touch("button:Exit Sketching"); time.sleep(1.6)
    cmd("view.isometric", 1.4)
    r = X("feature.extrude", {"sketchID": sk["id"], "seedPoint": [cx + 6 * sx, cy + 6 * sx], "distance": 6})
    time.sleep(0.8); cmd("view.fit", 1.2)
    tl.hold(0.4)
    tl.begin("outro")
    time.sleep(0.5)
    X("item.setHidden", {"allSketches": True}); time.sleep(0.5)
    cmd("view.front", 1.8); cmd("view.isometric", 1.4); cmd("view.fit", 0.4)
    tl.hold(1.0)


# ---- 2. shapes ----------------------------------------------------------------------

def take_shapes(t):
    tl = t.tl
    made = []                      # every body so far, for per-chapter framing

    def focus(*ids):
        """Show only these bodies and fit them; the row comes back at the end."""
        others = [b for b in made if b not in ids]
        if others:
            X("item.setHidden", {"ids": others, "hidden": True})
        X("item.setHidden", {"ids": list(ids), "hidden": False})
        cmd("view.fit", 1.2)

    def reveal():
        X("item.setHidden", {"ids": made, "hidden": False}); cmd("view.fit", 1.2)

    tl.begin("intro"); time.sleep(1.0)
    t.touch("new_design"); wait_document(); time.sleep(1.5)
    tl.hold(0.2)
    tl.begin("extrude")
    time.sleep(1.2)
    s1 = X("sketch.create", {"name": "Block"})["sketchID"]
    X("sketch.addEntities", {"sketchID": s1, "entities": [{"kind": "rect", "min": [-10, -10], "max": [10, 10]}]})
    cmd("view.isometric", 0.3); cmd("view.fit", 1.2)
    block = X("feature.extrude", {"sketchID": s1, "seedPoint": [0, 0], "distance": 12})["producedBodyIDs"][0]
    made.append(block); time.sleep(0.4); cmd("view.fit", 1.6)
    s2 = X("sketch.create", {"name": "Disc", "origin": [30, 0, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s2, "entities": [{"kind": "circle", "center": [0, 0], "radius": 8}]})
    time.sleep(0.6)
    cyl = X("feature.extrude", {"sketchID": s2, "seedPoint": [0, 0], "distance": 16})["producedBodyIDs"][0]
    made.append(cyl); time.sleep(0.3); cmd("view.fit", 1.4)
    s3 = X("sketch.create", {"name": "Taper", "origin": [58, 0, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s3, "entities": [{"kind": "polygon", "center": [0, 0], "radius": 9, "sides": 6}]})
    time.sleep(0.5)
    taper = X("feature.extrude", {"sketchID": s3, "seedPoint": [0, 0], "distance": 14, "taperDegrees": 12})["producedBodyIDs"][0]
    made.append(taper); time.sleep(0.3); cmd("view.fit", 1.2)
    X("item.setHidden", {"allSketches": True})
    tl.hold(0.3)
    tl.begin("revolve")
    time.sleep(0.8)
    s4 = X("sketch.create", {"name": "Handle", "origin": [90, 0, 0], "xAxis": [1, 0, 0], "yAxis": [0, 1, 0]})["sketchID"]
    prof = [[0, 0], [7, 0], [7, 3], [4, 5], [4, 12], [6, 15], [6, 20], [3, 24], [0, 24]]
    ents = [{"kind": "line", "a": prof[i], "b": prof[i + 1]} for i in range(len(prof) - 1)] + [{"kind": "line", "a": prof[-1], "b": prof[0]}]
    X("sketch.addEntities", {"sketchID": s4, "entities": ents})
    X("item.setHidden", {"ids": made, "hidden": True})
    cmd("view.front", 0.6); cmd("view.fit", 1.4)
    time.sleep(1.8)
    handle = X("feature.revolve", {"sketchID": s4, "seedPoint": [3, 10], "axisPoint": [0, 0], "axisDirection": [0, 1], "angleDegrees": 360})["producedBodyIDs"][0]
    made.append(handle); time.sleep(0.5); cmd("view.isometric", 0.8); cmd("view.fit", 1.2)
    X("item.setHidden", {"allSketches": True})
    tl.hold(0.3)
    tl.begin("sweep")
    time.sleep(0.6)
    import math
    s5 = X("sketch.create", {"name": "Tube profile", "origin": [120, 0, 0], "xAxis": [0, 0, 1], "yAxis": [0, 1, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s5, "entities": [{"kind": "circle", "center": [0, 0], "radius": 3}]})
    spine = [[120 + 25 * math.sin(a), 25 - 25 * math.cos(a), 0] for a in [i * math.pi / 2 / 16 for i in range(17)]]
    X("item.setHidden", {"ids": made, "hidden": True}); cmd("view.fit", 1.2)
    time.sleep(0.6)
    tube = X("feature.sweep", {"sketchID": s5, "seedPoint": [0, 0], "spine": spine})["producedBodyIDs"][0]
    made.append(tube); time.sleep(0.4); cmd("view.fit", 1.4)
    X("item.setHidden", {"allSketches": True})
    tl.hold(0.3)
    tl.begin("loft")
    time.sleep(0.6)
    s6 = X("sketch.create", {"name": "Loft base", "origin": [170, 0, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s6, "entities": [{"kind": "rect", "min": [-9, -9], "max": [9, 9]}]})
    s7 = X("sketch.create", {"name": "Loft top", "origin": [170, 22, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s7, "entities": [{"kind": "circle", "center": [0, 0], "radius": 5}]})
    X("item.setHidden", {"ids": made, "hidden": True}); cmd("view.fit", 1.4)
    time.sleep(1.2)
    loft = X("feature.loft", {"sections": [{"sketchID": s6, "seedPoint": [0, 0]}, {"sketchID": s7, "seedPoint": [0, 0]}]})["producedBodyIDs"][0]
    made.append(loft); time.sleep(0.4); cmd("view.fit", 1.2)
    X("item.setHidden", {"allSketches": True})
    tl.hold(0.3)
    tl.begin("booleans")
    focus(block)
    time.sleep(0.4)
    s8 = X("sketch.create", {"name": "Hole", "origin": [0, 12, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s8, "entities": [{"kind": "circle", "center": [0, 0], "radius": 4}]})
    time.sleep(1.2)
    X("feature.extrude", {"sketchID": s8, "seedPoint": [0, 0], "distance": -12, "boolean": "subtract", "booleanTargets": [block]})
    X("item.setHidden", {"allSketches": True}); time.sleep(1.8)
    focus(cyl)
    s9 = X("sketch.create", {"name": "Boss", "origin": [30, 16, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s9, "entities": [{"kind": "rect", "min": [-11, -3], "max": [11, 3]}]})
    time.sleep(1.0)
    X("feature.extrude", {"sketchID": s9, "seedPoint": [0, 0], "distance": 4, "boolean": "union", "booleanTargets": [cyl]})
    X("item.setHidden", {"allSketches": True}); time.sleep(0.4); cmd("view.fit", 1.0)
    tl.hold(0.3)
    tl.begin("fillet")
    focus(block)
    time.sleep(0.6)
    e = edges(block)
    vertical = [x["index"] for x in e if x.get("midpoint") and abs(x["lengthMM"] - 12) < 0.2 and abs(x["midpoint"][1] - 6) < 0.2]
    X("feature.fillet", {"bodyID": block, "radius": 3, "edges": vertical}); time.sleep(1.6)
    e = edges(block)
    top = [x["index"] for x in e if x.get("midpoint") and abs(x["midpoint"][1] - 12) < 0.2 and x["lengthMM"] > 8]
    X("feature.chamfer", {"bodyID": block, "setback": 1.5, "edges": top}); time.sleep(0.6)
    tl.hold(0.3)
    tl.begin("shell")
    focus(cyl)
    time.sleep(0.6)
    fs = faces(cyl)
    tops = [x["index"] for x in fs if x.get("kind") == "planar" and x.get("centroid") and x["centroid"][1] > 19]
    X("feature.shell", {"bodyID": cyl, "thickness": 1.5, "openFaces": tops[:1]}); time.sleep(0.6)
    cmd("view.top", 1.6); cmd("view.isometric", 1.2)
    tl.hold(0.3)
    tl.begin("pattern")
    focus(handle)
    time.sleep(0.4)
    s10 = X("sketch.create", {"name": "Peg", "origin": [90, 0, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": s10, "entities": [{"kind": "circle", "center": [12, 0], "radius": 2}]})
    peg = X("feature.extrude", {"sketchID": s10, "seedPoint": [12, 0], "distance": 8})["producedBodyIDs"][0]
    made.append(peg); X("item.setHidden", {"allSketches": True}); time.sleep(0.4); cmd("view.fit", 1.2)
    r = X("feature.pattern", {"bodyID": peg, "count": 6, "kind": "circular", "axis": [0, 1, 0], "center": [90, 0, 0]})
    made.extend(r.get("producedBodyIDs", [])); time.sleep(0.3); cmd("view.fit", 1.4)
    r = X("feature.mirror", {"bodyID": handle, "planeOrigin": [90, 0, -20], "planeNormal": [0, 0, 1]})
    made.extend(r.get("producedBodyIDs", [])); time.sleep(0.3); cmd("view.fit", 1.2)
    tl.hold(0.3)
    tl.begin("history")
    reveal()
    time.sleep(0.4)
    t.touch("toolbar:HistoryButton"); time.sleep(1.0)
    tl.hold(0.8)
    t.touch("toolbar:HistoryButton"); time.sleep(0.6)
    tl.begin("outro")
    cmd("view.front", 1.6); cmd("view.top", 1.6); cmd("view.isometric", 1.2); cmd("view.fit", 0.4)
    tl.hold(1.0)


# ---- 3. materials ---------------------------------------------------------------------

def take_materials(t):
    tl = t.tl
    DESELECT = "tap:0.14,0.9"          # empty grid, bottom-left of the viewport

    tl.begin("intro"); time.sleep(1.5); tl.hold(0.2)
    tl.begin("open")
    t.touch("add_samples"); time.sleep(1.5)
    t.touch("open_card:Motorcycle Wheel"); wait_document(); time.sleep(2.0)
    bs = bodies()
    rim = min(bs, key=lambda b: b["volumeMM3"]); tyre = max(bs, key=lambda b: b["volumeMM3"])
    # The wheel's axis is world X: the right view looks at the rim face-on.
    cmd("view.right", 1.8); cmd("view.fit", 0.9)
    bb = rim["bounds"]; cx, cy, cz = [(bb[0][i] + bb[1][i]) / 2 for i in range(3)]
    t.double_tap_world(cx, cy + 30, cz); time.sleep(1.0)      # the hub plate, clear of the bore
    tl.hold(0.3)
    tl.begin("sheet")
    time.sleep(0.8)
    t.touch("palette:Modify/Material"); time.sleep(2.0)
    tl.hold(-1.5)
    t.touch("button:Aluminum"); time.sleep(1.0)
    t.touch("button:MaterialApply"); time.sleep(1.0)
    t.touch(DESELECT); time.sleep(0.4)
    cmd("view.isometric", 1.4)
    tl.hold(0.3)
    tl.begin("presets")
    time.sleep(0.5)
    for name in ["Steel", "Aluminum", "Brass", "Plastic Matte", "Plastic Gloss", "Rubber", "Wood"]:
        X("body.setMaterial", {"bodyIDs": [rim["id"]], "preset": name}); time.sleep(2.2)
    X("body.setMaterial", {"bodyIDs": [rim["id"]], "preset": "Aluminum"})
    tl.hold(0.3)
    tl.begin("metallic")
    time.sleep(0.5)
    X("body.setMaterial", {"bodyIDs": [rim["id"]], "color": [0.83, 0.85, 0.87], "metallic": 0, "roughness": 0.3}); time.sleep(4.0)
    X("body.setMaterial", {"bodyIDs": [rim["id"]], "color": [0.83, 0.85, 0.87], "metallic": 1, "roughness": 0.3}); time.sleep(4.0)
    X("body.setMaterial", {"bodyIDs": [rim["id"]], "color": [0.83, 0.85, 0.87], "metallic": 0.5, "roughness": 0.3})
    tl.hold(0.3)
    tl.begin("roughness")
    time.sleep(0.5)
    for r in (0.05, 0.25, 0.5, 0.8):
        X("body.setMaterial", {"bodyIDs": [rim["id"]], "color": [0.83, 0.85, 0.87], "metallic": 1, "roughness": r}); time.sleep(2.4)
    tl.hold(0.3)
    tl.begin("custom")
    time.sleep(0.5)
    X("body.setMaterial", {"bodyIDs": [rim["id"]], "color": [0.16, 0.45, 0.95], "metallic": 0, "roughness": 0.5}); time.sleep(3.5)
    X("body.setMaterial", {"bodyIDs": [rim["id"]], "color": [0.16, 0.45, 0.95], "metallic": 0, "roughness": 0.12}); time.sleep(3.0)
    X("body.setMaterial", {"bodyIDs": [tyre["id"]], "preset": "Rubber"})
    cmd("view.fit", 0.6)
    tl.hold(0.3)
    tl.begin("bottle")
    t.touch("back:Demos"); time.sleep(1.4)
    t.touch("open_card:Glass Bottle"); wait_document(); time.sleep(1.5)
    bottle = bodies()[0]
    X("body.setMaterial", {"bodyIDs": [bottle["id"]], "color": [0.62, 0.86, 0.78], "metallic": 0, "roughness": 0.08}); time.sleep(1.0)
    cmd("view.front", 1.6); cmd("view.isometric", 1.4); cmd("view.fit", 0.4)
    tl.hold(0.3)
    tl.begin("geometry")
    time.sleep(0.5)
    bb = bottle["bounds"]; cx, cy, cz = [(bb[0][i] + bb[1][i]) / 2 for i in range(3)]
    t.double_tap_world(cx, cy - 60, bb[1][2]); time.sleep(1.5)  # info bar: volume + bounds
    t.touch("toolbar:HistoryButton"); time.sleep(0.8)
    tl.hold(0.6)
    t.touch("toolbar:HistoryButton"); time.sleep(0.4)
    tl.begin("outro")
    t.touch(DESELECT); time.sleep(0.4)
    cmd("view.right", 1.6); cmd("view.isometric", 1.4); cmd("view.fit", 0.4)
    tl.hold(1.0)


TAKES = {"sketching": take_sketching, "shapes": take_shapes, "materials": take_materials}

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("video", choices=list(VIDEOS))
    ap.add_argument("--compose-only", action="store_true")
    ap.add_argument("--take-only", action="store_true")
    a = ap.parse_args()
    v = VIDEOS[a.video]
    take_dir = os.path.join(S, "take-" + a.video)
    if not a.compose_only:
        run_take(a.video, v["script"], TAKES[a.video], take_dir)
    if not a.take_only:
        synthesize(a.video, v["script"])
        os.makedirs(OUT_DIR, exist_ok=True)
        out = os.path.join(OUT_DIR, f"openshape3d-tutorial-{a.video}.mp4")
        compose(a.video, v["script"], take_dir, v, out, v["series"])
        write_metadata(os.path.join(OUT_DIR, f"openshape3d-tutorial-{a.video}-metadata.md"), v, v["script"], take_dir)
