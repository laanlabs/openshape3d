"""Level 13 - Shell (12 problems). Modify > Shell with the open faces picked
by centroid/normal from /v1/faces; drafts as taper extrudes."""
import math
from kit import (Sketch, front, back, top, bottom, right, left, plane_at, extrude, revolve, fillet, chamfer,
                 shell, edges_where, edges, faces, union, subtract, mirror, pattern, bodies, vol)

PROBLEMS = {}


def problem(pid, volume, unit="mm", features=("Extrude Boss", "Shell")):
    def deco(fn):
        PROBLEMS[pid] = ({"volume": volume, "unit": unit, "features": list(features)}, fn)
        return fn
    return deco


def undo(n=1):
    """edit.undo over the command endpoint: a failed feature leaves its node
    (and evalErrors) in the document; one undo removes it (a bridge feature
    is one undo step, built or not, since 2026-09-16)."""
    from kit import call
    for _ in range(n):
        call("/v1/command", {"id": "edit.undo"})


def face_where(bid, pred):
    """Indices of faces whose (centroid, normal) satisfy pred."""
    return [f["index"] for f in faces(bid) if pred(f["centroid"], f["normal"])]


def _csk(body, center, n, depth, r_thru, r_csk):
    import level11
    return level11.csk_hole(body, center, n, depth, r_thru, r_csk)


@problem("13.1", 18931, features=("Extrude Boss", "Shell", "Hole Wizard (CSK, as cut + revolve)", "Chamfer", "Fillet", "Pattern (as recipe)"))
def p13_1():
    # L-block 55 wide (x), 55 tall: base 25 tall x 22 deep (z 0..22), upper
    # part 30 tall x 12 deep (z 0..12); origin at the bottom centre of the
    # front face. Shell 3 with the inside corner's two faces removed (the
    # step at y 25 and the upper part's back face at z 12 - Section A-A
    # and the iso show one cavity open there). The through hole is O23 (its
    # leader points at the solid circle) with the 6 CSK M2 flat-head holes
    # on the O32 bolt circle at 90 + k*60 deg; the hole goes through all,
    # so it also notches the base's back wall. 1 x 45 chamfers on both top
    # edges of that back wall (Detail B), R1 on the cavity's inside corners.
    body = extrude(Sketch(right(-27.5)).poly([(0, 0), (-22, 0), (-22, 25), (-12, 25), (-12, 55), (0, 55)]), (-6, 30), 55)
    open_faces = face_where(body, lambda c, n: (abs(n[1] - 1) < 1e-6 and abs(c[1] - 25) < 0.1)
                            or (abs(n[2] - 1) < 1e-6 and abs(c[2] - 12) < 0.1))
    assert len(open_faces) == 2, open_faces
    shell(body, 3.0, open_faces)
    top_back = edges_where(body, lambda e: abs(e["midpoint"][1] - 25) < 0.3 and e["lengthMM"] > 40
                           and (abs(e["midpoint"][2] - 22) < 0.3 or abs(e["midpoint"][2] - 19) < 0.3))
    assert len(top_back) == 2, top_back
    chamfer(body, 1.0, top_back)
    # the cavity's inside (concave) corners: edges lying on two of the inner
    # wall planes x = +-24.5, y = 3 / 52, z = 3 / 19 (the rims at the open
    # faces z = 12 and y = 25 are convex and stay sharp)
    def on(v, t):
        return abs(v - t) < 0.3
    def concave_pred(e):
        x, y, z = e["midpoint"]
        planes = sum([on(abs(x), 24.5), on(y, 3) or on(y, 52), on(z, 3) or on(z, 19)])
        return planes >= 2 and not on(z, 12) and not on(y, 25)
    concave = edges_where(body, concave_pred)
    assert len(concave) == 11, concave
    try:
        fillet(body, 1.0, concave)
    except Exception as e:  # noqa: BLE001
        print("  R1 inside fillets skipped:", str(e)[:120])
        undo()
    extrude(Sketch(front(-1)).circle((0, 25), 11.5), (0, 25), 24, cut=[body])
    for k in range(6):
        a = math.radians(90 + 60 * k)
        _csk(body, (16 * math.cos(a), 25 + 16 * math.sin(a), 0), (0, 0, 1), 3, 1.2, 2.2)
    return body


