#!/usr/bin/env python3
"""Runner kit for the SOLIDWORKS Practice Problem database
(https://www.solidworks.com/solution/education/practice-problems, 365
one-page PDFs). Each sheet is a dimensioned drawing with the part's
VOLUME printed on it, so every problem carries its own exact check.

A problem is a Python function that builds the part through the agent
bridge using only operations the app's palette offers (Sketch › Line /
Rect / Circle / Polygon / Arc, Modify › Extrude (boss, cut, symmetric,
draft), Revolve, Sweep, Loft, Fillet, Chamfer, Shell, Combine, Transform ›
Move / Rotate / Mirror / Pattern). The runner opens a FRESH document per
problem (a relaunch with OS3D_FRESH=1, what "New" does), builds, reads the
body volume back from /v1/state, compares it with the sheet's number, runs
/v1/check, and appends a row to the results ledger.

Sketch planes follow the SOLIDWORKS drawing convention: the FRONT plane is
world XY (x right, y up, z toward the viewer), TOP is world XZ (x right,
sketch y = world −z... i.e. the drawing's "up" in a top view is world −z),
RIGHT is world YZ. `PLANES` below spells each out as (origin, xAxis,
yAxis); the extrude direction is xAxis × yAxis.

    python3 scripts/swpp/run.py 1.1 1.2 …     # by problem number
    python3 scripts/swpp/run.py level:1        # a whole level
"""

import json, math, os, subprocess, sys, time, urllib.error, urllib.request

BASE = f"http://127.0.0.1:{os.environ.get('OS3D_PORT', '8899')}"
SIM = os.environ.get("OS3D_SIM", "53EC071E-7864-4E5C-81A1-27129A04287A")
BUNDLE = "com.laan.labs.openshape3d"
DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer"
IN3 = 25.4 ** 3
LEDGER_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "results.jsonl")


# ----------------------------------------------------------------- agent ---

def call(path, payload=None, timeout=180):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {e.code} on {path}: {body[:500]}")


def X(op, args):
    r = call("/v1/exec", {"op": op, "args": args})
    if not r.get("ok", True) or r.get("error"):
        raise RuntimeError(f"{op} failed: {json.dumps(r)[:600]}")
    errs = r.get("evalErrors") or []
    if errs:
        raise RuntimeError(f"{op} left eval errors: {json.dumps(errs)[:400]}")
    return r


def G(path):
    return call(path)


def state():
    return G("/v1/state")


def bodies():
    return state()["bodies"]


def body(bid):
    for b in bodies():
        if b["id"] == bid:
            return b
    raise RuntimeError(f"body {bid} vanished")


def vol(bid):
    return body(bid)["volumeMM3"]


def bounds(bid):
    b = body(bid)["bounds"]
    return b[0], b[1]


def edges(bid):
    return [e for e in G(f"/v1/edges?body={bid}")["edges"] if "midpoint" in e and "lengthMM" in e]


def faces(bid):
    return G(f"/v1/faces?body={bid}")["faces"]


def check(bid):
    r = G(f"/v1/check?body={bid}")
    row = (r.get("bodies") or [{}])[0]
    return r.get("invalid", 1) == 0 and not row.get("meshOnly") and (row.get("health") or {}).get("valid") is True


# ---------------------------------------------------------------- planes ---
# (origin, xAxis, yAxis); the sketch (u, v) maps to origin + u·x + v·y and
# the positive extrude direction is x × y.

def front(z=0.0):
    """XY plane at depth z; extrudes toward +Z (toward the viewer)."""
    return ([0, 0, z], [1, 0, 0], [0, 1, 0])


def back(z=0.0):
    """XY plane facing −Z (u = −x so the sketch stays right-handed)."""
    return ([0, 0, z], [-1, 0, 0], [0, 1, 0])


def top(y=0.0):
    """XZ plane at height y; sketch v = −z (drawing 'up' = away); extrudes +Y."""
    return ([0, y, 0], [1, 0, 0], [0, 0, -1])


def bottom(y=0.0):
    """XZ plane at height y facing down; extrudes −Y."""
    return ([0, y, 0], [1, 0, 0], [0, 0, 1])


def right(x=0.0):
    """YZ plane at x; sketch u = −z, v = y; extrudes +X."""
    return ([x, 0, 0], [0, 0, -1], [0, 1, 0])


def left(x=0.0):
    """YZ plane at x facing −X; sketch u = z, v = y; extrudes −X."""
    return ([x, 0, 0], [0, 0, 1], [0, 1, 0])


