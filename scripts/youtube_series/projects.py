"""The ten project tutorials' models, one builder per video.

A builder is a generator: it yields a chapter id (matching an entry in
projects_text.py) and then performs that chapter's steps. The same code runs
in a recorded take (project_tutorial.py paces each chapter to its narration)
and in a dry run against a live app (`project_tutorial.py <name> --dry`), so
the geometry in the video is exactly the geometry that was checked.

World axes follow the app: millimetres, Y up, the ground is XZ. A ground
sketch maps (u, v) to world (u, 0, -v); FRONT maps (u, v) to (u, v, 0).
"""
import json, math, time
from common import X, call, cmd, bodies, edges, faces, log, normalized, nstr

FRONT = dict(xa=(1, 0, 0), ya=(0, 1, 0))


# ---- small geometry helpers ----------------------------------------------------------

def L(a, b):
    return {"kind": "line", "a": list(a), "b": list(b)}


def C(c, r):
    return {"kind": "circle", "center": list(c), "radius": r}


def R(a, b):
    return {"kind": "rect", "min": list(a), "max": list(b)}


def P(center, radius, sides, rotation=0.0):
    return {"kind": "polygon", "center": list(center), "radius": radius, "sides": sides, "rotation": rotation}


def chain(pts, close=True):
    n = len(pts)
    return [L(pts[i], pts[(i + 1) % n]) for i in range(n if close else n - 1)]


def unit(v):
    n = math.sqrt(sum(c * c for c in v))
    return [c / n for c in v]


def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


class M:
    """What a builder drives: the bridge always, touches only in a recorded take."""

    def __init__(self, take=None, dry=False):
        self.t, self.dry = take, dry
        self.made = []

    @property
    def live(self):
        return self.t is not None

    def pause(self, s):
        time.sleep(0.02 if self.dry else s)

    def touch(self, action, timeout=30):
        return self.t.touch(action, timeout) if self.t else "skipped"

    def view(self, v="isometric", wait=1.2):
        # the orientation animates; a fit sent mid-animation cancels the turn
        cmd(f"view.{v}", 0.02 if self.dry else 0.8)
        cmd("view.fit", 0.02 if self.dry else wait)

    def sketch(self, name, origin=(0, 0, 0), xa=(1, 0, 0), ya=(0, 0, -1), ents=(), wait=0.8):
        s = X("sketch.create", {"name": name, "origin": list(origin), "xAxis": list(xa), "yAxis": list(ya)})["sketchID"]
        if ents:
            X("sketch.addEntities", {"sketchID": s, "entities": list(ents)})
        self.pause(wait)
        return s

    def body(self, r):
        b = r["producedBodyIDs"][0]
        self.made.append(b)
        return b

    def extrude(self, s, seed, dist, wait=1.0, **kw):
        r = X("feature.extrude", dict({"sketchID": s, "seedPoint": list(seed), "distance": dist}, **kw))
        self.pause(wait)
        return r

    def new_extrude(self, s, seed, dist, wait=1.0, **kw):
        return self.body(self.extrude(s, seed, dist, wait, **kw))

    def pattern(self, body, count, wait=1.0, **kw):
        r = X("feature.pattern", dict({"bodyID": body, "count": count}, **kw))
        self.made.extend(r.get("producedBodyIDs", []))
        self.pause(wait)
        return r.get("producedBodyIDs", [])

    def boolean(self, kind, target, tools, wait=1.0):
        X("feature.boolean", {"kind": kind, "targetBodyID": target, "toolBodyIDs": list(tools)})
        self.made = [b for b in self.made if b not in tools]
        self.pause(wait)

    def fillet(self, body, edge_ids, radius, wait=1.0):
        X("feature.fillet", {"bodyID": body, "radius": radius, "edges": list(edge_ids)})
        self.pause(wait)

    def chamfer(self, body, edge_ids, setback, wait=1.0):
        X("feature.chamfer", {"bodyID": body, "setback": setback, "edges": list(edge_ids)})
        self.pause(wait)

    def shell(self, body, face_ids, t, wait=1.0):
        X("feature.shell", {"bodyID": body, "thickness": t, "openFaces": list(face_ids)})
        self.pause(wait)

    def hide_sketches(self):
        X("item.setHidden", {"allSketches": True})

    def focus(self, *ids, v=None):
        others = [b for b in self.made if b not in ids]
        if others:
            X("item.setHidden", {"ids": others, "hidden": True})
        X("item.setHidden", {"ids": list(ids), "hidden": False})
        if v:
            cmd(f"view.{v}", 0.02 if self.dry else 0.8)
        cmd("view.fit", 0.02 if self.dry else 1.2)

    def reveal(self):
        live = {b["id"] for b in bodies()}
        self.made = [b for b in self.made if b in live]
        X("item.setHidden", {"ids": self.made, "hidden": False})
        cmd("view.fit", 0.02 if self.dry else 1.0)

    def material(self, ids, wait=1.0, **spec):
        X("body.setMaterial", dict({"bodyIDs": list(ids)}, **spec))
        self.pause(wait)

    # -- real touches, each with a bridge fallback so a missed gesture never
    #    derails a take (the video then shows the same result, built by exec)

    def new_design(self):
        if self.live:
            self.touch("new_design")
        from common import wait_document
        wait_document()
        self.pause(1.5)

    def touch_extrude(self, s, seed_world, seed_local, dist):
        """Tap a sketch region (arms Extrude), type the distance on the keypad."""
        before = {b["id"] for b in bodies()}
        if self.live:
            self.t.tap_world(*seed_world)
            self.pause(1.2)
            if self.touch("exists:Distance") == "done:yes":
                self.touch(f"field:Distance={dist:g}")
                self.pause(1.4)
            new = [b["id"] for b in bodies() if b["id"] not in before]
            if new:
                self.made.append(new[0])
                self.touch("tap:0.14,0.9")             # empty grid: deselect (drops the gizmo)
                self.pause(0.6)
                return new[0]
            log("touch extrude missed; building it over the bridge")
            self.touch("button:Cancel")
        return self.new_extrude(s, seed_local, dist)

    def touch_material(self, body, point, preset, fallback=None):
        """Double-tap the body, Material, pick a preset swatch, Apply."""
        ok = False
        if self.live:
            self.t.double_tap_world(*point)
            self.pause(1.0)
            sel = json.dumps(call("/v1/state").get("selection", []))
            if body not in sel:
                log(f"double-tap selected {sel[:120]}, not the body; material over the bridge")
                self.touch("tap:0.14,0.9")
                X("body.setMaterial", {"bodyIDs": [body], "preset": preset})
                if fallback:
                    self.material([body], **fallback)
                return
            self.touch("palette:Modify/MaterialButton")
            self.pause(1.6)
            if self.touch("exists:MaterialApply") == "done:yes":
                self.touch(f"button:{preset}")
                self.pause(1.0)
                self.touch("button:MaterialApply")
                ok = True
            self.pause(0.8)
            self.touch("tap:0.14,0.9")                 # empty grid: deselect
        if not ok:
            X("body.setMaterial", {"bodyIDs": [body], "preset": preset})
        if fallback:
            self.material([body], **fallback)

    def export(self, fmt="STL"):
        """Export ▸ STL/3MF opens the iPad's save sheet; show it, then back out."""
        if not self.live:
            return
        self.touch("toolbar:ExportMenu")
        self.pause(1.4)
        self.touch(f"button:{fmt}")
        r = self.touch("save_sheet:2.5", timeout=40)
        if r != "done:saved":
            log(f"save sheet: {r}")
            self.touch("tap:0.03,0.5")                 # outside the sheet
        self.pause(1.0)

    def until_end(self, spare=1.5):
        """In a take, wait until the chapter's narration is `spare` s from its end."""
        if self.live:
            time.sleep(max(0.0, self.t.tl.remaining() - spare))

    def history(self, hold=3.0):
        if not self.live:
            return
        self.touch("toolbar:HistoryButton")
        self.pause(hold)
        self.touch("toolbar:HistoryButton")
        self.pause(0.6)

    def turntable(self, views=("front", "right", "isometric")):
        for v in views:
            self.view(v, 1.6)


