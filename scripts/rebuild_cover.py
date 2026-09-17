#!/usr/bin/env python3
"""Rebuild the reference tutorial's "Motorcycle cover" through POST /v1/exec.

THE model NEXT §4b recorded as unreachable: its recipe needs Fillet and
Shell, which take topological refs, not numbers. The /v1/edges + /v1/faces
discovery endpoints and the identity-addressed exec ops (topo-naming step
4b) closed that gap — this script is their manual regression, the way
rebuild_wheel.py is for the original exec surface.

Recipe (scripts/model_extract.py on the tutorial archive, metres → mm;
recipe z-up maps to the app's y-up):

  Extrusion 01  blank   teardrop (2 tangent lines + 2 arcs) on ground, 12 up
  Extrusion 02  boss    a RING band (outer + inner teardrop, i.e. a profile
                        with a HOLE) at y=12, 1.4 tall, JOIN, DRAFTED 10°
                        (recipe taper; since 2026-09-02 `taperDegrees` — the
                        band contracts upward for mould release: the outer
                        wall leans in, the hole widens, both by tan10°·t).
                        Expected volume is the Steiner integral of the band:
                        (A_out−A_in)·h − (P_out+P_in)·tan10°·h²/2.
  Fillet 01     1.8     the recipe names Parasolid edges we cannot read; the
                        tutorial rounds the blank's top rim. The rim is one
                        TANGENT CHAIN, so we pick a single convex rim edge
                        from /v1/edges and the kernel propagates the loop.
  Shell 01      1.3     opening the bottom face (largest −y planar).
  Extrusion 03  nub     circle r4 at (60,0) on the DOWN-facing base plane,
                        0.75 along −y, JOIN, DRAFTED 10° (the recipe's −10°
                        reads as "contract away from the plane" too — its
                        sign follows the sketch normal, the nub extrudes
                        against it): a cone frustum r4 → r4−0.75·tan10°.

Skipped: Import 01 (Parasolid bodies, permanently out of reach) and
Extrusion 04 (the spline-profile engraving — splines DO become profiles
since 2026-09-01, but the recipe's control points were never extracted
into this script; the source archive is not on this machine).

Run against a live DEBUG app (see .claude/skills/drive-openshape3d/);
port from OS3D_PORT (default 8787 — this repo's newer machines may need
8899, see NEXT.md §1).
"""

import json, math, os, sys, urllib.error, urllib.request

BASE = f"http://127.0.0.1:{os.environ.get('OS3D_PORT', '8787')}"

def call(path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data,
                                 headers={"Content-Type": "application/json"})
    try:
        return json.load(urllib.request.urlopen(req, timeout=180))
    except urllib.error.HTTPError as e:
        return json.load(e)

def X(p):
    return call("/v1/exec", p)

def arc(cx, cy, sx, sy, ex, ey):
    return {"kind": "arc", "center": [cx, cy],
            "radius": math.hypot(sx - cx, sy - cy),
            "startAngle": math.atan2(sy - cy, sx - cx),
            "endAngle": math.atan2(ey - cy, ex - cx)}

def report(res, label, expect_mm3=None, tol=0.02, strict=True):
    ok = res.get("ok") and not res.get("failed")
    print(f"-- {label}: ok={res.get('ok')} failed={res.get('failed')} "
          f"warn={res.get('warning')} errs={res.get('evalErrors')}")
    if not ok:
        print(json.dumps(res, indent=1)[:800])
        if strict:
            sys.exit(f"{label} failed")
        return res
    for b in res.get("bodies", []):
        print(f"     {b['name']:<12} {b['volumeMM3']:>12,.2f} mm3  brep={b['brep']}")
    if expect_mm3 is not None:
        got = res["bodies"][0]["volumeMM3"]
        drift = abs(got - expect_mm3) / expect_mm3
        marker = "OK" if drift <= tol else "DRIFT"
        print(f"     expected ~{expect_mm3:,.0f} mm3  ({marker}, {drift*100:.2f}%)")
        if drift > tol:
            sys.exit(f"{label}: volume off by {drift*100:.1f}%")
    return res

def health():
    h = call("/v1/check")
    assert h["invalid"] == 0, f"invalid geometry: {json.dumps(h)[:400]}"
    print(f"     health: invalid={h['invalid']}")