def plane_at(origin, xa, ya):
    return (list(origin), list(xa), list(ya))


# ---------------------------------------------------------------- sketch ---

class Sketch:
    """A sketch on a plane; entities accumulate and are sent in one call."""

    def __init__(self, plane, name="Sketch"):
        o, xa, ya = plane
        self.id = X("sketch.create", {"name": name, "origin": o, "xAxis": xa, "yAxis": ya})["sketchID"]
        self.entities = []
        self.plane = plane

    def line(self, a, b):
        self.entities.append({"kind": "line", "a": list(a), "b": list(b)})
        return self

    def poly(self, pts, close=True):
        n = len(pts)
        for i in range(n if close else n - 1):
            a, b = pts[i], pts[(i + 1) % n]
            if abs(a[0] - b[0]) > 1e-9 or abs(a[1] - b[1]) > 1e-9:
                self.line(a, b)
        return self

    def rect(self, x0, y0, x1, y1):
        self.entities.append({"kind": "rect", "min": [min(x0, x1), min(y0, y1)], "max": [max(x0, x1), max(y0, y1)]})
        return self

    def rect_c(self, cx, cy, w, h):
        return self.rect(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2)

    def circle(self, c, r):
        self.entities.append({"kind": "circle", "center": list(c), "radius": r})
        return self

    def arc(self, c, r, a0, a1):
        """Arc by centre, radius and start/end angles in DEGREES (CCW)."""
        self.entities.append({"kind": "arc", "center": list(c), "radius": r,
                              "startAngle": math.radians(a0), "endAngle": math.radians(a1)})
        return self

    def ellipse(self, c, rx, ry, rotation_deg=0.0):
        self.entities.append({"kind": "ellipse", "center": list(c), "radiusX": rx, "radiusY": ry,
                              "rotation": math.radians(rotation_deg)})
        return self

    def polygon(self, c, r, sides, rotation_deg=0.0):
        """Regular polygon by circumscribed radius (vertices on it)."""
        self.entities.append({"kind": "polygon", "center": list(c), "radius": r,
                              "sides": sides, "rotation": math.radians(rotation_deg)})
        return self

    def polygon_flats(self, c, across_flats, sides, rotation_deg=0.0):
        r = across_flats / 2 / math.cos(math.pi / sides)
        return self.polygon(c, r, sides, rotation_deg)

    def rounded_poly(self, pts, r):
        """Closed polygon with every corner rounded by a sketch fillet of
        radius r (arcs tangent to both edges). Works for convex and concave
        corners; pass r as a per-corner list to vary it (0 = sharp)."""
        n = len(pts)
        radii = list(r) if isinstance(r, (list, tuple)) else [r] * n
        tangents = []
        for i in range(n):
            p0, p1, p2 = pts[i - 1], pts[i], pts[(i + 1) % n]
            ri = radii[i]
            if ri <= 0:
                tangents.append((p1, p1, None, None, None))
                continue
            a = (p0[0] - p1[0], p0[1] - p1[1]); b = (p2[0] - p1[0], p2[1] - p1[1])
            la, lb = math.hypot(*a), math.hypot(*b)
            a = (a[0] / la, a[1] / la); b = (b[0] / lb, b[1] / lb)
            cos_t = max(-1.0, min(1.0, a[0] * b[0] + a[1] * b[1]))
            theta = math.acos(cos_t)                     # interior angle at the corner
            d = ri / math.tan(theta / 2)                 # tangent distance along each edge
            ta = (p1[0] + a[0] * d, p1[1] + a[1] * d)
            tb = (p1[0] + b[0] * d, p1[1] + b[1] * d)
            bis = (a[0] + b[0], a[1] + b[1]); lbis = math.hypot(*bis)
            bis = (bis[0] / lbis, bis[1] / lbis)
            c = (p1[0] + bis[0] * ri / math.sin(theta / 2), p1[1] + bis[1] * ri / math.sin(theta / 2))
            tangents.append((ta, tb, c, ri, (a, b)))
        for i in range(n):
            ta, tb, c, ri, _ = tangents[i]
            nxt = tangents[(i + 1) % n][0]
            if c is not None:
                a0 = math.degrees(math.atan2(ta[1] - c[1], ta[0] - c[0]))
                a1 = math.degrees(math.atan2(tb[1] - c[1], tb[0] - c[0]))
                # sweep the short way from ta to tb
                sweep = (a1 - a0) % 360
                if sweep > 180:
                    self.arc(c, ri, a1, a0 + 360 if a0 < a1 else a0)
                else:
                    self.arc(c, ri, a0, a0 + sweep)
            if abs(tb[0] - nxt[0]) > 1e-9 or abs(tb[1] - nxt[1]) > 1e-9:
                self.line(tb, nxt)
        return self

    def hull2(self, c1, r1, c2, r2):
        """Convex hull of two circles (a lever arm): two tangent lines and
        the two outer arcs. Works for unequal radii."""
        x1, y1 = c1; x2, y2 = c2
        d = math.hypot(x2 - x1, y2 - y1)
        base = math.atan2(y2 - y1, x2 - x1)
        alpha = math.asin((r1 - r2) / d)          # tangent tilt
        # Tangent normals (rotated into the c1→c2 frame): upper and lower.
        nu = base + math.pi / 2 - alpha
        nl = base - math.pi / 2 + alpha
        def pt(c, r, ang):
            return (c[0] + r * math.cos(ang), c[1] + r * math.sin(ang))
        p1u, p2u = pt(c1, r1, nu), pt(c2, r2, nu)
        p1l, p2l = pt(c1, r1, nl), pt(c2, r2, nl)
        self.line(p1u, p2u)
        self.line(p2l, p1l)
        # Small-end cap (CCW from lower tangent to upper tangent through +base)
        self.arc(c2, r2, math.degrees(nl), math.degrees(nu))
        # Big-end cap (CCW from upper tangent round the back to the lower one)
        self.arc(c1, r1, math.degrees(nu), math.degrees(nl) + 360)
        return self

    def slot(self, a, b, r):
        """Straight slot: two semicircles + two tangent lines between centres a, b."""
        ax, ay = a; bx, by = b
        dx, dy = bx - ax, by - ay
        L = math.hypot(dx, dy)
        ux, uy = dx / L, dy / L
        nx, ny = -uy, ux
        ang = math.degrees(math.atan2(uy, ux))
        self.line((ax + nx * r, ay + ny * r), (bx + nx * r, by + ny * r))
        self.line((bx - nx * r, by - ny * r), (ax - nx * r, ay - ny * r))
        self.arc(b, r, ang - 90, ang + 90)
        self.arc(a, r, ang + 90, ang + 270)
        return self

    def commit(self):
        if self.entities:
            X("sketch.addEntities", {"sketchID": self.id, "entities": self.entities})
            self.entities = []
        return self