def edges_between(bid, pred_a, pred_b):
    """Edges whose two faces satisfy pred_a and pred_b (each pred takes
    (centroid, normal)); used to pick e.g. 'top face x flange side faces'."""
    fmap = {f["index"]: (f["centroid"], f["normal"]) for f in faces(bid)}
    out = []
    for e in edges(bid):
        fa, fb = [fmap.get(i) for i in e["faces"]]
        if fa is None or fb is None:
            continue
        if (pred_a(*fa) and pred_b(*fb)) or (pred_a(*fb) and pred_b(*fa)):
            out.append(e["index"])
    return out


def try_fillet(bid, radius, edge_ids_fn, label):
    """Fillet with a fresh edge list; on a kernel refusal (a recorded,
    failed node) undo it, on an HTTP refusal (nothing recorded) just skip."""
    ids = edge_ids_fn()
    if not ids:
        print("  fillet", label, "skipped: no edges matched")
        return False
    try:
        fillet(bid, radius, ids)
        return True
    except Exception as e:  # noqa: BLE001
        print("  fillet", label, "skipped:", str(e)[:110])
        if "eval errors" in str(e):
            undo()
        return False


def _kidney_pts(d, n=24):
    """Sampled points (u, v) of the 13.3 outline offset d (see _kidney)."""
    C = (30 * math.cos(math.radians(30)), 15.0)
    K = (C[0] + math.sqrt(8 * 8 - 6 * 6), 9.0)
    Rt, Rl, Rc, yf, Rn = 40 + d, 10 + d, 2 + d, 7 - d, 16 - d
    a_lc = math.degrees(math.atan2(K[1] - C[1], K[0] - C[0]))
    xn = math.sqrt(Rn * Rn - yf * yf); a_n = math.degrees(math.atan2(yf, xn))
    def arc(c, r, a0, a1):
        return [(c[0] + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), c[1] + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
    pts = arc((0, 0), Rt, 30, 150)
    for s_ in (1, -1):
        pts += arc((s_ * C[0], C[1]), Rl, a_lc, 30) if s_ > 0 else arc((s_ * C[0], C[1]), Rl, 150, 180 - a_lc)
        pts += arc((s_ * K[0], K[1]), Rc, -90, a_lc) if s_ > 0 else arc((s_ * K[0], K[1]), Rc, 180 - a_lc, 270)
        pts += [(s_ * (K[0] + (xn - K[0]) * i / n), yf) for i in range(n + 1)]
    pts += arc((0, 0), Rn, a_n, 180 - a_n)
    return pts


def _kidney(sk, d, flat_only=False):
    """13.3 outline offset d outward from the cup's inner opening I (R40 top
    arc about the origin, R10 side lobes tangent to it at 30 deg elevation,
    R2 corners onto the flat at y = 7, R16 notch about the origin). Offsetting
    keeps the arc centres: radii 40+d, 10+d, 2+d, flat at 7-d, notch 16-d."""
    C = (30 * math.cos(math.radians(30)), 15.0)
    K = (C[0] + math.sqrt(8 * 8 - 6 * 6), 9.0)        # R2 corner centre, tangent to the lobe (10-2 = 8 apart) and y = 7
    Rt, Rl, Rc, yf, Rn = 40 + d, 10 + d, 2 + d, 7 - d, 16 - d
    a_lc = math.degrees(math.atan2(K[1] - C[1], K[0] - C[0]))     # lobe -> corner tangency direction
    xn = math.sqrt(Rn * Rn - yf * yf)
    a_n = math.degrees(math.atan2(yf, xn))
    # right half, going CCW from the flat's inner end... build as a closed loop:
    sk.arc((0, 0), Rt, 30, 150)                                       # top arc
    for s in (1, -1):
        Cs = (s * C[0], C[1]); Ks = (s * K[0], K[1])
        if s > 0:
            sk.arc(Cs, Rl, a_lc, 30)                                   # lobe from the corner tangency up to 30 deg
            sk.arc(Ks, Rc, -90, a_lc)                                  # corner from the flat up to the lobe tangency
        else:
            sk.arc(Cs, Rl, 150, 180 - a_lc)
            sk.arc(Ks, Rc, 180 - a_lc, 270)
        sk.line((s * K[0], yf), (s * xn, yf))                          # flat from the corner to the notch
    sk.arc((0, 0), Rn, a_n, 180 - a_n)                                 # notch
    return sk


@problem("13.3", 43118.7, features=("Extrude Boss (draft)", "Shell", "Fillet"))
def p13_3():
    # Kidney cup, origin at the flange top on the arc centre ("Center"). The
    # callouts describe the cup's inner opening: R40 top arc and R16 notch
    # about the origin, the flat 7 above it, R2 corners; the flange is that
    # outline offset 6 (R8 TYP corners, R10 notch) and the 6 TYP is its
    # visible width. Side lobes: arcs tangent to the R40 arc at 30 deg
    # elevation (the flange's R16 lobes measure centred 30 from the origin).
    # Cup: outer wall = opening + 2, extruded 109.5 down with 2 deg draft,
    # shelled 2 from the top (inside depth 107.5); flange 3 thick; R2 on
    # the flange's top outer edge and on the cup's bottom outer edge.
    # taper sign follows the sketch normal, not the extrusion direction: a
    # boss extruded -y needs -2 to narrow downward (+2 expanded: 271848 =
    # the expanding closed form), and so does the cut below
    cup = extrude(_kidney(Sketch(top(0)), 2.0), (0, 30), -109.5, taper=-2.0)
    # the shell of a drafted prism, done exactly as a drafted cut: the inner
    # wall is the opening outline drafted the same 2 deg, floor 2 thick
    # (feature.shell refused the drafted body's top face: "no face within
    # tolerance of the pick"); a cut drafts the opposite way, hence -2
    extrude(_kidney(Sketch(top(0.01)), 0.0), (0, 30), -107.51, taper=-2.0, cut=[cup])
    # bottom outer edge R2 (the drafted body's edges blend fine; the edge
    # list must be fetched fresh right before the call)
    # curved faces report a meaningless normal over the bridge: pick by centroid height
    is_bottom = lambda c, n: abs(c[1] + 109.5) < 0.05
    is_wall = lambda c, n: -100 < c[1] < -20
    try_fillet(cup, 2.0, lambda: edges_between(cup, is_bottom, is_wall), "cup bottom outer edge")
    # flange ring as its own body (outer = opening + 6, inner just inside
    # the wall), R2 on its top outer edge, then joined
    ring = extrude(_kidney(_kidney(Sketch(top(0)), 6.0), 0.5), (0, 43), -3, new_body=True)
    pts = _kidney_pts(0.5)
    def far_from_inner(e):
        x, _, z = e["midpoint"]; u, v = x, -z
        return min(math.hypot(u - a, v - b) for a, b in pts) > 3.0
    is_top = lambda c, n: abs(c[1]) < 0.01
    is_side = lambda c, n: -2.9 < c[1] < -0.1
    try_fillet(ring, 2.0, lambda: [i for i in edges_between(ring, is_top, is_side)
                                   if far_from_inner(next(e for e in edges(ring) if e["index"] == i))], "flange top outer edge")
    union(cup, [ring])
    return cup


# ---------------------------------------------------------------- 13.9 A/B --
# Reading (R10D, both sheets pixel-measured, see agent_notes_R10D): a O200 x 50
# disc, origin at the centre of the BACK face (the section's origin side).
# Three holes OD on a bolt circle, cut from the back with a 5 deg outward
# draft (OD at the back, wider at the front - Section A-A). Everything is
# tied by tangency ("assume tangency"): each hole sits in a tube of radius
# D/2 + 10 that is tangent to the OD (pitch P = 90 - D/2, rim 10 at the
# back), the centre hole is tangent to the tubes (C/2 = P - D/2 - 10, i.e.
# C = 160 - 2D; the back view's "10" is the web between the hole edges).
# Front feature, a single 25-deep cut from the front (the section's "25"):
# the material left at full height is the convex hull of the three tubes
# minus three pockets; the pocket walls are the lines tangent to the
# BACK-diameter hole circles (perpendicular distance P/2 + D/2 from the
# origin; the hull's straight sides are 10 further out - the "10" band of
# the front view), the pockets wrap the tubes and meet them with R10
# fillets ("R10 TYP BOTH SIDES" = both ends of every wall). Both sheet
# pictures verify this (A's picture is the D=40 model, B's the D=60 one:
# hole, tube, wall, hull and fillet-arc crossings all land within 0.5 mm,
# and the tangent edges seen through the centre hole in the sections land
# at y = 8.5 / 9.7 vs 9.0 / 10.0 drawn). Shell t from the back ("5 THK TYP").
# Version A: D = 60, t = 5. Version B: D = 80, t = 7 -> C = 0 (no centre
# hole; the tubes R50 then overlap each other and the pockets shrink to
# slivers).

def _p139_geometry(D):
    P = 90 - D / 2; C = 160 - 2 * D; Rt = D / 2 + 10
    holes = [(P * math.sin(math.radians(a)), P * math.cos(math.radians(a))) for a in (0, 120, 240)]
    normals = [(math.cos(math.radians(a)), math.sin(math.radians(a))) for a in (30, 150, 270)]
    return P, C, Rt, holes, normals


def _p139_pocket_loops(D, n_arc=16):
    """Sampled closed polylines (one per pocket) of the 13.9 front pockets:
    inside the wall lines d < P/2 + D/2, outside the tubes R = D/2 + 10, with
    R10 fillets at each wall-tube corner. Built by walking the boundary of
    each pocket analytically (for D = 60 the three pockets touch only at the
    tube tangency points with the centre hole, so each is traced from its
    own wall)."""
    P, C, Rt, holes, normals = _p139_geometry(D)
    dw = P / 2 + D / 2
    loops = []
    for n in normals:
        t = (-n[1], n[0])
        # the two holes adjacent to this wall (their d-coordinate is P/2)
        adj = [h for h in holes if abs(n[0] * h[0] + n[1] * h[1] - P / 2) < 1e-6]
        assert len(adj) == 2
        # order them by s = t.h so that s increases along t
        adj.sort(key=lambda h: t[0] * h[0] + t[1] * h[1])
        hA, hB = adj                                # hA at negative s, hB at positive s
        nc = (dw - 10) - P / 2
        tc = math.sqrt((Rt + 10) ** 2 - nc ** 2)
        def fillet(h, sgn):
            F = (h[0] + n[0] * nc + sgn * t[0] * tc, h[1] + n[1] * nc + sgn * t[1] * tc)
            Tw = (F[0] + 10 * n[0], F[1] + 10 * n[1])
            ux, uy = (h[0] - F[0]) / (Rt + 10), (h[1] - F[1]) / (Rt + 10)
            Tt = (F[0] + 10 * ux, F[1] + 10 * uy)
            return F, Tw, Tt
        FA, TwA, TtA = fillet(hA, +1)               # fillet at hole A, toward the wall middle
        FB, TwB, TtB = fillet(hB, -1)
        def arc_pts(c, r, a0, a1, k):
            return [(c[0] + r * math.cos(a0 + (a1 - a0) * i / k), c[1] + r * math.sin(a0 + (a1 - a0) * i / k)) for i in range(k + 1)]
        def ang(c, p):
            return math.atan2(p[1] - c[1], p[0] - c[0])
        def short(a0, a1):
            d = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
            return a0, a0 + d
        # tube arcs: the two tubes intersect where the pocket closes (D = 60: at
        # the centre-hole tangency points, the tubes touch the centre circle;
        # the pocket boundary then runs along the centre hole between them.)
        # Tube A from its fillet tangent point TtA, going around the tube
        # toward the other tube, until it reaches the closing point.
        # Closing: intersection of tube A and tube B (they overlap for D = 80),
        # or, if they don't intersect, the arc of the centre hole between the
        # tangency points (C > 0).
        dAB = math.dist(hA, hB)
        pts = []
        pts += [TwA]
        a0, a1 = short(ang(FA, TwA), ang(FA, TtA)); pts += arc_pts(FA, 10, a0, a1, n_arc)[1:]
        if dAB < 2 * Rt:                            # tubes overlap: close at their intersection
            mx, my = (hA[0] + hB[0]) / 2, (hA[1] + hB[1]) / 2
            hh = math.sqrt(Rt ** 2 - (dAB / 2) ** 2)
            ux, uy = (hB[0] - hA[0]) / dAB, (hB[1] - hA[1]) / dAB
            # the intersection on the wall side (larger d)
            cands = [(mx - uy * hh, my + ux * hh), (mx + uy * hh, my - ux * hh)]
            X = max(cands, key=lambda p: n[0] * p[0] + n[1] * p[1])
            a0, a1 = short(ang(hA, TtA), ang(hA, X)); pts += arc_pts(hA, Rt, a0, a1, n_arc)[1:]
            a0, a1 = short(ang(hB, X), ang(hB, TtB)); pts += arc_pts(hB, Rt, a0, a1, n_arc)[1:]
        else:                                       # close along the centre hole (tangent to both tubes)
            QA = (hA[0] * (P - Rt) / P, hA[1] * (P - Rt) / P)      # tangency point tube A / centre circle
            QB = (hB[0] * (P - Rt) / P, hB[1] * (P - Rt) / P)
            a0, a1 = short(ang(hA, TtA), ang(hA, QA)); pts += arc_pts(hA, Rt, a0, a1, n_arc)[1:]
            a0, a1 = short(ang((0, 0), QA), ang((0, 0), QB)); pts += arc_pts((0, 0), C / 2, a0, a1, n_arc)[1:]
            a0, a1 = short(ang(hB, QB), ang(hB, TtB)); pts += arc_pts(hB, Rt, a0, a1, n_arc)[1:]
        a0, a1 = short(ang(FB, TtB), ang(FB, TwB)); pts += arc_pts(FB, 10, a0, a1, n_arc)[1:]
        loops.append(pts)                           # closes back to TwA along the wall
    return loops


def _p139_hull_pts(D, n_arc=24):
    """Closed polyline of the convex hull of the three tubes (tube arcs
    between the tangent points of the straight sides)."""
    P, C, Rt, holes, normals = _p139_geometry(D)
    pts = []
    # CCW around the part: top (90 deg), bottom-left (210), bottom-right (330);
    # each tube arc runs CCW from a_h - 60 to a_h + 60 so the straight sides
    # close the loop without crossing (a CW hole order self-intersected).
    for h in sorted(holes, key=lambda h: math.atan2(h[1], h[0]) % (2 * math.pi)):
        a_h = math.atan2(h[1], h[0])
        for k in range(n_arc + 1):                  # arc from a_h - 60 deg to a_h + 60 deg
            a = a_h - math.radians(60) + math.radians(120) * k / n_arc
            pts.append((h[0] + Rt * math.cos(a), h[1] + Rt * math.sin(a)))
    return pts


def _p139_build(D, t, do_shell=True):
    from kit import draft_face
    P, C, Rt, holes, normals = _p139_geometry(D)
    tan5 = math.tan(math.radians(5))
    # disc: sketch on the back face (z = 0), extruded +50 toward the front
    body = extrude(Sketch(front(0)).circle((0, 0), 100), (90, 0), 50)
    # front cut, 25 deep from the front (z 50 -> 25): everything outside the
    # hull, plus the three pockets. Sketch on the front face, cut -25.
    sk = Sketch(front(50))
    sk.circle((0, 0), 100)
    sk.poly(_p139_hull_pts(D))
    extrude(sk, (99, 0), -25, cut=[body])
    for loop in _p139_pocket_loops(D):
        sk = Sketch(front(50)).poly(loop)
        # seed: centroid of the loop
        cxp = sum(p[0] for p in loop) / len(loop); cyp = sum(p[1] for p in loop) / len(loop)
        extrude(sk, (cxp, cyp), -25, cut=[body])
    # holes: OD at the back, 5 deg outward toward the front; taper on a cut
    # from the back plane: the taper sign follows the sketch normal (+z); a
    # positive taper widens the cut along +z? (13.3's note: a cut drafts the
    # opposite way) - verified in-session, see the recipe log.
    # one cut per hole: a multi-circle sketch cuts only the seeded region
    for h in holes:
        extrude(Sketch(front(0)).circle(h, D / 2), h, 50, taper=_P139_HOLE_TAPER, cut=[body])
    if C > 0:
        extrude(Sketch(front(0)).circle((0, 0), C / 2), (0, 0), 50, cut=[body])
    if do_shell == "app":
        back_face = face_where(body, lambda c, n: abs(n[2] + 1) < 1e-6 and abs(c[2]) < 0.05)
        assert len(back_face) == 1, back_face
        shell(body, t, back_face)                   # refused on the D=60 body: fails validity checking (2026-09-16)
    elif do_shell:
        # Explicit shell cavity (the app's feature.shell refuses this body):
        # under every front face the offset ceiling is 25 - t (the pockets and
        # the outer region are 25 deep; the 10-wide band and the tube walls are
        # thinner than 2t so they carry no cavity); the walls are the rim
        # offset (R 100-t), the centre-hole offset (R C/2+t) and the hole
        # offsets - cones r = D/2 + t + z tan5, built here as cylinders at the
        # mid-height radius (same volume as the frustum to < 15 mm3 each).
        zt = 25 - t
        rb = D / 2 + t + (zt / 2) * tan5
        cav = extrude(Sketch(front(0)).circle((0, 0), 100 - t), (0, 0), zt, new_body=True)
        tools = [extrude(Sketch(front(0)).circle(h, rb), h, zt, new_body=True) for h in holes]
        if C > 0:
            tools.append(extrude(Sketch(front(0)).circle((0, 0), C / 2 + t), (0, 0), zt, new_body=True))
        subtract(cav, tools)
        subtract(body, [cav])
    return body


_P139_HOLE_TAPER = -5.0   # verified: +5 on a cut from the back plane narrows toward the front (121 759.6 = the narrowing frustum)


@problem("13.9A", 422545.8, features=("Extrude Boss", "Extrude Cut", "Draft (taper cut)", "Shell"))
def p13_9A():
    return _p139_build(60, 5)


@problem("13.9B", 506414.7, features=("Extrude Boss", "Extrude Cut", "Draft (taper cut)", "Shell"))
def p13_9B():
    return _p139_build(80, 7)


# F3 worker -------------------------------------------------------------
@problem("13.5", 37319, features=("Extrude Boss", "Shell", "Extrude Cut"))
def p13_5():
    # Trough: U profile 56 wide, straight 18 below the plate top then R28,
    # 67 long, shelled 3 with the TOP and the NEAR END open (the iso shows
    # the U rim at the near end and an end wall at the far end); the 3 plate
    # is 80 wide (15 TYP + 50 opening + 15) and overhangs the closed end by
    # the same 12 as the side wings (pixel: 12.2 in the side view, top view
    # 79.2 long) -> 80 x 79. Origin: plate top, trough centre, open end.
    z_len, plate_w, plate_l = 67.0, 80.0, 79.0
    sk = Sketch(front(0))
    sk.line((-28, 0), (-28, -18)).arc((0, -18), 28, 180, 360).line((28, -18), (28, 0)).line((28, 0), (-28, 0))
    body = extrude(sk, (0, -20), z_len)
    opens = face_where(body, lambda c, n: (abs(n[1] - 1) < 1e-6 and abs(c[1]) < 0.1)
                       or (abs(n[2] + 1) < 1e-6 and abs(c[2]) < 0.1))
    assert len(opens) == 2, opens
    shell(body, 3.0, opens)
    extrude(Sketch(bottom(0)).rect(-plate_w / 2, 0, plate_w / 2, plate_l), (-35, 70), 3, union=[body])
    extrude(Sketch(top(0)).rect(-25, 1, 25, -(z_len - 3)), (0, -30), -3, cut=[body])
    return body