def teardrop_perimeter(r0, x1, r1):
    """Perimeter of the same convex hull: two tangents + the two cap arcs."""
    t = math.asin((r1 - r0) / x1)
    seg = math.sqrt(x1 * x1 - (r1 - r0) ** 2)
    return 2 * seg + (math.pi - 2 * t) * r0 + (math.pi + 2 * t) * r1

def teardrop_area(r0, x1, r1):
    """Exact area of the convex hull of circles r0@(0,0) and r1@(x1,0)
    (two tangent lines + two arcs) — the cover's every outline."""
    # Standard decomposition: the two tangent trapezoids plus the two
    # circular sectors the caps keep (small cap π−2t, big cap π+2t).
    t = math.asin((r1 - r0) / x1)               # tangent tilt
    seg = math.sqrt(x1 * x1 - (r1 - r0) ** 2)   # tangent length
    quad = seg * (r0 + r1)                      # both tangent trapezoids
    sect = (math.pi / 2 - t) * r0 * r0 + (math.pi / 2 + t) * r1 * r1
    return quad + sect

# ---- geometry from the recipe --------------------------------------------
BLANK = dict(r0=10.0, x1=40.0, r1=20.0)           # from arc radii below
BOSS_OUT = dict(r0=6.7, x1=40.0, r1=16.7)
BOSS_IN = dict(r0=5.0, x1=40.0, r1=15.0)

blank_area = teardrop_area(**BLANK)
boss_area = teardrop_area(**BOSS_OUT) - teardrop_area(**BOSS_IN)

print(f"analytic: blank area {blank_area:.2f} mm2, boss band {boss_area:.2f} mm2")

# ---- 1. Extrusion 01: the blank ------------------------------------------
sk1 = X({"op": "sketch.create", "args": {"name": "Cover Outline"}})["sketchID"]
X({"op": "sketch.addEntities", "args": {"sketchID": sk1, "entities": [
    {"kind": "line", "a": [-2.5, -9.682458365518546], "b": [35.0, -19.36491673103709]},
    {"kind": "line", "a": [-2.5, 9.682458365518546], "b": [35.0, 19.36491673103709]},
    arc(0, 0, -2.5, 9.682458365518546, -2.5, -9.682458365518546),
    arc(40, 0, 35.0, -19.36491673103709, 35.0, 19.36491673103709),
]}})
res = X({"op": "feature.extrude", "args": {"sketchID": sk1,
                                           "seedPoint": [20, 0], "distance": 12}})
body = res["producedBodyIDs"][0]
report(res, "Extrusion 01 (blank)", expect_mm3=blank_area * 12)
health()

# ---- 2. Extrusion 02: the boss ring, JOINed ------------------------------
sk2 = X({"op": "sketch.create", "args": {
    "name": "Boss Band", "origin": [0, 12, 0],
    "xAxis": [1, 0, 0], "yAxis": [0, 0, -1]}})["sketchID"]
X({"op": "sketch.addEntities", "args": {"sketchID": sk2, "entities": [
    {"kind": "line", "a": [-1.675, -6.487247], "b": [35.825, -16.169705]},
    {"kind": "line", "a": [35.825, 16.169705], "b": [-1.675, 6.487247]},
    {"kind": "line", "a": [-1.25, -4.841229], "b": [36.25, -14.523688]},
    {"kind": "line", "a": [36.25, 14.523688], "b": [-1.25, 4.841229]},
    arc(0, 0, -1.675, 6.487247, -1.675, -6.487247),
    arc(40, 0, 35.825, -16.169705, 35.825, 16.169705),
    arc(0, 0, -1.25, 4.841229, -1.25, -4.841229),
    arc(40, 0, 36.25, -14.523688, 36.25, 14.523688),
]}})
# Drafted band (Steiner): the outer teardrop offsets inward by δ(t) and the
# hole outward by δ(t), δ = t·tan10°, so the band area at height t is
# (A_out − A_in) − (P_out + P_in)·δ(t) (the πδ² terms cancel).
TAPER = 10.0
tan_t = math.tan(math.radians(TAPER))
band_perim = teardrop_perimeter(**BOSS_OUT) + teardrop_perimeter(**BOSS_IN)
boss_drafted = boss_area * 1.4 - band_perim * tan_t * 1.4 ** 2 / 2
expected = blank_area * 12 + boss_drafted
print(f"analytic: drafted band {boss_drafted:.2f} mm3 (straight would be {boss_area * 1.4:.2f})")
res = report(X({"op": "feature.extrude", "args": {
    "sketchID": sk2, "seedPoint": [55.85, 0], "distance": 1.4,
    "taperDegrees": TAPER,
    "boolean": "union", "booleanTargets": [body]}}),
    "Extrusion 02 (boss join, drafted 10°)", expect_mm3=expected, tol=0.005)