# --------------------------------------------------------------- features ---

def extrude(sk, seed, distance, symmetric=False, taper=0.0, cut=None, union=None, new_body=False, end=None):
    """Modify › Extrude. `cut=[bodyIDs]` subtracts, `union=[bodyIDs]` joins;
    otherwise a new body. `end="throughAll"|"upToNext"` resolves the
    distance from the bodies (only the sign of `distance` is used then).
    Returns the produced or target body id."""
    sk.commit()
    args = {"sketchID": sk.id, "seedPoint": list(seed), "distance": distance, "symmetric": symmetric}
    if end:
        args["end"] = end
    if taper:
        args["taperDegrees"] = taper
    if cut:
        args["boolean"] = "subtract"; args["booleanTargets"] = list(cut)
    elif union:
        args["boolean"] = "union"; args["booleanTargets"] = list(union)
    elif new_body:
        args["boolean"] = "newBody"
    r = X("feature.extrude", args)
    ids = r.get("producedBodyIDs") or []
    if ids:
        return ids[0]
    return (cut or union)[0]


def revolve(sk, seed, axis_point, axis_dir, angle=360.0, cut=None, union=None):
    sk.commit()
    args = {"sketchID": sk.id, "seedPoint": list(seed), "axisPoint": list(axis_point),
            "axisDirection": list(axis_dir), "angleDegrees": angle}
    if cut:
        args["boolean"] = "subtract"; args["booleanTargets"] = list(cut)
    elif union:
        args["boolean"] = "union"; args["booleanTargets"] = list(union)
    r = X("feature.revolve", args)
    ids = r.get("producedBodyIDs") or []
    return ids[0] if ids else (cut or union)[0]


def sweep(sk, seed, spine, cut=None, union=None):
    """Modify › Sweep: the profile sketch along a world-space polyline spine
    (arcs are sampled into short segments by `arc_points`)."""
    sk.commit()
    args = {"sketchID": sk.id, "seedPoint": list(seed), "spine": [list(p) for p in spine]}
    if cut:
        args["boolean"] = "subtract"; args["booleanTargets"] = list(cut)
    elif union:
        args["boolean"] = "union"; args["booleanTargets"] = list(union)
    r = X("feature.sweep", args)
    ids = r.get("producedBodyIDs") or []
    return ids[0] if ids else (cut or union)[0]