def planar_faces(body, pred):
    return [f["index"] for f in faces(body) if f.get("kind") == "planar" and f.get("centroid") and pred(f["centroid"])]


def edge_ids(body, pred):
    return [e["index"] for e in edges(body) if e.get("midpoint") and pred(e)]


def arc_points(cx, cy, r, a0, a1, n):
    return [(cx + r * math.cos(a0 + (a1 - a0) * i / n), cy + r * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]


def helix_sweep(m, name, cx, y0, radius, pitch, turns, section, target, wait=1.5):
    """Sweep a (radial, axial) section along a right-handed helix about +Y
    through (cx, y0, 0), starting on +X; the section's plane is normal to the
    helix's start tangent (see scripts/rebuild_helicoil.py)."""
    t = unit([0.0, pitch / (2 * math.pi), -radius])
    xa = [1.0, 0.0, 0.0]
    xa = unit([xa[i] - sum(xa[j] * t[j] for j in range(3)) * t[i] for i in range(3)])
    ya = cross(t, xa)
    s = m.sketch(name, origin=(cx + radius, y0, 0), xa=xa, ya=ya, ents=chain(section), wait=1.0)
    seed = [sum(p[0] for p in section) / len(section), sum(p[1] for p in section) / len(section)]
    X("feature.sweep", {"sketchID": s, "seedPoint": seed, "boolean": "union", "booleanTargets": [target],
                        "helix": {"axisPoint": [cx, y0, 0], "axisDirection": [0, 1, 0], "referenceDirection": [1, 0, 0],
                                  "radius": radius, "pitch": pitch, "turns": turns}})
    m.pause(wait)


# ---- 1. coffee mug ------------------------------------------------------------------------

def build_mug(m):
    yield "intro"
    m.new_design()
    yield "profile"
    prof = [(0, 0), (38, 0), (41, 95), (0, 95)]
    s = m.sketch("Mug profile", **FRONT, ents=chain(prof), wait=0.2)
    m.view("front", 1.6)
    yield "revolve"
    mug = m.body(X("feature.revolve", {"sketchID": s, "seedPoint": [10, 40], "axisPoint": [0, 0],
                                       "axisDirection": [0, 1], "angleDegrees": 360}))
    m.pause(0.8)
    m.hide_sketches()
    m.view("isometric", 1.4)
    yield "fillet"
    m.fillet(mug, edge_ids(mug, lambda e: abs(e["midpoint"][1]) < 0.5 and e["lengthMM"] > 100), 6)
    yield "shell"
    m.shell(mug, planar_faces(mug, lambda c: c[1] > 94), 3.5)
    m.view("top", 1.4)
    m.view("isometric", 1.0)
    yield "path"
    top_y, bot_y, xr = 76, 30, 52
    r = (top_y - bot_y) / 2
    path = m.sketch("Handle path", **FRONT, ents=[
        L((38.5, top_y), (xr, top_y)),
        {"kind": "arc", "center": [xr, (top_y + bot_y) / 2], "radius": r, "startAngle": -math.pi / 2, "endAngle": math.pi / 2},
        L((xr, bot_y), (37.2, bot_y))], wait=0.4)
    m.view("front", 1.4)
    sec = m.sketch("Handle section", origin=(38.5, top_y, 0), xa=(0, 0, 1), ya=(0, 1, 0),
                   ents=[{"kind": "ellipse", "center": [0, 0], "radiusX": 7, "radiusY": 4.5}], wait=0.6)
    yield "sweep"
    m.view("isometric", 0.8)
    pts = [(38.5, top_y)] + arc_points(xr, (top_y + bot_y) / 2, r, math.pi / 2, -math.pi / 2, 30) + [(37.2, bot_y)]
    X("feature.sweep", {"sketchID": sec, "seedPoint": [0, 0], "spine": [[x, y, 0] for x, y in pts],
                        "boolean": "union", "booleanTargets": [mug]})
    m.pause(1.0)
    m.hide_sketches()
    m.view("isometric", 1.0)
    yield "rim"
    m.fillet(mug, edge_ids(mug, lambda e: e["midpoint"][1] > 94.5), 1.5)
    cmd("view.fit", 0.6)
    yield "material"
    m.material([mug], color=[0.96, 0.95, 0.91], metallic=0, roughness=0.12, wait=1.6)
    m.turntable()
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 2. chess pawn and rook ---------------------------------------------------------------

def build_chess(m):
    yield "intro"
    m.new_design()
    yield "pawn_profile"
    a0, hc, hr = -0.9, 35.0, 8.0
    head = (hr * math.cos(a0), hc + hr * math.sin(a0))
    ents = chain([(0, 0), (15, 0), (15, 3), (13, 5), (13, 7)], close=False)
    ents += [{"kind": "spline", "points": [[13, 7], [9.5, 11], [6.8, 17], [5.5, 24]], "closed": False}]
    ents += chain([(5.5, 24), (9, 25), (9, 27), head], close=False)
    ents += [{"kind": "arc", "center": [0, hc], "radius": hr, "startAngle": a0, "endAngle": math.pi / 2}]
    ents += [L((0, hc + hr), (0, 0))]
    s = m.sketch("Pawn profile", **FRONT, ents=ents, wait=0.2)
    m.view("front", 1.6)
    yield "pawn_revolve"
    pawn = m.body(X("feature.revolve", {"sketchID": s, "seedPoint": [4, 12], "axisPoint": [0, 0],
                                        "axisDirection": [0, 1], "angleDegrees": 360}))
    m.pause(0.6)
    m.hide_sketches()
    m.view("isometric", 1.4)
    yield "rook_profile"
    R0 = 45
    pts = [(0, 0), (16, 0), (16, 3), (14, 5), (14, 7), (11, 10), (9.5, 40), (12.5, 42), (12.5, 54), (0, 54)]
    s2 = m.sketch("Rook profile", origin=(R0, 0, 0), **FRONT, ents=chain(pts), wait=0.2)
    m.view("front", 1.4)
    rook = m.body(X("feature.revolve", {"sketchID": s2, "seedPoint": [5, 20], "axisPoint": [0, 0],
                                        "axisDirection": [0, 1], "angleDegrees": 360}))
    m.pause(0.6)
    m.hide_sketches()
    m.focus(rook, v="isometric")
    yield "pocket"
    s3 = m.sketch("Crown pocket", origin=(R0, 54, 0), ents=[C((0, 0), 8.5)], wait=0.8)
    m.extrude(s3, (0, 0), -5, boolean="subtract", booleanTargets=[rook])
    m.hide_sketches()
    yield "slot"
    s4 = m.sketch("Slot", origin=(R0, 54, 0), ents=[R((-14, -2.2), (14, 2.2))], wait=0.8)
    slot = m.new_extrude(s4, (0, 0), -6)
    m.hide_sketches()
    yield "pattern"
    copies = m.pattern(slot, 3, kind="circular", axis=[0, 1, 0], center=[R0, 0, 0], wait=1.4)
    m.boolean("subtract", rook, [slot] + copies, wait=1.2)
    m.view("isometric", 0.6)
    yield "material"
    m.reveal()
    m.material([pawn, rook], preset="Wood", wait=1.0)
    m.material([pawn, rook], color=[0.62, 0.43, 0.25], metallic=0, roughness=0.45, wait=1.0)
    m.turntable()
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 3. LEGO-style brick -----------------------------------------------------------------

def build_brick(m):
    Lx, Lz, H = 31.8, 15.8, 9.6
    yield "intro"
    m.new_design()
    yield "block"
    s = m.sketch("Brick", ents=[R((-Lx / 2, -Lz / 2), (Lx / 2, Lz / 2))], wait=0.3)
    m.view("isometric", 1.2)
    brick = m.touch_extrude(s, (0, 0, 0), (0, 0), H)
    m.hide_sketches()
    m.view("isometric", 1.0)
    yield "shell"
    m.view("bottom", 1.2)
    m.shell(brick, planar_faces(brick, lambda c: c[1] < 0.1), 1.2, wait=1.4)
    yield "stud"
    m.view("isometric", 1.0)
    st = m.sketch("Stud", origin=(0, H, 0), ents=[C((-12, 4), 2.4)], wait=0.8)
    stud = m.new_extrude(st, (-12, 4), 1.7)
    m.hide_sketches()
    yield "pattern"
    row = m.pattern(stud, 4, kind="linear", axis=[1, 0, 0], spacing=8, wait=1.4)
    m.boolean("union", stud, row)
    second = m.pattern(stud, 2, kind="linear", axis=[0, 0, 1], spacing=8, wait=1.4)
    m.boolean("union", brick, [stud] + second)
    yield "tubes"
    m.view("bottom", 1.0)
    tb = m.sketch("Tube", ents=[C((-8, 0), 6.51 / 2), C((-8, 0), 4.8 / 2)], wait=0.8)
    tube = m.new_extrude(tb, (-8 + 2.8, 0), H - 1.2)
    m.hide_sketches()
    more = m.pattern(tube, 3, kind="linear", axis=[1, 0, 0], spacing=8, wait=1.2)
    m.boolean("union", brick, [tube] + more, wait=1.4)
    yield "material"
    m.material([brick], color=[0.86, 0.1, 0.08], metallic=0, roughness=0.22, wait=2.0)
    m.turntable()
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 4. name keychain ----------------------------------------------------------------------

NAME = "JULES"


def entity_polyline(e):
    k = e["kind"]
    if k == "line":
        return [e["a"], e["b"]]
    if k == "rect":
        (x0, y0), (x1, y1) = e["min"], e["max"]
        return [[x0, y0], [x1, y0], [x1, y1], [x0, y1], [x0, y0]]
    if k in ("circle", "arc"):
        a0, a1 = (e.get("startAngle", 0.0), e.get("endAngle", 2 * math.pi)) if k == "arc" else (0.0, 2 * math.pi)
        if a1 < a0:
            a1 += 2 * math.pi
        n = 48
        return [[e["center"][0] + e["radius"] * math.cos(a0 + (a1 - a0) * i / n),
                 e["center"][1] + e["radius"] * math.sin(a0 + (a1 - a0) * i / n)] for i in range(n + 1)]
    if k == "spline":
        pts = e.get("points") or e.get("controlPoints") or []
        return pts + ([pts[0]] if e.get("closed") and pts else [])
    return []


def glyph_seeds(sketch_id, cell=0.08):
    """One interior point per filled region of the sketch (a letter, counters
    excluded): rasterise with the even-odd rule, label the filled components,
    and take each one's deepest cell — far from every edge, so the app's
    ProfileDetector resolves it to that letter's outline."""
    import numpy as np
    from scipy import ndimage
    sk = next(s for s in call("/v1/sketches")["sketches"] if s["id"] == sketch_id)
    segs = []
    for e in sk["entities"]:
        if e.get("construction"):
            continue
        pl = entity_polyline(e)
        segs += [(pl[i], pl[i + 1]) for i in range(len(pl) - 1)]
    xs = [p[0] for s in segs for p in s]; ys = [p[1] for s in segs for p in s]
    gx = np.arange(min(xs) - 0.5, max(xs) + 0.5, cell); gy = np.arange(min(ys) - 0.5, max(ys) + 0.5, cell)
    X_, Y_ = np.meshgrid(gx, gy)
    inside = np.zeros(X_.shape, dtype=bool)
    for (x1, y1), (x2, y2) in segs:
        if y1 == y2:
            continue
        cond = (Y_ >= min(y1, y2)) & (Y_ < max(y1, y2))
        xi = x1 + (Y_ - y1) * (x2 - x1) / (y2 - y1)
        inside ^= cond & (X_ < xi)
    labels, n = ndimage.label(inside)
    depth = ndimage.distance_transform_edt(inside)
    seeds = []
    for k in range(1, n + 1):
        d = np.where(labels == k, depth, 0)
        if d.max() * cell < 0.25:
            continue                                  # a sliver, not a letter
        iy, ix = np.unravel_index(np.argmax(d), d.shape)
        seeds.append([float(gx[ix]), float(gy[iy])])
    return sorted(seeds)


def build_keychain(m):
    # A sketch on a horizontal top face gets xAxis +Z, yAxis +X (the ground
    # plane is +X, -Z), so text written on the tag runs along +Z with its
    # letters rising towards +X. The tag is laid out along Z to match, and the
    # finished part turned 135° about Y so the name reads in the iso view.
    yield "intro"
    m.new_design()
    yield "plate"
    s = m.sketch("Tag", ents=[R((-10, -30), (10, 30))], wait=0.3)
    m.view("isometric", 1.0)
    plate = m.touch_extrude(s, (0, 0, 0), (0, 0), 3)
    m.hide_sketches()
    m.view("isometric", 0.8)
    yield "round"
    m.fillet(plate, edge_ids(plate, lambda e: abs(e["lengthMM"] - 3) < 0.05), 6)
    yield "hole"
    h = m.sketch("Ring hole", origin=(0, 3, 0), ents=[C((0, 23.5), 3)], wait=0.8)
    m.extrude(h, (0, 23.5), -3, boolean="subtract", booleanTargets=[plate])
    m.hide_sketches()
    yield "text"
    text_sketch = None
    if m.live:
        before = {s["id"] for s in call("/v1/sketches")["sketches"]}
        m.view("top", 1.4)
        m.touch("sketch_tool:Text")
        m.pause(1.8)
        m.t.tap_world(6, 3, 10)                      # plane pick: the tag's top face
        m.pause(2.0)
        cmd("view.fit", 1.2)                         # a new sketch zooms in tight
        # baseline start: "JULES" (cap height 10, ~43 mm) runs +Z to z ≈ 27
        m.t.tap_world(-5, 3, -16.5)
        m.pause(1.2)
        m.touch("text_field:TextContentField=" + NAME)
        m.pause(1.0)
        m.touch("button:TextAdd")
        m.pause(1.6)
        new = [s["id"] for s in call("/v1/sketches")["sketches"] if s["id"] not in before]
        text_sketch = new[0] if new else None
        m.touch("button:Exit Sketching")
        m.pause(1.2)
    if text_sketch is None:
        log("text by touch missed; no bridge text op exists — the take cannot continue")
        raise SystemExit(1)
    yield "raise"
    m.view("isometric", 1.0)
    letters = [m.new_extrude(text_sketch, seed, 1.6, wait=0.4) for seed in glyph_seeds(text_sketch)]
    if len(letters) > 1:
        m.boolean("union", letters[0], letters[1:], wait=0.8)
    m.hide_sketches()
    m.view("isometric", 0.8)
    yield "turn"
    for b in (plate, letters[0]):
        X("feature.transform", {"bodyID": b, "rotationDegrees": 135, "rotationAxis": [0, 1, 0], "rotationCenter": [0, 0, 0]})
    m.pause(1.2)
    m.view("isometric", 1.4)
    yield "colors"
    # a point on the tag on the camera's side of the letters (x = -8 before the
    # turn); behind them, the raised letters catch the double-tap
    a = math.radians(135)
    m.touch_material(plate, (-8 * math.cos(a), 3, 8 * math.sin(a)), "Plastic Gloss")
    m.material([letters[0]], color=[0.98, 0.98, 0.97], metallic=0, roughness=0.3, wait=1.4)
    m.turntable(("top", "isometric"))
    yield "export"
    m.export("3MF")
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 5. twisted vase -----------------------------------------------------------------------

def build_vase(m):
    secs = [(0, 34, 0), (45, 46, 20), (95, 40, 40), (140, 28, 60), (165, 33, 80)]   # height, radius, twist
    yield "intro"
    m.new_design()
    yield "base"
    ids = [m.sketch("Section 1", ents=[P((0, 0), secs[0][1], 6)], wait=0.3)]
    m.view("isometric", 1.2)
    yield "sections"
    for i, (h, r, tw) in enumerate(secs[1:], start=2):
        ids.append(m.sketch(f"Section {i}", origin=(0, h, 0), ents=[P((0, 0), r, 6, math.radians(tw))], wait=0.2))
        cmd("view.fit", 0.02 if m.dry else 1.2)
    yield "loft"
    vase = m.body(X("feature.loft", {"sections": [{"sketchID": s, "seedPoint": [0, 0]} for s in ids]}))
    m.pause(1.2)
    m.hide_sketches()
    m.view("isometric", 1.0)
    yield "shell"
    m.shell(vase, planar_faces(vase, lambda c: c[1] > 164), 2.0, wait=1.2)
    m.view("top", 1.4)
    m.view("isometric", 1.0)
    yield "material"
    m.material([vase], color=[0.13, 0.55, 0.56], metallic=0, roughness=0.28, wait=1.2)
    m.turntable()
    yield "vasemode"
    m.view("front", 1.6)
    m.view("isometric", 1.2)
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 6. hex bolt and nut with threads -------------------------------------------------------

def build_bolt(m):
    AF = 19.0
    RH = AF / 2 / math.cos(math.pi / 6)
    PITCH = 2.5
    yield "intro"
    m.new_design()
    yield "head"
    h = m.sketch("Bolt head", ents=[P((0, 0), RH, 6)], wait=0.3)
    m.view("isometric", 1.0)
    bolt = m.touch_extrude(h, (0, 0, 0), (0, 0), 8)
    m.hide_sketches()
    m.pause(0.6)
    m.chamfer(bolt, edge_ids(bolt, lambda e: abs(e["midpoint"][1] - 8) < 0.1), 1.0)
    yield "shank"
    sh = m.sketch("Shank", origin=(0, 8, 0), ents=[C((0, 0), 4.6)], wait=0.8)
    m.extrude(sh, (0, 0), 30, boolean="union", booleanTargets=[bolt])
    m.hide_sketches()
    cmd("view.fit", 0.6)
    yield "profile"
    m.view("front", 1.0)
    yield "thread"
    helix_sweep(m, "Bolt thread", 0, 11, 4.6, PITCH, 9.6, [(-0.4, -1.05), (1.4, -0.15), (1.4, 0.15), (-0.4, 1.05)], bolt, wait=1.6)
    m.hide_sketches()
    m.view("isometric", 1.2)
    yield "nut"
    N = 40
    n = m.sketch("Nut", origin=(N, 0, 0), ents=[P((0, 0), RH, 6), C((0, 0), 6.3)], wait=0.8)
    nut = m.new_extrude(n, (8, 0), 10)
    m.hide_sketches()
    cmd("view.fit", 0.8)
    yield "nut_thread"
    helix_sweep(m, "Nut thread", N, 1.3, 6.3, PITCH, 2.9, [(0.4, -1.05), (-1.3, -0.15), (-1.3, 0.15), (0.4, 1.05)], nut, wait=1.2)
    m.hide_sketches()
    m.focus(nut, v="top")
    m.pause(1.0)
    m.reveal()
    m.view("isometric", 0.6)
    yield "fit"
    # the bolt's thread starts at y = 11 on +X, the nut's at y = 1.3: lifting
    # the nut 13.45 mm puts its thread half a pitch between the bolt's turns
    X("feature.transform", {"bodyID": nut, "translation": [-N, 13.45, 0]})
    m.pause(1.5)
    m.view("front", 2.0)
    m.view("isometric", 1.6)
    m.until_end(3.0)
    cmd("edit.undo", 0.02 if m.dry else 1.4)
    m.view("isometric", 0.6)
    yield "material"
    m.touch_material(bolt, (0, 30, 5.5), "Steel", fallback=dict(color=[0.78, 0.8, 0.83], metallic=0.7, roughness=0.3))
    m.material([nut], color=[0.86, 0.7, 0.33], metallic=0.7, roughness=0.3, wait=1.2)
    m.turntable()
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 7. spur gears ---------------------------------------------------------------------------

def tooth_outline(module, teeth, phase=0.0):
    """One involute tooth (20° pressure angle), sketch coords, pointing +v
    before rotation by `phase` radians; the root dips 0.5 mm into the blank."""
    rp = module * teeth / 2
    rb = rp * math.cos(math.radians(20))
    ra = rp + module
    rr = rp - 1.25 * module
    inv = lambda a: math.tan(a) - a

    def psi(r):
        a = math.acos(min(1.0, rb / r)) if r > rb else 0.0
        return math.pi / (2 * teeth) + inv(math.radians(20)) - inv(a)

    r0 = rr - 0.5
    right = [(r0 * math.sin(psi(max(rb, r0))), r0 * math.cos(psi(max(rb, r0))))]
    start = max(rb, rr)
    for i in range(7):
        r = start + (ra - start) * i / 6
        right.append((r * math.sin(psi(r)), r * math.cos(psi(r))))
    pts = right + [(-x, y) for x, y in reversed(right)]
    c, s = math.cos(phase), math.sin(phase)
    return [(x * c - y * s, x * s + y * c) for x, y in pts], rr, (rp + rr) / 2


def gear(m, name, module, teeth, center_u, thick, phase=0.0, bore=4.0, windows=0):
    pts, rr, mid = tooth_outline(module, teeth, phase)
    blank = m.sketch(f"{name} blank", origin=(center_u, 0, 0), ents=[C((0, 0), rr + 0.3)], wait=0.6)
    body = m.new_extrude(blank, (0, 0), thick, wait=0.8)
    m.hide_sketches()
    t = m.sketch(f"{name} tooth", origin=(center_u, 0, 0), ents=chain(pts), wait=0.8)
    tooth = m.new_extrude(t, (-mid * math.sin(phase), mid * math.cos(phase)), thick, wait=1.0)
    m.hide_sketches()
    copies = m.pattern(tooth, teeth, kind="circular", axis=[0, 1, 0], center=[center_u, 0, 0], wait=1.4)
    m.boolean("union", body, [tooth] + copies, wait=1.2)
    b = m.sketch(f"{name} bore", origin=(center_u, thick, 0), ents=[C((0, 0), bore)], wait=0.6)
    m.extrude(b, (0, 0), -thick, boolean="subtract", booleanTargets=[body])
    if windows:
        w = m.sketch(f"{name} window", origin=(center_u, thick, 0), ents=[C((0, 10.5), 3.4)], wait=0.6)
        win = m.new_extrude(w, (0, 10.5), -thick, wait=0.6)
        more = m.pattern(win, windows, kind="circular", axis=[0, 1, 0], center=[center_u, 0, 0], wait=1.0)
        m.boolean("subtract", body, [win] + more, wait=1.0)
    m.hide_sketches()
    return body


def build_gear(m):
    MOD, Z1, Z2, T = 2.0, 20, 12, 8.0
    yield "intro"
    m.new_design()
    yield "numbers"
    pts, rr, mid = tooth_outline(MOD, Z1)
    blank = m.sketch("Gear blank", ents=[C((0, 0), rr + 0.3)], wait=0.3)
    m.view("isometric", 1.0)
    big = m.touch_extrude(blank, (0, 0, 0), (0, 0), T)
    m.hide_sketches()
    yield "tooth"
    t = m.sketch("Tooth", ents=chain(pts), wait=0.4)
    m.view("top", 1.4)
    m.pause(1.5)
    tooth = m.new_extrude(t, (0, mid), T, wait=0.8)
    m.until_end(2.5)
    m.hide_sketches()
    m.view("isometric", 1.0)
    yield "pattern"
    copies = m.pattern(tooth, Z1, kind="circular", axis=[0, 1, 0], center=[0, 0, 0], wait=1.6)
    m.boolean("union", big, [tooth] + copies, wait=1.4)
    yield "bore"
    b = m.sketch("Bore", origin=(0, T, 0), ents=[C((0, 0), 4.0)], wait=0.6)
    m.extrude(b, (0, 0), -T, boolean="subtract", booleanTargets=[big])
    w = m.sketch("Window", origin=(0, T, 0), ents=[C((0, 10.5), 3.4)], wait=0.6)
    win = m.new_extrude(w, (0, 10.5), -T, wait=0.6)
    more = m.pattern(win, 5, kind="circular", axis=[0, 1, 0], center=[0, 0, 0], wait=1.0)
    m.boolean("subtract", big, [win] + more, wait=1.0)
    m.hide_sketches()
    cmd("view.fit", 0.6)
    yield "pinion"
    centre = MOD * (Z1 + Z2) / 2
    small = gear(m, "Pinion", MOD, Z2, centre, T, phase=math.pi / Z2, bore=3.0)
    m.view("top", 1.6)
    m.view("isometric", 1.0)
    yield "material"
    m.touch_material(big, (-15, T, 0), "Brass", fallback=dict(color=[0.88, 0.7, 0.3], metallic=0.75, roughness=0.3))
    m.material([small], color=[0.8, 0.82, 0.85], metallic=0.7, roughness=0.3, wait=1.2)
    m.turntable(("top", "isometric"))
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 8. fidget spinner -----------------------------------------------------------------------

def build_spinner(m):
    T, BR = 7.0, 11.05
    yield "intro"
    m.new_design()
    yield "hub"
    s = m.sketch("Hub", ents=[C((0, 0), 15)], wait=0.3)
    m.view("isometric", 1.0)
    hub = m.touch_extrude(s, (0, 0, 0), (0, 0), T)
    m.hide_sketches()
    yield "lobe"
    lb = m.sketch("Lobe", ents=[C((0, 26), 14.5)], wait=0.6)
    lobe = m.new_extrude(lb, (0, 30), T)
    m.hide_sketches()
    cmd("view.fit", 0.6)
    yield "pattern"
    copies = m.pattern(lobe, 3, kind="circular", axis=[0, 1, 0], center=[0, 0, 0], wait=0.4)
    cmd("view.fit", 0.02 if m.dry else 1.2)
    m.boolean("union", hub, [lobe] + copies, wait=1.0)
    yield "fillet"
    m.view("top", 1.0)
    m.fillet(hub, [e["index"] for e in edges(hub) if e.get("convex") is False and abs(e["lengthMM"] - T) < 0.05], 6, wait=1.4)
    m.view("isometric", 0.8)
    yield "bearings"
    hs = m.sketch("Bearing seats", origin=(0, T, 0), ents=[C((0, 0), BR), C((0, 26), BR)], wait=0.8)
    m.extrude(hs, (0, 0), -T, boolean="subtract", booleanTargets=[hub])
    cut = m.new_extrude(hs, (0, 26), -T, wait=0.6)
    more = m.pattern(cut, 3, kind="circular", axis=[0, 1, 0], center=[0, 0, 0], wait=1.0)
    m.boolean("subtract", hub, [cut] + more, wait=1.0)
    m.hide_sketches()
    yield "edges"
    outer = [e["index"] for e in edges(hub) if e.get("convex") and e.get("midpoint")
             and (abs(e["midpoint"][1]) < 0.05 or abs(e["midpoint"][1] - T) < 0.05)]
    m.fillet(hub, outer, 1.0, wait=1.0)
    yield "material"
    m.material([hub], color=[0.96, 0.45, 0.1], metallic=0, roughness=0.2, wait=1.2)
    m.turntable(("top", "isometric"))
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 9. ice cube tray -------------------------------------------------------------------------

def build_tray(m):
    H, D = 25.0, 20.0
    yield "intro"
    m.new_design()
    yield "block"
    s = m.sketch("Tray", ents=[R((-58, -38), (58, 38))], wait=0.3)
    m.view("isometric", 1.0)
    tray = m.touch_extrude(s, (0, 0, 0), (0, 0), H)
    m.hide_sketches()
    m.fillet(tray, edge_ids(tray, lambda e: abs(e["lengthMM"] - H) < 0.05), 8)
    yield "pocket"
    c = m.sketch("Cube", origin=(0, H, 0), ents=[R((-51, -33), (-21, -3))], wait=0.8)
    cube = m.new_extrude(c, (-36, -18), -D, taperDegrees=6, wait=1.2)
    m.hide_sketches()
    yield "pattern"
    row = m.pattern(cube, 3, kind="linear", axis=[1, 0, 0], spacing=36, wait=1.2)
    m.boolean("union", cube, row, wait=0.6)
    second = m.pattern(cube, 2, kind="linear", axis=[0, 0, -1], spacing=36, wait=1.2)
    yield "subtract"
    m.boolean("subtract", tray, [cube] + second, wait=1.4)
    m.view("top", 1.2)
    m.view("isometric", 0.8)
    yield "floor"
    m.fillet(tray, [e["index"] for e in edges(tray) if e.get("convex") is False and e.get("midpoint")
                    and abs(e["midpoint"][1] - (H - D)) < 0.05], 3, wait=1.2)
    yield "material"
    m.material([tray], color=[0.35, 0.72, 0.95], metallic=0, roughness=0.35, wait=1.2)
    m.turntable()
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


# ---- 10. print-in-place hinged box ---------------------------------------------------------------

def build_hinge(m):
    W2, D2, H, WALL, GAP = 30.0, 20.0, 30.0, 2.0, 0.4
    AY, AZ, KR, CL = H + GAP / 2, -(D2 + 3.5), 4.0, 0.4
    KL, AG = 19.5, 0.5
    kx = KL / 2 + AG

    def rod(name, x0, length, r, wait=0.8):
        s = m.sketch(name, origin=(x0, 0, 0), xa=(0, 0, -1), ya=(0, 1, 0), ents=[C((-AZ, AY), r)], wait=0.4)
        return m.new_extrude(s, (-AZ, AY), length, wait=wait)

    yield "intro"
    m.new_design()
    yield "box"
    s = m.sketch("Box", ents=[R((-W2, -D2), (W2, D2))], wait=0.3)
    m.view("isometric", 1.0)
    box = m.touch_extrude(s, (0, 0, 0), (0, 0), H)
    m.hide_sketches()
    m.shell(box, planar_faces(box, lambda c: c[1] > H - 0.1), WALL, wait=1.2)
    yield "lid"
    ls = m.sketch("Lid", origin=(0, H + GAP, 0), ents=[R((-W2, -D2), (W2, D2))], wait=0.6)
    lid = m.new_extrude(ls, (0, 0), 3)
    m.hide_sketches()
    yield "knuckles"
    m.view("back", 1.0)
    kA = rod("Knuckle", -W2, W2 - kx, KR)
    kB = m.body(X("feature.mirror", {"bodyID": kA, "planeOrigin": [0, 0, 0], "planeNormal": [1, 0, 0]}))
    m.pause(1.0)
    kL = rod("Lid knuckle", -KL / 2, KL, KR)
    m.hide_sketches()
    yield "clearance"
    cA = rod("Lid clearance", -W2 - 1, W2 + 1 - kx + 0.1, KR + CL, wait=0.4)
    cB = m.body(X("feature.mirror", {"bodyID": cA, "planeOrigin": [0, 0, 0], "planeNormal": [1, 0, 0]}))
    m.boolean("subtract", lid, [cA, cB], wait=0.8)
    cM = rod("Box clearance", -KL / 2 - 0.4, KL + 0.8, KR + CL, wait=0.4)
    m.boolean("subtract", box, [cM], wait=0.8)
    m.hide_sketches()
    yield "pin"
    bore = rod("Pin clearance", -KL / 2 - 1, KL + 2, 1.8 + CL, wait=0.4)
    m.boolean("subtract", kL, [bore], wait=0.6)
    pin = rod("Pin", -W2, 2 * W2, 1.8)
    m.hide_sketches()
    m.boolean("union", box, [kA, kB, pin], wait=0.8)
    m.boolean("union", lid, [kL], wait=0.8)
    m.material([box], color=[0.2, 0.62, 0.35], metallic=0, roughness=0.3, wait=0.2)
    m.material([lid], color=[0.96, 0.78, 0.2], metallic=0, roughness=0.3, wait=0.8)
    m.view("isometric", 1.0)
    yield "open"
    X("feature.transform", {"bodyID": lid, "rotationDegrees": -105, "rotationAxis": [1, 0, 0], "rotationCenter": [0, AY, AZ]})
    m.pause(2.0)
    m.view("isometric", 1.4)
    m.view("right", 1.6)
    yield "close"
    cmd("edit.undo", 0.02 if m.dry else 2.0)
    m.view("isometric", 1.2)
    yield "export"
    m.export()
    yield "outro"
    m.history(3.5)
    m.view("isometric", 0.5)


BUILDERS = {"mug": build_mug, "chess": build_chess, "brick": build_brick, "keychain": build_keychain,
            "vase": build_vase, "bolt": build_bolt, "gear": build_gear, "spinner": build_spinner,
            "tray": build_tray, "hinge": build_hinge}