health()

# ---- 3. Fillet 01: one rim edge, tangent chain does the rest -------------
edges = call(f"/v1/edges?body={body}")["edges"]
rim = [e for e in edges
       if e.get("convex") and e.get("midpoint")
       and 11.5 < e["midpoint"][1] < 12.5]
assert rim, f"no convex rim edge at y~12 among {len(edges)} edges"
pre = call("/v1/state")["bodies"][0]["volumeMM3"]
res = report(X({"op": "feature.fillet", "args": {
    "bodyID": body, "radius": 1.8, "edges": [rim[0]["index"]]}}),
    "Fillet 01 (1.8, rim chain)")
post = call("/v1/state")["bodies"][0]["volumeMM3"]
print(f"     fillet removed {pre - post:,.2f} mm3")
assert post < pre, "a convex fillet must remove material"
health()

# ---- 4. Shell 01: open the bottom ----------------------------------------
faces = call(f"/v1/faces?body={body}")["faces"]
bottoms = [f for f in faces if f["kind"] == "planar" and f["normal"][1] < -0.9]
assert bottoms, "no down-facing planar face to open"
bottom = max(bottoms, key=lambda f: f["areaMM2"])
res = report(X({"op": "feature.shell", "args": {
    "bodyID": body, "thickness": 1.3, "openFaces": [bottom["index"]]}}),
    "Shell 01 (1.3, bottom open)")
shelled = call("/v1/state")["bodies"][0]["volumeMM3"]
print(f"     shelled down to {shelled:,.2f} mm3")
health()

# ---- 5. Extrusion 03: the nub, JOINed to the hollow cover ----------------
# Recipe-exact first: the r4 circle at (60,0) is TANGENT to the cover's
# outer wall at x=60 — the boolean hard case that originally HUNG the app
# forever at 99% CPU, and the reason constructive builders now run under a
# kernel deadline. A typed refusal here is ACCEPTABLE behavior (and leaves
# an auto-captured repro bundle); the 0.5 mm-overlap retry must succeed.
def nub(cx, label, strict):
    sk = X({"op": "sketch.create", "args": {
        "name": "Nub", "origin": [0, 0, 0],
        "xAxis": [1, 0, 0], "yAxis": [0, 0, 1]}})["sketchID"]
    X({"op": "sketch.addEntities", "args": {"sketchID": sk, "entities": [
        {"kind": "circle", "center": [cx, 0], "radius": 4},
    ]}})
    before = call("/v1/state")["bodies"][0]["volumeMM3"]
    res = report(X({"op": "feature.extrude", "args": {
        "sketchID": sk, "seedPoint": [cx, 0], "distance": 0.75,
        "taperDegrees": TAPER,
        "boolean": "union", "booleanTargets": [body]}}), label, strict=strict)
    if res.get("ok") and not res.get("failed"):
        r2 = 4 - 0.75 * tan_t
        frustum = math.pi * 0.75 / 3 * (16 + 4 * r2 + r2 * r2)
        after = call("/v1/state")["bodies"][0]["volumeMM3"]
        print(f"     nub added {after - before:,.2f} mm3 vs frustum {frustum:,.2f} "
              f"(a tangent/overlapping join adds slightly less)")
    return res

res = nub(60.0, "Extrusion 03 (nub, recipe-exact tangent)", strict=False)
if res.get("failed") or not res.get("ok"):
    print("     tangent union refused (typed, bounded — capture bundle "
          "written); undoing the recorded node and retrying with overlap")
    call("/v1/command", {"id": "edit.undo"})   # a bridge feature is one undo step
    nub(59.5, "Extrusion 03 (nub, 0.5 overlap)", strict=True)
health()

final = call("/v1/state")
print("\nFINAL:", json.dumps({
    "bodies": [{k: b[k] for k in ("name", "volumeMM3", "brep")}
               for b in final["bodies"]],
    "features": final["featureCount"],
    "evalErrors": final.get("evalErrors"),
}, indent=1))
print("\nMotorcycle cover: main sequence rebuilt with both drafts (engraving + import "
      "excluded — see the docstring).")