def arc_points(center, radius, a0_deg, a1_deg, n=24, plane="xy"):
    """Points along a circular arc for a sweep spine; plane 'xy' (z const),
    'xz' or 'yz'. `center` is a 3-tuple."""
    pts = []
    for i in range(n + 1):
        a = math.radians(a0_deg + (a1_deg - a0_deg) * i / n)
        c, s = radius * math.cos(a), radius * math.sin(a)
        if plane == "xy":
            pts.append((center[0] + c, center[1] + s, center[2]))
        elif plane == "xz":
            pts.append((center[0] + c, center[1], center[2] + s))
        else:
            pts.append((center[0], center[1] + c, center[2] + s))
    return pts


def fillet(bid, radius, edge_ids):
    X("feature.fillet", {"bodyID": bid, "radius": radius, "edges": list(edge_ids)})


def chamfer(bid, setback, edge_ids):
    X("feature.chamfer", {"bodyID": bid, "setback": setback, "edges": list(edge_ids)})


def shell(bid, thickness, open_faces):
    X("feature.shell", {"bodyID": bid, "thickness": thickness, "openFaces": list(open_faces)})


def union(target, tools):
    X("feature.boolean", {"kind": "union", "targetBodyID": target, "toolBodyIDs": list(tools)})
    return target


def subtract(target, tools):
    X("feature.boolean", {"kind": "subtract", "targetBodyID": target, "toolBodyIDs": list(tools)})
    return target


def move(bid, translation=(0, 0, 0), rotation_deg=0.0, axis=(0, 0, 1), center=(0, 0, 0)):
    args = {"bodyID": bid, "translation": list(translation)}
    if rotation_deg:
        args.update({"rotationDegrees": rotation_deg, "rotationAxis": list(axis), "rotationCenter": list(center)})
    X("feature.transform", args)


def mirror(bid, origin, normal, keep=True):
    X("feature.mirror", {"bodyID": bid, "planeOrigin": list(origin), "planeNormal": list(normal), "keepOriginal": keep})


def pattern(bid, kind, count, axis=(0, 1, 0), center=(0, 0, 0), spacing=0.0, total_angle=360.0):
    X("feature.pattern", {"bodyID": bid, "kind": kind, "count": count, "axis": list(axis),
                          "center": list(center), "spacing": spacing, "totalAngleDegrees": total_angle})


# --------------------------------------------------------- edge selection ---

def edges_where(bid, pred):
    return [e["index"] for e in edges(bid) if pred(e)]


def edges_near(bid, point, tol=0.5):
    p = point
    return edges_where(bid, lambda e: math.dist(e["midpoint"], p) < tol)


def edges_along(bid, axis, coord, tol=0.5, min_len=0.0):
    """Edges whose midpoint has `coord` on `axis` (0/1/2)."""
    return edges_where(bid, lambda e: abs(e["midpoint"][axis] - coord) < tol and e["lengthMM"] >= min_len)


def edges_parallel(bid, axis, length, tol=0.5):
    """Straight edges of a given length running along `axis`: picked by the
    edge's two other midpoint coords being the same as a box corner is
    not known here, so callers usually combine with edges_along."""
    return edges_where(bid, lambda e: abs(e["lengthMM"] - length) < tol)


# ------------------------------------------------------------------ runner ---

def relaunch_fresh():
    env = dict(os.environ, DEVELOPER_DIR=DEVELOPER_DIR)
    subprocess.run(["xcrun", "simctl", "terminate", SIM, BUNDLE], env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1.0)
    # The relaunched app must listen where this kit talks (OS3D_PORT), not a
    # fixed 8899 — several simulators run the campaign side by side, each on
    # its own port, and a relaunch onto another worker's port fails to bind
    # and comes up bridge-less (found 2026-09-04).
    env2 = dict(env, SIMCTL_CHILD_OS3D_AGENT="1",
                SIMCTL_CHILD_OS3D_AGENT_PORT=os.environ.get("OS3D_PORT", "8899"),
                SIMCTL_CHILD_OS3D_FRESH="1")
    launched = subprocess.run(["xcrun", "simctl", "launch", SIM, BUNDLE], env=env2,
                              capture_output=True, text=True)
    # `simctl launch` prints "<bundle>: <pid>". The bridge must answer from
    # THAT process: another session's app already listening on this port
    # (any simulator) keeps the relaunched app from binding, and a fresh
    # document there would otherwise pass for ours (found 2026-09-16, when
    # a problem was built and ledgered in another simulator's app).
    tail = launched.stdout.strip().rsplit(":", 1)[-1].strip()
    pid = int(tail) if tail.isdigit() else None
    other = None
    for _ in range(40):
        time.sleep(0.5)
        try:
            health = G("/v1/health")
            if pid is not None and health.get("pid") != pid:
                other = health.get("pid")
                continue
            st = state()
            if st.get("ok") and st.get("featureCount", 1) == 0:
                return st["document"]
        except Exception:
            pass
    if other is not None:
        raise RuntimeError(f"port {BASE.rsplit(':', 1)[-1]} is answered by pid {other}, "
                           f"not the app just launched on {SIM} (pid {pid}); pick another OS3D_PORT")
    raise RuntimeError("app did not come up on a fresh document")


