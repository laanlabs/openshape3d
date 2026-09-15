#!/usr/bin/env python3
"""Stage the App Store screenshot scenes in a live DEBUG app over the bridge.

Each scene builds its model through /v1/exec (the same DocumentCommands a
person's taps record), colours it with `body.setMaterial`, hides the
construction sketches with `item.setHidden`, and frames it. The touch-only
parts of a shot — a Dimension tool pass, an armed Extrude, an open History
panel or Export menu — are done by hand on top; see the shot list in
docs/APP_STORE_READINESS.md.

Launch each scene in its own titled design, e.g.

    SIMCTL_CHILD_OS3D_AGENT=1 SIMCTL_CHILD_OS3D_AGENT_PORT=8899 \
    SIMCTL_CHILD_OS3D_FRESH=1 SIMCTL_CHILD_OS3D_FRESH_NAME="Motorcycle Wheel" \
      xcrun simctl launch <udid> com.laan.labs.openshape3d
    OS3D_PORT=8899 python3 scripts/marketing_scenes.py wheel

Scenes: wheel (hero, and face-on under the Export menu), plate (sketch /
extrude / history), bottle (revolve + shell). World is Y-up; the ground
sketch plane is XZ. (Small parts such as the 9 mm Helicoil tessellate too
coarsely to show; scaling them up does not help.)
"""

import json, os, subprocess, sys, time, urllib.error, urllib.request

PORT = os.environ.get("OS3D_PORT", "8899")
BASE = f"http://127.0.0.1:{PORT}"
HERE = os.path.dirname(os.path.abspath(__file__))


def call(path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.load(e)


def X(op, args):
    r = call("/v1/exec", {"op": op, "args": args})
    if not r.get("ok") or r.get("evalErrors"):
        sys.exit(f"{op} failed: {json.dumps(r)[:600]}")
    return r


def bodies():
    return call("/v1/state")["bodies"]


def paint(ids, **material):
    X("body.setMaterial", {"bodyIDs": list(ids), **material})


def view(*ids):
    # Standard views animate; back-to-back camera commands cancel each other.
    for i in ids:
        call("/v1/command", {"id": i})
        time.sleep(1.2)


def rebuild(script):
    env = dict(os.environ, OS3D_PORT=PORT)
    out = subprocess.run([sys.executable, os.path.join(HERE, script)], env=env,
                         capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"{script} failed:\n{out.stdout[-1500:]}{out.stderr[-1500:]}")


def finish():
    X("item.setHidden", {"allSketches": True})
    view("view.isometric", "view.fit")
    for b in bodies():
        print(f"  {b['name']:<12} {b['id']}  {b['volumeMM3']:,.0f} mm3  brep={b['brep']}")


# ---- wheel: the motorcycle-wheel rebuild plus a revolved tyre -----------------

TYRE_R = 478.0


def wheel():
    rebuild("rebuild_wheel.py")
    rim = bodies()[0]["id"]
    # Same plane as the wheel section: u = radius along world Z, v = axial along
    # world X; revolved about v. Bead on the rim barrel (r 321.9), sidewalls
    # clearing the flanges (r ≤ 359 at |x| 147–159), tread at r 478.
    sk = X("sketch.create", {"name": "Tyre Section", "origin": [0, 0, 0],
                             "xAxis": [0, 0, 1], "yAxis": [1, 0, 0]})["sketchID"]
    side = [(325, 138), (368, 150), (412, 166), (452, 160), (473, 122)]
    pts = [[u, -v] for u, v in side] + [[TYRE_R, 0]] + [[u, v] for u, v in reversed(side)]
    X("sketch.addEntities", {"sketchID": sk, "entities": [
        {"kind": "spline", "points": pts, "closed": False},
        {"kind": "line", "a": pts[-1], "b": pts[0]}]})
    tyre = X("feature.revolve", {"sketchID": sk, "seedPoint": [420, 0], "axisPoint": [0, 0],
                                 "axisDirection": [0, 1], "angleDegrees": 360,
                                 "boolean": "newBody"})["producedBodyIDs"][0]
    # Stand it on the ground instead of half-sunk through the grid.
    for b in (rim, tyre):
        X("feature.transform", {"bodyID": b, "translation": [0, TYRE_R, 0]})
    paint([rim], color=[0.80, 0.83, 0.88], metallic=0.35, roughness=0.25)
    paint([tyre], preset="Rubber")
    finish()


# ---- plate: the Mac listing's mounting plate -----------------------------------

def plate():
    sk = X("sketch.create", {"name": "Plate"})["sketchID"]
    X("sketch.addEntities", {"sketchID": sk, "entities": [
        {"kind": "rect", "min": [-20, -12], "max": [20, 12]},
        {"kind": "circle", "center": [-12, 0], "radius": 3},
        {"kind": "circle", "center": [12, 0], "radius": 3}]})
    body = X("feature.extrude", {"sketchID": sk, "seedPoint": [0, 8], "distance": 6})["producedBodyIDs"][0]
    edges = call(f"/v1/edges?body={body}")["edges"]
    corners = [e["index"] for e in edges
               if e.get("midpoint") and abs(e["midpoint"][1] - 3) < 0.1 and abs(e["lengthMM"] - 6) < 0.1]
    X("feature.fillet", {"bodyID": body, "radius": 4, "edges": corners})
    edges = call(f"/v1/edges?body={body}")["edges"]
    # Every edge of the top face: 4 lines, 4 corner arcs, 2 hole rims. (A
    # `convex` filter dropped one hole rim and left it sharp.)
    top = [e["index"] for e in edges
           if e.get("midpoint") and abs(e["midpoint"][1] - 6) < 0.1]
    X("feature.fillet", {"bodyID": body, "radius": 1, "edges": top})
    boss = X("sketch.create", {"name": "Boss", "origin": [0, 6, 0]})["sketchID"]
    X("sketch.addEntities", {"sketchID": boss, "entities": [
        {"kind": "circle", "center": [0, 0], "radius": 5}]})
    X("feature.extrude", {"sketchID": boss, "seedPoint": [0, 0], "distance": 4.5,
                          "boolean": "union", "booleanTargets": [body]})
    paint([body], color=[0.30, 0.56, 0.96], roughness=0.3)
    finish()


# ---- bottle: revolve + shell + lip fillets --------------------------------------

def bottle():
    rebuild("rebuild_coke_bottle.py")
    paint([b["id"] for b in bodies()], color=[0.42, 0.74, 0.66], roughness=0.15)
    finish()


if __name__ == "__main__":
    scenes = {"wheel": wheel, "plate": plate, "bottle": bottle}
    if len(sys.argv) != 2 or sys.argv[1] not in scenes:
        sys.exit(f"usage: marketing_scenes.py {'|'.join(scenes)}")
    scenes[sys.argv[1]]()