def ledger(row):
    with open(LEDGER_PATH, "a") as f:
        f.write(json.dumps(row) + "\n")


def run_problem(pid, meta, build, fresh=True):
    """Build one problem and score it. `meta` = dict(volume=<sheet value>,
    unit='mm'|'in', features=[…]); `build()` returns the finished body id
    (or a list of ids whose volumes add up)."""
    t0 = time.time()
    doc = relaunch_fresh() if fresh else state()["document"]
    row = {"problem": pid, "doc": doc, "unit": meta.get("unit", "mm"), "expected": meta["volume"],
           "features": meta.get("features", []), "ts": time.strftime("%Y-%m-%d %H:%M")}
    try:
        out = build()
        if "configs" in meta:
            # A sheet with several printed volumes (Level 16 equations /
            # configurations): build() returns one body-id list per config,
            # in the order of meta["configs"] = [(label, volume), …]; every
            # config must score, the first one heads the row.
            configs, worst, healthy = [], 0.0, True
            for (label, expected), ids in zip(meta["configs"], out):
                got_mm3 = sum(vol(b) for b in ids)
                got = got_mm3 / IN3 if row["unit"] == "in" else got_mm3
                err = (got - expected) / expected
                healthy = healthy and all(check(b) for b in ids)
                configs.append({"label": label, "expected": expected, "got": round(got, 3),
                                "errorPct": round(err * 100, 3)})
                if abs(err) > abs(worst):
                    worst = err
            st = state()
            row.update({"got": configs[0]["got"], "expected": configs[0]["expected"],
                        "errorPct": round(worst * 100, 3), "healthy": healthy, "configs": configs,
                        "features_recorded": st["featureCount"], "evalErrors": st.get("evalErrors") or [],
                        "status": "pass" if abs(worst) <= 0.005 and healthy and not st.get("evalErrors") else "fail"})
        else:
            ids = out if isinstance(out, list) else [out]
            got_mm3 = sum(vol(b) for b in ids)
            got = got_mm3 / IN3 if row["unit"] == "in" else got_mm3
            err = (got - meta["volume"]) / meta["volume"]
            healthy = all(check(b) for b in ids)
            st = state()
            row.update({"got": round(got, 3), "errorPct": round(err * 100, 3), "healthy": healthy,
                        "features_recorded": st["featureCount"], "evalErrors": st.get("evalErrors") or [],
                        "status": "pass" if abs(err) <= 0.005 and healthy and not st.get("evalErrors") else "fail"})
    except Exception as e:  # noqa: BLE001 - the ledger wants the message
        row.update({"status": "error", "message": str(e)[:500]})
    row["seconds"] = round(time.time() - t0, 1)
    ledger(row)
    flag = {"pass": "PASS", "fail": "FAIL", "error": "ERROR"}[row["status"]]
    extra = f"{row.get('got')} vs {row.get('expected')} ({row.get('errorPct')}%)" if "got" in row else row.get("message")
    if "configs" in row:
        extra += " | " + ", ".join(f"{c['label']} {c['got']}/{c['expected']} ({c['errorPct']:+.2f}%)" for c in row["configs"])
    print(f"[{flag}] {pid}: {extra}  [{row['seconds']} s]")
    return row


def draft_face(bid, face, degrees, neutral_origin=(0, 0, 0), neutral_normal=(0, 1, 0)):
    """Modify › Draft: taper an EXISTING face about its intersection with the
    neutral plane. Positive narrows the body away from that plane."""
    X("feature.draftFace", {"bodyID": bid, "face": [face], "angleDegrees": degrees,
                            "neutralOrigin": list(neutral_origin),
                            "neutralNormal": list(neutral_normal)})
